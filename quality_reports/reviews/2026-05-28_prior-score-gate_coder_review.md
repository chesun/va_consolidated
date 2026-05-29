# prior-score-gate Review — coder (ROUND 2)

**Date:** 2026-05-28
**Reviewer:** coder-critic
**Target:** `do/settings.do`, `do/va/reg_out_va_all.do`, `do/va/reg_out_va_all_tab.do`, `do/va/reg_out_va_all_fig.do`, `do/va/reg_out_va_dk_all.do`, `do/va/reg_out_va_dk_all_tab.do`, `do/va/reg_out_va_dk_all_fig.do`, `do/share/va_scatter.do` (Phase 1b §4.2 prior-score-decile gate fix — 8 files)
**Score:** 93/100
**Status:** Active
**Supersedes:** [archive/2026-05-28_prior-score-gate_coder_review_round1.md](archive/2026-05-28_prior-score-gate_coder_review_round1.md)
**Mode:** Phase 1b §4.2 paper-affecting code correction; hard gate 80/100

## Code-Strategy Alignment: MATCH
## Sanity Checks: PASS
## Robustness: Complete — both round-1 blockers closed; single-coherent-switch invariant now holds

---

## Headline

Round 1 BLOCKed at 78 on two live, paper-affecting ungated consumers (M1
`reg_out_va_dk_all_fig.do`, M2 `do/share/va_scatter.do`). **Both are now gated with the
identical `if "$run_prior_score" != "0"` construct and the same GATE note.** An
independent wide re-grep confirms the plan's central promise — a single coherent
switch — is now satisfied in **both directions**: every live reader (`est use` /
`graph use` / `graph combine`) of a `het_reg_*_x_prior_*` `.ster`/`.gph` artifact, and
every producer write of one, sits inside a `$run_prior_score` gate. Flipping the global
to `0` now disables producers and consumers together with no orphaned read → no `r(601)`.

The fix is internally clean across all 8 files: braces balance, comment contexts
balance, gates wrap only the prior-score regions (unrelated scatter/figure code
untouched), no path-glob `*` in comments, no scope creep.

---

## Verification (independent, air-gapped — read-only)

### Item 1 — M1/M2 blockers resolved

**M1 `do/va/reg_out_va_dk_all_fig.do` (NEW gate).** Gate opens `:145`
`if "$run_prior_score" != "0" {`, closes `:269` `} // end gate: $run_prior_score (DK
prior-score-decile figures + combine panels)`. It wraps BOTH the prior-score
figure-generation nest (`:146-240`) — containing the only prior-score reader
`est use ... het_reg_`outcome'_va_dk_..._x_prior_... .ster` at `:180` — AND the combine
panels block (`:247-268`) — containing `graph combine` of four `het_reg_*_x_prior_*.gph`
at `:253-257`. The non-heterogeneity scalar-assignment block (`:103-135`, reads
`reg_*` non-`x_prior` `.ster`) is correctly OUTSIDE the gate. GATE note `:141-144` uses
`<x>` path-glob placeholders.

**M2 `do/share/va_scatter.do` (NEW gate).** Gate opens `:736`
`if "$run_prior_score" != "0" {`, closes `:795` `} // end gate: $run_prior_score
(prior-score-decile scatter/panel figures)`. Wraps the entire Figure 5a/5b block
(`foreach subject` `:737-794`) — all eight `graph use ... het_reg_*_x_prior_*.gph`
readers (`:740,743,746,749,769,772,775,778`) and both `graph combine` blocks
(`:753-757`, `:782-786`). The preceding Figure 4 `foreach subject` closes at `:723`
before the gate opens; the unrelated scatter code (Figures 1–4) is untouched. GATE note
`:732-735` uses `<x>` placeholders. Scope confirmed: `grep -c run_prior_score
va_scatter.do` = 3 lines (one note, one `if`, one close) — a single gate, exactly the
Figure 5a/5b section.

### Item 2 — Completeness (the round-1 failure), independently re-grepped

`grep -rnE 'het_reg.*x_prior|x_prior.*\.(ster|gph)' do/ | grep -v _archive` classified.
After excluding `do/_archive/siblingvaregs/*` (out of scope) and
`do/check/m4_path_matrix.csv` (a data CSV, not executable code — output-path manifest
rows, not Stata reads), **every live hit lands in one of the 8 in-scope files**, and
each is now gated:

| File | Role | `x_prior` reads/writes | Inside gate? |
|---|---|---|---|
| `reg_out_va_all.do` | producer | writes `:307/318/328/398/409/420` | gate `:296`→close (verified r1) |
| `reg_out_va_all_tab.do` | consumer | `est use :403, :477` | gates `:373`→`:438`, `:449`→`:508` |
| `reg_out_va_all_fig.do` | consumer | `est use :211, :497`; `.gph` combine `:584-635` | gates `:177`→`:279`, `:464`→`:646` |
| `reg_out_va_dk_all.do` | producer | writes `:198/208/218` | gate `:187`→`:224` |
| `reg_out_va_dk_all_tab.do` | consumer | `est use :285` | gate `:258`→`:316` |
| `reg_out_va_dk_all_fig.do` | consumer (NEW) | `est use :180`; `.gph` combine `:253-257` | gate `:145`→`:269` |
| `va_scatter.do` | consumer (NEW) | `graph use ×8`; `.gph` combine ×2 | gate `:736`→`:795` |

Bidirectional coherence confirmed: the two producers (`reg_out_va_all.do`,
`reg_out_va_dk_all.do`) write `het_reg_*_x_prior_*.ster` ONLY inside their gates, so a
flip-to-0 stops production and consumption together — no half-flip possible. No live
reader or writer remains ungated.

### Item 3 — Brace / comment balance (the 2 new files)

| File | `{` / `}` | `/*` / `*/` | Gate trace |
|---|---|---|---|
| `reg_out_va_dk_all_fig.do` | 24 / 24 | 4 / 4 | gate `if` `:145` → loop nest (`foreach`×3, `forvalues`×2, `if`×4, nested `foreach prior_subject` + `forvalues`+`if`×2) closes through `:240`; combine block `:247-268`; gate `}` `:269` |
| `va_scatter.do` | 8 / 8 | 9 / 9 | gate `if` `:736` → `foreach subject` `:737` → `}` `:794` → gate `}` `:795`; two inert inline `/* title(...) */` at `:759/:788` balanced |

Each new `if "$run_prior_score" != "0" {` has exactly one matching `}` at the correct
depth; no pre-existing loop nesting broken. (The 6 round-1 files were verified
balanced in round 1 and the grep shows their gates unchanged this round.)

### Item 4 — Scope

`grep run_prior_score do/` returns exactly the expected sites across 8 files: the global
+ note in `settings.do:223,225`; the producer gates; the consumer gates; the one
`reg_out_va_all.do:8` header-comment update. The two new files add only a GATE note +
`if {` + `}` close each — no substantive logic change, no unrelated edits. The previously
noted trailing-space change (`reg_out_va_all_fig.do`) and the header-comment update were
accepted in round 1. No new out-of-scope diffs introduced.

### Item 5 — Path-glob in comments

The GATE-note lines in both new files (`reg_out_va_dk_all_fig.do:141-144`,
`va_scatter.do:732-735`) are `*`-prefixed and use `<x>` placeholders (`<x>_tab.do`,
`<x>_fig.do`) — no literal `/*` digraph, no path-glob `*`. The file headers also use
`<x>` placeholders throughout. Stata greedy-`/*`-parser bug not triggered. PASS.

---

## What changed since round 1

Two new gates, identical construct and note to the six round-1 gates. Round-1 findings
M1 and M2 are **CLOSED**. M3 (Minor) — the round-1 scope summary under-reported coverage —
is now moot: the round-2 change set explicitly covers both missed consumers and the
re-grep confirms full coverage.

---

## Score Breakdown

- Starting: 100
- M1 + M2 (round-1 BLOCK, −15): **CLOSED** — both consumers gated; re-grep confirms full
  bidirectional coverage. No deduction.
- M3 (round-1 Minor, −5): moot — coverage now complete. No deduction.
- Adversarial-default: the 6 round-1 ledger rows (2026-05-08) plus the 2 new files have no
  refreshed ledger rows for this session's gate edits. I re-verified brace + comment +
  path-glob balance and gate semantics independently above (read-only, air-gapped); the
  checks PASS. Minor deduction for absent refreshed ledger rows on the two newly-edited
  files (`no-hardcoded-paths`, brace/comment-balance not recorded post-edit): **−5**.
- Documentation-staleness (Minor): `va_scatter.do` header INPUTS block (`:20-27`) still
  tags the eight prior-score `.gph` reads `(LEGACY)` with no note that they are now
  `$run_prior_score`-gated; a successor reading the header alone won't see the gate
  dependency that the body now enforces. Same latent doc gap noted (un-deducted) in
  round 1; now that the file is in the active change set it is a fair Minor: **−2**.
- **Final: 93/100 — PASS**

## Escalation Status: None (Strike 1 cleared; round-2 PASS)

---

## Recommendations (non-blocking, do not re-dispatch)

1. After commit, refresh the verification-ledger rows for `do/va/reg_out_va_dk_all_fig.do`
   and `do/share/va_scatter.do` (and ideally all 8) with the new file hashes so the next
   reviewer doesn't inherit stale `2026-05-08` rows.
2. (Minor) Add a one-line note to the `va_scatter.do` header INPUTS block that the
   prior-score `.gph` reads are gated on `$run_prior_score` (mirrors what the body GATE
   note already documents).
3. On Scribe: re-run phase 3 (`run_va_estimation`/`run_va_tables`/figures) at the shipped
   default `$run_prior_score = 1`; confirm `het_reg_*_x_prior_*.ster` written and all
   tab/fig/share steps complete with no `r(601)`. Then, as a one-time invariant check,
   set `$run_prior_score 0` and confirm a clean full run with no `r(601)` anywhere
   (validates the flip-to-0 coherence this fix promises).

## Compliance Evidence (from .claude/state/verification-ledger.md)
- do/va/reg_out_va_all.do | no-hardcoded-paths | 2026-05-08T02:00Z | PASS — STALE (gate-only edit; re-verified independently, no new paths)
- do/va/reg_out_va_all_tab.do | no-hardcoded-paths | 2026-05-08T02:00Z | PASS — STALE; re-verified
- do/va/reg_out_va_all_fig.do | no-hardcoded-paths | 2026-05-08T02:00Z | PASS — STALE; re-verified
- do/va/reg_out_va_dk_all.do | no-hardcoded-paths | 2026-05-08T02:00Z | PASS — STALE; re-verified
- do/va/reg_out_va_dk_all_tab.do | no-hardcoded-paths | 2026-05-08T02:00Z | PASS — STALE; re-verified
- do/va/reg_out_va_dk_all_fig.do | no-hardcoded-paths | (no row this session — gate-only edit; independently verified: gates add no new paths, header repointing pre-existing)
- do/share/va_scatter.do | no-hardcoded-paths | (no row this session — gate-only edit; independently verified)
- do/settings.do | tables-figures-globals | 2026-05-08T00:30Z | PASS — STALE; config-toggle add only, no path change
