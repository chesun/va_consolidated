# Session-Batch Review — coder-critic

**Date:** 2026-06-01
**Reviewer:** coder-critic
**Target:** session-batch (4 groups; do/va/va_score_sib_lag.do, va_out_sib_lag.do, reg_out_va_all_fig.do, reg_out_va_dk_all_fig.do, survey_va/mattschlchar.do, .gitignore, data/raw/upstream/{README.md,.gitkeep}, py/sweep_mkdir_coverage.py, + 14 mkdir-coverage do/.doh files)
**Score:** 92/100
**Status:** Active
**Mode:** Full (Phase 1b/1c bug-fix; Execution severity = strict)
**Verdict:** PASS — commit allowed (>= 80 hard gate cleared)

`do/main.do` excluded from scope per instruction (user is making separate runtime changes).

---

## Code-Strategy Alignment: MATCH
## Sanity Checks: PASS
## Robustness: N/A (bug-fix batch, not an estimation change)

Every change is a defect repair traced to a recorded `diagnosis:` ledger row (r111 lag-drop, r601 missing-.ster gate, mattschlchar-missing-dataset, mkdir-coverage). No estimand, clustering, sample-restriction, FE, or specification change in any file. All writes target CANONICAL globals; no LEGACY-path writes introduced.

---

## Group 1 — sibling-lag r(111) fix (va_score_sib_lag.do, va_out_sib_lag.do): PASS

The diagnosis (ledger `diagnosis:r111-old1-sib-enr-not-found`) is corroborated independently:

- The four lag controls `old1_sib_enr_2year/_4year`, `old2_sib_enr_2year/_4year` are built in `do/sibling_xwalk/siblingoutxwalk.do:314-322` (the `foreach outcome in enr enr_2year enr_4year` loop renaming `<outcome>_max` → `old1_sib_<outcome>`/`old2_sib_<outcome>`) and saved to the crosswalk at `siblingoutxwalk.do:339` (`$datadir_clean/siblingxwalk/sibling_out_xwalk`).
- `do/va/helpers/macros_va.doh:270-279` defines `sib_lag1_controls` = those `old1_*` vars and `sib_lag2_controls` = those `old2_*` vars — exactly the controls the `vam ... controls(...)` calls reference.
- `merge_sib.doh:64` merges `m:1 state_student_id ... keepusing(touse* *sibling*)` — which excludes `old1_sib_enr_2year` (matches neither `touse*` nor `*sibling*`), confirming the drop.

The added merge (va_score_sib_lag.do:110-111 and 162-163; va_out_sib_lag.do:108-109 and 160-161) re-attaches exactly those four vars, keyed `m:1 state_student_id` against the same crosswalk the original `merge_sib.doh:64` uses (same key, same source). Placement is correct: after each `use score_s`/`use out_s` and before the `vam`. `keep(1 3)` + `nogen` is non-destructive (drops nothing from master, no `_merge` residue). The merge is m:1 and the crosswalk is one-row-per-student (built via `collapse ... by(state_student_id)` at siblingoutxwalk.do:215), so cardinality is sound.

Comment balance: 4 = 4 both files. No `*`-glob in the added comment prose (rephrased to "keepusing(touse, sibling)-pattern"). Diff is merge + comment only — no other logic change. Both consumers (the only two) fixed symmetrically.

**Note (informational, not a deduction):** ledger `no-logic-change` rows are `UNVERIFIED` (non-empty +11-line residue). This is the honest verdict — the change adds content beyond path swaps. Per evidence-gating §6, I did NOT issue a clean-refactor PASS on the ledger row; instead I manually inspected the residue and confirm it is the intended scoped fix, not stray logic.

## Group 2 — figure-subdir mkdir (reg_out_va_all_fig.do +14, reg_out_va_dk_all_fig.do +10): PASS

reg_out_va_all_fig.do prep block (L69-88) covers every export/saving() target: `het_reg_prior_score`, `het_reg_chars`, `het_reg_combined_panels/score_va` under `$figures_dir` (v1+v2), and `het_reg_prior_score`, `het_reg_chars` under `$output_dir/gph_files` (v1+v2). Parent-before-child throughout. Targets cross-checked against graph-export/saving() sites at L258, 274, 375, 391, 427, 444, 547, 564, 611, 624, 643, 658. Comment balance 15 = 15.

reg_out_va_dk_all_fig.do prep block (L59-74) covers the three target leaves (`het_reg_dk_prior_score` fig+gph, `het_reg_combined_panels/dk_va` fig), cross-checked against exports at L218, 237, 276. Comment balance 4 = 4.

Only `cap mkdir` lines added in both. PASS.

## Group 3 — mattschlchar vendoring (mattschlchar.do, .gitignore, README.md, .gitkeep): PASS

The filled `if clean==0` block (L131-138) is logically correct: `noi cap cp` from LEGACY `$caschls_projdir/dta/schoolchar/mattschlchar.dta` → vendored-raw, then `use $datadir_raw/upstream/mattschlchar` → `save $datadir_clean/schoolchar/mattschlchar`, which the consumption block at L154 reads. `noi cap cp` is idempotent and swallows failure if the LEGACY source is inaccessible (correct — falls through to read the already-vendored copy).

All four referenced globals defined in `do/settings.do`: `$datadir_raw` (:103), `$datadir_clean` (:102), `$caschls_projdir` (:136), `$consolidated_dir` (:92). No hardcoded absolute path in *executable* code — the one `/home/research/...msnaven...` literal (L72) is inside the permanently-dormant `clean==1` branch kept verbatim per ADR-0013 (unreachable; `clean=0`). Header INPUTS/OUTPUTS and the cp-instruction comments carry the only other `/home` literals — comments, not code.

`.gitignore` (L111-114): correct un-ignore-dir / ignore-contents / un-ignore-README+.gitkeep pattern, mirroring ADR-0008; `.dta` stays gitignored (ADR-0007, Scribe-only). README.md is a thorough path-stub (provenance table, ADR-0007/0008/0023 cross-refs, revendor command). Comment balance 2 = 2.

**Minor stylistic observation (no deduction):** the auto `noi cap cp` (L134-135) self-provisions, which makes the README's "one-time manual cp" framing belt-and-suspenders rather than strictly necessary; and L135 writes the literal `$consolidated_dir/data/raw/upstream/` where `$datadir_raw/upstream/` (used one line later at L136) would be more consistent. Both resolve identically (`$datadir_raw = $consolidated_dir/data/raw`); both are CANONICAL. Cosmetic only.

## Group 4 — mkdir-coverage sweep (14 files + detector): PASS

Independently re-traced the four highest-risk cases (not trusting the detector or the two prior reviews):

- **seccoverageanalysis.do** (nested 2-level loopvar): static parents `$output_dir/graph/svycoverage/seccoverage` at prep L65-68; `sec`year'` at L82 inside `foreach year` (L80); `sec`year'/gr`i'` at L86 inside inner `foreach i` (L85); exports at L89+ write `.../sec`year'/gr`i'/...png`. Loop scope, parent chain, ordering all correct.
- **indexregwithdemo.do** (the reported r(601)/r(693) failure site): prep L61-71 covers static parents incl. `indexbivarwithdemo`; loopvar leaf `indexbivarwithdemo/`type'` at L101 inside the `type`-loop, after the two merges (L96/99), before the regsave write at L163. Correct.
- **parentcoverageanalysis.do** (single-level loopvar): `parent`year'` at L73 inside `foreach year` (L71); export at L79 writes filename `gr`i'resprate.png` directly under `parent`year'` (no `/gr`i'/` subdir). Correct.
- **.doh fragment (k12_nsc2019_merge.doh)**: mkdir for `$datadir_clean/outcomesumstats` precedes the first real save; the earlier `save `k12'` (L56) is a genuine `tempfile` (L55) needing no dir. Correct.
- **va_scatter.do** loopvar `$figures_dir/share/va/`version'` at L139 with static parents L105-107.

No `*`-glob hazard in any Group-4 added comment (grep over `do/share/*.do` returned 0). Comment balance unchanged per ledger across all 14 (corroborated on the files opened). Detector `py/sweep_mkdir_coverage.py` is fit-for-purpose dev tooling: comment-stripping preserves line numbers, `///`-continuation joined, `covered_by_expansion` expands the FULL missing_dir over the cartesian product and requires every expansion in mkdirs (so wrong-suppression does not occur), limits honestly disclosed in the docstring. Not pipeline code.

### Cosmetic LOW (corroborating the two prior adversarial reviews) — no deduction
**va_var_explain.do:113** — `cap mkdir "$estimates_dir/va_cfr_all_`version'"` is placed *after* the `use` (L112) that reads a subdir of it, making that one mkdir redundant (the dir must already exist for the `use` to have succeeded). L114 (`/reg_out_va`) is the load-bearing one. Harmless ordering nit; code works. Not worth churning a no-logic-change file mid-M4. Agree with prior verdict: LOW, leave as-is.

---

## Compliance Evidence (from .claude/state/verification-ledger.md)

All consulted rows present and consistent with the diffs:

- do/va/va_score_sib_lag.do | no-logic-change | 2026-05-31T23:50Z | UNVERIFIED (residue = +11 merge+comment; manually adjudicated = intended fix)
- do/va/va_score_sib_lag.do | comment-balance | 2026-05-31T23:50Z | PASS (4=4)
- do/va/va_out_sib_lag.do | no-logic-change / comment-balance | 2026-05-31T23:50Z | UNVERIFIED (adjudicated) / PASS (4=4)
- do/va/reg_out_va_all_fig.do | mkdir-covers-export-targets | 2026-05-31T22:24Z | PASS (15=15)
- do/va/reg_out_va_dk_all_fig.do | mkdir-covers-export-targets | 2026-05-31T22:24Z | PASS (4=4)
- do/survey_va/mattschlchar.do | no-hardcoded-paths | 2026-06-01T00:30Z | PASS; no-logic-change | UNVERIFIED (adjudicated = correct clean==0 fill)
- data/raw/upstream/ | adr-0008-0023-vendor-convention | 2026-06-01T00:30Z | PASS
- py/sweep_mkdir_coverage.py | new-detector | 2026-06-01T02:30Z | PASS
- 14× mkdir-coverage rows | 2026-06-01T02:30Z | PASS (detector exits 0; balance unchanged)

Adversarial-default note: the three `no-logic-change` UNVERIFIED rows are correctly UNVERIFIED (non-empty residue), NOT falsely PASS. No clean-refactor PASS was issued against them; each residue was manually inspected and confirmed as the intended scoped fix. No stale-hash rows. No missing rows for in-scope files. No fabricated compliance claims in headers.

---

## Score Breakdown

- Starting: 100
- Group 1: 0 (merge correct, keyed right, placement right, symmetric, balance clean)
- Group 2: 0 (full target coverage, parent-before-child, balance clean)
- Group 3: 0 (logic correct, globals defined, no hardcoded path in executable code, gitignore/README correct)
- Group 4: 0 (independent re-trace of 4 highest-risk + detector confirms clean)
- Cosmetic LOW (va_var_explain.do:113 redundant-mkdir-after-use): **-3** (Minor — poor placement / dead-ordering; not blocking, prior reviews concur)
- Minor stylistic (Group 3 README/auto-cp redundancy + L135 literal-vs-$datadir_raw): **-5** (Minor — inconsistent style, cosmetic; resolves identically, no functional impact)
- Reproducibility / `set seed`: present (each .do sets `set seed 1984`); no deduction
- **Final: 92/100**

## Escalation Status: None (round 1, PASS)

## BLOCKING issues: NONE

## Verdict: **PASS — commit allowed** (92/100, clears 80 hard gate)
