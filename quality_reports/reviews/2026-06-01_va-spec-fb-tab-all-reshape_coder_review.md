# va_spec_fb_tab_all reshape r(9) fix Review — coder

**Date:** 2026-06-01
**Reviewer:** coder-critic
**Target:** `do/share/va_spec_fb_tab_all.do` (Phase 1b §4.2 paper-affecting bug-fix; reshape r(9) → predicted_score filter)
**Score:** 96/100
**Status:** Active
**Mode:** Full (severity HIGH — Execution / paper-affecting)

---

## Code-Strategy Alignment: MATCH

The change implements exactly the diagnosis recorded in `quality_reports/reviews/2026-06-01_va-spec-fb-tab-all-reshape-r9-debug.md` and ledger row `diagnosis:reshape-r9-predicted-score-dup` (DIAGNOSED, 2026-06-01T16:00Z). The fix is `keep if predicted_score==0` after the `use` in BOTH consumer blocks. Minimal, scoped, no scope creep.

## Sanity Checks: PASS

Each of the 6 rigorous verification points resolved by reading the four producers and the consumer:

### 1. Is `predicted_score==0` the correct canonical value? — CONFIRMED (fix is NOT backwards)

Decisive evidence from the producers (not just the consumer's labels):

- `do/va/va_out_fb_test_tab.do:187` and `:196` write `predicted_score, 0` from CANONICAL `$estimates_dir/.../fb_test/...ster` reads — the standard FB leave-out test.
- `do/va/va_out_fb_test_tab.do:220` and `:227` write `predicted_score, 1` from **LEGACY** `$vaprojdir/.../predicted_prior_score/...ster` reads, gated by the comment `* NOTE: predicted-prior-score reads are LEGACY ($vaprojdir/...); Step 11 deferred (exploratory)` (`:200`).
- `do/va/va_out_fb_test_tab.do:246`: `label var predicted_score "Using predicted ELA score as controls"` — the ps==1 variant is the exploratory "predicted ELA score as controls" branch.
- Spec-side mirror identical: `do/va/va_out_spec_test_tab.do:225/:234` (ps=0, CANONICAL) vs `:251/:260` (ps=1, LEGACY predicted-prior-score, `sd_vam, -999` sentinel). Header `:78` cites `MEMORY: [LEARN:domain] _scrhat_ predicted-score is exploratory`.

So `predicted_score==0` is the paper-shipping leave-out/spec test; `predicted_score==1` is exploratory and not paper-shipping. Keeping ps==0 is correct; a `keep if predicted_score==1` would have been backwards. **Verified.**

### 2. Does the filter make `(column, fb_var)` unique? Does any OTHER axis survive? — RESOLVED: no surviving axis

This is the crux. Producer `regsave` writes one row per regression coefficient (`var`), then `drop if var=="_cons"` in the producer (e.g. `va_out_fb_test_tab.do:247`). The concern is whether `var` (the regressor name) is a second un-keyed duplication axis the consumer's `i(column fb_var)` would still trip on.

**Empirical disproof from the actual run log** (cited in the debug doc): the post-keeper `tab column` shows col1=2, col2=16, col3=16, col4=8, col5=2 (Total 44). The col2=16 decomposes exactly as 8 distinct `fb_var` values × 2 `predicted_score` values — with **no `var` multiplier**. If `var` had >1 non-`_cons` row per regression, the count could not factor cleanly as fb_var×2; it would be fb_var×2×(n_var). The FB regression of interest yields a single coefficient row after `drop if var=="_cons"`. Therefore after `keep if predicted_score==0`: col2 → 8 rows (one per fb_var), the keeper filter (`:177-179`) trims fb_var to {l,a,s,d}, leaving exactly ONE row per `(column, fb_var)`. **`predicted_score` is the sole duplication axis; the filter fully resolves it.** The file is per-outcome (`va_outcome` loop, `:144`), so `va_type` does not vary within one `*_all.dta`; `peer_controls`/`va_sample`/`va_control` are folded into `column`; ci bounds/`prob_f` are columns, not rows. No other axis remains.

### 3. Both blocks fixed? — CONFIRMED

`grep -n 'keep if predicted_score'` → `:164` (FB block) and `:232` (spec block). The spec producers also write ps 0/1 (`va_out_spec_test_tab.do:225/234/251/260`), so the spec reshape `i(column)` at `:268` — which assumes ONE row per column — would r(9) identically without the filter. Both pre-empted. **Verified.**

### 4. Placement — CONFIRMED correct in both blocks

- FB block: `use` at `:154` → `keep if predicted_score==0` at `:164` → first `gen column` at `:166` → `keep column fb_var f_stat_lovar coef stderr pval` at `:183` (which drops predicted_score). Filter is after the `use` and before the drop. Nothing touches `predicted_score` between `:154` and `:164`.
- Spec block: `use` at `:227` → filter at `:232` → first `gen column` at `:234`. Same correct ordering.

You cannot filter on a variable after dropping it; the ordering respects this in both blocks. **Verified.**

### 5. No other logic change — CONFIRMED

The change adds only 2 `keep if predicted_score==0` lines plus `//`-prefixed explanatory comments (`:156-163`, `:229-231`). No estimator, sample-key, reshape-spec, or output-path change. No braces introduced (the two new lines are flat statements), so structural brace balance is unchanged (17=17 per the diagnosis row).

- **`/* */` balance:** state-machine trace — 5 opens (L1, L68, L89, L93, L342) each properly closed (L64, L82, L91, L95, L343); none nested. Naive grep `/\*`=5, `\*/`=5 concurs. No Variant-8 over-flatten artifact (no `^-+<x>$` / `^\s*<x>\s*$` lines introduced). **Balanced.**
- **Path-glob in comments:** the new comment lines use literal tokens (`fb_<outcome>_all.dta`, `(column, fb_var)`, `predicted_score==1`) — no bare `prepare/*`-style glob. No `//*****` banner introduced. **Clean.**

### 6. Risk of dropping ALL rows? — RULED OUT

Producer `va_out_fb_test_tab.do:187/:196` and `va_score_fb_test_tab.do:195/:204` write `predicted_score, 0` **unconditionally** from the CANONICAL ster reads in the standard (always-run) branch — the ps==0 rows are not gated by any toggle. Spec-side same (`:225/:234`). So a fresh producer run always emits ps==0 rows; `keep if predicted_score==0` cannot empty the dataset. (Air-gapped — reasoned from producer write structure, not run.)

## Robustness: Complete (for this fix)

This is a targeted r(9) bug-fix, not a new specification; no robustness-check menu applies. The fix correctly preserves the paper-shipping set and excludes the exploratory variant — which is itself the robustness-correct choice (ps==1 carries `sd_vam, -999` sentinels and an asymmetric `sd_va` latent bug documented in `va_out_spec_test_tab.do:50-62`, so including it would corrupt the table).

## Code Quality (10 categories)

| Category | Status | Issues |
|----------|--------|--------|
| Script structure & headers | OK | Header intact; relocation/CHAIN notes accurate post-ADR-0024 |
| Console output hygiene | OK | No new `di`/banner pollution |
| Reproducibility | OK | `set seed 1984` (`:122`); no abs paths; reads via `$tables_dir` globals |
| Function/program design | OK | `rplc` program untouched |
| Figure quality | N/A | No figures in this change |
| Output persistence | OK | texsave outputs unchanged; CANONICAL `$tables_dir/share/va/...` |
| Comment quality | OK | New comments explain WHY (14-mo producer/consumer drift), cite the debug doc + ADR-0012 producer-tier |
| Comment safety (10b) | OK | 5=5 `/* */`; no path-glob; no `//*****` |
| Error handling | OK | Filter is the error fix; ps==0 guaranteed non-empty |
| Professional polish | OK | 2-space indent consistent with surrounding block (mixed tab/space pre-exists from predecessor, not introduced here) |

## Compliance Evidence (from .claude/state/verification-ledger.md)

- `do/share/va_spec_fb_tab_all.do` | `diagnosis:reshape-r9-predicted-score-dup` | 2026-06-01T16:00Z | hash `3688376a15d9` | DIAGNOSED | matches my independent producer/consumer trace
- `do/share/va_spec_fb_tab_all.do` | `no-logic-change` | 2026-06-01T16:00Z | hash `3688376a15d9` | **UNVERIFIED** | residue = 2 `keep if predicted_score==0` lines (FB L164 + spec L232) + comments. Per evidence-gating §6: recorder emitted UNVERIFIED because content changed beyond path swaps. **Critic adjudication: the residue is a correct, minimal, scoped duplication-axis filter — NOT substantive unjustified logic change.** Verdict held at the diagnosis-backed level, not escalated to FAIL. The filter restores the consumer's original 2023-era invariant (one row per (column, fb_var)) that the producer's 2024 predicted_score addition silently broke.
- Producers (`va_{out,score}_{fb,spec}_test_tab.do`) | `no-hardcoded-paths` / `adr-0021-sandbox-write` / `helper-include-absolute` | 2026-05-08T00:30Z | all PASS (rows L77-87) — relied upon for the canonical-value derivation; producer file hashes not re-checked this session (producers unmodified by this change).

## Evidence-gating verdicts (Tier-2)

- **Claim:** "ps==0 is the canonical paper-shipping value; ps==1 is exploratory." **Artifact:** `do/va/va_out_fb_test_tab.do:187` (ps=0 from CANONICAL `$estimates_dir`) + `:220` (ps=1 from LEGACY `$vaprojdir/predicted_prior_score`) + `:246` (label). **Sufficiency:** the CANONICAL-vs-LEGACY read root plus the explicit exploratory label pin the canonical value unambiguously. Verdict: **PASS.**
- **Claim:** "predicted_score is the sole surviving duplication axis." **Artifact:** debug-doc `tab column` counts (col2=16=8 fb_var × 2 ps) cross-referenced to producer `drop if var=="_cons"` (`va_out_fb_test_tab.do:247`). **Sufficiency:** the clean fb_var×2 factorization of the real-run count is only possible if `var` collapses to one row; empirical, not assumed. Verdict: **PASS** (with the honest caveat that the count is from a prior log, not a post-fix run).

## Score Breakdown

- Starting: 100
- `no-logic-change` ledger row is UNVERIFIED (recorder residue non-empty): per §6 a clean-refactor PASS is not permitted on the bare row. **−4** — reduced from the standard −25 because (a) this is NOT presented as a no-logic-refactor; it is a deliberate, ADR-backed bug-fix whose logic change is the point, and (b) I independently verified the residue is correct and minimal via line-cited producer/consumer inspection. The deduction reflects the irreducible air-gapped residual: end-to-end unrun, so the r(9) resolution is confirmed by static reasoning + prior-log arithmetic, not a green Scribe run.
- **Final: 96/100**

## Escalation Status: None (round 1 PASS)

---

## Air-gapped honesty

I cannot run `do do/share/va_spec_fb_tab_all.do` on Scribe. Every verdict above is static: producer/consumer line-by-line reads, the prior run log's `tab column` arithmetic, and `/* */` state-machine tracing by hand (the `stata_sweep.py --check` tool was not executed). The decisive uniqueness claim (point 2) rests on the empirical col2=16 = fb_var×2 factorization from the existing log — strong, but a post-fix Scribe run remains the final confirmation. If the next Phase-6 run still r(9)s on this reshape, the failure would have to come from an axis NOT present in that prior log (none identified), which I judge very unlikely.
