/*------------------------------------------------------------------------------
do/va/va_spec_fb_tab.do — combined spec + FB test paper-shipping CSV table
================================================================================

PURPOSE
    Build the combined spec-test + FB-test summary table per (version,
    va_outcome) cell.  Reads the .ster files produced by the entry-point
    estimation scripts directly — does not depend on the per-subject /
    per-outcome _all.dta files from `va_*_spec_test_tab.do' and
    `va_*_fb_test_tab.do' (those are different summaries).

    For each of the 5 va_outcomes (ela, math, enr, enr_2year, enr_4year),
    extracts:
      - FB test coefs/SEs for {l, s, a, las} leave-out vars at las-sample
        × b-control × {no-peer, peer}
      - FB test coef/SE for {a} leave-out var at las-sample × ls-control
      - Spec-test coefs at 4 (sample, control) cells:
          (b, b), (las, b), (las, ls), (las, las)
      - Each at no-peer and with-peer variants (8 total `eststo`)
    Then exports via `esttab` to a CSV per (va_outcome).

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after the 4 `*_test_tab' files.

INPUTS
    CANONICAL (read):
      $estimates_dir/va_cfr_all_v[12]/fb_test/fb_<outcome>_las_sp_b_ct_<lovar>_lv.ster
      $estimates_dir/va_cfr_all_v[12]/fb_test/fb_p_<outcome>_las_sp_b_ct_<lovar>_lv.ster
      $estimates_dir/va_cfr_all_v[12]/fb_test/fb_<outcome>_las_sp_ls_ct_a_lv.ster (+peer variant)
      $estimates_dir/va_cfr_all_v[12]/spec_test/spec_<outcome>_<sample>_sp_<ctrl>_ct.ster (+peer variants)

    Helper (CONSOLIDATED):
      $consolidated_dir/do/va/helpers/macros_va.doh

OUTPUTS
    CANONICAL:
      $tables_dir/va_cfr_all_v[12]/combined/fb_spec_<outcome>.csv
                                          — paper-shipping CSV; one per outcome × version
      $logdir/va_spec_fb_tab.smcl + .log

ROLE IN ADR-0021 SANDBOX
    Reads CANONICAL .ster only (no LEGACY reads — predecessor doesn't include
    a predicted-prior-score branch in this file).  Writes ONLY to CANONICAL
    `$tables_dir/.../combined/...` and `$logdir/`.  Sandbox-clean.

RELOCATION HISTORY (per plan v3 §3.3 step 3 batch 3b, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/va_spec_fb_tab.do
    Destination: do/va/va_spec_fb_tab.do
    Path repointing under ADR-0021:
      - L24 cd $vaprojdir preserved + restored at end.
      - L28 log target -> $logdir
      - L41 helper include -> $consolidated_dir/do/va/helpers/macros_va.doh
      - L67, L79, L97, L107, L128, L137, L151, L173, L199, L212, L228, L236
        (all .ster reads) -> $estimates_dir/va_cfr_all_`version'/...
      - L245 esttab using -> $tables_dir/va_cfr_all_`version'/combined/fb_spec_`va_outcome'.csv
      - L274-275 translate -> $logdir

    NOTE: predecessor uses local string macros `\`b_str'`, `\`las_str'`, `\`ls_str'`
    in `estadd local` calls (lines 132, 133, 154, 155, 176, 177, 202, 203, 215,
    216, 231, 232, 239, 240).  These locals ARE defined in macros_va.doh at
    lines 560 (`local b_str "base"`), 600 (`local ls_str "leave out score &
    sibling"`), and 616 (`local las_str "leave out score & ACS & sibling"`).
    Locals propagate from the `include` of macros_va.doh into this file's
    scope; resolve correctly at runtime.  No fix needed.

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina Sun)
    First created by Christina Sun October 26, 2022.
    2022-12-29: Added v1/v2 prior-score loop.
    2026-05-07: Relocated to consolidated repo per plan v3 §3.3 step 3 batch 3b.

REFERENCES
    Plan: §3.3 step 3
    ADRs: 0004, 0009, 0012, 0021
------------------------------------------------------------------------------*/


********************************************************************************
/* tables that include spec test and FB test results for score and outcome VA */
********************************************************************************

*****************************************************
* First created by Christina Sun October 26, 2022
*****************************************************

/* To run this do file, type:
do $consolidated_dir/do/va/va_spec_fb_tab.do
 */

/* CHANGE LOG:

12/29/2022: added loop for v1 and v2 versions of VA samples
v1: original prior score controls for ELA and Math
v2: same prior score controls for ELA and math
 */

 /* Notes:
 use the reference category refcat() option in esttab for indicating sample and controls
  */


* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$tables_dir"
cap mkdir "$tables_dir/va_cfr_all_v1"
cap mkdir "$tables_dir/va_cfr_all_v1/combined"
cap mkdir "$tables_dir/va_cfr_all_v2"
cap mkdir "$tables_dir/va_cfr_all_v2/combined"
cap mkdir "$logdir"


 cd $vaprojdir

 log close _all

 log using "$logdir/va_spec_fb_tab.smcl", replace text

 di as text _n "{hline 80}"
 di as text "va_spec_fb_tab.do — RUN START: `c(current_date)' `c(current_time)'"
 di as text "{hline 80}"

 graph drop _all
 set more off
 set varabbrev off
 set graphics off
 set scheme s1color
 set seed 1984

 local date1 = c(current_date)
 local time1 = c(current_time)

// include the macros
include $consolidated_dir/do/va/helpers/macros_va.doh

foreach version in v1 v2 {

  //------------------------------------------------------------------------------
  // table with the following:
  // Base sample, base control;
  // las sample, base control;
  // las sample, ls control;
  // las sample, las control;
  // each of the above combination without peer contorls and with peer controls
  //------------------------------------------------------------------------------

  foreach va_outcome in ela math enr enr_2year enr_4year {
    //----------------------------------------------------------------------
    //first extract the coef and se from forecast bias tests
    //----------------------------------------------------------------------

    //----------------------------------------------------------------
    // kitchen sink sample (leave out score, ACS, and sibling)
    // base controls
    // Forecast bias test leave out var: l, a, s, las
    //----------------------------------------------------------------

    //////////// No peer controls
    foreach lovar in l s a las {
      est use $estimates_dir/va_cfr_all_`version'/fb_test/fb_`va_outcome'_las_sp_b_ct_`lovar'_lv.ster

      // store the coef estimates in a matrix and extract the fb test coef to store in local macro
      matrix b = e(b)
      local b_las_sp_b_ct_`lovar'_lv: di %5.3f b[1,1]
      // extract the standard error and store in a local macro
      matrix v = e(V)
      local se_las_sp_b_ct_`lovar'_lv: di %5.3f sqrt(v[1,1])
    }

    //////////// With peer contorls
    foreach lovar in l s a las {
      est use $estimates_dir/va_cfr_all_`version'/fb_test/fb_p_`va_outcome'_las_sp_b_ct_`lovar'_lv.ster

      // store the coef estimates in a matrix and extract the fb test coef to store in local macro
      matrix b = e(b)
      local b_las_sp_b_ct_`lovar'_lv_p: di %5.3f b[1,1]
      // extract the standard error and store in a local macro
      matrix v = e(V)
      local se_las_sp_b_ct_`lovar'_lv_p: di %5.3f sqrt(v[1,1])
    }


    //----------------------------------------------------------------
    // kitchen sink sample (leave out score, ACS, and sibling)
    // leave out score and sibling controls
    // Forecast bias test leave out var: ACS
    //----------------------------------------------------------------

    //////////// No peer controls
    est use $estimates_dir/va_cfr_all_`version'/fb_test/fb_`va_outcome'_las_sp_ls_ct_a_lv.ster
    // store the coef estimates in a matrix and extract the fb test coef to store in local macro
    matrix b = e(b)
    local b_las_sp_ls_ct_a_lv: di %5.3f b[1,1]
    // extract the standard error and store in a local macro
    matrix v = e(V)
    local se_las_sp_ls_ct_a_lv: di %5.3f sqrt(v[1,1])


    /////////// With peer controls
    est use $estimates_dir/va_cfr_all_`version'/fb_test/fb_p_`va_outcome'_las_sp_ls_ct_a_lv.ster
    // store the coef estimates in a matrix and extract the fb test coef to store in local macro
    matrix b = e(b)
    local b_las_sp_ls_ct_a_lv_p: di %5.3f b[1,1]
    // extract the standard error and store in a local macro
    matrix v = e(V)
    local se_las_sp_ls_ct_a_lv_p: di %5.3f sqrt(v[1,1])





    //----------------------------------------------------------------------
    // build the table
    //----------------------------------------------------------------------


    //----------------------------------------------------------------
    // base sample, base control
    //----------------------------------------------------------------
    // base sample base control, no peer
    est use $estimates_dir/va_cfr_all_`version'/spec_test/spec_`va_outcome'_b_sp_b_ct.ster
    eststo b_sp_b_ct

      // add rows to identify sample, control, and peer
      estadd local sample "`b_str'"
      estadd local control "`b_str'"
      estadd local peer "N"

    // base sample base control, peer controls
    est use $estimates_dir/va_cfr_all_`version'/spec_test/spec_p_`va_outcome'_b_sp_b_ct.ster
    eststo b_sp_b_ct_p

      estadd local sample "`b_str'"
      estadd local control "`b_str'"
      estadd local peer "Y"



    //----------------------------------------------------------------
    // ktichen sink sample, base control
    //----------------------------------------------------------------

    // loscore_acs_sib sample base control, no peer
    est use $estimates_dir/va_cfr_all_`version'/spec_test/spec_`va_outcome'_las_sp_b_ct.ster
    eststo las_sp_b_ct

      estadd local sample "`las_str'"
      estadd local control "`b_str'"
      estadd local peer "N"

      // add scalars for FB test coef and se
      estadd scalar b_fb_score = `b_las_sp_b_ct_l_lv'
      estadd scalar se_fb_score = `se_las_sp_b_ct_l_lv'

      estadd scalar b_fb_sibling = `b_las_sp_b_ct_s_lv'
      estadd scalar se_fb_sibling = `se_las_sp_b_ct_s_lv'

      estadd scalar b_fb_acs = `b_las_sp_b_ct_a_lv'
      estadd scalar se_fb_acs = `se_las_sp_b_ct_a_lv'

      estadd scalar b_fb_score_acs_sibling = `b_las_sp_b_ct_las_lv'
      estadd scalar se_fb_score_acs_sibling = `se_las_sp_b_ct_las_lv'


    // loscore_acs_sib sample base control, with peer controls
    est use $estimates_dir/va_cfr_all_`version'/spec_test/spec_p_`va_outcome'_las_sp_b_ct.ster
    eststo las_sp_b_ct_p

    estadd local sample "`las_str'"
    estadd local control "`b_str'"
      estadd local peer "Y"

      // add scalars for FB test coef and se
      estadd scalar b_fb_score = `b_las_sp_b_ct_l_lv_p'
      estadd scalar se_fb_score = `se_las_sp_b_ct_l_lv_p'

      estadd scalar b_fb_sibling = `b_las_sp_b_ct_s_lv_p'
      estadd scalar se_fb_sibling = `se_las_sp_b_ct_s_lv_p'

      estadd scalar b_fb_acs = `b_las_sp_b_ct_a_lv_p'
      estadd scalar se_fb_acs = `se_las_sp_b_ct_a_lv_p'

      estadd scalar b_fb_score_acs_sibling = `b_las_sp_b_ct_las_lv_p'
      estadd scalar se_fb_score_acs_sibling = `se_las_sp_b_ct_las_lv_p'


    //----------------------------------------------------------------
    // ktichen sink sample, sibling + leave out score control
    //----------------------------------------------------------------

    // no peer controls
    est use $estimates_dir/va_cfr_all_`version'/spec_test/spec_`va_outcome'_las_sp_ls_ct.ster
    eststo las_sp_ls_ct

      estadd local sample "`las_str'"
      estadd local control "`ls_str'"
      estadd local peer "N"

      // add scalars for FB test coef and se
      estadd scalar b_fb_acs = `b_las_sp_ls_ct_a_lv'
      estadd scalar se_fb_acs = `se_las_sp_ls_ct_a_lv'


    // with peer controls
    est use $estimates_dir/va_cfr_all_`version'/spec_test/spec_p_`va_outcome'_las_sp_ls_ct.ster
    eststo las_sp_ls_ct_p

      estadd local sample "`las_str'"
      estadd local control "`ls_str'"
      estadd local peer "Y"

      // add scalars for FB test coef and se
      estadd scalar b_fb_acs = `b_las_sp_ls_ct_a_lv_p'
      estadd scalar se_fb_acs = `se_las_sp_ls_ct_a_lv_p'

    //----------------------------------------------------------------
    // ktichen sink sample, kitchen sink control
    //----------------------------------------------------------------

    // no peer controls
    est use $estimates_dir/va_cfr_all_`version'/spec_test/spec_`va_outcome'_las_sp_las_ct.ster
    eststo las_sp_las_ct

      estadd local sample "`las_str'"
      estadd local control "`las_str'"
      estadd local peer "N"

    // with peer controls
    est use $estimates_dir/va_cfr_all_`version'/spec_test/spec_p_`va_outcome'_las_sp_las_ct.ster
    eststo las_sp_las_ct_p

      estadd local sample "`las_str'"
      estadd local control "`las_str'"
      estadd local peer "Y"


    #delimit ;
    esttab using "$tables_dir/va_cfr_all_`version'/combined/fb_spec_`va_outcome'.csv",
    replace nonumbers se(%4.3f) b(%5.3f) nostar nocons
    scalars(b_fb_score se_fb_score b_fb_sibling se_fb_sibling
    b_fb_acs se_fb_acs b_fb_score_acs_sibling se_fb_score_acs_sibling
    sample control peer)
    refcat(va_cfr_g11_`va_outcome' "Specification Test:" b_fb_score "Forecast Bias Test:")
    title("`va_outcome' specification and forecast bias tests results")
    ;
    #delimit cr
  }




}






local date2 = c(current_date)
local time2 = c(current_time)

di "Do file va_spec_fb_tab.do start date time: `date1' `time1'"
di "End date time: `date2' `time2'"

cap log close
cap translate "$logdir/va_spec_fb_tab.smcl" ///
  "$logdir/va_spec_fb_tab.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
