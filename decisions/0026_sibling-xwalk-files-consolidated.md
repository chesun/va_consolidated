# 0026: sibling-crosswalk producers consolidated under `do/sibling_xwalk/`

- **Date:** 2026-06-01
- **Status:** Decided
- **Scope:** Infrastructure
- **Supersedes:** extends #0005 (siblingoutxwalk relocation path) — see below

## Context

The four sibling-crosswalk producer scripts were split across two directories purely as an
artifact of predecessor structure + two separate relocation batches:

- `do/sibling_xwalk/siblingoutxwalk.do` — relocated early (ADR-0005) from predecessor
  `caschls/do/share/siblingvaregs/siblingoutxwalk.do`.
- `do/share/siblingxwalk/{siblingmatch,uniquefamily,siblingpairxwalk}.do` — relocated later
  (Phase 1a §3.3 step 10 batch 10c) from predecessor `caschls/do/share/siblingxwalk/`,
  preserving that predecessor subpath under `do/share/`.

There is no functional reason for the split — all four build sibling/family crosswalks and
are the same conceptual family. The split was confusing (Christina flagged it 2026-06-01:
"why are three sibling matching do files under do/share/siblingxwalk, and siblingoutxwalk.do
under do/sibling_xwalk?").

## Decision

- **Move the three `do/share/siblingxwalk/*.do` files into `do/sibling_xwalk/`**, alongside
  `siblingoutxwalk.do`. All four sibling-crosswalk producers now live in one directory.
- **Repoint their log paths** from `$logdir/share/siblingxwalk/<name>` to
  `$logdir/sibling_xwalk/<name>` to satisfy the per-file logging mirror convention
  (`stata-code-conventions.md`: a file at `do/<reldir>/<name>.do` logs to
  `$logdir/<reldir>/<name>.smcl`; `check_logs.do` computes the expected log path from the
  do file's relative dir, so the mirror is enforced). Removed the now-orphan
  `cap mkdir "$logdir/share"` lines.
- **Update `do/main.do`** invocation paths (the three are currently commented in the
  dev-skip section; paths repointed in place).
- Header self-reference lines updated to the new path; predecessor `Source:` provenance
  lines and the predecessor "To run" example left intact (historical record).

This **extends ADR-0005**: that ADR placed `siblingoutxwalk.do` at `do/sibling_xwalk/`; this
ADR makes `do/sibling_xwalk/` the canonical home for *all* sibling-crosswalk producers, so
ADR-0005's destination is reaffirmed, not reversed.

## Consequences

**Commits us to:**
- One directory (`do/sibling_xwalk/`) for the 4 sibling-crosswalk producers; `$logdir`
  mirrors it.
- `do/share/siblingxwalk/` removed (empty after the move).

**Rules out:**
- Re-splitting these by predecessor subpath.

**Note (golden-master):** moves + log-path repoints are path-only; no analysis logic
changed, and the `.dta` outputs (`$datadir_clean/siblingxwalk/...`) are unchanged. The only
behavioral delta is *where the logs land* ($logdir/sibling_xwalk/ vs the old share/ path) —
which `check_logs.do` now expects. Confirmed by next Scribe run.

## Sources

- `do/sibling_xwalk/{siblingoutxwalk,siblingmatch,uniquefamily,siblingpairxwalk}.do`
- `do/main.do` Phase 6 sibling invocations (repointed)
- `.claude/rules/stata-code-conventions.md` § Per-file logging structure; `do/check/check_logs.do` (expected-log-path computation)
- Christina 2026-06-01 (flagged the confusing split)
- Related: ADR-0005 (siblingoutxwalk relocation — extended here), ADR-0021 (relocation conventions)
