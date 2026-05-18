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

## Status (end of 2026-05-17)

- **Phase 1a §3.5 (M4):** infrastructure 100% in place. Comment-bug + log-dir-mirror dual sweep landed. Field guide ready for `claude-config` circulation. **Acceptance run currently executing on Scribe** with M4 flag = 1.
- **Tree:** clean post-commit `b261918`; HEAD at `b261918` in sync with origin. m4_acceptance_run toggled to 1 in `do/main.do:115` for the active run (committed in this session's wrap-up).
- **ADR ledger:** 21 Decided + 1 amendment to 0021 (2026-05-17). No new ADRs.
- **Coder-critic audit trail (2026-05-17 evening):** 4 dispatches — dual-sweep round 1 BLOCK 62/100, dual-sweep round 2 PASS 90/100, T2-polish + field guide PASS. 1 escalation strike on the dual sweep round 1; resolved at round 2.
- **TODO Backlog:** 4 items resolved today; T2 follow-up resolved this session; 9 items remain (6 cosmetic Phase 1c §5.4 + 5 post-smoke M4-runner items minus 1 resolved).
