/*------------------------------------------------------------------------------
do/va/heterogeneity/va_corr_schl_char.do — Phase 1a §3.3 step 4 relocation
================================================================================

PURPOSE
    Estimate VA-by-school-characteristics regressions per (sample × control × peer × het_char) cell.  Heterogeneity dimensions: charter status, urban/rural locale, % econ-disadvantaged, % Black/Hispanic.  Inputs: merged VA + sch_char_2018 (CDE 2018 school-chars snapshot, LEGACY $vaprojdir/data/sch_char_2018.dta — Step 9 deferred CDE data).

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after batch 3c1 utilities
    (which produce the merged va_<outcome>_all.dta dataset this batch consumes).

INPUTS (verified via grep)
    CANONICAL:
      $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_all.dta — from merge_va_est.do (batch 3c1)
      $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_all_schl_char.dta — from this batch's va_het.do (output -> input chain)
    LEGACY (Step 9 deferred CDE data):
      $vaprojdir/data/sch_char.dta — school characteristics 1999-current panel
      $vaprojdir/data/sch_char_2018.dta — 2018 snapshot for cross-section regressions

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on the file body)
    $estimates_dir/va_cfr_all_v[12]/va_het/va_<outcome>_het_<het_char>_<sample>_sp_<va_ctrl>_ct[_p].ster
    $logdir/va/heterogeneity/va_corr_schl_char.smcl + .log

RELOCATION (per plan v3 §3.3 step 4, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/va_het/va_corr_schl_char.do
    Path repointing applied via script-based sed pass:
      $vaprojdir/log_files/va_het/<x> -> $logdir/<x>
      $vaprojdir/estimates/<x> -> $estimates_dir/<x>
      $vaprojdir/tables/<x> -> $tables_dir/<x>
      $vaprojdir/figures/<x> -> $figures_dir/<x>
      $vaprojdir/do_files/sbac/macros_va*.doh -> $consolidated_dir/do/va/helpers/<x> (absolute per batch 2c)
      $vaprojdir/data/sch_char[_2018].dta KEPT LEGACY (Step 9 CDE data deferred)

ADRs: 0004 (canonical pipeline), 0009 (v1 canonical), 0021 (sandbox; description convention)
ORIGINAL CHANGE LOG preserved verbatim below.
------------------------------------------------------------------------------*/


/* correlation of VA with school characteristics:
- charter status: charter
- pct econ disadvantage: prop_ecn_disadv
- pct black/hispanic: enr_black_hisp_prop
- urban/rural status: locale_coarse
 */

/* To run this do file, execute:
do $vaprojdir/do_files/va_het/va_corr_schl_char.do
 */


/* change log:
1/16/2024: remove standardization of VA estimates, 
cluster SE by school  
1/17/2024: only use 2019 school chars */

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$estimates_dir"
cap mkdir "$estimates_dir/va_cfr_all_v1"
cap mkdir "$estimates_dir/va_cfr_all_v1/va_het"
cap mkdir "$estimates_dir/va_cfr_all_v2"
cap mkdir "$estimates_dir/va_cfr_all_v2/va_het"
cap mkdir "$logdir"


cap mkdir "$logdir/va"
cap mkdir "$logdir/va/heterogeneity"
cd $vaprojdir

log close _all

log using "$logdir/va/heterogeneity/va_corr_schl_char.smcl", replace text

di as text _n "{hline 80}"
di as text "va_corr_schl_char.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"
 

graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984


local date1 = c(current_date)
local time1 = c(current_time)

// include project macros
include $consolidated_dir/do/va/helpers/macros_va.doh
include $consolidated_dir/do/va/helpers/macros_va_all_samples_controls.doh

local factor_het_char charter locale_coarse
local cont_het_char prop_ecn_disadv enr_black_hisp_prop

foreach version in v1 v2 {
    /* first merge VA estimates and school characteristics */
    di "VA version: `version'"

    use $estimates_dir/va_cfr_all_`version'/va_est_dta/va_all.dta, clear 
    merge m:1 cdscode using $vaprojdir/data/sch_char_2018.dta, nogen keep(1 3)

    /* // standardize VA estimates into z score
      foreach va of varlist va_* {
        sum `va'
        replace `va' = `va' - r(mean)
        replace `va' = `va' / r(sd)
      } */

    /* local char_vars charter prop_ecn_disadv enr_black_hisp_prop locale_coarse */

    local b_sample_controls b 
    local las_sample_controls las 
    

    foreach va_outcome in ela math enr enr_2year enr_4year {
        di "dependent var: `va_outcome'"


        foreach sample in b las {
            di "VA sample: `sample'"

            if "`sample'" == "las" {
                local peer _p
                local peer_yn "Y"
            } 
            else {
                local peer
                local peer_yn "N"
            }

            foreach va_ctrl of local `sample'_sample_controls {
            di "VA controls: `va_ctrl'"

            /* school level regs, no controls */
                foreach het_char of local factor_het_char {
                    di "categorical variable: `het_char'"
                    reg va_`va_outcome'_`sample'_sp_`va_ctrl'_ct i.`het_char' ///
                        , cluster(school_id)

                    estadd ysumm, mean 
                    estimates save $estimates_dir/va_cfr_all_`version'/va_het/va_`va_outcome'_het_`het_char'_`sample'_sp_`va_ctrl'_ct`peer'.ster, replace

                }

                foreach het_char of local cont_het_char {
                    di "continuous variables: `cont_het_char'"
                    reg va_`va_outcome'_`sample'_sp_`va_ctrl'_ct `het_char' ///
                        , cluster(school_id)

                    estadd ysumm, mean
                    estimates save $estimates_dir/va_cfr_all_`version'/va_het/va_`va_outcome'_het_`het_char'_`sample'_sp_`va_ctrl'_ct`peer'.ster, replace

                }


            }
        }

    }

}








local date2 = c(current_date)
local time2 = c(current_time)

di "do file start time: `date1' `time1' "
di "do file end time: `date2' `time2' "

cap log close
cap translate "$logdir/va/heterogeneity/va_corr_schl_char.smcl" ///
    "$logdir/va/heterogeneity/va_corr_schl_char.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
