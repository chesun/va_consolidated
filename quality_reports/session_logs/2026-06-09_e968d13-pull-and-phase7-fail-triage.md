# Session Log — e968d13 pull + Phase-7 FAIL triage

**Dates:** 2026-06-08 → 2026-06-09
**Goal:** Pull the most-recent server master run, review its logs, confirm end-to-end completion, and triage what the data checks surfaced.

## What happened

1. **Push-block resolved.** The server push had failed because the root-dir `main.log` (Stata `-b` batch auto-log) exceeded GitHub's 100 MB limit. Christina fixed + pushed on the server. Locally: added anchored `/*.log` + `nohup.out` to `.gitignore` (root-level batch artifacts only; the curated `log/<reldir>/` tree stays tracked). Commit `7ccf418`, pushed.

2. **Pulled `e968d13` "server pipeline run"** (7,685 files; table `.dta`/`.csv` + 240 run logs). Stashed local test-run log artifacts first (`stash@{0}`, recoverable) to avoid collisions; fast-forward pull clean.

3. **Run-log review** (`2026-06-08_server-run-e968d13_log-review.md`). Confirmed end-to-end: all 7 phases, **206/206 `[RUN]`/`[OK]`**, RUN START 1 Jun 21:30:55 → RUN END 3 Jun 03:01:24 (`m4_acceptance_run=1`, full rebuild on scribe). No fatal Stata errors in this run's per-file logs. Phase-7 checks: 22 PASS, **2 FAIL**, 1 SOFT.

4. **rc-clobber bug found + fixed.** `check_va_estimates.do` + `check_survey_indices.do` intended hard-halt but ran `cap log close`/`cap translate` before `exit _rc` — `cap` reset `_rc` to 0, so FAILing checks exited clean and the pipeline never halted (and the FAILing check exited *early*, skipping its own later sub-checks). Fix: `local rc = _rc` after each assert, `exit `rc''`. 13 branches. coder-critic **95/100**.

5. **FAIL 2 (ADR-0027):** imputed `secqoi27mean_pooled` max 2.61 > Likert 2.0 — `imputation.do` uses unbounded OLS `reg`+`predict`. **Decision: clamp** imputed predictions to [-2,2] (all 4 loops). coder-critic caught (and I verified) that the FAILing SUB-CHECK 1 read the **LEGACY** predecessor file, not the CANONICAL clamped output → **re-pointed SUB-CHECK 1 to CANONICAL**. coder-critic 82 (clamp) + 94 (re-point).

6. **FAIL 1 (ADR-0028):** `n_g11_ela_l_sp` min 4 < 5. Root cause (code-traced): base `>=7` filter (`touse_va.do:295-298`) binds the base count; the `l` variant drops students (`merge_loscore.doh:76,82`); count summed *after* the drop (`va_score_all.do:247`) → subsample cells fall below 5. **Decision: accept** (CFR shrinks thin cells; weight-only) → per-spec count check downgraded hard→soft.

7. **Committed `7ee1548`** (3 code files + ledger re-stamp + ADR-0027/0028 + index + 4 review reports), pushed.

## Key finding at session end (production-readiness)

Asked whether "everything else passes QA / is production-ready" — **answer: no, not certifiable.** The rc-clobber early-exits meant a chunk of the suite **never ran** this run:

- `check_va_estimates`: SOFT cross-spec + peer correlations — skipped.
- `check_survey_indices`: compcase source + **all of SUB-CHECK 2** — skipped, including the raw-index range check that verifies the **ADR-0011 sums→means** fix.
- **M4 golden-master** (cfout vs predecessor — the ADR-0018 acceptance gate) — not run at all.

The 3 fixes are code-reviewed + locally mechanic-tested but **not re-run on Scribe data**.

## Open items

- **One clean Scribe re-run** with the fixes: FAIL 1 now soft (won't block), FAIL 2 should pass (clamp + re-point) → all 6 checks run to completion → then run the **golden-master** and confirm it matches the predecessor.
- **Caveat to watch:** re-pointed SUB-CHECK 1 `assert _N == 5625` now validates the *consolidated* file's N for the first time; if it differs from the predecessor's 5625, triage as data, not a check bug.
- `stash@{0}` (local pre-pull log artifacts) still held — droppable when convenient.
- Vestigial dead loop `create_score_samples.do:376-384` (no `save`, omits `as`) — cleanup candidate, noted in ADR-0028.

## Reviews / decisions produced

- ADR-0027 (clamp + re-point), ADR-0028 (accept thin cells + soft check).
- Reviews: `2026-06-08_server-run-e968d13_log-review`, `2026-06-09_check-files-rc-fix_coder_review` (95), `2026-06-09_imputation-clamp_coder_review` (82), `2026-06-09_check-soft-and-repoint_coder_review` (94).
- Commits: `7ccf418` (gitignore), `7ee1548` (triage).

## Addendum — golden-master runnability + rc-report fix + cleanup (2026-06-09, later)

- Confirmed `do/check/m4_golden_master.do` runnable (static review: `include do/settings.do`; 8,324-row `m4_path_matrix.csv` present; all globals bound; built-in `cf` + optional `cfout` graceful fallback; shell `cmp`/`diff`/`pdftotext` wrapped in `capture`; `/*` 8=8, braces 57=57; 0 hardcoded paths). Config note: `tier_filter` defaults `"smoke"` — set `"full"` for the real comparison.
- Smoke run (5 pairs): **4 PASS + 1 READ_ERROR**. PASS across `.dta` (0 diffs), `.tex`/`.pdf` (byte-identical), `.ster` (0 coef/SE). READ_ERROR on `estimates/va_cfr_all_v1/va_est_dta/va_all.dta` — both files exist → structural `cf` mismatch (super-master VA dataset shape differs); investigate intended-vs-regression.
- Fixed golden-master rc-reporting bug: READ_ERROR/FAIL detail strings used `` `_rc' `` (local-macro → blank rc) not system `_rc`; `local rc=_rc` captured before the returns in all 4 branches (dta cf, dta cfout-fallback, ster pred-load, ster cons-load). coder-critic **96/100**. Commit `17418e9`.
- Cleanup (per Christina): removed the downloaded root `m4_golden_master.log`; dropped `stash@{0}`. `output/m4_diff_summary.txt` was initially `git rm`'d locally, but RESTORED on integrating `dd94f62` — Christina committed the golden-master run artifacts (`output/m4_diff_summary.txt` + `log/check/m4_golden_master.{log,smcl}`) from Scribe; kept the tracked server version (the earlier "delete" targeted the local download copy, superseded by the server commit).
- Updated state docs: `SESSION_REPORT.md` (+ `.claude/` mirror), `research_journal.md`, `TODO.md`, this log.

**Now in flight:** full golden-master on Scribe (`tier_filter="full"`, 8,324 pairs). **Next:** triage `m4_diff_summary.txt` (intended ADR deviations vs regressions; `va_all.dta` structural diff). **Pending:** clean Phase 5–7 re-run to propagate the clamp + complete all six checks.

## Addendum 2 — dd94f62 golden-master was SMOKE not full; tier flipped to full (2026-06-09, evening)

- Checked the server's committed `dd94f62` golden-master output: it was the **smoke tier (5 pairs)**, not full — `output/m4_diff_summary.txt` header `# tier_filter: smoke`, `rows_compared: 5`, and `do/check/m4_golden_master.do:394` was still `"smoke"` (the `tier_filter→"full"` edit was never applied on the server).
- The rc-report fix is confirmed working: `va_all.dta` READ_ERROR now prints `rc=9 on cf _all` (blank pre-fix). `rc=9` ⇒ the predecessor + consolidated `va_all.dta` don't conform (`cf` requires equal obs) → **structural mismatch**; confirm exact cause on Scribe with `count`/`describe` on both.
- Flipped `tier_filter` → `"full"` and pushed (`e999102`) so the next Scribe `git pull` + run is the full 8,324-pair comparison.
- **NEXT (fresh session):** on Scribe `git pull` → `nohup stata -b do do/check/m4_golden_master.do &` → triage `output/m4_diff_summary.txt`. Revert `tier_filter` → `"smoke"` after the acceptance run.
- Commits this segment: `9d8bb78` (state docs + cleanup), `e999102` (tier→full).

## Addendum 3 — FULL golden-master run triaged (2026-06-10)

- Christina ran the full 8,324-pair golden master on Scribe (80.1 min, clean RUN END, rc-report fix confirmed) and pushed `7fe9c1a`; pulled and triaged locally.
- **Tally:** 3,969 PASS / 46 FAIL / 560 READ_ERROR / 3,727 MISSING_PRED (3,717 of those "neither side exists" → benign matrix over-enumeration) / 22 MISSING_CONS.
- **All paper-facing tex/pdf/csv/xlsx PASS** (byte-identical or within tolerance); 3,166 ster at 0 coef/SE diffs including all main specs.
- **46 FAILs** = small coef diffs (max|db| 0.010–0.047, SEs within tol), 100% confined to `_la_`/`_las_`/`sib1` sample variants in `spec_test`+`reg_out_va` → hypothesis: intended ADR-0026/0028 deviations; confirm e(N) on Scribe.
- **560 READ_ERRORs** = `cf` rc=9 structural mismatches (incl. va_samples `score_*`/`out_*`, va_est_dta, analysisready) + 3 rc=900 (too wide for cf; raise maxvar). Downstream PASSes suggest variable-set diffs, not data regressions; classify on Scribe with `describe`/`count`.
- **22 MISSING_CONS** = cde clean years 2013/14/19/20 + sch_char_2019 → looks like intended year descope; needs ADR/plan citation.
- Full triage: `quality_reports/reviews/2026-06-10_m4-full-golden-master_triage.md`. Not yet ADR-0018-certifiable pending the 3 on-server confirmations + clean Phase 5–7 re-run + tier_filter revert.

## Addendum 4 — spot-check results (2026-06-11)

- Script `do/debug/m4_spotcheck_triage.do` (coder-critic PASS 97/100, commit 8322680) ran clean on Scribe (log commit aa43824, 69s).
- Sec 1: FAIL .ster N deltas confirmed sample-driven — sib1 +41 (clust 1020→1015), las −564 (1228→1219), la −1,084 (1263→1252).
- Sec 2: ALL six rc=9/rc=900 pairs have identical N + identical varlists → value diffs, not structural. sec1617 cf rc=0 (maxvar artifact → PASS). score_b: only 5 vars differ, all mindist_* (50,766 rows) → k12_postsec_distance input differs; NO ADR covers it — OPEN. va_all/analysisready: differing vars are restricted-variant va_* estimates (downstream of sample shifts).
- ADR-0029 written (cde year coverage 2015–2018; 22 MISSING_CONS = intended). Commits: eeea9b2, 8322680, a60837c.
- NEXT: trace mindist_* divergence (do/data_prep/k12_postsec_distance vs predecessor; rule out sort-order); then classify FAIL/READ_ERROR population and decide ADR-0018 acceptance. Pending: clean Phase 5–7 re-run; revert tier_filter→smoke.

## Addendum 5 — mindist_* ROOT CAUSE identified (2026-06-11)

- `k12_postsec_distances.do:139` fetches the LIVE CDE school directory URL at run time (cached pubschls.txt 3/20/23 is only the _rc!=0 fallback at :142) — predecessor-original logic, not a consolidation change.
- e968d13 run log (`log/data_prep/k12_postsec_distance/k12_postsec_distances.log:276-282`) proves the URL fetch SUCCEEDED (fallback import echoed but produced no obs output) → consolidated distance file = June-2026 CDE directory; predecessor = older snapshot. geodist/collapse deterministic → all diffs are input-vintage drift.
- Classification: NOT a code regression. Explains mindist_* (50,766 rows in score_b), distance-restricted sample N shifts, restricted-variant va_* value diffs, and (with ADR-0026 possibly contributing to sib1) the 46 ster FAILs.
- DECISION PENDING (Christina): Option A pin input to cached pubschls.txt (reproducible, needs ADR + code change) vs Option B accept drift (document via ADR, code stays identical). See triage review §ROOT CAUSE.

## Addendum 6 — Option A implemented: pinned CDE directory input (2026-06-12)

- ADR-0030 written + indexed. Implemented the reproducibility pin:
  - `do/settings.do`: new toggle `global refresh_cde_directory 0` (BEHAVIOR/CONFIG TOGGLES block, mirrors run_prior_score). Default 0 = pinned/reproducible.
  - `do/data_prep/k12_postsec_distance/k12_postsec_distances.do`: K12 directory load gated `if "$refresh_cde_directory"=="1"` (live URL + disk fallback, predecessor-original) `else` reads cached pubschls.txt directly (default). Header INPUTS updated.
- coder-critic PASS 96/100 (no Critical/Major; Minor = ledger row, added). Review: 2026-06-12_cde-directory-pin_coder_review.md. Ledger rows added (settings.do refresh-cde-toggle-default-off; producer cde-directory-pin).
- CONSEQUENCE (per ADR-0030): currently-committed canonical distance outputs were built from June-2026 live directory; after the pin they no longer match the code. Must REGENERATE on the next clean Phase 5-7 re-run → code+input+output internally consistent. Until then, knowingly inconsistent for the distance family. Subsequent golden master still won't byte-match predecessor on distance (predecessor vintage unrecoverable) — pin fixes FORWARD reproducibility.
- FOLLOW-UP (replication deposit, not blocking): vendor pubschls.txt into the package (cf ADR-0023).
- NEXT: clean Phase 5-7 re-run on Scribe (propagates clamp ADR-0027 + this pin; regenerates distance outputs; completes all 6 Phase-7 checks); revert tier_filter→smoke (m4_golden_master.do:394) after acceptance.

## Addendum 7 — offboarding: stata-mp standardization + PI handoff doc (2026-06-12 → 06-13)

- **stata-mp standardization (committed, unpushed on held stack).** Per Christina: `stata-mp` is the canonical server command; never `stata -b`. Fixed all forward-facing run-command references (README ×4, CLAUDE.md, TODO, do-file headers: main/m4_golden_master/m4_spotcheck/codebook_export) and codified it in `.claude/rules/stata-code-conventions.md` (new "Invocation (server)" block). Immutable ADRs + dated historical records left as-is. do-file edits comment-only.
- **HANDOFF.md drafted** (new root-level PI onboarding doc, for Paco). Scope set via AskUserQuestion: run/reproduce focus, minimal Claude-Code mention, dedicated doc. Covers: what the repo is; what we did (the mess, the implicit-dependency problem, how we resolved it); how-we-know-it's-correct QC (golden master 8,324-file repro, 6 Phase-7 checks, human review — Christina reviewed every change, 135 review-gated commits / 50+ reports / 30 ADRs); two-places mental model; run instructions; partial re-runs; sync (FileZilla OR git, Paco's choice); folder map; the paper (separate repo); troubleshooting.
- **QC passes:** humanize (13 comma-em-dashes recast + signposting/arrows removed; facts preserved) + writer-critic **93/100** (no High; applied M1 name triage report inline, M2 distinguish byte-identical vs estimate-match, L2 git-novice pull caveat). Review: `quality_reports/reviews/2026-06-13_handoff_writer_review.md`.
- **Christina edit rounds:** (a) human-reviewer framing — she was the reviewer; (b) named attribution — Christina wrote VA+CalSCHLS, distance code is Paco's own (header "created by Paco Martorell"), crosswalks/merge/geocoding are Matt Naven's (ADR-0017); (c) Matt+Paco are coauthors (dropped "another lab member"); de-jargoned "M4" (variable-prefix note); (d) reframed data-exclusion as a mandatory lab data-security/confidentiality requirement enforced by guardrails, NOT a personal choice — kept distinct from the optional sync-method choice.
- **State:** HANDOFF.md polished, UNCOMMITTED pending Christina's go-ahead. origin/main = 8660451 (incl. 255c9f8/84266cb/ADR-0030). Unpushed local stack above it, awaiting both Scribe runs: ac749c5 (tier→smoke) → 8f16495 (state docs) → 0ff40a2 (stata-mp). NEXT: commit HANDOFF.md + writer review when approved; push whole stack after Scribe runs complete.
