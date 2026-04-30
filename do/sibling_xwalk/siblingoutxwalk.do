/*------------------------------------------------------------------------------
do/sibling_xwalk/siblingoutxwalk.do — sibling enrollment-outcomes crosswalk
================================================================================

PURPOSE
    Build the sibling enrollment-outcomes crosswalk: a school-year × ufamilyid
    dataset with indicators for whether a student has older siblings, and
    whether those older siblings (a) matched to postsecondary outcomes data
    and (b) enrolled in 2-year / 4-year college.  Used downstream as the
    sibling-controls input for VA estimation (sample tags `s`, `ls`, `as`,
    `las`, `sd`, `lsd`, `asd`, `lasd` per ADR-0004).

    Pipeline shape:
      (1) merge full K12 test-score sample to postsecondary outcomes
          (via Matt's merge_k12_postsecondary.doh per ADR-0017)
      (2) collapse to ssid level
      (3) merge on the unique-family-id crosswalk (ufamilyxwalk)
      (4) compute older-sibling postsec-match counts + enrollment indicators
          (via rangestat over birth_order within ufamilyid)
      (5) compute lag-1 / lag-2 older-sibling outcome indicators
      (6) save sibling-outcomes crosswalk to canonical $datadir_clean

INVOKED FROM
    `do/main.do` Phase 2 (run_samples block).

INPUTS
    LEGACY (read-only per ADR-0021 sandbox principle):
      $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta
                                          — restricted-access raw K12 scores
      $caschls_projdir/do/share/siblingvaregs/vafilemacros.doh
                                          — defines local `ufamilyxwalk' macro
      $vaprojdir/do_files/sbac/macros_va.doh
                                          — Christina-owned VA macros
      $vaprojdir/do_files/merge_k12_postsecondary.doh
                                          — Matt's K12↔postsec merger (untouched per ADR-0017)
      `ufamilyxwalk' macro -> $caschls_projdir/dta/siblingxwalk/ufamilyxwalk.dta
                                          — pre-built family-id crosswalk

OUTPUTS
    CANONICAL (write per ADR-0021 sandbox principle):
      $datadir_clean/common_core_va/k12_postsecondary_out_merge.dta
                                          — full K12 sample × postsec outcomes
                                            (intermediate; read back at step 3)
      $datadir_clean/siblingxwalk/sibling_out_xwalk.dta
                                          — final sibling-outcomes crosswalk
      $logdir/siblingoutxwalk.smcl + .log — per-do-file log

ROLE IN ADR-0021 SANDBOX
    Reads LEGACY paths for (a) static predecessor inputs (caschls helpers,
    Matt's merge .doh) and (b) restricted-access raw K12 data on Scribe.
    Writes ONLY to CANONICAL paths under $consolidated_dir.  Sandbox-clean.

RELOCATION HISTORY (per ADR-0005, applied 2026-04-30)
    Source:      caschls/do/share/siblingvaregs/siblingoutxwalk.do (predecessor)
    Destination: do/sibling_xwalk/siblingoutxwalk.do (this file)
    Rationale:   N1 verdict (chunk-5 audit, reaffirmed in round-2): SAFE to
                 relocate — no internal references to the parent caschls dir.
                 Folder name `do/sibling_xwalk/` already reserved per CLAUDE.md
                 layout (the only file from the deprecated siblingvaregs/
                 directory that survives consolidation per ADR-0004).
    Caller-update protocol: predecessor callers (cde_va_project_fork/
                 do_files/do_all.do:142 + caschls/do/master.do:103) untouched
                 in this commit per plan v3 §3.3 step 5 parenthetical
                 ("both will themselves become Phase 1a archive once main.do
                 is built").  Wholesale predecessor retirement at Phase 1a
                 §3.5 golden-master verification supersedes the per-caller
                 edit step prescribed in ADR-0005's strict reading.

    Path repointing under ADR-0021 sandbox principle (analysis logic
    preserved verbatim; only path globals + log routing changed):
      - $projdir prefix on includes -> $caschls_projdir (explicit-named global
        per do/settings.do "LEGACY PATHS" comment block)
      - $projdir/log/share/siblingvaregs/sibling_out_xwalk.smcl
        -> $logdir/siblingoutxwalk.smcl (CANONICAL)
      - $projdir/dta/common_core_va/k12_postsecondary_out_merge
        -> $datadir_clean/common_core_va/k12_postsecondary_out_merge (CANONICAL)
      - $projdir/dta/siblingxwalk/sibling_out_xwalk
        -> $datadir_clean/siblingxwalk/sibling_out_xwalk (CANONICAL)
      - cd $vaprojdir preserved (some helpers may rely on CWD); cd back to
        $consolidated_dir at end so subsequent main.do invocations see CWD
        = $consolidated_dir.
      - `global projdir "$caschls_projdir"' aliased before LEGACY includes
        so vafilemacros.doh (L18-24) and macros_va.doh (L29-31) resolve
        their `$projdir/...' local definitions correctly.  Required because
        do/settings.do does NOT define $projdir; predecessor relied on
        outer-caller binding.  Caught by coder-critic round 1 (Critical
        finding); resolution committed in same first-relocation commit.

    Coder-critic round 1 verdict: 67/100 BLOCK on undefined $projdir
    (Critical).  Round 2 dispatched after the alias fix above + the
    [LEARN:stata] MEMORY entry + phase-1-review.md §2 self-check addition
    for LEGACY-include macro tracing.

ORIGINAL CHANGE LOG (preserved from predecessor; written by Che Sun)
    First written 2021-09-22.
    2021-10-22: Corrected wrong values for has-sibling matching to postsec
                indicators.  Problem was Stata treating missing as greater
                than nonmissing, so >0 logic returned true on missing.
    2022-04-28: Added indicator for sibling-controls sample for 2-yr and 4-yr
                sibling enrollment controls.  Sample = obs with at least 1
                sibling matched to postsec outcomes AND non-missing for the
                2yr/4yr enr sibling controls.
    2023-01-25: Added code to create outcome dummies for lag-1 and lag-2
                older siblings.
    2023-07-27: Moved code that merges entire K12 test-score sample onto
                postsec outcomes from createvasamples.do to the beginning
                of this file.
    2026-04-30: Relocated to consolidated repo per ADR-0005; path globals
                repointed to CANONICAL per ADR-0021; analysis logic verbatim.

REFERENCES
    Audit:      quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md (N1)
    Plan:       quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §3.3 step 5
    ADRs:       0004 (sibling-VA canonical pipeline), 0005 (this relocation),
                0017 (Matt's merge_k12_postsecondary.doh untouched),
                0021 (description convention; sandbox-write rule)
------------------------------------------------------------------------------*/


clear all
set more off
set varabbrev off
set scheme s1color

cap log close _all

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/common_core_va"
cap mkdir "$datadir_clean/siblingxwalk"
cap mkdir "$logdir"

* --- per-do-file log (CANONICAL per ADR-0021 + plan v3 §5.1 step 2) ----------
log using "$logdir/siblingoutxwalk.smcl", replace text

di as text _n "{hline 80}"
di as text "siblingoutxwalk.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


/* file path macros -- LEGACY includes preserved per ADR-0021 (static
   predecessor helpers; not yet relocated).  $projdir of the predecessor
   maps to $caschls_projdir in our settings.do per the LEGACY PATHS comment
   block in do/settings.do.

   IMPORTANT — `$projdir` aliasing for LEGACY-include compatibility:
   Both `vafilemacros.doh` (L18-24) and `macros_va.doh` (L29-31) define
   locals like `local ufamilyxwalk "$projdir/dta/siblingxwalk/ufamilyxwalk"'.
   Stata expands `$projdir` at the line where the local is defined (during
   the include).  In the predecessor pipeline, $projdir was bound to the
   caschls dir at the outer caller.  In our consolidated repo, $projdir is
   NOT defined in do/settings.do (only $caschls_projdir is — per the
   "LEGACY PATHS" comment block).  Without aliasing, `$projdir` expands to
   empty string and `\`ufamilyxwalk'` resolves to `/dta/siblingxwalk/ufamilyxwalk`
   — a broken absolute path; the merge at "merge 1:1 state_student_id using
   \`ufamilyxwalk''" fails with file-not-found.  Alias here so both LEGACY
   includes resolve correctly.  This is the relocation-time pattern for any
   relocated script that includes a LEGACY .doh referencing `$projdir` —
   see MEMORY.md [LEARN:stata] 2026-04-30.  Side effect: $projdir remains
   set globally for the rest of the Stata session, which is benign (nothing
   else in the consolidated pipeline references $projdir).  */
global projdir "$caschls_projdir"

include $caschls_projdir/do/share/siblingvaregs/vafilemacros.doh
// VA macros
include $vaprojdir/do_files/sbac/macros_va.doh

* The predecessor cd'd to $vaprojdir before downstream merges (some helpers
* may rely on relative paths).  Preserved here for behavior parity; restored
* to $consolidated_dir at end of file so subsequent main.do invocations see
* the canonical CWD.
cd $vaprojdir


* --- timer (preserved from predecessor) --------------------------------------
timer on 1


********************************************************************************
*** This merges the entire k12 test score sample onto postsecondary outcomes
//the output dataset is used subsequently
use merge_id_k12_test_scores all_students_sample first_scores_sample ///
  dataset test cdscode school_id state_student_id year grade ///
  cohort_size ///
  using $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta, clear
// merge on postsecondary Outcomes
do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only
drop enr enr_2year enr_4year
rename enr_ontime enr
rename enr_ontime_2year enr_2year
rename enr_ontime_4year enr_4year
drop if missing(state_student_id)

//save the merged k12 to postsecondary outcome dataset (CANONICAL output per ADR-0021)
compress
label data "Full K-12 test scores merged to postsecondary outcomes"
save "$datadir_clean/common_core_va/k12_postsecondary_out_merge", replace




********************************************************************************
//create sibling college outcome vars
//First load the k12 test score sample matched to postsecondary outcome data

use "$datadir_clean/common_core_va/k12_postsecondary_out_merge", clear

//generate an indicator for observations matched to postsecondary outcomes data
gen k12_postsec_match = 0
replace k12_postsec_match = 1 if k12_nsc_match == 1 | k12_ccc_match == 1 | k12_csu_match == 1
label var k12_postsec_match "Indicator for k12 observation matched to postsecondary data (NSC, CCC, or CSU)"

//collapse to ssid level
collapse (max) enr enr_2year enr_4year k12_postsec_match, by(state_student_id)

//merge on unique family id
merge 1:1 state_student_id using `ufamilyxwalk'
/*
Result                      Number of obs
    -----------------------------------------
    Not matched                     8,718,171
        from master                 8,590,681  (_merge==1)
        from using                    127,490  (_merge==2)

    Matched                         3,957,189  (_merge==3)
    -----------------------------------------

 */

//keep only the sample of matched siblings
drop if missing(ufamilyid)
//mark sibling sample who are matched to postsecondary outcomes for merged observations
gen sibling_out_sample = 0
replace sibling_out_sample = 1 if _merge==3 & k12_postsec_match == 1
label var sibling_out_sample "Indicator for sibling sample that are matched to postsecondary outcomes"
drop _merge

/*

. count if k12_postsec_match == 1
  2,466,979

. count if k12_postsec_match == 1 & sibling_out_sample==1
  2,466,979

All of the k12_postsec matched observations were matched to the sibling sample
 */

//mark students who have older siblings
gen has_older_sibling = 0
replace has_older_sibling = 1 if numsiblings_older > 0
label var has_older_sibling "Has at least 1 older sibling"

/* NEED TO CREATE PROPS ENROLLED FOR OLDER SIBLINGS  */
//number of siblings total in the family ranges from 1 to 10, so max number of older siblings is 9

/* this rangestat command calculates the sum of the variable for observations in
the interval between birth_order - lower_bound and birth_order - 1, which is all the older siblings  */
/* NOTE: rangestat treats missing enr vars as 0 */

/*
sort ufamilyid birth_order
gen lower_bound = -numsiblings_older
local outcomes enr enr_2year enr_4year
foreach i of local outcomes {
  rangestat (sum) `i', interval(birth_order, lower_bound, -1) by(ufamilyid)
  rename `i'_sum numsiblings_older_`i'
  label var numsiblings_older_`i' "Number of older siblings with `i'==1"
  gen propsiblings_older_`i' = numsiblings_older_`i' / numsiblings_older
  label var propsiblings_older_`i' "Proportion of older siblings with `i'==1"
}

drop lower_bound
*/

/* Create dummies for whether the student has an older sibling who was matched to
postsecondary outcomes and who was enrolled in 2 year, and 4 year */
sort ufamilyid birth_order
gen lower_bound = -numsiblings_older
//create a dummy for whether at least one older sibling was matched to postsecondary outcomes
rangestat (sum) k12_postsec_match, interval(birth_order, lower_bound, -1) by(ufamilyid)
rename k12_postsec_match_sum num_older_sibling_postsec_match
label var num_older_sibling_postsec_match "Number of older sibling matched to postsecondary outcomes"

/* SUPER IMPORTANT: STATA TREATS MISSING AS GREATER THAN ANY NONMISSING NUMBER!!!!!! */
gen has_older_sibling_postsec_match = 0
replace has_older_sibling_postsec_match = 1 if !missing(num_older_sibling_postsec_match) & num_older_sibling_postsec_match > 0
label var has_older_sibling_postsec_match "Has at least one older sibling matched to postsecondary outcomes"

local outcomes enr enr_2year enr_4year
foreach i of local outcomes {
  rangestat (sum) `i' if has_older_sibling_postsec_match == 1, interval(birth_order, lower_bound, -1) by(ufamilyid)
  rename `i'_sum numsiblings_older_`i'
  label var numsiblings_older_`i' "Number of older siblings that are matched to postsec outcomes with `i'==1"
  gen has_older_sibling_`i' = 0
  replace has_older_sibling_`i' = 1 if numsiblings_older_`i' > 0 & !missing(numsiblings_older_`i')
  label var has_older_sibling_`i' "Has at least 1 older sibling matched to postsec outcome and with `i' = 1"
}

drop lower_bound

// sample indicator for obs to use in VA with sibling 2 yr and 4 yr enrollment controls
// This sample consists of obs with at least 1 sibling matched to postsec outcomes, and who have non-missing for the sibling controls
gen sibling_2y_4y_controls_sample = 0
replace sibling_2y_4y_controls_sample = 1 if !mi(has_older_sibling_enr_2year) & !mi(has_older_sibling_enr_4year) & sibling_out_sample==1


// lag 1 older sibling and lag 2 older sibling
// degenerate interval bound for lag 1 and lag 2 older siblings for rangestat
bysort ufamilyid: gen lag1_bound = birth_order - 1
bysort ufamilyid: gen lag2_bound = birth_order - 2

foreach outcome in enr enr_2year enr_4year {
  // enrollment for lag 1 older sibling
  rangestat (max) `outcome' if has_older_sibling_postsec_match == 1, interval(birth_order, lag1_bound, lag1_bound) by(ufamilyid)
  rename `outcome'_max old1_sib_`outcome'
  label var old1_sib_`outcome' "`outcome' for first older sibling"
  // enrollment for lag 2 older sibling
  rangestat (max) `outcome' if has_older_sibling_postsec_match == 1, interval(birth_order, lag2_bound, lag2_bound) by(ufamilyid)
  rename `outcome'_max old2_sib_`outcome'
  label var old2_sib_`outcome' "`outcome' for second older sibling"

  gen touse_sib_lag1_lag2_`outcome' = 0
  replace touse_sib_lag1_lag2_`outcome' = 1 if !mi(old1_sib_`outcome') & !mi(old2_sib_`outcome')

}

gen touse_sib_lag = 0
replace touse_sib_lag = 1 if touse_sib_lag1_lag2_enr_2year == 1 & touse_sib_lag1_lag2_enr_4year == 1
drop lag1_bound lag2_bound




//create sibling outcomes crosswalk (CANONICAL output per ADR-0021)
compress
label data "Sibling enrollment outcomes crosswalk organized by unique families"
save "$datadir_clean/siblingxwalk/sibling_out_xwalk", replace




timer off 1
timer list


* --- WRAP-UP -----------------------------------------------------------------

di as text _n "{hline 80}"
di as text "siblingoutxwalk.do — RUN END: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"

* Restore CWD to $consolidated_dir for subsequent main.do invocations
* (this file's `cd $vaprojdir` above was preserved for behavior parity).
cd "$consolidated_dir"

cap log close
cap translate "$logdir/siblingoutxwalk.smcl" "$logdir/siblingoutxwalk.log", replace

* end of file
