# Plan — fix r(601) prior-score-decile gate desync

**Date:** 2026-05-28
**Status:** APPROVED
**Trigger:** Run `main_26-May-2026_20-50-27.smcl` errored `r(601) file not found` on
`het_reg_enr_va_ela_x_prior_ela_b_sp_b_ct.ster`.

## Root cause

Producer `do/va/reg_out_va_all.do:292` gates prior-score-decile heterogeneity OFF
(`local run_prior_score = 0`), so `het_reg_*_x_prior_*.ster` files are never written.
Consumers read those files **unconditionally** → `r(601)`:

- `do/va/reg_out_va_all_tab.do:398` (single-subject), `:466` (ela_math combined)
- `do/va/reg_out_va_all_fig.do:206` (single), `:486` (ela_math), `:573-576` (.gph combine)

DK-VA path (`reg_out_va_dk_all.do:188` producer / `reg_out_va_dk_all_tab.do:280` consumer)
is currently both-on and consistent, but has NO toggle — latent same-class fragility.

## Decisions (Christina, 2026-05-28)

1. **Re-enable** prior-score-decile heterogeneity (default ON).
2. **Single global** `run_prior_score` as source of truth (not per-file locals) — crosses
   do-file boundaries, impossible to half-flip.
3. **Gate DK too** for one coherent switch.

## Changes

| File | Change |
|---|---|
| `do/settings.do` | Add `global run_prior_score 1` with note: single source of truth for prior-score-decile het; producer + all consumers gate on it; flip to 0 disables producer AND consumers together. |
| `do/va/reg_out_va_all.do` | L292: remove `local run_prior_score = 0`; change gate to `if "$run_prior_score" != "0"`. Warning note. |
| `do/va/reg_out_va_all_tab.do` | Wrap both prior-subject blocks (≈375-420, ≈450-485) in `if "$run_prior_score" != "0" { ... }`. Warning note at each. |
| `do/va/reg_out_va_all_fig.do` | Wrap prior-score blocks (≈206, ≈486, ≈573-576 .gph combine) in same gate. Warning note. |
| `do/va/reg_out_va_dk_all.do` | Wrap L188 `foreach prior_subject` block in same gate. Warning note. |
| `do/va/reg_out_va_dk_all_tab.do` | Wrap L280 prior block in same gate. Warning note. |

## Gate convention

`if "$run_prior_score" != "0" { ... }` — treats unset (standalone sub-do run without
settings.do) as ON, preserving current behavior; only an explicit `0` in settings.do
disables. settings.do sets the documented default `1`.

## Warning-note template (each gated site)

```stata
* GATE: prior-score-decile heterogeneity. Single source of truth = $run_prior_score
* in do/settings.do. Producer (reg_out_va_all.do / reg_out_va_dk_all.do) and ALL
* consumers (this file + *_tab.do, *_fig.do) MUST gate on the same global, or a
* disabled producer leaves consumers reading missing .ster -> r(601). [2026-05-28]
```

## Verification (air-gapped — Christina runs on Scribe)

1. `coder-critic` review BEFORE commit (paper-affecting code; phase-1-review §4.2; hard gate 80).
2. `grep -c '/\*'` == `grep -c '\*/'` per edited file (comment-balance check).
3. Brace balance per edited file.
4. On Scribe: re-run phase 3 (`run_va_estimation`/`run_va_tables`); confirm
   `het_reg_*_x_prior_*.ster` now written and tab/fig steps complete with no r(601).

## Separate (raised, not yet decided)

Master log `main_*.smcl` captures full transcript (Stata mirrors output to all open logs;
master never closes during sub-dos) → 119MB, un-pushable. Options: `log off/on master`
wrapping to make it orchestration-only, OR gitignore the master + push only error tails.
