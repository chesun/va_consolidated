# base_nodrop fail-soft cache-guard fix Review — coder

**Date:** 2026-06-01
**Reviewer:** coder-critic
**Target:** `do/share/base_sum_stats_tab.do` (Phase 1b bug-fix, Option C)
**Score:** 90/100
**Status:** Active
**Mode:** Full (Execution-phase severity: strict)

## Verdict: PASS (90/100) — above the 80 hard gate

Static review only. **Scribe-only, air-gapped: I cannot run Stata.** The control-flow,
path, balance, and memory-state claims below are confirmed by static trace + grep against
the producer scripts. The end-to-end pass/fail is the next Scribe run. One real residual
risk (a legacy path inside the rebuild block) is flagged below — it does not resolve to a
broken path, but it is the single thing static review cannot fully clear.

---

## Code-Strategy Alignment: MATCH

The fix implements Option C from the diagnosis doc
(`2026-06-01_base-nodrop-cached-toggle-r601-debug.md`) exactly:

1. **Fail-soft cache guard** (L139-143): `cap confirm file "$datadir_clean/share/base_nodrop.dta"`
   then `if _rc { local create_sample = 1 }`. A missing cache forces the rebuild block to run.
2. **Latent relative-path fix** (L156): `using data/sbac/va_samples.dta` →
   `using $datadir_clean/sbac/va_samples.dta`.

Both changes match the recorded `no-logic-change` ledger residue (L177) and the diagnosis row
(L176) at the same file hash `3c72b9206c40`.

## Sanity Checks: PASS

## Robustness: Complete (single-bug-fix scope; no robustness matrix expected)

---

## Point-by-point verification (per dispatch instructions)

### Point 1 — Control-flow correctness across all 3 states: CORRECT

| State | Guard outcome | `if create_sample==1` build (L144-275) | `if create_sample==0` use (L277-279) | Result |
|-------|---------------|----------------------------------------|--------------------------------------|--------|
| (a) cache exists | `_rc==0`, stays 0 | skipped | **runs** → loads cache | correct: cache in memory |
| (b) cache missing | `_rc!=0` → set to 1 | **runs** → builds + saves L273 | skipped (create_sample now 1) | correct: rebuilt data in memory (see Point 2) |
| (c) manual `=1`, cache present | guard leaves 1 | **runs** → rebuild + overwrite L273 | skipped | correct: fresh rebuild, use skipped |

The guard runs *after* `local create_sample = 0` (L130) and *before* the `if` blocks, so it
correctly toggles state (b) before either block is evaluated.

### Point 2 — Does the rebuild leave memory in the right state? CONFIRMED CORRECT

This is the highest-risk claim and the one static review must nail. **Determination: YES.**

Trace of state (b), build block:
- L273 `save $datadir_clean/share/base_nodrop.dta, replace` writes the cache. **Stata `save`
  does NOT clear or alter memory** — the dataset that was just built remains loaded.
- L275 `}` closes the build block.
- L277-279 `if create_sample==0 { use base_nodrop.dta, clear }` — in state (b) `create_sample`
  is now 1, so this `use` is **skipped**. Memory therefore retains the L273-built dataset.
- First real downstream use of the data is L292 `estpost sum ... if touse_g11_ela==1`.

The cached `use` at L278 loads exactly the file written at L273. Because `save` leaves memory
intact, the build block's terminal in-memory dataset is byte-identical to what the cached `use`
would load. **There is no intervening `clear`, `preserve`/`restore`, or `drop`** between L273
and L292 — confirmed by grep (`preserve|restore|^clear$` returns only the L61 header word
"preserved" and `, clear` options attached to `use`/`merge`, never a standalone `clear`). The
`touse_*` markers the downstream `estpost` relies on are generated inside the build block
(`create_prior_scores_v1.doh` / `create_diff_school_prop.doh` includes at L240/L248 + the
sample-tag block L251-269), so they are present in the rebuilt memory state.

Note on the rebuild's own internal reload: L238 does `use if grade==11 ... using \`va_dataset', clear`
to filter to the 11th-grade subset, then L240-269 build the analysis vars, then L273 saves. So
the dataset saved at L273 (and left in memory) is the 11th-grade analysis sample — which is the
sample the downstream `touse_g11_ela`/`touse_g11_math` summary code expects. Consistent.

### Point 3 — The relative-path fix: CONFIRMED

`touse_va.do:337` is `save "$datadir_clean/sbac/va_samples.dta", replace` — the producer writes
exactly the path the fix now reads. Independently corroborated by the sibling helper
`create_va_sample.doh:78`, which does the identical merge
(`merge 1:1 merge_id_k12_test_scores using "$datadir_clean/sbac/va_samples.dta", nogen keepusing(touse_*)`)
— same key, same `nogen keepusing(touse_*)`, same canonical path. The merge keys and
`keepusing` in the fix (L156-157) are unchanged from the predecessor; only the path was
repointed. The m4 path matrix (`do/check/m4_path_matrix.csv:191`) also maps this CANONICAL
target. Path fix is correct and matches the established pattern.

### Point 4 — Other relative paths in the rebuild block: ONE FLAG (resolves, but legacy)

Grep of all `use`/`merge`/`do`/`include`/`save` inside the rebuild block (L144-275):

- L149 `use ... using \`k12_test_scores'/k12_test_scores_clean.dta` — backtick macro; `k12_test_scores`
  is a local from `macros_va.doh:107` = `$vaprojdir/data/restricted_access/clean/k12_test_scores`.
  Resolves on Scribe. (Locals survive `include` into the caller scope — confirmed mechanism.)
- L156 `merge ... using $datadir_clean/sbac/va_samples.dta` — the fixed canonical path. OK.
- L163, L175, L194, L198, L202 — all `\`k12_test_scores'` / `\`k12_test_scores_public'` /
  `\`k12_public_schools'` backtick-macro paths from `macros_va.doh`. Resolve.
- **L215 `do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only` — LEGACY path, FLAGGED.**
  This is a `$global`-rooted path, not relative, so it will not silently break the way L156 did.
  `$vaprojdir = /home/research/ca_ed_lab/projects/common_core_va` (settings.do:128), so
  `$vaprojdir/do_files/` == `$matt_files_dir` (settings.do:124) — Matt Naven's untouched pipeline
  dir per ADR-0017. The verification ledger (L44, L47) records
  `$matt_files_dir/merge_k12_postsecondary.doh` as a real, readable file referenced by other
  active scripts (`touse_va.do`, `create_score_samples.do`). **So L215 resolves on Scribe.**
- L233, L238 `\`va_dataset'` tempfile — in-session tempfile, fine.

**Why this is a Minor flag, not a Critical:** L215 is a *pre-existing* legacy reference inside
the dormant build block, not introduced by this fix. Before Option C, the build block never ran
(create_sample always 0), so L215 was never exercised. Option C now makes the block run on a
fresh sandbox, which means L215 will execute for the first time. It points at a `$global` that
*is* bound and *does* resolve to a real file — but it is the one line in the newly-live path
whose Scribe-readability I am inferring from the ledger rather than confirming by execution. If
Matt's `merge_k12_postsecondary.doh` has its own internal dependency that the sandbox lacks, the
rebuild would fail there, not at L156. This is the residual risk the next Scribe run must clear.
(Predecessor log `log/share/base_sum_stats_tab.smcl:868` shows the predecessor invoked the same
L215 line, so it is not a novel call — supporting that it resolves.)

### Point 5 — Sandbox / ADR-0021 compliance: PASS

The guard's `cap confirm` target and the L273 save target are both CANONICAL
(`$datadir_clean/share/base_nodrop.dta`). The L156 fix repoints to CANONICAL
`$datadir_clean/sbac/va_samples.dta`. **No new LEGACY write introduced.** The only legacy
*reference* (L215) is a read/include of Matt's untouched dir, which is the sanctioned exception
per ADR-0017, not a sandbox-violating write.

### Point 6 — Hazards: ALL CLEAR

- **Brace balance:** `\{` = 6, `\}` = 6 — balanced. (Ledger row L177 says "9=9" using a different
  counting method; both agree the file is balanced, which is what matters.)
- **Block-comment balance:** `/*` = 25, `*/` = 25 — balanced.
- **No `*/`-glob in added comments:** the added comment block (L131-138) uses explicit filenames
  (`base_nodrop.dta`, `$datadir_clean/sbac/va_samples.dta`); no `*` path-glob wildcard. The
  `*`-prefixed lines are line-comment markers, not globs. No comment-bug hazard.
- **No logic change beyond guard + path fix:** confirmed against the ledger residue (L177) and
  static read — the diff is the guard (L131-143) plus the single-token L156 repoint.

---

## Compliance Evidence (from .claude/state/verification-ledger.md)
- do/share/base_sum_stats_tab.do | diagnosis:base-nodrop-cached-toggle-r601 | 2026-06-01T03:30Z | hash 3c72b9206c40 | DIAGNOSED | root cause = cached-toggle with un-inherited legacy cache; matches diagnosis doc
- do/share/base_sum_stats_tab.do | no-logic-change | 2026-06-01T03:30Z | hash 3c72b9206c40 | UNVERIFIED | residue = Option C guard + L156 path fix; end-to-end unrun (Scribe-only)

**Note on the `no-logic-change` UNVERIFIED row (evidence-gating §6):** I am NOT issuing a
clean-refactor PASS on a no-logic-change claim. This change is a *deliberate bug-fix* that
intentionally alters behavior (a missing cache now forces a rebuild instead of erroring). The
`UNVERIFIED` result is therefore expected and correct — there is, by design, a behavior change,
and the recorded residue matches the intended fix exactly. The gate's prohibition (no clean PASS
on a non-empty residue) is satisfied because no clean-refactor PASS is being claimed. The score
reflects bug-fix correctness, with a deduction for the one unconfirmable runtime path (L215).

## Tier-2 verdict evidence

- **claim:** "In state (b) the rebuild leaves the correct dataset in memory for the L292+ summary code."
  **artifact_citation:** `do/share/base_sum_stats_tab.do:273-292`
  **sufficiency_argument:** L273 `save` (Stata save never clears memory) + skipped L278 `use` +
  absence of any `clear`/`preserve`/`drop` between L273 and L292 (grep-confirmed) means the
  build-block terminal memory == cached-use memory. Sufficient for the memory-state claim.
- **claim:** "The L156 path fix points at the actual producer of va_samples.dta."
  **artifact_citation:** `do/samples/touse_va.do:337`
  **sufficiency_argument:** producer's `save` target string equals the fix's `using` target;
  corroborated by `do/samples/create_va_sample.doh:78` doing the identical canonical merge.

---

## Score Breakdown
- Starting: 100
- Minor (-5): L215 `$vaprojdir/do_files/merge_k12_postsecondary.doh` inside the now-live rebuild
  block — a legacy reference whose Scribe-readability is inferred from the ledger, not executed.
  Resolves to a bound `$global` (not a broken path), so Minor not Major; flagged because Option C
  makes this line live for the first time and it is the residual single-point runtime risk.
- Minor (-5): cannot execute (Scribe-only) — the end-to-end rebuild (raw K12 reads, postsec
  merge, helper includes) is statically traced as resolvable but unrun. Standard air-gapped
  caveat; the next Scribe run is the final arbiter.
- **Final: 90/100**

## Escalation Status: None (PASS, round 1)

## Recommendations (non-blocking)
1. Before/at the next Scribe run, watch L215 specifically — if the rebuild fails, it is the most
   likely site (legacy include now exercised for the first time). Consider repointing it to the
   consolidated `merge_k12_postsecondary.doh` location if one exists, or confirming Matt's file is
   self-contained.
2. After the first successful Scribe rebuild, flip the `no-logic-change`/diagnosis ledger rows to
   reflect the realized pass (currently UNVERIFIED/DIAGNOSED pending execution).
