# va_consolidated

Consolidated codebase for the **California Education Lab Value-Added project**.

This repo merges three previously-separate codebases:

1. Matt Naven's original VA estimation code (foundational, ~10 years old)
2. Christina's CALSCHLS survey analysis codebase (uses Matt's VA estimates as input)
3. Christina's sibling-FE VA estimation codebase (uses sibling links constructed in [2])

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
