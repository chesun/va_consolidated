# Session Report - va_consolidated (Common Core VA Project)

Append-only consolidated log of operations across sessions. Per-session detailed logs live in `quality_reports/session_logs/`.

---

## 2026-04-24 - Project onboarding and hook fix

**Operations:**

- Read `va_paper_clone/paper/common_core_va_v2.tex` end-to-end (1357 lines).
- Created `quality_reports/session_logs/2026-04-24_project-onboarding.md` (5-round Q&A capturing project identity, repo scope, paper status, runtime, languages, definition of done).
- Created `quality_reports/reviews/2026-04-24_paper-map.md` (structured index of every load-bearing claim, table, and figure in the paper to its expected input file path; identifies six canonical pipelines that must reproduce in the consolidated repo).
- Created `quality_reports/reviews/2026-04-24_primary-source-hook-fix-memo.md` (diagnosis memo for the workflow repo to implement universal fixes for primary-source-check.py false-positive regex bugs; identified 4 distinct failure modes plus a separate escape-hatch regex bug).
- Populated `.claude/state/primary_source_surnames.txt` with 210 surnames auto-extracted from `va_paper_clone/literature/bibtex/common_core_va.bib` (1389-line bib).
- Verified the populated allowlist filters previously-blocking false positives (Only 2002, Spring 2015, CalSCHLS 2017, etc.) while preserving real citations (Naven 2022, Chetty 2014, Carrell-and-Sun 2024).
- Updated `MEMORY.md` with [LEARN:domain] entries for v1/v2 prior-score-control definition and repo scope, plus a [LEARN:discipline] entry for the no-assumptions rule.
- Created `.claude/state/server.md` (gitignored) with Scribe SSH info: `Scribe@ssds.ucdavis.edu`, project root `/home/research/ca_ed_lab/projects/common_core_va`, Stata 17.

**Decisions:**

- Repo scope = TWO predecessor repos: `~/github_repos/cde_va_project_fork` + `caschls` at the Dropbox path. NOT `ca_ed_lab-common_core_va` (superseded), NOT `common_core_va_workflow_merge` (2022 abandoned).
- Definition of done for the 3-month consolidation: (a) reproduces rejected-paper end-to-end, (b) cleanly resolves sibling/VA dependency, (c) survives future-me audit. NOT AEA-package readiness.
- Runtime location = restricted server only (Scribe), SSH terminal sessions only. Air-gapped workflow rule applies.
- Languages = Stata only; py_files/ in both predecessor repos is dead/unused.
- v1 = canonical prior-score variant (used in the paper). v2 explored but never reported.

**Key facts captured:**

- Paper "Do Schools Matter?" by Carrell, Kurlaender, Martorell, Naven, Sun. IES Grant R305E150006. Status: submitted, rejected, in limbo pending coauthor/PI decision.
- Working draft: `~/github_repos/va_paper_clone/paper/common_core_va_v2.tex` (NOT in va_consolidated yet).
- Estimator: CFR-style "value-added with drift" at school level; Eq (1) does NOT include school FE (differs from the original CFR baseline; estimates correlate at 0.99 either way).
- Sample: 4 cohorts of 11th-graders 2014-15 through 2017-18, ~2M students, ~1,400 high schools.
- Sibling crosswalk lives in caschls; address+surname matching with transitive closure; address data 2002-03 through 2012-13.
- CalSCHLS surveys 2017-2019 used for school-level mechanism analysis (cannot link to individual records).

**Commits:**

- (this session - see git log)

**Status:**

- Done: project context loaded across 5 question rounds, paper read, paper map produced, hook memo produced, surname allowlist populated, server info captured.
- Pending: deep-read of `cde_va_project_fork` + `caschls` master/settings/SBAC scripts; characterize sibling-VA circular dependency; draft consolidation ADRs; finish CLAUDE.md/README.md placeholder cleanup. See `TODO.md`.

---

## 2026-04-25 — Master-file audit + consolidation plan + foundational ADRs

**Operations:**

- Master-file audit: 56/66 referenced in fork's `do_all.do`; 89/112 in caschls's `master.do` (after extension normalization). Per-disposition decisions in `quality_reports/reviews/2026-04-25_master-file-audit.md`.
- 4 archival commits in `cde_va_project_fork` (Matt-original VA do-files → `_archive/matt_original/`; cde_presentations + kramer_nsc + resources → `_archive/`; nsc_outcomes crosswalk → `do_files/upstream/`; va_scatter_plot → `_archive/`). Plus `prior_decile_original_sample.do` registration into `do_all.do`.
- 4 archival commits in `caschls` (deprecated outcomesumstats/siblingvaregs files → `do/archive/`; Matt-style files → `do/archive/matt_original/`; CCC/CSU crosswalks elevated from archive to `do/upstream/`; `enrollmentconvert.do` → `do/local/`).
- Consolidation plan v2 written incorporating Christina's feedback (Phase 0 deep-read elevated to BLOCKING; py_files preserved as upstream geocoding; root-level do/ + py/; main.do not master.do; siblingoutxwalk relocation flagged).
- CLAUDE.md folder structure refactored (scripts/ removed; root-level do/ + py/ + ado/ + main.do + settings.do).
- ADRs 0001-0003 written (consolidation-scope, runtime-server-only, languages-stata-primary-python-upstream).

**Decisions (committed as ADRs):**

- 0001 — In-scope: cde_va_project_fork (changes_by_che) + caschls (main). Out-of-scope: ca_ed_lab-common_core_va (superseded), common_core_va_workflow_merge (abandoned).
- 0002 — Runtime: Scribe only, hostname-branched settings.do.
- 0003 — Languages: Stata primary, Python upstream-only (geocoding preserved), R out of scope.

**Commits**: see git log; ~25+ commits across cde_va_project_fork, caschls, va_consolidated.

**Status**: master-file inventory known-complete; consolidation plan v2 ready; foundational ADRs locked. Phase 0 deep-read pending.

---

## 2026-04-25 — Phase 0a deep-read marathon (10 chunks complete)

**Operations:**

All 10 chunks of Phase 0a deep-read complete via dispatched general-purpose agents. ~150 files audited.

- Chunk 1 (foundation, 6 files): two-folder server geometry mapped (N2 RESOLVED); vam = unmodified Stepner v2.0.1 (no customization); 3 bugs found and fixed (`asd_str` typo, missing semicolon in `macros_va.doh`; `noseed` no-op in `vam.ado`).
- Chunk 2 (helpers, 17 files): v1 prior-score table verified line-by-line; v2 user-table dates were transcription errors (code uses L5 = 5-year lag); `_scrhat_` orthogonal third axis confirmed; sample-restriction sequence mapped.
- Chunk 3 (VA core, 14 files): output-filename grammar formalized; `sp/ct/lv` literal separators (not macros); spec-test/FB-test β tracing complete; `out_drift_limit.doh` confirmed dead code.
- Chunk 4 (pass-through + heterogeneity, 11 files): paper Tables 4-7 producers mapped; `_m`/`_wt`/`_nw` naming tokens resolved; SE clustering audit (one deviation: `va_het.do:158` uses `cdscode` not `school_id`).
- Chunk 5 (sibling, 33 files): **N1 RESOLVED — SAFE to relocate `siblingoutxwalk.do`**; sibling-matching specifics documented (5-component address join + last_name; `group_twoway` transitive closure; 10-child cap); 4-spec convention `og/acs/sib/both`.
- Chunk 6 (survey VA, 17 files): paper Table 8 producer chain mapped; index = SUM (not "average" per paper text); `mvpatterns` ssc package new.
- Chunk 7 (data prep, ~30 files): **Distance-FB Row 6 RESOLVED** (`d` token wired in `macros_va_all_samples_controls.doh`); ACS only 2010-2013; `enrollmentclean.do` female-encoding bug.
- Chunk 8 (samples, 25 files): sample-restriction map definitively resolved (both `<7` per-cell and `<=10` cohort cuts coexist); `gr11enr_mean` weight chain; archive disposition for `sum_stats.do` initially flagged then corrected.
- Chunk 9 (share + explore, 13 files): all paper Tables 1-8 + Figs 1-4 producers in `share/` — closed loop; modern `share/sample_counts_tab.do` produces `counts_k12.tex` (corrects chunk-8 alarm); scrhat exploratory-only.
- Chunk 10 (upstream + Python, 6 files): 1 Python script (Census Geocoder API, free, keyless); 3 in-scope crosswalks + 2 external static; **CRITICAL Bug 93** in `crosswalk_nsc_outcomes.do` (paper-load-bearing).

**Decisions / commits:**

- 11 commits during deep-read (one per chunk + companion docs)
- Bit-rot estimate revised: last full pipeline run was probably mid-2024 (not 2023), based on `counts_k12.tex` mtime 2024-07-04. Bit-rot window narrows from ~3 years to ~21 months.

**Status**:

- Phase 0a complete. ~150 files audited; ~101 bugs/anomalies inventoried; ~30 user-facing questions queued; 80+ naming tokens; 16 ssc packages; 5 external static inputs.
- All foundational questions resolved (N1, N2, distance-FB, v1/v2, vam compat, paper-output mapping).
- Most material finding: Bug 93 (NSC UC inlist precedence) is paper-load-bearing → P1 priority for Phase 1 fix.

---

## 2026-04-25 — Phase 0a-v2 setup (independent blind verification)

**Operations:**

- Christina raised concern about agent confirmation bias / echo-chamber drift / synthesis-time fabrication; demanded "ABSOLUTELY ROCK SOLID" verification.
- Christina pressed sharper question: my own confirmation-bias risk on findings I synthesized. Honest acknowledgment + revised plan.
- Four-tier adjudication structure agreed: T1 empirical (Christina runs Stata), T2 adversarial agent, T3 deterministic check, T4 user investigation.
- Pre-flight T3 verification of Bug 93: round-1 chunk-10 over-claimed scope by 50% — only L218-219 and L226-228 are buggy (lines 222 and 230 have protective outer parens). Validates verification approach.
- Round-1 audit docs sequestered to `quality_reports/audits/round-1/` (9 files renamed via `git mv`).
- `quality_reports/audits/round-2/` created with protocol README documenting blind-sequester rules.
- Phase 0a-v2 plan written at `quality_reports/plans/2026-04-25_phase-0a-v2-verification-plan.md`. 12 sections covering scope, tier structure, step-by-step execution, per-chunk verification matrix, cost estimate, commit cadence, gating diagram, pre-flight result, open questions for Christina, and what changes after Phase 0a-v2.

**Decisions:**

- Verification scope: every Phase 0a finding (per Christina: "every single finding").
- Sequester: round-2 agents forbidden to read `round-1/`; produce findings independently from primary sources.
- Adversarial framing: round-2 + T2 adversarial agents told burden of proof is on the claim.
- I am NOT adjudicator for findings I synthesized; T1 (empirical), T2 (third agent), or T4 (Christina) handles.

**Commits**: `fa07571` (sequester + protocol README + pre-flight result) + plan-and-TODO updates.

**Status**: Phase 0a-v2 plan written and committed. **Awaiting Christina signoff on the plan before launching round-2 agents.** Five open questions in §10 of the plan.

---

## 2026-04-26 — Phase 0a-v2 batch 1 round-2 + chunk-1/2/3 disc reports + T3 verifications

**Operations:**

- Resumed Phase 0a-v2 after ~2hr rate-limit pause. Christina locked §10 answers; gave "ok lets resume".
- Dispatched and received round-2 verification of chunks 1, 2, 3 via 3 sequestered general-purpose agents (forbidden from reading round-1, instructed adversarial framing, required line-citation). Outputs at `round-2/chunk-1-verified.md`, `chunk-2-verified.md`, `chunk-3-verified.md`.
- Drafted per-chunk discrepancy reports at `round-2/chunk-1-discrepancies.md`, `chunk-2-discrepancies.md`, `chunk-3-discrepancies.md` with categories AGREE / ROUND-1-MISSED / ROUND-2-MISSED / DISAGREE / TEMPORAL-ARTIFACT.
- Performed 5 T3 deterministic verifications at `round-2/t3-verifications.md` resolving latent-bug questions and Bug 93 family regression sweep.
- Dispatched batch-2 round-2 agents (chunks 4 and 5) in parallel; running.

**Decisions / commits:**

- `9c41833` — chunks 1-3 round-2 verified + chunk-1 disc report
- `ff0b1b3` — chunks 2 and 3 disc reports
- `6f51ad7` — T3 verifications doc

**Key findings:**

- **Bug 93 family is 4 active instances** (NSC UC at L218-219 + L227-228, CCC ontime at merge_k12_postsecondary.doh:168-170, CSU ontime at :232-234). Phase 1 fix should bundle all 4 with a single inlist-precedence patch template. Adds CCC and CSU to the original chunk-10-only Bug 93 scope.
- **Two confirmation-bias errors caught — one by each round.** Round-2 chunk-2 mis-flagged `asd_str` typo as still active (was fixed in `e8dd083`); round-1 mis-flagged `peer_L3_cst_ela_z_score` as missing from keepusing (it IS at L29). Both caught by T3. The verification protocol works in both directions.
- **vam customization is a temporal artifact** — round-1 read pre-noseed-fix, round-2 read post-fix; both correct in their respective contexts. Phase 1 ADR-0009 should reflect the noseed fix as a deliberate customization (and update the `*!` line to bump version).
- **macros_va.doh has TWO missing-`;` bugs**: round-1 caught L558 (fixed in `e8dd083`), round-2 caught L23 (still open). Both LATENT — `$vaprojdofiles` and `$ca_ed_lab` are never consumed.
- **Distance-leave-out (`d`) FB-test row gap**: BOTH rounds independently flagged that `va_spec_fb_tab.do` loops `lovar in l s a las` and does NOT include `d`. Paper Table 2/3 row 6 attribution is the main open T4 question for chunk 3.

**Status:**

- Done: 3 of 10 round-2 chunks verified; 3 disc reports written; T3 verifications complete.
- Pending: chunks 4 and 5 round-2 (running); chunks 6-10 still to dispatch; Phase 1 bug priority triage; verified-final audit doc.

---

## 2026-04-26 (continued) — Phase 0a-v2 batch 2 + batch 3 dispatched

**Operations:**

- Received chunk 4 round-2 (53.8K, 11 files) and chunk 5 round-2 (1162-line, 32 files actually present — round-2 prompt had a spurious `reg_out_va_sib_acs_dk_tab.do` due to my symmetry assumption; T3 confirmed file doesn't exist).
- Drafted chunk-4 disc report (13 AGREE, 5 ROUND-1-MISSED, 2 ROUND-2-MISSED, 0 DISAGREE) and chunk-5 disc report (14 AGREE, 6 ROUND-1-MISSED, 4 ROUND-2-MISSED, 0 DISAGREE).
- Dispatched batch 3 round-2 agents (chunks 6, 7, 8) in parallel; running in background.

**Commits:**

- `23a801c` — batch 2 round-2 verified (chunks 4-5) + 2 disc reports
- `e38ed0c` — SESSION_REPORT + TODO interim update
- `36f874a` — MEMORY [LEARN] entries (Bug 93 family, _scrhat_ exploratory, verification-protocol discipline)

**Key findings:**

- **N1 verdict reaffirmed by both rounds**: SAFE to relocate `siblingoutxwalk.do` to `siblingxwalk/`. Two callers need updating in Phase 1: `master.do:103` and `do_all.do:142`. ADR-0004 unblocked.
- **chunk 4 most-material**: `reg_out_va_all.do:235 local run_prior_score = 0` — gates off single-subject prior-decile heterogeneity regs; the fig file unconditionally tries to load the gated `.ster` files. Fragile reproducibility; T4 question for Phase 0e.
- **chunk 4 file 4 mtitles 24-vs-32 column mismatch** (round-2 finding): possibly producing un-labeled or truncated columns in paper Table 4. T1 needed: open `$vaprojdir/tables/.../reg_*.csv` on Scribe and count columns vs declared mtitles. Combined with chunk-5 M1 mtitles labeling bug, suggests a multi-chunk pattern: Phase 1 should sweep all `esttab mtitles(...)` calls.
- **chunk 5 mtitles labeling bug** in `reg_out_va_sib_acs_tab.do` L82-88: uses FB-test column titles for what is a persistence-on-VA regression table. HIGH PRIORITY if these CSVs feed paper Table 7.
- **DK controls in `va_sib_acs_out_dk.do:64`**: hard-coded `va_ela_og va_math_og` across all 4 specs (og/acs/sib/both). Both rounds flagged. T4 question: design choice (single OG baseline) or bug (DK should be spec-matched)?
- **Verification-protocol confirmed errors so far: 3** (round-2 asd_str false positive in chunk 2, round-1 peer_L3_cst false positive in chunk 2, my round-2 prompt's spurious filename in chunk 5 — caught when round-2 noted file doesn't exist). All resolved by T3 deterministic checks.

**Status:**

- Done: 5 of 10 round-2 chunks verified (chunks 1-5); 5 disc reports written; T3 verifications complete.
- Pending: chunks 6, 7, 8 round-2 (running); chunks 9, 10 still to dispatch; Phase 1 bug priority triage; verified-final audit doc.
