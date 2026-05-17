# `do/main.do` Bugfix Bundle Review — coder

**Date:** 2026-05-17
**Reviewer:** coder-critic
**Target:** `do/main.do` (uncommitted working-tree delta; two bundled bugfixes)
**Score:** 94/100
**Status:** Active
**Supersedes:** n/a

---

## Mode

Full review (Phase 1b §4.2 — code correction to a paper-affecting orchestration file per `phase-1-review.md` §3 dispatch matrix). Hard gate 80/100. Adversarial-default stance: compliance is a positive claim and must be backed by concrete evidence (grep / line ref). Categories 1-3 (strategy alignment / sanity / robustness) interpreted relative to the dispatcher's stated intent (uncomment Phase 7 + escape `/*` in `*`-comments); categories 4-12 standard.

---

## Verdict

**PASS — score 94/100. Commit unblocked.**

Two bugfixes land cleanly. Phase 7's six `do do/check/check_*.do` calls are uncommented and verified live; the latent `/*`-in-`*`-comment parser hazard is fully resolved across all 6 sites. No scope creep, no collateral damage, no residual hazards detected.

---

## Code-Strategy Alignment: MATCH

Dispatcher described two bundled bugfixes:

1. **Bugfix 1 — Phase 7 uncomment.** Verified at lines 468-473: six `do do/check/check_*.do` invocations live, no leading `*`. `grep -nE '^\s*do\s+do/check/check_' do/main.do` returns exactly 6 hits. `grep -nE '^\s*\*\s*do\s+do/check' do/main.do` returns 0 hits (no commented-out check calls remain). All 6 referenced files exist on disk (verified via `Glob do/check/check_*.do`). Aligns with ADR-0018 acceptance criterion ("all toggles ON including run_data_checks") and the surrounding `WIRED 2026-05-17` audit-trail comment at line 467.

2. **Bugfix 2 — `/*`-in-`*`-comment escape.** Verified at lines 182, 387, 388, 389. `grep -nE '^\s*\*.*/\*' do/main.do` returns 0 hits. The original glob notation has been rewritten as `<sub>/<x>` (line 182) and `<x>` (lines 387-389), matching the existing `<sub>/<year>` placeholder convention used elsewhere in the same file (e.g., lines 167, 168). Semantic meaning preserved — readers still parse "<x>" as wildcard-placeholder.

Both fixes match the stated scope. No silent deviations detected.

---

## Sanity Checks: PASS

**Brace balance.** `grep -c '{' do/main.do` = 43; `grep -c '}' do/main.do` = 43. Equal. (Dispatcher's report of 44/44 is off by one but the load-bearing requirement is *equality*, which holds.) Structural verification: 7 phase `if {` openers (lines 125, 211, 268, 357, 381, 412, 455) ↔ 7 top-level `}` closers (lines 204, 261, 350, 374, 405, 448, 474). Inner `if `m4_acceptance_run' {` blocks (lines 227, 282) and `if `do_touse_va' {` / `if `do_create_samples' {` / `if `do_va' {` blocks all close properly within their parent phase.

**`/*` residual scan.** `grep -nE '/\*' do/main.do` returns 13 matches. Triage:

- Lines 1, 68, 83, 99, 121, 207, 264, 353, 377, 408, 451, 477: legitimate block-comment openers (`/*---` and `/*===` section banners). All paired with proper `*/` closers. Not the failure mode.
- Line 430: `// survey-VA index regression table (Table 8 panels); reads CHAIN $estimates_dir/survey_va/factor/* (Step 7)` — the `/*` here lives inside a `//` line-comment (path-glob `factor/*`). Stata's `//` consumes to EOL; the embedded `/*` cannot trigger block-comment opening. Not a hazard.
- Zero `^\s*\*.*/\*` matches (the load-bearing failure pattern: `/*` inside a `*`-prefixed comment line). Fix complete.

**Check-file existence.** All 6 files referenced at lines 468-473 exist on disk per `do/check/check_*.do` glob: `check_logs.do`, `check_samples.do`, `check_merges.do`, `check_va_estimates.do`, `check_survey_indices.do`, `check_paper_outputs.do`. No dispatch will fail with "file not found."

**No scope creep.** The two bugfixes do NOT touch:

- M4_ACCEPTANCE_RUN flag (lines 96-118, 226-230, 281-284) — these landed in the prior commit `2026-05-17_main-m4-flag_coder_review` PASS @ 94/100; this bundle leaves them untouched (verified by visual inspection of those line ranges; comments and `if `m4_acceptance_run' {` blocks intact).
- Phase 4 stub (lines 357-374) — documentation-only TODO; intentionally deferred. Confirmed untouched.
- Any other Stata code outside the 4 fix sites (lines 182, 387, 388, 389) + Phase 7 uncomment (lines 467-473).

The diff is minimal and tightly scoped to the two stated fixes.

---

## Robustness: Complete (within stated scope)

Both bugfixes are surgical. The Phase 7 uncomment is an exact reversal of the prior `*`-prefix; the `/*` → `/<x>` rewrite is a syntactic substitution with no semantic change. There is no need for a follow-up robustness check on the patch itself.

**Out-of-scope downstream risk** flagged in dispatcher context (acknowledged, not deducted): `check_survey_indices.do` reads from the wrong parent path per Partition B pre-flight finding M1 — when invoked under acceptance run, it will silent-skip via `capture confirm file`. This is **not a regression of this bundle**; the bundle merely wires the call. The latent bug pre-exists and is documented for deferred resolution. The wiring exposes the latent bug rather than introducing one, which is exactly what acceptance-run wiring is supposed to do.

---

## Code Quality (Categories 4-12)

| Category | Status | Notes |
|---|---|---|
| 4. Script structure & headers | OK | Header block at lines 1-56 unchanged; REFERENCES section cites ADR-0018 + ADR-0021 + plan v3 §3.4/§5.3 (the relevant ADRs for this bundle's scope). |
| 5. Console output hygiene | OK | No new `di` / `cat` / `print` lines added. Phase 7 already has its `di as text "PHASE 7: AUTOMATED DATA CHECKS"` banner from prior commits. |
| 6. Reproducibility | OK | No path / seed / library changes. CWD-relative `do do/check/...` calls (mirrors all other phase invocations). |
| 7. Function design | OK | No new programs / helpers; pure orchestration delta. |
| 8. Figure quality | n/a | main.do produces no figures. |
| 9. Output persistence | OK | No new save / export calls. Phase 7 check files write to their own `$logdir/check_*.smcl` per their own headers (verified separately in Partition B pre-flight). |
| 10. Comment quality | OK | New audit-trail comment at line 467 (`* WIRED 2026-05-17 — calls below activated for ADR-0018 acceptance run.`) is concrete, dated, and cites the governing ADR. Surrounding TODO marker at line 460 reworded from `TODO Phase 1c §5.3:` → `Phase 1c §5.3 —` to reflect that the calls are no longer TODO — appropriate. |
| 11. Error handling | OK | The wiring inherits each check file's own `assert` hygiene (which is the design memo's responsibility, audited separately in Partition B pre-flight). The bundle introduces no error-handling change at the orchestration layer. |
| 12. Professional polish | OK | Indentation matches surrounding 4-space convention within `if `run_data_checks' { ... }`. Line lengths ≤ ~140 chars (the inline `//` one-liners are wide but consistent with the rest of main.do's description-convention style — not a deduction in this file's local norm). |

---

## Compliance Evidence (Adversarial-default verification)

Per `.claude/rules/adversarial-default.md`, the following ledger-equivalent grep/read evidence backs each compliance claim above:

- `do/main.do` | brace-balance | 2026-05-17 (this review) | PASS | grep counts: `{` = 43, `}` = 43; structural pairing confirmed 7 phase opens ↔ 7 phase closes
- `do/main.do` | phase-7-uncommented | 2026-05-17 | PASS | `grep -nE '^\s*do\s+do/check/check_' do/main.do` = 6 matches (lines 468-473); `grep -nE '^\s*\*\s*do\s+do/check' do/main.do` = 0 matches
- `do/main.do` | no-residual-comment-slashstar | 2026-05-17 | PASS | `grep -nE '^\s*\*.*/\*' do/main.do` = 0 matches
- `do/check/check_*.do` | files-exist | 2026-05-17 | PASS | Glob `do/check/check_*.do` returns 6 files matching the 6 references
- `do/main.do` | no-scope-creep | 2026-05-17 | PASS | M4 lines 96-118, 226-230, 281-284 visually intact; Phase 4 stub 357-374 unchanged; no Stata code outside fix sites altered

No ledger row is `ASSUMED`. All claims are backed by concrete grep / glob / line-ref evidence. No `(MISSING — flagged)` rows.

---

## Score Breakdown

- Starting: 100
- **Minor** — Dispatcher's brace-count claim of 44/44 was actually 43/43. Not a correctness defect (equality is what matters), but worth flagging to the dispatcher for accuracy hygiene in future bundle descriptions: −2
- **Minor** — Surrounding comment update at line 460 changed `TODO Phase 1c §5.3:` → `Phase 1c §5.3 —`, but the upstream Step 9 comment at line 460 ("six check files per the design memo") could have been promoted to a stronger acceptance-run marker (e.g., a parallel `WIRED 2026-05-17` annotation alongside Phase 5 / Phase 6 LANDED markers elsewhere in the file). The single `WIRED` line at 467 is sufficient but slightly less prominent than peer-phase activation markers: −4

**Final: 94/100**

---

## Escalation Status: None

Round 1, PASS. No three-strikes activity.

---

## Recommendations (non-blocking)

1. (Dispatcher hygiene) Future bundle descriptions: confirm the brace-count numbers via `grep -c` before quoting them — the 44 vs 43 discrepancy was harmless here (equality satisfied), but in a denser fix it could mask a real off-by-one.
2. (File pattern, very minor) The audit-trail line at 467 (`WIRED 2026-05-17 ...`) is good. Consider mirroring this style consistently in future activations (e.g., when the `do_va` sub-toggle is flipped from 0 to 1 default, or when Phase 4 stubs fill in).

Neither recommendation blocks the commit. The PASS verdict stands as-is.

---

## Commit footer recommendation

Per `phase-1-review.md` §5:

```
coder-critic: PASS (94/100)
```

Or, if the user prefers the verbose form:

```
coder-critic: PASS (94/100) — Phase 7 uncommented (6 check calls wired); /* in *-comments escaped (4 lines, 6 substitutions); braces balanced 43/43; no scope creep on M4 flag or Phase 4 stub.
```
