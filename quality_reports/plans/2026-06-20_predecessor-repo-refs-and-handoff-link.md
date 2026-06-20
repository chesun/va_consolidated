# Plan — Fix predecessor-repo references + add HANDOFF link to README

**Date:** 2026-06-20
**Status:** COMPLETED (implemented + verified same session)

## Context

The README framed the two predecessor codebases as files living **locally on
Christina's machine** (`~/github_repos/cde_va_project_fork`; a Dropbox path for
`caschls`). That is wrong: those local folders are working **clones of GitHub repos**,
and each predecessor also has a **Scribe project folder** where its pipeline ran. A
future reader (incoming PI Paco, the data custodian, any successor) should be pointed at
the canonical GitHub repo + the Scribe path, not a path on one person's laptop. The
README also lacked a prominent pointer to `HANDOFF.md`.

**Scope (confirmed with user via AskUserQuestion):** edit living/forward-facing docs
only — `README.md`, `MEMORY.md`, `HANDOFF.md`. Append-only historical records (ADRs,
session logs, reviews, audits, `SESSION_REPORT.md`) left untouched per `decision-log.md`
/ `logging.md`.

## Derived facts (looked up, not guessed)

| Predecessor | GitHub (canonical) | Local clone | Scribe path | Master |
|---|---|---|---|---|
| `cde_va_project_fork` (VA estimation) | `https://github.com/chesun/cde_va_project_fork` | `~/github_repos/cde_va_project_fork` | `/home/research/ca_ed_lab/projects/common_core_va` | `do_files/do_all.do` |
| `caschls` (CalSCHLS + sibling links) | `https://github.com/chesun/caschls` | `~/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls` | `/home/research/ca_ed_lab/users/chesun/gsr/caschls` | `do/master.do` |

Sources: clone remotes (`git remote -v`); Scribe paths from `do/settings.do:128`
`$vaprojdir` + `:136` `$caschls_projdir`, cross-checked against the fork's own
`do_files/do_all.do:2` + `do_files/settings.do:25,28`.

**Correction caught:** README §10 claimed each predecessor was "archived at `v1.0-archive`
tag." Neither repo has that tag (`git tag` confirmed none) — claim dropped, not propagated.

Out-of-scope third predecessor left as a narrative note: `ca_ed_lab-common_core_va`
(Matt Naven's original, `https://github.com/mnaven/ca_ed_lab-common_core_va`, the fork's
`upstream`) per ADR-0001.

## Edits (all applied)

1. **`README.md`** — (a) blockquote HANDOFF callout immediately after the H1 (line 5);
   (b) §1 predecessor bullets now carry GitHub + Scribe each; (c) §10 "Predecessor
   codebases" rewritten to "GitHub is canonical; Scribe folder + local clone exist," with
   a GitHub/Scribe sub-list per repo (incl. `$vaprojdir` / `$caschls_projdir` cross-refs);
   false `v1.0-archive` claim removed.
2. **`MEMORY.md`** (`[LEARN:domain]`, line 78) — reframed to GitHub+clone+Scribe;
   README correction marked done 2026-06-20; "no `v1.0-archive` tag" noted.
3. **`HANDOFF.md`** (§2) — short Paco-friendly "For reference" note with each
   predecessor's GitHub + Scribe, plus a one-line "you don't need these to run it."

## Verification (passed)

1. `grep -nE "local machine|~/github_repos/cde_va|Christina.s Dropbox|v1.0-archive" README.md`
   → only the two legitimate "local machine" lines (§1 run-constraint, §2 clone-step);
   zero predecessor-as-local or `v1.0-archive` hits.
2. `grep -n HANDOFF README.md` → callout link at line 5; `HANDOFF.md` exists at root.
3. `grep -nE "chesun/cde_va_project_fork|chesun/caschls" README.md HANDOFF.md MEMORY.md`
   → GitHub URLs (with Scribe paths alongside) present in all three.
4. Visual scan — clean markdown (blank line before each list, nested sub-lists at 4-space
   indent).
5. `git status --porcelain` → only `README.md`, `HANDOFF.md`, `MEMORY.md` modified; no
   historical record touched.

## Status / follow-up

Edits unstaged, uncommitted. Per `phase-1-review.md` these are docs (not in-scope code),
so no coder-critic gate required. Commit pending user go-ahead.
