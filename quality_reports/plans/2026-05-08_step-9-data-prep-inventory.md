# Plan — Phase 1a §3.3 Step 9: Data prep relocation (5-batch split)

**Status:** APPROVED in spirit (Step 9 listed in plan v3 §3.3 as "data prep ~30 files"); this doc inventories the actual file set and proposes the batch split.

**Date:** 2026-05-08
**Prerequisite:** Steps 1-8 ALL COMPLETE (Step 8 PASS 97/100 commit `8fe1f28`).

## Inventory result — 33 files total

Inventory ran against both predecessor trees:
- `~/github_repos/cde_va_project_fork/do_files/`
- `~/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls/do/`

| # | Sub-batch | Source | Destination | Files |
|---|---|---|---|---:|
| 9a | acs/ | `cde/do_files/acs/` | `do/data_prep/acs/` | 2 |
| 9b | schl_chars/ | `cde/do_files/schl_chars/` | `do/data_prep/schl_chars/` | 11 |
| 9c | k12_postsec_distance/ | `cde/do_files/k12_postsec_distance/` | `do/data_prep/k12_postsec_distance/` | 5 |
| 9d | prepare/ | `caschls/do/build/prepare/` | `do/data_prep/prepare/` | 4 |
| 9e | qoiclean/ | `caschls/do/build/buildanalysisdata/qoiclean/{parent,staff,secondary}/` | `do/data_prep/qoiclean/{parent,staff,secondary}/` | 11 |
| | | | **Total** | **33** |

### Detailed file lists

**9a — acs/ (2):** `acs_2017_gen_dict.do`, `clean_acs_census_tract.do`

**9b — schl_chars/ (11):** `cds_nces_xwalk.do`, `clean_charter.do`, `clean_ecn_disadv.do`, `clean_elsch.do`, `clean_enr.do`, `clean_frpm.do`, `clean_locale.do`, `clean_sch_char.do`, `clean_staffcred.do`, `clean_staffdemo.do`, `clean_staffschoolfte.do`

**9c — k12_postsec_distance/ (5):** `check_merge.do`, `hd2021.do`, `k12_postsec_distances.do`, `merge_k12_postsec_dist.doh`, `reconcile_cdscodes.do`

**9d — prepare/ (4):** `enrollmentclean.do`, `poolgr11enr.do`, `renamedata.do`, `splitstaff0414.do`

**9e — qoiclean/ (11):** parent/{parentqoiclean1415, ...1516, ...1617, ...1819_1718}, secondary/{secqoiclean1415, ...1617, ...1819_1718_1516}, staff/{staffqoiclean1415, ...1617_1516, ...1819_1718}

## Discovered-but-out-of-Step-9-scope

Inventory surfaced two additional caschls subdirs under `buildanalysisdata/` that are also data-prep in nature but **not named in plan v3 §3.3 step 9 / TODO.md**:

- `caschls/do/build/buildanalysisdata/poolingdata/` (5 files): `clean_va.do`, `mergegr11enr.do`, `parentpooling.do`, `secpooling.do`, `staffpooling.do` — produce the pooled `*analysisready` datasets that the Step 7 survey-VA chain reads (e.g., `secanalysisready`, `parentanalysisready`, `staffanalysisready`).
- `caschls/do/build/buildanalysisdata/responserate/` (4 files): `parentresponserate.do`, `secresponserate.do`, `trimparentdemo.do`, `trimsecdemo.do` — build response-rate diagnostics.

**Disposition (proposed):** **defer to Christina decision.** Either:
- (a) Extend Step 9 with batches 9f (poolingdata, 5) + 9g (responserate, 4), bringing total to 42 files; OR
- (b) Keep Step 9 at 33 files; queue these as Step 9.5 / Step 10 prerequisite.

Going forward, **pursue option (a)** if and only if Christina confirms in this session; otherwise, finish Step 9 at 33 files and surface the question at the end for decision.

## Per-batch execution plan

For each batch (9a → 9e):

1. **Inventory + grep.** Confirm file count; grep for INPUTS/OUTPUTS/`$projdir` references.
2. **Relocate.** Apply script-based methodology per `[LEARN:workflow] script-based-relocation` (sed for path repointings + Python for ADR-0021 header insertion + mkdir + RUN-START block). Single-file batches may use Python directly without sed.
3. **Tier 1 self-check.** Run the now-extended sandbox-write grep (`save|export|esttab using|graph export|outsheet|outreg2 using|texsave|^\s*translate |log using`) on each relocated file. Verify path references updated; verify `$projdir` in code (not header doc-block) is zero. Verify INPUTS+OUTPUTS headers grep against body.
4. **Wire into main.do.** Add invocations under appropriate Phase. Step 9 = Phase 0 (data prep, runs first if at all). One-liner per ADR-0021 description convention.
5. **Atomic relocation commit.** Footer: `coder-critic: PENDING (separate dispatch this session)`.
6. **Tier 2 dispatch.** coder-critic full-scope (12-category) or tight-scope depending on batch size. Hard gate 80/100.
7. **Fix any findings in-commit (round 2 if needed).**
8. **Hygiene commit.** TODO + session log + SESSION_REPORT update. Footer: `coder-critic: skipped (rationale: docs-only hygiene)`.

## Path repointing strategy (canonical destinations)

Following the precedent from Steps 7 batches:

- Reads from `$projdir/dta/<x>/...` → `$caschls_projdir/dta/<x>/...` (LEGACY-static external)
- Reads from `$vaprojdir/data/<x>/...` → `$vaprojdir/data/<x>/...` (LEGACY-static; cde-side)
- Writes to `$projdir/dta/<x>/...` → `$datadir_clean/<sub>/<x>/...` (CANONICAL chain)
- Writes to `$projdir/log/<x>/...` → `$logdir/<x>/...` (CANONICAL)
- Writes to `$projdir/out/...` → `$output_dir/...` (CANONICAL)
- Within-batch `do $projdir/do/build/...` → `$consolidated_dir/do/data_prep/...` (CANONICAL)

Per-batch path repointings will be enumerated in each batch's commit message.

## main.do wiring

Step 9 files build LEGACY-input-state datasets (analysisready, sch_char, etc.) consumed by later phases. Currently main.do has Phase 0 (settings) → Phase 1 (data_prep) → ... → Phase 5 (survey VA). Step 9 invocations land in Phase 1 or just before — gated by `do_data_prep` flag (default 0; LEGACY data is canonical for now).

Wiring shape:

```
if `do_data_prep' {
    di as text "{hline 80}"
    di as text "PHASE 1: DATA PREP"
    di as text "{hline 80}"

    do do/data_prep/acs/clean_acs_census_tract.do                  // <one-liner>
    do do/data_prep/schl_chars/clean_charter.do                     // <one-liner>
    ...
}
```

## Session-log + housekeeping cadence

Per Christina's directive 2026-05-07: log + housekeeping after every batch.

- **Per-batch session log:** `quality_reports/session_logs/2026-05-08_step-9-batch-9{a,b,c,d,e}.md` (one per batch).
- **Per-batch hygiene commit:** TODO Done section update + SESSION_REPORT append + (if needed) MEMORY.md `[LEARN]` if new lesson surfaces.

## Risks + mitigations

- **`$projdir` ambiguity.** caschls files use `$projdir` as the root macro (= `/home/research/ca_ed_lab/users/chesun/gsr/caschls`). cde_va_project_fork files use `$vaprojdir` (= `/home/research/ca_ed_lab/projects/common_core_va`). Mitigation: alias-before-include pattern per [LEARN:stata] siblingoutxwalk, OR pre-emptive sed repoint per Step 7 precedent.
- **Cross-batch input/output dependencies.** schl_chars/ outputs feed into `merge_k12_postsec_dist.doh` (in 9c). Order matters: 9a → 9b → 9c → 9d → 9e likely. Mitigation: trace each batch's INPUTS to confirm prior batch wrote them.
- **Christina-owned files.** Per ADR-0017, Matt Naven's files are out of scope; per ADR-0019 and the Step 9 listing, these are Christina-owned. No conflict.

## Definition of done

- All 33 files relocated per the destinations above.
- All Tier-2 reviews PASS ≥ 80/100.
- `do/main.do` has Phase 1 wiring with all 33 invocations (or grouped subdirs) under `do_data_prep` flag.
- TODO.md Active flipped to Step 10.
- Phase 1a §3.3 progress: 116 of ~150 files (83 + 33).
- Out-of-scope `poolingdata/` + `responserate/` either landed in 9f/9g or queued for later step with explicit decision recorded.
