# Stata Code Conventions

**Paths:** `**/*.do`, `**/*.doh`

## Version
- Server may use Stata 18 with older package versions — flag compatibility concerns

## Project Structure
- **Master file:** `do/main.do` (per ADR-0021) — runs all do files via `do do/<subdir>/<file>.do`. CWD at runtime is `$consolidated_dir`.
- **Settings:** `do/settings.do` (per ADR-0021) — globals for paths, machine-specific via `c(hostname)` branching. Loaded by main.do via `include do/settings.do`.
- **Helpers:** `.doh` extension — included via `include` (preserves local macros)
- **Naming:** `01_clean.do`, `02_analysis.do`, `03_figures.do` (numbered order)
- **Subdirs under `do/`:** `data_prep/`, `samples/`, `va/`, `survey_va/`, `share/`, `sibling_xwalk/`, `check/`, `debug/`, `explore/`, `local/`, `upstream/`, `_archive/`

## Description Convention (per ADR-0021)
Every do file under `do/` (excluding `_archive/`) has both:
1. **Header description block** at the top — PURPOSE / INVOKED FROM / CONVENTIONS / REFERENCES (mirror the existing `do/settings.do` and `do/main.do` style). The header is the authoritative longer description of what the file does.
2. **A one-liner inline next to its `do do/<path>/<file>.do` invocation in `do/main.do`** — `do do/<path>/<file>.do    // <one-liner>`. Names the script's role at a glance.

Both are checked by coder-critic on every Phase 1 relocation per `phase-1-review.md` §3.

## Sandbox Write Discipline (per ADR-0021)
The `consolidated/` folder is a self-contained output sandbox. Every `save`, `export`, `outsheet`, `esttab using`, `graph export`, `outreg2 using`, `texsave`, etc. in any do file under `do/` MUST target a path under `$consolidated_dir` — i.e., one of the CANONICAL globals defined in `do/settings.do` (`$consolidated_dir`, `$datadir`, `$datadir_clean`, `$datadir_raw`, `$logdir`, `$estimates_dir`, `$output_dir`, plus `$consolidated_dir/tables/` and `$consolidated_dir/figures/`).

LEGACY globals (`$matt_files_dir`, `$vaprojdir`, `$vaprojxwalks`, `$caschls_projdir`, `$nscdtadir`, `$nscdtadir_oldformat`, `$mattxwalks`) are READ-ONLY. Writing to a LEGACY path breaks the `diff -r consolidated/output predecessor/output` comparability that the consolidation enables.

Per-commit self-check (per `phase-1-review.md` Tier 1): run `grep -nE 'save|export|esttab using|graph export|outsheet|outreg2 using|texsave'` on each relocated file; verify each match targets a CANONICAL global.

## Required Packages
reghdfe, estout, coefplot, ivreghdfe, palettes, cleanplots, egenmore, regsave, cdfplot, binscatter, binscatter2

When new package used: save `[LEARN:stata] New package: name — purpose` to MEMORY.md.

## Code Style
- `local` for within-file constants; `global` only in settings.do
- `cap log close _all` and `set more off` at top of master
- `preserve`/`restore` for temporary manipulation; `tempfile` for intermediates
- `set seed` once in main.do (reproducibility)
- `log using` for every analysis do file
- Never overwrite raw data

## Table Export
- `texsave` for manual tables; `esttab`/`estout` for regression tables
- Output to both local folder AND Overleaf directory
- Format: `tostring var, force format(%10.3f) replace`
- Stars: manual `replace coef=coef+"*" if pval<.05` or esttab options

## Figures
- `graph export` with `.pdf` and `.png`
- Color palette in `.doh` file; opacity locals: `opmax`, `ophigh`, `opmed`, `oplow`
- `binscatter`/`binscatter2` for binned scatter plots

## Regression
- `reghdfe` for OLS with high-dimensional FE
- `ivreghdfe` for IV with high-dimensional FE
- `regsave` for saving results to datasets
- Cluster SEs at appropriate level (document why)
