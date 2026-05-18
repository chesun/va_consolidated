/*------------------------------------------------------------------------------
do/va/heterogeneity/persist_het_student_char_fig.do — Phase 1a §3.3 step 4 relocation
================================================================================

PURPOSE
    Build combined-panel paper figures for outcome-VA heterogeneity persistence by student characteristics (race, sex, econ-disadvantage) for math VA × distance interactions.  Combines _fig.do .gph outputs from batch 3c2 reg_out_va_all_fig.do into multi-panel PDFs.

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after batch 3c1 utilities
    (which produce the merged va_<outcome>_all.dta dataset this batch consumes).

INPUTS (verified via grep on file body L97-101)
    CANONICAL .gph files from batch 3c2 reg_out_va_all_fig.do (intermediate Stata graph artifacts):
      $output_dir/gph_files/va_cfr_all_v[12]/het_reg_chars/het_reg_<outcome>_va_math_x_inc_median_hh_xtile_las_sp_lasd_ct_p_m.gph
      $output_dir/gph_files/va_cfr_all_v[12]/het_reg_chars/het_reg_<outcome>_va_math_x_race_las_sp_lasd_ct_p_m.gph
      $output_dir/gph_files/va_cfr_all_v[12]/het_reg_chars/het_reg_<outcome>_va_math_x_male_las_sp_lasd_ct_p_m.gph
      $output_dir/gph_files/va_cfr_all_v[12]/het_reg_chars/het_reg_<outcome>_va_math_x_econ_disadvantage_las_sp_lasd_ct_p_m.gph
    Helper:
      $consolidated_dir/do/va/helpers/macros_va.doh — `_str` locals for outcome titles

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep at body L106)
    $figures_dir/va_cfr_all_v[12]/het_reg_combined_panels/student_char/het_reg_distance_<outcome>_va_math_x_student_char_combined.pdf
                                          (per outcome: enr_2year + enr_4year)
    $logdir/va/heterogeneity/persist_het_student_char_fig.smcl + .log

    Note: file does NOT read sch_char.dta or va_all.dta — those LEGACY/CANONICAL reads
    listed in the boilerplate INPUTS for sister files in this batch don't apply here.
    This file only `graph combine`s pre-existing .gph artifacts; no data read.

RELOCATION (per plan v3 §3.3 step 4, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/va_het/persist_het_student_char_fig.do
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


/* Combine figures into panels for heterogeneity in VA persistence
 by student characteristics 
 Individual figures are created in reg_out_va_all_fig.do
 */

*****************************************************
* First created by Christina Sun March 5, 2024
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/va_het/persist_het_student_char_fig.do
 */


/* Change log:
08/15/2024: remove charter */


* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$figures_dir"
cap mkdir "$figures_dir/va_cfr_all_v1"
cap mkdir "$figures_dir/va_cfr_all_v1/het_reg_combined_panels"
cap mkdir "$figures_dir/va_cfr_all_v1/het_reg_combined_panels/student_char"
cap mkdir "$figures_dir/va_cfr_all_v2"
cap mkdir "$figures_dir/va_cfr_all_v2/het_reg_combined_panels"
cap mkdir "$figures_dir/va_cfr_all_v2/het_reg_combined_panels/student_char"
cap mkdir "$logdir"


cap mkdir "$logdir/va"
cap mkdir "$logdir/va/heterogeneity"
cd $vaprojdir

cap log close persist_het_student_char_fig

log using "$logdir/va/heterogeneity/persist_het_student_char_fig.smcl", replace text name(persist_het_student_char_fig)

di as text _n "{hline 80}"
di as text "persist_het_student_char_fig.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984


include $consolidated_dir/do/va/helpers/macros_va.doh
local race_xlabel `"1 "Black" 2 "Hispanic" 3 "Asian" 4 "White" 5 "Other""'
local charter_xlabel `"0 "Non-Charter" 1 "Charter""'
local male_xlabel `"0 "Female" 1 "Male""'
local econ_disadvantage_xlabel `"0 "Not Disadvantaged" 1 "Economically Disadvantaged""'

foreach version in v1 v2 {
    foreach outcome in enr_2year enr_4year {
        #delimit ;
        graph combine 
            $output_dir/gph_files/va_cfr_all_`version'/het_reg_chars/het_reg_`outcome'_va_math_x_inc_median_hh_xtile_las_sp_lasd_ct_p_m.gph
            $output_dir/gph_files/va_cfr_all_`version'/het_reg_chars/het_reg_`outcome'_va_math_x_race_las_sp_lasd_ct_p_m.gph
            /* $output_dir/gph_files/va_cfr_all_`version'/het_reg_chars/het_reg_`outcome'_va_math_x_charter_las_sp_lasd_ct_p_m.gph */
            $output_dir/gph_files/va_cfr_all_`version'/het_reg_chars/het_reg_`outcome'_va_math_x_male_las_sp_lasd_ct_p_m.gph
            $output_dir/gph_files/va_cfr_all_`version'/het_reg_chars/het_reg_`outcome'_va_math_x_econ_disadvantage_las_sp_lasd_ct_p_m.gph
            ,  ycommon cols(2)
            title("``outcome'_str' on Math VA interacted with Student Characteristics", size(small))
        ;
        #delimit cr
        graph export $figures_dir/va_cfr_all_`version'/het_reg_combined_panels/student_char/het_reg_distance_`outcome'_va_math_x_student_char_combined.pdf, replace



    }
}






cap log close persist_het_student_char_fig
translate  $logdir/va/heterogeneity/persist_het_student_char_fig.smcl ///
     "$logdir/va/heterogeneity/persist_het_student_char_fig.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
