# Session Log — 2026-05-08: Step 11 deferred files resolved — PHASE 1a §3.3 FULLY COMPLETE

## Goal

Address Step 11 deferral (3 files originally flagged "exploratory; deferred to do/explore/ or do/data_prep/" in main.do Phase 5 flag-comment from Step 7). Per Christina directive 2026-05-08: "address the deferrals, log in detail, thoroughly update TODO."

## Disposition audit

The 3 files were re-investigated to determine actual disposition (not just inherit the original "exploratory" flag):

### `allsvymerge.do` — ACTIVE chain producer (NOT exploratory)

- Predecessor invocation: `caschls/do/master.do:361 do $projdir/do/share/factoranalysis/allsvymerge`. Production pipeline.
- File header: "rename variables in surveys and merge all surveys for overall factor analysis, keeping only the qoimean variables".
- Outputs: `$projdir/dta/allsvyfactor/{formerge/{parent,sec,staff}qoimeans, allsvyqoimeans}` — 4 dtas.
- Consumers: `allsvyqoimeans` is read by Step 7's `imputation.do` (line 66) and `compcasecategoryindex.do` (line 86). These were originally pointing at LEGACY `$caschls_projdir/dta/allsvyfactor/allsvyqoimeans` because Step 11 was deferred.
- **Decision**: relocate ACTIVE to `do/survey_va/allsvymerge.do` (matches Step 7 precedent for factoranalysis-subdir files). Wire into main.do Phase 5 BEFORE imputation.

### `testscore.do` — ACTIVE chain producer (NOT exploratory)

- Predecessor invocation: `caschls/do/master.do:416`. Production pipeline.
- File header: "pull SBAC test score data from Matt dataset to create controls for index regressions using 6th and 8th grade test scores".
- Output: `$projdir/dta/schoolchar/testscorecontrols` — 1 dta.
- Consumer: `testscorecontrols` is read by Step 7's `indexregwithdemo.do:98` and `indexhorseracewithdemo.do:93` (Table 8 panel producers).
- **Decision**: relocate ACTIVE to `do/survey_va/testscore.do`. Wire into Phase 5 BEFORE indexregwithdemo.

### `allsvyfactor.do` — TRULY EXPLORATORY (archive)

- Predecessor invocation: `caschls/do/master.do:365`. Runs in pipeline.
- File header: "exploratory factor analysis for merge dataset with all 3 survey qoi means".
- Reads: `$projdir/dta/allsvyfactor/allsvyqoimeans` (output of allsvymerge).
- Writes: ONLY exploratory diagnostics — `allsvyfactor.csv`, `allsvyscreeplot.png`, `allsvyfactoreigen1.csv`. No persistent dtas. NO chain consumers anywhere in predecessor or consolidated.
- **Decision**: ARCHIVE per ADR-0010 archive convention. Goes to `do/_archive/exploratory/allsvyfactor.do` (verbatim cp).

## Cross-step chain coordination

Active relocations (allsvymerge + testscore) write CHAIN paths now consumed by Step 7. The Step 7 file headers + body reads needed updating from LEGACY `$caschls_projdir` to CHAIN `$datadir_clean`:

1. `imputation.do:66` + `compcasecategoryindex.do:86` — read CHAIN `$datadir_clean/survey_va/allsvyqoimeans` (was LEGACY)
2. `indexregwithdemo.do:98` + `indexhorseracewithdemo.do:93` — read CHAIN `$datadir_clean/schoolchar/testscorecontrols` (was LEGACY)
3. **BONUS catches** during the cross-step audit: `indexregwithdemo.do:95` + `indexhorseracewithdemo.do:91` were ALSO reading LEGACY `$caschls_projdir/dta/schoolchar/schlcharpooledmeans` despite Step 10 batch 10c relocating mattschlchar.do (which writes CANONICAL). Same pair-flow chain regression pattern as Step 9d's splitstaff0414. Repointed to CHAIN `$datadir_clean/schoolchar/schlcharpooledmeans`. Headers updated.

## Operations

1. **Disposition audit** — read all 3 files; checked predecessor master.do invocation; traced chain consumers in consolidated tree.
2. **Active relocations** — Python script: cp + sed transforms + ADR-0021 header insertion + cap mkdir blocks. Path repointings: `$projdir/log/share/factoranalysis/*` → `$logdir/*`; `$projdir/dta/allsvyfactor/*` → `$datadir_clean/survey_va/*`; `$projdir/dta/schoolchar/*` → `$datadir_clean/schoolchar/*`; `$projdir/dta/buildanalysisdata/{analysisready,va}/*` → `$datadir_clean/calschls/{analysisready,va}/*` (CHAIN reads from Step 9f); `$projdir/dta/<other>/*` → `$caschls_projdir/dta/<other>/*` (LEGACY-static).
3. **Mid-pass bug fix** — `allsvymerge.do` reads `$projdir/dta/buildanalysisdata/va/va_pooled_all.dta`. Initial sed mapped to `$caschls_projdir/dta/buildanalysisdata/va/...` (LEGACY) but Step 9f's `clean_va.do` produces CANONICAL `$datadir_clean/calschls/va/va_pooled_all.dta`. Fixed via sed `s|\$caschls_projdir/dta/buildanalysisdata/va/|\$datadir_clean/calschls/va/|g`. Header updated.
4. **Archive** — `allsvyfactor.do` cp verbatim to `do/_archive/exploratory/allsvyfactor.do`. README updated to add as 2nd file in this archive subdir (per Step 8 alpha.do precedent).
5. **Cross-step chain fixes** — sed substitutions in 4 Step 7 files (imputation, compcasecategoryindex, indexregwithdemo, indexhorseracewithdemo). Plus header text updates.
6. **main.do Phase 5 wiring** — allsvymerge.do INSERTED before imputation.do; testscore.do INSERTED before indexregwithdemo.do; Phase-5 docstring updated to reference Steps 9f + 10 + 11 chain reads (was "$caschls_projdir/dta/allsvyfactor/* LEGACY"); Step 11 flag-comment removed and replaced with COMPLETE marker.
7. **Tier 2 dispatch** (`6791dec`): **PASS 96/100**. -3 adversarial-default residual (verification ledger rows missing/stale); -1 visual-vs-hash verbatim verification of archived body. **All 5 in-scope concerns PASS** including the load-bearing cross-step chain coordination (6 chain paths fully closed-loop including the 2 BONUS Step 10 catches).

## Files changed

- `do/survey_va/allsvymerge.do` (new; 65 body + ADR-0021 header)
- `do/survey_va/testscore.do` (new; 49 body + ADR-0021 header)
- `do/_archive/exploratory/allsvyfactor.do` (new; verbatim cp; 28 lines)
- `do/_archive/exploratory/README.md` (updated — added allsvyfactor.do entry)
- `do/main.do` (Phase 5 wiring update)
- `do/survey_va/imputation.do` + `compcasecategoryindex.do` + `indexregwithdemo.do` + `indexhorseracewithdemo.do` (cross-step chain reads repointed)
- `quality_reports/reviews/2026-05-08_step-11-deferred-resolved_coder_review.md` (PASS 96/100)
- `quality_reports/reviews/INDEX.md`
- this session log

## Phase 1a §3.3 GRAND retrospective — COMPLETE 2026-05-08

| Step | Files | Notes |
|---|---:|---|
| 1 | helpers/macros | foundational |
| 2 | samples + merge helpers | 3 batches; chain-critical |
| 3 | VA estimation | 4 batches (3a-3d); ~870-2220 lines per |
| 4 | heterogeneity | small batch |
| 5 | sibling crosswalk | per ADR-0005 |
| 6 | siblingvaregs archive | 27 files per ADR-0004 |
| 7 | survey VA | 9 active relocations; round-2 after factor.do:131 fix |
| 8 | alpha.do archive | 1 per ADR-0010 |
| 9 (extended) | data prep | **41 files across 7 batches** (9a-9g); mean ~91/100 |
| 10 | share/ paper producers | 21 files across 3 batches; mean ~84/100 |
| 11 | deferred files resolved | 2 ACTIVE + 1 ARCHIVE; PASS 96/100 |

**TOTAL: 148 files. 27 coder-critic PASS verdicts. Chain reads/writes coordinated end-to-end across all batches.**

## Process learnings (10 cumulative; ready to codify in MEMORY.md)

1. Settings.do globals enumerated upfront from predecessor.
2. Cross-script chain coordination after every relocation.
3. Python regex whitespace-tolerant.
4. Stata `\`name'` macro vs `\w+` regex.
5. Translate inconsistencies (`.txt` vs `.log`; missing-space).
6. Even gated LEGACY writes are violations.
7. cap mkdir blocks must match actual write targets.
8. Helper relocations ripple to callers.
9. Multi-year `\`year'` loops — INPUTS enumerate year-set.
10. Initial inventory counts can be wrong — recount during setup.

## TODO cleanup

Per Christina directive: "thoroughly update the todo. there are some stale items at the bottom."

**Stale items removed:**

1. Lines 47-58 of pre-cleanup TODO — old "Per plan v3 §3.3 step 9" + pre-batch checklist (Step 9 done; checklist applied; learnings codified above).
2. Lines 60-67 — old "Remaining Phase 1a §3.3 steps" table showing Step 9 NEXT and Step 10 "After 9" (both COMPLETE).
3. Lines 69-73 — old "Options for next code work (Christina picks)" — A/B/C all done weeks ago.
4. Lines 100-109 "Up Next" — listed Phase 1a §3.3 as future work (now done).
5. Lines 137-157 Done section — pruned from 19 entries down to 8 most-recent (per `[LEARN:workflow]` 2026-05-07 hygiene-discipline).

**New TODO structure:**

- Active: Phase 1a §3.5 (M4 golden-master verification)
- Phase 1a §3.3 — COMPLETE table (per-step status)
- Up Next (post §3.3): §3.5, §4.x bug fixes, §5.x cosmetic + acceptance
- Per-commit review discipline (active through `v1.0-final`)
- Process learnings cumulative (10 entries)
- Resolved sections (T1, codebook, T4) — collapsed to one-liners
- Backlog (3 items)
- Done (last ~10)

## Status

- **Phase 1a §3.3:** **COMPLETE — 148 files across 11 steps.**
- **Coder-critic audit trail:** 27 PASS verdicts.
- **Tree:** dirty pre-hygiene-commit.

## Next

**§3.5 Golden-master verification (M4)** per ADR-0018 — first gate before `v1.0-final` tag. Verifier in submission mode runs `diff -r consolidated/output predecessor/output` on a fresh end-to-end Scribe run. Coordination required: Christina runs the consolidated pipeline on Scribe; agent compares outputs and reports.
