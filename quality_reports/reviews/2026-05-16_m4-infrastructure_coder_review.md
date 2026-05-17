# M4 Golden-Master Infrastructure Review — coder-critic
**Date:** 2026-05-16
**Reviewer:** coder-critic
**Target:** `do/check/m4_golden_master.do` + `do/check/m4_path_matrix.csv` + `do/check/m4_path_matrix_README.md`
**Score:** 82/100
**Status:** Superseded by quality_reports/reviews/2026-05-16_m4-infrastructure-round2_coder_review.md

---

## Verdict

**PASS at the 80/100 hard gate, but with caveats.** Five items below should be addressed before the first Scribe smoke run. None are show-stoppers; the smoke tier (5 rows, ~5 min runtime) will surface execution-time issues that static review cannot, and the script's defensive structure (per-row `capture`, distinct status codes, graceful degradation when `cfout`/`pdftotext` unavailable) means individual bugs won't kill the loop. Recommend: run smoke tier on Scribe FIRST; iterate on any execution-time findings; THEN run paper tier. Do not jump straight to full tier.

## Compliance evidence

Consulted `.claude/state/verification-ledger.md`. **No prior ledger rows exist for `do/check/m4_golden_master.do` or `do/check/m4_path_matrix.csv`** (grep returned 0 matches). Both files are new in this session — verification cost is born on first review (acceptable per `adversarial-default.md` § "Cost analysis"). New ledger rows can be appended after this review:

```
do/check/m4_golden_master.do | no-hardcoded-paths     | 2026-05-16T... | <hash> | PASS    | grep returned 0 matches for /Users|/home|C:\\ literals; all paths via $consolidated_dir / $logdir / $output_dir
do/check/m4_golden_master.do | adr-0021-sandbox-write | 2026-05-16T... | <hash> | PASS    | writes: $logdir/m4_golden_master.{smcl,log} + $output_dir/m4_diff_summary.txt; all CANONICAL
do/check/m4_golden_master.do | header-description     | 2026-05-16T... | <hash> | PASS    | PURPOSE / INVOKED FROM / INPUTS / OUTPUTS / ROLE / ORIGIN / TOLERANCES / DISPATCH / TIER SELECTOR / ASSUMED PACKAGES / DEFENSIVE CODE / REFERENCES present (lines 1-96, exceeds the check_logs.do precedent)
do/check/m4_golden_master.do | no-main-invocation     | 2026-05-16T... | <hash> | PASS    | header line 16-20 explicitly states "NOT wired into do/main.do — one-shot"
do/check/m4_path_matrix.csv  | schema-matches-readme  | 2026-05-16T... | <hash> | PASS    | header row = README schema verbatim; 8324 data rows = README total
do/check/m4_path_matrix.csv  | tier-counts            | 2026-05-16T... | <hash> | PASS    | grep ',smoke,' = 5; ',paper,' = 454; ',full,' = 7865; sum = 8324 = README total
```

## Findings — by severity

### CRITICAL — none

### MAJOR (5)

**M1. `e(b)` / `e(V)` element-wise compare does not verify column names.**
File: `do/check/m4_golden_master.do:216-220`. After loading both `.ster` files, `cap_compare_ster` checks `colsof(b1) == colsof(b2)` but never checks `colnames(b1) == colnames(b2)`. If a regressor was renamed between predecessor and consolidated (e.g., `frpm_share` → `pct_frpm`), the element-wise `b1[1,k] - b2[1,k]` compares apples to oranges and returns spurious tiny diffs (or no diffs, by chance) — the script reports PASS for a coefficient set that is actually mis-aligned. This is the canonical pitfall when comparing saved estimates from re-run regressions.

Deduction: **-5** (major; missing semantic check; replication-protocol §3 implicitly requires this).
Recommended fix: After `matrix b1 = e(b)` and `matrix b2 = e(b)`, capture and compare colname vectors. If colnames diverge but colsof matches, log details = "colname-mismatch despite same K" and mark FAIL.

**M2. `cf` row-count mismatch (`r(503)`) is classified as `READ_ERROR`.**
File: `do/check/m4_golden_master.do:130-134`. The capture-then-check-_rc pattern conflates two distinct conditions: (a) the file is truly unreadable (Stata format error, permission, etc.) and (b) the two files have different `_N` (Stata's `cf` errors with rc=503 "observations do not match"). The data-engineer's README §"Known limitations" notes loop-bound mismatches will produce row-count diffs; those rows should classify as `FAIL` (the files DO differ — meaningfully), not `READ_ERROR` (a non-comparison condition). Misclassification will inflate the READ_ERROR tally and Christina will spend time investigating "file format issues" that are actually behavior diffs.

Deduction: **-5** (major; status-code semantics are load-bearing for the summary tally).
Recommended fix: Branch on `_rc == 503` → FAIL with details "row-count mismatch: pred=<N1> cons=<N2>"; only treat other `_rc` codes as READ_ERROR. Stata returns r(_N) and r(N1) values in the cf output area when accessible; if not, fall back to a `count` after `use` on each.

**M3. `.ster` diff magnitudes leak into the air-gapped export.**
File: `do/check/m4_golden_master.do:250, 255`. The summary file `$output_dir/m4_diff_summary.txt` is the ONLY exportable artifact per the air-gapped-workflow rule. For .ster FAIL rows, the `details` column contains `max|db|=<value> max|dSE|=<value>` — these are derived numeric quantities (max absolute coefficient diff and max absolute SE diff) computed from estimates fit to restricted-access data. Per `.claude/rules/air-gapped-workflow.md`, "raw data never leaves Scribe"; whether bounded diff magnitudes (≤0.01 in the PASS case) count as "raw data" is a judgment call. Currently the header (lines 12-14) implies only PASS/FAIL/MISSING status is exported; it does NOT explicitly say "diff magnitudes are sanctioned to leave."

Deduction: **-3** (major; air-gapped-rule clarity).
Recommended fix: Either (a) drop the `max|db|` / `max|dSE|` numeric values from the FAIL details (replace with status code only — "FAIL: above tolerance"), OR (b) add a paragraph to the header explicitly sanctioning the export of bounded diff magnitudes with the rationale that they're "metadata about model fit, not data values." Option (a) is safer; option (b) requires Christina's explicit sign-off given the air-gapped rule.

**M4. README claims tier counts match exactly; review verifies they do — but the README's count table includes `paper` = 454 AND a separate `paper` count under "Tier definitions" that says "454 rows" while implying it ⊃ smoke.**
File: `do/check/m4_path_matrix_README.md:28-31` (Row counts table) vs `:140` ("rows in smoke are NOT additionally tagged paper or full in the CSV"). The CSV stores each row once with its strictest tier label; the README's count table reflects that single-label storage (`smoke=5, paper=454, full=7865, total=8324`). The script's tier-filter at line 442-446 implements OR-union ("paper" → keep tier in {smoke, paper}). So a `tier_filter = "paper"` run will process 5+454 = 459 rows, not 454. The header at line 68 says `~459 rows`. The README §"Row counts" says `454` for paper without clarifying this is the strict-label count. **No bug — the counts are consistent with the storage convention** — but a casual reader checking "did paper-tier match 454?" against the script's run output of 459 will be confused.

Deduction: **-2** (major; documentation ambiguity that propagates to operator confusion).
Recommended fix: Add a clarifying note under "Row counts" in the README: "These are *strict-label* counts. The runner's `paper`-tier filter processes 5 (smoke) + 454 (paper) = 459 rows; `full`-tier filter processes all 8,324."

**M5. `pdftotext` text-stream compare on PDF differences is byte-strict.**
File: `do/check/m4_golden_master.do:336-343`. After pdftotext extraction, the fallback diff is `cmp -s` byte-compare. PDFs containing dates ("Generated 2026-05-16") or build-host stamps will produce text-streams that differ only in those benign lines. The current path marks them as `FAIL_VISUAL` even when the substantive content is identical. The script's `cap_compare_tex` subroutine already has a numeric-strip + diff pattern for tex; the same heuristic (or a date-strip heuristic) would help here.

Deduction: **-2** (major; will inflate FAIL_VISUAL count on first paper-tier run when paper PDFs include build dates).
Recommended fix: After `pdftotext`, run a small `awk` filter to strip ISO dates / "Generated on ..." / known boilerplate lines BEFORE the `cmp -s`. Or accept the FAIL_VISUAL category as "needs manual offline review" and document that boilerplate-date diffs are expected.

### MINOR (3)

**Mi1. Smoke tier missing `csv` and `xlsx` coverage.**
File: `do/check/m4_path_matrix.csv` smoke rows (lines 53, 477, 688, 1506, 1676). The 5 smoke rows cover {dta, ster, tex, pdf} and {data, estimates, table, figure}. They do NOT cover the `csv` (22 rows) or `xlsx` (14 rows) filetypes, so a smoke run will not exercise the `cap_compare_bytes` dispatcher for those. If `cap_compare_bytes` has a bug, it surfaces only at paper or full tier — at which point a non-trivial number of rows are already in flight.

Deduction: **-1** (minor; smoke is meant to flush out dispatch logic).
Recommended fix: Add a 6th smoke row for csv (one of the `acs_2017_S0601_dict.csv` files would do) and a 7th for xlsx if there is a representative one. Alternatively, the smoke tier could be 7 rows covering all 7 filetypes — still <10 min runtime.

**Mi2. The two-file-missing case is classified as MISSING_PREDECESSOR.**
File: `do/check/m4_golden_master.do:549-552`. When neither side exists, status="MISSING_PREDECESSOR" and `n_missing_pred++`. The details say "neither side exists; cons=<path>" which is accurate but the tally bucket muddles two scenarios: "predecessor was supposed to produce this, but didn't" vs "neither pipeline produced this (probably a phantom row in the CSV)." Differentiating helps Christina cull phantom CSV rows after first run.

Deduction: **-1** (minor; tally hygiene).
Recommended fix: Add a `MISSING_BOTH` status with its own counter.

**Mi3. CSV re-load per row (8324 reads on full tier).**
File: `do/check/m4_golden_master.do:514-517`. Every iteration re-loads `matrix_snapshot` because subroutines `use` the predecessor .dta and clobber the in-memory CSV. For full tier (7865 rows), this is 7865 disk reads. On a fast SSD this is sub-second per read, so the loop overhead is bounded — but a `frame put` (Stata 16+) pattern would avoid the re-read entirely and shave likely 30 min off the full-tier run.

Deduction: **0** (performance, not correctness; acceptable for one-shot use).
Recommended fix: Consider rewriting the loop to use `frame copy` if Scribe Stata is 16+; otherwise accept the I/O.

## Per-deliverable summary

### `do/check/m4_golden_master.do` (663 LOC)

| Check | Status | Evidence |
|---|---|---|
| Header description block (ADR-0021) | PASS | Lines 1-96 cover all required + optional sections; mirrors check_logs.do |
| No hardcoded paths | PASS | All file refs via globals; visual scan + grep clean |
| Sandbox writes (ADR-0021) | PASS | Writes only to `$logdir/m4_golden_master.{smcl,log}` + `$output_dir/m4_diff_summary.txt` |
| `set more off` + `cap log close _all` | PASS | Lines 100-101 |
| `log using` + `translate` at end | PASS | Lines 105 + 660-661 |
| Defensive code (per-row `capture`) | PASS | Every subroutine wraps file ops in `capture`; loop continues on errors |
| Status enumeration | PASS | 9 distinct statuses per header line 86 |
| Pre-flight validation | PASS | Path matrix existence (397-403), tier_filter validity (406-411), zero-row guard (452-457) |
| Optional-package probing | PASS | `cfout` (414-421) and `pdftotext` (424-431) probed; graceful fallback |
| Progress reporting | PASS | Every 100 rows + first + last (lines 533-537) |
| `.dta` compare via `cf` | PARTIAL (M2) | Returns Nsum; row-count mismatch misclassified as READ_ERROR |
| `.ster` compare via e(b)/e(V) | PARTIAL (M1) | Element-wise compare without colname check |
| `.tex` compare via cmp + awk-strip-diff | PASS (depends on shell escape on Scribe) | Numeric-strip heuristic is reasonable |
| `.pdf` compare via cmp + pdftotext | PARTIAL (M5) | No boilerplate-strip on pdftotext stream |
| `.csv` `.xlsx` `.other` byte-compare | PASS | `cap_compare_bytes` dispatcher; smoke coverage gap noted in Mi1 |
| Air-gapped summary export hygiene | PARTIAL (M3) | Diff magnitudes leak in FAIL details |
| Tally block | PASS | All 9 counters + tier + runtime + row count |
| `local ++X` syntax | PASS | Stata 13+ supported on Scribe per stata-code-conventions.md |

### `do/check/m4_path_matrix.csv` (8324 data rows + 1 header)

| Check | Status | Evidence |
|---|---|---|
| Header schema matches README §"CSV schema" | PASS | `predecessor_abs_path,consolidated_abs_path,producer_file,filetype,tier,category` |
| Tier counts (README → actual) | PASS | smoke: 5 (claimed 5), paper: 454 (claimed 454), full: 7865 (claimed 7865); sum = 8324 |
| Path roots — spot-check N=10 random rows (lines 1, 5, 53, 477, 688, 1506, 1676, 2000, 5000, 8324) | PASS | All predecessors under `/home/research/ca_ed_lab/projects/common_core_va/` or `/home/research/ca_ed_lab/users/chesun/gsr/caschls/`; all consolidated under `/home/research/ca_ed_lab/projects/common_core_va/consolidated/` |
| Smoke tier coverage (filetypes + categories) | PARTIAL (Mi1) | Covers 4 filetypes (dta, ster, tex, pdf) + 4 categories; csv + xlsx + other not in smoke |
| All paths absolute | PASS | All begin with `/` |
| No placeholder strings (`<...>`) | PASS (README validation §188-194) | Verified |
| `filetype` values valid | PASS | Visible values: dta, ster, tex, pdf, csv, xlsx, other (per README counts) |

### `do/check/m4_path_matrix_README.md` (207 lines)

| Check | Status | Evidence |
|---|---|---|
| Schema documented matches CSV header | PASS | Lines 11-19 match line 1 of CSV |
| Tier counts match CSV grep counts | PASS | 5 + 454 + 7865 = 8324 |
| 12 known limitations honest + detailed | PASS | Lines 156-180; each item names a specific risk + action |
| Smoke-tier rationale present | PASS | Lines 144-150, one sentence per row, covers all 4 represented categories |
| Construction methodology traceable | PASS | Lines 68-141; cites `cde_va_project_fork/do_files/settings.do:12-52`, `do/settings.do:92-171`, `do/va/helpers/macros_va_all_samples_controls.doh`, etc. |
| Validation summary | PASS | Lines 188-194 |
| References | PASS | Lines 200-206 |
| Strict-label vs OR-union count ambiguity | PARTIAL (M4) | Row counts table at line 28-31 doesn't reconcile with paper-tier filter producing 459 rows |

## Score breakdown

| Item | Deduction |
|---|---|
| Starting score | 100 |
| M1 — .ster colname not checked | -5 |
| M2 — cf row-count mismatch misclassified | -5 |
| M3 — diff magnitudes in air-gapped export | -3 |
| M4 — README tier-count ambiguity | -2 |
| M5 — pdftotext stream byte-strict | -2 |
| Mi1 — smoke missing csv/xlsx | -1 |
| Mi2 — MISSING_BOTH bucketed as MISSING_PREDECESSOR | -1 |
| Mi3 — performance (CSV re-read per row) | 0 (advisory) |
| **Final** | **82/100** |

## Verdict and execution recommendation

**PASS — clears the 80/100 hard gate.** Recommend the following operator sequence on Scribe:

1. **Address M3 (air-gapped magnitudes) before any run.** Quickest fix: strip the `max|db|` / `max|dSE|` numeric values from FAIL `details`; replace with "FAIL: above tolerance (point or SE)." This keeps the air-gapped rule clean. Two-line edit at lines 250 and 255.
2. **Run smoke tier (`local tier_filter = "smoke"`).** Verify the 5 rows complete without errors; review the summary file format; confirm exportability.
3. **Address M1, M2, M5 after smoke.** These manifest at paper/full tier (estimates + pdf compares); fixing after smoke avoids over-engineering for cases that may not occur.
4. **Add Mi1 csv row to smoke.** Quick edit to CSV: change one `acs_2017_S0601_dict.csv` row's tier from `full` → `smoke`. Re-run smoke.
5. **Run paper tier (~459 rows).** Expect ~30 min runtime. Review summary, fix any new findings.
6. **Run full tier (~8324 rows).** Multi-hour run on Scribe.

If Christina decides to defer M3 and proceed with smoke (the FAIL details only appear if a row actually fails), that is also acceptable provided smoke is the first run and Christina manually reviews the summary file before exporting it.

## Three Strikes status

**Strike 0 / 3.** Round 1 review; no prior round. Score above 80 → no escalation triggered.

## Notes for follow-up

- The CSV's 12 known limitations are the most likely source of paper/full-tier `MISSING_PREDECESSOR` rows. Christina should expect 50-200 of these on first run and use them to curate the CSV (per the data-engineer's design intent).
- The script does not attempt `.png` comparison — covered by `cap_compare_bytes` as `other`. Visual-equivalence of figures is genuinely hard; byte-compare + manual review is the right tradeoff.
- No deductions for derive-don't-guess: every external entity (`$consolidated_dir`, `$logdir`, `$output_dir`, the matrix CSV path) is sourced from `do/settings.do` (lines 92, 99, 98) — verified.
- No deductions for primary-source-first: no external paper citations in the new files.
