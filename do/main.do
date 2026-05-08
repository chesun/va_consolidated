/*------------------------------------------------------------------------------
do/main.do — single pipeline entry point for the consolidated VA project
================================================================================

PURPOSE
    Replaces `cde_va_project_fork/do_files/do_all.do` and `caschls/do/master.do`.
    One command (`stata -b do do/main.do` from `$consolidated_dir` on Scribe)
    runs the entire pipeline end-to-end.

STATUS
    SKELETON (drafted 2026-04-28 ahead of plan v3 APPROVED; relocated under
    do/ on 2026-04-29 per ADR-0021).  Phase toggles are wired up; phase
    BODIES are stubbed with TODO markers.  Each stub will be filled in as
    Phase 1a §3.3 relocates the corresponding scripts.

INVOCATION
    cd /home/research/ca_ed_lab/projects/common_core_va/consolidated
    stata -b do do/main.do

SANDBOX PRINCIPLE (per ADR-0021)
    The consolidated/ folder is a self-contained output sandbox.  Every WRITE
    by every do file in this pipeline lands under $consolidated_dir.  Reads
    from predecessor paths (Matt's files, legacy caches, restricted-access
    raw data) are fine, but no script may write back to those paths.  Payoff:
    `diff -r consolidated/output predecessor/output` cleanly compares the new
    pipeline against the old one without polluting either side.

CONVENTIONS
    - Phase toggles let dev iterate on one stage without re-running everything.
      Production / acceptance runs (per ADR-0018) toggle ALL on, including
      run_data_checks.
    - Each phase block calls do-files relative to $consolidated_dir.
    - Per-do-file logging convention (plan v3 §5.1 step 2): each invoked do
      file opens its own log via `log using $logdir/<filename>.smcl`.
    - Description convention (per ADR-0021): every do-file invocation below
      carries a one-liner describing what the called script does.  The called
      script's own header carries the authoritative longer description.
    - The phase blocks below currently hold *placeholder* one-liners —
      Phase 1a §3.3 has not yet relocated the actual scripts.  When each
      script is relocated, the per-commit checklist (per phase-1-review.md
      §2) requires cross-checking the one-liner against the relocated
      script's header and updating it if the script's role differs.
    - main.do itself opens a master log at $logdir/main.smcl that captures
      the orchestration layer (which phases ran, runtime, exit codes).

REFERENCES
    Plan v3 §3.4 (main.do construction)
    Plan v3 §5.3 (automated data checks)
    ADR-0018 (offboarding acceptance criteria — all toggles on)
    ADR-0021 (do/ relocation; self-contained sandbox; description convention)
------------------------------------------------------------------------------*/


clear all
cap log close _all

* Load globals.  do/settings.do exits with rc=601 if $consolidated_dir is absent,
* so failure here is informative.  CWD is $consolidated_dir per the INVOCATION
* block above; include resolves relative to CWD.
include do/settings.do


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
    * (relocated under do/data_prep/).  Each invocation carries a one-liner
    * per the ADR-0021 description convention.  Authoritative longer
    * description lives in the called script's own header.  Example shape:
    *
    *   do do/data_prep/enrollmentclean.do            // clean K12 enrollment records
    *   do do/data_prep/acs/<scripts>                 // build ACS school-neighborhood demographics (2010-2013)
    *   do do/data_prep/schl_chars/<scripts>          // assemble school-level characteristics (race/SES/Title-I)
    *   do do/data_prep/k12_postsec_distance/<scripts>// build K12-to-postsec mindist controls
    *   do do/data_prep/prepare/<scripts>             // pre-merge prep for sample construction
    *   do do/data_prep/caschls_qoiclean/<scripts>    // clean CalSCHLS QOI items for survey-VA
    *
    * NOTE per ADR-0019 (Christina-authored NSC crosswalk; pipeline-inactive)
    * + plan v3 §8 Q1 (verified by grep — ZERO production invocations of
    * crosswalk_*_outcomes.do): these crosswalk-build files are NOT invoked
    * from main.do.  They are static, run-once-cached artifacts.  Their
    * .dta outputs are pre-existing inputs that merge_k12_postsecondary.doh
    * consumes when called by Christina's sample-construction code (in the
    * run_samples block below).
}


/*==============================================================================
PHASE 2 — SAMPLE CONSTRUCTION
==============================================================================*/

if `run_samples' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 2: SAMPLE CONSTRUCTION"
    di as text "{hline 80}"

    * Sample-construction sub-toggles (mirror predecessor `do_all.do' gates
    * for behavior parity).  Both touse_va and create_*_samples are
    * run-once-cached: their outputs persist in $datadir_clean and are
    * re-read by every VA-estimation step.  Default 0 mirrors `do_all.do:110'
    * (`local do_touse_va = 0') and `do_all.do:148' (`local do_create_samples = 0').
    * Flip to 1 only when re-seeding the sample crosswalks (e.g., after a CDE
    * data refresh).
    local do_touse_va        0
    local do_create_samples  0

    * RELOCATED 2026-04-30 per ADR-0005 — sibling enrollment-outcomes crosswalk
    * (the only file from caschls/do/share/siblingvaregs/ that survives
    * consolidation per ADR-0004).  First real Phase 1a §3.3 relocation; sets
    * the precedent for subsequent moves.
    do do/sibling_xwalk/siblingoutxwalk.do             // build sibling enrollment-outcomes crosswalk (transitive-closure family grouping; reads K12+postsec via Matt's merge_k12_postsecondary.doh; writes $datadir_clean/siblingxwalk/sibling_out_xwalk.dta)

    * RELOCATED 2026-05-07 per plan v3 §3.3 step 2 batch 2b — sample-tag
    * crosswalk + score/outcome VA estimation samples.  Both gated 0 by
    * default (run-once-cached pattern).  Relocation preserves predecessor
    * verbatim except for path repointing to CANONICAL `$datadir_clean'.
    if `do_touse_va' {
        do do/samples/touse_va.do                      // tag the VA-eligible analysis sample (touse_g11_<subject>/<outcome> markers; writes $datadir_clean/sbac/va_samples.dta)
    }
    if `do_create_samples' {
        do do/samples/create_score_samples.do          // build 7 test-score VA samples × 2 prior-score versions (v1/v2 per ADR-0009); writes $datadir_clean/va_samples_v[12]/score_*.dta
        do do/samples/create_out_samples.do            // build 7 outcome VA samples × 2 prior-score versions; writes $datadir_clean/va_samples_v[12]/out_*.dta
    }

    * NOTE: plan v3 main.do template (lines 175-176) listed
    * create_va_sib_acs_restr_smp.do + create_va_sib_acs_out_restr_smp.do at
    * this site, but per ADR-0004 those files are deprecated (caschls
    * siblingvaregs subtree) and belong in the Step 6 archive batch, not
    * Step 2 active relocation.  The plan v3 template will be corrected when
    * Step 6 lands.

    * TODO Phase 1a §3.3 step 2 batch 2c: relocate sample-construction merge
    * helpers (merge_loscore.doh, merge_sib.doh, merge_va_smp_acs.doh,
    * merge_lag2_ela.doh from cde sbac).  Until then, create_score_samples.do
    * and create_out_samples.do call them via LEGACY $vaprojdir paths.
}


/*==============================================================================
PHASE 3 — VA ESTIMATION
==============================================================================*/

if `run_va_estimation' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 3: VA ESTIMATION"
    di as text "{hline 80}"

    * VA estimation sub-toggle (mirrors predecessor `do_all.do:160' for
    * behavior parity).  All four entry points are run-once-cached: outputs
    * persist in $estimates_dir/va_cfr_all_v[12]/ and are re-read by
    * downstream paper tables, figures, and pass-through regressions.
    * Default 0 mirrors `do_all.do:160' (`local do_va = 0').  Flip to 1 only
    * when re-running estimation (e.g., after ADR-0006 vam.ado update).
    local do_va  0

    * RELOCATED 2026-05-07 per plan v3 §3.3 step 3 batch 3a — score-VA + outcome-VA
    * estimation entry points (canonical pipeline per ADR-0004; v1/v2 prior-score
    * controls per ADR-0009; CFR drift-limit shrinkage via vam.ado v2.0.1+noseed
    * per ADR-0006).  All 4 gated together (run-once-cached pattern).
    if `do_va' {
        do do/va/va_score_all.do                       // estimate score-VA (16 specs × subject × v1/v2; CFR drift; spec-test); writes $estimates_dir/va_cfr_all_v[12]/{vam,spec_test,va_est_dta}/
        do do/va/va_score_fb_all.do                    // forecast-bias test for score-VA (excludes lasd by design — see macros_va_all_samples_controls.doh:66); writes .../{vam,fb_test}/
        do do/va/va_out_all.do                         // estimate outcome-VA + Deep Knowledge VA (controlling for ELA/Math VA from va_score_all); writes .../{vam,spec_test,va_est_dta}/
        do do/va/va_out_fb_all.do                      // forecast-bias test for outcome-VA + DK VA; writes .../{vam,fb_test}/

        * RELOCATED 2026-05-07 per plan v3 §3.3 step 3 batch 3b — paper-shipping
        * spec/FB test summary tables.  Read .ster outputs from the 4 entry-point
        * scripts above; produce summary .dta + (for va_spec_fb_tab) per-outcome
        * CSV at $tables_dir/va_cfr_all_v[12]/{spec_test,fb_test,combined}/.
        do do/va/va_score_spec_test_tab.do             // score-VA spec-test summary table; appends rows to $tables_dir/.../spec_test/spec_<subject>_all.dta
        do do/va/va_out_spec_test_tab.do               // outcome-VA spec-test summary table; appends rows to $tables_dir/.../spec_test/spec_<outcome>_all.dta
        do do/va/va_score_fb_test_tab.do               // score-VA FB-test summary table (excludes lasd per ADR-0004); appends rows to $tables_dir/.../fb_test/fb_<subject>_all.dta
        do do/va/va_out_fb_test_tab.do                 // outcome-VA FB-test summary table; appends rows to $tables_dir/.../fb_test/fb_<outcome>_all.dta
        do do/va/va_spec_fb_tab.do                     // combined spec+FB CSV per (outcome × version); writes $tables_dir/.../combined/fb_spec_<outcome>.csv

        * RELOCATED 2026-05-08 per plan v3 §3.3 step 3 batch 3c1 — utilities
        * (merge per-cell estimates into master VA dataset; correlation
        * diagnostic; prior-decile + census-income-decile dtas for outcome
        * regressions).  These produce inputs consumed by reg_out_va_*.do
        * (batch 3c2).
        do do/va/merge_va_est.do                       // merge per-cell VA estimate dtas into va_<outcome>_all.dta + super-master va_all.dta; writes $estimates_dir/va_cfr_all_v[12]/va_est_dta/
        do do/va/va_corr.do                            // diagnostic: print correlation matrix of VA estimates across 8 spec combinations; output to log only (no .dta/.csv)
        do do/va/prior_decile_original_sample.do       // build student-level prior-score deciles + race/sex/econ from out_b sample; census income deciles from out_a; writes $datadir_clean/sbac/{prior_decile_original_sample,census_income_decile_a_sample}.dta

        * RELOCATED 2026-05-08 per plan v3 §3.3 step 3 batch 3c2 — outcome
        * regressions + paper-shipping tables/figures.  Read merged VA estimates
        * (from merge_va_est.do) + outcome samples (from batch 2b) + prior-decile
        * dtas (from prior_decile_original_sample.do); produce regression .ster
        * + paper Tables 4-7 CSVs + paper figures.
        do do/va/reg_out_va_all.do                     // regress postsec outcomes on score VA + heterogeneity (prior decile gated off; race/sex/econ/charter/income); writes $estimates_dir/.../reg_out_va/
        do do/va/reg_out_va_all_tab.do                 // paper-shipping CSV tables of outcome-VA regressions; writes $tables_dir/.../reg_out_va/
        do do/va/reg_out_va_all_fig.do                 // paper-shipping figures of outcome-VA heterogeneity; writes $figures_dir/.../ + $output_dir/gph_files/.../ (intermediate .gph)
        do do/va/reg_out_va_dk_all.do                  // regress postsec outcomes on Deep Knowledge VA; heterogeneity by prior-score decile; writes $estimates_dir/.../reg_out_va/
        do do/va/reg_out_va_dk_all_tab.do              // paper-shipping CSV tables of DK VA regressions; writes $tables_dir/.../reg_out_va_dk/
        do do/va/reg_out_va_dk_all_fig.do              // paper-shipping figures of DK VA heterogeneity; writes $figures_dir/.../ + $output_dir/gph_files/.../

        * RELOCATED 2026-05-08 per plan v3 §3.3 step 3 batch 3d — sibling-lag
        * forecast-bias diagnostic (not paper-reported per do_all.do comment).
        * Reads score_s sample dta from batch 2b; produces .ster + summary CSV.
        do do/va/va_score_sib_lag.do                   // sibling-lag FB diagnostic for score VA; lag-1 older-sibling controls + lag-2 FB leave-out; writes $estimates_dir/.../{vam,spec_test,fb_test,va_est_dta}/
        do do/va/va_out_sib_lag.do                     // sibling-lag FB diagnostic for outcome VA (mirror of score variant)
        do do/va/va_sib_lag_spec_fb_tab.do             // combined spec+FB summary CSV for sibling-lag diagnostic specs; writes $tables_dir/.../combined/sib_lag_fb_spec_<outcome>.csv

        * RELOCATED 2026-05-08 per plan v3 §3.3 step 4 — heterogeneity.
        * Reads merged VA estimates (from merge_va_est.do, batch 3c1) +
        * sch_char.dta (LEGACY, Step 9 deferred); produces VA-by-school-char
        * regressions + paper Table 8 panel + figures.
        * NOTE: plan v3 mentioned `pass_through/` as a Step 4 destination, but
        * the predecessor has no pass_through/ directory.  Step 4 = 4 va_het files only.
        do do/va/heterogeneity/va_het.do               // VA heterogeneity by district + school chars; produces va_all_schl_char.dta + paper Table 8 panel LaTeX (var_across_district + corr_char)
        do do/va/heterogeneity/va_corr_schl_char.do    // VA-by-school-char regressions per (sample × control × peer × het_char) cell; writes $estimates_dir/.../va_het/<...>.ster
        do do/va/heterogeneity/va_corr_schl_char_fig.do // paper figures: VA distribution by school chars (scatter + density); writes $figures_dir/.../va_het/<...>.pdf
        do do/va/heterogeneity/persist_het_student_char_fig.do // combined-panel figures for outcome-VA persistence by student chars; reads .gph from batch 3c2 reg_out_va_all_fig.do
    }

    * NOTE: predecessor `out_drift_limit.doh' is DEAD CODE (never included by any
    * active script — all 4 entry points include `drift_limit.doh' which already
    * defines both score_drift_limit and out_drift_limit).  Defer to Phase 1c §5.1
    * archival.
}


/*==============================================================================
PHASE 4 — VA TABLES + FIGURES
==============================================================================*/

if `run_va_tables' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 4: VA TABLES + FIGURES"
    di as text "{hline 80}"

    * TODO Phase 1a §3.3 step 10 (VA-specific share/ producers): paper-shipping
    * VA tables and figures (per ADR-0012, _tab.do CSVs are local-review-only;
    * canonical paper outputs come from share/).  Each invocation carries a
    * one-liner per the ADR-0021 description convention.  Example shape:
    *
    *   do do/share/va/<table producers>          // paper VA tables (Tables 2-3 spec/FB tests, etc.)
    *   do do/share/va/<figure producers>         // paper VA figures (forest plots, distributions)
    *
    * Phase 4 vs Phase 6: §3.3 step 10 covers ALL share/ producers as one
    * bucket; main.do splits VA-specific producers (Phase 4, depend on
    * va_estimation outputs) from non-VA producers (Phase 6, e.g.,
    * sample_counts_tab, base_sum_stats_tab, survey-VA tables).
}


/*==============================================================================
PHASE 5 — SURVEY VA (CalSCHLS indices)
==============================================================================*/

if `run_survey_va' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 5: SURVEY VA"
    di as text "{hline 80}"

    * TODO Phase 1a §3.3 step 7: invoke CalSCHLS index construction +
    * survey-VA regressions (relocated under do/survey_va/).  Each invocation
    * carries a one-liner per the ADR-0021 description convention.  Example
    * shape:
    *
    *   do do/survey_va/imputation.do                // multiply-impute missing CalSCHLS QOI items
    *   do do/survey_va/imputedcategoryindex.do      // build climate/quality/support indices on imputed data (sums→means fix per ADR-0011)
    *   do do/survey_va/compcasecategoryindex.do     // build climate/quality/support indices on complete-case data (sums→means fix per ADR-0011)
    *   do do/survey_va/indexalpha.do                // Cronbach α for canonical paper-α per ADR-0010
    *   do do/survey_va/indexregwithdemo.do          // single-index survey-VA regressions (paper Table 8 panel)
    *   do do/survey_va/indexhorseracewithdemo.do    // multi-index horserace survey-VA regressions (paper Table 8 panel)
}


/*==============================================================================
PHASE 6 — PAPER OUTPUTS
==============================================================================*/

if `run_paper_outputs' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 6: PAPER OUTPUTS"
    di as text "{hline 80}"

    * TODO Phase 1a §3.3 step 10 (non-VA share/ producers): paper-shipping
    * tables/figures that don't depend on VA estimates (counts, descriptives,
    * survey-VA tables).  See Phase 4 note for the §3.3-step-10 split rationale.
    * Each invocation carries a one-liner per the ADR-0021 description
    * convention.  Example shape:
    *
    *   do do/share/sample_counts_tab.do             // paper Table A.1 sample-restriction waterfall (ADR-0009 v1-only)
    *   do do/share/base_sum_stats_tab.do            // paper Table 1 baseline summary statistics (ADR-0009 v1-only)
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
    * Each invocation carries a one-liner per the ADR-0021 description
    * convention.
    *
    *   do do/check/check_logs.do            // assert every relocated do file produced a log (structural; runs first)
    *   do do/check/check_samples.do         // assert sample-construction N's match historical baselines
    *   do do/check/check_merges.do          // assert merge rates against codebook-derived bounds
    *   do do/check/check_va_estimates.do    // assert VA estimate ranges + counts within expected envelopes
    *   do do/check/check_survey_indices.do  // assert CalSCHLS indices in [-2,2] (means per ADR-0011)
    *   do do/check/check_paper_outputs.do   // assert paper table cells match historical magnitudes
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
