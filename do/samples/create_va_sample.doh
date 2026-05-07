/*------------------------------------------------------------------------------
do/samples/create_va_sample.doh — VA dataset constructor (in-memory fragment)
================================================================================

PURPOSE
    Pure parent-context fragment.  Reads the K12 test-score base dataset,
    merges in the touse_* crosswalk (built by `touse_va.do'), and chains
    merges for lagged scores, peer scores, school grade spans, median cohort
    sizes, and conventional-school filter.  Leaves the resulting dataset in
    memory for the calling parent (`create_score_samples.do' or
    `create_out_samples.do') to continue with sample-specific subsetting.

    Differences from `touse_va.do':
      - Reads the touse_* crosswalk from `$datadir_clean/sbac/va_samples.dta'
        (CANONICAL output of touse_va.do) and merges it in via _merge keepusing.
      - Adds `eth_white' to the keep-list (used downstream).
      - Filters via `keep if conventional_school==1' rather than
        `replace touse = 0 if conventional_school!=1' (a sample-restriction
        ordering choice — same final sample, different intermediate state).

INCLUDED FROM
    `do/samples/create_score_samples.do' (L63: base sample) and
    `do/samples/create_out_samples.do' (L66: base sample).
    Pure fragment — runs only inside its parent's log scope; no own log.

INPUTS
    LEGACY (read-only per ADR-0021 sandbox principle):
      $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta
                                          — restricted-access raw K12 scores
      $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_lag_test_scores_clean.dta
      $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_peer_test_scores_clean.dta
      $vaprojdir/data/public_access/clean/k12_test_scores/k12_diff_school_prop_schyr.dta
      $vaprojdir/data/public_access/clean/k12_test_scores/k12_cohort_size_sch.dta
      $vaprojdir/data/public_access/clean/k12_public_schools/k12_public_schools_clean.dta
                                          (paths defined as locals in macros_va.doh,
                                           which the parent script includes before
                                           this fragment)
    CANONICAL:
      $datadir_clean/sbac/va_samples.dta — touse_* crosswalk produced by
                                            `do/samples/touse_va.do'

OUTPUTS
    None on disk.  Leaves dataset in memory for parent script.

ROLE IN ADR-0021 SANDBOX
    Reads CANONICAL `$datadir_clean/sbac/va_samples.dta' (matches touse_va.do
    save target) plus LEGACY restricted-access K12 reads (via macros_va.doh
    locals in parent scope).  No saves; sandbox-trivially clean.

RELOCATION HISTORY (per plan v3 §3.3 step 2 batch 2b, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/create_va_sample.doh (predecessor)
    Destination: do/samples/create_va_sample.doh (this file)
    Path repointing under ADR-0021 (analysis logic preserved verbatim):
      - L9 read target: relative `data/sbac/va_samples.dta'
                     -> CANONICAL `$datadir_clean/sbac/va_samples.dta'
                     (CWD-independent; matches touse_va.do save path)

ORIGINAL CHANGE LOG (preserved from predecessor; no header attribution in source)
    Predecessor file lacked an authorship header.  Per file's role and adjacent
    file conventions, attributed to Matthew Naven / Che Sun jointly (touse_va.do
    cousin pattern).
    2026-05-07: Relocated to consolidated repo per plan v3 §3.3 step 2 batch 2b;
                read path repointed to CANONICAL.

REFERENCES
    Plan: quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §3.3 step 2
    ADRs: 0017 (Matt's files), 0021 (sandbox; description convention)
------------------------------------------------------------------------------*/

**************** Create VA Dataset
use merge_id_k12_test_scores all_students_sample first_scores_sample ///
	dataset test cdscode school_id state_student_id year grade ///
	cohort_size ///
	sbac_ela_z_score sbac_math_z_score ///
	`va_control_vars' eth_white ///
	/*if substr(cdscode, 1, 7)=="3768338"*/ ///
	using `k12_test_scores'/k12_test_scores_clean.dta, clear
merge 1:1 merge_id_k12_test_scores using "$datadir_clean/sbac/va_samples.dta" ///
	, nogen keepusing(touse_*)

* Merge to lagged scores
merge 1:1 merge_id_k12_test_scores using `k12_test_scores'/k12_lag_test_scores_clean.dta, nogen keep(1 3) ///
	keepusing( ///
		L3_cst_ela_z_score ///
		L3_sbac_ela_z_score ///
		L4_cst_ela_z_score ///
		L5_cst_ela_z_score ///
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
		peer_L5_cst_ela_z_score ///
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
keep if conventional_school==1

* Exclude schools where more than 25 percent of students are receiving special education services

* Drop if a student is receiving instruction at home, in a hospital, or in a school serving disabled students solely

* Drop if 10 or fewer students per school
drop if cohort_size<=10
