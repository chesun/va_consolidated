# 0018: Offboarding model refinement — Kramer is custodian; successor unknown; README is only orientation

- **Date:** 2026-04-27
- **Status:** Decided
- **Supersedes:** none (refines ADR-0007 §"Handoff endpoint")
- **Scope:** Infrastructure
- **Data quality:** Full context

## Context

ADR-0007 was written assuming a "handoff" event — Christina hands credentials and project to a successor coauthor. Christina clarified 2026-04-27 (post-ADR-0007 commit): there will be no live handoff. Christina's exit from the project is part of her **offboarding** from the lab. The deliverable goes to **Kramer (lab data-management custodian)**, who holds the artifact but is not the active maintainer. A future successor (whenever and whoever) inherits the deposited artifact through standard lab onboarding — no Christina-to-successor introduction occurs.

This refines the endpoint model in ADR-0007 without changing the rest of the architecture. The sync model, code-data separation, GitHub-as-frozen-archive, no-`.git/`-on-Scribe, and `.gitignore` policy from ADR-0007 all stand. What changes is the audience and the timing of the freeze.

## Decision

**Endpoint = Christina's offboarding date, not a handoff event.**

- Christina produces the consolidated artifact (GitHub repo + Scribe `consolidated/` folder) as part of her **offboarding deliverables** to the lab.
- The artifact is **deposited with Kramer** (lab data management). Kramer is custodian, not maintainer — they preserve and transfer when a successor is identified.
- The future successor is **unknown at offboarding time**. The README and audit trail (decisions/, quality_reports/) are the **only orientation** they will receive. There is no "Christina available for questions" period.
- The freeze tag at GitHub is `v1.0-final` (not `v1.0-handoff`), pushed at Christina's last commit before offboarding.
- Scribe credential continuity is **lab-onboarding-mediated** when a successor is hired. Christina does not directly hand SSH access to anyone.

**Acceptance criterion before `v1.0-final`:**

Christina runs the full pipeline end-to-end on Scribe (`stata -b do main.do`) and verifies it completes successfully **before** tagging `v1.0-final` and depositing the artifact with Kramer. This is non-negotiable — depositing a broken pipeline with Kramer would be worse than not depositing at all. The full-pipeline acceptance run produces:

- A clean log at `consolidated/log/` showing all phase toggles ran without error.
- All expected output artifacts (paper tables in `tables/share/.../pub/`, paper figures in `figures/share/.../pub/`) present and correctly dated.
- Documented runtime in the offboarding-deliverable memo (so successor knows what to expect).

This run is the last action Christina takes before deposit. It pairs with the README cold-read test (Phase 1 plan v3 §5.3 step 10) — together they constitute the acceptance criteria for offboarding.

**Implications for the README** (Phase 1c deliverable):

- Written for a reader with **no live introduction**. Cold-read test is one of two acceptance criteria.
- No "Contact Christina" section as primary support. May include "Christina's last known contact (post-2026-MM-DD: not guaranteed)" but the README must stand without it.
- The artifact must be self-explanatory using only what's in the repo + Scribe `consolidated/`. Anything Christina knows that isn't written down is lost at offboarding.

**Implications for Kramer's role:**

- Kramer holds the GitHub repo URL + Scribe `consolidated/` folder location.
- Kramer transfers the artifact (or onboards a successor onto it via lab IT) when a successor is identified.
- Kramer is NOT expected to run the pipeline, debug, or interpret findings.

## Consequences

**Commits us to:**

- Phase 1 plan v3's "handoff prep" framing renames to "offboarding deliverable preparation" throughout.
- README has elevated importance — Phase 1c puts more weight on the cold-read test.
- A full-pipeline acceptance run on Scribe is the last action before `v1.0-final` tag. Plan must budget time for it (1-2 days for run + verification + documenting runtime).
- No buffer period after the freeze. Anything Christina hasn't written down by `v1.0-final` tag is gone from the project's institutional knowledge.
- An offboarding-deliverable-inventory memo (in `quality_reports/handoff/` — keep the directory name for predictability) is part of Phase 1c. Captures: repo URL, Scribe folder location, where data lives, where Matt's untouched files are, what Kramer should know, and the acceptance-run log path.

**Rules out:**

- Treating any post-offboarding outreach to Christina as part of the project's recovery plan. If something breaks after `v1.0-final`, it's the successor's problem to solve from documentation alone.
- Naming a specific successor in the README. Generic framing only.
- Tagging `v1.0-final` before the full-pipeline run completes successfully. If the run fails, root-cause and fix; do not deposit.

**Open questions:**

- The exact offboarding date is not yet set. Phase 1 timeline (~3 months from Phase 1a start) is the working assumption.
- Whether Kramer wants a verbal walkthrough of what the artifact contains at deposit time. Discretionary; not required by this ADR. If yes, Christina records it in a session log so future-reader has access.

## Sources

- 2026-04-27 conversation: Christina clarified handoff vs offboarding semantics + acceptance-run requirement
- ADR-0007 (the section being refined — sync model and code-data separation stand)
- `CLAUDE.md` — meta-governance ("would another empirical researcher forking this repo benefit from this?") aligns with the cold-read posture this ADR formalizes
- Related: ADR-0001, ADR-0002, ADR-0003 (foundational); ADR-0017 (Matt's files untouched — successor inherits this constraint via the README's "What NOT to touch" section)
