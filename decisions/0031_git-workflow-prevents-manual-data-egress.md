# 0031: git-on-Scribe eliminates the manual drag-to-local data-egress risk (data-security rationale for the workflow)

- **Date:** 2026-06-13
- **Status:** Decided
- **Scope:** Infrastructure
- **Refines:** #0022 (Scribe-git-sync workflow, provisional) — adds a data-security rationale; does not reverse it
- **Data quality:** Full context

## Context

ADR-0022 adopted a git-based sync model on Scribe (sparse-checkout clone, `.gitignore` excluding `data/`+`estimates/`, `.githooks/pre-push` blocking any data file in a push), provisionally, to be revisited at offboarding before `v1.0-final`. Its data-leak analysis focused on the *push* direction: preventing restricted data from being committed and pushed to GitHub.

While drafting the PI handoff document (`HANDOFF.md`) at offboarding, Christina identified a second, distinct data-security advantage of the git workflow that ADR-0022 did not name — one on the *pull / local-copy* direction:

**The manual-transfer (FileZilla drag-and-drop) workflow leaves open a real and recurring confidentiality risk: accidentally dragging restricted data from the server pane onto the local machine.** A FileZilla session shows the Scribe (remote) and laptop (local) file trees side by side; a single mis-drop copies a restricted `.dta` onto a personal machine, which is a data-security/confidentiality violation. Christina notes this has actually happened to her and to others at the lab — it is not hypothetical.

The git workflow makes that specific mistake mechanically impossible:

- The data folders are gitignored, so they are not tracked. `git pull` brings down **only tracked files (code)** — the data is not in the repository, so there is no path by which a pull can land restricted data on a laptop.
- The `pre-push` hook (ADR-0022) closes the reverse direction.

So git removes the human-error egress path that manual transfer leaves open, in addition to the push-side protection ADR-0022 already documented. `geodist`-style live downloads aside, the data simply never travels through git in either direction.

## Decision

- **Record the data-security advantage of git over manual file transfer as an affirmed rationale for the Scribe sync workflow:** because the data is gitignored, the git workflow cannot copy restricted data onto a local machine, eliminating the accidental drag-to-local egress that drag-and-drop permits (and that has caused real incidents at the lab).
- **The offboarding workflow recommendation is git**, on this data-security basis plus the audit-trail/convenience basis in ADR-0022. This resolves ADR-0022's provisional keep/revert question in favor of *keep*, as the recommendation handed to the successor.
- **The successor's operational choice still stands** (per ADR-0020 / ADR-0022): Paco may use FileZilla drag-and-drop if he prefers. This ADR documents *why git is the safer default*, not a mandate. The `HANDOFF.md` §4/§7 framing presents the safety case while leaving the method to the operator.
- **This is lab-guide input material.** ADR-0022 anticipated a future lab-internal guide on the Scribe + Stata + git workflow; this drag-to-local argument is a primary point for that guide.

## Consequences

**Commits us to:**

- `HANDOFF.md` states the git safety advantage (the drag-to-local point) in §4 (one line) and §7 (the full case), framed as informing the successor's choice rather than mandating it.
- The data-security story for the workflow now covers both directions: push-side (pre-push hook, ADR-0022) and pull/local-copy-side (gitignored data, this ADR).

**Does not change:**

- ADR-0022's mechanics (sparse-checkout, `.gitignore`, pre-push hook) — unchanged; this ADR adds rationale, not new infrastructure.
- The successor's freedom to choose a transfer method.

## Sources

- Workflow + guardrails: ADR-0022 (Scribe-git-sync provisional), ADR-0020 (sync mechanism operator-choice), ADR-0007 (code-data separation)
- Enforcement: `.gitignore` (data/ + estimates/ excluded), `.githooks/pre-push`, `quality_reports/plans/2026-05-25_scribe-setup.md`
- Handoff framing: `HANDOFF.md` §4, §7
- Origin of the insight: Christina, 2026-06-13, during handoff-doc drafting (lab experience: accidental drag-to-local has occurred)
