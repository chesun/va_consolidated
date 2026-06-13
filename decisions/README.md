# Design Decisions Log

An append-only record of substantive research, design, and methodology decisions for this project. Each entry is an **ADR** (Architecture Decision Record, borrowed from software engineering): short, dated, immutable.

This log is the *record*. Analysis docs in `quality_reports/` are the *reasoning*. When we need to know **what** was decided, read here. When we need to know **why** in depth, follow the Sources link.

**Rule:** `.claude/rules/decision-log.md`.

---

## Rules

1. **One decision per file.** Numbered `NNNN_short-slug.md`, zero-padded to four digits.
2. **Never edit a Decided entry.** If the decision changes, write a new ADR whose Status is `Decided` and whose header links the prior entry: `Supersedes: #0008`. Then edit the old entry's Status to `Superseded by #NNNN`. The body of the old entry stays.
3. **Proposed entries may be edited** until they become Decided. Once Decided, rule 2 applies.
4. **Reference by number.** In session logs, analysis docs, and commit messages, cite decisions as `ADR-0008`. This is durable across file renames.
5. **Data quality flag is required.** "Full context" = source docs contain explicit reasoning. "Reconstructed — partial context" = date and decision are clear, but reasoning was retrofitted. Future-you needs to know which.
6. **Scope is a recommended field.** Each decision serves a specific component of the research — tagging the scope helps prevent conflating unrelated decisions and makes the log navigable by theme.

## Decision components

Tag each ADR with a single scope. Suggested categories depend on the research paradigm:

**Behavioral / experimental projects:**

- **Research framing** — what the paper is about; hypothesis choices.
- **IC foundation** — theoretical assumptions that make the mechanism incentive-compatible.
- **Behavioral theory** — frameworks explaining *why* subjects fail or succeed.
- **Experimental design** — arm structure, treatments, controls, instruments.
- **Methodology** — analysis metrics, ε tolerances, format choices, instructions.

**Applied micro / reduced-form projects:**

- **Research framing** — question, outcome, population.
- **Identification** — source of exogenous variation, exclusion restriction, parallel trends.
- **Data** — sample construction, restrictions, merges, cleaning rules.
- **Specification** — functional form, controls, fixed effects, interactions.
- **Inference** — clustering, weights, multiple-testing correction, confidence-interval method.

Not every ADR needs to be perfectly tagged — some decisions cut across components — but tag it when the scope is unambiguous.

---

## When to write a new ADR

Write one when any of the following becomes true:

- A research framing or hypothesis choice is locked.
- A design parameter is committed (sample size, arm structure, instrument format, specification).
- A methodological choice is made (estimator, metric, clustering, tolerance).
- A scope decision excludes a candidate.

Do **not** write an ADR for:

- Literature reading progress or individual paper summaries.
- Code, repo setup, or file-path logistics.
- Tentative thoughts that haven't been committed to. Draft those in a session log or analysis doc first; promote to an ADR once settled.

---

## Entry template

```markdown
# NNNN: [Decision title, <= 80 chars]

- **Date:** YYYY-MM-DD
- **Status:** Decided | Proposed | Superseded by #NNNN
- **Scope:** [one category]
- **Data quality:** Full context | Reconstructed — partial context
- **Supersedes:** #NNNN (optional)

## Context
1-3 paragraphs. What problem? What constraints? What prompted this now?

## Decision
The decision, stated crisply. Bullet points OK.

## Consequences
What this commits us to. What it rules out. Open questions it creates.

## Sources
- path/to/file.md :: section or line range
- Git commit hash if relevant
```

---

## Index

| ID | Title | Date | Status | Scope |
|----|-------|------|--------|-------|
| [0001](0001_consolidation-scope.md) | Consolidation scope — two predecessor repos in scope | 2026-04-25 | Decided | Infrastructure |
| [0002](0002_runtime-server-only.md) | Runtime — Scribe server only, hostname-branched settings | 2026-04-25 | Decided | Infrastructure |
| [0003](0003_languages-stata-primary-python-upstream.md) | Languages — Stata primary; Python preserved for upstream geocoding | 2026-04-25 | Decided | Methodology |
| [0004](0004_sibling-va-canonical-pipeline.md) | Sibling-VA canonical pipeline — `va_{score,out}_all.do`; `siblingvaregs/` regressions deprecated | 2026-04-27 | Decided | Specification |
| [0005](0005_siblingoutxwalk-relocation.md) | `siblingoutxwalk.do` canonical location — `do/sibling_xwalk/` | 2026-04-27 | Decided | Infrastructure |
| [0006](0006_vam-ado-pinning.md) | `vam.ado` pinned at v2.0.1 + noseed customization | 2026-04-27 | Decided | Methodology |
| [0007](0007_code-data-separation-and-sync-model.md) | Code-data separation; Scribe non-git working copy; GitHub frozen archive at handoff | 2026-04-27 | Decided | Infrastructure |
| [0008](0008_external-crosswalks-vendoring.md) | External crosswalks vendored as defensive backup on Scribe; runtime unchanged | 2026-04-27 | Decided | Infrastructure |
| [0009](0009_prior-score-v1-canonical.md) | Prior-score variant — v1 canonical for paper; v2 preserved as exploratory | 2026-04-27 | Decided | Specification |
| [0010](0010_paper-alpha-canonical.md) | Paper-reported α from `indexalpha.do`; `alpha.do` archived as exploratory | 2026-04-27 | Decided | Specification |
| [0011](0011_survey-indices-as-means.md) | Survey indices computed as means, not sums; code fix in `imputedcategoryindex.do` + `compcasecategoryindex.do` | 2026-04-27 | Decided | Specification |
| [0012](0012_tab-csvs-local-review-only.md) | `_tab.do` CSV outputs are local-review-only; paper tables come from `share/` | 2026-04-27 | Decided | Specification |
| [0013](0013_mattschlchar-gate-kept.md) | `mattschlchar.do` clean-gate kept; `sch_char.dta` consumed as-is, not reproduced | 2026-04-27 | Superseded in part by #0023 | Data |
| [0014](0014_old-paper-draft-preserved.md) | Old paper draft `common_core_va.tex` preserved as historical artifact | 2026-04-27 | Decided | Infrastructure |
| [0015](0015_filipino-asian-recoding-intentional.md) | Filipino-into-Asian race recoding intentional; documented in code | 2026-04-27 | Decided | Data |
| [0016](0016_pooledrr-renamed-by-scope.md) | `pooledrr` variable renamed by scope across the four producers | 2026-04-27 | Decided | Specification |
| [0017](0017_matt-naven-files-untouched.md) | Matt Naven's files stay untouched through Phase 1 | 2026-04-27 | Decided | Infrastructure |
| [0018](0018_offboarding-model-refinement.md) | Offboarding model — Kramer is custodian; successor unknown; full-pipeline acceptance run before `v1.0-final` | 2026-04-27 | Decided | Infrastructure |
| [0019](0019_nsc-crosswalk-authorship-correction.md) | `crosswalk_nsc_outcomes.do` is Christina's; refines ADR-0017 file list; Phase 1 leaves untouched anyway | 2026-04-27 | Decided | Infrastructure |
| [0020](0020_sync-mechanism-operator-choice.md) | File transfer is operator-choice (FileZilla today); refines ADR-0007 sync model; rest of ADR-0007 stands | 2026-04-28 | Superseded by #0022 | Infrastructure |
| [0021](0021_main-settings-relocation-and-self-contained-sandbox.md) | main.do + settings.do relocated under do/; consolidated/ is self-contained sandbox (no writes to legacy paths); every do file carries a header description + main.do one-liner | 2026-04-29 | Decided | Infrastructure |
| [0022](0022_scribe-git-sync-provisional.md) | Git repo on Scribe (provisional through end of project) supersedes FileZilla drag-and-drop; sparse-checkout excludes Claude-only paths; pre-push hook prevents data-leak pushes; revisit at Phase 1c §5.4 acceptance run | 2026-05-26 | Decided | Infrastructure |
| [0023](0023_mattschlchar-vendored-as-runtime-source.md) | `mattschlchar.dta` vendored into `data/raw/upstream/` as the active runtime source (predecessor access lost); fills the empty `clean==0` block; supersedes ADR-0013's consume-as-is posture in part | 2026-05-31 | Decided | Data |
| [0024](0024_tables-vs-estimates-dir-for-regsave-summaries.md) | regsave summary `.dta` tables (`fb_*_all`, `spec_*_all`) live under `$tables_dir`, raw `.ster` estimates under `$estimates_dir`; fixes va_spec_fb_tab_all r(601) producer/consumer root mismatch; refines ADR-0021, supersedes the misleading file-header relocation note | 2026-06-01 | Decided | Specification |
| [0025](0025_nsc-codebook-descoped.md) | `nsc_codebook.do` descoped + archived to `do/_archive/out_of_scope/` — input `nsc_2010_2017_clean` removed from Scribe (re-cleaned under new names), out of scope; removed from main.do Phase 6 | 2026-06-01 | Decided | Data |
| [0026](0026_sibling-xwalk-files-consolidated.md) | sibling-crosswalk producers consolidated under `do/sibling_xwalk/` (3 files moved from `do/share/siblingxwalk/`, log paths repointed to mirror); extends ADR-0005 | 2026-06-01 | Decided | Infrastructure |
| [0027](0027_clamp-imputed-survey-items-and-repoint-check.md) | clamp OLS-imputed survey QOI items to Likert [-2,2] (imputation.do) + re-point check_survey_indices SUB-CHECK 1 from LEGACY predecessor files to CANONICAL pipeline outputs; resolves e968d13 Phase-7 survey FAIL | 2026-06-09 | Decided | Methodology |
| [0028](0028_accept-thin-variant-va-cells-soft-check.md) | accept thin per-spec VA cells in restricted-variant samples (subsamples drop students post-merge; CFR shrinks them; weight-only) + downgrade check_va_estimates per-spec count assert from hard-halt to soft; resolves e968d13 Phase-7 VA FAIL | 2026-06-09 | Decided | Specification |
| [0029](0029_cde-cleaning-year-coverage-2015-2018.md) | CDE cleaning year coverage = spring 2015–2018 (macro-driven via macros_va.doh test_score_min/max_year); predecessor's 2013/2014/2019/2020 cleaned files + sch_char_2019 intentionally not rebuilt; classifies the 22 M4 MISSING_CONSOLIDATED rows as intended deviation; records the plan-draft's deferred cohort-coverage earmark | 2026-06-11 | Decided | Data |
| [0030](0030_pin-cde-directory-input-for-reproducibility.md) | pin K12 distance input to cached pubschls.txt (toggle refresh_cde_directory, default 0); drops the live-CDE-URL fetch that made mindist_* + distance-derived VA samples non-reproducible (root cause of the M4 mindist_* 50,766-row drift); predecessor live-fetch preserved as the ==1 branch; canonical distance outputs must be regenerated on the next clean re-run | 2026-06-12 | Decided | Data |

---

## Pending decisions (tracked, not yet committed)

Decisions that need to happen but aren't resolved. They get an ADR when resolved, not before.

The full list of expected ADRs (with proposed slugs) lives in
`quality_reports/plans/2026-04-25_consolidation-plan-draft.md` §5. Items deferred until Phase 0 deep-read completes:

- ~~**0004** sibling-xwalk canonical location~~ → **resolved 2026-04-27 as ADR-0004 (sibling-VA canonical pipeline) and ADR-0005 (siblingoutxwalk.do relocation)**
- ~~**0005** pipeline order~~ → reframed and resolved 2026-04-27 as ADR-0005 (siblingoutxwalk.do relocation); broader pipeline-order decision deferred to Phase 1 plan
- ~~**0006** prior-score policy v1-canonical / v2-preserved~~ → **resolved 2026-04-27 as ADR-0009**
- ~~**0007** upstream-data-prep convention~~ → **subsumed by ADR-0007 (code-data separation) — `data/raw/upstream/` directory convention defined there**
- ~~**0008** local-script convention~~ → **subsumed by ADR-0007 — local scripts live in `do/local/` per the folder layout**
- ~~**0009** custom vam ado handling~~ → **resolved 2026-04-27 as ADR-0006 (vam.ado pinned at v2.0.1 + noseed)**
- ~~**0010** paper source-of-truth~~ → **resolved 2026-04-27 as ADR-0014 (old draft preserved); current draft remains canonical at `va_paper_clone`**
- ~~**0011** output paths mirror paper expectations~~ → **subsumed by ADR-0007 (`tables/`, `figures/` paths in repo) + ADR-0012 (paper producers in `share/`)**
- ~~**0012** settings.do hostname branching pattern~~ → **already in ADR-0002 (runtime — Scribe only, hostname-branched)**
- **0013** cohort coverage 2014-15 to 2017-18 — *deferred*; not raised in Phase 0e walkthrough; data-scope question, can wait for Phase 1 if needed
- ~~**0014** entry-point naming~~ → **already established as `main.do` per CLAUDE.md and ADR-0002**
- **0015** Stata version pin — *deferred*; backlog item per TODO.md; revisit pre-submission per AEA package requirements
- ~~**0016** server canonical folder~~ → **resolved 2026-04-27 as ADR-0007 (`/home/research/ca_ed_lab/projects/common_core_va/consolidated/`)**

**Phase 0e ADR sweep COMPLETE 2026-04-27.** All committed-Decided ADRs in the index above. Remaining "pending" items (cohort coverage, Stata version pin) are non-blocking deferrals.
