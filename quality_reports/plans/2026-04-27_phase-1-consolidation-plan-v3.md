<!-- primary-source-ok: sun_2026 -->
(Note: "C. Sun 2026-04-25" in §4.2 below refers to Christina Sun, project author, not an external citation.)

# Phase 1 Consolidation Plan v3

**Status:** DRAFT — §8 questions all resolved 2026-04-27; ready for Christina to mark APPROVED and start Phase 1a §3.1.
**Date:** 2026-04-27
**Supersedes:** `2026-04-25_consolidation-plan-draft.md` (v2)
**Inputs:** ADRs 0001-0018, audit `2026-04-26_deep-read-audit-FINAL.md`, T4 answers `2026-04-27_T4_answers_CS.md`, T1 empirical-test results.

---

## 1. What v3 changes vs v2

v2 was written before Phase 0a-v2 audit, before Phase 0e walkthrough, and before the architecture pivot in ADR-0007. v3 is a clean restart based on:

- **18 Decided ADRs** locking design choices.
- **Phase 0a-v2 audit** mapping 85 verified bugs across the predecessor repos.
- **Phase 0e Q&A** reclassifying many findings (intentional, deferred, Matt-out-of-scope).
- **Architecture pivot (ADR-0007)**: code-data separation, Scribe non-git working copy, GitHub frozen archive at offboarding.
- **Offboarding model (ADR-0018)**: artifact deposited with Kramer (lab data-management custodian) at Christina's offboarding date; successor is unknown at offboarding time; README is the only orientation; no live handoff event.

Major v2 → v3 deltas:

| v2 assumption | v3 reality |
|---|---|
| Phase 1 fixes all 101 bugs | Phase 1 fixes Christina-owned bugs only; 4 retired (Matt-Naven), several reclassified intentional, FB-test concerns dissolved |
| Single working tree (data + code in repo) | Code in git, data on Scribe (ADR-0007) |
| Pipeline order locks in Phase 0b | Pipeline order locks here as part of Phase 1 |
| siblingvaregs lives | siblingvaregs (regression files only) deprecated; ~30 files archived (ADR-0004) |
| Bug 93 family is P1 paper-blocking | Bug 93 paper blast radius confirmed null; retired per ADR-0017 |
| AEA-package readiness target | Out of scope; reproducibility + audit-survivability + offboarding-readiness |
| Live handoff to a named successor | No live event; deposit with Kramer (custodian); successor unknown (ADR-0018) |

---

## 2. Sub-phases (locked structure)

Per Christina's 2026-04-26 framing, Phase 1 splits into three sub-phases. The boundaries are about *intent* of edits, not about which files get touched in which order — touching the same file across all three sub-phases is fine.

- **Phase 1a — Consolidate (behavior-preserving).** Move files to the canonical `consolidated/` folder layout. Update path references. Establish the Scribe sync workflow. Verify the relocated pipeline reproduces the current paper end-to-end (golden-master test). **No bug fixes in 1a.** This is structural refactoring only; the output should be byte-identical (or estimate-identical to numerical tolerance) with the predecessor repos.
- **Phase 1b — Bug fixes by priority.** Fix the bugs that ADRs identified as fixable, in priority order: paper-text corrections (ADR-0010, ADR-0011), code corrections (ADR-0011 sums→means, P3 typos), naming/clarity (ADR-0016, ADR-0015 documentation, ADR-0013 dormant-branch comment). Bugs in Matt's files retired per ADR-0017.
- **Phase 1c — Cosmetic cleanup.** Dead-code removal, log/translate cleanups, comment polish, README rewrite for the senior coauthor (per ADR-0007), HANDOFF preparation.

End of Phase 1 = offboarding-ready state. SESSION_REPORT and audit trail closed; GitHub becomes frozen archive.

---

## 3. Phase 1a — Consolidate (behavior-preserving)

### 3.1 Scribe folder + .gitignore setup

**Revised 2026-04-28 per ADR-0020.** Original §3.1 prescribed an `rsync` wrapper-script workflow (`sync_to_scribe.sh` / `sync_from_scribe.sh`) with SSH ControlMaster setup. ADR-0020 simplifies: file transfer is operator-choice (Christina uses FileZilla; her interactive-SSH workflow has worked reliably for years). The architectural commitments from ADR-0007 (code-data separation, no `.git/` on Scribe, `.gitignore` policy) all stand; only the *sync mechanism* simplifies.

1. **Create the Scribe consolidated folder.** Christina creates `/home/research/ca_ed_lab/projects/common_core_va/consolidated/` on Scribe.
2. **Initialize the GitHub repo's `.gitignore`** per ADR-0007:
   - Excluded paths: `data/`, `estimates/`, `log/`, `output/`
   - Excluded extensions: `*.dta`, `*.smcl`, `*.ster`, `.DS_Store`
   - Tracked everything else: tables, figures, code, docs, ADRs, paper LaTeX
   - Note on `*.log`: stays scoped per LaTeX dirs (existing convention) rather than globally excluded — Stata `.smcl` master logs are already excluded above, and `log/` dir-level exclusion covers their translated `.log` companions.
3. **File transfer mechanism (per ADR-0020)**: Christina uses FileZilla drag-and-drop for code changes from local Mac → Scribe `consolidated/`. Interactive SSH (`ssh chesun1@Scribe.ssds.ucdavis.edu` + password) for running the pipeline. No `~/.ssh/config` alias, no SSH key auth, no ControlMaster setup required for offboarding readiness.
4. **Clean-tree discipline at offboarding** (Phase 1c §5.4): Christina manually verifies local repo is at the `v1.0-final` tag with no uncommitted changes BEFORE pushing files to Scribe via FileZilla. One-time discipline at the offboarding moment, not a daily concern. The successor's reproduction instruction (in the offboarding deliverable memo per §5.2 step 8) is "clone GitHub at `v1.0-final`, copy contents to Scribe via your preferred file-transfer tool" — the GitHub tag is the authoritative version stamp, replacing the dropped on-Scribe `VERSION` marker from the original ADR-0007 design.

**Success criterion:** Scribe `consolidated/` exists; `.gitignore` excludes the right paths; file transfer mechanism documented (this section + ADR-0020) for Christina's daily work and for the successor's offboarding-time reproduction.

### 3.2 Folder layout build-out

Materialize the CLAUDE.md folder structure in the GitHub repo, leaving data/log/output dirs as empty path stubs with `.gitkeep` placeholders:

```
va_consolidated/
├── main.do                          # Phase 1a writes the SINGLE pipeline entry point
├── settings.do                      # Hostname-branched paths
├── ado/
│   └── vam.ado                      # Vendored per ADR-0006
├── do/
│   ├── _archive/                    # Holds the deprecated siblingvaregs/ etc. (Phase 1a moves)
│   ├── upstream/                    # Christina-owned upstream prep (excludes Matt's files)
│   ├── local/                       # Local-machine ad-hoc keepers
│   ├── sibling_xwalk/               # siblingoutxwalk.do moves here per ADR-0005
│   ├── data_prep/                   # Cleaning + raw-to-clean (Christina's portion)
│   ├── samples/                     # Sample construction (canonical)
│   ├── va/                          # VA estimation: helpers, score, outcome, pass_through, heterogeneity
│   ├── survey_va/                   # CalSCHLS index construction + survey-VA regs
│   ├── share/                       # Generic tab/figure helpers — ALL paper producers live here
│   ├── check/                       # Verification scripts (t1_empirical_tests.do already here)
│   ├── debug/                       # Ad-hoc diagnostics
│   └── explore/                     # Exploratory sandbox
├── py/
│   └── upstream/                    # Geocoding scripts (preserved per ADR-0003); gecode_json.py untouched per ADR-0017
├── data/                            # gitignored (Scribe-only)
├── estimates/                       # gitignored
├── output/                          # gitignored
├── log/                             # gitignored
├── tables/                          # tracked (per ADR-0007 / Q-tracking-everything)
├── figures/                         # tracked
├── paper/                           # Paper LaTeX (canonical at va_paper_clone; this folder may be empty for current milestone)
├── supplementary/                   # Online appendix
├── replication/                     # Phase 2+ (not Phase 1)
├── preambles/header.tex
├── explorations/
├── templates/
├── master_supporting_docs/
├── decisions/                       # ADRs (already populated)
├── quality_reports/                 # Audit + session logs (already populated)
└── README.md                        # rewritten in Phase 1c
```

**Success criterion:** Directory tree exists; `.gitignore` working as expected; empty stubs hold `.gitkeep` so directories are tracked even when empty.

### 3.3 Script relocation (predecessor → consolidated)

Move predecessor-repo files to the consolidated layout. **This is the bulk of Phase 1a.** Each move = one git commit so the diff stays readable.

**Order matters** (downstream depends on upstream):

1. **Helpers and macros** (`macros_va*.doh`, `vaestmacros.doh`, `vafilemacros.doh` if not deprecated, `drift_limit.doh`, `macros_va_all_samples_controls.doh`) → `do/va/helpers/`
2. **Sample construction** (`samples/` from `cde_va_project_fork/do_files/sbac/samples/`, plus `touse_va.do`, `create_*_samples.do`, `create_va_*.doh`) → `do/samples/`
3. **VA estimation** (`va_score_all.do`, `va_out_all.do`, plus `va_*_tab.do` and `va_*_fig.do` from `do_files/sbac/`) → `do/va/`
4. **Heterogeneity & pass-through** (`va_het.do`, `pass_through/` files, `reg_out_va_*.do`) → `do/va/heterogeneity/` and `do/va/pass_through/`
5. **Sibling crosswalk** (`siblingoutxwalk.do`) → `do/sibling_xwalk/` per ADR-0005. **Update the 2 callers**: `cde_va_project_fork/do_files/do_all.do:142` and `caschls/do/master.do:103`. (Both will themselves become Phase 1a archive once main.do is built.)
6. **Sibling-VA regressions DEPRECATED** per ADR-0004: move ~30 files from `caschls/do/share/siblingvaregs/` (minus `siblingoutxwalk.do`) to `do/_archive/siblingvaregs/`. Includes: `va_sibling*.do`, `va_sib_acs*.do`, `reg_out_va_sib_acs*.do`, `siblingvasamples.do`, `createvasample.do`, `vaestmacros.doh` (if confirmed deprecated-only), `vafilemacros.doh` (same).
7. **Survey VA** (`caschls/do/share/factoranalysis/imputedcategoryindex.do`, `compcasecategoryindex.do`, `indexalpha.do`, `indexhorserace.do`, `indexhorseracewithdemo.do`, `indexregwithdemo.do`, `imputation.do`, `factor.do`, `pcascore.do`, `mvpatterns.do`) → `do/survey_va/`
8. **`alpha.do` ARCHIVED** per ADR-0010 → `do/_archive/exploratory/`
9. **Data prep** — Christina-owned cleaning files (`enrollmentclean.do`, `acs/`, `schl_chars/`, `k12_postsec_distance/`, `prepare/`, `caschls_qoiclean/`) → `do/data_prep/`. **Matt's files (`crosswalk_nsc_outcomes.do`, `crosswalk_ccc_outcomes.do`, `crosswalk_csu_outcomes.do`, `merge_k12_postsecondary.doh`, `gecode_json.py`) NOT moved** per ADR-0017 — they stay in their predecessor location and continue to be called from there.
10. **Share / paper producers** — all paper-shipping table and figure producers from `cde_va_project_fork/do_files/share/` and `caschls/do/share/` (minus `siblingvaregs/` and `factoranalysis/alpha.do`) → `do/share/`. **Includes `mattschlchar.do`** (Christina-authored despite name, in scope per ADR-0013).
11. **Local / debug / explore / check** — keepers go to `do/local/`, `do/debug/`, `do/explore/`, `do/check/`. Already started: `do/check/t1_empirical_tests.do`.

**Path-reference updates.** Every relocated file's `do $projdir/.../old_path` calls update to the new structure. Phase 1a uses `grep -rn` to find all such calls and update systematically.

**Success criterion:** All Christina-owned files relocated; predecessor `do_all.do` and `master.do` callers retired; the new `main.do` is the single entry point.

### 3.4 main.do construction

`main.do` is the new single entry point. It replaces `cde_va_project_fork/do_files/do_all.do` and `caschls/do/master.do`. Sequence:

```stata
// main.do — single pipeline entry point for the Common Core VA project
// Per ADR-0014 (entry-point naming): main.do is canonical, do_all.do retired

include settings.do                    // hostname-branched paths per ADR-0002

// Toggle phases for dev convenience
local run_data_prep      1
local run_samples        1
local run_va_estimation  1
local run_va_tables      1
local run_survey_va      1
local run_paper_outputs  1

if `run_data_prep' {
    do do/data_prep/...
    // NOTE: crosswalk_nsc/ccc/csu_outcomes.do are NOT invoked from main.do.
    // They are static, run-once-cached artifacts (same pattern as gecode_json.py
    // per chunk-10 audit). Their .dta outputs are pre-existing inputs that
    // merge_k12_postsecondary.doh consumes when called by Christina's
    // sample-construction code (see `run_samples` block below).
}

if `run_samples' {
    do do/samples/touse_va.do
    do do/samples/create_score_samples.do
    do do/samples/create_out_samples.do
    do do/sibling_xwalk/siblingoutxwalk.do                  // ADR-0005
    do do/samples/create_va_sib_acs_restr_smp.do
    do do/samples/create_va_sib_acs_out_restr_smp.do
}

if `run_va_estimation' {
    do do/va/va_score_all.do                                 // ADR-0004 / ADR-0009
    do do/va/va_out_all.do
    do do/va/heterogeneity/va_het.do
    do do/va/pass_through/...
}

if `run_va_tables' {
    do do/share/va/...                                       // paper-shipping tables per ADR-0012
}

if `run_survey_va' {
    do do/survey_va/imputation.do
    do do/survey_va/imputedcategoryindex.do                  // sums→means fix per ADR-0011
    do do/survey_va/compcasecategoryindex.do                 // same fix
    do do/survey_va/indexalpha.do                            // canonical α per ADR-0010
    do do/survey_va/indexregwithdemo.do
    do do/survey_va/indexhorseracewithdemo.do
}

if `run_paper_outputs' {
    do do/share/sample_counts_tab.do                         // ADR-0009 v1-only
    do do/share/base_sum_stats_tab.do                        // ADR-0009 v1-only
    // ... etc.
}

di as text "main.do complete."
```

**Settings.do** uses `c(hostname)` branching to set `$vaprojdir`, `$projdir`, `$vaprojxwalks`, etc. Default branch resolves to Scribe paths.

**Success criterion:** `cd consolidated && stata -b do main.do` runs end-to-end with all phase toggles ON. Output matches predecessor pipeline byte-for-byte (or estimate-for-estimate to numerical tolerance per replication-protocol.md).

### 3.5 Golden-master verification

Before starting Phase 1b bug fixes, verify Phase 1a is **behavior-preserving**:

1. Run the predecessor pipeline (`cde_va_project_fork/do_files/do_all.do` + `caschls/do/master.do`) on Scribe; capture the produced tables/figures + key estimates `.dta` files.
2. Run `consolidated/main.do` on Scribe; capture the same outputs.
3. Compare:
   - **Tables** (`.tex` fragments): byte-identical OR identical to display precision.
   - **Figures** (`.pdf`): visually identical (eyeball check; vector PDFs may differ in metadata but match visually).
   - **Estimates** (`.dta`/`.ster`): coefficient values match to ≤0.01 (per replication-protocol.md tolerance table).
   - **Sample counts**: exact match.

If anything diverges, root-cause **before** moving to 1b. Any divergence at this stage indicates a Phase 1a relocation introduced a bug, which must be fixed first.

**Success criterion:** Predecessor and consolidated pipelines produce equivalent paper outputs.

---

## 4. Phase 1b — Bug fixes by priority

### 4.1 Paper-text corrections (low-risk, high-clarity)

1. **ADR-0010**: Update `paper/common_core_va_v2.tex:407` footnote — replace 20/17/4-question α values with 9/15/4 (from `indexalpha.do`). Coordinate with senior coauthor on whether to ship as Phase 1 edit or queue for next R&R.
2. **ADR-0014**: Add header note to `paper/common_core_va.tex` declaring it OLD/historical; do not delete.

### 4.2 Code corrections (analytical / paper-affecting)

3. **ADR-0011**: Sums→means in `do/survey_va/imputedcategoryindex.do:33-50` and `compcasecategoryindex.do` (same pattern). One added `replace <cat>index = <cat>index / `:word count `<cat>vars''` line per index. Update L33 comment from "summing" to "averaging." Verify post-z-score regression coefficients unchanged at paper-rounding precision.
4. **P2-3 / P2-11 cluster rename**: `do/va/heterogeneity/va_het.do:158` and any other Christina-owned reg using `cluster(cdscode)` — rename to `cluster(school_id)` for naming consistency (T1-3 confirmed 1:1 so SEs unchanged). Cosmetic; no re-run needed.
5. **ADR-0006 vam.ado version line**: bump `*! version 2.0.1` → `*! version 2.0.1.1 — C. Sun 2026-04-25 noseed-fix at L252-255`.

### 4.3 Naming and clarity

6. **ADR-0016 pooledrr rename**: edit 4 files (`parentresponserate.do`, `secresponserate.do`, `pooledparentdiagnostics.do`, `pooledsecdiagnostics.do`); rename variable + verify downstream consumer points via `grep -n 'pooledrr' do/`.
7. **ADR-0015 Filipino/Asian comment**: add inline explanation in `pooledsecdemographics.do:23-24`. Christina supplies the actual reasoning (cross-data alignment, small cells, etc.) at edit time.
8. **ADR-0013 mattschlchar dormant-branch comment**: add header note explaining `local clean = 0` is permanent; rebuild branch is dormant; cite ADR-0013.

### 4.4 P3 items (selective, time-permitting)

The P3 list has 69 items. Most are cosmetic typos and dead code. Phase 1b/1c addresses the readable subset; leave the truly trivial ones for the senior coauthor's discretion:

| Class | Examples | Treatment |
|---|---|---|
| Stata typos | `va_corr.do` "ase sample" / "ktichen" (P3-15); `_cts.ster` typo (P3-9); `\.dta\.dta` (P3-8) | Fix during 1b sweep |
| Missing `$` prefixes | `vaestmacros.doh` L45, L118 (P3-7) | Fix during 1b sweep |
| Missing `log close` / `translate` | `va_out_fb_test_tab.do` (P3-11), `factor.do` log dir (P3-34) | Fix during 1b sweep |
| Dead code | `out_drift_limit.doh` (P3-14) | Move to `_archive/dead/` during 1c |
| `set trace on` without `off` | `va_var_explain.do` (P2-12), `crosswalk_nsc_outcomes.do` (P3-67) | Fix Christina's; leave Matt's per ADR-0017 |
| Comment-only restrictions | `touse_va.do:104-107` special-ed/home-instruction (P3-48 / Q-14) | Defer per Q-14 — needs upstream investigation |
| `enrollmentclean.do` female-encoding | P2-14 | Fix during 1b (semantics matter) |

Phase 1b doesn't aim for completeness on P3; it aims for readability and correctness of items that matter. Items not addressed get a tracking entry in `TODO.md` Backlog.

### 4.5 Items NOT fixed in Phase 1 (recorded for clarity)

Per ADRs and Q-answers:

- **ADR-0017**: Bug 93 family (4 instances), `id` macro at `crosswalk_nsc_outcomes.do:250`, `merge_k12_postsecondary.doh:7` hardcoded path, P3-65 / P3-66 / P3-67 / P3-68 / P3-69 (all Matt's files).
- **Q-14 deferred**: Special-ed / home-instruction restrictions (P3-48) — needs upstream investigation; backlog item.
- **Reclassified intentional**: P2-5, P2-6, P3-62, P3-63 (per ADR-0012); P3-3, P3-6 (Q-7, Q-8 intentional); P3-53 (per ADR-0015); P3-57, P3-58 (per ADR-0009 Q-19).

---

## 5. Phase 1c — Cosmetic cleanup + offboarding prep

### 5.1 Code-side cleanup

1. **Dead code archival**: `out_drift_limit.doh` (P3-14), any other Phase-0a-flagged dead files → `do/_archive/dead/`.
2. **Per-do-file logging** (added 2026-04-28): every do file opens its own log near the top — `log using "$logdir/<filename>.smcl", replace text` — and closes at the bottom — `cap log close` + `translate "$logdir/<filename>.smcl" "$logdir/<filename>.log", replace`. `settings.do` defines `$logdir` per host. Phase 1c sweep audits each relocated do file: any without per-file logging gets the convention added. Convention enforced by `do/check/check_logs.do` (lives with the data-checks pipeline, §5.3 step 9; asserts every do file under `do/` produced a log on a clean `main.do` run; fails if any are missing). Predecessor convention — single global log per pipeline — is replaced because per-file logs make failures localizable for offboarding-era debugging.
3. **Header comments**: every `do/` file gets a 4-line header (purpose, inputs, outputs, ADR refs if applicable) per the convention used in `do/check/t1_empirical_tests.do`.
4. **`.gitignore` hardening**: pre-commit hook (optional) verifying no `.dta`/`.ster`/`.smcl` files are staged.

### 5.2 Documentation

5. **README.md rewrite** (per ADR-0007). Audience: Stata-skilled, no git, no data management. Structure (per 2026-04-27 chat):
   - Quick overview
   - **How to run the pipeline** (most important section)
   - **What to know** (folder map)
   - **Data flow**
   - **Where outputs go**
   - **How to make changes** (3 common cases)
   - **What NOT to touch** (Matt's files per ADR-0017; ado/vam.ado; data/raw/; SSH credentials)
   - **Where things are documented** (decisions/, master_supporting_docs/, quality_reports/)
   - **When something breaks** (Christina's contact; log/ pointer)
   - **Project history** (predecessor repos; GitHub link; ADR ledger pointer)
6. **CLAUDE.md update**: reflect actual final folder layout + ADR pointers.
7. **Provenance README files** in `data/raw/upstream/` (per ADR-0008 stub) and any other "data-only path" stubs in the gitignored tree.
8. **Offboarding deliverable memo** (per ADR-0018): document at `quality_reports/handoff/2026-MM-DD_offboarding-memo.md` (date set when the actual offboarding happens; directory kept as `handoff/` for predictability). Audience is Kramer + future-unknown successor. Captures:
   - GitHub repo URL
   - Scribe `consolidated/` folder location + lab IT onboarding contact for SSH access
   - Where data lives on Scribe (paths to `data/raw/`, `estimates/`, etc.)
   - Where Matt's untouched files are (per ADR-0017) — paths + rationale
   - The acceptance-run log path (per ADR-0018) showing the pipeline ran clean before `v1.0-final`
   - Inventory of what Kramer is responsible for (custodian, not maintainer)
   - Any conversations/decisions that didn't make it into ADRs

### 5.3 Automated data checks (added 2026-04-28; serves audit-survivability def-of-done)

Goal: every pipeline run produces verifiable signals that the analytical chain is intact. Complements M4 golden-master verification (a *relative* check — predecessor vs consolidated outputs) with *absolute* invariant checks tied to codebook ranges and historical sample sizes. The check pipeline becomes the offboarding-era smoke test — any future operator running `main.do` learns immediately whether the data and analysis are still well-formed.

Scaffolding can begin opportunistically during Phase 1a: as each stage of the pipeline relocates and is verified against the predecessor, write its companion check file. By the start of Phase 1c the check files exist; this section is where they get systematized, integrated into `main.do`, and finalized against codebook-derived bounds.

9. **Build `do/check/` pipeline** of assertion-based verification scripts. One file per analytical stage (filename mirrors the pipeline section it guards):
   - `check_samples.do` — row counts per cohort year (against historical N from the audit), key uniqueness (`isid` on student / school / cohort keys), no missings on critical vars, FRPM / EL / race-ethnicity / sex categorical levels in expected sets (codebook-derived where available).
   - `check_merges.do` — K12 ↔ NSC / CCC / CSU merge rates within historical bounds; flag if `_merge` distribution shifts >0.5 pp from the relocated baseline.
   - `check_va_estimates.do` — VA SD / cross-sectional spread within paper-reported ranges (~0.10–0.15 σ depending on outcome); estimate-level missings flagged; v1 prior-score deciles non-degenerate.
   - `check_survey_indices.do` — Likert-scale ranges per CalSCHLS codebook; index z-score completeness; item counts per index match `indexalpha.do` per ADR-0010 (9 / 15 / 4).
   - `check_paper_outputs.do` — sample sizes printed in paper tables match `share/` producer outputs and the audit-locked counts from chunk-9.
   - `check_logs.do` — every relocated do file under `do/` produced a log file on the most recent clean `main.do` run; fail-loud listing for missing logs (pairs with §5.1 step 2).
10. **Assertion conventions**: `assert` for hard invariants (pipeline halts on failure); `display as error` for soft signals (printed but non-halting). Each check file gets a 4-line header documenting invariant + tolerance + remediation pointer. Where a check has no documented bound yet, it carries an explicit `// TBD-codebook` marker so missing bounds are auditable.
11. **`main.do` integration**: a `local run_data_checks 1` toggle invokes the check pipeline AFTER main analysis completes. A clean `main.do` run = all checks pass. A failed assertion stops the pipeline at the offending check, leaving partial output on disk so the failure is diagnosable. Toggle defaults ON; can be disabled for dev iteration but production / acceptance runs must run with checks ON.
12. **Codebook-derived bounds**: per Christina-supplied codebooks for SBAC, CalSCHLS, CALPADS, NSC (etc.), each check file cites its codebook source for the ranges it asserts. If a codebook is unavailable for a given dataset, the bound derives from current pipeline output and is flagged TBD-codebook (see step 10) so the audit trail records what is and isn't pinned to an external source.

**Success criterion**: `local run_data_checks 1` block runs clean on Scribe at the v1.0-final acceptance run; all `do/check/check_*.do` log files committed alongside the production-run logs.

### 5.4 Final verification + freeze (per ADR-0018 acceptance criteria)

13. **Full-pipeline acceptance run on Scribe** (`stata -b do main.do` with `run_data_checks = 1`) — Christina runs the pipeline end-to-end. **Non-negotiable per ADR-0018**: this is the last action before `v1.0-final` tag. Captures clean log + all output artifacts + documented runtime. If it fails (including any data-check assertion), root-cause and fix before continuing.
14. **README cold-read test**: a friendly lab member (NOT Christina) reads the README cold and tries to run the pipeline. Iterate README until they succeed without asking questions. Per ADR-0018, this pairs with step 13 as the offboarding acceptance criteria — both must pass.
15. **Final commit + GitHub push**. Tag the commit as `v1.0-final` per ADR-0018 (not `v1.0-handoff`).
16. **Final file transfer to Scribe** (per ADR-0020): Christina pushes the `v1.0-final` working tree to Scribe via FileZilla (or her preferred tool). No on-Scribe `VERSION` marker — the GitHub tag is the authoritative version stamp, recorded in the offboarding deliverable memo.
17. **Deposit with Kramer** per ADR-0018: hand over the offboarding deliverable memo (§5.2 step 8) + GitHub repo URL + Scribe folder location.

**Success criterion** (per ADR-0018): full-pipeline acceptance run (with data checks ON) produces clean output AND a Stata-skilled stranger with SSH access can read README cold and reproduce the pipeline. Both gates required.

---

## 6. Order, dependencies, time budget

### 6.1 Sub-phase ordering

Phase 1a → Phase 1b → Phase 1c. Each gates the next.

- Phase 1a must complete the golden-master verification before Phase 1b begins. Reason: any bug fix during 1b changes outputs, so the comparison only works against a behavior-preserving 1a baseline.
- Phase 1c can begin in parallel with the tail of 1b (e.g., README rewriting can start while last typo fixes are happening).

### 6.2 Within-phase dependencies

- Phase 1a §3.1 (Scribe folder + sync setup) gates everything — without working sync, no testing on Scribe.
- Phase 1a §3.3 (script relocation) blocks §3.4 (main.do construction).
- Phase 1a §3.4 blocks §3.5 (golden-master verification).
- Phase 1b §4.2 (code corrections) blocks any verification in 1c that the corrections didn't break anything.

### 6.3 Time budget

3 months total. Rough allocation:

- **Phase 1a (~6 weeks)** — folder setup, ~150 file relocations + path updates, main.do, golden-master verification. The relocation work is the single largest chunk. Per-do-file logging convention (§5.1 step 2) and stub data-check files (§5.3) added opportunistically as each stage relocates.
- **Phase 1b (~4 weeks)** — bug fixes by priority, P3 sweep, paper-text edits.
- **Phase 1c (~3 weeks)** — README rewrite, offboarding deliverable memo, automated data-checks pipeline finalized against codebook bounds (§5.3), per-do-file logging audit (§5.1 step 2), full-pipeline acceptance run (with `run_data_checks = 1`), README cold-read test, freeze. (Bumped from ~2 to ~3 weeks 2026-04-28 to absorb the data-checks build-out and codebook integration.)

Buffer: ~0 weeks. If 1a slips, 1b/1c compress; if 1c bumps the offboarding date, that's coordinated with Kramer + lab admin (no successor to discuss with — see ADR-0018).

### 6.4 Milestones for tracking

| Milestone | Target | Gate |
|---|---|---|
| M1: Scribe folder + .gitignore + file-transfer mechanism documented | Phase 1a §3.1 + §3.2 done | Scribe `consolidated/` exists; `.gitignore` covers ADR-0007 paths; FileZilla workflow tested with a sample file (per ADR-0020) |
| M2: Files relocated | Phase 1a §3.3 done | Predecessor `do_all.do` + `master.do` retired |
| M3: main.do works | Phase 1a §3.4 done | `stata -b do main.do` runs on Scribe |
| M4: Golden-master pass | Phase 1a §3.5 done | Outputs match predecessor pipeline |
| M5: Paper-affecting bugs fixed | Phase 1b §4.1 + §4.2 done | Paper produces same numbers; α footnote updated |
| M6: P2/P3 sweep done | Phase 1b §4.3 + §4.4 done | TODO.md backlog reflects what's deferred |
| M7: README rewrite done | Phase 1c §5.2 done | Cold-read test passes |
| M8: Automated data checks pipeline live | Phase 1c §5.3 done | `local run_data_checks 1` block runs clean as part of `main.do`; per-do-file logs present (§5.1 step 2) |
| M9: Acceptance run + README cold-read pass | Phase 1c §5.4 steps 13-14 done | Pipeline runs clean (checks ON); cold-read test passes (per ADR-0018) |
| M10: Offboarding freeze + Kramer deposit | Phase 1c §5.4 steps 15-17 done | `v1.0-final` tag pushed; deliverable memo handed to Kramer |

Each milestone gets a session log + commit so the audit trail is durable.

### 6.5 Per-commit review discipline (added 2026-04-28)

Every in-scope code commit during Phase 1 goes through `coder-critic` at a hard 80/100 gate before push, per `.claude/rules/phase-1-review.md`. Layered defense:

| Tier | Mechanism | Fires on |
|---|---|---|
| 1 | Pre-commit self-check (path-references, scope, ADR cite) | Every in-scope commit |
| 2 | `coder-critic` agent dispatch | Substantive code changes (relocations, bug fixes, new `check_*.do`) |
| 3 | Data-checks pipeline (§5.3) | Every `main.do` run on Scribe |
| 4 | Golden-master M4 (§3.5) | End of Phase 1a |

Tiers 1-2 are the new addition; Tiers 3-4 are §5.3 and §3.5 respectively. Hard-gate score < 80 blocks commit; up to 3 worker-critic rounds before escalation. Commit message footer records the verdict (`coder-critic: PASS (89/100)` etc.) so `git log --grep='coder-critic'` is the audit trail.

Out of scope for `coder-critic`: ADR files, session logs, README rewrite (writer-critic instead), folder stubs, plan v3 edits.

Sunsets at `v1.0-final` per ADR-0018.

---

## 7. Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Path-reference updates miss something during relocation | Medium | High (silent breakage) | Systematic `grep -rn` sweeps; golden-master verification (M4) catches divergences |
| Matt's account decommissioned during Phase 1 | Low | High (pipeline breaks at NSC/CCC/CSU merge) | ADR-0008 backups give a recovery path; trigger successor ADR for the merge code |
| README cold-read fails for hypothetical future reader (per ADR-0018, no live introduction) | Medium | High | §5.4 step 14 cold-read test by friendly non-Christina lab member; iterate README until it works without questions |
| Full-pipeline acceptance run fails before `v1.0-final` (ADR-0018 non-negotiable) | Low-Medium | High | Root-cause and fix before tagging; do NOT deposit a broken pipeline with Kramer |
| Golden-master verification fails | Medium | Medium-High | Root-cause before moving to Phase 1b; never paper over with "close enough" |
| Repo size grows unmanageably from tracked tables/figures | Low | Low | ADR-0007 open question — monitor; switch to Git LFS for any single artifact > 50MB |
| Filipino/Asian recoding rationale unclear at edit time (Q-15) | Medium | Low | Christina + senior coauthor clarify reasoning; the comment captures it |
| Sums→means fix changes a downstream consumer outside the regression chain | Low | Medium | Phase 1b §4.2.3 verification step covers the regression chain; if any other consumer surfaces, treat as a Phase 1b finding |

---

## 8. Open questions — ALL RESOLVED 2026-04-27

1. ~~**Phase 1a §3.4 `main.do` Matt-file calls**~~ — **RESOLVED**: grep confirmed ZERO production invocations of any `crosswalk_*_outcomes.do` file (they're static, run-once-cached). main.do does NOT invoke them. settings.do gets a `$matt_files_dir` global (e.g., `/home/research/ca_ed_lab/projects/common_core_va/do_files`); Christina's relocated sample-construction files reference Matt's `merge_k12_postsecondary.doh` via that global. No predecessor-bridge wrapper needed.
2. ~~**Paper-LaTeX scope for Phase 1**~~ — **RESOLVED**: paper LaTeX **out of scope** for Phase 1. ADR-0010 (α footnote update) and ADR-0014 (old-draft header note) happen in `va_paper_clone`, NOT in this repo. Consolidated `paper/` folder stays empty per ADR-0001.

**Bonus discovery** (ADR-0019): `crosswalk_nsc_outcomes.do` is Christina-authored (Mar 2022, heavy refactor of Matt's archived original), not Matt's. ADR-0017 file list corrected to 4 files (CCC + CSU crosswalks, merge_k12_postsecondary.doh, gecode_json.py). Phase 1 still leaves NSC crosswalk untouched per option (B) — file isn't pipeline-active, Bug 93 paper-null, time better spent on offboarding acceptance run.
3. ~~**`v1.0-handoff` tag timing**~~ — **RESOLVED by ADR-0018**: tag is `v1.0-final`, frozen at last commit before offboarding; no availability window.
4. ~~**Senior coauthor identity**~~ — **RESOLVED by ADR-0018**: successor is unknown at offboarding time; README is generic. Kramer is custodian, not maintainer.
5. ~~**Phase 2 placeholder in TODO**~~ — **RESOLVED by ADR-0018**: Phase 1 ends at offboarding; no Phase 2 tracking. Anything not done by `v1.0-final` is the future successor's concern, fully off Christina's plate.

Remaining open questions (need Christina's answers before Phase 1a starts):

- See Q1, Q2 above. (Q3-Q5 superseded by ADR-0018.)

---

## 9. 2026-04-28 plan revision — per-do-file logging + automated data checks

Two additions, both Phase 1c:

- **§5.1 step 2 upgraded** — every do file opens its own log; predecessor's single-global-log convention replaced. Localizes failures for offboarding-era debugging.
- **§5.3 added** — automated data-checks pipeline under `do/check/check_*.do`. Six check files (samples, merges, va estimates, survey indices, paper outputs, logs) wired into `main.do` via a `run_data_checks` toggle. Codebook-derived bounds where available; `// TBD-codebook` markers where not.

Knock-on edits: §6.3 Phase 1c bumped 2 → 3 weeks; §6.4 milestones M8/M9/M10 added/renumbered; §7 risk register §5.3-step-10 reference updated to §5.4-step-14.

**Codebooks needed** (Christina to supply when convenient — does not block Phase 1a start). Priority order:

1. **CalSCHLS** — Likert scales, item counts per index, missing codes. Highest leverage: directly pins the survey-index checks per ADR-0010 / ADR-0011 (9 / 15 / 4 items + sums-vs-means).
2. **SBAC** — score range, performance bands, missing/exempt codes. Pins prior-score deciles and outcome-score sanity.
3. **CALPADS demographics** — race/ethnicity codes (esp. for ADR-0015 Filipino-into-Asian recoding), FRPM, EL, special-ed, sex coding. Pins categorical-level checks across samples.
4. **NSC outcomes** — sector codes (UC / CSU / CCC / private / OOS), persistence-year flags, degree-level codes. Pins K12 ↔ NSC merge checks.
5. **CCC / CSU outcomes** (Matt's pipeline; checks read the merged result, don't touch Matt's files per ADR-0017) — sector codes + transfer flags. Lower priority since downstream merges are Matt-owned.

Where a codebook is not available before v1.0-final, the corresponding check carries a `// TBD-codebook` marker and asserts only against the current pipeline output. Audit trail is honest about what is and isn't pinned externally.

---

## 9. Sources

- ADRs 0001-0018 in `decisions/`
- `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` (audit + bug priority triage)
- `quality_reports/audits/2026-04-27_T4_answers_CS.md` (Phase 0e answers)
- `quality_reports/plans/2026-04-25_consolidation-plan-draft.md` (v2 — superseded)
- `CLAUDE.md` (folder layout reference)
- `.claude/rules/` — workflow.md, replication-protocol.md, decision-log.md, todo-tracking.md, logging.md
- 2026-04-27 conversation: architecture pivot + offboarding context

---

## 10. Approval and next steps

This plan is DRAFT. After Christina reviews:

- Open questions in §8 get answered, plan becomes APPROVED.
- Christina commits the approved plan, then begins Phase 1a §3.1 (Scribe folder + sync setup).
- Each milestone (§6.4) produces a session log + commit on completion.

Once the plan is APPROVED, Christina signals start of Phase 1a and the milestone clock starts.
