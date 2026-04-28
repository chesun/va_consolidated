# Session log — 2026-04-27 — Phase 0e Q&A walkthrough + ADR drafting

## Goal

Close out Phase 0e Q&A walkthrough (19 T4 questions) and begin writing the ADRs that the answers unlock. Christina answers questions in `quality_reports/audits/2026-04-27_T4_answers_CS.md` while Claude writes corresponding ADRs.

## Activity

### T1 empirical-tests script + Matt-Naven ownership ADR (morning)

- Drafted single consolidated `do/check/t1_empirical_tests.do` covering all 5 T1 tests from audit §3.1. Used `capture noisily` per-test isolation, `$vaprojdir`/`$vaprojxwalks` globals, log to `log/check/`.
- Christina narrowed scope: "skip anything that touches Matt's do files." Removed T1-1 (`crosswalk_nsc_outcomes.do:250`) and T1-2 (Bug 93 family — spans NSC crosswalk + `merge_k12_postsecondary.doh`). Active list reduced to 3 tests (T1-3, T1-4, T1-5).
- Wrote **ADR-0017** (`decisions/0017_matt-naven-files-untouched.md`) formalizing the constraint that previously lived only in `MEMORY.md` and `TODO.md`. Number 0017 chosen because the 0004-0016 slots in the README's pending-decisions queue are reserved for Phase 0e topics; ADR-0017 sits cleanly after them.
- Updated `decisions/README.md` index, `TODO.md` (T1 list reduced; Bug 93 backlog struck through), `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` (header banner pointing to ADR-0017; P1-1 / P2-1 / P2-9 marked retired/deferred; §3.1 T1 list rewritten; §3.3 Phase 1 playbook items 1, 5, 9 amended).

### Q-source spelunking

- Christina asked for the source of two Phase 0e questions in the audit:
  - **Q-11** — paper "averages" vs code "sums" for survey indices. Source = `paper/common_core_va_v2.tex:407` (footnote saying "Our indices are averages...") vs `caschls/do/share/factoranalysis/imputedcategoryindex.do:33-50` (literally `gen index = 0` then `replace index = index + var` for each item). Round-1 chunk-6 audit L309/L353/L772 originally surfaced.
  - **Q-12** — NSC `keep(1 3 4 5) update` vs CCC/CSU `keep(1 3)`. Source = `cde_va_project_fork/do_files/merge_k12_postsecondary.doh:67` (NSC) vs L141-143 (CCC) and L206-208 / L217-219 (CSU). Matt's file → out of scope for Phase 1 fix; Christina answered "intentional" anyway.
- Also dug up the source for chunk-5 disc N2 (naming-system fragmentation) — round-1 chunk-5 doc L1087-1097, L1143, L1159.

### Phase 0e walkthrough complete

- Christina finished `quality_reports/audits/2026-04-27_T4_answers_CS.md` — all 19 questions answered.
- Buckets: 7 intentional/no fix; 3 Matt-out-of-scope; 5 Phase 1 actions; 3 defer/weak fix; 1 verify-upstream-later.
- Two big simplifications:
  1. **Q-6 cascade** — `_tab.do` CSV outputs are local-review-only; paper tables come from `share/`. Downgrades P2-5 and P2-6 to P3 (mtitles bugs don't reach paper).
  2. **Q-9 deprecation** — entire `caschls/do/share/siblingvaregs/` regression subtree (~30 files) is deprecated; production sibling-VA is in canonical `cde_va_project_fork/do_files/sbac/va_{score,out}_all.do` via the 16-spec framework. Verified by tracing `macros_va_all_samples_controls.doh` (`s`, `ls`, `as`, `las` codes confirm sibling samples produced inside canonical loop) and chunk-9 producer-chain conclusion (paper tables come from `share/`, not `siblingvaregs/`).
- `siblingoutxwalk.do` carve-out: still production (builds family crosswalk consumed by canonical sample construction) — relocates separately per ADR-0005.

### ADR drafting (interactive approval)

- Cadence agreed with Christina: draft each ADR in chat, get explicit "Approved" before writing to disk. Going in dependency order so each ADR can cite the ones already written.
- Proposed ordering (12 ADRs total): 0004 sibling-VA canonical pipeline → 0005 siblingoutxwalk relocation → 0006 vam.ado pinning → 0007 external crosswalks vendoring → 0008 prior-score v1 canonical → 0009 paper-α canonical → 0010 sums→means fix → 0011 _tab.do CSVs local-only → 0012 mattschlchar gate → 0013 old paper draft preserved → 0014 Filipino/Asian recoding → 0015 pooledrr rename.
- Original queue items dropped: 0013 (sample-restriction map — Q-14 deferred); 0014 (mtitles convention — answered "intentional, completeness" Q-17/Q-18); 0016 (Bug 93 patch — retired per ADR-0017).
- **ADR-0004 written** (`decisions/0004_sibling-va-canonical-pipeline.md`) — declares `va_{score,out}_all.do` canonical, deprecates `caschls/do/share/siblingvaregs/` regression files (~30 files to `_archive/`). Settles chunk-5 N2, Q-10 DK controls, original ADR-0004 placeholder. README index updated.
- **ADR-0005 drafted** (siblingoutxwalk.do → `do/sibling_xwalk/`) — pending Christina approval at end of session.

## Decisions made (committed)

- ADR-0017: Matt Naven's files stay untouched through Phase 1 (Decided).
- ADR-0004: Sibling-VA canonical pipeline (Decided).
- T1 active list reduced 5→3.

## Open questions

- ADR-0005 awaiting approval (drafted, not yet written to disk).
- Whether sex-coding-inversion (P3-51) needs its own ADR or just an inline code comment when touched. Decide at end of ADR sweep.
- Phase 1 plan v3 — start drafting once all ADRs are written, or earlier?

## Status

- Phase 0e Q&A: **COMPLETE** (Christina answered all 19).
- ADR queue progress: 1 of 12 written + 1 drafted.
- Next: write ADR-0005, then draft ADR-0006 (vam.ado pinning).

---

<!-- primary-source-ok: sun_2026 -->
(Note: "C. Sun 2026-04-25" below refers to Christina Sun, project author, not an external citation.)

## 2026-04-27 (afternoon-evening) — ADR sweep + architecture pivot + T1 closeout

### ADRs written (5 more)

- **ADR-0005** — `siblingoutxwalk.do` relocation to `do/sibling_xwalk/`. Drops out cleanly from ADR-0004; one file move + two caller updates in Phase 1.
- **ADR-0006** — `vam.ado` pinned at v2.0.1 + noseed customization. Vendored to `ado/vam.ado`; version line updated to `2.0.1.1`. Hit primary-source-first false positive on "C. Sun 2026-04-25" (project author, not citation) — escape hatch comment used.
- **ADR-0007** — Code-data separation + sync model + handoff endpoint. **Major architecture decision.** Triggered by Christina's clarifying question: GitHub holds code/docs/tables/figures only; Scribe `consolidated/` is non-git working copy; rsync-only sync from local Mac to Scribe (no `.git/` ever on Scribe); GitHub becomes frozen archive at handoff to non-git senior coauthor. SSH ControlMaster recommended for ergonomics.
- **ADR-0008** — External crosswalks (k12_ccc, k12_csu) vendored as defensive backup on Scribe `consolidated/data/raw/upstream/` (Path B). Runtime unchanged — Matt's merge code still reads from Matt's user dir. Resolves ADR-0017's open question on Matt's data files.
- **ADR-0009** — Prior-score v1 canonical for paper; v2 preserved as exploratory. v2 estimator loop kept (option value); paper producers hardcode v1 paths.
- **ADR-0010** — Paper-α from `indexalpha.do`; `alpha.do` archived as exploratory. Paper text at L407 footnote needs update from 20/17/4 items → 9/15/4 items in Phase 1.

### ADR-0011 drafted

Survey-index sums→means fix in `imputedcategoryindex.do` and `compcasecategoryindex.do`. Two-line code edit per file. Statistically inert post-z-scoring but restores paper-vs-code consistency. Awaiting approval.

### Architecture pivot (ADR-0007 details)

Christina raised two concerns that reshaped the architecture:

1. **Network exposure**: cloning GitHub remote on Scribe creates exfiltration channel. Even with .gitignore, accidental `git push` of staged data files is possible. Decision: no `.git/` on Scribe ever; rsync-only sync from local Mac. SSH ControlMaster handles auth ergonomics (no 2FA on Scribe = single auth per session).
2. **Handoff to non-git successor**: senior coauthor lacks git skills. Decision: GitHub becomes frozen archive at Phase 1 end; Scribe becomes canonical post-handoff; HANDOFF.md folded into a single living `README.md` (rewritten in Phase 1 for the actual audience).

Documentation discipline rule baked into ADR-0007: **all Phase 1 work documented with successor in mind**. ADRs cite sources; session logs date-stamp; commit messages explain WHY. Audit trail = `decisions/` + `quality_reports/`.

### T1 empirical tests CLOSED

Christina re-ran T1 tests on Scribe after T1-3 path fix. Both round-1 (rc=601) and round-2 (clean) logs in `quality_reports/audits/`.

- **T1-3** (school_id == cdscode): **VERDICT 1:1** (N=5009; n_tag_diff=0; both directions 0). P2-3 and P2-11 downgrade to **cosmetic rename only** in Phase 1. No regression re-runs needed.
- **T1-4** (mtitles count): **BUG FIRED** in all 4 CSVs (49/33/33/33 cols vs 24 declared mtitles). Per Q-6, CSVs not paper-feeding → cosmetic for paper integrity.
- **T1-5** (OpenCage key): manual reminder — Christina to revoke.

Audit doc §3.1 updated with verdicts; TODO entries marked done.

### Path fixes to t1_empirical_tests.do

- Server uses `do_files/` and `log_files/` (not `do/` and `log/`). Updated logdir to `log_files/check/` and instruction header. Verified via `cde_va_project_fork/log_files/` structure.
- T1-3 path was wrong (`estimates/.../va_all.dta`); fixed to `estimates/va_cfr_all_v1/va_est_dta/va_all_schl_char.dta` (the file actually loaded by `va_het.do:155` right before the buggy cluster regression).

### Status update

- ADR queue progress: **7 of 12 written** (0004-0010), 1 drafted (0011).
- Remaining: 0011 sums→means, 0012 _tab.do CSVs local-only (Q-6/Q-17/Q-18), 0013 mattschlchar gate (Q-5), 0014 old paper draft preserved (Q-13), 0015 Filipino/Asian recoding (Q-15), 0016 pooledrr rename (Q-16). Five remaining after 0011.
- T1 tests: CLOSED.
- Phase 0e Q&A: CLOSED.
- Audit doc: synced with ADR-0017, T1 results, ADR cross-refs.
- Next after 0011: 0012 _tab.do CSVs local-only, then continue down the list.

---

<!-- primary-source-ok: sun_2022, sun_2026 -->
(Note: "Che Sun" / "Sun 2022" / "Sun 2026-04-27" below refer to Christina Sun, project author, not external citations.)

## 2026-04-27 (late evening) — ADR sweep complete + Phase 1 plan v3 + offboarding pivot + NSC crosswalk authorship surprise

### ADRs 0012-0016 written + index pruned

- ADR-0012: `_tab.do` CSV outputs are local-review-only (Q-6 cascade settles P2-5, P2-6, P3-62, P3-63).
- ADR-0013: mattschlchar.do gate kept (Q-5).
- ADR-0014: Old paper draft `common_core_va.tex` preserved as historical artifact (Q-13).
- ADR-0015: Filipino/Asian recoding intentional, documented in code (Q-15).
- ADR-0016: pooledrr renamed by scope across 4 producers (Q-16).
- decisions/README.md pending-decisions list pruned: most original placeholders subsumed by 0004-0017; 2 remain deferred (cohort coverage, Stata version pin).

**Phase 0e ADR sweep COMPLETE: 13 ADRs (0004-0016) decided + ADR-0017 from earlier today.**

### Commit + push (mid-evening)

Commit `5d5f62d` pushed to origin/main. Captures 13 new ADRs + ADR-0017 + T1 .do file + audit doc updates + TODO sync + session log + SESSION_REPORT entry.

### Phase 1 plan v3 drafted

Written at `quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md`. ~10 sections covering: v2-vs-v3 deltas, sub-phase structure (1a/1b/1c), Phase 1a Scribe sync setup + folder build-out + script relocation + main.do construction + golden-master verification, Phase 1b bug fixes by priority, Phase 1c cosmetic cleanup + offboarding prep, milestones M1-M9, risk register, open questions (originally 5).

### Architecture pivot — offboarding model (ADR-0018)

Christina clarified: there is no live handoff event. Her exit is offboarding from the lab; deliverable goes to **Kramer (lab data-management custodian)**, not a successor. Successor is unknown at offboarding time. README is the only orientation. Phase 1 plan v3's "handoff" framing is wrong.

ADR-0018 written formalizing:

- Endpoint = offboarding date, not handoff event
- Kramer = custodian (preserve + transfer), not maintainer
- Successor = unknown; README is sole orientation
- Tag = `v1.0-final` (not `v1.0-handoff`)
- **Acceptance criteria before tag**: Christina runs full pipeline end-to-end on Scribe (`stata -b do main.do`); README cold-read test by friendly non-Christina lab member. Both must pass. Non-negotiable.
- No "Christina available for 30 days" buffer

ADR-0018 supersedes ADR-0007's "Handoff endpoint" subsection only; the rest of ADR-0007 (sync model, code-data separation, .gitignore policy) stands.

Plan v3 updated to reflect ADR-0018: §1, §2, §5.2 step 8 (offboarding deliverable memo to Kramer), §5.3 acceptance run + cold-read test, §6.4 milestones M8/M9, §7 risk register (cold-read failure + acceptance-run failure), §8 Q3-Q5 resolved.

Commit `e7e71d5` pushed to origin/main.

### Plan §8 open questions worked through

- **Q1 (main.do Matt-file calls)**: Christina pushed back on my §3.4 example — she didn't think the pipeline invoked the crosswalks. Verified via grep: ZERO production invocations of `crosswalk_nsc/ccc/csu_outcomes.do` (only the file's own header docstring matches). The crosswalk .dta outputs are static, run-once-cached artifacts; `merge_k12_postsecondary.doh` reads them. Plan §3.4 corrected to remove crosswalk invocations from main.do. Resolution: settings.do gets a `$matt_files_dir` global; Christina's relocated sample-construction files reference Matt's `merge_k12_postsecondary.doh` via that global. No predecessor-bridge wrapper needed.
- **Q2 (paper LaTeX scope)**: out of scope. Phase 1 doesn't touch paper LaTeX. ADR-0010 footnote update + ADR-0014 old-draft header note happen in `va_paper_clone`, NOT in this repo. Consolidated `paper/` folder stays empty per ADR-0001.

### NSC-crosswalk authorship surprise

While checking Q1, found `crosswalk_nsc_outcomes.do` header reads "First created by Che Sun March 17, 2022 ... Based on code from Matt Naven". The file is **Christina-authored**, not Matt's, despite Christina's earlier instruction "leave Matt's do files alone. for example, the nsc crosswalk." Round-1 chunk-10 audit had already flagged this: "Heavy refactor by Christina vs. archived Matt original."

CCC and CSU crosswalks unambiguously Matt's (his name + his user paths in headers).

Christina asked for input/output lineage trace before deciding what to do. Lineage from round-1 chunk-10 §File 2:

- INPUT: `$nscdtadir/nsc_xgyr<gradyear>.dta` (cleaned by Kramer)
- OUTPUT: `$vaprojxwalks/nsc_outcomes_crosswalk_ssid.dta` (consumed by `merge_k12_postsecondary.doh:67`)
- DOWNSTREAM: nsc_enr*, nsc_persist_year*, nsc_deg* — flow to paper Tables 4-7 via merge_k12_postsecondary.doh:79-90

Output IS paper-load-bearing in general. Bug 93 specifically (the `nsc_enr_uc` precedence error) is paper-null per chunk-10 round-2 trace (`csu_transfer_uc` not cited in paper, composite outcomes don't use `nsc_enr_uc`). The `id` macro bug at L250 could affect `nsc_persist_year2/3/4` which IS paper-relevant.

Three options surfaced for Christina:
- (A) Refine ADR-0017 + add Bug 93 NSC fix to Phase 1b (~½ day work: edit + re-run + verify)
- (B) Documentation-only ADR-0019 noting authorship but no Phase 1 work change
- (C) Status quo — keep treating as Matt's

**Christina's decision pending.**

### Status

- ADR sweep: 18 ADRs Decided (0001-0018).
- Phase 1 plan v3: DRAFT. §8 Q1 + Q2 resolved. NSC-crosswalk authorship question pending Christina's choice from (A)/(B)/(C).
- Commits pushed: 5d5f62d (Phase 0e closeout), e7e71d5 (ADR-0018 + plan v3 draft).
- Up next: Christina's decision on NSC-crosswalk scope; then plan moves to APPROVED; then Phase 1a §3.1 begins.

---

## 2026-04-27 (end of day) — ADR-0019 + plan v3 §8 closeout

Christina chose option (B) for the NSC-crosswalk authorship question: own authorship in the record, add a Phase 1c header note in the file, but don't change Phase 1 scope (no fix, no re-run). Reasoning: file isn't pipeline-active, Bug 93 paper-null per audit, ½-day fix not justified vs. offboarding acceptance run.

ADR-0019 written formalizing the authorship correction + the time-budget rationale for non-fix. ADR-0017 file list narrowed to 4 (CCC + CSU crosswalks, merge_k12_postsecondary.doh, gecode_json.py). T1-1 and T1-2 stay retired with rationale updated (Christina-time-budget for NSC instances; Matt-ownership for CCC/CSU instances).

Plan v3 §8 fully resolved. Status flipped from "DRAFT pending" to "DRAFT ready for Christina to mark APPROVED and start Phase 1a §3.1." Audit doc §3.1 + TODO.md T1-retired entries synced with new rationale.

Commit `f113ba1` pushed to origin/main.

### Final status (end of 2026-04-27)

- **ADR ledger: 19 Decided** (0001-0019). Phase 0e fully closed.
- **Phase 1 plan v3**: ready for APPROVED. Phase 1a §3.1 (Scribe sync setup) is next.
- **3 commits pushed today**: 5d5f62d, e7e71d5, f113ba1.
- **T1 tests**: 2 of 3 active tests run successfully; T1-5 (OpenCage revoke) pending manual.
- **Documentation discipline (per ADR-0007)**: every decision today captured in ADRs + session log + audit cross-refs. Audit trail is durable.
- **Outstanding for Christina**: mark plan v3 APPROVED when ready; T1-5 OpenCage key revocation when convenient.
