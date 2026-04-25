# Consolidation Plan — Common Core VA Project

**Status:** DRAFT (Claude proposing; awaiting Christina's review and corrections)
**Author:** Christina Sun (with Claude)
**Date drafted:** 2026-04-25
**Deadline:** ~2026-07-24 (3 months from project kickoff 2026-04-24)

---

## 1. Goal (recap)

Per `quality_reports/session_logs/2026-04-24_project-onboarding.md` and the user's confirmed definition of done, the consolidation must hold all three:

1. **Reproduces the rejected paper end-to-end**: from raw CAASPP/SBAC + roster on Scribe to every table and figure in `~/github_repos/va_paper_clone/paper/common_core_va_v2.tex`. Single master script that runs to completion.
2. **Resolves the sibling/VA dependency cleanly**: one canonical pipeline order, no circular references, no duplication between caschls and the fork.
3. **Survives a future-me audit in 5 years**: ADRs in `decisions/`, file dictionary, comments documenting non-obvious choices.

**NOT in scope for this milestone:** AEA replication-package readiness, openICPSR deposit, Overleaf-sync automation. These are post-consolidation follow-ups.

---

## 2. Inputs (what we know going in)

After 5 rounds of context-dump Q&A and the master-file audit:

- **Two predecessor repos**: `~/github_repos/cde_va_project_fork` (changes_by_che branch) and `caschls` at the Dropbox path. Both inventories are now known-complete after the audit (`quality_reports/reviews/2026-04-25_master-file-audit.md`).
- **Paper as single source of truth**: 1357-line draft, indexed in `quality_reports/reviews/2026-04-24_paper-map.md`. Six load-bearing pipelines must reproduce: sample creation, sibling crosswalk, prior-score creation (v1), VA estimation + drift, validity/heterogeneity/pass-through, CalSCHLS index + survey-VA regressions.
- **Runtime**: Scribe server only (`Scribe@ssds.ucdavis.edu`, `c(hostname)="scribe"`, project root `/home/research/ca_ed_lab/projects/common_core_va`, Stata 17 currently — was 16, now 18 in some areas; Stata version drift acknowledged).
- **Languages**: Stata only. py_files/ is dead in both predecessors.
- **Currently-known pipeline order** (from `master.do` toggles in caschls):
  1. `caschls/master.do` — sibling-matching block (4 do-files: `siblingmatch`, `uniquefamily`, `siblingpairxwalk`, `siblingoutxwalk`)
  2. `cde_va_project_fork/do_all.do` — full VA estimation pipeline
  3. `caschls/master.do` — survey indices + survey-VA regressions
- **vam shrinkage**: custom-modified version in `caschls/do/ado/`. Must be preserved.
- **v1 + v2 prior-score loops**: both preserved (v1 canonical for paper; v2 kept for potential future use).

---

## 3. Target folder structure (PROPOSAL — please react)

The va_consolidated template currently has the applied-micro layout (paper/, scripts/, data/, etc.). I propose adapting it to the project's actual needs as follows:

```
va_consolidated/
├── CLAUDE.md, README.md, LICENSE, MEMORY.md, TODO.md
├── SESSION_REPORT.md, .claude/SESSION_REPORT.md
├── .claude/                       # rules, hooks, skills, state
├── decisions/                     # ADRs (NNNN_slug.md, append-only)
├── quality_reports/               # plans, session logs, reviews, audits
├── master_supporting_docs/        # literature/ + reading_notes/
│
├── master.do                      # SINGLE entry point — runs everything
├── settings.do                    # hostname-branched paths
├── ado/                           # custom-modified vam package + any other custom .ado
│
├── do/                            # Stata pipeline (mirrors current caschls "do/" terminology)
│   ├── _archive/                  # historical, not in pipeline
│   ├── upstream/                  # data prep that produces static project inputs
│   │   ├── crosswalk_nsc_outcomes.do      # from fork
│   │   ├── crosswalk_ccc_outcomes.do      # from caschls
│   │   └── crosswalk_csu_outcomes.do      # from caschls
│   ├── local/                     # local-machine ad-hoc keepers (e.g., enrollmentconvert)
│   ├── sibling_xwalk/             # the 4 sibling-crosswalk scripts (currently in caschls/do/share/siblingxwalk/)
│   │   ├── siblingmatch.do
│   │   ├── uniquefamily.do
│   │   ├── siblingpairxwalk.do
│   │   └── siblingoutxwalk.do
│   ├── data_prep/                 # cleaning + sample construction
│   │   ├── acs/                   # ACS census tract cleaning
│   │   ├── schl_chars/            # school characteristics cleaning (11 files from fork)
│   │   ├── k12_postsec_distance/  # college proximity
│   │   ├── prepare/               # caschls build/prepare/* (enrollmentclean, renamedata, etc.)
│   │   └── caschls_qoiclean/      # caschls QOI cleaning (parent/secondary/staff x cohort)
│   ├── samples/                   # caschls build/sample/* + fork sbac sample construction
│   │   ├── caschls_pooling/       # pool surveys (parent/sec/staff)
│   │   ├── caschls_demographics/  # demographics + coverage
│   │   └── sbac/                  # touse_va, create_score_samples, create_out_samples, prior_decile_original_sample
│   ├── va/                        # VA ESTIMATION (the heart of the project)
│   │   ├── helpers/               # macros_va.doh, create_va_sample.doh, create_prior_scores_v1.doh, create_prior_scores_v2.doh, vafilemacros.doh
│   │   ├── score/                 # va_score_all, va_score_fb_all, va_score_fb_test_tab, va_score_spec_test_tab, va_score_sib_lag
│   │   ├── outcome/               # va_out_all, va_out_fb_all, va_out_fb_test_tab, va_out_spec_test_tab, va_out_sib_lag
│   │   ├── pass_through/          # reg_out_va_all, reg_out_va_dk_all, reg_out_va_*_tab, reg_out_va_*_fig
│   │   ├── heterogeneity/         # va_corr_schl_char, persist_het_student_char_fig
│   │   └── merge_va_est.do, va_corr.do, va_spec_fb_tab.do, va_var_explain.do, va_var_explain_tab.do
│   ├── survey_va/                 # caschls share/factoranalysis/* + share/svyvaregs/*
│   │   ├── factoranalysis/        # alpha, factor, allsvyfactor, allsvymerge, imputation, imputedcategoryindex, indexalpha, etc.
│   │   ├── sibling_va_regs/       # caschls share/siblingvaregs/* (~17 do-files)
│   │   └── allvaregs.do
│   ├── share/                     # generic-purpose tab/figure helpers (kdensity, sample_counts_tab, va_scatter, etc.)
│   ├── check/                     # verification utilities (sum_stats_check, gradetab, etc.)
│   ├── debug/                     # ad-hoc debug
│   └── explore/                   # exploratory (predicted-score work, etc.)
│
├── data/
│   ├── raw/                       # gitignored on disk; documented in README
│   └── cleaned/                   # gitignored; intermediate dta outputs
├── output/                        # logs and intermediate non-paper outputs
├── figures/                       # final figures (referenced by paper)
│   ├── share/                     # most paper figures land here (subdirectory matches what paper expects)
│   └── ... (mirrors paper's expected paths: share/va/v1/, share/va/v2/, share/survey/)
├── tables/                        # final tables (referenced by paper)
│   └── share/                     # similarly mirrors paper paths: share/va/pub/, share/survey/pub/
├── log/                           # log files
└── paper/                         # paper sources (deferred — NOT moving paper draft into va_consolidated for this milestone; va_paper_clone stays canonical)
```

### Open design questions on folder layout

**Q1: do/ vs scripts/stata/?**

The va_consolidated template uses `scripts/stata/`. Both predecessors use `do/`. I propose **`do/`** because:
- Lower migration cost (no rename of every reference)
- Matches what's on Scribe currently (`$projdir/do/...` paths in caschls; `$vaprojdir/do_files/...` in fork — but we'd be unifying anyway)
- "do" is canonical Stata terminology

But `scripts/stata/` is the va_consolidated template default, signalling a multi-language repo. Do you want flexibility for future Python/R additions, or commit to Stata-only?

**Q2: subdirectory granularity**

I've proposed grouping by analytic concern (data_prep, samples, va, survey_va, etc.) rather than by predecessor (caschls/, fork/). The grouping is denser than either predecessor used. Is that the right level, or do you want more / fewer subdirectories?

**Q3: helpers (.doh files)**

Both predecessors mix `.doh` includes alongside `.do` files in the same dirs. I've proposed putting them under `do/va/helpers/` together. Alternative: keep them next to the do-files that use them (closer to current state) but rely on consistent naming. Preference?

**Q4: master.do at root vs do/master.do?**

Caschls has `do/master.do`. The fork has `do_files/do_all.do`. va_consolidated template uses scripts/stata/. I'd put `master.do` at the repo root since it's the entry point (and you call `do master.do` once). settings.do co-located with it. Agree?

---

## 4. Pipeline ordering (PROPOSAL)

Single master.do that toggles each phase. Phase blocks:

```
Phase 0: settings.do (paths, hostname branching, version, ssc install failsafe)
Phase 1: upstream  [TOGGLE: do_upstream = 0]
   - crosswalk_nsc_outcomes.do, crosswalk_ccc_outcomes.do, crosswalk_csu_outcomes.do
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
   - sample_counts_tab, va_spec_fb_tab_all, var_explain_tab, kdensity, etc.
```

**Why phase-toggle pattern:** this is what both predecessors use today. Familiar to you. Makes targeted re-runs trivial (`do_va = 1` only re-does estimation; everything else stays fixed).

**Order rationale:**

- Upstream first (rarely re-run)
- Data prep before samples (cleaning before construction)
- Sibling crosswalk after data prep (it depends on cleaned CST data) but BEFORE samples that need sibling-restricted variants
- Samples include the sibling-restricted samples as well as the base/restricted samples
- VA estimation reads cleaned + sample-restricted dtas
- Survey VA reads VA estimates + cleaned QOI data
- Share/output runs last to produce final tab/fig outputs

This breaks the "circular dependency" because the new order is clean: sibling_xwalk produces its outputs, those feed into samples and VA estimation, which then feeds into survey_va. The original circularity was an artifact of the two repos calling each other; with a single master, it disappears.

---

## 5. ADRs (substantive decisions to record in decisions/)

Each gets a numbered file in `decisions/`. Ordering by importance:

| # | Slug | Decision |
|---|---|---|
| 0001 | consolidation-scope | In-scope: `cde_va_project_fork` (changes_by_che) + caschls (Dropbox). Out-of-scope: `ca_ed_lab-common_core_va` (superseded), `common_core_va_workflow_merge` (2022 abandoned). |
| 0002 | runtime-server-only | Pipeline runs on Scribe via SSH only. settings.do branches by `c(hostname)`. Local laptop is editor only. |
| 0003 | languages-stata-only | Stata 17+. py_files/ in both predecessors is dead. R out of scope. |
| 0004 | sibling-xwalk-canonical-location | Sibling crosswalk lives at `do/sibling_xwalk/` in the consolidated repo (originally in caschls/do/share/siblingxwalk/). Runs as Phase 3 of the master. |
| 0005 | pipeline-order | Phase ordering (upstream → data_prep → sibling_xwalk → samples → va → survey_va → share). Resolves the cross-repo circularity. |
| 0006 | prior-score-policy-v1-canonical-v2-preserved | v1 is the prior-score-control variant used in the rejected paper; canonical for reproduction. v2 is preserved in code (loops kept active) for potential coauthor revisits, NOT reported. |
| 0007 | upstream-data-prep-convention | `do/upstream/` for scripts that produce static project inputs (NSC, CCC, CSU crosswalks). Run once per data release; not on the production master. |
| 0008 | local-script-convention | `do/local/` for ad-hoc-but-keep scripts that ran on a local machine (e.g., enrollmentconvert). Not on the production master. |
| 0009 | custom-vam-ado-handling | Custom-modified vam shrinkage package lives at `ado/` in the repo. settings.do does `adopath ++ "$projdir/ado"` so Stata picks it up. Document the modifications vs. upstream Stepner/Jepsen vam. |
| 0010 | paper-source-of-truth | `~/github_repos/va_paper_clone/paper/common_core_va_v2.tex` stays canonical for the paper draft (cloned from Overleaf). va_consolidated/paper/ stays empty for this milestone; revisit post-consolidation. |
| 0011 | output-paths-mirror-paper-expectations | `figures/share/va/v1/` and `tables/share/va/pub/` in va_consolidated mirror the paths the paper LaTeX expects, so paper compilation just works after symlinking. |
| 0012 | settings-do-hostname-branching | `if "\`c(hostname)'" == "scribe" { ... } else { ... }` pattern in settings.do, with a clear error if neither branch matches. |
| 0013 | cohort-coverage-2014-15-to-2017-18 | Sample = 4 cohorts of 11th-graders, Spring 2015 through Spring 2018. Defined in macros_va.doh. |

These are NOT all written yet — listing here so we know the surface area. We'll write them incrementally as each decision is locked in during implementation.

---

## 6. Migration strategy

The cleanest mental model: **va_consolidated absorbs both predecessors via `git mv` → repo-relative-path translations**, preserving git history for every script that survives.

Two mechanical options:

### Option A: subtree-merge each predecessor

Use `git subtree add` to bring each predecessor's history into va_consolidated as a subtree, then `git mv` files into their target locations. Preserves full commit history of every file.

Pros: full history; tools like `git log --follow` keep working.
Cons: complex; subtree merges are awkward; doubles repo size.

### Option B: copy + register, drop history (RECOMMENDED)

Treat the predecessor repos as read-only references. Copy each load-bearing file into va_consolidated at its target path with a single import commit per logical group. Add a header comment in each script: `// Originally cde_va_project_fork/do_files/sbac/touse_va.do at commit <SHA>; full predecessor history preserved in that repo.`

Pros: simple; clean history that matches the new structure; predecessor repos remain intact for archeology.
Cons: `git log --follow` won't trace into the predecessor.

I recommend Option B. The predecessor repos aren't going anywhere; they remain accessible for any historical questions. The consolidated repo's history starts fresh and is *about* the consolidated project, not the messy past.

### Migration sequence (proposed)

Each step is one commit (or a few atomic commits). Implement bottom-up so dependencies are in place before consumers:

1. **Foundation**: settings.do skeleton, ado/ directory with custom vam, master.do skeleton (just toggles, no calls yet). [1 commit]
2. **Helpers**: copy macros_va.doh, vafilemacros.doh, create_prior_scores_v1.doh, create_prior_scores_v2.doh, etc. [1 commit per logical group]
3. **Upstream**: crosswalk_nsc_outcomes, crosswalk_ccc_outcomes, crosswalk_csu_outcomes. [1 commit]
4. **Data prep**: ACS, schl_chars, k12_postsec_distance, prepare, qoiclean. [1 commit per submodule, ~5 commits]
5. **Sibling crosswalk**: 4 scripts. [1 commit]
6. **Samples**: caschls pooling/demographics, sbac sample creation, prior_decile. [1-2 commits]
7. **VA estimation**: score, outcome, pass-through, heterogeneity, helpers. [3-4 commits]
8. **Survey VA**: factoranalysis, sibling_va_regs, allvaregs. [2-3 commits]
9. **Share/output**: tab and figure helpers. [1 commit]
10. **Check/debug/explore**: copy as-is for completeness. [1 commit]
11. **Master.do**: wire up all the phase blocks. [1 commit]
12. **README + ADRs**: write the 13 ADRs and update README. [several small commits]

Estimated commit count: ~30. Estimated time, with deep-reading each script before move: 2-4 weeks of focused work. Faster if some scripts can be moved without re-reading; slower if any of them break or have subtle dependencies.

---

## 7. settings.do design (PROPOSAL)

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
* When packages drift, prefer to fail loudly rather than silently use stale versions.
* Use cap to avoid hard failure if package is already installed.
foreach pkg in vam estout coefplot fwildclusterboot {
    cap which `pkg'
    if _rc {
        display as text "Installing missing ssc package: `pkg'"
        cap ssc install `pkg', replace
    }
}

* --- Stata version pin ---
* Was 16, now 17 on Scribe (drift to 18 in some areas). Pinning to 17 for reproducibility.
* If you need to upgrade, document in decisions/ and run end-to-end verification.
version 17

* --- bookkeeping ---
display as text "settings.do loaded; project root = $projdir"
```

### Open Q on settings.do

**Q5**: should the production runs pin `version 17` (current canonical) or follow the server's current Stata? Pinning is more reproducible but might cause friction if Stata upgrades and packages need newer syntax. Recommendation: pin 17 with a comment about how to revisit.

**Q6**: ado/ directory — copy the custom vam from caschls/do/ado/ as-is, or make modifications? I'd copy as-is and document the differences from upstream Stepner/Jepsen vam in `ado/README.md`. Verify the package version + commit hash if possible.

---

## 8. Verification plan

Per `verification-protocol.md`:

### After each migration commit

- Compile or run the moved scripts (where possible — air-gapped means user runs on Scribe and shares logs)
- Verify output paths match what the paper expects
- Spot-check 2-3 estimates against paper values

### After full consolidation

- Run end-to-end on Scribe from `master.do` with all phase toggles on
- Compare every paper table and figure against the original outputs (tolerance per `replication-protocol.md`: integers exact, point estimates < 0.01 diff, SEs < 0.05 diff)
- Document mismatches in `quality_reports/replication_report.md`
- If anything mismatches, debug to root cause before declaring done

### After every-table-and-figure passes

- Final pass: `verifier` agent in standard mode checks paper compiles, all references resolve, figures exist
- Update README, CLAUDE.md, decisions/ with final state

---

## 9. Risks / unknowns

- **Bit-rot**: last full run was 2023. Stata version drift, `ssc install` package updates, server filesystem moves. We'll discover broken pieces during verification. Budget ~30% of time for debugging unknown breaks.
- **NSC linkage opacity**: Matt did the original NSC linkage, you don't know how. The cleaned NSC dataset is a static input. Risk: if Scribe's NSC dta has been updated since 2023, results may shift. Mitigation: verify NSC dta timestamp before claiming reproduction.
- **Geocoding script availability**: you said the geocoding file is at the upstream/ level for record-keeping, but Matt did the actual run. Risk if we need to re-geocode (we shouldn't, since the geocoded outputs are static) — but worth verifying the geocoded dta exists on Scribe.
- **Custom vam package compatibility**: the `ado/` modifications may have been made against an older vam version. If we need to upgrade vam (e.g., for Stata 18 syntax compatibility), the modifications need to be re-applied. Mitigation: document the modifications precisely in `ado/README.md` early.
- **Cross-repo path references**: Both predecessors use `$projdir` (caschls) and `$vaprojdir` (fork). Consolidated will use just `$projdir`. Risk: a script in the fork that hardcodes `$vaprojdir/...` won't work after migration unless we systematically replace `$vaprojdir` → `$projdir`. Mitigation: grep for `$vaprojdir` after migration; replace; re-test.
- **Senior-coauthor course-correction risk**: paper is in limbo pending coauthor decision. They might come back with R&R-style requests that change scope. Mitigation: keep v1 + v2 both alive; build flexibility into the structure.

---

## 10. Out of scope (explicit)

- AEA replication-package readiness (`replication-protocol.md` Phase 5)
- openICPSR deposit / DOI assignment
- Overleaf-sync automation (paper stays in `va_paper_clone` clone)
- Migrating `master_supporting_docs/` from either predecessor (lit notes are sparse; can be back-filled later if needed)
- Notebook / Quarto / Markdown reports for non-paper outputs
- Adding R or Python pipeline pieces (Stata-only per ADR-0003)
- Gitignore hygiene for caschls (`.DS_Store`, `Icon\r` macOS noise — separate cleanup)

---

## 11. What I want from you before we start implementing

Six design questions are flagged Q1-Q6 above. Plus three meta-questions:

**M1: Aggressive vs. cautious migration pace?**

Aggressive: bulk-move large chunks per commit, verify only at the end. Faster but high-cost-of-failure debug.
Cautious: per-script reading + small commits, verify each. Slower but each break is local.

I'd lean cautious for the VA-estimation core (where bugs would be subtle and high-impact) and aggressive for the data-prep / cleaning chunks (where re-reading offers little value beyond what the audit + paper map already gave us).

**M2: Do you want me to write the ADRs upfront (before any code moves) or as each decision is locked in during implementation?**

Upfront pros: forcing function for decisions; no half-baked migrations.
As-needed pros: less throwaway work if a decision changes during implementation.

I'd lean as-needed for ADR-0007 onward (implementation details) and upfront for ADR-0001 through ADR-0006 (foundational).

**M3: Where do you want me to verify? The audit and the paper map both live in va_consolidated. The actual code lives on Scribe. The migration target is va_consolidated/do/ which itself just lives on your laptop. Plan: each commit goes to va_consolidated locally; you copy/sync to Scribe; you run; you share logs back.**

Is that right, or do you have a different sync workflow in mind (e.g., a Stata IDE that pushes to Scribe automatically)?

---

## 12. Next concrete step (if plan is approved)

Once you've reviewed and corrected this plan:

1. Lock in folder structure (Q1-Q4) and ADR-0001 through ADR-0006.
2. Write ADR-0001 through ADR-0006 in `decisions/`.
3. Create the empty target folder structure with `.gitkeep` files (one commit).
4. Migrate the foundation: settings.do, ado/, master.do skeleton (one commit).
5. Begin migration sequence per Section 6.

---

## 13. Appendix: things deferred for now

- D1-D5 (deep-read discoveries from context dump Section 10D): I'll handle these as I encounter each script during migration. Specifically:
  - D1 sibling matching specifics (handling of moves / surname change / typos): inspect `siblingmatch.do` during sibling_xwalk migration
  - D2 NSC linkage method: should be transparent during upstream/ migration (script is now at `do/upstream/crosswalk_nsc_outcomes.do`)
  - D3 distance computation: inspect `do_files/k12_postsec_distance/` during data_prep migration
  - D4 SE clustering: scan all VA-estimation scripts for `vce(cluster ...)` usage during VA migration
  - D5 vam modifications: inspect `caschls/do/ado/` early, document in `ado/README.md`

End of plan draft.
