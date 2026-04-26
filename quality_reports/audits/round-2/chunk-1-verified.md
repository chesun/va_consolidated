# Chunk 1 Verified — Foundation (settings, master/do_all, macros_va, vam.ado)

**Round:** 2 (independent blind verification)
**Date:** 2026-04-24
**Scope:** Foundation files: 2 settings.do + 2 entry-points (do_all.do, master.do) + macros_va.doh + every file under `caschls/do/ado/`.
**Sequester:** Did NOT read anything under `quality_reports/audits/round-1/`.
**Contamination disclosure:** While reading `round-2/README.md` (which I was permitted to look at to understand my own protocol) I incidentally saw a "Pre-flight" section reporting a Bug 93 verdict from a different chunk (chunk-10, NSC crosswalk). That bug is outside the present chunk's scope and I have not used it. All findings below are derived from primary-source reads of the 6+ files listed above.

---

## File inventory

### `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/ado/`

```
drwxr-xr-x  server_vam/         (subdirectory)
-rw-r--r--  vam.ado             26418 bytes, 763 lines, modified 2026-04-25 18:41

server_vam/:
-rw-r--r--  vam.ado             26185 bytes, 760 lines, modified 2026-04-25 18:31
```

Only one .ado file at the top level (`vam.ado`); `server_vam/` is a sibling directory containing a second copy (`server_vam/vam.ado`). No other .ado files exist in this tree.

### Line counts (all 7 in-scope files)

| File | Lines |
|---|---|
| `cde_va_project_fork/do_files/settings.do` | 52 |
| `caschls/do/settings.do` | 53 |
| `cde_va_project_fork/do_files/do_all.do` | 270 |
| `caschls/do/master.do` | 633 |
| `cde_va_project_fork/do_files/sbac/macros_va.doh` | 612 |
| `caschls/do/ado/vam.ado` | 763 |
| `caschls/do/ado/server_vam/vam.ado` | 760 |

---

## File entries

### File: `/Users/christinasun/github_repos/cde_va_project_fork/do_files/settings.do`

**Predecessor repo:** cde_va_project_fork
**Owner** (from header): "Che Sun. Email: ucsun@ucdavis.edu" (L5)
**Lines:** 52
**Purpose:** Defines the global path macros for the common_core_va project on the Scribe server. Sourced by `do_all.do` (L8) and by `caschls/do/master.do` indirectly (see below).

**Globals defined:**

| Line | Global | Value |
|---|---|---|
| 12 | `rawcsvdir` | `/home/research/ca_ed_lab/data/restricted_access/raw/calschls/csv` |
| 16 | `rawdtadir` | `/home/research/ca_ed_lab/data/restricted_access/raw/calschls/stata` |
| 20 | `clndtadir` | `/home/research/ca_ed_lab/data/restricted_access/clean/calschls` |
| 25 | `projdir` | `/home/research/ca_ed_lab/users/chesun/gsr/caschls` |
| 28 | `vaprojdir` | `/home/research/ca_ed_lab/projects/common_core_va` |
| 31 | `vadtadir` | `/home/research/ca_ed_lab/projects/common_core_va/data/sbac` |
| 35 | `cstdtadir` | `/home/research/ca_ed_lab/data/restricted_access/clean/cde/cst` |
| 39 | `nscdtadir` | `/home/research/ca_ed_lab/data/restricted_access/clean/cde_nsc` |
| 42 | `nscdtadir_oldformat` | `/home/research/ca_ed_lab/data/restricted_access/clean/cde_nsc/oldformat` |
| 45 | `mattxwalks` | `/home/research/ca_ed_lab/users/msnaven/data/restricted_access/clean/crosswalks` |
| 49 | `vaprojxwalks` | `/home/research/ca_ed_lab/projects/common_core_va/data/restricted_access/clean/crosswalks` |
| 52 | `distance_dtadir` | `/home/research/ca_ed_lab/projects/common_core_va/data/k12_postsec_distance` |

**Macros defined:** N/A (no `local` macros — this is a globals-only file).
**Inputs / Outputs:** N/A (declares paths, no I/O).
**Sourced helpers:** none.
**Calls:** none.

**Path references that need updating in consolidation:** all 12 globals above. The critical observation is that `$projdir` (L25) and `$vaprojdir` (L28) point to **different absolute paths** — `chesun/gsr/caschls` vs `projects/common_core_va`. This means `do_all.do` (in the cde_va_project_fork tree) and `master.do` (in the caschls tree) are intended to coexist on the Scribe server in two separate directories.

**Stata version / non-trivial syntax:** none — pure `global` statements.
**Packages used:** none.
**Gotchas:**

- L8: header comment misspells "IMPORTANT" as "IMPORTAMT" (cosmetic, also present in caschls copy).
- The same physical filename `settings.do` appears in both predecessor repos; they are byte-near-identical (see Q1 below). Distinguishing them requires the parent path — a hazard during consolidation because `do "settings.do"` resolves to whichever lives in the working directory.

**Reference to paper outputs:** Indirect — every downstream output that uses `$vaprojdir`, `$vadtadir`, `$nscdtadir`, etc. depends on these globals. Per the paper map, this includes essentially all VA-pipeline outputs (test-score VA, outcome VA, NSC merges, distance controls).

**Notes / open questions:** none.

---

### File: `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/settings.do`

**Predecessor repo:** caschls
**Owner** (from header): "Che Sun. Email: ucsun@ucdavis.edu" (L5)
**Lines:** 53
**Purpose:** Same purpose as above. Sourced by `master.do` (L52: `do "./do/settings.do"`).

**Globals defined:** Identical set and identical values to `cde_va_project_fork/do_files/settings.do` (verified by `diff`). All 12 globals listed above.

**Diff result vs cde_va_project_fork/do_files/settings.do:**
```
43a44
> 
```
The only difference is one extra blank line after L43 (`global nscdtadir_oldformat ...`) in the caschls copy. Otherwise byte-identical. The two copies are effectively redundant.

**Inputs / Outputs / Sourced helpers / Calls:** all N/A.
**Path references:** identical to above table.
**Stata version / packages:** none.

**Gotchas:**

- The two files are 99.5% identical but live in two repos. There is no `include` or `do` cross-reference between them. Each repo's master sources its own local copy. This is a maintenance hazard: any drift between them goes undetected.

**Reference to paper outputs:** Indirect, via `$projdir` references in `master.do` block-graph (especially the survey-analysis subtree under `do/share/...`).

**Notes / open questions:** none.

---

### File: `/Users/christinasun/github_repos/cde_va_project_fork/do_files/do_all.do`

**Predecessor repo:** cde_va_project_fork
**Owner** (from header): not declared explicitly. Header comment block at L1-4 just gives invocation instructions. CHANGE LOG (L11-13) credits "do files that match sibling from the master.do in caschls repo" — implies authored by Che Sun.
**Lines:** 270
**Purpose:** Top-level entry point for the common_core_va project. Sets up environment, optionally installs SSC packages, and dispatches block-toggled groups of do-files for ACS, school characteristics, distance, sample creation, VA estimation, share tables, VA heterogeneity, and survey analysis.

**Globals defined:** none (this file consumes globals; settings.do defines them).

**Macros defined:**

| Line | Local | Value |
|---|---|---|
| 29 | `date1_do_all` | `c(current_date)` (timer start) |
| 30 | `time1_do_all` | `c(current_time)` |
| 35 | `installssc` | 0 |
| 65 | `clean_acs` | 0 |
| 72 | `clean_sch_char` | **1** (active) |
| 104 | `do_distance` | 0 |
| 110 | `do_touse_va` | 0 |
| 121 | `do_match_siblings` | 0 |
| 148 | `do_create_samples` | 0 |
| 164 | `do_va` | 0 |
| 220 | `do_share_tables` | 0 |
| 238 | `do_va_het` | **1** (active) |
| 251 | `do_survey` | 0 |
| 261 | `date2_do_all` | `c(current_date)` (timer end) |
| 262 | `time2_do_all` | `c(current_time)` |

**Toggle states as committed:** only `clean_sch_char=1` (L72) and `do_va_het=1` (L238) are on; every other block is off.

**Inputs (datasets `use`'d):** none (this file is pure dispatch — no `use`).
**Outputs (datasets `save`'d):** none directly.

**Sourced helpers (.doh files):** none directly. Helpers are invoked from the called .do files.

**Calls (other do-files via `do`):**

L8: `do do_files/settings.do` (relative path; cwd already set to `$vaprojdir` at L7)

The block-by-block call graph (using the `local <toggle>=1` form):

| Block (toggle, line) | Calls |
|---|---|
| `clean_acs` (L65) | L67: `do $vaprojdir/do_files/acs/clean_acs_census_tract` |
| `clean_sch_char` (L72) | L75: `cds_nces_xwalk.do`; L78: `clean_locale.do`; L80: `clean_elsch.do`; L82: `clean_enr.do`; L84: `clean_frpm.do`; L86: `clean_staffcred.do`; L88: `clean_staffdemo.do`; L90: `clean_staffschoolfte.do`; L92: `clean_charter.do`; L94: `clean_ecn_disadv.do`; L97: `clean_sch_char.do` (all under `$vaprojdir/do_files/schl_chars/`) |
| `do_distance` (L104) | L106: `k12_postsec_distances.do`; L107: `reconcile_cdscodes.do` (under `$vaprojdir/do_files/k12_postsec_distance/`) |
| `do_touse_va` (L110) | L112: `do do_files/sbac/touse_va.do` (relative path, not `$vaprojdir`) |
| `do_match_siblings` (L121) | L126: `$projdir/do/share/siblingxwalk/siblingmatch`; L131: `$projdir/do/share/siblingxwalk/uniquefamily`; L136: `$projdir/do/share/siblingxwalk/siblingpairxwalk`; L142: `$projdir/do/share/siblingvaregs/siblingoutxwalk.do` — **these reference `$projdir` (= caschls), so they are cross-repo calls** |
| `do_create_samples` (L148) | L150: `create_score_samples.do`; L152: `create_out_samples.do` (under `$vaprojdir/do_files/sbac/`) |
| `do_va` (L164) | L165-215 — long sequence; see below |
| `do_share_tables` (L220) | L222-231: 9 do-files in `$vaprojdir/do_files/share/` (svyindex_tab, reg_out_va_tab, va_spec_fb_tab_all, base_sum_stats_tab, sample_counts_tab, va_var_explain, va_var_explain_tab, kdensity, va_scatter) |
| `do_va_het` (L238) | L240-245: `va_corr_schl_char.do`, `va_corr_schl_char_fig.do`, `persist_het_student_char_fig.do`, `va_het.do` (under `$vaprojdir/do_files/va_het/`) |
| `do_survey` (L251) | **L253: `do "/home/research/ca_ed_lab/users/chesun/gsr/caschls/do/master.do"` — hardcoded absolute path; this calls the OTHER predecessor repo's master.do** |

The `do_va` block (L164-216) calls, in order: va_score_all.do, va_score_fb_all.do, va_out_all.do, va_out_fb_all.do, explore/va_predicted_score.do, explore/va_predicted_score_fb.do, va_score_spec_test_tab.do, va_out_spec_test_tab.do, va_score_fb_test_tab.do, va_out_fb_test_tab.do, va_spec_fb_tab.do, explore/va_predicted_score_spec_fb_tab.do, merge_va_est.do, va_corr (no .do extension at L190), prior_decile_original_sample.do, reg_out_va_all.do, reg_out_va_dk_all.do, reg_out_va_all_tab.do, reg_out_va_dk_all_tab.do, reg_out_va_all_fig.do, reg_out_va_dk_all_fig.do, va_score_sib_lag.do, va_out_sib_lag.do, va_sib_lag_spec_fb_tab.do, share/check/corr_dk_score_va.do.

**Path references that need updating in consolidation:**

- L2 (comment), L7 (live `cd`): `cd "/home/research/ca_ed_lab/projects/common_core_va"` — hardcoded absolute path, twice.
- L8: relative `do do_files/settings.do`.
- L67-205: ~30+ uses of `$vaprojdir/do_files/...`.
- L126-142: 4 uses of `$projdir/do/share/...` (cross-repo).
- L253: hardcoded `do "/home/research/ca_ed_lab/users/chesun/gsr/caschls/do/master.do"` (cross-repo, no global expansion).

**Stata version / non-trivial syntax:** no `version` statement. Uses `set varabbrev off` (L23), `set graphics off` (L24), `set scheme s1color` (L25), `set seed 1984` (L26), `timer on/off 1` (L32, L269), `cap log close _all` (L15), `pause off` (L18).

**ssc/community packages used:** explicit `ssc install` block at L36-58 (gated by `installssc=0` so off in committed code): elabel, tabout, grstyle, palettes, colrspace, labutil2, labundef, rangestat, _gwtmean, estout, outreg2, regsave, group_twoway, vam, binscatter, descsave, parmest, texsave, plus `net install geodist`, opencagegeo.

**Gotchas:**

- L26: sets `set seed 1984` globally. This is an ENTRY-point seed, separate from the seed inside `vam.ado` (9827496). Any code in the dispatched .do files that relies on entropy will inherit 1984 unless overridden.
- L23: `set varabbrev off` is set BUT NOT permanently (`,perm`); `master.do` L38 uses the permanent form, so semantics may diverge by entry point.
- L67: `do ... clean_acs_census_tract` — no `.do` extension. Stata accepts but it is inconsistent with surrounding lines.
- L112: `do do_files/sbac/touse_va.do` is the only call inside the `do_va_*` ecosystem that uses a relative (vs `$vaprojdir`) path.
- L190: `do $vaprojdir/do_files/sbac/va_corr` — no `.do` extension; could fail if the file is named differently.
- L253: cross-repo call with a hardcoded absolute path (no `$projdir` expansion). This is a bug surface for consolidation.
- L21: `graph drop _all` runs unconditionally before any pause toggles, which is fine here because `pause off` (L18) means subsequent `pause` commands are silent.

**Reference to paper outputs:** Transitive — when the relevant block is on, it produces every downstream artifact in the VA pipeline. As committed (only `clean_sch_char` and `do_va_het` are on), this run only refreshes school characteristics and VA heterogeneity outputs.

**Notes / open questions:**

- Why is the working directory set on L7 (`cd ...`) when L2 already documents the same `cd` as a precondition? Possibly belt-and-suspenders.
- Why is L25 `set scheme s1color` set in do_all.do but `master.do` does not set a scheme? May produce inconsistent figures depending on entry point.

---

### File: `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/master.do`

**Predecessor repo:** caschls
**Owner** (from header): "Christina Sun. Email: ucsun@ucdavis.edu" (L6)
**Lines:** 633
**Purpose:** Top-level entry point for the survey-side caschls pipeline. Drives sibling matching (off), data build, data checks, representativeness diagnostics, response-rate datasets, QOI cleaning (secondary/parent/staff), pooling, gr11 enrollment merge, VA regs on survey data, factor analysis, imputation/index, index VA regs, optional sibling VA regs.

**Globals defined:** none.

**Macros defined:**

| Line | Local | Value |
|---|---|---|
| 57 | `installssc` | 0 |
| 82 | `do_match_siblings` | 0 |
| 125 | `do_build_data` | **1** |
| 138 | `do_check_data` | **1** |
| 159 | `do_diagnostics` | **1** |
| 215 | `do_response_rate` | **1** |
| 239 | `do_clean_sec_qoi` | **1** |
| 257 | `do_clean_parent_qoi` | **1** |
| 280 | `do_clean_staff_qoi` | **1** |
| 299 | `do_pool_qoi_merge` | **1** |
| 320 | `do_pool_gr11_enr` | **1** |
| 337 | `do_va_regs` | **1** |
| 354 | `dofactor` | **1** |
| 379 | `do_index` | **1** |
| 407 | `do_index_va_reg` | **1** |
| 451 | `dooutcomesumstats` | 0 |
| 463 | `do_sibling_va_regs` | 0 |

**Toggle states as committed:** all blocks except `installssc`, `do_match_siblings`, `dooutcomesumstats`, `do_sibling_va_regs` are ON. So a vanilla run executes a long pipeline of survey/diagnostics/QOI/factor/index work.

**Inputs / Outputs:** none directly (pure dispatch).
**Sourced helpers (.doh files):** none directly.

**Calls (other do-files via `do`):**

L52: `do "./do/settings.do"` — relative; cwd is `/home/research/ca_ed_lab/users/chesun/gsr/caschls` (set on L51).

Block-by-block calls (all paths begin with `$projdir`, which equals the caschls path per settings.do):

| Block | Calls |
|---|---|
| `do_match_siblings` (L82) | L87: `do/share/siblingxwalk/siblingmatch`; L92: `.../uniquefamily`; L97: `.../siblingpairxwalk`; L103: `do/share/siblingvaregs/siblingoutxwalk.do` |
| `do_build_data` (L125) | L128: `do/build/prepare/renamedata`; L132: `splitstaff0414` |
| `do_check_data` (L138) | L140: `do/check/sameschools`; L143: `schooloverlap`; L146: `gradetab`; L149: `do/build/prepare/enrollmentclean` |
| `do_diagnostics` (L159) | L162-205: 14 calls under `do/build/sample/`, `do/share/demographics/`, `do/check/` |
| `do_response_rate` (L215) | L220: `do/build/buildanalysisdata/responserate/trimsecdemo`; L223: `secresponserate`; L226: `trimparentdemo`; L229: `parentresponserate` |
| `do_clean_sec_qoi` (L239) | L242: `do/build/buildanalysisdata/qoiclean/secondary/secqoiclean1819_1718_1516`; L245: `secqoiclean1617`; L248: `secqoiclean1415` |
| `do_clean_parent_qoi` (L257) | L260: `do/build/buildanalysisdata/qoiclean/parent/parentqoiclean1819_1718`; L263: `parentqoiclean1617`; L266: `parentqoiclean1516`; L269: `parentqoiclean1415` |
| `do_clean_staff_qoi` (L280) | L283: `do/build/buildanalysisdata/qoiclean/staff/staffqoiclean1819_1718`; L286: `staffqoiclean1617_1516`; L289: `staffqoiclean1415` |
| `do_pool_qoi_merge` (L299) | L302: `secpooling`; L305: `parentpooling`; L308: `staffpooling` (under `do/build/buildanalysisdata/poolingdata/`) |
| `do_pool_gr11_enr` (L320) | L323: `do/build/prepare/poolgr11enr`; L327: `do/build/buildanalysisdata/poolingdata/mergegr11enr` |
| `do_va_regs` (L337) | L341: `do/build/buildanalysisdata/poolingdata/clean_va.do`; L346: `do/share/svyvaregs/allvaregs` |
| `dofactor` (L354) | L357: `factor`; L361: `allsvymerge`; L365: `allsvyfactor`; L369: `do/check/allsvymissing` (factoranalysis files under `do/share/factoranalysis/`) |
| `do_index` (L379) | L383: `imputation`; L388: `imputedcategoryindex`; L393: `compcasecategoryindex`; L398: `indexhorserace` |
| `do_index_va_reg` (L407) | L412: `mattschlchar`; L416: `testscore`; L420: `indexregwithdemo`; L425: `indexhorseracewithdemo`; L429: `alpha`; L433: `indexalpha`; L437: `pcascore` |
| `dooutcomesumstats` (L451) | L455: `do/share/outcomesumstats/nsc_codebook.do` |
| `do_sibling_va_regs` (L463) | L468: `createvasample.do`; L476: `siblingvasamples.do`; L486, L508: `va_sibling 0` and `va_sibling_out 0` (passed positional argument); plus 25+ additional sibling-VA do-files |

**Cross-repo calls:** **L18** (in a comment) and **L51** ($projdir-equivalent; cwd) reference the caschls path. There is **no** call from this file into `cde_va_project_fork`. Direction is one-way: `do_all.do` calls `master.do` (L253), but `master.do` does NOT call back.

**Path references that need updating in consolidation:**

- L11 (comment): `cd "/home/research/ca_ed_lab/users/chesun/gsr/caschls"`
- L18 (comment): `do "/home/research/ca_ed_lab/users/chesun/gsr/caschls/do/master.do"`
- L23 (comment): `cd "/home/research/ca_ed_lab/users/chesun/gsr/caschls"`
- L51 (live): `cd "/home/research/ca_ed_lab/users/chesun/gsr/caschls"`
- ~80+ uses of `$projdir/do/...` throughout the dispatch blocks.

**Stata version / non-trivial syntax:** no `version` statement. L38: `set varabbrev off, perm` (PERMANENT — distinct from `do_all.do`'s non-perm). L36: `cap log close _all`. L40: `set more off`. L49: `pause off`. L54: `timer on 1`. L630: `timer off 1`. L631: `timer list`. L633: `pause off` (redundant — already off).

**ssc/community packages used:** L57-77 install block (off): elabel, tabout, grstyle, palettes, colrspace, labutil2, labundef, rangestat, _gwtmean, estout, outreg2, regsave, group_twoway, vam, binscatter, descsave, parmest. (No texsave, geodist, opencagegeo here — distinct from do_all.do's installssc list.)

**Gotchas:**

- L51 hardcoded `cd` ALSO sets cwd before sourcing settings.do (L52). If consolidation moves files but leaves L51 untouched, settings.do will still resolve via `./do/settings.do` from the fixed cwd, so a path mismatch could silently load the wrong settings.do.
- The block toggles on lines 125, 138, 159, 215, 239, 257, 280, 299, 320, 337, 354, 379, 407 are ALL set to 1. A naive run will execute the entire survey pipeline. By contrast `do_all.do` is far more conservative.
- L468 / L476 / L486 / L508: positional argument `0` passed to `va_sibling` and `va_sibling_out` — the comment at L483-485 explains it's a drift-limit override. Inside the `do_sibling_va_regs` block (which is OFF), so currently inert.
- L86, L91, L96 etc.: no `.do` extension on many sibling and build calls. Stata defaults to .do, but can mask "wrong file" bugs.
- L6 vs `do_all.do`/`settings.do`: this header attributes to "Christina Sun" while the others attribute to "Che Sun." Same person; the inconsistent name is purely cosmetic.
- L9, L13: same "IMPORTAMT" typo in comment.

**Reference to paper outputs:** This file drives the survey-side analysis (factor / index / svy VA regressions). Per the paper map, expect this to feed any factor-analysis tables, alpha tables, and survey-VA regression tables.

**Notes / open questions:**

- The block at L109-117 is empty (a placeholder comment "THIS IS WHERE TO RUN THE VA ESTIMATES DO FILES" with no code). VA estimation is therefore not driven from `master.do` in caschls — it must come from `do_all.do` in cde_va_project_fork.
- L341 calls `clean_va.do`, which presumably reads VA estimates produced by the do_all.do pipeline. This is an implicit cross-repo data dependency: master.do consumes outputs from do_all.do.

---

### File: `/Users/christinasun/github_repos/cde_va_project_fork/do_files/sbac/macros_va.doh`

**Predecessor repo:** cde_va_project_fork
**Owner** (from CHANGE LOG): unknown — entries dated 4/28/2022, 9/20/2022, 10/31/2022, 5/31/2023, 8/22/2024 (so multiple authors over time; most likely Che Sun based on email convention used elsewhere).
**Lines:** 612
**Purpose:** Defines the controls / strings / sample-naming scheme used across the VA estimation pipeline. Sourced (via `include`) by every reg/spec do-file under `cde_va_project_fork/do_files/sbac/`.

**Macros defined (`local`):** This is a delimited block under `#delimit ;` (L19) ending at `#delimit cr` (L612).

**File-path locals (L22-31):** all under `#delimit ;`.

| Line | Macro | Value |
|---|---|---|
| 22 | `home` | `$vaprojdir` |
| 23 | `vaprojdofiles` | `$vaprojdir/do_files` (note: missing trailing `;` — see Gotchas) |
| 24 | `ca_ed_lab` | `/home/research/ca_ed_lab` |
| 25 | `k12_test_scores` | `$vaprojdir/data/restricted_access/clean/k12_test_scores` |
| 26 | `public_access` | `$vaprojdir/data/public_access` |
| 27 | `k12_public_schools` | `$vaprojdir/data/public_access/clean/k12_public_schools` |
| 28 | `k12_test_scores_public` | `$vaprojdir/data/public_access/clean/k12_test_scores` |
| 29 | `siblingxwalk` | `$projdir/dta/siblingxwalk/siblingpairxwalk` |
| 30 | `ufamilyxwalk` | `$projdir/dta/siblingxwalk/ufamilyxwalk` |
| 31 | `sibling_out_xwalk` | `$projdir/dta/siblingxwalk/sibling_out_xwalk` |

**Date locals (L34-65):** `test_score_min_year=2015`, `test_score_max_year=2018`, `star_min_year=2003`, `star_max_year=2013`, `caaspp_min_year=2015`, `caaspp_max_year=2019`, `outcome_min_year=2015`, `outcome_max_year=2018`.

**Outcome strings (L70-86):** `ela_str="ELA"`, `math_str="Math"`, `enr_str="Overall Enrollment"`, `enr_2year_str="2-Year Enrollment"`, `enr_4year_str="4-Year Enrollment"`.

**Sibling-census restricted-sample strings (L89-104):** `og_str="Original Specification"`, `acs_str="Original + Census"`, `sib_str="Original + Sibling"`, `both_str="Original + Census + Sibling"`.

**Value-Added control blocks:**

| Line | Macro | Content |
|---|---|---|
| 109 | `school_controls` | empty (`/*cohort_size*/` commented out) |
| 113 | `demographic_controls` | `age i.male i.eth_asian i.eth_hispanic i.eth_black i.eth_other i.econ_disadvantage i.limited_eng_prof i.disabled` |
| 122 | `ela_score_controls` | `i.year#(c.prior_ela_z_score##c.prior_ela_z_score##c.prior_ela_z_score)` |
| 127 | `ela_scrhat_controls` | same with `prior_ela_z_score_hat` (predicted) |
| 131 | `math_score_controls` | `i.year#(c.prior_math_z_score##c.prior_math_z_score##c.prior_math_z_score)` |
| 137 | `peer_ela_score_controls` | peer version of ela cubic |
| 141 | `peer_math_score_controls` | peer version of math cubic |
| 145 | `peer_demographic_controls` | peer demographic vector (no `i.` prefixes) |
| 156-158 | `va_control_vars` | derived: school+demographic, with `i.` stripped, deduped |
| 160 | `census_grade` | 6 |
| 164 | `census_controls` | ACS census-tract variables (asian/hispanic/black pct, hs dropout, 4yr+, child-poverty, median income) |
| 171 | `peer_census_controls` | peer counterparts |
| 177 | `sibling_controls` | `i.has_older_sibling_enr_2year i.has_older_sibling_enr_4year` |
| 182 | `peer_sibling_controls` | peer counterparts |
| 188 | `sib_lag1_controls` | `old1_sib_enr_2year old1_sib_enr_4year` |
| 194 | `sib_lag2_controls` | `old2_sib_enr_2year old2_sib_enr_4year` |
| 200 | `d_controls` | `mindist_any_nonprof_4yr mindist_ccc` (postsecondary distance) |

**Standalone control-block macros (L208-296):** `b_controls` (base), `peer_b_controls`, `l_controls` (= `loscore`), `peer_l_controls`, `a_controls` (= `census_controls`), `peer_a_controls`, `s_controls` (= `sibling_controls`), `peer_s_controls`, `la_controls`, `peer_la_controls`, `ls_controls`, `peer_ls_controls`, `as_controls`, `peer_as_controls`, `las_controls`, `peer_las_controls`.

**Distance-augmented forms (L298-307):** a `foreach` loop appends `_d` suffix to each control set:
```stata
foreach control in b l a s la ls as las {;
    local `control'd_controls
        ``control'_controls' `d_controls'
        ;
    local peer_`control'd_controls
        `peer_`control'_controls'
        ;
}
;
```

**SPEC-control combinations (L312-477):** another schema used for `_spec_controls` macros. For each base sample (b, l, a, s, la, ls, as, las), defines:
- `<sample>_spec_controls` — the controls for that spec
- `<sample>d_spec_controls` — same plus `d_controls`
- `<sample>_scrhat_spec_controls` — same with predicted prior-score controls
- `<sample>d_scrhat_spec_controls` — combined

**Sample-key string macros (L481-547):** `b_str="base"`, `bd_str=b_str`, `l_str="leave out score"`, `ld_str=l_str`, `a_str="ACS"`, `ad_str=a_str`, `s_str="sibling"`, `sd_str=s_str`, `la_str="leave out score & ACS"`, `lad_str=la_str`, `ls_str`, `lsd_str`, `as_str`, `asd_str`, `las_str`, `lasd_str`, `d_str="postsecondary distance"`. Note: every `Xd_str` aliases to `X_str` — the d-suffix is collapsed in the display string.

**Heterogeneity strings (L550-564):** `race_str`, `male_str`, `econ_disadvantage_str`, `prop_ecn_disadv_str`, `charter_str`, `inc_median_hh_xtile_str`, `enr_black_hisp_prop_str`.

**School-characteristics blocks (L567-609):** `sch_chars` (FTE/teacher/credentials/male-by-male-prop interactions/total enr); `sch_char_vars` (cleaned: i./c./##/# stripped, deduped); `dem_chars`; `dem_char_vars`; `expenditures` (5 expenditure variables); `expenditure_vars`; final composite `sch_char_control_vars` is the union of `sch_char_vars`, `dem_char_vars`, and `expenditure_vars`.

**Inputs / Outputs:** N/A (this file defines macros; it does not load or save data).
**Sourced helpers:** none.
**Calls:** none.

**Path references that need updating in consolidation:**

- L22 `$vaprojdir` (root)
- L23 `$vaprojdir/do_files`
- L24 hardcoded `/home/research/ca_ed_lab`
- L25-28 `$vaprojdir/data/...` (4 sub-dirs)
- L29-31 `$projdir/dta/siblingxwalk/...` (3 cross-repo dependencies on caschls/dta/)

**Stata version / non-trivial syntax:** entire body uses `#delimit ;` (L19). Heavy use of factor-variable notation (`i.`, `c.`, `##`, `#`). The `local <name> : list uniq <list>` pattern (L158, L585, L595, L606) is used to dedupe. The `subinstr local` pattern (L157, L581-584) strips factor-variable prefixes when building `_vars` aliases.

**ssc/community packages used:** none directly (this is purely macro-definition).

**Gotchas (line-cited):**

- **L23: missing trailing `;`** under `#delimit ;`. The line reads `local vaprojdofiles "$vaprojdir/do_files"` with NO `;`. Under `#delimit ;`, statements must end in `;`. The next statement `local ca_ed_lab "/home/research/ca_ed_lab" ;` (L24) is parsed as part of the macro value because the previous statement never terminated. Effective behavior: `vaprojdofiles` macro will contain `"$vaprojdir/do_files" local ca_ed_lab "/home/research/ca_ed_lab"` — meaning `vaprojdofiles` is corrupted AND `ca_ed_lab` is never defined. **This is a bug.** (Compare to L22 which DOES have `;` and L25 which also has `;`.)
- L298-307: the `foreach` body appears to define `peer_<X>d_controls` to be `peer_<X>_controls` ALONE (no `d_controls` appended). Compare with the non-peer version which DOES append `d_controls`. So the peer-distance variants do NOT include the distance controls. **This may be a bug or intentional.** Without cross-checking against how these macros are consumed, I cannot say which.
- L342-345 `l_scrhat_spec_controls`: defined in terms of `b_spec_controls` plus `loscore` — but uses `b_spec_controls` (which is the non-scrhat version) instead of `b_scrhat_spec_controls`. **Inconsistent with surrounding scrhat-flavored macros (L362, L382, L402, L422, etc., which DO use the scrhat base).** Looks like a copy-paste bug.
- The display strings `bd_str`, `ld_str`, `ad_str`, etc. (L485, L493, L501, L509, L517, L525, L533, L541) all alias to their non-d counterparts. So when these strings are used as table headers, the postsecondary-distance variant is NOT distinguishable from the non-distance variant in the rendered output. **Potentially a labeling bug, depending on whether downstream consumers expect to see "postsecondary distance" in the d-suffixed label.**
- The CHANGE LOG (L1-17) lists "Added macro for sibling controls" (4/28/2022), date-formatting changes, sample-naming convention (10/31/2022), distance controls (5/31/2023), predicted ELA score spec (8/22/2024). The schema has accreted over years; a single error in the foreach loop or alias chain can have wide downstream impact.

**Reference to paper outputs:** The macros defined here are consumed by every `va_*` and `reg_out_va_*` do-file. Per the paper map, that means main VA tables, spec-fb tables, persistence regressions — essentially the entire empirical core of the paper.

**Notes / open questions:**

- Need to grep all consumers of `$vaprojdofiles` and `$ca_ed_lab` to confirm whether the L23 missing-semicolon bug is observable in production, or whether the macros happen never to be referenced (in which case the bug is latent).
- Need to confirm whether `peer_<X>d_controls` is intentionally distance-free (e.g., because peer means of distances are degenerate by school) or a bug.
- Need to confirm whether `l_scrhat_spec_controls` SHOULD reference `b_scrhat_spec_controls` (as the other scrhat lines do).

---

### File: `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/ado/vam.ado` (top-level)

**Predecessor repo:** caschls
**Owner** (header L1): "version 2.0.1 27jul2013 Michael Stepner, stepner@mit.edu"
**Lines:** 763
**Purpose:** Stepner's `vam` package — implements drift-limited shrinkage estimator for teacher (here, school) value-added per Chetty/Friedman/Rockoff 2014. Used throughout the VA estimation pipeline.

**Customization evidence (CRITICAL):**

- L252-254: a comment block reads:
  ```
  * Bugfix 2026-04-25: option is named `noseed` (line 26) but original check
  * referenced macro `seed` which was never defined, so the seed was always
  * set regardless of caller's `noseed` flag. Now matches the option name.
  ```
- L255: `if "`noseed'"=="" {` — checks the correctly-named option.
- L256: `set seed 9827496`.

This file is **a customized version**, not the off-the-shelf SSC version. The customization is dated 2026-04-25.

**The `*!` version line (L1) was NOT updated to reflect the customization.** It still claims `2.0.1 27jul2013 Michael Stepner` even though the file was modified per the comment on 2026-04-25. This is misleading from a provenance perspective.

**Total lines:** 763.
**Syntax options (from `syntax` declaration L20-26):**

```
syntax varname(ts fv) [aweight/], teacher(varname) year(varname) class(varname) [
    by(varlist)
    controls(varlist ts fv) absorb(varname) tfx_resid(varname)
    data(string) output(string) output_addvars(varlist)
    driftlimit(integer -1)
    QUASIexperiment
    CONStant noseed varclasszero estimates(string asis)
]
```

Required: `varname(ts fv)` (depvar; accepts time-series and factor-variable operators), `teacher()`, `year()`, `class()`. Optional: `by()`, `controls()`, `absorb()`, `tfx_resid()`, `data()`, `output()`, `output_addvars()`, `driftlimit()`, `quasiexperiment`, `constant`, **`noseed`**, `varclasszero`, `estimates()`.

**`controls()` qualifier:** `varlist ts fv` (L22) — accepts time-series and factor-variable operators. Confirmed.

**Existence of `noseed`:** YES. Declared on L26.
**Where checked:** L255. The check `if "`noseed'"=="" { set seed 9827496 }` correctly fires WHEN noseed is NOT specified.

**`set seed` invocation:** L256. Value: `9827496`. Gate: `if "`noseed'"==""` (L255). Intended semantics: caller passes `noseed` to suppress the seed; otherwise the package seeds 9827496.

**Inputs / Outputs / Sourced helpers / Calls:** N/A (it is an .ado package; it operates on whatever dataset is in memory and writes to `output()` if specified).

**Path references that need updating in consolidation:** none — the .ado uses the `output()` argument and tempfiles, no hardcoded paths.

**Stata version / non-trivial syntax:** L16 `version 10.1` (program-level), L156, L162 `version 11 :` (regression calls), L508 `version 11`, L509 `set matastrict on`. Heavy use of mata (L511-762).

**ssc/community packages used:** none — pure ado/mata code.

**Gotchas (line-cited):**

- L1 version string `*! version 2.0.1 27jul2013` is **not updated to reflect the 2026-04-25 customization**. Anyone running `which vam` will see a 2013 timestamp and assume the upstream version, missing the bugfix.
- L252-257: the bugfix comment is helpful but does not include any reference to the original Stepner seed-injection design intent (whether the seed was meant to ensure reproducibility in the random tiebreaker on L259-260 `g `rand'=uniform()` / `bys `teacher' `year' (`rand'): gen `classnum'=_n`). The fix means callers can NOW actually disable the seed, where before they could not. Any prior call passing `noseed` did NOT actually suppress the seed.
- L259: `g `rand'=uniform()` — uses Stata's `uniform()` legacy syntax, not `runiform()`. Should still work in Stata 17 but is deprecated.
- L271, L272: `qui tsset `identifier' `classnum'/*, noquery*/` — the `,noquery` option is commented out. May affect verbosity in certain Stata versions but should not affect estimates.

**Reference to paper outputs:** This is the estimation engine for ALL VA estimates in the paper. Any change in seed behavior changes every reported VA estimate.

**Notes / open questions:**

- Christina's bugfix dated 2026-04-25 means: every VA estimate produced **before** that date in this repo had the seed set regardless of whether the caller passed `noseed`. Every VA estimate produced **after** that date with `noseed` will produce a DIFFERENT random tiebreaker. Reproducibility implication: rerunning a `vam` call with `noseed` post-fix will not match the pre-fix estimate. Need to confirm whether any caller in the consolidated pipeline actually passes `noseed` — if no callers pass it, the fix is observationally inert.
- T1 empirical test: enumerate every `vam` call in the codebase; check whether any include `noseed`.

---

### File: `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/ado/server_vam/vam.ado`

**Predecessor repo:** caschls (subdirectory)
**Owner** (header L1): same Stepner 2.0.1 27jul2013 string.
**Lines:** 760
**Purpose:** Identical to the parent vam.ado EXCEPT for the customization. This appears to be a saved copy of the **un-customized** (server-original) version of vam.

**Diff vs `caschls/do/ado/vam.ado`:**

```
252,255c252
< 		* Bugfix 2026-04-25: option is named `noseed` (line 26) but original check
< 		* referenced macro `seed` which was never defined, so the seed was always
< 		* set regardless of caller's `noseed` flag. Now matches the option name.
< 		if "`noseed'"=="" {
---
> 		if "`seed'"=="" {
```

So `caschls/do/ado/vam.ado` is the patched version (4 lines: 3 comment + corrected `if` predicate) while `caschls/do/ado/server_vam/vam.ado` is the original buggy version (1 line, same `if` predicate but referencing an undefined macro `seed`).

**Critical confirmation:** The bug Christina identified is real. In `server_vam/vam.ado` L252:
```stata
if "`seed'"=="" {
    set seed 9827496
}
```
The local macro `seed` is **never defined anywhere in the file**. The `syntax` declaration (L20-26) does not include a `seed()` option — only `noseed`. Therefore `"`seed'"` always evaluates to the empty string `""`, the `if` predicate is always true, and `set seed 9827496` ALWAYS executes regardless of whether the caller passed `noseed`. This makes `noseed` a no-op in the original.

**Syntax options:** identical to top-level vam.ado (also includes `noseed` in the syntax line at L26).
**Existence of `noseed`:** YES (L26).
**Where checked in original:** L252 — but the check uses the wrong macro name. **Bug confirmed.**

**`set seed` invocation:** L253. Value: `9827496`. Gate: `if "`seed'"==""` — always true. So the seed is unconditional in this version.

**Stata version / non-trivial syntax:** identical to top-level vam.ado.

**Gotchas:** All the same as the top-level version EXCEPT the seed bug, which is the entire point of this server_vam directory existing.

**Reference to paper outputs:** Identical scope to top-level. If this version is ever loaded (e.g., if Stata's adopath prefers `server_vam/` somehow), every VA estimate that requested `noseed` will silently re-seed.

**Notes / open questions:**

- Why is this file kept? Hypothesis: as a reference copy of the original-buggy version for diff/audit purposes. There is no README in `caschls/do/ado/server_vam/` documenting intent.
- adopath handling: which copy of `vam.ado` does Stata actually load? The standard adopath includes the `do/ado/` directory; `do/ado/server_vam/` would only be loaded if explicitly added (e.g., `adopath ++ ./do/ado/server_vam`). Need to grep for `adopath` in the entry-points to confirm. From my read of `do_all.do` (L1-270) and `master.do` (L1-633), I see NO `adopath` modification. So Stata should load the top-level (patched) version by default — assuming the working directory has `./do/ado/` on the path or the file is in the user's PERSONAL or PLUS dir.
- This means: in practice, the top-level (patched) vam.ado is the live version. The server_vam/ copy is dormant.

---

## Synthesis

### Q1. Path geometry: where does the code live, and how do the two repos relate?

**Two repos, two roots, one server.** The Scribe server hosts both:

- `cde_va_project_fork` → **`/home/research/ca_ed_lab/projects/common_core_va`** (= `$vaprojdir`)
- `caschls` → **`/home/research/ca_ed_lab/users/chesun/gsr/caschls`** (= `$projdir`)

The two `settings.do` files are **byte-near-identical** (single trailing-newline difference). Each repo sources its own local copy via a relative path:

- `do_all.do` L8: `do do_files/settings.do` (cwd is `$vaprojdir` per L7)
- `master.do` L52: `do "./do/settings.do"` (cwd is `$projdir` per L51)

Both copies declare the same 12 globals. Both globals point into both repos, so each entry point has the full set of paths after sourcing.

**Cross-repo references (one-way):**

- `do_all.do` → `master.do`: L253 hardcodes `do "/home/research/ca_ed_lab/users/chesun/gsr/caschls/do/master.do"` (under the `do_survey` toggle, currently OFF). Path is hardcoded — no `$projdir` expansion.
- `do_all.do` → caschls: L126, L131, L136, L142 reference `$projdir/do/share/siblingxwalk/...` and `$projdir/do/share/siblingvaregs/...` (under `do_match_siblings` toggle, currently OFF).
- `macros_va.doh` → caschls: L29-31 reference `$projdir/dta/siblingxwalk/...`.
- `master.do` → cde_va_project_fork: **none.** No path/reference back. The direction is one-way: do_all.do drives master.do for the survey block, and do_all.do consumes sibling crosswalk outputs from caschls.

**Implication for consolidation:** the two repos must coexist on the server because of these cross-references, OR the consolidation has to flatten both into a single tree and rewrite ~40 path expressions across the 6 in-scope files plus all called sub-files.

### Q2. vam package status

**Customization confirmed.** The version comment (`*!` line) still says `2.0.1 27jul2013 Michael Stepner` (L1) but the file was modified on **2026-04-25** with a 4-line bugfix comment block at L252-255. The `server_vam/vam.ado` directory holds a copy of the original-buggy code as evidence/baseline.

**The bug in the original (L252 of server_vam/vam.ado):** the check `if "`seed'"=="" { set seed 9827496 }` references a local macro `seed` that is never defined. The `syntax` declaration (L26) only declares the option `noseed` — there is no `seed()` option. Result: `"`seed'"` always evaluates to `""`, the `if` is always true, and the seed is ALWAYS set regardless of whether the caller passed `noseed`. This makes `noseed` a no-op in the original.

**Christina's fix (L255 of caschls/do/ado/vam.ado):** changed the check to `if "`noseed'"=="" { ... }`, matching the option name. Now `noseed` correctly suppresses the seed.

**Reproducibility implication:** any prior `vam` invocation with `noseed` did NOT actually disable seeding. Post-fix invocations with `noseed` produce different random tiebreakers (L259-260) and therefore can produce different VA estimates than the pre-fix run. If any caller in the production pipeline uses `noseed`, the fix changes downstream estimates.

**Total lines:** 763 (top-level patched), 760 (server_vam original).
**Syntax options:** required `varname(ts fv)`, `teacher()`, `year()`, `class()`; optional `by()`, `controls(varlist ts fv)`, `absorb()`, `tfx_resid()`, `data()`, `output()`, `output_addvars()`, `driftlimit()`, `quasiexperiment`, `constant`, `noseed`, `varclasszero`, `estimates()`.
**`controls()` qualifiers:** `varlist ts fv` — accepts time-series AND factor-variable operators. Confirmed at L22 of both files.

**Note:** The `*!` version line was NOT bumped after the fix. From `which vam` you would still see Stepner's 2013 string. Recommend updating the `*!` line to make the customization legible.

### Q3. macros_va.doh naming conventions

The schema is a 2-letter "sample × specification" code system, with optional `d` and `_scrhat` suffixes:

**Sample tokens (single letters):**

- `b` = base
- `l` = leave-out score (loscore)
- `a` = ACS (census-tract demographics)
- `s` = sibling

**Combinations are concatenations:** `la` = loscore + ACS; `ls` = loscore + sibling; `as` = ACS + sibling; `las` = loscore + ACS + sibling.

**Suffixes:**

- `d` = postsecondary distance controls added (`d_controls` = `mindist_any_nonprof_4yr mindist_ccc`).
- `_scrhat` = uses predicted lag-1 ELA score (`prior_ela_z_score_hat`) instead of observed (`prior_ela_z_score`).

**Macro families (each name expands by sample × suffix combination):**

| Family | Form | Examples |
|---|---|---|
| Standalone controls | `<sample>_controls`, `<sample>d_controls` | `b_controls`, `bd_controls`, `la_controls`, `lasd_controls` |
| Peer counterparts | `peer_<sample>_controls` | `peer_b_controls`, `peer_la_controls` |
| Spec controls | `<sample>_spec_controls`, `<sample>d_spec_controls`, `<sample>_scrhat_spec_controls`, `<sample>d_scrhat_spec_controls` | `b_spec_controls`, `lad_spec_controls`, `las_scrhat_spec_controls` |
| Display strings | `<sample>_str`, `<sample>d_str` | `b_str="base"`, `bd_str="base"` (aliased) |

**`_scrhat_` infix:** indicates predicted prior-score control. The variable referenced is `prior_ela_z_score_hat` (defined at L128: `i.year#(c.prior_ela_z_score_hat##c.prior_ela_z_score_hat##c.prior_ela_z_score_hat)`).

**`#delimit ;` block:** opens at L19, closes at L612 (`#delimit cr`). The entire body is delimited by semicolons.

**Anomalies / bugs (line-cited):**

1. **L23 missing trailing `;`** under `#delimit ;`: `local vaprojdofiles "$vaprojdir/do_files"` has no terminator. Under `#delimit ;` this corrupts both `vaprojdofiles` and the next macro `ca_ed_lab` (L24). **This is a bug; latent if neither macro is consumed.**
2. **L298-307 foreach loop**: defines `peer_<X>d_controls` to be `peer_<X>_controls` ALONE (no `d_controls` appended), whereas the non-peer arm correctly appends `d_controls`. **Asymmetry; possible bug.**
3. **L342-345**: `l_scrhat_spec_controls` is defined as `b_spec_controls + loscore` but uses non-scrhat `b_spec_controls`, breaking the pattern observed in surrounding `_scrhat_spec_controls` (which use `b_scrhat_spec_controls`). **Probable copy-paste bug.**
4. **`_str` aliases (L485, L493, L501, L509, L517, L525, L533, L541)**: every `Xd_str` is set equal to `X_str`. So the postsecondary-distance variant has no distinct display label. Whether this is a labeling bug depends on consumer expectations.

### Q4. Call graph at the entry-point level

```
                      do_all.do (cde_va_project_fork)
                              │
              ┌───────────────┼─────────────────┐
              │               │                 │
       (toggle=1) clean_sch_char    (toggle=1) do_va_het
              │ (10 sub-do-files)         │ (4 sub-do-files)
              │                           │
       (toggle=0) clean_acs / do_distance / do_touse_va / do_create_samples /
              │  do_va / do_share_tables (massive blocks, all OFF)
              │
       (toggle=0) do_match_siblings  ──→  $projdir/do/share/siblingxwalk/...
              │                           (cross-repo into caschls)
              │
       (toggle=0) do_survey  ──────────→  master.do (HARDCODED ABS PATH L253)
                                            │
                                  master.do (caschls)
                                            │
              ┌──────────┬──────────┬───────┼─────────┬──────────┐
              │          │          │       │         │          │
       (1) do_build  do_check  do_diag  do_response_rate  ...  do_index_va_reg
              │          │          │       │                   │
              ↓          ↓          ↓       ↓                   ↓
       $projdir/do/build, do/check, do/share/... (caschls subtree)
```

**Cross-repo edges:**

- `do_all.do` L253 → `master.do` (hardcoded absolute path; toggle currently 0)
- `do_all.do` L126/131/136/142 → `$projdir/do/share/sibling*` (toggle currently 0)
- `macros_va.doh` L29-31 → `$projdir/dta/siblingxwalk/*` (data dependency, not code)
- `master.do` → no calls back into cde_va_project_fork.

**Duplicated logic:**

- `do_all.do` L121-144 and `master.do` L82-105 both define a `do_match_siblings` block with effectively the **same 4 sub-calls** (`siblingmatch`, `uniquefamily`, `siblingpairxwalk`, `siblingoutxwalk`). Both are gated by `local do_match_siblings = 0`. Both reference the same `$projdir/do/share/siblingxwalk/...` paths. **Duplicate code.** If consolidation flattens, only one block should remain.
- Both files have an `installssc` block (do_all.do L36-58 vs master.do L57-77) with overlapping but not identical package lists. Differences: do_all.do adds `texsave` (L55), `geodist` (L56), `opencagegeo` (L57). master.do does not include these.
- Both files have `cap log close _all`, `clear all`, `set varabbrev off`, `pause off`, `timer on/off 1`. Standard housekeeping.

### Q5. Hardcoded-path inventory

| File | Line | Statement | Type |
|---|---|---|---|
| `do_all.do` | 2 | `cd "/home/research/ca_ed_lab/projects/common_core_va"` | comment |
| `do_all.do` | 7 | `cd "/home/research/ca_ed_lab/projects/common_core_va"` | live `cd` |
| `do_all.do` | 253 | `do "/home/research/ca_ed_lab/users/chesun/gsr/caschls/do/master.do"` | live cross-repo do, hardcoded |
| `master.do` | 11 | `cd "/home/research/ca_ed_lab/users/chesun/gsr/caschls"` | comment |
| `master.do` | 18 | `do "/home/research/ca_ed_lab/users/chesun/gsr/caschls/do/master.do"` | comment (self-invocation example) |
| `master.do` | 23 | `cd "/home/research/ca_ed_lab/users/chesun/gsr/caschls"` | comment |
| `master.do` | 51 | `cd "/home/research/ca_ed_lab/users/chesun/gsr/caschls"` | live `cd` |
| `macros_va.doh` | 24 | `local ca_ed_lab "/home/research/ca_ed_lab" ;` | macro definition (literal `/home/research/...`) |
| `settings.do` (both) | 12,16,20,25,28,31,35,39,42,45,49,52 | `global ... "/home/research/..."` | 12 global definitions, all literal |

Cross-user references (potentially cross-team coupling):

- `cde_va_project_fork/settings.do` L45: `global mattxwalks "/home/research/ca_ed_lab/users/msnaven/data/restricted_access/clean/crosswalks"` — references **msnaven** (Matt Naven)'s personal directory.
- `caschls/settings.do` L46: same.
- `master.do` L412: `do $projdir/do/share/factoranalysis/mattschlchar` — comment at L411 says "from the dataset created by Matt Naven."

**Total: 22 distinct hardcoded path expressions across 5 files** (excluding `$global` references which are globals-derived). Plus one cross-user dependency on the `msnaven` directory.

---

## Bugs / anomalies summary (with line citations)

| # | Severity | File | Line(s) | Bug |
|---|---|---|---|---|
| 1 | **HIGH** | `caschls/do/ado/server_vam/vam.ado` | 252 | Original `if "`seed'"==""` references undefined macro; `noseed` option is silently a no-op. Christina patched in `caschls/do/ado/vam.ado` L255 (date 2026-04-25). |
| 2 | MED | `caschls/do/ado/vam.ado` | 1 | `*! version` string still claims 2.0.1 27jul2013 despite the L252-255 patch. Misleading provenance. |
| 3 | MED | `cde_va_project_fork/do_files/sbac/macros_va.doh` | 23 | Missing `;` under `#delimit ;`; corrupts `vaprojdofiles` and `ca_ed_lab` macros. Latent if not consumed. |
| 4 | MED | `cde_va_project_fork/do_files/sbac/macros_va.doh` | 298-307 | `peer_<X>d_controls` does NOT append `d_controls`, while non-peer `<X>d_controls` does. Asymmetric. |
| 5 | LOW-MED | `cde_va_project_fork/do_files/sbac/macros_va.doh` | 342-345 | `l_scrhat_spec_controls` uses `b_spec_controls` instead of `b_scrhat_spec_controls`, breaking pattern. |
| 6 | LOW | `cde_va_project_fork/do_files/sbac/macros_va.doh` | 485, 493, 501, 509, 517, 525, 533, 541 | Every `Xd_str` aliases to `X_str`; postsecondary-distance variant has no distinct display label. |
| 7 | LOW | `cde_va_project_fork/do_files/do_all.do` | 253 | Cross-repo call to `master.do` is hardcoded absolute, no `$projdir` expansion. |
| 8 | LOW | `cde_va_project_fork/do_files/do_all.do` | 23 vs `caschls/do/master.do` 38 | `set varabbrev off` is permanent in master.do but transient in do_all.do; semantic divergence by entry point. |
| 9 | LOW | `cde_va_project_fork/do_files/settings.do` | 8 | "IMPORTAMT" typo in comment (also in caschls copy). Cosmetic. |
| 10 | LOW | `caschls/do/master.do` | 109-117 | Empty placeholder block "THIS IS WHERE TO RUN THE VA ESTIMATES DO FILES"; survey-side master never invokes VA estimates. Implicit cross-repo data dependency at L341 (`clean_va.do`). |

---

## Open questions I could not resolve from the 6 in-scope files alone

1. **Does any caller in the repo actually pass `noseed` to `vam`?** If not, the seed-bug fix is observationally inert. Need to grep `vam ` (with `noseed`) across all .do files.
2. **Is `$vaprojdofiles` ever consumed?** If never, the L23 missing-semicolon bug is latent. Need to grep.
3. **Is `peer_<X>d_controls` (the asymmetric distance-augmented peer macros) ever used in production regressions?** Need to check `reg_out_va_*.do`.
4. **Does `l_scrhat_spec_controls` (which mismatches the scrhat pattern) get used in production?** Need to check.
5. **Why does `caschls/do/ado/server_vam/` exist?** No README; my read is "archived original buggy version" but unconfirmed.
6. **Which copy of `vam.ado` does Stata actually load on the server?** Depends on adopath and PERSONAL/PLUS settings, neither set by the entry-points I read. Most likely the top-level patched version, but T1-empirical confirmation needed.
7. **What is `do/share/factoranalysis/mattschlchar`?** Master.do L412 references a Matt Naven dataset. Whether the path/file still exists is outside my read scope.
8. **Does `va_corr` (L190 of do_all.do, no .do extension) actually resolve to a file named `va_corr.do`?** The convention elsewhere in the file uses .do explicitly. Worth confirming.

---

## Verification methodology notes

- All findings above are sourced by line number from the primary files. No external context was used.
- I did NOT read any file under `quality_reports/audits/round-1/`.
- I did read the `quality_reports/audits/round-2/README.md` (which I was permitted to access) and incidentally saw a "Pre-flight" section about a Bug 93 in `crosswalk_nsc_outcomes.do`. That bug is in a different chunk (chunk-10), is not in any of the 6 in-scope files, and I have not used or extended that finding here.
- All diffs were computed with `diff` directly on filesystem paths.
- Line counts via `wc -l`.
- The `vam.ado` customization comment string (L252-254 of patched file) is itself the strongest single piece of evidence for the customization. The diff between the two vam.ado files reduces to exactly that comment block plus the `noseed` ↔ `seed` macro-name correction.
