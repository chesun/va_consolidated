# Adversarial Review — mkdir-coverage fixes (14 files) + detector

**Date:** 2026-06-01
**Reviewers:** 2 independent Explore agents (fresh context, refute-don't-approve), lenses: (1) Stata fix correctness, (2) detector soundness / false negatives
**Targets:** the 14 edited `.do`/`.doh` files + `py/sweep_mkdir_coverage.py`
**Status:** Active
**Verdict:** Fixes hold up — **13/14 VERIFIED CLEAN, 1 cosmetic LOW nit (works as-is)**. The detector's "0" is sound *for what it detects* but is NOT a sweep-complete guarantee — confirmed limitation, already disclosed; the next Scribe run remains the only true pass/fail.

---

## Review 1 — Stata fix correctness (loop scope, parent chain, placement, #delimit, sandbox)

**Result: 13 files VERIFIED CLEAN, 1 LOW nit.** Reviewer independently traced the loop nesting in each file (not trusting the detector).

- **Loop-scope correctness** — confirmed for every LOOPVAR fix: the `cap mkdir ".../`var'"` sits inside the loop that binds the var, var is in scope and non-empty, and the write's var matches the mkdir's var. Specifically traced and confirmed the **nested 2-level** seccoverageanalysis fix: `sec`year'` mkdir'd in the `foreach year` loop (L82), `sec`year'/gr`i'` in the inner `foreach i` loop (L86), parent-before-child.
- **Parent-chain completeness** — confirmed all intermediate levels present (e.g. base_sum_stats/sample_counts add `$estimates_dir` → `/va_cfr_all_v1` → `/sum_stats`, all three in order).
- **.doh fragment** — confirmed the mkdir block precedes the first real `$datadir_clean/outcomesumstats` save and the earlier `save `k12'` is a genuine `tempfile` (no dir needed).
- **#delimit ;** — verified the insertion points are outside any active `;`-region.
- **Logic / sandbox** — confirmed each diff adds ONLY `cap mkdir` (+ at most a comment); all targets are CANONICAL globals, no LEGACY-path mkdirs.

### The one finding (LOW, cosmetic — NOT fixing mid-M4)
**`do/share/va_var_explain.do:113`** — `cap mkdir "$estimates_dir/va_cfr_all_`version'"` is placed *after* the `use` that reads from that same dir (L112), and is **redundant** (the dir must already exist for the `use` to have succeeded). The reviewer's own severity: **LOW, "code works."** Only L114 (`/reg_out_va`) is load-bearing for the later writes. This is a cosmetic ordering nit, not a correctness bug. **Decision: leave as-is** — it's harmless, and churning a "no-logic-change" file again mid-M4 for cosmetics is not worth the coder-critic/commit cycle. (Verified independently: L112 `use ...va_est_dta/va_all.dta`, L113-114 the two mkdirs — works.)

---

## Review 2 — detector soundness / false negatives

**Result: the "0" is sound for detected patterns but NOT a completeness guarantee.** This is correct and was already disclosed in the tool header + discovery report ("static cannot see local-resolved paths; next Scribe run is final pass/fail"). The reviewer sharpened the specific blind spots:

| Blind spot | Real active-pipeline instance? | My assessment |
|---|---|---|
| `file write` verb not in VERBS | **NO** — only in `do/check/m4_golden_master.do` (verified NOT invoked by main.do; standalone harness). And `file write` targets a pre-opened HANDLE (`file open ... using`), not a dir — adding the verb wouldn't even work as the reviewer admits. | **Non-issue for the active pipeline.** Dismissed. |
| `foreach X of local Y` / `forvalues` loop-var dir levels not expansion-resolved | No current write found that needs it AND lacks the mkdir | **Correct limitation, currently latent.** The matcher only resolves `foreach in <literals>`. If such a write existed uncovered, the tool would still FLAG it (it only *suppresses* via literal-expansion; `of local` vars stay flagged), so this errs SAFE (false-positive, not false-negative) — except the dangerous sub-case below. |
| `covered_by_expansion` could wrongly SUPPRESS a leaf-gap if it only checked the var level not the full expanded path | Reviewer flagged as a risk | **Checked: the matcher expands the FULL `missing_dir` string (var + everything after) and requires every expanded path in mkdirs** — so `.../`version'/sub` is checked as `.../v1/sub` AND `.../v2/sub`, not just `.../v1`. The risk does NOT materialize. Verified in source (`covered_by_expansion` builds `expanded = missing_dir.replace(...)` over the whole level). |
| local-built paths (`local p "$d/sub"; save `p'/f`) opaque | tempfile case in va_het.do (but tempfiles need no dir) | **Correct, irreducible static limit.** Disclosed. |

**Headline:** the "0" reflects truth for the detectable verb+path patterns across the active tree; it is a strong DISCOVERY signal (it found 15 gaps the manual recon missed), not a proof of absence. Already framed that way. The reviewer's ~40-60% "miss rate" figure is about *future* added code, not the current swept state.

---

## My adjudication

- **Accept the fixes as correct.** 13/14 clean on independent loop-tracing; the 1 finding is a cosmetic LOW that works. No defect requires a code change.
- **Detector limitations are real but already disclosed and mostly errs-safe.** The one genuinely-dangerous direction (wrong suppression) was checked and does NOT occur — the matcher expands full paths.
- **No new fixes triggered by this review.** The honest close: static = discovery; Scribe = verdict. The sweep closed every gap the detector can see, which is materially better than the one-at-a-time loop, but is not a guarantee against runtime-only path bugs.

### Optional follow-ups (NOT blocking, post-M4 candidates)
1. va_var_explain.do L113 cosmetic reorder (bundle into any future edit of that file; not standalone).
2. If `file write`-to-handle or `foreach of local` dir-levels ever enter the active pipeline, extend the detector (track `file open` handles; resolve `of local` where the local is a literal list). Not needed today.

## Cross-refs
- Fixes: `quality_reports/reviews/2026-05-31_mkdir-coverage-discovery-report.md`
- Plan + prior review: `..._mkdir-coverage-sweep.md` (EXECUTED), `..._mkdir-sweep-plan_adversarial_review.md`
- Ledger: 14 mkdir-coverage PASS rows + detector row (2026-06-01)
