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
