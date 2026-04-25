# va_consolidated

Consolidated codebase for the **California Education Lab Value-Added project**.

This repo merges three previously-separate codebases:

1. (a) Matt Naven's original VA estimation code (foundational, ~10 years old). (b) Christina has created new versions and workflows for estimating VA by adapting Matt's original code, and the original code is now deprecated.
   1. Repo: ~/github_repos/cde_va_project_fork
2. Christina's CALSCHLS survey analysis codebase (uses VA estimates as input)
   1. repo: ~/github_repos/caschls
   2. This repo includes code that creates sibling links, which then feeds into the new version of VA estimation in [1](a)

**Goals:**

- One source of truth for student-year roster, sibling links, and VA estimates.
- Resolved dependency order (no circular references between sibling construction and VA estimation).
- Reproducible end-to-end from raw data to final estimates.

**Workflow infrastructure:** based on `claude-code-my-workflow` (applied-micro overlay), forked 2026-04-24.

## Structure

See `CLAUDE.md` for the full template structure. Key directories:

- `decisions/` — ADRs documenting consolidation choices (append-only)
- `scripts/stata/` — primary analysis code (Stata 17)
- `data/{raw,cleaned}/` — data pipelines
- `paper/`, `talks/` — manuscript and presentations (or Overleaf if used)
- `quality_reports/` — plans, session logs, reviews
- `master_supporting_docs/literature/` — cited primary sources (gated by primary-source-first hook)

## Getting started

1. Fill bracketed placeholders in `CLAUDE.md` (project name, institution, Stata version).
2. Populate `.claude/state/primary_source_surnames.txt` with VA-relevant authors.
3. Inventory the three predecessor codebases (location paths, what each produces).
4. Draft initial ADRs in `decisions/` for the consolidation charter.
