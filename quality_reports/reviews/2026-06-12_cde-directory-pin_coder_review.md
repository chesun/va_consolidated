# CDE Directory Pin Review — coder-critic

**Date:** 2026-06-12
**Reviewer:** coder-critic
**Target:** do/data_prep/k12_postsec_distance/k12_postsec_distances.do + do/settings.do
**Score:** 96/100
**Status:** Active
**Mode:** Full (Phase 1b §4.2 paper-affecting code correction; reproducibility pin per ADR-0030)

## Code-Strategy Alignment: MATCH

The change implements ADR-0030 exactly. The ADR decision text specifies: introduce `global refresh_cde_directory 0` in the BEHAVIOR/CONFIG TOGGLES block mirroring `run_prior_score`; default `0` reads the pinned cached file directly; `1` performs the original live-URL fetch with disk fallback; gate condition verbatim `if "$refresh_cde_directory" == "1"`; predecessor logic preserved (not deleted) as the `==1` branch. The diff delivers all of these. No silent deviation.

## Sanity Checks: PASS

- **Root cause correctly targeted.** The non-reproducibility came from `capture import delimited "<live URL>"` at producer line 146 succeeding at run time and consuming that day's CDE directory vintage. Gating the live fetch behind a default-off toggle and reading the cached `$distance_dtadir/raw/pubschls.txt` by default removes the run-date dependence. Sign and mechanism of the fix match the documented 50,766-row mindist_* drift.
- **Behavioral equivalence of the pinned branch — VERIFIED.** The original code path on its `_rc!=0` fallback was `import delimited $distance_dtadir/raw/pubschls.txt, clear`. The new `else` branch (line 153) is byte-identical: same command, same file, same `clear`. Downstream consumption (line 166 `keep cdscode latitude longitude`; line 167 `destring latitude longitude`) is unchanged, so var names cdscode/latitude/longitude survive identically. No other in-memory state is disturbed: the `highered` tempfile is saved at line 129 (before the gated block) and `local hn` is set at line 130 — both untouched by the restructure. The gated block leaves memory in exactly the state the original fallback left it (`allk12` tempfile saved at line 160 from whichever import ran).
- **Default-off semantics — VERIFIED.** With `global refresh_cde_directory 0`, the comparison `"0" == "1"` is false → pinned `else` branch. If the global were unset, `"" == "1"` is false → pinned branch. Unset or 0 both take the reproducible path, as the ADR and settings.do doc claim.

## Robustness: Complete

No downstream dependency on the live fetch. The two sibling consumers read only the saved `.dta` chain output:
- `merge_k12_postsec_dist.doh:70` merges `m:1 cdscode using .../k12_postsec_mindistance keepusing(mindist*)` — depends on cdscode + mindist_* vars, identical from both branches.
- `check_merge.do:69` mirrors the same merge.
- `hd2021.do` is the IPEDS sub-script `run` before the gated block (line 98); unaffected.
- `reconcile_cdscodes.do` is confirmed-orphan dead code (header line 13; ledger line 161), not invoked.

Nothing downstream assumed the URL fetch always runs.

## Code Quality (10 categories)

| Category | Status | Issues |
|----------|--------|--------|
| Script structure & headers | OK | INPUTS block (lines 18-19) accurately reflects new toggle: pinned default + fallback role for pubschls.txt; URL flagged as `==1`-only. ADR-0030 cited. |
| Console output hygiene | OK | No new `di`/`cat` status pollution introduced. |
| Reproducibility | OK | This change *improves* reproducibility — its entire purpose. No new absolute paths (live URL is an external source, predecessor-original, retained in `==1` branch only; not a deduction). |
| Function/program design | OK | n/a — straight-line script. |
| Figure quality | OK | n/a. |
| Output persistence | OK | `save` chain unchanged (lines 192, 208). |
| Comment quality | OK | Inline comment block (lines 134-141) explains WHY (live feed → non-reproducible), not WHAT. settings.do toggle doc (lines 227-239) thorough and cites M4 evidence + gate convention. |
| Stata comment safety | OK | settings.do `/*`=`*/` state-machine balanced (header banner + inline pairs; no path-glob `*` in comments). Producer headers use `<x>` placeholders throughout. No Variant-8 `^-+<x>$` artifacts (grep returned 0). No `//*****` banners introduced. |
| Error handling | OK | `capture` preserved on the live fetch with `_rc!=0` disk fallback inside `==1` branch. |
| Professional polish | OK | Stata `if/else` well-formed: `}` then `else {` on adjacent lines 150-151 (no blank line between — required by Stata parser). Braces balance. String comparison `"$g" == "1"` correct for a possibly-unset global. |

## Specific Concern Resolution (from dispatch)

1. **Gate-condition consistency** — PASS. settings.do:238 doc string `if "$refresh_cde_directory" == "1"` matches producer:143 verbatim. Default-off semantics hold (unset/0 → pinned).
2. **Behavioral equivalence of pinned branch** — PASS. `else` branch == original fallback line; no other state disturbed; downstream var names intact.
3. **No stale references** — PASS. Siblings consume the saved chain, not the fetch; reconcile_cdscodes orphan; nothing depended on the live fetch running.
4. **Stata conditional-block syntax** — PASS. Braces balanced, well-formed `if/else`, correct string comparison.
5. **ADR-0021 header conventions** — PASS. INPUTS block updated accurately; `/*`=`*/` balance preserved in both files.
6. **Scope minimal** — PASS. Diff is pin + toggle + ADR/index only. No unrelated changes observed in the reviewed files.
7. **Logging/path conventions** — PASS. log/translate block (lines 75-83, 211-212) unchanged; no new hardcoded absolute paths.

## Compliance Evidence (from .claude/state/verification-ledger.md)
- do/settings.do | tables-figures-globals | 2026-05-08T00:30Z | PASS (prior, unrelated check; file since edited — this toggle add not yet re-balloted, but the relevant check here is the new toggle, verified directly above)
- do/data_prep/k12_postsec_distance/k12_postsec_distances.do | no-logic-change | (NOT APPLICABLE — this is a deliberate, ADR-0030-sanctioned logic change gated behind a toggle, not a mechanical/no-logic-change refactor; the Tier-1 clean-refactor gate does not bind. No clean-refactor PASS is claimed.)
- No `Active` prior review for target slug `cde-directory-pin` (glob `*cde-directory*` → 0 files); no supersession needed.

## Tier-2 Verdict Evidence

- **Claim:** The pinned (`else`) branch is observationally equivalent to the original code's `_rc!=0` disk-fallback path.
  **artifact_citation:** `do/data_prep/k12_postsec_distance/k12_postsec_distances.do:153` (pinned branch) vs `:148` (original fallback, retained in `==1` branch).
  **sufficiency_argument:** Both lines are the identical command `import delimited $distance_dtadir/raw/pubschls.txt, clear`. Memory state entering the block (`highered` tempfile + `local hn` set at :129-130) and leaving it (`allk12` saved at :160; `keep`/`destring` at :166-167) is invariant across branches, so any consumer of the post-block dataset sees identical state.

## Score Breakdown
- Starting: 100
- Minor: settings.do ledger row (`tables-figures-globals`, 2026-05-08) is stale relative to this edit and the new toggle has no ledger row yet; the toggle was verified directly in this review but a fresh `(do/settings.do, behavior-toggle-default-off)` ledger row would close the audit loop. −4 (Minor; documentation-completeness, not a code defect).
- **Final: 96/100**

## Escalation Status: None

PASS — well above the 80/100 hard gate. No Critical or Major findings. Recommend committing with footer `coder-critic: PASS (96/100)`. Suggested follow-up (non-blocking): append a verification-ledger row for the new toggle so the next inheritor sees the default-off semantics confirmed by check, not just by review prose.
