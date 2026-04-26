# Chunk 7 (Data-Prep) — Round-2 Independent Blind Verification

**Date:** 2026-04-26
**Scope:** ACS census-tract cleaning, K-12-postsecondary distance pipeline, CDE school-characteristics build, CalSCHLS preparation and QOI year-batch cleaners.
**Method:** Direct primary-source reading. No round-1 documents consulted.

---

## Subdir 1 — `cde_va_project_fork/do_files/acs/`

### File 1. `acs/clean_acs_census_tract.do`

- **Lines:** 368
- **Purpose:** Cleans ACS 5-year subject tables S0601 (population/race), S1501 (education), S1702 (poverty), S1901 (income) at California census-tract level for fall years 2010-2013, then appends years into one final dataset.
- **Inputs:** `data/public_access/raw/acs/subject_tables/{year}/5yr/ACSST5Y{year}.{S0601|S1501|S1702|S1901}_data_with_overlays.csv` for `year in 2010 2011 2012 2013` (L52, L104, L136, L269).
- **Outputs:**
    - Per-year: `data/public_access/clean/acs/acs_ca_census_tract_clean_{year}.dta` (L347).
    - Appended: `data/public_access/clean/acs/acs_ca_census_tract_clean.dta` (L356).
- **Calls:** `include do_files/sbac/macros_va.doh` (L36).
- **Stata version / syntax:** No `version` directive. `set varabbrev off` (L23), `set seed 1984` (L30), `cap log close _all` (L26). Uses `#delimit ;`/`#delimit cr` for macro inclusion.
- **ssc packages:** None invoked here.
- **Path references:** All paths relative to `$vaprojdir` (`cd $vaprojdir` at L16); commented-out alternative path `$projdir/dta/common_core_va/acs/...` at L345-346 (legacy "while waiting for write access" path).
- **Paper output reference:** ACS variables (`eth_*_pct`, `educ_*_prop`, `pov_*`, `inc_median_hh`, etc.) feed grade-6 ACS controls used in regressions.
- **Variables created (load-bearing):**
    - Education proportions: `educ_hs_dropout_prop`, `educ_deg_hs_prop`, `educ_some_college_prop`, `educ_deg_2year_prop`, `educ_deg_4year_prop`, `educ_deg_grad_prop`, `educ_deg_4year_plus_prop` (L68-80).
    - Poverty: `fam_child_lt18_tot`, `pov_fam_child_lt18_pct` (L117-119).
    - Income: `inc_lt{N}k_{hh|fam|mcfam|nonfamhh}_pct` for N in {10,15,25,35,50,75,100,150,200}; `inc_median_hh`, `inc_mean_hh` and family/married-couple/non-family analogs (L152-251).
    - Population: `pop_517_tot`, `pop_lt18_tot`, `pop_native_tot`, `pop_native_prop`, `pop_517_native_tot`, `pop_517_native_prop`, `pop_lt18_native_tot`, `pop_lt18_native_prop` (L285-301).
    - Ethnicity percents: `eth_white_pct`, `eth_black_pct`, `eth_other_pct`, `eth_asian_pct`, `eth_hispanic_pct`, `eth_white_nonhispanic_pct` (L306-316).
- **Bugs / anomalies:**
    - **Year coverage gap.** L46 hardcodes `foreach year in 2010 2011 2012 2013`. Post-2013 ACS waves (2014-2022) are NOT processed. Grade-6 ACS merges that target post-2013 years will silently miss data unless an extension lives elsewhere — see Q2 below.
    - **`tot_prop` check is dead.** L83-85 generate a temp var to verify proportions sum to one, calls `sum`, but never asserts on the result. Just diagnostic output.
    - **L84 double-counts `s1501_c01_012e`.** The expression is `(s1501_c01_007e + s1501_c01_008e + s1501_c01_009e + s1501_c01_010e + s1501_c01_011e + s1501_c01_012e + s1501_c01_012e + s1501_c01_013e)`. The 4-year bachelor's term `s1501_c01_012e` appears twice. Almost certainly a typo. Because nothing asserts on this, the bug is silent.
    - **`destring ignore` patterns inconsistent.** Education uses `ignore(",+(X)-*null")` (L63), but poverty/income/population use `ignore(",+(X)-*Nnull")` (L113, L145, L281). The `N` is presumably a sentinel for non-disclosable estimates; the education table omits it.

### File 2. `acs/acs_2017_gen_dict.do`

- **Lines:** 47
- **Purpose:** Generate data dictionaries (variable name and label CSVs) for old-style 2017 ACS subject tables. **Does not produce any cleaned ACS data.**
- **Inputs:** `data/public_access/raw/acs/subject_tables/2017/ACS_17_5YR_{S0601|S1501|S1702|S1901}_with_ann.csv` (L32).
- **Outputs:** `$projdir/out/csv/acs/2017/acs_2017_{subject}_dict.{dta|csv}` (L40, L42).
- **Calls:** Nothing.
- **Stata syntax:** No `version`. `set varabbrev off` (L24).
- **ssc packages:** Comment at L18-19 says `ssc install descsave, replace` (used at L40).
- **Path references:** **Hardcoded absolute path** at L14: `cd "/home/research/ca_ed_lab/projects/common_core_va"` (in a comment block describing how non-Che users should run). Also hardcoded `$projdir` references at L40 and L42, presumed user-specific (it's `~/Dropbox/.../caschls`).
- **Bugs / anomalies:**
    - This is a meta-tool that helps build dictionaries; the cleaned ACS pipeline does not use 2017 data. So **2014–2017 ACS data is never converted** into cleaned form by this repo.

---

## Subdir 2 — `cde_va_project_fork/do_files/k12_postsec_distance/`

### File 3. `k12_postsec_distance/check_merge.do`

- **Lines:** 20
- **Purpose:** Sanity-check that schools in the VA base sample (`score_b.dta`) merge into the distance dataset.
- **Inputs:** `$vaprojdir/data/va_samples_v1/score_b.dta` (L12); `$distance_dtadir/clean/k12_postsec_mindistance` (L14).
- **Outputs:** Log only.
- **Calls:** `include $vaprojdir/do_files/sbac/macros_va.doh` (L10).
- **Stata syntax:** No `clear`/`set` block; relies on caller environment.
- **Anomalies:** Tiny diagnostic-only file. Tabulates schools with `_merge==1` (in master, not using). No bugs.

### File 4. `k12_postsec_distance/hd2021.do`

- **Lines:** 4322
- **Purpose:** Auto-generated NCES IPEDS dictionary file; `insheet`s `hd2021_data_stata.csv` (L32) and applies thousands of `label variable` and `label define` directives to the IPEDS Directory Information dataset for fall 2021.
- **Inputs:** `$distance_dtadir/raw/hd2021_data_stata.csv` (L32).
- **Outputs:** None — leaves data in memory for caller (`run`-style include).
- **Verification:** Spot-checked file head and tail. Entire body is `label variable`, `label define`, then a long `tab`/`summarize` block at the end. **Confirmed: opaque auto-generated NCES dictionary blob.** Header at L1-28 explicitly says it was generated by an external program. Not transcribing.
- **Bugs / anomalies:** None — boilerplate machine output.

### File 5. `k12_postsec_distance/k12_postsec_distances.do`

- **Lines:** 139
- **Purpose:** Compute all-pairs K12-to-postsecondary geodesic distance, then collapse to per-cdscode minimum distance for each college type.
- **Inputs:**
    - `$distance_dtadir/raw/hd2021_data_stata.csv` (loaded via `run hd2021` at L36).
    - `https://www.cde.ca.gov/schooldirectory/report?rid=dl1&tp=txt` (L76, primary) or `$distance_dtadir/raw/pubschls.txt` (L79, fallback if URL fails).
- **Outputs:**
    - `$distance_dtadir/clean/k12_postsec_distance` (full all-pairs distances, L118).
    - `$distance_dtadir/clean/k12_postsec_mindistance` (collapsed to per-cdscode minima, L134).
- **Calls:** `run $vaprojdir/do_files/k12_postsec_distance/hd2021` (L36).
- **Stata syntax:** Uses `cap log close _all` (L18), no `version`. `geodist` and `opencagegeo` packages installed at L24-25.
- **ssc packages:** `geodist` (`net install` from RePEc, L24); `opencagegeo` (L25).
- **Variables created:** `csu`, `uc`, `pub4yr`, `ccc`, `any_nonprof_4yr` (L48-60); `mindist_uc`, `mindist_csu`, `mindist_pub4yr`, `mindist_any_nonprof_4yr`, `mindist_ccc` (L120-122).
- **Paper output reference:** Distance variables feed `d_controls` macro (L200-203 of `macros_va.doh`) — see Q1 below.
- **Bugs / anomalies (significant):**
    - **L50: hardcoded assert on CSU count.** `count if csu==1` then `assert r(N)==23`. If IPEDS Directory changes (new CSU campus, e.g., proposed CSU San Joaquin), the script halts.
    - **L54: hardcoded assert on UC count.** `count if uc==1` then `assert r(N)==9`. Similar rigidity (ignores potential UC additions).
    - **L58: hardcoded assert on private 4-year count.** `assert r(N)==115`. Note that the assert here is NOT for the `ccc` variable count — `ccc` is generated AFTER the assert at L59 (`gen ccc=(uc==0 & csu==0 & control==1)`). The assert reads `r(N)` from the prior `tab f1sysnam if uc==0 & csu==0 & control==1` (L57). Brittle.
    - **L61 comment:** `*** 115 CC's, one less than 116 listed on CA CC. I think the calbright online is not in 2021 IPEDS??` — author flag of known data discrepancy.
    - **L98: hardcoded API key (commented but committed).** `/* opencagegeo if mi_geo_coord==1, key("[REVOKED 2026-04-30]") */`. The OpenCage geocoding API key is stored in plaintext in source. Even though commented, the secret is on disk and in git history. **Should be revoked.**
    - **L92-93: lossy `destring ... force`.** Latitude/longitude are `destring ... force, replace`. Any non-numeric coords coerce to missing without warning.
    - **L98 (again): missing-coord branch is disabled.** The `opencagegeo` line that would re-geocode 0/missing-coord rows is commented out. Schools with missing lat/long get no distance computation; `mindist_*` for them will be missing across all colleges.

### File 6. `k12_postsec_distance/merge_k12_postsec_dist.doh`

- **Lines:** 23
- **Purpose:** Helper to merge `mindist*` variables onto a calling dataset by cdscode.
- **Inputs:** `$distance_dtadir/clean/k12_postsec_mindistance` (L23).
- **Outputs:** Mutates the calling dataset in memory.
- **Calls:** `include $vaprojdir/do_files/sbac/macros_va.doh` (L20).
- **Anomalies:** Trivial wrapper. No bugs.

### File 7. `k12_postsec_distance/reconcile_cdscodes.do`

- **Lines:** 108
- **Purpose:** Patch 11 cdscodes that don't match between the VA sample and CDE directory (school closures/mergers) by relabeling cdscodes in the distance file to align with the VA sample.
- **Inputs:** `$vaprojdir/data/k12_postsec_distance/raw/cdscode_changes.csv` (L57); `$distance_dtadir/clean/k12_postsec_mindistance` (L74).
- **Outputs:** **In-place lossy overwrite** of `$distance_dtadir/clean/k12_postsec_mindistance` via `save, replace` at L81.
- **Patch count:** 11 cdscodes (L4-31, comment lists each VA→CDE mapping).
- **Bugs / anomalies:**
    - **In-place save (L81: `save, replace`).** This overwrites the same `k12_postsec_mindistance.dta` produced by `k12_postsec_distances.do`, with no separate output file or version tagging. If `k12_postsec_distances.do` is re-run after this patch, the patch is lost; if `reconcile_cdscodes.do` is re-run twice the second run will see already-patched data and may produce no-op or cumulative weirdness.
    - **Idempotency.** L78 `replace cdscode = cdscode_va if cdscode_va!=""` only fires when the joined `cdscode_va` is non-missing. After first run, the rows formerly keyed on CDE codes are now keyed on VA codes; a second merge using the same `cdscodes` tempfile would find no matches (since the CDE code is no longer in `cdscode`), so the second run is a silent no-op. So in practice the file is roughly idempotent — but the lossy-save concern still applies.
    - **`cdscode_va` not dropped after patch.** L78 reassigns `cdscode` from `cdscode_va`, but the helper variables `cdscode_va` and `cdscode_cde` (renamed `cdscode`) are kept in the saved file. Downstream merges on `cdscode` are unaffected, but the saved file has extra columns.

---

## Subdir 3 — `cde_va_project_fork/do_files/schl_chars/`

### File 8. `schl_chars/cds_nces_xwalk.do`

- **Lines:** 43
- **Purpose:** Build a crosswalk between CDS code and NCES district+school ID from the CDE public-school directory.
- **Inputs:** `$vaprojdir/data/public_access/raw/cde/pubschls.txt` (L23).
- **Outputs:** `$vaprojdir/data/public_access/clean/cde/cds_nces_id_xwalk.dta` (L42).
- **Variables created:** `nces_id` = ncesdist + ncesschool (L38).
- **Anomalies:**
    - **`log close _all`** at L12 instead of `cap log close _all` — will error if no log open. Then no `log using` is opened in this file. Mild.
    - **No log file** — script writes nothing diagnostic.
    - **No leading-zero recovery on cdscode** is done before the `replace cdscode = "0" + ...` on L36, which is correct.

### File 9. `schl_chars/clean_charter.do`

- **Lines:** 73
- **Purpose:** Clean CDE School Directory export to extract charter and public school dummies.
- **Inputs:** `data_local/CDESchoolDirectoryExport.txt` (Mac-Intel branch, L27) OR `$vaprojdir/data/public_access/raw/cde/CDESchoolDirectoryExport.txt` (server branch, L30).
- **Outputs:** `data_local/charter_status.dta` (Mac-Intel branch, L57) OR `$vaprojdir/data/public_access/clean/cde/charter_status.dta` (server branch, L60).
- **Variables created:** `charter` (1/0 dummy, L41-44); `public` (1/0 dummy, L47-50).
- **Bugs / anomalies (significant):**
    - **L26, L56: Apple Silicon detection bug.** Both branches use `if c(machine_type)=="Macintosh (Intel 64-bit)"`. On Apple Silicon (M1/M2/M3+) Stata reports `c(machine_type)` as `"Macintosh (Apple Silicon)"` (or similar — definitely not the Intel string). So on an arm64 Mac this branch is **never taken**, the script falls through to the server branch, and Stata then tries to load from `$vaprojdir/data/public_access/raw/cde/CDESchoolDirectoryExport.txt`. If `$vaprojdir` resolves to a Mac-local path that doesn't have that file, the script errors. **Confirmed bug.**
    - **L31, L68-69: log handling on the server branch only.** The Mac-Intel branch never opens a log file (no `log using` inside the `if` block at L26-28), so no log is produced when run on a Mac-Intel machine. Mild.
    - **L52: `keep cdscode opendate closeddate fundingtype charter public`** — the `keep` is in the shared block after the if/else, so both branches converge on the same column set. OK.

### File 10. `schl_chars/clean_ecn_disadv.do`

- **Lines:** 39
- **Purpose:** Compute school-year-level proportion of economically-disadvantaged students from the cleaned SBAC test-score file.
- **Inputs:** `$vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean` (L23, restricted to `year >= 2015`).
- **Outputs:** `$vaprojdir/data/public_access/clean/cde/ecn_disadv.dta` (L33).
- **Variables created:** `prop_ecn_disadv` (L28-29).
- **Anomalies:** Reasonable, no bugs spotted.

### File 11. `schl_chars/clean_elsch.do`

- **Lines:** 111
- **Purpose:** Clean CDE English Learners (`elsch`) files for fall years between `test_score_min_year - 1` and `test_score_max_year - 1` (so spring years `test_score_min_year` to `test_score_max_year`, i.e., 2015-2018 given the macros).
- **Inputs:** `data/public_access/raw/cde/elsch/elsch{YY}.txt` (L94).
- **Outputs:** `data/public_access/clean/cde/elsch/elsch_{YYYY}_clean.dta` (L104).
- **Stata syntax:** `version 16.1` (L1).
- **Anomalies:** No bugs spotted. Notable: encoding is `ISO-8859-1` (L94).

### File 12. `schl_chars/clean_enr.do`

- **Lines:** 187
- **Purpose:** Clean CDE Census-Day Enrollment by School files.
- **Inputs:** `data/public_access/raw/cde/enr/filesenr{YY}.asp.txt` (L94).
- **Outputs:** `data/public_access/clean/cde/enr/enr_{YYYY}_clean.dta` (L180).
- **Stata syntax:** `version 16.1` (L1).
- **Variables created:** `male`, `race` (recoded from `ethnicity`), and grade-level enrollment labels.
- **Anomalies:**
    - **L132-135: Sex/gender encoding.** `gen male:male = 1 if gender=="M"` then `replace male = 0 if gender=="F"` then `replace male = . if mi(gender)`. **Correct handling** — missing gender becomes `.` not 0. Contrast with `enrollmentclean.do` in caschls (different file, different encoding choice — see File 19).

### File 13. `schl_chars/clean_frpm.do`

- **Lines:** 152
- **Purpose:** Clean CDE Free or Reduced-Price Meal (FRPM) files.
- **Inputs:** Excel `.xlsx` for fall 2017/2018 (L103) and `.xls` for older years (L106).
- **Outputs:** `data/public_access/clean/cde/frpm/frpm_{YYYY}_clean.dta` (L142).
- **Stata syntax:** `version 16.1` (L1). `set seed 1984` (L70).
- **Anomalies:**
    - **L102 hardcoded year list `(2017 | 2018)`.** New years would need to be added by hand to the conditional.
    - **L109 cdscode construction:** concatenates `countycode + districtcode + schoolcode` from CSV — this assumes column types are string. The file uses `allstring clear` (L103, L106), so OK.

### File 14. `schl_chars/clean_locale.do`

- **Lines:** 91
- **Purpose:** Clean NCES EDGE 2015-16 geocode file to extract urban/rural locale type for CA schools.
- **Inputs:** `$vaprojdir/data/public_access/raw/nces/EDGE_GEOCODE_PUBLICSCH_1516.xlsx` (L20); `$vaprojdir/data/public_access/clean/cde/cds_nces_id_xwalk.dta` (L88).
- **Outputs:** `data/public_access/clean/nces/pubschls_locale.dta` (L91).
- **Variables created:** `locale_fine` (12-category), `locale_coarse` (4-category: City/Suburban/Town/Rural).
- **Anomalies:**
    - **L20 hardcodes 2015-16 NCES locale file.** Other years are not loaded; everything gets the 2015-16 classification regardless of test-score year.
    - **L19 comment confirms this** ("import the raw 2015-16 public school data file from NCES").

### File 15. `schl_chars/clean_sch_char.do`

- **Lines:** 549
- **Purpose:** Master combine — append all `enr_*`, `frpm_*`, `elsch_*`, `staffdemo_*`, `staffcred_*`, `staffschoolfte_*` per-year cleaned datasets, build school-level aggregates (enrollment by race/sex, FTE per student, teacher demographics, charter/locale), and produce the canonical `data/sch_char.dta`.
- **Inputs (intermediates produced upstream):**
    - `data/public_access/clean/cde/enr/enr_{YYYY}_clean.dta` (L103, L120, L204).
    - `data/public_access/clean/cde/frpm/frpm_{YYYY}_clean.dta` (L252).
    - `data/public_access/clean/cde/elsch/elsch_{YYYY}_clean.dta` (L283).
    - `data/public_access/clean/cde/staffdemo/staffdemo_{YYYY}_clean.dta` (L314).
    - `data/public_access/clean/cde/staffcred/staffcred_{YYYY}_clean.dta` (L341).
    - `data/public_access/clean/cde/staffschoolfte/staffschoolfte_{YYYY}_clean.dta` (L372).
    - `$vaprojdir/data/public_access/clean/cde/charter_status.dta` (L525).
    - `$vaprojdir/data/public_access/clean/cde/ecn_disadv.dta` (L527).
    - `$vaprojdir/data/public_access/clean/nces/pubschls_locale.dta` (L529).
- **Outputs:**
    - `data/sch_char.dta` (master, L532).
    - `data/sch_char_{YYYY}.dta` (per-spring-year, L541).
- **Stata syntax:** `version 16.1` (L1).
- **Variables created (load-bearing):** `enr_total`; `enr_{indian|asian|hispanic|black|white|biracial}`; `enr_black_hisp`, `enr_other`, `enr_minority`, `enr_majority`; same with `_prop`; `enr_female`, `enr_male`, `enr_female_prop`, `enr_male_prop`; `frpm_prop`, `el_prop`, `eth_minority` (staff-side, L318), `new_teacher` (L323), `credential_full`, `credential_full_prop`; `classification_{teach|admin|pupil}`, `fte_{teach|admin|pupil}`, `fte_*_pc` (per-student); `male_prop`, `eth_minority_prop`, `new_teacher_prop`.
- **Paper output reference (Q5):** Output `data/sch_char.dta` is consumed by `va_het.do` at L32 (`merge 1:1 cdscode year using $vaprojdir/data/sch_char.dta, nogen keep( 3)`) — feeds heterogeneity tables (paper Tables 5/7).
- **Bugs / anomalies:**
    - **L319-320: `eth_minority` definition.** `gen eth_minority = (inlist(race, 1, 5, 6, 8))` — combines American Indian (1), Hispanic (5), Black (6), Two-or-more-races (8) into "minority." Asian (2) and White (7) are excluded. This is a defensible operationalization but worth flagging that "minority" here is a specific subset and excludes Asian.
    - **L408 `merge` chain.** L407-408 merge `staffdemo` (m:1 on districtcode/year/recid), then `staffcred` (m:1 on year/recid). These are consecutive; the staffdemo merge's `_merge` is dropped via `nogen`. The `merge_enr_total` flag on L426 is the one that's preserved and dropped at L437. OK.
    - **L412: `restore, preserve`** — preserves the `staffschoolfte`/`staffdemo`/`staffcred` joined dataset, then later three more `restore, preserve` blocks at L449, L476 each rewind to that snapshot. OK pattern but fragile if any of the three diverging branches modifies state in a way that affects the next.
    - **L414-416 division by 100:** `replace fte_teach = fte_teach / 100`. This is to convert FTE values from percentages (0-100) to fractions (0-1). Documented behavior.
    - **L425-426: `keep(1 3)`** — keeps non-matched master and matched, drops "using only." Standard.
    - **L455-460 weighted mean:** `collapse (mean) male_prop = male eth_minority_prop = eth_minority new_teacher_prop = new_teacher [aw = fte_teach], by(cdscode year)`. Weighting by FTE. Standard.

### File 16. `schl_chars/clean_staffcred.do`

- **Lines:** 180
- **Purpose:** Clean CDE staff credentials files.
- **Inputs:** `data/public_access/raw/cde/staffcred/StaffCred{YY}.txt` (L96).
- **Outputs:** `data/public_access/clean/cde/staffcred/staffcred_{YYYY}_clean.dta` (L173).
- **Variables created:** `credential` (10-95 codes); `authorization` (100-999 codes); `date_created`.
- **Stata syntax:** `version 16.1`. UTF-8 encoding (L96).
- **Anomalies:** None spotted; clean. Note: file uses Unicode right-single-quote in label "Children's Center" (L110) — could break if encoding mismatches.

### File 17. `schl_chars/clean_staffdemo.do`

- **Lines:** 409
- **Purpose:** Clean CDE staff demographics files. **Two separate cleaning loops** because schema differs between fall 2014 and fall 2015+.
- **Inputs:** `data/public_access/raw/cde/staffdemo/StaffDemo{YY}.txt` (L96, L255).
- **Outputs:** `data/public_access/clean/cde/staffdemo/staffdemo_{YYYY}_clean.dta` (L244, L402).
- **Stata syntax:** `version 16.1`.
- **Bugs / anomalies (significant):**
    - **Two divergent loops with hardcoded year boundary.** L91 hardcodes `forvalues fall_year = 2014 (1) 2014` (a single iteration!) and L250 hardcodes `forvalues fall_year = 2015 (1) ... test_score_max_year - 1`. The 2014 block creates `male`, `education`, `ethnicity`, `race`, `years_teaching`, `years_district`, `employment_status`, `fte_teach`, `fte_admin`, `fte_pupil`, `fte` (L113-228) — note **`fte` is summed at L227**.
    - **L227 vs. L386 schema divergence.** The 2014 block creates a top-level `fte` variable via `egen fte = rowtotal(fte_teach fte_admin fte_pupil), missing` (L227). The 2015+ block does NOT create this `fte` variable. Downstream consumer `clean_sch_char.do` does `merge m:1 districtcode year recid using staffdemo` (L407 of `clean_sch_char.do`), so consumers expecting `fte` will see `.` for fall 2015+. This may be intentional (because staffschoolfte provides FTE in those years), but the schema asymmetry is real.
    - **L172-198: Commented-out per-race dummies in 2014 block.** The 2014 block has the per-race dummies (`eth_american_indian`, `eth_asian`, etc.) **commented out** (block comment at L172-198), while the 2015+ block has them **active** (L333-358). Schema mismatch between years.
    - **L278 `age` variable** is created only in 2015+ block; not in 2014.
    - **L389: 2015+ block has no `fte` rowtotal.** Consistent with the schema mismatch above.

### File 18. `schl_chars/clean_staffschoolfte.do`

- **Lines:** 159
- **Purpose:** Clean CDE Staff School FTE files (which schools each staff member is assigned to and their FTE there).
- **Inputs:** `data/public_access/raw/cde/staffschoolfte/StaffSchoolFTE{YY}.txt` (L96).
- **Outputs:** `data/public_access/clean/cde/staffschoolfte/staffschoolfte_{YYYY}_clean.dta` (L152).
- **Variables created:** `cdscode` (concatenated districtcode + schoolcode, L108); `job_classification` (10-27); `staff_type` (1-3); `fte`, `date_created`.
- **Anomalies:** Clean.

---

## Subdir 4 — `caschls/do/build/prepare/`

### File 19. `prepare/enrollmentclean.do`

- **Lines:** 212
- **Purpose:** Clean CDE enrollment datasets for spring 1415-1819, build school-level enrollment by grade × sex × ethnicity, then collapse to one row per school × year.
- **Inputs:** `$projdir/dta/enrollment/raw/{enr1415|enr1516|enr1617|enr1718|enr1819}` (L13, L17).
- **Outputs:** `$projdir/dta/enrollment/schoollevel/{enrYYYY}` (L203).
- **Stata syntax:** No `version`; `set more off` (L9).
- **Variables created:** `gr{1-12}{ethnic}enr` (24 ethnicity-buckets per grade), `gr{1-12}{femaleenr|maleenr}`, `femaleenrtotal`, `maleenrtotal`, `blackenrtotal`, `whiteenrtotal`, `hispanicenrtotal`.
- **Bugs / anomalies (significant):**
    - **L21-22 (Q7): Missing-gender students treated as male.** `gen byte female = 0` then `replace female = 1 if gender == "F"`. **No `replace female = .` for missing gender.** So students with `gender` missing or any non-"F" string get `female=0`. Downstream consequence: `gr{i}femaleenrtemp` (L40) is 0 for these students; `gr{i}maleenrtemp` (L43) gets `gr{i}enrsex` for them (since `female == 0`). So **missing-gender students are silently bucketed into the male enrollment count.** Compare with `cde_va_project_fork/do_files/schl_chars/clean_enr.do` L132-135 which correctly sets `male = . if mi(gender)`. Two parallel cleaners, two different policies.
    - **L120-145: huge `drop` statement** lists 10 ethnicity dummies × 12 grades + sex temps. Workable but fragile to renaming.
    - **L156-163: variable-label preservation hack.** Saves all variable labels into local macros `l`vname before `collapse`, then restores them after. Necessary because `collapse` would otherwise lose them. OK pattern.

### File 20. `prepare/poolgr11enr.do`

- **Lines:** 29
- **Purpose:** Pool school-level grade-11 enrollment over 1415-1819, compute the per-school mean, save for use as regression weights.
- **Inputs:** `$projdir/dta/enrollment/schoollevel/{enr1415|enr1516|enr1617|enr1718|enr1819}` (L14-18).
- **Outputs:** `$projdir/dta/enrollment/schoollevel/poolgr11enr` (L25).
- **Variables created:** `gr11enr_mean` (L22-23).
- **Anomalies:** Clean. `collapse (mean) gr11enr` ignores missing — fine.

### File 21. `prepare/renamedata.do`

- **Lines:** 229
- **Purpose:** Rename CalSCHLS surveys (CHKS Elementary, Parent CSPS, Secondary, Staff CSSS) to consistent year-stamped filenames; standardize cdscode formatting.
- **Inputs:**
    - Elementary 1415-1819 dta (L16, L23, L30, L37, L44).
    - Parent 1415 raw dta `csps1415 all.dta` (L59) — special handling.
    - Parent 1516-1819 raw dta (L92, L99, L106, L113).
    - Secondary 1112-1213 csv (L129, L134); 1314-1819 dta (L139-178).
    - Staff 0414 dta (L186); 1415-1819 dta (L193-221).
- **Outputs:** `$clndtadir/{elementary|parent|secondary|staff}/...` (numerous).
- **Stata syntax:** No `version`. `set more off` (L9).
- **Bugs / anomalies (significant):**
    - **L77-89 (Q8): Comment-vs-code drift.** Comment at L77-79 reads "There are 2 school IDs that are single digit: 3 and 4, for a total of 5 responses. Filling in leading zeros for the school code and search with the resulting cds code did not produce any result in the California School Directory. **Therefore I assume these are missing or incorrectly entered data and discard them.**" But code at L82-89 only does `strtrim`/`stritrim` and `replace schl = "0" + schl if inrange(length(schl), 6, 6)` (L84). **There is no `drop` for single-digit schl rows.** L84's condition `length(schl), 6, 6` only pads 6-digit codes; 1-digit codes are left untouched (and become invalid 8-digit cdscodes when concatenated). Then `save "$clndtadir/parent/parent1415"` at L89 saves the entire dataset including the malformed rows.
    - **L73-75 typo:** L74 sets `replace dist = strtrim(dist)`, but L75 sets `replace cnty = stritrim(cnty)` (should be `dist`). The cnty was already trimmed at L67-68; this re-trims cnty instead of running stritrim on dist. Cnty trim is just idempotent; no functional bug but the intent was clearly to do dist.
    - **L69-71: County code reconstruction** — the assumption is plausible (single-digit county codes 2/7/9 → 02/07/09) but unverified.
    - **No `compress`** before `save` at L89 (parent1415 path). Other branches compress at L19, L26, L33, etc.
    - **L130, L135: `tostring cdscode, replace format("%15.0f")`** for the 1112 and 1213 secondary CSVs. Note: format `%15.0f` would not pad with leading zeros, so 13-digit cdscodes will display as 13 chars. No leading-zero recovery is performed for these two files, unlike the post-1415 dta branches which use `strtrim`/`stritrim` only (assuming the strings are already correct). Could produce mismatched joins downstream.

### File 22. `prepare/splitstaff0414.do`

- **Lines:** 40
- **Purpose:** Split combined `staff0414.dta` (CSSS 2004-05 through 2013-14) into 10 per-year datasets.
- **Inputs:** `$clndtadir/staff/staff0414` (L13).
- **Outputs:** `$clndtadir/staff/staff{YYYY}` for `YYYY in {0405, 0506, 0607, 0708, 0809, 0910, 1011, 1112, 1213, 1314}` (L33).
- **Anomalies:**
    - **L16-25 schlyear matching:** uses `schlyear == 2004.2005` etc. as if `schlyear` were a float. If the raw file stores schlyear as a string, this will fail silently (yielding empty `tempyear`). Worth verifying upstream.
    - **L27 local macro `years`:** parallel list to L16-25 — manual sync hazard.

---

## Subdir 5 — `caschls/do/build/buildanalysisdata/qoiclean/`

These files share a recurring schema. Convention: `qoi{N}` = renamed question, `pctagree{N}`/`pctdisagree{N}`/`pctdontknow{N}` for 5-pt agree-disagree-with-DK, `pctwell{N}`/`pctokay{N}`/`pctnotwell{N}` for qoi 64 (parent), `pctyes{N}`/`pctno{N}`/`pctnotapp{N}` for staff yes/no questions (1617_1516 only).

### File 23. `qoiclean/parent/parentqoiclean1415.do`

- **Lines:** 152
- **Purpose:** Clean parent 1415 survey QOIs.
- **Inputs:** `$clndtadir/parent/parent1415` (L13).
- **Outputs:** `$projdir/dta/buildanalysisdata/qoiclean/parent/parentqoiclean1415` (L148).
- **Stata syntax:** `set more off` (L9). **No `set varabbrev off, perm`.**
- **QOIs covered:** 9, 15-17, 27, 31, 33 (L60).
- **Schema divergence:** **Missing qoi 30, 32, 34, 64** (L15 comment confirms). Therefore no `pctwell64`/`pctokay64`/`pctnotwell64` in this file.
- **Variables created:** `qoi{i}mean`, `stragree{i}`, `agree{i}`, `disagree{i}`, `strdisagree{i}`, `dontknow{i}`, `missing{i}`. **No `pct*` variables generated.** (The `pct*` derivation block at L198-228 of the 1516 file is absent here.)
- **Anomalies:**
    - **No `pct*` derivations.** Whereas all other parent year-batches generate `pctagree`/`pctdisagree`/`pctdontknow`, the 1415 file stops after the `collapse` at L114 and does not derive `nettotalresp` or `pct*`. Downstream pooling code that expects `pctagree9` etc. for 1415 must handle this absence.

### File 24. `qoiclean/parent/parentqoiclean1516.do`

- **Lines:** 235
- **Purpose:** Clean parent 1516 survey QOIs.
- **Inputs:** `$clndtadir/parent/parent1516` (L13).
- **Outputs:** `$projdir/dta/buildanalysisdata/qoiclean/parent/parentqoiclean1516` (L231).
- **Stata syntax:** `set more off` (L9). **No `set varabbrev off, perm`.**
- **QOIs covered:** 9, 15-17, 27, 31, 33, 64 (L28). Missing 30, 32, 34 (L27 comment).
- **Variables created:** `qoi{i}mean`, response-count dummies, `pctagree{i}`/`pctdisagree{i}`/`pctdontknow{i}` (L209-212), and for qoi64: `verywell64`, `justokay64`, `notwell64`, `doesnotdo64`, `pctwell64`, `pctokay64`, `pctnotwell64`, `pctdontknow64` (L216-223).

### File 25. `qoiclean/parent/parentqoiclean1617.do`

- **Lines:** 242
- **Purpose:** Clean parent 1617 survey QOIs.
- **Inputs:** `$clndtadir/parent/parent1617` (L13).
- **Outputs:** `$projdir/dta/buildanalysisdata/qoiclean/parent/parentqoiclean1617` (L238).
- **Stata syntax:** `set more off` (L9). **No `set varabbrev off, perm`.**
- **QOIs covered:** 9, 15-17, 27, 30, 31, 33, 34, 64 (L32). Missing 32 (L31 comment).
- **Variables created:** Same family as 1516 plus 30 and 34.

### File 26. `qoiclean/parent/parentqoiclean1819_1718.do`

- **Lines:** 235
- **Purpose:** Clean parent 1718 and 1819 surveys (looped, same schema).
- **Inputs:** `$clndtadir/parent/parent1718`, `$clndtadir/parent/parent1819` (L18, looped on `local years '"1718" "1819"'` at L15).
- **Outputs:** `$projdir/dta/buildanalysisdata/qoiclean/parent/parentqoiclean{1718|1819}` (L230).
- **Stata syntax:** `set more off` (L10). **No `set varabbrev off, perm`.**
- **QOIs covered:** 9, 15-17, 27, 30-34, 64 (L20).
- **Variables:** Full schema including all qoi 30/32/34.

### File 27. `qoiclean/secondary/secqoiclean1415.do`

- **Lines:** 204
- **Purpose:** Clean secondary 1415 (CHKS high-school).
- **Inputs:** `$clndtadir/secondary/sec1415` (L13).
- **Outputs:** `$projdir/dta/buildanalysisdata/qoiclean/secondary/secqoiclean1415` (L201).
- **Stata syntax:** `set more off` (L9). **No `set varabbrev off, perm`.**
- **QOIs covered:** 22-26 and 31-40 (L23-33). **Missing 27-30** (L21 comment).
- **Question schema:** qoi 22-26 and 31-34 use 5-pt agree/neither/disagree (`pctagree`/`pctdisagree`/`pctneither` at L180-185). qoi 35-40 use 4-pt true scale (`pctnottrue`/`pcttrue` at L189-193).
- **Anomalies:**
    - **L17 `keep` is `a14 a15 ... a28`.** L15 attempts `rename a#_a# a#` but `a#_a#` is not valid Stata syntax — `#` is not a wildcard. (Wildcards in `rename ... ...` are typically `*`, not `#`.) This rename would only fire if the dataset literally had variables named `a#_a#`, which is unlikely. The actual rename happens via the elabel rename + foreach loop at L19-33.
    - **L19 elabel rename uses `(a#_a#) (a#)` similar pattern**. Likely no-op.
    - **L41-44 comment value labels are corrupted:** "neither disagree nor disagree4 disagree5 strongly agree" — readable as a comment-typo, not a code issue.

### File 28. `qoiclean/secondary/secqoiclean1617.do`

- **Lines:** 192
- **Purpose:** Clean secondary 1617.
- **Inputs:** `$clndtadir/secondary/sec1617` (L13).
- **Outputs:** `$projdir/dta/buildanalysisdata/qoiclean/secondary/secqoiclean1617` (output path inside, see file).
- **Stata syntax:** `set more off` (L9). **No `set varabbrev off, perm`.**
- **QOIs covered:** 22-40 (raw `a21-a39` shifted by +1 at L16-20).
- **Anomalies:**
    - **L13-14 `keep cdscode a21 ... a39`** — 1617 uses different raw question numbers (`a21` corresponds to qoi 22, etc.).
    - **L15-20 shift loop:** `local j = `i' + 1` to map a21→qoi22 etc. Different from 1819/1718/1516 batch which uses identity mapping (a22→qoi22).

### File 29. `qoiclean/secondary/secqoiclean1819_1718_1516.do`

- **Lines:** 233
- **Purpose:** Clean 1516, 1718, 1819 secondary (same schema, looped).
- **Inputs:** `$clndtadir/secondary/sec{1516|1718|1819}` (L24, looped at L20).
- **Outputs:** `$projdir/dta/buildanalysisdata/qoiclean/secondary/secqoiclean{year}` (output path).
- **Stata syntax:** `set more off` (L11). **No `set varabbrev off, perm`.**
- **QOIs covered:** 22-40 (identity mapping `a22`→`qoi22` etc. at L25-30).
- **Note:** L15-17 has commented-out `ssc install` directives for `elabel`, `labutil2`, `labundef` — informational.

### File 30. `qoiclean/staff/staffqoiclean1415.do`

- **Lines:** 383
- **Purpose:** Clean staff 1415.
- **Inputs:** `$clndtadir/staff/staff1415` (L15).
- **Outputs:** `$projdir/dta/buildanalysisdata/qoiclean/staff/staffqoiclean1415` (saves toward bottom).
- **Stata syntax:** `set more off` (L10). **`set varabbrev off, perm` (L11).** Only staff files have this.
- **QOIs covered:** 10, 20, 41, 44, 98, 103-105, 109, 111, 112, 128 (L18, L50).
- **Schema divergence:** **Missing qoi 24, 64, 87** (L17, L49 comments).

### File 31. `qoiclean/staff/staffqoiclean1617_1516.do`

- **Lines:** 403
- **Purpose:** Clean staff 1516 and 1617 (looped, same schema).
- **Inputs:** `$clndtadir/staff/staff{1516|1617}` (L19, looped at L16).
- **Outputs:** `$projdir/dta/buildanalysisdata/qoiclean/staff/staffqoiclean{1516|1617}` (L397).
- **Stata syntax:** `set more off` (L10). **`set varabbrev off, perm` (L11).**
- **QOIs covered:** 10, 20, 41, 44, 87, 98, 103-105, 109, 111, 112, 128 (L22, L55). **Missing 24, 64** (L21, L54 comments).
- **Notable:**
    - **L262-264: 3-code recode for qoi 103-105/109/111/112.** `replace qoi`i' = -1 if qoi`i' == 1` (yes), `0 if qoi`i' == 3` (not applicable), `1 if qoi`i' == 2` (no). Three response options.
    - **L268-279: Three dummies generated** (`yes{i}`, `no{i}`, `notapp{i}`) plus `missing{i}`.
    - **L388-389: pctnotapp generated** for qoi 103/105/109/111/112.

### File 32. `qoiclean/staff/staffqoiclean1819_1718.do`

- **Lines:** 222
- **Purpose:** Clean staff 1718 and 1819 (looped, same schema).
- **Inputs:** `$clndtadir/staff/staff{1718|1819}` (L18, looped at L15).
- **Outputs:** `$projdir/dta/buildanalysisdata/qoiclean/staff/staffqoiclean{1718|1819}` (L218).
- **Stata syntax:** `set more off` (L10). **NO `set varabbrev off, perm`.** *Inconsistent with the other two staff files.*
- **QOIs covered:** 10, 20, 24, 41, 44, 64, 87, 98, 103-105, 109, 111, 112, 128 (L19, L21).
- **Schema divergence (significant):**
    - **L131-134: 2-code recode for qoi 103-105/109/111/112.** `replace qoi`i' = -1 if qoi`i' == 1` (yes), `1 if qoi`i' == 2` (no). **Only two response options** (yes/no) — the 1718/1819 raw data does NOT have a "not applicable" option.
    - **L136-145: Two dummies generated** (`yes{i}`, `no{i}`, `missing{i}`). **No `notapp{i}` dummy.**
    - **L207-211: `pctyes`/`pctno` generated. NO `pctnotapp`.**
- **This confirms the chunk-7 brief's expectation that staff 1718/1819 lacks `pctnotapp`.**

---

## Answers to Specific Questions

### Q1. Distance-FB Row 6 producer chain

**Q1a. Where are `mindist_*` variables created?**

In `cde_va_project_fork/do_files/k12_postsec_distance/k12_postsec_distances.do` at L120-122:

```stata
foreach coll in uc csu pub4yr any_nonprof_4yr ccc {
    gen mindist_`coll'=distance if `coll'==1
}
```

Then collapsed to one row per cdscode at L124 (`collapse (min) mindist_*, by(cdscode)`) and saved at L134 to `$distance_dtadir/clean/k12_postsec_mindistance`.

**Q1b. Where are they merged into the VA dataset?**

`merge_k12_postsec_dist.doh` L23:

```stata
merge m:1 cdscode using $distance_dtadir/clean/k12_postsec_mindistance, keepusing(mindist*) nogen keep(1 3)
```

This `.doh` is included from VA-sample-construction do-files via `include $vaprojdir/do_files/k12_postsec_distance/merge_k12_postsec_dist.doh`.

**Q1c. Where is `d` added to `*_ctrl_leave_out_vars` lists?**

In `cde_va_project_fork/do_files/sbac/macros_va_all_samples_controls.doh` L69-86. Every `_ctrl_leave_out_vars` line ends with `d`:

```
L69: local b_ctrl_leave_out_vars l a s la ls as las d
L70: local l_ctrl_leave_out_vars a s as d
... (etc through L76)
L79: local b_ctrl_scrhat_leave_out_vars a s as d
... (etc through L86)
```

The `d` token corresponds to the `d_controls` macro in `macros_va.doh` L200-203:

```
local d_controls
    mindist_any_nonprof_4yr
    mindist_ccc
    ;
```

**Q1d. Only 2 of 5 `mindist_*` variables enter regressions.** Confirmed: of `mindist_uc, mindist_csu, mindist_pub4yr, mindist_any_nonprof_4yr, mindist_ccc` (5 variables, all merged via `keepusing(mindist*)`), only `mindist_any_nonprof_4yr` and `mindist_ccc` are listed in `d_controls` (`macros_va.doh` L200-203). The other three (`mindist_uc`, `mindist_csu`, `mindist_pub4yr`) are merged into the dataset but unused as controls.

### Q2. ACS year coverage

`clean_acs_census_tract.do` L46 hardcodes `foreach year in 2010 2011 2012 2013` — produces clean datasets for spring 2010, 2011, 2012, 2013 only. The append at L352-355 covers exactly these four years. **Post-2013 ACS data is NOT loaded by this script.**

The only other ACS file in the repo is `acs_2017_gen_dict.do`, which **only generates a data dictionary** (CSV mapping variable names to labels) for the 2017 vintage — it does not produce any cleaned data values. So 2014, 2015, 2016, 2017+ ACS subject tables are not flowing through this codebase. Either there's a sibling pipeline elsewhere, or downstream regressions that intersect with post-2013 student cohorts will silently rely on stale 2010-2013 census-tract characteristics.

### Q3. `reconcile_cdscodes.do` patching

- **Patch count:** 11 cdscodes (`reconcile_cdscodes.do` L4-31).
- **Lossy in-place save:** YES. L81 is `save, replace` (no path argument), inheriting the path from the prior `use $distance_dtadir/clean/k12_postsec_mindistance, clear` at L74. The patch overwrites the file from `k12_postsec_distances.do`.

### Q4. `hd2021.do`

Confirmed: 4322-line auto-generated NCES IPEDS dictionary opaque blob. L1-28 is a header comment that the file was machine-generated. Body is wall-to-wall `label variable` and `label define` directives. Tail (L4280-4322) is a `tab`/`summarize` diagnostic block. **Not transcribed.**

### Q5. School-characteristics dependency tree

`clean_sch_char.do` inputs (per L103, L120, L204, L252, L283, L314, L341, L372, L525, L527, L529):

| Input | Source |
|---|---|
| `enr_{YYYY}_clean.dta` | clean_enr.do |
| `frpm_{YYYY}_clean.dta` | clean_frpm.do |
| `elsch_{YYYY}_clean.dta` | clean_elsch.do |
| `staffdemo_{YYYY}_clean.dta` | clean_staffdemo.do |
| `staffcred_{YYYY}_clean.dta` | clean_staffcred.do |
| `staffschoolfte_{YYYY}_clean.dta` | clean_staffschoolfte.do |
| `charter_status.dta` | clean_charter.do |
| `ecn_disadv.dta` | clean_ecn_disadv.do |
| `pubschls_locale.dta` | clean_locale.do |

Output: `data/sch_char.dta` at L532, plus per-spring-year `data/sch_char_{YYYY}.dta` at L541.

**Path alignment with `va_het.do`:** Confirmed. `va_het.do` L32 reads `$vaprojdir/data/sch_char.dta`; `clean_sch_char.do` L532 writes `data/sch_char.dta` after `cd $vaprojdir` (L30). Match.

### Q6. CalSCHLS QOI year-batching

| Survey | Year-batch file | QOIs |
|---|---|---|
| Parent | parentqoiclean1415.do (alone) | 9, 15-17, 27, 31, 33 — missing 30/32/34/64 |
| Parent | parentqoiclean1516.do (alone) | 9, 15-17, 27, 31, 33, 64 — missing 30/32/34 |
| Parent | parentqoiclean1617.do (alone) | 9, 15-17, 27, 30, 31, 33, 34, 64 — missing 32 |
| Parent | parentqoiclean1819_1718.do (1718 + 1819) | 9, 15-17, 27, 30-34, 64 — full schema |
| Secondary | secqoiclean1415.do (alone) | 22-26, 31-40 — missing 27-30 |
| Secondary | secqoiclean1617.do (alone) | 22-40 (`a21`-`a39` shifted +1) |
| Secondary | secqoiclean1819_1718_1516.do (1516 + 1718 + 1819) | 22-40 (identity mapping) |
| Staff | staffqoiclean1415.do (alone) | 10, 20, 41, 44, 98, 103-105, 109, 111, 112, 128 — missing 24/64/87 |
| Staff | staffqoiclean1617_1516.do (1516 + 1617) | 10, 20, 41, 44, 87, 98, 103-105, 109, 111, 112, 128 — missing 24/64 |
| Staff | staffqoiclean1819_1718.do (1718 + 1819) | 10, 20, 24, 41, 44, 64, 87, 98, 103-105, 109, 111, 112, 128 — full schema |

Schema divergences:
- Parent 1415 has no qoi 64 (no `pctwell64`/`pctokay64`/`pctnotwell64`).
- Parent 1415 has NO `pct*` derivations at all (skips the `nettotalresp` and `pctagree`/`pctdisagree`/`pctdontknow` blocks); only response counts.
- Parent 1516 lacks 30/32/34; parent 1617 lacks 32.
- Staff 1415 lacks qoi 24, 64, 87.
- Staff 1617_1516 lacks qoi 24, 64.
- Staff 1718/1819 has yes/no questions (qoi 103-105, 109, 111, 112) with **only 2 response options** (yes/no) — no "not applicable." Therefore **no `pctnotapp` variables.** Whereas staff 1617_1516 has `pctnotapp{103,104,105,109,111,112}`.
- Secondary 1415 lacks qoi 27-30.

### Q7. `enrollmentclean.do` female-encoding (L21)

Confirmed. `enrollmentclean.do` L21-22:

```stata
gen byte female = 0
replace female = 1 if gender == "F"
```

There is no `replace female = . if mi(gender)` (or analogous). All non-"F" rows — including missing gender, "M" males, and any other malformed values — are bucketed into `female == 0`.

Downstream impact (L36-51): `gr{i}femaleenrtemp` is 0 for these rows; `gr{i}maleenrtemp` is set to `gr{i}enrsex` for `female == 0`, so missing-gender students contribute their full enrollment to the "male" enrollment bucket. The collapsed school-level vars `gr{i}maleenr` and `maleenrtotal` therefore include missing-gender students; `femaleenrtotal` excludes them.

This conflicts with `cde_va_project_fork/do_files/schl_chars/clean_enr.do` L132-135, which does set `male = . if mi(gender)`. Two parallel cleaners with two different policies.

### Q8. `renamedata.do` 5-row drop discrepancy

Confirmed. `renamedata.do` L77-89 (parent 1415 block):

- **Comment at L77-79:** "There are 2 school IDs that are single digit: 3 and 4, for a total of 5 responses... Therefore I assume these are missing or incorrectly entered data and discard them."
- **Code at L82-89:** Strips whitespace from `schl` (L82-83), pads 6-digit codes to 7 with a leading zero (L84), then constructs cdcode and cdscode (L86-88), then saves the entire dataset (L89).
- **No `drop` for single-digit `schl`** rows. They survive into the saved file with malformed cdscodes (cnty + dist + 1-digit schl = 8-character cdscode).

Severity: 5 row impact at most. But the comment-vs-code drift is a real audit liability — claims something the code doesn't do.

### Q9. `clean_charter.do` Apple Silicon detection

Confirmed. `clean_charter.do` L26 and L56:

```stata
if c(machine_type)=="Macintosh (Intel 64-bit)" {
```

Stata 18 reports `c(machine_type)` as `"Macintosh (Apple Silicon)"` on M1/M2/M3+ machines, NOT the Intel string. So on an arm64 Mac:

- L26 evaluates false → falls into the `else` branch at L29-33 → loads from `$vaprojdir/data/public_access/raw/cde/CDESchoolDirectoryExport.txt` and opens `$vaprojdir/log_files/schl_chars/clean_charter.smcl`.
- L56 evaluates false → falls into `else` at L59-71 → saves to `$vaprojdir/data/public_access/clean/cde/charter_status.dta`.

If `$vaprojdir` resolves to a server path the user doesn't have, the script errors. If the user's `$vaprojdir` is local and the file is missing, the script errors. **The Mac-Intel-only detection silently mis-routes Apple Silicon Macs onto the server-style path.** Confirmed bug.

### Q10. Hardcoded paths and API keys

- **`acs_2017_gen_dict.do` L14:** Comment "OR if you are not Che, run cd '/home/research/ca_ed_lab/projects/common_core_va'" — gives a hardcoded server path as fallback instruction (in a comment block, not active code).
- **`k12_postsec_distances.do` L98:** Commented-out hardcoded OpenCage API key: `key("[REVOKED 2026-04-30]")`. Should be revoked from OpenCage. Even though commented out, the secret is committed to source.
- **No other hardcoded `/home/research/...` cross-user paths** found in the audited subdirs of `cde_va_project_fork`.
- **No hardcoded paths or API keys** found in the `caschls/do/build/` audited files; everything routes through `$projdir`, `$rawdtadir`, `$clndtadir`, `$rawcsvdir` globals.

### Q11. `set varabbrev off` consistency in QOI files

| File | `set varabbrev off, perm`? |
|---|---|
| parentqoiclean1415.do | NO (only `set more off`) |
| parentqoiclean1516.do | NO |
| parentqoiclean1617.do | NO |
| parentqoiclean1819_1718.do | NO |
| secqoiclean1415.do | NO |
| secqoiclean1617.do | NO |
| secqoiclean1819_1718_1516.do | NO |
| staffqoiclean1415.do | YES (L11) |
| staffqoiclean1617_1516.do | YES (L11) |
| staffqoiclean1819_1718.do | NO |

**Inconsistent.** Only 2 of 10 QOI files (staff 1415 and staff 1617_1516) set `varabbrev off, perm`. Most files lack any `set varabbrev` at all. All 10 set `set more off` and `cap log close _all`. Also inconsistent vs. the schl_chars files in `cde_va_project_fork`, which all use `set varabbrev off` (without `, perm`).

---

## Cross-cutting bug summary

### Hardcoded asserts on IPEDS counts

`k12_postsec_distances.do` L50 (CSU=23), L54 (UC=9), L58 (private 4yr=115) — all three asserts are in place. Will halt the script on any IPEDS update that adds/removes institutions. Brittle for future replications.

### Hardcoded API keys (commented or otherwise)

One found: OpenCage API key at `k12_postsec_distances.do` L98, commented out but committed to git.

### In-place `save, replace` patterns

- `reconcile_cdscodes.do` L81 — overwrites `k12_postsec_mindistance.dta` produced upstream by `k12_postsec_distances.do`.

### Apple Silicon detection

`clean_charter.do` L26, L56 — both branches hardcode `Macintosh (Intel 64-bit)`, mis-routes M1/M2/M3+ Macs.

### Sex/gender encoding bugs

`caschls/do/build/prepare/enrollmentclean.do` L21-22 — missing-gender students bucketed as `female=0` (effectively male) without any `if mi(gender)` guard. Contrast with `cde_va_project_fork/.../clean_enr.do` L132-135 which correctly handles missing gender. Two parallel cleaners, divergent policies.

### Schema divergence handling

- `clean_staffdemo.do` L91 (fall 2014 only) vs. L250 (fall 2015+): two divergent loops. `fte` rowtotal in 2014 only (L227); per-race dummies commented out in 2014 (L172-198), active in 2015+ (L333-358); `age` only in 2015+ (L278). Downstream consumers (e.g., `clean_sch_char.do` L407) merge unconditionally and silently inherit the schema asymmetry.
- QOI files: per-year question coverage divergence (Q6 above). Without a centralized schema spec, downstream pooling needs to handle each year's available subset.

### Comment-vs-code drift

`renamedata.do` L77-89: comment claims to discard 5 single-digit-schl rows; code never drops them.

### Filename inconsistencies

Naming conventions in QOI files are mostly clean (file name = batch composition, e.g., `staffqoiclean1819_1718.do`). One small concern: `staffqoiclean1617_1516.do` lists 1617 first, but `secqoiclean1819_1718_1516.do` lists 1819 first. Different file order, but no functional impact.

### Other (file-level) concerns

- **L84 of `clean_acs_census_tract.do`** double-counts `s1501_c01_012e` in the tot_prop sanity check. No assert means silent.
- **2014–2017 ACS coverage missing.** `clean_acs_census_tract.do` only handles 2010–2013.
- **`clean_locale.do` L20** hardcodes 2015-16 NCES locale data; all schools across all years inherit the 2015-16 classification.
- **Dictionary file `acs_2017_gen_dict.do`** is meta-tooling and produces no data.

---

## Conclusions

The data-prep layer has many reasonable cleaning patterns (consistent variable creation, `compress`, label-preservation hacks where needed). But it has several real reproducibility hazards:

1. **Schema divergence is silent.** Year-batches with different question coverage (parent 1415 missing qoi 64 entirely, staff 1718/1819 missing `pctnotapp`, parent 1415 missing all `pct*` derivations) produce datasets with subtly different columns, and pooling code downstream must handle each batch's idiosyncrasies.
2. **In-place mutation patterns** in `reconcile_cdscodes.do` make pipeline replays fragile.
3. **Hardcoded asserts on external IPEDS counts** will halt the entire distance-build on any IPEDS schema change.
4. **Cross-user/cross-platform fragility** in `clean_charter.do` (Apple Silicon detection) and `acs_2017_gen_dict.do` (cd to server path).
5. **Comment-vs-code drift** in `renamedata.do` claims to drop rows that are not dropped.
6. **API key in source** (commented but committed).
7. **`female==0` for missing-gender students** in CalSCHLS enrollment cleaning is a silent encoding choice that diverges from the CDE-side cleaner.

For paper Tables 5/7 heterogeneity, the chain `clean_*_clean.dta → clean_sch_char.do → data/sch_char.dta → va_het.do` is intact. For the distance-FB row, the chain `k12_postsec_distances.do → k12_postsec_mindistance.dta → reconcile_cdscodes.do (in-place patch) → merge_k12_postsec_dist.doh → d_controls macro` is intact, with the caveat that only 2 of 5 `mindist_*` variables (`mindist_any_nonprof_4yr`, `mindist_ccc`) actually enter regressions.
