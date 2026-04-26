# Chunk 7 Deep-Read Report — Data Prep (ACS, school chars, distance, CalSCHLS prepare/QOI)

**Source repos**: `cde_va_project_fork` at `~/github_repos/cde_va_project_fork/`; `caschls` at the Dropbox path. Agent: general-purpose; report received 2026-04-25.

---

## Per-file entries

### File: cde_va_project_fork/do_files/acs/clean_acs_census_tract.do

**Owner**: Che Sun (Feb 2022). **Pipeline phase**: data_prep / acs. **Lines**: 368.
**Purpose**: Cleans ACS 5-year subject tables (S0601 population/race, S1501 education, S1702 poverty, S1901 income) at census-tract level for years 2010–2013, generates derived shares, merges 4 subject tables per year, then appends across years.
**Inputs**: `data/public_access/raw/acs/subject_tables/<year>/5yr/ACSST5Y<year>.<S0601|S1501|S1702|S1901>_data_with_overlays.csv`.
**Outputs**: per-year `data/public_access/clean/acs/acs_ca_census_tract_clean_<year>.dta` and master `acs_ca_census_tract_clean.dta`.
**Sourced helpers**: `do_files/sbac/macros_va.doh`.
**Gotchas / bugs**: (1) `tot_prop` check (line 84) double-counts `s1501_c01_012e` — only a `sum` not corruption. (2) **Hardcoded year list 2010–2013 only**; later years not processed. (3) `ignore("...")` strings differ across tables.
**Reference to paper**: feeds `merge_va_smp_acs.doh` (chunk 2) → ACS at student grade-6 census tract → `a/la/as/las` specs.

### File: cde_va_project_fork/do_files/acs/acs_2017_gen_dict.do

**Owner**: Che Sun. **Pipeline phase**: data_prep / acs (utility). **Lines**: 47.
**Purpose**: Generates variable-label data dictionaries for old-format 2017 ACS subject tables (which use `hc*` rather than `s*` naming).
**Inputs**: `$vaprojdir/data/public_access/raw/acs/subject_tables/2017/ACS_17_5YR_<subject>_with_ann.csv`.
**Outputs**: `$projdir/out/csv/acs/2017/acs_2017_<subject>_dict.{dta,csv}`.
**ssc/community packages**: `descsave`.
**Reference to paper**: NOT load-bearing for the paper. Master-audit "unreferenced" flag is correct.

### File: cde_va_project_fork/do_files/k12_postsec_distance/k12_postsec_distances.do

**Owner**: Paco Martorell (originator), Christina Sun (added 03/24/2023). **Pipeline phase**: data_prep / distance. **Lines**: 139.
**Purpose**: Computes minimum distance (miles) from each CA K-12 school to nearest postsecondary institution of various types. Loads IPEDS HD2021 + CDE pubschls.txt, joins all K-12 × higher-ed combos via `joinby`, runs `geodist`, collapses to `(min)` distance per K-12 school per institution type.
**Inputs**: `hd2021.do` (run via `run`); live URL `https://www.cde.ca.gov/schooldirectory/report?rid=dl1&tp=txt` (with fallback).
**Outputs**: `$distance_dtadir/clean/k12_postsec_distance.dta` (full pairwise) and `$distance_dtadir/clean/k12_postsec_mindistance.dta` (collapsed minimum: `mindist_uc`, `mindist_csu`, `mindist_pub4yr`, `mindist_any_nonprof_4yr`, `mindist_ccc`).
**ssc/community packages**: `geodist` (BC), `opencagegeo` (commented).
**Gotchas / bugs**: (1) **Hardcoded assertions** (lines 50, 54, 58: `r(N)==23` for CSU, `9` UC, `115` 4yr-non-profit) — will fail with future IPEDS releases. (2) Network-dependent live URL fetch. (3) **Hardcoded API key (line 98, commented)**: `"[REVOKED 2026-04-30]"` — opencagegeo personal key in source. (4) cdscode reconstruction lines 128–132 (float→string with leading-zero fix).
**Reference to paper**: **Producer of the distance/mindist variables that drive `_d_` controls AND the distance FB leave-out test (paper Tables 2/3 row 6)**.

### File: cde_va_project_fork/do_files/k12_postsec_distance/reconcile_cdscodes.do

**Owner**: Christina Sun (04/30/2023). **Pipeline phase**: data_prep / distance (post-hoc patch). **Lines**: 108.
**Purpose**: Patches `k12_postsec_mindistance.dta` to fix 11 CDS codes that don't match between VA sample and CDE pubschls (caused by school closures/mergers). Reads manual crosswalk CSV.
**Inputs**: `cdscode_changes.csv`; `k12_postsec_mindistance.dta`.
**Outputs**: **overwrites `k12_postsec_mindistance.dta` in-place via `save, replace` — line 81**.
**Gotchas**: (1) **In-place overwrite** — lossy if re-run; no provenance to recover original mindist file. (2) Line 78 silent unmatched-in-using rows from `merge nogen` accidentally correct.

### File: cde_va_project_fork/do_files/k12_postsec_distance/check_merge.do

**Owner**: Christina Sun. **Pipeline phase**: verification (one-shot). **Lines**: 20.
**Purpose**: Diagnostic: tabulates which `cdscode × year` rows in VA base sample failed to merge to mindist file.
**Outputs**: log only. Confirms master-audit flag — purely verification, archive-eligible.

### File: cde_va_project_fork/do_files/k12_postsec_distance/hd2021.do

**Owner**: NCES (auto-generated October 2022). **Pipeline phase**: data_prep / distance (sub-program). **Lines**: 4322.
**Purpose**: NCES-supplied data dictionary for IPEDS Header (HD) 2021 file. Auto-generated.
**Inputs**: `$distance_dtadir/raw/hd2021_data_stata.csv`.
**Outputs**: in-memory only (no `save`); returned to caller.
**Reference**: IS called by `k12_postsec_distances.do` via `run`. Master-audit "unreferenced" flag should be **removed**.

### File: cde_va_project_fork/do_files/schl_chars/cds_nces_xwalk.do

**Owner**: Che Sun. **Pipeline phase**: data_prep / schl_chars. **Lines**: 43.
**Purpose**: Builds CDS-code (CA) ↔ NCES 12-digit district+school ID crosswalk from CDE pubschls.txt.

### File: cde_va_project_fork/do_files/schl_chars/clean_locale.do

**Owner**: Che Sun. **Pipeline phase**: data_prep / schl_chars. **Lines**: 91.
**Purpose**: Cleans NCES EDGE 2015–16 geocode file to assign each CA school an urban/rural locale code. Builds both fine (12-cat) and coarse (4-cat: City/Suburb/Town/Rural) classifications.
**Gotchas**: locale snapshot is fixed at 2015–16 — does not vary over time.

### File: cde_va_project_fork/do_files/schl_chars/clean_charter.do

**Owner**: Matt Naven (origin), Che Sun (Feb 2022). **Lines**: 73.
**Purpose**: Per-school charter and public dummies from CDE School Directory.
**Gotchas**: (1) **Apple Silicon detection broken**: branches on `c(machine_type)=="Macintosh (Intel 64-bit)"` — won't catch `MacOSX (Apple Silicon)`. (2) Single snapshot (no year var) — treated as time-invariant.

### File: cde_va_project_fork/do_files/schl_chars/clean_ecn_disadv.do

**Owner**: Che Sun. **Lines**: 39.
**Purpose**: Computes school × year mean of `econ_disadvantage` from SBAC test-score microdata.
**Gotchas**: (1) Server-only path (restricted_access). (2) Output **misleadingly placed in `public_access/clean/`** despite being derivative of restricted data.

### File: cde_va_project_fork/do_files/schl_chars/clean_elsch.do

**Owner**: Matt Naven, Che Sun. **Lines**: 111.
**Purpose**: Loops over fall years, imports CDE English Learners (ELSCH) data, saves per-year cleaned files.
**Gotchas**: lots of pasted color-palette boilerplate (lines 28–67) — dead code.

### File: cde_va_project_fork/do_files/schl_chars/clean_enr.do

**Owner**: Matt Naven, Che Sun. **Lines**: 187.
**Purpose**: Imports CDE Census Day Enrollment per year, recodes ethnicity (CDE 0–9 codes) to coarser `race`, processes male/female via `gender`.
**Gotchas**: CDE-code `9` ("Two or More Races, Not Hispanic") mapped to `race==8`.

### File: cde_va_project_fork/do_files/schl_chars/clean_frpm.do

**Owner**: Matt Naven, Che Sun. **Lines**: 152.
**Purpose**: Cleans CDE Free/Reduced-Price Meals data per year. Reads .xls (older) or .xlsx (1718/1819).
**Gotchas**: (1) Hardcoded year-format branch (lines 102–107). (2) `cellrange(A2)` with `firstrow` — fragile to layout changes. (3) No assertions on row count.

### File: cde_va_project_fork/do_files/schl_chars/clean_staffcred.do

**Owner**: Matt Naven, Che Sun. **Lines**: 180.
**Purpose**: Cleans CDE staff credential records.
**Gotchas**: Authorization code list hardcoded at lines 119–154 — will be incomplete for new authorizations.

### File: cde_va_project_fork/do_files/schl_chars/clean_staffdemo.do

**Owner**: Matt Naven, Che Sun. **Lines**: 409.
**Purpose**: Cleans CDE staff demographic records. Two batches: 2014 special handling, 2015+ general.
**Gotchas**: **90% code duplication** between 2014-only and 2015+ blocks. Refactor candidate.

### File: cde_va_project_fork/do_files/schl_chars/clean_staffschoolfte.do

**Owner**: Matt Naven, Che Sun. **Lines**: 159.
**Purpose**: Cleans CDE Staff-School FTE assignment file.

### File: cde_va_project_fork/do_files/schl_chars/clean_sch_char.do

**Owner**: Matt Naven, Che Sun (Dec 2023). **Lines**: 549. **THE SCHOOL-CHARACTERISTICS ASSEMBLER.**
**Inputs**: enr/frpm/elsch/staffdemo/staffcred/staffschoolfte per-year cleaned files (loops over years), plus charter_status (m:1 — time-invariant) + ecn_disadv + pubschls_locale (m:1).
**Outputs**:
- **`data/sch_char.dta` — MASTER school × year panel** (the `sch_char.dta` referenced in `va_het.do` from chunk 4)
- `data/sch_char_<year>.dta` — per-year snapshots
**Gotchas**: (1) Output path `data/sch_char.dta` is **at top level**, not under `data/public_access/clean/` like its inputs — inconsistent. (2) Charter merged `m:1` with no year — time-invariant assumption.

### File: caschls/do/build/prepare/renamedata.do

**Owner**: Che Sun. **Lines**: 229.
**Purpose**: One-time loader/renamer. Imports raw CalSCHLS survey datasets across 4 instruments × 5–9 years and saves with short standard names.
**Gotchas**: (1) Special handling for parent 1415 only (separate cnty/dist/schl columns; reconstruction with leading-zero handling, hardcoded fix for county codes 2/7/9 → 02/07/09). (2) **Comment claims to "discard" 5 single-digit-school responses but code does NOT actually drop them** — leaves them with no leading zero.

### File: caschls/do/build/prepare/splitstaff0414.do

**Owner**: Che Sun. **Lines**: 40.
**Purpose**: Splits cumulative `staff0414.dta` (covering 2004-05 through 2013-14) into 10 per-year files.
**Gotchas**: `schlyear == 2004.2005` exact float comparison — relies on Stata storing the float exactly.

### File: caschls/do/build/prepare/enrollmentclean.do

**Owner**: Che Sun. **Lines**: 212.
**Purpose**: Cleans CDE enrollment files into school-level enrollment by grade × sex × ethnicity.
**Inputs**: `$projdir/dta/enrollment/raw/{enr1415..enr1819}.dta`.
**Outputs**: `$projdir/dta/enrollment/schoollevel/<enrXXXX>.dta` (5 files).
**Gotchas / bugs**:
1. **Heavy code duplication** — for each of 12 grades, 9 ethnicity categories processed via near-identical block.
2. **Female-encoding bug** (line 21): `gen byte female = 0` then `replace female = 1 if gender == "F"` — rows with missing gender become `female==0` (treated as male), polluting the male-by-grade totals. **Real bug.**

### File: caschls/do/build/prepare/poolgr11enr.do

**Owner**: Che Sun. **Lines**: 29.
**Purpose**: Pools school-level grade-11 enrollment across 2014–15 through 2018–19, computes per-school average (`gr11enr_mean`).
**Reference**: `gr11enr_mean` is the regression `_wt` weight token in chunk-4 sample-construction code.

---

### CalSCHLS QOI cleaning (year-batched files)

All ten QOI files share a common structure: load renamed survey file → keep cdscode plus question columns → rename to standard `qoi<N>` schema (where N is the 2018-19 question number) → recode response codes from 1–4-disagree-to-agree (with "5=don't know") into symmetric −2…+2 (with 0=neutral) → generate per-response dummies and per-school sums via `collapse (sum)` → also generate per-school means (`qoi<N>mean`) → compute `nettotalresp<N>`, `pctdisagree<N>`, `pctagree<N>`, `pctdontknow<N>` → tag with `year` → save as `<survey>qoiclean<batch>.dta`.

**Year-batch logic**:

| File | Years | Carve-out reason |
|---|---|---|
| `parent/parentqoiclean1415.do` | 1415 only | Different question numbering (`q*`, not `p*`); no qoi 30 32 34 64 |
| `parent/parentqoiclean1516.do` | 1516 only | Has `p*` but missing qoi 30/32/34 |
| `parent/parentqoiclean1617.do` | 1617 only | p numbering with renames; missing qoi 32 |
| `parent/parentqoiclean1819_1718.do` | 1718 + 1819 | Aligned numbering; year-loop |
| `secondary/secqoiclean1415.do` | 1415 only | Unusual `a#_a#` notation |
| `secondary/secqoiclean1617.do` | 1617 only | All `a*` shift by 1 vs 1819 |
| `secondary/secqoiclean1819_1718_1516.do` | 1516 + 1718 + 1819 | Aligned `a*` numbering across 3 years; year-loop |
| `staff/staffqoiclean1415.do` | 1415 only | Many ad-hoc renames; missing qoi 24 64 87 |
| `staff/staffqoiclean1617_1516.do` | 1516 + 1617 | Same renames; missing qoi 24 64 |
| `staff/staffqoiclean1819_1718.do` | 1718 + 1819 | Canonical numbering, no renames |

**Critical year-specific quirks**:

- **2017 carve-out** (parallel to v1 ELA 2017 carve-out): sec 1617 and parent 1617 each have unique do files due to unique question numbering.
- **Parent 1415 has `q*` not `p*`** — completely different naming.
- **Parent 1415 missing qoi 64** — produces only parent QOI dataset without `pctwell64`/`pctnotwell64`/`pctokay64` columns; downstream pooling needs to handle missing columns.
- **Staff 1718/1819 missing `pctnotapp`** for yes/no questions (the "not applicable" option was dropped); downstream pooling needs to handle missing columns.

**ssc/community packages**: `elabel` (renaming value labels), `labutil2`, `labundef`, `labdu`.

---

## Chunk 7 synthesis

### 1. Distance-FB Row 6 verdict — **FOUND** (resolves chunks 3-6 mystery)

The "distance" forecast-bias test row in paper Tables 2/3 row 6 is wired into the FB framework via the `d` token in `cde_va_project_fork/do_files/sbac/macros_va_all_samples_controls.doh`:

- **Producer**: `k12_postsec_distances.do` lines 121–124 creates `mindist_uc`, `mindist_csu`, `mindist_pub4yr`, `mindist_any_nonprof_4yr`, `mindist_ccc` and saves to `$distance_dtadir/clean/k12_postsec_mindistance.dta`.
- **Patcher**: `reconcile_cdscodes.do` reconciles 11 cdscode mismatches in-place.
- **Macro definition**: `macros_va.doh` has `local d_controls` = `mindist_any_nonprof_4yr mindist_ccc` (only 2 of 5 mindist vars enter regressions).
- **FB-test wiring** (`macros_va_all_samples_controls.doh`, change-log "04/30/2023: added minimum distance to postsecondary institutions as fb leaveout var"): the token `d` is added to *every* `*_ctrl_leave_out_vars` list (`b_ctrl_leave_out_vars`, ..., `las_ctrl_leave_out_vars`, plus `_scrhat` variants). Plus `local d_fb_<x>_samples` blocks define the samples used per VA-control × `d`-leaveout combo.
- **Consumer**: `va_score_fb_all.do` and `va_out_fb_all.do` loop `foreach fb_var of local <va_ctrl>_ctrl_leave_out_vars`. When `fb_var=="d"`, `\`fb_var'_controls` resolves to `mindist_any_nonprof_4yr mindist_ccc`, added to the VAM control set in the leave-out version.
- **Output**: `fb_<subject>_<sample>_sp_<va_ctrl>_ct_d_lv.ster`.
- **Tabulator**: `va_score_fb_test_tab.do` and `va_out_fb_test_tab.do` read these `.ster` files; the `_ct_d_lv` filename token identifies the distance-leaveout row.

Tables 2/3 row 6 = generated by chunk-3 tab files reading FB estimates that loop over `d` as one of the FB leaveout tokens — same as `l, a, s` — not a special row but one row in a generic loop. **Chunk 3's "fb_var ∈ {l, s, a, las}" finding was incomplete because the `d` token lives in `macros_va_all_samples_controls.doh` (briefly noted in chunk 2 but not its full FB integration).**

### 2. ACS data flow (backwards trace)

```
clean_acs_census_tract.do (years 2010-2013 only)
  reads: ACSST5Y<year>.{S0601,S1501,S1702,S1901}_data_with_overlays.csv
  appends → acs_ca_census_tract_clean.dta
        ↓
merge_va_smp_acs.doh (chunk 2)
  joins ACS at student grade-6 census tract on geoid2 + year
        ↓
sample-construction code in chunks 3-4
  → ACS becomes the a/la/as/las/asd/lasd controls
```

**Potential issue**: only 2010–2013 ACS years are processed. If grade-6 cohorts in the analysis sample span beyond 2013 (year=2018 → grade-6 = fall 2012 → ACS 2013 5-year ending in 2013 is the latest), coverage may be incomplete for some cohorts. **Worth verifying with user.**

### 3. School-characteristics dependency tree

```
cds_nces_xwalk.do      → cds_nces_id_xwalk.dta
        ↓
clean_locale.do        → pubschls_locale.dta (NCES EDGE 1516, time-invariant)
clean_charter.do       → charter_status.dta (CDE Schools Dir, time-invariant)
clean_ecn_disadv.do    → ecn_disadv.dta (from SBAC restricted data)
clean_elsch.do         → elsch_<year>_clean.dta (per year, English Learners)
clean_enr.do           → enr_<year>_clean.dta (per year, race/sex enrollment)
clean_frpm.do          → frpm_<year>_clean.dta (per year, free-lunch)
clean_staffcred.do     → staffcred_<year>_clean.dta (per year, credentials)
clean_staffdemo.do     → staffdemo_<year>_clean.dta (per year, teacher demos)
clean_staffschoolfte.do → staffschoolfte_<year>_clean.dta (per year, FTE)
        ↓ (all → input)
        ↓
clean_sch_char.do  ← THE ASSEMBLER (549 lines)
   → data/sch_char.dta             (master school × year panel)
   → data/sch_char_<year>.dta      (per-year snapshots)
        ↓ (consumed by)
        ↓
va_het/va_het.do  (chunk 4)
   → heterogeneity-by-school-characteristic tables (paper Table 5, Table 7)
```

`data/sch_char.dta` IS the same `sch_char.dta` referenced in `va_het.do` from chunk 4. **Top-level location** (not in `data/public_access/clean/cde/`) is a consolidation flag — normalize during migration.

### 4. CalSCHLS QOI cleaning year-batch logic

Year-batching reflects which years have IDENTICAL question numbering (so they can be processed in one year-loop). Year-specific quirks (parent 1415 q-vs-p convention; staff 1415 ad-hoc renames; sec 1617 +1 shift) force per-year files. **Schema divergences worth flagging**:

- Parent 1415 lacks qoi 64 columns (no `pctwell64`/etc.)
- Staff 1718/1819 lack `pctnotapp` columns (yes/no questions dropped that option)

Downstream pooling code must handle these missing columns.

### 5. New naming tokens / packages from chunk 7

**New tokens** (additions to chunks 1-6 catalog):

- `d` token's full FB-test integration (was partially seen; now nailed down)
- `mindist_<X>` (uc, csu, pub4yr, any_nonprof_4yr, ccc)
- `pseflag, c21ugprf, instcat, c18basic, f1sysnam` (IPEDS HD2021 filtering vars)
- `qoi<N>` canonical CalSCHLS variable indexed by 2018-19 question number
- `stragree<N>, agree<N>, disagree<N>, strdisagree<N>, dontknow<N>, missing<N>` per-school sums
- `pctagree<N>, pctdisagree<N>, pctdontknow<N>` per-school proportions
- `pctwell<N>, pctokay<N>, pctnotwell<N>` (only qoi 64)
- `pctyes<N>, pctno<N>, pctnotapp<N>` (only staff yes/no qois)
- `pctsmallprob<N>, pctbigprob<N>` (only staff qoi 98)
- `nettotalresp<N>` total responses excluding missing
- `gr<i>{enr,femaleenr,maleenr,<ethnic>enr}` caschls grade × school enrollment counts
- `gr11enr_mean` pooled-average grade-11 enrollment used as `_wt` weight
- `prop_ecn_disadv, enr_<race>_prop, enr_minority_prop, enr_majority_prop, enr_black_hisp_prop`
- `fte_teach_pc, fte_admin_pc, fte_pupil_pc`
- `male_prop, eth_minority_prop, new_teacher_prop, credential_full_prop`
- `locale_coarse, locale_fine`
- `charter, public`

**ssc packages**: nothing fundamentally new beyond chunks 1-6 catalog. `geodist`, `opencagegeo`, `elabel`, `labutil2`, `labundef`, `descsave` all confirmed used.

### 6. 17 new bugs/anomalies in chunk 7 (running total ≈52)

1. `clean_acs_census_tract.do:84` `tot_prop` sanity-check double-counts `s1501_c01_012e`.
2. `clean_acs_census_tract.do`: only processes 2010–2013; potential coverage gap for later cohorts.
3. `k12_postsec_distances.do:50,54,58`: hardcoded asserts (CSU=23, UC=9, 4yr-non-profit=115) — will break with future IPEDS releases.
4. `k12_postsec_distances.do:98`: hardcoded API key in commented-out opencagegeo line.
5. `reconcile_cdscodes.do:81`: in-place `save, replace` overwrites unpatched mindist file with no provenance.
6. `clean_charter.do:26`: Apple Silicon detection broken (`c(machine_type)=="Macintosh (Intel 64-bit)"`).
7. `clean_ecn_disadv.do:33`: writes restricted-data-derivative to `data/public_access/clean/cde/` — misleading folder.
8. `clean_sch_char.do:532`: writes to top-level `data/sch_char.dta` instead of `data/public_access/clean/cde/sch_char.dta`.
9. `clean_sch_char.do`: charter and locale merged `m:1` (no year) — time-invariant assumption.
10. `clean_staffdemo.do`: 90% code duplication between 2014-only and 2015+ blocks.
11. **`enrollmentclean.do:21` female-encoding bug**: `gen byte female = 0` then `replace female = 1 if gender == "F"` — missing-gender rows become `female==0` (treated as male), polluting male-by-grade totals. **Real bug.**
12. `enrollmentclean.do`: massive code duplication (12 grades × 9 ethnicity blocks).
13. `renamedata.do:77-84`: comment claims to "discard" 5 single-digit-school responses in parent 1415, but the code does NOT actually drop them.
14. QOI files: `set varabbrev off` (not `, perm`) inconsistently set.
15. QOI 1718/1819 staff vs 1516/1617 staff: schema divergence (`pctnotapp` only in latter); pooling must handle missing columns.
16. Most QOI files: extensive dead code in commented-out fallback blocks.
17. `hd2021.do` (4322 lines): auto-generated NCES dictionary; treat as opaque blob, replace wholesale when IPEDS year updates.

### 7. Open questions

**For user**:

- Are 2014+ ACS years covered somewhere outside `clean_acs_census_tract.do`? Grade-6 cohorts may need ACS coverage beyond 2013.
- Is the `enrollmentclean.do` female-encoding bug (missing-gender → male totals inflated) known? Does the analysis sample restrict to non-missing gender, masking the bug downstream?
- Should `reconcile_cdscodes.do` write to a *new* file rather than overwriting unpatched?
- Is `data/sch_char.dta` (top-level) the intended final location?

**For chunks 8-10**:

- Chunk 8: trace `gr11enr_mean` weight through regression code; confirm it is the `_wt` token.
- Chunk 9: locate Python upstream geocoding scripts that assign students to census tracts.
- Chunk 10 (probable buildanalysisdata pooling): trace how `<survey>qoiclean<YYYY>.dta` files are appended/pooled. Confirm schema divergences (missing qoi 64 in parent 1415; missing `pctnotapp` in staff 1718/1819) are handled rather than producing silent missingness.
