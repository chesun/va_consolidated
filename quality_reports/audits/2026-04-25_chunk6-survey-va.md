`imputed_index_combined_wdemo.tex` doesn't exist as an artifact — it must be produced downstream (a chunk-7+ task that converts these CSVs into the LaTeX table). The two key intermediate producers are `indexregwithdemo.do` (panel A: bivariate regressions per index with controls) and `indexhorseracewithdemo.do` (panel B: all 3 indices together with controls). I have enough. Now I'll write the audit.

---

# Chunk 6 Audit — Survey-VA Regressions + CalSCHLS Factor Analysis

## Pre-amble: deviations from the file list

- `share/factoranalysis/allsvymissing.do` is **not** in `share/factoranalysis/` — it lives at `do/check/allsvymissing.do`. I audited it from there.
- `share/svyvaregs/` contains exactly one file (`allvaregs.do`); no extras.
- `share/factoranalysis/` contains exactly the 14 expected files (15 minus the misplaced `allsvymissing.do`); no extras.
- `build/buildanalysisdata/poolingdata/` contains four other files beyond `clean_va.do` (`mergegr11enr.do`, `parentpooling.do`, `secpooling.do`, `staffpooling.do`) — these are upstream pooling helpers, not in this chunk's scope.

---

## Per-file audit entries

### File: `share/factoranalysis/alpha.do`

**Owner**: Christina Sun (header: "written by Che Sun … 6/5/2022 added putexcel code"). Christina = Che.
**Pipeline phase**: factoranalysis (Cronbach's alpha calculator)
**Lines**: 224
**Purpose**: Compute Cronbach's α for (a) each of the three survey-level QOI mean files (sec, parent, staff) and (b) each of the four conceptual question-categories (school climate, teacher/staff quality, student support, student motivation). Writes results to a multi-sheet Excel workbook.

**Loop structure**: not loop-driven; six near-identical blocks (3 surveys × 1 sheet each + 4 categories) repeated by copy-paste. Each block runs `alpha *mean_pooled, std item`, captures `r(alpha)`, transposes the four return matrices (`r(ItemTestCorr)`, `r(ItemRestCorr)`, `r(MeanInterItemCorr)`, `r(Alpha)`), writes to a fresh sheet via `putexcel`.

**Inputs**:

- `$projdir/dta/buildanalysisdata/analysisready/secanalysisready.dta` (line 31)
- `$projdir/dta/buildanalysisdata/analysisready/parentanalysisready.dta` (line 60)
- `$projdir/dta/buildanalysisdata/analysisready/staffanalysisready.dta` (line 88)
- `$projdir/dta/allsvyfactor/allsvyqoimeans.dta` (line 114) — used for the four category-level α's.

**Outputs**:

- `$projdir/out/csv/factoranalysis/alpha.xlsx` — multi-sheet workbook with sheets: `alpha_sec`, `alpha_parent`, `alpha_staff`, `alpha_school_climate`, `alpha_teacher_quality`, `alpha_student_support`, `alpha_student_motivation`.
- Log: `$projdir/log/share/factoranalysis/alpha.{smcl,log}`.

**Filename naming pattern**: `alpha_{section}` sheet names within `alpha.xlsx`.

**Statistical specification**: Cronbach's α with `, std item` — items standardized to mean 0, var 1 prior to averaging; `item` requests item-test/item-rest correlations. No regressions — descriptive psychometrics only.

**Sourced helpers / Calls**: none (`include`/`do` not used).

**Path references that need updating**: all `$projdir/...` — straightforward.

**Stata version / syntax**: explicit `version 16.0` (line 1) — only file in the chunk that pins a version. `putexcel` syntax with `modify open` (line 64, 91 etc.) requires Stata 13+.

**ssc/community packages used**: none — `alpha`, `putexcel` are base Stata.

**Gotchas / non-obvious behavior**:

- Line 64 comment ("use the open option so that stata writes to working memory, otherwise there are problems with changes not saving"): institutional knowledge that `modify` alone can fail across multi-sheet writes — keep the `modify open` flow when porting.
- Line 117: school-climate α uses 20 items (`parentqoi9, 16, 17, 27 + secqoi22-30 + staffqoi20, 24, 41, 44, 64, 87, 98`). Note `secqoi25, secqoi28, secqoi30` are included here, but `imputedcategoryindex.do` line 28 uses a **different** climate item set (drops `parentqoi9, secqoi25, secqoi28, secqoi30, staffqoi41, staffqoi44, staffqoi64, staffqoi98` and keeps the rest). **The α reported for "school climate" in this file is NOT the α for the index actually used in Table 8.** The matching α file is `indexalpha.do`.
- Line 142 (teacher quality α): includes `secqoi35-40` + `parentqoi30-34` + `staffqoi103-105, 109, 111, 112` — also wider than the index set used downstream (which adds `secqoi28`, `staffqoi20, 24, 87` and drops `staffqoi103-112`).
- Line 167 (student support α): only 4 items (`parentqoi15, 64, staffqoi10, 128`) — this is identical to the index version.
- Lines 192 (student motivation): 4 items `secqoi31-34`. This category is **not** used in Table 8 — paper drops "student motivation" from the final analysis (commented-out in `imputedcategoryindex.do` line 31).
- Line 215 has a stray blank line and `putexcel save` followed by `putexcel clear` — the `clear` is fine but not strictly needed.
- Line 24 `/* set trace on */` left commented (debug residue).
- `cap log close _all` ... `log close` pattern reused; `translate` at the end converts smcl to log.

**Reference to paper outputs**: paper §6 footnote reports α for school climate (0.94), teacher/staff quality (0.90), counseling support (0.66) — those are α's of the **indices**, computed in `indexalpha.do`, NOT this file. This file is exploratory/diagnostic.

**Notes / open questions**: the wider item lists here vs the narrower item lists in `imputedcategoryindex.do`/`compcasecategoryindex.do` are evidence of an exploratory→final winnowing. Document why specific items were dropped (suspicion: factor-analysis loadings or low item-rest correlation flagged some; verify with the secfactoreigen1/parentfactoreigen1/stafffactoreigen1 CSVs from `factor.do`).

---

### File: `share/factoranalysis/factor.do`

**Owner**: Christina Sun
**Pipeline phase**: factoranalysis (exploratory PCA/factor)
**Lines**: 80
**Purpose**: Run exploratory factor analysis (principal-factor method) on each of the three single-survey QOI-mean datasets. Produces full loading tables, scree plots, and eigenvalue-≥1 retained-factor tables. Diagnostic, used to inform index construction.

**Loop structure**: three sequential blocks (sec, parent, staff). Within each, an inner `foreach i of numlist ...` z-standardizes each `qoi`i'mean_pooled' (despite line-74 comment noting it's unnecessary).

**Inputs**:

- `secanalysisready.dta`, `parentanalysisready.dta`, `staffanalysisready.dta` (all `$projdir/dta/buildanalysisdata/analysisready/`).

**Outputs** (under `$projdir/out/csv/factoranalysis/` and `$projdir/out/graph/factoranalysis/`):

- `secfactorall.csv`, `parentfactorall.csv`, `stafffactorall.csv` — full loadings.
- `secfactoreigen1.csv`, `parentfactoreigen1.csv`, `stafffactoreigen1.csv` — retained factors only (mineigen=1).
- `secscreeplot.png`, `parentscreeplot.png`, `staffscreeplot.png` — diagnostic scree plots.

**Filename naming pattern**: `{survey}{factor*|screeplot}.{csv|png}`.

**Statistical specification**: `factor *mean_z` — Stata's default principal-factor method (PF), unrotated. Then `factor *mean_z, mineigen(1)` — Kaiser criterion. Comments document interpretation: 2 factors retained for sec, 1 for parent, 3 for staff.

**Sourced helpers / Calls**: none.

**Path references that need updating**: log location is **inside** the do-folder (`$projdir/do/share/factoranalysis/factor.smcl`, line 11) rather than `$projdir/log/...` — anomaly relative to all other files in the chunk. Probably an oversight.

**Stata version / syntax**: no explicit version. `factor` and `screeplot` are base.

**ssc/community packages used**: `estout`/`esttab` (already in catalog).

**Gotchas**:

- Line 11 + line 79: log file written into `do/` directory, not `log/` — copy-paste typo. **Inconsistency with project convention.**
- Lines 25, 43, 61: numlist hardcoded to QOI items per survey — different from the lists in `imputedcategoryindex.do`/`compcasecategoryindex.do` (e.g. line 43 includes `parentqoi9` and excludes `parentqoi64` in some places — actually line 43 uses `9 15/17 27 30/34 64`, which is the union; later index files drop `parentqoi9` and `parentqoi15`).
- Line 74 comment confirms standardization is decorative.

**Reference to paper outputs**: not directly tabulated; informs item selection that goes into the indices in `imputedcategoryindex.do`.

**Notes**: factor-analysis output is part of the audit trail justifying which items load on which dimensions. Re-run is needed to re-document if the underlying QOI list changes.

---

### File: `share/factoranalysis/allsvyfactor.do`

**Owner**: Christina Sun
**Pipeline phase**: factoranalysis
**Lines**: 29
**Purpose**: Run a single combined exploratory factor analysis on all 45 QOI means across the three surveys merged into `allsvyqoimeans.dta`.

**Loop structure**: linear, no loops.

**Inputs**: `$projdir/dta/allsvyfactor/allsvyqoimeans.dta` (produced by `allsvymerge.do`).

**Outputs**:

- `$projdir/out/csv/factoranalysis/allsvy/allsvyfactor.csv` — full loadings.
- `$projdir/out/csv/factoranalysis/allsvy/allsvyfactoreigen1.csv` — retained factors (Kaiser).
- `$projdir/out/graph/factoranalysis/allsvy/allsvyscreeplot.png`.

**Statistical specification**: `factor *mean_pooled` (no z-standardization here, consistent with the line-74 comment in `factor.do`). Mineigen=1 retains 6 factors (commented in line 23).

**Sourced helpers / Calls**: none.

**Path references**: standard `$projdir/...`.

**Stata version**: no version pin.

**ssc**: `estout`.

**Gotchas**: very thin file — assumes `allsvyqoimeans.dta` exists. Depends on `allsvymerge.do` having been run.

**Reference to paper**: paper §6 alludes to "exploratory factor analysis" supporting the 3-index structure — this file produces the across-survey loadings that motivated grouping items into school-climate / teacher-staff-quality / counseling-support buckets.

**Notes**: output reports 6 retained factors, but the paper uses 3 indices. The mapping from "6 statistical factors" to "3 substantive indices" is an editorial decision not encoded in code; lives in the comments in the index do-files.

---

### File: `share/factoranalysis/allsvymerge.do`

**Owner**: Christina Sun
**Pipeline phase**: factoranalysis (merge prep)
**Lines**: 66
**Purpose**: Build `allsvyqoimeans.dta` — wide file at school (cdscode) level that joins parent QOI means, secondary QOI means, staff QOI means, and pooled VA estimates. Used by `imputation.do`, `compcasecategoryindex.do`, and `imputedcategoryindex.do`.

**Loop structure**: three near-identical rename-and-save blocks (parent / sec / staff), then a chain of three `merge 1:1 cdscode using` commands.

**Inputs**:

- `parentanalysisready.dta`, `secanalysisready.dta`, `staffanalysisready.dta` (analysis-ready).
- `$projdir/dta/buildanalysisdata/va/va_pooled_all.dta` (line 59) — the school-level VA produced by `clean_va.do`.

**Outputs**:

- `$projdir/dta/allsvyfactor/formerge/parentqoimeans.dta`, `secqoimeans.dta`, `staffqoimeans.dta` (intermediate).
- `$projdir/dta/allsvyfactor/allsvyqoimeans.dta` (final merged file).

**Filename naming pattern**: `{survey}qoimeans` and `allsvyqoimeans`.

**Statistical specification**: pure data prep; no regressions.

**Sourced helpers / Calls**: none.

**Path references**: standard `$projdir`.

**Stata version**: no version pin.

**ssc**: none.

**Gotchas**:

- Lines 26, 37, 46: `keep cdscode qoi*` — the `qoi*` glob catches **only** the qoi-mean variables and **drops VA** from the per-survey extracts (this is intentional per the 12/19/2024 change-log entry on line 12).
- Line 59 then re-adds VA from `va_pooled_all.dta` after the survey-merge, which is the post-2024 convention.
- Line 29 `rename qoi* parentqoi*` — this is the namespace renaming so the joined file can carry all three. Critical: downstream files reference, e.g., `parentqoi16mean_pooled`, `secqoi22mean_pooled`, `staffqoi20mean_pooled`.
- `merge 1:1 cdscode using ..., nogen` × 3 — assumes 1:1 at school level. No `assert` / `keep(3)` — keeps unmatched (master+using). The VA merge uses `keep(1 3)` to retain master rows with no VA.

**Reference to paper**: this is the master CalSCHLS×VA dataset; everything Table-8-related downstream depends on it.

**Notes**: 12/19/2024 change-log entry confirms the VA-merge was decoupled from the per-survey rename — important, because it means the QOI-mean variables in the per-survey files retain VA even though the merged file gets a single, harmonized VA panel from `va_pooled_all.dta`.

---

### File: `do/check/allsvymissing.do` (NOT in `share/factoranalysis/`)

**Owner**: Christina Sun
**Pipeline phase**: factoranalysis (diagnostic / `check`)
**Lines**: 50
**Purpose**: Tabulate missingness patterns in the 45 QOI-mean variables across the three surveys for each of the four conceptual categories. Used to motivate the imputation in `imputation.do`.

**Loop structure**: linear; uses `egen rmiss()` and `mvpatterns` per category.

**Inputs**: `$projdir/dta/allsvyfactor/allsvyqoimeans.dta`.

**Outputs**: log only — `$projdir/log/check/allsvymissing.{smcl,log}` (note `name(allsvymissing)` on line 12 to make tab output copy-pastable).

**Statistical specification**: `egen nmissall = rmiss(*mean_pooled)`; `mvpatterns` per category.

**Sourced helpers**: none.

**Stata version**: none.

**ssc**: `mvpatterns` — **NEW package not in chunks 1-5 catalog**. Add to package list.

**Gotchas**: Lives in `do/check/`, not `do/share/factoranalysis/` — easy to miss when auditing.

**Reference to paper**: not directly. Diagnostic input to imputation design.

---

### File: `share/factoranalysis/imputation.do`

**Owner**: Christina Sun
**Pipeline phase**: factoranalysis (imputation)
**Lines**: 135
**Purpose**: Two-stage imputation of missing QOI means in `allsvyqoimeans.dta`: (1) flag-and-fill with sample mean, (2) regression-imputation predicting each item from the others within its category, plus dummies for which observations are imputed (Heckman-style imputation indicator). Saves `imputedallsvyqoimeans.dta`.

**Loop structure**: four near-identical category blocks (climate, quality, support, motivation). Inside each, `foreach i of local <cat>vars { reg `i' <other vars> <other-imputed-dummies>; predict; replace if imputed`i' == 1 }`.

**Inputs**: `$projdir/dta/allsvyfactor/allsvyqoimeans.dta`.

**Outputs**: `$projdir/dta/allsvyfactor/imputedallsvyqoimeans.dta`.

**Filename naming pattern**: `imputed`+`allsvyqoimeans` prefix denotes the imputation-applied version.

**Statistical specification**:

1. **Stage 1 (lines 70-74)**: replace missing with category-overall mean — but actually with **the dataset-wide mean for each item across all `allqoivars`** (`egen mean`i' = mean(`i')` is unconditional, not by category).
2. **Stage 2 (lines 80-128)**: for each item, OLS-regress on (all-other items in its category + dummies for whether other items in its category were originally missing), predict in-sample, and overwrite the originally-missing rows with the prediction. The "imputed" dummies are added so that the model controls for whether the regressors were themselves imputed.

The order of operations matters: Stage 1 fills all missing with means **before** Stage 2 runs. So Stage-2 regressions are run on a dataset with no missing, where some rows are mean-imputed; the dummies isolate those rows' contribution.

**Sourced helpers / Calls**: none.

**Path references**: standard `$projdir`.

**Stata version**: none.

**ssc**: none — base `reg`, `egen`, `predict`.

**Gotchas**:

- 12/19/2024 change-log entry (line 9) corrects a "spelling error in `supportimputedummies` local macro" — implying earlier runs may have had a buggy support-vars imputation list. Ask whether the previously-saved `imputedallsvyqoimeans.dta` was rebuilt after the fix.
- Line 19 `local allqoivars` includes `parentqoi9` and `parentqoi15` (and many others) but the category lists (lines 23-26) **do not all overlap exactly** with `allqoivars`: e.g. `parentqoi9` and `staffqoi98` are in `climatevars` but not all category-bearing combinations match. Stage 1 fills *every* item in `allqoivars`, so any item not in any category list is still mean-imputed (e.g. ones used elsewhere). Confirms that Stage 1 is broader than Stage 2.
- Lines 23-26 use **wider** category lists than the index-construction lists in `imputedcategoryindex.do` (cf. `imputedcategoryindex.do` line 28 drops `parentqoi9, secqoi25, secqoi28, secqoi30, staffqoi41, staffqoi44, staffqoi64, staffqoi98` from the climate set when **constructing the index**). So the imputation regressions use the wider 20-item climate set as predictors but the index is built on a narrower 9-item subset.
- Stage 2 regressions are unweighted. SE clustering is not applicable (it's just imputation).
- Line 9 docstring "NEED TO ADD VAR LABELS" — TODO in code.

**Reference to paper**: paper §6 says "missing values are imputed by …" — this is the operationalization. The imputed file feeds Table 8 (imputed panel).

**Notes**: the chained mean-impute → regression-impute is non-standard; documenting whether this was preferred over `mi impute chained` is worth a session-log entry.

---

### File: `share/factoranalysis/imputedcategoryindex.do`

**Owner**: Christina Sun
**Pipeline phase**: factoranalysis / index construction & bivariate VA regs (imputed)
**Lines**: 165
**Purpose**: From `imputedallsvyqoimeans.dta`, build three indices (climate, quality, support) by **summing** items in each category, z-standardize them and the VA estimates, run bivariate `reg va_<spec> z_<index>` regressions for every (outcome, sample, peer) × index combination, save each via `regsave`, then merge the per-cell tables into a wide table.

**Loop structure**: deeply nested:

```
outer: foreach va_outcome ∈ {ela, math, enr, enr_2year, enr_4year, dk_enr, dk_enr_2year, dk_enr_4year}    (8)
   foreach sample ∈ {b, las}                                                                              (2)
     foreach control of `<sample>_sample_controls` (b → b; las → las)                                     (1)
       set peer macro: "" if b, "_p" if las
       foreach index ∈ {climateindex, qualityindex, supportindex}                                          (3)
         qui reg va_..._sp_..._ct{,_p} z_<index>
         regsave …
```

8 × 2 × 1 × 3 = 48 regressions, one per VA-spec × index. The `local append replace`/`append append` pattern accumulates the three indices into one file per VA-spec.

**Inputs**: `$projdir/dta/allsvyfactor/imputedallsvyqoimeans.dta`.

**Outputs**:

- Per-VA-spec: `$projdir/out/dta/factor/imputed/va_{outcome}_{sample}_sp_{control}_ct{,_p}_index.dta` (16 files total: 8 outcomes × 2 samples).
- Combined: `$projdir/out/dta/factor/imputed/vaindex_imputedregs_all.dta` and `.../vaindex_imputedregs_all` Excel via `export excel`.
- The category index dataset itself: `$projdir/dta/allsvyfactor/categoryindex/imputedcategoryindex.dta` (line 119) — consumed by `indexalpha.do`, `indexhorserace.do`, `indexhorseracewithdemo.do`, `indexregwithdemo.do`.

**Filename naming pattern**: `va_<outcome>_<sample>_sp_<control>_ct{,_p}_index` for per-cell; `vaindex_imputedregs_all` for joined.

**Statistical specification**:

- Index = unweighted sum (line 37, 43, 49) of imputed items.
- Both VA and index are z-standardized (lines 58-66) so coefficients are SD-on-SD elasticities.
- Bivariate OLS with **no controls**, **no clustering**, no weights.
- The two VA branches are: (a) "b" sample with "b" controls, no peer effects; (b) "las" sample with "las" controls, with `_p` peer effects (`_sp_las_ct_p`).

**Sourced helpers**: none (`regsave` is ssc).

**Path references**: standard `$projdir`.

**Stata version**: none pinned.

**ssc**: `regsave` (already in catalog).

**Gotchas**:

- **Sum vs mean**: paper says indices are "averages across several questions within each category" — but lines 36-50 implement **sums**, not means. Then z-standardization (lines 64-66) makes the distinction immaterial for the coefficient (rescaling cancels out), but the *raw* index variable saved in `imputedcategoryindex.dta` is a sum, so any downstream user expecting a mean would be misled. Worth flagging.
- Line 31 `local motivationvars ...` is **commented out** — the student-motivation index is dropped from this file. Confirms the paper's choice of three indices.
- Line 28 **climate** items: `parentqoi16, 17, 27 + secqoi22, 23, 24, 26, 27, 29` (9 items, drops `parentqoi9` and `secqoi25, 28, 30, staffqoi*` relative to the wider α list).
- Line 29 **quality** items: `parentqoi30-34, secqoi28, 35-40, staffqoi20, 24, 87` (15 items — note `secqoi28` jumps from "climate" in the α file to "quality" here; staff items are `20, 24, 87` not the `103-112` set used in α file).
- Line 30 **support** items: `parentqoi15, 64, staffqoi10, 128` (4 items, identical to α version).
- Lines 58-61: `replace `var' = (`var' - r(mean))/r(sd)` — z-standardizes VA **in place** (overwrites the originals in this dataset), so the saved `imputedcategoryindex.dta` no longer has raw VA — it's all z-scored.
- VA outcomes loop (line 82) includes `dk_enr*` (Dukes "ever-enrolled-by-age-X") variants — confirms the survey-side regressions use both 6mo (the `_enr_*` set, presumably) and a different cohort definition. `dk_` prefix new naming token? Actually, `dk_` showed up in earlier chunks too — Dukes-style. (Catalog: confirmed.)
- 8 outcomes × 2 samples = 16 per-cell regsave files; merging done at lines 126-153 with the standard `merge_command`/`merge_options` deferred-macro idiom (`use` first, `merge 1:1 var using` after).

**Reference to paper**: produces the **imputed Panel A** of Table 8 (each index regressed alone on each VA spec). The combined `imputed_index_combined_wdemo.tex` referenced by the paper is built **downstream** (likely a chunk-7+ TeX writer that consumes `vaindex_imputedregs_all` plus `imputed_index_horse_wdemo` and adds demo controls); this file produces the Panel A inputs *without* demo controls. The "with demo controls" version is `indexregwithdemo.do`.

---

### File: `share/factoranalysis/compcasecategoryindex.do`

**Owner**: Christina Sun
**Pipeline phase**: factoranalysis / index construction & bivariate VA regs (complete-case)
**Lines**: 162
**Purpose**: Mirror of `imputedcategoryindex.do` but consumes the **non-imputed** `allsvyqoimeans.dta` — complete-case ("compcase") sample. Same indices, same VA spec set, same regsave structure.

**Loop structure**: identical pattern to `imputedcategoryindex.do`. The only structural difference is the per-cell regsave naming: `..._{control}_ct{,_p}_`index'` (line 106) vs `..._{control}_ct{,_p}_index` (in imputed). I.e., compcase splits by index in the filename, imputed concatenates indices into one file. Consequence: lines 125-158 loop over indices to merge per-index-per-VA-spec into per-index combined files.

**Inputs**: `$projdir/dta/allsvyfactor/allsvyqoimeans.dta`.

**Outputs**:

- Per-cell: `$projdir/out/dta/factor/compcase/va_<outcome>_<sample>_sp_<control>_ct{,_p}_<index>.dta` (16 files × 3 indices = 48 files).
- Combined per-index: `$projdir/out/dta/factor/compcase/<index>_va_compregs.dta` + `.../<index>_va_compregs.xls`.
- Category-index dataset: `$projdir/dta/allsvyfactor/categoryindex/compcasecategoryindex.dta` (line 120).

**Statistical specification**: same as `imputedcategoryindex.do` — bivariate OLS, no controls, no clustering, no weights.

**Sourced helpers**: none.

**Path references**: standard.

**Stata version**: none.

**ssc**: `regsave`.

**Gotchas**:

- Lines 30-32 use **identical** category item lists to `imputedcategoryindex.do` (climate=9, quality=15, support=4) — good consistency. But because data is non-imputed, schools with any missing item get a missing index value (since `replace climateindex = climateindex + var` propagates missing).
- Sample size will differ between compcase and imputed regressions — this is the source of N differences in Table 8 across panels. No `e(sample)` capture though; relying on `regsave` to record N.
- Same sum-not-mean issue as `imputedcategoryindex.do`.
- Lines 59-62: VA z-standardization overwrites variables in memory before the index dataset is saved, so `compcasecategoryindex.dta` carries z-standardized VA columns.

**Reference to paper**: produces the complete-case Panel A inputs.

---

### File: `share/factoranalysis/indexalpha.do`

**Owner**: Christina Sun
**Pipeline phase**: factoranalysis (Cronbach's α for the *indices* used in Table 8)
**Lines**: 31
**Purpose**: Compute Cronbach's α for the three index item sets actually used in the paper. **This is the file that produces the α's reported in the paper footnote (0.94 / 0.90 / 0.66).**

**Loop structure**: linear, three `alpha` calls.

**Inputs**: `$projdir/dta/allsvyfactor/categoryindex/compcasecategoryindex.dta`.

**Outputs**: log file only — no Excel/CSV. The α values are read from the log.

**Statistical specification**: `alpha <items>, std item` — same as `alpha.do`.

**Sourced helpers**: none.

**Stata version**: none pinned.

**ssc**: none.

**Gotchas**:

- Item lists (lines 15-17) are the **narrow** post-winnowed lists from `imputedcategoryindex.do`/`compcasecategoryindex.do`: 9 climate, 15 quality, 4 support items. These are the α's the paper reports.
- Reads `compcasecategoryindex.dta` not `imputedcategoryindex.dta`. So **the paper-reported α's are computed on the complete-case sample** (only schools with all items observed contribute). Worth noting in audit — it is an honest-α; using the imputed file would have inflated α slightly.
- Line 26 `alpha `supportvars', std item` with only 4 items will reasonably yield α=0.66 (low, consistent with paper).
- No log-translate at the end — the SMCL log is left in `log/share/factoranalysis/indexalpha.smcl`.

**Reference to paper**: paper §6 footnote α values (0.94, 0.90, 0.66) → produced here.

---

### File: `share/factoranalysis/indexhorserace.do`

**Owner**: Christina Sun
**Pipeline phase**: factoranalysis / horse-race VA regressions
**Lines**: 106
**Purpose**: For both compcase and imputed datasets, run a "horse race" OLS — VA regressed on **all three** z-standardized indices simultaneously (no demo controls). Output is a wide table merging per-VA-spec results.

**Loop structure**: outermost `foreach type ∈ {compcase, imputed}` (2). Inside, the standard 8 × 2 × 1 = 16-cell loop. One regression per cell (no inner index loop, since all 3 indices enter together).

**Inputs**:

- `$projdir/dta/allsvyfactor/categoryindex/compcasecategoryindex.dta`
- `$projdir/dta/allsvyfactor/categoryindex/imputedcategoryindex.dta`

**Outputs**:

- Per-cell: `$projdir/out/csv/factoranalysis/indexhorserace/va_<outcome>_<sample>_sp_<control>_ct{,_p}_<type>.dta`.
- Combined: `$projdir/out/csv/factoranalysis/indexhorserace/<type>horserace.csv`.

**Filename naming pattern**: per-type combined file `compcasehorserace.csv` / `imputedhorserace.csv`. New naming token: **`horserace`** (multi-regressor specification).

**Statistical specification**: `qui reg va_<spec> z_climateindex z_qualityindex z_supportindex`. Bivariate-pattern broken — **trivariate** here. No controls, no weights, no clustering.

**Sourced helpers**: none.

**Stata version**: none.

**ssc**: `regsave`.

**Gotchas**:

- Output file extension is `.csv` for the combined — `export excel ... .csv` (line 95) writes an Excel-format file with `.csv` extension. This is a known quirk of `export excel` and produces a binary xlsx-like file with `.csv` extension. Consumers of these files need to know they are not ASCII CSVs.
- No `save` of the regression-merged dataset before `export excel` — only the per-cell `regsave` outputs and the export. Diff vs `compcasecategoryindex.do` which `save`s to `categoryindex/`.
- Output dir `out/csv/factoranalysis/indexhorserace/` is mixed-purpose: contains `.dta`s (per-cell regsave) and the combined "csv" (actually xlsx).

**Reference to paper**: produces **Panel B without demo controls**. The "with demo controls" version of Panel B is `indexhorseracewithdemo.do`.

---

### File: `share/factoranalysis/indexhorseracewithdemo.do`

**Owner**: Christina Sun (header line 6 says "Christina Sun")
**Pipeline phase**: factoranalysis / horse-race + demographic controls
**Lines**: 161
**Purpose**: Same as `indexhorserace.do` but **adds school-demographic controls and SBAC test-score controls** to each regression. **Strong candidate for paper Table 8 Panel B.**

**Loop structure**: identical to `indexhorserace.do` but with demo merge + log of demo vars before the VA loop.

**Inputs**:

- `compcasecategoryindex.dta` / `imputedcategoryindex.dta`
- `$projdir/dta/schoolchar/schlcharpooledmeans.dta` (line 41) — produced by `mattschlchar.do`.
- `$projdir/dta/schoolchar/testscorecontrols.dta` (line 43) — produced by `testscore.do`.

**Outputs**:

- Per-cell: `$projdir/out/dta/factor/indexhorsewithdemo/{type}/va_<outcome>_<sample>_sp_<control>_ct{,_p}.dta`.
- Combined: `$projdir/out/dta/factor/indexhorsewithdemo/{type}_index_horse_wdemo.dta` and `.../indexhorsewithdemo/{type}_index_horse_wdemo.csv` (line 132 — same `export excel` to `.csv` quirk as `indexhorserace.do`).

**Filename naming pattern**: token `_horse_wdemo` (combined trivariate-with-demo). New tokens: **`horse`**, **`wdemo`**.

**Statistical specification**:

- `reg va_<spec> z_climateindex z_qualityindex z_supportindex ln_<demo1> ... ln_<demoK> avg_gr6math_zscore avg_gr8ela_zscore`
- Demo controls: log-transformed (lines 55-57) with `+ 0.0000001` offset to handle zeros.
- demo vars (line 49): `minorityenrprop maleenrprop freemealprop elprop maleteachprop minoritystaffprop newteachprop fullcredprop fteteachperstudent fteadminperstudent fteserviceperstudent` (11 controls).
- score vars (line 52): `avg_gr6math_zscore avg_gr8ela_zscore` (2 controls).
- No clustering, no weights — heteroskedasticity-only OLS standard errors.

**Sourced helpers**: none.

**Path references**: standard.

**Stata version**: none pinned.

**ssc**: `regsave`.

**Gotchas**:

- Lines 41-43 merge with `keep(1 3) nogen` — keeps master and matched, but unmatched master rows will have missing demos and drop out of the regression silently. No `assert _merge==3` — silent attrition.
- `set seed 1984` (line 28) is set but no stochastic operations exist — vestigial.
- `set varabbrev off`, `set graphics off` (lines 25-26) — defensive.
- Header attribution differs from sister files: line 6 `Christina Sun` not `Che Sun`. They're the same person, but inconsistent owner attribution.
- Line 132 export-excel-to-csv quirk; line 130 also does a proper `save .dta`. Good — the .dta is the canonical artifact.
- Line 80 contains the regression. With `cap log close _all` (line 19) but **no `clear all`** — running this from a session with state could leak variables. Diff vs sister files which use `clear all`.
- Lines 152-156: prints start/end timestamps to log — useful instrumentation.

**Reference to paper**: produces `imputed_index_horse_wdemo.{dta,xls}`, the most likely backing for **Table 8 Panel B with controls**. The paper file `imputed_index_combined_wdemo.tex` is plausibly built downstream by combining Panel A from `indexregwithdemo.do` with Panel B from this file.

---

### File: `share/factoranalysis/indexregwithdemo.do`

**Owner**: Christina Sun
**Pipeline phase**: factoranalysis / bivariate VA regs + demographic controls
**Lines**: 167
**Purpose**: Same as `imputedcategoryindex.do`/`compcasecategoryindex.do` (bivariate per-index regressions) but **with the school-demographic and test-score controls** added. **This is the producer for Panel A with controls — likely the immediate input to the `imputed_index_combined_wdemo.tex` paper file.**

**Loop structure**: outermost `foreach type ∈ {compcase, imputed}` (2). Inside, the standard 8 × 2 × 1 × 3 = 48-regression loop (3 indices, each entered alone).

**Inputs**:

- `compcasecategoryindex.dta` / `imputedcategoryindex.dta`
- `schlcharpooledmeans.dta`, `testscorecontrols.dta`.

**Outputs**:

- Per-cell: `$projdir/out/dta/factor/indexbivarwithdemo/{type}/va_<outcome>_<sample>_sp_<control>_ct{,_p}_index.dta`.
- Combined: `$projdir/out/dta/factor/indexbivarwithdemo/{type}_index_bivar_wdemo.dta` + `.../{type}_index_bivar_wdemo.xls` (Excel-format with `.xls` extension this time, not `.csv` — line 159).
- Per-type category-index-with-demo dataset: `$projdir/dta/allsvyfactor/categoryindex/{type}indexwithdemo.dta` (line 120).

**Filename naming pattern**: token **`bivar_wdemo`** (panel A with demo). Companion to `_horse_wdemo`.

**Statistical specification**:

- `reg va_<spec> z_<index> ln_<demo*> avg_gr6math_zscore avg_gr8ela_zscore`
- demo+score controls = same 11+2 set as `indexhorseracewithdemo.do`.
- The `local append_macro replace`/`append append` pattern within the inner loop accumulates the three indices into one regsave file per (outcome, sample, peer) cell.

**Sourced helpers**: none.

**Stata version**: none pinned.

**ssc**: `regsave`.

**Gotchas**:

- Line 60-66 has a **commented-out z-standardization** of demo vars. Code uses log-transform instead. Check whether the paper's coefficients on demos are interpretable as elasticities (they should be — both LHS and RHS are scaled in SDs except the demos which are logs).
- Line 101 `reg ... z_<index> ln_* `scorevars'` — the `ln_*` glob picks up all logged demo variables generated lines 55-57 plus, importantly, **any other variable starting with `ln_` already in the dataset**. The category-index files don't have other `ln_` vars, so it's safe in practice, but the glob is fragile.
- Like `indexhorseracewithdemo.do`, no `clear all` at top — line 18-20 just `cap log close _all` then `clear all` (line 19). OK.
- Same `_merge` silent-attrition behavior from `keep(1 3) nogen` (lines 37, 40).

**Reference to paper**: produces `imputed_index_bivar_wdemo.{dta,xls}` — the imputed Panel A with controls. The paper Table 8 (`imputed_index_combined_wdemo.tex`) almost certainly comes from a downstream TeX-writer that consumes this file together with `imputed_index_horse_wdemo` from `indexhorseracewithdemo.do`. **No do-file in chunk 6 emits `.tex` — confirming the LaTeX writer is in another chunk** (probably the `tabletotex` or `share/tabletotex/` family in chunks 7-10).

---

### File: `share/factoranalysis/mattschlchar.do`

**Owner**: Christina Sun (cleans Matt Naven's data — cross-user dependency)
**Pipeline phase**: survey_clean (school characteristics)
**Lines**: 104
**Purpose**: Build `schlcharpooledmeans.dta`, the school-level pooled-mean (over 14-15 to 16-17) demographic/staffing characteristics dataset, by (a) reading Matt's raw `sch_char.dta` from his home folder, renaming and labeling vars (gated by a manual toggle), then (b) computing `elprop` (English-learner proportion) by collapsing a CDE student-level test-score file, (c) collapsing Matt's data over 2015-17 + merging in elprop.

**Loop structure**: linear; one rename block (lines 16-66, gated by `local clean = 0`) and one data-build block (lines 69-99).

**Inputs**:

- `/home/research/ca_ed_lab/msnaven/common_core_va/data/sch_char.dta` — **HARD-CODED ABSOLUTE PATH** (line 17). This is the cross-user dependency on Matt Naven's home directory. **High-risk for portability.** The toggle `local clean = 0` (line 15) keeps the block dormant by default; whoever last built `mattschlchar.dta` ran with `clean = 1`.
- `$vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta` (line 71) — for elprop.
- `$projdir/dta/schoolchar/mattschlchar.dta` (line 82) — built lazily.
- `$projdir/dta/schoolchar/elprop.dta` (line 92).

**Outputs**:

- `$projdir/dta/schoolchar/mattschlchar.dta` (line 65) — only when `clean=1`.
- `$projdir/dta/schoolchar/elprop.dta` (line 78).
- `$projdir/dta/schoolchar/schlcharpooledmeans.dta` (line 99) — the consumed-downstream dataset.

**Statistical specification**: pure data prep + `collapse (mean)`. No regressions.

**Sourced helpers**: none.

**Path references that need updating**:

- Line 17: `/home/research/ca_ed_lab/msnaven/common_core_va/data/sch_char` — needs replacement when porting to consolidated repo. Document path. Was Matt's pre-merge raw data.
- `$vaprojdir/data/restricted_access/...` (line 71) — second project-dir global, presumably the `va_consolidated` project root or a `/home/research/ca_ed_lab/...` parent. (Already noted in chunk 1; settings.do likely defines `$vaprojdir`.)

**Stata version**: none.

**ssc**: none — base.

**Gotchas**:

- Toggle pattern (line 15) is dangerous: re-running this script will **not** re-build `mattschlchar.dta` unless someone flips `clean=1`. Document this convention.
- Line 31 `drop el_prop` (with underscore!) — Matt's raw data has `el_prop` but it's dropped because of missing-data problems (per line 68 comment); replaced via the test-score-derived `elprop` from line 72.
- `keep if inrange(year, 2015, 2017)` (line 85) — restricts to 14-15, 15-16, 16-17 school years. Note the school-year-of-spring-semester convention (year=2015 means 2014-15 school year).
- `collapse *prop fte*, by(cdscode)` (line 90) — implicit list. *Any* variable starting with "prop" or "fte" in scope is averaged. Fragile if Matt adds variables.
- `merge ... keep if _merge==3` (line 94) — drops cdscodes without elprop. Acceptable for the index regression sample but **introduces sample restriction not documented in paper**.
- Date-range mismatch with VA: clean_va.do collapses VA over **2015-2018** (line 39 of clean_va.do), but mattschlchar.do collapses demos over **2015-2017** (line 85). Three-year vs four-year window. This is an acknowledged issue, perhaps because Matt's data ends in 2016-17. Document.

**Reference to paper**: produces the controls used in Table 8 with-demo specifications.

---

### File: `share/factoranalysis/pcascore.do`

**Owner**: Christina Sun
**Pipeline phase**: factoranalysis (PCA composite scores — diagnostic)
**Lines**: 44
**Purpose**: Compute first principal-component score for each survey separately and plot histograms of the PC scores. Diagnostic only.

**Loop structure**: three sequential blocks (sec, parent, staff).

**Inputs**: the three analysisready files.

**Outputs**: histograms only — `$projdir/out/graph/factoranalysis/pcascore/{sec,parent,staff}{pcascore,pc1score,pc2score}.png`. No saved score datasets.

**Statistical specification**: `pca *mean_pooled; predict pc1, score`. Staff also extracts `pc2`.

**Gotchas**: lines 36-39 — staff PC1 and PC2 histograms both load `pc1` (the second `histogram pc1` should probably be `histogram pc2`). **Bug**: `staffpc2score.png` is just a duplicate of `staffpc1score.png`.

**ssc**: none.

**Reference to paper**: not used.

**Notes**: diagnostic only; can be skipped during consolidation.

---

### File: `share/factoranalysis/testscore.do`

**Owner**: Christina Sun
**Pipeline phase**: survey_clean (test-score controls)
**Lines**: 50
**Purpose**: Build `testscorecontrols.dta` — school-level pooled (across 2015-17) average 6th-grade math z-score and 8th-grade ELA z-score for the 11th-grade cohorts in those years. Used as a control in `indexregwithdemo.do` and `indexhorseracewithdemo.do`.

**Loop structure**: linear.

**Inputs**:

- `$vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta` (line 17) — restricted-access state-student-level data.
- `$vaprojdir/data/restricted_access/clean/k12_test_scores/k12_lag_test_scores_clean.dta` (line 20) — lagged scores.

**Outputs**: `$projdir/dta/schoolchar/testscorecontrols.dta` (line 45).

**Statistical specification**: filter to 11th-grade CAASPP 2015-17, merge with lagged-scores file, take grade-6 math (`L5_cst_math_z_score`) and grade-8 ELA (`L3_cst_ela_z_score`, with grade-7 fallback `L4_cst_ela_z_score` for year=2017 — lines 26-27), collapse to school-year then to school.

**Gotchas**:

- Lines 26-27 the L3→L4 fallback for 2017 is a data-quality workaround. Worth ADR.
- L5 = 5 lags = grade 11 - 5 = grade 6; L3 = 3 lags = grade 11 - 3 = grade 8. This is the grade-mapping convention.
- `collapse` then `collapse` again (lines 33, 36) — first collapse to school-year, then to school. Equivalent to a single collapse with `by(cdscode)` only? Not quite — first collapse balances years. Documented.
- `drop if missing(cdscode)` (line 41) — cleans up.

**Reference to paper**: provides demo controls (test-score baseline) for Table 8 with-controls panels. Paper §6 does not explicitly mention these controls.

---

### File: `share/svyvaregs/allvaregs.do`

**Owner**: Christina Sun
**Pipeline phase**: survey_va (per-question survey-VA regressions)
**Lines**: 211
**Purpose**: For each survey (sec, parent, staff), z-standardize all QOI means and VA estimates, run **per-question bivariate** regressions of each VA spec on each individual QOI z-score (both unweighted and grade-11-enrollment-weighted), save via `regsave`, merge per-survey into wide tables and export. **This is the supersession of `parentvareg.do` and `secvareg.do` per the docstring.**

**Loop structure**: outer `foreach svyname ∈ {sec, parent, staff}` (3). Inside, the standard 8-VA-outcomes × 2-samples × 1-control × per-survey-qoi-list = ~3 × 8 × 2 × ~15-19 = ~700-900 regressions per survey, doubled because each is run unweighted and weighted (`[aweight = gr11enr_mean]`) — total ~1.5-2k regressions.

**Inputs**: `$projdir/dta/buildanalysisdata/analysisready/{svyname}analysisready.dta` for each survey.

**Outputs**:

- Per-cell: `$projdir/out/dta/varegs/{svyname}/va_<spec>_{nw,wt}.dta`.
- Combined unweighted: `$projdir/out/dta/varegs/{svyname}/{svyname}_va_all_nw.dta` + `.../out/xls/varegs/unweighted/{svyname}/{svyname}_va_all_nw.xls`.
- Combined weighted: should be `..._wt.dta` but **lines 197-198 save the weighted combined file to the same `_nw` filename and only the xls is `_wt`** — overwrites the unweighted .dta with the weighted regs!

**Filename naming pattern**: `_nw` (no weight), `_wt` (weighted). New tokens: **`nw`**, **`wt`** (already in catalog).

**Statistical specification**:

- All bivariate, no controls, no clustering.
- Both unweighted (`reg`) and weighted (`reg ... [aweight = gr11enr_mean]`).
- LHS and RHS both z-standardized → coefficient = SD-on-SD elasticity.

**Sourced helpers**: none.

**Stata version**: none.

**ssc**: `regsave`.

**Gotchas**:

- **BUG line 197**: `save $projdir/out/dta/varegs/`svyname'/`svyname'_va_all_nw, replace` — this is in the **weighted** merge block (it should be `_wt` not `_nw`). The weighted .dta result is silently overwriting the unweighted .dta. The accompanying xls (line 198) is correctly `_wt`. **Verify with the user — likely a typo.** This means consumers reading `{svyname}_va_all_nw.dta` from disk get the *weighted* combined regs, not the unweighted ones (since weighted merge runs second). **High-priority bug.**
- Line 36 parent QOI numbers: `9 15 16 17 27 30 31 32 33 34 64` — matches `factor.do` line 43 numlist. Note `parentqoi9` is here but excluded from the `climatevars` index in `imputedcategoryindex.do`.
- `set seed 1984` (line 27) — vestigial (no random ops).
- VA standardization (lines 59-62) — **in place**, overwrites VA values in the analysisready file's working copy (does not save). Only affects this run.
- weight variable `gr11enr_mean` (line 109) — pooled-mean grade-11 enrollment, presumably built upstream by `mergegr11enr.do` (out of scope).
- Inner-loop logic (lines 76-119) ends each VA-spec cell with an unweighted regsave then a weighted regsave, both `, append` after the first index. The `local append replace` at line 91 resets only at the start of each new sample/control combination.

**Reference to paper**: produces per-QOI survey-VA regressions — these are auxiliary to Table 8 (which uses indices not individual QOIs). May feed an appendix / robustness display table where each survey question is examined separately. Paper map says Table 8 uses index files, not these — so `allvaregs.do` outputs are likely **Appendix Tables**.

---

### File: `build/buildanalysisdata/poolingdata/clean_va.do`

**Owner**: Christina Sun
**Pipeline phase**: survey_clean (VA → school-level mean over 2015-2018, merge to surveys)
**Lines**: 93
**Purpose**: Read each VA-outcome estimates file (school×year level) from the fork pipeline, collapse to school-level mean over years 2015-2018, merge across the five outcomes, then merge the resulting school-level VA into each survey's analysisready dataset (replacing in place).

**Loop structure**: two outer loops:

1. Lines 42-48: foreach va_outcome ∈ {ela, math, enr, enr_2year, enr_4year} (5) — collapse each per-outcome estimates file to school level, save to tempfile.
2. Lines 58-62: deferred-macro merge of the 5 tempfiles into `va_pooled_all.dta`.
3. Lines 72-77: foreach svyname ∈ {sec, parent, staff} (3) — merge `va_pooled_all` onto analysisready, save in place.

**Inputs**:

- `$vaprojdir/estimates/va_cfr_all_v1/va_est_dta/va_<outcome>_all.dta` (line 43) — the school×year VA estimates produced by the fork pipeline (chunk 3 confirmed `va_<outcome>_all.dta` is the per-outcome merge).
- `$projdir/dta/buildanalysisdata/analysisready/{sec,parent,staff}analysisready.dta` (line 73).

**Outputs**:

- `$projdir/dta/buildanalysisdata/va/va_pooled_all.dta` (line 65) — school-level VA, all 5 outcomes, single row per cdscode.
- Replaces (lines 76 `save, replace`) the three analysisready datasets in-place with VA columns added.

**Filename naming pattern**: `va_pooled_all` for the consolidated school-level VA.

**Statistical specification**:

- `collapse (mean) va*, by(cdscode)` (line 44) — simple unweighted school-level mean across years 2015-2018.
- Note: line 39 says "over the years 2015-2018" — but no `keep if inrange(year, 2015, 2018)` is present. The collapse takes whatever rows are in the per-outcome files. **This relies on the upstream `va_<outcome>_all.dta` already being filtered to 2015-2018.** From chunk 3 we know `va_all.dta` typically pools all available years; need to confirm the year-filter happens upstream. This is a potential data-window bug.
- `va*` glob — captures every variable starting with `va`, including all the spec variants (`va_ela_b_sp_b_ct`, `va_ela_las_sp_las_ct_p_m`, etc.).

**Sourced helpers**: none.

**Stata version**: none.

**ssc**: none — base.

**Gotchas**:

- **Year-window mismatch with paper**: paper says VA averaged over 2015-2018, surveys averaged over 2017-2019. So the merge happens at **school** level (cdscode only), with `va_pooled_all` being a single school-level column collapsed across 2015-2018, and the analysisready survey datasets being pooled over 2017-2019 (whatever pooling logic lives in the per-survey `parentpooling.do`/`secpooling.do`/`staffpooling.do`). Year-mismatch is handled by **collapsing both sides to the school level before merging**. There's no school×year merge; the merge is purely cross-sectional.
- Line 12 has `do $projdir/do/build//buildanalysisdata/poolingdata/clean_va.do` — typo with **double slash** (`build//buildanalysisdata`). Same double-slash typo appears on lines 29, 91, 92 (`$projdir/log/build//buildanalysisdata/...`). Stata tolerates double slashes on Unix; harmless but ugly.
- `set seed 1984` (line 27), `set graphics off`, `set scheme s1color` — vestigial defaults.
- `merge 1:1 cdscode using ..., keep(1 3) nogen` (line 74) — schools in survey but not in VA are kept (with missing VA); schools in VA but not in survey are dropped. **Asymmetric attrition pattern**: survey-only schools are retained (for descriptive stats?) but VA-only schools are dropped. Document.
- Line 76 `save, replace` overwrites the analysisready files **in place** — so once `clean_va.do` runs, the analysisready files contain VA columns; the original (VA-free) versions are gone. Any later script that loads analysisready expects VA to be present. Make sure rebuild order is clean: each rerun of `clean_va.do` re-overlays VA, but the prior in-place save means the file diff isn't reproducible from raw. This is a non-idempotent build-step pattern.
- Double comment headers (lines 6-9) include "this do file replaces poolingva.do and combineva.do" — confirms supersession (chunk 1 noted these files are absent or deprecated).

**Reference to paper**: ALL Table 8 regressions (and `allvaregs.do`) consume VA columns added by this script. The school-level merge geometry (cdscode-only, no year) and the year-window asymmetry (VA 2015-18 vs surveys 2017-19) is encoded here.

---

## Chunk 6 synthesis

### Paper Table 8 producer chain

Best-supported chain:

```
clean_va.do
  └─→ va_pooled_all.dta (school × VA-spec cross-section, 2015-2018 mean)
  └─→ {sec,parent,staff}analysisready.dta (in-place overwrite to add VA cols)

allsvymerge.do
  └─→ allsvyqoimeans.dta (3 surveys' QOI means + VA, school-level wide)

imputation.do
  └─→ imputedallsvyqoimeans.dta (item-level mean-impute then within-category regression-impute)

[compcase branch]                       [imputed branch]
compcasecategoryindex.do                imputedcategoryindex.do
  └─→ compcasecategoryindex.dta           └─→ imputedcategoryindex.dta
                                           (sums of items, z-standardized;
                                            VA z-standardized in-place)

mattschlchar.do                         testscore.do
  └─→ schlcharpooledmeans.dta             └─→ testscorecontrols.dta
       (Matt’s school chars, 14-15..16-17)    (gr 6 math, gr 8 ELA, 14-15..16-17)

[Panel A with controls — bivar per index]   [Panel B with controls — horse race]
indexregwithdemo.do                          indexhorseracewithdemo.do
  └─→ {compcase,imputed}_index_bivar_wdemo     └─→ {compcase,imputed}_index_horse_wdemo
      .dta + .xls                                  .dta + .csv (Excel-format)

[downstream chunk 7+ TeX writer]
  └─→ tables/share/survey/pub/imputed_index_combined_wdemo.tex   ← paper Table 8
```

The `imputed_index_combined_wdemo.tex` file referenced by the paper map is **NOT produced by any do file in chunk 6**. The chunk-6 outputs end at `_bivar_wdemo` and `_horse_wdemo` `.dta`/`.xls`/`.csv` artifacts. The TeX-combination step lives elsewhere (likely a `tabletotex` family file in chunks 7-10 that reads both `bivar_wdemo` and `horse_wdemo` and emits the two-panel `combined_wdemo.tex`).

There are also intermediate VA regression artifacts at no-controls level produced by `imputedcategoryindex.do` (`vaindex_imputedregs_all`) and `compcasecategoryindex.do` (`<index>_va_compregs`), and at horse-race-no-controls level (`indexhorserace.do` → `compcasehorserace.csv` / `imputedhorserace.csv`). These are not used by Table 8 with-controls but supply the "without controls" robustness in an appendix (presumed).

### Index construction logic (paper §6)

- **Three indices**: school climate, teacher/staff quality, counseling support. Student-motivation index dropped (commented out in `imputedcategoryindex.do` line 31).
- **Items per index** (post-winnowing, from `imputedcategoryindex.do` lines 28-30):
  - **Climate** (9 items): `parentqoi16, 17, 27`; `secqoi22, 23, 24, 26, 27, 29`. Note: dropped from the wider 20-item α-set — `parentqoi9, secqoi25, 28, 30, staffqoi20, 24, 41, 44, 64, 87, 98`.
  - **Quality** (15 items): `parentqoi30-34`; `secqoi28, 35-40`; `staffqoi20, 24, 87`. Note `secqoi28` migrated from "climate" (in `alpha.do`) to "quality" (in indices); `staffqoi103-112` (in `alpha.do`) replaced by `staffqoi20, 24, 87` for indices.
  - **Support** (4 items): `parentqoi15, 64, staffqoi10, 128`. Identical between α and index files.
- **Scoring**: items already arrive as `qoi*mean_pooled` — i.e. school-level means of student responses to each question. The pooling-to-school-level happens upstream in `parentpooling.do`/`secpooling.do`/`staffpooling.do` (out of scope for this chunk, but flagged for chunks 7+). Likert-numeric responses; **reverse-coding (if any) would have happened at the per-question pooling step**, also out of chunk-6 scope.
- **Aggregation**: lines 36-50 of `imputedcategoryindex.do`/`compcasecategoryindex.do` use `gen <cat>index = 0` then `replace <cat>index = <cat>index + <var>` — i.e. a **sum**, not an average. **Discrepancy with paper text** ("averages across several questions"). Because z-standardization (lines 64-66) follows immediately, the coefficient is invariant to the sum-vs-mean choice (rescaling), but the raw index variable saved on disk is a sum. Worth fixing in paper or in code.
- **Standardization**: line 65 of `imputedcategoryindex.do` `gen z_<index> = (<index> - r(mean))/r(sd)` — the indices used in regressions are SD = 1, mean = 0. VA estimates are also z-standardized in place (lines 58-61). So the regressions are SD-on-SD.
- **Imputation**: applied in `imputation.do` per category (Stage 1: dataset-mean fill; Stage 2: within-category regression-imputation with imputed-indicator dummies as controls). Output `imputedallsvyqoimeans.dta` consumed by `imputedcategoryindex.do`. Compcase branch consumes the un-imputed `allsvyqoimeans.dta`.

### Cronbach's α computation file

- **`indexalpha.do`** computes the α's reported in the paper footnote. It loads `compcasecategoryindex.dta` (i.e., complete-case item values, not imputed) and runs `alpha <items>, std item` for each of the three index-item lists (9, 15, 4 items respectively). The α's flow only to the log file — they're hand-copied into the paper (no Excel/CSV emission).
- `alpha.do` separately computes α at survey-level and at category-level using **wider** item sets — these are not the paper-reported α's.

### Survey-VA merge geometry

- **All merges are at `cdscode` only (no year).** This is the year-mismatch resolution: VA is collapsed (mean over 2015-2018) → 1 row per school in `va_pooled_all.dta`; surveys are pooled across 2017-2019 (in upstream pooling files, out of chunk-6 scope) → 1 row per school in each analysisready file. The cross-section merge (`merge 1:1 cdscode`) joins them.
- `clean_va.do` line 74: `merge 1:1 cdscode using va_pooled_all, keep(1 3) nogen` — survey-side master rows are kept regardless of VA presence; VA-only schools are dropped. Schools with missing VA show up as missing in regression, not dropped a priori — the regressions handle them via listwise deletion at run time.
- The asymmetry (VA 2015-2018 vs surveys 2017-2019) is intentional but not tested for sensitivity in chunk 6 — there's no "alternative window" robustness file. Paper §6 should document.

### VA specifications used

`allvaregs.do`, the four index-related regression files, all loop over the same set:

```
outcomes:  ela, math, enr, enr_2year, enr_4year,
           dk_enr, dk_enr_2year, dk_enr_4year                          (8)
samples:   b (base), las (leave-acs-sibling)                            (2)
controls:  b → b ; las → las                                             (1 each)
peer:      "" if b ; "_p" if las                                         (built into spec)
```

Yielding spec strings of the form `va_<outcome>_<sample>_sp_<control>_ct{,_p}`. For example: `va_ela_b_sp_b_ct` (no peer), `va_math_las_sp_las_ct_p` (with peer).

**The `_m` (math) suffix ambiguity**: chunks 1-5 noted `_m` could mean "math" or be a sample marker. Here, the outcome `math` is in the loop variable, while the spec name is `va_math_b_sp_b_ct`. There's no `_m` token in the chunk-6 spec naming. So in survey-VA regs, `_m` does **not** appear — only the full outcome-name is in the spec.

**`enr` family**: 6 enrollment-style outcomes (`enr, enr_2year, enr_4year, dk_enr, dk_enr_2year, dk_enr_4year`). The `dk_` prefix presumably denotes the Dukes-style cohort definition (chunk 3 noted; confirmed here as a parallel set of three outcomes alongside `enr*`).

### New naming tokens / ssc packages

**New tokens introduced this chunk**:

- `_nw` / `_wt` — unweighted / weighted (already in catalog from chunks 1-5; reused).
- `horse` / `horserace` — multi-regressor index specification (all 3 indices on RHS together). New for the survey-VA side.
- `wdemo` — with demographic controls (test-score + Matt-school-chars). New token.
- `bivar` — bivariate (one index at a time on RHS). New token. Pairs with `horse` for the two panel kinds.
- `imputed` / `compcase` — the imputation-vs-complete-case branch flag. New tokens, file-name suffix and folder-name segment both.
- `qoi` — "question of interest" (used pervasively, but worth canonicalizing): `<survey>qoi<NN>mean_pooled` is the per-question school-level pooled mean.

**ssc packages new to this chunk** (additions to chunks 1-5 catalog):

- **`mvpatterns`** — used in `do/check/allsvymissing.do` line 38. Add to package list.

(All other packages in chunk 6 — `regsave`, `estout`/`esttab` — are already in catalog. `alpha`, `factor`, `pca`, `screeplot`, `histogram`, `putexcel`, `egen rmiss`, `collapse` are all base Stata.)

### Distance-FB Row 6 mystery

**Negative finding** (as expected): no `_d_` token, no `fb_d`, no `distance` references anywhere in chunk-6 files. This chunk is purely survey-VA / index analysis; the FB testing infrastructure (paper Tables 2-3) lives in the fork pipeline. Distance-FB Row 6 must reside in a chunk earlier than 6 (1-5) or in unaudited files (chunks 7-10).

### Anomalies / bugs (parallel to prior chunks)

1. **Bug — `allvaregs.do` line 197**: weighted-merge block saves to `_nw` filename instead of `_wt`. The `.dta` for the unweighted combined regs is silently overwritten by the weighted regs. The `.xls` file is correctly suffixed `_wt`. Verify and fix.

2. **Bug — `pcascore.do` lines 36-39**: staff PC2 histogram code re-uses `pc1` instead of `pc2`. `staffpc2score.png` is a duplicate of `staffpc1score.png`.

3. **Sum-vs-mean discrepancy**: paper says "averages"; code computes sums (`imputedcategoryindex.do` lines 36-50 and `compcasecategoryindex.do` lines 36-52). Z-standardization downstream makes coefficients identical, but the raw `<cat>index` variable on disk is a sum. Fix the paper text or divide by item count.

4. **In-place destructive saves**: `clean_va.do` line 76 (`save, replace` on analysisready files) and `imputedcategoryindex.do`/`compcasecategoryindex.do` (z-standardize VA in place before saving the categoryindex file). Reproducibility relies on always rebuilding from upstream raw — no separate "raw" copy of the analysisready file post-VA-merge.

5. **Path inconsistencies / typos**:
   - `factor.do` line 11 & 79: log file written to `do/share/factoranalysis/factor.{smcl,log}` instead of `log/share/factoranalysis/`. Anomaly.
   - `clean_va.do` lines 12, 29, 91, 92: `build//buildanalysisdata` double-slash typo (harmless on Unix but ugly).
   - `mattschlchar.do` line 17: hard-coded path `/home/research/ca_ed_lab/msnaven/common_core_va/data/sch_char` — cross-user dependency, gated by `local clean = 0` toggle.
   - `indexalpha.do`: no `translate` smcl→log, leaves smcl only.

6. **Header attribution drift**: `indexhorseracewithdemo.do` line 6 says "Christina Sun" while sibling files say "Che Sun". Same person, but inconsistent.

7. **Vestigial `set seed 1984`**: present in `clean_va.do`, `allvaregs.do`, `indexhorseracewithdemo.do` despite no stochastic operations. Harmless.

8. **Silent merge attrition**: every `merge ... keep(1 3) nogen` in chunk 6 silently drops unmatched-using rows without an `assert _merge==3` check. In `mattschlchar.do` line 94 the **opposite** `keep if _merge==3` drops both unmatched cases — likewise undocumented sample restriction.

9. **Imputation-list mismatch**: `imputation.do` uses the 20/17/4/4-item *wider* category lists (lines 23-26) for predictor pools; `imputedcategoryindex.do` uses the *narrower* 9/15/4-item lists for index construction (lines 28-30). So items removed from the index pool (e.g. `parentqoi9`) are still used as **predictors** during imputation. Whether that's intended is worth a note.

10. **`mattschlchar.do` toggle pattern (line 15)**: `local clean = 0` means re-running the do file does NOT rebuild `mattschlchar.dta` from raw — only `elprop` and `schlcharpooledmeans` are rebuilt. Easy to miss.

11. **Mean-impute + regression-impute order in `imputation.do`**: stage 1 fills all missing with the dataset mean (lines 70-74) **before** stage 2 runs the within-category regressions (lines 80-128). Means stage-2 regressions are run on a fully observed dataset where some rows are mean-imputed; the imputed-indicator dummies in stage 2 are meant to absorb that. Non-standard imputation pipeline. Document the rationale.

12. **Empty `motivation` index**: `imputedcategoryindex.do` line 31 has `motivationvars` commented out — confirms the paper's three-index structure. But `alpha.do` and `imputation.do` still process motivation items, leaving orphan downstream. Consider deletion.

### Open questions

**For user (Christina/Christina-as-Che):**

- Is the `allvaregs.do` line-197 bug (weighted save → `_nw` filename) a known typo or intentional? If known, when was it introduced?
- Was `imputedallsvyqoimeans.dta` rebuilt after the 12/19/2024 `supportimputedummies` spelling fix in `imputation.do`? If not, downstream `imputedcategoryindex.dta` may carry pre-fix imputations.
- The paper's "averages" language vs the code's "sums" — fix paper or fix code?
- Does the asymmetric year-window (VA 2015-18 vs surveys 2017-19) get robustness-tested? If not, plan a chunk-7+ alternative-window file.
- `mattschlchar.do` line 17: where does the consolidated repo expect to find `sch_char.dta`? Need to either rebuild or copy `mattschlchar.dta` into the consolidated tree.
- `clean_va.do` line 39 says "2015-2018" but no `keep if inrange(year, 2015, 2018)` is present — is the year-restriction enforced upstream in `va_<outcome>_all.dta` (chunk 3)? Verify.

**For downstream chunks 7-10:**

- Locate the LaTeX writer that produces `imputed_index_combined_wdemo.tex` from the `_bivar_wdemo` + `_horse_wdemo` `.dta`s.
- Document the per-question / per-survey LaTeX writer that consumes `allvaregs.do` outputs (probably also chunks 7-10).
- Distance-FB Row 6 producer must be identified in those chunks.
- Confirm the upstream pooling logic (parent/sec/staff `*pooling.do` in `build/buildanalysisdata/poolingdata/`) for survey-year window and Likert reverse-coding.
- The `dk_` prefix for enrollment outcomes — establish which "Dukes-style" definition this corresponds to and verify it's the version used in the paper's mechanism table (Table 8).