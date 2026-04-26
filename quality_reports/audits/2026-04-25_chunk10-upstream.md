# Phase 0a — Chunk 10: Upstream / Python (FINAL)

**Scope:** Python geocoding scripts plus the three Stata upstream crosswalks (`crosswalk_nsc_outcomes.do`, `crosswalk_ccc_outcomes.do`, `crosswalk_csu_outcomes.do`) and caschls's local-machine ad-hoc do files.

**Read-time inventory.** `cde_va_project_fork/py_files/` contains a single file: `sbac/gecode_json.py`. The audit doc's "caschls/py/" path does not exist — the caschls repo (Dropbox-resident at `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/`) has no `py/` directory. The other on-disk predecessor (`ca_ed_lab-common_core_va`, the upstream of cde_va_project_fork) has a byte-identical `py_files/sbac/gecode_json.py`. The third path mentioned (`common_core_va_workflow_merge`) also has the same identical copy. A single Python script is the entire Python surface area of this codebase.

---

## Per-file entries

### File: `cde_va_project_fork/py_files/sbac/gecode_json.py`

**Owner:** Matt (file is identical across all three predecessor repos; no Christina edits).

**Pipeline phase:** upstream geocoding (one-shot batch).

**Lines:** 117.

**Language:** Python 3 (uses f-strings absent; `print()` calls are function-form so Python 3-compatible).

**Purpose (1-2 sentences):** Reads a tab-delimited CSV of student addresses (`address_list_census.csv`) and calls the Census Bureau's free Geocoder API one address at a time, writing back a tab-delimited CSV (`address_list_census_geocoded2.csv`) with `census_block_geoid`, `census_tract`, `census_state`, `census_county`, lat/lon, and a few other fields. There is no batch endpoint use; this is one HTTP request per address.

**Inputs:**
- `/home/research/ca_ed_lab/common_core_va/data/sbac/address_list_census.csv` (tab-delimited; first row is header; columns: `address_id`, `street_address_line_one`, `city`, `state`, `zip_code`).

**Outputs:**
- `/home/research/ca_ed_lab/common_core_va/data/sbac/address_list_census_geocoded2.csv` (tab-delimited; 13 columns).

**External dependencies:**
- Census Bureau Geographies onelineaddress/address API (`https://geocoding.geo.census.gov/geocoder/geographies/address`), benchmark=9, vintage=910. **Free, no API key required**. Public endpoint — see https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.pdf.

**Sourced helpers / Calls:** none — single self-contained script.

**Path references (TBD list):**
- `home = "/home/research/ca_ed_lab/common_core_va"` (line 9) — server-absolute, will need to become `$vaprojdir` or a relative path.
- Two file paths derived from `home` (lines 10-11).

**Stata version / Python version + key packages:**
- Python 3 (functional `print`); `requests`, `csv`, `time`, `re`, `json`, `os` (stdlib only) plus `lxml.html` (imported but **never used** — dead import).

**ssc/Python packages:** `requests` (HTTP), `lxml` (imported only — not invoked).

**Gotchas / bugs (line numbers):**

1. **Lines 36-57: broken control flow.** The `while True:` block has `try/except/else` where the `else:` branch always prints `"Other Error"` and breaks — meaning the loop only exits via `else`, which fires on success. But each `except` does `page.close()` (the failed `requests.get` did not return a response, so `page` is undefined the first iteration → `NameError` would crash the script). In practice, exceptions are silently caught, retry, and the script keeps going. The structure is unusual: `try` → success → `else` (Other Error) → `break`. The exception handlers `continue` so they retry indefinitely on connection error / timeout. **No exit condition for repeated failures** — could loop forever on a bad address.
2. **Line 9: hardcoded server-absolute path.** Will not run anywhere but the Scribe `common_core_va` server.
3. **Line 1: dead import.** `from lxml import html` — never used.
4. **No rate-limit handling.** `time.sleep(.5)` (line 115) is a fixed 500ms between requests. Census Geocoder API has no documented rate limit but this is not robust to throttling.
5. **No idempotency / resume.** Lines 33-36: `if (index==0): continue` — manual restart logic. The script overwrites the entire output file (`"w+"` on line 12) on each invocation, so a partial run is lost.
6. **Line 31: zero string sanitization.** `street_address_line_one`, `city`, `zip_code` are URL-concatenated into the Census API request without `urllib.parse.quote()`. Apostrophes, ampersands, or `#` characters in addresses (the commented-out lines 26 hint Matt knew about `#`) will produce malformed URLs. The commented-out `address_census.replace("#", "")` is the workaround that was abandoned for the structured-address endpoint.
7. **No deduplication.** Each row is geocoded independently. If `address_list_census.csv` has duplicates, all duplicates are queried. Comparing with the `va_cfr_forecast_bias.do:589-594` consumer, duplicates are dropped post-geocoding inside Stata, so the API was likely called more often than necessary.
8. **Test for inclusion of header row is by index 0** (line 34). Brittle.

**Reference to paper outputs:**
- Output CSV `address_list_census_geocoded2.csv` is the source of `address_list_census_batch_geocoded.csv` (note the rename and the suffix change `_geocoded2` → `_batch_geocoded`) consumed by `va_cfr_forecast_bias.do:564` and by `merge_va_smp_acs.doh` (chunk 2). That ACS-tract merge is what feeds the seven census-tract demographic controls into the VA Table 4-7 controls block.
- **Important rename:** the script writes `_geocoded2.csv`. The downstream Stata code reads `_batch_geocoded.csv`. Either someone manually renamed the file before checking it into `data/restricted_access/clean/crosswalks/` on the server, or there is a one-shot manual step missing from this audit. **This is an undocumented breakpoint between the Python output and the Stata consumer.**

**Notes / open questions:**

- The script name "gecode" is a typo for "geocode" — it has propagated unchanged through three repos, suggesting nobody re-runs this often.
- Per ADR-0003 (languages: Stata primary, Python preserved for upstream geocoding), this file's role is exactly as expected. After consolidation it can move to `py/sbac/geocode_addresses.py` (rename for spelling) or stay as-is.
- **Static cache assumption:** because output is committed to `data/restricted_access/clean/crosswalks/` on the server, this script is **run once and cached**. It is not invoked by any do-file; no `shell python ...` call exists. **Nobody re-runs this except by hand.**
- For the consolidated repo, this file should keep ADR-0003's exemption (Python is allowed for one-off geocoding) but should be moved into `py/sbac/` and the path replaced with `$vaprojdir`.

---

### File: `cde_va_project_fork/do_files/upstream/crosswalk_nsc_outcomes.do`

**Owner:** Christina (header: "First created by Che Sun March 17, 2022, ucsun@ucdavis.edu, Based on code from Matt Naven"). Christina-edited fork of Matt's original.

**Pipeline phase:** upstream crosswalk producer (Stata).

**Lines:** 428.

**Language:** Stata 16.1.

**Purpose (1-2 sentences):** For each high school graduation cohort 2010–2020, take a fresh per-cohort NSC dataset (cleaned by Kramer at `$nscdtadir/nsc_xgyr<gradyear>.dta`), merge SSID-keyed students from the K-12 panel (built via `append_k12_all_data.doh`), generate ~60 college-enrollment / persistence / degree indicators, collapse to one observation per state_student_id per cohort, then `append` all 11 cohorts together and collapse again to produce the final wide-format `nsc_outcomes_crosswalk_ssid.dta`.

**Inputs:**
- `$nscdtadir/nsc_xgyr2010.dta` ... `$nscdtadir/nsc_xgyr2020.dta` (11 files).
- `$cstdtadir/...` (test-score panel, transitively via `append_k12_all_data.doh` line 55).

**Outputs:**
- `$vaprojxwalks/nsc_xwalk_intermediate/nsc_outcomes_crosswalk_xgyr2010.dta` ... `_xgyr2020.dta` (intermediate).
- `$vaprojxwalks/nsc_outcomes_crosswalk_ssid.dta` (final — ONE OF the 5 inputs to `merge_k12_postsecondary.doh`).
- `log_files/crosswalk_nsc_outcomes.smcl/.log`.

**External dependencies:** none.

**Sourced helpers / Calls:**
- `do $vaprojdir/do_files/append_k12_all_data.doh "*_student_id cdscode year grade birth_date"` (line 55).

**Path references (TBD list):**
- `cd $vaprojdir` (line 20).
- `$nscdtadir`, `$vaprojxwalks` (must be defined in `settings.do`).

**Stata version:** `version 16.1` (line 1).

**ssc/Python packages:** none — pure base Stata + `egen tag()`.

**Gotchas / bugs (line numbers):**

1. **Line 34: `set trace on`** — production crosswalk runs with full trace logging. Slows execution and bloats the smcl log. Almost certainly debugging detritus.
2. **Line 250: `egen college_begin_date = min(enrollmentbegin), by(\`id' collegecodebranch)`** — references a local macro `\`id'` that is not defined anywhere in this script. Would expand to empty, so `by()` would group by `collegecodebranch` only — silently incorrect. Either dead code (verify by checking smcl log) or a copy-paste leftover from Matt's original.
3. **Lines 318-339, 388-409: `foreach v of varlist ... nsc_enr_n_4year nsc_enr_n_2year nsc_enr_n_lt2year nsc_enr_n_4year nsc_enr_n_2year nsc_enr_n_lt2year`** — same three vars listed twice (typos, harmless: the second `replace ... if mi()` is a no-op).
4. **Line 219: `inlist(collegecodebranch, ..., "041271-00") | inlist(collegecodebranch, "001319-00")`** — the parenthesis grouping is wrong. The `& recordfoundyn=="Y"` only binds to the first inlist. Operator precedence makes this `(A & B) | C` rather than `A & (B | C)`. So `nsc_enr_uc = 1 if recordfoundyn=="Y" & first-inlist OR collegecodebranch=="001319-00"` — UC Merced (`001319-00`) gets coded as enrolled even when there's no NSC record. **Probably a bug**. Same pattern lines 222, 228, 232 (ucplus and ontime variants).
5. **Line 420: `erase \`k12students'`** — `erase` on a `tempfile` macro path. Stata cleans tempfiles automatically; explicit erase is redundant but harmless.
6. **Two `collapse (max)` rounds (lines 296, 366):** intermediate per-cohort and then final cross-cohort. Logically fine but means a student matched in two cohorts (e.g., 11th grade in 2013 plus 10th grade in 2013 by the line-58 special case) gets the max across cohorts — likely intended.

**Reference to paper outputs:**
- `nsc_outcomes_crosswalk_ssid.dta` is the upstream dependency of every NSC outcome variable in the paper (`nsc_enr`, `nsc_enr_4year_pub`, `nsc_enr_uc`, `nsc_persist_year2`, `nsc_deg`, etc.). These flow into `merge_k12_postsecondary.doh:79-90` and ultimately into outcome-VA tables (Tables 4-7) and any postsecondary-outcome panel/figure.

**Notes / open questions:**
- Heavy refactor by Christina vs. archived Matt original (per `_archive/crosswalk_nsc_outcomes_deprecated.do`). The Christina version pivots from Matt's monolithic single-cohort logic to per-cohort loop + cohort append. Cleaner. The deprecated version uses a distinctly different data structure and is correctly archived.
- The bug in line 219 (UC inlist precedence) is **load-bearing** for `nsc_enr_uc` and `nsc_enr_ucplus`, both of which appear as outcomes in the paper.

---

### File: `caschls/do/upstream/crosswalk_ccc_outcomes.do`

**Owner:** Matt (header: "First created by Matthew Naven on February 25, 2018"). Pristine Matt code. Christina has not modified.

**Pipeline phase:** upstream crosswalk producer (Stata).

**Lines:** 255.

**Language:** Stata 15.0.

**Purpose:** Produce `ccc_outcomes_crosswalk.dta` — one observation per CCC `STUDENT_ID` with enrollment / remediation / persistence / degree indicators in wide format.

**Inputs:**
- `\`ccc'/Raw/SXENRLM.dta` (Student Exchange Enrollment).
- `\`ccc'/Raw/STUDNTID.dta` (CCC student id mapping).
- `\`ccc'/Raw/CBCRSINV.dta` (course inventory; for `CB_BASIC_SKILLS_STATUS` and `CB_TOP_CODE`).
- `\`ccc'/SPAWARDS_studentID.dta` (CCC awards).
- `\`ccc' = "/secure/ca_ed_lab/Community_College/data"` on Sapper (line 17).

**Outputs:**
- `restricted_access/clean/crosswalks/ccc_outcomes_crosswalk.dta` (final).
- `log_files/crosswalk_ccc_outcomes.smcl/.log`.

**External dependencies:** none.

**Sourced helpers / Calls:** none.

**Path references (TBD list):** lines 8-19 (3 `if c(machine_type)/c(hostname)` branches, all defining `local home`); line 19 `cd \`home''`; line 244 `restricted_access/clean/crosswalks/...` (relative to `cd`).

**Stata version:** `version 15.0` (line 1).

**ssc/Python packages:** none — pure base Stata + `egen tag()`.

**Gotchas / bugs (line numbers):**

1. **Line 60, 69: merge then immediately `rename` back.** Pattern: `rename A B / merge / rename B A`. Cosmetic but bloats code.
2. **Lines 76-84: term parsing assumes 3-digit format.** `tostring SX_TERM_ID, replace format("%03.0f")` then string-substr the year and term. Works for `SX_TERM_ID` like `001` (2000 term 1), `095` (1995 term 5), etc. Robust as long as no 4-digit terms exist.
3. **Lines 78-79: year cutover hardcoded** at `(00, 20)`. Assumes any 2-digit year between 00 and 20 is 2000s, between 92 and 99 is 1990s. **Will silently miscode any term ID for academic year 2021+** (year would be `21`, not in `[00, 20]`, falls through to nothing → year is empty string, destring returns missing). Update needed for newer cohorts. Christina's data extends to 2020 graduation cohorts, so unaffected as of this audit, but a hard cliff exists at 2021 enrollment.
4. **Lines 89-99: ELA / math remediation coding** uses `CB_TOP_CODE` first 2 digits == "15" (ELA) or "17" (math). These are CCC TOP code prefixes. Hardcoded but stable.
5. **Lines 227-237: persist_year2 / persist_year3 censoring** uses `inlist(ccc_enr_start_year, 2016)` and `2017`. Hardcoded recent-year censoring assumes the data goes through some specific final term. Will need updating if the data extension extends.
6. **Line 19: `cd \`home''`** — changes Stata's cwd. Good practice.
7. **Lines 252-254: `if c(hostname)=="sapper" exit, STATA clear`** — auto-shutdown on the server. This means running this do file as part of a master script on Sapper would terminate the master at this point. **Master compatibility hazard** — if `crosswalk_ccc_outcomes.do` is `do`'d from another master file, the entire master exits. Confirm this is run standalone only.

**Reference to paper outputs:**
- `ccc_outcomes_crosswalk.dta` → consumed by `merge_k12_postsecondary.doh:152-154` → produces `ccc_enr`, `ccc_persist_year2`, `ccc_persist_year3`, `ccc_deg`, etc., all CCC outcomes used in outcome-VA tables.

**Notes / open questions:**
- This is Matt's pre-fork code, server-coupled (`if c(hostname)=="sapper"` branch). The Christina/Scribe pipeline must rebrand `\`home'` and `\`ccc'` for the new server. **Currently completely incompatible with the cde_va_project_fork's settings.do globals.** Since both upstream files (this and CSU below) live in caschls (Matt's untouched copy), they were Matt's responsibility, not Christina's. They are upstream of Christina's refactor.
- The **unique student ID for CCC** is `STUDENT_ID` (capital, line 103 onward), but the merger key in `merge_k12_postsecondary.doh:152` is `student_id` (lowercase). Either Matt's `restricted_access/clean/crosswalks/ccc_outcomes_crosswalk.dta` was post-renamed to lowercase by another upstream script, or this entire pipeline never ran successfully end-to-end against the merge step. **Possible silent breakage** — should be verified against the actual `.dta` schema on Scribe.

---

### File: `caschls/do/upstream/crosswalk_csu_outcomes.do`

**Owner:** Matt (header: "First created by Matthew Naven on February 20, 2018"). Pristine Matt code.

**Pipeline phase:** upstream crosswalk producer (Stata).

**Lines:** 547.

**Language:** Stata 15.0.

**Purpose:** Produce `csu_outcomes_crosswalk.dta` — one observation per CSU `idunique` with applied/accepted/enrolled/persistence/degree indicators plus CSU-specific GPAs and STEM/Other major coding in wide format.

**Inputs:**
- ERA (CSU applied) panel: `\`csu'/era/era<year><semester>.dta` for years 1997–2017.
- ERS (CSU enrolled) panel: `\`csu'/ers/ers<year><semester>.dta`.
- ERD (CSU degree) panel: `\`csu'/erd/erd<year>{,<semester>}.dta`.
- `\`csu' = "/secure/ca_ed_lab/data/restricted_access/clean/csu actually clean"` (line 17).

**Outputs:**
- `restricted_access/clean/crosswalks/csu_outcomes_crosswalk.dta`.
- `log_files/crosswalk_csu_outcomes.smcl/.log`.

**External dependencies:** none.

**Sourced helpers / Calls:** none.

**Path references (TBD list):** lines 8-19 same machine-branching pattern as `crosswalk_ccc_outcomes.do`.

**Stata version:** `version 15.0`.

**ssc/Python packages:** none.

**Gotchas / bugs (line numbers):**

1. **Lines 215-238 (and 240-263, 276-298, 301-323, 400-422, 425-447): `csu_first_maj_stem` / `csu_first_maj_other` / `csu_deg_stem` / `csu_deg_other`.** Hardcoded majordd-code-to-STEM mapping table, ~22 codes each, four near-identical blocks. Maintainability nightmare — any CSU classification update requires editing 4 places. No FK to a labelled value-label or external lookup. **Code 14 is silently missing from all four blocks** — line 230 jumps from majordd==13 to majordd==15 (and same in subsequent blocks). Code 14 students would have all four flags missing, then defaulted to 0 in the cleanup blocks 502-503. Probably intentional (CSU dropped code 14 at some point) but undocumented.
2. **Lines 56-78: `forvalues year` blocks with `forvalues semester` inner loops.** Different year ranges have different valid semesters. Hardcoded ad-hoc. If a year is missing, `append using` silently fails (Stata `append using` with a non-existent file errors out). Brittle.
3. **Lines 369-371: ERD append loop** runs `forvalues year = 2002 (1) 2016 { append using \`csu'/erd/erd\`year'.dta }` with NO semester suffix — but the previous loops (lines 345-368) DID use semester suffixes. Two file-naming conventions: `erd<year><semester>.dta` AND `erd<year>.dta` for years 2002–2016. **Files for years 2002-2007 with semester loops AND year-only loops will append duplicates.** Need to verify against actual data; if both file forms exist with overlapping content, lines 451-460 collapse will dedupe by `idunique` but variable-by-variable (max/firstnm/lastnm) which may mis-aggregate.
4. **Line 396: `csu_deg_ontime = real(string(...) + string(...)) < real(string(...) + string(...))`** — string-concatenated year and term. Brittle if term goes to 2 digits.
5. **Lines 506-515: persist year censoring** hardcodes `inlist(csu_enr_start_year, 2017)`, `(2016, 2017)`, `(2015, 2016, 2017)`. Same hardcoded-cohort-cutoff problem as CCC.
6. **Line 19: `cd \`home''`.**
7. **Lines 544-546: `if c(hostname)=="sapper" exit, STATA clear`** — same auto-shutdown gotcha.

**Reference to paper outputs:**
- `csu_outcomes_crosswalk.dta` → consumed by `merge_k12_postsecondary.doh:217-218` → produces `csu_enr`, `csu_persist_year2/3/4`, `csu_deg`, `csu_deg_stem`, `csu_first_maj_stem`, etc.

**Notes / open questions:**
- Same merge-key concern as CCC: this file's wide table is keyed on `idunique`, and `merge_k12_postsecondary.doh:217` uses `idunique` — consistent. Good.
- Hardcoded STEM-coding table is the highest-priority technical-debt item in this file. A lookup CSV with `(majordd, stem_yes_no)` would replace 88+ lines.

---

### File: `caschls/do/local/enrollmentconvert.do`

**Owner:** Christina (header: "written by Che Sun. Email: ucsun@ucdavis.edu").

**Pipeline phase:** upstream — local one-shot data conversion (CDE public enrollment files → dta).

**Lines:** 76.

**Language:** Stata.

**Purpose:** Convert CDE public enrollment text files (`enr1415.txt` through `enr1819.txt`, downloaded from https://www.cde.ca.gov/ds/sd/sd/fsenr.asp) into Stata dta files in `./dta/cln/`. Renames raw column names (`gr_1` → `gr1enrl`, etc.), labels variables, defines an ethnicity value label, casts cdscode to a 14-digit string.

**Inputs:**
- `./dta/raw/enr1415.txt`, ..., `./dta/raw/enr1819.txt` (5 files; tab-delimited per CDE public format).

**Outputs:**
- `./dta/cln/enr1415.dta`, ..., `./dta/cln/enr1819.dta` (5 files).

**External dependencies:** none.

**Sourced helpers / Calls:** none.

**Path references:** All relative to `./dta/raw/` and `./dta/cln/`. No globals — comment line 8 explicitly notes "This is a local do file. Global settings for Scribe server do files don't apply".

**Stata version:** none specified.

**ssc/Python packages:** none.

**Gotchas / bugs:**

1. **Lines 21-75: `foreach i of local enrlrawname`** but the `local enrlrawname` only includes 2014/15 through 2018/19 — does not extend to 2019/20 or 2020/21. Dataset is **time-frozen at 2018/19**. Either Christina re-runs this manually with new years appended to the local, or the conversion has not been refreshed.
2. **Line 13: comment says `cd "D:\Programs\Dropbox\..."`** — Christina's Windows machine path. Confirms this is a local-machine ad-hoc utility, not a server pipeline component.
3. **Lines 21, 75: no log file.**
4. **No `set seed`** — but no random ops, so harmless.
5. The output dtas (`enr1819.dta` etc.) are NEVER consumed by any in-scope do file in `caschls/do/master.do` or `cde_va_project_fork/do_files/do_all.do`. **Dead artifacts as far as the production pipeline is concerned.** Probably feeds an exploratory analysis or an old talk that has since been superseded.

**Reference to paper outputs:** None directly — these are CDE public enrollment counts, not student-level test scores. May feed `schl_chars/` indirectly but no grep evidence.

**Notes / open questions:**
- Per Round-2 archival decision (logged in `_round2-dispositions.md`), this file landed in `caschls/do/local/`. Verdict: keep as-is in the consolidated repo's `do/local/` (or equivalent). Local utilities live in their own bucket.
- Even if dead, preserving it costs nothing and signals "this is the script that made the public-enrollment dtas if you ever need them."

---

### File: `caschls/do/local/siblingtest.do`

**Owner:** Christina.

**Pipeline phase:** local sandbox — pure exploration / scratch work for the sibling-matching algorithm.

**Lines:** 22.

**Language:** Stata.

**Purpose:** A one-off algorithm-testing scaffold for the sibling-deduplication algorithm — uses fake test data (`siblingtest.csv`) to prototype the `group_twoway` step that ultimately landed in `caschls/do/share/siblingxwalk/uniquefamily.do` (chunk 5).

**Inputs:** `./dta/raw/siblingxwalk/siblingtest.csv`.

**Outputs:** `./dta/cln/siblingxwalk/siblingtest.dta`.

**External dependencies:** `group_twoway` (ssc package — already inventoried).

**Sourced helpers / Calls:** none.

**Path references:** `cd "D:/Programs/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls"` (line 3, Windows-machine local).

**Stata version:** none.

**ssc packages:** `group_twoway` (used elsewhere; already in inventory).

**Gotchas:** none load-bearing.

**Reference to paper outputs:** None. Pure prototyping scratch.

**Notes:** Keep alongside `enrollmentconvert.do` in `do/local/`. Both are local-machine scratch files preserved for transparency/lineage.

---

## Chunk 10 synthesis

### 1. Geocoding pipeline picture (Python's role)

The pipeline has **exactly one Python script** — `gecode_json.py` — and it does **one thing**: read a tab-delimited CSV of student addresses, query the Census Bureau Geographies API one row at a time, and write a tab-delimited CSV with `census_block_geoid`, `census_tract`, `census_state`, `census_county`, lat/lon, and a few other Census Block fields.

**Concrete answers to the chunk-10 questions:**

| Q | Answer |
|---|---|
| Which Python script geocodes addresses? | `gecode_json.py` (the only Python file in the entire codebase). |
| What service is used? | **U.S. Census Bureau Geographies API** (`geocoding.geo.census.gov/geocoder/geographies/address`), benchmark=9, vintage=910. **Free, no API key required**. NOT OpenCage, NOT Google. (OpenCage is referenced separately in `k12_postsec_distances.do:98` for K-12-school-to-postsecondary distance — see Q below.) |
| What is the input? | `address_list_census.csv` — tab-delimited CSV of unique student addresses, columns `address_id, street_address_line_one, city, state, zip_code`. **The script that produces this CSV is NOT in any in-scope repo** — it is upstream of Matt's K-12 cleaning. |
| What is the output? | `address_list_census_geocoded2.csv` (tab-delimited, 13 cols including `census_block_geoid`, lat/lon, `census_tract`). After a manual rename to `address_list_census_batch_geocoded.csv` (note: rename happens between Python output and Stata consumer — undocumented), this file is loaded by `va_cfr_forecast_bias.do:564` and by `merge_va_smp_acs.doh` (chunk 2). |
| API keys hardcoded? | **No** — Census Geocoder API is free and keyless. |
| Static or re-run? | **Run once and cached.** The output sits in `data/restricted_access/clean/crosswalks/` on Scribe and is never re-invoked from any do-file. Re-running requires manual execution of the .py script and the `_geocoded2 → _batch_geocoded` rename. |

### 2. Distance pipeline (chunk 7 finding revisited)

`k12_postsec_distances.do` (chunk 7) consumes K-12 school latitudes and longitudes from the **CDE School Directory** (`pubschls.txt`-like file) — NOT from a separate Python geocoding step. CDE publishes school addresses with lat/lon directly, so geocoding is not needed for K-12 schools. Only **student home addresses** go through `gecode_json.py`. Postsecondary lat/lon comes from IPEDS HD2021 (chunk 7). Chunk 7's `geodist`-based distance computation needs both, neither involves Python.

Confirmed: **geocoding via Python is exclusively for student home addresses → census tract → ACS demographics**.

### 3. Cross-repo crosswalk producer table (resolves chunk-2 dependency)

Per `merge_k12_postsecondary.doh`, FIVE `.dta` crosswalks are consumed. Each is split into a "K12-link" component (SSID-to-system-id) and an "outcomes" component (system-id-to-outcomes). Producer table:

| Consumed dta | Role | Producer in scope? | Producer file |
|--------------|------|---------------------|----------------|
| `nsc_outcomes_crosswalk_ssid.dta` | NSC outcomes (keyed on SSID directly — NSC has no separate id) | YES | `cde_va_project_fork/do_files/upstream/crosswalk_nsc_outcomes.do` (Christina, 2022) |
| `k12_ccc_crosswalk.dta` | SSID → CCC `student_id` mapping | **NO** | Upstream of all in-scope repos — Matt's pipeline at `/home/research/ca_ed_lab/users/msnaven/...` (presumed) |
| `ccc_outcomes_crosswalk.dta` | CCC `student_id` → CCC outcomes | YES | `caschls/do/upstream/crosswalk_ccc_outcomes.do` (Matt, 2018, untouched) |
| `k12_csu_crosswalk.dta` | SSID → CSU `idunique` mapping | **NO** | Upstream of all in-scope repos — Matt's external pipeline (presumed) |
| `csu_outcomes_crosswalk.dta` | CSU `idunique` → CSU outcomes | YES | `caschls/do/upstream/crosswalk_csu_outcomes.do` (Matt, 2018, untouched) |

**Critical out-of-scope dependency:** `k12_ccc_crosswalk.dta` and `k12_csu_crosswalk.dta` are consumed but never produced inside our repos. They must come from Matt's `/home/research/ca_ed_lab/users/msnaven/` pipeline. **For replication / reproducibility, these are external "data inputs" treated as static** — like the cleaned k12 panel.

### 4. lag2ela / upstream-data summary

`merge_lag2_ela.doh` (chunk 2) reads `L4_cst_ela_z_score` and `L5_cst_ela_z_score` from `k12_lag_test_scores_clean.dta`. **No do-file in any in-scope repo produces this file** — verified by grep. Producer is upstream Matt cleaning at `/home/research/ca_ed_lab/users/msnaven/...` per the audit assumption. Treated as **static data input** for our pipeline, alongside `k12_test_scores_clean.dta`, `k12_ccc_crosswalk.dta`, and `k12_csu_crosswalk.dta`.

### 5. Out-of-scope upstream dependencies (consolidated list)

These are files the pipeline reads but no in-scope script produces. They must be treated as **immutable external data inputs** in the consolidated repo:

| File | Where it lives on Scribe | Producer |
|------|---------------------------|----------|
| `k12_test_scores_clean.dta` | `data/restricted_access/clean/k12_test_scores/` | Matt's external pipeline |
| `k12_lag_test_scores_clean.dta` | same | Matt's external pipeline |
| `k12_ccc_crosswalk.dta` | `data/restricted_access/clean/crosswalks/` | Matt's external pipeline |
| `k12_csu_crosswalk.dta` | same | Matt's external pipeline |
| `address_list.dta` | same | Matt's external pipeline (or Christina, untraced) |
| `address_list_census.csv` | `data/sbac/` | Upstream of `gecode_json.py` |
| `nsc_xgyr<year>.dta` | `data/restricted_access/clean/nsc/` | Kramer (NSC clean) |
| `acs_ca_census_tract_clean.dta` | `data/public_access/clean/acs/` | `cde_va_project_fork/do_files/acs/clean_acs_census_tract.do` (in scope! chunk 7) |
| `pubschls.txt` and IPEDS HD2021 | `data/public_access/cde_school_directory/` and `data/ipeds/` | CDE / NCES (public) |

The consolidated repo's `data/raw/` should bind these as a manifest. Replication scope = our 100+ in-scope do files + py script + this static input set.

### 6. Final naming / package tally vs. chunks 1-9

**No new package names beyond chunks 1-9.** The crosswalk_csu/ccc/nsc files use only base Stata + `egen tag()`. The Python script uses stdlib + `requests` + (unused) `lxml`. No new ssc packages. Inventory remains at the ~16 listed.

**Naming grammar** — no new tokens. The crosswalk-stage outputs follow `<system>_outcomes_crosswalk[_<key>].dta`. The K12-link crosswalks (out of scope) use `k12_<system>_crosswalk.dta`. Both consistent.

### 7. Chunk-10 bugs / anomalies found

| # | File | Line | Issue | Severity |
|---|------|------|-------|----------|
| Bug 86 | `gecode_json.py` | 9-11 | Hardcoded server-absolute path; will break in consolidated repo. | High |
| Bug 87 | `gecode_json.py` | 1 | Dead `from lxml import html`. | Trivial |
| Bug 88 | `gecode_json.py` | 33-57 | Broken retry loop — `else` branch fires on success, exception handlers `continue` indefinitely. No max-retries. | Medium |
| Bug 89 | `gecode_json.py` | 31-32 | URL params not URL-encoded — addresses with `&`, `#`, `'` will produce malformed URLs. | Medium |
| Bug 90 | `gecode_json.py` | output filename | Output is `_geocoded2.csv` but Stata consumers expect `_batch_geocoded.csv` — manual rename required, undocumented. | Medium |
| Bug 91 | `crosswalk_nsc_outcomes.do` | 34 | `set trace on` left in production. | Low |
| Bug 92 | `crosswalk_nsc_outcomes.do` | 250 | `egen ... by(\`id' collegecodebranch)` — undefined local `\`id''` silently ignored. | Medium |
| Bug 93 | `crosswalk_nsc_outcomes.do` | 219, 222, 228, 232 | `inlist(...) | inlist(...)` precedence: `(A & B) | C` — UC Merced (`001319-00`) coded as enrolled even when `recordfoundyn != "Y"`. **Affects `nsc_enr_uc` and `nsc_enr_ucplus`** (paper outcomes). | High |
| Bug 94 | `crosswalk_nsc_outcomes.do` | 318-339, 388-409 | Duplicate `nsc_enr_n_*` vars in foreach varlist. Harmless. | Trivial |
| Bug 95 | `crosswalk_ccc_outcomes.do` | 78-79 | Year-cutover hardcoded `[00, 20]` — will silently miscode 2021+ enrollment. | Medium (deferred) |
| Bug 96 | `crosswalk_ccc_outcomes.do` | 252-254 | `if c(hostname)=="sapper" exit, STATA clear` — auto-shutdown breaks any master-script chaining. | Medium |
| Bug 97 | `crosswalk_csu_outcomes.do` | 215-447 | Hardcoded majordd → STEM/Other table (88+ lines, 4 places). Code 14 silently missing. | Low |
| Bug 98 | `crosswalk_csu_outcomes.do` | 369-371 | ERD append uses `erd<year>.dta` AND `erd<year><semester>.dta` overlapping for 2002-2007 — possible duplicate observations. | Medium |
| Bug 99 | `crosswalk_csu_outcomes.do` | 506-515 | Hardcoded persist-year cohort cutoff. | Low (deferred) |
| Bug 100 | `crosswalk_csu_outcomes.do` | 544-546 | Same auto-shutdown gotcha as CCC. | Medium |
| Bug 101 | `enrollmentconvert.do` | 19 | Local frozen at enr1819 — does not include later years. | Trivial (local-only) |

**Total bug inventory now: ~101.** Up from ~85+ pre-chunk-10. Bug 93 (NSC UC inlist precedence) is the highest-severity new finding — it's load-bearing on a paper outcome.

### 8. Phase 0 close — what's resolved vs. what remains for design-lock (Phase 0e)

**Resolved by chunk 10:**

- Geocoding pipeline architecture: single Python script, free Census Geocoder API, no API key, run-once-cached static input. ADR-0003 confirmed and unchanged.
- Cross-repo crosswalk producer table closed: 3 of the 5 `merge_k12_postsecondary.doh` inputs produced in-scope (NSC, CCC outcomes, CSU outcomes); 2 are external static inputs (k12_ccc, k12_csu link tables).
- `lag2ela` upstream confirmed external — Matt's K-12 cleaning at `/home/research/ca_ed_lab/users/msnaven/`. Will be treated as static input.
- `geoid2` lineage closed: produced inline in `va_cfr_forecast_bias.do:617` from `address_list_census_batch_geocoded.csv` (Python output). Also produced in `clean_acs_census_tract.do:90` (chunk 7) for the ACS side. Both meet at the `merge m:1 geoid2 year_grade<n>` join.
- The `_geocoded2.csv` → `_batch_geocoded.csv` rename gap is now identified as a documented breakpoint (not a bug, but an undocumented manual step that needs explicit recording in the consolidated README).

**Unchanged from chunk 9 / pending for Phase 0e design-lock:**

- Q1.x through Q9.x as listed in deep-read audit (~30 open questions).
- All "in-scope upstream files use server-absolute paths and machine-branched settings.do" issues — these need a design decision in Phase 0e about consolidating to a single `$projdir`.
- Whether to pin the `vam.ado` SSC version (chunk 1 finding).
- The five out-of-scope external static inputs need a manifest file in `data/raw/` describing where they come from, last-rebuild date, and how to refresh.
- Bug 93 (NSC UC inlist precedence) is **paper-load-bearing** and should be patched as a P1 in Phase 1 (consolidation), not deferred to Phase 2.

**No new architectural questions raised by chunk 10.** Phase 0a is complete. The pipeline is deterministically traceable end-to-end given the resolved out-of-scope-static-input list.
