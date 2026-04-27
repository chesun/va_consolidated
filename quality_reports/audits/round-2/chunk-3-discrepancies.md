# Chunk 3 — Discrepancy Report (Round-1 vs Round-2)

**Chunk:** 3 — VA-core estimation (14 .do files + 2 .doh helpers): `va_score_all`, `va_out_all`, `va_score_fb_all`, `va_out_fb_all`, `va_*_sib_lag`, `merge_va_est`, `va_corr`, spec/fb test-tab files, `va_spec_fb_tab`, `va_sib_lag_spec_fb_tab`, `drift_limit.doh`, `out_drift_limit.doh`
**Date:** 2026-04-26
**Round-1 source:** `quality_reports/audits/round-1/2026-04-25_deep-read-audit.md` §"Chunk 3: VA-core estimation"
**Round-2 source:** `quality_reports/audits/round-2/chunk-3-verified.md`
**Adjudicator:** Claude (this turn) for AGREE rows + T3 verifications.

---

## Summary table

| Category | Count |
|---|---|
| AGREE | 13 |
| ROUND-1-MISSED | 4 |
| ROUND-2-MISSED | 1 |
| DISAGREE | 0 |
| TEMPORAL ARTIFACTS | 0 |

**Headline finding from chunk 3**: BOTH rounds independently surface the **distance-leave-out (`d`) FB-test row gap** in `va_spec_fb_tab.do` — the published table builder loops `lovar in l s a las` and does NOT include `d`. This is now the main open question for paper Table 2/3 row 6 attribution. **High priority for T4 escalation.**

---

## AGREE rows

| # | Finding | R1 cite | R2 cite | Tier | Status |
|---|---|---|---|---|---|
| A1 | `sp / ct / lv` are LITERAL filename separators, not macros. Output filename grammar formalized. | R1 §"sp / ct / lv resolved" | R2 §Q1 | T3 | LOCKED |
| A2 | `nw / _m / _wt` NOT FOUND in chunk 3 — defer to figure-generation chunks (4+). | R1 §"nw / _m / _wt STILL NOT FOUND" | R2 §Q1 final paragraph | T3 (grep) | LOCKED |
| A3 | Output-filename construction grammar: `<prefix>_[p_][dk_]_<outcome>_<sample>_sp_<va_ctrl>_ct[_<fb_var>_lv].ster` | R1 §"Output-filename grammar" | R2 §"Output-filename construction grammar (formalized)" | T3 | LOCKED |
| A4 | All ~24 vam invocations using `data(merge tv score_r)` are followed by both `rename tv ...` and `rename score_r ...`. No silent overwrite vulnerabilities. | R1 §"vam invocation summary" | R2 §Q5 (full enumeration) | T3 | LOCKED |
| A5 | `drift_limit.doh` (4 lines) is the active helper; defines BOTH `score_drift_limit` and `out_drift_limit`. With current data both = 2. | R1 §"drift_limit usage" | R2 §drift_limit.doh entry; Q4 table | T3 | LOCKED |
| A6 | `out_drift_limit.doh` is DEAD CODE — never include'd anywhere in chunk 3. | R1 §"drift_limit usage" | R2 §out_drift_limit.doh entry; Q4 | T3 (grep) | LOCKED — propose deletion in Phase 1 |
| A7 | `va_out_sib_lag.do` L56, L97, L119 uses `score_drift_limit` for OUTCOME VA — should be `out_drift_limit`. Numerically benign today (both = 2) but semantically wrong. Latent bug. | R1 §"drift_limit usage" Exception | R2 §Q7 Bug 2 | T3 | LOCKED — Phase 1 fix |
| A8 | `va_out_all.do:176` typo: `dk_spec_p_..._cts.ster` (extra `s`) instead of `_ct.ster`. Currently no consumer fails because nothing loads `dk_spec_p_*` from chunk-3 files. | R1 §"New bugs:1" | R2 §Q7 Bug 1 + va_out_all entry L176 | T3 | LOCKED — Phase 1 fix |
| A9 | `va_out_fb_test_tab.do` L173-174: missing `log close` and `translate` at end of file (asymmetric vs score variant L187-189). | R1 §"New bugs:3" | R2 §Q7 Bug 3 | T3 | LOCKED — Phase 1 fix |
| A10 | `va_out_spec_test_tab.do:163` uses `sd_va` (no-peer) when assembling the predicted-score peer row; should be `sd_va_peer`. | R1 §"New bugs:4" | R2 §Q7 Bug 4 (more detailed) | T3 | LOCKED — Phase 1 fix |
| A11 | `va_sib_lag_spec_fb_tab.do:70` uses `p_value` while other tab files use `pval` per change-log convention. Inconsistency bug. | R1 §"New bugs:9" | R2 §Q7 Bug 12 | T3 | LOCKED — Phase 1 fix |
| A12 | Spec-test β estimator: `reg <outcome>_r va_cfr_g11_<outcome>, cluster(school_id)`. Cited at multiple lines. | R1 §"Spec-test / FB-test β tracing" | R2 §Q6 table | T3 | LOCKED |
| ~~A13~~ | ~~Distance leave-out (`d`) gap in `va_spec_fb_tab.do`~~ — **RESOLVED NOT-A-BUG (Christina 2026-04-26)**: structural FB-test property. `va_controls_for_fb` (`macros_va_all_samples_controls.doh:66`) excludes `lasd` — kitchen-sink VA has nothing left to leave out. Column 6 of paper Tables 2/3 is `lasd` (Distance INCLUDED IN VA SPEC, not as leave-out). Spec-test row populated; FB rows correctly blank. | R1 §"Spec-test / FB-test β tracing" Row 6 anomaly | R2 §Q7 Bug 9; Q2 final paragraph; Open Question 1 | T4 → RESOLVED | LOCKED |

---

## ROUND-1-MISSED rows (round-2 found, round-1 did not)

### M1 — `va_corr.do` typos and stray text

- **Round-2 claim** (Q7 Bug 5, 6, 7): `va_corr.do:82` `local date2` never assigned; di prints empty string. L57 typo "ase sample" should be "base sample". L60 typo "ktichen" should be "kitchen".
- **Round-1**: caught the date2 issue (R1 New bugs:8) but missed the di-string typos.
- **Tier**: T3 — verifiable.
- **Action**: Phase 1 fix — fix typos and define date2 (or remove the di line).

### M2 — `va_spec_fb_tab.do` typos "ase sample" and "ktichen"

- **Round-2 claim** (Q7 Bug 8): same typos as `va_corr.do`. These show that one file copied di strings from another.
- **Round-1**: missed.
- **Tier**: T3.
- **Action**: Phase 1 — sweep both files.

### M3 — `va_score_fb_test_tab.do:51, 179` `set trace off` is dead

- **Round-2 claim** (Q7 Bug 18): `/* set trace on */` (commented) at L51 paired with active `set trace off` at L179 — the latter is dead because trace was never on.
- **Round-1**: missed.
- **Tier**: T3.
- **Action**: Phase 1 cleanup.

### M4 — `merge_va_est.do:87-90` master merge assumes (cdscode, year) unique without explicit `keep if grade==11`

- **Round-2 claim** (Q7 Bug 20): `merge 1:1 cdscode year using` — depends on upstream sample construction to enforce uniqueness.
- **Round-1**: did not flag this. Round-1 noted the dynamic command-swapping pattern as "elegant idiom worth preserving" but did not check the uniqueness assumption.
- **Tier**: T3 — confirm upstream sample construction enforces grade==11 + uniqueness.
- **Severity**: latent. Robust today (project is grade-11-only); fragile to future scope changes.
- **Action**: Phase 1 — add explicit `assert` or `keep if grade==11` defensive guard before merge.

---

## ROUND-2-MISSED rows (round-1 had finding, round-2 did not reproduce)

### N1 — `va_*_fb_all.do` files re-estimate the no-FB baseline VA without saving (duplicates work)

- **Round-1 claim** (New bugs:6): `va_score_fb_all.do` and `va_out_fb_all.do` re-estimate the no-FB baseline VA without saving — duplicates work already done by `va_score_all.do` / `va_out_all.do`. Optimization target during consolidation.
- **Round-2**: did not raise this efficiency observation. Round-2's Q5 vam audit confirms reseted vam calls but does not flag the redundancy with `va_*_all.do`.
- **Tier**: T3 verifiable; this is an optimization observation, not a correctness bug.
- **Action**: defer to Phase 1 consolidation; refactor opportunity to read pre-computed .ster from disk in `va_*_fb_all.do` baseline path.

---

## Adjudication & open questions

### Q1 — Distance FB-test row attribution (A13)

The question both rounds raised is: **what does paper Table 2/3 row 6 actually contain?**

**Two competing interpretations**:
1. **Paper map's interpretation**: Row 6 is the "distance to nearest 2yr/4yr college" FB test (lovar = `d`).
2. **Code's interpretation**: Row 6 is the joint `las` FB test (loscore + ACS + sibling), since `va_spec_fb_tab.do` does NOT load `d` but DOES load `las`.

Possible reconciliation:
- The published paper used `las` (joint) but the paper map mis-described it as `d`.
- The published paper used `d` and a separate file produces row 6 (NOT `va_spec_fb_tab.do`); we should look for a `va_spec_fb_tab_distance.do` or similar in chunk 9 (share/).
- Paper Table 2/3 has 4 FB rows (l, s, a, las) and the paper map's "distance" was a separate addendum table.

**Tier**: T4 — Christina to confirm paper Table 2/3 actual row 6 content (read the paper PDF or her own memory).

**Recommendation**: high-priority resolve in Phase 0e Q&A. **This is the main scope-defining open question for chunk 3.**

### Q2 — Output filename grammar consolidation (A3)

Both rounds converged on the same grammar. Phase 1 should adopt a single consolidated naming convention. The asymmetry between filename `_p_` infix (peer) and variable-name `_p` suffix (which means peer in some places and predicted in others — Q7 Bug 21 in round 2) should be normalized.

**Tier**: T4 (design decision in Phase 0e).

### Q3 — `merge_va_est.do` defensive guard (M4)

**Tier**: T3 — verify upstream construction enforces grade==11 & uniqueness, then add defensive `assert` in Phase 1.

---

## What changes for downstream chunks

- **Chunk 4** (pass-through, `reg_out_va_all*.do`): chunk-3 round-2 confirms that pass-through ρ regression is NOT in chunk 3. Chunk 4 producer of paper Table 4 should be re-verified in chunk-4 discrepancy report.
- **Chunk 9** (share/explore): potential producer of distance-FB row 6 (if it exists separately). Watch for `va_spec_fb_tab_distance.do` or similar.
- **The output-filename grammar (A3)** is now LOCKED across chunks 3 and chunk 1's convention. Phase 1 settings.do consolidation can rely on this grammar for path globbing.

## Outstanding items (chunk 3 specifically)

1. T4 escalation: paper Table 2/3 row 6 = `d` or `las`? (A13/Q1)
2. T3 verify: `merge_va_est.do` upstream uniqueness (M4).
3. T3 grep: confirm no consumer of `dk_spec_p_*_cts.ster` exists (the L176 typo) anywhere in the project.
4. Phase 1 fix: 7 chunk-3 bugs catalogued in AGREE (A7-A11) + 4 in ROUND-1-MISSED (M1-M4).
5. Phase 1 cleanup: dead-code deletions (out_drift_limit.doh, dead set-trace, dead touse_dk flags).
6. Phase 1 consolidation refactor: `va_*_fb_all.do` baseline-VA redundancy (N1).

---

## Verdict

**Strong agreement between rounds on chunk 3.** Round-2 found 4 minor things round-1 missed (typos, dead trace toggles, latent uniqueness assumption). Round-1 found 1 thing round-2 didn't (efficiency observation about duplicate baseline-VA estimation). **Zero genuine contradictions.** The shared open question — paper Table 2/3 row 6 attribution — is downstream of chunk 3 and gates resolution of the distance-FB-test mystery that has accumulated across chunks 3, 4, 5.

The verification approach is settling into a stable pattern: round-1 caught most things; round-2 catches typos round-1 sometimes glossed; both rounds independently flag the high-stakes structural questions.
