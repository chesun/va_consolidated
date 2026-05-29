# do/main.do Master-Log Orchestration Review — coder-critic
**Date:** 2026-05-28
**Reviewer:** coder-critic
**Target:** do/main.do (master-log orchestration-only change)
**Score:** 95/100
**Status:** Active
**Mode:** Standalone (code-quality only; AIR-GAPPED — no project-pipeline run)

---

## Summary verdict

**PASS (95/100).** The change is correct, minimal, and well-documented. All 14 inserts land exactly where claimed, the 7 `log off`/`log on` pairs are correctly nested inside their `if run_X {` blocks, brace and comment balance are preserved, and the header-comment update is now accurate. The error-path behavior is sound and does not lose the master file. One Minor doc-consistency issue (the inline `(see LOG SETUP)` pointer aims at a section that does not contain the explanation) and one Minor robustness observation (master left suspended on a phase-body crash) are the only deductions.

This is a code-quality-only review (categories 4–12). No strategy memo applies; the change is a logging-orchestration fix, not an estimation change.

---

## 1. Pairing, nesting, and skipped-phase behavior — PASS

Verified by `grep -n` (not by eye). Counts and placement:

| Phase | `if run_X {` open | 3-line header ends | `log off master` | `log on master` | Block close `}` |
|---|---|---|---|---|---|
| 1 data_prep | 138 | 141 | **142** | **224** | 225 |
| 2 samples | 232 | 235 | **236** | **295** | 296 |
| 3 va_estimation | 303 | 306 | **307** | **386** | 387 |
| 4 va_tables | 394 | 397 | **398** | **412** | 413 |
| 5 survey_va | 420 | 423 | **424** | **458** | 459 |
| 6 paper_outputs | 466 | 469 | **470** | **503** | 504 |
| 7 data_checks | 511 | 514 | **515** | **531** | 532 |

- Exactly **7** `log off master` (lines 142, 236, 307, 398, 424, 470, 515) and exactly **7** `log on master` (lines 224, 295, 386, 412, 458, 503, 531). Counts match the author's claim.
- Each `log off master` sits immediately after the phase's 3-line `di ... {hline}` header (open+4). Each `log on master` sits immediately before the block's closing `}` (close−1).
- **Both** members of every pair are INSIDE the `if run_X {` block. A skipped phase (`run_X = 0`) executes neither — the master stays ON for that phase's (absent) body, which is correct: nothing runs, nothing to suppress, and the master is never left in an unexpected state.
- No `log off`/`log on master` appears outside a block or in the WRAP-UP section (the only matches in the file are the 14 listed).

Independent brace check: 7 `if run_X {` opens (grep `^if \`run_`) and 7 top-level `}` closes (grep `^}$`) — balanced. Block structure intact.

## 2. WRAP-UP intact — PASS

- Line 543: `cap log close master` — unchanged.
- Line 544: `cap translate "$logdir/main_\`stamp'.smcl" "$logdir/main_\`stamp'.log", replace` — unchanged.
- Lines 539–541: RUN END `di` banner — unchanged.
- Line 546: `di "Master log: ..."` — unchanged.
- The top-of-file `cap log close master` (line 68, pre-`include`) is also unchanged.

The WRAP-UP close + translate is reached on the normal path because, after Phase 7's `log on master` (line 531) re-enables the master, the master is ON when control reaches line 543. Correct.

## 3. Error-path soundness — PASS (acceptable; one Minor noted)

Reasoning about a mid-phase crash (a `do do/...` sub-script errors while the master is suspended):

- Stata `-b` halts on the error. The `log on master` at the end of the crashing phase's block does NOT execute, so the master remains **suspended** (off). The phase's per-file log (opened by the sub-do via its own `log using ... name(<stem>)`) captures the actual error — detail is preserved where it belongs.
- The WRAP-UP `cap log close master` (line 543) also does not execute (control never reaches it). However, **Stata closes all open logs on batch (`-b`) exit**, so the master `.smcl` is flushed and closed by the interpreter regardless. The file is NOT lost — it ends frozen at the crashing phase's header banner, with no RUN END line. That absent RUN END is itself a useful diagnostic signal ("the run died inside phase N").
- The `cap translate` to `.log` (line 544) won't run on the crash path, so a crashed run leaves the master as `.smcl` only (no `.log` mirror). This is acceptable: `.smcl` is readable in Stata and via `type`/`translate` after the fact; the human reading a failed run goes to the per-file log for the error anyway.

Conclusion: the error path does not lose the master file and leaves a coherent (if truncated) record. Acceptable.

**Minor (M-1, −2):** On a phase-body crash the named master log is left in the `off` state at interpreter exit. This is benign for a `-b` run (process exits; log auto-closes). It would matter only if `main.do` were ever `do`-sourced inside an interactive session that continues afterward — the master would silently stay suppressed. Not the documented invocation (INVOCATION block specifies `stata -b do do/main.do`), so this is an observation, not a blocker. No `capture`/cleanup-trap is warranted given the batch-only invocation; flagging for awareness only.

## 4. Brace + comment balance, no path-glob in comments — PASS

- Brace balance unchanged (see §1): 7 block opens, 7 closes; the inserted lines are bare commands + `//` line comments, introducing no braces.
- Comment balance: `grep -c '/\*'` = **12**, `grep -c '\*/'` = **12**. Matches the author-reported 12/12. The change introduced zero new `/* */` block-comment delimiters (the header edit modified prose inside the existing top block; the 14 inserts use `//` line comments only).
- No `*` path-glob in any new comment. The 14 inserted `//` comments and the header-block edit were grepped (`orchestration-only|resume master|orchestration layer`): the only tokens are prose ("orchestration-only", "suspend master during phase body", "resume master for the orchestration layer", "(see LOG SETUP)"). No `prepare/*`-style glob, no parser hazard. Consistent with `.claude/rules/stata-code-conventions.md` § Wildcards in comments.

State-machine balance is not separately disturbed: the edit added no comment-context-opening sequences. The existing 12/12 was already verified for this file in prior reviews (e.g., `2026-05-25_main-do-clean-va-reorder` 12/12; `2026-05-28_prior-score-gate`); the new inserts do not touch it.

## 5. Comment accuracy — PASS on header; Minor on inline pointer

- **Header block (lines 51–57) now TRUE.** It claims: "The master log captures only the orchestration layer (which phases ran, runtime, exit codes), not the full sub-do transcript. Each phase body runs with the master log suspended (named-log off at the start of the phase, named-log on at the end), so sub-do output goes only to the per-file logs." Given the 14 verified inserts, this is now an accurate description of runtime behavior. The header claim is no longer aspirational — the edits make it real.
- **Minor (M-2, −3): inline `(see LOG SETUP)` pointer is misdirected.** All seven `log off master` lines carry `// orchestration-only: suspend master during phase body (see LOG SETUP)`. The LOG SETUP section (lines 76–88) only opens the master log (`log using ... name(master)`); it contains **no** explanation of the suspend/resume design. The actual explanation lives in the top header block (lines 51–57, dated `[2026-05-28]`). A reader following the `(see LOG SETUP)` pointer will not find the rationale where the comment sends them. Low-stakes, but it's a self-referential doc inaccuracy in a load-bearing master file. Suggested fix (recommendation, not an edit — critics do not edit source): change the parenthetical to `(see header block)` or `(see top-of-file CONVENTIONS)`, or alternatively add a one-line explanation under the LOG SETUP banner so the pointer resolves. Either resolves it.

## 6. Scope — PASS

The diff is confined to: (a) 7 `log off master` inserts, (b) 7 `log on master` inserts, (c) the header-comment update at ~L51–57 describing the new behavior. No estimation logic, no toggles, no phase-body invocations, no path references, no settings changes. No unrelated cleanup riding along. Matches the stated 14 inserts + 1 comment update exactly.

---

## Code Quality (categories 4–12)

| Category | Status | Notes |
|---|---|---|
| 4. Script structure & headers | OK | Header block updated, dated `[2026-05-28]`, accurate post-edit |
| 5. Console output hygiene | OK | Uses `di as text` (Stata idiom; not `display`-as-status-pollution); no banners added |
| 6. Reproducibility | OK | No path/seed changes; relative `include do/settings.do` preserved |
| 7. Program design | OK | No programs touched; wrapper-program approach correctly rejected (55 sub-dos `clear all` would drop a program) |
| 8. Figure quality | n/a | No figure code |
| 9. Output persistence | OK | Logging change is itself an output-persistence improvement (master now small/pushable; detail in per-file logs) |
| 10. Comment quality | WARN | Header now accurate (good); inline `(see LOG SETUP)` pointer misdirected (M-2) |
| 10b. Stata comment safety | OK | 12/12 balance; no path-glob in comments; no Variant-8 artifacts introduced |
| 11. Error handling | OK | Crash path leaves coherent truncated master; `-b` auto-closes logs; M-1 observation only |
| 12. Professional polish | OK | Consistent indentation inside blocks; comment text aligned across all 7 pairs |

---

## Score breakdown

- Starting: 100
- M-1 (master left suspended on phase-body crash; benign under `-b`-only invocation, robustness observation): **−2**
- M-2 (inline `(see LOG SETUP)` pointer aims at a section lacking the explanation; doc-consistency): **−3**
- **Final: 95/100** — PASS (≥ 80, clears the commit gate)

---

## Compliance Evidence (from .claude/state/verification-ledger.md)

- `do/main.do` | gate-parity | 2026-05-07T23:30Z | hash `f9497e091c8a` | PASS — **STALE** (file edited many times since; hash no longer current). Not relevant to this logging change.
- `do/main.do` | brace-balance-batch-3d | 2026-05-08T03:00Z | hash `02149ecb668c` | PASS — **STALE** (hash no longer current). Brace balance independently re-verified this session (7 opens / 7 closes, §1).
- `do/main.do` | master-log-orchestration | (MISSING — no ledger row for this check)

Note on the missing/stale rows: per `adversarial-default.md`, an inherited file with no current ledger row for the check at hand would normally draw a deduction. Here the file was just edited by the author in this work cycle (not a cold-inherited artifact), the change is a self-contained 14-insert logging edit, and the load-bearing properties (pairing, nesting, brace balance, comment balance, path-glob absence) were each independently re-verified above with concrete grep evidence rather than relying on cache. No deduction is applied for the missing ledger row on that basis, but the row SHOULD be appended on commit: `do/main.do | master-log-orchestration | <ts> | <new-hash> | PASS | 7 log off/7 log on, each inside its if run_X block (off after header L142..L515, on before close L224..L531); 12/12 comment balance; WRAP-UP close+translate intact`.

---

## Recommendations (not edits — author's discretion)

1. **(M-2, low effort)** Change the seven inline `(see LOG SETUP)` parentheticals to point at the header block where the rationale actually lives, OR add a one-line note under the LOG SETUP banner (L76–88). Either makes the cross-reference resolve.
2. **(Optional)** Append the `master-log-orchestration` ledger row on commit (text above) so the next reviewer can cite the cache.
3. **(M-1, informational)** If `main.do` is ever sourced interactively rather than via `stata -b`, consider a trailing `cap log on master` safety line; unnecessary for the documented batch invocation.

## Escalation Status: None (round 1, PASS)
