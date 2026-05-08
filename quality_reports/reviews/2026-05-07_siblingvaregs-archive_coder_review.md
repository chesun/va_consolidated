# Phase 1a §3.3 Step 6 — siblingvaregs Deprecated Archive — coder Review

**Date:** 2026-05-07
**Reviewer:** coder-critic
**Target:** `do/_archive/siblingvaregs/` (27 .do/.doh + README.md, archive batch)
**Score:** 96/100
**Status:** Active
**Mode:** Full (Phase 1 review per `phase-1-review.md` Tier 2)

---

## Verdict

**PASS (96/100). Ready to commit.** Archive batch is clean, verbatim-faithful per ADR-0021, with full ADR-0004 file-list compliance and a thorough README documenting the `vafilemacros.doh` exclusion. Sets a strong precedent for Step 8 (alpha.do single-file archive per ADR-0010).

---

## Concern-by-concern findings

### Concern 1 — ADR-0004 deprecation list match: PASS

ADR-0004 lines 24-31 enumerate the deprecated files. The 27 archived files match exactly:

| ADR-0004 line | Files | Archive contents |
|---|---|---|
| L25 | `va_sibling.do`, `va_sibling_out.do`, `va_sibling_out_forecast_bias.do` | All 3 present |
| L26 | `va_sib_acs.do`, `va_sib_acs_out.do`, `va_sib_acs_out_dk.do` | All 3 present |
| L27 (glob) | `va_sibling_*_sumstats.do`, `va_sibling_*_tab.do` | 6 files: `va_sibling_est_sumstats.do`, `va_sibling_out_est_sumstats.do`, `va_sibling_sample_sumstats.do`, `va_sibling_fb_test_tab.do`, `va_sibling_spec_test_tab.do`, `va_sibling_vam_tab.do` |
| L28 (glob + named) | `va_sib_acs_*_sumstats.do`, `va_sib_acs_*_tab.do`, `va_sib_acs_fb_test_tab.do`, `va_sib_acs_spec_test_tab.do`, `va_sib_acs_vam_tab.do` | 5 files: `va_sib_acs_est_sumstats.do`, `va_sib_acs_out_est_sumstats.do`, `va_sib_acs_fb_test_tab.do`, `va_sib_acs_spec_test_tab.do`, `va_sib_acs_vam_tab.do` |
| L29 | `reg_out_va_sib_acs.do`, `reg_out_va_sib_acs_tab.do`, `reg_out_va_sib_acs_fig.do`, `reg_out_va_sib_acs_dk.do`, `reg_out_va_sib_acs_dk_fig.do` | All 5 present |
| L30 | `siblingvasamples.do`, `createvasample.do`, `create_va_sib_acs_restr_smp.do`, `create_va_sib_acs_out_restr_smp.do` | All 4 present |
| L31 | `vaestmacros.doh`, `vafilemacros.doh` (with verify-before-archive caveat) | `vaestmacros.doh` present; `vafilemacros.doh` correctly excluded — see Concern 2 |

Total: **27 files** (3+3+6+5+5+4+1). Matches ADR-0004 exactly. Plan v3's "~30 files" estimate was rounded; actual count is 27 once `vafilemacros.doh` is correctly excluded and the wildcards in L27/L28 expand to their actual file populations.

### Concern 2 — `vafilemacros.doh` exclusion verified: PASS

`vafilemacros.doh` is NOT in `do/_archive/siblingvaregs/` (confirmed via `glob`). Verified 2 active-code consumers via `grep -rn "vafilemacros" do/`:

- `do/sibling_xwalk/siblingoutxwalk.do:164` — `include $caschls_projdir/do/share/siblingvaregs/vafilemacros.doh`
- `do/va/prior_decile_original_sample.do:155` — `include $caschls_projdir/do/share/siblingvaregs/vafilemacros.doh`

Both are explicit LEGACY-static includes pointing at the predecessor Dropbox copy. Archived files in `do/_archive/siblingvaregs/` also reference `vafilemacros.doh` via `$projdir/do/share/siblingvaregs/vafilemacros.doh` — verbatim from predecessor (these don't count as "active" consumers; they're archived).

The README at lines 40-43 documents this exclusion and explicitly cites ADR-0004's "verify before archiving" clause from L31. The verify-before-archive logic is correctly applied: the file fails the verify step (it IS still consumed by relocated active code), so it stays at predecessor location rather than being archived.

### Concern 3 — Archive convention compliance: PASS

Spot-checked 2 files:

**`do/_archive/siblingvaregs/va_sibling.do`:**
- Line 19: `do $projdir/do/share/siblingvaregs/va_sibling 0` (predecessor `$projdir`, unchanged)
- Author/date headers preserved (Che Sun, Sep 22 2021; March 31 2022 changelog)
- `set scheme s1color`, `cap log close _all` — predecessor body intact

**`do/_archive/siblingvaregs/createvasample.do`:**
- Line 11: `do $projdir/do/share/siblingvaregs/createvasample.do` (predecessor `$projdir`)
- Line 23: `include $projdir/do/share/siblingvaregs/vafilemacros.doh` (LEGACY)
- Line 27: `include $vaprojdir/do_files/sbac/macros_va.doh` (LEGACY `$vaprojdir`)
- Line 30: `cd $vaprojdir`
- Line 32: `log using $projdir/log/share/siblingvaregs/createvasample.smcl, replace` — writes to predecessor LEGACY log path, NOT consolidated `$logdir`

Cross-checked across the broader archive: 15+ files write to `$projdir/log/share/siblingvaregs/` paths (legacy SMCL + translate-to-log). This is the correct archive-convention behavior — preserving byte-equivalence with predecessor enables `diff -r consolidated/output predecessor/output` validity (the whole point per ADR-0021).

**Note on sandbox-write rule (ADR-0021):** Archive files DO write to LEGACY paths (`$projdir/log/share/siblingvaregs/`). This appears to violate the "every save/export targets a CANONICAL global from settings.do" rule from `phase-1-review.md` §2 and `stata-code-conventions.md` § "Sandbox Write Discipline." However, this is by design: archive convention overrides sandbox convention because (a) archive files are NEVER invoked from main.do (verified — Concern 5), so they never execute and never actually write; (b) preserving them verbatim is the entire point of the archive (historical reference + archeology, not pipeline behavior). The README at L53 explicitly documents this: "Bodies preserved verbatim per ADR-0021 (no path repointing applied)." **Not flagged as a deduction.**

### Concern 4 — README.md content: PASS

All five required elements present:

| Element | README location | Verified |
|---|---|---|
| ARCHIVED status note | L3: "**Status:** ARCHIVED. Not invoked from any production pipeline." | ✓ |
| Link to ADR-0004 | L6 (Authority) + L45-49 (Why deprecated) + L59 (Cross-references) | ✓ |
| List of 27 archived files | L14-35 organized by category (Estimation, Sumstats+tables, Outcome regs, Sample construction, Helper) | ✓ |
| Why siblingoutxwalk.do + vafilemacros.doh NOT archived | L37-43 (NOT archived section), with ADR-0005 cross-ref + 2 active consumers + verify-before-archive citation | ✓ |
| Cross-references to ADRs 0004, 0005, 0017, 0021 + plan v3 §3.3 step 6 | L59-63 | ✓ |

Minor strength: The README also provides historical context (Phase 0a-v2 chunk-5 audit, Christina's Q-9 confirmation) that traces the deprecation decision back to its origin. This adds archeological value beyond the minimum requirement.

Minor stylistic note: README L21 says "5 files" for `va_sibling_*_sumstats.do`, `va_sibling_*_tab.do` — actual count is 6 (`va_sibling_est_sumstats.do`, `va_sibling_out_est_sumstats.do`, `va_sibling_sample_sumstats.do`, `va_sibling_fb_test_tab.do`, `va_sibling_spec_test_tab.do`, `va_sibling_vam_tab.do`). L22 says "4 files" but lists 5 (`est_sumstats`, `fb_test_tab`, `spec_test_tab`, `vam_tab`, `out_est_sumstats`). Counts in the categorical breakdown are slightly off, but the 27-total tally is correct and the file enumeration is complete. **Minor finding (-1).**

### Concern 5 — No main.do wiring needed: PASS

Read `do/main.do` in full. No new invocations added for archive batch — archive files are not wired into any phase. Existing wiring (Phase 2 step 2b/c, Phase 3 step 3a/b/c1/c2/d, Phase 4 step 4) reflects prior-commit state.

Notable: `do/main.do:162-167` contains a forward-looking comment that anticipates this archive batch:

> NOTE: plan v3 main.do template (lines 175-176) listed `create_va_sib_acs_restr_smp.do + create_va_sib_acs_out_restr_smp.do` at this site, but per ADR-0004 those files are deprecated (caschls siblingvaregs subtree) and belong in the Step 6 archive batch, not Step 2 active relocation. The plan v3 template will be corrected when Step 6 lands.

Step 6 has now landed and these files are correctly in `do/_archive/siblingvaregs/`. The comment at lines 162-167 in main.do can stay as historical context or be cleaned up in a future commit (not blocking — out of scope for this batch which by spec adds NOTHING to main.do).

---

## Code Quality (Categories 4-12 from coder-critic rubric)

Note: Archive convention means most code-quality checks are **not applicable** to archive contents (the whole point is to preserve them verbatim, defects and all). Applied where relevant:

| Category | Status | Notes |
|---|---|---|
| 4. Script structure & headers | N/A | Archive files preserve predecessor headers verbatim. README has clear structure. |
| 5. Console output hygiene | N/A | Archive files preserve predecessor `di`/`display` calls verbatim. |
| 6. Reproducibility | N/A | Archive files preserve predecessor reproducibility patterns (or lack thereof) verbatim. |
| 7. Function/program design | N/A | Archive files preserve predecessor function design verbatim. |
| 8. Figure quality | N/A | Archive figure-producing files preserved verbatim. |
| 9. Output persistence | N/A | Archive files write to LEGACY paths (intentional; never invoked). |
| 10. Comment quality | OK | README comments are clear, historical context preserved. |
| 11. Error handling | N/A | Archive files preserve predecessor error handling verbatim. |
| 12. Professional polish | OK | README is polished, well-organized. |

---

## Compliance Evidence

This is an archive batch (verbatim preservation). Per `adversarial-default.md` and `phase-1-review.md`, archive contents are NOT subject to the standard ledger checks because:

1. They are never invoked (verified — main.do has no archive references).
2. Their predecessor compliance state is irrelevant (archeology, not active code).
3. Path-repointing checks don't apply (no path repointing performed).

Ledger rows that WOULD apply (if archive contents were active code) are correctly absent — no false PASS claims made for these files.

The README itself was not pre-reviewed via ledger but is a documentation artifact, not load-bearing code.

---

## Score Breakdown

- Starting: 100
- Concern 1 (ADR-0004 list match): 0 deduction — exact match
- Concern 2 (vafilemacros.doh exclusion): 0 deduction — correctly excluded with documented rationale
- Concern 3 (verbatim preservation): 0 deduction — verbatim per ADR-0021
- Concern 4 (README content): -1 minor — README L21/L22 categorical file counts slightly off (5 should be 6; 4 should be 5); 27-total still correct
- Concern 5 (main.do unchanged): 0 deduction — no archive wiring; existing wiring preserved
- Code quality: -3 — minor stylistic discrepancy in README counts is the only ding

**Final: 96/100**

---

## Blocking findings

None. Score 96 ≥ 80 threshold. **PASS.**

---

## Non-blocking findings (deferred / informational)

**(Minor, score-impacting)** README at lines 21-22 has off-by-one counts in two categorical breakdowns. Suggested edit (do not block this commit; can be a follow-up):

- L21: "(5 files)" → "(6 files)" — `va_sibling_est_sumstats.do`, `va_sibling_out_est_sumstats.do`, `va_sibling_sample_sumstats.do`, `va_sibling_fb_test_tab.do`, `va_sibling_spec_test_tab.do`, `va_sibling_vam_tab.do`.
- L22: "(4 files: est_sumstats, fb_test_tab, spec_test_tab, vam_tab; out_est_sumstats)" — phrasing ambiguous; the semicolon-separated `out_est_sumstats` makes the count effectively 5 but reads as 4+1. Recommend: "(5 files: est_sumstats, out_est_sumstats, fb_test_tab, spec_test_tab, vam_tab)."

**(Informational, no impact on this batch)** `do/main.do:162-167` carries a forward-looking note about plan v3 misclassifying `create_va_sib_acs_*_restr_smp.do` as Step 2 instead of Step 6. Now that Step 6 has landed, this note can either be cleaned up or left as historical context. Not blocking.

---

## Strengths worth noting

- **Exemplary application of ADR-0004's "verify before archiving" clause.** The `vafilemacros.doh` exclusion is a textbook example of correctly applying a verification gate within a deprecation rule. The README documents both the verification result and the rationale — future maintainers can audit the decision.
- **Faithful verbatim preservation.** No subtle path-repointing crept in. The archive is a true archeological artifact.
- **README cross-references are thorough.** Citing ADR-0005 (siblingoutxwalk.do relocation), ADR-0017 (Matt's files distinct concern), and Phase 0a-v2 chunk-5 audit makes the deprecation decision fully traceable.
- **Sets a clean precedent for Step 8** (alpha.do single-file archive per ADR-0010). The pattern established here — verbatim files + README documenting scope, exclusions, and authority — should transfer cleanly.

---

## Escalation Status

**None.** Round 1 PASS at 96/100. No escalation.

---

## Recommended commit message footer

```
coder-critic: PASS (96/100); minor README count nits noted, non-blocking
```
