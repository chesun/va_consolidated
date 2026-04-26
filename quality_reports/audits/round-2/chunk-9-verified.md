# Chunk 9 — Round-2 Independent Blind Verification

**Scope:** `cde_va_project_fork/do_files/share/` (10 files), `do_files/share/check/` (1 file), `do_files/explore/` (3 files). **13 files, 4045 lines total.**

**Date:** 2026-04-26 | **Round-1 isolated:** Yes (no `round-1/` access)
**Method:** Direct primary-source reading with line-cited findings.

---

## Per-file inventory

### 1. `cde_va_project_fork/do_files/share/base_sum_stats_tab.do` (590 lines)

**Purpose:** Build summary-statistics estimates AND the LaTeX `sum_stats_g11.tex` and `sum_stats_college.tex` tables (paper Table 1).

**Inputs:**
- `data/va_samples_v1/base_nodrop.dta` (L182)
- `k12_test_scores'/k12_test_scores_clean.dta` (L59) [under L48 toggle, default off]
- `k12_test_scores'/k12_lag_test_scores_clean.dta` (L67)
- `k12_test_scores'/k12_peer_test_scores_clean.dta` (L79)
- `k12_test_scores_public'/k12_diff_school_prop_schyr.dta` (L98)
- `k12_test_scores_public'/k12_cohort_size_sch.dta` (L102)
- `k12_public_schools'/k12_public_schools_clean.dta` (L106)
- `data/va_samples_v1/score_las.dta` (L307)

**Outputs (absolute):**
- `/Users/christinasun/github_repos/cde_va_project_fork/estimates/va_cfr_all_v1/sum_stats/sum_stats_g11_{ela,math}{,_dropped,_all,_las,_college,_college_dropped,_college_all,_college_las}.ster` — 12 ster files (L204, L219, L233, L245, L260, L275, L286, L292, L298, L345, L356, L364)
- `$vaprojdir/tables/share/va/pub/sum_stats_g11.tex` (L463, +5 appends through L539) — **paper Table 1, panel A**
- `$vaprojdir/tables/share/va/pub/sum_stats_college.tex` (L569) — **paper Table 1, panel B**
- Saves `data/va_samples_v1/base_nodrop.dta` only when `create_sample==1` (L177)

**Calls / dependencies:**
- `include $vaprojdir/do_files/sbac/macros_va.doh` (L37)
- `include $vaprojdir/do_files/sbac/drift_limit.doh` (L38)
- `do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only` (L119, L324)
- `include $vaprojdir/do_files/sbac/create_diff_school_prop.doh` (L144)
- `include $vaprojdir/do_files/sbac/create_prior_scores_v1.doh` (L152) — hard-coded `_v1`

**Stata syntax:** `cd`, `cap log close`, `set`, `local`, `use`, `merge`, `estpost sum`, `estimates save`, `eststo`, `esttab`, `tab`, `count`, `tempfile`.

**ssc packages:** `estout`/`esttab`/`estpost`.

**Path references:** Always `tables/share/va/pub/`. All ster paths hard-coded `va_cfr_all_v1`. **No v2 parallel.**

**Paper output:** Table 1 (`tab:sum-stats`, `sum_stats_g11.tex` and `sum_stats_college.tex`).

**Bugs / anomalies:**
- **L182, L307: `data/va_samples_v1/...` hard-coded.** No `foreach version in v1 v2` loop wraps the sumstats logic — only v1 is generated. Confirms Q8.
- **All `estimates save` paths use `va_cfr_all_v1/`** (L204, L219, L233, L245, L260, L275, L286, L292, L298, L345, L356, L364, L435–L460, L555–L567). Hard-coded — no v2 generation despite chunk-9 sibling files (`reg_out_va_tab.do`, `va_var_explain.do`, etc.) running on `foreach version in v1 v2`.
- **L152: `create_prior_scores_v1.doh`** — hard-coded v1 prior-score helper. Even if a v2 toggle existed for the dataset, prior-scores would still be the v1 spec.
- **L324: `do do_files/merge_k12_postsecondary.doh enr_only`** — uses bare relative path (`do_files/`) rather than `$vaprojdir/do_files/`. Works only when `cd $vaprojdir` ran first (L19), but inconsistent with sibling L119 which uses absolute `$vaprojdir/do_files/...`.
- **L463 / L473 / L482 / L521 / L530 / L539: same `tables/share/va/pub/sum_stats_g11.tex`** — first call uses `replace`, subsequent calls use `append`, building a single multi-panel file. Verified via L464 `replace`, L474, L483, L522, L531, L540 `append`. Working as intended but fragile if order changes.
- **L530: `g11_math_all g11_math g11_math_las`** — when appending math row to `sum_stats_g11.tex` table that was opened with ELA columns (L463), the column header semantics change mid-table. Subtle: the columns are now math-stat-replaced but the upstream column header from the first esttab call sticks in the file because `nomtitles nonumbers` is set. Probably OK but visually confusing.

---

### 2. `cde_va_project_fork/do_files/share/kdensity.do` (128 lines)

**Purpose:** Kernel-density plots of VA estimates, base-vs-restricted comparison.

**Inputs:**
- `estimates/va_cfr_all_`version'/va_est_dta/va_`va_outcome'_all.dta` (L47) — `version` from `foreach version in v1 v2` (L45) and `va_outcome` from `{ela, math, enr_2year, enr_4year}` (L46).

**Outputs (absolute):**
- `figures/share/va/`version'/va_`va1'_`va2'_kdensity_b_b_las_las_`version'.pdf` (L107) — figures for ELA/math (`va1=ela, va2=math`) and 2yr/4yr enrollment (`va1=enr_2year, va2=enr_4year`).

**Calls:** `include macros_va.doh` (L37), `include drift_limit.doh` (L38).

**Stata syntax:** `kdensity`, `xtset`, `tempfile`, `merge`.

**Paper output:** Not directly in paper as numbered figure — descriptive supporting plot.

**Bugs / anomalies:**
- **L107: `graph export ... `version'.pdf`** — uses `\`version'` macro outside the `version` foreach. The `foreach version in v1 v2` opens at L45 and the inner `foreach va_type in score enr` is at L80. The kdensity twoway block (L93–105) and the export at L107 sit inside the `va_type` loop but still inside the `version` loop. Macro resolves correctly. **Not a bug.**
- **L40: `local sp_ct_p_combos b_sp_b_ct las_sp_las_ct`** — declared but never used in the file. Dead code.
- **L52: `keep cdscode school_id year *b_sp_b_ct *las_sp_las_ct`** — keeps four VA variants (ela/math × b/las controls). Then loops over `va_*` at L58.
- **L61: `local sd_`v' : di %4.3f = r(sd)`** — captures sd as macro for use in figure note. Fine.
- **L62: `local m_`v' = 0`** — mean macro hard-coded to 0 (because L63 demeans). The note at L102–105 prints "Mean = `m_va_*'" which is always 0 — that's intended after demeaning.
- **L111: closing brace** ends the `va_type` loop. The `version` loop should close before but the next `}` isn't there; instead L112 is empty and the next braces appear at L107 implicitly via outer scope. Let me re-read: L80 opens `foreach va_type`, L91 closes inner if, L98 starts twoway, L107 graph export, L108 closes va_type? Looking carefully: actually L107 IS the export inside va_type, then L108 nothing (end of va_type body), L111 closes va_type. The version loop opened at L45 — closing brace is at end of file but I see only L111 (`}`). Need to check; with `wc -l` showing 128 the file extends past. Looking at L111 `}` — that's `va_type`'s close. But the `version` foreach opened at L45 and the `va_outcome` foreach at L46. L68 closes va_outcome. Then merge logic L71-74 is INSIDE the version loop. Then `va_type` loop L80-111. So L111 closes `va_type`, and somewhere the `version` loop must close. Looking at the file: there's NO explicit `}` for `version` loop visible — but file ends at L128. Actual close must be implicit via end-of-file or there's a missing brace. **Need to verify** — apparent missing closing brace for `version` loop.

Re-checking L111-128: only blank lines and timestamps follow. The `foreach version` loop has no visible close brace. Stata's `do` parser may close implicitly at end-of-file but typically would error. **Possible syntax bug.**

---

### 3. `cde_va_project_fork/do_files/share/reg_out_va_tab.do` (331 lines)

**Purpose:** Persistence regressions of college enrollment on VA. Builds Table 6 (`persistence_single_subject.tex`) and a both-subjects companion table.

**Inputs:**
- `estimates/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_`subject'_`sample_control_peer'_m.dta` (L66) — produced upstream
- `estimates/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_ela_math_`sample_control_peer'_m.dta` (L90)

**Outputs:**
- `tables/va_cfr_all_`version'/reg_out_va/reg_out_`subject'_m.dta` (L75)
- `tables/va_cfr_all_`version'/reg_out_va/reg_out_both_m.dta` (L97)
- `tables/share/va/check/persistence_single_subject.tex` (L200)
- `tables/share/va/pub/persistence_single_subject.tex` (L203) — **paper Table 6**
- `tables/share/va/check/persistence_both_subject.tex` (L303)
- `tables/share/va/pub/persistence_both_subject.tex` (L306) — companion (likely supplementary)

**Calls:** `include macros_va.doh, drift_limit.doh` (L44–45).

**Stata syntax:** `foreach`, append-using pattern (L60–73), `reshape long`/`reshape wide`, `tostring`, `texsave`.

**Paper output:** Table 6 (`tab:va-persistence`, `persistence_single_subject.tex`).

**Bugs / anomalies:**
- **L47: `local sp_ct_p_combos b_sp_b_ct las_sp_b_ct las_sp_b_ct_p las_sp_las_ct_p las_sp_lasd_ct_p`** — FIVE combos.
- **L117–120 and L219–222: Column assignment.**
  - L117: `column = (colgroup-1)*4 + 1 if sample=="b"` (col 1)
  - L118: `column = (colgroup-1)*4 + 2 if sample=="las" & control=="b" & peer=="N"` (col 2)
  - L119: `column = (colgroup-1)*4 + 3 if sample=="las" & control=="b" & peer=="Y"` (col 3)
  - L120: `column = (colgroup-1)*4 + 4 if sample=="las" & control=="las"` (col 4)
- **`las_sp_lasd_ct_p` (control=="lasd") is not assigned to any column.** L121: `drop if column==.` silently drops it. **Confirmed Q6: column-dropping bug — `lasd` rows are silently discarded.** The combo macro pretends to support 5 combos but the column-mapping handles only 4.
- Same applies in the both-subjects regression block (L219–223).
- **L194 / L297: hlines option.** Uses `hlines(3 -4)` and `hlines(-4)` — no obvious issue.
- The `_p` (peer) suffix split between cols 2–4 contains a nuance: for `las/b/N` (col 2) and `las/b/Y` (col 3), peer differs; for `las/las` (col 4), peer is implicitly Y because of `_ct_p` in source naming. But the column-4 condition at L120 doesn't check peer — it accepts ANY `las/las` row regardless of peer. If the upstream regsave produces both `las_sp_las_ct` (no peer) and `las_sp_las_ct_p` (with peer) rows, both would map to col 4 → reshape collision. Looking at L47 only `las_sp_las_ct_p` is in combos, so only one row per outcome; OK in practice.

---

### 4. `cde_va_project_fork/do_files/share/sample_counts_tab.do` (644 lines)

**Purpose:** Construct sample-count cascade table (Table A.1, `counts_k12.tex`).

**Inputs:**
- `data/va_samples_v1/base_nodrop.dta` (L39)
- `k12_test_scores'/k12_lag_test_scores_clean.dta` (L43)
- `sibling_out_xwalk` (L53)
- `data/va_samples_v1/score_a.dta` (L64)

**Outputs:**
- 12 `counts_k12_{stage}_g11_{subject}.ster` files (L92, L105, L121, L137, L156, L177, L200, L227, L258, L291, L326, L364)
- 12 `z_score_k12_{stage}_g11_{subject}.ster` files (L393, L403, L412, L423, L436, L450, L464, L480, L499, L519, L540, L561)
- `tables/share/va/pub/counts_k12.tex` (L615) — **paper Table A.1**

**Calls:** `include macros_va.doh, drift_limit.doh` (L35–36).

**Stata syntax:** `estpost tabstat`, `estimates save`, `eststo`, `esttab`, `tempfile`.

**Paper output:** Table A.1 (`tab:sample-counts`, `counts_k12.tex`).

**Bugs / anomalies:**
- **Q9 confirmed: 12 cascading `if`-filter blocks for counts (L88–382) and 12 for z-scores (L388–561).** 24 cascading blocks total. The `estpost tabstat` call at L88 (line 1 — all students), L99 (line 2 — 9-12 schools), L115 (line 3 — first scores), L129 (line 4 — conventional), L147 (line 5 — cohort_size), L167 (line 6 — nonmissing test score), L189 (line 7 — nonmissing demographic), L214 (line 8 — nonmissing prior), L243 (line 9 — VA cohort), L275 (line 10 — leave-out score), L309 (line 11 — leave-out + sibling), L346 (line 12 — leave-out + sibling + ACS). For z-scores: L388, L397, L406, L415, L427, L440, L453, L467, L484, L503, L523, L543. Twelve each = 24 blocks. **Confirmed.**
- **L575–579: foreach loop iterates 12 sample names** (`all if_school_level first_scores conventional_school cohort_size cst_z_score demographic_controls prior_cst_z_score valid_cohort_size loscore loscore_sib loscore_sib_acs`). Matches.
- **L621: `rename(count_var x sbac_ela_z_score x sbac_math_z_score x)`** — renames `count_var` to `x` and BOTH `sbac_ela_z_score` AND `sbac_math_z_score` to `x`. After renaming the first var, esttab renames remaining vars in sequence. The two later `sbac_*_z_score` renames target the `g11_ela_z_score`/`g11_math_z_score` matrices stored. Looks intentional to give all rows the same coef label `x` and let `coeflabel(x "...")` (L622) populate from the macro. Working but cryptic.
- **L599: `local label_all_scores "+ Nonmissing Test Score"`** — but the foreach iterates `cst_z_score` not `all_scores`. The `label_all_scores` macro is defined but never used. Dead label. Similarly **L601 `label_ssid_grade_year_school` and L607 `label_peer`** — defined but never accessed (the iteration list at L575–579 doesn't include `ssid_grade_year_school` or `peer` as separate stages). Dead code.
- **L41–48: leave-out score variable construction** — `gen loscore = .` and replaces from `L4_cst_ela_z_score` (year 2015–16) and `L5_cst_ela_z_score` (year 2017–18). This is the L4/L5 naming pattern from chunk-7 — confirms the upstream cleaning ELA table-naming.
- **L39: hard-coded `data/va_samples_v1/base_nodrop.dta`.** Like base_sum_stats — no v2 parallel. All `estimates save` paths use `va_cfr_all_v1/sum_stats/`. Final tex output `tables/share/va/pub/counts_k12.tex` is also v1-only.

---

### 5. `cde_va_project_fork/do_files/share/svyindex_tab.do` (186 lines)

**Purpose:** CalSCHLS-survey-index regression tables — bivariate (Panel A) + horse-race (Panel B). Both compcase (complete-case) and imputed variants.

**Inputs:**
- `out/dta/factor/index{bivar,horse}withdemo/{compcase,imputed}_index_{bivar,horse}_wdemo.dta` (L43) — sourced from `$projdir` (CalSCHLS factor outputs from chunk 6).

**Outputs:**
- `tables/share/survey/check/{type}_index_{reg}_wdemo.tex` (L119) — single-panel
- `tables/share/survey/pub/{type}_index_{reg}_wdemo.tex` (L121) — single-panel publication
- `tables/share/survey/check/{type}_index_combined_wdemo.tex` (L143)
- `tables/share/survey/pub/{type}_index_combined_wdemo.tex` (L145) — **paper Table 8** (when `type==imputed`)

**Calls:** None outside `texsave` and `reshape`.

**Paper output:** Table 8 (`tab:survey`, `imputed_index_combined_wdemo.tex`). **Q10 confirmed.**

**Bugs / anomalies:**
- **L185: `translate$vaprojdir/log_files/...`** — missing space between `translate` and `$vaprojdir`. Unlike other share/ files (where `translate $vaprojdir/...` has a space), here the tokenizer would parse `translate$vaprojdir...` as a single token. Stata likely errors at this line with "command translate$vaprojdir... unrecognized." **Critical syntax bug — translate at end-of-script will fail.** The smcl log is closed (L184) but won't be translated. Note: does NOT affect tex output (which already wrote at L121, L145).
- **L33: `local datatype compcase imputed`** and **L35: `local regtype bivar horse`.** Iterations.
- **L43: `use $projdir/out/dta/factor/index`reg'withdemo/`type'_index_`reg'_wdemo, replace`** — `use` with `replace` option is invalid syntax. `replace` is for `save`/`outsheet`/`export`. `use` does not accept `replace`. **Possible bug** — Stata might tolerate as a meaningless trailing token but `use` syntax is `use [varlist] [if] [in] using filename [, clear nolabel]`. With `replace` (no comma), this would fail. Actually re-reading: there's no comma — Stata might treat `replace` as if it were a varlist subset `replace`, which is not a variable, would error "variable replace not found." **Probable syntax bug.**
- **L46: `drop va_dk* va_enr_l* va_enr_b*`** — drop dk, enr_l*, enr_b*. `enr_l*` would match `enr_las_*` patterns (drops all `_las` enrollment cols). `enr_b*` drops base enrollment cols. After this, only `va_ela_*` and `va_math_*` survive (presumably).
- **L48: `drop va_*b_sp_*`** — drops base-sample columns from ELA/math. Combined with L46, only `va_ela_las_sp_*` and `va_math_las_sp_*` survive.
- **L53: `drop if strpos(var, "_")==1`** — drops variables whose names start with `_`. Picks off `_cons` and similar internal names from regsave.
- **L106: `rename va_`i'_las_sp_las_ct_p `i'_las_p`** — variable-name-shortening to avoid texsave character limit. Comment at L104 states this is for character-limit avoidance.
- **L114: missing closing comma before `/*title...*/`** — actually the local macro options local is on the same line; `local texsave_options_single autonumber nonames replace size(footnotesize) hlines(-3)` — the comment block L115–116 follows. Looks fine.
- **L132–135: `insobs 1, before(1)` and `insobs 1, after(7)`** — adds Panel A label at row 1 and Panel B label at row 8. Hard-coded row 7 for "after(7)" — fragile if bivar table row count changes.
- **L185 typo plus L43 syntax → only `tables/share/survey/pub/imputed_index_combined_wdemo.tex` would actually generate IF the script runs at all.** Likely never tested with `set tracedepth` or had `use` flagged.

---

### 6. `cde_va_project_fork/do_files/share/va_scatter.do` (724 lines)

**Purpose:** VA scatter plots (Figures 1, 2, 2alt, 3, 3alt, 4a, 4b, 5a, 5b). Includes correlation/regression annotations.

**Inputs:**
- `estimates/va_cfr_all_`version'/va_est_dta/va_all.dta` (L54)
- `gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_*.gph` (L651, L654, L657, L660, L680, L683, L686, L689) — produced by chunk-7 het regressions

**Outputs:**
- `figures/share/va/`version'/va_`va_outcome'_scatter_*.pdf` (many) — Figures 1, 2, 2alt
- `figures/share/va/`version'/va_combined_scatter_*.pdf` (L255, L268, L281)
- `figures/share/va/`version'/va_enr_2year_4year_scatter_*.pdf` (L310, L323, L356, L369, L391)
- `figures/share/va/`version'/va_ela_math_scatter_*.pdf` (L419, L432, L465, L478, L500)
- `figures/share/va/`version'/va_`outcome'_`subject'_scatter_*.pdf` (L546, L559, L595, L609)
- `figures/share/va/`version'/va_enr_2year_4year_`subject'_scatter_combined_*.pdf` (L638)
- `figures/share/va/`version'/het_reg_*.pdf` (L652, L655, L658, L661, L681, L684, L687, L690)
- `figures/share/va/`version'/het_reg_va_*_combined_*.pdf` (L672, L702)

**Stata syntax:** `corr`, `reg`, `twoway scatter`, `lfit`, `graph combine`, `graph export`, `graph use`.

**Paper output:** Figures 1–5 (combined PDFs).

**Bugs / anomalies — Q5 fitted-line typos confirmed:**
- **L308: `"Fitted line slope = `corr_enr_2year_4year_1'"`** — should be `b_enr_2year_4year_1` (which is defined at L297). **Bug confirmed.**
- **L321: same typo** — weighted `enr_2year_4year` Figure 3 panel 1 (unweighted variant).
- **L333: same typo** in combined-panel-saving twoway block.
- **L417: `"Fitted line slope = `corr_ela_math_1'"`** — should be `b_ela_math_1` (which is defined at L406). Bug confirmed.
- **L430: same typo** for unweighted ela_math base.
- **L442: same typo** in combined-panel-saving twoway block.
- **Total: 6 lines with copy-paste error.**

Additional findings:
- **L50: `/* set trace on */`** — commented out. **L712: `set trace off`** — orphan, no matching `on`. Harmless but inconsistent.
- **L700: missing closing comma before `*/ title("...")*/`** — actually L699 has `/* title("...")*/` — comment is intentional.
- **L529–533, L577–581: regression for `b_*` macro defines** are RE-RUN inside nested `outcome × subject` loop (4 iterations) and then again for `las_sp` controls. Wasteful but not wrong.
- **L107–117: `saving($vaprojdir/gph_files/...)` paths** — these get created but the directory `gph_files/va_cfr_all_v1/` and `gph_files/va_cfr_all_v2/` must exist or `saving` errors. Not validated in script.
- **L308, L321, L333 (Figure 3 enr panel 1, "Base sample"):** the regression on L296–297 defines `b_enr_2year_4year_1` correctly, but it's never substituted into the note. The note shows `corr_*` value (correlation rho, ~0.5–0.7 typical) where it claims "Fitted line slope = " — making the figure text say slope when it's actually correlation. **Misleading figure annotation.**
- Pattern looks like the fitted-line slope mistakes appear in figures 3 panel 1 (L308, L321, L333) and figure 3-alt panel 1 (L417, L430, L442) — i.e., the FIRST panel of two-panel scatter combinations. The SECOND panel (las/las with peer) at L354, L367, L379 correctly references `b_enr_2year_4year_2` and L463, L476, L488 correctly references `b_ela_math_2`. So bug is confined to Panel 1 of two combined panels.

---

### 7. `cde_va_project_fork/do_files/share/va_spec_fb_tab_all.do` (278 lines)

**Purpose:** Combined VA specification + forecast-bias test tables (Tables 2 + 3). Rows: spec test + 4 FB rows; columns: 6 sample/control combinations.

**Inputs:**
- `tables/va_cfr_all_`version'/fb_test/fb_`va_outcome'_all.dta` (L69)
- `tables/va_cfr_all_`version'/spec_test/spec_`va_outcome'_all.dta` (L130)

**Outputs:**
- `tables/share/va/check/va_`va_outcome'_`version'.tex` (L200, L202) — both check, never pub
- `tables/share/va/check/va_score_`version'.tex` (L225)
- `tables/share/va/pub/va_score_`version'.tex` (L227) — **paper Table 2**
- `tables/share/va/check/va_out_`version'.tex` (L244)
- `tables/share/va/pub/va_out_`version'.tex` (L246) — **paper Table 3**

**Calls:** `include macros_va.doh, drift_limit.doh` (L56–57); `program rplc` (L47–49) for row-text replacement.

**Paper output:** Table 2 (`va_score_v1.tex`) and Table 3 (`va_out_v1.tex`).

**Bugs / anomalies — Q2 distance-FB row 6:**
- **L76: `replace column=6 if va_sample=="las" & va_control=="lasd" & peer_controls==1`** — column 6 IS for `lasd` (combined LO+ACS+Sib+Distance). Token is `lasd`, NOT just `d`.
- **L82–84: FB keeper.** L82: `keeper=1 if va_control=="b" & inlist(fb_var, "l", "a", "s", "d")` — col 1, 2, 3 (all base-control). L83: `keeper=1 if va_control=="a" & inlist(fb_var, "l", "s", "d")` — col 4 (a-control). L84: `keeper=1 if va_control=="las" & inlist(fb_var, "d")` — col 5 (las-control, distance only).
- **L84 does NOT include `va_control=="lasd"` for column 6.** When `va_control=="lasd"`, no `keeper=1` line fires, so all `fb_var` rows for col 6 are dropped at L86.
- **Result: column 6 in the FB section gets NO data.** Combined with L115 `keep row entry1-entry5` — wait, L115 is `keep row entry1-entry5` but L76 just defined column 6. Re-reading L115: `keep row entry1-entry5` only keeps 5 entry columns! The reshape at L106 created `entry1...entry6`, but L115 drops entry6. So column 6 is wiped out entirely from the FB block. **Confirmed bug:** column 6 (Distance / `lasd`) has NO FB data because (a) no keeper rule for `va_control=="lasd"` and (b) explicit `keep row entry1-entry5` discards it.
- The spec section (L130–177) DOES preserve column 6 (uses all rows after L139 `keep if column!=.`). So the spec test entry for col 6 is retained, but FB entry for col 6 is missing.
- After append (L180), the final table shows a column-6 spec test row but BLANK FB rows for column 6. **Genuine bug.**
- **L84 contradiction with what column 6's row should be:** If row 6 in the paper is the "Distance" Fully-Restricted-with-distance column, the FB row should test the Distance leave-out — but as written, fb_var `d` is needed and it's not retained because keeper rule for `lasd` is absent.
- **Round-1 likely-claimed: Row 6 produced via `lasd` (NOT bare `d`).** Confirmed — `lasd` IS the joint token at L76; `d` token is the FB variable filter at L84 (different semantic).
- **L196 / L198: `texsave_options_single`** has a `title("...")` and `footnote("...")`. These would render in a per-outcome single-panel tex.
- **L200 / L202: BOTH writes go to `check/`** — neither writes to `pub/`. Round-1 claim about "writes to check/ only, never pub/" — TRUE for the per-outcome single-subject tables (L200, L202). The combined panels DO write to pub at L227, L246.
- **L202 frag option:** `texsave using "$vaprojdir/tables/share/va/check/va_`va_outcome'_`version'.tex", frag `texsave_options_single'` — this OVERWRITES the L200 file (same path) with `frag` option. So the per-outcome per-version single tex is the frag version. **Same path used twice — second overwrites first.** Wasteful.
- **L113: `drop row` ; L114: `rename fb_var row`** — replaces the row column with fb_var values. Order matters.

---

### 8. `cde_va_project_fork/do_files/share/va_var_explain.do` (221 lines)

**Purpose:** Compute regression of enrollment VA on both ELA and Math VA (variance-decomposition). Build dta files used by `va_var_explain_tab.do`.

**Inputs:**
- `estimates/va_cfr_all_`version'/va_est_dta/va_all.dta` (L48)
- `estimates/va_cfr_all_`version'/va_est_dta/va_`outcome'_`sample'_sp_`va_ctrl'_ct.dta` (L140)

**Outputs:**
- `estimates/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_ela_math_*_ct{,_p}.ster` (L89, L102)
- `estimates/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_ela_math_*_ct{,_p}.dta` (L92, L105)
- `tables/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_both_all.dta` (L171, L183, L193)

**Stata syntax:** `reg`, `regsave`, `estadd ysumm`, `xtset`, `vam`-related macros.

**Paper output:** Indirect — input to `va_var_explain_tab.do` which produces Table 7.

**Bugs / anomalies — Q7 confirmed:**
- **L19: `set tracedepth 1`**, **L20: `set trace on`** — set at top of file. **NO matching `set trace off` anywhere in the file** (verified via grep — no match). The script will produce a massive log with every macro substitution traced. **Confirmed Q7.**
- **L42: `local b_sample_controls b`** — base sample uses only `b` control.
- **L43: `local las_sample_controls b a ls las lasd`** — restricted sample uses 5 controls (b, a, ls, las, lasd). **Note: `ls` not `l_s` — this implies a leave-out-score+sibling combined macro variant.**
- **L46–119: Main regression loop** — for each (version, sample, outcome, control, peer-toggle), runs `reg va_outcome ~ va_ela + va_math [aw=n_g11]` and saves estimates.
- **L82–94 vs L95–107: `if "`peer'"==""` and `if "`peer'"=="_p"` blocks are IDENTICAL except for the `peer` macro substitution** — the two branches have the same `reg` and the same `estadd`/`estimates save`/`regsave` commands, differing only in whether `_p` is appended to var names. Could be a single block. **Code duplication, not a bug.**
- **L86, L99: `[aw=n_g11_`outcome'_`sample'_sp]`** — analytic weight by school cohort size.
- **L93, L106: `addlabel(outcome, "`outcome' VA", subject, "ELA and Math", sample, `sample', control, `control', peer, `peer_yn')`** — labels `peer` field as `Y` or `N`.
- **L140: `use $vaprojdir/estimates/va_cfr_all_`version'/va_est_dta/va_`outcome'_`sample'_sp_`va_ctrl'_ct.dta`** — but this path matches a non-peer suffix. The inner regression at L168/L180 loads `_ct.ster` (non-peer) AND `_ct_p.ster` (peer). Each adds its own row. Fine.
- **L154–164: `va_cfr_g11_`outcome'_dk*` operations** — DK = Deming-Kane (decomposition variance). Captures `var_va_dk` for the variance-decomposition part of Table 7.
- **L171–187: `regsave using` builds appended dta** — alternates `replace` (first iteration via `append_macro`, set to `replace` at L128 then re-set to `append` after first call at L177). Builds long-format dta with one row per (control, peer) combo.
- **L196: `unexplained=1-r2`** — variance unexplained = 1 minus R² of regression of college VA on ELA+math VA.
- **The `version` foreach (L46) closes at L207 — visible.** The outcome-level foreach loop (L126) is INSIDE the version loop, then closes at L205. Brace structure is OK.
- **L171, L183: `regsave ... addlabel(... va_control, `va_ctrl', ...)`** — addlabel calls write `va_ctrl` macro into a column literally — but Stata `addlabel` expects literal strings. With `va_ctrl='lasd'`, the label is `lasd`. Fine.

---

### 9. `cde_va_project_fork/do_files/share/va_var_explain_tab.do` (143 lines)

**Purpose:** LaTeX table for variance-decomposition (Table 7).

**Inputs:**
- `tables/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_both_all.dta` (L42)

**Outputs:**
- `tables/share/va/check/va_var_explain_`version'.tex` (L115)
- `tables/share/va/pub/va_var_explain_`version'.tex` (L117) — **paper Table 7**

**Paper output:** Table 7 (`tab:va-enr-decomposition`, `va_var_explain_v1.tex`).

**Bugs / anomalies:**
- **L17: `set tracedepth 1`**, **L18: `set trace on`** — followed by **L126: `set trace off`** — properly paired.
- **L48–52: column assignment.** Five columns. **NO column 6 for `lasd`.** Despite `va_var_explain.do` producing `lasd` rows (L43 of that file), this tab file silently drops them via `keep if column!=.` at L54. **Mismatch — `va_var_explain.do` produces 5 controls (b, a, ls, las, lasd) but `va_var_explain_tab.do` only assigns 4 las-sample columns (b, b, b, las) — no `ls` or `lasd` columns.** Looking again: cols 1-5 cover `b/b/0`, `las/b/0`, `las/b/1`, `las/a/1`, `las/las/1`. The `ls` and `lasd` rows are silently dropped.
- **L62–64: control labels** — only `b`, `a`, `las` are renamed. `ls` and `lasd` rows had been filtered out at L54 already.
- **L111–112: `texsave_options_combined`** has `nofix` option. `hlines(1 4 5 5 6 9 10 10)` for 10-row layout (4 stat rows × 2 panels + 2 panel labels).
- **L102–105: drop sample/control/peer rows from Panel A** to avoid duplication with Panel B (added by L107 append). Panel B retains them.

---

### 10. `cde_va_project_fork/do_files/share/check/corr_dk_score_va.do` (85 lines)

**Purpose:** Diagnostic — print covariance matrix between DK VA and test-score VAs for each spec.

**Inputs:**
- `estimates/va_cfr_all_`version'/va_est_dta/va_all.dta` (L47)

**Outputs:**
- Log only: `log_files/share/check/corr_dk_score_va.smcl` → `.txt` (L21, L82–83). No data outputs.

**Paper output:** None — diagnostic only.

**Bugs / anomalies:** None notable. Reads the all-VA dataset and prints `corr X Y, cov wrap` for each (outcome, sample, ctrl) combo.

---

### 11. `cde_va_project_fork/do_files/explore/va_predicted_score.do` (184 lines)

**Purpose:** scrhat (predicted-prior-score) main pipeline. Replace observed lag1 ELA with predicted-from-lag2-ELA, then re-estimate VA (`vam`).

**Inputs:**
- `data/va_samples_`version'/score_`sample'.dta` (L53)
- `data/va_samples_`version'/out_`sample'` (L114)

**Outputs:**
- `estimates/va_cfr_all_`version'/vam/predicted_prior_score/va_*.ster` (L69, L89, L132, L154)
- `estimates/va_cfr_all_`version'/spec_test/predicted_prior_score/spec_*.ster` (L76, L96, L139, L162)
- `estimates/va_cfr_all_`version'/va_est_dta/predicted_prior_score/va_*_ct.dta` (L106, L173)

**Calls:** `macros_va.doh, drift_limit.doh, macros_va_all_samples_controls.doh` (L31–33).

**Paper output:** None — scrhat outputs go to `predicted_prior_score/` subdirs and `tables/explore/` (via L11).

**Bugs / anomalies — Q3 scrhat pipeline:**
- **Q3a: First-stage regression** — L57 (score) and L116 (enrollment): `reg prior_ela_z_score lag2ela i.year ``va_ctrl'_spec_controls'`. The regressor is `lag2ela` (twice-lagged ELA z-score).
- **Q3b: `predict prior_ela_z_score_hat`** — L58 (score) and L117 (enrollment).
- **Q3c: How does the predicted score replace observed?** — It does NOT directly replace `prior_ela_z_score` in the data. Instead, the macros `<va_ctrl>_scrhat_spec_controls` (at L65, L84, L128, L149) substitute `prior_ela_z_score_hat` for `prior_ela_z_score` in the controls list. Verified in `macros_va.doh` L319+ where `b_scrhat_spec_controls` etc. are defined.
- **Q3d: Effective sample.** The first-stage `reg` runs on rows where `lag2ela` is non-missing (Stata's listwise default). `predict` then fills `prior_ela_z_score_hat` for ALL rows where `lag2ela` is non-missing (in-sample prediction). For out-of-sample rows (lag2ela missing), `prior_ela_z_score_hat` is missing. Then `vam` listwise-drops on the predicted-hat — effectively restricting to lag2ela-non-missing subset.
- **Q3e: scrhat in paper?** L106, L173 save dta to `va_est_dta/predicted_prior_score/` — separate subdir. Tables (from `va_predicted_score_spec_fb_tab.do`) write to `tables/explore/` (not `tables/share/va/pub/`). **Confirmed: scrhat outputs are NOT in the paper.**
- **L57, L116: First stage IS recomputed every iteration.** Once for each (ela, sample, va_ctrl) and once per (outcome, sample, va_ctrl). **Per-iteration recomputation that could be cached** if first stage is deterministic per (sample, va_ctrl). Quality issue, not correctness. (However, the dataset is reloaded each iter at L53/L114, so cached macro wouldn't survive.)
- **L171: `label data "`outcome' VA estimates for `sample' sample with `va_ctrl'' controls"`** — note the extra single-quote: ``va_ctrl''` should be ``va_ctrl'`. **Typo — would cause label to expand `va_ctrl'` (with trailing quote) producing unbalanced macro reference.** Stata may swallow it gracefully (recovery from unbalanced macro is silent in `label data`) or might warn. Same string at L104 has correct `\``va_ctrl' controls"` — single trailing quote. So **L171 has typo, L104 doesn't.**

---

### 12. `cde_va_project_fork/do_files/explore/va_predicted_score_fb.do` (263 lines)

**Purpose:** scrhat parallel of forecast-bias test pipeline.

**Inputs:** Same as #11.

**Outputs:**
- `estimates/va_cfr_all_`version'/vam/predicted_prior_score/va_*_lv.ster` (L90, L135, L194, L237)
- `estimates/va_cfr_all_`version'/fb_test/predicted_prior_score/fb_*_lv.ster` (L100, L144, L203, L247)

**Bugs / anomalies — Q4:**
- **L43: `foreach fb_var of local `va_ctrl'_ctrl_leave_out_vars`** — uses `<va_ctrl>_ctrl_leave_out_vars` (NOT `<va_ctrl>_ctrl_scrhat_leave_out_vars`).
- Cross-checked in `macros_va_all_samples_controls.doh`:
  - L69: `b_ctrl_leave_out_vars l a s la ls as las d` (8 fb_var values)
  - L79: `b_ctrl_scrhat_leave_out_vars a s as d` (4 fb_var values — drops `l`, `la`, `ls`, `las`)
- The scrhat version explicitly excludes `l` (and combinations containing `l`) because under scrhat the prior score is the predicted leave-out score itself — so the FB test for "added leave-out score as control" is meaningless / circular.
- **By using the non-scrhat macro at L43, this script iterates `fb_var` over `l, a, s, la, ls, as, las, d` for the scrhat-VA — running `l` (leave-out-score) FB tests that are conceptually invalid under scrhat.** These extra runs are wasted compute AND potentially produce nonsense FB statistics that get saved to `fb_*_lv.ster` files.
- **Q4 confirmed: L43 uses `<va_ctrl>_ctrl_leave_out_vars` instead of `<va_ctrl>_ctrl_scrhat_leave_out_vars`. Bug.**
- Additionally, L46: `foreach sample of local `fb_var'_fb_`va_ctrl'_samples` — uses `<fb_var>_fb_<va_ctrl>_samples` macro, which is sample-list per (fb_var, va_ctrl) combo. If `fb_var=="l"` and `va_ctrl=="b"` (a combo only valid in non-scrhat space), this macro might be empty (no samples), causing the inner loop to no-op silently. Or it might be defined for all combos including `l*` ones, in which case scrhat-`l`-FB tests run.
- **L56–57, L160–161: First-stage repeated** — same wasteful pattern as #11.

---

### 13. `cde_va_project_fork/do_files/explore/va_predicted_score_spec_fb_tab.do` (269 lines)

**Purpose:** scrhat-version of `va_spec_fb_tab_all.do` — combine spec + FB into single table for scrhat VA.

**Inputs:**
- `tables/va_cfr_all_`version'/fb_test/fb_`va_outcome'_all.dta` (L57)
- `tables/va_cfr_all_`version'/spec_test/spec_`va_outcome'_all.dta` (L119)

**Outputs:**
- `tables/explore/va_`va_outcome'_`version'.tex` (L197)
- `tables/explore/va_score_`version'.tex` (L220)
- `tables/explore/va_out_`version'.tex` (L237)

**Paper output:** None — `tables/explore/` is non-paper.

**Bugs / anomalies:**
- **L59–64, L120–125: Column filters include `& predicted_score == 1`** — explicitly selects only scrhat rows. Good.
- **Column 6 SAME bug as `va_spec_fb_tab_all.do`:**
  - L64: column 6 maps to `va_control=="lasd"` — `lasd` token.
  - L71–73: keeper for `b`, `a`, `las` only — no `lasd` keeper.
  - L104: `keep row entry1-entry5` — explicit drop of column 6 entry. **Bug propagated.**
- **L158: `rename predicted_score entrypredicted_score`** — adds `predicted_score` row; L165, L180: `rplc "Predicted Scores" "predicted_score"`. New row vs share/ version.
- **L97: `rowgroup=1*(fb_var=="l")+...`** — keeps `l` as a possible fb_var even though scrhat shouldn't have `l` (per Q4 discussion). However, the keeper at L71–73 doesn't include `va_control=="b" & inlist(fb_var, "l", ...)` — wait, **L71: `keeper=1 if va_control=="b" & inlist(fb_var, "a", "s", "d")`** — drops `l` from FB rows for col 1! This is DIFFERENT from `va_spec_fb_tab_all.do` L82 which DID include `"l"`. Suggests this scrhat version recognizes that under scrhat, `l` FB is invalid. **But L97 still computes `rowgroup=1*(fb_var=="l")+...` setting non-`l` rowgroups starting at 2 — leaving rowgroup=0 for fb_var=="l". After L100 `sort rowgroup rowgroup2`, rowgroup=0 sorts first.**
- However, `keeper==1` filter at L75 `keep if keeper==1` — drops `l` rows for col 1 (only `a, s, d` kept). So the `l` row never appears in the final table. **Internally consistent.**
- **L269: `translate $vaprojdir/log_files/explore/va_predicted_score_spec_fb_tab.smcl /// $vaprojdir/log_files/share/va_predicted_score_spec_fb_tab.log, replace`** — destination path uses `log_files/share/` instead of `log_files/explore/`. **Path-mismatch typo: writes log file to wrong directory.**

---

## Cross-cutting findings

### Critical: `va_spec_fb_tab_all.do` does not filter `predicted_score`

`va_spec_fb_tab_all.do` (file #7) is the producer of paper Tables 2 and 3. Its column-mapping at L71–76 does NOT filter on `predicted_score==0`. Per chunk-7/8, the upstream `fb_*_all.dta` and `spec_*_all.dta` datasets now include rows for both predicted_score=0 (regular VA) and predicted_score=1 (scrhat VA). Without filtering, the column reshape at L106 will see TWO rows for each (column, fb_var) combination — one with predicted_score=0 and one with =1. This collides at the reshape, producing either an error or duplicate rows. Compare to `va_predicted_score_spec_fb_tab.do` L59–64 which explicitly filters `& predicted_score == 1`. **A symmetric filter `& predicted_score == 0` should appear in `va_spec_fb_tab_all.do` L71–76.** Without it, paper Tables 2 and 3 contents are unreliable.

### Critical: Column 6 (Distance / `lasd`) FB rows are dropped

In both `va_spec_fb_tab_all.do` (L84, L115) and `va_predicted_score_spec_fb_tab.do` (L73, L104), the FB-section keeper rules cover `va_control` ∈ {b, a, las} but NOT `lasd`. Column 6 in the source dataset (the Distance column) has `va_control=="lasd"`, so no keeper fires, and the `keep row entry1-entry5` truncation removes it explicitly. **Result: in paper Tables 2 and 3, column 6 has the spec-test row populated but BLANK FB rows.** This is a producer-side inconsistency.

### Critical: `va_var_explain.do` `set trace on` without `off`

L20 turns trace on; no matching off. When this file runs inside `main.do`, every macro substitution in subsequent files would also be traced if no other file resets it. Practically, the `va_var_explain_tab.do` sibling has its own `set trace on/off` pair which resets, but during the `va_var_explain.do` run alone, the log file would balloon.

### v1-only paths (no v2 parallel)

- `base_sum_stats_tab.do` — fully v1-only (L182, L307, all `estimates save` paths, `create_prior_scores_v1.doh`).
- `sample_counts_tab.do` — fully v1-only (L39, L64, all 24 `estimates save` paths, `tables/share/va/pub/counts_k12.tex`).
- All other share/ files use `foreach version in v1 v2` properly.

### `lasd_ct_p` silently dropped in `reg_out_va_tab.do`

L47 declares 5 combos; L117–120 (and L219–222) only assign columns 1–4 based on b/las+b/N, b/Y, las patterns. The `lasd_ct_p` rows have `column==.` and are dropped at L121/L223. **The 5th combo is dead.**

### Fitted-line-slope typos in `va_scatter.do` (Figures 3 panel 1, 3-alt panel 1)

- L308, L321, L333: `corr_enr_2year_4year_1` should be `b_enr_2year_4year_1`
- L417, L430, L442: `corr_ela_math_1` should be `b_ela_math_1`
- The corresponding _2 panels (las/las with peer) are correct.
- 6 lines total. The figure note prints the correlation rho where it claims "Fitted line slope = ".

### `predict prior_ela_z_score_hat` — variable-not-dropped between iterations

In `va_predicted_score.do` L58 and L117, `predict prior_ela_z_score_hat` is called without first checking if the variable already exists. Each iteration `use ... clear` reloads the dataset (L53, L114), which drops all pre-existing variables, so the predict line is safe within one iteration. But the inner control-loop reuses the variable name `prior_ela_z_score_hat` without verifying — Stata's `predict` errors on "variable already defined" if the var exists.

### `svyindex_tab.do` syntax problems

- L43: `use ... using filename, replace` — `replace` not valid for `use`. Probable error.
- L185: `translate$vaprojdir` — missing space between `translate` and macro. Probable error.

### `kdensity.do` apparent missing close brace

The `foreach version in v1 v2` opens at L45 but no closing `}` appears for it before EOF (L128 is the last line; intermediate close braces are L68 for `va_outcome` and L111 for `va_type`). Need to verify by Stata parse, but visually one brace is missing.

---

## Q1 — Paper-output producer mapping (closed-loop)

| Paper artifact | Producer file (chunk 9) | Output path | Lines |
|---|---|---|---|
| Table 1 (`tab:sum-stats`, `sum_stats_g11.tex`) | `share/base_sum_stats_tab.do` | `tables/share/va/pub/sum_stats_g11.tex` | L463, L473, L482, L521, L530, L539 (multi-append) |
| Table 1 (`sum_stats_college.tex`) | `share/base_sum_stats_tab.do` | `tables/share/va/pub/sum_stats_college.tex` | L569 |
| Table 2 (`tab:va-sum-stats`, `va_score_v1.tex`) | `share/va_spec_fb_tab_all.do` | `tables/share/va/pub/va_score_v1.tex` | L227 |
| Table 3 (`tab:va-enr-summary-statistics`, `va_out_v1.tex`) | `share/va_spec_fb_tab_all.do` | `tables/share/va/pub/va_out_v1.tex` | L246 |
| Table 6 (`tab:va-persistence`, `persistence_single_subject.tex`) | `share/reg_out_va_tab.do` | `tables/share/va/pub/persistence_single_subject.tex` | L203 |
| Table 7 (`tab:va-enr-decomposition`, `va_var_explain_v1.tex`) | `share/va_var_explain_tab.do` | `tables/share/va/pub/va_var_explain_v1.tex` | L117 |
| Table 8 (`tab:survey`, `imputed_index_combined_wdemo.tex`) | `share/svyindex_tab.do` | `tables/share/survey/pub/imputed_index_combined_wdemo.tex` | L145 (when `type==imputed`) |
| Table A.1 (`tab:sample-counts`, `counts_k12.tex`) | `share/sample_counts_tab.do` | `tables/share/va/pub/counts_k12.tex` | L615 |
| Figs 1–5 (combined PDFs) | `share/va_scatter.do` | `figures/share/va/{v1,v2}/va_*combined*_nw.pdf` and `het_reg_*combined*.pdf` | L255, L268, L281, L391, L500, L638, L672, L702 |
| Fig (kdensity supplementary) | `share/kdensity.do` | `figures/share/va/{v1,v2}/va_*_kdensity_*.pdf` | L107 |

**Closed-loop verdict:** Every paper Table 1/2/3/6/7/8/A.1 has a chunk-9 producer that writes to `tables/share/{va,survey}/pub/`. Figures 1–5 have producers in `va_scatter.do` writing to `figures/share/va/{version}/`. **Loop closes.** scrhat outputs (`tables/explore/`) are intentionally outside the paper.

---

## Q2 — Distance-FB Row 6 paper attribution

- **Producer:** `va_spec_fb_tab_all.do` (file #7).
- **Token:** `lasd` (L76 maps column 6 to `va_sample=="las" & va_control=="lasd" & peer_controls==1`). The `d` token is the FB-variable filter (`fb_var=="d"` for Distance).
- **CRITICAL BUG:** The FB section's keeper rule (L82–84) does NOT include `va_control=="lasd"`, so all `fb_var` rows for column 6 are dropped. Combined with `keep row entry1-entry5` at L115, column 6 FB rows are entirely missing from the final table.
- **Result:** Paper Tables 2 and 3 column 6 (Distance) shows the spec-test row but blank FB rows. **Genuine, currently un-fixed bug in the paper-output producer.**

---

## Q3 — scrhat (predicted-prior-score) pipeline

| Step | Where | Lines |
|---|---|---|
| 3a. First-stage regression `reg prior_ela_z_score lag2ela i.year ...` | `va_predicted_score.do` (and `_fb.do`) | L57 (score), L116 (enrollment) in `va_predicted_score.do`; L56, L160 in `_fb.do` |
| 3b. `predict prior_ela_z_score_hat` | Same files | L58, L117 in `va_predicted_score.do`; L57, L161 in `_fb.do` |
| 3c. Predicted score "replaces" observed | NOT a `replace` statement; rather, the macro `<va_ctrl>_scrhat_spec_controls` (defined in `macros_va.doh`) substitutes `prior_ela_z_score_hat` for `prior_ela_z_score` in the `vam` controls list | L65, L84, L128, L149 (score); L116, L160 (enrollment); referenced macros at `macros_va.doh` L319, L342, L362, L381, L400, L420, L440, L463 etc. |
| 3d. Effective sample | Subset where `lag2ela` is non-missing (first-stage listwise default → predict missing for lag2ela-missing rows → vam drops those rows) | implicit via `predict` semantics |
| 3e. scrhat outputs in paper? | NO — outputs to `tables/explore/` and `estimates/.../predicted_prior_score/` subdir | `va_predicted_score_spec_fb_tab.do` L197, L220, L237 |

---

## Q4 — `va_predicted_score_fb.do` leave-out variable list

**Confirmed.** L43 uses `<va_ctrl>_ctrl_leave_out_vars` (the non-scrhat macro). Should be `<va_ctrl>_ctrl_scrhat_leave_out_vars`.

Evidence from `macros_va_all_samples_controls.doh`:
- L69 `b_ctrl_leave_out_vars`: 8 vars (includes `l`, `la`, `ls`, `las`)
- L79 `b_ctrl_scrhat_leave_out_vars`: 4 vars (excludes leave-out-score-containing variants)

By using the non-scrhat list, the script runs FB tests for `fb_var ∈ {l, la, ls, las}` under scrhat — invalid because under scrhat the leave-out score IS the predicted prior score itself.

---

## Q5 — `va_scatter.do` figure-note typos

**Confirmed.** Six lines say `corr_*` where they should say `b_*`:
- L308, L321, L333 (Figure 3, panel 1, base sample)
- L417, L430, L442 (Figure 3-alt, panel 1, ELA-vs-Math base)

All in the FIRST panel of two-panel figures. The corresponding SECOND panel (las+peer) at L354/L367/L379 and L463/L476/L488 correctly references `b_*`. Copy-paste error confined to panel 1 of two figures.

---

## Q6 — `reg_out_va_tab.do` column dropping

**Confirmed.** L47 declares 5 combos including `las_sp_lasd_ct_p`. L117–120 and L219–222 assign columns 1–4 only (b, las+b+N, las+b+Y, las+las). `las_sp_lasd_ct_p` rows have `column==.` and are dropped at L121/L223. **Fifth combo is silent dead code.**

---

## Q7 — `va_var_explain*.do` `set trace on` without off

- `va_var_explain.do` L20: `set trace on`. **NO matching `off` in file.**
- `va_var_explain_tab.do` L18: `set trace on`. L126: `set trace off`. **Properly paired.**

Round-1 claim partially correct — only `va_var_explain.do` has unpaired `on`; `va_var_explain_tab.do` is OK.

---

## Q8 — `base_sum_stats_tab.do` v2 parallel

**Confirmed.** L182 hard-codes `data/va_samples_v1/base_nodrop.dta`. L307: `data/va_samples_v1/score_las.dta`. L152: `create_prior_scores_v1.doh`. All `estimates save` paths use `va_cfr_all_v1/sum_stats/`. The final tex at L463+, L569 writes to `tables/share/va/pub/` without a version subdirectory or `_v1`/`_v2` suffix.

**No v2 parallel exists.** Sibling chunk-9 files (`reg_out_va_tab.do`, `va_var_explain.do`, etc.) iterate `foreach version in v1 v2` but `base_sum_stats_tab.do` and `sample_counts_tab.do` do not.

---

## Q9 — `sample_counts_tab.do` cascading filters

**Confirmed.** 12 cascading-filter blocks for COUNTS at L88–382:
1. L88 (all students), L99 (9-12 schools), L115 (first scores), L129 (conventional), L147 (cohort_size>10), L167 (nonmissing test score), L189 (nonmissing demographic), L214 (nonmissing prior), L243 (VA cohort >=7), L275 (leave-out score), L309 (leave-out + sib), L346 (leave-out + sib + ACS).

Plus 12 for Z-SCORES at L388–561:
1. L388, L397, L406, L415, L427, L440, L453, L467, L484, L503, L523, L543.

**Total: 24 cascading-`if` blocks.** Each line adds one more `& mi_*==0` filter onto the previous. The cascading is duplicated literally — line 12's count block (L346) repeats all 11 prior conditions plus `& mi_acs==0`. A single missing `&` in the chain would silently break the count. High maintenance burden, but verified consistent across all 24 blocks.

---

## Q10 — `svyindex_tab.do` Table 8 producer

**Confirmed.** L145: `texsave using "$vaprojdir/tables/share/survey/pub/`type'_index_combined_wdemo.tex"`. When `type=="imputed"` (one of two iterations from L33), produces `imputed_index_combined_wdemo.tex` — **paper Table 8**.

**Inputs:** `out/dta/factor/index{bivar,horse}withdemo/{compcase,imputed}_index_{bivar,horse}_wdemo.dta` (L43) — sourced from `$projdir` (CalSCHLS factor-output directory, chunk-6 produced).

**Caveat:** L43 has a syntax error (`use ... , replace`) and L185 has `translate$vaprojdir` typo. Whether Table 8 actually generates depends on whether Stata silently swallows the L43 `replace` token.

---

## Cumulative chunk-9 bug list

| # | File | Line(s) | Severity | Description |
|---|---|---|---|---|
| 1 | `va_spec_fb_tab_all.do` | L71–76, L82–84, L115 | **Critical** | Column 6 (Distance, `lasd`) FB rows dropped — keeper rule missing for `va_control=="lasd"` AND `keep row entry1-entry5` truncates. **Affects paper Tables 2 and 3 column 6.** |
| 2 | `va_spec_fb_tab_all.do` | L71–76 | **Critical** | No `predicted_score==0` filter — chunk-7/8-added column would double rows in column-mapping reshape. **Affects paper Tables 2 and 3.** |
| 3 | `va_predicted_score_fb.do` | L43 | Major | Uses `<va_ctrl>_ctrl_leave_out_vars` instead of `<va_ctrl>_ctrl_scrhat_leave_out_vars`. Iterates over invalid `l`-containing FB tests under scrhat. |
| 4 | `va_var_explain.do` | L20 | Major | `set trace on` without matching `set trace off`. Produces massive log. |
| 5 | `reg_out_va_tab.do` | L47, L117–120, L219–222 | Major | `las_sp_lasd_ct_p` (5th combo) silently dropped — only 4 columns produced. |
| 6 | `base_sum_stats_tab.do` | L182, L307, L152, all estimates paths | Major | Hard-coded v1 — no v2 parallel. |
| 7 | `sample_counts_tab.do` | L39, L64, all save paths | Major | Hard-coded v1 — no v2 parallel. |
| 8 | `va_scatter.do` | L308, L321, L333, L417, L430, L442 | Major | Six "Fitted line slope = `corr_*`" notes — should be `b_*`. Misleading figure annotation. |
| 9 | `svyindex_tab.do` | L43 | Major | `use ... using ..., replace` — `replace` not valid for `use`. Likely runtime error. |
| 10 | `svyindex_tab.do` | L185 | Major | `translate$vaprojdir` — missing space, likely syntax error. Log not translated. |
| 11 | `va_var_explain_tab.do` | L48–52 | Moderate | Only 5 columns — `ls` and `lasd` rows from `va_var_explain.do` dropped silently. |
| 12 | `va_predicted_score_spec_fb_tab.do` | L71–73, L104 | Moderate | Same column-6 FB drop as #1 (parallel bug). Affects scrhat-explore tex but those are non-paper. |
| 13 | `va_predicted_score_spec_fb_tab.do` | L269 | Minor | Log destination path mismatch (writes `log_files/share/...` instead of `log_files/explore/...`). |
| 14 | `va_predicted_score.do` | L171 | Minor | `\``va_ctrl''` extra single-quote in `label data` string — unbalanced macro reference. |
| 15 | `kdensity.do` | L45 / EOF | Moderate | `foreach version` opens at L45; no visible matching close brace before EOF. |
| 16 | `va_scatter.do` | L712 | Minor | Orphan `set trace off` (only commented `/* set trace on */` at L50). Harmless. |
| 17 | `va_spec_fb_tab_all.do` | L200, L202 | Minor | Per-outcome single-subject tex written to `check/` only (never `pub/`). Combined panels DO write to `pub/` — paper outputs OK. Same path overwritten (L200 then L202 with `frag`). |
| 18 | `kdensity.do` | L40 | Minor | Dead local `sp_ct_p_combos`. |
| 19 | `sample_counts_tab.do` | L599, L601, L607 | Minor | Dead label macros (`label_all_scores`, `label_ssid_grade_year_school`, `label_peer`). |
| 20 | `base_sum_stats_tab.do` | L324 | Minor | `do do_files/...` uses bare relative path; sibling L119 uses `$vaprojdir/` prefix. Works only when `cd` ran first. |

---

## Summary

Chunk 9 closes the paper-output mapping loop:

- All 8 paper artifacts (Tables 1, 2, 3, 6, 7, 8, A.1, Figures 1–5) have producers in `cde_va_project_fork/do_files/share/`.
- scrhat (predicted-prior-score) pipeline outputs to `tables/explore/`, isolated from the paper.

Two **critical** bugs affect paper output integrity:

1. **`va_spec_fb_tab_all.do` column 6 FB drop** — paper Tables 2 and 3 column 6 (Distance) has blank FB rows because the keeper rule omits `va_control=="lasd"`.
2. **`va_spec_fb_tab_all.do` no `predicted_score==0` filter** — after chunk-7/8 added the `predicted_score` field to upstream datasets, the table builder doesn't filter, so reshape may collide.

One **major** scrhat-pipeline correctness bug:

3. **`va_predicted_score_fb.do` L43 wrong macro** — uses non-scrhat leave-out-vars list, runs invalid `l*` FB tests under scrhat.

Five **major** bugs that affect specific scenarios:

4. `va_var_explain.do` unpaired `set trace on`.
5. `reg_out_va_tab.do` 5th combo (`lasd`) silently dropped.
6. `base_sum_stats_tab.do` v1 hard-coded.
7. `sample_counts_tab.do` v1 hard-coded.
8. `va_scatter.do` 6 figure-note typos in panel-1 of two-panel figures.

Two **major** likely-syntax bugs in `svyindex_tab.do` (`use ... , replace` and `translate$vaprojdir`) — depending on Stata tolerance.

24 cascading filter blocks in `sample_counts_tab.do` (12 counts + 12 z-scores) verified literally consistent — high maintenance risk but no extant defect.
