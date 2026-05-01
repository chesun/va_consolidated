/*------------------------------------------------------------------------------
do/samples/create_va_g11_out_sample_v1.doh — g11 OUTCOME-VA sample (v1 prior scores)
================================================================================

PURPOSE
    Build the in-memory g11 OUTCOME-VA sample dataset.  Differs from
    `create_va_g11_sample_v1.doh' (score-VA variant) only in the year
    range:
      - SCORE-VA: cohorts in [`test_score_min_year', `test_score_max_year']
        = [2015, 2018]
      - OUTCOME-VA: cohorts in [`outcome_min_year', `outcome_max_year']
        = [2015, 2018]  (same window today; year ranges separated for
        future flexibility — outcome window may extend if NSC data refresh)
    Otherwise identical: g11, CAASPP, `diff_school_prop' >= 0.95, v1
    prior-score wiring per ADR-0009 (different ELA/Math).

    **CANONICAL per ADR-0009.** v1 is the prior-score spec used in the paper.

INCLUDED FROM
    Phase 2 sample-construction scripts (relocated next batch — likely
    `create_out_samples.do' per plan v3 §3.3 step 2).  Parent-scope
    requirements identical to `create_va_g11_sample_v1.doh' except uses
    `\`outcome_min_year'' / `\`outcome_max_year'' instead of test-score
    year locals.

ROLE IN ADR-0021 SANDBOX
    Same as score-VA variant: reads `\`va_dataset'.dta'; tempfile-only
    persist; no on-disk save / export.

RELOCATION HISTORY (per ADR-0021, applied 2026-04-30)
    Source:      cde_va_project_fork/do_files/sbac/create_va_g11_out_sample_v1.doh
    Destination: do/samples/create_va_g11_out_sample_v1.doh
    Path repointing per ADR-0021 path-globals-only amendment:
      - L6: `include do_files/sbac/create_diff_school_prop.doh'
        -> `include do/samples/create_diff_school_prop.doh' (CANONICAL)
      - L9: `include do_files/sbac/create_prior_scores_v1.doh'
        -> `include do/samples/create_prior_scores_v1.doh' (CANONICAL)
    Body otherwise verbatim from predecessor.

REFERENCES
    Plan v3 §3.3 step 2 (sample construction)
    ADRs:    0009 (v1 prior-score canonical), 0021 (description convention)
------------------------------------------------------------------------------*/

// create version 1 of VA samples, different prior score controls for ELA and Math

local drift_limit = max(`outcome_max_year' - `outcome_min_year' - 1, 1)
use if grade==11 & dataset=="CAASPP" & inrange(year, `outcome_min_year', `outcome_max_year') using `va_dataset', clear

include do/samples/create_diff_school_prop.doh
keep if diff_school_prop>=0.95

include do/samples/create_prior_scores_v1.doh


* Save temporary dataset
compress
tempfile va_g11_dataset
save `va_g11_dataset'
