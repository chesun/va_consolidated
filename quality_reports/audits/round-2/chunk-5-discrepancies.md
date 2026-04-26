# Chunk 5 — Discrepancy Report (Round-1 vs Round-2)

**Chunk:** 5 — Sibling crosswalk + sibling-VA regressions (32 files: 3 in `caschls/do/share/siblingxwalk/` + 29 in `caschls/do/share/siblingvaregs/`)
**Date:** 2026-04-26
**Round-1 source:** `quality_reports/audits/round-1/2026-04-25_chunk5-sibling.md` (companion doc) + summary at `2026-04-25_deep-read-audit.md` §"Chunk 5"
**Round-2 source:** `quality_reports/audits/round-2/chunk-5-verified.md`
**Adjudicator:** Claude (this turn).

---

## Summary table

| Category | Count |
|---|---|
| AGREE | 14 |
| ROUND-1-MISSED | 6 |
| ROUND-2-MISSED | 4 |
| DISAGREE | 0 |
| TEMPORAL ARTIFACTS | 0 |

**Headline findings:**

1. **N1 verdict reaffirmed** — both rounds independently conclude `siblingoutxwalk.do` is SAFE to relocate to `siblingxwalk/`, with the same proviso (update 2 callers in `master.do:103` and `do_all.do:142`).

2. **NEW: mtitles labeling bug** in `reg_out_va_sib_acs_tab.do` L82-88 — uses FB-test column titles ("Original w/ Census Leave Out", etc.) for what is a persistence-on-VA regression table. **HIGH PRIORITY** if these CSVs feed paper Table 7.

3. **NEW: ACS spec missing from combined panels** in `reg_out_va_sib_acs_fig.do` L213-216, L309-317 and `reg_out_va_sib_acs_dk_fig.do` L131-135. Combined panels show og/sib/both but not acs. May be intentional (4-graph layout) or content gap.

4. **DK controls anomaly verified** — `va_sib_acs_out_dk.do` L64 hard-codes `va_ela_og va_math_og` as DK control vector across all 4 specs (og/acs/sib/both). Both rounds flagged. **T4 question** for Christina: intentional design choice (single OG baseline) or bug (DK should be spec-matched)?

5. **Round-2 found 32 files, not 33** — `reg_out_va_sib_acs_dk_tab.do` listed in round-1 file count does not actually exist. Only the `_fig.do` counterpart is present.

---

## AGREE rows

| # | Finding | R1 cite | R2 cite | Tier | Status |
|---|---|---|---|---|---|
| A1 | **N1 SAFE to relocate `siblingoutxwalk.do` to `siblingxwalk/`** with proviso: update `master.do:103` and `do_all.do:142` (the only 2 callers; both reference source path explicitly). All consumers read OUTPUT dataset by absolute path, so move-of-source-file does not break them. | R1 §"N1 — siblingoutxwalk.do relocation: SAFE" | R2 §N1 verdict | T3 (already verified) | LOCKED — UNBLOCKS ADR-0004 |
| A2 | 4-spec `og/acs/sib/both` convention — defined inline in each VAM call, not centralized. Control vectors per spec match: og = base; acs = +census; sib = +sibling; both = +census+sibling. | R1 §"4-spec convention" | R2 §"4-Spec Convention" | T3 | LOCKED |
| A3 | Transitive closure via SSC `group_twoway` package at `uniquefamily.do:32`, args `(siblings_name_address_year, state_student_id)`. | R1 §"Sibling-matching specifics" | R2 §d (Transitive closure) | T3 | LOCKED |
| A4 | Address join: 5-component `street_address_line_one street_address_line_two city state zip_code` (plus `last_name` and `year` in some keys). Inconsistency: duplicates report uses 6 keys, egen group uses 7 (zip_code in egen but not duplicates). | R1 §"Sibling-matching specifics" + Bugs:2 | R2 §a (address join) | T3 | LOCKED |
| A5 | No surname normalization (no upper, no lower, no trim, no accent). Last_name used as-is. | R1 (implicit) | R2 §b (Surname) | T3 | LOCKED |
| A6 | 10-child cap at `uniquefamily.do:53`: `drop if numsiblings >= 9`. | R1 §"Sibling-matching specifics" + ADR candidate | R2 §uniquefamily entry quality filters | T3 | LOCKED — NEEDS ADR |
| A7 | `numsiblings_exclude_sef` typo in `uniquefamily.do:56` (should be `_self`). | R1 §"7 new bugs:3" | R2 §uniquefamily L56 | T3 | LOCKED — Phase 1 fix |
| A8 | DK controls (`va_sib_acs_out_dk.do:64`) hard-coded to `va_ela_og va_math_og` across ALL 4 specs (og/acs/sib/both). Both rounds flagged. | R1 §Q5.2 (DK controls fixed on `_og` test-score VA across all 4 specs — intentional or bug?) | R2 §"DK Controls — answer to N7" | T4 (Christina) | OPEN — needs Christina |
| A9 | `va_sibling.do:291` collapse adds `if sibling_full_sample == 1 & sibling_out_sample == 1`; `va_sibling_out.do:327-331` does NOT. Asymmetric but harmless (both already filter at load time). | R1 §"7 new bugs:4" | R2 §"Sibling Sample Filter Consistency" | T3 (verified harmless) | LOCKED — cosmetic asymmetry |
| A10 | SE clustering: heterogeneity regs in `reg_out_va_sib_acs.do` and `reg_out_va_sib_acs_dk.do` cluster on `cdscode`; main regs cluster on `school_id`. Same flag as chunk-4 `va_het.do:158`. | R1 §"7 new bugs:5" | R2 §"SE Clustering Audit" | T3/T4 (need cdscode≡school_id check) | OPEN |
| A11 | `vaestmacros.doh` L45, L118 missing `$` prefix on `vaprojdir` (resolves to literal directory). Already noted in chunk-2 disc report; chunk-5 also reads it. | R1 chunk-2 §vaestmacros.doh; chunk-5 N/A | R2 §5 (vaestmacros entry) | T3 | LOCKED — Phase 1 fix |
| A12 | Drift-limit default = 2 in `va_sibling.do` and `va_sibling_out.do` (formula `max(2018-2015-1, 1) = 2`). | R1 §"Positional arg `0` semantics" | R2 §"Positional arg `0` semantics — formula" | T3 | LOCKED |
| A13 | `siblingpairxwalk.do:24` rename `middle_intl sibling_middle_intl` works because `middle_intl` IS in `siblingmatch.do:16-18` keep list. Round-1's claim "doesn't include middle_intl" was incorrect. **Round-2 verified** middle_intl IS kept. | R1 §"7 new bugs:1" (claimed bug) | R2 §uniquefamily L47 (verified middle_intl IS kept) | T3 | LOCKED — round-1 false positive resolved by R2 |
| A14 | Cross-repo data flow: `siblingoutxwalk.do` reads K-12 from `$vaprojdir`, runs `merge_k12_postsecondary.doh` from `$vaprojdir`, writes output to `$projdir`. Clean cross-repo handoff. | R1 §"Cross-repo integration" (chunk-5 details) | R2 §"Cross-repo integration" | T3 | LOCKED |

---

## ROUND-1-MISSED rows (round-2 found, round-1 did not)

### M1 — `reg_out_va_sib_acs_tab.do` L82-88 mtitles labeling bug

- **Round-2 claim** (HIGH PRIORITY): The `esttab_mtitles` macro is the **forecast-bias-test mtitles** ("Original w/ Census Leave Out", "Original w/ Sibling Leave Out", "Census w/ Sibling Leave Out", "Sibling w/ Census Leave Out") — but this CSV is the persistence/regression-on-VA output, NOT a forecast-bias test. Correct mtitles should be "Original Specification" / "Census Controls" / "Sibling Controls" / "Sibling and Census Controls".
- **Round-1**: missed entirely.
- **Tier**: T1/T4 — verify the CSVs feed paper tables (Table 7 candidate); if so, fix is HIGH severity. Need Christina to confirm paper-table fidelity.
- **Severity**: HIGH if these CSVs feed paper Table 7. Mislabels paper output column headers.
- **Action**: T4 escalate; Phase 1 fix to use correct mtitles.

### M2 — ACS spec missing from combined panels in `reg_out_va_sib_acs_fig.do` and `reg_out_va_sib_acs_dk_fig.do`

- **Round-2 claim**: `reg_out_va_sib_acs_fig.do` L213-216, L309-317 and `reg_out_va_sib_acs_dk_fig.do` L131-135 omit `acs` spec from `graph_combine`. Combined panels show og/sib/both only.
- **Round-1**: missed entirely.
- **Tier**: T4 — Christina to confirm intent. If 4-panel layout was deliberate (og + sib + both + original sample = 4 panels), then exclude is intentional. If acs should be included, panels need to expand to 5.
- **Severity**: content gap, depends on whether ACS-only spec results appear in the paper.
- **Action**: Phase 0e Q&A.

### M3 — `siblingmatch.do:49` `egen group ..., mi` flag mega-family risk

- **Round-2 claim**: The `, mi` flag treats missing values as same-group. Students with missing address fields can collapse into a single "mega-family". Partially mitigated by L22 dropping near-empty addresses (`<=1` char), but two students with same last_name and missing `street_line_two` could still merge.
- **Round-1**: missed entirely. Round-1 documented address-join components but did not flag the `, mi` semantics.
- **Tier**: T1 (Christina runs Stata diagnostic on Scribe to estimate magnitude) or T3 grep for `, mi` patterns.
- **Severity**: depends on missing-rate of address fields among matched siblings. Could affect sibling-sample size and quality.
- **Action**: T1 diagnostic — count `ufamilyid` values where `numsiblings >= 5` and check if they're real or mega-family artifacts.

### M4 — `va_sibling_fb_test_tab.do` L64, L91 trailing-space typo in macro reference

- **Round-2 claim**: `estimates use \`\`subject\'_fb_va_sibling \''` — trailing space INSIDE the macro reference. Stata may either complain or silently look up an empty macro.
- **Round-1**: missed entirely.
- **Tier**: T3 (verifiable via direct read).
- **Severity**: latent. Either fails at runtime or produces empty estimate set.
- **Action**: Phase 1 fix.

### M5 — File count is 32, not 33: `reg_out_va_sib_acs_dk_tab.do` does not exist

- **Round-2 claim**: prompt listed 33 files but `reg_out_va_sib_acs_dk_tab.do` doesn't exist (only the `_fig.do` counterpart is present).
- **T3 verification (just performed)**: `grep -n "reg_out_va_sib_acs_dk_tab" round-1/2026-04-25_chunk5-sibling.md` returns ZERO matches. Round-1's detailed chunk-5 doc does NOT contain an entry for the non-existent file. Round-1's *summary* line (in `2026-04-25_deep-read-audit.md` §Chunk 5) says "33 files" but does not enumerate the missing file specifically. **Round-1 was NOT fabricated; the count was just off-by-one in the summary.**
- **Where the fabrication actually lived**: I (Claude, this turn) wrote the round-2 prompt from the round-1 summary and added `reg_out_va_sib_acs_dk_tab.do` by symmetry assumption (paired with `_dk_fig.do`). **My prompt was wrong, not round-1.**
- **Tier**: T3 — already verified.
- **Severity**: NIL — round-1 was correct; my prompt-construction was off; round-2 caught the prompt error.
- **Action**: note this as a verification-protocol finding: the protocol catches prompt-construction errors too, not just audit errors. Update my prompt-construction discipline: when drafting round-2 prompts, copy file lists verbatim from round-1's detailed companion docs (not from summary line counts).
- **Note**: this corrects an earlier framing in the round-2 chunk-5 verified doc that implied round-1 fabrication. Round-2's observation ("file does not exist") is correct; the inference about round-1 fidelity was based on my imprecise prompt. Round-1's audit fidelity for this chunk is unblemished.

### M6 — `siblingpairxwalk.do:53-57` concat() pair-direction normalization fragility

- **Round-2 claim**: `concat(state_student_id)` returns string with separator "" by default, so `"1234" + "5"` ("12345") could clash with `"123" + "45"` ("12345"). Edge case but real.
- **Round-1**: missed.
- **Tier**: T3 (verifiable) but unlikely to hit in production data (state_student_id is fixed-width per CDE).
- **Severity**: latent edge case.
- **Action**: Phase 1 — add a separator to `concat`. Defensive only.

---

## ROUND-2-MISSED rows (round-1 had finding, round-2 did not)

### N1 — `va_sib_acs_*` files lack `args setlimit` for drift-limit override

- **Round-1 claim**: older sibling-only files (`va_sibling`, `va_sibling_out`) accept positional arg `0` for drift-limit override; the newer 4-spec files (`va_sib_acs*`) hardcode the formula. If 4-spec drift fails in the future, manual code edit required.
- **Round-2**: did not explicitly flag this asymmetry. Round-2 verified the formula matches but didn't note the missing `args setlimit` mechanism in the 4-spec variant.
- **Tier**: T4 — design decision. Whether to add the `args setlimit` to the 4-spec files is a Phase 1 architectural choice.
- **Action**: Phase 0e Q&A.

### N2 — Naming-system fragmentation across sibling-VA files

- **Round-1 claim**: older sibling-only uses `_sibling/_nosibctrl/_nocontrol`; 4-spec files use `og/acs/sib/both`; `va_sibling_out_forecast_bias.do` uses ad-hoc tokens. Major consolidation hazard. Recommend standardizing on `og/acs/sib/both`.
- **Round-2**: documented the multiple naming systems in the token glossary but did not characterize as a "fragmentation hazard" requiring consolidation.
- **Tier**: T4 — design decision for Phase 1.
- **Action**: Phase 0e Q&A. Christina mentioned interest in standardizing.

### N3 — Dual-output pattern: PDFs to BOTH $projdir/out/graph/ AND $vaprojdir/figures/

- **Round-1 claim**: many post-est diagnostic files write PDFs to BOTH paths. Path-rerouting must update both during consolidation.
- **Round-2**: did not flag. (Round-2 documented per-file outputs but did not surface the dual-output pattern as a class.)
- **Tier**: T3 — verifiable.
- **Action**: Phase 1 consolidation: collapse to single output path (figures/) per `figures.md` rule.

### N4 — `vafilemacros.doh` L21 `siblingxwalk` is unused dead local

- **Round-1 claim**: `local siblingxwalk` defined but appears unused — dead local.
- **Round-2**: defined the local but did not check usage.
- **Tier**: T3 (grep).
- **Action**: post-disc-report deterministic check.

---

## Adjudication & open questions

### Q1 — DK controls intentionality (A8)

`va_sib_acs_out_dk.do:64` hard-codes `va_ela_og va_math_og` as DK control across all 4 specs. The fact that `create_va_sib_acs_out_restr_smp.do:85` ALSO uses `va_<subject>_og` for the DK touse is consistent — the design treats OG as the deep-knowledge baseline. But this means the DK regressions are NOT spec-matched (the standard econometric approach would match DK controls to spec).

**Tier**: T4 — Christina confirms design intent.

**If intentional**: document as ADR-0010-style decision — "DK regressions use OG baseline as deep-knowledge anchor across all specs to maintain comparability across specs."

**If bug**: Phase 1 fix to use spec-matched DK controls.

### Q2 — mtitles bug paper-table fidelity (M1)

**Tier**: T4 — does `reg_out_va_sib_acs_tab.do` produce CSV → TeX → paper table with the wrong column headers? If yes, Phase 1 fix is paper-load-bearing.

### Q3 — Round-1 fabricated file entry? (M5)

**Tier**: T3 — read `quality_reports/audits/round-1/2026-04-25_chunk5-sibling.md` and check if `reg_out_va_sib_acs_dk_tab.do` has a per-file entry. If so, that entry was fabricated.

### Q4 — `egen group ..., mi` mega-family risk (M3)

**Tier**: T1 — Christina runs diagnostic on Scribe.

### Q5 — Naming standardization to og/acs/sib/both (N2)

**Tier**: T4.

---

## What changes for downstream chunks

- **N1 verdict locked**: `siblingoutxwalk.do` relocation to `siblingxwalk/` is SAFE. Phase 0e ADR-0004 is unblocked. Two callers need updating in Phase 1: `master.do:103`, `do_all.do:142`.
- **mtitles bug** is a discovery from chunk 5 that should affect Phase 0e Q&A (need to map chunk-5 CSVs → paper tables). Cross-reference with the chunk-9 share/explore audit (when batch 4 dispatches), since `do_files/share/` likely has the CSV → TeX rendering step.
- **DK controls T4 question** combines with chunk-3's distance-FB-row-6 question as the major Phase 0e walkthrough items.
- **File count discrepancy (M5)** is the third confirmation-bias-style finding from the verification protocol (after asd_str false-positive and peer_L3_cst false-positive). Pattern: round-1 may have hallucinated content for non-existent files. T3 verify by reading round-1 chunk-5 doc.

---

## Outstanding items (chunk 5 specifically)

1. T1 test: `egen group ..., mi` mega-family risk diagnostic (M3).
2. T3 verify: round-1 chunk-5 doc has a fabricated `reg_out_va_sib_acs_dk_tab.do` entry? (M5/Q3)
3. T3 grep: `\`siblingxwalk'` macro consumers in vafilemacros.doh L21 (N4).
4. T3 grep: dual PDF output paths in chunk-5 files (N3).
5. T4 escalation: DK controls intentionality (A8).
6. T4 escalation: mtitles paper-table fidelity (M1).
7. T4 escalation: ACS spec missing from combined panels (M2).
8. T4 escalation: 4-spec drift-limit override architecture (N1).
9. T4 escalation: naming standardization (N2).
10. Phase 1 fixes: numsiblings_exclude_sef (A7), trailing-space macro reference (M4), concat separator (M6), vaestmacros $ prefixes (A11), mtitles (M1), DK controls if intentional (A8).
11. Phase 1 ADR: 10-child cap documentation (A6).

---

## Verdict

**Strong agreement on the foundational findings (N1, 4-spec, transitive closure).** Round-2 surfaced 6 new items round-1 missed including the **HIGH-priority mtitles bug** and the **possibly-fabricated round-1 file entry (M5)** — the third confirmation-bias finding from the protocol. Round-1 caught 4 design/architecture issues round-2 didn't characterize but instead enumerated mechanically.

**Total verification protocol confirmed errors so far: 3 — distributed across rounds AND prompt construction**:
1. Round-2 chunk-2 asd_str false positive (caught by T3).
2. Round-1 chunk-2 peer_L3_cst false positive (caught by T3).
3. **My round-2 prompt's spurious `reg_out_va_sib_acs_dk_tab.do` filename** (caught by round-2; T3 confirmed the file doesn't exist and round-1 didn't claim it did).

The protocol is paying off — surfacing audit fidelity issues that would otherwise have been carried forward. **All three errors caught are different in nature**: a round-2 false-positive (Stata code typo claim), a round-1 false-positive (keepusing list claim), and a prompt-construction artifact (spurious filename). The four-tier T3 deterministic check resolves all three with high confidence.
