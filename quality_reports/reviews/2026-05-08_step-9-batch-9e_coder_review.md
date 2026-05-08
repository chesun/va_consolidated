# Step 9 Batch 9e (caschls/qoiclean/) Review — coder-critic

**Date:** 2026-05-08
**Reviewer:** coder-critic
**Target:** Phase 1a §3.3 step 9 batch 9e — `do/data_prep/qoiclean/{parent,secondary,staff}/*.do` (10 files) + `do/main.do` Phase 1 wiring delta (commit `0034ae2`)
**Score:** 95/100
**Status:** Active
**Mode:** Tight 5-concern strict-severity review (Phase 1a active relocation; final batch of Step 9)

---

## Verdict

**PASS at 95/100.** Clean batch. All 10 files cleared the 5-concern checklist with one Minor doc-drift deduction. No Critical, no Major. Step 9 ALL BATCHES COMPLETE — proceed to hygiene + push.

---

## Compliance Evidence (from .claude/state/verification-ledger.md)

- `do/data_prep/qoiclean/parent/parentqoiclean1415.do` | (no rows) — inherited artifact
- `do/data_prep/qoiclean/parent/parentqoiclean1516.do` | (no rows)
- `do/data_prep/qoiclean/parent/parentqoiclean1617.do` | (no rows)
- `do/data_prep/qoiclean/parent/parentqoiclean1819_1718.do` | (no rows)
- `do/data_prep/qoiclean/secondary/secqoiclean1415.do` | (no rows)
- `do/data_prep/qoiclean/secondary/secqoiclean1617.do` | (no rows)
- `do/data_prep/qoiclean/secondary/secqoiclean1819_1718_1516.do` | (no rows)
- `do/data_prep/qoiclean/staff/staffqoiclean1415.do` | (no rows)
- `do/data_prep/qoiclean/staff/staffqoiclean1617_1516.do` | (no rows)
- `do/data_prep/qoiclean/staff/staffqoiclean1819_1718.do` | (no rows)

Per `adversarial-default.md` inherited-artifact protocol: all 5 concerns checked manually below; ledger rows not yet populated for this batch (consistent with prior 9a-9d batches; ledger backfill is a separate Phase 1c §5.x activity).

---

## Concern 1 — Sandbox-Write Check (Extended Grep)

**Method:** `grep -nE 'save|export|outsheet|esttab using|graph export|outreg2 using|texsave|translate|log using'` over `do/data_prep/qoiclean/`. Verify every match targets CANONICAL (`$logdir/`, `$datadir_clean/`).

**Result: PASS — zero LEGACY writes.**

| File | Code-line `save` | Code-line `log using` | Code-line `translate` | All CANONICAL? |
|---|---|---|---|---|
| parent/parentqoiclean1415.do | L197 → `$datadir_clean/calschls/qoiclean/parent/parentqoiclean1415` | L60 → `$logdir/parentqoiclean1415.smcl` | L201 → `$logdir/...` | YES |
| parent/parentqoiclean1516.do | L280 → `$datadir_clean/...` | L60 | L284 | YES |
| parent/parentqoiclean1617.do | L287 → `$datadir_clean/...` | L60 | L291 | YES |
| parent/parentqoiclean1819_1718.do | L279 → `$datadir_clean/...\`year'` | L61 | L284 | YES (loop ✓) |
| secondary/secqoiclean1415.do | L250 → `$datadir_clean/...` | L60 | L253 | YES |
| secondary/secqoiclean1617.do | L237 → `$datadir_clean/...` | L60 | L241 | YES |
| secondary/secqoiclean1819_1718_1516.do | L277 → `$datadir_clean/...\`year'` | L62 | L282 | YES (loop ✓) |
| staff/staffqoiclean1415.do | L429 → `$datadir_clean/...` | L62 | L432 | YES |
| staff/staffqoiclean1617_1516.do | L446 → `$datadir_clean/...\`year'` | L62 | L452 | YES (loop ✓) |
| staff/staffqoiclean1819_1718.do | L267 → `$datadir_clean/...\`year'` | L61 | L271 | YES (loop ✓) |

10 saves + 10 log_using + 10 translate = 30 code-line writes. All 30 target CANONICAL globals (`$datadir_clean`, `$logdir`). Multi-year files use `\`year'` correctly inside their loop (matches the read at the same `\`year'` position). No LEGACY writes detected.

**Per-loop save expansion:**
- parentqoiclean1819_1718: loop `{1718, 1819}` → 2 saves to `$datadir_clean/calschls/qoiclean/parent/parentqoiclean{1718,1819}.dta`. Output count consistent with INPUTS coverage (CHAIN-input parent1718, parent1819 both produced by renamedata.do).
- secqoiclean1819_1718_1516: loop `{1516, 1718, 1819}` → 3 saves. Output count matches.
- staffqoiclean1617_1516: loop `{1516, 1617}` → 2 saves. Output count matches.
- staffqoiclean1819_1718: loop `{1718, 1819}` → 2 saves. Output count matches.

Single-year files: 1 save each = 6 saves. Multi-year aggregate: 2+3+2+2 = 9 saves. Per-batch total = 15 .dta outputs (6 single + 9 multi-year inside loops). Reads from CANONICAL `$datadir_clean/calschls/<sub>/<x><year>.dta` (CHAIN from renamedata.do batch 9d).

---

## Concern 2 — INPUTS+OUTPUTS Header Fidelity (4th-recurrence discipline)

**Method:** Read each header's INPUTS section; verify it enumerates the actual reads (year-set for multi-year files, single year for single-year files); verify OUTPUTS section enumerates the saves.

**Result: PASS.**

| File | Year set in body | INPUTS header | OUTPUTS header | Match? |
|---|---|---|---|---|
| parent/parentqoiclean1415.do | 1415 | `parent/parent1415` (L16) | `qoiclean/parent/parentqoiclean1415` + log + translate | YES |
| parent/parentqoiclean1516.do | 1516 | `parent/parent1516` (L16) | matching | YES |
| parent/parentqoiclean1617.do | 1617 | `parent/parent1617` (L16) | matching | YES |
| parent/parentqoiclean1819_1718.do | loop {1718,1819} (body L64) | `parent/parent\`year'  (CHAIN read across {1718,1819}` (L16) | `parentqoiclean\`year'` + log/translate (L19-21) | YES — year-set explicitly enumerated |
| secondary/secqoiclean1415.do | 1415 | `secondary/sec1415` (L16) | matching | YES |
| secondary/secqoiclean1617.do | 1617 | `secondary/sec1617` (L16) | matching | YES |
| secondary/secqoiclean1819_1718_1516.do | loop {1516,1718,1819} (body L69) | `sec\`year' (CHAIN read across {1516,1718,1819}` (L16) | `secqoiclean\`year'` (L19) | YES — 3-year set enumerated |
| staff/staffqoiclean1415.do | 1415 | `staff/staff1415` (L16) | matching | YES |
| staff/staffqoiclean1617_1516.do | loop {1516,1617} (body L65) | `staff/staff\`year'  (CHAIN read across {1516,1617}` (L16) | `staffqoiclean\`year'` (L19) | YES |
| staff/staffqoiclean1819_1718.do | loop {1718,1819} (body L64) | `staff/staff\`year'  (CHAIN read across {1718,1819}` (L16) | `staffqoiclean\`year'` (L19) | YES |

4th-recurrence discipline holds: every multi-year file's INPUTS enumerates its loop's year-set in braces, distinguishing it from `\`year'`-wildcard claims. Single-year files name their concrete year. No ambiguity, no overstated coverage.

---

## Concern 3 — `$projdir`/`$clndtadir` Repointings Clean

**Method:** `grep -nE '\$projdir|\$clndtadir|\$matt_files_dir|\$vaprojdir|\$vaprojxwalks|\$caschls_projdir|\$nscdtadir|\$mattxwalks'` over `do/data_prep/qoiclean/`. Verify all hits are confined to the RELOCATION header doc-block.

**Result: PASS — zero code-line LEGACY-global references.**

All 30 hits (3 per file × 10 files) are at lines 26, 28, 30 of each file — strictly within the RELOCATION header doc-block:

```
$projdir/log/build/buildanalysisdata/qoiclean/<sub>/<x>.smcl   (line 26 — DOC)
$projdir/dta/buildanalysisdata/qoiclean/<sub>/<x>              (line 28 — DOC)
$clndtadir/<sub>/<x> (read) -> $datadir_clean/calschls/<sub>/<x>  (line 30 — DOC)
```

These are doc-block references (denoting predecessor paths to clarify the repointing applied during relocation). They are not interpreted as Stata commands — the surrounding `/*...*/` comment block (lines 1-40) wraps them. Verified by reading lines 41-42 of every file: a blank line separates the doc-block from the original-header `********` and the actual code.

No code-line `$projdir`/`$clndtadir` references found. No other LEGACY globals (`$matt_files_dir`, `$vaprojdir`, etc.) found anywhere.

---

## Concern 4 — main.do Phase 1 Wiring

**Method:** Read `do/main.do` lines 95-160; verify (a) 10 batch-9e invocations grouped by sub-dir (parent/secondary/staff) and year-ordered within sub-dir; (b) one-liner per ADR-0021 on each invocation; (c) Step 9 final-batch marker present (no PENDING blocks for 9a-9e).

**Result: PASS with one Minor doc-drift deduction.**

(a) **10 invocations grouped + ordered.** Lines 143-152: parent×4 (1415, 1516, 1617, 1819_1718) → secondary×3 (1415, 1617, 1819_1718_1516) → staff×3 (1415, 1617_1516, 1819_1718). Sub-dir grouping is parent → secondary → staff, year-ordered within each sub-dir. Sensible chain order: each consumes CANONICAL renamed CalSCHLS data produced by `renamedata.do` (line 136, batch 9d) earlier in the same Stata session. Order is internally consistent.

(b) **One-liners per ADR-0021.** All 10 invocations carry trailing `// QOI clean <subgroup> CalSCHLS <year>` one-liners. Multi-year files explicitly note `(loop)`. Verified against each file's PURPOSE header: one-liner content matches header longer-form purpose. Cross-reference passes.

(c) **Final-batch marker.** Line 139: `* Step 9 batch 9e — caschls/qoiclean/ (10 files): LANDED 2026-05-08 (final batch of Step 9)`. The "(final batch of Step 9)" annotation is present. All 5 batches (9a-9e) on lines 108, 112, 126, 133, 139 now show `LANDED` — none `PENDING`.

**Minor finding (drift):** Line 103 still reads `* Phase 1a §3.3 step 9 IN PROGRESS — Christina-owned data-prep scripts`. This top-level marker pre-dated all 5 batch landings; given that 9e is the final batch (line 139 explicit) and batches 9a-9d all show LANDED, the umbrella header's `IN PROGRESS` is stale. The user's task description anticipated a "Step 9 ALL BATCHES COMPLETE" header note as the final marker; line 139's annotation is sufficient but the top-level line 103 should ideally be updated to `Step 9 COMPLETE — all 5 batches landed 2026-05-08`. **Not load-bearing** — the per-batch annotations are unambiguous; only the umbrella header drifts. **Minor: -2 (inconsistent style / stale doc-string drift).**

(For reference, the batch-9d round-2 review accepted similar minor doc-string drift at the 87/100 threshold; this 9e drift is comparable in scale.)

---

## Concern 5 — Verbatim Preservation Spot-Check (ADR-0021)

**Method:** Diff predecessor body lines (below RELOCATION header) against consolidated body for 2-3 files. Check for documented-only transformations.

**Result: PASS.**

### Spot-check 1 — `parentqoiclean1415.do`

Predecessor `~/Library/CloudStorage/Dropbox/.../qoiclean/parent/parentqoiclean1415.do` (152 lines) vs consolidated (201 lines, of which 1-40 is RELOCATION header → body 41-201, total 161 body lines):

| Predecessor | Consolidated | Transformation |
|---|---|---|
| L1-9 (`*****`/`cap log close`/`clear all`/`set more off`) | L43-52 | Verbatim |
| (none) | L53-58 (`* --- output-directory prep` + 5 `cap mkdir`) | **Added** (CANONICAL mkdir block — expected per task description) |
| L11 `log using $projdir/.../parentqoiclean1415.smcl, replace` | L60 `log using "$logdir/parentqoiclean1415.smcl", replace text` | **Repointed** + double-quoted + `text` flag added (matches expected) |
| L13 `use $clndtadir/parent/parent1415, clear` | L62 `use $datadir_clean/calschls/parent/parent1415, clear` | **CHAIN-read repoint** |
| L14-147 (rename block, recodes, dummies, means, collapse, label vars, year, label data, compress) | L63-196 | Verbatim — no semantic edits |
| L148 `save $projdir/dta/buildanalysisdata/qoiclean/parent/parentqoiclean1415, replace` | L197 `save $datadir_clean/calschls/qoiclean/parent/parentqoiclean1415, replace` | **Repointed** |
| L151 `log close` | L200 `log close` | Verbatim |
| L152 `translate $projdir/.../parentqoiclean1415.smcl $projdir/.../parentqoiclean1415.log, replace` | L201 `translate $logdir/parentqoiclean1415.smcl $logdir/parentqoiclean1415.log, replace` | **Repointed** to single-line ABS form (CANONICAL) |

Total transformations: 4 path repoints (1 log_using, 1 use, 1 save, 1 translate) + 1 added mkdir block + 1 added `text` flag. **Zero semantic-logic edits.** Body lines 14-147 byte-for-byte identical (including comments, whitespace, and the multi-line `/* This is old code... */` commented-out block on L98-109).

### Spot-check 2 — `staffqoiclean1819_1718.do` (loop file)

Predecessor (222 lines) vs consolidated (271 lines = 40-line header + 231 body):

| Predecessor | Consolidated | Transformation |
|---|---|---|
| L1-10 (`*****`/`cap log close`/`clear all`/`set more off`) | L43-52 | Verbatim |
| (none) | L54-59 (mkdir block) | **Added** |
| L12 `log using $projdir/log/.../staffqoiclean1819_1718.smcl, replace` | L61 `log using "$logdir/staffqoiclean1819_1718.smcl", replace text` | **Repointed + quoted + text** |
| L14 `local years \`" "1718" "1819" "'` | L64 same | Verbatim |
| L17 `foreach year of local years {` | L66 same | Verbatim |
| L18 `use $clndtadir/staff/staff\`year', clear` | L67 `use $datadir_clean/calschls/staff/staff\`year', clear` | **CHAIN-read repoint** (loop variable preserved) |
| L19-217 (qoi-cleaning body inside loop) | L68-266 | Verbatim |
| L218 `save $projdir/dta/.../staffqoiclean\`year', replace` | L267 `save $datadir_clean/calschls/qoiclean/staff/staffqoiclean\`year', replace` | **Repointed** (loop variable preserved) |
| L219 `}` (loop close) | L268 same | Verbatim |
| L221 `log close` | L270 same | Verbatim |
| L222 `translate $projdir/log/...staffqoiclean1819_1718.smcl $projdir/log/...staffqoiclean1819_1718.log, replace` | L271 `translate $logdir/staffqoiclean1819_1718.smcl $logdir/staffqoiclean1819_1718.log, replace` | **Repointed to single-line ABS form** |

Total: same 4 repoints + 1 mkdir + 1 `text` flag. **Loop semantics preserved**: `\`year'` substitution in `use` and `save` correctly mirrors the predecessor's per-iteration behavior. **Zero semantic-logic edits.**

### Conclusion

ADR-0021 verbatim preservation holds for both single-year and multi-year (loop) files. The 4 documented transformations (log_using path repoint, save path repoint, translate path repoint, use path repoint for CHAIN-read; plus log_using upgrade to double-quote + `text` flag and prepended `cap mkdir` block) are uniform across all 10 files (verified by structural similarity in Reads of all 10). No semantic-logic drift introduced.

---

## Score Breakdown

| Concern | Severity | Finding | Deduction |
|---|---|---|---|
| 1. Sandbox-write | — | All 30 writes CANONICAL | 0 |
| 2. INPUTS+OUTPUTS headers | — | All 10 fidelity-correct (year-sets enumerated) | 0 |
| 3. `$projdir`/`$clndtadir` repointings | — | Header-only, no code-line refs | 0 |
| 4. main.do wiring | — (a, b, c-batch) | 10 invocations + one-liners + final-batch marker on L139 | 0 |
| 4. main.do wiring | Minor | Line 103 umbrella header still reads `IN PROGRESS` despite all batches landed | -2 |
| 5. Verbatim preservation | — | Spot-checks confirm body byte-identical; only documented transformations | 0 |
| **Other code-quality** | Minor | (none material — code-quality categories 4-12 not in scope per task) | -3 (general inherited-artifact compliance margin: per `adversarial-default.md` inherited-artifact protocol, ledger rows are absent for these files; deducted minimally as Phase-1 ongoing convention is to defer ledger backfill — but flagging) |

**Starting:** 100
**Deductions:** −2 (umbrella `IN PROGRESS` drift) + −3 (ledger rows absent for inherited artifacts; minor)
**Final: 95/100 — PASS.**

---

## Recommendations (non-blocking)

1. **Update line 103 of `do/main.do`** in a follow-up hygiene commit: `* Phase 1a §3.3 step 9 IN PROGRESS` → `* Phase 1a §3.3 step 9 COMPLETE — all 5 batches landed 2026-05-08`. Cosmetic; don't re-dispatch coder-critic for this single-line edit (per `phase-1-review.md` §7 single-line typo exception). Apply during the next batch's hygiene pass or in Phase 1c §5 cleanup.
2. **Ledger backfill for batches 9a-9e** as a Phase 1c §5.x task: 32 files (2+11+5+4+10) × ~5 checks each = ~160 ledger rows. Defer to a single batch-write rather than amortizing across each landing.

---

## Verdict (final)

**Score: 95/100. PASS.** Below the 90 PR-gate ceiling for warning, well above the 80 commit-gate hard floor. Only one Minor doc-drift finding (line 103 umbrella header) plus ledger-absence margin. Zero Critical, zero Major.

**Step 9 is complete.** All 5 batches (9a-9e) have landed: 2 + 11 + 5 + 4 + 10 = 32 Christina-owned data-prep files relocated under `do/data_prep/`. Proceed to hygiene + push.

**Commit footer recommendation:** `coder-critic: PASS (95/100); Minor finding deferred — line 103 umbrella header drift (apply in next hygiene pass).`
