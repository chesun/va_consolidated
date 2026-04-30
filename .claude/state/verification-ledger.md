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

<!-- Real entries replace the _example_ rows above. Keep one row per (path, check). When a file changes, its rows become stale and are re-evaluated on next access.

NOTE: file-hash recompute after the M1 fix (cap-translate-before-exit) — hashes
above are post-fix. If you later rebuild the ledger, run:
    for f in do/check/check_*.do; do shasum -a 256 "$f" | cut -c1-12; done -->

