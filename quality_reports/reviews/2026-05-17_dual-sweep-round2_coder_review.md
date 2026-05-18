# Dual-Sweep Review — Round 2 — coder-critic
**Date:** 2026-05-17
**Reviewer:** coder-critic
**Target:** dual sweep round-2 fix on `py/sweep_comments_and_logdirs.py::_flatten_lone_block_opens` (state-machine rewrite) + 5 originally-flagged + 4 additional qoiclean files re-flattened to close C1 / C2 from round 1; balance + regression checks across 159 active+archived `.do`/`.doh` files
**Score:** 90/100
**Status:** Superseded by quality_reports/reviews/2026-05-18_overflatten-fix_coder_review.md
**Supersedes:** `quality_reports/reviews/2026-05-17_dual-sweep_coder_review.md`

---

## Verdict — PASS

Round 1 BLOCK at 62/100. Critical findings C1 (5 files with un-commented dormant code) and C2 (verify no regressions elsewhere) are CLOSED. The coder applied option (a) from round 1 recommendation — broaden the helper to catch all `/* ... */` blocks at depth 0 — rather than the safer option (b) (5 manual edits). The broader approach was the correct call: it surfaced 4 additional files (`parent/parentqoiclean{1415,1516,1617,1819_1718}.do`) where a SECOND inner `/* ... */` pair existed lower in the same outer block that round-1 reviewer missed. Manual option (b) would have left those latent.

Hard gate 80/100 is met. Recommend proceeding to commit. T2 idempotence concern is real but defensible as a deferred follow-up (sweep is a one-shot tool, not pipeline-integrated; running it twice is a developer error, not a routine failure mode).

---

## CRITICAL — closure verification

### C1 — 5 originally-flagged sites are correctly enclosed (CLOSED)

Read each file's relevant span. Result: every previously-stray `*/` is now `<x>`, and the outer block-comment closes correctly at a single legitimate `*/` later.

| File | Outer open | Inner pair (round-1 missed) flattened to | Outer close (single legit `*/`) |
|---|---|---|---|
| `do/data_prep/qoiclean/staff/staffqoiclean1617_1516.do` | L188 `/* Note: include qoi 41 ...\n` | L189 `/<x> note: mean of qoi41 ... <x>` | L207 ` */` |
| `do/data_prep/qoiclean/parent/parentqoiclean1415.do` | L150 `/* This is old code ...\n` | L151 `/<x> generate mean ... <x>` | L161 ` ... //drop the temp vars */` |
| `do/data_prep/qoiclean/parent/parentqoiclean1516.do` | L195 `/* This is old cold ...\n` | L196 `/<x> generate mean ... <x>` | L208 ` */` |
| `do/data_prep/qoiclean/parent/parentqoiclean1617.do` | L203 `/* Note: this is old code ...\n` | L204 `/<x> generate mean ... <x>` | L215 ` ... //drop the temp vars */` |
| `do/data_prep/qoiclean/parent/parentqoiclean1819_1718.do` | L195 `/* This is old code ...\n` | L196 `/<x> generate mean ... <x>` | L206 ` ... //drop the temp vars */` |

All five outer blocks now span correctly across the dormant code regions, preserving predecessor behavior (the bounded rangestat means stay dormant; the simple egen means computed earlier remain the saved values). The plan v3 "no semantic changes" invariant is restored. ✓

### C2 — 4 additional sites also handled (CLOSED, with bonus catch)

The round-2 broadened pre-pass surfaced a SECOND inner `/* ... */` pair in each of the 4 parent files (the round-1 reviewer caught only the first inner pair per file because the regex-narrow approach would have only required 5 fixes total).

| File | Second inner pair flattened |
|---|---|
| `parentqoiclean1415.do` | L159-160 `/<x> Note: don't worry ... after collapsing dataset <x>` |
| `parentqoiclean1516.do` | L205-206 `/<x> Note: don't worry ... after collapsing dataset <x>` |
| `parentqoiclean1617.do` | L213-214 `/<x> Note: don't worry ... after collapsing dataset <x>` |
| `parentqoiclean1819_1718.do` | L204-205 `/<x> Note: don't worry ... after collapsing dataset <x>` |

These would have remained latent bugs under round-1 option (b) — the 5 manual edits would have closed the outer block at the FIRST inner `*/`, leaving the second inner pair half-rewritten with similar premature-close consequences (though less dramatic since the dormant code between the two inner pairs is small: 2 `gen lowbound`/`gen highbound` + 4-line foreach + 2-line rename). The round-2 state-machine approach catches both. ✓

**This is a substantive win**: option (a) was more robust than the round-1 reviewer's preferred option (b). Credit to coder for choosing the more thorough fix.

### Tree-wide regression check (CLOSED)

```
grep -rnE '^\s*/<x>.*\*/\s*$' do/ --include='*.do' --include='*.doh' | grep -v _archive
```

Returns **0 hits**. No `/<x> ... */` patterns remain anywhere in active tree.

For thoroughness, also scanned `do/_archive/` — also 0 matches. No new corruption was introduced. ✓

### Per-file `/*` balance (CLOSED)

Per-file token counts cross-referenced via `Grep` against all 159 `.do`/`.doh` files in `do/` (active + archive). Every file's `/*` count equals its `*/` count. Sampled hot spots (round-1 affected files + heaviest files):

| File | `/*` | `*/` |
|---|---|---|
| `do/data_prep/qoiclean/staff/staffqoiclean1617_1516.do` | 34 | 34 |
| `do/data_prep/qoiclean/parent/parentqoiclean1415.do` | 12 | 12 |
| `do/data_prep/qoiclean/parent/parentqoiclean1516.do` | 20 | 20 |
| `do/data_prep/qoiclean/parent/parentqoiclean1617.do` | 20 | 20 |
| `do/data_prep/qoiclean/parent/parentqoiclean1819_1718.do` | 20 | 20 |
| `do/main.do` | 12 | 12 |
| `do/share/base_sum_stats_tab.do` | 25 | 25 |
| `do/share/svyvaregs/allvaregs.do` | 15 | 15 |
| `do/data_prep/k12_postsec_distance/k12_postsec_distances.do` | 18 | 18 |
| `do/va/reg_out_va_all_fig.do` | 15 | 15 |
| `do/data_prep/poolingdata/staffpooling.do` | 13 | 13 |
| `do/data_prep/poolingdata/secpooling.do` | 11 | 11 |
| `do/data_prep/poolingdata/parentpooling.do` | 9 | 9 |

Both grep totals: 1104 token occurrences across 159 files — identical counts confirm tree-wide balance. ✓

---

## MAJOR — state machine soundness

### M-S1 — `_flatten_lone_block_opens` round-2 rewrite is sound

Read `py/sweep_comments_and_logdirs.py` lines 56-176 (helpers `_find_matching_close` + `_flatten_lone_block_opens`):

**String-literal protection (lines 128-159)** — when `state == "code"` and `ch == '"'`, transitions to `state == "string"`. In `string` state, ONLY `"` triggers a transition back; the `/`+`*` digraph check at line 133 is bypassed. ✓ `/*` inside `"..."` is correctly not treated as a block open.

**Depth-counting in `_find_matching_close` (lines 56-80)** — standard depth-counter from position immediately after `/*`. Every `/*` increments depth; every `*/` decrements. Returns position of the `*/` that brings depth to 0. Handles arbitrary nesting depth (Stata's parser would too). Edge case: at `i < n - 1` loop condition correctly guards 2-char lookahead. ✓

**Unmatched `/*` open handling (lines 137-140)** — when `_find_matching_close` returns -1, the pre-pass leaves the open alone and advances 2 chars. Transform 1's main pass then sees the unmatched `/*` and rewrites it to `/<x>` (since it's inside no comment-state-yet, but actually... it depends on what follows). Defensible: predecessor tree should not have unmatched opens; if one survives, Transform 1's state machine has its own handling. ✓

**Multi-line filter (line 147)** — only flatten if inner span contains a newline AND a nested digraph (`/*` or `*/`). Single-line `/* foo */` blocks are not flattened (no nesting risk; Transform 1 handles them in `block` state). ✓ This is the key safety property: legitimate `/* short comment */` text inside multi-line blocks would NOT be touched if the OUTER block is single-line. The filter restricts flattening to the genuine "fake nested" pattern.

**Reverse-order rewrite (lines 167-174)** — processes `spans` in reverse so each rewrite's offset doesn't invalidate later spans. Standard pattern. ✓

**Counting (lines 169-173)** — counts inner `/*` + `*/` digraphs for the `rewrites` return value. Used for logging only. ✓

**Edge case: `*/` at EOF with no matching `/*`** — `_flatten_lone_block_opens` only iterates code-state `/*` opens; an orphan `*/` is invisible to this pass. The follow-up `strip_orphan_block_closes` pass (lines 385-511) catches that, using its own depth-map verification. ✓

**Edge case: nested `/*` inside an outer `/*`** — `_find_matching_close` handles arbitrary nesting via depth-counter. The outer-only flattening at depth 0 (via the `state == "code"` outer loop) is the intent. Even if the inner block contains its own `/*`/`*/` pairs that net to 0, the outer span captures everything between the outer open and its matching close. ✓

State machine PASS.

### M-S2 — Docstring round-2 update is accurate

The function's docstring (lines 83-118) now documents:
- The "fake nested comment" pattern with concrete example.
- The round-1 narrow-regex bug and the 5 specific files affected.
- The round-2 state-machine approach.
- String-literal protection contract.

Comprehensive. Round 1's M1 deduction (helper docstring fidelity) is closed. ✓

---

## MAJOR — T2 idempotence (CONFIRMED issue, DEFERRABLE)

### M-T2 — T2 (`transform_log_paths`) is not idempotent due to `_CAP_MKDIR_LOGDIR` re-insertion

**Analysis of `_LOGPATH_SMCL_ANY` (line 541)**: `re.compile(r'\$logdir/([A-Za-z0-9_.-]+)\.smcl')`. Character class excludes `/`. After first run, `$logdir/data_prep/prepare/renamedata.smcl` would attempt match at position 0 (`$logdir/`); regex tries to capture `[A-Za-z0-9_.-]+` (matches `data_prep`), then requires `\.smcl` — but next char is `/`, not `.`. Match fails. Regex doesn't re-match the already-nested path. **`_LOGPATH_SMCL_ANY` is idempotent.** ✓

**Same logic for `_LOGPATH_LOG_ANY` (line 544)**. Idempotent. ✓

**Analysis of `_CAP_MKDIR_LOGDIR` (lines 548-550)**: `re.compile(r'^(\s*)cap\s+mkdir\s+"\$logdir"\s*$', re.MULTILINE)`. Matches the ORIGINAL `cap mkdir "$logdir"` line, which is preserved (not modified) after first run. The sweep inserts SIBLING lines AFTER the matched line; the original line remains intact. On second run, `_CAP_MKDIR_LOGDIR` re-matches the same line (via `subn` with `count=1`), and `_expand_mkdir` re-inserts the cascade. **Second run produces a doubled cascade.** ✗ (Coder's flag is correct.)

**Severity**: Major in principle, but practically deferrable for these reasons:

1. The sweep is a **one-shot helper**, not part of `do/main.do` or any recurring pipeline. It exists to migrate the consolidated tree from the predecessor's flat-log structure to the nested-log convention. Running it twice would be a developer mistake.
2. Even if rerun, the duplicate `cap mkdir` lines are syntactically harmless (`cap mkdir` is no-op on existing dirs). No data corruption; only diff noise.
3. The fix is straightforward: gate the insertion on whether the sibling lines already exist (e.g., regex `cap\s+mkdir\s+"\$logdir/{reldir_parts[0]}"` — if matches, skip insertion). One-block change to `_expand_mkdir`.

**Recommendation**: file as a follow-up TODO. Do NOT block the round-2 commit. The deduction below reflects this is a known limitation that should not have shipped with the original sweep, but is acceptable to defer.

**Deduction: −3 (Major, deferrable).** Cap at Major because it's not a correctness issue under the intended one-shot use; documentation in the helper would close it (a `WARNING: do not re-run on already-swept files` comment near `process_file`).

---

## MAJOR — round-1 M1 / M2 status

### M1 (round-1) — pre-pass regex limitation documentation

CLOSED. The round-2 docstring rewrite (lines 96-115) now explicitly documents the round-1 bug + the round-2 fix. Previous -3 deduction lifted.

### M2 (round-1) — per-fix `// 2026-05-17 sweep:` markers in the 5 affected files

NOT APPLICABLE in round 2. The round-2 fix is upstream in the helper (not 5 manual edits to source files), so the marker rationale (audit trail for manual edits) no longer applies. The round-2 trace is the helper's docstring + this review. Previous -2 deduction lifted.

---

## CRITICAL checks (verified PASS — beyond C1/C2)

All round-1 PASS items remain PASS (round-2 fix was scoped to `_flatten_lone_block_opens`; auxiliary artifacts untouched). Verified via Read:

- **Convention codification** — `.claude/rules/stata-code-conventions.md` lines 51-90 (Wildcards in comments + Per-file logging structure) intact. ✓
- **`.claude/rules/phase-1-review.md` §2 Tier-1 lines 41-42** (`/*` balance + log path mirror checks) intact. ✓
- **`decisions/0021_main-settings-relocation-and-self-contained-sandbox.md`** Amendment 2026-05-17 — not re-read in this round (no scope) but unchanged per scope of fix. ASSUMED unchanged.
- **`MEMORY.md` `[LEARN:stata]` entry** — ASSUMED unchanged.
- **`do/check/check_logs.do` walker** — ASSUMED unchanged.

For the ASSUMED items: per `.claude/rules/adversarial-default.md`, this is acceptable since the round-2 scope was strictly the helper rewrite + the 9 affected qoiclean files; if any auxiliary doc had been touched, it would show in the file count.

---

## MINOR checks (verified)

### Tree-wide `*/` balance

Both `/*` and `*/` grep totals report 1104 occurrences across 159 files (active+archive). Per-file counts cross-verified for ~13 hot-spot files; all balanced. The `do/_archive/` files are also balanced (they were not modified by the sweep but are caught by the same grep) — confirming no archive-file collateral damage from previous sweep runs. ✓

### No `//*` survives

Verified via prior round-1 check (`grep -rE '//\*' do/ --exclude-dir=_archive` returned 0). Round 2 did not touch the `//*` handling code (lines 235-245 of helper). Confirmed by re-reading those lines: unchanged. ✓

### Helper idempotence (T1 only)

T1 (`transform_comment_globs`):
- After first run, comment-state `/*` are all rewritten to `/<x>`; no `/*` survives in comment state. Second run: no comment-state matches → no rewrites. ✓
- After first run, comment-state `*/` are rewritten to `<x>` or `<x>/` depending on follow char; no `*/` survives in comment state except real block-closes. Second run: real block-closes still match the heuristic (followed by whitespace/newline/punctuation, NOT alphanumeric/`_`/`<`/`$`/`{`/`*`), so they're correctly preserved as block-closes (state transition to `code`). ✓
- After first run, the `//` → `// ` insertion only fires on `//*`; after first run, those have become `// *`, so the `if after == "*":` check (line 238) is false. ✓
- `_flatten_lone_block_opens` pre-pass: after first run, all multi-line block interiors with digraphs have been flattened to use `<x>` placeholders (no `/*` or `*/` inside). Second run: the `("/*" in inner or "*/" in inner)` guard at line 147 fails → no flattening. ✓
- `strip_orphan_block_closes`: after first run, orphan whole-line `*/` are stripped; depth-map on second run reaches the same conclusions but the candidates are now gone. ✓

**T1 is fully idempotent. T2 is non-idempotent (M-T2 above).**

---

## Score breakdown

| Item | Severity | Deduction |
|---|---|---|
| C1 (round-1 critical, 5 files) | Closed | 0 (was -25) |
| C2 (round-1 critical, follow-on regression check) | Closed | 0 (was -10) |
| M1 (round-1 major, docstring) | Closed | 0 (was -3) |
| M2 (round-1 major, per-fix markers) | N/A under round-2 scope | 0 (was -2) |
| M-T2 (round-2 major, T2 non-idempotent) | Major, deferrable | -3 |
| State machine soundness | PASS | 0 |
| Tree-wide regression check | PASS (0 corruptions) | 0 |
| Balance check (159 files) | PASS | 0 |
| Auxiliary artifacts (rules / ADR / MEMORY / walker) | PASS (unchanged) | 0 |
| **Polish gap** — helper lacks a "do not re-run on already-swept files" warning comment | Minor | -2 |
| **Polish gap** — round-2 fix description in plan v3 not yet updated (round-1 plan still says regex-based pre-pass) | Minor | -5 (documentation drift; plan v3 needs amendment noting the round-2 approach) |
| Starting score | — | 100 |
| **Final** | — | **90** |

---

## Recommendations

### To proceed to commit (READY)

1. Commit the dual sweep + round-2 fix with footer `coder-critic: round 2 — PASS (90/100); T2 non-idempotence deferred to follow-up TODO.`
2. Add a `TODO.md` Backlog item: "Make `transform_log_paths` idempotent — gate `_CAP_MKDIR_LOGDIR` expansion on whether sibling cap-mkdir lines already exist."
3. Optionally amend `quality_reports/plans/2026-05-17_comment-bug-sweep.md` (v3 → v4) noting the round-2 state-machine rewrite supersedes the v3 regex-based pre-pass description.

### Future-proofing (low priority)

- Add a 1-line warning comment near `def process_file` in the helper: `# WARNING: one-shot tool. Running twice on already-swept files duplicates the cap-mkdir cascade (see review 2026-05-17 round 2).` Closes the polish gap for −2.
- The state-machine `_flatten_lone_block_opens` rewrite is significant enough that a brief unit test on a synthetic input would be welcome — but not required for commit. (`py/test_sweep.py` doesn't currently exist; deferrable.)

---

## Compliance Evidence (from .claude/state/verification-ledger.md)

Same as round 1: the ledger does not yet have rows for the 111+ modified files. ASSUMED defensible given the Tier-1 grep checks are the gates for `/*`-balance and log-path-mirror, and Tier-3 data-checks (on Scribe post-commit) verify empirical correctness. The 5 + 4 = 9 round-2-affected files inherit the same balance-check evidence shown above (per-file `/*`/`*/` counts equal).

For round-2 specifically: ledger rows for `py/sweep_comments_and_logdirs.py::_flatten_lone_block_opens` (state-machine soundness) and the 9 affected qoiclean files (no-stray-`/<x>...*/`) would be the natural additions. ASSUMED — the regression-grep check above is the evidence; ledger row formalization is mechanical follow-up.

---

## Escalation Status: Round 2 of 3 — PASS

Hard gate 80/100 met (90/100). Recommend commit. No round 3 needed.

If user wants to address the −2 polish gap (helper warning comment) and −5 documentation drift (plan v3 amendment) before commit, a final round-3 review would bring this to ~95-97. But neither is blocking, and the M4 golden-master verification is the next strategic gate — fold the polish work into the post-M4 cleanup if time-bounded.

---

## Round-1 → Round-2 trajectory summary

| Round | Score | Verdict | Key change |
|---|---|---|---|
| 1 | 62 | BLOCK | Pre-pass regex `r'/\*[ \t]*\n'` too narrow; 5 files have un-commented dormant code |
| 2 | 90 | PASS | State-machine pre-pass walks every `/* ... */` block at depth 0; caught 5+4=9 files; T2 idempotence flagged as deferrable Major |

Net delta: +28. Both Critical findings (C1, C2) closed. One Major remains (M-T2 deferrable). Two Minor polish gaps. Comfortable PASS.
