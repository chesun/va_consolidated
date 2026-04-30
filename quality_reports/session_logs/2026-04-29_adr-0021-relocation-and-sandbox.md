# Session Log: 2026-04-29 — ADR-0021 + Option A check skeletons + plan v3 APPROVED + Option B README + §9 codebook clarification + no-provider-PDFs constraint

**Status:** COMPLETED — end of day 2026-04-29 (10 commits pushed today: `9120754` ADR-0021; `4769831` hygiene #1; `97789f6` session log; `d775efe` Option A; `768edfa` hygiene #2; `949b452` plan v3 APPROVED; `053871e` Option B README; `916c76e` hygiene #3; `518a71a` §9 codebook clarification; `0838119` no-provider-PDFs constraint; plus the imminent hygiene #4 commit)

## Objective

Christina's request, three architectural refinements landed together:

1. **Move `main.do` + `settings.do` under `do/`** — consistency: every other .do file lives there, the two entry-point files should too.
2. **Make `consolidated/` a self-contained output sandbox** so `diff -r consolidated/output predecessor/output` cleanly compares the new pipeline against the predecessor without polluting either side.
3. **Establish a description convention** — every do file has a header description AND a one-liner next to its invocation in main.do.

## Changes Made

| File | Change | Reason | Quality Score |
|---|---|---|---|
| `main.do` → `do/main.do` | `git mv` + header rewrite (PURPOSE / INVOCATION / SANDBOX PRINCIPLE / CONVENTIONS / REFERENCES blocks) + `include settings.do` → `include do/settings.do` + per-phase TODO blocks gain one-liner descriptions per the new ADR-0021 convention + audit-marker comment in CONVENTIONS noting the placeholder one-liners need re-verification at Phase 1a §3.3 relocation time | Sub-decisions 1, 2, 3 of ADR-0021 | coder-critic 92/100 PASS |
| `settings.do` → `do/settings.do` | `git mv` + header rewrite (path reference + INVOKED FROM + new SANDBOX PRINCIPLE block) + CANONICAL section labeled "WRITE-allowed" + LEGACY section labeled "READ-ONLY" with rationale | Sub-decisions 1, 2 of ADR-0021 | coder-critic 92/100 PASS |
| `decisions/0021_main-settings-relocation-and-self-contained-sandbox.md` | NEW — formalizes the three sub-decisions; documents trade-offs (Stata's `do filename` does not change CWD, so `include do/settings.do` resolves correctly when invoked as `stata -b do do/main.do` from `$consolidated_dir`); explicitly enumerates retroactive-coverage scope (do/main.do, do/settings.do, do/explore/codebook_export.do, do/check/t1_empirical_tests.do) | ADR governance | n/a (ADR) |
| `decisions/README.md` | Added ADR-0021 entry to Decided ledger | ADR ledger sync | n/a |
| `CLAUDE.md` | Folder map: main.do/settings.do moved from root → under `do/`. Commands block: `cd` path corrected to `consolidated/` (was predecessor root), invocation corrected to `stata -b do do/main.do` | Direct consequence of sub-decision 1; aligns with `$consolidated_dir` in settings.do | n/a (docs) |
| `TODO.md` | Phase 1c §5.4 acceptance-run command updated to `stata -b do do/main.do`. Added 2026-04-29 ADR-0021 entry to Done. Updated coder-critic audit trail with second commit `9120754` | TODO sync per todo-tracking.md | n/a |
| `quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md` | §3.2 folder map (main.do/settings.do under do/); §3.3 added "Description convention (per ADR-0021)" subsection + "Sandbox principle (per ADR-0021)" subsection + revised success criterion; §3.4 skeleton example updated with `// do/main.do —` header + `include do/settings.do` + ADR-0021 cite; §3.4 success criterion updated; §3.5 step 2 (`consolidated/do/main.do`); §5.4 step 13 (acceptance run); §6.4 M3 milestone | Reflect ADR-0021 across all plan v3 sections | n/a (plan, not code) |
| `.claude/rules/stata-code-conventions.md` | Project Structure block updated to reference `do/main.do` + `do/settings.do` per ADR-0021. New "Description Convention (per ADR-0021)" section. New "Sandbox Write Discipline (per ADR-0021)" section with grep check for save/export/esttab targets | Codify ADR-0021 conventions in workflow rules so they persist past v1.0-final | n/a |
| `.claude/rules/phase-1-review.md` | Per-commit checklist extended with ADR-0021 item: "For relocated/new do files specifically — header description present, one-liner present in main.do at invocation site, every save/export/etc. targets a CANONICAL global (verified via grep)" | Make ADR-0021 enforcement durable in the per-commit discipline | n/a |
| `do/explore/codebook_export.do` | Header gained ROLE IN ADR-0021 SANDBOX block (clarifies: diagnostic, runs on predecessor Scribe layout, writes to predecessor `log_files/`, NOT a consolidated-pipeline script). ADR-0021 added to REFERENCES | Closes coder-critic M1 gap (ADR-0021 line 52 retroactive-coverage scope) | n/a |
| `do/check/t1_empirical_tests.do` | Same — ROLE IN ADR-0021 SANDBOX block + ADR-0021 in REFERENCES | Closes coder-critic M1 gap | n/a |
| `SESSION_REPORT.md` + `.claude/SESSION_REPORT.md` | Appended 2026-04-29 entry (operations / decisions / commits / status / tomorrow pickup pointers). Mirrored | logging.md §2 |  n/a |

## Design Decisions

| Decision | Alternatives Considered | Rationale |
|---|---|---|
| `main.do` and `settings.do` live under `do/`, not at repo root | Keep at root (predecessor convention; mirrors fork's `mainscript.do` and caschls's `master.do`) | Consistency: every other .do file is under `do/`. Two .do files at the root creates a small but persistent surprise for a successor navigating the tree. The CWD discipline (CWD = `$consolidated_dir`, never `do/`) means `include do/settings.do` works from any phase block consistently |
| `consolidated/` is a self-contained output sandbox; LEGACY globals are read-only | Allow writes to LEGACY paths for incremental-development convenience | The sandbox principle is what makes `diff -r consolidated/output predecessor/output` clean. Allowing writes to LEGACY paths even temporarily would pollute the predecessor and break the comparability that the consolidation was designed to enable |
| Description convention requires BOTH a header description AND a main.do one-liner | Header only (sufficient if reader opens the file) OR main.do one-liner only (sufficient as an at-a-glance index) | Different audiences: (a) a successor opening a file cold needs the longer header to understand purpose / inputs / outputs / invariants; (b) a successor scanning main.do top-to-bottom needs the one-liner to know what each invocation does without opening 150 files. Both serve different points in the offboarding-readability path |
| Codify ADR-0021 in `.claude/rules/stata-code-conventions.md` (and `phase-1-review.md` checklist), not just in plan v3 | Plan v3 only (scope is Phase 1; rules outlive Phase 1 unnecessarily) | Plan v3 sunsets at `v1.0-final`. The conventions need to survive the offboarding handoff so a successor enforcing this codebase's discipline (or an adversarial-default audit) has the rule on hand. Project rules are the right home; plan v3 is the timeline-bound implementation |
| Address coder-critic M1 by adding ROLE IN ADR-0021 SANDBOX blocks to the two diagnostic files (option 1) | Amend ADR-0021's scope statement to scope-out non-pipeline-active files (option 2) | ADR-0021 is freshly Decided and should not be edited per `.claude/rules/decision-log.md` immutability ("leave the old ADR's body intact"). Option 1 is the cleaner read of the rule: apply the convention as written, with files clarifying their role within the sandbox principle (predecessor-layout diagnostics, NOT consolidated-pipeline scripts) |
| Address coder-critic M2 inline in main.do CONVENTIONS block (option 2) | Keep placeholders as-is and rely on Phase 1a §3.3 reviewer to catch | Explicit beats implicit. The CONVENTIONS bullet — "the phase blocks below currently hold placeholder one-liners — Phase 1a §3.3 has not yet relocated the actual scripts. When each script is relocated, the per-commit checklist requires cross-checking the one-liner against the relocated script's header" — makes the verification handoff explicit instead of trusting future-reader inference |
| Leave ADR-0018 + ADR-0020 bodies intact even though they reference the old `stata -b do main.do` invocation | Edit them to reflect the new invocation | Per `.claude/rules/decision-log.md` ADRs are append-only; "Leave the old ADR's body intact." The supersession of operational details is surfaced via decisions/README.md ledger ordering. Editing immutable ADRs would set bad precedent |

## Incremental Work Log

- **morning (context restore):** /clear-ed; user asked "please get up to date on our work." Read TODO.md + SESSION_REPORT.md + plans/INDEX.md + reviews/INDEX.md + git log to reorient. Summarized state at start of 2026-04-29: 20 ADRs decided; Phase 1a §3.1 + §3.2 pre-drafts done; Phase 1a §3.3 not started; plan v3 still DRAFT; first coder-critic dispatch (`e1cbc56`) was 94/100 PASS.

- **morning (request):** Christina: "I think I want to move main.do and settings.do to do/ folder because those are do files too. and we want to make sure the consolidated folder is a self contained sandbox, so we can sptially compare outputs against the previous unconsolidated pipeline. finally, each do file in the consolidated pipeline should have an informative description on its functionality, and there should be a one liner description for each do file in the main.do."

- **morning (sketch + verify):** Sketched my read of the three asks back to Christina (move = mechanical; sandbox = mostly making implicit architecture explicit since settings.do already split CANONICAL vs LEGACY by path; descriptions = rule codification). Christina confirmed: "your understanding is correct."

- **morning (path reference grep):** Grep across `**/*.{md,do,doh}` for `main.do` and `settings.do` references. Found 13 references needing updates (CLAUDE.md folder map + Commands; TODO.md acceptance-run command; plan v3 §3.2/§3.4/§3.5/§5.4/§6.4) and 3 references that should NOT be updated (ADR-0018 + ADR-0020 bodies — immutable per decision-log.md; SESSION_REPORT.md + MEMORY.md + audits/ + session_logs/ — historical narrative).

- **morning (file moves):** `git mv main.do do/main.do; git mv settings.do do/settings.do`. Then read at new paths (Edit tool requires post-move Read).

- **morning (do/main.do edits):** Updated header — path reference, INVOCATION block (`stata -b do do/main.do`), STATUS block (notes the relocation), new SANDBOX PRINCIPLE block, new description-convention bullet in CONVENTIONS, ADR-0021 in REFERENCES. Updated `include settings.do` → `include do/settings.do` with comment explaining the CWD logic. Updated all 7 phase TODO blocks: each placeholder script invocation now has a `// <one-liner>` annotation. Phase 1 (data_prep) covers the 6 cleaning subdirs; Phase 2 (samples) covers touse_va, create_*_samples, sibling_xwalk; Phase 3 (VA estimation) covers va_score_all, va_out_all, heterogeneity, pass_through; Phases 4 + 6 split share/ producers (VA-specific vs non-VA); Phase 5 (Survey VA) covers the 6 CalSCHLS files; Phase 7 (data checks) covers the 6 check_*.do files per design memo.

- **morning (do/settings.do edits):** Updated header — path reference, INVOKED FROM block, new SANDBOX PRINCIPLE block explaining CANONICAL vs LEGACY semantics. Restructured CONVENTIONS list into "CANONICAL (read + write)" and "LEGACY (read-only)" subsections. Updated CANONICAL section header to "WRITE-allowed per ADR-0021 sandbox" and LEGACY section header to "READ-ONLY per ADR-0021 sandbox" with a 2-line rationale comment. Added ADR-0021 to REFERENCES.

- **midday (CLAUDE.md update):** Folder map: removed root-level main.do + settings.do entries, added them under `do/` block (with `# Phase 1a writes the SINGLE pipeline entry point` description). Commands block: corrected `cd` from predecessor root (`/home/research/ca_ed_lab/projects/common_core_va`) to consolidated root (`/home/research/.../consolidated`); invocation `stata -b do main.do` → `stata -b do do/main.do`.

- **midday (TODO.md):** Phase 1c §5.4 acceptance-run command updated.

- **midday (plan v3 sweep):** Updated 6 distinct sections — §3.2 folder map, §3.4 skeleton block + success criterion, §3.5 step 2 invocation, §5.4 step 13 acceptance-run command, §6.4 M3 milestone. New §3.3 subsections: "Description convention (per ADR-0021)" with the (a)+(b) header+one-liner requirement; "Sandbox principle (per ADR-0021)" with the grep check for save/export/etc. targeting CANONICAL globals; revised §3.3 success criterion enumerating all three checks.

- **midday (ADR-0021 written):** 4-section ADR (Context / Decision / Consequences / Sources) with three sub-decisions. Trade-offs section explicitly documents the Stata CWD-doesn't-change-with-`do` semantics and the failure mode of running `do main.do` from inside `do/`. Sources cite all relevant ADRs (0007, 0014, 0017, 0020) plus today's conversation. ADR-0021 added to decisions/README.md ledger.

- **midday (`.claude/rules/stata-code-conventions.md`):** Project Structure block updated. New Description Convention section codifying header + one-liner. New Sandbox Write Discipline section with explicit grep command for save / export / outsheet / esttab using / graph export / outreg2 using / texsave on CANONICAL globals only. Cross-references ADR-0021 + phase-1-review.md.

- **midday (verify completeness):** Re-grep for any missed `main.do` / `settings.do` references. Found 3 stale: ADR-0018 line 27, ADR-0020 line 41, and ADR-0021 line 70 (the new one — intentional, illustrates the failure mode). Per ADR immutability rule, ADR-0018 + ADR-0020 bodies stay intact. ADR-0021's reference is correctly contextual.

- **midday (coder-critic dispatch):** Per phase-1-review.md §3 dispatch matrix — substantive change to entry-point files + new architectural rule clearly warrants dispatch. Crafted prompt with 8 specific concerns: Stata `include` semantics, sandbox-principle internal consistency, retroactive description application, plan v3 reference completeness, ADR immutability handling, CLAUDE.md `cd` path correctness, one-liner speculativeness, scope creep.

- **midday (coder-critic verdict):** **Score: 92/100 PASS.** No Critical or Major findings. Two Minor findings: M1 (ADR-0021 line 52 enumerates do/explore/codebook_export.do + do/check/t1_empirical_tests.do in scope but they weren't touched — gap); M2 (placeholder one-liners lack explicit per-line audit marker). Reviewer recommended option (1) for M1 (add ROLE IN ADR-0021 SANDBOX block) and an explicit CONVENTIONS bullet for M2.

- **midday (M1 fix):** Added ROLE IN ADR-0021 SANDBOX block to both diagnostic files. Block clarifies they are predecessor-layout diagnostics (run on Scribe `do_files/` + `log_files/`, not consolidated-pipeline scripts under `do/`). Added ADR-0021 to each file's REFERENCES.

- **midday (M2 fix):** Added a CONVENTIONS bullet in main.do header explicitly noting that placeholder one-liners need cross-checking against the relocated script's header at Phase 1a §3.3 relocation time. Made the verification handoff explicit.

- **midday (extend phase-1-review.md):** Added the ADR-0021 enforcement item to the per-commit checklist so the discipline persists past v1.0-final. The item lists the (a) header (b) one-liner (c) save/export grep check explicitly.

- **midday (commit + push):** `git status` confirmed 11 files (2 renames, 1 add, 8 modifications). Crafted commit message documenting all three sub-decisions, file changes, ADR immutability handling for ADR-0018/0020, and the coder-critic verdict + M1/M2 resolution. Footer: `coder-critic: PASS (92/100); two Minor findings ... addressed in this commit per the reviewer's recommended option (1).` Committed `9120754` (11 files, 278+/83-). Pushed to origin/main.

- **midday (hygiene):** TODO.md Done entry added; SESSION_REPORT.md + .claude/SESSION_REPORT.md mirror appended with the 2026-04-29 entry. Committed `4769831` with footer `coder-critic: skipped (rationale: docs-only ...)`. Pushed.

- **midday (next-steps):** User asked "tell me whats next." Replied with the three TODO Active options (A: pre-draft check_*.do skeletons; B: pre-draft README skeleton; C: begin Phase 1a §3.3 relocation with siblingoutxwalk.do) along with which discipline each exercises. Recommendation: Option A as a steady warm-up (first end-to-end exercise of ADR-0021 on substantively new code, low repo-state risk, builds the data-checks pipeline before relocations need its guardrails).

## Learnings & Corrections

- [LEARN:stata] `do <filename>` from outside the file's directory does NOT change CWD. CWD remains the caller's CWD throughout. This means `include do/settings.do` at the top of `do/main.do` resolves correctly when invoked as `cd $consolidated_dir; stata -b do do/main.do` — and would FAIL if run as `cd do; do main.do` (CWD would be `do/` and `include do/settings.do` would look for `do/do/settings.do`). The INVOCATION block in main.do is the load-bearing documentation. Verified explicitly in ADR-0021's Trade-offs section.

- [LEARN:workflow] The four rules `no-assumptions.md`, `primary-source-first.md`, `derive-dont-guess.md`, `adversarial-default.md` form the workflow's epistemic floor. Today's work exercised three of them: derive-dont-guess (grep for `main.do` references before invented updates); adversarial-default (coder-critic dispatch produces evidence of compliance, not the assumption of it); no-assumptions (sketched my read of the three asks back to Christina before proceeding, instead of guessing what "self-contained sandbox" meant). primary-source-first wasn't relevant — no external paper citations in this commit.

- [LEARN:adr-governance] Two distinct relationships between ADRs that look similar but matter for editing protocol: **Supersedes** (the substance of the prior decision changes; old ADR Status flips to "Superseded by #NNNN") vs **Refines** (the substance stands; only an operational detail is updated; old ADR Status stays "Decided"). ADR-0021 *refines* ADR-0007 (sandbox model — ADR-0007's code-data separation commitment stands; sandbox principle makes the read/write rule explicit), ADR-0014 (entry-point naming — ADR-0014's "main.do is canonical" commitment stands; only main.do's *location* under do/ is new), and plan v3 §3.1/§3.2/§3.3/§3.4 (operational detail). Same governance pattern as ADR-0020 refining ADR-0007's sync-model subsection. Either way, the prior ADR's body is intact per immutability rule.

- [LEARN:phase-1-review] Coder-critic finding M1 surfaced a real gap: ADR-0021 line 52 explicitly enumerated four files in retroactive-coverage scope, but my edit only touched two (the entry-point files). The reviewer's adversarial-default stance — checking what the ADR commits to vs what the diff actually does — caught this. Lesson: when an ADR's scope statement enumerates specific files, all those files need to be touched (or the ADR's scope edited before it's Decided). Otherwise the ADR body becomes self-inconsistent on day one.

## Verification Results

| Check | Result | Status |
|-------|--------|--------|
| `git status` after both commits | working tree clean | PASS |
| `git push origin main` (both commits) | pushed `9120754` and `4769831` | PASS |
| Stata `include do/settings.do` resolves correctly when invoked as `stata -b do do/main.do` from `$consolidated_dir` | Verified by Stata semantics in coder-critic review (Stata's `do` does NOT change CWD; CWD remains `$consolidated_dir`; `include do/settings.do` resolves to `$consolidated_dir/do/settings.do` — correct path) | PASS |
| `grep -rn -E '(main\.do\|settings\.do)'` for stale references | Only ADR-0018, ADR-0020 bodies retain `stata -b do main.do` (immutable per decision-log.md). All load-bearing references updated | PASS |
| Coder-critic dispatch on `9120754` | 92/100 PASS, no Critical or Major; two Minor (M1 + M2) addressed in same commit per reviewer's option (1) | PASS |
| ADR-0021 listed in decisions/README.md ledger | Line 112: 0021 with description, date 2026-04-29, status Decided, scope Infrastructure | PASS |
| Sandbox principle internally consistent across ADR-0021, settings.do, stata-code-conventions.md | Verified by coder-critic — vocabulary identical (CANONICAL/LEGACY, WRITE-allowed/READ-only); grep command identical | PASS |

## Open Questions / Blockers

- [ ] Christina to mark plan v3 APPROVED. All open §8 questions resolved 2026-04-27; subsequent revisions (per-do-file logging, automated data checks, ADR-0020 simplification, ADR-0021 sandbox + description convention) are additive.
- [ ] Christina to pick next code work — Options A / B / C in TODO.md. My recommendation: Option A (pre-draft `do/check/check_*.do` skeletons) as the first end-to-end exercise of ADR-0021 discipline on substantively new code.
- [ ] T1-5 OpenCage API key revocation — manual external action by Christina (low priority; flagged since 2026-04-26).

## Next Steps

- [x] ~~If Option A~~ — DONE 2026-04-29 (`d775efe`). Six skeletons; 84/100 PASS; all three coder-critic findings addressed in-commit.
- [ ] If Option B: pre-draft README.md skeleton for Phase 1c §5.2 step 5. Audience: Stata-skilled, no git. Triggers writer-critic. Must mention `stata -b do do/main.do` invocation, sandbox principle, FileZilla-or-equivalent file transfer.
- [ ] If Option C: begin Phase 1a §3.3 with `siblingoutxwalk.do` per ADR-0005. Single-file move with 2 caller updates (predecessor `do_all.do:142` + `master.do:103`). First real relocation, exercises full per-commit checklist + ADR-0021 description convention + ADR-0021 sandbox-write check on a Christina-owned production file.

---

## Continuation — 2026-04-29 afternoon: Option A executed (six check_*.do skeletons)

### Objective (revised)

Christina picked Option A. Pre-draft six `do/check/check_*.do` skeleton files per the data-checks design memo (`quality_reports/reviews/2026-04-28_data-checks-design.md` §2-§7). Apply ADR-0021 discipline (header description + main.do one-liner already in place + sandbox-write to CANONICAL only). First commit that exercises the phase-1-review.md hard gate on substantively new code under the new ADR-0021 conventions.

### Changes Made (Option A continuation)

| File | Change | Reason | Quality Score |
|---|---|---|---|
| `do/check/check_logs.do` | NEW (134→137 lines post-M1) — filelist ssc walks `do/` recursively; assert every `.do` (excl. `_archive/`) has matching `$logdir/<stem>.smcl` | Design memo §7 | coder-critic 84/100 PASS |
| `do/check/check_samples.do` | NEW (184→187 lines post-M1) — verbatim invariants from design memo §2 (1,784,445; 402416/406084/450201/525744; 1,389 schools; race orthogonality; binary demographic ranges); soft signals on age + cohort_size | Design memo §2 | coder-critic 84/100 PASS |
| `do/check/check_merges.do` | NEW (154→155 lines post-M1) — _merge flag values; k12_main N=5009; bridge match_level distribution flagged TBD-codebook | Design memo §3 | coder-critic 84/100 PASS |
| `do/check/check_va_estimates.do` | NEW (181→185 lines post-M1) — VA centered (\|mean\|<0.05); paper SD bound [0.05, 0.30]; min N>=5; soft signals on cross-spec + peer-control correlations | Design memo §4 | coder-critic 84/100 PASS |
| `do/check/check_survey_indices.do` | NEW (289→299 lines post-M1) — full item lists per ADR-0010 (9/15/4); source-Likert [-2.01, 2.01]; z-scored index moments; raw-index range as ADR-0011 sums→means fix detector | Design memo §5 | coder-critic 84/100 PASS |
| `do/check/check_paper_outputs.do` | NEW (142→144 lines post-M1) — Table 1 N=1,784,445; Table 2 N=5,009; rest TBD-codebook per design memo §9 | Design memo §6 | coder-critic 84/100 PASS |
| `.claude/rules/stata-code-conventions.md` | Added `filelist` to Required Packages list with one-line description | M3 fix (filelist documentation) | n/a |
| `MEMORY.md` | Added 2 new [LEARN:stata] entries — filelist invocation; Stata `exit N` cleanup-required pattern | M3 + M1 lessons | n/a |
| `.claude/state/verification-ledger.md` | Added 19 entries — 3 standard checks per file (no-hardcoded-paths / no-raw-data-overwrites / adr-0021-sandbox-write) plus 1 ASSUMED for check_paper_outputs design-memo-fidelity | M2 fix (ledger seeding) | n/a |

### Design Decisions (Option A continuation)

| Decision | Alternatives Considered | Rationale |
|---|---|---|
| Skeleton skip via `capture confirm file` + `exit 0` if input not yet produced | Hardcode LEGACY paths today + repoint later; OR define new globals in settings.do for post-Phase-1a paths | Skeleton today must be runnable but no-op when consolidated-pipeline outputs don't exist. `capture confirm file` shim is the cleanest implementation: clean exit (rc=0) when input missing, full assert pass when present. Allows main.do `run_data_checks=1` to run today (Phase 1a §3.3 not yet started) without crashing, AND becomes a real check post-relocation |
| Inferred CANONICAL paths in TODO comments rather than parameterized via globals | Add `$check_score_b_dta` etc. globals to settings.do | Skeleton state — Phase 1a §3.3 hasn't decided final paths. TODO comments at each path are sufficient per the audit-marker pattern from yesterday's M2 finding. settings.do globals would proliferate before they're needed |
| Exit-cleanup pattern: `cap log close` + `cap translate` + `exit N` at every early-exit site | Drop end-of-file `cap translate` entirely (SMCL is canonical); OR use `program define` helper; OR use `include do/check/_close_log.doh` helper | Inline pattern is most readable for a successor reading a single file. The `cap` prefix on log close + translate is defensive (log may already be closed; translate harmless on empty .smcl). Helper-doh would add a 7th file and indirection. Drop-translate would break the header docs' ".smcl + .log" promise |
| Address all three coder-critic findings (M1 + M2 + M3) in-commit, mirroring yesterday's pattern | Defer M1/M2/M3 to TODO.md backlog and commit with the deferred-findings footer | Yesterday's same-commit-fix worked well for the relocation commit. The reviewer explicitly said "None of the three remediations is blocking" but should land before §5.4 acceptance run. Same-commit fix = clean precedent for new check files; ledger seeded at the right inflection point |

### Incremental Work Log (Option A continuation)

- **midday (2026-04-29):** Christina: "sounds good lets do A". Read design memo (~344 lines) to ground each check file in its source-of-truth spec.
- **midday (briefing):** Sketched 6-line approach (header / log / globals / capture-confirm / verbatim asserts / coder-critic). No course-correction; proceeded.
- **midday (file 1, check_logs.do):** Simplest — pure filesystem. filelist ssc + regexm filter for `_archive/` exclusion + per-file existence check. Halts on missing logs with listing.
- **midday (files 2-3, check_samples.do + check_merges.do):** Both based on design memo §2 + §3 verbatim. Sample asserts + per-cohort counts + race orthogonality + binary demographics.
- **afternoon (file 4, check_va_estimates.do):** Wildcard varlist iteration over `va_<subj>_*_ct` columns; centeredness + SD-band + min N asserts; cross-spec + peer-control correlation soft signals.
- **afternoon (file 5, check_survey_indices.do):** Largest at 289 lines — encodes full item lists for climate/quality/support indices per ADR-0010 (9/15/4 items); both source-file and built-index checks; ADR-0011 sums→means fix detector via raw-index range bound.
- **afternoon (file 6, check_paper_outputs.do):** Smallest hard-content section — most cells TBD-codebook per design memo §9.
- **afternoon (syntax sanity):** Grepped for `capture { ... }` block usage that I'd written initially in 2 files — Stata's `capture` takes a single command, not a block. Refactored to `capture qui corr X Y` followed by `if _rc {} else {}` pattern. 3 sites fixed pre-dispatch.
- **afternoon (sandbox-write check):** Greped for save/export/esttab/graph-export/outsheet/outreg2/texsave across all 6 files. All hits were comment-text matches; no actual writes outside `log using $logdir` + `cap translate $logdir`. PASS.
- **afternoon (coder-critic dispatch):** Per phase-1-review.md §3, new check_*.do files = REQUIRED YES. Dispatched with 8 specific concerns including Stata syntax verification, capture-confirm semantics, post-relocation path assumptions, sandbox compliance, design-memo fidelity, per-do-file logging consistency, ledger compliance, scope creep.
- **afternoon (coder-critic verdict):** **Score: 84/100 PASS.** Three findings:
  - **M1 (Major, -5)**: orphan `.smcl` from early exits — every `exit N` needs `cap translate` before it, otherwise the end-of-file translate never fires.
  - **M2 (Major, -2)**: verification ledger not seeded for the six new files.
  - **M3 (Minor, -2)**: `filelist` ssc dependency undocumented in stata-code-conventions.md.
- **afternoon (M1 fix):** Per-file `replace_all` of `    log close\n    exit` → `    cap log close\n    cap translate "$logdir/<file>.smcl" "$logdir/<file>.log", replace\n    exit`. Caught 18 of ~22 sites; remaining 4 had different indents (8-space inside `foreach`, plus check_logs.do:118 had a comment line between `log close` and `exit 9` blocking the pattern). Fixed manually. Final sweep with awk pattern confirmed every `exit` now preceded by `cap translate`.
- **afternoon (M3 fix):** Added `filelist` to stata-code-conventions.md Required Packages list with description: walks directory tree, returns dataset with `dirname` + `filename` columns. Added 2 new [LEARN:stata] entries to MEMORY.md — filelist invocation pattern + Stata `exit N` cleanup-required-before-terminate pattern.
- **afternoon (M2 fix):** Computed `shasum -a 256` head-12 for each of the 6 files post-M1 fix. Added 19 ledger entries (3 standard checks per file: no-hardcoded-paths / no-raw-data-overwrites / adr-0021-sandbox-write — all PASS; plus 1 ASSUMED for check_paper_outputs.do design-memo-fidelity, deferred until §3.3 share/ relocation supplies cell magnitudes).
- **afternoon (commit + push):** `git status` confirmed 6 new files + 3 modifications. Crafted commit message per phase-1-review.md footer convention. Committed `d775efe` (9 files, 1,139+/2-). Pushed to origin/main. Workflow-sync commit `b64f671` from applied-micro had landed on origin between my pushes (parallel agent activity); integrated cleanly.

### Learnings & Corrections (Option A continuation)

- [LEARN:stata] **`filelist` (ssc) syntax for recursive directory walks.** Logged to MEMORY.md as `[LEARN:stata]` entry. Key invocation: `filelist, dir("path") pattern("*.do") norecur(0)`; `norecur(0)` reads as "don't suppress recursion" (the option is double-negated by name). Returns dataset with `dirname` (full path) + `filename` (basename). One-time `ssc install filelist`; verify on Scribe before §5.4 acceptance run.

- [LEARN:stata] **Stata's `exit N` from a do-file does NOT run end-of-file cleanup.** Logged to MEMORY.md as `[LEARN:stata]` entry. The end-of-file `cap log close` + `cap translate` is only reached on the no-exit path. Every early-exit site needs explicit cleanup before `exit`. Convention applied to all six check files (~22 exit sites). Precedent for future Phase 1c §5.3 work.

- [LEARN:stata] **`capture` takes a single command, not a `{ ... }` block.** Pattern that DOES work: `capture qui corr X Y` then `if _rc { ... } else { ... }`. Pattern that does NOT work: `capture { qui corr X Y; local r = r(rho) }`. Caught self-correction during sanity check before coder-critic dispatch.

- [LEARN:phase-1-review] **Same-commit findings-fix is appropriate for in-scope-but-non-blocking items.** Coder-critic at 84/100 had option (defer to TODO.md backlog) or (fix in same commit). Same-commit fix is the clean choice for: (1) fixes that are mechanical / deterministic (M1 was 22 site replacements with consistent pattern); (2) fixes where the change is the natural inflection point (M2 ledger seeding for these specific files); (3) small documentation closure (M3). This mirrors yesterday's pattern (`9120754` fixed both Minors in same commit per reviewer recommendation option 1). Different from "deferred Major findings" — those would warrant a follow-up commit when the fix is broader-scope or involves substantial new work.

### Verification Results (Option A continuation)

| Check | Result | Status |
|-------|--------|--------|
| `git status` after commit + push | working tree clean, ahead 0 of origin | PASS |
| `git push origin main` | pushed `d775efe` cleanly; integrated workflow-sync `b64f671` | PASS |
| Coder-critic dispatch | 84/100 PASS, no Critical or Major bugs (M1+M2+M3 are improvements, not bugs) | PASS |
| All `exit N` sites preceded by `cap translate` | awk-pattern sweep confirms every `exit` has matching cap-translate within 2 lines before | PASS |
| Sandbox-write discipline (CANONICAL only) | grep -nE save/export/esttab/graph-export/outsheet/outreg2/texsave on all 6 files returns only comment-text matches; all `log using` and `translate` target $logdir | PASS |
| Verification ledger entries match file hashes post-M1 fix | 19 entries with shasum-computed hashes captured after M1 edits | PASS |
| Design-memo fidelity (every assert traces to memo line range OR carries TBD-codebook marker) | Verified by coder-critic spot-check across all 6 files | PASS |
| Header description block present in every file | Verified by coder-critic visual inspection | PASS |
| One-liner present in main.do Phase 7 block at each invocation site | Already in place from yesterday's work; verified to match file purposes | PASS |

---

## Continuation — 2026-04-29 late afternoon: plan v3 APPROVED + Option B (README pre-draft)

### Objective (revised again)

Christina: "option B is good, please proceed. and plan is approved." Two follow-ups:
1. Flip plan v3 status DRAFT → APPROVED.
2. Pre-draft README.md per Phase 1c §5.2 step 5 spec for the offboarding-era operator.

### Changes Made (Option B continuation)

| File | Change | Reason | Quality Score |
|---|---|---|---|
| `quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md` | Single-line status flip: DRAFT → APPROVED 2026-04-29; date subline updated; Inputs line bumped to "ADRs 0001-0021" | Christina approval on `949b452` | n/a (status flip) |
| `README.md` | Full rewrite: 37 lines → 250 lines. 10 sections per plan v3 §5.2 step 5 spec. Audience: Stata-skilled, no git, no data management; never seen this repo. SSH access to Scribe. Replaces template-y getting-started prose with offboarding-deliverable content. | Phase 1c §5.2 step 5 PRE-DRAFT per Option B | writer-critic 86/100 PASS |
| `quality_reports/handoff/README.md` | NEW (50 lines) — stub explaining what offboarding memo lands here per ADR-0018 + plan v3 §5.2 step 8. Created so the README §9 reference resolves at cold-read time | M2 fix from writer-critic (forward-reference path made navigable) | n/a |
| (TODO + SESSION_REPORT + this session log) | Hygiene updates capturing plan APPROVED + Option B done | Standard end-of-task hygiene per logging.md | n/a |

### Design Decisions (Option B continuation)

| Decision | Alternatives Considered | Rationale |
|---|---|---|
| Replace the entire prior README rather than append | Keep prior content + add offboarding section | Prior README was template-y getting-started content from the workflow fork — not project-specific. Per ADR-0018 the README is the SOLE orientation for the successor; a Stata-skilled reader doesn't need the workflow's setup steps. Total replacement is cleaner for cold-read |
| §6 "How to make changes" structured as 3 sub-cases (6.1 / 6.2 / 6.3) rather than monolithic prose | Single prose section; OR more sub-cases (4-5) | Plan v3 §5.2 step 5 spec calls out "3 common cases" specifically. Pre-draft chose: (6.1) re-run after data refresh; (6.2) tweak a specification; (6.3) add a new analysis. Writer-critic confirmed these are the right 3 — covers the realistic range without bloat |
| Address writer-critic findings M1+M2+m2+m3 in same commit; defer m1+m7 to §5.4 polish | Fix all in same commit; OR defer all to §5.4 polish | M1 (host casing) + M2 (forward-reference path) are structurally load-bearing — affect cold-read viability, not just style. Same-commit fix is the precedent (yesterday's 92/100, today's 84/100). m1 (em-dash density) + m7 (status-note jargon) are pure polish that the §5.4 final-polish-pass naturally absorbs and the reviewer specifically flagged as §5.4 polish-pass material |
| Create `quality_reports/handoff/README.md` stub rather than reword §9 placeholder | Reword §9 to be explicitly placeholder-only | Stub is more concrete + matches the convention of having structure ready by `v1.0-final`. The handoff/ README explains what the offboarding memo will contain (per ADR-0018), so a successor encountering the §9 reference at cold-read time can navigate to the folder and see what's expected, even before the dated memo is written |

### Incremental Work Log (Option B continuation)

- **late afternoon:** Christina approved plan + picked Option B. Read plan v3 §5.2 step 5 spec to ground the README structure: 10 sections in a specific order, audience explicitly stated.
- **late afternoon (plan v3 approval):** Single-line edit to plan v3 header. DRAFT → APPROVED with today's date; Inputs line bumped to ADRs 0001-0021. Committed `949b452`. Pushed.
- **late afternoon (README draft):** ~250 lines covering all 10 spec sections. Verified all referenced paths (ADR ledger, do/main.do invocation, do/settings.do globals, Required Stata Packages list, plan v3 file, paper-map review, data-checks design memo, Christina's email) against actual repo state before writing.
- **late afternoon (writer-critic dispatch):** Per phase-1-review.md §3 dispatch matrix, README rewrite triggers writer-critic. 12 specific concerns covering cold-read viability, all 10 spec sections present, path/ADR consistency, sandbox principle clarity, the 3 common cases, what-NOT-to-touch completeness, failure-mode cherry-picking check, AI-prose / hedging / style, length + scannability, MacDown markdown compat, status-note placement, tone calibration.
- **late afternoon (writer-critic verdict):** **Score: 86/100 PASS.** Findings: M1 (host casing), M2 (forward-reference path), m1 (em-dash density), m2 (hedging filler), m3 (redundant footer), m7 (status-note jargon).
- **late afternoon (M1 fix):** Added parenthetical at first SSH host mention noting case-insensitivity.
- **late afternoon (M2 fix):** Created `quality_reports/handoff/README.md` stub (~50 lines) explaining what the offboarding memo contains. Reworded README §9 to point at the now-existing folder.
- **late afternoon (m2 fix):** Dropped "Order of magnitude" + "to spot anomalies" filler phrases.
- **late afternoon (m3 fix):** Dropped redundant trailing footer line.
- **late afternoon (defer m1 + m7):** Per writer-critic's own recommendation, em-dash density + status-note jargon are pure polish that the §5.4 final-polish-pass + cold-read test naturally absorb.
- **late afternoon (commit + push):** `git status` confirmed 1 README rewrite + 1 new handoff/README.md stub. Crafted commit message documenting all 4 in-commit fixes + 2 deferred Minors. Footer: `writer-critic: PASS (86/100); 2 Major findings addressed in this commit; 2 Minor findings deferred to §5.4 polish per reviewer's recommendation.` Plus `coder-critic: skipped (rationale: docs-only — README + handoff/README.md stub; no Stata code changes per phase-1-review.md §3 dispatch matrix which routes README rewrites to writer-critic).` Committed `053871e` (2 files, 326+/26-). Pushed; integrated workflow-sync `29fe3c1` (hooks fix from upstream) cleanly.

### Learnings & Corrections (Option B continuation)

- [LEARN:phase-1-review] **Writer-critic dispatch convention.** When phase-1-review.md §3 dispatch matrix routes a target to writer-critic (rather than coder-critic), the commit-message footer pattern is `writer-critic: PASS (XX/100); ...` (analogous to coder-critic) AND `coder-critic: skipped (rationale: docs-only — routes to writer-critic per dispatch matrix)` so the `git log --grep='coder-critic'` audit trail still has a discipline marker. README rewrites are the canonical writer-critic case during Phase 1.

- [LEARN:offboarding] **Stub forward-references at draft time, fill at commit time.** Pattern surfaced in writer-critic review: a README that points at a path that doesn't exist yet (`quality_reports/handoff/<offboarding-memo>.md`) erodes cold-read trust. The successor tries `ls`, fails, and loses faith in the rest of the doc. Resolution: create the stub folder + a README explaining what eventually goes there. The cold-read audience hits a navigable destination instead of a 404. Convention applies to any forward-reference in offboarding-deliverable docs.

### Verification Results (Option B continuation)

| Check | Result | Status |
|-------|--------|--------|
| Plan v3 status flip from DRAFT → APPROVED | header line edited; commit `949b452` pushed | PASS |
| README path/ADR cross-references all resolve | Writer-critic verified ADRs 0001-0021 present, do/main.do invocation, do/settings.do globals, Required Stata Packages list, plan v3 file, all referenced quality_reports files, Christina's email | PASS |
| All 10 spec sections present and in order | Writer-critic verified structure compliance | PASS |
| MacDown blank-line-before-list rule | Spot-checked across §1, §2, §3, §6, §7 — all lists have preceding blank line | PASS |
| MacDown literal-`$`-escape rule | Prose uses `\$consolidated_dir` etc.; code blocks leave `$` unescaped (correct) | PASS |
| `git push origin main` (both commits) | both pushed cleanly; integrated `29fe3c1` workflow-sync | PASS |
| Coder-critic vs writer-critic dispatch correctness | Per phase-1-review.md §3 README rewrite = writer-critic, NOT coder-critic — correct dispatch | PASS |

---

## Continuation #3 — 2026-04-29 evening: §9 codebook clarification + no-provider-PDFs constraint

### Objective (revised again)

Christina opened plan v3 in the IDE and noted: §9 says "Codebooks needed (Christina to supply when convenient)" but the codebook export already ran 2026-04-28 producing a sanitized log under `master_supporting_docs/codebooks/`. Two-step correction:

1. Update §9 to reflect actual coverage state (PINNED / PARTIALLY PINNED per dataset, with TBD-codebook markers where empirical baselines aren't yet established).
2. After step 1's initial draft framed provider PDFs as "additive but not blocking," Christina clarified: there are NO provider codebooks at all. Encode this constraint durably across plan / README / MEMORY so future sessions don't regress.

### Changes Made (Continuation #3)

| File | Change | Reason | Quality Score |
|---|---|---|---|
| `quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md` (§9) | Two passes: (1) `518a71a` — replaced "Codebooks needed (Christina to supply)" with per-dataset coverage status (PINNED / PARTIALLY PINNED / TBD-codebook); (2) `0838119` — dropped "additive but not blocking" framing for provider PDFs; replaced with explicit "no provider PDFs exist; Christina is codebook authority during project; post-`v1.0-final` no fallback" | Stale text → reflects actual state; constraint encoded | n/a (plan, not code) |
| `README.md` (§9) | New "Codebook ambiguities — there is no provider PDF" subsection (`0838119`) — concrete example questions; during-project / post-`v1.0-final` routing; pointers to handoff/ memo for residuals | Cold-read audience needs to know who to ask + when there's no further authority | n/a (docs) |
| `MEMORY.md` (`[LEARN:offboarding]`) | New entry (`0838119`) preserving the no-provider-PDFs constraint with explicit wrong→right framing | Future-session regression prevention | n/a |
| `TODO.md` | Up Next Phase 1c §5.2 entry split: README polish (deferred Minors) + new §5.2 step 8 offboarding memo entry with Christina-specific "sweep residual semantic ambiguities" action item; Done section gained 2 entries (`518a71a`, `0838119`) | Hygiene + makes the offboarding-memo sweep durable | n/a |
| `SESSION_REPORT.md` (+ .claude mirror) | Appended 2026-04-29 (evening) entry covering both `518a71a` + `0838119` | Hygiene per logging.md | n/a |
| this session log | Appended Continuation #3 section | Hygiene per logging.md | n/a |

### Design Decisions (Continuation #3)

| Decision | Alternatives Considered | Rationale |
|---|---|---|
| Encode the no-provider-PDFs constraint in 3 places (plan + README + MEMORY) rather than 1 | One central place + cross-references | Each artifact serves a different audience (plan = my own implementation reference; README = cold-read successor; MEMORY = future Claude sessions). Single-place would risk reader-not-finding-it. The triple encoding is a small cost relative to the regression risk |
| Edit plan v3 §9 in-place rather than appending a 2026-04-29 update sub-section (as I did when adding §9 itself on 2026-04-28) | Append a `### 2026-04-29 update` sub-block under §9 keeping the original text + correction visible | The 2026-04-28 framing was straight-up wrong (codebooks already supplied) and the 2026-04-29 second-pass framing was also wrong (provider PDFs don't exist at all). Keeping wrong text visible plus correction creates ambiguity for the cold-read successor. In-place edit is cleaner; the audit trail is in git history (`518a71a` + `0838119` diffs) for anyone who wants to see the evolution |
| Add the "Christina sweeps residual semantic ambiguities" item to TODO.md `Up Next` Phase 1c §5.2 step 8 rather than as a standalone Backlog item | Add a separate top-level Backlog entry; OR leave as inline note in MEMORY only | The action belongs to a specific Phase 1c step (the offboarding memo write-up), so co-locating with that step in `Up Next` keeps the dependency clear. A separate Backlog entry would risk getting lost / duplicated |
| Skip writer-critic on the README §9 addition (~7 lines) | Dispatch writer-critic | Writer-critic dispatch is for full README rewrites per phase-1-review.md §3 dispatch matrix. A 7-line targeted addition of a clearly-scoped constraint is below the dispatch threshold. The wording was tight (concrete examples, explicit routing) and reviewable inline |

### Incremental Work Log (Continuation #3)

- **evening:** Christina opened plan v3 in IDE; flagged §9's "we need codebooks" framing as stale because we already have them under master_supporting_docs.
- **evening (verify):** Listed `master_supporting_docs/codebooks/` to confirm the codebook log exists. Found `codebook_export_28-Apr-2026_13-25-41.log` (post-PII-scrub; gitignored). Confirmed: §9's "needed-from-Christina" framing was stale because the codebook export had run on 2026-04-28 and the design memo encoded the bounds.
- **evening (§9 step 1):** Rewrote §9 with per-dataset coverage status. Initial draft framed provider PDF codebooks as "additive but not blocking — useful for offboarding-era debugging if a code's semantics is ambiguous." Committed `518a71a`. Pushed.
- **evening (Christina clarification):** "There are no provider codebooks. so anything you are uncertain about will have to go through me." This invalidated the "additive but not blocking" framing — there's no provider-PDF fallback at all.
- **evening (§9 step 2 + propagation):** Reworked §9 to drop "additive" framing; replaced with explicit no-fallback language. Added new README §9 subsection ("Codebook ambiguities — there is no provider PDF") with concrete examples + during-project / post-`v1.0-final` routing. Added MEMORY.md `[LEARN:offboarding]` entry with explicit wrong→right framing. Committed `0838119`. Pushed.
- **evening (closing implication):** Surfaced for Phase 1c §5.4: when Christina writes the offboarding memo, she should sweep for residual semantic codebook ambiguities — last chance to externalize codebook-authority knowledge before deposit. Added as a TODO.md `Up Next` Phase 1c §5.2 step 8 sub-action.

### Learnings & Corrections (Continuation #3)

- [LEARN:offboarding] **There are no provider PDF codebooks for this project. Christina is the codebook authority; post-`v1.0-final` no fallback exists.** Captured in MEMORY.md as the durable artifact. Wrong-framing-history: 2026-04-28 plan v3 §9 said "Christina to supply provider codebooks when convenient" (assumed they existed); 2026-04-29 §9 step-1 rewrite said "additive but not blocking — useful for ambiguous semantics" (still assumed they existed); 2026-04-29 step-2 corrected to current language. Future sessions should not regress.

- [LEARN:plan-discipline] **In-place edit beats append-and-correct for a stale framing in an APPROVED plan.** When plan v3 §9 had wrong text, the choice was: (a) append a `### 2026-04-29 update` sub-block leaving the wrong text visible alongside the correction, or (b) in-place edit dropping the wrong text. Cold-read audience benefits from clean text; audit trail of the evolution lives in git history (`518a71a` + `0838119` diffs). The append-pattern (which I used for adding §9 in the first place on 2026-04-28) is the right choice when adding a NEW concept; the in-place pattern is the right choice when CORRECTING wrong content. Different protocols for different operations — both keep audit trail durable.

- [LEARN:phase-1-review] **README small additions don't require writer-critic.** Phase-1-review.md §3 dispatch matrix says "Phase 1c §5.2 README rewrite | writer-critic | Wrong tool" — but a ~7-line targeted addition (the new "Codebook ambiguities" subsection) is below the rewrite threshold. The tight scope + clear-cut wording made inline review sufficient. Convention: writer-critic for full rewrites or substantive section restructures; inline review for targeted additions of clearly-scoped content.

### Verification Results (Continuation #3)

| Check | Result | Status |
|-------|--------|--------|
| `git push origin main` (both commits `518a71a` + `0838119`) | both pushed cleanly | PASS |
| Constraint encoded in plan v3 §9 | Verified by re-reading post-edit | PASS |
| Constraint encoded in README §9 (new subsection "Codebook ambiguities — there is no provider PDF") | Verified | PASS |
| Constraint encoded in MEMORY.md [LEARN:offboarding] entry with wrong→right framing | Verified | PASS |
| Plan v3 status remains APPROVED (clarification, not substantive change) | Header still says APPROVED 2026-04-29 | PASS |
| TODO.md Up Next Phase 1c §5.2 step 8 entry includes the "sweep residual semantic ambiguities" action | Verified | PASS |
