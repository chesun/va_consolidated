# 0001: Consolidation scope -- two predecessor repos in scope

- **Date:** 2026-04-25
- **Status:** Decided
- **Scope:** Infrastructure (project-specific category; structural decision, not research)
- **Data quality:** Full context

## Context

The Common Core VA project's code has accreted across multiple repos over ~10 years. The original README of va_consolidated listed three predecessor codebases, but onboarding Q&A surfaced a more nuanced landscape: at least four candidate repos exist on the user's machine, plus a separate Overleaf clone for the paper draft.

Before any consolidation work begins, we need an authoritative answer to "which repos contribute code to va_consolidated?" — otherwise the migration scope is ambiguous and we risk (a) missing load-bearing scripts that live in an out-of-scope repo, or (b) wasting time auditing reference repos that supersede each other.

## Decision

**In-scope (two repos):**

- `~/github_repos/cde_va_project_fork` — Christina's fork of Matt Naven's `ca_ed_lab-common_core_va`. **Production branch: `changes_by_che`.** The fork supersedes Matt's origin because Matt is no longer actively involved; Christina forked to avoid blocking on his PR/merge cycle.
- `caschls` at `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls` — Christina's own VA + CALSCHLS survey work. **Production branch: `main`.** Includes the sibling crosswalk pipeline that feeds VA estimation in the fork.

**Out-of-scope (two repos):**

- `ca_ed_lab-common_core_va` — Matt's original origin. Superseded by Christina's fork; not migrated.
- `common_core_va_workflow_merge` — Christina's 2022 merge attempt that was abandoned because of time constraints. Did not produce anything useful. The 2022 README in caschls describes the intended merge structure; institutional knowledge worth preserving but not authoritative.

**Auxiliary (referenced but not migrated):**

- `~/github_repos/va_paper_clone` — Overleaf clone holding the canonical paper source (`paper/common_core_va_v2.tex`) and bibliography. Stays separate per ADR-0010 (forthcoming).

## Consequences

- The Phase 0 deep-read audit (per `quality_reports/plans/2026-04-25_consolidation-plan-draft.md` §6) covers only the two in-scope repos.
- Migration (Phase 1+) pulls files from these two repos only; out-of-scope repos remain intact for archeology.
- If the Phase 0 deep-read uncovers a load-bearing script that exists *only* in an out-of-scope repo, this ADR is superseded by a new one expanding scope. Likelihood: low (we have ~3.5 years of history under `changes_by_che` and `caschls/main` to draw from).
- The data-prep `archive/`, `upstream/`, `local/`, `check/`, `debug/` subdirectories of the in-scope repos are preserved during migration but most are not on the production pipeline (per the master-file audit, `quality_reports/reviews/2026-04-25_master-file-audit.md`).

## Sources

- `quality_reports/session_logs/2026-04-24_project-onboarding.md` :: rounds 1-2 (repo scope confirmation)
- `quality_reports/onboarding/2026-04-25_context-dump.md` :: Section 0, Section 1
- `quality_reports/reviews/2026-04-25_master-file-audit.md` :: full audit of both repos
- `quality_reports/plans/2026-04-25_consolidation-plan-draft.md` :: §2 inputs, ADR list
