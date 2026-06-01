# Adversarial Review — mkdir-coverage-sweep plan

**Date:** 2026-05-31
**Reviewers:** 3 independent Explore agents (fresh context, refute-don't-approve), lenses: detector-completeness, Stata-fix-correctness, strategy/ROI
**Target:** `quality_reports/plans/2026-05-31_mkdir-coverage-sweep.md`
**Status:** Active
**Verdict:** Plan is directionally right but **must be revised before execution** — 1 critical recon gap (confirmed), 1 broken helper, and a strong strategic objection to the static-detector shape.

---

## Verified findings (I re-checked the load-bearing claims against the repo)

1. **CONFIRMED — recon missed 2 files with the same loop-var-dir bug.** `do/share/va_scatter.do:176,190,237…` and `do/share/kdensity.do:170` both `graph export $figures_dir/share/va/`​`` `version' ``​`/...` but `cap mkdir` only reaches `$figures_dir/share/va` (va_scatter:107, kdensity:84) — never the per-`version` level. These were NOT in the plan §4 candidate list. This is the exact false-negative the review warned about: the "6 candidates" were under-scoped; the bug is broader. (verified by grep, this turn.)
2. **CONFIRMED — `esttab using` is in 4 active files.** Plan lists it (verb #8) so the detector *would* cover it IF implemented faithfully; R1's "will miss" is only true if the implementer drops it. Keep it; add a unit assertion.
3. **CORRECTED — R2's `ensure_dir` "`//home`" claim is WRONG.** Stata compresses empty tokens in a macro list, so `subinstr "/home/x" "/"→" "` then `foreach` yields `home x` (leading empty dropped) → `accum` builds `/home/x` correctly, not `//home`. BUT R2's **space-in-path** defect is real (a path component with a space word-splits), and the helper is still fragile. Net: don't ship the helper as-is for M4.

---

## Synthesis of the three reviews

### Detector completeness (R1) — real, fixable
- **HIGH:** recon under-scoped (va_scatter, kdensity missed) → detector MUST run the general all-files pass, not lean on the 6-file list. CONFIRMED.
- **HIGH:** `///` multi-line write paths (indexregwithdemo:162 spans lines) → must join continuations before regex.
- **MED:** locals that *build* dir paths (`local sub "x"; save $d/`​`` `sub' ``​`/f`) are opaque to string-matching → conservative mode: flag for manual review.
- **MED:** nested-loop scope + control-flow-gated writes → track full loop stack; mark gated writes MED not HIGH.

### Fix correctness (R2) — one critical, rest are guard-rails
- **CRITICAL:** `ensure_dir` helper (§3.3) — reject for M4 (space-path fragility; unproven). Stick to explicit `cap mkdir`.
- **HIGH:** loop-var mkdir placement — needs an explicit *nested-loop* example: the mkdir goes inside the loop that binds the var, after `use`/`merge`, before first write. (indexregwithdemo: at line ~102 inside `foreach type`.)
- **HIGH:** `#delimit ;` regions — an inserted `cap mkdir` needs a trailing `;`. None of the current candidates run an active `;`-block, but the detector/fixer must check ±10 lines. (Same family as the `*/`-glob hazard the hook already caught this session.)
- **MED but important:** **LEGACY-path guard** — if an uncovered write targets a LEGACY global ($caschls_projdir/$vaprojdir), the fix is NOT `mkdir` (would violate ADR-0021 sandbox) — it's a path repoint. Detector must cross-check each gap against settings.do globals. (indexreg/indexhorse write to $estimates_dir/$output_dir = CANONICAL, so safe.)

### Strategy / ROI (R3) — the strongest challenge
- Argues **reject the static-detector shape**; the bug is runtime-fixable in a Scribe-only world where the static analyzer can't see local-resolved paths → false confidence ("verification theater").
- Argues sequencing: fix the **known** sites now, commit, push, re-run on Scribe (the only ground truth); a 4–6h sweep balloons the uncommitted surface and stalls M4.
- Argues against wiring `--check` into a Tier-1 pre-commit hook (false-positive over-fire mid-debug); prefers a one-shot Phase-7 *runtime* `check_dirs.do` post-green.

---

## My adjudication (where I land, and where I push back on the reviewers)

**Accept:**
- Broaden scope beyond the 6 files — the general all-files pass is mandatory, not optional. (R1, confirmed.)
- Reject `ensure_dir` for M4; explicit `cap mkdir` only. (R2.)
- Add the **LEGACY-path guard** to whatever we build. (R2 — genuinely new, not in the plan.)
- Add the nested-loop placement example + `#delimit ;` check to the fix protocol. (R2.)

**Push back on R3's "pure runtime, no detector" maximalism:** the static pass is *not* wasted even if Scribe is ground truth — it batches discovery so we don't burn N Scribe round-trips (each ~hours) finding mkdir bugs one at a time, which is the painful loop the user is explicitly trying to exit ("the bug that keeps happening"). R3 is right that a static-only "green" is false confidence; it's wrong that the detector has no value. The synthesis is: **use a lightweight static pass to FIND all candidates in one shot (cheap discovery), but treat the fix — explicit cap mkdir — as the deliverable, and the next Scribe run as the verification.** Not detector-as-oracle; detector-as-discovery.

**Push back on R3's "adopt ensure_dir now":** directly contradicted by R2's proof the helper is fragile. The two strongest reviews disagree; I side with R2 — no helper mid-M4.

---

## Recommended revision to the plan (REVISED shape)

1. **Discovery (cheap, static, one-shot):** a *simple* grep-driven pass (not a 100-line scope-inferring analyzer) that lists every write target dir containing a loop-var level OR a static level deeper than its file's `cap mkdir` block, across ALL active files. Output = candidate list for human triage. ~1h, not 4–6h.
2. **Fix the confirmed set now** (the next-run critical path): indexregwithdemo, indexhorseracewithdemo, **va_scatter, kdensity** (newly found), plus re-confirm clean_acs_census_tract. Explicit `cap mkdir`, nested-loop placement, LEGACY-path check, `#delimit` check, `*/`-glob-safe comments.
3. **Defer** the `ensure_dir` helper and any pre-commit `--check` to **post-M4** (per R2 + R3).
4. **Permanent guard** = a Phase-7 **runtime** `check_dirs.do` that runs once post-green, NOT a Tier-1 static hook (per R3).
5. **Verification caveat stays:** static = discovery; the next Scribe M4 run is the only pass/fail.

---

## Cross-refs
- Plan: `quality_reports/plans/2026-05-31_mkdir-coverage-sweep.md` (to be revised per above)
- This session's 3 prior mkdir fixes (figures) + indexreg confirm: ledger 2026-05-31
- ADR-0021 (sandbox — the LEGACY-path guard rationale), phase-1-review.md (Tier-1 caution R3 cites)
