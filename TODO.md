# TODO — VA Consolidated (CEL Value-Added Project)

Last updated: 2026-04-26

## Active (doing now)

- [ ] **Phase 0a-v2 SYNTHESIS COMPLETE** — verified-final audit at `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md`. Awaiting T1 empirical tests + Phase 0e Q&A walkthrough.

## T1 Tests for Christina (run on Scribe when convenient — ~30-60 min in one session)

See verified-final audit §3.1 for snippets. **Reduced from 7 to 5 tests after Christina's FB-test correction (2026-04-26) reclassified 4 findings as NOT-A-BUG.**

- [ ] **T1-1** — `crosswalk_nsc_outcomes.do:250` `id` macro — does `college_begin_date` vary by student? (chunk-10 M1, potential silent corruption)
- [ ] **T1-2** — Bug 93 count test (4 instances)
- [ ] **T1-3** — `assert school_id == cdscode` in `va_all.dta`
- [ ] **T1-4** — Open `$vaprojdir/tables/.../reg_*.csv`; count actual columns vs declared mtitles (chunk-4 M4)
- [ ] **T1-5** — Revoke OpenCage API key at `k12_postsec_distances.do:98`

**Removed (resolved by Christina 2026-04-26):**
- ~~Column 6 FB rows blank?~~ — NOT A BUG (intentional, FB-test structural property)
- ~~`predicted_score==0` filter?~~ — NOT A BUG (separate dirs, no conflation)

## Up Next

- [ ] **Phase 0e Q&A walkthrough** with Christina — 20 T4 questions queued (verified-final §3.2). Estimated 1-2 hours.
- [ ] **Phase 0e ADRs 0004-0016** — write 13 ADRs against verified findings (consolidation-plan v3 lock).
- [ ] **Phase 1 (migration)** — execute consolidation per plan v3. 10-step playbook in verified-final §3.3.
- [ ] Phase 0a-v2 Step 4 — produce verified-final audit doc
- [ ] Phase 0a-v2 Step 5 — bug-priority triage (P1/P2/P3)
- [ ] Phase 0a-v2 Step 6 — Q&A consolidation for Phase 0e walk-through
- [ ] Phase 0e (design lock) — lock ADRs 0004-0016 against verified findings; consolidation plan v3
- [ ] Phase 1 (migration) — execute consolidation per plan v3

## Open T4 escalations (require Christina input at Phase 0e)

- [ ] Paper Table 2/3 row 6 = `d` (distance) or `las` (joint)? — chunk-3 disc report Q1
- [ ] `peer_<X>d_controls` peer-distance asymmetry — intentional or bug? — chunk-1 disc report Q1
- [ ] `Xd_str` display-string aliases (all collapse to `X_str`) — intentional or labeling bug? — chunk-1 disc report
- [ ] `enr=.` for NSC-non-matched-but-CCC-or-CSU-positive — intentional NSC anchoring or bug? — chunk-2 disc report A6
- [ ] NSC `keep(1 3 4 5)` + `update` — multi-vintage protocol intent? — chunk-2 disc report M3
- [ ] Where are special-ed/home-instruction restrictions enforced? — chunk-2 disc report A10

## Waiting On

- [ ] Christina signoff on Phase 0a-v2 verification plan (5 questions in §10 of the plan)
- [ ] Christina T1 Stata tests on Scribe (concentrated 30-90 min when convenient; Bug 93 + 4-5 others)

## Backlog

- [ ] Bug 93 (NSC UC inlist precedence) — P1 fix during Phase 1 (will need Stata test confirmation first)
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
