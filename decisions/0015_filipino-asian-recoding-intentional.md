# 0015: Filipino-into-Asian recoding intentional; documented in code

- **Date:** 2026-04-27
- **Status:** Decided
- **Scope:** Data
- **Data quality:** Full context

## Context

Phase 0a chunk-8 audit (P3-53) flagged a silent demographic recoding in `caschls/do/share/secondary/pooledsecdemographics.do:23-24`:

```stata
replace race = "Asian" if race == "Filipino"
```

The recoding collapses the Filipino race category into Asian for survey-side demographic analysis. There is no inline comment explaining why; the audit flagged it as a "silent recoding" because someone reading the data downstream would see "Asian" counts without realizing they include Filipino respondents.

CDE administrative data and the CalSCHLS survey both code Filipino as a separate race/ethnicity category (matching California state reporting). Collapsing it into Asian is a deliberate analyst choice — most likely to align the survey-side race buckets with what the K-12 administrative data uses for the school-VA estimation, OR to avoid small-cell-size privacy issues for the Filipino category (Filipino students concentrate in specific geographic areas, leading to thin cells).

Christina's Phase 0e Q-15 answer: **"Yes intentional."**

This decision documents the recoding as deliberate and adds an explanatory comment in code, so the recoding stops looking like a silent bug to future readers.

## Decision

- **The Filipino → Asian recoding in `pooledsecdemographics.do:23-24` is intentional.** Phase 1 does not change the recoding logic.
- **Phase 1 adds an inline code comment** above the recoding line, citing this ADR and giving a one-sentence rationale (analyst choice to align race buckets across administrative and survey data; or whatever Christina specifies as the actual reason during Phase 1 implementation).
- **The README's "Data flow" section flags this as a documented analyst choice** — under a "Demographic recoding decisions" subsection or similar — so the senior coauthor reading the README knows about it without having to grep for the line.
- The same recoding logic, if it appears in any parallel file (e.g., parent-survey or staff-survey demographic processing), gets the same treatment: keep the code, add the comment.

## Consequences

**Commits us to:**

- A multi-line comment in `pooledsecdemographics.do` (and any parallel files) explaining the recoding.
- A README mention so future maintainers see this without code-reading.
- The recoding becomes a documented, defensible analyst choice rather than a silent transformation.

**Rules out:**

- Removing or changing the recoding without a superseding ADR.
- Treating "I see Asian counts" as race counts excluding Filipino in any downstream paper text or table caption.

**Open questions:**

- The exact reason behind the recoding (privacy / small cells / cross-data alignment) is not specified in Q-15. The Phase 1 comment should reflect Christina's actual reasoning, captured at edit time.
- Whether other demographic recodings in the same file (e.g., `pooledsecdemographics.do:59` trans/nb/questioning gender, P3-52) also need their own comments. Defer to Phase 1 sweep — likely yes, but not covered by Q-15 specifically.

## Sources

- `caschls/do/share/secondary/pooledsecdemographics.do:23-24` (the recoding)
- `quality_reports/audits/2026-04-27_T4_answers_CS.md` Q-15
- `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` §2 P3-53
- `quality_reports/audits/round-2/chunk-8-discrepancies.md` A10 (Filipino-into-Asian recoding)
- Related: P3-52 (trans/nb/questioning gender comment-only handling), P3-51 (sex coding inversion landmine) — both have similar "documented analyst choice" character but are not covered by this ADR
