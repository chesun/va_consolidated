# 0003: Languages -- Stata primary; Python preserved for upstream geocoding

- **Date:** 2026-04-25
- **Status:** Decided
- **Scope:** Methodology
- **Data quality:** Full context

## Context

The production analytic pipeline -- everything that produces tables and figures in `common_core_va_v2.tex` -- is written in Stata. Both predecessor repos also contain a `py_files/` directory.

The status of `py_files/` was clarified across two onboarding rounds:

- **Round 4 (initial):** Christina described py_files as "dead/unused" in both predecessors.
- **Section 10 B1 (correction):** Christina revisited and corrected: `py_files/` is the upstream geocoding code (Matt's work). Outputs are static inputs to the Stata pipeline; the Python scripts are not run as part of normal pipeline runs but are preserved for completeness and record-keeping.

The v2 plan review locked this as a hard requirement: Python is preserved, not deleted.

This ADR exists to commit the language scope so the consolidated repo's main.do does not attempt to invoke Python and so the migration plan correctly carries py_files forward.

## Decision

- **Stata is the production-pipeline language.** `main.do` and every script it transitively invokes run in Stata. Stata version pinned to 17 per ADR-0015 (forthcoming).
- **Python is preserved as upstream-only.** The consolidated repo gets a root-level `py/` directory; geocoding scripts move from `<predecessor>/py_files/` to `py/upstream/`. These scripts are NOT invoked by `main.do`. Geocoded outputs already exist as static datasets on Scribe.
- **R is out of scope.** No R scripts in scope; no R rules apply.

## Consequences

- `main.do` calls only Stata `do` invocations; no shell-out to Python.
- `py/upstream/` ships with a `py/upstream/README.md` documenting:
  - That these scripts are preserved for completeness and reproducibility traceability.
  - The fact that geocoded outputs are static on Scribe; re-running the geocoding requires a separate manual decision.
  - The Python version, dependencies, and any API keys used (without committing the keys themselves; if applicable, document credential locations rather than values).
- The `r-code-conventions.md` rule does not apply to this project (R is out of scope).
- The `python-code-conventions.md` rule applies *narrowly* to `py/upstream/`. Code there should still follow virtual-env hygiene per the rule, but does not need pipeline-grade defensive coding since it doesn't run in normal flow.
- Future Python additions (e.g., new geocoding pass, ML models for student matching, NLP for survey free-text) require a new ADR. They would either move into `py/upstream/` (still upstream, still off-pipeline) or trigger a more substantial decision about multi-language pipeline orchestration.

## Sources

- `quality_reports/session_logs/2026-04-24_project-onboarding.md` :: round 4 (initial answer)
- `quality_reports/onboarding/2026-04-25_context-dump.md` :: §10 B1 (correction)
- `quality_reports/plans/2026-04-25_consolidation-plan-draft.md` :: §2 inputs, §3 folder structure (py/ at root)
- `.claude/rules/python-code-conventions.md` (applies narrowly to py/upstream/)
