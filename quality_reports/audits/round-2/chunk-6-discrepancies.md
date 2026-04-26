# Chunk 6 — Discrepancy Report (Round-1 vs Round-2)

**Chunk:** 6 — Survey VA + CalSCHLS factor analysis (17 files: 14 in `caschls/do/share/factoranalysis/` + 1 in `svyvaregs/` + `clean_va.do` + `allsvymissing.do`)
**Date:** 2026-04-26
**Round-1 source:** `quality_reports/audits/round-1/2026-04-25_chunk6-survey-va.md` + summary at `2026-04-25_deep-read-audit.md` §"Chunk 6"
**Round-2 source:** `quality_reports/audits/round-2/chunk-6-verified.md`

---

## Summary table

| Category | Count |
|---|---|
| AGREE | 14 |
| ROUND-1-MISSED | 4 |
| ROUND-2-MISSED | 1 |
| DISAGREE | 0 |
| TEMPORAL ARTIFACTS | 0 |

**Headline findings:**

1. **NEW from round-2: Climate/quality index item lists ≠ α item lists** (B3/C1). The paper-reported Cronbach's α (computed in `alpha.do` over wider 20/17/4/4-item lists) does NOT describe the indices used in paper Table 8 regressions (constructed from narrower 9/15/4-item lists in `compcase/imputedcategoryindex.do`). **Paper-vs-code consistency issue.** Round-1 noted the α-list/index-list distinction but did not sharpen to "the paper-reported α describes a DIFFERENT object than the regression indices."

2. **Both rounds agree on the major chunk-6 findings**: clean_va.do destructive in-place save, allvaregs.do _nw filename collision, sum-vs-mean discrepancy, mattschlchar.do hardcoded msnaven path, motivation-index orphan, header attribution drift, silent merge attrition.

3. **`mattschlchar.do:17` hardcoded msnaven path** — both rounds confirm. Gated by `local clean = 0` toggle so dormant by default; replication relies on the pre-built `mattschlchar.dta` being available. T4 question for Phase 0e.

4. **Year-window asymmetry**: round-1 noted VA (2015-2018) vs surveys (2017-2019); round-2 also noted VA (2015-2018) vs school chars (2015-2017). Combined: 3 different windows feeding the same Table 8 regression. T4 question for Phase 0e.

5. **No FB-test or distance infrastructure in chunk 6** — both rounds confirm. Distance-FB Row 6 mystery resolved in chunk 7.

---

## AGREE rows

| # | Finding | R1 cite | R2 cite | Tier | Status |
|---|---|---|---|---|---|
| A1 | **`clean_va.do:76` destructive in-place `save, replace`** on each `<svyname>analysisready.dta` (mutates parent/sec/staff analysisready files to include VA columns). | R1 New bugs:4 | R2 §B1 | T3 | LOCKED — Phase 1 fix |
| A2 | **`allvaregs.do:197` weighted-merge filename collision** — saves to `_nw` filename instead of `_wt`; weighted dta silently overwrites unweighted. The `.xls` IS correctly suffixed `_wt`. | R1 New bugs:1 | R2 §B2 | T3 | LOCKED — Phase 1 fix |
| A3 | **Sum-vs-mean discrepancy** — paper says "averages"; code computes sums (then z-standardizes, so coefficients are identical, but on-disk variable is a sum, not mean). | R1 New bugs:3 | R2 §M1 | T4 (Christina: fix paper or code) | OPEN |
| A4 | **`mattschlchar.do:17` hardcoded `/home/research/ca_ed_lab/msnaven/...`** cross-user path, gated by `local clean = 0` toggle. Dormant by default; replication weak point. | R1 New bugs:5 | R2 §B7 | T4 (vendor path or symlink during consolidation) | OPEN |
| A5 | **Header attribution drift**: `indexhorseracewithdemo.do:6` (and `allvaregs.do:6` per round-2) say "Christina Sun"; sibling files say "Che Sun". Same person. | R1 New bugs:8 | R2 §B8 | T3 | LOCKED — Phase 1 cleanup |
| A6 | **`factor.do:11, 79` log directory written to `do/share/factoranalysis/factor.{smcl,log}` instead of `log/share/factoranalysis/`.** | R1 New bugs:6 | R2 §B5 | T3 | LOCKED — Phase 1 fix |
| A7 | **Motivation index orphan**: `imputation.do` and `alpha.do` still process motivation items; `imputedcategoryindex.do:31` has `motivationvars` commented out. Orphan downstream computation. | R1 New bugs:9 | R2 §B9 / §C9 | T3 | LOCKED — Phase 1 cleanup or restoration |
| A8 | **Silent merge attrition** — every `merge ... keep(1 3) nogen` in chunk 6 silently drops unmatched-using rows without `assert _merge==3`. | R1 New bugs:10 | R2 §B11 | T3 | LOCKED — Phase 1 add asserts |
| A9 | **`pcascore.do` line 38 duplicate `pc1` histogram saved as `staffpc2score.png`**. PCA is exploratory only. | R1 New bugs:2 | R2 §B4 / §C7 | T3 | LOCKED — Phase 1 fix |
| A10 | **`mvpatterns` SSC package** used only in `allsvymissing.do:38, 40, 42, 44`. New SSC dep for installssc list. | R1 §"New ssc packages" | R2 §Q11 | T3 | LOCKED |
| A11 | **Paper Table 8 producer chain ends at `_bivar_wdemo` / `_horse_wdemo` .dta/.xls** in chunk 6. The combining TeX-writer for `imputed_index_combined_wdemo.tex` is downstream (chunks 7-10). | R1 §"Paper Table 8 producer chain" diagram | R2 §"Summary of paper Table 8 producer-chain conclusion" | T3 | LOCKED — chunk 9 will catch the .tex writer |
| A12 | **No FB-test or distance infrastructure in chunk 6**. Distance-FB Row 6 mystery defers to chunk 7. | R1 §"Distance-FB Row 6 — still NOT FOUND in chunk 6" | R2 §Q10 | T3 | LOCKED |
| A13 | **VA outcomes used in survey regressions**: 8 outcomes (`ela math enr enr_2year enr_4year dk_enr dk_enr_2year dk_enr_4year`); 2 sample-control combos (`b_sp_b_ct` no-peer, `las_sp_las_ct_p` peer); 2 weighting flags (`_nw`, `_wt`). | R1 §"VA specifications used in `allvaregs.do`" | R2 §Q6 | T3 | LOCKED |
| A14 | **Survey-VA merge geometry: at cdscode (school) only, NOT cdscode×year**. Schools with missing VA → missing in regression (listwise deletion at run time). | R1 §"Survey-VA merge geometry — year-mismatch resolution" | R2 §Q5 | T3 | LOCKED |

---

## ROUND-1-MISSED rows (round-2 found, round-1 did not)

### M1 — Climate/quality index item lists ≠ α item lists (paper-reported α describes different indices)

- **Round-2 claim** (B3/C1, CRITICAL): The α item lists in `alpha.do` (lines 117, 142) do NOT match the index item lists in `compcase/imputedcategoryindex.do` (lines 30-31, 28-29). Climate: 20 items in α, 9 items in index. Quality: 17 items in α, 15 items in index. Support: 4 items both. The paper-reported α (if from `alpha.do`) does NOT describe the indices actually used in Table 8 regressions.
- **Round-1**: noted that "`indexalpha.do` computes the α's reported in the paper" using narrower item lists, while `alpha.do` uses wider item sets — but did NOT explicitly identify the round-2 finding that the WIDER lists in `alpha.do` describe DIFFERENT indices than the paper's actual indices. The framing differs:
  - Round-1: "alpha.do's α's are NOT the paper-reported α's" (treats `alpha.do` output as exploratory).
  - Round-2: "If the paper-reported α is from `alpha.do`, then it describes a different (wider) index than the one used in regressions" — flips the question to whether the paper actually cites `alpha.do` or `indexalpha.do`.
- **Reconciliation**: this is a sharper round-2 framing of round-1's observation. Both correct in their respective framings; round-2's framing is more useful for paper-vs-code adjudication.
- **Tier**: T4 — Christina cross-references the paper PDF: which file's α is reported in the paper text? If `alpha.do`, then the wider lists need to either (a) become the canonical indices (= change Table 8 regressions) or (b) the paper text needs to clarify that α was computed on a wider set than the regression index. If `indexalpha.do`, the paper is consistent and `alpha.do` is exploratory.
- **Action**: Phase 0e Q&A.

### M2 — Stage-2 imputation regression bias

- **Round-2 claim** (M3): Stage-2 imputation regression in `imputation.do` is fit on data where stage-1 has already mean-imputed ALL missing values. The regression then has dummies indicating which observations were stage-1-imputed; this biases the regression toward the global mean. Mitigated by the dummy-flag controls.
- **Round-1**: noted "Non-standard pipeline" without sharpening to "regression is biased toward global mean."
- **Tier**: T4 — Christina assesses whether the bias is acceptable for the imputation purpose.
- **Severity**: methodological. May have small impact on imputed values; Stage-2 regression coefficients absorb the bias via dummies.
- **Action**: Phase 0e Q&A or accept as a known design choice.

### M3 — `testscore.do:27` naming/comment mismatch

- **Round-2 claim** (B12): variable named `prior_gr8_zscore` for year=2017 actually contains `L4_cst_ela_z_score` (4-year lag → grade 7 not grade 8), per the inline comment. Naming-comment-content mismatch.
- **Round-1**: missed.
- **Reconciliation**: this is the year-2017 carve-out we already know about (4-year lag for the 2014 SBAC test-skip year). The variable name `gr8` is wrong for the 2017 cohort. **Real but cosmetic** since it's a control variable — the regression coefficient doesn't depend on the variable name.
- **Tier**: T3.
- **Action**: Phase 1 fix — rename to clarify "prior_g7or8" or add comment.

### M4 — `clean_va.do:76` conflicts with `allsvymerge.do` change-log

- **Round-2 claim** (C4): `clean_va.do` line 76 destructively re-adds VA to `<svyname>analysisready.dta`, but `allsvymerge.do` change-log line 12 says "remove VA from analysis ready data." So the chain is: someone removed VA → clean_va.do then re-adds it. **Inconsistent intent across files.**
- **Round-1**: missed.
- **Tier**: T4 — Christina to clarify intent.
- **Severity**: clean_va.do still works (re-adds VA needed for downstream regressions), but the design intent is fragmented.

---

## ROUND-2-MISSED rows (round-1 found, round-2 did not)

### N1 — `indexalpha.do` no `translate` smcl→log

- **Round-1 claim** (New bugs:7): `indexalpha.do`: no `translate` smcl→log; leaves smcl only.
- **Round-2**: did not flag.
- **Tier**: T3.
- **Severity**: cosmetic (log file format; smcl is readable).
- **Action**: Phase 1 cleanup.

---

## Adjudication & open questions

### Q1 — Paper α attribution (M1)

The most consequential chunk-6 finding. Resolution path:

1. T4 — Christina checks paper text. Where does the paper's α value(s) come from? `alpha.do` or `indexalpha.do`?
2. If from `alpha.do` (wider lists): paper text needs clarification, OR the paper should report `indexalpha.do` α.
3. If from `indexalpha.do`: paper is consistent. `alpha.do` becomes exploratory, can be archived.

### Q2 — Paper "averages" vs code "sums" (A3)

Resolution path:

1. T4 — Christina decides: fix paper text (call them sums) or fix code (compute means before z-scoring; same result).
2. Statistical inert post-z-score, but text-vs-code consistency matters for reviewer credibility.

### Q3 — `mattschlchar.do` cross-user path (A4)

Phase 1 needs a portable solution:

1. Vendor `sch_char.dta` from Matt's directory into the consolidated repo's `data/` (preserves single-source).
2. Or: create a symlink that survives Matt's account decommissioning.
3. Or: add fallback path logic (try msnaven, fall back to consolidated `data/`).

### Q4 — Year-window asymmetry (A14, M4-related)

Resolution path:

1. T4 — Christina decides whether to robustness-test the year-window choice (VA 2015-2018, surveys 2017-2019, school chars 2015-2017).
2. Even if not robustness-tested, document in paper appendix or methods note.

### Q5 — Stage-2 imputation bias (M2)

T4 — Christina assesses whether the bias is acceptable for the imputation purpose. The bias absorbs into the dummy-indicator coefficients, so the imputed VALUES are reasonable; the question is methodological hygiene only.

---

## What changes for downstream chunks

- **Paper Table 8 TeX-writer** is downstream of chunk 6 — chunk 9 (share/output helpers + explore) audit should explicitly look for the `.tex` writer that consumes both `_bivar_wdemo` and `_horse_wdemo` `.dta`/`.xlsx` outputs and produces `imputed_index_combined_wdemo.tex`.
- **A11 Cronbach's α paper-vs-code** combines with chunk-9 paper-output mapping. If chunk 9 doesn't surface the .tex writer for Table 8, we may need to look in `do_files/share/` (chunk 9 territory) or possibly outside both repos.
- **mvpatterns** added to the cumulative SSC list (now ~16 packages).

## Outstanding items (chunk 6 specifically)

1. T4 escalation: paper-α attribution (M1 / Q1).
2. T4 escalation: paper-claim sums vs averages (A3).
3. T4 escalation: mattschlchar.do path strategy (A4).
4. T4 escalation: year-window asymmetry intent (A14, M4).
5. T4 escalation: stage-2 imputation bias acceptance (M2).
6. Phase 1 fixes: A1 (destructive save), A2 (filename collision), A6 (log dir), A8 (silent merge), A9 (pc1 dup histogram), M3 (naming), N1 (translate).
7. Phase 1 cleanup: A5 (header attribution).
8. Phase 1 decision: A7 (motivation index — restore or remove).

---

## Verdict

**Strong agreement on chunk 6** (14 AGREE rows) with one MAJOR new round-2 finding (M1: paper α describes different indices than regression indices). Round-2's chunk-6 audit was high-fidelity; round-1 caught essentially all the bugs but framed M1 less precisely.

**Most material finding for paper integrity**: M1. If the paper-reported α is from `alpha.do`, the paper has a paper-vs-code consistency issue that needs paper-text clarification or a code change. **HIGH PRIORITY for Phase 0e Q&A.**

**Methodological findings** (M1, M2, M3 = sum-vs-mean): all defensible given z-scoring downstream, but worth a paper-text note for reviewer credibility.
