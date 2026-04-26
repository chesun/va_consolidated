# TODO — VA Consolidated (CEL Value-Added Project)

Last updated: 2026-04-26

## Active (doing now)

- [ ] Phase 0a-v2 batch 4 (chunks 9, 10) — round-2 agents dispatched 2026-04-26, running in background
- [ ] Bug 93 T1 empirical verification — Christina runs Stata snippet on Scribe when convenient; **scope expanded** to 4 instances (NSC UC, NSC UC ontime, CCC ontime, CSU ontime)
- [ ] **Revoke OpenCage API key** committed in `k12_postsec_distances.do:98` (security hygiene)

## Up Next

- [ ] After batch 4 completes: draft chunks 9, 10 disc reports
- [ ] Phase 0a-v2 Step 3 — adjudicate per tier (T1/T2/T3/T4) for all 10 chunks
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
