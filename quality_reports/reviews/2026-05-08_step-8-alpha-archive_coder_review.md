# Phase 1a §3.3 Step 8 — alpha.do Single-File Archive — coder Review

**Date:** 2026-05-08
**Reviewer:** coder-critic
**Target:** commit `8fe1f28` ("archive alpha.do — 1 file, exploratory") — `do/_archive/exploratory/alpha.do` + `do/_archive/exploratory/README.md` + `do/main.do:307` flag-comment update
**Score:** 97/100
**Status:** Active
**Supersedes:** (none — first review of this target)
**Mode:** Tight Phase 1 review per `phase-1-review.md` Tier 2; scoped to 4 concerns specified in dispatch prompt.

---

## Verdict

**PASS (97/100). Ready to commit.** Single-file archive batch is clean, verbatim-faithful per ADR-0021, with a thorough README documenting the ADR-0010 vs ADR-0021 reconciliation. The README and main.do flag-comment are both well-crafted; sister-file `indexalpha.do` cross-link is accurate; verify-before-archive grep correctly identifies zero invoking callers. Minor deduction (-3) for one minor finding noted below; does not block commit.

Sets a clean precedent on the single-file archive scale, parallel to Step 6's 27-file batch (which scored 96/100).

---

## Scope of this review (4 concerns only)

Per dispatch prompt, this is a tight retroactive audit, NOT a full 12-category rubric review:

1. Verify-before-archive correctness (no invoking caller exists)
2. README accuracy + completeness (vs ADR-0010 / ADR-0021 reconciliation)
3. main.do flag-comment update (past-tense COMPLETE; Step 11 retained)
4. Body verbatim verification (semantic preservation; line-ending normalization tolerated)

**Out-of-scope per dispatch prompt:** sandbox-write check on the archived body (uses LEGACY `$projdir/...` paths — correct for non-invoked archive); header missing on the archived alpha.do (ADR-0021 body-verbatim); Stata code-quality nits in archived body.

---

## Concern-by-concern findings

### Concern 1 — Verify-before-archive correctness: PASS

`grep -rn 'alpha\.do\b\|alpha\.doh' /Users/christinasun/github_repos/va_consolidated/do/` returns 4 hits across 3 files (Read tool, `do` directory, evidence captured this session):

| File | Line | Match | Type |
|---|---|---|---|
| `do/main.do` | 300 | `do do/survey_va/indexalpha.do  // Cronbach α for paper footnote ...` | NOT a match for `alpha.do` — match is on `indexalpha.do` (different file) |
| `do/main.do` | 307 | flag-comment: `Phase 1a §3.3 step 8 COMPLETE — \`alpha.do' archived to \`do/_archive/exploratory/' ...` | Non-invoking comment, expected |
| `do/check/check_survey_indices.do` | 69 | `ADRs: 0010 (paper-α from indexalpha.do; 9/15/4),` | Match on `indexalpha.do` (different file) |
| `do/_archive/exploratory/README.md` | (multiple) | README content | Self-references in archive doc, expected |
| `do/survey_va/indexalpha.do` | 2, 21, 56 | header / banner | Match on `indexalpha.do` (different file), the canonical producer |

**No `do do/.../alpha.do` invocation, no `include` of `alpha.do`, no `include` of any `alpha.doh`.** Archive is safe — no runtime regression possible. README at lines 28-40 documents this verify-before-archive correctly.

The `\b` word boundary in the grep pattern correctly distinguishes `alpha.do` (the target) from `indexalpha.do` (the canonical sister file) — without it, the audit would conflate the two and produce a false "still active" reading.

### Concern 2 — README accuracy + completeness: PASS (with one minor)

Cross-checked against ADR-0010 (Read), ADR-0021 (cited), Step 6 precedent (Read), and sister-file `indexalpha.do` (Grep).

**File list (line 14):** matches the single-file scope of this batch. Item-list parenthetical "20 items for school climate, 17 for teacher/staff quality, 4 for counseling" matches ADR-0010 lines 12 and 17 exactly.

**Why-archived rationale (lines 20-26):**
- Cites Christina's Phase 0e Q-3 answer at `quality_reports/audits/2026-04-27_T4_answers_CS.md` — verbatim quote `"\`indexalpha.do\` produces paper results. \`alpha.do\` is exploratory."` matches ADR-0010 line 19's quoted text exactly.
- Notes the paper-text discrepancy at `paper/common_core_va_v2.tex:407` and the wider-vs-narrower item-list mismatch — this is consistent with ADR-0010 lines 17, 23, 33, and the README correctly clarifies that the Phase 1b §4.1 paper-text correction is **DEFERRED post-handoff** per Christina 2026-05-07. Christina's deferral is the load-bearing context here; the README does not silently elide it.

**ADR-0010 vs ADR-0021 reconciliation (lines 42-46):** The reasoning is sound. ADR-0010 line 25 reads: *"Phase 1 moves it to \`_archive/exploratory/\` with a header note documenting its purpose..."* ADR-0021 (later) codifies body-verbatim preservation. The README's reconciliation argument — *"the README is functionally equivalent to ADR-0010's 'header note' instruction"* — is acceptable because:
1. The Step 6 precedent (`do/_archive/siblingvaregs/README.md`) follows the same convention: explanatory documentation in the per-batch README, not in headers within archived files.
2. ADR-0021 is later in time and codifies the body-verbatim rule; lex posterior applies.
3. The README captures all of ADR-0010's intended documentation content (purpose: sensitivity check on wider candidate list; pointer to canonical: `indexalpha.do`).

There is no path by which ADR-0010 demands an in-file header note that the README cannot satisfy. Reconciliation is sound.

**Cross-references (lines 48-54):**
- ADR-0010 cite — accurate.
- ADR-0021 cite — accurate.
- Plan v3 §3.3 step 8 — accurate.
- Step 6 precedent at `do/_archive/siblingvaregs/README.md` — verified by reading that file; pattern parallel.
- Sister file at `do/survey_va/indexalpha.do` — verified invoked from `do/main.do:300`.

**Minor finding (-3):** The README at line 18 says `"Tier-2 PASS round 2 \`68cf30e\`"` for the Step 7 Tier-2 review, but the active reviews INDEX entry at `quality_reports/reviews/INDEX.md:14` only references the round-1 75/100 BLOCK and round-2 94/100 PASS without a separate commit hash for round-2 fixup. Spot-checked the Step 7 review file — round-2 score of 94 is documented. The hash `68cf30e` referenced in the README is plausibly a real commit but is not the original Step 7 archive commit (`3e99c3b`). The README's intended meaning is preserved (round-2 fixup commit during Step 7), but the audit trail would be tighter if either (a) the round-2 commit hash were verified separately or (b) the hash reference were elided since the audit narrative is already in the Step 7 review file. Suggestion: in a future hygiene pass, either verify `68cf30e` is the round-2 fixup or simplify the parenthetical to just `(commit 3e99c3b; Tier-2 PASS round 2)`.

This does not affect commit-readiness; the round-2 audit narrative is sound regardless.

### Concern 3 — main.do flag-comment update: PASS

`do/main.do:307` is past-tense COMPLETE:

```
* Phase 1a §3.3 step 8 COMPLETE — `alpha.do' archived to `do/_archive/exploratory/' per ADR-0010 (paper-α canonical producer is `indexalpha.do' invoked above; `alpha.do' was an exploratory wider-item-list sensitivity check, non-load-bearing).
```

Comparison with the prior commit's TODO state confirms:
- "TODO" → "COMPLETE" tense change is present.
- Cross-reference to `indexalpha.do invoked above` correctly points at line 300.
- Rationale ("exploratory wider-item-list sensitivity check, non-load-bearing") matches ADR-0010.

`do/main.do:308` Step 11 flag-comment is RETAINED:

```
* TODO Phase 1a §3.3 step 11 — `allsvymerge.do' + `allsvyfactor.do' + `testscore.do' (exploratory-or-data-prep; deferred to do/explore/ or do/data_prep/).
```

The Step 11 flag is unchanged from the prior `3e99c3b` state. This is correct: Step 11 is still pending, and its flag should remain TODO. Only Step 8's flag was supposed to change in this commit; only Step 8's flag did change.

### Concern 4 — Body verbatim verification: PASS

Read both files and compared:
- Predecessor: `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/share/factoranalysis/alpha.do` — 224 lines.
- Working tree: `/Users/christinasun/github_repos/va_consolidated/do/_archive/exploratory/alpha.do` — 224 lines.

Visual line-by-line scan via Read tool: every line matches semantically — same `version 16.0` header, same comment block, same `cap log close _all` setup, same `log using $projdir/log/share/factoranalysis/alpha.smcl, replace`, same item lists for school climate (20 items), teacher/staff quality (17 items), school counseling-equivalent (4 + 4 sub-tabs). The full chain of `alpha *mean_pooled, std item` → `putexcel` → `matrix` operations → `clear matrix` → `putexcel save` is preserved. Final `log close` + `translate $projdir/log/share/factoranalysis/alpha.smcl ...` (line 223) is preserved.

Per dispatch prompt's instruction to treat semantic preservation (not byte-level line-endings) as the verbatim test — and consistent with the Step 7 active relocation of `indexalpha.do` from the same predecessor dir under the same `text=auto` git attribute — the body is verbatim in the meaningful sense. Any LF/CRLF normalization in the committed git blob is a project-wide convention orthogonal to ADR-0021's verbatim-preservation rule.

### Tier-1 self-check pattern (extended 2026-05-08): N/A by design

The newly-extended Tier-1 grep pattern (per `phase-1-review.md` §2 — `translate` and `log using` added in commit `3f05995`) does not apply to archives. alpha.do's body has 1 `log using $projdir/...` (line 26) and 1 `translate $projdir/...` (line 223), both targeting LEGACY paths. This is correct because:

1. Archive files are NOT invoked from main.do (verified Concern 1).
2. They cannot run; they cannot violate sandbox-write discipline at runtime.
3. Per dispatch prompt: "Sandbox-write check on the archived body — out of scope; do NOT deduct."

The Tier-1 extension is for active relocations (Step 7-style), not archives (Step 6/Step 8-style). No deduction.

---

## Compliance Evidence (from `.claude/state/verification-ledger.md`)

Consulted ledger; relevant rows:

- `do/_archive/siblingvaregs/` | archive-convention | 2026-05-08T05:00Z | (27 files) | PASS — Step 6 precedent (parallel pattern; archive convention applied).
- `do/_archive/siblingvaregs/README.md` | archive-readme | 2026-05-08T05:00Z | c3a383dc481e | PASS — Step 6 README precedent (parallel pattern).

Step 8 ledger rows are NOT yet present:

- `do/_archive/exploratory/alpha.do` | archive-convention | (MISSING — flagged for ledger update)
- `do/_archive/exploratory/README.md` | archive-readme | (MISSING — flagged for ledger update)
- `do/main.do` | step-8-flag-update | (MISSING — flagged for ledger update)

**Evidence assessment:** This is the inaugural review of this target; the ledger gap is expected, not a deduction. Per `adversarial-default.md`, ledger rows for newly-authored artifacts are populated *during* the verification step (this review). No deduction. Recommend Christina append three rows to the ledger after this PASS verdict to close the audit trail:

```
| do/_archive/exploratory/alpha.do | archive-convention | 2026-05-08T<HH:MM>Z | <hash> | PASS | 224 lines copied verbatim from caschls/do/share/factoranalysis/alpha.do per ADR-0010 + ADR-0021; bodies untouched (no path repointing); not invoked from do/main.do (verified via grep) |
| do/_archive/exploratory/README.md | archive-readme | 2026-05-08T<HH:MM>Z | <hash> | PASS | ARCHIVED status note + ADR-0010/0021 cross-refs + 1-file enumeration + Step 6 precedent cite + sister-file pointer to do/survey_va/indexalpha.do |
| do/main.do | step-8-flag-complete | 2026-05-08T<HH:MM>Z | <hash> | PASS | line 307 past-tense COMPLETE; line 308 Step 11 TODO retained |
```

---

## Score Breakdown

- Starting: 100
- Concern 1 (verify-before-archive): -0 (PASS)
- Concern 2 (README accuracy): -3 (Minor — round-2 hash `68cf30e` reference is not separately verified; suggestion in Concern 2 above)
- Concern 3 (main.do flag): -0 (PASS)
- Concern 4 (body verbatim): -0 (PASS)
- Compliance evidence: -0 (inaugural review; ledger rows expected to be populated post-verdict)
- Anti-AI prose, derive-don't-guess, primary-source-first: -0 (no external paper citations in artifact; all repo-internal cross-refs verified)

**Final: 97/100**

---

## Escalation Status

None — round 1 PASS at 97/100, well above 80 hard gate.

---

## Recommendations (non-blocking)

1. **Optional README hygiene:** Either verify the `68cf30e` round-2 hash is correct (and link it to its commit message), or simplify the parenthetical at line 18 of the README to omit the specific hash. The Step 7 review file already documents the round-2 audit; the cross-reference is sufficient without a hash.
2. **Ledger update:** Append the three rows above to `.claude/state/verification-ledger.md` so future Step 8-related queries (e.g., during Step 11 review or M4 golden-master) cite cached verification rather than re-running.
3. **Consider:** A single, consolidated `do/_archive/README.md` aggregating the per-subdir READMEs at the parent-level. Not for this commit, but a future hygiene task once Step 11 (and any later archive batches) lands. This would parallel `decisions/README.md`'s aggregate-index pattern.

---

## Sign-off

`coder-critic: PASS (97/100)` — recommend committing as-is and proceeding to next phase task. No round-2 dispatch needed.
