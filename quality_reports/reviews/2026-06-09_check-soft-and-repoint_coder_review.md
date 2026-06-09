# Check Soft + Re-point Review — coder-critic

**Date:** 2026-06-09
**Reviewer:** coder-critic
**Target:** `do/check/check_va_estimates.do` (Change A, ADR-0028) + `do/check/check_survey_indices.do` (Change B, ADR-0027)
**Score:** 94/100 (PASS; hard gate 80)
**Status:** Active

> Review returned inline by the critic (its sandbox blocked report-file writes); transcribed here verbatim-in-substance by the orchestrating session. The post-review header doc-fidelity + ledger-hygiene fixes recommended below were applied 2026-06-09 (see §Recommendations).

## Verdict

Both changes are correct, minimal, ADR-faithful, and Tier-1 clean. Two documentation-hygiene Minors (−3 each), no behavioral defects. PASS at 94/100.

- **Code-strategy alignment:** MATCH. Both changes implement exactly what ADR-0027 / ADR-0028 prescribe; the ADRs' code-trace line refs verified accurate against source.
- **Robustness:** both e968d13 Phase-7 FAILs addressed.

## Verification (all 5 tasks confirmed)

1. **Change A non-halting; hard asserts intact.** CONFIRMED. Count block: `capture assert r(min)>=5` → `if _rc { di as error "  SOFT: ..." }`, no `exit`/`cap`. Tallies: `local rc` ×2, `exit `rc'` ×2 (the two surviving hard asserts: centered-mean, reference-SD), `exit 0` ×1 (skeleton), `exit _rc` ×0, SOFT count label ×1. No orphan `local rc`.
2. **Change B efficacy + caveat.** CONFIRMED via data-flow trace: `imputation.do:73` puts secqoi27 in climatevars → clamp at `:138-142` → save CANONICAL `:201` → check reads it. `assert inrange(r(max),0,2.01)` now reads the clamped value (≤2) → passes. Phase order: allsvymerge.do + imputation.do (Phase 5) produce both CANONICAL files before the checks (Phase 7). Caveat flagged: `assert _N == 5625` now validates the consolidated file's N (new failure surface; documented in ADR-0027, desired behavior).
3. **No LIVE `$caschls_projdir`.** CONFIRMED — one header-prose mention (line 14) documenting the re-point; both `src_dta` lines now `$datadir_clean/survey_va/`.
4. **ADR fidelity + index.** CONFIRMED — all line refs in ADR-0027/0028 accurate; README index rows 0027/0028 present, correct titles/status/scope.
5. **Tier-1.** CONFIRMED — `/*`==`*/`==5 both files; 0 hardcoded paths; log paths unchanged; scope minimal; headers updated to match behavior.

## Deductions (−6)

- **−3** ledger hygiene: the 6 convention rows for the two files were stale (hashes predated these edits) and the `check_survey_indices` `no-raw-data-overwrites` Evidence cell wrongly claimed a `$caschls_projdir` read. *(Fixed post-review: hashes re-stamped to a3df2b1db29d / 75bb23f8d9cd; evidence cell corrected to CANONICAL.)*
- **−3** header doc-fidelity: `check_va_estimates.do` line 17 ("pipeline halts") and the INVARIANTS "Hard asserts … min N >= 5" enumeration still read as hard after the count check was downgraded to soft. *(Fixed post-review: line 17 split into HARD vs SOFT; the per-spec count bullet moved under "Soft signals" with the ADR-0028 note.)*

## Recommendations (applied this session)

1. Refresh the ledger rows + correct the evidence cell — DONE.
2. Update `check_va_estimates.do` header to reflect the ADR-0028 amendment — DONE.
3. Watch the next Scribe run for a legitimate `_N != 5625` count mismatch from the re-point (triage as data, not a check bug) — OPEN, for the next run.

## Code Quality: 10/10 categories OK (no figures = N/A). Comment safety clean; `/*` balance 5=5; clobber-safe `local rc` idiom on the remaining hard asserts.
