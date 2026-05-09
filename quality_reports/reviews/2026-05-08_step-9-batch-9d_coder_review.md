# Step 9 Batch 9d (caschls/prepare/) Review — coder-critic

**Date:** 2026-05-08
**Reviewer:** coder-critic
**Target:** Phase 1a §3.3 step 9 batch 9d — `do/data_prep/prepare/{enrollmentclean,poolgr11enr,renamedata,splitstaff0414}.do` + `do/settings.do` LEGACY-globals delta + `do/main.do` Phase 1 wiring (round 1: commit `677033f`; round 2: commit `c35e22a`)
**Score:** round 1: 67/100 BLOCK → round 2: 87/100 PASS
**Status:** Active
**Mode:** Tight 5-concern strict-severity review (Phase 1a active relocation)

---

## Verdict

**Round 1: BLOCK at 67/100.** Two Critical findings made this a hard-stop:

1. **Undefined global `$rawcsvdir` referenced in `renamedata.do` lines 230 and 235** but NOT defined in `do/settings.do`. The 11-12 and 12-13 secondary CSV imports will fail at runtime on Scribe. Predecessor `caschls/do/settings.do:12` defines it; the consolidated settings.do delta added `$rawdtadir` (line 159) and `$clndtadir` (line 160) but missed the third sibling `$rawcsvdir`. Per `derive-dont-guess.md` per-domain table: "References a Stata global ($foo) that's not defined in settings.do or master script | -20".

2. **Chain semantics broken**: in the predecessor, `renamedata.do` writes `$clndtadir/staff/staff0414` (LEGACY) and `splitstaff0414.do` reads `$clndtadir/staff/staff0414`, so splitstaff0414 reads what renamedata just wrote in the same pipeline run. In the consolidated, renamedata writes to `$datadir_clean/calschls/staff/staff0414` (CANONICAL — line 291) but splitstaff0414 still reads `$clndtadir/staff/staff0414` (LEGACY pre-existing — line 68). After a fresh `rm -rf $datadir_clean/calschls/staff/` re-run, splitstaff0414 silently reads a stale LEGACY copy and ignores renamedata's update. The header docstring on splitstaff0414 calls staff0414 "pre-existing" but the predecessor master.do (lines 127-132) shows renamedata is invoked BEFORE splitstaff0414 — so in the predecessor pipeline, $clndtadir/staff/staff0414 is renamedata's just-written output, not a static input. This is a verbatim-preservation violation under ADR-0021.

Plus one Major and two Minor findings detailed below.

**Round 2: PASS at 87/100.** All 5 round-1 fixes verified landed. One new Minor finding: stale doc-string lines in 4 files + `main.do` line 137 one-liner still describe splitstaff0414 as a LEGACY pre-existing read (`$clndtadir/staff/staff0414`) even though the line-68 code is now a CHAIN read from CANONICAL. Code is correct; only doc-string drift. Below 80 threshold not approached; PASS.

---

## Compliance Evidence (from .claude/state/verification-ledger.md)

- `do/data_prep/prepare/enrollmentclean.do` | (no rows) — inherited artifact, not yet ledger-verified. Per inherited-artifact protocol, all 5 concerns checked manually below.
- `do/data_prep/prepare/poolgr11enr.do` | (no rows)
- `do/data_prep/prepare/renamedata.do` | (no rows)
- `do/data_prep/prepare/splitstaff0414.do` | (no rows)
- `do/settings.do` | (no rows for the 9d delta)
- `do/main.do` | (no rows for the 9d delta)

Adversarial-default deduction: per inherited-artifact protocol (-10 per missing row capped at -30) the absence of ledger rows is acknowledged but **not separately deducted here** because this is an active in-session review producing the verification — the manual checks below substitute. Recommend Christina (or follow-up tooling) populate ledger rows once round 2 lands.

---

## Concern-by-concern findings

### Concern 1 — Sandbox-write check (CANONICAL only, no LEGACY writes)

**Status: PASS.**

Grep `save|saving|export|graph export|outsheet|outreg2 using|texsave|esttab using|log using|translate` over the 4 files. All write-targets confirmed CANONICAL:

- `enrollmentclean.do`: 5 saves to `$datadir_clean/enrollment/schoollevel/\`enrdata'` (line 258, in foreach); log_using line 66 → `$logdir/enrollmentclean.smcl`; translate line 267 → `$logdir/`. Total: 5 dta + 2 log targets, all CANONICAL.
- `poolgr11enr.do`: 1 save line 84 → `$datadir_clean/enrollment/schoollevel/poolgr11enr` (CANONICAL); log_using line 70 + translate line 88 → `$logdir/`. 1 dta + 2 log, all CANONICAL.
- `renamedata.do`: 22 saves (lines 121, 128, 135, 142, 149, 190, 197, 204, 211, 218, 232, 237, 244, 251, 258, 265, 272, 279, 291, 298, 305, 312, 319, 326) — recount: 5 elem + 5 parent + 8 secondary + 6 staff = 24. (Header lists ~22; I counted 24 saves; close-enough match.) All target `$datadir_clean/calschls/{elementary,parent,secondary,staff}/`. log_using + translate to `$logdir/`. All CANONICAL.
- `splitstaff0414.do`: 1 save line 88 → `$datadir_clean/calschls/staff/staff\`i'` in foreach (CANONICAL). log_using + translate to `$logdir/`. All CANONICAL.

ZERO LEGACY writes. Grep `save\s+["\$]?(\$projdir|\$caschls_projdir|\$rawdtadir|\$clndtadir|\$rawcsvdir|\$vaprojdir|\$matt)` returns no matches.

### Concern 2 — INPUTS+OUTPUTS header fidelity

**Status: PARTIAL (Minor finding).**

Body grep for `use|using|merge|append using|import|include` per file:

- `enrollmentclean.do`: body has 1 `use` (line 72, `$caschls_projdir/dta/enrollment/raw/\`enrdata'`). Header line 12 lists 1 LEGACY input. Match. **PASS.**

- `poolgr11enr.do`: body has 1 `use` + 4 `append using` (lines 73-77, all `$datadir_clean/enrollment/schoollevel/enr<year>`). Header lines 12-16 enumerate all 5 CHAIN inputs. **PASS.**

- `renamedata.do`: body has 22 reads via `use` + 2 reads via `import delimited` = **24 inputs**. Header INPUTS block (lines 11-33) lists 22 inputs (all `$rawdtadir/...`). **The 2 `$rawcsvdir/secondary/CHKS_1112_*.csv` and `$rawcsvdir/secondary/CHKS_1213_*.csv` (body lines 230, 235) are NOT enumerated in the header.** This is a Minor INPUTS-list incompleteness (-3).

  Header OUTPUTS block (lines 35-61) lists 24 outputs (5 elem + 5 parent + 8 secondary + 6 staff) — body grep returns 24 saves. Match.

- `splitstaff0414.do`: body has 1 `use` (line 68, `$clndtadir/staff/staff0414`). Header line 12 lists this LEGACY input. Match. **PASS.**

**Deduction:** -3 (Minor: header-INPUT-list omits 2 `$rawcsvdir/secondary/` CSV reads in renamedata.do).

### Concern 3 — `$projdir`/`$rawdtadir`/`$clndtadir` repointings clean

**Status: PASS.**

Grep `\$projdir` over 4 files: 12 matches, all in header doc-block RELOCATION listings. ZERO code-line `$projdir` references. PASS.

Body code-line global usage:

- `$caschls_projdir/dta/enrollment/raw/...` reads (LEGACY raw): enrollmentclean line 72 — acceptable per header repointing rule.
- `$rawdtadir/.../...` reads (LEGACY): renamedata 22 occurrences — acceptable.
- `$clndtadir/staff/staff0414` read (LEGACY pre-existing): splitstaff0414 line 68 — acceptable per header.
- ZERO writes to any of `$projdir`, `$caschls_projdir`, `$rawdtadir`, `$clndtadir` in code lines. Grep confirms.

### Concern 4 — main.do Phase 1 wiring + chain order + ADR-0021 one-liners

**Status: PARTIAL (Minor finding).**

main.do lines 133-137 contain batch-9d block:

- Lines 134 + 135: enrollmentclean BEFORE poolgr11enr (chain order). **PASS.**
- Lines 136 + 137: renamedata BEFORE splitstaff0414. Order matches predecessor master.do (lines 127-132). However, see Concern 5 — chain output is broken at the path level even though invocation order is correct.
- Pending-9e flag-comment retained (lines 139-140). **PASS.**

ADR-0021 one-liners (cross-checked against each file's header PURPOSE):

- enrollmentclean (line 134): "clean CDE annual enrollment 2014-15..2018-19; produces $datadir_clean/enrollment/schoollevel/enr<year>.dta (5 files; chain producer)". Header line 6 says same. **PASS.**
- poolgr11enr (line 135): "pool gr11 enrollment across 5 years; reads CHAIN enr<year>; writes $datadir_clean/enrollment/schoollevel/poolgr11enr.dta". Header line 6 matches. **PASS.**
- renamedata (line 136): "rename + standardize raw CalSCHLS surveys (elementary/parent/secondary across years); writes $datadir_clean/calschls/{elementary,parent,secondary}/<x><year>.dta". **Omits "staff"** despite header PURPOSE (line 6) explicitly mentioning staff and OUTPUTS listing 6 staff dtas. Inconsistent with the file's actual scope. **Minor (-2)**.
- splitstaff0414 (line 137): "split pre-existing $clndtadir/staff/staff0414 by year; writes $datadir_clean/calschls/staff/staff<year>.dta". Header line 6 matches. **PASS** for the one-liner per se (but the underlying "pre-existing" framing is the load-bearing issue — see Concern 5).

**Deduction:** -2 (Minor: one-liner for renamedata omits staff scope).

### Concern 5 — Verbatim preservation under ADR-0021 + settings.do edit

**Status: FAIL (Critical + Major).**

#### Critical (5a) — Undefined `$rawcsvdir` global

`renamedata.do` body lines 230 and 235 reference `$rawcsvdir/secondary/...`:

```
import delimited "$rawcsvdir/secondary/CHKS_1112_SecData_Statewide_School_ID_1213Var_110414.csv", clear
import delimited "$rawcsvdir/secondary/CHKS_1213_SecData_Statewide_School_ID_111114.csv", clear
```

Grep `global\s+(rawcsvdir|rawdtadir|clndtadir)` over `do/settings.do`:

```
159:global rawdtadir  "/home/research/ca_ed_lab/data/restricted_access/raw/calschls/stata"
160:global clndtadir  "/home/research/ca_ed_lab/data/restricted_access/clean/calschls"
```

`$rawcsvdir` is NOT defined. The settings.do delta added `$rawdtadir` and `$clndtadir` but the third sibling required by renamedata.do was missed. Predecessor `caschls/do/settings.do:12` defines `global rawcsvdir "/home/research/ca_ed_lab/data/restricted_access/raw/calschls/csv"`.

On Scribe runtime, `import delimited "$rawcsvdir/secondary/CHKS_1112_*.csv"` resolves to `import delimited "/secondary/CHKS_1112_*.csv"` (empty global → leading slash) → file-not-found → script halts at line 230. The 11-12 secondary, 12-13 secondary, and all subsequent saves do not execute.

Per `derive-dont-guess.md` Critical row: "References a Stata global ($foo) that's not defined in settings.do or master script | -20".

**Deduction:** -20.

#### Major (5b) — Chain output discontinuity for staff0414

In the predecessor (caschls/do/master.do lines 127-132), `renamedata.do` runs first and writes `$clndtadir/staff/staff0414`. Then `splitstaff0414.do` reads `$clndtadir/staff/staff0414` — same path, just-written file.

In the consolidated (do/main.do lines 136-137), `renamedata.do` is repointed to write `$datadir_clean/calschls/staff/staff0414` (CANONICAL — line 291 of the consolidated `renamedata.do`). But `splitstaff0414.do` line 68 still reads `$clndtadir/staff/staff0414` (LEGACY pre-existing).

Result: after a fresh `rm -rf $datadir_clean/calschls/staff/` and a re-run, splitstaff0414 silently reads a stale LEGACY copy that may be older than what renamedata just wrote. Worse, if Christina (or successor) later modifies `renamedata.do`'s staff0414 cleaning logic, splitstaff0414 will not pick up the change.

The header docstring on splitstaff0414 (line 6, line 12) labels staff0414 "pre-existing" — technically true if read against a populated LEGACY dir, but predecessor master.do documents it is NOT pre-existing in the predecessor pipeline, it is renamedata's same-run output.

The fix is for splitstaff0414 to read `$datadir_clean/calschls/staff/staff0414` (CANONICAL) — the just-written output of renamedata in the consolidated pipeline. Alternative: make renamedata also write a copy to `$clndtadir/staff/staff0414` — but that violates the no-LEGACY-writes principle. The first option is the correct fix.

This is a verbatim-preservation violation: the consolidation changed the same-run chain from "read renamedata's output" to "read a stale LEGACY copy that ignores renamedata's output," which silently changes pipeline semantics on a fresh-run basis.

**Deduction:** -10 (Major: chain semantics changed; consolidated pipeline does not preserve the predecessor's same-run data flow for staff0414).

#### Major (5c) — Missing `cap mkdir "$datadir_clean/calschls/staff"` in renamedata.do

`renamedata.do` writes 6 staff dtas to `$datadir_clean/calschls/staff/` (lines 291, 298, 305, 312, 319, 326). But the cap mkdir block (lines 105-110) only creates:

```
$logdir, $datadir_clean, $datadir_clean/calschls, $datadir_clean/calschls/elementary, $datadir_clean/calschls/parent, $datadir_clean/calschls/secondary
```

The `$datadir_clean/calschls/staff` directory is NOT pre-created. On a fresh sandbox (e.g., a clean Scribe install or after `rm -rf $datadir_clean/calschls/`), the first staff save (line 291) will fail with "file ... could not be opened" because the staff/ subdir does not exist.

Note: `splitstaff0414.do` does cap mkdir `$datadir_clean/calschls/staff` (line 64), but it runs AFTER renamedata in main.do (lines 136 → 137), so it cannot remediate renamedata's missing mkdir.

This is a regression vs the existing batch-9d sister scripts (enrollmentclean, splitstaff0414) which all correctly mkdir before saving. Quick fix: add `cap mkdir "$datadir_clean/calschls/staff"` between lines 110 and 112.

**Deduction:** -5 (Major: missing mkdir for a write-target subdir; first staff save fails on fresh sandbox).

#### Settings.do docstring (5d)

Settings.do lines 152-160 add a clear LEGACY-READ-ONLY docstring:

```
* CalSCHLS restricted-access data dirs (LEGACY-READ-ONLY).  Predecessor caschls
* settings.do binds these to absolute Scribe paths outside both repos.  Used
* for raw-survey reads in batch 9d (renamedata.do, splitstaff0414.do) and
* batch 9e (qoiclean year-by-year files).  Writes from those batches go to
* CANONICAL $datadir_clean/calschls/* per ADR-0021 sandbox-write principle.
* Pre-existing cleaned data already in $clndtadir (e.g., staff0414) stays
* there as a LEGACY read source for splitstaff0414's split operation.
```

The docstring is clear and explicit about read-only status. **PASS** for this aspect — but note the docstring's "Pre-existing cleaned data already in $clndtadir (e.g., staff0414) stays there as a LEGACY read source" claim contradicts the predecessor master.do invocation order (renamedata BEFORE splitstaff0414 produces staff0414). This is the same finding as 5b in different framing — already deducted.

#### `name(...)` suffix preservation (5e)

Predecessor grep:

- enrollmentclean.do: `log using ... name(enrollmentclean)` → consolidated line 66: `log using "$logdir/enrollmentclean.smcl", replace text name(enrollmentclean)` — preserved. **PASS.**
- renamedata.do: `name(renamedata)` → consolidated line 112: `name(renamedata)` — preserved. **PASS.**
- splitstaff0414.do: `name(splitstaff0414)` → consolidated line 66: `name(splitstaff0414)` — preserved. **PASS.**
- poolgr11enr.do: predecessor has NO `name()` → consolidated line 70: `log using "$logdir/poolgr11enr.smcl", replace text` (no name). Consistent. **PASS.**

`text` flag added to all 4 (consolidated convention from Step 7 indexalpha). **PASS.**

#### `cap mkdir` blocks

- enrollmentclean: 4 mkdirs covering all write-targets. **PASS.**
- poolgr11enr: 4 mkdirs covering all write-targets. **PASS.**
- renamedata: 6 mkdirs but **missing staff/** — see 5c above. **FAIL.**
- splitstaff0414: 4 mkdirs covering all write-targets. **PASS.**

---

## Score breakdown

Starting: 100

| # | Severity | Finding | Deduction |
|---|---|---|---|
| 5a | Critical | `$rawcsvdir` referenced in renamedata.do lines 230/235; not defined in settings.do | -20 |
| 5b | Major | Chain semantics broken: renamedata writes CANONICAL staff0414, splitstaff0414 reads LEGACY pre-existing — verbatim-preservation violation under ADR-0021 | -10 |
| 5c | Major | `cap mkdir "$datadir_clean/calschls/staff"` missing in renamedata.do; first staff save fails on fresh sandbox | -5 |
| 2 | Minor | renamedata.do header INPUTS list omits 2 `$rawcsvdir/secondary/*.csv` reads (rows 230, 235) | -3 |
| 4 | Minor | main.do line 136 one-liner for renamedata.do omits "staff" scope | -2 |

Subtotal: -40 points.

**Round 1 final score: 60/100.**

Adjustment up: per coder-critic discretion, the 4 files demonstrate meaningful discipline elsewhere — clean header doc-blocks, consistent CANONICAL writes, ADR-0021 description convention applied, no `$projdir` code-line leakage, `name()` preservation, settings.do docstring quality. These do not erase the Critical finding but are evidence of good faith. Adjusting back to **67/100** to reflect that the bulk of the work is correct and the issues are concentrated in two specific oversights (rawcsvdir omission + staff0414 chain framing).

**Round 1: 67/100 — BLOCK (< 80).**

---

## Required fixes for round 2

1. **Add `$rawcsvdir` to do/settings.do** in the LEGACY-READ-ONLY block. Suggested form:

   ```stata
   global rawcsvdir  "/home/research/ca_ed_lab/data/restricted_access/raw/calschls/csv"
   ```

   Place adjacent to `$rawdtadir` (line 159) for visual grouping. Update the docstring header (lines 152-158) to mention `$rawcsvdir` alongside `$rawdtadir`/`$clndtadir`. Update header SETTINGS REQUISITE block in renamedata.do to list `$rawcsvdir` (and add $rawcsvdir to the "settings.do edited in this batch to add LEGACY-READ-ONLY globals" line — currently only mentions 2 globals).

2. **Resolve the staff0414 chain.** Two acceptable fixes:

   - **Preferred (CANONICAL chain):** Edit `splitstaff0414.do` line 68 from `use $clndtadir/staff/staff0414, clear` to `use $datadir_clean/calschls/staff/staff0414, clear`. Update the file's header doc-block INPUTS section, RELOCATION block, and PURPOSE line to reflect the CHAIN semantics (no longer "pre-existing LEGACY"; now "CHAIN read from renamedata.do batch-9d output"). Update settings.do docstring (lines 152-160) to remove the "Pre-existing cleaned data already in $clndtadir (e.g., staff0414) stays there as a LEGACY read source" sentence — it is now misleading.

   - **Alternative (preserve LEGACY semantics):** Document explicitly that splitstaff0414 reads a stale LEGACY copy and that re-running renamedata does NOT propagate to splitstaff0414 unless the LEGACY copy is also refreshed. This is uglier; the preferred fix is cleaner.

3. **Add `cap mkdir "$datadir_clean/calschls/staff"`** to `renamedata.do` between lines 110 and 112 (the existing mkdir block).

4. **Update renamedata.do header INPUTS** (lines 11-33) to enumerate the 2 `$rawcsvdir/secondary/CHKS_{1112,1213}_*.csv` reads. Suggested addition between line 27 and line 28 (after the 1314 secondary entry):

   ```
       $rawcsvdir/secondary/CHKS_1112_SecData_Statewide_School_ID_1213Var_110414.csv  (LEGACY)
       $rawcsvdir/secondary/CHKS_1213_SecData_Statewide_School_ID_111114.csv  (LEGACY)
   ```

5. **Update main.do line 136 one-liner** for renamedata to include staff:

   ```
   do do/data_prep/prepare/renamedata.do  // rename + standardize raw CalSCHLS surveys (elementary/parent/secondary/staff across years); writes $datadir_clean/calschls/{elementary,parent,secondary,staff}/<x><year>.dta
   ```

After these 5 fixes, re-dispatch round 2. None of them are scope-creep; all directly address findings in this review.

---

## Out of scope (not assessed)

- Stata version / package compatibility on Scribe.
- Whether the underlying CalSCHLS cleaning logic (gen/replace/collapse blocks) is correct.
- Full 12-category rubric beyond the 5 concerns.
- Plan v3 §3.3 step 9 batch 9e (qoiclean) — separate review.

---

## Round 2 — fix verification + re-score (commit `c35e22a`)

**Date:** 2026-05-08
**Method:** Per-fix grep verification + regression sweep + doc-code consistency check.

### Fix 1 (Critical 5a) — `$rawcsvdir` defined in settings.do

`grep -n 'global\s\+rawcsvdir' do/settings.do` → **line 164**:

```
164:global rawcsvdir  "/home/research/ca_ed_lab/data/restricted_access/raw/calschls/csv"
```

Absolute path matches predecessor `caschls/do/settings.do:12` exactly. Sibling-grouped immediately after `global rawdtadir` (line 163) and before `global clndtadir` (line 165), as round-1 review suggested.

Surrounding docstring (lines 152-162) updated coherently:
- Line 157-158: "$rawdtadir holds .dta-format raw surveys (most years); $rawcsvdir holds the pre-2014 .csv-format secondary surveys."
- Line 158-162: "$clndtadir is currently used only by qoiclean (batch 9e) for legacy-clean reads — splitstaff0414 was repointed to read CHAIN $datadir_clean/calschls/staff/staff0414 (produced by renamedata earlier in main.do invocation order; coder-critic round 1 on commit 677033f flagged the LEGACY-read regression)."

The docstring now correctly distinguishes the three globals' roles and acknowledges the round-1 LEGACY-read regression.

**Status: PASS.** -20 round-1 deduction restored.

### Fix 2 (Major 5b) — staff0414 chain fix in splitstaff0414.do

`grep -n 'staff0414' do/data_prep/prepare/splitstaff0414.do` → **line 68**:

```
68:use $datadir_clean/calschls/staff/staff0414, clear  // CHAIN read from renamedata.do (same-batch producer; see plan v3 §3.3 step 9 batch 9d invocation order)
```

CHAIN read from CANONICAL — no longer LEGACY. Inline comment cites the producer (`renamedata.do`) and references the plan section. Excellent.

INPUTS section updated (line 12):

```
12:    $datadir_clean/calschls/staff/staff0414  (CHAIN read; from renamedata.do this batch — runs first per main.do invocation order)
```

Settings.do docstring (lines 158-162, see Fix 1) explicitly removes the misleading "Pre-existing cleaned data ... stays there as a LEGACY read source" claim and replaces it with the CHAIN semantics.

**Status: PASS** for the load-bearing fix. **But see Concern R2-A below** for stale-doc-string drift introduced as a side-effect.

-10 round-1 deduction restored.

### Fix 3 (Major 5c) — `cap mkdir "$datadir_clean/calschls/staff"` in renamedata.do

`grep -n 'cap mkdir' do/data_prep/prepare/renamedata.do` → 7 mkdirs total:

```
107:cap mkdir "$logdir"
108:cap mkdir "$datadir_clean"
109:cap mkdir "$datadir_clean/calschls"
110:cap mkdir "$datadir_clean/calschls/elementary"
111:cap mkdir "$datadir_clean/calschls/parent"
112:cap mkdir "$datadir_clean/calschls/secondary"
113:cap mkdir "$datadir_clean/calschls/staff"
```

All 4 calschls subdirs covered. The 6 staff saves (lines 294, 301, 308, 315, 322, 329 — re-counted post-fix) will succeed on fresh sandbox.

**Status: PASS.** -5 round-1 deduction restored.

### Fix 4 (Minor 2) — renamedata.do INPUTS list now lists 24 inputs

`grep -nE '^\s+\$(raw(dta|csv)dir|clndtadir)' do/data_prep/prepare/renamedata.do` (header doc-block INPUTS section, lines 11-35) shows 24 enumerated inputs:

- 5 elementary `$rawdtadir/elementary/CHKS_*` (lines 12-16)
- 5 parent `$rawdtadir/parent/CSPS_*` (lines 17-21) [includes `csps1415 all.dta` on line 21]
- 2 secondary `$rawcsvdir/secondary/CHKS_*.csv` (lines 22-23) — **NEWLY ADDED**
- 6 secondary `$rawdtadir/secondary/CHKS_*` (lines 24-29)
- 6 staff `$rawdtadir/staff/CSSS_*` (lines 30-35)

Total: 5 + 5 + 2 + 6 + 6 = 24 inputs. Body grep also returns 24 (22 `use` + 2 `import delimited`). **Match exact.**

**Status: PASS.** -3 round-1 deduction restored.

### Fix 5 (Minor 4) — main.do line 136 one-liner

`do/main.do` line 136:

```
do do/data_prep/prepare/renamedata.do               // rename + standardize raw CalSCHLS surveys (elementary/parent/secondary/staff across years); writes $datadir_clean/calschls/{elementary,parent,secondary,staff}/<x><year>.dta — incl. pooled staff0414 consumed by splitstaff0414
```

Now includes "staff" in scope description, matches header PURPOSE (line 6) and OUTPUTS (lines 56-61 — 6 staff dtas). The "incl. pooled staff0414 consumed by splitstaff0414" tail is a nice cross-link to the chain semantics.

**Status: PASS.** -2 round-1 deduction restored.

### Concern R2-A (NEW Minor) — Doc-string drift on splitstaff0414's LEGACY framing

**Status: FAIL (Minor).**

The Fix 2 round-1 fix correctly updated `splitstaff0414.do` line 68 (CHAIN read) and line 12 (INPUTS section). But several other doc-block locations still describe the old LEGACY-read behavior:

1. `do/data_prep/prepare/splitstaff0414.do` line 6 (PURPOSE):

   ```
   split pre-existing $clndtadir/staff/staff0414 by year; produces $datadir_clean/calschls/staff/staff<year>.dta.
   ```

   Says "pre-existing $clndtadir/staff/staff0414" but line 68 reads `$datadir_clean/calschls/staff/staff0414`. **Stale.**

2. `do/data_prep/prepare/splitstaff0414.do` line 26 (RELOCATION block):

   ```
   $clndtadir/<sub>/<x> (read of pre-existing)      -> kept LEGACY (e.g., $clndtadir/staff/staff0414)
   ```

   Example given is staff0414, but staff0414 is now CHAIN, not LEGACY. **Stale.** (The general repointing rule "kept LEGACY (read of pre-existing)" is fine; only the example needs to change to a different file or note that batch 9d has no LEGACY pre-existing reads of $clndtadir.)

3. `do/data_prep/prepare/splitstaff0414.do` lines 35-39 (SETTINGS REQUISITE):

   ```
   settings.do edited in this batch to add LEGACY-READ-ONLY globals
   `$rawdtadir' (CalSCHLS restricted raw survey data) and `$clndtadir'
   (CalSCHLS restricted clean data, pre-existing — used for read of
   staff0414 in splitstaff0414.do).  No write-eligible target via
   those globals; writes go to $datadir_clean/calschls/* CANONICAL.
   ```

   Says "$clndtadir ... used for read of staff0414 in splitstaff0414.do" — false now; splitstaff0414 no longer reads $clndtadir. Should say "used for read by qoiclean (batch 9e)" or similar. Also missing $rawcsvdir from the LEGACY-globals list. **Stale + incomplete.**

4. `do/data_prep/prepare/splitstaff0414.do` line 12 (INPUTS) — **correctly updated** to CHAIN (already verified Fix 2). ✓

5. `do/data_prep/prepare/{enrollmentclean,poolgr11enr,renamedata}.do` — RELOCATION blocks (lines 25-26 / 29-30 / 71-72 / 25-26) all still show:

   ```
   $clndtadir/<sub>/<x> (read of pre-existing)      -> kept LEGACY (e.g., $clndtadir/staff/staff0414)
   ```

   The staff0414 example is stale across all 4 files. SETTINGS REQUISITE blocks (lines 36-40 / 39-43 / 80-84 / 35-39) all still say "$clndtadir ... used for read of staff0414 in splitstaff0414.do". Also missing $rawcsvdir from the globals list across all 4 files.

6. `do/main.do` line 137 one-liner:

   ```
   do do/data_prep/prepare/splitstaff0414.do           // split pre-existing $clndtadir/staff/staff0414 by year; writes $datadir_clean/calschls/staff/staff<year>.dta
   ```

   Says "pre-existing $clndtadir/staff/staff0414" — contradicts line 68 of the script (CHAIN read from CANONICAL). **Stale.**

The CODE is correct (Fix 2 succeeded). Only doc-strings drifted. Severity: Minor — these are framing/comment text, not load-bearing logic. Successor reading the doc-blocks would see contradictory information (line 12 says CHAIN; line 6 says pre-existing LEGACY) and have to consult the line-68 code or the round-1/round-2 review to disambiguate. Not pipeline-breaking.

**Deduction: -3 (Minor).** Fix is to grep-and-replace "pre-existing $clndtadir/staff/staff0414" → "CHAIN-read $datadir_clean/calschls/staff/staff0414" across the 4 batch-9d files + main.do, AND update the SETTINGS REQUISITE blocks across the 4 files to (a) list `$rawcsvdir` alongside `$rawdtadir`/`$clndtadir`, (b) replace the splitstaff0414-staff0414-LEGACY example with a qoiclean (batch 9e) reference or note that staff0414 is now CHAIN.

This is a follow-up cleanup, not a re-block — score stays comfortably above 80.

### Regression sweep — Concerns 1, 3, original-Concern-2 partial-PASS, original-Concern-4 partial-PASS

**Concern 1 (sandbox-write CANONICAL):** `grep -nE 'save|export|outsheet|esttab using|graph export|outreg2 using|texsave' do/data_prep/prepare/{enrollmentclean,poolgr11enr,renamedata,splitstaff0414}.do` returns 32 write-targets (5+1+24+1 = +1 from the new mkdir... wait, mkdirs aren't writes; rechecking) — re-count: enrollmentclean 5 saves + poolgr11enr 1 save + renamedata 24 saves + splitstaff0414 1 save = **31 write-targets**. All match `$datadir_clean/...` or `$logdir/...`. ZERO LEGACY writes. **PASS, no regression.**

**Concern 3 (`$projdir` code-line leakage):** `grep -nE '\$projdir' do/data_prep/prepare/` returns 12 matches across 4 files (3 per file × 4 = 12), all in RELOCATION header doc-block (lines 22-24 of each). ZERO code-line `$projdir`. **PASS, no regression.**

**Concern 2 (now-PASS):** Fix 4 raised renamedata.do INPUTS to 24 ✓; the other 3 files' INPUTS still match body. **PASS.**

**Concern 4 (now-PASS):** Fix 5 raised renamedata one-liner to include staff ✓; splitstaff0414 one-liner is stale per Concern R2-A but that's a separate doc-drift issue, not a scope-omission. The scope description on splitstaff0414's one-liner ("split ... by year; writes $datadir_clean/calschls/staff/staff<year>.dta") IS correct in scope; only the "pre-existing $clndtadir" framing is stale. **PASS for scope; stale framing folded into R2-A above.**

**No prior PASS concern regressed.** The Fix 2 chain repoint introduced doc-drift but did not break code in any file.

### Round 2 score

Starting: 100

| # | Severity | Finding | Deduction |
|---|---|---|---|
| 5a | (RESOLVED) | `$rawcsvdir` now defined at settings.do:164 | 0 |
| 5b | (RESOLVED) | splitstaff0414.do line 68 reads CHAIN-CANONICAL; settings.do docstring updated | 0 |
| 5c | (RESOLVED) | renamedata.do line 113 mkdirs `$datadir_clean/calschls/staff` | 0 |
| 2  | (RESOLVED) | renamedata.do INPUTS section now lists 24 inputs (added 2 $rawcsvdir CSV entries) | 0 |
| 4  | (RESOLVED) | main.do line 136 includes "staff" in renamedata's scope description | 0 |
| R2-A | Minor (NEW) | Doc-string drift: splitstaff0414's PURPOSE / RELOCATION / SETTINGS REQUISITE blocks + the same blocks in 3 sister files + main.do line 137 still describe staff0414 as "pre-existing $clndtadir LEGACY" though line 68 is CHAIN; SETTINGS REQUISITE missing $rawcsvdir | -3 |

Subtotal: -3.

Per `phase-1-review.md` §4 + `quality.md` §1, the floor is 80 for commit. Round-2 score is comfortably above:

**Round 2 final score: 97/100.**

Adjustment down: per coder-critic discretion, I am reluctant to score the doc-string drift at only -3 because it spans 4 files + main.do + the settings.do docstring (which itself partially corrects but does not fully fix — the line 158-162 sentence is correct, but the per-file doc-blocks are stale). The full set of stale lines is ~10-12 occurrences across 5 files. On the other hand, the underlying load-bearing fixes (5a-5c, 2, 4) all landed cleanly with thoughtful inline comments and updated cross-references. Settling on 87/100 to weight the doc-drift more honestly without over-penalizing high-quality core fixes.

**Round 2: 87/100 — PASS (≥ 80).**

### Verdict

**Round 2: PASS at 87/100. Batch 9d is committable.**

All 5 round-1 critical/major/minor findings landed clean fixes. One new Minor finding (R2-A) — doc-string drift introduced as a side-effect of Fix 2 — is below the BLOCK threshold. Recommend Christina address R2-A in the batch-9d commit as a tidy-up, OR fold it into a batch-9e/post-batch grep-and-replace pass that updates the LEGACY-framing language uniformly across batches 9d + 9e (since 9e files will inherit the same RELOCATION block template).

Given the auto-mode dispatch and the round-1 → round-2 convergence pattern (5/5 fixes landed with no regressions in the load-bearing checks), this is a well-executed correction cycle.

### Round-2 follow-up recommendations (not blocking)

1. **R2-A doc-string sweep** — update PURPOSE/RELOCATION/SETTINGS REQUISITE blocks in batch-9d files + main.do line 137 to remove stale "$clndtadir/staff/staff0414 pre-existing LEGACY" framing. Suggest doing this in batch 9e's commit (where the same RELOCATION block is being added to qoiclean files) to keep batch-level commits semantically tight.

2. **Verification ledger population** — once batch 9d is final-committed, populate ledger rows for `(do/data_prep/prepare/{enrollmentclean,poolgr11enr,renamedata,splitstaff0414}.do, no-hardcoded-paths|seed-set-once|sandbox-writes-canonical)` with PASS evidence so future inherited-artifact reviews can short-circuit on cached PASS rather than re-running grep.

3. **Status update on this review** — after R2-A is addressed (whether in 9d-followup or 9e), append a Round 3 verification (or just a one-line "R2-A cleared in commit XXX" note) and mark the review `Status: Completed` to remove from active queue.
