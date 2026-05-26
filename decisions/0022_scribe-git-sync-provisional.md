# 0022: Scribe-git-sync workflow (provisional) — supersedes ADR-0020 FileZilla operator-choice

- **Date:** 2026-05-26
- **Status:** Decided
- **Supersedes:** #0020 (FileZilla operator-choice); refines ADR-0007 §"Sync model" further
- **Scope:** Infrastructure
- **Data quality:** Full context

## Context

ADR-0020 (2026-04-28) committed to FileZilla drag-and-drop as Christina's daily sync mechanism between her Mac and the Scribe `consolidated/` folder. The rationale was operator simplicity: a wrapper-script-based rsync workflow had been drafted, but Christina assessed it as over-engineered for her remaining ~3 months in the project, especially when measured against a FileZilla workflow that had worked reliably for years.

That ADR also explicitly rejected the "git repo on Scribe" alternative — see ADR-0020 §"Open questions". The cited concerns were: GitHub credentials on a restricted server, accidental `git push` of staged data, and supply-chain risk from upstream commits.

Between 2026-04-28 and 2026-05-26, two things changed the calculus:

1. **Recurring M4 acceptance attempts on Scribe surfaced friction in the FileZilla workflow.** Each attempt (#1 through #4) required: (a) commit fixes on laptop, (b) push to origin, (c) launch FileZilla, (d) drag-and-drop modified files, (e) launch Stata on Scribe, (f) sync logs back via FileZilla. Across four attempts in 2026-05-16 to 2026-05-18 alone, this overhead was non-trivial. The FileZilla GUI is also lossy as an audit trail — there's no record of which files moved on which date with which content.
2. **The pre-push hook infrastructure (commit `e31fe15`, 2026-05-25) materially reduced the "accidental push of data" risk.** With `.gitignore` covering `data/` + `estimates/` + the `.githooks/pre-push` hook scanning commit ranges for any non-`.gitkeep` files under those paths, the "git on Scribe could leak data to GitHub" failure mode now requires both an explicit `git add -f` AND a `git push --no-verify` — two layers of intentional bypass.

On 2026-05-26, Christina decided to provisionally adopt a git-based sync model on Scribe to test whether the audit-trail and convenience improvements outweigh the residual concerns. The decision is explicitly framed as **experimental**, to be revisited at end of project before `v1.0-final` tag.

This refines ADR-0020's sync-implementation subsection only. The architectural commitments around code-data separation, `.gitignore` policy, and GitHub-as-frozen-archive at offboarding all stand. What changes is the daily sync mechanism.

## Decision

**Git repo on Scribe (consolidated/ folder is a clone of origin) is the primary sync mechanism, provisional through end of project.**

The setup recipe lives in `quality_reports/plans/2026-05-25_scribe-setup.md` (linear 5-step procedure). Concretely on Scribe:

- `.git/` is present in `/home/research/ca_ed_lab/projects/common_core_va/consolidated/.git`, cloned from `https://github.com/chesun/va_consolidated`
- Sparse-checkout configured to exclude Claude-only dirs (`.claude/`, `quality_reports/`, `master_supporting_docs/`, `decisions/`, `paper/`, `talks/`, `slides/`, `supplementary/`, `templates/`, `preambles/`, `replication/`, `explorations/`) + Claude-only top-level files (`CLAUDE.md`, `MEMORY.md`, `SESSION_REPORT.md`, `README.md`, `TODO.md`) — so the Scribe working tree contains only what Stata needs at runtime
- `.githooks/pre-push` activated via `git config core.hooksPath .githooks` — refuses any push whose commit range contains a non-`.gitkeep` file under `data/` or `estimates/`
- Daily rhythm: `git pull --rebase origin main` to receive laptop updates; `git push origin main` to send Scribe-originated work (e.g., new `check_*.do` files written on Scribe; M4 attempt logs)

**Mitigations for the three concerns ADR-0020 raised:**

| Concern from ADR-0020 | Mitigation in this ADR |
|---|---|
| GitHub credentials on restricted server | Repo is public; pulls require no auth. Pushes use HTTPS + a Personal Access Token scoped to this single repo only. PAT is stored at `~/.git-credentials` on Scribe (Scribe-account-only, no broader exposure). PAT can be revoked instantly from GitHub if the account is compromised. |
| Accidental `git push` of staged data | Three-layer defense: (a) `.gitignore` blocks `data/`, `estimates/`, untracked-and-ignored at `git add` time; (b) `.githooks/pre-push` scans the commit range and aborts with a clear error if any non-`.gitkeep` file under `data/` or `estimates/` is staged; (c) bypass requires `git push --no-verify` (explicit intentional override, audited via shell history). |
| Upstream supply-chain | Christina is the only person pushing to origin; she is also the only person on Scribe. There is no external-contributor or compromised-collaborator surface. The risk model is closer to "single-user sync" than "open-source consumption". |

**Two artifacts on Scribe that ADR-0020's FileZilla model didn't address:**

- **Per-attempt M4 logs.** Stata writes to `log/` during runs. With git-on-Scribe, the divergence shows up in `git status` and can be committed periodically as audit-trail commits (mirroring laptop-side commit `932a3fc` 2026-05-25 which captured attempt #4 logs). With FileZilla, the same logs required a separate drag-and-drop cycle.
- **Scribe-originated edits.** Any code change made directly on Scribe (e.g., debug fix during an interactive session) can now be committed + pushed directly. Under ADR-0020, those changes would have required manual file transfer back to laptop for staging.

**Provisional status — revisit at end of project.**

- The decision to keep, modify, or revert this workflow happens at the Phase 1c §5.4 acceptance run, before `v1.0-final` tag.
- Revisit criteria: did the audit-trail commits prove useful (e.g., diagnosing failures via committed logs)? Did the pre-push hook fire on any actual accidental staging (validating its protection)? Did any close-calls occur where data nearly leaked despite the safeguards? Any operational friction discovered (auth-flow issues, sparse-checkout edge cases, merge conflicts)?
- If kept: ADR-0007's "no `.git/` on Scribe" line is permanently refined; the offboarding deliverable memo (Phase 1c §5.2 step 8) instructs the successor on the git-based workflow.
- If reverted: a new ADR supersedes this one; Scribe-side `.git/` is removed at the revert point; offboarding memo instructs the successor per ADR-0020's drag-and-drop model.

**Lab guide doc.** Christina is planning a future lab-internal guide on best practices for the Scribe + Stata + git combination. This ADR + the experiment's outcome (kept or reverted, with rationale) become primary input material for that guide. Decisions made here are not project-private; they're learning material.

## Consequences

**Commits us to:**

- Setup procedure documented in `quality_reports/plans/2026-05-25_scribe-setup.md` (5 linear steps; recovery section; 10-item audit checklist; sparse-checkout pattern; pre-push hook activation).
- Pre-push hook (`.githooks/pre-push`) must stay armed (`git config core.hooksPath .githooks`) — disarming it removes a load-bearing safeguard.
- Sparse-checkout config must stay accurate — if Claude infrastructure expands (new top-level Claude-only file), it needs to be added to the exclusion list, or Scribe accumulates noise.
- PAT (or equivalent push auth) is provisioned for Scribe; the offboarding memo must include token-rotation instructions if the workflow is retained.
- Phase 1c §5.4 acceptance run discipline now includes verifying: `git status` clean on Scribe pre-launch, `git log --oneline HEAD..origin/main` empty (Scribe is in sync), pre-push hook armed.
- An evaluation memo at the revisit point (Phase 1c §5.4) documenting whether to keep the workflow. The memo becomes lab-guide input material.

**Rules out:**

- The `sync_to_scribe.sh` / `sync_from_scribe.sh` wrapper scripts described in ADR-0007. They were removed by ADR-0020 and stay removed.
- Mandating one specific git client. Christina uses the command line; a successor may add a GUI client; sparse-checkout config is the only invariant.

**Preserves (from ADR-0007 + ADR-0020, unchanged):**

- Code-data separation: code in git, data on Scribe filesystem only.
- `.gitignore` policy covers `data/`, `estimates/`, build artifacts, etc.
- GitHub repo as frozen archive at `v1.0-final` (the tag content is the same regardless of how Scribe sync is implemented).
- README as sole orientation for unknown future successor (per ADR-0018).
- Documentation discipline — every ADR / session log / commit explains WHY for the future-unknown successor.

**Open questions (revisit at Phase 1c §5.4):**

- Sparse-checkout exclusion list — is the current 12-dir + 5-file set right, or has the project accumulated other Claude-only paths since 2026-05-26?
- Hook coverage — has the pre-push hook fired any false positives, or false negatives we discovered after the fact?
- Auth lifecycle — was the PAT rotated during the project window? Did any auth issues block Scribe operations?
- Lab-guide framing — should the experimental rationale be folded directly into the lab guide, or kept separate as project-specific context?

## Sources

- 2026-05-26 conversation: Christina's request to adopt git on Scribe provisionally and write up the decision
- ADR-0020 (the decision being superseded; provides the prior rationale + concerns)
- ADR-0007 §"Sync model" (the architectural source; sync model is the only piece refined)
- ADR-0018 (offboarding model — successor instructions in the deliverable memo at Phase 1c §5.2 step 8)
- `quality_reports/plans/2026-05-25_scribe-setup.md` (the operational procedure this ADR commits us to)
- `quality_reports/session_logs/2026-05-16_m4-pre-flight-audit-and-protocol.md` (multi-day arc covering the M4 attempts that surfaced the friction in the FileZilla workflow + the safety infrastructure that enabled this revisit)
- Commits: `e31fe15` (.gitignore + .githooks/pre-push), `184ff0d` (clean_va.do hotfix; example of code-change-then-sync cycle), `932a3fc` (M4 attempt #4 logs as audit trail; example of log divergence handling)
- Related: ADR-0001 (consolidation scope), ADR-0002 (runtime — Scribe only), ADR-0021 (sandbox principle)
