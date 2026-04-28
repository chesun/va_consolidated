# 0013: `mattschlchar.do` clean-gate kept; `sch_char.dta` consumed as-is, not reproduced

- **Date:** 2026-04-27
- **Status:** Decided
- **Scope:** Data
- **Data quality:** Full context

## Context

`cde_va_project_fork/do_files/share/mattschlchar.do` is a Christina-authored wrapper (header L4-5: "written by Che Sun") that produces `schlcharpooledmeans.dta`, the school-characteristics file consumed by the paper Table 8 panel producers. Despite the `matt`-prefixed filename, the wrapper itself is in scope for Phase 1.

The complication is that the wrapper has two execution paths:

- **`local clean = 0` (production)** — reads a pre-built `sch_char.dta` from disk and pools it into `schlcharpooledmeans.dta`. This is what runs every time the pipeline runs in production.
- **`local clean = 1` (rebuild from raw)** — re-creates `sch_char.dta` from raw sources, including a hardcoded path into Matt Naven's user directory (`/home/research/.../msnaven/...`). This branch has not been exercised in current production; it depends on Matt's user dir being readable.

Phase 0a chunk-6 audit flagged the `clean=1` branch as a replication weak point (P2-15) — if Matt's account is decommissioned, the rebuild path breaks. Original audit recommendation was Phase 1 vendoring of the underlying `sch_char.dta`.

Christina's Phase 0e Q-5 answer: **"keep the gate. will not need to reproduce original file, avoid cross user dependency."**

The decision is to keep `local clean = 0` permanently and treat `sch_char.dta` as a pre-existing input artifact. The rebuild branch is dormant but not deleted (preserves archeology).

This decision composes with ADR-0007 (code-data separation) and ADR-0008 (external crosswalks vendoring): all three resolve different facets of the "Matt-source dependency" question. ADR-0017's no-touch rule does not apply here because `mattschlchar.do` is Christina's wrapper, not Matt's code.

## Decision

- **`mattschlchar.do` is in scope for Phase 1** (Christina's file, not Matt's). Code edits permitted.
- **The `local clean = 0` gate stays as-is.** Production reads pre-built `sch_char.dta`; the rebuild branch does not run.
- **`sch_char.dta` is treated as a pre-existing input artifact** consumed as-is, not reproduced from raw. It lives on Scribe (gitignored per ADR-0007) at its current production path.
- **The rebuild branch (`local clean = 1`) is preserved but commented as dormant.** Header note added to `mattschlchar.do` documenting that the rebuild path is not maintained, citing ADR-0013, and pointing future maintainers to the ADR if they ever need to revive it.
- **No vendoring of the underlying raw sources** that the rebuild branch reads. They stay in Matt's user directory, unchanged. Same posture as ADR-0008 for the CCC/CSU outcomes crosswalks: leave alone unless the dependency breaks.

## Consequences

**Commits us to:**

- A documentation comment in `mattschlchar.do` explaining the dormant rebuild branch and citing this ADR.
- `sch_char.dta` is permanently a runtime input, not a buildable output of this codebase.
- If `sch_char.dta` ever needs to be rebuilt, that's a Phase 2+ activity requiring a successor ADR (analogous to ADR-0008's "if Matt's directory becomes unavailable" clause).

**Rules out:**

- Phase 1 effort spent vendoring or rebuilding from Matt's raw sources.
- Treating the `clean=1` branch as runnable production code without a superseding ADR.

**Open questions:**

- Whether `sch_char.dta` should be defensively backed up to `consolidated/data/raw/upstream/` analogous to ADR-0008's CCC/CSU `.dta` files. Christina did not request this in Q-5; defaulting to no. Can revisit if the file is ever discovered to be at risk.
- Provenance of `sch_char.dta` itself (which fields, which years, who built it originally) is documented in `mattschlchar.do`'s header comments and the audit chunk-6 doc, but not in a standalone provenance file. README points to those.

## Sources

- `cde_va_project_fork/do_files/share/mattschlchar.do` L4-5 (Christina's authorship), L17 (the gate)
- `quality_reports/audits/2026-04-27_T4_answers_CS.md` Q-5
- `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` §2 P2-15 (original audit framing as replication weak point)
- `quality_reports/audits/round-2/chunk-6-discrepancies.md` A4 (mattschlchar cross-user path)
- Related: ADR-0007 (code-data separation — `sch_char.dta` lives on Scribe, not in git); ADR-0008 (external crosswalks — same posture for Matt-sourced data); ADR-0017 (Matt's files untouched — does NOT apply here since `mattschlchar.do` is Christina's)
