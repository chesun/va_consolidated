# M4-Blocking Fixes Review — coder-critic

**Date:** 2026-05-17
**Reviewer:** coder-critic
**Target:** 3 M4-blocking latent-issue fixes (Partition B carry-forward) — Mj-1 `do/check/check_survey_indices.do:197` categoryindex reader repoint; Mj-2 `do/check/t1_empirical_tests.do` archive to `do/_archive/check/` + new `_archive/check/README.md`; Mj-3 12 absolute-include repointing across 6 `.doh` files in `do/samples/`
**Score:** 96/100
**Status:** Active
**Supersedes:** none

---

## Verdict — PASS (96/100)

All three fixes are correctly implemented. The chain-coordination defects flagged in the 2026-05-16 Partition B audit (findings 3, 4, 5; total deductions -30 in round 1) are now resolved by these three targeted commits. Verification:

1. **Mj-1 (categoryindex reader path).** `do/check/check_survey_indices.do:197` reads `$datadir_clean/survey_va/categoryindex/<idx_tag>categoryindex.dta` — exact match to producers `do/survey_va/imputedcategoryindex.do:177` and `do/survey_va/compcasecategoryindex.do:178`, both confirmed by grep. Header INPUTS block (L16-18) and ROLE IN ADR-0021 SANDBOX block (L26-31) both updated to reference the CANONICAL path. Sub-check 1 (L127-189; reads LEGACY `$caschls_projdir/dta/allsvyfactor/...` for static predecessor source) intentionally unchanged — consistent with round-1 review's Minor observation that LEGACY static-source reads are defensible. **Silent-skip closed.**

2. **Mj-2 (t1_empirical_tests archival).** `do/check/t1_empirical_tests.do` removed from active `do/check/` tree; `do/_archive/check/t1_empirical_tests.do` exists with body preserved. `check_logs.do:76` enumerator drops `regexm(dirname, "/_archive($|/)")` — so the archive move correctly removes the orphan from the `filelist` scan, preserving the structural invariant ("every active `do/**/*.do` has a matching `$logdir/<stem>.smcl`"). New `do/_archive/check/README.md` (30 lines) mirrors the structure + reference style of `_archive/exploratory/README.md` and `_archive/siblingvaregs/README.md`: header (Status / Archived date / Authority), "What this directory contains", "Files archived", "Why archived" (cross-references finding 4 by name), and "Cross-references" (ADR-0017, ADR-0021, Phase 1c §5.4, pre-flight review, audit doc, consolidated-sandbox successor). Also resolves orthogonal Minor finding 9 (log routing to `log_files/check/`) — by archiving, that's no longer load-bearing. **check_logs invariant preserved + orphan-log concern moot.**

3. **Mj-3 (relative→absolute includes in 6 .doh files).** Grep verification:
   - `grep -rE '^\s*include do/samples/' do/samples/*.doh` → **0 hits** (relative includes purged).
   - `grep -rE '^\s*include \$consolidated_dir/do/samples/' do/samples/*.doh` → **12 hits across 6 files**, exactly the expected count: `create_va_g11_sample_v1.doh:63,66` + `create_va_g11_sample.doh:52,55` + `create_va_g11_sample_v2.doh:46,49` + `create_va_g11_out_sample_v1.doh:53,56` + `create_va_g11_out_sample.doh:52,55` + `create_va_g11_out_sample_v2.doh:46,49`.
   - RELOCATION HISTORY amendment block present in all 6 files (dated 2026-05-17 with rationale "to survive parent caller's `cd $vaprojdir` (pre-flight Partition B finding 5)") — sampled `create_va_g11_sample_v1.doh:35,49-51` and `create_va_g11_out_sample_v2.doh:22,31-33` directly.
   - Caller chain integrity: `create_score_samples.do` + `create_out_samples.do` already use absolute `include $consolidated_dir/do/samples/create_va_g11_*.doh` (verified in round-1 batch-2c ledger). The .doh files they include now contain absolute includes internally, so the `cd $vaprojdir`-after-include doesn't break the second-level cascade.

**Bonus — TODO.md cleanup correctly scoped.** Lines 86, 87, 88, 92 marked `[x] RESOLVED 2026-05-17` with cross-references to the round-1 review findings (3, 4, 5, 9 respectively — line 92 was the orthogonal Minor M9 closed-by-archive). Lines 89-91 (M6, M7, M8 deferred Minors) and 93-100 (Partition D + M4 post-smoke items) correctly untouched. No scope creep.

The single (Minor) residue is documentation-only: `do/check/m4_path_matrix_README.md:178` still mentions `t1_empirical_tests.do` in an informational sentence listing files excluded from the M4 matrix. The line is descriptive prose ("excluded by design — they're new pipeline diagnostics, not relocated files with predecessor counterparts"), not a load-bearing path reference. It accurately describes the file's now-archived state ("excluded"). Acceptable to leave as-is; flag as a Minor follow-up for cleanliness if-and-when the README is next edited.

---

## Code-Strategy Alignment: MATCH

The three fixes exactly mirror the round-1 review's "Recommended fix" prescriptions:

- **Mj-1 recommended:** "Change `$estimates_dir` → `$datadir_clean` in all 3 `local in_...` lines AND in the header INPUTS block." Fix matches in entirety.
- **Mj-2 recommended:** "Option 1 [archive to `do/_archive/check/`] is the lowest-friction." Fix takes Option 1.
- **Mj-3 recommended:** "Repoint all 12 relative includes in the 6 .doh files to absolute `$consolidated_dir/do/samples/...`." Fix matches in entirety.

No scope creep beyond the prescribed fixes. No drive-by edits to main.do, the M4 matrix/runner, or other check_*.do files (verified by `grep -l m4_golden_master|m4_path_matrix\.csv` returning only the 2 expected files, neither modified).

## Sanity Checks: PASS

- **Producer-consumer chain integrity (Mj-1):** `grep save.*categoryindex do/survey_va/*.do` confirms producers `imputedcategoryindex.do:177` + `compcasecategoryindex.do:178` write to `$datadir_clean/survey_va/categoryindex/`. Consumer at `check_survey_indices.do:197` now reads from the exact same path. Chain closes.
- **check_logs invariant preserved (Mj-2):** `check_logs.do:73-76` enumerates via `filelist` then drops `_archive` via `regexm`. Verified directly; archive move is correctly out-of-scope.
- **`cd $vaprojdir` survival (Mj-3):** All 12 includes now resolve via `$consolidated_dir`, which is a global bound in `settings.do` and unaffected by `cd`. The pattern matches the precedent ledger row 42 fix for `touse_va.do` (batch-2c).
- **No collateral damage.** `check_survey_indices.do` other reads unchanged. `_archive/check/README.md` style matches sibling archive READMEs. The 6 .doh files' bodies preserved verbatim except for the 12 include lines.

## Robustness: Complete

All three findings from the round-1 review that needed resolution before M4 are closed. Per the synthesis review (`2026-05-16_pre-flight-SYNTHESIS_M4-go-no-go.md`), the orchestrator scope was: close blockers; defer non-blockers. This commit closes exactly the three blockers.

---

## Findings

### MINOR — m4_path_matrix_README.md:178 informational mention of archived file

**Severity:** Minor (documentation-only; no runtime impact)
**Deduction:** -2

**Where:** `do/check/m4_path_matrix_README.md:178` — "11. **The two `check_*.do` files that produce intermediate outputs are NOT in the matrix.** `check_logs.do`, `check_merges.do`, `check_paper_outputs.do`, `check_samples.do`, `check_survey_indices.do`, `check_va_estimates.do`, `t1_empirical_tests.do`, and `explore/codebook_export.do` are excluded by design — they're new pipeline diagnostics (plan v3 §5.3), not relocated files with predecessor counterparts."

The line is informational prose listing files excluded from the M4 matrix. It accurately describes the file's now-archived state ("excluded"). The reference is technically correct — `t1_empirical_tests.do` is still excluded from the M4 matrix, just for a different reason now (it's archived rather than "new pipeline diagnostic"). The categorization could be tightened next time the README is edited: move `t1_empirical_tests.do` to a separate sub-bullet explaining "archived to `do/_archive/check/` 2026-05-17 — predecessor-layout one-off, not relocated" rather than grouping it with the active `check_*.do` diagnostics.

**Recommended fix:** Defer. Cleanup-only; coder flagged this exact case in the edge-case note. Resolve in next regular sweep of m4_path_matrix_README.md (e.g., post-smoke when matrix items get re-tiered per the README's own §1-12 limitations).

---

### MINOR — README.md ordering note (acceptable as-is)

**Severity:** Minor (style observation, not a defect)
**Deduction:** -2

The new `do/_archive/check/README.md` lists "Files archived (1)" with a per-file bullet. The sibling `_archive/exploratory/README.md` and `_archive/siblingvaregs/README.md` may have a slightly different sub-structure (e.g., per-file "Why archived" rather than directory-level "Why archived"). Style consistency across the three `_archive/` READMEs is not strictly required by any rule — ADR-0021 only requires a README per archive subdir, not a fixed template. The new README is comprehensive and cross-referenced; the structure is acceptable.

**Recommended fix:** None. Style consistency is a soft preference; the README hits all the substantive requirements (Status / Archived date / Authority / What's in directory / Why archived / Cross-references).

---

## Score Breakdown

- Starting: 100
- MINOR: m4_path_matrix_README.md informational mention of archived file: -2
- MINOR: README.md style ordering (acceptable as-is): -2
- All 3 main fixes (Mj-1, Mj-2, Mj-3) verified correct and chain-coordination-complete: +0 (they're what got verified)

**Final: 96/100** — PASS (hard gate 80)

---

## Top Findings by Severity

1. **No CRITICAL or MAJOR findings.** All three round-1 Critical+Major findings (Mj-1 chain coordination on categoryindex, Mj-2 check_logs invariant break, Mj-3 6 .doh relative includes) are CLOSED by this commit.

2. **MINOR** — `do/check/m4_path_matrix_README.md:178` informational mention of `t1_empirical_tests.do` is accurate (the file is still excluded from M4 matrix) but its categorization could be tightened in the next regular sweep. Defer.

3. **MINOR** — `do/_archive/check/README.md` style is comprehensive and substantively correct; structural symmetry with the other two `_archive/` READMEs is a soft preference. Acceptable as-is.

---

## Compliance Evidence (from .claude/state/verification-ledger.md)

The three fixes are post-relocation chain-coordination repairs rather than fresh relocations; ledger schema is per-file-per-check-class. Relevant prior ledger rows consulted:

- `do/check/check_survey_indices.do | adr-0021-sandbox-write` | 2026-04-29T18:55Z | PASS — verified for WRITE side; the round-1 finding 3 noted READ-side was NOT in scope of this check class. Mj-1 fix addresses the gap.
- `do/check/check_logs.do | adr-0021-sandbox-write` | (existing, inferred from cross-file PASS state) — confirms enumerator scope correctly excludes `_archive/`; Mj-2 fix routes around the structural invariant correctly.
- `do/samples/touse_va.do | no-hardcoded-paths` | 2026-05-07T22:00Z | PASS — relevant precedent: "rev'd post-batch-2c bugfix (3 broken consolidated relative includes -> $consolidated_dir/...)". The 6 .doh files were the batch-2c sweep miss; Mj-3 closes the same regression class for the now-identified files.
- `do/samples/create_score_samples.do | legacy-include-macro-trace` | 2026-05-07T22:00Z | PASS UPGRADED — relevant precedent for include-chain integrity; the 6 .doh helpers in Mj-3 were not separately rechecked in that row, hence the round-1 finding 5 gap. Mj-3 closes it.

**Ledger backfill recommendation (deferred, not deducted):** After this commit, the 6 .doh files in Mj-3 would benefit from an explicit `legacy-include-macro-trace` ledger row each, recording the post-fix absolute-include state. Similarly, `check_survey_indices.do` could carry a `chain-coordination` row (the schema addition flagged in the round-1 review's "Recommended ledger-schema addition"). Both are Phase 1c §5.4 housekeeping, not blockers.

**Observation:** All three fixes are post-hoc closures of regressions identified at audit time, not in-session new authorship. The original `phase-1-review.md` §2 Tier-1 self-check could not have caught these (they're cross-file producer-consumer chain breaks that only surface on an audit that traces both sides). The "Recommended ledger-schema addition" proposed in the round-1 review (`chain-coordination` check class) remains the durable systemic fix; this commit is the per-file closure of the three specific instances flagged.

---

## Escalation Status: None (Strike 0 of 3)

First and only review on this commit. The three fixes exactly match the round-1 review's prescriptions. No worker-critic disagreement, no rounds 2/3 anticipated.

---

## Verdict

**PASS at 96/100. Hard gate is 80.**

All three Partition B carry-forward Major findings are closed. The fixes are minimal, correctly scoped, and chain-coordination-complete. The two Minor findings are documentation-style follow-ups with no runtime impact; defer to a later sweep.

Cleared for commit and proceed to M4 golden-master kickoff.
