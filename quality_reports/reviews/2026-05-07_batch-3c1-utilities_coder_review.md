# Batch 3c1 (utilities) Review — coder-critic
**Date:** 2026-05-07
**Reviewer:** coder-critic
**Target:** `do/va/{merge_va_est,va_corr,prior_decile_original_sample}.do` + `do/main.do` Phase 3 batch 3c1 wiring
**Score:** 96/100
**Status:** Active

---

## Verdict: PASS — clears 80/100 commit gate.

Phase 1a §3.3 step 3 batch 3c1: relocation of 3 utility `.do` files from `cde_va_project_fork/do_files/sbac/` to `do/va/` plus main.do Phase 3 wiring.

## Code-Strategy Alignment: MATCH
ADR-0004 (canonical pipeline), ADR-0005 ($projdir alias-before-include precedent), ADR-0009 (v1 canonical), ADR-0021 (do/ relocation; sandbox; description convention) — all observed.

## Sanity Checks: PASS
Predecessor logic preserved verbatim; only path repointing applied per ADR-0021.

## Robustness: Complete
All 5 specific concerns verified, with grep + file-line evidence.

---

## 5 Specific Concerns — Verification

### 1. Sandbox-write check — PASS
- `merge_va_est.do`: 2 `save` lines, both targeting `$estimates_dir/...`:
  - L169 per-outcome save (inside `va_outcome` loop → 5 outputs × 2 versions = 10 actual writes per run; "5 per-outcome" claim in your prompt was the loop count, the static call sites are 2)
  - L178 super-master save (inside `version` loop → 2 actual writes per run)
- `va_corr.do`: 0 saves. Diagnostic-only; correlation matrix to log. ✓
- `prior_decile_original_sample.do`: 2 saves, both `$datadir_clean/sbac/...` (CANONICAL — was LEGACY `$vaprojdir/data/sbac/...` in predecessor):
  - L213 `prior_decile_original_sample.dta`
  - L224 `census_income_decile_a_sample.dta`
- All sandbox-clean per ADR-0021. **Note:** prompt counted 7 saves for merge_va_est; the predecessor at `cde_va_project_fork/do_files/sbac/merge_va_est.do:82,91` has the same 2 distinct save sites — the inflation in the prompt may have been a misread of loop iteration counts as static call sites.

### 2. `$projdir` alias-before-include in `prior_decile_original_sample.do` — PASS
- L152: `global projdir "$caschls_projdir"`
- L155: `include $caschls_projdir/do/share/siblingvaregs/vafilemacros.doh` (explicitly named global, not `$projdir`)
- Matches `do/sibling_xwalk/siblingoutxwalk.do` precedent at L162/L164 exactly.
- Header (L64-69) documents the rationale + cites the [LEARN:stata] 2026-04-30 + ADR-0005.

### 3. Predecessor latent bug preserved — PASS
- `va_corr.do:155` retains `di "End date time: \`date2' \`time2'"` where `date2` is never set (only `time2` at L152).
- Verified against predecessor `cde_va_project_fork/do_files/sbac/va_corr.do:79-82` — identical structure (predecessor sets `local time2` at L79 only, references `\`date2''` at L82).
- Header L46-48 explicitly documents this as PREDECESSOR LATENT BUG and notes Phase 1b naming/clarity may resolve.

### 4. Helper-include absolute paths — PASS
Grep `^[ \t]*include[ \t]+\$consolidated_dir/do/va/helpers` returns exactly 4 matches:
- `do/va/merge_va_est.do:128` `macros_va.doh`
- `do/va/merge_va_est.do:130` `macros_va_all_samples_controls.doh`
- `do/va/va_corr.do:107` `macros_va.doh`
- `do/va/prior_decile_original_sample.do:158` `macros_va.doh`

All 4 absolute under `$consolidated_dir`. Matches batch 2c convention.

### 5. `_str` locals actually defined in `macros_va.doh` — PASS
Grep `local ela_str|local math_str|local enr_str|local enr_2year_str|local enr_4year_str` returns:
- `do/va/helpers/macros_va.doh:150` `local ela_str`
- `do/va/helpers/macros_va.doh:153` `local math_str`
- `do/va/helpers/macros_va.doh:157` `local enr_str`
- `do/va/helpers/macros_va.doh:160` `local enr_2year_str`
- `do/va/helpers/macros_va.doh:163` `local enr_4year_str`

5/5 confirmed at predicted lines. Claim in `va_corr.do` header L50-52 is not fabricated.

---

## 12-category check (Code Quality)

| Category | Status | Notes |
|---|---|---|
| 1. Code-strategy alignment | OK | All 4 ADRs (0004/0005/0009/0021) cited and observed |
| 2. Sanity checks | OK | Predecessor logic preserved verbatim |
| 3. Robustness | OK | All 5 specific concerns verified |
| 4. Script structure & headers | OK | Full ADR-0021 header in all 3 files |
| 5. Console output hygiene | OK | Stata `di` is appropriate; no spurious banners |
| 6. Reproducibility | OK | `set seed 1984` in merge_va_est + va_corr; relative paths via globals only |
| 7. Function/program design | OK | No new programs; preserves predecessor pattern |
| 8. Figure quality | N/A | No figures produced |
| 9. Output persistence | OK | All `save` calls target CANONICAL globals |
| 10. Comment quality | WARN | `prior_decile_original_sample.do:170-187` retains 17-line commented-out predecessor block. Verbatim per ADR-0021; header L75-79 flags it for Phase 1b. |
| 11. Error handling | OK | `cap log close _all` + `cap mkdir` patterns observed |
| 12. Professional polish | WARN | merge_va_est.do uses `date1_va_scatter_plot`/`time1_va_scatter_plot` locals (predecessor naming kept verbatim) while va_corr.do uses `date1`/`time1`. Style inconsistency mirrors predecessor — not a real deviation. |

---

## main.do wiring (L213-220)

- L213-217 comment block: explains batch 3c1 + dependency (consumed by batch 3c2 reg files).
- L218 `do do/va/merge_va_est.do` + one-liner: matches script header L4-21 PURPOSE.
- L219 `do do/va/va_corr.do` + one-liner: matches script header L5-14.
- L220 `do do/va/prior_decile_original_sample.do` + one-liner: matches script header L4-20.
- All 3 gated under `if \`do_va''` (L197) per run-once-cached pattern.
- L223-228 TODO block lists batch 3c2 + 3c1 (slight redundancy: 3c1 files re-listed in TODO; minor — they're now invoked above so the TODO listing is dead reminder text. Acceptable.)

---

## Score Breakdown

- Starting: 100
- Comment quality: dead-comment block in prior_decile_original_sample.do (verbatim per ADR-0021, but acknowledged tradeoff): −2
- Professional polish: style inconsistency in local naming (merge_va_est vs va_corr; mirrored from predecessor): −2
- **Final: 96/100**

## Compliance Evidence (verification-ledger.md)

- `do/va/merge_va_est.do` | all checks | (NEW FILE — ledger row absence expected; authored in-session)
- `do/va/va_corr.do` | all checks | (NEW FILE — ledger row absence expected; authored in-session)
- `do/va/prior_decile_original_sample.do` | all checks | (NEW FILE — ledger row absence expected; authored in-session)

No deductions: per `adversarial-default.md` § Critic enforcement, "Major: Required ledger row missing for an inherited script (not authored in-session)" applies only to inherited code. These were authored in-session.

## Derive-don't-guess audit

All globals (`$consolidated_dir`, `$estimates_dir`, `$datadir_clean`, `$logdir`, `$caschls_projdir`, `$vaprojdir`) verified defined in `do/settings.do` (L92, L97, L99, L102, L128, L136). No fabrication. Predecessor sources at `cde_va_project_fork/do_files/sbac/{merge_va_est,va_corr,prior_decile_original_sample}.do` confirmed to exist and to match relocated logic verbatim except for path repointing.

## Escalation Status: None

## Commit-message footer (suggested)

```
coder-critic: PASS (96/100) — batch 3c1 (3 utility .do files relocated; sandbox-clean; $projdir alias-before-include verified; _str locals confirmed at macros_va.doh:150/153/157/160/163; predecessor latent bug preserved with header flag).
```
