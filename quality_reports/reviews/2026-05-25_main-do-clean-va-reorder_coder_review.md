# main.do Clean-VA Cross-Phase Reorder Review — coder

**Date:** 2026-05-25
**Reviewer:** coder-critic
**Target:** do/main.do (Phase 1c §5.4 M4 acceptance-run hotfix; clean_va.do moved from Phase 1 batch 9f to Phase 5 trailer)
**Score:** 95/100
**Status:** Active
**Mode:** Standalone code-quality + strategic-alignment review (categories 1, 2, 3, 4, 9, 10, 11, 12 in scope; Phase 1c §5.4 single-file hotfix)
**Supersedes:** None (new change target slug; prior `main.do`-touching reviews scoped to distinct commits)

---

## Verdict: PASS (95/100)

The cross-phase ordering fix is **correctly diagnosed, correctly implemented, and correctly documented**. The new Phase 5 invocation site satisfies all upstream dependencies; the removal from Phase 1 batch 9f is paired with a substantive NOTE block that future readers can use to understand why the predecessor's order was abandoned. No regressions surfaced in the dependency check.

Two minor deductions: (1) the new Phase 5 comment could explicitly call out the in-place `analysisready` update side-effect, and (2) Phase 5's existing batch-level header comment (lines 392-395) was not updated to mention that clean_va.do is now part of this phase's chain.

---

## Code-Strategy Alignment: MATCH

**Diagnosis verified.** Read `do/data_prep/poolingdata/clean_va.do:97-103`:

```stata
foreach va_outcome in ela math enr enr_2year enr_4year {
  use $estimates_dir/va_cfr_all_v1/va_est_dta/va_`va_outcome'_all.dta, clear
  collapse (mean) va*, by(cdscode)
  tempfile va_`va_outcome'
  save `va_`va_outcome''
}
```

This is the read-site that crashed `r(601)` in M4 attempt #4. The producer is `do/va/merge_va_est.do` (Phase 3 batch 3c1, invoked at main.do:317). Confirmed via the file's own dependency block (clean_va.do:18) and via `m4_path_matrix.csv:24` which records the consolidated output path for `va_pooled_all.dta`.

**Move target validated.** clean_va.do at the new Phase 5 position (line 406):
- All Phase 1 chain inputs (`analysisready` dtas) are available — Phase 1 completes fully before `run_survey_va` gate fires (Phase 5 is gated by `run_survey_va`, structurally downstream of Phase 1 unconditional flow).
- All Phase 3 chain inputs (`$estimates_dir/va_cfr_all_v1/va_est_dta/va_<outcome>_all.dta`) are available — Phase 3 completes before Phase 5 starts. In M4 acceptance (`m4_acceptance_run=1` → `do_va=1`), these are produced fresh. In default dev (`do_va=0`), they're read from cache, matching predecessor `do_all.do:160` behavior.

**Phase choice (Phase 5 vs Phase 3 trailer) justified.** Rationale in the dispatch prompt is sound:
- `va_pooled_all.dta` is consumed ONLY by Phase 5 (verified — `allsvymerge.do:121` is the sole non-self consumer outside `do/_archive/`).
- Phase 3 trailer placement would gate clean_va.do on `do_va` (VA re-estimation), which is wrong — clean_va.do should re-run whenever survey-VA runs, regardless of whether VA was re-estimated this session.
- Semantically, clean_va.do is a survey-VA prep step (predecessor `clean_va.do` original header even says "clean VA estimates to be used for survey data analysis, and merge to survey analysis datasets").

---

## Sanity Checks: PASS

**Data-flow integrity (`adversarial-default` style trace):**

| Input/output | Producer | Consumer | Phase order OK? |
|---|---|---|---|
| `$estimates_dir/.../va_<outcome>_all.dta` (5 files) | `do/va/merge_va_est.do` (Phase 3 batch 3c1, L317) | `do/data_prep/poolingdata/clean_va.do:97-103` (Phase 5, L406) | YES — 317 < 406 |
| `$datadir_clean/calschls/analysisready/{sec,parent,staff}analysisready` | `do/data_prep/poolingdata/{sec,parent,mergegr11enr}` (Phase 1, L198-201) | `clean_va.do:128-131` (in-place update merging VA cols) | YES — Phase 1 < Phase 5 |
| `$datadir_clean/calschls/va/va_pooled_all.dta` (NEW) | `clean_va.do:120` (Phase 5, L406) | `do/survey_va/allsvymerge.do:121` (L408) | YES — 406 < 408 |
| `analysisready` (post-VA-merge) | `clean_va.do:131` in-place save | `do/survey_va/{allsvymerge,factor,pcascore}.do` reads `analysisready` (L408, L418, L419) | YES — 406 < 408,418,419 |

**Pre-Phase-5 consumer search confirms zero hits:**
```
grep -rn 'va_pooled_all' do/
```
Returns only: `clean_va.do` (producer + self-read at L129), `allsvymerge.do:121` (Phase 5 consumer), `m4_path_matrix.csv` (path registry). No share/, no Phase 6 outputs, no check/ files reference `va_pooled_all.dta` before Phase 5.

**Behavior parity with predecessor master.do is preserved.** Predecessor caschls master.do invoked clean_va.do at the end of batch 9f (per the chain `secpooling -> parentpooling -> staffpooling -> mergegr11enr -> clean_va` in clean_va.do:10) precisely because (a) it needed sister batch 9f outputs before it, and (b) VA outputs were treated as pre-existing artifacts from a separate cde_va_project_fork pipeline. The consolidated single-master collapses both pipelines into one, so the implicit Phase-3-before-batch-9f dependency now binds. The move resolves the new binding; output behavior is unchanged.

**Cache-friendly default-run behavior intact.** In default dev (`m4_acceptance_run=0`, hence `do_va=0`), Phase 3 batch 3c1 is skipped. clean_va.do at line 406 will read whatever cached `va_<outcome>_all.dta` exists at `$estimates_dir/va_cfr_all_v1/va_est_dta/`. This is the same failure-mode as before, just relocated from Phase 1 to Phase 5 — fail-loudly with r(601) if no cache exists, which is acceptable per dispatch-prompt §"Behavior in non-M4 default run".

---

## Robustness: Complete (for a single-file hotfix)

Scope is correctly limited: one .do file, two edit sites (remove from L195, insert at L397-406), three comment-block additions documenting the move. No scope creep into unrelated cleanup. No path repointing. No other invocations touched.

---

## Code Quality (relevant categories for this change)

| Category | Status | Notes |
|---|---|---|
| #1 Code-strategy alignment | OK | Matches dispatch-prompt rationale; matches plan v3 §3.5 invariant (acceptance-run completes end-to-end) |
| #2 Sanity checks | OK | Data-flow trace confirms no pre-Phase-5 `va_pooled_all` consumers; in-place `analysisready` updates still occur before downstream Phase 5 readers |
| #3 Robustness | OK | Minimal scope; no parallel-spec changes |
| #4 Script structure & headers | OK | Two new NOTE blocks at the removal and insertion sites; future reader can follow the breadcrumb |
| #6 Reproducibility | OK | No new paths; uses existing CANONICAL globals via the invoked file; `$estimates_dir`, `$datadir_clean` already bound in settings.do |
| #9 Output persistence | N/A | This change does not touch outputs directly — clean_va.do's saves (L120, L131) are unchanged |
| #10 Comment quality | OK with one minor gap | NOTE blocks explain WHY (Phase 3 dependency binding under consolidation). One-liner at L406 matches ADR-0021 convention. **Minor:** Phase 5 header at L392-395 was not updated to reflect that clean_va.do is now part of this phase's chain (the existing batch-level RELOCATED comment refers only to "Steps 7+10+11"). |
| #10b Stata comment safety | OK | `/*` balance: 12/12 (was 12/12 before; insertion added no nested block markers). Verified via `grep -c '/\*'` and `grep -c '\*/'`. No path-glob `*` introduced into any comment context. |
| #11 Error handling | OK | No new assertions needed (move-only change); inherited `cap log close clean_va` and translate-on-exit pattern in clean_va.do preserved |
| #12 Professional polish | OK | Indentation matches surrounding 4-space pattern within the `if `run_survey_va'' block; the L406 invocation aligns with sibling L408+ format (do-file path + `//` one-liner) |

---

## Adversarial-default verification ledger consultation

This single-line move does not change any of the previously-verified (path, check) pairs for `do/main.do`:

- `main.do | gate-parity | 2026-05-07T23:30Z | PASS` — still valid (the `do_va=0` gate at L285 is unchanged; the moved invocation is OUTSIDE the `if `do_va'' block by design — clean_va should fire whenever survey-VA fires).
- `main.do | brace-balance-batch-3d | 2026-05-08T03:00Z | PASS` — file hash differs now, but the change does not touch braces; spot-check: `run_data_prep` opens L125, closes L210; `run_survey_va` opens L387, closes L423 (visible in this Read). Brace balance intact.

**Stale-but-acceptable:** the cached ledger rows have an old file hash; in principle they should be re-verified against the new hash. For this specific change (single-line move within established structure, no path/global modifications), the cached checks are inferentially still valid — no semantic ground was disturbed. Stronger position: re-run the two cached checks at next idle commit to refresh hashes.

---

## Derive-don't-guess verification

All references in the change are derived from the repo:

- `do/data_prep/poolingdata/clean_va.do` invocation path — derived from existing batch 9f invocations at L198-201 (sister files in same directory).
- `do/va/merge_va_est.do` reference in NOTE blocks — derived from main.do:317 (the actual invocation site).
- `$estimates_dir/va_cfr_all_v1/va_est_dta/va_<outcome>_all.dta` path in NOTE blocks — derived from clean_va.do:98 (the actual `use` statement) and merge_va_est.do's documented output location.
- `$datadir_clean/calschls/va/va_pooled_all.dta` path in L406 one-liner — derived from clean_va.do:120 (the actual `save` statement).

No fabricated paths, no fabricated dependencies. Compliance with `derive-dont-guess.md` is clean.

---

## Tier 1 pre-commit checklist (per `phase-1-review.md` §2)

| Item | Status | Evidence |
|---|---|---|
| Source identified | OK | Invocation moved within same file; original Phase 1 batch 9f position documented in NOTE block |
| Destination matches plan | OK | Plan v3 §3.5 (M4 acceptance — must complete end-to-end); ADR-0018 acceptance criterion; no ADR for the move itself (it's a bug fix of invocation ordering, not a design decision) |
| Path references updated | OK | grep confirms no stale `do do/data_prep/poolingdata/clean_va.do` at the old Phase 1 site; the new invocation at L406 is the sole live invocation |
| Scope minimal | OK | +21/-3 lines, two edit sites, no unrelated cleanup |
| ADR cited | N/A | No ADR for this hotfix per dispatch-prompt rationale (data dependency was always declared in the file header; this is a cross-phase ordering bug fix discovered empirically in M4 attempt #4) |
| For bug fixes: minimal diff, affected callers identified | OK | Diff is minimal; only caller is main.do itself |
| `/*` balance | OK | 12 opens vs 12 closes — passes the §2 Tier-1 gate |
| Log-path mirror | N/A | This change does not introduce new `log using` or `translate` lines; the invoked `clean_va.do` already writes to `$logdir/data_prep/poolingdata/clean_va.smcl` per its own logging block (lines 84, 146 of clean_va.do) |
| Sandbox-write discipline (ADR-0021) | OK | This change only repositions an invocation; no new write paths introduced. clean_va.do's existing writes (L120, L131 in-place save, L146 translate) all target CANONICAL globals (`$datadir_clean/calschls/va/`, `$logdir/data_prep/poolingdata/`) — verified at file relocation time per the file's own header (lines 30-34 of clean_va.do) |

---

## Score Breakdown

Starting: 100

- **-3** Phase 5 batch-level header at L392-395 was not updated to mention clean_va.do is now part of this phase's chain (the comment refers to "Steps 7+10+11" but the L406 invocation is a Step 9 batch 9f trailer — the L397-405 NOTE explains this, but the L392-395 comment is now slightly misleading on its own). Minor; comment-quality issue (category #10).
- **-2** L406 invocation one-liner could note the in-place `analysisready` update side-effect (lines 128-131 of clean_va.do re-save each survey's `analysisready` with VA columns merged in). This side-effect is load-bearing for Phase 5 downstream readers (`allsvymerge.do`, `factor.do`, `pcascore.do` all use the in-place-updated `analysisready` versions). Currently the one-liner only notes the `va_pooled_all.dta` output. Minor; documentation-completeness issue.

**Final: 95/100** — PASS (well above 80/100 hard gate; well above 90/100 PR gate).

---

## Recommendations (non-blocking, can defer to TODO or fold into next main.do edit)

1. Consider extending L392-395 Phase 5 header to read "Reads CHAIN ... (Step 9 batch 9f trailer + Steps 7+10+11)" so a future reader scanning the phase headers sees the cross-step composition.
2. Consider extending L406 one-liner to "...writes $datadir_clean/calschls/va/va_pooled_all.dta; also re-saves analysisready dtas with VA columns merged in-place (consumed by allsvymerge/factor/pcascore below)" — captures the second output channel.

Both are documentation-polish items. Neither blocks the hotfix.

---

## Escalation Status

None. Score 95/100 is well above all gates. Single-round PASS.

---

## Compliance Evidence (from `.claude/state/verification-ledger.md`)

- `do/main.do | gate-parity | 2026-05-07T23:30Z | PASS` (cached) — `do_va=0` gate parity preserved; this change keeps clean_va.do outside the do_va block by design.
- `do/main.do | brace-balance-batch-3d | 2026-05-08T03:00Z | PASS` (cached, file-hash stale post-edit) — visual spot-check on the modified file confirms balance preserved; `run_data_prep` L125-210, `run_survey_va` L387-423.
- No `cross-phase-data-flow` ledger row exists for main.do (would be a new check class). The data-flow trace performed in §"Sanity Checks" above is the working-receipt; consider adding a ledger row at the next sweep.

---

## Commit-message footer recommendation

```
coder-critic: PASS (95/100) — main.do clean_va.do Phase 1→Phase 5 reorder; M4 attempt #4 r(601) hotfix; cross-phase data dependency now satisfied (do/va/merge_va_est.do produces va_<outcome>_all.dta in Phase 3 batch 3c1, clean_va.do reads in Phase 5 trailer).
```
