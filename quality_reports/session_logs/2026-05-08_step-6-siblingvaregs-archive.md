# Session Log — 2026-05-08: Phase 1a §3.3 Step 6 — siblingvaregs archive

## Goal

Land Step 6: archive 27 deprecated siblingvaregs .do/.doh files. **First archive-convention batch** — different from active relocations (no path repointing, bodies untouched per ADR-0021).

## Approach

1. Inventory `caschls/do/share/siblingvaregs/` (29 files).
2. Verify each file against ADR-0004 deprecation list + active-code grep (vafilemacros.doh kept LEGACY).
3. `cp` 27 files to `do/_archive/siblingvaregs/` (Dropbox source → consolidated repo).
4. Write README at archive subdir.
5. Tier 1 + Tier 2 review.
6. Commit + push + immediate hygiene.

## Key finding — vafilemacros.doh exclusion

Per ADR-0004 line 31: "vaestmacros.doh, vafilemacros.doh (helpers used only by deprecated files — verify before archiving)".

**Verification grep:**
- `vaestmacros.doh` — included only by deprecated siblingvaregs files (`va_sibling_fb_test_tab.do`, `va_sibling_vam_tab.do`, etc.) → ARCHIVE
- `vafilemacros.doh` — included by ACTIVE relocated code:
  - `do/sibling_xwalk/siblingoutxwalk.do:164` (relocated 2026-04-30 per ADR-0005)
  - `do/va/prior_decile_original_sample.do:155` (relocated batch 3c1)
  → KEEP LEGACY at `$caschls_projdir/do/share/siblingvaregs/vafilemacros.doh`

ADR-0004's "verify before archiving" clause was the right gate; without it I'd have broken 2 active scripts at runtime.

## Step 6 archive convention (precedent for Step 8)

This is the FIRST archive batch; sets precedent:

| Aspect | Active relocation (Steps 1-5, 7, 9, 10) | Archive (Steps 6, 8) |
|---|---|---|
| Path repointing | YES — sed pass for $vaprojdir/* → CANONICAL | NO — bodies verbatim |
| Headers added | YES — full ADR-0021 headers | NO — files unchanged |
| main.do wiring | YES — invoked from production block | NO — not invoked |
| Verify-before-X | LEGACY-include macro-trace + grep-OUTPUTS/INPUTS | ADR deprecation list × active-code grep |
| Source method | `cp` + sed + Python script | `cp` only |
| Destination | `do/<topic>/` | `do/_archive/<topic>/` |
| README needed? | NO (each file's own header documents) | YES (explains archive scope + exclusions) |

## Tier 1 self-check

- ✅ Inventory cross-checked against ADR-0004 deprecation list
- ✅ vafilemacros.doh exclusion grounded in active-code grep
- ✅ siblingoutxwalk.do exclusion grounded in ADR-0005 prior relocation
- ✅ 27 files copied verbatim (no sed pass)
- ✅ README at `do/_archive/siblingvaregs/README.md` documenting scope
- ✅ main.do unchanged (archived files not invoked)

## Tier 2 coder-critic dispatch

**Verdict: PASS 96/100.**

5 concerns dispatched. All PASS:
1. ADR-0004 deprecation list match (27 files)
2. vafilemacros.doh exclusion verified (2 active consumers)
3. Archive convention compliance (verbatim; spot-check confirmed)
4. README content (status + ADR refs + file list + exclusion rationale)
5. main.do unchanged

One Minor finding: README L21-22 count nits ("5 files"/"4 files" but listed more) → **FIXED in-commit** by enumerating each file with category subtotals.

2 ledger rows added in-commit.

## Commit

`b8b4ce8` — phase-1a(§3.3 step 6): archive 27 deprecated siblingvaregs files.

Files:
- 27 .do/.doh files at `do/_archive/siblingvaregs/` (NEW)
- `do/_archive/siblingvaregs/README.md` (NEW)
- `.claude/state/verification-ledger.md` (MODIFIED — 2 new rows)
- `quality_reports/reviews/2026-05-07_siblingvaregs-archive_coder_review.md` (NEW)

Footer: `coder-critic: PASS (96/100); README count nit FIXED in-commit.`

## ★ STEPS 1-6 ALL COMPLETE ★

| Step | Type | Files | Status |
|---|---|---:|---|
| 1 | Active relocation (helpers/macros) | 3 | ✓ |
| 2 | Active relocation (sample construction) | 17 | ✓ |
| 3 | Active relocation (VA estimation chain) | 21 | ✓ |
| 4 | Active relocation (heterogeneity) | 4 | ✓ |
| 5 | Active relocation (sibling crosswalk) | 1 | ✓ |
| 6 | **Archive (siblingvaregs deprecated)** | 27 | ✓ |

**Total: 73 files Phase 1a §3.3 work to date.**

## Status (end of session segment)

- **Phase 1a §3.3 progress: 73 of ~150 files.**
- **ADR ledger:** 21 Decided.
- **Plan v3:** APPROVED.
- **Tree:** clean; pushed (`b8b4ce8`).
- **Coder-critic audit trail:** 15 entries.

## Next session

**Step 7 — Survey VA (~10 files).** Active relocation (NOT archive). Source: `caschls/do/share/factoranalysis/`. Destination: `do/survey_va/`.

**Convention reminders:**
1. Active-relocation conventions apply (paths to repoint per ADR-0021).
2. Watch for `$projdir` references (caschls files; alias-before-include pattern per [LEARN:stata]).
3. Grep BOTH inputs AND outputs before writing each header (4th-recurrence discipline).
4. `alpha.do` is in same source dir but is Step 8 (archive per ADR-0010); separate from Step 7.
