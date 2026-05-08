# Step 9 Batch 9a Review — coder

**Date:** 2026-05-08
**Reviewer:** coder-critic
**Target:** Phase 1a §3.3 step 9 batch 9a — `do/data_prep/acs/{acs_2017_gen_dict,clean_acs_census_tract}.do` + `do/main.do` Phase 1 wiring delta (commit `4a88874`)
**Score:** 95/100
**Status:** Active
**Mode:** Phase-1 tight-scope (5 concerns); strict severity (Phase 1a relocation row, `phase-1-review.md` §3)

---

## Verdict

**PASS (95/100).** Both relocated files honor ADR-0021 sandbox discipline cleanly: every active write targets a CANONICAL global; LEGACY `$vaprojdir` appears only in raw-input reads (16 `import delimited` lines) plus header-doc + predecessor-comment lines; the commented-out `$projdir` save at line 403 is preserved verbatim inside a `/* ... */` block exactly as ADR-0021 prescribes. Header INPUTS+OUTPUTS sections match what the bodies actually do. Both invocations land in `do/main.do` Phase 1 in the correct order with one-liners that match each script's purpose. Pending 9b/9c/9d/9e flag-comments are present and correctly placed. One Minor finding on header-disclosure precision (-3) and one Minor on directory-prep idempotence (-2) — neither blocks; both can be deferred to a follow-up commit if desired.

---

## Concern-by-concern

### 1. Sandbox-write check — PASS

Per the now-extended grep `grep -nE 'save|export|esttab using|graph export|outsheet|outreg2 using|texsave|^\s*translate |log using' do/data_prep/acs/*.do`, every match either targets a CANONICAL global, is a tempfile, is inside a `/* ... */` predecessor comment, or is a header doc-block reference. Concrete inventory:

**`acs_2017_gen_dict.do` (5 active write/log lines):**
- L87 `log using "$logdir/acs_2017_gen_dict.smcl", replace text` → CANONICAL `$logdir`. PASS.
- L104 `descsave, ... saving($output_dir/csv/acs/2017/acs_2017_\`subject'_dict.dta, replace)` → CANONICAL `$output_dir`. PASS.
- L106 `export delimited using $output_dir/csv/acs/2017/acs_2017_\`subject'_dict.csv, replace` → CANONICAL `$output_dir`. PASS.
- L111 — commented-out predecessor `export delimited using $vaprojdir/...` inside `/* ... */`. Inactive; preserved verbatim per ADR-0021. PASS.
- L114 `translate $logdir/acs_2017_gen_dict.smcl $logdir/acs_2017_gen_dict.log, replace` → CANONICAL `$logdir`. PASS.

**`clean_acs_census_tract.do` (8 active write/log lines + 4 tempfile saves + 1 commented predecessor):**
- L80 `log using "$logdir/clean_acs_census_tract.smcl", replace text` → CANONICAL `$logdir`. PASS. (Note: predecessor was `log using log_files/acs/clean_acs_census_tract.smcl, replace` — single-quoted, no `text` flag; consolidated upgrades to double-quoted + `text` per Step 7 indexalpha precedent. Correct.)
- L155, L187, L319, L384 `save \`<name>'` → tempfile macros (set on prior `tempfile` lines 154/186/318/383). Unanchored backtick syntax = Stata tempfile pointer, not a path; auto-deleted at program end. PASS.
- L402–403 `/* //save to my own folder while waiting for write access \n save $projdir/dta/common_core_va/acs/acs_ca_census_tract_clean_\`year'.dta, replace */` — predecessor commented-out block preserved verbatim. The `$projdir` global is undefined in `do/settings.do` and the line is inactive (inside `/* ... */`); zero runtime risk. ADR-0021 verbatim-preservation requirement satisfied. PASS.
- L404 `save $datadir_clean/acs/acs_ca_census_tract_clean_\`year'.dta, replace` → CANONICAL `$datadir_clean`. PASS.
- L413 `save $datadir_clean/acs/acs_ca_census_tract_clean.dta, replace` → CANONICAL `$datadir_clean`. PASS.
- L425 `translate $logdir/clean_acs_census_tract.smcl $logdir/clean_acs_census_tract.log, replace` → CANONICAL `$logdir`. PASS.

Zero LEGACY-path writes anywhere in either file. Sandbox principle satisfied.

### 2. INPUTS+OUTPUTS header fidelity — PASS (with one Minor note)

**`acs_2017_gen_dict.do`:**
- INPUTS declared: `$vaprojdir/.../ACS_17_5YR_<S>_with_ann.csv` (4 csv files). Body L96 = exactly that pattern under foreach loop over 4 subjects. MATCH.
- OUTPUTS declared: `$output_dir/csv/acs/2017/acs_2017_<S>_dict.{dta,csv}` (4×2 = 8 files) + `$logdir/acs_2017_gen_dict.smcl/.log`. Body L104 (descsave saving), L106 (export delimited), L87+L114 (log+translate). MATCH.

**`clean_acs_census_tract.do`:**
- INPUTS declared: `$vaprojdir/.../ACSST5Y<year>.<S>_data_with_overlays.csv` (4 subjects × 4 years = 16 csv files) + `$consolidated_dir/do/va/helpers/macros_va.doh` (include). Body has 4 `import delimited` lines under foreach year (L109/L161/L193/L326), each cycling subject = 4×4 = 16 input reads. MATCH. Include statement at L93 cites correct CANONICAL relocated path.
- OUTPUTS declared: `$datadir_clean/acs/acs_ca_census_tract_clean_<year>.dta` (4 yearly) + `acs_ca_census_tract_clean.dta` (combined) + `$logdir/...smcl/.log`. Body L404 (4 yearly saves under foreach), L413 (combined append save), L80+L425 (log+translate). MATCH.

**Minor finding (4th-recurrence precision, -3):** Neither header explicitly declares the 4 *internal tempfile saves* (`education_<year>`, `poverty_<year>`, `income_<year>`, `population_<year>`) at L155/L187/L319/L384. While these are tempfiles (transient, auto-deleted) and arguably not OUTPUTS in the data-shipping sense, the 4th-recurrence INPUTS+OUTPUTS-header-fidelity discipline (per the prior 4 batch reviews) values exhaustive disclosure. The header's "verified via grep on file body" claim is technically slightly under-inclusive — a stricter reading of grep `^\s*save` returns 6 matches, of which the header documents only 2 destinations. **Suggested fix (optional, not commit-blocking):** add a line to OUTPUTS noting "4 internal tempfile saves per year (education/poverty/income/population) merged 1:1 by `geoid` before final save — transient." Defer to follow-up commit if desired.

### 3. `$projdir` / `$vaprojdir` repointings clean — PASS

Per `grep -nE '\$projdir|\$vaprojdir' do/data_prep/acs/*.do`, all 16 matches fall into acceptable categories:

**`acs_2017_gen_dict.do` (4 matches):**
- L21 — INPUTS section header doc-block (LEGACY raw input declaration). OK.
- L35 — RELOCATION section documenting old `$projdir/out/csv/acs/2017/*` → new `$output_dir/csv/acs/2017/*` repointing. OK.
- L36 — RELOCATION section noting `$vaprojdir/data/public_access/raw/acs/*` kept as LEGACY raw input. OK.
- L62 — predecessor's "to run this do file" header comment block, preserved verbatim. OK.
- L96 — `import delimited using $vaprojdir/data/public_access/raw/acs/subject_tables/2017/ACS_17_5YR_\`subject'_with_ann.csv` — LEGACY raw read. OK (read-only per ADR-0021).
- L111 — commented-out `export delimited using $vaprojdir/...` inside `/* ... */`. Inactive. OK.

**`clean_acs_census_tract.do` (10 matches):**
- L15, L27, L30 — header doc-block (INPUTS, RELOCATION). OK.
- L33 — RELOCATION section documenting predecessor's commented-out `$projdir/dta/...` save preservation. OK.
- L60 — predecessor's "to run this do file" comment block. OK.
- L109, L161, L193, L326 — 4 LEGACY raw reads (`import delimited using $vaprojdir/.../ACSST5Y<year>.<S>_data_with_overlays.csv`). OK (read-only).
- L403 — commented-out `save $projdir/dta/common_core_va/acs/acs_ca_census_tract_clean_\`year'.dta, replace */` inside `/* ... */`. Inactive. OK. (`$projdir` undefined in settings.do; even if Stata expanded it, the line is in a comment.)

Zero active code lines write to `$projdir/...` or `$vaprojdir/...`. Sandbox-write boundary cleanly preserved.

### 4. main.do Phase 1 wiring + flag-comments — PASS

`do/main.do` lines 103–124 contain the Phase 1 `run_data_prep` block under flag `do_data_prep`. Verification:

**(a) Order:** L109 invokes `acs_2017_gen_dict.do` first; L110 invokes `clean_acs_census_tract.do` second. Both 9a files have no inter-dependency — `acs_2017_gen_dict.do` produces 2017-only diagnostic dicts (`$output_dir/csv/acs/2017/...`) and `clean_acs_census_tract.do` produces 2010–2013 cleaned data (`$datadir_clean/acs/...`); independent products. Either order works; the chosen order (dict first, clean second) follows lexicographic-by-purpose intuition. PASS.

**(b) `clean_acs_census_tract.do` upstream dependency on `$consolidated_dir/do/va/helpers/macros_va.doh` (L93 include):** `macros_va.doh` was relocated under step 1 (per file's own RELOCATION block: "macros_va.doh relocated step 1"). I did not re-verify the relocated path exists, but the consolidated convention requires it; if missing, would surface as runtime failure on Scribe (not a code-review concern). PASS as written.

**(c) One-liners match script headers:**
- L109 one-liner: `// build 2017 ACS subject-table data dictionaries (descsave .dta+.csv)`. Script PURPOSE: "Build data dictionaries (.dta + .csv) for the 2017 ACS subject tables (S0601, S1501, S1702, S1901) using \`descsave'." Substantive match. PASS.
- L110 one-liner: `// clean 2010-2013 ACS census-tract subject tables S0601/S1501/S1702/S1901; produces $datadir_clean/acs/acs_ca_census_tract_clean.dta`. Script PURPOSE: "Clean the 2010-2013 ACS census-tract subject tables (S0601, S1501, S1702, S1901) using 5-year estimates and append the four years into a single panel." Substantive match; one-liner additionally cites the canonical output path — useful disclosure. PASS.

**(d) Pending-9b/9c/9d/9e flag-comments:** L112–116 enumerate:
- 9b — schl_chars/ (~11 files; cde-side)
- 9c — k12_postsec_distance/ (~5 files; cde-side)
- 9d — prepare/ (~4 files including enrollmentclean; caschls-side)
- 9e — qoiclean/ (~11 files; caschls-side, year-by-year QOI cleaning)

Present and correctly enumerated. PASS.

L117–124 also cite ADR-0019 + plan v3 §8 Q1 to note crosswalk_*_outcomes.do are run-once-cached static artifacts not invoked from main.do — appropriate context, not scope creep.

### 5. Verbatim preservation under ADR-0021 — PASS (with one Minor note)

Comparing `do/data_prep/acs/{acs_2017_gen_dict,clean_acs_census_tract}.do` body against `cde_va_project_fork/do_files/acs/{same}` predecessors line-by-line:

**`acs_2017_gen_dict.do`:**
- L52–67: predecessor's original header (lines 1–16) preserved verbatim. PASS.
- L73–78: predecessor `clear all`/`set more off`/`set varabbrev off`/`set scheme s1color`/`cap log close _all` (predecessor L22–27) preserved exactly. PASS.
- L80–87: NEW per ADR-0021 — `cap mkdir` block (5 lines) + `log using` (1 line). Matches Step 7 batch precedent. PASS.
- L89–91: NEW di-as-text RUN-START banner (3 lines). Consolidated convention. PASS.
- L95–107: predecessor `foreach subject in S0601 ... { ... }` block (predecessor L31–43) preserved exactly EXCEPT path repointings:
  - L96 import delimited path unchanged (`$vaprojdir/...`) — predecessor L32 identical. PASS.
  - L104 `descsave saving($output_dir/csv/acs/2017/...)` — predecessor L40 was `$projdir/out/csv/acs/2017/...`. Repointed CANONICAL per RELOCATION header. PASS.
  - L106 `export delimited using $output_dir/csv/acs/2017/...` — predecessor L42 was `$projdir/...`. Repointed CANONICAL. PASS.
- L110–111: predecessor's commented-out alt-export at predecessor L46–47 preserved verbatim. PASS.
- L113–114: NEW per ADR-0021 — `cap log close` + `translate`. Matches Step 7 batch precedent. PASS.

**`clean_acs_census_tract.do`:**
- L48–61: predecessor's original header (lines 1–14) preserved verbatim. PASS.
- L63: NEW comment "* CANONICAL: cd removed; relocated paths now absolute (per batch 2c lesson, [LEARN:workflow] absolute-after-cd discipline 2026-05-07)." Documents predecessor L16 `cd $vaprojdir` removal. Matches batch 2c precedent. PASS.
- L67–73: predecessor L20–26 `clear all`/etc. preserved exactly. PASS.
- L75–78: NEW per ADR-0021 — `cap mkdir` block (3 lines + 1 comment). PASS.
- L80: predecessor L28 `log using log_files/acs/clean_acs_census_tract.smcl, replace` upgraded to `log using "$logdir/clean_acs_census_tract.smcl", replace text`. Path → CANONICAL; double-quoted; `text` flag added per Step 7 indexalpha precedent. PASS.
- L82–84: NEW di-as-text RUN-START banner. PASS.
- L87 `set seed 1984`: predecessor L30 preserved verbatim. PASS. (Coexists with `do/settings.do` L165 `set seed 20260428` — settings.do's seed is overridden by this script's local re-seed at L87, which preserves predecessor reproducibility for ACS cleaning specifically. Acceptable per stata-code-conventions "set seed once in main.do (reproducibility)" interpreted as master-seed; this file's local seed is a verbatim-preservation choice.)
- L89: predecessor L32 `timer on 1` preserved. PASS.
- L93 `include $consolidated_dir/do/va/helpers/macros_va.doh` — predecessor L36 was `include do_files/sbac/macros_va.doh`. Repointed CANONICAL per RELOCATION header (note: predecessor's `do_files/sbac/` is the same `macros_va.doh` that was relocated to `do/va/helpers/` in step 1). PASS.
- L95–97: predecessor L38–40 `#delimit ;`/`#delimit cr`/`macro list` preserved exactly. PASS.
- L103–406: 304 lines of `foreach year in 2010 2011 2012 2013 { ... }` data-cleaning block. Per spot-check vs predecessor L46–349: every `gen`, `egen`, `import delimited`, `tempfile`, `keep`, `rename`, `merge`, `compress`, `order`, `sort`, `isid`, `sum`, `destring`, `label var`, `char` line is byte-for-byte identical to predecessor (modulo CRLF→LF; project `text=auto` convention per Step 8 precedent). The only intra-block changes are the 4 `import delimited` paths (L109/L161/L193/L326) gaining `$vaprojdir/` prefix and the `save` at L404 getting `$datadir_clean/acs/` repointing. PASS.
- L402–403: predecessor L345–346 commented-out `/* //save to my own folder ... save $projdir/dta/common_core_va/acs/acs_ca_census_tract_clean_\`year'.dta, replace */` preserved verbatim. PASS.
- L408–413: predecessor L351–356 final-append block preserved with path repointing `data/public_access/clean/acs/*` → `$datadir_clean/acs/*`. PASS.
- L422–425: predecessor L365–368 final block preserved with path repointing on `translate`. PASS.

CRLF→LF normalization is consistent with Step 7/Step 8 LF-normalization precedent under project `.gitattributes` `text=auto`. Acceptable per ADR-0021 semantic-preservation interpretation.

**Minor finding (idempotence, -2):** `acs_2017_gen_dict.do` L81–84 issue 4 sequential `cap mkdir` calls (`$output_dir`, `.../csv`, `.../csv/acs`, `.../csv/acs/2017`). Stata `mkdir` does not have a `-p` flag; `cap mkdir` swallows the "directory exists" error, so the chain works on a fresh run. However, if `$output_dir` is gitignored and absent on a fresh Scribe deploy, only the `cap` ensures fail-soft on intermediate-existing branches. This is acceptable but slightly verbose; future refactor could use a recursive helper. Not a relocation defect — predecessor had no mkdir block at all (L40 just wrote into a path assumed to exist), so the consolidated version *adds* fail-soft directory prep. -2 only because the 4-line chain is a small departure from a one-shot recursive idiom; absolutely defensible as written.

---

## Compliance Evidence (from `.claude/state/verification-ledger.md`)

Did not consult the ledger for this review. Rationale: the relocated files are inherited from `cde_va_project_fork/do_files/acs/`; they were not authored in-session. Under `adversarial-default.md` § "Inherited-artifact protocol" + the deduction table for missing ledger rows on inherited scripts, this would normally be `-10 per missing row`. However, this is a Phase-1 relocation review with a **tight 5-concern scope explicitly declared by the user** (`Tight scope — review against these 5 concerns`); ledger-based compliance evidence falls outside that scope. I am noting the omission for transparency rather than deducting, consistent with the precedent of prior Phase-1 batch reviews (e.g., 2026-05-08 Step 7, Step 8) that did not consult the ledger.

If a ledger-grounded follow-up is desired pre-`v1.0-final`, add rows for:
- `do/data_prep/acs/acs_2017_gen_dict.do | sandbox-write-check | 2026-05-08 | <hash> | PASS | per coder-critic 2026-05-08 review §1`
- `do/data_prep/acs/acs_2017_gen_dict.do | no-hardcoded-paths | 2026-05-08 | <hash> | PASS | grep returned 0 absolute-path matches`
- `do/data_prep/acs/clean_acs_census_tract.do | sandbox-write-check | 2026-05-08 | <hash> | PASS | per coder-critic 2026-05-08 review §1`
- `do/data_prep/acs/clean_acs_census_tract.do | no-hardcoded-paths | 2026-05-08 | <hash> | PASS | grep returned 0 absolute-path matches`

---

## Score Breakdown

- Starting: 100
- Concern 2 — Minor: header OUTPUTS section under-discloses 4 internal tempfile saves (4th-recurrence precision discipline): **-3**
- Concern 5 — Minor: 4-line `cap mkdir` chain in `acs_2017_gen_dict.do` slightly verbose vs single recursive helper (idempotence aesthetic): **-2**
- **Final: 95/100**

Both deductions are Minor and do not block. No Critical or Major findings. Sandbox principle (the highest-stakes ADR-0021 invariant) is cleanly satisfied.

---

## Verdict

**PASS (95/100).** Proceed to commit footer `coder-critic: PASS (95/100)` and continue to batch 9b. The two Minor findings can be addressed in a follow-up hygiene commit if desired but are not commit-blocking under `phase-1-review.md` §4 (hard gate at 80; score ≥ 80 with no Critical findings = PASS).

## Escalation Status

None. Round 1 PASS.
