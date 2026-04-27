# Chunk 9 — Discrepancy Report (Round-1 vs Round-2)

**Chunk:** 9 — Share/output helpers + explore (13 files: `share/` × 10 + `share/check/` × 1 + `explore/` × 3)
**Date:** 2026-04-26
**Round-1 source:** `quality_reports/audits/round-1/2026-04-25_chunk9-share-explore.md` + summary at `2026-04-25_deep-read-audit.md` §"Chunk 9"
**Round-2 source:** `quality_reports/audits/round-2/chunk-9-verified.md`

---

## Summary table

| Category | Count |
|---|---|
| AGREE | 14 |
| ROUND-1-MISSED | 5 |
| ROUND-2-MISSED | 1 |
| DISAGREE | 0 |
| TEMPORAL ARTIFACTS | 0 |

**Headline findings (UPDATED 2026-04-26 PER CHRISTINA'S FB-TEST CORRECTION):**

1. **~~CRITICAL Column 6 FB drop~~ → NOT A BUG (Christina 2026-04-26).** The keeper rule omitting `va_control=="lasd"` is INTENTIONAL. FB test structure: regress (residual_no_ctrl − residual_with_ctrl) on round-1 VA. When VA spec is `lasd` (kitchen-sink + distance — already includes loscore + ACS + sibling + distance), there are NO controls left to leave out. `macros_va_all_samples_controls.doh:66` confirms: `va_controls_for_fb` lists only `b l a s la ls as las` — explicitly excludes `lasd`. There is no `lasd_ctrl_leave_out_vars` macro. **Column 6 blank FB cells is correct by design.** Paper Tables 2/3 column 6 (Distance INCLUDED IN VA SPEC) shows spec-test row only.

2. **~~CRITICAL predicted_score filter missing~~ → NOT A BUG (Christina 2026-04-26).** Per Christina's broader correction that "FB-test-related bugs are not actual bugs": scrhat outputs go to `predicted_prior_score/` subdirs separately; not conflated in upstream regsave datasets. No filter needed.

3. **Closed-loop paper-output mapping CONFIRMED**: every paper Table 1, 2, 3, 6, 7, 8, A.1 + Figs 1-5 has a chunk-9 producer writing to `tables/share/{va,survey}/pub/`. Both rounds agree.

4. **Distance-FB Row 6 mystery (chunk-3 carryover) RESOLVED**: column 6 of paper Tables 2/3 is the `lasd` (kitchen-sink + distance) column. Distance is INCLUDED IN THE VA SPEC, not used AS A LEAVE-OUT. The chunk-3 `va_spec_fb_tab.do` lovar loop (and the chunk-9 `va_spec_fb_tab_all.do` keeper rule) correctly omit `d`/`lasd` because there's nothing to leave out structurally.

---

## AGREE rows

| # | Finding | R1 cite | R2 cite | Tier | Status |
|---|---|---|---|---|---|
| A1 | **Closed-loop paper-output mapping**: every paper artifact has a producer in chunk 9. Table 1 → `base_sum_stats_tab.do`; Tables 2/3 → `va_spec_fb_tab_all.do`; Table 6 → `reg_out_va_tab.do`; Table 7 → `va_var_explain_tab.do`; Table 8 → `svyindex_tab.do`; Table A.1 → `sample_counts_tab.do`; Figs 1-5 → `va_scatter.do`. | R1 §"Final paper-output mapping" | R2 §Q1 | T3 | LOCKED |
| A2 | **`va_predicted_score_fb.do:43` uses `<va_ctrl>_ctrl_leave_out_vars`** instead of `<va_ctrl>_ctrl_scrhat_leave_out_vars`. Iterates over `l`-containing FB tests under scrhat which are conceptually invalid. | R1 chunk-9 New bugs:1 | R2 §Q4 | T3 | LOCKED — Phase 1 fix |
| A3 | **`va_scatter.do` figure-note `corr_*` vs `b_*` typos** at L308, L321, L333 (Fig 3 panel 1) and L417, L430, L442 (Fig 3-alt panel 1). Six lines say "Fitted line slope = `corr_*`" where they should say `b_*`. Panel 2 of each figure is correct. | R1 chunk-9 New bugs:3 | R2 §Q5 | T3 | LOCKED — Phase 1 fix; figures need re-rendering |
| A4 | **`reg_out_va_tab.do:47` declares `lasd_ct_p` in `sp_ct_p_combos`** but L117-120 / L219-222 column mapping covers only 4 columns; lasd rows silently dropped at L121/L223. Either Table 6 has 4 columns intentionally or the lasd combo is dead. | R1 chunk-9 New bugs:4 | R2 §Q6 | T4 (Christina to confirm intent) | OPEN |
| A5 | **`va_var_explain.do:20` `set trace on` without matching `set trace off`**. Produces massive log. (Sibling `va_var_explain_tab.do` L18/L126 is properly paired.) | R1 chunk-9 New bugs:5 | R2 §Q7 | T3 | LOCKED — Phase 1 fix |
| A6 | **`base_sum_stats_tab.do` is v1-only** (L182, L307, L152 hardcoded `_v1`; all `estimates save` paths use `va_cfr_all_v1/`). No v2 parallel. Sibling files iterate `foreach version in v1 v2` properly. | R1 chunk-9 New bugs:6 | R2 §Q8 | T4 (intentional?) | OPEN |
| A7 | **`base_sum_stats_tab.do:463-579` long sequence of `esttab ... append`** — failure mid-sequence leaves output file inconsistent. | R1 chunk-9 New bugs:7 | R2 §base_sum_stats_tab L463+ | T3 | LOCKED — Phase 1 robustness fix |
| A8 | **`sample_counts_tab.do` cascading `if`-filters duplicated 12 times for counts AND 12 times for z-scores** (24 total). A missing `&` would silently produce wrong rows. | R1 chunk-9 New bugs:8 | R2 §Q9 (verified 24 blocks) | T3 | LOCKED — Phase 1 refactor candidate |
| A9 | **`svyindex_tab.do:185` missing space after `translate`**. Path-token typo `translate$vaprojdir...`. Stata likely errors. | R1 chunk-9 New bugs:9 | R2 §svyindex L185 | T3 | LOCKED — Phase 1 fix |
| A10 | **`va_predicted_score.do` and `_fb.do` first-stage recomputed per iteration**. Wasteful but not wrong (dataset reloaded each iter, so cached macro wouldn't survive). | R1 chunk-9 New bugs:10 | R2 §11 (waste flag) | T3 | LOCKED — Phase 1 optimization |
| A11 | **`corr_dk_score_va.do` redundantly hardcodes** sample-control lists already in `macros_va_all_samples_controls.doh`. | R1 chunk-9 New bugs:11 | R2 §10 (no notable issues) | T3 | LOCKED — minor |
| A12 | **scrhat outputs go to `tables/explore/`, NOT `tables/share/va/pub/`** — exploratory only, not in paper. Both rounds confirm. | R1 §"scrhat... pipeline" diagram + bullet 4 | R2 §Q3e | T3 | LOCKED |
| A13 | **scrhat first-stage uses `lag2ela` regressor** to predict `prior_ela_z_score_hat`. Effective sample = original VA sample ∩ `lag2ela` non-missing (strict subset). | R1 §"scrhat (predicted-prior-score) pipeline" diagram | R2 §Q3 a-d | T3 | LOCKED |
| A14 | **`base_sum_stats_tab.do:152` hardcodes `create_prior_scores_v1.doh`** — even if a v2 toggle existed for the dataset, prior-scores would still be the v1 spec. | R1 §"sample restrictions" implicit | R2 §base_sum_stats L152 | T3 | LOCKED |

---

## ROUND-1-MISSED rows (round-2 found, round-1 did not)

### ~~M1 — `va_spec_fb_tab_all.do` column 6 (lasd) FB rows DROPPED~~ [REVISED: NOT A BUG, 2026-04-26]

- **Round-2 claim** (cross-cutting findings, Q2): The keeper rule at L82-84 covers `va_control` ∈ {b, a, las} but NOT `lasd`. Column 6 entry is explicitly truncated. Round-2 framed as paper-output integrity issue.
- **Christina correction (2026-04-26)**: This is **not a bug**. FB test structure: (1) estimate VA without certain controls, (2) estimate VA with those controls, (3) regress (residual difference) on round-1 VA. **When VA includes `lasd` (kitchen sink + distance), there are no more leave-out variables for the FB test.** Confirmed by `macros_va_all_samples_controls.doh:66-76`: `va_controls_for_fb` lists only `b l a s la ls as las` (excludes `lasd`); there is no `lasd_ctrl_leave_out_vars` macro defined.
- **T3 verification (just performed)**: read L66-76 of `macros_va_all_samples_controls.doh`. Confirmed structural property as Christina described.
- **Reconciliation**: Round-2 misread structural FB-test property as a producer bug. The keeper rule and `keep row entry1-entry5` truncation are CORRECT BY DESIGN — column 6 is the `lasd` (Distance INCLUDED IN VA SPEC) column, which has no FB rows because no leave-out variables remain.
- **Tier**: T4 (resolved by domain expertise).
- **Severity**: NIL. Removed from P1 list.
- **Action**: no fix needed. Phase 1 should preserve the structural design.

### ~~M2 — `va_spec_fb_tab_all.do` does NOT filter `predicted_score==0`~~ [REVISED: NOT A BUG, 2026-04-26]

- **Round-2 claim** (cross-cutting findings): the column-mapping at L71-76 doesn't filter on `predicted_score==0`. Round-2 framed as paper-output integrity issue.
- **Christina correction (2026-04-26)**: per the broader statement "this and other bugs you marked relating to the FB test are not actual bugs." Scrhat outputs go to `predicted_prior_score/` subdirs separately (per chunk-9 file 13 finding); not conflated in upstream regsave datasets that `va_spec_fb_tab_all.do` reads. No filter needed.
- **Tier**: T4 (resolved by domain expertise).
- **Severity**: NIL. Removed from P1 list.
- **Action**: no fix needed.

### Verification-protocol meta-finding from CB1/CB2 reclassification

Round-2's adversarial framing pushed it to flag candidate-bugs aggressively, including 4 findings (chunk-3 A13 distance-leave-out gap, chunk-9 M1 column 6 FB drop, chunk-9 M2 predicted_score filter, chunk-9 P2-7 va_predicted_score_fb.do lov list) that turn out to be structural FB-test properties. **The protocol does not equip round-2 to know FB-test theory; T4 (Christina) is the right adjudicator for "is this a bug or just a structural property?"**

**Lesson**: in future audits, when round-2 raises FB-test concerns, escalate to T4 BEFORE marking as P1/CRITICAL. Or include FB-test structure in the prompt upfront.

### M3 — `svyindex_tab.do:43` `use ... , replace` syntax error

- **Round-2 claim** (Q10 caveat, summary §9): `use $projdir/out/dta/factor/index`reg'withdemo/`type'_index_`reg'_wdemo, replace` — `use` does NOT accept `replace` option. Stata may error.
- **Round-1**: missed.
- **Tier**: T1 — Christina runs the file on Scribe and confirms whether it errors or silently swallows the token.
- **Severity**: HIGH if the file errors out (Table 8 wouldn't generate); LOW if Stata tolerates it.
- **Action**: T1 verify; Phase 1 fix.

### M4 — `kdensity.do` apparent missing close brace

- **Round-2 claim** (file 2 entry, summary §15): `foreach version in v1 v2` opens at L45; no visible matching close `}` before EOF (L128). Inner braces close at L68 (va_outcome) and L111 (va_type), but the outer version-loop close is missing.
- **Round-1**: missed.
- **Tier**: T1 — Christina runs the file or counts braces via `grep -c "^}"`.
- **Severity**: MEDIUM. Either Stata implicit-closes or errors.
- **Action**: T1 verify; Phase 1 fix.

### M5 — `va_var_explain_tab.do` 5 columns vs `va_var_explain.do` 5 controls produces silent drops

- **Round-2 claim** (file 9 entry): `va_var_explain.do:43` produces 5 controls (b, a, ls, las, lasd) but `va_var_explain_tab.do:48-52` only assigns 4 las-sample columns (b, b, b, las). The `ls` and `lasd` rows are silently dropped at L54 `keep if column!=.`.
- **Round-1**: did not flag this.
- **Tier**: T4 — intentional 4-column Table 7 layout, or oversight?
- **Severity**: MEDIUM-LOW. Same pattern as M1 (chunk-9 reg_out_va_tab.do A4) and chunk-4 file 4 mtitles question.
- **Action**: Phase 0e Q&A; Phase 1 sweep all `_tab.do` files for column-mapping silent drops.

---

## ROUND-2-MISSED rows (round-1 found, round-2 did not)

### N1 — Round-1 chunk-9 §"CORRECTION to chunk 8" (sum_stats archive disposition)

- **Round-1 claim**: chunk-9 round-1 explicitly noted that `share/sample_counts_tab.do` is the modern producer for `counts_k12.tex`, superseding `_archive/matt_original/sum_stats_tab.do`. So the chunk-8 alarm about archival was resolved in chunk 9's correction.
- **Round-2**: noted producer is `sample_counts_tab.do` but did not explicitly compare to the archived sum_stats_tab.do.
- **Reconciliation**: this isn't a finding round-2 missed; it's a chunk-cross-reference round-1 made. Both confirm `sample_counts_tab.do` is the modern producer. AGREE on substance.
- **Action**: no change.

---

## Adjudication & open questions

### Q1 — Column 6 FB drop (M1) — is this the answer to the chunk-3 distance-FB-row-6 mystery?

**Yes, very likely.** Combining:

- chunk 7 round-2: confirmed `d` token is wired in `macros_va_all_samples_controls.doh:69-86` and produces `fb_*_d_lv.ster` files at chunk-3 estimation time.
- chunk 3 round-2: noted `va_spec_fb_tab.do` (chunk 3) loops `lovar in l s a las` — does NOT include `d`.
- chunk 9 round-2 (M1): `va_spec_fb_tab_all.do` (chunk 9) maps column 6 to `va_control=="lasd"` BUT keeper rule does NOT cover `va_control=="lasd"` for FB. Result: column 6 FB rows are produced upstream but dropped at the table-builder.

**Resolution**: paper Table 2/3 column 6 is the "Distance" column (las + lasd = leave-out-score+ACS+sibling+distance). Spec-test row populated; FB rows blank. **The chunk-3 mystery resolves to a chunk-9 producer bug.**

**Phase 1 fix**: add `keeper=1 if va_control=="lasd" & inlist(fb_var, ...)` and update `keep row entry1-entryN`.

**Tier**: T1 — Christina verifies via the actual paper TeX file's Table 2/3 column 6. If FB rows are blank, M1 is confirmed paper-impacting.

### Q2 — `predicted_score==0` filter (M2)

**Tier**: T1.

### Q3 — `lasd_ct_p` and `ls`/`lasd` column drops (A4, M5)

**Tier**: T4 — column-count design decision for Phase 0e.

**Recommendation**: Phase 0e Q&A — settle column counts for Tables 6 and 7 once and for all.

### Q4 — `base_sum_stats_tab.do` and `sample_counts_tab.do` v1-only

**Tier**: T4 — intentional? If yes, document. If no, add v2 parallel.

---

## What changes for downstream chunks

- **Chunk 3 distance-FB-row-6 mystery is RESOLVED** by chunk-9 M1. Cross-reference in final synthesis.
- **mtitles audit pattern** continues: chunk 4 file 4 (24-vs-32 cols), chunk 5 reg_out_va_sib_acs_tab.do (FB-test mtitles for persistence), chunk 9 reg_out_va_tab.do (lasd col drop), chunk 9 va_var_explain_tab.do (5-col vs 5-control drop). Phase 1 sweep all `_tab.do` files.

## Outstanding items (chunk 9 specifically)

1. T1 verify: column 6 FB rows in paper Table 2/3 are blank (M1).
2. T1 verify: `predicted_score` filter in upstream regsave (M2).
3. T1 verify: `svyindex_tab.do` runs (M3).
4. T1 verify: `kdensity.do` brace structure (M4).
5. T4 escalation: lasd_ct_p drop intent (A4 / Q3).
6. T4 escalation: v1-only base_sum_stats / sample_counts (A6 / Q4).
7. T4 escalation: ls/lasd drop intent (M5 / Q3).
8. Phase 1 fixes: A2 (scrhat lov), A3 (corr/b typos), A5 (set trace), A7 (esttab append fragility), A8 (24 cascading filters refactor), A9 (translate space), A10 (first-stage recomputed), M1 (column 6 FB), M2 (predicted_score filter), M3 (use replace), M4 (kdensity brace).

---

## Verdict

**Strong agreement on chunk 9** (14 AGREE rows), with **TWO CRITICAL round-2 findings** (M1 and M2) that round-1 missed. M1 resolves the chunk-3 distance-FB-row-6 mystery: the producer bug drops column 6 FB rows from paper Tables 2 and 3. **HIGH PRIORITY for Phase 0e.**

The closed-loop paper-output mapping is locked. Phase 1 fixes can proceed with high confidence on chunk-9 producer files.
