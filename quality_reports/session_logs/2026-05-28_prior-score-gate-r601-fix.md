# Session — r(601) prior-score gate fix + master-log diagnosis

**Date:** 2026-05-28

## Trigger
Run `log/main_26-May-2026_20-50-27.smcl` (119MB, 1.58M lines) errored `r(601) file not
found`. Could not push to GitHub (>100MB single-file limit); Christina dragged log to
local via FileZilla for diagnosis.

## Diagnosis
- **Error:** producer/consumer desync. `reg_out_va_all.do:292` gated prior-score-decile
  heterogeneity OFF (`local run_prior_score = 0`) → `het_reg_*_x_prior_*.ster` never
  written. Live consumer `reg_out_va_all_fig.do:211` read them unconditionally → r(601).
  (Note: `reg_out_va_all_tab.do` reads are commented out, so not the live source.)
- **Log bloat:** master log opened `name(master)` at `main.do:78` never closes during
  sub-dos; Stata mirrors all console output to every open log → master = full transcript.
  `main.do:51` claims master holds "orchestration layer" only — comment-vs-behavior gap.

## Decisions (Christina)
1. Re-enable prior-score-decile het (default ON).
2. Single global `run_prior_score` (settings.do) as source of truth — not per-file locals.
3. Gate DK-VA path too (one coherent switch).

## Implementation
8 files: `global run_prior_score 1` in settings.do; `if "$run_prior_score" != "0"` gate
on producer + ALL consumers (reg_out_va_all{,_tab,_fig}.do, reg_out_va_dk_all{,_tab,_fig}.do,
share/va_scatter.do). Warning notes at each gate. Plan: `quality_reports/plans/2026-05-28_prior-score-gate-fix.md`.

## Review (coder-critic)
- Round 1: 78/100 BLOCK — missed two live ungated consumers (reg_out_va_dk_all_fig.do,
  share/va_scatter.do). Strike 1.
- Round 2: 93/100 PASS after gating both. Review:
  `quality_reports/reviews/2026-05-28_prior-score-gate_coder_review.md`.

## Status
- **Done:** code fix complete + PASS. NOT committed (air-gapped — Christina reviews `git
  diff`, pushes to Scribe, re-runs phase 3 to verify .ster written + no r(601)).
- **Pending:** (a) back the 119MB log out of the unpushed Scribe commit (`git reset --soft`
  + unstage); (b) master-log decision — `log off/on master` wrapping (orchestration-only)
  vs gitignore master + push error tails only.
- Local `log/main_26-May-2026_20-50-27.smcl` (119MB) left UNTRACKED for diagnosis — must
  NOT be git-added (would block local push too).

## Master-log fix (orchestration-only) — DONE

Christina chose the `log off/on master` approach over gitignore. Implemented in `do/main.do`:
each of the 7 phases now wraps its body in `log off master` (after the 3-line header) …
`log on master` (before the closing `}`), so the master captures only orchestration
(phase headers + run start/end); sub-do detail goes only to per-file logs. Header comment
updated to match.

- **Mechanism verified locally** (throwaway do-files, no project data): named-log
  suspend/resume works; sub-do output suppressed; errors still propagate; `clear all` in a
  sub-do doesn't disturb master; multi-phase + skipped-phase → zero sub-do leakage.
- **Wrapper-program approach REJECTED:** 55 sub-dos run `clear all`, which would drop a
  persistent program. Direct phase-level off/on is robust to that.
- **coder-critic: 95/100 PASS** (`2026-05-28_master-log-orchestration_coder_review.md`).
  Fixed the one Minor (inline `(see LOG SETUP)` → `(see file header)`).
- Not committed — Christina reviews `git diff do/main.do`, pushes to Scribe.
- On crash: master freezes at the failed phase's header with no RUN END (a useful signal);
  per-file log holds the error.
