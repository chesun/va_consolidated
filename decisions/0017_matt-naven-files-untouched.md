# 0017: Matt Naven's files stay untouched through Phase 1

- **Date:** 2026-04-27
- **Status:** Decided
- **Scope:** Infrastructure
- **Data quality:** Full context

## Context

Phase 0a-v2 audit (2026-04-26) inventoried 85 verified bugs across the two predecessor repos in scope (`cde_va_project_fork`, `caschls`). A subset of these bugs lives in files originally authored by Matt Naven — specifically the NSC/CCC/CSU outcome crosswalks, the post-secondary merge helper, and the Census-Bureau geocoding script. These files are wired into the production pipeline but Christina is not their author.

During Phase 1 framing (2026-04-26), Christina set the scope rule: **"Leave Matt Naven's files as-is; only fix code Christina owns."** Bugs in Matt's files — including the four-instance Bug 93 family (NSC UC + UC ontime + CCC ontime + CSU ontime) — stay UNFIXED in Phase 1. Path resolution still works on Scribe because Matt's hardcoded paths *are* the Scribe paths.

This decision was originally captured as a `[LEARN:domain]` entry in `MEMORY.md` and a TODO line. The 2026-04-27 T1-empirical-tests script-writing exercise made it concrete: testing for bugs we won't fix is wasted effort, so two of the five T1 tests (T1-1, T1-2) were retired from the active test list. That made the constraint load-bearing enough to warrant an ADR.

## Decision

The following files are **OUT OF SCOPE for code modification through Phase 1** of the consolidation:

- `cde_va_project_fork/do_files/upstream/crosswalk_nsc_outcomes.do`
- `cde_va_project_fork/do_files/upstream/crosswalk_ccc_outcomes.do`
- `cde_va_project_fork/do_files/upstream/crosswalk_csu_outcomes.do`
- `cde_va_project_fork/do_files/merge_k12_postsecondary.doh`
- `cde_va_project_fork/py_files/sbac/gecode_json.py`

Concrete consequences for known findings:

- **Bug 93 family (P2-1 in audit):** 4 instances — NSC UC at L218-219, NSC UC ontime at L227-228 of `crosswalk_nsc_outcomes.do`; CCC ontime at L168-170, CSU ontime at L232-234 of `merge_k12_postsecondary.doh`. **NOT FIXED in Phase 1.** Audit confirmed paper blast radius is null for current paper outputs (`csu_transfer_uc` not cited; composite `enr_*` outcomes do not consume `nsc_enr_uc`).
- **`id` macro at `crosswalk_nsc_outcomes.do:250` (P1-1 in audit):** local `id` undefined, possible silent corruption of `college_begin_date`. **NOT TESTED, NOT FIXED in Phase 1.**
- **Hardcoded user-machine paths in CCC/CSU crosswalks (P3-68):** **NOT FIXED in Phase 1.** Paths happen to resolve on Scribe because they ARE Scribe paths.
- **Hardcoded absolute path at `merge_k12_postsecondary.doh:7` (P2-9):** **NOT FIXED in Phase 1.** Was originally queued for parameterization via `$vaprojxwalks`; deferred.

`mattschlchar.do` is **explicitly NOT covered by this scope rule.** Despite the name, the file header (L4-5) credits "written by Che Sun"; it is Christina-authored production wrapper code that is wired into `master.do:412` and produces `schlcharpooledmeans.dta` consumed by both Table 8 panel producers. Bugs in `mattschlchar.do` ARE in scope for Phase 1 (P2-15 cross-user path).

## Consequences

**Commits us to:**

- Phase 1 file-touch list excludes the 5 files above.
- T1 empirical-test list reduced from 5 to 3 tests; T1-1 and T1-2 retired.
- Replication on Scribe will continue to work as-is for the current paper. Off-Scribe replication remains blocked on Matt's hardcoded paths (acceptable trade-off — no off-Scribe runtime is in scope per ADR-0002).
- Future analyses that depend on `nsc_enr_uc` or its derivatives will silently inherit Bug 93. Anyone extending the paper's college-outcome analysis to UC-selectivity questions must revisit this decision.

**Rules out:**

- Reframing Bug 93 as "P1, paper-blocking" — the constraint explicitly de-prioritizes it.
- A clean off-Scribe replication package built solely from this consolidated repo (until Matt's files are either re-authored or re-licensed for editing).

**Open questions this creates:**

- When does this constraint relax? Possible triggers: (a) Christina takes ownership of a file with Matt's permission, (b) Matt's files are re-authored from scratch in `cleaned/upstream/` and the originals retire, (c) a new paper revision needs UC-selectivity analyses that depend on `nsc_enr_uc`. Each trigger should produce a successor ADR.
- The CCC/CSU external crosswalk dependencies (`k12_ccc_crosswalk.dta`, `k12_csu_crosswalk.dta`) live in Matt's user directory and are referenced but not vendored. ADR-0006 (queued — external crosswalks vendoring) needs to address this without modifying Matt's source files.
- Should the constraint extend to Matt's two external `.dta` crosswalks (read-only data, not code)? Strict reading of the constraint says no (data ≠ code), but ADR-0006 should make this explicit.

## Sources

- `MEMORY.md` — `[LEARN:domain]` entry on file ownership constraint (added 2026-04-26)
- `TODO.md` — Active section, file-ownership constraint line (Last updated 2026-04-26)
- `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` §1 (Bug 93 paper-impact analysis), §2 P2-1 (Bug 93 family), §3.1 T1-1 and T1-2 (now retired)
- `SESSION_REPORT.md` — entry "2026-04-26 (continued) — Phase 1 framing discussion + ownership clarifications + plan deferred"
- Conversation 2026-04-27: T1 .do file scoping made the constraint load-bearing for the test list
- Related: ADR-0001 (consolidation scope), ADR-0002 (runtime — Scribe only)
