# 0011: Survey indices computed as means, not sums; code fix in `imputedcategoryindex.do` and `compcasecategoryindex.do`

- **Date:** 2026-04-27
- **Status:** Decided
- **Scope:** Specification
- **Data quality:** Full context

## Context

Phase 0a chunk-6 audit found a discrepancy between paper text and code in the survey-index construction:

- **Paper text** (`paper/common_core_va_v2.tex:407`, footnote): "Our indices are **averages across several questions within each category**."
- **Code** (`caschls/do/share/factoranalysis/imputedcategoryindex.do:33-50` and the parallel `compcasecategoryindex.do`): builds each index as a **sum** of items, not a mean. The script comment at L33 even reads: `/* generate linear index by summing the variables in each category */`. The construction pattern is `gen <cat>index = 0; foreach var of local <cat>vars { replace <cat>index = <cat>index + `var' }` — no division by item count.

The discrepancy is **statistically inert** for the regression coefficients reported in the paper: the index is z-standardized at L64-66 immediately after construction (`gen z_<cat>index = (<cat>index - mean) / sd`), and the regression at L101 uses the z-scored version. Z-standardization is invariant to multiplicative rescaling, so summing-then-z and averaging-then-z produce identical coefficient estimates.

But the on-disk variable in `imputedcategoryindex.dta` is a sum. Anyone reading the .dta and expecting a category mean (per the paper's text) gets a sum. That's a paper-vs-code consistency issue that matters for reviewer credibility and for any future analysis that consumes the raw (non-z-scored) index.

Christina's Phase 0e Q-11 answer: **"fix code"** — change the construction to compute means rather than fix the paper text.

## Decision

The index-construction blocks in `imputedcategoryindex.do` and `compcasecategoryindex.do` are **modified to compute category means**, not sums. The fix is mechanical: divide each accumulated `<cat>index` by the count of items in `<cat>vars` after the foreach loop, before the z-standardization step. Pattern:

```stata
gen climateindex = 0
foreach climatevar of local climatevars {
    replace climateindex = climateindex + `climatevar'
}
replace climateindex = climateindex / `: word count `climatevars''   // NEW: convert sum to mean
```

This matches what the paper text claims. The header comment at L33 is updated from "summing" to "averaging."

Statistical effect on the paper: **none** for the regression-coefficient tables (Table 8 and any related), because the indices are z-scored before entering the regression. The numerical change is bounded to the on-disk raw index variable scale; downstream consumers reading the raw index would have seen sums and now see means.

Christina performs the code edit during Phase 1. The Phase 1 verification step re-runs `imputedcategoryindex.do` and `compcasecategoryindex.do` and confirms that downstream regression outputs (the index-on-VA regressions in `imputed_index_bivar_wdemo.dta`, etc.) are unchanged at the coefficient-rounding level the paper reports.

## Consequences

**Commits us to:**

- Two-line code edits in two files.
- One verification re-run of the index-on-VA regression chain to confirm coefficient invariance.
- Paper-vs-code consistency restored without any paper-text edit.
- The `imputedcategoryindex.dta` and `compcasecategoryindex.dta` raw index variables now match what the paper says they are.

**Rules out:**

- The alternative resolution (fix paper text instead of code). Christina chose the code-fix path; reverting requires a superseding ADR.
- Leaving the inconsistency unresolved.

**Open questions:**

- Whether other downstream consumers of the raw index (outside the regression chain) exist. Phase 0a chunk-6 audit found none, but if Phase 1 verification surfaces any consumer that depends on the sum scale, that consumer needs adjustment.
- Whether a comment in the code should explain *why* division-by-item-count was added (anchor point for future maintainers). Recommend yes — a one-line comment citing this ADR.

## Sources

- `paper/common_core_va_v2.tex:407` (paper text claiming averages)
- `caschls/do/share/factoranalysis/imputedcategoryindex.do:33-50` (sum implementation; fix target)
- `caschls/do/share/factoranalysis/compcasecategoryindex.do` (parallel sum implementation; fix target)
- `quality_reports/audits/round-1/2026-04-25_chunk6-survey-va.md` L309, L353, L772 (original flag)
- `quality_reports/audits/round-2/chunk-6-discrepancies.md` A3 + Q2 (sum-vs-mean)
- `quality_reports/audits/2026-04-27_T4_answers_CS.md` Q-11 (Christina: "fix code")
- Related: ADR-0010 (paper-α from `indexalpha.do` — same survey-index family); ADR-0009 (v1 canonical — separate concern, no overlap)
