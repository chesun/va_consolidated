# Research Journal — VA Consolidated (CEL Value-Added Project)

Append-only agent-level history. One entry per agent invocation. See `.claude/rules/logging.md` §3.

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
