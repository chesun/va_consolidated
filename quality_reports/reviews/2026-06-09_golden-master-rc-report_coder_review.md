# m4 golden-master rc-detail-string fix Review — coder

**Date:** 2026-06-09
**Reviewer:** coder-critic
**Target:** `do/check/m4_golden_master.do` (Phase 1c §5.3-adjacent — golden-master verification harness; rc-detail-string bug-fix)
**Score:** 96/100
**Mode:** Full (Phase 1c bug-fix; Execution-phase severity)
**Status:** Active

---

## Verdict: PASS (96/100)

The fix is correct, complete, minimal, and confined to the human-readable `details` string. No Critical or Major findings. One Minor finding (ledger hygiene) below. This is the same `_rc`-capture idiom already verified and accepted in the sibling fix (`2026-06-09_check-files-rc-fix_coder_review.md`, PASS 95) — the difference is purely the destination of the captured rc (here a `return local details` string, there an `exit `rc'`).

## Code-Strategy Alignment: MATCH

The change implements exactly what the dispatch and the bug description specify, with no silent deviation.

- **The bug is real.** Lines 139, 164, 189, 211 built detail strings with `` `_rc' `` — local-macro syntax for a local that is never defined — so it expanded to empty and the summary printed `rc=` (blank). Confirmed empirically in the dispatch (smoke run's READ_ERROR on `va_all.dta` logged `rc= on cf _all`).
- **The categorization was never broken.** The `if _rc {` guards (L136, L161, L186, L208) read the *system* `_rc` correctly — they fire on the genuine return code. Only the *reported* detail lost the code. The fix is therefore a pure reporting correction with no effect on which status (READ_ERROR/FAIL/PASS/SKIP) a row receives.
- **Impact justifies the fix.** In the full 8,324-pair run, every READ_ERROR/FAIL detail would have hidden its rc, defeating triage (cannot distinguish r(601) missing-file from r(9)/r(111) structural mismatch). The fix restores the diagnostic signal at the only point it is consumed (offline summary read).

## Sanity Checks: PASS

### Concern 1 — idiom correctness (`local rc = _rc` first inside each guard; `` `rc' `` then used)

PASS. All four fixed branches were inspected line-by-line; in each, `local rc = _rc` is the FIRST statement inside the `if _rc {` block, captured before the `return local` commands (which reset `_rc`):

- **dta cf READ_ERROR** (L136–141): `if _rc {` → `local rc = _rc` (L137) → `return local status`/`return local details = "rc=`rc' on cf _all"` → `exit`.
- **dta cfout-fallback FAIL** (L161–166): `if _rc {` → `local rc = _rc` (L162) → `return local details = "cf:`nsum' obs-diffs (cfout fallback rc=`rc')"` → `exit`.
- **ster pred-load READ_ERROR** (L186–191): `if _rc {` → `local rc = _rc` (L187) → `return local details = "rc=`rc' loading pred .ster"` → `exit`.
- **ster cons-load READ_ERROR** (L208–213): `if _rc {` → `local rc = _rc` (L209) → `return local details = "rc=`rc' loading cons .ster"` → `exit`.

Two sub-claims, both sound (and identical to the verified sibling fix):

1. **`local rc = _rc` does not reset `_rc`.** An expression-assignment `local name = <expr>` reads `_rc` but is not a command that sets a return code, so `_rc` retains the value left by the preceding `capture {...}` / `capture estimates use`. Placing it after `if _rc {` is safe: the `if` test reads `_rc` but does not alter it, so the capture grabs the same genuine rc the guard tested on.
2. **The capture must precede the `return local` commands.** `return local ...` is a command that sets its own `_rc` (0 on success), so referencing `` `_rc' `` after them — the pre-fix bug — would have read 0 even if the local-vs-system confusion had not also been present. The fix's ordering (capture first) is correct on both counts.

I could not re-run Stata in this critic toolset (disclosed), but the semantics are standard batch behavior, the idiom is byte-identical in shape to the one independently `stata17`-verified for the sibling check-files fix (ledger row `do/check/check_va_estimates.do | diagnosis:fail-branch-exit-rc-clobber | DIAGNOSED`, "stata17-verified: rc preserved as 9 across di/cap clobber"), and the cf/cfout/estimates programs all leave `_rc` set per Stata's `capture` contract.

### Concern 2 — completeness

PASS. Verified by grep:

- `` `_rc' `` (the buggy local-macro form) → **0 matches** across the whole file.
- `local rc = _rc` → exactly **4 matches** at L137, L162, L187, L209 — the four fixed branches.
- The four `details` strings that should now carry the code do so: L139 `rc=`rc'`, L164 `rc=`rc'`, L189 `rc=`rc'`, L211 `rc=`rc'`.

The dispatch's claimed "all 4 `` `_rc' `` misuses fixed" is exact.

### Concern 3 — no over-reach (pre-existing correct system-_rc captures untouched)

PASS. The shell-diff sections (tex/pdf/csv comparators) already used the *correct* idiom — capturing `_rc` into distinctly-named locals before reuse — and the fix does not touch them:

- `cap_compare_tex`: `local rc_cmp = _rc` (L279), `local rc_strip = _rc` (L292).
- `cap_compare_pdf`: `local rc_cmp = _rc` (L323), `local rc1 = _rc` (L340), `local rc2 = _rc` (L342), `local rc_text = _rc` (L351).
- `cap_compare_bytes`: `local rc_cmp = _rc` (L370).

Crucially, the fix's new local is named `rc`, which does NOT collide with any of these (`rc_cmp`, `rc_strip`, `rc1`, `rc2`, `rc_text`) — and in any case each comparator is a separate `program define` scope, so even a name reuse would not leak across programs. No name-collision risk. The status-categorization logic, the dispatch loop, the tally counters, and the tolerance comparisons in `cap_compare_ster` (which use `max_b_diff`/`max_se_diff`, not `_rc`) are all unchanged.

### Concern 4 — no behavior change beyond the detail string

PASS. The diff is exactly: 4 inserted `local rc = _rc` lines + 4 `` `_rc' `` → `` `rc' `` substitutions in detail strings (+8/−4 net by the dispatch's count; consistent with what I see in the file). The four `return local status` values (READ_ERROR ×3, FAIL ×1) are unchanged, so the per-status counters, the summary tally, and the PASS/FAIL decision for every file pair are identical to pre-fix. Only the offline-readable `details` field now carries the real code. No change to which files are compared or how PASS/FAIL is decided.

## Robustness: Complete (for the stated scope)

The fix is scoped to the four error-detail strings only. It correctly leaves the comparator logic, tolerances (per `replication-protocol.md §3`), tier filtering, and the air-gap export discipline ($output_dir summary only) untouched. There is no robustness "matrix" to re-run here — this is a one-shot verification harness, not a pipeline producer.

## Code Quality (10 categories)

| Category | Status | Issues |
|----------|--------|--------|
| Script structure | OK | Full header block (purpose / invoked-from / inputs / outputs / role / tolerances / dispatch / tier / packages / defensive / references); numbered `/*===*/` sections; subroutines defined before dispatch loop. Unchanged by this fix. |
| Console output hygiene | OK | `di as text`/`di as error` used for run progress + summary (legitimate check reporting, not status banners); unchanged |
| Reproducibility | OK | No seed needed (deterministic diffs); paths via globals (`$consolidated_dir`, `$output_dir`, `$logdir`); predecessor/consolidated paths come from `m4_path_matrix.csv`, not hardcoded |
| Function/program design | OK | `cap program drop` before each `program define ..., rclass`; `args` for parameters; returns `r(status)`/`r(details)` via `return local` — consistent rclass contract. Helper-comparator design is sound. |
| Figure quality | OK | N/A — no figures |
| Output persistence | OK | Writes only `$output_dir/m4_diff_summary.txt` + log; correct for a verification harness (no data writes by design) |
| Comment quality | OK | WHY-comments throughout (data-context discipline note at L489–503, tolerance rationale at L257–260); no dead code; the fix added no comments |
| Stata comment safety | OK | State-machine balance satisfiable: all 8 `/*` (L1, 114, 388, 397, 448, 474, 489, 640) pair cleanly with 8 `*/`; no path-glob `*` inside any comment context; no Variant-8 over-flatten artifacts (`^-+<x>$` and `^\s*<x>\s*$` both 0); no `//*****` banners. The awk `gsub(/.../, "NUM")` regexes at L291 contain `*` but are inside double-quoted shell strings, not comments, so they are parser-safe and out of scope for the comment-balance check. |
| Error handling | OK (this fix improves it) | Every comparison wrapped in `capture`; status enumerated (READ_ERROR/FAIL/MISSING/SKIP/UNKNOWN). This fix corrects the one defect: the reported rc was lost. After the fix, READ_ERROR/FAIL details carry the genuine code. |
| Professional polish | OK | 4-space indent inside programs/conditionals consistent with the file; backtick-quoting of `` `rc' `` correct; lines within reasonable length |

## Tier-1 Pre-commit (phase-1-review §2)

PASS.

- **`/*` balance:** 8 `/*` = 8 `*/` (state-machine satisfiable — all are legitimate block-comment headers; the fix added no comments and no path-glob `*`).
- **Brace balance:** opens == closes (56 lines each by grep line-count; raw-char balance also holds — no unbalanced `{`/`}` introduced; the fix added only `local`/string lines, no braces).
- **Log path:** unchanged; `$logdir/check/m4_golden_master.smcl` + `.log` mirrors `do/check/ → $logdir/check/` (L111, L675). `cap mkdir "$logdir"` + `cap mkdir "$logdir/check"` present (L107, L110).
- **No hardcoded absolute paths:** `grep -nE '"/Users|"/home|"C:\\'` → 0 matches. Predecessor/consolidated paths are read from `m4_path_matrix.csv` rows, not literals. (Note: the file *header comment* mentions Scribe `/home/research/...` paths as documentation of where the harness reads — these are in comment context, not executable code, and are correct for an on-Scribe one-shot harness per the air-gapped rule.)
- **No new LEGACY-path writes:** the diff adds only `local`/`return local` statements; no `save`/`export`/`esttab`/`graph export`/`log using`/`translate` added or repointed. Sole export remains `$output_dir/m4_diff_summary.txt` (CANONICAL).
- **Scope minimal:** +8/−4, exactly the four detail-string branches. No unrelated edits.

## Score Breakdown

- Starting: 100
- Minor — ledger hygiene: no `no-logic-change` ledger row was recorded for this session's edit, and no row exists for `do/check/m4_golden_master.do` at all (the file's prior reviews predate the ledger's per-file rows for this script). For this change a `no-logic-change` row would correctly be `UNVERIFIED` — the `details` string *is* an observable behavior change (the rc now appears) — but the absence should be stamped rather than left implicit, and a `no-hardcoded-paths` PASS row would be worth caching given the smoke run is now the empirical ground truth. Same ledger-hygiene class flagged on the sibling rc-fix (2026-06-09). −4
- **Final: 96/100**

## Compliance Evidence (from .claude/state/verification-ledger.md)

- `do/check/m4_golden_master.do` | no-logic-change | (MISSING — recorder not run for this edit; the change is an intentional, observable behavior change to the `details` string, so a recorded row would correctly be `UNVERIFIED`, NOT a clean-refactor PASS. Noted; the Tier-1 no-logic-change gate does not bind to deduct here because no clean-refactor PASS is being claimed — this is an avowed reporting-behavior fix.)
- `do/check/m4_golden_master.do` | no-hardcoded-paths | (MISSING — re-verified live this session: `grep -nE '"/Users|"/home|"C:\\'` over executable lines returned 0 matches; only header-comment Scribe paths present, which are documentation. Worth caching as PASS.)
- `do/check/m4_golden_master.do` | comment-balance | (MISSING — re-verified live: 8 `/*` = 8 `*/`, all legitimate headers; no path-glob `*` in comments; no Variant-8 artifacts. Worth caching as PASS.)

Note: this is a deliberate, documented reporting-behavior fix (READ_ERROR/FAIL details now carry the genuine rc), not a refactor. No clean-refactor `PASS` is claimed, so the Tier-1 no-logic-change gate does not bind in a way that deducts beyond the Minor ledger-hygiene note above.

## Tier-2 verdict evidence (behavior-preservation / goal-achieved)

- **Claim 1:** All four error-detail branches now report the genuine system `_rc`, captured before the `return local` commands that would reset it; no other behavior changes.
  - **artifact_citation:** `do/check/m4_golden_master.do:136-141`, `do/check/m4_golden_master.do:161-166`, `do/check/m4_golden_master.do:186-191`, `do/check/m4_golden_master.do:208-213`
  - **sufficiency_argument:** Each cited range shows the ordered sequence `if _rc {` → `local rc = _rc` (first statement, before any `return local`) → `return local details = "...rc=`rc'..."` → `exit`. Grep across the file returns zero `` `_rc' `` (the buggy form) and exactly four `local rc = _rc`, so the transform is total over the four error branches and present nowhere else. The capture-before-`return local` ordering is what guarantees `` `rc' `` carries the assert/read rc rather than the `return local`'s 0, which is the entire bug.
- **Claim 2:** The pre-existing correct system-_rc captures in the shell-diff comparators are untouched and do not collide with the new `rc` local.
  - **artifact_citation:** `do/check/m4_golden_master.do:279`, `do/check/m4_golden_master.do:292`, `do/check/m4_golden_master.do:323`, `do/check/m4_golden_master.do:340-342`, `do/check/m4_golden_master.do:351`, `do/check/m4_golden_master.do:370`
  - **sufficiency_argument:** These captures use distinctly-named locals (`rc_cmp`, `rc_strip`, `rc1`, `rc2`, `rc_text`) inside separate `program define` scopes from the four fixed branches (which live in `cap_compare_dta` and `cap_compare_ster`). The new local `rc` shares no name with any of them, and program scopes isolate locals regardless, so there is no shadowing or leakage. They appear in `cap_compare_tex`/`cap_compare_pdf`/`cap_compare_bytes`, none of which the fix edits.

## Escalation Status: None
