# 0010: Paper-reported Cronbach's α comes from `indexalpha.do`; `alpha.do` archived as exploratory

- **Date:** 2026-04-27
- **Status:** Decided
- **Scope:** Specification
- **Data quality:** Full context

## Context

Phase 0a chunk-6 audit surfaced a paper-α attribution question: two scripts compute Cronbach's α for the survey indices, with different item lists.

- **`alpha.do`** — wider item lists: 20 items for school climate, 17 for teacher/staff quality, 4 for counseling. Computes α with `, std item` (items standardized to mean 0, variance 1; item-test/item-rest correlations reported).
- **`indexalpha.do`** — narrower item lists: 9 items for school climate, 15 for teacher/staff quality, 4 for counseling. Same `alpha` command, different inputs.

The narrower lists (`indexalpha.do`) match the items actually used by the regression-side index construction (`imputedcategoryindex.do` and `compcasecategoryindex.do`). The wider lists (`alpha.do`) appear to be an exploratory pass over a larger candidate set.

The paper text at `paper/common_core_va_v2.tex:407` reports α values of 0.94 (climate, 20 questions), 0.90 (teacher/staff, 17 questions), and 0.66 (counseling, 4 questions). The 20/17/4 numbers in the paper match `alpha.do`'s wider lists — but the indices that those α values describe are built from `indexalpha.do`'s narrower lists. So the paper reports α for one set of items but uses a different (smaller) set in the actual regression indices.

Christina's Phase 0e Q-3 answer: **"`indexalpha.do` produces paper results. `alpha.do` is exploratory."** This decision formalizes that — and notes the discrepancy in the paper text (item counts cited from the exploratory script don't match the production indices).

## Decision

`indexalpha.do` is the **canonical producer of α values reported in the paper**. The Phase 1 paper-text revision (or response-to-referee, depending on timing) updates the item counts and α values at `paper/common_core_va_v2.tex:407` to match `indexalpha.do`'s 9/15/4-item indices.

`alpha.do` is **archived** as exploratory code. Phase 1 moves it to `_archive/exploratory/` with a header note documenting its purpose (sensitivity check on the wider candidate item list) and pointing to `indexalpha.do` as the canonical producer.

The paper text update (line 407 footnote) replaces the 20/17/4-question α values with the 9/15/4-question values from `indexalpha.do`. If the wider-list α values are still wanted as a robustness check, they can be moved to an appendix table or footnote, sourced from `alpha.do`'s output and clearly labeled as exploratory.

## Consequences

**Commits us to:**

- Phase 1 paper-text edit at `common_core_va_v2.tex:407` (footnote reporting α values).
- `alpha.do` retired to `_archive/`.
- The paper-α footnote becomes a verifiable claim — the numbers tie to `indexalpha.do`'s output, and a reviewer or future maintainer can re-run that script to confirm.
- Resolves chunk-6 disc M1 (paper-α attribution issue) — formerly a P1 finding; now downgraded to "Phase 1 paper-text edit, no analysis change."

**Rules out:**

- Reporting α values in the paper that don't correspond to the items used in the regression indices.
- Treating `alpha.do`'s wider-list output as paper-load-bearing.

**Open questions:**

- Whether the wider-list α (from `alpha.do`) is worth keeping as an appendix robustness number. Discretionary — Christina + senior coauthor decision.
- Whether the paper revision (line 407 footnote) is part of Phase 1 (during consolidation) or deferred to the next R&R / response-to-referee cycle. Phase 1 is the right time if the paper is open for edits; otherwise queue for the next revision.

## Sources

- `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` §2 P1-2 / §3.2 Q-3 (formerly P1-5; reframed by this ADR)
- `quality_reports/audits/round-2/chunk-6-discrepancies.md` M1 (item-list mismatch)
- `quality_reports/audits/round-1/2026-04-25_chunk6-survey-va.md` (alpha.do vs indexalpha.do item-list trace)
- `quality_reports/audits/2026-04-27_T4_answers_CS.md` Q-3
- `paper/common_core_va_v2.tex:407` (the footnote being revised)
- `caschls/do/share/factoranalysis/indexalpha.do` (canonical α producer)
- `caschls/do/share/factoranalysis/alpha.do` (archived as exploratory)
- Related: ADR-0011 (sums→means in `imputedcategoryindex.do` — same survey-index family, separate decision)
