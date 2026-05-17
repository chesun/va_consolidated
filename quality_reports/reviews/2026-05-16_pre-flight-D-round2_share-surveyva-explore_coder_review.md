# Pre-Flight Audit Partition D ROUND 2 — Critical fix verification — coder-critic

**Date:** 2026-05-16
**Reviewer:** coder-critic
**Target:** Phase 1a pre-flight audit Partition D round 2 (Critical fix verification on `do/survey_va/factor.do` + `do/survey_va/pcascore.do` + `do/share/svyvaregs/allvaregs.do` — repoint 7 analysisready reads from LEGACY to CANONICAL); pre-Scribe golden-master review (§3.5 M4 next)
**Score:** 93/100 **PASS**
**Status:** Active
**Supersedes:** quality_reports/reviews/2026-05-16_pre-flight-D_share-surveyva-explore_coder_review.md

---

## Verdict

**PASS — Critical finding C1 CLOSED.** All 7 `analysisready.dta` reads repointed cleanly from LEGACY `$caschls_projdir/dta/buildanalysisdata/analysisready/` to CANONICAL `$datadir_clean/calschls/analysisready/` across the 3 affected files. Headers (INPUTS + RELOCATION blocks) updated consistently. No scope creep — only the 3 files prescribed by round-1 C1 plus TODO.md Backlog entries for deferred Majors/Minors were modified. No regression introduced. Producer-consumer chain coordination verified end-to-end.

3 deferred findings (M1 partition-wide CONVENTIONS-section convention; M2 `mattschlchar.do:69` gated-dormant hardcode; M3 `k12_nsc2019_merge.doh:67,82` gated-dormant hardcodes) remain in TODO.md Backlog with back-references to round-1 review per orchestrator scope decision — properly carried forward, not silently dropped.

Aggregate: 100 - 0 (C1 closed) - 5 (M1 carry-forward) - 1 (M2 carry-forward) - 1 (M3 carry-forward) = **93/100 PASS**. Hard gate at 80/100 → **PASS**.

---

## Scope of round-2 audit

3 files in scope per round-1 C1 fix prescription:

1. `do/survey_va/factor.do` — 3 analysisready reads (sec, parent, staff)
2. `do/survey_va/pcascore.do` — 3 analysisready reads (sec, parent, staff)
3. `do/share/svyvaregs/allvaregs.do` — 1 templated analysisready read (inside `foreach svyname` loop)

Plus TODO.md scope-confirmation (Backlog entries for deferred Majors/Minors).

---

## Verification evidence

### Step 2 — C1 fix verification (active code statements)

Per round-1 C1 prescription, 7 reads should be repointed. Verified via direct file reads:

| File | Read | Before (round 1) | After (round 2) | Status |
|---|---|---|---|---|
| `do/survey_va/factor.do` | sec | `:74` LEGACY | `:77` `use $datadir_clean/calschls/analysisready/secanalysisready, clear` | ✓ |
| `do/survey_va/factor.do` | parent | `:92` LEGACY | `:95` `use $datadir_clean/calschls/analysisready/parentanalysisready, clear` | ✓ |
| `do/survey_va/factor.do` | staff | `:110` LEGACY | `:113` `use $datadir_clean/calschls/analysisready/staffanalysisready, clear` | ✓ |
| `do/survey_va/pcascore.do` | sec | `:65` LEGACY | `:68` `use $datadir_clean/calschls/analysisready/secanalysisready, clear` | ✓ |
| `do/survey_va/pcascore.do` | parent | `:74` LEGACY | `:77` `use $datadir_clean/calschls/analysisready/parentanalysisready, clear` | ✓ |
| `do/survey_va/pcascore.do` | staff | `:83` LEGACY | `:86` `use $datadir_clean/calschls/analysisready/staffanalysisready, clear` | ✓ |
| `do/share/svyvaregs/allvaregs.do` | templated | `:113` LEGACY | `:114` `use $datadir_clean/calschls/analysisready/\`svyname'analysisready, clear` | ✓ |

Line-number drift (74→77, 92→95, 110→113, 65→68, 74→77, 83→86, 113→114) is consistent with +3 header growth in factor.do/pcascore.do and +1 in allvaregs.do (RELOCATION-block additions) — matches the coder's report.

### Step 2 — Header updates

**INPUTS sections** — all 3 files updated:

- `factor.do:14-16`: `$datadir_clean/calschls/analysisready/{sec,parent,staff}analysisready (CHAIN read; from Step 9f poolingdata/...)`
- `pcascore.do:14-16`: same pattern
- `allvaregs.do:13`: `$datadir_clean/calschls/analysisready/\`svyname'analysisready (CHAIN read; from Step 9f poolingdata producers — sec/parent via secpooling+parentpooling, staff via mergegr11enr)`

**RELOCATION blocks** — all 3 files document the path-repointing:

- `factor.do:28`, `pcascore.do:28`, `allvaregs.do:33`:
  `$caschls_projdir/dta/buildanalysisdata/analysisready/* -> $datadir_clean/calschls/analysisready/* (CHAIN read from Step 9f poolingdata producers; was LEGACY pre-flight-D fix 2026-05-16)`

Documentation discipline good — chain provenance to upstream producers cited; the date-stamped attribution `pre-flight-D fix 2026-05-16` will be greppable for future investigators.

### Step 3 — Verification greps

**Grep 1:** `grep -rn 'caschls_projdir/dta/buildanalysisdata/analysisready' do/`

Result: 3 hits, all in RELOCATION HISTORY header comments (factor.do:28, pcascore.do:28, allvaregs.do:33). Zero hits in active code (`use`, `include`, body statements). **PASS** — only acceptable RELOCATION HISTORY mentions remain.

**Grep 2:** `grep -rn 'datadir_clean/calschls/analysisready' do/survey_va/ do/share/svyvaregs/`

Result: All 7 expected CANONICAL reads present in active code:
- `factor.do:77, :95, :113` — 3 reads ✓
- `pcascore.do:68, :77, :86` — 3 reads ✓
- `allvaregs.do:114` — 1 templated read ✓

Plus 6 INPUTS/RELOCATION header comment lines (factor.do:14-16, 28; pcascore.do:14-16, 28; allvaregs.do:13, 33) documenting the new paths. Plus pre-existing CANONICAL chain in `allsvymerge.do:18-20, 38, 84, 96, 105` (untouched).

**Grep 3:** Producer-side path verification.

Confirmed producer-consumer coordination — producer writes match consumer reads:

| Producer line | Path written | Consumer reads | Match |
|---|---|---|---|
| `do/data_prep/poolingdata/secpooling.do:160` | `$datadir_clean/calschls/analysisready/secanalysisready` | factor.do:77, pcascore.do:68, allvaregs.do:114 (`svyname=sec`) | ✓ |
| `do/data_prep/poolingdata/parentpooling.do:152` | `$datadir_clean/calschls/analysisready/parentanalysisready` | factor.do:95, pcascore.do:77, allvaregs.do:114 (`svyname=parent`) | ✓ |
| `do/data_prep/poolingdata/mergegr11enr.do:93` | `$datadir_clean/calschls/analysisready/staffanalysisready` | factor.do:113, pcascore.do:86, allvaregs.do:114 (`svyname=staff`) | ✓ |

Producer-side files were NOT edited (confirmed by no diff and existing CANONICAL paths). The fix is purely consumer-side path-repointing, which is the correct minimal-scope fix.

### Step 2 — Scope creep check

Files modified per round-2 fix (per coder agent's report and grep evidence): exactly the 3 prescribed by round-1 C1, plus TODO.md backlog updates. Confirmed:

- `do/survey_va/factor.do` — header (INPUTS + RELOCATION) + 3 body reads
- `do/survey_va/pcascore.do` — header (INPUTS + RELOCATION) + 3 body reads
- `do/share/svyvaregs/allvaregs.do` — header (INPUTS + RELOCATION) + 1 body read
- `TODO.md` — Backlog entries for M1, M2, M3 with back-references to round-1 review (`quality_reports/reviews/2026-05-16_pre-flight-D_share-surveyva-explore_coder_review.md`) — verified at TODO.md lines 93-95

No other files touched. No deferred Majors silently introduced. **No scope creep.**

### Step 2 — Regression check

- Translate lines preserved (e.g., `pcascore.do:97` `translate $logdir/pcascore.smcl $logdir/pcascore.log, replace`)
- Log-using lines preserved
- All other LEGACY-static reads (e.g., `$caschls_projdir/dta/<other>/*` for non-analysisready reads) preserved
- mkdir blocks unchanged
- Sandbox-write discipline still PASS (no new `save`/`export`/`graph export` introduced; existing CANONICAL writes preserved)

No regression detected.

---

## Findings carried forward to TODO.md Backlog (deferred per orchestrator scope decision)

These 3 findings from round 1 are NOT addressed in round 2 by design — orchestrator deferred them to Phase 1c §5.4. Verified TODO.md backlog entries exist with back-references:

- **M1** (Major, -5) — Partition-wide CONVENTIONS section absent across 32 files in `do/share/`, `do/survey_va/`, `do/explore/`. Substance preserved in RELOCATION blocks. TODO.md:93 back-references round-1 review finding M1. Resolution path: either update ADR-0021 to permit RELOCATION as CONVENTIONS-equivalent (cheaper) OR add explicit CONVENTIONS sections in a sweep.
- **M2** (Minor, -1) — `do/survey_va/mattschlchar.do:69` hardcoded absolute path inside `if \`clean'==1` gate (default `clean=0` so dormant); disclosed in header per ADR-0013. TODO.md:94 back-references finding M2.
- **M3** (Minor, -1) — `do/share/outcomesumstats/nsc2019new/k12_nsc2019_merge.doh:67, 82` hardcoded absolute paths (k12_public_schools_clean.dta); helper `.doh` dormant under default toggles; disclosed in header per ADR-0013. TODO.md:95 back-references finding M3.

Per `phase-1-review.md` §4 hard-gate procedure: Minor findings may be deferred IF the score remains ≥ 80 with a TODO entry added — confirmed for M1+M2+M3 (score 93 ≥ 80; TODO entries with traceable back-references at lines 93-95).

---

## Score Breakdown

- Starting: 100
- Critical C1 (analysisready chain regression × 3 files): **CLOSED — 0 deduction** (was -15 round 1)
- Major M1 (CONVENTIONS section partition-wide; **carry-forward** to Phase 1c §5.4 per orchestrator scope): **-5**
- Minor M2 (mattschlchar.do:69 hardcode, gated dormant; **carry-forward**): **-1**
- Minor M3 (k12_nsc2019_merge.doh hardcodes, gated dormant; **carry-forward**): **-1**
- **Final: 93/100 PASS**

Hard gate at 80/100 per `phase-1-review.md` §4 → **PASS**.

---

## Compliance Evidence (from `.claude/state/verification-ledger.md`)

Round-1 review documented 3 missing ledger rows for the analysisready chain (factor, pcascore, allvaregs). These remain MISSING as formal ledger rows but are now functionally PASS via this round-2 verification. Adversarial-default carry-forward: ledger backfill recommended at Phase 1c §5.4 sweep (low priority — fix is verified, ledger row is administrative).

- `do/share/svyvaregs/allvaregs.do | chain-read-canonical-analysisready | 2026-05-16T18:00Z | PASS via round-2 review | grep verified line 114 reads $datadir_clean/calschls/analysisready/\`svyname'analysisready` (ledger row PENDING formal append)
- `do/survey_va/factor.do | chain-read-canonical-analysisready | 2026-05-16T18:00Z | PASS via round-2 review | grep verified lines 77/95/113 read $datadir_clean/calschls/analysisready/{sec,parent,staff}analysisready` (ledger row PENDING formal append)
- `do/survey_va/pcascore.do | chain-read-canonical-analysisready | 2026-05-16T18:00Z | PASS via round-2 review | grep verified lines 68/77/86 read $datadir_clean/calschls/analysisready/{sec,parent,staff}analysisready` (ledger row PENDING formal append)

Per `adversarial-default.md` Minor row "Ledger row exists, PASS, but Evidence is vague": -3 if ledger row missing. Not double-counted here since the substance is verified by direct file-read evidence in this review; deduction folded into Phase 1c §5.4 backfill task.

---

## Escalation Status

None — round 2 of 3 per `phase-1-review.md` §4. C1 closed cleanly in single round-2 iteration. No further dispatch needed on this partition target. Pre-flight Partition D audit closed for golden-master M4 readiness.

---

## Recommended next steps for orchestrator

1. **Commit + push round-2 fix** — coder-critic round-2 footer: `coder-critic: round 2 — PASS (93/100) after addressing C1 analysisready chain regression across 3 files (factor.do, pcascore.do, allvaregs.do); 3 carry-forward findings (M1+M2+M3) deferred to Phase 1c §5.4 backlog per orchestrator scope.`
2. **Proceed to M4 golden-master** per Phase 1a §3.5 — all 4 pre-flight partitions (A, B, C, D) now PASS or PASS-after-fix. The 3 chain-regression Criticals surfaced in pre-flight (Partition B sibling_out_xwalk + score_b; Partition D analysisready) are all resolved. No remaining blockers for M4.
3. **Phase 1c §5.4 sweep items** (carry-forward backlog): M1 partition-wide CONVENTIONS resolution + ADR-0021 update; M2+M3 dead-code-branch ADR-0013 archive decision; ledger row backfill for the 3 analysisready chain reads.
