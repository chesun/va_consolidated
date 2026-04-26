# Chunk 10 — Independent Blind Verification (Round 2)

**Scope:** Upstream + Python geocoding layer (6 files, 1440 lines total).
**Date:** 2026-04-26
**Method:** Direct primary-source reading. Adversarial framing — every claim line-cited.
**Sequestered from:** `quality_reports/audits/round-1/` (not read).
**Pre-flight context consumed:** `round-2/README.md` only (Bug 93 T3 verdict on L218–219, L226–228 taken as given).

---

## File-by-file findings

### File 1: `gecode_json.py`

- **Path:** `/Users/christinasun/github_repos/cde_va_project_fork/py_files/sbac/gecode_json.py`
- **Lines:** 116 (note: lines 12–115 are inside a `with open` block indented with **tabs**; this is the entire and only Python file in the project surface area).
- **Purpose:** Geocode student/school addresses from a CSV input. For each row, hits an HTTP geocoding endpoint and writes census GEOID + lat/lon + tract/block to a tab-delimited output CSV.
- **Inputs:** `address_list_census.csv` at hardcoded path `/home/research/ca_ed_lab/common_core_va/data/sbac/address_list_census.csv` (L9–L10, tab-delimited per L20).
- **Outputs:** `address_list_census_geocoded2.csv` at hardcoded path `/home/research/ca_ed_lab/common_core_va/data/sbac/address_list_census_geocoded2.csv` (L11). Tab-delimited per L14.
- **Calls:** Standard library only (`csv`, `time`, `re`, `json`, `os`) plus `requests` for HTTP and `lxml.html` (imported L1 but **never used in the body** — dead import).
- **Language version:** No `# -*- coding ... -*-`, no shebang, no `if __name__ == "__main__"` guard, no version pin in any file. Module-level execution. Python 3 syntax (`print(...)` calls, f-style concatenation only — no f-strings).
- **Packages required (PyPI):** `requests`, `lxml`. Not pinned anywhere in repo.

#### Bugs / anomalies (line-cited):
- **L1 dead import**: `from lxml import html` — `html` is never referenced. Cosmetic.
- **L9–L11 hardcoded absolute paths**: machine-locked to `/home/research/ca_ed_lab/common_core_va` (Scribe layout). Will not run elsewhere without edit. Severity: medium (replication blocker for off-server use, but Scribe-only project).
- **L25–L27 commented-out `onelineaddress` fallback**: stale dead code; the active code path on L28–L32 uses the `address` (street/city/state/zip) endpoint. Cosmetic.
- **L34–L36 silent skip of row 0**: if `index==0` the code prints "Index = 0" and `continue`s. This means **the first data row is silently skipped** (assumes input has a header that was already consumed by `next(reader)` on L21 — so this is a *second* skip). Effect: the first data row is dropped from output. Severity: high if not documented; documented in inline comment "manual restart" on L33 — apparently a manual-restart hack so a re-run doesn't re-geocode the row that crashed previously. Brittle.
- **L37–L57 retry loop `while True` is broken**: the `else` clause of the try/except runs after no exception — and it does `print("Other Error"); page.close(); break`. So a successful request **prints "Other Error"** and then exits the loop. Confusing log output, but the `break` means a single successful request advances to JSON parsing. The `continue` branches on `ConnectionError`/`Timeout`/`ValueError` will retry indefinitely with no backoff — risk of infinite loop if Census API is down. No `time.sleep()` inside the retry, only at L115 after the row is written. Severity: medium (operational risk, not correctness).
- **L41 timeout=15s**: hardcoded.
- **L62 `data=page.json()`**: silently inherits whatever `page` was at the loop's exit. If the `else` branch on L54–L57 fired without a successful response, `page` could be undefined or stale. The current logic only `break`s after the `else` — the `else` actually runs *after no exception*, so this works, but the structure is misleading.
- **L78 `print(json.dumps(data, sort_keys=True, indent=4))`**: prints the entire JSON response for every row to stdout. With ~thousands of rows this produces gigabytes of log noise.
- **L115 `time.sleep(.5)`**: rate-limit between calls (~2 req/sec). Census geocoder permits this, but no documented rate limit observation.
- **No retries on JSON parse failure** — falls through to "NOT FOUND" on first ValueError (L63–L77).

---

### File 2: `crosswalk_nsc_outcomes.do`

- **Path:** `/Users/christinasun/github_repos/cde_va_project_fork/do_files/upstream/crosswalk_nsc_outcomes.do`
- **Lines:** 427.
- **Purpose:** Build NSC enrollment-outcomes crosswalk keyed on `state_student_id` for HS graduation cohorts 2010–2020. Produces `nsc_outcomes_crosswalk_ssid.dta`.
- **Inputs:**
  - `$nscdtadir/nsc_xgyr`gradyear'.dta` for `gradyear ∈ [2010, 2020]` (L38, L81, 11 files).
  - K-12 test-score panel via `do $vaprojdir/do_files/append_k12_all_data.doh "*_student_id cdscode year grade birth_date"` (L55).
- **Outputs:**
  - Per-cohort: `$vaprojxwalks/nsc_xwalk_intermediate/nsc_outcomes_crosswalk_xgyr`gradyear'.dta` (L348).
  - Master: `$vaprojxwalks/nsc_outcomes_crosswalk_ssid.dta` (L417).
  - Logs: `log_files/crosswalk_nsc_outcomes.smcl` and `.log` (L22, L427).
- **Language version:** `version 16.1` (L1).
- **Packages:** No `ssc install` calls; uses base Stata only.
- **Path references:** Globals `$vaprojdir` (L17, L20, L55), `$nscdtadir` (L38, L81), `$vaprojxwalks` (L348, L417).
- **Set seed:** `set seed 1984` (L30).
- **Paper-load-bearing chain:** Output `nsc_outcomes_crosswalk_ssid.dta` is consumed by `merge_k12_postsecondary.doh` L67 (`merge m:1 state_student_id using `crosswalks'/nsc_outcomes_crosswalk_ssid.dta`). The merged dataset feeds composite outcomes `enr`, `enr_2year`, `enr_4year`, `enr_ontime`, `enr_pub`, `enr_priv` (L326–L369 of merge file). These composite variables are used downstream for paper figures `va_enr_4year_*` (multiple references in `paper/common_core_va_v2.tex` lines 490, 528, 654, 661, 701, 708, 748, 755, 795, 802, 1156, 1163, 1350).

#### Bugs / anomalies (line-cited):

- **Bug 93 — UC inlist precedence (PRE-FLIGHT GIVEN; reproduced).**

  - **L218–219 `nsc_enr_uc`**:
    ```
    gen nsc_enr_uc = 1 if recordfoundyn=="Y" ///
        & inlist(collegecodebranch, "001312-00", ..., "041271-00") | inlist(collegecodebranch, "001319-00")
    ```
    The expression evaluates as `(recordfoundyn=="Y" & inlist(... 9 codes ...)) | inlist("001319-00")` because Stata's operator precedence binds `&` tighter than `|`. **UC Merced (001319-00) is set to 1 even when `recordfoundyn != "Y"`**, i.e., even when no NSC record was found. **BUG REAL.** Confirmed in primary source.
  - **L221–223 `nsc_enr_ucplus`**:
    ```
    gen nsc_enr_ucplus = 1 if recordfoundyn=="Y" ///
        & (inlist(... 9 UC codes ...) | inlist("001319-00") ///
        | inlist(... Stanford/Caltech/USC ...))
    ```
    **Outer parens present.** All ORs grouped under the `&`. **CORRECT.** Confirmed.
  - **L226–228 `nsc_enr_ontime_uc`**:
    ```
    gen nsc_enr_ontime_uc = 1 if recordfoundyn=="Y" ///
        & inrange(enrollmentbegin, mdy(8,1,year_grad_hs), mdy(5,15,year_grad_hs+1)) ///
        & inlist(... 9 UC codes ...) | inlist("001319-00")
    ```
    Same precedence error. UC Merced (001319-00) is set to 1 unconditionally on `recordfoundyn` AND `inrange(enrollmentbegin,...)`. **BUG REAL.** Confirmed.
  - **L230–233 `nsc_enr_ontime_ucplus`**:
    ```
    gen nsc_enr_ontime_ucplus = 1 if recordfoundyn=="Y" ///
        & inrange(enrollmentbegin, ...) ///
        & (inlist(... 9 codes ...) | inlist("001319-00") | inlist(... 3 codes ...))
    ```
    **Outer parens present.** **CORRECT.** Confirmed.

  **Severity assessment.** UC Merced (collegecodebranch == "001319-00") rows in the NSC dataset that have `recordfoundyn != "Y"` would be miscoded as `nsc_enr_uc = 1`. Whether this affects paper outputs depends on the downstream chain (see "paper-load-bearing" below).

  **Note on L218**: This is *just one* row — `001319-00` is the *one* code that was added later, in a separate `inlist()` call, breaking the original parenthesization pattern of L221–223 / L230–233. The fix is trivial: wrap the OR clause in outer parens. Recommend applying the round-1 fix.

  **Round-1 over-claim verified.** Round-1 (per pre-flight summary) claimed Bug 93 affected `nsc_enr_ucplus` and `nsc_enr_ontime_ucplus` as well. This is **wrong**: those are protected by outer parens. The real bug affects exactly two outcomes: `nsc_enr_uc` and `nsc_enr_ontime_uc`.

- **Paper-load-bearing impact of Bug 93 (Q3 answer):**
  - `nsc_enr_uc` is consumed at `merge_k12_postsecondary.doh` L462–463 to generate `csu_transfer_uc = 1 if csu_enr==1 & nsc_enr_uc==1`.
  - `nsc_enr_ucplus` is consumed at `merge_k12_postsecondary.doh` L469–470 to generate `csu_transfer_ucplus`.
  - **Paper search for `csu_transfer_uc`/`nsc_enr_uc` in `va_paper_clone/paper/*.tex` returned ZERO matches.** The paper's primary outcome variable is `enr_4year` (figure paths at common_core_va_v2.tex L490, L528, L654, ...).
  - The composite `enr_4year` is built at `merge_k12_postsecondary.doh` L342 as `gen enr_4year = 1 if nsc_enr_4year==1 | csu_enr==1` — does **NOT** include `nsc_enr_uc`.
  - **Conclusion:** Bug 93 produces a corrupted `nsc_enr_uc` indicator and a corrupted `csu_transfer_uc` indicator, but neither appears in the paper's reported outputs. Severity downgrade: **the bug is real but does not propagate to any paper figure or table I can identify in `paper/common_core_va_v2.tex`.** Future work that uses UC enrollment as an outcome (e.g., heterogeneity by selectivity, UC-specific tables) would inherit the bug.

- **Other anomalies in `crosswalk_nsc_outcomes.do`:**
  - **L34 `set trace on`**: trace mode enabled for the entire script. Produces enormous log output. Not turned off until L422. Severity: low (cosmetic / log clutter).
  - **L73 `keep if (tag_ssid==1) & (!mi(state_student_id))`**: drops all observations with missing SSID, immediately *before* the merge. This is a sample-restriction step happening upstream, deliberate per comments at L67–L68.
  - **L250 `egen college_begin_date = min(enrollmentbegin), by(`id' collegecodebranch)`**: macro `id` is referenced but **never defined in this script**. Stata would substitute empty string, making the `by()` group only `collegecodebranch`. This is either a hidden bug or `id` is set elsewhere via include — but I see no `include` statement in this file. Severity: HIGH if `id` resolves to empty (groups across all students; college_begin_date would be the global min for that college, not per-student). Confirms by reading: there is no `local id` or `global id` defined in the visible portion of this file. **NEW POTENTIAL BUG NOT IN PRE-FLIGHT.** Either (a) `$id` is set in some `set seed`-equivalent global outside the file (unlikely — would need `${id}` syntax to use as global), or (b) this is a real bug that quietly mis-aggregates persistence dates. T1 verification needed. Recommend Christina test on Scribe.
  - **L253–L262 `persist_year2_min/max_date`** uses `cond(...)` with **4 arguments** (Stata's `cond()` takes 3 — the 4th argument `,.` is the `if-missing` value, valid in modern Stata). OK.
  - **L296–L316 collapse**: collapses by `state_student_id` only, taking max across all college records per student. Standard.
  - **L318–L339 first inner loop replaces missing → 0**, then **L388–L409 second outer loop does it again** after the cross-cohort append + collapse. The second replacement is necessary because re-collapse can introduce missings; both blocks are correct but redundant code (could be factored into a `.doh`).
  - **L337 `nsc_enr_n_4year nsc_enr_n_2year nsc_enr_n_lt2year nsc_enr_n_4year nsc_enr_n_2year nsc_enr_n_lt2year`** — these three variables appear **twice** in the foreach varlist. Cosmetic (replace `=0 if mi(.)` is idempotent), no harm.
  - **L407 same duplication**: cosmetic.
  - **L420 `erase `k12students'`**: erases tempfile. Unusual — tempfiles are auto-erased at program end. Defensive but pointless. Cosmetic.

---

### File 3: `crosswalk_ccc_outcomes.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/upstream/crosswalk_ccc_outcomes.do`
- **Lines:** 254.
- **Purpose:** Build California Community College outcomes crosswalk (`STUDENT_ID` keyed). Produces `ccc_outcomes_crosswalk.dta`.
- **Inputs:** `'ccc'/Raw/SXENRLM.dta` (L55), `'ccc'/Raw/STUDNTID.dta` (L60), `'ccc'/Raw/CBCRSINV.dta` (L69), `'ccc'/SPAWARDS_studentID.dta` (L150). Where `'ccc' = /secure/ca_ed_lab/Community_College/data` on host `sapper` (L17).
- **Outputs:** `restricted_access/clean/crosswalks/ccc_outcomes_crosswalk.dta` (L244, written relative to `'home' = /secure/ca_ed_lab/data` on `sapper`).
- **Language version:** `version 15.0` (L1).
- **Packages:** Base Stata only.
- **Path references:**
  - **HARDCODED ABSOLUTE PATHS** (L9, L12, L16): `/Users/Naven/Documents/research/ca_ed_lab/data`, `/Users/navenm/Documents/research/ca_ed_lab/data`, `/secure/ca_ed_lab/data`. Conditionally branched by `c(machine_type)` and `c(username)` and `c(hostname)`. Three users hard-coded. Replication blocker for any other user.
  - L17 hardcoded path `/secure/ca_ed_lab/Community_College/data`.
- **Set seed:** L29.
- **Paper-load-bearing chain:** Output `ccc_outcomes_crosswalk.dta` is consumed by `merge_k12_postsecondary.doh` L153 (`merge m:1 student_id using `crosswalks'/ccc_outcomes_crosswalk.dta`). Feeds composite `enr_2year` via `merge_k12_postsecondary.doh` L334 — paper-load-bearing.

#### Q4 — inlist-precedence bug check (CCC):
- Searched for pattern `& inlist(.*) | inlist` in this file — **0 matches**. No Bug 93-family pattern in CCC crosswalk. Verified by grep.
- The file uses `inlist()` at L175, L178, L181 (e.g., `gen ccc_deg_c = 1 if inlist(SP_AWARD, "E", "B", "L", "T", "F")`) — single-list patterns with no chained `|`. Safe.
- L229–230, L235–236 use `inlist(...) & inlist(...)` and `inlist(...) | (inlist(...) & inlist(...))` shapes — both are AND-only or OR-already-parenthesized. Verified safe.

#### Other bugs / anomalies:
- **L8–L18 hardcoded user-machine paths**: replication-package blocker.
- **L75 `tostring SX_TERM_ID, replace format("%03.0f")`**: assumes `SX_TERM_ID` is numeric ≤ 999. If 4-digit term IDs occur, output is silently truncated. Severity: low (would manifest as merge failure downstream).
- **L78–L79 `replace year = "19" + year if inrange(real(year), 92, 99)` then `"20" + year if inrange(real(year), 00, 20)`**: hardcoded century cutover at year 20 (i.e., 2020). After 2020, term IDs would map to "0021" → discarded. **Y2K-style time bomb at year 2021.** Severity: medium for any post-2020 CCC data refresh.
- **L173 `replace ccc_persist_year2 = 1 if ccc_persist_year3==1`**: defines persist_year2 as union of year2 and year3 starts. Logic intentional but worth a comment.
- **L223–225, L228–231 `replace ccc_persist_year2 = .` etc.**: hard-coded year cutoffs `2016, 2017` for which cohorts have insufficient follow-up. Will need refresh as data extends.

---

### File 4: `crosswalk_csu_outcomes.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/upstream/crosswalk_csu_outcomes.do`
- **Lines:** 546.
- **Purpose:** Build CSU outcomes crosswalk (`idunique` keyed) from ERA (applications), ERS (enrollment), ERD (degrees) datasets. Produces `csu_outcomes_crosswalk.dta`.
- **Inputs:** `'csu'/era/era`year``semester'.dta`, `'csu'/ers/ers`year``semester'.dta`, `'csu'/erd/erd`year``semester'.dta` looped 1993–2017 (L56, L126, L345, L369). Where `'csu' = /secure/ca_ed_lab/data/restricted_access/clean/csu actually clean` on `sapper` (L17 — note the **whitespace and "actually" in the path name**).
- **Outputs:** `restricted_access/clean/crosswalks/csu_outcomes_crosswalk.dta` (L536).
- **Language version:** `version 15.0` (L1).
- **Packages:** Base Stata only.
- **Path references:**
  - L9, L12, L16: hardcoded user paths same pattern as CCC file.
  - **L17 path includes the literal phrase "actually clean"** — `/secure/ca_ed_lab/data/restricted_access/clean/csu actually clean`. This is a Naven-era informal directory naming. Not a bug per se but breaks any tooling assuming POSIX-friendly paths.
- **Set seed:** L29.
- **Paper-load-bearing chain:** Output `csu_outcomes_crosswalk.dta` consumed by `merge_k12_postsecondary.doh` L218. Feeds composite `enr_4year` via L342 (`csu_enr==1`) and `enr_pub` via L354. Paper-load-bearing.

#### Q4 — inlist-precedence bug check (CSU):
- Searched `& inlist(.*) | inlist` — **0 matches**. No Bug 93-family pattern in CSU crosswalk.
- The file does have many `inlist()` calls (L85, L102, L207–L213, L506–L515) but all are single-list patterns or conjunctions with `==`-checks that don't trigger the precedence trap.

#### Other bugs / anomalies:
- **L8–L18 hardcoded paths**: replication blocker, same as CCC.
- **L17 path with whitespace and editorial language ("actually clean")**: portability hazard.
- **L56–L78 forvalues loop spans for ERA**: ranges 1997 (semester 4 only), 1998–1999 (semesters 2 and 4), 2000–2002 (semesters 2–4), 2003–2017 (semesters 1–4). Hardcoded magic numbers — encodes the historical schedule of CSU file deliveries. As the data extends past 2017, this loop must be hand-updated. Maintenance hazard.
- **L126–L148 ERS loop**: similar hand-coded year/semester schedule with 1997, 1998 partial, 1999–2002, 2003–2017. Same hazard.
- **L215–L237 `csu_first_maj_stem` hand-coded list of major codes** — 22 individual `replace` statements mapping `majordd ∈ {1..49}` to STEM 0/1. Same in `csu_first_maj_other` (L240–262), `csu_final_maj_stem` (L276–298), `csu_final_maj_other` (L301–323), `csu_deg_stem` (L400–422), `csu_deg_other` (L425–447). Six near-duplicate 23-line blocks. Should be a single `.doh` mapping table called four times. Severity: low (correctness intact assuming the lists agree — would warrant a diff to verify they all have the same STEM assignments). Spot check confirms yes (codes 1, 2, 4, 7, 9, 12, 17, 19, 20 → STEM in all four blocks).
- **L396–L398 `csu_deg_ontime` formula**: `gen csu_deg_ontime = real(string(csu_deg_year) + string(csu_deg_term)) < real(string(csu_ontime_year) + string(csu_ontime_term))`. If `csu_deg_year` or `csu_ontime_year` is missing, `string(.)` returns `"."` and the concatenated result is ill-formed (`real(".."+ "...")` ≈ `.`). Comparison with `.` returns false. So missing-year cases get `csu_deg_ontime = 0`. May be intentional or a corner-case bug. Severity: low.
- **L506–L515 hard-coded enr_start_year cohort exclusions**: same year-cutoff pattern as CCC file.

---

### File 5: `enrollmentconvert.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/local/enrollmentconvert.do`
- **Lines:** 75.
- **Purpose:** One-time conversion utility — imports CDE public-school enrollment text files (`enr1415.txt` through `enr1819.txt`) from CDE's public DataQuest, renames variables to camelCase + Stata-friendly stems, applies value labels for ethnicity, and saves as `.dta` files in `dta/cln/`.
- **Inputs:** `./dta/raw/enr1415.txt`, `enr1516.txt`, `enr1617.txt`, `enr1718.txt`, `enr1819.txt` (5 files; L19, L22).
- **Outputs:** `./dta/cln/enr1415.dta`, ... `enr1819.dta` (L74).
- **Language version:** No `version` directive.
- **Packages:** Base Stata only (`import delimited`, `tostring`, `label define`).
- **Set seed:** None (no stochastic operations).

#### Q5 — disposition:
- **Yes, this is a one-time conversion utility.** Purpose: take public CDE enrollment download (5 academic years 2014/15 through 2018/19) and produce Stata `.dta` cleaned versions with consistent variable names and a labeled ethnicity factor.
- **Local-machine evidence:** L13 has commented-out path `cd "D:\Programs\Dropbox\Davis\Research_Projects\Ed Lab GSR\caschls"` — Windows backslash, drive `D:`. Indicates author's Windows machine. Comment header L8 says "This is a local do file. Global settings for Scribe server do files don't apply." Author intentionally classified it as local.
- **Should it move to upstream?** Arguable. It's a deterministic, reproducible cleaning step on public CDE data. If the CDE enrollment data participates in any analysis (e.g., school-level enrollment for size controls, sample restrictions to enrollment ≥ N), this should be in `do/upstream/` and run on Scribe. But: (a) I see no caller of `enr1415.dta..enr1819.dta` elsewhere in the chunk-10 scope; (b) if the author left it in `do/local/`, the analysis path probably doesn't depend on these files. **Recommend leaving in local for now**, but document in TODO that downstream analysis should be checked for any `use ./dta/cln/enr????.dta` calls before final disposition.
- **Codebook reference**: L10 cites https://www.cde.ca.gov/ds/sd/sd/fsenr.asp — useful for replication. Keep.

#### Bugs / anomalies:
- **L13 commented-out Windows-only path**: cosmetic drift; should be removed or replaced with a portable `.cd` block.
- **L19 `local enrlrawname `" "enr1415" "enr1516" ... "'`**: hand-coded list of years. Refresh required to extend.
- **L67 `tostring cdscode, replace format("%15.0f")`**: cdscode is the 14-digit California school identifier (the `\$cdscode` is sometimes 13, 14, or 15 chars depending on source). The "%15.0f" format zero-pads to 15. Standard idiom in this project.
- **L70 ethnicity label** lists code 0–8 with named categories. Codes match the cited CDE codebook. Spot-checked OK.

---

### File 6: `siblingtest.do`

- **Path:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/local/siblingtest.do`
- **Lines:** 22.
- **Purpose:** Sandbox / test script. Comment header L1: "test file using test data to find an algorithm to remove duplicate families across years." Loads a tiny `siblingtest.csv` test fixture, splits it into "master" and "year2" copies (renaming variables), then calls `group_twoway` to assign a unique family ID.
- **Inputs:** `./dta/raw/siblingxwalk/siblingtest.csv` (L5).
- **Outputs:** `./dta/cln/siblingxwalk/siblingtest.dta` (L18).
- **Language version:** No `version` directive.
- **Packages:** Uses `group_twoway` (L23) — community-contributed package by James Fiedler / others, available via SSC. Not declared anywhere. **Implicit dependency — replication hazard.**
- **Set seed:** None.

#### Q6 — disposition:
- **Yes, this is a diagnostic / scratch script.** It uses a hand-rolled test fixture (`siblingtest.csv`) and is exploring an algorithm rather than producing a load-bearing output.
- **Should it stay in `do/local/`?** Yes. It does not belong in `upstream/` because (a) it's exploratory, (b) it depends on a non-production test fixture, (c) the saved output `siblingtest.dta` is not consumed by any non-local file (verified via grep — only the file itself references its output).
- **Recommend**: keep in local; consider moving to a `do/explorations/` or `do/_archive/` if no longer active. The accompanying `caschls/do/master.do` references siblingvaregs scripts that may have superseded this exploration.

#### Bugs / anomalies:
- **L3 hardcoded Windows path**: `cd "D:/Programs/Dropbox/..."`. Drive `D:` with forward slashes — runs on the author's Windows machine, breaks elsewhere.
- **L5 `insheet`**: deprecated since Stata 13 — should be `import delimited`. Minor.
- **L23 `group_twoway`**: undeclared SSC dependency. Severity: low for a local script, but flag.
- **No `clear`, no `cap log close`, no `set more off`** — minimal infrastructure.
- **L8 saves a tempfile but L11 reuses `master` after `use` overwrites memory** — non-issue, intentional reload of tempfile.

---

## Cross-cutting Q&A summary

### Q1 — `gecode_json.py` geocoding service:
- **Service:** US Census Bureau Geocoder (`https://geocoding.geo.census.gov/geocoder/geographies/address`, L32).
- **Endpoint:** `geographies/address` — returns census block, tract, county, state with GEOIDs and centroids.
- **Benchmark/vintage:** `benchmark=9` and `vintage=910` per L32. Per the Census Geocoder documentation, benchmark `9` corresponds to the "Public_AR_Current" benchmark; vintage `910` corresponds to "Census2010_Current" — i.e., the script geocodes against the 2010-decennial geography vintage (not 2020). This is consistent with a project whose CalSCHLS / SBAC outcome window ends pre-2021.
- **API key:** **NOT required.** The Census Bureau Geocoder API is public/anonymous. No `api_key` or auth header anywhere in the script. Verified by reading the URL on L32 — no token parameter.
- **Rate:** ~2 req/sec (`time.sleep(0.5)` at L115).

### Q2 — Bug 93 status (re-verified):
- L218–219 `nsc_enr_uc`: precedence bug present. UC Merced bypasses `recordfoundyn=="Y"`. **CONFIRMED.**
- L221–223 `nsc_enr_ucplus`: outer parens present. **CORRECT (no bug).**
- L226–228 `nsc_enr_ontime_uc`: precedence bug present. UC Merced bypasses both `recordfoundyn` AND `inrange(enrollmentbegin)`. **CONFIRMED.**
- L230–233 `nsc_enr_ontime_ucplus`: outer parens present. **CORRECT (no bug).**
- **Pre-flight summary fully reproduced.** Round-1 over-claim (claiming 4 affected outcomes) confirmed as over-claim — only 2 outcomes affected.
- **T1 test proposed in pre-flight is the right test.** Run `count if nsc_enr_uc == 1 & recordfoundyn != "Y"` on Scribe.

### Q3 — paper-load-bearing analysis of `crosswalk_nsc_outcomes.do`:
- **a.** `nsc_enr_uc` and `nsc_enr_ucplus` are consumed: at `merge_k12_postsecondary.doh` L462 and L469, used to build `csu_transfer_uc` and `csu_transfer_ucplus`. `nsc_enr_ontime_uc` and `nsc_enr_ontime_ucplus` are kept in the collapse (L310, L331, L380, L401 of the crosswalk file) but **I found no consumer for the `_ontime_uc` family in `merge_k12_postsecondary.doh` or any other do file in scope** (grep confirmed). They are produced but unused downstream.
- **b. Paper outcomes**: composite `enr_4year`, `enr_2year`, `enr`, `enr_ontime`, `enr_pub`, `enr_priv` (all defined at `merge_k12_postsecondary.doh` L326–L369) are paper-load-bearing — extensively cited via figure paths `figures/share/va/v1/va_enr_4year_*` in `paper/common_core_va_v2.tex` (L490, L528, L654, L661, L701, L708, L748, L755, L795, L802, L1156, L1163, L1350). However, **none of these composite outcomes use `nsc_enr_uc`**:
  - `enr` ← `nsc_enr` (L326)
  - `enr_4year` ← `nsc_enr_4year | csu_enr` (L342)
  - `enr_2year` ← `nsc_enr_2year | nsc_enr_lt2year | ccc_enr` (L334)
  - `enr_pub` ← `nsc_enr_pub | ccc_enr | csu_enr` (L354)
  - etc.
- **Conclusion: Bug 93 produces incorrect `nsc_enr_uc` / `csu_transfer_uc` indicators, but neither flows into paper figures or tables identified in `common_core_va_v2.tex`.** The bug is real, but its blast radius in current paper outputs is **null**. It would corrupt any future analysis that uses `nsc_enr_uc`, `nsc_enr_ontime_uc`, `csu_transfer_uc`, or `csu_transfer_ucplus` (the last is `_ucplus` — that one is actually computed from the safe `nsc_enr_ucplus`, so it's clean).

### Q4 — CCC/CSU inlist-precedence audit:
- **CCC file:** searched for `& inlist(.*) | inlist` pattern — **0 matches.** No Bug 93-family bugs.
- **CSU file:** same search — **0 matches.** No Bug 93-family bugs.
- **Bug 93 family is isolated to `crosswalk_nsc_outcomes.do` only.**

### Q5 — `enrollmentconvert.do` disposition:
- One-time conversion utility for public CDE enrollment files 2014/15–2018/19.
- Author intentionally placed it in `do/local/` (L8 comment).
- No external consumer found in chunk-10 scope.
- **Recommend: leave in `do/local/`. Promote to `do/upstream/` only if a load-bearing analysis is identified that uses `enr1415..enr1819.dta`.**

### Q6 — `siblingtest.do` disposition:
- Diagnostic / sandbox script for a sibling-deduplication algorithm using a 22-line test fixture.
- Hardcoded Windows path; uses deprecated `insheet`; uses undeclared SSC package `group_twoway`.
- No external consumer.
- **Recommend: keep in `do/local/`** (or move to `do/explorations/`); add a TODO to either retire it or document the algorithm it was prototyping.

### Q7 — `merge_k12_postsecondary.doh` external crosswalk dependencies:
Verified by direct read of the cde_va_project_fork copy:
- **L142**: `merge m:1 state_student_id using `crosswalks'/k12_ccc_crosswalk.dta` — consumes `k12_ccc_crosswalk.dta`. `'crosswalks'` is a local macro (set earlier in the file or by caller).
- **L207**: `merge m:1 state_student_id using `crosswalks'/k12_csu_crosswalk.dta` — consumes `k12_csu_crosswalk.dta`.
- **Both crosswalks are external to chunk-10's source tree** (k12-to-postsec ID crosswalks, presumably built upstream by Naven). They appear as out-of-scope external `.dta` dependencies — replication blocker if not deposited.

### Q8 — geocoding pipeline rename gap:
- **Confirmed.** `gecode_json.py` writes `address_list_census_geocoded2.csv` (L11) at `$home/data/sbac/`.
- The Stata consumer `do_files/sbac/merge_va_smp_acs.doh` L49 reads `$vaprojdir/data/restricted_access/clean/crosswalks/address_list_census_batch_geocoded.csv`.
- **Two gaps:**
  1. Filename: `..._geocoded2.csv` (Python output) vs `..._batch_geocoded.csv` (Stata input). Different stems.
  2. Directory: `data/sbac/` (Python output) vs `data/restricted_access/clean/crosswalks/` (Stata input). Different folders.
- **Manual rename + manual move** required between Python and Stata — undocumented in either script. Replication-package blocker. The "_batch_" prefix suggests the Stata side may also accept output from the Census Bureau's bulk batch-geocoder web tool (separate from the Python script's per-row geocoder), and the author may have used both methods at different times.
- **15 separate Stata import calls reference `..._batch_geocoded.csv`** across `create_out_samples.smcl`, `create_score_samples.smcl`, `va_cfr_*.smcl`, etc. (per grep). Production pipeline expects the renamed file.

### Q9 — cross-repo Python presence:
- `gecode_json.py` exists ONLY in `/Users/christinasun/github_repos/cde_va_project_fork/py_files/sbac/gecode_json.py`.
- No copies in `caschls/` (verified — `find ... -name "*.py"` returns empty for that tree).
- No copies in `va_consolidated/` outside `.claude/hooks/` (verified).
- **Diff is moot — only one copy exists.** Cross-repo identicality not applicable; the script lives only in cde_va_project_fork.

---

## Summary of bugs catalogued

| Severity | File | Line(s) | Description | Paper impact |
|---|---|---|---|---|
| HIGH | crosswalk_nsc_outcomes.do | 218–219 | Bug 93: UC Merced miscoded `nsc_enr_uc=1` w/o NSC record | Real bug, produces corrupted `csu_transfer_uc`, but **NOT consumed in `paper/common_core_va_v2.tex`** |
| HIGH | crosswalk_nsc_outcomes.do | 226–228 | Bug 93: same precedence error in `nsc_enr_ontime_uc` | Real bug, **no consumer found** in merge or paper |
| MEDIUM-HIGH | crosswalk_nsc_outcomes.do | 250 | `egen ... by(\`id' collegecodebranch)` — local `id` not defined; collapses to `by(collegecodebranch)` only | T1 verification needed; potential silent data corruption in `college_begin_date` and downstream `nsc_persist_year{2,3,4}` |
| MEDIUM | gecode_json.py | 11 vs merge_va_smp_acs.doh L49 | Python outputs `_geocoded2.csv` to `data/sbac/`; Stata reads `_batch_geocoded.csv` from `data/restricted_access/clean/crosswalks/`. Manual rename + move undocumented | Replication-blocker; not paper-correctness |
| MEDIUM | gecode_json.py | 9–11 | Hardcoded server-absolute paths (Scribe layout) | Replication-blocker |
| MEDIUM | crosswalk_ccc_outcomes.do | 78–79 | Y2K-style century cutover hardcoded at year 20 (2020) | Time bomb post-2020 data refresh |
| MEDIUM | crosswalk_csu_outcomes.do | 17 | Path with whitespace `"...csu actually clean"` | Portability hazard |
| LOW | crosswalk_ccc_outcomes.do | 8–18 | Hardcoded user-machine paths (3 users) | Replication-blocker |
| LOW | crosswalk_csu_outcomes.do | 8–18 | Same | Same |
| LOW | crosswalk_csu_outcomes.do | 215–447 | Six near-duplicate 23-line major-code mapping blocks | Maintenance hazard, no correctness risk |
| LOW | crosswalk_nsc_outcomes.do | 34 | `set trace on` global | Log clutter |
| LOW | crosswalk_nsc_outcomes.do | 337, 407 | Duplicated variable names in foreach varlist | Idempotent, cosmetic |
| LOW | gecode_json.py | 1, 25–27, 78 | Dead import; commented-out fallback URL; massive JSON dump per row | Cosmetic / log noise |
| LOW | gecode_json.py | 34–36, 37–57 | Manual restart silent skip of row 0; broken try/except/else structure | Operational confusion |
| LOW | siblingtest.do | 3, 5, 23 | Windows path; deprecated `insheet`; undeclared `group_twoway` SSC dep | Non-load-bearing local script |
| LOW | enrollmentconvert.do | 13 | Commented Windows-only `cd` | Cosmetic |

---

## Verifications NOT done (deferred to T1 / Christina on Scribe)

1. Bug 93 empirical: run `count if nsc_enr_uc==1 & recordfoundyn!="Y"` on `nsc_outcomes_crosswalk_ssid.dta` — should be `>0` if bug active. (Pre-flight proposed test.)
2. **NEW**: Verify `egen college_begin_date = min(enrollmentbegin), by(\`id' collegecodebranch)` at L250 — does `id` resolve to `state_student_id` via some macro, or is this a silent bug? Test: `tab _grouping if collegecodebranch != ""` and check whether college_begin_date varies by student.
3. Whether any Naven-era CCC/CSU paper output (not common_core_va_v2.tex) consumes the `csu_transfer_uc` family or the `_ontime_uc` family. Out-of-scope for this chunk.
4. Whether `address_list_census_batch_geocoded.csv` was ever produced by `gecode_json.py` after a manual rename, or whether it came from the Census Bureau's bulk web batch tool. Git history of the CSV would tell.

---

## Confidence

- **HIGH** on Bug 93 verdicts (direct read, pre-flight matches mine).
- **HIGH** on Q4 (no Bug-93-family in CCC/CSU — grep was deterministic).
- **HIGH** on Q8 (filename + directory mismatch — read both ends).
- **HIGH** on Q9 (no other Python files exist).
- **MEDIUM-HIGH** on Q3 paper-impact analysis: I searched paper text and `merge_k12_postsecondary.doh` definitions; the conclusion that Bug 93 doesn't propagate to paper figures rests on (a) `enr_4year` etc. compositions not using `_uc`, (b) no `csu_transfer_uc` reference in paper.tex. Possible miss: if a different paper draft, supplement, or talk file consumes `nsc_enr_uc`, I'd not have found it. **Recommend Christina spot-check `paper/intro.tex`, `paper/check_sum_stats.tex`, and the talks under `va_paper_clone/presentations/` for any UC-specific outcomes.**
- **MEDIUM** on the L250 `id` macro finding — it's plausibly a real bug but could be set by a global I haven't inspected; T1 test resolves.
