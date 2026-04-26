# Chunk-8 Verified Audit (Round 2, Independent Blind Verification)

**Scope:** Sample-construction layer.
**Date:** 2026-04-26.
**Reviewer instruction:** Forbidden to read `quality_reports/audits/round-1/`. All claims grounded in primary source line citations.

---

## Executive summary of findings

1. Paper Table A.1 (`counts_k12.tex`) is produced by `do_files/share/sample_counts_tab.do`, wired into `do_files/do_all.do:226`. The archived `do_files/_archive/matt_original/sum_stats.do` is NOT wired into `do_all.do` and is superseded.
2. Two cohort-size cuts coexist and are NOT redundant: `cohort_size<=10` (school-level cohort size) and `n_g11_<subject> < 7` (school×year cell N for a specific touse). Both are real and operate at different levels.
3. **Three** `pooledrr` definitions exist in two different files (round-1 reportedly claimed two; round-2 finds at least three; arguably four if we count the secondary diagnostics version separately). All four are saved to different .dta files so they don't collide on disk, but the variable name overload is a real footgun.
4. Sex coding inversion between secondary and elementary is real and confirmed (`secdemographics.do:102`, `elemdemographics.do:67` comments; recoding logic at the lines below); the underlying recoding produces consistent `female`/`male` indicators downstream.
5. Trans/nb/questioning gender from sec1718/sec1819 is acknowledged in a comment (`secdemographics.do:59`) but never ingested by current code path.
6. Comments in `touse_va.do:104-106` and `create_va_sample.doh` (counterpart) describe ">25% special ed" and "home/hospital" filters that the code does NOT implement.
7. `create_out_samples.do:71` does `rename enr_ontime enr` (after `drop enr enr_2year enr_4year` on line 70). Same pattern in `touse_va.do:117`. This silently overwrites the original `enr` semantics with the on-time variant.
8. Dead code: `egen n_g11_<subject>_<sample>_sp` computed at `create_score_samples.do:240-247` and `egen n_g11_<outcome>_<sample>_sp` at `create_out_samples.do:225-232` are never `save`'d. These are the dataset-level n-counts for VA scatter plots; they vanish at the end of the `foreach` loop.
9. Silent demographic recoding bug: `pooledsecdemographics.do:23-24` does `replace gr9asianenr = gr9asianenr + gr9filipinoenr` (and gr11). Filipino students are silently merged into the Asian category. The downstream `pooledasianrr` therefore actually means "Asian + Filipino combined".
10. Silent data-quality drops at graph time: `pooledsecanalysis.do:31-43` generates `checkhispanic`, `checkasian`, `checkblack`, `checkwhite` indicators for "survey count exceeds enrollment" and then does sequential `drop if check<race>==1` BEFORE the histograms but AFTER the all-races `pooledrr` and `pooledfemalerr` histograms. The race-specific histograms after line 43 see a different sample (intersection of all 4 race validity checks).
11. `trimparentdemo.do` and `trimsecdemo.do` are pure projection/rename helpers; no statistical trimming. Confirmed.
12. Survey pooling pattern: 5-year append → `wtmean` weighted by `nettotalresp<i>` → `collapse (mean)` for pooled stats and `(sum)` for raw counts → save pooledstats → merge response rate → save analysisready. Schema-divergence (parent 1415 missing qoi64) is handled implicitly because `wtmean` of `qoi64mean` ignores missings; missing `nettotalresp64` for 1415 contributes nothing.
13. `gr11enr_mean` weight chain: produced at `dta/enrollment/schoollevel/poolgr11enr` (outside chunk-8 scope), merged at `mergegr11enr.do:15, 25, 35` for parent/sec/staff respectively, and consumed downstream as `[aweight=gr11enr_mean]` (in chunk-9-scope analysis files; not visible in chunk-8 files).

---

## Per-file audit

### 1. `cde_va_project_fork/do_files/sbac/touse_va.do` (201 lines)

**Purpose:** Build `touse_g11_<subject|outcome>` flags on the master test-scores dataset. Outputs `data/sbac/va_samples.dta` (a crosswalk of `merge_id_k12_test_scores` and all `touse*` variables).

**Stata version:** `version 16.1` (line 1).

**Inputs:**
- `k12_test_scores/k12_test_scores_clean.dta` (line 63)
- `k12_test_scores/k12_lag_test_scores_clean.dta` (lagged scores, line 67)
- `k12_test_scores/k12_peer_test_scores_clean.dta` (peer scores, line 79)
- `k12_test_scores_public/k12_diff_school_prop_schyr.dta` (grade-span proportions, line 92)
- `k12_test_scores_public/k12_cohort_size_sch.dta` (median cohort size, line 96)
- `k12_public_schools/k12_public_schools_clean.dta` (conventional-school flag, line 100)
- Merged via `do_files/merge_k12_postsecondary.doh enr_only` (line 115) — postsecondary outcomes
- Helper includes: `do_files/sbac/macros_va.doh` (line 45); `do_files/sbac/create_diff_school_prop.doh` (line 129); `do_files/sbac/create_prior_scores.doh` (line 131)

**Output:** `data/sbac/va_samples.dta` keeping only `merge_id_k12_test_scores touse*` (lines 191, 194).

**Restrictions encoded:**
- L102: `replace touse = 0 if conventional_school!=1` — Restriction R4.
- L109: `replace touse = 0 if cohort_size<=10` — Restriction R5 (cohort-level cut).
- L136-138 (test scores) / L161-163 (outcomes): `mark touse_g11_<subject|outcome>` with conjunction
  - `grade==11` (R1)
  - `dataset=="CAASPP"`
  - `inrange(year, test_score_min_year, test_score_max_year)` (2015–2018) for scores; `(outcome_min_year, outcome_max_year)` (also 2015–2018) for outcomes
  - `diff_school_prop>=0.95` (R2)
  - `first_scores_sample==1` (R3)
- L139-148 (test scores) / L164-173 (outcomes): `markout` against
  - the test score (R6) `sbac_<subject>_z_score`
  - `school_id i.year`
  - `school_controls`, `demographic_controls` (R7), `ela_score_controls` and `math_score_controls` (R8), peer demographics, peer prior scores
- L150 / L175: `replace touse_g11_<subject|outcome> = 0 if touse==0` — propagate sample-master flag (carries R4 and R5).
- L152-155 / L177-180: `egen n_g11_<subject|outcome> = count(state_student_id) if touse_g11_<subject|outcome>==1, by(cdscode year)` then `replace touse_g11_<subject|outcome> = 0 if n_g11_<subject|outcome><7` — Restriction R9 (cell N>=7 cut at school×year×subject level).

**Comment-only restrictions (NOT IMPLEMENTED in code):**
- L104: `* Exclude schools where more than 25 percent of students are receiving special education services`
- L106: `* Drop if a student is receiving instruction at home, in a hospital, or in a school serving disabled students solely`
- These two comments stand alone with no corresponding code. **Confirms Q11 finding** — the paper may mention these restrictions but they are not in the code.

**`enr_ontime → enr` rename:** L117-119
```
drop enr enr_2year enr_4year
rename enr_ontime enr
rename enr_ontime_2year enr_2year
rename enr_ontime_4year enr_4year
```
After `merge_k12_postsecondary.doh enr_only` brings in both `enr` and `enr_ontime` flavors, the original `enr` is dropped and `enr_ontime` is renamed to `enr`. Downstream code expecting `enr` actually gets the on-time variant. This is destructive renaming and is **easy to miss** because the symbol name is preserved.

**Bugs/anomalies:**
- Comment-only restrictions at L104 and L106.
- `enr_ontime → enr` overwrite at L117 (silent semantic shift).
- `version 16.1` (L1) but file uses `set scheme s1color` (L36) — not an issue.

---

### 2. `cde_va_project_fork/do_files/sbac/create_score_samples.do` (280 lines)

**Purpose:** Materialize 7 score-sample fan-out files (`b, l, a, s, la, ls, las`) × 2 versions (`v1, v2`) — total 14 datasets — under `data/va_samples_<v>/score_<sample>.dta`.

**Stata syntax:** No `version` declaration; uses standard Stata syntax.

**Inputs (per iteration of foreach version in v1 v2):**
- `data/sbac/va_samples.dta` (touse flags, indirectly via `create_va_sample.doh`)
- `k12_test_scores_clean.dta` (indirectly)
- `do_files/sbac/macros_va.doh` (L52)
- `do_files/sbac/create_va_sample.doh` (L63)
- `do_files/sbac/create_va_g11_sample_<version>.doh` (L70)
- `do_files/k12_postsec_distance/merge_k12_postsec_dist.doh` (L73)
- `do_files/sbac/merge_lag2_ela.doh` (L76)
- `do_files/sbac/merge_loscore.doh` (L107)
- `do_files/sbac/merge_va_smp_acs.doh` — used for ACS arms (L124, L166)
- `do_files/sbac/merge_sib.doh` — sibling arms (L149, L190, L209, L230)

**Outputs (per iteration):**
- `data/va_samples_<v>/score_b.dta` (L84)
- `data/va_samples_<v>/score_l.dta` (L112)
- `data/va_samples_<v>/score_a.dta` (L134)
- `data/va_samples_<v>/score_s.dta` (L154)
- `data/va_samples_<v>/score_la.dta` (L175)
- `data/va_samples_<v>/score_ls.dta` (L196)
- `data/va_samples_<v>/score_as.dta` (L215)
- `data/va_samples_<v>/score_las.dta` (L236)

**Sample fan-out semantics:** From CHANGE LOG L13-22:
- `b` = base
- `l` = leave-out prior score
- `a` = ACS controls
- `s` = sibling controls
- `la, ls, as, las` = combinations

**Dead code (Q13 verified):** L240-247
```stata
foreach sample in b l a s la ls las {
    foreach subject in ela math {
    use $vaprojdir/data/va_samples_`version'/score_`sample'.dta, clear
    egen n_g11_`subject'_`sample'_sp = count(state_student_id) ///
      if touse_g11_`subject'==1 ///
      , by(cdscode year)
  }
}
```
The inner loop uses each `score_<sample>.dta` and computes `n_g11_<subject>_<sample>_sp`, but does NOT `save` after the egen. Each iteration overwrites the in-memory dataset on the next `use` and there is no `save, replace` call. The variable is never persisted. **Round-1 finding confirmed.** 

The naming convention `n_g11_<outcome>_<sample>_sp` is described in the CHANGE LOG L29-31 as intended for "weighting in scatter plots" — but it never reaches disk. Whatever is plotted using `_sp` variables comes from a different source (or is silently using the persisted `n_g11_<subject>` from `touse_va.do:152` which lacks the `_<sample>_sp` suffix).

---

### 3. `cde_va_project_fork/do_files/sbac/create_out_samples.do` (245 lines)

**Purpose:** Mirror of `create_score_samples.do` for outcomes. Materializes 7 outcome-sample fan-out files (`b, l, a, s, la, ls, las`) × 2 versions, total 14 datasets.

**Outputs:** `data/va_samples_<v>/out_<sample>.dta` (one per arm).

**`enr_ontime → enr` rename (Q12 confirmed):** L69-73
```stata
do do_files/merge_k12_postsecondary.doh enr_only
drop enr enr_2year enr_4year
rename enr_ontime enr
rename enr_ontime_2year enr_2year
rename enr_ontime_4year enr_4year
```
Same pattern as `touse_va.do:117`. After this, the variable named `enr` in `out_b.dta` actually carries `enr_ontime` semantics (i.e., enrolled within 6 months of HS graduation, not "ever enrolled"). This is the postsecondary outcome used by all downstream regressions in `out_*.dta`.

**Dead code:** L225-232
```stata
foreach sample in b l a s la ls las {
  foreach outcome in enr enr_2year enr_4year {
    use $vaprojdir/data/va_samples_`version'/out_`sample'.dta, clear
    egen n_g11_`outcome'_`sample'_sp = count(state_student_id) ///
      if touse_g11_`outcome'==1 ///
      , by(cdscode year)
  }
}
```
Same dead-code pattern as `create_score_samples.do:240-247`. No `save`. The egen output never reaches disk.

---

### 4. `caschls/do/build/buildanalysisdata/poolingdata/parentpooling.do` (99 lines)

**Purpose:** Pool parent-survey QOI statistics across years 2014/15–2018/19, merge with response-rate dataset, save analysis-ready .dta.

**Inputs:**
- `parentqoiclean1819, 1718, 1617, 1516, 1415` (lines 14-22) — appended in reverse-chronological order
- `responserate/parentresponserate.dta` (line 87)

**Outputs:**
- `poolingdata/parentpooledstats.dta` (line 84) — wtmean stats only
- `analysisready/parentanalysisready.dta` (line 94) — pooled stats + response rates

**Pooling logic:**
- `drop if missing(cdscode)` (line 24) — comment notes "3 observations with missing cdscode"
- L31-33: `wtmean(qoi<i>mean), weight(nettotalresp<i>)` for `i in {9, 15/17, 27, 30/34, 64}` — note qoi64 is included.
- L36-40: `pctagree<i>`, `pctdisagree<i>`, `pctdontknow<i>` weighted means for `i in {9, 15/17, 27, 30/34}` (NOT 64).
- L43-46: qoi64 has special pct vars: `pctwell64`, `pctokay64`, `pctnotwell64`, `pctdontknow64`.
- L49-50: `collapse (mean) *pooled (sum) nettotalresp* stragree* agree* disagree* strdisagree* dontknow* verywell64 justokay64 notwell64 doesnotdo64 missing*, by(cdscode)`.

**Schema divergence (Q5):** Parent 1415 reportedly missing qoi 64. Since `wtmean` ignores missing values, the pooled qoi64mean for a school that appeared in all 5 years (one of which was 1415 with qoi64=missing) collapses to the wtmean over only the years that had qoi64 — confirmed by Stata's `wtmean` semantics. No special handling in code; the natural missing-skip behavior is sufficient.

**Final merge:** L87 `merge 1:1 cdscode using ... parentresponserate`, then `drop _merge` (L88), `drop if missing(cdscode)` (L90), save `parentanalysisready` (L94).

---

### 5. `caschls/do/build/buildanalysisdata/poolingdata/secpooling.do` (107 lines)

**Purpose:** Pool secondary-survey QOI statistics across 5 years.

**Inputs:** `secqoiclean1415..1819` (L17-24); `responserate/secresponserate.dta` (L94).

**Outputs:** `poolingdata/secpooledstats.dta` (L89); `analysisready/secanalysisready.dta` (L102).

**Pooling logic:**
- `drop if missing(cdscode)` (L26) — "one observation".
- L34-36: `wtmean(qoi<i>mean), weight(nettotalresp<i>)` for `i in {22/40}`.
- L40-44: `pctagree<i>`, `pctdisagree<i>`, `pctneither<i>` for `i in {22/34}`.
- L47-50: `pcttrue<i>`, `pctnottrue<i>` for `i in {35/40}`.
- L53-54: `collapse (mean) *pooled (sum) nettotalresp* missing* strdisagree* disagree* neither* agree* stragree* nottrue* littletrue* prettytrue* verytrue*, by(cdscode)`.

Comment at L31: "Note: collapse doesn't work because the weight is different for each variable, would have to write everything out" — explains why `wtmean` is preferred over `collapse [aweight=]`.

---

### 6. `caschls/do/build/buildanalysisdata/poolingdata/staffpooling.do` (89 lines)

**Purpose:** Pool staff-survey QOI statistics across 5 years.

**Inputs:** `staffqoiclean1415..1819` (L14-21).

**Output:** `poolingdata/staffpooledstats.dta` (L84).

**No analysis-ready file:** Comment at L80: "there is no staff response rate so cannot merge with the response rate dataset." Therefore staffanalysisready is created later, in `mergegr11enr.do:39` (only adds the gr11enr_mean weight, not response rates).

**Pooling logic:**
- L31-33: `wtmean(qoi<i>mean), weight(nettotalresp<i>)` for `i in {10, 20, 24, 41, 44, 64, 87, 98, 103/105, 109, 111, 112, 128}`.
- L36-39: `pctagree`, `pctdisagree` for the agree/disagree-style qoi (excluding qoi 98).
- L42-43: `pctsmallprob98`, `pctbigprob98` for qoi98 (problem-severity scale).
- L46-49: `pctyes<i>`, `pctno<i>` for `i in {103/105, 109, 111, 112}` (yes/no).
- L51: `collapse (mean) *pooled (sum) nettotalresp* missing*, by(cdscode)`.

**Schema divergence (Q5 — staff 1718/1819 missing pctnotapp):** Not directly visible in this file. The `pctnotapp` variable is not part of the variable list collapsed at L51 (only `*pooled`, `nettotalresp*`, `missing*`). If `pctnotapp` exists in some years and not others, it's neither pooled nor saved here. The schema divergence is upstream (`staffqoiclean<year>.dta` files, in chunk-6 scope); this file does not propagate any `pctnotapp` mismatch.

---

### 7. `caschls/do/build/buildanalysisdata/poolingdata/mergegr11enr.do` (44 lines)

**Purpose:** Add the `gr11enr_mean` weight to all three analysis-ready datasets.

**Inputs:**
- `analysisready/parentanalysisready.dta` (L14)
- `analysisready/secanalysisready.dta` (L24)
- `poolingdata/staffpooledstats.dta` (L34) — note: staff comes from `poolingdata/`, not `analysisready/`
- `enrollment/schoollevel/poolgr11enr.dta` (L15, L25, L35) — source of `gr11enr_mean` (creation outside chunk-8 scope)

**Outputs (in-place except staff):**
- `parentanalysisready.dta` (L19, in-place `save, replace`)
- `secanalysisready.dta` (L29, in-place)
- `analysisready/staffanalysisready.dta` (L39, NEW save)

**Q3 verification (gr11enr_mean weight chain):**
- Generated: `dta/enrollment/schoollevel/poolgr11enr.dta` — outside chunk-8 (chunk-7 / enrollment build).
- Merged: `mergegr11enr.do:15, 25, 35` (parent, sec, staff in that order).
- Consumed downstream as `[aweight=gr11enr_mean]` — confirmed in many chunk-9 share/ files (not in chunk-8 scope).

**Anomaly:** L19 and L29 are `save, replace` without explicit path — they overwrite the dataset most recently `use`'d at L14 and L24 respectively. So `parentanalysisready` and `secanalysisready` are silently re-saved with an additional column. The behavior is the standard Stata "save, replace" idiom but is implicit destructive update.

---

### 8. `caschls/do/build/buildanalysisdata/responserate/parentresponserate.do` (95 lines)

**Purpose:** Combine 5 years of trimmed parent demographics (after `trimparentdemo.do`) into a school-level response-rate dataset.

**Inputs:** `demotrim/parent/trimparentdemo<year>.dta` for each of 5 years (L13, 14, 18, 22, 26).

**Output:** `responserate/parentresponserate.dta` (L91).

**Logic:**
- L13-29: Sequential `merge 1:1 cdscode using` for each year. Comments on L15, 19, 23, 27 record matched/not-matched counts. After each merge, `drop _merge`. By the end, the school is on the dataset if it had a parent survey response in any of the 5 years.
- L33-39: `replace svygr<i>_<year> = 0 if missing` for each grade i (1-12) and each year — recodes "no responses" as 0 (since unmatched after merge means zero, not unknown).
- L46-49: `gen svy<year> = svygr1_<year> + ... + svygr12_<year>` — total survey responses across grades 1-12 in each year.
- L51-55: `gen enr<year> = enrgr1_<year> + ... + enrgr12_<year>` — total enrollment grades 1-12.
- L57-61: `gen has<year> = (svy<year> > 0)` — indicator for each year.
- **L72: `gen pooledrr = numertemp/denomtemp`** where numer = sum of `svy<year>` over years with `has<year>==1`, denom = sum of `enr<year>` over those same years. **POOLEDRR DEFINITION #1: Parent, grades 1-12, conditional on year having any response.**
- L77-87: Repeat the calculation for grades 9 and 11 only → `pooledrr_gr9and11` (L85).

**Q6 verification:** First definition site of `pooledrr` is here at L72.

---

### 9. `caschls/do/build/buildanalysisdata/responserate/secresponserate.do` (96 lines)

**Purpose:** Mirror of `parentresponserate.do` for secondary survey.

**Output:** `responserate/secresponserate.dta` (L91).

**Differences from parent:**
- L31: grades local is `"9" "10" "11" "12"` (not 1-12).
- L47: `gen svy<year> = svygr9_<year> + svygr10_<year> + svygr11_<year> + svygr12_<year>` — sum over only 9-12.
- L52: `gen enr<year> = enrgr9_<year> + enrgr10_<year> + enrgr11_<year> + enrgr12_<year>`.
- **L71: `gen pooledrr = numertemp/denomtemp`** — **POOLEDRR DEFINITION #2: Secondary, grades 9-12, conditional on year having any response.**
- L84: `gen pooledrr_gr9and11`.

**Q6 verification:** Second definition site at L71. Same name `pooledrr` in both files. Different semantic scope (grades 1-12 vs 9-12). The variable label differs: parent says "for grades 1-12" (L73), secondary says "for grades 9-12" (L72) — only the label distinguishes them. No suffix.

---

### 10. `caschls/do/build/buildanalysisdata/responserate/trimparentdemo.do` (89 lines)

**Q7 verification:** Pure projection/rename helper. No statistical trimming.

**Pattern repeated 5x (one per year, lines 13-85):**
1. `use parentdemo<year>.dta`
2. `keep cdscode svygr1..svygr12 gr1enr..gr12enr` — pure column subset (L18-19, 33-34, 47-48, 61-62, 75-76)
3. `foreach i of grades` rename `svygr<i>` → `svygr<i>_<year>` and `gr<i>enr` → `enrgr<i>_<year>` (L21-26, 35-40, 49-54, 63-68, 77-82)
4. `save trimparentdemo<year>.dta`

The word "trim" in the filename is misleading — it refers to column-trimming (variable subsetting), not statistical trimming (e.g., percentile removal). Confirmed round-1 finding.

---

### 11. `caschls/do/build/buildanalysisdata/responserate/trimsecdemo.do` (88 lines)

**Q7 verification:** Same pattern as `trimparentdemo.do`. Pure projection (`keep cdscode svygr9 svygr10 svygr11 svygr12 gr9enr gr10enr gr11enr gr12enr`, L19, 33, 46, 59, 72) + rename to `_<year>` suffix.

Restricts to grades 9-12 only (vs. parent which keeps 1-12). No statistical trimming.

---

### 12. `caschls/do/build/sample/elemcoveragedata.do` (136 lines)

**Purpose:** Compute response rates and demographic-coverage diagnostics for the elementary survey, in-place per year.

**Inputs:** `dta/demographics/elementary/elemdemo<year>` (L19) — output of `elemdemographics.do`.

**Outputs:** `dta/demographics/analysis/elementary/elemdemo<year>analysis` (L129).

**Logic per year:**
- L23-37: `gen svygr<i>resprate = .a` then `replace svygr<i>resprate = svygr<i>/gr<i>enr if gr<i>enr != 0` for i in {3, 4, 5, 6}. Uses extended-missing `.a` to flag "denominator zero" cases.
- L46-49: `label define ... .a "Grade <i> Enrollment is 0"`.
- L53-67: `svyfemalegr<i>pct = svyfemalegr<i>/svygr<i> if svygr<i>!=0` for i in {3-6}.
- L78-92: `svymalegr<i>pct = svymalegr<i>/svygr<i> if svygr<i>!=0`.
- L106-115: Enrollment-side counterparts: `enrfemalegr<j>pct`, `enrmalegr<j>pct` for j in {1-12}.
- L120-125: Differences: `femalegr<k>dif = svyfemalegr<k>pct - enrfemalegr<k>pct` and male equivalent for k in {3-6}.

**Note:** `.a` extended missing is used as a sentinel for "denominator zero" — pre-empts the divide-by-zero warning. Standard practice.

---

### 13. `caschls/do/build/sample/elemdemographics.do` (157 lines)

**Purpose:** Build elementary survey demographics + enrollment merge.

**Output:** `dta/demographics/elementary/elemdemo<year>` (L151).

**Sex coding (Q9 verification):**
- **Comment L67:** `// Note: in elementary datasets the var sex = 1 if female and 2 if male`
- **L69-70:** `gen byte female = 0; replace female = 1 if sex == 1`
- **L72-73:** `gen byte male = 0; replace male = 1 if sex == 2`

**Confirmed: elementary `sex == 1 → female`.** 

The variable `runelemrename = 0` at L19 means the renaming block (L20-56) is GATED OFF in the current run — i.e., the `sex` and `selfreportgrade` renames from raw `ele2/ele3/ele4` columns are pre-baked into the temp datasets `elem<year>temp.dta`, and the runtime path uses those temp files directly (L64). Note from L36, L43, L50 that for years 1617, 1718, 1819 the source is `ele2`; for 1415, 1516 it's `ele3`. (Schema divergence handled in the toggle-off block.)

**Demographics generation:**
- L76-103: Per-grade female and male indicators by interaction.
- L106: `collapse (sum) ...` aggregates to school level.
- L108-141: Rename `female`→`svyfemale`, `male`→`svymale`, `gr<i>`→`svygr<i>`, etc.
- L146: `merge 1:1 cdscode using enr<year>.dta` — merge with school enrollment.
- L147: `drop if _merge != 3` — keep only matched. Schools without enrollment data drop.

---

### 14. `caschls/do/build/sample/parentcoveragedata.do` (43 lines)

**Purpose:** Generate `svygr<i>resprate` response rates for parent survey across grades 1-12.

**Output:** `dta/demographics/analysis/parent/parentdemo<year>analysis` (L38).

**Logic:** Single foreach loop generates `svygr<i>resprate` for i in {1..12}, with `.a` extended-missing for "grade <i> enrollment is 0". Simpler than secondary version because parent survey doesn't have race or sex (per L23 of `pooledparentdemographics.do` "there is no sex or ethnicity in parent data").

---

### 15. `caschls/do/build/sample/parentdemographics.do` (123 lines)

**Purpose:** Build parent-demographics dataset (one observation per household = one child grade indicator).

**Output:** `dta/demographics/parent/parentdemo<year>.dta` (L117).

**Logic:**
- L13 comment: "parent1415 data do not have grade 7 observations. grade = -8 has 1327 observations which might be 7th grade, but cannot be sure" — known schema oddity.
- L22 toggle `runparentname = 0` — rename block (L23-63) is gated off; uses pre-baked temp files.
- L73-99: Generate `gr<i>` indicators for i in {k, 1..12} based on `childgr` value (1=K, 2=Gr1, ..., 13=Gr12).
- L101: `collapse (sum)` to school level.
- L104-107: Rename `gr<i>`→`svygr<i>`.
- L112: Merge with `enr<year>` school enrollment.

---

### 16. `caschls/do/build/sample/pooledparentdemographics.do` (44 lines)

**Purpose:** Reconstruct parent demographics for cross-year pooling (only grades 9 and 11).

**Inputs:** `parentdemo<year>.dta` (L22).
**Outputs:**
- `pooled/forpooling/parent/parentdemoforpooling<year>.dta` (L29) — per-year, restricted columns
- `pooled/paneldata/parentdemopanel.dta` (L41) — appended panel

**Logic:**
- L23: `keep cdscode svygr9 svygr11 gr9enr gr11enr` (and L23 comment "there is no sex or ethnicity in parent data")
- L24-25: `gen year = `year''` then `tostring year, replace`. (Stores as string.)
- L34-38: `append using parentdemoforpooling1415..1819`. Note 1415 is the master, then 1516..1819 appended.

---

### 17. `caschls/do/build/sample/pooledparentdiagnostics.do` (56 lines)

**Purpose:** Compute pooled (across years and grades 9+11) parent response rates.

**Input:** `pooled/paneldata/parentdemopanel.dta` (L13).
**Output:** `pooled/pooledparentdiagnostics.dta` (L52).

**Logic:**
- L21-22: `gen svytotal = svygr9 + svygr11` and `enrtotal = gr9enr + gr11enr` per row (per year).
- L26: `collapse (sum) svytotal enrtotal svygr9 svygr11 gr9enr gr11enr, by(cdscode)` — sum over 5 years per school.
- **L42: `gen pooledrr = svytotal/enrtotal`** — **POOLEDRR DEFINITION #3: Parent, grades 9 and 11 only, NOT conditional on year having response (just raw sum across all 5 years; if a school has zero responses in some year it just contributes 0 to numerator and full enrollment to denominator).** Crucially different from the parent-responserate version where the denominator is conditional on `has<year>==1`.
- L45: `pooledgr9rr = svygr9total/enrgr9total`.
- L47: `pooledgr11rr = svygr11total/enrgr11total`.

---

### 18. `caschls/do/build/sample/pooledsecdemographics.do` (53 lines)

**Purpose:** Reconstruct secondary demographics for cross-year pooling (only grades 9 and 11).

**Inputs:** `secdemo<year>.dta` (L22) — output of `secdemographics.do`.

**Outputs:**
- `pooled/forpooling/secondary/secdemoforpooling<year>.dta` (L36)
- `pooled/paneldata/secdemopanel.dta` (L48)

**Silent demographic recoding (Q-bug-list verified):**
```
L23: replace gr9asianenr = gr9asianenr + gr9filipinoenr
L24: replace gr11asianenr = gr11asianenr + gr11filipinoenr
```
Then L25-29 `keep cdscode svygr9 svygr11 svyfemalegr9 svyfemalegr11 svymalegr9 svymalegr11 svyhispanicgr9 svyhispanicgr11 svyasiangr9 svyasiangr11 svyblackgr9 svyblackgr11 svywhitegr9 svywhitegr11 gr9enr gr11enr gr9femaleenr gr9maleenr gr11femaleenr gr11maleenr gr9asianenr gr9hispanicenr gr9blackenr gr9whiteenr gr11asianenr gr11hispanicenr gr11blackenr gr11whiteenr` — note `gr9filipinoenr` and `gr11filipinoenr` are NOT in the keep list.

**This is a silent demographic merge:** Filipino enrollment is folded into Asian enrollment, and the Filipino column is dropped. No comment explains why. Downstream consumers see only `gr9asianenr` (which now means "Asian + Filipino combined") and `gr11asianenr` (likewise). 

**Note:** Survey-side `svyasiangr9` and `svyasiangr11` are NOT modified — these come from `secdemographics.do` where the `race==2` mapping is "Asian" (per `secdemographics.do:180` value label) and Filipino is not a separate race code (race codes 1-6 with no Filipino). So the survey-side Asian count includes self-reported Asians only (not self-reported Filipinos as a separate race), but the enrollment-side Asian denominator includes Filipino students.

**This is a bug:** Survey numerator and enrollment denominator now refer to slightly different populations. `pooledasianrr = svyasiantotal/enrasiantotal` (computed downstream in `pooledsecdiagnostics.do:83`) is therefore biased downward (denominator inflated by Filipinos who aren't in the numerator).

---

### 19. `caschls/do/build/sample/pooledsecdiagnostics.do` (99 lines)

**Purpose:** Compute pooled (5 years × grades 9+11) secondary survey response rates by demographic.

**Input:** `pooled/paneldata/secdemopanel.dta` (L13).
**Output:** `pooled/pooledsecdiagnostics.dta` (L94).

**Logic:**
- L21-35: `gen svy<demo>total` and `enr<demo>total` for each demographic (total, female, male, hispanic, asian, black, white).
- L38-39: `collapse (sum) ...` over years per school.
- **L65: `gen pooledrr = svytotal/enrtotal`** — **POOLEDRR DEFINITION #4: Secondary, grades 9 and 11 only, NOT conditional on year having response.** Mirror of parent-diagnostics version.
- L68-71: `pooledgr9rr`, `pooledgr11rr`.
- L74-90: Demographic-specific response rates: `pooledfemalerr`, `pooledmalerr`, `pooledhispanicrr`, `pooledasianrr`, `pooledblackrr`, `pooledwhiterr`.

**Q6 finding (TOTAL):** **Four distinct `pooledrr` definitions exist** in chunk-8 scope:
1. `parentresponserate.do:72` — parent, grades 1-12, conditional on `has<year>==1`
2. `secresponserate.do:71` — secondary, grades 9-12, conditional on `has<year>==1`
3. `pooledparentdiagnostics.do:42` — parent, grades 9 and 11, unconditional sum
4. `pooledsecdiagnostics.do:65` — secondary, grades 9 and 11, unconditional sum

All four save to different .dta files so on-disk collision is avoided. But anyone joining these datasets without renaming `pooledrr` first will silently overwrite. Round-1 reportedly found 2; round-2 finds 4. **ROUND-1-MISSED.**

---

### 20. `caschls/do/build/sample/responseyear.do` (92 lines)

**Purpose:** Generate `has<year><survey>` indicators for each (school, survey, year) tuple.

**Inputs:**
- `schooloverlap/schlfreqbyyear/parentschlfreq.dta` (L17)
- `secondaryschlfreq.dta` (L44)
- `staffschlfreq.dta` (L71)

**Outputs:**
- `responseyear/parentresponseyear.dta` (L37)
- `responseyear/secresponseyear.dta` (L64)
- `responseyear/staffresponseyear.dta` (L91)

**Logic:** Per survey: `keep cdscode has1415..has1819`, `label drop _all`, relabel as "appears in <year> <survey> survey", rename `has<year>` to `has<year><survey>` (suffix the survey type).

Trivial pure-rename file, no derivation logic.

---

### 21. `caschls/do/build/sample/seccoveragedata.do` (215 lines)

**Purpose:** Compute response rates + demographic coverage diagnostics for secondary survey (grades 6-12), per year.

**Input:** `secdemo<year>.dta` (L19).
**Output:** `analysis/secondary/secdemo<year>analysis.dta` (L209).

**Logic:**
- L21: `local secgrades 6 7 8 9 10 11 12` — note non-traditional ("nt") students excluded.
- L29-34: `svygr<i>resprate = svygr<i>/gr<i>enr if gr<i>enr!=0`.
- L39-44, 48-53: `svyfemalegr<i>pct`, `svymalegr<i>pct` (denominator is `svygr<i>`, the within-grade survey count).
- L58-111: Race-specific percentages for hispanic, native, asian, black, pacific, white, mixed.
- L124-178: Enrollment-side counterparts `enr<demo>gr<j>pct` for j in {1..12}.
- L185-205: Differences `<demo>gr<i>dif = svy<demo>gr<i>pct - enr<demo>gr<i>pct`.

---

### 22. `caschls/do/build/sample/secdemographics.do` (273 lines)

**Purpose:** Build secondary survey demographics + enrollment merge.

**Output:** `dta/demographics/secondary/secdemo<year>.dta` (L266).

**Sex coding (Q9 verification):**
- **Comment L102:** `// NOte: in secondary datasets the var sex equals 1 if male and 2 if female`
- **L103-104:** `gen byte female = 0; replace female = 1 if sex == 2`
- **L106-107:** `gen byte male = 0; replace male = 1 if sex == 1`

**Confirmed: secondary `sex == 1 → male`, `sex == 2 → female`.** Inverted from elementary (`elemdemographics.do:67-73` had `1 → female`). The recoding produces consistent `female`/`male` indicators, but the raw `sex` variable has different semantics across the two surveys. Anyone using raw `sex` downstream would conflate them. Safe-by-virtue-of-recoding-locally.

**Trans/nb/questioning gender (Q10 verification):**
- **Comment L59:** `/* note: sec1718 and 1819 also has a self reported gender variable, includes trans,nb, or questioning as an option */`
- **The comment is in the `runsecblock = 0` block (gated off, L21-84).** The current code path uses pre-baked temp files (`sec<year>temp.dta`) and only references `sex` (the binary M/F variable from `a3` or `a4`). The self-reported-gender variable from 1718/1819 is acknowledged but **not ingested**.
- The `gen byte female` / `gen byte male` logic (L103-107) only handles `sex==1` and `sex==2`. Trans/nb/questioning students who marked the self-reported variable but not the binary sex variable will be missing from both `female` and `male` indicators.

**Confirmed: round-1 finding holds.** The prompt's pointer to `secdemographics.do:59` is the comment; the actual recoding gap is at L103-107 where only binary sex codes are handled.

---

### 23. `caschls/do/share/demographics/elemcoverageanalysis.do` (55 lines)

**Purpose:** Generate histograms for elementary survey coverage (response rate, female/male diffs) per grade and year.

**Input:** `analysis/elementary/elemdemo<year>analysis.dta` (L31).

**Outputs:** `out/graph/svycoverage/elemcoverage/elem<year>/gr<j>resprate.png`, `gr<j>femaledif.png`, `gr<j>maledif.png` for j in {3, 4, 5, 6} (L38, 42, 44).

Uses `grstyle` package (L25-28) for plain background and `Set1` palette. Requires `grstyle`, `palettes`, `colrspace` (commented installs at L13).

---

### 24. `caschls/do/share/demographics/parentcoverageanalysis.do` (38 lines)

**Purpose:** Generate `svygr<i>resprate` histograms for parent survey, grades 1-12, per year.

**Input:** `analysis/parent/parentdemo<year>analysis.dta` (L24).

**Outputs:** `out/graph/svycoverage/parentcoverage/parent<year>/gr<i>resprate.png` (L30).

Simpler than secondary because parent survey has no race/sex breakdown.

---

### 25. `caschls/do/share/demographics/pooledsecanalysis.do` (65 lines)

**Purpose:** Generate histograms for pooled secondary diagnostics.

**Input:** `pooled/pooledsecdiagnostics.dta` (L13).

**Outputs:** `out/graph/pooleddiagnostics/secondary/pooled<demo>rr.png`.

**Silent data-quality drops at graph time (BUG CONFIRMED):**
```stata
L31: gen checkhispanic = 0
L32: replace checkhispanic = 1 if svyhispanictotal > enrhispanictotal
L33: gen checkasian = 0
L34: replace checkasian = 1 if svyasiantotal > enrasiantotal
L35: gen checkblack = 0
L36: replace checkblack = 1 if svyblacktotal > enrblacktotal
L37: gen checkwhite = 0
L38: replace checkwhite = 1 if svywhitetotal > enrwhitetotal

L40: drop if checkhispanic == 1
L41: drop if checkasian == 1
L42: drop if checkblack == 1
L43: drop if checkwhite == 1
```

**Issues:**
1. Drops are SEQUENTIAL on the in-memory dataset. Schools where any of the 4 race counts exceed enrollment are dropped — meaning the surviving sample is the intersection of "all 4 races sum-validity passes."
2. The drops occur AFTER the `pooledrr` (L21) and `pooledfemalerr` (L25) histograms, but BEFORE the race-specific histograms (L45-55). So `pooledrr` and `pooledfemalerr` see the full sample; `pooledhispanicrr` etc. see the post-filter sample.
3. **The drops are not propagated back to the on-disk dataset** — `pooledsecdiagnostics.dta` retains all schools. The drops only affect this one in-memory dataset for the histogram.
4. No diagnostic message is printed about how many schools were dropped.
5. The `>` filter (rather than `>=`) suggests the intent is to drop schools where there's a clear over-count (not equality).

This is a "silent data-quality drop at graph time" — the histograms in the paper/talk based on race-specific response rates are based on a different sample than the all-races version, and the user has no signal of this from looking at the graph file. **Confirms round-1 finding.**

---

### 26. `caschls/do/share/demographics/seccoverageanalysis.do` (61 lines)

**Purpose:** Generate per-year × per-grade histograms for secondary survey coverage (response rate, female/male diff, race diffs).

**Input:** `analysis/secondary/secdemo<year>analysis.dta` (L24).

**Outputs:** `out/graph/svycoverage/seccoverage/sec<year>/gr<i>/<measure>.png` for measures: `gr<i>resprate`, `femalegr<i>dif`, `malegr<i>dif`, `hispanicgr<i>dif`, `nativegr<i>dif`, `asiangr<i>dif`, `blackgr<i>dif`, `pacificgr<i>dif`, `whitegr<i>dif`, `mixedgr<i>dif` for i in {6, 7, 8, 9, 10, 11, 12} — total 70 histograms per year × 5 years = 350 .png files.

No data-quality filtering here; just histograms.

---

## Q1: Sample-restriction map (Paper Table A.1 ↔ code)

The cascade in the modern producer `do_files/share/sample_counts_tab.do` (and the upstream `touse_*` flag construction in `touse_va.do` + `create_va_sample.doh`) maps to the paper's 9 restrictions as follows:

| Row | Restriction | `sample_counts_tab.do` (Table A.1 producer) | `touse_va.do` enforcement | Other site |
|-----|------------|---------------------------------------------|----------------------------|------------|
| R1 | All g11 students | L88-91: `if grade==11 & all_students_sample==1` | L136 / L161: `mark touse_g11_<v> if grade==11 & dataset=="CAASPP" & inrange(year, …)` | `create_va_g11_sample_v1.doh:4`: `use if grade==11 & dataset=="CAASPP" & inrange(year, ...) using ...` |
| R2 | Grade-span ≥ 95% | L102: `& (diff_school_prop>=0.95 & !mi(diff_school_prop))` | L138 / L162: `& diff_school_prop>=0.95` (inside markout block); `diff_school_prop` constructed via `create_diff_school_prop.doh` (`gr11_L3_…` for non-2017, `gr11_L4_…` for 2017) | `create_va_g11_sample_v1.doh:7`: `keep if diff_school_prop>=0.95` |
| R3 | First scores | L119: `& first_scores_sample==1` | L138 / L163: `& first_scores_sample==1` | — |
| R4 | Conventional schools | L134-135: `& mi_ssid_grade_year_school==0 & conventional_school==1` | L102: `replace touse = 0 if conventional_school!=1` | `create_va_sample.doh:48-49`: `merge ... keepusing(conventional_school) keep(1 3); keep if conventional_school==1` |
| R5 | Cohort size > 10 | L154: `& (cohort_size>10 & !mi(cohort_size))` | L109: `replace touse = 0 if cohort_size<=10` | `create_va_sample.doh:54`: `drop if cohort_size<=10` |
| R6 | Non-missing test | L175: `& mi_sbac_<subject>_z_score==0` | L139-148 / L164-173: `markout touse_g11_<v> sbac_<subject>_z_score ...` | — |
| R7 | Non-missing demographics | L198: `& mi_demographic_controls==0` | `markout` block enforces against `demographic_controls` macro (defined in `macros_va.doh`) | — |
| R8 | Non-missing prior scores | L224-225: `& mi_prior_ela_z_score==0 & mi_prior_math_z_score==0` | `markout` block enforces against `ela_score_controls` and `math_score_controls` macros | `create_prior_scores.doh` (helper) |
| R9 | School VA cell N >= 7 | L256: `& (n_g11_<subject>>=7 & !mi(n_g11_<subject>))` | L152-155 / L177-180: `egen n_g11_<v> = count(state_student_id) if touse_g11_<v>==1, by(cdscode year)` then `replace touse_g11_<v>=0 if n_g11_<v><7` | — |

**Discrepancy (Q1):** The cascade in the producer enforces the restrictions in order (R1 → R2 → R3 → R4 → R5 → R6 → R7 → R8 → R9), so each row of Table A.1 shows the cumulative student count after that restriction. In `touse_va.do`, R4 and R5 are enforced via `replace touse=0` BEFORE R1-R3, and R6/R7/R8 are enforced via `markout` AFTER. So the order of enforcement differs from the table cascade order, but the conjunction is the same. Result: same sample, different code paths.

---

## Q2: `<7` vs `<=10` cohort cuts

**Both cuts coexist and operate at different levels — they are NOT redundant.**

**Cut A — Cohort size > 10 (R5):**
- Variable: `cohort_size` (constructed upstream of chunk-8 in `k12_test_scores_clean.dta`; per `create_va_sample.doh:51` definition, it's a school-level cohort metric).
- Level: school × year (one value of `cohort_size` per school×year row in test-scores data).
- Cut sites:
  - `touse_va.do:109` — `replace touse = 0 if cohort_size<=10`
  - `create_va_sample.doh:54` — `drop if cohort_size<=10`
  - `sample_counts_tab.do:154` — `& (cohort_size>10 & !mi(cohort_size))`
- Semantic: drop schools whose total g11 cohort is <=10 students.

**Cut B — N >= 7 (R9):**
- Variable: `n_g11_<subject>` (computed locally by egen).
- Level: school × year × subject (count of students passing all prior restrictions in the touse, by cdscode-year).
- Cut sites:
  - `touse_va.do:152-155` (test scores): `egen n_g11_<subject> = count(state_student_id) if touse_g11_<subject>==1, by(cdscode year); replace touse_g11_<subject>=0 if n_g11_<subject><7`
  - `touse_va.do:177-180` (outcomes): same pattern
  - `sample_counts_tab.do:256`: `& (n_g11_<subject>>=7 & !mi(n_g11_<subject>))`
- Semantic: after all other restrictions, drop school×year×subject cells with fewer than 7 valid student observations. This is the school-VA cell size constraint.

**Why both:** The cohort cut filters out small-school cohorts BEFORE the markout, ensuring that even pre-VA the school is large enough; the N>=7 cut filters out school-year-subject cells that are too small for stable VA estimation AFTER all the missing-data restrictions are applied. Both are necessary.

---

## Q3: `gr11enr_mean` weight chain

- **Generated:** `dta/enrollment/schoollevel/poolgr11enr.dta` — outside chunk-8 scope (chunk-7 enrollment build).
- **Merged:** `mergegr11enr.do` for all 3 surveys:
  - L15: parent — `merge 1:1 cdscode using poolgr11enr, keepusing(gr11enr_mean)`
  - L25: secondary — same
  - L35: staff — same
- **Saved:** in-place save for parent (L19) and secondary (L29); new file save for staff (`staffanalysisready.dta`, L39) since staff didn't have an analysisready before this step.
- **Consumed:** as `[aweight=gr11enr_mean]` in chunk-9 share/ files (analysis/regression files producing the survey-VA results in the paper). Not visible in chunk-8 scope but referenced by the chain.

---

## Q4: Survey pooling logic

**Pattern (verified in parentpooling.do, secpooling.do, staffpooling.do):**

1. **Append 5 years (chronologically reverse: 1819 first, then 1718 → 1617 → 1516 → 1415).** This places newest-first in the panel.
2. **Drop missing cdscode.**
3. **`wtmean(qoi<i>mean), weight(nettotalresp<i>)` by cdscode** — produces `qoi<i>mean_pooled`. The pooling weight is `nettotalresp<i>` (per-qoi, per-year, per-school count of net responses). This means each year contributes proportionally to its actual response volume. Years with `nettotalresp<i>=0` or missing contribute nothing (Stata `wtmean` skips missings naturally).
4. **`wtmean(pctagree<i>), weight(nettotalresp<i>)` etc.** — same pattern for pct-aggregated vars.
5. **`collapse (mean) *pooled (sum) nettotalresp* missing* …`** — collapse to one row per cdscode. The `(mean)` operation on the wtmean outputs is a no-op for the pooled vars (already constant per cdscode); the `(sum)` operation aggregates the raw counts.
6. **Save pooledstats.**
7. **Merge response rate dataset (parentresponserate / secresponserate) by cdscode.** (No staff response rate, per `staffpooling.do:80`.)
8. **Save analysisready.**

**Pooling weight (final answer):** `nettotalresp<i>` — the per-qoi, per-school, per-year net response count. This is computed in chunk-6 (`<survey>qoiclean<year>` files).

---

## Q5: Schema divergence handling

- **Parent 1415 missing qoi 64:** `parentpooling.do:31` includes 64 in the `numlist 9 15/17 27 30/34 64`. The `wtmean` function ignores missings, and 1415's `qoi64mean` is missing → contributes nothing to the wtmean for 1415's portion. The pooled `qoi64mean_pooled` for a 5-year school is the wtmean over the 4 years that DID have qoi64. The `nettotalresp64` from 1415 is also missing/zero → not contributing weight. **Handled implicitly via Stata's missing-skip semantics in `wtmean`.**
- **Staff 1718/1819 missing `pctnotapp`:** Not directly visible in `staffpooling.do`. The `pctnotapp` variable is not part of the variable list in the `collapse` at L51 (which keeps only `*pooled`, `nettotalresp*`, `missing*`). If `pctnotapp` exists in some years' `staffqoiclean<year>` files but not 1718/1819, it would never be aggregated here. The schema divergence is fully upstream (chunk-6 cleaning code).

---

## Q6: `pooledrr` definitions (4, not 2)

**Round-1 reportedly claimed two parallel definitions; round-2 finds FOUR.**

| # | File | Line | Scope | Conditional? |
|---|------|------|-------|--------------|
| 1 | `parentresponserate.do` | 72 | Parent, grades 1-12 | Yes (`has<year>==1`) |
| 2 | `secresponserate.do` | 71 | Secondary, grades 9-12 | Yes (`has<year>==1`) |
| 3 | `pooledparentdiagnostics.do` | 42 | Parent, grades 9 and 11 only | No (raw sum) |
| 4 | `pooledsecdiagnostics.do` | 65 | Secondary, grades 9 and 11 only | No (raw sum) |

All four are saved to different .dta files so on-disk collision is avoided. But anyone joining these datasets (or reading code that mentions `pooledrr` without context) faces a 4-way semantic ambiguity. The variable label is the only signal.

**ROUND-1-MISSED:** definitions #3 and #4 in the diagnostics files were apparently not enumerated in round-1.

---

## Q7: `trimparentdemo.do` / `trimsecdemo.do` semantics

**Confirmed: pure projection/rename helpers, NOT statistical trimming.**

Both files do exactly:
1. `use <survey>demo<year>.dta`
2. `keep cdscode <subset of svygr* and gr*enr columns>`
3. Rename `svygr<i>` → `svygr<i>_<year>` and `gr<i>enr` → `enrgr<i>_<year>`
4. `save trim<survey>demo<year>.dta`

Repeated 5x (one per year). The "trim" terminology refers to column-trimming (variable subsetting) plus a year-suffix rename to enable wide-to-wide cross-year merge. There is no trimming of observations, no winsorization, no percentile filter — nothing statistical.

Round-1 finding fully confirmed.

---

## Q8: Paper Table A.1 producer

**Modern producer: `do_files/share/sample_counts_tab.do`** (in the `cde_va_project_fork` repo).
- Outputs `tables/share/va/pub/counts_k12.tex` at L615.
- Wired in `do_files/do_all.do:226` under `local do_share_tables`.
- Computes 9-row cumulative cascade matching paper restrictions R1-R9 (plus extra rows 10-12 for leave-out-score / sibling / ACS extensions, which are paper Table A.2 or beyond).

**Archived legacy: `do_files/_archive/matt_original/sum_stats.do`** (also in fork).
- Produces estimates files with the same `counts_k12_*` naming convention (per L223-445, L617- of that file).
- **NOT wired into `do_all.do`** — the only mention in `do_all.do` is the modern `sample_counts_tab.do` path.
- The path token `_archive/matt_original/` suggests this is the original Matt Naven version that was superseded when Christina Sun re-implemented the cascade.

**Verdict:** Modern producer is `do_files/share/sample_counts_tab.do`. The legacy `sum_stats.do` is dead code per `do_all.do` toggles. Round-1 may have pointed at `_archive/matt_original/sum_stats.do` — that is incorrect; the active producer is `share/sample_counts_tab.do`. (This is consistent with the prompt's pre-statement that the modern producer was independently verified.)

Confirming evidence:
- `cde_va_project_fork/.gitignore:287` whitelists `tables/sbac/counts_k12.tex` (the on-disk artifact).
- `cde_va_project_fork/paper/common_core_va.tex:163` includes `\inputfragment{../tables/sbac/counts_k12.tex}` (the paper consumer).
- The legacy `sum_stats.do` outputs to `estimates/sbac/counts_k12_*.ster` (not `tables/sbac/counts_k12.tex`).
- The modern `sample_counts_tab.do` outputs to `estimates/va_cfr_all_v1/sum_stats/counts_k12_*.ster` AND to `tables/share/va/pub/counts_k12.tex`.

The paper consumer is `paper/common_core_va.tex:163` reading from `tables/sbac/counts_k12.tex`, but the modern producer outputs to `tables/share/va/pub/counts_k12.tex`. **There may be a path mismatch here** — either the paper has been moved, or the producer's output path needs to be aligned with the paper's input path. This is worth a follow-up by Christina but is downstream of chunk-8.

---

## Q9: Sex coding inversion

**Confirmed.**

| File | Comment line | Recoding lines | Sex == 1 → ? | Sex == 2 → ? |
|------|--------------|----------------|--------------|--------------|
| `elemdemographics.do` | L67: "in elementary datasets the var sex = 1 if female and 2 if male" | L69-70, 72-73 | female | male |
| `secdemographics.do` | L102: "in secondary datasets the var sex equals 1 if male and 2 if female" | L103-104, 106-107 | male | female |

The semantics of raw `sex` is opposite. Each file recodes locally into binary `female`/`male` indicators, so downstream consumers using `female` and `male` (rather than raw `sex`) get consistent values. Anyone using raw `sex` would conflate them. Safe in current pipeline; fragile if future code refactors expose `sex`.

---

## Q10: Trans/nb/questioning gender

**Confirmed missing in code.**

- `secdemographics.do:59` comment: `/* note: sec1718 and 1819 also has a self reported gender variable, includes trans,nb, or questioning as an option */`
- Comment is inside the `if runsecblock == 1` block (L21-84), which is gated OFF (`runsecblock = 0` at L21).
- Active code path uses pre-baked temp files `sec<year>temp.dta` (L98) and only references `sex` (binary variable, L102). The self-reported-gender variable from 1718/1819 is not ingested.
- Logic at L103-107 only handles `sex==1` and `sex==2`. Trans/nb/questioning students who marked the self-reported-gender variable but selected non-binary sex (or skipped the binary sex question) will be missing from both `female` and `male` indicators. They will still be counted in `svygrnt` (non-traditional) only if they coded grade=13.

**Round-1 finding confirmed.**

---

## Q11: Paper-mentioned but not-implemented restrictions

**Confirmed.**

- `touse_va.do:104` comment: `* Exclude schools where more than 25 percent of students are receiving special education services` — no corresponding code.
- `touse_va.do:106` comment: `* Drop if a student is receiving instruction at home, in a hospital, or in a school serving disabled students solely` — no corresponding code.
- `create_va_sample.doh` (helper used by `create_score_samples.do` and `create_out_samples.do`) has the same two comment-stubs (lines visible in earlier read-through, between the conventional-school keep and the cohort-size drop). Same lack of implementation.

If the paper claims these restrictions are applied, the paper text and code do not match. Worth a follow-up: (a) check whether the >25% special-ed and home/hospital filters are implemented at an earlier upstream step (in `k12_test_scores_clean.dta` construction or in `k12_public_schools_clean.dta`); (b) if not, the paper text should be revised or the code should be extended.

**Round-1 finding confirmed.**

---

## Q12: `enr_ontime → enr` rename

**Confirmed at TWO sites:**
- `touse_va.do:117`: `rename enr_ontime enr` (after `drop enr enr_2year enr_4year` at L116)
- `create_out_samples.do:71`: `rename enr_ontime enr` (after `drop enr enr_2year enr_4year` at L70)

**Impact characterization:**
- `merge_k12_postsecondary.doh enr_only` brings in BOTH `enr` (ever-enrolled) AND `enr_ontime` (enrolled within 6 months of HS graduation).
- The drop+rename overwrites `enr` with `enr_ontime` semantics.
- All downstream regressions in `out_*.dta` files use the variable named `enr`, but the actual values are `enr_ontime`. The "ever-enrolled" `enr` is gone.
- This is destructive: the original `enr` is deleted, not preserved under another name.

**Why this matters:** If the paper claims to study postsecondary enrollment without specifying "on-time," but the code only computes on-time enrollment, there is a paper-code mismatch on the headline outcome. A reader looking at `out_b.dta` would see `enr` and assume ever-enrolled — wrong by silent rename.

---

## Q13: Silent dead-code (egen never saved)

**Confirmed at TWO sites:**

- **`create_score_samples.do:240-247`:** `egen n_g11_<subject>_<sample>_sp = count(...) if touse_g11_<subject>==1, by(cdscode year)` — inner loop opens each `score_<sample>.dta`, computes the var, then the next iteration opens the next file (overwriting in-memory). NO `save, replace` after the egen. The variable evaporates.

- **`create_out_samples.do:225-232`:** Same pattern for outcomes — `egen n_g11_<outcome>_<sample>_sp = ...` with no save.

**Impact:**
- Per the CHANGE LOG (`create_score_samples.do:28-31`): "naming convention: n_g11_outcome_sample_sp ... for use in weighting in scatter plots."
- The `_sp` suffix indicates "scatter plot" — these variables were intended to be the per-VA-cell sample size used for weighting symbols in the VA scatter plots.
- Since they're never saved, any chunk-9 scatter plot file using `n_g11_<outcome>_<sample>_sp` weights will fail (variable not found) OR will fall back to whichever variable is loaded with that name from elsewhere.
- More likely: the scatter plots use the bare `n_g11_<subject>` (without the `_<sample>_sp` suffix) saved by `touse_va.do:152` — which is the SAME for all sample arms, defeating the purpose of the dead loop.

**Round-1 finding confirmed.**

---

## Bug summary table

| # | Bug type | Location | Severity | Notes |
|---|----------|----------|----------|-------|
| B1 | Four `pooledrr` definitions, same name, different semantics | parentresponserate.do:72; secresponserate.do:71; pooledparentdiagnostics.do:42; pooledsecdiagnostics.do:65 | High | Variable-name overload across 4 files. Collision avoided only by separate .dta storage. |
| B2 | Sex-coding inversion across surveys | elemdemographics.do:67; secdemographics.do:102 | Low (handled locally by recoding into `female`/`male`) | Raw `sex` has different semantics; downstream code must use derived indicators. |
| B3 | Silent demographic recoding (Filipino → Asian) | pooledsecdemographics.do:23-24 | High | `pooledasianrr` denominator inflated; numerator unchanged; biased downward. |
| B4 | Silent data-quality drops at graph time | pooledsecanalysis.do:31-43 | Medium | Race-specific histograms see different sample than overall histograms; no diagnostic message. |
| B5 | In-place destructive saves | mergegr11enr.do:19, 29 | Low (idiomatic) | `save, replace` overwrites parentanalysisready and secanalysisready in place. |
| B6 | Comments describe restrictions not in code | touse_va.do:104, 106; create_va_sample.doh (mirror) | Medium | >25% special ed and home/hospital filters mentioned but not implemented. |
| B7 | Dead-code n_g11_<v>_<sample>_sp computations never saved | create_score_samples.do:240-247; create_out_samples.do:225-232 | Medium | Intended scatter-plot weights silently lost. |
| B8 | Trans/nb/questioning gender from sec1718/1819 not handled | secdemographics.do:103-107 (logic) ; L59 (comment) | Medium | Self-reported-gender variable acknowledged in comment but not ingested. |
| B9 | `enr_ontime → enr` silent rename | touse_va.do:117; create_out_samples.do:71 | High | Original `enr` (ever-enrolled) destroyed; downstream code that says `enr` actually uses on-time variant. |

---

## Notes on cross-references

- The path `tables/sbac/counts_k12.tex` referenced by `paper/common_core_va.tex:163` differs from the producer output `tables/share/va/pub/counts_k12.tex` (`sample_counts_tab.do:615`). Either the paper's input path or the producer's output path is wrong, or there's a copy step elsewhere. Worth verifying with a `find` for the actual file.
- Variables `gr<i>enr`, `gr<i>femaleenr`, `gr<i>maleenr`, `gr<i><race>enr` referenced in chunk-8 files are merged in from `dta/enrollment/schoollevel/enr<year>.dta` (`elemdemographics.do:146`, `parentdemographics.do:112`, `secdemographics.do:261`). The construction of these enrollment-side counts is in chunk-7 / enrollment build.
- The `va_control_vars`, `peer_demographic_controls`, `school_controls`, `demographic_controls`, `ela_score_controls`, `math_score_controls`, `peer_ela_score_controls`, `peer_math_score_controls` macros are defined in `do_files/sbac/macros_va.doh` (chunk-7 / specifications).

---

## Verification methodology

For each file, the audit:
1. Read the entire file (lines 1 through end-of-file).
2. Cited specific line numbers for each finding.
3. Cross-referenced helper `.doh` includes when the main file delegated logic to a helper.
4. Cross-referenced the paper Table A.1 producer's cascade against the touse_va.do enforcement to identify level-of-cut and ordering differences.
5. Did NOT read any round-1 documents.
6. Did NOT trust any received summary; defaulted to primary source.

Findings that contradict or extend the prompt's framing of the round-1 claims (e.g., "two `pooledrr` definitions" → in fact four; "sum_stats.do" → in fact `sample_counts_tab.do`) are flagged as ROUND-1-MISSED or potential-misframings for the discrepancy report.
