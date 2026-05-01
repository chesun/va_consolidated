/*------------------------------------------------------------------------------
do/samples/create_prior_scores_v1.doh — prior-score controls (v1: differing ELA/Math)
================================================================================

PURPOSE
    Construct `prior_ela_z_score' / `peer_prior_ela_z_score' /
    `prior_math_z_score' / `peer_prior_math_z_score' for the VA estimation
    sample.  v1 uses DIFFERENT lag/grade prior controls for ELA and Math
    (per the predecessor 12/29/2022 spec).  v1 is the CANONICAL prior-score
    spec used in the paper per ADR-0009.

    ELA prior-score wiring per cohort:
      - Spring 2015 cohort: 8th-grade ELA (spring 2012)
      - Spring 2016 cohort: 8th-grade ELA (spring 2013)
      - Spring 2017 cohort: 7th-grade ELA (spring 2013)  [L4 not L3]
      - Spring 2018 cohort: 8th-grade ELA (spring 2015)
    Math prior-score wiring per cohort:
      - Spring 2015 cohort: 6th-grade math (spring 2010)
      - Spring 2016 cohort: 6th-grade math (spring 2011)
      - Spring 2017 cohort: 6th-grade math (spring 2012)
      - Spring 2018 cohort: 8th-grade math (spring 2015)

INCLUDED FROM
    `do/samples/create_va_g11_sample.doh' (base; byte-equivalent to v1) +
    `do/samples/create_va_g11_sample_v1.doh' +
    `do/samples/create_va_g11_out_sample.doh' (base) +
    `do/samples/create_va_g11_out_sample_v1.doh'.
    Requires parent-scope locals `star_min_year', `star_max_year',
    `caaspp_min_year', `caaspp_max_year' (defined by `do/va/helpers/macros_va.doh').
    Requires parent-scope dataset variables `L3_cst_ela_z_score',
    `L3_sbac_ela_z_score', `L4_cst_ela_z_score', `L5_cst_math_z_score',
    `L3_sbac_math_z_score', plus their `peer_*' variants (merged in by
    `do/samples/create_va_sample.doh' before this fragment runs).

ROLE IN ADR-0021 SANDBOX
    Pure `gen'/`replace'/`label var' on in-memory dataset; no save / export
    / log.  No `$global' references.

RELOCATION HISTORY (per ADR-0021, applied 2026-04-30)
    Source:      cde_va_project_fork/do_files/sbac/create_prior_scores_v1.doh
    Destination: do/samples/create_prior_scores_v1.doh
    Body verbatim from predecessor.  No path repointing (no `$global' or
    relative-path references).
    Predecessor caller-update protocol: predecessor callers untouched per
    plan v3 §3.3 step 5 parenthetical.

REFERENCES
    Plan v3 §3.3 step 2 (sample construction)
    ADRs:    0009 (v1 prior-score canonical), 0021 (description convention)
------------------------------------------------------------------------------*/

**************** Prior Scores
/* Original version of VA sample: different prior score controls for ELA and Math
VA Test Score Controls
updated 12/29/2022 by Christina Sun

Spring 2015 cohort use 8th grade ELA (spring 2012) and 6th grade math (spring 2010)
Spring 2016 cohort use 8th grade ELA  (spring 2013) and 6th grade math (spring 2011)
Spring 2017 cohort use 7th grade ELA  (spring 2013) and 6th grade math (spring 2012)
Spring 2018 cohort use 8th grade ELA  (spring 2015) and 8th grade math (spring 2015)
 */
******** ELA
gen prior_ela_z_score = L3_cst_ela_z_score if inrange(year, `star_min_year' + 3, `star_max_year' + 3) & year!=2017
replace prior_ela_z_score = L3_sbac_ela_z_score if inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3) & year!=2017
replace prior_ela_z_score = L4_cst_ela_z_score if year==2017
label var prior_ela_z_score "Prior ELA Z-Score"
gen peer_prior_ela_z_score = peer_L3_cst_ela_z_score if inrange(year, `star_min_year' + 3, `star_max_year' + 3) & year!=2017
replace peer_prior_ela_z_score = peer_L3_sbac_ela_z_score if inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3) & year!=2017
replace peer_prior_ela_z_score = peer_L4_cst_ela_z_score if year==2017
label var peer_prior_ela_z_score "Peer Avg. Prior ELA Z-Score"

******** Math
gen prior_math_z_score = L5_cst_math_z_score if inrange(year, `star_min_year' + 5, `star_max_year' + 5) & !inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3)
replace prior_math_z_score = L3_sbac_math_z_score if inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3)
label var prior_math_z_score "Prior Math Z-Score"
gen peer_prior_math_z_score = peer_L5_cst_math_z_score if inrange(year, `star_min_year' + 5, `star_max_year' + 5) & !inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3)
replace peer_prior_math_z_score = peer_L3_sbac_math_z_score if inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3)
label var peer_prior_math_z_score "Peer Avg. Prior Math Z-Score"
