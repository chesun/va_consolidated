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

- The change-log notes "v1/v2" but on inspection, **`scrhat` ≠ v2**. The `scrhat` variants are the *predicted-prior-score* exploratory specs (added Aug 2024). The v1/v2 distinction the user flagged is about prior-score controls more broadly; in this file the v2 manifests as the `_scrhat_` family. **Verify**: is `scrhat` *one of* the v2 variants, or orthogonal to v1/v2?
- Naming convention confirmed: `b/l/a/s/d` with combinations, `peer_` prefix, `_str` suffix, `_controls` (standalone) vs `_spec_controls` (full spec), `_scrhat_` infix.
- Conventions the user mentioned but **not visible in this file** (`sp`, `ct`, `nw`, `_m`, `_wt`): not defined in macros_va.doh — flagged for downstream chunks.
- **Bug at line 535**: `asd_str = a_str` (NOT `as_str`) — looks like a copy-paste bug; the string "ACS" gets used as the label for the "ACS & sibling & distance" combo.
- **Bug at line 558**: `prop_ecn_disadv_str` is missing a trailing `;` — Stata's `#delimit ;` mode means this label line continues into the next definition.
- **Empty `peer_d_controls` issue** (line 304 loop): `peer_<combo>d_controls` lacks any peer-distance terms.

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

## Chunks pending

### Chunk 2: VA-core helpers (.doh files referenced by va_score_all / va_out_all)

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
