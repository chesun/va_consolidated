# TODO — VA Consolidated (CEL Value-Added Project)

Last updated: 2026-04-29

## Active (next-up)

- [ ] **Christina decision: pick next code work** (see options A/B/C below).
- [ ] **Christina: mark plan v3 APPROVED** when ready — all §8 questions resolved 2026-04-27; subsequent revisions are additive (per-do-file logging, automated data checks, ADR-0020 simplification, per-commit review discipline, ADR-0021 sandbox + description convention).
- [ ] Phase 1 sub-phase structure (locked): 1a consolidate (behavior-preserving) → 1b bug fixes by priority → 1c cosmetic. File ownership constraint: Matt Naven's files stay UNTOUCHED per ADR-0017.

### Options for next code work (Christina picks; in priority order)

- [x] ~~**Option A — pre-draft `do/check/check_*.do` skeletons**~~ — DONE 2026-04-29 (`d775efe`); 84/100 PASS.
- [ ] **Option B — pre-draft README.md skeleton** for Phase 1c §5.2 step 5. Audience: Stata-skilled, no git. Triggers writer-critic, not coder-critic.
- [ ] **Option C — begin Phase 1a §3.3 script relocation** starting with `siblingoutxwalk.do` per ADR-0005 (single-file move). Requires Christina go-ahead — changes repo state.

### Per-commit review discipline (active)

Every Phase 1 code commit goes through coder-critic at 80/100 hard gate per `.claude/rules/phase-1-review.md`. Commit message footer convention:

- Code commits: `coder-critic: PASS (XX/100)`
- Cosmetic / out-of-scope: `coder-critic: skipped (rationale: ...)`

Audit trail: `git log --grep='coder-critic'`. Entries: `e1cbc56`, `9120754`, `d775efe`.

## T1 Tests for Christina (run on Scribe when convenient — ~5-15 min in one session)

Consolidated as a single .do file at `do/check/t1_empirical_tests.do` (2026-04-27). **Reduced from 5 to 3 tests after ADR-0017 retired Matt-Naven-file tests (T1-1, T1-2).**

- [x] **T1-3** — `school_id == cdscode` 1:1 check — **VERDICT: 1:1 (N=5009).** Cosmetic rename only in Phase 1. Resolves P2-3, P2-11. — 2026-04-27
- [x] **T1-4** — mtitles count test — **BUG FIRED** (49/33/33/33 cols vs 24 declared). Per Q-6, CSVs don't feed paper → cosmetic. — 2026-04-27
- [ ] **T1-5** — Revoke OpenCage API key (manual external action; reminder in script)

**Retired:**
- ~~T1-1 — `crosswalk_nsc_outcomes.do:250` `id` macro~~ — file is Christina's (per ADR-0019, refining ADR-0017) but **out of scope by time-budget** in Phase 1: file not pipeline-active, paper blast radius for Bug 93 null, ½-day fix not justified vs. offboarding acceptance run.
- ~~T1-2 — Bug 93 family count (4 instances)~~ — NSC instances in Christina's file (per ADR-0019) but out of scope by time-budget; CCC/CSU instances in Matt's files (`merge_k12_postsecondary.doh`) per ADR-0017.

**Removed earlier (resolved by Christina 2026-04-26 FB-test correction):**
- ~~Column 6 FB rows blank?~~ — NOT A BUG (intentional, FB-test structural property)
- ~~`predicted_score==0` filter?~~ — NOT A BUG (separate dirs, no conflation)

## Up Next

- [ ] **Phase 1a §3.3 script relocation** (the bulk of Phase 1a — ~6 weeks). Each file move is one commit; coder-critic dispatch on each per phase-1-review rule. Order: helpers/macros → samples → VA estimation → heterogeneity/pass-through → sibling crosswalk → siblingvaregs deprecation → survey VA → data prep → share/.
- [ ] **Phase 1a §3.5 golden-master verification** (M4) at end of §3.3. Verifier in submission mode; the canonical relative regression check (predecessor vs consolidated outputs).
- [ ] **Phase 1b bug fixes by priority** — paper-text corrections (ADR-0010, ADR-0014) → code corrections (ADR-0011 sums→means, P3 typos) → naming/clarity (ADR-0016 pooledrr rename, ADR-0015 Filipino-into-Asian comment, ADR-0013 mattschlchar dormant-branch comment).
- [ ] **Phase 1c §5.1 cosmetic cleanup** — dead-code archival, log/translate sweep (per-do-file logging convention from §5.1 step 2).
- [ ] **Phase 1c §5.2 README rewrite** — for non-git Stata-skilled successor. File transfer is operator-choice per ADR-0020; offboarding deliverable memo instructs "clone GitHub at v1.0-final, copy contents to Scribe via preferred tool".
- [ ] **Phase 1c §5.3 automated data checks** — six `do/check/check_*.do` files per design memo. Optionally pre-draft as Option A above.
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

- [ ] Christina T1-5 (revoke OpenCage API key — manual action). T1-3 and T1-4 RESOLVED 2026-04-27.
- [ ] Christina codebook-export run on Scribe (above section). Not blocking Phase 1a start; needed before Phase 1c §5.3 finalizes.

## Backlog

- [ ] ~~Bug 93 (NSC UC inlist precedence) — P1 fix during Phase 1~~ — RETIRED per ADR-0017 (Matt's files untouched in Phase 1)
- [ ] Universal hook fix in workflow repo (status: shipped + propagated; only filter-ordering edge case remains, low priority)
- [ ] Stata version compatibility revisit (post-consolidation, pre-submission)

## Done (recent)

- [x] Initialize repo from `claude-code-my-workflow` applied-micro template — 2026-04-24
- [x] Personalize template — 2026-04-24
- [x] 5-round Q&A onboarding context-gathering — 2026-04-24
- [x] Read `paper/common_core_va_v2.tex` end-to-end; produce paper map — 2026-04-24
- [x] Diagnose primary-source-check hook false-positive bugs — 2026-04-24
- [x] Populate `.claude/state/primary_source_surnames.txt` (210 surnames) — 2026-04-24
- [x] Capture server info to gitignored `.claude/state/server.md` — 2026-04-24
- [x] Master-file audit + 4 archival commits in cde_va_project_fork — 2026-04-25
- [x] Master-file audit + 4 archival commits in caschls — 2026-04-25
- [x] Consolidation plan v2 incorporating Christina's feedback — 2026-04-25
- [x] CLAUDE.md folder structure refactor (scripts/ → root-level do/ + py/) — 2026-04-25
- [x] ADRs 0001-0003 (foundational) — 2026-04-25
- [x] **Phase 0a complete: 10-chunk deep-read, ~150 files audited, ~101 bugs inventoried, paper-output mapping closed loop, all foundational questions resolved (N1, N2, distance-FB, v1/v2, vam compat)** — 2026-04-25
- [x] Phase 0a-v2 setup: round-1 docs sequestered, round-2 dir + protocol README created, pre-flight Bug 93 T3 verification (caught round-1 over-claim by 50%) — 2026-04-25
- [x] Phase 0a-v2 plan drafted at `quality_reports/plans/2026-04-25_phase-0a-v2-verification-plan.md` — 2026-04-25
- [x] Phase 0a-v2 batch 1 — chunks 1, 2, 3 round-2 verified; 3 disc reports written; T3 verifications resolved 5 latent-bug questions and confirmed Bug 93 family is 4 active instances — 2026-04-26
- [x] Phase 0a-v2 batch 2 — chunks 4, 5 round-2 verified; 2 disc reports written; N1 SAFE-to-relocate verdict reaffirmed; new HIGH-priority mtitles bugs surfaced in chunk-4 file 4 and chunk-5 reg_out_va_sib_acs_tab.do — 2026-04-26
- [x] Phase 0a-v2 batch 3 — chunks 6, 7, 8 round-2 verified; 3 disc reports written; Distance-FB Row 6 producer chain LOCKED end-to-end; sample-restriction map (paper Table A.1) FINALIZED; T3.6 confirmed counts_k12.tex paper-path "mismatch" is OLD-paper / NEW-paper divergence (NOT a Phase 1 issue) — 2026-04-26
- [x] Phase 0a-v2 batch 4 — chunks 9, 10 round-2 verified; 2 disc reports written; **Phase 0a-v2 round-2 COMPLETE (10 chunks)**. CRITICAL: chunk 9 M1 resolves distance-FB-row-6 mystery — column 6 (lasd) FB rows DROPPED from paper Tables 2/3 by `va_spec_fb_tab_all.do` keeper-rule omission. Bug 93 family LOCKED at 4 instances; blast radius NULL for current paper — 2026-04-26
- [x] Phase 0a-v2 SYNTHESIS — verified-final audit doc at `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md`. 89 verified bugs (5 P1 + 15 P2 + 69 P3); 7 T1 tests; 20 T4 questions; 13 ADRs queued for Phase 0e; 10-step Phase 1 playbook. **Verification protocol caught 3 confirmation-bias errors (1 per round + 1 prompt-construction). All resolved by T3 deterministic checks.** — 2026-04-26
- [x] Phase 0a-v2 FB-test correction — Christina identified that column 6 (lasd) FB blank cells are structurally correct, NOT a bug. FB test requires leave-out variables; `lasd` (kitchen sink + distance) has nothing left to leave out. `va_controls_for_fb` (`macros_va_all_samples_controls.doh:66`) excludes `lasd` by design. Reclassified 4 findings as NOT-A-BUG. Bug count revised: 89 → 85 (2 P1 + 14 P2 + 69 P3). T1 tests reduced 7 → 5. Distance-FB Row 6 mystery FULLY RESOLVED. — 2026-04-26
- [x] Phase 1 framing agreed — consolidate-first-fix-bugs-later split into Phase 1a/1b/1c. File ownership constraint locked: Matt Naven's files (NSC/CCC/CSU crosswalks, `merge_k12_postsecondary.doh`, `gecode_json.py`) stay UNTOUCHED. `mattschlchar.do` traced as Christina-owned production code (paper Table 8 chain). Phase 1 plan creation paused per Christina until Phase 0e walkthrough completes. — 2026-04-26
- [x] T1 empirical tests consolidated into `do/check/t1_empirical_tests.do`; T1-1 and T1-2 retired per ADR-0017 (Matt-Naven file ownership). Active T1 list = 3 tests (T1-3, T1-4, T1-5). — 2026-04-27
- [x] ADR-0017 written: Matt Naven's files stay untouched through Phase 1 (formalizes constraint previously held only in MEMORY/TODO). — 2026-04-27
- [x] **Phase 0e Q&A walkthrough COMPLETE** — Christina answered all 19 T4 questions in `quality_reports/audits/2026-04-27_T4_answers_CS.md`. — 2026-04-27
- [x] **T1-3 and T1-4 RUN ON SCRIBE** — T1-3 verdict: school_id == cdscode 1:1 (cosmetic rename only). T1-4: bug fired but per Q-6 CSVs not paper-feeding (cosmetic for paper). Logs in `quality_reports/audits/`. — 2026-04-27
- [x] **ADRs 0004-0016 (13 ADRs) all written and approved** — Phase 0e ADR sweep COMPLETE. Decision queue at `decisions/README.md`. Audit doc §4.6 synced. — 2026-04-27
- [x] **Plan v3 §5.1/§5.3/§5.4 revisions** — per-do-file logging convention + automated data-checks pipeline (six `do/check/check_*.do` files spec'd). Phase 1c bumped 2 → 3 weeks. (`a078f27`) — 2026-04-28
- [x] **Codebook export pipeline + PII remediation** — `do/explore/codebook_export.do`; ran on Scribe twice (PII-leakage caught + sanitized re-run). 10 datasets covered; sanitized log (3.8 MB) lives at gitignored `master_supporting_docs/codebooks/codebook_export_28-Apr-2026_13-25-41.log`. (`a078f27`) — 2026-04-28
- [x] **Data-checks design memo** — `quality_reports/reviews/2026-04-28_data-checks-design.md` (~250 lines). Per-check-file specs with codebook line citations. (`a078f27`) — 2026-04-28
- [x] **CalSCHLS index TBDs resolved** — climateindex (9), qualityindex (15), supportindex (4); 28 of 45 source QOIs used. ADR-0010 "9/15/4" fully decoded. (`8215bb0`) — 2026-04-28
- [x] **Phase 1a §3.1 pre-drafts** — settings.do (hostname-branched + master seed + fail-fast), main.do (7-phase skeleton), .gitignore extensions per ADR-0007. (`82a565e`, refined `e1cbc56`) — 2026-04-28
- [x] **ADR-0020** — file transfer is operator-choice (FileZilla); refines ADR-0007 §"Sync model"; sync wrapper scripts removed. (`3eb7167`) — 2026-04-28
- [x] **Phase 1a §3.2 folder build-out** — 13 missing tracked-dir stubs created (.gitkeep). CLAUDE.md folder map matches repo reality. (`f79d755`) — 2026-04-28
- [x] **`.claude/rules/phase-1-review.md`** — hard-gate coder-critic on every Phase 1 code commit. 4-tier defense; 80/100 gate; commit-message-footer audit trail. (`51036f5`) — 2026-04-28
- [x] **First coder-critic dispatch** — settings.do + main.do scored 94/100 PASS. M1+M2 findings + plan v3 §9 numbering bug addressed in followup. (`e1cbc56`) — 2026-04-28
- [x] **ADR-0021 — main.do+settings.do relocated under do/; self-contained sandbox principle (CANONICAL=write, LEGACY=read-only); description convention (header + main.do one-liner) codified in stata-code-conventions.md and phase-1-review.md checklist.** Coder-critic 92/100 PASS; both Minor findings (M1: retroactive coverage of two diagnostic files; M2: audit-marker for placeholder one-liners) addressed in same commit per reviewer's option (1). 11 files, 278+/83-. (`9120754`) — 2026-04-29
- [x] **Option A — six `do/check/check_*.do` skeletons** per data-checks design memo §2-§7. check_logs/check_samples/check_merges/check_va_estimates/check_survey_indices/check_paper_outputs. ~1,139 lines. Each has full ADR-0021 header (PURPOSE/INPUTS/OUTPUTS/ROLE IN SANDBOX/INVARIANTS/REFERENCES), per-do-file logging, capture-confirm-file skip-clean shim for unproduced inputs, design-memo-line citations on every assert. Coder-critic 84/100 PASS; all three findings (M1: ~22 early-exit log-close gaps; M2: ledger seeding for the six files; M3: `filelist` ssc package documentation in stata-code-conventions.md + 2 [LEARN:stata] entries) addressed in same commit. (`d775efe`) — 2026-04-29
