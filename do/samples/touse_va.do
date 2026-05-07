/*------------------------------------------------------------------------------
do/samples/touse_va.do — tag the VA-eligible analysis sample
================================================================================

PURPOSE
    Build a single-pass crosswalk of `touse_*` indicators (sample-membership
    tags) keyed by `merge_id_k12_test_scores'.  For every K12 test-score
    observation, decide whether it qualifies for:
      - touse_g11_ela / touse_g11_math    (test-score VA samples)
      - touse_g11_enr / _enr_2year /      (postsecondary-outcome VA samples
        _enr_4year                          for 11th-grade outcomes)
    based on grade==11, dataset=="CAASPP", year-range, school-stability
    (diff_school_prop>=0.95), first-time-test (first_scores_sample==1),
    non-missing controls (markout against demographic, peer, and lagged-score
    controls), conventional-school filter, and per-school cohort size >= 7.

    Output crosswalk is consumed by `create_va_sample.doh' (this batch) which
    in turn feeds `create_score_samples.do' / `create_out_samples.do'.

INVOKED FROM
    `do/main.do' Phase 2 (run_samples block).

PRODUCTION STATUS
    GATED OFF in the predecessor `do_all.do:110-113' (`local do_touse_va = 0').
    `va_samples.dta' is a run-once-cached artifact in the predecessor pipeline:
    seeded long ago, persists at $vaprojdir/data/sbac/va_samples.dta on Scribe,
    and re-read by every subsequent sample-construction step.  In the
    consolidated repo this file is similarly run-once-cached, written to the
    CANONICAL `$datadir_clean/sbac/va_samples.dta'.  See `do/main.do' Phase 2
    block — the invocation is gated by the same `do_touse_va' local for
    behavior parity.

INPUTS
    LEGACY (read-only per ADR-0021 sandbox principle):
      $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta
                                          — restricted-access raw K12 scores
      $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_lag_test_scores_clean.dta
                                          — lagged scores (L3..L6 ELA/math)
      $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_peer_test_scores_clean.dta
                                          — peer scores (mean within school-year)
      $vaprojdir/data/public_access/clean/k12_test_scores/k12_diff_school_prop_schyr.dta
                                          — same-school proportion across grades
      $vaprojdir/data/public_access/clean/k12_test_scores/k12_cohort_size_sch.dta
                                          — median cohort sizes
      $vaprojdir/data/public_access/clean/k12_public_schools/k12_public_schools_clean.dta
                                          — conventional-school filter
      $matt_files_dir/merge_k12_postsecondary.doh
                                          — Matt's K12↔postsec merger (ADR-0017)
      do/va/helpers/macros_va.doh        — VA-pipeline locals (relocated 2026-04-30)
      do/samples/create_diff_school_prop.doh
                                          — diff-school-prop indicator builder
      do/samples/create_prior_scores.doh — DEAD INCLUDE (see CONVENTION DEVIATIONS below)

OUTPUTS
    CANONICAL (write per ADR-0021 sandbox principle):
      $datadir_clean/sbac/va_samples.dta — touse_* crosswalk by merge_id
      $logdir/touse_va.smcl + .log       — per-do-file log

ROLE IN ADR-0021 SANDBOX
    Reads LEGACY paths (restricted-access K12 data; Matt's merge .doh; Christina's
    relocated helpers under do/) and writes ONLY to CANONICAL `$datadir_clean'.
    Sandbox-clean.

RELOCATION HISTORY (per plan v3 §3.3 step 2 batch 2b, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/touse_va.do (predecessor)
    Destination: do/samples/touse_va.do (this file)
    Path repointing under ADR-0021 (analysis logic preserved verbatim):
      - L17 usage comment: $vaprojdir/do_files/sbac/touse_va
                        -> $consolidated_dir/do/samples/touse_va.do
      - L28 `cd $vaprojdir' preserved (predecessor pattern; macros_va.doh
        defines `local k12_test_scores "$vaprojdir/data/..."' which uses
        absolute paths — but other helpers historically relied on relative-CWD
        behavior; preserve for parity); `cd "$consolidated_dir"' restored at end.
      - L30 log target: relative `log_files/sbac/touse_va.smcl'
                     -> CANONICAL `$logdir/touse_va.smcl' (per plan v3 §5.1 step 2)
      - L45 `include do_files/sbac/macros_va.doh'
         -> `include $consolidated_dir/do/va/helpers/macros_va.doh' (relocated 2026-04-30 helpers batch)
      - L115 `do do_files/merge_k12_postsecondary.doh'
          -> `do "$matt_files_dir/merge_k12_postsecondary.doh"' (Matt's, untouched per ADR-0017)
      - L129 `include do_files/sbac/create_diff_school_prop.doh'
            -> `include $consolidated_dir/do/samples/create_diff_school_prop.doh' (relocated 2026-04-30 batch 2a)
      - L131 `include do_files/sbac/create_prior_scores.doh' — VERBATIM (see DEAD INCLUDE)
      - L194 save target: relative `data/sbac/va_samples.dta'
                       -> CANONICAL `$datadir_clean/sbac/va_samples.dta'
                       (matches read path in do/samples/create_va_sample.doh:9)
      - L200 translate: `log_files/sbac/touse_va.{smcl,log}'
                     -> `$logdir/touse_va.{smcl,log}'

CONVENTION DEVIATIONS (verbatim preservation per ADR-0021)
    DEAD INCLUDE at L131: `include $consolidated_dir/do/samples/create_prior_scores.doh' refers to
    a file that was DELETED 2022-12-29 in the v1/v2 prior-score refactor (commit
    f8764bf in cde_va_project_fork; see also ADR-0009 declaring v1 canonical).
    The unsuffixed `create_prior_scores.doh' has not existed since.  This dead
    include has been latent in the predecessor `touse_va.do' for 3+ years
    because `do_touse_va' is gated 0 in `do_all.do:110' — the script is never
    actually run in the production pipeline.  Preserved verbatim here per
    ADR-0021's "behavior-preserving" mandate (Phase 1a is path-only repointing;
    no analysis-logic edits).  Phase 1b §4.3 (naming/clarity) will resolve by
    repointing to `create_prior_scores_v1.doh' per ADR-0009 v1-canonical, OR
    by archiving touse_va.do entirely if its `va_samples.dta' output is
    deemed permanently cached.  Tracked in TODO.md.

ORIGINAL CHANGE LOG (preserved from predecessor; written by Matthew Naven, edited by Che Sun)
    First created by Matthew Naven on August 30, 2018.
    Edited by Che Sun March 10, 2022.
    2022-06-27: Added & first_scores_sample==1 to mark touse_g11_`subject' and
                mark touse_g11_`outcome' commands on lines 135 and 160.
    2026-05-07: Relocated to consolidated repo per plan v3 §3.3 step 2 batch 2b;
                paths repointed to CANONICAL per ADR-0021; dead include at L131
                preserved with header flag.

REFERENCES
    Plan:  quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §3.3 step 2
    ADRs:  0009 (prior-score v1 canonical), 0017 (Matt's files untouched),
           0021 (do/ relocation; sandbox; description convention)
    Predecessor caller: cde_va_project_fork/do_files/do_all.do:110-113 (gated 0)
    Dead include git history: cde_va_project_fork commit f8764bf 2022-12-29
------------------------------------------------------------------------------*/


version 16.1
cap log close _all
clear all


/*****************************************************
* First created by Matthew Naven on August 30, 2018 *
* edited by Che Sun March 10, 2022
*****************************************************/

/* To run this do file, type:
do $consolidated_dir/do/samples/touse_va.do
 */


 /* CHANGE LOG
6/27/2022: Added & first_scores_sample==1 to mark touse_g11_`subject' and
mark touse_g11_`outcome' commands on lines 135 and 160
 */


* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/sbac"
cap mkdir "$logdir"


* The predecessor cd'd to $vaprojdir before downstream merges (some helpers
* may rely on relative paths).  Preserved here for behavior parity; restored
* to $consolidated_dir at end of file so subsequent main.do invocations see
* the canonical CWD.
cd $vaprojdir

log using "$logdir/touse_va.smcl", replace text

di as text _n "{hline 80}"
di as text "touse_va.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"

graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984




**********
* Macros *
**********
include $consolidated_dir/do/va/helpers/macros_va.doh

#delimit ;

#delimit cr
macro list


timer on 1
*****************
* Begin Do File *
*****************
**************** Create VA Dataset
use merge_id_k12_test_scores all_students_sample first_scores_sample ///
	dataset test cdscode school_id state_student_id year grade ///
	cohort_size ///
	sbac_ela_z_score sbac_math_z_score ///
	`va_control_vars' ///
	using `k12_test_scores'/k12_test_scores_clean.dta, clear
mark touse

* Merge to lagged scores
merge 1:1 merge_id_k12_test_scores using `k12_test_scores'/k12_lag_test_scores_clean.dta, nogen keep(1 3) ///
	keepusing( ///
		L3_cst_ela_z_score ///
		L3_sbac_ela_z_score ///
		L4_cst_ela_z_score ///
		L3_sbac_math_z_score ///
		L4_sbac_math_z_score ///
		L5_cst_math_z_score ///
		L6_cst_math_z_score ///
	)

* Merge to peer scores
merge 1:1 merge_id_k12_test_scores using `k12_test_scores'/k12_peer_test_scores_clean.dta, nogen keep(1 3) ///
	keepusing( ///
		`peer_demographic_controls' ///
		peer_L3_cst_ela_z_score ///
		peer_L3_sbac_ela_z_score ///
		peer_L4_cst_ela_z_score ///
		peer_L3_sbac_math_z_score ///
		peer_L4_sbac_math_z_score ///
		peer_L5_cst_math_z_score ///
		peer_L6_cst_math_z_score ///
	)

* Merge to school grade spans
merge m:1 cdscode year using `k12_test_scores_public'/k12_diff_school_prop_schyr.dta ///
	, gen(merge_grade_span) keepusing(gr11_*_diff_school_prop) keep(1 3)

* Merge to median cohort sizes
merge m:1 cdscode using `k12_test_scores_public'/k12_cohort_size_sch.dta ///
	, gen(merge_cohort_size) keepusing(med_cohort_size_first_scores) keep(1 3)

* Keep conventional schools
merge m:1 cdscode using `k12_public_schools'/k12_public_schools_clean.dta ///
	, gen(merge_public_schools) keepusing(conventional_school) keep(1 3)
replace touse = 0 if conventional_school!=1

* Exclude schools where more than 25 percent of students are receiving special education services

* Drop if a student is receiving instruction at home, in a hospital, or in a school serving disabled students solely

* Drop if 10 or fewer students per school
replace touse = 0 if cohort_size<=10




******** Postsecondary Outcomes
do "$matt_files_dir/merge_k12_postsecondary.doh" enr_only
drop enr enr_2year enr_4year
rename enr_ontime enr
rename enr_ontime_2year enr_2year
rename enr_ontime_4year enr_4year







******************************** 11th Grade (8th Grade ELA Controls, 6th Grade Math Controls)
include $consolidated_dir/do/samples/create_diff_school_prop.doh

* DEAD INCLUDE — see CONVENTION DEVIATIONS in header.  File deleted 2022-12-29
* in v1/v2 prior-score refactor; touse_va.do gated OFF in predecessor and in
* main.do, so this never executes in production.  Phase 1b §4.3 resolves.
include $consolidated_dir/do/samples/create_prior_scores.doh

**** Test Score Sample
foreach subject in ela math {
	mark touse_g11_`subject' ///
		if grade==11 & dataset=="CAASPP" & inrange(year, `test_score_min_year', `test_score_max_year') ///
		& diff_school_prop>=0.95 ///
		& first_scores_sample==1
	markout touse_g11_`subject' ///
		sbac_`subject'_z_score ///
		school_id i.year ///
		`school_controls' ///
		`demographic_controls' ///
		`ela_score_controls' ///
		`math_score_controls' ///
		`peer_demographic_controls' ///
		`peer_ela_score_controls' ///
		`peer_math_score_controls'

	replace touse_g11_`subject' = 0 if touse==0

	egen n_g11_`subject' = count(state_student_id) ///
		if touse_g11_`subject'==1 ///
		, by(cdscode year)
	replace touse_g11_`subject' = 0 if n_g11_`subject'<7
}

**** Postsecondary Outcomes Sample
foreach outcome in enr enr_2year enr_4year {
	mark touse_g11_`outcome' ///
		if grade==11 & dataset=="CAASPP" & inrange(year, `outcome_min_year', `outcome_max_year') ///
		& diff_school_prop>=0.95 ///
		& first_scores_sample==1
	markout touse_g11_`outcome' ///
		`outcome' ///
		school_id i.year ///
		`school_controls' ///
		`demographic_controls' ///
		`ela_score_controls' ///
		`math_score_controls' ///
		`peer_demographic_controls' ///
		`peer_ela_score_controls' ///
		`peer_math_score_controls'

	replace touse_g11_`outcome' = 0 if touse==0

	egen n_g11_`outcome' = count(state_student_id) ///
		if touse_g11_`outcome'==1 ///
		, by(cdscode year)
	replace touse_g11_`outcome' = 0 if n_g11_`outcome'<7
}

**** Sample Tabulations
foreach v of varlist touse* {
	tab year `v'
}




keep merge_id_k12_test_scores touse*
sort merge_id_k12_test_scores
compress
save "$datadir_clean/sbac/va_samples.dta", replace


timer off 1
timer list

cap log close
cap translate "$logdir/touse_va.smcl" "$logdir/touse_va.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
