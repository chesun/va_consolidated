/*------------------------------------------------------------------------------
do/check/check_logs.do — assert every relocated do file produced a log file
================================================================================

PURPOSE
    Walk the `do/` tree and assert that every `.do` file (excluding `do/_archive/`)
    has a matching log under `$logdir/<stem>.smcl`.  Pairs with the per-do-file
    logging convention (plan v3 §5.1 step 2): every analytical do file opens
    its own log; missing logs indicate either (a) the file was invoked but its
    `log using` line is absent / wrong, or (b) the file was not invoked at all
    on the most recent `main.do` run.  Either case is a regression worth
    halting the pipeline for.

INPUTS
    Filesystem only.  Reads `do/**/*.do` and `$logdir/*.smcl`.  No Stata data.
    Requires the `filelist` ssc package (used to enumerate `.do` files
    recursively across the do/ tree).

OUTPUTS
    Per-do-file log: $logdir/check_logs.smcl + .log
    On `assert` failure: pipeline halts; partial outputs preserved.

ROLE IN ADR-0021 SANDBOX
    Reads filesystem under $consolidated_dir (CANONICAL).  Writes only to
    $logdir (CANONICAL).  Compliant with sandbox principle.

INVARIANTS (per design memo §7)
    - Every `do/**/*.do` (excluding `do/_archive/**`) has a matching
      `$logdir/<basename-without-extension>.smcl`.
    - Failure = listing of missing logs + halt.

REFERENCES
    Design memo:    quality_reports/reviews/2026-04-28_data-checks-design.md §7
    Plan:           quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §5.1 step 2 + §5.3 step 9
    ADRs:           0018 (acceptance criteria), 0021 (description convention; sandbox role above)
------------------------------------------------------------------------------*/


clear all
set more off
cap log close _all
set linesize 120

* Per-do-file log per stata-code-conventions.md.
cap mkdir "$logdir"
log using "$logdir/check_logs.smcl", replace text

di as text _n "{hline 80}"
di as text "check_logs.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


/*==============================================================================
ENUMERATE EXPECTED LOGS
==============================================================================*/

* `filelist` (from ssc) walks a directory recursively and writes a dataset of
* file paths.  ssc install filelist (one-time) — listed alongside the other
* required ssc packages in stata-code-conventions.md.
*
* TODO Phase 1c §5.4 acceptance run: confirm `filelist` is installed on Scribe
*    or vendored under `ado/`.  If not, `ssc install filelist` once before the
*    acceptance run.

capture which filelist
if _rc {
    di as error "  ERROR: filelist (ssc) is required.  Run: ssc install filelist"
    cap log close
    cap translate "$logdir/check_logs.smcl" "$logdir/check_logs.log", replace
    exit 198
}

quietly filelist, dir("$consolidated_dir/do") pattern("*.do") norecur(0)

* Drop archive (per ADR-0021: convention applies to do/ excluding do/_archive/).
quietly drop if regexm(dirname, "/_archive($|/)")

* Drop anything not a .do file (filelist's pattern is glob, but be defensive).
quietly keep if regexm(filename, "\.do$")

count
if r(N) == 0 {
    di as error "  ERROR: no .do files found under $consolidated_dir/do — pipeline state surprising."
    cap log close
    cap translate "$logdir/check_logs.smcl" "$logdir/check_logs.log", replace
    exit 459
}

local n_dofiles = r(N)
di as text "  enumerated `n_dofiles' do files under $consolidated_dir/do (excluding _archive/)"


/*==============================================================================
ASSERT EVERY DO FILE HAS A LOG
==============================================================================*/

* Build expected log basename for each do file.
quietly gen str240 stem    = substr(filename, 1, length(filename) - 3)
quietly gen str240 logfile = "$logdir/" + stem + ".smcl"

* Check existence of each.
quietly gen byte log_exists = 0
forvalues i = 1/`n_dofiles' {
    local lf = logfile[`i']
    capture confirm file "`lf'"
    if !_rc {
        quietly replace log_exists = 1 in `i'
    }
}

quietly count if log_exists == 0
local n_missing = r(N)

if `n_missing' > 0 {
    di as error _n "  FAIL: `n_missing' do file(s) under do/ have no matching log under \$logdir."
    di as error "  Missing logs:"
    list dirname filename if log_exists == 0, clean noobs
    cap log close
    cap translate "$logdir/check_logs.smcl" "$logdir/check_logs.log", replace
    * Halt the pipeline — assertion failure semantics per design memo §8.
    exit 9
}

di as text "  PASS: every do file under do/ has a matching log."

/*==============================================================================
WRAP-UP
==============================================================================*/

di as text _n "{hline 80}"
di as text "check_logs.do — RUN END: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"

cap log close
cap translate "$logdir/check_logs.smcl" "$logdir/check_logs.log", replace

* end of file
