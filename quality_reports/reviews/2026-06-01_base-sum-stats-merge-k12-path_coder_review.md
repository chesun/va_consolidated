# base_sum_stats_tab.do (merge_k12 path fix) Review — coder

**Date:** 2026-06-01
**Reviewer:** coder-critic
**Target:** do/share/base_sum_stats_tab.do (L420/L425 relative-path repoint, Phase 1b bug-fix)
**Score:** 92/100
**Mode:** Full (single-line bug-fix; Execution severity)
**Status:** Active

---

## Verdict: PASS (commit allowed; >= 80 hard gate cleared)

One-line fix repointing a bare-relative `do do_files/merge_k12_postsecondary.doh enr_only` to the
absolute `$vaprojdir/do_files/...` form, matching the same file's first-block call. Correct,
minimal, well-commented, and traceable. Cannot run on Scribe (air-gapped) — empirical pass/fail
is the next Scribe run, an honest and disclosed limit.

---

## Code-Strategy Alignment: MATCH

The fix matches the recorded diagnosis (verification-ledger row 176,
`diagnosis:merge-k12-relative-path-r601`, `DIAGNOSED`): r(601) at the kitchen-sink-sample block
because the relocation removed the predecessor's `cd $vaprojdir` (header L44/L83) but left one
relative `do_files/...` reference behind. The fix is exactly the prescribed change.

## Sanity Checks: PASS (static — cannot execute)

## Robustness: N/A (single-line path fix; no estimation touched)

---

## Verification of the five required checks

### 1. Path equivalence / correctness — PASS

- **L215 (first block, create_sample==1):** `do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only` — canonical absolute form. Confirmed.
- **L425 (second block, kitchen-sink-sample, post-fix):** `do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only` — now matches L215 character-for-character (same global, same path, same `enr_only` arg). Confirmed.
- **settings.do globals:**
  - `do/settings.do:128` — `global vaprojdir "/home/research/ca_ed_lab/projects/common_core_va"`
  - `do/settings.do:124` — `global matt_files_dir "/home/research/ca_ed_lab/projects/common_core_va/do_files"`
  - Therefore `$vaprojdir/do_files/` == `$matt_files_dir` == `.../common_core_va/do_files`. Both forms resolve to the same real file — Matt Naven's untouched `merge_k12_postsecondary.doh` per ADR-0017. Confirmed via grep on settings.do.

The fix resolves the same physical file the working first-block call resolves. No ambiguity.

### 2. Only change is path (+ comment) — PASS

Diff adds: (a) the repointed `$vaprojdir` prefix on L425, and (b) a 5-line dated `//`-comment block (L420-424) explaining the relocation-induced cause. The `enr_only` argument is unchanged. No other edits. This matches the recorder's `no-logic-change` residue (ledger row 177): "Repointed L420 ... ; no other bare-relative reads remain."

### 3. No other relative-path landmines in this file — PASS (none remain)

Grepped every `do` / `include` / `use` / `run` / `using` statement in the file. Findings:

| Line | Statement | Form | Verdict |
|------|-----------|------|---------|
| 120, 121, 240, 248 | `include $consolidated_dir/...` | `$global` | OK |
| 155, 163, 175, 194, 198, 202 | `using \`k12_test_scores'/...` etc. | backtick-local | OK — locals resolve to `$vaprojdir/...` absolute (macros_va.doh:107/109/110) |
| 156, 273, 278, 300+ | `$datadir_clean/...`, `$estimates_dir/...` | `$global` | OK |
| 215 | `do $vaprojdir/do_files/merge_k12_postsecondary.doh` | `$global` | OK (was already correct) |
| 238 | `use ... using \`va_dataset', clear` | tempfile local | OK |
| 403 | `use $vaprojdir/data/va_samples_v1/score_las.dta` | `$global` | OK (legacy read — see check 5) |
| 409, 417, 435, 405-406 | inside `/* ... */` block (L405-417, L429-435) | commented out | inert |
| 425 | `do $vaprojdir/do_files/merge_k12_postsecondary.doh` | `$global` | OK (this fix) |

I verified `macros_va.doh:107/109/110` define `k12_test_scores`, `k12_public_schools`,
`k12_test_scores_public` as `"$vaprojdir/data/..."` absolutes — so the backtick-local `using`
statements are not bare-relative and will not r(601) on Scribe. Note these only execute in the
`create_sample==1` rebuild branch (gated by the 2026-06-01 cache guard, ledger row 179). **L420
was the only remaining bare-relative landmine. Confirmed.**

### 4. Sandbox / ADR-0021 — PASS (it's a read, not a write)

`do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only` *executes* (reads) Matt's helper —
a LEGACY READ, which ADR-0021 permits (only WRITES must target CANONICAL globals). The fix
introduces no `save`/`export`/`graph export`/`esttab using`/`outreg2 using`/`log using`. Confirmed
read-only.

### 5. Hazards — PASS

- **Brace balance:** `{` count == `}` count == 9 (matches recorder residue, ledger rows 177/179). Balanced.
- **`/* */` balance:** `/*` count == `*/` count == 25 (matches recorder residue). Balanced. The added comment is a `//`-line comment, not a block comment — does not perturb the count.
- **No `*/`-glob in the added comment:** the comment uses no path-glob `*`; the only `*/`-adjacent token is the literal `cd $vaprojdir` reference written in prose. No Variant-8 over-flatten artifact, no path-glob `*` inside the comment. Clean.

---

## L403 legacy-read note (out of scope — flagged for follow-up)

L403 `use $vaprojdir/data/va_samples_v1/score_las.dta, clear` is a LEGACY read of sample data the
header (L52) explicitly declares "kept LEGACY ... out of Step 10 scope." The canonical producer
`create_score_samples.do:373` (per the task brief) saves `score_las` to `$datadir_clean`. So the
consolidated repo has *two* potential homes for `score_las`: the legacy `$vaprojdir/data/va_samples_v1/`
copy (read here) and the canonical `$datadir_clean/...` copy (the chain producer). This is a latent
**provenance-divergence** risk: if the two ever drift, this script silently reads the stale legacy
copy. It read OK this run (legacy file present on Scribe), so it is not a blocker — but it is a real
follow-up worth an ADR/TODO once the va_samples_v1 relocation reaches Step-10 scope. **Out of scope
for this fix; do not require fixing here.** My take: yes, worth a tracked follow-up — the
inconsistency is the same class as the base_nodrop legacy-cache issue (ledger row 178) that already
bit this file once; consolidating the score sample reads onto `$datadir_clean` would close it.

---

## Compliance Evidence (from .claude/state/verification-ledger.md)

- do/share/base_sum_stats_tab.do | diagnosis:merge-k12-relative-path-r601 | 2026-06-01T13:00Z | hash 06419f8970ef | DIAGNOSED | confirms the cause exactly (L420 relative; missing cd; L215 correct)
- do/share/base_sum_stats_tab.do | no-logic-change | 2026-06-01T13:00Z | hash 06419f8970ef | UNVERIFIED | residue: repointed L420; brace 9=9; /* */ 25=25; no other bare-relative; L403 legacy-read note; end-to-end unrun (Scribe-only)
- do/share/base_sum_stats_tab.do | mkdir-coverage | 2026-06-01T02:30Z | hash a3c3e6ee6f3b | PASS (prior unrelated edit)

### Evidence-gating adjudication (Tier-1 no-logic-change gate)

The `no-logic-change` row (177) is `UNVERIFIED`. Per the binding Tier-1 protocol, I do **not** issue
a blanket clean-refactor `PASS` verdict on the recorder's word alone. I manually inspected the
residue: it is a path swap (relative -> canonical absolute, matching the working L215 sibling) plus
an explanatory `//`-comment plus the "end-to-end unrun" caveat. That is path/scaffold refactoring,
**not** substantive logic change — so I do **not** escalate to `FAIL`. The `UNVERIFIED` is driven
solely by the air-gapped cannot-run constraint, which is honest and unavoidable here. My commit
verdict (PASS) rests on the static evidence above (path equivalence, balance, read-only,
no-other-landmines), with the empirical confirmation deferred to the next Scribe run.

---

## Score Breakdown

- Starting: 100
- Air-gapped: empirical r(601)-resolution unverifiable until next Scribe run (the fix is statically correct and matches the working L215 sibling, so this is a deferred-confirmation deduction, not a defect): -3
- L403 latent legacy/canonical provenance divergence present in the file (out of scope for this fix, not introduced by it; noted, not penalized as a defect of the change): -5 advisory, applied as -5 (latent inconsistency the successor should track)
- **Final: 92/100**

(No deduction for the Tier-1 `UNVERIFIED` row: residue manually confirmed as path/scaffold-only, not substantive logic change. No derive-don't-guess deductions: every referenced global traced to settings.do. No hazard deductions: brace and comment balance confirmed.)

## Escalation Status: None (round 1, PASS)
