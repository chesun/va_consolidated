# 0004: Sibling-VA production pipeline — `va_{score,out}_all.do` canonical; `siblingvaregs/` regressions deprecated

- **Date:** 2026-04-27
- **Status:** Decided
- **Scope:** Specification
- **Data quality:** Full context

## Context

Phase 0a-v2 chunk-5 audit found two parallel sibling-VA estimation pipelines coexisting in the predecessor repos:

1. **Old pipeline** — `caschls/do/share/siblingvaregs/` (~30 .do files): `va_sibling.do`, `va_sibling_out.do`, `va_sib_acs.do`, `va_sib_acs_out.do`, `va_sib_acs_out_dk.do`, `reg_out_va_sib_acs*.do`, `siblingvasamples.do`, `createvasample.do`, etc. Uses an older naming convention (`_sibling`/`_nosibctrl`/`_nocontrol`/ ad-hoc tokens) and is wired into `caschls/do/master.do:468-561`.
2. **Canonical pipeline** — `cde_va_project_fork/do_files/sbac/va_score_all.do` and `va_out_all.do`. Loops over the standard 16-spec framework `b/l/a/s/la/ls/as/las/bd/ld/...` defined in `macros_va_all_samples_controls.doh`, where `s` = sibling control. Sibling-VA is produced INSIDE the canonical `(sample × control × subject × version)` loop — no separate sibling pipeline needed. All paper-load-bearing tables and figures (chunk-9: Tables 1-8, Figs 1-5) are downstream of the canonical pipeline.

Christina (Phase 0e Q-9, 2026-04-27) confirmed: "sibling VA estimation files in `/siblingvaregs` are deprecated. Production code for sibling VA estimation is in `cde_va_project_fork/do_files/sbac/va_{score|out}_all.do`." Verified 2026-04-27 by tracing both pipelines through their respective master scripts and sample/control macro files.

This decision settles three other queued items: chunk-5 N2 (naming fragmentation hazard), Q-10 (DK controls in `va_sib_acs_out_dk.do` intentional-but-deprecated), and the original ADR-0004 placeholder ("siblingoutxwalk.do canonical location") — see ADR-0005 for the relocation specifics.

## Decision

The canonical production pipeline for sibling-VA estimation is **`cde_va_project_fork/do_files/sbac/va_score_all.do` and `va_out_all.do`**. Sibling-VA is produced inside the standard 16-spec framework using sample/control codes from `macros_va_all_samples_controls.doh` (`s`, `ls`, `as`, `las`, plus the `d`-suffixed distance variants).

The `caschls/do/share/siblingvaregs/` regression subtree is **deprecated**. The following files are moved to `_archive/` during Phase 1:

- `va_sibling.do`, `va_sibling_out.do`, `va_sibling_out_forecast_bias.do`
- `va_sib_acs.do`, `va_sib_acs_out.do`, `va_sib_acs_out_dk.do`
- `va_sibling_*_sumstats.do`, `va_sibling_*_tab.do`
- `va_sib_acs_*_sumstats.do`, `va_sib_acs_*_tab.do`, `va_sib_acs_fb_test_tab.do`, `va_sib_acs_spec_test_tab.do`, `va_sib_acs_vam_tab.do`
- `reg_out_va_sib_acs.do`, `reg_out_va_sib_acs_tab.do`, `reg_out_va_sib_acs_fig.do`, `reg_out_va_sib_acs_dk.do`, `reg_out_va_sib_acs_dk_fig.do`
- `siblingvasamples.do`, `createvasample.do`, `create_va_sib_acs_restr_smp.do`, `create_va_sib_acs_out_restr_smp.do`
- `vaestmacros.doh`, `vafilemacros.doh` (helpers used only by deprecated files — verify before archiving)

The corresponding lines in `caschls/do/master.do` (L468-561) are commented out or removed during Phase 1 archival.

`siblingoutxwalk.do` is **not** deprecated — it builds the family crosswalk consumed by canonical sample construction. See ADR-0005.

## Consequences

**Commits us to:**

- Phase 1 archives ~30 deprecated `.do` files in one move; `caschls/do/master.do:468-561` block is removed.
- Old naming conventions (`_sibling`/`_nosibctrl`/`_nocontrol`/ ad-hoc tokens) retire with the files. The canonical 16-spec framework in `macros_va_all_samples_controls.doh` is the only naming system going forward. Settles chunk-5 N2.
- Several P2/P3 audit findings inside the deprecated subtree become **moot**: P2-5 (`reg_out_va_sib_acs_tab.do` mtitles labeling), P3-29 (sibling collapse asymmetry), P3-30 (ACS spec missing in combined panels), P3-31 (trailing-space typo in `va_sibling_fb_test_tab.do`), and the chunk-5 disc A8 / Q-10 DK-controls question.
- Cluster-level concern at chunk-5 (`cdscode` vs `school_id` in `reg_out_va_sib_acs.do`) is moot — file is archived. T1-3 still needed because the same pattern exists in `cde_va_project_fork/do_files/va_het/va_het.do` (canonical pipeline, P2-3).

**Rules out:**

- Reviving the deprecated subtree without superseding this ADR.
- Reading `_sibling/_nosibctrl/_nocontrol`-named outputs as authoritative for any future analysis.

**Open questions:**

- Several deprecated `caschls/do/share/siblingvaregs/` files have non-trivial content (e.g., `siblingvasamples.do` may overlap with canonical sample-construction). Phase 1 verification before archival should confirm none of these files produce outputs consumed by `share/` table/figure scripts.
- Whether the `_archive/` should preserve the original directory structure or flatten — preference for preserving structure for archeology.

## Sources

- `quality_reports/audits/2026-04-27_T4_answers_CS.md` Q-9
- `quality_reports/audits/round-2/chunk-5-discrepancies.md` N2 (naming fragmentation), A8 (DK controls)
- `quality_reports/audits/round-1/2026-04-25_chunk5-sibling.md` L1087-1097, L1143, L1159 (original framing)
- `cde_va_project_fork/do_files/sbac/macros_va_all_samples_controls.doh` (canonical 16-spec framework)
- `cde_va_project_fork/do_files/sbac/va_score_all.do` and `va_out_all.do` (canonical entry points)
- `caschls/do/master.do:468-561` (deprecated wiring)
- Verification 2026-04-27: dual-pipeline trace through both master scripts
- Related: ADR-0005 (siblingoutxwalk.do relocation), ADR-0017 (Matt's files untouched — distinct concern from this deprecation)
