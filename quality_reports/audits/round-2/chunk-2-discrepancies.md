# Chunk 2 — Discrepancy Report (Round-1 vs Round-2)

**Chunk:** 2 — VA-core helpers (~21 files: SBAC sample-construction `.doh`, prior-score doh, merge helpers, `vafilemacros.doh`, `vaestmacros.doh`)
**Date:** 2026-04-26
**Round-1 source:** `quality_reports/audits/round-1/2026-04-25_deep-read-audit.md` §"Chunk 2: VA-core helpers"
**Round-2 source:** `quality_reports/audits/round-2/chunk-2-verified.md`
**Adjudicator:** Claude (this turn) for AGREE rows + T3 verifications.

---

## Summary table

| Category | Count |
|---|---|
| AGREE | 11 |
| ROUND-1-MISSED | 5 |
| ROUND-2-MISSED | 4 |
| DISAGREE — round-2 reporting error confirmed by T3 | 1 |
| TEMPORAL ARTIFACTS | 1 |

**Headline finding**: Round-2 caught two NEW Bug-93-family operator-precedence bugs (CCC `ccc_enr_ontime` and CSU `csu_enr_ontime` in `merge_k12_postsecondary.doh`). Bug 93 is no longer just an NSC UC issue; it is a code-pattern that recurs in three places. **High priority for Phase 1 fix**.

**One round-2 reporting error**: Round-2 reported `asd_str` typo at L533-535 still active. T3 read of the current file shows it has been fixed (commit `e8dd083`). The fix predates round-2's read; the round-2 agent appears to have either mis-read or hallucinated the typo. Documented as a confirmation-bias-style false positive — exactly the kind of error this verification protocol exists to catch.

---

## AGREE rows

| # | Finding | R1 cite | R2 cite | Tier | Status |
|---|---|---|---|---|---|
| A1 | v1 prior-score table verified line-by-line; matches paper map exactly. ELA: L3-cst (2015), L3-cst (2016), L4-cst (2017), L3-sbac (2018). Math: L5-cst, L5-cst, L5-cst, L3-sbac. | R1 §create_prior_scores_v1.doh table | R2 §Q1 v1 table | T3 (already verified by primary read) | LOCKED |
| A2 | v2 prior-score table: code uses L5 = 5-year lag (NOT grade 5). Cohorts 2015-2017 use spring-2010/11/12 6th-grade ELA (NOT spring 2012/13/13 as the v2 file's docstring claims). v2 docstring is a transcription bug. | R1 §create_prior_scores_v2.doh table; chunk-2 synthesis "v2 vs user's table — RESOLVED 2026-04-25" | R2 §Q1 v2 table | T3 (Christina confirmed 2026-04-25); deferred fix to docstring | LOCKED |
| A3 | `_scrhat_` is a third axis, orthogonal to v1/v2 (not v3). `prior_ela_z_score_hat` is generated only in `va_predicted_score.do` and `va_predicted_score_fb.do` under `do_files/explore/`. | R1 §"_scrhat_ resolution" | R2 §Q2 | T3 | LOCKED |
| A4 | `create_diff_school_prop.doh`: 2-line file. Year==2017 carve-out (uses L4 instead of L3) handles the spring-2014 SBAC test-skip transition. Load-bearing logic. | R1 §create_diff_school_prop.doh | R2 §create_diff_school_prop.doh | T3 | LOCKED |
| A5 | `merge_k12_postsecondary.doh:7` HARDCODED ABSOLUTE PATH `/home/research/ca_ed_lab/projects/common_core_va/data/restricted_access/clean/crosswalks/`. Must parameterize for consolidation. | R1 §merge_k12_postsecondary.doh:Bugs:1 | R2 §Q7 Bug 1 | T3 | LOCKED |
| A6 | `merge_k12_postsecondary.doh:326-327` `enr` definition NSC/CCC/CSU asymmetry: `enr=1` requires NSC (CCC/CSU commented out), but `enr=0` requires NSC=0 AND CCC!=1 AND CSU!=1. Students never matched to NSC end up `enr=.` even with positive CCC/CSU. May be intentional NSC-anchoring; needs T4 (Christina). | R1 §merge_k12_postsecondary.doh:Bugs:2 | R2 §Q7 Bug 20; gotchas | T4 | OPEN — needs Christina |
| A7 | `vaestmacros.doh:27` (and L99 for outcomes): filename ends `.dta.dta` — duplicated extension. | R1 §vaestmacros.doh:Bugs | R2 §Q7 Bug 6 | T3 | LOCKED |
| A8 | `vaestmacros.doh:45, 118`: missing `$` prefix on `vaprojdir`. Resolves to literal directory `vaprojdir/` rather than the global. **Two `.ster` paths affected.** | R1 §vaestmacros.doh:Bugs | R2 §Q7 Bug 5 | T3 | LOCKED |
| A9 | `create_va_sample.doh:50` `keep if conventional_school==1` is a HARDER drop than `touse_va.do:102`'s `replace touse=0 if conventional_school!=1`. | R1 §create_va_sample.doh:Gotchas | R2 §create_va_sample.doh:Gotchas (line 50 description) | T3 | LOCKED |
| A10 | `create_va_sample.doh:52, 54` comments describe restrictions (≥25% special-ed, home/hospital instruction) that are NOT implemented in code. Either upstream in `va_samples.dta` or never applied. | R1 §create_va_sample.doh:Gotchas | R2 §Q7 Bug 9 | T4 (Christina to confirm where) | OPEN |
| A11 | `vafilemacros.doh` defines `va_g11_dataset` under `$projdir/dta/common_core_va/...` but `vaestmacros.doh:19` routes test-score VA estimates to `$vaprojdir/data/sbac/...`. Inputs from caschls; outputs to fork. Cross-repo triangulation. | R1 §vafilemacros.doh:Discrepancy | R2 §vafilemacros.doh:Gotchas | T3 | LOCKED |

---

## ROUND-1-MISSED rows (round-2 found, round-1 did not)

### M1 — `merge_k12_postsecondary.doh:168-170` operator-precedence bug for `ccc_enr_ontime`

- **Round-2 claim** (Q7 Bug 2, HIGH): `gen ccc_enr_ontime = 1 if ccc_enr==1 & A | B` — `&` binds tighter than `|`, so it parses as `(ccc_enr==1 & A) | B`. The second `|` clause fires regardless of `ccc_enr`. **Same code pattern as Bug 93** (the NSC UC inlist precedence bug at chunk 10).
- **Round-1**: missed entirely.
- **Tier**: T1 — Christina runs Stata test on Scribe (similar pattern to Bug 93 T1 test).
- **Severity**: paper-load-bearing if `ccc_enr_ontime` is a paper outcome variable. (The paper's Table 3 reports enr_2year and enr_4year — `ccc_enr_ontime` is upstream of those via the multi-source enr derivation.) HIGH.
- **Action**: file as Bug 102 (or appropriate index). Add to T1 Stata test list. Possibly the same root cause as Bug 93; if Christina's bugfix template handles all three (UC, CCC, CSU), wrap as a single Phase 1 patch.

### M2 — `merge_k12_postsecondary.doh:232-234` operator-precedence bug for `csu_enr_ontime`

- **Round-2 claim** (Q7 Bug 3, HIGH): same operator-precedence bug for CSU.
- **Round-1**: missed entirely.
- **Tier**: T1.
- **Severity**: HIGH (parallel to M1).
- **Action**: file with M1; treat as a single bug class (Bug 93 family).

**Combined with the chunk-10 Bug 93 (NSC UC and NSC UC ontime), the inlist-precedence error appears 4 times across this codebase (NSC UC, NSC UC ontime, CCC ontime, CSU ontime).** Phase 1 fix should sweep all 4. Worth checking for additional instances by greppable pattern: `& inlist(...) | inlist(...)` without outer parens.

### M3 — `merge_k12_postsecondary.doh:67` asymmetric merge keep-rules

- **Round-2 claim** (Q7 Bug 7, MEDIUM): NSC SSID merge uses `keep(1 3 4 5)` + `update` while CCC/CSU merges use plain `keep(1 3)`. Asymmetric. May be intentional (NSC has updated vintages that overwrite master) but undocumented.
- **Round-1**: noted "L67 keep mode is `keep(1 3 4 5)` — non-standard; codes 4 and 5 mean using-takes-master-values via update" but did NOT compare against the CCC/CSU merge rules.
- **Reconciliation**: Round-2 elevated round-1's observation to a documented asymmetry. Not a true round-1 miss; round-1 was incomplete in highlighting why this matters.
- **Tier**: T4 — Christina to confirm intent.
- **Action**: defer to Phase 0e Q&A.

### M4 — `create_prior_scores_v1.doh:22-23` math has no year-2017 override

- **Round-2 claim** (Q7 Bug 10, MEDIUM): Math branch has no `year==2017` override analogous to ELA. The `inrange(year, caaspp_min_year+3, caaspp_max_year+3)` evaluation for 2017 is `inrange(2017, 2018, 2022)=false`, so the SBAC branch does NOT fire; CST branch at L22 fires using `L5_cst_math_z_score`. **Works** but only because of date arithmetic — visually non-obvious.
- **Round-1**: did NOT explicitly check this safety case for math. Round-1's table verified math behavior cohort-by-cohort but did not note the structural asymmetry between ELA and math in handling year 2017.
- **Tier**: T3 verifiable; not a bug — robustness/code-clarity concern only.
- **Action**: document as "code is correct but fragile" anomaly. No code change in Phase 1; possibly a comment in Phase 1's consolidated `create_prior_scores.doh`.

### M5 — `create_va_g11_out_sample.doh:15` tempfile name collision (`va_g11_dataset` not `va_g11_out_dataset`)

- **Round-2 claim** (Q7 Bug 11, MEDIUM): `tempfile va_g11_dataset` saved in `create_va_g11_out_sample.doh` collides with `create_va_g11_sample.doh`'s tempfile of the same name. Tempfile is a `local` macro; second call overwrites first if both helpers run in the same Stata session.
- **Round-1**: flagged this in §create_va_g11_out_sample.doh: "Tempfile name `va_g11_dataset` collides with the score variant's tempfile if both helpers are sourced in one session — verify no caller does this in Chunk 3+."
- **Reconciliation**: BOTH ROUNDS HAVE IT. So this is actually an AGREE not a M5. Moving to AGREE list (A12).

(Adding to AGREE retroactively as A12; correcting M5.)

| A12 | `create_va_g11_out_sample.doh:15` tempfile name collision: same name `va_g11_dataset` as test-score variant's tempfile. | R1 §create_va_g11_out_sample.doh | R2 §Q7 Bug 11 | T3 | LOCKED — same finding both rounds |

---

## ROUND-2-MISSED rows (round-1 had finding, round-2 did not reproduce)

### N1 — `create_va_sample.doh:26` keepusing list missing `peer_L3_cst_ela_z_score`

- **Round-1 claim**: keepusing list does NOT include `peer_L3_cst_ela_z_score`, but `create_prior_scores_v1.doh:16` references it. Possible silent bug — `peer_prior_ela_z_score` may be missing for STAR-era cohorts in the `_g11_` pipeline.
- **Round-2**: did not report this. Round-2 noted: "Line 41 `keepusing(gr11_*_diff_school_prop)` — wildcard merge; downstream references will fail silently." But did not check the L3-peer omission specifically.
- **Tier**: T3 — grep `peer_L3_cst_ela_z_score` and confirm consumers.
- **Action**: post-discrepancy-report deterministic check.

### N2 — Sample-restriction map: `<7` vs `<=10` 11th-grader cut

- **Round-1 claim**: code has `<7` not `<=10`. Worth verifying against paper Table A.1 wording.
- **Round-2**: noted "Could not find `7` as a hard threshold in any chunk-2 file. The closest filter is line 57 of `create_va_sample.doh` (`cohort_size<=10`), which is school-level not school-year-level. Need to audit downstream estimation files for the N=7 cutoff."
- **Reconciliation**: Round-1 located the `<7` cutoff in `touse_va.do:155`. Round-2 didn't — `touse_va.do` lives in chunks 7-8, not chunk 2. Not a true round-2 miss; it's a chunk-boundary issue.
- **Action**: defer to chunk 7-8 discrepancy.

### N3 — `vaestmacros.doh:18, 89` `, replace` embedded inside macro values

- **Round-1**: did not note this calling-convention oddity.
- **Round-2** (Q7 Bug 17, LOW): `local x_va_dta "$vaprojdir/data/sbac/va_g11_*.dta, replace"` — the comma plus `replace` is embedded inside the macro value. Works only if caller uses macro inside a `save` command.
- **Reconciliation**: This is a NEW finding by round-2 (not previously caught). It's actually a ROUND-1-MISSED, not ROUND-2-MISSED. Reclassifying:

| M6 | `vaestmacros.doh:18, 89` macro values include `, replace`. Calling convention only works if dereferenced inside `save`. | — | R2 §Q7 Bug 17 | T3 | LOCKED — round-1 missed |

### N4 — `vaestmacros.doh:1-5` author docstring "macro management is unmaintainable"

- **Round-1**: noted "L1-5 header acknowledges maintenance debt: 'does not include estimates from the sibling acs restricted sample. Too much bloating.'"
- **Round-2** (Q7 Bug 19, LOW): same finding, slightly different phrasing.
- **Reconciliation**: AGREE. Not a discrepancy. Moving to AGREE retroactively as A13.

| A13 | `vaestmacros.doh:1-5` author docstring acknowledges macro-management debt. Refactor target for consolidation. | R1 §vaestmacros.doh:Bugs | R2 §Q7 Bug 19 | T3 | LOCKED |

(Reclassifying. Updated category counts: AGREE=13, ROUND-1-MISSED=5, ROUND-2-MISSED=2.)

### N5 — Naming-convention catalog completion (after chunk 2)

- **Round-1**: after chunk 2, produced a 17-row naming-convention catalog covering `b/l/a/s/d/_p/peer_/_str/_fb_/_scrhat_/_dta/_spec_va/_l4/_census/_sibling/_og/_vam/_nosibctrl`.
- **Round-2** (Q3): "tokens `sp`, `ct`, `nw`, `_m`, `_wt` not found; defer." — narrower scope; only checked the 5 specific user-flagged tokens.
- **Reconciliation**: not a true miss — round-2 was scoped to verifying the deferred tokens, not to producing a fresh catalog. Both arrive at the same conclusion (those 5 tokens live downstream).
- **Action**: no change.

### N6 — Real round-2 miss: ssc/community packages used in chunk-2 helpers

- **Round-1**: did not enumerate package usage by chunk.
- **Round-2** (per-file): notes `rangestat` usage in `merge_loscore.doh:31`, `merge_sib.doh:15`, `merge_va_smp_acs.doh:110`. Properly inventoried.
- **Reconciliation**: this is a ROUND-1-MISSED. Reclassifying as M7.

| M7 | `rangestat` is used in 3 chunk-2 helpers (`merge_loscore.doh:31`, `merge_sib.doh:15`, `merge_va_smp_acs.doh:110`). Must be in installssc list. | — | R2 per-file | T3 | LOCKED |

---

## DISAGREE — round-2 chunk-2 reporting error

### D1 — `macros_va.doh:533-535` `asd_str` status

- **Round-2 claim** (Q7 Bug 4, HIGH): `asd_str` set to `` `a_str' `` ("ACS") instead of `` `as_str' `` ("ACS & sibling"). Mislabeled output for asd combo.
- **Round-1**: this bug WAS real, was caught in round-1, and was FIXED in commit `e8dd083` on 2026-04-25 (the same day round-1 was written).
- **T3 verification (just performed)**: read L530-545 of current `cde_va_project_fork/do_files/sbac/macros_va.doh`:
  ```
  L533: local asd_str
  L534:	`as_str'
  L535: 	;
  ```
  **`asd_str` is set to `` `as_str' ``, NOT `` `a_str' ``. Round-2 chunk-2 misreported.**
- **Git log confirms**: commit `e8dd083 fix(macros_va.doh): asd_str typo + missing semicolon under #delimit ;` is the only commit touching this file since the bug was introduced.
- **Verdict**: **round-2 chunk-2 made a confirmation-bias-style false positive.** The agent saw a known bug pattern (typo where one variant aliases to a too-short base) and asserted it without verifying the current bytes.
- **Tier**: T3 (just performed). **No bug; round-2 wrong.**
- **Action**: discount Q7 Bug 4 from the chunk-2 verified bug list. The verification protocol catches the false positive — this is exactly why we run two rounds. **Note: this is a round-2 error, not a round-1 miss; the protocol works in both directions.**

---

## TEMPORAL ARTIFACTS

### TA1 — `macros_va.doh:535` asd_str status (related to D1)

The asd_str typo was a real bug (round-1 finding), fixed in commit `e8dd083`. Round-1 wrote pre-fix; round-2 wrote post-fix. The discrepancy in D1 is partially a temporal artifact (round-1 reported the pre-fix state correctly) and partially a round-2 error (round-2 reported the bug as still present, when it had been fixed).

**Conclusion**: D1's underlying claim (the bug was real) is correct; D1's current-status claim from round-2 is wrong.

---

## Adjudication & open questions

### Q1 — Bug 93 family extent (M1, M2, plus chunk 10's NSC UC + NSC UC ontime)

The same operator-precedence pattern (`& inlist(...) | inlist(...)` without outer parens) appears 4 times in `merge_k12_postsecondary.doh` and `crosswalk_nsc_outcomes.do` combined.

**Tier**: T1 — Christina runs a small Stata test on Scribe to confirm the bug fires and to estimate impact magnitude.

**Recommendation**: bundle all 4 instances as a single Phase 1 fix:
1. NSC UC: `crosswalk_nsc_outcomes.do:218-219` (chunk 10 Bug 93)
2. NSC UC ontime: `crosswalk_nsc_outcomes.do:226-228` (chunk 10 Bug 93 part 2)
3. CCC ontime: `merge_k12_postsecondary.doh:168-170` (this chunk M1)
4. CSU ontime: `merge_k12_postsecondary.doh:232-234` (this chunk M2)

Plus a regression test: grep for the pattern `& inlist\(.*\) | inlist\(` (no outer parens) across all .do/.doh files. If matches found, flag for review.

### Q2 — `enr=.` for NSC-non-matched-but-CCC-or-CSU-positive students (A6)

Round-2's reading is the more rigorous interpretation: students who never matched to NSC end up with missing `enr` regardless of CCC/CSU positivity. The commented-out `| ccc_enr==1 | csu_enr==1` in the L326 `gen` shows this was intentional at some point. Either:

- **Intent**: treat NSC as the primary outcome anchor (CCC/CSU are confirmatory only); students unmatched to NSC contribute no observation to the postsecondary VA.
- **Bug**: someone commented out the OR clauses to test, never restored.

**Tier**: T4 — Christina knows the design intent.

### Q3 — `keep(1 3 4 5)` + `update` for NSC SSID merge (M3)

**Tier**: T4 — Christina knows whether NSC has multi-vintage update protocol.

### Q4 — Where are the un-implemented restrictions enforced? (A10)

**Tier**: T4 + downstream chunks. Likely `va_samples.dta` upstream in chunks 7-8.

### Q5 — `peer_L3_cst_ela_z_score` consumer existence (N1)

**Tier**: T3 (grep).

---

## What changes for downstream chunks

- **Bug 93 family**: chunk-10 discrepancy report should be amended to reflect that "Bug 93" is no longer just NSC UC; it's a 4-instance pattern across `crosswalk_nsc_outcomes.do` and `merge_k12_postsecondary.doh`. Phase 1 patch should bundle.

- **Round-2 false positive**: D1 demonstrates that round-2 agents can also produce confirmation-bias errors, not just round-1. The four-tier T3 verification (deterministic file read) caught this one. Going forward, all "still-broken" claims about typos previously fixed in round-1 should be T3-verified before locking.

## Outstanding items (chunk 2 specifically)

1. T1 test: Bug 93 family on Scribe (4 instances).
2. T3 grep: `peer_L3_cst_ela_z_score` consumers.
3. T3 grep: regression test for `& inlist(...) | inlist(...)` pattern across all do/doh.
4. T4 escalation: NSC-anchoring intent for `enr` definition (A6).
5. T4 escalation: NSC `keep(1 3 4 5)` + `update` intent (M3).
6. T4 escalation: where are special-ed/home-instruction restrictions enforced? (A10).
7. Phase 1 fix: macros_va.doh L23 missing `;` (this one chunk 1, applied to chunk 2 only via consumer trace).
8. Phase 1 fix: Bug 93 family (bundled).

---

## Verdict

**One genuine round-2 reporting error (D1, asd_str false positive).** Round-2 still net-positive: caught 5 things round-1 missed (M1, M2, M3, M4, M6/M7), including TWO HIGH-severity Bug 93 family members. Round-1 caught 2 things round-2 didn't or undercounted (N1, N2). The verification protocol is working as designed: catches bugs in both directions, including confirmation-bias errors by either round.

**Bug 93 family is the dominant material finding from chunk-2 round-2.** Elevates Phase 1 priority for the inlist-precedence sweep.
