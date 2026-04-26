# Chunk 4 — Independent Blind Verification (Round 2)

**Scope:** Pass-through and heterogeneity layer — VA → postsecondary outcome regressions, heterogeneity by prior decile / student characteristics / school characteristics. Produces paper Tables 4-5, 7 and Figures 5-6, OA Figs C.1-C.2.
**Method:** Direct file reads, line-cited; no cross-reference to round-1 outputs.
**Files audited:** 11 primary + 2 helper `.doh` files.

---

## File 1 — `prior_decile_original_sample.do`

- **File:** `/Users/christinasun/github_repos/cde_va_project_fork/do_files/sbac/prior_decile_original_sample.do`
- **Lines:** 121
- **Purpose:** Builds two student-level lookup datasets used by the pass-through regressions: (a) prior-score decile crosswalks (ELA & Math) using the base outcome sample (for the heterogeneity-by-prior-decile regressions) and (b) census-tract household-income deciles using the ACS outcome sample.
- **Inputs:**
  - `$vaprojdir/data/va_samples_v1/out_b.dta` (L76) — base outcome sample
  - `$vaprojdir/data/va_samples_v1/out_a.dta` (L103) — ACS outcome sample
- **Helpers `include`'d:**
  - L40: `$projdir/do/share/siblingvaregs/vafilemacros.doh` (Dropbox path — outside `$vaprojdir`)
  - L43: `$vaprojdir/do_files/sbac/macros_va.doh`
- **Outputs:**
  - L98: `$vaprojdir/data/sbac/prior_decile_original_sample.dta` — student-level prior decile + race + male + econ_disadvantage
  - L109: `$vaprojdir/data/sbac/census_income_decile_a_sample.dta` — student-level income deciles
  - L33, L120-121: `prior_decile_original_sample.smcl` / `.log`
- **Calls:** none active. L56, L71 reference more `include` statements but are inside `/* ... */` comment block (L55-72).
- **Stata syntax:** `xtile ... , n(10)`, `collapse (mean)/(max)`, `label define`, `label values`. No factor-variable use, no `reghdfe`. Stata 12+ idioms.
- **ssc/community packages:** none required.
- **Path references that need updating:**
  - L33, L40, L43, L76, L98, L103, L109, L120-121 — all use `$vaprojdir`
  - L40 — uses `$projdir` (separate Dropbox path)
- **Reference to paper outputs:** Builds inputs (deciles) consumed by `reg_out_va_all.do` and `reg_out_va_dk_all.do` for paper Figures 5-6 and OA Figs C.1-C.2 heterogeneity regressions.
- **Line-cited bugs / anomalies:**
  - **BUG (L106).** `xtile inc_mean_hh_xtile = inc_median_hh, n(10)` — the variable being named "mean" is actually built from `inc_median_hh` (the median variable), identical to L105's source. Either L106 should reference `inc_mean_hh` (with separate underlying var) or the var should be renamed. As written, `inc_mean_hh_xtile` is a duplicate of `inc_median_hh_xtile`. This propagates into `census_income_decile_a_sample.dta` (L108-109).
  - **L82:** prior `merge ... keep(1 3)` is missing `nogen` (L82 of `reg_out_va_all.do` — see file 2). Here at L40 the include uses `$projdir` (Dropbox), which will need consolidation.
  - **L84-88:** race coding overwrites in cascade (`replace race = 1 if eth_black ... replace race = 4 if eth_white`). If a student has overlapping flags (e.g., both `eth_black==1` and `eth_white==1`), the LATER assignment wins (white). Plausibly fine for mutually exclusive flags but worth documenting.
  - **L94-95 collapse.** `(mean) prior_ela_z_score_xtile prior_math_z_score_xtile` then `(max) race male econ_disadvantage` — taking the MEAN of decile (an integer) is unusual. If a student appears in only one observation, mean = that decile. If they appear multiple times, mean is non-integer and might break `i.prior_ela_z_score_xtile` later. Worth verifying that `collapse` produces integer deciles (single-row-per-student).

---

## File 2 — `reg_out_va_all.do`

- **File:** `/Users/christinasun/github_repos/cde_va_project_fork/do_files/sbac/reg_out_va_all.do`
- **Lines:** 400
- **Purpose:** Runs OLS pass-through regressions of postsecondary outcomes on test-score VA. Loops over (version v1/v2) × (sample b/las) × (control variant) × (outcome enr/enr_2year/enr_4year) × (peer y/n) × {single-subject ELA, single-subject Math, both-subject} × {base second-stage controls vs matching second-stage controls (`_m`)}. Produces `.ster` (and some `.dta` via `regsave`) files for downstream tables/figures.
- **Inputs:**
  - L64: `$vaprojdir/data/va_samples_`version'/out_`sample'.dta` (sample = b or las)
  - L69: `$vaprojdir/estimates/va_cfr_all_`version'/va_est_dta/va_`subject'_all.dta` (subject = ela/math)
  - L83: `$vaprojdir/data/sbac/prior_decile_original_sample.dta` (built by file 1)
  - L87: `$vaprojdir/data/sbac/census_income_decile_a_sample.dta` (built by file 1)
  - L90: `$vaprojdir/data/public_access/clean/cde/charter_status.dta`
- **Helpers `include`'d:** L46: `$vaprojdir/do_files/sbac/macros_va.doh`
- **Outputs (estimates):**
  - L143: `$vaprojdir/estimates/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_`subject'_`sample'_sp_`control'_ct`peer'.ster` (single-subject, base 2nd-stage controls)
  - L152, L166: same with `_m.ster` suffix (matching 2nd-stage controls)
  - L154, L168, L207, L220: parallel `.dta` writes via `regsave` with `addlabel(...)` metadata
  - L195, L205, L218: both-subject ELA+Math files
  - L247, L258, L268: het_reg single-subject × prior decile (only when `run_prior_score==1` — see bug below)
  - L297, L308, L318: het_reg single-subject × demographic char (race, male, econ_disadvantage, charter, inc_median_hh_xtile when `las`)
  - L338, L349, L360: het_reg both-subject × prior decile
- **Calls:** none.
- **Stata syntax:** `reg`, `c.x#i.factor` (factor-variable interactions), `i.year`, `cluster(school_id)`, `estadd ysumm`, `estimates save`, `regsave ... addlabel(...)`, `forvalues`, `foreach`. Standard Stata 14+.
- **ssc/community packages:** `regsave` (community-contributed).
- **Path references:** all `$vaprojdir`.
- **Reference to paper outputs:** Produces estimates for paper **Table 4** (pass-through ρ for score VA) and paper **Figures 5-6** (heterogeneity-by-prior-decile bar plots, both-subject case) and **OA Figs C.1-C.2** (heterogeneity by demographic chars).
- **Line-cited bugs / anomalies:**
  - **MAJOR (L235).** `local run_prior_score = 0` — this hard-codes a gate that disables the entire single-subject × prior-score-decile heterogeneity block (L236-272). The block is wrapped `if run_prior_score == 1 { ... }`, which is now never true. Consequences:
    1. The single-subject `het_reg_..._va_<subject>_x_prior_<prior_subject>_..._sp_..._ct(_p)(_m).ster` files (L247, L258, L268) are NOT produced by current runs.
    2. `reg_out_va_all_fig.do` at L159 still tries to load these files — that figure step will fail unless those `.ster` were generated by an earlier run.
    3. The both-subject prior-score block (L327-363) is NOT gated and still runs, producing the `het_reg_..._va_ela_math_x_prior_..._...ster` files used in the both-subject panel of Figs 5-6.
  - **L82-83.** `merge m:1 state_student_id using ..., keep(1 3)` (no `nogen`) — leaves `_merge` variable in dataset. Subsequent merge at L86 uses `nogen`, but the `_merge` from L82 stays as an extra variable through the regressions. Sloppy, not blocking.
  - **L60-64 (z-score loop is in `reg_out_va_dk_all.do` not here — see file 3).** Here the standardization at L74-78 is done inside the `foreach subject` loop (L66) — this means after the math merge, the ELA VA variables get re-standardized (idempotent under normal conditions but inefficient).
  - **L156-169 vs L137-149.** When `peer == ""`, the `regsave` (`.dta` with metadata) is written ONLY for the matched controls (`_m`), but estimates (`.ster`) are saved for both base AND matched. When `peer == "_p"`, same. The "base 2nd stage controls" matched controls do not get a `regsave` companion. Consistent within branch but an asymmetry vs the `_m` companion logic.
  - **L171.** `local append_macro append` set inside `if peer=="_p"` branch, but is never used downstream. Dead code.
  - **Naming token consistency.** The control list at L50 (`b_sample_controls`) is `b bd` and at L51 (`las_sample_controls`) is `b a ls las bd ad lsd lasd`. These align with the spec controls defined in `macros_va.doh`. The loop names files using `<sample>_sp_<control>_ct[_p][_m]` consistently. No filename token errors found.

---

## File 3 — `reg_out_va_dk_all.do`

- **File:** `/Users/christinasun/github_repos/cde_va_project_fork/do_files/sbac/reg_out_va_dk_all.do`
- **Lines:** 213
- **Purpose:** Pass-through regressions of postsecondary outcomes on Deep-Knowledge (DK) VA — VA built directly from the corresponding postsecondary outcome on the LHS. Always matches LHS outcome with RHS DK VA (`va_dk_<outcome>_...`). Produces estimates for paper Table 5 (DK VA pass-through) and OA DK heterogeneity figs.
- **Inputs:**
  - L51: `$vaprojdir/data/va_samples_`version'/out_`sample'.dta`
  - L56: `$vaprojdir/estimates/va_cfr_all_`version'/va_est_dta/va_`outcome'_all.dta` (DK VA file per outcome)
  - L69: `$vaprojdir/data/sbac/prior_decile_original_sample.dta`
- **Helpers `include`'d:** L39: `$vaprojdir/do_files/sbac/macros_va.doh`
- **Outputs:**
  - L110, L119, L128: `reg_`outcome'_va_dk_`outcome'_`sample'_sp_`control'_ct`peer'(_m).ster`
  - L146, L156, L166: `het_reg_`outcome'_va_dk_`outcome'_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'(_m).ster`
- **Calls:** none.
- **Stata syntax:** Same idioms as file 2.
- **ssc/community packages:** none.
- **Path references:** all `$vaprojdir`.
- **Reference to paper outputs:** Paper **Table 5** (DK VA pass-through) and DK figures (OA appendix).
- **Line-cited bugs / anomalies:**
  - **L54-65 (multiple-merge re-standardization).** The script merges three DK VA files in a loop (L54-58), one per outcome (`enr`, `enr_2year`, `enr_4year`), and after each merge runs `foreach va of varlist va_*` (L60-64) to z-score every VA variable in the dataset. After the first merge, ELA-named VA vars (none here — DK file only has `va_dk_*`) and prior `va_dk_enr_*` are re-standardized. Z-score is idempotent (within rounding), so result is correct, but inefficient. Not a bug, but worth flagging.
  - **L43-44.** `local b_sample_controls b` and `local las_sample_controls b ls las` — narrower than file 2's `b bd` and `b a ls las bd ad lsd lasd`. Consistent with file 5 (DK tab) at L48-49 (`b` and `b las`) — but file 5 omits `ls`. **Inconsistency between file 3 and file 5:** file 3 includes `ls` for `las_sample_controls` (L44), file 5 omits it. The DK figure file (file 7, L46) uses `b ls las` (matches file 3). The DK table file (file 5, L49) uses `b las` (drops `ls`). When file 5 reads `.ster` files, it skips the `ls` variant — those files exist on disk but never appear in tables. Likely intentional simplification of tables, but worth noting.
  - **L68-69.** `merge m:1 state_student_id using ... keep(1 3)` — no `nogen`. Leaves `_merge` in dataset.
  - **No demographic-heterogeneity regressions.** Unlike file 2 (which has race/male/econ_disadvantage/charter/inc_median_hh_xtile interactions), file 3 only has prior-decile heterogeneity. So DK VA does NOT contribute to demographic-heterogeneity figures. This is a design choice, not a bug.
  - **`set seed 1984` (L33).** Unused — no random operations in the script.

---

## File 4 — `reg_out_va_all_tab.do`

- **File:** `/Users/christinasun/github_repos/cde_va_project_fork/do_files/sbac/reg_out_va_all_tab.do`
- **Lines:** 468
- **Purpose:** Reads `.ster` files saved by file 2 and constructs CSV tables (single-subject and both-subject) of pass-through coefficients for paper Table 4 / OA tables. Heterogeneity-by-prior-decile and heterogeneity-by-demographic-char table-generation blocks are present but commented out (L322-385, L392-449).
- **Inputs:**
  - L184, L193: `reg_`outcome'_va_`subject'_`sample'_sp_`control'_ct`peer'(_m).ster`
  - L265, L273: `reg_`outcome'_va_ela_math_`sample'_sp_`control'_ct`peer'(_m).ster`
- **Helpers `include`'d:** L43: `$vaprojdir/do_files/sbac/macros_va.doh`
- **Outputs:**
  - L219: `$vaprojdir/tables/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va.csv` (one CSV per outcome, single-subject)
  - L306: `$vaprojdir/tables/va_cfr_all_`version'/reg_out_va/reg_out_va_ela_math.csv` (one CSV with all 3 outcomes × 9-column blocks for both-subject)
- **Calls:** none.
- **Stata syntax:** `estimates use`, `estadd local`, `eststo`, `esttab ... rename() mtitles() mgroups()`, `#delimit ;`. Stata 12+.
- **ssc/community packages:** `estout` (`esttab`, `eststo`).
- **Path references:** all `$vaprojdir`.
- **Reference to paper outputs:** Paper **Table 4** (single-subject pass-through ρ) and a both-subject table.
- **Line-cited bugs / anomalies:**
  - **Inconsistent control list relative to file 2.** File 2 (L50) defines `b_sample_controls b bd`. File 4 (L46) defines `b_sample_controls b` only — drops `bd`. So distance-control specs are NOT loaded into the table. Likely an intentional table simplification, but it does mean some `.ster` files are produced by file 2 and never appear in any CSV (files 6 & 11 do consume them via figures).
  - **L46 vs L47.** File 4 uses `b a las` for `las_sample_controls` (L47), but file 2's `las_sample_controls b a ls las bd ad lsd lasd` (L51) is wider. So this table excludes `ls`, `bd`, `ad`, `lsd`, `lasd` variants.
  - **L208, L213, L289-298.** A "most saturated VA model" block is fully commented out — dead code (referenced in change-log L15-18 but disabled).
  - **Both-subject `esttab` placement (L304-311).** The `esttab` writing the "both subjects" table is placed AFTER the `foreach outcome` loop closes at L302. This means `eststo` accumulates models for ALL 3 outcomes (enr, enr_2year, enr_4year), and a SINGLE CSV at L306 contains all three outcomes stacked horizontally as 36 columns. The `mgroups_both_subjects` (L128-146) defines 9 group titles with pattern of 3 rows × 12 columns = 36 — matches design. Confirmed intentional, not a bug.
  - **Single-subject `esttab` placement (L218-224).** Inside the outer outcome loop (L158-229). Each outcome gets its own CSV file. Within each, `eststo` accumulates 24 models = 2 subjects × {b sample × b control × 4 + las sample × {b,a,las} × 4} = 2 × (4 + 12) = 32 if we count all controls × 2 subjects × 2 (matched/base 2nd stage) × 2 (peer/no peer). Actually: 2 (subjects) × 4 (sample-control combos: b/b, las/b, las/a, las/las) × 4 (peer × match: NoPeer base, NoPeer match, Peer base, Peer match) = 32 columns? But `mtitles` only declares 24. Need to verify `mtitles_mgroups` count.

    Looking at `mtitles` (L84-94): 6 lines × 4 names each = 24 names. `mgroups` (L96-107) has 6 group titles, pattern `1 0 0 0 1 0 0 0 1 0 0 0` repeated twice = 24 columns. So 24 columns total per CSV. With `b_sample_controls = b` (1 control) and `las_sample_controls = b a las` (3 controls), per subject we get (1 + 3) × 2 (peer) × 2 (match) = 16 models. Two subjects × 16 = 32. **This MISMATCHES** the 24-col `mtitles`. esttab will likely warn about column count, but won't error — extra columns will get default labels.

    **POSSIBLE BUG:** `mtitles` and `mgroups` were sized for an earlier (smaller) sample-controls list. Since the table is wider than the labels declare, the rightmost columns may render with default mtitles/mgroups.
  - **L221.** `rename(`renamelist')` — `renamelist` accumulates across all loop iterations. With `b las` × `b a las` × {peer, no peer} × 2 subjects = 24 entries. Each entry is a pair (`old_name`, `new_name`). All pairs map distinct VA variables to a common `va_<subject>` name. esttab then aggregates them into common rows.
  - **L227-228 inside outcome loop:** `eststo clear; macro drop _renamelist` resets state per outcome. Good.

---

## File 5 — `reg_out_va_dk_all_tab.do`

- **File:** `/Users/christinasun/github_repos/cde_va_project_fork/do_files/sbac/reg_out_va_dk_all_tab.do`
- **Lines:** 288
- **Purpose:** Construct CSV tables for DK VA pass-through and DK × prior-decile heterogeneity. Reads `.ster` files written by file 3.
- **Inputs:**
  - L157, L165: `reg_`outcome'_va_dk_`outcome'_`sample'_sp_`control'_ct`peer'(_m).ster`
  - L233: `het_reg_`outcome'_va_dk_`outcome'_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'.ster`
- **Helpers `include`'d:** L44: `$vaprojdir/do_files/sbac/macros_va.doh`
- **Outputs:**
  - L192: `$vaprojdir/tables/va_cfr_all_`version'/reg_out_va_dk/reg_out_va_dk.csv` (one CSV with all 3 outcomes stacked horizontally — 36 columns)
  - L254: `$vaprojdir/tables/va_cfr_all_`version'/reg_out_va_dk/het_reg_out_va_dk_x_prior_`prior_subject'.csv` (one per prior subject)
- **Calls:** none.
- **Stata syntax:** as file 4.
- **ssc/community packages:** `estout` family.
- **Path references:** `$vaprojdir`.
- **Reference to paper outputs:** Paper **Table 5** (DK VA pass-through) and DK heterogeneity tables (OA).
- **Line-cited bugs / anomalies:**
  - **L48-49.** `b_sample_controls b` and `las_sample_controls b las` — drops `ls` even though file 3 produces `ls` `.ster` files (L44). Inconsistency: those `ls` `.ster` files exist but are never read into a table. Likely intentional table simplification (matches file 4's pattern).
  - **L130-187 (main DK table).** The `foreach outcome` loop (L134) closes at L187. The `esttab` write at L190-197 is OUTSIDE that loop. So all 3 outcomes are stacked in a single 36-column CSV. Same intentional pattern as file 4's both-subjects block.
  - **L242 nested `forvalues i = 1/9` inside `forvalues i = 1/2` (L219).** `i` is shadowed. Stata `forvalues` re-initializes the iterator on each outer iteration, so this works in practice but is fragile and confusing. Should be renamed (e.g., `forvalues k = 1/9`).
  - **`renamelist` accumulation in heterogeneity block (L240-243).** Adds 1 (main rename) + 9 (decile rename) per outer-i iteration. With 2 peer × {b}∪{b las}=3 control combinations = 6 outer iterations per outcome and 3 outcomes = 18 outer iterations total per prior_subject. Final renamelist has 180 entries (intended).
  - **Comments only — no actual cluster-level deviation found in this file.** All `.ster` reads come from file 3, which always uses `cluster(school_id)`. So this file inherits correct clustering.
  - **L172, L185.** `va_dk_<outcome>` rename mapping — note the rename target `va_dk_`outcome'` includes the outcome name. So in the multi-outcome table, the rename target differs per outcome (e.g., `va_dk_enr` vs `va_dk_enr_2year`), which means each outcome's coefficient appears as a SEPARATE row in the final esttab output. With `mtitles` `depvars` option (L100), each model column shows its own dep var, and rows are the various `va_dk_<outcome>` variables. This is intentional layout.

---

## File 6 — `reg_out_va_all_fig.do`

- **File:** `/Users/christinasun/github_repos/cde_va_project_fork/do_files/sbac/reg_out_va_all_fig.do`
- **Lines:** 607
- **Purpose:** Generate heterogeneity bar plots: (a) coefficient × prior-score-decile (single-subject and both-subject); (b) coefficient × demographic char (race, male, econ_disadvantage, charter, inc_median_hh_xtile). Combine into 4-panel figures (b sample/base, b sample/base+peer-matched, las sample/las, las sample/las+peer-matched).
- **Inputs:**
  - L88, L94: single-subject base reg `.ster` (for yline reference scalar)
  - L103, L110: both-subject base reg `.ster`
  - L159: `het_reg_`outcome'_va_`subject'_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'`match'.ster`
  - L272: `het_reg_`outcome'_va_`subject'_x_`het_char'_`sample'_sp_`control'_ct`peer'`match'.ster`
  - L439: `het_reg_`outcome'_va_ela_math_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'`match'.ster`
- **Helpers `include`'d:** L51: `$vaprojdir/do_files/sbac/macros_va.doh`
- **Outputs (selected):**
  - L189: `$vaprojdir/figures/va_cfr_all_`version'/het_reg_prior_score/het_reg_`outcome'_va_`subject'_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'`match'.pdf`
  - L205: gph file for panel combination (same path tree under `gph_files/`)
  - L305, L321, L357, L374: `het_reg_chars/...` outputs (race, male, econ_disadv, charter, inc_median_hh_xtile)
  - L472: both-subject prior decile output
  - L536, L549, L568, L583: combined-panel PDFs under `het_reg_combined_panels/score_va/`
- **Calls:** none.
- **Stata syntax:** `est use`, `parmest, norestore`, `tempname`, `scalar`, `twoway (bar) (rcap)`, `graph combine`, `graph export`. Heavy use of factor-variable parameters parsing via `strpos` + `subinstr`.
- **ssc/community packages:** **`parmest`** (community-contributed).
- **Path references:** `$vaprojdir`.
- **Reference to paper outputs:** Paper **Figures 5-6** (heterogeneity by prior decile, both-subject) and **OA Figs C.1-C.2** (heterogeneity by student characteristics).
- **Line-cited bugs / anomalies:**
  - **CONFIRMED COMMENT/CODE MISMATCH (L172, L288, L453).** Comments state "twoway graph 1) bar graph of coefficient estimates 2) rcap for 90% CI" but the actual plotting variables are `min95 max95` (L177, L196, L293, L312, L344, L364, L459, L479) — `parmest` defaults emit 95% CI columns. Either the comment is wrong (most likely) or the code should use `min90 max90` (would require passing a 90% CI option to `parmest`). Currently the bars are 95% CI; comments claim 90%. **This is a documentation bug; the figure content is 95% CI.**
  - **CONFIRMED LOAD-DEPENDENT BUG (L159).** This file loads `het_reg_..._va_<subject>_x_prior_<prior_subject>_..._.ster` files. These files are produced ONLY when `local run_prior_score == 1` in file 2 (L235), but file 2 has it hardcoded to 0. **Therefore the single-subject prior-score heterogeneity figures (L189) cannot be re-generated from a clean run — they depend on stale `.ster` files left over from a prior run when the toggle was 1.** This is a build-reproducibility hazard.
  - **NESTED `forvalues i` SHADOWING.** L138 outer + L149 inner; L251 outer + L262 inner; L418 outer + L429 inner. The inner loop re-uses `i` and overwrites the outer `i`, but Stata's `forvalues` re-initializes the iterator each outer cycle, so behavior is correct. However it is fragile — should be renamed to `match_idx` etc. for clarity.
  - **L91, L96 scalar names.** `tempname` declares are placed inside loops over `subject` (L84) — meaning `tempname` would be redeclared every iteration. `tempname` is fine to repeat — Stata reuses the name. Storage of `_b[va_..._sp_..._ct`peer']` uses the regression's coefficient (not standardized — already z-scored at file 2 L74-78). Correct.
  - **L91-96 vs L106-113.** Single-subject scalars use suffixes `_m` and no suffix; both-subject scalars use `_b` and `_b_m`. The `_b` here means "both-subject" not "matched"; the `_m` means "matched 2nd-stage controls". Naming is internally consistent but confusing because `_m` could be read as "matched" or "minus" — fine, just non-obvious.
  - **L240-246 demographic char selection.** When sample == "las": `het_char_vars race male econ_disadvantage charter inc_median_hh_xtile`. Else: drops `inc_median_hh_xtile` (only available in las sample because it comes from ACS merge). Consistent with file 2 L279-285.
  - **L526-530 (combined panel filenames).** Specifies four `.gph` files: `b_sp_b_ct.gph`, `b_sp_b_ct_p_m.gph`, `las_sp_las_ct.gph`, `las_sp_las_ct_p_m.gph`. The naming `_p_m` means peer-VA + matched-2nd-stage-controls. `_ct.gph` (no peer, base controls) is shorthand for the `(no peer, base 2nd-stage)` panel. So the panels are: NoPeer-Base / Peer-Match for each of {b sample base controls, las sample las controls}. **Sensible asymmetric design**: the "showing" panels are the most parsimonious (b/b NoPeer-Base) and the most saturated (las/las Peer-Match).
  - **L568.** `het_reg_`outcome'_va_both_x_prior_x_prior_`prior_subject'_combined.pdf` — the substring `_x_prior_x_prior_` appears DOUBLED. **Filename TYPO bug** — should likely be `_x_prior_`prior_subject'_combined.pdf` (single `_x_prior_`). The companion at L583 (distance) does NOT have the doubled substring (`het_reg_distance_..._x_prior_..._combined.pdf`). Inconsistent and likely a copy-paste error at L568.
  - **L298 (xtitle).** `xtitle("``het_char'_str'")` for the income-decile figure — uses the string label from `macros_va.doh` `inc_median_hh_xtile_str` ("Census Tract Median Household Income Decile"). Correct.

---

## File 7 — `reg_out_va_dk_all_fig.do`

- **File:** `/Users/christinasun/github_repos/cde_va_project_fork/do_files/sbac/reg_out_va_dk_all_fig.do`
- **Lines:** 245
- **Purpose:** Generate DK-VA × prior-decile heterogeneity bar plots and combined panels. DK only (no demographic-char heterogeneity).
- **Inputs:**
  - L75, L81: non-het DK regs (for yline scalar)
  - L129: `het_reg_`outcome'_va_dk_`outcome'_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'`match'.ster`
- **Helpers `include`'d:** L41: `$vaprojdir/do_files/sbac/macros_va.doh`
- **Outputs:**
  - L154, L173: `$vaprojdir/figures/va_cfr_all_`version'/het_reg_dk_prior_score/het_reg_..._x_prior_...pdf` and `.gph`
  - L212: `$vaprojdir/figures/va_cfr_all_`version'/het_reg_combined_panels/dk_va/het_reg_..._combined.pdf`
- **Calls:** none.
- **Stata syntax:** `parmest`, `twoway`, `graph combine`. Same pattern as file 6.
- **ssc/community packages:** `parmest`.
- **Path references:** `$vaprojdir`.
- **Reference to paper outputs:** OA appendix DK-VA heterogeneity figures.
- **Line-cited bugs / anomalies:**
  - **`min95 max95` used (L141, L163)** — 95% CI bars (no commented "90% CI" claim here, unlike file 6).
  - **L144, L166 `yscale(range(0))`.** Forces 0 to be in y-axis range. Distinct from file 6 which omits this option. Different design choice for DK figures (likely because DK coefficients can be near zero or include 0).
  - **L148-150, L170-172.** `title()` and `subtitle()` are NOT commented out, unlike file 6 (which has them all commented). So the DK figures get on-graph titles, while the score figures do not. Inconsistency in figure styling.
  - **NESTED `forvalues i`** at L104 (outer) and L119 (inner) — same shadowing pattern as file 6. Same caveat.
  - **L46.** `las_sample_controls b ls las` — three control variants. File 5 (DK tab) at L49 only loads `b las` — so this fig file produces `ls` PDFs that are not in any DK table.
  - **L203-206 panel filenames.** `b_sp_b_ct`, `b_sp_b_ct_p_m`, `las_sp_las_ct`, `las_sp_las_ct_p_m`. Same pattern as file 6.
  - **No filename typo at L212** (no doubled substring).

---

## File 8 — `va_corr_schl_char.do`

- **File:** `/Users/christinasun/github_repos/cde_va_project_fork/do_files/va_het/va_corr_schl_char.do`
- **Lines:** 124
- **Purpose:** Run school-level regressions of VA on school characteristics (charter, locale_coarse, prop_ecn_disadv, enr_black_hisp_prop). One regression per VA variant × school-char.
- **Inputs:**
  - L46: `$vaprojdir/estimates/va_cfr_all_`version'/va_est_dta/va_all.dta`
  - L47: `$vaprojdir/data/sch_char_2018.dta`
- **Helpers `include`'d:**
  - L36: `$vaprojdir/do_files/sbac/macros_va.doh`
  - L37: `$vaprojdir/do_files/sbac/macros_va_all_samples_controls.doh`
- **Outputs:**
  - L88, L98: `$vaprojdir/estimates/va_cfr_all_`version'/va_het/va_`va_outcome'_het_`het_char'_`sample'_sp_`va_ctrl'_ct`peer'.ster`
- **Calls:** none.
- **Stata syntax:** `reg ... cluster(school_id)`. No factor-variable interactions — this is a *correlation* style regression, with VA on LHS, school-char on RHS.
- **ssc/community packages:** none.
- **Path references:** `$vaprojdir`.
- **Reference to paper outputs:** Possibly an OA table on VA's correlation with school characteristics. Superseded by `va_het.do` (file 10) which produces a combined `corr_char_*.tex` table.
- **Line-cited bugs / anomalies:**
  - **CONFIRMED FILENAME-VS-VARIABLE MISMATCH (L84, L88, L94, L98).** The regression's LHS uses `va_`va_outcome'_`sample'_sp_`va_ctrl'_ct` — note **no `peer` suffix in the variable name** (always `_ct`, never `_ct_p`). But the output `.ster` filename at L88, L98 uses `..._ct`peer'.ster` — **includes the `peer` suffix in the filename**. So:
    - When sample == "las" (L69-72: `peer = _p`, `peer_yn = Y`): the regression uses VA WITHOUT peer (`_ct` only), but saves to a file named `..._ct_p.ster`. **The filename's `_p` token claims peer-VA but the regression actually uses non-peer VA.**
    - When sample == "b": peer is empty, no mismatch.
  - The bug only fires for the `las` branch — and it would silently produce `.ster` files with misleading filenames. Downstream readers of these `.ster` files (none in chunk-4 — `va_corr_schl_char_fig.do` does NOT load `.ster` files; it does live correlations on the dataset) would be confused if they grepped by filename.
  - **L82-90 (categorical regressors).** `reg va_... i.charter`, etc. With clustering at `school_id` and only school-level RHS, the cluster has 1 obs per cluster on the RHS — clustering is trivially correct but reduces to robust SEs at school level.
  - **L93.** `di "continuous variables: `cont_het_char'"` — displays the LIST `prop_ecn_disadv enr_black_hisp_prop`, but inside loop variable is `het_char` (singular). Cosmetic.
  - **L20.** `log close _all` is missing the `cap` modifier — will error if no log open. Same in file 9 (L22), file 10 (L11).

---

## File 9 — `va_corr_schl_char_fig.do`

- **File:** `/Users/christinasun/github_repos/cde_va_project_fork/do_files/va_het/va_corr_schl_char_fig.do`
- **Lines:** 133
- **Purpose:** Generate scatter (binscatter) and kernel-density plots of VA vs school chars. Plots are from raw data, not from the regressions saved by file 8.
- **Inputs:**
  - L50: `$vaprojdir/estimates/va_cfr_all_`version'/va_est_dta/va_all.dta`
  - L51: `$vaprojdir/data/sch_char_2018.dta`
- **Helpers `include`'d:** L38, L39 (same as file 8).
- **Outputs:**
  - L81: `va_`va_outcome'_scatter_`het_char'_`sample'_sp_`va_ctrl'_ct`peer'.pdf`
  - L98: `va_`va_outcome'_density_locale_..._ct`peer'.pdf`
  - L108: `va_`va_outcome'_density_charter_..._ct`peer'.pdf`
- **Calls:** none.
- **Stata syntax:** `corr`, `binscatter`, `twoway kdensity`.
- **ssc/community packages:** **`binscatter`** (community-contributed).
- **Path references:** `$vaprojdir`.
- **Reference to paper outputs:** Possibly OA scatter/density figures (advisory, may not be in main paper).
- **Line-cited bugs / anomalies:**
  - **L74, L77, L90-93, L102-103.** This file uses `va_..._ct`peer'` consistently in BOTH the variable name AND the output filename. **No mismatch** — unlike file 8.
  - **L78.** `xtitle("``het_char'_str'")` — relies on `macros_va.doh` having a `*_str` defined for each `het_char`. `prop_ecn_disadv_str` is defined at macros_va.doh L558 ("Proportion Economically Disadvantaged"). `enr_black_hisp_prop_str` at L564. Good.
  - **L75.** `local cor_..._ct`peer': di %5.3f r(rho)` — captures correlation as a local. Used at L80 to embed in note. Correct.
  - **L94, L104.** `xtitle` vs `ytitle` — locale density uses `xtitle` (L94), charter density uses `ytitle` (L104). Inconsistency — for kernel-density on a single variable, the X-axis is usually the variable being kdensity'd. L94 has `xtitle("``va_outcome'_str' VA")` — correct for kdensity. L104 has `ytitle("``va_outcome'_str' VA")` — **inverted**, since kdensity puts the variable on the X-axis. The Y-axis of kdensity is "density" by default. So L104 mislabels the Y-axis as "VA". **Plot-label bug.**

---

## File 10 — `va_het.do`

- **File:** `/Users/christinasun/github_repos/cde_va_project_fork/do_files/va_het/va_het.do`
- **Lines:** 235
- **Purpose:** Two analyses producing paper Table 7 (variance decomposition) and a paper-table for VA correlation with school characteristics:
  1. **Variance decomposition:** fraction of VA variance that is across-district. Uses `areg ... absorb(district)` and reads R² as the across-district share.
  2. **Correlation table:** OLS regression of VA on each school characteristic (with weights), saving coefficients/SE table.
  Both are done for two specs (`las_sp_b_ct`, `las_sp_las_ct_p`) × weighted/unweighted × v1/v2.
- **Inputs:**
  - L31: `$vaprojdir/estimates/va_cfr_all_`version'/va_est_dta/va_all.dta`
  - L32: `$vaprojdir/data/sch_char.dta`
  - L73: `$vaprojdir/estimates/va_cfr_all_`version'/va_est_dta/va_all_schl_char.dta` (created at L73 then re-loaded multiple times)
- **Helpers `include`'d:** L25: `$vaprojdir/do_files/sbac/macros_va.doh`
- **Outputs:**
  - L73: `$vaprojdir/estimates/va_cfr_all_`version'/va_est_dta/va_all_schl_char.dta`
  - L93: `$vaprojdir/estimates/va_cfr_all_`version'/va_het/district_`district_type'_`spec'_`w_str'.dta` (per outcome)
  - L137-138: `$vaprojdir/tables/share/va/{check,pub}/va_het/var_across_district_`w_str'_`version'.tex` (paper Table 7)
  - L160: `$vaprojdir/estimates/va_cfr_all_`version'/va_het/corr_`char'_va_`spec'_`w_str'.dta`
  - L218-219: `$vaprojdir/tables/share/va/{check,pub}/va_het/corr_char_`w_str'_`version'.tex`
- **Calls:** none.
- **Stata syntax:** `areg ... absorb(district)`, `regsave ... table(...)`, `texsave`, `insobs`, `tempfile`. `gen district = substr(cdscode, 3, 5)` (district = chars 3-7 of cdscode).
- **ssc/community packages:** **`regsave`**, **`texsave`** (both community-contributed).
- **Path references:** `$vaprojdir`. Outputs to `$vaprojdir/tables/share/va/...` (this is the paper-mirroring output tree).
- **Reference to paper outputs:** Paper **Table 7** (variance decomposition: "Fraction of VA variance that is across-district") and an OA / appendix table on VA-vs-school-char correlations.
- **Line-cited bugs / anomalies:**
  - **CONFIRMED CLUSTER-LEVEL DEVIATION (L158).** This is the **only** regression in chunk-4 that uses `cluster(cdscode)` instead of `cluster(school_id)`. Every other regression in files 1-11 uses `cluster(school_id)`. Whether `cdscode` and `school_id` are 1-to-1 in this dataset depends on the merge/dataset structure. Since each cdscode = one California school (CDS code is a unique school code in CA), and `school_id` typically maps to cdscode, they may be effectively identical clustering. **But the inconsistency in the code is real and should be reviewed.** If they are not 1:1, the clustering would differ.
  - **CONFIRMED gr5 DEAD CODE (L66, L102).** L66 creates `gen gr5 = (numsch >= 5)`. The label-replacement at L102 has `if "`district_type'" == "gr5" replace var = "At least 5 schools..."`. But the `district_type` loop at L86 only iterates over `gr2 top25` — `gr5` is never used. Dead branch.
  - **CONFIRMED hlines TYPO (L214).** `hlines(1 3  5 11 13 13 14 16 18 24)` — `13` appears twice. Likely a typo; the intended sequence is probably `1 3 5 11 13 14 16 18 24`. Effect on rendered TeX is benign (drawing two `\hline` at the same row is a no-op in LaTeX).
  - **L42-49.** Imputation of school chars by cdscode mean (`egen temp=mean(`var'), by(cdscode); replace `var'=temp if `var'==.`). Done for `charter fte_pupil_pc fte_teach_pc new_teacher_prop`. `enr_black_hisp_prop`, `prop_ecn_disadv`, `locale_coarse`, `logenroll` are summarized but NOT imputed — they're treated as already complete or missing-handled by drop-in regression.
  - **L53.** `gen district = substr(cdscode, 3, 5)` — extracts characters 3-7 (i.e., 5 characters starting at position 3). For California cdscodes (14-digit format `CC-DDDDD-SSSSSSS`), characters 3-7 are the district code. Correct.
  - **L56 `have_test_lr` filter.** Hardcoded to `year==2018`, hardcoded VA spec (`las_sp_las_ct_p`). Anyone running the file on a different sample year would need to edit the hardcode.
  - **L92.** `areg va_`outcome'_`spec' `wt' if `district_type' == 1 & year == 2018, absorb(district)` — note **no `cluster()` on this regression** — uses default `areg` SE (heteroskedastic-robust if `, vce(robust)` were specified, but here it's the default OLS SE). The Table 7 reads R², so the SE doesn't matter for the published number, but the coefficient table emitted by `regsave` (L93) will have OLS SE (not clustered). Since only R² is kept (L100), this doesn't affect the published table.
  - **L101-103.** `replace var` chain to relabel rows. Note `gr5` branch (L102) is unreachable since loop omits gr5.
  - **L75-83 weight macros.** `wt = "[w = enr_total]"` for w==1 (school-enrollment-weighted regressions). Standard. Wt naming `wt`/`nw` — answers Q4: `_wt` and `_nw` ARE used here as filename tokens encoding weighted vs unweighted; defined L78, L82.
  - **L75-83.** Note: outer loop variable is `w` (0 or 1) and string is `w_str` (nw or wt). Consistent.
  - **L168-169.** `if "`char'"!="locale_coarse"  keep if _n<=2` and `if "`char'"=="locale_coarse"  keep if _n<=6` — keeps coef + SE rows only. For locale_coarse (3 dummies = suburb/town/rural), 6 rows = 3 coef + 3 SE. Correct.
  - **L189-194 tempfile assembly.** Builds two tempfiles `het_las_sp_b_ct` and `het_las_sp_las_ct_p` then combines (L202-203).

---

## File 11 — `persist_het_student_char_fig.do`

- **File:** `/Users/christinasun/github_repos/cde_va_project_fork/do_files/va_het/persist_het_student_char_fig.do`
- **Lines:** 67
- **Purpose:** Combine four already-existing `.gph` files (income decile / race / male / econ_disadvantage, all for `_va_math_x_..._las_sp_lasd_ct_p_m`) into a 2×2 panel figure. Individual `.gph` files are produced by `reg_out_va_all_fig.do` (file 6).
- **Inputs:**
  - L43-47: four `.gph` files under `$vaprojdir/gph_files/va_cfr_all_`version'/het_reg_chars/het_reg_`outcome'_va_math_x_<char>_las_sp_lasd_ct_p_m.gph`
- **Helpers `include`'d:** L33: `$vaprojdir/do_files/sbac/macros_va.doh`
- **Outputs:**
  - L52: `$vaprojdir/figures/va_cfr_all_`version'/het_reg_combined_panels/student_char/het_reg_distance_`outcome'_va_math_x_student_char_combined.pdf`
- **Calls:** none.
- **Stata syntax:** `graph combine`.
- **ssc/community packages:** none.
- **Path references:** `$vaprojdir`.
- **Reference to paper outputs:** **OA Figs C.1-C.2** (heterogeneity of math VA by student characteristics, distance-controls spec, with peer + matched 2nd-stage controls).
- **Line-cited bugs / anomalies:**
  - **L40 outcome scope.** Loops only over `enr_2year enr_4year` — does NOT include `enr` (overall enrollment). So this combined panel exists only for 2-year and 4-year outcomes. Likely intentional (paper figs focus on these).
  - **L45 commented out.** `charter_..._gph` line is commented out per change-log L16 ("08/15/2024: remove charter"). So the panel is 4-cell (income, race, male, econ_disadv) not 5-cell. This means `cols(2)` (L48) gives a 2×2 layout — clean.
  - **L52 output filename `het_reg_distance_..._va_math_x_student_char_combined.pdf`.** "distance" prefix indicates distance-control spec (matches the `lasd` token in the input gph names). Consistent.
  - **L34-37 xlabel locals are defined but unused** in this file (L43-47 only do `graph combine` of pre-built `.gph` files). The xlabels were applied earlier in file 6 when the individual `.gph` files were saved. Dead code (harmless).
  - **L20.** `cap log close _all` — uses `cap` (good defensive coding, unlike files 8-10).
  - **Subject hardcoded to `math`** (L43-47). No `ela` variant of this combined panel — design choice.

---

## Helpers — `macros_va.doh` and `macros_va_all_samples_controls.doh`

- **`macros_va.doh`:** 612 lines. Defines:
  - `b_controls`, `peer_b_controls` (base + peer base controls used in regressions)
  - `b_spec_controls` ... `lasd_spec_controls` (matched-spec controls for `_m` regressions; built up from atomic `school_controls`, `demographic_controls`, `ela_score_controls`, `math_score_controls`, `census_controls`, `sibling_controls`, `d_controls`).
  - String labels: `b_str` "base", `l_str` "leave out score", `a_str` "ACS", `s_str` "sibling", `d_str` "postsecondary distance", `las_str` "leave out score & ACS & sibling", and combinations.
  - Outcome strings: `enr_str`, `enr_2year_str`, `enr_4year_str`.
  - Heterogeneity-string labels: `race_str`, `male_str`, `econ_disadvantage_str`, `charter_str`, `inc_median_hh_xtile_str`, etc.
  - **Naming convention codified at L4-13:** `b base / l loscore / a acs / s sibling / la loscore+acs / ls loscore+sibling / as acs+sibling / las loscore+acs+sibling`. Distance suffix `d` (`bd`, `lsd`, `lasd`, etc.) added at L14.
  - **Confirms Q4 partially:** `_m` is a filename suffix denoting "matched" 2nd-stage controls (i.e., the regression includes the same controls as the VA estimation). Not defined here as a string — defined by usage in files 2 and 3 (`_m.ster` files when `peer != ""` add peer controls also).
- **`macros_va_all_samples_controls.doh`:** 144 lines. Defines per-control sample-restriction lists (`b_ctrl_samples`, `l_ctrl_samples`, etc.) for VA estimation loops AND forecast-bias loops. Used only by files 8 and 9 — not by files 2, 3, 4, 5, 6, 7, 10, 11.

---

## Synthesis — Answers to specific questions

### Q1. Pass-through ρ regression (paper Tables 4-5)

**Single-subject score VA (Table 4) — file 2 (`reg_out_va_all.do`) L137-149:**

```
reg `outcome' va_`subject'_`sample'_sp_`control'_ct`peer' i.year `b_controls', cluster(school_id)
```

**Match-controls variant (`_m` files) — file 2 L147-149 / L160-163:**

```
reg `outcome' va_`subject'_`sample'_sp_`control'_ct`peer' i.year ``control'_spec_controls' [`peer_`control'_controls'], cluster(school_id)
```

- LHS: postsecondary outcome (enr / enr_2year / enr_4year) — student-level binary
- RHS: standardized (z-score) VA estimate (1 variable for single-subject; 2 for both-subject)
- Year FE (`i.year`)
- Base controls = `school_controls + demographic_controls + ela_score_controls + math_score_controls` (from `macros_va.doh` L208-213)
- For `_m` runs, additionally controls match VA-estimation spec (e.g., `las_spec_controls` adds loscore + census + sibling; `_p` peer adds peer-equivalent controls)
- **Cluster: `school_id`** (every regression in files 2 & 3)

**DK VA (Table 5, OA) — file 3 (`reg_out_va_dk_all.do`) L104-106:**

```
reg `outcome' va_dk_`outcome'_`sample'_sp_`control'_ct`peer' i.year `b_controls', cluster(school_id)
```

LHS = RHS outcome (DK VA matches outcome by definition).

### Q2. Heterogeneity by prior-decile (paper Figs 5-6) regression

**Both-subject case (figs 5-6) — file 2 L331-335:**

```
reg `outcome' c.va_ela_..._sp_..._ct`peer'#i.prior_`prior_subject'_z_score_xtile c.va_math_..._sp_..._ct`peer'#i.prior_..._xtile i.year `b_controls', cluster(school_id)
```

- VA × prior-decile interaction is `c.va#i.prior_xtile`
- Outputs decile-specific ATT-like coefficients
- `parmest, norestore` (file 6 L162) extracts per-decile coefficient + 95% CI for plotting
- Cluster: `school_id`

**Single-subject prior-decile case — file 2 L242-244 — IS GATED OFF (L235 `local run_prior_score = 0`).**

### Q3. Heterogeneity by student-char (OA Figs C.1-C.2) regression

**File 2 L291-294:**

```
reg `outcome' c.va_`subject'_..._ct`peer'#i.`het_char' i.year `b_controls', cluster(school_id)
```

- Het char ∈ `{race, male, econ_disadvantage, charter, inc_median_hh_xtile}` (last only when sample == las)
- Cluster: `school_id`
- Plotted by file 6 with bars per category + 95% CI rcaps

### Q4. Naming-token resolution (`_m`, `_wt`, `_nw`)

- **`_m`** = "matched" 2nd-stage controls. The pass-through regression's controls match the VA-estimation specification (e.g., for `las_sp_las_ct`: VA was estimated with loscore+ACS+sibling controls, and the `_m` 2nd-stage adds those same controls). Used by files 2, 3, 4, 5, 6, 7, 11.
- **`_wt`** / **`_nw`** = "weighted" / "not weighted" (school-enrollment-weighted vs unweighted). Used **only in file 10** (`va_het.do` L78, L82). Output filenames embed `_wt_v1.tex`, `_nw_v1.tex` etc.
- These tokens do NOT appear in files 1-9 or 11.
- **`_p`** = peer-controls included in the VA estimation (file 6, file 2, etc.). Defined in files via `if i==2 { local peer _p }`.
- **`_lv`** (leave-out): NOT found in any chunk-4 file.

### Q5. SE clustering audit

| File | Regression cluster level |
|------|---------------------------|
| File 1 | (no regressions; just `xtile` and `collapse`) |
| File 2 | `cluster(school_id)` × all 9 reg invocations (L139, L149, L163, L191, L202, L215, L244, L255, L265, L294, L305, L315, L335, L346, L357) |
| File 3 | `cluster(school_id)` × all 6 reg invocations (L106, L116, L125, L143, L153, L163) |
| File 4 | (no regressions) |
| File 5 | (no regressions) |
| File 6 | (no regressions) |
| File 7 | (no regressions) |
| File 8 | `cluster(school_id)` × 2 (L85, L95) |
| File 9 | (no regressions; `corr` + `binscatter` only) |
| File 10 | **`cluster(cdscode)`** at L158. **`areg ... absorb(district)`** at L92 (no cluster — default OLS SE) |
| File 11 | (no regressions) |

**ANOMALY: file 10 L158 uses `cluster(cdscode)`** — the only deviation from `cluster(school_id)` in chunk-4. If `cdscode == school_id` 1:1 (likely true since CA `cdscode` is the unique school identifier), the cluster is functionally identical. But the inconsistency is a code-style flag.

L92 `areg ... absorb(district), [no cluster()]` uses OLS SE — only R² is consumed downstream (Table 7), so SE-method for L92 doesn't propagate to a published number.

### Q6. Variance-decomposition table (paper Table 7)

File 10 `va_het.do`, output at L137-138:

```
$vaprojdir/tables/share/va/{check,pub}/va_het/var_across_district_`w_str'_`version'.tex
```

with title (L134) **"Fraction of VA variance that is across-district"**. Spec is `areg va_<outcome>_<spec> [w=enr_total] if district_type==1 & year==2018, absorb(district)` (L92), where `district_type` ∈ {gr2, top25} and `spec` ∈ {las_sp_b_ct, las_sp_las_ct_p}. The published value is `r2`, kept at L100. Two panels (Panel A: base controls; Panel B: full controls), 2 district-restriction rows per panel.

### Q7. `va_corr_schl_char.do` vs `va_het.do` — redundancy

- **`va_corr_schl_char.do` (file 8):** older. Runs ONE regression per (VA outcome, sample, control, het_char) writing one `.ster` per combination. Loops over `va_outcome ∈ {ela, math, enr, enr_2year, enr_4year}`, sample ∈ {b, las}. Output naming uses `_ct`peer'.ster` filename suffix but uses non-peer VA in regression (the BUG noted above for the `las` branch).
- **`va_het.do` (file 10):** newer (created 2024-06-28 per L7). Produces consolidated TWO TABLES (Table 7 + correlation table) by running `regsave ... table(...)` and combining via `texsave`. Restricted to outcomes `ela math enr_2year enr_4year` (no `enr` overall) and to specs `las_sp_b_ct las_sp_las_ct_p`.
- **Relationship:** `va_het.do` SUPERSEDES `va_corr_schl_char.do` for the published correlation table. The older file still produces `.ster` files but those are not consumed by `va_het.do`. The companion fig file (`va_corr_schl_char_fig.do`) does not load `.ster` from file 8 either — it generates plots from the raw merged dataset. **`va_corr_schl_char.do` is orphaned in the publication pipeline.**

### Q8. Local-toggle gates

| File | Line | Gate | Effect |
|------|------|------|--------|
| File 2 | L235 | `local run_prior_score = 0` | **Disables single-subject × prior-decile heterogeneity regressions** — so paper Figs 5-6 single-subject panels and OA single-subject prior-decile figures cannot be regenerated cleanly without flipping this to 1. |

No other local-toggle gates found.

---

## Cross-cutting bugs and anomalies (summary)

| # | File | Line(s) | Severity | Issue |
|---|------|---------|----------|-------|
| 1 | File 1 | L106 | BUG | `xtile inc_mean_hh_xtile = inc_median_hh, n(10)` — name claims "mean", source is "median". Variable is duplicate of L105. |
| 2 | File 2 | L235 | MAJOR (load-bearing toggle) | `local run_prior_score = 0` disables single-subject prior-decile het regressions. File 6 L159 will fail to find these `.ster` files on a clean run. |
| 3 | File 6 | L172, L288, L453 | DOC bug | Comments say "rcap for 90% CI" but vars used are `min95 max95` from `parmest` defaults (95% CI). The figure content is 95% CI; the comment is wrong. |
| 4 | File 6 | L568 | FILENAME typo | `het_reg_..._va_both_x_prior_x_prior_..._combined.pdf` — `_x_prior_` doubled; companion at L583 is correctly single. |
| 5 | File 8 | L84 vs L88, L94 vs L98 | BUG (filename mislabel) | Regression uses non-peer VA (`_ct`) but saves under filename with `peer` suffix (`_ct_p.ster`) when sample == las. Misleading filename. |
| 6 | File 9 | L104 | PLOT-LABEL bug | `ytitle("``va_outcome'_str' VA")` on a kdensity plot — kdensity's Y-axis is density, not VA. Should be `xtitle`. |
| 7 | File 10 | L158 | INCONSISTENCY | `cluster(cdscode)` — only chunk-4 reg using non-`school_id` cluster. May be functionally equivalent (cdscode = school_id 1:1 in CA), but inconsistent code. |
| 8 | File 10 | L66, L102 | DEAD CODE | `gr5` indicator created and labeled but loop at L86 omits it. |
| 9 | File 10 | L214 | TYPO | `hlines(1 3 5 11 13 13 14 16 18 24)` — `13` duplicated. Benign in TeX. |
| 10 | File 4 | L46 vs File 2 L50 | INCONSISTENCY | File 4 omits `bd` from `b_sample_controls` and `ad lsd lasd` etc. from `las_sample_controls`. Some `.ster` produced by file 2 are never read by tables. |
| 11 | File 5 | L49 vs File 3 L44 | INCONSISTENCY | File 5 omits `ls` from `las_sample_controls`. DK `ls` `.ster` files are produced but never tabled. |
| 12 | File 5 | L242 | SHADOW | Nested `forvalues i = 1/9` inside `forvalues i = 1/2`. Stata `forvalues` resets per-iteration, so it works but is fragile. |
| 13 | File 6 | L138/L149, L251/L262, L418/L429 | SHADOW | Same nested `forvalues i` pattern as file 5. Same caveat. |
| 14 | File 6 | L177 (24-col mtitles vs 32-col actual) | POSSIBLE-BUG | `mtitles` in file 4 declares 24 columns; actual eststo accumulates 32 (2 subjects × 16 sample-ctrl-peer-match). esttab will likely produce extra unlabeled columns. **Verify by counting actual CSV output.** |
| 15 | Files 8, 9, 10 | L20, L22, L11 | STYLE | `log close _all` without `cap` — errors if no log open. |

---

## Open questions (could not resolve from chunk-4 alone)

1. Is `cdscode == school_id` strictly 1-to-1 in `va_all.dta` and the merged dataset of file 10? If yes, the file 10 L158 cluster anomaly is cosmetic. If no, the SEs in the published correlation table differ from every other regression.
2. Are the `.ster` files for the single-subject prior-decile heterogeneity (file 2 L247, L258, L268) currently present in `$vaprojdir/estimates/...`? If yes, they are stale (from when `run_prior_score == 1`) and may not match the current data version.
3. For file 4's "32 columns vs 24 mtitles" mismatch: does esttab silently produce un-labeled columns, or does it error? The CSV at `$vaprojdir/tables/.../reg_`outcome'_va.csv` would resolve this.
4. The output dataset of file 1 (`prior_decile_original_sample.dta`) has student-level prior deciles AT THE COLLAPSE level — but the file does `collapse (mean) prior_*_xtile (max) race male econ_disadvantage`. If a student had multiple decile assignments (e.g., crossing waves), their final value is NON-INTEGER, which would break `i.prior_..._xtile` factor-variable use in regressions. Worth confirming the input `out_b.dta` has 1 row per student per year.
5. Whether the single-subject heterogeneity-by-prior-decile is a blocking dependency for paper Figs 5-6, or whether the paper uses only the both-subject panel (which is NOT gated). The figure file (file 6) produces both single- and both-subject panels and combined panels — the paper might use only one variant.

---

## Adversarial check — claims that look suspicious but are NOT bugs

- **L74-78 of file 2 (re-z-scoring inside subject loop):** Looks like double-standardization. After ELA merge, all `va_*` vars are z-scored. After Math merge, they get z-scored again. Z-score is idempotent (mean ≈ 0, sd ≈ 1 already), so the re-application produces no change beyond floating-point noise. **Not a bug**, just inefficient.
- **Nested `forvalues i` (files 5, 6, 7):** Stata's `forvalues` does reset the iterator on each outer cycle independently. The inner overwrite of `i` is harmless under standard Stata semantics. **Confusing, not broken.**
- **File 10 L75-76 (`if w==0 panel_a/panel_b same as if w==1`):** L120-126 — both branches write the same panel titles. Redundant but not wrong; at most a missed opportunity to differentiate.
- **File 11 L34-37 xlabel locals unused:** They were copy-pasted from file 6 but the actual labels are baked into the `.gph` files at save time. Harmless dead code.
- **L82 missing `nogen` in file 2:** Leaves `_merge` in dataset, but the next `merge ... nogen` works fine because Stata's merge auto-detects and replaces `_merge`. So actually — the L82 `merge` will fail when the next merge tries to create a fresh `_merge`! Wait — let me re-check. Actually `merge` will refuse to add `_merge` if it already exists; the program would error with "variable _merge already defined". So either Stata silently overwrites (newer versions do, with a warning) or this was masked by `nogen` on subsequent merges. In Stata 14+ this IS handled gracefully (auto-replace with warning). So L82 missing `nogen` is technically OK in modern Stata but flag-worthy.

---

## Verification checklist for downstream

- [ ] Check whether the gate at File 2 L235 was historically toggled. Search for any commit / log artifact showing `run_prior_score = 1` was set in a prior run.
- [ ] Resolve the cdscode-vs-school_id 1:1 question.
- [ ] Verify File 1 L106 `inc_mean_hh_xtile` semantics — should likely use `inc_mean_hh` source.
- [ ] Check rendered file at `$vaprojdir/tables/.../reg_enr_va.csv` for column count vs declared `mtitles`.
- [ ] Check file 6 L568 output filename for the `_x_prior_x_prior_` doubled token — confirm whether the produced PDF actually has that name in `$vaprojdir/figures/...`.
- [ ] Confirm whether file 8's `va_corr_schl_char.do` `.ster` outputs are still used anywhere (I found no consumer in chunk-4).
