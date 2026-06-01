# base_sum_stats_tab.do r(601) — base_nodrop cached-toggle bug

**Date:** 2026-06-01
**Target:** `do/share/base_sum_stats_tab.do`; log `log/share/base_sum_stats_tab.smcl:934-939`
**Status:** Active
**Class:** run-once-cached toggle with missing cache (SAME class as the mattschlchar bug / ADR-0023)

## Error

```
. if `create_sample'==0 {
.   use $datadir_clean/share/base_nodrop.dta, clear
file .../consolidated/data/cleaned/share/base_nodrop.dta not found
r(601);
```

## Root cause

`base_sum_stats_tab.do` has a run-once-cache toggle:

- L130 `local create_sample = 0`
- L131-262 `if create_sample==1 { ... build ... save $datadir_clean/share/base_nodrop.dta }` — **skipped** when 0.
- L264-266 `if create_sample==0 { use $datadir_clean/share/base_nodrop.dta }` — runs, but the file was never built → r(601).

The predecessor ran with `create_sample = 0` too (`cde_va_project_fork/.../base_sum_stats_tab.do:47`) and relied on a **pre-existing cached** `base_nodrop.dta` at `$vaprojdir/data/va_samples_v1/base_nodrop.dta` (this file's own header, L39). The ADR-0021 self-contained sandbox does not inherit that cache, and `m4_acceptance_run=1` does not rebuild it (the create block is gated by `create_sample`, not by the M4 override). So the cached `use` finds nothing.

This is the **same class** as ADR-0023 (mattschlchar): a relocated script that consumed a pre-built cache from a legacy path the sandbox doesn't carry.

## Two complications found while diagnosing

1. **`base_nodrop.dta` is self-produced** — only this file's own create block builds it (no separate producer in predecessor). So it's a within-file cache, not a chain input from another script.
2. **Latent relative-path bug in the create block** (L143):
   `merge 1:1 merge_id_k12_test_scores using data/sbac/va_samples.dta` — a **relative** path. The relocation removed the predecessor's `cd $vaprojdir` (header L44) in favor of absolute paths, but this `using` was left relative. The producer `touse_va.do:337` saves to `$datadir_clean/sbac/va_samples.dta`. So flipping `create_sample=1` would ALSO need this repointed to `$datadir_clean/sbac/va_samples.dta` (and the other relative reads in the block checked).

## Fix options (decision required)

### Option A — rebuild on demand (flip the gate under M4, fix the relative path)
Make the create block run when the cache is absent (or under `m4_acceptance_run`), AND repoint L143 `data/sbac/va_samples.dta` → `$datadir_clean/sbac/va_samples.dta` (plus audit the block's other reads). The block reads raw K12 (`$k12_test_scores`...) + `va_samples.dta` + includes consolidated helpers — all of which exist in the pipeline, so it is rebuildable on Scribe.
- **Pro:** self-contained; no manual vendoring; regenerates from canonical inputs.
- **Con:** must verify the whole create block's paths/ helpers resolve (it's ~130 lines, several merges + 5 helper includes); larger surface; golden-master must match the old cached file.

### Option B — vendor the cached base_nodrop.dta (mirror ADR-0023)
Treat `base_nodrop.dta` as a pre-existing input: vendor it from its Scribe location into `data/raw/upstream/` (or read the legacy cache once), and have the `create_sample==0` block source it — exactly the mattschlchar pattern.
- **Pro:** minimal, consistent with the just-established ADR-0023 vendoring precedent; doesn't touch the 130-line create block.
- **Con:** needs the cached `.dta` to exist somewhere readable on Scribe (the predecessor `$vaprojdir/data/va_samples_v1/base_nodrop.dta`); adds another vendored artifact; doesn't fix the latent relative-path bug (just leaves the create block dormant like clean==1).

### Option C — guard the cached use (fail-soft) 
Wrap the `use` so a missing cache triggers the rebuild automatically:
`capture confirm file "$datadir_clean/share/base_nodrop.dta"` → if missing, run the create block; else use it. (Combines A's rebuild with a guard so it self-heals.) Still needs the L143 relative-path fix.

## Recommendation
**Option A or C if the create block is genuinely rebuildable from canonical Scribe inputs** (it appears to be — raw K12 + va_samples + consolidated helpers), because it removes the cache dependency entirely and is the more durable sandbox-compliant fix. **Option B only if** the create block has a hidden inaccessible dependency (like mattschlchar's gone raw source) — then vendoring the cache is the pragmatic match to ADR-0023. The relative-path bug at L143 must be fixed under A/C regardless.

Decision hinges on: **can the create block's inputs (raw K12 test-score files at `$k12_test_scores`, `va_samples.dta`) actually be read on Scribe in the current run?** If yes → A/C. If the raw K12 files are gone like Matt's dir → B.

## Verification caveat
Scribe-only, air-gapped — cannot run locally. Whichever option, the next Scribe run is the pass/fail.
