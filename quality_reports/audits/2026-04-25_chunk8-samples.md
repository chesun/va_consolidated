# Chunk 8 Deep-Read Report — Samples (sample construction, pooling, response rates, demographics, coverage)

**Source repos**: `cde_va_project_fork` and `caschls`. Agent: general-purpose; report received 2026-04-25.

## File inventory

25 files audited:

- `cde_va_project_fork/do_files/sbac/`: `touse_va.do`, `create_score_samples.do`, `create_out_samples.do`
- `caschls/do/build/buildanalysisdata/poolingdata/`: `mergegr11enr.do`, `parentpooling.do`, `secpooling.do`, `staffpooling.do`
- `caschls/do/build/buildanalysisdata/responserate/`: `parentresponserate.do`, `secresponserate.do`, `trimparentdemo.do`, `trimsecdemo.do`
- `caschls/do/build/sample/`: `elemcoveragedata.do`, `elemdemographics.do`, `parentcoveragedata.do`, `parentdemographics.do`, `pooledparentdemographics.do`, `pooledparentdiagnostics.do`, `pooledsecdemographics.do`, `pooledsecdiagnostics.do`, `seccoveragedata.do`, `secdemographics.do`, `responseyear.do` (extra discovery)
- `caschls/do/share/demographics/`: `elemcoverageanalysis.do`, `parentcoverageanalysis.do`, `pooledsecanalysis.do`, `seccoverageanalysis.do`

Per-file detail content trimmed to highlights here; the full chunk 8 agent report is captured in audit-trail commits below.

---

## Critical finding — `_archive/matt_original/sum_stats.do` IS STILL LOAD-BEARING

**The authoritative source for paper Online Appendix Table A.1 (`tables/share/va/pub/counts_k12.tex`) is `_archive/matt_original/sum_stats.do` (1215 lines)**, which post-hoc re-derives the count cascade. Matched producer file: `_archive/matt_original/sum_stats_tab.do` formats the .tex output via `esttab`.

We archived this file in commit `85a97e7` (`archive: move 21 Matt-original VA do-files to _archive/matt_original/`) based on the user's direction that Matt-originals were superseded by `va_score_all.do` / `va_out_all.do`. But:

1. `sum_stats.do` produces a **different artifact** (the Table A.1 sample-counts cascade), not a VA estimate.
2. The `do do_files/sbac/sum_stats.do` references in `do_all.do` were already **commented-out before our archival** — meaning Table A.1 hasn't been re-derived from this code in some time.
3. The paper map flags `counts_k12.tex` as a load-bearing input (paper Table A.1).

**This means**:

- Either the paper's `counts_k12.tex` is stale (last produced when the commented-out block was active)
- Or the user reproduces it manually some other way
- Or it's a separate ad-hoc invocation outside the master pipelines

**Action item** flagged for user: confirm whether `counts_k12.tex` is currently stale, and decide whether `sum_stats.do` + `sum_stats_tab.do` should move out of `_archive/matt_original/` back into the active pipeline (or to a new `do/share/` location for paper-output formatting). For now, the file remains in archive.

---

## Final sample-restriction map (paper Table A.1 ↔ code)

The 9 rows of Table A.1 (ELA branch — math symmetric) are produced by `_archive/matt_original/sum_stats.do` L215-460:

| Table A.1 row | Code restriction (cumulative) | Source line |
|---|---|---|
| 1. All grade-11 students | `grade==11 & all_students_sample==1` | L218-228 |
| 2. School-level (grade-span) | `+ diff_school_prop>=0.95 & !mi(diff_school_prop)` | L230-243 |
| 3. First scores | `+ first_scores_sample==1` | L257-269 |
| 4. Conventional schools | `+ mi_ssid_grade_year_school==0 & conventional_school==1` | L286-302 |
| 5. **Cohort size > 10** | `+ cohort_size>10 & !mi(cohort_size)` | L305-322 |
| 6. Non-missing test score | `+ mi_sbac_<subject>_z_score==0` | L326-344 |
| 7. Non-missing demographic controls | `+ mi_demographic_controls==0` | L348-368 |
| 8. Non-missing prior test scores | `+ mi_prior_ela_z_score==0 & mi_prior_math_z_score==0` | L372-394 |
| 9. **School VA sample size ≥ 7** | `+ n_g11_<subject>>=7 & !mi(n_g11_<subject>)` | L425-452 |

### "≥7 vs ≤10" question definitively RESOLVED

**Both cuts exist and are different**:

- **Row 5** (cohort-size cut): `cohort_size > 10` — at the school × test × year level; drops schools with `cohort_size <= 10` (CBEDS school-level cohort metric). Implemented in `touse_va.do:109`.
- **Row 9** (per-cell cut): `n_g11_<subject> >= 7` — at the school × year × subject × analysis-cell level; counts students contributing to a VA cell after all controls non-missing. Implemented in `touse_va.do:155, 180`.

Both restrictions are real. The chunk-2 confusion was conflating them. Internal consistency: confirmed.

`counts_k12.tex` is built by `sum_stats_tab.do:145` from 9 saved `.ster` estimates files. Uses `esttab ... booktabs nonotes noobs nomtitles nonumbers ... fragment` — bare tabular fragment, paper-side wraps with `\begin{table}` per `tables.md`.

---

## `gr11enr_mean` weight consumption trace

- **Generated** upstream (chunk 7) in school-level `poolgr11enr.dta`.
- **Merged** onto `parentanalysisready`, `secanalysisready`, `staffanalysisready` by `mergegr11enr.do` (this chunk).
- **Consumed** as `[aweight=gr11enr_mean]` (the `_wt` token from chunk 7) in every survey-on-VA second-stage regression in `do_files/share/`.
- **`mergegr11enr.do` is the single bottleneck merge** that "promotes" `staffpooledstats` to `staffanalysisready` (no other step does this for staff).

---

## Survey pooling logic (parent/sec/staff)

| Survey | QOI items pooled | Schema-divergence handling | Output |
|---|---|---|---|
| Parent | 9, 15-17, 27, 30-34, 64 | 1415 missing qoi 64 → wtmean ignores missings | `parentpooledstats` → response-rate merge → `parentanalysisready` |
| Secondary | 22-40 (split: 22-34 Likert, 35-40 true-style) | None needed (all 5 years have 22-40) | `secpooledstats` → `secanalysisready` |
| Staff | 10, 20, 24, 41, 44, 64, 87, 98, 103-105, 109, 111, 112, 128 | 1718/1819 missing `pctnotapp` → wtmean ignores missings | `staffpooledstats` (no response-rate file; promoted later by mergegr11enr.do) |

Common pattern: 5-year `append`, then `by cdscode: egen <var>_pooled = wtmean(<var>), weight(nettotalresp<i>)`, then `collapse (mean) *pooled (sum) <count_vars> missing*, by(cdscode)`. Output is school-level (one row per cdscode), not school-year level.

---

## Response-rate semantics

- **Definition**: `pooledrr = (sum of svygr<i>_<year> across i,year where school had any response) / (sum of enrgr<i>_<year> across i,year where school had any response)`. Two grade-restricted variants: `pooledrr_gr9and11` for the headline grade-9+11 rate.
- **Used as**: covariate / weight candidate, **NOT a sample restriction**. No `keep if pooledrr > X` filter found.
- **TWO parallel definitions of `pooledrr` exist**:
  - `parentresponserate.do` builds it over all `has<year>=1` years
  - `pooledparentdiagnostics.do` builds a different `pooledrr` (sum-collapse over the 5-year panel)
  - Same name, different semantics. Naming clash.
- **`trimparentdemo.do` / `trimsecdemo.do`**: Just keep `(cdscode, svygr*, gr*enr)` and rename to `<var>_<year>` suffix. NO statistical trimming despite the name — these are projection helpers.

---

## Anomalies / bugs (17+ items, partial list)

| File | Line | Issue | Severity |
|---|---|---|---|
| `touse_va.do` | 104-107 | "Exclude schools where >25% receive special ed", "drop home/hospital instruction" stub comments — never coded | Med — paper mentions but unenforced |
| `create_score_samples.do` | 240-247 | `egen n_g11_<subject>_<sample>_sp` computed but never `save`d — labels claim it's persisted | **High — silent dead-code** |
| `create_out_samples.do` | 225-232 | Same egen-not-saved bug for outcomes | **High** |
| `create_out_samples.do` | 71 | `enr_ontime → enr` rename overrides original `enr` semantics silently | Med |
| `parentdemographics.do` | 13 | 1415 missing grade-7 obs (`-8` code, 1327 obs) silently dropped | **High** — affects pooled grade-7 stats |
| `pooledsecdemographics.do` | 23-24 | `gr<9|11>asianenr += filipinoenr` overwrites in-place — substantive demographic recoding without ADR | Med |
| `pooledsecanalysis.do` | 31-43 | Silent `drop if check<race>==1` data-quality filter applied only at graph time | Med |
| `secdemographics.do` | 102 vs `elemdemographics.do:67` | Sex coding inverts between elem (1=F) and sec (1=M) — landmine | Low — documented |
| `secdemographics.do` | 59 | 1718/1819 trans/nb/questioning gender option not handled — dropped from sex-stratified counts | Med |
| Various `*coveragedata.do` | many | `label define <varname>` instead of `label define <labname>` + `label values` — labels orphaned | Low |
| `pooledparentdiagnostics.do` vs `parentresponserate.do` | both | Two distinct definitions of `pooledrr` with the same name | Med |
| `parentpooling.do` | 49 | `(sum) dontknow*` summed across years vs `(mean) *pooled` constant; inconsistent collapse semantics | Low |

---

## New naming tokens / packages (additions to chunks 1-7 catalog)

**Tokens**: `touse_g11_<subject|outcome>`, `n_g11_<...>`, sample fan-out `score_<flag>` / `out_<flag>` (where flag ∈ b/l/a/s/la/ls/as/las), version path `va_samples_v1/`, `<var>_pooled` family (mean/pct{agree,disagree,neither,dontknow,well,okay,notwell,true,nottrue,yes,no,smallprob,bigprob}<i>_pooled), `nettotalresp<i>`, `gr11enr_mean`, sex/race-stratified `svy<demo>gr<i>` / `enr<demo>gr<j>` / `pct` / `dif` forms, `pooledrr` family (overall / `gr9and11` / `gr<i>` / `<sex|race>`), `has<year>` / `has<year><survey>`, file-suffix forms `analysisready` / `pooledstats` / `forpooling` / `paneldata` / `responseyear`.

**Packages**: `_gwtmean` (provides `wtmean` egen extension; commented `ssc install` in staffpooling/secpooling).

---

## Open questions for user (Chunk 8)

| # | Question | Affects |
|---|---|---|
| Q8.1 | **Is `counts_k12.tex` (paper Table A.1) currently stale?** Should `sum_stats.do` + `sum_stats_tab.do` move out of `_archive/matt_original/`? | Paper Table A.1 reproducibility |
| Q8.2 | Does Table A.1 paper text caption need to disambiguate `≤10 cohort` (Row 5) vs `<7 per-cell` (Row 9)? | Paper text clarity |
| Q8.3 | The grade-7 1415 silent drop (`gr=−8` code, 1327 obs) — flag pooled grade-7 stats or exclude? | Pooled grade-7 statistics |
| Q8.4 | Trans/nb/questioning gender code in 1718/1819 sec — drop or include in sex-stratified counts? | Section 2 representativeness |
| Q8.5 | Silent `drop if check<race>==1` filter in `pooledsecanalysis.do` — promote to data-quality assertion? | Reproducibility |
| Q8.6 | Two `pooledrr` definitions — rename one or document explicitly? | Risk of consuming wrong one |
| Q8.7 | The `gr<9|11>asianenr += filipinoenr` recoding — needs ADR if it survives consolidation. | Methodology documentation |

## Open questions for chunks 9-10

- Is `pooledrr` ever used as a sample-restriction filter (`keep if pooledrr >= X`)? Chunk 9 should resolve.
- The paper text claim about ">25% special ed" filter — is it in chunk 9 (a wrapper script applies it) or is the paper text a stub?
- The `n_g11_<subject>_<sample>_sp` weights — if not persisted by `create_score_samples.do`, where does scatter-plot weighting actually come from? Chunk 9.
- ADR-worthy: the `gr<9|11>asianenr += filipinoenr` recoding decision.
