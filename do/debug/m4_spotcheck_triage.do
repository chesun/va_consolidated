/*==============================================================================
    m4_spotcheck_triage.do — one-off M4 golden-master FAIL/READ_ERROR triage

    Purpose:    Spot-check the full-run (7fe9c1a) diff summary:
                  Section 1 — e(N) on one FAILing .ster pair per cluster
                              (sib1 / las / la) to tie the 46 small-coef FAILs
                              to ADR-0026 / ADR-0028 sample changes.
                  Section 2 — count + variable-list diff on representative
                              rc=9 structural-mismatch .dta pairs, plus the
                              3 rc=900 pairs under raised maxvar; where obs
                              counts match, cf on the common varlist to test
                              whether shared values are identical.
    Invoked:    standalone on Scribe from repo root —
                  stata-mp -b do do/debug/m4_spotcheck_triage.do
                NOT called by do/main.do.
    Paths:      predecessor/consolidated pairs copied verbatim from
                do/check/m4_path_matrix.csv (grep the filename to audit).
                derive-ok: `pred_`i'' / `cons_`i'' / `ster_`i'' are nested
                locals indexed by the forvalues counter `i' — resolved at
                runtime, not undefined globals.
    References: quality_reports/reviews/2026-06-10_m4-full-golden-master_triage.md
==============================================================================*/

clear all
set more off
set maxvar 32767            // rc=900 pairs (analysisready, sec1617) are too wide for default
include do/settings.do

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/debug"
cap log close m4_spotcheck
log using "$logdir/debug/m4_spotcheck_triage.smcl", replace name(m4_spotcheck)

di as text _n "m4_spotcheck_triage.do — RUN START: `c(current_date)' `c(current_time)'"

*===============================================================================
* SECTION 1 — e(N) comparison on FAILing .ster pairs (one per cluster)
*===============================================================================
di as text _n "{hline 79}" _n "[SECTION 1] e(N) on FAIL .ster pairs" _n "{hline 79}"

local pred_root  "/home/research/ca_ed_lab/projects/common_core_va"
local cons_root  "/home/research/ca_ed_lab/projects/common_core_va/consolidated"

* cluster label : relpath (identical on both sides for these pairs)
local ster_1 "estimates/va_cfr_all_v1/spec_test/spec_math_s_sp_sib1_ct.ster"
local lab_1  "sib1 (ADR-0026 hypothesis)"
local ster_2 "estimates/va_cfr_all_v1/reg_out_va/reg_enr_2year_va_ela_las_sp_ad_ct_p_m.ster"
local lab_2  "las (ADR-0028 hypothesis)"
local ster_3 "estimates/va_cfr_all_v1/spec_test/spec_ela_la_sp_lad_ct.ster"
local lab_3  "la (ADR-0028 hypothesis)"

forvalues i = 1/3 {
    di as text _n "--- [`lab_`i''] `ster_`i''"
    local Np = .
    local Nc = .
    local Cp = .
    local Cc = .
    capture estimates use "`pred_root'/`ster_`i''"
    if _rc di as error "    predecessor load FAILED rc=" _rc
    else {
        local Np = e(N)
        local Cp = cond(e(N_clust) < ., e(N_clust), .)
    }
    capture estimates use "`cons_root'/`ster_`i''"
    if _rc di as error "    consolidated load FAILED rc=" _rc
    else {
        local Nc = e(N)
        local Cc = cond(e(N_clust) < ., e(N_clust), .)
    }
    di as result "    e(N):       pred=`Np'  cons=`Nc'  delta=" `Nc' - `Np'
    di as result "    e(N_clust): pred=`Cp'  cons=`Cc'"
}

*===============================================================================
* SECTION 2 — structural classification of rc=9 / rc=900 .dta pairs
*===============================================================================
di as text _n "{hline 79}" _n "[SECTION 2] count + varlist diff on READ_ERROR .dta pairs" _n "{hline 79}"

* Pairs: pred_i = predecessor abs path, cons_i = consolidated abs path
* (verbatim from do/check/m4_path_matrix.csv)
local npairs = 6

local pred_1 "`pred_root'/data/va_samples_v1/score_b.dta"
local cons_1 "`cons_root'/data/cleaned/va_samples_v1/score_b.dta"
local lab_1  "score_b (rc=9 rep; family: va_samples score_/out_)"

local pred_2 "`pred_root'/estimates/va_cfr_all_v1/va_est_dta/va_all.dta"
local cons_2 "`cons_root'/estimates/va_cfr_all_v1/va_est_dta/va_all.dta"
local lab_2  "va_all v1 (rc=9 rep; family: va_est_dta)"

local pred_3 "/home/research/ca_ed_lab/users/chesun/gsr/caschls/dta/buildanalysisdata/analysisready/staffanalysisready.dta"
local cons_3 "`cons_root'/data/cleaned/calschls/analysisready/staffanalysisready.dta"
local lab_3  "staffanalysisready (rc=9 rep; family: calschls analysisready)"

local pred_4 "/home/research/ca_ed_lab/users/chesun/gsr/caschls/dta/buildanalysisdata/analysisready/parentanalysisready.dta"
local cons_4 "`cons_root'/data/cleaned/calschls/analysisready/parentanalysisready.dta"
local lab_4  "parentanalysisready (rc=900 — retry under maxvar 32767)"

local pred_5 "/home/research/ca_ed_lab/users/chesun/gsr/caschls/dta/buildanalysisdata/analysisready/secanalysisready.dta"
local cons_5 "`cons_root'/data/cleaned/calschls/analysisready/secanalysisready.dta"
local lab_5  "secanalysisready (rc=900 — retry under maxvar 32767)"

local pred_6 "/home/research/ca_ed_lab/data/restricted_access/clean/calschls/secondary/sec1617.dta"
local cons_6 "`cons_root'/data/cleaned/calschls/secondary/sec1617.dta"
local lab_6  "sec1617 (rc=900 — retry under maxvar 32767)"

forvalues i = 1/`npairs' {
    di as text _n "--- [`lab_`i'']"
    di as text "    pred: `pred_`i''"
    di as text "    cons: `cons_`i''"

    capture use "`pred_`i''", clear
    if _rc {
        di as error "    predecessor load FAILED rc=" _rc
        continue
    }
    local Np = _N
    local Kp = c(k)
    qui ds
    local vp `r(varlist)'

    capture use "`cons_`i''", clear
    if _rc {
        di as error "    consolidated load FAILED rc=" _rc
        continue
    }
    local Nc = _N
    local Kc = c(k)
    qui ds
    local vc `r(varlist)'

    di as result "    obs:  pred=`Np'  cons=`Nc'  delta=" `Nc' - `Np'
    di as result "    vars: pred=`Kp'  cons=`Kc'"

    local pred_only : list vp - vc
    local cons_only : list vc - vp
    local common    : list vp & vc
    local n_po : word count `pred_only'
    local n_co : word count `cons_only'
    local n_cm : word count `common'
    di as result "    vars only in PREDECESSOR (`n_po'): `pred_only'"
    di as result "    vars only in CONSOLIDATED (`n_co'): `cons_only'"

    * If obs counts match, value-compare the common variables.
    * CAVEAT: cf compares row-by-row — if reported diffs are large, rule out a
    *         sort-order difference before concluding data regression.
    if `Np' == `Nc' & `n_cm' > 0 {
        di as text "    obs counts match -> cf on `n_cm' common vars:"
        capture use "`pred_`i''", clear
        if _rc {
            di as error "    predecessor RE-load FAILED rc=" _rc " -> skip cf (would self-compare consolidated)"
            continue
        }
        capture noisily cf `common' using "`cons_`i''"
        di as result "    cf rc=" _rc " (0 = all common-var values identical)"
    }
    else if `Np' != `Nc' {
        di as result "    obs counts DIFFER -> skip cf; triage the N delta (intended ADR change vs regression)"
    }
}

di as text _n "m4_spotcheck_triage.do — RUN END: `c(current_date)' `c(current_time)'"

cap log close m4_spotcheck
cap translate "$logdir/debug/m4_spotcheck_triage.smcl" "$logdir/debug/m4_spotcheck_triage.log", replace
