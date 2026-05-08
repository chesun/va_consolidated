********************************************************************************
/* Macros for common core VA project stored estimates
NOTE: does not include estimates from the sibling acs restricted sample. Too much
bloating in the number of files, impossible to find unique local macro names
and it's getting out of control. */
********************************************************************************
********************************************************************************
/* First written by Che Sun, 1/6/2022  */

/* to include this in do files:
include $projdir/do/share/siblingvaregs/vaestmacros.doh
 */

********************************************************************************
***test score VA
foreach subject in ela math {
  //original VA CFR estimates
  local `subject'_va_dta "$vaprojdir/data/sbac/va_g11_`subject'.dta, replace"
  //original VA CFR spec test without peer control
  local `subject'_spec_va "$vaprojdir/estimates/sbac/spec_test_va_cfr_g11_`subject'.ster"
  //original VA CFR spec test with peer control
  local `subject'_spec_va_peer "$vaprojdir/estimates/sbac/spec_test_va_cfr_g11_`subject'_peer.ster"



  //original VA with leave out L4 scores sample
  local `subject'_va_dta_l4 "$vaprojdir/data/sbac/bias_va_g11_`subject'_L4ela.dta.dta"
  //spec test for VA on L4 leave out var sample
  **no peer controls
  local `subject'_spec_va_l4 "$vaprojdir/estimates/sbac/bias_spec_test_va_cfr_g11_`subject'_L4ela.ster"
  **with peer controls
  local `subject'_spec_va_l4_peer "$vaprojdir/estimates/sbac/bias_spec_test_va_cfr_g11_`subject'_L4ela_peer.ster"
  //forecast bias test for VA with L4 score leave out var
  **without peer controls
  local `subject'_fb_va_l4 "$vaprojdir/estimates/sbac/bias_test_va_cfr_g11_`subject'_L4ela.ster"



  //Original VA with census tract leave out var sample
  local `subject'_va_dta_census "$vaprojdir/data/sbac/bias_va_g11_`subject'_census.dta"
  //original VA spec test on census tract leave out var sample
  **no peer controls
  local `subject'_spec_va_census "$vaprojdir/estimates/sbac/bias_spec_test_va_cfr_g11_`subject'_census.ster"
  **with peer controls
  local `subject'_spec_va_census_peer "vaprojdir/estimates/sbac/bias_spec_test_va_cfr_g11_`subject'_census_peer.ster"
  //forecast bias test for VA with census tract leave out var
  **without peer controls
  local `subject'_fb_va_census "$vaprojdir/estimates/sbac/bias_test_va_cfr_g11_`subject'_census.ster"



  //VA on sibling sample without sibling control
  local `subject'_va_dta_sibling "$projdir/dta/common_core_va/test_score_va/va_g11_`subject'_sibling.dta"
  //spec test for original VA on sibling sample
  **no peer controls
  local `subject'_spec_va_sibling_og "$projdir/est/siblingvaregs/test_score_va/spec_test_va_cfr_g11_`subject'_sibling_nocontrol.ster"
  //spec test for sibling VA with sibling controls
  **no peer controls
  local `subject'_spec_va_sibling "$projdir/est/siblingvaregs/test_score_va/spec_test_va_cfr_g11_`subject'_sibling.ster"
  **peer control
  local `subject'_spec_va_sibling_peer "$projdir/est/siblingvaregs/test_score_va/spec_test_va_cfr_g11_`subject'_peer_sibling.ster"
  //forecast bias test for sibling control leave out var
  **without peer controls
  local `subject'_fb_va_sibling "$projdir/est/siblingvaregs/test_score_va/fb_test_va_cfr_g11_`subject'_sibling.ster"


  //sibling test score VA coefficients from vam command wihout sibling controls
  local `subject'_sibling_vam_nosibctrl "$vaprojdir/estimates/sibling_va/test_score_va/vam_cfr_g11_`subject'_nosibctrl.ster"
  //sibling test score VA coefficients from vam command with sibling controls
  local `subject'_sibling_vam "$vaprojdir/estimates/sibling_va/test_score_va/vam_cfr_g11_`subject'.ster"
}













********************************************************************************
**** enrollment outcome VA
foreach outcome in enr enr_2year enr_4year {
  //original VA CFR estimates
  local `outcome'_va_dta "$vaprojdir/data/sbac/va_g11_`outcome'.dta, replace"
  //original VA CFR spec test without peer control
  local `outcome'_spec_va "$vaprojdir/estimates/sbac/spec_test_va_cfr_g11_`outcome'.ster"
  //original VA CFR spec test with peer control
  local `outcome'_spec_va_peer "$vaprojdir/estimates/sbac/spec_test_va_cfr_g11_`outcome'_peer.ster"




  //original VA with leave out L4 scores sample
  local `outcome'_va_dta_l4 "$vaprojdir/data/sbac/bias_va_g11_`outcome'_L4ela.dta.dta"
  //spec test for VA on L4 leave out var sample
  **no peer controls
  local `outcome'_spec_va_l4 "$vaprojdir/estimates/sbac/bias_spec_test_va_cfr_g11_`outcome'_L4ela.ster"
  **with peer controls
  local `outcome'_spec_va_l4_peer "$vaprojdir/estimates/sbac/bias_spec_test_va_cfr_g11_`outcome'_L4ela_peer.ster"
  //forecast bias test for VA with L4 score leave out var
  **without peer controls
  local `outcome'_fb_va_l4 "$vaprojdir/estimates/sbac/bias_test_va_cfr_g11_`outcome'_L4ela.ster"




  //Original VA with census tract leave out var sample
  local `outcome'_va_dta_census "$vaprojdir/data/sbac/bias_va_g11_`outcome'_census.dta"
  //original VA spec test on census tract leave out var sample
  **no peer controls
  local `outcome'_spec_va_census "$vaprojdir/estimates/sbac/bias_spec_test_va_cfr_g11_`outcome'_census.ster"
  **with peer controls
  local `outcome'_spec_va_census_peer "vaprojdir/estimates/sbac/bias_spec_test_va_cfr_g11_`outcome'_census_peer.ster"
  //forecast bias test for VA with census tract leave out var
  **without peer controls
  local `outcome'_fb_va_census "$vaprojdir/estimates/sbac/bias_test_va_cfr_g11_`outcome'_census.ster"




  //VA on sibling sample without sibling control
  local `outcome'_va_dta_sibling "$projdir/dta/common_core_va/outcome_va/va_g11_`outcome'_sibling.dta"
  //spec test for original VA on sibling sample
  **no peer controls
  local `outcome'_spec_va_sibling_og "$projdir/est/siblingvaregs/outcome_va/spec_test_va_cfr_g11_`outcome'_sibling_nocontrol.ster"
  //spec test for sibling VA with sibling controls
  **no peer controls
  local `outcome'_spec_va_sibling "$projdir/est/siblingvaregs/outcome_va/spec_test_va_cfr_g11_`outcome'_sibling.ster"
  **peer control
  local `outcome'_spec_va_sibling_peer "$projdir/est/siblingvaregs/outcome_va/spec_test_va_cfr_g11_`outcome'_peer_sibling.ster"
  //forecast bias test for sibling control leave out var
  **without peer controls
  local `outcome'_fb_va_sibling "$projdir/est/siblingvaregs/outcome_va/fb_test_va_cfr_g11_`outcome'_sibling.ster"


  // VA dataset on sibling census sample
  local `outcome'_va_dta_sib_census "$vaprojdir/data/sibling_va/outcome_va/va_g11_`outcome'_sibling_census.dta"
  // spec test for sibling census sample original VA without sibling or census controls
  local `outcome'_spec_sib_census_og "$vaprojdir/estimates/sibling_va/outcome_va/spec_test_`outcome'_census_nosib_noacs.ster"
  // spec test for sibling census sample VA with sibling control, no census control. Need a short enough name
  /* local `outcome'_spec_ "$vaprojdir/estimates/sibling_va/outcome_va/spec_test_`outcome'_census_noacs.ster" */
  // forecast bias test for sibling census sample VA with sibling control and census control as leave out var
  /* local `outcome'_fb_sib_census "$vaprojdir/estimates/sibling_va/outcome_va/fb_test_`outcome'_census.ster" */

  //sibling postsecondary outcome va coefficients from vam command without sibling controls
  /* local `outcome'_sibling_vam_nosibctrl "$vaprojdir/estimates/sibling_va/outcome_va/vam_cfr_g11_`outcome'_nosibctrl.ster" */
  //sibling postsecondary outcome va coefficients from vam command with sibling controls
  local `outcome'_sibling_vam "$vaprojdir/estimates/sibling_va/outcome_va/vam_cfr_g11_`outcome'.ster"
  // sibling census sample outcome VA coefficients without sibling control or census control
  /* local `outcome'_sib_census_vam_og "$vaprojdir/estimates/sibling_va/outcome_va/vam_`outcome'_census_nosib_noacs.ster" */
  // sibling census sample outcome VA coefficients with sibling control, without census controls
  /* local `outcome'_sib_census_vam_sibctrl "$vaprojdir/estimates/sibling_va/outcome_va/vam_`outcome'_census_noacs.ster" */
  // sibling census sample outcome VA coefficients with sibling control and census controls
  /* local `outcome'_sib_census_vam_allctrl "$vaprojdir/estimates/sibling_va/outcome_va/vam_`outcome'_sib_census.ster" */
}
