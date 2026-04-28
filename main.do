/*------------------------------------------------------------------------------
main.do — single pipeline entry point for the consolidated VA project
================================================================================

PURPOSE
    Replaces `cde_va_project_fork/do_files/do_all.do` and `caschls/do/master.do`.
    One command (`stata -b do main.do` from `$consolidated_dir` on Scribe)
    runs the entire pipeline end-to-end.

STATUS
    SKELETON (drafted 2026-04-28 ahead of plan v3 APPROVED).  Phase toggles
    are wired up; phase BODIES are stubbed with TODO markers.  Each stub
    will be filled in as Phase 1a §3.3 relocates the corresponding scripts.

INVOCATION
    cd /home/research/ca_ed_lab/projects/common_core_va/consolidated
    stata -b do main.do

CONVENTIONS
    - Phase toggles let dev iterate on one stage without re-running everything.
      Production / acceptance runs (per ADR-0018) toggle ALL on, including
      run_data_checks.
    - Each phase block calls do-files relative to $consolidated_dir.
    - Per-do-file logging convention (plan v3 §5.1 step 2): each invoked do
      file opens its own log via `log using $logdir/<filename>.smcl`.
    - main.do itself opens a master log at $logdir/main.smcl that captures
      the orchestration layer (which phases ran, runtime, exit codes).

REFERENCES
    Plan v3 §3.4 (main.do construction)
    Plan v3 §5.3 (automated data checks)
    ADR-0018 (offboarding acceptance criteria — all toggles on)
------------------------------------------------------------------------------*/


clear all
cap log close _all

* Load globals.  settings.do exits with rc=601 if $consolidated_dir is absent,
* so failure here is informative.
include settings.do


/*==============================================================================
LOG SETUP
==============================================================================*/

cap mkdir "$logdir"
local stamp = subinstr("`c(current_date)'", " ", "-", .) + "_" ///
            + subinstr("`c(current_time)'", ":", "-", .)
log using "$logdir/main_`stamp'.smcl", replace text

di as text _n(2) "{hline 80}"
di as text "main.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "Host: `c(hostname)' | Stata: `c(stata_version)' | User: `c(username)'"
di as text "{hline 80}"


/*==============================================================================
PHASE TOGGLES  (set to 1 to run the phase, 0 to skip)
==============================================================================*/

* Default: every phase ON.  Production / acceptance runs (ADR-0018) require
* every toggle ON, including run_data_checks.  Dev iteration can toggle off
* upstream phases if their cached outputs are still valid.
local run_data_prep         1
local run_samples           1
local run_va_estimation     1
local run_va_tables         1
local run_survey_va         1
local run_paper_outputs     1
local run_data_checks       1


/*==============================================================================
PHASE 1 — DATA PREP
==============================================================================*/

if `run_data_prep' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 1: DATA PREP"
    di as text "{hline 80}"

    * TODO Phase 1a §3.3 step 9: invoke Christina-owned data-prep scripts
    * (relocated under do/data_prep/).  Examples expected:
    *   do do/data_prep/enrollmentclean.do
    *   do do/data_prep/acs/<scripts>
    *   do do/data_prep/schl_chars/<scripts>
    *   do do/data_prep/k12_postsec_distance/<scripts>
    *   do do/data_prep/prepare/<scripts>
    *   do do/data_prep/caschls_qoiclean/<scripts>
    *
    * NOTE per plan v3 §8 Q1 / ADR-0019: the crosswalk_*_outcomes.do files
    * are NOT invoked from main.do.  They are static, run-once-cached
    * artifacts.  Their .dta outputs are pre-existing inputs that
    * merge_k12_postsecondary.doh consumes when called by Christina's
    * sample-construction code (in the run_samples block below).
}


/*==============================================================================
PHASE 2 — SAMPLE CONSTRUCTION
==============================================================================*/

if `run_samples' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 2: SAMPLE CONSTRUCTION"
    di as text "{hline 80}"

    * TODO Phase 1a §3.3 step 2: invoke sample-construction scripts
    * (relocated under do/samples/).  Examples:
    *   do do/samples/touse_va.do
    *   do do/samples/create_score_samples.do
    *   do do/samples/create_out_samples.do
    *   do do/sibling_xwalk/siblingoutxwalk.do      // ADR-0005
    *   do do/samples/create_va_sib_acs_restr_smp.do
    *   do do/samples/create_va_sib_acs_out_restr_smp.do
}


/*==============================================================================
PHASE 3 — VA ESTIMATION
==============================================================================*/

if `run_va_estimation' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 3: VA ESTIMATION"
    di as text "{hline 80}"

    * TODO Phase 1a §3.3 step 3: invoke VA estimation
    * (relocated under do/va/).  Examples:
    *   do do/va/va_score_all.do                    // ADR-0004 / ADR-0009
    *   do do/va/va_out_all.do
    *   do do/va/heterogeneity/va_het.do
    *   do do/va/pass_through/<scripts>
}


/*==============================================================================
PHASE 4 — VA TABLES + FIGURES
==============================================================================*/

if `run_va_tables' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 4: VA TABLES + FIGURES"
    di as text "{hline 80}"

    * TODO Phase 1a §3.3 step 10: paper-shipping tables (per ADR-0012,
    * _tab.do CSVs are local-review-only; canonical paper outputs come
    * from share/).  Examples:
    *   do do/share/va/<table producers>
    *   do do/share/va/<figure producers>
}


/*==============================================================================
PHASE 5 — SURVEY VA (CalSCHLS indices)
==============================================================================*/

if `run_survey_va' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 5: SURVEY VA"
    di as text "{hline 80}"

    * TODO Phase 1a §3.3 step 7: invoke CalSCHLS index construction +
    * survey-VA regressions (relocated under do/survey_va/).
    *   do do/survey_va/imputation.do
    *   do do/survey_va/imputedcategoryindex.do      // sums→means fix per ADR-0011
    *   do do/survey_va/compcasecategoryindex.do     // sums→means fix per ADR-0011
    *   do do/survey_va/indexalpha.do                // canonical α per ADR-0010
    *   do do/survey_va/indexregwithdemo.do
    *   do do/survey_va/indexhorseracewithdemo.do
}


/*==============================================================================
PHASE 6 — PAPER OUTPUTS
==============================================================================*/

if `run_paper_outputs' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 6: PAPER OUTPUTS"
    di as text "{hline 80}"

    * TODO Phase 1a §3.3 step 10: paper-shipping tables/figures from share/.
    *   do do/share/sample_counts_tab.do             // ADR-0009 v1-only
    *   do do/share/base_sum_stats_tab.do            // ADR-0009 v1-only
    *   ... etc.
}


/*==============================================================================
PHASE 7 — AUTOMATED DATA CHECKS  (per plan v3 §5.3)
==============================================================================*/

if `run_data_checks' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 7: AUTOMATED DATA CHECKS"
    di as text "{hline 80}"

    * TODO Phase 1c §5.3: six check files per the design memo
    * (quality_reports/reviews/2026-04-28_data-checks-design.md).
    * Order matters: structural check first, then data invariants, then
    * pipeline outputs.  A failed `assert` halts the pipeline at the
    * offending check, leaving partial outputs on disk for diagnosis.
    *
    *   do do/check/check_logs.do          // structural; runs first
    *   do do/check/check_samples.do
    *   do do/check/check_merges.do
    *   do do/check/check_va_estimates.do
    *   do do/check/check_survey_indices.do
    *   do do/check/check_paper_outputs.do
}


/*==============================================================================
WRAP-UP
==============================================================================*/

di as text _n(3) "{hline 80}"
di as text "main.do — RUN END: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"

cap log close
cap translate "$logdir/main_`stamp'.smcl" "$logdir/main_`stamp'.log", replace

di as text "Master log: $logdir/main_`stamp'.{smcl,log}"

* end of file
