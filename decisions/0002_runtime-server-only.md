# 0002: Runtime -- Scribe server only, hostname-branched settings

- **Date:** 2026-04-25
- **Status:** Decided
- **Scope:** Infrastructure
- **Data quality:** Full context

## Context

The project's data is restricted-access: SBAC test scores, NSC enrollment records, student addresses, and CalSCHLS surveys all live behind UC Davis's restricted-access agreements. Data cannot leave Scribe (UC Davis Social Sciences Data Service). The pipeline has always run on the server, with the local laptop used only as an editor.

Both predecessor repos (`cde_va_project_fork`, `caschls`) currently use hardcoded `/home/research/ca_ed_lab/...` paths in their `settings.do` files (per Christina's answer in context-dump §10 B4). For consolidation, we need to commit to a runtime model up front so settings.do design is consistent.

## Decision

- **All Stata pipeline scripts run on Scribe.** `c(hostname) == "scribe"` is the production hostname.
- **Local laptop is editor-only.** No remote-VS-Code; no Claude code execution. Air-gapped Claude workflow per `.claude/rules/air-gapped-workflow.md`: defensive code with assertions; Christina runs scripts; logs returned.
- **`settings.do` branches by `c(hostname)` from day one** of the consolidated repo, even though only Scribe is currently supported. Future portability comes free; non-Scribe hostnames trigger a clear error.
- **Project root on server:** `/home/research/ca_ed_lab/projects/common_core_va`. (This was the 2022 caschls/README proposal; Christina confirmed it during onboarding round 4. The reconciliation between this proposed root and any other server-side folder containing predecessor code is deferred to ADR-0016, which lands after Phase 0d.)
- **SSH access pattern:** `Scribe@ssds.ucdavis.edu`. Terminal sessions only. (Captured in gitignored `.claude/state/server.md`.)

## Consequences

- `settings.do` is hostname-aware from the foundation commit (Phase 1 step 1). Single-hostname code is rejected.
- Replication-package readiness (AEA / openICPSR) is post-consolidation: requires either porting paths to a portable form or shipping a Docker image with the Scribe environment pinned.
- Claude cannot run scripts directly; every verification step requires Christina to execute on Scribe and share logs back.
- Defensive code (`assert`, explicit `// ASSUMPTION:` comments) is the norm in scripts that depend on data state Claude cannot inspect.
- If/when a second hostname is added (e.g., a personal local machine for offline editing of derived datasets), a new branch is added to settings.do and an ADR documents the addition.

## Sources

- `quality_reports/session_logs/2026-04-24_project-onboarding.md` :: round 4 (server logistics)
- `.claude/state/server.md` (gitignored; SSH details, project root)
- `quality_reports/onboarding/2026-04-25_context-dump.md` :: §10 B4 (settings.do convention)
- `quality_reports/plans/2026-04-25_consolidation-plan-draft.md` :: §8 (settings.do design)
- `.claude/rules/air-gapped-workflow.md`
