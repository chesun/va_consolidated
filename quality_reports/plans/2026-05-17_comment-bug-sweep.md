# Stata `/*` Block-Comment Bug Sweep + Log-Dir Mirror — Comprehensive Plan

**Status:** APPROVED v3 — Option B + log-dir mirror bundled; dispatching coder
**Date:** 2026-05-17 (revised, bundled log-dir transform)
**Authority:** ADR-0021 (description convention amended); `.claude/rules/stata-code-conventions.md` gets new rules; `.claude/rules/phase-1-review.md` gets new Tier-1 check items
**Trigger:** M4 acceptance run halted after Phase 1; `sec1415.dta` not produced. Root cause: Stata's parser counts `/*` opens greedily — `prepare/*` inside header description blocks creates unmatched opens, pushing the rest of the file into a runaway block comment.

**v3 addition** — bundle a structural improvement that's been wanted independently: **mirror the log directory structure to the do/ structure**. Currently all per-file logs land in a flat `$logdir/` (`log/`); want `do/<subdir>/<name>.do` → `log/<subdir>/<name>.smcl`. Same files touched as the `/*` sweep; both transforms run in the same Python helper.

---

## v2 changes (per Christina 2026-05-17)

- Drop Option C (single-line-inline-only `/* */` makes no sense — `*` and `//` already handle single-line).
- Drop `check_comments.do` runtime check. The invariant belongs at the agent/commit layer, not Stata runtime. By the time main.do runs, if the bug existed the pipeline already broke; the real correctness test is the full pipeline running clean (every file written, no errors).
- Coder-critic uses command-line tools (`grep -c '/\*'` vs `grep -c '\*/'`) for `/*` balance — invariant lives in the per-commit checklist.
- Naive sed won't work — fix tool must be context-aware (state-machine Python helper). See "Fix tool" section.

## v3 addition (per Christina 2026-05-17)

- Bundle log-directory mirroring with the `/*` sweep. Currently all per-file logs land in a flat `$logdir/`; want `do/<subdir>/<name>.do` → `log/<subdir>/<name>.smcl`. Mechanical transform on the same files.
- Three transforms per file: (1) `log using` path, (2) `translate` path, (3) `cap mkdir` block — need to ensure the parent subdir exists.
- `do/check/check_logs.do` walker updated to find logs at the new nested paths.

---

## Empirical evidence

1. **89 of 129 active `.do`/`.doh` files have unbalanced `/*` vs `*/` counts.** Top offenders: `staffqoiclean1617_1516.do` (40 opens / 39 closes), `base_sum_stats_tab.do` (39/25), `allvaregs.do` (29/15). Most files have ~10-20 spurious `/*` from path-glob descriptions.

2. **`renamedata.do` specifically**: 16 `/*` vs 7 `*/`. If Stata counts opens-minus-closes at end-of-file: depth = 9, meaning a large fraction of the file body sits inside an accidental block comment.

3. **Master log from 2026-05-17 acceptance run** (`log/main_17-May-2026_17-23-02.smcl`): shows every nested .do file being source-echoed (`>` prefix) and reporting "end of do-file", BUT zero "file saved" messages across 6,588 lines. No errors before `secqoiclean1415.do` halted at `sort cdscode: r(111)`. Consistent with: nested-do source was read but commands inside accidental block comments didn't execute.

4. **Per-file logs absent on Scribe**: each script's `log using "$logdir/<name>.smcl", replace text` should have created a per-file log. None exist. Consistent with: `log using` was inside an unintended block comment.

5. **Christina's IDE confirmation**: opened `renamedata.do` in the IDE; the entire body renders as commented out (IDE syntax highlighter agrees with the depth-9 calculation).

---

## Root cause

Two project conventions collided:

- **ADR-0021 description convention**: every relocated `.do` file carries a `/* ... */` header block documenting PURPOSE / INPUTS / OUTPUTS / RELOCATION / etc.
- **Path-glob notation in those headers**: write paths like `$logdir/*`, `$datadir_clean/calschls/secondary/<x>`, `prepare/*`, etc.

The `*` in `<path>/*` immediately follows a `/`, producing the character sequence `/*` — which Stata's parser detects as a block-comment open token regardless of context (i.e., even when already inside a `/* ... */` block).

Every `<path>/*` inside a header is an unmatched open. Multiplied across 89 files, runaway block comments hide ~70% of the consolidated pipeline's behavior.

This bug was latent throughout Phase 1a §3.3 because per-batch coder-critics never ran the relocated scripts standalone — they only checked path-repointing and chain coordination. The first end-to-end execution today exposed it.

---

## Chosen convention (Option B)

**Rule**: inside any Stata comment (any `/* ... */` block, any `*`-prefixed line, any `//`-prefixed line), `*` is NOT allowed as a path-glob wildcard. Use `<x>` (or `<file>`, `<filename>`) as the placeholder.

### Rationale for B over A

A alone doesn't fix the bug. The empirical evidence (main.do line 182 — a `*`-prefixed line containing `<sub>/*`) shows Stata's parser picks up `/*` inside line comments too. So Option A would need to ALSO change path-glob notation, making it Option A + B. Strictly more work than B alone.

B's marginal cost vs A+B: A+B additionally restructures header block comments to `*` line comments. The marginal safety benefit (prevents anyone in the future from writing `/* nested comment */` inside a header) is real but small — the new Tier-1 grep check on every commit catches recurrence regardless of which form headers use.

B preserves the visual scanability of `/* ===== HEADER ===== */` blocks. A header restructure can land as a Phase 1c §5.4 polish item independent of M4.

### Examples

| Before (bug pattern) | After (fixed) |
|---|---|
| `$logdir/*` | `$logdir/<x>` |
| `prepare/*` | `prepare/<x>` |
| `$projdir/dta/buildanalysisdata/<sub>/*` | `$projdir/dta/buildanalysisdata/<sub>/<x>` |
| `$datadir_clean/calschls/{a,b}/*` | `$datadir_clean/calschls/{a,b}/<x>` |
| Legitimate header open `/*----- HEADER -----` | (unchanged) |
| Legitimate inline `/* short note */` | (unchanged) |

---

## Plan structure

### Phase 1 — Convention codification

Update `.claude/rules/stata-code-conventions.md` with the new rule:

> Inside any Stata comment context (`/* ... */` block, `*`-prefixed line, `//`-prefixed line), do NOT use `*` as a path-glob wildcard. Use `<x>` or `<file>` placeholder notation. The character sequence `/*` is reserved for legitimate block-comment opens, since Stata's parser counts opens greedily and an extra `/*` inside a header creates a runaway nested block comment.

Update `.claude/rules/phase-1-review.md` §2 Tier-1 self-check with a new item:

> - [ ] **`/*` balance** — `grep -c '/\*' <file>` must equal `grep -c '\*/' <file>` for every modified .do/.doh file in the commit. Imbalance = runaway block comment bug.

Update ADR-0021 description convention to reference both rules.

Add a `[LEARN:stata]` entry to `MEMORY.md` capturing the 2026-05-17 discovery.

### Phase 2 — Fix tool: context-aware Python helper (does BOTH transforms)

Naive sed won't work — it would catch legitimate block-comment opens. The fix tool is a small Python helper at `py/sweep_comments_and_logdirs.py` that walks each file with a state machine and applies **two transforms**:

**Transform 1 — `/*` path-glob fix:**

```
state = "code" | "block_comment" | "line_comment_star" | "line_comment_slash"
when state == "code" and chars == "/*":
    state = "block_comment"; depth = 1; emit "/*"   # legitimate open
when state == "block_comment" and chars == "/*":
    emit "/<x>"   # SPURIOUS — inside existing block comment
when state == "block_comment" and chars == "*/":
    depth -= 1; if depth == 0: state = "code"; emit "*/"
when state == "line_comment_*" and chars == "/*":
    emit "/<x>"   # SPURIOUS — inside line comment
when state == "line_comment_*" and char == "\n":
    state = "code"; emit "\n"
otherwise:
    emit char
```

**Transform 2 — log directory mirror:**

For each `.do` file at relative path `do/<reldir>/<name>.do`:

1. Find `log using "$logdir/<name>.smcl", replace text` → rewrite to `log using "$logdir/<reldir>/<name>.smcl", replace text`. (Note: header description block references to `$logdir/<name>.smcl` should also be updated for consistency.)
2. Find `translate "$logdir/<name>.smcl" "$logdir/<name>.log", replace` → rewrite to `translate "$logdir/<reldir>/<name>.smcl" "$logdir/<reldir>/<name>.log", replace`.
3. Find the existing `cap mkdir "$logdir"` block and add a sibling `cap mkdir "$logdir/<reldir>"` line (one per parent path component if `<reldir>` is multi-level, e.g., `data_prep/prepare` needs `cap mkdir "$logdir/data_prep"` then `cap mkdir "$logdir/data_prep/prepare"`).

Edge cases:
- `do/main.do` is at top level — its log goes to `$logdir/main_<stamp>.smcl` (unchanged; no subdir).
- `do/settings.do` doesn't open a log (unchanged).
- `.doh` helper files are include'd, not invoked directly, and typically don't open their own logs (no transform needed unless they do).

The helper runs once across all active `.do`/`.doh` files (excluding `_archive/`). Both transforms apply. Each spurious `/*` becomes `/<x>`. Log paths get the subdir prefix. Legitimate opens preserved.

### Phase 2.5 — Update `check_logs.do`

`do/check/check_logs.do` uses the `filelist` package to walk `do/` and asserts each .do has a matching log under `$logdir/`. With nested log paths, it needs to walk `$logdir/<subdir>/` recursively and match by relative path.

Pseudocode for the updated assert:
```
foreach d in <every active .do under do/>:
    reldir = subdir(d, "do/")
    expected_log = $logdir/reldir/basename(d) - ".do" + ".log"
    assert file exists expected_log
```

### Phase 3 — Sweep dispatch

1. **Coder writes the Python helper** + runs it across the active tree. Produces a single bundled diff across the 89 affected files.
2. **Coder-critic reviews the helper + the resulting diff**: confirms `grep -c '/\*' = grep -c '\*/'` per file (balanced); spot-checks 5 random files for semantic preservation; confirms no legitimate block-comment opens were rewritten.

### Phase 4 — DROPPED — no runtime invariant check

Original plan had `check_comments.do` as a Stata-runtime invariant. Christina (2026-05-17): "the check comments do file sounds useless. the better test is whether every file is written and whether the entire pipeline runs bug free. the coder critic can use command line tools to check for /* balance".

Replaced by:
- **Commit-time check** via the new Tier-1 item in `phase-1-review.md` (added in Phase 1 above)
- **Runtime check** via the existing `check_logs.do` invariant which asserts every relocated .do produced a log — this already catches the runaway-comment-bug indirectly (a script eaten by a block comment produces no log)
- **Integration test** via the actual main.do acceptance run (Phase 6 below); a comment-bugged script produces no outputs, which the pipeline-level diff in M4 golden-master would catch

### Phase 5 — Standalone test on Scribe

Have Christina run `renamedata.do` standalone on Scribe:
- `cd /home/research/ca_ed_lab/projects/common_core_va/consolidated`
- `stata-mp -b do do/data_prep/prepare/renamedata.do`
- Confirm `log/renamedata.smcl` is created
- Confirm `data/cleaned/calschls/secondary/sec1415.dta` is created
- If both, hypothesis confirmed and fix worked

### Phase 6 — Re-run M4 acceptance

With `m4_acceptance_run = 1` (verify line ~115 of `do/main.do` is flipped this time):

```
screen -S consolidated_m4  # or nohup
cd /home/research/ca_ed_lab/projects/common_core_va/consolidated
stata-mp -b do do/main.do
```

Monitor `log/main_*.smcl` (will be a new timestamp). Expect Phase 1 to produce ~50+ .dta files in `data/cleaned/`, Phase 5 to produce survey-VA outputs, Phase 6 to produce paper tables/figures, Phase 7 to fire the 6 data checks.

### Phase 7 — Re-run M4 golden-master

After main.do finishes, with the consolidated pipeline's outputs now in place:
- Set `tier_filter = "smoke"` in `do/check/m4_golden_master.do` line 380
- `stata-mp -b do do/check/m4_golden_master.do`
- Pull `output/m4_diff_summary.txt` back
- Expect 5 PASS rows (or FAIL rows with tolerance-comparable magnitudes — review and triage)

Then paper tier, then full tier per protocol.

---

## Agent dispatch sequence

1. **Coder** (convention update + helper + sweep): writes the Python helper at `do/check/fix_glob_comments.py`, runs it across the active tree, applies the convention update to `.claude/rules/stata-code-conventions.md` + `.claude/rules/phase-1-review.md` §2 + ADR-0021 + `MEMORY.md` `[LEARN:stata]` entry. Single bundled commit.
2. **Coder-critic**: verifies `grep -c '/\*' == grep -c '\*/'` per file across the 89 affected files; spot-checks 5 random files for semantic preservation; confirms no legitimate block-comment opens were rewritten; reviews the convention update for accuracy.
3. **Commit + push** the bundle.
4. **Christina syncs to Scribe + runs Phase 5 standalone test.**
5. **If Phase 5 PASSES**, Christina proceeds to Phase 6 (full main.do) and Phase 7 (M4 smoke).

---

## Risk mitigations

- **Risk**: sweep introduces a subtle regression somewhere. **Mitigation**: Phase 5 standalone test on a representative file (renamedata.do) before committing to the multi-hour main.do run. Each fixed file's RELOCATION HISTORY block still documents predecessor↔consolidated path mapping intact; semantic equivalence is verifiable by `git diff` review.
- **Risk**: the diagnosis is wrong; Stata's parser doesn't actually nest, and the bug is elsewhere. **Mitigation**: Phase 5 verifies — if renamedata.do still fails after the sweep, we know the hypothesis was wrong and we revisit. Cheap test.
- **Risk**: more bugs in Phase 2/3 of main.do that we haven't seen because Phase 1 halted. **Mitigation**: Phase 6 surfaces them; iterate as needed.
- **Risk**: future authors re-introduce the bug. **Mitigation**: Phase 4 invariant check + the convention rule in stata-code-conventions.md.

---

## Cross-references

- ADR-0021: main + settings relocation + self-contained sandbox + description convention
- `.claude/rules/stata-code-conventions.md`: convention rules (to be updated)
- `.claude/rules/phase-1-review.md`: coder-critic dispatch protocol
- `do/main.do`: orchestration entry point
- `quality_reports/session_logs/2026-05-16_m4-pre-flight-audit-and-protocol.md`: pre-flight + acceptance-run context
- `log/main_17-May-2026_17-23-02.smcl`: the failed acceptance run (evidence)
