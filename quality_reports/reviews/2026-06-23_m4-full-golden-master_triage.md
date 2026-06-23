# M4 Full Golden-Master Triage — v1.0-final Gate

**Date:** 2026-06-23
**Reviewer:** Claude (triage)
**Target:** `output/m4_diff_summary.txt` (tier=full, 8,324 pairs) + June-21 full acceptance run
**Verdict:** **GATE PASSED** — no regression class; all deviations whitelisted (ADR-0011/0026/0027/0028/0029/0030)
**Status:** Active
**Supersedes:** `quality_reports/reviews/2026-06-10_m4-full-golden-master_triage.md` (June-9 baseline run)

---

## 1. What this run is

The first golden master against a **fully clean from-scratch acceptance run** that has all the late-Phase-7 fixes applied:

- **Pipeline:** launched 2026-06-21 (`2a93d15`), `m4_acceptance_run=1` + all 7 phases ON. Committed `f2301455` ("june 21 full pipeline run").
- **Golden master:** `tier_filter="full"` (`077f9710`), run 2026-06-23, committed `ae1fa85e`.

This run reflects, relative to the June-9 baseline: ADR-0011 (sums→means in category indices, `df32e94a`), ADR-0027 (clamp propagation), ADR-0030 (CDE-directory distance pin), and ADR-0033 (removal of heuristic Phase-7 checks).

---

## 2. Gate criteria (ADR-0018)

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | Master log RUN END, all 7 phases | **PASS** | `main_21-Jun-2026_14-15-58.smcl` + `20-27-50.smcl`: PHASE 1–7 all fired; `RUN END 23 Jun`; 0 fired `r(#)` |
| 2 | All 6 Phase-7 data-checks PASS | **PASS** | 29 fired PASS, **0 fired FAIL**, 0 assertion halts across the 6 `log/check/check_*.log` |
| 3 | ADR-0011 means fix live | **PASS** | check_survey_indices: "raw indices ∈ [-2.01, 2.01] (ADR-0011 sums→means fix verified)" (imputed + compcase) |
| 4 | Paper output parity | **PASS** | **0** non-PASS rows among all `tex`/`pdf`/`csv` pairs |
| 5 | No new regression class | **PASS** | Deviation set matches June-9 baseline fingerprint (see §3–§4) |

Paper-facing anchors all reproduced: Table 1 N = 1,784,445; Table 2 N schools = 5,009; k12_main N = 5,009 (89% retention).

---

## 3. Summary tally vs June-9 baseline

| Status | June-9 (`9 Jun 20:48`) | June-23 (`23 Jun 11:23`) | Δ |
|---|---:|---:|---:|
| PASS | 3,969 | 3,967 | −2 |
| FAIL | 46 | 46 | 0 |
| MISSING_PREDECESSOR | 3,727 | 3,727 | 0 |
| MISSING_CONSOLIDATED | 22 | 22 | 0 |
| READ_ERROR | 560 | 562 | +2 |
| FAIL_VISUAL / FAIL_BINARY / SKIP / UNKNOWN | 0 | 0 | 0 |

Runtime 40.2 min. Net −2 PASS / +2 READ_ERROR — fully accounted for in §4.

---

## 4. Deviation classification (all whitelisted)

### 4a. 46 FAIL — restricted-variant `.ster` only (whitelisted)

- 100% are `.ster` in `spec_test/` or `reg_out_va/`; **every one** matches a restricted-variant tag (`_la_`, `_las_`, `_b_`, `_ls_`, `sib1`, `dk_…las`). **Zero main-spec FAILs.**
- Magnitudes: `max|db|` 0.0100–0.0401 (just over the 0.01 point-estimate tolerance); all `max|dSE|` within the 0.05 SE tolerance.
- **Composition shift vs June-9** (still 46 total — boundary cases crossing the 0.01 line, expected from the distance-pin + clamp rebuild):
  - `reg_enr_4year_va_{ela,math,ela_math}_las_sp_ad_ct_p_m` (v1+v2, 6 files) → replaced by the `_b_sp_bd_ct_p_m` siblings.
  - `+ dk_spec_enr_2year_la_sp_lad_ct` (v1); `− spec_ela_la_sp_lad_ct` (v2).
- **Classification:** intended/benign per ADR-0026 (sibling), ADR-0028 (thin VA cells), ADR-0030 (distance-vintage drift). Deterministic estimators on slightly-different restricted-sample membership; not a code regression.

### 4b. 22 MISSING_CONSOLIDATED — byte-identical to baseline (ADR-0029)

CDE years 2013/2014/2019/2020 for elsch/enr/frpm/staffcred/staffdemo/staffschoolfte + `sch_char_2019.dta`. Descoped per ADR-0029. Set unchanged from June-9.

### 4c. 562 READ_ERROR — structural `cf` mismatches, all `.dta` (whitelisted)

All `rc=9` (cf cannot conform the two files → differing variable set / N), 100% `.dta`. Family = restricted-sample VA outputs (`va_*_dta`), survey category indices, analysisready. Downstream paper outputs built from these all PASS → variable-set diffs, not value regressions.

- **Δ vs June-9 (+2):** `calschls/secondary/sec1617.dta` resolved (now conforms); `+ va_enr_2year_la_sp_l_ct.dta`, `+ va_enr_4year_la_sp_l_ct.dta`, `+ va_math_la_sp_l_ct.dta` (v2 distance-restricted `la` VA `.dta`). All in the established structural-mismatch family.
- **categoryindex.dta (ADR-0011):** `imputed/compcase categoryindex.dta` + `imputedindexwithdemo.dta` show `rc=9` (READ_ERROR) — the structural manifestation of the means change vs the predecessor's sums. `z_*`-scored columns and all downstream regressions PASS. Already READ_ERROR in the June-9 file too, so the means fix did not add new READ_ERRORs here; the +2 net is the `va_*_la_sp_l_ct.dta` trio minus the `sec1617.dta` resolution.

### 4d. 3,727 MISSING_PREDECESSOR — benign

Dominated by "neither side exists" phantom-CSV rows (3,717 at June-9). Neither pipeline produces these; matrix-manifest artifacts, not pipeline gaps.

---

## 5. Observation for Christina (not a gate blocker)

Two full-run master logs overlap in wall-clock time:

- `main_21-Jun-2026_14-15-58` — START 21 Jun 14:15:58 → END 23 Jun 02:03:07
- `main_21-Jun-2026_20-27-50` — START 21 Jun 20:27:50 → END 23 Jun 10:08:48

If two from-scratch runs wrote to the same output dirs concurrently, there is a theoretical interleaved-write risk. **Empirically ruled out** for the committed state: all 6 data-checks validate internal consistency of the *final* outputs (N counts, merge codes, index ranges, VA columns) and the golden master validates output parity — both on the final on-disk state, both clean. Worth a one-line confirmation of what was launched, but the evidence says the final outputs are coherent.

---

## 6. Verdict & remaining steps

**M4 golden-master gate: PASSED.** No regression class surfaced; every deviation maps to a documented, whitelisted ADR; all paper-facing outputs reproduce exactly.

Remaining ADR-0018 sequence:

1. **Revert** `tier_filter → "smoke"` (`do/check/m4_golden_master.do:394`, currently `"full"`) — leaves the committed default safe for future smoke runs.
2. **Tag** `v1.0-final`.

---

## Cross-references

- Baseline triage: `quality_reports/reviews/2026-06-10_m4-full-golden-master_triage.md`
- Gate criteria: ADR-0018; plan v3 §3.5
- Whitelisted deviations: ADR-0011, ADR-0026, ADR-0027, ADR-0028, ADR-0029, ADR-0030, ADR-0033
- Tolerance table: `.claude/rules/replication-protocol.md` §3
