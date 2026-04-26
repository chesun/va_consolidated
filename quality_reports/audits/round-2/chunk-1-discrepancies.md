# Chunk 1 — Discrepancy Report (Round-1 vs Round-2)

**Chunk:** 1 — Foundation (settings × 2, do_all.do, master.do, macros_va.doh, vam.ado × 2)
**Date:** 2026-04-26
**Round-1 source:** `quality_reports/audits/round-1/2026-04-25_deep-read-audit.md` §"Chunk 1: Foundation"
**Round-2 source:** `quality_reports/audits/round-2/chunk-1-verified.md`
**Adjudicator:** Claude (this turn) for AGREE rows + T3 verifications; T1/T2/T4 escalations flagged below.

---

## Methodology

- Read both rounds end-to-end.
- For every claim in either round, place it into one of: **AGREE**, **ROUND-1-MISSED**, **ROUND-2-MISSED**, **DISAGREE**, or **TEMPORAL ARTIFACT** (a fifth category I introduce because two of the apparent disagreements are explained by intervening fixes between rounds 1 and 2).
- For non-AGREE rows, propose tier (T1/T2/T3/T4) and verification path.
- Where I could verify on the spot via grep / diff / file read (T3 deterministic), I did, and report the result inline.

---

## Summary table

| Category | Count |
|---|---|
| AGREE | 17 |
| ROUND-1-MISSED (round 2 found something round 1 didn't) | 3 |
| ROUND-2-MISSED (round 1 had a finding round 2 didn't reproduce) | 4 |
| DISAGREE (substantive contradiction) | 0 |
| TEMPORAL ARTIFACT (apparent contradiction explained by intervening fix) | 2 |

**No genuine factual contradictions between the two rounds.** Two apparent contradictions reduce to "round 1 wrote before fix, round 2 wrote after." Three new bugs surfaced by round 2 that round 1 missed.

---

## AGREE rows

| # | Finding | R1 cite | R2 cite | T-tier (verification) | Status |
|---|---|---|---|---|---|
| A1 | Two-repo co-resident geometry: `$vaprojdir` = common_core_va, `$projdir` = caschls; both globals defined identically in both settings.do | R1 §settings.do:67 | R2 §Q1; settings.do entries | T3 (already verified by Claude pre-flight) | LOCKED |
| A2 | Both settings.do byte-near-identical (single trailing-newline difference) | R1 §settings.do:64 | R2 §settings.do diff result | T3 | LOCKED |
| A3 | 12 globals defined in settings.do (`rawcsvdir`, `rawdtadir`, `clndtadir`, `projdir`, `vaprojdir`, `vadtadir`, `cstdtadir`, `nscdtadir`, `nscdtadir_oldformat`, `mattxwalks`, `vaprojxwalks`, `distance_dtadir`) | R1 §settings.do:27-40 | R2 globals table | T3 | LOCKED |
| A4 | `do_all.do` toggle state as committed: only `clean_sch_char=1` (L72) and `do_va_het=1` (L238); all other blocks 0 | R1 §do_all.do:79, 86, 97 | R2 toggle table | T3 | LOCKED |
| A5 | `do_all.do` L253 hardcoded absolute path `do "/home/research/ca_ed_lab/users/chesun/gsr/caschls/do/master.do"` (no `$projdir` expansion) | R1 §do_all.do:98, 100 | R2 path-references inventory | T3 | LOCKED |
| A6 | Cross-repo wiring is one-way: `do_all.do` → `master.do` (L253) and `do_all.do` → `$projdir/do/share/sibling*` (L126-142). `master.do` does NOT call back into cde_va_project_fork. | R1 §master.do:128 (no callbacks documented); call-graph diagram | R2 §Q1 "Cross-repo references (one-way)" | T3 (grep) | LOCKED |
| A7 | `master.do` toggle state: 13 blocks ON (do_build_data, do_check_data, do_diagnostics, do_response_rate, do_clean_sec_qoi, do_clean_parent_qoi, do_clean_staff_qoi, do_pool_qoi_merge, do_pool_gr11_enr, do_va_regs, dofactor, do_index, do_index_va_reg). 4 OFF (installssc, do_match_siblings, dooutcomesumstats, do_sibling_va_regs) | R1 §master.do:131-146 | R2 toggle table | T3 | LOCKED |
| A8 | `master.do` L109-117 is an empty placeholder ("THIS IS WHERE TO RUN THE VA ESTIMATES DO FILES") — VA estimation is NOT driven from master.do; it consumes outputs via `clean_va.do` (L341) | R1 §master.do:155 | R2 §master.do:Notes | T3 | LOCKED |
| A9 | Sibling-matching block is duplicated: do_all.do L121-144 and master.do L82-105 have the same 4 sub-calls (siblingmatch, uniquefamily, siblingpairxwalk, siblingoutxwalk) | R1 §master.do:131; synthesis §"Anomalies":5 | R2 §Q4 "Duplicated logic" | T3 | LOCKED |
| A10 | Sibling block has 4 calls, NOT 5 | R1 §master.do:161 | R2 §master.do:do_match_siblings table row | T3 | LOCKED |
| A11 | `vam.ado` L1 still claims `*! version 2.0.1 27jul2013 Michael Stepner` even though the file has been modified | R1 §vam.ado:Update + Fixes | R2 §vam.ado:Customization evidence | T3 | LOCKED |
| A12 | `vam.ado` `noseed` option exists in syntax declaration L26; the original check at L252 references undefined macro `seed`, making `noseed` a no-op in original | R1 §vam.ado:Gotchas; Anomalies:4 | R2 §Q2 "The bug in the original" | T3 (verified) | LOCKED |
| A13 | `server_vam/vam.ado` exists as a sibling subdirectory; preserves the original-buggy version | R1 §vam.ado:Update | R2 §server_vam/vam.ado | T3 | LOCKED |
| A14 | `vam.ado` `set seed 9827496` is hardcoded at L256 of patched / L253 of original | R1 §vam.ado:Gotchas | R2 §vam.ado L256; server_vam L253 | T3 | LOCKED |
| A15 | `macros_va.doh` `#delimit ;` block runs L19 to L612 | R1 §macros_va.doh:226 | R2 §macros_va.doh L19/L612 | T3 | LOCKED |
| A16 | `macros_va.doh` foreach loop L298-307 has a peer-side asymmetry: `peer_<X>d_controls` does NOT append `d_controls`, while non-peer `<X>d_controls` does | R1 §macros_va.doh:216, 235; Anomalies:asymmetry deferred | R2 §macros_va.doh:Gotchas L298-307; Bug 4 | T2 (intentional or bug?) — needs to check downstream consumers | OPEN — see Adjudication §Q1 |
| A17 | 22 hardcoded path expressions across 5 files; cross-user dependency on `msnaven` (`$mattxwalks`) | R1 §settings.do:50; do_all.do gotchas; master.do gotchas; synthesis | R2 §Q5 hardcoded-path inventory | T3 | LOCKED |

---

## ROUND-1-MISSED rows (round-2 found, round-1 did not)

### M1 — `macros_va.doh` L23 missing trailing `;`

- **Round-2 claim** (Bug #3 in R2 summary): `local vaprojdofiles "$vaprojdir/do_files"` at L23 has NO trailing `;` under `#delimit ;`. Under that delimiter, statements must end in `;`. The next statement at L24 is then parsed as part of the macro value, corrupting both `vaprojdofiles` and `ca_ed_lab`.
- **Round-1**: missed entirely. Round-1 did flag a missing-semicolon bug, but at L558 (`prop_ecn_disadv_str`), and noted it was FIXED in commit `e8dd083`. The file had TWO missing-`;` bugs; only one was caught and fixed.
- **T3 verification (just performed):** I read L20-30 of `cde_va_project_fork/do_files/sbac/macros_va.doh` and confirmed:
  - L22: `local home $vaprojdir ;` — has `;`
  - L23: `local vaprojdofiles "$vaprojdir/do_files"` — **no `;` (BUG CONFIRMED)**
  - L24: `local ca_ed_lab "/home/research/ca_ed_lab" ;` — has `;` (would be parsed as part of L23 value due to L23 missing terminator)
  - L25-31: all have `;`
- **Tier**: T3 (deterministic, already verified). **Confirmed bug.**
- **Severity**: Latent if `$vaprojdofiles` and `$ca_ed_lab` are never consumed; high otherwise. Round-2 noted the consumer-search question. R1 already had a `[LEARN]`-style fix workflow for the L558 bug; same pattern applies.
- **Action**: file as bug for Phase 1 fix. Re-read commit `e8dd083` to confirm only L558 was fixed and L23 was untouched. Add to bug inventory as Bug #102 (or whatever next index).

### M2 — `macros_va.doh` L342-345 `l_scrhat_spec_controls` pattern break

- **Round-2 claim** (Bug #5 in R2 summary): `l_scrhat_spec_controls` is defined in terms of `b_spec_controls + loscore`, but uses `b_spec_controls` (the non-scrhat version) instead of `b_scrhat_spec_controls`. The surrounding `_scrhat_spec_controls` macros (L362, L382, L402, L422, etc.) DO use the scrhat base. Looks like a copy-paste bug.
- **Round-1**: missed entirely. Round-1 documented the schema (`<combo>_scrhat_spec_controls` substitutes `b_scrhat_spec_controls` for the base, line 218) but did not check whether each macro in the family actually does so.
- **Tier**: T3 (deterministic — read L342-345 and L362 and compare).
- **Severity**: depends on whether `l_scrhat_spec_controls` is ever invoked. Need to grep consumers.
- **Action**: T3 verify (post-discrepancy-report) and add to bug inventory if confirmed.

### M3 — `macros_va.doh` `Xd_str` aliases all collapse to `X_str`

- **Round-2 claim** (Bug #6 in R2 summary): every `Xd_str` (X ∈ {b, l, a, s, la, ls, as, las}) at L485, 493, 501, 509, 517, 525, 533, 541 is set equal to `X_str`. So the postsecondary-distance variant has no distinct display label; tables built from these strings cannot tell distance from non-distance.
- **Round-1**: noted this in passing for `asd_str=a_str` (which it identified as a TYPO and fixed in `e8dd083`), but did not generalize to the pattern that ALL `Xd_str` aliases are intentional. Round-1 fixed `asd_str=a_str` to `asd_str=as_str` based on a typo-hypothesis (noting that `<combo>d_str = <combo>_str` was the surrounding pattern).
- **Reconciliation**: Round-1's typo fix (asd_str → as_str) is consistent with round-2's reading of the pattern. The asd_str line was anomalous for being `a_str` instead of `as_str` (i.e., it broke the distance-collapse pattern by using the wrong base). After fix, asd_str now collapses to `as_str` (i.e., follows the pattern). The pattern itself — that the `d` suffix is collapsed in the display — is what round-2 elevated to a finding.
- **Tier**: T2 or T4 — interpretation. Is the pattern intentional (the display string for "base + distance" is meant to read as just "base", relying on table column ordering or other context to convey the distance variant), or unintentional (display strings should distinguish)?
- **Severity**: Cosmetic at worst, factual at best (depends on whether the pattern shows up in published tables in a way that would mislead readers).
- **Action**: defer to T4 — Christina to review the schema intent.

---

## ROUND-2-MISSED rows (round-1 had finding, round-2 did not reproduce)

### N1 — Adopath finding (local vam.ado is dead code today)

- **Round-1 claim** (R1 §vam.ado Update 2026-04-25, bullet "Critical operational finding"): NO `adopath ++` or `sysdir set` invocation exists anywhere in either repo. The local `caschls/do/ado/vam.ado` is therefore not on the Stata search path at runtime. Stata's default adopath would look for `./ado/` not `./do/ado/`. So in current predecessor pipeline runs, the SSC vam (installed via `ssc install vam, replace`) is what fires.
- **Round-2**: addressed the same question but landed on uncertainty: "Stata should load the top-level (patched) version by default — assuming the working directory has `./do/ado/` on the path or the file is in the user's PERSONAL or PLUS dir... I see NO `adopath` modification. So Stata should load the top-level (patched) version by default..."
- **Reconciliation**: round-1 says local vam is dead code (server uses SSC vam). Round-2 says local vam IS loaded (because there's no adopath modification, but it's "by default"). **These appear to disagree but actually agree on the underlying fact**: no adopath modification exists. The differences are:
  - **Stata default adopath behavior**: round-1 says default does NOT include `./do/ado/`; round-2 says it does (or at least suggests it might).
  - **Which version is currently loaded**: round-1 says SSC vam (which has the bug); round-2 says local patched vam.
- **This is a factual sub-disagreement.** Stata's actual default adopath rules: `./` (current dir), `./PERSONAL/`, `./PLUS/` (where SSC ends up). It does NOT include `./do/ado/` automatically. **Round-1 is correct.**
- **Tier**: T1 — empirical (run `adopath` from the Scribe shell after `cd $projdir`; show the output). Or T3 if we have enough info from `which vam` output. Christina has access; this is a 30-second test on Scribe.
- **Severity**: Material for replication: it determines whether `noseed` was effectively-respected at the time of the most recent pipeline run. Round-1 says no (SSC bug active); round-2 implies yes (local patched version active).
- **Action**: T1 test — Christina runs `adopath` and `which vam` on Scribe with cwd at `$projdir`, reports output. Add to T1 list.

### N2 — vam invocation patterns: 40+ across 13 files inventoried

- **Round-1 claim** (R1 §vam.ado "Beyond `i.year`: full vam-invocation compatibility verification"): inventoried every option-set used across all `vam` calls (including `teacher(school_id)`, `class(school_id)`, `controls()` with `i.year` + cubic, `data() = merge tv score_r` or `variance`, `driftlimit`, `estimates`). Verified against published v2.0.1 syntax. Conclusion: published Stepner v2.0.1 handles every invocation; no customization required.
- **Round-2**: did not perform this inventory (it's outside the chunk-1 file scope; round-1's inventory traversed downstream chunks).
- **Reconciliation**: not a true gap — round-2's scope was only the 6+ chunk-1 files. The vam-invocation inventory naturally lives in chunks 3-5 (where vam is called). Round-2 will (or has, in chunk-3 round-2) re-derive this.
- **Tier**: N/A — not a chunk-1 finding strictly. **No action.**

### N3 — `_scrhat_` ≠ v1/v2 conceptual finding

- **Round-1 claim** (R1 §macros_va.doh:230, 441): `_scrhat_` is the predicted-prior-score variant (added 8/22/2024). The user-flagged v1/v2 distinction is about prior-score controls more broadly (`create_prior_scores_v1.doh` / `_v2.doh`). Round-1 explicitly flagged: "Need to verify if `_scrhat_` is one of the v2 variants or orthogonal."
- **Round-2**: described `_scrhat_` mechanically (uses `prior_ela_z_score_hat`) but did not address the conceptual question of whether `_scrhat_` is a v2 variant.
- **Reconciliation**: not a conflict — round-2 documented the WHAT, round-1 raised the WHY. The conceptual question is downstream of chunk 1 (resolves in chunks 2-3 where `prior_ela_z_score_hat` is generated).
- **Tier**: T4 — defer to Christina; or resolved in chunk-2 round-2 (which I just received: round-2 chunk-2 confirms `prior_ela_z_score_hat` is generated only in `va_predicted_score.do` and `va_predicted_score_fb.do`, both under `do_files/explore/`). So `_scrhat_` is exploratory, not v2.
- **Action**: roll into Phase 0e Q&A. **Resolved**: `_scrhat_` is orthogonal to v1/v2; it is the exploratory predicted-score axis (third axis), per chunk-2 round-2 finding.

### N4 — `asd_str` typo (round-1 found and fixed; round-2 did not mention)

- **Round-1 claim** (R1 §macros_va.doh:233; Anomalies:1): bug at L535 — `asd_str = a_str` (should be `as_str` per surrounding pattern). FIXED in commit `e8dd083`.
- **Round-2**: did not mention `asd_str` directly; treated all `Xd_str` aliases uniformly under M3.
- **Reconciliation**: round-2 read post-fix; the bug was already corrected at the time round-2 ran. No discrepancy.
- **T3 verification (just performed):** L533-535 of current file reads:
  ```
  local asd_str
      `as_str'
      ;
  ```
  Confirmed fix. **No action.**

---

## TEMPORAL ARTIFACTS (apparent contradiction explained by intervening fixes)

### TA1 — vam.ado customization status

- **Round-1**: "no Christina/Matt modifications visible" → updated post-foundation: "Christina ran the diff; server_vam matches; no Christina/Matt modifications. Bottom line: there is no custom vam." Then a later update: "noseed bug fixed in `caschls/do/ado/vam.ado` at commit `0202251` (caschls)."
- **Round-2**: "vam.ado customized: 4-line bugfix at L252-255 dated 2026-04-25." "server_vam/vam.ado is the original buggy version."
- **Reconciliation**: round-1's first-pass read was BEFORE the noseed fix was applied (file was clean Stepner v2.0.1). Christina then ran the diff (confirmed no customization at THAT moment). Then I (Claude) applied the noseed fix at commit `0202251` on 2026-04-25. Round-2 read AFTER that commit and correctly identified the 4-line modification. Both rounds are correct in their respective temporal contexts.
- **Current ground truth**: `caschls/do/ado/vam.ado` IS customized (4-line noseed fix added by Claude 2026-04-25). `caschls/do/ado/server_vam/vam.ado` preserves the original Stepner-v2.0.1 unmodified. Round-2's read is the current state.
- **Action for Phase 1**: ADR-0009 (custom vam handling) should reflect the noseed fix as a deliberate customization, not an accident. Update vam.ado's `*!` line to `*! version 2.0.1.1 2026-04-25 (noseed-fix) — based on Stepner 2.0.1 27jul2013` so provenance is legible.

### TA2 — `macros_va.doh` missing-semicolon location (L23 vs L558)

- **Round-1**: bug at L558 (`prop_ecn_disadv_str` missing trailing `;`). FIXED in commit `e8dd083`.
- **Round-2**: bug at L23 (`vaprojdofiles` missing trailing `;`). Still open.
- **Reconciliation**: the file had TWO missing-`;` bugs. Round-1 caught L558 and fixed it; round-1 missed L23 entirely. Round-2 read post-fix (L558 now has `;`) and caught the still-broken L23. No contradiction — round-2 found a genuine new bug (M1 above).
- **Action**: see M1 — file L23 as new bug.

---

## Adjudication & open questions

### Q1 — `peer_<X>d_controls` asymmetry (A16, intentional vs bug)

The peer-side foreach branch in macros_va.doh L298-307 sets `peer_<X>d_controls` = `peer_<X>_controls` ALONE, omitting the `peer_d_controls` append. There is no `peer_d_controls` defined anywhere in the file. Both rounds flagged this; neither resolved it.

**Possible interpretations**:

1. **Intentional**: peer means of `mindist_any_nonprof_4yr` and `mindist_ccc` are degenerate or non-meaningful at the school level (since distance is from school to nearest college, the "peer mean of distance" is trivially the same as the school's own distance for school-FE samples). Therefore omitting them in peer-side d-augmented specs is correct.
2. **Unintentional**: the peer arm should append a peer version of `d_controls`, which someone forgot to define.

**Tier**: T2 (third agent, "find evidence one or the other interpretation is correct") OR T4 (Christina knows whether peer-distance is meaningful in this design).

**Recommendation**: T4. Christina is the cheaper resolver. If she confirms (1), round-2 can update Bug 4 to "intentional asymmetry (T4-confirmed)".

### Q2 — Local vam.ado adopath status (N1)

Round-1 says SSC vam was the live version on past pipeline runs. Round-2 implies local patched vam is. Resolves whether `noseed` worked in pre-fix runs.

**Tier**: T1 — Christina runs `adopath` + `which vam` on Scribe.

**Recommendation**: add to T1 list (alongside Bug 93 NSC UC test).

### Q3 — L23/M1 corrupted macros: which (if any) consume `$vaprojdofiles` and `$ca_ed_lab`?

If these macros are never read, the L23 bug is latent and downgrades to LOW severity. Round-2 already flagged this as an open question.

**Tier**: T3 — grep across all `.do` and `.doh` files.

**Recommendation**: post-discrepancy-report deterministic check.

### Q4 — L342-345/M2 corrupted: is `l_scrhat_spec_controls` ever consumed?

Same logic as Q3.

**Tier**: T3.

**Recommendation**: same as Q3.

---

## What changes for downstream chunks

- The vam.ado customization ground truth is round-2's (current state). Round-1's "no custom vam" framing in chunks 2-10 should be re-read with this in mind. **Cross-chunk audit needed**: any downstream finding that says "vam unmodified" needs to be reframed to "vam unmodified pre-2026-04-25, noseed-patched after."
- Bug 93 (chunk 10 NSC UC) PLUS chunk-2 round-2 just found two more inlist-precedence bugs (CCC `ccc_enr_ontime`, CSU `csu_enr_ontime` in `merge_k12_postsecondary.doh:168-170, 232-234`). The Bug 93 family is bigger than initially scoped. Will be addressed in chunk-2 discrepancy report.

## Outstanding items (for chunk-1 specifically)

1. T1 test: `adopath` + `which vam` on Scribe (Christina).
2. T3 grep: consumers of `$vaprojdofiles`, `$ca_ed_lab`, `l_scrhat_spec_controls`.
3. T4 escalation: `peer_<X>d_controls` asymmetry intent (Christina).
4. T4 escalation: `Xd_str` display-string collapse intent (Christina).
5. Phase 1 fix: macros_va.doh L23 missing `;` (paired with already-fixed L558 fix from `e8dd083`).
6. Phase 1 fix: macros_va.doh L342-345 `l_scrhat_spec_controls` pattern break (if confirmed used).
7. Phase 1: update vam.ado `*!` version line to reflect the 2026-04-25 customization (provenance hygiene).

---

## Verdict

**No genuine contradictions between rounds.** Round-2 surfaced 3 new bugs round-1 missed (L23 missing `;`, L342-345 pattern break, `Xd_str` collapse). Round-1 caught 2 things round-2 didn't restate (adopath analysis, vam invocation inventory) — the first is a sub-disagreement that goes to T1, the second is out of chunk-1 scope. Two apparent contradictions (vam customization status, missing-`;` location) are temporal artifacts of intervening fixes and resolve cleanly.

The verification approach is working: round-2 caught real bugs round-1 missed without spurious noise.
