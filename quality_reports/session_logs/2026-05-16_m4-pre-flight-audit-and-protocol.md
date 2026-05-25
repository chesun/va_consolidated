# Session Log — 2026-05-16 M4 Pre-Flight Audit + Protocol Prep

## Headline

Pre-flight Tier-2 audit of all 110 active .do files before Phase 1a §3.5 M4 golden-master run on Scribe. **Sandbox-write discipline (ADR-0021) confirmed pipeline-wide** (0 LEGACY writes in active code). **3 Critical chain regressions found and fixed.** Then drafted M4 infrastructure: path matrix CSV (8,324 rows) + Stata diff runner (663 LOC). Both committed; user input pending on whether to extend air-gap fix to 3 additional analogous leaks before round-2 critic re-verify.

## Per-step rollup (chronological)

### Pre-flight audit (4 parallel coder-critic dispatches)

Christina's call: before running M4 on Scribe, validate the consolidation holistically — per-batch coder-critics across Steps 1-11 each saw their batch in isolation but never the union. Single holistic Tier-2 pass with full-tree visibility = the missing layer.

Partitioned into 4:

| Partition | Scope | Files | Round 1 | Round 2 | Verdict |
|---|---|---:|---:|---:|---|
| A | main.do + settings.do + wiring | 2 | 92/100 PASS | — | ✅ |
| B | va/ + samples/ + sibling_xwalk/ + check/ | 36 | 73/100 BLOCK | 88/100 PASS | ✅ |
| C | data_prep/ | 40 | 91/100 PASS | — | ✅ |
| D | share/ + survey_va/ + explore/ | 32 | 78/100 BLOCK | 93/100 PASS | ✅ |

**3 Critical chain regressions** (same class as Step 11 BONUS catches — producer relocated to CANONICAL post-Step-9/10/11 but consumers still read LEGACY):

1. **`analysisready.dta`** chain regression across `do/survey_va/factor.do` (3 reads), `do/survey_va/pcascore.do` (3 reads), `do/share/svyvaregs/allvaregs.do` (1 templated read). Step 11 fixed 4 sister files but missed these 3. `allvaregs.do` is paper-shipping (Table 8 inputs per main.do:407).
2. **`sibling_out_xwalk`** bind in `do/va/helpers/macros_va.doh:110` still LEGACY despite producer at `do/sibling_xwalk/siblingoutxwalk.do:338` writing CANONICAL. Propagated to active consumers `merge_sib.doh:66` and `sample_counts_tab.do:118`.
3. **`score_b.dta`** wrong parent in 3 check files (`check_samples.do:71`, `check_merges.do:66`, `check_paper_outputs.do:67`). Silently skipped via `capture confirm file` shim → false-confidence PASS on acceptance check.

All 12 line-edits applied by coder agents (2 dispatches; one per BLOCK partition), verified by round-2 coder-critic. Committed as:

```
6607445 phase-1a(pre-flight M4): close 3 Critical chain regressions before golden-master
6d5981d docs: 2026-05-16 pre-flight M4 audit -- 4-partition coder-critic + 2 round-2 PASS
```

8 deferred Major/Minor items (clean_charter Mac branch, t1_empirical_tests orphan, check_survey_indices wrong parent, gated-0 doh-includes, CONVENTIONS sections, etc.) added to TODO Backlog under Phase 1c §5.4 with back-references to round-1 review files. **`check_chain.do` queued for Phase 1c §5.3** — programmatic scan for producer-CANONICAL/consumer-LEGACY pairs to prevent future regressions of this class.

### M4 protocol prep (path matrix + diff runner)

Christina asked for a guide for running the test on Scribe. Discovery: no consolidated guide exists; pieces scattered across plan v3 §3.5, ADR-0018, replication-protocol.md §3. Two upstream constraints she clarified:

1. **Predecessor outputs are not centralized on Scribe** — they live wherever the predecessor `cde_va_project_fork/do_files/do_all.do` + `caschls/do/master.do` pipelines write them. We never enumerated these in a project doc because the consolidation didn't need to. But every consolidated .do file's RELOCATION header documents its predecessor path — so the predecessor↔consolidated path matrix is derivable mechanically.
2. **Air-gapped diff requirement** — Christina cannot export data from Scribe; only the diff summary can be exported. So the diff runner has to execute on Scribe (Stata) and produce a small text-file summary as the export artifact.

Pre-pinned CSV schema: `predecessor_abs_path,consolidated_abs_path,producer_file,filetype,tier,category`. Three tiers: `smoke` (~5; <5 min); `paper` (~30-50); `full` (rest). Recommendation accepted: smoke first to catch catastrophic breakage in minutes, then full union confirms behavior preservation.

**Two agents dispatched in parallel** (data-engineer + coder), schema pre-pinned as the bridge contract:

| Agent | Deliverable | Result |
|---|---|---|
| data-engineer | `do/check/m4_path_matrix.csv` + `m4_path_matrix_README.md` | 8,324 rows (smoke=5, paper=454, full=7,865). Much larger than my ~50 rough estimate — the VA estimation pipeline produces thousands of `.ster` files via `control × sample × peer × outcome × version` cross-product enumerated in `do/va/helpers/macros_va_all_samples_controls.doh:73-196`. README §"Row counts" documents the deviation transparently. 12 known-limitation items flagged (year-loop bounds, distance-controls VA may be gated OFF in predecessor, etc.). |
| coder | `do/check/m4_golden_master.do` | 663 LOC. Tier-selector at line 380 (`local tier_filter = "smoke" // CHANGE ME`). Dispatch per filetype: `.dta` via Stata `cf` (+ optional `cfout` fallback); `.ster` via `estimates use` + `e(b)` element-wise compare; `.tex` via shell `diff` + numeric-strip; `.pdf` via byte-compare → `pdftotext` text-diff fallback; `.png`/other byte-compare. All file ops wrapped in `capture` per defensive-code pattern. Sandbox-write clean (only `$logdir/m4_golden_master.{smcl,log}` + `$output_dir/m4_diff_summary.txt`). Optional packages probed via `command -v` with graceful fallback. |

### Coder-critic round 1 on M4 deliverables

Score: **82/100 PASS at gate.** 5 Major + 3 Minor findings, 0 Critical.

Must-fix-before-running (1 item): **M3** — `.ster` FAIL branch writes `max|db|` and `max|dSE|` numeric magnitudes into the exported summary. Per `air-gapped-workflow.md`, anything derived from restricted data is restricted; these numeric deltas should stay in the `.log` file (on Scribe) and the summary should carry only status strings.

Can-fix-after-smoke (4 items): M1 (.ster colname-alignment check), M2 (cf row-count mismatch reclassify), M5 (PDF date/timestamp tolerance), Mi1 (smoke csv/xlsx coverage).

### Coder round-2 M3 fix

Surgical 2-line edit applied: `.ster` FAIL details now use status strings ("coef exceeds 0.01 tolerance" / "SE exceeds 0.05 tolerance"); magnitudes kept in `display` calls so they land in the `.smcl`/`.log` file but not the export summary. 5 deferred items (M1, M2, M5, Mi1, Mi2) added to TODO Backlog with back-references.

**Coder surfaced 3 analogous leaks** the critic did not flag — `.dta` row-counts (line 156), `.dta` cell-diffs (lines 162, 167), `.tex` structural-diff line counts (line 293). Same epistemic class as M3 (counts derived from restricted data). Critic's own M2 finding treated row counts as acceptable detail strings — internally inconsistent. **Decision pending from Christina**: fix all 3 in this same round (extend M3 scope) before round-2 critic re-verify, OR ship M3-only fix and queue the 3 analogous leaks for post-smoke.

## Today's commits

```
6607445 phase-1a(pre-flight M4): close 3 Critical chain regressions before golden-master
6d5981d docs: 2026-05-16 pre-flight M4 audit -- 4-partition coder-critic + 2 round-2 PASS
```

(M4 infrastructure deliverables — path matrix + diff runner + round-1 critic review + round-2 fix — staged but not yet committed; awaiting Christina's air-gap-scope decision.)

## Process learnings

1. **Per-batch coder-critics miss cross-batch chain regressions by design** — each saw their batch in isolation; the union was only visible to the holistic pre-flight pass. Step 11 cross-step coordination found 2 BONUS catches; today's pre-flight found 3 more of the same class. Pattern: producer relocated to CANONICAL in Step N's batch, consumer in Step M's batch never re-grepped after Step M completed. **`check_chain.do` (queued for Phase 1c §5.3) is the right systematic prevention** — programmatic post-relocation invariant rather than audit-time grep.
2. **Pre-flight before expensive runs has high ROI** — Christina's instinct to validate before burning hours on Scribe paid off. 3 Critical findings would have produced silent stale-data consumption on M4; Stata wouldn't have errored; `diff -r` would have falsely reported pass on stale rows. The 4-partition parallel dispatch took ~30 min wall-clock; the M4 run is multi-hour.
3. **Path matrix construction from RELOCATION headers is the audit trail's hidden value** — we didn't centralize predecessor outputs into a single root because the consolidation didn't need to, but the per-file RELOCATION blocks already encode the full predecessor↔consolidated mapping. The data-engineer's CSV is just an aggregation of work that was already in the headers.
4. **Schema-as-contract works for parallel agent dispatch** — pre-pinning the CSV schema in both prompts (data-engineer + coder) let them work in parallel without coordination. Coder wrote against the schema spec, data-engineer produced the schema-conformant output, both converged at the same artifact boundary.

## Next session pickup

**Pending Christina's decision on air-gap-scope extension** (round-2 M3 fix → fix-all-leaks vs ship-as-is + queue-others):

1. If extend: dispatch coder for 3 additional `display`-to-log conversions (~5 min); then round-2 critic re-verify M3 + 3 analogous leaks.
2. If ship-as-is: dispatch round-2 critic to verify M3 fix only.
3. Either way: after critic PASS, write `quality_reports/plans/2026-05-16_m4-golden-master-protocol.md` — the operator-facing guide that wraps the path matrix + diff runner with step-by-step Scribe instructions (smoke → paper → full sequence; what to export; how to interpret).
4. Commit M4 infrastructure (path matrix + diff runner + round-1/round-2 reviews + protocol doc) in two commits (code + docs).
5. Christina runs smoke on Scribe (~5 min). Reviews summary. Proceeds to paper or full per the protocol doc.

## Status

- **Phase 1a §3.3:** COMPLETE per 2026-05-08 END-OF-SESSION log (148 files; 27 coder-critic PASS verdicts).
- **Phase 1a §3.5 (M4):** infrastructure prep IN PROGRESS. Pre-flight cleared (3 Criticals fixed; pushed). Path matrix + diff runner staged untracked; awaiting air-gap-scope decision + protocol doc.
- **Tree:** dirty (M4 infrastructure unstaged); HEAD at `6d5981d` in sync with origin.
- **ADR ledger:** 21 Decided. No new ADRs this session.
- **Coder-critic audit trail (today):** 5 dispatches — 4 pre-flight (A 92/B 73→88/C 91/D 78→93) + 1 M4 infra (82/100). 1 escalation strike on B, 1 on D, 0 on A/C/M4. All resolved at round 2.

---

# Continuation — 2026-05-17

## Headline (continued)

Christina ran smoke on Scribe (correctly identified 5 MISSING_CONSOLIDATED — expected since main.do hadn't been run). Surfaced 4 additional Christina-caught bugs in main.do + m4_golden_master.do that the per-batch coder-critics had missed because main.do was never end-to-end-tested during Phase 1a §3.3. All 4 fixed; 3 additional deferred Major latent issues fixed in scope reopen. Repo now M4-ready pending Christina launching the acceptance run with `m4_acceptance_run = 1`.

## Per-step rollup (2026-05-17)

### Air-gap rule clarification + M3 revert

Christina clarified: the air-gap rule applies to raw row-level restricted data only, NOT to derived summaries (coefficient deltas, counts, p-values, summary stats — all paper-class content). Round-1 critic's M3 deduction was misapplied. Dispatched two coders in parallel: (a) revert M3 in `m4_golden_master.do` (restore `max|db|` / `max|dSE|` magnitudes to FAIL details + augment PASS details for triage symmetry); (b) tighten `.claude/rules/air-gapped-workflow.md` with explicit "What IS OK to Export" / "What IS Air-Gapped" sections + one-line bright-line test "Counts, magnitudes, and estimates are derived." Round-2 coder-critic PASS 85/100 (was 82 with M3 misapplied). Committed `07b8f80`.

### Smoke run on Scribe + matrix-path verification

Christina ran smoke (~1 sec, 0% CPU); all 5 rows MISSING_CONSOLIDATED. **First Christina catch**: I conflated runner-smoke (verifies the script works) with behavior-smoke (verifies the consolidated pipeline produces equivalent outputs). The latter requires main.do to be run first to produce consolidated outputs. My fault — protocol doc didn't explicitly state this prerequisite.

**Second Christina catch**: in walking through path verification, I reconstructed a predecessor path from memory (`/home/.../caschls/dta/buildanalysisdata/poolingdata/sec/sec1718.dta`) and asked her to verify. She corrected: that directory structure doesn't exist; `poolingdata/` directly contains only 3 .dta files. Violation of `derive-dont-guess.md` — I should have grep'd `m4_path_matrix.csv` directly for the exact stored path. Apologized; pasted the 5 smoke predecessor paths verbatim from CSV; she confirmed all 5 exist.

### M4_ACCEPTANCE_RUN flag (commit `c2d208c`)

Investigated `do/main.do` properly — phase-level toggles default 1 but THREE sub-toggles inside Phase 2/3 default 0 (`do_touse_va`, `do_create_samples`, `do_va`) per the run-once-cached pattern from predecessor `do_all.do`. ADR-0018 acceptance criterion requires "all toggles ON" but flipping three separate sub-toggles is error-prone. Dispatched coder to add a top-level master flag `local m4_acceptance_run = 0` that overrides all three to 1 when set to 1. Default 0 preserves cached-iteration dev pattern. Display line logs ENABLED/DISABLED state to master log.

Coder-critic round 1: PASS 94/100. 3 Minor discretionary (status-line tense, override-block locality, defensive run_data_checks assert) deferred non-blocking.

**Third Christina catch — bundled in same commit**: `m4_golden_master.do` shipped (commit `567b01d`) WITHOUT `include do/settings.do`. `cap mkdir "$logdir"` and `log using "$logdir/..."` would have run with empty globals on Scribe. Christina added the include manually on Scribe; `git blame` confirmed lines 104-106 were uncommitted working-tree changes — the commit itself shipped buggy. Bundled fix into `c2d208c`.

### Two more main.do bugs (commit `55b0c13`)

**Fourth Christina catch**: Phase 7 (`do/main.do:455-474`, DATA CHECKS) had all 6 `do do/check/*.do` calls commented out as `*` prefix from the original Phase 1c §5.3 TODO. With `run_data_checks=1` default, the phase printed its header and did nothing. ADR-0018 requires checks to fire on the acceptance run. All 6 check files exist on disk.

**Fifth Christina catch — bigger bug**: 4 `*`-prefixed comment lines in `do/main.do` contain `/*` inside path-glob text (lines 182, 387, 388, 389). Stata's parser treats `/*` as block-comment start regardless of leading `*` context. Impact:
- Line 182's `/*` matched `*/` at line 209 → swallowed 9 data-prep do-calls (batches 9g + 9f) AND Phase 1's closing `}` at line 204
- Line 387's `/*` matched `*/` at line 408 → swallowed all 11 Phase 5 do-calls AND Phase 5's closing `}` at line 405

Net: 2 unmatched `{` braces → Stata `do` errors mid-run or skips eaten phases entirely. The bug had been latent in main.do since drafting (2026-04-28); never surfaced because main.do was never end-to-end-run-tested during Phase 1a §3.3.

Dispatched coder to fix both: uncomment Phase 7 (6 lines) + replace `/*` with `/<x>` in 4 sites (6 substitutions; matches existing `<sub>/<year>` placeholder convention). Coder-critic round 1 PASS 94/100. Brace balance restored 43/43.

### 3 M4-blocking latent issues fixed (commit `5782189`)

Christina reopened scope: "dispatch coder to fix the latent issues". I scoped to 3 M4-blocking deferred Majors from Partition B pre-flight (deferred 2026-05-16 as post-smoke or Phase 1c §5.4; promoted to fix-now since they'd silently degrade M4 quality):

1. **Mj-1**: `check_survey_indices.do:197` reader path `$estimates_dir/calschls/categoryindex/` → `$datadir_clean/survey_va/categoryindex/`. Was silent-skipping via `capture confirm file` shim. Header INPUTS + ROLE IN SANDBOX blocks also updated for internal consistency.

2. **Mj-2**: `t1_empirical_tests.do` archived to `do/_archive/check/` via `git mv` (history preserved). New `do/_archive/check/README.md` mirrors existing `_archive/exploratory/` + `_archive/siblingvaregs/` conventions. Resolves orphan-breaks-check_logs-invariant AND orthogonal Minor about its log routing (since archived files are excluded from `check_logs.do:76`'s filelist enumeration).

3. **Mj-3**: 12 relative `include do/samples/X.doh` lines across 6 `create_va_g11_*.doh` files → absolute via `$consolidated_dir/do/samples/X.doh`. RELOCATION HISTORY blocks carry dated 2026-05-17 amendment per audit-trail precedent.

Coder-critic round 1 PASS 96/100. 2 trivial Minor advisories (m4_path_matrix_README informational mention; archive README style symmetry preference). TODO Backlog lines 86, 87, 88, 92 marked `[x] RESOLVED 2026-05-17`.

### Scope deferred (still in Backlog)

- **6 cosmetic/Phase 1c §5.4 items** (TODO Backlog lines 89-91, 93-95): dead-code hardcoded paths in dormant gates, missing ledger rows, CONVENTIONS-section sweep, process-rule codification. Zero runtime impact on M4.
- **5 post-smoke M4-runner improvement items** (lines 96-100): `.ster` colname check, `cf` row-count reclassify, PDF timestamp tolerance, csv/xlsx smoke coverage, MISSING_BOTH status. Need actual smoke output to surface them; fixing speculatively would be premature.

## Today's commits (2026-05-17)

```
07b8f80 docs: 2026-05-17 M4 protocol doc + air-gap rule tightened + reviews + session log
c2d208c phase-1a(§3.5): M4_ACCEPTANCE_RUN flag + fix missing settings include
55b0c13 phase-1a(§3.5): fix two main.do bugs before M4 acceptance run
5782189 phase-1a(§3.5): fix 3 M4-blocking latent issues from Partition B pre-flight
```

(Plus 2026-05-16 commits already logged in original section above: `6607445`, `6d5981d`, `567b01d`.)

## Process learnings (cumulative)

5. **main.do was never end-to-end-tested before today**. All 5 Christina catches (settings include in M4 runner, M4_ACCEPTANCE_RUN sub-toggle bug, Phase 7 commented-out checks, `/*` block-comment bug, path-reconstruction fabrication) were latent for weeks because the per-batch Phase 1a §3.3 coder-critics each saw their batch in isolation and never the union of main.do's wiring. **The pre-flight Tier-2 audit caught chain regressions but didn't run main.do** — that's a gap. Future Phase 1a-equivalent consolidations should include an end-to-end syntax-check of the orchestration file before declaring §3.3 complete.

6. **Stata parser ambiguity: `/*` inside `*`-prefixed lines is a block-comment-start**. Documented in `.claude/rules/anti-ai-prose.md`? No — this is a Stata-specific gotcha, deserves a `[LEARN:stata]` entry. The pattern `<path>/*` in path-glob comments is common and silently dangerous. Mitigation: use `<x>` placeholder convention.

7. **Air-gap rule must explicitly enumerate exportable content** to prevent over-correction. Originally `air-gapped-workflow.md` had a one-line aside "Claude CAN work with: summary stats". Both a coder-critic and the orchestrator misread that as covering only categorical metadata, not derived numbers like coefficient deltas. Tightened rule with explicit "What IS OK to Export" / "What IS Air-Gapped" sections + bright-line test "Counts, magnitudes, and estimates are derived."

8. **Derive-don't-guess violation on path reconstruction**. When verifying a predecessor path with Christina, I should have grep'd `m4_path_matrix.csv` first to get the exact stored path, not reconstructed from memory. Christina explicitly reprimanded ("how many times do I need to tell you — no guessing!!!"). Rule reinforced.

## Next session pickup (updated)

1. **Christina syncs latest commits to Scribe** (FileZilla/scp/git pull). Most recent: `5782189`. Files to sync: `do/main.do`, `do/check/check_survey_indices.do`, `do/check/t1_empirical_tests.do` (deletion), `do/_archive/check/` (new dir + README + relocated file), `do/samples/create_va_g11_*.doh` (6 files).
2. **Christina sets `m4_acceptance_run = 1`** at `do/main.do:115`.
3. **Christina launches acceptance run on Scribe**: `nohup stata-mp -b do do/main.do &` (confirmed appropriate vs screen; difference is just whether you want reattach capability).
4. **Monitor**: `tail -f log/main_*.smcl` for orchestration-level progress.
5. **Runtime estimate**: multi-hour (~1-2 days based on VA estimation overhead — 5,236 .ster files via CFR shrinkage).
6. **When run completes** (or hits a runtime error): pull `log/` + `output/` back to local. Triage from the master log + (if run completed) the data-check assertions in Phase 7. Then re-run M4 smoke (`tier_filter = "smoke"`) to verify the 5 representative pairs match. If smoke PASS → paper tier (~30-60 min). If paper PASS → full tier (multi-hour again).
7. **Post-smoke iteration**: address the 5 deferred M4-runner items (TODO Backlog lines 96-100) once we see actual smoke output indicating which manifest. Defer all 6 cosmetic items (lines 89-95) to Phase 1c §5.4 polish per the original orchestrator scope decision.

## Status (mid-2026-05-17)

- **Phase 1a §3.5 (M4):** infrastructure complete and pushed. All 5 Christina-caught bugs fixed. 3 M4-blocking latent issues closed. **Awaiting Scribe acceptance run.**
- **Tree:** clean (`log/`, `output/`, `master_supporting_docs/codebooks/` untracked but pre-existing or generated; not for commit).
- **HEAD:** `5782189` in sync with origin.
- **ADR ledger:** 21 Decided. No new ADRs this session.
- **Coder-critic audit trail (2026-05-17):** 5 dispatches — M4 round 2 PASS 85/100; main.do M4-flag PASS 94/100; main.do bugfix bundle PASS 94/100; M4-blocking-fixes PASS 96/100. 0 BLOCK verdicts; 0 escalation strikes.
- **TODO Backlog:** 14 items at session start; 4 marked `[x] RESOLVED` (lines 86, 87, 88, 92); 10 remain (6 cosmetic Phase 1c §5.4; 5 post-smoke M4 runner — one item span both via line numbering).

---

# Continuation — 2026-05-17 (late afternoon / evening)

## Headline

Christina launched the M4 acceptance run, immediately discovered the M4 flag was 0 (had been synced as default), reset, and on the next attempt hit a different failure: `secqoiclean1415.do` errored with `sort cdscode: r(111) "no variables defined"`. She caught the root cause: **`/*` parser bug**. Stata's parser counts `/*` opens greedily regardless of context, so path-glob `*` in `<path>/*` patterns inside `/* ... */` header description blocks create runaway block comments. 89 of 129 active files affected. Comprehensive dual-sweep fix landed (commit `eededa0`), followed by T2 idempotence + portable field guide (commit `b261918`). m4_acceptance_run toggled to 1 locally for the next Scribe attempt.

## Per-step rollup (2026-05-17 evening)

### M4 acceptance run attempt #1 — failed at secqoiclean1415

Christina ran `stata-mp -b do do/main.do` on Scribe. Master log at `log/main_17-May-2026_17-23-02.smcl` showed:
- Phase 1 entered; nested .do files source-echoed through `end of do-file` markers
- ZERO "file saved" messages across 6,588 lines
- Halted at `secqoiclean1415.do` line 85: `sort cdscode` with `r(111) "no variables defined"`
- Cascading r(111) propagated through remaining Phase 1 scripts and ended main.do after Phase 1's closing `}`

Christina pointed out: `sec1415.dta` doesn't exist on Scribe, AND no per-file logs were produced in `log/`. Diagnostic implications: **nested .do file commands weren't actually executed** despite source-echo through to "end of do-file". Master log showed M4 flag was at default 0 (Christina forgot to flip; sync carried the default).

Then Christina opened `renamedata.do` in the IDE and saw the body rendered as commented out. Diagnosis: same `/*` parser bug as main.do line 182 from the pre-flight session, but now widespread.

### Quantified the scope

`grep -c '/\*'` vs `grep -c '\*/'` per file across active tree: **89 of 129 files (69%) had unbalanced counts**. Top offenders: `staffqoiclean1617_1516.do` (40/39), `base_sum_stats_tab.do` (39/25), `allvaregs.do` (29/15). renamedata.do itself: 16 opens / 7 closes → depth 9 at EOF, meaning most of the body was inside an accidental block comment.

### Comprehensive dual sweep — commit `eededa0`

Plan drafted at `quality_reports/plans/2026-05-17_comment-bug-sweep.md`. Three iterations on the design:

1. **v1**: Option A (eliminate /* */ blocks) vs B (path-glob fix) vs C (hybrid)
2. **v2** (per Christina): drop C (makes no sense); drop runtime check_comments.do (belongs at agent/commit layer, not Stata runtime; coder-critic uses command-line grep)
3. **v3** (per Christina): bundle log-directory mirror — `do/<reldir>/<name>.do` → `log/<reldir>/<name>.smcl`. Both transforms in one Python helper.

Coder wrote `py/sweep_comments_and_logdirs.py` — state-machine forward walk with depth-counting + string-literal protection. 6 edge cases handled (`*/<sub>` continuations, lone `*` trailing globs, `//****` decorative-banner overlap, fake-nested-comment pattern, orphan `*/` strip, multi-char output-list bug). Applied 842 T1 replacements + 680 T2 updates across 111 files. Convention codified in `.claude/rules/stata-code-conventions.md` (Wildcards in comments + Per-file logging structure) + `.claude/rules/phase-1-review.md` §2 Tier-1 (two new checklist items) + ADR-0021 amendment + `MEMORY.md` `[LEARN:stata]` entry.

### Coder-critic round 1 — BLOCK 62/100

Critical finding C1: pre-pass regex `r'/\*[ \t]*\n'` was too narrow — only matched lone `/*\n` openers, missed `/*<text>\n`. Result: **5 files had inner `*/` left verbatim**, prematurely closing outer blocks and **activating previously-dormant code** (e.g., `parentqoiclean1415.do` lines 152-158 `rangestat` would OVERWRITE the simple `egen` mean from line 146). Would have produced semantic divergence vs predecessor that M4 golden-master would have caught later.

### Coder round 2 + Coder-critic round 2 — PASS 90/100

Coder replaced narrow regex with state-machine forward walk (depth-counted matching for every `/*` at depth-zero). Caught **4 additional dormant-code activation sites** beyond the original 5. Critic verified balance tree-wide (1104 `/*` = 1104 `*/`). Found one Major M-T2: T2 (log-path mirror) non-idempotent on re-run; deferred to follow-up.

### T2 idempotence fix + field guide — commit `b261918`

- T2 fix: `_expand_mkdir` callback now checks whether expected `cap mkdir` cascade lines already present before inserting. Verified 0 changes on re-run.
- Helper docstring polish: "ONE-SHOT INTENT, IDEMPOTENT BY CONSTRUCTION" warning + per-process_file comment.
- Plan doc Phase 2 amendment: round-2 addendum describing regex→state-machine evolution.
- **Portable field guide** at `master_supporting_docs/stata-block-comment-bug-field-guide.md` (561 lines, 8 sections): 7 bug variants enumerated with concrete examples + grep detection + fix patterns. Self-contained for circulation to other Stata projects via `claude-config`.

### M4 acceptance run attempt #2 — IN PROGRESS

After syncing the dual sweep + T2 fix to Scribe, Christina toggled `m4_acceptance_run = 1` locally and launched `nohup stata-mp -b do do/main.do &`. As of mid-session, Phase 1 batch 9a (ACS census tract cleaning) is producing thousands of lines of `destring` output (Census Bureau `*`/`-` placeholder removal — benign). Runtime expected to be multi-hour; the bottleneck will be Phase 3 VA estimation (5,236 .ster files via CFR shrinkage).

## Today's commits (2026-05-17 evening)

```
b261918 phase-1a(§3.5): T2 idempotence fix + sweep-helper polish + portable field guide
eededa0 phase-1a(§3.5): dual sweep -- /* comment-bug fix + log-dir mirror across 111 files
```

(Plus earlier commits from morning/afternoon: `07b8f80`, `c2d208c`, `55b0c13`, `5782189`.)

## Process learnings (cumulative — append)

9. **Stata parser counts `/*` opens greedily, even inside open block comments**. Empirical evidence: 89 files with unbalanced counts behaved correctly under our nesting model (depth = opens - closes) but not under a "no-nesting" assumption. The IDE's syntax-highlighter rendering ("renamedata.do is all commented out") matched the empirical pipeline behavior (no per-file logs created, no `.dta` files saved, silent halt at first executable script downstream). The convention rule "never use `*` as path-glob wildcard in comments" is necessary and sufficient.

10. **Adversarial pairing is doing exactly what it's designed for**. Coder applied 842 T1 + 680 T2 transforms; coder-critic caught 5 files where the transform would have silently changed pipeline behavior (C1 dormant-code activation). Coder round 2 caught 4 additional sites the critic hadn't flagged. Net: 9 latent semantic-divergence sites prevented from making it to commit. Without the worker-critic separation, those would have been caught only by the M4 golden-master diff hours later.

11. **Per-file-log directory mirror is a structural improvement worth bundling**. Even without the bug fix, the flat `$logdir/` was getting unwieldy for ~110 nested do files. Mirroring `do/<reldir>/` → `log/<reldir>/` makes per-script logs trivially locatable. Marginal cost was small since we were already touching every file.

12. **Forgetting to flip the M4 flag is recoverable but expensive**. Christina's attempt #1 ran with `m4_acceptance_run = 0` (sync carried the default). Phase 2/3 sub-toggles defaulted off → no samples produced, no VA estimates. Phase 1 still ran but then immediately hit the comment bug. Costs ~30 min to discover. Next attempt: flag committed to repo at = 1 so sync to Scribe carries the right state.

## Next session pickup (updated)

1. **Acceptance run on Scribe in progress.** Christina launched `nohup stata-mp -b do do/main.do &` with the M4 flag at 1. Phase 1 ACS cleanup currently producing destring output. Expected multi-hour runtime.
2. **When run completes** (or errors): pull `log/` + `output/` back. Triage from master log + Phase 7 data-check assertions.
3. **If main.do completes cleanly**: run M4 smoke with `tier_filter = "smoke"` on `do/check/m4_golden_master.do`. Pull `output/m4_diff_summary.txt` back.
4. **Then paper tier** (~30-60 min). **Then full tier** (multi-hour).
5. **Post-smoke iteration**: address the 5 deferred M4-runner items (TODO Backlog) once we see actual smoke output indicating which manifest.
6. **Phase 1c §5.4 polish**: 6 cosmetic items still deferred (CONVENTIONS-section sweep, dead-code hardcoded paths in dormant gates, missing ledger rows). + 1 follow-up: T2 helper idempotence (now resolved by commit `b261918`).

## Status (mid-2026-05-17 evening — intermediate snapshot)

- **Phase 1a §3.5 (M4):** infrastructure 100% in place. Comment-bug + log-dir-mirror dual sweep landed. Field guide ready for `claude-config` circulation. **Acceptance run currently executing on Scribe** with M4 flag = 1.
- **Tree:** clean post-commit `b261918`; HEAD at `b261918` in sync with origin. m4_acceptance_run toggled to 1 in `do/main.do:115` for the active run (committed in this session's wrap-up).
- **ADR ledger:** 21 Decided + 1 amendment to 0021 (2026-05-17). No new ADRs.
- **Coder-critic audit trail (2026-05-17 evening):** 4 dispatches — dual-sweep round 1 BLOCK 62/100, dual-sweep round 2 PASS 90/100, T2-polish + field guide PASS. 1 escalation strike on the dual sweep round 1; resolved at round 2.
- **TODO Backlog:** 4 items resolved today; T2 follow-up resolved this session; 9 items remain (6 cosmetic Phase 1c §5.4 + 5 post-smoke M4-runner items minus 1 resolved).

---

# Continuation — 2026-05-18

## Headline

M4 attempt #2 errored at `clean_acs_census_tract.do:406` with r(603) "could not be opened" because Stata's `mkdir` doesn't auto-create parent directories, and per-script `cap mkdir "$datadir_clean"` silently failed when `$datadir` (= `$consolidated_dir/data`) didn't exist first. Fixed via `do/settings.do` bootstrap block. Master log was also strangely truncated (7.4 KB only) because each nested .do does `cap log close _all` which kills main.do's master log — fixed via named-log sweep across 107 files. M4 attempt #3 then errored at `secqoiclean1415.do:89` r(110) "totalresp already defined" — root cause was the round-2 dual-sweep helper had **over-flattened** legitimate block-comment markers in 2 files (sec1415, sec1617), making bodies into runaway block comments. Round-3 helper fix added path-glob-aware predicates + context-aware inner rewriter. Portable field guide extended with Variant 8 documenting the over-flatten trap. Today's M4 retry NOT YET LAUNCHED (commits ready; sync to Scribe + next attempt is the next user step).

## Per-step rollup (2026-05-18)

### M4 attempt #2 — `clean_acs_census_tract.do` r(603)

Christina launched main.do with `m4_acceptance_run = 1`. Master log started capturing properly (much bigger than attempt #1's 7.4 KB — eventually 240 KB). Phase 1 batch 9a started: `acs_2017_gen_dict.do` completed cleanly (4 ACS subject-table dictionaries written to `$output_dir/csv/acs/2017/`). Then `clean_acs_census_tract.do` errored at line 406 `save $datadir_clean/acs/acs_ca_census_tract_clean_2010.dta, replace` with r(603) "could not be opened".

Christina caught: there was NO `data/` directory under `consolidated/` on Scribe at all. Diagnosis: Stata's `mkdir` does NOT auto-create parent directories. The per-script `cap mkdir "$datadir_clean"` (= `mkdir "$consolidated_dir/data/cleaned"`) silently failed because the parent `$datadir = $consolidated_dir/data` was never created. The `cap` swallowed the error.

Fix (commit `5749872`): bootstrap block in `do/settings.do` lines 174-200 with `cap mkdir` for all 9 canonical top-level globals (`$consolidated_dir`, `$datadir`, `$datadir_clean`, `$datadir_raw`, `$estimates_dir`, `$output_dir`, `$logdir`, `$tables_dir`, `$figures_dir`). Idempotent via `cap`. Runs every time settings.do is included.

### Named-log sweep — fix master-log-killed-by-nested-do (same commit)

Discovered concurrently while reading the failed attempt #2 master log: only 7.4 KB captured. Investigation: every nested .do file starts with `cap log close _all` (predecessor convention), which closes ALL open logs — including main.do's master log opened at `log/main_<stamp>.smcl`. After the FIRST nested .do invocation, the master log is dead. Subsequent error context goes nowhere. The nested-do's own log briefly opens via `log using ...`, then closes on its `log close`; main.do's residual source echo after a downstream error leaks into whichever nested-do log happens to still be open when control returns.

Fix: replace `cap log close _all` + unnamed `log using` + bare `log close` triplet with NAMED-log triplet across 107 .do files. Each script's stem becomes its log name (e.g., `name(clean_acs_census_tract)`). main.do special case uses `name(master)`. `cap log close <name>` only closes that specific log, not the master.

Helper: `py/sweep_named_logs.py` (217 LOC; idempotent state-machine). Stats: 108 × `cap log close _all` → `cap log close <stem>`; 102 × `log using ... name(<stem>)` additions; 128 × bare `log close` → `log close <stem>` (covers early-exit branches in check files).

coder-critic: round 1 PASS 95/100. Bundled with settings.do bootstrap in single commit `5749872`.

### M4 attempt #3 — `secqoiclean1415.do` r(110) "totalresp already defined"

Master log this run was 1.9 MB (vs 7.4 KB before — confirming the named-log fix worked!). Phase 1 batches 9a, 9b, 9c, 9d, parent-qoiclean batch 9e all completed. Then `secqoiclean1415.do:89` errored: `by cdscode: gen totalresp = _N` with r(110) "variable totalresp already defined".

Diagnosis: the dataset at line 89 was inherited from the PREVIOUS script (parentqoiclean1819_1718.do, which already creates `totalresp`). Why did secqoiclean1415's body not run? Because the body (`use sec1415, clear`, `keep cdscode a14...`, foreach renames, etc.) was SILENTLY COMMENTED OUT.

Root cause: the 2026-05-17 dual-sweep helper's `_flatten_lone_block_opens` pre-pass had **over-flattened** legitimate block-comment markers in 2 files (sec1415, sec1617). The pre-pass used greedy depth-counted `_find_matching_close` to find "multi-line outer blocks", then **blanket replaced** every `/*` and `*/` digraph in the inner span. For files with path-glob substrings inside the header (e.g., `$logdir/*`), the depth counter inflated past the real header close at line 40, and the matched outer-close landed at line 87 (a `* count ... */` line-comment with stray `*/` text). Inner span extended lines 2-87. Blanket replacement destroyed:
- Line 40 `------*/` → `------<x>` (header close lost)
- Line 44 `/* rename ... */` → `/<x> rename ... <x>` (single-line block destroyed)
- Lines 73, 74, 80 (more single-line blocks destroyed)

Stata then saw line 1's `/*` open with no `*/` until line 87 (which DID survive because it was in `*`-prefixed line-comment context, treated as text). Lines 2-87 became one giant runaway block comment. `use sec1415, clear` etc. all silent. At line 88 `sort cdscode`, dataset was inherited from previous script. Line 89 errored.

### Round-3 helper fix (commit `06ccbdf`)

Coder fix:
1. **Restoration**: 7 surgical edits across 2 files (sec1415 lines 40/44/73/74/80; sec1617 lines 40/44) restoring `*/` and `/* ... */` markers
2. **Helper rewrite**: new predicates `_is_path_glob_open` / `_is_path_glob_close` (preceded/followed by path-continuation char). `_find_matching_close` now skips path-glob digraphs when counting depth. New `_rewrite_inner_block_markers` walks the inner span char-by-char and rewrites ONLY real block markers (whitespace-adjacent), preserving path-globs (which Transform 1 state machine handles natively). `_flatten_lone_block_opens` calls the new walker instead of blanket `inner.replace(...)`.
3. **Field guide extension**: appended Variant 8 ("Over-flatten bug in fix-tool pre-pass — round-2 trap") to `master_supporting_docs/stata-block-comment-bug-field-guide.md` with concrete example, detection greps, root-cause analysis, fix pattern, reference implementation. Plus updates to §3 (detection commands), §4 (path-glob-awareness invariant), §6 (false-fix row), §7 (case study), §8 (history).

coder-critic: round 1 PASS 95/100. Three non-blocking polish items deferred + addressed in follow-up commit `33d41c6`:
- Round-3 review cited in helper REFERENCES block
- TODO Backlog entry for idempotence regression test
- Round-2 review Status set to `Superseded by 2026-05-18_overflatten-fix_coder_review.md`

### Inventory check

Across 86 files containing `/<x> ... <x>` patterns, ONLY sec1415 and sec1617 had the over-flatten damage. All other files' `/<x>` patterns are LEGITIMATE path-glob rewrites in headers — not over-flatten artifacts. Confirmed via `grep '^-+<x>$'` returning only 2 hits.

Other path-glob-heavy headers (secpooling, renamedata, allvaregs) were spot-checked: their header closes at the expected line are intact. So the over-flatten was specific to these 2 files (likely because their headers' path-globs happened to inflate the depth counter past the real close — a function of where path-glob `/*` substrings appear in the header text and the file's overall structure).

## Today's commits (2026-05-18)

```
33d41c6 docs: 3 polish items from round-3 over-flatten fix review
06ccbdf phase-1a(§3.5): fix over-flatten bug (round-3 helper fix) + extend field guide
5749872 phase-1a(§3.5): bootstrap settings.do + named-log sweep across 107 files
```

(Plus 4 commits earlier today from before the over-flatten discovery: `d0991f2` track logs, `c64a1b7` TODO update for named-log follow-up.)

## Process learnings (cumulative — append, #13-15)

13. **Stata's `mkdir` doesn't auto-create parent directories.** Per-script `cap mkdir "$datadir_clean"` failed silently when `$datadir` didn't exist. The `cap` swallowed the error. Fix: bootstrap all top-level globals in settings.do. Future workflow rule: any settings.do that defines a directory global should also `cap mkdir` it as part of the bootstrap. Codify in stata-code-conventions.md as part of the consolidation pattern.

14. **`cap log close _all` is a predecessor anti-pattern.** It closes ALL open logs, including the orchestrator's master log. In a single-script-runs-standalone world it's defensive (closes any inherited log); in a master.do-invokes-many-scripts world it kills the master log irrecoverably. Named logs (`name(<stem>)`) are the correct pattern: `cap log close <stem>` only closes that script's log; master log survives. Codify in stata-code-conventions.md.

15. **Pre-pass "fake nested comment" detection must be path-glob-aware.** The round-2 dual-sweep helper used greedy depth-counted matching to find "multi-line outer blocks", treating path-glob `/*` substrings (e.g., `$logdir/*`) as depth-incrementing opens — matching Stata's parser behavior precisely. But then it blanket-replaced ALL `/*` and `*/` digraphs in the inner span, destroying legitimate block markers (header close + single-line body blocks). Round-3 fix: predicates distinguish path-glob digraphs from real block markers; the inner rewriter only touches real markers. Captured in the field guide as Variant 8 + §6 false-fix row + §4 critical-invariant bullet. Codified for cross-project use.

## Next session pickup (updated 2026-05-18)

1. **Christina syncs commits `5749872`, `06ccbdf`, `33d41c6` to Scribe** (3 commits, ~80 files modified across them, all .do files + helpers + reviews + docs).
2. **Christina re-launches M4 acceptance** with `m4_acceptance_run = 1` already committed: `nohup stata-mp -b do do/main.do &`.
3. **Phase 1 should now progress** through all of batch 9e (parent + sec + staff qoiclean), 9g (responserate), 9f (poolingdata), into Phase 2 (samples — quick), then Phase 3 (VA estimation — multi-hour, the bottleneck).
4. **If main.do completes**: launch M4 smoke (`tier_filter = "smoke"` already set in `do/check/m4_golden_master.do:380`).
5. **Then paper tier, then full tier** per `quality_reports/plans/2026-05-17_m4-golden-master-protocol.md`.
6. **Post-smoke iteration**: the 5 deferred M4-runner items + 6 cosmetic Phase 1c §5.4 items remain on TODO Backlog.

## Status (end of 2026-05-18)

- **Phase 1a §3.5 (M4):** infrastructure COMPLETE + 4 attempts behind us (1: silent comment bug; 2: r(603) no `data/` dir; 3: r(110) over-flatten). All 4 root causes diagnosed + fixed. Attempt #4 prerequisites ready.
- **Tree:** clean post-commit `33d41c6`; HEAD in sync with origin.
- **ADR ledger:** 21 Decided + 1 amendment to 0021 (2026-05-17). No new ADRs this session.
- **Helper evolution:** `py/sweep_comments_and_logdirs.py` round 1 (narrow regex) → round 2 (state-machine) → round 3 (path-glob-aware predicates). `py/sweep_named_logs.py` new helper.
- **Field guide:** 8 Variants documented + path-glob-awareness invariant + false-fix rows + case study. Portable to `claude-config`.
- **Coder-critic audit trail (2026-05-18):** 5 dispatches — bootstrap+named-log PASS 95/100; restoration+helper-fix PASS 95/100; field-guide extension PASS; polish items PASS 98/100. 0 BLOCK verdicts in this session.
- **TODO Backlog:** 5 items resolved across 2026-05-17 + 2026-05-18 (named-log triplet, T2 idempotence, 3 polish items); 9 items remain (6 cosmetic + 5 post-smoke minus 2 already resolved). 1 new entry added: idempotence regression test.
- **Total commits today (2026-05-18):** 3 substantive + 4 housekeeping/follow-up = 7. Combined 2026-05-17 + 2026-05-18: ~15 commits.

---

## 2026-05-25 continuation — M4 attempt #4 r(601) hotfix + Scribe-safety infrastructure

Picked up after 7 days idle. State at start: M4 attempt #4 had been launched on Scribe 2026-05-18 (master log `log/main_18-May-2026_10-30-58.smcl`, 1.9 MB; synced back to laptop but uncommitted); pipeline crashed `r(601)` on `do/data_prep/poolingdata/clean_va.do:97-103` reading `$estimates_dir/va_cfr_all_v1/va_est_dta/va_ela_all.dta`. Workflow-sync repo had landed 4 commits 2026-05-24 (universal hook + skill propagation; no project work).

### Per-step rollup

**Step 1 — Diagnose the r(601).** Cross-phase ordering bug in `do/main.do`. `clean_va.do` invoked at Phase 1 batch 9f (line 195) but CHAIN-reads VA outputs produced by `do/va/merge_va_est.do` at Phase 3 batch 3c1 (line 311). File's own RELOCATION header (lines 17-18) declared the dependency: predecessor caschls master.do treated VA outputs as pre-existing artifacts from a separate cde_va_project_fork run; consolidation collapses both into one master so the dependency now binds. Predecessor pipeline never tripped this because VA estimates were always cached from a prior cde fork run.

**Step 2 — Hotfix + coder-critic.** Moved `clean_va.do` invocation from Phase 1 site to start of Phase 5 (survey-VA trailer). Rationale for Phase 5 trailer vs Phase 3 trailer: clean_va.do produces `va_pooled_all.dta` consumed only by Phase 5; placing it at start of Phase 5 keeps it semantically grouped with consumers AND gates it consistently under `if `run_survey_va''`. Phase 1 batch 9f comment updated to "4 of 5 files"; new Phase 5 explanatory comment added. Coder-critic dispatched per phase-1-review.md §3 (paper-affecting code change): PASS 95/100 round 1; -3 for stale Phase 5 header (not mentioning Step 9 batch 9f trailer) and -2 for missing in-place `analysisready` update side-effect in one-liner. Both polish items applied pre-commit. Commit `184ff0d`.

**Step 3 — M4 attempt #4 log artifacts.** Committed 47 modified per-step logs + 4 new untracked log dirs (poolingdata/, qoiclean/{secondary,staff}/, responserate/) + the attempt #4 master log + attempt #3 master log as accumulating audit trail, mirroring `d0991f2` pattern from 2026-05-17. Commit `932a3fc`.

**Step 4 — Scribe-safety infrastructure.** User flagged divergent Scribe-side checkout with populated `data/`, `figures/`, etc. and asked specifically to gitignore `data/` to prevent accidental push from Scribe. Three-layer defense:
  - **`.gitignore`** — added `/data/*` + `/data/raw/*` + `/data/cleaned/*` + `/estimates/*` patterns with explicit allowlist for `.gitkeep` stubs. Path-anchored (leading `/`) so only matches project-root paths.
  - **`estimates/.gitkeep`** — new stub for the previously-untracked canonical dir.
  - **`.githooks/pre-push`** — git-native Bash hook (NOT Claude-specific, since Scribe has no Claude). Diffs the push range (or, for new-branch pushes, all commits not on other remotes via `git rev-list ... --not --remotes`), aborts with remediation message if any file under `data/` or `estimates/` (other than the four allowlisted `.gitkeep` stubs) appears in the range. Per-machine opt-in via `git config core.hooksPath .githooks`. Override via `git push --no-verify`. Commit `e31fe15`.

**Step 5 — Scribe-setup plan doc.** Wrote `quality_reports/plans/2026-05-25_scribe-setup.md`. Iterated 3x based on user feedback:
  - **v1 (`7622aec`):** initial plan — pre-flight diagnostic + 3 branches (A/B/C) for divergent-pull resolution + sparse-checkout for excluding `.claude/` (and optionally other Claude-only/LaTeX dirs) + pre-push hook activation + going-forward sync protocol + 6 common errors + 8-item audit checklist.
  - **v2 (`b680d5f`):** added reading of user's pasted git status output (1 commit ahead, 191 behind; `data/cleaned/acs/acs_ca_census_tract_clean_2010.dta` modified = TRACKED on Scribe) + the data-preservation wrinkle (`git reset --hard` would delete tracked-on-Scribe-but-not-on-origin files) + 7-stage in-place-reset path with `/tmp/` backup.
  - **v3 (`0f888bf`):** after user confirmed `git init` history, added Option B (delete + re-clone) as primary recommendation with comparison table; demoted in-place reset to "Option A — alternative".

### Today's commits

```
184ff0d phase-1a(§3.5): main.do clean_va.do Phase 1→Phase 5 reorder; M4 attempt #4 r(601) hotfix
932a3fc chore: log artifacts from M4 acceptance attempt #4 (2026-05-18 run)
e31fe15 chore(scribe-safety): gitignore data/ + estimates/; add git-native pre-push hook
7622aec docs: scribe-side setup plan for M4 attempt #5 (divergent-pull + sparse-checkout + pre-push)
b680d5f docs: scribe-setup — add `git init` history wrinkle + recommended reset path
0f888bf docs: scribe-setup — add nuke+re-clone as Option B (recommended over in-place reset)
```

6 commits, all pushed.

### Process learnings (cumulative — append, #16-18)

16. **Cross-phase ordering bugs survive per-batch coder-critic by design.** Per-batch critics (Phase 1a §3.3 Steps 1-11) reviewed each batch in isolation. Cross-phase chain dependencies — like clean_va.do's read of merge_va_est.do output — slipped through because: (a) Step 9 batch 9f saw clean_va.do as a Phase 1 pooling file (verbatim relocation per predecessor's master.do:302-341), (b) Step 3 batch 3c1 added merge_va_est.do at Phase 3 (canonical VA estimation chain), (c) no batch ever held both in scope. Pre-flight Tier-2 audit (2026-05-16) caught 3 of these but missed this one because clean_va.do's RELOCATION header *declared* the dependency cleanly — partition C (data_prep) coder-critic saw a self-consistent file. The runtime invariant ("the consumer must be invoked AFTER the producer") was never empirically tested before M4. **`check_chain.do` proposed for Phase 1c §5.3 would catch this class** — a programmatic post-relocation scan for producer-CANONICAL/consumer-LEGACY-OR-WRONG-PHASE pairs would have flagged clean_va.do reading `$estimates_dir/...` before Phase 3 ran. Codify after M4 closure.

17. **Pre-existing-artifact assumptions from predecessor pipelines must be re-tested in consolidated single-master flow.** caschls's master.do assumed VA outputs were pre-existing (built by a separate cde_va_project_fork pipeline). Consolidation collapses both into one main.do; the pre-existing assumption no longer holds, but the comment ("Order from predecessor master.do:302-341: <sub>pooling -> mergegr11enr -> clean_va") preserved the predecessor order verbatim without flagging the broken assumption. Going forward: any RELOCATION comment that documents predecessor invocation order should be cross-checked against the consolidated invocation graph for cross-phase chain dependencies.

18. **For divergent local repos (Scribe), "discard local history + adopt origin" is simpler than "rewrite history".** `git filter-repo` / interactive rebase to scrub data files from Scribe's history would be complex, blocked by `.claude/rules/destructive-actions.md`, and unnecessary — origin's history is pristine, so adopting it wholesale (with a `/tmp/` backup of disk files first) trivially produces the same end state. Codified in `quality_reports/plans/2026-05-25_scribe-setup.md` as Option B (nuke + re-clone, recommended) and Option A (in-place reset, alternative).

### Status (end of 2026-05-25)

- **Phase 1a §3.5 (M4):** attempt #4 r(601) root cause fixed (`184ff0d`); attempt #5 blocked on Scribe-side sync prerequisites.
- **Scribe sync:** plan doc shipped; awaits user execution of Option B (nuke + re-clone) on Scribe followed by sparse-checkout + hook activation.
- **Tree:** clean post `0f888bf`; HEAD in sync with origin.
- **ADR ledger:** unchanged (21 Decided + 1 amendment).
- **Coder-critic audit trail (today):** 1 dispatch — main.do clean_va.do reorder PASS 95/100 round 1 (no BLOCK). Other commits skipped critic per phase-1-review.md §3 (governance / docs / logs / Bash hook).
- **TODO Backlog:** unchanged (9 items); 1 new Active entry added for Scribe-side setup.
- **Total commits today (2026-05-25):** 6 (1 code, 1 log artifacts, 1 infra, 3 doc-iterations).

### Next session pickup

**Blocking on user:** Scribe-side setup per `quality_reports/plans/2026-05-25_scribe-setup.md` Option B (delete + re-clone) or Option C (delete `.git/` only — user proposal 2026-05-25, simpler still; pending plan-doc update). After Scribe is synced:
1. Sparse-checkout to exclude `.claude/` (Step 2 of plan)
2. Activate `.githooks/pre-push` via `git config core.hooksPath .githooks` (Step 3)
3. Re-launch M4 acceptance attempt #5: `nohup stata-mp -b do do/main.do &`
4. Monitor through Phase 5 trailer (where clean_va.do now invokes); if it passes, run smoke tier of M4 golden-master comparison.
