/*------------------------------------------------------------------------------
do/samples/create_va_g11_out_sample_v2.doh — g11 OUTCOME-VA sample (v2 prior scores)
================================================================================

PURPOSE
    Build the in-memory g11 OUTCOME-VA sample dataset with v2 prior-score
    controls (SAME ELA/Math lag/grade per cohort).

    **EXPLORATORY per ADR-0009.** v1 is the canonical paper version; v2
    preserved for reproducibility of the exploratory analysis.  Same
    restriction as v1 (g11, CAASPP, outcome-year range, `diff_school_prop'
    >= 0.95) — only differs in the prior-score include
    (`create_prior_scores_v2.doh' instead of `_v1').

INCLUDED FROM
    Phase 2 sample-construction scripts.  Same parent-scope requirements
    as v1 (see `create_va_g11_out_sample_v1.doh' INCLUDED FROM block).

ROLE IN ADR-0021 SANDBOX
    Same as v1: reads `\`va_dataset'.dta'; no persistent saves.

RELOCATION HISTORY (per ADR-0021, applied 2026-04-30)
    Source:      cde_va_project_fork/do_files/sbac/create_va_g11_out_sample_v2.doh
    Destination: do/samples/create_va_g11_out_sample_v2.doh
    Path repointing per ADR-0021 path-globals-only amendment:
      - L6: `include do_files/sbac/create_diff_school_prop.doh'
        -> `include do/samples/create_diff_school_prop.doh' (CANONICAL)
      - L9: `include do_files/sbac/create_prior_scores_v2.doh'
        -> `include do/samples/create_prior_scores_v2.doh' (CANONICAL)
    Body otherwise verbatim from predecessor.

REFERENCES
    Plan v3 §3.3 step 2 (sample construction)
    ADRs:    0009 (v2 exploratory; preserved for reproducibility),
             0021 (description convention)
------------------------------------------------------------------------------*/

// create version 2 of VA samples, same prior score controls for ELA and Math

local drift_limit = max(`outcome_max_year' - `outcome_min_year' - 1, 1)
use if grade==11 & dataset=="CAASPP" & inrange(year, `outcome_min_year', `outcome_max_year') using `va_dataset', clear

include do/samples/create_diff_school_prop.doh
keep if diff_school_prop>=0.95

include do/samples/create_prior_scores_v2.doh


* Save temporary dataset
compress
tempfile va_g11_dataset
save `va_g11_dataset'
