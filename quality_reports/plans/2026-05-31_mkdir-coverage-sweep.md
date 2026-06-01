# Plan — Comprehensive sweep for the "directory not created" bug

**Date:** 2026-05-31
**Status:** EXECUTED 2026-06-01 (revised per adversarial review: lightweight detector `py/sweep_mkdir_coverage.py` built + run; 15 gaps found across 14 files [recon had found 6]; all fixed, detector exits 0. ensure_dir helper + pre-commit --check DEFERRED post-M4 per review. Reports: `quality_reports/reviews/2026-05-31_mkdir-coverage-discovery-report.md` + `..._adversarial_review.md`.)
**Author:** Claude (coder)
**Scope:** all active `do/**/*.do` + `*.doh` (excludes `do/_archive/`)

---

## 1. The bug class (what we are hunting)

Stata's `mkdir` does **not** create intermediate parents (no `-p`). A script errors
(`r(601)` "file ... could not be opened", or `r(693)`) the moment a write command —
`save`, `graph export`, `regsave using`, `esttab using`, `export excel using`, `saving()`,
`estimates save`, `translate`, `log using`, … — targets a directory that was never
`cap mkdir`'d.

This session alone it has bitten three times:

| Site | Missing dir | Fixed in |
|---|---|---|
| `reg_out_va_all_fig.do` | `figures/va_cfr_all_v*/het_reg_prior_score/` etc. | 2026-05-31 |
| `reg_out_va_dk_all_fig.do` | `het_reg_dk_prior_score/`, `het_reg_combined_panels/dk_va/` | 2026-05-31 |
| `indexregwithdemo.do:162` | `estimates/survey_va/factor/indexbivarwithdemo/` **`` `type' ``** `/` | THIS sweep |

**The dominant sub-pattern** is a write target whose directory path contains a
**loop-variable level** — e.g. `.../indexbivarwithdemo/` `` `type' `` `/file`, where
`` `type' `` ranges over `climate quality support` — but the `cap mkdir` block only creates
`.../indexbivarwithdemo` (the static prefix), never the per-value child
`.../indexbivarwithdemo/climate`, `/quality`, `/support`.

A subtler sibling: a **static** subdir that's simply deeper than the mkdir block reaches
(the figure bug — `het_reg_chars/` existed in the export path but not in the mkdir list).

**The crucial distinction the detector must get right** (false-positive guard):

- `.../indexbivarwithdemo/` `` `type' `` `/va_...`  → `` `type' `` is a **directory level** → needs `cap mkdir .../indexbivarwithdemo/` `` `type' `` inside the loop. **TRUE bug.**
- `.../indexbivarwithdemo/` `` `type' `` `_index_bivar_wdemo`  → `` `type' `` is a **filename prefix** (no trailing slash before more path) → no extra dir needed. **NOT a bug.**

Both shapes appear in the very same file (`indexregwithdemo.do` line 162 vs 217/218), so a
naïve "path contains a backtick local" grep over-reports. The detector keys on **`/` before
AND after** the loop-var token (it's a directory component), not the token alone.

---

## 2. Why a script, not greps

Reconnaissance for this plan tried to enumerate instances with `grep`/`awk` and the
backtick-local + slash logic repeatedly broke under shell quoting (zsh/bash mangle
`` `type' `` inside `grep -E` in a `for` loop). That fragility is exactly why this must be a
standalone Python file the shell never re-quotes. Precedent exists: `py/stata_sweep.py`,
`py/sweep_comments_and_logdirs.py`, `py/sweep_named_logs.py` are prior one-shot sweep tools
in this repo; this adds one more in the same mold.

---

## 3. Deliverables

### 3.1 Detector — `py/sweep_mkdir_coverage.py` (new)

A static analyzer. For each active `.do`/`.doh`:

1. **Collect write targets.** Regex over the 12 write verbs (from the active-tree
   inventory, by frequency): `save` (361), `translate` (307), `log using` (243),
   `estimates save` (132), `graph export` (126), `export` (37), `regsave using` (34),
   `esttab using` (32), `saving(` (24), `texsave using` (20), `export excel using` (7),
   `export delimited using` (2). Extract the **target path string** (the `$GLOBAL/.../...`
   token after the verb, before the comma/options/`firstrow`/whitespace-continuation).

2. **Reduce each target to its directory.** Strip the final path component (the filename,
   which may carry a `` `local' `` prefix — that's fine, filenames don't need dirs). Keep
   every **directory** component, including any that are `` `local' `` loop-var levels.

3. **Collect the `cap mkdir` set.** All `cap mkdir "..."` / `mkdir "..."` paths in the file.

4. **Flag a gap** when a target directory (or any of its parent levels below the first
   global) has **no** matching `cap mkdir`. Loop-var dir levels match only if a `cap mkdir`
   with the **same** `` `local' `` token at that position exists (so `allvaregs.do:89`
   `cap mkdir "$output_dir/dta/varegs/` `` `svyname' `` `"` correctly clears its
   per-`svyname` write).

5. **Resolve loop context** (best-effort): note which `foreach`/`forvalues` the write sits
   inside, so the fix can place the per-value `cap mkdir` at the right loop scope and the
   report can list the value set (e.g. `type ∈ {climate, quality, support}`).

6. **Emit** a report: `quality_reports/reviews/2026-05-31_mkdir-coverage-sweep-report.md`
   — one row per gap: `file:line | verb | target dir | missing mkdir level | enclosing loop |
   severity`. Severity = **HIGH** if the missing level is reached on every run (unconditional
   write), **MED** if gated behind a toggle/condition.

`--check` mode (exit 1 if any gap) for CI/pre-commit; `--report` mode writes the MD.
**The detector never edits code** — separation of detect vs fix, so the fix diff is auditable.

### 3.2 Fixes — applied per-file, reviewed in batches

For each confirmed gap, add the missing `cap mkdir` line(s), **one per level, parent
before child**, matching the established CANONICAL block style
(`* --- output-directory prep (CANONICAL) ---`). Two placement rules:

- **Static missing level** → add to the top-of-file dir-prep block (like the figure fixes).
- **Loop-var level** (`/` `` `type' `` `/`) → add `cap mkdir ".../` `` `type' `` `"` **inside
  the loop**, immediately after the loop opens (before the first write), because the value
  isn't known at top-of-file. Model: `allvaregs.do:89-91` already does this correctly — use
  it as the style template.

Guard the comment text against the `*/`-glob hazard (the `/*` hook bit us earlier this
session): never write a literal `` `x'/ `` or `*/ ` inside a `//` or `/* */` comment.

### 3.3 Optional hardening — a reusable mkdir helper (`do/helpers/ensure_dir.doh`?)

Propose (for discussion, not auto-adopt): a tiny program that emulates `mkdir -p` —

```stata
cap program drop ensure_dir
program define ensure_dir
  args path
  local parts : subinstr local path "/" " ", all
  local accum ""
  foreach p of local parts {
    local accum "`accum'/`p''"
    cap mkdir "`accum'"
  }
end
```

Then a write site becomes `ensure_dir "$estimates_dir/survey_va/factor/indexbivarwithdemo/`type'"`
— immune to this whole bug class going forward. **Trade-off:** it's a behavior-adjacent
refactor across many files (churn + golden-master parity questions mid-M4), so it is
proposed as a **post-M4** improvement, not part of this sweep. This sweep's job is to make
the existing explicit-`cap mkdir` style correct and complete.

### 3.4 Permanent guard — extend the Phase 7 data-checks

Add `do/check/check_dirs.do` (or fold into `check_logs.do`) that runs the detector's logic
at the *start* of an acceptance run as a fail-fast structural check, AND/OR wire
`py/sweep_mkdir_coverage.py --check` into the phase-1-review.md Tier-1 pre-commit checklist
(alongside the existing `/* */`-balance and log-path-mirror checks). This stops the bug from
silently returning on the next relocated/edited file.

---

## 4. Known candidate files (from this session's recon — to be confirmed by the detector)

The loop-var-dir-level heuristic surfaced **6** files; the detector will confirm/expand and
separate true gaps from already-correct ones:

| File | Status from recon |
|---|---|
| `do/survey_va/indexregwithdemo.do` | **CONFIRMED gap** — line 162 `indexbivarwithdemo/` `` `type' `` `/` not mkdir'd |
| `do/survey_va/indexhorseracewithdemo.do` | likely same pattern (sister Table 8 producer) — confirm |
| `do/data_prep/acs/clean_acs_census_tract.do` | candidate — confirm |
| `do/share/va_scatter.do` | candidate — confirm |
| `do/share/kdensity.do` | candidate — confirm |
| `do/share/svyvaregs/allvaregs.do` | **likely already-correct** — has per-`svyname` `cap mkdir` (89-91); detector should clear it |

The static-deeper-subdir variant (the figure bug shape) is NOT caught by the loop-var
heuristic, so the detector must also run the general "every target dir has a covering mkdir"
check across **all 110 active files**, not just these 6.

---

## 5. Execution order

1. **Approve this plan.**
2. Write `py/sweep_mkdir_coverage.py`; run `--report` → review the gap list with you.
3. Triage gaps (HIGH first); apply `cap mkdir` fixes file-by-file.
4. Re-run `--check` → 0 gaps. Verify `/* */` balance unchanged per file; no `*/`-glob in new comments.
5. Record in the verification ledger (`mkdir-coverage` PASS per fixed file + a `diagnosis:` row for indexregwithdemo).
6. Decide §3.3 (helper) and §3.4 (permanent guard) — adopt now vs defer post-M4.
7. coder-critic on the batch (per phase-1-review.md) → commit.

**Verification caveat:** all of this is static + code-only. Stata cannot run locally
(Scribe-only, air-gapped), so "fixed" means *the detector finds no uncovered write target*
— not a green end-to-end run. Final confirmation is the next Scribe M4 pass.

---

## 6. Scale / cost

- 110 active `.do` files; ~1,200 write commands across 12 verbs.
- Detector: minutes to write + run. Fixes: bounded by the gap count (recon suggests a
  handful of files, not dozens — most use static dirs already covered by their prep block).
- No data access needed; pure static analysis of source text.
