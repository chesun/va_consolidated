# 0012: `_tab.do` CSV outputs are local-review-only; paper tables come from `share/`

- **Date:** 2026-04-27
- **Status:** Decided
- **Scope:** Specification
- **Data quality:** Full context

## Context

Phase 0a audits across chunks 4 and 5 surfaced multiple `mtitles`, column-mapping, and labeling concerns in `_tab.do` files inside `cde_va_project_fork/do_files/sbac/` and `caschls/do/share/siblingvaregs/`. Examples:

- **P2-5** (chunk-5 disc M1): `reg_out_va_sib_acs_tab.do` L82-88 — uses FB-test column titles for what is structurally a persistence-on-VA regression table.
- **P2-6** (chunk-4 disc M4): `reg_out_va_all_tab.do` declares `mtitles` for 24 columns but `eststo` accumulates 32. T1-4 verified the bug fired (CSVs have 49 / 33 / 33 / 33 columns vs declared 24).
- **P3-62** (chunk-9 disc A4): `reg_out_va_tab.do` silently drops `lasd_ct_p` (5th sample×control combo).
- **P3-63** (chunk-9 disc M5): `va_var_explain_tab.do` declares 5 controls but only 4 columns.

These all looked like potential paper-table integrity bugs during the audit. Christina's Phase 0e answers reframed the entire class:

- **Q-6**: "[`reg_out_va_sib_acs_tab.do`] does not feed paper tables, the csv outputs are for local review only. **All paper tables are produced by code in `share/` folder.**"
- **Q-17** (covers P2-5, P2-6, P3-62, P3-63): "Treat all irregularities in table production as intentional — the code usually includes the full range of results for completeness but end product depends on what senior coauthors want to show in the paper."
- **Q-18** (specific to P3-62): "same as above" — `lasd_ct_p` drop is intentional / coauthor preference.

The chunk-9 audit had already independently established that all paper Tables 1-8 + Figs 1-5 producers live in `do/share/` (the producer chain closed loop). The `_tab.do` files in `do_files/sbac/` and `siblingvaregs/` produce CSV/XLSX scratch files for **local review** as Christina iterates with senior coauthors to decide what shipping table layouts should look like.

This ADR formalizes the distinction so Phase 1 can:

1. Stop treating `_tab.do` mtitles bugs as paper-blocking.
2. Document the producer hierarchy explicitly in the README so the senior coauthor doesn't accidentally edit a `_tab.do` file thinking it controls a paper table.

This decision settles four audit findings (P2-5, P2-6, P3-62, P3-63) and the `Q-17` umbrella question.

## Decision

The producer hierarchy is **two-tiered and explicit**:

- **Paper tables (canonical, paper-shipping):** producers live in `do/share/` (consolidated repo) / `caschls/do/share/` (predecessor). Output paths terminate in `tables/share/.../pub/*.tex` (and parallel paper paths) and are `\input{}`-ed by `paper/common_core_va_v2.tex`. **These are paper-load-bearing — bugs here are paper-integrity bugs.**
- **Local-review CSVs (exploratory, NOT paper-shipping):** producers are `_tab.do` files outside `share/`, primarily in `cde_va_project_fork/do_files/sbac/` and (for the deprecated subtree per ADR-0004) `caschls/do/share/siblingvaregs/`. Output paths terminate in `tables/va_cfr_all_v1/.../*.csv`. **These exist for Christina-and-coauthor iteration. mtitles, column-count, and labeling irregularities in these files are NOT bugs to fix.**

Specifically, the following audit findings are **reclassified** by this ADR:

| Finding | Pre-ADR class | Post-ADR class |
|---|---|---|
| P2-5 (`reg_out_va_sib_acs_tab.do` mtitles labeling) | P2 — needs fixing | NOT A BUG — local review CSV; also moot per ADR-0004 (file archived) |
| P2-6 (`reg_out_va_all_tab.do` 24-vs-32 mtitles) | P2 — needs verification | NOT A BUG (paper-integrity) — local review CSV. Phase 1 may fix mtitles for completeness only. |
| P3-62 (`reg_out_va_tab.do` `lasd_ct_p` drop) | P3 — possible oversight | INTENTIONAL — coauthor preference (Q-18) |
| P3-63 (`va_var_explain_tab.do` 5 controls / 4 cols) | P3 — possible oversight | INTENTIONAL — same family as Q-17 |

Phase 1 scope for `_tab.do` files: optional cosmetic mtitles cleanups for completeness; no obligation. The README documents the two-tier hierarchy so the senior coauthor doesn't get confused.

## Consequences

**Commits us to:**

- README explicitly distinguishes "paper-shipping table producers" (in `share/`) from "local review CSV producers" (in `do_files/sbac/`).
- Phase 1 does not block on fixing `_tab.do` mtitles bugs.
- The bug-priority triage in `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` is updated to reflect the reclassifications.

**Rules out:**

- Treating `_tab.do` CSV outputs as paper-load-bearing without a superseding ADR.
- Phase 1 effort budget being consumed by fixing local-review-CSV cosmetics.

**Open questions:**

- Whether the local-review CSVs should eventually be archived if no longer iterated against. Discretionary — leaving alone for now.
- The 49-column case in `reg_out_va_ela_math.csv` (T1-4) is structurally different from the 33-column cases. Worth a one-line note in the file header explaining the column layout, but not a Phase 1 blocker.

## Sources

- `quality_reports/audits/2026-04-27_T4_answers_CS.md` Q-6, Q-17, Q-18
- `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` §2 P2-5, P2-6, P3-62, P3-63 (reclassified by this ADR)
- `quality_reports/audits/round-2/chunk-4-discrepancies.md` M4 (mtitles 24 vs 32)
- `quality_reports/audits/round-2/chunk-5-discrepancies.md` M1 (mtitles labeling)
- `quality_reports/audits/round-2/chunk-9-discrepancies.md` A4, M5 (column-count irregularities)
- T1-4 log at `quality_reports/audits/t1_empirical_tests_27-Apr-2026_17-49-08.smcl` (49/33/33/33 column counts)
- Chunk-9 audit conclusion: paper Tables 1-8 + Figs 1-5 producers all in `share/`
- Related: ADR-0004 (`siblingvaregs/` deprecation — overlaps with P2-5 specifically)
