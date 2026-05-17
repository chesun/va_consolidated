# Pre-Flight M4 Synthesis — Go/No-Go Before Scribe Pipeline Run

**Date:** 2026-05-16
**Reviewer:** orchestrator-synthesis (4 parallel coder-critic dispatches)
**Target:** entire consolidated do/ tree (110 active .do files) — pre-flight before Phase 1a §3.5 M4 golden-master
**Score (weighted by partition file count):** 83/100
**Status:** Active
**Verdict:** **NO-GO** — fix 3 Critical chain regressions before M4

---

## TL;DR

**Christina's pre-flight call was the right one.** The holistic audit caught what 27 per-batch reviews missed: when each batch saw only its own files, the Step-11 chain-coordination check ran on each batch's local writes — but a producer relocated in Step N's batch can have consumers in Step M's batch that nobody re-grepped after Step M had already completed.

Result: **3 CRITICAL chain regressions across 9 files** (12 lines to fix). All match the same regression class — producer writes CANONICAL post-relocation, consumer still reads LEGACY. M4 would still "succeed" superficially (Stata won't error on a LEGACY read), but downstream tables would silently consume stale predecessor data and `diff -r consolidated/output predecessor/output` would falsely report behavioral equivalence on those rows.

---

## Per-partition scores

| Partition | Scope | Files | Score | Verdict | Critical findings |
|---|---|---:|---:|---|---:|
| A | main.do + settings.do + wiring | 2 | 92/100 | PASS | 0 |
| B | va/ + samples/ + sibling_xwalk/ + check/ | 36 | 73/100 | **BLOCK** | 2 |
| C | data_prep/ | 40 | 91/100 | PASS | 0 |
| D | share/ + survey_va/ + explore/ | 32 | 78/100 | **BLOCK** | 1 |
| **Weighted mean** | full active tree | 110 | **83/100** | **NO-GO** | **3** |

Reports:
- `quality_reports/reviews/2026-05-16_pre-flight-A_main-settings_coder_review.md`
- `quality_reports/reviews/2026-05-16_pre-flight-B_va-samples-xwalk-check_coder_review.md`
- `quality_reports/reviews/2026-05-16_pre-flight-C_data-prep_coder_review.md`
- `quality_reports/reviews/2026-05-16_pre-flight-D_share-surveyva-explore_coder_review.md`

---

## Sandbox-write discipline — PASS pipeline-wide

**Zero LEGACY-WRITE violations** confirmed across all 110 active files. All 6 `$vaprojdir` pre-scan hits in active code resolved to header `RELOCATION HISTORY` comments, not live writes. The 27 LEGACY-write hits in the repo are all in `do/_archive/` (dead per ADR-0004) and not invoked from main.do.

**This is the failure mode that would have corrupted the shared Scribe filesystem. It is closed.**

---

## Critical chain regressions to fix before M4

All 3 are the same pattern: producer relocated and now writes CANONICAL, but at least one consumer still reads LEGACY. Total: 9 files, 12 line-edits.

### CRITICAL-1: `analysisready.dta` chain (Partition D)

**Producers (CANONICAL):**
- `do/data_prep/poolingdata/secpooling.do:160` writes `$datadir_clean/calschls/analysisready/secanalysisready.dta`
- `do/data_prep/poolingdata/parentpooling.do:152` writes `$datadir_clean/calschls/analysisready/parentanalysisready.dta`
- `do/data_prep/poolingdata/mergegr11enr.do:93` writes `$datadir_clean/calschls/analysisready/staffanalysisready.dta`

**Consumers still reading LEGACY `$caschls_projdir/dta/buildanalysisdata/analysisready/`:**
- `do/survey_va/factor.do:74, 92, 110`
- `do/survey_va/pcascore.do:65, 74, 83`
- `do/share/svyvaregs/allvaregs.do:113` (templated read)

**Step 11 fixed 4 sister files (`imputation`, `compcasecategoryindex`, `indexregwithdemo`, `indexhorseracewithdemo`) reading the same producer set but missed these 3.** `allvaregs.do` is paper-shipping per `main.do:407` (Table 8 inputs).

**Fix:** 7 single-line edits across 3 files. Per-file INPUTS header section also needs updating.

### CRITICAL-2: `sibling_out_xwalk` chain (Partition B)

**Producer (CANONICAL):**
- `do/sibling_xwalk/siblingoutxwalk.do:338` writes `$datadir_clean/siblingxwalk/sibling_out_xwalk`

**Consumer-side bind still LEGACY:**
- `do/va/helpers/macros_va.doh:110` binds the consumer-side local to `$caschls_projdir/dta/siblingxwalk/sibling_out_xwalk`

**Propagates to active consumers:**
- `do/samples/merge_sib.doh:66` (uses the bound local)
- `do/share/sample_counts_tab.do:118` (uses the bound local)

**Fix:** repoint the bind in `macros_va.doh:110` from `$caschls_projdir/dta/siblingxwalk/` to `$datadir_clean/siblingxwalk/`. Consumers inherit automatically.

### CRITICAL-3: `score_b.dta` parent-path drift in check files (Partition B)

**Producer (CANONICAL):**
- `$datadir_clean/va_samples_v1/score_b.dta` (per producer's CANONICAL write)

**Check-file consumers reading wrong parent `$estimates_dir/va_samples_v1/score_b.dta`:**
- `do/check/check_samples.do:71`
- `do/check/check_merges.do:66`
- `do/check/check_paper_outputs.do:67`

**Why this is silently dangerous:** the `capture confirm file` shim wraps each check so a missing file does not error — it **silently skips**. So the M4 acceptance run would report "checks PASS" on output that wasn't actually checked. Headers in each check file also encode the wrong path.

**Fix:** 3 single-line edits (path) + 3 header updates. Same fix-class as CRITICAL-1.

---

## Major findings (deferrable but should be acknowledged)

These do not block M4 but should land before `v1.0-final`:

| # | Partition | Severity | File / Issue | Impact |
|---|---|---|---|---|
| Mj-1 | B | Major (-10) | `check_survey_indices.do:197` reads `$estimates_dir/calschls/categoryindex/...` but producers write `$datadir_clean/survey_va/categoryindex/...` | Silent check skip (same shim as C-3) |
| Mj-2 | B | Major (-10) | `do/check/t1_empirical_tests.do` is predecessor-layout one-off, not invoked from main.do | Would fail `check_logs.do` invariant on `run_data_checks=1` acceptance run |
| Mj-3 | B | Major (-10) | 6 `.doh` files in `do/samples/` use `include do/samples/...` (relative) — breaks if caller `cd $vaprojdir` | Gated 0 by default; fires on all-toggles-on acceptance per ADR-0018 |
| Mj-4 | C | Major (-5) | `do/data_prep/schl_chars/clean_charter.do:75,105` Mac-only branch writes relative `data_local/...` | Dead on Scribe; sandbox-discipline gap |
| Mj-5 | D | Major (-5) | CONVENTIONS section absent across all 32 D-files (also flagged in A/B/C — workflow-wide) | Documentation drift, no behavior bug |
| A-M1 | A | Minor (-3) | main.do:332-335 claims Phase 4 holds VA-share producers but block is empty; Phase 6 has them | Runtime impact 0 with defaults; future-dev confusion |

---

## Minor findings (very-low priority)

- A-M3 (-2): Phase 7 data-checks block is empty stub. Documented Phase 1c §5.3.
- A-M2 (-1) / ledger drift on main.do/settings.do PASS rows — re-verified directly this session.
- B-Mi-1 (-2): `cd $vaprojdir` documentation drift + t1 log routing not under `$logdir`.
- B-Mi-2 (-5): Missing ledger rows for `do/sibling_xwalk/siblingoutxwalk.do`.
- B-Mi-3 (-2): Hardcoded path `/home/research/ca_ed_lab` at `macros_va.doh:103` (local unused — verified).
- C-Mi-1 (-2): 4 files missing `cap` prefix on `log close _all` (`cds_nces_xwalk.do:53`, `clean_charter.do:53`, `clean_ecn_disadv.do:52`, `clean_locale.do:51`).
- C-Mi-2 (-2): Year-set partition documentation drift in `prepare/renamedata.do` and `prepare/splitstaff0414.do`.
- D-Mi-1 (-1): Hardcoded path at `mattschlchar.do:69` (gated dormant via `if clean == 1`, disclosed in header per ADR-0013).
- D-Mi-2 (-1): Hardcoded paths at `k12_nsc2019_merge.doh:67, 82` (dormant helper, not invoked from main.do).

---

## Recommended next steps

1. **Fix the 3 Criticals now** (12 line-edits across 9 files):
   - `do/va/helpers/macros_va.doh:110` — repoint bind from `$caschls_projdir/dta/siblingxwalk/` to `$datadir_clean/siblingxwalk/`
   - `do/survey_va/factor.do:74, 92, 110` — repoint `analysisready` reads to `$datadir_clean/calschls/analysisready/`
   - `do/survey_va/pcascore.do:65, 74, 83` — same
   - `do/share/svyvaregs/allvaregs.do:113` — same
   - `do/check/check_samples.do:71` — repoint `score_b.dta` parent to `$datadir_clean/va_samples_v1/`
   - `do/check/check_merges.do:66` — same
   - `do/check/check_paper_outputs.do:67` — same
   - Plus header INPUTS section updates for each affected file
2. **Commit + push** the fix with `coder-critic: PASS (re-verify)` footer.
3. **Re-dispatch Partitions B + D** (since C and A were PASS) to confirm fixes hold and score ≥ 90.
4. **Then run M4 golden-master** on Scribe.
5. **Defer Majors and Minors to Phase 1c §5.4** polish (per TODO Phase 1c §5.1 cosmetic cleanup track).
6. **Add `check_chain.do` to §5.3 data-checks** to flag producer-CANONICAL/consumer-LEGACY pairs systematically (Partition C recommendation; would prevent future regressions of this class as the only failure mode that's now established).

---

## Why this matters

The Step 11 cross-step chain coordination produced 2 BONUS catches (schlcharpooledmeans) precisely because Christina extended the coordination check across step boundaries. **This audit found 3 more cases where that coordination was incomplete** — across `analysisready`, `sibling_out_xwalk`, and `score_b`. Each would have produced a silent stale-data consumption on M4. None would have raised a Stata error. The golden-master diff would have falsely reported failure or, worse, falsely reported pass on rows that consumed mismatched inputs.

The 12 line-edits are mechanical. The validation that the consolidation is otherwise sound is real: sandbox-write discipline is fully closed, main.do wiring is sane, helper-doh include trace pattern holds, and the only remaining work is the chain-regression cleanup.
