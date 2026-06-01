# mkdir-coverage Discovery Report

**Date:** 2026-05-31
**Tool:** `py/sweep_mkdir_coverage.py` (static discovery; loop-literal-expansion matcher + block-comment stripping)
**Status:** Active
**Verification caveat:** static discovery only — "gap" = a write whose target dir (incl. loop-var levels) has no covering `cap mkdir` in the same file, after resolving `foreach v in <literals>` expansions. The next Scribe run is the only pass/fail.

## Result

- **15 distinct (file × missing-dir) gaps across 14 files** (100 write-sites).
- **0 LEGACY-path gaps** (the 6 initial LEGACY flags were all inside `/* */` header comments → false positives, now suppressed).
- False-positive suppression: loop-literal expansion (`foreach version in v1 v2` → mkdir of `.../v1/...`+`.../v2/...` counts as covered) cut 210→100 write-sites; this correctly cleared the already-fixed `reg_out_va_all_fig.do`/`reg_out_va_dk_all_fig.do` and the genuinely-covered `va_score_all.do` etc.

## The 15 gaps (all CANONICAL — fix = add `cap mkdir`)

| # | File | Missing dir | Kind | Sites |
|---|------|-------------|------|-------|
| 1 | `do/share/base_sum_stats_tab.do` | `$estimates_dir/va_cfr_all_v1/sum_stats` | static | 12 |
| 2 | `do/share/sample_counts_tab.do` | `$estimates_dir/va_cfr_all_v1/sum_stats` | static | 24 |
| 3 | `do/share/siblingxwalk/uniquefamily.do` | `$output_dir/graph/siblingxwalk` | static | 1 |
| 4 | `do/share/outcomesumstats/nsc2019new/k12_nsc2019_merge.doh` | `$datadir_clean/outcomesumstats` (+`$logdir`) | static | 2 |
| 5 | `do/share/demographics/elemcoverageanalysis.do` | `$output_dir/graph/svycoverage/elemcoverage/elem`​`` `i' `` | LOOPVAR | 3 |
| 6 | `do/share/demographics/parentcoverageanalysis.do` | `.../parentcoverage/parent`​`` `year' `` | LOOPVAR | 1 |
| 7 | `do/share/demographics/seccoverageanalysis.do` | `.../seccoverage/sec`​`` `year' ``​`/gr`​`` `i' `` | LOOPVAR (2 levels) | 10 |
| 8 | `do/share/kdensity.do` | `$figures_dir/share/va/`​`` `version' `` | LOOPVAR | 1 |
| 9 | `do/share/va_scatter.do` | `$figures_dir/share/va/`​`` `version' `` | LOOPVAR | 34 |
| 10 | `do/share/reg_out_va_tab.do` | `$estimates_dir/va_cfr_all_`​`` `version' ``​`/reg_out_va` | LOOPVAR | 2 |
| 11 | `do/share/va_var_explain.do` | `$estimates_dir/va_cfr_all_`​`` `version' ``​`/reg_out_va` | LOOPVAR | 6 |
| 12 | `do/survey_va/indexregwithdemo.do` | `$estimates_dir/survey_va/factor/indexbivarwithdemo/`​`` `type' `` | LOOPVAR | 1 |
| 13 | `do/survey_va/indexhorseracewithdemo.do` | `$estimates_dir/survey_va/factor/indexhorsewithdemo/`​`` `type' `` | LOOPVAR | 1 |
| 14 | `do/va/va_sib_lag_spec_fb_tab.do` | `$tables_dir/va_cfr_all_`​`` `version' ``​`/spec_test` | LOOPVAR | 1 |
| 15 | `do/va/va_sib_lag_spec_fb_tab.do` | `$tables_dir/va_cfr_all_`​`` `version' ``​`/fb_test` | LOOPVAR | 1 |

## Fix protocol (per adversarial review 2026-05-31)

- **static** → add `cap mkdir`, one per level (parent→child), to the top-of-file `* --- output-directory prep (CANONICAL) ---` block. base_sum_stats / sample_counts also need the parent levels `$estimates_dir`, `$estimates_dir/va_cfr_all_v1` if absent.
- **LOOPVAR** → add `cap mkdir ".../`​`` `var' ``​`"` **inside** the loop that binds the var, after any `use`/`merge`, before the first write. **Nested (seccoverageanalysis)**: mkdir the `sec`​`` `year' `` level in the `year` loop AND the `sec`​`` `year' ``​`/gr`​`` `i' `` level in the `i` loop (each level needs its own mkdir; parent before child). Model: `allvaregs.do:89-91`.
- **`.doh` (k12_nsc2019_merge.doh)** → it's an included fragment; verify whether the dir should be created in the fragment or its caller(s). If the fragment writes, it should mkdir (it can't assume caller did).
- **`#delimit ;` check**: scan ±10 lines of each insertion; if inside an active `;`-region, the `cap mkdir` line needs a trailing `;`.
- **`*/`-glob safety**: never put a literal `` `x'/ `` or `*/` inside a `//` or `/* */` comment on the added lines.
- Preserve `/* */` balance per file (grep -c check after).

## Re-verify

After fixes: `python3 py/sweep_mkdir_coverage.py --check` must exit 0. Then ledger rows per file.
