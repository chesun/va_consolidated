# CLAUDE.MD -- Applied Microeconomics Research with Claude Code

<!-- HOW TO USE: Replace [BRACKETED PLACEHOLDERS] with your project info.
     Customize for your analysis language, LaTeX engine, and identification strategy.
     Keep this file under ~150 lines — Claude loads it every session.
     Based on clo-author (Hugo Sant'Anna) + infrastructure from Pedro Sant'Anna. -->

**Project:** Value Added Project
**Institution:** California Education Lab, UC Davis
**Branch:** main

---

## Core Principles

- **Plan first** -- enter plan mode before non-trivial tasks; save plans to `quality_reports/plans/`
- **Verify after** -- compile and confirm output at the end of every task
- **Single source of truth** -- Paper `main.tex` is authoritative; talks and supplements derive from it
- **Quality gates** -- weighted aggregate score; nothing ships below 80/100; see `quality.md`
- **Worker-critic pairs** -- every creator has a paired critic; critics never edit files
- **Primary source first** -- before citing a paper in a load-bearing artifact, read the PDF and produce reading notes in `master_supporting_docs/literature/reading_notes/`; hooks block edits otherwise (see `primary-source-first.md`)
- **Decisions are ADRs** -- substantive design, identification, or specification decisions live in `decisions/NNNN_slug.md`; analysis docs hold reasoning, ADRs hold the record (see `decision-log.md`)
- **Track TODOs** -- project root `TODO.md` tracks open work (Active / Up Next / Waiting / Backlog / Done); update after completing any task (see `todo-tracking.md`)
- **[LEARN] tags** -- when corrected, save `[LEARN:category] wrong → right` to MEMORY.md

---

## Getting Started

1. Fill in the `[BRACKETED PLACEHOLDERS]` in this file
2. Run `/discover interview [topic]` to build your research specification
3. Or run `/new-project [topic]` for the full orchestrated pipeline

---

## Folder Structure

```
va_consolidated/
├── CLAUDE.md                    # This file
├── README.md, LICENSE, MEMORY.md, TODO.md
├── SESSION_REPORT.md            # Mirrored to .claude/SESSION_REPORT.md
├── .claude/                     # Rules, skills, agents, hooks, state
├── decisions/                   # ADRs — NNNN_slug.md, append-only
├── quality_reports/             # Plans, session logs, reviews, audits
│
├── main.do                      # SINGLE Stata pipeline entry point (phase toggles)
├── settings.do                  # Hostname-branched paths (Scribe vs other)
├── ado/                         # Custom-modified .ado packages (vam shrinkage etc.)
│
├── do/                          # Stata pipeline (root-level; no scripts/ parent)
│   ├── _archive/                # Historical / superseded
│   ├── upstream/                # Stata data prep producing static project inputs
│   ├── local/                   # Local-machine ad-hoc keepers
│   ├── sibling_xwalk/           # Sibling-crosswalk pipeline
│   ├── data_prep/               # Cleaning + raw-to-clean transformations
│   │   ├── acs/, schl_chars/, k12_postsec_distance/, prepare/, caschls_qoiclean/
│   ├── samples/                 # Sample construction
│   ├── va/                      # VA estimation (helpers, score, outcome, pass_through, heterogeneity)
│   ├── survey_va/               # CalSCHLS index + survey-VA regressions
│   ├── share/                   # Generic tab/figure helpers
│   ├── check/, debug/, explore/ # Verification / ad-hoc / exploratory
│
├── py/                          # Python (root-level)
│   └── upstream/                # Geocoding scripts (preserved for completeness)
│
├── data/
│   ├── raw/                     # Original untouched data (often gitignored)
│   └── cleaned/                 # Processed datasets
├── output/                      # Logs, intermediate non-paper outputs
├── figures/                     # Mirrors paths the paper LaTeX expects (share/va/v1/, share/survey/, etc.)
├── tables/                      # Mirrors paper paths (share/va/pub/, share/survey/pub/)
├── log/                         # Stata log files
│
├── paper/                       # Empty for current milestone (paper canonical = ~/github_repos/va_paper_clone)
├── talks/                       # Beamer presentations (deferred)
├── supplementary/               # Online appendix
├── replication/                 # Replication package for deposit (post-consolidation)
├── preambles/header.tex         # LaTeX headers / shared preamble
├── explorations/                # Research sandbox
├── templates/                   # Session log, quality report templates
└── master_supporting_docs/      # Reference papers and data docs
    ├── literature/              # Primary sources (gated by primary-source-first hook)
    │   ├── papers/              # PDFs of cited papers (surname_year naming)
    │   └── reading_notes/       # One .md per cited paper
    └── supporting_papers/       # Methodology references (not load-bearing)
```

---

## Commands

```bash
# Pipeline run (on Scribe via SSH)
cd /home/research/ca_ed_lab/projects/common_core_va
stata -b do main.do

# Paper compilation (canonical paper lives in ~/github_repos/va_paper_clone)
cd ~/github_repos/va_paper_clone/paper
pdflatex -interaction=nonstopmode common_core_va_v2.tex
BIBINPUTS=../literature/bibtex:$BIBINPUTS bibtex common_core_va_v2
pdflatex -interaction=nonstopmode common_core_va_v2.tex
pdflatex -interaction=nonstopmode common_core_va_v2.tex
```

---

## Quality Thresholds

| Score | Gate | Applies To |
|-------|------|------------|
| 80 | Commit | Weighted aggregate (blocking) |
| 90 | PR | Weighted aggregate (blocking) |
| 95 | Submission | Aggregate + all components >= 80 |
| -- | Advisory | Talks (reported, non-blocking) |

See `quality.md` for weighted aggregation formula.

---

## Skills Quick Reference

| Command | What It Does |
|---------|-------------|
| `/new-project [topic]` | Full pipeline: idea → paper (orchestrated) |
| `/discover [mode] [topic]` | Discovery: interview, literature, data, ideation |
| `/strategize [question]` | Identification strategy or pre-analysis plan |
| `/analyze [dataset]` | End-to-end data analysis |
| `/write [section]` | Draft paper sections + humanizer pass |
| `/review [file/--flag]` | Quality reviews (routes by target: paper, code, peer) |
| `/revise [report]` | R&R cycle: classify + route referee comments |
| `/talk [mode] [format]` | Create, audit, or compile Beamer presentations |
| `/submit [mode]` | Journal targeting → package → audit → final gate |
| `/challenge [file --mode]` | Devil's advocate: `--paper`, `--identification`, `--fresh` |
| `/balance [treatment]` | Generate balance tables (Stata/R) |
| `/event-study [spec]` | Event study plots with pre-trends and CIs |
| `/compile-latex [file]` | 3-pass pdflatex + bibtex (papers and talks) |
| `/tools [subcommand]` | Utilities: commit, validate-bib, context-status, learn, etc. |

---

<!-- CUSTOMIZE: Replace the example entries below with your own
     Beamer environments for talks. -->

## Beamer Custom Environments (Talks)

| Environment       | Effect        | Use Case       |
|-------------------|---------------|----------------|
| `[your-env]`      | [Description] | [When to use]  |

---

## Current Project State

| Component | File | Status | Description |
|-----------|------|--------|-------------|
| Paper | `paper/main.tex` | [draft/submitted/R&R] | [Brief description] |
| Data | `scripts/stata/` | [complete/in-progress] | [Analysis description] |
| Replication | `replication/` | [not started/ready] | [Deposit status] |
| Job Market Talk | `talks/job_market_talk.tex` | -- | [Status] |
