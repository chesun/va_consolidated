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


/*==============================================================================
STATA DEFAULTS
==============================================================================*/

set more off
set linesize 120

* Reproducibility: master seed.  Per stata-code-conventions: "set seed once
* in main.do (reproducibility)."  Set here so every entry point gets it.
set seed 20260428

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
