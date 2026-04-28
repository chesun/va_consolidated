# 0014: Old paper draft `common_core_va.tex` preserved as historical artifact

- **Date:** 2026-04-27
- **Status:** Decided
- **Scope:** Infrastructure
- **Data quality:** Full context

## Context

Two paper LaTeX files coexist in the project's predecessor location:

- `paper/common_core_va.tex` — older draft, predates a structural revision. References `tables/sbac/counts_k12.tex` (an older path).
- `paper/common_core_va_v2.tex` — current working draft (canonical, in `~/github_repos/va_paper_clone/paper/`). References `tables/share/va/pub/counts_k12.tex` (the modern path produced by `caschls/do/share/sample_counts_tab.do` — the v1-only producer per ADR-0009 / Q-19).

Phase 0a chunk-8 audit T3.6 verification confirmed the apparent `counts_k12.tex` "path mismatch" was simply OLD-paper-vs-NEW-paper divergence — the modern path is correct for the modern paper, and the old path matches the old paper. There's no live bug.

Original audit suggestion (P3-56): Phase 1 cleanup deletes both `paper/common_core_va.tex` and the stale `tables/sbac/counts_k12.tex`. Christina's Phase 0e Q-13 answer: **"old paper draft, do not touch, keep for record keeping."**

The decision is to preserve the old draft as a frozen historical artifact, not delete it. This composes with ADR-0007's documentation discipline ("audit trail with the README in mind") — the old draft *is* part of the project's history and may be referenced when explaining how the paper evolved.

## Decision

- **`paper/common_core_va.tex` is preserved as a historical artifact.** Phase 1 does NOT delete it.
- **`tables/sbac/counts_k12.tex` (the old-paper-companion table) is also preserved.** Phase 1 does NOT delete it.
- Both files are flagged with a header comment (or a sibling `README.md` in the relevant directories) noting:
  - This is the OLD draft, superseded by `common_core_va_v2.tex` (which lives canonically at `~/github_repos/va_paper_clone/paper/`).
  - It is preserved for historical reference only. Do not edit. Do not compile expecting the modern result.
  - Cite ADR-0014 for the preservation rationale.
- `paper/common_core_va_v2.tex` (and its companion bibliography, figures, tables) remains the canonical current draft.

The README's "Where things are documented" / "Project history" section points to the old draft as part of the archeology, alongside the predecessor repos and ADR log.

## Consequences

**Commits us to:**

- One header-comment edit (or one small README) per preserved file. Two files total.
- Lightly increased repo size — both are small `.tex` files (likely <100KB combined). Acceptable.
- Future maintainers see both drafts and understand which is current.

**Rules out:**

- Phase 1 deletion of either file.
- Treating `common_core_va.tex` as if it were a current draft. Anyone editing it would be working on a frozen artifact.

**Open questions:**

- Whether the old draft's bibliography / figures / tables should ALL be preserved, or just the `.tex` source. Default: preserve everything that compiled with the old draft, since file-by-file pruning would require knowing exactly which artifacts are old-only vs shared. Erring on the side of preservation (cheap, consistent with Q-13).
- Whether the canonical paper (`common_core_va_v2.tex`) eventually moves into the consolidated repo or stays at `va_paper_clone`. Out of scope here; ADR-0001 marks the consolidated paper folder as empty for current milestone.

## Sources

- `quality_reports/audits/2026-04-27_T4_answers_CS.md` Q-13
- `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` §2 P3-56 (original deletion suggestion, now overridden)
- `quality_reports/audits/round-2/chunk-8-discrepancies.md` M1 (counts_k12.tex path mismatch resolution)
- `quality_reports/audits/round-2/t3-verifications.md` T3.6 (OLD-paper / NEW-paper divergence confirmed)
- `paper/common_core_va.tex` (the file being preserved)
- `~/github_repos/va_paper_clone/paper/common_core_va_v2.tex` (the canonical current draft)
- Related: ADR-0001 (consolidation scope), ADR-0009 (v1 canonical / `sample_counts_tab.do` v1-only)
