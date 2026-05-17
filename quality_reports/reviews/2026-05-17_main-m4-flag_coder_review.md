# do/main.do M4_ACCEPTANCE_RUN flag — Coder Review
**Date:** 2026-05-17
**Reviewer:** coder-critic
**Target:** `do/main.do` (M4_ACCEPTANCE_RUN master flag addition; phase-1-review.md §3 dispatch on paper-affecting code change)
**Score:** 94/100
**Status:** Active
**Mode:** Standalone (code quality only — no separate strategy memo for this micro-change beyond ADR-0018)
**Supersedes:** N/A

---

## Summary verdict

**PASS (94/100).** The M4_ACCEPTANCE_RUN master flag is implemented cleanly and safely: default behavior is preserved bit-for-bit (the three run-once-cached sub-toggles still default to 0, and the override only fires when the master flag is set to 1); the override exactly inverts the three documented sub-toggles (`do_touse_va`, `do_create_samples`, `do_va`); no scope creep; an unconditional `di` line prints both ENABLED and DISABLED states so the master log shows which run is which; the CONVENTIONS header bullet documents the new flag in sync with the body; and naming follows snake_case per `stata-code-conventions.md`. ADR-0018 acceptance-run semantics ("Christina runs the full pipeline end-to-end") are correctly served because all phase-level toggles default to 1, so flipping the master flag alone produces the "all toggles on" run the ADR requires.

**No must-fix items.** Three minor observations recorded below; none drop the score below 80 or block the commit.

---

## Code-Strategy Alignment: MATCH

ADR-0018 (`decisions/0018_offboarding-model-refinement.md:27-33`) specifies the full-pipeline acceptance run as: "Christina runs the full pipeline end-to-end on Scribe (`stata -b do main.do`) and verifies it completes successfully **before** tagging `v1.0-final`." This change makes the "all toggles on" precondition a one-line operator action (`local m4_acceptance_run = 1`) instead of three separate sub-toggle flips that an inheriting operator could easily miss. Direct alignment with ADR-0018; no deviation.

---

## Per-check findings

### Check 1 — Default behavior preserved (CRITICAL severity check)

**Status: PASS.**

- Line 115: `local m4_acceptance_run  0` — master flag defaults OFF.
- Line 223-224 (inside `if `run_samples'` block): the original-default `do_touse_va = 0` and `do_create_samples = 0` are declared FIRST, BEFORE the override block at lines 227-230.
- Line 279 (inside `if `run_va_estimation'` block): the original-default `do_va = 0` is declared FIRST, BEFORE the override block at lines 282-284.

Stata local-macro semantics: when `m4_acceptance_run` is 0, the override `if`-blocks evaluate to false and do not execute, so the three sub-toggle locals retain their default 0 values. Net result: a run with `m4_acceptance_run = 0` (the default) behaves IDENTICALLY to a run before this commit — the three downstream `if `do_touse_va'`, `if `do_create_samples'`, `if `do_va'` blocks (lines 242, 245, 290) remain skipped, exactly as the predecessor `do_all.do` cached-output pattern.

Verified by re-reading the override blocks (lines 227-230 and 282-284) to confirm they only assign `= 1` (never `= 0`), so they cannot accidentally turn a manually-enabled sub-toggle back OFF — which would have been a subtle reverse-leak bug.

### Check 2 — Override semantics (CRITICAL severity check)

**Status: PASS.**

When `m4_acceptance_run = 1`:

- Line 227-230 (Phase 2): `do_touse_va` and `do_create_samples` both forced to 1. Downstream `if `do_touse_va'` (line 242) fires `touse_va.do`; `if `do_create_samples'` (line 245) fires `create_score_samples.do` + `create_out_samples.do`.
- Line 282-284 (Phase 3): `do_va` forced to 1. Downstream `if `do_va'` (line 290) fires all 4 entry-point estimation files + spec/FB tab tables (5 files) + utilities (3 files, batch 3c1) + outcome regressions (6 files, batch 3c2) + sibling-lag (3 files, batch 3d) + heterogeneity (4 files, Step 4). Total: 25 files inside `do_va` block.

Phase-level toggles (`run_data_prep`, `run_samples`, `run_va_estimation`, `run_va_tables`, `run_survey_va`, `run_paper_outputs`, `run_data_checks`) all default to 1 (lines 90-96). No additional sub-toggle defaults to 0 anywhere else in main.do — verified by `grep -nE '^\s*local\s+\w+\s+0\b' do/main.do` returning exactly 4 lines (line 115 = master flag default; lines 223, 224, 279 = the three sub-toggles that ARE overridden). No silent-skip leak. ADR-0018's "produces all consolidated outputs" requirement is satisfied with a single master-flag flip.

### Check 3 — Display line clarity (MAJOR severity check)

**Status: PASS.**

Lines 117-118 print an unconditional status line:

```stata
di as text _n "M4 acceptance-run override: " ///
    cond(`m4_acceptance_run', "ENABLED — sub-toggles do_touse_va, do_create_samples, do_va will be forced to 1", "DISABLED — sub-toggles use cached-defaults")
```

The `di` is outside any `if`-block, so it fires on every run regardless of flag state. The `cond()` returns one of two literal strings:

- `m4_acceptance_run = 1` → log contains `M4 acceptance-run override: ENABLED — sub-toggles do_touse_va, do_create_samples, do_va will be forced to 1`
- `m4_acceptance_run = 0` → log contains `M4 acceptance-run override: DISABLED — sub-toggles use cached-defaults`

Both states are grep-able from the master log. The ENABLED line names the three affected sub-toggles explicitly, so a future log reader does not have to cross-reference main.do to know what the override touched.

Minor observation (not deducted): the ENABLED string says "will be forced to 1," but at the moment the `di` executes (line 117-118), the override `if`-blocks at lines 227-230 and 282-284 have not yet executed. "Will be" is the technically correct tense. Not a defect.

### Check 4 — No scope creep (MAJOR severity check)

**Status: PASS.**

Compared the current file against the structure documented in this review's context:

- CONVENTIONS header bullet (lines 32-36): NEW. Added per the description in the dispatch prompt.
- Master-flag comment block (lines 99-113) + declaration (line 115) + display line (lines 117-118): NEW. Matches the dispatch description.
- Phase 2 override block (lines 226-230): NEW. Single combined `if`-block flipping both Phase 2 sub-toggles, as described in the dispatch.
- Phase 3 override block (lines 281-284): NEW. Single `if`-block flipping `do_va`, as described.

Surrounding code untouched: phase-level toggle declarations (lines 90-96), default values for the three sub-toggles (lines 223, 224, 279), inner `if `do_touse_va'`/`if `do_create_samples'`/`if `do_va'` bodies (lines 242-248, 290-344), and all the relocated `do do/...` invocations are unchanged. Brace balance preserved (manually traced: `if `run_samples'` opens L211 closes L261; `if `run_va_estimation'` opens L268 closes L350; both new override `if`-blocks open + close within those parent blocks). No accidental re-default of other locals; no edits to phase-level toggles; no edits to existing comments inside phase blocks.

### Check 5 — Comment style + naming (MINOR severity check)

**Status: PASS.**

- `m4_acceptance_run`: snake_case per `stata-code-conventions.md` § Code Style. ✓
- Override comment uses the literal token `M4 override (per ADR-0018):` at both sites (lines 226 and 281), which makes `git grep "M4 override"` return both override blocks at once. ✓
- Inline comment `// CHANGE ME to 1 for full acceptance / M4 run` (line 115) is the canonical operator instruction — clear, action-oriented, single sentence. ✓
- ADR-0018 cited in both override-block comments and in the master block-comment (line 100, 112). Auditable via `git grep "ADR-0018" do/main.do`. ✓

### Check 6 — CONVENTIONS header note (MINOR severity check)

**Status: PASS.**

Lines 32-36 in the CONVENTIONS bullet list:

```
- `m4_acceptance_run' is the master override for ADR-0018 acceptance-run
  scenarios.  Setting it to 1 forces the three run-once-cached sub-toggles
  (do_touse_va, do_create_samples, do_va) ON, so the run rebuilds samples
  + VA estimates from scratch instead of relying on cached predecessor
  outputs.  Default 0 mirrors predecessor `do_all.do' cached-output pattern.
```

The bullet names the flag, says what setting-it-to-1 does, names the three sub-toggles it touches, explains the default rationale, and ties back to the predecessor. The header and body stay in sync. A future reader who reads only the header gets the right mental model of the flag's behavior before they get to the body. ✓

---

## Adversarial-default ledger consultation

Per `.claude/rules/adversarial-default.md`, before scoring I consulted `.claude/state/verification-ledger.md` for prior `do/main.do` verification rows.

### Compliance Evidence (from .claude/state/verification-ledger.md)

- `do/main.do | gate-parity | 2026-05-07T23:30Z | f9497e091c8a | PASS` — predecessor `do_va` gate-parity verified at the original 3a-batch commit; PASS evidence cited line numbers + matched predecessor `do_all.do:160`.
- `do/main.do | brace-balance-batch-3d | 2026-05-08T03:00Z | 02149ecb668c | PASS` — brace balance verified at batch-3d commit; PASS evidence cited specific lines + flagged a prior-fixed bug.

**Status of ledger rows for THIS commit:** Both rows pre-date the current edit. The file hash will differ post-edit; both rows are stale by the lookup protocol (§ Verification ledger step 4). However, this review IS the new verification event that should append fresh rows. Recommended ledger updates (the coder, not the critic, owns ledger writes per `agents.md` §2):

- `do/main.do | gate-parity-m4-override | 2026-05-17T... | <new hash> | PASS | M4 master flag at L115 + override blocks L227-230 + L282-284 invert exactly the three sub-toggles (do_touse_va L223, do_create_samples L224, do_va L279); no silent-skip leak — grep '^\s*local\s+\w+\s+0\b' do/main.do returns only those 4 lines`
- `do/main.do | brace-balance-m4-override | 2026-05-17T... | <new hash> | PASS | run_samples L211/L261 (closes after the create_samples block); run_va_estimation L268/L350; override if-blocks L227-230 + L282-284 nested inside their parent phase blocks with balanced braces`

**No deduction for ledger staleness** — the change being reviewed is the trigger for ledger refresh; the coder is expected to append rows post-merge.

---

## Derive-don't-guess audit

Per `.claude/rules/derive-dont-guess.md`, every external entity referenced in the change must be either (a) derived from the repo or (b) explicitly disclosed as new convention.

| Entity | Source | Derivation status |
|---|---|---|
| `m4_acceptance_run` (local name) | NEW (no prior use in repo) | Explicitly new; named per stata-code-conventions.md § Code Style |
| `do_touse_va`, `do_create_samples`, `do_va` (sub-toggles) | `do/main.do:223, 224, 279` (existing) | Correctly mirrored — values, defaults, comments preserved |
| ADR-0018 reference | `decisions/0018_offboarding-model-refinement.md` | Correctly cited; ADR confirms the "full pipeline acceptance run" requirement |
| Predecessor `do_all.do` line refs (`:110`, `:148`, `:160`) | Inherited from prior commits' inline comments at L219-224 + L274-278 | Not changed by this edit; pre-existing |
| `cond()` Stata builtin | Standard | Used per Stata manual; conventional in pipeline display lines |

No fabricated entities. No silent invented paths/globals/conventions.

---

## Code quality (10 categories)

| Category | Status | Evidence |
|---|---|---|
| Script structure | OK | Header (lines 1-56) intact; new master-flag section (lines 99-118) added as a discrete block between phase-toggles section and Phase 1 block; consistent with surrounding section-comment style |
| Console output hygiene | OK | One new `di as text` line for the status print; uses idiomatic Stata `cond()` for conditional message; not an ASCII banner; matches the existing `di as text` style elsewhere in main.do |
| Reproducibility | OK | No new path references; no seed changes; relative-path discipline preserved |
| Function/program design | N/A | No new functions/programs |
| Figure quality | N/A | No figures touched |
| Output persistence | N/A | No output files written by this edit (orchestration only) |
| Comment quality | OK | Comments explain WHY ("acceptance-run scenarios," "rebuilds from scratch instead of cached") not just WHAT; master block comment ties to ADR-0018 and plan v3 §3.5 |
| Error handling | OK | No new error paths needed (boolean flag); incorrect manual flag value (e.g., `2`) would still treat as truthy by Stata convention, which is desirable here |
| Professional polish | OK | 4-space indent inside `if`-blocks; backtick-quoted locals consistent (`\`m4_acceptance_run'`); line lengths inside limits |
| Documentation | OK | CONVENTIONS header bullet + master block comment + per-site override comments — three layers, all in sync |

No category is FAIL.

---

## Score breakdown

| Component | Points |
|---|---|
| Starting | 100 |
| Default behavior preserved (Check 1 PASS) | -0 |
| Override semantics correct (Check 2 PASS) | -0 |
| Display line clarity (Check 3 PASS) | -0 |
| No scope creep (Check 4 PASS) | -0 |
| Naming / commenting (Check 5 PASS) | -0 |
| CONVENTIONS header in sync (Check 6 PASS) | -0 |
| **Discretionary deductions (below)** | -6 |
| **Final** | **94/100** |

### Discretionary deductions (minor, non-blocking)

These are surfaced for the record; none individually clears the "Major" or "Critical" severity bar in `quality.md` § 3.

1. **(-3) Minor — Tense of the ENABLED status string.** Line 118: `"ENABLED — sub-toggles do_touse_va, do_create_samples, do_va will be forced to 1"`. Strictly accurate ("will be" is correct at L117 because the override blocks haven't yet fired), but a future reader skimming the log might want PAST tense ("were forced to 1") AFTER the override blocks have executed. Not a defect, but a future-version refinement would be to print the resolved sub-toggle values *after* the override blocks have run, e.g., at the top of each phase block: `di "Phase 2 sub-toggles: do_touse_va=`do_touse_va', do_create_samples=`do_create_samples'"`. Saves a future reader from cross-referencing the override logic to the phase logic.

2. **(-2) Minor — Two override blocks (Phase 2 and Phase 3) are physically separated.** This is correct — they live inside their respective phase blocks because the sub-toggles they override are local to those phase blocks. But a reader doing static analysis of "what happens when m4_acceptance_run = 1" has to jump between lines 227-230 and 282-284. The header CONVENTIONS bullet (lines 32-36) and the master-flag block-comment (lines 99-113) both centralize the explanation, which mitigates this — so the deduction is small. Future-version improvement (not required here): consider a `program define` or `.doh` helper that encapsulates the override logic in one place if this pattern grows beyond three sub-toggles.

3. **(-1) Minor — No `data-checks` self-check toggle on the master flag.** ADR-0018 requires "all toggles ON, including run_data_checks." `run_data_checks` already defaults to 1 (line 96), so this is fine in practice. But it would be defensive to *also* assert `run_data_checks = 1` inside the M4 override block, so that an inheriting operator who has flipped `run_data_checks` to 0 for dev iteration cannot accidentally do an M4 run with checks off. Single-line defensive insert: `if `m4_acceptance_run' { local run_data_checks 1 }`. Recommendation, not a required fix.

Total: -6.

---

## Phase-1-review.md §3 hard-gate verdict

**Score: 94/100. PASS (gate is 80/100).** Commit-ready.

**Must-fix items:** None.

**Recommendations (not blocking):** Consider items 1-3 above in a future polish pass. Add the two suggested ledger rows post-merge.

**Commit footer suggestion** (per `phase-1-review.md` §5):

```
coder-critic: PASS (94/100); 3 Minor recommendations deferred (status-line tense, override-block locality, run_data_checks defensive assert).
```

---

## Escalation Status

None. Single round; PASS on first review.
