# Chunk-2 Verified Audit: VA-Core Helpers

**Date:** 2026-04-24
**Scope:** SBAC sample-construction `.doh` helpers, `merge_k12_postsecondary.doh`, and `caschls/do/share/siblingvaregs/*.doh`.
**Method:** Independent blind verification, line-by-line read of primary sources. The previous audit at `quality_reports/audits/round-1/` was sequestered (not consulted).

---

## 0. File Inventory (vs. assignment list)

The assignment listed 9 files plus an instruction to enumerate any extras under `cde_va_project_fork/do_files/sbac/*.doh` and `caschls/do/share/siblingvaregs/*.doh`.

**Files explicitly named in the assignment (all present and audited):**

1. `cde_va_project_fork/do_files/sbac/create_va_sample.doh` (57 lines)
2. `cde_va_project_fork/do_files/sbac/create_va_g11_sample.doh` (15 lines)
3. `cde_va_project_fork/do_files/sbac/create_va_g11_out_sample.doh` (15 lines)
4. `cde_va_project_fork/do_files/sbac/create_diff_school_prop.doh` (2 lines)
5. `cde_va_project_fork/do_files/sbac/create_prior_scores_v1.doh` (28 lines incl. trailing newline)
6. `cde_va_project_fork/do_files/sbac/create_prior_scores_v2.doh` (32 lines)
7. `cde_va_project_fork/do_files/merge_k12_postsecondary.doh` (480 lines)
8. `caschls/do/share/siblingvaregs/vafilemacros.doh` (24 lines)
9. `caschls/do/share/siblingvaregs/vaestmacros.doh` (160 lines)

**Files mentioned in the assignment's "plus list" (all present and audited):**

10. `cde_va_project_fork/do_files/sbac/create_va_g11_sample_v1.doh` (15 lines)
11. `cde_va_project_fork/do_files/sbac/create_va_g11_sample_v2.doh` (15 lines)
12. `cde_va_project_fork/do_files/sbac/create_va_g11_out_sample_v1.doh` (15 lines)
13. `cde_va_project_fork/do_files/sbac/create_va_g11_out_sample_v2.doh` (15 lines)
14. `cde_va_project_fork/do_files/sbac/merge_lag2_ela.doh` (29 lines)
15. `cde_va_project_fork/do_files/sbac/merge_loscore.doh` (33 lines)
16. `cde_va_project_fork/do_files/sbac/merge_sib.doh` (18 lines)
17. `cde_va_project_fork/do_files/sbac/merge_va_smp_acs.doh` (123 lines)
18. `cde_va_project_fork/do_files/sbac/macros_va_all_samples_controls.doh` (143 lines)
19. `cde_va_project_fork/do_files/sbac/drift_limit.doh` (4 lines)
20. `cde_va_project_fork/do_files/sbac/out_drift_limit.doh` (2 lines)

**Additional `.doh` file found in `cde_va_project_fork/do_files/sbac/` not in the assignment list (extras, audited briefly):**

21. `cde_va_project_fork/do_files/sbac/macros_va.doh` (612 lines) — **referenced repeatedly as "macros_va.doh" in the assignment's Q2** but never explicitly listed; it is in scope by reference. Audited as a chunk-2 file because chunk-2 helpers reference its macros pervasively.

**No additional `.doh` files in `caschls/do/share/siblingvaregs/`** — only the two listed.

(Note: `cde_va_project_fork/do_files/append_k12_all_data.doh`, 6491 bytes, exists at the parent `do_files/` directory level alongside `merge_k12_postsecondary.doh`. Per the assignment scope this is **not** in chunk 2 and was not audited.)

---

## 1. Per-File Entries

### File: `cde_va_project_fork/do_files/sbac/create_va_sample.doh`

**Predecessor repo:** cde_va_project_fork
**Owner:** unknown (no explicit attribution in file header)
**Lines:** 57
**Purpose:** Builds the **all-grades VA dataset** by reading cleaned k12 test scores, merging on `touse_*` indicators (from a previously-built `va_samples.dta`), then merging lagged peer scores, school-grade-span proportions, median cohort sizes, and a "conventional schools" filter. This is the upstream starting point for `create_va_g11_sample.doh` and family.

**Macros defined:** None (this file *uses* macros set elsewhere, e.g. `va_control_vars`, `peer_demographic_controls`, `k12_test_scores`, `k12_test_scores_public`, `k12_public_schools`).

**Variables created/transformed:**

- (no `gen`/`replace` of analysis variables — the file's `gen` calls produce only merge-flag variables `merge_grade_span` (line 41), `merge_cohort_size` (line 45), `merge_public_schools` (line 49))

**Inputs (datasets `use`'d):**

- `` `k12_test_scores'/k12_test_scores_clean.dta `` (line 8) — base data
- `data/sbac/va_samples.dta` (line 9) — `touse_*` indicators
- `` `k12_test_scores'/k12_lag_test_scores_clean.dta `` (line 13) — lagged scores
- `` `k12_test_scores'/k12_peer_test_scores_clean.dta `` (line 26) — peer scores
- `` `k12_test_scores_public'/k12_diff_school_prop_schyr.dta `` (line 40)
- `` `k12_test_scores_public'/k12_cohort_size_sch.dta `` (line 44)
- `` `k12_public_schools'/k12_public_schools_clean.dta `` (line 48)

**Outputs (datasets `save`'d):** None — leaves data in memory.

**Sourced helpers:** None (no `include`).

**Path references that need updating in consolidation:**

- `` `k12_test_scores' `` (`$vaprojdir/data/restricted_access/clean/k12_test_scores`)
- `` `k12_test_scores_public' `` (`$vaprojdir/data/public_access/clean/k12_test_scores`)
- `` `k12_public_schools' `` (`$vaprojdir/data/public_access/clean/k12_public_schools`)
- `data/sbac/va_samples.dta` — relative path; depends on PWD at call time

**Stata version / non-trivial syntax:** `use varlist if cond using fname, clear` (line 2-8) is a select-on-use pattern; no `version`, no `#delimit ;` block.

**ssc/community packages used:** None directly.

**Gotchas / non-obvious behavior:**

- Line 7: `/*if substr(cdscode, 1, 7)=="3768338"*/` — a commented-out single-school filter, kept in source. Not a bug, but a developer-test residue.
- Line 41: `keepusing(gr11_*_diff_school_prop)` — wildcard merge; downstream `create_diff_school_prop.doh` references `gr11_L3_diff_school_prop` and `gr11_L4_diff_school_prop` specifically. If those wildcards do not match in the merge file, downstream references will fail silently.
- Line 50: `keep if conventional_school==1` — drops any merge_public_schools=1 (master-only) rows because `conventional_school` will be `.` for them. This is the correct intended behavior for filtering to conventional schools, but means the `keep(1 3)` on line 49 is redundant.
- Line 57: `drop if cohort_size<=10` — applies to per-school per-year cohort size. **Maps to Online Appendix Table A.1 row 5 ("Drop schools with <=10 11th-graders/year")** in the paper map.
- Lines 52-54: comment block describing two restrictions (more than 25% special-ed, and home-instruction/hospital-school) that are **NOT actually implemented in code** — only described in comments. **This is a "comments describe restrictions not in code" anomaly.**

**Reference to paper outputs:** Upstream of every paper artifact — feeds `va_g11_dataset` -> `va_g11_*_v1.dta` -> Tables 2-3 (validity), 4-7, all Figures 1-6.

**Notes / open questions:**

- Line 13 merge does not have an explicit `keep(1 3)` mate to the `keepusing(...)` lagged-score variables — actually it does (line 13). OK.

---

### File: `cde_va_project_fork/do_files/sbac/create_va_g11_sample.doh`

**Predecessor repo:** cde_va_project_fork
**Owner:** unknown
**Lines:** 15
**Purpose:** Restricts the all-grades VA dataset to grade 11, CAASPP, valid year range, applies the diff-school-prop >= 0.95 filter, generates v1 prior scores, and saves to a tempfile `va_g11_dataset`.

**Macros defined:** `local drift_limit = max(\`test_score_max_year' - \`test_score_min_year' - 1, 1)` (line 3).

**Variables created/transformed:** None directly; via `include`d files.

**Inputs:** `` `va_dataset' `` (line 4) — the on-disk VA dataset.

**Outputs:** `tempfile va_g11_dataset` saved at line 15.

**Sourced helpers:**

- `do_files/sbac/create_diff_school_prop.doh` (line 6)
- `do_files/sbac/create_prior_scores_v1.doh` (line 9)

**Path references that need updating in consolidation:**

- `` `va_dataset' `` — set in `vafilemacros.doh` line 18 to `$projdir/dta/common_core_va/va_dataset`
- `do_files/sbac/...` — relative path expressions assuming PWD = `$vaprojdir`

**Stata version / non-trivial syntax:** `use if ... using fname, clear` (line 4) — select-on-use.

**ssc/community packages used:** None directly.

**Gotchas:**

- Line 1 comment says "version 1 of VA samples" — and **uses `create_prior_scores_v1.doh`** (line 9). The base `create_va_g11_sample.doh` and `create_va_g11_sample_v1.doh` (file 10) are **identical line-for-line** (verified: 15 lines each, same contents). This is duplication, not a bug.
- Line 3: `drift_limit` is set as a `local` here (file scope) but is also set in `drift_limit.doh` and `out_drift_limit.doh` as separate locals. Naming overlap.

**Reference to paper outputs:** Upstream of all 11th-grade VA estimates (Tables 2-7; Figures 1-6).

**Notes:** `keep if diff_school_prop>=0.95` (line 7) is the **"95% from same school"** filter — restricts to students whose 11th-grade peers are at least 95% from the same school. **Maps to a sample restriction not explicitly enumerated in Table A.1 of the paper map**, between rows 4 and 5.

---

### File: `cde_va_project_fork/do_files/sbac/create_va_g11_out_sample.doh`

**Predecessor repo:** cde_va_project_fork
**Owner:** unknown
**Lines:** 15
**Purpose:** Same as `create_va_g11_sample.doh` but for the **outcome VA** (postsecondary outcome) sample: uses `outcome_min_year` / `outcome_max_year` instead of `test_score_min_year`/`test_score_max_year`.

**Macros defined:** `local drift_limit = max(\`outcome_max_year' - \`outcome_min_year' - 1, 1)` (line 3).

**Variables created/transformed:** Via includes only.

**Inputs:** `` `va_dataset' `` (line 4).

**Outputs:** `tempfile va_g11_dataset` (line 15).

**Sourced helpers:**

- `do_files/sbac/create_diff_school_prop.doh` (line 6)
- `do_files/sbac/create_prior_scores_v1.doh` (line 9)

**Path references that need updating:** Same as `create_va_g11_sample.doh`.

**Gotchas:**

- **Tempfile name collision:** Line 15 saves to `tempfile va_g11_dataset` — **the same name as the test-score sample tempfile** (`create_va_g11_sample.doh` line 15). Because tempfiles are `local` macros, this only matters if both helpers run in the same Stata invocation; if they do, the second call overwrites the first.
- File is named `..._out_sample` but the saved tempfile is `va_g11_dataset` not `va_g11_out_dataset`. The `vafilemacros.doh` (line 20) declares `va_g11_out_dataset` exists separately on disk; the tempfile naming here does **not** mirror that. **Source of confusion: the tempfile name does not encode "outcome" / "out".**

**Reference to paper outputs:** Upstream of all postsecondary-enrollment VA estimates (Table 3; enrollment panels of Figures 1-4; Figure 5-6 outcome-side; Online Appendix C).

---

### File: `cde_va_project_fork/do_files/sbac/create_diff_school_prop.doh`

**Predecessor repo:** cde_va_project_fork
**Owner:** unknown
**Lines:** 2
**Purpose:** Constructs `diff_school_prop`, the proportion of an 11th grader's prior-period peers who attended a **different** school. Selects between L3 (3-years-prior) and L4 (4-years-prior) lag based on cohort year.

**Macros defined:** None.

**Variables created/transformed:**

- `gen diff_school_prop = gr11_L3_diff_school_prop if year!=2017` (line 1)
- `replace diff_school_prop = gr11_L4_diff_school_prop if year==2017` (line 2)

**Inputs:** None directly — uses already-merged variables `gr11_L3_diff_school_prop` and `gr11_L4_diff_school_prop` from `create_va_sample.doh` line 41.

**Outputs:** None.

**Sourced helpers:** None.

**Path references:** None.

**Stata version / non-trivial syntax:** None.

**ssc/community packages used:** None.

**Gotchas:**

- The L3 vs. L4 switch handles the **2014 SBAC test-skip year** (California did not administer SBAC tests in spring 2014; 2017 cohort needs to look back 4 years not 3). **Critical to document for consolidation — without this branch the 2017 cohort gets a missing or wrong prior-period peer composition.**
- Comment from comments only — no inline justification of the L3/L4 split. Future reader needs to know the 2014 testing-skip context.

**Reference to paper outputs:** Feeds the `keep if diff_school_prop>=0.95` filter in every grade-11 sample (test-score and outcome). All paper artifacts depend on this filter.

---

### File: `cde_va_project_fork/do_files/sbac/create_prior_scores_v1.doh`

**Predecessor repo:** cde_va_project_fork
**Owner:** Christina Sun (per file header line 5)
**Lines:** 27 (28 with trailing newline)
**Purpose:** Constructs `prior_ela_z_score`, `prior_math_z_score`, and their peer averages **under v1 specification**: different prior-score grades for ELA vs. math, with per-cohort grade choices.

**Macros defined:** None.

**Variables created/transformed:**

- `gen prior_ela_z_score = L3_cst_ela_z_score if inrange(year, \`star_min_year' + 3, \`star_max_year' + 3) & year!=2017` (line 12)
- `replace prior_ela_z_score = L3_sbac_ela_z_score if inrange(year, \`caaspp_min_year' + 3, \`caaspp_max_year' + 3) & year!=2017` (line 13)
- `replace prior_ela_z_score = L4_cst_ela_z_score if year==2017` (line 14)
- `label var prior_ela_z_score "Prior ELA Z-Score"` (line 15)
- `gen peer_prior_ela_z_score = peer_L3_cst_ela_z_score if inrange(year, \`star_min_year' + 3, \`star_max_year' + 3) & year!=2017` (line 16)
- `replace peer_prior_ela_z_score = peer_L3_sbac_ela_z_score if inrange(year, \`caaspp_min_year' + 3, \`caaspp_max_year' + 3) & year!=2017` (line 17)
- `replace peer_prior_ela_z_score = peer_L4_cst_ela_z_score if year==2017` (line 18)
- `label var peer_prior_ela_z_score "Peer Avg. Prior ELA Z-Score"` (line 19)
- `gen prior_math_z_score = L5_cst_math_z_score if inrange(year, \`star_min_year' + 5, \`star_max_year' + 5) & !inrange(year, \`caaspp_min_year' + 3, \`caaspp_max_year' + 3)` (line 22)
- `replace prior_math_z_score = L3_sbac_math_z_score if inrange(year, \`caaspp_min_year' + 3, \`caaspp_max_year' + 3)` (line 23)
- `label var prior_math_z_score "Prior Math Z-Score"` (line 24)
- (and matching `peer_*` versions, lines 25-27)

**Inputs:** None directly — uses already-merged variables (`L3_cst_ela_z_score`, `L4_cst_ela_z_score`, `L3_sbac_ela_z_score`, `L3_sbac_math_z_score`, `L5_cst_math_z_score`, and `peer_*` versions) from `create_va_sample.doh` lines 13-37.

**Outputs:** None (in-memory variable creation).

**Sourced helpers:** None.

**Path references:** None.

**Stata version / non-trivial syntax:** Backtick-quoted local macros (`star_min_year`, `star_max_year`, `caaspp_min_year`, `caaspp_max_year`) — relies on `macros_va.doh` to set these.

**ssc/community packages used:** None.

**Gotchas:**

- The `inrange` patterns encode **lag relative to test-year**: `L3_cst_ela_z_score if inrange(year, star_min_year+3, star_max_year+3)` selects students whose `year - 3` (= `L3` test-year) is in the STAR-CST window (2003-2013). Once `year=2014` this fails because the L3 year would be 2011 (still in CST), but the `& year!=2017` exclusion is for the 2014-skip handling at line 14.
- For ELA in **year 2017** specifically, the file overrides to `L4_cst_ela_z_score` (2013 test year, 7th grade). The reasoning: California tested grades 2-11 in CST through 2012-13, then skipped 2013-14, then transitioned to SBAC in 2014-15. So 2017 11th graders' "L3 = 2014" was a non-test year, requiring fallback to L4 = 2013 (7th-grade CST).
- **Math has no parallel "year==2017" override.** Line 22-23 only switches math between `L5_cst_math_z_score` and `L3_sbac_math_z_score`, which means 2017 cohort uses `L3_sbac_math_z_score` (2014 SBAC math) — but **2014 SBAC was not administered**. This is a potential bug or relies on the lagged-test-scores file padding 2014 with missings, which would silently drop the entire 2017 cohort from the math VA. (Documented as Q7 anomaly below.) Need to confirm by checking `k12_lag_test_scores_clean.dta` content, which is outside chunk-2 scope.
- Line 22 `& !inrange(year, \`caaspp_min_year' + 3, \`caaspp_max_year' + 3)` is logically equivalent to `& year < caaspp_min_year + 3 (=2018) | year > caaspp_max_year + 3 (=2022)`. For our cohort range 2015-2018, this restricts the CST math branch to year 2015-2017 only? No — `caaspp_min_year+3 = 2018`. Therefore CST-math fires for `year<2018`. So 2018 cohort uses SBAC-L3-math (= L3 SBAC year = 2015), and 2015-2017 cohorts use CST-L5-math (i.e., L5 = year-5: 2010-2012, 6th-grade STAR/CST math). **This matches the docstring lines 6-9 of this file.**
- Comment block lines 6-9 explicitly enumerates the per-cohort grade/year mapping; verified consistent with the code. (See Synthesis Q1 table.)

**Reference to paper outputs:** All v1-suffixed paper artifacts (the **paper uses v1**). Tables 2-7 columns, Figures 1-6 panels.

---

### File: `cde_va_project_fork/do_files/sbac/create_prior_scores_v2.doh`

**Predecessor repo:** cde_va_project_fork
**Owner:** Christina Sun (per file header line 3)
**Lines:** 32
**Purpose:** Same as v1 but uses **same prior-score grade for ELA and math** (both 6th grade for 2015-2017 cohorts; both 8th grade for 2018 cohort). v2 is an alternative robustness specification not used in the main paper text.

**Macros defined:** None.

**Variables created/transformed:**

- `gen prior_ela_z_score = L5_cst_ela_z_score if inrange(year, \`star_min_year' + 5, \`star_max_year' + 5) & year!=2018` (line 13)
- (commented-out line 14: would have used L5_sbac_ela)
- `replace prior_ela_z_score = L3_sbac_ela_z_score if year==2018` (line 16)
- `gen peer_prior_ela_z_score = peer_L5_cst_ela_z_score if ... & year!=2018` (line 19)
- `replace peer_prior_ela_z_score = peer_L3_sbac_ela_z_score if year==2018` (line 21)
- `gen prior_math_z_score = L5_cst_math_z_score if inrange(year, \`star_min_year' + 5, \`star_max_year' + 5) & !inrange(year, \`caaspp_min_year' + 3, \`caaspp_max_year' + 3)` (line 26)
- `replace prior_math_z_score = L3_sbac_math_z_score if inrange(year, \`caaspp_min_year' + 3, \`caaspp_max_year' + 3)` (line 28)
- (peer math equivalents, lines 30-31)

**Inputs:** None directly — uses already-merged lagged-score variables.

**Outputs:** None.

**Gotchas:**

- v2 ELA branches: `L5_cst_ela_z_score` for years 2015-2017 (= L5 = 6th grade STAR/CST 2010-2012) and `L3_sbac_ela_z_score` for year 2018 (= L3 SBAC = 8th grade 2015).
- The math branch in v2 is **identical** to v1 math (line-for-line same code as v1 lines 22-26 vs. v2 lines 26-31). Confirms math controls don't differ between v1 and v2.
- Line 14 and 20 are commented-out alternative SBAC versions — kept for reference.

**Reference to paper outputs:** Per the paper map, v2 is **not used in main paper**, only v1 is. v2 may exist as a robustness check artifact (`v2`-suffixed tables/figures referenced in paper map).

---

### File: `cde_va_project_fork/do_files/sbac/create_va_g11_sample_v1.doh`

**Lines:** 15. **Identical line-by-line to `create_va_g11_sample.doh`** (verified). This is a duplicate file — likely a developer's `_v1` rename without removing the original. Same purpose, same code.

### File: `cde_va_project_fork/do_files/sbac/create_va_g11_sample_v2.doh`

**Lines:** 15. **Differs from v1 only at line 9:** `include do_files/sbac/create_prior_scores_v2.doh` instead of `_v1`. Otherwise identical. Comment line 1 says "version 2 of VA samples, same prior score controls for ELA and Math".

### File: `cde_va_project_fork/do_files/sbac/create_va_g11_out_sample_v1.doh`

**Lines:** 15. **Identical line-by-line to `create_va_g11_out_sample.doh`** — same duplication pattern as `_v1` test-score file.

### File: `cde_va_project_fork/do_files/sbac/create_va_g11_out_sample_v2.doh`

**Lines:** 15. **Differs from out_v1 only at line 9:** `include do_files/sbac/create_prior_scores_v2.doh`.

(All four `create_va_g11_*_v{1,2}.doh` are thin wrappers around the prior-score includes; nothing else changes between them.)

---

### File: `cde_va_project_fork/do_files/sbac/drift_limit.doh`

**Predecessor repo:** cde_va_project_fork
**Owner:** unknown
**Lines:** 4
**Purpose:** Sets two locals that compute the drift limit (years over which to allow drift) for **both** test-score VA and outcome VA in one helper.

**Macros defined:**

- `local score_drift_limit = max(\`test_score_max_year' - \`test_score_min_year' - 1, 1)` (line 2)
- `local out_drift_limit = max(\`outcome_max_year' - \`outcome_min_year' - 1, 1)` (line 4)

**Inputs / Outputs:** None.
**Gotchas:** This file declares **separate macro names** (`score_drift_limit`, `out_drift_limit`) — distinct from the `drift_limit` (singular) name used in `create_va_g11_sample.doh` line 3, `create_va_g11_out_sample.doh` line 3, and `out_drift_limit.doh` line 2. **Naming collision risk:** if calling code uses `\`drift_limit'`, this file does not provide it. Potential source of confusion in consolidation.

### File: `cde_va_project_fork/do_files/sbac/out_drift_limit.doh`

**Lines:** 2 (4 with comments).
**Purpose:** Sets a single `local drift_limit = max(\`outcome_max_year' - \`outcome_min_year' - 1, 1)` (line 2) — **the same expression as `drift_limit.doh` line 4 but stored in `drift_limit` instead of `out_drift_limit`.** Used by code that references just `\`drift_limit'` for outcome VA.

**Macros defined:** `local drift_limit` (line 2).

**Gotcha:** Two different files compute essentially the same outcome-side drift limit but store it in differently-named locals (`out_drift_limit` vs. `drift_limit`). Calling scripts must know which to include.

---

### File: `cde_va_project_fork/do_files/sbac/macros_va.doh`

**Predecessor repo:** cde_va_project_fork
**Owner:** unknown (inherited Naven, modified by Sun per change log line 1-17)
**Lines:** 612
**Purpose:** Master macro file for VA project — defines file-path locals, year-range locals, control-variable lists, control-specification combinations, sample-string labels, and school-characteristics lists for all VA estimation scripts.

**Macros defined (selected, with line numbers):**

- File paths (all under `#delimit ;` block starting line 19):
  - `home`, `vaprojdofiles`, `ca_ed_lab` (lines 22-24)
  - `k12_test_scores`, `public_access`, `k12_public_schools`, `k12_test_scores_public` (lines 25-28)
  - `siblingxwalk`, `ufamilyxwalk`, `sibling_out_xwalk` (lines 29-31)
- Year ranges:
  - `test_score_min_year` = 2015 (line 35)
  - `test_score_max_year` = 2018 (line 39)
  - `star_min_year` = 2003 (line 43)
  - `star_max_year` = 2013 (line 47)
  - `caaspp_min_year` = 2015 (line 51)
  - `caaspp_max_year` = 2019 (line 55)
  - `outcome_min_year` = 2015 (line 59)
  - `outcome_max_year` = 2018 (line 63)
- Outcome strings: `ela_str`, `math_str`, `enr_str`, `enr_2year_str`, `enr_4year_str` (lines 71-86)
- Sample-set strings: `og_str`, `acs_str`, `sib_str`, `both_str` (lines 90-104)
- Control-variable lists:
  - `school_controls` (line 109; commented-out cohort_size)
  - `demographic_controls` (lines 113-120: age, i.male, ethnicity dummies, econ_disadvantage, limited_eng_prof, disabled)
  - `ela_score_controls` (line 122-124: cubic in `prior_ela_z_score` interacted with year)
  - `ela_scrhat_controls` (line 127-129: cubic in `prior_ela_z_score_hat` interacted with year — predicted ELA)
  - `math_score_controls` (line 131-133)
  - `peer_ela_score_controls`, `peer_math_score_controls` (lines 137-143)
  - `peer_demographic_controls` (lines 145-152)
  - `va_control_vars` (line 156, with cleanup at 157-158)
  - `census_grade` = 6 (line 160)
  - `census_controls` (lines 164-169: eth_asian/hispanic/black_pct, educ_hs_dropout/4year+_prop, pov_fam_child_lt18_pct, inc_median_hh)
  - `peer_census_controls` (lines 171-175)
  - `sibling_controls` (lines 177-180: i.has_older_sibling_enr_2year, i.has_older_sibling_enr_4year)
  - `peer_sibling_controls` (lines 182-185)
  - `sib_lag1_controls`, `sib_lag2_controls` (lines 187-197)
  - `d_controls` (lines 199-203: mindist_any_nonprof_4yr, mindist_ccc)
- Control combinations: `b_controls`, `peer_b_controls`, `l_controls`, `peer_l_controls`, `a_controls`, ..., `las_controls`, `peer_las_controls` (lines 207-296). Foreach loop at 298-307 appends `d_controls` to each base set.
- Spec combinations: `b_spec_controls`, `b_scrhat_spec_controls`, `bd_spec_controls`, `bd_scrhat_spec_controls`, `l_spec_controls`, ..., `lasd_scrhat_spec_controls` (lines 312-477).
- Sample-string labels: `b_str` ("base"), `bd_str` (= `b_str`), `l_str` ("leave out score"), `ld_str` (= `l_str`), `a_str` ("ACS"), `ad_str` (= `a_str`), `s_str` ("sibling"), `sd_str` (= `s_str`), `la_str` ("leave out score & ACS"), `lad_str` (= `la_str`), `ls_str` ("leave out score & sibling"), `lsd_str` (= `ls_str`), `as_str` ("ACS & sibling"), `asd_str` (= `a_str` — **TYPO, should be `as_str`**), `las_str` ("leave out score & ACS & sibling"), `lasd_str` (= `las_str`), `d_str` ("postsecondary distance") (lines 481-547).
- Heterogeneity strings: `race_str`, `male_str`, `econ_disadvantage_str`, `prop_ecn_disadv_str`, `charter_str`, `inc_median_hh_xtile_str`, `enr_black_hisp_prop_str` (lines 550-564).
- School characteristics: `sch_chars`, `sch_char_vars`, `dem_chars`, `dem_char_vars`, `expenditures`, `expenditure_vars`, `sch_char_control_vars` (lines 567-609).

**Inputs / Outputs:** None — pure macro file.
**Sourced helpers:** None.

**Path references that need updating:** Every `local *` between lines 22-31 references `$vaprojdir` or `$projdir` globals.

**Stata version / non-trivial syntax:**

- `#delimit ;` at line 19, `#delimit cr` at line 612 — **all macro lines need terminal `;`**.
- Heavy use of factor-variable interaction syntax: `i.year#(c.prior_ela_z_score##c.prior_ela_z_score##c.prior_ela_z_score)` (line 123, 128, 132, etc.).
- Macro-list operators: `subinstr`, `list uniq`, `list |` (lines 157-158, 581-585, 595, 608-609).

**ssc/community packages used:** None directly (downstream commands use reghdfe, vam, esttab, etc.).

**Gotchas:**

- **Line 533-535 — `asd_str` typo:**
    ```
    local asd_str
        `a_str'
        ;
    ```
   Sets `asd_str` to "ACS" (the value of `a_str`). The pattern from other `*d_str` definitions is to mirror the version without `d`: `bd_str`=`b_str`, `ld_str`=`l_str`, `ad_str`=`a_str`, `sd_str`=`s_str`, `lad_str`=`la_str`, `lsd_str`=`ls_str`, `lasd_str`=`las_str`. By analogy `asd_str` should be `as_str` ("ACS & sibling"), not `a_str` ("ACS"). **This is a labeling bug — output tables/figures with the `asd` (ACS+sibling+distance) sample/control combo would be mislabeled "ACS" instead of "ACS & sibling".**
- **Line 305:** in the foreach at 298-307, `peer_\`control'd_controls` is set to just `\`peer_\`control'_controls'` (line 304-306) — i.e., the peer side does NOT include `d_controls`. So `peer_bd_controls = peer_b_controls`, peer-distance is NOT in the peer macro. May or may not be intended.
- **Line 318-324 — `b_scrhat_spec_controls`** uses `ela_scrhat_controls` instead of `ela_score_controls` — this is the predicted-ELA-prior-score variant. `prior_ela_z_score_hat` must exist when these are applied; **it is NOT generated in any chunk-2 helper** (see Q2 below).
- **Line 342-345** `l_scrhat_spec_controls` is built on `b_spec_controls` (NOT `b_scrhat_spec_controls`), which means the `l_scrhat` variant **uses the actual `prior_ela_z_score`, not the predicted version**. **Inconsistency vs. line 362 `a_scrhat_spec_controls` which uses `b_scrhat_spec_controls`.** May be a copy-paste bug. Worth flagging.
- Line 165 `eth_white_pct` is commented out; same for `eth_other_pct`, `educ_deg_2year_prop` — only 4 of 7 ethnicity/education ACS variables actively included.

**Reference to paper outputs:** Every paper estimation script includes `macros_va.doh`. Macros defined here directly drive the columns in Tables 2, 3, 4, 5, 6, 7 and the panel labels in Figures 1-6.

---

### File: `cde_va_project_fork/do_files/sbac/macros_va_all_samples_controls.doh`

**Predecessor repo:** cde_va_project_fork
**Owner:** unknown
**Lines:** 143
**Purpose:** Defines locals listing **valid (sample, control-spec) combinations** for looping over forecast bias tests and spec tests. Encodes which control specifications are allowed on which restricted samples.

**Macros defined (selected):**

- `va_controls`: `b l a s la ls as las bd ld ad sd lad lsd asd lasd` (line 24)
- `b_ctrl_samples`, `bd_ctrl_samples`, `l_ctrl_samples`, ..., `lasd_ctrl_samples` (lines 29-57)
- `va_controls_for_fb` (line 66): `b l a s la ls as las` (8 specs only — `_d` suffixed not in fb test)
- Forecast-bias leave-out vars: `b_ctrl_leave_out_vars` ... `las_ctrl_leave_out_vars` (lines 69-76)
- Predicted-score variants of fb leave-out vars: `b_ctrl_scrhat_leave_out_vars` ... `las_ctrl_scrhat_leave_out_vars` (lines 79-86)
- FB samples by spec: `l_fb_b_samples`, `a_fb_b_samples`, ..., `d_fb_b_samples` etc. (lines 92-143)

**Inputs / Outputs:** None.
**Sourced helpers:** None.

**Path references:** None.

**Stata version / non-trivial syntax:** No `#delimit` block; standard line-continuation with macro lists.

**Gotchas:**

- **Comments contain unusual sample-acronym typos:**
  - Line 36, 41 say "ac" (should be "acs"?), "sling" (should be "sibling"?). These are in **comments only**, no code effect, but they obscure what samples are encoded. E.g., line 95: "forecast bias test samples for acsibling controls as leave out var" — combines "acs" + "sibling" via concatenation, not as a known acronym. These are typos accumulated across the change log.
- The `_ctrl_scrhat_leave_out_vars` family at lines 79-86 omits the `l` (loscore) leave-out var across all `*_scrhat_leave_out_vars`. **Why:** if the spec already uses predicted ELA score, leaving out a 7th-grade ELA leave-out score has no clean analogue. (Speculation; not annotated.)
- Lines 24 and 66 — `va_controls` includes 16 specs but `va_controls_for_fb` includes only 8. Asymmetry not documented.

**Reference to paper outputs:** Used by FB-test driver scripts to control the loop space. Drives Tables 2-3 row 3-6 (forecast bias tests).

---

### File: `cde_va_project_fork/do_files/sbac/merge_lag2_ela.doh`

**Predecessor repo:** cde_va_project_fork
**Owner:** unknown (header references "Christina Sun" inferred from change log style)
**Lines:** 29
**Purpose:** Merge lag 2 ELA scores **without dropping missing observations** — used to compute `prior_ela_z_score_hat` while preserving the full sample. Generates a `lag2ela` variable holding either `L4_cst_ela_z_score` or `L5_cst_ela_z_score` depending on cohort year.

**Macros defined:** None.

**Variables created/transformed:**

- `gen lag2ela = .` (line 24)
- `replace lag2ela = L4_cst_ela_z_score if year == 2015 | year == 2016` (line 25)
- `replace lag2ela = L5_cst_ela_z_score if year == 2017 | year == 2018` (line 26)
- `label var lag2ela "leave out scores"` (line 27)
- `drop L4_cst_ela_z_score L5_cst_ela_z_score` (line 29)

**Inputs:** `` `k12_test_scores'/k12_lag_test_scores_clean.dta `` (line 20).

**Outputs:** None.

**Sourced helpers:** None.

**Path references:** `` `k12_test_scores' `` macro.

**Gotchas:**

- **Line 2-4 docstring vs. line 7 docstring inconsistency:** The header at lines 1-5 says "same as merge_loscore.doh but does not drop missing obs". This implies parity with `merge_loscore.doh` line 27. Verified: `merge_loscore.doh` lines 22-26 build `loscore` exactly the same way as `lag2ela` (only the variable name and `drop if mi(loscore)` line differ). **This file is `merge_loscore.doh` minus the `drop` and the peer-score creation.** Naming is non-self-documenting; "lag2ela" doesn't convey "leave out for predicted-score creation".
- Line 29 drops the lagged variables after using them — leaves `lag2ela` as the only lag variable for downstream use.

**Reference to paper outputs:** Used by `va_predicted_score.do` and `va_predicted_score_fb.do` (per grep) to predict `prior_ela_z_score_hat`. Indirectly feeds the `_scrhat_` paper specifications.

---

### File: `cde_va_project_fork/do_files/sbac/merge_loscore.doh`

**Predecessor repo:** cde_va_project_fork
**Owner:** unknown
**Lines:** 33
**Purpose:** Merge prior-prior ELA scores and create the **leave-out-score** variable `loscore`, plus its peer-jackknife `peer_loscore`.

**Macros defined:** None.

**Variables created/transformed:**

- `gen loscore = .` (line 23)
- `replace loscore = L4_cst_ela_z_score if year == 2015 | year == 2016` (line 24)
- `replace loscore = L5_cst_ela_z_score if year == 2017 | year == 2018` (line 25)
- `drop if mi(loscore)` (line 26)
- `label var loscore "leave out scores"` (line 27)
- `rangestat (mean) loscore, interval(year, 0, 0) by(cdscode) excludeself` (line 31)
- `rename loscore_mean peer_loscore` (line 32)
- `label var peer_loscore "peer leave out scores"` (line 33)

**Inputs:** `` `k12_test_scores'/k12_lag_test_scores_clean.dta `` (line 18).

**Outputs:** None.

**Sourced helpers:** None.

**Stata version / non-trivial syntax:** `rangestat` is a community package (line 31). **`rangestat` must be installed** (`ssc install rangestat`).

**ssc/community packages used:** **`rangestat`** (line 31).

**Gotchas:**

- Line 20 `drop if mi(L4_cst_ela_z_score) & mi(L5_cst_ela_z_score)` — drops only when **both** are missing. So a student with one valid lag is kept.
- Line 26 `drop if mi(loscore)` — but `loscore` is built with `replace` only for years 2015-2018. Any other year would have `loscore=.` and be dropped. Effectively limits to 2015-2018 cohort.
- Line 31 `excludeself` produces a leave-out (jackknife) mean, computed within each (year, cdscode) cell. Standard CFR-style peer measure.

**Reference to paper outputs:** Drives the `loscore` control in column 5 ("leave-out 7th-grade ELA") of Tables 2-7. **Maps to Online Appendix Table A.1 row 10 ("Drop students missing 7th-grade ELA")** in the paper map.

---

### File: `cde_va_project_fork/do_files/sbac/merge_sib.doh`

**Predecessor repo:** cde_va_project_fork
**Owner:** unknown (Christina Sun, inferred)
**Lines:** 18
**Purpose:** Merge sibling outcome crosswalk to attach **older-sibling college-going indicators**, restrict to obs with at least one matched older sibling, and compute peer (jackknife) sibling controls.

**Macros defined:** None.

**Variables created/transformed:**

- After merge: variables matching `touse* *sibling*` (line 5).
- `drop if mi(has_older_sibling_enr_2year)` (line 7)
- `drop if mi(has_older_sibling_enr_4year)` (line 8)
- `keep if sibling_out_sample == 1` (line 11)
- For each `var in has_older_sibling_enr_2year has_older_sibling_enr_4year`:
  - `rangestat (mean) \`var', interval(year, 0, 0) by(cdscode) excludeself` (line 15)
  - `rename \`var'_mean peer_\`var'` (line 16)
  - `label var peer_\`var' "percentage of peers in same school and year with \`var' equals 1"` (line 17)

**Inputs:** `` `sibling_out_xwalk' `` (line 5; declared in `vafilemacros.doh` line 24).

**Outputs:** None.

**Sourced helpers:** None.

**ssc/community packages used:** **`rangestat`** (line 15).

**Gotchas:**

- Line 5 keeps `(1 3)` — but a 1:m or m:1 crosswalk merge would not produce 1 (master only) by definition... OK, m:1 can produce 1. Fine.
- Line 11 `keep if sibling_out_sample == 1` — a previously-defined indicator on the using dataset. Restricts to students whose older sibling could plausibly be matched to college outcomes.
- **Maps to Online Appendix Table A.1 row 11 ("Drop students unmatched to older sibling")** in the paper map.

**Reference to paper outputs:** Drives the sibling-restricted sample (column 5+ of Tables 2-7), and creates the `has_older_sibling_enr_*` controls in column 5.

---

### File: `cde_va_project_fork/do_files/sbac/merge_va_smp_acs.doh`

**Predecessor repo:** cde_va_project_fork
**Owner:** Che Sun (per file header lines 16-17; first written 4/27/2022)
**Lines:** 123
**Purpose:** Merge ACS census-tract demographics (using lagged 6th-grade home address) to a VA dataset. Produces the **ACS-restricted sample** (drops obs with missing ACS variables) and creates peer (jackknife) ACS averages.

**Macros defined:** None directly — receives 5 args `va_type va_dataset_file va_dataset_name purpose va_name` (line 44).

**Variables created/transformed:**

- `census_sct = statefp + countyfp + tract` (line 51) on the geocode lookup table.
- `keep if grade==\`census_grade' & inrange(year, ...)` (line 62) on the lagged-address subset.
- `egen year_min = min(year) if dup_ssid!=0, by(state_student_id)` (line 65)
- `gen byte census_controls_sample = 1` (line 105) on the merged result
- For each ACS variable `eth_asian_pct eth_hispanic_pct eth_black_pct educ_hs_dropout_prop educ_deg_4year_plus_prop pov_fam_child_lt18_pct inc_median_hh`:
  - `rangestat (mean) \`var', interval(year, 0, 0) by(cdscode) excludeself` (line 110)
  - `rename \`var'_mean peer_\`var'` (line 111)

**Inputs:**

- `$vaprojdir/data/restricted_access/clean/crosswalks/address_list_census_batch_geocoded.csv` (line 49) — geocode CSV
- `$vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta` (line 60) — 6th-grade addresses
- `$vaprojdir/data/restricted_access/clean/crosswalks/address_list.dta` (line 74) — address-id table
- `$vaprojdir/data/public_access/clean/acs/acs_ca_census_tract_clean.dta` (line 81) — ACS data
- `` `va_dataset_file' `` (line 88) — the VA dataset to merge to (passed as arg)

**Outputs:** None.

**Sourced helpers:**

- `$vaprojdir/do_files/sbac/macros_va.doh` (line 47, via `include`)

**Path references that need updating:** All paths under `$vaprojdir` (multiple).

**Stata version / non-trivial syntax:**

- `args` (line 44) — Stata function arg passing convention.
- `import delimited` with `delimiter(tab) varnames(1) case(lower) stringcols(_all)` (line 50).
- `duplicates tag ... gen(...)` and `egen ... by(...)` (lines 64-65).
- Multiple `merge m:1 ... using ..., keep(3)` (lines 89-98) — keeps **only matched** obs, dropping master-only.

**ssc/community packages used:** **`rangestat`** (line 110).

**Gotchas:**

- **Line 62 `keep if grade==\`census_grade' & inrange(year, \`\`va_type'_min_year'-(11-\`census_grade'), \`\`va_type'_max_year'-(11-\`census_grade'))`:**
  This nested-macro expression uses `\`va_type'_min_year'` then dereferences via `\`\`va_type'_min_year''`. With `census_grade=6` and `va_type=test_score` it becomes `inrange(year, test_score_min_year - 5, test_score_max_year - 5) = inrange(year, 2010, 2013)`. So this **selects 6th-grade addresses for 11th graders in 2015-2018**, i.e., addresses from when student was 6 years prior to 11th grade. This is the **lagged-address-from-grade-6 logic**. Note the assumption is `11 - census_grade` years between current grade and census_grade. Hardcoded to 11.
- **Line 89-98 — chained `keep(3)` merges drop any obs that fails any one of {address-id, geocode, ACS-tract} match.** This is the source of the "Drop students unmatched to ACS Census-tract data" restriction (paper map row 12).
- Line 88-89: the `m:1` merges assume student-level `va_dataset_file` and crosswalks are unique on the merge key. If `lagged_address` had any state_student_id duplicates not handled by line 67's `duplicates drop`, the `m:1` would fail.
- **Line 100-102:** drops obs where any `census_controls` variable is missing — this defines the "ACS-restricted" sample. Matches the comment at line 11-13.
- Line 47 `include $vaprojdir/do_files/sbac/macros_va.doh` — **this helper sources macros_va.doh internally**, meaning it can be called as a standalone helper but inherits all the project macros.
- Line 54-56: `tempfile census_geocode` saved at line 56. Then line 71 `tempfile lagged_address`, line 78 `tempfile address_id`, line 84 `tempfile lagged_acs`. Four tempfiles, all chained.

**Reference to paper outputs:** ACS-restricted sample drives column 4-5 ACS controls in Tables 2-7. **Maps to Online Appendix Table A.1 row 12 ("Drop students unmatched to ACS Census-tract data")**.

**Notes / open questions:** Line 62's nested macro is brittle to typos (`va_type` arg). If the user passes `va_type=outscore` instead of `outcome`, the indirect macro reference would break silently.

---

### File: `cde_va_project_fork/do_files/merge_k12_postsecondary.doh`

**Predecessor repo:** cde_va_project_fork
**Owner:** Matthew Naven (per header line 4: "First created by Matthew Naven on June 11, 2018")
**Lines:** 480
**Purpose:** Merges K-12 student records to **three** postsecondary outcome sources: **NSC** (National Student Clearinghouse), **CCC** (California Community Colleges), **CSU** (California State University). Then constructs combined enrollment / persistence / degree outcome variables.

**Macros defined (key ones):**

- `crosswalks` = `/home/research/ca_ed_lab/projects/common_core_va/data/restricted_access/clean/crosswalks/` (line 7) — **HARDCODED ABSOLUTE SERVER PATH**
- Year ranges (lines 22-44): `min_nsc_hs_grad_year=2010`, `max_nsc_hs_grad_year=2019`, `min_nsc_enr_year=2010`, `max_nsc_enr_year=2020`, `min_nsc_deg_year=2011`, `max_nsc_deg_year=2020`, `min_ccc_enr_year=1993`, `max_ccc_enr_year=2017`, `min_ccc_deg_year=1993`, `max_ccc_deg_year=2016`, `min_csu_app_year=2002`, `max_csu_app_year=2017`, `min_csu_enr_year=2002`, `max_csu_enr_year=2017`, `min_csu_deg_year=2002`, `max_csu_deg_year=2016`.
- `args enr_only` (line 20) — argument controlling whether to derive only enrollment vars (`enr_only`) or also persistence/degree vars.

**Variables created/transformed (selected — there are many):**

- `gen year_grad_hs = year + (12 - grade)` (line 51)
- `gen year_college = year + (13 - grade)` (line 52)
- `gen k12_nsc_match = 0`, `k12_nsc_2010_2017_match`, `k12_nsc_2018cde_match`, `k12_nsc_2019cde_match` (lines 58-62) — match flags
- `gen k12_ccc_match = 0` (line 138)
- `gen k12_csu_match = 0` (line 203)
- `replace nsc_persist_year`t' = 0/.` (lines 95-100) — fills in NSC persistence as 0 for matched-but-not-persisted
- (Similarly for `nsc_deg_lt2year`, `nsc_deg_2year`, `nsc_deg_4year` lines 103-125)
- CCC: `replace ccc_enr=0/.` (line 159-164), `gen ccc_enr_ontime` (line 168-170, **multi-line `if` with line-continuation pattern**)
- `gen csu_enr_ontime` (lines 232-234)
- Composite outcomes:
  - `gen enr = 1 if nsc_enr==1` (line 326)
  - `replace enr = 0 if nsc_enr==0 & ccc_enr!=1 & csu_enr!=1` (line 327) — **note the asymmetry**: `enr=1` triggered only by NSC (line 326 has `/* | ccc_enr==1 | csu_enr==1*/` commented out), but `enr=0` requires NSC=0 AND CCC!=1 AND CSU!=1.
  - `gen enr_2year = 1 if nsc_enr_2year==1 | nsc_enr_lt2year==1 | ccc_enr==1` (line 334) — and parallel `replace ... = 0 if all are 0/!=1` (line 335)
  - `gen enr_4year = 1 if nsc_enr_4year==1 | csu_enr==1` (line 342)
  - `replace enr_2year = 0 if enr_4year==1` (line 346) — **enforces 4-year exclusivity**
  - Also `enr_pub`, `enr_priv`, `enr_instate`, `enr_outstate` (lines 354-393), and on-time variants
  - Persistence: `persist_year2`, `persist_year3`, `persist_year4` (lines 398-408)
  - Degree: `deg`, `deg_2year`, `deg_4year` (lines 414-424)
- CCC transfer to 4-year: `gen ccc_transfer_4year` (lines 445-450) with edge-case handling on enrollment-start-term boundary
- CSU transfer to UC: `csu_transfer_uc`, `csu_transfer_ucplus` (lines 462-477)

**Inputs (datasets `use`'d via merge):**

- `` `crosswalks'/nsc_outcomes_crosswalk_ssid.dta `` (line 67)
- `` `crosswalks'/k12_ccc_crosswalk.dta `` (line 142)
- `` `crosswalks'/ccc_outcomes_crosswalk.dta `` (line 153)
- `` `crosswalks'/k12_csu_crosswalk.dta `` (line 207)
- `` `crosswalks'/csu_outcomes_crosswalk.dta `` (line 218)
- `` `crosswalks'/k12_unique_crosswalk.dta `` (line 294)

**Outputs:** None — all changes in-memory.

**Sourced helpers:** None.

**Path references that need updating:**

- `crosswalks` (line 7) — **HARDCODED ABSOLUTE SERVER PATH** `/home/research/ca_ed_lab/...`. **Q7 BUG.** This is the most egregious portability issue in the whole chunk.

**Stata version / non-trivial syntax:**

- `version 16.1` (line 1) — explicit version requirement.
- Mixed merge keep options: `keep(1 3 4 5)` for NSC SSID merge with `update` (line 67); `keep(1 3)` for CCC and CSU merges. **Asymmetric merge keep-rules — flagged as Q7.**
- Repeated `tab grade year` calls (lines 68, 86, 101, 109, 117, 125, 132, etc.) — diagnostic prints, not errors, but bloat the log.
- Heavy use of multi-condition `replace ... if ... | ... & ...` with operator-precedence pitfalls.

**ssc/community packages used:** None directly — pure base Stata.

**Gotchas:**

- **HARDCODED ABSOLUTE PATH:** Line 7 `local crosswalks "/home/research/ca_ed_lab/projects/common_core_va/data/restricted_access/clean/crosswalks/"`. **MUST be parameterized for consolidation.**
- **Line 67 `keep(1 3 4 5)` + `update`** for NSC SSID merge — non-standard. `keep(4)` keeps "missing updated" cases and `keep(5)` keeps "non-missing conflict (master kept)" cases. Implies the master may already have NSC variables that get updated by the using; downstream replace logic at lines 82-84 then overwrites them based on `k12_nsc_match`. **The CCC and CSU merges (lines 142, 152, 218) use plain `keep(1 3)`** — asymmetric.
- **Line 326-327 `enr` commented-out OR clauses:** Line 326 `gen enr = 1 if nsc_enr==1 /*| ccc_enr==1 | csu_enr==1*/`. The comment-out means **`enr=1` requires NSC=1**, but the line 327 `replace enr = 0 if nsc_enr==0 & ccc_enr!=1 & csu_enr!=1` requires NSC=0 AND others not 1. So `enr` is missing if NSC is missing (e.g., student couldn't be matched to NSC at all) regardless of CCC/CSU. **This biases `enr` in favor of NSC matchability** — students who never could match to NSC end up `enr=.` even if they have CCC=1 enrollment. This is potentially an intentional choice (treat NSC as the primary outcome) but is non-obvious from code; the commented-out OR shows it was once different.
- **Line 168-170 — `gen ccc_enr_ontime = 1 if ccc_enr==1 & (... start_term in 5-8) | (... start_term in 1-4)`** — this is a **classic Stata operator precedence bug**: `&` binds tighter than `|`, so the expression is `(ccc_enr==1 & (... in 5-8)) | (... in 1-4)`. The second `|` clause ignores `ccc_enr==1`. **Likely a bug** — would produce `ccc_enr_ontime=1` for students with `ccc_enr_start_year==year_grad_hs+1 & start_term in 1-4` even if `ccc_enr=0` or `.`. **Q7 BUG.** Same pattern at lines 232-234 for CSU.
- **Line 233 `gen csu_enr_ontime = 1 if csu_enr==1 & (csu_enr_start_year==year_grad_hs & inlist(csu_enr_start_term, 3, 4)) | (csu_enr_start_year==year_grad_hs + 1 & inlist(csu_enr_start_term, 1, 2))`** — same operator-precedence bug.
- Line 75-77 / line 88: `if "\`enr_only'"=="enr_only"` defines varlist as enrollment-only; downstream foreach loops apply replace logic only to those. The branch logic is replicated multiple times.
- Line 95-99: `forvalues t = 2 (1) 4` — fine, uses standard syntax.
- Line 141, 153, 154: in CCC merge, `gen(merge_k12_ccc) keep(1 3) keepusing(student_id)` then `merge m:1 student_id ...` immediately reuses `gen(merge_k12_ccc)` (line 154) — the previous `merge_k12_ccc` was dropped at line 146 first. OK.
- **Line 446-449 CCC transfer-to-4-year edge case:** `replace ccc_transfer_4year = . if (ccc_enr_start_year==max_ccc_enr_year & start_term in {7,8}) | (ccc_enr_start_year==max_ccc_enr_year+1 & start_term in {1,2,3,4,5,6})` — corrects for the truncation at end of CCC data window.

**Reference to paper outputs:** This file produces the `enr`, `enr_2year`, `enr_4year`, `persist_year*`, `deg*` variables that are the **outcome-side dependent variables** in postsecondary VA. Tables 3 (`tab:va-enr-summary-statistics`), 6 (`tab:va-persistence`), 7 (`tab:va-enr-decomposition`), and Figures 1-6 panels for enr_2year/enr_4year all depend on these.

**Notes / open questions:**

- Why is `keep(1 3 4 5)` used for NSC-SSID merge but `keep(1 3)` for CCC/CSU? May relate to NSC update protocol where multiple NSC vintages get appended. Worth tracing.
- Why does the file not have a `clear` at the start? It assumes the caller has data already loaded. Should be documented.

---

### File: `caschls/do/share/siblingvaregs/vafilemacros.doh`

**Predecessor repo:** caschls
**Owner:** Che Sun (per header line 6: "First written by Che Sun, 12/13/2021")
**Lines:** 24
**Purpose:** Set local file-path macros for VA project datasets so that Matt Naven's do files (originally written for cde_va_project_fork structure) can be reused under caschls's `$projdir`.

**Macros defined:**

- `local vaprojdofiles "$vaprojdir/do_files"` (line 15)
- `local va_dataset "$projdir/dta/common_core_va/va_dataset"` (line 18)
- `local va_g11_dataset "$projdir/dta/common_core_va/va_g11_dataset"` (line 19)
- `local va_g11_out_dataset "$projdir/dta/common_core_va/va_g11_out_dataset"` (line 20)
- `local siblingxwalk "$projdir/dta/siblingxwalk/siblingpairxwalk"` (line 21)
- `local ufamilyxwalk "$projdir/dta/siblingxwalk/ufamilyxwalk"` (line 22)
- `local k12_postsecondary_out_merge "$projdir/dta/common_core_va/k12_postsecondary_out_merge"` (line 23)
- `local sibling_out_xwalk "$projdir/dta/siblingxwalk/sibling_out_xwalk"` (line 24)

**Inputs / Outputs:** None — pure macro file.
**Sourced helpers:** None.

**Path references that need updating:** All locals at lines 15-24 reference `$vaprojdir` or `$projdir` globals.

**Stata version / non-trivial syntax:** None.

**ssc/community packages used:** None.

**Gotchas:**

- **Two project root globals:** `$vaprojdir` (line 15) and `$projdir` (lines 18-24). `$vaprojdir` is for the cde_va_project_fork tree, `$projdir` is for caschls. These globals must both be set by the caller before this file is included. **Naming overlap with `cde_va_project_fork/do_files/sbac/macros_va.doh` lines 22-31 which also redefines several similar paths:** `siblingxwalk`, `ufamilyxwalk`, `sibling_out_xwalk` are defined in both files but with **identical** values (both use `$projdir`). Calling code that includes both gets last-one-wins — works, but fragile.
- **Comments at lines 7-9 reference "Matt's doh files" and the renaming of `vaprojdofiles`** — historical context that helps consolidation. Worth preserving in consolidation README.

**Reference to paper outputs:** Indirect — every paper-producing script that uses the caschls path conventions includes this file.

---

### File: `caschls/do/share/siblingvaregs/vaestmacros.doh`

**Predecessor repo:** caschls
**Owner:** Che Sun (per header line 8: "First written by Che Sun, 1/6/2022")
**Lines:** 160
**Purpose:** Define `local` macros for **stored estimate file names** for VA estimation outputs across subjects (ELA, math) and outcomes (enr, enr_2year, enr_4year). Provides standardized paths for `.dta` and `.ster` files for each combination of (subject/outcome × control spec × peer-or-not).

**Macros defined:**

- A `foreach subject in ela math` loop (line 16-71) defining for each subject:
  - `\`subject'_va_dta` — original VA CFR estimates dataset path
  - `\`subject'_spec_va` — original VA CFR spec test (no peer)
  - `\`subject'_spec_va_peer` — original VA CFR spec test (with peer)
  - `\`subject'_va_dta_l4` — VA with leave-out L4 scores
  - `\`subject'_spec_va_l4`, `_peer` — spec tests for L4 leave-out
  - `\`subject'_fb_va_l4` — forecast bias test on L4
  - `\`subject'_va_dta_census`, `_spec_va_census`, `_spec_va_census_peer`, `_fb_va_census` — census-tract leave-out variants
  - `\`subject'_va_dta_sibling`, `_spec_va_sibling_og`, `_spec_va_sibling`, `_spec_va_sibling_peer`, `_fb_va_sibling` — sibling sample variants
  - `\`subject'_sibling_vam_nosibctrl`, `_sibling_vam` — vam-command output for sibling
- An identical structure for `foreach outcome in enr enr_2year enr_4year` (lines 87-160), including `_va_dta_sib_census`, `_spec_sib_census_og`, `_sib_census_vam_*` for sibling+census combinations (most commented out).

**Inputs / Outputs:** None — pure macro file.
**Sourced helpers:** None.

**Path references:**

- `$vaprojdir/data/sbac/...` — for some output paths (lines 18-22, 27, 30, 32, 40, 43, 45, 48)
- `$vaprojdir/estimates/sbac/...` — most spec/fb test outputs (lines 20-22, 30-32, 35, 43, 45, 48)
- `$projdir/dta/common_core_va/test_score_va/...` — sibling test-score VA dta (line 53)
- `$projdir/est/siblingvaregs/test_score_va/...` — sibling spec/fb tests (lines 56-64)
- `$projdir/dta/common_core_va/outcome_va/...` — sibling outcome-VA dta (line 127)
- `$projdir/est/siblingvaregs/outcome_va/...` — sibling outcome spec/fb tests (lines 130-138)
- `$vaprojdir/estimates/sibling_va/test_score_va/...` — sibling vam outputs (lines 68, 70)
- `$vaprojdir/estimates/sibling_va/outcome_va/...` — sibling outcome vam outputs (line 153, plus mostly commented-out lines 144-151)
- `$vaprojdir/data/sibling_va/outcome_va/...` — sibling census sample data (line 142)

**Stata version / non-trivial syntax:** Two `foreach` loops, no `#delimit`.

**ssc/community packages used:** None.

**Gotchas:**

- **Line 27 — `local \`subject'_va_dta_l4 "$vaprojdir/data/sbac/bias_va_g11_\`subject'_L4ela.dta.dta"`:** filename has **`.dta.dta`** — duplicated extension! **Q7 BUG.** Same at line 99 for outcome version: `bias_va_g11_\`outcome'_L4ela.dta.dta`. Probably the loop string accidentally appended `.dta` twice.
- **Line 18 — `local \`subject'_va_dta "$vaprojdir/data/sbac/va_g11_\`subject'.dta, replace"`:** the comma plus `replace` is **embedded inside the macro value**. This works only if the calling code uses this macro directly as `save \`\`subject'_va_dta'` — i.e., the caller is constructing a save command. Otherwise it's syntactically broken if used as a `use`. **Non-obvious** — worth flagging as a calling convention.
- **Line 45 — `local \`subject'_spec_va_census_peer "vaprojdir/estimates/sbac/bias_spec_test_va_cfr_g11_\`subject'_census_peer.ster"`:** missing `$` prefix on `vaprojdir`! **Q7 BUG** — `vaprojdir` will be interpreted as a literal directory name "vaprojdir" rather than the global. Same at line 118 for outcome version.
- Many lines 144-160 are **commented out** (lines 146, 148, 151, 155, 157, 159) — implying many sibling-census variants are defined-but-disabled. Documents intent without implementing.
- **Lines 4-5 docstring:** "NOTE: does not include estimates from the sibling acs restricted sample. Too much bloating in the number of files, impossible to find unique local macro names and it's getting out of control." — **author explicitly acknowledges the macro-management is unmaintainable.** This is important for consolidation: the macro-naming scheme has known scaling problems.
- All paths use mixed `$vaprojdir` and `$projdir` — depends on which global is set.

**Reference to paper outputs:** Indirect — these are the destination paths for stored estimates that paper-producing scripts then load. Tables 2, 3, 4, 5, 6, 7 all consume `.ster` files written to these paths.

**Notes / open questions:**

- Author's note at line 4-5 motivates a refactor in consolidation. Worth tracking.

---

## 2. Synthesis

### Q1. v1 vs v2 Prior-Score Tables

#### v1 (per `create_prior_scores_v1.doh`, lines 12-26)

| Cohort (year) | ELA prior — variable | ELA — grade & spring year | Math prior — variable | Math — grade & spring year | v1 line |
|---|---|---|---|---|---|
| Spring 2015 | `L3_cst_ela_z_score` (line 12 fires; year 2015 is in `[star_min_year+3=2006, star_max_year+3=2016]` and `year!=2017`) | 8th grade ELA, spring 2012 | `L5_cst_math_z_score` (line 22 fires; year 2015 is in `[2008, 2018]` and not in `[caaspp_min_year+3=2018, caaspp_max_year+3=2022]`) | 6th grade math, spring 2010 | 12, 22 |
| Spring 2016 | `L3_cst_ela_z_score` (line 12 fires; year 2016 in `[2006, 2016]` and != 2017) | 8th grade ELA, spring 2013 | `L5_cst_math_z_score` (line 22 fires) | 6th grade math, spring 2011 | 12, 22 |
| Spring 2017 | `L4_cst_ela_z_score` (line 14 fires; year==2017 override) | 7th grade ELA, spring 2013 (2014 was a no-test year) | `L5_cst_math_z_score` (line 22 fires; year 2017 in `[2008, 2018]` and not in `[2018, 2022]`) | 6th grade math, spring 2012 | 14, 22 |
| Spring 2018 | `L3_sbac_ela_z_score` (line 13 fires; year 2018 in `[caaspp_min_year+3=2018, caaspp_max_year+3=2022]` and != 2017) | 8th grade ELA SBAC, spring 2015 | `L3_sbac_math_z_score` (line 23 fires; year 2018 in `[2018, 2022]`) | 8th grade math SBAC, spring 2015 | 13, 23 |

**Verification check:** matches the docstring at lines 6-9 exactly.

**Verification check:** matches the paper map's "v1" table verbatim. **No discrepancies.**

#### v2 (per `create_prior_scores_v2.doh`, lines 13-31)

| Cohort (year) | ELA prior — variable | ELA — grade & spring year | Math prior — variable | Math — grade & spring year | v2 line |
|---|---|---|---|---|---|
| Spring 2015 | `L5_cst_ela_z_score` (line 13 fires; year 2015 in `[star_min_year+5=2008, star_max_year+5=2018]` and != 2018) | 6th grade ELA, spring 2010 | `L5_cst_math_z_score` (line 26 fires) | 6th grade math, spring 2010 | 13, 26 |
| Spring 2016 | `L5_cst_ela_z_score` (line 13 fires) | 6th grade ELA, spring 2011 | `L5_cst_math_z_score` (line 26 fires) | 6th grade math, spring 2011 | 13, 26 |
| Spring 2017 | `L5_cst_ela_z_score` (line 13 fires) | 6th grade ELA, spring 2012 | `L5_cst_math_z_score` (line 26 fires) | 6th grade math, spring 2012 | 13, 26 |
| Spring 2018 | `L3_sbac_ela_z_score` (line 16 fires; year==2018 override) | 8th grade ELA SBAC, spring 2015 | `L3_sbac_math_z_score` (line 28 fires) | 8th grade math SBAC, spring 2015 | 16, 28 |

**Verification check:** v2 ELA branch at line 13 uses `L5` (5-year lag = 6th grade), so spring-2015 cohort uses spring-2010 6th-grade ELA. Matches docstring lines 6-9.

**Verification check:** matches paper map's "v2" table verbatim. **No discrepancies.**

**Note on the L3/L4/L5 semantics:** `L<N>` here means **lag of N years** in the test-year, applied to a student who is in grade 11 in the current year. For an 11th-grader in year `Y`, `L3` is year `Y-3` (= grade 8 if continuous progression), `L4` is year `Y-4` (= grade 7), `L5` is year `Y-5` (= grade 6). This is consistent with the docstring and the inrange windows.

### Q2. The `_scrhat_` (predicted-prior-score) variant

**Where `prior_ela_z_score_hat` is referenced in chunk-2 files:**

- `cde_va_project_fork/do_files/sbac/macros_va.doh` line 128: `i.year#(c.prior_ela_z_score_hat##c.prior_ela_z_score_hat##c.prior_ela_z_score_hat)` — the macro `ela_scrhat_controls` references it.

**Where `prior_ela_z_score_hat` is `gen`'d or `predict`'d in the entire `cde_va_project_fork` repo (via grep):**

- `cde_va_project_fork/do_files/explore/va_predicted_score.do` lines 58 and 117 — `predict prior_ela_z_score_hat`
- `cde_va_project_fork/do_files/explore/va_predicted_score_fb.do` lines 57 and 161 — `predict prior_ela_z_score_hat`

**Where it is `gen`'d / `predict`'d in the caschls repo:** Not found via grep.

**Conclusion:**

- **`prior_ela_z_score_hat` is NOT generated in any chunk-2 helper file** (none of the 21 audited files produces it).
- It is `predict`'d only in `cde_va_project_fork/do_files/explore/va_predicted_score.do` and `va_predicted_score_fb.do` — files **outside chunk 2**.
- Therefore: any code path that uses `ela_scrhat_controls`, `b_scrhat_spec_controls`, `bd_scrhat_spec_controls`, `l_scrhat_spec_controls`, etc. (declared in `macros_va.doh` lines 127-477) **requires `prior_ela_z_score_hat` to have been generated in a previous step by the explore-folder scripts**. There is no chunk-2 helper that wires this generation into the standard pipeline.

This is a **structural dependency on `do_files/explore/`** that the chunk-2 helpers do not document. Worth flagging for consolidation: either move `va_predicted_score.do` into the production pipeline, or accept that `_scrhat_` macros are dead code in the current chunk-2 scope.

### Q3. Naming conventions: `sp`, `ct`, `nw`, `_m`, `_wt`

**Searched all 21 chunk-2 files via grep for tokens `sp`, `ct`, `nw`, `_m`, `_wt`:**

- `sp` — **not found** in any chunk-2 file. (`bd_spec_controls` etc. contain `_spec_` not `_sp_`; no standalone `sp` token.)
- `ct` — **not found** in any chunk-2 file.
- `nw` — **not found** in any chunk-2 file.
- `_m` — **not found** as a suffix in any chunk-2 file.
- `_wt` — **not found** in any chunk-2 file.

**Interpretation:** These tokens (which appear in figure filenames per the paper map, e.g. `va_ela_scatter_b_vs_las_sp_b_ct_v1_nw`) are **defined downstream of chunk 2**, presumably in:

- The figure-generating do files (probably in `cde_va_project_fork/do_files/sbac/` outside the helper set, or in caschls)
- A figure-naming convention file we have not yet audited

**Defer to downstream chunks.** No chunk-2 file documents these tokens.

### Q4. Sample-restriction map (paper Online Appendix Table A.1 ↔ code line)

| A.1 # | Restriction | Code file : line | Variable / mechanism |
|---|---|---|---|
| 1 | All 11th graders in CAASPP | `create_va_g11_sample.doh` line 4: `use if grade==11 & dataset=="CAASPP" & inrange(year, ...)` | base filter |
| 2 | Schools serving grades 9-12 only | **Not in chunk 2.** May live in `va_samples.dta` upstream merge at `create_va_sample.doh` line 9 (touse_* indicators) or in `k12_diff_school_prop_schyr.dta` merge at line 40. Defer. | `touse_*` |
| 3 | First 11th-grade attempt only | **Not explicit in chunk 2.** May be in `first_scores_sample` flag merged at `create_va_sample.doh` line 2. | `first_scores_sample` |
| 4 | Conventional schools only | `create_va_sample.doh` line 50: `keep if conventional_school==1` | `conventional_school` |
| (extra) | School-cohort same-school proportion ≥ 95% | `create_va_g11_sample.doh` line 7 / `create_va_g11_out_sample.doh` line 7: `keep if diff_school_prop>=0.95` | `diff_school_prop` from `create_diff_school_prop.doh` |
| 5 | Drop schools with ≤10 11th-graders/year | `create_va_sample.doh` line 57: `drop if cohort_size<=10` | `cohort_size` |
| 6 | Drop students missing current-year subject test score | **Implicit:** scripts using `sbac_ela_z_score` or `sbac_math_z_score` as the dependent variable will drop missings via `reg`. Not a hard filter in chunk-2 code. | implicit |
| 7 | Drop students missing demographics | **Implicit via control variables in `va_control_vars`** (`macros_va.doh` line 156). `reg` drops students missing any demographic. Not explicit in chunk 2. | implicit |
| 8 | Drop students missing prior test scores | **Implicit:** `prior_ela_z_score` and `prior_math_z_score` are generated in `create_prior_scores_v1.doh`/`v2.doh`. Students missing all relevant lags get `prior_*_z_score=.` and are dropped at regression time. | implicit |
| 9 | Drop students whose school-year cell has <7 obs | **Not in chunk 2.** Likely enforced at VA estimation time via the `vam` package's minimum-cell-size option, or by a downstream filter. Defer. | unknown N=7 enforcement |
| 10 | Drop students missing 7th-grade ELA (FB leave-out) | `merge_loscore.doh` line 26: `drop if mi(loscore)` | `loscore` |
| 11 | Drop students unmatched to older sibling | `merge_sib.doh` lines 7, 8, 11: `drop if mi(has_older_sibling_enr_2year)`, `drop if mi(has_older_sibling_enr_4year)`, `keep if sibling_out_sample==1` | sibling-out flag |
| 12 | Drop students unmatched to ACS | `merge_va_smp_acs.doh` lines 89-98 (chained `keep(3)` merges to `lagged_address`, `address_id`, `census_geocode`, `lagged_acs`) and lines 100-102 `drop if mi(\`v')` for each census var | ACS merge cascade |

**Note re: A.1 row 9 (school-year cell <7 obs):** I could not find `7` as a hard threshold in any chunk-2 file. The closest filter is line 57 of `create_va_sample.doh` (`cohort_size<=10`), which is school-level not school-year-level. **Need to audit downstream estimation files for the N=7 cutoff.**

### Q5. Distance-to-college variables

**Definition site:** `cde_va_project_fork/do_files/sbac/macros_va.doh` lines 199-203:
```stata
local d_controls
    mindist_any_nonprof_4yr
    mindist_ccc
    ;
```

**Variables expected:** `mindist_any_nonprof_4yr` (minimum distance to any non-profit 4-year), `mindist_ccc` (minimum distance to a California Community College).

**Merge of these variables into the VA dataset:** **Not in any chunk-2 file.** No `mindist_*` variable creation, no merge with these names. Therefore:

- **The merge happens upstream of chunk 2** (probably during construction of `va_dataset` on disk, in a script not in this chunk's scope).
- Or these variables are hardcoded into the master VA dataset by a non-chunk-2 helper.

Defer to upstream / data-prep chunk audit.

### Q6. ACS census-tract variables

**Definition site:** `cde_va_project_fork/do_files/sbac/macros_va.doh` lines 164-169:
```stata
local census_controls
    /*eth_white_pct*/ eth_asian_pct eth_hispanic_pct eth_black_pct /*eth_other_pct*/
    educ_hs_dropout_prop /*educ_deg_2year_prop*/ educ_deg_4year_plus_prop
    pov_fam_child_lt18_pct
    inc_median_hh
    ;
```
(Active: 7 variables — 3 ethnicity %, 2 education prop, 1 poverty %, 1 income.)

**Merge file:** `cde_va_project_fork/do_files/sbac/merge_va_smp_acs.doh` (123 lines, audited above).

**Student-grade level of the merge:** **Grade 6** (per `census_grade=6` in `macros_va.doh` line 160; the merge in `merge_va_smp_acs.doh` line 62 keeps only students in grade 6 in years 2010-2013 to match Census tract data from when the student was in 6th grade).

**Macro defining the merge grade:** `local census_grade 6` at `macros_va.doh` line 160-162.

### Q7. Bugs / typos / anomalies — line-cited inventory

| # | Severity | File:line | Issue |
|---|---|---|---|
| 1 | **HIGH** | `merge_k12_postsecondary.doh:7` | Hardcoded absolute server path `/home/research/ca_ed_lab/projects/common_core_va/data/restricted_access/clean/crosswalks/`. Must be parameterized for portability. |
| 2 | **HIGH** | `merge_k12_postsecondary.doh:168-170` | Operator-precedence bug in `gen ccc_enr_ontime`: `ccc_enr==1 & A | B` parses as `(ccc_enr==1 & A) | B`, so `B` clause fires regardless of `ccc_enr`. Probably needs parentheses around the OR clauses. |
| 3 | **HIGH** | `merge_k12_postsecondary.doh:232-234` | Same operator-precedence bug for `csu_enr_ontime`. |
| 4 | **HIGH** | `macros_va.doh:533-535` | `asd_str` set to ``a_str'` ("ACS") instead of ``as_str'` ("ACS & sibling"). Mislabeled output for the asd (ACS+sibling+distance) sample/control combo. |
| 5 | **HIGH** | `vaestmacros.doh:45, 118` | Missing `$` prefix on `vaprojdir`: `local x_spec_va_census_peer "vaprojdir/estimates/..."` will literally write to a relative directory called `vaprojdir`. Both subject and outcome paths affected. |
| 6 | **MEDIUM** | `vaestmacros.doh:27, 99` | Filename ends in `.dta.dta` (duplicated extension): `bias_va_g11_\`subject'_L4ela.dta.dta` and `bias_va_g11_\`outcome'_L4ela.dta.dta`. |
| 7 | **MEDIUM** | `merge_k12_postsecondary.doh:67` | Asymmetric merge `keep(1 3 4 5)` for NSC SSID + `update` while CCC and CSU merges use `keep(1 3)` (lines 142, 152, 218). May be intentional (NSC has updated vintages) but undocumented. |
| 8 | **MEDIUM** | `macros_va.doh:342-345` vs `:362` | `l_scrhat_spec_controls` is built on `b_spec_controls` (no `_scrhat_`), but `a_scrhat_spec_controls` is built on `b_scrhat_spec_controls`. Inconsistent — likely copy-paste error in `l_scrhat_spec_controls`. |
| 9 | **MEDIUM** | `create_va_sample.doh:52-54` | Comments describe two restrictions (≥25% special-ed schools dropped, home-instruction/hospital-school dropped) that are NOT implemented in code. Either the restrictions actually live in `va_samples.dta`'s `touse_*` indicators (line 9 merge) or they were never implemented. |
| 10 | **MEDIUM** | `create_prior_scores_v1.doh:22-23` | Math branch has no `year==2017` override analogous to ELA. For 2017 cohort, `inrange(year, caaspp_min_year+3, caaspp_max_year+3)` evaluates to `inrange(2017, 2018, 2022)=false`, so the SBAC branch does NOT fire; instead the CST branch at line 22 fires using `L5_cst_math_z_score`. So 2017 cohort math = L5 = 2012 = 6th grade math CST. **This works** but only because of the date arithmetic — it is not visually obvious the 2017 case is handled. Robustness concern. |
| 11 | **MEDIUM** | `create_va_g11_out_sample.doh:15` (and `_v1`, `_v2`) | Tempfile saved as `va_g11_dataset` rather than `va_g11_out_dataset`. Name collision risk if both test-score and outcome helpers run in the same Stata session. |
| 12 | **LOW** | `drift_limit.doh` vs `out_drift_limit.doh` | Two helpers compute the same outcome-side drift limit but store it in differently-named locals (`out_drift_limit` vs `drift_limit`). Caller must know which to include. |
| 13 | **LOW** | `create_va_g11_sample.doh` ↔ `_v1.doh` | The two files are line-by-line identical (both 15 lines). Pure duplication. |
| 14 | **LOW** | `create_va_g11_out_sample.doh` ↔ `_v1.doh` | Same duplication. |
| 15 | **LOW** | `macros_va_all_samples_controls.doh:36, 41, 95-105` | Comments contain typos ("ac" / "acsibling" / "sling") that conflate sample acronyms. Code is correct; comments are misleading. |
| 16 | **LOW** | `merge_va_smp_acs.doh:62` | Nested macro `\`\`va_type'_min_year'` is brittle — typo in `va_type` arg silently produces empty range. |
| 17 | **LOW** | `vaestmacros.doh:18, 89` | Macro values include `, replace`: `"$vaprojdir/data/sbac/va_g11_\`subject'.dta, replace"`. Only valid if caller uses macro inside a `save` command. Non-obvious calling convention. |
| 18 | **LOW** | `macros_va.doh:298-307` foreach loop | `peer_\`control'd_controls` is set to `\`peer_\`control'_controls'` only — peer-side does NOT include `d_controls`. Asymmetry vs. own-side `\`control'd_controls`. May be intentional. |
| 19 | **LOW** | `vaestmacros.doh:4-5` | Author's docstring explicitly states: "impossible to find unique local macro names and it's getting out of control" — known scaling problem. |
| 20 | **LOW** | `merge_k12_postsecondary.doh:326-327` | `gen enr` line has commented-out `| ccc_enr==1 | csu_enr==1` in the `=1` branch but the `=0` branch requires all three. Asymmetric — students never matched to NSC get `enr=.` even with positive CCC/CSU. May be intentional but is non-obvious. |

---

## 3. Open questions (unresolved from chunk 2 alone)

These are the items I could not pin down from the in-scope files; they need to be answered against either upstream data-prep scripts, downstream estimation scripts, or the `va_samples.dta` content:

1. **Where is the ≥25% special-ed and home-instruction/hospital-school school exclusion implemented?** Comments at `create_va_sample.doh:52-54` describe it but no code. Likely in `data/sbac/va_samples.dta`'s `touse_*` flags (line 9 merge).
2. **Where is the school-year cell minimum-N=7 cutoff (paper A.1 row 9) enforced?** Not in chunk 2.
3. **Where is `mindist_any_nonprof_4yr` and `mindist_ccc` generated?** Used by `d_controls` macro (line 199-203 of `macros_va.doh`) but not produced by any chunk-2 file. Either upstream data prep or a non-chunk-2 helper.
4. **Where is `prior_ela_z_score_hat` generated in the production pipeline?** Only found in `do_files/explore/va_predicted_score{,_fb}.do` — outside chunk 2. The `_scrhat_` macros in `macros_va.doh` are otherwise dead code.
5. **What do the figure-naming tokens `sp`, `ct`, `nw`, `_m`, `_wt` mean?** Defer to downstream chunks (figure-generating scripts).
6. **Why `keep(1 3 4 5)` + `update` for NSC SSID merge but `keep(1 3)` for CCC/CSU?** (`merge_k12_postsecondary.doh:67` vs `:142, 152, 218`). NSC may have multi-vintage update protocol; needs documentation.
7. **Is the `enr=.` for NSC-non-matched-but-CCC-or-CSU-positive students intentional?** (`merge_k12_postsecondary.doh:326-327` asymmetry.)
8. **What is the calling convention for `vaestmacros.doh` paths embedded with `, replace`?** (lines 18, 89 — where these are dereferenced as `save \`x_va_dta'` presumably.) Confirm the call sites.
9. **First-attempt-only filter (A.1 row 3):** Where does `first_scores_sample` get set? Probably in `va_samples.dta`'s upstream construction.

---

## 4. Summary of verified findings

- **Q1 (v1 vs v2 prior-score tables):** Verified line-by-line against `create_prior_scores_v{1,2}.doh`. Tables match the paper map exactly.
- **Q2 (`_scrhat_`):** `prior_ela_z_score_hat` is **not** generated in any chunk-2 helper. Only in `do_files/explore/va_predicted_score{,_fb}.do` (lines 58, 117, 57, 161 respectively). The `_scrhat_` macros at `macros_va.doh:127-477` depend on a generation step external to chunk 2.
- **Q3 (naming tokens `sp`, `ct`, `nw`, `_m`, `_wt`):** None are defined or used in any chunk-2 file. Defer.
- **Q4 (sample-restriction map):** A.1 rows 1, 4, 5, 10, 11, 12 are explicitly implemented in chunk 2; rows 2, 3, 9 are not in chunk 2; rows 6, 7, 8 are implicit via missing-data drop at regression time.
- **Q5 (distance vars):** Defined in `macros_va.doh:199-203`, but the merge that produces `mindist_*` is upstream of chunk 2.
- **Q6 (ACS):** Defined in `macros_va.doh:164-169`. Merged via `merge_va_smp_acs.doh` at student-grade-6 level. `census_grade=6` at `macros_va.doh:160`.
- **Q7 (bugs):** 20 issues identified, 5 high-severity (hardcoded path, two operator-precedence bugs, the `asd_str` typo, the missing `$` in `vaestmacros.doh`), 6 medium-severity, 9 low-severity.

