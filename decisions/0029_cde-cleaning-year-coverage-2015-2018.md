# 0029: CDE cleaning year coverage = spring 2015–2018; predecessor's extra years intentionally not rebuilt

- **Date:** 2026-06-11
- **Status:** Decided
- **Scope:** Data
- **Data quality:** Full context

## Context

The full M4 golden-master run (commit `7fe9c1a`, 8,324 pairs) reported 22
MISSING_CONSOLIDATED files — all CDE cleaned per-year files for spring years
2013, 2014, 2019, and 2020
(`data/cleaned/cde/{elsch,enr,frpm,staffcred,staffdemo,staffschoolfte}/<type>_<year>_clean.dta`)
plus `data/cleaned/sch_char_2019.dta`. The predecessor pipeline produced these;
the consolidated pipeline does not. All analysis-window years (spring 2015–2018)
exist on both sides and PASS.

Code trace (verified locally 2026-06-11):

1. The analysis window is defined once: `do/va/helpers/macros_va.doh:116-122`
   sets `test_score_min_year = 2015`, `test_score_max_year = 2018` — the 4
   cohorts of 11th-graders, spring 2015 through spring 2018.
2. Every CDE cleaning loop derives its bounds from those macros:
   `forvalues fall_year = test_score_min_year-1 (1) test_score_max_year-1`
   (i.e., fall 2014–2017 = spring 2015–2018) at `clean_elsch.do:141`,
   `clean_enr.do:140`, `clean_frpm.do:145`, `clean_staffcred.do:142`,
   `clean_staffschoolfte.do:143` (all under `do/data_prep/schl_chars/`).
   `clean_staffdemo.do` splits the same span into a 2014-only loop (`:142`,
   schema change year) plus `2015 (1) test_score_max_year-1` (`:301`).
3. `clean_sch_char.do:603` snapshots `sch_char_<spring_year>.dta` over the same
   macro-driven span, so only `sch_char_2015–2018.dta` are produced; the
   predecessor additionally produced `sch_char_2019.dta`.
4. The M4 path matrix enumerated spring 2013–2020 as an acknowledged covering
   guess — `do/check/m4_path_matrix_README.md` ("CDE year ranges are
   best-guess … confirm against predecessor bodies during first M4 run").
   This ADR is that confirmation.

The decision itself predates this ADR: the consolidation plan draft earmarked it
as "0013 cohort-coverage-2014-15-to-2017-18 — Sample = 4 cohorts of
11th-graders, Spring 2015 through Spring 2018. Defined in macros_va.doh"
(`quality_reports/plans/2026-04-25_consolidation-plan-draft.md:165`) and
deferred writing the file; the number 0013 was later used for the mattschlchar
decision. This ADR records the deferred decision under its own number.

## Decision

- **The consolidated pipeline's CDE cleaning coverage is spring 2015–2018,
  driven by `test_score_min_year`/`test_score_max_year` in `macros_va.doh`.**
  This matches the paper's analysis sample (4 cohorts of 11th-graders).
- **The 22 predecessor files outside that window are intentionally not
  rebuilt.** They fed no consolidated-pipeline consumer: every downstream
  artifact that exists was compared in the M4 run, and none read the
  2013/2014/2019/2020 cleaned files.
- The 22 MISSING_CONSOLIDATED rows in `output/m4_diff_summary.txt` are
  classified **intended deviation**, not regression, for ADR-0018 acceptance.

Alternatives considered and rejected: rebuilding the extra years for byte parity
with the predecessor (adds runtime and raw-data dependencies for files nothing
consumes); widening the macros (would silently change the analysis window — a
substantive sample decision outside consolidation scope).

## Consequences

**Commits us to:**

- Any future change to the analysis window is a single edit in
  `macros_va.doh` (plus a superseding ADR), and all CDE cleaning loops follow.
- M4 triage treats the 22 rows as resolved; the path-matrix README's
  "CDE year ranges" action item is closed. The 2013/2014/2019/2020 rows may be
  pruned from `do/check/m4_path_matrix.csv` (or left to report
  MISSING_CONSOLIDATED with this ADR as the recorded explanation).

**Rules out (for now):** treating MISSING_CONSOLIDATED on out-of-window CDE
years as a golden-master failure.

## Sources

- Triage: `quality_reports/reviews/2026-06-10_m4-full-golden-master_triage.md` §4
- Code: `do/va/helpers/macros_va.doh:116-122`; `do/data_prep/schl_chars/clean_*.do`
  loop lines above; `do/data_prep/schl_chars/clean_sch_char.do:603`
- Prior record: `quality_reports/plans/2026-04-25_consolidation-plan-draft.md:165`
  (deferred ADR earmark); `do/check/m4_path_matrix_README.md` item 2
- Run artifact: `output/m4_diff_summary.txt` (commit `7fe9c1a`)
- Session log: `quality_reports/session_logs/2026-06-09_e968d13-pull-and-phase7-fail-triage.md`
  Addendum 3
