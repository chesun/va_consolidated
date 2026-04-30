/*------------------------------------------------------------------------------
do/va/helpers/macros_va_all_samples_controls.doh — sample/control combinations
================================================================================

PURPOSE
    Define `va_controls', `<spec>_ctrl_samples', and forecast-bias `<X>_fb_<Y>_samples'
    locals enumerating the cross-product of VA control specifications and
    samples consumed by VA estimation + forecast-bias regression loops in
    Phase 3 (VA estimation) and Phase 4 (VA tables).

    Defines (verbatim from predecessor):
      - 16 distinct VA-control specifications: b, l, a, s, la, ls, as, las
        and their distance-augmented variants (bd, ld, ad, sd, lad, lsd,
        asd, lasd) per ADR-0009 (v1 prior-score canonical) and the 2023-04-30
        distance-controls addition.
      - Per-spec sample lists (`<spec>_ctrl_samples') determining which
        analytic samples each spec runs against.
      - Forecast-bias leave-out variable lists (`<spec>_ctrl_leave_out_vars')
        per spec, including scrhat (predicted-score) variants.
      - Per-leave-out × spec sample lists (`<lov>_fb_<spec>_samples') for
        the forecast-bias regression sweep.

INCLUDED FROM
    Phase 3+ VA estimation/table-producer scripts under `do/va/' and `do/share/va/'.
    Typically included AFTER `macros_va.doh' (since some downstream uses
    overlap with the higher-level VA control definitions there).

ROLE IN ADR-0021 SANDBOX
    Pure local definitions; no reads, no writes; sandbox-trivially clean.
    No `$global' references, so no LEGACY-include macro-trace concerns.

RELOCATION HISTORY (per ADR-0005 + ADR-0021, applied 2026-04-30)
    Source:      cde_va_project_fork/do_files/sbac/macros_va_all_samples_controls.doh
    Destination: do/va/helpers/macros_va_all_samples_controls.doh
    Path repointing: none (no `$global' references).
    Analysis logic preserved verbatim.
    Predecessor caller-update protocol: predecessor callers untouched in
    this commit per plan v3 §3.3 step 5 parenthetical.

ORIGINAL CHANGE LOG (preserved from predecessor)
    2022-10-31: Naming-convention change for samples (b/l/a/s/la/ls/as/las).
    2023-04-30: Added minimum distance to postsecondary institutions as
                forecast-bias leave-out var (`d': distance).

REFERENCES
    Plan v3 §3.3 step 1 (helpers/macros)
    ADRs:    0009 (v1 prior-score canonical), 0021 (description convention)
    Audit:   chunk-3 (FB-test structure per Christina 2026-04-26 correction —
             `lasd' has nothing to leave out beyond distance, so column 6 of
             paper Tables 2/3 has blank FB rows BY DESIGN; verified via
             `va_controls_for_fb' L66 which excludes `lasd')
------------------------------------------------------------------------------*/

/* do helper file with macros for different controls, samples, forecast bias leave out vars,
and their combinations for running loops */

/* CHANGE LOG
10/31/2022: Changed naming convention for samples
b - base
l - loscore
a - acs
s - sibling
la - loscore and acs
ls - loscore and sibling
as - acs and sibling
las - loscore, acs and sibling

04/30/2023: added minimum distance to postsecondary institutions as fb leaveout var
d: distance
 */


****************************************************
/* macros for VA estimation */
****************************************************
// different control specifications
local va_controls b l a s la ls as las bd ld ad sd lad lsd asd lasd


*** samples for different VA control specifications
// samples used for specification with base controls
local b_ctrl_samples b l a s la ls as las
local bd_ctrl_samples b l a s la ls as las
// samples used for specification with leave out score controls
local l_ctrl_samples l la ls las
local ld_ctrl_samples l la ls las

// samples used for specification with acs controls
local a_ctrl_samples a la as las
local ad_ctrl_samples a la as las

// samples used for specification with sibling controls
local s_ctrl_samples s ls as las
local sd_ctrl_samples s ls as las

// samples used for specifications with leave out score and acs controls
local la_ctrl_samples la las
local lad_ctrl_samples la las

// samples used for specifications with leave out score and sibling controls
local ls_ctrl_samples ls las
local lsd_ctrl_samples ls las

// samples used for specifications with acs and sling controls
local as_ctrl_samples as las
local asd_ctrl_samples as las

// samples used for specifications with leave out score, acs, and sibling controls
local las_ctrl_samples las
local lasd_ctrl_samples las




****************************************************
/*  macros for forecast bias tests */
****************************************************
*** different control specifications used in forecast bias tests
local va_controls_for_fb b l a s la ls as las

*** different forecast bias leave out vars for different VA control specifications
local b_ctrl_leave_out_vars l a s la ls as las d
local l_ctrl_leave_out_vars a s as d
local a_ctrl_leave_out_vars l s ls d
local s_ctrl_leave_out_vars l a la d
local ls_ctrl_leave_out_vars a d
local la_ctrl_leave_out_vars s d
local as_ctrl_leave_out_vars l d
local las_ctrl_leave_out_vars d

// FB leave out vars for controls using predicted scores
local b_ctrl_scrhat_leave_out_vars a s as d
local l_ctrl_scrhat_leave_out_vars a s as d
local a_ctrl_scrhat_leave_out_vars s d
local s_ctrl_scrhat_leave_out_vars a d
local ls_ctrl_scrhat_leave_out_vars a d
local la_ctrl_scrhat_leave_out_vars s d
local as_ctrl_scrhat_leave_out_vars d
local las_ctrl_scrhat_leave_out_vars d

****************************************************
/*  samples for different forecast bias leave out vars with different VA specificationa */
****************************************************
******* samples for different corecast biase leave out vars with base control VA specification
// forecast bias test samples for leave out prior score as leave out var with base controls VA
local l_fb_b_samples l la ls las
// forecast bias test samples for acsibling controls as leave out var with base controls VA
local a_fb_b_samples a la as las
// forecast bias test samples for sling controls as leave out var with base controls VA
local s_fb_b_samples s ls as las
// forecast bias test samples for leave out score and acsibling controls as leave out var with base controls VA
local la_fb_b_samples la las
// forecast bias test samples for leave out score and sling controls as leave out var with base controls VA
local ls_fb_b_samples ls las
// forecast bias test samples for a and sling controls as leave out var with base controls VA
local as_fb_b_samples as las
// forecast bias test samples for leave out score, a, and sling controls as leave out var with base controls VA
local las_fb_b_samples las
// forecast bias test samples for postsec distance as leave out var with base controls VA
local d_fb_b_samples b l a s la ls as las

******* samples for different forecast bias leave out vars with base + leave out prior score VA specification
local a_fb_l_samples la las
local s_fb_l_samples ls las
local as_fb_l_samples las
local d_fb_l_samples l la ls las


******* samples for different forecast bias leave out vars with base + a VA specification
local l_fb_a_samples la las
local s_fb_a_samples as las
local ls_fb_a_samples las
local d_fb_a_samples a as la las



******* samples for different forecast bias leave out vars with base + sling VA specification
local l_fb_s_samples ls las
local a_fb_s_samples as las
local la_fb_s_samples las
local d_fb_s_samples s ls as las


******* samples for different forecast bias leave out vars with base + leave out prior score + a VA specification
local s_fb_la_samples las
local d_fb_la_samples la las

******* samples for different forecast bias leave out vars with base + leave out prior score + sling VA specification
local a_fb_ls_samples las
local d_fb_ls_samples ls las

******* samples for different forecast bias leave out vars with base + a + sling VA specification
local l_fb_as_samples las
local d_fb_as_samples as las

local d_fb_las_samples las
