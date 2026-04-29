/*------------------------------------------------------------------------------
Codebook Export — for Phase 1c automated data checks (plan v3 §5.3)
================================================================================

PURPOSE
    For each dataset listed in §0, run `describe` and `codebook` and capture
    the output to a single log file.  `codebook` shows variable type, range,
    n unique, n missing, and (for labeled vars) the numeric-to-label
    tabulation — which is everything Claude needs to design the data-checks
    pipeline.

    Output contains variable metadata + value-frequency tables only — no
    individual student records — but please skim before sharing.

INSTRUCTIONS
    1. Place this file on Scribe at `do_files/explore/codebook_export.do`.
       (Server uses do_files/ + log_files/, NOT consolidated do/ + log/.)
    2. Edit §0 globals — at minimum the CalSCHLS path(s).  Verify the rest.
       Blank a global to skip its dataset.
    3. Run from the project root:
            cd /home/research/ca_ed_lab/projects/common_core_va
            stata -b do do_files/explore/codebook_export.do
    4. Ship `log_files/codebooks/codebook_export_<stamp>.log` to Claude.

NOTE
    Each `use` is wrapped in `capture noisily` — a wrong path or missing
    file prints `[SKIP]` and the script continues.  Edit the matching
    global and re-run; previously-successful blocks finish in seconds.

ROLE IN ADR-0021 SANDBOX
    Diagnostic, NOT pipeline-active in the consolidated sandbox.  Runs on
    the predecessor Scribe layout (`do_files/` + `log_files/`) and reads
    predecessor data globals; its log lands under predecessor `log_files/`,
    not under `$consolidated_dir/log/`.  This is intentional — the file's
    purpose is to dump codebook metadata from datasets that the predecessor
    pipeline produces.  When/if a consolidated codebook export becomes
    needed, write a separate consolidated-sandbox script at that time.

REFERENCES
    Plan:    quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §5.3, §9
    Audit:   quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md
    ADRs:    0010, 0011, 0015, 0017, 0021 (description convention; sandbox role above)
------------------------------------------------------------------------------*/

clear all
set more off
cap log close _all
set linesize 255


/*==============================================================================
BASE GLOBALS  (auto-defined if missing so the script is standalone)
==============================================================================*/

* Values mirror cde_va_project_fork/do_files/settings.do (verified 2026-04-28).
* If Christina has already loaded settings.do this session, existing values
* are preserved.  Otherwise the defaults below kick in.
if "$vaprojdir"   == "" global vaprojdir   "/home/research/ca_ed_lab/projects/common_core_va"
if "$vaprojxwalks" == "" global vaprojxwalks "$vaprojdir/data/restricted_access/clean/crosswalks"
if "$projdir"     == "" global projdir     "/home/research/ca_ed_lab/users/chesun/gsr/caschls"

di as text "  vaprojdir   = $vaprojdir"
di as text "  vaprojxwalks = $vaprojxwalks"
di as text "  projdir     = $projdir"


/*==============================================================================
§0 — DATASET PATHS  (verify / edit before running; blank to skip)
==============================================================================*/

* All paths below verified 2026-04-28 against the actual source code.
* Reference lines noted in each block.

* Priority 1 — CalSCHLS index sources.  Two distinct files, one per index type.
*   _1: imputedcategoryindex.do:26 reads this (imputed-data pipeline)
*   _2: compcasecategoryindex.do:28 reads this (complete-case pipeline)
* Christina: $projdir in caschls context resolves to your gsr/caschls dir
* (already confirmed by the cb_calschls_1 path you filled in).
global cb_calschls_1  "/home/research/ca_ed_lab/users/chesun/gsr/caschls/dta/allsvyfactor/imputedallsvyqoimeans"
global cb_calschls_2  "/home/research/ca_ed_lab/users/chesun/gsr/caschls/dta/allsvyfactor/allsvyqoimeans"
global cb_calschls_3  ""    /* spare */

* Priority 2 — K-12 main analytical sample (post-VA estimation, school-char merged).
* Confirmed at va_het.do:73 (`save $vaprojdir/estimates/va_cfr_all_`version'/va_est_dta/va_all_schl_char.dta`)
* with version=v1 per ADR-0009.
global cb_k12_main    "$vaprojdir/estimates/va_cfr_all_v1/va_est_dta/va_all_schl_char.dta"

* Pre-VA base sample.  create_score_samples.do:84 saves the `score_b` (base)
* sample here; the _l / _a / _s / _la / _ls / _as / _las variants in the same
* directory add lags / ACS / sibling.  `score_b` is the foundation — richest
* demographic content before the VA-est join trims columns.
global cb_k12_pre_va  "$vaprojdir/data/va_samples_v1/score_b.dta"

* School characteristics (mattschlchar.do output per ADR-0013).
* Loaded by va_het.do:32 — drives the heterogeneity tables (paper Table 8 chain).
global cb_sch_char    "$vaprojdir/data/sch_char.dta"

* Priority 3 — NSC outcomes crosswalk.
* Confirmed at merge_k12_postsecondary.doh:67.
global cb_nsc         "$vaprojxwalks/nsc_outcomes_crosswalk_ssid.dta"

* Priority 4 — CCC outcomes + bridge.  Matt-owned producers but readable as data.
* Confirmed at merge_k12_postsecondary.doh:142 (bridge) and :153 (outcomes).
* NOTE: filenames are *_crosswalk.dta with no _ssid suffix (corrected 2026-04-28).
global cb_k12_ccc_xw  "$vaprojxwalks/k12_ccc_crosswalk.dta"
global cb_ccc         "$vaprojxwalks/ccc_outcomes_crosswalk.dta"

* Priority 5 — CSU outcomes + bridge.
* Confirmed at merge_k12_postsecondary.doh:207 (bridge) and :218 (outcomes).
* NOTE: filenames are *_crosswalk.dta with no _ssid suffix (corrected 2026-04-28).
global cb_k12_csu_xw  "$vaprojxwalks/k12_csu_crosswalk.dta"
global cb_csu         "$vaprojxwalks/csu_outcomes_crosswalk.dta"


/*==============================================================================
LOG SETUP
==============================================================================*/

local logdir "log_files/codebooks"
cap mkdir "log_files"
cap mkdir "`logdir'"
local stamp = subinstr("`c(current_date)'", " ", "-", .) + "_" ///
            + subinstr("`c(current_time)'", ":", "-", .)
local logbase "`logdir'/codebook_export_`stamp'"

log using "`logbase'.smcl", replace text

di as text _n(2) "{hline 80}"
di as text "CODEBOOK EXPORT — RUN START: `c(current_date)' `c(current_time)'"
di as text "Host: `c(hostname)' | Stata: `c(stata_version)' | User: `c(username)'"
di as text "{hline 80}"


/*==============================================================================
DUMP — describe + codebook for each non-empty path
==============================================================================*/

foreach g in cb_calschls_1 cb_calschls_2 cb_calschls_3       ///
             cb_k12_main cb_k12_pre_va cb_sch_char            ///
             cb_nsc                                           ///
             cb_k12_ccc_xw cb_ccc                             ///
             cb_k12_csu_xw cb_csu                             {
    local d "${`g'}"
    if "`d'" == "" continue

    di as text _n(2) "{hline 80}"
    di as text "DATASET (`g'): `d'"
    di as text "{hline 80}"

    capture noisily use "`d'", clear
    if _rc {
        di as error "  [SKIP] could not open — fix \$`g' in §0 and re-run."
        continue
    }

    * --- PII scrub --------------------------------------------------------
    * `codebook` prints up to 4 example values for string variables.  For
    * ID / name / DOB columns those examples are restricted-access values
    * (CSIS IDs, real student names, real DOBs).  Drop the known PII
    * columns BEFORE `describe` and `codebook`, so neither command can
    * surface those values in the log.  `cap drop` is harmless when a
    * column doesn't exist in the current dataset.
    foreach pii in state_student_id student_id idunique             ///
                   first_name last_name birth_date                  ///
                   merge_id_k12_test_scores                         ///
                   address address1 address2 ssid local_id          ///
                   first_name_dad first_name_mom last_name_parent   {
        cap drop `pii'
    }
    di as text "  PII scrub: dropped any of {state_student_id, student_id, idunique, first/last_name, birth_date, merge_id_k12_test_scores, address*, ssid, local_id, parent name fields} present in this dataset."

    di as text _n "*** describe ***"
    describe

    di as text _n "*** count ***"
    count

    di as text _n "*** codebook ***"
    codebook
}


/*==============================================================================
WRAP-UP
==============================================================================*/

di as text _n(3) "{hline 80}"
di as text "CODEBOOK EXPORT — RUN END: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"
di as text ""
di as text "OUTPUT: `logbase'.{smcl,log}"
di as text "Skim before sharing, then send the .log to Claude."

cap log close
cap translate "`logbase'.smcl" "`logbase'.log", replace

di as text _n "Log written to: `logbase'.log"

* end of file
