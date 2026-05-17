/*------------------------------------------------------------------------------
T1 Empirical Tests — Phase 0a-v2 verified findings
================================================================================

PURPOSE
    Run the T1 empirical tests queued from the Phase 0a-v2 verified-final
    audit (`quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` §3.1)
    that touch ONLY Christina-owned files. Each test resolves a HIGH or
    MEDIUM-priority finding from the deep-read that requires running Stata
    against the data on Scribe (cannot be settled by code-reading alone).

    Resolves: P2-3 (and P2-11), P2-6, P2-13.

    SKIPPED (per Matt-Naven file ownership constraint, Phase 1 leaves these
    files untouched, so empirical testing is wasted effort):
      - T1-1 (P1-1: `id' macro at crosswalk_nsc_outcomes.do:250)
      - T1-2 (P2-1: Bug 93 family — NSC crosswalk + merge_k12_postsecondary.doh)

INSTRUCTIONS
    1. Place this file on Scribe at `do_files/check/t1_empirical_tests.do`
       (the project structure on Scribe uses `do_files/` and `log_files/`,
       NOT the consolidated repo's `do/` and `log/`).
    2. Run on Scribe in the project root:
            cd /home/research/ca_ed_lab/projects/common_core_va
            stata -b do do_files/check/t1_empirical_tests.do
       (or `do "do_files/check/t1_empirical_tests.do"` from inside Stata.)
    3. Tests are independent — each is wrapped in `capture` so a failure in
       one does not abort the others. Read the log end-to-end.
    4. T1-5 (OpenCage API key revocation) is a manual external action; this
       script only prints the reminder.

EXPECTED RUNTIME
    ~5-15 minutes total (small loads + diagnostics).

OUTPUT
    Stata log to log_files/check/t1_empirical_tests_<datetime>.smcl + .log

ROLE IN ADR-0021 SANDBOX
    Diagnostic, NOT pipeline-active in the consolidated sandbox.  Runs on
    the predecessor Scribe layout (`do_files/` + `log_files/`) and reads
    predecessor data; its log lands under predecessor `log_files/check/`,
    not under `$consolidated_dir/log/`.  This is intentional — the file's
    purpose is to verify findings from the Phase 0a deep-read audit against
    predecessor-pipeline state on Scribe before Phase 1a §3.3 relocation.
    Once the corresponding files are relocated and re-verified, this script
    is superseded by `do/check/check_*.do` (consolidated-sandbox checks per
    plan v3 §5.3).

REFERENCES
    Audit doc:  quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md §3.1
    TODO:       TODO.md (T1 Tests for Christina)
    ADRs:       0021 (description convention; sandbox role above)
------------------------------------------------------------------------------*/

clear all
set more off
cap log close _all
set linesize 120

* --- log setup ---------------------------------------------------------------
* Server uses log_files/ (not log/) per cde_va_project_fork convention.
local logdir "log_files/check"
cap mkdir "`logdir'"
local stamp = subinstr("`c(current_date)'", " ", "-", .) + "_" + subinstr("`c(current_time)'", ":", "-", .)
log using "`logdir'/t1_empirical_tests_`stamp'.smcl", replace

di as text _n(2) "{hline 80}"
di as text "T1 EMPIRICAL TESTS — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}" _n


/*==============================================================================
TEST T1-3 — `school_id == cdscode` 1:1 check (P2-3, P2-11)
================================================================================
BUG
    va_het.do:158 clusters on `cdscode` while paper claims clustering at
    `school_id`. Same pattern in chunk-5 sibling regs (reg_out_va_sib_acs.do
    L151, L174, L211, L225). If school_id and cdscode are 1:1, the difference
    is cosmetic only.

DIAGNOSTIC
    Load va_all.dta (or any analysis-ready VA file). Confirm school_id and
    cdscode are 1:1 — i.e., the tag of school_id is identical to the tag of
    cdscode.

VERDICT KEYS
    n_diff == 0 : 1:1 — clustering equivalent — fix is COSMETIC (rename only)
    n_diff >  0 : not 1:1 — clustering is SUBSTANTIVELY different — re-run
                  affected regressions in Phase 1
==============================================================================*/

di as text _n(2) "{hline 80}"
di as text "T1-3 — school_id == cdscode 1:1 check"
di as text "{hline 80}"

capture noisily {
    * va_all_schl_char.dta is the file actually loaded by va_het.do:155 right
    * before the buggy `cluster(cdscode)` regression at L158.
    local va_file "$vaprojdir/estimates/va_cfr_all_v1/va_est_dta/va_all_schl_char.dta"
    confirm file "`va_file'"

    use "`va_file'", clear
    di as text "  loaded `va_file' — N = `=_N'"

    capture confirm variable school_id cdscode
    if _rc {
        di as error "  school_id and/or cdscode not present in this file. " ///
            "Try a different file (e.g., a sample-construction output)."
    }
    else {
        * Tag uniqueness: every distinct school_id should map to exactly one cdscode and vice versa.
        egen tag_sid  = tag(school_id)
        egen tag_cds  = tag(cdscode)
        count if tag_sid != tag_cds
        local n_tag_diff = r(N)

        * Stronger check: any (school_id, cdscode) pair where the mapping is many-to-one?
        bysort school_id (cdscode): gen byte _multi_cds = cdscode != cdscode[1]
        bysort cdscode (school_id): gen byte _multi_sid = school_id != school_id[1]
        count if _multi_cds == 1
        local n_school_to_many_cds = r(N)
        count if _multi_sid == 1
        local n_cds_to_many_school = r(N)

        di as result _n "  n_tag_diff:               `n_tag_diff'"
        di as result    "  school_id -> many cdscode:`n_school_to_many_cds'"
        di as result    "  cdscode   -> many school: `n_cds_to_many_school'"

        if `n_tag_diff'==0 & `n_school_to_many_cds'==0 & `n_cds_to_many_school'==0 {
            di as result _n "  VERDICT: school_id == cdscode (1:1). " ///
                "Clustering on either is EQUIVALENT. Phase 1 fix is cosmetic rename only."
        }
        else {
            di as error  _n "  VERDICT: school_id != cdscode (NOT 1:1). " ///
                "Clustering is SUBSTANTIVELY different. Phase 1 must re-run affected regs."
        }
    }
}
if _rc {
    di as error "  T1-3 failed with rc=`_rc'. Check \$vaprojdir and the file path."
}


/*==============================================================================
TEST T1-4 — mtitles 24 cols vs eststo 32 cols in reg_out_va_all_tab.do (P2-6)
================================================================================
BUG (chunk 4 disc M4)
    reg_out_va_all_tab.do declares mtitles for 24 columns but accumulates
    32 eststo (2 subjects × 16 sample-ctrl-peer-match). esttab will silently
    produce un-labeled columns in the published CSV.

DIAGNOSTIC
    Read the produced CSV(s) directly and count columns. This .do file
    does the count via `import delimited' and reports the column count.

NOTE
    Adjust the glob pattern below if the table dir is named differently on the
    server (e.g., va_cfr_v1 vs va_cfr_all_v1). The check is shallow — it just
    counts comma-separated columns in the first row of each matching file.
==============================================================================*/

di as text _n(2) "{hline 80}"
di as text "T1-4 — reg_out_va_all_tab.do mtitles vs CSV column count"
di as text "{hline 80}"

capture noisily {
    local tab_dir "$vaprojdir/tables/va_cfr_all_v1/reg_out_va"
    local files : dir "`tab_dir'" files "reg_*.csv"
    local nfiles : word count `files'
    if `nfiles' == 0 {
        di as error "  No reg_*.csv files found in `tab_dir' (or directory missing)."
    }
    else {
        di as text "  Found `nfiles' CSV file(s) in `tab_dir':"
        foreach f of local files {
            capture import delimited "`tab_dir'/`f'", varnames(nonames) stringcols(_all) clear
            if _rc {
                di as error "    `f' — failed to read (rc=`_rc')"
            }
            else {
                local ncols = c(k)
                di as result "    `f' — `ncols' columns (declared mtitles = 24; expect 32 if bug fired)"
            }
        }
    }
}
if _rc {
    di as error "  T1-4 failed with rc=`_rc'. Check \$vaprojdir/tables path."
}


/*==============================================================================
TEST T1-5 — Revoke OpenCage API key (P2-13)
================================================================================
BUG
    OpenCage API key `[REVOKED 2026-04-30]` committed in source at
    k12_postsec_distances.do:98 (commented out, but live in git history).

ACTION (manual, NOT Stata)
    1. Log into the OpenCage account that owns the key.
    2. Revoke / rotate `[REVOKED 2026-04-30]`.
    3. If the key is still needed for a Phase-1 reproduction, generate a new
       one and store it OUTSIDE the repo (e.g., in `.claude/state/`, gitignored,
       or via an environment variable).

This block is a printed reminder only — no Stata logic.
==============================================================================*/

di as text _n(2) "{hline 80}"
di as text "T1-5 — Revoke OpenCage API key (manual external action)"
di as text "{hline 80}"
di as text "  Key to revoke: [REVOKED 2026-04-30]"
di as text "  Source:        k12_postsec_distances.do:98 (committed-but-commented)"
di as text "  Action:        log into OpenCage, revoke key, rotate if still needed."
di as text "  Storage:       new key (if any) goes in .claude/state/ or env var, NOT the repo."


/*==============================================================================
END OF TESTS
==============================================================================*/

di as text _n(2) "{hline 80}"
di as text "T1 EMPIRICAL TESTS — RUN END: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"
di as text "Read the per-test VERDICT lines above. Report results back to Claude:"
di as text "  - T1-3 verdict (1:1 / not 1:1)"
di as text "  - T1-4 column counts per CSV"
di as text "  - T1-5 confirmation that key is revoked"

cap log close _all
exit
