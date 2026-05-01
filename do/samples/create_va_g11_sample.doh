/*------------------------------------------------------------------------------
do/samples/create_va_g11_sample.doh — g11 SCORE-VA sample (base; byte-eq to v1)
================================================================================

PURPOSE
    Build the in-memory g11 SCORE-VA sample dataset.  **BYTE-IDENTICAL to
    `create_va_g11_sample_v1.doh' in the predecessor** — likely a pre-v1/v2-
    split historical name retained when the explicit `_v1' was added.

    Functionality identical to v1 (per ADR-0009 v1 is canonical; base is
    just an unsuffixed alias).  Same restriction (g11, CAASPP, 2015-2018,
    `diff_school_prop' >= 0.95) and same prior-score wiring (calls
    `create_prior_scores_v1.doh').

    **Phase 1c §5.1 candidate for archival** if no remaining caller needs
    the unsuffixed name.  Preserved in step-2-batch-2a per ADR-0021
    verbatim rule pending §5.1 dead-code sweep.

INCLUDED FROM
    Phase 2 sample-construction scripts (relocated next batch).  Same
    parent-scope requirements as `create_va_g11_sample_v1.doh' (see that
    file's INCLUDED FROM block).

ROLE IN ADR-0021 SANDBOX
    Same as v1: reads `\`va_dataset'.dta'; no persistent saves.

RELOCATION HISTORY (per ADR-0021, applied 2026-04-30)
    Source:      cde_va_project_fork/do_files/sbac/create_va_g11_sample.doh
    Destination: do/samples/create_va_g11_sample.doh
    Path repointing per ADR-0021 path-globals-only amendment:
      - L6: `include do_files/sbac/create_diff_school_prop.doh'
        -> `include do/samples/create_diff_school_prop.doh' (CANONICAL)
      - L9: `include do_files/sbac/create_prior_scores_v1.doh'
        -> `include do/samples/create_prior_scores_v1.doh' (CANONICAL)
    Body otherwise verbatim from predecessor.  Confirmed byte-identical to
    v1 in predecessor; relocated as separate file for verbatim preservation.

REFERENCES
    Plan v3 §3.3 step 2 (sample construction)
    ADRs:    0009 (v1 canonical; base is an alias), 0021 (description
             convention; verbatim preservation)
------------------------------------------------------------------------------*/

// create version 1 of VA samples, different prior score controls for ELA and Math

local drift_limit = max(`test_score_max_year' - `test_score_min_year' - 1, 1)
use if grade==11 & dataset=="CAASPP" & inrange(year, `test_score_min_year', `test_score_max_year') using `va_dataset', clear

include do/samples/create_diff_school_prop.doh
keep if diff_school_prop>=0.95

include do/samples/create_prior_scores_v1.doh


* Save temporary dataset
compress
tempfile va_g11_dataset
save `va_g11_dataset'
