/*------------------------------------------------------------------------------
do/check/check_logs.do — assert every do file that RAN produced its log file
================================================================================

PURPOSE
    Assert that every `.do` file which actually RAN in the most recent `main.do`
    pipeline run produced its per-file log.  Pairs with the per-do-file logging
    convention (plan v3 §5.1 step 2): every analytical do file opens its own log
    at `$logdir/<reldir>/<name>.smcl` (the log dir mirrors the do/ tree).  A file
    that ran but has no log is a regression (its `log using' is absent/wrong) and
    HALTS the pipeline.  A file that did NOT run this run (its phase toggled off
    in dev iteration) is reported informationally, NOT failed — see SCOPE.

    [2026-06-01 rewrite] Two earlier bugs fixed: (A) the expected log path was
    built from the basename only (`$logdir/<name>.smcl') and never matched the
    reldir-mirrored real log; (B) the check asserted ALL do files have a log,
    failing 111/112 on a dev run where only some phases ran.

SCOPE — which files are asserted
    Only files that RAN this run, detected from the `[RUN] do/<path>.do' markers
    `main.do' writes to the master log before each `do'.  The master log's path is
    obtained via `log query master' (check_logs runs while that log is open, just
    suspended).  main.do + settings.do are EXEMPT (no per-file log by design:
    main opens the master log; settings is `include'd).  If no master log is open
    (check run standalone), the check WARNs and skips rather than failing.

INPUTS
    Filesystem + the open master log.  Reads `do/<reldir>/<name>.do', the master
    log lines, and `$logdir/<reldir>/<name>.smcl'.  No Stata data.
    Requires the `filelist' ssc package (recursive `.do' enumeration).

OUTPUTS
    Per-do-file log: $logdir/check/check_logs.smcl + .log
    On a ran-but-no-log file: pipeline halts (exit 9); partial outputs preserved.

ROLE IN ADR-0021 SANDBOX
    Reads filesystem under $consolidated_dir (CANONICAL).  Writes only to
    $logdir (CANONICAL).  Compliant with sandbox principle.

INVARIANTS (per design memo §7, updated 2026-06-01)
    - Every `.do' that ran this run (per master-log [RUN] markers; excluding
      `do/_archive/<x>', main.do, settings.do) has a matching
      `$logdir/<reldir>/<name>.smcl'.
    - Failure = listing of ran-but-unlogged files + halt (exit 9).

REFERENCES
    Design memo:    quality_reports/reviews/2026-04-28_data-checks-design.md §7
    Plan:           quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §5.1 step 2 + §5.3 step 9
    ADRs:           0018 (acceptance criteria), 0021 (description convention; sandbox role above)
------------------------------------------------------------------------------*/


clear all
set more off
cap log close check_logs
set linesize 120

* Per-do-file log per stata-code-conventions.md.
cap mkdir "$logdir"
cap mkdir "$logdir/check"
log using "$logdir/check/check_logs.smcl", replace text name(check_logs)

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
    cap log close check_logs
    cap translate "$logdir/check/check_logs.smcl" "$logdir/check/check_logs.log", replace
    exit 198
}

* filelist recurses subdirectories BY DEFAULT (its `norecursive' is a flag that
* RESTRICTS to top level; there is no `norecur(0)').  We NEED recursion — 107 .do
* files live under do/va, do/share, do/check, etc. — so omit the option entirely.
* 2026-06-01: removed the invalid `norecur(0)' (option name is `norecursive', flag-only;
* `norecur(0)' -> r(198) "option norecur() incorrectly specified").  Verified syntax
* against filelist.ado (Robert Picard, ssc): `syntax , [... noRecursive MAXdeep(string) ...]'.
quietly filelist, dir("$consolidated_dir/do") pattern("*.do")

* Drop archive (per ADR-0021: convention applies to do/ excluding do/_archive/).
quietly drop if regexm(dirname, "/_archive($|/)")

* Drop anything not a .do file (filelist's pattern is glob, but be defensive).
quietly keep if regexm(filename, "\.do$")

count
if r(N) == 0 {
    di as error "  ERROR: no .do files found under $consolidated_dir/do — pipeline state surprising."
    cap log close check_logs
    cap translate "$logdir/check/check_logs.smcl" "$logdir/check/check_logs.log", replace
    exit 459
}

local n_enumerated = r(N)
di as text "  enumerated `n_enumerated' do files under $consolidated_dir/do (excluding _archive/; incl. main.do + settings.do, dropped below)"


/*==============================================================================
ASSERT EVERY DO FILE THAT RAN HAS A LOG
==============================================================================

    2026-06-01 rewrite (two bugs fixed + scope correction):

    BUG A (path): logs mirror the do/ tree — a file at do/<reldir>/<name>.do logs
      to $logdir/<reldir>/<name>.smcl (stata-code-conventions.md, Per-file logging).
      The old check built the expected path from `filename' (basename only), so it
      looked for $logdir/<name>.smcl and never found the nested log -> every subdir
      file falsely "missing".  Fixed: expected path = $logdir/<reldir>/<name>.smcl,
      where <reldir> = dirname minus the "$consolidated_dir/do" prefix.

    BUG B (scope): the old check asserted ALL do files have a log.  But main.do
      runs only the toggled-ON phases (dev iteration), so files from skipped phases
      legitimately have no log -> 111/112 false failures on a Phase-6/7-only run.
      Fixed: only assert a log for files that ACTUALLY RAN this run, detected via
      the [RUN] markers main.do writes to the master log for every do it executes.
      Files not in the [RUN] set are reported as "not run this run" (informational).

    EXEMPT: main.do + settings.do never produce a per-file log (main opens the
      master log; settings is include'd) — excluded from the assertion.
==============================================================================*/

* reldir = dirname with the leading "$consolidated_dir/do" stripped ("" at top level,
* "/share", "/va/heterogeneity", ... in subdirs).  Expected log mirrors it.
quietly gen str244 reldir  = subinstr(dirname, "$consolidated_dir/do", "", 1)
quietly gen str244 stem    = substr(filename, 1, length(filename) - 3)
quietly gen str244 logfile = "$logdir" + reldir + "/" + stem + ".smcl"

* Exempt main.do + settings.do (no per-file log by design).
quietly drop if inlist(filename, "main.do", "settings.do")
quietly count
local n_dofiles = r(N)

* Determine which do files RAN this run, from the master log's [RUN] markers.
* main.do writes `  [RUN] do/<reldir>/<name>.do' immediately before each `do'.
* check_logs runs WHILE main.do's master log is open (suspended via `log off master'),
* so ask Stata for that log's exact path directly — robust vs. guessing the filename.
quietly gen byte ran_this_run = 0
local masterlog ""
capture log query master
if !_rc local masterlog "`r(filename)'"
* Build the set of [RUN] do-paths from that master log (each do file = one token).
* relpath of each enumerated file = "do" + reldir + "/" + filename.
quietly gen str244 relpath = "do" + reldir + "/" + filename
if "`masterlog'" != "" {
    * Read the master log line by line; on each "[RUN] <path>" marker, flag the
    * matching enumerated file immediately.  `macval()' shields each line's contents
    * (echoed Stata code may carry backticks/quotes) from re-evaluation.  We mark the
    * flag INSIDE the loop (a single-token, marker-derived path) rather than
    * accumulating tokens into a macro and re-iterating with `foreach of local' —
    * that re-parses the macro and raises r132 "too few quotes" on any odd quote.
    tempname fh
    file open `fh' using "`masterlog'", read text
    file read `fh' line
    while r(eof)==0 {
        * Match a genuine marker: "[RUN] <do-path>" where the path runs to a closing
        * double-quote or end-of-line.  Anchoring the terminator (regex below) rejects
        * non-marker lines that merely MENTION "[RUN] do/..." in prose / a di / leaked
        * sub-do output — a bare strpos("[RUN] do/") would false-flag those as "ran"
        * and halt a clean pipeline (r(9)).  The master log holds the SMCL echo of the
        * di command, so the path is followed by a closing `"'.  `macval()' shields the
        * line's contents (echoed code may carry backticks/quotes/$macros) -> no r132.
        if regexm(`"`macval(line)'"', `"\[RUN\] (do/[^ "]+\.do)("|$)"') {
            local p = regexs(1)
            quietly replace ran_this_run = 1 if relpath == "`p'"
        }
        file read `fh' line
    }
    file close `fh'
}
quietly count if ran_this_run==1
local n_ran = r(N)
di as text "  of `n_dofiles' do files, `n_ran' ran this run (per master-log [RUN] markers)"

* Check log existence for the files that ran.
quietly gen byte log_exists = 0
forvalues i = 1/`n_dofiles' {
    local lf = logfile[`i']
    capture confirm file "`lf'"
    if !_rc quietly replace log_exists = 1 in `i'
}

quietly count if ran_this_run==1 & log_exists==0
local n_missing = r(N)

if `n_missing' > 0 {
    di as error _n "  FAIL: `n_missing' do file(s) RAN this run but have no matching log under \$logdir/<reldir>/."
    di as error "  Missing logs (ran but no log):"
    list dirname filename if ran_this_run==1 & log_exists==0, clean noobs
    cap log close check_logs
    cap translate "$logdir/check/check_logs.smcl" "$logdir/check/check_logs.log", replace
    * Halt the pipeline — assertion failure semantics per design memo §8.
    exit 9
}

if "`masterlog'" == "" {
    di as error "  WARN: no master log found under $logdir — could not scope to files that ran; check skipped (not failed)."
}
else {
    di as text "  PASS: every do file that ran this run has a matching log."
}

/*==============================================================================
WRAP-UP
==============================================================================*/

di as text _n "{hline 80}"
di as text "check_logs.do — RUN END: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"

cap log close check_logs
cap translate "$logdir/check/check_logs.smcl" "$logdir/check/check_logs.log", replace

* end of file
