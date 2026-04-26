# Chunk 7 — Discrepancy Report (Round-1 vs Round-2)

**Chunk:** 7 — Data prep (~32 files: ACS, k12_postsec_distance, schl_chars, prepare/, qoiclean/)
**Date:** 2026-04-26
**Round-1 source:** `quality_reports/audits/round-1/2026-04-25_chunk7-data-prep.md` + summary at `2026-04-25_deep-read-audit.md` §"Chunk 7"
**Round-2 source:** `quality_reports/audits/round-2/chunk-7-verified.md`

---

## Summary table

| Category | Count |
|---|---|
| AGREE | 16 |
| ROUND-1-MISSED | 4 |
| ROUND-2-MISSED | 1 |
| DISAGREE | 0 |
| TEMPORAL ARTIFACTS | 0 |

**Headline finding**: **Distance-FB Row 6 chain end-to-end CONFIRMED by both rounds.** The `d` token wires the distance leave-out variant for paper Tables 2/3 row 6. Producer: `k12_postsec_distances.do:120-122`. Wired in `macros_va_all_samples_controls.doh:69-86`. Two of 5 mindist variables (`mindist_any_nonprof_4yr`, `mindist_ccc`) actually enter regressions per `d_controls`. **This resolves the chunk-3 distance-FB-row-6 mystery on the producer side.** The remaining open question (paper Table 2/3 row 6 = `d` or `las`?) is downstream of chunk 7 — the table builder `va_spec_fb_tab.do` doesn't load `d`-suffixed `.ster` files. T4 question for Christina.

---

## AGREE rows

| # | Finding | R1 cite | R2 cite | Tier | Status |
|---|---|---|---|---|---|
| A1 | **Distance-FB chain confirmed end-to-end** (`k12_postsec_distances.do:120-122` → `merge_k12_postsec_dist.doh:23` → `macros_va_all_samples_controls.doh:69-86` `d` token → `macros_va.doh:200-203` `d_controls`). | R1 §"Distance-FB Row 6 mystery RESOLVED" | R2 §Q1 a-d | T3 | LOCKED |
| A2 | **Only 2 of 5 `mindist_*` variables in `d_controls`**: `mindist_any_nonprof_4yr` and `mindist_ccc`. The other three (`mindist_uc`, `mindist_csu`, `mindist_pub4yr`) are merged into the dataset but unused as controls. | R1 §"Distance-FB Row 6" detail | R2 §Q1d | T3 | LOCKED |
| A3 | **`clean_acs_census_tract.do` only processes 2010-2013** (4 ACS waves; L46 hardcodes `foreach year in 2010 2011 2012 2013`). Post-2013 ACS not loaded. Potential coverage gap for grade-6 cohorts after 2013. | R1 §"ACS data flow" | R2 §Q2 | T4 | OPEN — Q4 below |
| A4 | **`k12_postsec_distances.do` hardcoded asserts**: CSU=23 (L50), UC=9 (L54), private 4-year=115 (L58). Brittle to IPEDS schedule. | R1 chunk-7 New bugs:2 | R2 §File 5 bugs | T3 | LOCKED — Phase 1 fix |
| A5 | **`k12_postsec_distances.do:98` hardcoded API key** in commented-out `opencagegeo` line. Even though commented, secret is on disk and in git history. **Should be revoked.** | R1 chunk-7 New bugs:3 | R2 §File 5 bugs L98 | T3 | LOCKED — REVOKE the key (security) |
| A6 | **`reconcile_cdscodes.do:81`** in-place `save, replace` overwrites unpatched mindist file (lossy). 11 cdscodes patched. | R1 chunk-7 New bugs:4 | R2 §Q3 | T3 | LOCKED — Phase 1 fix to write new file |
| A7 | **`clean_charter.do:26` Apple Silicon detection broken** (`c(machine_type)=="Macintosh (Intel 64-bit)"` never matches arm64). | R1 chunk-7 New bugs:5 | R2 §Q9 | T3 | LOCKED — Phase 1 fix |
| A8 | **`enrollmentclean.do:21` female-encoding bug**: missing-gender → `female==0` (treated as male), pollutes male-by-grade totals. | R1 chunk-7 New bugs:6 | R2 §Q7 | T3 | LOCKED — Phase 1 fix |
| A9 | **`renamedata.do:77-84` 5-row drop discrepancy**: comment claims to "discard" 5 parent-1415 rows; code does NOT drop them. | R1 chunk-7 New bugs:7 | R2 §Q8 | T3 | LOCKED — Phase 1 fix |
| A10 | **`clean_sch_char.do` produces `data/sch_char.dta`** at top-level location. Path alignment confirmed with `va_het.do:32`. | R1 §"School-characteristics dependency tree" | R2 §Q5 | T3 | LOCKED |
| A11 | **CalSCHLS QOI year-batching: schema divergences mapped.** Parent 1415 missing qoi 64; parent 1516 missing 30/32/34; parent 1617 missing 32; staff 1718/1819 has yes/no questions (no `pctnotapp`); staff 1617_1516 missing qoi 24, 64. Secondary 1617 uses different raw question numbers (`a21`-`a39` shifted +1). | R1 §"CalSCHLS QOI year-batching logic" + chunk-7 New bugs:15 | R2 §Q6 | T3 | LOCKED |
| A12 | **`set varabbrev off, perm` consistency**: round-2 confirmed only staff 1415 and staff 1617_1516 set this; other 8 QOI files lack it. Round-1's "inconsistently set" claim verified at granular level. | R1 chunk-7 New bugs:14 | R2 §Q11 | T3 | LOCKED |
| A13 | **`hd2021.do` is auto-generated NCES dictionary opaque blob** (4322 lines). | R1 chunk-7 New bugs:17 | R2 §Q4 | T3 | LOCKED |
| A14 | **`clean_sch_char.do` charter + locale merged `m:1`** (time-invariant assumption). | R1 chunk-7 New bugs:9 | R2 (implicit, in dependency tree) | T3 | LOCKED |
| A15 | **`clean_staffdemo.do` 90% code duplication** between 2014-only and 2015+ blocks. | R1 chunk-7 New bugs:10 | R2 §"Additional bugs surfaced" (divergent fall-2014 vs fall-2015+ loops) | T3 | LOCKED — Phase 1 refactor |
| A16 | **`clean_ecn_disadv.do` writes restricted-data-derivative to `public_access/clean/`** (misleading folder). | R1 chunk-7 New bugs:11 | R2 (implicit) | T3 | LOCKED — Phase 1 fix path |

---

## ROUND-1-MISSED rows

### M1 — `clean_acs_census_tract.do:84` double-counts `s1501_c01_012e`

- **Round-2 claim** (File 1 bugs): The `tot_prop` check expression at L84 has the 4-year bachelor's term `s1501_c01_012e` listed TWICE. Almost certainly a typo. Because nothing asserts on the result, the bug is silent.
- **Round-1**: missed (round-1 noted only the year-coverage gap).
- **Tier**: T3.
- **Severity**: silent — the var is diagnostic only. Fix in Phase 1.

### M2 — `clean_locale.do:20` hardcodes 2015-16 NCES locale data for all years

- **Round-2 claim** (additional bugs surfaced): NCES locale data hardcoded to 2015-16, applied to all years.
- **Round-1**: missed.
- **Tier**: T3 — verify by reading file.
- **Severity**: time-invariance assumption (locale changes are slow) — defensible but brittle.

### M3 — Per-race dummies commented out in fall-2014 staff demo

- **Round-2 claim** (additional bugs): `clean_staffdemo.do` has divergent fall-2014 vs fall-2015+ loops with schema asymmetry — `fte` rowtotal only in 2014; per-race dummies commented out in 2014.
- **Round-1**: noted "90% code duplication" at high level; did not enumerate the specific schema asymmetries.
- **Tier**: T3.
- **Severity**: documentation gap; downstream code may silently rely on race fields that don't exist in 2014.

### M4 — `secqoiclean1415.do:17` `keep` and `rename` patterns suspicious

- **Round-2 claim** (File 27 bugs): `keep cdscode a14 a15 ... a28`. L15 attempts `rename a#_a# a#` but `#` is not a wildcard (Stata uses `*`). Likely no-op rename. Same for elabel rename at L19.
- **Round-1**: missed.
- **Tier**: T3.
- **Severity**: latent — depends on whether the rename was needed at all (perhaps the dataset already had the correct names).

---

## ROUND-2-MISSED rows

### N1 — `clean_frpm.do` hardcoded year-format branch (xls vs xlsx)

- **Round-1 claim** (chunk-7 New bugs:12): hardcoded year-format branch (xls vs xlsx); fragile to layout changes.
- **Round-2**: did not flag.
- **Tier**: T3.
- **Severity**: brittle to CDE format changes. Phase 1 fix.

---

## Adjudication & open questions

### Q1 — `mindist_uc/csu/pub4yr` unused as controls (A2)

Three of five mindist variables are in the merged dataset but not in `d_controls`. Either:
1. Intentional — only `mindist_any_nonprof_4yr` (any nonprofit 4-year, captures Stanford/USC/CalTech + UC/CSU) and `mindist_ccc` (community college) are the relevant policy-distance variables.
2. Bug — UC/CSU/pub4yr were intended to be in `d_controls` but were forgotten.

**Tier**: T4 — Christina to confirm. Likely (1).

### Q2 — Distance-FB Row 6 paper attribution (still open from chunk 3)

`d` is wired through chunks 7. But paper Table 2/3 row 6 is built by `va_spec_fb_tab.do` (chunk 3) which loops `lovar in l s a las` — does NOT include `d`.

So either:
- Paper Table 2/3 row 6 = `las` (joint), and `d`-suffixed `.ster` files exist on disk but never appear in the published table.
- OR paper Table 2/3 has a separate "distance" row that is NOT built by `va_spec_fb_tab.do` — produced elsewhere (chunk 9?).

**Tier**: T4 — Christina checks paper PDF.

**Recommendation**: high-priority Phase 0e Q&A.

### Q3 — Post-2013 ACS coverage (A3)

If post-2013 ACS isn't loaded, students whose grade-6 year was post-2013 would get no ACS controls (or stale 2013 ACS recycled). Grade-6 cohorts:
- Test-year 2015 → grade-6 = 2010 ✓
- Test-year 2016 → grade-6 = 2011 ✓
- Test-year 2017 → grade-6 = 2012 ✓
- Test-year 2018 → grade-6 = 2013 ✓

So actually 2015-2018 11th-grade cohorts have grade-6 years 2010-2013 — covered exactly. **No coverage gap for the current paper sample.** But future cohort additions would need post-2013 ACS.

**Tier**: T3 — verified by date arithmetic. Document in Phase 1 (consolidation README) that ACS coverage is 2010-2013 and intentional given current cohort window.

### Q4 — OpenCage API key revocation (A5)

Even though commented, the key `[REVOKED 2026-04-30]` is in source and git history. **Should be revoked** — security hygiene.

**Tier**: T1 — Christina logs into OpenCage and revokes/rotates the key.

**Severity**: low (geocoding is benign; rate-limit only) but standard hygiene.

---

## What changes for downstream chunks

- **Distance-FB Row 6 mystery is resolved on producer side** in chunk 7. Open question is downstream (chunk 9 — does any other file produce Table 2/3 row 6?).
- **`clean_locale.do` time-invariance** (M2) — should be considered when school chars change over time (locale doesn't change much, so probably fine).

## Outstanding items (chunk 7 specifically)

1. T1: revoke OpenCage API key (A5/Q4).
2. T4 escalation: paper Table 2/3 row 6 attribution (Q2).
3. T4 escalation: `mindist_uc/csu/pub4yr` unused intentionally? (A2/Q1).
4. Phase 1 fixes: A4-A9, A11-A12, A14-A16, M1-M4, N1.
5. Phase 1 documentation: ACS 2010-2013 coverage is intentional (Q3).

---

## Verdict

**Strong agreement on chunk 7** (16 AGREE rows). Round-2 surfaced 4 minor new bugs round-1 missed; round-1 caught 1 small thing round-2 didn't. **Distance-FB Row 6 producer chain is now LOCKED.** Phase 1 fix template for chunk 7 is clear.
