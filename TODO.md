# TODO — VA Consolidated (CEL Value-Added Project)

Last updated: 2026-05-08 (after Step 11 commit `6791dec` PASS 96/100 — **PHASE 1a §3.3 FULLY COMPLETE — 148 files across 11 steps**)

## Active (next-up)

- [ ] **Phase 1a §3.5 — Golden-master verification (M4)** per ADR-0018 acceptance criteria. Verifier in submission mode runs `diff -r consolidated/output predecessor/output` on a fresh end-to-end Scribe run. Confirms behavior preservation across all 148 relocated/archived files. **First gate before `v1.0-final` tag.**

## Phase 1a §3.3 — COMPLETE 2026-05-08 ✅ (148 files across 11 steps)

| Step | Description | Files | Status |
|---|---|---:|---|
| 1 | Helpers + macros (`do/va/helpers/`) | foundational | ✅ |
| 2 | Samples + merge helpers (`do/samples/`) | 3 batches | ✅ |
| 3 | VA estimation (`do/va/`) | 4 batches (3a-3d); ~2200 body lines/batch | ✅ |
| 4 | Heterogeneity (`do/va/heterogeneity/`) | small batch | ✅ |
| 5 | Sibling crosswalk (`do/sibling_xwalk/`) | per ADR-0005 | ✅ |
| 6 | siblingvaregs archive (`do/_archive/siblingvaregs/`) | 27 files per ADR-0004 | ✅ |
| 7 | Survey VA (`do/survey_va/`) | 9 active relocations | ✅ |
| 8 | `alpha.do` archive (`do/_archive/exploratory/`) | 1-file per ADR-0010 | ✅ |
| 9 (extended) | Data prep (`do/data_prep/`) | **41 files across 7 batches** (9a-9g) | ✅ |
| 10 | share/ paper producers (`do/share/` + `do/survey_va/mattschlchar.do`) | 21 files across 3 batches (10a-10c) | ✅ |
| 11 | Deferred files resolved | 2 ACTIVE (allsvymerge + testscore → `do/survey_va/`) + 1 ARCHIVE (allsvyfactor → `do/_archive/exploratory/`) per ADR-0010 | ✅ |

**Totals: 148 files. 27 coder-critic PASS verdicts.** Chain reads/writes coordinated end-to-end across all batches.

### Coder-critic audit trail

`git log --grep='coder-critic'` is the index. Recent entries (Step 9-11): `4a88874`, `40cb161`+`9478ded`, `4403758`+`02b5189`, `677033f`+`c35e22a`, `0034ae2`, `87856ba`+`cf9cb10`, `4477b6d`+`ef6006c`, `65aae2d`+`bc17fbf`+`3d8874d`, `6791dec` (Step 11 PASS 96/100). Pre-Step-9 entries: `e1cbc56`, `9120754`, `d775efe`, `275efc0`, `7983a8d`, `94fd2b8`, `5de34a7`, `90700c2`, `223e9b2`, `4ee0b58`, `9e102fd`, `421333f`, `ccc2600`, `c84371f`, `b8b4ce8`, `3e99c3b`+`68cf30e`, `8fe1f28`. Note: pre-`275efc0` SHAs were rewritten 2026-04-30 by `git filter-repo` (OpenCage history strip).

## Up Next (post §3.3)

- [ ] **Phase 1a §3.5 — Golden-master verification (M4)** — see Active above.
- [ ] **Phase 1b — Bug fixes by priority** (per plan v3 §4):
  - **§4.2 — Code corrections:** ADR-0011 sums→means in `imputedcategoryindex.do` + `compcasecategoryindex.do`.
  - **§4.3 — Naming/clarity:** ADR-0016 pooledrr rename, ADR-0015 Filipino-into-Asian comment, ADR-0013 mattschlchar dormant-branch comment, **plus carry-forward Minor doc-string drift items** from Steps 9-10 round-2 deductions (per `quality_reports/reviews/2026-05-08_step-10-batches-10bc_coder_review.md` round-2 carry-forward list).
  - **§4.1 — Paper-text corrections:** ADR-0010 footnote, ADR-0014 old-draft note. **DEFERRED post-handoff** per Christina 2026-05-07; coordinate with senior coauthor on a separate timeline. Effectively retired from Phase 1.
- [ ] **Phase 1c §5.1 — Cosmetic cleanup** — dead-code archival, log/translate sweep (per-do-file logging convention from §5.1 step 2). Includes `out_drift_limit.doh` (identified as dead in Step 3 batch 3a; deferred there).
- [ ] **Phase 1c §5.2 — README polish + cold-read** (PRE-DRAFT done as Option B `053871e`; writer-critic 86/100; 2 Minors deferred to §5.4 polish: m1 em-dash density, m7 status-note Phase-1c jargon). Final polish + cold-read test occur at §5.4. File transfer is operator-choice per ADR-0020.
- [ ] **Phase 1c §5.2 step 8 — offboarding deliverable memo** at `quality_reports/handoff/` (per ADR-0018). Stub created `053871e`. Memo content per `quality_reports/handoff/README.md`. **Specific Christina action when writing the memo:** sweep for residual *semantic* codebook ambiguities (e.g., specific NSC sector codes she knows but never wrote down) — last chance to externalize codebook-authority knowledge before deposit, since post-`v1.0-final` no fallback exists (no provider PDFs; Kramer is custodian-not-maintainer).
- [ ] **Phase 1c §5.3 — Data checks — TBD-codebook resolution.** Six skeletons pre-drafted as Option A (`d775efe`); each runnable as no-op via capture-confirm-file shim; becomes a real check post-Phase-1a §3.3. TBD-codebook markers (NSC merge rate; CCC/CSU match-level==1 share; paper-table cell magnitudes) resolve as Phase 1a §3.5 golden-master + first production runs supply baselines.
- [ ] **Phase 1c §5.4 — Acceptance run** (per ADR-0018) — `stata -b do do/main.do` on Scribe with `run_data_checks 1`; README cold-read test by friendly non-Christina lab member. BOTH must pass before `v1.0-final` tag.

## Per-commit review discipline (active through `v1.0-final` tag)

Every Phase 1 code commit goes through coder-critic at 80/100 hard gate per `.claude/rules/phase-1-review.md`. Commit footer convention:

- Code commits: `coder-critic: PASS (XX/100)` (or `BLOCK XX/100` followed by fix + round-2)
- Cosmetic / out-of-scope: `coder-critic: skipped (rationale: ...)`

## Process learnings cumulative across Phase 1a §3.3 (codified in MEMORY.md as `[LEARN]` entries)

10 learnings accumulated through Steps 9-11; ready to codify or already in MEMORY.md:

1. Settings.do globals must be enumerated upfront from predecessor (caused Step 9d Critical `$rawcsvdir`; Step 10 batch 10c `$cstdtadir` add).
2. Cross-script chain coordination: after repointing writes, grep tree for matching predecessor reads (caused Step 9d splitstaff0414 chain regression; Step 11 surfaced 2 BONUS Step 10 schlcharpooledmeans catches).
3. Python regex must be whitespace-tolerant for `cd`/`log using` patterns.
4. Stata `\`name'` macro syntax breaks `\w+` regex — use literal sub or `[^/]+`.
5. Translate destinations: predecessor inconsistencies (`.txt` vs `.log`; missing-space `translate$vaprojdir`) — normalize.
6. Even gated LEGACY writes are ADR-0021 violations (e.g., `if create_sample==1` branches).
7. cap mkdir blocks must match ACTUAL write targets (not assumed sub-dir name); grep first.
8. Helper relocations ripple to callers — search-and-update all callers.
9. Multi-year files use `\`year'` loops — INPUTS sections enumerate the year-set.
10. Initial inventory counts can be wrong — recount during setup (Step 9e was 10 not 11; Step 10 was 21 not ~50).

## T1 Tests for Christina — ALL RESOLVED 2026-04-27/30

- [x] T1-3 — `school_id == cdscode` 1:1 check — VERDICT: 1:1 (N=5009). Cosmetic rename only. — 2026-04-27
- [x] T1-4 — mtitles count test — BUG FIRED (cosmetic per Q-6). — 2026-04-27
- [x] T1-5 — Revoke OpenCage API key — RESOLVED 2026-04-30 (key revoked + history-stripped from repo). — 2026-04-30

## Codebook export for Christina — COMPLETE 2026-04-28

- [x] All steps complete; sanitized log at `master_supporting_docs/codebooks/codebook_export_28-Apr-2026_13-25-41.log`. Findings extracted to `quality_reports/reviews/2026-04-28_data-checks-design.md`.

## Open T4 escalations (require Christina input at Phase 0e) — ALL RESOLVED 2026-04-27

In `quality_reports/audits/2026-04-27_T4_answers_CS.md`. ADRs 0004-0016 operationalize. Q-14 (special-ed/home-instruction restrictions) deferred per Christina's "honestly no idea, took from Matt" answer.

## Backlog

- [ ] Universal hook fix in workflow repo (status: shipped + propagated; only filter-ordering edge case remains, low priority)
- [ ] Stata version compatibility revisit (post-consolidation, pre-submission)
- [ ] **Tier-1 sandbox-write grep further extension** — current pattern catches `save|export|esttab|graph export|outsheet|outreg2|texsave|translate|log using`. Step 10 surfaced `regsave using` and `export excel` patterns that may need separate consideration (caught by extended grep for these specifically). Low priority; current pattern catches the overwhelming majority.
- [ ] **[Phase 1c §5.3]** New data-check `check_chain.do` — programmatic scan for producer-CANONICAL/consumer-LEGACY pairs across entire do/ tree. Prevents future regression of the class found 2026-05-16 pre-flight (3 Criticals: analysisready, sibling_out_xwalk, score_b; also Partition B Mj-1 categoryindex). Partition C explicitly recommended this; would make chain-coordination an empirical post-relocation invariant rather than an audit-time grep. See `quality_reports/reviews/2026-05-16_pre-flight-SYNTHESIS_M4-go-no-go.md` "Recommended next steps" §6.
- [ ] **[Follow-up post-M4]** `py/sweep_comments_and_logdirs.py` T2 (`transform_log_paths`) is non-idempotent — `_CAP_MKDIR_LOGDIR` regex re-matches the original `cap mkdir "$logdir"` line on re-run and re-inserts duplicate cascade lines. Sweep is one-shot so this isn't a runtime concern, but a future helper run would corrupt files. Add idempotence guard or document "do not re-run" in helper header. See `quality_reports/reviews/2026-05-17_dual-sweep-round2_coder_review.md` finding M-T2.
- [x] **[Phase 1c §5.4]** check_survey_indices.do:197 reads from `$estimates_dir/calschls/categoryindex/` but producers write to `$datadir_clean/survey_va/categoryindex/` — silent-skip on acceptance run; repoint reader path (Major) — see `quality_reports/reviews/2026-05-16_pre-flight-B_va-samples-xwalk-check_coder_review.md` finding 3 — RESOLVED 2026-05-17
- [x] **[Phase 1c §5.4]** `do/check/t1_empirical_tests.do` is a predecessor-layout one-off diagnostic not invoked from main.do; breaks `check_logs.do` invariant on acceptance run; archive to `do/_archive/check/` or add exclusion regex (Major) — see `quality_reports/reviews/2026-05-16_pre-flight-B_va-samples-xwalk-check_coder_review.md` finding 4 — RESOLVED 2026-05-17 (archived to `do/_archive/check/`)
- [x] **[Phase 1c §5.4]** 6 `.doh` files in `do/samples/` (`create_va_g11_{sample,out_sample}{,_v1,_v2}.doh`) have relative `include do/samples/...` lines that break after caller `cd $vaprojdir`; repoint to absolute `$consolidated_dir/do/samples/...` (Major; fires on `do_create_samples=1` acceptance run) — see `quality_reports/reviews/2026-05-16_pre-flight-B_va-samples-xwalk-check_coder_review.md` finding 5 — RESOLVED 2026-05-17 (12 substitutions across 6 files)
- [ ] **[Phase 1c §5.4]** Unused hardcoded absolute path `local ca_ed_lab "/home/research/ca_ed_lab"` in `do/va/helpers/macros_va.doh:103` (Minor; line is dead-code, no runtime impact) — see `quality_reports/reviews/2026-05-16_pre-flight-B_va-samples-xwalk-check_coder_review.md` finding 6
- [ ] **[Phase 1c §5.4]** Backfill 3 verification-ledger rows for `do/sibling_xwalk/siblingoutxwalk.do` (no-hardcoded-paths, adr-0021-sandbox-write, legacy-include-macro-trace) (Minor) — see `quality_reports/reviews/2026-05-16_pre-flight-B_va-samples-xwalk-check_coder_review.md` finding 7
- [ ] **[Phase 1c §5.4]** Codify `cd $vaprojdir` → absolute-include convention in `.claude/rules/phase-1-review.md` §2 Tier-1 checklist; relative-include-inside-helper-of-helper is a recurring regression risk class (Minor) — see `quality_reports/reviews/2026-05-16_pre-flight-B_va-samples-xwalk-check_coder_review.md` finding 8
- [x] **[Phase 1c §5.4]** `do/check/t1_empirical_tests.do:62-65` writes its log to relative `log_files/check/` instead of `$logdir/`; orthogonal aspect to finding 4 (Minor) — see `quality_reports/reviews/2026-05-16_pre-flight-B_va-samples-xwalk-check_coder_review.md` finding 9 — RESOLVED 2026-05-17 by Mj-2 archive (file moved to `do/_archive/check/`; no longer load-bearing)
- [ ] **[Phase 1c §5.4]** CONVENTIONS section absent partition-wide across 32 files in `do/share/`, `do/survey_va/`, `do/explore/` — substance preserved in RELOCATION blocks; resolve either by updating ADR-0021 to permit RELOCATION as CONVENTIONS-equivalent (cheaper) or by adding explicit CONVENTIONS sections in a sweep (Major M1) — see `quality_reports/reviews/2026-05-16_pre-flight-D_share-surveyva-explore_coder_review.md` finding M1
- [ ] **[Phase 1c §5.4]** Hardcoded absolute path in `do/survey_va/mattschlchar.do:69` (`/home/research/ca_ed_lab/msnaven/common_core_va/data/sch_char`); gated dormant via `if \`clean'==1`, disclosed in header per ADR-0013; archive-or-keep decision in Phase 1c §5.1 dead-code review (Minor M2) — see `quality_reports/reviews/2026-05-16_pre-flight-D_share-surveyva-explore_coder_review.md` finding M2
- [ ] **[Phase 1c §5.4]** Hardcoded absolute paths in `do/share/outcomesumstats/nsc2019new/k12_nsc2019_merge.doh:67, 82` (k12_public_schools_clean.dta); helper `.doh` dormant under default toggles, disclosed in header per ADR-0013; archive-or-keep decision in Phase 1c §5.1 dead-code review (Minor M3) — see `quality_reports/reviews/2026-05-16_pre-flight-D_share-surveyva-explore_coder_review.md` finding M3
- [ ] **[Phase 1c §5.4 / post-smoke]** M4 `.ster` `e(b)`/`e(V)` element-wise compare needs colname check — colsof equal but colnames mismatch produces spurious tiny diffs (silent regressor-rename bug) — see `quality_reports/reviews/2026-05-16_m4-infrastructure_coder_review.md` finding M1
- [ ] **[Phase 1c §5.4 / post-smoke]** M4 `cf` row-count mismatch (rc=503) is misclassified as `READ_ERROR`; should be `FAIL` with "row-count mismatch: pred=<N1> cons=<N2>"; only other `_rc` codes should be READ_ERROR — see `quality_reports/reviews/2026-05-16_m4-infrastructure_coder_review.md` finding M2
- [ ] **[Phase 1c §5.4 / post-smoke]** M4 `.pdf` comparison via `pdftotext` + `cmp -s` is byte-strict; benign build-date stamps inflate FAIL_VISUAL count; add `awk` filter to strip ISO dates / "Generated on ..." boilerplate before compare — see `quality_reports/reviews/2026-05-16_m4-infrastructure_coder_review.md` finding M5
- [ ] **[Phase 1c §5.4 / post-smoke]** M4 smoke tier (5 rows) missing csv/xlsx coverage — `cap_compare_bytes` dispatcher untested at smoke; add 6th smoke row for csv (e.g., one of the `acs_2017_S*_dict.csv` files) and 7th for xlsx — see `quality_reports/reviews/2026-05-16_m4-infrastructure_coder_review.md` finding Mi1
- [ ] **[Phase 1c §5.4 / post-smoke]** M4 two-file-missing case (neither side exists) classified as `MISSING_PREDECESSOR`; add distinct `MISSING_BOTH` status + counter to differentiate "pred should have produced this" from "phantom CSV row neither pipeline produced" — see `quality_reports/reviews/2026-05-16_m4-infrastructure_coder_review.md` finding Mi2
- [x] **[Phase 1c §5.4]** Replace `cap log close _all` + unnamed `log using` + `log close` triplet with named-log pattern across all ~110 relocated .do files — RESOLVED 2026-05-17 by `py/sweep_named_logs.py` helper. 107 files transformed; main.do uses `name(master)`; coder-critic PASS 95/100.

## Done (last ~10 — older completions in session logs + git history per `todo-tracking.md` rule 6)

- [x] **Phase 1a §3.3 step 9 batch 9b — 11 school-characteristics files relocated** to `do/data_prep/schl_chars/`. Chain order from predecessor `do_all.do:75-97`. Caught 3 mid-pass bugs. Coder-critic PASS 92/100 round 1; 2 findings (Major: `clean_sch_char.do:609` relative `save` missed by sed; Minor: tempfile attribution drift) FIXED in `9478ded`. (`40cb161`+`9478ded`) — 2026-05-08
- [x] **Phase 1a §3.3 step 9 batch 9c — 5 k12-postsec-distance files relocated** to `do/data_prep/k12_postsec_distance/`. SECURITY SCRUB: revoked OpenCage API key replaced with placeholder. Coder-critic PASS 84/100 round 1; 3 findings FIXED in `02b5189`. (`4403758`+`02b5189`) — 2026-05-08
- [x] **Phase 1a §3.3 step 9 batch 9d — 4 caschls/prepare files relocated** to `do/data_prep/prepare/`. Settings.do edit: 3 LEGACY-READ-ONLY globals (`$rawdtadir`, `$rawcsvdir`, `$clndtadir`). Coder-critic round 1 BLOCK 67/100 (Critical undefined `$rawcsvdir`; Major chain regression; Major missing mkdir; 2 Minors); 5 fixes in `c35e22a` round 2 PASS 87/100. (`677033f`+`c35e22a`) — 2026-05-08
- [x] **Phase 1a §3.3 step 9 batch 9e — 10 caschls/qoiclean files relocated** to `do/data_prep/qoiclean/{parent,secondary,staff}/`. Multi-year loop files. Coder-critic PASS 95/100. (`0034ae2`) — 2026-05-08
- [x] **Phase 1a §3.3 step 9 EXTENSION batches 9g+9f (joint) — 9 caschls/buildanalysisdata files relocated** per Christina decision. **STEP 9 EXTENDED COMPLETE — 41 files across 7 batches.** Coder-critic joint PASS 93/100. (`87856ba`+`cf9cb10`) — 2026-05-08
- [x] **Phase 1a §3.3 step 10 batch 10a — 10 cde/share paper producers relocated** to `do/share/`. 13 sbac helper includes repointed; chain reads to Steps 3+7 outputs. Coder-critic round 1 BLOCK 71/100 (5 Major); 5 fixes in `ef6006c` round 2 PASS 88/100. (`4477b6d`+`ef6006c`) — 2026-05-08
- [x] **Phase 1a §3.3 step 10 batches 10b+10c (joint) — 11 caschls/share files relocated.** Settings.do `$cstdtadir` global added. Phase 5 INSERT: mattschlchar.do wired. Coder-critic joint round 1 BLOCK 78/100 (F1 mkdir mismatches + F2 header drift); fix in `3d8874d` round 2 PASS 82/100. **STEP 10 COMPLETE.** (`65aae2d`+`bc17fbf`+`3d8874d`) — 2026-05-08
- [x] **Phase 1a §3.3 step 11 — deferred files resolved** — 2 ACTIVE relocations (allsvymerge.do + testscore.do → `do/survey_va/`) + 1 ARCHIVE (allsvyfactor.do → `do/_archive/exploratory/`). Cross-step chain coordination: 4 Step 7 files repointed (allsvyqoimeans + testscorecontrols + 2 BONUS schlcharpooledmeans catches from Step 10 chain). main.do Phase 5 wiring updated. Coder-critic PASS 96/100. **STEP 11 COMPLETE — PHASE 1a §3.3 FULLY DONE — 148 files across 11 steps; 27 coder-critic PASS verdicts.** (`6791dec`) — 2026-05-08

**Older completions** (pre-2026-05-07 batches) live in:
- `quality_reports/session_logs/2026-04-*` and `2026-05-0[1-7]_*` — per-session detailed logs
- `git log --oneline` — commit-level audit trail
- `git log --grep='coder-critic'` — Phase 1 code-commit audit trail
