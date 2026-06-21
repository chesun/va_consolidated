# ADR-0011 sums→means Review — coder-critic

**Date:** 2026-06-21
**Reviewer:** coder-critic
**Target:** ADR-0011 sums→means fix — `do/survey_va/imputedcategoryindex.do` + `do/survey_va/compcasecategoryindex.do`
**Score:** 96/100
**Status:** Active

---

## Verdict

**PASS (96/100).** The deferred ADR-0011 fix is implemented exactly as the ADR prescribes, in both constructors, with correct Stata syntax, correct placement (after the sum loop, before z-scoring), and a verified z-invariance guarantee for every paper-affecting downstream consumer. The raw on-disk indices now match the paper text ("averages across questions"); the z-scored columns and all regression coefficients are mathematically unchanged. Mechanics are clean (`/*` 7=7, braces balanced, 0 hardcoded paths, no new LEGACY writes, no `*`-glob-in-comment, no Variant-8 artifacts). Air-gapped — not re-run; UNVERIFIED-by-execution flagged, not deducted.

## Code-Strategy Alignment: MATCH

ADR-0011 §Decision prescribes the pattern verbatim:

```stata
replace climateindex = climateindex / `: word count `climatevars''   // NEW: convert sum to mean
```

Both files implement exactly this, for all three indices, placed after the corresponding `foreach` sum loop:

| File | climate | quality | support |
|------|---------|---------|---------|
| `imputedcategoryindex.do` | L102 | L109 | L116 |
| `compcasecategoryindex.do` | L104 | L111 | L118 |

No silent deviation. ADR-0011 §Decision is satisfied to the line.

## Sanity Checks: PASS

- **Diagnosis is correct.** The raw-index hard-halt (`raw climateindex min = −5.3293 < −2.01`) was the ADR-0011 regression test firing legitimately, not a heuristic false-positive. A 9-item sum of items each ∈ [−2,2] ranges [−18,18]; −5.33 is a valid sum. After `/9` it becomes a mean ∈ [−2,2]. `do/check/check_survey_indices.do:258-287` documents this exact invariant: "a mean of items each in [−2,2] is itself in [−2,2] (±0.01)... This IS the ADR-0011 sums→means test." The fix turns the failing assert into a passing one for the right reason.
- **Magnitude/sign:** N/A (mechanical rescale; no estimand change).
- **Sample size:** unchanged (division is row-wise, no `drop`/`keep` added).

## Robustness: Complete

This is a single deferred-ADR implementation, not a multi-spec analysis. The relevant robustness question — "does any paper number move?" — is answered NO under the z-invariance verification below.

---

## Adversarial verification (the 6 requested checks)

### 1. Stata syntax of `` `: word count `<cat>vars'' `` — CONFIRMED CORRECT
The extended macro function `: word count <list>` returns the integer count of whitespace-delimited words in its argument. With the inner `` `climatevars' `` expanding to the 9-item varlist, the expression evaluates to `climateindex / 9`. The `<cat>vars` locals are defined at the top of each file (imputed L87-89; compcase L89-91) and are still in scope at the replace site (no intervening `clear`/scope break — `clear all` is at the top, before the locals; `use ... , clear` at L85/L87 does not clear locals). Nesting of backtick-quotes is valid: outer `` `: ... ' `` wraps inner `` `climatevars' ``. **Item counts (counted from the varlists):**

| Index | Varlist members | Count | Design memo | Match |
|-------|-----------------|-------|-------------|-------|
| climate | parentqoi 16/17/27 + secqoi 22/23/24/26/27/29 | **9** | 9 | ✓ |
| quality | parentqoi 30/31/32/33/34 + secqoi 28/35/36/37/38/39/40 + staffqoi 20/24/87 | **15** (5+7+3) | 15 | ✓ |
| support | parentqoi 15/64 + staffqoi 10/128 | **4** | 4 | ✓ |

So the three divisions are `/9`, `/15`, `/4` respectively. Matches ADR-0010 + `check_survey_indices.do:42-45`.

### 2. Placement (after sum loop, before z-scoring) — CONFIRMED in BOTH files
`imputedcategoryindex.do`: sum loop L99-101 → divide L102 → z-scoring L129-132 (`gen z_`i' = (`i'-r(mean))/r(sd)`). Same ordering L104-109-… and L111-116. `compcasecategoryindex.do`: L101-103 → L104 → z-scoring L131-134. The division sits strictly between accumulation and standardization in all six instances. No double-count risk (it runs once, outside the loop) and no skipped-application risk (it precedes every consumer of the index).

### 3. Both files identical (3 divisions, counts 9/15/4) — CONFIRMED
The three `replace ... / `: word count ...''` lines are textually identical across the two files; only line numbers differ (compcase is offset by ~2 lines due to a different blank-line layout). Same varlists → same 9/15/4 divisors.

### 4. z-invariance claim — CONFIRMED for all paper-affecting consumers
Mathematically: if `x_new = x_old / N`, then `mean_new = mean_old/N`, `sd_new = sd_old/N`, so `z_new = (x_old/N − mean_old/N)/(sd_old/N) = (x_old − mean_old)/sd_old = z_old`. Exact in real arithmetic; the uniform 1/N factor cancels in floating point to well within the paper's display precision.

Grepped every raw (non-z) `climateindex`/`qualityindex`/`supportindex` use across `do/survey_va/` and `do/share/`:
- `do/share/` — **0 matches** (no raw-index consumer in the share/ paper-producer tree).
- `do/survey_va/indexhorserace.do:74` and `indexhorseracewithdemo.do:99` — use `z_climateindex z_qualityindex z_supportindex` only (z-scored); regressions at L98 / L133 consume the z-names. Invariant.
- `do/survey_va/indexregwithdemo.do:106` — declares `local indexvars climateindex qualityindex supportindex` (raw names) BUT the regression at L161 is `reg va_... z_`index' ...` — i.e., the macro is only a name-stem list to build `z_`index''. **The raw index never enters a regression.** This is the one place a raw name appears downstream, and it is z-prefixed before use. Verified non-paper-affecting.
- The two constructors themselves: raw index used only to build `z_`i'` (imputed L129-132 / compcase L131-134) and saved to disk. Z-build is invariant.

Conclusion: no paper number consumes the raw index; every regression uses a z-scored index; z is unchanged. ADR-0011 §Consequences ("none for the regression-coefficient tables") holds.

### 5. Golden-master consequence — FLAGGED (intended deviation)
The on-disk RAW columns `climateindex`/`qualityindex`/`supportindex` in `imputedcategoryindex.dta` and `compcasecategoryindex.dta` will now differ from the predecessor (sums → means; e.g. climate scaled by 1/9). **This is an INTENDED ADR-0011 deviation, not a regression.** A naive `cf _all` golden-master compare of these two `.dta` files against the predecessor WILL flag the raw index columns as differing — the M4 triage must whitelist these three columns in both files. The `z_climateindex`/`z_qualityindex`/`z_supportindex` columns are unaffected (z-invariant), and all downstream regression-export `.dta`/`.ster` artifacts stay identical. Recommend a note in the M4 path-matrix / triage doc so the intended raw-column delta isn't chased as a spurious mismatch.

### 6. Mechanics — ALL PASS
| Check | imputed | compcase |
|-------|---------|----------|
| `/*` vs `*/` balance | 7 = 7 | 7 = 7 |
| brace `{` vs `}` | 18 = 18 | 19 = 19 |
| hardcoded abs paths (`"/Users`/`"/home`/`"C:\`) | 0 | 0 |
| `*`-glob-in-comment / Variant-8 over-flatten (`^-+<x>$`, `^\s*<x>\s*$`, `[a-z]/\*`) | 0 | 0 |
| log-path mirror (`$logdir/survey_va/<name>.smcl` + `cap mkdir`) | intact (L77-78, L230) | intact (L79-80, L227) |
| new LEGACY writes | none (all `save`/`export` target CANONICAL globals) | none |

Header doc updated correctly in both files ("summing"→"averaging"; "deferred"→"applied 2026-06-21"; ADR-0011 line in the ADR list). ADR-0011 status line marked implemented 2026-06-21. The inline comment block (imputed L92-96 / compcase L94-98) explains the WHY (ADR cite + z-invariance rationale) — satisfies ADR-0011 §Open-questions recommendation for a maintainer anchor comment.

---

## Compliance Evidence (from .claude/state/verification-ledger.md)
- `do/survey_va/imputedcategoryindex.do` | no-logic-change | (no row — N/A: this IS a deliberate logic change, sum→mean; the no-logic-change gate does not apply)
- `do/survey_va/compcasecategoryindex.do` | no-logic-change | (no row — N/A, same reason)
- `do/survey_va/imputedcategoryindex.do` | no-hardcoded-paths | (MISSING — verified live this review: grep returned 0 matches; recommend appending a PASS row)
- `do/survey_va/compcasecategoryindex.do` | no-hardcoded-paths | (MISSING — verified live: 0 matches; recommend appending a PASS row)
- `do/check/check_survey_indices.do` | diagnosis:z-climateindex-min-neg7-tail-bound | 2026-06-21T16:30Z | a17d51fe4d1a | DIAGNOSED (ADR-0033 heuristic-removal context; consulted to confirm the raw-index check that fired is the real ADR-0011 test, not a heuristic)

No ledger row asserts compliance on these two files, so there is no stale-hash or false-PASS exposure. The fix is a logic change (not a refactor), so the Tier-1 no-logic-change recorder gate is not in scope.

## Tier-2 verdict — z-invariance / behavior-preservation
- **claim:** No paper-reported regression coefficient changes; every downstream regression consumes a z-scored index, and z is invariant to the 1/N rescale.
- **artifact_citation:** `do/survey_va/indexregwithdemo.do:161` (raw `indexvars` consumed only as `z_`index'`), `do/survey_va/indexhorserace.do:98`, `do/survey_va/indexhorseracewithdemo.do:133`, `do/survey_va/imputedcategoryindex.do:131`.
- **sufficiency_argument:** These four sites are the complete set of index consumers (grep of `do/survey_va/` + `do/share/` returned no other raw or z index use). Each uses the `z_`-prefixed variable; the z-build follows the division, and z is algebraically invariant to a uniform multiplicative rescale, so the saved z columns are numerically identical pre/post fix. `do/share/` has zero raw-index consumers.

## Score Breakdown
- Starting: 100
- Air-gapped (Scribe-only) — not executed this review: UNVERIFIED, **no deduction** per task instruction.
- Minor (−2): two `no-hardcoded-paths` ledger rows absent for these files; verified live (0 matches) but not recorded — recommend appending PASS rows so the cache reflects the verification.
- Minor (−2): golden-master M4 triage should be annotated for the intended raw-column delta (not yet done in a triage/path-matrix doc); without it a future `cf` compare risks chasing a spurious mismatch.
- **Final: 96/100 PASS**

## Escalation Status: None

## Recommendations (non-blocking)
1. Append two `no-hardcoded-paths | PASS` rows to the verification ledger for the two constructor files (evidence: grep 0 matches, this review).
2. Note the intended raw-index column delta (climate/quality/support, ÷9/15/4) in the M4 golden-master triage / path-matrix doc so the predecessor-vs-consolidated `cf` whitelists these three columns in both `.dta` files; confirm `z_*` columns stay in the exact-match set.
3. On the next Scribe run, confirm `check_survey_indices.do` SUB-CHECK raw-index assert (`[-2.01, 2.01]`) now PASSes for both imputed and compcase — that is the empirical close-out of ADR-0011.
