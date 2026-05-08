# Step 9 batch 9b Review — coder

**Date:** 2026-05-08
**Reviewer:** coder-critic
**Target:** Phase 1a §3.3 step 9 batch 9b (commit `40cb161` — 11 school-characteristics files in `do/data_prep/schl_chars/` + `do/main.do` Phase 1 wiring delta)
**Score:** 92/100
**Status:** Active
**Mode:** Phase 1 §3.3 active relocation, strict severity per `phase-1-review.md` §3, tight 5-concern scope per dispatch instruction

---

## Code-Strategy Alignment: MATCH

The relocation implements plan v3 §3.3 step 9 batch 9b and ADR-0021 (sandbox + description convention). The 11 files land at the destination prescribed by the plan, and `do/main.do` wires them into Phase 1 in the chain order matching predecessor `cde_va_project_fork/do_files/do_all.do:75-97`. All path repointings, helper-include relocation, and log convention upgrades follow the methodology established by Steps 7-8 and prior batches.

## Sanity Checks: PASS

- 11 files present at `do/data_prep/schl_chars/` (verified via Glob)
- main.do invokes all 11 in chain order on lines 114-124 with one-liner descriptions
- All persistent-data writes target CANONICAL `$datadir_clean/...` (with one Major exception flagged below)
- LEGACY raw reads correctly preserved as `$vaprojdir/data/public_access/raw/...`
- LEGACY restricted-clean read in `clean_ecn_disadv.do` correctly preserved
- Helper include path correctly repointed to `$consolidated_dir/do/va/helpers/macros_va.doh`; the helper exists at that path and defines the `test_score_min_year`/`test_score_max_year` locals consumed by the year-loops
- Chain dependencies verified: `clean_sch_char.do` (line 124, master) reads `$datadir_clean/cde/charter_status.dta` (produced by line 122), `$datadir_clean/cde/ecn_disadv.dta` (line 123), and `$datadir_clean/nces/pubschls_locale.dta` (line 115) — all produced earlier in the chain

## Robustness: N/A (relocation, not estimation)

---

## 5-concern findings

### Concern 1 — Sandbox-write check: WARN (1 Major + 1 acceptable-verbatim)

**Major finding (-5): `clean_sch_char.do:609` relative-path write missed by relocation methodology.**

```stata
forvalues spring_year = `test_score_min_year' (1) `test_score_max_year' {
    keep if year == `spring_year'
    save data/sch_char_`spring_year'.dta, replace      // <-- LINE 609
    snapshot restore 1
}
```

Predecessor verbatim was `save data/sch_char_<year>.dta` after `cd $vaprojdir`, intended to land in `cde_va_project_fork/data/sch_char_<year>.dta`. In consolidated, with `cd $vaprojdir` removed and main.do CWD `$consolidated_dir`, this save lands at `$consolidated_dir/data/sch_char_<year>.dta` — i.e., `$consolidated_dir/data/` not `$consolidated_dir/data/cleaned/`.

This **does** land inside the sandbox (so not a LEGACY-write violation; doesn't break `diff -r consolidated/output predecessor/output` against the corresponding predecessor location), but:

- It bypasses the CANONICAL `$datadir_clean` global per `do/settings.do:102`.
- Inconsistent with the relocation methodology's documented rule "data/* (relative form post-cd) → $datadir_clean/* (CANONICAL chain; relative form post-cd)" stated in every file's RELOCATION header doc-block.
- The same file's master save (line 603) WAS correctly repointed to `$datadir_clean/sch_char.dta`. The per-year-snapshot block (lines 607-611) was missed.
- The RELOCATION header doc-block (lines 44-59) lists `data/sch_char.dta → $datadir_clean/sch_char.dta` (singular master) but does NOT mention the per-year `data/sch_char_<year>.dta` writes.

Severity: Major. Behavior-affecting (output lands at wrong subdir relative to project convention) and self-inconsistent with the relocation methodology stated in the file's own header.

**Suggested fix (NOT applied — critic does not edit source):** Repoint line 609 to `save $datadir_clean/sch_char_\`spring_year'.dta, replace` and add `cap mkdir "$datadir_clean"` (already present at line 102). Also add the per-year output line to the OUTPUTS section of the header doc-block.

**Acceptable verbatim (no deduction): `clean_charter.do:75 + 105` Mac-branch.**

```stata
if c(machine_type)=="Macintosh (Intel 64-bit)" {
    import delimited using "data_local/CDESchoolDirectoryExport.txt", delimiters("\t")
}
...
if c(machine_type)=="Macintosh (Intel 64-bit)" {
    save "data_local/charter_status.dta", replace
}
```

Per dispatch instruction Concern 1 ("Predecessor verbatim per ADR-0021; dead on Linux/Scribe production. The commit message acknowledges this..."), this is preserved verbatim per ADR-0021. The Mac-branch is not exercised on Scribe production (`c(machine_type)` returns Linux). Predecessor has the same structure (verified at `cde_va_project_fork/do_files/schl_chars/clean_charter.do:26-28, 56-58`). The relative `data_local/...` would land at `$consolidated_dir/data_local/` if a Mac were ever to run this script, which is inside the sandbox. Verbatim-preservation rationale is sound.

### Concern 2 — INPUTS+OUTPUTS header fidelity: WARN (1 Minor cluster, -3)

Per the dispatch's 4th-recurrence discipline, three drifts:

**(a) 6 sister cleaners falsely claim tempfile output.** The PURPOSE line of each sister cleaner says, e.g.:

- `clean_elsch.do:6` — "produces yearly elsch dtas + tempfile elsch consumed by clean_sch_char"
- `clean_enr.do:6` — "produces yearly enr dtas + tempfiles consumed by clean_sch_char"
- `clean_frpm.do:6`, `clean_staffcred.do:6`, `clean_staffdemo.do:6`, `clean_staffschoolfte.do:6` — same shape

In fact, NONE of these 6 files contain a `tempfile` declaration (verified by `grep tempfile do/data_prep/schl_chars/*.do`). Each produces ONLY per-year persistent `.dta` files in `$datadir_clean/cde/<subdir>/`.

**(b) `clean_sch_char.do` header INPUTS list 8 tempfiles "from sister cleaner".** Lines 22-29 of the header attribute `enr_total`, `enr_race`, `enr_sex`, `frpm`, `elsch`, `staffdemo`, `staffcred`, `staffschoolfte` as tempfiles "from sister cleaner". In fact, all 8 are defined and consumed within `clean_sch_char.do` itself (declared on lines 182, 266, 302, 333, 364, 399, 429, 465; re-declared on lines 513, 540, 561). The actual sister-cleaner inputs are the per-year persistent `.dta`s on lines 174, 191, 275, 323, 354, 385, 412, 443 (which the header DOES list correctly under "CHAIN read; from this batch" on lines 15-20).

**(c) `clean_charter.do` header missing Mac-branch input + output.** Header line 12 lists only the `else`-branch raw input (`$vaprojdir/.../CDESchoolDirectoryExport.txt`). The Mac-branch input (`data_local/CDESchoolDirectoryExport.txt`, line 75) is absent. Header lines 14-17 list only the `else`-branch save (`$datadir_clean/cde/charter_status.dta`); the Mac-branch save (`data_local/charter_status.dta`, line 105) is absent.

**Bonus drift propagation:** main.do line 124 one-liner reads "MASTER: merges 6 sister tempfiles + 4 chain dtas; writes $datadir_clean/sch_char.dta". The "6 sister tempfiles" framing inherits the same misleading attribution as the headers; should read something like "merges per-year .dtas (8 internal tempfiles) + 4 chain dtas".

Severity: Minor cluster (-3). Documentation-only; runtime behavior is correct. But this is exactly the kind of drift the 4th-recurrence header-fidelity discipline aims to catch.

**Note on dispatch claim:** The dispatch instruction Concern 1 said "The 6 cleaner files ... have BOTH tempfile saves (`save \`name'`) AND per-year persistent saves." This is also incorrect; the 6 cleaners have only per-year persistent saves. Surfacing this so the bias-checking the pair-flow is meant to catch operates correctly.

### Concern 3 — `$projdir`/`$vaprojdir`/`$caschls`/`$matt` repointings clean: PASS

Grep on `\$(vaprojdir|projdir|caschls|matt|caschls_projdir|matt_files_dir|mattxwalks|nscdtadir|distance_dtadir|vaprojxwalks)` across all 11 files yields only acceptable matches:

- Header doc-block RELOCATION sections listing the repointings (every file)
- Predecessor "to run" comment lines (e.g., `cds_nces_xwalk.do:46`, `clean_locale.do:47`, `clean_charter.do:49`, `clean_ecn_disadv.do:48`)
- LEGACY raw imports: `import delimited|excel $vaprojdir/data/public_access/raw/...` — 11 occurrences across the 7 cleaner+xwalk files
- LEGACY restricted-clean read: `clean_ecn_disadv.do:71` — `using $vaprojdir/data/restricted_access/clean/k12_test_scores/...` — explicitly noted in dispatch instruction as acceptable

**Zero code-line writes to LEGACY paths.** No `$projdir`, no `$caschls`, no `$matt` references at all (only `$vaprojdir` and `$datadir_clean`/`$logdir`).

### Concern 4 — main.do Phase 1 wiring + chain order: PASS

Verified main.do lines 112-124 wire all 11 files in chain order matching predecessor `do_all.do:75-97`:

| main.do line | Script | Predecessor do_all.do line | Chain role |
|---|---|---|---|
| 114 | cds_nces_xwalk.do | 75 | first; produces cds_nces xwalk |
| 115 | clean_locale.do | 78 | reads cds_nces xwalk |
| 116 | clean_elsch.do | 80 | independent yearly cleaner |
| 117 | clean_enr.do | 82 | independent yearly cleaner |
| 118 | clean_frpm.do | 84 | independent yearly cleaner |
| 119 | clean_staffcred.do | 86 | independent yearly cleaner |
| 120 | clean_staffdemo.do | 88 | independent yearly cleaner |
| 121 | clean_staffschoolfte.do | 90 | independent yearly cleaner |
| 122 | clean_charter.do | 92 | independent lookup cleaner |
| 123 | clean_ecn_disadv.do | 94 | independent (LEGACY-restricted reader) |
| 124 | clean_sch_char.do | 97 | LAST — master assembly |

Each invocation has a one-liner per ADR-0021 description convention. Pending-9c/9d/9e flag-comments retained on lines 126-129. Banner comment on line 112 records "LANDED 2026-05-08" with the chain-order rationale.

The "tempfiles" wording on line 124 is captured under Concern 2 (drift cluster); not separately deducted.

### Concern 5 — Verbatim preservation under ADR-0021: PASS with caveat

Spot-checked 6 of 11 files against `cde_va_project_fork/do_files/schl_chars/<file>.do` predecessors:

- **`cds_nces_xwalk.do`**: predecessor 1-43 vs consolidated 41-97. `cd $vaprojdir` removed → comment+mkdir block. NO log block in predecessor; full canonical log block added (lines 58-66, 95-96). `import delimited` line 23→75 path-preserved as LEGACY raw. `save` line 42 → 94 repointed CANONICAL. ✓
- **`clean_locale.do`**: predecessor 1-95 vs consolidated 41-147. Same shape: cd removed, full canonical log block added (lines 56-64, 146-147), import excel line 30→73 LEGACY-raw preserved, merge line 90→141 repointed CANONICAL, save line 95→145 repointed CANONICAL. ✓
- **`clean_elsch.do`**: predecessor 1-111 vs consolidated 45-161. `cd $vaprojdir` (predecessor:18) removed → comment+mkdir block. `log using log_files/...` (predecessor:20) → `log using "$logdir/clean_elsch.smcl", replace text` (consolidated:70) — path-repointed + double-quotes + text flag added. `include do_files/sbac/macros_va.doh` (predecessor:77) → `include $consolidated_dir/do/va/helpers/macros_va.doh` (consolidated:127). `import delimited data/...` (predecessor:94) → `import delimited $vaprojdir/data/...` (consolidated:144) — LEGACY-raw absolute. `save data/...` (predecessor:104) → `save $datadir_clean/...` (consolidated:154) — CANONICAL absolute. `translate log_files/...` (predecessor:111) → `translate $logdir/...` (consolidated:161). ✓
- **`clean_ecn_disadv.do`**: predecessor 1-40 vs consolidated 43-87. Same shape. `use ... using $vaprojdir/data/restricted_access/...` preserved as LEGACY-restricted read on line 71. ✓
- **`clean_sch_char.do`**: predecessor 1-549 vs consolidated 67-617. Body verbatim modulo path repointings. **Caveat:** line 541 predecessor `save data/sch_char_<year>.dta` was preserved verbatim at consolidated line 609 — i.e., the relative-path write was NOT repointed. This is the Major finding under Concern 1.
- **`clean_charter.do`**: predecessor 1-71 vs consolidated 41-119. Body verbatim. The Mac-branch (lines 74-75, 104-106) and else-branch path repointings preserved. ✓ (Mac-branch idiosyncrasy noted under Concern 1 acceptable-verbatim and Concern 2 minor.)

**Side observation on dispatch description accuracy:** The dispatch's Concern 5 listed three files getting "FULL canonical log block added" — `cds_nces_xwalk`, `clean_locale`, `clean_charter`. The first two checked out (verified above). For `clean_charter.do`, the existing else-branch `log using` (predecessor line 31) was just path-repointed in place (consolidated line 79) — no full canonical log block was lifted out of the else-branch. The log opens AFTER `import delimited` and stays inside the `else`. This is a description-error in the dispatch, not a code-error in the relocation; just noting for transparency.

LF normalization vs predecessor CRLF is project convention per Step 7-8 precedent; not deducted.

---

## Score Breakdown

- Starting: 100
- **Concern 1 — Major: `clean_sch_char.do:609` relative-path write missed by relocation methodology:** -5
- **Concern 2 — Minor cluster: header fidelity drift (sister cleaners' tempfile-output claims, master's "from sister cleaner" attribution, charter Mac-branch unenumerated):** -3
- Concern 3: 0 (PASS)
- Concern 4: 0 (PASS, drift on line 124 already counted in Concern 2)
- Concern 5: 0 (PASS, caveat already counted in Concern 1)
- **Final: 92/100**

## Verdict: PASS (≥ 80 gate)

Strong batch overall. Chain order, one-liner discipline, helper-include relocation, log-convention upgrade, and LEGACY-read preservation are all correct. Two real findings:

1. The per-year `data/sch_char_<year>.dta` save in `clean_sch_char.do:609` should be repointed to `$datadir_clean/sch_char_<year>.dta` for consistency with the relocation methodology applied elsewhere in the same file.
2. Header documentation drift on the "tempfile from sister cleaner" claim is a 4th-recurrence-discipline catch; six sister cleaners and the master all carry the same misattribution.

Both are addressable in a follow-up hygiene commit (or in-commit if Christina prefers to fix before pushing). Neither blocks the 80/100 gate.

## Compliance Evidence (from `.claude/state/verification-ledger.md`)

The 11 files in this batch have **no ledger rows** as of review time (verified by inspecting `.claude/state/verification-ledger.md` lines 23-40, which are populated only with `do/check/check_*.do` rows from 2026-04-29).

Per the dispatch's tight 5-concern scope ("Out of scope: 12-category rubric items outside the 5 concerns"), missing ledger rows are **not deducted** in this review. The 5 concerns themselves served as the verification basis; evidence is captured inline above (grep counts, line numbers, predecessor comparisons). The author may add ledger rows in a hygiene commit if desired.

## Escalation Status: None (Round 1 PASS)

No three-strikes escalation. PASS at Round 1.

## Suggested commit-message footer

```
coder-critic: PASS (92/100); deferred 2 Minor/Major findings — clean_sch_char.do:609 relative-path write + sister-cleaner tempfile-attribution drift; addressable in follow-up hygiene commit.
```

If the author prefers to fix in-commit and re-dispatch for Round 2:

```
coder-critic: round 2 — PASS (XX/100) after addressing Major Concern 1 + Minor Concern 2.
```
