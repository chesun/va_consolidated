# Chunk 5 Audit: Sibling Crosswalk + Sibling VA Regs

**Date:** 2026-04-24
**Scope:** 4 files in `do/share/siblingxwalk/` + 28 files in `do/share/siblingvaregs/` (incl. 2 helpers `vafilemacros.doh`, `vaestmacros.doh` already in chunk 2)
**Server root:** `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/`

## File inventory of `siblingvaregs/` (read-time `ls`)

```
create_va_sib_acs_out_restr_smp.do   create_va_sib_acs_restr_smp.do   createvasample.do
reg_out_va_sib_acs.do                reg_out_va_sib_acs_dk.do         reg_out_va_sib_acs_dk_fig.do
reg_out_va_sib_acs_fig.do            reg_out_va_sib_acs_tab.do
siblingoutxwalk.do                   siblingvasamples.do
va_sib_acs.do                        va_sib_acs_est_sumstats.do
va_sib_acs_fb_test_tab.do            va_sib_acs_out.do
va_sib_acs_out_dk.do                 va_sib_acs_out_est_sumstats.do
va_sib_acs_spec_test_tab.do          va_sib_acs_vam_tab.do
va_sibling.do                        va_sibling_est_sumstats.do
va_sibling_fb_test_tab.do            va_sibling_out.do
va_sibling_out_est_sumstats.do       va_sibling_out_forecast_bias.do
va_sibling_sample_sumstats.do        va_sibling_spec_test_tab.do
va_sibling_vam_tab.do                vaestmacros.doh    vafilemacros.doh
```

26 `.do` files + 2 `.doh` helpers. (Helpers were covered in chunk 2; entries below are abbreviated cross-refs.)

---

## Per-file entries

### File: do/share/siblingxwalk/siblingmatch.do

**Owner:** Comments say "Code taken mostly from do file by Matt Naven", header credits Christina Sun.
**Pipeline phase:** sibling_xwalk
**Lines:** 109
**Purpose:** Build two raw "siblings" crosswalks from CST k-12 enrollment by joining students who share an address+name. Produces a within-year crosswalk and an across-years crosswalk.

**Loop structure:** No outer loop. Two if-block sections gated by `local matchonsameyear = 1` (ll. 32-69) and `local matchacrossyears = 1` (ll. 77-105). Inside the within-year block, a `foreach year of numlist 2004 (1) 2013` (l. 15) appends 10 annual CST datasets.

**Inputs:** `$cstdtadir/cst_<year>` for years 2004–2013 (line 16; `$cstdtadir` is a global presumed defined in caschls's settings.do — chunks 1-2 didn't lift its definition; needs verification). Variables kept: `state_student_id birth_date year first_name middle_intl last_name street_address_line_one street_address_line_two city state zip_code` (ll. 17-18).

**Outputs:**
- `$projdir/dta/siblingxwalk/k12_xwalk_name_address_year.dta` (l. 68) — within-year matches
- `$projdir/dta/siblingxwalk/k12_xwalk_name_address.dta` (l. 104) — across-year matches
- `$projdir/log/share/siblingxwalk/siblingmatch.smcl` and `.log` (ll. 12, 108)

**Filename naming pattern:** Hand-coded; literal names. No subject/outcome stem.

**Statistical specification:** No regression. Pure data construction. Group/`egen group()` with `mi` flag treating missings as their own group (ll. 49, 86) — flagged as a non-trivial design choice.

**Sourced helpers / Calls:** None — does not include any `.doh` files. Relies on `$projdir` and `$cstdtadir` globals from project's settings.do (caschls home).

**Path references that need updating:** `$cstdtadir/cst_<year>`; `$projdir/dta/siblingxwalk/...`; `$projdir/log/share/siblingxwalk/...`.

**Stata version / syntax:** No `version` statement. Uses `egen long ... = group(..., mi)`, `bysort ... : drop if _N==1`, `tempfile`, `compress`, `label data`. Standard Stata 13+.

**ssc/community packages used:** None.

**Gotchas / non-obvious behavior:**
- l. 22: `drop if strlen(street_address_line_one) <= 1` — uses `strlen` instead of `missing()` because some addresses are 1-char placeholders ("Y", "0"). Flag for documentation.
- ll. 38-40: comment notes 38.56% missing middle initial and 7.36% missing zip; the keys deliberately omit middle initial for matching.
- l. 41 vs l. 49: `duplicates report` lists 6 keys (without `zip_code`) but `egen group()` uses 7 keys (with `zip_code`). Subtle inconsistency — duplicates are dropped on a slightly looser key than the group definition.
- l. 43: `duplicates drop ... force` — silently picks first; not deterministic across sorts.
- l. 49 the `group(..., mi)` with `mi` option: missing addresses become their own group. So all students with a given last name and "missing zip" cluster together. **This could artificially inflate sibling counts**; documented in next file (uniquefamily.do l. 53) by capping max children at 10.

**Reference to paper outputs:** Indirect — paper Section 2.4 sibling sample description (line 183 of paper map). Does NOT directly produce a paper table; supplies the building blocks.

**Notes / open questions:** The paper says "address and surname" — code matches on `last_name` AND `street_address_line_one street_address_line_two city state zip_code` (5-component address). Confirms paper Q1.

---

### File: do/share/siblingxwalk/uniquefamily.do

**Owner:** Christina Sun (header).
**Pipeline phase:** sibling_xwalk
**Lines:** 78
**Purpose:** Take the within-year sibling crosswalk and chain transitively across years — implements "linking all students who share a common sibling." Outputs the canonical family ID dataset and the trimmed sibling-pairs xwalk.

**Loop structure:** No loop. Linear pipeline.

**Inputs:** `$projdir/dta/siblingxwalk/k12_xwalk_name_address_year.dta` (l. 18).

**Outputs:**
- `$projdir/dta/siblingxwalk/uniquelinkedfamilyraw.dta` (l. 35) — pre-dedupe
- `$projdir/dta/siblingxwalk/uniquelinkedfamilyclean.dta` (l. 50) — one row per student
- `$projdir/dta/siblingxwalk/ufamilyxwalk.dta` (l. 74) — trimmed (≤ 10 children/family) version with birth-order fields **— this is the CANONICAL sibling crosswalk consumed downstream**
- `$projdir/out/graph/siblingxwalk/numsiblingdist.png` (l. 49)
- `$projdir/log/share/siblingxwalk/uniquefamily.smcl/log` (ll. 16, 78)

**Filename naming pattern:** Literal.

**Statistical specification:** No regression. Transitive-closure via `group_twoway` (l. 32) on (`siblings_name_address_year`, `state_student_id`).

**Sourced helpers / Calls:** None.

**Path references that need updating:** `$projdir/dta/siblingxwalk/`, `$projdir/out/graph/siblingxwalk/`, `$projdir/log/share/siblingxwalk/`.

**ssc/community packages used:** **`group_twoway`** (line 32, with optional `ssc install` line on l. 21 commented). This is the connected-components algorithm from Haghish (cited at https://haghish.com/statistics/stata-blog/stata-programming/download/group_twoway.html).

**Gotchas / non-obvious behavior:**
- ll. 24-27: `siblings_name_address_year` is converted to string and prefixed with "family" so the two arguments to `group_twoway` (family ID and student ID) are guaranteed disjoint. If they overlap as numerics, the package errors.
- l. 53: **Hard cutoff `drop if numsiblings >= 9`** caps at 10 children per family. Anything above is flagged as likely matching error (cousins/extended family at the same address). Documented in comment l. 52. **This is a research-design parameter that should be promoted to an ADR.**
- l. 56: `numsiblings` renamed to `numsiblings_exclude_sef` (typo for "self") — flag for cleanup.
- l. 62: `birth_order = _n` after `sort ufamilyid birth_date` — birth order is purely chronological by `birth_date`. Ties on the same date will be deterministic by Stata's sort but **arbitrary in expectation**.
- l. 69: `gen sibling_full_sample = 1` — every row has it set; this is a marker for the population in `ufamilyxwalk.dta`, used downstream as a sample restrictor.

**Reference to paper outputs:** Paper Section 2.4. Not a directly-cited table.

**Notes / open questions:** The 10-child cap is paper-relevant; Christina should confirm whether the paper text mentions this cap.

---

### File: do/share/siblingxwalk/siblingpairxwalk.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_xwalk
**Lines:** 82
**Purpose:** Construct a pairwise sibling crosswalk (each row is a (self, sibling) pair, both directed and undirected variants). Used for sibling-pair-level analyses and birth-distance summary stats.

**Loop structure:** None.

**Inputs:** `$projdir/dta/siblingxwalk/uniquelinkedfamilyclean.dta` (loaded twice, ll. 16 and 35).

**Outputs:**
- `$projdir/dta/siblingxwalk/siblingpairxwalk.dta` (l. 45) — directed pairs (both orderings)
- `$projdir/dta/siblingxwalk/uniquesiblingpairxwalk.dta` (l. 77) — unique unordered pairs with `birth_date_distance` and `avg_birth_date_distance_family`
- `$projdir/log/share/siblingxwalk/siblingpairxwalk.smcl/log`

**Filename naming pattern:** Literal.

**Statistical specification:** None. `joinby` self-join on `ufamilyid` (l. 37) creates pairs; bysort dedupe drops permutations (ll. 60-61).

**Sourced helpers / Calls:** None.

**Path references that need updating:** `$projdir/dta/siblingxwalk/`, `$projdir/log/share/siblingxwalk/`.

**ssc/community packages used:** None (uses `joinby`, `egen concat`).

**Gotchas / non-obvious behavior:**
- l. 24: `rename middle_intl sibling_middle_intl` — but `uniquelinkedfamilyclean.dta` (per uniquefamily.do l. 54 `keep` list) doesn't keep `middle_intl`. **Possible bug: this rename will silently fail or error depending on Stata version.** Flag as a deferred bug.
- ll. 53-57: pair-ordering trick — concat both orderings, replace with the smaller one if `state_student_id > sibling_state_student_id`. Then `bysort` drops within-family duplicates. Standard but worth noting.
- l. 71: divides `avg_birth_date_distance_family` by 365 to convert days→years. Not days→years exactly (no leap-year correction); fine for summary stats.

**Reference to paper outputs:** Indirect — feeds `va_sibling_sample_sumstats.do`'s "average birth-date distance" reported in sample description (paper Section 2.4 / Table 1 row).

**Notes / open questions:** Possible `middle_intl` rename failure (see above).

---

### File: do/share/siblingvaregs/siblingoutxwalk.do **(N1 anchor)**

**Owner:** Christina Sun (header lines 6-9).
**Pipeline phase:** sibling_xwalk **(produces a crosswalk; downstream consumers are sibling-VA files)**
**Lines:** 223
**Purpose:** Build the **enriched sibling outcomes crosswalk** by merging the full k-12 panel onto postsecondary enrollment data (NSC/CCC/CSU), collapsing to student level, then merging onto `ufamilyxwalk.dta` and computing per-family older-sibling enrollment indicators (lag1, lag2, "any older with enr").

**Loop structure:** Two `foreach i of local outcomes` loops over `enr enr_2year enr_4year`: one to count older-sibling enrollment (l. 165) and one to extract lag1 / lag2 older-sibling enrollment indicators (l. 187).

**Inputs:**
- `$vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta` (l. 59) — base k-12 sample
- Postsecondary outcomes via `do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only` (l. 61)
- `$projdir/dta/siblingxwalk/k12_postsecondary_out_merge.dta` — saved on l. 71, then re-loaded l. 80
- `\`ufamilyxwalk'` (l. 91) — local macro defined in `vafilemacros.doh` line 22, expanding to `$projdir/dta/siblingxwalk/ufamilyxwalk`

**Outputs:**
- `$projdir/dta/common_core_va/k12_postsecondary_out_merge.dta` (l. 71) — full k-12 + postsecondary outcomes merge (intermediate but shared with other do files; **side-effect output** since it has nothing to do with the sibling xwalk per se)
- `$projdir/dta/siblingxwalk/sibling_out_xwalk.dta` (l. 212) — **the canonical sibling-outcomes crosswalk consumed by all sibling-VA do files**
- `$projdir/log/share/siblingvaregs/sibling_out_xwalk.smcl/log` (ll. 47, 222)

**Filename naming pattern:** Literal.

**Statistical specification:** None — pure data construction. Uses `rangestat (sum)` (l. 140, 155, 166) to count older siblings within `ufamilyid`, with intervals `[birth_order - numsiblings_older, birth_order - 1]`.

**Sourced helpers / Calls:**
- `include $projdir/do/share/siblingvaregs/vafilemacros.doh` (l. 39)
- `include $vaprojdir/do_files/sbac/macros_va.doh` (l. 41)
- `do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only` (l. 61)

**Path references that need updating:** `$projdir/dta/common_core_va/`, `$projdir/dta/siblingxwalk/`, `$vaprojdir/data/restricted_access/`, `$vaprojdir/do_files/`, `$projdir/log/share/siblingvaregs/`.

**Stata version / syntax:** Uses `rangestat`, `merge 1:1`, `collapse (max)`. No `version` statement.

**ssc/community packages used:** **`rangestat`** (Robert Picard / Nick Cox SSC package, used at lines 140, 155, 166, 189, 193). Required dependency.

**Gotchas / non-obvious behavior:**
- ll. 159-162: explicit guard `if !missing(num_older_sibling_postsec_match) & num_older_sibling_postsec_match > 0` — comment "STATA TREATS MISSING AS GREATER THAN ANY NONMISSING NUMBER!!!!!!" (l. 159). The change-log explains this was a bug fix on 10/22/2021. **Important pattern — replicate elsewhere if any other `>0` comparisons exist.**
- l. 178-179: the **`sibling_2y_4y_controls_sample`** indicator — restricts to obs with at least 1 older sibling matched to postsecondary AND non-missing for `has_older_sibling_enr_2year` AND `has_older_sibling_enr_4year`. **This is THE sample restriction for the 4-spec analysis.** Used in `create_va_sib_acs_restr_smp.do` l. 60 (`keep if sibling_2y_4y_controls_sample==1`).
- ll. 184-204: lag1 / lag2 older-sibling outcome variables (`old1_sib_<outcome>`, `old2_sib_<outcome>`) and a `touse_sib_lag` indicator. **Per change log 1/25/2023, this is recently added; likely supports a robustness extension not yet in the paper.**
- ll. 135-148 (commented out): an earlier formulation that computed proportions `propsiblings_older_<outcome>`. The current implementation computes counts and dummies instead.
- l. 91 `merge 1:1 state_student_id using \`ufamilyxwalk'`: the local `ufamilyxwalk` is defined in `vafilemacros.doh` line 22. Without that include, this line would fail. **Confirmed dependency: vafilemacros.doh.**

**Reference to paper outputs:** Indirect — feeds every sibling-VA estimation file via `sibling_out_xwalk.dta`. Paper Tables 4 robustness rows / OA tables for the sibling-restricted sample.

**Notes / open questions:** None blocking. The N1 question is fully resolved below in the synthesis.

---

### File: do/share/siblingvaregs/createvasample.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_va (sample creation)
**Lines:** 129
**Purpose:** Create the two main grade-11 VA sample datasets — test-score VA sample and outcome (postsecondary) VA sample — by running Matt Naven's helpers `create_va_sample.doh` → `create_va_g11_sample.doh` / `create_va_g11_out_sample.doh`. These are the foundation samples that `va_sibling.do` and friends merge onto sibling info.

**Loop structure:** None.

**Inputs:** Constructed by `create_va_sample.doh` etc. — ultimately the cleaned k-12 + postsecondary data on `$vaprojdir`.

**Outputs:**
- `$projdir/dta/common_core_va/va_dataset.dta` (l. 56) — full VA sample
- `$projdir/dta/common_core_va/va_g11_dataset.dta` (l. 71) — grade-11 test score VA sample
- `$projdir/dta/common_core_va/va_g11_out_dataset.dta` (l. 106) — grade-11 outcome VA sample
- log file `$projdir/log/share/siblingvaregs/createvasample.smcl/log`

**Filename naming pattern:** Literal.

**Statistical specification:** None — pure data construction.

**Sourced helpers / Calls:**
- `include $projdir/do/share/siblingvaregs/vafilemacros.doh` (l. 23)
- `include $vaprojdir/do_files/sbac/macros_va.doh` (l. 27)
- `include $vaprojdir/do_files/sbac/create_va_sample.doh` (l. 47)
- `include $vaprojdir/do_files/sbac/create_va_g11_sample.doh` (l. 65)
- `do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only` (l. 83)
- `include $vaprojdir/do_files/sbac/create_va_g11_out_sample.doh` (l. 101)

**Path references that need updating:** `$projdir/dta/common_core_va/`, `$projdir/log/share/siblingvaregs/`, `$vaprojdir/do_files/sbac/`.

**ssc/community packages used:** None directly (delegated to Matt's helpers).

**Gotchas / non-obvious behavior:**
- ll. 73-74: `tempfile va_dataset` is `erase`d at line 74 immediately after the temp variable is no longer needed, then re-created at line 93 with the same name. Allowed but confusing.
- The VA dataset is saved twice — once as a permanent file at l. 56 and again as a tempfile at l. 51 — causing some redundancy.

**Reference to paper outputs:** Indirect — these are the input samples for all VA estimation.

**Notes / open questions:** None.

---

### File: do/share/siblingvaregs/siblingvasamples.do

**Owner:** Christina Sun (header credits Matt for first block, ll. 36-37 "directly taken from Matt's touse_Va.do").
**Pipeline phase:** sibling_va (sample marker creation)
**Lines:** 218
**Purpose:** Reconstruct the touse_g11_<subject>/<outcome> sample markers from scratch (echoing the logic of Matt's helpers) and merge on the sibling outcome xwalk to produce a unified touse + sibling-membership marker file. Used by `va_sibling_sample_sumstats.do`.

**Loop structure:** Two `foreach subject in ela math` (l. 152) and `foreach outcome in enr enr_2year enr_4year` (l. 176) loops to build the touse markers.

**Inputs:** `\`k12_test_scores'/k12_test_scores_clean.dta` (l. 60), various lag/peer files (ll. 64-94), `\`sibling_out_xwalk'` (l. 203).

**Outputs:**
- `$projdir/dta/common_core_va/va_sibling_samples.dta` (l. 208) — slim file with touse_* + sibling_full_sample + sibling_out_sample
- log file

**Filename naming pattern:** Literal.

**Statistical specification:** Uses `mark`/`markout` to define touse for: grade==11, dataset=="CAASPP", year-window restriction, `diff_school_prop>=0.95`, `cohort_size>10`, `conventional_school==1`, and non-missingness on full control sets. Identical sample logic to chunk 3's main VA touse files.

**Sourced helpers / Calls:**
- `include $projdir/do/share/siblingvaregs/vafilemacros.doh` (l. 29)
- `include \`vaprojdofiles'/sbac/macros_va.doh` (l. 42)
- `do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only` (l. 112)

**Path references that need updating:** `$projdir/dta/common_core_va/`, `$projdir/log/share/siblingvaregs/`, `$vaprojdir/do_files/`.

**ssc/community packages used:** None.

**Gotchas / non-obvious behavior:**
- This file **duplicates** the touse logic from Matt's helpers — drift is possible if Matt updates his helper but Christina does not update this file. **Should be flagged for consolidation: replace with a call to Matt's helper if feasible.**
- ll. 50-52: `timer on 1` is called at l. 32 AND again at l. 50. Second call has no effect.

**Reference to paper outputs:** Indirect — the saved markers feed sample-size cells in Table 1 and similar.

**Notes / open questions:** Drift hazard — duplicates Matt's logic.

---

### File: do/share/siblingvaregs/create_va_sib_acs_restr_smp.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_va (sample creation)
**Lines:** 98
**Purpose:** Create the test-score VA restricted sample that has BOTH non-missing sibling controls AND non-missing ACS controls. This is the population for the 4-specification test-score analysis.

**Loop structure:** None.

**Inputs:** `\`va_g11_dataset'` (l. 53) = `$projdir/dta/common_core_va/va_g11_dataset.dta`. Sibling crosswalk via `\`sibling_out_xwalk'` (l. 56).

**Outputs:** `$vaprojdir/data/va_samples/va_sib_acs_restr_smp.dta` (l. 76).

**Filename naming pattern:** Literal — the dataset is named after its sample stem (`va_sib_acs_restr_smp`).

**Statistical specification:** None — sample construction. Restricts to `sibling_2y_4y_controls_sample==1` (l. 60), then merges ACS via Matt's helper (l. 69).

**Sourced helpers / Calls:**
- `include $projdir/do/share/siblingvaregs/vafilemacros.doh` (l. 39)
- `include $vaprojdir/do_files/sbac/macros_va.doh` (l. 42)
- `do $vaprojdir/do_files/sbac/merge_va_smp_acs.doh test_score \`va_g11_sibling_dataset' va_g11_sibling_dataset create_sample none` (l. 69) — five positional args: domain, tempfile, tempfile-name, mode, fb_var. Mode `create_sample` says "build the restricted sample"; `none` says "no leave-out variable".

**Path references that need updating:** `$projdir/dta/`, `$vaprojdir/data/va_samples/`, `$vaprojdir/do_files/sbac/`.

**ssc/community packages used:** None directly.

**Gotchas / non-obvious behavior:**
- l. 76 the saved output goes to `$vaprojdir/data/va_samples/` (FORK home), NOT `$projdir/dta/`. So the sample dataset is in the VA project tree, not the sibling tree.
- The "create_sample" arg-mode of `merge_va_smp_acs.doh` is one of the routes through Matt's helper; the alternative is `create_va` (used in `va_sibling_out_forecast_bias.do` l. 82).

**Reference to paper outputs:** Feeds `va_sib_acs.do` which produces the test-score VAs whose ρ regressions appear in OA tables paired with paper Tables 4 robustness rows.

**Notes / open questions:** None.

---

### File: do/share/siblingvaregs/create_va_sib_acs_out_restr_smp.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_va (sample creation)
**Lines:** 120
**Purpose:** Create the outcome (enrollment) VA restricted sample that has BOTH non-missing sibling controls AND non-missing ACS controls AND merges in the test-score VA estimates from the same restricted sample (so deep-knowledge VA can be estimated downstream).

**Loop structure:** Nested `foreach outcome in enr enr_2year enr_4year` (l. 75) × `foreach subject in ela math` (l. 76) merging in test-score VA, then a second pass to construct deep-knowledge touse markers `touse_<outcome>_dk` (ll. 89-91).

**Inputs:** `\`va_g11_out_dataset'` (l. 56), `\`sibling_out_xwalk'` (l. 59), test-score VA datasets `$vaprojdir/data/sib_acs_restr_smp/test_score_va/va_<subject>_sib_acs.dta` (l. 79).

**Outputs:** `$vaprojdir/data/va_samples/va_sib_acs_out_restr_smp.dta` (l. 102).

**Filename naming pattern:** Literal.

**Statistical specification:** None — sample construction with merging. Defines `touse_<outcome>_<subject>_og` (ll. 83-85) requiring obs in outcome touse AND non-missing subject VA, then `touse_<outcome>_dk` requires both ela AND math VA non-missing (ll. 89-91).

**Sourced helpers / Calls:**
- `include $projdir/do/share/siblingvaregs/vafilemacros.doh` (l. 40)
- `include $vaprojdir/do_files/sbac/macros_va.doh` (l. 43)
- `do $vaprojdir/do_files/sbac/merge_va_smp_acs.doh outcome \`va_g11_out_sibling_dataset' va_g11_out_sibling_dataset create_sample none` (l. 71)

**Path references that need updating:** `$projdir/dta/`, `$vaprojdir/data/va_samples/`, `$vaprojdir/data/sib_acs_restr_smp/test_score_va/`, `$vaprojdir/do_files/sbac/`.

**Gotchas / non-obvious behavior:**
- l. 80 `keepusing(va_<subject>_*)` — pulls in ALL VA spec variants (`og`, `acs`, `sib`, `both`) for that subject. The deep-knowledge touse uses only `<subject>_og` per ll. 85, but later DK estimation files use `<control>_dk` patterns that pair with each spec.
- The DK touse is **conjunctive**: requires non-missing in BOTH ela_og and math_og — so DK sample is a subset of the outcome restricted sample that is in both single-subject test-score VA samples.
- Pre-condition: `va_sib_acs.do` (test-score VA) must run BEFORE this file, or the merge at l. 79 yields no test-score VA columns. **Strict ordering dependency.**

**Reference to paper outputs:** Feeds `va_sib_acs_out.do`, `va_sib_acs_out_dk.do`, and the entire pass-through-on-sibling-restricted-sample chain (`reg_out_va_sib_acs*.do`).

**Notes / open questions:** Strict file ordering must be documented in master.do.

---

### File: do/share/siblingvaregs/va_sibling.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_va (estimation — test score)
**Lines:** 318
**Purpose:** Compute test-score VA on the sibling-restricted sample, with TWO specifications: (a) no sibling controls, (b) with sibling controls (i.has_older_sibling_enr_2year, i.has_older_sibling_enr_4year). Produces VAM .ster, spec test, forecast-bias test (sibling controls as leave-out), and saved school×year VA dataset.

**Loop structure:** `foreach subject in ela math` (l. 103). Inside: VAM (no sib ctrl) → spec test → VAM (with sib ctrl) → spec test → FB test → collapse → save.

**Inputs:** `\`va_g11_dataset'` (l. 76), `\`sibling_out_xwalk'` (l. 79).

**Outputs:** Per subject:
- `$vaprojdir/estimates/sibling_va/test_score_va/vam_cfr_g11_<subject>_nosibctrl.ster` (l. 125)
- `$vaprojdir/estimates/sibling_va/test_score_va/vam_cfr_g11_<subject>.ster` (l. 161) — with sib ctrl
- `$projdir/est/siblingvaregs/test_score_va/spec_test_va_cfr_g11_<subject>_sibling_nocontrol.ster` and `$vaprojdir/estimates/sibling_va/test_score_va/spec_test_..._nocontrol.ster` (ll. 137, 139)
- spec test with sibling controls (ll. 172, 174)
- `fb_test_va_cfr_g11_<subject>_sibling.ster` to both folders (ll. 278, 280)
- collapsed school×year VA: `$projdir/dta/common_core_va/test_score_va/va_g11_<subject>_sibling.dta` (l. 294) and `$vaprojdir/data/sibling_va/test_score_va/va_g11_<subject>_sibling.dta` (l. 296)

**Filename naming pattern:** Mixed/inconsistent.
- Some `_nocontrol` suffix (e.g., `spec_test_..._sibling_nocontrol.ster` l. 137)
- Some `_nosibctrl` suffix (e.g., `vam_cfr_g11_<subj>_nosibctrl.ster` l. 125)
- The "with sibling controls" version omits any suffix (just `vam_cfr_g11_<subj>.ster`)
- The FB test follows `fb_test_va_cfr_g11_<subj>_sibling.ster` — no separate-file convention; the "leave-out var" is implicit (sibling controls).

**Statistical specification:**
- VAM: `vam sbac_<subj>_z_score, teacher(school_id) year(year) class(school_id) controls(...) data(merge tv score_r) driftlimit(`drift_limit') estimates(...)` — same structure as chunk 3 main VA.
- Spec test: `reg sbac_g11_<subj>_r va_cfr_g11_<subj>, cluster(school_id)` (ll. 135, 170).
- FB test: `reg sbac_g11_<subj>_r_d va_cfr_g11_<subj>, cluster(school_id)` (l. 276), where `_r_d = _r_nosibctrl - _r` (l. 271). Sibling controls are the leave-out var.
- Drift limit: `max(test_score_max_year - test_score_min_year - 1, 1)` if positional arg = 0 (l. 96-101); otherwise = positional arg.

**Sourced helpers / Calls:**
- `args setlimit` (l. 51) — receives `0` or other integer
- `include $projdir/do/share/siblingvaregs/vafilemacros.doh` (l. 54)
- `include \`vaprojdofiles'/sbac/macros_va.doh` (l. 63)

**Path references that need updating:** `$projdir/`, `$vaprojdir/estimates/sibling_va/test_score_va/`, `$vaprojdir/data/sibling_va/test_score_va/`.

**Stata version / syntax:** Uses `vam`, `args`, `local`, `rename` chains.

**ssc/community packages used:** **`vam`** (Stepner, SSC).

**Gotchas / non-obvious behavior:**
- ll. 7-10: comment notes that family fixed effects are NOT used because there are too few observations relative to families ("749488 obs but 600210 families"). Important sample/identification constraint.
- ll. 142-145, 164-165, 273-274, 282-284: **rename gymnastics** to make the independent variable name `va_cfr_g11_<subj>` for both no-sib-ctrl and with-sib-ctrl regressions, so downstream `esttab` columns line up. Pattern:
  - First spec: rename `tv` → `va_cfr_g11_<subj>`, run spec test, then rename → `va_cfr_g11_<subj>_nosibctrl`
  - Second spec: rename `tv` → `va_cfr_g11_<subj>` (same name!), spec test runs cleanly
  - For FB test: `va_cfr_g11_<subj>` → `va_cfr_g11_<subj>_temp`, then `..._nosibctrl` → `..._<subj>` (so the regressor in the FB test is named consistently), then roll back. **Brittle — single misnamed line breaks downstream tables.**
- ll. 181-262: substantial commented-out code for TFX and peer-controls variants. They are excluded from the published spec.
- ll. 287-296: collapse `if sibling_full_sample == 1 & sibling_out_sample == 1` — the FULL sibling sample (≥1 sibling) AND the outcome-matched sibling sample. So the saved school×year VA dataset is filtered to the sibling-out sample BEFORE collapsing.
- Positional arg: `if \`setlimit' == 0` use original; else use the supplied integer. **The semantics are "0 = default formula; non-zero = override".** (Not a binary toggle — `0` is sentinel.) Same in `va_sibling_out.do`.

**Reference to paper outputs:** Spec tests on the sibling sample with/without sibling controls feed Spec Test tables in OA. The corresponding FB test (`fb_test_va_cfr_g11_<subj>_sibling.ster`) feeds the sibling-leave-out FB row in **paper Table 2 (FB test for test-score VA, sibling row)**.

**Notes / open questions:** None.

---

### File: do/share/siblingvaregs/va_sibling_out.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_va (estimation — outcome)
**Lines:** 358
**Purpose:** Identical structural pattern to `va_sibling.do`, but for outcome VA (enr, enr_2year, enr_4year). Same TWO specifications (without/with sibling controls), same rename gymnastics, same FB-test logic with sibling controls as leave-out.

**Loop structure:** `foreach outcome in enr enr_2year enr_4year` (l. 99). Note this is the OUTER loop here (vs. subject in va_sibling.do).

**Inputs:** `\`va_g11_out_dataset'` (l. 74), `\`sibling_out_xwalk'` (l. 77).

**Outputs:** Per outcome:
- VAM: `$vaprojdir/estimates/sibling_va/outcome_va/vam_cfr_g11_<outcome>_nosibctrl.ster` (l. 117), `..._<outcome>.ster` (l. 151)
- Spec tests: both `$projdir/est/siblingvaregs/outcome_va/...` and `$vaprojdir/estimates/sibling_va/outcome_va/...`
- FB test: `fb_test_va_cfr_g11_<outcome>_sibling.ster` (ll. 310, 312)
- Collapsed: `$projdir/dta/common_core_va/outcome_va/va_g11_<outcome>_sibling.dta` (l. 333), `$vaprojdir/data/sibling_va/outcome_va/va_g11_<outcome>_sibling.dta` (l. 335)

**Filename naming pattern:** Same as va_sibling.do.

**Statistical specification:** Same structure. Outcome z-score variable replaced by `<outcome>` directly (no z-score transformation since outcomes are 0/1). FB test: `g11_<outcome>_r_d = g11_<outcome>_r_nosibctrl - g11_<outcome>_r` (l. 302).

**Sourced helpers / Calls:** Same set as va_sibling.do.

**ssc/community packages used:** `vam`.

**Gotchas / non-obvious behavior:**
- Drift limit at l. 92-97 same pattern; positional arg semantics same as va_sibling.do.
- l. 27-28 change-log comment: "re-ran with drift limit = 2. Still produces an error if drift limit = 3." So practical default seems to be 2 in some runs — needs disambiguation. The default-formula calculation (line 93) should be checked against `test_score_min_year`/`test_score_max_year` macros for what 0 actually evaluates to.
- ll. 165-271: extensive commented-out TFX and peer-controls variants.
- ll. 275-323: spec test and FB test code is at the END of the loop (nested under `foreach outcome` from l. 99 to l. 338). Because the "with peer controls" branches are commented, only the "no peer controls" variants run.
- l. 328-330: collapse with `(sum) n_g11_<outcome> = touse_g11_<outcome>` — but no sibling-sample filter here, unlike va_sibling.do l. 291 (`if sibling_full_sample == 1 & sibling_out_sample == 1`). **Inconsistency between va_sibling.do and va_sibling_out.do — flag as a probable bug.** The collapsed outcome-VA dataset is over the full estimation sample, not just sibling-out.

**Reference to paper outputs:** Sibling-leave-out FB tests feed **paper Table 3 (FB test for outcome VA, sibling row)**.

**Notes / open questions:** Sibling-sample filter inconsistency.

---

### File: do/share/siblingvaregs/va_sib_acs.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_va (estimation — test score, 4-spec)
**Lines:** 252
**Purpose:** **Implements the canonical 4-specification test-score VA on the sibling-ACS restricted sample.** Header doc-comment explicitly enumerates the four specs.

**Loop structure:** `foreach subject in ela math` (l. 60), inside which 4 sequential vam blocks (one per spec).

**Inputs:** `$vaprojdir/data/va_samples/va_sib_acs_restr_smp.dta` (l. 62).

**Outputs (per subject, per spec):**
- VAM: `$vaprojdir/estimates/sib_acs_restr_smp/test_score_va/vam_<subj>_<ctrl>.ster` where `<ctrl>` ∈ {`og`, `acs`, `sib`, `both`}
- Spec test: `$vaprojdir/estimates/sib_acs_restr_smp/test_score_va/spec_test_<subj>_<ctrl>.ster`
- FB tests:
  - `fb_test_<subj>_acs_og.ster` — leave out ACS, base = OG (l. 133)
  - `fb_test_<subj>_sib_og.ster` — leave out sib, base = OG (l. 173)
  - `fb_test_<subj>_sib_acs.ster` — leave out sib, base = ACS-only (l. 216)
  - `fb_test_<subj>_acs_sib.ster` — leave out ACS, base = sib-only (l. 225)
- Collapsed: `$vaprojdir/data/sib_acs_restr_smp/test_score_va/va_<subj>_sib_acs.dta` (l. 237)

**Filename naming pattern:**
- `<ctrl>` token: `og` / `acs` / `sib` / `both` — **the canonical 4-spec naming**.
- For FB tests: `fb_test_<subj>_<leaveout>_<base>.ster` where base = comparison anchor without the leave-out var. Naming convention enumerated explicitly in inline comments l. 215, 223.

**Statistical specification:** All vam invocations use `data(merge tv score_r)`, `teacher(school_id) year(year) class(school_id)`, `driftlimit(`drift_limit')`. Controls vary across the 4 specs:
1. og: standard CFR controls only
2. acs: + `\`census_controls'`
3. sib: + `\`sibling_controls'`
4. both: + `\`sibling_controls'` + `\`census_controls'`

Spec/FB tests cluster `school_id`. The macros `\`sibling_controls'` and `\`census_controls'` are defined in `macros_va.doh` (chunk 2).

**Sourced helpers / Calls:**
- `include $projdir/do/share/siblingvaregs/vafilemacros.doh` (l. 43)
- `include $vaprojdir/do_files/sbac/macros_va.doh` (l. 46)

**Path references that need updating:** `$projdir/`, `$vaprojdir/`.

**ssc/community packages used:** `vam`.

**Gotchas / non-obvious behavior:**
- No positional `args` — drift limit is hardcoded to the formula at l. 58. **Asymmetry with va_sibling.do, which takes a `setlimit` arg.** Probably because the 4-spec is run only with default drift; a manual override would require code edit.
- 4 vam runs per subject per file — **expensive**. Estimated: 4 ELA + 4 math = 8 vam invocations.
- Labels embed `\`<subj>_str'` and `\`<ctrl>_str'` macros (e.g., l. 84) — these `_str` macros come from `macros_va.doh` (chunk 2 confirmed).
- The 6 FB tests sweep all pairwise controls combinations, NOT just one-against-baseline. This is a thorough leave-out-var design.

**Reference to paper outputs:** This is the engine for **paper Table 4 (sibling-restricted-sample 4-spec rows)** test-score VA pass-through. Also feeds OA Table for sibling restricted sample spec tests / FB tests.

**Notes / open questions:** None.

---

### File: do/share/siblingvaregs/va_sib_acs_out.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_va (estimation — outcome, 4-spec)
**Lines:** 261
**Purpose:** Same 4-spec pattern as `va_sib_acs.do` but for outcome VA (enr, enr_2year, enr_4year). NOT the deep-knowledge variant (that's `va_sib_acs_out_dk.do`).

**Loop structure:** `foreach outcome in enr enr_2year enr_4year` (l. 65).

**Inputs:** `$vaprojdir/data/va_samples/va_sib_acs_out_restr_smp.dta` (l. 67).

**Outputs:** Same 4-spec × outcome pattern. VAM, spec test, 4 FB tests per outcome, plus collapsed `$vaprojdir/data/sib_acs_restr_smp/outcome_va/va_<outcome>_sib_acs.dta`.

**Filename naming pattern:** `<outcome>_<ctrl>` exactly as test-score 4-spec.

**Statistical specification:** Same structure, dependent var is outcome (no z-score), spec/FB regressors are the residuals from each spec.

**Sourced helpers / Calls:** Same.

**ssc/community packages used:** `vam`.

**Gotchas / non-obvious behavior:**
- l. 72 explicitly separates blocks — this file has 4 distinct spec blocks per outcome × 3 outcomes = 12 vam invocations total.
- The outputs feed `va_sib_acs_out_dk.do` (deep-knowledge needs the test-score VA from the same restricted sample as ingredients for DK regression) AND the pass-through-to-outcome regs in `reg_out_va_sib_acs.do`.

**Reference to paper outputs:** Outcome 4-spec sibling-restricted-sample VA estimates feed paper Tables 4-5 sibling rows.

**Notes / open questions:** None.

---

### File: do/share/siblingvaregs/va_sib_acs_out_dk.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_va (estimation — outcome, 4-spec, deep knowledge)
**Lines:** 276
**Purpose:** 4-specification deep-knowledge outcome VA on the sibling-ACS restricted sample. DK = controls for ELA AND math test-score VA from the same sample.

**Loop structure:** `foreach outcome in enr enr_2year enr_4year` (l. 70). Sample restriction = `touse_<outcome>_dk==1` (constructed in `create_va_sib_acs_out_restr_smp.do`).

**Inputs:** `$vaprojdir/data/va_samples/va_sib_acs_out_restr_smp.dta` (already has merged-in test-score VAs from the 4-spec).

**Outputs (per outcome × ctrl):**
- VAM: `vam_<outcome>_<ctrl>_dk.ster`
- Spec test: `spec_test_<outcome>_<ctrl>_dk.ster`
- 4 FB tests: `fb_test_<outcome>_acs_og_dk.ster`, `..._sib_og_dk.ster`, `..._sib_acs_dk.ster`, `..._acs_sib_dk.ster`
- Collapsed: `$vaprojdir/data/sib_acs_restr_smp/outcome_va/va_<outcome>_sib_acs_dk.dta`

**Filename naming pattern:** `<outcome>_<ctrl>_dk` — extends the canonical 4-spec naming with `_dk` suffix.

**Statistical specification:** vam controls include `\`sib_acs_dk_controls'` (l. 64 = `va_ela_og va_math_og`) — i.e., DK is built on the OG test-score VAs (not the spec-matching ones). Combined with the standard CFR controls, plus the spec-specific sibling/census controls.

**Sourced helpers / Calls:** Same.

**ssc/community packages used:** `vam`.

**Gotchas / non-obvious behavior:**
- l. 64: `local sib_acs_dk_controls va_ela_og va_math_og` — DK controls for ALL 4 specs use `_og` (original) test-score VA. So the deep-knowledge "controls for prior knowledge" is fixed across the 4 specs, only the additional sibling/census controls vary. **Important design choice — paper should clarify whether this is consistent across all DK specs or whether DK controls vary by spec.**
- 4 vam runs per outcome × 3 outcomes = 12 vam invocations (matching va_sib_acs_out.do).

**Reference to paper outputs:** DK 4-spec outputs feed pass-through-to-outcome on DK in `reg_out_va_sib_acs_dk.do`. Likely paper Table 5 / OA tables.

**Notes / open questions:** Confirm whether DK-controls fixing on `_og` is intentional.

---

### File: do/share/siblingvaregs/va_sibling_out_forecast_bias.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_va (estimation — outcome, sibling+census FB)
**Lines:** 199
**Purpose:** Run forecast-bias test on the sibling outcome VA sample using **census tract variables as the leave-out variable** (vs. va_sibling_out.do which uses sibling controls as leave-out). Conceptually: are census controls explanatory after conditioning on siblings?

**Loop structure:** `foreach outcome in enr enr_2year enr_4year` (l. 78).

**Inputs:** `\`va_g11_out_dataset'` (l. 56), `\`sibling_out_xwalk'` (l. 59).

**Outputs (per outcome):**
- VAM 1 (no sib, no acs): `vam_<outcome>_census_nosib_noacs.ster`
- VAM 2 (sib, no acs): `vam_<outcome>_census_noacs.ster`
- VAM 3 (sib + acs): `vam_<outcome>_sib_census.ster`
- Spec tests for VAMs 1, 2 (both folders)
- FB test (census leave-out, conditioning on sib): `fb_test_<outcome>_census.ster` (both folders)
- Collapsed: `$projdir/dta/common_core_va/outcome_va/va_g11_<outcome>_sibling_census.dta` and `$vaprojdir/data/sibling_va/outcome_va/...` (ll. 181, 183)

**Filename naming pattern:** `<outcome>_<spec>` where spec ∈ `census_nosib_noacs` / `census_noacs` / `sib_census`. **Note: this introduces tokens that DON'T match the canonical `og/acs/sib/both` of va_sib_acs_out.do.** This is the older naming (chronologically the FB-test-with-sibling-AND-acs was a precursor to the 4-spec design).

**Statistical specification:**
- VAM 1: standard CFR controls only.
- VAM 2: + sibling controls.
- VAM 3: + sibling + census controls.
- FB test: `<outcome>_r_d = <outcome>_r_noacs - <outcome>_r_sib_census` (l. 169), then `reg <outcome>_r_d va_<outcome>_noacs, cluster(school_id)` (l. 170). I.e., the leave-out var is the CENSUS controls, the base regressor is the sibling-only VA.

**Sourced helpers / Calls:**
- `include $projdir/do/share/siblingvaregs/vafilemacros.doh` (l. 33)
- `include \`vaprojdofiles'/sbac/macros_va.doh` (l. 42)
- `do $vaprojdir/do_files/sbac/merge_va_smp_acs.doh outcome \`va_g11_out_sibling_dataset' va_g11_out_sibling_dataset create_va \`outcome'` (l. 82) — note the 4th arg is `create_va` not `create_sample`, and the 5th arg is the outcome (used as the leave-out variable).

**Path references that need updating:** `$projdir/`, `$vaprojdir/`.

**ssc/community packages used:** `vam`.

**Gotchas / non-obvious behavior:**
- l. 62: `keep if sibling_2y_4y_controls_sample==1` — same restriction as the 4-spec.
- This file produces output with `_census_nosib_noacs`, `_census_noacs`, `_sib_census` tokens — used by `va_sibling_spec_test_tab.do` (l. 174) and `va_sibling_fb_test_tab.do` (l. 95). **It's a separate experiment from the 4-spec `va_sib_acs_out.do`** — they use different input samples (this one uses `va_g11_out_dataset` with sibling restriction; 4-spec uses `va_sib_acs_out_restr_smp.dta`).

**Reference to paper outputs:** **This is the file that produces the sibling-and-census FB-test row used in paper Table 3.** The corresponding test-score variant (sibling+L4 or sibling+census) doesn't exist here — only outcome.

**Notes / open questions:** Is this file made redundant by `va_sib_acs_out.do`? Inspect carefully whether paper uses this file's outputs or the 4-spec outputs for the same row.

---

### File: do/share/siblingvaregs/va_sibling_sample_sumstats.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_post-est (sample diagnostics)
**Lines:** 128
**Purpose:** Sample diagnostics for the sibling sample — average birth-date distance, number of unique families in test-score VA sample, distributions by year. Outputs are display-only (di / sum / tab); no saved tables.

**Loop structure:** None.

**Inputs:** `\`va_g11_dataset'` (l. 42), `\`sibling_out_xwalk'` (l. 45), `$projdir/dta/siblingxwalk/uniquesiblingpairxwalk.dta` (l. 58).

**Outputs:** Log file only. No saved .tex/.csv.

**Statistical specification:** None. `sum`, `egen group`, `tab`.

**Sourced helpers / Calls:**
- `include $projdir/do/share/siblingvaregs/vafilemacros.doh` (l. 19)
- `include \`vaprojdofiles'/sbac/macros_va.doh` (l. 28)

**ssc/community packages used:** None.

**Gotchas:** Log-only output — values in the log get hand-copied to the paper.

**Reference to paper outputs:** Paper Section 2.4 sibling sample summary statistics.

---

### File: do/share/siblingvaregs/va_sibling_est_sumstats.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_post-est (estimation diagnostics)
**Lines:** 275
**Purpose:** Diagnostic plots for sibling test-score VA: scatter va_with_sib vs va_without_sib, scatter va_with_sib vs original va, kdensity, spec-test binscatters.

**Loop structure:** Two `foreach subject in ela math` loops. Inside, outputs PDFs.

**Inputs:** `$projdir/dta/common_core_va/test_score_va/va_g11_<subject>_sibling.dta` (l. 47), `$vaprojdir/data/sbac/va_g11_<subject>.dta` (l. 149) original.

**Outputs:** Many `$projdir/out/graph/siblingvaregs/test_score_va/*.pdf` files — scatter and kdensity plots, plus spec-test binscatter PDFs.

**ssc/community packages used:** `binscatter` (line 225, 246).

**Gotchas:** All graph titles are baked into the figure (violates `figures.md` "no in-figure titles" — but this is paper-internal exploratory output, not publication-quality). Hardcoded `s1color` scheme.

**Reference to paper outputs:** Diagnostic — not a paper figure.

---

### File: do/share/siblingvaregs/va_sibling_out_est_sumstats.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_post-est (estimation diagnostics)
**Lines:** 261
**Purpose:** Outcome-VA analog of va_sibling_est_sumstats.do — same scatter / kdensity / binscatter pattern but for enr / enr_2year / enr_4year.

**Loop structure:** `foreach outcome in enr enr_2year enr_4year` (multiple times).

**Inputs:** Outcome-VA datasets in `$projdir/dta/common_core_va/outcome_va/va_g11_<outcome>_sibling.dta` and original `$vaprojdir/data/sbac/va_g11_<outcome>.dta`.

**Outputs:** PDFs in `$projdir/out/graph/siblingvaregs/outcome_va/`.

**ssc/community packages used:** `binscatter`.

**Reference to paper outputs:** Diagnostic.

---

### File: do/share/siblingvaregs/va_sib_acs_est_sumstats.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_post-est (estimation diagnostics — 4-spec test-score)
**Lines:** 208
**Purpose:** Diagnostic correlation/difference plots comparing test-score VA across (a) original sample, (b) restricted sample with og controls, (c) restricted sample with both controls.

**Loop structure:** Three blocks each with `foreach subject in ela math`. Outputs scatter (correlation) and histogram (difference) PDFs.

**Inputs:** Original `$vaprojdir/data/sbac/va_g11_<subject>.dta` (l. 59), 4-spec `$vaprojdir/data/sib_acs_restr_smp/test_score_va/va_<subject>_sib_acs.dta` (l. 76).

**Outputs:** PDFs in `$vaprojdir/figures/va_sib_acs/va_compare_sib_acs_restr_smp/` AND `$projdir/out/graph/siblingvaregs/test_score_va/va_compare_sib_acs_restr_smp/` — DUAL OUTPUT pattern.

**ssc/community packages used:** None directly.

**Reference to paper outputs:** Likely fig in OA showing VA stability across samples.

---

### File: do/share/siblingvaregs/va_sib_acs_out_est_sumstats.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_post-est (estimation diagnostics — 4-spec outcome)
**Lines:** 172
**Purpose:** Outcome-VA analog of va_sib_acs_est_sumstats.do.

**Loop structure:** `foreach outcome` × nested `foreach control in og both`.

**Inputs / Outputs:** Parallel to va_sib_acs_est_sumstats.do but for outcomes.

**Reference to paper outputs:** Diagnostic / OA.

---

### File: do/share/siblingvaregs/va_sibling_spec_test_tab.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_post-est (table generation — spec tests)
**Lines:** 215
**Purpose:** Aggregate spec-test estimates from multiple samples into a single CSV table per subject/outcome. Combines: original-sample original-VA, L4 leave-out, census leave-out, sibling sample (no sib ctrl), sibling sample (sib ctrl), and (for outcomes) sibling-census combined samples.

**Loop structure:** `foreach subject in ela math` and `foreach outcome in enr enr_2year enr_4year`.

**Inputs:** `.ster` files referenced via `vaestmacros.doh` macros (e.g., `\`<subj>_spec_va'`, `\`<subj>_spec_va_l4'`, `\`<subj>_spec_va_sibling_og'`, etc.). Plus direct `$vaprojdir/estimates/sibling_va/outcome_va/spec_test_<outcome>_census_nosib_noacs.ster`.

**Outputs:** `$projdir/out/csv/siblingvaregs/spec_test/spec_test_<subject>.csv` and `..._<outcome>.csv`.

**Filename naming pattern:** `spec_test_<subj-or-out>.csv`.

**Sourced helpers / Calls:**
- `include $projdir/do/share/siblingvaregs/vafilemacros.doh` (l. 30)
- `include $projdir/do/share/siblingvaregs/vaestmacros.doh` (l. 32)
- `include \`vaprojdofiles'/sbac/macros_va.doh` (l. 43)

**ssc/community packages used:** `esttab` (estout suite).

**Reference to paper outputs:** Spec test row in paper **Table 2 row 4 (sibling sample), row 5 (sibling sample with sibling controls)** plus Table 3 analogs for outcomes.

---

### File: do/share/siblingvaregs/va_sibling_fb_test_tab.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_post-est (table generation — FB tests)
**Lines:** 116
**Purpose:** Aggregate FB-test estimates into a CSV: L4 sample, census sample, sibling sample, and (for outcomes) sibling-census sample.

**Inputs:** `.ster` files via `vaestmacros.doh` (`\`<subj>_fb_va_l4'`, `\`<subj>_fb_va_census'`, `\`<subj>_fb_va_sibling '`) and direct path for sibling-census FB.

**Outputs:** `$projdir/out/csv/siblingvaregs/fb_test/fb_test_<subject-or-outcome>.csv`.

**Gotchas / non-obvious behavior:**
- ll. 64, 91 use `\`<subj>_fb_va_sibling '` — note the **trailing space** inside the macro reference. Stata macros with trailing space → typically ok but flag for consistency.

**Reference to paper outputs:** **Paper Table 2 row for sibling-control FB test (test score)** + Table 3 analog for outcome. The "sibling-census" row is Table 3 only (since va_sibling_out_forecast_bias.do produces only outcome-VA-side variants).

---

### File: do/share/siblingvaregs/va_sib_acs_spec_test_tab.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_post-est (table generation — 4-spec spec tests)
**Lines:** 250
**Purpose:** Three CSV tables (test-score, outcome, deep-knowledge outcome) aggregating the 4-spec spec tests on the sibling-ACS restricted sample.

**Loop structure:** Three sequential blocks: `foreach subject` for test-score, `foreach outcome` for outcome, `foreach outcome` for DK.

**Inputs:** `.ster` files at `$vaprojdir/estimates/sib_acs_restr_smp/{test_score_va,outcome_va}/spec_test_<X>_<ctrl>{_dk}.ster`.

**Outputs:**
- `$projdir/out/csv/siblingvaregs/spec_test/sib_acs_restr_smp/spec_test_sib_acs_restr_smp_score.csv`
- `..._outcome.csv`
- `..._outcome_dk.csv`

**ssc/community packages used:** `esttab`.

**Reference to paper outputs:** OA tables for the 4-spec sibling-ACS restricted sample spec tests.

---

### File: do/share/siblingvaregs/va_sib_acs_fb_test_tab.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_post-est (table generation — 4-spec FB tests)
**Lines:** 168
**Purpose:** Three CSV tables aggregating the 4 FB tests per spec on the sibling-ACS restricted sample (test-score, outcome, deep-knowledge outcome).

**Inputs:** `.ster` files at `$vaprojdir/estimates/sib_acs_restr_smp/{test_score_va,outcome_va}/fb_test_*`.

**Outputs:** CSVs at `$projdir/out/csv/siblingvaregs/fb_test/sib_acs_restr_smp/fb_test_sib_acs_restr_smp_{score,outcome,outcome_dk}.csv`.

**Reference to paper outputs:** OA tables, sibling-restricted FB tests.

---

### File: do/share/siblingvaregs/va_sibling_vam_tab.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_post-est (table generation — VAM coefficients)
**Lines:** 81
**Purpose:** Output table of vam regression coefficients for sibling test-score and outcome VA WITH sibling controls.

**Inputs:** `\`<subj>_sibling_vam'`, `\`<outcome>_sibling_vam'` macros from `vaestmacros.doh`.

**Outputs:** `$projdir/out/csv/siblingvaregs/vam/test_score_sibling_vam.csv`, `outcome_sibling_vam.csv`.

**Reference to paper outputs:** Diagnostic / appendix.

---

### File: do/share/siblingvaregs/va_sib_acs_vam_tab.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_post-est (table generation — 4-spec VAM coefficients)
**Lines:** 179
**Purpose:** Three CSV tables (test-score, outcome, DK-outcome) of vam coefficients for the 4-spec sibling-ACS restricted sample.

**Inputs:** `.ster` files at `$vaprojdir/estimates/sib_acs_restr_smp/`.

**Outputs:** CSVs at `$projdir/out/csv/siblingvaregs/vam/sib_acs_restr_smp/{test_score,outcome,outcome_dk}_sib_acs_restr_smp_vam.csv`.

**Reference to paper outputs:** OA appendix tables.

---

### File: do/share/siblingvaregs/reg_out_va_sib_acs.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_va (pass-through estimation — test-score VA → enrollment, 4-spec)
**Lines:** 246
**Purpose:** **Pass-through ρ regressions on the sibling-ACS restricted sample.** Three regression families:
1. Outcome on single-subject test-score VA (l. 87) — 3 outcomes × 2 subjects × 4 specs = 24 regs
2. Outcome on both-subject test-score VA (l. 105) — 3 × 4 = 12 regs
3. Heterogeneity by prior-score deciles (l. 144, 167) — 48 + 24 = 72 regs
4. Heterogeneity by SED status × prior decile (l. 204, 218) — 96 regs (but only single-subject)

Total: ~ 200+ regressions.

**Loop structure:** Heavily nested foreach: outcome × subject × control × prior_subject × sed_status.

**Inputs:** `$vaprojdir/data/va_samples/va_sib_acs_out_restr_smp.dta` (l. 56), `$vaprojdir/data/sib_acs_restr_smp/test_score_va/va_<subject>_sib_acs.dta` (l. 61), `$vaprojdir/data/sbac/prior_decile_original_sample.dta` (l. 127).

**Outputs:** `.ster` files at `$vaprojdir/estimates/sib_acs_restr_smp/persistence/`. Naming patterns:
- `reg_<outcome>_va_<subject>_<control>.ster`
- `reg_<outcome>_va_ela_math_<control>.ster`
- `het_reg_<outcome>_va_<subject>_<control>_x_prior_<prior_subject>.ster`
- `het_reg_<outcome>_va_ela_math_<control>_x_prior_<prior_subject>.ster`
- `het_reg_<outcome>_va_<subject>_<control>_x_prior_<prior_subject>_sed{0,1}.ster`

**Filename naming pattern:** Adds `het_reg_` prefix and `_x_prior_<sub>` token, plus `_sed{0,1}` suffix. `<control>` continues the canonical `og/acs/sib/both`.

**Statistical specification:** `reg <outcome> va_<subj>_<ctrl> <controls>, cluster(school_id)` (or `cluster(cdscode)` for the heterogeneity regs — l. 151, 174, 211, 224 — **inconsistency: heterogeneity regs cluster at cdscode, not school_id**).

**ssc/community packages used:** None directly (uses base `reg`, `estadd`).

**Gotchas / non-obvious behavior:**
- **Cluster level inconsistency:** main pass-through regs cluster `school_id` (ll. 94, 112); heterogeneity regs cluster `cdscode` (ll. 151, 174, 211, 224). Same issue as flagged in chunk 4 for `va_het.do:158`. **This is the same pattern — likely intentional for heterogeneity but should be flagged in the paper.**
- VA estimates are **z-score standardized** within each merge (ll. 65-69) — `replace va = va - r(mean); replace va = va / r(sd)`. Normalizes ρ coefficients to per-σ effects.
- The DK pass-through file is separate (`reg_out_va_sib_acs_dk.do`) — NOT in this file.

**Reference to paper outputs:** **Paper Table 4 (pass-through to enrollment, 4-spec sibling-restricted-sample rows)** and Figs 5-6 / OA Figs C.1-C.2 heterogeneity panels.

**Notes / open questions:** The `cdscode`-vs-`school_id` cluster inconsistency.

---

### File: do/share/siblingvaregs/reg_out_va_sib_acs_dk.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_va (pass-through estimation — DK VA → enrollment, 4-spec)
**Lines:** 166
**Purpose:** Pass-through regressions of outcome on **DK outcome VA** (4-spec) on the sibling-ACS restricted sample. Two specifications:
1. Outcome on all 3 DK outcome VAs simultaneously (l. 81)
2. Outcome on matched DK VA (l. 105) — i.e., enr-VA → enr, etc.
Plus heterogeneity by prior decile (l. 139).

**Loop structure:** outcome × control × (prior_subject for het).

**Inputs:** `$vaprojdir/data/va_samples/va_sib_acs_out_restr_smp.dta`, `$vaprojdir/data/sib_acs_restr_smp/outcome_va/va_<outcome>_sib_acs_dk.dta`, `$vaprojdir/data/sbac/prior_decile_original_sample.dta`.

**Outputs:**
- `reg_<outcome>_va_allenr_<control>_dk.ster` (3 outcomes × 4 ctrls = 12 regs, all-3-outcome-VA-on-RHS)
- `reg_<outcome>_va_<outcome>_<control>_dk.ster` (matched, 12 regs)
- `het_reg_<outcome>_va_<outcome>_<control>_dk_x_prior_<prior_subject>.ster` (24 regs)

**Filename naming pattern:** `_dk` suffix on outcome side: `va_<outcome>_<control>_dk` token. Heterogeneity follows the same pattern.

**Statistical specification:** `reg <outcome> va_..._dk <controls>, cluster(school_id)` for main, `cluster(cdscode)` for heterogeneity.

**Gotchas:** Same cluster inconsistency as reg_out_va_sib_acs.do.

**Reference to paper outputs:** Paper Table 5 (DK pass-through) sibling-restricted rows + heterogeneity figs.

---

### File: do/share/siblingvaregs/reg_out_va_sib_acs_tab.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_post-est (table generation — pass-through regs)
**Lines:** 240
**Purpose:** Aggregate the test-score-VA pass-through `.ster` files (4-spec) into CSV tables.

**Loop structure:** `foreach subject` × `foreach outcome` × `foreach control` for main; `foreach subject` × `foreach prior_subject` × `foreach outcome` × `foreach control` for het.

**Inputs:** `.ster` files at `$vaprojdir/estimates/sib_acs_restr_smp/persistence/`.

**Outputs:** CSVs at `$projdir/out/csv/siblingvaregs/persistence/sib_acs_restr_smp/reg_out_score_va/`.

**ssc/community packages used:** `esttab`.

**Reference to paper outputs:** Paper Table 4 sibling 4-spec rows, OA equivalents.

---

### File: do/share/siblingvaregs/reg_out_va_sib_acs_fig.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_post-est (figure generation — heterogeneity)
**Lines:** 342
**Purpose:** Produce heterogeneity-by-prior-decile bar+CI figures for outcome-on-test-score-VA regressions, both standalone and combined with original-sample equivalents into multi-panel figures.

**Loop structure:** Outcome × subject × control × prior_subject (× sed_status for the SED variant).

**Inputs:** `.ster` files at `$vaprojdir/estimates/sib_acs_restr_smp/persistence/`. Original-sample `.gph` files at `$vaprojdir/gph_files/sbac/` (for combining into panels — these come from chunk 3/4 territory).

**Outputs:** PDFs in TWO trees: `$vaprojdir/figures/va_sib_acs/het_reg_prior_score/` AND `$projdir/out/graph/siblingvaregs/persistence/sib_acs_restr_smp/het_reg_prior_score/` (also `combined_panels/...`). Plus saved `.gph` files for panel combination.

**ssc/community packages used:** **`parmest`** (l. 114, 164, 250) — converts estimation results to a dataset for plotting. Required dependency.

**Filename naming pattern:** `het_reg_<outcome>_va_<subject>_<control>_x_prior_<prior_subject>{_sed<0|1>}.pdf`.

**Gotchas / non-obvious behavior:**
- l. 118 vs l. 254: `gen xtile = subinstr(substr(parm, 1, strpos(parm, ".")-1), "b", "", .)` (l. 118) vs `gen xtile = subinstr(substr(parm, 1, strpos(parm, ".")), "b", "", .)` (l. 254) — **off-by-one inconsistency in substring extraction**. l. 118 ends at `strpos(parm, ".") - 1`; l. 254 ends at `strpos(parm, ".")` — i.e., the latter includes the literal "." in the extracted string, which destring then truncates. Functionally equivalent due to destring's tolerance, but inconsistent. **Flag as a minor bug per change log 11/28/2022.**
- ll. 213-216 reference `$vaprojdir/gph_files/sbac/reg_<outcome>_va_<subject>_hetero_prior_<prior_subject>.gph` — these are saved by chunk 4's main-pass-through file. So **panel combination requires both chunk 4 main-pass-through and this file's outputs to exist before running**.
- **Default Stata scheme `s1color` is set on l. 27** — figures NOT publication-quality without post-processing.

**Reference to paper outputs:** **Paper Fig 6 (heterogeneity by prior decile, 4-spec sibling-restricted rows)** and OA Figs C.1, C.2.

---

### File: do/share/siblingvaregs/reg_out_va_sib_acs_dk_fig.do

**Owner:** Christina Sun.
**Pipeline phase:** sibling_post-est (figure generation — DK heterogeneity)
**Lines:** 162
**Purpose:** Same structure as reg_out_va_sib_acs_fig.do but for DK VA. Produces het-by-prior-decile bar+CI figs and combines into panels with original-sample DK equivalents.

**Inputs:** `.ster` files at `$vaprojdir/estimates/sib_acs_restr_smp/persistence/het_reg_<outcome>_va_<outcome>_<control>_dk_x_prior_<prior_subject>.ster`. `.gph` files at `$vaprojdir/gph_files/sbac/reg_<outcome>_va_cfr_g11_<outcome>_dk_hetero_prior_<prior_subject>.gph` (from chunk 4 main DK).

**Outputs:** PDFs and `.gph` files at `$vaprojdir/figures/va_sib_acs/het_reg_dk_prior_score/` and `$projdir/out/graph/siblingvaregs/persistence/sib_acs_restr_smp/het_reg_dk_prior_score/`.

**ssc/community packages used:** `parmest`.

**Reference to paper outputs:** Paper DK heterogeneity panels (likely OA).

---

### File: do/share/siblingvaregs/vafilemacros.doh

(Already in chunk 2.) 25 lines. Defines local macros for sibling-VA file paths. **Critical for siblingoutxwalk.do — it provides `\`ufamilyxwalk'` (l. 22) and `\`sibling_out_xwalk'` (l. 24).**

---

### File: do/share/siblingvaregs/vaestmacros.doh

(Already in chunk 2.) 161 lines. Defines local macros for `.ster` filenames. The `_str` macros (e.g., `\`ela_str'`, `\`enr_str'`, `\`og_str'`, `\`both_str'`, `\`acs_str'`, `\`sib_str'`) used throughout sibling-VA files come from the OTHER macros file `macros_va.doh` (Matt's, in `$vaprojdir/do_files/sbac/`), NOT from this one. This file holds `.ster` filename macros.

---

## Chunk 5 Synthesis

### N1 Verdict: **SAFE to relocate `siblingoutxwalk.do` to `sibling_xwalk/`**

Concrete dependency-trace evidence:

1. **What `siblingoutxwalk.do` consumes** (its INPUTS):
   - `$vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta` (data)
   - `$vaprojdir/do_files/merge_k12_postsecondary.doh` (Matt's helper)
   - `\`ufamilyxwalk'` = `$projdir/dta/siblingxwalk/ufamilyxwalk.dta` (output of `uniquefamily.do` in `siblingxwalk/`)
   - `vafilemacros.doh` (an include — easily re-routable)
   - `macros_va.doh` (Matt's, on $vaprojdir — unchanged)

   **None of its inputs come from a `siblingvaregs/` data output.** It reads only from k-12 source data, the `siblingxwalk/` family ID, and shared Matt-helpers.

2. **What `siblingoutxwalk.do` produces** (its OUTPUTS):
   - `$projdir/dta/common_core_va/k12_postsecondary_out_merge.dta` — into `common_core_va/`
   - `$projdir/dta/siblingxwalk/sibling_out_xwalk.dta` — into `siblingxwalk/` ← **the canonical output is already in the siblingxwalk/ folder!**

3. **Who consumes `sibling_out_xwalk.dta`** (downstream consumers): `createvasample.do`, `siblingvasamples.do`, `va_sibling.do`, `va_sibling_out.do`, `va_sibling_out_forecast_bias.do`, `create_va_sib_acs_restr_smp.do`, `create_va_sib_acs_out_restr_smp.do`. All of these are in `siblingvaregs/` and access the file via the `\`sibling_out_xwalk'` macro. After relocation, the macro still resolves to the same path (it's `$projdir/dta/siblingxwalk/sibling_out_xwalk` regardless of where the do file lives).

4. **Is anything in `siblingvaregs/` called by `siblingoutxwalk.do`?** No. It only includes `vafilemacros.doh` (a macro file) and `macros_va.doh` (Matt's). Both can be referenced from anywhere.

5. **Master.do reference**: `master.do:103` calls `do $projdir/do/share/siblingvaregs/siblingoutxwalk.do` — this needs to update to `sibling_xwalk/siblingoutxwalk.do` after relocation.

**Verdict: SAFE to relocate. Update master.do l. 103 path. No circular reference.** (The output dataset's destination path `$projdir/dta/siblingxwalk/` is already in the right place.)

### Sibling-matching specifics (paper Q1)

**Address fields joined:** Full address — `street_address_line_one street_address_line_two city state zip_code` (5-component join). Note: `zip_code` is included for grouping (egen group, l. 49) but NOT for the duplicates report (l. 41) — slight inconsistency.

**Surname field:** `last_name` as-is (no normalization, no fuzzy matching).

**"Same year" interpretation:** Within-year matches (k12_xwalk_name_address_year) require enrolled in the SAME calendar year — see `egen group(year last_name street_address_line_one ...)` l. 49. Across-year crosswalk drops the year (l. 86).

**Transitive closure:** Implemented via Haghish's **`group_twoway`** package (uniquefamily.do l. 32). The two arguments are (within-year-family-ID, student-ID). The package computes connected components over both, so a student in family A in year 1 and family B in year 2 (same student, different addresses or surnames) is linked transitively.

**Family moves:** Handled by transitive closure across years.

**Surname changes (remarriage):** NOT explicitly handled. If a student's surname changes across years and their address also changes, the link breaks. If only the surname changes but address is constant, transitive closure via the SSID would still link them (since the within-year groups share the SSID).

**Data-entry typos:** Not explicitly handled. The match is exact-string.

**Quality filters:**
- `drop if strlen(street_address_line_one) <= 1` (siblingmatch.do l. 22) — drops 0/1-char addresses.
- `drop if missing(state_student_id)` (l. 23).
- `bysort siblings_name_address_year: drop if _N==1` (l. 53) — drops singletons (no siblings).
- `drop if numsiblings >= 9` (uniquefamily.do l. 53) — caps at 10 children/family. **Promote to ADR.**

### 4-spec convention for sibling-restricted sample

Confirmed from `va_sib_acs.do` ll. 1-9 doc-comment and code structure:

| Spec | `<ctrl>` token | Controls beyond CFR baseline |
|------|----------------|------------------------------|
| 1 | `og` | None (CFR baseline only) |
| 2 | `acs` | + `\`census_controls'` |
| 3 | `sib` | + `\`sibling_controls'` |
| 4 | `both` | + `\`sibling_controls'` + `\`census_controls'` |

The `_str` macros (`og_str`, `acs_str`, `sib_str`, `both_str`) for human-readable labels come from `macros_va.doh` in `$vaprojdir/do_files/sbac/` (Matt's, chunk 2 confirmed). Filename grammar: `<prefix>_<subj-or-out>_<ctrl>{_dk}.ster` and FB tests use `<prefix>_<subj-or-out>_<leaveout>_<base>{_dk}.ster`.

The 4-spec governs three estimators in three files:
- `va_sib_acs.do` (test-score VA, 4 specs × 2 subjects = 8 vam)
- `va_sib_acs_out.do` (outcome VA, 4 specs × 3 outcomes = 12 vam)
- `va_sib_acs_out_dk.do` (DK outcome VA, 4 specs × 3 outcomes = 12 vam, with `_dk` suffix)

### Positional-argument semantics for `va_sibling`/`va_sibling_out`

From `va_sibling.do` ll. 51, 96-101 and `va_sibling_out.do` ll. 51, 92-97:

```stata
args setlimit
...
if `setlimit' == 0 {
  local drift_limit = max(`test_score_max_year' - `test_score_min_year' - 1, 1)
}
else {
  local drift_limit = `setlimit'
}
```

**Semantics:**
- `0` = sentinel, **use the default formula**: `max(test_score_max_year - test_score_min_year - 1, 1)`.
- Any non-zero integer = override drift limit to that value.

The change log of `va_sibling_out.do` ll. 26-28 notes: "re-ran with drift limit = 2. Still produces an error if drift limit = 3" — suggesting that for the sibling outcome sample, drift_limit=3 hits a numerical issue (possibly singular variance matrix), and 2 is the working override. Christina has called `va_sibling_out 0` first per the change-log, then re-run with `va_sibling_out 2` if errors arise.

The 4-spec files `va_sib_acs.do`, `va_sib_acs_out.do`, `va_sib_acs_out_dk.do` do NOT take a positional arg — they hardcode the formula. **This is an inconsistency: the older sibling-only files (va_sibling, va_sibling_out) are tunable; the 4-spec files are not.** Worth flagging: if the 4-spec files ever fail with the default drift, manual code edit is required.

### Paper-output mapping

| Sibling-VA artifact | Paper destination |
|---|---|
| `va_sibling.do` → `fb_test_va_cfr_g11_<subj>_sibling.ster` | **Paper Table 2 (FB test for test-score VA, sibling-control leave-out row)** |
| `va_sibling_out.do` → `fb_test_va_cfr_g11_<outcome>_sibling.ster` | **Paper Table 3 (FB test for outcome VA, sibling-control leave-out row)** |
| `va_sibling_out_forecast_bias.do` → `fb_test_<outcome>_census.ster` | **Paper Table 3 (FB test for outcome VA, sibling+census combined row)** |
| `va_sibling_spec_test_tab.do` → `spec_test_<X>.csv` | Spec tests for paper Tables 2-3 (sibling sample columns) |
| `va_sibling_fb_test_tab.do` → `fb_test_<X>.csv` | FB tests for paper Tables 2-3 (sibling rows) |
| `va_sib_acs.do` → `vam_<subj>_<ctrl>.ster`, spec/FB | **Paper OA: 4-spec test-score VA spec/FB tests** |
| `va_sib_acs_out.do` → `vam_<outcome>_<ctrl>.ster`, spec/FB | **Paper OA: 4-spec outcome VA** |
| `va_sib_acs_out_dk.do` → `vam_<outcome>_<ctrl>_dk.ster`, spec/FB | **Paper OA: 4-spec DK VA** |
| `va_sib_acs_spec_test_tab.do` → CSVs | OA tables for 4-spec spec tests |
| `va_sib_acs_fb_test_tab.do` → CSVs | OA tables for 4-spec FB tests |
| `va_sib_acs_vam_tab.do` → CSVs | OA tables for VAM coefficients |
| `reg_out_va_sib_acs.do` → ρ regs | **Paper Table 4 (pass-through, sibling-restricted-sample 4-spec rows)** |
| `reg_out_va_sib_acs_dk.do` → DK ρ regs | **Paper Table 5 (DK pass-through, sibling-restricted rows)** |
| `reg_out_va_sib_acs_tab.do` → CSVs | Tables for Table 4 sibling rows + OA |
| `reg_out_va_sib_acs_fig.do` → het-prior-decile figs | **Paper Fig 6 sibling rows + OA Figs C.1, C.2** |
| `reg_out_va_sib_acs_dk_fig.do` → DK het figs | OA DK heterogeneity panels |
| `va_sibling_sample_sumstats.do` (log-only) | Paper Section 2.4 sample size text |
| `va_sibling_est_sumstats.do`, `va_sibling_out_est_sumstats.do`, `va_sib_acs_est_sumstats.do`, `va_sib_acs_out_est_sumstats.do` | Diagnostic only / OA sup figs |

**Distance-FB row mystery (chunk 3 open question):** The "distance-FB" row mentioned in chunk 3 for paper Tables 2/3 row 6 does NOT live in the sibling-VA territory. It must live in `va_distance_*` files (chunks 6-7 territory or in main VA chunk 3 territory not yet read).

### New naming tokens found

Compared to chunk 4's catalog (`nw/_m/_wt`):
- **`og` / `acs` / `sib` / `both`** (4-spec control tokens) — **major addition** for the 4-spec analysis.
- **`_dk`** suffix for deep-knowledge variants.
- **`_nosibctrl`** — VAM with no sibling control (used in va_sibling.do).
- **`_nocontrol`** — spec test on sibling sample without sibling controls (some files; inconsistent vs `_nosibctrl`).
- **`_sibling`** suffix on .ster files (vs the `_<ctrl>` token system) — this is the older naming, used by va_sibling.do / va_sibling_out.do.
- **`_census_nosib_noacs` / `_census_noacs` / `_sib_census`** — older 3-way ad-hoc tokens used only in `va_sibling_out_forecast_bias.do`.
- **`_x_prior_<subject>`** — heterogeneity-by-prior-decile pattern.
- **`_sed{0,1}`** — heterogeneity-by-SED-status pattern.
- **`het_reg_` prefix** — heterogeneity regression token.
- **`old1_sib_<outcome>` / `old2_sib_<outcome>`** — lag1/lag2 older-sibling outcome variables (siblingoutxwalk.do l. 190, 194).
- **`touse_<outcome>_dk`** / **`touse_<outcome>_<subject>_og`** — DK-specific touse markers (in `create_va_sib_acs_out_restr_smp.do`).

The sibling-VA territory is **NOT canonically named** with the same `og/acs/sib/both` system across all files. The older sibling-only files use `_sibling` / `_nosibctrl` / `_nocontrol`, the 4-spec files use the `og/acs/sib/both` system, and `va_sibling_out_forecast_bias.do` uses ad-hoc tokens. **This is a naming-inconsistency hazard for consolidation; recommend standardizing on `og/acs/sib/both` and migrating the older patterns.**

### ssc/community package full list (combined across chunks)

Confirmed used in chunks 1-5:
- **`vam`** — Stepner v2.0.1 (chunk 1, used everywhere VAM is estimated)
- **`reghdfe`** (chunk 1, main VA via Matt's helpers)
- **`ivreghdfe`** (chunk 1, settings.do)
- **`estout` / `esttab`** (chunks 3-5, table output everywhere)
- **`coefplot`** (chunks 3-4, settings.do)
- **`palettes`**, **`cleanplots`** (settings.do)
- **`egenmore`** (settings.do)
- **`regsave`** (settings.do)
- **`cdfplot`** (settings.do)
- **`binscatter`** / **`binscatter2`** (chunks 3-5, va_sibling_est_sumstats.do l. 225)
- **`group_twoway`** — Haghish (chunk 5, uniquefamily.do l. 32) — **NEW dependency identified in chunk 5**
- **`rangestat`** — Picard/Cox (chunk 5, siblingoutxwalk.do l. 140) — **NEW dependency identified in chunk 5**
- **`parmest`** — Newson (chunk 5, reg_out_va_sib_acs_fig.do l. 114) — **NEW dependency identified in chunk 5**
- `texsave` (settings.do)

Total ~14 packages. The consolidated `settings.do` install-block needs all of these, plus `group_twoway` (which is NOT on SSC — Haghish's site only) and `rangestat`/`parmest` (which ARE on SSC).

### Anomalies / bugs (parallel to prior chunks)

1. **`siblingpairxwalk.do` l. 24**: `rename middle_intl sibling_middle_intl` — but `uniquelinkedfamilyclean.dta` (per uniquefamily.do l. 54 keep list) doesn't include `middle_intl`. Will silently fail or error. **Minor bug**.

2. **`siblingmatch.do` l. 41 vs l. 49**: duplicates report uses 6 keys; egen group uses 7 keys (with zip_code). Slight inconsistency. **Documentation issue**, not bug.

3. **`uniquefamily.do` l. 56**: `numsiblings_exclude_sef` typo for "self". Cosmetic.

4. **`va_sibling_out.do` l. 328-330 vs `va_sibling.do` l. 287-291**: outcome-VA collapse has no `if sibling_full_sample == 1 & sibling_out_sample == 1` filter; test-score-VA collapse does. **Inconsistency — possible bug**: outcome-VA collapsed dataset spans more obs than sibling-only.

5. **`reg_out_va_sib_acs.do` l. 151 / 174 / 211 / 224**: heterogeneity regs cluster on `cdscode`, not `school_id` (which is used in main pass-through regs ll. 94, 112). **Cluster-level inconsistency** — same flag as chunk 4's `va_het.do:158`.

6. **`reg_out_va_sib_acs_fig.do` l. 118 vs l. 254**: substring-extraction off-by-one — `strpos(parm, ".") - 1` vs `strpos(parm, ".")`. Functionally equivalent due to destring tolerance; cosmetic.

7. **`siblingvasamples.do` ll. 32, 50**: `timer on 1` called twice. No harm; cosmetic.

8. **`vafilemacros.doh` l. 21**: `local siblingxwalk` defined but appears unused in any of the do files I've read (the canonical sibling crosswalk macro used downstream is `\`sibling_out_xwalk'`). Dead local — flag for cleanup.

9. **`createvasample.do` ll. 51-56 vs l. 73-74**: tempfile created, then permanent file saved with same name, then tempfile erased. Not a bug, but confusing flow.

10. **`siblingoutxwalk.do` l. 71** vs **`createvasample.do`**: both define output `k12_postsecondary_out_merge.dta` (l. 71 of siblingoutxwalk.do at `$projdir/dta/common_core_va/k12_postsecondary_out_merge.dta`). The change-log notes this was moved from `createvasample.do` to here on 07/27/2023. **Verify** that `createvasample.do` no longer also saves it (I read createvasample.do — it does not save this file, it only saves `va_dataset.dta`, `va_g11_dataset.dta`, `va_g11_out_dataset.dta`). OK.

11. **`va_sibling_fb_test_tab.do` ll. 64, 91**: `\`<subj>_fb_va_sibling '` — trailing space inside macro reference. Harmless but stylistic.

12. **Naming-system fragmentation across sibling-VA files**: 4-spec files use `og/acs/sib/both`; older files use `_sibling/_nosibctrl/_nocontrol/_census_nosib_noacs/...`; `va_sibling_out_forecast_bias.do` uses ad-hoc tokens. Not a bug per se but a major consolidation hazard.

13. **`va_sib_acs_*` files lack the `args setlimit` positional arg** that `va_sibling*.do` have. If 4-spec drift fails, manual edit required.

14. **Dual-output pattern**: many post-est diagnostic files write PDFs to BOTH `$projdir/out/graph/...` AND `$vaprojdir/figures/...`. Path-rerouting must update both for consolidation.

(Combined with chunks 1-4, total bugs = ~16 + 7 new from chunk 5 = ~23.)

### Open questions

**For user (Christina):**
- Q5.1: Confirm 10-child cap (`uniquefamily.do` l. 53) is documented in paper or appendix.
- Q5.2: Clarify whether DK controls in `va_sib_acs_out_dk.do` (fixed on `_og` test-score VA across all 4 specs) is intentional or a bug.
- Q5.3: Is `va_sibling_out_forecast_bias.do` redundant given `va_sib_acs_out.do`? Both produce outcome-VA-with-sibling-and-census-controls FB tests, but with different sample restrictions and naming conventions. Confirm which feeds paper Table 3.
- Q5.4: Confirm the cluster-level inconsistency in heterogeneity regs (`cdscode` vs `school_id`) is intentional, or fix.
- Q5.5: `va_sibling_out.do` collapse missing the sibling-sample filter — bug or intentional?
- Q5.6: Should the older `_sibling/_nosibctrl/_nocontrol` filename naming be migrated to the canonical `og/acs/sib/both` system at consolidation, or kept for backward compatibility?

**For downstream chunks (6-10):**
- Chunk 6/7: The "distance-FB" row in paper Tables 2/3 row 6 must live in `va_distance_*` files. Confirm there.
- Chunk 6/7: Verify `\`siblingxwalk'` macro (`vafilemacros.doh` l. 21 — `siblingpairxwalk.dta` path) is actually consumed somewhere downstream (sibling-pair-level regressions?), since I saw no consumer in chunk 5.
- Chunk 8 (master.do): l. 103 `do siblingvaregs/siblingoutxwalk.do` must update to `siblingxwalk/siblingoutxwalk.do` after relocation. Document in consolidation plan.

**Resolved questions from prior chunks:**
- Chunk 3's "what does positional `0` arg do for va_sibling/va_sibling_out": **resolved** — sentinel meaning "use default formula".
- The 4-spec convention: **resolved** — `og/acs/sib/both`, defined in `va_sib_acs.do` and friends.
