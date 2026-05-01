/*------------------------------------------------------------------------------
do/samples/create_va_g11_sample_v1.doh — g11 SCORE-VA sample (v1 prior scores)
================================================================================

PURPOSE
    Build the in-memory g11 SCORE-VA sample dataset, restricting to:
      - grade==11, dataset=="CAASPP"
      - cohort years in [`test_score_min_year', `test_score_max_year'] = [2015, 2018]
      - schools where >=95% of students were at the same school last year
        (`diff_school_prop' >= 0.95)
    Computes prior-score controls per ADR-0009 v1 (different ELA/Math).
    Saves to a tempfile (`va_g11_dataset') for downstream consumption.

    **CANONICAL per ADR-0009.** v1 is the prior-score spec used in the paper.

INCLUDED FROM
    Phase 2 sample-construction scripts (relocated next batch — touse_va.do
    + create_score_samples.do per plan v3 §3.3 step 2).
    Requires parent-scope:
      - `\`test_score_min_year'' / `\`test_score_max_year'' (from
        `do/va/helpers/macros_va.doh' — typically include macros_va.doh
        before this fragment)
      - `\`va_dataset'' (predecessor `local va_dataset' from vafilemacros.doh
        L18 = `$projdir/dta/common_core_va/va_dataset'; in consolidated this
        should be `$datadir_clean/common_core_va/va_dataset' — to be
        defined by the calling script in Phase 1a §3.3 step 2 batch 2b).
    Tempfile `va_g11_dataset' returned to parent scope.

ROLE IN ADR-0021 SANDBOX
    Reads `\`va_dataset'.dta' (LEGACY in predecessor; CANONICAL in
    consolidated post-step-2-batch-2b).  No save/export to disk; only
    `tempfile' + `save \`va_g11_dataset'' (Stata tempfile is auto-cleaned,
    not persisted).

RELOCATION HISTORY (per ADR-0021, applied 2026-04-30)
    Source:      cde_va_project_fork/do_files/sbac/create_va_g11_sample_v1.doh
    Destination: do/samples/create_va_g11_sample_v1.doh
    Path repointing per ADR-0021 path-globals-only amendment:
      - L8: `include do_files/sbac/create_diff_school_prop.doh'
        -> `include do/samples/create_diff_school_prop.doh' (CANONICAL)
      - L11: `include do_files/sbac/create_prior_scores_v1.doh'
        -> `include do/samples/create_prior_scores_v1.doh' (CANONICAL)
    Body otherwise verbatim from predecessor.
    NOTE: `create_va_g11_sample.doh' (no-suffix) is byte-identical to v1
    in the predecessor; both relocated for verbatim preservation.  Phase 1c
    §5.1 may archive the redundant base if confirmed unused.
    Predecessor caller-update protocol: predecessor callers untouched per
    plan v3 §3.3 step 5 parenthetical.

REFERENCES
    Plan v3 §3.3 step 2 (sample construction)
    ADRs:    0009 (v1 prior-score canonical), 0021 (description convention)
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
