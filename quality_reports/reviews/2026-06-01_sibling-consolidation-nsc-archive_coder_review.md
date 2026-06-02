# Sibling-consolidation + NSC-archive Review — coder

**Date:** 2026-06-01
**Reviewer:** coder-critic
**Target:** do/sibling_xwalk/{siblingmatch,uniquefamily,siblingpairxwalk}.do (relocation) + do/_archive/out_of_scope/nsc_codebook.do (archive) + README
**Score:** 96/100
**Status:** Active
**Mode:** Full (Phase 1a §3.3; Execution severity)

## Verdict: PASS (hard gate 80 cleared)

Path-only relocation + descope archive. No analysis logic touched. The two parity cruxes
(data-output paths unchanged; no over-broad sed damage) both pass. Air-gapped: verified by
`git`-tree reading + grep, not by running Stata.

---

## Code-Strategy Alignment: MATCH

ADR-0026 (sibling consolidation) and ADR-0025 (nsc descope) both written this session; the
implemented diff matches each ADR's prescribed change exactly:

- ADR-0026 §Decision: move 3 files to `do/sibling_xwalk/`, repoint logs
  `$logdir/share/siblingxwalk/<name>` -> `$logdir/sibling_xwalk/<name>`, remove orphan
  `cap mkdir "$logdir/share"`, keep predecessor `Source:`/`To run` lines. All confirmed.
- ADR-0025: nsc_codebook descoped (input `nsc_2010_2017_clean` removed from Scribe, r(601)),
  body preserved verbatim with ARCHIVED note, removed from main.do Phase 6. Confirmed.

## Sanity Checks: PASS
## Robustness: N/A (mechanical relocation, no estimation)

---

## Detailed verification (per requested checklist)

### 1. Log-path mirror correctness — PASS

All 3 moved files now mirror `do/sibling_xwalk/` -> `$logdir/sibling_xwalk/`:

| File | `log using` | `translate` | `cap mkdir` |
|------|-------------|-------------|-------------|
| siblingmatch.do | L61 `$logdir/sibling_xwalk/siblingmatch.smcl` | L157 `$logdir/sibling_xwalk/...` | L55-56 `$logdir` + `$logdir/sibling_xwalk` |
| uniquefamily.do | L70 `$logdir/sibling_xwalk/uniquefamily.smcl` | L132 `$logdir/sibling_xwalk/...` | L61-62 `$logdir` + `$logdir/sibling_xwalk` |
| siblingpairxwalk.do | L64 `$logdir/sibling_xwalk/siblingpairxwalk.smcl` | L131 `$logdir/sibling_xwalk/...` | L58-59 `$logdir` + `$logdir/sibling_xwalk` |

- `grep '$logdir/share'` on `do/sibling_xwalk/` returns **0 matches** — no leftover old log
  path, no orphan `cap mkdir "$logdir/share"`.
- `check_logs.do` computes expected log path from each file's reldir under `do/` (L77 excludes
  `_archive`). Expected `$logdir/sibling_xwalk/<name>.smcl` == what each file opens -> these 3
  will PASS check_logs.do on the next Scribe run.

### 2. Data-output paths UNCHANGED — PASS (parity crux)

Every `.dta` save/use still targets `$datadir_clean/siblingxwalk/` (the *data* global +
directory name `siblingxwalk`, which is **unchanged** — only the log global moved):

- siblingmatch.do: saves `$datadir_clean/siblingxwalk/k12_xwalk_name_address{,_year}` (L117, L153)
- uniquefamily.do: reads `.../k12_xwalk_name_address_year` (L72); saves
  `.../{uniquelinkedfamilyraw, uniquelinkedfamilyclean, ufamilyxwalk}` (L89, L104, L128);
  graph -> `$output_dir/graph/siblingxwalk/numsiblingdist.png` (L103) — also unchanged
- siblingpairxwalk.do: reads `.../uniquelinkedfamilyclean` (L66, L85), `.../siblingpairxwalk`
  (L102); saves `.../siblingpairxwalk` (L95), `.../uniquesiblingpairxwalk` (L127)

The sed repoint touched only `$logdir/share/siblingxwalk` -> `$logdir/sibling_xwalk`. The data
directory name `siblingxwalk` was correctly NOT flattened to `sibling_xwalk`. Golden-master
data parity preserved.

### 3. No over-broad sed damage — PASS (parity crux)

Classified every `siblingxwalk` occurrence in the 3 moved files (grep -n):

- **Data paths** `$datadir_clean/siblingxwalk/...` — UNTOUCHED (different global, dir name kept). Correct.
- **Log paths** — all now `$logdir/sibling_xwalk/` (the intended change). Correct.
- **Header/comment prose** (`Source: caschls/do/share/siblingxwalk/...`, `Sister files:` lists,
  the kept "To run" line) — left intact per spec.

No accidental `$datadir_clean/sibling_xwalk` (would have been a bug); no var-name/comment
collateral. The sed was scoped to the log substring only.

### 4. Comment / brace balance — PASS

`/* ` vs ` */` counts (equal in each; bodies visibly intact, no runaway comment swallowing code):

| File | `/*` | `*/` |
|------|------|------|
| siblingmatch.do | 12 | 12 |
| uniquefamily.do | 10 | 10 |
| siblingpairxwalk.do | 4 | 4 |

No path-glob `*` inside any comment context in the moved files (the `prepare/*`-class greedy-parser
bug is absent). Air-gapped caveat: I used grep-count + manual read rather than the
`stata_sweep.py --check` state machine (cannot run); counts are equal and the V7-banner/string-`/*`
false-positive classes are not present here, so the balance is genuine.

### 5. NSC archive integrity — PASS

- Body below the ARCHIVED note (L12-85) is the relocated predecessor file verbatim — header
  block (L12-53) + original code (L56-85) present, not truncated. Spot-checked the executable
  tail (`use ... clear` / `log using` / `codebook` / `log close`) is intact.
- ARCHIVED note (L2-10) claims — input removed (r(601) on `nsc_2010_2017_clean`), descoped by
  PI, diagnostic-only / not paper-shipping, no downstream consumer, removed from main.do Phase 6
  — all consistent with ADR-0025 and the README.
- The archived file's own internal log paths still use `$logdir/share/outcomesumstats/` — this is
  **correct**: `check_logs.do` excludes `do/_archive/` (L77), so the file is exempt from the
  mirror convention, and it is non-runnable anyway. Not repointing it is the right call.
- `k12_nsc2019_merge.doh` (the DIFFERENT helper) correctly NOT touched — still at
  `do/share/outcomesumstats/nsc2019new/`.

### 6. Inter-file references — PASS (with 2 minor cosmetic notes)

`do/share/siblingxwalk/` is empty/removed (glob: no files). No ACTIVE file (excl main.do, excl
_archive) executably references the old paths. Remaining matches are all non-executable:

- "Sister files:"/"txt-format log destination for nsc_codebook" lines in `allvaregs.do`,
  `mattschlchar.do`, `k12_nsc2019_merge.doh` — documentation prose inside relocation-header
  comment blocks; not `do`/`include` calls. Out of this change set's scope (those files weren't
  edited here).
- `do/main.do:991,994` — EXCLUDED from review (user owns). Both are commented/RETIRED annotations
  that already reference the new locations correctly.

---

## Deductions

| Severity | Issue | Deduction |
|----------|-------|-----------|
| Minor | `uniquefamily.do:55` predecessor "To run" line still reads `do $projdir/do/share/siblingxwalk/uniquefamily.do` — a now-nonexistent path. Kept intentionally per spec/ADR-0026 as historical record, but inside a `/* */` it could mislead a reader. Cosmetic. | -2 |
| Minor | "Sister files:" header lists in the 3 moved files (+ untouched siblings) still name `nsc_codebook.do` as a batch sibling without noting it is now archived/descoped. Stale-but-harmless documentation drift introduced by the parallel ADR-0025 archive. Not load-bearing. | -2 |

Both are documentation-only; neither affects execution, data outputs, or check_logs.do.

## Score Breakdown
- Starting: 100
- Minor: stale predecessor "To run" path in comment: -2
- Minor: "Sister files" lists not updated for nsc_codebook archive: -2
- **Final: 96/100**

## Compliance Evidence (from .claude/state/verification-ledger.md)
- do/sibling_xwalk/siblingmatch.do | log-mirror | (no row — new relocation this session; verified inline above, recommend appending PASS)
- do/sibling_xwalk/uniquefamily.do | log-mirror | (no row — verified inline)
- do/sibling_xwalk/siblingpairxwalk.do | log-mirror | (no row — verified inline)
- do/sibling_xwalk/* | data-output-paths-unchanged | (no row — verified inline, PASS)
- Note: ledger has no prior rows for these paths; expected since the files were relocated this
  session. No stale/FAIL rows to flag.

## Air-gapped honesty
Could not run Stata (Scribe-only, no data access locally). All verdicts derive from reading the
relocated/archived files, the two ADRs, README, check_logs.do exclusion logic, and grep over the
`do/` tree. The behavioral parity claim (data outputs identical) is verified at the *source* level
(save/use targets unchanged) — the empirical golden-master confirmation is the next Scribe run, as
ADR-0026 §Note states.

## Escalation Status: None (round 1 PASS)
