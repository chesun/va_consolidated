# Pre-Flight Audit Partition D — do/share/ + do/survey_va/ + do/explore/ — coder-critic

**Date:** 2026-05-16
**Reviewer:** coder-critic
**Target:** Phase 1a pre-flight audit, Partition D = `do/share/` (19 files) + `do/survey_va/` (12 files) + `do/explore/` (1 file) = 32 files total; pre-Scribe golden-master review (§3.5 M4 next)
**Score:** 78/100 **BLOCK**
**Status:** Superseded by quality_reports/reviews/2026-05-16_pre-flight-D-round2_share-surveyva-explore_coder_review.md

---

## Verdict

**BLOCK — 2 CRITICAL chain regressions on `analysisready.dta` reads** (3 files: `factor.do`, `pcascore.do`, `allvaregs.do`) confirm the dominant failure-mode pattern surfaced by Partitions B/C. Step 11 fixed 4 of the affected files (`imputation`, `compcasecategoryindex`, `indexregwithdemo`, `indexhorseracewithdemo`) but missed these 3. At runtime under the consolidated pipeline, these 3 files will silently re-read predecessor LEGACY data instead of the CANONICAL `$datadir_clean/calschls/analysisready/{sec,parent,staff}analysisready.dta` produced upstream by `do/data_prep/poolingdata/{secpooling,parentpooling,mergegr11enr}.do`. Because the predecessor and consolidated copies of the analysisready files MAY differ (the consolidated copy is the only one the Phase 1 data-prep is sandbox-tested to produce), this breaks the diff-r comparability ADR-0021 was designed for, and risks downstream factor-analysis + Table 8 results computing off stale data.

Plus 1 MAJOR (CONVENTIONS section absent across all 32 files) and 2 MINOR findings.

Aggregate: 100 - 15 (Critical C1, capped: 1 chain class × 3 files but treated as one logical bug class) - 5 (Major M1 ADR-0021 header convention) - 2 (Minor) = **78/100 BLOCK**.

---

## Scope of audit

19 files in `do/share/`, 12 files in `do/survey_va/`, 1 file in `do/explore/`. Pre-flight is a holistic re-review before the M4 golden-master execution on Scribe; per-batch reviews (Step 7, 10a, 10bc, 11) approved these files individually but the cross-step coordination check is the new pre-flight contribution.

Tools used:
- Full-tree `grep -nE '^\\s*(save|export|...)' do/{share,survey_va,explore}` → write-discipline scan
- Full-tree `grep -nE '\\$(matt_files_dir|vaprojdir|caschls_projdir|nscdtadir|rawdtadir|clndtadir|cstdtadir)' do/{share,survey_va,explore}` → LEGACY-reference scan
- For each CANONICAL CHAIN read, traced via `grep -nE 'save.*<name>' do` to confirm a producer in the consolidated pipeline
- Header-convention scan: `grep -E 'PURPOSE|INVOKED FROM|CONVENTIONS|REFERENCES' do/{share,survey_va}/*.do`
- Read main.do Phase 5 + Phase 6 invocation order for chain consumers/producers

---

## Findings

### CRITICAL C1 — Chain regression: stale LEGACY reads of `analysisready.dta` in 3 files

The Phase 1 data-prep pipeline produces CANONICAL `$datadir_clean/calschls/analysisready/{sec,parent,staff}analysisready.dta` via:

- `do/data_prep/poolingdata/secpooling.do:160` → `secanalysisready`
- `do/data_prep/poolingdata/parentpooling.do:152` → `parentanalysisready`
- `do/data_prep/poolingdata/mergegr11enr.do:93` → `staffanalysisready`

Three consumers in this partition still read the LEGACY predecessor location `$caschls_projdir/dta/buildanalysisdata/analysisready/`:

| File | Lines | What it reads (LEGACY) | Should read |
|---|---|---|---|
| `do/survey_va/factor.do` | 74, 92, 110 | `$caschls_projdir/dta/buildanalysisdata/analysisready/{sec,parent,staff}analysisready` | `$datadir_clean/calschls/analysisready/{sec,parent,staff}analysisready` |
| `do/survey_va/pcascore.do` | 65, 74, 83 | same | same |
| `do/share/svyvaregs/allvaregs.do` | 113 | `$caschls_projdir/dta/buildanalysisdata/analysisready/\`svyname'analysisready` (loop over sec/parent/staff) | `$datadir_clean/calschls/analysisready/\`svyname'analysisready` |

**Confirmation of regression scope:** Step 11 review explicitly addressed the analogous chain for `imputation.do`, `compcasecategoryindex.do`, `indexregwithdemo.do`, `indexhorseracewithdemo.do` — these 4 files were repointed to read CANONICAL during Step 11 (see review L152). The Step 11 fixer-set did NOT include `factor.do`, `pcascore.do`, or `allvaregs.do`. Those three slipped through.

**Why it matters:**
- ADR-0021 sandbox principle: `diff -r consolidated/output predecessor/output` cleanly compares. If 3 of the 14 survey_va/share-svy files read from a different upstream than their sister files, the comparison breaks for any output that flows through them.
- Production runs: at M4 golden-master execution, `factor.do` and `pcascore.do` are explicitly intermediate-exploratory (header at `factor.do:17` says "intermediate exploratory; not paper-shipping"), but `allvaregs.do:113` IS paper-shipping (svyvaregs umbrella; produces Table 8 inputs per main.do:407).
- Reproducibility: if the predecessor `analysisready.dta` gets removed or modified outside the consolidated sandbox, these 3 files break silently while their sister files keep working.

**Severity calibration:** Per quality.md §3 Stata Scripts table — "Domain-specific bugs (wrong clustering, wrong estimand)" is -30; "Code doesn't match strategy memo" is -25. This is a code-strategy mismatch on the ADR-0021 sandbox principle. Treated as one logical bug class (3 files all have the same defect from the same Step 11 omission). **Deduction: -15** (between "missing robustness checks" at -15 and "domain-specific bugs" at -30, weighted by paper-shipping impact only on the 1 of 3 — `allvaregs.do`).

**Recommended fix:** Repoint the 7 reads (4 in factor.do, 3 in pcascore.do, 1 templated in allvaregs.do) from `$caschls_projdir/dta/buildanalysisdata/analysisready/` to `$datadir_clean/calschls/analysisready/`. Update each file's header INPUTS list to match. Verify the file header's RELOCATION block declares this as a "CHAIN read from Step 9f poolingdata producers (was $caschls_projdir/dta/buildanalysisdata/analysisready/ LEGACY)" mirroring the Step 11 README convention.

---

### MAJOR M1 — Header convention deviation: CONVENTIONS section absent partition-wide

ADR-0021 description convention requires a four-section header block: **PURPOSE / INVOKED FROM / CONVENTIONS / REFERENCES**. Across all 32 in-scope files:

- PURPOSE: present in 32/32 ✓
- INVOKED FROM: present in 31/32 ✓ (codebook_export.do uses INSTRUCTIONS instead — defensible per its standalone-diagnostic role declared in header)
- CONVENTIONS: present in **0/32** ✗ — the literal string "CONVENTIONS" appears nowhere in any file under `do/share/`, `do/survey_va/`, or `do/explore/`
- REFERENCES: present in 23/32 (20 share + 3 survey_va: allsvymerge, testscore, mattschlchar) — the other 9 survey_va files use `RELOCATION` + `ADRs:` blocks instead

The substantive equivalent of CONVENTIONS is captured in the RELOCATION block (path-repoint table) + the explicit INPUTS/OUTPUTS lists. Information is present, structure deviates from spec. This is the third pre-flight partition to surface this — likely a workflow-wide pattern, not partition-specific.

**Deduction: -5** (Stata-Scripts "No documentation headers" floor is -5; substance present so not full deduction; partition-wide so floor binds anyway).

**Recommended fix:** This is workflow-wide. Either (a) update ADR-0021 description convention to permit RELOCATION as the CONVENTIONS-equivalent for relocation-context headers, OR (b) add explicit CONVENTIONS sections in a pass across all relocated files. Option (a) is the cheaper resolution given Phase 1a §3.3 is complete.

---

### MINOR M2 — Hardcoded absolute path in `do/survey_va/mattschlchar.do:69`

Line 69: `use /home/research/ca_ed_lab/msnaven/common_core_va/data/sch_char, clear`

Inside an `if \`clean' == 1` gate; default `local clean = 0` at line 67, so dormant. Header at line 16 declares the hardcoded path as "LEGACY hardcoded; per ADR-0013 dormant rebuild branch". Code-quality smell but disclosed; the dormancy gate keeps it from executing in the default pipeline.

**Deduction: -1**. ADR-0013 documents the gate-as-shield decision; not a regression, but the hardcode is conspicuous.

---

### MINOR M3 — Hardcoded absolute paths in `do/share/outcomesumstats/nsc2019new/k12_nsc2019_merge.doh:67, 82`

Two hardcoded reads of `/home/research/ca_ed_lab/msnaven/data/public_access/clean/k12_public_schools/k12_public_schools_clean.dta`. Header at line 13 declares them as "LEGACY hardcoded; per ADR-0013 dormant rebuild branch". The `.doh` is a helper included by callers (per main.do:408 comment, NOT directly invoked from main.do).

**Deduction: -1**. Same pattern as M2; disclosed in header; not pipeline-active under default toggles.

---

### Verified PASS (no deductions)

- **Sandbox write discipline (ADR-0021):** zero LEGACY writes in any of the 32 files. Every `save`/`export`/`graph export`/`esttab using`/`texsave`/`regsave using`/`export excel`/`translate`/`log using` targets CANONICAL: `$logdir/`, `$datadir_clean/`, `$estimates_dir/`, `$output_dir/`, `$tables_dir/`, `$figures_dir/`. `do/explore/codebook_export.do` writes to a script-local `log_files/codebooks/` per declared standalone-diagnostic role — out of scope for ADR-0021 sandbox.
- **Step 11 cross-step chain coordination (`testscore`, `mattschlchar`, `allsvymerge`):** producers (mattschlchar:151 schlcharpooledmeans, testscore:97 testscorecontrols, allsvymerge:122 allsvyqoimeans) all write CANONICAL; consumers (indexregwithdemo:91/95/98, indexhorseracewithdemo:91/93, imputation:66, compcasecategoryindex:86) all read the same CANONICAL paths.
- **Step 10 chain coordination (siblingmatch → uniquefamily → siblingpairxwalk → allvaregs):** verified — siblingmatch:116/152 writes `$datadir_clean/siblingxwalk/k12_xwalk_name_address[_year]`, uniquefamily:124 writes `ufamilyxwalk`, siblingpairxwalk:94/126 writes sibling crosswalks. All CANONICAL chain reads.
- **base_sum_stats_tab.do CANONICAL self-cache (line 256 ↔ 261):** save then use in the same file via `$datadir_clean/share/base_nodrop.dta` — clean self-loop, not a producer-consumer chain.
- **`indexalpha.do`, `indexhorserace.do`, `imputedcategoryindex.do`, `compcasecategoryindex.do` chain reads:** all read `$datadir_clean/survey_va/categoryindex/{type}categoryindex.dta` produced by imputedcategoryindex:177 + compcasecategoryindex:178 (run earlier in same Phase 5). Order verified in main.do.
- **`do/explore/codebook_export.do`:** explicitly standalone-diagnostic per its header; hardcoded paths are intentional per declared role (runs on predecessor Scribe layout, not on consolidated sandbox). Out of scope for ADR-0021 sandbox-write discipline.
- **Translate-line normalization:** all 31 active pipeline files have correctly-formed `translate $logdir/<x>.smcl $logdir/<x>.log, replace` invocations. The sed-mistranslation pattern that BLOCKED `factor.do` at Step 7 round-1 is fully resolved (factor.do:131 verified clean). `indexhorseracewithdemo.do:209-210` uses multi-line ABS form correctly.
- **`$projdir` references:** all in-scope `$projdir` occurrences are inside `/* */` comment blocks (header / change-log paraphrases) — no executable references to the unbound `$projdir` global.
- **Helper-doh include trace:** active `include` statements all point to `$consolidated_dir/do/va/helpers/{macros_va,drift_limit}.doh` or `$consolidated_dir/do/samples/<x>.doh` (CANONICAL). The `do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only` at base_sum_stats_tab.do:198 + 403 is a LEGACY include of Matt's untouched .doh per ADR-0017 (documented LEGACY).

---

## Compliance Evidence (from `.claude/state/verification-ledger.md`)

Consulted ledger for adversarial-default required checks; current ledger rows for the 32 files in scope:

- `do/share/{19 files} | adr-0021-sandbox-write | (MISSING — partition-wide) — Step 10 reviews (10a, 10bc) verified at commit time; rows not promoted to ledger
- `do/survey_va/{12 files} | adr-0021-sandbox-write | (MISSING — partition-wide) — Step 7 + Step 11 reviews verified; rows not promoted to ledger
- `do/explore/codebook_export.do | (out of scope — standalone diagnostic, declared in header) — N/A
- `do/share/svyvaregs/allvaregs.do | chain-read-canonical-analysisready | (MISSING — flagged FAIL via this review)` — finding C1
- `do/survey_va/factor.do | chain-read-canonical-analysisready | (MISSING — flagged FAIL via this review)` — finding C1
- `do/survey_va/pcascore.do | chain-read-canonical-analysisready | (MISSING — flagged FAIL via this review)` — finding C1

Per `adversarial-default.md` Minor row "Ledger row exists, PASS, but Evidence is vague": -3 for not having ledger-cached PASS rows. Folded into the partition-wide M1 deduction.

---

## Score Breakdown

- Starting: 100
- Critical C1 (analysisready chain regression × 3 files, one logical bug class, mixed paper-shipping impact): **-15**
- Major M1 (CONVENTIONS section absent partition-wide; partition-wide pattern, ADR-0021 4-section convention): **-5**
- Minor M2 (hardcoded path in mattschlchar.do, gated dormant, disclosed in header): **-1**
- Minor M3 (hardcoded paths in k12_nsc2019_merge.doh, gated dormant, disclosed in header): **-1**
- Adversarial-default: subsumed into M1 (-3 conceptual deduction not double-counted)
- **Final: 78/100 BLOCK**

Hard gate at 80/100 per phase-1-review.md §4 → **BLOCK**.

---

## Escalation Status

None — single round, first dispatch on this partition target. Findings are concrete, fix is mechanical (7 line edits across 3 files). Re-dispatch after Christina applies the C1 fix.

---

## Recommended next steps for Christina

1. **Resolve C1 (CRITICAL, blocking):** Repoint 7 reads from `$caschls_projdir/dta/buildanalysisdata/analysisready/` to `$datadir_clean/calschls/analysisready/` across these 3 files. Update each file's INPUTS section in the header. Single-line edits each:
   - `do/survey_va/factor.do:74`, `:92`, `:110`
   - `do/survey_va/pcascore.do:65`, `:74`, `:83`
   - `do/share/svyvaregs/allvaregs.do:113` (templated by `\`svyname''` loop variable)
2. **Defer M1 to a workflow-wide ADR (optional):** Either update ADR-0021 to permit RELOCATION as the CONVENTIONS-equivalent, OR add explicit CONVENTIONS sections in a sweep. Recommend (a) — substance is preserved; cost of (b) is high relative to safety improvement.
3. **Defer M2 + M3 (Minor, both gated dormant):** Document in Phase 1c §5.1 dead-code review batch for archive-or-keep decision per ADR-0013.

After C1 is fixed, re-dispatch coder-critic on the 3 modified files to confirm chain coordination. Expected re-review score ≥ 92 if only C1 is addressed; ≥ 95 if M1 is also resolved.
