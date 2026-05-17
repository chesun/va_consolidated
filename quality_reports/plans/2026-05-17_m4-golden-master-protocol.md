# M4 Golden-Master Verification Protocol

**Status:** Active
**Author:** orchestrator (with data-engineer path-matrix + coder diff-runner)
**Created:** 2026-05-17
**Operator:** Christina (runs on Scribe; air-gapped per `.claude/rules/air-gapped-workflow.md`)

---

## What this is

The M4 test asks: **does the consolidated pipeline (`do/main.do`) produce the same outputs as the two predecessor pipelines (`cde_va_project_fork/do_files/do_all.do` + `caschls/do/master.do`)?** Per plan v3 §3.5 and ADR-0018, this is the **first gate before `v1.0-final` tag** — a behavior-preserving consolidation must produce byte-identical (or numerically-equivalent within tolerance) outputs.

The infrastructure for the test:

| Artifact | Purpose |
|---|---|
| `do/check/m4_path_matrix.csv` | 8,324 rows mapping every consolidated CANONICAL output to its predecessor counterpart. |
| `do/check/m4_path_matrix_README.md` | Schema, construction methodology, smoke-tier rationale, known limitations (12 items). |
| `do/check/m4_golden_master.do` | Stata runner. Reads the matrix, iterates pairs, compares per filetype with replication-protocol tolerances, writes a small text summary. |
| `$output_dir/m4_diff_summary.txt` | The single exportable artifact. Contains per-pair PASS/FAIL + magnitude per row. |

Tolerance source: `.claude/rules/replication-protocol.md` §3 — integers exact, point estimates ≤ 0.01, SEs ≤ 0.05, percentages ≤ 0.1pp.

---

## Prerequisites

Before starting, confirm:

- [ ] Local repo is in sync with origin (`git status` clean; `git log -1` matches `origin/main`).
- [ ] Latest M4 infrastructure commit is on Scribe (push first, then pull on Scribe; or use your preferred file-transfer per ADR-0020).
- [ ] Predecessor pipeline outputs exist on Scribe — they live wherever `cde_va_project_fork/do_files/do_all.do` + `caschls/do/master.do` last wrote them. If they're stale, re-run the predecessor pipelines first (per plan v3 §3.5 step 1). If you trust the most recent outputs as the paper-reference, skip the re-run.
- [ ] `$consolidated_dir` exists on Scribe at `/home/research/ca_ed_lab/projects/common_core_va/consolidated/` and the `do/`, `data/`, `estimates/`, `tables/`, `figures/`, `output/`, `log/` subdirectories are writable.
- [ ] Stata (17 or 18) installed on Scribe with `cf` built-in. Optional packages probed via `command -v` with fallback: `cfout` (community-contrib SSC; improves `.dta` diff granularity if present), `pdftotext` (poppler-utils; enables `.pdf` text-extraction fallback if PDFs aren't byte-identical).

---

## Procedure

### Tier 1 — Smoke (~5 minutes)

Catches catastrophic breakage (settings.do load failure, wrong path resolution, Stata-startup error) before committing to multi-hour runs.

```bash
# On Scribe
cd /home/research/ca_ed_lab/projects/common_core_va/consolidated

# Confirm tier-selector is set to "smoke" at line 380 of m4_golden_master.do:
grep -n 'tier_filter' do/check/m4_golden_master.do
# Expect: 380:    local tier_filter = "smoke"    // CHANGE ME ...

stata -b do do/check/m4_golden_master.do
```

Runtime: <5 min. The runner compares 5 representative pairs (one per major pipeline phase / filetype). Output: `$output_dir/m4_diff_summary.txt`.

**Expected at smoke**: 5 rows in the summary, all PASS. If anything fails, **STOP** — investigate before paper-tier.

### Tier 2 — Paper (~30-60 minutes, est.)

Verifies every output that ends up in `$tables_dir` or `$figures_dir` — the artifacts that directly enter the paper LaTeX. 454 rows.

```bash
# On Scribe
# Edit do/check/m4_golden_master.do line 380:
#   local tier_filter = "paper"    // CHANGE ME
# Then:
stata -b do do/check/m4_golden_master.do
```

Runtime: ~30-60 min (estimate; first run will calibrate). Output overwrites the smoke summary at `$output_dir/m4_diff_summary.txt`.

**Expected at paper**: 454 rows, most PASS. Any FAIL is a paper-shipping behavior divergence — investigate per "When a row FAILs" below before full-tier.

### Tier 3 — Full (multi-hour)

Verifies all 8,324 outputs. Estimates are 5,236 .ster files + 2,360 .dta files + figures + tables. Stata `cf` is the bottleneck (per-file overhead × 7,596 numeric-file comparisons).

```bash
# On Scribe
# Edit line 380:
#   local tier_filter = "full"    // CHANGE ME
# Then:
stata -b do do/check/m4_golden_master.do
```

Runtime: multi-hour (estimate 4-8 hours). Run during a low-load window. Use `screen` or `nohup` if your SSH session might disconnect.

**Expected at full**: 8,324 rows. Some MISSING_PREDECESSOR is acceptable for outputs the predecessor doesn't write (e.g., distance-controls VA may be gated OFF in predecessor — see m4_path_matrix_README.md "Known limitations" §1-12). FAILs are real divergences; investigate.

---

## Export and review

After each tier:

```bash
# On Scribe — confirm summary exists:
ls -la $output_dir/m4_diff_summary.txt
# (where $output_dir resolves to /home/.../consolidated/output)

# Pull the summary to your local machine via FileZilla / scp / your preferred transfer.
# This is the ONLY file you export. The .log file at $logdir/m4_golden_master.log
# stays on Scribe (it contains the same diagnostic info plus the raw display output).
```

The summary file is plain text. Each row:

```
<STATUS>  <tier>  <filetype>  <consolidated_relpath>  <details>
```

`STATUS` values:
- `PASS` — bit-equal or within tolerance.
- `FAIL` — within-tolerance comparison failed; magnitude in `details`.
- `MISSING_PREDECESSOR` — predecessor file doesn't exist on Scribe.
- `MISSING_CONSOLIDATED` — consolidated file doesn't exist (pipeline didn't produce it; investigate).
- `READ_ERROR` — Stata couldn't read one or both files; see log for cause.
- `FAIL_VISUAL` — .pdf differs even after text-extraction; needs offline visual review.
- `FAIL_BINARY` — non-PDF binary differs; offline review.
- `SKIP` — comparison skipped (e.g., unknown filetype).

Tally at the end of the file:

```
--- SUMMARY ---
PASS: 8200  FAIL: 5  MISSING_PRED: 100  MISSING_CONS: 0  READ_ERROR: 19  ...
TIER: full
RUNTIME: 47 minutes
```

---

## When a row FAILs

For each FAIL row in the summary:

1. **Inspect the details column.** For `.ster` rows, the magnitude (`max|db|=0.034`) tells you how far off the tolerance you are. A coefficient delta of 0.005 is rounding noise; a delta of 0.5 is a real divergence.
2. **Check the producer file.** The row's `consolidated_relpath` reverse-maps to a producer via `grep <relpath> do/check/m4_path_matrix.csv`. Open the producer .do file in the consolidated repo. Check its RELOCATION header for what changed in relocation.
3. **Cross-reference with chain coordination.** The 2026-05-16 pre-flight audit caught 3 Critical chain regressions of this exact class (producer relocated to CANONICAL, consumer still reads LEGACY). If the FAIL output depends on inputs from other relocated files, check whether one of those inputs is stale.
4. **Compare consolidated log to predecessor log on Scribe** (both stay on Scribe; not exported). If runtime behavior differs, the log will show why (different sample count, different N, different missingness handling).

If the FAIL is a tolerance violation but the magnitude is paper-irrelevant (e.g., a coefficient differs by 1e-8 due to Stata version skew), document the rationale and accept. The replication-protocol tolerances are floors, not ceilings.

If the FAIL is a real behavior divergence, dispatch coder for fix per `phase-1-review.md` §3 dispatch matrix; route through coder-critic.

---

## Escalation triggers

Stop and ask before proceeding past:

- **Smoke tier reports any FAIL or READ_ERROR.** Smoke is supposed to be obviously-PASS; if it doesn't pass, there's a systemic issue (settings.do, path resolution, Stata version, predecessor outputs missing).
- **Paper tier reports >5% FAIL.** A 5% failure rate (~23 rows) suggests a systematic divergence, not isolated bugs. Investigate before full-tier.
- **Full tier reports >1% FAIL** (~83 rows). Same logic — systemic issue.
- **Any MISSING_CONSOLIDATED.** The consolidated pipeline should produce every row in the matrix. A missing consolidated output means a write was skipped — could be a main.do wiring bug or a relocated file that's no longer reachable.

If escalation is needed, paste the relevant rows from `m4_diff_summary.txt` into a session log and dispatch coder-critic on the affected producer files.

---

## Known limitations (carried forward from m4_path_matrix_README.md)

The 12 items the data-engineer flagged when building the matrix:

1. ACS year enumeration is best-guess (2009-2019 assumed).
2. CDE year enumeration is best-guess (2013-2020 assumed).
3. `share/svyvaregs/allvaregs.do` cross-product upper-bound (96 cells; actual may be narrower).
4. Distance-controls VA estimates (8 distance variants) may be gated OFF in predecessor.
5. `acs_2017_gen_dict.do` .dta side-output (from descsave) — predecessor may not have produced.
6-12. (Per m4_path_matrix_README.md "Known limitations" §1-12; check that file for details.)

These items appear as MISSING_PREDECESSOR in the summary. **They are not bugs in the consolidated pipeline** — they're scope-of-the-matrix items where the CSV included a row the predecessor didn't actually produce. After the first M4 run, the matrix can be trimmed of confirmed-non-existent predecessor rows.

---

## Round-2 critic deferred items

The coder-critic round-2 review (`quality_reports/reviews/2026-05-16_m4-infrastructure-round2_coder_review.md`) deferred 5 improvements to post-smoke iteration:

| ID | Issue | Action after smoke |
|---|---|---|
| M1 | `.ster` element-wise compare doesn't verify column-name alignment | Add `colnames(b1) == colnames(b2)` guard |
| M2 | `cf` row-count mismatch (`r(503)`) misclassified as READ_ERROR not FAIL | Reclassify in the dispatch |
| M5 | PDF byte-strict text diff fails on timestamp differences | Add date/time strip before text diff |
| Mi1 | Smoke tier doesn't exercise csv/xlsx filetypes | Promote one csv to smoke |
| Mi2 | Both-missing case bucketed as MISSING_PREDECESSOR | Distinct MISSING_BOTH status |

Address these only if smoke surfaces them. Otherwise defer to Phase 1c §5.4 polish.

---

## Cross-references

- Plan v3 §3.5: `quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md`
- ADR-0018 acceptance criteria: `decisions/0018_offboarding-model-refinement.md`
- ADR-0021 sandbox-write discipline: `decisions/0021_main-settings-relocation-and-self-contained-sandbox.md`
- Replication-protocol tolerances: `.claude/rules/replication-protocol.md` §3
- Air-gapped workflow (updated 2026-05-17): `.claude/rules/air-gapped-workflow.md`
- Round-1 coder-critic review (M3-misapplied; superseded): `quality_reports/reviews/2026-05-16_m4-infrastructure_coder_review.md`
- Round-2 coder-critic review (PASS 85/100): `quality_reports/reviews/2026-05-16_m4-infrastructure-round2_coder_review.md`
- Pre-flight audit synthesis: `quality_reports/reviews/2026-05-16_pre-flight-SYNTHESIS_M4-go-no-go.md`
