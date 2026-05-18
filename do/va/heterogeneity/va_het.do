/*------------------------------------------------------------------------------
do/va/heterogeneity/va_het.do — Phase 1a §3.3 step 4 relocation
================================================================================

PURPOSE
    VA heterogeneity by school-district (across-district variance share via areg+absorb) and by school characteristics (% Black/Hispanic, % econ-disadvantaged, urban/rural locale, log enrollment).  Per ADR-0004 + paper Table 8 round-1 revision.  Reads merged VA estimates + sch_char.dta; produces fragment + publishable LaTeX tables.

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
    $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_all_schl_char.dta (merged VA + school-char dataset)
      $estimates_dir/va_cfr_all_v[12]/va_het/{district_<type>_<spec>_<wt>, corr_<char>_va_<spec>_<wt>}.dta
      $tables_dir/share/va/{check,pub}/va_het/{var_across_district_<wt>_v[12], corr_char_<wt>_v[12]}.tex (paper-shipping LaTeX fragments)
    $logdir/va/heterogeneity/va_het.smcl + .log

RELOCATION (per plan v3 §3.3 step 4, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/va_het/va_het.do
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


/* create estimates for correlation between VA and school characteristics */

/* To run this do file, execute:
do $vaprojdir/do_files/va_het/va_het.do
 */

/* created June 28, 2024 */

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$estimates_dir"
cap mkdir "$estimates_dir/va_cfr_all_v1"
cap mkdir "$estimates_dir/va_cfr_all_v1/va_est_dta"
cap mkdir "$estimates_dir/va_cfr_all_v1/va_het"
cap mkdir "$estimates_dir/va_cfr_all_v2"
cap mkdir "$estimates_dir/va_cfr_all_v2/va_est_dta"
cap mkdir "$estimates_dir/va_cfr_all_v2/va_het"
cap mkdir "$tables_dir"
cap mkdir "$tables_dir/share"
cap mkdir "$tables_dir/share/va"
cap mkdir "$tables_dir/share/va/check"
cap mkdir "$tables_dir/share/va/check/va_het"
cap mkdir "$tables_dir/share/va/pub"
cap mkdir "$tables_dir/share/va/pub/va_het"
cap mkdir "$logdir"


cap mkdir "$logdir/va"
cap mkdir "$logdir/va/heterogeneity"
cd $vaprojdir

log close _all

log using "$logdir/va/heterogeneity/va_het.smcl", replace text

di as text _n "{hline 80}"
di as text "va_het.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"
 

graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984



// include project macros
include $consolidated_dir/do/va/helpers/macros_va.doh

foreach version in v1 v2 {
    di "VA version: `version'"

    // merge VA estimates with school characteristics
    use $estimates_dir/va_cfr_all_`version'/va_est_dta/va_all.dta, clear 
    merge 1:1 cdscode year using $vaprojdir/data/sch_char.dta, nogen keep( 3)

    // create category dummies for locale
    gen suburb = (locale_coarse==2)
    gen town = (locale_coarse==3)
    gen rural = (locale_coarse==4)

    // create log enrollment
    gen logenroll = ln(enr_total)

    // impute missing values
    summ enr_black_hisp_prop prop_ecn_disadv locale_coarse logenroll fte_pupil_pc fte_teach_pc new_teacher_prop
    foreach var of varlist charter fte_pupil_pc fte_teach_pc new_teacher_prop {
        egen temp=mean(`var'), by(cdscode)
        replace `var'=temp if `var'==.
        drop temp
    }
    summ enr_black_hisp_prop prop_ecn_disadv locale_coarse logenroll fte_pupil_pc fte_teach_pc new_teacher_prop


    // create disctrict code
    gen district = substr(cdscode, 3, 5)

    // find the sample of schools that have all va estimates in 2018
    gen have_test_lr = (va_ela_las_sp_las_ct_p !=. & va_math_las_sp_las_ct_p !=. & va_enr_2year_las_sp_las_ct_p !=. & va_enr_4year_las_sp_las_ct_p !=. & year==2018)
    // calculate number of schools in the sample in each district
    egen numsch=sum(have_test_lr), by(district)
    // tag unique districts in the sample
    egen tag=tag(district) if have_test_lr==1
    gsort -tag -numsch enr_total cdscode

    // indicator for having 2 or more schools in the district
    gen gr2 = (numsch >= 2)
    // indicator for having 5 or more schools in the district
    gen gr5 = (numsch >= 5)
    // indictor for schools in the top 25 largest school districts
    summ numsch if _n==25 
    gen top25=(numsch>=(r(mean)-.000000001))

    list tag numsch district enr_total gr2 gr5 top25 if tag==1 & _n<=30

    save $estimates_dir/va_cfr_all_`version'/va_est_dta/va_all_schl_char.dta, replace 

    foreach w in 0 1 {
        if `w' == 0 {
            local wt ""
            local w_str "nw"
        }
        if `w' == 1 {
            local wt "[w = enr_total]"
            local w_str "wt"
        }

        foreach spec in las_sp_b_ct las_sp_las_ct_p {
            foreach district_type in gr2 top25 {
                use $estimates_dir/va_cfr_all_`version'/va_est_dta/va_all_schl_char.dta, clear 

                local replace replace 

                foreach outcome in ela math enr_2year enr_4year {
                    areg va_`outcome'_`spec' `wt' if `district_type' == 1 & year == 2018, absorb(district)
                    regsave using $estimates_dir/va_cfr_all_`version'/va_het/district_`district_type'_`spec'_`w_str'.dta ///
                        , table("`outcome'", asterisk(5 1) parentheses(stderr) format(%5.3f)) addvar(type, `district_type') `replace'
                    local replace append 
                }

                use $estimates_dir/va_cfr_all_`version'/va_het/district_`district_type'_`spec'_`w_str', clear 
                
                keep if var == "r2"
                if "`district_type'" == "gr2" replace var  = "At least 2 schools in district"
                if "`district_type'" == "gr5" replace var = "At least 5 schools in district (about top 50)"
                if "`district_type'" == "top25" replace var = "25 largest districts (7+ schools)"

                save, replace 

            }
        }

        // make combined table 
        use $estimates_dir/va_cfr_all_`version'/va_het/district_gr2_las_sp_b_ct_`w_str', clear 
        append using $estimates_dir/va_cfr_all_`version'/va_het/district_top25_las_sp_b_ct_`w_str'
        append using $estimates_dir/va_cfr_all_`version'/va_het/district_gr2_las_sp_las_ct_p_`w_str'
        append using $estimates_dir/va_cfr_all_`version'/va_het/district_top25_las_sp_las_ct_p_`w_str'


        
        // add panel title
        if `w' == 0 {
            local panel_a_title "Panel A: Restricted sample with base controls"
            local panel_b_title "Panel B: Restricted sample with full controls"
        }
        if `w' == 1 {
            local panel_a_title "Panel A: Restricted sample with base controls"
            local panel_b_title "Panel B: Restricted sample with full controls"
        }

        insobs 1, before(1)
        replace var = "`panel_a_title'" if _n==1
        insobs 1, after(3)
        replace var = "`panel_b_title'" if _n==4

        local texsave_options autonumber nonames replace hlines(1 3 4) ///
            title("Fraction of VA variance that is across-district") ///
            headerlines("{} & ELA & Math & 2 Year Enr & 4 Year Enr")

        texsave using $tables_dir/share/va/check/va_het/var_across_district_`w_str'_`version'.tex,  `texsave_options'
        texsave using $tables_dir/share/va/pub/va_het/var_across_district_`w_str'_`version'.tex, frag `texsave_options'



        //----------------------------------------------------------------
        // corelation between VA and school characteristics
        //----------------------------------------------------------------
        foreach spec in las_sp_b_ct las_sp_las_ct_p {
            local order 1
            tempfile het_`spec'

            foreach char in enr_black_hisp_prop prop_ecn_disadv locale_coarse logenroll {
                if "`char'" != "locale_coarse" local rhs "`char'"
                if "`char'" == "locale_coarse" local rhs "suburb town rural"

                local replace replace 

                use $estimates_dir/va_cfr_all_`version'/va_est_dta/va_all_schl_char.dta, clear

                foreach outcome in ela math enr_2year enr_4year {
                    reg va_`outcome'_`spec' `rhs' `wt', cluster(cdscode)
                    regsave `rhs' ///
                        using $estimates_dir/va_cfr_all_`version'/va_het/corr_`char'_va_`spec'_`w_str'.dta ///
                        , table(`outcome', asterisk(5 1) parentheses(stderr)  format(%5.3f)) `replace'
                    local replace append

                }

                use  $estimates_dir/va_cfr_all_`version'/va_het/corr_`char'_va_`spec'_`w_str'.dta, clear
                // keep only the coef and stderr of interest
                if "`char'"!="locale_coarse"  keep if _n<=2
			    if "`char'"=="locale_coarse"  keep if _n<=6
                // rename first column of table
                replace var=subinstr(var,"_coef","",.)
                replace var="" if strpos(var,"_stderr")!=0	
                replace var = "Percent Black or Hispanic" if var == "enr_black_hisp_prop"
                replace var = "Percent Economically Disadvantaged" if var == "prop_ecn_disadv"
                replace var = "Suburb" if var == "suburb"
                replace var = "Town" if var == "town"
                replace var = "Rural" if var == "rural"
                replace var = "Log Enrollment" if var == "logenroll"
                gen order = `order'
                gen coef = _n
                if "`spec'" == "las_sp_b_ct" {
                    gen spec = 1 
                }
                if "`spec'" == "las_sp_las_ct_p" {
                    gen spec = 2 
                }
                 

                tempfile het_`char'
                save `het_`char'', replace 
                list

                if `order' != 1 append using `het_`spec''
                save `het_`spec'', replace 

                local ++order 


        }
        }

        use `het_las_sp_b_ct', clear 
        append using `het_las_sp_las_ct_p'
        sort spec order coef 
        drop spec order coef 
        list 


        insobs 1, before(1)
        replace var = "`panel_a_title'" if _n==1
        insobs 1, after(13)
        replace var = "`panel_b_title'" if _n==14

        local texsave_options autonumber nonames replace hlines(1 3  5 11 13 13 14 16 18 24) ///
            title("Correlation between VA and school characteristics") ///
            headerlines("{} & ELA & Math & 2 Year Enr & 4 Year Enr") size(footnotesize)

        texsave using $tables_dir/share/va/check/va_het/corr_char_`w_str'_`version'.tex,  `texsave_options'
        texsave using $tables_dir/share/va/pub/va_het/corr_char_`w_str'_`version'.tex, frag `texsave_options'




    }
}








cap log close
cap translate "$logdir/va/heterogeneity/va_het.smcl" ///
    "$logdir/va/heterogeneity/va_het.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
