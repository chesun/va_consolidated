# Chunk 6 — Survey-VA + CalSCHLS Factor-Analysis — Round 2 Independent Blind Verification

**Date:** 2026-04-26
**Auditor:** Round-2 blind agent (no access to round-1 output)
**Scope:** 17 files in the factor-analysis / survey-VA layer

All findings below are derived from direct line-cited reads of the primary source. Round-1 output was sequestered (not consulted). The grep tooling occasionally surfaced round-1 file-paths as side effects of multi-directory searches; those hits were ignored — only the chunk-6 do-file content drives the findings.

---

## File 1 — `caschls/do/share/factoranalysis/allsvyfactor.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/factoranalysis/allsvyfactor.do`
- **Lines:** 28
- **Author header:** "written by Che Sun" (line 5)
- **Purpose:** Exploratory factor analysis of the merged all-survey QOI-pooled-mean dataset. Runs `factor *mean_pooled` over all three surveys' pooled-mean items, exports loadings and a screeplot, then re-runs with `mineigen(1)` retaining only factors with eigenvalue ≥ 1.
- **Inputs:** `$projdir/dta/allsvyfactor/allsvyqoimeans` (line 16) — the dataset built by `allsvymerge.do`.
- **Outputs:**
  - `$projdir/out/csv/factoranalysis/allsvy/allsvyfactor.csv` (line 19) — full factor loadings
  - `$projdir/out/graph/factoranalysis/allsvy/allsvyscreeplot.png` (line 21) — screeplot
  - `$projdir/out/csv/factoranalysis/allsvy/allsvyfactoreigen1.csv` (line 24) — 6-factor (eigen ≥ 1) loadings
  - `$projdir/log/share/factoranalysis/allsvyfactor.{smcl,log}` (lines 11, 28)
- **Calls:** none.
- **Stata commands of note:** `factor *mean_pooled` (line 18, default = principal-factor method); `factor *mean_pooled, mineigen(1)` (line 23); `screeplot, yline(1)` (line 20); `esttab e(L)` (line 19, 24) for exporting loading matrices.
- **Community packages:** `esttab` (estout).
- **Hardcoded path issues:** none beyond `$projdir`.
- **Reference to paper outputs:** Diagnostic for index construction; does NOT directly produce a paper table. Comment on line 23 "6 factors with eigenvalue above 1" is an annotation of expected output.
- **Anomalies:**
  - Comment on line 13 "use principal factoring method because data is not multinormal" — Stata's `factor` default is principal factor method, so this matches; documentation is informational.
  - 28 lines total; 1 of them is `screeplot, yline(1)` (line 20) and that uses `cleanplots` style implicitly only if it's the active scheme.

---

## File 2 — `caschls/do/share/factoranalysis/allsvymerge.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/factoranalysis/allsvymerge.do`
- **Lines:** 65
- **Author header:** "written by Che Sun" (line 6)
- **Purpose:** Renames the per-survey QOI-mean variables with a survey-specific prefix and merges the three surveys into one school-level dataset, then merges in pooled VA estimates.
- **Inputs:**
  - `$projdir/dta/buildanalysisdata/analysisready/parentanalysisready` (line 23)
  - `$projdir/dta/buildanalysisdata/analysisready/secanalysisready` (line 35)
  - `$projdir/dta/buildanalysisdata/analysisready/staffanalysisready` (line 44)
  - `$projdir/dta/buildanalysisdata/va/va_pooled_all.dta` (line 59) — produced by `clean_va.do`
- **Outputs:**
  - `$projdir/dta/allsvyfactor/formerge/parentqoimeans` (line 31)
  - `$projdir/dta/allsvyfactor/formerge/secqoimeans` (line 40)
  - `$projdir/dta/allsvyfactor/formerge/staffqoimeans` (line 49)
  - `$projdir/dta/allsvyfactor/allsvyqoimeans` (line 61) — the merged-with-VA master dataset that all downstream factor / index files use.
  - `$projdir/log/share/factoranalysis/allsvymerge.{smcl,log}` (lines 20, 65)
- **Calls:** none.
- **Stata syntax:** `keep cdscode qoi*`, `rename qoi* parentqoi*` (etc.) at lines 26–47; three sequential `merge 1:1 cdscode using ..., nogen` (lines 55–56), one with `keep(1 3) nogen` (line 59).
- **Community packages:** none.
- **Merge geometry:** unit is **cdscode** (school) — NOT cdscode×year. The QOI-pooled-mean variables are already pooled across years upstream.
- **Anomalies / bugs:**
  - Lines 55–56: parent + sec + staff are merged with `nogen` (no `keep(...)` filter), so unmatched master and using observations are both retained. This is a **silent merge attrition / non-merged retention** — there is no `assert _merge==3`.
  - Line 59: the VA merge is `keep(1 3) nogen` — keeps master observations that don't merge to VA, so the merged file may contain school-survey rows with no VA estimates (these will fall out of regressions but are NOT explicitly counted).
  - Change-log on line 12 documents that VA used to be in the analysisready files but is now merged in here ("12/19/2024: remove VA from analysis ready data when renaming, merge in again after merging survey datasets together").
- **Reference to paper outputs:** Indirect — produces the foundational dataset for indices that feed Table 8.

---

## File 3 — `caschls/do/share/factoranalysis/alpha.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/factoranalysis/alpha.do`
- **Lines:** 223
- **Author header:** "written by Che Sun" (line 6)
- **Stata version pin:** `version 16.0` (line 1) — only file in chunk 6 with an explicit version statement.
- **Purpose:** Compute Cronbach's α for (a) each individual survey's full QOI-mean panel and (b) each of the four classification indices: school climate, teacher/staff quality, student support, student motivation. Writes results to a multi-sheet xlsx.
- **Inputs:**
  - `$projdir/dta/buildanalysisdata/analysisready/secanalysisready` (line 31)
  - `$projdir/dta/buildanalysisdata/analysisready/parentanalysisready` (line 60)
  - `$projdir/dta/buildanalysisdata/analysisready/staffanalysisready` (line 88)
  - `$projdir/dta/allsvyfactor/allsvyqoimeans` (line 114) — the **non-imputed**, complete-case dataset.
- **Outputs:**
  - `$projdir/out/csv/factoranalysis/alpha.xlsx` with sheets: `alpha_sec`, `alpha_parent`, `alpha_staff`, `alpha_school_climate`, `alpha_teacher_quality`, `alpha_student_support`, `alpha_student_motivation` (lines 37, 64, 91, 119, 144, 169, 194).
  - `$projdir/log/share/factoranalysis/alpha.{smcl,log}` (lines 26, 223).
- **Calls:** none.
- **Stata syntax:** `alpha varlist, std item` (lines 35, 61, 89, 117, 142, 167, 192). The `std` option = "standardize items in the scale to mean 0, variance 1" (per comment line 33). `putexcel set ... modify open` pattern used for multi-sheet xlsx.
- **Community packages:** none required (alpha is base Stata; putexcel is base Stata 13+).
- **The four classification α blocks (the heart of the file):**
  - **School Climate (line 117)** — 20 items: parentqoi 9, 16, 17, 27; secqoi 22, 23, 24, 25, 26, 27, 28, 29, 30; staffqoi 20, 24, 41, 44, 64, 87, 98.
  - **Teacher and Staff Quality (line 142)** — 17 items: parentqoi 30–34; secqoi 35–40; staffqoi 103–105, 109, 111, 112.
  - **Student Support (line 167)** — 4 items: parentqoi 15, 64; staffqoi 10, 128.
  - **Student Motivation (line 192)** — 4 items: secqoi 31, 32, 33, 34.
- **Reference to paper outputs:** This is the **paper-reported α** producer (per design — file is purpose-named `alpha.do`). α is computed on the **complete-case** `allsvyqoimeans` (line 114), NOT on the imputed dataset.
- **Anomalies / bugs:**
  - The α item lists for school climate (line 117) and teacher/staff quality (line 142) **DO NOT match** the climate/quality item lists used to construct the indices in `compcasecategoryindex.do` and `imputedcategoryindex.do`. See the *Cross-file inconsistencies* section below — this is the most consequential finding in chunk 6.
  - The student-motivation α block (line 192) is computed even though the motivation index was dropped from the paper's downstream pipeline — see motivation-index orphan finding.
  - Style: `set trace on` is commented at line 24 and `set trace off` at line 219; no live trace.

---

## File 4 — `caschls/do/share/factoranalysis/compcasecategoryindex.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/factoranalysis/compcasecategoryindex.do`
- **Lines:** 161
- **Author header:** "written by Che Sun" (line 6)
- **Purpose:** Construct the three category indices (climate, quality, support) on the **complete-case** dataset, z-standardize, run **bivariate** VA regressions of each VA outcome on each index, and emit a combined regression table.
- **Inputs:** `$projdir/dta/allsvyfactor/allsvyqoimeans` (line 28) — non-imputed dataset.
- **Outputs:**
  - `$projdir/out/dta/factor/compcase/va_<va_outcome>_<sample>_sp_<control>_ct[<peer>]_<index>.dta` — one per (VA outcome × sample × control × index) combination via `regsave` (lines 106–109).
  - `$projdir/dta/allsvyfactor/categoryindex/compcasecategoryindex` (line 120) — saved dataset with indices and z-scored VA, used downstream by `indexhorserace.do`, `indexalpha.do`, `indexregwithdemo.do`, `indexhorseracewithdemo.do`.
  - `$projdir/out/dta/factor/compcase/<index>_va_compregs.dta` (line 156) and `$projdir/out/csv/factoranalysis/compcase/<index>_va_compregs.xlsx` (line 157) — one per index, combined merged regression table.
- **Calls:** none directly; consumed by downstream files.
- **Index construction:**
  - **climate (line 30)** — 9 items: parentqoi 16, 17, 27; secqoi 22, 23, 24, 26, 27, 29.
  - **quality (line 31)** — 15 items: parentqoi 30–34; secqoi 28, 35–40; staffqoi 20, 24, 87.
  - **support (line 32)** — 4 items: parentqoi 15, 64; staffqoi 10, 128.
  - **motivation (line 33)** — COMMENTED OUT but the local would have been: secqoi 31, 32, 33, 34. **Motivation is dropped here.**
- **Index aggregation method (lines 35–52):**
  - `gen <index> = 0` then `replace <index> = <index> + <var>` for each item — this is a **SUM**, not an average. The header on line 1 says "linear index" and code body confirms. Per the paper claim "averages", this is a discrepancy in nomenclature; code-wise it is a sum-of-items.
  - Because complete-case rows by definition have all items non-missing, the sum is well-defined for the rows used in regressions. (For rows with any missing item, the sum becomes missing — `0 + .` = `.` in Stata — which silently drops them downstream.)
- **z-standardization (lines 59–68):** Both VA variables (lines 59–62, `replace` in place) and the indices (lines 65–68, `gen z_<index>`) are mean-centered and divided by sd. **VA z-scoring is a destructive `replace`** (overwriting the original `va_*` columns), but only inside the working dataset, which is then saved to `compcasecategoryindex.dta`. So the saved version of `va_*` is z-scored, not raw — downstream consumers must know this.
- **Regression loop (lines 85–116):**
  - VA outcomes: `ela math enr enr_2year enr_4year dk_enr dk_enr_2year dk_enr_4year` (8 outcomes).
  - Samples: `b` (base) and `las` (leave out score-sibling-acs sample).
  - Controls: each sample has one control set — `b` → `b`; `las` → `las`. (i.e., one control per sample; the loop appears more general but degenerates to single-element.)
  - Peer: empty for `b`, `_p` for `las`. So 4 VA spec slots per outcome × index.
  - The bivariate regression on line 104 is `qui reg va_..._ct<peer> z_<index>` — single regressor, no controls. **Bivariate, no demo.**
- **Output filename grammar (line 106):** `va_<va_outcome>_<sample>_sp_<control>_ct[<peer>]_<index>.dta` — the `_sp_` and `_ct` are literal tokens in the VA variable name (sample × control × type slots in the va estimate naming convention).
- **Reference to paper outputs:** Produces the **complete-case** Panel A of the survey-VA Table 8 chain (no demo). The `_va_compregs` per-index combined table is the per-index complete-case bivariate inputs.
- **Anomalies / bugs:**
  - Index is a **sum**, not an average (lines 36–52). The paper's "averages" wording would require dividing by item count, which is not done. Sums and averages give the same z-score after standardization (since dividing by a constant rescales mean and sd identically), so for downstream regression coefficients of z-scored indices on z-scored outcomes this difference is **statistically inert**. But the variable-label nomenclature is wrong relative to the paper.
  - Note that for the complete-case dataset, sum-vs-average does NOT matter for sample selection (a missing item makes both undefined). For the imputed dataset, sum-vs-average is also numerically equivalent up to scaling.
  - Climate-index item list (9 items, line 30) is a STRICT SUBSET of the climate-α item list in `alpha.do` line 117 (20 items). Cronbach's α is therefore being reported on a different scale than what the index actually uses — see Cross-file inconsistency C1.
  - No `set seed` (regressions are deterministic, so this does not cause non-reproducibility, but the file does not declare a seed).

---

## File 5 — `caschls/do/share/factoranalysis/factor.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/factoranalysis/factor.do`
- **Lines:** 79
- **Author header:** "written by Che Sun" (line 5)
- **Purpose:** Per-survey exploratory factor analysis (parent / secondary / staff). For each survey, z-score the QOI-mean items, run unconstrained `factor`, export full loadings and screeplot, then re-run with `mineigen(1)`.
- **Inputs:**
  - `$projdir/dta/buildanalysisdata/analysisready/secanalysisready` (line 22)
  - `$projdir/dta/buildanalysisdata/analysisready/parentanalysisready` (line 40)
  - `$projdir/dta/buildanalysisdata/analysisready/staffanalysisready` (line 58)
- **Outputs:**
  - `$projdir/out/csv/factoranalysis/secfactorall.csv` (line 31), `secfactoreigen1.csv` (line 36)
  - `$projdir/out/graph/factoranalysis/secscreeplot.png` (line 33)
  - `$projdir/out/csv/factoranalysis/parentfactorall.csv` (line 49), `parentfactoreigen1.csv` (line 53)
  - `$projdir/out/graph/factoranalysis/parentscreeplot.png` (line 51)
  - `$projdir/out/csv/factoranalysis/stafffactorall.csv` (line 67), `stafffactoreigen1.csv` (line 71)
  - `$projdir/out/graph/factoranalysis/staffscreeplot.png` (line 69)
- **Calls:** none.
- **Stata commands:** `factor *mean_z` (lines 30, 48, 66), `factor *mean_z, mineigen(1)` (lines 35, 52, 70).
- **QOI ranges** (per-survey numlist for z-scoring):
  - sec: 22/40 (line 25) — same as the secqoinums in `allvaregs.do`
  - parent: 9 15/17 27 30/34 64 (line 43) — matches `parentqoinums` in `allvaregs.do`
  - staff: 10 20 24 41 44 64 87 98 103/105 109 111 112 128 (line 61) — matches `staffqoinums` in `allvaregs.do`
- **Anomalies:** Line 11 logs to `$projdir/do/share/...` (the **do-file directory** under `do/`, not `log/`), and line 79 translates accordingly. This is anomalous — every other file in this directory logs to `$projdir/log/share/...`. The `do/share/factoranalysis/factor.smcl` and `.log` would be sitting next to the do-file. **Bug:** wrong log directory (`do` vs `log`).
- **Reference to paper outputs:** Diagnostic for the choice of indices; not a direct paper-table producer.

---

## File 6 — `caschls/do/share/factoranalysis/imputation.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/factoranalysis/imputation.do`
- **Lines:** 134
- **Author header:** "written by Che Sun" (line 5)
- **Purpose:** Two-stage imputation of missing per-school QOI-mean values. Stage 1: mean-impute all items globally. Stage 2: regress each item on the rest of its category (climate / quality / support / motivation) and the imputed-dummies for that category, predict, replace imputed cells with predicted values.
- **Inputs:** `$projdir/dta/allsvyfactor/allsvyqoimeans` (line 17).
- **Outputs:** `$projdir/dta/allsvyfactor/imputedallsvyqoimeans` (line 131), log at lines 15 and 134.
- **Item lists (lines 19–26):**
  - **`allqoivars` (lines 19–21)** — 45 items pooled across all four categories. (Used only for stage-1 mean-impute on line 70.)
  - **climate (line 23)** — **20 items**: parentqoi 9, 16, 17, 27; secqoi 22, 23, 24, 25, 26, 27, 28, 29, 30; staffqoi 20, 24, 41, 44, 64, 87, 98.
  - **quality (line 24)** — **17 items**: parentqoi 30–34; secqoi 35–40; staffqoi 103–105, 109, 111, 112.
  - **support (line 25)** — 4 items: parentqoi 15, 64; staffqoi 10, 128.
  - **motivation (line 26)** — 4 items: secqoi 31, 32, 33, 34.
- **Two-stage imputation:**
  - **Stage 1 — mean impute (lines 70–74):** For each item in `allqoivars`, generate `mean<i>` = `egen mean(<i>)`, replace `<i>` with `mean<i>` if missing, drop the egen var. After this loop, the SAME-stage-1 imputed values are visible in the stage-2 regressors of every later category — so the within-category regression in stage 2 uses **already-mean-imputed** values from OTHER items as predictors.
  - **Stage 2 — within-category regression (lines 80–128):** For each category, for each item in the category: `local xvars: list <category>vars - i` (other items in same category); `local xdummies: list <category>imputedummies - imputed<i>` (other-item imputation dummies); `reg <i> <xvars> <xdummies>` (line 85, 98, 111, 124); `predict hat_<i>`; `replace <i> = hat_<i> if imputed<i> == 1` (line 87 etc.); drop `hat_<i>`.
- **Imputation predictor pool vs index pool — the discrepancy:**
  - The **imputation** climate pool (line 23) has 20 items including parentqoi9, secqoi 25/28/30, and 6 staffqoi items.
  - The **index-construction** climate pool in `compcasecategoryindex.do` line 30 and `imputedcategoryindex.do` line 28 has **only 9 items** — none of staff, no parentqoi9, no sec 25/28/30.
  - So **15 of the 20 items used as imputation predictors** for climate items are subsequently dropped from the climate index. The reverse is also true: the 9 climate-index items are all imputed (by virtue of being in the imputation pool), but using a much wider prediction model.
  - Same pattern for quality: imputation pool 17 items (line 24), index pool 15 items (line 31 of compcase) — different memberships (imputation lacks sec28, staff20/24/87; has staff103-112).
  - Support pool is identical across both files (4 items).
  - Motivation: imputation processes it (line 26) but no downstream index uses it.
- **Stata syntax:** `egen mean<i> = mean(<i>)` (line 71); `local <cat>imputedummies: list <cat>imputedummies | addvar` (lines 38, 47, 56, 65) — list-union accumulation idiom.
- **Community packages:** none.
- **Anomalies / bugs:**
  - **C2 (cross-file inconsistency, see below):** Imputation pool ≠ index pool.
  - The header for stage 2 (line 78) says "Regress each var on other vars in each category and imputed dummies; predict y hat and replace missing with y hat." But after stage 1, no value is missing — every value was already mean-imputed. So `replace <i> = hat_<i> if imputed<i> == 1` (line 87) replaces stage-1 means with stage-2 predictions. The stage-2 prediction is computed from an OLS fit on the entire (now-non-missing-everywhere) sample — including rows where the LHS was previously missing and is currently the global mean. **This biases the OLS fit toward the global mean** for items with high missingness, because the regression is fit on (originally observed) + (mean-substituted) values. This is a methodological concern, not necessarily a bug, but downstream the estimated index slopes are not the standard "regression imputation" estimates (which would refit on observed-only LHS).
  - Change-log on line 9: "12/19/2024: correct spelling error in supportimputedummies local macro" — informational.
  - Comment on line 29: "NEED TO ADD VAR LABELS" — open TODO inside code.
  - Motivation imputation is performed (lines 119–128) even though the motivation index is commented out downstream. **Orphan computation.**

---

## File 7 — `caschls/do/share/factoranalysis/imputedcategoryindex.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/factoranalysis/imputedcategoryindex.do`
- **Lines:** 164
- **Author header:** "written by Che Sun" (line 6)
- **Purpose:** Same as `compcasecategoryindex.do` but operates on `imputedallsvyqoimeans.dta`. Constructs three indices, z-standardizes, runs bivariate VA regressions, exports combined table.
- **Inputs:** `$projdir/dta/allsvyfactor/imputedallsvyqoimeans` (line 26).
- **Outputs:**
  - `$projdir/out/dta/factor/imputed/va_<va_outcome>_<sample>_sp_<control>_ct[<peer>]_index.dta` (line 103) — note filename ends in literal `_index`, not `_<index>` — because the loop appends index estimates within one file (see below).
  - `$projdir/dta/allsvyfactor/categoryindex/imputedcategoryindex.dta` (line 119) — saved working dataset with z-scored indices and z-scored VA. Used downstream by `indexhorserace.do`, `indexregwithdemo.do`, `indexhorseracewithdemo.do`.
  - `$projdir/out/dta/factor/imputed/vaindex_imputedregs_all.dta` (line 156) and `$projdir/out/csv/factoranalysis/imputed/vaindex_imputedregs_all.xlsx` (line 158) — combined merged regression table.
- **Index construction (lines 28–50):** **IDENTICAL item lists** to `compcasecategoryindex.do` lines 30–32. So the **imputed indices use only the 9/15/4 items** that the complete-case version uses, even though the imputation pool was wider. The wider imputation pool is purely for prediction-pool richness, not index membership.
- **Index aggregation:** SUM, same as compcase (lines 33–50). Sum of imputed values.
- **Loop append behavior — KEY DIFFERENCE FROM COMPCASE:**
  - `compcasecategoryindex.do` line 106: filename includes `_<index>` and uses `replace` always — one regsave file PER index.
  - `imputedcategoryindex.do` line 99: `local append replace` and line 109: `local append append` — appends each index's row to the SAME file `_index.dta` (no `_<index>` suffix). Result: one file per (VA outcome × sample × control), containing rows for all 3 indices stacked. Different output structure.
- **Reference to paper outputs:** Produces the **imputed Panel A inputs** (bivariate, no demo) for the survey-VA chain. The combined `vaindex_imputedregs_all.xlsx` (line 158) is the imputed bivariate-no-demo panel.
- **Anomalies:**
  - Same sum-vs-average issue as compcase.
  - **Filename collision-friendly:** the imputed file structure uses `_index` (literal) rather than `_<index>` (varname-suffixed), so each VA-spec file holds 3 stacked rows. This is intentional (controlled by `local append append` on line 109) but is a different convention than the compcase counterpart.
  - No `set seed`.

---

## File 8 — `caschls/do/share/factoranalysis/indexalpha.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/factoranalysis/indexalpha.do`
- **Lines:** 30
- **Author header:** "written by Che Sun" (line 5)
- **Purpose:** Cronbach's α for **the actual index item lists** (climate, quality, support — not motivation), computed on the **complete-case index dataset** `compcasecategoryindex.dta`.
- **Inputs:** `$projdir/dta/allsvyfactor/categoryindex/compcasecategoryindex` (line 13).
- **Outputs:** log only (no excel). lines 11, 30.
- **Stata commands:** `alpha <vars>, std item` (lines 20, 23, 26).
- **Item lists:** **IDENTICAL** to `compcasecategoryindex.do` (climate 9, quality 15, support 4). Lines 15–17. Motivation commented out (line 18).
- **Reference to paper outputs:** This is the **alpha for the actual index item composition** — the "what α should be reported" file IF the paper reports α on the indices as constructed. By contrast, `alpha.do` reports α on a different (broader) item list.
- **Anomalies:**
  - **Two competing α producers** — `alpha.do` (broad item lists) and `indexalpha.do` (narrow lists matching the indices used). Which one feeds the paper is ambiguous from chunk 6 alone; would need to check the paper's α numerical reporting.
  - No log-translate on this file? Actually line 30 does translate. Fine.
  - The motivation block is commented out (line 18). Consistent with index-side dropping.

---

## File 9 — `caschls/do/share/factoranalysis/indexhorserace.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/factoranalysis/indexhorserace.do`
- **Lines:** 105
- **Author header:** "written by Che Sun" (line 6)
- **Purpose:** "Horse race" regressions — VA outcome on **all three z-scored indices simultaneously**, **without demographic controls**. Done for both compcase and imputed datasets via outer `foreach type in compcase imputed` loop.
- **Inputs:**
  - `$projdir/dta/allsvyfactor/categoryindex/compcasecategoryindex` (line 19, type=compcase)
  - `$projdir/dta/allsvyfactor/categoryindex/imputedcategoryindex` (line 19, type=imputed)
- **Outputs:**
  - `$projdir/out/csv/factoranalysis/indexhorserace/va_<va_outcome>_<sample>_sp_<control>_ct[<peer>]_<type>.dta` (line 48) — one per VA spec × type (each holds 3 coefficient rows, one per index).
  - `$projdir/out/csv/factoranalysis/indexhorserace/<type>horserace.csv.xlsx` (line 95) — combined.
- **Regression (line 46):** `qui reg va_..._ct<peer> z_climateindex z_qualityindex z_supportindex` — the **horserace** specification: all three indices on RHS at once.
- **Reference to paper outputs:** Produces the **horse-race / Panel B inputs** for the survey-VA Table 8 chain (no demo controls).
- **Anomalies:**
  - Output path on line 48 is under `out/csv/...` even though it's a `.dta` (regsave writes a `.dta`). The directory naming is misleading but Stata will write `.dta` files into a directory called `csv/` if the save command uses an explicit dta extension implicitly — `regsave` writes dta. So the dta files end up in a directory named `csv/`. **Naming inconsistency**, not a runtime bug.
  - Line 95 `export excel using ... .csv` — but `export excel` writes `.xlsx`. With the `.csv` extension in the filename, Stata will still write an xlsx file (extension in filename doesn't override the export-excel format). The output file will be `<type>horserace.csv.xlsx` or `<type>horserace.csv` interpreted as filename — needs runtime to confirm. **Suspect bug** in extension specification.

---

## File 10 — `caschls/do/share/factoranalysis/indexhorseracewithdemo.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/factoranalysis/indexhorseracewithdemo.do`
- **Lines:** 160
- **Author header:** "written by Christina Sun" (line 6) — **header attribution drift** from "Che Sun" used in nearly all other factor-analysis files. Same email `ucsun@ucdavis.edu`.
- **Purpose:** Horse-race regressions of VA on all three indices **WITH** school-demographic and test-score controls. Both compcase and imputed via outer loop.
- **Inputs:**
  - `$projdir/dta/allsvyfactor/categoryindex/<type>categoryindex` (line 38)
  - `$projdir/dta/schoolchar/schlcharpooledmeans` (line 41) — produced by `mattschlchar.do`.
  - `$projdir/dta/schoolchar/testscorecontrols` (line 43) — produced by `testscore.do`.
- **Outputs:**
  - `$projdir/out/dta/factor/indexhorsewithdemo/<type>/va_..._ct<peer>.dta` (line 82)
  - `$projdir/out/dta/factor/indexhorsewithdemo/<type>_index_horse_wdemo.dta` (line 130)
  - `$projdir/out/csv/factoranalysis/indexhorsewithdemo/<type>_index_horse_wdemo.csv.xlsx` (line 132).
- **Demo controls (lines 49):** `minorityenrprop maleenrprop freemealprop elprop maleteachprop minoritystaffprop newteachprop fullcredprop fteteachperstudent fteadminperstudent fteserviceperstudent` — log-transformed via `gen ln_<i> = log(<i> + 0.0000001)` (lines 55–57). The `0.0000001` shift is a tiny pseudocount to make `log(0)` finite.
- **Test-score controls (line 52):** `avg_gr6math_zscore avg_gr8ela_zscore`.
- **Regression (line 80):** `qui reg va_..._ct<peer> z_climateindex z_qualityindex z_supportindex ln_* <scorevars>` — horserace + log-demo + test-score controls. **This is the Panel B with demo** producer.
- **Merge attrition (lines 41, 43):** `merge ..., keep(1 3) nogen` — keeps master and matched, no `assert _merge==3`.
- **Reference to paper outputs:** Produces the **horse-race-with-demo Panel B** for `imputed_index_combined_wdemo.tex` (paper Table 8). The actual `.tex` file is NOT produced in chunk 6 — output ends at `.dta` and `.xlsx`.
- **Anomalies:**
  - Header attribution: "Christina Sun" (line 6) — drift from "Che Sun".
  - Line 28 `set seed 1984` — only file in the index-regression family with an explicit seed (and `indexregwithdemo.do` lacks one despite parallel structure).
  - Line 132 `.csv` extension on `export excel` — will produce a `.csv.xlsx` file (or possibly Stata writes `.csv` if Stata respects the extension hint; needs runtime verification). Same suspected bug as `indexhorserace.do` line 95.
  - Trailing 17 blank lines (lines 134–151) — cosmetic, no impact.
  - Lines 31, 152–156 wrap the body in `local date1 = c(current_date)`...`di "End date time"` — runtime tracking.

---

## File 11 — `caschls/do/share/factoranalysis/indexregwithdemo.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/factoranalysis/indexregwithdemo.do`
- **Lines:** 166
- **Author header:** "written by Che Sun" (line 5)
- **Purpose:** Bivariate VA regressions per index **with demographic + test-score controls**, for both compcase and imputed.
- **Inputs:**
  - `$projdir/dta/allsvyfactor/categoryindex/<type>categoryindex` (line 33)
  - `$projdir/dta/schoolchar/schlcharpooledmeans` (line 37)
  - `$projdir/dta/schoolchar/testscorecontrols` (line 40)
- **Outputs:**
  - `$projdir/out/dta/factor/indexbivarwithdemo/<type>/va_..._ct<peer>_index.dta` (line 103) — one per (VA outcome × sample × control), with 3 index rows appended via `local append_macro replace/append` pattern (lines 98, 108).
  - `$projdir/dta/allsvyfactor/categoryindex/<type>indexwithdemo.dta` (line 120) — saved working dataset.
  - `$projdir/out/dta/factor/indexbivarwithdemo/<type>_index_bivar_wdemo.dta` (line 158)
  - `$projdir/out/csv/factoranalysis/indexbivarwithdemo/<type>_index_bivar_wdemo.xlsx` (line 159).
- **Regression (line 101):** `reg va_..._ct<peer> z_<index> ln_* <scorevars>` — single-index + demo controls. Note this is **NOT `qui reg`** like the other files, so output prints to the log.
- **Reference to paper outputs:** Produces the **bivariate-with-demo Panel A** input for the paper's Table 8 (`imputed_index_combined_wdemo.tex`). Together with `indexhorseracewithdemo.do`, this provides the two halves of the Table 8 panels.
- **Anomalies:**
  - **Heavy commented-out z-demo block (lines 59–66)** — was previously z-scoring demos; now using log-transform. Style debt.
  - Inner block has `set trace on` commented at line 124 and `set trace off` at line 162. No live trace.
  - No `set seed` (compare `indexhorseracewithdemo.do` line 28 which has one).
  - Note line 101 lacks `qui` — printed regression output bloats the log.

---

## File 12 — `caschls/do/share/factoranalysis/mattschlchar.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/factoranalysis/mattschlchar.do`
- **Lines:** 103
- **Author header:** "written by Che Sun" (line 6)
- **Purpose:** Two purposes —
  1. Clean Matt Naven's school-characteristics raw file (renaming variables) — **gated by `local clean = 0`** so it's OFF by default (line 15).
  2. Build `elprop` from the K-12 test-score data and merge with the cleaned school-char file to produce the pooled-means dataset for index regressions.
- **Inputs:**
  - `/home/research/ca_ed_lab/msnaven/common_core_va/data/sch_char` (line 17) — **HARDCODED PATH to Matt Naven's user directory on Scribe**, gated by `if `clean' == 1`. NOT toggleable via `$mattxwalks` global; it's literal text.
  - `$vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta` (line 71) — collapsed to `elprop` per (cdscode, year) then per cdscode.
  - `$projdir/dta/schoolchar/mattschlchar` (lines 65, 82) — output of step 1, input to step 2.
  - `$projdir/dta/schoolchar/elprop` (line 92) — built mid-script.
- **Outputs:**
  - `$projdir/dta/schoolchar/mattschlchar.dta` (line 65) — only if `clean=1`.
  - `$projdir/dta/schoolchar/elprop.dta` (line 78).
  - `$projdir/dta/schoolchar/schlcharpooledmeans.dta` (line 99) — the pooled-means dataset consumed by `indexregwithdemo.do` and `indexhorseracewithdemo.do`.
- **Year window (line 85):** `keep if inrange(year, 2015, 2017)` — collapse over school years 2014-15 through 2016-17 (year of spring semester). Note the lag between this window (2015-2017) and VA estimate years (2015-2018) — they are aligned only on the lower bound. The comment on line 84 explains: "to condition on the same year as VA estimates since year is the year of spring semester".
- **Stata syntax of note:**
  - `if all_students_sample==1 & inrange(year, 2015, 2017)` (lines 70-71) — filter at use-time on the test-score file.
  - `collapse elprop = limited_eng_prof, by(cdscode year)` then `collapse elprop, by(cdscode)` (lines 72–73) — two-stage collapse: per-school-year then per-school average.
  - `collapse *prop fte*, by(cdscode)` (line 90) — collapse using wildcard varlists.
  - `merge 1:1 cdscode using ..., keep(1 3)` is NOT used here — line 92 uses just `merge 1:1 cdscode using $projdir/dta/schoolchar/elprop` with no options, then line 94 `keep if _merge==3`. So this file enforces complete-merge selection.
- **Hardcoded path issue:** Line 17 hardcodes `/home/research/ca_ed_lab/msnaven/...` — Matt Naven's HOME directory on Scribe. The file is **gated by `local clean = 0`** so by default the line never executes; Christina presumably ran it once (with `clean=1`) on Scribe to produce `mattschlchar.dta`, then saved into shared `$projdir`. **For replication, the gated block requires Matt's directory to exist or the toggle stays off.** Cross-user dependency exists but is mostly dormant.
- **Reference to paper outputs:** Indirect — produces the school-characteristics control set for Table 8 with-demo specifications.
- **Anomalies:**
  - Line 17: **hardcoded `/home/research/ca_ed_lab/msnaven/...`** path — not protected by an environment global like `$mattxwalks`. Documented in audit-question Q8 below.
  - Line 31 `drop el_prop` removes the el-proportion from Matt's file before recomputing it from K-12 test-score data (line 78). Documented choice — the comment on line 68 says "create elprop by collapsing student test score data to avoid missing data problem in the CDE school level dataset."

---

## File 13 — `caschls/do/share/factoranalysis/pcascore.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/factoranalysis/pcascore.do`
- **Lines:** 43
- **Author header:** "written by Che Sun" (line 5)
- **Purpose:** Per-survey principal-component analysis. Extracts PC1 (and PC2 for staff) from the QOI-mean panel, predicts scores, plots histogram, exports.
- **Inputs:**
  - `$projdir/dta/buildanalysisdata/analysisready/secanalysisready` (line 14)
  - `$projdir/dta/buildanalysisdata/analysisready/parentanalysisready` (line 23)
  - `$projdir/dta/buildanalysisdata/analysisready/staffanalysisready` (line 32)
- **Outputs:**
  - `$projdir/out/graph/factoranalysis/pcascore/secpcascore.png` (line 19)
  - `$projdir/out/graph/factoranalysis/pcascore/parentpcascore.png` (line 28)
  - `$projdir/out/graph/factoranalysis/pcascore/staffpc1score.png` (line 37)
  - `$projdir/out/graph/factoranalysis/pcascore/staffpc2score.png` (line 39)
- **Stata commands:** `pca *mean_pooled` (lines 16, 25, 34); `predict pc1, score` / `predict pc1 pc2, score` (lines 17, 26, 35).
- **Reference to paper outputs:** Diagnostic/exploration — does not produce a paper table.
- **Anomalies:**
  - **Bug at line 38:** `histogram pc1, freq` (should be `histogram pc2`) before the line 39 export of `staffpc2score.png`. **The pc2 histogram is actually a duplicate of the pc1 histogram** because line 38 plots `pc1` again, then line 39 saves under the `staffpc2score.png` filename. **REAL BUG — visualization mislabel.**

---

## File 14 — `caschls/do/share/factoranalysis/testscore.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/factoranalysis/testscore.do`
- **Lines:** 49
- **Author header:** "written by Che Sun" (line 5)
- **Purpose:** Pull the SBAC test-score controls (6th-grade math, 8th-grade ELA z-scores) for 11th-graders in school-years 2014-15 to 2016-17 and pool to per-school averages, used as controls in the with-demo regressions.
- **Inputs:**
  - `$vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta` (line 17) — current-grade scores filtered to grade==11, dataset=="CAASPP", year 2015-2017, all_scores_sample==1.
  - `$vaprojdir/data/restricted_access/clean/k12_test_scores/k12_lag_test_scores_clean.dta` (line 20) — lag scores, merged 1:1.
- **Outputs:** `$projdir/dta/schoolchar/testscorecontrols.dta` (line 45).
- **Stata:**
  - Lag-score selection (lines 25–27): `gen prior_gr8_zscore = L3_cst_ela_z_score if inrange(year, 2015, 2016)` then `replace prior_gr8_zscore = L4_cst_ela_z_score if year==2017`. The L3 vs L4 split — for grade-11 students, 3-year lag is grade 8 in 2015–2016, but in 2017 the data structure required L4 ("use grade 7 ELA score for grade 8 in year 2017 due to missing data"). **Note: comment says "grade 7" but the variable is named `prior_gr8_zscore` and the code uses L4_cst_ela_z_score. Either the comment or the variable label is wrong.** Need to check what L4_cst_ela_z_score really is — probably 4-year lag → grade 7 ELA, not grade 8. **Variable naming may be misleading**: `prior_gr8_zscore` for year=2017 actually contains a 4-year-lag (grade-7) ELA score per the comment.
- **Two-stage collapse (lines 33, 36):** by (cdscode year), then by (cdscode) — per-year mean within school, then average across years.
- **Reference to paper outputs:** Indirect — produces controls for Table 8 with-demo specifications.
- **Anomalies:**
  - Line 25–27: Variable naming vs. comment mismatch — `prior_gr8_zscore` for year=2017 may actually contain grade-7 ELA per the inline comment. Documented but not fixed.
  - `merge 1:1 ... ` on line 20 has no `keep` option; line 22 enforces `keep if _merge == 3` — proper attrition handling.

---

## File 15 — `caschls/do/share/svyvaregs/allvaregs.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/svyvaregs/allvaregs.do`
- **Lines:** 210
- **Author header:** "written by Christina Sun" (line 6) — second file with "Christina Sun" attribution (the other is `indexhorseracewithdemo.do`).
- **Purpose:** Bivariate VA regressions of every VA outcome × spec on every per-survey QOI z-score, both unweighted and weighted by `gr11enr_mean`. Per-survey loop (sec / parent / staff).
- **Inputs:** `$projdir/dta/buildanalysisdata/analysisready/<svyname>analysisready` (line 50) — for each survey.
- **Outputs:**
  - `$projdir/out/dta/varegs/<svyname>/va_..._ct<peer>_nw.dta` (line 100, unweighted; appended within VA outcome × sample × control × QOI).
  - `$projdir/out/dta/varegs/<svyname>/va_..._ct<peer>_wt.dta` (line 110, weighted).
  - `$projdir/out/dta/varegs/<svyname>/<svyname>_va_all_nw.dta` (line 160) — merged unweighted.
  - `$projdir/out/xls/varegs/unweighted/<svyname>/<svyname>_va_all_nw.xlsx` (line 161).
  - **Line 197:** `save $projdir/out/dta/varegs/<svyname>/<svyname>_va_all_nw.dta, replace` — **saves the WEIGHTED merged dta to the UNWEIGHTED filename `_nw.dta`. BUG.** The previous save at line 160 is overwritten with the weighted dta.
  - `$projdir/out/xls/varegs/weighted/<svyname>/<svyname>_va_all_wt.xlsx` (line 198) — Excel export uses correct `_wt` suffix.
- **QOI numbers (lines 33–39):**
  - **secqoinums** — 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 (19 numbers).
  - **parentqoinums** — 9 15 16 17 27 30 31 32 33 34 64 (11 numbers).
  - **staffqoinums** — 10 20 24 41 44 64 87 98 103 104 105 109 111 112 128 (15 numbers).
- **Sample / control / peer combos (lines 72–88):** identical to compcase/imputedcategoryindex — 4 VA spec slots per outcome × QOI (b/b/N, las/las/Y).
- **Weighting:** `[aweight = gr11enr_mean]` on line 109 — analytic weight by 11th-grade enrollment.
- **Anomalies / bugs:**
  - **CRITICAL BUG: line 197 — `save ..._va_all_nw, replace`** — same filename as line 160. The merged-weighted regsave dataset is saved over the merged-unweighted dataset. The Excel export at line 198 uses the correct `_wt` suffix, so the `.xlsx` weighted output IS produced — but the `.dta` weighted-merged dataset is saved under the wrong (`_nw`) filename, overwriting the unweighted dta.
  - Header drift (line 6): "Christina Sun" vs "Che Sun" elsewhere.

---

## File 16 — `caschls/do/build/buildanalysisdata/poolingdata/clean_va.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/build/buildanalysisdata/poolingdata/clean_va.do`
- **Lines:** 92
- **Author header:** "First created by Christina (Che) Sun November 21, 2022" (line 7) — Christina/Che union form.
- **Purpose:** Pool the year-level VA estimates to school-level means (collapse over years 2015-2018) per outcome (ela / math / enr / enr_2year / enr_4year), merge into one panel, save, and propagate by merging onto each survey's analysisready file.
- **Inputs:**
  - `$vaprojdir/estimates/va_cfr_all_v1/va_est_dta/va_<va_outcome>_all.dta` (line 43) — for `va_outcome` in `{ela math enr enr_2year enr_4year}` (5 outcomes).
  - `$projdir/dta/buildanalysisdata/analysisready/<svyname>analysisready` (line 73) — for each survey.
- **Outputs:**
  - `$projdir/dta/buildanalysisdata/va/va_pooled_all.dta` (line 65) — the pooled VA panel.
  - **Line 76: `save, replace`** — bare save with no filename, INSIDE the `foreach svyname` loop. After `use ...analysisready` on line 73 and merging VA on line 74, this writes back to **`<svyname>analysisready.dta`**. **DESTRUCTIVE IN-PLACE OVERWRITE** of the upstream survey analysisready files. Permanently mutates the upstream artifacts to include VA columns.
- **Year window:** "VA mean estimates for all test scores and enrollment over 2015-2018" (line 64 dataset label). The collapse `collapse (mean) va*, by(cdscode)` (line 44) implicitly averages all years available in the source; the comment says 2015-2018 (4 years).
- **Note:** The 5 outcomes `ela math enr enr_2year enr_4year` are pooled here, but downstream files (e.g., `compcasecategoryindex.do` line 85) iterate over **8 outcomes**: `ela math enr enr_2year enr_4year dk_enr dk_enr_2year dk_enr_4year`. The 3 `dk_*` outcomes are NOT in the clean_va.do loop. They must be added to the analysisready files by some other pathway (likely already in `<svyname>analysisready` from upstream, or from `va_cfr_all_v1` via a different route). Verifying the source of `dk_*` columns is OUT of chunk 6's scope but flagged.
- **Stata syntax:** `collapse (mean) va*` (line 44); `tempfile va_<va_outcome>` (line 46); macro-driven sequential merge pattern (lines 55–62).
- **Anomalies / bugs:**
  - **CRITICAL: line 76 destructive `save, replace`** — bare save inside a loop that overwrites upstream survey analysisready files in-place. Per the change-log of `allsvymerge.do` line 12 ("12/19/2024: remove VA from analysis ready data when renaming, merge in again after merging survey datasets together"), this VA-merge-in-place was the **previous** workflow that has already been changed in `allsvymerge.do`. The fact that `clean_va.do` still has the destructive save means the two files are **redundant or inconsistent**. The current pipeline's source of truth for VA in survey datasets is unclear.
  - The 8 VA outcomes used downstream vs 5 produced here suggests `dk_*` columns come from a different pre-existing source.
  - The double-slash in path strings `do/build//buildanalysisdata/...` (lines 12, 29, 91) is harmless on POSIX file systems but is style debt.
- **Reference to paper outputs:** Indirect — produces the pooled VA used by `allsvymerge.do` (and historically directly merged into per-survey analysisready files).

---

## File 17 — `caschls/do/check/allsvymissing.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/check/allsvymissing.do`
- **Lines:** 49
- **Author header:** "written by Che Sun" (line 5)
- **Purpose:** Diagnostic — examine the distribution of missing values across the merged QOI-mean dataset, in total and by category, and run `mvpatterns` to enumerate missing-data patterns.
- **Inputs:** `$projdir/dta/allsvyfactor/allsvyqoimeans` (line 14).
- **Outputs:** log only (lines 12, 49).
- **Item lists:** Categories use the **broad** lists matching `imputation.do`/`alpha.do` — climate 20 items (line 20), quality 17 items (line 21), support 4 items (line 22), motivation 4 items (line 23). NOT the narrow lists from the index-construction files.
- **`mvpatterns` package:** community-contributed (`ssc install mvpatterns`). Used at lines 38, 40, 42, 44 — one call per category.
- **Reference to paper outputs:** Diagnostic; does not produce a paper artifact directly. Likely produces input to a footnote / data section about missingness.
- **Anomalies:**
  - The lists here align with the `imputation.do` / `alpha.do` broad lists, NOT with the narrow `compcase/imputedcategoryindex.do` lists actually used to construct indices. So the diagnostic measures missingness on a wider pool than what the indices cover. Documented but not necessarily a bug — diagnostic intent is to understand missingness patterns broadly.

---

## Cross-file inconsistencies (the chunk-6 elephants)

### C1 — Climate / Quality α item list ≠ index item list

The α reported for the school-climate and teacher/staff-quality classifications (in `alpha.do` lines 117 and 142) is computed on a SUPERSET of the items actually used in the indices that feed the paper Table 8.

| Index | `alpha.do` α items | `compcase/imputedcategoryindex.do` index items | Net difference |
|---|---|---|---|
| Climate | 20 (line 117) | 9 (line 30 / line 28) | **11 items in α but not in index** (parentqoi9; secqoi 25,28,30; staffqoi 20,24,41,44,64,87,98) |
| Teacher/Staff Quality | 17 (line 142) | 15 (line 31 / line 29) | α has staffqoi 103-105,109,111,112; index has secqoi28, staffqoi 20,24,87 instead. **Items are differently composed, not nested.** |
| Student Support | 4 (line 167) | 4 (line 32) | **Same** |
| Student Motivation | 4 (line 192) | dropped (line 33 commented) | α reports for orphan index |

Implications: the paper's Cronbach's α figure (if drawn from `alpha.do`) does not describe the actual indices used in regressions. The proper file would be `indexalpha.do` (lines 15–17), which uses the narrow-index item lists.

### C2 — Imputation predictor pool ≠ index pool

In `imputation.do` (lines 23–26), the within-category imputation regression uses BROADER item lists than the indices later constructed in `imputedcategoryindex.do`:

| Category | Imputation pool (imputation.do) | Index pool (imputedcategoryindex.do) | Difference |
|---|---|---|---|
| Climate | 20 items (line 23) | 9 items (line 28) | **11 imputation predictors not in index** |
| Quality | 17 items (line 24) | 15 items (line 29) | Different membership |
| Support | 4 items (line 25) | 4 items (line 30) | Same |
| Motivation | 4 items (line 26) | dropped | Predicted but never used |

Methodological consequence: items used in indices are imputed with a wider feature set than the index membership would suggest. This is a defensible choice (more predictors → better imputations) but it complicates interpretation — the indices are in effect informed by items not nominally part of them.

### C3 — Header attribution drift

15 of 17 files: "Che Sun" (or "First created by Christina (Che) Sun" in `clean_va.do` line 7).

Two files: "Christina Sun" — `indexhorseracewithdemo.do` line 6, `allvaregs.do` line 6.

All use the same email `ucsun@ucdavis.edu`. The two "Christina Sun" files are also the only ones that include `set seed 1984` (lines 28 and 27 respectively), suggesting they were written or rewritten in a later style era.

### C4 — `clean_va.do` line 76 vs `allsvymerge.do` change-log conflict

The `allsvymerge.do` change-log (line 12) says "12/19/2024: remove VA from analysis ready data when renaming, merge in again after merging survey datasets together." Yet `clean_va.do` line 76 (`save, replace` in the analysisready loop) STILL writes VA into each `<svyname>analysisready.dta` in place. Either:

- (a) `clean_va.do` is now obsolete (its `save, replace` writes a state that `allsvymerge.do` then explicitly drops via its own `keep` selection); or
- (b) the repo is in an inconsistent state where both pipelines are live.

There is no toggle gating the loop on lines 72–77.

### C5 — `allvaregs.do` `_nw` filename collision (line 197)

`save $projdir/out/dta/varegs/<svyname>/<svyname>_va_all_nw, replace` at line 197 saves the WEIGHTED merged regsave dataset over the unweighted dataset previously saved at line 160. Filename collision. The `.xlsx` weighted output (line 198) IS correctly suffixed `_wt`. Net effect: weighted-merged `.dta` is recoverable from the xlsx but not from the dta filename.

### C6 — `indexhorserace.do` line 95 and `indexhorseracewithdemo.do` line 132 — `.csv` extension on `export excel`

`export excel using ... .csv, replace` — Stata's `export excel` writes xlsx format. The `.csv` extension in the filename is ignored or appended; runtime behavior may produce `.csv` files (with xlsx contents), or `.csv.xlsx`. Suspect bug; needs runtime confirmation. Not catastrophic but the file produced may not be openable in Excel by name.

### C7 — `pcascore.do` line 38 — duplicate pc1 histogram saved as pc2

Line 38 plots `histogram pc1, freq` immediately before line 39 exports `staffpc2score.png`. Should be `histogram pc2, freq`. Real bug.

### C8 — `factor.do` log directory (line 11)

`log using $projdir/do/share/factoranalysis/factor.smcl, replace` — uses `do/` instead of `log/`. Anomalous; will produce log files inside the do-file directory.

### C9 — Motivation index orphan

The motivation index appears in:
- `imputation.do` (lines 26, 59–66, 119–128) — fully imputed.
- `allsvymissing.do` (lines 23, 34, 44) — diagnostic.
- `alpha.do` (lines 192–215) — α reported.

But it is COMMENTED OUT in:
- `compcasecategoryindex.do` (line 33).
- `imputedcategoryindex.do` (line 31).
- `indexalpha.do` (line 18).

Result: motivation is processed upstream, dropped at index construction. **Orphan computation** (see paper claim that motivation index was dropped — code-evidence is consistent with that).

---

## Specific question answers

### Q1 — Paper Table 8 (`tab:survey`, `imputed_index_combined_wdemo.tex`) producer chain

Within chunk 6, the chain is:

```
buildanalysisdata/poolingdata/clean_va.do
  └─→ va_pooled_all.dta
        ↑
share/factoranalysis/allsvymerge.do
  └─→ allsvyqoimeans.dta (parent + sec + staff per-school QOI means + VA)
        │
        ├─→ share/factoranalysis/imputation.do
        │     └─→ imputedallsvyqoimeans.dta
        │           │
        │           └─→ share/factoranalysis/imputedcategoryindex.do
        │                 └─→ imputedcategoryindex.dta (z-scored indices + z-scored VA)
        │                       │
        │                       ├─→ share/factoranalysis/indexregwithdemo.do (Panel A bivar + demo)
        │                       │     └─→ imputed_index_bivar_wdemo.{dta,xlsx}
        │                       │
        │                       └─→ share/factoranalysis/indexhorseracewithdemo.do (Panel B horse + demo)
        │                             └─→ imputed_index_horse_wdemo.{dta,xlsx}
        │
        └─→ share/factoranalysis/compcasecategoryindex.do (compcase parallel)
              └─→ compcasecategoryindex.dta
                    │
                    ├─→ indexregwithdemo.do (compcase Panel A bivar + demo)
                    │     └─→ compcase_index_bivar_wdemo.{dta,xlsx}
                    │
                    └─→ indexhorseracewithdemo.do (compcase Panel B horse + demo)
                          └─→ compcase_index_horse_wdemo.{dta,xlsx}

NB: school-char and test-score control inputs:
  share/factoranalysis/mattschlchar.do  → schlcharpooledmeans.dta
  share/factoranalysis/testscore.do     → testscorecontrols.dta
```

The two final-stage producers are `indexregwithdemo.do` (Panel A: bivariate per-index with controls) and `indexhorseracewithdemo.do` (Panel B: horse race with controls).

**No file in chunk 6 emits a `.tex`.** The `imputed_index_combined_wdemo.tex` is downstream of chunk 6 — produced by a separate writer file that consumes the `_bivar_wdemo` and `_horse_wdemo` `.dta` / `.xlsx` outputs. The downstream `.tex` writer is not in the 17-file chunk-6 scope.

### Q2 — Index construction

(a) **Item lists per index** (per `compcase/imputedcategoryindex.do` — the actual index-construction files):

| Index | Items used | Count |
|---|---|---|
| Climate | parentqoi 16, 17, 27; secqoi 22, 23, 24, 26, 27, 29 | 9 |
| Quality | parentqoi 30–34; secqoi 28, 35–40; staffqoi 20, 24, 87 | 15 |
| Support | parentqoi 15, 64; staffqoi 10, 128 | 4 |
| (Motivation) | (commented out — secqoi 31, 32, 33, 34) | (4, dropped) |

(b) **Sum or average?** The code is a **SUM** of items: `gen <index> = 0` then `replace <index> = <index> + <var>` per item (lines 36–52 of compcase, 33–50 of imputed). The paper's "averages" wording does NOT match the code mechanically. **However, after z-standardization, sum and (sum / k) for fixed k produce identical z-scores** (since dividing by a constant rescales mean and sd identically). So in regression coefficients of z-scored outcomes on z-scored indices, the sum-vs-average distinction is **statistically inert**. Nomenclature mismatch only.

(c) **z-standardization step.** Indices are z-scored at the end of construction in BOTH `compcasecategoryindex.do` (lines 65–68: `gen z_<i> = (<i> - r(mean))/r(sd)`) and `imputedcategoryindex.do` (lines 63–66). VA estimates are also z-scored at the same point (lines 59–62 / 58–61), with `replace`, overwriting the original `va_*` columns. So the saved `compcasecategoryindex.dta` and `imputedcategoryindex.dta` files contain **z-scored VA** and a z-scored copy of the index (`z_<index>`) alongside the un-standardized index (`<index>` itself, summed-but-not-z-scored).

### Q3 — Imputation pipeline

Two stages, both in `imputation.do`:

1. **Stage 1 — global mean impute (lines 70–74).** For every item in `allqoivars` (45 items pooled across all four categories): `egen mean<i> = mean(<i>)`, `replace <i> = mean<i> if missing(<i>)`, `drop mean<i>`. After this stage, no value is missing.
2. **Stage 2 — within-category regression impute (lines 80–128).** For each category, for each item: regress on the OTHER items in the same category PLUS the imputation-dummies for those other items, predict, and replace previously-missing values with predictions. This refines stage-1 means with category-specific structure.

**Predictor pool.** The within-category regression uses the **broad** category lists (climate 20, quality 17, support 4, motivation 4). These differ from the index pools (climate 9, quality 15, support 4, motivation dropped). So the imputation regression for a climate-index item uses 19 OTHER predictors (= 20 − 1) plus 19 imputation dummies, while only 8 of those 19 actually feed the climate index later.

### Q4 — Cronbach's α

Two competing producers:

- **`alpha.do`** (lines 117, 142, 167, 192) — α on the BROAD item lists (climate 20, quality 17, support 4, motivation 4), computed on the **complete-case** `allsvyqoimeans.dta` (line 114). This file also reports α for each survey alone (lines 35, 61, 89). This is the **likely paper-reported α** (the file is naming-convention-named `alpha.do` and writes a multi-sheet xlsx with the natural reporting headers).
- **`indexalpha.do`** (lines 20, 23, 26) — α on the NARROW item lists matching the constructed indices (climate 9, quality 15, support 4), computed on `compcasecategoryindex.dta` (line 13). This is α "as the indices are actually composed."

**Both compute α on complete-case data.** Neither uses imputed data.

The paper-reported α — without primary-source paper-text inspection — is most likely from `alpha.do` (broader list), but as noted in C1, those α values do not describe the indices used in Table 8 regressions. This is a paper-vs-code consistency question that needs the paper text to adjudicate.

### Q5 — Survey-VA merge geometry

**Unit:** cdscode (school) — NOT cdscode×year. All merges in the chain are `merge 1:1 cdscode using ...`:

- `allsvymerge.do` lines 55, 56, 59 — by cdscode.
- `imputedcategoryindex.do` line 26 (use), no merge.
- `mattschlchar.do` line 92 — by cdscode.
- `clean_va.do` line 74 — by cdscode.
- `indexregwithdemo.do` line 37, 40 — by cdscode.
- `indexhorseracewithdemo.do` line 41, 43 — by cdscode.

**Year alignment:**
- VA: pooled over school-years 2015-2018 per `clean_va.do` line 64 dataset label (4 years).
- Surveys: per the paper's "2017-2019" stated window (NOT verified in chunk 6 code — survey year window is set in upstream `<svyname>analysisready` files; not in chunk 6).
- School characteristics (Matt's data): collapsed over 2015-2017 per `mattschlchar.do` line 85. Documented as aligning with VA spring-semester years.
- Test-score controls: 2015-2017 per `testscore.do` line 16.

The year windows are NOT identical across components — VA is 2015-2018 (4 years), school chars are 2015-2017 (3 years). All collapse to school-level; the merge is at school-level only, so within-school year variation is averaged out before merge.

### Q6 — VA specifications in `allvaregs.do`

Per lines 32–39 and 76–88:

- **VA outcomes (line 76, also in compcasecategoryindex.do line 85 and elsewhere):** `ela math enr enr_2year enr_4year dk_enr dk_enr_2year dk_enr_4year` (8 outcomes).
- **Sample × control × peer combos (4 spec slots):**
  - `b` (base sample) × `b` (base control) × no peer → `va_<outcome>_b_sp_b_ct`
  - `las` (leave out score-sibling-acs sample) × `las` (kitchen-sink controls) × peer → `va_<outcome>_las_sp_las_ct_p`
  - The loop in lines 78–88 syntactically permits multiple controls per sample but each sample has only ONE control listed. So 2 sample-control combos × 1 peer-condition each = **2 distinct VA specs per outcome**, not 4.
- **Weighting:** unweighted (line 99) and `[aweight = gr11enr_mean]` (line 109) — both run.
- **Per-survey loop:** sec / parent / staff (line 44).
- **Bivariate, single QOI per regression** (line 99: `qui reg va_..._ct<peer> qoi<i>mean_z`).

So the regression count is: 3 surveys × (19 + 11 + 15 = 45) QOIs × 8 outcomes × 2 specs × 2 weighting flags = 360 + 720 = roughly 720 regressions; the actual loop produces 8 × 2 × 45 × 2 = 1,440 QOI-spec runs across 3 surveys → ~720 unique outcomes per file. (Order-of-magnitude check.)

### Q7 — clean_va.do destructive saves

**YES.** `clean_va.do` line 76 — bare `save, replace` inside the `foreach svyname` loop on lines 72–77. After loading `<svyname>analysisready.dta` on line 73 and merging VA in on line 74, the `save, replace` writes back to the same `.dta` file, in-place, destructively.

This is the only chunk-6 destructive in-place overwrite of an upstream artifact. It mutates `parentanalysisready.dta`, `secanalysisready.dta`, `staffanalysisready.dta` to include VA columns. As noted in C4, the change-log of `allsvymerge.do` line 12 indicates VA was supposed to be removed from these datasets — but the `clean_va.do` save still puts it back. Inconsistent state.

### Q8 — `mattschlchar.do` Matt-directory dependency

**YES, hardcoded.** Line 17: `use /home/research/ca_ed_lab/msnaven/common_core_va/data/sch_char, clear` — literal path to Matt Naven's user directory on Scribe.

**It is NOT gated by a `$mattxwalks` global.** The path is hardcoded in the `use` statement.

**It IS gated by `local clean = 0` toggle (line 15).** When `clean=0`, the entire cleaning block (lines 16–66) is skipped, so the hardcoded path is never read at runtime under default conditions. The file then proceeds to use the previously-saved `mattschlchar.dta` in `$projdir/dta/schoolchar/` (line 82).

**Cross-user implications.** For a fresh replication on a new user/machine, the file as-written would only re-clean if `clean=1` AND the user has access to `/home/research/ca_ed_lab/msnaven/...`. For most replicators this means `mattschlchar.dta` must be obtained as a pre-existing file in `$projdir/dta/schoolchar/` rather than rebuilt. This is a weak point for replication.

### Q9 — Naming token resolution

Confirmed from primary-source code:

- **`qoi<N>`** = "question of interest", numbered. Per-survey QOI numbers: sec 22-40, parent 9/15-17/27/30-34/64, staff 10/20/24/41/44/64/87/98/103-105/109/111/112/128 (per `allvaregs.do` lines 33-39 and `factor.do` lines 25, 43, 61).
- **`<survey>qoi<N>mean_pooled`** = per-school pooled mean of QOI N for survey ∈ {parent, sec, staff}. Renamed in `allsvymerge.do` lines 29, 38, 47.
- **`horse` / `horserace`** = multi-regressor regression with all 3 indices on the RHS. Confirmed at `indexhorserace.do` line 46: `qui reg va_..._ct<peer> z_climateindex z_qualityindex z_supportindex` — three indices simultaneously.
- **`bivar`** = bivariate regression — single index on RHS. Confirmed at `compcasecategoryindex.do` line 104, `indexregwithdemo.do` line 101 (single z-index).
- **`wdemo`** = with demographic + test-score controls (log-transformed). Used in `indexhorseracewithdemo.do` and `indexregwithdemo.do` filenames at lines 130, 132 and 158, 159 respectively.
- **`imputed`** = uses imputed data from `imputedallsvyqoimeans.dta`. **`compcase`** = complete-case from `allsvyqoimeans.dta` (no imputation). Both confirmed in `indexhorserace.do` (line 17 outer loop), `indexregwithdemo.do` (line 30), `indexhorseracewithdemo.do` (line 35).
- **`_p`** = peer-effects-included VA estimates. Confirmed at `compcasecategoryindex.do` lines 95–96 (`local peer "_p"` for sample=`las`).
- **`dk_enr` etc.** = "deep-knowledge enrollment" VA outcomes. Used in the outcome list `ela math enr enr_2year enr_4year dk_enr dk_enr_2year dk_enr_4year` (e.g., `compcasecategoryindex.do` line 85). Note these are NOT produced by `clean_va.do` (which only handles 5 outcomes); they must come from upstream survey analysisready files.
- **`_nw` / `_wt`** = unweighted / weighted (analytic-weight by `gr11enr_mean`). Confirmed at `allvaregs.do` line 100 (`_nw`) and 110 (`_wt`).
- **`<sample>_sp_<control>_ct`** = sample × specification × control type tokens of the VA estimate naming convention. `_sp_` and `_ct` are literal tokens; `_<peer>` (empty or `_p`) follows.

### Q10 — Distance-FB / Row 6 (paper Table 2/3 row 6) infrastructure

**No FB-test or distance infrastructure in chunk-6 files.** Greps for `fb_`, `distance`, `free_bus`, `busride`, `fbtest`, `FB ` returned zero hits across all 17 chunk-6 files. The chunk-6 layer is the **survey-VA + factor-analysis** layer; FB-tests and distance instruments live in a different chunk.

### Q11 — `mvpatterns` package

`mvpatterns` is used only in **`allsvymissing.do`** (lines 38, 40, 42, 44) — one call per category (climate / quality / support / motivation). It is a community-contributed package (`ssc install mvpatterns`) that enumerates **missing-value patterns** in a varlist: each unique combination of (missing/non-missing) flags across the variables gets a row, and the count of observations with that pattern. Output goes to the log file (which is named-logged on line 12 with `name(allsvymissing)` for easier copy-paste).

Not used in any other chunk-6 file.

---

## Bug summary (chunk 6)

Critical (changes results / data integrity):

- **B1:** `clean_va.do` line 76 — destructive in-place `save, replace` on each `<svyname>analysisready.dta`. **REAL.**
- **B2:** `allvaregs.do` line 197 — weighted merged dta saved over unweighted dta (filename collision: both write to `_va_all_nw.dta`). **REAL.**
- **B3:** Climate/quality index item lists ≠ α item lists in `alpha.do`; the paper-reported α (if from `alpha.do`) does not describe the indices used in Table 8 regressions. **REAL.**

Methodological:

- **M1:** Indices are SUMS, not AVERAGES (paper claim "averages" mismatches code; statistically inert post-z-scoring but nomenclature is wrong). **REAL.**
- **M2:** Imputation predictor pool is wider than the index pool — items used as imputation predictors are not necessarily in the index. Defensible but consequential for interpretation. **REAL.**
- **M3:** Stage-2 imputation regression (in `imputation.do`) is fit on data where stage-1 has already mean-imputed all missing values, which biases the regression toward the global mean. **REAL** but mitigated by the dummy-flag controls.

Minor / cosmetic:

- **B4:** `pcascore.do` line 38 — duplicate `pc1` histogram saved as `staffpc2score.png`. **REAL** but PCA is exploratory only.
- **B5:** `factor.do` line 11 — log directory written to `do/share/...` instead of `log/share/...`. **REAL** but only affects log location.
- **B6:** `indexhorserace.do` line 95 / `indexhorseracewithdemo.do` line 132 — `.csv` extension on `export excel` produces a file with confusing extension. Suspect; needs runtime confirmation.
- **B7:** `mattschlchar.do` line 17 — hardcoded `/home/research/ca_ed_lab/msnaven/...`. Gated by `clean=0` toggle so dormant by default. **REAL** as a replication weak point.
- **B8:** Header attribution drift — 2 files use "Christina Sun", 15 use "Che Sun" (same person, same email).
- **B9:** Motivation index orphan — fully imputed and α-reported, but commented out at index construction. **REAL** orphan computation.
- **B10:** Year-window mismatch — VA pooled 2015-2018 (4 years) vs. school chars 2015-2017 (3 years). Documented but inconsistent.
- **B11:** Silent merge attrition — `allsvymerge.do` lines 55–56 and 59 use `nogen` (or `keep(1 3) nogen`) without `assert _merge==3`.
- **B12:** `testscore.do` line 27 — variable named `prior_gr8_zscore` for year=2017 actually contains `L4_cst_ela_z_score` (4-year lag → likely grade 7), per the inline comment. Naming-comment mismatch.

---

## Summary of paper Table 8 producer-chain conclusion

Within chunk 6, the chain of producers ends at `_bivar_wdemo` and `_horse_wdemo` `.dta`/`.xlsx` outputs. The TeX-combination step (`imputed_index_combined_wdemo.tex`) is NOT produced by any of the 17 chunk-6 files. It must be downstream — a separate writer file that consumes both panels and emits the formatted Table 8 LaTeX.

The five most consequential chunk-6 findings to surface to the user are:

1. Climate/quality α item lists ≠ index item lists (C1 / B3).
2. Imputation predictor pool ≠ index pool (C2 / M2).
3. Indices are sums, paper says averages (M1) — statistically inert post-z-score, nomenclature only.
4. `clean_va.do` line 76 destructive in-place save (B1 / Q7).
5. `allvaregs.do` line 197 weighted/unweighted filename collision (B2).
