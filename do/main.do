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
    - `m4_acceptance_run' is the master override for ADR-0018 acceptance-run
      scenarios.  Setting it to 1 forces the three run-once-cached sub-toggles
      (do_touse_va, do_create_samples, do_va) ON, so the run rebuilds samples
      + VA estimates from scratch instead of relying on cached predecessor
      outputs.  Default 0 mirrors predecessor `do_all.do' cached-output pattern.
      Predecessor's cached outputs live at LEGACY paths the consolidated
      pipeline doesn't read from, so M4 must regenerate them at CANONICAL
      $datadir_clean paths.
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
    - main.do itself opens a master log at $logdir/main.smcl.  [2026-05-28]
      The master log captures only the orchestration layer (which phases
      ran, runtime, exit codes), not the full sub-do transcript.  Each phase
      body runs with the master log suspended (named-log off at the start of
      the phase, named-log on at the end), so sub-do output goes only to the
      per-file logs.  This keeps the master log small and pushable; the
      per-file logs hold the detail.

REFERENCES
    Plan v3 §3.4 (main.do construction)
    Plan v3 §5.3 (automated data checks)
    ADR-0018 (offboarding acceptance criteria — all toggles on)
    ADR-0021 (do/ relocation; self-contained sandbox; description convention)
------------------------------------------------------------------------------*/


clear all
cap log close master

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
log using "$logdir/main_`stamp'.smcl", replace text name(master)

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
ACCEPTANCE-RUN MASTER OVERRIDE  (per ADR-0018)

    Set m4_acceptance_run = 1 when doing the canonical end-to-end run that
    produces ALL consolidated outputs (M4 golden-master, v1.0-final freeze,
    any other ADR-0018-acceptance scenario).  The flag overrides three
    sub-toggles inside Phases 2-3 (do_touse_va, do_create_samples, do_va)
    from their cached-default 0 to 1, so the run rebuilds samples + VA
    estimates from scratch instead of relying on cached predecessor outputs.

    Why all three: the cached samples + VA estimates from predecessor
    production live at LEGACY paths the consolidated pipeline doesn't read
    from.  M4 must regenerate them at CANONICAL $datadir_clean and
    $estimates_dir paths so the consolidated pipeline finds them.

    Leave at 0 for dev iteration where you want the cached-outputs pattern
    (mirrors predecessor `do_all.do' defaults).

    See ADR-0018 acceptance criteria + plan v3 §3.5 golden-master verification.
==============================================================================*/

local m4_acceptance_run  1   // CHANGE ME to 1 for full acceptance / M4 run

di as text _n "M4 acceptance-run override: " ///
    cond(`m4_acceptance_run', "ENABLED — sub-toggles do_touse_va, do_create_samples, do_va will be forced to 1", "DISABLED — sub-toggles use cached-defaults")


/*==============================================================================
PHASE 1 — DATA PREP
==============================================================================*/

if `run_data_prep' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 1: DATA PREP"
    di as text "{hline 80}"
    log off master   // orchestration-only: suspend master during phase body (see file header)

    * Phase 1a §3.3 step 9 COMPLETE 2026-05-08 — Christina-owned data-prep
    * scripts relocated under do/data_prep/.  5 batches (9a-9e) landed;
    * 32 files total.  Each invocation carries a one-liner per ADR-0021.
    *
    * Step 9 batch 9a — ACS census-tract (2 files): LANDED 2026-05-08
    do do/data_prep/acs/acs_2017_gen_dict.do        // build 2017 ACS subject-table data dictionaries (descsave .dta+.csv)
    do do/data_prep/acs/clean_acs_census_tract.do   // clean 2010-2013 ACS census-tract subject tables S0601/S1501/S1702/S1901; produces $datadir_clean/acs/acs_ca_census_tract_clean.dta

    * Step 9 batch 9b — school-characteristics (11 files): LANDED 2026-05-08
    * Chain order from predecessor do_all.do:75-97; tempfile-based assembly in clean_sch_char (master)
    do do/data_prep/schl_chars/cds_nces_xwalk.do        // build CDS<->NCES school-id crosswalk; writes $datadir_clean/cde/cds_nces_id_xwalk.dta
    do do/data_prep/schl_chars/clean_locale.do           // clean NCES urban-rural locale codes; writes $datadir_clean/nces/pubschls_locale.dta (reads cds_nces xwalk)
    do do/data_prep/schl_chars/clean_elsch.do            // clean CDE EL-school yearly data; per-year $datadir_clean/cde/elsch/ dtas (consumed by clean_sch_char via append)
    do do/data_prep/schl_chars/clean_enr.do              // clean CDE enrollment by race/sex/total yearly; per-year $datadir_clean/cde/enr/ dtas (consumed by clean_sch_char via append)
    do do/data_prep/schl_chars/clean_frpm.do             // clean CDE Free/Reduced Price Meals yearly; per-year $datadir_clean/cde/frpm/ dtas (consumed by clean_sch_char via append)
    do do/data_prep/schl_chars/clean_staffcred.do        // clean CDE staff credentials yearly; per-year $datadir_clean/cde/staffcred/ dtas (consumed by clean_sch_char via append)
    do do/data_prep/schl_chars/clean_staffdemo.do        // clean CDE staff demographics yearly; per-year $datadir_clean/cde/staffdemo/ dtas (consumed by clean_sch_char via append)
    do do/data_prep/schl_chars/clean_staffschoolfte.do   // clean CDE staff-school FTE yearly; per-year $datadir_clean/cde/staffschoolfte/ dtas (consumed by clean_sch_char via append)
    do do/data_prep/schl_chars/clean_charter.do          // clean CDE charter status; writes $datadir_clean/cde/charter_status.dta
    do do/data_prep/schl_chars/clean_ecn_disadv.do       // clean CDE economic-disadvantage; writes $datadir_clean/cde/ecn_disadv.dta
    do do/data_prep/schl_chars/clean_sch_char.do         // MASTER: appends 6 sister cleaners' per-year dtas into 8 in-file tempfiles + merges with 3 chain dtas; writes $datadir_clean/sch_char.dta + per-year snapshots

    * Step 9 batch 9c — k12_postsec_distance (5 files): LANDED 2026-05-08
    * MAIN entry-point sub-calls hd2021 (run); reconcile_cdscodes.do + merge_k12_postsec_dist.doh + check_merge.do are not directly invoked from main.do.
    * - reconcile_cdscodes.do is ORPHAN in both predecessor and consolidated (not called by anyone); preserved per ADR-0021.  Phase 1c §5.1 dead-code review will decide its fate.
    * - merge_k12_postsec_dist.doh is a helper `include'd by relocated batch-2b sample-construction files (do/samples/create_score_samples.do + create_out_samples.do; consolidated callsites updated 2026-05-08).
    do do/data_prep/k12_postsec_distance/k12_postsec_distances.do  // MAIN: build K12-postsec distance file (IPEDS HD2021 + CDE pubschls + geodist); writes $datadir_clean/k12_postsec_distance/clean/k12_postsec_{distance,mindistance}.dta; calls `run hd2021.do' as sub-script
    do do/data_prep/k12_postsec_distance/check_merge.do            // diagnostic: verify mindistance merges cleanly with score_b VA sample (sanity check; LEGACY read of $vaprojdir/data/va_samples_v1/score_b.dta + include of merge_k12_postsec_dist.doh)

    * Step 9 batch 9d — caschls/prepare/ (4 files): LANDED 2026-05-08
    do do/data_prep/prepare/enrollmentclean.do          // clean CDE annual enrollment 2014-15..2018-19; produces $datadir_clean/enrollment/schoollevel/enr<year>.dta (5 files; chain producer)
    do do/data_prep/prepare/poolgr11enr.do              // pool gr11 enrollment across 5 years; reads CHAIN enr<year>; writes $datadir_clean/enrollment/schoollevel/poolgr11enr.dta
    do do/data_prep/prepare/renamedata.do               // rename + standardize raw CalSCHLS surveys (elementary/parent/secondary/staff across years); writes $datadir_clean/calschls/{elementary,parent,secondary,staff}/<x><year>.dta — incl. pooled staff0414 consumed by splitstaff0414
    do do/data_prep/prepare/splitstaff0414.do           // split pre-existing $clndtadir/staff/staff0414 by year; writes $datadir_clean/calschls/staff/staff<year>.dta

    * Step 9 batch 9e — caschls/qoiclean/ (10 files): LANDED 2026-05-08 (final batch of Step 9)
    * Year-by-year QOI cleaning per CalSCHLS subgroup (parent/secondary/staff).
    * Reads CHAIN $datadir_clean/calschls/<sub>/<x><year>.dta (from renamedata batch 9d).
    * Writes CHAIN $datadir_clean/calschls/qoiclean/<sub>/<x>qoiclean<year>.dta.
    do do/data_prep/qoiclean/parent/parentqoiclean1415.do            // QOI clean parent CalSCHLS 1415
    do do/data_prep/qoiclean/parent/parentqoiclean1516.do            // QOI clean parent CalSCHLS 1516
    do do/data_prep/qoiclean/parent/parentqoiclean1617.do            // QOI clean parent CalSCHLS 1617
    do do/data_prep/qoiclean/parent/parentqoiclean1819_1718.do       // QOI clean parent CalSCHLS 1718+1819 (loop)
    do do/data_prep/qoiclean/secondary/secqoiclean1415.do            // QOI clean secondary CalSCHLS 1415
    do do/data_prep/qoiclean/secondary/secqoiclean1617.do            // QOI clean secondary CalSCHLS 1617
    do do/data_prep/qoiclean/secondary/secqoiclean1819_1718_1516.do  // QOI clean secondary CalSCHLS 1516+1718+1819 (loop)
    do do/data_prep/qoiclean/staff/staffqoiclean1415.do              // QOI clean staff CalSCHLS 1415
    do do/data_prep/qoiclean/staff/staffqoiclean1617_1516.do         // QOI clean staff CalSCHLS 1516+1617 (loop)
    do do/data_prep/qoiclean/staff/staffqoiclean1819_1718.do         // QOI clean staff CalSCHLS 1718+1819 (loop)

    * Step 9 batch 9g — caschls/responserate (4 files): LANDED 2026-05-08 (extension batch — Christina decision)
    * Order from predecessor master.do:220-229: trim<sub>demo -> <sub>responserate per subgroup.
    * Reads LEGACY $caschls_projdir/dta/demographics/<sub>/<x> (raw); writes CHAIN $datadir_clean/calschls/{demotrim,responserate}/<x>.
    do do/data_prep/responserate/trimsecdemo.do         // trim secondary CalSCHLS demographics per year (1415-1819); writes 5 yearly trimsecdemo dtas
    do do/data_prep/responserate/secresponserate.do     // compute secondary survey response rates by school; writes $datadir_clean/calschls/responserate/secresponserate.dta (consumed by 9f secpooling)
    do do/data_prep/responserate/trimparentdemo.do      // trim parent CalSCHLS demographics per year (1415-1819); writes 5 yearly trimparentdemo dtas
    do do/data_prep/responserate/parentresponserate.do  // compute parent survey response rates by school; writes $datadir_clean/calschls/responserate/parentresponserate.dta (consumed by 9f parentpooling)

    * Step 9 batch 9f — caschls/poolingdata (4 of 5 files): LANDED 2026-05-08 (extension batch — Christina decision)
    * Order from predecessor master.do:302-341: <sub>pooling -> mergegr11enr -> clean_va.
    * Reads CHAIN qoiclean (9e) + responserate (9g) + poolgr11enr (9d); writes CHAIN analysisready/poolingdata outputs (consumed by Step 7 survey-VA in do/survey_va/).
    * NOTE: clean_va.do (5th file of batch 9f) moved to Phase 5 trailer 2026-05-25
    * because it CHAIN-reads $estimates_dir/va_cfr_all_v1/va_est_dta/va_<outcome>_all.dta
    * produced by do/va/merge_va_est.do (Phase 3 batch 3c1) and so must run AFTER
    * Phase 3.  Predecessor caschls master.do treated VA outputs as pre-existing
    * artifacts from a separate cde_va_project_fork pipeline; consolidation
    * collapses both into one master so the dependency now binds.  See its
    * invocation under PHASE 5 below.
    do do/data_prep/poolingdata/secpooling.do           // pool secondary qoiclean across years; writes secpooledstats + secanalysisready
    do do/data_prep/poolingdata/parentpooling.do        // pool parent qoiclean across years; writes parentpooledstats + parentanalysisready
    do do/data_prep/poolingdata/staffpooling.do         // pool staff qoiclean across years; writes staffpooledstats only (staffanalysisready is created downstream by mergegr11enr from staffpooledstats + poolgr11enr)
    do do/data_prep/poolingdata/mergegr11enr.do         // merge gr11enr_mean weight onto parent/sec analysisready (in-place update); CREATES staffanalysisready from staffpooledstats + poolgr11enr
    *
    * NOTE per ADR-0019 (Christina-authored NSC crosswalk; pipeline-inactive)
    * + plan v3 §8 Q1 (verified by grep — ZERO production invocations of
    * crosswalk_*_outcomes.do): these crosswalk-build files are NOT invoked
    * from main.do.  They are static, run-once-cached artifacts.  Their
    * .dta outputs are pre-existing inputs that merge_k12_postsecondary.doh
    * consumes when called by Christina's sample-construction code (in the
    * run_samples block below).
    log on master    // resume master for the orchestration layer
}


/*==============================================================================
PHASE 2 — SAMPLE CONSTRUCTION
==============================================================================*/

if `run_samples' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 2: SAMPLE CONSTRUCTION"
    di as text "{hline 80}"
    log off master   // orchestration-only: suspend master during phase body (see file header)

    * Sample-construction sub-toggles (mirror predecessor `do_all.do' gates
    * for behavior parity).  Both touse_va and create_*_samples are
    * run-once-cached: their outputs persist in $datadir_clean and are
    * re-read by every VA-estimation step.  Default 0 mirrors `do_all.do:110'
    * (`local do_touse_va = 0') and `do_all.do:148' (`local do_create_samples = 0').
    * Flip to 1 only when re-seeding the sample crosswalks (e.g., after a CDE
    * data refresh).
    local do_touse_va        0
    local do_create_samples  0

    * M4 override (per ADR-0018): acceptance-run flips both sub-toggles ON
    * so the run rebuilds samples from scratch instead of relying on cached
    * predecessor outputs.  Required for a fully-self-contained M4 verification
    * — the cached samples on Scribe live at LEGACY predecessor paths
    * ($vaprojdir/data/sbac/va_samples.dta etc.), NOT at the CANONICAL
    * $datadir_clean paths the consolidated VA-estimation chain reads from.
    *
    * History: this override was REMOVED 2026-05-26 (earlier today) after
    * M4 attempt #5 hit r(601) on a dead include in touse_va.do:262.  The
    * dead include was RESOLVED later same day per ADR-0009 v1-canonical
    * (touse_va.do CONVENTION DEVIATIONS block), so the override is now
    * safe to restore.  See attempt #6 master log for the cache-missing
    * symptom that prompted this restoration.
    if `m4_acceptance_run' {
        local do_touse_va        1
        local do_create_samples  1
    }

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
    log on master    // resume master for the orchestration layer
}


/*==============================================================================
PHASE 3 — VA ESTIMATION
==============================================================================*/

if `run_va_estimation' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 3: VA ESTIMATION"
    di as text "{hline 80}"
    log off master   // orchestration-only: suspend master during phase body (see file header)

    * VA estimation sub-toggle (mirrors predecessor `do_all.do:160' for
    * behavior parity).  All four entry points are run-once-cached: outputs
    * persist in $estimates_dir/va_cfr_all_v[12]/ and are re-read by
    * downstream paper tables, figures, and pass-through regressions.
    * Default 0 mirrors `do_all.do:160' (`local do_va = 0').  Flip to 1 only
    * when re-running estimation (e.g., after ADR-0006 vam.ado update).
    local do_va  0

    * M4 override (per ADR-0018): acceptance-run flips do_va ON.
    if `m4_acceptance_run' {
        local do_va  1
    }

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
    log on master    // resume master for the orchestration layer
}


/*==============================================================================
PHASE 4 — VA TABLES + FIGURES
==============================================================================*/

if `run_va_tables' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 4: VA TABLES + FIGURES"
    di as text "{hline 80}"
    log off master   // orchestration-only: suspend master during phase body (see file header)

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
    log on master    // resume master for the orchestration layer
}


/*==============================================================================
PHASE 5 — SURVEY VA (CalSCHLS indices)
==============================================================================*/

if `run_survey_va' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 5: SURVEY VA"
    di as text "{hline 80}"
    log off master   // orchestration-only: suspend master during phase body (see file header)

    * RELOCATED 2026-05-08 per plan v3 §3.3 steps 7+10+11 (+ Step 9 batch 9f
    * trailer clean_va.do, moved 2026-05-25; see NOTE below) — Survey VA chain.
    * Reads CHAIN $datadir_clean/{survey_va,schoolchar,calschls/{analysisready,va}}/<x>
    * (Steps 9f + 10 + 11); writes CANONICAL $datadir_clean/survey_va/<x> +
    * $estimates_dir/survey_va/factor/<x> + $output_dir/csv|graph/factoranalysis/<x>.

    * Step 9 batch 9f trailer — clean_va.do moved here 2026-05-25 (cross-phase
    * ordering fix discovered during M4 acceptance attempt #4).  Belongs at start
    * of Phase 5 because it CHAIN-reads both Phase 1 analysisready dtas (from
    * sec/parent/staffpooling + mergegr11enr above) AND Phase 3 VA outputs (from
    * do/va/merge_va_est.do), and produces va_pooled_all.dta consumed only by
    * survey-VA scripts below.  Predecessor caschls master.do invoked it within
    * the pooling batch because VA outputs were treated as pre-existing artifacts
    * from a separate cde_va_project_fork pipeline; consolidated single-master
    * flow now requires it to wait for Phase 3.
    do do/data_prep/poolingdata/clean_va.do        // clean VA estimates from $estimates_dir/va_cfr_all_v1/ (CHAIN from do/va/merge_va_est.do — Phase 3); writes $datadir_clean/calschls/va/va_pooled_all.dta + in-place updates secanalysisready/parentanalysisready (consumed by allsvymerge + factor + pcascore below)

    do do/survey_va/allsvymerge.do                 // RELOCATED Step 11; merges parent/sec/staff CalSCHLS qoimeans into $datadir_clean/survey_va/allsvyqoimeans.dta + per-survey formerge dtas (consumed by imputation + compcasecategoryindex below)
    do do/survey_va/imputation.do                  // multiply-impute missing CalSCHLS QOI items; writes $datadir_clean/survey_va/imputedallsvyqoimeans.dta
    do do/survey_va/imputedcategoryindex.do        // build climate/quality/support indices on imputed data (9/15/4 items per ADR-0010); sums→means fix DEFERRED Phase 1b §4.2 per ADR-0011
    do do/survey_va/compcasecategoryindex.do       // same indices on complete-case data
    do do/survey_va/indexalpha.do                  // Cronbach α for paper footnote (paper-text fix DEFERRED post-handoff per Christina 2026-05-07)
    do do/survey_va/mattschlchar.do                // RELOCATED Step 10 batch 10c per ADR-0013; produces $datadir_clean/schoolchar/schlcharpooledmeans.dta consumed by Table 8 panel producers (indexregwithdemo + indexhorseracewithdemo below)
    do do/survey_va/testscore.do                   // RELOCATED Step 11; produces $datadir_clean/schoolchar/testscorecontrols.dta (6th + 8th grade test scores) consumed by Table 8 panel producers below
    do do/survey_va/indexregwithdemo.do            // bivariate survey-VA regressions w/ school chars (paper Table 8 Panel A)
    do do/survey_va/indexhorseracewithdemo.do      // horserace survey-VA regressions w/ school chars (paper Table 8 Panel B)
    do do/survey_va/indexhorserace.do              // horserace without demo controls
    do do/survey_va/factor.do                      // exploratory factor analysis (eigen plots; intermediate, not paper-shipping)
    do do/survey_va/pcascore.do                    // PCA scoreplot for survey factors

    * Phase 1a §3.3 step 8 COMPLETE — `alpha.do' archived to `do/_archive/exploratory/' per ADR-0010.
    * Phase 1a §3.3 step 11 COMPLETE — `allsvymerge.do' + `testscore.do' relocated ACTIVE above (chain producers, not exploratory as initially flagged); `allsvyfactor.do' archived to `do/_archive/exploratory/' per ADR-0010 (truly exploratory; no chain consumers).
    log on master    // resume master for the orchestration layer
}


/*==============================================================================
PHASE 6 — PAPER OUTPUTS
==============================================================================*/

if `run_paper_outputs' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 6: PAPER OUTPUTS"
    di as text "{hline 80}"
    log off master   // orchestration-only: suspend master during phase body (see file header)

    * Phase 1a §3.3 step 10 IN PROGRESS — share/ paper producers relocated
    * under do/share/.  3-batch split (10a-10c); landing batches incrementally.
    * Each invocation carries a one-liner per the ADR-0021 description convention.
    *
    * Step 10 batch 10a — cde/share (10 files): LANDED 2026-05-08
    do do/share/sample_counts_tab.do                // sample-size counts table across spec/sample/outcome combinations
    do do/share/base_sum_stats_tab.do               // base sample summary statistics table for paper
    do do/share/kdensity.do                         // kdensity plots of VA estimates by version
    do do/share/va_scatter.do                       // VA scatter plots — score vs outcome VA, multiple specifications
    do do/share/va_var_explain.do                   // variance-explained regression by VA component
    do do/share/va_var_explain_tab.do               // variance-explained table from var-explain regression results
    do do/share/va_spec_fb_tab_all.do               // VA specification + forecast-bias test summary table (all-outcomes combined)
    do do/share/reg_out_va_tab.do                   // outcome-on-VA regression coefficient table
    do do/share/svyindex_tab.do                     // survey-VA index regression table (Table 8 panels); reads CHAIN $estimates_dir/survey_va/factor/<x> (Step 7)
    do do/share/check/corr_dk_score_va.do           // diagnostic: correlation between drift-knot (DK) score and VA estimates

    * Step 10 batch 10b — caschls/share/demographics (4 files): LANDED 2026-05-08
    * Diagnostic coverage analyses; produce .png graphs under $output_dir/graph/pooleddiagnostics/.
    do do/share/demographics/elemcoverageanalysis.do        // diagnostic: elementary CalSCHLS coverage analysis
    do do/share/demographics/parentcoverageanalysis.do      // diagnostic: parent CalSCHLS coverage analysis
    do do/share/demographics/seccoverageanalysis.do         // diagnostic: secondary CalSCHLS coverage analysis
    do do/share/demographics/pooledsecanalysis.do           // diagnostic: pooled secondary CalSCHLS analysis

    * Step 10 batch 10c — caschls/share/{outcomesumstats,siblingxwalk,svyvaregs,factoranalysis/mattschlchar} (7 files): LANDED 2026-05-08 — STEP 10 COMPLETE
    do do/share/siblingxwalk/siblingmatch.do            // build sibling-match (cdscode-pair) crosswalk
    do do/share/siblingxwalk/uniquefamily.do            // produce unique-family identifier crosswalk (reads CHAIN siblingxwalk/k12_xwalk)
    do do/share/siblingxwalk/siblingpairxwalk.do        // produce sibling-pair crosswalk dataset for downstream regs
    do do/share/outcomesumstats/nsc_codebook.do         // produce NSC outcomes codebook (txt log; 2010-2017 + 2010-2018)
    do do/share/svyvaregs/allvaregs.do                  // run all VA-on-survey regressions (svyvaregs umbrella)
    * NOTE: do/share/outcomesumstats/nsc2019new/k12_nsc2019_merge.doh is a helper `include'd by callers — not directly invoked from main.do.
    * NOTE: do/survey_va/mattschlchar.do (relocated this batch per ADR-0013) is invoked from Phase 5 via the existing wiring or separately by Table 8 producers.
    log on master    // resume master for the orchestration layer
}


/*==============================================================================
PHASE 7 — AUTOMATED DATA CHECKS  (per plan v3 §5.3)
==============================================================================*/

if `run_data_checks' {
    di as text _n(2) "{hline 80}"
    di as text "PHASE 7: AUTOMATED DATA CHECKS"
    di as text "{hline 80}"
    log off master   // orchestration-only: suspend master during phase body (see file header)

    * Phase 1c §5.3 — six check files per the design memo
    * (quality_reports/reviews/2026-04-28_data-checks-design.md).
    * Order matters: structural check first, then data invariants, then
    * pipeline outputs.  A failed `assert` halts the pipeline at the
    * offending check, leaving partial outputs on disk for diagnosis.
    * Each invocation carries a one-liner per the ADR-0021 description
    * convention.
    * WIRED 2026-05-17 — calls below activated for ADR-0018 acceptance run.
    do do/check/check_logs.do            // assert every relocated do file produced a log (structural; runs first)
    do do/check/check_samples.do         // assert sample-construction N's match historical baselines
    do do/check/check_merges.do          // assert merge rates against codebook-derived bounds
    do do/check/check_va_estimates.do    // assert VA estimate ranges + counts within expected envelopes
    do do/check/check_survey_indices.do  // assert CalSCHLS indices in [-2,2] (means per ADR-0011)
    do do/check/check_paper_outputs.do   // assert paper table cells match historical magnitudes
    log on master    // resume master for the orchestration layer
}


/*==============================================================================
WRAP-UP
==============================================================================*/

di as text _n(3) "{hline 80}"
di as text "main.do — RUN END: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"

cap log close master
cap translate "$logdir/main_`stamp'.smcl" "$logdir/main_`stamp'.log", replace

di as text "Master log: $logdir/main_`stamp'.{smcl,log}"

* end of file
