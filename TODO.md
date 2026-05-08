# TODO — VA Consolidated (CEL Value-Added Project)

Last updated: 2026-05-08 (after Step 7 commit `3e99c3b` — **Steps 1-7 LANDED; coder-critic DEFERRED per context-budget**)

## Active (next-up)

- [ ] **Phase 1a §3.3 IN PROGRESS — 82 of ~150 files relocated/archived. Steps 1-7 LANDED.** Remaining: Step 8 (1) + Step 9 (~30) + Step 10 (~50). **NOTE:** Step 7 (`3e99c3b`) committed without coder-critic dispatch due to context-budget pressure (session at 81% pre-compact). Next session must dispatch coder-critic on Step 7 retroactively before claiming Step 7 PASS.

### Next session — FIRST: retroactive coder-critic on Step 7 commit `3e99c3b`

Before starting Step 8, dispatch coder-critic on the 9 Step 7 files (`do/survey_va/*.do`) to close out the audit-trail gap. Tight scope (5 concerns):
1. Sandbox-write check (writes -> CANONICAL `$datadir_clean/survey_va/*` + `$estimates_dir/survey_va/factor/*` + `$output_dir/csv|graph/factoranalysis/*` + `$logdir/`)
2. INPUTS-OUTPUTS header fidelity (per 4th-recurrence grep-before-claim discipline)
3. `$projdir` repointings clean (LEGACY-only via `$caschls_projdir`; chain outputs via CANONICAL)
4. main.do Phase 5 wiring + flag-comments for Step 8 + Step 11
5. Verbatim preservation under ADR-0021 (predecessor typos preserved; e.g., `indexhorsewithdemo.smcl` instead of `indexhorseracewithdemo.smcl`)

### After Step 7 audit — Step 8 (alpha.do archive, 1 file)

Per plan v3 §3.3 step 7. Relocate `imputedcategoryindex.do`, `compcasecategoryindex.do`, `indexalpha.do`, `indexhorserace.do`, `indexhorseracewithdemo.do`, `indexregwithdemo.do`, `imputation.do`, `factor.do`, `pcascore.do`, `mvpatterns.do` from `caschls/do/share/factoranalysis/` to `do/survey_va/`.

**Pre-batch checklist (carry forward; per `[LEARN:discipline]` lessons in MEMORY.md):**

1. Inventory source files at `caschls/do/share/factoranalysis/`.
2. **Absolute paths after `cd $vaprojdir`** — convention from batch 2c bugfix.
3. ADR-0021 conventions: header, sandbox-write check, LEGACY-include macro-trace.
4. **Always grep before claiming a local/macro is undefined** (batch 3b lesson).
5. **Always grep BOTH inputs AND outputs before writing the header** (batches 3d + Step 4 lessons — 4th-recurrence discipline now extends to inputs).
6. Watch for `$projdir` references in caschls files (per [LEARN:stata] siblingoutxwalk pattern: alias-before-include or pre-emptive repoint).
7. Note: `alpha.do` from same directory is Step 8 (single-file archive per ADR-0010); separate it from Step 7 active relocations.

### Remaining Phase 1a §3.3 steps after Step 6

| Step | Description | Source | Destination | Approx files |
|---|---|---|---|---:|
| 7 | Survey VA (`imputedcategoryindex.do`, `compcasecategoryindex.do`, `indexalpha.do`, `indexhorserace*`, `indexregwithdemo.do`, `imputation.do`, `factor.do`, `pcascore.do`, `mvpatterns.do`) | `caschls/do/share/factoranalysis/` | `do/survey_va/` | ~10 |
| 8 | `alpha.do` archived per ADR-0010 | `caschls/do/share/factoranalysis/` | `do/_archive/exploratory/` | 1 |
| 9 | Data prep (Christina-owned; `enrollmentclean.do`, `acs/`, `schl_chars/`, `k12_postsec_distance/`, `prepare/`, `caschls_qoiclean/`) | mixed | `do/data_prep/` | ~30 |
| 10 | share/ paper producers (everything in `cde_va_project_fork/do_files/share/` + `caschls/do/share/` minus deprecated subtrees) | mixed | `do/share/` | ~50 |
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

Audit trail: `git log --grep='coder-critic'`. Entries: `e1cbc56`, `9120754`, `d775efe`, `275efc0`, `7983a8d`, `94fd2b8`, `5de34a7`, `90700c2`, `223e9b2`, `4ee0b58`, `9e102fd`, `421333f`, `ccc2600`, `c84371f`, `b8b4ce8`. **Step 7 commit `3e99c3b` PENDING coder-critic** (deferred next-session per context-budget; first action of next session). (Plus writer-critic dispatches for doc commits: `053871e`.) Note: pre-`275efc0` SHAs were rewritten 2026-04-30 by `git filter-repo` (OpenCage history strip); refs in markdown use post-rewrite SHAs.

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

- [x] **Phase 1a §3.3 step 2 batch 2b — 4 sample-construction entry points** (`touse_va.do`, `create_score_samples.do`, `create_out_samples.do`, `create_va_sample.doh`) relocated to `do/samples/`. Output-path coordination via `$datadir_clean/sbac/va_samples.dta`. Prereq settings.do edit added `$distance_dtadir` LEGACY global. main.do Phase 2 wired with `do_touse_va`/`do_create_samples = 0` gates mirroring predecessor. Caschls-side disposition: 3 files (`createvasample.do`, `create_va_sib_acs_*.do`) re-routed to Step 6 archive per ADR-0004 (no cde-side caller). Coder-critic 96/100 PASS; 2 Minor findings closed in-commit (ledger rows + ASSUMED out-of-repo macro-trace). (`5de34a7`) — 2026-05-07
- [x] **Phase 1a §3.3 step 2 batch 2c — 4 merge helpers + Critical bugfix** — `merge_loscore.doh`, `merge_sib.doh`, `merge_lag2_ela.doh`, `merge_va_smp_acs.doh` relocated. **Bugfix:** 9 broken consolidated relative `include do/...` after `cd $vaprojdir` in batch 2b files (would have resolved to `$vaprojdir/do/...` at runtime; nonexistent). Fix: convert to absolute `$consolidated_dir/do/...`. New convention codified in TODO checklist for Step 3+. 16 LEGACY refs in batch 2b create_*_samples.do repointed to consolidated. Christina decision: paper-text edits deferred post-handoff (`[LEARN:project]`). Coder-critic 95/100 PASS. (`90700c2`) — 2026-05-07
- [x] **Phase 1a §3.3 step 3 batch 3a — 4 VA estimation entry points** (`va_score_all`, `va_score_fb_all`, `va_out_all`, `va_out_fb_all`) relocated to `do/va/`. ~870 body lines. Critical dependency chain verified atomic: va_score_all writes `va_<subject>...ct.dta`; va_out_all + va_out_fb_all read same path for DK chain. main.do Phase 3 wired with `do_va = 0` gate. `out_drift_limit.doh` identified as dead code (deferred to Phase 1c §5.1). 4 predecessor typos preserved verbatim. Coder-critic 92/100 PASS. (`223e9b2`) — 2026-05-07
- [x] **Phase 1a §3.3 step 3 batch 3b — 5 spec/FB test summary tables** (`va_score_spec_test_tab`, `va_out_spec_test_tab`, `va_score_fb_test_tab`, `va_out_fb_test_tab`, `va_spec_fb_tab`) relocated. Prereq settings.do edit: added `$tables_dir` and `$figures_dir` to CANONICAL block (per ADR-0012). Predicted-prior-score reads KEPT LEGACY (Step 11 deferred per `[LEARN:domain] _scrhat_`). 2 round-1 critic findings fixed in-commit: M1 (-10) fabricated "undefined locals" claim about `b_str/las_str/ls_str` (they ARE defined at macros_va.doh:560/600/616) — corrected; M2 (-3) real predecessor latent bug (sd_va asymmetry in va_out_spec_test_tab.do:245) — documented. **Lesson codified:** always grep before claiming a local/macro is undefined. Coder-critic 84/100 PASS. (`4ee0b58`) — 2026-05-07
- [x] **Phase 1a §3.3 step 3 batch 3c1 — 3 VA utility files** (`merge_va_est`, `va_corr`, `prior_decile_original_sample`) relocated. `merge_va_est` produces master VA dataset (`va_<outcome>_all.dta` + super-master `va_all.dta`); `va_corr` correlation diagnostic; `prior_decile_original_sample` builds prior-score deciles + race/sex/econ + census income deciles. `prior_decile_original_sample.do` uses `$projdir` alias-before-include pattern per siblingoutxwalk.do precedent. `_str` locals verified at `macros_va.doh:150/153/157/160/163` BEFORE writing header (lesson from batch 3b applied). Coder-critic 96/100 PASS. (`9e102fd`) — 2026-05-07
- [x] **Phase 1a §3.3 step 3 batch 3c2 — 6 outcome-regression files** (`reg_out_va_all` + `_tab` + `_fig` × {regular, dk}) relocated via script-based methodology (sed for 8 path patterns + Python for ADR-0021 header insertion + mkdir + RUN-START block). ~2220 body lines. New `gph_files` routing convention: intermediate `.gph` → `$output_dir/gph_files/...`; paper-shipping `.pdf` → `$figures_dir/...`. Charter status data KEPT LEGACY (Step 9 deferred). Round-1 critic finding M1 (-3): stale TODO in main.do referencing now-relocated files — fixed in-commit. Coder-critic 87/100 PASS. (`421333f`) — 2026-05-07
- [x] **Hygiene + MEMORY.md learnings** — TODO + SESSION_REPORT (+ `.claude/` mirror) + new session log for batches 3c1/3c2; 2 `[LEARN]` entries in MEMORY.md (script-based relocation methodology + `gph_files` routing convention). (`4c4ec81`, `712f803`) — 2026-05-07
- [x] **TODO maintenance fix + 1 LEARN entry** — Christina caught Done section drift (~50 stale 2026-04-* entries; missing 6 recent batches). Pruned per todo-tracking.md rule 6 (~10 most recent). Added `[LEARN:workflow]` codifying the hygiene-commit-must-update-Done-and-prune discipline. (`3503765`) — 2026-05-07
- [x] **Phase 1a §3.3 step 3 batch 3d — 3 sibling-lag diagnostic files** (`va_score_sib_lag`, `va_out_sib_lag`, `va_sib_lag_spec_fb_tab`) relocated to `do/va/`. Diagnostic-only per do_all.do. **Brace-misplacement bug in main.do wiring caught + fixed before push** (Python script landed batch 3d invocations OUTSIDE the `if `do_va'' block; corrected via Edit). One round-1 critic finding (M1 -3): header-vs-code mismatch in va_sib_lag_spec_fb_tab.do (declared CSV outputs that don't get written; actually appends .dta to spec_test/fb_test) — derive-don't-guess violation, FIXED in-commit by rewriting OUTPUTS section. **STEP 3 NOW COMPLETE.** Coder-critic 95/100 PASS. (`ccc2600`) — 2026-05-08
- [x] **Phase 1a §3.3 step 4 — 4 heterogeneity files** (`va_het`, `va_corr_schl_char`, `va_corr_schl_char_fig`, `persist_het_student_char_fig`) relocated to `do/va/heterogeneity/`. Plan v3 mentioned `pass_through/` but predecessor has no such directory; Step 4 = 4 files only. One round-1 critic finding (M2 -7, Major strict-phase): `persist_het_student_char_fig.do` header INPUTS section had boilerplate sch_char/va_all references that the body doesn't read (body only reads `.gph` from `$output_dir/gph_files/`); fixed in-commit by rewriting INPUTS to match body grep at L97-101. Lesson recurrence — discipline now extends to BOTH OUTPUTS and INPUTS. Coder-critic 91/100 PASS. (`c84371f`) — 2026-05-08
- [x] **Phase 1a §3.3 step 6 — 27 deprecated siblingvaregs files archived** to `do/_archive/siblingvaregs/`. First archive-convention batch (bodies preserved verbatim per ADR-0021; not invoked from main.do). 2 files NOT archived per ADR-0004's "verify before archiving" caveat: `siblingoutxwalk.do` (already relocated to `do/sibling_xwalk/` per ADR-0005); `vafilemacros.doh` (still consumed by ACTIVE relocated code in siblingoutxwalk.do + prior_decile_original_sample.do — kept LEGACY-static at predecessor location). README at `do/_archive/siblingvaregs/README.md` documents archive scope + exclusion rationale. One Minor critic finding (README count nits) FIXED in-commit. **Steps 1-6 NOW COMPLETE.** Coder-critic 96/100 PASS. (`b8b4ce8`) — 2026-05-08
- [x] **Phase 1a §3.3 step 7 — 9 Survey VA files relocated** to `do/survey_va/`: `imputation`, `imputed/compcase categoryindex`, `indexalpha`, `indexhorserace[withdemo]`, `indexregwithdemo`, `factor`, `pcascore`. Out-of-scope: `alpha.do` (Step 8 archive), `mattschlchar.do` (Step 10), `allsvymerge`/`allsvyfactor`/`testscore` (Step 11). Path repointing methodology: chain outputs to `$datadir_clean/survey_va/*` + `$estimates_dir/survey_va/factor/*`; LEGACY external reads via `$caschls_projdir`; intermediate exploratory outputs to `$output_dir/{csv,graph}/factoranalysis/*`. INPUTS+OUTPUTS verified via grep on each body BEFORE writing each header (4th-recurrence discipline applied). **Coder-critic DEFERRED to next session per context-budget pressure** (session at 81% real context); Tier 1 self-check PASS. Next-session retroactive audit required before claiming Step 7 PASS. (`3e99c3b`) — 2026-05-08

**Older completions** (pre-2026-05-07 batches) live in:
- `quality_reports/session_logs/2026-04-*` — per-session detailed logs
- `git log --oneline` — commit-level audit trail
- `git log --grep='coder-critic'` — Phase 1 code-commit audit trail (12 entries through `421333f`)
