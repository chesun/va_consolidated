# 0020: File transfer mechanism is operator-choice (FileZilla today); refines ADR-0007 sync model

- **Date:** 2026-04-28
- **Status:** Decided
- **Supersedes:** none (refines ADR-0007 §"Sync model")
- **Scope:** Infrastructure
- **Data quality:** Full context

## Context

ADR-0007 specified an `rsync`-based wrapper-script workflow (`sync_to_scribe.sh` / `sync_from_scribe.sh`) for moving code between Christina's local Mac and Scribe `consolidated/`. The wrapper rationale was: clean-tree gate, automatic ADR-0007 exclusion list, idempotent operation, `VERSION` SHA marker on Scribe.

On 2026-04-28 — after the wrapper scripts were drafted and committed — Christina raised the honest assessment: the wrapper layer is heavier than necessary for her actual workflow, and the architectural value (deterministic Scribe-matches-GitHub state) is only relevant at the offboarding moment. Her existing FileZilla + interactive-SSH workflow has worked reliably for years with no observed failure modes. Forcing a new tool (`rsync` + `~/.ssh/config` + ControlMaster + key auth) onto her last 3 months in the project introduces friction without solving an observed problem.

The deeper realization: **the `rsync` wrapper was solving a problem that doesn't actually need to be solved on Scribe.** What matters at offboarding is that the GitHub repo at the `v1.0-final` tag is the canonical artifact. A successor, on inheriting access, can clone GitHub at the tag and copy the contents to Scribe via *whatever mechanism they prefer*. The "Scribe filesystem state matches GitHub commit X" guarantee comes from the GitHub tag itself, not from a sync-script-written `VERSION` marker.

This refines ADR-0007's sync-model subsection only. The architectural commitments (code-data separation, no `.git/` on Scribe, `.gitignore` policy, GitHub-as-frozen-archive, README as sole orientation) remain in force. Only the *implementation detail* of how-to-sync changes.

## Decision

**File transfer between local Mac and Scribe is operator-choice.**

- Christina continues with FileZilla (drag-and-drop) for daily code changes during Phase 1 consolidation. No tool change.
- Interactive SSH (`ssh chesun1@Scribe.ssds.ucdavis.edu` + password prompt) for running the pipeline on Scribe. No `~/.ssh/config` alias or key-auth setup required.
- A future successor inheriting at offboarding chooses their own tool (FileZilla, scp, rsync, `git clone` to a non-Scribe machine + scp the contents over, etc.) — the offboarding deliverable memo (Phase 1c §5.2 step 8 per plan v3) instructs them to clone GitHub at the `v1.0-final` tag and copy the contents to Scribe.

**The `sync_to_scribe.sh` and `sync_from_scribe.sh` scripts are removed from the repo.** They were drafted but never run; deleting them eliminates an over-engineered surface and removes the implicit pressure to set up SSH key auth + ControlMaster.

**No `~/.ssh/config` host alias and no SSH key auth required for offboarding readiness.** If Christina or a successor finds key-auth + ControlMaster useful for ergonomic reasons, they may set it up — but it is not part of the architecture.

**The clean-tree-before-deploy discipline still applies, but is operator-enforced, not script-enforced.** At the Phase 1c §5.4 acceptance run (per ADR-0018), Christina verifies local is at the `v1.0-final` tag with no uncommitted changes BEFORE pushing files to Scribe via FileZilla. This is a one-time discipline at the offboarding moment, not a daily concern.

**The `VERSION` marker on Scribe is dropped.** The GitHub tag `v1.0-final` is the authoritative version stamp. The offboarding deliverable memo records the GitHub tag URL; the successor reads from there.

## Consequences

**Commits us to:**

- Plan v3 §3.1 simplifies: drop steps 3-5 (sync scripts + ControlMaster). Step 1 (create `consolidated/` on Scribe) and step 2 (`.gitignore` per ADR-0007) stand. New step 3: file transfer is operator-choice (FileZilla currently).
- Phase 1c §5.4 acceptance run discipline: Christina manually verifies local clean-tree + tag-match before pushing to Scribe. Documented in the offboarding deliverable memo.
- Offboarding deliverable memo (Phase 1c §5.2 step 8) explicitly instructs successor: "clone GitHub at `v1.0-final`, copy the working tree to Scribe `consolidated/` via your preferred file-transfer tool, then run `stata -b do main.do`."
- Loss of `--delete` semantics: stale code that was deleted locally may persist on Scribe. Operator-managed cleanup at offboarding (one-time pass to remove orphaned files before `v1.0-final` acceptance run).

**Rules out:**

- Committing wrapper scripts (`sync_to_scribe.sh`, `sync_from_scribe.sh`) for sync. Already removed in the same commit as this ADR.
- Mandating `~/.ssh/config` setup or key auth as part of project setup. May be set up at operator discretion; not architectural.
- Documenting "use rsync" as the prescribed mechanism in the offboarding memo. The memo describes the architectural endpoint (GitHub tag + Scribe folder) and lets the successor choose how to bridge them.

**Preserves (from ADR-0007, unchanged):**

- Code-data separation (code in git, data on Scribe).
- No `.git/` on Scribe ever (no GitHub creds on the restricted server).
- `.gitignore` policy (`data/`, `estimates/`, `log/`, `output/`, `*.dta`, `*.smcl`, `*.ster`, etc.).
- GitHub repo as frozen archive at offboarding.
- Documentation discipline — every ADR / session log / commit explains WHY for the future-unknown successor.

**Open questions:**

- Whether to set up a local git repo *on Scribe itself* (Christina considered this 2026-04-28). Rejected: ADR-0007's "no `.git/` on Scribe ever" stands. The security rationale (no GitHub credentials on a restricted server, no risk of accidental `git push` of staged data, no malicious-upstream-supply-chain attack surface) outweighs the convenience. The successor's instruction is to clone GitHub on a non-Scribe machine and transfer the tree; Scribe stays a non-git working filesystem.

## Sources

- 2026-04-28 conversation: Christina's honest-feedback question on whether the rsync wrapper was over-engineered for her actual workflow
- ADR-0007 §"Sync model" (the section being refined; rest of ADR-0007 stands)
- ADR-0018 (offboarding model — successor instructions live in the deliverable memo per §5.2 step 8)
- Plan v3 §3.1 (about to be simplified to reflect this ADR)
- `.claude/rules/air-gapped-workflow.md` (Scribe-as-restricted; transfer mechanism is unspecified there too)
- Related: ADR-0001 (consolidation scope), ADR-0002 (runtime — Scribe only)
