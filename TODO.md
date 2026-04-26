# TODO — VA Consolidated (CEL Value-Added Project)

Last updated: 2026-04-25

## Active (doing now)

- [ ] Phase 0a-v2 — plan + §10 answers locked 2026-04-25; **execution paused at Christina's request (rate-limit reset ~2 hrs); awaiting explicit "go" signal in a future session before any round-2 agent dispatches**
- [ ] Bug 93 T1 empirical verification — Christina runs Stata snippet on Scribe when convenient (snippet in `quality_reports/audits/round-2/README.md`)

## Up Next

- [ ] Phase 0a-v2 Step 1 — dispatch round-2 agents (chunks 1-10 in 4 parallel-batched waves)
- [ ] Phase 0a-v2 Step 2 — produce per-chunk discrepancy reports (`round-2/chunk-N-discrepancies.md`)
- [ ] Phase 0a-v2 Step 3 — adjudicate per tier (T1/T2/T3/T4)
- [ ] Phase 0a-v2 Step 4 — produce verified-final audit doc
- [ ] Phase 0a-v2 Step 5 — bug-priority triage (P1/P2/P3); ~101 bugs + Bug 93 scope correction
- [ ] Phase 0a-v2 Step 6 — Q&A consolidation for Phase 0e walk-through
- [ ] Phase 0e (design lock) — lock ADRs 0004-0016 against verified findings; consolidation plan v3
- [ ] Phase 1 (migration) — execute consolidation per plan v3

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
