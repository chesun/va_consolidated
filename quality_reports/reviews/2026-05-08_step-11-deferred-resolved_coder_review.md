# Phase 1a §3.3 Step 11 — Deferred files resolved — coder-critic review
**Date:** 2026-05-08
**Reviewer:** coder-critic
**Target:** Phase 1a §3.3 step 11 (commit `6791dec`); 2 active relocations (`do/survey_va/{allsvymerge,testscore}.do`) + 1 archive (`do/_archive/exploratory/allsvyfactor.do`) + 4 cross-step Step 7 chain fixes + main.do Phase 5 wiring + step-marker COMPLETE
**Score:** 96/100
**Status:** Active
**Mode:** Full (Phase 1a §3.3 strict; tight 5-concern scope per dispatch)

---

## Verdict

**PASS at 96/100. Hard gate (80) cleared comfortably. Phase 1a §3.3 FULLY COMPLETE = 148 files across 11 steps.**

This is the cleanest Step disposition reviewed in Phase 1a. The cross-step chain coordination — the load-bearing concern given the disposition-audit recategorization from "exploratory" to "ACTIVE chain producer" — is **fully closed-loop**: 6 producer/consumer paths (3 producer writes by allsvymerge + 1 by testscore + 2 sister-step consumer fixes per Step 7 file) all verify against the CANONICAL chain. The disposition logic is documented thoroughly in both file headers and the `do/_archive/exploratory/README.md` update; future archeology will reconstruct the "originally deferred → re-audited → ACTIVE" decision path without ambiguity.

One Minor deduction (-3) is for missing verification-ledger rows on the 2 active relocations; one Minor (-1) for the archived file's body-verbatim claim being stated rather than independently hash-checked in this review.

---

## Concern-by-concern

### Concern 1 — Sandbox-write check (extended grep) on the 2 active relocations: PASS

`allsvymerge.do` writes (verified via `grep -nE 'save|export|outsheet|esttab using|graph export|outreg2 using|texsave|log using|translate'`):
- L81 `log using "$logdir/allsvymerge.smcl"` — CANONICAL
- L92 `save $datadir_clean/survey_va/formerge/parentqoimeans` — CANONICAL
- L101 `save $datadir_clean/survey_va/formerge/secqoimeans` — CANONICAL
- L110 `save $datadir_clean/survey_va/formerge/staffqoimeans` — CANONICAL
- L122 `save $datadir_clean/survey_va/allsvyqoimeans` — CANONICAL
- L126 `translate $logdir/allsvymerge.smcl $logdir/allsvymerge.log` — CANONICAL

Total: 4 saves + 1 log_using + 1 translate. Matches expected pattern. **No LEGACY writes.**

`testscore.do` writes:
- L63 `log using "$logdir/testscore.smcl"` — CANONICAL
- L97 `save $datadir_clean/schoolchar/testscorecontrols` — CANONICAL
- L101 `translate $logdir/testscore.smcl $logdir/testscore.log` — CANONICAL

Total: 1 save + 1 log_using + 1 translate. Matches expected pattern. **No LEGACY writes.**

`grep -nE '"/Users|"/home|"C:\\\\'` returns 0 matches in both files (no hardcoded paths).

`$projdir` references in both files appear ONLY in header documentation (the path-repointing reference table). No live code uses `$projdir`. Verified via grep.

### Concern 2 — INPUTS+OUTPUTS header fidelity: PASS

`allsvymerge.do` header (L17-29) declares 7 inputs and 4 outputs (+1 log+log) ; body confirms:

| Header claim | Body verification |
|---|---|
| INPUT `$datadir_clean/calschls/va/va_pooled_all.dta` | L120 `merge 1:1 cdscode using $datadir_clean/calschls/va/va_pooled_all.dta` ✓ |
| INPUT `$datadir_clean/calschls/analysisready/parentanalysisready` | L84 `use` ✓ |
| INPUT `$datadir_clean/calschls/analysisready/secanalysisready` | L96 `use` ✓ |
| INPUT `$datadir_clean/calschls/analysisready/staffanalysisready` | L105 `use` ✓ |
| INPUTS `$datadir_clean/survey_va/formerge/{parent,sec,staff}qoimeans` | L115/116/117 `use`/`merge` (these are intermediates this script also produces — round-trip via formerge dtas) ✓ |
| OUTPUTS 4 dtas + log | L92, L101, L110, L122 saves + L81 log + L126 translate ✓ |

`testscore.do` header (L17-22) declares 2 LEGACY restricted-access inputs and 1 CANONICAL output; body confirms:

| Header claim | Body verification |
|---|---|
| INPUT (LEGACY) `$vaprojdir/data/restricted_access/.../k12_test_scores_clean.dta` | L69 ✓ |
| INPUT (LEGACY) `$vaprojdir/data/restricted_access/.../k12_lag_test_scores_clean.dta` | L72 ✓ |
| OUTPUT `$datadir_clean/schoolchar/testscorecontrols` | L97 ✓ |
| OUTPUT `$logdir/testscore.{smcl,log}` | L63 + L101 ✓ |

LEGACY restricted-access K12 reads correctly preserved (per ADR-0017 / Matt Naven scope carve-out). 4th-recurrence header fidelity: clean PASS.

### Concern 3 — Cross-step chain coordination: PASS (load-bearing concern)

This is the disposition-audit's load-bearing concern: the "deferred → ACTIVE" recategorization is correct only if the chain producer/consumer loop is fully closed.

**Closed-loop verification (6 paths):**

A. allsvymerge → imputation chain:
- Producer write `allsvymerge.do:122` `save $datadir_clean/survey_va/allsvyqoimeans`
- Consumer read `imputation.do:66` `use $datadir_clean/survey_va/allsvyqoimeans` ✓ MATCH

B. allsvymerge → compcasecategoryindex chain:
- Producer (same as A)
- Consumer read `compcasecategoryindex.do:86` `use $datadir_clean/survey_va/allsvyqoimeans` ✓ MATCH

C. testscore → indexregwithdemo chain:
- Producer write `testscore.do:97` `save $datadir_clean/schoolchar/testscorecontrols`
- Consumer read `indexregwithdemo.do:98` `merge 1:1 cdscode using $datadir_clean/schoolchar/testscorecontrols` ✓ MATCH

D. testscore → indexhorseracewithdemo chain:
- Producer (same as C)
- Consumer read `indexhorseracewithdemo.do:93` `merge 1:1 cdscode using $datadir_clean/schoolchar/testscorecontrols` ✓ MATCH

E. mattschlchar (Step 10) → indexregwithdemo (BONUS Step 11 catch):
- Producer write `do/survey_va/mattschlchar.do:151` `save $datadir_clean/schoolchar/schlcharpooledmeans`
- Consumer read `indexregwithdemo.do:95` `merge 1:1 cdscode using $datadir_clean/schoolchar/schlcharpooledmeans` ✓ MATCH

F. mattschlchar (Step 10) → indexhorseracewithdemo (BONUS catch):
- Producer (same as E)
- Consumer read `indexhorseracewithdemo.do:91` `merge 1:1 cdscode using $datadir_clean/schoolchar/schlcharpooledmeans` ✓ MATCH

All 6 chain paths confirmed exact-match producer/consumer; no path drift, no orphan writes, no orphan reads. The "BONUS catch" (E+F) — fixing 2 LEGACY reads of `schlcharpooledmeans` that the Step 10 commit had relocated the producer of but had not fully repointed in the Step 7 consumers — is exactly the kind of cross-step coordination drift this Tier 2 review is designed to catch. Surfacing it inside the Step 11 commit (rather than letting it ship as a hidden chain break) is solid scope discipline.

**Upstream chain integrity (sanity check):**
- `parentanalysisready/secanalysisready/staffanalysisready` are produced by Step 9f producers writing to the exact CANONICAL paths allsvymerge reads (verified via `grep -n save.*analysisready do/data_prep/poolingdata/`).
- `va_pooled_all.dta` is produced by Step 9f `do/data_prep/poolingdata/clean_va.do:118` writing to the exact CANONICAL path allsvymerge reads.

Predecessor behavioral parity: predecessor `imputation.do:17` and `compcasecategoryindex.do:28` both used `$projdir/dta/allsvyfactor/allsvyqoimeans`; predecessor `indexregwithdemo.do:40` and `indexhorseracewithdemo.do:43` both used `$projdir/dta/schoolchar/testscorecontrols`. The consolidated chain repoints `$projdir/dta/{allsvyfactor,schoolchar}/...` → `$datadir_clean/{survey_va,schoolchar}/...`. **Faithful repointing — no behavioral change**, only sandbox-canonical path remapping.

### Concern 4 — Archive convention compliance for `allsvyfactor.do`: PASS

(a) Body byte-identical to predecessor: verified by reading both files; both are 29 lines with identical content (header comment block + `cap log close _all` / `clear all` / `set more off` / `log using $projdir/log/share/factoranalysis/allsvyfactor.smcl, replace` / factor analysis / esttab / screeplot / graph export / second factor with mineigen / esttab eigen1 / log close / translate). The `$projdir` references in the archived body are EXPECTED (verbatim preservation per ADR-0021's archive convention).

(b) README at `do/_archive/exploratory/README.md` updated correctly. Step 8 had 1 file (`alpha.do`); Step 11 adds the `allsvyfactor.do` entry at L15. The new entry documents:
- Archive trigger date (2026-05-08, Step 11)
- Per-file-header rationale ("exploratory factor analysis for merge dataset")
- LEGACY input read (`$caschls_projdir/dta/allsvyfactor/allsvyqoimeans` — pre-relocation predecessor path) — appropriate caveat that the predecessor path is preserved verbatim
- Output enumeration (allsvyfactor.csv, allsvyscreeplot.png, allsvyfactoreigen1.csv) — all exploratory diagnostics, no chain consumers
- "No chain consumers in either predecessor or consolidated" claim (independently verified — none of the 4 outputs are read by any consolidated `do` file; verified via grep below)
- Archive-convention authority (ADR-0010 archive convention; ADR-0021 verbatim-preservation)

(c) NOT invoked from main.do: `grep -nE 'allsvyfactor|alpha\.do' do/main.do` returns 2 hits, both in flag-comments at L365-366 (Step 8 + Step 11 archive markers — non-invoking comments, expected). No `do do/_archive/exploratory/allsvyfactor.do` invocation. ✓

Step 8 README precedent applied consistently. Archive convention compliance is clean.

### Concern 5 — main.do Phase 5 wiring + chain order: PASS

`do/main.do` Phase 5 (L340-367) verified:

(a) `allsvymerge.do` (L352) BEFORE `imputation.do` (L353) and `compcasecategoryindex.do` (L355) — chain producer correctly precedes both consumers ✓

(b) `testscore.do` (L358) BEFORE `indexregwithdemo.do` (L359) and `indexhorseracewithdemo.do` (L360) — chain producer correctly precedes both consumers ✓

(c) `mattschlchar.do` (L357) — already in place from Step 10 batch 10c per ADR-0013; correctly precedes `indexregwithdemo.do` and `indexhorseracewithdemo.do` (which need its `schlcharpooledmeans` output) ✓

(d) Phase-5 docstring (L348-351) updated correctly: "RELOCATED 2026-05-08 per plan v3 §3.3 steps 7+10+11 — Survey VA chain. Reads CHAIN $datadir_clean/{survey_va,schoolchar,calschls/{analysisready,va}}/* (Steps 9f + 10 + 11); writes CANONICAL ..." — accurate description of the now-fully-resolved chain. ✓

(e) Step 11 flag-comment removed and replaced with COMPLETE marker (L366): `* Phase 1a §3.3 step 11 COMPLETE — 'allsvymerge.do' + 'testscore.do' relocated ACTIVE above (chain producers, not exploratory as initially flagged); 'allsvyfactor.do' archived to 'do/_archive/exploratory/' per ADR-0010 (truly exploratory; no chain consumers).` ✓

The COMPLETE marker also correctly preserves the disposition-audit history ("not exploratory as initially flagged"), which is valuable archeology for the next reader who wants to understand why these files moved through 3 dispositions (Step 7 deferred → Step 11 ACTIVE-or-archived).

Per-line wiring inserts are clean: each new `do do/survey_va/<file>.do` line carries a `// RELOCATED Step 11; ...` one-liner describing both the source step and the chain role (per ADR-0021 description convention).

---

## Compliance Evidence (from `.claude/state/verification-ledger.md`)

Consulted ledger; relevant rows for the 2 active relocations and the 4 cross-step Step 7 file fixes:

- `do/survey_va/allsvymerge.do | no-hardcoded-paths | (MISSING — flagged)` — file is new this commit; no ledger row yet
- `do/survey_va/allsvymerge.do | adr-0021-sandbox-write | (MISSING — flagged)` — file is new this commit
- `do/survey_va/testscore.do | no-hardcoded-paths | (MISSING — flagged)` — file is new this commit
- `do/survey_va/testscore.do | adr-0021-sandbox-write | (MISSING — flagged)` — file is new this commit
- `do/survey_va/{imputation,compcasecategoryindex,indexregwithdemo,indexhorseracewithdemo}.do | adr-0021-sandbox-write | (MISSING — flagged)` — these were verified in Step 7 review (ledger entries should exist from `2026-05-08_step-7-survey-va_coder_review.md`); the cross-step chain fixes in this commit modified them, so their existing rows should now be marked stale (file hash mismatch)
- `do/_archive/exploratory/allsvyfactor.do | (no checks needed; archived non-load-bearing)` — N/A
- `do/main.do | (modified this commit; existing rows stale)` — known limitation; main.do hash drifts every step

The MISSING ledger rows are the source of the -3 Minor deduction below. The convention is to write the rows after PASS verification; this review's evidence above (concrete paths, line numbers, save-call inventory) suffices to populate the rows post-PASS.

---

## Score Breakdown

- Starting: 100
- Concern 1 (Sandbox-write check): PASS, 0 deduction
- Concern 2 (INPUTS+OUTPUTS header fidelity): PASS, 0 deduction
- Concern 3 (Cross-step chain coordination — load-bearing): PASS with bonus catch (E+F), 0 deduction
- Concern 4 (Archive convention compliance for allsvyfactor.do): PASS, 0 deduction
- Concern 5 (main.do Phase 5 wiring + chain order): PASS, 0 deduction
- Adversarial-default Minor (vague-evidence): -3 — verification-ledger rows for the 2 active relocations and the 4 modified Step 7 files are missing; PASS verdict relies on this review's grep evidence rather than ledger-cached PASS rows
- Adversarial-default Minor (vague-evidence): -1 — `allsvyfactor.do` body-verbatim claim was verified by visual side-by-side reading of both files (predecessor + archive copy) rather than `sha256sum` hash comparison; the visual match is unambiguous (29 lines, identical content), but a hash check would be definitive

**Final: 96/100**

---

## Recommendations (non-blocking)

1. After commit, append verification-ledger rows for the 2 new active relocations:
    - `do/survey_va/allsvymerge.do | no-hardcoded-paths | <today> | <hash> | PASS | grep returned 0 matches`
    - `do/survey_va/allsvymerge.do | adr-0021-sandbox-write | <today> | <hash> | PASS | 4 saves to $datadir_clean/survey_va/{allsvyqoimeans,formerge/{parent,sec,staff}qoimeans}; log+translate target $logdir/; no LEGACY writes`
    - `do/survey_va/testscore.do | no-hardcoded-paths | <today> | <hash> | PASS | grep returned 0 matches`
    - `do/survey_va/testscore.do | adr-0021-sandbox-write | <today> | <hash> | PASS | 1 save to $datadir_clean/schoolchar/testscorecontrols; log+translate target $logdir/; LEGACY $vaprojdir restricted-access reads (Matt K12 test scores) preserved per ADR-0017`
    - Also re-hash and update existing rows for the 4 modified Step 7 files (imputation, compcasecategoryindex, indexregwithdemo, indexhorseracewithdemo) — they were verified in Step 7 review at older hashes; the cross-step chain fixes in this commit have changed their content.

2. The "originally deferred → recategorized to ACTIVE" disposition history is documented in headers + main.do COMPLETE marker + this review. Consider also appending a 1-line entry to `decisions/README.md` Pending decisions or as a footnote on the relevant ADR (none currently exists for this disposition; ADR-0010 covers `alpha.do` only). Since the chain works and the rationale is documented in 3 places, a separate ADR is probably overkill — but flagging in case the next-reader convention is "every disposition reversal gets an ADR."

3. `do/_archive/exploratory/README.md:39` says "Body preserved verbatim per ADR-0021" for `allsvyfactor.do`. A definitive verification would be `diff` of predecessor vs archive copy; this review used visual side-by-side. A future archive-batch convention extension could cite a `sha256sum` comparison output in the README to make the verbatim claim machine-verifiable.

---

## Escalation Status

None. PASS at 96/100; well above the 80 hard gate. **Phase 1a §3.3 FULLY COMPLETE = 148 files across 11 steps.** Proceed with hygiene (TODO cleanup) + push.

---

## Commit message footer suggestion

```
coder-critic: PASS (96/100); 2 Minor deductions for missing/stale verification-ledger rows
(populate post-commit per Recommendation 1) and visual-vs-hash verbatim verification
of archived allsvyfactor.do body (Recommendation 3). Cross-step chain coordination
fully closed-loop across 6 producer/consumer paths (4 Step 11 + 2 BONUS Step 10
catches). Phase 1a §3.3 FULLY COMPLETE = 148 files across 11 steps.
```
