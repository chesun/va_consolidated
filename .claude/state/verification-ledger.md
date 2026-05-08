# Verification Ledger

Cache of verification results for the adversarial-default rule (`.claude/rules/adversarial-default.md`). Each row is one `(path, check)` pair. Agents consult this before running a check; if `File hash` matches the current `sha256(path) | head -c 12` AND `Result == PASS`, the cached result is cited and the check is not re-run.

**Columns:**

- *Path* — repo-relative path to the artifact under check.
- *Check* — slug from the per-domain table in `adversarial-default.md` (e.g., `no-hardcoded-paths`, `seed-set-once`, `parallel-trends`, `incentive-compatibility`).
- *Verified At* — ISO 8601 UTC, minute precision.
- *File hash* — `sha256(<path>) | head -c 12`. Content hash, not metadata.
- *Result* — `PASS`, `FAIL`, or `ASSUMED` (cost-prohibitive / infrastructure-unavailable).
- *Evidence* — short headline with the specific detail (line number, count, p-value, etc.). Full output → session log.

**Update protocol** is in `.claude/rules/adversarial-default.md` § Verification ledger. Stale rows (file hash mismatch, or convention rule modified after `Verified At`) are re-run on access.

---

| Path | Check | Verified At | File hash | Result | Evidence |
|------|-------|-------------|-----------|--------|----------|
| _example_ scripts/01_clean.do | no-hardcoded-paths | 2026-04-28T10:00Z | a1b2c3d4e5f6 | PASS | grep returned 0 matches |
| _example_ scripts/02_analysis.do | seed-set-once | 2026-04-28T10:00Z | f7e8d9c0b1a2 | FAIL | 0 occurrences in master.do |
| _example_ paper/main.tex | bibliography-resolves | 2026-04-28T10:05Z | 9e8d7c6b5a4f | ASSUMED | Cost-prohibitive: full pdflatex+biber run not yet executed in this session |
| do/check/check_logs.do | no-hardcoded-paths | 2026-04-29T18:55Z | d1cb1e870a17 | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/check/check_logs.do | no-raw-data-overwrites | 2026-04-29T18:55Z | d1cb1e870a17 | PASS | no save/export/outsheet/esttab using/graph export/outreg2 using/texsave outside header comments |
| do/check/check_logs.do | adr-0021-sandbox-write | 2026-04-29T18:55Z | d1cb1e870a17 | PASS | only writes are log using $logdir + cap translate to $logdir (CANONICAL) |
| do/check/check_samples.do | no-hardcoded-paths | 2026-04-29T18:55Z | dfec994cd69b | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/check/check_samples.do | no-raw-data-overwrites | 2026-04-29T18:55Z | dfec994cd69b | PASS | no save/export calls; only reads $estimates_dir/va_samples_v1/score_b.dta |
| do/check/check_samples.do | adr-0021-sandbox-write | 2026-04-29T18:55Z | dfec994cd69b | PASS | only writes are log using $logdir + cap translate to $logdir (CANONICAL) |
| do/check/check_merges.do | no-hardcoded-paths | 2026-04-29T18:55Z | 1499ac14ef67 | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/check/check_merges.do | no-raw-data-overwrites | 2026-04-29T18:55Z | 1499ac14ef67 | PASS | no save/export calls; reads $estimates_dir + $vaprojxwalks (LEGACY-static per ADR-0017) |
| do/check/check_merges.do | adr-0021-sandbox-write | 2026-04-29T18:55Z | 1499ac14ef67 | PASS | only writes are log using $logdir + cap translate to $logdir (CANONICAL) |
| do/check/check_va_estimates.do | no-hardcoded-paths | 2026-04-29T18:55Z | 21a2be73fb53 | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/check/check_va_estimates.do | no-raw-data-overwrites | 2026-04-29T18:55Z | 21a2be73fb53 | PASS | no save/export calls; only reads $estimates_dir/va_cfr_all_v1/.../va_all_schl_char.dta |
| do/check/check_va_estimates.do | adr-0021-sandbox-write | 2026-04-29T18:55Z | 21a2be73fb53 | PASS | only writes are log using $logdir + cap translate to $logdir (CANONICAL) |
| do/check/check_survey_indices.do | no-hardcoded-paths | 2026-04-29T18:55Z | 4926001734ca | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/check/check_survey_indices.do | no-raw-data-overwrites | 2026-04-29T18:55Z | 4926001734ca | PASS | no save/export calls; reads $caschls_projdir (LEGACY-static CalSCHLS) + $estimates_dir |
| do/check/check_survey_indices.do | adr-0021-sandbox-write | 2026-04-29T18:55Z | 4926001734ca | PASS | only writes are log using $logdir + cap translate to $logdir (CANONICAL) |
| do/check/check_paper_outputs.do | no-hardcoded-paths | 2026-04-29T18:55Z | ca365c234143 | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/check/check_paper_outputs.do | no-raw-data-overwrites | 2026-04-29T18:55Z | ca365c234143 | PASS | no save/export calls; only reads $estimates_dir |
| do/check/check_paper_outputs.do | adr-0021-sandbox-write | 2026-04-29T18:55Z | ca365c234143 | PASS | only writes are log using $logdir + cap translate to $logdir (CANONICAL) |
| do/check/check_paper_outputs.do | design-memo-fidelity | 2026-04-29T18:55Z | ca365c234143 | ASSUMED | Most cells TBD-codebook per design memo §6 + §9 — needs Phase 1a §3.3 share/ relocation outputs to seed concrete cell-magnitude assertions |
| do/samples/touse_va.do | no-hardcoded-paths | 2026-05-07T22:00Z | b04973ca7ab3 | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches; rev'd post-batch-2c bugfix (3 broken consolidated relative includes -> $consolidated_dir/...) |
| do/samples/touse_va.do | adr-0021-sandbox-write | 2026-05-07T22:00Z | b04973ca7ab3 | PASS | sole persistent save at L324 targets CANONICAL `$datadir_clean/sbac/va_samples.dta`; log + translate target CANONICAL `$logdir/`; no LEGACY writes |
| do/samples/touse_va.do | legacy-include-macro-trace | 2026-05-07T22:00Z | b04973ca7ab3 | PASS | LEGACY include `$matt_files_dir/merge_k12_postsecondary.doh` references no top-level `$<global>`s (Matt's args-based file); CONSOLIDATED includes use absolute `$consolidated_dir/do/...` paths post-bugfix |
| do/samples/create_score_samples.do | no-hardcoded-paths | 2026-05-07T22:00Z | e546d0594de2 | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches; rev'd post-batch-2c (3 broken includes fixed; 8 LEGACY refs repointed to consolidated batch 2c helpers) |
| do/samples/create_score_samples.do | adr-0021-sandbox-write | 2026-05-07T22:00Z | e546d0594de2 | PASS | all 8 persistent saves target CANONICAL `$datadir_clean/va_samples_`version'/score_*.dta`; tempfile save at L203 exempt per established convention; log + translate target CANONICAL `$logdir/` |
| do/samples/create_score_samples.do | legacy-include-macro-trace | 2026-05-07T22:00Z | e546d0594de2 | PASS | UPGRADED from ASSUMED (batch 2c relocated all 4 sbac merge helpers in-repo at do/samples/). $matt_files_dir/merge_k12_postsecondary.doh references no top-level $<global>s. $vaprojdir/do_files/k12_postsec_distance/merge_k12_postsec_dist.doh KEPT LEGACY (Step 9 deferred); $distance_dtadir bound in do/settings.do |
| do/samples/create_out_samples.do | no-hardcoded-paths | 2026-05-07T22:00Z | 3953e18a8193 | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches; rev'd post-batch-2c |
| do/samples/create_out_samples.do | adr-0021-sandbox-write | 2026-05-07T22:00Z | 3953e18a8193 | PASS | all 8 persistent saves target CANONICAL `$datadir_clean/va_samples_`version'/out_*.dta`; tempfile save at L196 exempt; log + translate target CANONICAL `$logdir/` |
| do/samples/create_out_samples.do | legacy-include-macro-trace | 2026-05-07T22:00Z | 3953e18a8193 | PASS | UPGRADED from ASSUMED (batch 2c relocated 4 sbac merge helpers in-repo). Same trace as create_score_samples.do |
| do/samples/create_va_sample.doh | no-hardcoded-paths | 2026-05-07T20:30Z | 78d209313d1d | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/samples/create_va_sample.doh | adr-0021-sandbox-write | 2026-05-07T20:30Z | 78d209313d1d | PASS | pure parent-context fragment; no own saves; only reads — `$datadir_clean/sbac/va_samples.dta` (CANONICAL match to touse_va.do output) plus LEGACY restricted-access K12 reads via macros_va.doh locals |
| do/samples/merge_loscore.doh | no-hardcoded-paths | 2026-05-07T22:00Z | 22c730e7a2ae | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/samples/merge_loscore.doh | adr-0021-sandbox-write | 2026-05-07T22:00Z | 22c730e7a2ae | PASS | pure parent-context fragment; no own save/log; only reads via parent-scope `k12_test_scores' local (LEGACY) |
| do/samples/merge_sib.doh | no-hardcoded-paths | 2026-05-07T22:00Z | 2a3ecddad94e | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/samples/merge_sib.doh | adr-0021-sandbox-write | 2026-05-07T22:00Z | 2a3ecddad94e | PASS | pure parent-context fragment; no own save/log; reads `sibling_out_xwalk' via parent-scope local |
| do/samples/merge_lag2_ela.doh | no-hardcoded-paths | 2026-05-07T22:00Z | 4731ca86546d | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/samples/merge_lag2_ela.doh | adr-0021-sandbox-write | 2026-05-07T22:00Z | 4731ca86546d | PASS | pure parent-context fragment; no own save/log; same LEGACY K12 read as merge_loscore.doh |
| do/samples/merge_va_smp_acs.doh | no-hardcoded-paths | 2026-05-07T22:00Z | 464da3083c57 | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/samples/merge_va_smp_acs.doh | adr-0021-sandbox-write | 2026-05-07T22:00Z | 464da3083c57 | PASS | called via `do' (own scope); 4 tempfile saves (exempt per established convention); no persistent-disk writes; reads LEGACY `$vaprojdir/data/...` (restricted-access K12 + crosswalks) and CONSOLIDATED `$consolidated_dir/do/va/helpers/macros_va.doh` |
| do/va/va_score_all.do | no-hardcoded-paths | 2026-05-07T23:30Z | 8f4df08c6a6d | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/va/va_score_all.do | adr-0021-sandbox-write | 2026-05-07T23:30Z | 8f4df08c6a6d | PASS | 5 estimates/save calls (vam ster L208, spec_test ster L215, vam ster L233, spec_test ster L240, dta L251) all target CANONICAL `$estimates_dir/va_cfr_all_`version'/...`; log + translate target `$logdir/`; no LEGACY writes |
| do/va/va_score_all.do | helper-include-absolute | 2026-05-07T23:30Z | 8f4df08c6a6d | PASS | 3/3 helper includes use absolute `$consolidated_dir/do/va/helpers/...` (macros_va, drift_limit, macros_va_all_samples_controls); zero relative `include do/...` post-`cd $vaprojdir` per batch 2c bugfix convention |
| do/va/va_score_fb_all.do | no-hardcoded-paths | 2026-05-07T23:30Z | 3e4867fe8278 | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/va/va_score_fb_all.do | adr-0021-sandbox-write | 2026-05-07T23:30Z | 3e4867fe8278 | PASS | 4 estimates/save calls (vam ster L227 + L279, fb_test ster L237 + L288) all target CANONICAL `$estimates_dir/va_cfr_all_`version'/...`; log + translate target `$logdir/`; no-FB-leaveout vam calls intentionally don't save (residual-only); no LEGACY writes |
| do/va/va_score_fb_all.do | helper-include-absolute | 2026-05-07T23:30Z | 3e4867fe8278 | PASS | 3/3 helper includes use absolute `$consolidated_dir/do/va/helpers/...` |
| do/va/va_out_all.do | no-hardcoded-paths | 2026-05-07T23:30Z | c00e81dd22ee | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/va/va_out_all.do | adr-0021-sandbox-write | 2026-05-07T23:30Z | c00e81dd22ee | PASS | 9 estimates/save + 1 .dta save all target CANONICAL `$estimates_dir/va_cfr_all_`version'/...`; log + translate target `$logdir/`; no LEGACY writes |
| do/va/va_out_all.do | helper-include-absolute | 2026-05-07T23:30Z | c00e81dd22ee | PASS | 3/3 helper includes absolute |
| do/va/va_out_all.do | dependency-chain-integrity | 2026-05-07T23:30Z | c00e81dd22ee | PASS | merge at L232 reads `$estimates_dir/va_cfr_all_`version'/va_est_dta/va_`subject'_`sample'_sp_`va_ctrl'_ct.dta` — exact-match path va_score_all.do:251 writes |
| do/va/va_out_fb_all.do | no-hardcoded-paths | 2026-05-07T23:30Z | 26af7f0587d8 | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/va/va_out_fb_all.do | adr-0021-sandbox-write | 2026-05-07T23:30Z | 26af7f0587d8 | PASS | 8 estimates/save calls (4 standard + 4 DK; all .ster) all target CANONICAL `$estimates_dir/va_cfr_all_`version'/...`; log + translate target `$logdir/`; no LEGACY writes |
| do/va/va_out_fb_all.do | helper-include-absolute | 2026-05-07T23:30Z | 26af7f0587d8 | PASS | 3/3 helper includes absolute |
| do/va/va_out_fb_all.do | dependency-chain-integrity | 2026-05-07T23:30Z | 26af7f0587d8 | PASS | merge in DK branch reads same CANONICAL path va_score_all.do:251 writes |
| do/main.do | gate-parity | 2026-05-07T23:30Z | f9497e091c8a | PASS | `local do_va = 0` matches predecessor `do_all.do:160`; 4 batch 3a invocations gated by `if `do_va''`; matches the run-once-cached pattern established in batch 2b for sample construction |
| do/va/va_score_spec_test_tab.do | no-hardcoded-paths | 2026-05-08T00:30Z | 25e751e81150 | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/va/va_score_spec_test_tab.do | adr-0021-sandbox-write | 2026-05-08T00:30Z | 25e751e81150 | PASS | 4 regsave + 1 use target CANONICAL `$tables_dir/va_cfr_all_`version'/spec_test/`; log + translate target `$logdir/`; predicted_prior_score reads KEPT LEGACY (Step 11 deferred) |
| do/va/va_score_spec_test_tab.do | helper-include-absolute | 2026-05-08T00:30Z | 25e751e81150 | PASS | 3/3 helper includes use absolute `$consolidated_dir/do/va/helpers/...` |
| do/va/va_out_spec_test_tab.do | no-hardcoded-paths | 2026-05-08T00:30Z | d261fd799c64 | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/va/va_out_spec_test_tab.do | adr-0021-sandbox-write | 2026-05-08T00:30Z | d261fd799c64 | PASS | 4 regsave + 1 use target CANONICAL `$tables_dir/...`; predicted_prior_score reads KEPT LEGACY |
| do/va/va_out_spec_test_tab.do | helper-include-absolute | 2026-05-08T00:30Z | d261fd799c64 | PASS | 3/3 absolute |
| do/va/va_score_fb_test_tab.do | no-hardcoded-paths | 2026-05-08T00:30Z | b2f2d96665d6 | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/va/va_score_fb_test_tab.do | adr-0021-sandbox-write | 2026-05-08T00:30Z | b2f2d96665d6 | PASS | 4 regsave target CANONICAL `$tables_dir/.../fb_test/`; CFR ster reads CANONICAL; predicted_prior_score reads KEPT LEGACY |
| do/va/va_score_fb_test_tab.do | helper-include-absolute | 2026-05-08T00:30Z | b2f2d96665d6 | PASS | 2/2 absolute (no drift_limit needed — only reads .ster, no vam call) |
| do/va/va_out_fb_test_tab.do | no-hardcoded-paths | 2026-05-08T00:30Z | 6b5932f1cf93 | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/va/va_out_fb_test_tab.do | adr-0021-sandbox-write | 2026-05-08T00:30Z | 6b5932f1cf93 | PASS | 4 regsave target CANONICAL `$tables_dir/.../fb_test/`; CFR ster reads CANONICAL; predicted_prior_score reads KEPT LEGACY |
| do/va/va_out_fb_test_tab.do | helper-include-absolute | 2026-05-08T00:30Z | 6b5932f1cf93 | PASS | 2/2 absolute |
| do/va/va_spec_fb_tab.do | no-hardcoded-paths | 2026-05-08T00:30Z | 480b0c5d2267 | PASS | grep -nE '"/Users\|"/home\|"C:\\\\' returned 0 matches |
| do/va/va_spec_fb_tab.do | adr-0021-sandbox-write | 2026-05-08T00:30Z | 480b0c5d2267 | PASS | 1 esttab using -> CANONICAL `$tables_dir/.../combined/fb_spec_<outcome>.csv`; all `est use` reads from CANONICAL `$estimates_dir/...`; no LEGACY reads (no predicted-score branch) |
| do/va/va_spec_fb_tab.do | helper-include-absolute | 2026-05-08T00:30Z | 480b0c5d2267 | PASS | 1/1 absolute (only macros_va.doh needed; b_str/las_str/ls_str locals defined therein at L560/600/616 propagate via include) |
| do/settings.do | tables-figures-globals | 2026-05-08T00:30Z | 5f0101247e55 | PASS | $tables_dir = "$consolidated_dir/tables" and $figures_dir = "$consolidated_dir/figures" added to CANONICAL block (per ADR-0012; consumers in batch 3b use $tables_dir for paper-shipping spec/FB tables) |

<!-- Real entries replace the _example_ rows above. Keep one row per (path, check). When a file changes, its rows become stale and are re-evaluated on next access.

NOTE: file-hash recompute after the M1 fix (cap-translate-before-exit) — hashes
above are post-fix. If you later rebuild the ledger, run:
    for f in do/check/check_*.do; do shasum -a 256 "$f" | cut -c1-12; done -->

