/*------------------------------------------------------------------------------
do/va/helpers/macros_va.doh — VA project file paths, dates, controls, strings
================================================================================

PURPOSE
    Define the canonical VA-pipeline locals consumed across Phase 3+
    estimation, table-producer, figure-producer, and heterogeneity scripts:
    - Restricted-access K12 data paths.
    - Sibling crosswalk paths (cross-references caschls predecessor).
    - Cohort-year ranges (test_score / star / caaspp / outcome).
    - Outcome strings (ELA, Math, enrollment).
    - Control-variable groupings (school, demographic, score, peer, census,
      sibling, distance, scrhat — predicted-score variants).
    - Per-spec control combinations (b/l/a/s/la/ls/as/las and their `d'-augmented
      variants per ADR-0009 + 2023-04-30 distance addition).
    - String labels for sample × control display.
    - School-characteristics + demographic-characteristics + expenditure groups.

INCLUDED FROM
    Phase 3+ VA estimation/table/figure scripts under `do/va/' and `do/share/va/'.
    Typically the FIRST helper-include in any consuming script (sets up the
    parent-scope locals consumed by `drift_limit.doh' and
    `macros_va_all_samples_controls.doh').

    Uses Stata's `#delimit ;' syntax (semicolons end statements) per the
    predecessor convention.  The closing `#delimit cr' restores default
    line-end semantics for the calling script.

ROLE IN ADR-0021 SANDBOX
    Pure local definitions; no save / export / log; sandbox-trivially clean.
    Reads from LEGACY paths via global expansion at include-time:
      - $vaprojdir/data/restricted_access/clean/k12_test_scores
        (LEGACY restricted-access K12 raw data)
      - $vaprojdir/data/public_access/...
        (LEGACY public-access subdirs)
      - $caschls_projdir/dta/siblingxwalk/<...>
        (sibling crosswalk built by relocated do/sibling_xwalk/siblingoutxwalk.do
         per ADR-0005; predecessor referenced as `$projdir/...')

RELOCATION HISTORY (per ADR-0005 + ADR-0021, applied 2026-04-30)
    Source:      cde_va_project_fork/do_files/sbac/macros_va.doh
    Destination: do/va/helpers/macros_va.doh
    Path repointing per ADR-0021 sandbox amendment ("paths only; analysis
    logic preserved verbatim"):
      - L29-31: `$projdir/dta/siblingxwalk/<file>' -> `$caschls_projdir/dta/siblingxwalk/<file>'
        (3 references: siblingxwalk, ufamilyxwalk, sibling_out_xwalk)
        Reason: $projdir is NOT defined in do/settings.do; $caschls_projdir
        is the explicit-named global per the LEGACY PATHS comment block.
        Repointing here eliminates the include-time `$projdir' alias-need
        for any future calling script (per the [LEARN:stata] 2026-04-30
        pattern surfaced in the siblingoutxwalk.do round-1 review).
      - $vaprojdir references (L22-28) preserved unchanged — $vaprojdir
        IS defined in do/settings.do as the predecessor cde_va_project_fork
        dir; LEGACY-static restricted-access K12 paths are READS-only
        per ADR-0021.
    Predecessor caller-update protocol: predecessor callers untouched in
    this commit per plan v3 §3.3 step 5 parenthetical.
    Analysis logic preserved verbatim (the cross-product of controls, the
    string labels, the cohort-year ranges, the school-char groupings — all
    byte-equivalent to the predecessor).

ORIGINAL CHANGE LOG (preserved from predecessor)
    2022-04-28: Added macro for sibling controls.
    2022-09-20: Added delimiter `;' after comments.
    2022-10-31: Changed naming convention for samples (b/l/a/s/la/ls/as/las).
    2023-05-31: Added distance control macros.
    2024-08-22: Added predicted ELA score spec controls (`scrhat' variants).

REFERENCES
    Plan v3 §3.3 step 1 (helpers/macros)
    ADRs:    0009 (v1 prior-score canonical), 0017 (Matt's files untouched —
             $vaprojdir paths are LEGACY-static reads), 0021 (description
             convention; sandbox-write rule; path-globals-only amendment)
    Audit:   chunk-2 (file structure verification); chunk-3 (control
             specifications cross-checked against paper Tables 2-3)
    MEMORY:  [LEARN:stata] 2026-04-30 ($projdir explicit-rename pattern)
------------------------------------------------------------------------------*/


/* CHANGE LOG
4/28/2022: Added macro for sibling controls
09/20/2022: Added delimiter : after comments
10/31/2022: Changed naming convention for samples
b - base
l - loscore
a - acs
s - sibling
la - loscore and acs
ls - loscore and sibling
as - acs and sibling
las - loscore, acs and sibling

05/31/2023: added distance control macros

08/22/2024: added predicted ELA score spec controls
*/

#delimit ;

*** file paths ;
local home $vaprojdir ;
local vaprojdofiles "$vaprojdir/do_files"
local ca_ed_lab "/home/research/ca_ed_lab" ;
local k12_test_scores "$vaprojdir/data/restricted_access/clean/k12_test_scores" ;
local public_access "$vaprojdir/data/public_access" ;
local k12_public_schools "$vaprojdir/data/public_access/clean/k12_public_schools" ;
local k12_test_scores_public "$vaprojdir/data/public_access/clean/k12_test_scores" ;
local siblingxwalk "$caschls_projdir/dta/siblingxwalk/siblingpairxwalk";
local ufamilyxwalk "$caschls_projdir/dta/siblingxwalk/ufamilyxwalk";
local sibling_out_xwalk "$caschls_projdir/dta/siblingxwalk/sibling_out_xwalk";


**** Dates ;
local test_score_min_year
	2015
	;

local test_score_max_year
	2018
	;

local star_min_year
	2003
	;

local star_max_year
	2013
	;

local caaspp_min_year
	2015
	;

local caaspp_max_year
	2019
	;

local outcome_min_year
	2015
	;

local outcome_max_year
	2018
	;




**** Outcome Strings ;
local ela_str
	"ELA"
	;
local math_str
	"Math"
	;

local enr_str
	"Overall Enrollment"
	;
local enr_2year_str
	"2-Year Enrollment"
	;
local enr_4year_str
	"4-Year Enrollment"
	;


**** Sibling Census Restricted Sample Controls Strings ;
local og_str
	"Original Specification"
	;

local acs_str
	"Original + Census"
	;

local sib_str
	"Original + Sibling"
	;

local both_str
	"Original + Census + Sibling"
	;



**** Value Added ;
local school_controls
	/*cohort_size*/
	;

local demographic_controls
	age
	i.male
	i.eth_asian i.eth_hispanic i.eth_black i.eth_other
	i.econ_disadvantage
	i.limited_eng_prof
	i.disabled
	;

local ela_score_controls
	i.year#(c.prior_ela_z_score##c.prior_ela_z_score##c.prior_ela_z_score)
	;

// controls using predicted lag 1 ELA scores
local ela_scrhat_controls
	i.year#(c.prior_ela_z_score_hat##c.prior_ela_z_score_hat##c.prior_ela_z_score_hat)
	;

local math_score_controls
	i.year#(c.prior_math_z_score##c.prior_math_z_score##c.prior_math_z_score)
	;



local peer_ela_score_controls
	i.year#(c.peer_prior_ela_z_score##c.peer_prior_ela_z_score##c.peer_prior_ela_z_score)
	;

local peer_math_score_controls
	i.year#(c.peer_prior_math_z_score##c.peer_prior_math_z_score##c.peer_prior_math_z_score)
	;

local peer_demographic_controls
	peer_age
	peer_male
	peer_eth_asian peer_eth_hispanic peer_eth_black peer_eth_other
	peer_econ_disadvantage
	peer_limited_eng_prof
	peer_disabled
	;



local va_control_vars "`school_controls' `demographic_controls'" ;
local va_control_vars : subinstr local va_control_vars "i." "", all ;
local va_control_vars : list uniq va_control_vars ;

local census_grade
	6
	;

local census_controls
	/*eth_white_pct*/ eth_asian_pct eth_hispanic_pct eth_black_pct /*eth_other_pct*/
	educ_hs_dropout_prop /*educ_deg_2year_prop*/ educ_deg_4year_plus_prop
	pov_fam_child_lt18_pct
	inc_median_hh
	;

local peer_census_controls
	peer_eth_asian_pct  peer_eth_hispanic_pct  peer_eth_black_pct
	peer_educ_hs_dropout_prop  peer_educ_deg_4year_plus_prop
	peer_pov_fam_child_lt18_pct	 peer_inc_median_hh
	;

local sibling_controls
	i.has_older_sibling_enr_2year
	i.has_older_sibling_enr_4year
	;

local peer_sibling_controls
	peer_has_older_sibling_enr_2year
	peer_has_older_sibling_enr_4year
	;

// lag 1 older sibling controls ;
local sib_lag1_controls
	old1_sib_enr_2year
	old1_sib_enr_4year
	;

// lag 2 older sibling controls ;
local sib_lag2_controls
	old2_sib_enr_2year
	old2_sib_enr_4year
	;

// postsecondary distance controls
local d_controls
	mindist_any_nonprof_4yr
	mindist_ccc
	;

**********************************************  ;
*** macros for STANDALONE control vars for running loops over all samples and specifications ;
//base specification controls ;
local b_controls
	`school_controls'
	`demographic_controls'
	`ela_score_controls'
	`math_score_controls'
	;

//peer base controls ;
local peer_b_controls
	`peer_ela_score_controls'
	`peer_math_score_controls'
	`peer_demographic_controls'
	;

// leave out score controls ;
local l_controls
	loscore
	;

// peer leave out score controls ;
local peer_l_controls
	`peer_b_controls'
	peer_loscore
	;

local a_controls
	`census_controls'
	;

local peer_a_controls
	`peer_b_controls'
	`peer_census_controls'
	;

local s_controls
	`sibling_controls'
	;

local peer_s_controls
	`peer_b_controls'
	`peer_sibling_controls'
	;

// control var groups for looping ;
local la_controls
	`l_controls'
	`a_controls'
	;

local peer_la_controls
	`peer_b_controls'
	peer_loscore
	`peer_census_controls'
	;

local ls_controls
	`l_controls'
	`s_controls'
	;

local peer_ls_controls
	`peer_b_controls'
	peer_loscore
	`peer_sibling_controls'
	;

local as_controls
	`a_controls'
	`s_controls'
	;

local peer_as_controls
	`peer_b_controls'
	`peer_census_controls'
	`peer_sibling_controls'
	;

local las_controls
	`l_controls'
	`a_controls'
	`s_controls'
	;

local peer_las_controls
	`peer_b_controls'
	peer_loscore
	`peer_census_controls'
	`peer_sibling_controls'
	;

foreach control in b l a s la ls as las {;
	local `control'd_controls
		``control'_controls' `d_controls'
		;

	local peer_`control'd_controls
		`peer_`control'_controls'
		;
	}
	;


*** macros for control var COMBINATIONS for running loops over all samples and specifications ;
//base specification controls ;
local b_spec_controls
	`school_controls'
	`demographic_controls'
	`ela_score_controls'
	`math_score_controls'
	;
// predicted score spec controls
local b_scrhat_spec_controls
	`school_controls'
	`demographic_controls'
	`ela_scrhat_controls'
	`math_score_controls'
	;

local bd_spec_controls
	`b_spec_controls'
	`d_controls'
	;

local bd_scrhat_spec_controls
	`b_scrhat_spec_controls'
	`d_controls'
	;

// leave out prior score controls ;
local l_spec_controls
	`b_spec_controls'
	loscore
	;

local l_scrhat_spec_controls
	`b_spec_controls'
	loscore
	;

local ld_spec_controls
	`l_spec_controls'
	`d_controls'
	;

local ld_scrhat_spec_controls
	`l_scrhat_spec_controls'
	`d_controls'
	;

// ACS
local a_spec_controls
	`b_spec_controls'
	`census_controls'
	;
local a_scrhat_spec_controls
	`b_scrhat_spec_controls'
	`census_controls'
	;
local ad_spec_controls
	`a_spec_controls'
	`d_controls'
	;

local ad_scrhat_spec_controls
	`a_scrhat_spec_controls'
	`d_controls'
	;

// sibling
local s_spec_controls
	`b_spec_controls'
	`s_controls'
	;
local s_scrhat_spec_controls
	`b_scrhat_spec_controls'
	`s_controls'
	;
local sd_spec_controls
	`s_spec_controls'
	`d_controls'
	;
local sd_scrhat_spec_controls
	`s_scrhat_spec_controls'
	`d_controls'
	;

// loscores and acs
local la_spec_controls
	`b_spec_controls'
	`l_controls'
	`a_controls'
	;
local la_scrhat_spec_controls
	`b_scrhat_spec_controls'
	`l_controls'
	`a_controls'
	;

local lad_spec_controls
	`la_spec_controls'
	`d_controls'
	;
local lad_scrhat_spec_controls
	`la_scrhat_spec_controls'
	`d_controls'
	;

local ls_spec_controls
	`b_spec_controls'
	`l_controls'
	`s_controls'
	;
local ls_scrhat_spec_controls
	`b_scrhat_spec_controls'
	`l_controls'
	`s_controls'
	;

local lsd_spec_controls
	`ls_spec_controls'
	`d_controls'
	;
local lsd_scrhat_spec_controls
	`ls_scrhat_spec_controls'
	`d_controls'
	;

local as_spec_controls
	`b_spec_controls'
	`a_controls'
	`s_controls'
	;
local as_scrhat_spec_controls
	`b_scrhat_spec_controls'
	`a_controls'
	`s_controls'
	;

local asd_spec_controls
	`as_spec_controls'
	`d_controls'
	;
local asd_scrhat_spec_controls
	`as_scrhat_spec_controls'
	`d_controls'
	;



local las_spec_controls
	`b_spec_controls'
	`l_controls'
	`a_controls'
	`s_controls'
	;
local las_scrhat_spec_controls
	`b_scrhat_spec_controls'
	`l_controls'
	`a_controls'
	`s_controls'
	;

local lasd_spec_controls
	`las_spec_controls'
	`d_controls'
	;
local lasd_scrhat_spec_controls
	`las_scrhat_spec_controls'
	`d_controls'
	;

// strings for all sample and control combinations ;

local b_str
	"base"
	;

local bd_str
	`b_str'
	;

local l_str
	"leave out score"
	;

local ld_str
	`l_str'
	;

local a_str
	"ACS"
	;

local ad_str
	`a_str'
	;

local s_str
	"sibling"
	;

local sd_str
	`s_str'
	;

local la_str
	"leave out score & ACS"
	;

local lad_str
	`la_str'
	;

local ls_str
	"leave out score & sibling"
	;

local lsd_str
	`ls_str'
	;

local as_str
	"ACS & sibling"
	;

local asd_str
	`as_str'
	;

local las_str
	"leave out score & ACS & sibling"
	;

local lasd_str
	`las_str'
	;

local d_str
	"postsecondary distance"
	;

// strings for heterogeneity in persistence vars ;
local race_str
	"Race"
	;

local male_str "Male";

local econ_disadvantage_str "Economically Disadvantaged";

local prop_ecn_disadv_str "Proportion Economically Disadvantaged" ;

local charter_str "Charter Status" ;

local inc_median_hh_xtile_str "Census Tract Median Household Income Decile";

local enr_black_hisp_prop_str "Proportion of Black and Hispanic Enrollment";

**** School Characteristics ;
local sch_chars
	fte_teach_pc fte_pupil_pc /*fte_admin_pc*/
	/*eng_learner_staff_pc*/
	new_teacher_prop
	/*educ_grad_sch_prop educ_associate_prop*/
	/*status_tenured_prop*/
	credential_full_prop
	/*authorization_stem_prop authorization_ela_prop*/
	c.male_prop##c.enr_male_prop
	c.eth_minority_prop##c.enr_minority_prop
	enr_total
	;

local sch_char_vars "`sch_chars'" ;
local sch_char_vars : subinstr local sch_char_vars "i." "", all ;
local sch_char_vars : subinstr local sch_char_vars "c." "", all ;
local sch_char_vars : subinstr local sch_char_vars "##" " ", all ;
local sch_char_vars : subinstr local sch_char_vars "#" " ", all ;
local sch_char_vars : list uniq sch_char_vars ;

local dem_chars
	enr_male_prop
	enr_minority_prop
	frpm_prop el_prop
	enr_total
	;

local dem_char_vars "`dem_chars'" ;
local dem_char_vars : list uniq dem_char_vars ;

local expenditures
	expenditures_instr_pc
	expenditures3000_pc
	expenditures4000_pc
	expenditures_other_pc
	expenditures7000_pc
	;

local expenditure_vars "`expenditures'" ;
local expenditure_vars : list uniq expenditure_vars ;

local sch_char_control_vars : list sch_char_vars | dem_char_vars ;
local sch_char_control_vars : list sch_char_control_vars | expenditure_vars ;


#delimit cr
