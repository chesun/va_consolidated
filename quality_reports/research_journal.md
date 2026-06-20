# Research Journal — VA Consolidated (CEL Value-Added Project)

Append-only agent-level history. One entry per agent invocation. See `.claude/rules/logging.md` §3.

### 2026-06-12 — coder-critic
**Phase:** Execution (Phase 1b §4.2 — reproducibility pin)
**Target:** `do/data_prep/k12_postsec_distance/k12_postsec_distances.do` + `do/settings.do` (ADR-0030 distance-input pin)
**Score:** 96/100 PASS
**Verdict:** Pinned `else` branch byte-identical to original `_rc!=0` fallback; live-URL fetch preserved in `==1` branch; gate string + default-off semantics correct; surrounding tempfile/local state untouched. No Critical/Major. Minor (−4): missing ledger row — added in same commit.
**Report:** `quality_reports/reviews/2026-06-12_cde-directory-pin_coder_review.md`; commit `8660451`

### 2026-06-11 — coder-critic
**Phase:** Execution (Phase 1c — M4 triage tooling)
**Target:** `do/debug/m4_spotcheck_triage.do` (new read-only spot-check script)
**Score:** 97/100 PASS
**Verdict:** All 9 predecessor/consolidated path literals verified verbatim against `m4_path_matrix.csv`; rc-clobber-clean; cf gated on equal N; logging/comment conventions OK. Minor (−3): unchecked cf re-load could self-compare → fixed pre-commit with a guard.
**Report:** `quality_reports/reviews/2026-06-11_m4-spotcheck-triage_coder_review.md`; commit `8322680`

### 2026-06-10 → 06-13 — triage (session, Claude)
**Phase:** Execution (full golden-master triage)
**Target:** `output/m4_diff_summary.txt` (8,324 pairs) + spot-check log
**Score:** N/A (triage)
**Verdict:** Whole non-PASS population classified — 46 FAILs sample-driven (+ADR-0026), 560 READ_ERROR value-diffs (mindist root-caused to live-URL fetch → ADR-0030 pin), 22 MISSING_CONS intended (ADR-0029), sec1617 reclassified PASS. No regressions.
**Report:** `quality_reports/reviews/2026-06-10_m4-full-golden-master_triage.md`

### 2026-06-09 (PM) — coder-critic
**Phase:** Execution (golden-master harness fix)
**Target:** `do/check/m4_golden_master.do` rc-reporting fix (`` `_rc' `` local-macro → blank rc; 4 branches)
**Score:** 96/100 PASS
**Verdict:** READ_ERROR/FAIL detail strings used `` `_rc' `` (empty local) not system `_rc` → summary printed `rc=` blank (smoke `va_all.dta`). Fix: `local rc=_rc` before the returns, detail uses `` `rc' ``. Reporting-only; categorization/tally unchanged. −4 ledger hygiene (rows added post-review).
**Report:** `quality_reports/reviews/2026-06-09_golden-master-rc-report_coder_review.md`

### 2026-06-09 — coder-critic
**Phase:** Execution (Phase-7 check fixes)
**Target:** `check_va_estimates.do` soft-downgrade (ADR-0028) + `check_survey_indices.do` SUB-CHECK 1 re-point (ADR-0027)
**Score:** 94/100 PASS
**Verdict:** Per-spec count check hard→soft (thin variant cells accepted); survey source re-pointed LEGACY→CANONICAL so it validates the clamped output. Correct, ADR-faithful, Tier-1 clean. 2 doc-hygiene Minors fixed post-review.
**Report:** `quality_reports/reviews/2026-06-09_check-soft-and-repoint_coder_review.md`

### 2026-06-09 — coder-critic
**Phase:** Execution (survey imputation fix)
**Target:** `do/survey_va/imputation.do` clamp OLS-imputed QOI items to Likert [-2,2] (ADR-0027)
**Score:** 82/100 PASS
**Verdict:** Clamp idiom correct (incl. `!missing` guard). HIGH flag (−15): clamp writes CANONICAL but the FAILing check read the LEGACY file → resolved by the re-point.
**Report:** `quality_reports/reviews/2026-06-09_imputation-clamp_coder_review.md`

### 2026-06-09 — coder-critic
**Phase:** Execution (Phase-7 check harness fix)
**Target:** `check_va_estimates.do` + `check_survey_indices.do` rc-clobber hard-halt fix (13 branches)
**Score:** 95/100 PASS
**Verdict:** Pre-fix `exit _rc` clobbered to 0 by `cap log close`/`translate` → FAILing checks exited clean, pipeline never halted (server run e968d13). Fix: `local rc=_rc` after each capture, `exit `rc''`. Complete, minimal, no over-reach.
**Report:** `quality_reports/reviews/2026-06-09_check-files-rc-fix_coder_review.md`

### 2026-06-01 01:15 — coder
**Phase:** Execution (Phase 1 consolidation debug)
**Target:** `do/main.do` Phase 4 (VA TABLES + FIGURES) — empty no-op with `<...>` placeholders
**Score:** N/A (debug/cleanup)
**Verdict:** Phase 4 body was an unfilled TODO stub (placeholder tokens + phantom `do/share/va/` path) with toggle on — a harmless no-op, not a functional bug. The planned VA/non-VA producer split never happened; all VA producers run in Phase 6 (batch 10a) + Phase 3. Orphan sweep confirmed no producer stranded. Fix: stub → accurate NOTE, `run_va_tables` → 0. Also confirmed Phase 3/5 `/* */` wraps are local debug-skips, not committed.
**Report:** session log `2026-05-31_va-fig-pdf-save-mkdir-and-r601-diagnosis.md`; ledger rows 2026-06-01T01:15Z

### 2026-06-01 00:30 — coder
**Phase:** Execution (Phase 1 consolidation debug)
**Target:** `do/survey_va/mattschlchar.do` (missing-dataset error); ADR-0023 + vendoring scaffold
**Score:** N/A (debug/fix dispatch)
**Verdict:** M4 errored at mattschlchar.do:139 — `clean==0` block was empty so the cleaned `mattschlchar.dta` was never provisioned into the sandbox; `clean==1` rebuild branch unusable (Matt's dir access lost). Fix: vendor the cleaned file to `data/raw/upstream/` and read it in the `clean==0` block (`$datadir_raw/upstream/mattschlchar` → `$datadir_clean/schoolchar/mattschlchar`). Wrote ADR-0023 (supersedes ADR-0013 in part); created path-stub README + .gitignore exceptions per ADR-0008 convention. Requires one-time `cp` on Scribe.
**Report:** ADR-0023; `data/raw/upstream/README.md`; ledger rows 2026-06-01T00:30Z

### 2026-05-31 23:50 — coder
**Phase:** Execution (Phase 1 consolidation debug)
**Target:** `do/va/va_score_sib_lag.do`, `do/va/va_out_sib_lag.do` (r(111) sibling-lag controls); log `log/va/va_score_sib_lag.smcl:841-845`
**Score:** N/A (debug/fix dispatch)
**Verdict:** r(111) `old1_sib_enr_2year not found` — lag controls built in siblingoutxwalk.do but dropped by merge_sib.doh:64 `keepusing(touse* *sibling*)` before score_s/out_s saved. NOT a relocation regression (merge_sib.doh byte-identical to predecessor; predecessor .smcl shows same r(111)). Surfaced via m4_acceptance_run=1 forcing fresh sample rebuild. Fix: Option B scoped re-merge of old1_sib_enr_*/old2_sib_enr_* in both diagnostics at both use-sites.
**Report:** `quality_reports/reviews/2026-05-31_va-score-sib-lag-r111-debug.md`; ledger rows 2026-05-31T23:50Z

### 2026-05-31 22:24 — coder
**Phase:** Execution (Phase 1 consolidation debug)
**Target:** `do/va/reg_out_va_all_fig.do`, `do/va/reg_out_va_dk_all_fig.do` (figure-subdir mkdir bug); `log/main_26-May-2026_20-50-27.smcl`
**Score:** N/A (debug/fix dispatch, not a scored review)
**Verdict:** Fatal May-26 error is `r(601)` `est use ... het_reg_*_x_prior_*.ster not found` (producer/consumer prior-score-decile gate desync, fixed pre-session in `e8d47aa`), NOT a PDF-save failure. Separately, applied missing nested `cap mkdir` (one-per-level, v1+v2, $figures_dir + $output_dir/gph_files) to both figure scripts for the latent r(603) export bug.
**Report:** `quality_reports/reviews/2026-05-31_va-fig-pdf-save-debug.md`; ledger rows in `.claude/state/verification-ledger.md` (2026-05-31T22:24Z)

### 2026-05-31 22:10 — Explore (×2)
**Phase:** Execution (Phase 1 consolidation debug)
**Target:** May-26 batch log error + producer/consumer `$run_prior_score` gate alignment across `do/`
**Score:** N/A (read-only investigation)
**Verdict:** Confirmed the gate (`if "$run_prior_score" != "0"`) is identical token-for-token across producer + all consumers in current code, and the `.ster` save/read paths match character-for-character; `run_prior_score` assigned once (`do/settings.do:225`, global). The desync was historical (pre-`e8d47aa`), not present in current code.
**Report:** inline (session) — see session log `2026-05-31_va-fig-pdf-save-mkdir-and-r601-diagnosis.md`

### 2026-06-20 21:00 — coder-critic
**Phase:** Execution (Phase 1 — staffqoi98 extended-scale fix)
**Target:** `do/survey_va/imputation.do` (clamp floor) + `do/check/check_survey_indices.do` (min bound) per ADR-0032
**Score:** 92/100 PASS
**Verdict:** Faithfully implements ADR-0032. Independently re-verified: staffqoi98 is the only -3-coded item; both index constructors (imputedcategoryindex.do / compcasecategoryindex.do) exclude it; repo-wide grep finds it only in the two changed files + one archived file → built indices, SUB-CHECK 2, and survey-VA regressions genuinely unaffected. -8 ledger hygiene (stale check rows + missing imputation.do rows), since addressed.
**Report:** `quality_reports/reviews/2026-06-20_staffqoi98-clamp-and-check_coder_review.md`
