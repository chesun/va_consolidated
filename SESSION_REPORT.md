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

---

## 2026-04-26 (continued) — Phase 0a-v2 batch 3 + batch 4 dispatched

**Operations:**

- Received chunk 6 round-2 (~68K, 17 files), chunk 7 round-2 (~30K, 32 files), chunk 8 round-2 (~70K, 26 files). All 3 batch-3 agents completed cleanly with adversarial framing intact.
- Drafted chunk-6, chunk-7, chunk-8 disc reports (cumulative AGREE counts: 14, 16, 14 respectively).
- T3.6 verification: counts_k12.tex paper-vs-code path "mismatch" is between OLD paper version + archived producer (`tables/sbac/counts_k12.tex`) and CURRENT working draft + modern producer (`tables/share/va/pub/counts_k12.tex`). Current draft uses correct path. M1 severity downgraded from HIGH to LOW (Phase 1 cleanup only).
- Dispatched batch 4 round-2 agents (chunks 9 and 10) in parallel; running.

**Commits:**

- `2f8e30d` — batch 3 round-2 verified (chunks 6-8) + 3 disc reports
- `380874a` — T3.6 verification (counts_k12.tex path)

**Key findings (batch 3):**

- **Distance-FB Row 6 producer chain LOCKED** end-to-end (chunk 7 round-2 confirms). `mindist_*` produced in `k12_postsec_distances.do:120-122`, merged via `merge_k12_postsec_dist.doh:23`, `d` token wired in `macros_va_all_samples_controls.doh:69-86`. Only 2 of 5 mindist vars (`mindist_any_nonprof_4yr`, `mindist_ccc`) actually enter `d_controls`. Open question for paper attribution remains: does paper Table 2/3 row 6 use `d` (chunk 7 wires it correctly) or `las` (chunk 3's `va_spec_fb_tab.do` does NOT load `d`-suffixed `.ster` files)? T4 for Phase 0e.
- **Sample-restriction map FINALIZED (chunk 8)**: 9-row map mapping paper Table A.1 to code. Two coexisting cohort cuts (`<=10` school-level + `<7` cell-level) confirmed not redundant.
- **Chunk 6 paper-α attribution issue (M1)**: climate/quality index item lists in `compcase/imputedcategoryindex.do` (9/15/4 items) ≠ α item lists in `alpha.do` (20/17/4/4 items). If paper-reported α is from `alpha.do`, the paper describes a DIFFERENT index than the regression's. T4 for Phase 0e.
- **Chunk 8 DISAGREE: 4 `pooledrr` definitions, not 2** (round-1 undercounted). Round-2 found definitions in 4 files with 2 structurally different formulas (conditional vs unconditional). All 4 save to different .dta files; on-disk collision avoided. Phase 1: rename to indicate scope.
- **OpenCage API key in source** at `k12_postsec_distances.do:98` (commented but committed). `[REVOKED 2026-04-30]...` — should be revoked.

**Status:**

- Done: 8 of 10 round-2 chunks verified (chunks 1-8); 8 disc reports written; T3.1-T3.6 verifications complete.
- Pending: chunks 9, 10 round-2 (running); Phase 1 bug priority triage; verified-final audit doc.

---

## 2026-04-26 (continued) — Phase 0a-v2 round-2 COMPLETE (chunks 9-10) + 2 critical findings

**Operations:**

- Received chunk 9 round-2 (53K, 13 files) and chunk 10 round-2 (35K, 6 files). Both agents wrote outputs before hitting org's monthly usage limit on the final summary message.
- Drafted chunk-9 and chunk-10 disc reports.
- **Phase 0a-v2 round-2 COMPLETE: 10 of 10 chunks verified, 10 disc reports written.**

**Commits:**

- `150ff42` — batch 4 round-2 verified (chunks 9-10) + 2 disc reports — Phase 0a-v2 round-2 COMPLETE

**Two CRITICAL paper-output integrity findings (from chunk 9):**

1. **Column 6 (`lasd`) FB rows DROPPED from paper Tables 2 and 3** (M1). `va_spec_fb_tab_all.do:82-84` keeper rule has NO branch for `va_control=="lasd"`. Combined with L115 `keep row entry1-entry5` truncation, column 6 FB entry is explicitly removed. **Result: paper Tables 2 and 3 column 6 (Distance) shows the spec-test row but BLANK FB rows. THIS RESOLVES THE CHUNK-3 DISTANCE-FB-ROW-6 MYSTERY.** The producer drops what chunk-7 wires up correctly.

2. **`va_spec_fb_tab_all.do` does NOT filter `predicted_score==0`** (M2). The chunks-7/8 added column would double rows in column-mapping reshape. The scrhat parallel `va_predicted_score_spec_fb_tab.do:59-64` correctly filters `& predicted_score == 1`. The non-scrhat producer of paper Tables 2 and 3 needs symmetric `& predicted_score == 0`.

**Bug 93 reframing (from chunk 10):**

- **Bug 93 paper-impact analysis: BLAST RADIUS IS NULL for current paper.** `nsc_enr_uc` consumed only by `csu_transfer_uc`; `csu_transfer_uc` not cited in paper. Composite outcomes (`enr_4year`, `enr_2year`, `enr`) do NOT use `nsc_enr_uc`. Phase 1 priority: still fix (cheap, prevents future inheritance), but **downgrade from PAPER-BLOCKING to LOW-impact (P2 not P1).**
- **Bug 93 family BOUNDED at 4 instances.** Round-2 verified zero instances in CCC/CSU crosswalks. Phase 1 patch template is finalized.
- **NEW potential silent bug at `crosswalk_nsc_outcomes.do:250`** — references local `id` which is not defined in the file. `egen ... by(\`id' collegecodebranch)` may collapse to `by(collegecodebranch)` only. T1 verification needed BEFORE Phase 1.

**Status:**

- **Phase 0a-v2 round-2 COMPLETE: 10 chunks verified, 10 disc reports written.**
- Pending: Phase 0a-v2 Step 3 (T1/T4 escalations to Christina); Step 4 (verified-final audit doc); Step 5 (bug-priority triage P1/P2/P3); Step 6 (Phase 0e Q&A consolidation).

---

## 2026-04-26 (continued) — Phase 0a-v2 SYNTHESIS COMPLETE (verified-final audit doc)

**Operations:**

- Wrote `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` consolidating 10 chunks of round-2 disc reports + 6 T3 verifications into a single 306-line reference doc.
- Synthesized Step 4 (verified-final audit) and Step 5 (bug-priority triage) into one document. Sections: Executive Summary, Bug-Priority Triage (P1/P2/P3), Action Items by Audience (T1 / Phase 0e / Phase 1), Reference (per-chunk pointers, ADRs, deps).

**Commits:**

- `6a8f74d` — VERIFIED-FINAL audit doc — Phase 0a-v2 SYNTHESIS COMPLETE

**Bug-priority triage outcomes:**

- **89 verified bugs** total: 5 P1 + 15 P2 + 69 P3.
- **P1 (5)**: Column 6 FB drop (chunk 9 M1 — paper Tables 2/3 integrity); `predicted_score==0` filter missing (chunk 9 M2); Distance-FB-Row-6 paper attribution; `id` macro at `crosswalk_nsc_outcomes.do:250` (potential silent corruption); paper-α attribution issue (chunk 6 M1).
- **P2 (15)**: Bug 93 family (4 instances, downgraded from P1 due to NULL paper blast radius); `va_corr_schl_char.do` LHS-peer-suffix bug; `cdscode` vs `school_id` cluster level; `run_prior_score=0` gate; `reg_out_va_sib_acs_tab.do` mtitles labeling bug; `reg_out_va_all_tab.do` mtitles 24-vs-32 col mismatch; `va_predicted_score_fb.do` non-scrhat lov list; `va_scatter.do` corr/b typos (6 lines); `merge_k12_postsecondary.doh:7` hardcoded path; NSC/CCC/CSU `enr` asymmetry; sibling het cluster mismatch; `va_var_explain.do` set-trace; OpenCage API key; `enrollmentclean.do` female-encoding; mattschlchar.do msnaven path.
- **P3 (69)**: cosmetic, dead code, comment-only restrictions, naming hygiene.

**Action items queued:**

- 7 T1 empirical tests for Christina on Scribe (~30-90 min in one session): paper TeX column-6 inspection, predicted_score check, `id` macro at L250, Bug 93 count, `school_id == cdscode`, mtitles vs CSV column count, OpenCage key revocation.
- 20 T4 questions for Phase 0e walkthrough (paper Table 2/3 row 6 attribution, paper-α attribution, NSC anchoring intent, sum-vs-mean, naming standardization, etc.).
- 13 ADRs queued for Phase 0e (ADRs 0004-0016).
- 10-step Phase 1 implementation playbook.

**Verification-protocol meta-finding:** 3 confirmation-bias-style errors caught (one per round + one prompt-construction artifact). All resolved by T3 deterministic checks. **Protocol works as designed in both directions.**

**Status:**

- Phase 0a-v2 SYNTHESIS COMPLETE. 13 commits over the day; ~10K lines of audit/disc/synthesis docs written.
- Ready for Phase 0e once Christina has time for T1 tests + Q&A walkthrough.

---

## 2026-04-26 (continued) — Christina FB-test correction: 4 findings reclassified NOT-A-BUG

**Operations:**

- Christina corrected my CB1 finding (column 6 FB drop in `va_spec_fb_tab_all.do`). FB test structure: (1) estimate VA without controls, (2) estimate VA with controls, (3) regress residual difference on round-1 VA. When VA spec is `lasd` (kitchen sink + distance), there are NO controls left to leave out → no FB test possible → blank FB cells BY DESIGN.
- T3 verified `macros_va_all_samples_controls.doh:66-76`: `va_controls_for_fb` lists 8 specs (`b l a s la ls as las`) and explicitly excludes `lasd`. There is NO `lasd_ctrl_leave_out_vars` macro defined.
- Christina extended: "this and other bugs you marked relating to the FB test are not actual bugs."
- Reclassified 4 findings as NOT-A-BUG: P1-1 / chunk-9 M1 (column 6 FB drop), P1-2 / chunk-9 M2 (predicted_score filter), P1-3 / chunk-3 A13 (distance-leave-out gap), P2-7 (va_predicted_score_fb.do non-scrhat lov list).
- Updated verified-final audit doc, chunk-3 disc, chunk-9 disc, MEMORY.md (added 2 [LEARN:domain] entries on FB test structure + paper Table 2/3 row 6 attribution).

**Bug count revised**: 89 → **85** (2 P1 + 14 P2 + 69 P3).

**Verification-protocol meta-finding (added)**: Round-2's adversarial framing pushed it to flag candidate-bugs aggressively, including 4 findings that turn out to be structural FB-test properties. Round-2 doesn't have FB-test theory; T4 (Christina) is the right adjudicator for "is this a bug or just a structural property?" **Lesson**: in future audits, escalate FB-test concerns to T4 BEFORE marking as P1/CRITICAL, OR include FB-test structure in the prompt upfront.

**Distance-FB Row 6 mystery FULLY RESOLVED**: column 6 of paper Tables 2/3 is the `lasd` (kitchen-sink + distance) column. Distance is INCLUDED IN THE VA SPEC, not used as a LEAVE-OUT. Spec-test row populated; FB rows correctly blank.

**Status:**

- Phase 0a-v2 SYNTHESIS revised. 5 T1 tests remaining for Christina (down from 7); 19 T4 questions (down from 20).
- Ready for Phase 0e.

---

## 2026-04-26 (continued) — Phase 1 framing discussion + ownership clarifications + plan deferred

**Operations:**

- Discussed consolidate-first-fix-bugs-later approach. Proposed Phase 1a (consolidate, behavior-preserving), 1b (bug fixes by priority), 1c (cosmetic cleanup) split. Christina agreed to the framing.
- Christina added scope constraint: "leave Matt Naven's files as-is; only fix code Christina owns." Bug 93 family stays UNFIXED in Phase 1; NSC/CCC/CSU crosswalks + `merge_k12_postsecondary.doh` + `gecode_json.py` (confirmed Matt-authored) stay UNTOUCHED. Path resolution still works on Scribe because Matt's hardcoded paths ARE the Scribe paths.
- Traced `mattschlchar.do` I/O lineage: Christina-authored wrapper (header L4-5: "written by Che Sun"); IS production code (wired into `master.do:412`; produces `schlcharpooledmeans.dta` consumed by both Table 8 panel producers). Underlying data file originates from Matt's user dir but is gated off; current production reads pre-built copy.
- Christina deferred Phase 1 plan creation: "Phase 0e is blocking — I need to answer your T4 questions first."

**Decisions:**

- Phase 1 plan creation BLOCKED until Phase 0e Q&A walkthrough is complete.
- File ownership constraint locked via [LEARN:domain] entry in MEMORY.md.

**Commits:**

- `322a33d` — Christina FB-test correction (4 findings reclassified NOT-A-BUG)
- (this commit) — late-evening logs + MEMORY [LEARN] entries

**Status:**

- Phase 0a-v2 fully closed.
- Up next: Phase 0e Q&A walkthrough (19 T4 questions; ~1-2 hours of Christina's time). Then 13 ADRs (0004-0016). Then detailed Phase 1 plan v3.
- All audit/synthesis work pushed to remote (origin: chesun/va_consolidated).


---

## 2026-04-26 14:05 — Hooks: context-monitor stderr fix + PreCompact auto-compact bypass fallback

**Operations:**

- Diagnosed missing pre-compaction notification: `~/.claude/sessions/088d2ff7/` had no `pre-compact-state.json` after auto-compact, despite both `claude-code-my-workflow` and `va_consolidated` correctly configuring `PreCompact` at `.claude/settings.json`. Hook works manually; fails on auto-compact under MCP servers (anthropics/claude-code#14111).
- Fixed `.claude/hooks/context-monitor.py`: warnings now print to `sys.stderr` (were going to stdout → invisible to user, model-only). Added `capture_precompact_snapshot()` fallback at the 90% threshold so state is written to `pre-compact-state.json` even when Claude Code silently bypasses PreCompact.
- Tuned `MAX_TOOL_CALLS` from 150 → 500 (env-var overridable via `CONTEXT_MONITOR_MAX_TOOL_CALLS`) to match observed Opus 4.7 1M-context auto-compact timing (~500 tool calls in this repo).
- Mirrored the patched `context-monitor.py` from `claude-code-my-workflow` to `va_consolidated`; verified byte-for-byte identical.

**Decisions:**

- Snapshot fallback added to `context-monitor.py` (PostToolUse) rather than as a new hook event — already runs every tool call and tracks the 90% threshold.
- Distinct `"trigger": "context-monitor-fallback"` value in fallback snapshots so log analysis can tell which path captured the state. `post-compact-restore.py` does not key on `trigger`, so restore behavior is unchanged.
- Did NOT promote PreCompact to global `~/.claude/settings.json`; user wants it as a workflow feature only, and the auto-compact bypass bug would not be fixed by going global.

**Results:**

- Manual test: 80% warning renders on stderr; 90% warning renders on stderr AND writes `pre-compact-state.json` with active plan + current task. `pre-compact.py` still works when manually invoked. Sync verified.

**Commits:**

- (this commit) — context-monitor stderr fix + PreCompact fallback + tuned heuristic

**Status:**

- Done: hook fix shipped + session log + SESSION_REPORT update.
- Pending: nothing on this thread; pre-existing audit work (chunks 9–10 round-2) untouched.

---

<!-- primary-source-ok: sun_2026 -->

## 2026-04-27 — Phase 0e walkthrough complete + 13 ADRs decided + architecture pivot + T1 closeout

**Operations:**

- Drafted `do/check/t1_empirical_tests.do` consolidating 5 T1 tests, then narrowed to 3 active tests after Christina's "skip Matt's files" instruction. T1-1 (id macro) and T1-2 (Bug 93 family) retired.
- Wrote ADR-0017 (Matt Naven's files untouched) formalizing the scope rule.
- Christina ran T1 tests on Scribe (logs in `quality_reports/audits/`):
  - T1-3 (school_id == cdscode): 1:1 confirmed (N=5009). P2-3, P2-11 → cosmetic rename only in Phase 1.
  - T1-4 (mtitles count): bug fired (49/33/33/33 cols vs 24 declared). Per Q-6, CSVs not paper-feeding → cosmetic for paper.
  - T1-5: manual reminder (revoke OpenCage key).
- Server path conventions corrected in t1_empirical_tests.do (`do_files/` and `log_files/` per fork structure).
- Christina completed Phase 0e Q&A walkthrough — all 19 T4 questions answered in `quality_reports/audits/2026-04-27_T4_answers_CS.md`.
- **Architecture pivot** triggered by Christina's clarifying questions on (a) repo scope (code-only vs code+data) and (b) GitHub remote on Scribe (network-exposure concern) and (c) handoff to non-git senior coauthor. Decision crystallized in ADR-0007.
- Wrote 13 ADRs (0004-0016) interactively with Christina approving each:
  - ADR-0004: Sibling-VA canonical pipeline (`va_{score,out}_all.do`); `siblingvaregs/` regressions deprecated
  - ADR-0005: `siblingoutxwalk.do` relocation to `do/sibling_xwalk/`
  - ADR-0006: vam.ado pinned at v2.0.1 + noseed-fix vendored to `ado/`
  - ADR-0007: Code-data separation; Scribe non-git working copy; rsync-only sync; GitHub frozen archive at handoff
  - ADR-0008: External crosswalks vendored to Scribe `consolidated/data/raw/upstream/` (Path B); runtime unchanged
  - ADR-0009: Prior-score v1 canonical for paper; v2 preserved as exploratory
  - ADR-0010: Paper-α from `indexalpha.do`; `alpha.do` archived as exploratory
  - ADR-0011: Survey indices computed as means, not sums (code fix in two factor-analysis files)
  - ADR-0012: `_tab.do` CSV outputs are local-review-only; paper tables come from `share/`
  - ADR-0013: `mattschlchar.do` clean-gate kept; `sch_char.dta` consumed as-is
  - ADR-0014: Old paper draft `common_core_va.tex` preserved as historical artifact
  - ADR-0015: Filipino-into-Asian race recoding intentional; documented in code
  - ADR-0016: `pooledrr` variable renamed by scope across 4 producers
- Synced docs: `decisions/README.md` (index + pending list pruned); audit doc §3.1 (T1 verdicts) + §4.6 (ADR status table); TODO.md (Phase 0e closed; Phase 1 plan up next); session log appended.

**Decisions (committed as ADRs):** see list above.

**Key meta-finding — architecture pivot:** Christina's 2026-04-27 questions about code-data separation reshaped Phase 1 design. Net architecture: GitHub repo holds code+docs+tables+figures only (no `.dta`/data); Scribe `consolidated/` is non-git working copy synced via rsync from Christina's local Mac (`.git/` never on Scribe = no GitHub credentials on restricted server); GitHub becomes frozen archive at handoff to non-git senior coauthor; single living README serves both audiences. Documentation discipline rule baked in: every ADR/log/commit written with successor in mind.

**Commits:**

- (this commit) — Phase 0e ADR sweep + T1 closeout + architecture pivot + audit/TODO sync

**Status:**

- Phase 0a-v2: CLOSED.
- Phase 0e Q&A: CLOSED.
- ADR sweep: 17 ADRs total, all Decided.
- T1 tests: 2 of 3 active tests run (T1-3 1:1, T1-4 bug fired but cosmetic per Q-6); T1-5 awaiting manual action.
- Audit doc + TODO + decisions index: synced.
- Up next: draft comprehensive Phase 1 plan v3 operationalizing ADRs 0004-0017.

---

<!-- primary-source-ok: sun_2022, sun_2026 -->

## 2026-04-27 (evening + end of day) — ADR-0018 (offboarding pivot) + ADR-0019 (NSC authorship) + Phase 1 plan v3 + closeout

**Operations:**

- Phase 1 plan v3 drafted at `quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md` — 10 sections, 3 sub-phases, 9 milestones, risk register, originally 5 open questions.
- Architecture pivot: Christina clarified there is no live handoff event. Her exit is offboarding from the lab; deliverable goes to **Kramer (lab data-management custodian)**. Successor is unknown at offboarding time. README is the only orientation. ADR-0018 written formalizing this; supersedes ADR-0007's "Handoff endpoint" subsection. Tag becomes `v1.0-final` (not `v1.0-handoff`). Acceptance criteria before tag: Christina runs full pipeline end-to-end on Scribe + README cold-read test by friendly non-Christina lab member; both must pass.
- Plan v3 updated to reflect ADR-0018: handoff→offboarding throughout, milestones M8/M9 split (acceptance run + cold-read pass / freeze + Kramer deposit), risk register replaces successor-onboarding risk with cold-read-failure + acceptance-run-failure, §8 Q3-Q5 resolved.
- Plan §8 Q1 (main.do Matt-file calls) — Christina pushed back; verified via grep that ZERO production code invokes `crosswalk_*_outcomes.do`. They're static run-once-cached artifacts. Plan §3.4 corrected; settings.do gets `$matt_files_dir` global; no predecessor-bridge wrapper needed.
- **NSC-crosswalk authorship surprise**: file header reads "First created by Che Sun March 17, 2022 ... Based on code from Matt Naven." Round-1 chunk-10 audit had flagged this as "heavy refactor by Christina." File is Christina's, not Matt's. ADR-0017's "Matt's files" list was wrong on this one. Lineage trace from round-1 chunk-10 §File 2 captured: input is per-cohort raw NSC (Kramer-cleaned); output `nsc_outcomes_crosswalk_ssid.dta` is paper-load-bearing via `merge_k12_postsecondary.doh:67` → paper Tables 4-7. Producer is NOT pipeline-active.
- Christina chose option (B): own authorship + add Phase 1c header note, but don't change Phase 1 scope (Bug 93 paper-null per audit; ½-day fix not justified vs. offboarding acceptance run). ADR-0019 written formalizing.
- Plan v3 §8 fully resolved; Q2 (paper LaTeX) confirmed out of scope.
- Synced: TODO.md T1-retired rationale (now Christina-time-budget for NSC instances, Matt-ownership for CCC/CSU); audit doc §3.1 T1 entries; session log final wrap entry.

**Decisions (committed as ADRs):**

- ADR-0018 (offboarding model refinement: Kramer custodian, successor unknown, full-pipeline acceptance run + README cold-read as gates before `v1.0-final` tag, no Christina-availability buffer).
- ADR-0019 (NSC crosswalk authorship correction: Christina-authored, Mar 2022; refines ADR-0017 file list to 4 files; Phase 1 leaves untouched anyway by time-budget).

**Commits:**

- `e7e71d5` — ADR-0018 + Phase 1 plan v3 draft
- `f113ba1` — ADR-0019 + plan v3 §8 closeout
- (this commit) — end-of-day session log + SESSION_REPORT update + MEMORY [LEARN] entries

**Status (end of 2026-04-27):**

- ADR ledger: **19 Decided** (0001-0019). Phase 0e fully closed.
- Phase 1 plan v3: DRAFT, all open questions resolved, ready for Christina to mark APPROVED and start Phase 1a §3.1.
- T1 tests: 2 of 3 run successfully (T1-3, T1-4); T1-5 (OpenCage revoke) awaiting manual action.
- 3 commits pushed today: 5d5f62d (Phase 0e closeout), e7e71d5 (ADR-0018 + plan v3), f113ba1 (ADR-0019 + plan §8 closeout).
- Documentation discipline per ADR-0007 holding: every decision captured in ADRs + session logs + audit cross-refs. Audit trail durable for offboarding.
- Outstanding for Christina: mark plan v3 APPROVED when ready; T1-5 OpenCage key revocation when convenient; start Phase 1a §3.1 (Scribe sync setup) on next session.
