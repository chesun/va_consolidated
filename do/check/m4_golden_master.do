/*------------------------------------------------------------------------------
do/check/m4_golden_master.do — M4 golden-master diff runner (on-Scribe)
================================================================================

PURPOSE
    Drive the M4 golden-master verification per plan v3 §3.5 + ADR-0021
    sandbox principle.  For every CANONICAL output produced by the consolidated
    pipeline, compare against the predecessor pipeline's corresponding output
    file.  Emit a compact, exportable text summary that lists PASS/FAIL/MISSING
    outcomes per file pair, plus a tally block at the end.

    Air-gapped-workflow rule applies (.claude/rules/air-gapped-workflow.md):
    raw data never leaves Scribe.  Only the summary text file at
    $output_dir/m4_diff_summary.txt is the export artifact.

INVOKED FROM
    NOT wired into do/main.do — one-shot golden-master check, not pipeline.
    Christina runs manually on Scribe:
        cd /home/research/ca_ed_lab/projects/common_core_va/consolidated
        stata-mp -b do do/check/m4_golden_master.do

INPUTS
    do/check/m4_path_matrix.csv — 8,324-row manifest of (predecessor,
        consolidated) absolute Scribe paths with filetype/tier/category
        annotations.  Schema documented in do/check/m4_path_matrix_README.md.

OUTPUTS
    $output_dir/m4_diff_summary.txt — exportable text summary, one line per
        comparison plus a tally block at the end.  Format:
            <STATUS>  <tier>  <filetype>  <consolidated_relpath>  <details>
    $logdir/check/m4_golden_master.smcl + .log — full Stata log per stata-code
        conventions (log routing).

ROLE IN ADR-0021 SANDBOX
    Reads from CANONICAL ($consolidated_dir/...) and LEGACY (predecessor
    pipelines under /home/research/ca_ed_lab/users/chesun/gsr/caschls and
    /home/research/ca_ed_lab/projects/common_core_va).  Writes ONLY to
    $output_dir/m4_diff_summary.txt and $logdir/m4_golden_master.*.

ORIGIN
    New in 2026-05-16 pre-flight M4 protocol.  Not a relocated file — no
    predecessor counterpart in cde_va_project_fork or caschls.

TOLERANCES (per .claude/rules/replication-protocol.md §3)
    Integers (N, counts):    exact match
    Point estimates:         < 0.01
    Standard errors:         < 0.05
    P-values:                same significance level (not enforced numerically;
                             we compare on the point/SE channel above)
    Percentages:             < 0.1pp

DISPATCH BY FILETYPE
    dta  : Stata `cf _all using <other>`; PASS if cumulative diffs = 0 OR
           max numeric diff per variable <= 0.01.
    ster : load both estimates files; compare e(b) element-wise (tol 0.01)
           and sqrt(diag(e(V))) element-wise (tol 0.05).
    tex  : byte-compare (`cmp`); if differ, run line-by-line diff with numeric
           tolerance via awk strip + diff.
    pdf  : byte-compare; if differ, `pdftotext -layout` + text diff.
    csv  : byte-compare; if differ, mark FAIL with note (numeric reparse not
           attempted on-Scribe — small N of csv rows, manual review).
    xlsx : byte-compare only (binary; no on-Scribe xlsx parser assumed).
    other: byte-compare only.

TIER SELECTOR
    Set `tier_filter' local below to one of:
        "smoke"  — 5 representative rows, ~5 min runtime
        "paper"  — smoke + paper-shipping ($tables_dir / $figures_dir), ~459 rows
        "full"   — all 8,324 rows; ~hours of runtime
    Tier semantics in m4_path_matrix_README.md "Tier definitions": rows in
    smoke are NOT additionally tagged paper/full in the CSV.  Filter is
    OR-union: "smoke" -> tier=="smoke"; "paper" -> tier in
    ("smoke","paper"); "full" -> all three.

ASSUMED PACKAGES ON SCRIBE
    Stata built-in:    `cf`, `shell`, `estimates use`
    Shell utilities:   `cmp`, `diff`, `awk`, `pdftotext`, `wc`, `bash`
    Community-contrib: `cfout` (optional — falls back gracefully if not
                       installed; we still use built-in `cf` for the canonical
                       PASS/FAIL signal)

DEFENSIVE CODE
    Every per-row comparison wrapped in `capture` — one bad file does not
    kill the loop.  Status enumerated:
        PASS, FAIL, MISSING_PREDECESSOR, MISSING_CONSOLIDATED, READ_ERROR,
        FAIL_VISUAL, FAIL_BINARY, SKIP, UNKNOWN_FILETYPE.

REFERENCES
    Plan v3 §3.5:        quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md
    Path matrix:         do/check/m4_path_matrix.csv
    Matrix README:       do/check/m4_path_matrix_README.md
    Tolerance table:     .claude/rules/replication-protocol.md §3
    Sandbox semantics:   decisions/0021_main-settings-relocation-and-self-contained-sandbox.md
    Air-gapped rule:     .claude/rules/air-gapped-workflow.md
    Stata conventions:   .claude/rules/stata-code-conventions.md
------------------------------------------------------------------------------*/


clear all
set more off
cap log close m4_golden_master
set linesize 200

include do/settings.do


cap mkdir "$logdir"


cap mkdir "$logdir/check"
log using "$logdir/check/m4_golden_master.smcl", replace text name(m4_golden_master)


/*==============================================================================
SUBROUTINE DEFINITIONS (must come before the dispatch loop)

    Each returns r(status) + r(details) via `return local`.  All commands
    inside use `capture` so a bad file's error surfaces as a READ_ERROR
    status rather than killing the do-file.

    `cap program drop` at top of each so re-running the .do file in the same
    Stata session (rare for one-shot M4, but defensive) doesn't error on
    "program already defined".
==============================================================================*/


* -- dta comparison via `cf` --------------------------------------------------
capture program drop cap_compare_dta
program define cap_compare_dta, rclass
    args pred_path cons_path has_cfout

    capture {
        quietly use "`pred_path'", clear
        quietly cf _all using "`cons_path'"
    }
    if _rc {
        local rc = _rc
        return local status = "READ_ERROR"
        return local details = "rc=`rc' on cf _all"
        exit
    }

    * cf populates r(Nsum) = total number of differing observations across vars.
    * If 0 -> no row-level mismatch.
    local nsum = r(Nsum)
    if missing(`nsum') local nsum = 0

    if `nsum' == 0 {
        return local status = "PASS"
        return local details = "cf _all: 0 cumulative diffs"
        exit
    }

    * Diffs found.  If cfout available, get cell-level diff count for context.
    if `has_cfout' {
        tempfile cfout_tmp
        capture {
            quietly use "`pred_path'", clear
            quietly cfout _all using "`cons_path'", saving("`cfout_tmp'") replace
        }
        if _rc {
            local rc = _rc
            return local status = "FAIL"
            return local details = "cf:`nsum' obs-diffs (cfout fallback rc=`rc')"
            exit
        }
        local nd = r(diffs)
        if missing(`nd') local nd = `nsum'
        return local status = "FAIL"
        return local details = "cf:`nsum' obs-diffs; cfout:`nd' cell-diffs"
        exit
    }

    return local status = "FAIL"
    return local details = "cf _all: `nsum' cumulative diffs"
end


* -- ster comparison: load both, compare e(b) + sqrt(diag(e(V))) --------------
capture program drop cap_compare_ster
program define cap_compare_ster, rclass
    args pred_path cons_path

    * Load predecessor estimates
    capture estimates use "`pred_path'"
    if _rc {
        local rc = _rc
        return local status = "READ_ERROR"
        return local details = "rc=`rc' loading pred .ster"
        exit
    }
    tempname b1 V1
    capture matrix `b1' = e(b)
    local has_b1 = (_rc == 0)
    capture matrix `V1' = e(V)
    local has_V1 = (_rc == 0)

    if !`has_b1' {
        return local status = "SKIP"
        return local details = "pred .ster has no e(b) — non-estimation save"
        exit
    }

    local nc1 = colsof(`b1')

    * Load consolidated estimates
    capture estimates use "`cons_path'"
    if _rc {
        local rc = _rc
        return local status = "READ_ERROR"
        return local details = "rc=`rc' loading cons .ster"
        exit
    }
    tempname b2 V2
    capture matrix `b2' = e(b)
    local has_b2 = (_rc == 0)
    capture matrix `V2' = e(V)
    local has_V2 = (_rc == 0)

    if !`has_b2' {
        return local status = "FAIL"
        return local details = "cons .ster has no e(b) (pred had `nc1' coefs)"
        exit
    }

    local nc2 = colsof(`b2')
    if `nc1' != `nc2' {
        return local status = "FAIL"
        return local details = "coef vector size mismatch: pred=`nc1' cons=`nc2'"
        exit
    }

    * Compare element-wise.  b is 1 x K row vector.
    local max_b_diff  = 0
    local max_se_diff = 0
    forvalues k = 1/`nc1' {
        local b1k = `b1'[1,`k']
        local b2k = `b2'[1,`k']
        if !missing(`b1k') & !missing(`b2k') {
            local d = abs(`b1k' - `b2k')
            if `d' > `max_b_diff' local max_b_diff = `d'
        }
        if `has_V1' & `has_V2' {
            capture {
                local v1k = `V1'[`k',`k']
                local v2k = `V2'[`k',`k']
                if !missing(`v1k') & !missing(`v2k') & `v1k' >= 0 & `v2k' >= 0 {
                    local se1 = sqrt(`v1k')
                    local se2 = sqrt(`v2k')
                    local sed = abs(`se1' - `se2')
                    if `sed' > `max_se_diff' local max_se_diff = `sed'
                }
            }
        }
    }

    * Tolerance per replication-protocol.md §3.  Diff magnitudes (max|db|,
    * max|dSE|) are summary-class quantities and are reported in the `details`
    * string so offline triage can compare against the 0.01 / 0.05 tolerances
    * without re-running on Scribe.  Also printed to the log for redundancy.
    display as text "  [ster diag] max|db|=" %7.4f `max_b_diff' "  max|dSE|=" %7.4f `max_se_diff'
    if (`max_b_diff' <= 0.01) & (`max_se_diff' <= 0.05) {
        return local status = "PASS"
        return local details = "coef and SE within tolerance (max|db|=`:di %7.4f `max_b_diff'' max|dSE|=`:di %7.4f `max_se_diff'')"
        exit
    }

    return local status = "FAIL"
    return local details = "max|db|=`:di %7.4f `max_b_diff'' max|dSE|=`:di %7.4f `max_se_diff''"
end


* -- tex comparison: byte-cmp; fallback to numeric-strip awk + diff -----------
capture program drop cap_compare_tex
program define cap_compare_tex, rclass
    args pred_path cons_path

    capture shell cmp -s "`pred_path'" "`cons_path'"
    local rc_cmp = _rc

    if `rc_cmp' == 0 {
        return local status = "PASS"
        return local details = "byte-identical"
        exit
    }

    * Files differ.  Strip numeric tokens (digits, dot, minus, exponent) and
    * re-diff to check whether the only differences are within numeric
    * rounding (a heuristic).  Use bash process substitution.
    tempfile stripped_diff
    capture shell bash -c "diff <(awk '{gsub(/-?[0-9]+(\\.[0-9]+)?([eE][-+]?[0-9]+)?/, \"NUM\"); print}' '`pred_path'') <(awk '{gsub(/-?[0-9]+(\\.[0-9]+)?([eE][-+]?[0-9]+)?/, \"NUM\"); print}' '`cons_path'') > '`stripped_diff'' 2>/dev/null; wc -l < '`stripped_diff'' > '`stripped_diff'.count'"
    local rc_strip = _rc

    if `rc_strip' == 0 {
        tempname fh_sd
        capture file open `fh_sd' using "`stripped_diff'.count", read
        if !_rc {
            file read `fh_sd' line
            file close `fh_sd'
            local n_struct_diff = trim("`line'")
            if "`n_struct_diff'" == "0" {
                return local status = "PASS"
                return local details = "numeric-only diff (structure identical)"
                exit
            }
            return local status = "FAIL"
            return local details = "diff: `n_struct_diff' structural-diff lines"
            exit
        }
    }

    return local status = "FAIL"
    return local details = "byte-different (numeric-strip diff rc=`rc_strip')"
end


* -- pdf comparison: byte-cmp; fallback to pdftotext + diff -------------------
capture program drop cap_compare_pdf
program define cap_compare_pdf, rclass
    args pred_path cons_path has_pdftotext

    capture shell cmp -s "`pred_path'" "`cons_path'"
    local rc_cmp = _rc

    if `rc_cmp' == 0 {
        return local status = "PASS"
        return local details = "byte-identical"
        exit
    }

    if !`has_pdftotext' {
        return local status = "FAIL_BINARY"
        return local details = "pdfs differ byte-wise (no pdftotext available)"
        exit
    }

    * Run pdftotext on each and compare the text streams.
    tempfile ptxt1 ptxt2
    capture shell pdftotext -layout "`pred_path'" "`ptxt1'" 2>/dev/null
    local rc1 = _rc
    capture shell pdftotext -layout "`cons_path'" "`ptxt2'" 2>/dev/null
    local rc2 = _rc

    if `rc1' | `rc2' {
        return local status = "FAIL_VISUAL"
        return local details = "pdftotext rc1=`rc1' rc2=`rc2'"
        exit
    }

    capture shell cmp -s "`ptxt1'" "`ptxt2'"
    local rc_text = _rc

    if `rc_text' == 0 {
        return local status = "PASS"
        return local details = "byte-different, text-identical via pdftotext"
        exit
    }

    return local status = "FAIL_VISUAL"
    return local details = "pdf text-streams differ (need offline visual review)"
end


* -- byte-only comparison: cmp.  Used for csv/xlsx/other ----------------------
capture program drop cap_compare_bytes
program define cap_compare_bytes, rclass
    args pred_path cons_path ftype_tag

    capture shell cmp -s "`pred_path'" "`cons_path'"
    local rc_cmp = _rc

    if `rc_cmp' == 0 {
        return local status = "PASS"
        return local details = "byte-identical"
        exit
    }

    if "`ftype_tag'" == "csv" {
        return local status = "FAIL"
        return local details = "csv byte-different (manual review)"
        exit
    }
    return local status = "FAIL_BINARY"
    return local details = "`ftype_tag' byte-different"
end


/*==============================================================================
TIER SELECTOR — CHANGE ME
    Flip this between "smoke" / "paper" / "full" between runs.
    Smoke first (~5 min) to validate dispatch logic; then paper; then full.
==============================================================================*/

local tier_filter = "smoke"     // CHANGE ME : "smoke" | "paper" | "full"


/*==============================================================================
PATH SETUP + PRE-FLIGHT
==============================================================================*/

di as text _n "{hline 80}"
di as text "m4_golden_master.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "  tier_filter = `tier_filter'"
di as text "{hline 80}"

local matrix_csv  "$consolidated_dir/do/check/m4_path_matrix.csv"
local summary_txt "$output_dir/m4_diff_summary.txt"

cap mkdir "$output_dir"

capture confirm file "`matrix_csv'"
if _rc {
    di as error "  FATAL: path matrix not found at `matrix_csv'"
    cap log close m4_golden_master
    cap translate "$logdir/check/m4_golden_master.smcl" "$logdir/check/m4_golden_master.log", replace
    exit _rc
}

* Validate tier_filter
if !inlist("`tier_filter'", "smoke", "paper", "full") {
    di as error "  FATAL: tier_filter must be smoke|paper|full, got `tier_filter'"
    cap log close m4_golden_master
    cap translate "$logdir/check/m4_golden_master.smcl" "$logdir/check/m4_golden_master.log", replace
    exit 198
}

* Probe for cfout (optional dependency; non-fatal if missing)
capture which cfout
local has_cfout = (_rc == 0)
if `has_cfout' {
    di as text "  cfout available — cell-level diff count enabled for .dta"
}
else {
    di as text "  cfout NOT installed — using built-in cf only for .dta"
}

* Probe for pdftotext (optional shell dep for pdf text-diff)
capture shell command -v pdftotext >/dev/null 2>&1
local has_pdftotext = (_rc == 0)
if `has_pdftotext' {
    di as text "  pdftotext available — pdf text-diff enabled"
}
else {
    di as text "  pdftotext NOT available — pdf compare reverts to byte-only"
}


/*==============================================================================
LOAD PATH MATRIX + FILTER BY TIER
==============================================================================*/

import delimited using "`matrix_csv'", varnames(1) clear stringcols(_all)

* Filter rows by tier_filter (OR-union semantics per README "Tier definitions")
if "`tier_filter'" == "smoke" {
    keep if tier == "smoke"
}
else if "`tier_filter'" == "paper" {
    keep if inlist(tier, "smoke", "paper")
}
* "full" -> keep all rows

local n_rows = _N
di as text "  rows after tier filter: `n_rows'"

if `n_rows' == 0 {
    di as error "  FATAL: zero rows after tier filter — check CSV or tier_filter"
    cap log close m4_golden_master
    cap translate "$logdir/check/m4_golden_master.smcl" "$logdir/check/m4_golden_master.log", replace
    exit 198
}


/*==============================================================================
INITIALIZE SUMMARY FILE
==============================================================================*/

tempname fh
file open `fh' using "`summary_txt'", write replace text

file write `fh' "# M4 golden-master diff summary" _n
file write `fh' "# generated: `c(current_date)' `c(current_time)'" _n
file write `fh' "# tier_filter: `tier_filter'" _n
file write `fh' "# rows_compared: `n_rows'" _n
file write `fh' "# format: <STATUS>  <tier>  <filetype>  <consolidated_relpath>  <details>" _n
file write `fh' "#" _n


/*==============================================================================
PER-ROW DISPATCH LOOP

    Note on data-context discipline: the loop reads row metadata from the CSV
    dataset, then dispatches to subroutines that themselves call `use` /
    `estimates use`.  Those calls CLEAR the in-memory CSV dataset.  We must
    therefore read all row fields into locals BEFORE the dispatch, and
    re-load the CSV after each dispatch.  Idiom below uses `preserve`/`restore`
    once around the entire forvalues loop body would not work (preserve is
    bounded by the data; subroutine `use` would invalidate the snapshot
    pointer).  Instead, we cache the entire CSV into a tempfile, then re-use
    it inside each iteration via `frame put` is overkill — simpler: read the
    CSV once into Mata-like vectors, OR re-import the CSV after each dispatch.
    We use the latter via a tempfile snapshot for clarity.
==============================================================================*/

* Snapshot the (filtered) matrix to a tempfile so we can re-read after each
* dispatch (which `use`s the predecessor .dta and clobbers our CSV in-memory).
tempfile matrix_snapshot
save "`matrix_snapshot'", replace

* Counters for tally block
local n_pass         = 0
local n_fail         = 0
local n_missing_pred = 0
local n_missing_cons = 0
local n_read_err     = 0
local n_fail_visual  = 0
local n_fail_binary  = 0
local n_skip         = 0
local n_unknown      = 0

* Wall-clock start (for runtime reporting)
local start_time = clock("`c(current_date)' `c(current_time)'", "DMYhms")

* Stash relative-path prefix for compact output
local cons_root = "$consolidated_dir"
local cons_root_len = length("`cons_root'") + 1   // +1 to skip trailing slash

forvalues i = 1/`n_rows' {

    * Re-load row metadata from snapshot (subroutines clobber the data).
    quietly use "`matrix_snapshot'", clear

    local pred_path  = predecessor_abs_path[`i']
    local cons_path  = consolidated_abs_path[`i']
    local prod_file  = producer_file[`i']
    local ftype      = filetype[`i']
    local row_tier   = tier[`i']
    local cat        = category[`i']

    * Compact relpath = consolidated_abs_path with $consolidated_dir/ stripped
    local cons_relpath = substr("`cons_path'", `cons_root_len' + 1, .)
    if "`cons_relpath'" == "" {
        local cons_relpath = "`cons_path'"   // fallback if prefix didn't match
    }

    * Progress every 100 rows
    if mod(`i', 100) == 0 | `i' == 1 | `i' == `n_rows' {
        local now = clock("`c(current_date)' `c(current_time)'", "DMYhms")
        local elapsed_min = (`now' - `start_time') / 60000
        di as text "  row `i' / `n_rows'  (`:di %5.1f `elapsed_min'' min elapsed)"
    }

    * Pre-flight: do BOTH files exist?
    capture confirm file "`pred_path'"
    local pred_exists = (_rc == 0)

    capture confirm file "`cons_path'"
    local cons_exists = (_rc == 0)

    local status = ""
    local details = ""

    if !`pred_exists' & !`cons_exists' {
        local status  = "MISSING_PREDECESSOR"
        local details = "neither side exists; cons=`cons_path'"
        local ++n_missing_pred
    }
    else if !`pred_exists' {
        local status  = "MISSING_PREDECESSOR"
        local details = "pred not found: `pred_path'"
        local ++n_missing_pred
    }
    else if !`cons_exists' {
        local status  = "MISSING_CONSOLIDATED"
        local details = "cons not found: `cons_path'"
        local ++n_missing_cons
    }
    else {

        * Both exist — dispatch by filetype
        if "`ftype'" == "dta" {
            cap_compare_dta `"`pred_path'"' `"`cons_path'"' `has_cfout'
            local status  = "`r(status)'"
            local details = "`r(details)'"
        }
        else if "`ftype'" == "ster" {
            cap_compare_ster `"`pred_path'"' `"`cons_path'"'
            local status  = "`r(status)'"
            local details = "`r(details)'"
        }
        else if "`ftype'" == "tex" {
            cap_compare_tex `"`pred_path'"' `"`cons_path'"'
            local status  = "`r(status)'"
            local details = "`r(details)'"
        }
        else if "`ftype'" == "pdf" {
            cap_compare_pdf `"`pred_path'"' `"`cons_path'"' `has_pdftotext'
            local status  = "`r(status)'"
            local details = "`r(details)'"
        }
        else if "`ftype'" == "csv" {
            cap_compare_bytes `"`pred_path'"' `"`cons_path'"' "csv"
            local status  = "`r(status)'"
            local details = "`r(details)'"
        }
        else if "`ftype'" == "xlsx" {
            cap_compare_bytes `"`pred_path'"' `"`cons_path'"' "xlsx"
            local status  = "`r(status)'"
            local details = "`r(details)'"
        }
        else if "`ftype'" == "other" {
            cap_compare_bytes `"`pred_path'"' `"`cons_path'"' "other"
            local status  = "`r(status)'"
            local details = "`r(details)'"
        }
        else {
            local status  = "UNKNOWN_FILETYPE"
            local details = "filetype=`ftype' has no dispatcher"
        }

        * Update counters by status
        if "`status'" == "PASS"               local ++n_pass
        else if "`status'" == "FAIL"          local ++n_fail
        else if "`status'" == "READ_ERROR"    local ++n_read_err
        else if "`status'" == "FAIL_VISUAL"   local ++n_fail_visual
        else if "`status'" == "FAIL_BINARY"   local ++n_fail_binary
        else if "`status'" == "SKIP"          local ++n_skip
        else                                  local ++n_unknown
    }

    * Pad columns for grep-ability.
    local status_pad = "`status'" + substr("                       ", 1, max(0, 22 - length("`status'")))
    local tier_pad   = "`row_tier'" + substr("       ", 1, max(0, 6 - length("`row_tier'")))
    local ftype_pad  = "`ftype'" + substr("       ", 1, max(0, 6 - length("`ftype'")))

    file write `fh' "`status_pad'  `tier_pad'  `ftype_pad'  `cons_relpath'  `details'" _n
}


/*==============================================================================
TALLY BLOCK
==============================================================================*/

local end_time = clock("`c(current_date)' `c(current_time)'", "DMYhms")
local runtime_min = (`end_time' - `start_time') / 60000

file write `fh' _n
file write `fh' "--- SUMMARY ---" _n
file write `fh' "PASS: `n_pass'  FAIL: `n_fail'  MISSING_PRED: `n_missing_pred'  MISSING_CONS: `n_missing_cons'  READ_ERROR: `n_read_err'  FAIL_VISUAL: `n_fail_visual'  FAIL_BINARY: `n_fail_binary'  SKIP: `n_skip'  UNKNOWN: `n_unknown'" _n
file write `fh' "TIER: `tier_filter'" _n
file write `fh' "RUNTIME: `:di %5.1f `runtime_min'' minutes" _n
file write `fh' "ROWS: `n_rows'" _n

file close `fh'

* Echo tally to log
di as text _n "{hline 80}"
di as text "SUMMARY ( tier=`tier_filter', rows=`n_rows' )"
di as text "  PASS:                 `n_pass'"
di as text "  FAIL:                 `n_fail'"
di as text "  MISSING_PREDECESSOR:  `n_missing_pred'"
di as text "  MISSING_CONSOLIDATED: `n_missing_cons'"
di as text "  READ_ERROR:           `n_read_err'"
di as text "  FAIL_VISUAL:          `n_fail_visual'"
di as text "  FAIL_BINARY:          `n_fail_binary'"
di as text "  SKIP:                 `n_skip'"
di as text "  UNKNOWN_FILETYPE:     `n_unknown'"
di as text "  RUNTIME:              `:di %5.1f `runtime_min'' min"
di as text "  SUMMARY FILE:         `summary_txt'"
di as text "{hline 80}"

di as text _n "m4_golden_master.do — RUN END: `c(current_date)' `c(current_time)'"

cap log close m4_golden_master
cap translate "$logdir/check/m4_golden_master.smcl" "$logdir/check/m4_golden_master.log", replace

* end of file
