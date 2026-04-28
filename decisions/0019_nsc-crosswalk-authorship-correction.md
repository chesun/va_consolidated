# 0019: `crosswalk_nsc_outcomes.do` is Christina's; Phase 1 leaves it untouched anyway

- **Date:** 2026-04-27
- **Status:** Decided
- **Supersedes:** none (refines ADR-0017's file-ownership list)
- **Scope:** Infrastructure
- **Data quality:** Full context

## Context

ADR-0017 (Matt Naven's files stay untouched through Phase 1) listed `cde_va_project_fork/do_files/upstream/crosswalk_nsc_outcomes.do` among the 5 untouched files. That listing was based on Christina's 2026-04-27 chat instruction ("leave Matt's do files alone. for example, the nsc crosswalk").

Subsequent inspection during Phase 1 plan v3 drafting revealed the file's header attributes authorship to Christina:

> First created by Che Sun March 17, 2022
> ucsun@ucdavis.edu
> Based on code from Matt Naven

Round-1 chunk-10 audit had already flagged this: "Heavy refactor by Christina vs. archived Matt original" — Christina's 2022 version pivots from Matt's monolithic single-cohort logic to a per-cohort loop + cohort append. Matt's original is preserved at `_archive/crosswalk_nsc_outcomes_deprecated.do`.

Lineage trace (round-1 chunk-10 §File 2):

- **Input:** `$nscdtadir/nsc_xgyr<gradyear>.dta` (raw NSC per-cohort data, cleaned by Kramer)
- **Output:** `$vaprojxwalks/nsc_outcomes_crosswalk_ssid.dta`
- **Consumer:** `merge_k12_postsecondary.doh:67` reads it; downstream NSC outcome variables (`nsc_enr*`, `nsc_persist_year*`, `nsc_deg*`) flow into paper Tables 4-7.

The output IS paper-load-bearing. The producer is **not pipeline-active** — the .dta sits on disk; the pipeline reads the .dta but does not regenerate it.

Bug 93 (the inlist-precedence error at L218-219, L227-228) and the `id` macro bug at L250 are therefore in **Christina's code**, not Matt's. Christina's 2026-04-27 instruction conflated "based on Matt's logic" with "Matt's file."

By contrast, `crosswalk_ccc_outcomes.do` and `crosswalk_csu_outcomes.do` are unambiguously Matt's — both headers read "First created by Matthew Naven on February [20|25], 2018", and both contain `c(username)=="Naven"` / `c(username)=="navenm"` user-path branches. Those two stay covered by ADR-0017 unchanged.

This ADR corrects the authorship record while preserving ADR-0017's practical scope outcome (the file isn't touched in Phase 1). Christina's preference (2026-04-27): own the authorship, add a note in the file, but don't spend Phase 1 time fixing Bug 93 since (a) paper blast radius is null per chunk-10 audit, (b) re-running the producer would consume ~half a day, (c) the file isn't pipeline-active anyway.

## Decision

**Authorship correction:**

`crosswalk_nsc_outcomes.do` is **Christina-authored** (March 2022, heavy refactor of Matt's archived original). It is removed from ADR-0017's "untouched files" list. The remaining ADR-0017 list is:

- `crosswalk_ccc_outcomes.do` (Matt, 2018)
- `crosswalk_csu_outcomes.do` (Matt, 2018)
- `merge_k12_postsecondary.doh` (Matt)
- `gecode_json.py` (Matt)

**Practical scope unchanged for Phase 1:**

Despite the authorship correction, Phase 1 **does not modify** `crosswalk_nsc_outcomes.do`. Justification:

- The file is **not pipeline-active**. The pipeline consumes the static `nsc_outcomes_crosswalk_ssid.dta` artifact on disk, not the producer.
- **Bug 93 paper blast radius is null** per chunk-10 round-2 trace: `nsc_enr_uc` is consumed only by `csu_transfer_uc`; `csu_transfer_uc` is not cited in `paper/common_core_va_v2.tex`. Composite outcomes (`enr_4year`, `enr_2year`, `enr`) do NOT use `nsc_enr_uc`.
- **Phase 1 time-budget**: the cost to fix + re-run + verify is ~½ day. Phase 1c includes the offboarding acceptance run (per ADR-0018), which is the operational priority. Bug-fixing a paper-null pipeline-inactive file is not.
- **The `id` macro bug at L250** could affect `nsc_persist_year2/3/4` which is paper-relevant. Paper exposure for that specific bug is not separately traced in the audit. Acknowledged risk; not fixed in Phase 1.

**File-level documentation (Phase 1c deliverable):**

A header comment is added to `crosswalk_nsc_outcomes.do` during Phase 1c, stating:

- File is Christina's heavy refactor of Matt's archived original (Mar 2022)
- Producer is not pipeline-active; consumers read the static `nsc_outcomes_crosswalk_ssid.dta` on Scribe
- Known issues (Bug 93 inlist precedence at L218-219 / L227-228; `id` macro at L250) — left untouched in Phase 1 per this ADR
- Cite ADR-0019 for the rationale

This documentation lets a future maintainer understand the authorship, the deliberate non-fix, and the path forward (re-run the producer if the bugs need to be addressed).

**T1-1 and T1-2 status:**

Both stay **retired** from the active T1 list. T1-1 (the `id` macro test) and T1-2 (Bug 93 family count) are no longer Matt-Naven-out-of-scope-by-ownership — they're Christina-out-of-scope-by-time-budget. Same outcome (don't run); different recorded reason.

## Consequences

**Commits us to:**

- One header-comment edit in `crosswalk_nsc_outcomes.do` during Phase 1c (per ADR-0007 documentation discipline).
- ADR-0017's file list is technically corrected; the four files actually covered are listed above.
- T1-1 and T1-2 stay retired with rationale updated in TODO.md and the audit doc.
- Future maintainer reading the file header sees the authorship + the deliberate non-fix decision + path forward.

**Rules out:**

- Treating `crosswalk_nsc_outcomes.do` as Matt's in any future record. The authorship is now formally Christina's.
- Hiding the bug list in this file. The Phase 1c header comment makes the deferred bugs visible.

**Open questions:**

- If a future maintainer or referee asks for `nsc_enr_uc` coverage (UC-selectivity heterogeneity, etc.), the bugs become paper-relevant and would need a Phase-2+ fix. Trigger condition for a successor ADR.
- Whether the `id` macro bug at L250 has any paper exposure via `nsc_persist_year*` — could be traced in a future audit pass if motivation arises.

## Sources

- 2026-04-27 conversation: Christina's choice of option (B) — own authorship, add note, no Phase 1 fix
- `cde_va_project_fork/do_files/upstream/crosswalk_nsc_outcomes.do` L11-13 (header authorship)
- `quality_reports/audits/round-1/2026-04-25_chunk10-upstream.md` §File 2 (full lineage trace + "heavy refactor by Christina")
- `quality_reports/audits/round-2/chunk-10-discrepancies.md` M2 (Bug 93 paper blast radius null) + M1 (id macro at L250)
- `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` §1
- ADR-0017 (refined here — file list corrected)
- ADR-0018 (offboarding model — informs the time-budget reasoning)
