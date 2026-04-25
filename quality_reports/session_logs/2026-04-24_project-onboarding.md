# Session Log: 2026-04-24 -- Project Onboarding & Orientation

**Status:** IN PROGRESS

## Objective

Initial orientation session for the `va_consolidated` repo. User asked Claude to read `CLAUDE.md` and `README.md` and report back what's understood about the project so far. No code or analysis work yet — this is the first working session after the workflow infrastructure was forked from `claude-code-my-workflow` on 2026-04-24.

## Key Context

**Project:** Value Added Project — California Education Lab, UC Davis.

**What this repo is:** A consolidation of three previously-separate codebases:

1. Matt Naven's original VA estimation code (~10 years old, now deprecated). Christina has adapted it into new VA estimation versions/workflows. Source: `~/github_repos/cde_va_project_fork`.
2. Christina's CALSCHLS survey analysis codebase, which uses VA estimates as input. Source: `~/github_repos/caschls`.
3. Sibling-link construction code (currently inside the CALSCHLS repo) which feeds into the new VA estimation — source of a circular dependency between the two predecessor repos.

**Stated goals (from README):**

- One source of truth for student-year roster, sibling links, and VA estimates.
- Resolved dependency order: sibling construction → VA estimation (no circularity).
- Reproducible end-to-end from raw data to final estimates.

**Repo state at start of session:**

- Workflow infrastructure freshly forked (2026-04-24) from `claude-code-my-workflow` applied-micro overlay.
- `CLAUDE.md` still contains bracketed placeholders (project name, current status fields).
- No ADRs yet, no session logs yet, no scripts yet, no inventory of predecessor codebases yet.
- README "Getting started" lists four open onboarding tasks: fill placeholders, populate primary-source surname allowlist, inventory predecessor codebases, draft consolidation ADRs.

## Changes Made

| File | Change | Reason | Quality Score |
|------|--------|--------|---|
| `quality_reports/session_logs/2026-04-24_project-onboarding.md` | Created (this file) | Stop hook required a session log before continuing | n/a |

## Design Decisions

None this session.

## Incremental Work Log

- Read `README.md` and the `CLAUDE.md` shown in system context.
- Reported a summary back to the user: project identity, three-codebase consolidation, stated goals, infrastructure provenance, current state (placeholders unfilled, four open onboarding tasks).
- Stop hook fired requesting a session log; created this file.

<!-- primary-source-ok: the_2022, spring_2015, spring_2016, spring_2017, spring_2018 -->
<!-- These are not paper citations. "The 2022..." is a sentence start; "Spring 2015"..."Spring 2018" are cohort labels in a table describing prior-score-control choices for SBAC test cohorts. No external paper is being cited. -->

## Round 2 - Codebase landscape and project status (after user answers)

**Repo scope confirmed:**

- IN scope: `~/github_repos/cde_va_project_fork` -- Christina's fork of Matt Naven's `ca_ed_lab-common_core_va`. Matt is no longer actively involved; the fork is the canonical Matt-derived source. Christina is a collaborator on Matt's repo but forked to make changes without depending on Matt for PR/merge.
- IN scope: `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls` -- Christina's own VA + CALSCHLS survey repo. Has v2 branch merged (`eda7b3a`) and contains the sibling crosswalk code.
- OUT of scope: `ca_ed_lab-common_core_va` (superseded by the fork).
- OUT of scope: `common_core_va_workflow_merge` -- Christina started this 2022-era merge attempt but never progressed. Did not produce anything useful. Abandoned because of time, not because anything broke. The "Tentative unified folder structure" in caschls/README is institutional knowledge worth reading but not authoritative.

**Paper status:**

- Submitted, rejected. In limbo pending coauthor/PI decision on next venue.
- Coauthors are senior faculty not involved with coding.
- Christina is the sole person in charge of data and code.
- Submitted-snapshot Overleaf clone: `va_paper_clone`.
- Working draft: `paper/commoncore_va_v2.tex`.

**v1 / v2 terminology (CRITICAL -- corrected by user):**

v1 and v2 are **different choices of prior test score controls for ELA and Math VA estimates**. They are NOT sibling vs CFR, and not anything related to sibling-based estimation. Authoritative source: `create_prior_scores_v1.doh` and `create_prior_scores_v2.doh`.

| Cohort | v1 ELA prior | v1 Math prior | v2 ELA prior | v2 Math prior |
|---|---|---|---|---|
| spring-2015 | 8th grade ELA (spring 2012) | 6th grade math (spring 2010) | 6th grade ELA (spring 2012) | 6th grade math (spring 2010) |
| spring-2016 | 8th grade ELA (spring 2013) | 6th grade math (spring 2011) | 6th grade ELA (spring 2013) | 6th grade math (spring 2011) |
| spring-2017 | 7th grade ELA (spring 2013) | 6th grade math (spring 2012) | 6th grade ELA (spring 2013) | 6th grade math (spring 2012) |
| spring-2018 | 8th grade ELA (spring 2015) | 8th grade math (spring 2015) | 8th grade ELA (spring 2015) | 8th grade math (spring 2015) |

## Round 3 - Pipeline geometry and definition of done

- **Circular dependency between sibling construction and VA estimation:** user does not currently remember the precise circle. To be characterized by tracing do-files together (deferred investigation task).
- **Runtime location:** restricted research server only (SSH terminal). Local laptop is editor only. No remote VS Code; no Claude-side execution. Air-gapped workflow rule (`.claude/rules/air-gapped-workflow.md`) applies fully: Christina runs scripts on the server, shares logs/outputs back; Claude writes defensive code with `assert` and inline `// ASSUMPTION` comments.
- **Definition of done (3-month deadline) -- ALL three must hold:**
  1. Reproduces the rejected-paper results end-to-end: from raw CAASPP/SBAC + roster to all tables/figures in `paper/commoncore_va_v2.tex`. Single master script must run.
  2. Resolves the sibling/VA dependency cleanly: one canonical pipeline order, no circularity, no duplication between caschls and the fork.
  3. Survives a future-me audit in 5 years: ADRs for substantive decisions, file dictionary, comments documenting non-obvious choices.
  - NOT required for this milestone: AEA replication-package audit / openICPSR deposit. May come later but is not the 3-month target.
- **Reading depth:** user wants deep read (every script in both in-scope repos), not strategic skim, despite deadline.

## Round 4 - Scope, server logistics, languages

- **caschls scope:** the CALSCHLS survey work IS part of the VA project, not a separate strand. The paper correlates VA estimates with school-climate and other survey constructs. Authoritative source for the analysis structure: `paper/commoncore_va_v2.tex`. The full caschls repo is in scope, including factor analysis, QOI cleaning, sibling-VA-on-survey regressions.
- **Stata version:** 17 (confirm by checking server `version` in any do-file). CLAUDE.md placeholder is correct.
- **Server access pattern:** SSH login, terminal sessions only. No VS Code remote. Means: do-files are edited locally, pushed/copied to server, run on server, logs come back.
- **Languages:** Stata only. The `py_files/` folder in both predecessor repos is dead/unused. Do not include any Python pieces in the consolidated pipeline. (R also not in scope; ignore R rules in `.claude/rules/r-code-conventions.md` for this project.)

## Learnings & Corrections

- [LEARN:domain] v1/v2 = prior-score-control variants, NOT sibling vs CFR. Always check `create_prior_scores_v*.doh` for the authoritative spec rather than inferring from context.
- [LEARN:discipline] User invoked the no-assumptions rule (global). I made a plausible-sounding but wrong guess about v1/v2. Going forward: when user terminology is ambiguous, ASK; do not infer by analogy.

<!-- primary-source-ok: chetty_2014, chetty-friedman-rockoff_2014, naven_2022, calschls_2017, only_2002, available_2002, the_2022, spring_2015, spring_2016, spring_2017, spring_2018 -->
<!-- This session-log entry summarises the just-completed read of common_core_va_v2.tex; it does not make new framing claims about any external paper. CalSCHLS is the data source name (not a paper), and Spring/Only/Available/The are sentence starts and cohort labels caught as false-positives. -->

## Round 5 - Paper read (post-approval, 2026-04-24)

- Located `common_core_va_v2.tex` at `~/github_repos/va_paper_clone/paper/common_core_va_v2.tex` (1357 lines). The file is in the va_paper_clone Overleaf clone, NOT in va_consolidated/paper/. va_consolidated/paper/ currently contains only `.gitkeep`.
- Read the paper end-to-end. Paper map saved to `quality_reports/reviews/2026-04-24_paper-map.md`. The map indexes every table and figure referenced in the paper to the input file path the LaTeX expects, plus six load-bearing pipelines that must reproduce.
- Key facts captured for the consolidation work:
  - 4 cohorts (2014-15 through 2017-18), ~2M students, ~1,400 high schools, ~1.2M base sample.
  - SBAC test scores (ELA, math) + NSC college-enrollment outcomes (2yr, 4yr).
  - Sibling links built from shared address + surname, transitive closure. Address data covers academic years 2002-03 through 2012-13 only.
  - CFR-style "value-added with drift", school-level. Eq (1) does NOT include school FE -- this differs from the original CFR baseline and from Naven dissertation; estimates correlate at 0.99 either way.
  - 5 control specifications across columns; preferred = restricted sample with peer + ACS + sibling + leave-out 7th-grade ELA.
  - Survey mechanism analysis uses CalSCHLS data 2017-2019 at school-level only (cannot link to CDE individual records).
- Six canonical pipelines for consolidation: (1) sample creation, (2) sibling crosswalk, (3) prior-score creation (v1), (4) VA estimation + drift, (5) validity/heterogeneity/pass-through, (6) CalSCHLS index + survey-VA regressions.
- Filename token glossary in the paper map is partially inferred (tokens like `las`, `sp`, `ct`, `nw`) -- do not propagate these guesses; verify against do-files in next phase.
- Hook noise: the primary-source-check.py hook's Author-Year regex generates many false-positives on cohort labels and sentence starts. Each false-positive needed an explicit `<!-- primary-source-ok: ... -->` escape comment. This is now on the TODO list to fix (better regex, sentence-start filter, surname allowlist).

## Verification Results

n/a — no artifacts produced.

## Open Questions / Blockers

- [ ] Which onboarding task does the user want to tackle first: (a) fill `CLAUDE.md` placeholders, (b) populate `.claude/state/primary_source_surnames.txt`, (c) inventory the three predecessor codebases, or (d) draft the consolidation charter ADR?
- [ ] Stata version on the user's machine (CLAUDE.md placeholder).
- [ ] Whether the paper/talks live in this repo or on Overleaf.

## Next Steps

- [ ] Wait for user direction on which onboarding task to start.
