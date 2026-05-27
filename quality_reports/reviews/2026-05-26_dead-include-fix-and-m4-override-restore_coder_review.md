# Dead-Include Fix + M4 Override Restore — coder-critic
**Date:** 2026-05-26
**Reviewer:** coder-critic
**Target:** `do/samples/touse_va.do` (dead include resolution) + `do/main.do` (M4 override restoration; reverts yesterday's `1ae9cf7` Option-A trim with updated context)
**Score:** 94/100
**Status:** Active
**Supersedes:** n/a (distinct target slug from `2026-05-26_main-do-m4-override-trim` — which it functionally reverses; that prior review should be marked `Status: Superseded by <this-path>` per `agents.md` §2a, see Note below)
**Mode:** Full (Phase 1c §5.4 M4 acceptance-run hotfix #3 + Phase 1b §4.3 dead-include resolution, pulled forward; paper-affecting via `va_samples.dta → score_*.dta → va_score_all.do` chain — **highest severity calibration** per `.claude/rules/phase-1-review.md` §1 Tier 2)

---

## Verdict

**PASS (94/100)** — both edits are correct, minimum-diff, internally consistent, and resolve the M4 attempt #5 r(601) cache-missing symptom by restoring the only valid path forward: regenerate `va_samples.dta` + `score_*.dta` at CANONICAL paths during M4, with the previously-latent dead include now properly repointed to `create_prior_scores_v1.doh` per ADR-0009.

The include repoint is **load-bearing** (not decorative): `create_prior_scores_v1.doh` generates the four variables (`prior_ela_z_score`, `peer_prior_ela_z_score`, `prior_math_z_score`, `peer_prior_math_z_score`) that `touse_va.do:283-287` and `:308-312` reference via the `ela_score_controls` / `math_score_controls` / `peer_*` macros expanded by `macros_va.doh`. Without the include resolving to a real file, `markout` at L278-287 / L303-312 would fail with undefined-variable errors. The previously-undefined state (predecessor's 3+ years of latent dead-include bug) is corrected as a side effect of unblocking M4.

The one Major-tier deduction is for an internal **doc-inconsistency** in `touse_va.do` header line 52 (`INPUTS` block still calls L131's include "DEAD INCLUDE" while line 270 now points at the live v1 file). Minor items: a couple of small doc nits noted below.

---

## Code-Strategy Alignment: MATCH

The two edits implement exactly what the dispatch description and ADR-0009 specify.

### Edit 1 — `do/samples/touse_va.do`

- **L267-270** (the include site): rewritten from `include $consolidated_dir/do/samples/create_prior_scores.doh` (DEAD) to `include $consolidated_dir/do/samples/create_prior_scores_v1.doh` with a 3-line lead-in comment block citing the resolution date, ADR-0009 v1-canonical, and the header CONVENTION DEVIATIONS block.
- **L89-110** (CONVENTION DEVIATIONS block): annotated RESOLVED 2026-05-26 with 4-paragraph diagnosis: (a) predecessor 3+ year latent bug, (b) origin in 2022-12-29 v1/v2 refactor + ADR-0009 v1 canonical, (c) repointing rationale, (d) no paper-impact concern since predecessor never ran the script.

### Edit 2 — `do/main.do`

Three doc sites + one runtime expression restored to three-toggle (do_touse_va + do_create_samples + do_va) override behavior:

- **L240-256** (Phase 2 override block, restored): `if `m4_acceptance_run' { local do_touse_va 1; local do_create_samples 1 }` with a 10-line `History:` comment noting yesterday's removal, the dead-include block, the same-day resolution, and the cache-missing symptom that prompted restoration. Phase 2 doc convention matches the existing single-toggle override at Phase 3 L307-310 (`do_va`).
- **L28-39** (header CONVENTIONS block, restored): explicit list of all three sub-toggles + the new LEGACY-vs-CANONICAL paths rationale ("Predecessor's cached outputs live at LEGACY paths the consolidated pipeline doesn't read from, so M4 must regenerate them at CANONICAL $datadir_clean paths").
- **L102-121** (ACCEPTANCE-RUN MASTER OVERRIDE block): restored three-toggle description with the same LEGACY-vs-CANONICAL paths rationale matching the header block.
- **L125-126** (runtime `di cond(...)` line): restored to enumerate all three sub-toggles in the operator-facing message.

### ADR scope

- **ADR-0009** (v1-canonical) — drives the v1 (not v2) repoint. Confirmed: v1 is the canonical paper-shipping spec; v2 is the robustness variant. `touse_va.do` is the sample-tagging entry point that produces a single `va_samples.dta` consumed by both v1 and v2 downstream sample-construction scripts (`create_score_samples.do` invokes both `create_va_g11_sample_v1.doh` and `_v2.doh`). The v1/v2 split happens AT the per-version sample-construction step, not at `touse_va.do`, so v1 in `touse_va.do` is the correct choice — v1 prior-score logic at the sample-tagging step is what would have been intended had the file been pointing at a real include in 2022.
- **ADR-0018** (M4 acceptance criteria) — drives the override-restoration. M4 must rebuild samples + VA at CANONICAL paths because cached predecessor outputs at LEGACY paths aren't readable by the consolidated VA-estimation chain.
- **ADR-0021** (sandbox + description convention) — already satisfied by the prior relocation (writes go to `$datadir_clean`; log + translate go to `$logdir/samples/`; verified at touse_va.do L333, L340).

---

## Sanity Checks: PASS

### Correctness of the include repoint

- **Verified `do/samples/create_prior_scores_v1.doh` exists** — `Glob do/samples/create_prior_scores*` returned both v1.doh and v2.doh present.
- **No other broken include reference in `touse_va.do`** — `grep '^[[:space:]]*include' do/samples/touse_va.do` finds 3 includes (`macros_va.doh` L182, `create_diff_school_prop.doh` L265, `create_prior_scores_v1.doh` L270); all three target files exist on disk.
- **v1-canonical correctness** — confirmed via cross-reference: (a) ADR-0009 declares v1 the paper-shipping spec; (b) `create_prior_scores_v2.doh:30` header explicitly cites v1 as the "same ELA/Math" peer; (c) `create_va_g11_sample.doh:13` notes the base sample variant "calls `create_prior_scores_v1.doh'" (the implicit canonical fallthrough); (d) 11 separate `do/share/*.do` files include v1 (not v2) for their analyses.
- **Behavior preservation: the include is LOAD-BEARING, not decorative.** `create_prior_scores_v1.doh:62-78` defines `prior_ela_z_score`, `peer_prior_ela_z_score`, `prior_math_z_score`, `peer_prior_math_z_score`. `macros_va.doh:204-207, 213-215, 219-225` defines `ela_score_controls` / `math_score_controls` / `peer_*` referencing those exact variables. `touse_va.do:278-287` and `:303-312` then `markout` against `\`ela_score_controls'` / `\`math_score_controls'` / peer variants. Without the include resolving, the variables don't exist and the `markout` step would fail with `variable prior_ela_z_score not found`. The bug was latent only because `do_touse_va` was gated 0 in predecessor production for 3+ years.
- **Predecessor 3+ year latent state, now corrected:** confirmed via the dispatch context — script never executed in predecessor production because `do_all.do:110` gated it 0. The fact that yesterday's attempt #5 hit r(601) on this include is the first time it ran end-to-end. Repointing to v1 is the behavior the script SHOULD have had if it had ever run.

### Internal consistency in main.do (three-toggle restoration)

- Phase 2 sub-toggle override (L253-256): restored, flips `do_touse_va` + `do_create_samples` ON under `m4_acceptance_run`.
- Phase 3 sub-toggle override (L307-310): unchanged, flips `do_va` ON under `m4_acceptance_run` (was correct all along).
- Header CONVENTIONS block (L32-39): now lists all three sub-toggles.
- ACCEPTANCE-RUN MASTER OVERRIDE block (L102-121): now lists all three sub-toggles + the LEGACY-vs-CANONICAL paths rationale.
- Runtime `di cond(...)` line (L125-126): enumerates all three sub-toggles.
- All four doc sites are mutually consistent.

### `/*` balance (per phase-1-review.md §2 Tier-1 commit-time check)

- `do/samples/touse_va.do`: `grep -c '/\*'` = 4; `grep -c '\*/'` = 4 → **BALANCED**.
- `do/main.do`: `grep -c '/\*'` = 12; `grep -c '\*/'` = 12 → **BALANCED**.

### Variant-8 over-flatten artifacts (per skill/stata-sweep field guide)

- `do/samples/touse_va.do`: 0 matches for `^-+<x>$` or `^\s*<x>\s*$`.
- `do/main.do`: 0 matches for either pattern.

### No other dead includes elsewhere in the sample-construction chain

Full sweep via `grep '^[[:space:]]*(include|do)' do/samples/*.doh + create_score_samples.do + create_out_samples.do`:

- All 14 include/do targets in `do/samples/*.doh` exist on disk (verified via `Glob do/samples/create_prior_scores*` + `Glob do/samples/merge_*.doh`; `create_va_sample.doh` and `create_diff_school_prop.doh` also confirmed present).
- All 12 include/do targets in `create_score_samples.do` and `create_out_samples.do` resolve to existing files or to `$matt_files_dir/...` per ADR-0017 (Matt's files untouched).
- **`grep -rn 'create_prior_scores' do/`** shows only v1 + v2 explicit references plus the now-fixed line 270 in `touse_va.do`. The unsuffixed dead form appears only in three header doc strings (touse_va.do lines 52, 82, 94, 97 — describing the historical bug). Zero active live references.

### Adversarial-default: cached LEGACY artifacts assumption

The diff comments at L113-115 + L243-245 claim "predecessor's cached samples live at LEGACY paths the consolidated pipeline doesn't read from." Dispatch context confirms Christina verified this 2026-05-26 ("they do exist in the legacy paths"). Reasonable to trust; M4 attempt #5's r(601) at `data/cleaned/va_samples_v1/score_b.dta not found` independently corroborates that the CANONICAL paths are empty.

---

## Robustness: Complete

All three of yesterday's `1ae9cf7` doc-drift edits are reverted, and the underlying paper-relevant assumption (v1-canonical per ADR-0009) is now correctly applied in the previously-undefined-state region of `touse_va.do`. No other documentation surface in main.do or touse_va.do remains stale; the four main.do doc sites + the touse_va.do CONVENTION DEVIATIONS block + the L267-269 lead-in comment + the L52 INPUTS-block note are mutually self-consistent **except** for the one Major-tier deduction below.

---

## Code Quality (12 categories)

| Category | Status | Issues |
|----------|--------|--------|
| 1. Code-Strategy Alignment | OK | Two-file change implements ADR-0009 + ADR-0018 cleanly; no scope creep |
| 2. Sanity Checks | OK | Include is load-bearing (variable chain traced); LEGACY-cache assumption corroborated by r(601) symptom |
| 3. Robustness | OK | All three yesterday's doc sites consistently restored; runtime `di cond` line matches |
| 4. Script structure & headers | OK | Both files have rich headers; touse_va.do CONVENTION DEVIATIONS block well-structured |
| 5. Console output hygiene | OK | No new `cat`/`print` pollution; existing `di as text` matches house style |
| 6. Reproducibility | OK | No path/seed changes; CWD-restoration pattern at touse_va.do L343 preserved |
| 7. Function/program design | OK | Include-not-do correctly used per ADR-0009 helper convention |
| 8. Figure quality | N/A | No figure changes |
| 9. Output persistence | OK | No save-target changes; `va_samples.dta` save at L333 unchanged |
| 10. Comment quality | WARN | One stale "DEAD INCLUDE" reference in touse_va.do:52 INPUTS block — see Findings |
| 10b. Stata comment safety | OK | `/*` balance 4/4 + 12/12; no path-glob `*` in new comments; no Variant-8 artifacts |
| 11. Error handling | OK | No new assertion changes; existing `cap log close touse_va` pattern preserved |
| 12. Professional polish | OK | Indentation matches surrounding context; line lengths reasonable; no T/F or magic numbers |

---

## Findings

### Major (1)

**Mj-1.** `do/samples/touse_va.do:52` INPUTS block still reads:

```
do/samples/create_prior_scores.doh — DEAD INCLUDE (see CONVENTION DEVIATIONS below)
```

This is now inconsistent with the actual L270 include of `create_prior_scores_v1.doh`. The CONVENTION DEVIATIONS block at L89-110 was updated to say RESOLVED, but the INPUTS list at L52 was not. A reader scanning the header will see "DEAD INCLUDE" and then look at the live line and be confused.

**Suggested fix** (recommendation, not implementation): replace L52 with

```
do/samples/create_prior_scores_v1.doh — v1-canonical prior-score helper (resolved L131 dead include; see CONVENTION DEVIATIONS below)
```

Or simply drop "DEAD INCLUDE" from the bracketed annotation. Same edit principle as the rest of today's resolution: header surfaces should match the active code.

**Deduction: −3** (Major; comment-quality / internal doc inconsistency on a load-bearing surface).

### Minor (2)

**Mn-1.** `do/samples/touse_va.do:82` RELOCATION HISTORY entry still reads:

```
- L131 `include do_files/sbac/create_prior_scores.doh' — VERBATIM (see DEAD INCLUDE)
```

This is the historical relocation record; arguably it's correct to preserve it as "what we relocated VERBATIM from the predecessor on 2026-05-07." But the trailing parenthetical `(see DEAD INCLUDE)` is now slightly anachronistic — the CONVENTION DEVIATIONS block no longer flags this as DEAD, it says RESOLVED. Either acceptable as-is (relocation history is point-in-time) or could be updated to `(later RESOLVED 2026-05-26 — see CONVENTION DEVIATIONS below)`.

**Deduction: −1** (Minor; doc fidelity).

**Mn-2.** `do/main.do:247-252` History comment inside the Phase 2 override block reads as expected but adds a non-trivial 6-line block to that override. Phase 3's corresponding override (L307-310) is just 4 lines (no history). Slight visual asymmetry: a future reader scanning the two overrides side-by-side may wonder why Phase 2 is verbose while Phase 3 is terse. Acceptable here because Phase 2 is the one that just got removed + restored; Phase 3 has never been touched. But worth noting for symmetry-conscious readers.

**Deduction: −1** (Minor; doc-symmetry; non-blocking).

### Critical (0)

None.

---

## Compliance Evidence (from `.claude/state/verification-ledger.md`)

Consulted ledger rows for the two files under review:

- `do/samples/touse_va.do | no-hardcoded-paths | 2026-05-07T22:00Z | b04973ca7ab3 | PASS` — file hash now stale (current edit changed L259-270 + header doc). Re-running the check on current diff: no new absolute paths introduced (the L182 and L265, L270 includes use `$consolidated_dir/...` which is the canonical form; `$matt_files_dir/...` on L252 unchanged). **Spot-check: PASS.** Recommend updating ledger row with new hash post-commit.
- `do/samples/touse_va.do | adr-0021-sandbox-write | 2026-05-07T22:00Z | b04973ca7ab3 | PASS` — file hash stale; current diff does not touch save targets (L333 unchanged). **Spot-check: PASS.**
- `do/samples/touse_va.do | legacy-include-macro-trace | 2026-05-07T22:00Z | b04973ca7ab3 | PASS` — file hash stale; the relevant trace is unchanged (`$matt_files_dir/merge_k12_postsecondary.doh` is args-based — `enr_only` — and references no top-level macros). **Spot-check: PASS.**
- `do/main.do | gate-parity | 2026-05-07T23:30Z | f9497e091c8a | PASS` — file hash stale (multiple commits since 2026-05-07). The relevant gate-parity claim (`local do_va = 0` at predecessor `do_all.do:160`) is unchanged by today's diff; today's diff RESTORES the override block that flips it to 1 under `m4_acceptance_run`, which was the original ADR-0018 design. **Spot-check: PASS.**
- `do/main.do | brace-balance-batch-3d | 2026-05-08T03:00Z | 02149ecb668c | PASS` — file hash stale; today's diff adds 6-line History comment inside the existing override block, no brace change. Brace balance preserved. **Spot-check: PASS.**

No missing ledger rows for the (path, check) pairs that bear on this commit. Adversarial-default deduction: **0**.

---

## Derive-Don't-Guess Evidence

All entity references in the new code verified against the existing repo:

- `create_prior_scores_v1.doh` — derived from existing inclusion pattern in 6 sibling files (`create_va_g11_sample.doh:55`, `create_va_g11_sample_v1.doh:66`, `create_va_g11_out_sample.doh:55`, `create_va_g11_out_sample_v1.doh:56`, plus 11 `do/share/*.do` includes). Path mirrors the well-established `$consolidated_dir/do/samples/<helper>.doh` convention. **PASS.**
- `prior_ela_z_score` / `prior_math_z_score` / `peer_prior_*` — variables created by `create_prior_scores_v1.doh:63-78` and referenced through `\`ela_score_controls'` / `\`math_score_controls'` / peer variants in `macros_va.doh:204-225`. **PASS.**
- ADR-0009 v1-canonical decision — cited consistently across the two-file diff. **PASS.**
- `$datadir_clean`, `$consolidated_dir`, `$matt_files_dir`, `$logdir`, `$vaprojdir` — all defined in `do/settings.do` (per verification-ledger row `do/settings.do | global-definitions`, not re-checked in this review). **PASS.**

Derive-don't-guess deduction: **0**.

---

## Score Breakdown

- Starting: 100
- Mj-1 (touse_va.do:52 stale "DEAD INCLUDE" in INPUTS block): **−3**
- Mn-1 (touse_va.do:82 anachronistic parenthetical in RELOCATION HISTORY): **−1**
- Mn-2 (main.do override-block doc-symmetry between Phase 2 verbose and Phase 3 terse): **−1**
- Compliance / derive-don't-guess deductions: **0**
- Adversarial-default deductions: **0**
- Stata `/*` balance + Variant-8 deductions: **0**

**Final: 94/100 — PASS** (≥ 80 per `phase-1-review.md` §4 hard gate; ≥ 90 per `quality.md` §1 PR gate).

---

## Escalation Status

**None.** Round 1 PASS with score ≥ 90. No outstanding Critical findings. Three minor doc-polish items recommended (1 Major / 2 Minor) but not blocking — can be addressed in same commit or as a same-day follow-up patch.

---

## Recommendations for follow-up (non-blocking)

1. **(Major)** Update `touse_va.do:52` INPUTS-block annotation for `create_prior_scores.doh` → reflect that the include is now resolved to `_v1.doh`. Minimum-diff one-line edit.
2. **(Minor)** Optionally update `touse_va.do:82` RELOCATION HISTORY trailing parenthetical from `(see DEAD INCLUDE)` to `(later RESOLVED 2026-05-26 — see CONVENTION DEVIATIONS below)`. Pure doc fidelity.
3. **(Minor)** Optionally trim or relocate the 6-line History comment inside `main.do:247-252` if visual symmetry with the Phase 3 override at L307-310 becomes a future concern. The history is valuable; the question is whether it belongs at the override site or in a session log.
4. **(Ledger maintenance, not deduction-bearing)** After commit, update the 5 ledger rows for `do/samples/touse_va.do` and `do/main.do` with current file hashes per `.claude/rules/adversarial-default.md` § Verification ledger.
5. **(Process note)** Per `.claude/rules/agents.md` §2a supersession protocol: when committing this change, also update `quality_reports/reviews/2026-05-26_main-do-m4-override-trim_coder_review.md` to `Status: Superseded by 2026-05-26_dead-include-fix-and-m4-override-restore_coder_review.md`, `git mv` it to `archive/`, and update `INDEX.md`. The prior review's 88/100 PASS recommendation (address the doc drift) is functionally addressed by today's revert.

---

## Commit-message footer recommendation

Per `phase-1-review.md` §5:

```
coder-critic: PASS (94/100) — Mj-1 INPUTS-block doc-stale finding deferred to same-day patch or commit-amend; Mn-1, Mn-2 optional polish.
```
