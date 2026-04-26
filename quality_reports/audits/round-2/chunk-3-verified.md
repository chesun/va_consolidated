# Chunk 3 Verification Audit — VA-Core Estimation Pipeline

**Audit type:** Independent blind verification (Phase 0a-v2, chunk 3)
**Date:** 2026-04-24
**Auditor:** sequestered (no access to round-1)
**Scope:** 14 .do files + 2 .doh helpers under `cde_va_project_fork/do_files/sbac/`
**Predecessor:** `~/github_repos/cde_va_project_fork`, branch `changes_by_che`

All paths cited in this report are absolute. All line numbers refer to the file under audit.

---

## File Inventory

The 14 files in scope, plus the 2 helpers, are all present at the paths the prompt specifies. No additional files outside scope are referenced from these 14 except `macros_va.doh` and `macros_va_all_samples_controls.doh` (called via `include`). No surprise extras; no missing files.

| # | File | Lines |
|---|---|---|
| 1 | `va_score_all.do` | 142 |
| 2 | `va_out_all.do` | 211 |
| 3 | `va_score_fb_all.do` | 200 |
| 4 | `va_out_fb_all.do` | 315 |
| 5 | `va_score_sib_lag.do` | 150 |
| 6 | `va_out_sib_lag.do` | 155 |
| 7 | `merge_va_est.do` | 121 |
| 8 | `va_corr.do` | 88 |
| 9 | `va_score_spec_test_tab.do` | 206 |
| 10 | `va_out_spec_test_tab.do` | 206 |
| 11 | `va_score_fb_test_tab.do` | 189 |
| 12 | `va_out_fb_test_tab.do` | 174 |
| 13 | `va_spec_fb_tab.do` | 275 |
| 14 | `va_sib_lag_spec_fb_tab.do` | 139 |
| h1 | `drift_limit.doh` | 4 |
| h2 | `out_drift_limit.doh` | 2 |

---

## Per-File Entries

### File: do_files/sbac/va_score_all.do

**Owner**: Christina (Che) Sun (header comment, line 6)
**Lines**: 142
**Purpose** (1-2 sentences): Estimates Chetty-Friedman-Rockoff (CFR) school value-added (VA) using the `vam` ado on SBAC ELA and Math z-scores. Loops over all sample × control specification combinations defined in `macros_va_all_samples_controls.doh`, with and without peer controls, and for both v1 and v2 prior-score variants.

**Loop structure**:

- `foreach version in v1 v2` (line 58) — prior-score variant
- `foreach va_ctrl of local va_controls` (line 61) — 16 control specs from macro `va_controls = b l a s la ls as las bd ld ad sd lad lsd asd lasd`
- `foreach sample of local \`va_ctrl'_ctrl_samples` (line 62) — sample list keyed by control spec
- `foreach subject in ela math` (line 63)

Total nested depth: 4. Inside the body each iteration runs 2 vam invocations (no peer / with peer) plus the spec-test regressions and one collapse-and-save.

**Sample restrictions applied**: `if touse_g11_\`subject'==1` on line 65 (the only restriction; sample membership is encoded in the `score_<sample>.dta` file via a `touse_g11_*` flag built upstream).

**vam invocations**: 2 per iteration.

- L72-80: `vam sbac_\`subject'_z_score`, no peer controls, controls = `i.year` + `\`\`va_ctrl'_spec_controls'`. `data(merge tv score_r)`. `driftlimit(\`score_drift_limit')`. `estimates(...va_\`subject'_\`sample'_sp_\`va_ctrl'_ct.ster, replace)`.
- L96-105: same target, with peer controls added (`\`peer_\`va_ctrl'_controls'`). Output file prefixed `va_p_`.

**Output files written**:

- Estimates (`.ster`):
  - `$vaprojdir/estimates/va_cfr_all_\`version'/vam/va_\`subject'_\`sample'_sp_\`va_ctrl'_ct.ster` (L80)
  - `$vaprojdir/estimates/va_cfr_all_\`version'/vam/va_p_\`subject'_\`sample'_sp_\`va_ctrl'_ct.ster` (L105)
  - `$vaprojdir/estimates/va_cfr_all_\`version'/spec_test/spec_\`subject'_\`sample'_sp_\`va_ctrl'_ct.ster` (L87)
  - `$vaprojdir/estimates/va_cfr_all_\`version'/spec_test/spec_p_\`subject'_\`sample'_sp_\`va_ctrl'_ct.ster` (L112)
- Datasets (`.dta`):
  - `$vaprojdir/estimates/va_cfr_all_\`version'/va_est_dta/va_\`subject'_\`sample'_sp_\`va_ctrl'_ct.dta` (L123) — collapsed school-year level VA estimates with both no-peer and peer columns plus `n_g11_\`subject'_\`sample'_sp`.
- Logs: `$vaprojdir/log_files/sbac/va_score_all.smcl` and `.log` (L32, L141-142).

**Filename naming pattern**: `va_<subject>_<sample>_sp_<va_ctrl>_ct.ster`. Peer variant inserts `_p_` after `va_`: `va_p_<subject>_...`. Spec-test files use prefix `spec_` (no peer) or `spec_p_` (peer). The `_sp` and `_ct` are LITERAL fixed tokens (sample marker and control marker, respectively); the values of sample and va_ctrl come from the loops.

**Inputs** (datasets `use`'d): `$vaprojdir/data/va_samples_\`version'/score_\`sample'` (L65). One per sample, accessed via `if touse_g11_\`subject'==1`.

**Sourced helpers / Calls**:

- `include $vaprojdir/do_files/sbac/macros_va.doh` (L42) — defines `\`<va_ctrl>_spec_controls'`, `\`peer_<va_ctrl>_controls'`, etc.
- `include $vaprojdir/do_files/sbac/drift_limit.doh` (L47) — defines `\`score_drift_limit'`. NOTE: this in turn requires `\`test_score_max_year'` and `\`test_score_min_year'` macros to be already in scope from `macros_va.doh`.
- `include $vaprojdir/do_files/sbac/macros_va_all_samples_controls.doh` (L55) — defines `va_controls`, `<va_ctrl>_ctrl_samples`.

**Path references that need updating in consolidation**: every path is built from `$vaprojdir`. Specific expressions:

- `$vaprojdir/log_files/sbac/...` (L32, L141-142)
- `$vaprojdir/do_files/sbac/macros_va.doh` (L42)
- `$vaprojdir/do_files/sbac/drift_limit.doh` (L47)
- `$vaprojdir/do_files/sbac/macros_va_all_samples_controls.doh` (L55)
- `$vaprojdir/data/va_samples_\`version'/score_\`sample'` (L65)
- `$vaprojdir/estimates/va_cfr_all_\`version'/vam/...` (L80, L105)
- `$vaprojdir/estimates/va_cfr_all_\`version'/spec_test/...` (L87, L112)
- `$vaprojdir/estimates/va_cfr_all_\`version'/va_est_dta/...` (L123)

No hardcoded `/Users/`, `/home/`, or `C:\` paths. All paths are global-relative.

**Stata version / non-trivial syntax**:

- `cd $vaprojdir` (L28)
- `set varabbrev off` (L36) — disable abbrevation, defensive
- `set scheme s1color` (L38)
- `set seed 1984` (L39) — reproducibility
- `vam` is the Stepner ado package (`ssc install vam` per CFR conventions); not standard Stata.
- `i.year#(c.prior_ela_z_score##c.prior_ela_z_score##c.prior_ela_z_score)` factor variable interactions in the spec controls (defined upstream in `macros_va.doh`).
- `collapse (firstnm) va_* (mean) sbac_*_r* (sum) n_... = touse_g11_\`subject', by(school_id cdscode grade year)` (L116-119) — assumes `va_*` and `sbac_*_r*` are constant within school-year, takes first non-missing.

**ssc/community packages used**: `vam` (Stepner). No others in this file.

**Gotchas / non-obvious behavior**:

- L82-83 / L107-108: After every vam call, `tv` and `score_r` (vam reserved names) are renamed. The peer call is followed by `_peer`-suffixed variables so the no-peer renames are not overwritten in the next loop iteration (good).
- L116 collapse uses `va_*` wildcard — relies on the renames having happened. If a future variant of vam yielded e.g. `tv_<grade>` instead of plain `tv`, the renames would silently miss it.
- The `_p` suffix in the peer rename targets diverges from the `_p_` infix in the .ster filename (L105 has `va_p_<subject>...`, L107 produces var `va_cfr_g11_<subject>_peer`). This is consistent within each domain but is a naming inconsistency.
- `cd $vaprojdir` (L28) changes the working dir for the entire process — affects any subsequent relative-path operations.
- No `cap log close` (just `log close _all`, L30) — if a previous `.smcl` is locked, this errors. The sib_lag files (L20) use `cap log close _all`.
- `compress` (L122) before save — saves disk space, no behavioral effect.

**Reference to paper outputs**: The `.ster` files saved here are the PRIMARY input to `va_score_spec_test_tab.do` (which builds the dta feeding Table 2). The `.dta` files in `va_est_dta/` are read by `merge_va_est.do`, then by `va_corr.do` (correlation matrices) and by `va_out_all.do` (which uses ELA/Math VA as controls in the deep-knowledge VA estimation, L118 of `va_out_all.do`).

**Notes / open questions**:

- The peer rename target diverges from the spec-test test command. The spec-test reg on line 111 uses `va_cfr_g11_\`subject'_peer` — matches the rename on line 107 (peer variable named `_peer`, not `_p`). All consistent within the file.
- Loops over 16 `va_controls` (including the `*d` distance variants), but `va_corr.do` and the published paper tables only use 8 of these. This file produces extra `.ster` files that are likely not all consumed downstream. To audit at consolidation time.

---

### File: do_files/sbac/va_out_all.do

**Owner**: Christina (Che) Sun (header L6)
**Lines**: 211
**Purpose** (1-2 sentences): Estimates outcome (NSC enrollment) VA for three outcomes (`enr`, `enr_2year`, `enr_4year`), with both "regular" outcome VA (no test-score VA in controls) and "Deep Knowledge" outcome VA that controls for the previously-estimated ELA and Math test-score VA. Mirrors `va_score_all.do` structure.

**Loop structure**:

- `foreach version in v1 v2` (L52)
- `foreach va_ctrl of local va_controls` (L59)
- `foreach sample of local \`va_ctrl'_ctrl_samples` (L60)
- `foreach outcome in enr enr_2year enr_4year` (L61)
- Within: nested `foreach subject in ela math` (L117) for the DK merge.

**Sample restrictions applied**: `if touse_g11_\`outcome'==1` on L62. Inside the body, `touse_g11_\`outcome'_dk` is generated (L124) and set to 0 if either `va_cfr_g11_ela` or `va_cfr_g11_math` is missing (L125-126). `touse_g11_\`outcome'_\`subject'` flags also generated in L120-121 inside the inner subject loop, but I do not see them USED for any subsequent restriction in this file — flagged below.

**vam invocations**: 4 per iteration (regular VA without peer, regular with peer, DK without peer, DK with peer):

- L70-78 — regular outcome VA, no peer
- L93-102 — regular outcome VA, with peer
- L133-143 — DK outcome VA controlling for ELA/Math VA, no peer
- L157-168 — DK outcome VA controlling for ELA/Math VA, with peer

**Output files written**:

- Estimates (`.ster`):
  - `va/va_\`outcome'_\`sample'_sp_\`va_ctrl'_ct.ster` (L78)
  - `vam/va_p_\`outcome'_\`sample'_sp_\`va_ctrl'_ct.ster` (L102)
  - `vam/dk_va_\`outcome'_\`sample'_sp_\`va_ctrl'_ct.ster` (L143)
  - `vam/dk_va_p_\`outcome'_\`sample'_sp_\`va_ctrl'_ct.ster` (L168)
  - `spec_test/spec_\`outcome'_\`sample'_sp_\`va_ctrl'_ct.ster` (L85)
  - `spec_test/spec_p_\`outcome'_\`sample'_sp_\`va_ctrl'_ct.ster` (L109)
  - `spec_test/dk_spec_\`outcome'_\`sample'_sp_\`va_ctrl'_ct.ster` (L150)
  - `spec_test/dk_spec_p_\`outcome'_\`sample'_sp_\`va_ctrl'_cts.ster` (L176) — **TYPO: ends `_cts.ster` instead of `_ct.ster`**, see Q7.
- Datasets:
  - `va_est_dta/va_\`outcome'_\`sample'_sp_\`va_ctrl'_ct.dta` (L191) — collapsed school-year, includes both regular and DK VA columns. Single file per outcome × sample × va_ctrl.
- Logs: `log_files/sbac/va_out_all.smcl` and `.log` (L31, L210-211).

**Filename naming pattern**: same as `va_score_all.do`, with `\`outcome'` substituted for `\`subject'`. DK variant uses `dk_` prefix. Peer variant uses `_p_` infix after `va_`. The L176 typo (`_cts`) is the only deviation.

**Inputs**:

- `$vaprojdir/data/va_samples_\`version'/out_\`sample'` (L62)
- For DK: merges in `$vaprojdir/estimates/va_cfr_all_\`version'/va_est_dta/va_\`subject'_\`sample'_sp_\`va_ctrl'_ct.dta` (L118) — these are the ELA/Math VA dta files from `va_score_all.do`. **Therefore `va_score_all.do` MUST be run before `va_out_all.do` for the deep-knowledge spec.**

**Sourced helpers / Calls**:

- `include macros_va.doh` (L41)
- `include drift_limit.doh` (L46)
- `include macros_va_all_samples_controls.doh` (L50)

**Path references that need updating in consolidation**: same path families as `va_score_all.do`. All `$vaprojdir`-rooted.

**Stata version / non-trivial syntax**:

- `merge m:1 cdscode year using ... , nogen keep(1 3) keepusing(va_cfr_g11_\`subject')` (L118) — many-to-one merge bringing in test-score VA estimates per school-year.
- `compress` before save (L190).

**ssc/community packages used**: `vam`.

**Gotchas / non-obvious behavior**:

- **L176 typo**: `dk_spec_p_..._cts.ster` (with extra `s`) — the only file with `_cts` instead of `_ct`. Downstream consumers expecting `_ct` will not find this file; downstream consumers won't write to this name. This is a real bug to flag to the user. (See `va_out_spec_test_tab.do` — it does NOT load any `dk_spec_*.ster` file, so the immediate spec-test table consumption isn't broken; but anything that does load the DK peer spec_test estimates will fail.)
- L66, L89: di string says "Subject: \`subject'" but this is in the OUTCOME loop where `subject` is unset (still has the residual value from the previous `va_score_all.do` run, or empty). Cosmetic display bug only — does not affect estimation.
- L120-122: generates `touse_g11_\`outcome'_\`subject'` indicators that depend on whether the test-score VA estimate is present. These touse flags are NEVER referenced again in this file (the DK estimation on L133 just runs vam with the ELA/Math VA in controls; vam will drop obs missing the controls anyway). So these `touse_g11_<outcome>_<subject>` variables are computed but unused — dead code unless used downstream after the collapse.
- The collapse on L183 takes `(firstnm) va_*` — collects every `va_*` variable, including the merged-in `va_cfr_g11_ela` and `va_cfr_g11_math`. This is intentional: the saved .dta carries all of regular VA, DK VA, and the test-score VA covariates per school-year cell.
- L189 label has a stray apostrophe: `with \`va_ctrl'' controls` (extra single quote). Cosmetic.
- Reserved-name `tv` and `score_r` are renamed after each of the 4 vam calls — no silent overwrites. Verified in Q5 audit below.

**Reference to paper outputs**: spec_test `.ster` files feed Table 3 (`tab:va-enr-summary-statistics`) via `va_out_spec_test_tab.do`. The `va_est_dta/va_<outcome>_..._ct.dta` is consumed by `va_corr.do` and `merge_va_est.do`, and is the basis for the pass-through ρ regression in Table 4 (paper Table 4 input is computed in some downstream file — see Q3).

**Notes / open questions**:

- Does the L176 typo actually cause a run-time error or just orphan a file? Need to grep for any `estimates use ...dk_spec_p_*_cts.ster` consumption — none found in chunk 3. So the file gets written and ignored. To raise as a bug.
- Why are the touse_dk flags computed if not used? Suggests refactoring left dead code. To check.

---

### File: do_files/sbac/va_score_fb_all.do

**Owner**: Christina (Che) Sun (L6)
**Lines**: 200
**Purpose** (1-2 sentences): Forecast-bias variant of test-score VA: re-estimates VA on the same samples but additionally treats specific covariate sets (`fb_var`) as "leave-out" variables included as controls. The forecast-bias test then compares the resulting predicted residual against the no-leave-out residual via an OLS regression on the `va_cfr` shrunken estimate.

**Loop structure**:

- `foreach version in v1 v2` (L59)
- `foreach va_ctrl of local va_controls_for_fb` (L63) — note this uses `va_controls_for_fb` = `b l a s la ls as las` (8 specs, no `*d` distance variants)
- `foreach fb_var of local \`va_ctrl'_ctrl_leave_out_vars` (L66) — see Q2 below for full list
- `foreach sample of local \`fb_var'_fb_\`va_ctrl'_samples` (L69)
- `foreach subject in ela math` (L71)

**Sample restrictions applied**: `if touse_g11_\`subject'==1` (L74). Same one-line filter on the input dta.

**vam invocations**: 4 per iteration:

- L83-90: no leave-out, no peer — used as baseline; **NO `estimates(...)` option**, output discarded except for the rename and spec-test display
- L101-110: with leave-out, no peer — saved to `vam/va_<subject>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster`
- L132-140: no leave-out, with peer — output discarded
- L153-163: with leave-out, with peer — saved to `vam/va_p_<subject>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster`

**Output files written**:

- Estimates (`.ster`):
  - `vam/va_<subject>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster` (L110)
  - `vam/va_p_<subject>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster` (L163)
  - `fb_test/fb_<subject>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster` (L120)
  - `fb_test/fb_p_<subject>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster` (L172)
- Logs: `log_files/sbac/va_score_fb_all.smcl` and `.log` (L32, L199-200).

**Filename naming pattern**: same prefix structure as `va_score_all.do` plus `_<fb_var>_lv` suffix. The `_lv` is LITERAL.

**Inputs**: `$vaprojdir/data/va_samples_\`version'/score_\`sample'` (L74).

**Sourced helpers / Calls**: same three includes as `va_score_all.do` (macros_va, drift_limit, macros_va_all_samples_controls).

**Path references that need updating in consolidation**: same families as `va_score_all.do`, plus the new `fb_test/` subdirectory.

**Stata version / non-trivial syntax**:

- L114-119 and L165-170: builds residual difference `sbac_g11_\`subject'_r_d = sbac_g11_\`subject'_r - sbac_g11_\`subject'_r_p` (and `..._d_peer` variant), then regresses on the no-leave-out VA estimate. This is the FB test estimator.

**ssc/community packages used**: `vam`.

**Gotchas / non-obvious behavior**:

- **No `estimates(...)` on the no-leave-out vam (L83 and L132)** — these run, produce `tv` and `score_r`, and are renamed and used in residual differencing, but are not saved. The displayed `reg sbac..._r va_cfr...` on L97 and L148 is purely a sanity-check display (its estimate dataset is the IMPLICIT one that the FOLLOWING vam call replaces). This is fine but confusing.
- The "no-leave-out" vam called inside `va_score_fb_all.do` is doing the same work as the one in `va_score_all.do` — same controls — but the .ster output is not saved here. So the spec_test's no-leave-out .ster comes from `va_score_all.do`, and the FB test's no-leave-out residuals are recomputed in this file (with seed 1984, output is deterministic, so should match).
- L114: `rename score_r sbac_g11_\`subject'_r_p` — using `_p` suffix here for "predicted" / leave-out version. This collides with the convention in `va_score_all.do` and `merge_va_est.do` where `_p` denotes "peer." This is an internal-convention conflict. (No actual variable collision because peer-vs-leaveout files don't coexist in the same dataset within this file.)
- The `_p_peer` suffix on L166 is a stack of `_p` (predicted) and `_peer` (peer). Awkward but not wrong.
- Indentation inconsistency: L143-172 has extra leading spaces (inside the peer-controls block) compared to L92-122 (inside the no-peer block). Cosmetic.
- L177 ends with `}` closing the va_ctrl loop, but verification: open braces count = close braces? Let me think — version (1) → va_ctrl (2) → fb_var (3) → sample (4) → subject (5). Closing on L173 (subject), L175 (sample), L176 (fb_var), L177 (va_ctrl), L179 (version). 5 closes for 5 opens; correct.

**Reference to paper outputs**: The `fb_test/fb_<subject>_..._lv.ster` files feed `va_score_fb_test_tab.do` which builds the dta consumed by `va_spec_fb_tab.do` for paper Table 2 (rows 3-6, FB test β coefficients).

**Notes / open questions**:

- Why duplicate the no-leave-out vam estimation between `va_score_all.do` and `va_score_fb_all.do` rather than `estimates use` the previously saved one? Possibly because the variable `score_r` (residual without leave-out) is needed in this file's dataset, not just the .ster.

---

### File: do_files/sbac/va_out_fb_all.do

**Owner**: Christina (Che) Sun (L6)
**Lines**: 315
**Purpose** (1-2 sentences): Forecast-bias variant of outcome (enrollment) VA — covers regular outcome VA AND deep-knowledge outcome VA, both with and without peer controls and with leave-out variables included. Largest file in the chunk; mirrors the structure of `va_score_fb_all.do` but with the additional DK layer.

**Loop structure**:

- `foreach version in v1 v2` (L60)
- `foreach va_ctrl of local va_controls_for_fb` (L64)
- `foreach fb_var of local \`va_ctrl'_ctrl_leave_out_vars` (L67)
- `foreach sample of local \`fb_var'_fb_\`va_ctrl'_samples` (L70)
- `foreach outcome in enr enr_2year enr_4year` (L72)
- Inner: `foreach subject in ela math` (L179) for the DK merge.

**Sample restrictions applied**:

- `if touse_g11_\`outcome'==1` (L75)
- `touse_g11_\`outcome'_\`subject' = touse_g11_\`outcome'; replace = 0 if mi(va_cfr_g11_\`subject')` (L182-183)
- `touse_g11_\`outcome'_dk` similarly (L186-188)

**vam invocations**: 8 per iteration:

- L84-91: regular outcome VA, no leave-out, no peer (no save)
- L102-111: regular, with leave-out, no peer (saved to `vam/va_..._lv.ster`)
- L131-139: regular, no leave-out, with peer (no save)
- L152-162: regular, with leave-out, with peer (saved `vam/va_p_..._lv.ster`)
- L193-202: DK, no leave-out, no peer (no save)
- L214-225: DK, with leave-out, no peer (saved `vam/dk_va_..._lv.ster`)
- L244-254: DK, no leave-out, with peer (no save)
- L267-279: DK, with leave-out, with peer (saved `vam/dk_va_p_..._lv.ster`)

**Output files written**:

- Estimates (`.ster`):
  - `vam/va_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster` (L111)
  - `vam/va_p_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster` (L162)
  - `vam/dk_va_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster` (L225)
  - `vam/dk_va_p_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster` (L279)
  - `fb_test/fb_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster` (L120)
  - `fb_test/fb_p_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster` (L171)
  - `fb_test/dk_fb_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster` (L236)
  - `fb_test/dk_fb_p_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster` (L288)
- Logs: `log_files/sbac/va_out_fb_all.smcl` and `.log` (L33, L314-315).

**Filename naming pattern**: same as `va_score_fb_all.do` patterns plus `dk_` prefix for the deep-knowledge variants. `_lv` literal suffix.

**Inputs**: `$vaprojdir/data/va_samples_\`version'/out_\`sample'` (L75); also merges in test-score VA from `va_est_dta/va_<subject>_<sample>_sp_<va_ctrl>_ct.dta` (L180), so depends on prior `va_score_all.do` run.

**Sourced helpers / Calls**: same three includes (macros_va, drift_limit, macros_va_all_samples_controls).

**Path references that need updating in consolidation**: same families. All `$vaprojdir`.

**Stata version / non-trivial syntax**:

- `merge m:1 cdscode year using ..., nogen keep(1 3) keepusing(va_cfr_g11_\`subject')` (L180-181) — same as `va_out_all.do`.

**ssc/community packages used**: `vam`.

**Gotchas / non-obvious behavior**:

- L66, L89: same "Subject: \`subject'" display bug as in `va_out_all.do` — cosmetic only.
- L191: di displays "Subject: \`subject'" — same cosmetic issue, `subject` macro may not be set in the current loop (we're outside the inner subject loop at L191 but inside its body? Actually L191 is inside the `foreach outcome` loop but after the L179 inner subject loop ends at L184. The macro `subject` will hold "math" (last value from inner loop) — confusing but not breaking).
- The 4 "no-leave-out" vam calls (L84, L131, L193, L244) save no .ster — same pattern as `va_score_fb_all.do`.
- All `tv` and `score_r` reserved names are renamed after every vam call — verified.
- L233: " DK Forecast bias test ... \`subject' VA" — same `subject` issue (math leftover).

**Reference to paper outputs**: feeds `va_out_fb_test_tab.do` which builds the dta consumed in Table 3 (FB rows for enrollment VA).

**Notes / open questions**:

- DK FB tests are run but I don't see the DK FB results in the published main paper Tables 2/3 — Tables 2/3 list 4 FB test rows (l, s, a, d / score, sibling, ACS, distance). May be appendix or extra robustness. To verify by reading the table-build files in chunk 4+.

---

### File: do_files/sbac/va_score_sib_lag.do

**Owner**: Christina (Che) Sun (L7)
**Lines**: 150
**Purpose** (1-2 sentences): Robustness variant: estimates test-score VA using a "sibling-lag-as-leave-out" identifying strategy — lag-1 older sibling outcomes as controls, lag-2 older sibling outcomes as the FB leave-out. Single sample (`s`, the sibling sample) restricted further by `touse_sib_lag==1`.

**Loop structure**:

- `foreach version in v1 v2` (twice — once at L44 for VA estimation, once at L85 for FB test). Two SEPARATE outer loops.
- Inner: `foreach subject in ela math` (L47, L88).

**Sample restrictions applied**: `if touse_g11_\`subject'==1 & touse_sib_lag==1` (L48, L89).

**vam invocations**: 3 per (version, subject):

- L50-59: VA with sib_lag1 controls (saved to `va_<subject>_s_sp_sib1_ct.ster`)
- L91-99: VA with sib_lag1 controls (NOT saved — same spec as L50-59, re-run for residual variable creation)
- L112-122: VA with sib_lag1+sib_lag2 controls, leave-out for FB test (saved to `va_<subject>_s_sp_sib1_ct_sib2_lv.ster`)

**Output files written**:

- Estimates (`.ster`):
  - `vam/va_<subject>_s_sp_sib1_ct.ster` (L59)
  - `spec_test/spec_<subject>_s_sp_sib1_ct.ster` (L66)
  - `vam/va_<subject>_s_sp_sib1_ct_sib2_lv.ster` (L122)
  - `fb_test/fb_<subject>_s_sp_sib1_ct_sib2_lv.ster` (L131)
- Datasets:
  - `va_est_dta/va_<subject>_s_sp_sib1_ct.dta` (L76)
- Logs: `log_files/sbac/va_score_sib_lag.smcl` and `.log` (L22, L149-150).

**Filename naming pattern**: `va_<subject>_s_sp_sib1_ct[_sib2_lv].ster`. Sample is hardcoded as `s` (sibling sample); va_ctrl token is `sib1`; fb_var token is `sib2`.

**Inputs**: `$vaprojdir/data/va_samples_\`version'/score_s` (L48, L89).

**Sourced helpers / Calls**:

- `include macros_va.doh` (L36)
- `include drift_limit.doh` (L37)

(does NOT include `macros_va_all_samples_controls.doh` — doesn't need it since loops are hardcoded to sib_lag samples/controls.)

**Path references that need updating in consolidation**: same families as `va_score_all.do`.

**Stata version / non-trivial syntax**: standard. Uses `\`b_controls' \`sib_lag1_controls'` and `\`sib_lag2_controls'` from `macros_va.doh` (L188-197 of macros_va.doh).

**ssc/community packages used**: `vam`.

**Gotchas / non-obvious behavior**:

- L99: trailing `///` on `driftlimit(\`score_drift_limit') ///` followed by a BLANK LINE (L100), then `rename` (L101). This is a hanging continuation: the blank line after `///` may or may not concatenate properly — Stata typically ignores blank lines after `///`. **Same issue in `va_out_sib_lag.do` L97**. This works (Stata sees it as continuing to the next non-empty line which is the rename), but the rename is then attached as part of the vam command line — actually no, since vam terminates at the line after the option, with the blank line after `///` Stata closes the command. Need to verify experimentally; hanging `///` with blank line is brittle. Flagged.
- Actually re-reading: `vam ..., driftlimit(\`score_drift_limit') ///` with the next line being blank means Stata is waiting for continuation. Stata sees the blank line as the continuation, so the command ends at that point. `rename` then runs as a separate command. Works, but the trailing `///` is dead syntax — it should be just `driftlimit(...)` without `///`.
- L20 uses `cap log close _all` — defensive, good.
- The first vam call at L50-59 saves `.ster`; the second at L91-99 does not — duplicating the work. Same pattern as `va_score_fb_all.do`.
- Renames: L61-62 after L50; L101-102 after L91; L124-125 after L112. All 3 vam calls have proper renames. Good.

**Reference to paper outputs**: feeds `va_sib_lag_spec_fb_tab.do` which builds an alternate spec/FB table — likely an appendix table or robustness check.

**Notes / open questions**:

- Why split into TWO `foreach version in v1 v2` blocks (L44 and L85) when the loops have identical structure? Could be consolidated. Cosmetic.

---

### File: do_files/sbac/va_out_sib_lag.do

**Owner**: Christina (Che) Sun (L7)
**Lines**: 155
**Purpose** (1-2 sentences): Sibling-lag robustness variant for outcome (enrollment) VA. Mirrors `va_score_sib_lag.do` exactly, swapping `sbac_<subject>_z_score` for the enrollment outcomes.

**Loop structure**: identical structure to `va_score_sib_lag.do`:

- `foreach version in v1 v2` (L42, L83) — two separate outer loops
- `foreach outcome in enr enr_2year enr_4year` (L45, L86)

**Sample restrictions applied**: `if touse_g11_\`outcome'==1 & touse_sib_lag==1` (L46, L87).

**vam invocations**: 3 per (version, outcome):

- L48-57: VA with sib_lag1 controls (saved)
- L89-97: VA with sib_lag1 controls (NOT saved; re-run for residuals)
- L110-120: VA with sib_lag1+sib_lag2 controls (saved)

**Output files written**:

- Estimates:
  - `vam/va_<outcome>_s_sp_sib1_ct.ster` (L57)
  - `spec_test/spec_<outcome>_s_sp_sib1_ct.ster` (L64)
  - `vam/va_<outcome>_s_sp_sib1_ct_sib2_lv.ster` (L120)
  - `fb_test/fb_<outcome>_s_sp_sib1_ct_sib2_lv.ster` (L129)
- Datasets:
  - `va_est_dta/va_<outcome>_s_sp_sib1_ct.dta` (L74)
- Logs: `log_files/sbac/va_out_sib_lag.smcl` and `.log` (L22, L154-155).

**Filename naming pattern**: same as `va_score_sib_lag.do` with outcome substituted for subject.

**Inputs**: `$vaprojdir/data/va_samples_\`version'/out_s` (L46, L87).

**Sourced helpers / Calls**: macros_va, drift_limit.

**Path references that need updating in consolidation**: same families.

**Stata version / non-trivial syntax**: standard.

**ssc/community packages used**: `vam`.

**Gotchas / non-obvious behavior**:

- **L56, L97, L119: `driftlimit(\`score_drift_limit')` — but this is OUTCOME VA**, which by convention should use `out_drift_limit` (per `va_out_all.do` L77, etc.). This is a likely BUG: `va_out_sib_lag.do` uses the test-score drift limit for outcome VA. Whether this matters numerically depends on whether `score_drift_limit` and `out_drift_limit` evaluate to the same number — see Q4. As of `macros_va.doh` L35-65, `test_score_min_year`=2015, `test_score_max_year`=2018, `outcome_min_year`=2015, `outcome_max_year`=2018, so both evaluate to `max(2018-2015-1, 1) = max(2, 1) = 2`. So today the bug is BENIGN (same numeric value) but is SEMANTICALLY a bug. If the cohort window changes, this becomes a real bug.
- L60, L100, L123: variables renamed `sbac_g11_<outcome>_r` — the `sbac_` prefix is misleading for OUTCOME VA (`<outcome>` here is `enr`, `enr_2year`, `enr_4year`, not `ela`/`math`). Stylistic — variables are named `sbac_g11_enr_r` etc.
- Same hanging `///` pattern as `va_score_sib_lag.do` (L97).
- All renames present after each vam call.

**Reference to paper outputs**: feeds `va_sib_lag_spec_fb_tab.do`.

**Notes / open questions**:

- Confirmed `out_drift_limit.doh` is unused anywhere in chunk-3 files. The wrong-drift-limit-name bug here would have been caught if `out_drift_limit.doh` were the one that defined the outcome drift limit, but instead `drift_limit.doh` defines BOTH `score_drift_limit` AND `out_drift_limit` (see Q4). So `out_drift_limit.doh` is dead code.

---

### File: do_files/sbac/merge_va_est.do

**Owner**: Christina (Che) Sun (L6)
**Lines**: 121
**Purpose** (1-2 sentences): Merges all the per-(sample, va_ctrl) VA estimate `.dta` files (one for each combination produced by `va_score_all.do` and `va_out_all.do`) into a single per-outcome dta, then merges those into one master `va_all.dta`. Renames variables to encode (sample, va_ctrl, peer) in the variable name.

**Loop structure**:

- `foreach version in v1 v2` (L50)
- `foreach va_outcome in ela math enr enr_2year enr_4year` (L54)
- `foreach va_ctrl of local va_controls` (L59) — uses `va_controls = b l a s la ls as las bd ld ad sd lad lsd asd lasd`
- `foreach sample of local \`va_ctrl'_ctrl_samples` (L60)

**Sample restrictions applied**: none. Pure dataset merge operation.

**vam invocations**: 0.

**Output files written**:

- `va_est_dta/va_<va_outcome>_all.dta` (L82) — per-outcome consolidated
- `va_est_dta/va_all.dta` (L91) — master file with all five outcomes merged on (cdscode, year)
- Logs: `log_files/sbac/merge_va_est.smcl` and `.log` (L26, L120-121).

**Filename naming pattern**:

- Inputs: `va_<va_outcome>_<sample>_sp_<va_ctrl>_ct.dta`
- Renamed variables: `va_<va_outcome>_<sample>_sp_<va_ctrl>_ct` (no peer) and `va_<va_outcome>_<sample>_sp_<va_ctrl>_ct_p` (peer). For DK: `va_dk_<va_outcome>_<sample>_sp_<va_ctrl>_ct` and `..._ct_p`.

**Inputs**: every `va_<va_outcome>_<sample>_sp_<va_ctrl>_ct.dta` produced by chunk-3 score and outcome estimation files (L62, then L86-90 for the master merge).

**Sourced helpers / Calls**: `include macros_va.doh` (L41); `include macros_va_all_samples_controls.doh` (L43).

**Path references that need updating in consolidation**: all `$vaprojdir`-rooted as before.

**Stata version / non-trivial syntax**:

- L56-57: lazy initialization pattern using local macros that morph from "use" to "merge 1:1 cdscode year using" between iterations (L77-78). Clever — first iteration loads, subsequent iterations merge.
- L77-78: AFTER first iter, `merge_command` becomes `merge 1:1 cdscode year using` and `merge_options` becomes `nogen`. So the first call is `use ..., clear`, subsequent are `merge 1:1 cdscode year using ..., nogen`.

**ssc/community packages used**: none (base Stata).

**Gotchas / non-obvious behavior**:

- L56-57: `local merge_command use; local merge_options clear`. After the first `use` succeeds with the `, clear` option, the next iteration switches to `merge 1:1 ... using` with `nogen`. So syntax adapts implicitly. Works but is unusual.
- The `if "\`va_outcome'"=="enr"|"\`va_outcome'"=="enr_2year"|"\`va_outcome'"=="enr_4year"` block (L69-75) handles the DK rename — so DK columns are only renamed when looping over the enr* outcomes. Correct.
- L87-90: master merge uses `merge 1:1 cdscode year using` — assumes (cdscode, year) is unique. The collapse in `va_score_all.do` is `by(school_id cdscode grade year)` — multiple grades per (cdscode, year) would break this 1:1 merge. Since this project is grade 11 only, this should be fine, but should verify `grade==11` is enforced upstream.
- L62: every iteration overwrites the in-memory dataset with the next merged version. After the loop completes, current data has all (sample, va_ctrl) combinations as columns.
- The renames at L63-64 use `va_cfr_g11_\`va_outcome'` and `va_cfr_g11_\`va_outcome'_peer` — these are the variable names produced by `va_score_all.do` and `va_out_all.do` (after their renames).

**Reference to paper outputs**: produces inputs for `va_corr.do` (Table of correlations across specs) and likely the heterogeneity / pass-through analyses in chunk 4+ (`reg_out_va_all*.do` files outside this chunk).

**Notes / open questions**:

- The `va_dk_` prefix scheme means the master `va_all.dta` has columns like `va_dk_enr_2year_las_sp_las_ct_p` — this is a naming convention for downstream reg files to consume.

---

### File: do_files/sbac/va_corr.do

**Owner**: Christina Sun (L6)
**Lines**: 88
**Purpose** (1-2 sentences): Produces a `corr` correlation matrix among 8 specific VA estimate columns per outcome (4 sample-control combinations × 2 peer/no-peer). Diagnostic display only — no .dta output.

**Loop structure**:

- `foreach version in v1 v2` (L41)
- `foreach va_outcome in ela math enr enr_2year enr_4year` (L52)

**Sample restrictions applied**: none.

**vam invocations**: 0.

**Output files written**: none (diagnostic display in log only). Logs: `log_files/sbac/va_corr.smcl` and `.log` (L24, L87-88).

**Filename naming pattern**: N/A (no output files).

**Inputs**: `$vaprojdir/estimates/va_cfr_all_\`version'/va_est_dta/va_\`va_outcome'_all.dta` (L53) — depends on `merge_va_est.do` having been run.

**Sourced helpers / Calls**: `include macros_va.doh` (L34).

**Path references that need updating in consolidation**: `$vaprojdir/estimates/va_cfr_all_<version>/va_est_dta/va_<outcome>_all.dta`.

**Stata version / non-trivial syntax**: `#delimit ;` block for multi-line `di` (L55-63). `corr` command (L65-68) on 8 specific columns.

**ssc/community packages used**: none.

**Gotchas / non-obvious behavior**:

- L57: typo "ase sample" instead of "base sample" in the di string.
- L60: typo "ktichen" instead of "kitchen" (also appears in `va_spec_fb_tab.do` and other files — pattern).
- L82: "End date time: \`date2' \`time2'" — `date2` is NEVER assigned in this file (only `time2` at L79). Display will show empty `date2`. Cosmetic.
- L26: `graph drop _all` despite this file producing no graphs — defensive boilerplate copied across files.

**Reference to paper outputs**: not directly referenced. Producing `corr` output for the working log (verification that VA estimates across specs are highly correlated). The actual published correlation tables in the paper come from elsewhere (chunk 4+).

**Notes / open questions**: `date2` is undefined — minor display bug; doesn't affect correctness.

---

### File: do_files/sbac/va_score_spec_test_tab.do

**Owner**: Christina (Che) Sun (L6)
**Lines**: 206
**Purpose** (1-2 sentences): Builds a per-subject `.dta` summary table of the spec-test results (β=coef on shrunken VA in regression of residual on shrunken VA, with H0: β=1). Loads each saved spec_test `.ster`, runs `test _b[...] = 1`, and writes one row per (sample, va_ctrl, peer, predicted_score) combination using `regsave`. Also computes SD of VA two ways: empirically from the dta, and from the vam variance output (running vam with `data(variance)` for each spec).

**Loop structure**:

- `foreach version in v1 v2` (L58)
- `foreach subject in ela math` (L61)
- `foreach va_ctrl of local va_controls` (L65)
- `foreach sample of local \`va_ctrl'_ctrl_samples` (L68)

**Sample restrictions applied**: `if touse_g11_\`subject'==1` (L74) — only when re-running vam for variance.

**vam invocations**: 2 per iteration (both with `data(variance)`):

- L78-85: vam with `data(variance)` (no peer) — produces `var_class` matrix; SD is `sqrt(var_class[_N])`
- L94-102: vam with `data(variance)` (peer)

These are NOT for tv/score_r — they yield the variance decomposition, used for the `sd_vam` SD reported in paper Table 2 row 1.

**Output files written**:

- `tables/va_cfr_all_<version>/spec_test/spec_<subject>_all.dta` (L125, L133, L155, L164, L173). Single dta per (version, subject) accumulates 4 rows per (sample, va_ctrl): no-peer, peer, predicted-score-no-peer, predicted-score-peer.
- Logs: `log_files/sbac/va_score_spec_test_tab.smcl` and `.log` (L39, L205-206).

**Filename naming pattern**: `spec_<subject>_all.dta` (single output dta per subject).

**Inputs**:

- `$vaprojdir/data/va_samples_<version>/score_<sample>` (L74) — for SD via vam variance run
- `$vaprojdir/estimates/va_cfr_all_<version>/va_est_dta/va_<subject>_<sample>_sp_<va_ctrl>_ct.dta` (L107) — for empirical SD
- `$vaprojdir/estimates/va_cfr_all_<version>/spec_test/spec_<subject>_<sample>_sp_<va_ctrl>_ct.ster` (L120)
- `$vaprojdir/estimates/va_cfr_all_<version>/spec_test/spec_p_<subject>_<sample>_sp_<va_ctrl>_ct.ster` (L129)
- `$vaprojdir/estimates/va_cfr_all_<version>/va_est_dta/predicted_prior_score/va_<subject>_<sample>_sp_<va_ctrl>_ct.dta` (L138) — variant with predicted ELA scores
- `$vaprojdir/estimates/va_cfr_all_<version>/spec_test/predicted_prior_score/spec_<subject>_<sample>_sp_<va_ctrl>_ct.ster` (L150)
- `$vaprojdir/estimates/va_cfr_all_<version>/spec_test/predicted_prior_score/spec_p_<subject>_<sample>_sp_<va_ctrl>_ct.ster` (L159)

**Sourced helpers / Calls**: macros_va, macros_va_all_samples_controls, drift_limit (L49, L51, L52).

**Path references that need updating in consolidation**: same families plus the `predicted_prior_score/` subdirectory.

**Stata version / non-trivial syntax**:

- `regsave using ..., ci addlabel(pval, \`p_spec', sd_va, \`sd_va', sd_vam, \`sd_vam', va_control, \`va_ctrl', va_sample, \`sample', va_type, \`subject', peer_controls, 0, predicted_score, 0) \`append_macro'` — `regsave` is a community-contributed package that saves regression results as a dta with optional `addlabel` columns.
- `preserve` / `restore` (L75, L91) — used to preserve the loaded data while running the variance vam call, then restore for the second variance run.
- `xtset school_id year` (L110, L140) — sets panel structure but no panel-only command is run (just `sum`); seems unnecessary. Cosmetic.

**ssc/community packages used**: `regsave`. (`vam` for variance.)

**Gotchas / non-obvious behavior**:

- L107: AFTER the `restore` (L91) and the second variance vam (L94-102), the file does `use $vaprojdir/estimates/.../va_<subject>_<sample>_sp_<va_ctrl>_ct.dta, clear` — this throws away the restored sample dta. So the `restore` is partially wasted; it's there to ensure the second `vam` call has the original obs. This is correct but could be tightened.
- L126 `\`append_macro'` — first iteration is `replace` (L63), then switches to `append` (L170). Standard regsave accumulation pattern.
- L138: depends on a `predicted_prior_score/` subdirectory that is filled by some OTHER script (not in chunk 3). If those `.dta` and `.ster` files don't exist, this script fails. The CHANGE LOG entry "08/15/2024" suggests the predicted-score functionality was added later.
- L156, L165: the predicted-score branches set `sd_vam, -999` (sentinel) — meaning the SD-from-vam-variance is NOT computed for the predicted-score variants. Either deliberate or oversight. Flagged.
- The `sd_va_peer` macro is used at L134 with the predicted-score path on L156, and `sd_va` (from `va_cfr_g11_<subject>_peer`) on L147 — wait, re-reading: L143 sets `sd_va` from `va_cfr_g11_<subject>` (no peer), L147 sets `sd_va_peer` from `va_cfr_g11_<subject>_peer`. Both use predicted-prior-score data. Then L156 uses `sd_va`, L165 uses `sd_va_peer`. Consistent.
- Empirical sd (sd_va) is computed AFTER an `xtset` — weakly suspicious, but `sum` is unaffected.
- Multiple `restore`/`preserve` interactions with `use ... clear` patterns can be fragile.

**Reference to paper outputs**: feeds paper Table 2 row 1 (σ̂ from vam variance, "σ̂_λ" / SD of VA), row 2 (β-spec-test = coefficient on `va_cfr_g11_<subject>` in residual regression). The `sd_va` (empirical) and `sd_vam` (model) are both stored; paper uses one or the other.

**Notes / open questions**:

- Why both `sd_va` and `sd_vam`? Paper Table 2 reports σ̂_λ — likely `sd_vam` (model-based). To verify in chunk 4 build script.

---

### File: do_files/sbac/va_out_spec_test_tab.do

**Owner**: Christina Sun (L6)
**Lines**: 206
**Purpose** (1-2 sentences): Outcome-VA equivalent of `va_score_spec_test_tab.do`. Builds spec-test summary `.dta` for each enrollment outcome. Same structure: variance vam runs for SD_vam, empirical SD from dta, spec-test β from .ster.

**Loop structure**:

- `foreach version in v1 v2` (L59)
- `foreach outcome in enr enr_2year enr_4year` (L62)
- `foreach va_ctrl of local va_controls` (L66)
- `foreach sample of local \`va_ctrl'_ctrl_samples` (L69)

**Sample restrictions applied**: `if touse_g11_<outcome>==1` (L75).

**vam invocations**: 2 per iteration (both `data(variance)`):

- L79-86 (no peer)
- L94-102 (with peer)

**Output files written**:

- `tables/va_cfr_all_<version>/spec_test/spec_<outcome>_all.dta` (L127, L136, L153, L162, L168). Single dta per (version, outcome).
- Logs: L39, L205-206.

**Filename naming pattern**: `spec_<outcome>_all.dta`.

**Inputs**:

- `$vaprojdir/data/va_samples_<version>/out_<sample>` (L75)
- `va_est_dta/va_<outcome>_..._ct.dta` (L109)
- `spec_test/spec_<outcome>_..._ct.ster` (L122)
- `spec_test/spec_p_<outcome>_..._ct.ster` (L131)
- `va_est_dta/predicted_prior_score/va_<outcome>_..._ct.dta` (L140)
- `spec_test/predicted_prior_score/spec_<outcome>_..._ct.ster` (L148)
- `spec_test/predicted_prior_score/spec_p_<outcome>_..._ct.ster` (L157)

**Sourced helpers / Calls**: macros_va, macros_va_all_samples_controls, drift_limit (L49, L51, L52).

**Path references that need updating in consolidation**: same families.

**Stata version / non-trivial syntax**: same as score variant.

**ssc/community packages used**: `regsave`, `vam`.

**Gotchas / non-obvious behavior**:

- L154: passes `sd_va` to the predicted-score-no-peer call (correct).
- L163: passes `sd_va` to the predicted-score-PEER call — wait, this is the regsave for `peer_controls=1, predicted_score=1`, but it's adding `sd_va, \`sd_va'` not `sd_va, \`sd_va_peer'`. Compare to the score variant (`va_score_spec_test_tab.do` L165) where it correctly uses `sd_va_peer`. **This is a BUG**: the predicted-score peer row carries the no-peer SD value. Flagged in Q7.
- Also note: in this file (L139-163), the empirical peer SD `sd_va_peer` is NEVER computed for the predicted-score branch. The score-variant computes both at L143-147 (`sd_va` and `sd_va_peer`). The outcome-variant only computes `sd_va` at L144-145 — so even if L163 wanted to use `sd_va_peer`, the local doesn't exist. The bug is more correctly described as: **for the outcome predicted-score branch, the peer SD is never computed**, and L163 silently uses the no-peer SD. Flagged.
- L74-86: vam variance call, no peer, with `preserve` at L76.
- L92: `restore` then second variance vam call (L94-102) — same pattern as score variant.
- All other behavior parallel to `va_score_spec_test_tab.do`.

**Reference to paper outputs**: feeds paper Table 3 (`tab:va-enr-summary-statistics`) — outcome VA σ̂_λ and β-spec-test rows.

**Notes / open questions**:

- Same `predicted_prior_score/` subdirectory dependency as score variant.

---

### File: do_files/sbac/va_score_fb_test_tab.do

**Owner**: Christina (Che) Sun (L6)
**Lines**: 189
**Purpose** (1-2 sentences): Builds a per-subject `.dta` summary table of forecast-bias test results: F-test stat for the joint significance of leave-out vars, plus the regression β coefficient (and pval) from the FB test regression. Mirrors `va_score_spec_test_tab.do` but loads `fb_*.ster` files and runs F-tests on the `\`fb_var'_controls'` macros.

**Loop structure**:

- `foreach version in v1 v2` (L54)
- `foreach subject in ela math` (L57)
- `foreach va_ctrl of local va_controls_for_fb` (L61)
- `foreach fb_var of local \`va_ctrl'_ctrl_leave_out_vars` (L64)
- `foreach sample of local \`fb_var'_fb_\`va_ctrl'_samples` (L67)

**Sample restrictions applied**: none in this file (operates entirely on saved estimates).

**vam invocations**: 0.

**Output files written**:

- `tables/va_cfr_all_<version>/fb_test/fb_<subject>_all.dta` (L104, L113, L135, L142, L153, L166). Single dta per (version, subject).
- Logs: L34, L188-189.

**Filename naming pattern**: `fb_<subject>_all.dta`.

**Inputs**:

- `vam/va_<subject>_..._lv.ster` (L87)
- `vam/va_p_<subject>_..._lv.ster` (L94)
- `fb_test/fb_<subject>_..._lv.ster` (L101)
- `fb_test/fb_p_<subject>_..._lv.ster` (L110)
- `vam/predicted_prior_score/va_<subject>_..._lv.ster` (L119)
- `vam/predicted_prior_score/va_p_<subject>_..._lv.ster` (L126)
- `fb_test/predicted_prior_score/fb_<subject>_..._lv.ster` (L133)
- `fb_test/predicted_prior_score/fb_p_<subject>_..._lv.ster` (L140)

**Sourced helpers / Calls**: `include macros_va.doh` (L44); `include macros_va_all_samples_controls.doh` (L46). NOTE: does NOT include `drift_limit.doh` — that's fine because no vam estimation is done here.

**Path references that need updating in consolidation**: `$vaprojdir/estimates/va_cfr_all_<version>/{vam,fb_test}/[predicted_prior_score/]...`, plus `tables/va_cfr_all_<version>/fb_test/`.

**Stata version / non-trivial syntax**:

- L73-84: dynamic redefinition of the `<fb_var>_controls` macro to include the sibling indicator vars `1.has_older_sibling_enr_2year` and `1.has_older_sibling_enr_4year` for fb_vars `s`, `ls`, `as`, `las`. This is necessary because in the original `\`s_controls'` (from macros_va.doh L242-244, which is `\`sibling_controls'` = `i.has_older_sibling_enr_2year i.has_older_sibling_enr_4year`), the `i.var` form treats each level as a coefficient pair, so `test \`s_controls'` would actually test `i.has_older_sibling_enr_2year` levels — but the FB test typically wants a single F-stat for the leave-out-as-block. Using `1.has_older_sibling_enr_2year` ensures only the specific `1` level is tested.
- `regsave using ..., pval ci addlabel(...) \`append_macro'` (L104) — note the `pval ci` options.

**ssc/community packages used**: `regsave`.

**Gotchas / non-obvious behavior**:

- L51: `/* set trace on */` — commented out trace. L179: `set trace off` — uncommented; will run silently if trace is off (default), no harm.
- L73-84: the dynamic `if "\`fb_var'" == "..."` redefinitions OVERWRITE the macros that were defined in `macros_va.doh`. After the loop iteration runs, `\`s_controls'` for the rest of the program is the OVERWRITTEN version (1.has_older_sibling_enr_2year 1.has_older_sibling_enr_4year). If the loop iterates over multiple fb_vars per va_ctrl, by iteration 2, `\`s_controls'` has been mutated. This is fine because the if-blocks gate by current `fb_var`, but it's mutation-prone.
- L89: `test \`\`fb_var'_controls'` — double-deref `\`<fb_var>_controls'`. This expands to e.g. `test \`s_controls'` which (after the L73 mutation) becomes `test 1.has_older_sibling_enr_2year 1.has_older_sibling_enr_4year`. Correct.
- L121, L128: `test \`\`fb_var'_controls'` for the predicted-score variants — same logic.
- The dta accumulates 4 rows per iteration (no-peer, peer, predicted-no-peer, predicted-peer).

**Reference to paper outputs**: feeds paper Table 2 rows 3-6 (FB test β coefficients).

**Notes / open questions**:

- The dynamic-macro-redefinition trick (L73-84) is non-obvious and subtle. To preserve in consolidation.

---

### File: do_files/sbac/va_out_fb_test_tab.do

**Owner**: Christina (Che) Sun (L6)
**Lines**: 174
**Purpose** (1-2 sentences): Outcome-VA forecast-bias test summary table builder. Direct mirror of `va_score_fb_test_tab.do` for the three enrollment outcomes.

**Loop structure**: identical structure to the score variant:

- `foreach version in v1 v2` (L53)
- `foreach outcome in enr enr_2year enr_4year` (L56)
- `foreach va_ctrl of local va_controls_for_fb` (L60)
- `foreach fb_var of local \`va_ctrl'_ctrl_leave_out_vars` (L63)
- `foreach sample of local \`fb_var'_fb_\`va_ctrl'_samples` (L66)

**Sample restrictions applied**: none.

**vam invocations**: 0.

**Output files written**:

- `tables/va_cfr_all_<version>/fb_test/fb_<outcome>_all.dta` (L107, L116, L139, L146, L159, L171).
- **NO log close at end of file** — file ends with closing braces at L172-174 and no `log close` / `translate`. **BUG: missing log_close**. Compare to score variant L187-189.

**Filename naming pattern**: `fb_<outcome>_all.dta`.

**Inputs**:

- `vam/va_<outcome>_..._lv.ster` (L87)
- `vam/va_p_<outcome>_..._lv.ster` (L94)
- `fb_test/fb_<outcome>_..._lv.ster` (L104)
- `fb_test/fb_p_<outcome>_..._lv.ster` (L113)
- `vam/predicted_prior_score/va_<outcome>_..._lv.ster` (L122)
- `vam/predicted_prior_score/va_p_<outcome>_..._lv.ster` (L130)
- `fb_test/predicted_prior_score/fb_<outcome>_..._lv.ster` (L137)
- `fb_test/predicted_prior_score/fb_p_<outcome>_..._lv.ster` (L144)

**Sourced helpers / Calls**: macros_va (L45); macros_va_all_samples_controls (L47).

**Path references that need updating in consolidation**: same families as score variant.

**Stata version / non-trivial syntax**: same as score variant (dynamic macro redefinition L72-83).

**ssc/community packages used**: `regsave`.

**Gotchas / non-obvious behavior**:

- L72-83: same dynamic macro redefinition pattern as score variant.
- **L172-174 file ends WITHOUT `log close` or `translate`**: the score variant has these at L187-189; this file just stops. The .smcl log file remains open after run. Probably benign in interactive use but a real omission. Flagged in Q7.

**Reference to paper outputs**: feeds paper Table 3 rows 3-6.

**Notes / open questions**: Missing log close/translate is a real bug.

---

### File: do_files/sbac/va_spec_fb_tab.do

**Owner**: Christina Sun (L6)
**Lines**: 275
**Purpose** (1-2 sentences): Builds the actual published `.csv` (and presumably TeX downstream) tables combining spec test and forecast bias tests for each VA outcome (ELA, Math, enr, enr_2year, enr_4year). Loads specific `.ster` files (4 sample-control combinations × peer / no-peer = 8 model rows; plus 4 FB leave-out coefs per row), uses `eststo` and `esttab` to format.

**Loop structure**:

- `foreach version in v1 v2` (L43)
- `foreach va_outcome in ela math enr enr_2year enr_4year` (L54)
  - inner `foreach lovar in l s a las` (L66, L78) — 4 leave-out vars

**Sample restrictions applied**: none.

**vam invocations**: 0.

**Output files written**:

- `tables/va_cfr_all_<version>/combined/fb_spec_<va_outcome>.csv` (L245). One csv per (version, outcome).
- Logs: `log_files/sbac/va_spec_fb_tab.smcl` and `.log` (L28, L274-275).

**Filename naming pattern**: `fb_spec_<va_outcome>.csv` (output csv).

**Inputs**: 8 spec-test `.ster` and many fb-test `.ster` files. Specifically:

- 4 sample×control combos × {no-peer, peer} = 8 spec_test files:
  - `spec_<va_outcome>_b_sp_b_ct.ster` (L128) and `_p` variant L137
  - `spec_<va_outcome>_las_sp_b_ct.ster` (L151), `_p` L173
  - `spec_<va_outcome>_las_sp_ls_ct.ster` (L199), `_p` L212
  - `spec_<va_outcome>_las_sp_las_ct.ster` (L228), `_p` L236
- FB test files (only for the `las_sp_b_ct` and `las_sp_ls_ct` rows):
  - `fb_<va_outcome>_las_sp_b_ct_<lovar>_lv.ster` (L67) for lovar in {l, s, a, las}
  - `fb_p_<va_outcome>_las_sp_b_ct_<lovar>_lv.ster` (L79) — peer variant
  - `fb_<va_outcome>_las_sp_ls_ct_a_lv.ster` (L97); `fb_p_<va_outcome>_las_sp_ls_ct_a_lv.ster` (L107)

**Sourced helpers / Calls**: `include macros_va.doh` (L41).

**Path references that need updating in consolidation**: `$vaprojdir/estimates/va_cfr_all_<version>/{spec_test,fb_test}/...` and `$vaprojdir/tables/va_cfr_all_<version>/combined/`.

**Stata version / non-trivial syntax**:

- `est use` (community alias for `estimates use`) — loads each estimate set.
- `eststo <name>` — stores currently-loaded estimates with a label.
- `estadd local sample "..."` and `estadd scalar b_fb_score = ...` — attaches metadata to the stored estimate.
- `matrix b = e(b)` and `local b_..._lv: di %5.3f b[1,1]` — pulls coefficient into local for `estadd scalar`.
- `esttab` (L245): formatting options `nonumbers se(%4.3f) b(%5.3f) nostar nocons`, `scalars(...)`, `refcat(va_cfr_g11_<va_outcome> "Specification Test:" b_fb_score "Forecast Bias Test:")`. Uses `#delimit ;` block (L244-253).

**ssc/community packages used**: `estout` family (`est`, `eststo`, `esttab`, `estadd`).

**Gotchas / non-obvious behavior**:

- L66, L78: `foreach lovar in l s a las` — only 4 leave-out vars (l, s, a, las). The full leave-out var set in `macros_va_all_samples_controls.doh` includes `d` (distance) but `d` is NOT in this published-table loop. Question: paper Table 2/3 rows 3-6 are described as l, s, a, d (distance) in the paper map. The `las` lovar here is the joint test of all three — distinct from `d`. So this file is NOT producing the distance row. Distance must be added in a different table-build file or the paper Table 2/3 has `las` instead of `d` — to verify.
- L57: typo "ase sample" instead of "base sample" (in di string).
- L60: typo "ktichen" instead of "kitchen" (in di string).
- The 4 sample-control combinations encoded in this file:
  1. `b_sp_b_ct` (base sample, base control)
  2. `las_sp_b_ct` (las sample, base control)
  3. `las_sp_ls_ct` (las sample, leave-out-score-and-sibling control)
  4. `las_sp_las_ct` (las sample, kitchen-sink control)
  
  This matches paper columns 1-4 of Table 2/3 (or 1-5 if including a peer-controls-only column). The paper map says 5 cols (Base, Restricted, +peer, +ACS, +sibling+score, +distance). The 4 here × 2 peer/no-peer = 8 columns. Mapping:
  - Col 1 (Base) ⇄ b_sp_b_ct (no peer)
  - Col 2 (Restricted) ⇄ las_sp_b_ct (no peer)
  - Col 3 (+peer) ⇄ las_sp_b_ct_p
  - Col 4 (+ACS) ⇄ las_sp_ls_ct or las_sp_b_ct + ACS — to verify
  - Col 5 (+sibling, preferred) ⇄ las_sp_las_ct
  - Col 6 (+distance) — NOT produced by this file
- The b_sp and las_sp_las_ct rows do NOT have FB scalars added (L131-143, L229-242) because for the base spec there are no leave-out vars (`b` controls = no l/s/a; FB tests would require leave-outs). For las_sp_las_ct the only remaining lovar would be `d`, also not loaded here.
- The FB scalars `b_fb_score` etc. are scalars labeled by the leave-out var meaning: `_score` ⇄ lovar=l (loscore, the leave-out 7th-grade ELA), `_sibling` ⇄ lovar=s, `_acs` ⇄ lovar=a, `_score_acs_sibling` ⇄ lovar=las (joint test).
- L246: `nonumbers se(%4.3f) b(%5.3f) nostar nocons` — "nostar" suppresses significance stars. `nonumbers` removes column numbers.
- L247-249: `scalars(b_fb_score se_fb_score b_fb_sibling se_fb_sibling b_fb_acs se_fb_acs b_fb_score_acs_sibling se_fb_score_acs_sibling sample control peer)` — adds these eight FB-test rows + 3 metadata rows.
- L268: `Do file va_spec_fb_tab.do start date time: ...` — the `local date2 = c(current_date)` is set at L267. So both date1 and date2 are correctly assigned in this file (unlike `va_corr.do`). Good.

**Reference to paper outputs**: produces `tables/va_cfr_all_<version>/combined/fb_spec_<va_outcome>.csv` — one per outcome. CSVs are then converted to TeX downstream (chunk 4+) for paper Tables 2 and 3.

**Notes / open questions**:

- Distance leave-out (lovar `d`) is missing from this table. Either paper Table 2/3 row 6 is built elsewhere, or the published paper used `las` joint where I expected `d`. Open question.

---

### File: do_files/sbac/va_sib_lag_spec_fb_tab.do

**Owner**: Christina (Che) Sun (L8)
**Lines**: 139
**Purpose** (1-2 sentences): Builds spec-test and FB-test summary `.dta` files specifically for the sibling-lag robustness variant. Loads spec_test/fb_test `.ster` files produced by `va_score_sib_lag.do` and `va_out_sib_lag.do`, runs F-tests on `sib_lag2_controls`, and accumulates rows via `regsave`.

**Loop structure**:

- Two SEPARATE blocks: spec-test (L48-81) and fb-test (L89-124).
- Each: `foreach version in v1 v2`; `foreach va_outcome in ela math enr enr_2year enr_4year`.

**Sample restrictions applied**: none.

**vam invocations**: 0.

**Output files written**:

- `tables/va_cfr_all_<version>/spec_test/spec_sib_lag.dta` (L69, L76, L80)
- `tables/va_cfr_all_<version>/fb_test/fb_sib_lag.dta` (L110, L119, L123)
- Logs: `log_files/sbac/va_sib_lag_spec_fb_tab.smcl` and `.log` (L23, L138-139).

**Filename naming pattern**: `spec_sib_lag.dta` and `fb_sib_lag.dta`.

**Inputs**:

- `va_est_dta/va_<va_outcome>_s_sp_sib1_ct.dta` (L56)
- `spec_test/spec_<va_outcome>_s_sp_sib1_ct.ster` (L65)
- `vam/va_<va_outcome>_s_sp_sib1_ct_sib2_lv.ster` (L99)
- `fb_test/fb_<va_outcome>_s_sp_sib1_ct_sib2_lv.ster` (L108)

**Sourced helpers / Calls**: macros_va (L37); drift_limit (L38). Note: drift_limit is INCLUDED but never used in this file (no vam calls). Cosmetic.

**Path references that need updating in consolidation**: same families.

**Stata version / non-trivial syntax**: standard `regsave` accumulation pattern.

**ssc/community packages used**: `regsave`.

**Gotchas / non-obvious behavior**:

- L70: addlabel uses `p_value` (not `pval` like the other tab files). Inconsistent: other tab files use `pval`. The change-log header in `va_score_spec_test_tab.do` L26 explicitly says "03/02/2023: changed p value variable name to pval to be consistent with fb tables" — but this sibling-lag file was missed by that change. **Inconsistency bug**.
- L102: `test \`sib_lag2_controls'` — uses the macro from `macros_va.doh` L194-197 which is `old2_sib_enr_2year old2_sib_enr_4year` (no `i.` prefix), so test is straightforward.
- L19: header has both `cap log close _all` (L21) — defensive. Good.
- The two outer `foreach version` blocks (L48 and L89) duplicate boilerplate — could be consolidated.

**Reference to paper outputs**: produces sibling-lag robustness check tables. Likely an appendix table, not in main paper Tables 2/3.

**Notes / open questions**:

- p_value vs pval naming inconsistency.

---

### File: do_files/sbac/drift_limit.doh

**Lines**: 4 (3 lines of code, 1 blank).

**Content**:

```
local score_drift_limit = max(`test_score_max_year' - `test_score_min_year' - 1, 1)
local out_drift_limit = max(`outcome_max_year' - `outcome_min_year' - 1, 1)
```

**Defines**: BOTH `score_drift_limit` AND `out_drift_limit`.

**Behavior**: with `test_score_min_year=2015`, `test_score_max_year=2018`, `outcome_min_year=2015`, `outcome_max_year=2018` (per `macros_va.doh` L35-65), both evaluate to `max(3-1, 1) = max(2, 1) = 2`. So in the current configuration both have value 2. NOTE: `2018 - 2015 - 1 = 2`, not 3. Reading again: `max(test_score_max_year - test_score_min_year - 1, 1)` = `max(2018-2015-1, 1)` = `max(2, 1)` = **2**. So drift limit is 2 (years).

**Inclusion sites in chunk 3**: 9 files include this — see Q4 answer below.

**Notes / open questions**:

- Used in 9 of 14 chunk-3 files. Defines two locals: `score_drift_limit` and `out_drift_limit`.

---

### File: do_files/sbac/out_drift_limit.doh

**Lines**: 2 (1 line of code, 1 comment).

**Content**:

```
local drift_limit = max(`outcome_max_year' - `outcome_min_year' - 1, 1)
```

**Defines**: a local called `drift_limit` (no prefix).

**Inclusion sites in chunk 3**: ZERO. Verified by grep — `out_drift_limit.doh` is NEVER `include`d nor `do`'d by any of the 14 chunk-3 files.

**Notes / open questions**:

- This file appears to be DEAD CODE. The local `drift_limit` it defines does not match any name used in chunk 3 (which uses `score_drift_limit` and `out_drift_limit`). The file may be a leftover from an earlier iteration before the consolidated `drift_limit.doh` was authored.

---

## Synthesis

### Q1. Naming-convention tokens (sp, ct, nw, _m, _wt, _lv, _p, peer)

Verified against the actual chunk-3 source code:

- **`sp`** — LITERAL fixed token meaning "sample". Always appears as `_<sample>_sp_` in filenames, where `<sample>` is one of {b, l, a, s, la, ls, as, las, bd, ld, ad, sd, lad, lsd, asd, lasd, sib_lag} or, in sib_lag files, the literal `s_sp_sib1`. Example: `va_ela_b_sp_b_ct.ster` reads as "VA, ELA, sample=b, control=b". Verified at `va_score_all.do:80`, change log L18.

- **`ct`** — LITERAL fixed token meaning "control". Always appears as `_<va_ctrl>_ct[.ster|.dta|_<lv>_lv.ster]`. Example: `..._b_ct.ster` reads as "control=b". Verified at `va_score_all.do:80`, change log L19.

- **`_lv`** — LITERAL fixed token meaning "leave-out". Appears as `_<fb_var>_lv.ster` only in forecast-bias estimation files. Example: `va_ela_las_sp_b_ct_l_lv.ster` reads as "VA, ELA, sample=las, control=b, fb leave-out var=l". Verified at `va_score_fb_all.do:110`, change log L21.

- **`_p` infix** in filenames — meaning "peer-controls variant". Appears between the `va_` prefix and the subject/outcome: `va_p_<subject>_<sample>_sp_<va_ctrl>_ct.ster`. Example: `va_p_ela_b_sp_b_ct.ster`. Also `spec_p_`, `fb_p_`, `dk_va_p_`, `dk_fb_p_`. Verified throughout `va_score_all.do`, `va_out_all.do`, etc.

- **`_p` suffix** in variable names — has TWO MEANINGS depending on context:
  1. In forecast-bias residuals (`va_score_fb_all.do:114`), `_p` means "predicted" (the leave-out residual).
  2. In `merge_va_est.do:64`, `_p` means "peer" (the peer-control variant column).
  This is a real semantic conflict but the two meanings never coexist in the same dataset — flagged in Q7.

- **`peer` suffix** in variable names — means "peer-controls variant" inside a single-iteration scope (e.g. `va_cfr_g11_ela_peer` in `va_score_all.do:107`). After collapsing-and-saving to dta, the column is retained as `va_cfr_g11_ela_peer`. After `merge_va_est.do` runs (L64), it's renamed to `..._ct_p` (from `..._peer` to `_p`). So `_peer` is the in-script convention; `_p` is the merged-dataset convention.

- **`nw`** — NOT FOUND anywhere in chunk-3 files. Per the paper map, it appears in figure filenames like `va_ela_scatter_b_vs_las_sp_b_ct_v1_nw`. So `nw` must be defined in chunk-4+ figure-generation scripts, NOT in chunk-3 estimation files. Inferred meaning per paper map: "non-weighted" or "no-weight," to be confirmed in figure-script chunk.

- **`_m`** — NOT FOUND in chunk-3 files. Per paper map appears in `het_reg_*_m` figure filenames. Defined elsewhere.

- **`_wt`** — NOT FOUND in chunk-3 files. Per paper map appears in `corr_char_wt_v1` table names. Defined elsewhere; "wt" likely = "weighted".

So of the 7 tokens asked about, FOUR appear in chunk 3 (`sp`, `ct`, `_lv`, `_p`/`peer`) and THREE do NOT (`nw`, `_m`, `_wt`).

### Q2. Spec-test and FB-test β trace

Mapping paper Tables 2/3 rows to chunk-3 producer files. Paper Table 2 has rows: σ̂, β-spec-test, FB-test rows 3-6. The producers are:

| Paper Table 2/3 row | Producer file (estimation) | Output `.ster` consumed by | Final table builder |
|---|---|---|---|
| σ̂ (SD of VA) | `va_score_spec_test_tab.do:78-86` (vam variance call, no peer); `va_score_spec_test_tab.do:94-102` (peer) | (computed in same file via `local sd_vam: di sqrt(var_class[_N])`) | `va_score_spec_test_tab.do:125-134` regsave; consumed by `va_spec_fb_tab.do` (no — that file uses spec_test/spec_*.ster directly via `est use`) |
| β-spec-test (test b=1) | `va_score_all.do:86` reg sbac_..._r va_cfr..., cluster(school_id); save .ster L87 | `va_spec_fb_tab.do:128-243` `est use spec_<va_outcome>_..._ct.ster; eststo` | `va_spec_fb_tab.do:245` esttab to csv |
| β-FB-test, leave-out=l (loscore) | `va_score_fb_all.do:119` reg sbac_..._r_d va_cfr..., cluster(school_id); save .ster L120 | `va_score_fb_test_tab.do:101` regsave; ALSO `va_spec_fb_tab.do:67-74` `est use fb_<va_outcome>_las_sp_b_ct_l_lv.ster` | `va_spec_fb_tab.do:159-160 estadd; L245 esttab` |
| β-FB-test, leave-out=s (sibling) | `va_score_fb_all.do:119` (with fb_var=s) | same as above | same |
| β-FB-test, leave-out=a (ACS) | `va_score_fb_all.do:119` (with fb_var=a); ALSO `va_score_fb_all.do:119` (with fb_var=a) when loaded from `las_sp_ls_ct_a_lv` | `va_spec_fb_tab.do:97-103` (las_sp_ls_ct_a_lv) | same |
| β-FB-test, leave-out=d (distance) | `va_score_fb_all.do:119` (with fb_var=d) | NOT loaded by `va_spec_fb_tab.do` (which only loops over l, s, a, las for FB) | distance FB row likely produced elsewhere or omitted from this table builder |

**FB-test fb_var values found in chunk 3**: confirmed via `macros_va_all_samples_controls.doh`:

- `b_ctrl_leave_out_vars`: `l a s la ls as las d` (8 values)
- `l_ctrl_leave_out_vars`: `a s as d` (4)
- `a_ctrl_leave_out_vars`: `l s ls d` (4)
- `s_ctrl_leave_out_vars`: `l a la d` (4)
- `ls_ctrl_leave_out_vars`: `a d` (2)
- `la_ctrl_leave_out_vars`: `s d` (2)
- `as_ctrl_leave_out_vars`: `l d` (2)
- `las_ctrl_leave_out_vars`: `d` (1)

Plus `*_scrhat_leave_out_vars` (predicted-score variants) — same overall set minus some redundant cases.

The estimation file `va_score_fb_all.do:66` iterates `foreach fb_var of local \`va_ctrl'_ctrl_leave_out_vars`, so the fb_var values it iterates over depend on va_ctrl. The full set across all va_ctrl is `{l, a, s, la, ls, as, las, d}`. (8 distinct fb_var values.)

The published Table 2/3 only uses 4 leave-out specs (l, s, a, d per paper map) — and `va_spec_fb_tab.do` only loads `{l, s, a, las}` (the `las` is the joint, not the 4-d-only). So the table's "row 6" is either `las` (joint of l+s+a — see `va_spec_fb_tab.do:66`) or `d` (distance, NOT loaded by that file). **This is an inconsistency between paper claim and code that needs resolution downstream**.

### Q3. Pass-through ρ producer (paper Table 4)

Paper Table 4 (`tab:va-persistence`, file `persistence_single_subject.tex`) regresses college enrollment on test-score VA (the pass-through ρ).

**Not produced in chunk 3.** Verified by grepping all 14 chunk-3 files for "persistence", "single_subject", or any pass-through regression specification — zero hits. Chunk 3 produces:

- The `va_<subject>_..._ct.dta` and `va_<outcome>_..._ct.dta` school-year level files (in `va_est_dta/`)
- The merged `va_all.dta` (via `merge_va_est.do`)

These are the INPUTS to the pass-through regression but the regression itself is not in chunk 3. Likely producer: `cde_va_project_fork/do_files/sbac/reg_out_va_all.do` or `reg_out_va_all_tab.do` (the names in the directory listing) — defer to the chunk that contains those.

### Q4. drift_limit usage audit

`drift_limit.doh` (the shared file) is `include`d in 9 of 14 chunk-3 files:

| File | Line | Used? |
|---|---|---|
| va_score_all.do | 47 | yes — `score_drift_limit` at L79, L104 |
| va_out_all.do | 46 | yes — `out_drift_limit` at L77, L101, L142, L167 |
| va_score_fb_all.do | 47 | yes — `score_drift_limit` at L90, L109, L140, L162 |
| va_out_fb_all.do | 48 | yes — `out_drift_limit` at L91, L110, L139, L161, L202, L224, L254, L278 |
| va_score_sib_lag.do | 37 | yes — `score_drift_limit` at L58, L99, L121 |
| va_out_sib_lag.do | 37 | **uses `score_drift_limit` at L56, L97, L119** — should be `out_drift_limit`. Numerically benign in current config (both = 2) but semantically wrong. |
| va_score_spec_test_tab.do | 52 | yes — `score_drift_limit` at L85, L102 |
| va_out_spec_test_tab.do | 52 | yes — `out_drift_limit` at L86, L102 |
| va_sib_lag_spec_fb_tab.do | 38 | included but no vam call — local goes unused (cosmetic) |

**`out_drift_limit.doh` is NEVER include'd.** It's dead code.

**Drift-limit value**: with `test_score_min_year=2015`, `test_score_max_year=2018`, `outcome_min_year=2015`, `outcome_max_year=2018`: both `score_drift_limit` and `out_drift_limit` evaluate to `max(2018 - 2015 - 1, 1) = 2`.

### Q5. Reserved-name handling (vam tv / score_r)

vam reserved names are `tv` and `score_r` (per the prompt). The audit pattern is: every `vam` invocation that uses `data(merge tv score_r)` MUST be followed by `rename tv ...` and `rename score_r ...`, otherwise the next vam invocation in the same iteration's scope would silently overwrite the previous estimates.

vam invocations using `data(variance)` (`va_score_spec_test_tab.do:78`, `:94`; `va_out_spec_test_tab.do:79`, `:94`) do NOT produce `tv`/`score_r` and don't need renames. These 4 are exempt.

vam invocations using `data(merge tv score_r)` and their renames:

| File | vam line | rename tv line | rename score_r line | Status |
|---|---|---|---|---|
| va_score_all.do | 72 | 82 | 83 | OK |
| va_score_all.do | 96 | 107 | 108 | OK |
| va_out_all.do | 70 | 80 | 81 | OK |
| va_out_all.do | 93 | 104 | 105 | OK |
| va_out_all.do | 133 | 145 | 146 | OK |
| va_out_all.do | 157 | 171 | 172 | OK |
| va_score_fb_all.do | 83 | 92 | 93 | OK |
| va_score_fb_all.do | 101 | 113 | 114 | OK |
| va_score_fb_all.do | 132 | 143 | 144 | OK |
| va_score_fb_all.do | 153 | 165 | 166 | OK |
| va_out_fb_all.do | 84 | 93 | 94 | OK |
| va_out_fb_all.do | 102 | 113 | 114 | OK |
| va_out_fb_all.do | 131 | 141 | 142 | OK |
| va_out_fb_all.do | 152 | 164 | 165 | OK |
| va_out_fb_all.do | 193 | 204 | 205 | OK |
| va_out_fb_all.do | 214 | 228 | 229 | OK |
| va_out_fb_all.do | 244 | 256 | 257 | OK |
| va_out_fb_all.do | 267 | 281 | 282 | OK |
| va_score_sib_lag.do | 50 | 61 | 62 | OK |
| va_score_sib_lag.do | 91 | 101 | 102 | OK |
| va_score_sib_lag.do | 112 | 124 | 125 | OK |
| va_out_sib_lag.do | 48 | 59 | 60 | OK |
| va_out_sib_lag.do | 89 | 99 | 100 | OK |
| va_out_sib_lag.do | 110 | 122 | 123 | OK |

**All 24 vam invocations with `data(merge tv score_r)` are followed by both `rename tv` and `rename score_r`.** No silent-overwrite vulnerability detected.

I did NOT find any vam calls referencing `tv_2yr_l`, `tv_2yr_f`, or `tv_ss` (the other 3 reserved names mentioned in the prompt) in any chunk-3 file. Those reserved names are produced by vam only when specific options (e.g., `bypass`/`leaveout` family) are used; they don't appear in this codebase's vam calls.

### Q6. Spec-test β estimator location

The spec-test estimator regresses school-year residuals on shrunken VA, clustered at school_id, and tests coef = 1. Producer lines:

| File | Line | Estimator |
|---|---|---|
| va_score_all.do | 86 | `reg sbac_g11_\`subject'_r va_cfr_g11_\`subject', cluster(school_id)` (no peer) |
| va_score_all.do | 111 | `reg sbac_g11_\`subject'_r_peer va_cfr_g11_\`subject'_peer, cluster(school_id)` (peer) |
| va_out_all.do | 84 | `reg g11_\`outcome'_r va_cfr_g11_\`outcome', cluster(school_id)` |
| va_out_all.do | 108 | `reg g11_\`outcome'_r_peer va_cfr_g11_\`outcome'_peer, cluster(school_id)` |
| va_out_all.do | 149 | `reg g11_\`outcome'_dk_r va_cfr_g11_\`outcome'_dk, cluster(school_id)` (DK no-peer) |
| va_out_all.do | 175 | `reg g11_\`outcome'_dk_r_peer va_cfr_g11_\`outcome'_dk_peer, cluster(school_id)` (DK peer) |
| va_score_sib_lag.do | 65 | `reg sbac_g11_\`subject'_r va_cfr_g11_\`subject', cluster(school_id)` |
| va_out_sib_lag.do | 63 | `reg sbac_g11_\`outcome'_r va_cfr_g11_\`outcome', cluster(school_id)` |

Spec-test β is then loaded for `test _b[...] = 1` in:

- `va_score_spec_test_tab.do:121, 130, 151, 160`
- `va_out_spec_test_tab.do:123, 132, 149, 158`
- `va_sib_lag_spec_fb_tab.do:66`

### Q7. Bugs / typos / anomalies inventory

| # | File | Line | Issue | Severity |
|---|---|---|---|---|
| 1 | va_out_all.do | 176 | Filename literal ends in `_cts.ster` instead of `_ct.ster` for `dk_spec_p_<outcome>_<sample>_sp_<va_ctrl>_cts.ster` | Real bug — file is written under wrong name; downstream consumers expecting `_ct.ster` won't find it. The matching downstream file `va_out_spec_test_tab.do` doesn't load `dk_spec_p_*` so the bug is currently silent, but any future consumer or audit will fail. |
| 2 | va_out_sib_lag.do | 56, 97, 119 | Uses `\`score_drift_limit'` for OUTCOME VA where `\`out_drift_limit'` is conventional. Numerically equal in current config (both = 2) but semantically wrong | Latent bug; will become an active bug if cohort window changes asymmetrically |
| 3 | va_out_fb_test_tab.do | 172-174 | File ends without `log close` or `translate` (compare score variant L187-189) | Real bug — log handle leaks |
| 4 | va_out_spec_test_tab.do | 163 | Predicted-score peer row uses `\`sd_va'` instead of `\`sd_va_peer'` (SD of no-peer estimates carried into the peer row's metadata). Note `sd_va_peer` for the predicted-score branch is never computed in this file (no `sum va_cfr_g11_<outcome>_peer` for predicted-score data) — compare score variant `va_score_spec_test_tab.do:147` which DOES compute it | Real bug — wrong SD reported for outcome predicted-score peer cells. |
| 5 | va_corr.do | 82 | `local date2` is never assigned; di prints empty string | Cosmetic |
| 6 | va_corr.do | 57 | Typo: "ase sample" should be "base sample" in di string | Cosmetic |
| 7 | va_corr.do | 60 | Typo: "ktichen" should be "kitchen" in di string | Cosmetic |
| 8 | va_spec_fb_tab.do | 57, 60 | Same typos: "ase sample", "ktichen" | Cosmetic |
| 9 | va_spec_fb_tab.do | 66, 78 | Loop iterates `lovar in l s a las` — `d` (distance) leave-out is NOT loaded into the published spec/FB table; if paper Table 2/3 row 6 is the `d` (distance) row, this file does not produce it. | Possible content gap |
| 10 | va_score_sib_lag.do | 99-100; va_out_sib_lag.do | 97-98 | Hanging `///` followed by blank line at end of vam call (just before next `rename`); works in Stata but is brittle | Cosmetic |
| 11 | va_score_fb_all.do, va_score_fb_test_tab.do | various | The dynamic redefinition of `\`<fb_var>_controls'` macros at fb_test_tab L73-84 mutates macros defined upstream in `macros_va.doh`. Within-iteration this is correct, but across iterations the macros stay mutated | Smell — works correctly given current loop order, but fragile |
| 12 | va_sib_lag_spec_fb_tab.do | 70 | `addlabel(p_value, ...)` uses variable name `p_value`, while all other spec/fb tables use `pval`. Per change log, `pval` is intentional. | Real inconsistency bug |
| 13 | va_out_all.do | 66, 89, 131, 155 | `di "Subject: \`subject'"` inside the OUTCOME loop where `subject` macro is unset (residual from prior loop or empty) | Cosmetic — display only |
| 14 | va_out_fb_all.do | 191, 233, 285 | Same `subject` display issue as #13 | Cosmetic |
| 15 | va_out_all.do | 120-122 | `touse_g11_\`outcome'_\`subject'` flags computed but never used after creation | Dead code |
| 16 | va_out_all.do | 189 | Label has stray apostrophe: `with \`va_ctrl'' controls` | Cosmetic |
| 17 | out_drift_limit.doh | entire | Never `include`d anywhere in chunk 3 | Dead file |
| 18 | va_score_fb_test_tab.do | 51, 179 | `/* set trace on */` (commented) and `set trace off` (uncommented). The `set trace off` is dead — trace was never on. | Cosmetic |
| 19 | va_sib_lag_spec_fb_tab.do | 38 | `include drift_limit.doh` but no vam call uses the locals | Cosmetic — unused inclusion |
| 20 | merge_va_est.do | 87-90 | Master merge uses `merge 1:1 cdscode year using` — assumes (cdscode, year) is unique. Project is grade-11-only; this should be safe, but no explicit `keep if grade==11` is present. | Latent bug — depends on upstream sample construction |
| 21 | Variable `_p` semantic conflict | va_score_fb_all.do:114 vs merge_va_est.do:64 | `_p` means "predicted (leave-out)" in fb_all but "peer" in merge_va_est. Two meanings never coexist in a single dataset, but is confusing | Smell |

### Output-filename construction grammar (formalized)

Across all chunk-3 estimation files, the filename grammar is:

```
<prefix>_[p_][dk_][va_]<outcome>_<sample>_sp_<va_ctrl>_ct[_<fb_var>_lv].ster
```

Where:

- `<prefix>` ∈ {`va`, `spec`, `fb`} (or `dk_va`, `dk_spec`, `dk_fb` for deep-knowledge variants)
- `_p_` (literal infix) — appears immediately after the prefix word for peer-controls variants (e.g., `va_p_`, `spec_p_`, `fb_p_`)
- `dk_` (literal prefix) — for deep-knowledge variants of OUTCOME-VA only; `dk_va_`, `dk_spec_`, `dk_fb_`
- `<outcome>` — one of {ela, math, enr, enr_2year, enr_4year}
- `<sample>` — one of {b, l, a, s, la, ls, as, las, bd, ld, ad, sd, lad, lsd, asd, lasd, sib_lag} (full set)
- `_sp_` — literal token (sample marker)
- `<va_ctrl>` — one of {b, l, a, s, la, ls, as, las, bd, ld, ad, sd, lad, lsd, asd, lasd, sib1}
- `_ct` — literal token (control marker)
- `_<fb_var>_lv` — optional, only for FB-test estimation files; `<fb_var>` ∈ {l, a, s, la, ls, as, las, d, sib2}
- `_lv` — literal token (leave-out marker)

For dataset (`.dta`) files the same grammar applies. For collapsed-master files: `va_<outcome>_all.dta` (after merge_va_est) or the simpler `va_all.dta`.

Special fixed-suffix file: `dk_spec_p_<outcome>_<sample>_sp_<va_ctrl>_cts.ster` (the typo at `va_out_all.do:176` — should be `_ct.ster`).

Sib-lag variants follow a fixed pattern: `va_<outcome>_s_sp_sib1_ct[_sib2_lv].ster`. Note `sib1` is the va_ctrl token, `sib2` is the fb_var token; `s` is the sample token (sibling sample).

### Open questions

1. **Distance leave-out (lovar `d`) FB test row** — produced in `va_score_fb_all.do` and `va_out_fb_all.do` but NOT loaded by `va_spec_fb_tab.do` (which only iterates l, s, a, las). Is paper Table 2/3 row 6 actually the `d` row, or is it `las` (joint)? Need to read the published TeX for tables 2/3 or chunk-4 table-conversion script.

2. **Paper map says 5-6 columns in Table 2/3, code emits 8** — `va_spec_fb_tab.do` produces 8 model columns (4 sample-control combos × peer/no-peer). Paper map describes 5 columns (Base, Restricted, +peer, +ACS, +sibling-score, +distance). Mapping may be: paper col 3 = las_sp_b_ct_p, col 4 = las_sp_ls_ct (no peer)? — needs cross-check with the .csv → .tex conversion in chunk 4+.

3. **Pass-through ρ regression (paper Table 4)** — not produced in chunk 3. Defer to chunk containing `reg_out_va_all*.do`.

4. **`predicted_prior_score/` subdirectory** — chunk-3 spec_test_tab and fb_test_tab files load files from this subdirectory but no chunk-3 file PRODUCES them. The producer must live in another chunk (likely a "predicted-prior-score" estimation script).

5. **Drift-limit asymmetry** — `va_out_sib_lag.do` uses `score_drift_limit`; in current config this is identical numerically to `out_drift_limit`. If the paper's cohort window asymmetrizes, this becomes a real bug. Decision: should consolidation fix the name (recommended) or leave for backwards compatibility?

6. **`out_drift_limit.doh`** — dead file. Safe to delete in consolidation? (recommend yes.)

7. **The `_p` two-meaning convention** (predicted vs peer) — is the merger of these conventions in `merge_va_est.do:64` a deliberate choice (peer wins because that's what's persisted to dta), and the within-script `_p` for "predicted" is just temp variable naming? If so, fine — but consolidation should document this.

8. **DK FB test results** — produced in `va_out_fb_all.do` but I don't see them surfaced in main paper Tables 2/3. Likely an appendix or robustness table; verify in chunk 4+.

---

End of chunk-3 verification audit.
