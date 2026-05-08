********************************************************************************
/* create the VA sample dataset to save processing time. Using doh helpher files
each time to recreate the data takes too much time
 */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on Sep 22, 2021 ***************************

/* to run this do file:
do $projdir/do/share/siblingvaregs/createvasample.do
 */


 clear all
 set more off
 set varabbrev off
 set scheme s1color
 //capture log close: Stata should not complain if there is no log open to close
 cap log close _all

/* file path macros  */
include $projdir/do/share/siblingvaregs/vafilemacros.doh


//run the do helper file to set the local macros
include $vaprojdir/do_files/sbac/macros_va.doh

//change directory to common_core_va project directory
cd $vaprojdir
//starting log file
log using $projdir/log/share/siblingvaregs/createvasample.smcl, replace



//set a timer for this do file to see how long it runs
timer on 1







    ** this creates the full VA sample
   //run the do helper file to create the VA sample
   include $vaprojdir/do_files/sbac/create_va_sample.doh

   //Save it as a temporary dataset
   compress
   tempfile va_dataset
   save `va_dataset'



   save $projdir/dta/common_core_va/va_dataset, replace





  ********************************************************************************
  **create the VA dataset for the VA CFR regressions (score VA)
  ** use onoy 11th Grade (8th Grade ELA Controls, 6th Grade Math Controls)
  include $vaprojdir/do_files/sbac/create_va_g11_sample.doh

  **the above steps create the VA dataset for the VA CFR regressions (score VA)
  compress

  label data "Test Score Grade 11 VA Sample"
  save $projdir/dta/common_core_va/va_g11_dataset, replace

  //erase the tempfile to avoid name conflict
  erase `va_dataset'




  ********************************************************************************
  ** create the VA dataset for the long term outcome VA regressions
  use $projdir/dta/common_core_va/va_dataset, clear
  // merge on postsecondary Outcomes
  do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only
  drop enr enr_2year enr_4year
  rename enr_ontime enr
  rename enr_ontime_2year enr_2year
  rename enr_ontime_4year enr_4year



  * Save temporary dataset
  compress
  tempfile va_dataset
  save `va_dataset'



  ** need to create grade 11 sample for long term outcome VA, use create_va_g11_sample.doh

  // use only 11th Grade (8th Grade ELA Controls, 6th Grade Math Controls)
  include $vaprojdir/do_files/sbac/create_va_g11_out_sample.doh

  ** this creates the VA dataset for the long term outcome VA regressions
  compress
  label data "Enrollment Outcome Grade 11 VA Sample"
  save $projdir/dta/common_core_va/va_g11_out_dataset, replace













timer off 1
timer list
log close

//change directory back
cd $projdir

//translate the log file to a text log file
translate $projdir/log/share/siblingvaregs/createvasample.smcl $projdir/log/share/siblingvaregs/createvasample.log, replace
