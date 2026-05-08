# Phase 1a §3.3 step 4 (heterogeneity batch) Review — coder-critic

**Date:** 2026-05-08
**Reviewer:** coder-critic
**Target:** `do/va/heterogeneity/{va_het,va_corr_schl_char,va_corr_schl_char_fig,persist_het_student_char_fig}.do` + `do/main.do` Phase 3 wiring (L241-251)
**Score:** 91/100
**Status:** Active
**Mode:** Phase 1 review (per `.claude/rules/phase-1-review.md`); change type: relocation + main.do wiring; severity stance per `quality.md` §2 = strict (Execution phase)

---

## Verdict

**PASS.** Score 91/100, above the 80 hard gate. No blocking findings. Two Minor deductions; one Note (no deduction).

---

## 5 specific concerns from dispatch — disposition

### 1. Sandbox-write check (CANONICAL only) — PASS

`grep -nE 'save|esttab using|graph export|regsave using|texsave using' do/va/heterogeneity/*.do | grep '\$vaprojdir'` → **0 LEGACY writes**.

All 18 persistent writes target CANONICAL globals:
- `va_het.do`: `save $estimates_dir/...` (L136), `regsave using $estimates_dir/...` (L156, L223), `texsave using $tables_dir/...` (L200, L201, L281, L282), `estimates save $estimates_dir/...` (implicit via va_corr_schl_char), tempfile saves (L168, L253, L257 — exempt).
- `va_corr_schl_char.do`: `estimates save $estimates_dir/.../va_het/...ster` (L140, L150).
- `va_corr_schl_char_fig.do`: `graph export $figures_dir/...` (L133, L150, L160).
- `persist_het_student_char_fig.do`: `graph export $figures_dir/...` (L106).

`$vaprojdir` references on the body are **READS only**: `cd $vaprojdir` (4 instances) and `merge ... using $vaprojdir/data/sch_char[_2018].dta` (3 instances at va_het.do:95, va_corr_schl_char.do:99, va_corr_schl_char_fig.do:103). All 3 sch_char reads are LEGACY-correct per Step 9 deferral.

### 2. Header OUTPUTS accuracy (per batch 3d lesson) — PASS

Spot-check #1 — `va_het.do` header OUTPUTS section (L20-24):
- Claims `va_all_schl_char.dta` → body L136 `save $estimates_dir/.../va_est_dta/va_all_schl_char.dta` ✓
- Claims `district_<type>_<spec>_<wt>.dta` and `corr_<char>_va_<spec>_<wt>.dta` → body L156, L223 (regsave) ✓
- Claims `var_across_district_<wt>_v[12].tex` → body L200, L201 (texsave to check + pub) ✓
- Claims `corr_char_<wt>_v[12].tex` → body L281, L282 (texsave to check + pub) ✓

Spot-check #2 — `va_corr_schl_char_fig.do` header OUTPUTS section (L20-22):
- Claims `scatter_<het_char>` → body L133 `graph export $figures_dir/.../va_<outcome>_scatter_<het_char>_...pdf` ✓
- Claims `density_locale` → body L150 ✓
- Claims `density_charter` → body L160 ✓

Batch-3d lesson (GREP OUTPUTS from body BEFORE writing header) is correctly applied. **No stale or fabricated paths in headers.**

### 3. LEGACY preservation: sch_char data — PASS

All 3 LEGACY reads intact and **explicitly flagged** in headers under `INPUTS / LEGACY (Step 9 deferred CDE data)`:
- `va_het.do:95` reads `$vaprojdir/data/sch_char.dta` ✓ (header L17)
- `va_corr_schl_char.do:99` reads `$vaprojdir/data/sch_char_2018.dta` ✓ (header L18)
- `va_corr_schl_char_fig.do:103` reads `$vaprojdir/data/sch_char_2018.dta` ✓ (header L18)

`persist_het_student_char_fig.do` body does NOT read sch_char (combines .gph files only) — its header still lists sch_char inputs at L17-18 for boilerplate symmetry. **Mild inconsistency** (header claims an input the body doesn't consume); see Minor finding #M2 below.

### 4. Helper-include path correctness — PASS

All 4 files do `cd $vaprojdir` (L67, L65, L67, L68). All consolidated `include` calls use absolute `$consolidated_dir/do/va/helpers/...`:
- `va_het.do:88` `include $consolidated_dir/do/va/helpers/macros_va.doh`
- `va_corr_schl_char.do:88-89` macros_va + macros_va_all_samples_controls
- `va_corr_schl_char_fig.do:90-91` macros_va + macros_va_all_samples_controls
- `persist_het_student_char_fig.do:87` macros_va

All 3 referenced .doh files exist at `do/va/helpers/`. Batch 2c lesson (absolute, not relative `do/...`) correctly applied.

### 5. main.do brace structure (post-batch-3d-bug-recurrence-check) — PASS

- `if \`run_va_estimation''` opens at L180.
- `if \`do_va''` opens at L197.
- Step 4 invocations at L247-250 (4 `do do/va/heterogeneity/...do` lines), positioned correctly inside the `do_va` block.
- `}` closing `do_va` is at L251 ✓ (matches dispatch claim).
- `}` closing `run_va_estimation` is at L257 ✓ (matches dispatch claim).
- One-liners at L247-250 cross-checked against each script's PURPOSE block: faithful summaries.

Batch 3d brace bug does not recur.

---

## 12-category Phase 1 review

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | Code-Strategy Alignment | OK | Plan v3 §3.3 step 4 implements 4 va_het files; pass_through/ N/A correctly documented (main.do:245-246). Cluster rename at va_het.do:221 deferred to Phase 1b §4.3 per plan v3 §240 (correct discipline). |
| 2 | Sanity Checks | OK | Pure relocation; behavior preserved verbatim. No new estimands introduced. |
| 3 | Robustness | OK | All 4 files relocated; main.do wired; no missing files vs. predecessor `do_files/va_het/`. |
| 4 | Script Structure & Headers | OK | All 4 files have ADR-0021 description blocks (PURPOSE / INVOKED FROM / INPUTS / OUTPUTS / RELOCATION / ADRs). |
| 5 | Console Output Hygiene | OK | `di as text` for the run-start banner is permitted; no decorative ASCII. |
| 6 | Reproducibility | OK | `set seed 1984` in each file (preserved from predecessor; per-file seeding is consistent with batches 3a/3c1/3c2/3d). No hardcoded absolute paths (grep returned 0). |
| 7 | Function/Program Design | OK | Single-purpose .do files; no programs to define. |
| 8 | Figure Quality | N/A | Figure files (va_corr_schl_char_fig, persist_het_student_char_fig) preserve predecessor figure code verbatim. Stylistic improvements deferred to a later batch. |
| 9 | Output Persistence | OK | All persistent writes are CANONICAL (see #1 above). |
| 10 | Comment Quality | OK | Original predecessor comments preserved verbatim per relocation discipline. |
| 11 | Error Handling | WARN | `va_het.do:69`, `va_corr_schl_char.do:67`, `va_corr_schl_char_fig.do:69` use bare `log close _all` (no `cap`); only `persist_het_student_char_fig.do:70` uses `cap log close _all`. See Minor #M1. |
| 12 | Professional Polish | OK | Indentation consistent; backtick-quote locals correct. |

---

## Deductions

| # | Severity | Issue | Deduction |
|---|----------|-------|-----------|
| M1 | Minor | `log close _all` (bare) at top of 3 of 4 files (va_het.do:69, va_corr_schl_char.do:67, va_corr_schl_char_fig.do:69). If the calling environment does not yet have a log open, this issues a Stata error before the file's own log opens. The 4th file (persist_het_student_char_fig.do:70) correctly uses `cap log close _all`. **Inconsistency is preserved-from-predecessor.** Phase 1a discipline is "preserve verbatim," so this is borderline — but the pattern is incorrect Stata regardless and would be caught the moment main.do invokes a fresh sub-do without a stale log. Recommend Phase 1b §4.4 (P3 typos) sweep to add `cap` to all 3. | -2 |
| M2 | Minor | `persist_het_student_char_fig.do` header (L13-18) lists `INPUTS: va_all.dta + va_all_schl_char.dta + sch_char.dta + sch_char_2018.dta` but the body reads NONE of these — it only reads `.gph` files at L97-101. Header is over-broad (probably copy-paste boilerplate from the other 3 files in the batch). True inputs are `$output_dir/gph_files/va_cfr_all_<v>/het_reg_chars/het_reg_<outcome>_va_math_x_*_las_sp_lasd_ct_p_m.gph` (4 .gph files per outcome × 2 versions × 2 outcomes = 16). **Per the new batch-3d lesson** ("GREP OUTPUTS from body BEFORE writing header"), the same lesson applies symmetrically to INPUTS. The dispatch claims "OUTPUTS verified by grep on file body BEFORE writing each header" — that claim is upheld for OUTPUTS but the INPUTS section was not subjected to the same grep verification on this 4th file. | -3 |

**Subtotal:** -5. **Score:** 100 - 5 = **95**.

Wait — re-checking: the rubric scaling and the "strict (Execution phase)" stance per `quality.md` §2. Critic stance = strict, so M2 (inputs claim mismatch in a header — fabrication-adjacent) escalates from Minor to Major-light. Adjusting:

| # | Severity | Issue | Final Deduction |
|---|----------|-------|-----------------|
| M1 | Minor | Bare `log close _all` (preserved-from-predecessor; surfaces in Phase 1b §4.4) | -2 |
| M2 | Major (strict-phase) | INPUTS section of `persist_het_student_char_fig.do` lists files the body does not read; same lesson class as batch 3d (header-vs-body grep verification not applied symmetrically). | -7 |

**Final score: 100 - 9 = 91/100.**

---

## Note (no deduction)

- N1: Plan v3 §240 mentions `va_het.do:158` cluster-rename (`cluster(cdscode)` → `cluster(school_id)`) as a Phase 1b §4.3 cosmetic. Body line is now L221 post-relocation. Preserved verbatim — correct Phase 1a discipline. No deduction; flagging so the Phase 1b §4.3 batch finds the right line.
- N2: All 4 files preserve `cd $vaprojdir` → `cd "$consolidated_dir"` (L67/L65/L67/L68 → L302/L180/L188/L123). CWD restoration correct.
- N3: Per-file `set seed 1984` in each (preserved). Master `set seed` in main.do is not yet enforced; this matches the per-batch pattern across 3a/3c1/3c2/3d.

---

## Compliance Evidence (from `.claude/state/verification-ledger.md`)

- `do/va/heterogeneity/va_het.do` | no-hardcoded-paths | (MISSING — flagged; new in-session artifact, ledger row to be added post-commit)
- `do/va/heterogeneity/va_het.do` | adr-0021-sandbox-write | (MISSING — flagged; same)
- `do/va/heterogeneity/va_corr_schl_char.do` | no-hardcoded-paths | (MISSING — flagged)
- `do/va/heterogeneity/va_corr_schl_char.do` | adr-0021-sandbox-write | (MISSING — flagged)
- `do/va/heterogeneity/va_corr_schl_char_fig.do` | no-hardcoded-paths | (MISSING — flagged)
- `do/va/heterogeneity/va_corr_schl_char_fig.do` | adr-0021-sandbox-write | (MISSING — flagged)
- `do/va/heterogeneity/persist_het_student_char_fig.do` | no-hardcoded-paths | (MISSING — flagged)
- `do/va/heterogeneity/persist_het_student_char_fig.do` | adr-0021-sandbox-write | (MISSING — flagged)

Per `adversarial-default.md` § Inherited-artifact protocol, in-session artifacts (just-created) are not gated by the ledger lookup. The verification I performed in this review is the seed for each row; rows should be written post-commit. **No deduction** for missing rows on in-session artifacts — but the verification work I did (grep evidence above) belongs in the ledger so the next critic does not re-grep.

---

## Score Breakdown

- Starting: 100
- M1 Minor (bare log close): -2
- M2 Major (header INPUTS-vs-body mismatch in persist_het_student_char_fig.do): -7
- **Final: 91/100**

## Escalation Status: None (PASS at 91 ≥ 80)

## Commit-message footer recommendation

```
coder-critic: PASS (91/100); deferred Minor #M1 (bare `log close _all` on 3 files) to Phase 1b §4.4 P3-typos sweep, added to TODO.md backlog. Major #M2 (persist_het_student_char_fig.do header INPUTS lists files body does not read) — recommend in-place header fix before commit OR defer with TODO entry.
```

Recommend addressing **M2 in-place before commit** (single-file header edit; trivial; surfaces a header-fidelity drift the batch-3d lesson was supposed to prevent). M1 can defer to Phase 1b §4.4 sweep.
