# T3 Deterministic Verifications — Phase 0a-v2

**Purpose:** Resolve the deterministic-check items flagged in chunk-1 and chunk-2 discrepancy reports without round-trip with agents or the user. T3 = grep / read / diff. No interpretation, just bytes.

**Date:** 2026-04-26
**Performed by:** Claude (this turn)
**Bias risk:** near-zero (deterministic checks)

---

## T3.1 — Is `$vaprojdofiles` consumed anywhere? (chunk-1 disc Q3)

**Question:** The L23 missing-`;` bug in `macros_va.doh` would corrupt `vaprojdofiles` (and the next macro `ca_ed_lab`). If neither is consumed, the bug is LATENT.

**Method:** `grep -rn "vaprojdofiles" --include="*.do" --include="*.doh"` across both predecessor repos.

**Result:** ONE match. `cde_va_project_fork/do_files/sbac/macros_va.doh:23` (the definition itself).

**Verdict:** `$vaprojdofiles` is **never consumed** outside its own definition. The L23 missing-`;` bug is **latent** — the corrupted macro value is never read.

**Severity downgrade:** Bug M1 in chunk-1 disc report goes from "potentially HIGH" to **LOW** (cosmetic / defensive). Phase 1 fix should still add the `;` for hygiene, but it does not affect any output today.

---

## T3.2 — Is `$ca_ed_lab` (the macro) consumed anywhere?

**Question:** Same as T3.1 for the L24 macro that would be corrupted by the L23 missing `;`.

**Method:** `grep -rn "ca_ed_lab'" --include="*.do" --include="*.doh"` across both repos.

**Result:** **ZERO matches.** No file references the `\`ca_ed_lab'` local.

**Verdict:** `\`ca_ed_lab'` (the macro) is **never consumed**. **Latent.**

**Severity downgrade:** consistent with T3.1.

---

## T3.3 — Is `l_scrhat_spec_controls` consumed by external code? (chunk-1 disc Q4)

**Question:** The L342-345 bug (`l_scrhat_spec_controls` uses `b_spec_controls` instead of `b_scrhat_spec_controls`, breaking the scrhat pattern) only matters if the macro is consumed.

**Method:** `grep -rn "l_scrhat_spec_controls" --include="*.do" --include="*.doh"` across both repos.

**Result:**
- `macros_va.doh:342` (definition)
- `macros_va.doh:353` (definition of `ld_scrhat_spec_controls = l_scrhat_spec_controls + d_controls` — the bug propagates)
- No external matches in this narrow grep.

**Method (broader):** `grep -rn "scrhat_spec_controls" --include="*.do" --include="*.doh"` to find all `<X>_scrhat_spec_controls` consumers.

**Result:** Two consumers outside macros_va.doh:
- `cde_va_project_fork/do_files/explore/va_predicted_score.do` L65, 84, 128, 149: uses `\`\`va_ctrl'_scrhat_spec_controls'` pattern (where `va_ctrl` loops over a list that includes `l` and `ld`).
- `cde_va_project_fork/do_files/explore/va_predicted_score_fb.do` L68, 85, 109, 129, 171, 189, 212, 231: same pattern.

**Verdict:** `l_scrhat_spec_controls` and `ld_scrhat_spec_controls` ARE consumed by `do_files/explore/` predicted-score files. **NOT latent for those files.**

**Severity:** the bug affects predicted-score (`_scrhat_`) VA estimates produced by the explore folder — NOT the canonical paper estimates. Per chunk-2 round-1 finding, the canonical paper uses v1 prior scores, not `_scrhat_` (which is exploratory). **Severity is MEDIUM** (affects exploratory outputs only, not paper-load-bearing).

**Phase 1 action:** fix L342-345 to use `b_scrhat_spec_controls`. Document the upstream propagation into `ld_scrhat_spec_controls`.

---

## T3.4 — Is `peer_L3_cst_ela_z_score` actually missing from `create_va_sample.doh` keepusing list? (chunk-2 disc N1)

**Round-1 claim:** "L26 keepusing list does NOT include `peer_L3_cst_ela_z_score`, but `create_prior_scores_v1.doh:16` references it. Possible silent bug."

**Method:** Read `create_va_sample.doh` L20-37.

**Result:** L29 IS `peer_L3_cst_ela_z_score ///` inside the keepusing block of the merge that starts at L26.

```
L26: merge 1:1 merge_id_k12_test_scores using `k12_test_scores'/k12_peer_test_scores_clean.dta, nogen keep(1 3) ///
L27:    keepusing( ///
L28:        `peer_demographic_controls' ///
L29:        peer_L3_cst_ela_z_score ///
L30:        peer_L3_sbac_ela_z_score ///
L31:        peer_L4_cst_ela_z_score ///
L32:        peer_L5_cst_ela_z_score ///
L33:        peer_L3_sbac_math_z_score ///
L34:        peer_L4_sbac_math_z_score ///
L35:        peer_L5_cst_math_z_score ///
L36:        peer_L6_cst_math_z_score ///
L37:    )
```

**Verdict:** `peer_L3_cst_ela_z_score` IS present at L29. **Round-1 was wrong.** Round-1's claim that the keepusing list "does NOT include" the variable was a false positive — likely a confusion between the merge-statement line (L26) and the keepusing block contents (L27-37).

**Action:** N1 (chunk-2 disc) is RETRACTED. Round-2 was right not to flag this. **Round-1 false positive caught by T3.**

This is a second confirmation-bias-style error caught by the verification protocol — this time round-1 was wrong, round-2 right. The protocol catches errors in both directions.

---

## T3.5 — Bug 93 family: regression sweep for `& inlist(...) | inlist(...)` and `& A | B` precedence patterns

**Question:** Are there OTHER instances of the operator-precedence bug pattern beyond the 4 known (NSC UC, NSC UC ontime, CCC ontime, CSU ontime)?

**Method:** Multi-step grep:

1. `& inlist(` followed by `| inlist(` (the chunk-10 NSC UC pattern) across all .do and .doh files.
2. Direct read of `merge_k12_postsecondary.doh` L168-170 and L232-234 (the chunk-2 round-2 finds).

**Result of step 1:**

| File | Lines | Status |
|---|---|---|
| `cde_va_project_fork/do_files/upstream/crosswalk_nsc_outcomes.do` | L218-219 | **BUG (Bug 93 chunk 10)** — confirmed pre-flight |
| `cde_va_project_fork/do_files/upstream/crosswalk_nsc_outcomes.do` | L227-228 | **BUG (Bug 93 chunk 10 part 2)** — confirmed pre-flight |
| `cde_va_project_fork/do_files/_archive/crosswalk_nsc_outcomes_deprecated.do` | L367, L375 | Archived; same bug in dead code |
| `caschls/do/archive/matt_original/crosswalk_nsc_outcomes.do` | L291, L299 | Archived; original Matt version |

**Result of step 2:** Direct read of `merge_k12_postsecondary.doh`:

L168-170 (CCC ontime):
```
gen ccc_enr_ontime = 1 if ccc_enr==1 ///
    & (ccc_enr_start_year==year_grad_hs & inlist(ccc_enr_start_term, 5, 6, 7, 8)) ///
    | (ccc_enr_start_year==year_grad_hs + 1 & inlist(ccc_enr_start_term, 1, 2, 3, 4))
```

Structure: `1 if A & B | C` where `A = ccc_enr==1`, `B = (... & inlist(...))`, `C = (... & inlist(...))`. Stata `&` binds tighter than `|`, so parses as `(A & B) | C`. **C fires regardless of `ccc_enr==1`. BUG CONFIRMED.**

L232-234 (CSU ontime): same pattern. **BUG CONFIRMED.**

**Verdict:** Bug 93 family confirmed at 4 active locations:

1. `cde_va_project_fork/do_files/upstream/crosswalk_nsc_outcomes.do:218-219` (`nsc_enr_uc`)
2. `cde_va_project_fork/do_files/upstream/crosswalk_nsc_outcomes.do:227-228` (`nsc_enr_ontime_uc`)
3. `cde_va_project_fork/do_files/merge_k12_postsecondary.doh:168-170` (`ccc_enr_ontime`)
4. `cde_va_project_fork/do_files/merge_k12_postsecondary.doh:232-234` (`csu_enr_ontime`)

Plus 4 occurrences in archived/deprecated files (cosmetic — already non-load-bearing).

**Phase 1 fix template** (Stata):

```stata
* BEFORE (BUG):
gen ccc_enr_ontime = 1 if ccc_enr==1 ///
    & (...) ///
    | (...)

* AFTER (FIX): wrap the OR clauses in outer parens
gen ccc_enr_ontime = 1 if ccc_enr==1 ///
    & ((...) | (...))
```

Same template for all 4 instances. Bundle as a single Phase 1 patch.

---

## Summary

| # | Item | Outcome |
|---|---|---|
| T3.1 | `$vaprojdofiles` consumed? | **No.** L23 missing-`;` bug latent. Severity downgrade to LOW. |
| T3.2 | `$ca_ed_lab` (macro) consumed? | **No.** Latent. |
| T3.3 | `l_scrhat_spec_controls` consumed externally? | **Yes** (in `do_files/explore/`). Bug at L342-345 affects predicted-score VA only. Severity MEDIUM. |
| T3.4 | `peer_L3_cst_ela_z_score` missing from keepusing list? | **No** — round-1 false positive. Variable IS at L29 of `create_va_sample.doh`. |
| T3.5 | Bug 93 family regression sweep | **4 active instances** across 2 files. Bundle Phase 1 patch. |

**Two false positives caught by the protocol:**

- Round-2 chunk-2 mis-flagged `asd_str` as still broken (was fixed in `e8dd083`).
- Round-1 chunk-2 mis-flagged `peer_L3_cst_ela_z_score` as missing from keepusing (it IS present at L29).

The four-tier T3 verification (deterministic file read) caught both. **Verification protocol works as designed.**
