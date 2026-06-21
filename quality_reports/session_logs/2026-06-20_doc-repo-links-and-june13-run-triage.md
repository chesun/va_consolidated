# Session Log — 2026-06-20 — Predecessor/other-repo doc links + June-13 full-run triage

**Goal:** (1) Fix docs that framed the predecessor repos as local-on-machine → use GitHub
links + Scribe paths; add a prominent README→HANDOFF link; link all other-repo mentions.
(2) Pull the finished June-13 server full run and inspect the logs.

## Part 1 — Doc fixes (living docs only; history left untouched per user)

- **Predecessor repos** reframed in `README.md` (§1 + §10), `HANDOFF.md` (§2 "For
  reference" note), `MEMORY.md` (`[LEARN:domain]` line 78). Each now carries **GitHub +
  Scribe**, not a laptop path:
    - `cde_va_project_fork` — <https://github.com/chesun/cde_va_project_fork>; Scribe `/home/research/ca_ed_lab/projects/common_core_va` (`$vaprojdir`).
    - `caschls` — <https://github.com/chesun/caschls>; Scribe `/home/research/ca_ed_lab/users/chesun/gsr/caschls` (`$caschls_projdir`).
  Sources: clone remotes + `do/settings.do:128,136` (cross-checked vs the fork's own
  `do_files/do_all.do:2`, `settings.do:25,28`).
- **Dropped a false claim:** README §10 said each predecessor was "archived at a
  `v1.0-archive` tag." `git tag` on both clones shows no such tag → removed.
- **Prominent HANDOFF link** added at README top (blockquote callout under the H1).
- **Other-repo links:** `claude-code-my-workflow` → <https://github.com/pedrohcgs/claude-code-my-workflow>
  (README §10); `claude-config` → <https://github.com/chesun/claude-config> (MEMORY line 105).
  `va_paper_clone` is **Overleaf-backed (no GitHub remote)** → no link added.
- **Plan persisted:** `quality_reports/plans/2026-06-20_predecessor-repo-refs-and-handoff-link.md`
  (+ INDEX entry).

## Part 2 — June-13 full run pulled + triaged

- Pulled `dc220e5 "full run june 13, 2026"` (5,161 files; fast-forward; my uncommitted doc
  edits untouched — none overlapped the incoming commit).
- Two June-13 master logs: `17-22-03.smcl` = aborted false start (4 [RUN]/2 [OK]);
  `17-23-53.smcl` = the real run (RUN START 13 Jun 17:23:53; 204 [RUN]/202 [OK]; **zero
  Stata `r()` errors**). The run spanned to 15 Jun 04:30 (VA estimation is the multi-hour
  leg).
- **Phase-7: 5/6 checks PASS** — `check_samples` (cdscode==1389, cohort sizes ok),
  `check_merges` (k12_main N==5009, canonical _merge codes), `check_va_estimates` (soft
  signals now actually run — cross-spec ela corr 0.997, peer corr 0.939; rc-clobber fix
  confirmed), `check_paper_outputs` (Table 1 N==1,784,445; Table 2 schools==5,009),
  `check_logs` (every do that ran has a log).
- **1 FAIL hard-halted the run** (the rc-clobber fix working as designed — the master log
  froze mid-`check_survey_indices` with no RUN END):
  `FAIL: imputed staffqoi98mean_pooled min = -3.0000 (expected ∈ [-2.01, 0])`
  (`check_survey_indices.do:167`).

### Diagnosis (code-traced, air-gapped — recorded in verification ledger)

NOT a pipeline regression. `staffqoi98` is **deliberately coded on an extended scale**
where −3 = "severe problem": `do/data_prep/qoiclean/staff/staffqoiclean1415.do:250/258/276`
(`replace qoi98temp = -3 if qoi98 == 4`; identical in `1617_1516.do` + `1819_1718.do`). A
school-pooled mean of −3.0 is therefore legitimate. `qoi98` is the **only** item with −3
coding (`grep 'qoi[0-9]+temp = -3'` across all qoiclean = qoi98 only), so no other source
item trips the same bound. The check's min-assertion `inrange(r(min), -2.01, 0)` assumes the
standard [−2,2] Likert, which is false for this item → **check-assumption error (ADR-0028
class), not a data fix.** Secondary: the ADR-0027 clamp `[-2,2]` (imputation.do:141/159/177/195,
fires only on `imputed`i'==1`) may over-censor legitimate severe (−3) imputed staffqoi98 values.

## Decision pending (Christina)

How to resolve the staffqoi98 FAIL — both ADR-class:

1. **Check bound** — widen `check_survey_indices.do:167` min-assertion for staffqoi98 to
   ~`[-3.01, 0]` (exempt the one severe-coded item), keep `[-2.01,0]` for the rest.
2. **Clamp floor** — decide whether imputed staffqoi98 should be clamped at −2 (current,
   censors severe) or −3 (preserves the severe category). Affects the climate/support indices
   staffqoi98 feeds.

Once decided → coder-critic per phase-1-review.md → Scribe re-run of Phase 5–7 → all 6
checks complete → then the M4 golden master + `tier_filter→smoke` revert remain (per ADR-0018).

## Status

- Working tree: README/HANDOFF/MEMORY/INDEX + ledger modified; new plan + this log untracked.
  **Uncommitted** — awaiting Christina's go-ahead (docs are not in-scope code per
  phase-1-review.md §3, so no coder-critic gate on the doc edits).
- HEAD: `dc220e5` (in sync with origin after the pull).

---

## Addendum — staffqoi98 fix implemented (2026-06-20, later)

Christina's decision: **widen the check bound + relax the clamp** for staffqoi98.

- `do/check/check_survey_indices.do` — SUB-CHECK 1 min bound is per-variable: `-2.01` for all items, `-3.01` for `staffqoi98mean_pooled` (both `imputed` + `compcase` sources). Header PURPOSE + INVARIANTS doc lines updated; PASS/FAIL messages reflect the per-var bound.
- `do/survey_va/imputation.do` — climatevars clamp floor is `cond("`i'"=="staffqoi98mean_pooled", -3, -2)`; ceiling stays +2. Other 3 category loops untouched (staffqoi98 isn't in them).
- **ADR-0032** written (amends ADR-0027 clamp; extends ADR-0028 check pattern) + indexed.
- **coder-critic 92/100 PASS** — independently re-verified the blast-radius claim (staffqoi98 excluded from all 3 built indices; only the 2 changed files + 1 archived file reference it). Review: `2026-06-20_staffqoi98-clamp-and-check_coder_review.md`.
- Ledger: diagnosis row marked RESOLVED; check rows re-stamped (hash a17d51fe4d1a); imputation.do rows added (83f87d53cf7d).
- Tier-1 self-check clean: `/* */` 5=5 both files, 0 hardcoded paths, no LEGACY writes, log-paths intact, `*`-glob comments converted to `<x>`.

**Air-gapped:** code-only + critic-verified, NOT re-run. NEXT: Christina pushes to Scribe → clean Phase 5–7 re-run → confirm `check_survey_indices` passes SUB-CHECK 1 and proceeds through SUB-CHECK 2 (staffqoi98 doesn't feed it) → all 6 checks complete → then M4 golden master + `tier_filter→smoke` revert (ADR-0018).

---

## Addendum 2 — removed all heuristic data-checks (2026-06-21, ADR-0033)

The 2026-06-20 Phase 5+7 rerun cleared staffqoi98 (SUB-CHECK 1 PASS both sources) then
hard-halted on a NEW pre-existing FAIL: `imputed z_climateindex min = -7.0888 (expected ∈
[-5,-1])` — an a-priori "typical z-score tail" heuristic (design memo l.224), independent of
the staffqoi98 fix (z_climateindex excludes staffqoi98; z-mean/SD passed → genuine heavy tail).

Christina's directive: **remove all heuristic checks without a hard basis.** Audited all 6
check files (`2026-06-21_heuristic-check-audit.md`); confirmed 3 borderline calls (remove VA
mean, remove CFR count soft, loosen centering). Implemented per **ADR-0033**:

- **Removed:** z-tail min/max + soft z-corr (survey); VA centered-mean + SD envelope + CFR
  count soft + 2 corr softs (va_estimates — all its checks were heuristic); age + cohort_size
  soft ranges (samples).
- **Loosened** (drop ≤0/≥0 centering, keep hard coding/math bound): source-item + raw-index
  ranges (survey).
- **Added** one hard-basis structural check to check_va_estimates (reference VA cols exist +
  non-empty); VA numeric correctness moves to the M4 golden master.
- **Kept:** all exact counts, coding ranges, z mean/SD (math), ADR-0011 raw-index test,
  merge codes, presence, check_logs.
- **Also fixed** (coder-critic M1) the pre-existing rc-clobber in check_samples.do's two
  wrapped fail-branches.

coder-critic **94/100 PASS**. ADR-0028 marked superseded-in-part; ADR-0032 cross-referenced;
ledger re-stamped (samples 5eca4736b2d2, survey f535769583d3, va_estimates a94610b44de7).
Air-gapped — not re-run. NEXT: same Phase 5+7 rerun should now run all 6 checks to completion.

---

## Addendum 3 — applied the long-deferred ADR-0011 sums→means fix (2026-06-21)

After the ADR-0033 heuristic removal, the rerun ran the raw-index check to completion for
the first time and hard-halted: `imputed raw climateindex min = -5.3293 (below -2.01)`.
This is NOT a heuristic — it's the ADR-0011 regression test firing correctly. The
constructors built each index as a SUM (no `/N`); ADR-0011 (Decided 2026-04-27) had
mandated MEANS (paper says "averages") but the fix was deferred through Phase 1b and never
applied.

FIXED: added `replace <idx> = <idx> / `: word count `<idx>vars''` after each sum loop in
both `imputedcategoryindex.do` + `compcasecategoryindex.do` (climate/quality/support;
counts 9/15/4). Headers updated; ADR-0011 marked implemented. coder-critic **96/100 PASS**
— verified z-invariance for every paper consumer (all regressions use `z_*`; the one
raw-name occurrence is consumed as `z_`), so no paper number changes.

CONSEQUENCE (flag for the next M4 golden master): the consolidated `categoryindex.dta` RAW
index columns now differ from the predecessor (which summed) — an INTENDED ADR-0011
deviation; the `z_*` columns and all regression exports stay identical. The M4 cf/triage
should whitelist climateindex/qualityindex/supportindex raw columns in both categoryindex
files.

Air-gapped — not re-run. NEXT: same Phase 5+7 rerun should now clear the raw-index check
and complete all 6 Phase-7 checks.

---

## Addendum 4 — clean Phase 5+7 rerun: all 6 checks PASS (2026-06-21)

Christina ran Phase 5+7 on Scribe with the staffqoi98 (ADR-0032), heuristic-removal
(ADR-0033), and ADR-0011 sums→means fixes, and pushed the logs (`1f6ec89`).

- Master `log/main_21-Jun-2026_14-01-50.smcl`: **RUN END present, 122 [RUN] = 122 [OK],
  0 r() errors** (the `13-39-22` log was an aborted false start, 120/118). First fully clean
  Phase-7 completion.
- **All 6 Phase-7 checks PASS** (each `log/check/*.log` has RUN END + 0 errors + PASS lines;
  the `FAIL:` strings are source-echoed `di as error` templates, none executed):
    - check_samples — N==1784445, 4 cohort Ns, cdscode==1389, grade/year, orthogonality, binary.
    - check_merges — _merge codes ≤5, k12_main==5009.
    - check_va_estimates — reference VA cols exist + non-empty (the new ADR-0033 structural check).
    - check_survey_indices — counts 9/15/4, _N==5625 both sources, staffqoi98 source ranges,
      z mean/SD, and **`raw indices ∈ [-2.01,2.01] (ADR-0011 sums→means fix verified)` both
      sources** — the ADR-0011 fix confirmed.
    - check_paper_outputs — Table 1 N==1,784,445, Table 2 schools==5,009.
    - check_logs — every do that ran has a log.

The three progressively-surfaced findings (staffqoi98 → heuristic checks → ADR-0011 sums)
are all cleared. Phase-7 data-checks are GREEN.

REMAINING for ADR-0018 `v1.0-final`: (1) one full `m4_acceptance_run=1` end-to-end run
(this was the targeted Phase 5+7 rerun on cached Phase 1–4); (2) M4 golden master
(`tier_filter="full"`) — whitelist the intended categoryindex.dta RAW-column ADR-0011 delta;
(3) revert `tier_filter→"smoke"`; (4) push held `ac749c5`.

---

## Next session pickup — FULL acceptance run in progress (2026-06-21)

**State at handoff:** Phase-7 data-checks are GREEN (confirmed clean Phase 5+7 rerun, master
`log/main_21-Jun-2026_14-01-50.smcl`). Christina then committed `2a93d15` ("edit toggles in
main.do for full run after debug") and **launched the FULL ADR-0018 acceptance run on
Scribe.** `do/main.do`: `m4_acceptance_run=1` (line 167) + all 7 phase toggles ON → full
from-scratch rebuild (samples + VA re-estimated, not cached). Runtime is multi-hour, possibly
~1–1.5 days (Phase 3 VA estimation via CFR shrinkage is the bottleneck).

origin/main HEAD at handoff: `2a93d15`. Working tree clean. All three fixes (ADR-0032
staffqoi98, ADR-0033 heuristic removal, ADR-0011 sums→means) are committed + pushed +
check-confirmed.

**When the run completes (do this in the fresh session):**

1. `git pull` on Scribe-side then locally; pull the new `log/` + `output/` + `tables/` +
   `figures/`. Find the newest `log/main_<date>_<time>.smcl`.
2. **Verify the full run:** master log has `RUN END`; `[RUN]` count == `[OK]` count; 0 `r(NNN);`
   error codes; all 7 phases present (data_prep → samples → va_estimation → va_tables[no-op]
   → survey_va → paper_outputs → data_checks). Then verify all 6 `log/check/*.log` show
   `RUN END` + 0 errors + PASS lines (same method as the 2026-06-21 confirmation: the `FAIL:`
   strings in check logs are source-echoed templates, not executed — a real FAIL `exit`s
   before RUN END).
3. **If clean → M4 golden master:** flip `do/check/m4_golden_master.do:394`
   `tier_filter "smoke"→"full"`; commit+push; Christina runs `nohup stata-mp -b do
   do/check/m4_golden_master.do &` on Scribe (8,324 pairs, ~80 min); pull `output/m4_diff_summary.txt`.
4. **Triage the golden master** against the 2026-06-10 full-triage baseline
   (`quality_reports/reviews/2026-06-10_m4-full-golden-master_triage.md`). **Expected/INTENDED
   deviations to whitelist (NOT regressions):**
   - **NEW this cycle — ADR-0011:** `imputed/compcasecategoryindex.dta` RAW `climateindex`,
     `qualityindex`, `supportindex` columns now differ from predecessor (means vs sums). The
     `z_*` columns + all index-on-VA regression exports stay identical. coder-critic
     2026-06-21_adr0011-sums-to-means verified z-invariance.
   - **NEW this cycle — staffqoi98 (ADR-0032):** imputed `staffqoi98mean_pooled` may differ
     (clamp floor −2→−3 for imputed obs). Not an index component → indices/regs unaffected.
   - **Carried (already-classified):** ADR-0030 distance-vintage drift (mindist_*, distance-
     restricted sample N shifts, restricted-variant va_* value diffs); ADR-0026 sibling;
     ADR-0029 22 MISSING_CONS (cde clean years 2013/14/19/20 descoped). See the 2026-06-10
     triage for the full population (3,969 PASS / 46 FAIL / 560 READ_ERROR / etc.).
5. **Revert** `tier_filter→"smoke"` (commit+push).
6. **Tag `v1.0-final`** once the golden master is accepted (all diffs explained).

**Stale-note corrections (verified 2026-06-21):** `ac749c5` (tier→smoke) is ALREADY in
main history — there is NO held commit to push. `tier_filter` is already committed as
`"smoke"`. Prior session logs' "held ac749c5 / 2026-06-12 stack" references are obsolete.

**Fresh-Scribe reminder:** a from-scratch run needs the SSC packages installed
(`installssc=1` in main.do for one run, currently 0) and the vendored
`data/raw/upstream/mattschlchar.dta` present (ADR-0023; gitignored, Scribe-only).
