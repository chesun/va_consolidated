# Chunk 10 — Discrepancy Report (Round-1 vs Round-2)

**Chunk:** 10 — Upstream + Python geocoding (6 files: `gecode_json.py`, `crosswalk_nsc_outcomes.do`, `crosswalk_ccc_outcomes.do`, `crosswalk_csu_outcomes.do`, `enrollmentconvert.do`, `siblingtest.do`)
**Date:** 2026-04-26
**Round-1 source:** `quality_reports/audits/round-1/2026-04-25_chunk10-upstream.md` + summary at `2026-04-25_deep-read-audit.md` §"Chunk 10"
**Round-2 source:** `quality_reports/audits/round-2/chunk-10-verified.md`

---

## Summary table

| Category | Count |
|---|---|
| AGREE | 11 |
| ROUND-1-MISSED | 5 |
| ROUND-2-MISSED | 1 |
| DISAGREE | 0 |
| TEMPORAL ARTIFACTS | 0 |

**Headline findings:**

1. **Bug 93 paper-impact analysis: BLAST RADIUS IS NULL FOR CURRENT PAPER OUTPUTS.** Round-2 traced the consumer chain: `nsc_enr_uc` is consumed by `csu_transfer_uc` (merge_k12_postsecondary.doh:462-463); `csu_transfer_uc` is NOT cited anywhere in `paper/common_core_va_v2.tex`. Composite outcomes `enr_4year`, `enr_2year`, `enr` etc. do NOT use `nsc_enr_uc`. **Bug 93 produces corrupted `nsc_enr_uc`/`csu_transfer_uc` indicators that do not propagate to any paper figure or table.** Pre-flight T3 verdict still holds, but severity downgrades for current paper.

2. **Bug 93 family is BOUNDED to NSC.** Round-2 confirmed by direct grep that `crosswalk_ccc_outcomes.do` and `crosswalk_csu_outcomes.do` have ZERO instances of the `& inlist(...) | inlist(...)` pattern. Combined with chunk-2's finds in `merge_k12_postsecondary.doh`, the **complete Bug 93 family is 4 instances** (NSC UC, NSC UC ontime, CCC ontime, CSU ontime) — no additional ones in chunk-10 territory.

3. **NEW from round-2: `crosswalk_nsc_outcomes.do:250` `egen ... by(\`id' collegecodebranch)` — local `id` not defined.** Possibly a silent bug where college_begin_date and downstream persistence dates aggregate across all students instead of per-student. T1 verification needed.

---

## AGREE rows

| # | Finding | R1 cite | R2 cite | Tier | Status |
|---|---|---|---|---|---|
| A1 | **Bug 93 verified at L218-219 (`nsc_enr_uc`) and L226-228 (`nsc_enr_ontime_uc`)** in `crosswalk_nsc_outcomes.do`. L221-223 (`nsc_enr_ucplus`) and L230-233 (`nsc_enr_ontime_ucplus`) protected by outer parens. | R1 chunk-10 §Bug 93 + pre-flight | R2 §Q2 | T3 | LOCKED — Phase 1 fix |
| A2 | **`gecode_json.py` uses US Census Bureau Geographies API.** Free, no API key. Benchmark=9, vintage=910 (2010-decennial geography). | R1 §"Geocoding pipeline mapped" | R2 §Q1 | T3 | LOCKED |
| A3 | **`gecode_json.py` is byte-identical (or only-copy) across both repos.** Round-1 said byte-identical across 3 predecessor repos; round-2 verified only one copy exists (in `cde_va_project_fork`). Reconciles to: only one copy, in cde_va_project_fork. | R1 §"Exactly one Python script" | R2 §Q9 | T3 | LOCKED |
| A4 | **Manual rename gap between Python output and Stata input**: `_geocoded2.csv` (Python) vs `_batch_geocoded.csv` (Stata). | R1 §"Manual rename gap" | R2 §Q8 | T3 | LOCKED — Phase 1 documentation |
| A5 | **`gecode_json.py` is static, run-once-cached.** Never invoked from any do-file. | R1 §"Static, run-once-cached" | R2 §11 (file 1 disposition) | T3 | LOCKED |
| A6 | **Cross-repo crosswalk producer table**: 5 .dta crosswalks consumed by `merge_k12_postsecondary.doh`, of which 3 are in scope (NSC, CCC, CSU outcomes) and 2 are external (Matt's `k12_ccc_crosswalk.dta` and `k12_csu_crosswalk.dta`). | R1 §"Cross-repo crosswalk producer table" | R2 §Q7 | T3 | LOCKED |
| A7 | **`enrollmentconvert.do` is local-machine one-time conversion utility.** Author intentionally placed in `do/local/`. No external consumer. Recommend leaving in `do/local/`. | R1 (chunk-10 disposition) | R2 §Q5 | T3 | LOCKED |
| A8 | **`siblingtest.do` is sandbox/diagnostic.** No external consumer. Should stay in `do/local/` or move to `do/explorations/`. | R1 (chunk-10 disposition) | R2 §Q6 | T3 | LOCKED |
| A9 | **`crosswalk_nsc_outcomes.do:34 `set trace on`** at top of script, no matching off until L422 (or never). Produces enormous log. | R1 (implicit) | R2 §"Other anomalies" L34 | T3 | LOCKED — Phase 1 fix |
| A10 | **`crosswalk_ccc_outcomes.do` and `crosswalk_csu_outcomes.do` hardcoded user-machine paths** at L8-18 (3 users hardcoded). Replication blocker. | R1 (Naven legacy code) | R2 §file 3 + 4 | T3 | LOCKED — Phase 1 portability fix |
| A11 | **External crosswalk dependencies** (`k12_ccc_crosswalk.dta`, `k12_csu_crosswalk.dta`) live in Matt's user directory and are NOT in either predecessor repo. Replication-package blocker if not deposited. | R1 §"Cross-repo crosswalk producer table" rows marked "NO" | R2 §Q7 | T4 | OPEN — Phase 1 vendoring decision |

---

## ROUND-1-MISSED rows (round-2 found, round-1 did not)

### M1 — `crosswalk_nsc_outcomes.do:250` `egen ... by(\`id' collegecodebranch)` — `id` macro not defined

- **Round-2 claim**: `egen college_begin_date = min(enrollmentbegin), by(\`id' collegecodebranch)` references local `id` but no `local id` or `global id` defined in the file. Stata would substitute empty string, making the `by()` group only `collegecodebranch`. **Possible silent bug**: college_begin_date would be the global min for that college across all students, not per-student.
- **Round-1**: missed.
- **Tier**: T1 — Christina runs `tab _grouping if collegecodebranch != ""` on Scribe and checks whether college_begin_date varies by student.
- **Severity**: HIGH if `id` is empty (silent data corruption in `college_begin_date` and downstream `nsc_persist_year{2,3,4}`); LOW if Stata recovers somehow or `id` is set globally elsewhere.
- **Action**: T1 verification BEFORE Phase 1 (this could be a real paper-impacting bug). Add to T1 list alongside Bug 93.

### M2 — Bug 93 paper-impact analysis: blast radius is NULL for current paper

- **Round-2 claim** (Q3): traced `nsc_enr_uc` consumer chain. Used at `merge_k12_postsecondary.doh:462-463` to build `csu_transfer_uc`. `csu_transfer_uc` is NOT cited anywhere in `paper/common_core_va_v2.tex`. Composite outcomes `enr_4year`, `enr_2year`, `enr` do NOT use `nsc_enr_uc`. **Bug 93's blast radius is NULL for current paper outputs.** `nsc_enr_ontime_uc` has NO consumer found in any do file in scope.
- **Round-1**: caught Bug 93 as paper-load-bearing without quantifying the blast radius.
- **Tier**: T3 (already verified by round-2 grep).
- **Severity**: round-2 downgrades from HIGH paper-load-bearing to HIGH-but-not-currently-paper-impacting. Future analyses (e.g., UC selectivity heterogeneity) would inherit the bug.
- **Action**: revise the bug-priority triage. Bug 93 is still HIGH-priority for Phase 1 fix (cheap fix, prevents future inheritance) but NOT a "blocker" for current paper integrity.

### M3 — CCC/CSU crosswalks: ZERO Bug 93-family patterns

- **Round-2 claim** (Q4): grep `& inlist(.*) | inlist` returned 0 matches in both `crosswalk_ccc_outcomes.do` and `crosswalk_csu_outcomes.do`. **Bug 93 family is bounded.**
- **Round-1**: did not perform this check.
- **Tier**: T3 — verified by grep.
- **Severity**: NIL (good news). Combined with chunk-2's `merge_k12_postsecondary.doh` finds, **the complete Bug 93 family is 4 instances** (NSC UC, NSC UC ontime, CCC ontime, CSU ontime).
- **Action**: locks the Bug 93 family scope. Phase 1 fix template can address all 4 with high confidence.

### M4 — `crosswalk_ccc_outcomes.do:78-79` Y2K-style century cutover

- **Round-2 claim**: `replace year = "19" + year if inrange(real(year), 92, 99)` then `"20" + year if inrange(real(year), 00, 20)`. Hardcoded century cutover at year 20 (2020). After 2020, term IDs would map to "0021" → discarded. **Time bomb post-2020.**
- **Round-1**: missed.
- **Tier**: T3.
- **Severity**: MEDIUM for any post-2020 CCC data refresh. Currently inert because data ends 2017.
- **Action**: Phase 1 — change to year >= 90 to "19xx" else "20xx", or extend cutover to >= 50 etc.

### M5 — `crosswalk_csu_outcomes.do:17` path with whitespace and editorial language ("actually clean")

- **Round-2 claim**: path `/secure/ca_ed_lab/data/restricted_access/clean/csu actually clean`. Naven-era informal directory naming.
- **Round-1**: missed.
- **Tier**: T3.
- **Severity**: portability hazard — POSIX-friendly tooling may break.
- **Action**: Phase 1 — rename path to remove whitespace + adjective.

---

## ROUND-2-MISSED rows (round-1 found, round-2 did not)

### N1 — `gecode_json.py` is the entire Python surface area

- **Round-1 claim**: chunk-10 explicitly noted "Exactly one Python script" — the entire Python surface area.
- **Round-2**: noted only that `gecode_json.py` exists in cde_va_project_fork; did not explicitly state "this is the entire Python surface area".
- **Reconciliation**: round-2's claim is consistent (`No copies in caschls/`, `No copies in va_consolidated/`) — so round-2 did de facto verify "only one Python file". Not a true round-2 miss.
- **Action**: no change.

---

## Adjudication & open questions

### Q1 — `crosswalk_nsc_outcomes.do:250` `id` macro (M1)

**Tier**: T1 — Christina runs on Scribe to confirm `id` resolution and college_begin_date semantics.

**Resolution path**:
- If `id` is set by some upstream `local`/`global`/`include`, M1 is moot (just bad code style).
- If `id` is empty, college_begin_date is global-min-by-college, not per-student — silently corrupting persistence dates.

**Severity if confirmed**: HIGH (potential silent data corruption affecting persistence outcomes — but `nsc_persist_*` may not flow into paper either, similar to `nsc_enr_uc` blast-radius analysis).

### Q2 — Bug 93 fix priority (M2)

Now that Bug 93 has null current-paper blast radius, the question is: do we still fix in Phase 1?

**Recommendation**: YES, fix in Phase 1.
- Cheap fix (4 lines wrapping in outer parens).
- Prevents future-analysis inheritance.
- Follows ADR-style convention "fix data integrity bugs even when they don't currently propagate."

### Q3 — `merge_k12_postsecondary.doh` external crosswalks (A11)

`k12_ccc_crosswalk.dta` and `k12_csu_crosswalk.dta` are in Matt's user directory, not in either predecessor repo.

**Tier**: T4 — Christina decides whether to vendor them into the consolidated repo or leave as external.

**Recommendation**: vendor into `data/restricted_access/clean/crosswalks/` for Phase 1 single-source-of-truth.

### Q4 — Geocoding rename gap (A4)

The `address_list_census_geocoded2.csv` (Python) → `address_list_census_batch_geocoded.csv` (Stata) rename is undocumented. Either:
- Production used the Python script + manual rename.
- Production used the Census Bureau's bulk batch tool (separate).

**Tier**: T4 — Christina knows.

**Recommendation**: document in Phase 1 README; if Python was the source, automate the rename inside the script.

---

## What changes for downstream chunks

- **Bug 93 family scope is LOCKED at 4 instances** (chunk-2 disc had 4; chunk-10 round-2 confirms no more in CCC/CSU crosswalks). Phase 1 patch template is finalized.
- **Bug 93 paper-impact downgrade** (M2) → bug-priority triage in Step 5 should reflect this. Bug 93 is HIGH-confidence-fix, LOW-current-impact (P2 not P1).

## Outstanding items (chunk 10 specifically)

1. T1 verify: `crosswalk_nsc_outcomes.do:250` `id` macro resolution (M1).
2. T1 verify: Bug 93 NSC UC count test (pre-flight proposed).
3. T4 escalation: external crosswalks vendoring (A11 / Q3).
4. T4 escalation: geocoding pipeline documentation (A4 / Q4).
5. **Revoke OpenCage API key** in `k12_postsec_distances.do:98` (chunk 7 finding, also tracked).
6. Phase 1 fixes: A1 (Bug 93 — bundled across 4 instances now), A4 (rename gap), A9 (set trace), A10 (Naven hardcoded paths), M4 (Y2K-style cutover), M5 (path with whitespace).
7. Phase 1 cleanup: A11 vendoring, A4 documentation.

---

## Verdict

**Strong agreement on chunk 10** (11 AGREE rows). Round-2 surfaced 5 NEW findings:
- M1 (potential `id` macro silent bug)
- M2 (Bug 93 blast radius is null for current paper)
- M3 (Bug 93 family bounded — no more in CCC/CSU)
- M4 (Y2K-style cutover in CCC)
- M5 (CSU path with whitespace)

**M2 + M3 together change Bug 93 priority**: still fix, but no longer paper-blocking for current outputs. **Bug 93 family is fully scoped at 4 instances; Phase 1 can fix with confidence.**

**M1 (the `id` macro question) is the most material open T1 item from chunk 10** — could affect persistence outcomes silently.
