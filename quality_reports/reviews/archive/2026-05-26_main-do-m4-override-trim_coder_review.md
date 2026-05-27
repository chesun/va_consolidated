# `do/main.do` M4 Override Trim — coder-critic
**Date:** 2026-05-26
**Reviewer:** coder-critic
**Target:** `do/main.do` (Phase 2 M4 override removal; +18/-5 in single block)
**Score:** 88/100
**Status:** Superseded by [archive/2026-05-26_dead-include-fix-and-m4-override-restore_coder_review.md](archive/2026-05-26_dead-include-fix-and-m4-override-restore_coder_review.md) — the trim approved here was reverted later same day after M4 attempt #6 surfaced the cache-missing symptom (cached samples live at LEGACY `$vaprojdir` paths, not CANONICAL `$datadir_clean`); the dead include that prompted the trim was resolved (Phase 1b §4.3 partial) and the M4 override restored to its original three-toggle form.
**Supersedes:** n/a (distinct target slug from `2026-05-25_main-do-clean-va-reorder` and `2026-05-17_main-m4-flag`)
**Mode:** Full (Phase 1c §5.4 acceptance-run hotfix; paper-affecting indirectly via VA chain — highest-severity calibration per `.claude/rules/phase-1-review.md` §1 Tier 2)

---

## Verdict

**PASS (88/100)** — change is correct, minimum-diff, mirrors predecessor production semantics, and resolves the documented dead-include landmine surfaced in M4 attempt #5. The only deduction-worthy issue is **documentation drift inside `main.do` itself**: the header CONVENTIONS block and the ACCEPTANCE-RUN MASTER OVERRIDE block were not updated to match the new (post-trim) behavior, so they over-promise what the M4 override does.

This is a **single Major finding** that does not block commit (score above 80). Recommend addressing it in the same commit or as a same-day follow-up.

---

## Code-Strategy Alignment: MATCH

The change implements exactly what the dispatch description specifies:

- Removes the Phase 2 `if `m4_acceptance_run' { local do_touse_va 1; local do_create_samples 1 }` override.
- Replaces it with a 17-line comment block documenting (a) what was there, (b) why it was removed, (c) why this is correct relative to predecessor production behavior, (d) re-add conditions.
- Phase 3 override (`do_va` flip) untouched — verified at `do/main.do:300-303`.
- Default-0 behavior outside M4 mode unchanged — verified at `do/main.do:229-230`.

ADR scope: change refines the M4 override pattern from ADR-0007 / ADR-0018; no new ADR required (operator-mode refinement, not a methodology change). Plan v3 §3.5 (M4 acceptance run) is the binding scope.

---

## Sanity Checks: PASS

Verified each load-bearing claim against the primary source.

| Claim | Verification | Result |
|---|---|---|
| `touse_va.do` has dead include `create_prior_scores.doh` at line 262 | Read `do/samples/touse_va.do:259-262` | CONFIRMED — exact line; preceded by 3-line `DEAD INCLUDE` warning comment |
| `touse_va.do` header documents the dead include at lines 90-99 | Read `do/samples/touse_va.do:89-101` | CONFIRMED — `CONVENTION DEVIATIONS` block spans lines 89-101 (the cited "90-99" is slightly off-by-one on the start; minor) |
| M4 attempt #5 r(601) at `create_prior_scores.doh` | Read `log/main_25-May-2026_15-38-40.smcl` lines 55555-55585 | CONFIRMED — `file ... /consolidated/do/samples/create_prior_scores.doh not found` followed by `r(601);` five times |
| Predecessor `do_all.do:110` has `local do_touse_va = 0` | Predecessor repo not present in `va_consolidated` tree (verified via `Glob **/do_all.do` → no files); claim is consistent with the same line refs cited (and verified) in the prior review `2026-05-17_main-m4-flag_coder_review.md` and in the canonical comments at `do/samples/touse_va.do:24` ("GATED OFF in the predecessor `do_all.do:110-113'") | ASSUMED — cited line numbers consistent with multiple in-repo cross-references; predecessor repo is off-tree |
| Predecessor `do_all.do:148` has `local do_create_samples = 0` | Same as above | ASSUMED |
| `/*` balance preserved 12/12 | `grep -c '/\*' do/main.do` = 12; `grep -c '\*/' do/main.do` = 12 | CONFIRMED |
| Only two M4 overrides existed pre-trim, only one remains post-trim | `grep -n 'm4_acceptance_run' do/main.do` returns 5 hits: header doc (L32), ACCEPTANCE block doc (L102), local-set (L115), `di cond(...)` (L117-118), Phase 3 `if` (L301) | CONFIRMED — Phase 2 `if`-block is gone; Phase 3 `if`-block intact |

**Adversarial-default sweep** (per dispatch concern): scanned `do/main.do` for any other M4-overridden sub-toggle that might land on a dead-code path:

- `do_va` (Phase 3): flips ON under M4 — landing points are `do/va/va_score_all.do`, `va_score_fb_all.do`, `va_out_all.do`, `va_out_fb_all.do`, plus 11 batch 3b/3c/3d/heterogeneity files. Verified in ledger row 75 (`do/main.do | gate-parity | PASS`) and ledger rows for partition-B M4-blocking fixes (`2026-05-17_m4-blocking-fixes_coder_review.md` PASS at 96/100). No outstanding dead-include landmines under `do_va`.
- No other M4-conditioned local exists.

Sign / magnitude / dynamics / balance / first-stage / sample-size are not in scope for a master-script hotfix; the VA estimation chain runs against existing cached samples, and Phase 3 behavior is unchanged.

---

## Robustness: Complete

All robustness expectations for the hotfix are met:

- **Behavior parity with predecessor production** — under M4, `do_touse_va = 0` and `do_create_samples = 0` mirror `do_all.do:110, :148`. Predecessor production reads cached `va_samples.dta` + `score_*.dta` + `out_*.dta`; consolidated does the same.
- **No regression in dev (non-M4) mode** — when `m4_acceptance_run = 0`, both toggles remain at their default 0 (line 229-230). Identical to pre-trim non-M4 behavior.
- **Phase 3 production verification still happens** — `do_va` still flips under M4 (line 301-303), which is the actual paper-affecting estimation step.
- **Re-add path documented** — comment block at lines 248-249 specifies the two conditions under which the override should be re-added (Phase 1b §4.3 dead-include resolution + deliberate re-seed need). Future operators have a clear flag.

---

## Code Quality (10 categories)

| Category | Status | Issues |
|---|---|---|
| Script structure & headers | **WARN** | `do/main.do` header CONVENTIONS block (lines 32-36) and ACCEPTANCE-RUN MASTER OVERRIDE block (lines 100-118) still describe the OLD three-sub-toggle behavior. See Documentation Drift below. |
| Console output hygiene | **WARN** | Same as above — the `di cond(...)` at line 117-118 still says "sub-toggles do_touse_va, do_create_samples, do_va will be forced to 1" even though only `do_va` flips post-trim. |
| Reproducibility | OK | No new paths, no seed changes, no relative-path drift |
| Function/program design | OK | n/a — master script, no new programs |
| Figure quality | OK | n/a — no figure code touched |
| Output persistence | OK | n/a — no new saves |
| Comment quality | OK | The new comment block (lines 232-249) explains WHY (not WHAT): documents the r(601) symptom, the gating rationale, and re-add conditions. Section dividers (`* RELOCATED ...` `* M4 override REMOVED ...`) consistent with the file's existing style. |
| Stata comment safety | OK | `/*` balance verified 12/12. No path-glob `*` inside any comment context in the diff. No `//*****` banners introduced. No Variant-8 over-flatten artifacts (`^-+<x>$` 0 hits; `^[[:space:]]*<x>[[:space:]]*$` 0 hits inside the modified region). |
| Error handling | OK | n/a — orchestration script; downstream files handle their own asserts |
| Professional polish | OK | Indentation matches surrounding `if `run_samples'` block (4-space inside the block); 100-char limit respected; consistent with the M4 flag review's introduced style |

### Documentation Drift (Major finding, -8)

After the trim, three locations in `do/main.do` still document the **pre-trim** behavior:

1. **Line 32-36, CONVENTIONS block:** "`m4_acceptance_run` … forces the three run-once-cached sub-toggles (do_touse_va, do_create_samples, do_va) ON".
2. **Line 102-110, ACCEPTANCE-RUN MASTER OVERRIDE block:** "The flag overrides three sub-toggles inside Phases 2-3 (do_touse_va, do_create_samples, do_va) from their cached-default 0 to 1, so the run rebuilds samples + VA estimates from scratch instead of relying on cached predecessor outputs."
3. **Line 117-118, runtime `di` message:** `cond(`m4_acceptance_run', "ENABLED — sub-toggles do_touse_va, do_create_samples, do_va will be forced to 1", "DISABLED — sub-toggles use cached-defaults")`.

Post-trim, M4 only forces `do_va` ON. Sample-construction sub-toggles intentionally stay at 0 to mirror predecessor production. The documentation must reflect that, or the next operator (or 2026-future-Christina re-reading the file) will be misled about what `m4_acceptance_run = 1` does. The runtime `di` is the most user-visible — it prints to the master log on every M4 run.

This is consistent with the new in-block comment at lines 232-249 (which correctly says only `do_va` should flip). The fix is mechanical text-edit across three locations; should land in the same commit as the trim, or as a same-day follow-up commit. Single Major finding worth -8.

---

## Score Breakdown

- Starting: 100
- Documentation drift in header CONVENTIONS + ACCEPTANCE-RUN OVERRIDE block + runtime `di` (Major, code-strategy alignment / comment fidelity): **-8**
- Off-by-one in cited touse_va.do header line range (claim "lines 90-99"; actual block is lines 89-101): **-2** (Minor, cosmetic; comment is still locatable)
- Predecessor `do_all.do` line numbers unverifiable in this tree (off-tree repo): **-2** (Minor; consistent with prior in-repo cross-refs that were previously verified, so risk is low — flagged for transparency per adversarial-default)
- **Final: 88/100 PASS**

No deductions for the trim itself, which is the correct minimum-diff fix.

---

## Compliance Evidence (from `.claude/state/verification-ledger.md`)

Consulted rows:

- `do/main.do | gate-parity | 2026-05-07T23:30Z | f9497e091c8a | PASS` — stale (file hash changed since 2026-05-07; subsequent legitimate edits 2026-05-17 M4 flag, 2026-05-25 clean_va reorder, 2026-05-26 this trim). **Not re-run here** because the gate-parity check is now structurally different post-trim — sample-construction sub-toggles are correctly NOT M4-overridden, which is the new semantics. A new ledger row should be written post-commit reflecting the trimmed semantics (recommended slug: `m4-override-scope-trim`).
- `do/main.do | brace-balance-batch-3d | 2026-05-08T03:00Z | 02149ecb668c | PASS` — stale (hash changed). Spot-verified brace balance for the trim site: `if `run_samples' {` at line 217 closes at line 280; `if `do_touse_va' {` at 261 closes at 263; `if `do_create_samples' {` at 264 closes at 267. All balanced.
- No row exists for `comment-safety` (`/*` balance) on `do/main.do`. Verified manually: 12 opens, 12 closes.

Recommendation: write a new ledger row `do/main.do | m4-override-scope-trim | 2026-05-26 | <new-hash> | PASS | Phase 2 M4 override removed; Phase 3 override intact at L301-303; non-M4 default-0 behavior preserved; documents r(601) avoidance` post-commit.

---

## Phase 1 Review (Tier 1) Checklist Confirmation

Per `.claude/rules/phase-1-review.md` §2:

- [x] Source identified — same file, only the M4 Phase 2 override block was modified
- [x] Destination matches plan — n/a (in-place edit of master script)
- [x] Path references updated — no path references touched; verified via `grep -n '$consolidated_dir' do/main.do | wc -l` matches pre-existing pattern count
- [x] Scope minimal — diff is single block at lines 222-249; no other edits ride along
- [x] ADR cited — change refines ADR-0007 + ADR-0018 behavior; commit message should reference both
- [x] Bug-fix specifically — Yes, fix matches the dispatched diagnosis (M4 #5 r(601) traced to `create_prior_scores.doh`); minimum-diff path chosen over Alternative B (fix touse_va.do directly) for correct phase-stage reasons
- [x] `/*` balance — 12/12 confirmed
- [x] Log-path mirror — n/a (the trim is in main.do, which has its own special-cased master-log convention; no per-sub-script log path changed)

Tier 2 dispatch (this review) — score >= 80 → PASS.

---

## Escalation Status: None (round 1, score above 80)

---

## Recommendations (non-blocking)

1. **Same-commit fix the documentation drift** (header CONVENTIONS block lines 32-36; ACCEPTANCE-RUN block lines 100-118; runtime `di` line 117-118). Single-purpose mechanical text edit; restore description accuracy to "M4 forces `do_va` ON (samples remain cached per predecessor production parity)."
2. **Add a new verification-ledger row** post-commit per the Compliance Evidence section above.
3. **Optional**: amend the runtime `di` to also state, at M4-enable time, that sample-construction is intentionally NOT re-run and that operators should re-add the override if a deliberate re-seed is needed. Same point as #1, just elevating the operator-warning value.

These are recommendations, not blockers. The score reflects the documentation drift; the trim itself is sound.

---

## Sign-off

The trim is the correct minimum-diff response to M4 attempt #5's r(601). Mirrors predecessor production. No regressions in non-M4 mode. Phase 3 production verification (the paper-affecting bit) is intact. Documentation drift identified in the same file is the lone -8 finding and is mechanical to fix.
