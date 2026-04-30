/*------------------------------------------------------------------------------
do/check/check_paper_outputs.do — assert paper-table cells match analytic outputs
================================================================================

PURPOSE
    Verify that the sample sizes and key magnitudes printed in the paper's
    tables match what the analytic pipeline produces (`share/` table-producer
    outputs).  Encodes the design memo §6 specification.

INPUTS
    Paper-table producer outputs (`share/` .tex fragments or .dta sidecars
    if producers save them).  Paths TBD until plan v3 §3.3 share/ relocation
    lands.

OUTPUTS
    Per-do-file log: $logdir/check_paper_outputs.smcl + .log
    On `assert` failure: pipeline halts; partial outputs preserved.

ROLE IN ADR-0021 SANDBOX
    Will read from CANONICAL paths once Phase 1a §3.3 relocates the share/
    producers.  Writes only to $logdir (CANONICAL).  Skeleton has NO
    runnable assertions yet — most cells are TBD-codebook per design memo §9
    open items ("Paper-table cell magnitudes ... after Phase 1a §3.3 share/
    relocation").  Skeleton verifies the inputs that are already known
    (k12_main N=5009, score_b N=1,784,445); the rest will be filled in as
    share/ producers come online.

INVARIANTS (verbatim from design memo §6)
    Hard asserts (currently runnable):
      - Table 1 (sample): N student-years == 1,784,445  (cf. score_b)
      - Table 2 (main spec): N schools == 5,009         (cf. k12_main)
    TBD-codebook (per design memo §9 open items; needs share/ producer outputs):
      - Per ADR-0010 footnote correction: indices have 9 / 15 / 4 items
        (NOT 20 / 17 / 4) — verifiable in paper table caption / footnote
        rather than in code; soft-check only.
      - Specific table cells (Table 2/3 main coefficients, etc.) — loaded
        from share/ producer .tex outputs or .dta sidecars if producers
        save them.

REFERENCES
    Design memo:    quality_reports/reviews/2026-04-28_data-checks-design.md §6
    Plan:           quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §5.3 step 9
    Codebook:       k12_main N (line 47349); score_b N (line 72845)
    ADRs:           0010 (paper-α 9/15/4), 0012 (share/ producers are paper-canonical),
                    0021 (description convention; sandbox role above)
------------------------------------------------------------------------------*/


clear all
set more off
cap log close _all
set linesize 120

cap mkdir "$logdir"
log using "$logdir/check_paper_outputs.smcl", replace text

di as text _n "{hline 80}"
di as text "check_paper_outputs.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


/*==============================================================================
SUB-CHECK 1 — Table 1 sample N (student-years)
==============================================================================*/

* TODO Phase 1a §3.3: confirm post-relocation path (sample-construction).
local in_score_b "$estimates_dir/va_samples_v1/score_b.dta"

capture confirm file "`in_score_b'"
if _rc {
    di as text "  [SKELETON] `in_score_b' not found — produced by Phase 1a §3.3"
    di as text "             sample-construction relocation.  Skipping Table 1 N check."
}
else {
    use "`in_score_b'", clear
    capture assert _N == 1784445
    if _rc {
        di as error "  FAIL: paper Table 1 N = " r(N) " (expected 1,784,445 student-years)"
        cap log close
        cap translate "$logdir/check_paper_outputs.smcl" "$logdir/check_paper_outputs.log", replace
        exit _rc
    }
    di as text "  PASS: paper Table 1 N == 1,784,445 (cf. score_b)"
}


/*==============================================================================
SUB-CHECK 2 — Table 2 N schools
==============================================================================*/

* TODO Phase 1a §3.3: confirm post-relocation path (VA-estimation outputs).
local in_k12_main "$estimates_dir/va_cfr_all_v1/va_est_dta/va_all_schl_char.dta"

capture confirm file "`in_k12_main'"
if _rc {
    di as text "  [SKELETON] `in_k12_main' not found — produced by Phase 1a §3.3"
    di as text "             VA-estimation relocation.  Skipping Table 2 N check."
}
else {
    use "`in_k12_main'", clear
    capture assert _N == 5009
    if _rc {
        di as error "  FAIL: paper Table 2 N schools = " r(N) " (expected 5,009)"
        cap log close
        cap translate "$logdir/check_paper_outputs.smcl" "$logdir/check_paper_outputs.log", replace
        exit _rc
    }
    di as text "  PASS: paper Table 2 N schools == 5,009 (cf. k12_main)"
}


/*==============================================================================
SUB-CHECK 3 — Specific table cells  (TBD-codebook)
==============================================================================*/

* TBD-codebook per design memo §9 open items.  Once Phase 1a §3.3 relocates
* the share/ table producers, their output paths (e.g.,
* $consolidated_dir/tables/share/va/v1/va_main.tex) become known.  This
* section will then load the .tex fragments (or .dta sidecars if producers
* save them) and assert that the printed cell magnitudes match the analytic
* pipeline's outputs to the tolerance specified in plan v3 §3.5 (estimates
* match to ≤ 0.01 per replication-protocol.md tolerance table).

di as text "  [TBD-codebook] specific cell magnitudes deferred to Phase 1a §3.3"
di as text "                 share/ relocation per design memo §9 open items."

* TODO Phase 1c §5.3 step 12: when share/ producers are relocated, replace
*    the [TBD-codebook] block above with concrete cell-loading + assert
*    blocks for paper Tables 2/3 main coefficients (and any other cells
*    Christina decides are load-bearing for offboarding).


/*==============================================================================
WRAP-UP
==============================================================================*/

di as text _n "{hline 80}"
di as text "check_paper_outputs.do — RUN END: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"

cap log close
cap translate "$logdir/check_paper_outputs.smcl" "$logdir/check_paper_outputs.log", replace

* end of file
