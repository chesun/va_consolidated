# Server Pipeline Run — Log Review

**Date:** 2026-06-08
**Reviewer:** Claude (run-log verification, not a critic dispatch)
**Target:** `e968d13` "server pipeline run" — master log `log/main_-1-Jun-2026_21-30-55.{smcl,log}`
**Verdict:** Pipeline ran START → END (confirmed). 22 data-check PASS, **2 FAIL**, 1 SOFT. Plus a confirmed harness bug (FAIL checks don't halt).
**Status:** Active

---

## 1. Did the whole pipeline run start to end? — YES (confirmed)

Evidence from the most recent master log (`log/main_-1-Jun-2026_21-30-55.log`):

| Signal | Value |
|---|---|
| Host / Stata | `scribe` / Stata 18, user `chesun1` |
| Mode | `m4_acceptance_run = 1` — full end-to-end rebuild (samples + VA estimated from scratch, not cached) |
| RUN START | 1 Jun 2026 21:30:55 |
| RUN END | **3 Jun 2026 03:01:24** (~29.5 h wall-clock) |
| Phase banners | PHASE 1 → 2 → 3 → 4 (intentional no-op) → 5 → 6 → 7 — all present, in order |
| `[RUN]` / `[OK]` markers | **206 / 206** — every invoked script completed; last pair = `check_paper_outputs.do` |
| Fatal Stata errors (`r(NNN);`) in this run's per-file logs | **none** (the only `r(111);` hits are in `log/main.log`, a STALE file opened 17 May 2026, last committed `d0991f2` on 2026-05-17 — NOT part of this run) |

Conclusion: the run reached the WRAP-UP block (RUN END banner + master-log translate, which is why the `.log` exists). No phase aborted.

## 2. Data checks (Phase 7) — 22 PASS, 2 FAIL, 1 SOFT

| Check | PASS | FAIL | SOFT |
|---|---|---|---|
| check_logs | 1 | 0 | 0 |
| check_samples | 11 | 0 | 1 |
| check_merges | 4 | 0 | 0 |
| check_va_estimates | 2 | **1** | 0 |
| check_survey_indices | 2 | **1** | 0 |
| check_paper_outputs | 2 | 0 | 0 |

Headline PASSes confirm the core numbers are intact: total g11 student-years `_N == 1,784,445`; cohort N's 2015–2018 all match (402416 / 406084 / 450201 / 525744); `k12_main _N == 5009` (89% retention); all VA column means `|mean| < 0.05`; `va_ela_b_sp_b_ct` SD ∈ [0.05, 0.30]; survey item counts match ADR-0010 (climate=9, quality=15, support=4); paper Table 1 N == 1,784,445 and Table 2 schools == 5,009.

### FAIL 1 — `check_va_estimates`
```
FAIL: n_g11_ela_l_sp has min student-year count = 4 — below CFR minimum 5
```
At least one VA cell for the `n_g11_ela_l_sp` count variable has only 4 student-years, below the CFR drift-shrinkage minimum of 5. A 4-student cell yields a noisy VA estimate. Needs investigation: is it a sample-filter gap, or an expected thin cell that should be dropped?

### FAIL 2 — `check_survey_indices`
```
FAIL: imputed secqoi27mean_pooled max = 2.6133 (expected ∈ [0, 2.01])
```
The multiply-imputed secondary QOI item 27 produced a value (2.61) above the Likert ceiling (2.01). Imputation is not bounded to the valid range. Could distort that index; investigate whether to clamp/winsorize imputed values to the Likert band.

### SOFT — `check_samples`
```
SOFT: 7486 rows have age outside [5478, 6940] days (~15-19 yrs)
        upstream age-encoding may be corrupted; investigate but not halting.
```
~7.5k g11 student-years fall outside the expected 15–19 yr age band. Flagged by design as non-halting; worth a look upstream.

## 3. Confirmed harness bug — "hard" checks report FAIL but do not halt

`check_va_estimates.do` and `check_survey_indices.do` intend to hard-halt on failure (main.do header: "A failed assert halts the pipeline at the offending check"). Every fail-branch in both files does:

```stata
capture assert <condition>
if _rc {
    di as error "  FAIL: ..."
    cap log close <name>          // <-- resets _rc
    cap translate "...smcl" "...log", replace   // <-- resets _rc to 0 on success
    exit _rc                       // <-- exits 0, pipeline CONTINUES
}
```

Because the two `cap` commands run between the failure detection and `exit _rc`, `_rc` is 0 (the rc of the successful `cap translate`) by the time `exit _rc` runs. The check exits cleanly, main.do prints `[OK]`, and the pipeline proceeds. This is why the run reached RUN END despite two FAILs (verified against the echoed source at `check_va_estimates.do:127-132` and `check_survey_indices.do:163-175`).

**Implication:** RUN END / exit-0 / balanced `[RUN]`/`[OK]` is NOT sufficient to conclude "all checks passed" — the check logs must be read. (This is why this review read them.)

**Fix candidate:** capture the failure rc into a local before the `cap` lines, e.g. `local rc = _rc` right after the assert, then `exit `rc'` (or move `cap log close`/`cap translate` after computing the exit code; or use `error 9`). Applies to every fail-branch in both files.

## 4. Recommended next steps (for user decision)

1. Investigate FAIL 1 (4-student VA cell) — sample filter vs expected thin cell.
2. Investigate FAIL 2 (imputed survey value > Likert ceiling) — bound imputation to valid range.
3. Decide whether the age SOFT (7486 rows) needs an upstream fix.
4. Fix the `_rc`-clobber in the two checks so future bad runs actually halt (separate, code-level; phase-1-review coder-critic applies since it touches `do/check/*.do`).

Items 1–2 do not invalidate the run's outputs but flag two data-quality issues to resolve before the outputs are treated as final.
