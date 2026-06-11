# Code Audit — m4_spotcheck_triage.do (M4 golden-master triage spot-checks)
**Date:** 2026-06-11
**Reviewer:** coder-critic
**Target:** do/debug/m4_spotcheck_triage.do
**Score:** 97/100
**Status:** Active
**Mode:** Full (Phase 1c dispatch; new one-off READ-ONLY diagnostic; hard gate 80/100)

## Code-Strategy Alignment: MATCH

Implements exactly the three spot-checks from `quality_reports/reviews/2026-06-10_m4-full-golden-master_triage.md` § "Spot-check commands": Section 1 = `e(N)` (+ `e(N_clust)`) on one FAILing `.ster` pair per cluster (sib1 / las / la, mapped to ADR-0026/ADR-0028 hypotheses in labels); Section 2 = obs count + varlist set-diff on 2 representative rc=9 pairs + 3 rc=900 pairs under `set maxvar 32767`, with conditional `cf` on the common varlist when `_N` matches. No scope creep; never wired into `do/main.do`.

## Sanity Checks: PASS
## Robustness: Complete (N/A — diagnostic, no estimation)

## Path Fabrication Audit (dispatch concern #1, highest priority): PASS — all 9 literals verified verbatim

Every predecessor/consolidated path constructed by the script matches a row of `do/check/m4_path_matrix.csv` exactly (col 1 = predecessor, col 2 = consolidated), including all three predecessor roots:

| Script local(s) | Constructed path(s) | CSV row | Match |
|---|---|---|---|
| `ster_1` (script:46) | `…/common_core_va/estimates/va_cfr_all_v1/spec_test/spec_math_s_sp_sib1_ct.ster` (pred + cons) | 4797 | VERBATIM both cols |
| `ster_2` (script:48) | `…/va_cfr_all_v1/reg_out_va/reg_enr_2year_va_ela_las_sp_ad_ct_p_m.ster` | 4956 | VERBATIM both cols |
| `ster_3` (script:50) | `…/va_cfr_all_v1/spec_test/spec_ela_la_sp_lad_ct.ster` | 1640 | VERBATIM both cols |
| `pred_1`/`cons_1` (script:84-85) | `…/common_core_va/data/va_samples_v1/score_b.dta` → `…/consolidated/data/cleaned/va_samples_v1/score_b.dta` | 159 | VERBATIM |
| `pred_2`/`cons_2` (script:88-89) | `…/va_cfr_all_v1/va_est_dta/va_all.dta` (both sides) | 1506 | VERBATIM |
| `pred_3`/`cons_3` (script:92-93) | `…/users/chesun/gsr/caschls/dta/buildanalysisdata/analysisready/staffanalysisready.dta` → `…/consolidated/data/cleaned/calschls/analysisready/staffanalysisready.dta` | 27 | VERBATIM |
| `pred_4`/`cons_4` (script:96-97) | `parentanalysisready.dta` pair | 25 | VERBATIM |
| `pred_5`/`cons_5` (script:100-101) | `secanalysisready.dta` pair | 26 | VERBATIM |
| `pred_6`/`cons_6` (script:104-105) | `…/data/restricted_access/clean/calschls/secondary/sec1617.dta` → `…/consolidated/data/cleaned/calschls/secondary/sec1617.dta` | 52 | VERBATIM |

Section 1 relpaths are identical on both sides; CSV rows 4797/4956/1640 confirm cons = pred-root + `/consolidated` + same relpath, matching the script's `pred_root`/`cons_root` construction (script:42-43). Per dispatch, the hardcoded absolute paths are intentional (predecessor repo, copied from the matrix) — no deduction; the header discloses the derivation source (script:16-17), satisfying derive-dont-guess.

## Stata Mechanics (dispatch concern #2): PASS

- **Nested-local idiom** `` `pred_`i'' `` / `` `ster_`i'' `` is correct (inner expands first); header carries an explicit `derive-ok` note (script:18-20).
- **forvalues bounds:** Section 1 `1/3` against defined `ster_1..3`/`lab_1..3`; Section 2 `1/`npairs'` with `npairs=6` against defined `pred/cons/lab_1..6`. `lab_1..3` reuse occurs only after Section 1 has finished — safe ordering.
- **`set maxvar 32767` placement** (script:26): after `clear all`, before `include do/settings.do`. Verified `do/settings.do` contains no `clear all` / `set maxvar` (grep: 0 matches), so the raised limit survives the include.
- **`: list` set operators on wide varlists:** under `maxvar 32767` the rc=900 files imply >5,000 vars; `r(varlist)` at ~7,000 names × ~20 chars ≈ 140K chars is far below the Stata MP macro-length ceiling. `: list` is O(n²) — slow but feasible for a one-off; informational only.
- **`cond(e(N_clust) < ., e(N_clust), .)`** (script:63, 69): correct missing-safe handling — when `e(N_clust)` is unset the condition is false and `.` is returned.
- **Missing-safe display arithmetic:** `Np`/`Nc` initialized to `.` (script:55-58); a failed load yields `delta=.` rather than a syntax error.

## rc-Clobber Discipline (dispatch concern #3): PASS

`capture noisily cf` (script:151) is followed immediately by `di … _rc` (script:152) — no intervening `cap` command, so the displayed rc is the cf return code. The `if _rc` branches after each `capture use` / `capture estimates use` (script:60, 66, 114, 124) likewise read `_rc` immediately. This is the bug class fixed in `2026-06-09_check-files-rc-fix_coder_review.md`; not repeated here.

## cf Semantics (dispatch concern #4): PASS

`cf` runs only when `` `Np' == `Nc' `` and the common varlist is non-empty (script:148); predecessor is reloaded as master before `cf … using` (script:150-151), satisfying cf's master-in-memory + equal-`_N` requirements. The sort-order caveat is documented in a comment (script:146-147).

## Logging Conventions (dispatch concern #5): PASS

- Log path mirrors do/ structure: `do/debug/<name>.do` → `$logdir/debug/m4_spotcheck_triage.smcl` (script:33). `$logdir` defined at `do/settings.do:99`.
- `cap mkdir "$logdir"` + `cap mkdir "$logdir/debug"` — one mkdir per path level (script:30-31).
- Named log (`name(m4_spotcheck)`), defensive `cap log close m4_spotcheck` before open and at end, `cap translate` smcl→log at end (script:32-33, 161-162) — matches the 2026-05-17 named-log sweep pattern.
- **Comment-wildcard balance:** `/*` count = 1, `*/` count = 1 (single header block); no path-glob `*` inside any comment context (CSV reference comments at script:17, 81 are glob-free); no `//*****` banners; no Variant-8 artifacts.

## Scope / Read-Only (dispatch concern #6): PASS

Data-touching commands are exclusively `estimates use`, `use`, `ds`, `cf`, `di` — no `save`/`export`/`outsheet`/`esttab`/`graph export`. Only writes are the script's own log + translate. Header accurately states purpose, standalone invocation from repo root (`stata -b do do/debug/m4_spotcheck_triage.do`, consistent with the relative `include do/settings.do`), NOT-called-by-main.do, path provenance, and references — ADR-0021 header conventions satisfied.

## Code Quality (10 categories)

| Category | Status | Issues |
|----------|--------|--------|
| Script structure & headers | OK | Full ADR-0021 header block |
| Console output hygiene | OK | `di as text/result/error`, `{hline}` section banners — Stata-idiomatic |
| Reproducibility | OK | No randomness (no seed needed); settings.do include for `$logdir`; intentional matrix-sourced absolute paths |
| Function/program design | OK | Linear one-off; locals only — appropriate |
| Figure quality | N/A | No figures |
| Output persistence | OK | Log + translate only — correct for a READ-ONLY diagnostic (regsave/save would violate scope) |
| Comment quality | OK | Comments explain WHY (sort-order caveat, maxvar rationale, derive-ok note); no dead code |
| Comment safety (10b) | OK | 1/1 balance; no glob-in-comment; no banner noise |
| Error handling | WARN | Minor finding F1 below |
| Professional polish | OK | Consistent indent, aligned locals, lines < 100 chars |

## Findings

**F1 (Minor, -3) — unchecked `capture use` re-load before cf (script:150).** The predecessor re-load ahead of `cf` is `capture`d but its `_rc` is never checked. If that re-load failed, the consolidated dataset (loaded at script:123) would still be in memory and `cf` would compare the consolidated file against itself, reporting a spurious `rc=0` ("all common-var values identical") — a silent false-PASS, this project's most sensitive bug class. Risk is near-zero (the same path loaded successfully ~35 lines earlier in the same iteration), hence Minor, but add an `if _rc { di as error …; continue }` guard for symmetry with script:114 and 124.

**Informational (no deduction):**
- `: list` O(n²) and full varlist-diff display on ~7,000-var files will be slow and log-heavy; acceptable for a one-off triage where the full name lists are the deliverable.
- `log using` omits the `text` option shown in the `stata-code-conventions.md` boilerplate; the smcl-then-translate form used here is the substantive convention applied tree-wide by the 2026-05-17 named-log sweep — treated as conforming.

## Compliance Evidence (from .claude/state/verification-ledger.md)

- `do/debug/m4_spotcheck_triage.do` | (any check) | NO ROWS — file is newly authored for this dispatch; no no-logic-change claim is in force (new script, not a refactor), so the Tier-1 recorder gate does not apply. No compliance claims appear in the header beyond the path-provenance citation, which this review independently verified against `do/check/m4_path_matrix.csv` (rows 25, 26, 27, 52, 159, 1506, 1640, 4797, 4956).
- Comment balance verified directly this session: `/*` = 1, `*/` = 1 (Grep counts; Bash/`stata_sweep.py` unavailable in this critic's toolset — disclosed, residual risk negligible for a 163-line single-header file).

## Tier-2 verdict evidence

- claim: "All 9 path pairs in the script match the path matrix verbatim" | artifact_citation: `do/check/m4_path_matrix.csv:25-27,52,159,1506,1640,4797,4956` + `do/debug/m4_spotcheck_triage.do:42-106` | sufficiency: each constructed literal was string-compared against the cited CSV row's columns 1-2 in-session; RESOLVED.
- claim: "Script is read-only" | artifact_citation: `do/debug/m4_spotcheck_triage.do:24-162` | sufficiency: exhaustive command scan of the full 163-line file shows no data-writing command; only log/translate writes.

## Score Breakdown

- Starting: 100
- F1: unchecked `capture` re-load before cf (silent false-PASS path) — Minor, error handling: -3
- **Final: 97/100 — PASS (gate 80)**

## Escalation Status: None
