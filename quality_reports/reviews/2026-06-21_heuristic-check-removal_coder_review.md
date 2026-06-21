# heuristic-check-removal Review — coder

**Date:** 2026-06-21
**Reviewer:** coder-critic
**Target:** heuristic-check removal (`do/check/check_va_estimates.do` full rewrite + `do/check/check_survey_indices.do` + `do/check/check_samples.do`)
**Score:** 94/100
**Status:** Active
**Supersedes:** (none — new target slug; prior `2026-06-09_check-soft-and-repoint` / `2026-06-09_check-files-rc-fix` are different targets)

**Mode:** Full (Phase 1c §5.3 methodology change; Execution-phase severity HIGH)

---

## Code-Strategy Alignment: MATCH

The diff implements ADR-0033 and the 2026-06-21 audit faithfully. Every item the audit
classified REMOVE / MODIFY / KEEP / ADD lands as specified, and Christina's confirmed
borderline calls (remove VA centered-mean, remove CFR cell-floor soft, loosen the centering
halves) are all applied.

## Sanity Checks: PASS

The motivating principle is sound: the z_climateindex min = -7.0888 halt was a false-FAIL on
an a-priori tail heuristic while the mathematical asserts (z mean≈0, SD≈1) passed, confirming
standardization is correct. Removing the distributional guesses and keeping the hard-basis
checks is the right call. The claim that VA numeric correctness is covered by the M4 golden
master is **substantiated** — see "VA-check defensibility" below.

## Robustness: Complete

All KEPT hard-basis checks verified present and intact; all REMOVED heuristics verified gone
from active code (only comments documenting the removal remain).

---

## What I verified (evidence)

### 1. No hard-basis check was removed — KEPT items confirmed present

| KEPT item | Location | Status |
|---|---|---|
| raw-index `[-2.01, 2.01]` ADR-0011 regression test | check_survey_indices.do:268, 277 (`r(min) >= -2.01` / `r(max) <= 2.01`) with ADR-0011 FAIL message at :271-272, :280-281 | INTACT (loosened, not deleted) |
| z `abs(r(mean)) < 0.01` (mathematical) | check_survey_indices.do:234 | INTACT |
| z `inrange(r(sd), 0.95, 1.05)` (mathematical) | check_survey_indices.do:242 | INTACT |
| source items `[-2.01, 2.01]`, staffqoi98 `[-3.01, ...]` (ADR-0032) | check_survey_indices.do:176-177 (`lo_bound`), :178, :186 | INTACT, floor preserved |
| item counts 9/15/4 | check_survey_indices.do:124-126 | INTACT |
| `_N == 5625` | check_survey_indices.do:155 | INTACT |
| item presence (28 components) | check_survey_indices.do:198-208 | INTACT |
| `_N == 1784445`, per-cohort 402416/406084/450201/525744, 1389 schools | check_samples.do:92, 103-119 | INTACT |
| grade==11, year∈[2015,2018] | check_samples.do:95, 98 | INTACT |
| race orthogonality, binary {0,1,.} | check_samples.do:124, 138 | INTACT |

### 2. No heuristic check survived — REMOVED items confirmed gone from active code

`grep` for `inrange(r(min), -5`, `[0.05, 0.30]`, `5478`, `6940`, `cohort_size`-range,
`abs(r(mean)) < 0.05`, and any active `corr`/`pwcorr`/`correlate`: **every match is in a
comment** (check_survey_indices.do:64-65, 250, 289-290; check_va_estimates.do:12-14, 101-102;
check_samples.do:38, 154) documenting the removal, or is a KEPT mathematical assert (the
`abs(r(mean)) < 0.01` z-mean at :234, not the removed `< 0.05` VA mean). Zero active
`corr`/`pwcorr`/`correlate` statements across all three files (the soft correlation signals
are gone, not merely commented inline).

### 3. Loosened bounds are correct

The source-item and raw-index asserts now test `r(min) >= floor` AND `r(max) <= ceiling`,
dropping the `min <= 0` / `max >= 0` centering half. This keeps the hard Likert-coding /
mathematical bound and removes only the distributional centering assumption — exactly the
ADR-0033 prescription. staffqoi98's `-3.01` floor is preserved (check_survey_indices.do:177)
per ADR-0032.

### 4. New structural check in check_va_estimates is sound

`foreach v in va_ela_b_sp_b_ct va_math_b_sp_b_ct` → `capture confirm variable` (FAIL → non-zero
`exit \`rc'`) + `qui count if !missing(\`v')` (N==0 → `exit 9`). The `local rc = _rc` is read
immediately after `capture confirm variable` (:107) before the `cap log close`/`cap translate`
(:110-111), so the rc-clobber bug fixed in `2026-06-09_check-files-rc-fix` is correctly
avoided. The `exit 9` for all-missing is a hardcoded structural code (not a clobbered `_rc`),
which is acceptable. Skeleton `exit 0` (:89) and the capture-confirm-file shim are preserved.

### 5. Removing ALL of check_va_estimates' distributional checks IS defensible

I sanity-checked the "M4 golden master covers VA correctness" claim against
`do/check/m4_golden_master.do`. It is true and concrete: `cap_compare_dta` runs `cf _all`
(PASS only at 0 cumulative diffs / max numeric diff ≤ 0.01, m4 header line 53) and
`cap_compare_ster` compares `e(b)` element-wise (tol 0.01) and `sqrt(diag(e(V)))` (tol 0.05,
:262). Every VA `.dta` and `.ster` in the path matrix is diffed against the predecessor at
those tolerances. That is a strictly stronger correctness guarantee than the removed
distributional envelopes, which were a-priori magnitude guesses, not predecessor-anchored
diffs. **No hard-basis VA check was lost** — the former checks were all heuristic (centered-mean
tolerance, SD envelope, cross-spec/peer-control correlations, CFR soft floor). The one
genuinely structural fact (reference columns exist + non-empty) is the one that was added.

### 6. Mechanics — all PASS

| Check | check_va_estimates | check_survey_indices | check_samples |
|---|---|---|---|
| `/*` vs `*/` balance | 4 = 4 | 5 = 5 | 5 = 5 |
| Variant-8 over-flatten (`^-+<x>$`, `^\s*<x>\s*$`) | 0 | 0 | 0 |
| `*`-glob in comment | 0 | 0 | 0 |
| hardcoded abs paths | 0 | 0 | 0 |
| log-path mirror `$logdir/check/<name>.{smcl,log}` | OK (:68, :88, :134) | OK (:88, :303) | OK (:58, :170) |
| rc-clobber pattern in kept asserts | OK (:107→112) | OK (16× `local rc=_rc` then `exit \`rc'`) | see Minor M1 |

Reported brace balances (11/11, 22/22, 16/16) were not independently re-counted brace-by-brace
(no Stata parser in this critic's toolset); structural read of all three files shows no
unbalanced block. Treated as **UNVERIFIED-but-plausible**, not a deduction (consistent with
the `/*` balance which I did confirm).

### 7. Consistency — headers, ADRs, index

- Headers updated to match new behavior: check_va_estimates INVARIANTS rewritten to
  structural-only with ADR-0033 note (:43-47); check_survey_indices INVARIANTS records the
  removed/loosened items (:51-65); check_samples INVARIANTS + SOFT-SIGNALS-REMOVED block
  (:28-39, :150-158). All coherent.
- ADR-0028 Status correctly marked "Superseded in part by #0033" (ADR file :6 + README
  index :119).
- ADR-0033 present, well-formed, with Removed/Loosened/Added/Kept sections; README index
  entry :124 coherent; audit doc coherent.

---

## Compliance Evidence (from .claude/state/verification-ledger.md)

The three edited files' ledger rows are now **STALE** (file content changed since the cached
`Verified At` hashes — check_va_estimates a3df2b1db29d @2026-06-09; check_survey_indices
a17d51fe4d1a @2026-06-20; check_samples dfec994cd69b @2026-04-29). No `no-logic-change` row
exists for this edit. Because this is a **declared methodology change** (not a no-logic-change
refactor), the Tier-1 no-logic-change gate does not bind, and the absence of a `no-logic-change`
row is expected and correct — I do not deduct for it. I independently re-ran the staleness-
invalidated checks:

- check_{va_estimates,survey_indices,samples}.do | no-hardcoded-paths | 2026-06-21 | **PASS** | grep `"/Users|"/home|"C:\\` returned 0 matches
- check_{va_estimates,survey_indices,samples}.do | no-raw-data-overwrites | 2026-06-21 | **PASS** | no save/export/outsheet/esttab/graph export; only writes are `log using`/`cap translate` to `$logdir` (CANONICAL)
- check_{va_estimates,survey_indices,samples}.do | comment-balance | 2026-06-21 | **PASS** | `/*`=`*/` (4=4, 5=5, 5=5)

**Action item for the author (not a deduction):** re-stamp the nine stale ledger rows
(3 files × 3 checks) with the new hashes after commit, or they will be flagged stale on the
next adversarial pass.

---

## Findings

### Minor M1 (-3): pre-existing rc-clobber in check_samples.do is now the odd-one-out

check_samples.do fail-branches use `exit _rc` (:130, :144) with `cap log close` / `cap translate`
executing **between** `if _rc {` and `exit _rc`, so `_rc` is clobbered to 0 before the `exit` —
the exact bug `2026-06-09_check-files-rc-fix` repaired in the other two check files by inserting
`local rc = _rc` and using `exit \`rc'`. This block was **not touched by this diff** (the hard
asserts were left intact, only the SOFT SIGNALS block was removed), so it is a pre-existing
latent defect, not introduced here. But this change makes check_samples.do the only one of the
three still carrying the clobber pattern, and the file's INVARIANTS header was edited in this
same commit — a natural moment to have swept it. The race-orthogonality (:124-131) and
binary-coding (:138-146) blocks would, on a real FAIL, `exit 0` and let the pipeline print
`[OK]` and continue (the very failure mode ADR/`2026-06-09` documented). Flagging for a
follow-up; deducting lightly because it is adjacent to in-scope edited code and was a missed
sweep opportunity, not a regression.

### Minor M2 (-3): ADR-0032 Status line not annotated, though its centering half is superseded

ADR-0033 loosens the staffqoi98 source-item bound from `min ∈ [-3.01, 0]` (ADR-0032's stated
form, :18/:34/:58-59) to `min >= -3.01` (drops the `<= 0` centering half). ADR-0033 lists
ADR-0032 only under "Relates to" (:9), not "Supersedes (in part)". The staffqoi98 **floor**
(the hard part of 0032) is genuinely kept, so full supersession is not required — but the
centering half of 0032's check form IS now changed, and 0032's Status line (`Decided`,
unqualified) gives no pointer to 0033 the way ADR-0028's does. A reader of 0032 would not learn
the bound form changed. Recommend either a "Superseded in part by #0033" annotation on 0032
(mirroring the 0028 treatment) or an explicit note in 0033 that 0032's *floor* is retained but
its *centering form* is loosened. Doc-coherence nit, not a code issue.

### UNVERIFIED (no deduction): not re-run on Scribe

Per the air-gapped constraint, the three files were not executed. The structural logic,
control-flow, exit-code propagation, and mechanical balances are verified by static read; the
empirical PASS/FAIL behavior on real data is UNVERIFIED until the next Scribe run. No deduction
per the brief.

---

## Score Breakdown

- Starting: 100
- Minor M1 (pre-existing rc-clobber, missed sweep on adjacent edited file): -3
- Minor M2 (ADR-0032 status not annotated for the centering-half change): -3
- **Final: 94/100**

No Critical or Major findings. Code-strategy alignment is exact; all hard-basis checks
preserved; all heuristics removed; new structural check sound; M4-golden-master coverage
claim substantiated; mechanics clean.

## Escalation Status: None

Above the 80 hard gate. Recommend addressing M1 in a follow-up sweep (or this commit) and M2
as a one-line ADR annotation; neither blocks. Re-stamp the nine stale ledger rows post-commit.
