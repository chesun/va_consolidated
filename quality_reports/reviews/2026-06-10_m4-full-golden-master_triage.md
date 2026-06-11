# M4 Full Golden-Master Run — Triage Review
**Date:** 2026-06-10
**Reviewer:** Claude (session triage; not a critic-agent review)
**Target:** `output/m4_diff_summary.txt` (commit `7fe9c1a`, generated 2026-06-09 22:08 on Scribe)
**Status:** Active

## Run integrity

- Tier `full`, 8,324 matrix rows compared, runtime 80.1 min.
- `log/check/m4_golden_master.log` shows clean RUN START → RUN END; 0 Stata error codes; summary footer written. The rc-report fix (`17418e9`) is working — every READ_ERROR row now carries an explicit `rc=` value.

## Headline tally

| Status | N | Of which |
|---|---|---|
| PASS | 3,969 | 3,166 ster (0 coef/SE diffs), 333 dta, 166 pdf, 42 tex, 20 csv, 8 xlsx, 234 other |
| MISSING_PREDECESSOR | 3,727 | **3,717 are "neither side exists"** (benign matrix over-enumeration — see §3); only 10 are true predecessor-missing |
| READ_ERROR | 560 | 557 `rc=9` (structural `cf` mismatch), 3 `rc=900` (var-limit, file too wide to compare) |
| FAIL | 46 | all `.ster`, all in `spec_test` (17) + `reg_out_va` (29) |
| MISSING_CONSOLIDATED | 22 | all `data/cleaned/cde/*` year 2013/2014/2019/2020 + `sch_char_2019.dta` |

Where both sides produced a comparable file, the parity rate is high: 3,969 PASS vs 46 FAIL + 560 structural mismatches. Every compared `.tex`, `.pdf`, `.csv`, `.xlsx` PASSed (byte-identical or within tolerance) — **all paper-facing tables and figures match the predecessor exactly.**

## 1. The 46 FAILs — small coef diffs, fully confined to lagged/sibling sample variants

- Tolerances (from `do/check/m4_golden_master.do:262`): coef ≤ 0.01, SE ≤ 0.05. All 46 exceed the coef tolerance only; range max|db| = 0.0100–0.0470. All SE diffs are within tolerance (max 0.0186).
- **Every one of the 46 paths contains `_la_`, `_las_`, or `sib1`** (verified: 0 FAILs outside those variants). None of the main VA estimate files FAIL — the 3,166 PASSing `.ster` include the primary specs with literally 0 cumulative coef/SE diffs.
- Pattern: outcome regressions (`reg_enr_2year_va_*`, `reg_enr_4year_va_*`) and spec tests on the lagged-survey (`la`/`las`) and sibling-instrument (`s_sp_sib1`) samples.
- **Triage hypothesis (unconfirmed):** these are the sample variants touched by intended Phase-1 changes — ADR-0026 (sibling-xwalk producer consolidation) for the `sib1` cluster, and the `l`-variant student drops documented in ADR-0028 (`merge_loscore.doh:76,82`) for the `la`/`las` cluster. Magnitudes (≤0.047, i.e., a few hundredths of an SD on enrollment outcomes) are consistent with marginal sample-composition shifts, not a broken estimator. **Needs confirmation on Scribe**: compare e(N) between predecessor and consolidated for 2–3 of these `.ster` pairs; if N differs by a handful of obs in the direction the ADRs predict, classify as intended deviation and record in an ADR/ledger row.

## 2. The 560 READ_ERRORs — structural mismatches, the main open question

`cf _all` rc=9 means the two files don't conform (different obs count, or a variable present on one side only) — `cf` can't even begin value comparison. Distribution:

| Area | N |
|---|---|
| `estimates/va_cfr_all_v1` + `_v2` (va_est_dta, va_het, …) | 479 |
| `data/cleaned` (va_samples score_*/out_*, calschls analysisready, k12_postsec_distance, sch_char.dta, nces locale) | 55 |
| `tables/va_cfr_all_v1` + `_v2` (.dta table sources) | 20 |
| `estimates/survey_va/factor` (imputed index files) | 3 |
| `output/dta` | 3 |

Two readings, and the evidence favors the benign one:

- **Benign (likely):** consolidated files carry added/renamed/dropped *variables* (or different obs counts from intended ADR changes — e.g., ADR-0027 clamp re-generates imputed survey files; the smoke run's `va_all.dta` rc=9 was already flagged as a shape difference). Crucially, the *downstream* artifacts built from these very files — 3,166 `.ster`, all tex/pdf/csv — PASS. If the analytic content of `score_*`/`out_*` samples had regressed, the esters could not match to 0 diffs.
- **Regression (must rule out):** a real data change that happens not to feed the compared esters.

**Needs Scribe**: for a sample of rc=9 pairs (start with `va_samples_v1/score_b.dta`, `va_est_dta/va_all.dta`, one `analysisready` file), run `describe, short` + `count` on both sides and diff the variable lists. If diffs are added-variable-only (or ADR-traceable obs deltas), record the pattern once and classify the family. The 3 rc=900 files (`parentanalysisready`, `secanalysisready`, `sec1617`) are too wide for `cf` under current `maxvar` — re-run those three with `set maxvar` raised or compare with a var-by-var loop.

## 3. MISSING_PREDECESSOR — 99.7% benign

3,717 of 3,727 rows say "neither side exists": the path matrix enumerates the full spec grid (e.g., 1,504 × 2 `reg_out_va` combinations) but neither the predecessor nor the consolidated run produces those cells. Both sides absent = parity holds; no action. The remaining 10 (all `reg_out_va`) exist only on the consolidated side — likely new outputs; worth a one-line confirm.

## 4. MISSING_CONSOLIDATED — 22 files, looks like year-coverage descope

All are `data/cleaned/cde/{elsch,enr,frpm,staffcred,staffdemo,staffschoolfte}` for years **2013, 2014, 2019, 2020**, plus `sch_char_2019.dta`. The analysis years (1415–1819) all PASS. The predecessor cleaned a wider year range than the consolidated pipeline rebuilds. **Needs confirmation**: check whether an ADR or the consolidation plan documents the year-range restriction; if yes, record as intended; if no, decide whether the extra years matter (they don't feed any FAILing/PASSing downstream artifact, since all downstream artifacts that exist were compared).

## Verdict

**The golden master looks good where it matters most**: all paper-facing tables/figures byte-identical, main VA estimates at 0 diffs, and the FAILs are small-magnitude and perfectly confined to the sample variants Phase-1 ADRs intentionally touched. Not yet certifiable as ADR-0018 acceptance, because three things still need on-server confirmation:

1. e(N) spot-check on 2–3 FAIL `.ster` pairs → tie the 46 FAILs to ADR-0026/0028.
2. `describe`/`count` spot-check on rc=9 families → classify the 560 structural mismatches (variable-set vs obs-count; intended vs regression). Re-compare the 3 rc=900 files with raised `maxvar`.
3. Confirm the cde 2013/14/19/20 year descope is intended (ADR or plan citation).

Also still pending from the prior session: the clean Phase 5–7 re-run (clamp propagation + all six checks to completion), and reverting `tier_filter` → `"smoke"` in `do/check/m4_golden_master.do:394` after acceptance.

## Spot-check commands

Paths below are taken from `do/check/m4_path_matrix.csv` (predecessor root `/home/research/ca_ed_lab/projects/common_core_va/`, consolidated root `.../common_core_va/consolidated/`).

### 1. FAIL `.ster` e(N) comparison (Stata on Scribe)

One pair per FAIL cluster — `sib1`, `_las_`, `_la_`:

```stata
* sib1 cluster (ADR-0026 hypothesis)
estimates use "/home/research/ca_ed_lab/projects/common_core_va/estimates/va_cfr_all_v1/spec_test/spec_math_s_sp_sib1_ct.ster"
di e(N)
estimates use "/home/research/ca_ed_lab/projects/common_core_va/consolidated/estimates/va_cfr_all_v1/spec_test/spec_math_s_sp_sib1_ct.ster"
di e(N)

* las cluster (ADR-0028 hypothesis) — repeat pattern for:
*   estimates/va_cfr_all_v1/reg_out_va/reg_enr_2year_va_ela_las_sp_ad_ct_p_m.ster
* la cluster — repeat for:
*   estimates/va_cfr_all_v1/spec_test/spec_ela_la_sp_lad_ct.ster
```

Decision rule: small N delta consistent with ADR-0026 (sibling xwalk consolidation) / ADR-0028 (`merge_loscore.doh` `l`-variant drops) → intended deviation, record. Equal N with coef diffs → investigate the estimator path.

### 2. rc=9 structural classification (Stata on Scribe)

One representative per family:

```stata
use "/home/research/ca_ed_lab/projects/common_core_va/data/va_samples_v1/score_b.dta", clear
count
describe, short
use "/home/research/ca_ed_lab/projects/common_core_va/consolidated/data/cleaned/va_samples_v1/score_b.dta", clear
count
describe, short
```

Repeat for `estimates/va_cfr_all_v1/va_est_dta/va_all.dta` and `data/cleaned/calschls/analysisready/staffanalysisready.dta` (predecessor sides per the matrix). Diff the variable lists (`ds`). Benign: same N + variable-set differences (optionally `cfout <common varlist>` to confirm shared values match). Suspicious: unexplained N delta.

For the 3 rc=900 files (`parentanalysisready`, `secanalysisready`, `sec1617`): `set maxvar 32767` first, then retry `cf _all` — they were too wide to load under the default.

### 3. cde year descope (local, no server)

## Spot-check RESULTS (2026-06-11, log commit `aa43824`)

**Section 1 — FAIL .ster e(N):** all three clusters show sample-composition shifts, confirming the coef diffs are sample-driven, not estimator-driven: sib1 N +41 (clusters 1020→1015), las N −564 (1228→1219), la N −1,084 (1263→1252).

**Section 2 — READ_ERROR .dta:** all six pairs have **identical obs counts and identical variable sets** — the rc=9s were VALUE diffs, not structural. Per-pair cf on common vars:

| Pair | Verdict |
|---|---|
| `sec1617` | **cf rc=0 — fully identical.** rc=900 was a pure maxvar artifact → reclassify PASS. |
| `score_b` | Only **5 vars differ, all `mindist_*`** (uc/csu/pub4yr/ccc/any), 50,766 mismatches each (2.8% of 1.78M rows); other 72 vars identical. → the k12_postsec_distance input differs between predecessor and consolidated (matches the rc=9 on `k12_postsec_{distance,mindistance}.dta`). **No ADR documents a distance-data change — OPEN QUESTION.** Note: `d` in sample codes (`lad`, `lasd`) is plausibly the distance restriction, so mindist diffs may be the upstream root cause of part of the Section-1 N deltas. |
| `va_all` (580/950 vars), `staff`/`parent`/`sec analysisready` (~577 each) | Differing vars are restricted-variant VA estimates (`va_*_s/ls/as_*`) — downstream propagation of the same sample shifts. |

## ROOT CAUSE — mindist_* divergence (2026-06-11, code + log traced)

**The distance input is non-deterministic by design: the producer fetches the live CDE school directory at run time.** Chain of evidence:

1. `do/data_prep/k12_postsec_distance/k12_postsec_distances.do:139` — `capture import delimited "https://www.cde.ca.gov/schooldirectory/report?rid=dl1&tp=txt", clear`; the cached `$distance_dtadir/raw/pubschls.txt` (downloaded 3/20/23) is only the `_rc!=0` fallback (`:142`). This is predecessor-original logic (relocated verbatim), not a consolidation change.
2. The e968d13 acceptance-run log (`log/data_prep/k12_postsec_distance/k12_postsec_distances.log:276-282`) shows the URL import succeeded — the fallback `import delimited` echoes but produces **no obs-count output**, i.e. the `if _rc!=0` block did not execute. The consolidated distance file was therefore built from the **June-2026 CDE directory**, while the predecessor's on-disk file reflects an earlier directory snapshot.
3. Downstream computation (`geodist` at `:178`, `collapse (min) … by(cdscode)` at `:186`) is deterministic, so the value diffs come entirely from the input vintage: school universe + coordinate updates between the two fetches → `mindist_*` changes for affected schools → 50,766 student rows (2.8%) in `score_b` → distance-restricted/controlled samples and restricted-variant VA estimates shift slightly → the 46 small-coef ster FAILs and the va_all/analysisready value diffs. (The `sib1` cluster may additionally reflect ADR-0026's sibling-xwalk consolidation; both contribute.)
4. IPEDS HD2021 (`hd2021.do`, fixed 2021 vintage CSV on disk) is not a drift source.

**Classification: input-vintage drift, not a code regression.** The consolidated pipeline is behavior-identical; the input moved underneath it.

**Decision needed (Christina):**

- **Option A — pin the input:** drop the live-URL fetch (or gate it behind a toggle) and always read the cached `pubschls.txt`, making the pipeline reproducible and golden-master-stable. Deviates from predecessor code; needs an ADR.
- **Option B — accept the drift:** document via ADR that distance-derived artifacts are expected to differ across run dates; golden-master treats the mindist family as intended deviation. Keeps code identical; replication runs will keep drifting with CDE updates.

With the root cause identified, the entire FAIL + READ_ERROR population is classified pending the Option A/B decision (plus the optional `sib1` attribution split between mindist drift and ADR-0026 — only worth doing if a precise per-ADR attribution is wanted).

Grep `do/data_prep/` for the cde cleaning year-loop bounds; confirm 2013/2014/2019/2020 are deliberately excluded (analysis years 1415–1819 all PASS). Cite the existing plan/ADR if one records it; otherwise write a short ADR documenting the descope.
