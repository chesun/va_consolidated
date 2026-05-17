# Air-Gapped Server Workflow

**Paths:** `**/*.do`, `**/*.doh`

## When This Applies
Project data/code lives on a restricted server Claude cannot access (e.g., TERC, FSRDC).

## Constraints
- Claude CANNOT see raw data or run code
- Claude CAN work with: variable names, summary stats, codebooks, exported .do files, log files

## What IS OK to Export

Derived summaries are NOT air-gapped. The line is between **raw or row-level restricted data** (air-gapped) and **derived summaries / paper-class content** (exportable). The following are explicitly safe to export from the restricted server:

- **Regression estimates** — coefficients, standard errors, t-stats, p-values, confidence intervals, F-stats. Paper content.
- **Summary statistics** — means, medians, SDs, quantiles, min/max, percentiles. Paper content.
- **Counts** — sample sizes (N), cell counts, merge rates, missingness counts, cluster counts, number-of-differences from `cf`/`cfout`, line-diff counts from `diff`. Counts are summary stats.
- **Derived diff magnitudes** — coefficient deltas (`max|db|`), SE deltas (`max|dSE|`), tolerance comparisons. Paper-class content; the kind of number that goes in a tolerance row of a table.
- **Table contents** — anything that would land in a paper table. `.tex` fragments produced for inclusion in the manuscript are by definition exportable.
- **Figure outputs** — `.pdf`/`.png` files the paper includes. Embedded in the manuscript.
- **Log file content** — `.smcl`/`.log` files from analysis runs. Contains code echoes, command outputs, diagnostic messages, derived numbers. Not raw row-level data.
- **Codebook excerpts** — variable definitions, ranges, value labels.

## What IS Air-Gapped

These categories should never be exported or printed/logged in clear:

- **Raw row-level data** — individual records from `.dta` files (e.g., a specific student's gender + test score + outcomes). Never `list` to log; never `export` from the server.
- **Identifiers or personally-linkable variables** — student IDs, school IDs at sensitive granularity, identifier crosswalks, address-level fields.
- **Small-cell tabulations** — cells where N is small enough to be reidentifying (typically < 10 per project convention; check institutional rules).
- **Restricted-access metadata** — anything the data-use agreement names as confidential.

When in doubt, ask: is this derived from data (exportable) or the row-level data itself (air-gapped)? Counts, magnitudes, and estimates are derived.

## What Claude Does
- Review exported .do files for logic errors and best practices
- Generate new code with explicit assumptions documented
- Design replication package structure
- Format tables and figures from shared output

## Defensive Code Rules
1. Add assertions: `assert _N > 0`, `assert !missing(key_var)`
2. Document assumptions: `// ASSUMPTION: merge keys are string type`
3. Flag version deps: `// REQUIRES: reghdfe with absorb() syntax`
4. Include diagnostics: `// DIAGNOSTIC: share this output with Claude`

## Communication Protocol
1. Ask for: variable names, data dimensions, summary stats, codebook
2. Write code with assumptions documented
3. User runs on server, shares output/errors
4. Claude iterates based on output
