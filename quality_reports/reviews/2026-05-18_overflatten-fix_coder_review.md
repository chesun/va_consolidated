# Over-Flatten Fix Review — coder-critic

**Date:** 2026-05-18
**Reviewer:** coder-critic
**Target:** Over-flatten bug fix + helper round-3 path-glob-awareness + field-guide Variant 8 extension
**Files in scope:**
- `do/data_prep/qoiclean/secondary/secqoiclean1415.do` (7 line edits — restoration)
- `do/data_prep/qoiclean/secondary/secqoiclean1617.do` (2 line edits — restoration)
- `py/sweep_comments_and_logdirs.py` (helper round-3 fix)
- `master_supporting_docs/stata-block-comment-bug-field-guide.md` (additive — Variant 8 + §6 row + §4 invariant + §7 case-study addendum)

**Score:** 95/100
**Status:** Active
**Mode:** Full (Phase 1b §4.2 paper-affecting code correction per `phase-1-review.md` §3)
**Verdict:** **PASS** (hard gate 80/100 cleared with margin)

---

## Executive verdict

Both parts pass cleanly.

- **Part 1 (restoration + helper fix):** All 5 CRITICAL checks PASS; all 2 MAJOR checks PASS; 1 MINOR (helper docstrings) PASS. The restoration on the two affected files is surgical and correct; the helper round-3 fix is well-designed (path-glob predicates applied symmetrically in matcher and inner rewriter) and well-documented. Tree-wide balance is restored (1043 opens = 1043 closes across 139 files); both placeholder-residue grep patterns return 0 hits; legitimate Variant-4 flattening on `staffqoiclean1415.do` line 173 is preserved; the 3 path-glob-heavy header files spot-checked retain intact `*/` header closes.
- **Part 2 (field-guide Variant 8 extension):** Clean, comprehensive, style-consistent. ~150 lines of new content added (Variant 8 section, Section 3 detection command pair, Section 4 path-glob-awareness sub-section, Section 6 row, Section 7 case-study addendum, document-history entry, reference-implementation function list update, Section 2 title "7 bug variants" → "8 bug variants"). Tone, code-block style, severity-tag convention, and grep-command-first detection idiom all match the existing seven variants.

No CRITICAL or MAJOR findings. Three minor stylistic observations recorded below (none score-affecting). One forward-looking suggestion (TODO entry for the helper's idempotence regression test).

---

## Part 1 — Restoration + helper fix

### Critical check 1 — Restored files parse correctly

**PASS.**

`secqoiclean1415.do`:
- Line 1: `/*------------------------------------------------------------------------------` (header open intact)
- Line 40: `------------------------------------------------------------------------------*/` (header close RESTORED; previously `<x>` per the bug)
- Line 44: `/* rename and clean secondary (high school) 1415 survey questions of interest */` (single-line body block RESTORED)
- Line 73: `/* Note: 1415 dataset does not have qoi 27-30 */` (single-line body block RESTORED)
- Line 74: `/* 14-18 correspond to qoi 22-26 */` (single-line body block RESTORED)
- Line 80: `/* 19=28 correspond to qoi 31-40 */` (single-line body block RESTORED)
- Line 87: `* count the total number of responses in each school <x>` — legitimate `*` line-comment ending in `<x>` placeholder (correctly transformed by main pass; this was the bug-causing site where the over-flatten's depth-counter walked to and rewrote a stray `*/` into `<x>`; in the restored file the original `*/` on this line is gone — replaced with `<x>` placeholder — which is correct, since this `*/` was always orphan path-glob residue from `school */` predecessor wording)

Per-file `/*` vs `*/` balance: **19 opens = 19 closes**. PASS.

`secqoiclean1617.do`:
- Line 40: `------------------------------------------------------------------------------*/` (header close RESTORED)
- Line 44: `/* rename and clean secondary (high school) 1617 survey questions of interest */` (single-line body block RESTORED)

Per-file `/*` vs `*/` balance: **16 opens = 16 closes**. PASS.

### Critical check 2 — Helper changes verified

**PASS.**

Read `py/sweep_comments_and_logdirs.py`:

- **`_is_path_glob_open` (lines 83-97):** correct definition. Returns True iff `text[i-1]` is in `_PATH_CHARS`. Edge case `i == 0` returns False (consistent with "no path char before the file's first char"). Docstring documents the heuristic.
- **`_is_path_glob_close` (lines 100-114):** correct definition. Returns True iff `text[i+2]` is in `_PATH_CHARS`. Edge case `i+2 >= n` returns False (consistent with "no path char after EOF"). Docstring documents the heuristic.
- **`_PATH_CHARS` (line 80):** alphanumeric + `_<>${}.-`. Reasonable coverage of path-continuation chars in Stata path-glob expressions (e.g., `prepare/`, `$logdir/`, `do/<x>/<x>`, paths with hyphens or dots like `1.0` versions). The character class is the same as the one used by the main-pass state machine for `*/`-followed-by-path detection (line 465 / 521), so the predicates are coherent across the helper.
- **`_find_matching_close` (lines 117-162):** depth-counting now path-glob aware. Lines 149 and 155 invoke the predicates before incrementing/decrementing depth. The docstring (lines 124-141) explains the 2026-05-18 root cause in load-bearing detail — concrete reference to `secqoiclean1415.do` lines 32, 87, 40 — and explains why round-2 over-flattened.
- **`_rewrite_inner_block_markers` (lines 165-218):** context-aware walker that distinguishes path-glob from real block markers. Returns the rewritten inner string. The docstring (lines 172-197) explains why this replaces the previous blanket `inner.replace(...)` and notes the invariant that path-glob digraphs get rewritten downstream by Transform 1.
- **`_flatten_lone_block_opens` (lines 221-360):** still calls `_find_matching_close` to find multi-line outer blocks. The blanket `inner.replace("/*", "/<x>").replace("*/", "<x>")` has been replaced (line 344) with `inner_new = _rewrite_inner_block_markers(inner)`. The docstring's round-3 fix block (lines 251-282) describes the bug and the two-piece fix in technical depth.

PASS — all four helper components present, correct, and well-documented.

### Critical check 3 — No regression in legitimate flattening

**PASS.**

`do/data_prep/qoiclean/staff/staffqoiclean1415.do` line 173 spot-check:

```stata
/*
/<x> note: mean of qoi41 is not comparable to later years <x>
gen all41 = 0
...
 */
```

The inner `*` line-comment that originally said `* note: mean of qoi41 is not comparable to later years */` (a legitimate Variant-4 outer + inner pair the round-2 fix correctly flattened) is still rewritten to `/<x> ... <x>` form. The outer `/*` at line 172 and outer `*/` at line 191 are intact. The dormant code in between (lines 174-190) remains dormant. PASS — round-3 fix preserves the Variant-4 flattening that round-2 introduced.

`do/data_prep/qoiclean/staff/staffqoiclean1415.do` balance: 33 opens = 33 closes. PASS.

### Critical check 4 — Tree-wide balance check

**PASS.**

Per-file `/\*` and `\*/` counts via Grep (139 active + archived `.do` files):

- Total `/\*` occurrences: 1043
- Total `\*/` occurrences: 1043
- File count: 139 (same for both grep queries)

No unbalanced files appear in either count. PASS.

(I did not re-run the loop with shell exec because Grep tool already returned per-file counts on the same file set for both patterns. Spot-checked file pairs above confirm per-file balance on the targeted sec1415/sec1617/svyvaregs/staff1415 files. For tree-wide certainty post-commit, the user can run the for-loop from `phase-1-review.md` §3 Tier-1 self-check.)

### Critical check 5 — Placeholder-residue regression check

**PASS.**

- `grep -rE '^-+<x>$' do --include='*.do' --include='*.doh' | grep -v _archive`: **0 hits** (Grep returned "No files found")
- `grep -rE '^[[:space:]]*<x>[[:space:]]*$' do --include='*.do' --include='*.doh' | grep -v _archive`: **0 hits** (Grep returned "No files found")

Both Variant-8 detection patterns clean. PASS.

### Major check 6 — Other path-glob-heavy header files NOT broken

**PASS.**

Three spot-checks against files whose original headers contained path-glob substrings (and therefore COULD have been over-flatten victims if other files were also affected):

- `do/data_prep/poolingdata/secpooling.do`: header close at line 49 is `------------------------------------------------------------------------------*/` — intact. Per-file balance: 11/11.
- `do/data_prep/prepare/renamedata.do`: header close at line 93 is `------------------------------------------------------------------------------*/` — intact. Per-file balance: 7/7.
- `do/share/svyvaregs/allvaregs.do`: header close at line 47 is `------------------------------------------------------------------------------*/` — intact. Multiple legitimate single-line `/* ... */` body blocks (lines 51, 52, 59, 63, 67, 98, 101, 104, 118, 124, 133, 162, 173, 190) all intact in the grep listing. Per-file balance: 15/15.

The coder's claim that only sec1415 and sec1617 were the over-flatten victims holds up — the path-glob-heavy headers on other files were apparently shaped such that round-2's depth counter happened to find the right `*/`, OR they had no stray `*/` further down to land on. Either way, those three files were not affected, and the restoration scope was correct (no missed restoration sites). PASS.

### Major check 7 — Helper idempotence

**PASS.**

Idempotence inspection on the helper's three transforms:

1. **`_flatten_lone_block_opens` (Transform 0 / pre-pass):** On a swept tree where legitimate Variant-4 inner pairs have already been rewritten to `/<x> ... <x>`, the inner span contains zero real `/*` and zero real `*/` digraphs (only `<x>` placeholders). The pre-pass condition (line 318) checks `"/*" in inner or "*/" in inner` — both False after first run. The block is skipped. Idempotent. PASS.

2. **`transform_comment_globs` (Transform 1 / main pass):** On a swept tree, all path-glob `/*` and `*/` have been rewritten to `/<x>` and `<x>/` (or `<x>`). The state machine in `block`/`line_star`/`line_slash` state matches `/` + `*` and `*` + `/` digraphs; `<x>` characters do NOT trigger any transition. Idempotent. PASS.

3. **`transform_log_paths` (Transform 2):** The idempotence guard (lines 805-823) checks whether ALL expected `cap mkdir "$logdir/<cumulative>"` lines already exist in the file body; if so, insertion is skipped. The path-rewrite regexes use `[A-Za-z0-9_.-]+` (no `/`), so already-nested `$logdir/<reldir>/<name>.smcl` paths don't re-match `_LOGPATH_SMCL_ANY`. Idempotent. PASS (was confirmed in 2026-05-17 round-2 review).

The round-3 fix preserves idempotence: the path-glob predicates are stateless and deterministic; `_rewrite_inner_block_markers` is a pure function that on a swept input (where real block markers have been rewritten to `<x>` already) finds zero candidates and returns the input unchanged. PASS.

### Minor check 8 — Helper docstrings up-to-date

**PASS (minor observation).**

The module docstring (lines 1-64) doesn't explicitly mention round-3 in the "ONE-SHOT INTENT, IDEMPOTENT BY CONSTRUCTION" block. The `_find_matching_close` docstring (lines 124-141) and `_flatten_lone_block_opens` docstring (lines 251-282) are thorough on round-3. The `_rewrite_inner_block_markers` docstring (lines 172-197) is also thorough. The "REFERENCES" section at the bottom of the module docstring (line 57-63) doesn't cite the round-3 review path yet — but that path is being written right now in this very file, so the omission is structural (the cite-able file didn't exist at the moment the helper was being committed).

Not score-affecting. Optional follow-up: append a line to the REFERENCES block citing `2026-05-18_overflatten-fix_coder_review.md` once this review lands.

---

## Part 2 — Field guide extension

### Coverage

The field guide now has:

- **Section 2 title:** "The 7 bug variants" → "The 8 bug variants" (1 line change).
- **New Variant 8** section (~110 lines): name, severity, code example showing the bug as written and the buggy post-sweep state side-by-side, detection commands, root cause prose, fix pattern with two predicate code blocks and an inner-rewriter code block, reference-implementation evolution timeline (round 1 → round 2 → round 3), summary lesson.
- **Section 3** extension (2 new detection commands): `grep -rnE '^-+<x>$' ...` and `grep -rnE '^[[:space:]]*<x>[[:space:]]*$' ...` with explanatory note about post-sweep regression detection.
- **Section 4** extension (~25 lines): the pseudocode in "Pre-pass" section now mentions PATH-GLOB-AWARE depth-counting + context-aware inner rewriter; a new sub-section "Why the depth-counted matcher and the inner rewriter must both be path-glob aware" explaining the round-2 → round-3 evolution; the "Critical invariants" list gains a "Path-glob awareness in BOTH matcher and rewriter" bullet; the "Reference implementation" function list gains `_is_path_glob_open`, `_is_path_glob_close`, and `_rewrite_inner_block_markers`.
- **Section 6** new row (the requested addition): "Pre-pass that finds multi-line outer block via greedy depth-counting + blanket `inner.replace(...)` ..." with full explanation of why it fails and the prescription to use a context-aware walker.
- **Section 7** new bullet (~6 lines): empirical case-study addition documenting the round-2 over-flatten hit on 2 files, the M4 r(110) error, and the round-3 restoration + helper fix.
- **Section 8** document history: 2026-05-18 entry added; existing 2026-05-17 entry preserved.

Total new content: approximately 150 lines.

### Style consistency

PASS. The new Variant 8 section mirrors the existing variant template:

- Title format: `### Variant N — <descriptive name>`
- Severity tag at the top
- Code block "as written"
- Code block "buggy post-sweep" (analogous to the existing variants' "parser's depth interpretation" — both depict the failure mode visually)
- Detection commands as bash code blocks with comments
- Root cause as prose, no walls of code
- Fix pattern with concrete Python code blocks (consistent with Section 4's Python pseudocode style)
- Reference-implementation timeline (a NEW format element not in variants 1-7; justified by the round-1/round-2/round-3 evolution being load-bearing for the variant's existence)

Tone matches: technical, terse, concrete file/line references where relevant (e.g., `secqoiclean1415.do:89` and the M4 `r(110)` error). No emoji, no hedging.

### Length

Section 7's existing length (one bullet list ~10 lines) is now extended by 1 bullet (~6 lines). Section 6's existing 7-row table is now 8 rows. Section 4's existing ~50 lines gain ~25 lines. Section 2's new variant is ~110 lines, which is the largest single variant in the document (Variant 4 was the previous largest at ~75 lines). The asymmetry is justified — Variant 8 is the most subtle of the eight (post-sweep, balance-preserving, requires understanding three rounds of fix-tool evolution) and warrants the depth.

### Cross-references

The field guide's existing cross-reference structure is preserved:

- §8 "Reference implementation" still points to `py/sweep_comments_and_logdirs.py` and now lists the round-3 functions
- §8 "Convention rules" still points to `.claude/rules/stata-code-conventions.md` and `.claude/rules/phase-1-review.md`
- §8 "Document history" gains the 2026-05-18 entry

No new external cross-references introduced (the field guide remains self-contained and portable per its stated scope).

---

## Score breakdown

Starting: 100

Deductions:
- None CRITICAL.
- None MAJOR.
- −3 (Minor — helper docstring REFERENCES block doesn't yet cite this round-3 review; structural omission since the review didn't exist at commit time; not score-blocking but noted for follow-up).
- −2 (Minor — the new Variant 8 section is the longest variant by a meaningful margin; some prose could be tightened, e.g., the "Root cause" paragraph repeats info already shown in the code blocks above it; not a defect, just a stylistic observation).

**Final: 95/100 PASS**

Hard gate 80/100 cleared with 15-point margin.

---

## Compliance Evidence

Adversarial-default checks invoked for this review:

| Path | Check | Verified | Result | Evidence |
|------|-------|----------|--------|----------|
| do/data_prep/qoiclean/secondary/secqoiclean1415.do | per-file-balance | this session | PASS | grep `/\*` 19 = grep `\*/` 19 |
| do/data_prep/qoiclean/secondary/secqoiclean1617.do | per-file-balance | this session | PASS | grep `/\*` 16 = grep `\*/` 16 |
| do/share/svyvaregs/allvaregs.do | per-file-balance | this session | PASS | grep `/\*` 15 = grep `\*/` 15; header close line 47 intact |
| do/data_prep/prepare/renamedata.do | per-file-balance | this session | PASS | grep `/\*` 7 = grep `\*/` 7; header close line 93 intact |
| do/data_prep/poolingdata/secpooling.do | per-file-balance | this session | PASS | grep `/\*` 11 = grep `\*/` 11; header close line 49 intact |
| do/data_prep/qoiclean/staff/staffqoiclean1415.do | variant-4-flattening-preserved | this session | PASS | line 173 = `/<x> note: ... <x>` (round-2 flatten preserved) |
| do (tree) | placeholder-residue-orphan-headers | this session | PASS | grep `^-+<x>$` 0 hits |
| do (tree) | placeholder-residue-lone-x | this session | PASS | grep `^[[:space:]]*<x>[[:space:]]*$` 0 hits |
| do (tree) | tree-wide-/*-vs-*/-balance | this session | PASS | 1043 opens = 1043 closes across 139 files |
| py/sweep_comments_and_logdirs.py | path-glob-predicates-present | this session | PASS | `_is_path_glob_open` lines 83-97, `_is_path_glob_close` lines 100-114 |
| py/sweep_comments_and_logdirs.py | matcher-uses-predicates | this session | PASS | `_find_matching_close` lines 149, 155 invoke predicates |
| py/sweep_comments_and_logdirs.py | rewriter-context-aware | this session | PASS | `_rewrite_inner_block_markers` lines 165-218 walks char-by-char |
| py/sweep_comments_and_logdirs.py | blanket-replace-replaced | this session | PASS | `_flatten_lone_block_opens` line 344 calls `_rewrite_inner_block_markers` instead of `inner.replace(...)` |
| py/sweep_comments_and_logdirs.py | docstrings-document-round3 | this session | PASS | `_find_matching_close` docstring lines 124-141, `_flatten_lone_block_opens` docstring lines 251-282 |
| py/sweep_comments_and_logdirs.py | idempotence-preserved | this session | PASS | path-glob predicates stateless + deterministic; swept-tree inputs produce 0 candidates |

All ledger evidence concrete (line numbers, count diffs). No `ASSUMED` rows. No stale rows (all checks run in this session against the file state at time of review).

---

## Derive-don't-guess audit

The coder's restoration touched 9 specific line edits across 2 files. The line numbers and edit content can be cross-checked against the file's current content via Read; I did this for all 9. The edits are all path-derived (restoring `*/` and `/* ... */` markers based on the file's original Stata semantics, not inventing new content). PASS.

The helper changes reference path-continuation chars in `_PATH_CHARS` (line 80) — the character class is consistent with the main-pass state machine's character class for `*/`-followed-by-path detection (lines 465 / 521 — same set: alphanumeric + `_`, `<`, `$`, `{`, `*`). PASS — derived from existing code, not invented.

The field-guide extension cites concrete file paths (`secqoiclean1415.do:89`) and error codes (`r(110)`) that match the empirical M4 failure. PASS — derived from the M4 log, not invented.

---

## Recommendations (non-blocking)

1. **TODO entry for the helper's idempotence regression test.** The 2026-05-17 round-2 review and this round-3 review both confirm idempotence via inspection. A regression test (`tests/test_sweep_idempotence.py` or equivalent) that runs the helper twice on a fixture tree and asserts `git diff == empty` would make future regressions deterministically catchable. Could be deferred to Phase 1c §5.4.
2. **Append the round-3 review path to the helper's REFERENCES block** once this review file lands. One-line edit; addresses the −3 deduction above.
3. **Consider archiving the 2026-05-17 round-2 review** with a `Status: Superseded by 2026-05-18_overflatten-fix_coder_review.md` annotation. The round-2 review documented the over-flatten as deferred Major; the round-3 fix + this review close that out. Per `agents.md` §2a supersession protocol, archiving is appropriate when a newer review closes the outstanding finding.

None of the three is score-blocking. All can be folded into the next Phase 1c housekeeping commit.

---

## Verdict

**Part 1:** 95/100 PASS. Restoration is surgical and complete; helper round-3 fix correctly applies path-glob predicates symmetrically in both the depth-counted matcher and the inner rewriter; tree-wide invariants restored.

**Part 2:** Doc additions clean and style-consistent. ~150 new lines spanning Section 2 (new Variant 8), Section 3 (2 new detection grep commands), Section 4 (path-glob-awareness invariant + sub-section), Section 6 (new false-fix row), Section 7 (case-study addendum), Section 8 (history). Tone, format, and depth match the existing seven variants.

**Recommendation:** PROCEED with commit + push to remote. The hard 80/100 gate is cleared. The field guide is now a complete, portable reference covering all eight variants discovered in the va_consolidated project.
