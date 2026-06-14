# Stata Code Conventions

**Paths:** `**/*.do`, `**/*.doh`

## Version
- Server may use Stata 18 with older package versions — flag compatibility concerns

## Invocation (server — Scribe)
- **`stata-mp` is the canonical server command. Always `stata-mp`; NEVER `stata -b`.** Batch runs: `stata-mp -b do do/main.do` from `$consolidated_dir`. This is the only supported runtime for the pipeline (per ADR-0002). Any doc, comment, or instruction that gives a Scribe run command must use `stata-mp -b ...`, not `stata -b ...`. [Christina, 2026-06-13]

## Invocation (local machine)
- **Always invoke as `stata17` from the command line** — `stata17 -b do file.do` for batch runs.
- **Never call binaries inside `/Applications/Stata/StataMP.app/...` directly.** That path is the older Stata MP 14 install on this machine; both versions ship a binary literally named `StataMP` / `stata-mp` inside their respective `.app` bundles, so a direct path call to `/Applications/Stata/...` silently picks Stata 14.
- `stata17` is the version-pinned alias on PATH (typically `~/.local/bin/stata17 → ~/Documents/stata/StataMP.app/Contents/MacOS/stata-mp`). The unqualified `stata-mp` resolves to the same binary on this machine but is ambiguous in principle; prefer `stata17`.
- See `.claude/skills/stata/SKILL.md` for full Stata reference, including documentation lookup, language essentials, and common pitfalls.

## Project Structure
- **Master file:** `mainscript.do` or `main.do` — runs all do files via `do ./do/filename.do`
- **Settings:** `settings.do` — globals for paths, machine-specific via `c(hostname)` branching
- **Helpers:** `.doh` extension — included via `include` (preserves local macros)
- **Naming:** `01_clean.do`, `02_analysis.do`, `03_figures.do` (numbered order)
- **Subdirs:** `clean/`, `share/`, `learn/`, `helpers/`

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

## Wildcards in comments (per 2026-05-17 sweep)

Inside any Stata comment context — `/* ... */` block, `*`-prefixed line, or `//`-prefixed line — do **not** use `*` as a path-glob wildcard. Use `<x>` (or `<file>`, `<filename>`) as the placeholder.

The character sequence `/*` is reserved for legitimate block-comment opens. Stata's parser counts `/*` opens greedily and treats them as state transitions regardless of context — including inside an existing `/* ... */` block, inside a `//` line comment, and inside a `*`-prefixed line comment. An extra `/*` from a path-glob like `prepare/*` inside a header description creates a runaway nested block comment that silently swallows large portions of the file.

| Before (bug pattern) | After (fixed) |
|---|---|
| `$logdir/*` | `$logdir/<x>` |
| `prepare/*` | `prepare/<x>` |
| `do/**/*.do` | `do/<x>/<x>.do` |
| `$datadir_clean/calschls/{a,b}/*` | `$datadir_clean/calschls/{a,b}/<x>` |

The fix tool (one-time): `py/sweep_comments_and_logdirs.py` ran across the active tree on 2026-05-17 and applied the rewrite mechanically. Going forward, the rule applies to every new `.do` / `.doh` file. The commit-time check in `.claude/rules/phase-1-review.md` §2 Tier-1 enforces it via `grep -c '/\*'` vs `grep -c '\*/'` per file.

See `quality_reports/plans/2026-05-17_comment-bug-sweep.md` v3 for the bug analysis and the rationale for Option B (path-glob `*` placeholder) over Option A (header-block restructure).

## Per-file logging structure (per 2026-05-17 sweep)

Each `.do` file under `do/<reldir>/<name>.do` writes its log to `$logdir/<reldir>/<name>.smcl` — i.e., the log directory mirrors the do/ directory structure.

Required boilerplate:

```stata
* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/<first-level-parent>"
cap mkdir "$logdir/<first-level-parent>/<second-level-parent>"
...                                              // one mkdir per intermediate path component
log using "$logdir/<reldir>/<name>.smcl", replace text
...
cap log close
cap translate "$logdir/<reldir>/<name>.smcl" "$logdir/<reldir>/<name>.log", replace
```

Top-level files (`do/main.do`, `do/settings.do`) are exempt: `main.do` opens a timestamped master log; `settings.do` is `include`'d and doesn't open its own log.

`do/check/check_logs.do` walks the structure and asserts every active `.do` file under `do/` (excluding `do/_archive/`) produced a matching log. The walker computes the expected log path from the file's relative directory under `do/`.

The commit-time check in `.claude/rules/phase-1-review.md` §2 Tier-1 enforces the log-path convention.
