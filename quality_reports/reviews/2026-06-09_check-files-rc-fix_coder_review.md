# check-files rc-clobber fix Review — coder

**Date:** 2026-06-09
**Reviewer:** coder-critic
**Target:** `do/check/check_va_estimates.do`, `do/check/check_survey_indices.do` (Phase 1c §5.3 hard-halt rc-clobber fix)
**Score:** 95/100
**Mode:** Full (Phase 1c §5.3 bug-fix; Execution-phase severity)
**Status:** Active

---

## Verdict: PASS (95/100)

The fix is correct, complete, minimal, and restores the documented hard-halt intent. No Critical or Major findings. Two Minor findings (one doc-fidelity, one ledger-hygiene) below.

## Code-Strategy Alignment: MATCH

The change implements exactly what the design memo and `do/main.do` document, with no silent deviation.

- **Documented intent (primary sources read):**
  - Design memo `quality_reports/reviews/2026-04-28_data-checks-design.md:319` — "Defaults ON. A failed `assert` in any check halts the pipeline; partial outputs preserved."
  - `do/main.do:1162-1163` — "A failed `assert` halts the pipeline at the offending check, leaving partial outputs on disk for diagnosis."
  - `do/main.do:1169-1172` — "Stop-on-error is preserved: if a do file errors, the pipeline halts and the LAST [RUN] line in the master log with no following [OK]/phase-end is the culprit."
- **The bug it fixes is real and empirically confirmed.** The invocation block (`do/main.do:1173-1203`) calls each `do do/check/check_*.do` and *unconditionally* prints `  [OK]  ...` on the next line — the `[OK]` is not gated on the sub-do's return code. A sub-do that `exit`s 0 therefore prints `[OK]` even after a FAIL. The pre-fix `exit _rc` clobbered the assert's rc with the rc of the intervening `cap log close` / `cap translate` (which succeed, rc=0), so the pipeline did not halt. Corroborated by the prior log review (`2026-06-08_server-run-e968d13_log-review.md`, cited in dispatch).

## Sanity Checks: PASS

### Concern 1 — idiom correctness (`local rc = _rc` preserves rc; `exit `rc'` propagates)

PASS. Two sub-claims, both sound:

1. **`local rc = _rc` does not reset `_rc`.** In Stata, an expression-assignment `local name = <expr>` reads `_rc` but is not a command that sets a return code, so `_rc` retains the value left by the preceding `capture assert`. Hence the unchanged `if _rc {` test on the next line still fires on the assert's rc, and `local rc` faithfully captures it for the `exit`. The author's standalone `stata17` test (rc=9 captured into `rc`; `_rc` still 9 at the `if`; `cap log close`→111, `cap translate`→601 clobber `_rc`; `exit `rc'` exits 9) is the correct demonstration. I could not re-run Stata in this critic toolset (disclosed), but the semantics are standard batch behavior and are independently corroborated by the main.do header's own stop-on-error design statement.
2. **A nonzero `exit `rc'` from a `do`-called file propagates and halts the caller in batch mode.** Standard Stata behavior; this is the exact mechanism `do/main.do:1169-1172` relies on ("if a do file errors, the pipeline halts"). After the fix, `exit `rc'` carries the genuine nonzero assert rc (9), so the caller halts before the next `[OK]` line prints — restoring the documented "last [RUN] with no [OK]" culprit signal.

### Concern 2 — completeness

PASS. Every fail-branch that previously did `exit _rc` now has a paired `local rc = _rc` captured immediately after the `capture`, before any clobbering `di`/`cap`, and changes `exit _rc` → `exit `rc'`. Verified by grep:

- `check_va_estimates.do`: 3 `capture assert` (L101, L114, L129) → 3 `local rc = _rc` at the correct spot (L102, L115, L130) → 3 `exit `rc'` (L107, L121, L135). Zero bare `exit _rc` remain. The `local rc` is in each case placed *before* the `di`/`cap log close`/`cap translate` lines, so it never captures a clobbered 0.
- `check_survey_indices.do`: 10 hard branches — `capture assert _N==5625` (L149/150/155), source `inrange(r(min),…)` (L164/165/170) + `inrange(r(max),…)` (L172/173/178), `capture confirm variable` (L185/186/191), z-index mean/sd/min/max (L220/228/236/244 → captures L221/229/237/245 → exits L226/234/242/250), raw-index min/max (L261/270 → captures L262/271 → exits L268/277). 10 × `local rc = _rc`, 10 × `exit `rc'`, zero bare `exit _rc`.

This matches the dispatch's claimed 3 + 10 transform count exactly.

### Concern 3 — no over-reach

PASS. The three categories of branch that must NOT change are all untouched:

- **Skeleton clean-skip** `capture confirm file "`in_dta'"` → `exit 0` (`check_va_estimates.do:79-87`) — intentional clean skip when the input is absent; correctly left as `exit 0` (not converted, since rc here is a *found/not-found* signal, not a data FAIL).
- **`continue` skeleton skips** (`check_survey_indices.do:139-144` source files, L205-211 built-index files) — `capture confirm file` → `continue`, no `exit`. Untouched.
- **Soft-signal branches** `capture qui corr` (`check_va_estimates.do:147,163`; `check_survey_indices.do:283`) — diagnostic `if _rc`/`if `r_…'` blocks with no `exit`. Untouched. Confirmed L283-296 carries no `exit`.
- **Bare item-count `assert`** (`check_survey_indices.do:119-121`, no `capture`) — these halt natively (uncaptured assert failure stops the do-file), so no rc-capture idiom is needed. Correctly left alone.

### Concern 4 — Pre-commit Tier-1 (phase-1-review §2)

PASS.

- **`/*` balance:** `check_va_estimates.do` 5 `/*` = 5 `*/`; `check_survey_indices.do` 5 `/*` = 5 `*/`. (Matches dispatch's reported 5/5; no path-glob `*` introduced inside any comment by this change — the added lines are `local rc = _rc` and `exit `rc'`, no comments.)
- **Log paths:** unchanged; both still mirror `do/check/ → $logdir/check/<name>.{smcl,log}` (`check_va_estimates.do:65/188`, `check_survey_indices.do:83/309`).
- **No new LEGACY-path writes:** the diff adds only `local`/`exit` statements; no `save`/`export`/`esttab`/`graph export`/`log using`/`translate` added or repointed.
- **Scope minimal:** diff is exactly the rc-clobber fix — 13 `local rc = _rc` insertions + 13 `exit _rc`→`exit `rc'` substitutions. No unrelated edits.

### Concern 5 — side effects of `local rc` in loops / macro reuse

PASS. Two sub-questions:

1. **`local rc` inside `foreach`:** the macro is set and consumed within the same iteration (set right after `capture`, read on the next `exit `rc'` two lines later). On a PASS iteration, `rc`=0 is set and never read (no `exit` fires). No cross-iteration leakage of consequence — even if a prior iteration left `rc`=0 in scope, the current iteration's `capture` + `local rc = _rc` overwrites it before any `exit` is reachable. Sound.
2. **Reusing the name `rc` across all branches:** locals are file-scoped; reusing one name `rc` across sequential branches is fine because each branch reassigns it immediately before use. No shadowing risk (no nested do-file scope crosses these branches). Acceptable and arguably cleaner than 13 distinct names.

## Robustness: Complete (for the stated scope)

The fix is scoped to the rc-clobber mechanic only. It correctly does NOT touch the assert thresholds or the two underlying data FAILs (`n_g11_ela_l_sp` min=4<5; imputed `secqoi27` max=2.61>2.01) — those are separate researcher decisions, explicitly out of scope per dispatch. After this fix lands, those two real FAILs will (correctly) halt the pipeline rather than silently passing — which is the entire point. Note for the operator: the next M4/acceptance run will now HALT at `check_va_estimates.do` (the min-count FAIL) unless the data issue or threshold is resolved first. That is expected and desired behavior, not a regression of this fix.

## Code Quality (10 categories)

| Category | Status | Issues |
|----------|--------|--------|
| Script structure | OK | Numbered sections, full header blocks, clear execution order — unchanged by this fix |
| Console output hygiene | OK | `di as error`/`di as text` used appropriately (these are check-result reporting, not status banners); unchanged |
| Reproducibility | OK | No seed needed (deterministic asserts); paths via globals; no absolute paths added |
| Function/program design | OK | N/A — linear check scripts |
| Figure quality | OK | N/A |
| Output persistence | OK | N/A — check files persist only logs (correct for their role); no data writes |
| Comment quality | OK | Existing WHY-comments preserved; no dead code added |
| Stata comment safety | OK | `/*` balance 5/5 both files; no path-glob `*` in comments introduced; no Variant-8 artifacts; no `//*****` banners added |
| Error handling | OK (improved) | This fix *is* the error-handling correction — `capture` + rc-capture + propagating `exit` now correct |
| Professional polish | OK | 4-space indent inside loops/conditionals consistent with surrounding code; backtick-quoting of `` `rc' `` correct |

## Score Breakdown

- Starting: 100
- Minor — doc-fidelity drift: file-header INVARIANTS blocks (`check_va_estimates.do:33-34`, `check_survey_indices.do:48-49`) say "Hard asserts" / "(display as error, non-halting)" but do not mention the rc-propagation idiom; a future reader who only reads the header would not learn that the fail-branch uses `exit `rc'` rather than `exit _rc`. Not load-bearing (the body is self-documenting via the explicit `local rc`/`exit `rc'`), but the same header-vs-body staleness class flagged on `check_logs.do` (2026-06-01 F1). -3
- Minor — ledger hygiene: the existing ledger rows for both files (lines 32-37, hashes `21a2be73fb53` / `4926001734ca`, dated 2026-04-29) are now STALE (both files edited by this fix). They are `no-hardcoded-paths`/`no-raw-data-overwrites`/`adr-0021-sandbox-write` checks — unaffected in substance by an rc-only edit — but the hashes no longer match and should be re-stamped, and a `no-logic-change` row was NOT recorded for this session's edit (the change is an intentional behavior change, so `no-logic-change` would correctly be `UNVERIFIED`/not-applicable, but the absence should be noted rather than left implicit). -2
- **Final: 95/100**

## Compliance Evidence (from .claude/state/verification-ledger.md)

- `do/check/check_va_estimates.do` | no-hardcoded-paths | 2026-04-29T18:55Z | hash `21a2be73fb53` | PASS (STALE — file edited by this fix; substance unaffected by rc-only edit, but hash mismatch; flagged Minor)
- `do/check/check_va_estimates.do` | adr-0021-sandbox-write | 2026-04-29T18:55Z | PASS (STALE hash; no write-target change in this diff — still log + translate to `$logdir` only)
- `do/check/check_survey_indices.do` | no-hardcoded-paths | 2026-04-29T18:55Z | hash `4926001734ca` | PASS (STALE — file edited; rc-only)
- `do/check/check_survey_indices.do` | adr-0021-sandbox-write | 2026-04-29T18:55Z | PASS (STALE hash; no write-target change)
- `do/check/check_va_estimates.do` | no-logic-change | (MISSING — and correctly so: this is an intentional behavior change, so a no-logic-change PASS would be wrong; the recorder, if run, would emit UNVERIFIED. Noted, not deducted as a Tier-1 violation because no clean-refactor PASS is being claimed.)
- `do/check/check_survey_indices.do` | no-logic-change | (MISSING — same rationale)

Note: this is a deliberate, documented behavior change (restoring hard-halt), not a refactor. No clean-refactor `PASS` is claimed, so the Tier-1 no-logic-change gate does not bind here in a way that would deduct beyond the Minor ledger-hygiene note above.

## Tier-2 verdict evidence (behavior-preservation / goal-achieved)

- **Claim:** Every former `exit _rc` fail-branch now propagates the genuine assert rc via `exit `rc'`, with the rc captured before any clobbering command.
  - **artifact_citation:** `do/check/check_va_estimates.do:101-107`, `do/check/check_va_estimates.do:114-121`, `do/check/check_va_estimates.do:129-135`; `do/check/check_survey_indices.do:149-156`, `do/check/check_survey_indices.do:164-178`, `do/check/check_survey_indices.do:185-191`, `do/check/check_survey_indices.do:220-251`, `do/check/check_survey_indices.do:261-277`
  - **sufficiency_argument:** Each cited range shows the ordered triple `capture <assert/confirm>` → `local rc = _rc` (immediately after, no intervening command) → `if _rc { … exit `rc' }`. Grep across both files returns zero `exit _rc` and the exact 3+10 `exit `rc'` / `local rc = _rc` counts the fix claims, so the transform is total over the fail-branches and partial nowhere. The placement (rc-capture before `di`/`cap`) is verified by line ordering, which is what makes the propagated rc the assert's rather than the clobbered translate rc.

## Escalation Status: None
