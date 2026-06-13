/*------------------------------------------------------------------------------
do/settings.do — global path configuration for the consolidated VA project
================================================================================

PURPOSE
    Define every path global the pipeline needs.  Hostname-branched per ADR-0002
    (Scribe is the only supported runtime; other hosts default to Scribe paths
    so that running locally fails fast with a clear error rather than silently
    using wrong paths).

INVOKED FROM
    `do/main.do` via `include do/settings.do` (CWD is $consolidated_dir per
    main.do's INVOCATION block).  Standalone diagnostic scripts (e.g.,
    `do/explore/codebook_export.do`) define their own defensive auto-define
    block; this file is the canonical source.

SANDBOX PRINCIPLE (per ADR-0021)
    Path globals split into two classes — see CANONICAL vs LEGACY sections
    below.  CANONICAL paths point inside $consolidated_dir; the pipeline may
    READ and WRITE these freely.  LEGACY paths point outside $consolidated_dir
    (predecessor repos, Matt's files, restricted-access raw data); the
    pipeline READS these but MUST NOT WRITE to them.  This keeps consolidated/
    a self-contained output sandbox, so `diff -r consolidated/output
    predecessor/output` cleanly compares the new pipeline against the old.

CONVENTIONS (per plan v3 §3.4 + §5.1 step 2)
    CANONICAL (read + write):
        $consolidated_dir   — root of the consolidated repo on Scribe
        $logdir             — per-do-file logs (`log using $logdir/<file>.smcl`)
        $datadir            — gitignored data root inside consolidated/
        $datadir_clean      — cleaned-data subdir under $datadir
        $datadir_raw        — raw-data subdir under $datadir
        $estimates_dir      — gitignored estimates root
        $output_dir         — gitignored intermediate output root

    LEGACY (read-only — predecessor or restricted-access locations):
        $matt_files_dir     — Matt Naven's pipeline files (untouched per ADR-0017)
        $vaprojdir          — fork-repo data dir (legacy compat for callers
                              not yet relocated)
        $vaprojxwalks       — crosswalks subdir under $vaprojdir
        $caschls_projdir    — caschls predecessor repo root (legacy: scripts
                              that assume `$projdir` is the caschls dir use
                              $caschls_projdir via a per-script alias)
        $nscdtadir          — Kramer-cleaned NSC raw data
        $nscdtadir_oldformat — pre-2017 NSC oldformat subdir
        $mattxwalks         — Matt's crosswalks (separate from $vaprojxwalks)

REFERENCES
    ADR-0002 (runtime: server only)
    ADR-0007 (code/data separation; Scribe non-git working copy)
    ADR-0017 (Matt Naven's files untouched)
    ADR-0021 (do/ relocation; self-contained sandbox; description convention)
    Plan v3 §3.4 (main.do / settings.do construction)
    Plan v3 §5.1 step 2 (per-do-file logging convention)
------------------------------------------------------------------------------*/


/*==============================================================================
HOST DETECTION
==============================================================================*/

local host = lower("`c(hostname)'")
display as text "settings.do: detected hostname = `c(hostname)'"

* Scribe is the only supported runtime per ADR-0002.  If the detected host
* doesn't match a known Scribe pattern, the script defaults to Scribe paths
* anyway — un-runnable locally, which is the desired failure mode.  If a
* future Scribe-equivalent host is added, branch on its hostname here.

local on_scribe = 0
if regexm("`host'", "scribe") | regexm("`host'", "ssds") {
    local on_scribe = 1
}

if !`on_scribe' {
    di as text ""
    di as text "  NOTE: not running on Scribe (detected '`c(hostname)''). "
    di as text "  Pipeline runtime is Scribe-only per ADR-0002.  Path globals"
    di as text "  below default to Scribe values; expect file-not-found errors"
    di as text "  on non-Scribe hosts.  Edit this file to add a new host branch"
    di as text "  if needed."
    di as text ""
}


/*==============================================================================
CANONICAL PATHS (consolidated repo) — WRITE-allowed per ADR-0021 sandbox
==============================================================================*/

* Root of the consolidated repo on Scribe (file-transfer destination
* per ADR-0007 + ADR-0020; transfer mechanism is operator-choice — FileZilla today).
global consolidated_dir "/home/research/ca_ed_lab/projects/common_core_va/consolidated"

* Subdirectories under $consolidated_dir.  These match the CLAUDE.md folder
* structure and the gitignore exclusions in .gitignore (per ADR-0007).
global datadir          "$consolidated_dir/data"
global estimates_dir    "$consolidated_dir/estimates"
global output_dir       "$consolidated_dir/output"
global logdir           "$consolidated_dir/log"

* Convenience: data subdirs that scripts read most often.
global datadir_clean    "$datadir/cleaned"
global datadir_raw      "$datadir/raw"

* Tables and figures roots for paper-shipping artifacts.  Match the paper
* path conventions in CLAUDE.md folder map (`tables/share/va/pub/`,
* `figures/share/va/v1/`, etc.).  Phase 3+ producer scripts write here;
* paper main.tex `\input{}` reads from `tables/...` and `\includegraphics{}`
* reads from `figures/...`.
global tables_dir       "$consolidated_dir/tables"
global figures_dir      "$consolidated_dir/figures"


/*==============================================================================
LEGACY PATHS — READ-ONLY per ADR-0021 sandbox
    Predecessor / restricted-access locations.  Pipeline scripts may READ
    from these but MUST NOT WRITE.  Any save/export targeting these paths
    breaks the diff-r comparability the sandbox is designed for.
==============================================================================*/

* Matt Naven's pipeline files (per ADR-0017 they stay in their predecessor
* location through Phase 1).  Christina's relocated sample-construction
* scripts call Matt's `merge_k12_postsecondary.doh` via this global.
global matt_files_dir   "/home/research/ca_ed_lab/projects/common_core_va/do_files"

* Legacy: the predecessor fork repo's $vaprojdir.  Used by VA-estimation
* scripts that read pre-existing estimates / .dta caches not yet relocated.
global vaprojdir        "/home/research/ca_ed_lab/projects/common_core_va"
global vaprojxwalks     "$vaprojdir/data/restricted_access/clean/crosswalks"

* Legacy: caschls predecessor repo.  Survey-VA constructor scripts
* (imputedcategoryindex.do, compcasecategoryindex.do, etc.) historically
* used $projdir to mean the caschls dir.  Phase 1 relocates these scripts
* but for any caller that hasn't been relocated yet, $caschls_projdir provides
* the correct path.
global caschls_projdir  "/home/research/ca_ed_lab/users/chesun/gsr/caschls"

* NSC raw data (Kramer-cleaned).  Read by `crosswalk_nsc_outcomes.do`
* (Christina-authored per ADR-0019, but not pipeline-active per Phase 1
* time-budget — kept for reproducibility of the static .dta outputs).
global nscdtadir            "/home/research/ca_ed_lab/data/restricted_access/clean/cde_nsc"
global nscdtadir_oldformat  "$nscdtadir/oldformat"

* Matt's separate crosswalks dir (distinct from $vaprojxwalks).
global mattxwalks       "/home/research/ca_ed_lab/users/msnaven/data/restricted_access/clean/crosswalks"

* Christina-owned k12-to-postsecondary distance data (LEGACY for raw inputs;
* relocated batch 9c writes outputs to $datadir_clean/k12_postsec_distance/clean/<x>).
* Predecessor settings.do (do_files/settings.do:52) bound this to the same path.
global distance_dtadir  "$vaprojdir/data/k12_postsec_distance"

* CalSCHLS restricted-access data dirs (LEGACY-READ-ONLY).  Predecessor caschls
* settings.do binds these to absolute Scribe paths outside both repos.  Used
* for raw-survey reads in batch 9d (renamedata.do, splitstaff0414.do) and
* batch 9e (qoiclean year-by-year files).  Writes from those batches go to
* CANONICAL $datadir_clean/calschls/<x> per ADR-0021 sandbox-write principle.
* $rawdtadir holds .dta-format raw surveys (most years); $rawcsvdir holds
* the pre-2014 .csv-format secondary surveys.  $clndtadir is currently used
* only by qoiclean (batch 9e) for legacy-clean reads — splitstaff0414 was
* repointed to read CHAIN $datadir_clean/calschls/staff/staff0414 (produced
* by renamedata earlier in main.do invocation order; coder-critic round 1
* on commit 677033f flagged the LEGACY-read regression).
global rawdtadir  "/home/research/ca_ed_lab/data/restricted_access/raw/calschls/stata"
global rawcsvdir  "/home/research/ca_ed_lab/data/restricted_access/raw/calschls/csv"
global clndtadir  "/home/research/ca_ed_lab/data/restricted_access/clean/calschls"

* CDE CST (California Standards Tests) cleaned data dir (LEGACY-READ-ONLY).
* Predecessor caschls/do/settings.do:35 binds this to the absolute Scribe
* path.  Used by batch 10c siblingmatch.do (sibling-name-address xwalk
* construction) for raw CST yearly reads ($cstdtadir/cst_<year>).
global cstdtadir  "/home/research/ca_ed_lab/data/restricted_access/clean/cde/cst"


/*==============================================================================
BOOTSTRAP CANONICAL DIRECTORIES

    Stata's `mkdir` does not auto-create parent directories.  Per-script
    `cap mkdir "$datadir_clean/<subdir>"` fails silently when intermediate
    parents (e.g., $datadir) don't yet exist, leading to silent r(603) save
    failures downstream (e.g., 2026-05-17 M4 attempt #2 r(603) in
    clean_acs_census_tract.do:406).

    Idempotent — `cap` suppresses "already exists" errors.  Runs every time
    main.do (or any standalone script that includes settings.do) starts, so
    canonical top-level directories are guaranteed present before any
    downstream per-script `cap mkdir` cascade attempts to create children.
==============================================================================*/

cap mkdir "$consolidated_dir"
cap mkdir "$datadir"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_raw"
cap mkdir "$estimates_dir"
cap mkdir "$output_dir"
cap mkdir "$logdir"
cap mkdir "$tables_dir"
cap mkdir "$figures_dir"


/*==============================================================================
STATA DEFAULTS
==============================================================================*/

set more off
set linesize 120

* Reproducibility: master seed.  Per stata-code-conventions: "set seed once
* in main.do (reproducibility)."  Set here so every entry point gets it.
set seed 20260428


/*==============================================================================
BEHAVIOR / CONFIG TOGGLES (not paths)
==============================================================================*/

* Single source of truth for prior-score-decile heterogeneity.  The PRODUCER
* scripts (reg_out_va_all.do, reg_out_va_dk_all.do) write the
* het_reg_<x>_x_prior_<x>.ster estimates only when this is on; ALL CONSUMERS
* (reg_out_va_all_tab.do, reg_out_va_all_fig.do, reg_out_va_dk_all_tab.do)
* gate their .ster reads on the same global.  Flipping this to 0 disables the
* producer AND the consumers together, so a disabled producer can never leave
* a consumer reading a missing .ster -> r(601).  Gate condition used verbatim
* everywhere: `if "$run_prior_score" != "0"` (unset == on; only explicit 0
* disables).  [2026-05-28]
global run_prior_score 1

* K12-postsec distance input source (ADR-0030).  The distance producer
* (do/data_prep/k12_postsec_distance/k12_postsec_distances.do) historically
* fetched the CDE school directory from a LIVE URL at run time, falling back to
* the cached $distance_dtadir/raw/pubschls.txt only on HTTP error.  Because the
* CDE directory is continuously updated, that made distance-derived outputs
* (mindist_*, and every distance-restricted/-controlled VA sample downstream)
* NON-REPRODUCIBLE: each run silently consumed whatever the directory was that
* day.  The M4 golden-master mismatch on mindist_* (50,766 rows in score_b)
* traced to exactly this drift.  Default 0 = read the pinned cached file, so a
* fresh run reproduces.  Set to 1 ONLY to deliberately rebuild distances from
* the current live directory (a new-data operation, not a replication run).
* Gate condition used verbatim: `if "$refresh_cde_directory" == "1"`
* (unset == pinned; only explicit 1 enables the live fetch).  [2026-06-12]
global refresh_cde_directory 0

* Confirm $consolidated_dir resolves before main.do tries to use it.
capture confirm file "$consolidated_dir"
if _rc {
    di as error ""
    di as error "  ERROR: \$consolidated_dir not found at:"
    di as error "         $consolidated_dir"
    di as error "  Either you're not on Scribe, or the consolidated/ folder"
    di as error "  hasn't been created yet (Phase 1a §3.1 step 1)."
    di as error ""
    exit 601
}

di as text "settings.do: globals defined; \$consolidated_dir = $consolidated_dir"

* end of file
