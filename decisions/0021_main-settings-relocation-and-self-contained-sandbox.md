# 0021: Relocate main.do + settings.do under do/; consolidated/ is a self-contained output sandbox; every do file carries a description

- **Date:** 2026-04-29
- **Status:** Decided
- **Supersedes:** none (refines ADR-0007 sandbox model + ADR-0014 entry-point naming + plan v3 §3.1/§3.2/§3.3/§3.4)
- **Scope:** Infrastructure
- **Data quality:** Full context

## Context

Three related architectural refinements to the Phase 1a pre-drafts surfaced 2026-04-29:

1. **main.do and settings.do at repo root were inconsistent with the folder layout.** The CLAUDE.md folder map placed `main.do` and `settings.do` at the repo root alongside `ado/`, `do/`, `py/`, etc. This mirrored the predecessor convention (`mainscript.do` at fork root, `master.do` at caschls root). But both files are .do files — the same kind of artifact that lives under `do/` for everything else. Putting two .do files in a special-case root location, while the other ~150 .do files live under `do/`, creates a small but persistent surprise for anyone navigating the tree.

2. **Output-path discipline was implicit, not architecturally committed.** ADR-0007 established code-data separation (GitHub holds code+docs+tables+figures only; data on Scribe). settings.do's path globals already split into "canonical" (under `$consolidated_dir`) and "legacy" (predecessor / restricted-access). But there was no explicit commitment that *no relocated do file may write to a legacy path*. Without that commitment, a future relocation could `save "$vaprojdir/data/cleaned/foo.dta", replace` and silently pollute the predecessor pipeline's output, breaking the `diff -r consolidated/output predecessor/output` comparability that the consolidation was designed to enable.

3. **Description discipline was unenforced.** settings.do and main.do had detailed header blocks (drafted 2026-04-28). The convention was implicit: future relocated files would presumably follow suit. But "presumably" is not a rule. With ~150 files to relocate and an offboarding successor who will read this codebase cold, the discipline of (a) every do file's own header describing what it does and (b) every main.do invocation having a one-liner naming the called script's role needs to be a binding rule, not a convention people remember if they remember.

The three refinements share an offboarding-readability frame: a successor opening this repo at `v1.0-final` should (a) find main.do where they expect it (with the rest of the .do files), (b) trust that consolidated/ is self-contained so the pipeline runs without leaking outputs to predecessor paths, and (c) be able to skim main.do top-to-bottom and understand at one-line precision what each invoked script does, without having to open every .do file.

## Decision

**Three sub-decisions, codified together:**

### Sub-decision 1 — main.do and settings.do live under do/

- `main.do` is at `do/main.do`. `settings.do` is at `do/settings.do`.
- Pipeline invocation becomes: `cd $consolidated_dir && stata -b do do/main.do`.
- Inside main.do: `include do/settings.do` (CWD is `$consolidated_dir` at runtime, so the include resolves correctly).
- All other phase-block invocations remain as `do do/<subdir>/<file>.do` — consistent with the new entry point.
- CLAUDE.md folder map updated; plan v3 §3.1, §3.2, §3.4, §3.5 references updated; TODO.md acceptance-run command updated.

### Sub-decision 2 — consolidated/ is a self-contained output sandbox

settings.do globals split into two explicit classes:

- **CANONICAL paths** — point inside `$consolidated_dir`. The pipeline may READ and WRITE these freely. (`$consolidated_dir`, `$datadir`, `$datadir_clean`, `$datadir_raw`, `$logdir`, `$estimates_dir`, `$output_dir`, plus `$consolidated_dir/tables/` and `$consolidated_dir/figures/` for paper-shipping artifacts.)
- **LEGACY paths** — point outside `$consolidated_dir` (predecessor repos, Matt's untouched files, restricted-access raw data). The pipeline READS these but MUST NOT WRITE. (`$matt_files_dir`, `$vaprojdir`, `$vaprojxwalks`, `$caschls_projdir`, `$nscdtadir`, `$nscdtadir_oldformat`, `$mattxwalks`.)

The architectural commitment: every `save`, `export`, `outsheet`, `esttab using`, `graph export`, `outreg2 using`, `texsave` (etc.) call in any relocated do file targets a CANONICAL path. Phase 1a uses `grep -nE 'save|export|esttab using|graph export|outsheet'` per relocated file as part of the per-commit self-check (per phase-1-review.md Tier 1).

Payoff: at offboarding, `diff -r consolidated/output predecessor/output` produces a clean comparison. No path-collision noise; no predecessor paths polluted by the consolidated pipeline. The successor inherits a sandbox they can run, modify, and re-run without touching predecessor state.

### Sub-decision 3 — description convention

Every do file in the consolidated pipeline (under `do/` excluding `_archive/`) has:

1. **A header description block** at the top of the file. Mirrors the existing settings.do / main.do header style: PURPOSE / INVOKED FROM / CONVENTIONS / REFERENCES (or a similar block adapted to the script's role). The header is the authoritative longer description of what the script does.

2. **A one-liner inline next to its `do do/<path>/<file>.do` call site in main.do.** Format: `do do/<path>/<file>.do    // <one-liner>`. The one-liner names the script's role at a glance — what it produces, what it depends on, what stage of the pipeline it serves. The one-liner is the at-a-glance index; the header is the source of truth.

Both apply to all relocated files in Phase 1a §3.3, plus the existing pre-drafts (`do/main.do`, `do/settings.do`, `do/explore/codebook_export.do`, `do/check/t1_empirical_tests.do`). Going forward, coder-critic checks both on each relocation per phase-1-review.md §3 dispatch matrix; the per-commit checklist in phase-1-review.md §2 is extended to include "relocated/new do file has a header block AND a one-liner in main.do."

## Consequences

**Commits us to:**

- Updating CLAUDE.md folder map: main.do and settings.do listed under `do/`, not at root.
- Updating CLAUDE.md Commands block: `stata -b do do/main.do` (and `cd consolidated/` not `cd common_core_va/`).
- Updating plan v3 §3.1 (folder layout), §3.4 (main.do skeleton example), §3.5 (golden-master invocation), §6.4 M3 milestone, §5.4 step 13 (acceptance run command).
- Updating TODO.md Phase 1c §5.4 acceptance-run command.
- Editing do/main.do INVOCATION block + `include do/settings.do` line + adding SANDBOX PRINCIPLE block + adding description-convention block.
- Editing do/settings.do INVOKED-FROM block + adding SANDBOX PRINCIPLE block + adding READ vs WRITE separation in CANONICAL/LEGACY section headers.
- Adding the description requirement and sandbox-write check to plan v3 §3.3 step instructions for every Phase 1a relocation.
- Updating .claude/rules/stata-code-conventions.md with the description-header rule + sandbox-write rule (codifies the convention beyond plan v3 so it persists past v1.0-final).
- coder-critic dispatched on this commit per phase-1-review.md (substantive changes to settings.do + main.do).

**Trade-offs accepted:**

- Stata's `do filename` from a directory other than the file's parent: CWD does NOT auto-change to the do-file's directory. So `do do/main.do` keeps CWD = `$consolidated_dir`, and `include do/settings.do` resolves relative to that. This is the desired behavior (every other `do do/<path>/<file>.do` invocation also expects CWD = `$consolidated_dir`); but a future operator running `do main.do` from inside `do/` would have `include do/settings.do` fail. Mitigation: the INVOCATION block in main.do explicitly states the working directory; the offboarding deliverable memo (Phase 1c §5.2 step 8) reinforces it.
- A two-line header on every do file is mild boilerplate. Accepted as worth it for offboarding readability — the alternative is a successor opening every file to figure out what it does.
- The sandbox WRITE rule means relocated files that historically wrote to `$vaprojdir/something/` need their save paths repointed to `$consolidated_dir/something/`. This is mechanical; Phase 1a per-commit self-check catches violations.

**Forward implications:**

- Every Phase 1a §3.3 relocation commit now has three checklist items beyond path-reference updates: header description present, one-liner added in main.do at the invocation site, all writes target CANONICAL globals.
- Phase 1c §5.4 README must reflect the new invocation (`stata -b do do/main.do`) and document the sandbox principle for the successor.
- ADR-0007's code-data separation commitment is reinforced (not weakened) — the sandbox principle is the operational rule that ADR-0007's commitment implies but does not state.
- ADR-0014's "main.do is canonical" commitment is reinforced — this ADR clarifies *where* canonical main.do lives.

## Sources

- `do/main.do` (current state, post-2026-04-28 pre-draft)
- `do/settings.do` (current state, post-2026-04-28 pre-draft)
- `quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md` §3.1, §3.3, §3.4, §3.5
- `decisions/0007_code-data-separation.md` (sync-model section now refined twice — ADR-0020 dropped wrapper scripts; ADR-0021 makes sandbox principle explicit)
- `decisions/0014_main-do-canonical-entry-point.md` (entry-point naming; this ADR clarifies *location*)
- `decisions/0017_matt-naven-files-untouched.md` (LEGACY paths include Matt's files)
- `.claude/rules/phase-1-review.md` (per-commit self-check + dispatch matrix — extended)
- `.claude/rules/stata-code-conventions.md` (will be amended with description + sandbox-write rules)
- 2026-04-29 conversation between Christina and Claude where the three refinements landed together.
