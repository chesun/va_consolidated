# check_logs.do Rewrite Review — coder-critic

**Date:** 2026-06-01
**Reviewer:** coder-critic
**Target:** `do/check/check_logs.do` (2026-06-01 [RUN]-scoped, reldir-mirrored rewrite)
**Score:** 88/100
**Status:** Active
**Mode:** Full (Phase 1c data-checks; Execution severity)
**Supersedes:** none (no prior Active coder review for this target slug)

---

## Verdict: PASS — clear for commit (>= 80 hard gate)

The three fixes are correct. The regex hardening genuinely closes the false-FAIL
defect the adversarial review found. The code logic is sound on all hard mechanics.
The deductions are for a **stale top-of-file header that now contradicts the rewritten
body** (a documentation-fidelity defect the adversarial review missed) plus minor
convention/ledger nits.

---

## Code-Strategy Alignment: MATCH

The change implements exactly the three fixes described, traceable to the ledger
`diagnosis:` rows (2026-06-01T20:00Z) and ADR-0021/plan-v3 §5.3:

1. `norecur(0)` (r198) -> omitted; filelist recurses by default. Corroborated against
   the in-code citation (line 79: filelist.ado syntax `[... noRecursive MAXdeep ...]`)
   and the ledger `diagnosis:filelist-norecur-r198` row.
2. Expected log path now reldir-mirrored: `$logdir/<reldir>/<name>.smcl` where
   `reldir = subinstr(dirname, "$consolidated_dir/do", "", 1)` (line 126). Matches the
   per-file logging convention in `stata-code-conventions.md`.
3. Scope narrowed to files that ran this run via `[RUN]` master-log markers, with the
   anchored regex at line 164.

---

## Independent verification of the 3 core cases (concern #1)

**Constraint disclosed honestly:** my available toolset (Read/Grep/Glob) does **not**
include Bash execution, so I could **not** re-run `stata17 -b` harnesses myself. I built
the harness (`/tmp/cc_test/run_tests.sh`) but could not execute it. Instead I corroborated
each case by (a) **static trace of the actual code** against (b) the **real two-form SMCL
markers** I read directly from `log/main_-1-Jun-2026_19-50-47.smcl:1067-1068`. This is
code-reading + real-log evidence, not re-execution — weaker than the adversarial review's
13 live harnesses, but independent of its conclusions.

Regex under test (compound-quote-delimited, so embedded `"` are literal):
`` `"\[RUN\] (do/[^ "]+\.do)("|$)"' ``

Real master log holds TWO lines per marker (confirmed at lines 1067-1068):
- command-echo: `.     di as text "  [RUN] do/check/check_logs.do"` — path ends at a `"`
- di-output:    `  [RUN] do/check/check_logs.do` — path ends at EOL

| Case | Trace | Result |
|------|-------|--------|
| **(a) genuine marker + log present** | both forms match (`"` and `$` alternation); `regexs(1)=do/check/check_logs.do`; `replace ran_this_run=1` (idempotent across the two forms); `confirm file` succeeds -> `log_exists=1`; `n_missing=0` -> fall through | **PASS — confirmed** |
| **(b) genuine marker + log MISSING** | marker matches -> `ran_this_run=1`; `confirm file` fails -> `log_exists=0`; `n_missing=1` -> enters block -> `list` + `cap log close` + `cap translate` + `exit 9` | **FAIL exit 9 — confirmed** |
| **(c) PROSE line `... [RUN] do/x.do later ...`** | after `.do` the next char is a space (not `"`/not EOL) -> `("|$)` fails -> `regexm`=0 -> not flagged -> `ran_this_run=0` -> `n_missing=0` | **No false-FAIL — confirmed** |

I **corroborate** all three of the adversarial review's post-fix results. The strpos->regex
hardening is real and correct.

### One residual edge the adversarial review framed as out-of-scope, restated precisely
A prose line whose text **ends** with a bare do-path (`...mentions do/va/alpha.do` at EOL,
no trailing token) WOULD match the `$` alternation and false-flag. This is intrinsic to the
marker design — a di-output marker is itself "a line ending in a bare do-path" — so the
two are not distinguishable by the consumer. The mitigation lives in main.do's marker
emission (the producer), not here. Severity: Low. Not a check_logs defect; noted for the
record. (The adversarial review's "vacuous-PASS/marker-emission" open item is the dual of this.)

---

## Sanity Checks: PASS

- **`clear all` (L39) vs `log query master` (L141):** `clear all` clears data/programs/
  macros/Mata but does NOT close open log handles (only `log close` / `cap log close _all`
  do). The session-level `master` handle survives, so `log query master` returns
  `r(filename)` while suspended (`log off master`, the Phase-7 state). Corroborated from
  Stata semantics + the main.do orchestration (master opened L122 `name(master)`, suspended
  L1157/L1175 around the check_logs call, closed L1216). Not a no-op false PASS.
- **Marker ordering:** main.do writes each `[RUN]` while master is ON, then `log off master`
  before the `do` (L1173-1176). check_logs runs first in Phase 7, so the master log contains
  every Phase-1..6 marker plus check_logs's own — but NOT the later Phase-7 checks
  (check_samples etc., written L1179+). Correct: those run after check_logs and write their
  own logs; check_logs simply doesn't assert them (runs-first ordering). Acceptable scope.
- **filelist count alignment:** `n_enumerated` (pre-drop) is reported separately from
  `n_dofiles` (post-drop of main.do/settings.do); `forvalues 1/n_dofiles` + `in i` indexing
  stay aligned after the contiguous `drop`. Cosmetic count-message fix verified present (L96/L131).

## Robustness: Complete for a structural check (no estimator; reghdfe-class items N/A)

---

## Code Quality (10 categories)

| Category | Status | Issues |
|----------|--------|--------|
| Script structure & headers | **WARN** | Header PURPOSE/INPUTS/INVARIANTS (L5-30) is STALE — contradicts the rewritten body (see Findings F1). Body section-comments (L100-122) are correct. |
| Console output hygiene | OK | `di as text/error` only; no `cat/print`; SMCL `{hline}` banners are idiomatic Stata, fine |
| Reproducibility | OK | No seed needed (no RNG); paths via `$logdir`/`$consolidated_dir` globals from settings.do (L92/L99); no abs paths in executable code |
| Function/program design | OK | Linear check script; no programs; appropriate |
| Figure quality | N/A | No figures |
| Output persistence | OK | Per-file log + `cap translate` to `.log`; sandbox-compliant (writes only `$logdir`) |
| Comment quality | **WARN** | L28 path-glob `<x>*` inside `/* */` (convention says `<x>` only); folded into F1. Body comments explain WHY well. |
| Stata comment safety | OK | `/*`=4 == `*/`=4 (balanced); no Variant-8 (`^-+<x>$`=0, `^\s*<x>\s*$`=0); no `//*****` banner; L28 `*` forms no `*/`/`/*` (no parser hazard) |
| Error handling | OK | `capture which filelist`->r198 guard; `capture log query master`->WARN+skip if standalone; `cap confirm file`; exit-9 halt semantics correct |
| Professional polish | OK | Consistent indent inside blocks; backtick-quoted locals; `macval()` quote-shielding correct |

---

## Findings

### F1 (Major→Minor, -5) — Stale top-of-file header contradicts the rewritten body
The header block was NOT updated to match the rewrite. Concrete contradictions:
- **L7:** "matching log under `$logdir/<stem>.smcl`" — body now uses reldir-mirrored
  `$logdir/<reldir>/<name>.smcl` (L128). Header describes the OLD basename-only path (the
  exact BUG A the rewrite fixed).
- **L9-12:** "the file was not invoked at all ... Either case is a regression worth halting"
  — the rewrite's BUG-B fix makes not-invoked files legitimately NOT a failure (they're
  informational). Header asserts the opposite of the new behavior.
- **L27-29 INVARIANTS:** "**Every** `do/...do` ... has a matching `$logdir/<basename-without-
  extension>.smcl`" — both the universal quantifier and "basename-without-extension" are now
  wrong (body asserts only files that RAN, reldir-mirrored).
- **L28 sub-issue:** path-glob `do/_archive/<x>*` — `<x>` placeholder used but trailed by a
  literal `*` (convention: `<x>` only). No parser hazard here (the `*` is followed by `)`, forms
  no `*/`; balance intact), so this is a convention nit, not the silent-comment-bug.

**Why it matters at Execution severity:** Phase-1-review §2 Tier-1 and ADR-0021 require the
header description to match behavior; the verifier (submission mode) and any future maintainer
read this header as the contract. A header that says "every file, basename path, not-run is a
failure" while the code does "only-ran files, reldir path, not-run is informational" is a
documentation-fidelity defect. Code is correct; the header lies about it. The adversarial
review did not examine the header block. **Recommend (not blocking): update L5-30 to describe
the reldir-mirror + ran-this-run scope before/at commit.**

### F2 (Minor, -2) — Ledger has duplicate/conflicting rows for this target
`.claude/state/verification-ledger.md` carries TWO `no-logic-change` rows for
`do/check/check_logs.do | 2026-06-01T20:00Z` with DIFFERENT hashes: `6908efa59074` (L187,
pre-regex-fix) and `70cb8367f7fd` (L191, post-fix). The `adversarial-review-defect-fixed`
row (L192) uses `70cb8367f7fd`. The earlier-hash rows (L185-187) describe the pre-hardening
state and should have been superseded/removed, not left alongside. Current file matches the
`70cb8367f7fd` description (anchored regex at L164). Ledger-hygiene nit; the current rows are
internally consistent with the file I read.

### F3 (informational, -0) — Producer-side marker fragility (out of check_logs scope)
A dropped `[RUN]` marker in main.do for a file that DID run -> `n_ran` undercount -> that file
not asserted (vacuous PASS). Plus the EOL-prose edge in concern (c) above. Both are main.do
marker-emission concerns, consistent with the design-memo scope ("files that ran per markers").
Noted; correctly not fixed here.

---

## Regression vs the other 5 check_*.do (concern #4): CLEAN
`grep` for `include`/`do ` across `do/check/` shows NO shared helper between check_logs.do and
the other five checks (only `m4_golden_master.do` includes settings.do; `m4_path_matrix_README.md`
is docs). Git status at session start lists only `check_logs.do` modified among the six checks.
Scope is correctly isolated.

---

## Compliance Evidence (from .claude/state/verification-ledger.md)
- do/check/check_logs.do | no-hardcoded-paths | 2026-04-29T18:55Z | PASS (pre-rewrite hash d1cb1e870a17 — STALE vs current file; re-verified by me: 0 abs paths in executable code; `$consolidated_dir` literal lives in settings.do:92, allowed)
- do/check/check_logs.do | adr-0021-sandbox-write | 2026-04-29T18:55Z | PASS (stale hash; re-verified: only writes are `log using $logdir` + `cap translate` to `$logdir`)
- do/check/check_logs.do | no-logic-change | 2026-06-01T20:00Z | 70cb8367f7fd | UNVERIFIED — **CORRECT verdict.** This is an INTENTIONAL behavior change (BUG-A path + BUG-B scope), not a pure refactor; a clean-refactor PASS would be wrong here. Per the no-logic-change gate, I do NOT issue a clean-refactor PASS; I cite the recorded residue and adjudicate the change on its merits (done above). No -25 deduction applies because no clean-refactor PASS was claimed by the author — UNVERIFIED is the honest, correct label.
- do/check/check_logs.do | adversarial-review-defect-fixed | 2026-06-01T20:00Z | 70cb8367f7fd | PASS (corroborated independently by static trace + real-log forms)
- do/check/check_logs.do | diagnosis:filelist-norecur-r198 | 2026-06-01T20:00Z | DIAGNOSED (corroborated by in-code citation L79)
- do/check/check_logs.do | diagnosis:checklogs-allfiles-and-basename-r9 | 2026-06-01T20:00Z | DIAGNOSED (matches BUG-A/BUG-B in body comments)
- **Ledger nit (F2):** stale duplicate rows at hash 6908efa59074 (L185-187) not superseded.

---

## Score Breakdown
- Starting: 100
- F1 stale header contradicting body (Major→Minor at this severity; code correct, header wrong): **-5**
- L28 `<x>*` path-glob convention nit (folded into F1, no parser hazard): **-3**
- F2 ledger duplicate/conflicting rows (housekeeping): **-2**
- Derive-don't-guess, abs-paths, sandbox, comment-balance, brace-balance, regex correctness, exit-semantics: all PASS, no deduction
- **Final: 88/100**

## Escalation Status: None (PASS round 1)
