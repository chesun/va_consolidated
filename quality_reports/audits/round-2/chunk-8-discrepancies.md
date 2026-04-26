# Chunk 8 — Discrepancy Report (Round-1 vs Round-2)

**Chunk:** 8 — Sample construction (26 files: `cde_va_project_fork/do_files/sbac/` × 3 + caschls poolingdata/responserate/sample/share-demographics)
**Date:** 2026-04-26
**Round-1 source:** `quality_reports/audits/round-1/2026-04-25_chunk8-samples.md` + summary at `2026-04-25_deep-read-audit.md` §"Chunk 8"
**Round-2 source:** `quality_reports/audits/round-2/chunk-8-verified.md`

---

## Summary table

| Category | Count |
|---|---|
| AGREE | 14 |
| ROUND-1-MISSED | 3 |
| ROUND-2-MISSED | 2 |
| DISAGREE | 1 (round-1 said 2 `pooledrr` definitions; round-2 found 4) |
| TEMPORAL ARTIFACTS | 0 |

**Headline findings:**

1. **Sample-restriction map (paper Table A.1) FINALIZED** — both rounds agree on the 9-row map (R1: g11; R2: 95% grade-span; R3: first scores; R4: conventional; R5: cohort > 10; R6: non-missing test; R7: non-missing demographics; R8: non-missing prior; R9: cell N >= 7). Two coexisting cuts (cohort > 10 at school level; N >= 7 at school×year×subject cell level) are NOT redundant.

2. **Paper Table A.1 producer is `do_files/share/sample_counts_tab.do`** (wired in `do_all.do:226`) — both rounds agree. The archived `_archive/matt_original/sum_stats.do` is NOT wired and is superseded. Q8.1 (round-1 alarm about archival) was already corrected in chunk 9 round-1.

3. **DISAGREE: 4 `pooledrr` definitions, not 2.** Round-2 found `pooledrr` defined in 4 places (round-1 said 2). Round-2 is correct (T3-verifiable). The two diagnostics-file definitions have a structurally different formula (raw 5-year sum, not conditional on year-having-response). All 4 save to different .dta files; on-disk collision is avoided. But variable-name overload is a real footgun for any code that joins two of these datasets.

4. **NEW from round-2: paper-vs-code path mismatch for `counts_k12.tex`** — paper `paper/common_core_va.tex:163` reads `tables/sbac/counts_k12.tex` but `sample_counts_tab.do:615` writes to `tables/share/va/pub/counts_k12.tex`. Either the paper has a stale path or there's a copy step somewhere outside chunk 8. **Possible Phase 1 path-rerouting issue.**

---

## AGREE rows

| # | Finding | R1 cite | R2 cite | Tier | Status |
|---|---|---|---|---|---|
| A1 | **Paper Table A.1 producer = `do_files/share/sample_counts_tab.do`** wired at `do_all.do:226`. Archived `_archive/matt_original/sum_stats.do` is not wired (superseded). | R1 chunk-9 §"CORRECTION to chunk 8 finding" | R2 §1 (executive summary) | T3 | LOCKED |
| A2 | **9-row sample-restriction map** maps cleanly to `sample_counts_tab.do` and `touse_va.do` enforcement (different code paths but same conjunction). | R1 §"Final sample-restriction map" | R2 §Q1 sample-restriction-map table | T3 | LOCKED |
| A3 | **Two coexisting cohort cuts**: `cohort_size <=10` (school × year level) at `touse_va.do:109` / `create_va_sample.doh:54`; `n_g11_<subj><7` (school × year × subject cell) at `touse_va.do:155, 180`. NOT redundant. | R1 §"≥7 vs ≤10 question DEFINITIVELY RESOLVED" | R2 §Q2 | T3 | LOCKED |
| A4 | **`gr11enr_mean` weight chain**: produced upstream → merged via `mergegr11enr.do:15, 25, 35` for parent/sec/staff → consumed downstream as `[aweight=gr11enr_mean]` (`_wt` token). | R1 §"`gr11enr_mean` weight chain confirmed" | R2 §Q3 | T3 | LOCKED |
| A5 | **`touse_va.do:104, 106` paper-mentioned but NOT-implemented restrictions** (>25% special ed, home/hospital). Comments stand alone with no code. | R1 chunk-8 New bugs:9 | R2 §Q11; per-file entry §1 | T3 | LOCKED — paper-code consistency issue |
| A6 | **`touse_va.do:117 / create_out_samples.do:71` `enr_ontime → enr` silent rename**: drops original `enr enr_2year enr_4year` and renames `_ontime` variants to take their place. Silent semantic shift. | R1 chunk-8 New bugs:10 | R2 §Q12; per-file entry §1 | T3 | LOCKED — Phase 1 document |
| A7 | **`create_score_samples.do:240-247` and `create_out_samples.do:225-232`** `egen n_g11_<...>_sp` computed but never `save`'d. Dead code. | R1 chunk-8 New bugs:2 | R2 §Q13; per-file entry §2 | T3 | LOCKED — Phase 1 cleanup |
| A8 | **Sex coding inversion**: `secdemographics.do:102` (`sex==1→male`); `elemdemographics.do:67` (`sex==1→female`). Recoding produces consistent `female`/`male` indicators downstream, but raw `sex` has different semantics across surveys. | R1 chunk-8 New bugs:6 | R2 §Q9; §22 | T3 | LOCKED — landmine documentation |
| A9 | **Trans/nb/questioning gender (1718/1819 sec)** acknowledged in `secdemographics.do:59` comment but never ingested. Only binary `sex` handled at L103-107. | R1 chunk-8 New bugs:7 | R2 §Q10; §22 | T3 | LOCKED |
| A10 | **`pooledsecdemographics.do:23-24`** silent demographic recoding: `gr<i>asianenr += filipinoenr`. Filipino students silently merged into Asian category. Downstream `pooledasianrr` actually means "Asian + Filipino combined". | R1 chunk-8 New bugs:4 | R2 §9 (executive summary) | T3 | LOCKED — Phase 1 ADR needed |
| A11 | **`pooledsecanalysis.do:31-43`** silent `drop if check<race>==1` filter applied at graph time only. Race-specific histograms see different sample than all-races histogram. Drops not propagated to disk. | R1 chunk-8 New bugs:5 | R2 §10; §25 | T3 | LOCKED — Phase 1 promote to assertion |
| A12 | **`trimparentdemo.do` / `trimsecdemo.do` are projection helpers, not statistical trimming.** Misleading file names. | R1 §"Response-rate semantics" bullet 3 | R2 §11 (executive summary); §Q7 | T3 | LOCKED |
| A13 | **Survey pooling pattern**: 5-year append → `wtmean` weighted by `nettotalresp<i>` → `collapse (mean)` for pooled stats and `(sum)` for raw counts → save pooledstats → merge response rate → save analysisready. Schema-divergence (parent 1415 missing qoi64) handled by wtmean ignoring missings. | R1 §"Survey pooling logic" | R2 §12 (executive summary) | T3 | LOCKED |
| A14 | **Response-rate semantics**: `pooledrr` and `pooledrr_gr9and11` are covariates / weights, NOT sample restrictions. No `keep if pooledrr > X` filter. | R1 §"Response-rate semantics" | R2 (per-file entries; no `keep if pooledrr` found) | T3 | LOCKED |

---

## ROUND-1-MISSED rows

### M1 — Paper-vs-code path mismatch for `counts_k12.tex`

- **Round-2 claim** (Q8 follow-up): `paper/common_core_va.tex:163` reads `tables/sbac/counts_k12.tex` but `sample_counts_tab.do:615` writes to `tables/share/va/pub/counts_k12.tex`.
- **Round-1**: missed.
- **Tier**: T1 — Christina to check whether there's a `cp` / `mv` step or symlink that makes the path consistent, OR whether the paper path is stale.
- **Severity**: HIGH if the paper's compile depends on the file being at the old path. Phase 1 path-rerouting must align both producers and consumers.
- **Action**: T1 verification, then Phase 1 fix.

### M2 — `pooledparentdiagnostics.do:42` `pooledrr` formula structurally different

- **Round-2 claim** (Q6): the diagnostics-file `pooledrr` is a raw 5-year sum (NOT conditional on year-having-response, unlike the response-rate-file definitions).
- **Round-1**: noted "two parallel definitions of `pooledrr` exist with same name in different files" but did NOT detail the structural difference.
- **Reconciliation**: round-1 caught the duplication; round-2 sharpened to "structurally different formulas." This is partial round-1 miss.
- **Action**: documented in the discrepancy report.

### M3 — 4 `pooledrr` definitions (not 2)

- **Round-2 claim** (Q6): four distinct `pooledrr` definitions:
  1. `parentresponserate.do:72` — parent, grades 1-12, conditional on `has<year>==1`
  2. `secresponserate.do:71` — secondary, grades 9-12, conditional on `has<year>==1`
  3. `pooledparentdiagnostics.do:42` — parent, grades 9 and 11, unconditional sum
  4. `pooledsecdiagnostics.do:65` — secondary, grades 9 and 11, unconditional sum
- **Round-1**: claimed 2 definitions only.
- **Reconciliation**: round-2 is more thorough — DISAGREE row, see below.

---

## ROUND-2-MISSED rows

### N1 — Header attribution drift (round-1 caught a few cases)

- **Round-1 had implicit observations** about Christina vs Che attribution; round-2 didn't restate at chunk-8 level.
- **Tier**: low priority.
- **Action**: rolled into Phase 1 cleanup sweep.

### N2 — Files with extensive dead code in commented fallback blocks

- **Round-1** chunk-8 New bugs:16: extensive dead code in commented-out fallback blocks (QOI files).
- **Round-2**: noted some commented-out `ssc install` directives but did not characterize as a class.
- **Tier**: T3.
- **Action**: Phase 1 cleanup.

---

## DISAGREE rows

### D1 — Number of `pooledrr` definitions (2 vs 4)

- **Round-1 claim**: 2 parallel `pooledrr` definitions.
- **Round-2 claim**: 4 distinct `pooledrr` definitions.
- **T3 verification (round-2 cited 4 specific lines)**: I'm taking round-2's 4-definition count as authoritative — round-2 enumerated specific lines and described the structural difference between conditional-on-has<year> and unconditional-sum formulas. Round-1's "2" is an undercount.
- **Severity**: All 4 save to different .dta files (no on-disk collision). But variable-name overload is a real footgun.
- **Action**: Phase 1 — rename the 4 `pooledrr` variables to indicate scope (e.g., `pooledrr_parent_grade1to12_cond`, `pooledrr_sec_grade9to12_cond`, `pooledrr_parent_grade9and11_uncond`, `pooledrr_sec_grade9and11_uncond`). Or document explicitly with consistent suffixes.

---

## Adjudication & open questions

### Q1 — Paper-vs-code path mismatch for `counts_k12.tex` (M1)

**Tier**: T1 — Christina runs `find ~/github_repos/va_paper_clone -name counts_k12.tex` and checks the actual TeX include path.

**Resolution path**:
- If paper path is `tables/sbac/counts_k12.tex` and the file exists there, then there's a copy/symlink step that needs to be documented.
- If paper path is stale, Phase 1 should update the paper to use the new path.

### Q2 — Paper-mentioned restrictions not implemented (A5)

`touse_va.do:104, 106` comments mention ">25% special ed" and "home/hospital instruction" filters that aren't in code. Either:
1. They're upstream in `va_samples.dta` (then comments are misplaced).
2. They were never implemented (then paper text needs correction OR code needs implementation).

**Tier**: T4 — Christina confirms.

### Q3 — Filipino-Asian recoding (A10)

`pooledsecdemographics.do:23-24` silently merges Filipino into Asian. This is a substantive demographic recoding without an ADR.

**Tier**: T4 — Christina confirms intent and writes ADR.

### Q4 — `pooledrr` rename (D1)

**Tier**: T4 — naming convention decision for Phase 1.

---

## What changes for downstream chunks

- **Path-rerouting (M1)** is critical for Phase 1 consolidation. Phase 1 plan v3 should account for the `tables/sbac/` vs `tables/share/va/pub/` divergence.
- **`pooledrr` naming** combined with Phase 0e Q&A. Suggest pattern: `pooledrr_<survey>_<grade-scope>_<cond|uncond>`.

## Outstanding items (chunk 8 specifically)

1. T1: paper vs code path for `counts_k12.tex` (M1 / Q1).
2. T4 escalation: paper-mentioned restrictions NOT-implemented intent (A5 / Q2).
3. T4 escalation: Filipino-Asian recoding ADR (A10 / Q3).
4. T4 escalation: `pooledrr` naming convention (D1 / Q4).
5. Phase 1 fixes: A6, A7, A11; M1.
6. Phase 1 cleanup: A8 (sex coding landmine documentation), A9 (trans/nb gender), N2 (dead code in QOI files).
7. Phase 1 ADR: Filipino-Asian recoding (A10).

---

## Verdict

**Strong agreement on the foundational chunk-8 findings** (sample-restriction map, cohort cut, Table A.1 producer, weight chain). One DISAGREE: round-2 found 4 `pooledrr` definitions where round-1 found 2 — round-2 is right.

**Most material new round-2 finding**: paper-vs-code path mismatch for `counts_k12.tex` (M1). T1 needed before Phase 1 path-rerouting.

**Sex coding landmine** (A8) and **silent demographic recoding** (A10) are flagged for ADR-style documentation in Phase 1, even where current behavior is correct.
