# Path-Reference Catalog

**Status:** IN PROGRESS (foundation chunk seeded)
**Plan reference:** `quality_reports/plans/2026-04-25_consolidation-plan-draft.md` §6.3 (Phase 0c)
**Companion doc:** `2026-04-25_deep-read-audit.md`

Every distinct path expression encountered during the deep-read. Drives the global path-translation pass during Phase 1+ migration.

---

## Globals (defined in settings.do, both repos byte-identical)

| Global | Current value | Consolidation target |
|---|---|---|
| `$projdir` | `/home/research/ca_ed_lab/users/chesun/gsr/caschls` | `/home/research/ca_ed_lab/projects/common_core_va` (single root) |
| `$vaprojdir` | `/home/research/ca_ed_lab/projects/common_core_va` | Same as `$projdir` post-consolidation; `$vaprojdir` retained as alias for backward compat during migration, removed at end |
| `$rawcsvdir` | `/home/research/ca_ed_lab/data/restricted_access/raw/calschls/csv` | unchanged (restricted-access raw, outside project tree) |
| `$rawdtadir` | `/home/research/ca_ed_lab/data/restricted_access/raw/calschls/stata` | unchanged |
| `$clndtadir` | `/home/research/ca_ed_lab/data/restricted_access/clean/calschls` | unchanged |
| `$cstdtadir` | `/home/research/ca_ed_lab/data/restricted_access/clean/cde/cst` | unchanged |
| `$nscdtadir` | `/home/research/ca_ed_lab/data/restricted_access/clean/cde_nsc` | unchanged |
| `$nscdtadir_oldformat` | `/home/research/ca_ed_lab/data/restricted_access/clean/cde_nsc/oldformat` | unchanged |
| `$vadtadir` | `/home/research/ca_ed_lab/projects/common_core_va/data/sbac` | `$projdir/data/sbac` |
| `$vaprojxwalks` | `/home/research/ca_ed_lab/projects/common_core_va/data/restricted_access/clean/crosswalks` | `$projdir/data/restricted_access/clean/crosswalks` |
| `$distance_dtadir` | `/home/research/ca_ed_lab/projects/common_core_va/data/k12_postsec_distance` | `$projdir/data/k12_postsec_distance` |
| `$mattxwalks` | `/home/research/ca_ed_lab/users/msnaven/data/restricted_access/clean/crosswalks` | **OPEN QUESTION**: vendor into `$projdir/data/...` or maintain symlink? Cross-user dependency, fragile if Matt's account decommissioned. |

---

## Hardcoded paths (not via global)

| File | Line | Path | Action |
|---|---|---|---|
| `cde_va_project_fork/do_files/do_all.do` | 7 | `cd "/home/research/ca_ed_lab/projects/common_core_va"` (literal `$vaprojdir`) | Replace with `cd "$projdir"` |
| `cde_va_project_fork/do_files/do_all.do` | 253 | `do "/home/research/ca_ed_lab/users/chesun/gsr/caschls/do/master.do"` | Remove entirely; in consolidated layout, `main.do` runs both predecessors' work in one entry. |
| `caschls/do/master.do` | 51 | `cd "/home/research/ca_ed_lab/users/chesun/gsr/caschls"` (literal `$projdir`) | Replace with `cd "$projdir"` |
| `cde_va_project_fork/do_files/sbac/macros_va.doh` | 24 | `local ca_ed_lab "/home/research/ca_ed_lab"` | Document as the lab root; rarely directly referenced; can leave or globalize as `$cael_root`. |

---

## Cross-repo references (the wiring that breaks during migration)

These references mean "from one predecessor, point into the other." All collapse to a single repo's subpaths post-consolidation.

### From cde_va_project_fork pointing at caschls (`$projdir/...`)

| Source file | Reference | Target file |
|---|---|---|
| `do_all.do:128-141` | `$projdir/do/share/siblingxwalk/siblingmatch` | `caschls/do/share/siblingxwalk/siblingmatch.do` |
| `do_all.do:128-141` | `$projdir/do/share/siblingxwalk/uniquefamily` | `caschls/do/share/siblingxwalk/uniquefamily.do` |
| `do_all.do:128-141` | `$projdir/do/share/siblingxwalk/siblingpairxwalk` | `caschls/do/share/siblingxwalk/siblingpairxwalk.do` |
| `do_all.do:128-141` | `$projdir/do/share/siblingvaregs/siblingoutxwalk.do` | `caschls/do/share/siblingvaregs/siblingoutxwalk.do` (N1 anchor) |
| `do_all.do:253` | hardcoded full path | `caschls/do/master.do` (whole-master invocation) |
| `macros_va.doh:29-31` | `$projdir/dta/siblingxwalk/siblingpairxwalk` etc. | output dtas of the sibling pipeline, written by caschls scripts |

### From caschls pointing at cde_va_project_fork (`$vaprojdir/...`)

To be populated as deep-read covers caschls scripts. Foundation-level finding: master.do does NOT call any cde_va_project_fork do-files directly; it consumes their output dtas via `clean_va.do` (caschls's own).

---

## Path-translation rules for migration (global pass)

Once consolidated, apply these substitutions across all migrated files:

| From | To |
|---|---|
| `$vaprojdir/do_files/` | `$projdir/do/` (with subdir reorg per plan §3) |
| `$projdir/do/share/siblingxwalk/` | `$projdir/do/sibling_xwalk/` (collapsed name) |
| `$projdir/do/share/siblingvaregs/` | `$projdir/do/survey_va/sibling_va_regs/` (per plan §3 layout) |
| `$projdir/do/share/svyvaregs/` | `$projdir/do/survey_va/` |
| `$projdir/do/share/factoranalysis/` | `$projdir/do/survey_va/factoranalysis/` |
| `$projdir/do/share/demographics/` | `$projdir/do/samples/caschls_demographics/` |
| `$projdir/do/build/prepare/` | `$projdir/do/data_prep/prepare/` |
| `$projdir/do/build/buildanalysisdata/qoiclean/` | `$projdir/do/data_prep/caschls_qoiclean/` |
| `$projdir/do/build/buildanalysisdata/poolingdata/` | `$projdir/do/samples/caschls_pooling/` |
| `$projdir/do/build/buildanalysisdata/responserate/` | `$projdir/do/samples/caschls_pooling/responserate/` |
| `$projdir/do/build/sample/` | `$projdir/do/samples/caschls_demographics/` |
| `$projdir/do/share/check/` | `$projdir/do/check/` |
| `$projdir/do/check/` | `$projdir/do/check/` (already at right level) |
| `$projdir/do/local/` | `$projdir/do/local/` (unchanged) |
| `$projdir/do/upstream/` | `$projdir/do/upstream/` (unchanged) |
| `$projdir/do/archive/` | `$projdir/do/_archive/` (rename to underscore-prefix per fork convention) |
| `$projdir/do/ado/` | `$projdir/ado/` (root-level, NOT under do/) |

Layout above is provisional per the v2 plan §3; will be locked in ADR-0004 after Phase 0 design lock.

---

## Sibling-output dtas (`$projdir/dta/...`)

These are dtas written by caschls scripts and consumed cross-repo. Listed here from `macros_va.doh:29-31`:

| Dta path | Producer | Consumers |
|---|---|---|
| `$projdir/dta/siblingxwalk/siblingpairxwalk.dta` | `caschls/do/share/siblingxwalk/siblingpairxwalk.do` | various — to be enumerated |
| `$projdir/dta/siblingxwalk/ufamilyxwalk.dta` | `caschls/do/share/siblingxwalk/uniquefamily.do` | various |
| `$projdir/dta/siblingxwalk/sibling_out_xwalk.dta` | `caschls/do/share/siblingvaregs/siblingoutxwalk.do` | various — likely the consumer pattern that determines N1 |

Will populate the consumers column as the sibling chunk audit completes.

---

## Stata adopath (custom .ado discovery)

| File | Path | Note |
|---|---|---|
| `caschls/do/ado/vam.ado` | (the only custom .ado found in foundation) | Stepner v2.0.1 27jul2013 — agent could not identify any Christina/Matt modifications. Recommend `ssc install vam, replace` diff in sandbox. Consolidated location: `$projdir/ado/vam.ado`. |

`do_all.do:51` includes `ssc install vam` in the install-block — would overwrite the local custom copy if run. Consolidated installer should skip vam OR install with `replace` only after explicitly re-applying the custom version.

---

## What the catalog still needs (rolls up across pending chunks)

- All `$vaprojdir/do_files/...` references in fork's downstream scripts
- All `$projdir/do/...` references in caschls's downstream scripts
- All `$projdir/dta/...` and `$vaprojdir/data/...` references (the data-output paths)
- Hardcoded `/Users/...` paths (none expected on Scribe-targeted code, but worth confirming)
- Any remaining cross-user (`/home/research/ca_ed_lab/users/<other>/...`) references

---

## Chunk 2 additions (2026-04-25)

### New hardcoded server-absolute paths found

| File | Line | Path | Action |
|---|---|---|---|
| `cde_va_project_fork/do_files/merge_k12_postsecondary.doh` | 7 | `/home/research/ca_ed_lab/projects/common_core_va/data/restricted_access/clean/crosswalks/` | Replace with `$vaprojdir/data/restricted_access/clean/crosswalks/` |

### New cross-repo wire-up paths found

`caschls/do/share/siblingvaregs/vafilemacros.doh` (24 lines) defines local macros for cross-repo dataset paths:

| Local | Path | Cross-repo? |
|---|---|---|
| `vaprojdofiles` | `$vaprojdir/do_files` | yes |
| `va_dataset` | `$projdir/dta/common_core_va/va_dataset` | caschls subroot |
| `va_g11_dataset` | `$projdir/dta/common_core_va/va_g11_dataset` | caschls subroot |
| `va_g11_out_dataset` | `$projdir/dta/common_core_va/va_g11_out_dataset` | caschls subroot |
| `siblingxwalk` | `$projdir/dta/siblingxwalk/siblingpairxwalk` | caschls subroot |
| `ufamilyxwalk` | `$projdir/dta/siblingxwalk/ufamilyxwalk` | caschls subroot |
| `k12_postsecondary_out_merge` | `$projdir/dta/common_core_va/k12_postsecondary_out_merge` | caschls subroot |
| `sibling_out_xwalk` | `$projdir/dta/siblingxwalk/sibling_out_xwalk` | caschls subroot |

### vaestmacros.doh path bugs (preserve in path-translation pass)

| File | Line | Bug | Effect |
|---|---|---|---|
| `caschls/.../vaestmacros.doh` | 27 | filename has `.dta.dta` | wrong filename / failed save/load |
| `caschls/.../vaestmacros.doh` | 45 | `"vaprojdir/estimates/sbac/..."` missing `$` | resolves to literal `vaprojdir/...` directory |
| `caschls/.../vaestmacros.doh` | 118 | same as L45 | same |

These three are FILE-PATH bugs; the consolidation cleanup must NOT just rename `$vaprojdir → $projdir` blindly because lines 45 + 118 lack the `$` prefix entirely. A naive global-replace would not fix them.

### ACS data-source paths (Chunk 2 finding)

`caschls/.../merge_va_smp_acs.doh` references three ACS-pipeline data sources to be cataloged for consolidation (paths to verify in actual file):

- `acs_ca_census_tract_clean.dta` (L81)
- `address_list_census_batch_geocoded.csv` (L49)
- `address_list.dta` (L74)

### Other consolidation paths from Chunk 2

`vaestmacros.doh` paths split across `$vaprojdir/estimates/sbac/...` (test-score VA) and `$projdir/est/siblingvaregs/...` (sibling-VA). Same triangulation as `vafilemacros.doh`.

`do_files/sbac/create_va_g11_sample.doh` and its `_v1`/`_v2` siblings tempfile-name `va_g11_dataset` — collision risk if a downstream script sources both score and outcome variants in one session.
