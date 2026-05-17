# Pre-Flight Audit Partition C — do/data_prep/

**Date:** 2026-05-16
**Reviewer:** coder-critic
**Target:** Partition C — `do/data_prep/` (40 files across 7 subdirectories: `acs/`, `schl_chars/`, `k12_postsec_distance/`, `prepare/`, `qoiclean/{parent,secondary,staff}/`, `poolingdata/`, `responserate/`)
**Score:** 91/100
**Status:** Active
**Supersedes:** none

---

## Verdict — PASS (91/100)

ADR-0021 sandbox-write discipline holds across all 40 files. **Zero CRITICAL LEGACY-write violations.** Every active `save`, `export`, `outsheet`, `esttab using`, `graph export`, `texsave`, `regsave`, `log using`, `translate` either (a) targets a CANONICAL global (`$consolidated_dir`, `$datadir`, `$datadir_clean`, `$datadir_raw`, `$logdir`, `$estimates_dir`, `$output_dir`), (b) is a Stata `tempfile` (session-scoped; sandbox-exempt), or (c) is inside a `/* ... */` block (commented-out documentation).

**Pre-scan-flagged `do/data_prep/acs/acs_2017_gen_dict.do:111` — confirmed inside `/* ... */` block** spanning lines 110-111 (relative-write to `$vaprojdir/data/public_access/raw/acs/...` is commented; legacy author comment preserved per ADR-0021 verbatim-preservation). Not active code. **No deduction.**

The 9-point deduction is driven by:

1. **MAJOR** — `clean_charter.do` (lines 75, 105) has Mac-local branch writing relative-path `data_local/charter_status.dta` outside the sandbox. Branch never taken on Scribe (gated by `c(machine_type)=="Macintosh (Intel 64-bit)"`); but it's a non-CANONICAL write, undocumented in ADR-0021, and the relative path resolves under `$consolidated_dir` (CWD per main.do) — meaning on a Mac dev machine, the consolidated dir grows an unsandboxed `data_local/` directory. **Deduction: -5.**

2. **MINOR** — `cap`-less `log close _all` in 4 schl_chars files (`cds_nces_xwalk.do:53`, `clean_charter.do:53`, `clean_ecn_disadv.do:52`, `clean_locale.do:51`) and `log close` (no `cap`) at end of several files. Per `stata-code-conventions.md`, the canonical pattern is `cap log close _all` to tolerate no-open-log state. Non-blocking — on the acceptance run these all follow an open log so the call succeeds; but inconsistent with the rest of the partition. **Deduction: -2.**

3. **MINOR** — Documentation drift: `splitstaff0414.do` and `renamedata.do` write to OVERLAPPING `$datadir_clean/calschls/staff/` namespace. `renamedata.do` writes `staff0414, staff1415, staff1516, staff1617, staff1718, staff1819` (lines 294, 301, 308, 315, 322, 329); `splitstaff0414.do` then reads `staff0414` and produces 10 yearly outputs `staff0405..staff1314` (line 88). No actual clash since year-sets don't overlap. But the relationship is not as clearly documented as the chain-producer/chain-consumer pattern elsewhere. Worth a one-liner clarifying the year-set partition. **Deduction: -2.**

4. **MINOR** — Cross-partition chain coordination — `sch_char.dta` produced CANONICAL but Partition B heterogeneity files still read LEGACY. This is **documented Phase 1b deferred work** (each heterogeneity file's header says "`$vaprojdir/data/sch_char[_2018].dta` KEPT LEGACY (Step 9 CDE data deferred)"); flagged here for the partition-coordination ledger. Not a Partition C regression. **No deduction.**

**No chain coordination issues found WITHIN Partition C.** All 7 subdirs' producer-consumer pairs verified consistent on CANONICAL paths. The `clean_va.do` → `va_pooled_all.dta` → `survey_va/allsvymerge.do` chain checks out. The `renamedata` → `splitstaff0414` / `qoiclean` chain checks out. The `clean_*` per-year → `clean_sch_char` assembly chain checks out. The `trim<sub>demo` → `<sub>responserate` → `<sub>pooling` chain checks out.

---

## Code-Strategy Alignment: MATCH (within partition)

The strategy specifies a self-contained sandbox where consolidated/ is the single source of truth (ADR-0021). Within Partition C, both write-side and within-partition read-side hold. Cross-partition reads from Partition C outputs (sch_char.dta, analysisready dtas, va_pooled_all.dta) are appropriately CANONICAL where the consumer has been Phase-1a relocated (`survey_va/allsvymerge.do`); LEGACY where consumer is deferred (`do/va/heterogeneity/*`, `do/survey_va/factor.do`, `do/survey_va/pcascore.do`, `do/share/svyvaregs/allvaregs.do` — all consistent with their headers documenting deferred chain wire-up).

## Sanity Checks: PASS

- **Hardcoded absolute paths:** 0 active hits. Pre-scan-flagged `acs_2017_gen_dict.do:65` confirmed inside `/* ... */` comment block. The `/home/research/...` substring appearing in `settings.do:163-165` (`$rawdtadir`, `$rawcsvdir`, `$clndtadir`) is the documented LEGACY-READ-ONLY global definition, not a per-script hardcode.
- **Multi-year loops:** All `forvalues`/`foreach year` loops use explicit local year-lists (per Step 9e learning #9). Verified for `parentqoiclean1819_1718.do:64`, `secqoiclean1819_1718_1516.do:69`, `staffqoiclean1617_1516.do:65`, `staffqoiclean1819_1718.do:64`, `enrollmentclean.do:68`, `responserate/*responserate.do:95,94`, `poolingdata/*pooling.do` (loop-free; explicit year-by-year appends with documented match counts). No globbing or `c(date)`-driven year-sets.
- **Helper-doh includes:** Only one helper-doh in partition (`merge_k12_postsec_dist.doh`). Verified line 67 includes `$consolidated_dir/do/va/helpers/macros_va.doh` (CANONICAL); line 70 reads `$datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance` (CANONICAL). No `$projdir`/`$caschls_projdir` rebinding required.
- **Header convention per ADR-0021:** 40/40 files have PURPOSE / INVOKED FROM / INPUTS / OUTPUTS / RELOCATION / REFERENCES blocks. Verified by spot-reading every file's first 50 lines.
- **`log using`/`translate` discipline:** 40/40 active files open a log via `log using "$logdir/<filename>.smcl"` and translate to `.log` at end. Verified by grep `^log using` and `^translate`. Plus one log open at `clean_charter.do:79` which is conditional on non-Mac branch (acceptable; Mac branch skips logging).

## Robustness: Complete

- ADR-0021 description-block coverage: 40/40 (100%).
- Sister-file cross-references in each header: present and accurate (spot-checked acs, schl_chars, k12_postsec_distance, prepare, qoiclean, responserate, poolingdata batches).
- Reading-time chain notes (e.g., `splitstaff0414.do:68` "CHAIN read from renamedata.do (same-batch producer; see plan v3 §3.3 step 9 batch 9d invocation order)") present at all chain-consumer entry points.
- The `reconcile_cdscodes.do` orphan status is correctly documented at lines 16-23 (ORPHAN STATUS callout); Phase 1c §5.1 dead-code review is the deferred resolution path. Acceptable.

---

## Findings

### MAJOR — Mac-local relative-path writes in clean_charter.do

**Severity:** Major (non-CANONICAL write on non-Scribe runs; minor on Scribe acceptance run since branch is skipped)
**Deduction:** -5

**Where:**

- `do/data_prep/schl_chars/clean_charter.do:75` — `import delimited using "data_local/CDESchoolDirectoryExport.txt", delimiters("\t")` (read, but inside the Mac-branch that also writes locally).
- `do/data_prep/schl_chars/clean_charter.do:105` — `save "data_local/charter_status.dta", replace` (relative-path write).
- Both wrapped in `if c(machine_type)=="Macintosh (Intel 64-bit)"` branch (line 74, 104).

**Why this matters:** Per ADR-0021, the consolidated/ folder is a self-contained sandbox. On Scribe (the only supported runtime per ADR-0002), the Mac branch is never taken, so the LEGACY `$vaprojdir/...` raw read fires and the CANONICAL `$datadir_clean/cde/charter_status.dta` save fires (line 108). The acceptance run produces correct output. However:

1. The relative path `data_local/` resolves under CWD = `$consolidated_dir`. A developer running the script on a Mac (e.g., for spot-debugging) would silently spawn a `data_local/` directory inside the consolidated repo, outside the documented sandbox-write globals.
2. ADR-0021 does not enumerate `data_local/` as a sanctioned write target. The Mac-local pattern predates the consolidated sandbox principle.
3. Future readers of the script will not understand the `data_local/` convention without reading the predecessor history.

The pre-commit Tier-1 self-check (per `phase-1-review.md` §2) requires every `save`/`export` to target a CANONICAL global; this file has 2 hits that don't. The reviewer at batch 9b time scored the file PASS, presumably treating the Mac branch as dead code on Scribe — which it is. But it's still a sandbox-discipline gap.

**Recommended fix (NOT IMPLEMENTED — critics are read-only):** Either (a) excise the Mac branch entirely (Scribe-only runtime per ADR-0002 means the dev-Mac workflow is unsupported), (b) repoint `data_local/` to a CANONICAL global (e.g., `$datadir_raw/cde_local/`) so the Mac branch is sandbox-compliant, or (c) add an ADR-0021 amendment carving out `data_local/` as a sanctioned dev-local sandbox.

---

### MINOR — `cap`-less `log close _all` in 4 schl_chars files

**Severity:** Minor (acceptance-run behavior is fine when prior file leaves a log open; otherwise errors)
**Deduction:** -2

**Where:**

- `do/data_prep/schl_chars/cds_nces_xwalk.do:53` — `log close _all`
- `do/data_prep/schl_chars/clean_charter.do:53` — `log close _all`
- `do/data_prep/schl_chars/clean_ecn_disadv.do:52` — `log close _all`
- `do/data_prep/schl_chars/clean_locale.do:51` — `log close _all`

Plus several files use `log close` (no `cap`) at the end of their bodies (after the canonical `log using` block).

Per `stata-code-conventions.md`: "`cap log close _all` and `set more off` at top of master." The canonical defensive pattern is to prefix `log close` with `cap` so the call is a no-op when no log is open. On the acceptance run, every file in main.do Phase 1 is preceded by a prior file that opened a log, so the close succeeds; but if these scripts are invoked standalone or the prior file errored out before its own `log close`, the bare `log close _all` will error.

**Recommended fix:** Prefix each with `cap` (one-character edit per occurrence).

---

### MINOR — Documentation drift in renamedata.do / splitstaff0414.do year-set partition

**Severity:** Minor (no behavior bug; documentation clarity gap)
**Deduction:** -2

**Where:**

- `do/data_prep/prepare/renamedata.do:294` writes `$datadir_clean/calschls/staff/staff0414` (pooled).
- `do/data_prep/prepare/renamedata.do:301,308,315,322,329` write `staff1415, staff1516, staff1617, staff1718, staff1819` (yearly).
- `do/data_prep/prepare/splitstaff0414.do:88` writes `$datadir_clean/calschls/staff/staff<i>` for `i ∈ {0405,0506,0607,0708,0809,0910,1011,1112,1213,1314}` (yearly splits of the pooled `staff0414`).

The year-sets are disjoint: renamedata writes the post-2014 yearly + pre-2014 pooled, splitstaff0414 splits the pre-2014 pooled into pre-2014 yearly. No file collision. But the relationship is not as clearly documented as the chain-producer/chain-consumer pattern elsewhere (e.g., compared to the trimsecdemo → secresponserate header in `responserate/`).

**Recommended fix:** Add a one-liner in `renamedata.do`'s header (OUTPUTS section) saying "Note: per-year `staff0405..staff1314` outputs are produced downstream by `splitstaff0414.do` from this script's `staff0414` pooled output."

---

### Informational — Cross-partition chain coordination: sch_char.dta deferred consumers

**Severity:** Informational (documented Phase 1b deferred work; not a Partition C regression)
**Deduction:** 0

**Where:**

- Producer: `do/data_prep/schl_chars/clean_sch_char.do:595` writes CANONICAL `$datadir_clean/sch_char.dta` + per-year snapshots `$datadir_clean/sch_char_<spring_year>.dta` (line 601).
- Consumers in Partition B (not Partition C):
  - `do/va/heterogeneity/va_het.do:95` — `merge 1:1 cdscode year using $vaprojdir/data/sch_char.dta` (LEGACY)
  - `do/va/heterogeneity/va_corr_schl_char.do:99` — `merge ... $vaprojdir/data/sch_char_2018.dta` (LEGACY)
  - `do/va/heterogeneity/va_corr_schl_char_fig.do:103` — same (LEGACY)
  - `do/explore/codebook_export.do:96` — `global cb_sch_char "$vaprojdir/data/sch_char.dta"` (LEGACY; explore-only diagnostic)

The heterogeneity files' OWN headers explicitly state "`$vaprojdir/data/sch_char[_2018].dta` KEPT LEGACY (Step 9 CDE data deferred)" — meaning this is a Christina-acknowledged deferred-chain-rewire decision. Phase 1a Step 9 (this partition) PRODUCES the new chain, but Phase 1b/c will UPDATE the consumers separately. On the next acceptance run, Phase 1 Step 9 batch 9b will produce CANONICAL `sch_char.dta` that no Phase 3 script reads, while Phase 3 heterogeneity scripts read predecessor LEGACY `sch_char.dta` (stale by definition since predecessor `do_all.do` doesn't run as part of consolidated pipeline).

**Why no Partition C deduction:** Partition C correctly produces CANONICAL. The consumer-side staleness is Partition B's problem (and is documented LEGACY there). However, this is the exact class of regression that pre-flight Partition B already caught with `sibling_out_xwalk` and `score_b.dta` — surfacing it here for the partition-coordination ledger.

**Recommended follow-up (NOT IMPLEMENTED — outside Partition C scope):** Phase 1b or §5.3 data-checks should add a `check_chain.do` step that flags any producer-consumer pair where producer is CANONICAL but consumer is LEGACY. The two pre-flight reviews together have identified 5 instances of this class: `sibling_out_xwalk`, `score_b.dta` (×3 readers), survey indices (`<idx>categoryindex.dta`), `analysisready` dtas (×3 deferred readers), `sch_char.dta` (×3 deferred readers).

---

### Informational — Cross-partition deferred consumers of analysisready dtas

**Severity:** Informational (deferred; not Partition C regression)
**Deduction:** 0

Same pattern as sch_char.dta. Partition C `poolingdata/{secpooling,parentpooling,staffpooling,mergegr11enr}.do` produce CANONICAL `$datadir_clean/calschls/analysisready/<sub>analysisready`. The active downstream consumer `do/survey_va/allsvymerge.do:84,96,105` correctly reads CANONICAL. Three other consumers still read LEGACY $caschls_projdir:

- `do/survey_va/factor.do:74,92,110` — reads LEGACY `$caschls_projdir/dta/buildanalysisdata/analysisready/<sub>analysisready` per file header (factor.do is documented "exploratory factor analysis; intermediate, not paper-shipping" in main.do:362).
- `do/survey_va/pcascore.do:65,74,83` — LEGACY per file header (PCA scoreplot for survey factors; intermediate).
- `do/share/svyvaregs/allvaregs.do:113` — LEGACY per file header (svyvaregs umbrella; documented LEGACY-read in INPUTS section line 13).

All three are documented LEGACY-readers. They produce intermediate / exploratory output and are not paper-shipping. Acceptable per the partition's documented deferred-chain decision.

---

### Informational — reconcile_cdscodes.do orphan status

**Severity:** Informational (correctly documented; pending Phase 1c §5.1 review)
**Deduction:** 0

`do/data_prep/k12_postsec_distance/reconcile_cdscodes.do` is NOT invoked from `do/main.do` Phase 1 nor from sister `k12_postsec_distances.do`. The script's own header (lines 16-23) correctly documents this:

> "Per coder-critic round-1 finding on commit `4403758`: this script is NOT invoked from `k12_postsec_distances.do` (the predecessor MAIN never called `do reconcile_cdscodes.do`); it is also NOT invoked from `do/main.do` Phase 1. The script is preserved per ADR-0021 verbatim but is currently orphan in both predecessor and consolidated pipelines. Phase 1c §5.1 dead-code review will decide whether to archive (per ADR-0010 archive-convention) or wire into main.do."

Preserved per ADR-0021 verbatim-preservation principle. Phase 1c §5.1 deferred resolution. Acceptable.

---

## Code Quality (12 categories)

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | Code-Strategy Alignment | MATCH | ADR-0021 sandbox-write principle holds within partition; cross-partition deferred consumers are documented |
| 2 | Sanity Checks | PASS | 0 hardcoded absolute paths in active code; explicit year-set loops; pre-scan flag confirmed false-positive |
| 3 | Robustness | Complete | 40/40 ADR-0021 description blocks; chain documentation present |
| 4 | Script Structure & Headers | OK | All 40 files have PURPOSE / INVOKED FROM / INPUTS / OUTPUTS / RELOCATION / REFERENCES |
| 5 | Console Output Hygiene | OK | `di as text "{hline 80}"` banners are at file-entry points (per ADR-0021 RUN-START convention); not pollution |
| 6 | Reproducibility | OK | `set seed 1984` (or `set seed 20260428` via settings.do) appears in all stochastic files; `set more off` at top |
| 7 | Function/Program Design | OK | One `.doh` helper (merge_k12_postsec_dist.doh); `include` discipline OK |
| 8 | Figure Quality | N/A | This partition produces .dta files, not figures |
| 9 | Output Persistence | OK | All saves to CANONICAL; one Mac-branch sandbox gap (Finding 1) |
| 10 | Comment Quality | OK | Original-author comments preserved verbatim per ADR-0021; relocation notes explain WHY |
| 11 | Error Handling | WARN | `cap`-less `log close _all` in 4 schl_chars files (Finding 2) |
| 12 | Professional Polish | OK | Indentation, line-length, naming consistent across partition |

## Score Breakdown

- Starting: 100
- MAJOR Finding 1 (Mac-local relative-path writes in clean_charter.do): -5
- MINOR Finding 2 (`cap`-less `log close _all` in 4 files): -2
- MINOR Finding 3 (renamedata.do / splitstaff0414.do year-set partition documentation): -2
- Informational Findings 4-6: 0
- **Final: 91/100**

## Compliance Evidence (from .claude/state/verification-ledger.md)

Partition C reviews against ADR-0021 sandbox-write discipline (project-specific; not in the ledger's per-check rubric — the ledger covers `stata-code-conventions.md` per-row). Evidence collected directly during review:

- `do/data_prep/**/*.do` | no-hardcoded-paths | 2026-05-16 | PASS | grep returned 1 match, confirmed inside `/* ... */` at acs_2017_gen_dict.do:65
- `do/data_prep/**/*.do` | sandbox-write-canonical | 2026-05-16 | PASS-with-Minor | 40 files reviewed; 0 active LEGACY-write violations; 1 Mac-branch relative-path write (Finding 1)
- `do/data_prep/**/*.do` | log-using-canonical | 2026-05-16 | PASS | 40/40 files open `log using "$logdir/<filename>.smcl"` + translate to `.log`
- `do/data_prep/**/*.do` | header-block-adr0021 | 2026-05-16 | PASS | 40/40 files have PURPOSE/INVOKED FROM/INPUTS/OUTPUTS/RELOCATION/REFERENCES
- `do/data_prep/**/*.do` | helper-include-absolute | 2026-05-16 | PASS | only `merge_k12_postsec_dist.doh` helper, includes `$consolidated_dir/do/va/helpers/macros_va.doh` absolutely
- `do/data_prep/**/*.do` | multi-year-loop-explicit | 2026-05-16 | PASS | all loops use `local years \`" ... "'` or `forvalues fall_year = ...`; no globbing
- `do/data_prep/**/*.do` | chain-coordination-within-partition | 2026-05-16 | PASS | 7 subdirs producer-consumer pairs all on CANONICAL paths
- `do/data_prep/**/*.do` | cap-log-close | 2026-05-16 | PASS-with-Minor | 4 files use `log close _all` without `cap` prefix (Finding 2)

## Verdict & Escalation Status

**PASS — 91/100.** Above the 80/100 commit gate. No CRITICAL findings. The pre-Scribe golden-master can proceed with respect to Partition C with three caveats:

1. The Mac-local `data_local/` writes in `clean_charter.do` are dead on Scribe; acceptance run is unaffected.
2. The `cap`-less `log close _all` issue is also dead on the acceptance run (prior file leaves a log open); could surface in standalone-script runs.
3. The cross-partition deferred consumers of `sch_char.dta` and `analysisready` dtas are documented Phase 1b/c work and are not Partition C regressions. Combined with Partition B's findings, the project has 5 instances of producer-CANONICAL/consumer-LEGACY chain breaks (sibling_out_xwalk, score_b.dta ×3, categoryindex, analysisready ×3 deferred, sch_char.dta ×3 deferred). The first two classes are blocking (Partition B BLOCK). The last three are documented deferred work — acceptable for the M4 golden-master if the acceptance criteria scope is Step 9 chain-completeness, not full project-wide chain integrity.

**Escalation Status: None.** No strikes accumulated on this review.

---

## Top Findings Summary

| # | Severity | File | Issue | Deduction |
|---|----------|------|-------|-----------|
| 1 | MAJOR | `schl_chars/clean_charter.do:75,105` | Mac-branch relative-path writes outside sandbox | -5 |
| 2 | MINOR | `schl_chars/{cds_nces_xwalk,clean_charter,clean_ecn_disadv,clean_locale}.do` | `log close _all` missing `cap` prefix | -2 |
| 3 | MINOR | `prepare/{renamedata,splitstaff0414}.do` | Year-set partition documentation drift | -2 |
| 4 | INFO | cross-partition | sch_char.dta deferred consumers (out-of-partition; documented LEGACY) | 0 |
| 5 | INFO | cross-partition | analysisready deferred consumers (out-of-partition; documented LEGACY) | 0 |
| 6 | INFO | `k12_postsec_distance/reconcile_cdscodes.do` | Orphan status (correctly documented; Phase 1c §5.1 deferred) | 0 |

**Verdict: PASS (91/100).** Cleared for M4 golden-master with respect to Partition C internal integrity.
