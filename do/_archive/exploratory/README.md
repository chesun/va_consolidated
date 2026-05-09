# do/_archive/exploratory/ — Exploratory / non-load-bearing scripts

**Status:** ARCHIVED. Not invoked from any production pipeline. Preserved for historical reference + archeology.

**Archived:** 2026-05-08 per Phase 1a §3.3 step 8 (plan v3).
**Authority:** ADR-0010 (paper-α canonical producer is `indexalpha.do`; `alpha.do` exploratory).

## What this directory contains

Single-file batch (Step 8). Files copied verbatim from `caschls/do/share/factoranalysis/` (predecessor; Dropbox path). Bodies preserved byte-identical per ADR-0021 — no header note added, no path repointing, not invoked from `do/main.do`.

## Files archived (2)

- `alpha.do` (added Step 8, 2026-05-08) — Cronbach's α over a wider candidate item list (20 items for school climate, 17 for teacher/staff quality, 4 for counseling). Exploratory sensitivity check; not the source of paper-reported α values.
- `allsvyfactor.do` (added Step 11, 2026-05-08) — Exploratory factor analysis on the merged `allsvyqoimeans.dta`. Per file header: "exploratory factor analysis for merge dataset with all 3 survey qoi means". Reads `$caschls_projdir/dta/allsvyfactor/allsvyqoimeans` (LEGACY; pre-relocation predecessor path) and writes ONLY exploratory diagnostics: `allsvyfactor.csv`, `allsvyscreeplot.png`, `allsvyfactoreigen1.csv`. **No chain consumers in either predecessor or consolidated**; archived per ADR-0010 archive convention. Body preserved verbatim per ADR-0021.

## NOT archived (canonical / still active)

- `indexalpha.do` (sister file in same source dir) — **paper-α canonical producer** with narrower 9/15/4-item lists matching the regression-side index construction in `imputedcategoryindex.do` and `compcasecategoryindex.do`. Relocated to `do/survey_va/indexalpha.do` per Phase 1a §3.3 step 7 (commit `3e99c3b`; Tier-2 PASS round 2 `68cf30e`).

## Why archived

Phase 0e Q-3 answer from Christina (recorded in `quality_reports/audits/2026-04-27_T4_answers_CS.md`):

> "`indexalpha.do` produces paper results. `alpha.do` is exploratory."

ADR-0010 formalizes that disposition. The paper text at `paper/common_core_va_v2.tex:407` reports α values cited from `alpha.do`'s wider lists (20/17/4) but the indices those values describe in the regressions are built from `indexalpha.do`'s narrower lists (9/15/4). The Phase 1b §4.1 paper-text correction (revising the footnote item counts to match `indexalpha.do`) is **DEFERRED post-handoff** per Christina 2026-05-07 — out of scope for consolidation; coordinate with senior coauthor on a separate timeline.

## Verify-before-archive (per [LEARN:workflow] 2026-05-08)

Cross-referenced ADR-0010's deprecation against grep across the consolidated `do/` tree:

```
grep -rn 'alpha\.do\b\|alpha\.doh' do/
```

Hits found:
- `do/main.do:307` — flag-comment ("Phase 1a §3.3 step 8 — `alpha.do' archived per ADR-0010 (`do/_archive/exploratory/').") — non-invoking comment, expected.
- `do/survey_va/indexalpha.do` and `do/check/check_survey_indices.do` — match on `indexalpha.do` (different file), not `alpha.do`.

**No invoking caller** of `alpha.do` in consolidated `do/`. Archive is safe — no runtime regression possible.

## Note on body-verbatim convention

ADR-0010 (2026-04-27) reads "moves it to `_archive/exploratory/` with a header note documenting its purpose." ADR-0021 (later, codifying the archive-batch convention) reads "bodies preserved verbatim per ADR-0021 ... not invoked from main.do." The Step 6 archive precedent (siblingvaregs, 27 files) put all explanatory documentation in the per-batch README, not in headers within archived files — so the README is functionally equivalent to ADR-0010's "header note" instruction.

This README satisfies ADR-0010's documentation requirement; the alpha.do body is preserved byte-identical per ADR-0021's verbatim-preservation rule. ADR-0021 supersedes ADR-0010's specific header-note instruction; archive documentation lives at the README level.

## Cross-references

- **ADR-0010** — paper-α canonical (this batch's authority)
- **ADR-0021** — sandbox + body-verbatim archive convention
- **Plan v3** §3.3 step 8
- **Step 6 precedent** — `do/_archive/siblingvaregs/README.md` (27-file archive convention; same pattern applied here at single-file scale)
- **Sister file** — `do/survey_va/indexalpha.do` (canonical paper-α producer; `do do/survey_va/indexalpha.do` invoked from `do/main.do:300`)
