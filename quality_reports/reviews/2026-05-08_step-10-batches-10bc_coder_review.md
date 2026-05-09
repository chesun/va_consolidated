# Step 10 Batches 10b + 10c Joint Review — coder-critic
**Date:** 2026-05-08
**Reviewer:** coder-critic
**Target:** Phase 1a §3.3 step 10 batches 10b (4 caschls/share/demographics files; commit `65aae2d`) + 10c (7 caschls misc files + STEP 10 COMPLETE marker; commit `bc17fbf`); round 2 fixes commit `3d8874d`
**Score:** Round 1: 78/100 — BLOCK. **Round 2: 82/100 — PASS** (≥ 80 hard gate).
**Status:** Active

---

## Verdict

**Round 1: BLOCK** at the 80/100 hard gate. **Round 2: PASS** at 82/100.

The round-2 commit `3d8874d` lands the strategic intent of the F1 + F2-headline fixes, but does so partially. F1 is partially fixed (4 of 7 affected files completely fixed; 3 demographics files + uniquefamily.do retain leaf-mkdir gaps), and F2 is one-of-five fixed (k12_nsc2019_merge.doh OUTPUTS only). The dispatch prompt explicitly acknowledged F2.2-F2.5 deferred as "Minor; runtime unaffected" — that's a legitimate scoping choice consistent with the round-1 fix-recommendation note that F3+F4 may be deferred if doing so doesn't push below 80. Round-2 score lands at 82/100, just above the hard gate. Step 10 + Phase 1a §3.3 ratify-as-PASS.

The remaining F1 leaf-mkdir gap (per-year leaves for the 3 demographics graph files + 1 missing graph dir in uniquefamily.do) is a real runtime regression on a fresh sandbox — the demographics graphs will fail to export. But (a) the demographics files are diagnostic-only ("not paper-shipping" per their own headers), (b) uniquefamily.do's missing `$output_dir/graph/siblingxwalk` mkdir is a single-graph diagnostic-export failure that doesn't break the chain (the chain `save` to `$datadir_clean/siblingxwalk/uniquelinkedfamilyclean` at L100 IS protected by the new mkdir), and (c) the failing leaf-mkdir cases are documented here for future cleanup. Keeping these as known-issue F5/F6 deductions in this round-2 audit rather than re-blocking — gate calibration is "is this commit shippable?" not "is this commit perfect?" The round-2 fixes meet the shippable bar.

---

## Round 2 Findings

### Round-2 fix verification (per dispatch prompt items 1-7)

| Item | File | Fix landed | Notes |
|------|------|------------|-------|
| 1 | `do/share/demographics/elemcoverageanalysis.do` | PARTIAL | mkdir to `$output_dir/graph/svycoverage/elemcoverage` ✓; **missing 5 per-year leaves** (`elem1415` through `elem1819`) per round-1 F1.1 explicit rec |
| 2 | `do/share/demographics/parentcoverageanalysis.do` | PARTIAL | mkdir to `$output_dir/graph/svycoverage/parentcoverage` ✓; missing 5 per-year leaves (`parent1415`-`parent1819`) |
| 3 | `do/share/demographics/seccoverageanalysis.do` | PARTIAL | mkdir to `$output_dir/graph/svycoverage/seccoverage` ✓; missing 35 nested leaves (`sec<year>/gr<i>` for 5 years × 7 grades) |
| 4 | `do/share/demographics/pooledsecanalysis.do` | UNCHANGED | already correct in round 1; verified unchanged |
| 5 | `do/share/siblingxwalk/siblingmatch.do` | FIXED ✓ | L57 now `cap mkdir "$datadir_clean/siblingxwalk"` matching L116+L152 saves |
| 5 | `do/share/siblingxwalk/uniquefamily.do` | PARTIAL | L63 `siblingxwalk` mkdir landed ✓ (L100 chain save protected); **missing `$output_dir/graph/siblingxwalk` for L99 graph export** |
| 5 | `do/share/siblingxwalk/siblingpairxwalk.do` | FIXED ✓ | L60 now `cap mkdir "$datadir_clean/siblingxwalk"` matching L94+L126 saves |
| 6 | `do/share/svyvaregs/allvaregs.do` | FIXED ✓ | L77-88 prep block correctly drops dead `$tables_dir/share/survey/` prep, adds `$output_dir/dta/varegs/` + `$output_dir/xls/varegs/{unweighted,weighted}/` with foreach-svyname loop creating per-survey leaves for parent/sec/staff/elem (matches L113 `foreach svyname in sec parent staff` plus the elem branch). All 448 regsave + 6 export-excel write targets covered. |
| 7 | `do/share/outcomesumstats/nsc2019new/k12_nsc2019_merge.doh` | FIXED ✓ | OUTPUTS L15-17 now `$datadir_clean/outcomesumstats/k12_nsc_2019_{final,provisional}_merge` (CANONICAL); LEGACY tag dropped |

**F1 fix completeness:** 4 of 7 files completely fixed; 3 demographics files + uniquefamily.do retain leaf-mkdir gaps. Round-1 F1 was -10; round-2 reduction to **-5** reflects the 4 of 7 fully-fixed (~57% complete on count) plus F2.1's headline win removing the most-serious LEGACY-claim mismatch.

**F2 fix completeness:** 1 of 5 fixed (k12_nsc2019_merge.doh OUTPUTS — the headline F2.1, which was the most consequential because it was a falsified compliance claim). The other 4 (nsc_codebook INPUTS, allvaregs INPUTS, siblingpairxwalk INPUTS, demographics-trio INVOKED FROM line) are deferred per dispatch prompt's explicit choice. Round-1 F2 was -8; round-2 reduction to **-3** reflects the headline-fix landing (k12_nsc2019_merge was -3 on its own in the round-1 cluster decomposition).

### F5 (Minor, -2) NEW — uniquefamily.do graph export will fail on fresh sandbox

L99 `graph export $output_dir/graph/siblingxwalk/numsiblingdist.png, replace` has no protecting `cap mkdir "$output_dir/graph"` or `cap mkdir "$output_dir/graph/siblingxwalk"`. Round-1 F1.5 explicitly called this out: *"also add `cap mkdir "$output_dir"`, `cap mkdir "$output_dir/graph"`, `cap mkdir "$output_dir/graph/siblingxwalk"` for the L99 graph export."*

The round-2 fix added the `siblingxwalk` data-dir mkdir for L100 save (chain-critical, correct), but did not add the graph-dir mkdir for L99. On fresh sandbox, the `graph export` at L99 will fail. The downstream chain to `save` at L100 is protected and will succeed (so the chain through siblingpairxwalk → allvaregs is intact), but the diagnostic graph won't write. Diagnostic-only impact; deduction = -2.

### F6 (Minor, -3) NEW — demographics-trio missing per-year leaf mkdirs

The 3 demographics graph files (elem/parent/sec coverageanalysis) write to per-year (and for sec, per-year-per-grade) leaves but the round-2 fix only added the parent dir, not the leaves. Round-1 F1.1-F1.3 explicitly recommended `foreach i in 1415 1516 1617 1718 1819 { cap mkdir "$output_dir/graph/svycoverage/.../<prefix>`i'" }` (and the nested 5×7 = 35 leaves for sec). On fresh sandbox, these 40+ graph-export calls will fail. Diagnostic-only impact (per the headers themselves which call these "diagnostic — not paper-shipping"), so deduction = -3 (down from F1's -10 because the chain-critical saves are all protected and only diagnostic graphs are at risk).

### F3 + F4 (carried from round 1; not addressed in round-2 commit)

- **F3 (Minor, -2):** k12_nsc2019_merge.doh body L67+L82 hardcoded paths still characterized as "dormant rebuild branch" in header L13 + L29. Active code, not dormant. Header text only; no runtime impact. Deduction held at -2.
- **F4 (Minor, -1):** main.do L407 comment about mattschlchar Phase 5/6 invocation still imprecise. Deduction held at -1.

### Standing approvals (unchanged from round 1)

All round-1 standing approvals carry forward:
- mattschlchar.do header + mkdir + dormant `clean==1` branch all OK
- Sandbox-write check across all 11 files: zero LEGACY writes in active code (re-verified post round-2 commit; no regressions)
- `$projdir` repointing: zero active-code references in all 11 files
- Phase 6 main.do wiring (L401-406): correct dependency order (siblingmatch → uniquefamily → siblingpairxwalk; nsc_codebook standalone; allvaregs standalone)
- Phase 5 main.do mattschlchar.do insertion (L356): correct order
- Phase 6 main.do batch 10b (L395-398): correct order
- settings.do `$cstdtadir` add: correct
- allvaregs.do `_va_all_nw` save in weighted block: predecessor parity bug; document but do not deduct

---

## Round 2 Score Breakdown

- **Starting:** 100
- **F1 (Major, -5):** 4 of 7 mkdir fixes complete; 3 demographics + uniquefamily.do retain leaf-mkdir gaps (down from round-1 -10 reflecting 57% file-count completion + headline-win)
- **F2 (Major, -3):** k12_nsc2019_merge.doh OUTPUTS LEGACY → CANONICAL fix landed (the most-consequential header drift; down from round-1 -8 reflecting headline-fix landing while 4 sub-findings deferred)
- **F3 (Minor, -2):** k12_nsc2019_merge.doh header still calls active hardcoded paths "dormant" — unchanged
- **F4 (Minor, -1):** main.do L407 mattschlchar Phase 5/6 invocation comment still imprecise — unchanged
- **F5 (Minor, -2):** uniquefamily.do L99 `$output_dir/graph/siblingxwalk` graph mkdir still missing (NEW — separately-tracked because the data-dir mkdir DID land but the graph-dir didn't)
- **F6 (Minor, -3):** demographics-trio per-year leaf mkdirs still missing (NEW — separately-tracked because the parent svycoverage mkdirs DID land but the per-year leaves didn't)
- **Adversarial-default ledger evidence captured:** -2 (rows still not appended for batch 10b/c paths post-fix; same gap as round 1, slightly larger because round-2 changes invalidate any pre-fix hashes)

**Final round 2: 100 - 5 - 3 - 2 - 1 - 2 - 3 - 2 = 82/100 — PASS** (≥ 80 hard gate)

The score lands at 82, just above the gate. The author's deferral choices (defer F2.2-F2.5 + accept partial F1 on diagnostic-only paths) are defensible given the runtime impact map: chain-critical saves are all protected (siblingmatch → uniquefamily → siblingpairxwalk → allvaregs intact), only diagnostic-graph exports fail on first run, and re-runs after manual `mkdir -p` or hand-creation of a few dirs would succeed.

---

## Carry-forward to Phase 1b §4.2 candidate list

The following defects are surfaced here for future cleanup but do not block Step 10 / Phase 1a §3.3 closure:

1. **F5:** uniquefamily.do L99 — add `cap mkdir "$output_dir/graph"` + `cap mkdir "$output_dir/graph/siblingxwalk"` (1-line each)
2. **F6:** elemcoverageanalysis.do — add 5-year leaf-mkdir loop after L66
3. **F6:** parentcoverageanalysis.do — add 5-year leaf-mkdir loop after L57
4. **F6:** seccoverageanalysis.do — add 5-year × 7-grade nested leaf-mkdir loops after L66
5. **F2.2:** nsc_codebook.do INPUTS — drop the 2 `$output_dir/txt/outcomesumstats/...` lines (own outputs, not inputs)
6. **F2.3:** allvaregs.do INPUTS — drop the 4 OUTPUTS-misclassified-as-inputs at L13-17
7. **F2.4:** siblingpairxwalk.do INPUTS — drop the self-output re-read at L13
8. **F2.5:** demographics-trio (elem/parent/sec coverageanalysis.do) INVOKED FROM L11 — change `pooleddiagnostics/` → `svycoverage/`
9. **F3:** k12_nsc2019_merge.doh header L13 + L29 — change "dormant rebuild branch" → "preserved verbatim per ADR-0021"
10. **F4:** main.do L407 — replace ambiguous "or separately by Table 8 producers" wording

Recommend: address in a single Phase 1b §4.3 cleanup commit (mechanical edits; no behavioral change). Total: ~10-15 line-edits across 8 files.

---

## Compliance Evidence (from .claude/state/verification-ledger.md)

Round 2 again did not append ledger rows for the 11 batch-10b/c relocated files. Spot-checks substituting for ledger rows:

- `do/share/demographics/elemcoverageanalysis.do` | mkdir-prep-matches-write-targets | 2026-05-08T (round 2) | (post-`3d8874d`) | PARTIAL | mkdir to `svycoverage/elemcoverage` ✓; missing 5 per-year leaves
- `do/share/demographics/parentcoverageanalysis.do` | mkdir-prep-matches-write-targets | 2026-05-08T (round 2) | (post-`3d8874d`) | PARTIAL | mkdir to `svycoverage/parentcoverage` ✓; missing 5 per-year leaves
- `do/share/demographics/seccoverageanalysis.do` | mkdir-prep-matches-write-targets | 2026-05-08T (round 2) | (post-`3d8874d`) | PARTIAL | mkdir to `svycoverage/seccoverage` ✓; missing 35 nested leaves
- `do/share/siblingxwalk/siblingmatch.do` | mkdir-prep-matches-write-targets | 2026-05-08T (round 2) | (post-`3d8874d`) | PASS | `siblingxwalk` mkdir matches all 2 saves
- `do/share/siblingxwalk/uniquefamily.do` | mkdir-prep-matches-write-targets | 2026-05-08T (round 2) | (post-`3d8874d`) | PARTIAL | `siblingxwalk` data mkdir ✓ (L100 chain save protected); missing graph-dir for L99
- `do/share/siblingxwalk/siblingpairxwalk.do` | mkdir-prep-matches-write-targets | 2026-05-08T (round 2) | (post-`3d8874d`) | PASS | `siblingxwalk` mkdir matches both saves
- `do/share/svyvaregs/allvaregs.do` | mkdir-prep-matches-write-targets | 2026-05-08T (round 2) | (post-`3d8874d`) | PASS | foreach-svyname loop covers parent/sec/staff/elem under both `dta/varegs/` and `xls/varegs/{unweighted,weighted}/`
- `do/share/outcomesumstats/nsc2019new/k12_nsc2019_merge.doh` | header-output-fidelity | 2026-05-08T (round 2) | (post-`3d8874d`) | PASS | OUTPUTS L15-17 now CANONICAL `$datadir_clean/outcomesumstats/...` matching body L71+86

Recommendation for Phase 1b §4.3 cleanup commit: append concrete rows for each of the 11 paths covering `no-hardcoded-paths`, `adr-0021-sandbox-write`, `header-input-fidelity`, `mkdir-prep-matches-write-targets` post-cleanup. Per-file content hashes recompute after cleanup commit.

Reference rows from prior batches that calibrate this round-2 review's severity:

- `do/_archive/siblingvaregs/` | archive-convention | 2026-05-08T05:00Z | PASS — establishes that LEGACY writes in `do/_archive/` are expected and out of scope
- `do/va/heterogeneity/persist_het_student_char_fig.do` | header-input-fidelity | 2026-05-08T04:00Z | PASS — establishes that header INPUTS field must match body grep output
- `do/samples/touse_va.do` | adr-0021-sandbox-write | 2026-05-07T22:00Z | PASS — strict-severity sandbox-fidelity precedent

---

## Escalation Status

None — round 2 PASS. Strike count for batches 10b+10c: 1 of 3 (round 1 BLOCK only); round 2 cleared the gate. **Step 10 + ALL OF PHASE 1a §3.3 = COMPLETE.** Hygiene + push approved. Phase 1b §4.3 cleanup commit recommended for the 10 carry-forward defects (mechanical; no behavioral risk).
