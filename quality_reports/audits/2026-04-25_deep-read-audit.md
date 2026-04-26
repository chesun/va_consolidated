# Phase 0a Deep-Read Audit

**Status:** IN PROGRESS (foundation chunk complete)
**Plan reference:** `quality_reports/plans/2026-04-25_consolidation-plan-draft.md` §6
**Scope:** every file referenced (transitively) by `caschls/do/master.do` or `cde_va_project_fork/do_files/do_all.do` post-archival, plus `.doh` helpers, custom `.ado`, and Python upstream geocoding scripts.

**Per-file template** (verbatim from plan §6.2): see plan §6.2; reproduced where helpful per entry.

---

## Chunk 1: Foundation (COMPLETE)

Files audited: `cde_va_project_fork/do_files/settings.do`, `caschls/do/settings.do`, `cde_va_project_fork/do_files/do_all.do`, `caschls/do/master.do`, `cde_va_project_fork/do_files/sbac/macros_va.doh`, `caschls/do/ado/vam.ado`.

Foundation agent: general-purpose; report received 2026-04-25.

---

### File: cde_va_project_fork/do_files/settings.do

**Predecessor repo**: cde_va_project_fork
**Owner**: Christina Sun
**Pipeline phase**: foundation (settings)
**Lines**: 52
**Purpose**: Defines all global directory macros for the common-core-VA project. No code execution beyond `global` assignments — pure path declarations.

**Globals defined** (no hostname-branching anywhere; all paths hardcoded to the Scribe `/home/research/...` tree):

- `$rawcsvdir` = `/home/research/ca_ed_lab/data/restricted_access/raw/calschls/csv` (line 12)
- `$rawdtadir` = `/home/research/ca_ed_lab/data/restricted_access/raw/calschls/stata` (line 16)
- `$clndtadir` = `/home/research/ca_ed_lab/data/restricted_access/clean/calschls` (line 20)
- `$projdir` = `/home/research/ca_ed_lab/users/chesun/gsr/caschls` (line 25) — **points to the caschls sibling repo location, NOT the cde_va_project_fork's own location**
- `$vaprojdir` = `/home/research/ca_ed_lab/projects/common_core_va` (line 28)
- `$vadtadir` = `/home/research/ca_ed_lab/projects/common_core_va/data/sbac` (line 31)
- `$cstdtadir` = `/home/research/ca_ed_lab/data/restricted_access/clean/cde/cst` (line 35)
- `$nscdtadir` = `/home/research/ca_ed_lab/data/restricted_access/clean/cde_nsc` (line 39)
- `$nscdtadir_oldformat` = `/home/research/ca_ed_lab/data/restricted_access/clean/cde_nsc/oldformat` (line 42)
- `$mattxwalks` = `/home/research/ca_ed_lab/users/msnaven/data/restricted_access/clean/crosswalks` (line 45) — Matt Naven's user-tree (cross-user dependency)
- `$vaprojxwalks` = `/home/research/ca_ed_lab/projects/common_core_va/data/restricted_access/clean/crosswalks` (line 49)
- `$distance_dtadir` = `/home/research/ca_ed_lab/projects/common_core_va/data/k12_postsec_distance` (line 52)

**Inputs / Outputs**: none (pure declaration file).
**Sourced helpers / Calls**: none.
**Path references that need updating**: every line. The dual `$projdir` (caschls) + `$vaprojdir` (common_core_va) split needs to collapse to a single project root in the consolidated layout.
**Stata version / syntax**: no `version` statement; pure macro syntax.
**ssc/community packages used**: none.
**Gotchas**:

- `$projdir` resolves to the **caschls** server location even though this file lives in cde_va_project_fork — confirms the two repos are wired to point at each other on the server.
- `$mattxwalks` lives under another user's home (`msnaven`) — when Matt's account is decommissioned this will break.

**Reference to paper outputs**: indirectly all (every downstream do-file dereferences these globals).

---

### File: caschls/do/settings.do

**Predecessor repo**: caschls
**Owner**: Christina Sun
**Pipeline phase**: foundation (settings)
**Lines**: 53
**Purpose**: Same as above — global directory definitions.

**Globals defined**: **byte-for-byte identical** to `cde_va_project_fork/do_files/settings.do` except for an extra blank line at line 43. Same paths, same `$projdir` value, same `$vaprojdir` value.

**Path references that need updating**: identical set as above.
**Critical finding**: both settings files define `$projdir` to point at caschls (`/home/research/ca_ed_lab/users/chesun/gsr/caschls`) and `$vaprojdir` to point at common_core_va (`/home/research/ca_ed_lab/projects/common_core_va`). Each repo, when its master is run, can resolve do-files in the *other* repo via `$projdir` or `$vaprojdir`. This is the cross-repo wiring that allows `do_all.do` to reach into caschls's siblingxwalk files and vice versa.

**Notes / open questions**: confirm with user whether the paths drifted in either repo since the last server run; the two on-disk copies match exactly today, but if `$projdir` on the server has been bumped, the local files are stale.

---

### File: cde_va_project_fork/do_files/do_all.do

**Predecessor repo**: cde_va_project_fork
**Owner**: Christina Sun
**Pipeline phase**: foundation (entry-point / orchestration)
**Lines**: 270
**Purpose**: Master orchestrator for the **VA-estimate side** of the project. Loads `settings.do`, then executes a long sequence of toggle-gated blocks. Currently configured with most toggles OFF; only `clean_sch_char` and `do_va_het` are ON (lines 72, 238).

**Sourced helpers**: `do do_files/settings.do` (line 8).

**Calls** (in execution order; toggle state in parens — current setting in repo):

1. `clean_acs = 0`: `$vaprojdir/do_files/acs/clean_acs_census_tract`
2. `clean_sch_char = 1`: 10 do-files in `$vaprojdir/do_files/schl_chars/` — `cds_nces_xwalk`, `clean_locale`, `clean_elsch`, `clean_enr`, `clean_frpm`, `clean_staffcred`, `clean_staffdemo`, `clean_staffschoolfte`, `clean_charter`, `clean_ecn_disadv`, `clean_sch_char`
3. `do_distance = 0`: `$vaprojdir/do_files/k12_postsec_distance/k12_postsec_distances.do`, `reconcile_cdscodes.do`
4. `do_touse_va = 0`: `do_files/sbac/touse_va.do` — note relative path, not `$vaprojdir`-prefixed
5. **`do_match_siblings = 0`**: 4 calls into the caschls repo via `$projdir` —
   - `$projdir/do/share/siblingxwalk/siblingmatch`
   - `$projdir/do/share/siblingxwalk/uniquefamily`
   - `$projdir/do/share/siblingxwalk/siblingpairxwalk`
   - `$projdir/do/share/siblingvaregs/siblingoutxwalk.do` ← lives in `siblingvaregs/` not `siblingxwalk/` (the N1 anchor)
6. `do_create_samples = 0`: `$vaprojdir/do_files/sbac/create_score_samples.do`, `create_out_samples.do`
7. `do_va = 0`: ~20 distinct files — the heart of VA estimation
8. `do_share_tables = 0`: 8 do-files in `$vaprojdir/do_files/share/`
9. **`do_va_het = 1`** ACTIVE: `va_corr_schl_char.do`, `va_corr_schl_char_fig.do`, `persist_het_student_char_fig.do`, `va_het.do`
10. `do_survey = 0`: a single line invoking the entire caschls master.do as a sub-program: `do "/home/research/ca_ed_lab/users/chesun/gsr/caschls/do/master.do"` — **a hardcoded absolute path, not `$projdir`**

**Path references that need updating**: `$vaprojdir/...` (most), `$projdir/...` (4 sibling calls), `do_files/sbac/touse_va.do` (relative), the hardcoded `/home/research/ca_ed_lab/users/chesun/gsr/caschls/do/master.do` at line 253, and `cd "/home/research/ca_ed_lab/projects/common_core_va"` at line 7.

**Stata version / syntax**: no `version` statement; uses `pause`, `timer`, `set seed 1984` (line 26). `pause off` at line 18 means subsequent `pause` invocations are no-ops.

**ssc packages used** (only when `installssc=1`, currently 0): `elabel`, `tabout`, `grstyle`, `palettes`, `colrspace`, `labutil2`, `labundef`, `rangestat`, `_gwtmean`, `estout`, `outreg2`, `regsave`, `group_twoway`, `vam`, `binscatter`, `descsave`, `parmest`, `texsave`; plus net `geodist` from BC, `opencagegeo`. **Note**: `vam` is listed for `ssc install` (line 51) but the caschls repo also ships a custom `vam.ado` — the ssc-install would silently overwrite the custom one if run.

**Gotchas**:

- Line 7 `cd` is hardcoded — must be run from a Scribe shell with that exact directory present.
- Line 26 `set seed 1984` is the project seed.
- Comment at lines 158–160 indicates Matt's original VA estimation has been archived to `do_files/_archive/matt_original/`; the active pipeline is `va_score_all` / `va_out_all`.
- Comment at line 192: `prior_decile_original_sample.dta` is consumed by `reg_out_va_all` and `reg_out_va_dk_all`.

**Reference to paper outputs**: this is the call-graph apex for everything in the paper that touches VA estimates, school characteristics, persistence figures, deep-knowledge VA, and the ACS+sibling restricted sample.

**Notes / open questions**: line 253 unconditionally chains caschls/master.do — but caschls/master.do *also* tries to run sibling code which `do_all.do` already ran in block 5. Current toggle settings (`do_match_siblings=0`, `do_survey=0`) prevent this collision, but the design fragility is worth flagging.

---

### File: caschls/do/master.do

**Predecessor repo**: caschls
**Owner**: Christina Sun
**Pipeline phase**: foundation (entry-point)
**Lines**: 633
**Purpose**: Master orchestrator for the **survey-side analysis** (CHKS — California Healthy Kids Survey). Builds analysis datasets, computes response rates, cleans QOI, runs factor analysis and category indices, runs VA regressions on resulting survey indices.

**Sourced helpers**: `do "./do/settings.do"` (line 52).

**Calls** (toggle-state in parens; default in repo):

1. **`do_match_siblings = 0`**: same 4 calls as `do_all.do` block 5 — `siblingmatch`, `uniquefamily`, `siblingpairxwalk`, `siblingoutxwalk.do`. **Identical block** — duplicated logic.
2. `do_build_data = 1`: `$projdir/do/build/prepare/renamedata`, `splitstaff0414`
3. `do_check_data = 1`: 4 files
4. `do_diagnostics = 1`: 14 files for elementary/secondary/parent representativeness diagnostics
5. `do_response_rate = 1`: 4 files
6. `do_clean_sec_qoi = 1`: 3 files (year-batched)
7. `do_clean_parent_qoi = 1`: 4 files
8. `do_clean_staff_qoi = 1`: 3 files
9. `do_pool_qoi_merge = 1`: 3 files (`secpooling`, `parentpooling`, `staffpooling`)
10. `do_pool_gr11_enr = 1`: `poolgr11enr`, `mergegr11enr`
11. `do_va_regs = 1`: `clean_va.do` then `do/share/svyvaregs/allvaregs`. **Link from caschls back to VA estimates produced in cde_va_project_fork pipeline.**
12. `dofactor = 1`: `factor`, `allsvymerge`, `allsvyfactor`, `allsvymissing`
13. `do_index = 1`: `imputation`, `imputedcategoryindex`, `compcasecategoryindex`, `indexhorserace`
14. `do_index_va_reg = 1`: `mattschlchar` (consumes `$mattxwalks`), `testscore`, `indexregwithdemo`, `indexhorseracewithdemo`, `alpha`, `indexalpha`, `pcascore`
15. `dooutcomesumstats = 0`: `nsc_codebook.do` only
16. **`do_sibling_va_regs = 0`**: ~30 files — the largest block — covering `createvasample`, `siblingvasamples`, `va_sibling 0`, `va_sibling_out 0`, the 4-spec restricted-sample creation/estimators, matching tables/figures.

**Path references that need updating**: `$projdir/...` everywhere; `cd "/home/research/ca_ed_lab/users/chesun/gsr/caschls"` at line 51 (hardcoded).

**Stata version / syntax**: no `version` statement. `set varabbrev off, perm` (line 38) is permanent. `pause off` (line 49). `do/share/siblingvaregs/va_sibling 0` (line 486) and `va_sibling_out 0` (line 508) — the `0` is a positional argument (drift-limit override; `0` means use original drift limit).

**Gotchas**:

- Block 1 (sibling matching) duplicates `do_all.do`'s sibling block exactly.
- Comment at lines 109–122 ("THIS IS WHERE TO RUN THE VA ESTIMATES DO FILES") is a placeholder gap with **no actual `do` calls** — VA estimation is run from `do_all.do` instead, and master.do consumes the *output* via `clean_va.do` at line 341.
- `va_sibling 0` and `va_sibling_out 0` take a numeric arg whose semantics ("0 for original drift limit; otherwise set a number if encountering an error") are documented only in inline comments at lines 481–486 and 500–507.
- Line 13 says "All regressions are run using version 1 VA data" — anchors the v1-canonical convention.

**Reference to paper outputs**: feeds the survey-index regressions (CHKS climate/staff-quality/student-support/student-motivation indices regressed on VA), Cronbach's alpha, factor analysis, sibling-restricted-sample 4-specification table/figure family.

**Notes / open questions**: 4 sibling calls confirmed (NOT 5).

---

### File: cde_va_project_fork/do_files/sbac/macros_va.doh

**Predecessor repo**: cde_va_project_fork
**Owner**: Christina Sun (change-log style; entries 4/28/2022 → 8/22/2024)
**Pipeline phase**: foundation (macro definitions / variable-naming convention authority)
**Lines**: 612
**Purpose**: Defines all reusable local macros for VA estimation: file paths, year ranges, control-variable lists, sample/specification combinations, label strings. **Variable-naming convention authority** for the entire pipeline.

**Path macros** (lines 22–31, all `local`):

- `home` = `$vaprojdir`
- `vaprojdofiles` = `$vaprojdir/do_files`
- `ca_ed_lab` = `/home/research/ca_ed_lab` (hardcoded)
- `k12_test_scores` = `$vaprojdir/data/restricted_access/clean/k12_test_scores`
- `public_access` = `$vaprojdir/data/public_access`
- `k12_public_schools` = `$vaprojdir/data/public_access/clean/k12_public_schools`
- `k12_test_scores_public` = `$vaprojdir/data/public_access/clean/k12_test_scores`
- `siblingxwalk` = `$projdir/dta/siblingxwalk/siblingpairxwalk` — **points into caschls repo**
- `ufamilyxwalk` = `$projdir/dta/siblingxwalk/ufamilyxwalk` — caschls
- `sibling_out_xwalk` = `$projdir/dta/siblingxwalk/sibling_out_xwalk` — caschls

**Year-range macros** (lines 35–65): `test_score_min_year=2015`, `test_score_max_year=2018`, `star_min_year=2003`, `star_max_year=2013`, `caaspp_min_year=2015`, `caaspp_max_year=2019`, `outcome_min_year=2015`, `outcome_max_year=2018`.

**Outcome label strings** (lines 71–86): `ela_str`, `math_str`, `enr_str`, `enr_2year_str`, `enr_4year_str`.

**Sibling-census restricted-sample label strings** (lines 90–104): `og_str`, `acs_str`, `sib_str`, `both_str`.

**Control-variable building blocks** (lines 109–203):

- `school_controls` (line 110) — empty (cohort_size commented out)
- `demographic_controls` (line 113): `age, i.male, eth_asian/hispanic/black/other, econ_disadvantage, limited_eng_prof, disabled`
- `ela_score_controls` (line 122): `i.year#(c.prior_ela_z_score##c.prior_ela_z_score##c.prior_ela_z_score)` — year-interacted cubic
- `ela_scrhat_controls` (line 127): same but with `prior_ela_z_score_hat` — predicted-score variant (added 8/22/2024)
- `math_score_controls`, `peer_*` analogs
- `va_control_vars` (lines 156–158): collapses school+demographic into a clean variable list
- `census_grade=6` (line 160) — grade level at which census-tract controls merged
- `census_controls` (line 164): `eth_asian_pct, eth_hispanic_pct, eth_black_pct, educ_hs_dropout_prop, educ_deg_4year_plus_prop, pov_fam_child_lt18_pct, inc_median_hh`
- `peer_census_controls`
- `sibling_controls` (line 177): `i.has_older_sibling_enr_2year, i.has_older_sibling_enr_4year`
- `peer_sibling_controls`
- `sib_lag1_controls` / `sib_lag2_controls`: lag specifications for forecast-bias diagnostic
- `d_controls` (line 200): `mindist_any_nonprof_4yr, mindist_ccc` — postsecondary-distance controls (added 5/31/2023)

**Standalone-control macros for loops** (lines 207–306) — naming `<combo>_controls` where combo ∈ {b, l, a, s, la, ls, as, las}:

- `b_controls` = base = school + demographic + ELA-score + math-score
- `l_controls` = `loscore` (just leave-out-score)
- `a_controls` = `census_controls`
- `s_controls` = `sibling_controls`
- `la, ls, as, las_controls` = combinations
- `peer_*_controls` analogs
- `foreach control in b l a s la ls as las` loop (line 298) generates `<combo>d_controls` (with distance) and `peer_<combo>d_controls` programmatically — **but line 304: `peer_<combo>d_controls = peer_<combo>_controls` (no `peer_d_controls` exists). May be intentional or a bug.**

**Specification-combination macros** (lines 312–477) — naming `<combo>_spec_controls` and `<combo>_scrhat_spec_controls` where combo ∈ {b, bd, l, ld, a, ad, s, sd, la, lad, ls, lsd, as, asd, las, lasd}. Each starts from `b_spec_controls` (base) and adds combination-specific controls. The `_scrhat_` variants substitute `b_scrhat_spec_controls` (which uses `ela_scrhat_controls`) for the base — these are the v2 predicted-prior-score variants.

**Label strings for combinations** (lines 481–547): `b_str="base"`, `l_str="leave out score"`, `a_str="ACS"`, `s_str="sibling"`, `la_str="leave out score & ACS"`, etc.

**Heterogeneity-variable strings** (lines 550–564): `race_str`, `male_str`, `econ_disadvantage_str`, `prop_ecn_disadv_str`, `charter_str`, `inc_median_hh_xtile_str`, `enr_black_hisp_prop_str`.

**School-characteristics macros** (lines 567–609): `sch_chars`, `sch_char_vars`, `dem_chars`, `dem_char_vars`, `expenditures`, `expenditure_vars`, `sch_char_control_vars`.

**Stata version / syntax**: uses `#delimit ;` for the entire body (line 19), `#delimit cr` at end (line 612). Heavy use of `local <name> : list ...`.

**Gotchas**:

- The change-log notes "v1/v2" but on inspection, **`scrhat` ≠ v2**. The `scrhat` variants are the *predicted-prior-score* exploratory specs (added Aug 2024). The v1/v2 distinction the user flagged is about prior-score controls more broadly; in this file the v2 manifests as the `_scrhat_` family. **Verify**: is `scrhat` *one of* the v2 variants, or orthogonal to v1/v2? **DEFERRED** until full read complete (per user direction 2026-04-25).
- Naming convention confirmed: `b/l/a/s/d` with combinations, `peer_` prefix, `_str` suffix, `_controls` (standalone) vs `_spec_controls` (full spec), `_scrhat_` infix.
- Conventions the user mentioned but **not visible in this file** (`sp`, `ct`, `nw`, `_m`, `_wt`): not defined in macros_va.doh — flagged for downstream chunks.
- **Bug at line 535**: `asd_str = a_str` (NOT `as_str`) — copy-paste typo. **FIXED** in commit `e8dd083` (cde_va_project_fork). Verified the rest of the `<combo>d_str` family (sd, ld, ad, lad, lsd, lasd) all follow the correct pattern (`<combo>d_str = \`<combo>_str'`); asd_str was the only outlier.
- **Bug at line 558**: `prop_ecn_disadv_str` missing trailing `;`. **FIXED** in commit `e8dd083` (cde_va_project_fork).
- **Empty `peer_d_controls` issue** (line 304 loop): `peer_<combo>d_controls` lacks any peer-distance terms. Defer to downstream-chunk verification.

**Reference to paper outputs**: source for **every** VA-estimation regression in the paper.

---

### File: caschls/do/ado/vam.ado

**Predecessor repo**: caschls (only place this lives)
**Owner**: Michael Stepner (original; line 1: `*! version 2.0.1 27jul2013 Michael Stepner, stepner@mit.edu`); CC0 license. **No Christina/Matt modifications visible from version-string or comment headers** — see synthesis for diff recommendation.
**Pipeline phase**: foundation (custom shrinkage estimator)
**Lines**: 760
**Purpose**: Implements the Chetty-Friedman-Rockoff (CFR 2014) value-added shrinkage estimator with empirical-Bayes drift correction. Produces teacher value-added (`tv`) plus optional quasi-experimental variants.

**Stata `program define vam`** (lines 14–502):

- Syntax: `vam varname [aw] , teacher() year() class() [by() controls() absorb() tfx_resid() data() output() output_addvars() driftlimit(int) QUASIexperiment CONStant noseed varclasszero estimates()]`
- `version 10.1` (line 16)
- Validates `data` argument as one of: `preserve`, `tv`, `merge tv`, `merge score_r`, `merge tv score_r`, `merge score_r tv`, `variance`
- Mutual exclusion of `absorb` and `tfx_resid`
- Main estimation loop over by-vals: `areg`/`reg` → residuals to `score_r` → variance components (`var_total`, `var_ind`, `var_class`) → precision weights → collapse to teacher-year → `compute_cov_corr` (mata) → `create_m` autocov vector → `driftcalclist` (mata) GLS-weighted shrinkage → produce `tv`
- Quasi-experimental branch produces `tv_2yr_l/f/ss` by zeroing specific lag positions

**Mata functions** (lines 506–760):

- `computeweights(M, i, c, [weights])` — GLS shrinkage weights
- `compute_cov_corr(scores_var, weight_var, dim, teacher_var)` — Stata-callbacked covariance/correlation/SE accumulator
- `create_m(lag_covariances, cov_sameyear, [lagdim, driftlimit])` — autocov vector with drift truncation
- `vectorToStripeDiag(m)` — Toeplitz/striped-diagonal matrix builder
- `driftcalc(M, i, c, weights, scores)` and `driftcalclist(...)` — main shrinkage loop

**Inputs / Outputs**: dataset-in-memory (test-score panel); writes `<output>.dta` (teacher-year VA) and `<output>_variance.csv` (variance components per by-val).

**Stata version / syntax**: `version 10.1` for the main program; `version 11` + `set matastrict on` for the mata block (lines 505–506). Uses `tsset`, `egen`, `collapse`, `corr ..., cov`, `tsset` time-series operators.

**ssc packages used**: none — entirely self-contained.

**Gotchas**:

- **`set seed 9827496` hardcoded inside vam (line 253)** when generating the random class-numbering tiebreaker for same-year covariance computation — overrides any caller-set seed. The `noseed` option (in syntax line 26) appears to skip this but is **not actually checked anywhere** — line 252 reads `if "\`seed'"==""`. The macro `seed` is never set elsewhere; **`noseed` is a no-op and the hardcoded seed always fires**. Critical for reproducibility — but reproducible (deterministic).
- Lines 219–225, 293–301, 313–326: commented-out branches for `ind_weight` (individual student-level weights). Active code path uses class-mean branch only. **`ind_weight`/`aweight` path appears partially disabled.**
- Line 314 `collapse` uses `(rawsum) weight` and `[aw=weight]` simultaneously — Stata-correct but subtle.
- `data` parameter accepts `merge tv score_r` and `merge score_r tv` as equivalent.

**Reference to paper outputs**: `vam` invoked by `va_score_all.do`, `va_out_all.do`, `va_score_fb_all.do`, `va_out_fb_all.do`, `va_sibling`, `va_sibling_out`, `va_sib_acs`, `va_sib_acs_out`, `va_sib_acs_out_dk`, etc. — every value-added estimate in the paper.

**Notes / open questions**:

- **Diff vs SSC vam recommendation**: version string `2.0.1 27jul2013` matches Stepner's GitHub release. On a careful read, **no Christina/Matt modifications are identifiable**. Either (a) this is a clean copy preserved locally to insulate against ssc updates, (b) modifications are subtle (numerical tolerance, print suppression) that need a `diff` to detect, or (c) misremembering. **Strongly recommend running `ssc install vam, replace` in a sandbox and `diff` against this file.**
- The hardcoded `set seed 9827496` overriding `noseed` is a real bug if the user expects `noseed` to work. Should the consolidated version preserve or fix this?
- Why is the `ind_weight` branch commented out?

**Update 2026-04-25 (post-foundation, Christina ran the diff):**

- User downloaded the server's `vam.ado` and placed it at `caschls/do/ado/server_vam/vam.ado`. **Diff against `caschls/do/ado/vam.ado` is empty; both files are byte-identical (26185 bytes).** Confirms: server's `vam.ado` matches local; both match Stepner v2.0.1 27jul2013; no Christina/Matt modifications.
- **Critical operational finding via grep**: NO `adopath ++` or `sysdir set` invocation exists anywhere in either repo. The local `caschls/do/ado/vam.ado` is therefore **not on the Stata search path** at runtime. Stata's default adopath does not include `do/ado/`; it includes `./ado/` relative to cwd, which would be `caschls/ado/` (not `caschls/do/ado/`). So **the local `vam.ado` is dead code today** — every `vam` invocation hits the SSC-installed version. SSC version has the same content (Stepner v2.0.1) as the local copy, so behavior is unaffected, but this means:
  - Bug fixes to the local `vam.ado` only take effect after consolidation (where `settings.do` will `adopath ++ "$projdir/ado"`).
  - The two `ssc install vam, replace` lines (`do_all.do:51`, `master.do:73`) are how vam gets onto the adopath today (via PLUS).
- **vam usage** (verified by grep): ~30 invocations across 9 files in cde_va_project_fork's sbac/ subdir + the explore/ predicted-score variant. Heavy use across va_score_all, va_out_all, va_score_fb_all, va_out_fb_all, va_score_spec_test_tab, va_out_spec_test_tab, va_score_sib_lag, va_out_sib_lag, va_predicted_score. Plus more in caschls's siblingvaregs (per the ssc-install comments at lines 40, 18, 43 in three va_sibling*.do files). vam is critical-path.

**Fixes applied (post-foundation)**:

- **noseed bug**: fixed in `caschls/do/ado/vam.ado` at commit `0202251` (caschls). Line 252 changed from `if "\`seed'"==""` to `if "\`noseed'"==""`. Note: fix only takes effect once vam.ado is on the adopath via consolidated settings.do; for predecessor pipeline runs, the SSC vam still has the bug (but the seed override is deterministic, so reproducibility is preserved either way).
- **server_vam folder** preserved as a snapshot reference (per Christina's intention); not modified.

**Fixed-effects compatibility verification (the question Christina raised)**:

Christina recalled Matt saying the original vam package doesn't support fixed-effects controls. Investigated:

- **Code uses `i.year` (and other factor variables) inside `controls(...)`**, not via `absorb()` or `tfx_resid()`. Verified by grep across va_score_all.do, va_out_all.do — no absorb/tfx_resid usage; all FE go through the controls list.
- **Local vam.ado syntax declaration** (line 22): `controls(varlist ts fv)` — the `ts fv` qualifiers explicitly allow time-series operators AND factor-variable syntax in the controls list.
- **Stepner v2.0.1 (27jul2013)** is what we have locally and what's on the server. v2.0.1 was a major refactor that added `ts fv` syntax support (Stata 11+ feature; Stata 11 released 2009).
- **Matt's recollection likely refers to an earlier vam version** (v1.x circa 2010-2011), pre-`ts fv` syntax. The team upgraded to v2.0.1 at some point — whether deliberately or via an SSC update — and the `i.year` usage works fine on the published v2.0.1.

**Bottom line**: there is **no custom vam**. The SSC-published v2.0.1 handles the team's `i.year`-in-controls usage natively. The "custom vam package" recollection was likely a misattribution from an earlier version of the codebase. Both the local copy and the server-downloaded copy are clean Stepner v2.0.1.

**Implication for consolidation**: ADR-0009 (custom vam handling) should reframe — we're not preserving "modifications", we're pinning v2.0.1 against potential future SSC updates. Two options for the consolidated repo:

- (a) Ship `ado/vam.ado` (the same Stepner v2.0.1 file, with the `noseed` fix applied) and `adopath ++ "$projdir/ado"` in settings.do. Pinned, drift-resistant.
- (b) Rely on `ssc install vam, replace`. Simpler but vulnerable to future SSC updates if Stepner ever pushes a breaking change (unlikely; the package hasn't been updated since 2013).

Recommendation: option (a). Same as v2 plan §3 + §7. The pin is cheap insurance.

**Beyond `i.year`: full vam-invocation compatibility verification (2026-04-25)**

User asked to verify every vam usage pattern, not just `i.year`, against published v2.0.1. Inventoried 40+ vam invocations across 13 files (9 in cde_va_project_fork sbac/explore, 4 in caschls share/siblingvaregs).

**Option-set actually used** (uniform across all invocations):

| Option | Argument(s) used | Stepner v2.0.1 syntax | Valid? |
|---|---|---|---|
| `<depvar>` | simple z-score / outcome names | `varname(ts fv)` | ✓ |
| `teacher()` | `school_id` (always) | `varname` | ✓ |
| `year()` | `year` (always) | `varname` | ✓ |
| `class()` | `school_id` (always — equals `teacher` for school-level VA) | `varname` | ✓ |
| `controls()` | `i.year` + macros containing `i.year#(c.X##c.X##c.X)` cubic interactions | `varlist ts fv` accepts `i.`, `c.`, `##` | ✓ |
| `data()` | `merge tv score_r` or `variance` (spec-test only) | `data(string)`; both values explicitly validated in vam.ado lines 67-75 | ✓ |
| `driftlimit()` | numeric local | `integer -1` default | ✓ |
| `estimates()` | path with `replace` | `string asis` | ✓ |

**Options NOT used anywhere** (so we don't need to verify them): `by()`, `absorb()`, `tfx_resid()`, `output()`, `output_addvars()`, `quasiexperiment`, `constant`, `noseed`, `varclasszero`, `[aweight]`.

**Patterns specifically checked**:

1. **`teacher(school_id) class(school_id)`** (same variable for both): standard CFR school-level adaptation. Vam's variance decomposition handles the degenerate case (within-class variance becomes school-year residual variance).
2. **`controls(i.year \`b_controls' ...)`**: macros already contain `i.year#(c....)` interactions; the explicit `i.year` adds the main effect. No double-counting; standard "year main + year-by-cubic" specification.
3. **VA estimates as controls** (`va_cfr_g11_ela`, `va_cfr_g11_math` at va_out_all.do:138-139): continuous variables, no factor syntax needed; valid.
4. **Reserved names** (`tv`, `score_r`): every vam call is followed by `rename tv ...` / `rename score_r ...`. Conflict-free.
5. **Caschls vam invocations** (in va_sibling.do, va_sibling_out.do, va_sib_acs_out.do, va_sibling_out_forecast_bias.do): same pattern, same option set. Compatible.

**Verdict**: the published Stepner vam v2.0.1 can run every invocation in the codebase as-is. No customization required. The `noseed` bug (now fixed in our local copy at commit `0202251`) is the only deviation from textbook; it's deterministic so reproducibility is unaffected.

---

## Foundation chunk synthesis

### Path geometry summary (resolves N2)

The two folders on Scribe are **co-resident and cross-wired**, not redundant:

```
/home/research/ca_ed_lab/
├── projects/common_core_va/            ← $vaprojdir (cde_va_project_fork's home)
│   ├── do_files/                       ← cde_va_project_fork content
│   ├── data/sbac/                      ← VA estimates output ($vadtadir)
│   ├── data/k12_postsec_distance/
│   ├── data/restricted_access/clean/crosswalks/  ← $vaprojxwalks
│   └── data/restricted_access/clean/k12_test_scores/
└── users/chesun/gsr/caschls/           ← $projdir (caschls's home)
    └── do/                              ← caschls content
        ├── share/siblingxwalk/         ← sibling matching pipeline
        ├── share/siblingvaregs/        ← sibling VA regressions, incl siblingoutxwalk.do
        ├── ado/vam.ado                 ← local vam package (overrides ssc)
        └── share/svyvaregs/            ← survey VA regs
```

**Both `settings.do` files (in both repos) define the same `$projdir` and `$vaprojdir`.** This is the cross-wiring: from cde_va_project_fork, scripts can reach into caschls via `$projdir/do/...`; from caschls, scripts can reach into cde_va_project_fork via `$vaprojdir/do_files/...`. Both repos *must* be checked out side-by-side at exact server paths for either pipeline to run.

The `cd` statements at `do_all.do:7` (`cd "$vaprojdir"` literal) and `master.do:51` (`cd "$projdir"` literal) lock each entry-point to its own root, but cross-references via globals work regardless of cwd.

**Consolidation implication**: in the consolidated layout, both subroots collapse under one repo. The two settings files merge into one with a single `$projdir`. Every `$projdir/do/share/...` reference in `do_all.do`, `master.do`, and `macros_va.doh` becomes a single-repo subpath. The `$mattxwalks` reference (cross-user, `users/msnaven/...`) is the only path that genuinely lives outside the project tree — should either be vendored into the consolidated `data/` or replaced with a symlink that survives Matt's account decommissioning.

### Naming convention authority

`macros_va.doh` is the single source of truth. Confirmed conventions:

| Convention | Definition | Lines |
|---|---|---|
| `b` | base sample/controls (school + demographic + ELA-score + math-score) | 208–213 |
| `l` | leave-out score (`loscore`) | 222–225 |
| `a` | ACS / census-tract controls | 233–235 |
| `s` | sibling controls | 242–244 |
| `d` | postsecondary distance | 200–203 |
| `la, ls, as, las` (and `+d`) | combinations | 252–296, 298–306 |
| `peer_` prefix | peer-effect analogs of any control block | 137–152, 171, 182, etc. |
| `_str` suffix | display-string label | 481–547 |
| `_controls` | standalone control block | passim |
| `_spec_controls` | full specification (base + adds) | 312–477 |
| `_scrhat_` infix | predicted-prior-score variant (added 8/22/2024) | 127–129, 319–476 |

**Conventions the user mentioned but not visible in macros_va.doh** (`sp`, `ct`, `nw`, `_m`, `_wt`): flagged for downstream chunks. Likely defined in `va_score_all` / `va_out_all` or `caschls/do/share/siblingvaregs/vaestmacros.doh`.

### Call graph at the entry-point level

```
do_all.do (cde_va_project_fork)              master.do (caschls)
  │  cd $vaprojdir                              │  cd $projdir
  │  do $vaprojdir/.../settings.do              │  do $projdir/do/settings.do
  │                                              │
  ├──[block 5, currently OFF] ────┐  ┌──────────┤  [block 1 do_match_siblings, currently OFF]
  │   sibling matching (4 calls)  │  │   sibling matching (SAME 4 calls) ← duplicated
  │   into $projdir/...           │  │   into $projdir/...
  │                                                │
  ├──[block 7, do_va, OFF]                          │
  │   ~20 VA estimation files (heart of paper)   │
  │                                                │
  ├──[block 9, do_va_het = 1 ACTIVE]                │
  │   4 heterogeneity files for R&R                │
  │                                                │  [blocks 2-14, ALL ACTIVE]
  └──[block 10, do_survey, OFF]──────────────►      │ build/check/diagnostics → response rate
      "do .../caschls/do/master.do" ←                  qoi clean → pool → factor → index
       hardcoded absolute path                       │   index_va_reg → outcomesumstats
                                                    │
                                                    └──[block 16 do_sibling_va_regs, OFF]
                                                       ~30 files for sibling 4-spec analysis
```

In steady state: `do_all.do` runs the VA pipeline first, producing VA-estimate output dtas, then `master.do` runs to consume them via `clean_va.do` + `allvaregs` for survey regressions. The `do_survey` toggle in `do_all.do` enables the latter chained run.

### Custom vam diff (best effort)

`vam.ado` presents itself as Stepner's v2.0.1 27jul2013 with no header annotation indicating modifications. The license, comments, syntax, mata functions, and control flow all match what would be expected from public ssc package at that version. **Agent was unable to identify any modifications by Christina or Matt from reading the file alone.**

**Recommendation**: have user run `ssc install vam, replace` into a clean ado-path in a sandbox and `diff` resulting `vam.ado` against `caschls/do/ado/vam.ado`. If diff is empty, this is a pinned copy — still important to preserve in consolidated repo so SSC drift cannot break replication.

**One real bug noticed**: the `noseed` option (declared at line 26) is documented as suppressing the hardcoded `set seed 9827496` (line 253), but the actual check at line 252 references a macro `seed` that is never set anywhere — the `noseed` option toggles a macro called `noseed`, not `seed`. `noseed` does nothing; the hardcoded seed always fires.

### Anomalies that affect downstream chunks

1. **macros_va.doh:535** — `asd_str = a_str` (should be `as_str` per surrounding semantics).
2. **macros_va.doh:558** — missing trailing `;` under `#delimit ;`.
3. **vam.ado `ind_weight` branch commented out throughout** (lines 219–225, 293–301, 313–326). All VA estimates use class-level weighting only.
4. **vam.ado hardcoded seed override** (line 253) means project-level `set seed 1984` (do_all.do:26) is *not* the seed for VA shrinkage — uses 9827496. Reproducibility fine (deterministic) but AEA-replication seed disclosure needs both numbers.
5. **Duplicated sibling-matching block** in do_all.do:121-144 and master.do:82-105.
6. **Cross-user dependency on `$mattxwalks`** — `/home/research/ca_ed_lab/users/msnaven/...`.
7. **`ssc install vam, replace`** in do_all.do:51 may overwrite the local custom `vam.ado` depending on adopath order.
8. **`_scrhat_` ≠ v1/v2 as initially understood**. `_scrhat_` is the predicted-prior-score variant (added 8/22/2024). The v1/v2 distinction is about prior-score controls more broadly (`create_prior_scores_v1.doh` / `_v2.doh`). **Need to verify** if `_scrhat_` is one of the v2 variants or orthogonal.

### Open questions

**For user**:

- macros_va.doh:535 string mismatch — bug or intentional?
- macros_va.doh:558 missing semicolon — confirm bug.
- `noseed` option in vam.ado — should the consolidated version fix this so the project-level seed flows through?
- Is `vam.ado` actually customized vs. a clean Stepner copy? (Run the diff.)
- Is the cross-repo `$mattxwalks` dependency planned to be vendored into the consolidated repo, or is there an arrangement with Matt for permanent access?
- Is `_scrhat_` part of the v2 family or orthogonal?

**Resolvable in downstream chunks**:

- Where are `sp`, `ct`, `nw`, `_m`, `_wt` conventions defined? — likely in va_score_all/va_out_all chunk, or vaestmacros.doh / vafilemacros.doh in caschls.
- Full v1 vs v2 prior-score split — `cde_va_project_fork/do_files/sbac/create_prior_scores_v1.doh` and `_v2.doh` need reading.
- The `_archive/matt_original/` folder (referenced at do_all.do:158) inventory — confirm what was superseded.
- `siblingoutxwalk.do` in `siblingvaregs/` — read its actual contents to determine whether it's a matching step or a VA-prep step. Defer to sibling chunk.

---

## Cross-cutting findings (rolled up across chunks)

### N1: siblingoutxwalk relocation -- dependency trace

Foundation finding: file confirmed at `caschls/do/share/siblingvaregs/siblingoutxwalk.do`; called from BOTH masters' sibling-matching block. Whether it should relocate to `sibling_xwalk/` depends on its actual content (the dependency-trace question). Defer to sibling_xwalk chunk.

### N2: server-folder reconciliation -- RESOLVED

The two folders are co-resident, cross-wired, both required. See "Path geometry summary" above. ADR-0016 can now be drafted: canonical server location for the consolidated repo is `/home/research/ca_ed_lab/projects/common_core_va` (the `$vaprojdir` location); the caschls subroot at `users/chesun/gsr/caschls/` should be archived after consolidation completes.

### Path-reference catalog

See `quality_reports/audits/2026-04-25_path-references.md`.

### Dependency graph

See `quality_reports/audits/2026-04-25_dependency-graph.md`.

---

## Chunk 2: VA-core helpers (COMPLETE)

Files audited: `create_va_sample.doh`, `create_va_g11_sample.doh` (+ `_v1.doh`, `_v2.doh` siblings), `create_va_g11_out_sample.doh` (+ siblings), `create_diff_school_prop.doh`, `create_prior_scores_v1.doh`, `create_prior_scores_v2.doh`, `merge_k12_postsecondary.doh`, plus discovered helpers (`drift_limit.doh`, `out_drift_limit.doh`, `merge_lag2_ela.doh`, `merge_loscore.doh`, `merge_sib.doh`, `merge_va_smp_acs.doh`, `macros_va_all_samples_controls.doh`); caschls `vafilemacros.doh` and `vaestmacros.doh`.

Chunk 2 agent: general-purpose; report received 2026-04-25.

### File: cde_va_project_fork/do_files/sbac/create_va_sample.doh

**Owner**: Matt Naven (no header; Matt-style merge chain)
**Lines**: 57
**Purpose**: Master VA dataset constructor. Use cleaned K12 test scores; merge in lagged scores, peer scores, school grade-span proportions, median cohort sizes, conventional-school flag; apply two early sample restrictions.

**Sample restrictions**: L50 `keep if conventional_school==1`; L57 `drop if cohort_size<=10` (school-median cohort cut).

**Inputs**: `k12_test_scores_clean.dta`, `va_samples.dta`, `k12_lag_test_scores_clean.dta`, `k12_peer_test_scores_clean.dta`, `k12_diff_school_prop_schyr.dta`, `k12_cohort_size_sch.dta`, `k12_public_schools_clean.dta`. **Gotchas**:
- L52, L54 contain comments describing restrictions (">25% special ed", "home/hospital instruction") that are NOT implemented in code. Either upstream in `k12_test_scores_clean.dta` or unimplemented intent.
- L26 keepusing list does NOT include `peer_L3_cst_ela_z_score`, but `create_prior_scores_v1.doh` L16 references it. **Possible silent bug** — `peer_prior_ela_z_score` may be missing for STAR-era cohorts in the `_g11_` pipeline.
- L50's `keep if` is a HARDER drop than `touse_va.do` L102's `replace touse=0 if conventional_school!=1`.

### File: cde_va_project_fork/do_files/sbac/create_va_g11_sample.doh

**Owner**: Christina Sun (L1 "create version 1 of VA samples")
**Lines**: 16
**Purpose**: Restrict master VA dataset to grade-11 CAASPP, apply 95% same-school threshold, build v1 prior-score controls, save tempfile.
**Sample restrictions**: L4 `use if grade==11 & dataset=="CAASPP" & inrange(year, test_score_min_year, test_score_max_year)`; L7 `keep if diff_school_prop>=0.95`.
**Sourced helpers**: `create_diff_school_prop.doh` (L6), `create_prior_scores_v1.doh` (L9). **Byte-identical to `create_va_g11_sample_v1.doh`.**

### File: cde_va_project_fork/do_files/sbac/create_va_g11_out_sample.doh

Same structure as the score variant; uses `outcome_min_year`/`outcome_max_year` (instead of `test_score_*_year`). Tempfile name `va_g11_dataset` collides with the score variant's tempfile if both helpers are sourced in one session — verify no caller does this in Chunk 3+.

### File: cde_va_project_fork/do_files/sbac/create_diff_school_prop.doh

**Lines**: 2 — single year-conditional gen.

```stata
gen     diff_school_prop = gr11_L3_diff_school_prop if year!=2017
replace diff_school_prop = gr11_L4_diff_school_prop if year==2017
```

**Critical**: the year-2017 carve-out matches v1's 2017 ELA carve-out (uses 7th-grade lookback because spring-2014 was the no-test transition year). Load-bearing logic; consolidation must preserve.

### File: cde_va_project_fork/do_files/sbac/create_prior_scores_v1.doh — VERIFIED

**v1 verification (all four cohorts match user's table exactly)**:

| Cohort | v1 ELA prior | code line | v1 Math prior | code line |
|---|---|---|---|---|
| 2015 | 8th ELA sp 2012 | L12 (CST L3) | 6th math sp 2010 | L22 (CST L5) |
| 2016 | 8th ELA sp 2013 | L12 (CST L3) | 6th math sp 2011 | L22 (CST L5) |
| 2017 | 7th ELA sp 2013 | L14 (CST L4) | 6th math sp 2012 | L22 (CST L5) |
| 2018 | 8th ELA sp 2015 | L13 (SBAC L3) | 8th math sp 2015 | L23 (SBAC L3) |

The 2017 ELA carve-out (L4 instead of L3 lookback) is asymmetric with math (which stays on L5 for all cohorts) because grade-7 CST ELA is available for 2017 lookback whereas grade-8 CST ELA isn't.

### File: cde_va_project_fork/do_files/sbac/create_prior_scores_v2.doh — DISCREPANCY WITH USER TABLE

**v2 code says 6th-grade ELA (year-5)** for all STAR-era cohorts:

| Cohort | User's v2 ELA claim | What code actually computes (L13: L5_cst_ela_z_score) |
|---|---|---|
| 2015 | 6th ELA sp 2012 | **6th ELA sp 2010** |
| 2016 | 6th ELA sp 2013 | **6th ELA sp 2011** |
| 2017 | 6th ELA sp 2013 | **6th ELA sp 2012** |
| 2018 | 8th ELA sp 2015 | 8th ELA sp 2015 ✓ |

The v2 file's own header comment block (lines 6-8) ALSO has the same wrong dates as the user's table. So it's a header transcription error that propagated to user's mental model. Code is authoritative.

### File: cde_va_project_fork/do_files/merge_k12_postsecondary.doh

**Owner**: Matt Naven (header L4 "First created by Matthew Naven on June 11, 2018")
**Lines**: 479
**Purpose**: Merge K-12 records to NSC, CCC, CSU postsecondary data; build composite enrollment, persistence, degree variables.
**Args**: optional `enr_only` (skips persistence/degree construction).

**Year windows defined as locals** (L22-44): NSC HS-grad 2010-2019, NSC enr 2010-2020, NSC deg 2011-2020, CCC enr 1993-2017, CCC deg 1993-2016, CSU app 2002-2017, CSU enr 2002-2017, CSU deg 2002-2016.

**Variables**: `year_grad_hs`, `year_college`, `k12_nsc_match`, `k12_ccc_match`, `k12_csu_match`, composites `enr`, `enr_2year`, `enr_4year`, `enr_pub`, `enr_priv`, `enr_instate`, `enr_outstate`, `persist_year2/3/4`, `deg`, `deg_2year`, `deg_4year`.

**Mutex rules** (load-bearing): L346 `replace enr_2year = 0 if enr_4year==1` (4-year trumps 2-year); L366 `replace enr_pub = 0 if enr_priv==1`; L386 `replace enr_instate = 0 if enr_outstate==1`. Preserve in consolidation.

**Bugs / gotchas**:
- **L7 hardcoded absolute path**: `local crosswalks "/home/research/ca_ed_lab/projects/common_core_va/data/restricted_access/clean/crosswalks/"`. Needs `$vaprojdir`-relative replacement.
- **L326-327 enr asymmetry**: `gen enr = 1 if nsc_enr==1 /*| ccc_enr==1 | csu_enr==1*/` — CCC/CSU commented OUT of one-rule. Then L327 `replace enr = 0 if nsc_enr==0 & ccc_enr!=1 & csu_enr!=1` — CCC/CSU IN the zero-rule. **Asymmetry**: a student at CCC/CSU but not NSC gets `enr=.`, not `enr=1`. Either intentional NSC-anchoring or bug.
- L67 keep mode is `keep(1 3 4 5)` — non-standard; codes 4 and 5 mean using-takes-master-values via update.
- Many `tab grade year` lines are debug/diagnostic (L68, L86, L101, ...).

### File: caschls/do/share/siblingvaregs/vafilemacros.doh

**Lines**: 24
**Purpose**: Define caschls-side filename macros for cross-repo dataset paths.
**Macros**: `vaprojdofiles`, `va_dataset`, `va_g11_dataset`, `va_g11_out_dataset`, `siblingxwalk`, `ufamilyxwalk`, `k12_postsecondary_out_merge`, `sibling_out_xwalk`. All routed through `$projdir` (caschls) or `$vaprojdir` (cde_va_project_fork) — cross-repo wire-up.

**Discrepancy**: `vafilemacros.doh` L18-20 routes `va_g11_dataset` to `$projdir/dta/common_core_va/va_g11_dataset` (caschls subroot), while `vaestmacros.doh` L19 routes test-score VA estimates to `$vaprojdir/data/sbac/va_g11_<subject>.dta` (fork subroot). Inputs come from caschls; outputs go to fork. Consolidation must collapse this triangulation.

### File: caschls/do/share/siblingvaregs/vaestmacros.doh

**Lines**: 160
**Purpose**: Define `.ster` file path macros for stored regression estimates, partitioned by sample × spec × peer/no-peer.

**Naming conventions discovered here** (parallel to macros_va.doh's b/l/a/s/d):

- `_dta` = dataset suffix
- `_spec_va` = specification-test estimates
- `_va_peer` = peer-controls variant
- `_l4` = L4 leave-out scores variant
- `_census` = census-tract-restricted-sample variant
- `_sibling` = sibling-restricted-sample variant
- `_sibling_og` = original spec on sibling sample (no sibling controls)
- `_fb_` = forecast-bias test
- `_vam` = `vam` command (Stata vam package, school-by-year FE VA)
- `_nosibctrl` = without sibling controls

**Bugs**:
- **L27**: filename ends `.dta.dta` — double extension typo.
- **L45 and L118**: `"vaprojdir/estimates/sbac/..."` MISSING `$` prefix on `vaprojdir`. Resolves to literal subdirectory `vaprojdir/...` rather than the global. **TWO occurrences** — same bug class as Chunk 1's `asd_str` typo. Two `.ster` file paths affected.
- L142-159 sibling-census macros are mostly commented out — the path was incomplete.
- L1-5 header acknowledges maintenance debt: "does not include estimates from the sibling acs restricted sample. Too much bloating."

---

## Chunk 2 synthesis

### v1 verification — PASSED EXACTLY against user's table

Four cohort rows, four matches with code line citations. v1 is the canonical paper specification.

### v2 vs user's table — RESOLVED (2026-04-25)

Code in `create_prior_scores_v2.doh` L13 uses `L5_cst_ela_z_score` where **`L5` denotes 5-year lag, NOT grade 5**. For an 11th-grader taking SBAC in year T, the L5 lookback retrieves their grade-6 score (taken in year T-5). For year=2015 → spring 2010, year=2016 → spring 2011, year=2017 → spring 2012, year=2018 → year-3 (L3) SBAC = spring 2015.

Christina confirmed (2026-04-25): "the L5 stands for 5 years lag, so the year math checks out." Code is internally consistent and authoritative.

**The discrepant dates in the v2 file's header comment block (L6-8) and the user's context-dump v2 table** (sp 2012/2013/2013 for the STAR-era cohorts) **were transcription errors** that propagated from the buggy v2 header. The actual v2 spec is:

| Cohort | v2 ELA prior (per code) | v2 Math prior (per code) |
|---|---|---|
| 2015 | 6th ELA sp 2010 | 6th math sp 2010 |
| 2016 | 6th ELA sp 2011 | 6th math sp 2011 |
| 2017 | 6th ELA sp 2012 | 6th math sp 2012 |
| 2018 | 8th ELA sp 2015 | 8th math sp 2015 |

Note: the v2 file's HEADER comment block still reads sp 2012/2013/2013 — this is a documentation bug deferred until end-of-Phase-0 per "form complete mental model first" directive.

### `_scrhat_` resolution

`prior_ela_z_score_hat` is computed in EXACTLY two files:

- `cde_va_project_fork/do_files/explore/va_predicted_score.do` L58, L117
- `cde_va_project_fork/do_files/explore/va_predicted_score_fb.do` L57, L161

NOT in any helper or canonical pipeline. So `_scrhat_*` controls in `macros_va.doh` only matter if explore-pipeline scripts run first to populate the predicted variable. Per user's earlier "defer until full read", final disposition pending.

**Conclusion**: `_scrhat_` is a **third axis**, orthogonal to v1/v2. Not "v3", not part of v2.

### Naming convention catalog (full)

Complete inventory after Chunk 2:

| Token | Meaning | Defined in |
|---|---|---|
| `b` | base controls | macros_va.doh L208 |
| `l` | leave-out (forecast-bias) prior score | macros_va.doh L223 |
| `a` | ACS census-tract controls | macros_va.doh L233 |
| `s` | sibling controls | macros_va.doh L242 |
| `d` | postsecondary distance | macros_va.doh L200 |
| `la/ls/as/las` (+`d`) | combinations | macros_va.doh / macros_va_all_samples_controls.doh |
| `_p` / `peer_` | peer averages | macros_va.doh L137 |
| `_str` | display string | macros_va.doh L481 |
| `_fb_` | forecast-bias test | vaestmacros.doh L35 |
| `_scrhat_` | predicted prior score | macros_va.doh L127 |
| `_dta` | dataset filename suffix | vaestmacros.doh |
| `_spec_va` | spec-test estimates | vaestmacros.doh |
| `_l4` | L4 leave-out scores variant | vaestmacros.doh |
| `_census` | census-tract sample | vaestmacros.doh |
| `_sibling` | sibling-restricted sample | vaestmacros.doh |
| `_og` | original spec on restricted sample (no add'l controls) | vaestmacros.doh |
| `_vam` | vam command (FE VA) | vaestmacros.doh |
| `_nosibctrl` | without sibling controls | vaestmacros.doh |

**Still NOT FOUND**: `sp`, `ct`, `nw`, `_m`, `_wt`. These will appear in Chunk 3+ (output filename construction in main analysis files like `va_score_all.do`, `reg_out_va_all.do`).

### Sample-restriction map (paper Table A.1 ↔ code)

11 distinct restriction steps reconstructed from `touse_va.do`, `create_va_sample.doh`, `create_va_g11_sample.doh`, `create_diff_school_prop.doh`, `merge_sib.doh`, `merge_va_smp_acs.doh`, `merge_loscore.doh`. See chunk-2 audit detail above. **Two divergent counts**:

- `create_va_sample.doh` L57: `drop if cohort_size<=10` (school-median cohort cut)
- `touse_va.do` L155: `replace touse=0 if n_g11_*<7` (grade-11-specific count cut)

The paper / TODO summary mentioned "<=10 11th-graders". The code's grade-11 count cut is `<7`, not `<=10`. Worth verifying against paper Table A.1 wording. (The cohort_size<=10 cut is a separate, prior, school-level cut.)

### Distance + ACS variables (where computed/merged)

- **Distance** (`mindist_any_nonprof_4yr`, `mindist_ccc`): not in Chunk 2 helpers. Likely merged in `do_files/k12_postsec_distance/*` (Chunk 3+).
- **ACS** (7 census-tract vars): merged in `merge_va_smp_acs.doh` L97-98, joining `lagged_acs` on `geoid2 year_grade6`. Match window L62: grade-6 records in years `[year-5, year-5]`. With `census_grade=6`, this matches paper exactly: "matched student addresses in sixth grade to their specific Census tract".
- ACS sources: `acs_ca_census_tract_clean.dta`, `address_list_census_batch_geocoded.csv`, `address_list.dta`. Three paths to consolidate.
- Peer ACS computed via `rangestat (mean) ..., interval(year, 0, 0) by(cdscode) excludeself` (peer = same-school-and-year).

### New bugs surfaced (parallel to Chunk 1's asd_str/semicolon)

1. **`vaestmacros.doh` L27**: `.dta.dta` double extension.
2. **`vaestmacros.doh` L45 + L118**: missing `$` prefix on `vaprojdir`. Two `.ster` paths affected.
3. **`merge_k12_postsecondary.doh` L7**: hardcoded absolute path.
4. **`merge_k12_postsecondary.doh` L326-327**: `enr` definition NSC/CCC/CSU asymmetry (CCC/CSU in zero-rule but commented out of one-rule).
5. **`create_va_sample.doh` L26**: keepusing list missing `peer_L3_cst_ela_z_score` despite downstream reference.
6. **`create_va_sample.doh` L52, L54**: comments describe restrictions not implemented (>25% special-ed, home/hospital).
7. **v2 ELA spring-year discrepancy** (header L6-8 says wrong dates).
8. **`<7` vs `<=10` 11th-grader cut**: code has `<7` not `<=10`.

Per user's "form complete mental model first" directive, NOT fixing these in this chunk — collecting for end-of-Phase-0 review.

### Open questions

**For user (defer-able to end of Phase 0 unless flagged blocking)**:

- ~~Confirm v2 ELA = year-5 (6th grade) per code; the spring-2012/2013 dates in the v2 header / your table are transcription errors?~~ **RESOLVED 2026-04-25**: code is correct (L5 = 5-year lag); v2 header dates are transcription bugs (deferred fix).
- Was the NSC/CCC/CSU asymmetry in `enr` (`merge_k12_postsecondary.doh` L326-327) intentional NSC-anchoring? Significant for postsecondary identification.
- Are the un-implemented restrictions in `create_va_sample.doh` L52/54 handled upstream in `k12_test_scores_clean.dta`, or never applied?
- Is the grade-11-count cut `<7` (code) or `<=10` (paper claim)? Either fix code or fix paper.

**For downstream chunks**:

- Where do `sp/ct/nw/_m/_wt` get used? Output filename construction in main analysis files.
- Where is `mindist_*` computed? Chunk 3 `do_files/k12_postsec_distance/`.
- Verify no caller sources both `create_va_g11_sample.doh` AND `create_va_g11_out_sample.doh` (tempfile name collision risk).
- Where (if anywhere) does `prior_ela_z_score_hat` get populated for non-explore pipeline use?

---

## Chunk 3: VA-core estimation (COMPLETE — synthesis-focused)

Files audited: `va_score_all.do`, `va_out_all.do`, `va_score_fb_all.do`, `va_out_fb_all.do`, `va_score_sib_lag.do`, `va_out_sib_lag.do`, `merge_va_est.do`, `va_corr.do`, `va_score_spec_test_tab.do`, `va_out_spec_test_tab.do`, `va_score_fb_test_tab.do`, `va_out_fb_test_tab.do`, `va_spec_fb_tab.do`, `va_sib_lag_spec_fb_tab.do`, plus `drift_limit.doh` and `out_drift_limit.doh` re-checks.

Chunk 3 agent: general-purpose; report received 2026-04-25. **Note**: agent returned synthesis sections rather than per-file template entries; can re-dispatch for per-file granularity if needed for any specific file. The synthesis below preserves all line-number citations and concrete findings.

### `sp / ct / lv` resolved — they're literal filename separators, NOT macros

Confirmed across all chunk-3 files (e.g., `va_score_all.do` L80, L87, L105, L112, L123):

- `sp` = literal token between sample marker and control marker → `<sample>_sp_<ctrl>_ct`
- `ct` = literal token at end after the control marker
- `lv` = literal token at end of FB-var leave-out filename → `..._<fb_var>_lv.ster`

These were never macros — they're static separators in the filename grammar. **Naming-convention catalog updated.**

Plus the chunk found additional naming tokens:

- `_p` (peer-controls variant suffix in variable name; `_p_` infix in filename)
- `_dk` = Deep-Knowledge VA variant
- `_r` / `_r_p` / `_r_d` = residual / residual-with-FB-control / residual difference
- `predicted_prior_score/` = subfolder for scrhat (predicted prior-score) variant

### `nw / _m / _wt` STILL NOT FOUND in Chunk 3

Searched all 14 files; no occurrences. Likely live in share/, explore/, or replication-package files (Chunk 4+). User's description ("nw = non-weighted, _wt = weighted, _m = matched controls") suggests alternative inference modes overlaid on the standard pipeline.

### Output-filename construction grammar (formalized)

```
Estimates (.ster):
  estimates/va_cfr_all_<version>/{vam,spec_test,fb_test}/
    [predicted_prior_score/]
       {prefix}{_p}_<outcome>_<sample>_sp_<ctrl>_ct{_<fb_var>_lv}.ster

  prefix    ∈ {va, spec, fb, dk_va, dk_spec, dk_fb}
  peer infix `_p` inserted between prefix and outcome iff peer-controls run
  outcome   ∈ {ela, math, enr, enr_2year, enr_4year}
  sample    ∈ {b, l, a, s, ls, as, las, s}    (s = sibling sample, sib_lag only)
  ctrl      ∈ {b, l, a, s, ls, as, las, sib1} (sib1 only in sib_lag)
  fb_var    ∈ {l, s, a, las, sib2}            (sib2 only in sib_lag)

Collapsed VA panels (.dta):
  estimates/va_cfr_all_<version>/va_est_dta/
    [predicted_prior_score/]
       va_<outcome>_<sample>_sp_<ctrl>_ct.dta
       va_<outcome>_all.dta            (merge_va_est output)
       va_all.dta                      (fully merged across outcomes)

Aggregate tables:
  tables/va_cfr_all_<version>/{spec_test,fb_test,combined}/
       spec_<outcome>_all.dta, fb_<outcome>_all.dta
       spec_sib_lag.dta, fb_sib_lag.dta
       fb_spec_<outcome>.csv           (combined CSV — paper Tables 2/3 source)
```

### vam invocation summary (count + pattern compliance)

Verified ~30+ vam invocations across the 6 estimation files:

- All follow the foundation-documented standard pattern (no deviations)
- All followed by `rename tv ...` and `rename score_r ...` immediately (no reserved-name conflicts)
- Spec-test-tab files use `data(variance)` mode (extracts σ̂ from variance components without saving estimates)
- All other files use `data(merge tv score_r)` mode

### Spec-test / FB-test β tracing — paper Tables 2 and 3

Mapping of paper rows → ster file → producer:

| Paper row | Description | Ster file pattern | Producer |
|---|---|---|---|
| Row 1 | σ̂ (VA SD) | `va_<outcome>_<smp>_sp_<ctrl>_ct.dta` (collapsed dta) | SD computed in `va_*_spec_test_tab.do` L113, L143 |
| Row 2 | β specification test | `spec_test/spec_<outcome>_<smp>_sp_<ctrl>_ct.ster` | `va_score_all.do` L87, `va_out_all.do` L85 |
| Row 3 | β FB-test, leave-out 7th-grade ELA | `fb_test/fb_<outcome>_<smp>_sp_<ctrl>_ct_l_lv.ster` | `va_score_fb_all.do` L120 (`fb_var=l`) |
| Row 4 | β FB-test, older sibling enrollment | `..._s_lv.ster` | same files, `fb_var=s` |
| Row 5 | β FB-test, ACS neighborhood | `..._a_lv.ster` | same files, `fb_var=a` |
| Row 6 | β FB-test, **distance to nearest college** (per paper map) | NOT FOUND in chunk-3 fb_vars (`l, s, a, las` only — no `d`) | **OPEN: probably `do_files/explore/`** |

Final paper table assembled by `va_spec_fb_tab.do` from .ster files via `matrix b = e(b)` / `matrix v = e(V)` per row, then `eststo` per (sample × control) combination, `esttab` to CSV at `tables/va_cfr_all_<version>/combined/fb_spec_<outcome>.csv`.

**Anomaly**: paper map describes Row 6 as "distance to nearest 2yr/4yr college" but chunk-3 code's fb_vars are only {l, s, a, las}. Either paper map mis-described, or distance robustness lives in a different file. Defer to Chunk 4 (where reg_out_va_tab and other share/ files are).

### drift_limit usage — surprising findings

- **`drift_limit.doh` (4 lines, the active helper)**: sets `score_drift_limit` and `out_drift_limit` from year ranges in macros_va.doh.
- **With current data** (2015-2018 for both): both equal `max(3-1, 1) = 2`.
- **Score files use `score_drift_limit`; outcome files use `out_drift_limit`** — appropriate separation.
- **Exception (latent bug)**: `va_out_sib_lag.do` L56, L97, L119 uses `score_drift_limit` for OUTCOME VA. Currently inert because both globals = 2, but if the year ranges ever diverge, outcome sib_lag VA will use the wrong drift limit.
- **`out_drift_limit.doh` (2 lines, the OTHER helper) is DEAD CODE — never `include`d anywhere in the project.** Confirmed by grep across both repos.

### Loop structure

Most chunk-3 estimation files follow a 4-nested structure: `version × va_ctrl × sample × {subject|outcome}`. FB variants add `fb_var` for 5 levels. Spec-test-tab files invert subject-outermost vs va_ctrl-outermost (subject moves OUTSIDE va_ctrl) so each subject gets its own dta with clean `replace`/`append` macro handling.

`va_corr.do` is a degenerate 2-loop (just `version × va_outcome`).

`merge_va_est.do` uses dynamic command swapping (`use` first iteration → `merge 1:1 ... using` subsequent iterations) inside the loop — elegant idiom worth preserving.

### New bugs / anomalies (12 surfaced; parallel to prior chunks' findings)

1. **`va_out_all.do` L176 typo**: `dk_spec_p_..._cts.ster` (extra `s` on `cts` — should be `ct.ster`). Orphans the DK peer spec-test estimate.
2. **`va_out_sib_lag.do` L56, L97, L119**: uses `score_drift_limit` instead of `out_drift_limit`. Latent bug, currently inert.
3. **`va_out_fb_test_tab.do` L173-174**: missing `log close` and `translate` at end of file — asymmetric with score variant.
4. **`va_out_spec_test_tab.do` L163**: uses `sd_va` (no-peer) when assembling the peer + predicted-score row; should be `sd_va_peer`.
5. **`va_score_sib_lag.do` L99 / `va_out_sib_lag.do` L97**: hanging `///` continuation on `driftlimit(...)` line followed by blank line. Inert (Stata terminates command on blank line) but syntactically wrong.
6. **`va_score_fb_all.do` and `va_out_fb_all.do`**: re-estimate the no-FB baseline VA without saving — duplicates work already done by `va_score_all.do` / `va_out_all.do`. Optimization target during consolidation.
7. **`out_drift_limit.doh`**: never included anywhere — dead code in repo.
8. **`va_corr.do` L82**: `date2` referenced but never defined.
9. **`va_sib_lag_spec_fb_tab.do` L70**: uses `addlabel(p_value, ...)` while sibling spec-test-tabs use `pval` — naming inconsistency.
10. **`va_out_all.do` L120-122**: builds `touse_g11_<outcome>_<subject>` flag never consumed. Dead code.
11. **`va_out_fb_all.do` L191, L233, L285**: display strings reference undefined `subject` macro — log noise.
12. **`va_score_spec_test_tab.do` and `va_out_spec_test_tab.do`**: indentation inconsistencies in the predicted_prior_score branch (extra-indented blocks, possibly tacked on later).

### Open questions

**For user**:

1. Where do `nw / _m / _wt` get used? Likely in `do_files/share/`, `do_files/explore/`, or replication-package files (Chunk 4+).
2. The L176 typo (`_cts.ster`) in `va_out_all.do` — fix during consolidation, or preserve to match historical outputs?
3. `out_drift_limit.doh` is dead code — safe to delete in consolidated repo?
4. The duplicated baseline-VA estimation in `va_*_fb_all.do` files — refactor to read .ster from disk?
5. The `va_out_sib_lag.do` `score_drift_limit` bug — fix to `out_drift_limit` (currently inert)?
6. The `p_value` vs `pval` inconsistency in `va_sib_lag_spec_fb_tab.do` — standardize to `pval`?

**For downstream chunks**:

- Where is `predicted_prior_score/` (scrhat) estimation done? `do_files/explore/va_predicted_score.do` and friends — pulled into chunk-3 spec-test-tab files but produced elsewhere.
- Where is paper Table 4 (pass-through ρ) actually produced? Likely `do_files/share/reg_out_va_tab.do` (writes `persistence_single_subject.tex`). Need to verify clustering pattern + dependency on `va_<subject>_<smp>_sp_<ctrl>_ct.dta`.
- Where is the "distance to nearest college" FB test computed? Not in chunk-3 fb_var set.
- Where do CSVs from `va_spec_fb_tab.do` get converted to LaTeX for the paper?
- Confirm `touse_sib_lag` flag origin (referenced at `va_score_sib_lag.do` L48).

---

## Chunk 4: Pass-through and heterogeneity (COMPLETE)

Files audited: `prior_decile_original_sample.do`, `reg_out_va_all.do`, `reg_out_va_dk_all.do`, `reg_out_va_all_tab.do`, `reg_out_va_dk_all_tab.do`, `reg_out_va_all_fig.do`, `reg_out_va_dk_all_fig.do`, `va_corr_schl_char.do`, `va_corr_schl_char_fig.do`, `va_het.do`, `persist_het_student_char_fig.do` (11 files).

Chunk 4 agent: general-purpose; report received 2026-04-25. Full per-file entries available in saved tool result; key findings synthesized below. Per-file entries available on request.

### Naming convention catalog — `nw / _m / _wt` ALL RESOLVED

| Token | Meaning | Where defined / used |
|---|---|---|
| `_m` | matched second-stage controls (the second-stage regression replicates the controls used in VA estimation) | `reg_out_va_all.do` L152, L154, L166, L168 (and propagated to all `*_tab.do`, `*_fig.do`); `reg_out_va_dk_all.do` L119, L128 |
| `_wt` | enrollment-weighted (`[w = enr_total]`) | `va_het.do` L81: `local w_str "wt"` when `w==1` |
| `_nw` | non-weighted | `va_het.do` L78: `local w_str "nw"` when `w==0` |

`_wt`/`_nw` appear ONLY in `va_het.do` outputs (the variance-decomposition and the school-char correlation tables — paper Tables 5 and 7). They do NOT appear in pass-through outputs because pass-through regressions are individual-level, not weighted.

`_m` appears only in pass-through outputs. Not in `va_het.do` outputs because `va_het.do` regressions are descriptive, no second-stage-matches-VA-controls concept.

**Naming convention catalog now complete** through the canonical pipeline.

### Paper-output mapping (Tables 4-5, 7; Figs 5-6, C.1-C.2)

| Paper artifact | Producer file | Lines |
|---|---|---|
| Table 4 (`tab:va-persistence`, `persistence_single_subject.tex`) | regression: `reg_out_va_all.do` L137-143 + matched L147-152; table CSV: `reg_out_va_all_tab.do` L219 | 219 |
| Table 5 (`tab:hetero`, `corr_char_wt_v1.tex`) | `va_het.do` L219 (with `frag` for paper version) | 219 |
| Table 7 (`tab:va-var-across-district`, `var_across_district_*.tex`) | `va_het.do` L138 | 138 |
| Fig 5 (heterogeneity by prior decile, ELA) | regression: `reg_out_va_all.do` L338, L349, L360 (both-subjects × prior-decile); 4-panel combine: `reg_out_va_all_fig.do` L536 (subject=ela) | 536 |
| Fig 6 (heterogeneity by prior decile, math) | same as Fig 5 with subject=math | 536 |
| OA Fig C.1-C.2 (pass-through het by student chars) | regression: `reg_out_va_all.do` L297, L308, L318; per-panel gphs: `reg_out_va_all_fig.do` L305, L321, L357, L374; 4-panel combine: `persist_het_student_char_fig.do` L52 | 52 |
| OA DK pass-through tables | `reg_out_va_dk_all_tab.do` L192, L254 | 192/254 |
| OA DK heterogeneity figures | `reg_out_va_dk_all_fig.do` L212 | 212 |

**CSV→TeX rendering step for Table 4** (`reg_<outcome>_va.csv` → `persistence_single_subject.tex`) NOT in chunk 4. Likely lives under `do_files/share/` (future chunk).

### SE clustering audit

| File | Cluster level | Paper-consistent? |
|---|---|---|
| `reg_out_va_all.do` | `cluster(school_id)` (L139, L149, L163, L191, L202, L215, L244, L255, L265, L294, L305, L315, L335, L346, L357) | ✓ |
| `reg_out_va_dk_all.do` | `cluster(school_id)` (L106, L116, L125, L143, L153, L163) | ✓ |
| `va_corr_schl_char.do` | `cluster(school_id)` (L85, L95) | ✓ (but see LHS-peer-suffix bug below) |
| `va_het.do` (variance decomp) | NO `vce()` clause at L92 — defaults to iid OLS SEs | DEVIATION — but R² is the reported quantity, so OK in spirit |
| `va_het.do` (correlation regs) | **`cluster(cdscode)`** at L158 | DEVIATION — paper claims `school_id`. Need to verify `cdscode == school_id` 1:1 in this data |

No two-way clustering anywhere. No robust-only specifications without clustering.

### Pass-through ρ — canonical regression specification

```stata
reg <outcome> va_<subject>_<sample>_sp_<control>_ct[_p] i.year <SECOND-STAGE CONTROLS>, cluster(school_id)
```

- `<outcome>` ∈ `{enr, enr_2year, enr_4year}` (Table 4 displays only `enr_2year` and `enr_4year`)
- `<subject>` ∈ `{ela, math}` (both stacked in panels)
- `<sample>` ∈ `{b, las}` — outcome sample
- `<control>` ∈ `{b, las}` — VA-side control set
- `[_p]` — peer controls in VA estimation: with vs. without (the 2 "Peer" / "No Peer" columns per panel)
- **Second-stage controls (two variants per ster)**:
  - Without `_m` (base): `i.year + b_controls` (year FE + base demographics + cubic prior scores)
  - With `_m` (matched): `i.year + <control>_spec_controls` plus `peer_<control>_controls` if peer — full set of controls used in VA estimation. Paper text "each regression includes all controls used in VA estimation" refers to this matched variant.

The 8-column structure of paper Table 4 corresponds to (outcome × {b sample b control × {peer, no-peer} × {base, matched 2nd-stage}}) projected to 4 columns per outcome, repeated for ELA and math panels.

### Heterogeneity ρ — canonical specifications

**Prior-decile heterogeneity (Figs 5-6)** — both-subjects regression with VA × prior-decile interaction:

```stata
reg <outcome> c.va_ela_<sample>_sp_<control>_ct[_p]#i.prior_<prior_subject>_z_score_xtile
              c.va_math_<sample>_sp_<control>_ct[_p]#i.prior_<prior_subject>_z_score_xtile
              i.year <controls>, cluster(school_id)
```

`reg_out_va_all.do` L331-335, L342-346, L352-357. The `c.#i.` syntax produces 10 decile-specific slope coefficients per VA subject.

**Student-char heterogeneity (Figs C.1-C.2)** — single-subject VA × student-char interaction:

```stata
reg <outcome> c.va_<subject>_<sample>_sp_<control>_ct[_p]#i.<het_char>
              i.year <controls>, cluster(school_id)
```

`reg_out_va_all.do` L291-294, with `<het_char>` ∈ {race, male, econ_disadvantage, charter, inc_median_hh_xtile (las only)}.

### 15 anomalies / bugs surfaced

1. **`reg_out_va_all.do:235` `local run_prior_score = 0` gates single-subject prior-decile heterogeneity OFF**, but `reg_out_va_all_fig.do:159` unconditionally tries to `est use` those ster files. **Fragile** — fails on fresh run unless ster files already on disk OR figure script made conditional. Investigate whether the both-subjects variant (which IS produced unconditionally at L331-360) is what the paper actually uses.
2. **`va_corr_schl_char.do` L84, L94: LHS-peer-suffix bug.** Regression LHS lacks `<peer>` but output filename embeds `_p` from sample-coupled local. Result: when sample==las, output is named `…_ct_p.ster` but the regression actually used the no-peer VA. Fig companion does NOT have this bug.
3. **`va_het.do:158 cluster(cdscode)`** vs paper-claimed `school_id`. May be equivalent if `cdscode == school_id` 1:1 in data; need verification.
4. **`va_het.do:92 areg` has no `vce()` clause** — defaults to iid SEs. R²-only output mitigates impact.
5. **`va_het.do:102` `if "\`district_type'" == "gr5"`** — `gr5` not in `district_type` loop (`gr2 top25`); dead code.
6. **`reg_out_va_all_fig.do:568`** filename typo: `x_prior_x_prior_<prior_subject>` (duplicated token).
7. **`reg_out_va_all_tab.do:463`** copy-paste in di message: references `reg_out_va_all_fig.do` instead of `_tab.do`.
8. **`reg_out_va_all_tab.do:47` `las_sample_controls = "b a las"`** — subset of regression file's `"b a ls las bd ad lsd lasd"`. Tables format only a subset of regressions actually produced; the rest exist only for figures.
9. **`reg_out_va_all_fig.do` and `reg_out_va_dk_all_fig.do` line-172 comment** says "90% CI" but `parmest`'s `min95`/`max95` are **95% CI bounds**.
10. **`reg_out_va_dk_all_fig.do` L148-150** retains on-figure titles/subtitles — inconsistent with `reg_out_va_all_fig.do` (which has them commented out at L183-185).
11. **`prior_decile_original_sample.do:106`**: `xtile inc_mean_hh_xtile = inc_median_hh, n(10)` — variable named "mean" computed from "median" input. Cosmetic (no downstream consumer).
12. **`va_corr_schl_char.do` is functionally orphaned**: produces ster files at `va_het/va_<va_outcome>_het_<het_char>_<sample>_sp_<va_ctrl>_ct[_p].ster` that no chunk-4 file consumes. The paper-Table-5 producer is `va_het.do`. Worth confirming nothing reads these in later chunks.
13. **Distance-FB-test mystery** (chunk 3 anomaly) NOT resolved — none of chunk 4 produces a "distance to nearest college" FB test. Defer to Chunk 9 (`do_files/explore/`).
14. **Variable naming collision: nested `forvalues i = 1/2`** in 4 files (outer = peer, inner = match). Works because outer `i` is consumed before inner overwrites and outer is reset on next outer iteration, but fragile. Should be renamed (j, k) in consolidation.
15. **Header inconsistencies**: `va_corr_schl_char.do` and `va_corr_schl_char_fig.do` lack author line; `va_het.do` shows only the date. All look like Christina's based on style.

### Open questions

**For user (Christina)**:

1. Was `local run_prior_score = 0` at `reg_out_va_all.do:235` set deliberately or temporarily (skip recompute when ster already on disk)? Affects what the consolidated repo retains.
2. In `va_corr_schl_char.do`, was the LHS-peer-suffix bug intentional (always use no-peer VA) or accidental? If unintended, the output ster files have miscoded labels.
3. In `va_het.do:158`, is `cluster(cdscode)` intentional or a typo for `cluster(school_id)`? Affects SEs in Table 5's reported regressions.
4. Confirm: paper Table 5 (`corr_char_wt_v1.tex`) uses the **weighted** specification (`_wt`) — correct?
5. Is `va_corr_schl_char.do` superseded by `va_het.do`? If so, consolidation can drop it.

**For downstream chunks**:

- Chunk 7 (data prep): `sch_char_2018.dta`, `sch_char.dta`, `charter_status.dta` provenance.
- Chunk 9 (`explore/`): the distance-FB Row-6 producer, if any.
- A future chunk (likely `share/`): the CSV → `persistence_single_subject.tex` rendering step.

---

## Chunk 5: Sibling crosswalk + sibling VA regs (COMPLETE — N1 RESOLVED)

Files audited: 33 files across `caschls/do/share/siblingxwalk/` (3) and `caschls/do/share/siblingvaregs/` (30 including `.doh`).

**Per-file detail**: see companion doc `quality_reports/audits/2026-04-25_chunk5-sibling.md` (1168 lines, 33 per-file entries + full synthesis).

Synthesis below.

### N1 — siblingoutxwalk.do relocation: SAFE to move to `sibling_xwalk/`

Concrete dependency-trace evidence:

1. **Inputs of siblingoutxwalk.do**: only k-12 source data (`k12_test_scores_clean.dta`), Matt's helper `merge_k12_postsecondary.doh`, the `ufamilyxwalk.dta` produced by `uniquefamily.do` (which IS in `siblingxwalk/`), and shared macro includes (`vafilemacros.doh`, `macros_va.doh`). **NONE come from `siblingvaregs/` data outputs.**
2. **Outputs**: `$projdir/dta/common_core_va/k12_postsecondary_out_merge.dta` and `$projdir/dta/siblingxwalk/sibling_out_xwalk.dta`. **The canonical output is already in the `siblingxwalk/` folder** (data-side, not code-side).
3. **Consumers of `sibling_out_xwalk.dta`**: 7 files in `siblingvaregs/` (`createvasample`, `siblingvasamples`, `va_sibling`, `va_sibling_out`, `va_sibling_out_forecast_bias`, `create_va_sib_acs_restr_smp`, `create_va_sib_acs_out_restr_smp`). All access via `\`sibling_out_xwalk'` macro — relocation doesn't change resolved path.
4. **Nothing in `siblingvaregs/` calls `do siblingoutxwalk.do`** — only `master.do:103` does.

**Verdict: SAFE to relocate. Single edit needed: update `master.do:103` path** from `do/share/siblingvaregs/siblingoutxwalk.do` → `do/share/siblingxwalk/siblingoutxwalk.do` (or whatever the consolidated layout's path becomes). No circular reference. **Unblocks ADR-0004 (sibling-xwalk canonical location).**

### Sibling-matching specifics (paper Q1 from paper-map open questions)

- **Address join**: 5-component (`street_address_line_one street_address_line_two city state zip_code`). Note: `zip_code` included in `egen group` (`siblingmatch.do` L49) but NOT in the duplicates report (L41) — slight inconsistency.
- **Surname**: `last_name` as-is (no normalization, no fuzzy matching).
- **"Same year"**: within-year matches require enrolled in SAME calendar year (egen group keys on year + identifiers). Cross-year crosswalk drops year (`siblingmatch.do` L86).
- **Transitive closure**: implemented via Haghish's **`group_twoway`** package (`uniquefamily.do` L32). Args = (within-year-family-ID, student-ID). Computes connected components over both, so a student in family A in year 1 and family B in year 2 (different addresses or surnames) is linked transitively via SSID.
- **Family moves**: handled by transitive closure across years.
- **Surname changes (remarriage)**: NOT explicitly handled. If both surname AND address change, link breaks. If only surname changes, transitive closure via SSID still links them.
- **Data-entry typos**: NOT explicitly handled. Match is exact-string.
- **Quality filters**:
  - Drop addresses with ≤1 character (`siblingmatch.do` L22)
  - Drop missing SSID (L23)
  - Drop singletons (no siblings) (L53)
  - **10-child cap** (`uniquefamily.do` L53: `drop if numsiblings >= 9`) — promote to ADR.

### 4-spec convention for sibling-restricted sample

Confirmed from `va_sib_acs.do` doc-comment + code structure:

| Spec | `<ctrl>` token | Controls beyond CFR baseline |
|---|---|---|
| 1 | `og` | None (CFR baseline only) |
| 2 | `acs` | + `census_controls` |
| 3 | `sib` | + `sibling_controls` |
| 4 | `both` | + `sibling_controls` + `census_controls` |

`_str` macros (`og_str`, `acs_str`, `sib_str`, `both_str`) for human-readable labels live in `macros_va.doh` (chunk 2 confirmed).

The 4-spec convention applies to:

- `va_sib_acs.do` (test-score VA, 4 specs × 2 subjects = 8 vam invocations)
- `va_sib_acs_out.do` (outcome VA, 4 specs × 3 outcomes = 12 vam)
- `va_sib_acs_out_dk.do` (DK outcome VA, 4 specs × 3 outcomes = 12 vam)

### Positional arg `0` semantics for `va_sibling*.do`

```stata
args setlimit
if `setlimit' == 0 {
    local drift_limit = max(`test_score_max_year' - `test_score_min_year' - 1, 1)
}
else {
    local drift_limit = `setlimit'
}
```

- `0` = sentinel, use default formula `max(year_range - 1, 1)`
- Any non-zero integer = override drift_limit to that value

`va_sibling_out.do` change-log notes: "re-ran with drift limit = 2. Still produces an error if drift limit = 3" — for the sibling outcome sample, drift_limit=3 hits a numerical issue (possibly singular variance matrix); 2 is the working override.

**Inconsistency**: the older sibling-only files (`va_sibling`, `va_sibling_out`) accept the positional arg; the newer 4-spec files (`va_sib_acs*`) hardcode the formula. If 4-spec drift fails in the future, manual code edit required.

### Paper-output mapping (sibling-VA artifacts)

| Sibling-VA artifact | Paper destination |
|---|---|
| `va_sibling.do` | Paper Table 2 sibling-FB row |
| `va_sibling_out.do` | Paper Table 3 sibling-FB row |
| `va_sibling_out_forecast_bias.do` | Paper Table 3 sibling+census combined row |
| `va_sib_acs.do` / `va_sib_acs_out.do` / `va_sib_acs_out_dk.do` | OA: 4-spec test-score / outcome / DK VA |
| `va_sib_acs_spec_test_tab.do`, `va_sib_acs_fb_test_tab.do`, `va_sib_acs_vam_tab.do` | OA tables for 4-spec spec/FB/VAM |
| `reg_out_va_sib_acs.do` | Paper Table 4 (pass-through, sibling-restricted-sample 4-spec rows) |
| `reg_out_va_sib_acs_dk.do` | Paper Table 5 (DK pass-through, sibling-restricted rows) |
| `reg_out_va_sib_acs_tab.do`, `reg_out_va_sib_acs_fig.do` | Tables for Table 4 sibling rows + OA Figs C.1-C.2 |

**Distance-FB Row 6 mystery (chunk 3 open question) NOT in chunk 5 territory either.** Confirmed not in sibling-VA. Must live in `va_distance_*` files (Chunk 6/7 territory) or possibly `do_files/explore/` (Chunk 9).

### New naming tokens found in chunk 5

- **`og` / `acs` / `sib` / `both`** — 4-spec control tokens (major addition)
- `_dk` suffix for deep-knowledge variants
- `_nosibctrl` / `_nocontrol` — older sibling-only naming
- `_sibling` suffix — older naming on `.ster` files (vs `_<ctrl>` token system)
- `_census_nosib_noacs` / `_census_noacs` / `_sib_census` — older 3-way ad-hoc tokens (only in `va_sibling_out_forecast_bias.do`)
- `_x_prior_<subject>` — heterogeneity-by-prior-decile pattern
- `_sed{0,1}` — heterogeneity-by-SED-status pattern
- `het_reg_` prefix
- `old1_sib_<outcome>` / `old2_sib_<outcome>` — lag1/lag2 older-sibling outcome variables

**Naming-system fragmentation in sibling-VA**: the older sibling-only files use `_sibling`/`_nosibctrl`/`_nocontrol`; the 4-spec files use `og/acs/sib/both`; `va_sibling_out_forecast_bias.do` uses ad-hoc tokens. Major consolidation hazard. Recommend standardizing on `og/acs/sib/both`.

### ssc/community packages — full list across chunks 1-5

Total ~14 packages. The consolidated `settings.do` install-block needs all:

| Package | Source | First seen |
|---|---|---|
| `vam` | SSC (Stepner v2.0.1) | chunk 1 |
| `reghdfe` | SSC | chunk 1 |
| `ivreghdfe` | SSC | chunk 1 |
| `estout` / `esttab` | SSC | chunk 3 |
| `coefplot` | SSC | chunk 4 |
| `palettes` | SSC | settings.do |
| `cleanplots` | SSC | settings.do |
| `egenmore` | SSC | settings.do |
| `regsave` | SSC | settings.do |
| `cdfplot` | SSC | settings.do |
| `binscatter` / `binscatter2` | SSC | chunks 3-5 |
| `parmest` | SSC | chunk 5 |
| `rangestat` | SSC | chunk 5 |
| `texsave` | SSC | settings.do |
| **`group_twoway`** | **Haghish (NOT on SSC)** | chunk 5 |

`group_twoway` is the one non-SSC dependency — installs via `net install` from Haghish's site. Settings.do install-block needs a separate branch for it.

### 7 new bugs/anomalies in chunk 5 (running total ≈23 across all chunks)

1. **`siblingpairxwalk.do` L24**: `rename middle_intl sibling_middle_intl` — but `uniquelinkedfamilyclean.dta` doesn't include `middle_intl` per `uniquefamily.do` L54 keep list. Will silently fail or error.
2. **`siblingmatch.do` L41 vs L49**: duplicates report uses 6 keys; egen group uses 7 (with zip_code). Slight inconsistency.
3. **`uniquefamily.do` L56**: `numsiblings_exclude_sef` typo for "self".
4. **`va_sibling_out.do` L328-330 vs `va_sibling.do` L287-291**: outcome-VA collapse has NO `if sibling_full_sample == 1 & sibling_out_sample == 1` filter; test-score-VA collapse does. **Inconsistency — possible bug**: outcome-VA collapsed dataset spans more obs than sibling-only.
5. **`reg_out_va_sib_acs.do` L151, L174, L211, L224**: heterogeneity regs cluster on `cdscode`, not `school_id` (which is used in main pass-through regs L94, L112). Same flag as chunk 4's `va_het.do:158`.
6. **`vafilemacros.doh` L21**: `local siblingxwalk` defined but appears unused — dead local.
7. **Naming-system fragmentation across sibling-VA files** — older `_sibling/_nosibctrl/_nocontrol` vs 4-spec `og/acs/sib/both` vs ad-hoc tokens.
8. **`va_sib_acs_*` files lack `args setlimit`** — if 4-spec drift fails, manual edit required.
9. **Dual-output pattern**: many post-est diagnostic files write PDFs to BOTH `$projdir/out/graph/...` AND `$vaprojdir/figures/...`. Path-rerouting must update both during consolidation.

### Open questions for user

| # | Question | Affects |
|---|---|---|
| Q5.1 | Confirm 10-child cap in `uniquefamily.do:53` is documented in paper / appendix | Reproducibility documentation |
| Q5.2 | DK controls in `va_sib_acs_out_dk.do` (fixed on `_og` test-score VA across all 4 specs) — intentional or bug? | DK regression results |
| Q5.3 | Is `va_sibling_out_forecast_bias.do` redundant given `va_sib_acs_out.do`? Both produce outcome-VA-with-sibling-and-census-controls FB tests with different sample restrictions and naming. Which feeds paper Table 3? | Table 3 producer attribution |
| Q5.4 | Cluster-level inconsistency in heterogeneity regs (`cdscode` vs `school_id`) — intentional? | SE in OA tables |
| Q5.5 | `va_sibling_out.do` collapse missing sibling-sample filter — bug or intentional? | Sibling outcome-VA dataset scope |
| Q5.6 | Migrate older `_sibling/_nosibctrl/_nocontrol` naming to `og/acs/sib/both` at consolidation, or keep for backward compatibility? | Naming convention for consolidated repo |

### Resolved questions from prior chunks

- N1: SAFE to relocate siblingoutxwalk.do (this chunk).
- v1/v2 prior-score table: chunk 2 (v1 verified, v2 corrected).
- naming convention catalog: chunks 2-5 (all major tokens found).
- vam compatibility: chunks 1-3 (no customization needed).

---

## Chunk 6: Survey VA + CalSCHLS factor analysis (COMPLETE)

Files audited: 17 files across `caschls/do/share/factoranalysis/` (15), `caschls/do/share/svyvaregs/` (1: `allvaregs.do`), `caschls/do/build/buildanalysisdata/poolingdata/clean_va.do`. Plus `caschls/do/check/allsvymissing.do` (relocation discovery — listed in chunk 6 brief but actually lives in `check/`).

**Per-file detail**: see companion doc `quality_reports/audits/2026-04-25_chunk6-survey-va.md` (872 lines).

### Paper Table 8 producer chain (`tab:survey`, `imputed_index_combined_wdemo.tex`)

```
clean_va.do
  ├─→ va_pooled_all.dta (school × VA-spec, 2015-2018 mean)
  └─→ {sec,parent,staff}analysisready.dta (in-place overwrite to add VA cols)
                                ↓
allsvymerge.do
  └─→ allsvyqoimeans.dta (3 surveys' QOI means + VA, school-level wide)
                                ↓
imputation.do
  └─→ imputedallsvyqoimeans.dta (Stage 1 mean-impute + Stage 2 within-cat regression-impute)
                                ↓
[compcase branch]                       [imputed branch]
compcasecategoryindex.do                imputedcategoryindex.do
  └─→ compcasecategoryindex.dta           └─→ imputedcategoryindex.dta
                                          (sums of items, z-standardized;
                                           VA z-standardized in-place)
                                ↓
mattschlchar.do (school chars from $mattxwalks)         testscore.do (gr 6 math, gr 8 ELA)
  └─→ schlcharpooledmeans.dta                             └─→ testscorecontrols.dta
                                ↓
[Panel A: bivar w/ controls]            [Panel B: horse race w/ controls]
indexregwithdemo.do                      indexhorseracewithdemo.do
  └─→ {compcase,imputed}_index_bivar_wdemo  └─→ {compcase,imputed}_index_horse_wdemo
      .dta + .xls                              .dta + .csv (Excel-format)
                                ↓
[downstream chunk 7+ TeX writer (NOT IN CHUNK 6)]
  └─→ tables/share/survey/pub/imputed_index_combined_wdemo.tex   ← paper Table 8
```

The chain stops at `_bivar_wdemo` and `_horse_wdemo` `.dta`/`.xls`/`.csv` artifacts. **The TeX-combination step is downstream** — likely a `tabletotex`-family file in chunks 7-10.

### Index construction logic (paper §6 detail)

- **3 indices** (post-winnowing): climate (9 items), teacher/staff quality (15 items), counseling support (4 items). Student-motivation index dropped (commented out at `imputedcategoryindex.do:31`).
- **Aggregation**: code uses `gen <cat>index = 0; replace <cat>index = <cat>index + <var>` — i.e. **a SUM, not an average** as the paper claims. Because z-standardization (lines 64-66) follows immediately, the coefficient is invariant to sum-vs-mean choice. **Discrepancy worth flagging**: fix paper text or fix code.
- **Standardization**: indices and VA both z-standardized to mean=0, SD=1 before regressions. So coefficients are SD-on-SD.
- **Imputation pipeline**: Stage 1 mean-impute (lines 70-74), then Stage 2 within-category regression-impute with imputed-indicator dummies as controls (lines 80-128). Non-standard pipeline.
- **Imputation-list mismatch**: `imputation.do` uses 20/17/4/4-item *wider* category lists for predictor pools; `imputedcategoryindex.do` uses *narrower* 9/15/4-item lists for index construction. So items removed from the index pool (e.g., `parentqoi9`) are still used as **predictors** during imputation.

### Cronbach's α computation

- **`indexalpha.do`** computes the α's reported in the paper footnote. Loads `compcasecategoryindex.dta` (complete-case items, NOT imputed), runs `alpha <items>, std item` for each of the three index-item lists. **Output goes only to the log file** — α values are hand-copied into the paper.
- `alpha.do` separately computes α's at survey-level and category-level using **wider** item sets — these are NOT the paper-reported α's.

### Survey-VA merge geometry — year-mismatch resolution

- **All merges are at `cdscode` only (NO year)**.
- VA: collapsed to mean over 2015-2018 → 1 row per school in `va_pooled_all.dta`.
- Surveys: pooled across 2017-2019 (in upstream pooling files, chunk-7+ scope) → 1 row per school.
- `clean_va.do` line 74: `merge 1:1 cdscode using va_pooled_all, keep(1 3) nogen` — survey-side master rows kept regardless of VA presence; VA-only schools dropped. Schools with missing VA → missing in regression (listwise deletion at run time).
- **The asymmetric year-window (VA 2015-2018 vs surveys 2017-2019) is intentional but NOT robustness-tested** in chunk 6. Worth a sensitivity note.

### VA specifications used in `allvaregs.do`

```
outcomes:  ela, math, enr, enr_2year, enr_4year,
           dk_enr, dk_enr_2year, dk_enr_4year                          (8)
samples:   b (base), las (leave-acs-sibling)                           (2)
controls:  b → b ; las → las                                           (1 each)
peer:      "" if b ; "_p" if las                                       (built into spec)
```

Spec strings: `va_<outcome>_<sample>_sp_<control>_ct{,_p}`. E.g., `va_ela_b_sp_b_ct` (no peer), `va_math_las_sp_las_ct_p` (with peer).

`_m` (matched) does NOT appear in survey-VA spec naming — only the full outcome-name is in the spec.

### New naming tokens / packages from chunk 6

**New tokens**:

- `horse` / `horserace` — multi-regressor index spec (all 3 indices on RHS together)
- `wdemo` — with demographic controls (test-score + Matt-school-chars)
- `bivar` — bivariate (one index at a time on RHS); pairs with `horse` for the two panel kinds
- `imputed` / `compcase` — imputation-vs-complete-case branch (folder + filename suffix)
- `qoi` = "question of interest" pattern: `<survey>qoi<NN>mean_pooled` is the per-question school-level pooled mean
- `dk_` prefix on enrollment outcomes confirmed (Dukes-style cohort definition)

**New ssc packages**:

- **`mvpatterns`** (in `do/check/allsvymissing.do:38`)

Combined ssc list now ~15 packages.

### Distance-FB Row 6 — still NOT FOUND in chunk 6

Chunk 6 is purely survey-VA / index analysis; no FB testing infrastructure here. Distance-FB Row 6 must be in chunks 7-10 (data prep / samples / share / explore / upstream).

### 12 new bugs/anomalies in chunk 6 (running total ≈35)

Most material:

1. **`allvaregs.do:197`**: weighted-merge block saves to `_nw` filename instead of `_wt`. The `.dta` for unweighted combined regs is silently overwritten by weighted regs. The `.xls` is correctly suffixed `_wt`.
2. **`pcascore.do:36-39`**: staff PC2 histogram code re-uses `pc1` instead of `pc2`. `staffpc2score.png` is a duplicate of `staffpc1score.png`.
3. **Sum-vs-mean discrepancy**: paper says "averages"; code computes sums. Fix paper or fix code (z-standardization makes coefficients identical, but the on-disk variable is a sum).
4. **In-place destructive saves**: `clean_va.do:76` (`save, replace` on analysisready files) and category-index files (z-standardize VA in place). Reproducibility relies on always rebuilding from upstream raw.
5. **`mattschlchar.do:17`**: hard-coded path `/home/research/ca_ed_lab/msnaven/common_core_va/data/sch_char` — cross-user dependency, gated by `local clean = 0` toggle.
6. **`factor.do:11, 79`**: log file written to `do/share/factoranalysis/factor.{smcl,log}` instead of `log/share/factoranalysis/`.
7. **`indexalpha.do`**: no `translate` smcl→log; leaves smcl only.
8. **Header attribution drift**: `indexhorseracewithdemo.do:6` says "Christina Sun" while sibling files say "Che Sun". Same person.
9. **Empty `motivation` index**: `imputedcategoryindex.do:31` has `motivationvars` commented out, but `alpha.do` and `imputation.do` still process motivation items, leaving orphan downstream.
10. **Silent merge attrition**: every `merge ... keep(1 3) nogen` in chunk 6 silently drops unmatched-using rows without an `assert _merge==3` check. In `mattschlchar.do:94` the OPPOSITE `keep if _merge==3` drops both unmatched cases — undocumented sample restriction.

### 6 open questions for user (Chunk 6)

| # | Question | Affects |
|---|---|---|
| Q6.1 | `allvaregs.do:197` weighted save → `_nw` filename — known typo or intentional? | Output integrity |
| Q6.2 | Was `imputedallsvyqoimeans.dta` rebuilt after the 12/19/2024 `supportimputedummies` spelling fix in `imputation.do`? | Imputation correctness for downstream regressions |
| Q6.3 | "Averages" (paper) vs "sums" (code) — fix paper or fix code? | Paper text or code |
| Q6.4 | Asymmetric VA 2015-18 vs surveys 2017-19 — get robustness-tested? | Reviewer pushback |
| Q6.5 | `mattschlchar.do:17` cross-user dependency — vendor into consolidated repo? | Reproducibility |
| Q6.6 | `clean_va.do:39` says "2015-2018" but no `keep if inrange(year, 2015, 2018)` — year-restriction enforced upstream? | Sample window verification |

---

## Chunk 7: Data prep (COMPLETE — Distance-FB Row 6 RESOLVED)

Files audited: ~30 files across `cde_va_project_fork/do_files/{acs,k12_postsec_distance,schl_chars}/` and `caschls/do/build/{prepare,buildanalysisdata/qoiclean}/`. Per-file detail in companion doc `quality_reports/audits/2026-04-25_chunk7-data-prep.md`.

### Distance-FB Row 6 mystery RESOLVED

The "distance" forecast-bias row in paper Tables 2/3 row 6 is wired via the `d` token in `cde_va_project_fork/do_files/sbac/macros_va_all_samples_controls.doh` (added 04/30/2023):

- **Producer**: `k12_postsec_distances.do` L121-124 creates `mindist_uc/csu/pub4yr/any_nonprof_4yr/ccc`. Saves to `$distance_dtadir/clean/k12_postsec_mindistance.dta`.
- **Patcher**: `reconcile_cdscodes.do` reconciles 11 cdscode mismatches in-place (lossy overwrite).
- **`d_controls` macro**: only `mindist_any_nonprof_4yr` and `mindist_ccc` (2 of 5 mindist vars) actually enter regressions.
- **FB-test wiring**: `d` is added to *every* `*_ctrl_leave_out_vars` list in `macros_va_all_samples_controls.doh`. Plus `local d_fb_<x>_samples` blocks define samples.
- **Consumer**: chunk 3's `va_score_fb_all.do` and `va_out_fb_all.do` loops `foreach fb_var of local <va_ctrl>_ctrl_leave_out_vars`. When `fb_var=="d"`, `\`fb_var'_controls` resolves to `mindist_any_nonprof_4yr mindist_ccc`.
- **Output filename**: `fb_<subject>_<sample>_sp_<va_ctrl>_ct_d_lv.ster`. The `_ct_d_lv` token identifies the distance row.

**Chunk 3's "fb_var ∈ {l, s, a, las}" finding was incomplete** because `d` lives in `macros_va_all_samples_controls.doh` (briefly noted in chunk 2 but its full FB integration was missed). Now corrected: full fb_var set = {l, s, a, las, d}.

### ACS data flow

```
clean_acs_census_tract.do  (2010-2013 only)
   reads: ACSST5Y<year>.{S0601,S1501,S1702,S1901}_data_with_overlays.csv
   appends → acs_ca_census_tract_clean.dta
        ↓
merge_va_smp_acs.doh (chunk 2)
   joins ACS at student grade-6 census tract on geoid2 + year
        ↓
sample-construction → a/la/as/las/asd/lasd controls
```

**Potential coverage issue**: only 2010-2013 ACS years are processed. Grade-6 cohorts in the analysis sample may extend beyond 2013; need to verify whether 2014+ ACS is processed elsewhere or whether 2013 ACS is recycled.

### School-characteristics dependency tree

11 input files (cds_nces_xwalk, clean_locale, clean_charter, clean_ecn_disadv, clean_elsch, clean_enr, clean_frpm, clean_staffcred, clean_staffdemo, clean_staffschoolfte, plus sch_char itself) → `clean_sch_char.do` (549-line assembler) → `data/sch_char.dta` (master school × year panel) → consumed by `va_het.do` (chunk 4) for paper Tables 5/7.

**Confirmed**: `data/sch_char.dta` IS the same `sch_char.dta` referenced in chunk 4's `va_het.do`. Top-level path location (not under `data/public_access/clean/cde/`) is a consolidation flag.

### CalSCHLS QOI year-batching logic

10 QOI files year-batched by question-numbering compatibility:

- **2017 carve-out** (parallel to v1 ELA 2017 carve-out): sec 1617 + parent 1617 each have unique do files.
- **Parent 1415 lacks qoi 64** (different response options); produces only parent QOI dataset without `pctwell64`/etc.
- **Staff 1718/1819 lack `pctnotapp`** (the "not applicable" option dropped); downstream pooling must handle missing columns.

### New naming tokens (additions to chunks 1-6 catalog)

`d` (full FB integration), `mindist_<X>`, `qoi<N>`, `stragree<N>`/`agree<N>`/`disagree<N>`/`strdisagree<N>`/`dontknow<N>`/`missing<N>`, `pctagree<N>`/`pctdisagree<N>`/`pctdontknow<N>`, `pctwell<N>`/`pctokay<N>`/`pctnotwell<N>` (qoi 64 only), `pctyes<N>`/`pctno<N>`/`pctnotapp<N>` (staff yes/no), `pctsmallprob<N>`/`pctbigprob<N>` (staff qoi 98), `nettotalresp<N>`, `gr<i>{enr,femaleenr,...}`, `gr11enr_mean` (= `_wt` weight token), school-char tokens (`fte_teach_pc`/`fte_admin_pc`/`fte_pupil_pc`/`male_prop`/`eth_minority_prop`/`new_teacher_prop`/`credential_full_prop`/`locale_coarse`/`locale_fine`/`charter`/`public`).

### 17 new bugs/anomalies in chunk 7 (running total ≈52)

Most material:

1. **`clean_acs_census_tract.do`**: only processes 2010-2013 — potential coverage gap for later cohorts.
2. **`k12_postsec_distances.do:50,54,58`**: hardcoded asserts (CSU=23, UC=9, 4yr-non-profit=115) — will break with future IPEDS releases.
3. **`k12_postsec_distances.do:98`**: hardcoded API key in commented-out opencagegeo line.
4. **`reconcile_cdscodes.do:81`**: in-place `save, replace` overwrites unpatched mindist file (lossy).
5. **`clean_charter.do:26`**: Apple Silicon detection broken (`c(machine_type)=="Macintosh (Intel 64-bit)"`).
6. **`enrollmentclean.do:21` female-encoding bug**: missing-gender → `female==0` (treated as male), pollutes male-by-grade totals. **Real bug.**
7. **`renamedata.do:77-84`**: comment claims to "discard" 5 parent-1415 rows; code does NOT actually drop them.
8. `clean_sch_char.do`: top-level `data/sch_char.dta` location inconsistent with sibling outputs.
9. `clean_sch_char.do`: charter + locale merged `m:1` (time-invariant assumption).
10. `clean_staffdemo.do`: 90% code duplication between 2014-only and 2015+ blocks.
11. `clean_ecn_disadv.do`: writes restricted-data-derivative to `public_access/clean/` (misleading folder).
12. `clean_frpm.do`: hardcoded year-format branch (xls vs xlsx); fragile to layout changes.
13. `clean_staffcred.do`: authorization code list hardcoded — will be incomplete for new authorizations.
14. QOI files: `set varabbrev off` inconsistently set with `, perm`.
15. Schema divergences across QOI year-batches (parent 1415 missing qoi 64; staff 1718/1819 missing `pctnotapp`).
16. QOI files: extensive dead code in commented-out fallback blocks.
17. `hd2021.do` (4322 lines): auto-generated NCES dictionary; treat as opaque blob.

### Open questions for user (chunk 7)

| # | Question | Affects |
|---|---|---|
| Q7.1 | Are 2014+ ACS years covered somewhere outside `clean_acs_census_tract.do`? Grade-6 cohorts may need post-2013 ACS coverage. | Sample completeness |
| Q7.2 | Is `enrollmentclean.do` female-encoding bug (missing-gender → male inflation) known? Does analysis sample restrict to non-missing gender? | Possible silent bias in enrollment counts |
| Q7.3 | Should `reconcile_cdscodes.do` write to a new file rather than overwrite unpatched? | Reproducibility provenance |
| Q7.4 | Is `data/sch_char.dta` (top-level) the intended final location, or should it move to `data/public_access/clean/cde/`? | Folder consistency |

---

## Chunk 8: Samples (COMPLETE — sample-restriction map FINALIZED)

Files audited: 25 files across `cde_va_project_fork/do_files/sbac/` (3) and `caschls/do/build/{buildanalysisdata/poolingdata,buildanalysisdata/responserate,sample}/` + `share/demographics/` (22). Per-file detail: `quality_reports/audits/2026-04-25_chunk8-samples.md`.

### CRITICAL FINDING — `_archive/matt_original/sum_stats.do` is still load-bearing

**The paper's `counts_k12.tex` (Online Appendix Table A.1) is produced by `_archive/matt_original/sum_stats.do` + `sum_stats_tab.do`** — files we archived in commit `85a97e7` (`archive: move 21 Matt-original VA do-files to _archive/matt_original/`).

The user's earlier direction to archive Matt-originals was based on the assumption they were superseded by `va_score_all.do` / `va_out_all.do`. But `sum_stats.do` produces a different artifact (the Table A.1 sample-counts cascade), not a VA estimate.

**The do-file references in `do_all.do` for `sum_stats.do` were already commented-out before our archival** — meaning Table A.1 hasn't been re-derived from this code in some time. So either `counts_k12.tex` is stale, or it's reproduced manually outside the master pipelines.

**Action item flagged for user (Q8.1)**: confirm whether `counts_k12.tex` is currently stale, and decide whether `sum_stats.do` + `sum_stats_tab.do` should move out of `_archive/matt_original/` back into the active pipeline (or to a new `do/share/` location for paper-output formatting).

### Final sample-restriction map (paper Table A.1 ↔ code)

The 9 rows of Table A.1 (ELA branch — math symmetric) are produced by `_archive/matt_original/sum_stats.do` L215-460:

| Row | Restriction (cumulative) | Source line |
|---|---|---|
| 1 | All grade-11 students | L218-228 |
| 2 | School-level (grade-span >= 95%) | L230-243 |
| 3 | First scores | L257-269 |
| 4 | Conventional schools | L286-302 |
| 5 | **Cohort size > 10** (CBEDS school-level cut) | L305-322 |
| 6 | Non-missing test score | L326-344 |
| 7 | Non-missing demographic controls | L348-368 |
| 8 | Non-missing prior test scores | L372-394 |
| 9 | **School VA sample size ≥ 7** (per-cell cut) | L425-452 |

### "≥7 vs ≤10" question DEFINITIVELY RESOLVED

**Both cuts exist and are different**:

- **Row 5** (`touse_va.do:109`): `cohort_size > 10` at school × test × year level (drops schools with `cohort_size ≤ 10` per CBEDS).
- **Row 9** (`touse_va.do:155, 180`): `n_g11_<subject> >= 7` at the school × year × subject × analysis-cell level (after all controls non-missing).

Chunk 2's confusion was conflating them. **Internal consistency: confirmed**.

### `gr11enr_mean` weight chain confirmed

Generated upstream → merged via `mergegr11enr.do` → consumed as `[aweight=gr11enr_mean]` (the `_wt` token) in survey-on-VA second-stage regressions in `do_files/share/`.

### Survey pooling logic

Three pooling files (parent/sec/staff) follow common pattern: 5-year `append` → `wtmean` weighted by `nettotalresp<i>` → collapse to school level → output `<survey>pooledstats.dta` → response-rate merge → `<survey>analysisready.dta`. Schema divergences (parent 1415 missing qoi 64; staff 1718/1819 missing `pctnotapp`) handled by wtmean ignoring missings.

### Response-rate semantics

- `pooledrr` and `pooledrr_gr9and11` are **covariate / weight candidates, NOT sample restrictions**. No `keep if pooledrr > X` filter.
- **Two parallel definitions of `pooledrr`** exist (`parentresponserate.do` vs `pooledparentdiagnostics.do`): same name, different semantics. Naming clash.
- `trimparentdemo.do` / `trimsecdemo.do` are misleadingly named — they're projection helpers (variable subset + rename), NOT statistical trimming.

### New naming tokens / packages

**Tokens**: `touse_g11_<subj|out>`, `n_g11_<...>`, `score_<flag>` / `out_<flag>` (sample fan-out), `va_samples_v1/` path, `<var>_pooled` family (mean/pct{agree|disagree|neither|dontknow|well|okay|notwell|true|nottrue|yes|no|smallprob|bigprob}<i>_pooled), `nettotalresp<i>`, sex/race-stratified `svy<demo>gr<i>` / `enr<demo>gr<j>` / `pct` / `dif`, `pooledrr` family, `has<year>` / `has<year><survey>`, file-suffix forms (`analysisready`, `pooledstats`, `forpooling`, `paneldata`, `responseyear`).

**Packages**: `_gwtmean` (`wtmean` egen extension).

### 17+ new bugs/anomalies in chunk 8 (running total ≈70)

Most material:

1. **`_archive/matt_original/sum_stats.do` still produces paper Table A.1 — should not have been archived without flagging.** (Resolved by the action item Q8.1.)
2. `create_score_samples.do:240-247` and `create_out_samples.do:225-232`: `egen n_g11_<subject>_<sample>_sp` computed but never `save`d — silent dead-code (the labels claim it's persisted).
3. `parentdemographics.do:13`: 1415 missing grade-7 obs (`-8` code, 1327 obs) silently dropped.
4. `pooledsecdemographics.do:23-24`: `gr<9|11>asianenr += filipinoenr` overwrites in-place — substantive demographic recoding without ADR.
5. `pooledsecanalysis.do:31-43`: silent `drop if check<race>==1` data-quality filter applied only at graph time.
6. `secdemographics.do:102` vs `elemdemographics.do:67`: sex coding inverts between elem (1=F) and sec (1=M) — landmine.
7. `secdemographics.do:59`: 1718/1819 trans/nb/questioning gender option not handled.
8. Two `pooledrr` definitions with same name in different files.
9. `touse_va.do:104-107`: paper-mentioned ">25% special ed" + "home/hospital" filters never implemented in code.
10. `create_out_samples.do:71`: `enr_ontime → enr` rename silently overwrites original `enr` semantics.

### Open questions for user (Chunk 8)

| # | Question | Affects |
|---|---|---|
| Q8.1 | **Is `counts_k12.tex` (paper Table A.1) currently stale?** Should `sum_stats.do` + `sum_stats_tab.do` move out of `_archive/matt_original/`? | **Paper Table A.1 reproducibility** |
| Q8.2 | Does Table A.1 paper text caption need to disambiguate ≤10 cohort vs <7 per-cell cuts? | Paper text |
| Q8.3 | Grade-7 1415 silent drop (1327 obs in `-8`) — flag or exclude pooled grade-7 stats? | Pooled grade-7 statistics |
| Q8.4 | Trans/nb/questioning gender in 1718/1819 sec — drop or include in sex-stratified counts? | Section 2 representativeness |
| Q8.5 | Silent `drop if check<race>==1` filter in `pooledsecanalysis.do` — promote to data-quality assertion? | Reproducibility |
| Q8.6 | Two `pooledrr` definitions — rename one or document explicitly? | Risk of consuming wrong one |
| Q8.7 | `gr<9|11>asianenr += filipinoenr` recoding — needs ADR if it survives consolidation | Methodology documentation |

---

## Chunk 9: Share/output helpers + explore (COMPLETE — paper-output mapping closed loop)

Files audited: 13 in `cde_va_project_fork/do_files/{share,share/check,explore}/`. Per-file detail: `quality_reports/audits/2026-04-25_chunk9-share-explore.md`.

### CORRECTION to chunk 8 finding

**`share/sample_counts_tab.do` is the MODERN producer for `counts_k12.tex`** (paper Table A.1), **superseding** `_archive/matt_original/sum_stats_tab.do`. So Q8.1 (Table A.1 staleness alarm) is **resolved** — the .tex IS being produced, just from the modern share/ path, not the archived file. The chunk-8 alarm was based on the older code path that's no longer active. **The archive disposition for `sum_stats.do` and `sum_stats_tab.do` is correct after all** — they ARE superseded.

### Final paper-output mapping (all chunks consolidated)

Closed loop — every paper artifact has a confirmed producer in `cde_va_project_fork/do_files/share/`:

| Paper artifact | Filename | Producer |
|---|---|---|
| Table 1 (`tab:sum-stats`) | `sum_stats_g11.tex`, `sum_stats_college.tex` | `share/base_sum_stats_tab.do` (chunk 9) |
| Table 2 (`tab:va-sum-stats`) | `va_score_v1.tex` | `share/va_spec_fb_tab_all.do` (chunk 9; chunk 3 deferred) |
| Table 3 (`tab:va-enr-summary-statistics`) | `va_out_v1.tex` | `share/va_spec_fb_tab_all.do` (chunk 9) |
| Table 4 (`tab:hetero`) | `va_het/corr_char_wt_v1.tex` | `share/va_het.do` (chunk 4) |
| Table 5 (`tab:va-var-across-district`) | `va_het/var_across_district_wt_v1.tex` | `share/va_het.do` (chunk 4) |
| Table 6 (`tab:va-persistence`) | `persistence_single_subject.tex` | `share/reg_out_va_tab.do` (chunk 9; chunk 4 deferred) |
| Table 7 (`tab:va-enr-decomposition`) | `va_var_explain_v1.tex` | `share/va_var_explain.do` + `va_var_explain_tab.do` (chunk 9) |
| Table 8 (`tab:survey`) | `imputed_index_combined_wdemo.tex` | `share/svyindex_tab.do` (chunk 9; chunk 6 deferred — no manual combination needed) |
| Table A.1 (`tab:sample-counts`) | `counts_k12.tex` | `share/sample_counts_tab.do` (chunk 9 — corrects chunk 8 archive alarm) |
| Figs 1-4 (VA correlations + scatter + heterogeneity panels) | combined PDFs | `share/va_scatter.do` (chunk 9) |

**No paper-artifact producer lives outside `cde_va_project_fork/do_files/share/`.** The only out-of-repo dependency is the input data for Table 8 (`$projdir/out/dta/factor/index<reg>withdemo/...` from CASCHLS), but the TeX writer itself is in cde_va_project_fork.

### scrhat (predicted-prior-score) pipeline

```
data/va_samples/{score,out}_<sample>.dta
        ↓
reg prior_ela_z_score lag2ela i.year <va_ctrl>_spec_controls
predict prior_ela_z_score_hat       (only valid where lag2ela non-missing)
        ↓
explore/va_predicted_score.do          (no leave-out; main scrhat VA estimates)
explore/va_predicted_score_fb.do       (with leave-out; FB tests on scrhat VA)
        ↓
estimates/va_cfr_all_<v>/{vam,spec_test,fb_test,va_est_dta}/predicted_prior_score/*.{ster,dta}
        ↓
explore/va_predicted_score_spec_fb_tab.do
        ↓
tables/explore/va_{score,out,<outcome>}_<version>.tex   (NOT in the paper)
```

**Confirmed**:

- First-stage uses `lag2ela` (= `L4_cst_ela_z_score` for 2015-16, `L5_cst_ela_z_score` for 2017-18 — the leave-out-school CST score from 2 grades back).
- The predicted score replaces the observed `prior_ela_z_score` everywhere `lag2ela` is non-missing; observations with missing `lag2ela` drop from the VA regression.
- Effective scrhat sample = original VA sample ∩ `lag2ela` non-missing (strict subset).
- **Reported in paper? NO.** Outputs to `tables/explore/`, never referenced from `paper/main.tex`. Robustness check / internal-only.
- The scrhat per-cell `va_*.dta` files are written but never re-read (only `.ster` files consumed). Dead artifacts on disk.

### New tokens / packages

- `predicted_prior_score/` subdir (scrhat pipeline)
- `_lv` filename-stem suffix (FB leave-out version) — partially seen earlier; now confirmed pattern
- `_va_ela_math_` regression-target naming for both-subject simultaneous regressions

**No new ssc packages.** Total catalog still ~16 packages.

### 17 new bugs/anomalies in chunk 9 (running total ≈85)

Most material:

1. **`va_predicted_score_fb.do:43`**: uses `<va_ctrl>_ctrl_leave_out_vars` instead of `<va_ctrl>_ctrl_scrhat_leave_out_vars`. Result: FB tests on `loscore` are computed for scrhat VA, which is conceptually invalid (loscore is the first-stage IV — can't simultaneously be a leave-out for the second stage).
2. **`va_spec_fb_tab_all.do:200-202`**: per-outcome `texsave` writes both versions to `check/`, never `pub/`. Per-outcome single-table files only exist in `check/`.
3. **`va_scatter.do:308, 321, 333, 417, 430, 442`**: figure note says "Fitted line slope = `corr_*`" but should be `b_*` — copy-paste error in 6+ places. Affects panel 1 of paper Fig 3 and Fig 3-alt.
4. **`reg_out_va_tab.do:47`**: `lasd_ct_p` in `sp_ct_p_combos` but 4-column reshape silently drops it. Either intentional (paper Table 6 has only 4 columns per outcome) or oversight.
5. **`va_var_explain.do:19-20`** and **`va_var_explain_tab.do:17-18`**: `set trace on` never paired with `set trace off`.
6. **`base_sum_stats_tab.do`**: hard-codes `data/va_samples_v1/base_nodrop.dta` — no v2 parallel.
7. **`base_sum_stats_tab.do:463-579`**: long sequence of `esttab ... append` — failure mid-sequence leaves output file inconsistent.
8. **`sample_counts_tab.do`**: cascading `if`-filters duplicated 12 times for counts AND 12 times for z-scores — a missing `&` would silently produce wrong table rows.
9. **`svyindex_tab.do:185`**: missing space after `translate` keyword.
10. **`va_predicted_score.do` and `va_predicted_score_fb.do`**: first-stage (`reg prior_ela_z_score lag2ela`) recomputed per iteration despite being identical — wasteful.
11. **`corr_dk_score_va.do`**: redundantly hard-codes sample-control lists already in `macros_va_all_samples_controls.doh`.

### Open questions

**For user (Chunk 9)**:

| # | Question | Affects |
|---|---|---|
| Q9.1 | Is the "predicted_score" column in `fb_<outcome>_all.dta` populated by chunk-3 producer, or did Christina's 2024 changes break the upstream contract? If upstream writes `predicted_score = 0`, the scrhat tab files produce empty tables. | scrhat exploratory pipeline integrity |
| Q9.2 | Should the `va_predicted_score_fb.do:43` bug (non-scrhat leave-out list) be patched, even though scrhat is exploratory? | scrhat reproducibility |
| Q9.3 | Should the `va_scatter.do` `corr_*` vs `b_*` typo (6+ occurrences) be fixed and figures re-rendered? Affects paper Fig 3 panel 1 and Fig 3-alt. | Paper figure note correctness |
| Q9.4 | The `lasd` column dropping in `reg_out_va_tab.do` — intentional (Table 6 has 4 columns) or oversight (chunk 4 produces `lasd` cells)? | Paper Table 6 column count |
| Q9.5 | Are scrhat per-cell `.dta` files (`va_est_dta/predicted_prior_score/`) dead artifacts to delete? | Cleanup scope |

**For chunk 10**:

- Where does `lag2ela` ultimately come from? `merge_lag2_ela.doh` reads from `k12_lag_test_scores_clean.dta` — chunk 10 should cover upstream lag-test-score panel construction.
- The `sibling_out_xwalk` global path referenced in `sample_counts_tab.do:53` but never defined locally.
- Distance controls Python pipeline (geocoding) — chunk 10 territory.

---

## Chunks pending

### Chunk 10: Upstream / Python geocoding (final chunk)

- `cde_va_project_fork/do_files/sbac/macros_va.doh` ← DONE in foundation
- `cde_va_project_fork/do_files/sbac/create_va_sample.doh`
- `cde_va_project_fork/do_files/sbac/create_va_g11_sample.doh`
- `cde_va_project_fork/do_files/sbac/create_va_g11_out_sample.doh`
- `cde_va_project_fork/do_files/sbac/create_diff_school_prop.doh`
- `cde_va_project_fork/do_files/sbac/create_prior_scores_v1.doh`
- `cde_va_project_fork/do_files/sbac/create_prior_scores_v2.doh`
- `cde_va_project_fork/do_files/merge_k12_postsecondary.doh`
- `caschls/do/share/siblingvaregs/vafilemacros.doh`
- `caschls/do/share/siblingvaregs/vaestmacros.doh`

Cautious mode (these are referenced by every estimation script).

### Chunk 3: VA-core estimation (CAUTIOUS)

- `va_score_all.do`, `va_score_fb_all.do`
- `va_out_all.do`, `va_out_fb_all.do`
- `va_score_sib_lag.do`, `va_out_sib_lag.do`
- `merge_va_est.do`, `va_corr.do`
- spec-test and forecast-bias tab files

### Chunk 4: Pass-through and heterogeneity (CAUTIOUS)

- `reg_out_va_all.do`, `reg_out_va_dk_all.do`
- `_tab` and `_fig` variants
- `prior_decile_original_sample.do`
- `va_corr_schl_char.do`, `va_het.do`, `persist_het_student_char_fig.do`

### Chunk 5: Sibling crosswalk + sibling VA regs (CAUTIOUS — N1 trace lives here)

- `caschls/do/share/siblingxwalk/siblingmatch.do`
- `caschls/do/share/siblingxwalk/uniquefamily.do`
- `caschls/do/share/siblingxwalk/siblingpairxwalk.do`
- `caschls/do/share/siblingvaregs/siblingoutxwalk.do`
- ~30 sibling_va_regs files for the 4-spec analysis

### Chunk 6: Survey VA (CAUTIOUS for regs, AGGRESSIVE for cleaning)

- `caschls/do/share/factoranalysis/*` (~10 files)
- `caschls/do/share/svyvaregs/*`
- `caschls/do/build/buildanalysisdata/poolingdata/clean_va.do`
- `caschls/do/share/svyvaregs/allvaregs.do`

### Chunk 7: Data prep (AGGRESSIVE)

- `cde_va_project_fork/do_files/acs/*`
- `cde_va_project_fork/do_files/schl_chars/*` (11 files)
- `cde_va_project_fork/do_files/k12_postsec_distance/*`
- `caschls/do/build/prepare/*`
- `caschls/do/build/buildanalysisdata/qoiclean/*` (10 files)

### Chunk 8: Samples (AGGRESSIVE)

- `cde_va_project_fork/do_files/sbac/touse_va.do`, `create_score_samples.do`, `create_out_samples.do`
- `caschls/do/build/buildanalysisdata/poolingdata/*`
- `caschls/do/build/buildanalysisdata/responserate/*`
- `caschls/do/build/sample/*`
- `caschls/do/share/demographics/*`

### Chunk 9: Share/output helpers (AGGRESSIVE)

- `cde_va_project_fork/do_files/share/*` (~10 files)
- `cde_va_project_fork/do_files/explore/*` (3 files)

### Chunk 10: Upstream (AGGRESSIVE)

- `cde_va_project_fork/do_files/upstream/crosswalk_nsc_outcomes.do`
- `caschls/do/upstream/crosswalk_ccc_outcomes.do`
- `caschls/do/upstream/crosswalk_csu_outcomes.do`
- Python upstream geocoding scripts (py_files/ in both predecessors)

After Chunk 1 (foundation), Chunks 2-5 should run sequentially or with limited parallelism (they share VA-core context). Chunks 6-10 can run in parallel after that.
