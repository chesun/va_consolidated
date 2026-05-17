# Pre-Flight Audit Partition B — do/va/ + do/samples/ + do/sibling_xwalk/ + do/check/

**Date:** 2026-05-16
**Reviewer:** coder-critic
**Target:** Partition B (36 files) — `do/va/` (25 files: 21 .do + 3 .doh + heterogeneity/4), `do/samples/` (3 .do + .doh helpers), `do/sibling_xwalk/siblingoutxwalk.do`, `do/check/` (7 files including t1_empirical_tests.do)
**Score:** 73/100
**Status:** Superseded by quality_reports/reviews/2026-05-16_pre-flight-B-round2_va-samples-xwalk-check_coder_review.md
**Supersedes:** none

---

## Verdict — BLOCK (73/100)

ADR-0021 sandbox-write discipline holds across all 36 files I checked — **zero CRITICAL LEGACY-write violations.** Every `save`, `export`, `regsave using`, `esttab using`, `graph export`, `texsave`, `translate`, `log using`, `estimates save` that I grepped targets either a CANONICAL global (`$consolidated_dir`, `$datadir_clean`, `$estimates_dir`, `$tables_dir`, `$figures_dir`, `$logdir`, `$output_dir`) or a Stata `tempfile` (session-scoped; sandbox-exempt). The pre-scan-flagged `$vaprojdir` matches at `do/va/va_score_all.do:90`, `do/va/va_score_fb_all.do:83`, `do/va/va_out_all.do:78`, `do/va/prior_decile_original_sample.do:72`, `do/samples/create_score_samples.do:102`, `do/samples/create_out_samples.do:84` are ALL inside `RELOCATION HISTORY` comment blocks (path-repointing documentation) — confirmed by reading each file. None are live writes. Sandbox-write principle: **PASS.**

The BLOCK is driven by **three distinct chain-coordination defects** that would either (a) fail the ADR-0018 acceptance run with all toggles ON or (b) cause silent data-staleness if predecessor LEGACY data still exists on Scribe:

1. **CRITICAL — broken `sibling_out_xwalk` producer-consumer chain.** Producer `do/sibling_xwalk/siblingoutxwalk.do:338` writes to **CANONICAL** `$datadir_clean/siblingxwalk/sibling_out_xwalk`. Consumer `do/va/helpers/macros_va.doh:110` binds the local `sibling_out_xwalk` to **LEGACY** `$caschls_projdir/dta/siblingxwalk/sibling_out_xwalk`. Active consumers `do/samples/merge_sib.doh:66` and `do/share/sample_counts_tab.do:118` will read stale predecessor data (silent), not the freshly-written CANONICAL chain output. Identical failure-class to the Step 11 BONUS catch on `schlcharpooledmeans`.

2. **CRITICAL — broken score_b.dta reader path in 3 check files.** Producer `do/samples/create_score_samples.do:220` writes to `$datadir_clean/va_samples_v1/score_b.dta`. Readers `do/check/check_samples.do:71`, `do/check/check_merges.do:66`, `do/check/check_paper_outputs.do:67` look at `$estimates_dir/va_samples_v1/score_b.dta`. The `capture confirm file` shim means these checks SILENTLY SKIP on the acceptance run instead of FAILing — producing false-confidence "skeleton" output, not real validation.

3. **MAJOR — broken survey-index reader paths in check_survey_indices.do.** Sub-check 2 (L197) reads `$estimates_dir/calschls/categoryindex/<idx>categoryindex.dta`. Actual producers `do/survey_va/imputedcategoryindex.do:177` and `do/survey_va/compcasecategoryindex.do:178` write to `$datadir_clean/survey_va/categoryindex/<idx>categoryindex.dta`. Same silent-skip failure mode as finding 2.

Additional findings: 6 `.doh` files in `do/samples/` (`create_va_g11_{sample,out_sample}{,_v1,_v2}.doh`) have **relative includes** that break after the caller `cd`s to `$vaprojdir`; `do/check/t1_empirical_tests.do` is a predecessor-layout diagnostic that will cause `check_logs.do` to FAIL on the acceptance run (it's in the do/ tree but never invoked, so no `$logdir/t1_empirical_tests.smcl` is produced); and `do/va/helpers/macros_va.doh:103` has a hardcoded absolute path `/home/research/ca_ed_lab` (though the `local ca_ed_lab` it defines is unused — verified by grep).

---

## Code-Strategy Alignment: DEVIATION (3 chain-coordination defects)

The strategy specifies a self-contained sandbox where consolidated/ is the single source of truth (ADR-0021). On the WRITE side this is achieved. On the READ side, three subtrees still resolve to LEGACY paths:

- `sibling_out_xwalk` local (defined LEGACY in `macros_va.doh:110`, read by 2 active consumers).
- 3 check files reading from `$estimates_dir/va_samples_v1/...` instead of `$datadir_clean/va_samples_v1/...` (wrong CANONICAL parent global).
- 1 check file reading from `$estimates_dir/calschls/categoryindex/...` instead of `$datadir_clean/survey_va/categoryindex/...` (wrong CANONICAL parent global).

These are not LEGACY-write violations — they're producer-consumer path drift introduced when the producers were repointed without updating downstream readers. Same regression class the Step 11 BONUS catches on schlcharpooledmeans surfaced, and the protocol from `phase-1-review.md` §2 Tier-1 was supposed to catch.

## Sanity Checks: CONCERNS

- **Hardcoded paths:** 1 hit at `do/va/helpers/macros_va.doh:103` (`local ca_ed_lab "/home/research/ca_ed_lab"`). The local is unused (`grep '\`ca_ed_lab'' do/` returns no matches), so this is dead-code-smell only, not a runtime bug.
- **`cd $vaprojdir` discipline:** 23 of 25 do/va/ files cd to $vaprojdir for behavior parity, then cd back at end. Each is paired with absolute `include $consolidated_dir/do/va/helpers/...` includes (per the batch-2c convention) — verified for all 25 via the helper-include-absolute ledger rows. Good.
- **Header-doc comment matches:** Every pre-scan-flagged `$vaprojdir` write match is inside a `RELOCATION HISTORY` or comment block. Confirmed by reading each file directly. No false-positive promotions.

## Robustness: Complete (within Partition B scope)

- 28/28 do/va files have ADR-0021 PURPOSE headers.
- 7/7 do/check files have ADR-0021 PURPOSE headers.
- The 3 .doh helpers in do/va/helpers/ all have PURPOSE headers and document the `$projdir` aliasing requirement (siblingoutxwalk precedent).
- 24/25 do/va files have helper-include-absolute ledger PASS rows.
- The `cd $vaprojdir` / `cd "$consolidated_dir"` symmetry was verified by grep: 23 leading `cd $vaprojdir` matched 23 trailing `cd "$consolidated_dir"` restorations.

---

## Findings

### CRITICAL — Chain coordination: `sibling_out_xwalk` producer → CANONICAL, consumer → LEGACY

**Severity:** Critical (domain-specific chain break; same class as Step 11 BONUS catch)
**Deduction:** -15

**Where:**

- Producer: `do/sibling_xwalk/siblingoutxwalk.do:338` writes `save "$datadir_clean/siblingxwalk/sibling_out_xwalk", replace` (CANONICAL).
- Binding: `do/va/helpers/macros_va.doh:110` — `local sibling_out_xwalk "$caschls_projdir/dta/siblingxwalk/sibling_out_xwalk"` (LEGACY).
- Consumers:
  - `do/samples/merge_sib.doh:66` — `merge m:1 state_student_id using \`sibling_out_xwalk', nogen keep(1 3) keepusing(touse* *sibling*)`
  - `do/share/sample_counts_tab.do:118` — `merge m:1 state_student_id using \`sibling_out_xwalk', nogen keep(1 3)`

The `local` in macros_va.doh:110 is bound at include-time. Since macros_va.doh is included by both consumers via their parent caller, both will resolve `\`sibling_out_xwalk'` to `$caschls_projdir/dta/siblingxwalk/sibling_out_xwalk`, NOT to `$datadir_clean/siblingxwalk/sibling_out_xwalk`. If the predecessor LEGACY file still exists on Scribe (likely, per ADR-0017 "Matt's files untouched") the merges silently read stale data. If it doesn't, they crash with file-not-found.

**Why pre-commit self-check (phase-1-review.md §2 Tier-1) missed this:** The siblingoutxwalk relocation predates the schlcharpooledmeans-style trace convention. macros_va.doh:110 is in a different file from siblingoutxwalk.do, so the per-file relocation review didn't surface the consumer-side staleness.

**Recommended fix (NOT IMPLEMENTED — critics are read-only):** Either (a) repoint the local in macros_va.doh:110 to `$datadir_clean/siblingxwalk/sibling_out_xwalk` so consumers read the freshly-produced chain output, or (b) leave macros_va.doh untouched (ADR-0005 says no fork-repo edits) and create a per-script alias `local sibling_out_xwalk "$datadir_clean/siblingxwalk/sibling_out_xwalk"` in both consumers AFTER the macros_va.doh include.

---

### CRITICAL — Chain coordination: `score_b.dta` reader path wrong in 3 check files

**Severity:** Critical (3 check files SILENTLY skip on acceptance run; produces false-confidence PASS)
**Deduction:** -15

**Where:**

- Producer: `do/samples/create_score_samples.do:220` — `save "$datadir_clean/va_samples_\`version'/score_b.dta", replace`
- Readers (wrong parent global — should be `$datadir_clean`, not `$estimates_dir`):
  - `do/check/check_samples.do:71` — `local in_dta "$estimates_dir/va_samples_v1/score_b.dta"`
  - `do/check/check_merges.do:66` — `local in_score_b "$estimates_dir/va_samples_v1/score_b.dta"`
  - `do/check/check_paper_outputs.do:67` — `local in_score_b "$estimates_dir/va_samples_v1/score_b.dta"`

The `capture confirm file` shim at L73, L68, L69 respectively means the check SKIPS cleanly instead of FAILing, but every hard assertion (`_N == 1784445`, per-cohort counts, race orthogonality, school count) NEVER RUNS. The skeleton becomes a no-op that produces a misleading "PASS" log line if read superficially.

This is worse than a clean fail — it gives false confidence that the check ran. On the M4 golden-master + ADR-0018 acceptance run, the data-checks pipeline is supposed to be the substantive Tier-3 protection (per phase-1-review.md §1).

**Cross-cut concern with header docs:** Headers at L14 (check_samples.do), L13 (check_merges.do), L67 (check_paper_outputs.do) all say "Path post-Phase-1a §3.3: `$estimates_dir/va_samples_v1/score_b.dta`" — the header doc encodes the same wrong path. Either the design memo was wrong about which global produces sample outputs, or all three files inherited the same path from a draft and were never refreshed.

**Recommended fix:** Change `$estimates_dir` → `$datadir_clean` in all 3 `local in_...` lines AND in the header `INPUTS` block.

---

### MAJOR — Chain coordination: `categoryindex.dta` reader path wrong in check_survey_indices.do

**Severity:** Major (1 check sub-block SILENTLY skips on acceptance run)
**Deduction:** -10

**Where:**

- Producers:
  - `do/survey_va/imputedcategoryindex.do:177` — `save $datadir_clean/survey_va/categoryindex/imputedcategoryindex, replace`
  - `do/survey_va/compcasecategoryindex.do:178` — `save $datadir_clean/survey_va/categoryindex/compcasecategoryindex, replace`
- Reader (wrong parent global AND wrong subdir name — `$estimates_dir/calschls/` vs `$datadir_clean/survey_va/`):
  - `do/check/check_survey_indices.do:197` — `local idx_dta "$estimates_dir/calschls/categoryindex/\`idx_tag'categoryindex.dta"`

Same silent-skip-on-file-missing pattern as finding 2.

Same header-doc drift: L17-18 of check_survey_indices.do says "$estimates_dir/calschls/categoryindex/{imputed,compcase}categoryindex.dta" — the header doc reflects the wrong path.

**Note on sub-check 1 (L129/L133):** These read LEGACY `$caschls_projdir/dta/allsvyfactor/{imputed,}allsvyqoimeans.dta`. The CANONICAL chain now has `$datadir_clean/survey_va/{imputed,}allsvyqoimeans.dta` produced by `allsvymerge.do:122` and `imputation.do:180`. Reading from LEGACY is defensible if the intent is "verify the static predecessor source hasn't drifted", but given the consolidated chain has fresh CANONICAL versions, this is at best stale and at worst masks regressions in the consolidated chain. Document as ASSUMED or fix; left as MINOR observation.

---

### MAJOR — `t1_empirical_tests.do` will fail check_logs.do on acceptance run

**Severity:** Major (acceptance-run blocker; will FAIL the structural Tier-3 check)
**Deduction:** -10

**Where:**

- `do/check/t1_empirical_tests.do` exists in the `do/` tree, gets enumerated by `do/check/check_logs.do:73` (`filelist, dir("$consolidated_dir/do") pattern("*.do")`).
- It is NOT invoked from `do/main.do` (confirmed: `grep t1_empirical do/main.do` returns no matches).
- Its log target at L62-65 is `local logdir "log_files/check"` followed by `log using "\`logdir'/t1_empirical_tests_\`stamp'.smcl"` — relative path, predecessor-layout `log_files/`, not `$logdir/` from settings.do.
- Result on acceptance run: `check_logs.do` expects `$logdir/t1_empirical_tests.smcl` to exist; no producer wrote it; check fails at L121 with `exit 9` (halts pipeline).

The file's own header (L20-26) documents that it's "Place this file on Scribe at `do_files/check/t1_empirical_tests.do`" — i.e., it's a one-off predecessor-layout script that doesn't belong in the consolidated do/ tree at all. Per phase-1-review.md §6 dispatch matrix, file relocations require coder-critic dispatch, but archival/exclusion of a one-off diagnostic file is "self-check is enough" — yet the file's presence here breaks check_logs's invariant.

**Recommended fix (choices):**

1. Move `do/check/t1_empirical_tests.do` to `do/_archive/check/` (it's a Phase 0a artifact, already resolved per the audit-FINAL.md it references).
2. Add an exclusion regex in `check_logs.do:76` for `t1_empirical_tests.do` (or for `do/check/t1_*` as a pattern).
3. Add an explicit "exclude one-off diagnostics" tag system.

Option 1 is the lowest-friction.

---

### MAJOR — Relative includes inside 6 `.doh` helpers break after `cd $vaprojdir`

**Severity:** Major (will fail on `do_create_samples = 1` acceptance run; gated 0 by default but ALL toggles ON on ADR-0018 acceptance)
**Deduction:** -10

**Where:**

- `do/samples/create_va_g11_sample_v1.doh:60` — `include do/samples/create_diff_school_prop.doh`
- `do/samples/create_va_g11_sample_v1.doh:63` — `include do/samples/create_prior_scores_v1.doh`
- `do/samples/create_va_g11_sample.doh:49`, L52 — same pattern
- `do/samples/create_va_g11_sample_v2.doh:43`, L46 — same pattern (`_v2`)
- `do/samples/create_va_g11_out_sample_v1.doh:50`, L53 — same pattern
- `do/samples/create_va_g11_out_sample.doh:49`, L52 — same pattern
- `do/samples/create_va_g11_out_sample_v2.doh:43`, L46 — same pattern (`_v2`)

The chain at runtime:

1. main.do starts; CWD = `$consolidated_dir`.
2. main.do invokes `do do/samples/create_score_samples.do` at L213 (gated by `do_create_samples`).
3. create_score_samples.do:169 executes `cd $vaprojdir` — CWD now `$vaprojdir`.
4. create_score_samples.do:206 `include $consolidated_dir/do/samples/create_va_g11_sample_\`version'.doh` (absolute — resolves).
5. The .doh file at L60 executes `include do/samples/create_diff_school_prop.doh` — RELATIVE, resolves to `$vaprojdir/do/samples/create_diff_school_prop.doh` — DOES NOT EXIST.

This is the same regression class the touse_va.do ledger row (line 42) explicitly UPGRADED from: "rev'd post-batch-2c bugfix (3 broken consolidated relative includes -> $consolidated_dir/...)". The 6 .doh helpers above were missed in the batch-2c sweep.

Counter: the include comments in the .doh headers (e.g., create_va_g11_sample_v1.doh L38-42) explicitly document "L8: `include do_files/sbac/create_diff_school_prop.doh` -> `include do/samples/create_diff_school_prop.doh` (CANONICAL)". So the relocation was intentional but the relative-path-after-cd interaction was not anticipated. Per ledger row 47 (`legacy-include-macro-trace` for create_score_samples.do, "UPGRADED from ASSUMED"), only the top-level merge helpers (merge_loscore, merge_sib, etc.) were verified; the v1/v2 g11_sample fragments weren't separately rechecked.

**Practical impact:** Default `do_create_samples = 0` (main.do L197), so the bug doesn't fire on a normal dev run. ADR-0018 acceptance criteria say "all toggles on" — so this WILL fire on the acceptance run.

**Recommended fix:** Repoint all 12 relative includes in the 6 .doh files to absolute `$consolidated_dir/do/samples/...`.

---

### MINOR — Hardcoded absolute path in macros_va.doh:103

**Severity:** Minor (line is unused; verified by grep `\`ca_ed_lab'`)
**Deduction:** -2

**Where:** `do/va/helpers/macros_va.doh:103` — `local ca_ed_lab "/home/research/ca_ed_lab" ;`

Predecessor-preserved local that's never referenced elsewhere in the codebase (grep returns no matches outside this file). Documented as inherited verbatim from cde_va_project_fork per the relocation header (L40-60). Not a runtime bug, but a `no-hardcoded-paths` check that should ideally pass uniformly across all helpers.

**Recommended fix:** Either delete the unused local OR refactor to derive from `$consolidated_dir/..` — but the analysis-logic-verbatim guarantee per ADR-0021 sandbox amendment argues for leaving as-is. Defensible to leave.

---

### MINOR — Missing ledger row for do/sibling_xwalk/siblingoutxwalk.do

**Severity:** Minor (adversarial-default protocol; -10 default but reduced — file is well-documented + the ledger has a precedent row at line 100 for prior_decile_original_sample.do covering the same `$projdir` aliasing pattern)
**Deduction:** -5

**Where:** `.claude/state/verification-ledger.md` has no rows for `do/sibling_xwalk/siblingoutxwalk.do`. Per adversarial-default rule deduction table, "Required ledger row missing for an inherited script (not authored in-session) -10 per missing row." 3 check classes (no-hardcoded-paths, adr-0021-sandbox-write, legacy-include-macro-trace) would have a row each = -30 nominal, but the file is well-documented in commit messages + the round-1 coder-critic review on its first relocation (L86-88 of the file header) records the relevant verification evidence. The header documentation is a partial substitute for ledger rows but not a complete one.

**Recommended fix:** Backfill 3 ledger rows for siblingoutxwalk.do; particularly the `legacy-include-macro-trace` row, which would have helped catch the `sibling_out_xwalk` chain break in Finding 1 by recording that the local-binding-site for the consumer chain wasn't verified.

---

### MINOR — `cd $vaprojdir` pattern as documentation drift

**Severity:** Minor
**Deduction:** -2

23 of 25 do/va files execute `cd $vaprojdir` near the top and restore `cd "$consolidated_dir"` at the bottom. The pattern is justified at scale in the headers as "predecessor pattern; some helpers may rely on CWD"; verified empirically across all files. But this means any include in those files MUST use an absolute path (the helper-include-absolute ledger rows confirm 24/25 do so). The 6 .doh helpers under do/samples/ that have relative includes (Finding 5) are downstream of this same pattern — the `cd` makes relative includes a regression risk class on every relocated file. The convention should be documented somewhere as a hard rule with a per-commit check.

**Recommended fix:** Add to phase-1-review.md §2 Tier-1 checklist: "After any `cd $vaprojdir`, every `include`/`do` must use an absolute `$consolidated_dir/...` path." (Already partially covered by ledger `helper-include-absolute`, but not for relative-include patterns inside helper-of-helper files.)

---

### MINOR — t1_empirical_tests.do log target not under $logdir

**Severity:** Minor (covered substantively in Finding 4; this is the orthogonal aspect — even if t1 is archived/excluded, the log routing is still unsubmissive to settings.do)
**Deduction:** -2

`do/check/t1_empirical_tests.do:62-65` writes its log to `log_files/check/...` (relative; predecessor layout). If anyone DOES run this file from inside consolidated/, the log lands under `consolidated/log_files/`, not `consolidated/log/` (`$logdir`). The header documents this as intentional (L36-47), but the convention is inconsistent with every other do file in the partition.

**Recommended fix:** Either archive (per Finding 4) or repoint the log target to `$logdir/`.

---

## Score Breakdown

- Starting: 100
- CRITICAL: sibling_out_xwalk chain break: -15
- CRITICAL: score_b.dta reader path wrong in 3 check files: -15
- MAJOR: categoryindex reader path wrong in check_survey_indices: -10
- MAJOR: t1_empirical_tests breaks check_logs invariant: -10
- MAJOR: 6 .doh files have relative includes that break after cd: -10
- MINOR: hardcoded path in macros_va.doh:103 (unused): -2
- MINOR: missing ledger rows for siblingoutxwalk.do: -5
- MINOR: cd $vaprojdir as documentation drift: -2
- MINOR: t1 log routing not under $logdir: -2
- Sandbox-write discipline (ADR-0021): +0 (no LEGACY writes — what got verified)

**Final: 73/100** — BLOCK (hard gate 80)

---

## Top 3 Findings by Severity

1. **CRITICAL** — `do/va/helpers/macros_va.doh:110` binds `sibling_out_xwalk` local to LEGACY `$caschls_projdir/dta/siblingxwalk/sibling_out_xwalk`, but producer `do/sibling_xwalk/siblingoutxwalk.do:338` writes to CANONICAL `$datadir_clean/siblingxwalk/sibling_out_xwalk`. Active consumers in `do/samples/merge_sib.doh:66` and `do/share/sample_counts_tab.do:118` read STALE LEGACY data, silently. -15 deduction.

2. **CRITICAL** — 3 check files (`check_samples.do:71`, `check_merges.do:66`, `check_paper_outputs.do:67`) read from `$estimates_dir/va_samples_v1/score_b.dta` but producer writes to `$datadir_clean/va_samples_v1/score_b.dta`. The `capture confirm file` shim silently SKIPS the check on the acceptance run — producing false-confidence "skeleton" output instead of real validation. -15 deduction.

3. **MAJOR** — 6 `.doh` files in `do/samples/` (`create_va_g11_{sample,out_sample}{,_v1,_v2}.doh`) have relative `include do/samples/create_{diff_school_prop,prior_scores_v1,prior_scores_v2}.doh` lines that resolve to `$vaprojdir/do/samples/...` (doesn't exist) after caller `cd $vaprojdir`. Gated 0 by default but fires on ADR-0018 all-toggles-on acceptance run. -10 deduction.

---

## Compliance Evidence (from .claude/state/verification-ledger.md)

Sample of consulted rows for in-scope files:

- `do/va/va_score_all.do | no-hardcoded-paths` | 2026-05-07T23:30Z | `8f4df08c6a6d` | PASS | grep returned 0 matches — verified
- `do/va/va_score_all.do | adr-0021-sandbox-write` | 2026-05-07T23:30Z | `8f4df08c6a6d` | PASS | 5 estimates/save calls CANONICAL — verified
- `do/va/va_score_all.do | helper-include-absolute` | 2026-05-07T23:30Z | `8f4df08c6a6d` | PASS — verified
- `do/va/va_out_all.do | dependency-chain-integrity` | 2026-05-07T23:30Z | PASS | merge at L232 reads exact-match path va_score_all.do:251 writes — verified, supports chain coordination for VA estimation
- `do/samples/touse_va.do | no-hardcoded-paths` | 2026-05-07T22:00Z | PASS | rev'd post-batch-2c bugfix (3 broken consolidated relative includes fixed) — relevant precedent for Finding 5
- `do/samples/create_score_samples.do | legacy-include-macro-trace` | 2026-05-07T22:00Z | PASS | UPGRADED from ASSUMED (batch 2c relocated all 4 sbac merge helpers in-repo) — relevant context; this row did NOT extend to the 6 .doh helpers in Finding 5
- `do/samples/merge_sib.doh | adr-0021-sandbox-write` | 2026-05-07T22:00Z | PASS | "reads `sibling_out_xwalk' via parent-scope local" — recorded the parent-scope dependency but did not verify which path the local resolves to (chain coordination not in scope of this check class)
- `do/check/check_samples.do | adr-0021-sandbox-write` | 2026-04-29T18:55Z | `dfec994cd69b` | PASS — verified for WRITE side, but the check class did not verify reader path matches producer path
- `do/check/check_merges.do | adr-0021-sandbox-write` | 2026-04-29T18:55Z | PASS — same as above
- `do/check/check_paper_outputs.do | design-memo-fidelity` | 2026-04-29T18:55Z | ASSUMED | "Most cells TBD-codebook per design memo §6 + §9" — the ASSUMED-cost classification correctly flagged that this check is incomplete, but the score_b reader-path bug was not surfaced
- `do/check/check_survey_indices.do | adr-0021-sandbox-write` | 2026-04-29T18:55Z | PASS — verified for WRITE side
- **MISSING:** `do/sibling_xwalk/siblingoutxwalk.do` — no rows; flagged in Finding 7
- **MISSING:** `do/va/helpers/macros_va.doh` (the binding-site for `sibling_out_xwalk`) — no rows for `chain-coordination` check class

**Observation:** Every ledger PASS row for the check_*.do files covers `no-hardcoded-paths`, `no-raw-data-overwrites`, `adr-0021-sandbox-write`. None cover `producer-consumer-path-match` or any chain-coordination invariant. The 3 critical chain coordination defects in this partition are precisely the class of bug the existing check classes don't detect. This is a procedural gap in the verification-ledger schema, not an authorship failure — but it's how the score_b.dta + categoryindex.dta + sibling_out_xwalk regressions slipped through 11 prior coder-critic reviews.

**Recommended ledger-schema addition:** A `chain-coordination` check class verifying that every reader-side path local/global resolves to a producer-side path in the consolidated pipeline (not LEGACY). Trace: for each `use $X/...`, `merge ... using $X/...`, `local foo "$X/..."` consumed by `using \`foo''`, verify `$X` is a CANONICAL global and the path is written by some other do file in the active pipeline.

---

## Verdict

**BLOCK at 73/100. Hard gate is 80.**

The 3 chain-coordination defects (`sibling_out_xwalk` chain, 3 check files reading wrong score_b path, 1 check file reading wrong categoryindex path) will either produce silent stale-data reads (sibling_out_xwalk) or silent skipped-check false confidence (3 check files + 1 sub-block) on the ADR-0018 acceptance run. None of these would fire on a Phase 2-toggles-off dev run, but the acceptance criteria require all toggles ON.

The 6 .doh files with relative-includes-after-cd are gated 0 by default but fire on `do_create_samples = 1` (acceptance).

Recommended path forward: address Findings 1, 2, 3, 4, 5 (the 5 Critical+Major findings) before kicking off the M4 golden-master. Findings 6-9 (Minor) can be deferred to Phase 1c.

## Escalation Status: None (Strike 0 of 3)

This is the first review on this partition. No prior coder-critic reviews exist for the union of `do/va/` + `do/samples/` + `do/sibling_xwalk/` + `do/check/` as a holistic partition. Per-batch reviews covered individual files but did not cross-cut producer-consumer chains across step boundaries — which is exactly where these defects emerged.
