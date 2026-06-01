# Figure PDF-save / r(601) Debug — coder

**Date:** 2026-05-31
**Reviewer:** claude (debug)
**Target:** `do/va/reg_out_va_all_fig.do`, `do/va/reg_out_va_dk_all_fig.do`; log `log/main_26-May-2026_20-50-27.smcl`
**Status:** Active

## TL;DR

There are **two distinct bugs**, not one:

1. **The literal terminating error in the May-26 log is NOT a PDF-save failure.** It is
   `r(601)` — `est use $estimates_dir/va_cfr_all_v1/reg_out_va/het_reg_enr_va_ela_x_prior_ela_b_sp_b_ct.ster not found`
   at the figure script's `est use` (`do/va/reg_out_va_all_fig.do:211`). The entire 1.58M-line log
   contains only `r(601)` codes — zero `r(603)`/write/"could not be saved" errors. The figure script
   tried to *read* a `.ster` that the upstream producer (`do/va/reg_out_va_all.do`) never wrote in that run.

2. **The bug the user described — subdirectories under `figures/va_cfr_all_v*` not created, so the PDF
   can't be saved — is real, separate, and latent.** It would be the *next* error (an `r(603)` on
   `graph export`) once bug #1 is resolved and the script reaches the export. **This is now fixed.**

## Root cause of bug #1 (the May-26 termination)

Producer (`reg_out_va_all.do:296`) and consumer (`reg_out_va_all_fig.do:194`) now gate the prior-score-decile
block on the **identical** global `if "$run_prior_score" != "0"`. That harmonization carries a `[2026-05-28]`
stamp — i.e. it was added **after** the failing `main_26-May` run. In the May-26 run the producer and
consumer gates were not aligned, so the producer skipped writing the `het_reg_*_x_prior_*.ster` files while
the consumer tried to read them → `r(601)`.

`run_prior_score` is assigned in exactly one place: `do/settings.do:225` → `global run_prior_score 1`
(a global, default on; no toggle-off anywhere in `do/`). With the current harmonized code, producer and
consumer agree, so this specific `r(601)` should not recur **as long as the producer `reg_out_va_all.do`
actually runs and writes the `.ster` files before the figure script in the next run.**

> NOTE: the `clear all`-wipes-the-global theory is wrong. If the global were wiped, *both* producer and
> consumer would read it as unset == on (`"" != "0"` is true), so it cannot explain producer-off/consumer-on.

## Fix applied for bug #2 (the PDF-save / mkdir bug)

Stata `mkdir` does **not** create intermediate parents. Both figure scripts only `cap mkdir`'d the top-level
`va_cfr_all_v1` / `va_cfr_all_v2`, but `graph export` / `saving()` write into nested subdirs. Added one
`cap mkdir` per level (parent→child, v1 and v2, under both `$figures_dir` and `$output_dir/gph_files`):

- `do/va/reg_out_va_all_fig.do`: `het_reg_prior_score/`, `het_reg_chars/`, `het_reg_combined_panels/score_va/`
- `do/va/reg_out_va_dk_all_fig.do`: `het_reg_dk_prior_score/`, `het_reg_combined_panels/dk_va/`

Style mirrors the two siblings that already did it correctly:
`do/va/heterogeneity/persist_het_student_char_fig.do`, `do/va/heterogeneity/va_corr_schl_char_fig.do`.

## Execution context

Run is on the remote Scribe server (error path `/home/research/ca_ed_lab/...`; `estimates/` and `figures/`
do not exist locally). Per air-gapped-workflow, Stata cannot be run here — the fix is code-only; verification
requires a re-run on Scribe.

## Current toggle state (confirmed)

- `do/settings.do:225` → `global run_prior_score 1` (gate ON; both producer and consumer agree).
- `do/main.do:100` → `local run_va_estimation 1` (producer phase will run).
- So the next `stata -b do do/main.do` re-run should: producer writes the `het_reg_*_x_prior_*.ster`
  (gate open) → figure scripts find them (no r(601)) → the now-created subdirs let the PDFs export (no r(603)).
- Also fixed a stale comment at `do/main.do:355` that said "prior decile gated off" (contradicted the
  re-enabled gate).

## Open / unverified

- Cannot run Stata locally (Scribe-only runtime per ADR-0002; air-gapped). End-to-end success not verified —
  needs a Scribe re-run.
- The only local log is the **May-26** run (`r(601)`, pre-gate-fix). I have **not** seen a log showing the
  actual `r(603)` PDF-save failure the user described — that symptom is consistent with the mkdir bug now
  fixed, but a confirming log isn't present locally (likely a later Scribe run whose log didn't sync back).
