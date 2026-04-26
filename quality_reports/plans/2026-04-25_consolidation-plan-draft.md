# Consolidation Plan — Common Core VA Project (v2)

**Status:** DRAFT v2 (incorporates Christina's feedback on v1)
**Author:** Christina Sun (with Claude)
**Date drafted:** 2026-04-25
**Deadline:** ~2026-07-24 (3 months from project kickoff 2026-04-24)

> **v2 changes**: py_files preserved as upstream geocoding (was incorrectly marked dead); root-level `do/` + `py/` (no `scripts/` parent); `main.do` not `master.do`; **Phase 0 = full deep-read audit before any consolidation**; server-folder reconciliation added; siblingoutxwalk relocation flagged for dependency tracing. v1 is preserved in git history at commit `7dba243`.

---

## 1. Goal (recap)

Per `quality_reports/session_logs/2026-04-24_project-onboarding.md` and Christina's confirmed definition of done, the consolidation must hold all three:

1. **Reproduces the rejected paper end-to-end**: from raw CAASPP/SBAC + roster on Scribe to every table and figure in `~/github_repos/va_paper_clone/paper/common_core_va_v2.tex`. Single entry-point script that runs to completion.
2. **Resolves the sibling/VA dependency cleanly**: one canonical pipeline order, no circular references, no duplication between caschls and the fork.
3. **Survives a future-me audit in 5 years**: ADRs in `decisions/`, file dictionary, comments documenting non-obvious choices.

**NOT in scope for this milestone:** AEA replication-package readiness, openICPSR deposit, Overleaf-sync automation. These are post-consolidation follow-ups.

---

## 2. Inputs (what we know going in)

After 5 rounds of context-dump Q&A, the master-file audit, and Christina's v1-plan feedback:

- **Two predecessor repos**: `~/github_repos/cde_va_project_fork` (changes_by_che branch) and `caschls` at the Dropbox path. Both inventories are now known-complete after the audit (`quality_reports/reviews/2026-04-25_master-file-audit.md`). Files outside the production pipeline are bucketed: `archive/`, `upstream/`, `local/`, `check/`, `debug/`.
- **Two folders on Scribe**: Christina noted in the v1 plan review that the code lives in TWO folders on the server. The reconciliation between them (which is canonical, what's stale, are they tracked by either local repo) is a **must-resolve item during the deep-read phase**, not after.
- **Paper as single source of truth**: 1357-line draft, indexed in `quality_reports/reviews/2026-04-24_paper-map.md`. Six load-bearing pipelines must reproduce.
- **Runtime**: Scribe server only (`Scribe@ssds.ucdavis.edu`, `c(hostname)="scribe"`, project root `/home/research/ca_ed_lab/projects/common_core_va`, Stata version on server has drifted 16 → 17 → 18; we'll pin 17 and revisit version compatibility as a TODO).
- **Languages**:
  - **Stata** is the production-pipeline language.
  - **Python** is preserved as upstream geocoding (in `py_files/` of both predecessors). Python scripts are NOT on the production pipeline but ARE kept for completeness and record-keeping (parallel to `do/upstream/`'s role for Stata upstream scripts).
- **Currently-known pipeline order** (from `master.do` toggles in caschls):
  1. `caschls/master.do` — sibling-matching block (4 do-files: `siblingmatch`, `uniquefamily`, `siblingpairxwalk`, **`siblingoutxwalk`**)
  2. `cde_va_project_fork/do_all.do` — full VA estimation pipeline
  3. `caschls/master.do` — survey indices + survey-VA regressions
- **`siblingoutxwalk.do` lives in `do/share/siblingvaregs/`, not `do/share/siblingxwalk/`** despite logically being part of the sibling-crosswalk pipeline. Christina flagged: should relocate to `siblingxwalk/`-equivalent but **needs dependency-trace check first** in case anything in `siblingvaregs/` itself depends on its sibling-folder neighbors. Deep-read will resolve this.
- **vam shrinkage**: custom-modified version in `caschls/do/ado/`. Must be preserved.
- **v1 + v2 prior-score loops**: both preserved (v1 canonical for paper; v2 kept for potential coauthor revisits).

---

## 3. Target folder structure (v2)

```
va_consolidated/
├── CLAUDE.md, README.md, LICENSE, MEMORY.md, TODO.md
├── SESSION_REPORT.md, .claude/SESSION_REPORT.md
├── .claude/                       # rules, hooks, skills, state
├── decisions/                     # ADRs
├── quality_reports/               # plans, session logs, reviews, audits
├── master_supporting_docs/        # literature/, reading_notes/
│
├── main.do                        # single entry point at repo root, replaces "master.do"
├── settings.do                    # hostname-branched paths, colocated with main.do
├── ado/                           # custom-modified vam package + any other custom .ado
│
├── do/                            # ALL Stata pipeline scripts (root-level, no scripts/ parent)
│   ├── _archive/                  # historical / superseded
│   ├── upstream/                  # produces static project inputs (Stata)
│   ├── local/                     # local-machine ad-hoc keepers
│   ├── sibling_xwalk/             # 4 (or 5, see siblingoutxwalk question) sibling-crosswalk scripts
│   ├── data_prep/
│   │   ├── acs/
│   │   ├── schl_chars/
│   │   ├── k12_postsec_distance/
│   │   ├── prepare/               # caschls build/prepare/* (enrollmentclean, renamedata, etc.)
│   │   └── caschls_qoiclean/      # caschls QOI cleaning (parent/secondary/staff x cohort)
│   ├── samples/
│   │   ├── caschls_pooling/
│   │   ├── caschls_demographics/
│   │   └── sbac/                  # touse_va, create_score_samples, create_out_samples, prior_decile_original_sample
│   ├── va/
│   │   ├── helpers/               # macros_va.doh, create_va_sample.doh, create_prior_scores_v1.doh, create_prior_scores_v2.doh, vafilemacros.doh
│   │   ├── score/
│   │   ├── outcome/
│   │   ├── pass_through/
│   │   ├── heterogeneity/
│   │   └── (top-level: merge_va_est, va_corr, va_spec_fb_tab, va_var_explain, va_var_explain_tab)
│   ├── survey_va/
│   │   ├── factoranalysis/
│   │   ├── sibling_va_regs/
│   │   └── allvaregs.do
│   ├── share/                     # generic tab/figure helpers
│   ├── check/                     # verification utilities
│   ├── debug/
│   └── explore/
│
├── py/                            # Python (root-level, no scripts/ parent)
│   └── upstream/                  # geocoding (and any other upstream Python from py_files/)
│
├── data/
│   ├── raw/                       # gitignored; documented
│   └── cleaned/                   # gitignored; intermediate dta outputs
├── output/                        # logs, intermediate non-paper outputs
├── figures/                       # mirrors paths the paper LaTeX expects
│   └── share/va/v1/, share/va/v2/, share/survey/
├── tables/                        # mirrors paper paths
│   └── share/va/pub/, share/survey/pub/
├── log/                           # log files
└── paper/                         # left empty for this milestone (paper canonical = va_paper_clone)
```

**Resolved design questions from v1:**

- Q1: `do/` (Christina confirmed; remove `scripts/` entirely).
- Q2: subdirectory granularity by analytic concern (data_prep, samples, va, survey_va) — agreed.
- Q3: helpers under `do/va/helpers/` together — agreed.
- Q4: entry-point script renamed to `main.do` (not `master.do`); colocated with settings.do at repo root — agreed.
- Q5: pin Stata 17 for now; add Stata-version compatibility revisit to TODO.
- Q6: copy custom vam package as-is to `ado/` with `ado/README.md` documenting modifications.

**Open structural question:**

- **siblingoutxwalk.do relocation**: currently `caschls/do/share/siblingvaregs/siblingoutxwalk.do`. Should move to `do/sibling_xwalk/siblingoutxwalk.do` in the consolidated layout. **Blocking on dependency trace** — if anything in `siblingvaregs/` includes/sources files that include/source siblingoutxwalk-style logic, we could introduce a new circular reference. Deep-read Phase 0 must resolve this before locking the structure.

---

## 4. Pipeline ordering

Single `main.do` that toggles each phase. Phase blocks:

```
Phase 0: settings.do (paths, hostname branching, version, ssc install failsafe)
Phase 1: upstream  [TOGGLE: do_upstream = 0]
   - Stata: crosswalk_nsc_outcomes, crosswalk_ccc_outcomes, crosswalk_csu_outcomes
   - Python: geocoding scripts (py/upstream/)
   - WHY off by default: produces static inputs, run once per data release
Phase 2: data_prep  [TOGGLE: do_data_prep = 0/1 per submodule]
   - acs/, schl_chars/, k12_postsec_distance/, prepare/, caschls_qoiclean/
Phase 3: sibling_xwalk  [TOGGLE: do_sibling = 1 if rerunning]
   - siblingmatch -> uniquefamily -> siblingpairxwalk -> siblingoutxwalk
Phase 4: samples  [TOGGLE: do_samples = 1]
   - caschls_pooling, caschls_demographics, sbac/touse_va, prior_decile_original_sample, etc.
Phase 5: VA estimation  [TOGGLE: do_va = 1]
   - score/, outcome/, pass_through/, merge_va_est, va_corr, heterogeneity/, etc.
   - This is the bulk of fork/do_all.do's do_va block
Phase 6: survey_va  [TOGGLE: do_survey_va = 1]
   - factoranalysis/, sibling_va_regs/, allvaregs
Phase 7: share/output (tabs + figures)  [TOGGLE: do_share = 1]
```

**Order rationale**: same as v1 (upstream → data prep → sibling crosswalk → samples → VA → survey VA → share). Breaks the "circular dependency" because the new order is linear in a single `main.do`.

---

## 5. ADRs (revised list)

| # | Slug | Decision |
|---|---|---|
| 0001 | consolidation-scope | In-scope: `cde_va_project_fork` (changes_by_che) + caschls (Dropbox). Out-of-scope: `ca_ed_lab-common_core_va` (superseded), `common_core_va_workflow_merge` (2022 abandoned). |
| 0002 | runtime-server-only | Pipeline runs on Scribe via SSH only. settings.do branches by `c(hostname)`. Local laptop is editor only. |
| 0003 | languages-stata-primary-python-upstream | Stata 17+ for production pipeline. Python is preserved for upstream geocoding scripts (py_files/ in predecessors → py/upstream/ in consolidated). Python is NOT on the production pipeline; preserved for completeness and record-keeping. R out of scope. |
| 0004 | sibling-xwalk-canonical-location | Sibling crosswalk lives at `do/sibling_xwalk/`. Includes siblingoutxwalk.do (relocated from caschls's siblingvaregs/). Runs as Phase 3 of main.do. |
| 0005 | pipeline-order | Phase ordering (upstream → data_prep → sibling_xwalk → samples → va → survey_va → share). Resolves cross-repo circularity. |
| 0006 | prior-score-policy-v1-canonical-v2-preserved | v1 is the prior-score-control variant used in the rejected paper; canonical for reproduction. v2 is preserved in code (loops kept active) for potential coauthor revisits, NOT reported. |
| 0007 | upstream-data-prep-convention | `do/upstream/` for Stata, `py/upstream/` for Python. Run once per data release; not on the production main.do. |
| 0008 | local-script-convention | `do/local/` for ad-hoc-but-keep scripts that ran on a local machine. Not on the production main.do. |
| 0009 | custom-vam-ado-handling | Custom-modified vam shrinkage package lives at `ado/`. settings.do does `adopath ++ "$projdir/ado"`. Modifications vs. upstream Stepner/Jepsen vam documented in `ado/README.md`. |
| 0010 | paper-source-of-truth | `~/github_repos/va_paper_clone/paper/common_core_va_v2.tex` stays canonical. va_consolidated/paper/ stays empty for this milestone. |
| 0011 | output-paths-mirror-paper-expectations | `figures/share/va/v1/` and `tables/share/va/pub/` mirror the paths the paper LaTeX expects. |
| 0012 | settings-do-hostname-branching | `if "\`c(hostname)'" == "scribe" { ... } else { ... }` pattern, with a clear error if neither branch matches. |
| 0013 | cohort-coverage-2014-15-to-2017-18 | Sample = 4 cohorts of 11th-graders, Spring 2015 through Spring 2018. Defined in macros_va.doh. |
| 0014 | entry-point-naming | `main.do` not `master.do`. Phase-out the "master" naming convention for historical sensitivity. |
| 0015 | stata-version-pin | Pin Stata 17 in settings.do for the duration of this consolidation. Revisit version compatibility as a follow-up TODO before any submission-readiness work. |
| 0016 | server-canonical-folder | Resolved during Phase 0 deep-read: which of the two server folders is canonical, what's stale, are they tracked by either local repo. ADR locked once the audit answers it. |

ADRs 0001-0006 + 0014 are foundational — write upfront before Phase 0 finishes.
ADRs 0007-0013 + 0015 are implementation-detail — write as each decision is locked in.
ADR 0016 is data-dependent — write after Phase 0 server-folder audit.

---

## 6. Phase 0: Deep-read audit (BLOCKING — must complete before any consolidation step)

**Christina's directive (verbatim):** "I want a deep read and in depth audit of EVERY SINGLE LINE OF EVERY SINGLE FILE before we lock in any design decisions and execute any consolidation steps. We MUST form a complete mental model of dependencies and what each line of code does before touching them."

This phase is a hard prerequisite. NO file moves, no consolidation commits, no folder restructuring until Phase 0 produces a complete dependency map and Christina signs off.

### 6.1 Scope

Every file referenced (transitively) by `caschls/do/master.do` or `cde_va_project_fork/do_files/do_all.do` after the audit dispositions are in place. Concretely:

| Bucket | File count (approx, post-audit) |
|---|---|
| caschls/do/ scripts on the production pipeline | ~80 |
| cde_va_project_fork/do_files/ scripts on the production pipeline | ~55 |
| .doh helper files in both | ~10 |
| caschls/do/ado/ custom vam package | 1-3 .ado files |
| py_files/ (upstream geocoding) in both predecessors | ~5-10 |
| do/upstream/ scripts (NSC/CCC/CSU crosswalks) | 3 |
| **Total** | **~150 files** |

Out of scope for Phase 0: archive/, debug/, check/ (we know they're not on the pipeline).

### 6.2 Per-file audit template

Each in-scope file gets one entry in the deep-read audit doc:

```markdown
### File: <repo>/<path/to/file>.do

**Predecessor location**: <which repo, original path>
**Owner**: Matt | Christina | both
**Pipeline phase** (target consolidated layout): Phase N (data_prep | sibling_xwalk | samples | va | survey_va | share)
**Lines**: <count>
**Purpose** (1 sentence):

**Inputs** (datasets read):
- $cleandir/cde/cst/<name>.dta
- ...

**Outputs** (datasets written, tables, figures):
- $projdir/dta/<path>.dta
- ...

**Sourced helpers** (.doh files):
- $vaprojdir/do_files/sbac/macros_va.doh
- ...

**Calls** (other do-files via `do`):
- ...

**Called by**:
- caschls/do/master.do (which block / line)

**Path references that need updating in consolidation**:
- $vaprojdir → $projdir
- $projdir/do/share/X → $projdir/do/<new-target>/X
- (any hardcoded /home/research/... paths)

**Stata version requirements / non-trivial syntax**:
- (e.g., uses Stata 17 frame syntax; uses regsave package; etc.)

**ssc/community packages used**:
- vam, estout, coefplot, ...

**Gotchas / non-obvious behavior** (line numbers):
- L<n>: <description>
- L<m>: <description>

**Reference to paper outputs**:
- Produces inputs to: Table X, Figure Y (per paper map)
- OR: helper / not directly producing paper outputs

**Notes / open questions**:
- ...
```

### 6.3 Phase 0 sub-deliverables

The deep-read audit produces multiple artifacts, all under `quality_reports/audits/`:

**Phase 0a — Per-file audit** (`2026-04-XX_deep-read-audit.md`):

Organized by target consolidated phase (so it doubles as the migration spec). One per-file entry per script using the template above.

**Phase 0b — Dependency graph** (`2026-04-XX_dependency-graph.md`):

A textual (and possibly Mermaid) graph of which scripts feed which. Identifies:
- Any remaining circular references (we believe there are none after the new pipeline order, but verify).
- Critical-path scripts (failure here breaks downstream chains).
- Orphans (scripts that aren't callers and aren't called — should already be archived; verify zero remain).

**Phase 0c — Path-reference catalog** (`2026-04-XX_path-references.md`):

Every distinct path expression appearing in any in-scope file:
- `$projdir/...`, `$vaprojdir/...`, `$cleandir/...`, `$rawdir/...`, hardcoded `/home/research/...`
- For each, what it currently resolves to and what it should resolve to in the consolidated layout.
- This is the spec for the path-translation pass during migration.

**Phase 0d — Server-folder reconciliation** (`2026-04-XX_server-folders.md`):

Resolves the open question of which server folders hold which code, and which is canonical. Christina runs the diagnostic commands on Scribe and shares output:

```bash
ls -la /home/research/ca_ed_lab/projects/common_core_va/    # candidate canonical folder
ls -la /home/research/ca_ed_lab/users/chesun/gsr/caschls/  # alternate location referenced in fork's do_all.do
ls -la /home/research/ca_ed_lab/msnaven/                    # Matt's home dir referenced in Naven readme
# any other locations Christina knows about
```

Plus diff against local repos (file-count, last-modified). Output: which folder is canonical for each predecessor, where to push the consolidated repo to.

**Phase 0e — Pre-migration design lock** (`2026-04-XX_design-lock.md`):

Synthesized from 0a-0d:
- Final folder structure (corrected for any surprises in 0a-0c)
- Final ADR list with proposed text
- siblingoutxwalk relocation decision (after dependency trace in 0b)
- Updated estimate of migration commit count + time
- Christina signs off (or revises)

### 6.4 Phase 0 execution method

Christina's M1 preference: cautious for VA core, aggressive for data prep / cleaning. Translating to deep-read pace:

- **Cautious deep-read** (10-15 min/file, line-by-line annotation): VA estimation core (`do/va/`), survey-VA regs (`do/survey_va/`), the custom vam .ado, settings.do, helpers.
- **Aggressive deep-read** (3-5 min/file, header + outputs + dependencies, skim body): data prep (acs/, schl_chars/, prepare/, qoiclean/), sample construction, share/check helpers.

Time estimate (rough, depends on focus blocks):
- 30 cautious files × 12 min = 6 hours
- 100 aggressive files × 4 min = 6.5 hours
- Server-folder audit + dependency graph synthesis: 3-4 hours
- Pre-migration design lock: 1-2 hours
- **Total Phase 0: ~16-20 hours of focused work**, spread across 4-7 sessions.

### 6.5 Phase 0 commit cadence

Per atomic discipline:
- One commit per "audit chunk" (e.g., "audit: settings.do + macros_va.doh", "audit: do/va/score/* (5 files)", "audit: do/survey_va/factoranalysis/* (8 files)").
- Each commit appends to the audit doc; doc grows incrementally.
- Christina can review chunks as they land rather than at the end.

---

## 7. Phase 1+: Migration (post-Phase 0)

After Phase 0e (design lock) and Christina's approval, Phase 1 begins.

### 7.1 Migration approach

Confirmed from v1: **Option B — copy + register without preserving predecessor history**. Predecessor repos stay intact for archeology. Each script gets a header comment in the consolidated copy:

```stata
/*
* Originally <repo>/<path> at predecessor commit <SHA>.
* Full predecessor history preserved in the predecessor repo.
* Audit entry: quality_reports/audits/2026-04-XX_deep-read-audit.md#<anchor>
*/
```

### 7.2 Migration sequence

Bottom-up dependency order (foundation → consumers). Each step is one or a few atomic commits:

1. **Foundation** — settings.do, ado/, main.do skeleton (toggles only). [1 commit]
2. **Helpers** — macros_va.doh, vafilemacros.doh, create_prior_scores_v1.doh, v2.doh, vam_*.doh. [1-2 commits]
3. **Upstream** — Stata crosswalks + Python geocoding. [1-2 commits]
4. **Data prep** — acs, schl_chars, k12_postsec_distance, prepare, qoiclean. [~5 commits]
5. **Sibling crosswalk** — 4 (or 5) scripts. [1 commit]
6. **Samples** — caschls pooling/demographics, sbac sample creation, prior_decile. [1-2 commits]
7. **VA estimation** — score, outcome, pass-through, heterogeneity. [3-4 commits]
8. **Survey VA** — factoranalysis, sibling_va_regs, allvaregs. [2-3 commits]
9. **Share/output** — tab and figure helpers. [1 commit]
10. **Check/debug/explore** — copy as-is for completeness. [1 commit]
11. **Wire main.do** — toggle blocks call all phases. [1 commit]
12. **Path translation pass** — replace `$vaprojdir` → `$projdir` etc. globally per Phase 0c spec. [1 commit; possibly broken into chunks]
13. **README + ADRs** — write the 16 ADRs and update README. [several small commits]

Estimated commits: ~30-35.
Estimated time post-Phase 0: 2-3 weeks of focused work.

### 7.3 Per-file migration ritual

For each script being migrated:

1. Read the corresponding Phase 0 audit entry (already written).
2. `cp` from predecessor to target consolidated path.
3. Apply path translations per Phase 0c.
4. Add the predecessor-pointer header comment.
5. Verify Stata syntax with `do <script.do>` on Scribe (Christina runs; logs back).
6. If the script reads/writes a dataset that's been moved, verify upstream/downstream pieces are coherent.

---

## 8. settings.do design

Same as v1, with Stata-version-pinning policy added per Q5:

```stata
*======================================================================
* settings.do — Common Core VA Project consolidated codebase
*======================================================================

clear all
set more off
set varabbrev off
cap log close _all

* --- hostname branching ---
local h = c(hostname)

if "`h'" == "scribe" {
    global projdir   "/home/research/ca_ed_lab/projects/common_core_va"
    global rawdir    "/home/research/ca_ed_lab/data/restricted_access/raw"
    global cleandir  "/home/research/ca_ed_lab/data/restricted_access/clean"
}
else {
    display as error "settings.do: hostname `h' not recognized."
    display as error "Currently supported: scribe (UC Davis SSDS)."
    display as error "Add a new branch above if you're running on a new host."
    exit 198
}

* --- ado path for custom vam ---
adopath ++ "$projdir/ado"

* --- ssc package install failsafe ---
foreach pkg in vam estout coefplot fwildclusterboot {
    cap which `pkg'
    if _rc {
        display as text "Installing missing ssc package: `pkg'"
        cap ssc install `pkg', replace
    }
}

* --- Stata version pin ---
* Server has drifted 16 -> 17 -> 18. Pinned to 17 for the duration of this
* consolidation. Revisit version compatibility as a follow-up TODO before
* any submission-readiness work. See ADR-0015.
version 17

display as text "settings.do loaded; project root = $projdir"
```

---

## 9. Verification plan

### 9.1 During Phase 0 (deep-read)

Every audit chunk reviewed by Christina before the next chunk starts. Catches misreadings early.

### 9.2 During Phase 1+ (migration)

Per `verification-protocol.md`:

- After each migration commit, spot-check the moved scripts run on Scribe (Christina executes; logs returned).
- After each phase complete, run that phase end-to-end and verify outputs exist with non-zero size.

### 9.3 Server reconciliation (cross-cutting)

The two-folder server question (Section 2 + Phase 0d) resolves *what to push the consolidated repo to* and *what to validate against*. Two scenarios:

- **If one folder is canonical and the other is stale**: push consolidated to the canonical location; archive the stale folder on the server (rename to `<old-name>_pre_consolidation_<date>` or similar).
- **If both folders are jointly necessary** (e.g., one holds Christina's working state, one holds Matt's older state): the consolidation absorbs both. Decide via ADR-0016 which lives where in the new layout, then archive the originals.

### 9.4 End-to-end verification

After full consolidation:

- Run `main.do` end-to-end on Scribe with all phase toggles on.
- Compare every paper table and figure against original outputs (tolerance per `replication-protocol.md`).
- Document mismatches in `quality_reports/replication_report.md`.
- Debug to root cause; re-run; confirm match.

### 9.5 Final pass

- `verifier` agent in standard mode: paper compiles, all references resolve, figures exist.
- Update README, CLAUDE.md, decisions/.

---

## 10. Risks / unknowns

- **Bit-rot** (last full run 2023): Stata version drift (16→17→18), `ssc install` package updates, server filesystem moves. Budget ~30% of time for debugging unknown breaks.
- **NSC linkage opacity**: Matt did the original NSC linkage. Cleaned NSC dataset is a static input. Risk: if Scribe's NSC dta has been updated since 2023, results may shift. Mitigation: verify NSC dta timestamp before claiming reproduction.
- **Geocoding script availability**: now confirmed in `py_files/` and preserved in `py/upstream/`. Risk if the geocoded outputs disappear from Scribe — but they should be static. Verify presence early in Phase 0.
- **Custom vam package compatibility**: `ado/` modifications may have been made against an older vam version. If we need to upgrade vam (e.g., Stata 18 syntax), modifications need to be re-applied. Mitigation: document modifications precisely in `ado/README.md` early.
- **Cross-repo path references**: Both predecessors use `$projdir` (caschls) and `$vaprojdir` (fork). Consolidated will use just `$projdir`. Risk: a script in the fork that hardcodes `$vaprojdir/...` won't work after migration. Mitigation: Phase 0c path-reference catalog drives the global replacement.
- **siblingoutxwalk relocation**: moving from `siblingvaregs/` to `sibling_xwalk/` could introduce a new circular reference if `siblingvaregs/` siblings reference it via relative paths. Mitigation: dependency trace in Phase 0b BEFORE relocating.
- **Two-folder server divergence**: if the two server folders contain genuinely different code (not just one stale copy), reconciliation is harder than just picking the newer one. Mitigation: full diff in Phase 0d; ADR-0016 documents the decision.
- **Senior-coauthor course-correction**: paper in limbo pending coauthor decision. They might come back with R&R-style requests changing scope. Mitigation: keep v1 + v2 alive; build flexibility.

---

## 11. Out of scope (explicit)

- AEA replication-package readiness (`replication-protocol.md` Phase 5)
- openICPSR deposit / DOI assignment
- Overleaf-sync automation (paper stays in `va_paper_clone`)
- Migrating `master_supporting_docs/` from either predecessor
- Notebook / Quarto / Markdown reports for non-paper outputs
- Adding R pipeline pieces (Stata-primary; Python upstream-only per ADR-0003)
- Gitignore hygiene for caschls (`.DS_Store`, `Icon\r` macOS noise)

---

## 12. Resolved questions from v1 + new questions

**Resolved (Christina v2 review):**

- Q1: do/ at root (no scripts/ parent). py/ at root for upstream geocoding.
- Q2: subdir granularity by analytic concern — agreed.
- Q3: helpers under do/va/helpers/ — agreed.
- Q4: main.do (not master.do). Colocate settings.
- Q5: pin Stata 17; add version-compat revisit to TODO.
- Q6: copy custom vam as-is + ado/README.md.
- M1: cautious VA core, aggressive data-prep — agreed; mapped onto Phase 0 deep-read pace.
- M2: ADR-0001 through 0006 + 0014 upfront; rest as decisions lock.
- M3: laptop edit → manual sync → Scribe SSH run → log back — agreed.
- Migration option: copy + register, drop subtree history — agreed.

**New questions opened by v2:**

- **N1: siblingoutxwalk relocation** — must wait for Phase 0b dependency trace; do NOT pre-decide.
- **N2: Server-folder reconciliation** — must wait for Phase 0d; ADR-0016 then locks the canonical location.
- **N3: Stata version compat revisit** — when do we revisit? After consolidation completes? After first end-to-end success? Christina's call. Default: after consolidation Phase 1 completes and we have a known-working pipeline on Stata 17, before any push to other use cases.

---

## 13. TODO list updates (proposed for project root TODO.md)

Items to add or move:

**Active (doing now):**
- [ ] Phase 0 deep-read audit (this plan, Section 6).

**Up Next:**
- [ ] Phase 1 migration (per Section 7.2 sequence).

**Backlog:**
- [ ] Stata version compatibility revisit: after consolidation completes, evaluate what's needed to support Stata 18 on Scribe.
- [ ] Gitignore hygiene in caschls (.DS_Store, Icon\r noise — separate cleanup).
- [ ] AEA replication package (post-consolidation; out-of-scope for the 3-month milestone).

---

## 14. Next concrete step

Once Christina approves this v2 plan:

1. Update CLAUDE.md folder structure (drop `scripts/`, add `do/`, `py/`, `ado/`, `main.do`, `settings.do` at root).
2. Write ADR-0001 through ADR-0006 + ADR-0014 (foundational decisions).
3. **Begin Phase 0a deep-read** starting with the highest-leverage chunk:
   - settings.do (both predecessors) — sets the path conventions everything else inherits
   - macros_va.doh — defines the variable-naming convention referenced everywhere
   - The custom vam .ado file(s) in caschls/do/ado/ — defines the shrinkage estimator
   - main.do / master.do entry-points (caschls + fork) — gives the call graph
4. Ping Christina after each chunk for review.
5. Continue Phase 0a-0d.
6. Phase 0e design lock.
7. Phase 1 migration begins.

---

## 15. Appendix: deferred deep-read targets (D1-D5 from context dump)

Will be addressed during Phase 0:

- D1 sibling matching specifics → `siblingmatch.do` deep-read
- D2 NSC linkage method → `do/upstream/crosswalk_nsc_outcomes.do` deep-read
- D3 distance computation → `do/data_prep/k12_postsec_distance/` deep-read
- D4 SE clustering → cross-cutting scan during VA-core deep-read (cautious mode)
- D5 vam modifications → `caschls/do/ado/` deep-read in Phase 0a (highest priority)

End of plan v2 draft.
