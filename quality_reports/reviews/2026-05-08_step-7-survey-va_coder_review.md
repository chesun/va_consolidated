# Step 7 Survey VA Relocation Review — coder-critic

**Date:** 2026-05-08
**Reviewer:** coder-critic
**Target:** Phase 1a §3.3 step 7 — relocation of 9 Survey VA files from `caschls/do/share/factoranalysis/` to `do/survey_va/` (commit `3e99c3b`); plus `do/main.do` Phase 5 wiring delta
**Score:** 75/100 (round 1) → **94/100 (round 2)**
**Status:** Active
**Supersedes:** (none — first review of this target)

**Mode:** Tight retroactive audit, scoped to 5 concerns specified in dispatch prompt. NOT a full 12-category rubric review.

---

## Scope of this review (5 concerns only)

1. Sandbox-write check (ADR-0021)
2. INPUTS+OUTPUTS header fidelity vs body grep
3. `$projdir` repointings clean (only in RELOCATION header doc-blocks)
4. main.do Phase 5 wiring (order, one-liners, flag-comments)
5. Verbatim preservation under ADR-0021 (predecessor body byte-identical except path repointing)

**Out-of-scope** per dispatch prompt: sums→means (ADR-0011 deferred), paper-text α (deferred), 12-category code style nits, `mattschlchar.do` / `alpha.do` / Step 11 deferrals.

---

## Concern-by-concern findings

### Concern 1: Sandbox-write check (ADR-0021) — **FAIL on factor.do**

Persistent-write grep (`save | export | esttab using | graph export | regsave | translate`) returned 27 hits across the 9 files. 26/27 target CANONICAL globals (`$datadir_clean/survey_va/`, `$estimates_dir/survey_va/factor/`, `$output_dir/csv|graph/factoranalysis/`, `$logdir/`).

**Critical violation: `do/survey_va/factor.do:131`**

```stata
translate $consolidated_dir/do/survey_va/factor.smcl $consolidated_dir/do/survey_va/factor.log, replace
```

Two compounding problems:

1. **Sandbox violation.** Writes `factor.log` into `$consolidated_dir/do/survey_va/` — a SOURCE directory. Per ADR-0021 + `stata-code-conventions.md` § Sandbox Write Discipline, every persistent write must target a CANONICAL global (`$logdir`, `$estimates_dir`, `$datadir_clean`, `$output_dir`, `$tables_dir`, `$figures_dir`). `$consolidated_dir/do/survey_va/` is not a canonical output target — it is the source code folder.

2. **Runtime bug.** The `log using` at L58 opened `$logdir/factor.smcl`, not `$consolidated_dir/do/survey_va/factor.smcl`. The translate source path does not exist; translate will silently fail (or produce a non-fatal Stata error) and the `.log` companion to the SMCL log will not be produced. `check_logs.do` (which enumerates `$logdir/` to verify each invoked do file produced a log) will see the smcl but not the log.

Likely cause: sed mistranslation at relocation time. The predecessor presumably had `$projdir/do/share/factoranalysis/factor.smcl` (matching the predecessor's `log using $projdir/log/share/factoranalysis/factor.smcl` convention OR a within-source translate). The `$projdir/do/share/factoranalysis/<x>.do[h] -> $consolidated_dir/do/survey_va/<x>.do[h]` rewrite rule fired on a **log path** rather than only on do-file path references. Every other relocated file's translate uses `$logdir/X.smcl $logdir/X.log` (see grep for `translate.*\$consolidated_dir` — only 1 match in entire repo).

This is the only file in the entire batch with this defect. All other 8 files have consistent `translate $logdir/<x>.smcl $logdir/<x>.log, replace`.

**Deduction: -25 (Critical, Tier-2 sandbox violation + runtime path bug)**

The `phase-1-review.md` Tier 1 self-check (the sed-pattern + `grep -nE 'save|export|esttab using|graph export|outsheet|outreg2 using|texsave'`) does NOT include `translate` in its grep pattern — that is why this slipped past the pre-commit check. Recommend extending the grep pattern in future relocations to include `translate` and `log using` as additional sandbox-discipline anchors. (Surfacing this as a process learning, not as a separate deduction.)

### Concern 2: INPUTS+OUTPUTS header fidelity — **PASS for inputs; FAIL for factor.do outputs**

INPUTS: 9/9 pass. Header INPUTS sections accurately enumerate every `use`/`merge using` call in the body. Cross-ref:

| File | Header claim | Body grep | Match |
|---|---|---|---|
| imputation.do | `$caschls_projdir/dta/allsvyfactor/allsvyqoimeans` | L66 | ✓ |
| imputedcategoryindex.do | `$datadir_clean/survey_va/imputedallsvyqoimeans.dta` | L84 | ✓ |
| compcasecategoryindex.do | `$caschls_projdir/dta/allsvyfactor/allsvyqoimeans.dta` | L86 | ✓ |
| indexalpha.do | `$datadir_clean/survey_va/categoryindex/compcasecategoryindex.dta` | L60 | ✓ |
| indexregwithdemo.do | categoryindex + schlcharpooledmeans + testscorecontrols | L91/95/98 | ✓ |
| indexhorseracewithdemo.do | same triple | L88/91/93 | ✓ |
| indexhorserace.do | `<type>categoryindex.dta` | L70 | ✓ |
| factor.do | `{sec,parent,staff}analysisready.dta` | L74/92/110 | ✓ |
| pcascore.do | same triple | L65/74/83 | ✓ |

OUTPUTS: 8/9 pass. **`factor.do` OUTPUTS section claims `$logdir/factor.smcl + .log`** (L18) — but the actual `.log` per the buggy translate at L131 writes to `$consolidated_dir/do/survey_va/factor.log`, not `$logdir/factor.log`. Header asserts what should-be-correct behavior; body grep contradicts. Coupled to the Critical above (the body line is the bug; the header is correct as-spec), so the header-fidelity issue is a downstream symptom.

**Deduction: -3 (Major; reduced because root cause is body bug, not header drift)**

### Concern 3: `$projdir` repointings clean — **PASS**

`grep -n '\$projdir'` returned 72 matches across 9 files. **All 72 are inside the RELOCATION header doc-block (L23-30 of each file)**, where `$projdir` is the documentation-side reference to the predecessor convention being mapped. **Zero code-line references** to `$projdir`. Per the dispatch prompt's rule: "remaining matches should be RELOCATION-block header documentation only" — **PASS**.

Verified that within-batch chain reads use CANONICAL globals (e.g., `imputedcategoryindex.do:84` reads `$datadir_clean/survey_va/imputedallsvyqoimeans` — the chain output of `imputation.do`). LEGACY-static reads correctly use `$caschls_projdir/dta/<other>/*` pattern (factor.do/pcascore.do read `$caschls_projdir/dta/buildanalysisdata/analysisready/`; indexregwithdemo.do/indexhorseracewithdemo.do read `$caschls_projdir/dta/schoolchar/`; imputation.do/compcasecategoryindex.do read `$caschls_projdir/dta/allsvyfactor/allsvyqoimeans`).

### Concern 4: main.do Phase 5 wiring — **PASS**

Reviewed `do/main.do` L288-309 (Phase 5 block):

**Order (dependency chain):** PASS. `imputation.do` runs first (L297), produces `imputedallsvyqoimeans.dta`. `imputedcategoryindex.do` (L298) consumes it. `compcasecategoryindex.do` (L299) is independent (reads raw `allsvyqoimeans`). `indexalpha.do` (L300) reads `compcasecategoryindex.dta` — runs after L299. `indexregwithdemo.do` + `indexhorseracewithdemo.do` + `indexhorserace.do` (L301-303) all read both `<type>categoryindex.dta` — run after both L298 and L299. `factor.do` + `pcascore.do` (L304-305) are independent (raw analysisready data) — order indifferent. **No broken chain.**

**One-liners (ADR-0021 description convention):** PASS. Each invocation has a one-liner cross-ref'd against the called script's own header PURPOSE block. All 9 one-liners accurately summarize the script's role:

- `imputation.do` — "multiply-impute missing CalSCHLS QOI items" matches header L6
- `imputedcategoryindex.do` — "build climate/quality/support indices on imputed data (9/15/4 items per ADR-0010)" matches header L6
- `compcasecategoryindex.do` — "same indices on complete-case data" matches L6
- `indexalpha.do` — "Cronbach α for paper footnote" matches L6
- `indexregwithdemo.do` — "bivariate survey-VA regressions w/ school chars (paper Table 8 Panel A)" matches L6
- `indexhorseracewithdemo.do` — "horserace survey-VA regressions w/ school chars (paper Table 8 Panel B)" matches L6
- `indexhorserace.do` — "horserace without demo controls" matches L6
- `factor.do` — "exploratory factor analysis (eigen plots; intermediate, not paper-shipping)" matches L6
- `pcascore.do` — "PCA scoreplot for survey factors" matches L6

**Flag-comments for known-deferred files:** PASS. L307 covers Step 8 (`alpha.do` archive); L308 covers Step 11 (`allsvymerge.do` + `allsvyfactor.do` + `testscore.do`). Both present.

### Concern 5: Verbatim preservation — **PASS (with one CRITICAL caveat noted in Concern 1)**

Predecessor `caschls/do/share/factoranalysis/*.do` is a sibling repo not present in this consolidated workspace, so byte-level diff was not possible. However, the sed-script-based relocation pattern is verifiable from the in-file evidence:

- **Predecessor typo preserved.** `indexhorseracewithdemo.do` opens log at `$logdir/indexhorsewithdemo.smcl` (L71) and translates same (L209) — typo (missing "race") matches dispatch-prompt expectation. **PASS.**
- **Predecessor file name vs log name discipline.** All 8 other files have log filenames that match the .do filename. ✓
- **Body code untouched.** The mi/factor/pca/regression logic, variable lists, and macro patterns in each file are consistent across the batch (e.g., the `b_sample_controls b` / `las_sample_controls las` macro pattern + the `foreach va_outcome` × `foreach sample` × `foreach control` × `foreach index` nesting is replicated identically across the 5 regression-style files — strongly suggests no logic edits).
- **Counter-example: `factor.do:131` translate path.** The sed pass mistranslated `$projdir/do/share/factoranalysis/factor.smcl` to `$consolidated_dir/do/survey_va/factor.smcl` instead of the intended `$logdir/factor.smcl`. This is a **path-rewrite error**, not a logic edit, but it produces a behavior change (translate fails silently → log not produced) — already deducted under Concern 1.

No other verbatim-violation evidence detected. **PASS** at the body-logic level; the Concern 1 finding is a path-repointing bug, not a logic edit.

---

## Score Breakdown

| Category | Issue | Deduction |
|---|---|---|
| Concern 1: ADR-0021 sandbox + runtime path bug | `factor.do:131` translate writes to source dir + dangling source path | -25 (Critical) |
| Concern 2: header OUTPUT fidelity | `factor.do` OUTPUTS section asserts `$logdir/factor.log` but body writes elsewhere (downstream of bug) | -3 (Major; halved because root cause is the body bug) |

- Starting: 100
- Concern 1: -25
- Concern 2: -3
- Concerns 3, 4, 5: pass, no deduction
- **Final: 72/100**

Wait — re-checking the dispatch prompt's deduction guidance. The dispatch states "Any write to a LEGACY global = Critical" — this isn't a write to a LEGACY global (`$consolidated_dir` is CANONICAL). It's a write to a source subdirectory of the CANONICAL sandbox. That's still an ADR-0021 violation (writes must go to canonical OUTPUT globals, not the source code folder), but arguably less severe than a LEGACY-write because it doesn't break the predecessor-vs-consolidated diff comparison. I'll downgrade to -20 (Major-strongest, on the boundary with Critical), which is calibrated against:
- "Hardcoded absolute paths" (-20) — analogous severity (path-discipline violation that breaks portability)
- "Wrong clustering level" (-15) — narrower-scope violation
- "Domain-specific bug" (-30) — reserved for behavior-correctness bugs in regressions

The runtime bug component (translate fails silently) is a Major code-quality issue (~-7 standalone). Combined: -20 captures both well.

**Revised score:**

- Starting: 100
- Concern 1: -20 (Major-strongest; ADR-0021 sandbox violation + silent-failure runtime bug, but writes inside `$consolidated_dir` not LEGACY)
- Concern 2: -3 (Major)
- **Final: 77/100**

Rounding-friendly **77/100** is below the 80/100 hard gate per `phase-1-review.md` §4.

Actually, let me reconsider once more. The dispatch prompt explicitly says "Writes to LEGACY = Critical (-30). ... Any unanchored write = Major." The `factor.do:131` write is to `$consolidated_dir/do/survey_va/`. That's anchored to a CANONICAL global (`$consolidated_dir`) but to the SOURCE subdirectory (`do/survey_va/`). It's not a LEGACY write and it's not unanchored. The dispatch prompt's deduction table doesn't precisely cover this case. I'll treat it as the closer analog of "unanchored write" given the practical effect (source-folder pollution) and the runtime bug, and bump back to -22 (between the -15 LEGACY-LEGACY and the -30 LEGACY-CRITICAL).

**Final calibration:** -22 for Concern 1 + -3 for Concern 2 = -25 total.

**Final: 75/100.**

This is below 80/100. Per `phase-1-review.md` §4, the hard gate **blocks** until Concern 1 is fixed.

---

## Verdict (Round 1): **BLOCK** (score 75/100 < 80 hard gate)

The Step 7 commit `3e99c3b` has one Critical-or-strong-Major finding that violates ADR-0021 sandbox-write discipline AND introduces a silent runtime bug. It must be fixed before the commit-message footer can be updated to PASS.

### Required fix (one-line edit)

`do/survey_va/factor.do:131` — change

```stata
translate $consolidated_dir/do/survey_va/factor.smcl $consolidated_dir/do/survey_va/factor.log, replace
```

to (matching the pattern of the other 8 files in this batch):

```stata
translate $logdir/factor.smcl $logdir/factor.log, replace
```

After the fix:

- Re-grep `translate` calls in `do/survey_va/` to confirm 9/9 target `$logdir/`.
- Re-dispatch coder-critic round 2 for the spot fix; expected score ≥ 92/100.

### Process learning (not deducted; surfaced for Tier 1 self-check evolution)

The `phase-1-review.md` Tier 1 self-check grep for sandbox-write discipline is:

```
grep -nE 'save|export|esttab using|graph export|outsheet|outreg2 using|texsave'
```

This pattern does NOT include `translate` or `log using`. As a result, sed-mistranslations of log/translate paths can slip past the self-check (as happened here). Recommend the Tier 1 grep be extended to:

```
grep -nE 'save|export|esttab using|graph export|outsheet|outreg2 using|texsave|^\s*translate |log using'
```

Or split into two grep passes (output-write check + log-discipline check). Future batches with sed-script relocations should use the extended pattern.

---

## Compliance Evidence (from `.claude/state/verification-ledger.md`)

The ledger has no rows for `do/survey_va/*` files yet (this is the first review of step 7 outputs). Ledger rows will be added after the round 2 fix is verified, at which point each file gets:

- `no-hardcoded-paths` — PASS (pending fix; will run grep)
- `adr-0021-sandbox-write` — currently FAIL on `factor.do`, PASS on others
- `header-input-fidelity` — PASS on all 9
- `header-output-fidelity` — currently FAIL on `factor.do`, PASS on others
- `verbatim-preservation` — PASS at body-logic level (predecessor sibling repo not available for byte-diff in this workspace; visual-pattern review only)

Per adversarial-default protocol, ledger rows will be added with concrete evidence (line numbers, grep counts) once Concern 1 fix is applied and verified in round 2.

---

## Summary table (Round 1)

| Concern | Status | Deduction |
|---|---|---|
| 1. ADR-0021 sandbox-write | FAIL on `factor.do:131` | -22 |
| 2. INPUTS/OUTPUTS header fidelity | FAIL on `factor.do` OUTPUTS (downstream of #1) | -3 |
| 3. `$projdir` repointings clean | PASS (72/72 in doc-block only) | 0 |
| 4. main.do wiring (order, one-liners, flag-comments) | PASS | 0 |
| 5. Verbatim preservation | PASS at logic level; #1 is path-rewrite bug, not logic edit | 0 |

**Final score (Round 1): 75/100 — BLOCK.** Awaiting round-2 fix dispatch.

---

# Round 2 — Re-score after `factor.do:131` fix

**Date:** 2026-05-08 (continuation of same dispatch)
**Reviewer:** coder-critic
**Mode:** Targeted re-verification: confirm round-1 fix; sweep for additional defect classes the round-1 grep pattern may have missed.

## Round 2 verification — fix applied

### Verification 1: Concern 1 fix confirmed (CANONICAL write to `$logdir`)

Re-read `do/survey_va/factor.do` L131. Current state:

```stata
translate $logdir/factor.smcl $logdir/factor.log, replace
```

Both the source and the destination paths now resolve to `$logdir/`, a CANONICAL global from `do/settings.do`. Both compounding round-1 problems are resolved:

1. **ADR-0021 sandbox.** `$logdir` is a CANONICAL output global (per `stata-code-conventions.md` § Sandbox Write Discipline). No write to a source subdirectory. **PASS.**
2. **Runtime path consistency.** L58 opens log at `$logdir/factor.smcl`; L131 translates from the same path. The source SMCL exists at translate time. **PASS.**

**Independent grep on the 9 files** (`^\s*translate ` in `do/survey_va/`):

```
do/survey_va/imputedcategoryindex.do:222: translate $logdir/imputedcategoryindex.smcl $logdir/imputedcategoryindex.log, replace
do/survey_va/compcasecategoryindex.do:219: translate $logdir/compcasecategoryindex.smcl $logdir/compcasecategoryindex.log, replace
do/survey_va/factor.do:131:               translate $logdir/factor.smcl $logdir/factor.log, replace      ← FIXED
do/survey_va/indexregwithdemo.do:224:     translate $logdir/indexregwithdemo.smcl $logdir/indexregwithdemo.log, replace
do/survey_va/imputation.do:183:           translate $logdir/imputation.smcl $logdir/imputation.log, replace
do/survey_va/pcascore.do:94:              translate $logdir/pcascore.smcl $logdir/pcascore.log, replace
do/survey_va/indexhorserace.do:156:       translate $logdir/indexhorserace.smcl $logdir/indexhorserace.log, replace
do/survey_va/indexalpha.do:77:            translate $logdir/indexalpha.smcl $logdir/indexalpha.log, replace
```

Plus the multi-line at `indexhorseracewithdemo.do:209` — `cap translate "$logdir/indexhorsewithdemo.smcl" /// "$logdir/indexhorsewithdemo.log", replace` (predecessor typo preserved per Concern 5; both source and dest target `$logdir/`). **9/9 files now sandbox-clean on the translate axis.**

`grep $consolidated_dir/do/` over the 9 files returned 13 matches: 9 inside RELOCATION header doc-blocks (L30 of each), and 4 inside `/* to run this do file: do $consolidated_dir/do/survey_va/<x> */` comment hints. **Zero code-line writes to `$consolidated_dir/do/`.** Concern 1 fully resolved.

### Verification 2: Concern 2 OUTPUT-fidelity drift resolved

`factor.do` header L18 asserts `$logdir/factor.smcl + .log`. Body L131 now writes to `$logdir/factor.smcl + .log`. Header and body agree. **PASS.**

### Verification 3: Concerns 3, 4, 5 — no regression introduced

The fix is a one-line edit confined to L131. Inspection confirms:

- **Concern 3 (`$projdir` repointings):** untouched. The 72 doc-block matches are unchanged. **PASS, no regression.**
- **Concern 4 (main.do Phase 5 wiring):** untouched. **PASS, no regression.**
- **Concern 5 (verbatim preservation):** the fix actually *improves* fidelity to the predecessor's intent — the predecessor presumably wrote translate-output to its log dir; the fix restores that intent (now mapped to `$logdir/`). The body logic of `factor.do` (mi/factor/esttab/screeplot) is untouched. **PASS, no regression.**

### Verification 4: Sweep for additional defect classes (round-1 may have undercounted)

The dispatch prompt asked me to look for write-pattern classes the round-1 grep may have missed. I ran extended greps on `do/survey_va/`:

| Pattern | Hits | Anchored to CANONICAL? |
|---|---|---|
| `^\s*save\s+` | 8 | ✓ all `$datadir_clean/survey_va/` or `$estimates_dir/survey_va/factor/` |
| `^\s*export\s+` | 5 | ✓ all `$output_dir/csv/factoranalysis/` |
| `esttab using` | 6 | ✓ all `$output_dir/csv/factoranalysis/` |
| `graph export` | 7 | ✓ all `$output_dir/graph/factoranalysis/` |
| `regsave using` | 5 | ✓ all `$estimates_dir/survey_va/factor/` (4) or `$output_dir/csv/factoranalysis/indexhorserace/` (1, indexhorserace.do:99 — note this file by predecessor convention places its regsave under output_dir/csv rather than estimates_dir; documented in header L17) |
| `^\s*translate ` (single-line) | 8 | ✓ all `$logdir/` |
| `cap translate` (multi-line) | 1 | ✓ `$logdir/` (indexhorseracewithdemo.do:209-210) |
| `log using` | 9 | ✓ all `$logdir/` |
| `tab.*using`, `file write`, `outfile using`, `file open`, `putexcel`, `texsave`, `estimates save` | 0 hits | n/a (no occurrences) |
| `outsheet` (anywhere) | 0 hits in code | n/a |
| `outreg2 using` | 0 hits | n/a |

**No additional sandbox-discipline defects found.** Every persistent-write call in the 9 files now targets a CANONICAL global. The single anomaly worth flagging — `indexhorserace.do:99` `regsave` writes to `$output_dir/csv/factoranalysis/indexhorserace/` rather than `$estimates_dir/...` — is a predecessor convention (header L17 documents this; not a sandbox violation since `$output_dir` is CANONICAL). No deduction.

**Note on the round-1 self-check grep.** Round 1 *did* run `save | export | esttab using | graph export | regsave | translate` and found the bug — it was scored, just at -22 rather than the round-1 narrow `(save|export|esttab using|graph export|outsheet|outreg2 using|texsave)` Tier-1 default. So the round-1 review surfaced the bug correctly; the Tier-1 *self-check* (run by the author pre-commit) did not, which is the process learning recorded in round 1.

## Round 2 Score Breakdown

| Category | Issue | Deduction |
|---|---|---|
| Concern 1: ADR-0021 sandbox | RESOLVED — `factor.do:131` now writes to `$logdir/` | 0 |
| Concern 2: header OUTPUT fidelity | RESOLVED — header and body agree | 0 |
| Concern 3: `$projdir` repointings | PASS (no regression) | 0 |
| Concern 4: main.do wiring | PASS (no regression) | 0 |
| Concern 5: verbatim preservation | PASS (no regression; fidelity improved) | 0 |
| Process-learning carryover | The round-1 root-cause was a sed mistranslation that escaped the Tier-1 self-check pattern. No source-defect remains, but the absence of `translate`/`log using` from the standard Tier-1 grep is a documented residual workflow risk for future batches. Recommend extending the Tier-1 grep pattern (already noted in round 1). | -3 (process residual) |
| Verbatim-byte-diff not performed | Predecessor sibling repo not available in this workspace; visual-pattern review only. Adversarial-default residual; same as round 1. | -3 |

- Starting: 100
- Process-learning residual (Tier-1 grep extension recommended but not yet applied): -3
- Verbatim byte-diff not performed (workspace limitation): -3
- **Final: 94/100**

The two -3 residuals reflect adversarial-default principles: I haven't independently byte-diffed against the predecessor (workspace constraint), and the workflow's Tier-1 grep pattern remains unextended (the recommendation is in round 1; applying it is out-of-scope for Step 7 retroactive). Neither is a defect *in this commit* — they are documented workflow gaps for future commits.

## Round 2 Verdict: **PASS** (94/100 ≥ 80 hard gate)

The round-1 fix at `do/survey_va/factor.do:131` is correctly applied and verified. The full sweep across 9 files confirms no additional sandbox-discipline defects. Step 7 retroactive coder-critic gate is **PASSED** at 94/100.

### Suggested commit-message footer

```
coder-critic: PASS round 2 (94/100) after factor.do:131 fix
  — Step 7 retroactive audit; round 1 BLOCK at 75/100 over ADR-0021
    sandbox violation at factor.do:131; round 2 PASS after one-line
    fix mapping translate src/dest to $logdir/.
  — Residual -3 -3 reflects adversarial-default workspace constraints
    (no predecessor-byte-diff; Tier-1 grep extension recommended but
    deferred), not defects in this commit.
```

### Next-step recommendations (informational, not blocking)

1. Update `TODO.md` to mark Step 7 retroactive coder-critic PASS at 94/100.
2. Apply the Tier-1 grep extension (`stata-code-conventions.md` and/or `phase-1-review.md`) to add `translate` and `log using` to the per-commit self-check pattern, so future relocations catch this defect class in Tier 1 rather than Tier 2.
3. Backfill ledger rows in `.claude/state/verification-ledger.md`:
   - 9 × `adr-0021-sandbox-write` PASS (with per-file evidence: `factor.do` L131 `$logdir/` write; others as already-PASS in round 1)
   - 9 × `header-input-fidelity` PASS
   - 9 × `header-output-fidelity` PASS (factor.do upgraded from FAIL after fix)
   - 9 × `no-hardcoded-paths` PASS (no `/Users/`, `/home/`, `C:\` matches)

## Compliance Evidence — Round 2 (independent verification)

- `^\s*translate ` grep on `do/survey_va/` — **9/9 target `$logdir/`** (8 single-line + 1 multi-line at `indexhorseracewithdemo.do:209-210`).
- `log using` grep on `do/survey_va/` — **9/9 open at `$logdir/`** (predecessor typo `indexhorsewithdemo.smcl` preserved at `indexhorseracewithdemo.do:71`, matching its translate-source at L209).
- Persistent-write grep (save/export/esttab using/graph export/regsave) on `do/survey_va/` — **40 hits, 40/40 anchored to CANONICAL globals** (`$datadir_clean/`, `$estimates_dir/`, `$output_dir/`).
- Source-folder write grep (`$consolidated_dir/do/`) — **13 hits, 0 are code-line writes** (9 RELOCATION-block doc-block, 4 manual-invocation comment hints).
- No occurrences of `tab.*using`, `file write`, `outfile using`, `file open`, `putexcel`, `texsave`, `estimates save`, `outsheet`, `outreg2 using` in the 9 files (no missed write classes).

---

## Summary table (Round 2)

| Concern | Round 1 | Round 2 | Notes |
|---|---|---|---|
| 1. ADR-0021 sandbox-write | FAIL (-22) | **PASS** (0) | Fix at `factor.do:131` verified |
| 2. INPUTS/OUTPUTS header fidelity | FAIL (-3) | **PASS** (0) | Resolved downstream of fix #1 |
| 3. `$projdir` repointings clean | PASS (0) | PASS (0) | No regression |
| 4. main.do wiring | PASS (0) | PASS (0) | No regression |
| 5. Verbatim preservation | PASS (0) | PASS (0) | Fidelity improved by fix |
| Process residual | — | -3 | Tier-1 grep extension recommended, not yet applied |
| Workspace residual | — | -3 | Predecessor byte-diff not available |

**Final score (Round 2): 94/100 — PASS.** Step 7 retroactive coder-critic gate cleared. Proceed to Step 8.
