# Chunk 5 — Sibling Crosswalk + Sibling-VA Regressions — Round-2 Verified Audit

**Scope:** 32 files in `caschls/do/share/siblingxwalk/` (3) + `caschls/do/share/siblingvaregs/` (29).
The prompt listed 33 files but `reg_out_va_sib_acs_dk_tab.do` does not exist in the directory (verified by `ls`); only `reg_out_va_sib_acs_dk_fig.do` exists. So actual count is 32.

**Source paths:**

- `$projdir` = `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/`
- `$vaprojdir` = `/Users/christinasun/github_repos/cde_va_project_fork/` (and the live counterpart on Scribe at `/home/research/ca_ed_lab/projects/common_core_va`)

**Token glossary used by the chunk-5 layer:**

- `og` / `acs` / `sib` / `both` — the canonical 4-spec sibling-acs-restricted control vector (no controls / + ACS / + sibling / + ACS+sibling), used pervasively in `va_sib_acs*` and `reg_out_va_sib_acs*` files.
- `_dk` — "deep knowledge": outcome VA that controls additionally for ELA and math test-score VA on the same sample. Filenames: `va_sib_acs_out_dk.do`, `reg_out_va_sib_acs_dk*`.
- `_sibling`, `_nosibctrl`, `_nocontrol` — older naming style for the sibling-only sample (no ACS overlay), in `va_sibling.do`, `va_sibling_out.do`, `va_sibling_*_est_sumstats.do`, `va_sibling_*_tab.do`. `_nosibctrl`/`_nocontrol` are inconsistent siblings.
- `_census_nosib_noacs`, `_census_noacs`, `_sib_census` — ad-hoc 3-way naming used only in `va_sibling_out_forecast_bias.do` (the predecessor of `va_sib_acs_out.do`).
- `_x_prior_<subject>` — heterogeneity by prior-decile, with subject in `{ela, math}` (heterogeneity is by *prior* score subject, not necessarily the VA subject).
- `_sed{0,1}` — heterogeneity by `econ_disadvantage` status (SED).
- `het_reg_` prefix — heterogeneity regression estimates.

---

## Per-file inventory

### 1. `siblingmatch.do` (108 lines)

**Path:** `$projdir/do/share/siblingxwalk/siblingmatch.do`
**Purpose:** Use CST data 2004–2013 to match students with their siblings by (last_name, address, year) and by (last_name, address) across years. Two outputs corresponding to the two match strategies.

**Inputs:**

- L16: `append using $cstdtadir/cst_`year' ` for years 2004–2013 (10 CST yearly datasets); keepvars: `state_student_id birth_date year first_name middle_intl last_name street_address_line_one street_address_line_two city state zip_code` (L16-18).

**Outputs:**

- L68: `save $projdir/dta/siblingxwalk/k12_xwalk_name_address_year` — match on same year + last name + full address.
- L104: `save $projdir/dta/siblingxwalk/k12_xwalk_name_address` — match across years on last name + full address.
- L12, L108: log to `$projdir/log/share/siblingxwalk/siblingmatch.{smcl,log}`.

**Calls:** none (no `do` or `include`).

**Path references:** `$cstdtadir`, `$projdir`. Both global; settings.do branches on hostname.

**Paper outputs:** Upstream — no direct paper artifact. Feeds `uniquefamily.do`.

**Line-cited bugs / anomalies:**

- L22: `drop if strlen(street_address_line_one) <= 1` — drops both empty strings AND single-character addresses ("Y", "0"). This is a deliberate quality filter (commented at L21 as a workaround for `missing()` not catching "Y" or "0"); not a bug, but the threshold is arbitrary.
- L41, L43: duplicates check uses `state_student_id year street_address_line_one street_address_line_two city state` — does NOT include zip_code or last_name. Comment at L37-40 explains: middle_initial 38.56% missing, zip 7.36% missing, so excluding them avoids treating same person as different.
- L49: `egen long siblings_name_address_year = group(year last_name street_address_line_one street_address_line_two city state zip_code), mi` — note the `, mi` flag. Per Stata docs, this groups missing into the same group. Comment L47-48 calls this out: "Treat missing as any other variables and group observations with match vars missing into the same family." This means students who all have missing addresses can collapse into one mega-family. Mitigated by L22 dropping addresses ≤1 char, but two students with the same last name and missing street_line_two might still be merged.
- L86: same `, mi` issue for the cross-year match.
- No surname normalization (case, accent, whitespace) is applied — the raw `last_name` field is used as-is.

### 2. `uniquefamily.do` (78 lines)

**Path:** `$projdir/do/share/siblingxwalk/uniquefamily.do`
**Purpose:** Take the same-year sibling crosswalk and use `group_twoway` to compute transitive closure of (family_id ↔ ssid), producing one `ufamilyid` per student that links siblings observed in different years even after moves.

**Inputs:**

- L18: `use $projdir/dta/siblingxwalk/k12_xwalk_name_address_year` (output of `siblingmatch.do`).

**Outputs:**

- L35: `save $projdir/dta/siblingxwalk/uniquelinkedfamilyraw` (raw, before deduping per ssid).
- L49: `graph export $projdir/out/graph/siblingxwalk/numsiblingdist.png` (histogram of `numsiblings`).
- L50: `save $projdir/dta/siblingxwalk/uniquelinkedfamilyclean` (one record per ssid, before max-children cap).
- L74: `save $projdir/dta/siblingxwalk/ufamilyxwalk` (one record per ssid, capped at 10 children, with birth_order, sibling_full_sample=1).
- L16, L78: log.

**Calls:** none. Comment L21 references SSC package `group_twoway`.

**Transitive closure (key methodological step):**

- L24: tostring `siblings_name_address_year`, format("%17.0f") so it's disjoint from numeric ssid.
- L27: prepend "family" to siblings_name_address_year so namespaces don't clash.
- L32: `group_twoway siblings_name_address_year state_student_id, generate(ufamilyid)` — connected components over (family-id, ssid) edges.

**Quality filters:**

- L53: `drop if numsiblings >= 9` — caps at 10 children per family; comment at L52 says "anything above that likely matching error". This is the explicit "max-children cap".
- L48: `hist numsiblings` and exported PNG — diagnostic only.

**Variables produced (L56-71):** `numsiblings_exclude_sef`, `numsiblings_total`, `birth_order`, `numsiblings_older`, `sibling_full_sample`.

**Paper outputs:** Upstream. Feeds `siblingpairxwalk.do` and (via `ufamilyxwalk` macro) `siblingoutxwalk.do`.

**Line-cited bugs / anomalies:**

- L56: variable named `numsiblings_exclude_sef` — looks like a typo for `_self`. Cosmetic but propagated.
- L47: order statement references `middle_intl` but that variable was not kept in `siblingmatch.do` L16-18 (which keeps `middle_intl` — actually it IS kept; just verified). Order is fine.
- The cap `numsiblings >= 9` (i.e. ≥ 10 total siblings) is documented but conservative; large extended families/cousins at the same address get clipped.

### 3. `siblingpairxwalk.do` (81 lines)

**Path:** `$projdir/do/share/siblingxwalk/siblingpairxwalk.do`
**Purpose:** Generate all sibling pair combinations (ordered self-pairs dropped at L40) and average birth-date distance per family.

**Inputs:**

- L16, L35: `use $projdir/dta/siblingxwalk/uniquelinkedfamilyclean` (twice).

**Outputs:**

- L45: `save $projdir/dta/siblingxwalk/siblingpairxwalk` (ordered pairs, both directions).
- L77: `save $projdir/dta/siblingxwalk/uniquesiblingpairxwalk` (deduped pairs + family-mean birth-date distance).

**Calls:** none. `joinby` at L37 to do self-merge.

**Transitive closure:** N/A — works on the `uniquelinkedfamilyclean` output of `uniquefamily.do`.

**Paper outputs:** Feeds `va_sibling_sample_sumstats.do` (which calls L58 `use uniquesiblingpairxwalk`). Used for descriptive stats — average sibling birth-date distance.

**Line-cited bugs / anomalies:**

- L53-57: pair-direction normalization uses `concat(...)` of `state_student_id` (numeric) — this is OK since concat preserves the comparison logic, but if the IDs have different string lengths the concatenation could mis-order. Stata `concat` returns string with separator "" by default, so `"1234" + "5"` ("12345") could clash with `"123" + "45"` ("12345"). I do not see a separator option.
- L57: `replace pairorder1 = pairorder2 if state_student_id > sibling_state_student_id` — uses numeric comparison after `concat` returned strings; this is comparing the original numeric vars, which is fine, but the consequence is that `pairorder1` then represents the lexicographically sorted pair only if numeric comparison agrees, which it should here.
- L67: `birth_date_distance = abs(birth_date - sibling_birth_date)` — assumes `birth_date` is a daily-coded numeric. Then divided by 365 at L71 to get years (ignoring leap years).
- No `compress` before save at L45.

### 4. `vafilemacros.doh` (24 lines)

**Path:** `$projdir/do/share/siblingvaregs/vafilemacros.doh`
**Purpose:** Local-macro registry of canonical paths used throughout chunk-5. Included via `include` in nearly every `siblingvaregs/*.do` file.

**Macros defined (locals — survive within calling do file):**

- L15: `vaprojdofiles "$vaprojdir/do_files"` — anchor for all Matt's helper doh files.
- L18: `va_dataset` = `$projdir/dta/common_core_va/va_dataset`
- L19: `va_g11_dataset` = `$projdir/dta/common_core_va/va_g11_dataset`
- L20: `va_g11_out_dataset` = `$projdir/dta/common_core_va/va_g11_out_dataset`
- L21: `siblingxwalk` = `$projdir/dta/siblingxwalk/siblingpairxwalk` (note: this is the paired-xwalk dataset, NOT the family xwalk)
- L22: `ufamilyxwalk` = `$projdir/dta/siblingxwalk/ufamilyxwalk`
- L23: `k12_postsecondary_out_merge` = `$projdir/dta/common_core_va/k12_postsecondary_out_merge`
- L24: `sibling_out_xwalk` = `$projdir/dta/siblingxwalk/sibling_out_xwalk`

**Anomalies:** Note that L21's `siblingxwalk` macro points to `siblingpairxwalk` (pairs), while L22's `ufamilyxwalk` is the family-level dataset — naming is non-obvious. Cross-repo drift: the same-named macros also exist in `cde_va_project_fork/do_files/sbac/macros_va.doh` L29-31 (verified by grep) — duplication, but values match.

### 5. `vaestmacros.doh` (160 lines)

**Path:** `$projdir/do/share/siblingvaregs/vaestmacros.doh`
**Purpose:** Local-macro registry mapping nicknames to .ster/.dta paths for VA estimates. Per L1-5 docstring, "does NOT include estimates from the sibling acs restricted sample. Too much bloating." So this file pre-dates the 4-spec/`og/acs/sib/both` work.

**Macros (subjects ela/math, outcomes enr/enr_2year/enr_4year — all looped):**

For test-score VA (L16-71):

- `<subject>_va_dta`, `_spec_va`, `_spec_va_peer` — original CFR estimates (`$vaprojdir`).
- `_va_dta_l4`, `_spec_va_l4`, `_spec_va_l4_peer`, `_fb_va_l4` — L4-leave-out (predates ACS).
- `_va_dta_census`, `_spec_va_census`, `_spec_va_census_peer`, `_fb_va_census` — census-tract leave-out.
- `_va_dta_sibling`, `_spec_va_sibling_og`, `_spec_va_sibling`, `_spec_va_sibling_peer`, `_fb_va_sibling` — sibling sample.
- `_sibling_vam_nosibctrl`, `_sibling_vam` — vam-command stored estimates.

For outcome VA (L87-160), parallel structure plus:

- L141-159: `_va_dta_sib_census` and ad-hoc `_spec_sib_census_og` etc. for the 3-way `census_nosib_noacs`/`census_noacs`/`sib_census` triplet (most commented out — dead code with `/* ... */`).

**Anomalies — verified bugs:**

- **L45 typo: `local `subject'_spec_va_census_peer "vaprojdir/estimates/sbac/bias_spec_test_va_cfr_g11_`subject'_census_peer.ster"`** — missing `$` before `vaprojdir`. Path is broken. Affects only test-score peer-control census spec test, but since that .ster is referenced from `va_sibling_spec_test_tab.do` only via the non-peer macro (`_spec_va_census` at L81), this dead-spot may never bite at runtime.
- **L118 same typo for outcome VA: `local `outcome'_spec_va_census_peer "vaprojdir/estimates/...peer.ster"`** — also missing `$`. Same dead-spot.
- L27: `local `subject'_va_dta_l4 "$vaprojdir/data/sbac/bias_va_g11_`subject'_L4ela.dta.dta"` — `.dta.dta` double-extension. Cosmetic if the file is named that way (but unlikely on disk). Triple-checked — the value in the macro literally is `.dta.dta`.
- L99 same `.dta.dta` for outcomes.

### 6. `siblingoutxwalk.do` (222 lines) — **N1 PRIMARY TARGET**

**Path:** `$projdir/do/share/siblingvaregs/siblingoutxwalk.do`
**Purpose:** Two-step: (a) merge full K-12 test-score sample to postsecondary outcomes (writes `k12_postsecondary_out_merge.dta`) using Matt's helper; (b) collapse to ssid level, merge onto `ufamilyxwalk`, compute older-sibling enrollment counts/dummies, lag1/lag2 sibling outcomes — writes `sibling_out_xwalk.dta` consumed by every downstream sibling-VA do file.

**Inputs:**

- L39: `include $projdir/do/share/siblingvaregs/vafilemacros.doh` — local file paths.
- L41: `include $vaprojdir/do_files/sbac/macros_va.doh` — Matt's macros (control lists, year ranges, `sibling_controls`, `census_controls`).
- L56-59: `use ... using $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta` (the canonical K-12 clean dataset, restricted access).
- L61: `do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only` — runs Matt's NSC/CCC/CSU merge helper (verified at `cde_va_project_fork/do_files/merge_k12_postsecondary.doh`, accepts arg `enr_only` → restricts varlist to enrollment outcomes only at L20, L75).
- L80: re-loads `$projdir/dta/common_core_va/k12_postsecondary_out_merge` (just saved at L71).
- L91: `merge 1:1 state_student_id using \`ufamilyxwalk'` (= `$projdir/dta/siblingxwalk/ufamilyxwalk`).

**Outputs:**

- **L71:** `save $projdir/dta/common_core_va/k12_postsecondary_out_merge, replace` — full K-12 ↔ postsec merge dataset. Used by other research code (see consumers analysis below).
- **L212:** `save $projdir/dta/siblingxwalk/sibling_out_xwalk, replace` — the central sibling-VA join table (ssid-level: `enr`, `enr_2year`, `enr_4year`, `k12_postsec_match`, `ufamilyid`, `numsiblings_*`, `birth_order`, `sibling_full_sample`, `sibling_out_sample`, `has_older_sibling`, `has_older_sibling_postsec_match`, `num_older_sibling_postsec_match`, `numsiblings_older_<outcome>`, `has_older_sibling_<outcome>`, `sibling_2y_4y_controls_sample`, `old1_sib_<outcome>`, `old2_sib_<outcome>`, `touse_sib_lag1_lag2_<outcome>`, `touse_sib_lag`).

**Calls:** Yes — see L61. Direct invocation of the cross-repo helper `merge_k12_postsecondary.doh`.

**Path refs that need updating:** `$vaprojdir/data/restricted_access/...` (L59), `$vaprojdir/do_files/merge_k12_postsecondary.doh` (L61), `$projdir/dta/common_core_va/...` (L71, L80), `$projdir/dta/siblingxwalk/sibling_out_xwalk` (L212), and log paths at L47/L222.

**Paper outputs:** Upstream. Feeds **every sibling-VA artifact** in chunks 5; many of those eventually feed paper tables/figures (sibling spec test tables, FB test tables, persistence regressions on the restricted sample).

**Line-cited bugs / anomalies:**

- **L84: `replace k12_postsec_match = 1 if k12_nsc_match == 1 | k12_ccc_match == 1 | k12_csu_match == 1`** — Stata short-circuit evaluation does not apply, but the `==` and `|` precedence here is fine. (`==` binds tighter than `|`, which is the desired behavior.)
- **L161: `replace has_older_sibling_postsec_match = 1 if !missing(num_older_sibling_postsec_match) & num_older_sibling_postsec_match > 0`** — explicitly guards against the Stata "missing > any number" trap. Good. The change-log entry at L11-13 documents that this trap was a previously-fixed bug for the `_enr_*` versions too.
- **L170: `replace has_older_sibling_`i' = 1 if numsiblings_older_`i' > 0 & !missing(numsiblings_older_`i')`** — same explicit missing-guard. Good.
- **L155-156:** `rangestat (sum) k12_postsec_match` over older siblings — correct because `k12_postsec_match` is 0/1, never missing.
- **L166: `rangestat (sum) `i' if has_older_sibling_postsec_match == 1`** — applies the rangestat ONLY for students with at least one older sibling in postsec sample. This is correct: we only want the older-sibling enrollment outcome among those for whom such sibling outcomes are observed.
- **Caveat: Comment at L133 "rangestat treats missing enr vars as 0"** — this was the trap the change-log addresses. Filter at L166 (`if has_older_sibling_postsec_match == 1`) is the workaround so that students with NO matched older sibling get no `numsiblings_older_enr_*` (it stays missing), but students with at least one matched older sibling get a count over the matched older siblings (where `enr` etc. is genuine).

### 7. `createvasample.do` (128 lines)

**Path:** `$projdir/do/share/siblingvaregs/createvasample.do`
**Purpose:** Build full VA sample dataset (`va_dataset`), then grade-11 test-score VA sample (`va_g11_dataset`), then grade-11 outcome VA sample (`va_g11_out_dataset`). Used as input to all sibling-VA do files via the `va_g11_dataset` and `va_g11_out_dataset` macros.

**Inputs:**

- L23: `include $projdir/do/share/siblingvaregs/vafilemacros.doh`.
- L27: `include $vaprojdir/do_files/sbac/macros_va.doh`.
- L47: `include $vaprojdir/do_files/sbac/create_va_sample.doh` — Matt's full-sample builder.
- L65: `include $vaprojdir/do_files/sbac/create_va_g11_sample.doh` — grade-11 score sample.
- L83: `do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only` — postsec merge for outcome sample.
- L101: `include $vaprojdir/do_files/sbac/create_va_g11_out_sample.doh` — grade-11 outcome sample.

**Outputs:**

- L56: `$projdir/dta/common_core_va/va_dataset`
- L71: `$projdir/dta/common_core_va/va_g11_dataset`
- L106: `$projdir/dta/common_core_va/va_g11_out_dataset`

**Calls:** five Matt-files via include/do.

**Paper outputs:** Upstream. Provides the canonical g11 samples for all chunk-5 work.

**Line-cited bugs / anomalies:**

- L74: `erase \`va_dataset'` — erases the **tempfile** local macro (which was set at L51-52 and saved as a permanent file at L56). Erasing a tempfile is fine; but note the same name `va_dataset` is reassigned to a NEW tempfile at L93, then never erased.
- Reuses tempfile name `va_dataset` (L51, L93) — confusing but not buggy.

### 8. `siblingvasamples.do` (217 lines)

**Path:** `$projdir/do/share/siblingvaregs/siblingvasamples.do`
**Purpose:** Re-run Matt's `touse_va.do` logic from scratch (rather than depend on `va_g11_dataset.dta`) and merge sibling outcomes. Produces an ssid-level dataset of sample markers.

**Inputs:**

- L29: `include vafilemacros.doh`.
- L42: `include macros_va.doh`.
- L55-60: `use ... using \`k12_test_scores'/k12_test_scores_clean.dta`.
- L64: `merge 1:1 ... using \`k12_test_scores'/k12_lag_test_scores_clean.dta`.
- L76: `merge 1:1 ... using \`k12_test_scores'/k12_peer_test_scores_clean.dta`.
- L89: `merge m:1 cdscode year using \`k12_test_scores_public'/k12_diff_school_prop_schyr.dta`.
- L93: `merge m:1 cdscode using \`k12_test_scores_public'/k12_cohort_size_sch.dta`.
- L97: `merge m:1 cdscode using \`k12_public_schools'/k12_public_schools_clean.dta`.
- L112: `do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only` (postsec merge).
- L203: `merge m:1 state_student_id using \`sibling_out_xwalk'` (= the dataset from `siblingoutxwalk.do`).

**Outputs:**

- L208: `$projdir/dta/common_core_va/va_sibling_samples` (touse* + sibling sample markers, used downstream for sample sumstats).

**Paper outputs:** Likely feeds the sample-counts table or descriptive statistics.

**Anomalies:**

- L99-106: hard-coded sample exclusion logic (conventional schools, cohort_size > 10).
- L172, L196: `replace touse_g11_<X> = 0 if n_g11_<X> < 7` — the "drop schools with <7 students" filter.
- L165: control-list ordering in `markout` — uses `peer_demographic_controls` etc., suggesting peer effects in some downstream regs (though the chunk-5 sibling regressions explicitly skip peer).
- This file partially duplicates `createvasample.do` work but produces sample markers without saving the underlying dataset. Smells like dead code or redundant — may be only used for diagnostics.

### 9. `va_sibling.do` (317 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sibling.do`
**Purpose:** Test-score VA on the sibling sample. Two specifications: (i) without sibling controls (`_nosibctrl`); (ii) with sibling controls (`i.has_older_sibling_enr_2year i.has_older_sibling_enr_4year`). Spec test + forecast-bias test (sibling controls as leave-out).

**Args:** L51 `args setlimit` — positional integer.

**Drift-limit semantics (positional arg `0`):**

- **L96-101:**

  ```
  if `setlimit' == 0 {
    local drift_limit = max(`test_score_max_year' - `test_score_min_year' - 1, 1)
  }
  else {
    local drift_limit = `setlimit'
  }
  ```

- With `test_score_max_year=2018`, `test_score_min_year=2015` (verified at `cde_va_project_fork/do_files/sbac/macros_va.doh` L35-41), this evaluates to `max(2018-2015-1, 1) = max(2, 1) = 2`. So **arg 0 → drift_limit = 2.**

**Inputs:**

- L54: `include vafilemacros.doh`.
- L63: `include macros_va.doh`.
- L76: `use \`va_g11_dataset'` (= `$projdir/dta/common_core_va/va_g11_dataset`).
- L79: `merge m:1 state_student_id using \`sibling_out_xwalk'`.

**Outputs (ster, 2 copies each — one to `$projdir/est`, one to `$vaprojdir/estimates`):**

- L125: `vam_cfr_g11_<subject>_nosibctrl.ster`
- L137: `spec_test_va_cfr_g11_<subject>_sibling_nocontrol.ster`
- L161: `vam_cfr_g11_<subject>.ster`
- L172: `spec_test_va_cfr_g11_<subject>_sibling.ster`
- L278: `fb_test_va_cfr_g11_<subject>_sibling.ster`
- L294-296: `va_g11_<subject>_sibling.dta` (collapsed VA estimates).

**SE clustering:** `cluster(school_id)` at L135, L170, L276. Uniformly school_id.

**Sibling-sample filter on collapse:** L288-292:

```stata
collapse (firstnm) va_* (mean) sbac_*_r* (sum) n_g11_<subject> = touse_g11_<subject> ///
  if sibling_full_sample == 1 & sibling_out_sample == 1 ///
  , by(school_id cdscode grade year)
```

The `if sibling_full_sample == 1 & sibling_out_sample == 1` filter IS present at L291.

**Paper outputs:** Original sibling-VA test-score VA, predates the 4-spec layer. May be deprecated by `va_sib_acs.do`.

**Line-cited bugs / anomalies:**

- L81-82: `drop if mi(has_older_sibling_enr_2year)` and `mi(has_older_sibling_enr_4year)` — the SAMPLE is essentially `sibling_2y_4y_controls_sample == 1` (which is what `siblingoutxwalk.do` L178-179 defines). But `va_sibling.do` does NOT use that flag directly; it filters via the missing checks.
- Lots of commented-out peer-effects code (L210-262).
- The "rename gymnastics" comment block (L271-285): renames vars temporarily so spec test, fb test all use the same indep-var name. Increases chance of name-error bugs.
- L96: `if `setlimit' == 0` — Stata treats string "0" and numeric 0 as equal in this context but if `args setlimit` is empty (e.g. `do va_sibling`), `setlimit` is empty string and `if "" == 0` errors. The docstring at L18-22 says "for original drift limit, do va_sibling 0" — silently breaks if user forgets the 0.

### 10. `va_sibling_out.do` (357 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sibling_out.do`
**Purpose:** Outcome VA (enrollment, 2-year, 4-year) on the sibling sample. Same 2-spec structure as `va_sibling.do` (without/with sibling controls).

**Args:** L51 `args setlimit`. Same `0`→default semantics (L92-97; same formula as `va_sibling.do`).

**Inputs:**

- L74: `use \`va_g11_out_dataset'`.
- L77: `merge m:1 state_student_id using \`sibling_out_xwalk', nogen keep(1 3)`.

**Outputs:**

- L117: `vam_cfr_g11_<outcome>_nosibctrl.ster`
- L130: `spec_test_va_cfr_g11_<outcome>_sibling_nocontrol.ster` (and to `$projdir`)
- L151: `vam_cfr_g11_<outcome>.ster`
- L162: `spec_test_va_cfr_g11_<outcome>_sibling.ster`
- L312: `fb_test_va_cfr_g11_<outcome>_sibling.ster`
- L333-335: `va_g11_<outcome>_sibling.dta` (per outcome).

**SE clustering:** `cluster(school_id)` at L126, L158, L308. Uniform.

**Sibling-sample filter on collapse — KEY DIFFERENCE FROM `va_sibling.do`:**

L327-331:

```stata
collapse (firstnm) va_* ///
  (mean) g11_`outcome'* ///
  (sum) n_g11_`outcome' = touse_g11_`outcome' ///
  , by(school_id cdscode grade year)
```

**No `if sibling_full_sample == 1 & sibling_out_sample == 1` filter on the collapse step** — contrast `va_sibling.do` L291 which DOES include that filter. This is an inconsistency between the two files (potentially a bug or potentially intentional because the outcome regression's `use` at L100 already filters `if touse_g11_<outcome>==1 & sibling_out_sample == 1`).

Actually looking again at L100: `use \`va_g11_out_sibling_dataset' if touse_g11_<outcome>==1 & sibling_out_sample == 1, clear` — the `sibling_out_sample == 1` filter is already applied at the load step. So the missing filter on collapse is OK for the outcome version. But `va_sibling.do` ALSO filters at the load step (L109) AND adds it on collapse — redundant but not a bug.

**Line-cited bugs / anomalies:**

- L79-80: `drop if mi(has_older_sibling_enr_2year/4year)` — same filter as `va_sibling.do`.
- L302-316: "rename gymnastics" with potential for var-name errors.
- Lots of commented-out peer/TFX regs.

### 11. `va_sibling_out_forecast_bias.do` (199 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sibling_out_forecast_bias.do`
**Purpose:** Forecast-bias test for sibling-outcome VA, using **census tract** (ACS) as leave-out. 3-spec sequence: `census_nosib_noacs`, `census_noacs`, `sib_census` — predates `va_sib_acs_out.do`.

**Inputs:**

- L33: `include vafilemacros.doh`.
- L42: `include macros_va.doh`.
- L56: `use \`va_g11_out_dataset'`.
- L59: `merge m:1 state_student_id using \`sibling_out_xwalk'`.
- L62: `keep if sibling_2y_4y_controls_sample==1`.
- L82: `do $vaprojdir/do_files/sbac/merge_va_smp_acs.doh outcome \`va_g11_out_sibling_dataset' va_g11_out_sibling_dataset create_va \`outcome'` — Matt's 5-arg ACS-merger.

**Outputs (per outcome):**

- L100: `vam_<outcome>_census_nosib_noacs.ster`
- L107-109: `spec_test_<outcome>_census_nosib_noacs.ster`
- L131: `vam_<outcome>_census_noacs.ster`
- L139-141: `spec_test_<outcome>_census_noacs.ster`
- L162: `vam_<outcome>_sib_census.ster`
- L171-172: `fb_test_<outcome>_census.ster`
- L181-183: `va_g11_<outcome>_sibling_census.dta`

**SE clustering:** `cluster(school_id)` everywhere (L105, L137, L170).

**Paper outputs:** This file is the predecessor of `va_sib_acs_out.do`. The 3-way `census_nosib_noacs/census_noacs/sib_census` outputs feed the `va_sibling_spec_test_tab.do` (L174,183 ad-hoc references) and `va_sibling_fb_test_tab.do` (L95).

**Line-cited bugs / anomalies:**

- L74: drift-limit hardcoded `local drift_limit = max(`test_score_max_year' - `test_score_min_year' - 1, 1)` — no `args` mechanism (always default).
- The 3-way naming `census_nosib_noacs / census_noacs / sib_census` is inconsistent with the later 4-spec `og/acs/sib/both` (which is in `va_sib_acs.do`). Confusing for reader.

### 12. `va_sib_acs.do` (251 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sib_acs.do`
**Purpose:** **The 4-spec test-score VA (`og`/`acs`/`sib`/`both`)** on the sibling-acs restricted sample. Establishes the canonical 4-spec naming.

**Inputs:**

- L43: `include vafilemacros.doh`.
- L46: `include macros_va.doh`.
- L62: `use $vaprojdir/data/va_samples/va_sib_acs_restr_smp.dta if touse_g11_<subject>==1` (output of `create_va_sib_acs_restr_smp.do`).

**Outputs (per subject ela/math, suffix `og|acs|sib|both`):**

- L78: `vam_<subject>_og.ster`
- L91: `spec_test_<subject>_og.ster`
- L111: `vam_<subject>_acs.ster`
- L124: `spec_test_<subject>_acs.ster`
- L133: `fb_test_<subject>_acs_og.ster` (FB: og minus acs, regressed on og VA)
- L152: `vam_<subject>_sib.ster`
- L164: `spec_test_<subject>_sib.ster`
- L173: `fb_test_<subject>_sib_og.ster` (FB: og minus sib, regressed on og VA)
- L194: `vam_<subject>_both.ster`
- L206: `spec_test_<subject>_both.ster`
- L216: `fb_test_<subject>_sib_acs.ster` (FB: acs minus both, regressed on acs VA — leave-out is sibling)
- L225: `fb_test_<subject>_acs_sib.ster` (FB: sib minus both, regressed on sib VA — leave-out is acs)
- L237: `va_<subject>_sib_acs.dta` (collapsed estimates, school×year level).

**4-spec definitions (L67-194):**

| Spec | Controls used |
|---|---|
| `og` | i.year, school_controls, demographic_controls, ela_score_controls, math_score_controls |
| `acs` | og + `census_controls` |
| `sib` | og + `sibling_controls` |
| `both` | og + `sibling_controls` + `census_controls` |

(`sibling_controls` and `census_controls` defined at `cde_va_project_fork/do_files/sbac/macros_va.doh` L164-181.)

**SE clustering:** `cluster(school_id)` for all spec/FB regressions (L88, L122, L132, L162, L172, L204, L214, L223). Uniform.

**Paper outputs:** Likely Table 5/6 of the paper (sibling/ACS robustness), via `va_sib_acs_spec_test_tab.do`, `va_sib_acs_fb_test_tab.do`, `va_sib_acs_vam_tab.do`.

**Line-cited bugs / anomalies:**

- L83, L84, L88: label refers to ``subject'_str` (a Matt macro that's defined but only used inside double quotes). Should be `_str` not `_str`. Macro probably resolves correctly via `macros_va.doh` L72-76.
- The `og`-spec is a copy of the original spec but on the **restricted** sample (i.e. only obs that have non-missing sibling controls AND ACS controls). NOT identical to the published "primary" VA.
- The naming convention for FB tests at L216/L225 is unintuitive — `fb_test_<subject>_sib_acs.ster` actually does FB with sibling as leave-out against ACS-only spec, not "sib AND acs".

### 13. `va_sib_acs_out.do` (260 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sib_acs_out.do`
**Purpose:** **The 4-spec outcome VA** (`og`/`acs`/`sib`/`both`) on the sibling-acs-out restricted sample. Parallel to `va_sib_acs.do` for outcomes.

**Inputs:**

- L43: vafilemacros, L46: macros_va.
- L67: `use $vaprojdir/data/va_samples/va_sib_acs_out_restr_smp.dta if touse_g11_<outcome>==1`.

**Outputs:** Parallel structure to `va_sib_acs.do`, replacing `<subject>` with `<outcome>`. Outputs per outcome:

- L83 vam_og, L96 spec_og, L115 vam_acs, L128 spec_acs, L138 fb_acs_og, L158 vam_sib, L171 spec_sib, L180 fb_sib_og, L201 vam_both, L214 spec_both, L224 fb_sib_acs, L233 fb_acs_sib, L245 va_<outcome>_sib_acs.dta.

**SE clustering:** uniformly `cluster(school_id)`.

**Drift limit:** L58: `local drift_limit = max(\`test_score_max_year' - \`test_score_min_year' - 1, 1)` — default, no args.

### 14. `va_sib_acs_out_dk.do` (275 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sib_acs_out_dk.do`
**Purpose:** **Deep-knowledge** outcome VA — outcome VA controlling for ELA + math test-score VA on the same sample. Same 4-spec pattern.

**Inputs:**

- L45: vafilemacros, L48: macros_va.
- L72: `use $vaprojdir/data/va_samples/va_sib_acs_out_restr_smp.dta if touse_<outcome>_dk==1`.

**DK control vector:**

- **L64: `local sib_acs_dk_controls va_ela_og va_math_og`**

This is a single hard-coded list, used identically across **all 4 specs** (L81 `og`, L115 `acs_dk`, L158 `sib_dk`, L201 `both_dk`).

**Question N7 — Is the DK control consistent across specs, or does it vary?**

**ANSWER: It is hard-coded to `va_ela_og va_math_og` for all 4 outcome specs.** This is a likely bug or design choice that the author noted — the OG-spec test-score VA is used as control even when the outcome is the SIB or BOTH spec. A more "purist" deep-knowledge implementation would use spec-matched test-score VA: e.g., `va_ela_acs va_math_acs` for the `acs_dk` outcome spec, etc.

Verification:

- L64 defines `local sib_acs_dk_controls va_ela_og va_math_og` ONCE.
- L81 (og spec): `\`sib_acs_dk_controls'` → `va_ela_og va_math_og` ✓
- L115 (acs spec): `\`sib_acs_dk_controls'` → still `va_ela_og va_math_og` (NOT `va_ela_acs va_math_acs`)
- L158 (sib spec): same, `va_ela_og va_math_og`
- L201 (both spec): same, `va_ela_og va_math_og`

This is an **identified anomaly**. The OG test-score VA leaks into all DK outcome specs. Whether this is intentional ("we want a single deep-knowledge baseline") or a bug ("we forgot to spec-match") is a question for Christina.

**Outputs:**

- L90 vam_og_dk, L104 spec_og_dk, L125 vam_acs_dk, L138 spec_acs_dk, L148 fb_acs_og_dk, L168 vam_sib_dk, L181 spec_sib_dk, L190 fb_sib_og_dk, L212 vam_both_dk, L225 spec_both_dk, L235 fb_sib_acs_dk, L243 fb_acs_sib_dk, L254 va_<outcome>_sib_acs_dk.dta.

**SE clustering:** all `cluster(school_id)`.

### 15. `create_va_sib_acs_restr_smp.do` (97 lines)

**Path:** `$projdir/do/share/siblingvaregs/create_va_sib_acs_restr_smp.do`
**Purpose:** Build the restricted test-score VA sample with both sibling controls and ACS controls non-missing.

**Inputs:**

- L39: vafilemacros, L42: macros_va.
- L53: `use \`va_g11_dataset'`.
- L56: `merge m:1 state_student_id using \`sibling_out_xwalk', nogen keep(1 3)`.
- L60: `keep if sibling_2y_4y_controls_sample==1`.
- L69: `do $vaprojdir/do_files/sbac/merge_va_smp_acs.doh test_score \`va_g11_sibling_dataset' va_g11_sibling_dataset create_sample none`.

**Outputs:** L76: `$vaprojdir/data/va_samples/va_sib_acs_restr_smp.dta`.

**Anomalies:** none material.

### 16. `create_va_sib_acs_out_restr_smp.do` (119 lines)

**Path:** `$projdir/do/share/siblingvaregs/create_va_sib_acs_out_restr_smp.do`
**Purpose:** Build the restricted outcome VA sample with both sibling and ACS controls + create DK touse indicators.

**Inputs:**

- L40, L43: includes.
- L56: `use \`va_g11_out_dataset'`.
- L59: merge to sibling_out_xwalk.
- L63: `keep if sibling_2y_4y_controls_sample==1`.
- L71: ACS merge helper.
- L78-86: per outcome × {ela,math}: merge in test-score VA from `$vaprojdir/data/sib_acs_restr_smp/test_score_va/va_<subject>_sib_acs.dta` keeping `va_<subject>_*`. Creates `touse_<outcome>_<subject>_og` (= 1 if `touse_g11_<outcome>==1` AND `va_<subject>_og` non-missing; **L85 specifically uses `va_<subject>_og`, not the spec-matched VA**).
- L89-91: `touse_<outcome>_dk = 1` if both `touse_<outcome>_ela_og==1` AND `touse_<outcome>_math_og==1`.

**Outputs:** L102: `$vaprojdir/data/va_samples/va_sib_acs_out_restr_smp.dta`.

**Anomalies / supports DK observation:**

- **L85 confirms the OG-only design intent: the DK touse is built off `va_<subject>_og`, not spec-matched VA.** So the DK cross-spec design at L64 of `va_sib_acs_out_dk.do` is consistent with the touse logic here. Whether the design is right is the question.

### 17. `reg_out_va_sib_acs.do` (245 lines)

**Path:** `$projdir/do/share/siblingvaregs/reg_out_va_sib_acs.do`
**Purpose:** Persistence: regress enrollment outcomes on the test-score VA from the 4-spec sibling-ACS restricted sample. Produces main, hetero-by-prior-decile, and hetero-by-prior-decile-by-SED-status estimates.

**Inputs:**

- L41: vafilemacros, L44: macros_va.
- L56: `use $vaprojdir/data/va_samples/va_sib_acs_out_restr_smp.dta`.
- L60-62: merge in test-score VA dataset per subject.
- L65-69: standardize each `va_*` to z-score by `(x - mean)/sd`.
- L126-127: `merge m:1 state_student_id using $vaprojdir/data/sbac/prior_decile_original_sample.dta` — prior-score deciles.

**Outputs:**

- L97: `reg_<outcome>_va_<subject>_<control>.ster` (3 outcomes × 2 subjects × 4 specs = 24).
- L115: `reg_<outcome>_va_ela_math_<control>.ster` (3 × 4 = 12 — both subjects on RHS).
- L154: `het_reg_<outcome>_va_<subject>_<control>_x_prior_<prior_subject>.ster` (3 × 2 × 4 × 2 = 48 hetero by prior decile).
- L177: `het_reg_<outcome>_va_ela_math_<control>_x_prior_<prior_subject>.ster` (3 × 4 × 2 = 24).
- L214: `het_reg_<outcome>_va_<subject>_<control>_x_prior_<prior_subject>_sed1.ster` (3 × 2 × 4 × 2 = 48 SED=1).
- L228: `het_reg_<outcome>_va_<subject>_<control>_x_prior_<prior_subject>_sed0.ster` (3 × 2 × 4 × 2 = 48 SED=0).

**SE clustering — INCONSISTENCY:**

- L94 (main reg): `cluster(school_id)`.
- L112 (both-subject): `cluster(school_id)`.
- **L151 (hetero by prior decile, single subject): `cluster(cdscode)`.**
- **L174 (hetero by prior decile, both subject): `cluster(cdscode)`.**
- **L211 (hetero by prior + SED=1): `cluster(cdscode)`.**
- **L225 (hetero by prior + SED=0): `cluster(cdscode)`.**

Main regs cluster on `school_id`; heterogeneity regs cluster on `cdscode`. **This is a real inconsistency** — `school_id` is a Matt-defined permanent identifier; `cdscode` is the CDE school identifier. Whether they're 1-to-1 is project-specific. If they differ, SEs are computed on different cluster groupings between main and hetero results — not directly comparable. Worth flagging.

**Paper outputs:** This file feeds the Table-of-persistence and the prior-decile heterogeneity figures.

### 18. `reg_out_va_sib_acs_dk.do` (165 lines)

**Path:** `$projdir/do/share/siblingvaregs/reg_out_va_sib_acs_dk.do`
**Purpose:** Persistence regressions with DK VA as RHS. Three blocks: (i) all-3 enrollment outcomes on RHS together, (ii) outcome-matched DK VA, (iii) hetero by prior decile.

**Inputs:**

- L40, L43: includes.
- L55: `use va_sib_acs_out_restr_smp.dta`.
- L60-62: merge DK outcome VA per outcome.
- L64-68: z-score standardization of all `va_*`.
- L126: prior-decile merge.

**Outputs:**

- L91: `reg_<outcome>_va_allenr_<control>_dk.ster` (3 × 4 = 12 — all-3 RHS).
- L115: `reg_<outcome>_va_<outcome>_<control>_dk.ster` (3 × 4 = 12 — outcome-matched).
- L149: `het_reg_<outcome>_va_<outcome>_<control>_dk_x_prior_<prior_subject>.ster` (3 × 4 × 2 = 24).

**SE clustering — same inconsistency pattern:**

- L88 (main, 3 outcomes RHS): `cluster(school_id)`.
- L112 (outcome-matched main): `cluster(school_id)`.
- **L146 (hetero by prior): `cluster(cdscode)`.**

### 19. `reg_out_va_sib_acs_tab.do` (239 lines)

**Path:** `$projdir/do/share/siblingvaregs/reg_out_va_sib_acs_tab.do`
**Purpose:** Build CSV tables from `reg_out_va_sib_acs.do` ster files via `esttab`.

**Inputs:** Many `estimates use $vaprojdir/estimates/sib_acs_restr_smp/persistence/reg_*.ster` (L111, L135, L156, L189, L215).

**Outputs:**

- L117: `$projdir/out/csv/siblingvaregs/persistence/sib_acs_restr_smp/reg_out_score_va/reg_outcome_va_<subject>.csv` (single subject VA, 3 outcomes × 4 specs = 12 cols).
- L162: `reg_outcome_va_ela_math.csv`.
- L196: `het_reg_outcome_va_<subject>_x_prior_<prior_subject>.csv`.
- L222: `het_reg_outcome_va_ela_math_x_prior_<prior_subject>.csv`.

**Anomalies — esttab MTITLES BUG:**

- **L82-88: `esttab_mtitles` macro is the **forecast-bias-test mtitles** ("Original w/ Census Leave Out", "Original w/ Sibling Leave Out", "Census w/ Sibling Leave Out", "Sibling w/ Census Leave Out") — but this CSV is the persistence/regression output, NOT a forecast bias test.** The correct mtitles for a 4-spec persistence reg should be "Original Specification" / "Census Controls" / "Sibling Controls" / "Sibling and Census Controls" (matching `va_sib_acs_spec_test_tab.do` L103-106). This is a labeling bug — the regression-on-VA tables produced by this file have misleading column headers describing leave-out variables that don't apply. **HIGH-PRIORITY BUG** if these CSVs feed paper tables.

### 20. `reg_out_va_sib_acs_fig.do` (341 lines)

**Path:** `$projdir/do/share/siblingvaregs/reg_out_va_sib_acs_fig.do`
**Purpose:** Build figures from prior-decile heterogeneity regression estimates.

**Inputs:** Many `estimates use ...persistence/het_reg_*.ster`. Uses `parmest, norestore` to convert estimation results into a dataset for plotting.

**Outputs (to two parallel locations):**

- L135-136: `het_reg_<outcome>_va_<subject>_<control>_x_prior_<prior_subject>.pdf` (per-spec individual figures).
- L186-187: `het_reg_<outcome>_va_both_<control>_x_prior_<prior_subject>.pdf` (both-subject).
- L220-221: combined panel `het_reg_<outcome>_va_<subject>_x_prior_<prior_subject>.pdf` — original sample + 3 restricted-sample specs (og/sib/both, **but NOT acs spec** — see panel-construction L213-216 omits acs).
- L269-270: SED-stratified individual figures.
- L321-322: SED combined panels (8-graph: 4 specs × 2 SED status).

**Line-cited bugs / anomalies:**

- **L116, L168, L252: `gen xtile = subinstr(substr(parm, 1, strpos(parm, ".")-1), "b", "", .)` (L116/L168) vs `substr(parm, 1, strpos(parm, "."))` (L254 — note: NO `-1`).** L116 and L168 strip the period; L254 keeps it. The destring at L256 then strips it via destring's quirk. **Verified:** L118 has `-1` (correct), L168 has `-1` (correct), **L254 is missing the `-1`**. This means the SED-stratified figures parse the parm string differently. Looking carefully: L254 has `strpos(parm, ".")` (no -1) so it includes the period, then `subinstr` strips the "b". `destring` should still convert "12." to 12, so this is a benign inconsistency. But it IS an inconsistency.
- L213-216: graph-combine for prior-decile panel uses `og`, `sib`, `both` — **acs is missing**. This means the panel does NOT include the ACS-only specification. Whether intentional (to avoid 5 panels) or a bug requires checking against the paper.
- L309-317: SED panel combines 4 specs × 2 SED — **but uses `og`, `sib`, `both` for restricted plus original-sample — again, no `acs` spec**. Same omission.
- L222 leftover blank lines.

### 21. `reg_out_va_sib_acs_dk_fig.do` (161 lines)

**Path:** `$projdir/do/share/siblingvaregs/reg_out_va_sib_acs_dk_fig.do`
**Purpose:** Figures for DK persistence regressions, prior-decile heterogeneity.

**Inputs:** `het_reg_<outcome>_va_<outcome>_<control>_dk_x_prior_<prior_subject>.ster`.

**Outputs:**

- L100-101: individual DK heterogeneity figures.
- L139-140: combined panels (original sample + restricted og + sib + both — **acs again missing**).

**Bugs / anomalies:**

- **L86: `gen xtile = subinstr(substr(parm, 1, strpos(parm, ".")), "b", "", .)`** — uses `strpos(parm, ".")` WITHOUT `-1`. Compare with `reg_out_va_sib_acs_fig.do` L116 which has `-1`. Same benign inconsistency as that file's L254.
- **L131-135: graph_combine omits `acs` spec.** Same pattern.

### 22. `va_sib_acs_spec_test_tab.do` (249 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sib_acs_spec_test_tab.do`
**Purpose:** Spec test tables for test-score VA, outcome VA, and DK outcome VA. Each builds a 4-spec table.

**Inputs:** ster files from spec_test_<*>.ster.

**Outputs:**

- L99: `spec_test_sib_acs_restr_smp_score.csv`
- L157: `spec_test_sib_acs_restr_smp_outcome.csv`
- L219: `spec_test_sib_acs_restr_smp_outcome_dk.csv`

**Adds H0 test (`test _b[va_*] = 1`) p-values via `estadd matrix test_p`.**

**Paper outputs:** likely Table 5/6 spec-test rows of the paper.

### 23. `va_sib_acs_fb_test_tab.do` (167 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sib_acs_fb_test_tab.do`
**Purpose:** Forecast-bias test tables (4 spec × outcome × {test_score, outcome, dk}).

**Inputs:** `fb_test_*.ster` from each VA estimation file.

**Outputs:**

- L74: `fb_test_sib_acs_restr_smp_score.csv`
- L107: `fb_test_sib_acs_restr_smp_outcome.csv`
- L143: `fb_test_sib_acs_restr_smp_outcome_dk.csv`

The FB-test is exactly the 4-column pattern: og/census-leave-out, og/sibling-leave-out, census/sibling-leave-out, sibling/census-leave-out (L77-80, L110-115, L146-151).

### 24. `va_sib_acs_vam_tab.do` (178 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sib_acs_vam_tab.do`
**Purpose:** Output the VAM coefficient tables (each spec's controls) for test-score VA, outcome VA, and DK outcome VA, 4 specs each.

**Outputs:**

- L75: `test_score_sib_acs_restr_smp_vam.csv`
- L114: `outcome_sib_acs_restr_smp_vam.csv`
- L153: `outcome_dk_sib_acs_restr_smp_vam.csv`

### 25. `va_sib_acs_est_sumstats.do` (207 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sib_acs_est_sumstats.do`
**Purpose:** Diagnostic correlation scatters and difference histograms for test-score VA, comparing original sample, restricted+og, restricted+both.

**Outputs:** Many graphs to `va_compare_sib_acs_restr_smp/`.

### 26. `va_sib_acs_out_est_sumstats.do` (171 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sib_acs_out_est_sumstats.do`
**Purpose:** Same as #25 but for outcome VA.

### 27. `va_sibling_est_sumstats.do` (274 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sibling_est_sumstats.do`
**Purpose:** Sum stats / scatter / kdensity / spec-test binscatter for sibling test-score VA (no ACS).

**Inputs:** `va_g11_<subject>_sibling.dta` (output of `va_sibling.do`), and the original VA dataset `data/sbac/va_g11_<subject>.dta`.

**Outputs:** Lots of PDFs to `$projdir/out/graph/siblingvaregs/test_score_va/`.

### 28. `va_sibling_fb_test_tab.do` (115 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sibling_fb_test_tab.do`
**Purpose:** Forecast-bias table comparing FB tests across L4-score, census, sibling, and sibling-census samples.

**Inputs:** Uses `vaestmacros.doh` registry — references `\`<subject>_fb_va_l4'`, `\`<subject>_fb_va_census'`, `\`<subject>_fb_va_sibling '` (note trailing space at L64, L91).

**Outputs:** L68: `fb_test_<subject>.csv`. L98: `fb_test_<outcome>.csv`.

**Bugs:**

- **L64: `estimates use \`\`subject\'_fb_va_sibling \''` — note the trailing space inside the macro reference.** The macro `\`<subject>_fb_va_sibling'` is what `vaestmacros.doh` L64 defines. With the trailing space in `va_sibling_fb_test_tab.do`'s reference, Stata may complain or silently look up an empty macro. Same at L91. Possible runtime bug.

### 29. `va_sibling_out_est_sumstats.do` (260 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sibling_out_est_sumstats.do`
**Purpose:** Sum stats for outcome VA on sibling sample (parallel to #27).

### 30. `va_sibling_sample_sumstats.do` (127 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sibling_sample_sumstats.do`
**Purpose:** Diagnostics on sibling sample sizes — number of families, average birth-date distance — for ELA and math g11 samples.

**Inputs:**

- L42: `use \`va_g11_dataset'`.
- L45: `merge m:1 state_student_id using \`sibling_out_xwalk'`.
- L58: `use $projdir/dta/siblingxwalk/uniquesiblingpairxwalk` (output of `siblingpairxwalk.do`).

**Outputs:** None (just `sum`/`tab` to log).

### 31. `va_sibling_spec_test_tab.do` (214 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sibling_spec_test_tab.do`
**Purpose:** Spec test tables aggregating across multiple samples — original / L4 / census / sibling / sibling+ctrl / sibling-census / sibling-census+ctrl.

**Inputs:** ster paths via `vaestmacros.doh`.

**Outputs:** L111: `spec_test_<subject>.csv` (5-col). L193: `spec_test_<outcome>.csv` (7-col, includes `census_nosib_noacs` and `census_noacs` from `va_sibling_out_forecast_bias.do`).

### 32. `va_sibling_vam_tab.do` (80 lines)

**Path:** `$projdir/do/share/siblingvaregs/va_sibling_vam_tab.do`
**Purpose:** VAM coefficient tables for sibling-VA-with-controls.

**Outputs:** L52 `test_score_sibling_vam.csv`, L65 `outcome_sibling_vam.csv`.

---

## N1 — `siblingoutxwalk.do` Relocation Analysis

### a. Inputs of `siblingoutxwalk.do`

Verified from primary source (lines cited):

1. **L39:** `include $projdir/do/share/siblingvaregs/vafilemacros.doh` — IS in `siblingvaregs/`. Defines local macros (paths only). Could be moved or referenced from new location.
2. **L41:** `include $vaprojdir/do_files/sbac/macros_va.doh` — in `cde_va_project_fork`, NOT in either subdir.
3. **L56-59:** `use ... using $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta` — restricted-access raw data, location independent.
4. **L61:** `do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only` — Matt's helper file in `cde_va_project_fork/do_files/`. NOT in either subdir.
5. **L80:** `use $projdir/dta/common_core_va/k12_postsecondary_out_merge` — re-loads its own L71 output (self-input).
6. **L91:** `merge 1:1 state_student_id using \`ufamilyxwalk'` — local macro = `$projdir/dta/siblingxwalk/ufamilyxwalk.dta`. This dataset is produced by `siblingxwalk/uniquefamily.do` (verified at uniquefamily.do L74).

**ANSWER (a):** None of `siblingoutxwalk.do`'s inputs are FROM `siblingvaregs/` other than the `vafilemacros.doh` registry (which contains only path macros, no actual data dependencies). The substantive data inputs are: (i) restricted K-12 test scores in `$vaprojdir`, (ii) the postsec merge helper in `$vaprojdir`, and (iii) the family xwalk in `$projdir/dta/siblingxwalk/`. Moving the file to `siblingxwalk/` will not break input paths because all paths are absolute (via `$projdir`/`$vaprojdir` globals).

### b. Outputs of `siblingoutxwalk.do`

Verified:

1. **L71:** `$projdir/dta/common_core_va/k12_postsecondary_out_merge.dta` — full K-12-postsec merge, written to `common_core_va/`, NOT to `siblingxwalk/`.
2. **L212:** `$projdir/dta/siblingxwalk/sibling_out_xwalk.dta` — written to `siblingxwalk/`, despite the do file living in `siblingvaregs/`.

So the outputs already live in `siblingxwalk/` (one of them) — relocation is consistent with output destinations.

### c. Consumers of `siblingoutxwalk.do` outputs (cross-repo grep)

Grep for `sibling_out_xwalk` or `siblingoutxwalk` across both repos:

**In `caschls/`:**

- `do/share/siblingvaregs/siblingoutxwalk.do` — itself (self-reference).
- `do/share/siblingvaregs/vafilemacros.doh:24` — defines the macro.
- `do/share/siblingvaregs/siblingvasamples.do:203` — `merge m:1 state_student_id using \`sibling_out_xwalk'` — IS in `siblingvaregs/`.
- `do/share/siblingvaregs/va_sibling_sample_sumstats.do:45` — IS in `siblingvaregs/`.
- `do/share/siblingvaregs/va_sibling_out_forecast_bias.do:59` — IS in `siblingvaregs/`.
- `do/share/siblingvaregs/create_va_sib_acs_restr_smp.do:56` — IS in `siblingvaregs/`.
- `do/share/siblingvaregs/va_sibling.do:79` — IS in `siblingvaregs/`.
- `do/share/siblingvaregs/create_va_sib_acs_out_restr_smp.do:59` — IS in `siblingvaregs/`.
- `do/share/siblingvaregs/va_sibling_out.do:77` — IS in `siblingvaregs/`.
- `do/archive/vamtest.do:74` — archived.
- `do/archive/va_sibling_out_spec_test_tab.do:45` — archived.
- `do/master.do:103` — caller (see (d)).

**In `cde_va_project_fork/`:**

- `do_files/do_all.do:142` — `do $projdir/do/share/siblingvaregs/siblingoutxwalk.do` — caller (see (d)).
- `do_files/sbac/macros_va.doh:31` — defines duplicate macro.
- `do_files/sbac/merge_sib.doh:5` — `merge m:1 state_student_id using \`sibling_out_xwalk'` — Matt's helper, NOT in `siblingvaregs/`.
- `do_files/share/sample_counts_tab.do:53` — `merge m:1 state_student_id using \`sibling_out_xwalk'` — NOT in `siblingvaregs/` (it's in `share/`).

**ANSWER (c):** Most consumers ARE in `siblingvaregs/` (8 files), reading via the `\`sibling_out_xwalk'` local macro from `vafilemacros.doh`. Two consumers in `cde_va_project_fork/` (`merge_sib.doh`, `sample_counts_tab.do`) read via a duplicate macro registry. None of the consumers reference `siblingoutxwalk.do` itself by path — they all read its OUTPUT dataset by absolute path. Therefore relocating `siblingoutxwalk.do` does not break any consumer.

### d. Callers of `siblingoutxwalk.do` itself

Verified via grep:

1. **`caschls/do/master.do:103:`** `do $projdir/do/share/siblingvaregs/siblingoutxwalk.do` (path is hardcoded).
2. **`cde_va_project_fork/do_files/do_all.do:142:`** `do $projdir/do/share/siblingvaregs/siblingoutxwalk.do` (path is hardcoded).
3. The change-log entry at `master.do` L29 says "moved siblingoutxwalk.do to the match siblings code block" — note this is a comment about the LOCATION-IN-MASTER (the call site within master.do moved earlier in the sequence to before VA), NOT about the file's directory location.

**ANSWER (d):** Two callers, both in `caschls/do/master.do` and `cde_va_project_fork/do_files/do_all.do`. Both reference the file by full path `$projdir/do/share/siblingvaregs/siblingoutxwalk.do`. Neither caller is in `siblingvaregs/` (master.do is in `caschls/do/`, not `caschls/do/share/siblingvaregs/`). Both callers will need to be updated if the file moves to `siblingxwalk/`.

### Verdict on N1

**SAFE to relocate `siblingoutxwalk.do` from `siblingvaregs/` to `siblingxwalk/`, with a proviso.**

- **No consumers break:** outputs are already in `siblingxwalk/dta/` (L212) and `common_core_va/dta/` (L71), so move-of-source-file does not affect output paths or consumers (which read by data-path, not source-path).
- **Two callers need updating:** `caschls/do/master.do:103` and `cde_va_project_fork/do_files/do_all.do:142` reference the source path `$projdir/do/share/siblingvaregs/siblingoutxwalk.do`. Either update those `do` paths, or leave the file in its current home and move only logically/semantically (rename group label).
- **Naming sanity argues for the move:** the file's purpose is to BUILD the sibling crosswalk dataset (writes `sibling_out_xwalk.dta` to `siblingxwalk/`). Other crosswalk-building files live in `siblingxwalk/`. Keeping it in `siblingvaregs/` is a historical artifact (the file was originally written to feed sibling-VA regs but is logically a crosswalk builder).
- **Risk of inadvertent breakage (low):** The change-log at `siblingoutxwalk.do` L21-23 ("07/27/2023: moved the code used to merges the entire k12 test score sample onto postsecondary outcomes from createvasamples.do to the beginning of this file") shows the author is willing to refactor; relocation continues that intent.

---

## Sibling-matching Specifics (consolidated answers)

### a. Address join — components used

**Verified:** `siblingmatch.do` L49 uses 7 components for same-year egen group: `year last_name street_address_line_one street_address_line_two city state zip_code`. **CONSISTENCY CAVEAT:** The duplicates check at L41-43 uses 6 of these (no `last_name`, no `zip_code`, no `first_name`); the family-grouping at L49 uses 7 (no `first_name`). The cross-year version at L86 uses 6 (drops `year` from the 7).

### b. Surname

**Verified:** `last_name` field is used directly. **No normalization** (no upper, no lower, no trim, no accent strip). Cited: L49, L86. This is a known weak point — case-sensitivity may cause `Smith` and `smith` to be treated as different families.

### c. Same-year vs. cross-year

**Verified:** Two parallel matching logics in `siblingmatch.do`:

- L33-69: `matchonsameyear = 1` block requires same `year` (L49).
- L77-105: `matchacrossyears = 1` block does NOT require year (L86).
- The transitive-closure step in `uniquefamily.do` L32 uses ONLY the `_year`-keyed dataset (L18: `use ... k12_xwalk_name_address_year`). The cross-year matching from `siblingmatch.do` produces `k12_xwalk_name_address.dta` (L104), which is NOT used downstream — appears to be diagnostic-only or dead code.

So in the production pipeline, **family matching is "same-year + cross-year via transitive closure"**, not "cross-year direct match".

### d. Transitive closure

**Verified:** Package = `group_twoway` (SSC), called at `uniquefamily.do` L32 with arguments `siblings_name_address_year state_student_id, generate(ufamilyid)`. Per the L26 URL comment, this connects students through shared family-ID-or-ssid edges.

### e. Family moves

**Handled** through the cross-year transitive closure at L32: if family A is at address X in year 2010 (matched as group G1) and at address Y in year 2011 (matched as group G2), but both groups contain at least one student in common (say sibling 1), then G1 and G2 both share ssid 1, and `group_twoway` connects them via ssid 1. So the family stays unified across the move. Comment at L29-31 says exactly this.

### f. Surname changes / remarriage

**NOT handled.** Surname (L49: `last_name`) is part of the family-id key. If a student's last name changes (remarriage of parent, surname update), they will be assigned to a different family-id in different years, and `group_twoway` cannot connect them unless they share a family-id with another sibling who also matched under both surnames (rare).

### g. Data-entry typos / fuzzy matching

**NOT handled.** Address fields, last_name, first_name are matched on exact string equality. No edit-distance, no soundex.

### h. Quality filters

Verified explicitly:

- `siblingmatch.do` L22: `drop if strlen(street_address_line_one) <= 1` (drops empty + 1-char).
- `siblingmatch.do` L23: `drop if missing(state_student_id)`.
- `siblingmatch.do` L43, L83: `duplicates drop` per (ssid, year, address) or (ssid, address).
- `siblingmatch.do` L53, L90: `bysort siblings_name_*: drop if _N==1` — drops singletons (no siblings).
- `uniquefamily.do` L53: `drop if numsiblings >= 9` (max 10 children per family).

---

## 4-Spec Convention — Where It's Defined

The 4 specs (`og`/`acs`/`sib`/`both`) are defined inline in each VAM call, NOT in a central macro. The control vectors per spec:

| Spec | Inline expansion (verified at `va_sib_acs.do`) |
|---|---|
| `og` | i.year, school_controls, demographic_controls, ela_score_controls, math_score_controls (L67-75) |
| `acs` | og + `census_controls` (L99-108) |
| `sib` | og + `sibling_controls` (L140-149) |
| `both` | og + `sibling_controls` + `census_controls` (L181-191) |

The supporting macros come from `cde_va_project_fork/do_files/sbac/macros_va.doh` L164-181:

- `census_controls` (L164-170): `eth_asian_pct, eth_hispanic_pct, eth_black_pct, educ_hs_dropout_prop, educ_deg_4year_plus_prop, pov_fam_child_lt18_pct, inc_median_hh`.
- `sibling_controls` (L177-180): `i.has_older_sibling_enr_2year, i.has_older_sibling_enr_4year`.

**Files implementing the 4-spec convention:** `va_sib_acs.do`, `va_sib_acs_out.do`, `va_sib_acs_out_dk.do`, `reg_out_va_sib_acs.do`, `reg_out_va_sib_acs_dk.do`, `va_sib_acs_spec_test_tab.do`, `va_sib_acs_fb_test_tab.do`, `va_sib_acs_vam_tab.do`, `va_sib_acs_est_sumstats.do`, `va_sib_acs_out_est_sumstats.do`, `reg_out_va_sib_acs_tab.do`, `reg_out_va_sib_acs_fig.do`, `reg_out_va_sib_acs_dk_fig.do`.

**Older / inconsistent naming used in:**

- `va_sibling.do`, `va_sibling_out.do`: 2-spec (`_nosibctrl` vs no suffix).
- `va_sibling_out_forecast_bias.do`: 3-spec (`_census_nosib_noacs`, `_census_noacs`, `_sib_census`).
- `vaestmacros.doh`: registry tracks the older 2-spec and 3-spec naming; explicitly does NOT track the 4-spec (L1-5 docstring confirms).

---

## Positional arg `0` semantics for `va_sibling*.do` — formula

**Verified at both `va_sibling.do` L96-101 and `va_sibling_out.do` L92-97:**

```
if `setlimit' == 0 {
  local drift_limit = max(`test_score_max_year' - `test_score_min_year' - 1, 1)
}
```

With `test_score_max_year=2018`, `test_score_min_year=2015` (verified at `cde_va_project_fork/do_files/sbac/macros_va.doh` L35-41):

- **Default `drift_limit = max(2018 - 2015 - 1, 1) = max(2, 1) = 2`.**

Note the change-log at `va_sibling_out.do` L26 says: "1.6.2022: re-ran with drift limit = 2. Still produces an error if drift limit = 3." This corroborates the value 2 as the actual default.

---

## Paper-output Mapping (best-effort, not load-bearing without tab/fig file source-of-truth)

Without access to the paper LaTeX, mapping is inferred from filenames and the change-log narrative:

| File | Likely Paper Destination |
|---|---|
| `va_sib_acs_spec_test_tab.do` (3 CSVs: score, outcome, outcome_dk) | Tables for sibling+census-controls robustness check (likely Table 5 or 6, "Robustness: Sibling and Census Controls"). |
| `va_sib_acs_fb_test_tab.do` | FB test table for restricted sample (likely an Appendix table or Table 6 robustness rows). |
| `va_sib_acs_vam_tab.do` | Possibly an appendix table showing the underlying VAM regression coefficients (school-controls, demographic-controls). |
| `reg_out_va_sib_acs_tab.do` | The persistence-on-VA tables (Table 7-style: outcomes regressed on test-score VA, reporting effect sizes). |
| `reg_out_va_sib_acs_fig.do` | Heterogeneity by prior-decile figures, comparing OG sample to restricted-sample specs. |
| `reg_out_va_sib_acs_dk_fig.do` | DK-VA prior-decile heterogeneity figures. |
| `va_sibling_spec_test_tab.do`, `va_sibling_fb_test_tab.do`, `va_sibling_vam_tab.do` | Older sibling-only tables. May or may not appear in current paper; could be in supplementary. |
| `va_sibling_*_est_sumstats.do` | Diagnostic figures (correlation scatters); likely in appendix only. |
| `siblingmatch.do`, `uniquefamily.do`, `siblingpairxwalk.do`, `siblingoutxwalk.do` | Upstream — no direct paper output. Numbers like "X% of g11 students matched to siblings" might appear in data section. |

This mapping needs to be cross-checked against the paper LaTeX (`~/github_repos/va_paper_clone/paper/`).

---

## SE Clustering Audit

| File | Regression | Cluster |
|---|---|---|
| `va_sibling.do` | spec test (L135), fb test (L276) | `school_id` |
| `va_sibling_out.do` | spec test (L126, L158), fb test (L308) | `school_id` |
| `va_sibling_out_forecast_bias.do` | spec test (L105, L137), fb test (L170) | `school_id` |
| `va_sib_acs.do` | spec test (L88, L122, L162, L204), fb test (L132, L172, L214, L223) | `school_id` (all 8) |
| `va_sib_acs_out.do` | parallel | `school_id` |
| `va_sib_acs_out_dk.do` | parallel | `school_id` |
| `reg_out_va_sib_acs.do` | main regs (L94, L112) | `school_id` |
| `reg_out_va_sib_acs.do` | hetero by prior (L151, L174), hetero by prior×SED (L211, L225) | **`cdscode`** ← inconsistent with main |
| `reg_out_va_sib_acs_dk.do` | main regs (L88, L112) | `school_id` |
| `reg_out_va_sib_acs_dk.do` | hetero by prior (L146) | **`cdscode`** ← inconsistent |

**Real inconsistency:** the heterogeneity regressions in `reg_out_va_sib_acs.do` and `reg_out_va_sib_acs_dk.do` cluster on `cdscode`, while the corresponding main regressions cluster on `school_id`. If `cdscode` and `school_id` are not 1-to-1 — and they may not be (`cdscode` is the CDE code, `school_id` is presumably a Matt-defined integer encoding) — then the SEs are not directly comparable across the main and hetero regressions. Worth a primary-source check.

---

## DK Controls — answer to N7

**See File 14 (`va_sib_acs_out_dk.do`) above.** Verified at L64: `local sib_acs_dk_controls va_ela_og va_math_og` is **a single hard-coded list** that does NOT vary across the 4 specs (og/acs/sib/both). Same OG-spec test-score VA used as DK control for all 4 outcome-VA specs. This is supported by `create_va_sib_acs_out_restr_smp.do` L85 which builds the DK touse from `va_<subject>_og` (not spec-matched). **Likely a design choice rather than a bug** (the author explicitly used "OG" as the deep-knowledge baseline), but worth verifying with the author since spec-matched DK controls would be the more purist econometric approach.

---

## Sibling Sample Filter Consistency — answer to N8

**`va_sibling.do` L288-292:**

```stata
collapse (firstnm) va_* (mean) sbac_*_r* ///
  (sum) n_g11_<subject> = touse_g11_<subject> ///
  if sibling_full_sample == 1 & sibling_out_sample == 1 ///
  , by(school_id cdscode grade year)
```

**`va_sibling_out.do` L327-331:**

```stata
collapse (firstnm) va_* ///
  (mean) g11_<outcome>* ///
  (sum) n_g11_<outcome> = touse_g11_<outcome> ///
  , by(school_id cdscode grade year)
```

**Asymmetry confirmed:** `va_sibling.do` adds `if sibling_full_sample == 1 & sibling_out_sample == 1` on the collapse (L291), `va_sibling_out.do` does not (no `if` clause at L327-331).

**Mitigation:** The dataset that `va_sibling_out.do` collapses was already loaded with `if touse_g11_<outcome>==1 & sibling_out_sample == 1` (L100), so all observations on the collapse step already satisfy `sibling_out_sample == 1`. Adding the explicit filter would be redundant. So the asymmetry is **harmless in practice** but visually jarring.

`va_sibling.do` similarly load-filters at L109 (`if touse_g11_<subject>==1 & sibling_out_sample == 1`), so the additional filter on collapse at L291 is doubly-redundant — but in particular the `sibling_full_sample == 1` check is NEW (not in load-filter). Since `sibling_full_sample == 1` is set at `uniquefamily.do` L69 for ALL students with `ufamilyid` (i.e., ALL siblings in the matched sample), and all siblings already pass the load filter `sibling_out_sample == 1` (which is a subset of `sibling_full_sample == 1`), this filter is **also redundant** but clearer about intent.

**Verdict:** No bug, but a stylistic asymmetry between two parallel files. Both produce the same dataset.

---

## Cross-repo integration: `siblingoutxwalk.do` × `merge_k12_postsecondary.doh`

Verified flow at `siblingoutxwalk.do` L53-71:

1. L56-59: Load **K-12 test scores from `cde_va_project_fork`** ($vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta).
2. **L61: `do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only`** — invokes Matt's helper, passing `enr_only` as positional arg. The helper (read at `cde_va_project_fork/do_files/merge_k12_postsecondary.doh`) does:
   - L66-71: Merge to NSC crosswalk (`nsc_outcomes_crosswalk_ssid.dta`).
   - L141-147, L152-156: Merge to CCC crosswalk + outcomes.
   - L206-219: Merge to CSU crosswalk + outcomes.
   - L324-393: Compute aggregate enrollment vars (`enr`, `enr_2year`, `enr_4year`, `enr_ontime`, etc.) by combining NSC/CCC/CSU.
   - With `enr_only=enr_only`, restricts vars to enrollment-only (drops persistence, degrees).
3. L62-65: rename `_ontime` versions to be the canonical names (because in this project we use on-time enrollment as the primary outcome).
4. L66: drop missing ssid.
5. L71: save the merged dataset back to **`$projdir/dta/common_core_va/k12_postsecondary_out_merge.dta`** (in `caschls`).

**Direction of data flow:** Data flows from `$vaprojdir` (cde_va_project_fork) → through Matt's `merge_k12_postsecondary.doh` helper → into `$projdir` (caschls). Both repos contribute: cde_va_project_fork supplies the input data and the merge helper; caschls is where the output dataset is consumed.

**Implication for relocation/consolidation:** If the project consolidates into a single repo, the `siblingoutxwalk.do` ↔ `merge_k12_postsecondary.doh` boundary collapses, and the `enr_only` arg can either be inlined (if there's only one usage) or kept as a helper.

---

## Summary of Notable Findings

1. **N1 verdict:** `siblingoutxwalk.do` is SAFE to relocate to `siblingxwalk/` — no consumer breaks (consumers read its output dataset, which is already in `siblingxwalk/dta/`); the two callers (`master.do` L103, `do_all.do` L142) need path updates.
2. **DK controls (N7):** `va_sib_acs_out_dk.do` L64 uses `va_ela_og va_math_og` as DK control for ALL 4 outcome specs (og, acs, sib, both). Possibly a design choice; possibly a bug. Inherited consistently from `create_va_sib_acs_out_restr_smp.do` L85 (which builds DK touse off `va_<subject>_og` only). Flag for Christina.
3. **mtitles bug in `reg_out_va_sib_acs_tab.do` L82-88:** Uses forecast-bias-test mtitles for what is a regression-of-outcome-on-VA table. **Mislabeled output** — the column headers say "Original w/ Census Leave Out" etc. when they should say "Original Specification" / "Census Controls" / "Sibling Controls" / "Sibling and Census Controls". HIGH PRIORITY if these CSVs feed paper tables.
4. **SE clustering inconsistency:** main regressions in `reg_out_va_sib_acs.do` and `reg_out_va_sib_acs_dk.do` use `cluster(school_id)`; heterogeneity regressions use `cluster(cdscode)`. Whether `school_id` ≡ `cdscode` 1-to-1 needs a primary-source check; if not, the SEs are not directly comparable across main vs hetero results.
5. **`acs` spec missing from combined panels:** `reg_out_va_sib_acs_fig.do` L213-216, L309-317 and `reg_out_va_sib_acs_dk_fig.do` L131-135 omit the `acs` spec from graph_combine — only `og`, `sib`, `both` panels are produced. Likely intentional (4-graph layout), but the resulting figure does not display ACS-only specification.
6. **Typo `vaprojdir` (no `$`)** at `vaestmacros.doh` L45 (test-score peer census spec) and L118 (outcome peer census spec). These macros may resolve to broken paths if used; appears to be dead code (commented-out peer regs).
7. **Trailing space typo** at `va_sibling_fb_test_tab.do` L64, L91 in macro reference `\`<subject>_fb_va_sibling \''`. Possible runtime bug.
8. **`siblingmatch.do` L49 `egen group ..., mi`:** treats missing values as same-group. With `, mi`, students with missing address fields can collapse into one mega-family — partially mitigated by L22 dropping near-empty addresses, but worth flagging.
9. **No surname normalization** in matching (case-sensitive, no trim, no accent strip).
10. **Drift limit default = 2** for both `va_sibling.do` and `va_sibling_out.do` (verified formula).
11. **`reg_out_va_sib_acs_dk_tab.do` listed in prompt does not exist** — only the `_fig.do` counterpart exists. Verify if the missing tab file was an intentional omission.
12. **Cross-repo data flow:** `siblingoutxwalk.do` reads K-12 data from `$vaprojdir`, runs Matt's merge helper from `$vaprojdir`, writes output to `$projdir`. Boundary spans both repos cleanly.

---

## Files Inspected (absolute paths)

All in `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/`:

- `siblingxwalk/siblingmatch.do`, `siblingxwalk/uniquefamily.do`, `siblingxwalk/siblingpairxwalk.do`
- `siblingvaregs/vafilemacros.doh`, `siblingvaregs/vaestmacros.doh`
- `siblingvaregs/siblingoutxwalk.do`, `siblingvaregs/createvasample.do`, `siblingvaregs/siblingvasamples.do`
- `siblingvaregs/va_sibling.do`, `siblingvaregs/va_sibling_out.do`, `siblingvaregs/va_sibling_out_forecast_bias.do`
- `siblingvaregs/va_sib_acs.do`, `siblingvaregs/va_sib_acs_out.do`, `siblingvaregs/va_sib_acs_out_dk.do`
- `siblingvaregs/create_va_sib_acs_restr_smp.do`, `siblingvaregs/create_va_sib_acs_out_restr_smp.do`
- `siblingvaregs/reg_out_va_sib_acs.do`, `siblingvaregs/reg_out_va_sib_acs_dk.do`
- `siblingvaregs/reg_out_va_sib_acs_tab.do`, `siblingvaregs/reg_out_va_sib_acs_fig.do`, `siblingvaregs/reg_out_va_sib_acs_dk_fig.do`
- `siblingvaregs/va_sib_acs_spec_test_tab.do`, `siblingvaregs/va_sib_acs_fb_test_tab.do`, `siblingvaregs/va_sib_acs_vam_tab.do`
- `siblingvaregs/va_sib_acs_est_sumstats.do`, `siblingvaregs/va_sib_acs_out_est_sumstats.do`
- `siblingvaregs/va_sibling_est_sumstats.do`, `siblingvaregs/va_sibling_out_est_sumstats.do`
- `siblingvaregs/va_sibling_sample_sumstats.do`
- `siblingvaregs/va_sibling_spec_test_tab.do`, `siblingvaregs/va_sibling_fb_test_tab.do`, `siblingvaregs/va_sibling_vam_tab.do`

Cross-repo files referenced (read for verification, not in audit scope):

- `/Users/christinasun/github_repos/cde_va_project_fork/do_files/merge_k12_postsecondary.doh`
- `/Users/christinasun/github_repos/cde_va_project_fork/do_files/sbac/macros_va.doh`
- `/Users/christinasun/github_repos/cde_va_project_fork/do_files/sbac/merge_sib.doh`
- `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/master.do`
