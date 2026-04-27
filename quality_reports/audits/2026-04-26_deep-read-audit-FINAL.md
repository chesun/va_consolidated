# Phase 0a-v2 Verified-Final Audit (Common Core VA Project)

**Status:** Phase 0a-v2 round-2 COMPLETE.
**Date:** 2026-04-26
**Method:** Independent blind verification (round 2) of every Phase 0a finding (round 1). 10 chunks × 2 rounds + 6 T3 deterministic checks. **3 confirmation-bias-style errors caught and resolved by the protocol.**

This document consolidates the verified findings across 10 chunks of deep-read audit. It supersedes the round-1 docs at `quality_reports/audits/round-1/` for reference purposes (round-1 is preserved for archeology). Per-chunk discrepancy details are in `quality_reports/audits/round-2/chunk-N-discrepancies.md`.

---

## 1. Executive Summary

**Scope audited:** ~150 files across `cde_va_project_fork/` and `caschls/`, in 10 chunks: foundation, VA helpers, VA core, pass-through+heterogeneity, sibling crosswalk+regs, survey VA+factor analysis, data prep, samples, share/output helpers+explore, upstream+Python.

**Verification protocol outcomes:**

- **0 genuine factual contradictions** between rounds.
- **3 confirmation-bias-style errors caught**:
  1. Round-2 chunk-2 mis-flagged `asd_str` as still broken (was fixed in `e8dd083`).
  2. Round-1 chunk-2 mis-flagged `peer_L3_cst_ela_z_score` as missing from keepusing (it IS present at L29 of `create_va_sample.doh`).
  3. My round-2 chunk-5 prompt added spurious `reg_out_va_sib_acs_dk_tab.do` filename by symmetry assumption (T3 confirmed file doesn't exist; round-1 didn't claim it did).
- **All 3 errors resolved by T3** (deterministic file read).
- Two TEMPORAL ARTIFACTS (vam customization status, macros_va.doh missing-`;` location) resolved cleanly as "both rounds correct in their respective time slices."

**Foundational findings LOCKED:**

- N1: SAFE to relocate `siblingoutxwalk.do` from `siblingvaregs/` to `siblingxwalk/`. Two callers need updating: `master.do:103` and `do_all.do:142`. **Unblocks ADR-0004.**
- N2 (path geometry): two predecessor repos co-resident on Scribe, cross-wired via `$projdir`/`$vaprojdir`; one-way cross-repo direction (do_all.do → master.do).
- v1 prior-score table verified line-by-line; v2 docstring dates were transcription errors (code uses L5 = 5-year lag).
- `_scrhat_` is exploratory third axis, orthogonal to v1/v2 (predicted prior score, not in paper).
- vam.ado is Stepner v2.0.1 with one customization: noseed-fix at L252-255 dated 2026-04-25 (commit `0202251`).
- Paper Tables 1-8 + Figs 1-5 producers all in `cde_va_project_fork/do_files/share/`. Closed loop.
- Sample-restriction map (paper Table A.1) finalized: 9 rows mapped to `sample_counts_tab.do` + `touse_va.do`. Two cohort cuts (school-level `<=10` + cell-level `<7`) coexist, not redundant.
- **Distance-FB Row 6 mystery RESOLVED.** Producer chain (chunk 7) wires `d` token correctly. **But chunk 9 producer (`va_spec_fb_tab_all.do`) DROPS column 6 FB rows due to keeper-rule omission.** Paper Tables 2 and 3 column 6 has spec-test row but BLANK FB rows. **Real paper-output integrity bug.**

**Two findings initially flagged as CRITICAL — RECLASSIFIED NOT-A-BUG (Christina 2026-04-26):**

- **~~CB1~~ → NOT A BUG (intentional, structural FB-test property)**: `va_spec_fb_tab_all.do:82-84` keeper rule omits `va_control=="lasd"` because **the FB test has no leave-out variable when VA already includes everything**. FB test structure: (1) estimate VA w/o some controls, (2) estimate VA with those controls, (3) regress (residual_no_ctrl − residual_with_ctrl) on the round-1 VA estimates. When the VA spec is `lasd` (loscore + ACS + sibling + distance — kitchen sink), there are no controls left to leave out, so no FB test is possible. `macros_va_all_samples_controls.doh:66-76` confirms: `va_controls_for_fb` lists 8 specs (`b l a s la ls as las`), **explicitly excludes `lasd`**, and there is NO `lasd_ctrl_leave_out_vars` macro. Column 6 blank FB cells is correct by design. Paper Tables 2/3 column 6 (Distance) shows the spec-test row only.
- **~~CB2~~ → NOT A BUG (Christina 2026-04-26)**: same structural-FB-property reframing applies. Per Christina: "this and other bugs you marked relating to the FB test are not actual bugs."

**Other FB-test-related findings reclassified (per Christina 2026-04-26):**

- chunk-3 §A13 distance-leave-out (`d`) gap in `va_spec_fb_tab.do` lovar loop → NOT A BUG. The lovar loop omits `lasd` for the same structural reason.
- chunk-9 M2 (`predicted_score==0` filter missing) → NOT A BUG. Scrhat outputs are written to `predicted_prior_score/` subdirs separately; not conflated in upstream regsave datasets.

**Bug 93 family scoped at 4 instances (LOCKED):**

1. `crosswalk_nsc_outcomes.do:218-219` — `nsc_enr_uc` (UC Merced bypasses `recordfoundyn`)
2. `crosswalk_nsc_outcomes.do:227-228` — `nsc_enr_ontime_uc` (bypasses `recordfoundyn` AND `enrollmentbegin`)
3. `merge_k12_postsecondary.doh:168-170` — `ccc_enr_ontime`
4. `merge_k12_postsecondary.doh:232-234` — `csu_enr_ontime`

**Bug 93 paper-impact: NULL for current paper.** `nsc_enr_uc` consumed only by `csu_transfer_uc`; `csu_transfer_uc` not cited in `paper/common_core_va_v2.tex`. Composite outcomes (`enr_4year`, `enr_2year`, `enr`) do NOT use `nsc_enr_uc`. Phase 1 priority: still fix (cheap, prevents future inheritance) but **downgrade from PAPER-BLOCKING to LOW current-paper-impact (P2 not P1)**.

---

## 2. Verified Findings — Bug-Priority Triage

### P1 — High-priority (paper-output integrity OR pre-Phase-1 blocker)

| # | Bug | File:Line | Source | Action |
|---|---|---|---|---|
| ~~**P1-1**~~ | ~~Column 6 FB rows DROPPED from paper Tables 2/3~~ — **NOT A BUG** (Christina 2026-04-26): structural FB-test property — `lasd` has no leave-out variables left, so no FB test possible. `va_controls_for_fb` (`macros_va_all_samples_controls.doh:66`) excludes `lasd` by design. Column 6 blank FB cells is correct. | `va_spec_fb_tab_all.do:82-84` | chunk 9 disc M1 | RESOLVED — no fix needed |
| ~~**P1-2**~~ | ~~`predicted_score==0` filter MISSING~~ — **NOT A BUG** (Christina 2026-04-26): scrhat outputs go to `predicted_prior_score/` subdirs separately; not conflated in upstream regsave. | `va_spec_fb_tab_all.do:71-76` | chunk 9 disc M2 | RESOLVED — no fix needed |
| ~~**P1-3**~~ | ~~Distance-FB Row 6 attribution~~ — **RESOLVED**: column 6 IS the `lasd` (kitchen-sink + distance) column. Paper Table 2/3 row 6 = Distance INCLUDED IN VA SPEC, not Distance-as-leave-out. Spec-test row populated; FB rows correctly blank. | `paper/common_core_va_v2.tex` | chunk 3, 7, 9 | RESOLVED |
| **P1-1** | **Local `id` macro undefined at `crosswalk_nsc_outcomes.do:250`** — `egen ... by(\`id' collegecodebranch)` may collapse to global-min-by-college | `crosswalk_nsc_outcomes.do:250` | chunk 10 disc M1 | T1: Christina runs on Scribe, checks whether `college_begin_date` varies by student. If empty `id`, persistence outcomes silently corrupted. |
| **P1-2** | **Paper-α attribution issue** — climate/quality index item lists in `compcase/imputedcategoryindex.do` (9/15 items) ≠ α item lists in `alpha.do` (20/17 items). If paper-α is from `alpha.do`, paper describes a DIFFERENT object than Table 8 regression indices | `alpha.do` vs `compcasecategoryindex.do` | chunk 6 disc M1 | T4: Christina checks paper PDF for α attribution |

### P2 — Medium-priority (correct in current paper but should be fixed; future-proofing)

| # | Bug | File:Line | Source | Action |
|---|---|---|---|---|
| **P2-1** | **Bug 93 family — 4 instances of `& inlist(...) | inlist(...)` precedence error** | `crosswalk_nsc_outcomes.do:218-219, 227-228` + `merge_k12_postsecondary.doh:168-170, 232-234` | chunks 2, 10 disc reports | T1: Christina runs `count if nsc_enr_uc==1 & recordfoundyn!="Y"` etc. Phase 1: bundled patch wrapping OR clauses in outer parens. |
| **P2-2** | **`va_corr_schl_char.do` LHS-peer-suffix bug** — when sample==las, regression uses non-peer VA but saves under `..._ct_p.ster` filename | `va_corr_schl_char.do:84-88, 94-98` | chunk 4 disc A2 | Phase 1: fix LHS to use peer VA when filename suffix is `_p` |
| **P2-3** | **`va_het.do:158 cluster(cdscode)`** vs paper-claimed `school_id` (only chunk-4 reg using `cdscode`) | `va_het.do:158` | chunk 4 disc A3 | T1: Christina runs `assert school_id == cdscode` on Scribe. If 1:1, cosmetic only. |
| **P2-4** | **`run_prior_score = 0` hard-codes single-subject prior-decile heterogeneity OFF** — fig file unconditionally tries to load gated `.ster` files | `reg_out_va_all.do:235`, fig file `reg_out_va_all_fig.do:159` | chunk 4 disc A1 | T4: keep gate, remove gate, or make explicit toggle? |
| **P2-5** | **`reg_out_va_sib_acs_tab.do` mtitles labeling bug** — uses FB-test column titles for persistence-on-VA regression table | `reg_out_va_sib_acs_tab.do:82-88` | chunk 5 disc M1 | T4: confirm CSV feeds paper Table 7. Phase 1: replace mtitles with "Original Specification" / "Census Controls" / "Sibling Controls" / "Sibling and Census Controls" |
| **P2-6** | **`reg_out_va_all_tab.do` mtitles 24 cols vs 32 actual eststo** — possible silently un-labeled columns | `reg_out_va_all_tab.do` (file 4 of chunk 4) | chunk 4 disc M4 | T1: open `$vaprojdir/tables/.../reg_*.csv` on Scribe and count columns vs declared mtitles |
| ~~**P2-7**~~ | ~~`va_predicted_score_fb.do:43` uses `<va_ctrl>_ctrl_leave_out_vars`~~ — **NOT A BUG** (Christina 2026-04-26): may be intentional given scrhat is exploratory; structural FB-test reasoning means extra runs are either inert (sample list undefined) or just exploratory output. Reclassified per Christina's broad statement that "FB-test-related bugs are not actual bugs." | `va_predicted_score_fb.do:43` | chunk 9 disc A2 | RESOLVED |
| **P2-8** | **`va_scatter.do` figure-note `corr_*` vs `b_*` typos** — 6 lines say "Fitted line slope = `corr_*`" when value is correlation rho | `va_scatter.do:308, 321, 333, 417, 430, 442` | chunk 4 + 9 disc A3 | Phase 1: fix typos + re-render figures |
| **P2-9** | **`merge_k12_postsecondary.doh:7` HARDCODED ABSOLUTE PATH** to `/home/research/ca_ed_lab/projects/common_core_va/data/restricted_access/clean/crosswalks/` | `merge_k12_postsecondary.doh:7` | chunk 2 disc A5 | Phase 1: parameterize via `$vaprojxwalks` |
| **P2-10** | **NSC/CCC/CSU asymmetry in `enr` definition** — `enr=1` requires NSC (CCC/CSU commented out); `enr=0` requires NSC=0 AND CCC!=1 AND CSU!=1. Students never matched to NSC end up `enr=.` | `merge_k12_postsecondary.doh:326-327` | chunk 2 disc A6 | T4: intentional NSC-anchoring or bug? |
| **P2-11** | **`reg_out_va_sib_acs.do` heterogeneity regs cluster on `cdscode`** while main regs cluster on `school_id` (same flag as chunk-4 P2-3) | `reg_out_va_sib_acs.do:151, 174, 211, 225` | chunk 5 disc A10 | T1: same `school_id == cdscode` test resolves jointly with P2-3 |
| **P2-12** | **`set trace on` without matching `off`** in `va_var_explain.do` | `va_var_explain.do:20` | chunk 9 disc A5 | Phase 1: add `set trace off` |
| **P2-13** | **OpenCage API key in source** (commented but committed) | `k12_postsec_distances.do:98` | chunk 7 disc A5 | T1: Christina revokes/rotates the key (security hygiene) |
| **P2-14** | **`enrollmentclean.do:21` female-encoding bug** — missing-gender → `female==0` (treated as male) | `enrollmentclean.do:21` | chunk 7 disc A8 | Phase 1: fix to `female=.` for missing |
| **P2-15** | **mattschlchar.do hardcoded msnaven cross-user path** — gated by `local clean = 0` so dormant; replication weak point | `mattschlchar.do:17` | chunk 6 disc A4 | T4 + Phase 1: vendor `sch_char.dta` from Matt's directory into consolidated `data/` |

### P3 — Low-priority (cosmetic, dead code, comment-only restrictions, naming hygiene)

| # | Bug | File:Line | Source |
|---|---|---|---|
| **P3-1** | macros_va.doh L23 missing `;` (LATENT — `$vaprojdofiles` and `$ca_ed_lab` never consumed) | `macros_va.doh:23` | chunk 1 disc M1 + T3.1/T3.2 |
| **P3-2** | macros_va.doh `l_scrhat_spec_controls` pattern break (LATENT-MEDIUM — affects scrhat exploratory only) | `macros_va.doh:342-345` | chunk 1 disc M2 + T3.3 |
| **P3-3** | macros_va.doh `Xd_str` aliases all collapse to `X_str` | `macros_va.doh:485, 493, 501, 509, 517, 525, 533, 541` | chunk 1 disc M3 (T4 intent) |
| **P3-4** | `do_all.do:253` cross-repo call hardcoded absolute path (no `$projdir` expansion) | `do_all.do:253` | chunk 1 disc A5 |
| **P3-5** | vam.ado `*!` version line not updated to reflect 2026-04-25 noseed-fix | `vam.ado:1` | chunk 1 disc A11 |
| **P3-6** | macros_va.doh `peer_<X>d_controls` asymmetry (peer-distance not appended) | `macros_va.doh:298-307` | chunk 1 disc A16 (T4 intent) |
| **P3-7** | vaestmacros.doh L45, L118 missing `$` prefix on `vaprojdir` | `vaestmacros.doh:45, 118` | chunk 2 disc A8 |
| **P3-8** | vaestmacros.doh L27 `.dta.dta` double extension typo | `vaestmacros.doh:27` | chunk 2 disc A7 |
| **P3-9** | va_out_all.do L176 typo `_cts.ster` instead of `_ct.ster` | `va_out_all.do:176` | chunk 3 disc A8 |
| **P3-10** | va_out_sib_lag.do uses `score_drift_limit` for outcome VA (latent — both = 2 today) | `va_out_sib_lag.do:56, 97, 119` | chunk 3 disc A7 |
| **P3-11** | va_out_fb_test_tab.do missing `log close` and `translate` at end of file | `va_out_fb_test_tab.do:172-174` | chunk 3 disc A9 |
| **P3-12** | va_out_spec_test_tab.do uses `sd_va` instead of `sd_va_peer` for predicted-score peer row | `va_out_spec_test_tab.do:163` | chunk 3 disc A10 |
| **P3-13** | va_sib_lag_spec_fb_tab.do uses `p_value` instead of `pval` (naming inconsistency) | `va_sib_lag_spec_fb_tab.do:70` | chunk 3 disc A11 |
| **P3-14** | out_drift_limit.doh dead code (never include'd) | `out_drift_limit.doh` | chunk 3 disc A6 |
| **P3-15** | va_corr.do typos "ase sample", "ktichen"; date2 never assigned | `va_corr.do:57, 60, 82` | chunk 3 disc M1 |
| **P3-16** | reg_out_va_all.do nested forvalues `i` shadowing | various | chunk 4 disc A11 |
| **P3-17** | va_corr_schl_char_fig.do `ytitle` on kdensity (mislabels density as VA) | `va_corr_schl_char_fig.do:104` | chunk 4 disc M2 |
| **P3-18** | va_het.do `gr5` dead branch (loop omits gr5) | `va_het.do:66, 102` | chunk 4 disc A5 |
| **P3-19** | va_het.do hlines typo (13 duplicated) | `va_het.do:214` | chunk 4 disc M3 |
| **P3-20** | reg_out_va_all_fig.do filename typo `_x_prior_x_prior_` | `reg_out_va_all_fig.do:568` | chunk 4 disc A6 |
| **P3-21** | reg_out_va_all_fig.do comment "90% CI" but vars are 95% (`min95 max95`) | `reg_out_va_all_fig.do:172, 288, 453` | chunk 4 disc A7 |
| **P3-22** | reg_out_va_dk_all_fig.do retains on-figure titles | `reg_out_va_dk_all_fig.do:148-150` | chunk 4 disc A8 |
| **P3-23** | prior_decile_original_sample.do `inc_mean_hh_xtile` typo | `prior_decile_original_sample.do:106` | chunk 4 disc A9 |
| **P3-24** | va_corr_schl_char.do orphaned (superseded by va_het.do) | `va_corr_schl_char.do` | chunk 4 disc A10 |
| **P3-25** | reg_out_va_all_tab.do:463 di message references `_fig.do` instead of `_tab.do` | `reg_out_va_all_tab.do:463` | chunk 4 disc N1 |
| **P3-26** | siblingmatch.do `egen group ..., mi` flag (mega-family risk if many missing addresses) | `siblingmatch.do:49, 86` | chunk 5 disc M3 |
| **P3-27** | siblingmatch.do no surname normalization (case-sensitive) | `siblingmatch.do:49` | chunk 5 disc A5 |
| **P3-28** | uniquefamily.do `numsiblings_exclude_sef` typo | `uniquefamily.do:56` | chunk 5 disc A7 |
| **P3-29** | va_sibling.do collapse `if sibling_full_sample==1` filter ASYMMETRIC vs va_sibling_out.do (harmless but jarring) | `va_sibling.do:291` vs `va_sibling_out.do:327-331` | chunk 5 disc A9 |
| **P3-30** | reg_out_va_sib_acs_fig.do ACS spec missing from combined panels | `reg_out_va_sib_acs_fig.do:213-216, 309-317` + dk_fig L131-135 | chunk 5 disc M2 |
| **P3-31** | va_sibling_fb_test_tab.do trailing-space typo in macro reference | `va_sibling_fb_test_tab.do:64, 91` | chunk 5 disc M4 |
| **P3-32** | clean_va.do destructive in-place save on each `<svy>analysisready.dta` | `clean_va.do:76` | chunk 6 disc A1 |
| **P3-33** | allvaregs.do weighted-merge filename collision | `allvaregs.do:197` | chunk 6 disc A2 |
| **P3-34** | factor.do log dir wrong (`do/share/` instead of `log/share/`) | `factor.do:11, 79` | chunk 6 disc A6 |
| **P3-35** | Motivation index orphan (imputed + α-reported but commented out at index construction) | `imputation.do`/`alpha.do` vs `imputedcategoryindex.do:31` | chunk 6 disc A7 |
| **P3-36** | Silent merge attrition across chunk-6 files (no `assert _merge==3`) | various | chunk 6 disc A8 |
| **P3-37** | pcascore.do duplicate pc1 histogram saved as staffpc2score.png | `pcascore.do:38` | chunk 6 disc A9 |
| **P3-38** | indexalpha.do no `translate` smcl→log | chunk 6 disc N1 |
| **P3-39** | clean_acs_census_tract.do L84 double-counts `s1501_c01_012e` | `clean_acs_census_tract.do:84` | chunk 7 disc M1 |
| **P3-40** | k12_postsec_distances.do hardcoded asserts (CSU=23, UC=9, 4yr=115) | `k12_postsec_distances.do:50, 54, 58` | chunk 7 disc A4 |
| **P3-41** | reconcile_cdscodes.do in-place lossy save | `reconcile_cdscodes.do:81` | chunk 7 disc A6 |
| **P3-42** | clean_charter.do Apple Silicon detection broken | `clean_charter.do:26` | chunk 7 disc A7 |
| **P3-43** | renamedata.do 5-row drop discrepancy (comments vs code) | `renamedata.do:77-84` | chunk 7 disc A9 |
| **P3-44** | clean_locale.do hardcodes 2015-16 NCES locale data | `clean_locale.do:20` | chunk 7 disc M2 |
| **P3-45** | clean_staffdemo.do divergent fall-2014 vs fall-2015+ schema asymmetry | `clean_staffdemo.do` | chunk 7 disc M3 |
| **P3-46** | secqoiclean1415.do suspicious `keep`/`rename` patterns | `secqoiclean1415.do:15-19` | chunk 7 disc M4 |
| **P3-47** | clean_frpm.do hardcoded year-format branch | chunk 7 disc N1 |
| **P3-48** | touse_va.do paper-mentioned restrictions NOT-implemented (special ed, home/hospital) | `touse_va.do:104-107` | chunk 8 disc A5 |
| **P3-49** | enr_ontime → enr silent rename (overwrites original `enr` semantics) | `touse_va.do:117`, `create_out_samples.do:71` | chunk 8 disc A6 |
| **P3-50** | create_score_samples.do dead-code egen never `save`'d | `create_score_samples.do:240-247`, `create_out_samples.do:225-232` | chunk 8 disc A7 |
| **P3-51** | Sex coding inversion landmine (elem vs sec) | `secdemographics.do:102` vs `elemdemographics.do:67` | chunk 8 disc A8 |
| **P3-52** | Trans/nb/questioning gender (1718/1819 sec) acknowledged in comment but never ingested | `secdemographics.do:59` | chunk 8 disc A9 |
| **P3-53** | Filipino-into-Asian silent demographic recoding | `pooledsecdemographics.do:23-24` | chunk 8 disc A10 |
| **P3-54** | Silent graph-time drops in pooledsecanalysis.do | `pooledsecanalysis.do:31-43` | chunk 8 disc A11 |
| **P3-55** | 4 `pooledrr` definitions (variable-name overload across files) | `parentresponserate.do:72`, `secresponserate.do:71`, `pooledparentdiagnostics.do:42`, `pooledsecdiagnostics.do:65` | chunk 8 disc D1 |
| **P3-56** | counts_k12.tex paper-vs-code path "mismatch" (resolved by T3.6 — OLD-paper / NEW-paper divergence; cleanup only) | `paper/common_core_va.tex:169` | chunk 8 disc M1 + T3.6 |
| **P3-57** | base_sum_stats_tab.do v1-only (no v2 parallel) | `base_sum_stats_tab.do` | chunk 9 disc A6 |
| **P3-58** | sample_counts_tab.do v1-only (no v2 parallel) | `sample_counts_tab.do` | chunk 9 disc A7 |
| **P3-59** | sample_counts_tab.do 24 cascading-`if` blocks (refactor candidate) | `sample_counts_tab.do` | chunk 9 disc A8 |
| **P3-60** | svyindex_tab.do `translate$vaprojdir` missing space | `svyindex_tab.do:185` | chunk 9 disc A9 |
| **P3-61** | svyindex_tab.do `use ... , replace` syntax error | `svyindex_tab.do:43` | chunk 9 disc M3 |
| **P3-62** | reg_out_va_tab.do `lasd_ct_p` silently dropped (5th combo unused) | `reg_out_va_tab.do:47` | chunk 9 disc A4 |
| **P3-63** | va_var_explain_tab.do 5 controls but only 4 columns (`ls`/`lasd` dropped) | `va_var_explain_tab.do:48-52` | chunk 9 disc M5 |
| **P3-64** | kdensity.do apparent missing close brace | `kdensity.do:45 / EOF` | chunk 9 disc M4 |
| **P3-65** | crosswalk_ccc_outcomes.do Y2K-style cutover at year 20 (2020) | `crosswalk_ccc_outcomes.do:78-79` | chunk 10 disc M4 |
| **P3-66** | crosswalk_csu_outcomes.do path with whitespace ("actually clean") | `crosswalk_csu_outcomes.do:17` | chunk 10 disc M5 |
| **P3-67** | crosswalk_nsc_outcomes.do `set trace on` without off | `crosswalk_nsc_outcomes.do:34` | chunk 10 disc A9 |
| **P3-68** | Naven hardcoded user-machine paths in CCC/CSU crosswalks | `crosswalk_{ccc,csu}_outcomes.do:8-18` | chunk 10 disc A10 |
| **P3-69** | Geocoding rename gap (Python `_geocoded2.csv` vs Stata `_batch_geocoded.csv`) | `gecode_json.py:11` vs `merge_va_smp_acs.doh:49` | chunk 10 disc A4 |

**Total bug count: 85 (2 P1 + 14 P2 + 69 P3).** Original 89 minus 4 reclassified as NOT-A-BUG (CB1/P1-1, CB2/P1-2, P1-3 distance-FB attribution, P2-7 scrhat lov list) per Christina 2026-04-26 FB-test structural correction.

---

## 3. Action Items by Audience

### 3.1 — T1 Empirical Tests for Christina (run on Scribe when convenient)

These resolve P1-1, P2-1, P2-3, P2-6, P2-13. Approximate time: 30-60 minutes total in one session.

| # | Test | Resolves | Snippet |
|---|---|---|---|
| **T1-1** | After loading `nsc_outcomes_crosswalk_ssid.dta`, run: `egen check_grouping = tag(\`id' collegecodebranch)` then `count if check_grouping`. If `id` is empty, count = collegecodebranch count (small); if `id` resolves to ssid, count = ssid×collegecodebranch (large). | P1-1 (id macro at L250) | T3 verify on Scribe |
| **T1-2** | Bug 93 verification — count UC Merced rows with no NSC record. Confirms 4 family instances. | P2-1 | `use $vaprojdir/data/sbac/k12_postsecondary_out_merge.dta, clear` then `count if nsc_enr_uc==1 & recordfoundyn!="Y"` (>0 confirms bug for instance 1; analogous tests for the other 3) |
| **T1-3** | `school_id == cdscode` 1:1 check — resolves whether `va_het.do:158 cluster(cdscode)` and chunk-5 sibling regs `cdscode` clustering are equivalent to `school_id`. | P2-3, P2-11 | `use $vaprojdir/estimates/.../va_all.dta, clear` then `egen tag1 = tag(school_id)` `egen tag2 = tag(cdscode)` `count if tag1 != tag2` |
| **T1-4** | Open `$vaprojdir/tables/va_cfr_all_v1/reg_out_va/reg_*.csv`. Count actual columns vs declared `mtitles` (24 expected, 32 actual?). | P2-6 | open file in editor or `head` |
| **T1-5** | Revoke / rotate the OpenCage API key `[REVOKED 2026-04-30]`. | P2-13 | log into OpenCage account, revoke key |

**T1 items removed (resolved by Christina 2026-04-26):**

- ~~T1-1 (column 6 FB blank)~~ — NOT A BUG (intentional)
- ~~T1-2 (predicted_score filter)~~ — NOT A BUG (separate dirs)

### 3.2 — Phase 0e Q&A Items (T4 escalations)

Christina to discuss/decide. Most can be batched into a single Phase 0e walkthrough session.

| # | Question | Source |
|---|---|---|
| ~~**Q-1**~~ | ~~Paper Table 2/3 row 6 attribution~~ — **RESOLVED** (Christina 2026-04-26): Column 6 is the `lasd` column (kitchen-sink + distance INCLUDED IN VA SPEC). Spec-test row populated; FB rows correctly blank by FB-test structural property. | RESOLVED |
| **Q-2** | Is the `run_prior_score = 0` gate intentional? Single-subject prior-decile heterogeneity figures need it ON to regenerate cleanly. | P2-4 |
| **Q-3** | Where does the paper-reported α come from — `alpha.do` (wider 20/17/4/4-item lists) or `indexalpha.do` (narrower 9/15/4-item lists matching the regression indices)? | P1-5 |
| **Q-4** | Is the `enr=.` for NSC-non-matched-but-CCC-or-CSU-positive intentional NSC-anchoring or a bug? | P2-10 |
| **Q-5** | Is `mattschlchar.do`'s msnaven cross-user dependency planned for Phase 1 vendoring or symlink? | P2-15 |
| **Q-6** | Does `reg_out_va_sib_acs_tab.do` actually feed paper Table 7? If yes, the mtitles labeling bug needs fixing. | P2-5 |
| **Q-7** | `peer_<X>d_controls` peer-distance asymmetry — intentional (peer-distance not meaningful at school level) or bug? | P3-6 |
| **Q-8** | `Xd_str` display-string aliases (all collapse to `X_str`) — intentional or labeling bug? | P3-3 |
| **Q-9** | Naming standardization for sibling-VA — adopt `og/acs/sib/both` as canonical, deprecate `_sibling/_nosibctrl/_nocontrol`? | chunk 5 disc N2 |
| **Q-10** | DK controls in `va_sib_acs_out_dk.do` — hard-coded `va_ela_og va_math_og` across all 4 specs — intentional design choice (single OG baseline) or bug (should be spec-matched)? | chunk 5 disc A8 |
| **Q-11** | "Averages" (paper text) vs "Sums" (code) for survey indices — fix paper or fix code? | P3 (chunk 6 A3) |
| **Q-12** | NSC `keep(1 3 4 5)` + `update` vs CCC/CSU `keep(1 3)` — intentional NSC multi-vintage update or undocumented? | chunk 2 disc M3 |
| **Q-13** | `paper/common_core_va.tex` (OLD paper version) — abandoned? Phase 1 cleanup deletes it + stale `tables/sbac/counts_k12.tex`? | T3.6 / P3-56 |
| **Q-14** | Paper-mentioned but NOT-implemented restrictions in `touse_va.do:104-106` (>25% special ed, home/hospital) — were they implemented upstream in `va_samples.dta`, or never applied? | P3-48 |
| **Q-15** | Filipino-into-Asian silent recoding — needs ADR if survives consolidation. | P3-53 |
| **Q-16** | 4 `pooledrr` definitions — Phase 1 rename to indicate scope? | P3-55 |
| **Q-17** | Naming convention standardization for column-mapping consistency — Phase 1 sweep all `_tab.do` `mtitles` declarations vs eststo accumulation. | P2-5, P2-6, P3-62, P3-63 |
| **Q-18** | `lasd_ct_p` (5th combo in Table 6) silently dropped — intentional 4-column Table 6 layout, or oversight? | P3-62 |
| **Q-19** | `base_sum_stats_tab.do` and `sample_counts_tab.do` v1-only — intentional? | P3-57, P3-58 |
| **Q-20** | Geocoding pipeline documentation — Python `_geocoded2.csv` → Stata `_batch_geocoded.csv` rename: was production using the Python script + manual rename, or the Census Bureau's bulk batch tool? | P3-69 |

### 3.3 — Phase 1 Implementation Playbook (after Phase 0e)

Phase 1 fixes can proceed in this order after Phase 0e Q&A:

1. **Bundled Bug 93 patch** (4 instances, single template).
2. **Column 6 FB / `predicted_score==0` fixes** in `va_spec_fb_tab_all.do` (after T1-1, T1-2 confirm).
3. **mtitles audit sweep** across all `_tab.do` files (P2-5, P2-6, P3-62, P3-63).
4. **`run_prior_score` gate decision** + figure regeneration (after Q-2 resolved).
5. **Cross-repo path consolidation** — `merge_k12_postsecondary.doh:7` hardcoded path; mattschlchar.do msnaven path; OpenCage rotation; Naven user-machine paths in CCC/CSU.
6. **vam.ado provenance** — bump `*!` version to reflect noseed-fix.
7. **vendor external crosswalks** (`k12_ccc_crosswalk.dta`, `k12_csu_crosswalk.dta`) into consolidated repo.
8. **Sample-restriction code path simplification** — `touse_va.do` enforcement + paper-mentioned restrictions implementation.
9. **All P3 cleanup** — typos, dead code, log/translate fixes, naming consistency.
10. **siblingoutxwalk.do relocation** to `siblingxwalk/` (N1 SAFE) — 2 callers updated.

### 3.4 — Cross-cutting verification protocol meta-findings

The four-tier verification protocol (T1 empirical, T2 adversarial, T3 deterministic, T4 user) caught 3 confirmation-bias-style errors during Phase 0a-v2:

- Round-2 chunk-2 `asd_str` false positive (resolved by T3.4).
- Round-1 chunk-2 `peer_L3_cst_ela_z_score` false positive (resolved by T3.4).
- My round-2 chunk-5 prompt's spurious `reg_out_va_sib_acs_dk_tab.do` filename (resolved by T3 ls + grep on round-1 doc).

**Lesson**: the protocol catches errors in BOTH rounds AND in prompt construction. Don't assume any single round/source is authoritative — the T3 deterministic check is the arbiter. **Apply the same discipline in Phase 1 implementation reviews.**

---

## 4. Reference Section

### 4.1 — Per-chunk discrepancy report locations

| Chunk | File |
|---|---|
| 1 — Foundation | `quality_reports/audits/round-2/chunk-1-discrepancies.md` |
| 2 — VA helpers | `quality_reports/audits/round-2/chunk-2-discrepancies.md` |
| 3 — VA core | `quality_reports/audits/round-2/chunk-3-discrepancies.md` |
| 4 — Pass-through + heterogeneity | `quality_reports/audits/round-2/chunk-4-discrepancies.md` |
| 5 — Sibling | `quality_reports/audits/round-2/chunk-5-discrepancies.md` |
| 6 — Survey VA + factor analysis | `quality_reports/audits/round-2/chunk-6-discrepancies.md` |
| 7 — Data prep | `quality_reports/audits/round-2/chunk-7-discrepancies.md` |
| 8 — Samples | `quality_reports/audits/round-2/chunk-8-discrepancies.md` |
| 9 — Share/output helpers + explore | `quality_reports/audits/round-2/chunk-9-discrepancies.md` |
| 10 — Upstream + Python | `quality_reports/audits/round-2/chunk-10-discrepancies.md` |
| Cross-cutting T3 verifications | `quality_reports/audits/round-2/t3-verifications.md` |

### 4.2 — Round-1 archeology

Preserved (sequestered from round-2 agents):

- `quality_reports/audits/round-1/2026-04-25_deep-read-audit.md` — round-1 main consolidated audit (1500+ lines)
- `quality_reports/audits/round-1/2026-04-25_chunk{5,6,7,8,9,10}-*.md` — round-1 per-chunk companion docs
- `quality_reports/audits/round-1/2026-04-25_path-references.md`
- `quality_reports/audits/round-1/2026-04-25_dependency-graph.md`

### 4.3 — Cumulative file inventory

- `cde_va_project_fork/` (Christina's fork): ~150 files audited (do_files/ + py_files/sbac/).
- `caschls/`: ~80 files audited (do/share/, do/build/, do/check/, do/local/, do/upstream/).
- **Out-of-scope**: `_archive/` directories preserved but not audited (already archived 2026-04-25 before Phase 0a).

### 4.4 — Dependencies (cumulative SSC + community packages)

- Stata SSC: `vam`, `reghdfe`, `ivreghdfe`, `estout`/`esttab`/`estpost`, `coefplot`, `palettes`, `cleanplots`, `egenmore`, `regsave`, `cdfplot`, `binscatter`/`binscatter2`, `parmest`, `rangestat`, `texsave`, `mvpatterns`, `descsave`.
- Net (non-SSC): `group_twoway` (Haghish), `geodist`, `opencagegeo`.
- Python: `requests`, `lxml`. Standard library: `csv`, `time`, `re`, `json`, `os`.
- **~17 Stata packages + 2 Python.** Phase 1 settings.do install-block must include all.

### 4.5 — Foundational ADRs (committed)

- ADR-0001: Consolidation scope = cde_va_project_fork (changes_by_che) + caschls (main).
- ADR-0002: Runtime = Scribe only, hostname-branched settings.do.
- ADR-0003: Languages = Stata primary, Python upstream-only (geocoding preserved), R out of scope.

### 4.6 — Pending ADRs for Phase 0e

- ADR-0004: siblingoutxwalk.do canonical location (now unblocked — SAFE to relocate).
- ADR-0005: VA estimator pinning (vam.ado v2.0.1.1 with noseed-fix).
- ADR-0006: external crosswalks vendoring (k12_ccc, k12_csu).
- ADR-0007: column 6 FB row producer fix (`va_spec_fb_tab_all.do`).
- ADR-0008: predicted_score filter discipline.
- ADR-0009: prior-score variant standardization (v1 canonical).
- ADR-0010: DK controls intentionality (single OG baseline vs spec-matched).
- ADR-0011: Filipino/Asian recoding documentation.
- ADR-0012: Sex coding inversion landmine documentation.
- ADR-0013: Sample-restriction map (paper Table A.1) implementation.
- ADR-0014: Naming convention for `_tab.do` mtitles audit.
- ADR-0015: pooledrr renaming convention.
- ADR-0016: Bug 93 family fix template.

---

## 5. Verdict

**Phase 0a-v2 round-2 is COMPLETE.** 10 chunks verified independently with adversarial framing. Total: **85 verified bugs (2 P1 + 14 P2 + 69 P3)** after Christina's 2026-04-26 FB-test correction reclassified 4 findings as NOT-A-BUG. 19 T4 questions for Phase 0e. 5 T1 empirical tests for Christina. 13 ADRs queued for Phase 0e.

**Distance-FB Row 6 mystery RESOLVED**: column 6 of paper Tables 2/3 is the `lasd` (kitchen-sink + distance) column. Distance is INCLUDED IN THE VA SPEC, not used AS A LEAVE-OUT. Spec-test row populated; FB rows correctly blank because `lasd` has no controls left to leave out (structural property of the FB test: `va_controls_for_fb` excludes `lasd` by design per `macros_va_all_samples_controls.doh:66`).

**Bug 93 is bounded and re-prioritized.** 4 instances, all in NSC/merge files. Paper blast radius is null for current paper. Phase 1 still fixes (cheap), but Bug 93 is no longer the headline finding.

**Verification protocol works in BOTH directions.** 3 confirmation-bias errors caught and resolved by T3 (round-2 false positive, round-1 false positive, prompt-construction error). PLUS a 4th-class error caught by Christina herself: round-2 misframed structural FB-test properties as bugs. This last class is what T4 escalation is for — domain expertise the protocol can't supply.

**Round-2 false-positive rate (re-estimated)**: 4 of round-2's findings were FB-structure misreadings. The protocol's adversarial framing made round-2 surface candidate-bugs aggressively; T4 (Christina) is the right adjudicator for "is this actually a bug or just a structural property I don't understand". Lesson: **round-2 should flag structural-FB-test concerns more cautiously OR the prompt should explain FB-test structure upfront.**

**Ready for Phase 0e** (design lock — ADRs 0004-0016 against verified findings; consolidation plan v3) once Christina has time for the remaining 5 T1 empirical tests + Phase 0e Q&A walkthrough.
