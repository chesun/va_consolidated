# imputation-clamp Review — coder-critic

**Date:** 2026-06-09
**Reviewer:** coder-critic
**Target:** `do/survey_va/imputation.do` (clamp OLS-imputed predictions to Likert [-2, 2])
**Score:** 82/100
**Status:** Active

## Code-Strategy Alignment: MATCH (implementation) — but DEVIATION from the stated goal of resolving the FAIL

The researcher directed: clamp OLS-imputed predictions to [-2, 2], censoring out-of-range predictions to the nearest bound, and do NOT relax the check. The 5-line insertion implements exactly that idiom, identically in all 4 regression-imputation loops. The clamp logic is correct.

However, the **stated motivation** — "fixes secqoi27mean_pooled max=2.61 -> 2; check_survey_indices" (the comment on lines 140/158/176/194) — does **not hold**, because of a source/destination path mismatch. The clamp does not touch the file the failing assert reads. This is the dominant finding below (Concern 2). The implementation faithfully executes the researcher's instruction; the instruction will not, by itself, turn the Phase-7 check from FAIL to PASS.

## Sanity Checks: CONCERNS

The clamp is directionally and numerically sound (verified below), but it targets the wrong artifact relative to the check it is meant to satisfy.

## Robustness: N/A (not a robustness-check change)

---

## Detailed findings by concern

### Concern 1 — Clamp correctness: PASS

The idiom bounds ONLY imputed observations and leaves observed values untouched:

```stata
replace `i' = hat_`i' if imputed`i' == 1
replace `i' = -2 if imputed`i' == 1 & `i' < -2
replace `i' =  2 if imputed`i' == 1 & `i' >  2 & !missing(`i')
```

- The `imputed`i' == 1` guard on both clamp lines confines the operation to imputed cells. Observed (`imputed`i' == 0`) cells, already in range from the survey, are never rewritten. Correct.
- The `!missing(`i')` guard on the **upper** bound is necessary and correctly placed: Stata orders missing as `+∞`, so `. > 2` is true; without the guard a missing prediction would be coerced to 2. With the guard, missing stays missing.
- The **lower** bound needs no guard: missing is never `< -2`, so `replace `i' = -2 if ... & `i' < -2` cannot fire on a missing value. Correct asymmetry.
- Order is right: clamp runs after the `replace = hat` assignment and before `drop hat`, so it operates on the just-written imputed values.

This matches the researcher's standalone stata17 verification (2.61→2, -2.7→-2, missing stays missing, non-imputed 1.5/-1.0 unchanged). I independently confirmed the missing-value semantics against Stata's ordering rule; no separate run needed for a 3-line `replace` idiom whose behavior is fully determined by documented `replace`/missing semantics.

**Verdict — Tier-2 locatable judgment:**
- claim: "The clamp bounds only imputed obs to [-2,2], leaves observed values untouched, and preserves missing."
- artifact_citation: `do/survey_va/imputation.do:141-142` (and identical blocks at 159-160, 177-178, 195-196)
- sufficiency_argument: The two `replace` lines carry the `imputed`i'==1` predicate (scopes to imputed), the bound predicates `< -2` / `> 2` (only out-of-range fire), and the `!missing` guard on the upper bound (Stata missing > 2). Observed-cell and missing-cell behavior follow deterministically from `replace`'s if-condition semantics; no data run is required to establish it. Citation RESOLVED (lines present in file, confirmed by Read).

### Concern 2 — Does it resolve the FAIL: NO (HIGH severity)

This is the load-bearing finding. The clamp does **not** make `check_survey_indices` pass for `secqoi27`, because the failing assert reads a **different file** from the one `imputation.do` writes.

Evidence chain:

1. The FAIL is in **SUB-CHECK 1** (source items), confirmed by the server log:
   `log/check/check_survey_indices.smcl:137-138`:
   ```
   PASS: imputed source _N == 5625
   FAIL: imputed secqoi27mean_pooled max =  2.6133 (expected ∈ [0, 2.01])
   ```
   The `imputed source` label corresponds to `src_tag == calschls_1`.

2. SUB-CHECK 1's `imputed` source is the **LEGACY predecessor** file, not the consolidated output:
   `do/check/check_survey_indices.do:131`:
   ```stata
   local src_dta "$caschls_projdir/dta/allsvyfactor/imputedallsvyqoimeans.dta"
   ```
   `$caschls_projdir = /home/research/ca_ed_lab/users/chesun/gsr/caschls` (`do/settings.do:136`). This is the static predecessor artifact produced by the OLD caschls pipeline.

3. The consolidated `imputation.do` (the file under review) writes its clamped output to the **CANONICAL** path:
   `do/survey_va/imputation.do:201`:
   ```stata
   save $datadir_clean/survey_va/imputedallsvyqoimeans, replace
   ```
   `$datadir_clean = $consolidated_dir/data/cleaned` (`do/settings.do:96,102`). Different file.

4. Nothing in the consolidated tree writes back to the LEGACY `$caschls_projdir/.../imputedallsvyqoimeans.dta` (`grep` for any `save` targeting `caschls_projdir`/`allsvyfactor` returned 0). The 2.6133 value is baked into the predecessor file the OLD pipeline produced without a clamp; the clamp in the consolidated file cannot reach it.

Consequence: with the rc-clobber now fixed (ledger row `do/check/check_survey_indices.do | diagnosis:fail-branch-exit-rc-clobber | 2026-06-09T17:37Z | DIAGNOSED`), SUB-CHECK 1 will `exit 9` on `secqoi27` **before** SUB-CHECK 2 (the built-index checks that consume the CANONICAL clamped output) ever runs. The clamp fix lands in the right place for the *built indices* but the *first* assert to fire reads an unclamped predecessor file and halts the pipeline.

Note the early-exit also masks the rest of SUB-CHECK 1: there may be other out-of-range items in the same LEGACY file (the loop exits on the first failing `max`).

Three escalation-worthy implications for the researcher (NOT mine to decide):
- If the intent is for the consolidated pipeline to be self-contained (per ADR-0021 sandbox), SUB-CHECK 1's `imputed` source arguably should read the CANONICAL `$datadir_clean/survey_va/imputedallsvyqoimeans.dta` (the clamp's actual output), not the LEGACY predecessor. As written, the check validates a predecessor artifact the consolidated code does not control.
- Alternatively, if SUB-CHECK 1 is intentionally a LEGACY-source integrity check (validating the static caschls inputs), then clamping `imputation.do` is the wrong lever for it — that file's out-of-range value can only be fixed by re-running the predecessor pipeline or by re-pointing the check.
- The compcase branch (`calschls_2`, `allsvyqoimeans.dta`) is a complete-case file with no imputation, so it is not at risk from unbounded OLS — but it too reads LEGACY.

**Verdict — Tier-2 locatable judgment:**
- claim: "The clamp does not resolve the reported `secqoi27` FAIL because the failing assert reads a LEGACY file the clamp does not write."
- artifact_citation: `do/check/check_survey_indices.do:131` (reads LEGACY) vs `do/survey_va/imputation.do:201` (writes CANONICAL); confirming log at `log/check/check_survey_indices.smcl:138`
- sufficiency_argument: The check's `imputed`-source local resolves to `$caschls_projdir/...` and `imputation.do`'s save targets `$datadir_clean/...`; settings.do binds these to disjoint roots; grep shows no consolidated write to the LEGACY path. The labeled log line ties the 2.6133 FAIL to that LEGACY source. All citations RESOLVED.

### Concern 3 — Completeness / consistency: PASS

- All 4 loops (climate / quality / support / motivation) carry an identical 5-line insertion. Grep confirms 4× each of the three patterns (`replace = -2`, `replace = 2`, clamp comment) — 12 lines total, evenly distributed.
- The **motivation** loop should NOT differ. Its imputed vars (`secqoi31-34mean_pooled`) are exploratory and dropped from the paper (`imputedcategoryindex.do:90` comments out `motivationvars`; `check_survey_indices.do:46-47` says do not assert motivation). They are also not among the climate/quality/support index items, so clamping them changes nothing paper-shipping and keeps the four loops uniform. Treating all four identically is the right call.
- No imputed variable bypasses these loops: every var in `allqoivars` that gets mean-filled (lines 120-124) and then regression-imputed belongs to exactly one of the four category locals, and each category local drives one clamp loop.

### Concern 4 — Methodological soundness (FLAG, not blocking — researcher's call)

Clamping (censoring to the nearest bound) is a defensible quick fix but has the known costs the prompt anticipated:
- It biases the affected imputed values toward the boundary and creates point masses at exactly ±2 for the out-of-range imputations. For the items where OLS overshoots (only `secqoi27` is documented so far, but the early-exit masks others), the imputed distribution gains a spike at the bound.
- Interaction with downstream z-scoring (`imputedcategoryindex.do:117-125`): the raw index is a sum of clamped items, then z-scored. Clamping can only *reduce* the magnitude of an out-of-range imputed item (2.61→2). The effect on `climateindex` (which contains `secqoi27`) is a small downward nudge for schools whose `secqoi27` was imputed-and-overshooting; after z-scoring (mean 0, SD 1), the index is rescaled, so the level shift is absorbed but the relative ordering of those few schools changes slightly. The check's z-score invariants (mean≈0, SD∈[0.95,1.05], min∈[-5,-1], max∈[1,5]) are robust to this. No correctness break in the index construction.
- Alternatives (PMM, truncated regression, or relaxing the check bound) trade differently between bias and distributional fidelity. The decision among them is the researcher's; I am reviewing implementation faithfulness, which is sound.

This is a research-design tradeoff, not a code defect. Recorded here so it is auditable, not deducted.

### Concern 5 — Pre-commit Tier-1 (phase-1-review §2): PASS

- `/*` balance: `grep -c '/\*'` = 5, `grep -c '\*/'` = 5. Balanced.
- No Variant-8 over-flatten artifacts: `^-+<x>$` and `^\s*<x>\s*$` both return 0.
- No path-glob `*` introduced into any comment context. The clamp comments use prose + bracket notation `[-2, 2]`; `secqoi27mean_pooled` in the comment is a full variable name, not a glob.
- Per-file log path unchanged: `log using "$logdir/survey_va/imputation.smcl"` (`:60`) and `translate ... $logdir/survey_va/imputation.log` (`:204`) — correct reldir mirror, untouched by the change.
- No new LEGACY writes: sole `save` (`:201`) targets CANONICAL `$datadir_clean/survey_va/imputedallsvyqoimeans`. `log using` / `translate` target CANONICAL `$logdir/`. No writes outside the sandbox.
- Scope minimal: the diff is the 4 identical 5-line clamp insertions and nothing else. The mean-imputation pass, regression loops, locals, and save are unchanged.

### Concern 6 — ADR: SHOULD be written (ADR-0027)

This is a methodological choice (bounding imputed predictions to the survey's Likert support), which per `.claude/rules/decision-log.md` ("a methodological choice is made") warrants an ADR. The next number is **0027** (highest existing is 0026). It is distinct from ADR-0011 (sums→means in the *index constructor*); this one concerns the *imputation* step. Recommend an ADR recording: the decision to clamp vs alternatives (PMM / truncated regression / relax-check), the point-mass-at-bound tradeoff, and — critically — the resolution of the SUB-CHECK 1 LEGACY-vs-CANONICAL question from Concern 2 (whether the check should be re-pointed to the CANONICAL clamped output). Not blocking the commit, but should accompany it.

---

## Code Quality (10 categories)

| Category | Status | Issues |
|----------|--------|--------|
| Script structure & headers | OK | Header block present (purpose / invoked-from / inputs / outputs / ADRs); change doesn't touch it |
| Console output hygiene | OK | Uses `di as text` for run markers; no cat/print pollution introduced |
| Reproducibility | OK | Relative paths via globals only; no abs paths; no seed needed (deterministic OLS) |
| Function/program design | OK | Idiom mirrors existing per-loop pattern |
| Figure quality | N/A | No figures |
| Output persistence | OK | Sole `save` targets CANONICAL; downstream chain intact |
| Comment quality | OK | Clamp comment explains WHY (unbounded OLS) + cites the symptom; no dead code. Minor: the "fixes ...check_survey_indices" claim is inaccurate per Concern 2 — comment overstates the effect |
| Stata comment safety | OK | `/*`==`*/` 5=5; no glob in comments; no Variant-8 artifacts; no `//*****` banners added |
| Error handling | OK | `!missing` guard is itself defensive error handling against Stata missing-ordering |
| Professional polish | OK | 2-space indent consistent with file; aligned `=  2` / `= -2` |

---

## Compliance Evidence (from .claude/state/verification-ledger.md)
- do/survey_va/imputation.do | no-logic-change | (MISSING — file edited this session; recorder row not present in ledger. This IS a logic change, not a clean refactor, so a no-logic-change PASS is not claimed.)
- do/survey_va/imputation.do | no-hardcoded-paths | (not in ledger; verified in-review — grep for `"/Users`/`"/home`/`"C:\\` in use/save lines: 0 matches in executable code. The only absolute literals are in the header-comment relocation log, not executable code.)
- do/survey_va/imputation.do | adr-0021-sandbox-write | (not in ledger; verified in-review — sole save L201 + log/translate all target CANONICAL `$datadir_clean` / `$logdir`.)
- do/check/check_survey_indices.do | diagnosis:fail-branch-exit-rc-clobber | 2026-06-09T17:37Z | 975d4c06e885 | DIAGNOSED | (cited — confirms the FAIL now halts post-rc-fix, which is why Concern 2 matters)
- do/check/check_survey_indices.do | no-hardcoded-paths / no-raw-data-overwrites / adr-0021-sandbox-write | 2026-06-09T17:37Z | PASS (consulted for the LEGACY-source path confirmation)

No fabricated compliance claims in the file's comments — the change carries no docstring asserting a verified property; the only overclaim is the "fixes check_survey_indices" comment, addressed as a Minor under Concern 2.

---

## Score Breakdown
- Starting: 100
- Concern 2 — change does not resolve the reported FAIL (the assert reads a LEGACY file the clamp does not write); the stated code-purpose comment is therefore inaccurate and the Phase-7 gate will still halt: **-15** (Major — code does not achieve its stated paper-affecting purpose; not a -25 "code doesn't match strategy" because the *clamp idiom itself* is exactly as specified and is correct where it lands)
- ADR not yet written for a methodological decision (ADR-0027): **-3** (Minor; not blocking the commit but should accompany it)
- **Final: 82/100**

Clamp idiom: correct. Tier-1 pre-commit: clean. Scope: minimal. The deduction is entirely about the path-target mismatch between where the clamp writes (CANONICAL) and where the failing assert reads (LEGACY) — which means the change, while correctly implemented, will not by itself flip the Phase-7 check to PASS.

## Escalation Status: None (score >= 80)

Gate met at 82/100. But flag for the researcher before relying on this to pass Phase 7: **the clamp will not resolve the `secqoi27` FAIL as the check is currently written.** SUB-CHECK 1 reads the LEGACY predecessor `$caschls_projdir/.../imputedallsvyqoimeans.dta`; the clamp writes the CANONICAL `$datadir_clean/survey_va/imputedallsvyqoimeans.dta`. A decision is needed (and belongs in ADR-0027): re-point SUB-CHECK 1's `imputed` source to the CANONICAL clamped output, OR accept that the LEGACY-source assert needs a different remedy. Until then, the next M4 run will still `exit 9` at `check_survey_indices.do` SUB-CHECK 1.
