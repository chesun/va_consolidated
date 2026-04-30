/*------------------------------------------------------------------------------
do/check/check_samples.do — assert sample-construction outputs match historical baselines
================================================================================

PURPOSE
    Verify the analytic VA sample (`score_b.dta`) is structurally what we
    expect before any VA estimation runs.  Hard `assert` invariants halt the
    pipeline on regression; soft signals (`display as error`) flag oddities
    without halting.  Encodes the design memo §2 specification.

INPUTS
    `score_b.dta` — student-year, g11, cohorts 2015-18 (1,784,445 rows × 77 vars
    per codebook line 73020).
    Path post-Phase-1a §3.3: $estimates_dir/va_samples_v1/score_b.dta
    (built by relocated sample-construction scripts under do/samples/).

OUTPUTS
    Per-do-file log: $logdir/check_samples.smcl + .log
    On `assert` failure: pipeline halts; partial outputs preserved.

ROLE IN ADR-0021 SANDBOX
    Reads from CANONICAL ($estimates_dir/va_samples_v1/score_b.dta) once
    Phase 1a §3.3 lands the sample-construction relocation.  Writes only to
    $logdir (CANONICAL).  Skeleton uses capture-confirm-file shim so a
    pre-relocation main.do run skips this check cleanly with an informative
    message rather than crashing.

INVARIANTS (verbatim from design memo §2)
    Hard asserts:
      - _N == 1784445 (total g11 student-years; codebook line 73020)
      - grade == 11 for all rows (g11-only by construction)
      - inrange(year, 2015, 2018) (4-cohort window)
      - per-cohort counts: 402416 / 406084 / 450201 / 525744 (codebook line 73020)
      - 1389 unique schools (audit + codebook line 73040)
      - race dummies orthogonal: rowtotal(eth_*) ∈ {0, 1}
      - binary demographics in {0, 1, .}
    Soft signals (display as error, non-halting):
      - age in [5478, 6940] days (~15-19 yrs; codebook range was [-14, 43099])
      - cohort_size in [11, 1325] (codebook line 73086)

REFERENCES
    Design memo:    quality_reports/reviews/2026-04-28_data-checks-design.md §2
    Plan:           quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §5.3 step 9
    Codebook:       master_supporting_docs/codebooks/codebook_export_28-Apr-2026_13-25-41.log
                    (gitignored; see design memo §2 codebook-references for line ranges)
    ADRs:           0011 (sums→means; not relevant here but shapes survey-VA checks),
                    0021 (description convention; sandbox role above)
------------------------------------------------------------------------------*/


clear all
set more off
cap log close _all
set linesize 120

cap mkdir "$logdir"
log using "$logdir/check_samples.smcl", replace text

di as text _n "{hline 80}"
di as text "check_samples.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


/*==============================================================================
INPUT
==============================================================================*/

* TODO Phase 1a §3.3: confirm post-relocation path (sample-construction scripts
*    under do/samples/ produce `score_b.dta`; canonical destination expected
*    under $estimates_dir/va_samples_v1/).
local in_dta "$estimates_dir/va_samples_v1/score_b.dta"

capture confirm file "`in_dta'"
if _rc {
    di as text "  [SKELETON] `in_dta' not found — produced by Phase 1a §3.3"
    di as text "             relocated sample-construction scripts under do/samples/."
    di as text "             Skipping check_samples.do."
    cap log close
    cap translate "$logdir/check_samples.smcl" "$logdir/check_samples.log", replace
    exit 0
}

use "`in_dta'", clear


/*==============================================================================
HARD ASSERTS (from design memo §2)
==============================================================================*/

* sample size + structure -- codebook line 73020
assert _N == 1784445
di as text "  PASS: _N == 1784445 (total g11 student-years)"

assert grade == 11
di as text "  PASS: grade == 11 (g11-only)"

assert inrange(year, 2015, 2018)
di as text "  PASS: year ∈ [2015, 2018] (4-cohort window)"

* per-cohort counts -- codebook line 73020
qui count if year == 2015
assert r(N) == 402416
di as text "  PASS: 2015 cohort N == 402416"
qui count if year == 2016
assert r(N) == 406084
di as text "  PASS: 2016 cohort N == 406084"
qui count if year == 2017
assert r(N) == 450201
di as text "  PASS: 2017 cohort N == 450201"
qui count if year == 2018
assert r(N) == 525744
di as text "  PASS: 2018 cohort N == 525744"

* uniqueness -- 1389 schools per audit + codebook line 73040
qui levelsof cdscode, local(cds_list)
local n_schools : word count `cds_list'
assert `n_schools' == 1389
di as text "  PASS: distinct cdscode count == 1389"

* race dummies orthogonal + cover (rowtotal of indicators ∈ {0, 1})
tempvar eth_sum
egen `eth_sum' = rowtotal(eth_asian eth_hispanic eth_black eth_white eth_other)
capture assert inlist(`eth_sum', 0, 1)
if _rc {
    di as error "  FAIL: race dummies (eth_asian/hispanic/black/white/other) not orthogonal."
    qui tab `eth_sum', missing
    cap log close
    cap translate "$logdir/check_samples.smcl" "$logdir/check_samples.log", replace
    exit _rc
}
di as text "  PASS: race dummies orthogonal (rowtotal ∈ {0, 1})"
drop `eth_sum'

* binary-coded demographics in {0, 1, .}
foreach v in econ_disadvantage male limited_eng_prof disabled                 ///
             eth_asian eth_hispanic eth_black eth_white eth_other             {
    capture assert inlist(`v', 0, 1, .)
    if _rc {
        di as error "  FAIL: binary-coded var `v' has values outside {0, 1, .}"
        qui tab `v', missing
        cap log close
        cap translate "$logdir/check_samples.smcl" "$logdir/check_samples.log", replace
        exit _rc
    }
}
di as text "  PASS: binary demographics in {0, 1, .}"


/*==============================================================================
SOFT SIGNALS (display as error; non-halting)
==============================================================================*/

* Plausible age-on-Jan-1 in days for g11 students = ~16 yrs = ~5,840 days.
* Codebook range was [-14, 43099] with 5,483 missings — the upper tail looks
* like a date-encoding artifact.  Soft-flag rather than halt.
qui count if !missing(age) & !inrange(age, 5478, 6940)
local n_age_oddity = r(N)
if `n_age_oddity' > 0 {
    di as error "  SOFT: `n_age_oddity' rows have age outside [5478, 6940] days (~15-19 yrs)"
    di as error "        upstream age-encoding may be corrupted; investigate but not halting."
}
else {
    di as text "  PASS: age within [5478, 6940] days for all non-missing rows"
}

* cohort_size range -- codebook line 73086
qui sum cohort_size
if r(min) < 11 | r(max) > 1325 {
    di as error "  SOFT: cohort_size range [`r(min)', `r(max)'] outside expected [11, 1325]"
}
else {
    di as text "  PASS: cohort_size within [11, 1325]"
}


/*==============================================================================
WRAP-UP
==============================================================================*/

di as text _n "{hline 80}"
di as text "check_samples.do — RUN END: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"

cap log close
cap translate "$logdir/check_samples.smcl" "$logdir/check_samples.log", replace

* end of file
