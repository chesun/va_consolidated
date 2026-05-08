# do/_archive/siblingvaregs/ — Deprecated sibling-VA regression subtree

**Status:** ARCHIVED. Not invoked from any production pipeline. Preserved for historical reference + archeology.

**Archived:** 2026-05-08 per Phase 1a §3.3 step 6 (plan v3).
**Authority:** ADR-0004 (sibling-VA canonical pipeline; siblingvaregs/ deprecated).

## What this directory contains

27 .do/.doh files copied verbatim from `caschls/do/share/siblingvaregs/` (predecessor; Dropbox path). These implement an OLD parallel sibling-VA estimation pipeline that has been superseded by the canonical pipeline at `do/va/va_score_all.do` + `do/va/va_out_all.do` (per ADR-0004).

The OLD pipeline used naming conventions `_sibling`, `_nosibctrl`, `_nocontrol`, and ad-hoc tokens. The CANONICAL pipeline produces sibling-VA inside the standard 16-spec framework using sample/control codes from `macros_va_all_samples_controls.doh` (`s`, `ls`, `as`, `las`, plus `d`-suffixed distance variants).

## Files archived (27)

**Estimation:**
- `va_sibling.do`, `va_sibling_out.do`, `va_sibling_out_forecast_bias.do`
- `va_sib_acs.do`, `va_sib_acs_out.do`, `va_sib_acs_out_dk.do`

**Summary statistics + tables:**
- `va_sibling_est_sumstats.do`, `va_sibling_out_est_sumstats.do`, `va_sibling_sample_sumstats.do` (3 sumstats)
- `va_sibling_fb_test_tab.do`, `va_sibling_spec_test_tab.do`, `va_sibling_vam_tab.do` (3 tabs)
- `va_sib_acs_est_sumstats.do`, `va_sib_acs_out_est_sumstats.do` (2 sumstats)
- `va_sib_acs_fb_test_tab.do`, `va_sib_acs_spec_test_tab.do`, `va_sib_acs_vam_tab.do` (3 tabs)

**Outcome regressions (DK variant):**
- `reg_out_va_sib_acs.do`, `reg_out_va_sib_acs_tab.do`, `reg_out_va_sib_acs_fig.do`
- `reg_out_va_sib_acs_dk.do`, `reg_out_va_sib_acs_dk_fig.do`

**Sample construction (deprecated branch):**
- `siblingvasamples.do`
- `createvasample.do`
- `create_va_sib_acs_restr_smp.do`
- `create_va_sib_acs_out_restr_smp.do`

**Helper:**
- `vaestmacros.doh` — defines locals consumed only by other deprecated files in this archive

## NOT archived (still active / superseded by relocation)

- **`siblingoutxwalk.do`** — relocated to `do/sibling_xwalk/siblingoutxwalk.do` 2026-04-30 per ADR-0005 (the only file from siblingvaregs/ that survives consolidation). Builds the sibling-outcomes crosswalk consumed by the canonical pipeline.
- **`vafilemacros.doh`** — kept at predecessor location `$caschls_projdir/do/share/siblingvaregs/vafilemacros.doh` (LEGACY-static helper) because it is consumed by ACTIVE relocated code:
  - `do/sibling_xwalk/siblingoutxwalk.do:164` (LEGACY include)
  - `do/va/prior_decile_original_sample.do:155` (LEGACY include with `$projdir` alias-before-include pattern)
  - Per ADR-0004's own "verify before archiving" clause, this file fails the verify step (it IS used by non-deprecated active code) and stays in caschls predecessor location.

## Why these are deprecated (per ADR-0004)

Phase 0a-v2 chunk-5 audit found two parallel sibling-VA pipelines coexisting in the predecessor repos. Christina (Phase 0e Q-9, 2026-04-27) confirmed: the canonical production pipeline is `cde_va_project_fork/do_files/sbac/va_{score|out}_all.do` (NOT the siblingvaregs subtree). Sibling-VA in the canonical pipeline is produced inside the standard 16-spec framework — no separate pipeline needed.

All paper-load-bearing tables and figures (Tables 1-8, Figs 1-5) are downstream of the canonical pipeline. None of the files in this archive feed paper outputs.

## Archive convention

- Bodies preserved verbatim per ADR-0021 (no path repointing applied).
- File timestamps reflect archive-copy date (2026-05-08), not original predecessor authorship dates.
- Original predecessor copies remain at `caschls/do/share/siblingvaregs/` (Dropbox path) until Christina decides to retire the predecessor working copy entirely (separate decision; not blocking the consolidated repo's `v1.0-final` tag).

## Cross-references

- ADR-0004: sibling-VA canonical pipeline; siblingvaregs/ deprecated
- ADR-0005: siblingoutxwalk.do relocation (the survivor)
- ADR-0017: Matt Naven's files untouched (different concern; siblingvaregs is Christina-authored)
- ADR-0021: do/ relocation; sandbox; description convention
- Plan v3 §3.3 step 6: archive batch
- Phase 0a-v2 chunk-5 audit: identified the duplicate-pipeline issue
