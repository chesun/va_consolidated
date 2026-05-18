/*------------------------------------------------------------------------------
do/va/va_corr.do — VA estimate correlations across spec combinations
================================================================================

PURPOSE
    Print correlation matrix of VA estimates across 8 (sample × control × peer)
    combinations per (version, va_outcome):
      1) base sample, base control
      2) las sample, base control
      3) las sample, leave-out-score + sibling control
      4) las sample, las (kitchen-sink) control
    each at no-peer and with-peer.

    Diagnostic-only output (printed to log; no .dta or .csv produced).

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after `merge_va_est.do'
    produces `va_<outcome>_all.dta' that this consumes.

INPUTS
    CANONICAL (read):
      $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_<outcome>_all.dta
                                          — merged per-outcome VA dataset (from merge_va_est.do)

    Helper (CONSOLIDATED):
      $consolidated_dir/do/va/helpers/macros_va.doh

OUTPUTS
    No .dta / .csv on disk (correlations printed to log).
    CANONICAL:
      $logdir/va/va_corr.smcl + .log         — per-do-file log (this is where corrs land)

ROLE IN ADR-0021 SANDBOX
    Reads CANONICAL only.  Writes ONLY to `$logdir/`.  Sandbox-clean.

RELOCATION HISTORY (per plan v3 §3.3 step 3 batch 3c1, applied 2026-05-08)
    Source:      cde_va_project_fork/do_files/sbac/va_corr.do
    Destination: do/va/va_corr.do
    Path repointing under ADR-0021:
      - L20 cd $vaprojdir preserved + restored at end.
      - L24 log target -> $logdir
      - L34 helper include -> $consolidated_dir/do/va/helpers/macros_va.doh
      - L53 use ... -> $estimates_dir
      - L87-88 translate -> $logdir

    PREDECESSOR LATENT BUG: predecessor uses `\`date2''` at L82 but never
    sets `local date2 = ...`.  Resolves to empty string in display.  Verbatim
    preservation per ADR-0021; cosmetic-only impact (display message).
    Phase 1b naming/clarity may resolve.  Note: predecessor also references
    `\`\`va_outcome'_str''` in the `di` block (L56-62) — these `_str` locals
    are defined in `macros_va.doh` (e.g., `ela_str`, `math_str`, `enr_str`)
    so they propagate via the include and resolve correctly.

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina Sun)
    First created by Christina Sun November 1, 2022.
    2022-12-29: Added v1/v2 prior-score loop.
    2026-05-08: Relocated to consolidated repo per plan v3 §3.3 step 3 batch 3c1.

REFERENCES
    Plan: §3.3 step 3
    ADRs: 0004, 0009, 0021
------------------------------------------------------------------------------*/


********************************************************************************
/* Correlation for VA estimates from different sample-control combinations */
********************************************************************************

*****************************************************
* First created by Christina Sun November 1, 2022
*****************************************************

/* To run this do file, type:
do $consolidated_dir/do/va/va_corr.do
 */

/* CHANGE LOG:

12/29/2022: added loop for v1 and v2 versions of VA samples
v1: original prior score controls for ELA and Math
v2: same prior score controls for ELA and math
 */


* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"


cap mkdir "$logdir/va"
 cd $vaprojdir

 log close _all

 log using "$logdir/va/va_corr.smcl", replace text

 di as text _n "{hline 80}"
 di as text "va_corr.do — RUN START: `c(current_date)' `c(current_time)'"
 di as text "{hline 80}"

 graph drop _all
 set more off
 set varabbrev off
 set graphics off
 set scheme s1color
 set seed 1984

// include the macros
include $consolidated_dir/do/va/helpers/macros_va.doh

local date1 = c(current_date)
local time1 = c(current_time)
di "`date1' `time1'"


foreach version in v1 v2 {

  //------------------------------------------------------------------------
  // correlation matrix of VA estimates between the following 8 specifications:
  // Base sample, base control
  // kitchen sink sample, base control
  // kitchen sink sample, leave out score & sibling control
  // ktichen sink sample, kitchen sink control
  // each of the above 4 with and without peer controls
  //------------------------------------------------------------------------

  foreach va_outcome in ela math enr enr_2year enr_4year {
    use "$estimates_dir/va_cfr_all_`version'/va_est_dta/va_`va_outcome'_all.dta", clear

    #delimit ;
    di "Correlation matrix for ``va_outcome'_str' VA estimates between
    1) ase sample, base control
    2) kitchen sink sample, base control
    3) kitchen sink sample, leave out score & sibling control
    4) ktichen sink sample, kitchen sink control
    and each of these without and with peer effects"
    ;
    #delimit cr

    corr va_`va_outcome'_b_sp_b_ct va_`va_outcome'_b_sp_b_ct_p ///
      va_`va_outcome'_las_sp_b_ct va_`va_outcome'_las_sp_b_ct_p ///
      va_`va_outcome'_las_sp_ls_ct va_`va_outcome'_las_sp_ls_ct_p ///
      va_`va_outcome'_las_sp_las_ct va_`va_outcome'_las_sp_las_ct_p


  }

}




// At the end of the .do file or section
local time2 = c(current_time)

 di "Start date time for va_corr.do: `date1' `time1'"
 di "End date time: `date2' `time2'"


cap log close

cap translate "$logdir/va/va_corr.smcl" ///
  "$logdir/va/va_corr.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
