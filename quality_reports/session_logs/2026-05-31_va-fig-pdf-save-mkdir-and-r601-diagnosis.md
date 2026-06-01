# Session Log — 2026-05-31 — VA figure PDF-save mkdir fix + r(601) re-diagnosis

## Goal

User reported: the most recent run errored at "the selected line" in a do file, and the figure
subdirectories inside `figures/va_cfr_all_v*` were not being created, so the PDF figure could not be saved.
Debug and fix.

## What I found (two distinct bugs)

### Bug #1 — the actual May-26 batch termination (NOT a PDF-save failure)

- Log `log/main_26-May-2026_20-50-27.smcl` (119 MB, FileZilla'd from Scribe; mtime May-28 16:32; internal
  RUN START 26 May 20:50). The **only** error code in all 1.58M lines is `r(601)` (×5, the terminating
  cascade): `est use $estimates_dir/va_cfr_all_v1/reg_out_va/het_reg_enr_va_ela_x_prior_ela_b_sp_b_ct.ster
  not found` at `do/va/reg_out_va_all_fig.do:211`. Zero `r(603)` / "could not be opened" / "not be saved".
- Root cause: in that batch the producer `do/va/reg_out_va_all.do` ran with the single-subject
  prior-score-decile heterogeneity block effectively OFF (producer di-histogram: `Heterogeneity: ela VA
  interacted with prior ela` = 0 occurrences vs charter/race/econ/income = 120 each), so
  `het_reg_*_x_prior_*.ster` were never written; the live consumer figure script then `est use`d the missing
  file → r(601). A producer/consumer gate desync, not a directory bug.
- This was **already fixed** before today, in commit `e8d47aa` (2026-05-28) — "re-enable
  prior-score-decile heterogeneity via single run_prior_score global" — which harmonized producer + all 8
  consumers onto `if "$run_prior_score" != "0"`, with `global run_prior_score 1` the single source of truth
  at `do/settings.do:225`. The May-26 log predates that fix.

### Bug #2 — the mkdir/PDF-save bug the user described (real, separate, latent)

- Stata `mkdir` does not create intermediate parents. Both figure scripts only `cap mkdir`'d the top-level
  `va_cfr_all_v1`/`v2`, but `graph export` / `saving()` write into nested subdirs. This would surface as the
  NEXT error (`r(603)` on the first export) once Bug #1 cleared and execution reached an export — exactly the
  symptom the user described. Not present in the local log because that log died earlier at Bug #1.

## Fix applied (this session)

- `do/va/reg_out_va_all_fig.do` — added 14 `cap mkdir` lines (one per level, parent→child, v1+v2, under
  both `$figures_dir` and `$output_dir/gph_files`): `het_reg_prior_score/`, `het_reg_chars/`,
  `het_reg_combined_panels/score_va/`. Hash `fe9d46b36987`.
- `do/va/reg_out_va_dk_all_fig.do` — added 10 `cap mkdir` lines: `het_reg_dk_prior_score/`,
  `het_reg_combined_panels/dk_va/`. Hash `bbd1ca17f33f`.
- `do/main.do:356` — fixed stale one-liner that still said "prior decile gated off" (contradicted the
  re-enabled gate) → "prior decile via $run_prior_score, default on". Hash `76ecd1223900`.
- Style mirrors the two siblings already doing it right: `do/va/heterogeneity/persist_het_student_char_fig.do`,
  `do/va/heterogeneity/va_corr_schl_char_fig.do`.

## Verification

- Code-only; Scribe-only runtime (ADR-0002), air-gapped — cannot run Stata locally.
- FS-level check: every `graph export`/`saving()` target dir in both files now has a matching parent-before-child
  `cap mkdir` for v1+v2; `/* */` balance unchanged (all_fig 15=15, dk_fig 4=4). Recorded in
  `.claude/state/verification-ledger.md` (rows: `diagnosis:batch-r601-pdf-save` DIAGNOSED;
  `mkdir-covers-export-targets` PASS ×2; `no-logic-change` UNVERIFIED ×2 — UNVERIFIED because end-to-end
  re-run not yet done on Scribe).

## Reports

- Debug write-up: `quality_reports/reviews/2026-05-31_va-fig-pdf-save-debug.md`.

## Current toggle state (confirmed)

- `do/settings.do:225` → `global run_prior_score 1` (gate ON).
- `do/main.do:100` `run_va_estimation 1`; `do/main.do:128` `m4_acceptance_run 1` (rebuilds samples + VA from
  scratch). Producer phase will run on the next Scribe run.

## Open / next

- Three files modified, **not committed** (`reg_out_va_all_fig.do`, `reg_out_va_dk_all_fig.do`, `main.do`).
  Per phase-1-review.md, the two figure files are in-scope code changes → coder-critic dispatch before commit.
- Needs a Scribe re-run to confirm end-to-end (no local Stata). Expected order on next run: producer writes
  `.ster` (gate on) → figure scripts find them (no r(601)) → new subdirs let PDFs export (no r(603)).
- Still no local log showing the actual `r(603)` PDF-save failure — if Christina has a newer Scribe log, use
  it to confirm the mkdir fix matches the exact failing line.

---

## Addendum (same session) — third bug: va_score_sib_lag r(111)

User reported the next run errored further down at `log/va/va_score_sib_lag.smcl:841-845`:
`variable old1_sib_enr_2year not found, (error in option controls()) r(111)`.

**Root cause (fully traced):** `vam`'s `controls(... \`sib_lag1_controls' ...)` (va_score_sib_lag.do:102/164,
va_out_sib_lag.do:100/164) expands `sib_lag1_controls`/`sib_lag2_controls` (macros_va.doh:270-279) to
`old1_sib_enr_2year old1_sib_enr_4year` / `old2_...`. Those vars are built in
`do/sibling_xwalk/siblingoutxwalk.do:314-327` and saved to the crosswalk, but `do/samples/merge_sib.doh:64`
merges with `keepusing(touse* *sibling*)` — `old1_sib_enr_2year` matches neither pattern (`sib` ≠ `sibling`),
so the lag controls are dropped before `score_s`/`out_s` are saved. The two sib-lag diagnostics are the only
consumers of these controls.

**NOT a relocation regression:** consolidated `merge_sib.doh:64` is byte-identical to predecessor
`cde_va_project_fork/do_files/sbac/merge_sib.doh:5`. Decisive evidence from predecessor logs: `.log` (run
2023-03-07) ran clean with `old1_sib_enr_*` coefficients (lines 718/722); `.smcl` (2024-07) shows the
identical r(111). So it's a pre-existing latent bug that broke in the predecessor too. It surfaced in M4
because `m4_acceptance_run = 1` (main.do:128) forces `do_create_samples = 1`, rebuilding `score_s` fresh
through the current `merge_sib.doh` instead of reading the old cached `.dta`.

**Fix (Option B, user-chosen — scoped, golden-master-parity-safe):** after each `use ... score_s/out_s ...`
in both diagnostics, re-merge the four lag vars from the crosswalk:

```stata
merge m:1 state_student_id using "$datadir_clean/siblingxwalk/sibling_out_xwalk", ///
  nogen keep(1 3) keepusing(old1_sib_enr_2year old1_sib_enr_4year old2_sib_enr_2year old2_sib_enr_4year)
```

Added at both `use` sites in each file (VA-est block + FB-test block). `state_student_id` confirmed retained
in the sample (create_va_sample.doh:72; score_s is student-level, no collapse before save). Shared paper
sample `.dta` files untouched → clean for M4 golden-master parity. Considered + rejected: Option A (broaden
merge_sib.doh keepusing — touches shared samples) and Option C (gate diagnostic off — defers, doesn't fix).

**Files:** `do/va/va_score_sib_lag.do` (hash 18273ca02938), `do/va/va_out_sib_lag.do` (95e779641c61).
Comment balance 4=4 in both; `*/`-glob hazard avoided (hook caught a first attempt that used `old1_sib_*/`
literally — rephrased). Debug write-up: `quality_reports/reviews/2026-05-31_va-score-sib-lag-r111-debug.md`.
Ledger rows added (diagnosis + no-logic-change UNVERIFIED ×2 + comment-balance PASS ×2). Code-only; needs
Scribe re-run to confirm.

**Now 5 files uncommitted this session:** reg_out_va_all_fig.do, reg_out_va_dk_all_fig.do, main.do,
va_score_sib_lag.do, va_out_sib_lag.do. coder-critic dispatch still pending before commit.
