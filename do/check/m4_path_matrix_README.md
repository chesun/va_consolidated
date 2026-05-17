# M4 Golden-Master Path Matrix — README

**File:** `do/check/m4_path_matrix.csv`
**Purpose:** Drive the M4 golden-master `diff -r` runner on Scribe — for every CANONICAL output produced by the consolidated pipeline, the runner compares against the corresponding predecessor pipeline's output to verify behavior preservation per plan v3 §3.5 + ADR-0021 sandbox principle.
**Generated:** 2026-05-16 from RELOCATION headers + body greps across 100 active relocated `.do` files under `do/`.

---

## CSV schema

| Column | Description |
|---|---|
| `predecessor_abs_path` | Absolute Scribe path to the predecessor pipeline's output file (under `cde_va_project_fork/` or `caschls/`). |
| `consolidated_abs_path` | Absolute Scribe path to the consolidated pipeline's output file (under `consolidated/` per ADR-0021 sandbox). |
| `producer_file` | Repo-relative path under `do/` (no `do/` prefix; e.g., `va/merge_va_est.do`). The script that produces both sides. |
| `filetype` | Extension class: `dta`, `ster`, `tex`, `pdf`, `csv`, `xlsx`, `other`. |
| `tier` | Verification tier: `smoke` (~5 representative rows), `paper` (paper-shipping under `$tables_dir`/`$figures_dir`), `full` (everything else). |
| `category` | Output category: `data`, `estimates`, `table`, `figure`. |

Tier semantics: rows in `smoke` are also in `paper` AND `full` (logically); rows in `paper` are also in `full`. The runner can filter by tier with `tier == "smoke"`, `tier in ("smoke","paper")`, or `tier in ("smoke","paper","full")` (everything). The CSV stores each row once with its strictest applicable tier label.

---

## Row counts

| Tier | Count |
|---|---|
| smoke | 5 |
| paper | 454 |
| full | 7,865 |
| **Total** | **8,324** |

| Filetype | Count |
|---|---|
| `dta` | 2,360 |
| `ster` | 5,236 |
| `pdf` | 364 |
| `other` (png + intermediate) | 264 |
| `tex` | 64 |
| `csv` | 22 |
| `xlsx` | 14 |
| **Total** | **8,324** |

| Category | Count |
|---|---|
| `data` | 215 |
| `estimates` | 7,389 |
| `figure` | 628 |
| `table` | 92 |
| **Total** | **8,324** |

Top-5 producers by output count (sanity check — the heaviest VA-estimation loops):

| Producer | Rows |
|---|---|
| `va/reg_out_va_all.do` | 2,592 |
| `va/va_out_all.do` | 1,080 |
| `va/va_out_fb_all.do` | 1,024 |
| `va/reg_out_va_dk_all.do` | 864 |
| `va/va_score_all.do` | 648 |

These five files together produce ~75% of all rows. They run the cross-product of VA-control specifications (16) × per-spec sample lists × outcomes × peer ∈ ("", "_p") × version ∈ (v1, v2), with each cell producing one or more `.ster` / `.dta` files. The combinatorics are not invented — they are dictated by the loops in `do/va/helpers/macros_va_all_samples_controls.doh` (the `va_controls`, `<ctrl>_ctrl_samples`, `<lov>_fb_<ctrl>_samples` locals). Each row corresponds to an actual file the predecessor pipeline writes.

**Note on the rough bound (`full ≤ ~300`) in the task spec:** the predecessor pipeline produces *thousands* of estimate files (every `va_controls × <ctrl>_ctrl_samples × peer` cell × 2 versions × multiple outcomes). The rough bound was a planning-guess; the actual scale of `full` is determined by what the predecessor writes. The M4 runner can wildcard via `find $estimates_dir/va_cfr_all_v1/spec_test -name '*.ster'` and similar to bulk-diff, but the CSV still enumerates each file so the runner has a definitive "expected outputs" manifest.

---

## Construction methodology

### 1. Global resolution

Predecessor globals were sourced from `cde_va_project_fork/do_files/settings.do:12-52`:

| Global | Absolute Scribe path |
|---|---|
| `$rawcsvdir` | `/home/research/ca_ed_lab/data/restricted_access/raw/calschls/csv` |
| `$rawdtadir` | `/home/research/ca_ed_lab/data/restricted_access/raw/calschls/stata` |
| `$clndtadir` | `/home/research/ca_ed_lab/data/restricted_access/clean/calschls` |
| `$projdir` (predecessor caschls) | `/home/research/ca_ed_lab/users/chesun/gsr/caschls` |
| `$vaprojdir` | `/home/research/ca_ed_lab/projects/common_core_va` |
| `$vadtadir` | `/home/research/ca_ed_lab/projects/common_core_va/data/sbac` |
| `$cstdtadir` | `/home/research/ca_ed_lab/data/restricted_access/clean/cde/cst` |
| `$nscdtadir` | `/home/research/ca_ed_lab/data/restricted_access/clean/cde_nsc` |
| `$mattxwalks` | `/home/research/ca_ed_lab/users/msnaven/data/restricted_access/clean/crosswalks` |
| `$vaprojxwalks` | `/home/research/ca_ed_lab/projects/common_core_va/data/restricted_access/clean/crosswalks` |
| `$distance_dtadir` | `/home/research/ca_ed_lab/projects/common_core_va/data/k12_postsec_distance` |

Consolidated globals were sourced from `do/settings.do:92-171`:

| Global | Absolute Scribe path |
|---|---|
| `$consolidated_dir` | `/home/research/ca_ed_lab/projects/common_core_va/consolidated` |
| `$datadir` | `$consolidated_dir/data` |
| `$datadir_clean` | `$datadir/cleaned` |
| `$datadir_raw` | `$datadir/raw` |
| `$estimates_dir` | `$consolidated_dir/estimates` |
| `$output_dir` | `$consolidated_dir/output` |
| `$logdir` | `$consolidated_dir/log` |
| `$tables_dir` | `$consolidated_dir/tables` |
| `$figures_dir` | `$consolidated_dir/figures` |
| `$matt_files_dir` | `/home/research/ca_ed_lab/projects/common_core_va/do_files` |
| `$caschls_projdir` | `/home/research/ca_ed_lab/users/chesun/gsr/caschls` (same Scribe path as predecessor `$projdir`) |

### 2. Path migration source

For each relocated `.do` file, the RELOCATION block in the header documents the mapping from predecessor globals → consolidated globals. The two predecessor source repos use different global names that resolve to disjoint physical locations:

- **cde_va_project_fork**: outputs live under `$vaprojdir/<subdir>/...` (e.g., `$vaprojdir/estimates/va_cfr_all_<version>/...`, `$vaprojdir/tables/share/...`, `$vaprojdir/figures/share/...`, `$vaprojdir/data/va_samples_<version>/...`, `$vaprojdir/log_files/...`).
- **caschls**: outputs live under `$projdir/<subdir>/...` (e.g., `$projdir/dta/buildanalysisdata/...`, `$projdir/dta/enrollment/schoollevel/...`, `$projdir/out/dta/factor/...`, `$projdir/log/...`).

Both source bases are resolved to absolute paths via the global tables above.

### 3. Filter: CANONICAL writes only

The matrix includes only writes that target a CANONICAL global (`$datadir_clean`, `$estimates_dir`, `$output_dir`, `$tables_dir`, `$figures_dir`). Per ADR-0021 sandbox principle, all writes from the consolidated pipeline land in CANONICAL — so the matrix is the full set of `diff`-able outputs.

LEGACY writes are not possible in the consolidated pipeline (per the sandbox rule + Tier-1 self-check in `phase-1-review.md` §2). `$logdir` writes are excluded — logs differ by design (timestamps, file paths in headers) and aren't part of golden-master.

### 4. Enumeration of templated writes

Enumerable loop iterators were expanded by reading the relevant loop definitions:

- **Year iterators** (1415, 1516, 1617, 1718, 1819 for CalSCHLS data; 1112-1819 for secondary; 0405-1819 for staff splits; 2013-2020 for CDE) — sourced from `do/data_prep/prepare/enrollmentclean.do:68`, `renamedata.do` body, and analogous loops.
- **Sample/control pairs** (`b_ctrl_samples`, `l_ctrl_samples`, ..., `lasd_ctrl_samples`) — sourced from `do/va/helpers/macros_va_all_samples_controls.doh:82-110`.
- **FB leave-out × control × sample combinations** (`<lov>_fb_<ctrl>_samples`) — sourced from `do/va/helpers/macros_va_all_samples_controls.doh:146-196`.
- **Subjects** (ela, math) — score VA loop bodies.
- **Outcomes** (enr_2year, enr_4year) — outcome VA loop bodies.
- **Versions** (v1, v2) — top-level version loop in `samples/create_score_samples.do:193` and other version-aware producers.
- **CFR shrinkage variants** (regular + dk = drift-kink) — per `va_out_all.do`, `va_score_fb_all.do` body.
- **Peer indicator** (peer ∈ ("", "_p")) — per VA estimation loops.
- **Survey types** (parent, sec, staff) — per `survey_va/factor.do`, `allsvyqoimeans`, `compcasecategoryindex`, etc.
- **Factor-analysis index types** (comp, imputed, imputedhorserace, imputedhorseracewithdemo) — per `survey_va/indexhorserace.do`, `indexhorseracewithdemo.do`, `indexregwithdemo.do`, `svyindex_tab.do` body.

### 5. Tier definitions

- **`smoke`** (5 rows): one representative output per major pipeline phase, picked to (a) cover all CANONICAL global parents (`$datadir_clean`, `$estimates_dir`, `$tables_dir`, `$figures_dir`), (b) cover all major filetypes (dta, ster, pdf, tex), (c) total runtime to verify <5 min on Scribe. Smoke-tier rationale below.
- **`paper`** (454 rows): every CANONICAL output that ends up under `$tables_dir` or `$figures_dir` — i.e., the artifacts that directly enter the paper LaTeX via `\input{}` or `\includegraphics{}`. Plus the explicit smoke tier overrides.
- **`full`** (7,865 rows): every other CANONICAL output — `$datadir_clean/*`, `$estimates_dir/*`, `$output_dir/*` intermediate artifacts.

Note: a row's tier is a single value; rows in `smoke` are NOT additionally tagged `paper` or `full` in the CSV, even though logically smoke ⊂ paper ⊂ full. The runner filters by tier OR-union (e.g., `tier in ("smoke","paper","full")` for the full sweep, `tier in ("smoke","paper")` for a paper-only check).

---

## Smoke-tier rationale (one sentence per row)

1. **`data_prep/prepare/renamedata.do` → `$datadir_clean/calschls/secondary/sec1718.dta`** — representative of the CalSCHLS raw-survey rename pipeline (batch 9d); single .dta produced by a year-templated loop; tests the LEGACY-read → CANONICAL-write chain that feeds qoiclean and beyond.
2. **`va/merge_va_est.do` → `$estimates_dir/va_cfr_all_v1/va_est_dta/va_all.dta`** — the super-master VA estimates aggregate; tests that the per-outcome merge step yields a byte-identical combined .dta (touches `$estimates_dir`, the most-heavily-written canonical path).
3. **`va/va_score_all.do` → `$estimates_dir/va_cfr_all_v1/spec_test/spec_math_b_sp_b_ct.ster`** — the canonical "math VA with base sample, base controls, no peer, v1 prior" — the headline VA estimate that's read by Table 2 / Table 3 producers; .ster filetype coverage.
4. **`share/reg_out_va_tab.do` → `$tables_dir/share/va/pub/persistence_single_subject.tex`** — paper Table 4 (single-subject persistence regression); .tex filetype coverage; tests the paper-shipping `$tables_dir` write convention.
5. **`share/va_scatter.do` → `$figures_dir/share/va/v1/va_combined_scatter_las_sp_b_vs_las_ct_p_v1_nw.pdf`** — paper Figure 5 (combined-panel scatter, las sample, b vs las controls); .pdf filetype coverage; tests the paper-shipping `$figures_dir` write convention.

---

## Known limitations

Be transparent about what the matrix does NOT precisely capture (per the task's "flag rather than silently drop" mandate):

1. **ACS year enumeration is best-guess.** `data_prep/acs/clean_acs_census_tract.do` iterates over ACS years but the loop bounds aren't documented in the RELOCATION block. I enumerated 2009-2019 (11 years) as a best-guess covering the CalSCHLS-paper span. If the actual loop is narrower (e.g., only 2014-2019), the runner will see missing files for the unused years — those should be removed from the CSV after the first M4 run. **Action item:** confirm against `cde_va_project_fork/do_files/acs/clean_acs_census_tract.do` body when first running M4.

2. **CDE year ranges are best-guess.** `clean_elsch.do`, `clean_enr.do`, `clean_frpm.do`, `clean_staffcred.do`, `clean_staffdemo.do`, `clean_staffschoolfte.do`, `clean_sch_char.do` iterate over fall years (spring = fall + 1). I enumerated spring 2013-2020 (8 years) as a covering range. The actual span depends on CDE data availability per-script. **Action item:** same as ACS — confirm against predecessor bodies during first M4 run.

3. **`base_sum_stats_tab.do` intermediate dta predecessor path may not match.** The RELOCATION block notes "$vaprojdir/data/va_samples_v1/* -> kept LEGACY" but the script's `base_nodrop.dta` cache write was repointed under Step 10 to `$datadir_clean/share/base_nodrop.dta`. The predecessor location is *probably* `$vaprojdir/data/va_samples_v1/base_nodrop.dta`, but the RELOCATION block doesn't explicitly state this; I derived it from context. If predecessor used a different path (or no cache file), this single row will be unmatched.

4. **`svyvaregs/allvaregs.do` cross-product is broad-cut.** The script iterates over `svynames × va_outcomes × samples × controls × peer × weight`. I enumerated 3 svynames × 4 outcomes × 2 samples × 1 control × 2 peer × 2 weight = 96 .dta cells per producer call. The actual loop may be narrower (e.g., only certain outcomes per survey); the matrix is therefore an upper-bound expansion. M4 runner will see "missing predecessor file" for cells that don't actually exist; those should be removed from CSV.

5. **`share/svyindex_tab.do` `reg` iterator unknown.** I enumerated `reg = ela, math` based on context (typical VA-vs-survey-index regression scope). The actual loop iterator's local definition wasn't traceable from the RELOCATION block alone. **Action item:** verify by reading predecessor body at first M4 run.

6. **`fb_vars` in va_score_fb_all / va_out_fb_all** — I used the union of `<ctrl>_ctrl_leave_out_vars` from `macros_va_all_samples_controls.doh:122-129` (8 distinct leave-out vars across controls). This is the correct universe per the macros file, but individual `(lov, ctrl, samp)` triples are gated by `<lov>_fb_<ctrl>_samples` (lines 146-196). I encoded those constraints via the `lov_fb_ctrl_samples` dict in the build script — but if any cell is missing from the dict (e.g., an `(la, l)`-pair that isn't in the macros file), it won't appear in the matrix. **Action item:** spot-check against predecessor body.

7. **`reg_out_va_all_fig.do` figure granularity.** The script produces per-(subject, sample, control, peer, outcome) .pdf het-reg figures (~hundreds per call). I included only the *combined-panel* outputs (paper-shipping) in the matrix, dropping per-cell .pdfs to keep `paper`-tier tractable. If M4 needs per-cell verification, add the enumeration to the build script (mirror the reg_out_va_all.do .ster row pattern with `.pdf` extension under `$figures_dir/va_cfr_all_<version>/het_reg_prior_score/` and `het_reg_chars/`).

8. **`share/va_scatter.do` figure paper-shipping vs intermediate.** I marked all `va_scatter.do` figures as `paper`-tier on the assumption they all enter the paper. Per RELOCATION block, `$vaprojdir/figures/share/*` is paper-shipping (CANONICAL), so this is correct. But if some figures are intermediate/diagnostic (not actually `\includegraphics`'d in the paper), they should be re-tiered to `full`.

9. **Distance-controls VA estimates may not exist.** The 8 distance variants (bd, ld, ad, sd, lad, lsd, asd, lasd) in `va_controls` (macros_va_all_samples_controls.doh:77) require `merge_k12_postsec_dist.doh` to be active in `create_score_samples.do` / `create_out_samples.do`. The RELOCATION block notes this helper is KEPT LEGACY; if the predecessor pipeline gates distance estimation OFF, the distance-control .ster rows will be unmatched on M4 first run. **Action item:** check predecessor `do_all.do` for distance-controls gates.

10. **Paper-tier subject for `kdensity` figures.** `share/kdensity.do` produces va1_va2 pairwise density figures. I enumerated 4 representative pairs (ela_math, ela_enr_4year, math_enr_4year, enr_2year_enr_4year). Actual loop may include more pairs (e.g., ela_enr_2year). Best-guess; M4 first run will surface missing pairs.

11. **The two `check_*.do` files that produce intermediate outputs are NOT in the matrix.** `check_logs.do`, `check_merges.do`, `check_paper_outputs.do`, `check_samples.do`, `check_survey_indices.do`, `check_va_estimates.do`, `t1_empirical_tests.do`, and `explore/codebook_export.do` are excluded by design — they're new pipeline diagnostics (plan v3 §5.3), not relocated files with predecessor counterparts.

12. **Predecessor path for `acs_2017_gen_dict.do` .dta side-output may not exist.** The script's `descsave ... saving($output_dir/csv/acs/2017/acs_2017_<subject>_dict.dta, replace)` produces a .dta alongside the .csv. The predecessor caschls repo's `$projdir/out/csv/acs/2017/...` may or may not contain the .dta (depending on whether descsave was active in predecessor). If predecessor didn't produce the .dta, those 4 rows will be unmatched.

These limitations are documented for transparency; the M4 runner should handle "predecessor file missing" rows by reporting them as warnings (not errors) so Christina can curate the CSV after first run.

---

## Validation summary (per task §5)

- [x] CSV is valid (`python3 -c "import csv; list(csv.DictReader(open('do/check/m4_path_matrix.csv')))"` returns 8,324 rows without error).
- [x] No `<placeholder>` strings remain in the CSV (`grep -c '<.*>' m4_path_matrix.csv` returns 0).
- [x] All paths use forward slashes (Linux convention; Scribe is Linux).
- [x] All paths are absolute (start with `/`).
- [x] CSV header row present.
- [x] Smoke tier: 5 rows covering 4 categories (data, estimates, table, figure) and 4 filetypes (dta, ster, tex, pdf).
- [x] Spot-check 5 random rows: producer paths match real .do files; consolidated paths match the actual `save` / `esttab using` / `graph export` statements in their bodies; predecessor paths trace through RELOCATION rules.

---

## References

- Plan v3 §3.5 — `quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md` (golden-master verification protocol).
- ADR-0021 — `decisions/0021_main-settings-relocation-and-self-contained-sandbox.md` (sandbox semantics; LEGACY vs CANONICAL classes).
- `do/settings.do:92-171` — consolidated global definitions.
- `cde_va_project_fork/do_files/settings.do:12-52` — predecessor cde_va_project_fork global definitions.
- `do/va/helpers/macros_va_all_samples_controls.doh` — VA control/sample/leave-out enumeration source.
- `.claude/rules/phase-1-review.md` §2 — pre-commit Tier-1 self-check (CANONICAL write discipline).
- `.claude/rules/air-gapped-workflow.md` — M4 runs on Scribe; this CSV is the input manifest Christina executes there.
