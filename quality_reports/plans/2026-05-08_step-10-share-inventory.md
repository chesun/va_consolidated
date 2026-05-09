# Plan — Phase 1a §3.3 Step 10: share/ paper producers (3-batch split)

**Status:** APPROVED in spirit (Step 10 listed in plan v3 §3.3 as "share/ paper producers ~50 files"); this doc inventories the actual file set and proposes the batch split.

**Date:** 2026-05-08
**Prerequisite:** Steps 1-9 (extended) ALL COMPLETE.

## Inventory result — 21 files (NOT ~50 as plan v3 estimated)

The "~50" estimate in plan v3 was made before Steps 7/8/11 carved out the factoranalysis/ subtree. After accounting for already-relocated, archived, and deferred subtrees, Step 10 is **21 files**, not ~50.

### Files in scope (21)

**cde-side (10 files):** `cde_va_project_fork/do_files/share/`
- `base_sum_stats_tab.do`
- `kdensity.do`
- `reg_out_va_tab.do`
- `sample_counts_tab.do`
- `svyindex_tab.do`
- `va_scatter.do`
- `va_spec_fb_tab_all.do`
- `va_var_explain.do`
- `va_var_explain_tab.do`
- `check/corr_dk_score_va.do` (in `check/` subdir)

**caschls-side (11 files):** `caschls/do/share/`
- `demographics/` (4): `elemcoverageanalysis`, `parentcoverageanalysis`, `pooledsecanalysis`, `seccoverageanalysis`
- `outcomesumstats/` (2 Christina-owned): `nsc_codebook.do`, `nsc2019new/k12_nsc2019_merge.doh`
- `siblingxwalk/` (3): `siblingmatch`, `siblingpairxwalk`, `uniquefamily`
- `svyvaregs/` (1): `allvaregs`
- `factoranalysis/mattschlchar.do` (1; per ADR-0013 — Christina's wrapper)

### Files OUT of scope (already handled in earlier steps)

- `caschls/do/share/siblingvaregs/` (27 files) — ARCHIVED in Step 6 (`b8b4ce8`) to `do/_archive/siblingvaregs/`
- `caschls/do/share/factoranalysis/` (14 files except mattschlchar):
  - 9 active relocated to `do/survey_va/` in Step 7 (`3e99c3b`+`68cf30e`)
  - `alpha.do` archived in Step 8 (`8fe1f28`) to `do/_archive/exploratory/`
  - 3 files (`allsvymerge.do`, `allsvyfactor.do`, `testscore.do`) DEFERRED to Step 11 (per main.do flag-comment)
  - `mattschlchar.do` is the only one for Step 10

### Files OUT of scope (Matt-Naven untouched per ADR-0017)

- `caschls/do/share/outcomesumstats/matt/merge_k12_postsecondary.doh` (Matt's per ADR-0017)

## 3-batch split

| # | Sub-batch | Source | Destination | Files |
|---|---|---|---|---:|
| 10a | cde/share/ | `cde/do_files/share/` (incl. check/) | `do/share/` | 10 |
| 10b | caschls demographics | `caschls/do/share/demographics/` | `do/share/demographics/` | 4 |
| 10c | caschls misc | `caschls/do/share/{outcomesumstats,siblingxwalk,svyvaregs,factoranalysis/mattschlchar}/` | `do/share/{outcomesumstats,siblingxwalk,svyvaregs,va/}` | 7 |
| | | | **Total** | **21** |

### Detailed file lists

**10a — cde/share/ (10):**
- `base_sum_stats_tab.do`, `kdensity.do`, `reg_out_va_tab.do`, `sample_counts_tab.do`, `svyindex_tab.do`, `va_scatter.do`, `va_spec_fb_tab_all.do`, `va_var_explain.do`, `va_var_explain_tab.do`, `check/corr_dk_score_va.do`

**10b — caschls demographics/ (4):**
- `elemcoverageanalysis.do`, `parentcoverageanalysis.do`, `pooledsecanalysis.do`, `seccoverageanalysis.do`

**10c — caschls misc (7):**
- `outcomesumstats/nsc_codebook.do`
- `outcomesumstats/nsc2019new/k12_nsc2019_merge.doh`
- `siblingxwalk/siblingmatch.do`
- `siblingxwalk/siblingpairxwalk.do`
- `siblingxwalk/uniquefamily.do`
- `svyvaregs/allvaregs.do`
- `factoranalysis/mattschlchar.do` (per ADR-0013 — Christina's wrapper despite name)

## Per-batch execution plan

For each batch (10a → 10c):

1. **Inventory + grep** — confirm file count, paths, includes, log/translate patterns.
2. **Relocate** — script-based methodology (Python+sed transforms + ADR-0021 header insertion + per-file mkdir blocks; same flow as Step 9 batches).
3. **Tier 1 self-check** — extended grep for sandbox writes; `$projdir`/`$caschls_projdir`/`$vaprojdir` reference verification; INPUTS+OUTPUTS header fidelity.
4. **Wire into main.do** — Phase 6 (paper outputs) most likely. One-liner per ADR-0021.
5. **Atomic relocation commit.**
6. **Tier 2 dispatch coder-critic** — strict severity Phase 1a; hard gate 80/100.
7. **Fix any findings in-commit (round 2 if needed).**
8. **Hygiene commit** — TODO + session log + SESSION_REPORT update.

## Key chain considerations

Step 10 files are typically paper producers — they READ from CHAIN data produced by Step 9 (data prep) + Step 3 (VA estimation) + Step 7 (survey VA), and WRITE to CANONICAL `$tables_dir/`, `$figures_dir/`, `$output_dir/` (paper-shipping outputs).

- `va_scatter.do`, `kdensity.do`, `reg_out_va_tab.do` etc. — VA-related figures/tables; consume Step 3 VA estimates from `$estimates_dir/va_cfr_all_v[12]/...`
- `svyindex_tab.do`, `mattschlchar.do`, etc. — survey-VA related; consume Step 7 survey-VA outputs from `$estimates_dir/survey_va/factor/*` + `$datadir_clean/calschls/analysisready/*` (Step 9 batch 9f)
- `siblingxwalk/*` — sibling crosswalk family; reads sibling data
- `demographics/*coverage*` — coverage/demographic diagnostics

Per Step 9 lessons: when reads point at predecessor LEGACY paths that consolidated has repointed to CANONICAL, repoint the reads in the relocated Step 10 file too. Cross-batch chain coordination discipline applies.

## main.do wiring location

Step 10 paper producers go in **Phase 6 (PAPER OUTPUTS)** — currently empty/stubbed. Each invocation gated by `do_paper_outputs` flag (default 1).

## Risks + mitigations

- **`$projdir` ambiguity** (caschls files) — alias-before-include OR pre-emptive sed repoint per Step 9 precedent.
- **Cross-step chain reads** — must repoint to CANONICAL (Step 9 lesson).
- **Matt-owned files** — verify per ADR-0017 before relocating any caschls file.

## Definition of done

- 21 files relocated under `do/share/` (or sub-subdirs).
- All Tier-2 reviews PASS ≥ 80/100.
- `do/main.do` Phase 6 wired with all 21 invocations.
- TODO.md Active flipped to §3.5 golden-master verification (M4).
- Phase 1a §3.3 progress: 145 of ~150 files (124 + 21).
- Phase 1a §3.5 (M4 golden-master) becomes NEXT.
