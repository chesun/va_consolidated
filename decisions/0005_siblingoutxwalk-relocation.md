# 0005: `siblingoutxwalk.do` canonical location — `do/sibling_xwalk/`

- **Date:** 2026-04-27
- **Status:** Decided
- **Scope:** Infrastructure
- **Data quality:** Full context

## Context

`siblingoutxwalk.do` lives inside `caschls/do/share/siblingvaregs/` — the directory whose other contents are deprecated per ADR-0004. But the file itself is **not** deprecated: it builds the family-crosswalk dataset that maps students sharing an address+surname into family groups (transitive closure via `group_twoway`, with a 10-child cap). This crosswalk is consumed by the canonical sample-construction code in `cde_va_project_fork/do_files/sbac/samples/` — every sibling-control sample (`s`, `ls`, `as`, `las`, `sd`, `lsd`, `asd`, `lasd`) needs the family grouping the file produces.

Two callers reference it today:

- `cde_va_project_fork/do_files/do_all.do:142` — `do $projdir/do/share/siblingvaregs/siblingoutxwalk.do`
- `caschls/do/master.do:103` — same call

Phase 0a chunk-5 audit verdict (N1 SAFE-to-relocate, reaffirmed in round-2): no internal references to the parent directory; file can be moved without breaking any output. Per the consolidated repo's folder layout (CLAUDE.md), there is already a `do/sibling_xwalk/` slot reserved for this kind of producer.

This decision is the relocation logistics that flow from ADR-0004 — placed in a separate ADR because the relocation is a Phase 1 implementation step with concrete file-move + caller-update mechanics, distinct from the canonical-pipeline framing in ADR-0004.

## Decision

`siblingoutxwalk.do` is **moved to `do/sibling_xwalk/siblingoutxwalk.do`** in the consolidated repo during Phase 1. The two callers update their `do` lines to reference the new path. The file's contents are not modified during the move.

## Consequences

**Commits us to:**

- One file move + two caller updates during Phase 1.
- All other contents of `caschls/do/share/siblingvaregs/` go to `_archive/` per ADR-0004 — `siblingoutxwalk.do` is the **only** file from that directory that survives consolidation.
- Family-crosswalk producer becomes self-evident in the folder layout (`do/sibling_xwalk/`) rather than buried in a deprecated subtree.

**Rules out:**

- Leaving `siblingoutxwalk.do` alongside the archived deprecated regression files (would be confusing: "why is this one file here when everything else around it is dead?").

**Open questions:**

- None. The N1 verdict from chunk-5 was unambiguous and the relocation is mechanical.

## Sources

- `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` §1 (N1 SAFE to relocate)
- `quality_reports/audits/round-2/chunk-5-discrepancies.md` (N1 reaffirmed)
- `cde_va_project_fork/do_files/do_all.do:142` (caller 1)
- `caschls/do/master.do:103` (caller 2)
- `CLAUDE.md` folder layout (reserved `do/sibling_xwalk/` slot)
- Related: ADR-0004 (sibling-VA pipeline canonical, parent decision)
