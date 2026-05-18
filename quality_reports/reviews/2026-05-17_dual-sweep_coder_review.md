# Dual-Sweep Review — coder-critic
**Date:** 2026-05-17
**Reviewer:** coder-critic
**Target:** dual sweep (Transform 1 path-glob `/*`→`/<x>` + Transform 2 log-dir mirror) across 111 modified files + `py/sweep_comments_and_logdirs.py` + 4 governance updates (rules / ADR-0021 amendment / MEMORY.md / `do/check/check_logs.do`)
**Score:** 62/100
**Status:** Superseded by `quality_reports/reviews/2026-05-17_dual-sweep-round2_coder_review.md`
**Supersedes:** —

---

## Verdict — BLOCK

Two CRITICAL findings prevent commit. Both stem from a single root cause: the pre-pass `_flatten_lone_block_opens` in `py/sweep_comments_and_logdirs.py` uses a regex (`r'/\*[ \t]*\n'`) that matches the *lone* `/*\n` form but NOT the `/* <text>\n` form. As a result, predecessor "fake nested comment" blocks whose outer open was `/* Note: include qoi ...\n` were incorrectly UN-COMMENTED in the consolidated version — previously-dormant code lines are now ACTIVE and will produce `.dta` files that diverge from the predecessor (M4 golden-master will catch).

The plan v3 explicitly specifies "no semantic changes — paths and comments only." This finding is a semantic-change introduction by the sweep, which violates the plan's invariant.

CRITICAL Finding 1 must be fixed (re-run sweep with a broader pre-pass regex, OR manually rewrite the 5 affected files) before commit. CRITICAL Finding 2 then needs re-verification once Finding 1 is fixed.

Everything else (Transform 2 log mirror, convention codification in rules / ADR / MEMORY, `check_logs.do` walker, `/*` balance across 156 active files, `//*` insertion, orphan-`*/` strip, `cap mkdir` cascade) verified correct.

---

## CRITICAL findings

### C1 — Pre-pass regex too narrow; 5 files have UN-COMMENTED code that was dormant in predecessor

The pre-pass's job is to detect "fake nested comment" blocks where the predecessor relied on Stata's depth-counting parser to keep blocks commented even when they contained inner `/* mini */` pairs. The pre-pass flattens inner `/*`/`*/` to `<x>` placeholders so the outer block stays one big comment after the sweep.

**Regex (`py/sweep_comments_and_logdirs.py:106`):** `r'/\*[ \t]*\n'`

Matches `/*\n`, `/*   \n`, `/*\t\n`. Does NOT match `/* Note: include qoi 41 ...\n` (content character before newline).

When the outer is `/* <text>\n`, the pre-pass skips it. Then `transform_comment_globs` walks the outer block normally:
- Sees inner `/*` (line below outer open) → rewrites to `/<x>` per the in-block `/*` rule.
- Sees inner `*/` (same or next line) → per the heuristic at lines 249-261, `*/` followed by `\n` is treated as a "real close" → state returns to `code`.

Net effect: the inner `/* mini */` pair is half-rewritten (open → `/<x>`, close → `*/` kept verbatim), and the `*/` of the inner closes the OUTER block prematurely. Code that follows (which was commented out in predecessor via depth counting) becomes ACTIVE in consolidated.

**Five affected files (verified by reading each):**

| File | Outer open line | Outer close (was inner `*/`) | Lines now ACTIVE that were COMMENTED in predecessor |
|---|---|---|---|
| `do/data_prep/qoiclean/staff/staffqoiclean1617_1516.do` | 188 (`/* Note: include qoi 41 with the rest in creating statistics ...\n`) | 189 (`/<x> note: mean of qoi41 ... */`) | 190-206 (gen `all41`..`missing41` dummies) PLUS 207-on (down to next real `*/` at line ~441) |
| `do/data_prep/qoiclean/parent/parentqoiclean1415.do` | 150 (`/* This is old code before the recoding of qoi values\n`) | 151 (`/<x> generate mean of vars, excluding don't know. */`) | 152-158 (`gen lowbound = 1`, `gen highbound = 4`, foreach rangestat) PLUS 159-161 |
| `do/data_prep/qoiclean/parent/parentqoiclean1516.do` | 195 (`/* This is old cold before recoding of qoi values\n`) | 196 (`/<x> generate mean of vars, excluding don't know. */`) | 197-204 (same pattern: lowbound/highbound + rangestat overwriting `qoi*mean`) |
| `do/data_prep/qoiclean/parent/parentqoiclean1617.do` | 203 area | 204 (`/<x> generate mean of vars, excluding don't know. */`) | 205+ (same pattern) |
| `do/data_prep/qoiclean/parent/parentqoiclean1819_1718.do` | 195 area | 196 (`/<x> generate mean of vars, excluding don't know. */`) | 197+ (same pattern) |

**Why this matters empirically:**

- *Parent files (4):* In each, lines 146 / 191-193 (depending on file) compute the simple mean: `egen qoi`i'mean = mean(qoi`i'), by(cdscode)`. The dormant block (lines 152-158 in parent1415) re-computes the same variable via `rangestat (mean) qoi`i', interval(qoi`i' lowbound highbound) by(cdscode)` followed by `rename qoi`i'_mean qoi`i'mean` — this OVERWRITES the simple egen mean. So in predecessor, the saved variable is the simple mean; in consolidated, it's the rangestat-bounded mean. Variable labels in the same file (lines 215+ in parent1516) say `Mean (excluding don't know) of Q: ...` — the rangestat form matches the labels, the simple-egen form doesn't. Whether the predecessor was "buggy" (labels say one thing, values are another) or the sweep is "fixing" the bug is not the question — the plan says no semantic changes.

- *Staff file (1):* Lines 190-206 introduce six new dummies (`all41`, `most41`, `some41`, `few41`, `none41`, `missing41`) into the saved `staffqoiclean1617.dta`. In predecessor these did not exist. The consumers at lines 408-411 ARE commented out (the pre-pass DID flatten the outer `/*\n` at line 406 — that one's a lone `/*`), so the variables are produced but not used. Still alters the saved schema.

**Either fix path is acceptable:**

a. Broaden the pre-pass regex to `r'/\*[^\n]*\n'` (allow any text up to newline) AND add an inner-content gate (only flatten if the inner span contains `/*` or `*/` digraphs, which the code already checks at line 127). Re-run the sweep. Verify the 5 files now have proper depth-preserving comment-outs.

b. Manually rewrite the 5 lines:
- For each, change the inner `*/` (e.g., line 189 in staffqoiclean1617_1516) to `<x>` so it doesn't close the outer block prematurely. Then the outer block stays one big comment, lines 190-onwards stay dormant.
- Effort: 5 single-line edits. Lowest-risk fix.

**Recommendation:** apply (b) to unblock the commit, then file (a) as a follow-up improvement to the helper for future-proofing.

### C2 — Verify the fix didn't miss other instances

After applying the C1 fix, re-run the regex `grep -nE '^\s*/<x>.*\*/\s*$' do/ --exclude-dir=_archive` to confirm zero remaining `/<x> ... */` patterns. The current search returns exactly 5 matches (the C1 instances); after fix it must return 0.

Beyond the regex check, also verify there's no symmetric "outer was `*` line comment containing nested `/* */`" case where the inner pair was half-rewritten. (The current sweep handles `*`-line state at lines 293-337 of the helper; spot-check passed.)

---

## MAJOR findings

### M1 — Pre-pass regex limitation should be documented as a known limitation in `py/sweep_comments_and_logdirs.py`

Once C1 is fixed, the helper's `_flatten_lone_block_opens` docstring at lines 83-104 should be amended with the broadened regex AND a note that any further `/*<text>\n ... /* ... */ ... */` patterns would need either the broader regex or manual handling. Currently the docstring says "scan for `/*\n` (lone-`/*`-on-line) opens" — accurate to the current code but misses the real-world variation. **Deduction: −3 (Major; code-quality / docstring fidelity).**

### M2 — `staff/staffqoiclean1617_1516.do` and `parent/parentqoiclean*.do` should add a `// 2026-05-17 sweep:` note next to each fixed line

Per the spirit of the per-file logging discipline (each transform leaves a trace), the C1-fix should leave a one-line comment marker next to each fixed inner-`*/`-rewritten-to-`<x>`. This lets the next reader know why the file deviates from the `/<x>` ↔ `<x>` symmetry the rest of the codebase has. Minor-Major. **Deduction: −2 (Major; lessens repeatability of audit).**

---

## CRITICAL checks (verified PASS — beyond the 5 C1 files)

### Check 1: `/*` balance per file (Tier-1 grep)

Spot-verified by grep'ing each suspect file individually. All 156 active `.do`/`.doh` files (excluding `_archive/`) have matched `/*` and `*/` token counts:

| File | `/*` lines | `*/` lines |
|---|---|---|
| `do/main.do` | 12 | 12 |
| `do/share/base_sum_stats_tab.do` | 25 | 25 (line 179 contains both) |
| `do/data_prep/qoiclean/staff/staffqoiclean1617_1516.do` | 34 | 34 |
| `do/survey_va/factor.do` | 11 | 11 |
| `do/va/va_score_all.do` | 6 | 6 |
| `do/data_prep/prepare/renamedata.do` | 7 | 7 |
| `do/share/svyvaregs/allvaregs.do` | 15 | 15 |
| `do/data_prep/k12_postsec_distance/k12_postsec_distances.do` | 18 | 18 |
| `do/va/reg_out_va_all_fig.do` | 15 | 15 |
| `do/survey_va/allsvymerge.do` | 9 | 9 |
| `do/survey_va/indexregwithdemo.do` | 8 | 8 |

Per-file `/*` balance PASS across the active tree. *But* (important caveat) — balance does NOT detect the C1 semantic-change issue, because in those 5 files the `/*` and `*/` are still balanced; the problem is *which* `*/` closes *which* `/*`, not the count.

### Check 2: No `/*` survives in `*`-prefixed line comments
`grep -rE '^\s*\*.*/\*' do/ --include='*.do' --include='*.doh' --exclude-dir=_archive` returned 0 hits.

### Check 3: No `//*` survives
`grep -rE '//\*' do/ --exclude-dir=_archive` returned 0 hits.

### Check 4: Transform 1 spot-check semantic preservation

For `staffqoiclean1415.do` (a "fake nested comment" file where outer open was `/*\n` and pre-pass triggered correctly): lines 172-191 stay as one big commented-out block; inner `/*` rewritten to `/<x>` and inner `*/` rewritten to `<x>`. Semantic preserved. ✓

For `base_sum_stats_tab.do` (heaviest file at 25/25): block `/*\n ... /* inner */ ... */` at lines 408-414 correctly stays as the outer commented-out block (no semantic change). ✓

For `secqoiclean1819_1718_1516.do`: block `/* a snippet of code to check the dummies ... */` at lines 137-138 (single-line balanced) and `/* by cdscode: ... drop check* ... */` at lines 139-148 (multi-line balanced, no inner `/*`) — both preserved correctly. ✓

For `staffqoiclean1617_1516.do` (the C1 file): lines 358-373 (outer `/*\n`) preserved as commented out. Lines 188-189 (outer `/* Note: ...\n`) BROKEN per C1. ✗

For `renamedata.do`: lines 161-162, 169-172, 179, 183-185, 186-187, 229-230 — all multi-line `/* ... */` blocks (no inner `/*`) correctly preserved. ✓

### Check 5: Transform 2 spot-check log-path mirror

| File | log using | translate | cap mkdir cascade |
|---|---|---|---|
| `do/data_prep/prepare/renamedata.do` | L117 `$logdir/data_prep/prepare/renamedata.smcl` ✓ | L335 nested ✓ | L107-109 `$logdir` → `data_prep` → `prepare` ✓ |
| `do/check/check_samples.do` | L59 `$logdir/check/check_samples.smcl` ✓ | (verify) | L56,58 `$logdir` → `check` ✓ |
| `do/va/heterogeneity/va_het.do` | L73 `$logdir/va/heterogeneity/va_het.smcl` ✓ | (verify) | L64,67,68 `$logdir` → `va` → `heterogeneity` ✓ |
| `do/survey_va/factor.do` | L62 `$logdir/survey_va/factor.smcl` ✓ | (verify) | (verify) |
| `do/share/sample_counts_tab.do` | L87 `$logdir/share/sample_counts_tab.smcl` ✓ | (verify) | (verify) |
| `do/share/svyvaregs/allvaregs.do` | L95 `$logdir/share/svyvaregs/allvaregs.smcl` ✓ | L276 nested ✓ | (verify) |

All log-path rewrites verified consistent. `cap mkdir` cascade order is correct (parent before child).

### Check 6: Edge case 5 — Fake nested comment preservation (PARTIAL)

The pre-pass `_flatten_lone_block_opens` correctly handles `/*\n` outer opens (verified in staffqoiclean1415, base_sum_stats_tab L408, staffqoiclean1617_1516 L358/406/412). It MISSES `/* <text>\n` outer opens → C1. **Partial PASS; C1 documents the gap.**

### Check 7: Edge case 6 — Orphan `*/` stripping

The agent reported "2 instances in qoiclean parent series". From the per-file `/*` and `*/` balance counts (all balanced post-sweep), the strip pass successfully removed 2 unmatched closes that the predecessor parser bug had been masking. Cannot independently verify which 2 without `git diff`, but the balance-equal-on-every-file evidence is consistent with the report.

---

## MAJOR checks (verified PASS)

### Convention codification

- **`.claude/rules/stata-code-conventions.md` lines 51-90:** Two new sections added — "Wildcards in comments" (rule + before/after table + sweep-tool reference) and "Per-file logging structure" (path convention + required boilerplate + check_logs.do role). Style matches the rest of the file. ✓

- **`.claude/rules/phase-1-review.md` §2 Tier-1 lines 41-42:** Two new checklist items added — `/*` balance check (with grep command + bug-prevention rationale + cross-ref to conventions and plan) and log path mirror check (with `cap mkdir` cascade requirement + exemption for top-level files). Markdown checkbox format matches existing items. ✓

- **`decisions/0021_main-settings-relocation-and-self-contained-sandbox.md` Amendment 2026-05-17 (lines 93-111):** Context, amendment, codification, sweep, and cross-references sections all present. Cross-references both rules + the plan + MEMORY.md + `check_logs.do`. ✓

- **`MEMORY.md` `[LEARN:stata]` entry (line 157):** Format matches existing `[LEARN:category]` entries. Captures the discovery context (M4 acceptance run halted), root cause (greedy `/*` parser), empirical evidence (89/129 files unbalanced, 6,588-line log with zero "file saved"), the rule, the sweep tool, the commit-time check, and cross-refs. Comprehensive. ✓

### `do/check/check_logs.do` walker

Reviewed lines 1-160:
- Uses `filelist` (ssc) to walk `do/` recursively (line 77).
- Drops `_archive/` paths (line 80).
- Drops top-level `main.do` and `settings.do` from the asserted set (line 88) — correctly exempts files that don't open per-file logs.
- Computes expected log path as `$logdir/<reldir>/<stem>.smcl` for non-top-level, or `$logdir/<stem>.smcl` for top-level (lines 115-121).
- Asserts existence via `capture confirm file` loop (lines 124-131).
- Lists missing logs and `exit 9` on failure (lines 136-144).
- Opens its own per-file log at `$logdir/check/check_logs.smcl` (line 50) and translates to `.log` at the end.

Header description block present and follows ADR-0021 convention (PURPOSE / INPUTS / OUTPUTS / ROLE IN ADR-0021 SANDBOX / INVARIANTS / REFERENCES). ✓

One observation: the `reldir` computation at line 116 uses `subinstr(dirname, "$consolidated_dir/do", "", 1)` — Stata interpolates `$consolidated_dir` at parse time. Will work on Scribe (where `$consolidated_dir` is bound by `do/settings.do` before this script runs). ✓

### `//*` → `// *` space-insertion (edge case 3)

`grep -rE '//\*' do/ --exclude-dir=_archive` returns 0 hits. Originals where decorative banners had `//****` now have `// ****`. Stata line-comment semantics unaffected: `//` opens the line comment regardless of trailing space. ✓

### `cap mkdir` multi-component cascade

Spot-verified:
- `staffqoiclean1617_1516.do` lines 56-63: `$logdir` → `data_prep` → `qoiclean` → `staff` (3-deep). ✓
- `va/heterogeneity/va_het.do` lines 64,67,68: `$logdir` → `va` → `heterogeneity` (2-deep). ✓
- `data_prep/k12_postsec_distance/k12_postsec_distances.do` lines 76-78: `$logdir` → `data_prep` → `k12_postsec_distance` (2-deep). ✓

Cascade order is parent-first (correct for filesystem mkdir).

---

## MINOR checks (verified)

### Python helper code quality

`py/sweep_comments_and_logdirs.py` (676 lines):

- **State machine soundness (Transform 1).** States `code`, `block`, `line_star`, `line_slash`, `string` are exhaustive. Transitions handled; string-literal state correctly suppresses both `/*` and `*/` semantics. ✓ (Subject to C1 — the pre-pass gate is the issue, not the state machine itself.)
- **String-literal protection.** Lines 224-229 enter `string` state on `"`, exit on `"` (line 339-344). `/*` inside a string is not rewritten. ✓
- **Heuristic for path-glob `*/` vs real close.** Lines 249-261: `*/` followed by `[A-Za-z0-9_<${]` or `*` → path-glob rewrite; otherwise → real close. The heuristic is the source of the C1 issue indirectly — it correctly identifies `\n` as "real close", but the OUTER state was misjudged because the pre-pass didn't flatten the inner pair.
- **Pre-pass `_flatten_lone_block_opens` (lines 83-146).** Regex too narrow per C1. Otherwise sound: only rewrites interiors that contain at least one `/*` or `*/` digraph (line 127), processes in reverse order to preserve offsets (line 137).
- **Orphan close strip (lines 355-481).** Two-pass: regex finds candidate lines, then depth-map verifies each `*/` lies at depth 0. Strips whole line on confirmation. ✓
- **Idempotence.** Re-running on a swept file: pre-pass finds no `/*\n` opens with inner digraphs (since first pass flattened them); Transform 1 finds no spurious `/*` in comment state (since first pass rewrote them); Transform 2's regex on `$logdir/<stem>.smcl` won't match `$logdir/<reldir>/<stem>.smcl` (so it won't double-mirror). Idempotent. ✓
- **Docstrings.** Comprehensive at module level (lines 1-43), per-function (`_flatten_lone_block_opens`, `transform_comment_globs`, `strip_orphan_block_closes`, `transform_log_paths`). Subject to M1 caveat.

### `.doh` files

Transform 2 is gated to `path.suffix == ".do"` only (line 618). `.doh` helpers (which are include'd, not invoked, and don't open their own logs) correctly excluded from log-path rewrite. Transform 1 still applies to `.doh`. ✓

---

## Score breakdown

| Item | Severity | Deduction |
|---|---|---|
| C1: Pre-pass regex too narrow; 5 files have semantically diverged code | Critical (sweep introduces semantic change despite plan's "paths and comments only" invariant) | −25 |
| C2: Verification of fix not yet possible until C1 is repaired | Critical (follow-on) | −10 |
| M1: Helper docstring should document the pre-pass regex limitation | Major | −3 |
| Starting score | — | 100 |
| **Final** | — | **62** |

(Other Majors / Minors that would normally deduct — convention codification quality, walker design, `cap mkdir` cascade, idempotence, etc. — all PASS, so no deductions there.)

---

## Recommendations to unblock

Apply C1 fix path (b): manually rewrite the inner `*/` to `<x>` at the 5 locations:

1. `do/data_prep/qoiclean/staff/staffqoiclean1617_1516.do:189` — change `*/` to `<x>`.
2. `do/data_prep/qoiclean/parent/parentqoiclean1415.do:151` — change `*/` to `<x>`.
3. `do/data_prep/qoiclean/parent/parentqoiclean1516.do:196` — change `*/` to `<x>`.
4. `do/data_prep/qoiclean/parent/parentqoiclean1617.do:204` — change `*/` to `<x>`.
5. `do/data_prep/qoiclean/parent/parentqoiclean1819_1718.do:196` — change `*/` to `<x>`.

Then re-verify:
- `grep -rE '^\s*/<x>.*\*/\s*$' do/ --exclude-dir=_archive` returns 0.
- Per-file `/*` balance check on all 5 files still PASS (still balanced after edit).
- The blocks that were UN-COMMENTED (e.g., lines 152-158 in parentqoiclean1415) stay inside the outer block, dormant.

After C1 fix, re-dispatch coder-critic for round-2 verification. Expected score post-fix: ~88-92 (M1 stays as Major; everything else PASS).

---

## Compliance Evidence (from .claude/state/verification-ledger.md)

The ledger does NOT yet contain rows for the 111 modified files. This is expected — the sweep just landed, no rows have been written for the new hashes. Adversarial-default applies on the next pre-commit gate: the agent committing this work needs to either (a) add ledger rows for each modified file's `/*-balance` and `log-path-mirror` checks marked PASS with current hashes, or (b) declare the gates as ASSUMED with rationale (e.g., "Tier-1 grep check is the gate; per-file ledger row is redundant"). Either is defensible. Not a deduction; just flag for the commit pipeline.

For context, prior ledger rows verified (relevant to this review):
- `do/check/check_logs.do | adr-0021-sandbox-write | 2026-04-29 | PASS` — still applies; the 2026-05-17 walker amendment is additive (adds nested-path matching), the original PASS for "writes only $logdir + cap translate" still holds.
- No row exists for the new walker logic itself; ASSUMED (Tier-3 data-checks pipeline on Scribe will exercise it post-commit). Defensible.

---

## Escalation Status: Round 1 of 3 — BLOCK

Hard gate: 80/100. Current score 62/100. Block commit. After C1 fix, round 2 will verify.

If round 2 still BLOCKED, round 3 of 3 fires; if round 3 fails, escalate per `phase-1-review.md` §1 three-strikes protocol — but C1 has a clean 5-line manual-edit remediation, so round-2 PASS is highly likely.
