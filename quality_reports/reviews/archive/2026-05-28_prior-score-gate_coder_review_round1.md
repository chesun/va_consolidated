# prior-score-gate Review — coder (ROUND 1)

**Date:** 2026-05-28
**Reviewer:** coder-critic
**Target:** `do/settings.do`, `do/va/reg_out_va_all.do`, `do/va/reg_out_va_all_tab.do`, `do/va/reg_out_va_all_fig.do`, `do/va/reg_out_va_dk_all.do`, `do/va/reg_out_va_dk_all_tab.do` (Phase 1b §4.2 prior-score-decile gate fix)
**Score:** 78/100
**Status:** Superseded by [../2026-05-28_prior-score-gate_coder_review.md](../2026-05-28_prior-score-gate_coder_review.md)
**Mode:** Phase 1b §4.2 paper-affecting code correction; hard gate 80/100

> Archived round-1 record. The two BLOCK findings below (M1 `reg_out_va_dk_all_fig.do`,
> M2 `do/share/va_scatter.do`) were remediated in round 2; see the superseding review.

## Code-Strategy Alignment: DEVIATION (incomplete)
## Sanity Checks: PASS (the 6 touched files)
## Robustness: Incomplete — two ungated consumers missed

---

## Headline

The fix is **internally clean across all 6 touched files** — braces balance, comment
contexts balance, gate semantics are correct, no scope creep, no path-glob `*` in
comments. At the default value `$run_prior_score = 1` the immediate `r(601)` on
`het_reg_enr_va_ela_x_prior_ela_b_sp_b_ct.ster` is resolved and no behavior regresses.

**But the change does not deliver the plan's central promise — a single coherent
switch.** Plan Decisions #2 and #3 state that flipping `$run_prior_score` to 0 must
disable producer AND every consumer together. A wide grep finds **two live,
paper-affecting consumers of prior-score `.ster`/`.gph` artifacts that this change did
not gate** — `do/va/reg_out_va_dk_all_fig.do` (M1) and `do/share/va_scatter.do` (M2).

## Findings (round 1)

- **M1 (Major)** — `do/va/reg_out_va_dk_all_fig.do` ungated consumer (`est use` `:176`,
  `graph combine` `:249-253`); not in change set. Flip to 0 → r(601) on DK figure path.
- **M2 (Major)** — `do/share/va_scatter.do` ungated consumer of non-DK prior-score `.gph`
  (`graph use`/export `:735-786`); not in change set. Flip to 0 → r(601) on share figure path.
- **M3 (Minor)** — coder's scope summary reported the desync eliminated when two live
  readers remained ungated.

## Score Breakdown (round 1)

- Starting: 100
- M1 + M2 — two live paper-affecting ungated consumers (missing coverage from memo): **−15**
- M3 (Minor): **−5**
- **Final: 78/100 — BLOCK**

## Escalation Status: None (Strike 1 of 3)
