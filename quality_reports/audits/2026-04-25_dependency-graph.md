# Dependency Graph

**Status:** IN PROGRESS (foundation chunk seeded)
**Plan reference:** `quality_reports/plans/2026-04-25_consolidation-plan-draft.md` §6.3 (Phase 0b)
**Companion doc:** `2026-04-25_deep-read-audit.md`

Direct + transitive dependencies between scripts. Identifies critical paths, residual circularities, and orphans.

---

## Entry-point graph

```
USER-INVOKED ENTRY POINTS
=========================

cde_va_project_fork/do_files/do_all.do
  ├── do settings.do (line 8)
  │   ├── globals: $rawcsvdir, $rawdtadir, $clndtadir, $projdir, $vaprojdir,
  │   │            $vadtadir, $cstdtadir, $nscdtadir, $nscdtadir_oldformat,
  │   │            $mattxwalks, $vaprojxwalks, $distance_dtadir
  │
  ├── [block 1 clean_acs] do $vaprojdir/do_files/acs/clean_acs_census_tract
  ├── [block 2 clean_sch_char ACTIVE] 11 files in $vaprojdir/do_files/schl_chars/
  ├── [block 3 do_distance] 2 files in $vaprojdir/do_files/k12_postsec_distance/
  ├── [block 4 do_touse_va] do_files/sbac/touse_va.do (relative)
  │
  ├── [block 5 do_match_siblings] ─────────► CROSS-REPO
  │   ├── do $projdir/do/share/siblingxwalk/siblingmatch
  │   ├── do $projdir/do/share/siblingxwalk/uniquefamily
  │   ├── do $projdir/do/share/siblingxwalk/siblingpairxwalk
  │   └── do $projdir/do/share/siblingvaregs/siblingoutxwalk.do  (N1 anchor)
  │
  ├── [block 6 do_create_samples] 2 files in $vaprojdir/do_files/sbac/
  ├── [block 7 do_va] ~20 VA estimation files (heart of the paper)
  │     consumes: prior_decile_original_sample.dta (from prior_decile_original_sample.do)
  │     uses: vam.ado on adopath (caschls/do/ado/vam.ado)
  │     sources: macros_va.doh
  │
  ├── [block 8 do_share_tables] 8 share/ files
  ├── [block 9 do_va_het ACTIVE] 4 va_het/ files
  └── [block 10 do_survey] ─────────► CROSS-REPO
      └── do "/...caschls/do/master.do"   (hardcoded absolute path)

caschls/do/master.do
  ├── do "./do/settings.do" (line 52)
  │
  ├── [block 1 do_match_siblings] ───── DUPLICATE OF do_all.do block 5
  │   (identical 4 calls)
  │
  ├── [block 2 do_build_data] 2 files
  ├── [block 3 do_check_data] 4 files
  ├── [block 4 do_diagnostics] 14 files
  ├── [block 5 do_response_rate] 4 files
  ├── [block 6 do_clean_sec_qoi] 3 files
  ├── [block 7 do_clean_parent_qoi] 4 files
  ├── [block 8 do_clean_staff_qoi] 3 files
  ├── [block 9 do_pool_qoi_merge] 3 files
  ├── [block 10 do_pool_gr11_enr] 2 files
  ├── [block 11 do_va_regs] do clean_va.do, do allvaregs
  │     consumes: VA estimates produced by do_all.do block 7
  ├── [block 12 dofactor] 4 files
  ├── [block 13 do_index] 4 files
  ├── [block 14 do_index_va_reg] 7 files (mattschlchar consumes $mattxwalks)
  ├── [block 15 dooutcomesumstats] 1 file
  └── [block 16 do_sibling_va_regs] ~30 files for 4-spec analysis
```

---

## Universally-sourced foundations

These are sourced/dereferenced by every script in their pipeline scope:

| Foundation | Sourced/dereferenced by |
|---|---|
| `settings.do` (either repo) | `do_all.do`, `master.do`, transitively every block they invoke |
| `macros_va.doh` | every VA-estimation script in `cde_va_project_fork/do_files/sbac/` (`include $vaprojdir/do_files/sbac/macros_va.doh`) |
| `vam.ado` | every script that calls `vam ...` — VA estimation and sibling-VA estimation |
| `vafilemacros.doh` (caschls) | TO BE AUDITED — likely sourced by `caschls/do/share/siblingvaregs/*` and `caschls/do/share/svyvaregs/*` |
| `vaestmacros.doh` (caschls) | TO BE AUDITED |

---

## Cross-repo edges (the wiring that breaks during migration)

```
do_all.do ──[block 5 sibling matching]──► caschls/do/share/siblingxwalk/*
                                          caschls/do/share/siblingvaregs/siblingoutxwalk.do

do_all.do ──[block 10 do_survey, hardcoded path]──► caschls/do/master.do

macros_va.doh ──[$projdir/dta/siblingxwalk/...]──► dtas produced by caschls sibling pipeline

caschls scripts ──[$mattxwalks]──► /home/research/ca_ed_lab/users/msnaven/...
                                     (Matt's user-tree; cross-user dependency)
```

---

## Steady-state run order (when both masters used)

Christina's documented order (per context dump §2):

1. `caschls/master.do` with `do_match_siblings = 1` (others 0) → produces sibling crosswalks at `$projdir/dta/siblingxwalk/*`
2. `cde_va_project_fork/do_all.do` with `do_va = 1`, `do_share_tables = 1`, `do_va_het = 1` (others 0) → consumes sibling crosswalks; produces VA estimates at `$vaprojdir/data/sbac/*`
3. `caschls/master.do` with `do_match_siblings = 0`, all others 1 → consumes VA estimates via `clean_va.do`, produces survey-VA results

In the consolidated `main.do`, these collapse to phase blocks (per plan §4):

```
Phase 0: settings
Phase 1: upstream (off by default)
Phase 2: data_prep
Phase 3: sibling_xwalk          ← was caschls/master block 1 = do_all block 5
Phase 4: samples
Phase 5: VA estimation          ← was do_all block 7
Phase 6: survey_va              ← was caschls/master blocks 11-16
Phase 7: share/output
```

---

## Critical paths

A "critical path" = a script whose failure breaks downstream chains. Foundation-level critical paths:

1. **`settings.do`** — every downstream depends on its globals.
2. **`macros_va.doh`** — every VA estimator depends on its macros.
3. **`vam.ado`** — every VA estimate is shrunk through it.
4. **`siblingoutxwalk.do`** — produces the sibling-outcome crosswalk that's used as a forecast-bias leave-out variable in the saturated VA spec.

Downstream critical paths (TBD):

5. `va_score_all.do` — produces the canonical ELA/math test-score VA dtas
6. `va_out_all.do` — produces the canonical 2-yr/4-yr enrollment VA dtas
7. `merge_va_est.do` — consolidates VA estimates for downstream regression consumers
8. `clean_va.do` (caschls) — translates VA dtas into the form survey-VA regressions expect

---

## Residual circularity check

After consolidation under the new phase order, all cross-repo edges resolve into within-repo references. No circularity is currently visible at the foundation level.

The only structural concern was N1 (siblingoutxwalk.do living in `siblingvaregs/`). Foundation finding: the file is called from BOTH masters' sibling-matching block, AND lives in the sibling_va_regs directory. Whether a relocation to `sibling_xwalk/` introduces a new circular reference depends on whether the file `include`s or `do`s anything from `siblingvaregs/`. **To verify in sibling chunk.**

---

## Orphans

Confirmed orphans (zero callers in active pipeline) — already archived per round-2 dispositions:

- caschls: `poolenrollment.do`, `nsc2019sumstats.do`, `searchdate_sumstats.do`, `k12_nsc_match_sumstats.do`, `matchdiscrep.do`, `reg_out_va_sib_acs_dk_tab.do`, `vamtest.do` → moved to `caschls/do/archive/`
- cde_va_project_fork: `va_scatter_plot.do` → moved to `_archive/`
- Both repos have orphan py_files content → preserved in py/upstream/ per ADR-0003

No new orphans surfaced at foundation level. To verify in downstream chunks.
