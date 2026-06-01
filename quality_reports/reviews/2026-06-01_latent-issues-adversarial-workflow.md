# Latent-Issue Adversarial Workflow — Outcome (APPLY NOW: empty)

**Date:** 2026-06-01
**Workflow:** wf_5ea1ac93-c94 (15 agents: 7 sites × investigate→refute + synthesize)
**Status:** Active
**Verdict:** All 7 candidate fixes DEFERRED. 5 refuted/amended as regressions, 2 confirmed-but-NO-CHANGE (orphan/dead). Root cause traced to a main.do orchestration gap, NOT the read lines.

## Independently verified root cause
`run_samples = 0` (main.do:99); `m4_acceptance_run=1` forces `do_create_samples=1` ONLY inside the `if run_samples {` block (main.do:261-263), which never executes. So Phase 2 (create_score_samples) never builds the canonical $datadir_clean samples. Every proposed LEGACY→CANONICAL repoint would therefore swap an r(601) on the legacy path for an r(601) on the (never-produced) canonical path — a regression. NOTE: this toggle state is also the user'''s current deliberate dev-iteration config (Phase 6/7 only); the legacy reads currently WORK because legacy cached files exist on Scribe. The issue is latent for a true fresh acceptance run.

## Per-site verdicts
- **base_sum_stats_tab:403** → REFUTED: NO CHANGE to line 403. The issue is NOT in base_sum_stats_tab.do:403 (the read statement) but in do/main.do:128-131 (the orchestration). Fix main.do by forcing run_samples=1 when m4_acceptance_run=1, OR defer sample relocation to a later phase per ADR-0021 §Step 10 scope decision (line 52 header already documents it as "out of Step 10 scope"). Repointing without fixing Phase 2 orchestration would create a new r(601) failure at the canonical path instead of the legacy path—not a fix, a regression.
- **sample_counts_tab_legacy_base_nodrop_read** → REFUTED: NO CHANGE. The proposed execution-order swap (Option A) does not fix the underlying bug. A proper fix requires one of: (1) Repoint sample_counts_tab.do:108 to `$datadir_clean/share/base_nodrop.dta` AND add a fail-soft cache-guard (cap confirm file...; if _rc { ... recreate or error cleanly }), OR (2) Repoint + explicit documented ordering requirement that base_sum_stats_tab.do must run before sample_counts_tab.do (enforce via main.do phase structure and a comment tie-in), OR (3) Clarify scope: if the LEGACY read is intentional-by-design (golden-master fidelity), vendor the legacy base_nodrop.dta file into data/raw/upstream/ and repoint to that canonical proxy. Reordering without repointing is a silent failure trap — it appears to fix the problem on first read but sample_counts_tab will fail r(601) on any fresh sandbox run because the legacy input file is not carried forward and is not created by any pipeline script.
- **sample_counts_tab_legacy_read_133** → AMENDED: AMENDED FIX REQUIRED: Apply the repointing PLUS update the header at line 40 from "kept LEGACY (sample data; out of Step 10 scope)" to "relocated to CANONICAL (Phase 2 batch 2b produces at $datadir_clean path; Phase 6 consumer repointed correspondingly; requires Phase 2 to run before Phase 6)". Then ensure do/main.do Phase 6 (or sample_counts_tab.do itself) asserts Phase 2 ran, or document that r(601) file-not-found is the correct failure mode when do_create_samples=0 and m4_acceptance_run=0.
- **check_merge:67** → REFUTED: NO CHANGE
- **codebook_export:92** → REFUTED: NO CHANGE to codebook_export.do line 92. (File is correctly marked diagnostic/not-pipeline-active per ADR-0021 header lines 30–37; zero invocations from main.do confirmed.) However, escalate check_merge.do (do/data_prep/k12_postsec_distance/check_merge.do:67) as a NEW latent issue: it reads LEGACY $vaprojdir/data/va_samples_v1/score_b.dta before the canonical version is produced, creating golden-master parity risk. Recommend: (a) add explicit NOTE in check_merge.do explaining LEGACY-read-is-intentional rationale (diagnostic-only, not pipeline output), OR (b) gate check_merge.do on a separate toggle (e.g., `local do_check_merge = 0`) so it only runs in dev, not acceptance runs, OR (c) defer to Phase 2 after create_score_samples.do completes (requires reordering logic to postpone diagnostic until canonical file exists).
- **prior_decile_original_sample.do:175** → CONFIRMED: NO CHANGE
- **acs_2017_gen_dict_L66** → CONFIRMED: NO CHANGE

## Full synthesis

All facts verified. Key findings confirmed:

- `score_las.dta` and `score_b.dta` are produced canonically by `create_score_samples.do` (Phase 2, only runs under `do_create_samples`/`run_samples`), at lines 373 and 221.
- `base_sum_stats_tab.do:273` saves `base_nodrop.dta` to `$datadir_clean/share/` (NOT the legacy `va_samples_v1/` path the consumer at `sample_counts_tab.do:108` reads).
- `run_samples` is never forced to 1; `m4_acceptance_run` only flips sub-toggles *inside* the `if run_samples` block — so Phase 2 is dead under the current config. This confirms the base_sum_stats_tab and check_merge refutations.

This means every proposed "repoint to canonical" fix would read a file that Phase 2 never produces under the current toggles — a regression, not a fix. The consolidated report follows.

---

# Latent-Issue Fix Consolidation — Adversarial Review Outcome

**Repo:** `/Users/christinasun/github_repos/va_consolidated` · **Date:** 2026-06-01
**Verified against:** `do/main.do`, `do/share/{base_sum_stats_tab,sample_counts_tab}.do`, `do/data_prep/k12_postsec_distance/check_merge.do`, `do/samples/create_score_samples.do`

## 1. Site-by-site outcome

| Site | Verdict | Final action |
|---|---|---|
| `base_sum_stats_tab:403` | refuted | **NO CHANGE** to line 403. BACKLOG: orchestration bug in `main.do` — `run_samples` never forced under `m4_acceptance_run` (Phase 2 dead). |
| `sample_counts_tab_legacy_base_nodrop_read` (`:108`) | refuted | **NO CHANGE**. Reorder is a no-op; canonical `base_nodrop.dta` lives at `$datadir_clean/share/`, not the legacy path read. BACKLOG (ADR). |
| `sample_counts_tab_legacy_read_133` (`:133`) | amended | **DEFER → ADR**. Repoint + header rewrite changes a documented LEGACY decision; needs ADR + Phase-2-before-Phase-6 guarantee. |
| `check_merge:67` | refuted | **NO CHANGE**. Repoint creates new r(601) (Phase 1 runs before Phase 2 producer). BACKLOG. |
| `codebook_export:92` | refuted | **NO CHANGE** (orphan, 0 invocations from `main.do`). BACKLOG: escalate `check_merge.do:67` golden-master parity risk (already captured above). |
| `prior_decile_original_sample.do:175` | confirmed | **NO CHANGE** (dead code in `/* */` block, ADR-0021-documented). |
| `acs_2017_gen_dict_L66` | confirmed | **NO CHANGE** (file unreachable; `run_data_prep=0`. Separate `main.do` toggle concern, not a file bug). |

## 2. APPLY NOW

**Empty.** No site has a corrected_fix that is both concrete and safe.

Every proposed "repoint LEGACY → CANONICAL" edit (sites 403, 108, 133, 67) was refuted or amended for the same verified reason: the canonical target file (`score_las.dta`, `score_b.dta`, `base_nodrop.dta` at the legacy `va_samples_v1/` location) is **not produced before the consumer runs** under the current `main.do` toggles. `create_score_samples.do` (the canonical producer, lines 221/373) sits inside the `if run_samples` block, and `run_samples` is hard-`0` at line 99 with no `m4_acceptance_run` override at the phase-toggle level. Applying any repoint would swap an r(601) on the legacy path for an r(601) on the canonical path. Per the conservative rule, all defer.

## 3. DEFER (TODO backlog)

| Item | Type | One-line rationale |
|---|---|---|
| `main.do` — force `run_samples=1` when `m4_acceptance_run=1` | **BACKLOG (bug)** | Root cause of `base_sum_stats_tab:403` r(601): `m4_acceptance_run` flips only sub-toggles *inside* `if run_samples` (line 232), but `run_samples` itself stays 0 (line 99) — Phase 2 never executes, so no canonical samples are built. Violates ADR-0018 "every toggle ON" for acceptance runs. Fix in `main.do`, then site-403/108/67 repoints become safe. |
| `sample_counts_tab.do:108` repoint + cache-guard | **BACKLOG** (blocked on above) | Consumer reads legacy `va_samples_v1/base_nodrop.dta`; canonical producer (`base_sum_stats_tab:273`) writes to `$datadir_clean/share/base_nodrop.dta` — different path. Needs repoint to share/ path + `cap confirm file` guard + documented ordering (base_sum_stats before sample_counts). Reorder alone is a no-op. |
| `sample_counts_tab.do:133` repoint | **ADR required** | Changing the line-40 "kept LEGACY (out of Step 10 scope)" marker is reversing a documented ADR-0021 decision; requires ADR + header rewrite + Phase-2-before-Phase-6 enforcement (or documenting r(601) as correct failure when `do_create_samples=0`). |
| `check_merge.do:67` LEGACY read | **BACKLOG** (golden-master) | Diagnostic runs Phase 1 (line 171) before canonical `score_b.dta` is produced in Phase 2 (`create_score_samples.do:221`); reads a stale legacy copy that may diverge (ADR-0018 parity risk). Options: gate behind a dev-only toggle, add intentional-LEGACY NOTE, or reorder after Phase 2. Repoint is unsafe (r(601)). |
| `codebook_export.do:92` | **BENIGN/orphan** | Zero `main.do` invocations; diagnostic-only per ADR-0021 header. No consolidated output effect. |
| `prior_decile_original_sample.do:175` | **BENIGN/dead** | Inside a never-executed `/* */` block; ADR-0021 documents repointing as deferred Phase-1b work. |
| `acs_2017_gen_dict.do:L66` | **BENIGN (unreachable)** | `run_data_prep=0` (line 98); file never runs. File body is sound (canonical outputs, documented LEGACY input). The unreachability is the `main.do` orchestration concern, not a file edit. |

## 4. Golden-master note

No apply-now fix exists, so **nothing requires a Scribe parity re-run yet**.

When the deferred `main.do` orchestration fix lands (forcing `run_samples=1` on acceptance runs), it is **not** path-equivalent — it activates Phase 2, which **changes which data the whole downstream chain reads** (canonical regenerated samples instead of cached/legacy). That fix, and any subsequent `:108`/`:67`/`:133` repoints it unblocks, **must be confirmed against the next full Scribe M4 golden-master run** (`output/m4_diff_summary.txt`) for output parity before `v1.0-final`. The `check_merge.do:67` stale-read divergence is itself a parity risk that only a full Phase-1-then-Phase-2 Scribe run can detect.
