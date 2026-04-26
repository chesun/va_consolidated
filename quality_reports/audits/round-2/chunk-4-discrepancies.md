# Chunk 4 — Discrepancy Report (Round-1 vs Round-2)

**Chunk:** 4 — Pass-through and heterogeneity (11 files: `reg_out_va_all.do`, `reg_out_va_dk_all.do`, `_tab.do` + `_fig.do` variants, `prior_decile_original_sample.do`, `va_corr_schl_char.do` + `_fig.do`, `va_het.do`, `persist_het_student_char_fig.do`)
**Date:** 2026-04-26
**Round-1 source:** `quality_reports/audits/round-1/2026-04-25_deep-read-audit.md` §"Chunk 4: Pass-through and heterogeneity"
**Round-2 source:** `quality_reports/audits/round-2/chunk-4-verified.md`
**Adjudicator:** Claude (this turn).

---

## Summary table

| Category | Count |
|---|---|
| AGREE | 13 |
| ROUND-1-MISSED | 5 |
| ROUND-2-MISSED | 2 |
| DISAGREE | 0 |
| TEMPORAL ARTIFACTS | 0 |

**Headline findings:**

1. **Both rounds independently flag the same 11 known bugs/anomalies in chunk 4** — exceptional convergence. The verification protocol shows that the chunk-4 round-1 audit was high-fidelity.

2. **Round-2 surfaced 5 new findings round-1 missed** — most notably the **file 4 L177 mtitles 24-vs-32 column mismatch** (potentially producing un-labeled columns in published Table 4) and the **file 9 L104 kdensity ytitle bug** (mislabels density Y-axis as VA).

3. **Round-1 caught 2 small things round-2 didn't** — `reg_out_va_all_tab.do:463` di-message copy-paste and missing-author-line header inconsistencies.

4. **`local run_prior_score = 0` (file 2 L235) is the most consequential finding in chunk 4** — both rounds agree this hard-codes off the single-subject prior-decile heterogeneity regs, breaking clean reproducibility of `reg_out_va_all_fig.do` L159's downstream consumption. Phase 1 must address.

---

## AGREE rows

| # | Finding | R1 cite | R2 cite | Tier | Status |
|---|---|---|---|---|---|
| A1 | **`reg_out_va_all.do:235`** `local run_prior_score = 0` hard-codes single-subject × prior-decile heterogeneity regs OFF. `reg_out_va_all_fig.do:159` unconditionally loads these `.ster` files — fragile/broken on clean run. | R1 New bugs:1 | R2 §File 2 BUG (L235) | T4 (Christina decision: keep gate, remove gate, or restore unconditional run) | OPEN |
| A2 | **`va_corr_schl_char.do` L84/L88, L94/L98 LHS-peer-suffix bug.** Regression LHS lacks `peer` token but output filename embeds `_p` from sample-coupled local. When sample==las, output named `..._ct_p.ster` but regression actually used non-peer VA. | R1 New bugs:2 | R2 §File 8 CONFIRMED FILENAME-VS-VARIABLE MISMATCH | T3 | LOCKED — Phase 1 fix |
| A3 | **`va_het.do:158`** uses `cluster(cdscode)` vs paper-claimed `school_id`. May be functionally equivalent if cdscode≡school_id 1:1 in CA data. | R1 New bugs:3 | R2 §File 10 CONFIRMED CLUSTER-LEVEL DEVIATION | T1/T3 (Christina runs `assert school_id==cdscode` on Scribe) | OPEN |
| A4 | **`va_het.do:92`** `areg` has no `vce()` clause — defaults to iid SEs. R²-only output mitigates impact. | R1 New bugs:4 | R2 §File 10 L92 (no cluster()) | T3 | LOCKED — cosmetic |
| A5 | **`va_het.do` `gr5` dead branch** at L66/L102 — `gr5` not in `district_type` loop (`gr2 top25`), so the labeling branch never fires. | R1 New bugs:5 | R2 §File 10 CONFIRMED gr5 DEAD CODE | T3 | LOCKED — Phase 1 cleanup |
| A6 | **`reg_out_va_all_fig.do:568`** filename typo `x_prior_x_prior_` (doubled token). | R1 New bugs:6 | R2 §File 6 L568 FILENAME TYPO bug | T3 | LOCKED — Phase 1 fix |
| A7 | **`reg_out_va_all_fig.do` and `reg_out_va_dk_all_fig.do` line-172** comments claim "90% CI" but `parmest`'s `min95`/`max95` are 95% CI bounds. | R1 New bugs:9 | R2 §File 6 CONFIRMED COMMENT/CODE MISMATCH (L172, L288, L453) | T3 | LOCKED — comment fix in Phase 1 |
| A8 | **`reg_out_va_dk_all_fig.do` L148-150** retains on-figure titles/subtitles — inconsistent with `reg_out_va_all_fig.do` (which has them commented out). | R1 New bugs:10 | R2 §File 7 L148-150 (NOT commented out, inconsistency) | T3 | LOCKED — Phase 1 cleanup per `figures.md` rule |
| A9 | **`prior_decile_original_sample.do:106`** `xtile inc_mean_hh_xtile = inc_median_hh` — variable named "mean" computed from "median" input. Cosmetic (no downstream consumer per round-1; round-2 confirms). | R1 New bugs:11 | R2 §File 1 BUG (L106) | T3 | LOCKED — Phase 1 fix |
| A10 | **`va_corr_schl_char.do` is functionally orphaned** — produces ster files no chunk-4 file consumes. Paper-Table-5 producer is `va_het.do`. | R1 New bugs:12 | R2 §File 8 §Q7 redundancy answer | T3 | LOCKED — Phase 1 archive candidate |
| A11 | **Nested `forvalues i = 1/2` (outer = peer, inner = match)** in 4 files. Works in Stata but fragile. Should rename inner to `j`/`k`. | R1 New bugs:14 | R2 §File 5 L242 SHADOW; §File 6 L138/L149, L251/L262, L418/L429 | T3 | LOCKED — Phase 1 cleanup |
| A12 | **Pass-through ρ canonical regression specification:** `reg <outcome> va_<subject>_<sample>_sp_<control>_ct[_p] i.year <controls>, cluster(school_id)`. Two variants: base (`b_controls`) and matched (`<control>_spec_controls`). Both rounds derive same spec. | R1 §"Pass-through ρ — canonical regression specification" | R2 §Q1 | T3 | LOCKED |
| A13 | **Naming-token resolution**: `_m` = matched 2nd-stage controls (used in `reg_out_va_all*.do`); `_wt`/`_nw` = weighted/unweighted (only in `va_het.do` L78, L82). Both AGREE. | R1 §"Naming convention catalog — `nw / _m / _wt` ALL RESOLVED" | R2 §Q4 | T3 | LOCKED — naming catalog now complete |

---

## ROUND-1-MISSED rows (round-2 found, round-1 did not)

### M1 — `prior_decile_original_sample.do` collapse mean of integer deciles

- **Round-2 claim** (File 1 L94-95): `(mean) prior_ela_z_score_xtile prior_math_z_score_xtile` then `(max) race male econ_disadvantage` — taking MEAN of decile (an integer) is unusual. If a student appears multiple times, mean is non-integer and would break `i.prior_*_xtile` factor-variable use in regressions.
- **Round-1**: missed. Did not interrogate the collapse semantics.
- **Tier**: T3 — verify `out_b.dta` has 1 row per student per year via `assert`.
- **Severity**: LATENT but consequential if students have multi-row entries.
- **Action**: Phase 1 — add defensive assertion or change collapse to `(firstnm)` for deciles.

### M2 — File 9 (`va_corr_schl_char_fig.do`) L104 kdensity `ytitle` bug

- **Round-2 claim**: `ytitle("``va_outcome'_str' VA")` on a kdensity plot. Kdensity's Y-axis is density, not VA — should be `xtitle`. **Plot-label bug.**
- **Round-1**: missed.
- **Tier**: T3 — direct read.
- **Severity**: PUBLISH if used in OA figure (mislabels axis).
- **Action**: Phase 1 fix.

### M3 — File 10 `va_het.do:214` hlines typo (13 duplicated)

- **Round-2 claim**: `hlines(1 3 5 11 13 13 14 16 18 24)` — `13` appears twice. Likely intended `1 3 5 11 13 14 16 18 24`. Effect on rendered TeX is benign (drawing two `\hline` at same row is no-op).
- **Round-1**: missed.
- **Tier**: T3.
- **Severity**: cosmetic.
- **Action**: Phase 1 cleanup.

### M4 — File 4 (`reg_out_va_all_tab.do`) `mtitles` 24-cols vs 32-cols actual

- **Round-2 claim** (File 4 L177): `mtitles` declares 24 columns; actual `eststo` accumulates 32 (2 subjects × 16 sample-ctrl-peer-match). esttab will likely silently produce un-labeled columns or default labels. **POSSIBLE BUG** — needs verification on actual CSV output.
- **Round-1**: missed.
- **Tier**: T1 — Christina opens the actual CSV at `$vaprojdir/tables/va_cfr_all_v1/reg_out_va/reg_*.csv` and counts columns. Compare to `mtitles` declaration.
- **Severity**: HIGH if paper Table 4 is built from this CSV with truncated/misaligned column headers.
- **Action**: T1 verification needed BEFORE Phase 1 fix. If confirmed, fix `mtitles` and `mgroups` to match 32 columns.

### M5 — Files 4 and 5 sample-control list narrower than producer files

- **Round-2 claim** (File 4 §"Inconsistent control list" + File 5 §L48-49): tab files use narrower control lists than the producer regression files. Some `.ster` files exist on disk but never appear in tables.
- **Round-1**: noted "subset" in `reg_out_va_all_tab.do:47 las_sample_controls = "b a las"` — subset of regression file's `"b a ls las bd ad lsd lasd"`. So round-1 DID flag the file-4 case. But round-1 did NOT enumerate the file-5 DK case (`b las` vs `b ls las`).
- **Reconciliation**: Round-1 caught file 4 (partial); round-2 caught both file 4 AND file 5 systematically. **Partial round-1 miss; full round-2 catch.**
- **Tier**: T3 — already documented in both rounds.
- **Action**: Phase 1 — decide whether to drop the orphan `.ster` files or expand tab files to load them. Likely the former (table simplification).

### M6 — File 5 `reg_out_va_dk_all_tab.do` L242 `forvalues i = 1/9` shadows outer `forvalues i = 1/2`

- **Round-2 claim**: Same shadowing pattern as elsewhere; documented at L242 vs L219.
- **Round-1**: caught the shadowing at L138/L149 etc. in `reg_out_va_all_fig.do` but did NOT explicitly note it at file 5 L242.
- **Reconciliation**: Round-1 documented the pattern as a class but didn't enumerate every instance. Round-2 enumerated. **Partial round-1 miss.**

---

## ROUND-2-MISSED rows (round-1 found, round-2 did not reproduce)

### N1 — `reg_out_va_all_tab.do:463` di-message copy-paste error

- **Round-1 claim** (New bugs:7): `reg_out_va_all_tab.do:463` references `reg_out_va_all_fig.do` instead of `_tab.do` in a di message.
- **Round-2**: did not flag.
- **Tier**: T3 — direct read.
- **Severity**: cosmetic.
- **Action**: Phase 1 fix.

### N2 — Header inconsistencies (missing author lines)

- **Round-1 claim** (New bugs:15): `va_corr_schl_char.do` and `va_corr_schl_char_fig.do` lack author line; `va_het.do` shows only the date.
- **Round-2**: did not flag header inconsistencies. (Round-2 noted ownership at "unknown" but didn't classify as a documentation issue.)
- **Tier**: T3 — direct read.
- **Severity**: documentation hygiene.
- **Action**: Phase 1 — add headers per `stata-code-conventions.md` template.

---

## Adjudication & open questions

### Q1 — `run_prior_score = 0` (A1) — what to do?

The single-subject × prior-decile heterogeneity regs are gated OFF. Three Phase 1 options:

1. **Remove the gate**: restore unconditional run. Single-subject panels in Figs 5-6 + OA single-subject prior-decile figures regenerate cleanly.
2. **Keep the gate**: paper uses only the both-subject panel (which is NOT gated). Single-subject is exploratory; archive the gated block.
3. **Make the gate explicit (config flag)**: turn into a settings.do toggle.

**Tier**: T4 — Christina knows which option is consistent with paper.

### Q2 — File 4 L177 mtitles 24-vs-32 mismatch (M4)

**Tier**: T1 — Christina opens CSV on Scribe.

**Why this is high-priority**: if paper Table 4 has mis-labeled columns, that's a paper-output integrity issue. Worst case: published table has wrong column headers. Even if benign, fix is cheap.

### Q3 — `cdscode == school_id` 1:1 in `va_all.dta` (A3)

**Tier**: T1 — Christina runs `assert school_id == cdscode` (or `egen tag = tag(cdscode school_id)` and checks for cross-pairs).

If TRUE → A3 collapses to a cosmetic inconsistency. If FALSE → SEs in `va_het.do:158` differ from chunk-4 main regs and from chunk-5's heterogeneity regs (also use `cdscode`).

### Q4 — Header conventions for Phase 1 consolidation (N2)

**Tier**: T4 — Phase 0e Q&A. Standardize all chunk-4 file headers in Phase 1.

---

## What changes for downstream chunks

- **A1 (`run_prior_score=0`)** is the most material chunk-4 finding. Cross-reference with chunk-9 (share/explore) when batch 4 dispatches: are the single-subject prior-decile figures actually used in the paper? If yes, restoring the gate is essential.
- **M4 (file 4 mtitles mismatch)** combined with chunk-5 M1 (mtitles labeling bug in `reg_out_va_sib_acs_tab.do`) suggests `esttab` mtitles audits should be a recurring concern across all `_tab.do` files. Phase 1: sweep all `esttab mtitles(...)` calls and verify column counts.
- **A3 (cdscode vs school_id)** combines with chunk-5 SE clustering question (also flagged) — single T1 test on Scribe answers both at once.

---

## Outstanding items (chunk 4 specifically)

1. T1 test: open `$vaprojdir/tables/va_cfr_all_v1/reg_out_va/reg_*.csv` and count columns vs declared mtitles (M4).
2. T1 test: `assert school_id == cdscode` in `va_all.dta` (A3 / chunk-5 A10 jointly).
3. T1 test: confirm `out_b.dta` has 1 row per student per year (M1).
4. T4 escalation: `run_prior_score = 0` decision (A1 / Q1).
5. T4 escalation: A3 cluster-level intent if cdscode ≠ school_id.
6. T4 escalation: header conventions (N2).
7. Phase 1 fixes: A2, A5, A6, A7, A8, A9, A11, M2, M3, M6, N1, N2.
8. Phase 1 archive: `va_corr_schl_char.do` + `_fig.do` (A10) — supersede with `va_het.do`.

---

## Verdict

**Strong agreement on chunk 4 — exceptional convergence (13 AGREE rows).** Round-2 surfaced 5 minor-to-medium new findings; round-1 caught 2 small documentation issues round-2 didn't flag. **Zero contradictions.** Round-1 chunk-4 audit was high-fidelity.

**The most consequential finding is A1** (the `run_prior_score = 0` gate). Combined with the chunk-3 distance-FB-row-6 question and the chunk-5 mtitles labeling bug, chunk 4's `run_prior_score` is the third major Phase-0e walkthrough item.

**Round-2 found no chunk-4 confirmation-bias errors** — round-1's chunk-4 was clean. (Compare to chunks 2 and 5 where round-2 found round-1 false positives.)
