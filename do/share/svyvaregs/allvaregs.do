/*------------------------------------------------------------------------------
do/share/svyvaregs/allvaregs.do — Phase 1a §3.3 step 10 batch 10c relocation
================================================================================

PURPOSE
    run all VA-on-survey regressions (svyvaregs umbrella).

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'
    (or as a helper `include'd by sister scripts).

INPUTS (verified via grep on file body)
    $datadir_clean/calschls/analysisready/`svyname'analysisready  (CHAIN read; from Step 9f poolingdata producers — sec/parent via secpooling+parentpooling, staff via mergegr11enr)
    $output_dir/dta/varegs/`svyname'/va_`va_outcome'_`sample'_sp_`control'_ct`peer'_nw ///  (LEGACY)
    $output_dir/dta/varegs/`svyname'/va_`va_outcome'_`sample'_sp_`control'_ct`peer'_wt ///  (LEGACY)
    $output_dir/xls/varegs/unweighted/`svyname'/`svyname'_va_all_nw  (LEGACY)
    $output_dir/xls/varegs/weighted/`svyname'/`svyname'_va_all_wt  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $logdir/allvaregs.smcl (via log using)
    $logdir/allvaregs.smcl + $logdir/allvaregs.log (translate)
    $output_dir/dta/varegs/`svyname'/`svyname'_va_all_nw
    $output_dir/dta/varegs/`svyname'/va_`va_outcome'_`sample'_sp_`control'_ct`peer'_nw ///
    $output_dir/dta/varegs/`svyname'/va_`va_outcome'_`sample'_sp_`control'_ct`peer'_wt ///

RELOCATION (per plan v3 §3.3 step 10 batch 10c, applied 2026-05-08)
    Source: caschls/do/share/svyvaregs/allvaregs.do
    Path repointing applied (script-based methodology):
      $projdir/log/share/<sub>/* -> $logdir/* (CANONICAL; flattened from nested predecessor)
      $projdir/out/txt/outcomesumstats/* -> $output_dir/txt/outcomesumstats/* (txt-format log destination for nsc_codebook)
      $projdir/dta/sibling* -> $datadir_clean/sibling* (CANONICAL chain — sibling crosswalks)
      $projdir/dta/schoolchar/* -> $datadir_clean/schoolchar/* (CANONICAL — mattschlchar outputs consumed by Table 8 producers)
      $caschls_projdir/dta/buildanalysisdata/analysisready/* -> $datadir_clean/calschls/analysisready/* (CHAIN read from Step 9f poolingdata producers; was LEGACY pre-flight-D fix 2026-05-16)
      $projdir/dta/<other>/* -> $caschls_projdir/dta/<other>/* (LEGACY-static raw reads)
      $projdir/out/* -> $output_dir/* (intermediate CANONICAL)
      translate (single-line ABS form) -> $logdir/* (CANONICAL)
      /home/research/ca_ed_lab/msnaven/* (mattschlchar dormant rebuild) -> kept verbatim per ADR-0013 + ADR-0021
    Predecessor's `log using' upgraded to consolidated convention.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 10 batch 10c
    Sister files (this batch): nsc_codebook.do, k12_nsc2019_merge.doh, siblingmatch.do, siblingpairxwalk.do, uniquefamily.do, mattschlchar.do


ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* running value added regressions for secondary, parent, and staff surveys questions of interest */
/* This file supercededs parentvareg.do and secvareg.do since this files does the VA regs for secondary, staff, and parent using a loop*/
********************************************************************************
********************************************************************************
*************** written by Christina Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************


/* To run this do file, type:
do $projdir/do/share/svyvaregs/allvaregs
 */

/* CHANGE LOG:
11/21/2022: Rewrote code for using new VA estimates
 */

/* set trace on
set tracedepth 1 */

cap log close _all
graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984
* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$output_dir"
cap mkdir "$output_dir/dta"
cap mkdir "$output_dir/dta/varegs"
cap mkdir "$output_dir/xls"
cap mkdir "$output_dir/xls/varegs"
cap mkdir "$output_dir/xls/varegs/unweighted"
cap mkdir "$output_dir/xls/varegs/weighted"
foreach svyname in parent sec staff elem {
    cap mkdir "$output_dir/dta/varegs/`svyname'"
    cap mkdir "$output_dir/xls/varegs/unweighted/`svyname'"
    cap mkdir "$output_dir/xls/varegs/weighted/`svyname'"
}


log using "$logdir/allvaregs.smcl", replace text


/* create a local macro for secondary qoi numbers  */
local secqoinums 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40

/* create a local macro for parent qoi numbers  */
local parentqoinums 9 15 16 17 27 30 31 32 33 34 64

/* create a local macro for staff qoi numbers  */
local staffqoinums 10 20 24 41 44 64 87 98 103 104 105 109 111 112 128




foreach svyname in sec parent staff {

  //-------------------------------------------------------------
  // create z scores for survey qoi and VA estimates
  //-------------------------------------------------------------

  use $datadir_clean/calschls/analysisready/`svyname'analysisready, clear

  /* standardize qoi mean vars into z scores */
  foreach i of local `svyname'qoinums {
    sum qoi`i'mean_pooled
    gen qoi`i'mean_z = (qoi`i'mean_pooled - r(mean))/r(sd)
  }

  /* standardize va vars into z scores */
  foreach var of varlist va* {
    sum `var'
    replace `var' = (`var' - r(mean))/r(sd)
  }


  //-------------------------------------------------------------
  // bivariate regression of VA z scores on qoi z scores
   /* 1. base sample base contro, no peer effects
   2. leave out score - sibling - acs sample, kitchen sink controls, peer effects */
  //-------------------------------------------------------------

  // macros for different VA estimates to be used in each sample
  local b_sample_controls b
  local las_sample_controls las


  foreach va_outcome in ela math enr enr_2year enr_4year dk_enr dk_enr_2year dk_enr_4year {

    foreach sample in b las {
      foreach control of local `sample'_sample_controls {
        //macro for whether to use the VA estimates with peer effects
        if "`sample'" == "b" {
          local peer
          local peer_yn "N"
        }
        if "`sample'" == "las" {
          local peer "_p"
          local peer_yn "Y"

        }

          local append replace

          foreach i of local `svyname'qoinums {

            //---------------------------------------------------
            /* running unweighted regressions */
            //---------------------------------------------------

            qui reg va_`va_outcome'_`sample'_sp_`control'_ct`peer' qoi`i'mean_z
            regsave using $output_dir/dta/varegs/`svyname'/va_`va_outcome'_`sample'_sp_`control'_ct`peer'_nw ///
              , `append' ///
              table(va_`va_outcome'_`sample'_sp_`control'_ct`peer', format(%7.2f) parentheses(stderr) asterisk()) ///
              addlabel(va, `va_outcome', sample, `sample', control, `control', peer, `peer_yn', weighted, N)


            //---------------------------------------------------
            /* running weighted regressions */
            //---------------------------------------------------
            qui reg va_`va_outcome'_`sample'_sp_`control'_ct`peer' qoi`i'mean_z  [aweight = gr11enr_mean]
            regsave using $output_dir/dta/varegs/`svyname'/va_`va_outcome'_`sample'_sp_`control'_ct`peer'_wt ///
              , `append' ///
              table(va_`va_outcome'_`sample'_sp_`control'_ct`peer', format(%7.2f) parentheses(stderr) asterisk()) ///
              addlabel(va, `va_outcome', sample, `sample', control, `control', peer, `peer_yn', weighted, Y)

            local append append
          }
        }

      }

  }

  //---------------------------------------------------------
  /* merge regsave output dta datasets to produce big table */
  //---------------------------------------------------------


  //-------------------------------------------
  // merge unweighted regressions
  //-------------------------------------------
  local merge_command use
  local merge_options clear

  foreach va_outcome in ela math enr enr_2year enr_4year dk_enr dk_enr_2year dk_enr_4year {
    di "va: `va_outcome'"
    foreach sample in b las {
      di "sample: `sample'"
      foreach control of local `sample'_sample_controls {
        //macro for whether to use the VA estimates with peer effects
        if "`sample'" == "b" {
          local peer
          local peer_yn "N"
        }
        if "`sample'" == "las" {
          local peer "_p"
          local peer_yn "Y"
        }

        di "peer controls in VA estimates (empty if no peer, _p if peer): `peer'"


        `merge_command' $output_dir/dta/varegs/`svyname'/va_`va_outcome'_`sample'_sp_`control'_ct`peer'_nw, `merge_options'

        local merge_command "merge 1:1 var using"
        local merge_options nogen
      }
    }
  }

  save $output_dir/dta/varegs/`svyname'/`svyname'_va_all_nw, replace
  export excel using $output_dir/xls/varegs/unweighted/`svyname'/`svyname'_va_all_nw, replace firstrow(variables)


  //-------------------------------------------
  // merge weighted regressions
  //-------------------------------------------
  local merge_command use
  local merge_options clear


  foreach va_outcome in ela math enr enr_2year enr_4year dk_enr dk_enr_2year dk_enr_4year {
    di "va: `va_outcome'"
    foreach sample in b las {
      di "sample: `sample'"
      foreach control of local `sample'_sample_controls {
        //macro for whether to use the VA estimates with peer effects
        if "`sample'" == "b" {
          local peer
          local peer_yn "N"
        }
        if "`sample'" == "las" {
          local peer "_p"
          local peer_yn "Y"
        }

        di "peer controls in VA estimates (empty if no peer, _p if peer): `peer'"


        `merge_command' $output_dir/dta/varegs/`svyname'/va_`va_outcome'_`sample'_sp_`control'_ct`peer'_wt, `merge_options'

        local merge_command "merge 1:1 var using"
        local merge_options nogen
      }
    }
  }

  save $output_dir/dta/varegs/`svyname'/`svyname'_va_all_nw, replace
  export excel using $output_dir/xls/varegs/weighted/`svyname'/`svyname'_va_all_wt, replace firstrow(variables)




}


set trace off


log close
translate $logdir/allvaregs.smcl $logdir/allvaregs.log, replace
