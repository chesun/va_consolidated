# Session Log: 2026-04-25 -- Master-file audit, consolidation plan, foundational ADRs

**Status:** IN PROGRESS

## Objective

After yesterday's onboarding and paper read, today's session covers the next layer of preparation work for the consolidation:

1. Audit `do_all.do` (fork) and `master.do` (caschls) for completeness against on-disk file inventories.
2. Resolve unreferenced/orphaned scripts via Christina's dispositions and lineage tracing.
3. Bucket non-pipeline files into `archive/`, `upstream/`, `local/` per disposition.
4. Draft the consolidation plan; iterate on Christina's feedback.
5. Write foundational ADRs 0001-0003.

The session does NOT begin Phase 0 deep-read or any consolidation-step migration; those are gated on plan-v2 acceptance and ADR foundations being in place.

## Key Context

- Yesterday's work: 5-round Q&A onboarding, paper read end-to-end, paper map produced (`quality_reports/reviews/2026-04-24_paper-map.md`).
- Hook fixes shipped from upstream workflow repo over a 4-iteration field-driven cycle (separate session log: `2026-04-25_primary-source-hook-iterative-fixes.md`). Hook is now functional with full filter chain + escape-hatch repair + display-string round-trip safety.

## Changes Made

| File | Change | Reason | Quality Score |
|------|--------|--------|---|
| `cde_va_project_fork/.../changes_by_che` (commits c7867e4, 85a97e7, ab0395d, 5d9956f, cce7c84, 731610f) | Archive non-production files; register prior_decile in pipeline; reword sib_lag comment; archive va_scatter_plot; introduce upstream/ for crosswalk_nsc_outcomes | Consolidate inventory + fix bit-rot bug | n/a |
| `caschls` (commits f0c17d7, 83767d6, e057a09, cb275af, ea165d3, c493b8e, f59fb64) | Archive deprecated/orphan files; introduce do/upstream/ + do/local/; commit user's master.do refactor (double-slash fix + outcomesumstats unwrap) | Consolidate inventory in symmetry with fork | n/a |
| `va_consolidated/quality_reports/reviews/2026-04-25_master-file-audit.md` | Created; 3 update rounds (initial audit, round-2 dispositions, final close) | Document the inventory completeness check | -- |
| `va_consolidated/quality_reports/plans/2026-04-25_consolidation-plan-draft.md` | v1 → v2 rewrite incorporating Christina's feedback | Phase 0 deep-read elevated to BLOCKING; py_files preserved; root-level do/ + py/; main.do not master.do; siblingoutxwalk relocation flagged | -- |
| `va_consolidated/CLAUDE.md` | Folder structure section refactored: dropped scripts/; added root-level do/ + py/ + ado/ + main.do + settings.do | Match locked v2 plan | -- |
| `va_consolidated/scripts/ → do/ + py/` | Moved .gitkeep markers; scripts/ dir gone | Per Christina's direction | -- |
| `va_consolidated/quality_reports/onboarding/2026-04-25_context-dump.md` | Added Section 10 (Claude's follow-up questions); committed Christina's fills (commit 91b7a26) | Capture follow-ups; commit user's answers | -- |
| `va_consolidated/decisions/0001_consolidation-scope.md` | Created (commit aaf7005) | Lock in-scope = fork@changes_by_che + caschls@main; out = ca_ed_lab-common_core_va, common_core_va_workflow_merge | -- |
| `va_consolidated/decisions/0002_runtime-server-only.md` | Created (commit 9b82d24) | Lock Scribe-only runtime; settings.do hostname-branched from day one | -- |
| `va_consolidated/decisions/0003_languages-stata-primary-python-upstream.md` | Created (commit bdcfa2a) | Lock Stata primary + Python upstream-only (geocoding); R out | -- |
| `va_consolidated/decisions/README.md` | Index populated; pending decisions list added | Track ADRs 0004-0016 deferred until Phase 0 completes | -- |

## Design Decisions (cross-cutting; ADRs document each individually)

| Decision | Alternatives Considered | Rationale |
|----------|------------------------|-----------|
| Two predecessor repos in scope | (3 originally per old README; 4+ candidate forks discovered) | Christina's fork supersedes Matt's origin; 2022 merge attempt was abandoned and produced nothing useful |
| Server-only runtime | Local + server hybrid | Restricted-access data; pipeline never ran locally |
| Stata primary, Python upstream-only | Stata only (initial assumption) | Christina corrected: py_files contains real geocoding code worth preserving |
| Phase 0 deep-read BLOCKING | Aggressive migrate-as-we-read | Christina's directive: "EVERY SINGLE LINE OF EVERY SINGLE FILE before we lock in any design decisions" |
| Root-level do/ + py/ (no scripts/ parent) | Template default scripts/{stata,python,R}/ | Christina explicit |
| main.do entry-point name | master.do (legacy from predecessors) | Phase out master naming; analogous to Python's main.py |
| Copy + register migration (drop predecessor history) | Subtree-merge each predecessor | Predecessors stay accessible for archeology; consolidated history starts clean |

## Incremental Work Log

- **early session:** Began master-file audit. Found do_all.do at 56/66 referenced; master.do at 89/112 referenced (with one false positive due to a double-slash that Christina later fixed). Wrote audit doc (2026-04-25_master-file-audit.md).
- **mid-session:** Resolved Section 10 follow-ups via Q&A. Christina-confirmed dispositions for 4 caschls files; lineage-traced 6 more (5 archive, 1 false positive). prior_decile_original_sample.do identified as missing-from-pipeline production code; added to do_all.do as fix(do_all) commit. va_scatter_plot.do archived (deprecated). sib_lag comment reworded (intentional reactivation, not in paper but kept).
- **mid-session:** Christina extended A6 disposition: CCC/CSU crosswalks are upstream too, not just Matt-superseded. Moved them out of caschls archive/matt_original/ to a new do/upstream/. Same disposition applied to fork's crosswalk_nsc_outcomes.do. enrollmentconvert.do moved to do/local/ per its own header. poolenrollment.do archived (orphaned, superseded by poolgr11enr.do).
- **late session:** Plan v1 written and committed. Christina reviewed; major feedback led to plan v2 rewrite with Phase 0 deep-read as a BLOCKING phase, plus folder-structure changes and a number of N1-N3 follow-up questions.
- **late session:** CLAUDE.md folder structure refactored to match plan v2. scripts/ removed; do/ + py/ at root with .gitkeep markers. ADRs 0001-0003 written and committed atomically; the decisions/README.md index lists them and notes ADRs 0004-0016 as pending Phase 0 completion.

## Learnings & Corrections

- [LEARN:domain] py_files in both predecessors contains upstream geocoding scripts (Matt's work). NOT dead. Outputs are static inputs to Stata pipeline; scripts preserved for record-keeping. Initial onboarding answer was "dead/unused"; Christina corrected in §10 B1.
- [LEARN:workflow] When user requests "deep read of EVERY SINGLE LINE OF EVERY SINGLE FILE" before consolidation, this elevates from a per-file activity during migration to a hard BLOCKING gating phase. Plan must reflect this; folder restructure must wait for the audit to complete.
- [LEARN:domain] siblingoutxwalk.do lives in caschls/do/share/siblingvaregs/ (not siblingxwalk/) despite being a sibling-crosswalk pipeline step. Relocation needs a dependency trace before the move (could otherwise introduce a new circular reference).
- [LEARN:domain] Two folders on Scribe contain related code; their reconciliation is deferred to ADR-0016 / Phase 0d. Will become apparent once we deep-read settings.do across both predecessors.
- [LEARN:workflow] Atomic commit discipline scales: today produced ~20 commits across 3 repos. Each is a single logical change with a clear message. Trade-off: high count vs. high bisect-ability. User confirmed preference.

## Verification Results

| Check | Result | Status |
|-------|--------|--------|
| Audit doc covers both predecessor repos completely | 56/66 fork; 89/112 caschls (after false positive correction) | PASS |
| All flagged files have a confirmed disposition | All 22+ files have decisions; 12 moves committed | PASS |
| Plan v2 incorporates all of Christina's feedback (Q1-Q6, M1-M3, plus directives) | Confirmed in v2 review | PASS |
| ADRs 0001-0003 follow the template | Yes; index populated | PASS |
| No edits to load-bearing files outside scope | Restricted to predecessors and va_consolidated docs/ADRs | PASS |
| Working tree clean across all three repos | va_consolidated clean; caschls has macOS noise (.DS_Store, Icon\r) deliberately untouched | PARTIAL (noise unrelated to consolidation work) |

## Open Questions / Blockers

- [ ] N1: siblingoutxwalk.do relocation -- needs Phase 0b dependency trace before moving from siblingvaregs/ to sibling_xwalk/
- [ ] N2: Server-folder reconciliation -- which of the two server folders is canonical, what's stale, which is tracked by which local repo. Resolved via Phase 0d.
- [ ] N3: Stata version compat revisit timing -- after consolidation Phase 1 completes? Before any submission-readiness work?

## Next Steps

- [ ] Phase 0a deep-read of the foundation chunk (settings.do x2, macros_va.doh, custom vam .ado, master.do/do_all.do entry points)
- [ ] Continue Phase 0a per the plan §6 sub-deliverables (per-file audit, dependency graph, path-reference catalog)
- [ ] Phase 0d server-folder reconciliation (Christina runs diagnostic commands on Scribe; Claude synthesizes)
- [ ] Phase 0e design lock; Christina sign-off; THEN Phase 1 migration begins.

---

## Update — Phase 0a CLOSED (2026-04-25)

All 10 deep-read chunks complete. Marathon session; ~10 commits. Major resolutions:

- **Chunk 1 (foundation)**: vam = unmodified Stepner v2.0.1 (no customization); two-folder server geometry mapped (N2 RESOLVED — co-resident, cross-wired); macros_va.doh `asd_str` and missing-`;` bugs fixed in commits `e8dd083`, vam.ado `noseed` bug fixed in `0202251`.
- **Chunk 2 (helpers)**: v1 prior-score table verified line-by-line; v2 had wrong dates in user's table (header transcription bug — code uses L5 = 5-year lag); `_scrhat_` confirmed as orthogonal third axis (predicted vs observed prior scores), not part of v1/v2.
- **Chunk 3 (VA core)**: output-filename grammar formalized (`<prefix>{_p}_<outcome>_<sample>_sp_<ctrl>_ct{_<fb_var>_lv}.ster`); `sp/ct/lv` confirmed literal separators not macros; vam compat fully verified (every invocation works on Stepner v2.0.1).
- **Chunk 4 (pass-through)**: all paper Tables 4-7 + Figs 5-6, C.1-C.2 producers mapped; `_m`/`_wt`/`_nw` naming tokens resolved; SE clustering audit reveals `va_het.do:158` uses `cdscode` not `school_id` (deviation flagged).
- **Chunk 5 (sibling)**: **N1 RESOLVED — SAFE to relocate `siblingoutxwalk.do`** to sibling_xwalk/; only single edit at master.do:103. Sibling-matching specifics documented (5-component address join + last_name; `group_twoway` transitive closure; 10-child cap). 4-spec convention `og/acs/sib/both` confirmed.
- **Chunk 6 (survey VA)**: Paper Table 8 producer chain mapped. Sum-vs-mean discrepancy: code computes sum, paper says "averages"; z-standardization makes coefficient invariant.
- **Chunk 7 (data prep)**: **Distance-FB Row 6 RESOLVED** — `d` token wired in `macros_va_all_samples_controls.doh` (not the macros_va.doh I'd checked). `enrollmentclean.do:21` female-encoding bug found (real bug). ACS only covers 2010-2013 (potential coverage gap).
- **Chunk 8 (samples)**: Sample-restriction map definitively resolved — both `<7` per-cell and `<=10` cohort cuts exist (different rows, not contradictory). False alarm raised about archived `sum_stats.do`; chunk 9 corrected.
- **Chunk 9 (share/explore)**: All paper Tables 1-8 + Figs 1-4 producers in `share/` — closed loop. Modern `share/sample_counts_tab.do` produces `counts_k12.tex` (chunk 8 alarm Q8.1 RESOLVED). scrhat pipeline confirmed exploratory-only.
- **Chunk 10 (upstream)**: 1 Python script (Census Geocoder API, free, keyless, run-once-cached). Cross-repo crosswalks: 3 in-scope, 2 external static. **CRITICAL Bug 93** in `crosswalk_nsc_outcomes.do:219` (operator-precedence error silently codes UC Merced as `nsc_enr_uc=1` even without NSC record — paper-load-bearing).

### Phase 0a totals

- ~150 files audited
- ~101 bugs/anomalies inventoried
- ~30 user-facing questions queued (Q1.x-Q9.x)
- 80+ naming tokens catalogued
- 16 ssc/community packages
- 5 external static inputs identified

### Side correction on bit-rot risk

Christina's "last full pipeline run was 2023" claim revised to mid-2024 based on `counts_k12.tex` mtime 2024-07-04 (commit `0ce6209`). Bit-rot window narrows from ~3 years to ~21 months. Consolidation risk lower than initially feared.

### Companion audit docs produced

`quality_reports/audits/`:

- `2026-04-25_deep-read-audit.md` (master, ~2500 lines)
- `2026-04-25_path-references.md` (path-translation catalog)
- `2026-04-25_dependency-graph.md` (call-graph + cross-repo edges)
- `2026-04-25_chunk5-sibling.md` (1168 lines per-file detail)
- `2026-04-25_chunk6-survey-va.md` (872 lines)
- `2026-04-25_chunk7-data-prep.md`
- `2026-04-25_chunk8-samples.md`
- `2026-04-25_chunk9-share-explore.md` (477 lines)
- `2026-04-25_chunk10-upstream.md` (~3300 words)

## Phase 0a-v2 — independent blind verification (proposed; awaiting user signoff)

User raised concern that round-1 agents may suffer from confirmation bias / echo-chamber drift / detail-invention during synthesis. Given consolidation is load-bearing and the bug inventory is ~101 items (some paper-load-bearing), Phase 0a-v2 is a blind re-audit of every Phase 0a finding.

### Three-tier verification structure

User's sharper question: "what insurance do I have that you won't yourself suffer from confirmation bias when reading source for high-priority findings?" Honest acknowledgment: I synthesized round 1, so my reading of source is contaminated. Revised plan removes me as adjudicator for findings I produced. Three tiers:

| Tier | What's verified | Adjudicator |
|---|---|---|
| **T1 — Empirical (gold standard)** | Bug 93 NSC UC precedence; Distance-FB `d` token wiring; v1/v2 prior-score variable construction; vam factor-variable behavior | Christina, by running 5-15 lines of Stata on Scribe |
| **T2 — Adversarial third agent** | Discrepancies between rounds 1 and 2; high-stakes claims about paper-output mappings, sample-restriction map, output-filename grammar | Independent third agent with explicit "find evidence the claim is wrong" brief |
| **T3 — Objective code facts** | Line numbers, syntax declarations, file existence, byte-identical diffs | My direct reading + deterministic checks (grep, wc, diff) — bias risk near-zero for these |

### Cost / scope

- ~10-25 hours total work, mostly compute on agents
- ~30-90 min of Christina's active time (concentrated on T1 verifications)
- Final deliverable: `2026-04-XX_deep-read-audit-FINAL.md` containing only verified findings; round-1 and round-2 preserved in subdirs for archeology

### Awaiting user signoff

3 design questions surfaced; user reviewing the revised tier structure before I execute.

## Updated Open Questions / Blockers (2026-04-25 close)

- [x] N1: ~~siblingoutxwalk.do relocation~~ — RESOLVED in chunk 5 (SAFE; single edit at master.do:103)
- [x] N2: ~~Server-folder reconciliation~~ — RESOLVED in chunk 1 (co-resident, cross-wired; canonical = `/home/research/ca_ed_lab/projects/common_core_va`)
- [ ] N3: Stata version compat revisit timing — DEFERRED, low risk
- [ ] **Phase 0a-v2 verification plan** — awaiting user signoff before execution
- [ ] ~30 user-facing questions consolidated into Phase 0e walk-through (post-verification)
- [ ] Bug-priority triage (P1: Bug 93 NSC UC precedence; P2/P3 for the rest)

## Next Steps (revised)

1. **Christina decides on Phase 0a-v2 plan** — accept tier structure, propose changes, or skip verification entirely
2. **If accepted**: Phase 0a-v2 execution (T1 + T2 + T3 verifications across all 10 chunks)
3. **Phase 0e (design lock)**: against verified-final findings, lock ADRs 0004-0016 + write consolidation plan v3
4. **Christina sign-off on plan v3**
5. **Phase 1: Migration**
