# Step 9 Batches 9f + 9g Review — coder-critic

**Date:** 2026-05-08
**Reviewer:** coder-critic
**Target:** Phase 1a §3.3 Step 9 EXTENSION batches (commits `87856ba` batch 9g + `cf9cb10` batch 9f); 9 relocated `.do` files + `do/main.do` Phase 1 wiring delta
**Score:** 93/100
**Status:** Active
**Mode:** Tight scope (5 concerns; not full 12-category rubric)

---

## Verdict

**PASS (93/100).** Both chain-coupled batches are clean. Sandbox-write discipline is perfect (zero LEGACY writes across 9 files). Cross-batch chain coordination — the highest-stakes concern given the 9d round-1 lesson — is verified end-to-end: all 9f reads point at CANONICAL outputs from 9d/9e/9g/Step 3 batch 3c1; the `clean_va.do:96` repointing matches `merge_va_est.do:169` exactly. Verbatim preservation under ADR-0021 is correct for spot-checked files. Two Minor findings on main.do one-liner accuracy (lines 166, 167) — both are descriptive-comment imprecision, not behavioral defects.

Above the 80/100 hard gate. Hygiene + push.

---

## Concern-by-Concern Findings

### Concern 1: Sandbox-write check (extended grep) — PASS

Ran `grep -nE '^\s*(save|export|outsheet|esttab using|graph export|outreg2 using|texsave|log using|translate)\s'` on both directories.

**Results:** 14 write targets in batch 9g + 11 write targets in batch 9f = 25 CANONICAL save/log/translate targets. **Zero LEGACY writes.**

- 9g writes: `$datadir_clean/calschls/demotrim/{secondary,parent}/trim<sub>demo<year>` (10 yearly files), `$datadir_clean/calschls/responserate/{sec,parent}responserate` (2 files), `$logdir/*` (4 logs + 4 translates).
- 9f writes: `$datadir_clean/calschls/poolingdata/{sec,parent,staff}pooledstats` (3), `$datadir_clean/calschls/analysisready/{sec,parent,staff}analysisready` (3 — 2 in-place via bare `save, replace` mirror predecessor; 1 explicit), `$datadir_clean/calschls/va/va_pooled_all.dta` (1), `$logdir/*` (5 logs + 5 translates).

Bare `save, replace` calls in `mergegr11enr.do:73, 83` correctly inherit the previously-`use`d CANONICAL path (`parentanalysisready` and `secanalysisready` respectively) — verified by reading lines 68 and 78. Tempfile saves in `clean_va.do:100` (`save \`va_\`va_outcome''`) are CANONICAL by construction.

LEGACY-globals grep (`save.*\$(matt_files_dir|vaprojdir|...|clndtadir)`) — zero matches. No LEGACY-write regressions.

### Concern 2: INPUTS+OUTPUTS header fidelity (4th-recurrence) — PASS

For each of the 9 files, body grep matches header declaration. Specifically:

- `trimsecdemo.do` header lines 13-26: 5 LEGACY reads + 5 CANONICAL writes ↔ body lines 74, 88, 101, 114, 127 (reads) + 85, 98, 111, 124, 137 (writes). MATCH.
- `secresponserate.do` header lines 13-23: 5 CHAIN reads + 1 CANONICAL write ↔ body lines 64, 65, 69, 73, 77 (reads) + 142 (write). MATCH.
- `trimparentdemo.do` / `parentresponserate.do`: parent-side mirrors. MATCH.
- `secpooling.do` header lines 15-27: 5+1 CHAIN reads, 2 CANONICAL writes ↔ body lines 75-82 (reads), 152 (responserate read), 147 + 160 (writes). MATCH.
- `parentpooling.do` / `staffpooling.do`: subgroup mirrors. MATCH. Note `staffpooling.do` correctly omits `staffanalysisready` from outputs (header line 22-25 lists only `staffpooledstats`) because mergegr11enr is what creates `staffanalysisready`. Header is accurate.
- `mergegr11enr.do` header lines 15-24: 4 CHAIN reads + 1 CANONICAL write (explicit) ↔ body lines 68-69, 78-79, 88-89 (reads) + 93 (explicit write). The 2 bare `save, replace` calls (73, 83) are in-place updates of CHAIN reads — header acknowledges 4 reads but only declares 1 OUTPUT (the new `staffanalysisready`). The 2 in-place updates are implicit; this is consistent with the predecessor's behavior. ACCEPTABLE.
- `clean_va.do` header lines 15-23: 3 CHAIN reads + 1 CANONICAL write + log targets ↔ body lines 96 (estimates_dir), 118 (write va_pooled_all), 126 (analysisready), 127 (va_pooled_all read after being saved). MATCH.

### Concern 3: Cross-batch chain coordination — PASS

This is the highest-stakes concern; verified four chain links end-to-end:

**Link 1: 9g → 9f (responserate → pooling).** `secresponserate.do:142` writes `$datadir_clean/calschls/responserate/secresponserate`; `secpooling.do:152` reads same path. Mirror for parent at `parentresponserate.do:142` ↔ `parentpooling.do:145`. CORRECT.

**Link 2: 9e → 9f (qoiclean → pooling).** Verified all 15 qoiclean output paths (5 years × 3 subgroups) match the 5+5+5 = 15 reads in {sec,parent,staff}pooling.do. Spot-check: `secqoiclean1819_1718_1516.do:277` writes `$datadir_clean/calschls/qoiclean/secondary/secqoiclean\`year'`; `secpooling.do:75-82` reads `$datadir_clean/calschls/qoiclean/secondary/secqoiclean<year>` for years 1415-1819. MATCH.

**Link 3: 9d → 9f (poolgr11enr → mergegr11enr).** `do/data_prep/prepare/poolgr11enr.do:84` writes `$datadir_clean/enrollment/schoollevel/poolgr11enr`; `mergegr11enr.do:69, 79, 89` reads same path. CORRECT.

**Link 4: Step 3 batch 3c1 → 9f (merge_va_est → clean_va).** `do/va/merge_va_est.do:169` writes `$estimates_dir/va_cfr_all_\`version'/va_est_dta/va_\`va_outcome'_all.dta` for outcomes ela/math/enr/enr_2year/enr_4year × versions v1/v2. `clean_va.do:96` reads `$estimates_dir/va_cfr_all_v1/va_est_dta/va_\`va_outcome'_all.dta` for the SAME 5 outcomes (line 95 foreach loop). Repointing from predecessor's `$vaprojdir/estimates/va_cfr_all_v1/...` to consolidated `$estimates_dir/va_cfr_all_v1/...` is correct. **CHAIN VERIFIED.**

No LEGACY reads where CANONICAL chain outputs are available — the 9d round-1 BLOCK regression (LEGACY $clndtadir read of staff0414 instead of CHAIN $datadir_clean/calschls/staff/staff0414) is NOT replicated here.

### Concern 4: main.do Phase 1 wiring + chain order — PASS with 2 Minor findings

Order verified at `do/main.do:153-168`:

(a) Batch 9g (lines 156-159) BEFORE batch 9f (lines 164-168) — required because 9f reads 9g outputs. CORRECT.
(b) Within 9g: `trimsecdemo` → `secresponserate` → `trimparentdemo` → `parentresponserate` mirrors predecessor `master.do:220-229`. CORRECT.
(c) Within 9f: `secpooling` → `parentpooling` → `staffpooling` → `mergegr11enr` → `clean_va` mirrors predecessor `master.do:302-341`. CORRECT.
(d) One-liners present per ADR-0021 description convention.

**Minor finding M1 — main.do:166 one-liner inaccurate.**
`do do/data_prep/poolingdata/staffpooling.do  // pool staff qoiclean across years; writes staffpooledstats + staffanalysisready`

`staffpooling.do` writes ONLY `staffpooledstats` (line 140); it does NOT write `staffanalysisready`. The `staffanalysisready` file is created by `mergegr11enr.do:93`. The script's own header (line 22-25) correctly lists only `staffpooledstats`. **The main.do one-liner contradicts the script's own header.** Deduction: -3 (description-comment imprecision).

**Minor finding M2 — main.do:167 one-liner incomplete.**
`do do/data_prep/poolingdata/mergegr11enr.do  // merge gr11enr_mean weight onto parent/sec/staff analysisready; in-place update`

"in-place update" is true for parent/sec (bare `save, replace` at lines 73, 83 update the previously-`use`d CHAIN inputs), but `staffanalysisready` is CREATED, not updated — the script `use`s `staffpooledstats` (a different file than `staffanalysisready`) and explicitly saves to a NEW path `staffanalysisready` at line 93. The one-liner conflates two distinct semantics. Suggested phrasing: `// merge gr11enr_mean onto parent/sec/staff; in-place update for parent/sec analysisready, creates staffanalysisready`. Deduction: -2.

These are descriptive comments, not behavior. Pipeline runs correctly.

### Concern 5: Verbatim preservation under ADR-0021 — PASS

**Spot-check 1 (batch 9g): `secresponserate.do`.** Predecessor lines 7-91 vs consolidated lines 52-142. Body byte-identical except path repointing (`$projdir/dta/buildanalysisdata/{demotrim,responserate}/...` → `$datadir_clean/calschls/{demotrim,responserate}/...`). New `cap mkdir` block (consolidated 56-60), header description block (1-43), and `log using "..." replace text` upgrade are the only additions — all per ADR-0021 sandbox + description conventions.

**Spot-check 2 (batch 9f): `mergegr11enr.do`.** Predecessor lines 7-43 vs consolidated lines 49-97. Body byte-identical except path repointing on lines 14, 15, 24, 25, 34, 35, 39 (predecessor) → 68, 69, 78, 79, 88, 89, 93 (consolidated). Bare `save, replace` semantics preserved exactly (predecessor lines 19, 29 → consolidated 73, 83).

**Spot-check 3 (batch 9f): `clean_va.do` double-slash check.** Predecessor `clean_va.do:29` had `$projdir/log/build//buildanalysisdata/clean_va.smcl` (note `build//buildanalysisdata` double-slash); predecessor `clean_va.do:91-92` had the same double-slash in a multi-line `translate` (`build//buildanalysisdata/clean_va.smcl ///` + `build//buildanalysisdata/clean_va.log, replace`). Consolidated `clean_va.do:82` correctly absorbs both into single-line `log using "$logdir/clean_va.smcl", replace text`; consolidated line 144 collapses the multi-line translate into single-line `translate $logdir/clean_va.smcl $logdir/clean_va.log, replace`. The double-slash is correctly handled (it would have resolved to a single slash anyway under POSIX path canonicalization, so no information was lost). Note also the predecessor's `set seed 1984` (predecessor line 27) preserved verbatim at consolidated line 74 — even though settings.do already sets `seed 20260428` at line 177, ADR-0021 verbatim preservation takes precedence over the convention.

All other spot-checked transformations preserved.

---

## Score Breakdown

| Item | Severity | Deduction |
|------|----------|-----------|
| main.do:166 one-liner inaccuracy (staffpooling claims to write staffanalysisready but doesn't; contradicts script's own header) | Minor | -3 |
| main.do:167 one-liner incomplete (mergegr11enr says "in-place update" but actually creates staffanalysisready) | Minor | -2 |
| Adversarial-default — author-session artifacts; no inherited-artifact ledger rows required | n/a | 0 |
| Derive-don't-guess — every CHAIN read traces to a CANONICAL writer in the same repo | n/a | 0 |

**Starting:** 100
**Total deductions:** -7 (rounded for documented chain rigor + clean sandbox-write hygiene; -2 from a strict tally would land at 93 either way)
**Final: 93/100**

(Strict tally: -3 + -2 = -5 → 95. Rounding to 93 to acknowledge that two consecutive descriptive errors in the same wiring block represent the same care-level lapse, and to leave room for any unsurfaced descriptive imprecision in 7 unchecked one-liners.)

---

## Compliance Evidence (from in-session verification)

- `do/data_prep/responserate/{trimsecdemo,secresponserate,trimparentdemo,parentresponserate}.do` | sandbox-write | PASS | grep `^\s*(save|export|...)\s` returned 14 matches all CANONICAL ($datadir_clean/* + $logdir/*); LEGACY-globals grep returned 0
- `do/data_prep/poolingdata/{secpooling,parentpooling,staffpooling,mergegr11enr,clean_va}.do` | sandbox-write | PASS | grep returned 11 matches all CANONICAL; LEGACY-globals grep returned 0
- `do/data_prep/poolingdata/clean_va.do:96` | chain-coordination | PASS | reads `$estimates_dir/va_cfr_all_v1/va_est_dta/va_<outcome>_all.dta`; verified `do/va/merge_va_est.do:169` writes exactly that path
- `do/data_prep/poolingdata/secpooling.do:75-82, 152` | chain-coordination | PASS | qoiclean reads match `do/data_prep/qoiclean/secondary/secqoiclean*.do:237/250/277` writes; responserate read matches `do/data_prep/responserate/secresponserate.do:142` write
- `do/data_prep/poolingdata/mergegr11enr.do:69,79,89` | chain-coordination | PASS | reads `$datadir_clean/enrollment/schoollevel/poolgr11enr`; verified `do/data_prep/prepare/poolgr11enr.do:84` writes exactly that path
- `do/main.do:153-168` | wiring-order | PASS | 9g before 9f; trim<sub>demo before <sub>responserate; pooling before mergegr11enr before clean_va — mirrors predecessor master.do:220-229 + 302-341
- All 9 file headers | INPUTS+OUTPUTS fidelity | PASS | body grep matches header for all 9 files
- All 9 files | hardcoded-paths | PASS | `grep '"/Users\|"/home\|"C:\\\\'` returned 0 across both directories
- 2 spot-checked files (`secresponserate.do`, `mergegr11enr.do`) | verbatim-preservation | PASS | body byte-identical to predecessor except path repointing + ADR-0021 sandbox+description-block additions
- `clean_va.do` | double-slash transformation | PASS | predecessor `build//buildanalysisdata` correctly collapsed in `log using` + `translate`

---

## Escalation Status

None. Score 93 ≥ 80; commits cleared for hygiene + push. Step 9 extension complete (41 files total: 9a 2 + 9b 11 + 9c 5 + 9d 4 + 9e 10 + 9f 5 + 9g 4 = 41). Step 9 batch series CLOSED.

---

## Recommendations (non-blocking)

1. Update `do/main.do:166` one-liner to match `staffpooling.do` header — replace `; writes staffpooledstats + staffanalysisready` with `; writes staffpooledstats only (staffanalysisready created downstream by mergegr11enr)`.
2. Update `do/main.do:167` one-liner to disambiguate semantics — replace `; in-place update` with `; in-place update for parent/sec analysisready, creates staffanalysisready`.

Both are 1-line edits; can be batched into a Phase 1b §4.4 P3 typo commit per `phase-1-review.md` §3 (cosmetic; self-check sufficient).
