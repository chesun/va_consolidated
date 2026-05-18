/*------------------------------------------------------------------------------
do/va/prior_decile_original_sample.do — prior-score deciles for outcome regs
================================================================================

PURPOSE
    Build student-level prior-score deciles + race/sex/econ-disadvantage
    indicators from the base outcome VA sample (out_b.dta).  This is consumed
    by the outcome regression scripts (`reg_out_va_all.do`, `reg_out_va_dk_all.do`)
    for heterogeneity analyses (interactions of VA with prior-score deciles
    and demographic groups).

    Pipeline:
      1. Load `$datadir_clean/va_samples_v1/out_b.dta` (v1 base outcome sample).
      2. Compute `prior_<subj>_z_score_xtile` (deciles via `xtile ..., n(10)`)
         for ELA and Math prior scores.
      3. Build a race factor variable from binary indicators (eth_black/
         eth_hispanic/eth_asian/eth_white/eth_other).
      4. Collapse to student level and save.
      5. Repeat with `out_a.dta` (ACS sample) for census-tract median+mean
         hh-income deciles → save `census_income_decile_a_sample.dta`.

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after `va_*_all.do' have
    produced their estimate dtas.  Consumed by `reg_out_va_all.do' and
    `reg_out_va_dk_all.do' (batch 3c2).

PRODUCTION STATUS
    GATED OFF in predecessor `do_all.do' (`local do_va = 0').

INPUTS
    CANONICAL (read):
      $datadir_clean/va_samples_v1/out_b.dta — v1 base outcome sample (batch 2b output)
      $datadir_clean/va_samples_v1/out_a.dta — v1 ACS outcome sample

    LEGACY (read-only per ADR-0021):
      $caschls_projdir/do/share/siblingvaregs/vafilemacros.doh
                                          — caschls helper; defines locals like
                                            `ufamilyxwalk' that may be referenced
                                            downstream.  Same pattern as
                                            do/sibling_xwalk/siblingoutxwalk.do
                                            relocation per ADR-0005.

    Helpers (CONSOLIDATED):
      $consolidated_dir/do/va/helpers/macros_va.doh

OUTPUTS
    CANONICAL (write per ADR-0021 sandbox):
      $datadir_clean/sbac/prior_decile_original_sample.dta
                                          — student-level prior deciles + race/sex/econ
      $datadir_clean/sbac/census_income_decile_a_sample.dta
                                          — student-level census income deciles
      $logdir/va/prior_decile_original_sample.smcl + .log

ROLE IN ADR-0021 SANDBOX
    Reads CANONICAL sample dtas + LEGACY caschls helper.  Writes ONLY to
    CANONICAL `$datadir_clean/sbac/...` and `$logdir/`.  Sandbox-clean.

RELOCATION HISTORY (per plan v3 §3.3 step 3 batch 3c1, applied 2026-05-08)
    Source:      cde_va_project_fork/do_files/sbac/prior_decile_original_sample.do
    Destination: do/va/prior_decile_original_sample.do
    Path repointing under ADR-0021:
      - L33 log target -> $logdir
      - L37 cd $vaprojdir preserved + restored at end.
      - L40 `include $projdir/do/share/siblingvaregs/vafilemacros.doh'
         -> alias-before-include pattern: `global projdir "$caschls_projdir"'
            then `include $caschls_projdir/do/share/siblingvaregs/vafilemacros.doh'
         (per [LEARN:stata] LEGACY-include macro-trace + siblingoutxwalk.do
         precedent).  $projdir not bound in do/settings.do; alias is benign
         because nothing else in pipeline references $projdir.
      - L43 macros_va.doh include -> $consolidated_dir/do/va/helpers/...
      - L76, L103 use ... -> $datadir_clean/va_samples_v1/...
      - L98, L109 save ... -> $datadir_clean/sbac/... (CANONICAL; was LEGACY $vaprojdir/data/sbac/)
      - L120-121 translate -> $logdir

    Note: the predecessor file had a long commented-out block (L55-72) that
    re-creates the VA sample via `include create_va_sample.doh` etc.  This
    block is preserved verbatim per ADR-0021 — if uncommented, the
    `do_files/...` paths inside would still need repointing (Phase 1b
    naming/clarity work).

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina (Che) Sun)
    First written on June 2, 2022.
    2024-01-12: Added race factor variable.
    2026-05-08: Relocated to consolidated repo per plan v3 §3.3 step 3 batch 3c1;
                $projdir aliased to $caschls_projdir before LEGACY include
                (per siblingoutxwalk.do precedent).

REFERENCES
    Plan: §3.3 step 3
    ADRs: 0004, 0005 (siblingoutxwalk.do precedent for $projdir alias),
          0009, 0021
    MEMORY: [LEARN:stata] 2026-04-30 LEGACY-include macro-trace + $projdir alias pattern
------------------------------------------------------------------------------*/


********************************************************************************
/* Creates prior score deciles using the original 11th grade VA sample for merge
with sibling census restricted sample
 */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on June 2, 2022 ***************************

/* To run this do file:

do $consolidated_dir/do/va/prior_decile_original_sample.do

 */

/* CHANGE LOG
01/12/2024:
create a race factor variable
*/


* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/sbac"
cap mkdir "$logdir"


cap mkdir "$logdir/va"
clear all
graph drop _all
set more off
set varabbrev off
set scheme s1color
//capture log close: Stata should not complain if there is no log open to close
cap log close _all

/* set trace on */


//starting log file
log using "$logdir/va/prior_decile_original_sample.smcl", replace text

di as text _n "{hline 80}"
di as text "prior_decile_original_sample.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"

/* change directory to common_core_va project directory for all value added
do files because some called subroutines written by Matt may use relative file paths  */
cd $vaprojdir

/* $projdir alias before LEGACY include (per [LEARN:stata] 2026-04-30
   + siblingoutxwalk.do precedent).  vafilemacros.doh defines locals like
   `ufamilyxwalk "$projdir/dta/siblingxwalk/ufamilyxwalk"' which need
   $projdir to resolve to the caschls dir.  do/settings.do does NOT define
   $projdir; we alias to $caschls_projdir here.  Side effect (global remains
   set for the Stata session) is benign because nothing else in the
   consolidated pipeline references $projdir. */
global projdir "$caschls_projdir"

/* file path macros for datasets */
include $caschls_projdir/do/share/siblingvaregs/vafilemacros.doh

//run Matt's do helper file to set the local macros for VA project
include $consolidated_dir/do/va/helpers/macros_va.doh

macro list

//startomg timer
timer on 1


********************************************************************************
* begin main code


/* // create VA sample
include $vaprojdir/do_files/sbac/create_va_sample.doh

// merge on postsecondary outcomes
do do_files/merge_k12_postsecondary.doh enr_only
drop enr enr_2year enr_4year
rename enr_ontime enr
rename enr_ontime_2year enr_2year
rename enr_ontime_4year enr_4year

// Save temporary dataset
compress
tempfile va_dataset
save `va_dataset'

// create the postsecondary outcome VA sample and saves temp dataset called va_g11_dataset
include $vaprojdir/do_files/sbac/create_va_g11_out_sample.doh
 */

// load the base outcome sample

use "$datadir_clean/va_samples_v1/out_b.dta", clear

* calculate Prior Scores Quantiles
xtile prior_ela_z_score_xtile = prior_ela_z_score, n(10)
xtile prior_math_z_score_xtile = prior_math_z_score, n(10)

// create a race variable
gen race = .
replace race = 1 if eth_black == 1
replace race = 2 if eth_hispanic == 1
replace race = 3 if eth_asian == 1
replace race = 4 if eth_white == 1
replace race = 5 if eth_other == 1

label define racelabel 1 "Black" 2 "Hispanic" 3 "Asian" 4 "White" 5 "Other"
label values race racelabel


collapse (mean) prior_ela_z_score_xtile prior_math_z_score_xtile ///
  (max) race male econ_disadvantage, by(state_student_id)

keep state_student_id prior_ela_z_score_xtile prior_math_z_score_xtile race male econ_disadvantage
save "$datadir_clean/sbac/prior_decile_original_sample.dta", replace



/* create median and mean hh income deciles for the acs sample  */
use "$datadir_clean/va_samples_v1/out_a.dta", clear

xtile inc_median_hh_xtile = inc_median_hh, n(10)
xtile inc_mean_hh_xtile = inc_median_hh, n(10)

collapse (mean) inc_median_hh_xtile inc_mean_hh_xtile, by(state_student_id)
save "$datadir_clean/sbac/census_income_decile_a_sample.dta", replace




timer off 1
timer list

set trace off

cap log close
cap translate "$logdir/va/prior_decile_original_sample.smcl" ///
  "$logdir/va/prior_decile_original_sample.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
