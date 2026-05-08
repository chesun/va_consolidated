# TODO — VA Consolidated (CEL Value-Added Project)

Last updated: 2026-05-08 (after Step 9 batch 9d commits `677033f` + fix `c35e22a` — **PASS round 2 87/100** — 4 caschls/prepare files relocated)

## Active (next-up)

- [ ] **Phase 1a §3.3 IN PROGRESS — 105 of ~150 files relocated/archived. Steps 1-8 + Step 9 batches 9a+9b+9c+9d COMPLETE.** Remaining: Step 9 batch 9e (11 qoiclean files) + Step 10 (~50 share/).

### Step 9 — Data prep (~33 files; Christina-owned) IN PROGRESS — batch 9b NEXT

**Inventory + 5-batch plan:** `quality_reports/plans/2026-05-08_step-9-data-prep-inventory.md` (committed `a6cd5f2`).

**Batch progress:**

| Batch | Source | Files | Status | Score |
|---|---|---:|---|---|
| 9a | `cde/do_files/acs/` | 2 | LANDED `4a88874` | PASS 95/100 |
| 9b | `cde/do_files/schl_chars/` | 11 | LANDED `40cb161` + fix `9478ded` | PASS 92/100 (round 1) |
| 9c | `cde/do_files/k12_postsec_distance/` | 5 | LANDED `4403758` + fix `02b5189` | PASS 84/100 (round 1) |
| 9d | `caschls/do/build/prepare/` | 4 | LANDED `677033f` + fix `c35e22a` | PASS round 2 87/100 |
| 9e | `caschls/do/build/buildanalysisdata/qoiclean/` | 11 | NEXT | — |

**Out-of-named-scope discovered:** `caschls/do/build/buildanalysisdata/poolingdata/` (5) + `responserate/` (4) — defer Christina-decision to end of Step 9.

Per plan v3 §3.3 step 9. Relocate Christina-owned cleaning files from mixed predecessor sources to `do/data_prep/` (subdirs: `acs/` ✓, `schl_chars/`, `k12_postsec_distance/`, `prepare/`, `qoiclean/`). Apply Step 7 active-relocation methodology (header + sed path repointing + main.do Phase wiring).

**Pre-batch checklist (carry forward; per `[LEARN:discipline]` lessons in MEMORY.md):**

1. Inventory source files (mixed sources: `cde_va_project_fork/do_files/...` + `caschls/do/...`).
2. **Absolute paths after `cd $vaprojdir`** — convention from batch 2c bugfix.
3. ADR-0021 conventions: header, sandbox-write check (now-extended grep `'save|export|esttab using|graph export|outsheet|outreg2 using|texsave|^\s*translate |log using'` per commit `3f05995`), LEGACY-include macro-trace.
4. **Always grep before claiming a local/macro is undefined** (batch 3b lesson).
5. **Always grep BOTH inputs AND outputs before writing the header** (batches 3d + Step 4 lessons — 4th-recurrence discipline).
6. **Tier-1 grep extension catches sed-mistranslated `translate`/`log using` paths** (Step 7 lesson — see `[LEARN:discipline]` 2026-05-08).
7. Watch for `$projdir` references in caschls files (per [LEARN:stata] siblingoutxwalk pattern: alias-before-include or pre-emptive repoint).
8. Likely sub-batches given size (~30 files): inventory first, propose batch split before starting.

### Remaining Phase 1a §3.3 steps

| Step | Description | Source | Destination | Approx files | Status |
|---|---|---|---|---:|---|
| 9 | Data prep (Christina-owned; `enrollmentclean.do`, `acs/`, `schl_chars/`, `k12_postsec_distance/`, `prepare/`, `caschls_qoiclean/`) | mixed | `do/data_prep/` | ~30 | NEXT |
| 10 | share/ paper producers (everything in `cde_va_project_fork/do_files/share/` + `caschls/do/share/` minus deprecated subtrees) | mixed | `do/share/` | ~50 | After 9 |
- [x] ~~**Christina: mark plan v3 APPROVED**~~ — APPROVED 2026-04-29 (`949b452`). Plan v3 status flipped DRAFT → APPROVED.
- [ ] Phase 1 sub-phase structure (locked): 1a consolidate (behavior-preserving) → 1b bug fixes by priority → 1c cosmetic. File ownership constraint: Matt Naven's files stay UNTOUCHED per ADR-0017.

### Options for next code work (Christina picks; in priority order)

- [x] ~~**Option A — pre-draft `do/check/check_*.do` skeletons**~~ — DONE 2026-04-29 (`d775efe`); 84/100 PASS.
- [x] ~~**Option B — pre-draft README.md skeleton**~~ — DONE 2026-04-29 (`053871e`); 86/100 PASS.
- [x] ~~**Option C — begin Phase 1a §3.3 with `siblingoutxwalk.do`**~~ — STARTED 2026-04-30 (`275efc0`); first real production relocation landed; precedent established for the remaining ~150 relocations.

### Per-commit review discipline (active)

Every Phase 1 code commit goes through coder-critic at 80/100 hard gate per `.claude/rules/phase-1-review.md`. Commit message footer convention:

- Code commits: `coder-critic: PASS (XX/100)`
- Cosmetic / out-of-scope: `coder-critic: skipped (rationale: ...)`

Audit trail: `git log --grep='coder-critic'`. Entries: `e1cbc56`, `9120754`, `d775efe`, `275efc0`, `7983a8d`, `94fd2b8`, `5de34a7`, `90700c2`, `223e9b2`, `4ee0b58`, `9e102fd`, `421333f`, `ccc2600`, `c84371f`, `b8b4ce8`, `3e99c3b` (retroactive round 2 94/100 after `factor.do:131` fix `68cf30e`), `8fe1f28` (Step 8 alpha.do archive 97/100), `4a88874` (Step 9 batch 9a 95/100), `40cb161` (Step 9 batch 9b 92/100 + fix `9478ded`), `4403758` (Step 9 batch 9c 84/100 + fix `02b5189`), `677033f` (Step 9 batch 9d 67/100 BLOCK round 1 + fix `c35e22a` round 2 PASS 87/100 — `quality_reports/reviews/2026-05-08_step-9-batch-9d_coder_review.md`). (Plus writer-critic dispatches for doc commits: `053871e`.) Note: pre-`275efc0` SHAs were rewritten 2026-04-30 by `git filter-repo` (OpenCage history strip); refs in markdown use post-rewrite SHAs.

## T1 Tests for Christina (run on Scribe when convenient — ~5-15 min in one session)

Consolidated as a single .do file at `do/check/t1_empirical_tests.do` (2026-04-27). **Reduced from 5 to 3 tests after ADR-0017 retired Matt-Naven-file tests (T1-1, T1-2).**

- [x] **T1-3** — `school_id == cdscode` 1:1 check — **VERDICT: 1:1 (N=5009).** Cosmetic rename only in Phase 1. Resolves P2-3, P2-11. — 2026-04-27
- [x] **T1-4** — mtitles count test — **BUG FIRED** (49/33/33/33 cols vs 24 declared). Per Q-6, CSVs don't feed paper → cosmetic. — 2026-04-27
- [x] **T1-5** — Revoke OpenCage API key — **RESOLVED 2026-04-30 (Christina revoked the key + history-stripped from repo).**

**Retired:**
- ~~T1-1 — `crosswalk_nsc_outcomes.do:250` `id` macro~~ — file is Christina's (per ADR-0019, refining ADR-0017) but **out of scope by time-budget** in Phase 1: file not pipeline-active, paper blast radius for Bug 93 null, ½-day fix not justified vs. offboarding acceptance run.
- ~~T1-2 — Bug 93 family count (4 instances)~~ — NSC instances in Christina's file (per ADR-0019) but out of scope by time-budget; CCC/CSU instances in Matt's files (`merge_k12_postsecondary.doh`) per ADR-0017.

**Removed earlier (resolved by Christina 2026-04-26 FB-test correction):**
- ~~Column 6 FB rows blank?~~ — NOT A BUG (intentional, FB-test structural property)
- ~~`predicted_score==0` filter?~~ — NOT A BUG (separate dirs, no conflation)

## Up Next

- [ ] **Phase 1a §3.3 script relocation** (the bulk of Phase 1a — ~6 weeks). Each file move is one commit; coder-critic dispatch on each per phase-1-review rule. Order: helpers/macros → samples → VA estimation → heterogeneity/pass-through → sibling crosswalk → siblingvaregs deprecation → survey VA → data prep → share/.
- [ ] **Phase 1a §3.5 golden-master verification** (M4) at end of §3.3. Verifier in submission mode; the canonical relative regression check (predecessor vs consolidated outputs).
- [ ] **Phase 1b bug fixes by priority** — code corrections (ADR-0011 sums→means, P3 typos) → naming/clarity (ADR-0016 pooledrr rename, ADR-0015 Filipino-into-Asian comment, ADR-0013 mattschlchar dormant-branch comment). **Paper-text corrections (ADR-0010 footnote, ADR-0014 old-draft note) DEFERRED post-handoff per Christina 2026-05-07** — out of scope for consolidation; coordinate with senior coauthor on a separate timeline. Plan v3 §4.1 effectively retired.
- [ ] **Phase 1c §5.1 cosmetic cleanup** — dead-code archival, log/translate sweep (per-do-file logging convention from §5.1 step 2).
- [ ] **Phase 1c §5.2 README polish + cold-read** (PRE-DRAFT done as Option B `053871e`; writer-critic 86/100; 2 Minors deferred to §5.4 polish: m1 em-dash density, m7 status-note Phase-1c jargon). Final polish + cold-read test occur at §5.4. File transfer is operator-choice per ADR-0020.
- [ ] **Phase 1c §5.2 step 8 — offboarding deliverable memo at `quality_reports/handoff/`** (per ADR-0018). Stub created `053871e`. Memo content per `quality_reports/handoff/README.md`. **Specific Christina action when writing the memo:** sweep for residual *semantic* codebook ambiguities (e.g., specific NSC sector codes she knows but never wrote down) — last chance to externalize codebook-authority knowledge before deposit, since post-`v1.0-final` no fallback exists (no provider PDFs; Kramer is custodian-not-maintainer).
- [ ] **Phase 1c §5.3 data checks — TBD-codebook resolution.** Six skeletons pre-drafted as Option A (`d775efe`); each runnable as no-op via capture-confirm-file shim; becomes a real check post-Phase-1a §3.3. TBD-codebook markers (NSC merge rate; CCC/CSU match-level==1 share; paper-table cell magnitudes) resolve as Phase 1a §3.5 golden-master + first production runs supply baselines.
- [ ] **Phase 1c §5.4 acceptance run** (per ADR-0018) — `stata -b do do/main.do` on Scribe with `run_data_checks 1`; README cold-read test by friendly non-Christina lab member. BOTH must pass before `v1.0-final` tag.

## Open T4 escalations (require Christina input at Phase 0e)

**ALL RESOLVED 2026-04-27** in `quality_reports/audits/2026-04-27_T4_answers_CS.md`. ADRs 0004-0016 operationalize. Q-14 (special-ed/home-instruction restrictions) deferred per Christina's "honestly no idea, took from Matt" answer.

## Codebook export for Christina (run on Scribe — for plan v3 §5.3 data checks)

Single .do file at `do/explore/codebook_export.do`. Produces a consolidated codebook log Claude needs to design the Phase 1c automated data-checks pipeline. ~5-15 min runtime.

**Status 2026-04-28**: COMPLETE. First run surfaced PII in `codebook` Examples blocks; remediated by (1) adding `master_supporting_docs/codebooks/` to `.gitignore` and (2) editing the script to `cap drop` known PII columns before `describe`/`codebook`. Christina re-ran; sanitized log at `master_supporting_docs/codebooks/codebook_export_28-Apr-2026_13-25-41.log` (3.8 MB, gitignored, PII-scrub fired in all 10 datasets). Findings extracted to **`quality_reports/reviews/2026-04-28_data-checks-design.md`** — ~250-line design memo covering all six future `do/check/check_*.do` files (assertions, Likert ranges, sample-size invariants, codebook line refs).

- [x] Verify dataset paths in §0 — done; all 10 datasets loaded without [SKIP].
- [x] First run on Scribe — done.
- [x] PII-scrub re-run on Scribe — done.
- [x] Extract findings into data-checks design memo — done (`quality_reports/reviews/2026-04-28_data-checks-design.md`).

## Waiting On

- [x] ~~Christina T1-5 (revoke OpenCage API key — manual action)~~ — RESOLVED 2026-04-30 (key revoked + history-stripped from repo via git-filter-repo). T1-3 and T1-4 RESOLVED 2026-04-27.
- [ ] Christina codebook-export run on Scribe (above section). Not blocking Phase 1a start; needed before Phase 1c §5.3 finalizes.

## Backlog

- [ ] ~~Bug 93 (NSC UC inlist precedence) — P1 fix during Phase 1~~ — RETIRED per ADR-0017 (Matt's files untouched in Phase 1)
- [ ] Universal hook fix in workflow repo (status: shipped + propagated; only filter-ordering edge case remains, low priority)
- [ ] Stata version compatibility revisit (post-consolidation, pre-submission)

## Done (recent — last ~10 entries; older completions in session logs + git history per `todo-tracking.md` rule 6)

- [x] **Phase 1a §3.3 step 3 batch 3c2 — 6 outcome-regression files** (`reg_out_va_all` + `_tab` + `_fig` × {regular, dk}) relocated via script-based methodology (sed for 8 path patterns + Python for ADR-0021 header insertion + mkdir + RUN-START block). ~2220 body lines. New `gph_files` routing convention: intermediate `.gph` → `$output_dir/gph_files/...`; paper-shipping `.pdf` → `$figures_dir/...`. Charter status data KEPT LEGACY (Step 9 deferred). Round-1 critic finding M1 (-3): stale TODO in main.do referencing now-relocated files — fixed in-commit. Coder-critic 87/100 PASS. (`421333f`) — 2026-05-07
- [x] **Hygiene + MEMORY.md learnings** — TODO + SESSION_REPORT (+ `.claude/` mirror) + new session log for batches 3c1/3c2; 2 `[LEARN]` entries in MEMORY.md (script-based relocation methodology + `gph_files` routing convention). (`4c4ec81`, `712f803`) — 2026-05-07
- [x] **TODO maintenance fix + 1 LEARN entry** — Christina caught Done section drift (~50 stale 2026-04-* entries; missing 6 recent batches). Pruned per todo-tracking.md rule 6 (~10 most recent). Added `[LEARN:workflow]` codifying the hygiene-commit-must-update-Done-and-prune discipline. (`3503765`) — 2026-05-07
- [x] **Phase 1a §3.3 step 3 batch 3d — 3 sibling-lag diagnostic files** (`va_score_sib_lag`, `va_out_sib_lag`, `va_sib_lag_spec_fb_tab`) relocated to `do/va/`. Diagnostic-only per do_all.do. **Brace-misplacement bug in main.do wiring caught + fixed before push** (Python script landed batch 3d invocations OUTSIDE the `if `do_va'' block; corrected via Edit). One round-1 critic finding (M1 -3): header-vs-code mismatch in va_sib_lag_spec_fb_tab.do (declared CSV outputs that don't get written; actually appends .dta to spec_test/fb_test) — derive-don't-guess violation, FIXED in-commit by rewriting OUTPUTS section. **STEP 3 NOW COMPLETE.** Coder-critic 95/100 PASS. (`ccc2600`) — 2026-05-08
- [x] **Phase 1a §3.3 step 4 — 4 heterogeneity files** (`va_het`, `va_corr_schl_char`, `va_corr_schl_char_fig`, `persist_het_student_char_fig`) relocated to `do/va/heterogeneity/`. Plan v3 mentioned `pass_through/` but predecessor has no such directory; Step 4 = 4 files only. One round-1 critic finding (M2 -7, Major strict-phase): `persist_het_student_char_fig.do` header INPUTS section had boilerplate sch_char/va_all references that the body doesn't read (body only reads `.gph` from `$output_dir/gph_files/`); fixed in-commit by rewriting INPUTS to match body grep at L97-101. Lesson recurrence — discipline now extends to BOTH OUTPUTS and INPUTS. Coder-critic 91/100 PASS. (`c84371f`) — 2026-05-08
- [x] **Phase 1a §3.3 step 6 — 27 deprecated siblingvaregs files archived** to `do/_archive/siblingvaregs/`. First archive-convention batch (bodies preserved verbatim per ADR-0021; not invoked from main.do). 2 files NOT archived per ADR-0004's "verify before archiving" caveat: `siblingoutxwalk.do` (already relocated to `do/sibling_xwalk/` per ADR-0005); `vafilemacros.doh` (still consumed by ACTIVE relocated code in siblingoutxwalk.do + prior_decile_original_sample.do — kept LEGACY-static at predecessor location). README at `do/_archive/siblingvaregs/README.md` documents archive scope + exclusion rationale. One Minor critic finding (README count nits) FIXED in-commit. **Steps 1-6 NOW COMPLETE.** Coder-critic 96/100 PASS. (`b8b4ce8`) — 2026-05-08
- [x] **Phase 1a §3.3 step 7 — 9 Survey VA files relocated** to `do/survey_va/`: `imputation`, `imputed/compcase categoryindex`, `indexalpha`, `indexhorserace[withdemo]`, `indexregwithdemo`, `factor`, `pcascore`. Out-of-scope: `alpha.do` (Step 8 archive), `mattschlchar.do` (Step 10), `allsvymerge`/`allsvyfactor`/`testscore` (Step 11). Path repointing: chain outputs CANONICAL `$datadir_clean/survey_va/*` + `$estimates_dir/survey_va/factor/*`; LEGACY external reads via `$caschls_projdir`; intermediate exploratory outputs to `$output_dir/{csv,graph}/factoranalysis/*`. INPUTS+OUTPUTS verified via grep on each body BEFORE writing each header (4th-recurrence discipline). Original commit `3e99c3b` deferred Tier 2 per context-budget. **Retroactive audit (2026-05-08): coder-critic round 1 BLOCK 75/100 — flagged `factor.do:131` `translate $consolidated_dir/do/survey_va/factor.{smcl,log}` (sed-mistranslated; ADR-0021 sandbox violation + runtime path bug since SMCL opened at `$logdir/factor.smcl` per L58). One-line fix to `$logdir/factor.{smcl,log}`. Round 2 PASS 94/100.** (`3e99c3b` + fix `68cf30e`) — 2026-05-08
- [x] **Tier-1 sandbox-write grep extension** — `phase-1-review.md` §3 pattern extended to `'save|export|esttab using|graph export|outsheet|outreg2 using|texsave|^\s*translate |log using'`. Process learning from Step 7 retroactive audit: original pattern omitted log-write commands; sed-mistranslated `translate` line slipped past pre-commit. Codified `[LEARN:discipline]` in MEMORY.md cross-referencing the rule update. (`3f05995`) — 2026-05-08
- [x] **Phase 1a §3.3 step 8 — alpha.do archived** (1-file batch) to `do/_archive/exploratory/`. ADR-0010 authority (paper-α canonical producer is `indexalpha.do` — relocated to `do/survey_va/` in Step 7; `alpha.do` was exploratory wider-item-list 20/17/4 sensitivity vs production 9/15/4). Body preserved verbatim (semantic; LF normalization per repo `text=auto` consistent with Step 7 actively-relocated `indexalpha.do` from same predecessor dir). README at `do/_archive/exploratory/README.md` documents archive scope, ADR-0010 authority, file list, why-archived, verify-before-archive grep result, ADR-0010 vs ADR-0021 convention reconciliation. main.do:307 flag-comment updated past-tense COMPLETE; Step 11 flag retained. **Steps 1-8 NOW COMPLETE.** Coder-critic PASS 97/100 (one Minor -3 on README defensive cross-ref). (`8fe1f28`) — 2026-05-08
- [x] **Phase 1a §3.3 step 9 inventory + 5-batch plan committed** at `quality_reports/plans/2026-05-08_step-9-data-prep-inventory.md`. 33 files across 5 named sub-batches (acs/2, schl_chars/11, k12_postsec_distance/5, prepare/4, qoiclean/11). Discovered-but-out-of-named-scope: `buildanalysisdata/poolingdata/` (5) + `responserate/` (4); decision deferred to end of Step 9. (`a6cd5f2`) — 2026-05-08
- [x] **Phase 1a §3.3 step 9 batch 9a — 2 ACS census-tract files relocated** to `do/data_prep/acs/`: `acs_2017_gen_dict.do` (47 body lines) + `clean_acs_census_tract.do` (369 body lines). Path repointings: `cd $vaprojdir` removed; reads `$vaprojdir/data/...` (LEGACY raw); writes `$datadir_clean/acs/...` (CHAIN) + `$output_dir/csv/acs/2017/...` (diagnostic) + `$logdir/...`; `include do_files/sbac/macros_va.doh` → `$consolidated_dir/do/va/helpers/macros_va.doh`. Coder-critic PASS 95/100 (2 Minors deferred). (`4a88874`) — 2026-05-08
- [x] **Phase 1a §3.3 step 9 batch 9b — 11 school-characteristics files relocated** to `do/data_prep/schl_chars/`. Chain order from predecessor `do_all.do:75-97`. Caught 3 mid-pass bugs (relative-after-cd form; broken raw imports after `cd` removal; Python INPUTS regex missed `import delimited|excel`). Coder-critic PASS 92/100 round 1; 2 findings (Major: `clean_sch_char.do:609` relative `save` missed by sed; Minor: tempfile attribution drift) FIXED in `9478ded`. (`40cb161`+`9478ded`) — 2026-05-08
- [x] **Phase 1a §3.3 step 9 batch 9c — 5 k12-postsec-distance files relocated** to `do/data_prep/k12_postsec_distance/`. Path repointings to `$datadir_clean/k12_postsec_distance/clean/*`. SECURITY SCRUB: revoked OpenCage API key replaced with placeholder. Coder-critic PASS 84/100 round 1; 3 findings (false sub-call claim; stale callsite includes in `do/samples/`; header self-listing) FIXED in `02b5189`. (`4403758`+`02b5189`) — 2026-05-08
- [x] **Phase 1a §3.3 step 9 batch 9d — 4 caschls/prepare files relocated** to `do/data_prep/prepare/`: `enrollmentclean.do` (chain producer; 5 yearly enr dtas), `poolgr11enr.do` (chain consumer; pooled gr11 weight), `renamedata.do` (22 raw→cleaned CalSCHLS surveys), `splitstaff0414.do` (split staff0414 into 11 yearly files). Settings.do edit: added 3 LEGACY-READ-ONLY globals (`$rawdtadir`, `$rawcsvdir`, `$clndtadir`) for CalSCHLS restricted-access raw + clean data. Coder-critic round 1 BLOCK 67/100 (Critical: undefined `$rawcsvdir` global; Major: chain regression splitstaff0414 reading LEGACY instead of CHAIN; Major: missing mkdir for staff/; 2 Minors); 5 fixes in `c35e22a`. **Round 2 PASS 87/100** (one new Minor doc-string drift deferred to batch 9e folding). (`677033f`+`c35e22a`) — 2026-05-08

**Older completions** (pre-2026-05-07 batches) live in:
- `quality_reports/session_logs/2026-04-*` — per-session detailed logs
- `git log --oneline` — commit-level audit trail
- `git log --grep='coder-critic'` — Phase 1 code-commit audit trail (12 entries through `421333f`)
