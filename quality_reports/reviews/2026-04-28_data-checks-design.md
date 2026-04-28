# Data-Checks Pipeline Design — Phase 1c §5.3

**Date:** 2026-04-28
**Source:** `master_supporting_docs/codebooks/codebook_export_28-Apr-2026_13-25-41.log` (sanitized; gitignored per `.gitignore` 2026-04-28 entry)
**Plan ref:** `quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md` §5.3
**Status:** DRAFT — locks the assertions/bounds the future `do/check/check_*.do` files will encode.

This memo translates what the codebook revealed into a per-check-file specification. Each subsection maps to one `do/check/check_*.do` file. Where a bound or invariant comes from the codebook, the line range is cited.

---

## 1. Dataset inventory (post-PII-scrub)

| Tag | Path (resolved) | N | Vars | Granularity |
|---|---|---|---|---|
| `calschls_1` | `$projdir/dta/allsvyfactor/imputedallsvyqoimeans.dta` | 5,625 | 957 | School-level; imputed pipeline; weighted means over years |
| `calschls_2` | `$projdir/dta/allsvyfactor/allsvyqoimeans.dta` | 5,625 | 912 | School-level; complete-case pipeline |
| `k12_main` | `$vaprojdir/estimates/va_cfr_all_v1/va_est_dta/va_all_schl_char.dta` | 5,009 | 996 | School-level VA × samples × controls (post-`va_het.do`) |
| `k12_pre_va` | `$vaprojdir/data/va_samples_v1/score_b.dta` | 1,784,445 | 77 | Student-year, g11, cohorts 2015-18 |
| `sch_char` | `$vaprojdir/data/sch_char.dta` | 81,595 | 37 | School-year (2015-19, all CA schools) |
| `nsc` | `$vaprojxwalks/nsc_outcomes_crosswalk_ssid.dta` | 4,842,346 | 59 | All NSC-matched CA students |
| `k12_ccc_xw` | `$vaprojxwalks/k12_ccc_crosswalk.dta` | 3,217,358 | 2 post-scrub | Bridge — informative cols PII-stripped |
| `ccc` | `$vaprojxwalks/ccc_outcomes_crosswalk.dta` | 31,098,744 | 17 | All CA CCC enrollees ever |
| `k12_csu_xw` | `$vaprojxwalks/k12_csu_crosswalk.dta` | 1,420,209 | 2 post-scrub | Bridge — informative cols PII-stripped |
| `csu` | `$vaprojxwalks/csu_outcomes_crosswalk.dta` | 5,099,956 | 50 | All CA CSU enrollees ever |

**Key resolved questions from the codebook:**

- `score_b` is g11-only by construction (`grade==11` for all 1.78M rows) — `check_samples.do` can `assert grade == 11` instead of subsetting.
- 4 analytic cohorts confirmed: 2015 (402,416), 2016 (406,084), 2017 (450,201), 2018 (525,744). Counts give a hard tolerance for the per-cohort assertion.
- 1,389 unique schools in `score_b` vs 5,009 schools in `k12_main` vs 5,625 schools in CalSCHLS — CalSCHLS is the broadest school sample, k12_main filters to VA-estimable schools, `score_b` filters further to schools with g11 in 2015-18. The drop pattern is meaningful, not anomalous.
- CalSCHLS QOIs are coded on a **-2 to +2 scale** (e.g., `parentqoi9mean_pooled` range = [-2, 2], mean ≈ 1.22 — strongly-disagree to strongly-agree centered at 0). NOT 1-4 or 1-5 as initially assumed. Index z-scores derived from these will have mean 0, SD 1 by construction.
- 45 unique source survey items: 11 parent QOIs (9, 15, 16, 17, 27, 30, 31, 32, 33, 34, 64) + 19 sec QOIs (22-40 sequential) + 15 staff QOIs (10, 20, 24, 41, 44, 64, 87, 98, 103, 104, 105, 109, 111, 112, 128). ADR-0010's "9 / 15 / 4" item counts must refer to *subsets* selected by `imputedcategoryindex.do` / `compcasecategoryindex.do`, not the totals. Identifying the exact subsets is a Phase 1c task — read the constructor scripts at edit time.

---

## 2. `check_samples.do`

**Inputs:** `score_b.dta` (`k12_pre_va`).
**Purpose:** assert the analytic sample is structurally what we expect before any VA estimation runs.

### Hard `assert` invariants

```stata
* sample size + structure
assert _N == 1784445                                      // total g11 student-years
assert grade == 11                                        // g11-only
assert inrange(year, 2015, 2018)                          // 4-cohort window

* per-cohort counts (from codebook line 73020)
qui count if year == 2015 & assert r(N) == 402416
qui count if year == 2016 & assert r(N) == 406084
qui count if year == 2017 & assert r(N) == 450201
qui count if year == 2018 & assert r(N) == 525744

* uniqueness — 1389 schools per audit + codebook line 73040
qui levelsof cdscode, local(cds_n)
assert `: word count `cds_n'' == 1389

* race dummies orthogonal + cover (mean of indicator-sum should be 1.0 for non-missing)
egen eth_sum = rowtotal(eth_asian eth_hispanic eth_black eth_white eth_other)
assert inlist(eth_sum, 0, 1)
drop eth_sum

* binary-coded demographics in {0, 1, .}
foreach v in econ_disadvantage male limited_eng_prof disabled              ///
             eth_asian eth_hispanic eth_black eth_white eth_other          {
    capture assert inlist(`v', 0, 1, .)
    if _rc {
        di as error "  binary-coded var `v' has values outside {0, 1, .}"
    }
}
```

### Soft signals (`display as error`, non-halting)

- `assert age >= 5478 & age <= 6940` — codebook range was [-14, 43099] with 5,483 missings. Plausible age-on-Jan-1 in days for g11 students = ~16 yrs = ~5,840 days. Anything outside [15, 19] yrs = [5478, 6940] days is suspicious; soft-flag rather than halt.
- Cohort-size range from `cohort_size` should fall within [11, 1325] per codebook (line 73086).

### Codebook references

- `score_b` describe: lines 72841-72950
- `cohort_size` codebook: 73075-73093
- year/grade/cdscode codebooks: 72983-73070

---

## 3. `check_merges.do`

**Inputs:** `va_all_schl_char.dta` (`k12_main`) plus the merge-result columns from `score_b.dta`.
**Purpose:** assert post-merge join rates against historical baselines from the audit + codebook.

### Hard `assert` invariants

```stata
* score_b merge results — `_merge` flags from upstream merges
* (cf. score_b cols merge_grade_span, merge_cohort_size, merge_public_schools)
foreach m in merge_grade_span merge_cohort_size merge_public_schools {
    qui inspect `m'
    assert `r(N_unique)' <= 5    // _merge values 1..5
}

* k12_main keeps schools with VA estimable; check N drop is sensible
* (5,625 calschls schools → 5,009 k12_main schools = 89% retention)
assert _N == 5009                  // schools in k12_main
```

### Codebook-derived bounds (TBD-codebook-merge — needs production-run baseline)

- K12 ↔ NSC merge rate: TBD-codebook (run baseline once, then bound as `±0.5pp`).
- K12 ↔ CCC bridge match: codebook `k12_ccc_crosswalk.dta` shows `match_level ∈ {1, 2, 3, 4}` with freqs (2.21M, 63K, 918K, 27K). Match-level 1 = exact match; higher = fuzzier. Bound the share of match_level==1 against historical (~68.7%).
- K12 ↔ CSU bridge: similar logic; smaller universe (1.42M vs 3.22M for CCC).

### Codebook references

- `k12_ccc_xw` describe: lines 77150-77179 (2 informative vars post-scrub)
- `k12_ccc_xw` `match_level` tabulation: lines 77317-77321
- `nsc` describe (59 outcome cols): lines 75743-75824

---

## 4. `check_va_estimates.do`

**Inputs:** `va_all_schl_char.dta` (`k12_main`).
**Purpose:** verify VA estimates are structurally well-formed and within paper-reported magnitude bands.

### Variable inventory (from codebook lines 47369-47442)

VA columns follow `va_<subj>_<sample>_sp_<ctrl>_ct[_p]` pattern:
- `<subj>` ∈ {`ela`, `math`}
- `<sample>` ∈ {`b`, `l`, `a`, `s`, `la`, `ls`, `as`, `las`} (8 samples; matches audit chunk-3)
- `<ctrl>` ∈ {`b`, `l`, `a`, `s`} (kitchen-sink controls)
- `_ct` = "controls" suffix; `_p` = "with peer controls" suffix
- Companion `n_g11_<subj>_<sample>_sp` = student-year count per spec

### Hard `assert` invariants

```stata
* main-spec VA centered (school-level VA ≈ 0 by construction after BLUP shrinkage)
foreach v of varlist va_ela_*_ct va_math_*_ct va_*_ct_p {
    qui sum `v'
    assert abs(r(mean)) < 0.05    // tight tolerance — paper says school VA centered
}

* paper-reported SD bound: VA SD ~0.10-0.15 σ (paper Tables 2-3)
qui sum va_ela_b_sp_b_ct
assert inrange(r(sd), 0.05, 0.30)    // wide tolerance; halt only on absurd values

* per-spec student-year counts non-zero
foreach v of varlist n_g11_ela_*_sp n_g11_math_*_sp {
    qui sum `v'
    assert r(min) >= 5    // CFR-style estimator needs minimum cell size
}
```

### Soft signals

- Cross-spec correlation (`va_ela_b_sp_b_ct` vs `va_ela_l_sp_l_ct`): expected ~0.85+ per chunk-3 audit; soft-flag if <0.7.
- `_p` (peer controls) vs no-`_p` correlations: expected very high (~0.97); soft-flag if <0.9.

### Codebook references

- `k12_main` describe: lines 47325-48951 (1626 lines)
- VA columns: visible at 47373-47442

---

## 5. `check_survey_indices.do`

**Inputs:** both CalSCHLS source files (`imputedallsvyqoimeans.dta`, `allsvyqoimeans.dta`) + the BUILT index files (`$projdir/dta/allsvyfactor/categoryindex/imputedcategoryindex.dta`, same path with `compcase` prefix).
**Purpose:** verify source items are within Likert range and built indices are well-formed z-scores.

### Hard `assert` invariants on source

```stata
* source-item Likert range — codebook line 1415: parentqoi9mean range [-2, 2]
* (5-point Likert centered at 0)
foreach v of varlist parentqoi*mean_pooled secqoi*mean_pooled staffqoi*mean_pooled {
    qui sum `v'
    assert inrange(r(min), -2.01, 0)        // tolerance ±0.01 for floating-point
    assert inrange(r(max), 0, 2.01)
}

* school-level row count — codebook line 105 (calschls_1) + 24269 (calschls_2)
assert _N == 5625
```

### Hard `assert` invariants on built indices (post-`imputedcategoryindex.do` / `compcasecategoryindex.do`)

```stata
* per ADR-0010, three indices: counts 9 / 15 / 4 items
* (item lists in imputedcategoryindex.do — verify at edit time)
foreach idx in <index1_name> <index2_name> <index3_name> {
    qui sum `idx'
    assert abs(r(mean)) < 0.01            // z-scored
    assert inrange(r(sd), 0.95, 1.05)     // z-scored, SD ≈ 1
    assert inrange(r(min), -5, -1)        // typical z-score lower tail
    assert inrange(r(max),  1,  5)        // typical z-score upper tail
}
```

### Open question (Phase 1c task)

The exact item lists per index — the 9, 15, and 4 source QOIs that go into each — must be read from `imputedcategoryindex.do` and `compcasecategoryindex.do` at edit time. Once known, add an item-count assertion: `assert <count of items in index1> == 9` etc., per ADR-0010 / ADR-0011.

### Codebook references

- `calschls_1` parentqoi9mean_pooled: lines 1404-1422
- `calschls_1` describe: lines 101-1320 (long; 957 vars)
- 45 source QOIs enumerated above (§1)

---

## 6. `check_paper_outputs.do`

**Inputs:** the `share/` table-producer outputs (paths TBD per plan v3 §3.3).
**Purpose:** sample sizes and key magnitudes printed in paper tables match the analytic-pipeline outputs.

### Hard `assert` invariants

```stata
* Table 1 (sample): N = 1,784,445 student-years (cf. score_b)
* Table 2 (main spec): N schools = 5,009 (cf. k12_main)
* Per ADR-0010 footnote correction: indices have 9 / 15 / 4 items (NOT 20 / 17 / 4)

* Specific cells (loaded from share/ producer .tex outputs or .dta sidecars
*  if producers save them)
* TBD until plan v3 §3.3 script relocations expose the producer outputs
```

### Codebook references

- `k12_main` N: line 47349
- `score_b` N: line 72845

---

## 7. `check_logs.do`

**Inputs:** filesystem only (no Stata data).
**Purpose:** every relocated do file under `do/` produced a log on the most recent clean `main.do` run; pairs with §5.1 step 2 of the plan.

### Hard `assert` invariants

```stata
* Walk do/ recursively; for each .do file, verify $logdir/<stem>.log exists.
* If any do file is missing its log → fail-loud listing.
* Implementation TBD — likely uses `filelist, dir(do)` (from filelist .ado)
* or shell calls to `find`.
```

No codebook input — purely structural.

---

## 8. `main.do` integration

Per plan v3 §5.3 step 11, all six check files are invoked from `main.do` via:

```stata
local run_data_checks 1
if `run_data_checks' {
    do do/check/check_logs.do              // structural; runs first
    do do/check/check_samples.do
    do do/check/check_merges.do
    do do/check/check_va_estimates.do
    do do/check/check_survey_indices.do
    do do/check/check_paper_outputs.do
}
```

Defaults ON. A failed `assert` in any check halts the pipeline; partial outputs preserved.

---

## 9. Summary of TBD / open items

| Item | Owned-by | Resolves-when |
|---|---|---|
| Item lists per CalSCHLS index (9 / 15 / 4 — which exact QOIs?) | Christina (or Claude reading `imputedcategoryindex.do`) | Phase 1c when `check_survey_indices.do` is written |
| K12 ↔ NSC / CCC / CSU merge-rate baselines | Claude | After Phase 1a §3.5 golden-master verification |
| Paper-table cell magnitudes (Table 2/3 main coefficients) | Claude | After Phase 1a §3.3 share/ relocation |
| `<index1_name>` / `<index2_name>` / `<index3_name>` actual variable names | Claude reading constructor scripts | Phase 1c |
| Stata version Christina ran on (codebook log header would have it but I haven't pulled it) | trivial | Anytime |

## 10. What's NOT in scope here

- Bridge crosswalk schema (k12_ccc_xw, k12_csu_xw): post-PII-scrub only `match_level` and `male` remain — informative for merge-rate sanity but not for joint-key checks. The actual K12 ↔ college joins happen inside `merge_k12_postsecondary.doh` (Matt-owned, untouched per ADR-0017). The check pipeline asserts on the result of these merges (in `score_b` / `k12_main`), not on the bridges themselves.
- PII surfacing — handled by the `cap drop` block at the top of each `use` in `codebook_export.do` (2026-04-28 revision); no further hardening needed.

## 11. Next action

When the Phase 1a script relocation reaches the `share/` paper producers, run their outputs and fill in:
- §6 paper-output cell magnitudes
- §3 codebook-merge baseline numbers

Then write the six `check_*.do` files per the specs above and wire them into `main.do`.
