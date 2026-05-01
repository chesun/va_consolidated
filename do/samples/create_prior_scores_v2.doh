/*------------------------------------------------------------------------------
do/samples/create_prior_scores_v2.doh — prior-score controls (v2: same ELA/Math)
================================================================================

PURPOSE
    Construct `prior_ela_z_score' / `peer_prior_ela_z_score' /
    `prior_math_z_score' / `peer_prior_math_z_score' for the VA estimation
    sample.  v2 uses THE SAME lag/grade prior controls for ELA and Math
    (per the predecessor 12/20/2022 spec).

    **EXPLORATORY per ADR-0009.** The paper uses v1 (different ELA/Math
    prior-score controls).  v2 is preserved for reproducibility of the
    exploratory analysis but is NOT the canonical pipeline output.

    ELA prior-score wiring per cohort:
      - Spring 2015 cohort: 6th-grade ELA (spring 2012; CST)
      - Spring 2016 cohort: 6th-grade ELA (spring 2013; CST)
      - Spring 2017 cohort: 6th-grade ELA (spring 2013; CST)
      - Spring 2018 cohort: 8th-grade ELA (spring 2015; SBAC)
    Math prior-score wiring per cohort:
      - Spring 2015 cohort: 6th-grade math (spring 2010)
      - Spring 2016 cohort: 6th-grade math (spring 2011)
      - Spring 2017 cohort: 6th-grade math (spring 2012)
      - Spring 2018 cohort: 8th-grade math (spring 2015)

INCLUDED FROM
    `do/samples/create_va_g11_sample_v2.doh' +
    `do/samples/create_va_g11_out_sample_v2.doh' (exploratory v2 callers).
    Requires same parent-scope locals/variables as v1 (see
    `create_prior_scores_v1.doh').

ROLE IN ADR-0021 SANDBOX
    Pure `gen'/`replace'/`label var' on in-memory dataset; no save / export
    / log.  No `$global' references.

RELOCATION HISTORY (per ADR-0021, applied 2026-04-30)
    Source:      cde_va_project_fork/do_files/sbac/create_prior_scores_v2.doh
    Destination: do/samples/create_prior_scores_v2.doh
    Body verbatim from predecessor.  No path repointing.
    Predecessor caller-update protocol: predecessor callers untouched per
    plan v3 §3.3 step 5 parenthetical.

REFERENCES
    Plan v3 §3.3 step 2 (sample construction)
    ADRs:    0009 (v1 canonical; v2 preserved as exploratory),
             0021 (description convention)
------------------------------------------------------------------------------*/

**************** Prior Scores
/* VA sample version 2: same prior score controls for ELA and Math
updated 12/20/2022 by Christina Sun

VA Test Score Controls
Spring 2015 cohort use 6th grade ELA (spring 2012) and 6th grade math (spring 2010)
Spring 2016 cohort use 6th grade ELA  (spring 2013) and 6th grade math (spring 2011)
Spring 2017 cohort use 6th grade ELA  (spring 2013) and 6th grade math (spring 2012)
Spring 2018 cohort use 8th grade ELA  (spring 2015) and 8th grade math (spring 2015)
 */
******** ELA
// spring 2015-2017 cohort: 6th grade ELA (not many observations for sbac for 6th grade prior scores)
gen prior_ela_z_score = L5_cst_ela_z_score if inrange(year, `star_min_year' + 5, `star_max_year' + 5) & year!=2018
/* replace prior_ela_z_score = L5_sbac_ela_z_score if inrange(year, `caaspp_min_year' + 5, `caaspp_max_year' + 5) & year!=2018 */
// spring 2018 cohort: 8th grade ELA (use sbac)
replace prior_ela_z_score = L3_sbac_ela_z_score if year==2018
label var prior_ela_z_score "Prior ELA Z-Score"

gen peer_prior_ela_z_score = peer_L5_cst_ela_z_score if inrange(year, `star_min_year' + 5, `star_max_year' + 5) & year!=2018
/* replace peer_prior_ela_z_score = peer_L5_sbac_ela_z_score if inrange(year, `caaspp_min_year' + 5, `caaspp_max_year' + 5) & year!=2018 */
replace peer_prior_ela_z_score = peer_L3_sbac_ela_z_score if year==2018
label var peer_prior_ela_z_score "Peer Avg. Prior ELA Z-Score"

******** Math
// spring 2015-2017 cohort: 6th grade math
gen prior_math_z_score = L5_cst_math_z_score if inrange(year, `star_min_year' + 5, `star_max_year' + 5) & !inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3)
// spring 2018 cohort: 8th grade math
replace prior_math_z_score = L3_sbac_math_z_score if inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3)
label var prior_math_z_score "Prior Math Z-Score"
gen peer_prior_math_z_score = peer_L5_cst_math_z_score if inrange(year, `star_min_year' + 5, `star_max_year' + 5) & !inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3)
replace peer_prior_math_z_score = peer_L3_sbac_math_z_score if inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3)
label var peer_prior_math_z_score "Peer Avg. Prior Math Z-Score"
