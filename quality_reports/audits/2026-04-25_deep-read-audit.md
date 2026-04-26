# Phase 0a Deep-Read Audit

**Status:** IN PROGRESS (chunks landing as agents complete)
**Plan reference:** `quality_reports/plans/2026-04-25_consolidation-plan-draft.md` §6
**Scope:** every file referenced (transitively) by `caschls/do/master.do` or `cde_va_project_fork/do_files/do_all.do` post-archival, plus `.doh` helpers, custom `.ado`, and Python upstream geocoding scripts.

**Per-file template** (verbatim from plan §6.2):

```markdown
### File: <repo>/<path/to/file>.do

**Predecessor location**: <which repo, original path>
**Owner**: Matt | Christina | both
**Pipeline phase** (target consolidated layout): Phase N (data_prep | sibling_xwalk | samples | va | survey_va | share)
**Lines**: <count>
**Purpose** (1 sentence):

**Inputs** (datasets read):
- $cleandir/cde/cst/<name>.dta
- ...

**Outputs** (datasets written, tables, figures):
- $projdir/dta/<path>.dta
- ...

**Sourced helpers** (.doh files):
- $vaprojdir/do_files/sbac/macros_va.doh
- ...

**Calls** (other do-files via `do`):
- ...

**Called by**:
- caschls/do/master.do (which block / line)

**Path references that need updating in consolidation**:
- $vaprojdir → $projdir
- $projdir/do/share/X → $projdir/do/<new-target>/X
- (any hardcoded /home/research/... paths)

**Stata version requirements / non-trivial syntax**:
- (e.g., uses Stata 17 frame syntax; uses regsave package; etc.)

**ssc/community packages used**:
- vam, estout, coefplot, ...

**Gotchas / non-obvious behavior** (line numbers):
- L<n>: <description>
- L<m>: <description>

**Reference to paper outputs**:
- Produces inputs to: Table X, Figure Y (per paper map)
- OR: helper / not directly producing paper outputs

**Notes / open questions**:
- ...
```

---

## Chunks

### Chunk 1: Foundation (sequential — establishes path/naming/call-graph context for all downstream chunks)

In progress. Files in scope:

- `cde_va_project_fork/do_files/settings.do`
- `caschls/do/settings.do`
- `cde_va_project_fork/do_files/do_all.do`
- `caschls/do/master.do`
- `cde_va_project_fork/do_files/sbac/macros_va.doh`
- `caschls/do/ado/*` (custom-modified vam package)

*(entries appended below as foundation agent completes)*

---

## Cross-cutting findings (rolled up across chunks)

### N1: siblingoutxwalk relocation -- dependency trace

*(populated when sibling_xwalk chunk completes)*

### N2: server-folder reconciliation

*(populated when foundation chunk surfaces the two-server-folder situation in settings.do)*

### Path-reference catalog

*(separate document: `quality_reports/audits/2026-04-25_path-references.md` — populated incrementally)*

### Dependency graph

*(separate document: `quality_reports/audits/2026-04-25_dependency-graph.md` — populated incrementally)*
