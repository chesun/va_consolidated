# 0016: `pooledrr` variable renamed by scope across the four producers

- **Date:** 2026-04-27
- **Status:** Decided
- **Scope:** Specification
- **Data quality:** Full context

## Context

Phase 0a chunk-8 audit found four scripts that each define a variable named `pooledrr` (parent/secondary response rate, pooled across years):

- `caschls/do/share/secondary/parentresponserate.do:72`
- `caschls/do/share/secondary/secresponserate.do:71`
- `caschls/do/share/diagnostics/pooledparentdiagnostics.do:42`
- `caschls/do/share/diagnostics/pooledsecdiagnostics.do:65`

The four definitions are **not identical** — round-2 chunk-8 audit flagged that two formulas are conditional and two are unconditional, producing structurally different rates that all share the same variable name. On disk, each script saves to a different `.dta` file, so there's no actual collision at file-write time. But anyone who loads two of these `.dta` files into the same Stata session and sees `pooledrr` in both will silently get different things.

This is a P3-class issue (chunk-8 D1 / P3-55) — exploratory diagnostic code, not paper-load-bearing — but it's a real correctness landmine for any future maintainer doing comparative diagnostics.

Christina's Phase 0e Q-16 answer: **"Yes [rename]. This is exploratory code so does not impact production code, but good practice nonetheless."**

This decision formalizes the rename as a Phase 1 deliverable.

## Decision

The four `pooledrr` definitions are **renamed in Phase 1** to indicate scope and conditioning:

- `parentresponserate.do` → `pooledrr_parent` (parent-survey, unconditional)
- `secresponserate.do` → `pooledrr_sec` (secondary-survey, unconditional)
- `pooledparentdiagnostics.do` → `pooledrr_parent_diag` (parent-survey, conditional formula)
- `pooledsecdiagnostics.do` → `pooledrr_sec_diag` (secondary-survey, conditional formula)

(Final names subject to Christina's edit at Phase 1 implementation time — the principle is "scope-tagged name", not the specific suffix.)

The rename propagates to:

- The `.dta` save column names produced by each script.
- Any downstream `use` + reference to `pooledrr` in callers — Phase 1 verification step is a `grep -n 'pooledrr' caschls/do/` to find all consumer points and update them. The chunk-8 audit found no paper-shipping consumer; consumer points are diagnostic-only.

A short comment block at the top of each affected file documents the rename and cites this ADR.

## Consequences

**Commits us to:**

- Four file edits + a grep-based consumer sweep.
- The `pooledrr` variable name no longer exists in the consolidated repo — only its scoped successors do.
- Any future analyst comparing parent vs secondary response rates can see at a glance from the variable name which is which.

**Rules out:**

- Re-introducing a generic `pooledrr` variable without an ADR.
- Treating the four definitions as interchangeable.

**Open questions:**

- The exact suffix convention (`_parent` / `_sec` / `_diag`) is a Phase 1 implementation choice, not a hard ADR constraint. As long as the names are scope-tagged and unambiguous, the suffix doesn't matter.
- Whether a similar rename should be applied to other "same name, different formula" patterns surfaced by the audit. Out of scope for this ADR; revisit case-by-case if any others surface during Phase 1.

## Sources

- `quality_reports/audits/2026-04-27_T4_answers_CS.md` Q-16
- `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` §2 P3-55
- `quality_reports/audits/round-2/chunk-8-discrepancies.md` D1 (4 `pooledrr` definitions, 2 structurally different)
- The four files cited above
- Related: ADR-0012 (`_tab.do` CSVs local-only — same "exploratory code, fix for hygiene" character)
