# Chunk 9 Audit: SHARE / OUTPUT HELPERS + EXPLORE (predicted-prior-score)

**Scope:** 13 files in `cde_va_project_fork/do_files/share/` (including `share/check/`) and `cde_va_project_fork/do_files/explore/`.

**Note on path:** all files actually live at `/Users/christinasun/github_repos/cde_va_project_fork/do_files/...` (sibling repo, NOT inside `va_consolidated/`).

---

## Per-file entries

### File: `cde_va_project_fork/do_files/share/base_sum_stats_tab.do`

- **Owner**: Christina Sun (created 02/20/2023; updated 06/14/2023, 07/19/2023).
- **Pipeline phase**: share — produces paper Table 1.
- **Lines**: 590.
- **Purpose**: builds summary-statistics estimate files (`estpost sum`) for the 11th-grade ELA / Math / postsec-enrollment samples and three sample-restriction tiers (VA sample, dropped, combined, kitchen-sink/`las`), then renders **paper Table 1 Panel A** (`sum_stats_g11.tex`) and **Panel B** (`sum_stats_college.tex`).
- **Loop structure**: linear top-to-bottom. Two halves: (1) `create_sample` block (gated `if create_sample==1`) that re-builds `data/va_samples_v1/base_nodrop.dta` from raw merges, including reshapes from `k12_test_scores_clean.dta`, lag/peer scores, school-grade spans, cohort sizes, conventional schools, and postsec outcomes via `merge_k12_postsecondary.doh`; (2) the load-and-tabulate path that uses the saved `base_nodrop.dta`. The header pre-loops are `estpost sum` calls per sample × subject; the rendering block uses `est use` + `eststo` then a sequence of `esttab ... append` blocks per row group.
- **Inputs**:
  - `data/va_samples_v1/base_nodrop.dta` (the load-only path; line 182).
  - In the `create_sample==1` build: `k12_test_scores_clean.dta`, `data/sbac/va_samples.dta`, `k12_lag_test_scores_clean.dta`, `k12_peer_test_scores_clean.dta`, `k12_diff_school_prop_schyr.dta`, `k12_cohort_size_sch.dta`, `k12_public_schools_clean.dta`, `data/va_samples_v1/score_las.dta`.
  - Helper macros: `do_files/sbac/macros_va.doh`, `do_files/sbac/drift_limit.doh`, `do_files/sbac/create_diff_school_prop.doh`, `do_files/sbac/create_prior_scores_v1.doh`, `do_files/merge_k12_postsecondary.doh enr_only`.
- **Outputs (.ster)**:
  - `estimates/va_cfr_all_v1/sum_stats/sum_stats_g11_ela.ster`, `..._dropped.ster`, `..._all.ster`, `..._las.ster`.
  - Same five suffixes for `_g11_math` and for `_g11_ela_college`.
- **Outputs (.tex)** — paper Table 1:
  - `tables/share/va/pub/sum_stats_g11.tex` (Panel A; built with five `esttab ... append` calls).
  - `tables/share/va/pub/sum_stats_college.tex` (Panel B).
  - These are the producers for paper Table 1 (`tab:sum-stats`). **CRITICAL paper-map entry resolved.**
- **Filename naming pattern**: `sum_stats_g11_<subject>{_dropped|_all|_las}.ster`; output `.tex` files are the paper-table fragments.
- **Statistical specification**: descriptive only — `estpost sum` (mean) over `cohort_size`, `va_control_vars`, `eth_white`, subject z-score, prior ELA/Math z-scores, peer demographic + peer prior z-scores. Three sample tiers per subject: VA sample (`touse_g11_<subject>==1`), dropped (`==0 & all_students_sample==1`), combined.
- **Sourced helpers / Calls**: `macros_va.doh` (`va_control_vars`, `peer_demographic_controls`); `drift_limit.doh` (although not used here, included by habit); `merge_k12_postsecondary.doh enr_only` for postsec outcomes.
- **Path references**: writes to `tables/share/va/pub/` (the publication target). The corresponding paper section is `paper/sections/data.tex` / `paper/main.tex` `\input{}`'d (via the `va_paper_clone` repo per chunk 8).
- **ssc/community packages**: `estout`/`esttab` (`estpost sum`).
- **Gotchas / bugs**:
  - **Hard-coded `data/va_samples_v1/base_nodrop.dta` path** (line 177 / 182) — the rebuild block writes to and reads from `_v1` only; there's no `_v2` parallel build.
  - The rebuild block uses local `k12_test_scores`, `k12_test_scores_public`, `k12_public_schools`, `sibling_out_xwalk` — none defined in this file; presumably set in the user's session (in `settings.do` or before this is called). Running this standalone breaks unless those paths exist.
  - `set tracedepth 1` / `set trace on` are NOT used here — but they ARE in `va_var_explain.do` and `va_var_explain_tab.do` and never turned off, polluting the log.
  - Line 119 invokes `merge_k12_postsecondary.doh` with `enr_only` argument both inside and outside the `create_sample==0` branch (line 324) — meaning if the user takes the load-only path, postsec is merged again on top of an already-merged `base_nodrop.dta`. Probably harmless because `merge` checks (1 3) but worth confirming.
  - Multi-line `esttab` blocks at lines 463–579 reuse the same target file with `replace`/`append` — fragile; if any single block fails, the file is left in inconsistent state.
  - **CONFIRMED PAPER MAP**: this file produces both `sum_stats_g11.tex` and `sum_stats_college.tex`. The third column in each `esttab` is the kitchen-sink (`las`) sample; this matches the paper's Panel A / Panel B columns.
- **Reference to paper outputs**: paper Table 1 (`tab:sum-stats`).

---

### File: `cde_va_project_fork/do_files/share/sample_counts_tab.do`

- **Owner**: Christina Sun (03/02/2023).
- **Pipeline phase**: share — produces paper Appendix Table A.1.
- **Lines**: 644.
- **Purpose**: builds the **sample-counts cascade** showing N students remaining after each successive sample-restriction step (12 lines: all students → 9–12 schools → first scores → conventional → cohort > 10 → nonmissing test → nonmissing demos → nonmissing priors → school VA size ≥ 7 → +loscore → +sib → +ACS), with mean z-score on each step.
- **Loop structure**: outer loop over `subject in {ela, math}` for the `estpost tabstat` cascade; second outer loop over `sample` (12 names) × `subject` for the table assembly, building a 4-column wide block (count_ela, mean_z_ela, count_math, mean_z_math).
- **Inputs**:
  - `data/va_samples_v1/base_nodrop.dta` (line 39 — same SSOT as `base_sum_stats_tab.do`).
  - `k12_lag_test_scores_clean.dta` (for `L4_cst_ela_z_score`, `L5_cst_ela_z_score` to construct `loscore`).
  - `sibling_out_xwalk` (for `has_older_sibling_enr_2year`, `has_older_sibling_enr_4year`, `sibling_out_sample`).
  - `data/va_samples_v1/score_a.dta` (for `census_controls_sample`).
- **Outputs (.ster)**: 12 sample-stage `.ster` files for counts and 12 for z-scores, per subject (24 + 24 = 48 estimate files):
  - `counts_k12_<sample>_g11_<subject>.ster` and `z_score_k12_<sample>_g11_<subject>.ster`.
- **Outputs (.tex)** — paper Appendix Table A.1:
  - `tables/share/va/pub/counts_k12.tex` (lines 614–622). **CRITICAL paper-map entry resolved.**
- **Filename naming pattern**: `<stat>_k12_<sample-stage>_g11_<subject>.ster` where `<sample-stage>` ∈ `{all, if_school_level, first_scores, conventional_school, cohort_size, cst_z_score, demographic_controls, prior_cst_z_score, valid_cohort_size, loscore, loscore_sib, loscore_sib_acs}`.
- **Statistical specification**: cumulative `if`-based tabulations with `estpost tabstat ..., stat(n) columns(statistics)` for counts, `stat(mean sd)` for z-scores. Each line adds an additional `&` filter to the prior.
- **Sourced helpers / Calls**: `macros_va.doh`, `drift_limit.doh`.
- **Path references**: `tables/share/va/pub/counts_k12.tex` is referenced in the paper map as Table A.1 (`tab:sample-counts`).
- **ssc/community packages**: `estout`/`esttab` for the final `cells(mat_stat ...)` rendering.
- **Gotchas / bugs**:
  - **Cascade ordering** is hard-coded twelve times (lines 88–382 and again 387–561). Mismatched filters between count and z-score blocks would silently produce wrong rows. Sample-restriction map from chunk 8 should be cross-referenced — this file is the canonical encoding of "which restrictions in which order."
  - Lines 597–611 declare `local label_<sample>` strings for the row labels, including `+ Conventional School`, `+ 11th Graders per School > 10`, etc. These are read inside `coeflabel(x "<label>")` via macro expansion.
  - Tracks the **chunk 8 finding** that `_archive/matt_original/sum_stats_tab.do` produced an OLDER variant (`counts_k12.tex`); this file (`share/sample_counts_tab.do`) is the modern Christina-authored producer.
- **Reference to paper outputs**: paper Appendix Table A.1 (`tab:sample-counts`).

---

### File: `cde_va_project_fork/do_files/share/va_spec_fb_tab_all.do`

- **Owner**: Christina Sun (03/01/2023).
- **Pipeline phase**: share — produces paper Tables 2 + 3.
- **Lines**: 278.
- **Purpose**: combines specification-test results and forecast-bias-test results from chunk 3 into stacked tables for ELA, Math, 2-yr enrollment, 4-yr enrollment, then stacks them by score (ELA + Math, paper Table 2) and outcome (2yr + 4yr, paper Table 3).
- **Loop structure**: outer `version in {v1, v2}` × middle `va_outcome in {ela, math, enr_2year, enr_4year}`. Inner: load FB `.dta`, build column code 1–6 by `va_sample`/`va_control`/`peer_controls`, reshape coef/stderr/F-stat into row × column matrix; same for spec-test `.dta`; append; `texsave`.
- **Inputs**:
  - `tables/va_cfr_all_<v1|v2>/fb_test/fb_<va_outcome>_all.dta` (output of chunk 3 `va_fb_test_tab.do`).
  - `tables/va_cfr_all_<v1|v2>/spec_test/spec_<va_outcome>_all.dta` (output of chunk 3 `va_spec_test_tab.do`).
- **Outputs (.tex)**:
  - `tables/share/va/check/va_<va_outcome>_<v1|v2>.tex` (per outcome, both check + frag versions but they overwrite same file — see bugs).
  - `tables/share/va/check/va_score_<v1|v2>.tex` and `tables/share/va/pub/va_score_<v1|v2>.tex` — **paper Table 2** (`tab:va-sum-stats`).
  - `tables/share/va/check/va_out_<v1|v2>.tex` and `tables/share/va/pub/va_out_<v1|v2>.tex` — **paper Table 3** (`tab:va-enr-summary-statistics`).
- **Filename naming pattern**: `va_{score|out|<va_outcome>}_<version>.tex`. Note: 6-column structure (column codes 1–6) corresponds to: (1) base sample base controls no peer, (2) `las` sample base no peer, (3) `las` base + peer, (4) `las` ACS + peer, (5) `las` LAS + peer, (6) `las` LASD + peer.
- **Statistical specification**: pure formatting — no estimation. `tostring ... format(%10.3f)` for coefs/SEs/SD; star encoding `replace coef=coef+"*" if pval<.05/.01/.001`; F-stat in `{...}`.
- **Sourced helpers / Calls**: `macros_va.doh`, `drift_limit.doh`, custom inline `program rplc` for row-text replacement.
- **ssc/community packages**: `texsave`.
- **Gotchas / bugs**:
  - **Bug — both `texsave` calls write to `check/`**: lines 200–202 — the second `texsave` with `frag` option also writes to `check/`, not `pub/`. So per-outcome `.tex` files (e.g. `va_ela_v1.tex`) only land in `check/` ever, never `pub/`. Probably a copy-paste error from the score+out blocks below where the convention is correctly check vs pub.
  - **`hlines(1 4 19 19 20 23)` is hard-coded** for the stacked tables — assumes exactly 19 rows in panel A and exactly 23 in panel B. Adding/removing FB leave-out-vars or peer toggles silently misaligns the lines.
  - **No filter** on the `version` loop — runs both `v1` and `v2` even if you only want one.
  - The header `local texsave_options_combined` for `va_out_<version>` (line 238) has the title and footnote commented out — not a bug, just noting the asymmetry vs. score table.
  - "paranthesis" typo in `texsave` footnote (line 198, 222) — propagates into the `\footnote{...}` of any stacked table that uses these locals.
  - Resolves chunk 3 deferred mapping: yes, `va_spec_fb_tab_all.do` is the producer of paper Tables 2 and 3.
- **Reference to paper outputs**: paper Table 2 (`tab:va-sum-stats`), paper Table 3 (`tab:va-enr-summary-statistics`).

---

### File: `cde_va_project_fork/do_files/share/va_var_explain.do`

- **Owner**: Christina Sun (05/31/2023; updated 07/20/2023).
- **Pipeline phase**: share — produces inputs for paper Table 7 / Variance-decomposition.
- **Lines**: 221.
- **Purpose**: school-level regression of *enrollment* VA on both ELA and Math VAs (no controls — both standardized to z-scores first), aggregated together with DK VA variance and total VA variance into one stacked `.dta` per outcome, used as input to `va_var_explain_tab.do`.
- **Loop structure**: phase 1 (lines 46–119) — outer `version` × `sample in {b, las}` × `outcome in {enr, enr_2year, enr_4year}` × `control in <sample>_sample_controls` × `i in 1/2` (no peer / peer). Phase 2 (lines 126–207) — outer `outcome` × `sample` × `va_ctrl`: assemble `var_va`, `var_va_dk`, `dk_total_ratio`, `r2`/`unexplained` into a single `.dta` per outcome via `regsave ... append`.
- **Inputs**:
  - `estimates/va_cfr_all_<version>/va_est_dta/va_all.dta` (chunk 5 output).
  - Per-outcome / per-sample-control `va_<outcome>_<sample>_sp_<va_ctrl>_ct.dta` (chunk 4 → has `va_cfr_g11_<outcome>` and `va_cfr_g11_<outcome>_dk`).
- **Outputs (.ster)**:
  - `estimates/va_cfr_all_<version>/reg_out_va/reg_va_<outcome>_va_ela_math_<sample>_sp_<control>_ct{,_p}.ster` (32 per version: 3 outcomes × 2 samples × ~5 controls × 2 peer).
- **Outputs (.dta)** (consumed by `va_var_explain_tab.do`):
  - `estimates/va_cfr_all_<version>/reg_out_va/reg_va_<outcome>_va_ela_math_<sample>_sp_<control>_ct{,_p}.dta` (per cell, with `regsave addlabel`).
  - `tables/va_cfr_all_<version>/reg_out_va/reg_va_<outcome>_va_both_all.dta` (combined per outcome).
- **Filename naming pattern**: New token combination `_va_ela_math_` (regress y_VA on both subject VAs simultaneously). Compare to chunk 4's `_va_ela` / `_va_math` (single-subject persistence). Already in catalog.
- **Statistical specification**: `reg y_VA x_ela_VA x_math_VA [aw=n_g11_<outcome>_<sample>_sp]` — weighted by VA cohort size. NO controls. NO clustering. **All VAs are pre-standardized** (line 51–55) so coefficients are correlation-like.
- **Sourced helpers / Calls**: `macros_va.doh` (does NOT include `drift_limit.doh`).
- **ssc/community packages**: `regsave`.
- **Gotchas / bugs**:
  - **Bug — `set tracedepth 1` / `set trace on` (lines 19–20) never paired with `set trace off`**. Pollutes the log file.
  - **Bug — `regsave addlabel` macro list confusion** at lines 172–175: the addlabel writes `var_va`, `var_va_dk` correctly for the no-peer cell, but at lines 184–187 reuses identical literal labels (`var_va`, `var_va_dk`) when adding the peer row — overwriting? No, `regsave append` appends rows, so we have two rows with the same `var_va` label naming column. The values `_peer` are stored in the row, but the column name is shared. OK, that is the intent.
  - **Bug — phase 2 references `version` outside the outer `foreach version` loop** at line 140 (`use $vaprojdir/estimates/va_cfr_all_`version'/va_est_dta/...`). Wait — the outer `foreach version in v1 v2` opens at line 46 and is closed at line 207 (the `}` after `save, replace`). But examining more carefully: the second outer loop at line 126 (`foreach outcome ...`) has `version` macro from outer loop, so they DO share the version. Confirmed nesting OK.
  - **No `set seed` even though `set seed 1984` is set globally**.
  - **DK VA variance is the key concept**: `va_dk_<outcome>` is "doctored" enrollment VA (chunk 5 — DK = "deKnow" / Drop Known? — actually it's the `dk` suffix that denotes "VA orthogonal to test-score VA," from chunk 4/5). This file uses `var_va_dk / var_va` as the share of enrollment-VA variance NOT explained by test-score VA — i.e., the variance decomposition table. **Confirmed paper Table 7 producer (with `va_var_explain_tab.do` as renderer).**
- **Reference to paper outputs**: input to paper Table 7 (`tab:va-enr-decomposition`) — variance decomposition.

---

### File: `cde_va_project_fork/do_files/share/va_var_explain_tab.do`

- **Owner**: Christina Sun (05/18/2023).
- **Pipeline phase**: share — renders paper Table 7.
- **Lines**: 142.
- **Purpose**: rearranges the per-outcome variance/r² `.dta` into a 2-panel (Panel A: 2-year, Panel B: 4-year) LaTeX table with rows = {Total Var, Var Net of Test Score VA, Net Var/Total Var, 1−R²} × columns = 5 sample-control-peer combinations.
- **Loop structure**: outer `version in {v1, v2}` × `outcome in {enr_2year, enr_4year}`. Inner: load `reg_va_<outcome>_va_both_all.dta`, dedupe by sample/control/peer, build 5-column code, reshape, `tempfile`. Then `append` and `texsave`.
- **Inputs**: `tables/va_cfr_all_<version>/reg_out_va/reg_va_<outcome>_va_both_all.dta` (from `va_var_explain.do`).
- **Outputs (.tex)** — paper Table 7:
  - `tables/share/va/check/va_var_explain_<version>.tex`.
  - `tables/share/va/pub/va_var_explain_<version>.tex` — **paper Table 7** (`tab:va-enr-decomposition`, file `va_var_explain_v1.tex`). **CRITICAL paper-map entry resolved.**
- **Filename naming pattern**: `va_var_explain_<version>.tex`.
- **Statistical specification**: pure formatting — `tostring ... format(%10.4f)`.
- **Sourced helpers / Calls**: `macros_va.doh`, `drift_limit.doh`.
- **ssc/community packages**: `texsave`.
- **Gotchas / bugs**:
  - **Bug — `set tracedepth 1` / `set trace on` (lines 17–18); `set trace off` only at line 126** — but it's *inside* the `foreach version` block (line 120 is `}`); actually `set trace off` is OUTSIDE the loop on inspection. OK but trace runs through the whole formatting routine, generating a huge log.
  - **5-column matrix vs `va_spec_fb_tab_all.do`'s 6-column matrix mismatch**: `va_spec_fb_tab_all.do` uses 6 columns (adds `lasd`); this file only has 5 (no `lasd` column). The `lasd_d` row from FB tests would have nowhere to go, but this isn't an FB table — it's variance decomp. Still worth flagging: paper Table 7 will have one fewer column than paper Tables 2/3, by design.
- **Reference to paper outputs**: paper Table 7 (`tab:va-enr-decomposition`).

---

### File: `cde_va_project_fork/do_files/share/kdensity.do`

- **Owner**: Christina Sun (02/16/2023).
- **Pipeline phase**: share — produces kernel-density figures.
- **Lines**: 128.
- **Purpose**: kernel-density plots of standardized VA estimates for two specifications side by side: base/base vs `las`/`las`-with-peer; one figure for ELA+Math (`va_score_ela_math_kdensity_b_b_las_las_<version>.pdf`-ish) and one for 2-yr + 4-yr enrollment.
- **Loop structure**: outer `version` × middle `va_outcome` (4 outcomes for prep), inner `va_type in {score, enr}` for the actual figure.
- **Inputs**: `estimates/va_cfr_all_<version>/va_est_dta/va_<va_outcome>_all.dta` (chunk 5).
- **Outputs (.pdf)**:
  - `figures/share/va/<version>/va_<va1>_<va2>_kdensity_b_b_las_las_<version>.pdf` (e.g. `va_ela_math_kdensity_b_b_las_las_v1.pdf`, `va_enr_2year_enr_4year_kdensity_b_b_las_las_v1.pdf`).
- **Filename naming pattern**: `va_<va1>_<va2>_kdensity_<sp1>_<ct1>_<sp2>_<ct2>_<version>.pdf`. NEW token: `kdensity` figure prefix. Already mostly known; cataloged.
- **Statistical specification**: `kdensity` (default Gaussian kernel) on de-meaned VA estimates (line 58–64: subtract mean only — does not divide by SD; the local `sd_va` is computed for the figure note).
- **Gotchas / bugs**:
  - **Bug — DK VA dropped at line 55** for enrollment outcomes "to get around character limit for macros for mean and sd." Acknowledged technical-debt.
  - These figures are NOT in the paper map (paper Figs 1–4 are scatter plots, not kdensity). These are likely talk-only figures for AEFP/APPAM presentations; **not load-bearing**.
- **Reference to paper outputs**: NOT referenced in `common_core_va_v2.tex`. Talks only.

---

### File: `cde_va_project_fork/do_files/share/svyindex_tab.do`

- **Owner**: Christina Sun (02/06/2023; updated 09/12/2024).
- **Pipeline phase**: share — produces paper Table 8.
- **Lines**: 186.
- **Purpose**: combines bivariate and horse-race CASCHLS survey-index regression results from chunk 6 into a single 2-panel table per data type (`compcase` and `imputed`).
- **Loop structure**: outer `type in {compcase, imputed}` × inner `reg in {bivar, horse}`. Innermost: load combined survey-index `.dta` from chunk 6; drop unused VA columns (DK and `enr_l*`/`enr_b*`); reshape; rename. Then combine bivar + horse into one stacked `texsave` table per type.
- **Inputs**: `$projdir/out/dta/factor/index<reg>withdemo/<type>_index_<reg>_wdemo.dta` (chunk 6 outputs: `compcase_index_bivar_wdemo`, `compcase_index_horse_wdemo`, `imputed_index_bivar_wdemo`, `imputed_index_horse_wdemo`).
- **Outputs (.tex)** — paper Table 8:
  - `tables/share/survey/check/<type>_index_<reg>_wdemo.tex` (4 per-cell files).
  - `tables/share/survey/pub/<type>_index_<reg>_wdemo.tex`.
  - `tables/share/survey/check/<type>_index_combined_wdemo.tex` (stacked).
  - `tables/share/survey/pub/<type>_index_combined_wdemo.tex` — **paper Table 8** (`tab:survey`, file `imputed_index_combined_wdemo`). **CRITICAL paper-map entry resolved.**
- **Filename naming pattern**: `<type>_index_{bivar,horse,combined}_wdemo.tex` where `<type>` ∈ `{compcase, imputed}`.
- **Statistical specification**: pure formatting — drops constants and demographic controls (`drop if strpos(var,"ln")==1 | strpos(var,"avg")==1 | strpos(var,"_")==1`), keeps coef/stderr rows for `climate`, `quality`, `support`.
- **Gotchas / bugs**:
  - **Cross-repo path**: input dataset uses `$projdir` (CASCHLS project dir) NOT `$vaprojdir`. The CASCHLS repo is upstream — this is the boundary between projects.
  - **Bug — typo on line 185**: `translate$vaprojdir/log_files/share/svyindex_tab.smcl` — missing space between `translate` and `$vaprojdir`. Will fail at translation step (but log is still saved as `.smcl`).
  - **Hard-coded `hlines(1 7 7 8 -3)`** for the combined table — assumes 7 rows in Panel A, fragile.
  - **Confirmed**: Table 8 is built end-to-end inside this file; no external manual combination.
- **Reference to paper outputs**: paper Table 8 (`tab:survey`).

---

### File: `cde_va_project_fork/do_files/share/reg_out_va_tab.do`

- **Owner**: Christina Sun (02/07/2023; updated 03/01/2023).
- **Pipeline phase**: share — produces paper Table 6 (persistence).
- **Lines**: 331.
- **Purpose**: combines the per-cell persistence regressions (enrollment ~ VA) from chunk 4 into stacked single-subject and both-subject tables. Single-subject = paper Table 6 (`persistence_single_subject.tex`).
- **Loop structure**: outer `version in {v1, v2}`. Inner: (a) for each subject in {ela, math} × outcome × sample-control-peer combo, append the chunk 4 `.dta` into one `reg_out_<subject>_m.dta`; (b) same for `_va_ela_math_` (both subjects); (c) reshape into 8-column wide format (4 sample-controls × 2 outcomes); (d) `texsave`.
- **Inputs**:
  - `estimates/va_cfr_all_<version>/reg_out_va/reg_<outcome>_va_<subject>_<sample-control-peer>_m.dta` — chunk 4's `_m` suffix (chunk 4 deferred TeX writer is THIS file; CONFIRMED).
  - `estimates/va_cfr_all_<version>/reg_out_va/reg_<outcome>_va_ela_math_<sample-control-peer>_m.dta` (both-subject variant).
- **Outputs (.dta)**:
  - `tables/va_cfr_all_<version>/reg_out_va/reg_out_<subject>_m.dta` (one per subject).
  - `tables/va_cfr_all_<version>/reg_out_va/reg_out_both_m.dta`.
- **Outputs (.tex)** — paper Table 6:
  - `tables/share/va/check/persistence_single_subject.tex`.
  - `tables/share/va/pub/persistence_single_subject.tex` — **paper Table 6** (`tab:va-persistence`). **CRITICAL paper-map entry resolved.**
  - `tables/share/va/check/persistence_both_subject.tex` and `pub/`.
- **Filename naming pattern**: `persistence_{single,both}_subject.tex`.
- **Statistical specification**: pure formatting — `tostring ... format(%10.3f)`, star encoding, `headerlines("& \multicolumn{4}{c}{2-Year Enrollment} ...")`.
- **Sourced helpers / Calls**: `macros_va.doh`, `drift_limit.doh`.
- **ssc/community packages**: `texsave`.
- **Gotchas / bugs**:
  - **`sp_ct_p_combos`** at line 47 includes `lasd_ct_p` (5th column) — but the 4-column reshape (line 117–120) only assigns `column = (colgroup-1)*4 + 1..4`, never 5. So the `lasd` row is implicitly dropped (`drop if column==.`). Surviving columns are: (1) `b_sp_b_ct`, (2) `las_sp_b_ct`, (3) `las_sp_b_ct_p`, (4) `las_sp_las_ct_p`. The `lasd` cell from chunk 4 is silently discarded — paper Table 6 has 4 columns per outcome × 2 outcomes = 8 columns total.
  - **Confirmed**: the chunk 4 deferred TeX writer for `persistence_single_subject.tex` is THIS file. The CSV-rendering step from chunk 4 may have been a different artifact (rec'd to inspect chunk 4 audit for the exact matching).
- **Reference to paper outputs**: paper Table 6 (`tab:va-persistence`).

---

### File: `cde_va_project_fork/do_files/share/va_scatter.do`

- **Owner**: Christina Sun (02/20/2023; updated 03/13/2023).
- **Pipeline phase**: share — produces paper Figs 1–4 (and other panels).
- **Lines**: 724.
- **Purpose**: VA-correlation scatter plots across VA-sample × VA-control combinations. Each "Figure" block has weighted (`_wt`) and unweighted (`_nw`) versions and a third "redrawn for combine" version saved as `.gph`. Then four panels are combined via `graph combine`.
- **Loop structure**: outer `version in {v1, v2}` × middle `va_outcome in {ela, math, enr_2year, enr_4year}` for Figs 1, 2, 2-alt. Then Fig 3 (2-yr vs 4-yr) outside outcome loop. Fig 3-alt (ELA vs Math) similar. Figs 4a/4b loop over `outcome × subject`. Fig 5a/5b is heterogeneity (consumes already-saved `.gph` files from chunk 4 `va_het.do`).
- **Inputs**:
  - `estimates/va_cfr_all_<version>/va_est_dta/va_all.dta` (chunk 5).
  - `gph_files/va_cfr_all_<version>/het_reg_prior_score/het_reg_<outcome>_va_<subject>_x_prior_<subject>_<spec>_m.gph` (chunk 4 output, for Fig 5).
- **Outputs (.gph)** (intermediate, for `graph combine`):
  - `gph_files/va_cfr_all_<version>/va_<outcome>_scatter_<spec>_<version>_nw.gph`.
- **Outputs (.pdf)** — paper Figs 1–4 + supplements:
  - `figures/share/va/<version>/va_<outcome>_scatter_<spec>_<version>_{wt,nw}.pdf` (per-cell).
  - `figures/share/va/<version>/va_combined_scatter_las_sp_b_vs_las_ct_p_<version>_nw.pdf` — Fig 1 (same sample, change controls).
  - `figures/share/va/<version>/va_combined_scatter_b_vs_las_sp_b_ct_<version>_nw.pdf` — Fig 2 (change sample, base control).
  - `figures/share/va/<version>/va_combined_scatter_b_vs_las_sp_b_ct_p_<version>_nw.pdf` — Fig 2 alt.
  - `figures/share/va/<version>/va_enr_2year_4year_scatter_combined_<version>_nw.pdf` — combined 2-yr vs 4-yr panel.
  - `figures/share/va/<version>/va_ela_math_scatter_combined_<version>_nw.pdf` — combined ELA vs Math panel.
  - `figures/share/va/<version>/va_enr_2year_4year_<subject>_scatter_combined_<version>_nw.pdf` — Figs 3/4 (enrollment vs subject).
  - `figures/share/va/<version>/het_reg_va_<subject>_x_prior_<subject>_combined_<version>.pdf` and `het_reg_distance_va_<subject>_x_prior_<subject>_combined_<version>.pdf` — heterogeneity panels.
- **Filename naming pattern**: rich combinations, all matching paper-map Figs 1–4.
  - Per paper-map (chunk's existing audit): Fig 1 panels are `va_<outcome>_scatter_b_vs_las_sp_b_ct_v1_nw.gph`; Fig 2 panels are `va_<outcome>_scatter_las_sp_b_vs_las_ct_p_v1_nw.gph`; Fig 3 panels are `va_enr_{2year,4year}_ela_scatter_{b_sp_b_ct,las_sp_las_ct_p}_v1_nw.gph`; Fig 4 panels are `va_enr_{2year,4year}_math_scatter_...`. **All cross-checked.**
- **Statistical specification**:
  - `corr` for correlation coefficient → `local corr_<...>: di %5.3f r(rho)`.
  - `reg` for OLS slope → `local b_<...>: di %5.3f _b[<x>]`.
  - Weighted (`[aw=n_g11_<outcome>_<sample>_sp]`) and unweighted versions both produced.
- **Sourced helpers / Calls**: `macros_va.doh`, `drift_limit.doh`.
- **Gotchas / bugs**:
  - **Bug at line 308**: weighted Fig 3 panel-1 footer states `Fitted line slope = `corr_enr_2year_4year_1'` — uses correlation coefficient instead of regression slope. Should be `b_enr_2year_4year_1`. **Same bug at line 321 (unweighted), 333 (combined gph), 417, 430, 442 for ELA-vs-Math Fig 3-alt.** This is a consistent copy-paste error across the "Panel 1: base sample base control" sections. The slope was correctly computed but never used in the figure note.
  - **Lots of duplicated code** — could be folded into a foreach-driven helper. Currently 12+ near-identical `twoway` blocks.
  - **Heterogeneity figs** (Fig 5a/5b) consume `.gph` files from chunk 4's `va_het.do`. They are reused, NOT regenerated here.
  - **Three save targets** for each figure (wt PDF, nw PDF, nw GPH-for-combine). Total artifact count is large (>100 files per version).
- **Reference to paper outputs**: paper Figs 1–4 (scatter combined panels). Heterogeneity panels are paper Appendix C figures.

---

### File: `cde_va_project_fork/do_files/share/check/corr_dk_score_va.do`

- **Owner**: Christina Sun (07/03/2023).
- **Pipeline phase**: share/check — diagnostic script.
- **Lines**: 85.
- **Purpose**: print covariance matrix of `va_dk_<outcome>` (orthogonalized enrollment VA) with `va_ela_<...>` and `va_math_<...>` for all 10 sample-control specifications — used to cross-check the variance-decomposition table.
- **Loop structure**: outer `version` × middle `outcome in {enr_2year, enr_4year}` × inner `sample in {b, las}` × innermost `va_ctrl`.
- **Inputs**: `estimates/va_cfr_all_<version>/va_est_dta/va_all.dta` (chunk 5).
- **Outputs**: text-only via log file; nothing saved.
- **Statistical specification**: `corr ..., cov wrap` (Stata's covariance display).
- **Gotchas / bugs**:
  - **Hard-coded inline `local b_sample_controls b_ct` and `local las_sample_controls b_ct b_ct_p a_ct_p las_ct_p lasd_ct_p`** (lines 41–42) — duplicates info that *should* live in `macros_va_all_samples_controls.doh`. Worth folding back.
  - The two `include` lines (37–38) are commented out — perhaps intentional, but dropping them means the file works as-is.
  - Read-only diagnostic; not load-bearing for paper.
- **Reference to paper outputs**: NONE — diagnostic only.

---

### File: `cde_va_project_fork/do_files/explore/va_predicted_score.do`

- **Owner**: Christina Sun (08/15/2024; updated 08/22 + 08/29/2024).
- **Pipeline phase**: explore — predicted-prior-score robustness.
- **Lines**: 184.
- **Purpose**: estimates value-added using a *predicted* lag-1 ELA z-score (constructed by regressing `prior_ela_z_score` on `lag2ela`), as a robustness check. Loops over all sample-control combinations × score outcomes (ELA, Math) and enrollment outcomes (`enr`, `enr_2year`, `enr_4year`).
- **Loop structure**: outer `version in {v1, v2}` × middle `va_ctrl of va_controls` × inner `sample of <va_ctrl>_ctrl_samples` × innermost { test-score block (ELA, Math) and enrollment block (3 outcomes), each with no-peer + peer variants}.
- **Inputs**:
  - `data/va_samples_<version>/score_<sample>.dta` (test-score VA cohort).
  - `data/va_samples_<version>/out_<sample>` (enrollment cohort).
  - Macros: `macros_va.doh`, `drift_limit.doh`, `macros_va_all_samples_controls.doh`.
  - `lag2ela` (loscore-equivalent two-period lag, defined via `merge_lag2_ela.doh`).
  - `<va_ctrl>_scrhat_spec_controls` macro (from `macros_va.doh` lines 319–474; substitutes `prior_ela_z_score_hat` for `prior_ela_z_score` only in ELA control polynomial — math controls remain unchanged).
- **Outputs (.ster)**:
  - `estimates/va_cfr_all_<version>/vam/predicted_prior_score/va_<subject>_<sample>_sp_<va_ctrl>_ct.ster` (no peer).
  - `..._va_p_<subject>_<sample>_sp_<va_ctrl>_ct.ster` (peer).
  - `estimates/va_cfr_all_<version>/spec_test/predicted_prior_score/spec_<{subject,outcome}>_<sample>_sp_<va_ctrl>_ct.ster` and `spec_p_...ster`.
  - Same pattern for `va_<outcome>_...` and `va_p_<outcome>_...`.
- **Outputs (.dta)**:
  - `estimates/va_cfr_all_<version>/va_est_dta/predicted_prior_score/va_<{subject,outcome}>_<sample>_sp_<va_ctrl>_ct.dta` (per cell).
  - **NOT consumed** anywhere downstream that I can find — no `_all.dta` aggregation, no scrhat-specific `va_all.dta`. The cells exist on disk but only the spec/FB results feed into the spec_fb_tab. Confirms scrhat is robustness-only.
- **Filename naming pattern**: introduces `predicted_prior_score/` SUBDIR under all three stem dirs (`vam/`, `spec_test/`, `va_est_dta/`). NEW cataloguable subdir. Already known token: `_scrhat_` (suffix in macros).
- **Statistical specification**:
  - **First-stage**: `reg prior_ela_z_score lag2ela i.year `<va_ctrl>_spec_controls'` (line 57, 116). Then `predict prior_ela_z_score_hat` (xb).
  - **VA estimation**: `vam <subject> | <outcome>, teacher(school_id) year(year) class(school_id) controls(i.year `<va_ctrl>_scrhat_spec_controls' [`peer_<va_ctrl>_controls']) data(merge tv score_r) driftlimit(<drift>)`.
  - **Spec test**: `reg <residual> <va_cfr>, cluster(school_id)`.
- **Gotchas / bugs**:
  - **Sample restriction via missing `lag2ela`**: `predict prior_ela_z_score_hat` produces missing values whenever `lag2ela` (or other regressors) are missing. So scrhat VA is implicitly estimated on the leave-out-score sub-sample (where `lag2ela` is non-missing). This is by design but worth noting — scrhat VA samples ⊂ original VA samples.
  - **First-stage sample is the same as the VA sample** (no `keep if touse_g11_<subject>==1` before the `reg`) — wait, line 53 `use ... if touse_g11_<subject>==1` filters at the load step. So first-stage and VA sample match.
  - **Same first-stage rerun for every subject** — wasteful: lines 57–58 rerun the same `reg ... predict` for ELA before estimating both the ELA and Math VA. Could cache.
  - **`label data` typo** at line 171: `with `va_ctrl'' controls` (extra apostrophe).
  - **Math VA uses ELA-predicted score in controls**, i.e., `<va_ctrl>_scrhat_spec_controls` substitutes `prior_ela_z_score_hat` for `prior_ela_z_score` even in Math regressions. The Math control polynomial (`math_score_controls`) is untouched. So Math VA is conditioned on a *predicted* ELA prior + actual Math prior. This is by design (only ELA priors are believed to suffer measurement error from the testing-regime change in 2014).
  - **Outputs to per-cell `.dta` files but no roll-up**: there's no `va_all.dta` for scrhat, hence no aggregated `corr_dk_score_va.do`-style scrhat diagnostic. Only `spec_*.ster` and `fb_*.ster` are consumed downstream by `va_predicted_score_spec_fb_tab.do`.
- **Reference to paper outputs**: NOT in paper — robustness check only. Output tables are written to `tables/explore/` (not `tables/share/va/pub/`). May appear in talks but is not part of the submitted paper.

---

### File: `cde_va_project_fork/do_files/explore/va_predicted_score_fb.do`

- **Owner**: Christina Sun (08/15/2024; updated 08/22 + 08/29/2024).
- **Pipeline phase**: explore — scrhat forecast-bias tests.
- **Lines**: 263.
- **Purpose**: forecast-bias tests on scrhat VA — for each leave-out variable (`l`, `a`, `s`, `d` etc.) and each scrhat sample-control combination, estimate VA without then with the leave-out var, then test whether residual differences correlate with the original VA.
- **Loop structure**: outer `version` × middle `va_ctrl of va_controls_for_fb` × inner `fb_var of <va_ctrl>_ctrl_leave_out_vars` (note: NOT `<va_ctrl>_ctrl_scrhat_leave_out_vars`!) × `sample of <fb_var>_fb_<va_ctrl>_samples` × subject (or outcome) × { no peer, peer }.
- **Inputs**:
  - `data/va_samples_<version>/score_<sample>.dta`, `out_<sample>.dta`.
  - Macros from `macros_va.doh`, `drift_limit.doh`, `macros_va_all_samples_controls.doh`.
- **Outputs (.ster)**:
  - `estimates/va_cfr_all_<version>/vam/predicted_prior_score/va_<subject>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster` and `va_p_..._lv.ster`.
  - `estimates/va_cfr_all_<version>/fb_test/predicted_prior_score/fb_<subject>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster` and `fb_p_..._lv.ster`.
  - Same pattern for `<outcome>` instead of `<subject>`.
- **Filename naming pattern**: same as `va_predicted_score.do` plus suffix `_<fb_var>_lv` for the augmented-controls variant.
- **Statistical specification**:
  - First-stage: same `reg prior_ela_z_score lag2ela i.year ...; predict prior_ela_z_score_hat`.
  - VA without leave-out: `vam y, controls(i.year `scrhat_spec' [peer])`.
  - VA with leave-out: same plus `<fb_var>_controls`.
  - FB test: `gen <y>_r_d = <y>_r - <y>_r_p; reg <y>_r_d <va_cfr>, cluster(school_id)`.
- **Gotchas / bugs**:
  - **Bug — uses non-scrhat leave-out-var list**: line 43 references `<va_ctrl>_ctrl_leave_out_vars` (the regular FB list) NOT `<va_ctrl>_ctrl_scrhat_leave_out_vars` (the scrhat-specific list at lines 79–86 of `macros_va_all_samples_controls.doh`). The scrhat list excludes `l` (loscore) — sensible because loscore is what feeds the first-stage prediction, so it can't be used as a leave-out var. The non-scrhat list INCLUDES `l`. **This is a real bug that will produce nonsense FB-on-loscore tests for scrhat VA.** Should switch to `<va_ctrl>_ctrl_scrhat_leave_out_vars`.
  - **Same first-stage repetition** as in `va_predicted_score.do` — recomputed per loop iteration despite being identical.
- **Reference to paper outputs**: NONE — robustness only, outputs go to `tables/explore/`.

---

### File: `cde_va_project_fork/do_files/explore/va_predicted_score_spec_fb_tab.do`

- **Owner**: Christina Sun (08/22/2024).
- **Pipeline phase**: explore — scrhat table renderer.
- **Lines**: 269.
- **Purpose**: rebuild of `share/va_spec_fb_tab_all.do` but filtered to `predicted_score == 1` rows from the FB and spec test combined `.dta`s. Adds an extra row "Predicted Scores" to indicate these are scrhat results.
- **Loop structure**: outer `version` × middle `va_outcome` (4). Same internal logic as `va_spec_fb_tab_all.do`.
- **Inputs**:
  - `tables/va_cfr_all_<version>/fb_test/fb_<va_outcome>_all.dta`.
  - `tables/va_cfr_all_<version>/spec_test/spec_<va_outcome>_all.dta`.
  - **CRITICAL**: these are the SAME files as in `va_spec_fb_tab_all.do`, so they must contain a `predicted_score` column with values 0/1 — the upstream chunk 3 producer must encode this. Worth verifying in chunk 3 audit.
- **Outputs (.tex)**:
  - `tables/explore/va_<va_outcome>_<version>.tex` (per outcome).
  - `tables/explore/va_score_<version>.tex` (stacked ELA + Math).
  - `tables/explore/va_out_<version>.tex` (stacked 2-yr + 4-yr).
- **Filename naming pattern**: same stem as `va_spec_fb_tab_all.do` but written to `tables/explore/` not `tables/share/va/pub/`.
- **Gotchas / bugs**:
  - **Bug — `keeper=1 if va_control=="b" & inlist(fb_var, "a", "s", "d")`** (line 71): missing `"l"` compared to share counterpart (line 82 of `va_spec_fb_tab_all.do` includes `"l"`). Consistent with scrhat's no-`l` design (since scrhat eats loscore in first-stage). Not a bug — intentional.
  - **Bug — `hlines(4)`** at line 193 (single-outcome) and `hlines(1 4 17 17 18 22)` for combined: row counts assume 4 fewer rows than non-scrhat counterpart (the 4 FB-leave-out-var blocks for `l` are missing) — looks correct.
  - **Output goes to `tables/explore/`**: confirms this is robustness, not paper.
  - Same `set trace on` left running issue as other Christina files.
- **Reference to paper outputs**: NONE.

---

## Chunk 9 synthesis

### Final paper-artifact → producer mapping (consolidated across all chunks)

| Paper artifact | File | Producer |
|---|---|---|
| Table 1 (`tab:sum-stats`) | `sum_stats_g11.tex`, `sum_stats_college.tex` | `share/base_sum_stats_tab.do` (CHUNK 9 — RESOLVED) |
| Table 2 (`tab:va-sum-stats`) | `va_score_v1.tex` | `share/va_spec_fb_tab_all.do` (CHUNK 9 — confirms chunk 3 deferred) |
| Table 3 (`tab:va-enr-summary-statistics`) | `va_out_v1.tex` | `share/va_spec_fb_tab_all.do` (CHUNK 9) |
| Table 4 (`tab:hetero`) | `va_het/corr_char_wt_v1.tex` | `share/va_het.do` (chunk 4) |
| Table 5 (`tab:va-var-across-district`) | `va_het/var_across_district_wt_v1.tex` | `share/va_het.do` (chunk 4) |
| Table 6 (`tab:va-persistence`) | `persistence_single_subject.tex` | `share/reg_out_va_tab.do` (CHUNK 9 — RESOLVED, chunk 4 deferred) |
| Table 7 (`tab:va-enr-decomposition`) | `va_var_explain_v1.tex` | `share/va_var_explain.do` + `share/va_var_explain_tab.do` (CHUNK 9 — RESOLVED) |
| Table 8 (`tab:survey`) | `imputed_index_combined_wdemo.tex` | `share/svyindex_tab.do` (CHUNK 9 — RESOLVED, no manual combination needed) |
| Table A.1 (`tab:sample-counts`) | `counts_k12.tex` | `share/sample_counts_tab.do` (CHUNK 9) — note the older `_archive/matt_original/sum_stats_tab.do` is superseded |
| Figs 1–4 | combined scatter PDFs | `share/va_scatter.do` (CHUNK 9) |
| Fig 5 (heterogeneity panels) | `het_reg_*_combined_v1.pdf` | `share/va_scatter.do` consumes `gph` from `share/va_het.do` (chunk 4) |

**All Table 1–8 producers and Figs 1–4 producers are now identified.** No paper-artifact producer lives outside the `cde_va_project_fork/do_files/share/` tree (apart from upstream CASCHLS for Table 8's `.dta` inputs).

### scrhat (predicted-prior-score) pipeline picture

```
                   ┌─ macros_va.doh: ela_scrhat_controls (predicted lag-1 ELA in cubic polynomial)
                   │
data/va_samples/{score,out}_<sample>.dta
                   │
                   ▼
       reg prior_ela_z_score lag2ela i.year `<va_ctrl>_spec_controls'
       predict prior_ela_z_score_hat       (only valid where lag2ela non-missing)
                   │
                   ▼
explore/va_predicted_score.do          (no leave-out; main scrhat VA estimates)
explore/va_predicted_score_fb.do       (with leave-out vars; FB tests on scrhat VA)
                   │
                   ▼
estimates/va_cfr_all_<v>/vam/predicted_prior_score/*.ster
estimates/va_cfr_all_<v>/spec_test/predicted_prior_score/*.ster
estimates/va_cfr_all_<v>/fb_test/predicted_prior_score/*.ster
estimates/va_cfr_all_<v>/va_est_dta/predicted_prior_score/*.dta  (NOT rolled up further)
                   │
                   ▼
explore/va_predicted_score_spec_fb_tab.do
                   │
                   ▼
tables/explore/va_{score,out,<outcome>}_<version>.tex   (NOT in the paper)
```

**Key questions resolved:**

- **What model predicts `prior_ela_z_score_hat`?** OLS of `prior_ela_z_score` on `lag2ela` (defined in `merge_lag2_ela.doh` as L4_cst_ela for 2015–16, L5_cst_ela for 2017–18 — the leave-out-school CST score from 2 grades back) plus `i.year` and the rest of `<va_ctrl>_spec_controls`.
- **Which observations get the predicted vs observed prior score?** The predicted score replaces the observed `prior_ela_z_score` *everywhere it can be computed* — i.e., everywhere `lag2ela` is non-missing. Where `lag2ela` is missing, `prior_ela_z_score_hat` is missing, so those obs drop from the VA regression. Effective sample for scrhat VA = obs where original VA sample met AND `lag2ela` non-missing. This is a strict subset of the original VA sample.
- **Reported in paper?** No. Outputs are in `tables/explore/` and never referenced from `paper/main.tex`. Robustness check / internal-only.
- **Are scrhat per-cell `va_*.dta` files used downstream?** No — only the `spec_test` and `fb_test` `.ster` files are consumed by `va_predicted_score_spec_fb_tab.do`. The `.dta` files are written but never re-read in this codebase. **Dead artifacts on disk**, useful only for ad-hoc debugging.

### Missing TeX writers (do they live outside both repos?)

All paper Table 1–8 + Fig 1–4 TeX/PDF writers are inside `cde_va_project_fork/do_files/share/`. The only **out-of-repo** dependency is the *input data* for Table 8 (`$projdir/out/dta/factor/index<reg>withdemo/...`), which lives in the CASCHLS project. That data is produced by chunk 6 in the CASCHLS repo. The TeX writer itself (`svyindex_tab.do`) is in the CDE-VA repo.

No paper-artifact TeX writer lives outside `cde_va_project_fork/do_files/share/`. **Closed loop confirmed.**

### New tokens / packages

- **NEW subdir token: `predicted_prior_score/`** — appears beneath `vam/`, `spec_test/`, `fb_test/`, `va_est_dta/` in the scrhat pipeline. Marks the scrhat sub-tree of estimate dirs.
- **NEW filename-stem token: `_lv`** (stands for "leave-out version") — appears as suffix on FB-test `.ster` filenames in scrhat (and possibly in the original chunk 3 fb pipeline, worth re-checking). Confirms a model with the FB leave-out variable added.
- **NEW filename-stem token: `_d`** (for distance) — referenced everywhere in chunks 3+; not new.
- **NEW pattern `_va_ela_math_`** — confirmed both-subject simultaneous regression naming. Already partially cataloged from chunk 4.
- **No new ssc packages** — chunk 9 uses only `texsave`, `esttab`/`estout`, `regsave`, all already in inventory.
- **`predicted_score` column** — must exist in upstream `fb_<outcome>_all.dta` and `spec_<outcome>_all.dta` files. Worth verifying chunk 3 audit for whether this column is actually populated by 0/1 (Christina's Aug 2024 changes may have added it post-hoc).

### Anomalies / bugs (chunk 9 additions to inventory)

1. **`va_spec_fb_tab_all.do` line 200–202**: per-outcome `texsave` writes both versions to `check/`, never `pub/`. Per-outcome single-table files only exist in `check/`.
2. **`va_spec_fb_tab_all.do` line 198, 222**: typo "paranthesis" in footnote.
3. **`va_var_explain.do` lines 19–20**: `set trace on` never paired with `set trace off`.
4. **`va_var_explain_tab.do` lines 17–18**: same — `set trace on` without proper end (off only at line 126, but spans entire formatting routine).
5. **`svyindex_tab.do` line 185**: missing space after `translate` keyword.
6. **`va_scatter.do` lines 308, 321, 333, 417, 430, 442**: figure note says "Fitted line slope = `corr_*` " but should be `b_*` — copy-paste error in 6+ places.
7. **`va_scatter.do`**: heavy code duplication; many ~30-line near-identical twoway blocks.
8. **`reg_out_va_tab.do` line 47**: `lasd_ct_p` in `sp_ct_p_combos` but reshape only assigns columns 1–4 — `lasd` cell silently dropped from paper Table 6.
9. **`va_predicted_score_fb.do` line 43**: uses `<va_ctrl>_ctrl_leave_out_vars` instead of the scrhat-specific `<va_ctrl>_ctrl_scrhat_leave_out_vars`; will compute FB-on-loscore tests for scrhat VA which are conceptually invalid (loscore is the IV in the first-stage — can't be a leave-out var for the second stage).
10. **`va_predicted_score.do` and `va_predicted_score_fb.do`**: first-stage (`reg prior_ela_z_score lag2ela`) recomputed per ELA/Math/outcome iteration despite being identical — wasteful runtime.
11. **`va_predicted_score.do` line 171**: `label data` string has `'va_ctrl''` (extra apostrophe).
12. **`base_sum_stats_tab.do` line 119, 324**: `merge_k12_postsecondary.doh enr_only` invoked in both code branches — risk of double-merging in load-only path.
13. **`base_sum_stats_tab.do`**: hard-codes `data/va_samples_v1/base_nodrop.dta` — no `_v2` parallel.
14. **`base_sum_stats_tab.do` lines 463–579**: long sequence of `esttab ... append` calls; failure mid-sequence leaves output file inconsistent.
15. **`corr_dk_score_va.do` lines 41–42**: redundantly hard-codes sample-control lists that are already in `macros_va_all_samples_controls.doh`.
16. **`sample_counts_tab.do`**: cascading `if`-filters duplicated 12 times for counts AND 12 times for z-scores — a missing `&` in one block would silently produce wrong table rows.
17. **`reg_out_va_tab.do` lines 175 and 289**: row label "VA Controls" and prior label "Regression Controls" — distinguishable but easy to confuse during reading.

### Open questions

#### For user
- **Q1:** Is the "predicted_score" column in `fb_<outcome>_all.dta` populated by the chunk-3 producer, or did Christina's 2024 changes break the upstream contract? If upstream still writes `predicted_score = 0` only, then `va_predicted_score_spec_fb_tab.do` will produce empty tables.
- **Q2:** Should the `va_predicted_score_fb.do` bug at line 43 (using non-scrhat leave-out list) be patched? It silently produces FB tests on loscore for scrhat VA — invalid since loscore is the first-stage instrument.
- **Q3:** Are the scrhat per-cell `.dta` files (in `va_est_dta/predicted_prior_score/`) intended to feed into a future `va_all.dta` aggregation, or can they be deleted as dead artifacts?
- **Q4:** Is `share/check/corr_dk_score_va.do` worth keeping at all? It's a one-off diagnostic with hard-coded sample lists that duplicate macros.
- **Q5:** Should the `va_scatter.do` `corr_*`-vs-`b_*` bug (~6 occurrences) be fixed and figures re-rendered? This affects panel 1 of paper Fig 3 and Fig 3-alt.
- **Q6:** The `lasd` column dropping in `reg_out_va_tab.do` — was that intentional (paper Table 6 has only 4 columns per outcome) or an oversight (chunk 4 produces `lasd` cells but they vanish at table-build)?

#### For chunk 10 (upstream / Python geocoding)
- **Q7:** Where does `lag2ela` ultimately come from? Chunk 9 confirms `merge_lag2_ela.doh` reads `L4_cst_ela_z_score` and `L5_cst_ela_z_score` — but those originate in `k12_lag_test_scores_clean.dta`. Chunk 10 should cover the upstream cleaning / panel-construction steps that produce this lag-test-score dataset.
- **Q8:** The `sibling_out_xwalk` global path is referenced in `sample_counts_tab.do` line 53 but never defined locally — chunk 10 should locate where this is set (likely `settings.do` or a project-level header).
- **Q9:** Distance controls (`d_controls`) are mentioned throughout but the geocoding pipeline (Python in `cde_va_project_fork/py_files/`) is upstream of any Stata script in chunks 3–9. Chunk 10 should map the Python ETL to the Stata-consumed `<distance>` variables.
- **Q10:** Does the `census_controls_sample` / `score_a.dta` ACS sample creation have its own audit chunk, or is it folded into the data-prep chunks (1–2)? The `acs/` log-files dir suggests substantial ACS prep code exists.

### Summary

**All deferred chunks 3 → 9 paper-artifact mappings now resolved.** Every paper Table 1–8 and Fig 1–4 has a confirmed producer in `cde_va_project_fork/do_files/share/`. The scrhat pipeline (`explore/`) is fully exploratory — output goes to `tables/explore/`, never referenced from `paper/main.tex`. Bugs identified add ~17 items to the inventory (running total: ~85+). New cataloged tokens: `predicted_prior_score/` subdir, `_lv` suffix, `_va_ela_math_` regression-target naming.
