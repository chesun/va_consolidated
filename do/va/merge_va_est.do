/*------------------------------------------------------------------------------
do/va/merge_va_est.do — merge all sample × control × outcome VA estimates
================================================================================

PURPOSE
    Consolidate the per-cell VA estimate .dta files (from va_score_all.do
    and va_out_all.do) into a master VA dataset.  For each (version, va_outcome):
      1. Iterates over the standard 16-spec framework (va_controls × samples
         from `macros_va_all_samples_controls.doh').
      2. Merges each per-cell `va_<outcome>_<sample>_sp_<va_ctrl>_ct.dta` file
         on cdscode-year keys.
      3. Renames `va_cfr_g11_<outcome>` -> `va_<outcome>_<sample>_sp_<va_ctrl>_ct`
         (and `_peer` variant -> `_p`).  For postsecondary outcomes (enr,
         enr_2year, enr_4year), also renames the DK VA estimates to
         `va_dk_<outcome>_<sample>_sp_<va_ctrl>_ct[_p]`.
      4. Saves merged per-outcome dataset to `va_<outcome>_all.dta`.
      5. Saves super-master `va_all.dta` (merged across all 5 outcomes).

    `va_all.dta` is the dataset consumed by `va_corr.do' and
    `reg_out_va_all.do' / `reg_out_va_dk_all.do' downstream.

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after `va_*_all.do' and
    `va_*_fb_all.do' produce per-cell estimate dtas.

PRODUCTION STATUS
    GATED OFF in predecessor `do_all.do' (via `local do_va = 0').

INPUTS
    CANONICAL (read):
      $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_<outcome>_<sample>_sp_<va_ctrl>_ct.dta
                                          — per-cell VA estimates (from batch 3a;
                                            5 outcomes × ~16 spec cells × 2 versions)

    Helpers (CONSOLIDATED):
      $consolidated_dir/do/va/helpers/{macros_va,macros_va_all_samples_controls}.doh

OUTPUTS
    CANONICAL (write per ADR-0021 sandbox):
      $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_<outcome>_all.dta
                                          — per-outcome merged estimates (5 outcomes × 2 versions)
      $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_all.dta
                                          — super-master across all 5 outcomes
      $logdir/va/merge_va_est.smcl + .log    — per-do-file log

ROLE IN ADR-0021 SANDBOX
    Reads CANONICAL .dta only.  Writes ONLY to CANONICAL `$estimates_dir/...`
    and `$logdir/`.  Sandbox-clean.

RELOCATION HISTORY (per plan v3 §3.3 step 3 batch 3c1, applied 2026-05-08)
    Source:      cde_va_project_fork/do_files/sbac/merge_va_est.do
    Destination: do/va/merge_va_est.do
    Path repointing under ADR-0021 (analysis logic preserved verbatim):
      - L22 cd $vaprojdir preserved + restored at end.
      - L26 log target -> $logdir
      - L41, L43 helper includes -> $consolidated_dir/do/va/helpers/...
      - L62 use ... -> $estimates_dir
      - L82, L86-90 use/save -> $estimates_dir
      - L91 save super-master -> $estimates_dir
      - L120-121 translate -> $logdir

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina (Che) Sun)
    First created by Christina (Che) Sun October 31, 2022.
    2022-12-29: Added v1/v2 prior-score loop.
    2023-03-03: Added code to merge all VA outcome estimates into one dataset.
    2026-05-08: Relocated to consolidated repo per plan v3 §3.3 step 3 batch 3c1.

REFERENCES
    Plan: §3.3 step 3
    ADRs: 0004, 0009, 0021
------------------------------------------------------------------------------*/


********************************************************************************
/* merge all VA estimates into one dataset */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun October 31, 2022
*****************************************************

/* To run this do file, type:
do $consolidated_dir/do/va/merge_va_est.do
 */

/* CHANGE LOG:

12/29/2022: added loop for v1 and v2 versions of VA samples
v1: original prior score controls for ELA and Math
v2: same prior score controls for ELA and math

03/03/2023: added code to merge all VA outcome estimates into one dataset
 */


* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$estimates_dir"
cap mkdir "$estimates_dir/va_cfr_all_v1"
cap mkdir "$estimates_dir/va_cfr_all_v1/va_est_dta"
cap mkdir "$estimates_dir/va_cfr_all_v2"
cap mkdir "$estimates_dir/va_cfr_all_v2/va_est_dta"
cap mkdir "$logdir"


cap mkdir "$logdir/va"
 cd $vaprojdir

 log close _all

 log using "$logdir/va/merge_va_est.smcl", replace text

 di as text _n "{hline 80}"
 di as text "merge_va_est.do — RUN START: `c(current_date)' `c(current_time)'"
 di as text "{hline 80}"

 graph drop _all
 set more off
 set varabbrev off
 set graphics off
 set scheme s1color
 set seed 1984


 local date1_va_scatter_plot = c(current_date)
 local time1_va_scatter_plot = c(current_time)


// include the macros
include $consolidated_dir/do/va/helpers/macros_va.doh

include $consolidated_dir/do/va/helpers/macros_va_all_samples_controls.doh


//--------------------------------------------------------------
// merge all sample-control combination VA estimates
//--------------------------------------------------------------

foreach version in v1 v2 {
  di "VA version: `version'"


  foreach va_outcome in ela math enr enr_2year enr_4year {
    // use a macro to store the command to initialize the data for merge
    local merge_command use
    local merge_options clear

    foreach va_ctrl of local va_controls {
      foreach sample of local `va_ctrl'_ctrl_samples {

        `merge_command' "$estimates_dir/va_cfr_all_`version'/va_est_dta/va_`va_outcome'_`sample'_sp_`va_ctrl'_ct.dta", `merge_options'
        rename va_cfr_g11_`va_outcome' va_`va_outcome'_`sample'_sp_`va_ctrl'_ct
        rename va_cfr_g11_`va_outcome'_peer va_`va_outcome'_`sample'_sp_`va_ctrl'_ct_p

        label var va_`va_outcome'_`sample'_sp_`va_ctrl'_ct "VA from `sample' sample and `va_ctrl' control"
        label var va_`va_outcome'_`sample'_sp_`va_ctrl'_ct_p "VA from `sample' sample and `va_ctrl' control with peer controls"

        if "`va_outcome'"=="enr"|"`va_outcome'"=="enr_2year"|"`va_outcome'"=="enr_4year" {
          rename va_cfr_g11_`va_outcome'_dk va_dk_`va_outcome'_`sample'_sp_`va_ctrl'_ct
          rename va_cfr_g11_`va_outcome'_dk_peer va_dk_`va_outcome'_`sample'_sp_`va_ctrl'_ct_p

          label var va_dk_`va_outcome'_`sample'_sp_`va_ctrl'_ct "DK VA from `sample' sample and `va_ctrl' control"
          label var va_dk_`va_outcome'_`sample'_sp_`va_ctrl'_ct_p "DK VA from `sample' sample and `va_ctrl' control with peer controls"
        }

        local merge_command "merge 1:1 cdscode year using"
        local merge_options nogen
      }
    }
    label data "`va_outcome' estimates from all sample and control combinations"
    save "$estimates_dir/va_cfr_all_`version'/va_est_dta/va_`va_outcome'_all.dta", replace
  }

  // merge all outcome VA estimates into one dataset
  use "$estimates_dir/va_cfr_all_`version'/va_est_dta/va_ela_all.dta", clear
  merge 1:1 cdscode year using "$estimates_dir/va_cfr_all_`version'/va_est_dta/va_math_all.dta", nogen
  merge 1:1 cdscode year using "$estimates_dir/va_cfr_all_`version'/va_est_dta/va_enr_all.dta", nogen
  merge 1:1 cdscode year using "$estimates_dir/va_cfr_all_`version'/va_est_dta/va_enr_2year_all.dta", nogen
  merge 1:1 cdscode year using "$estimates_dir/va_cfr_all_`version'/va_est_dta/va_enr_4year_all.dta", nogen
  save "$estimates_dir/va_cfr_all_`version'/va_est_dta/va_all.dta", replace



}


local date2_va_scatter_plot = c(current_date)
local time2_va_scatter_plot = c(current_time)

di "Do file merge_va_est.do start date time: `date1_va_scatter_plot' `time1_va_scatter_plot'"
di "End date time: `date2_va_scatter_plot' `time2_va_scatter_plot'"


cap log close
cap translate "$logdir/va/merge_va_est.smcl" ///
  "$logdir/va/merge_va_est.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
