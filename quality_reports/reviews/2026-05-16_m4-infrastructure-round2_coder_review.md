# M4 Golden-Master Infrastructure Review — coder-critic (ROUND 2)
**Date:** 2026-05-16
**Reviewer:** coder-critic
**Target:** `do/check/m4_golden_master.do` lines 247-260 (M3 revert) + `.claude/rules/air-gapped-workflow.md` (rule clarification)
**Score:** 85/100
**Status:** Active
**Supersedes:** `quality_reports/reviews/2026-05-16_m4-infrastructure_coder_review.md`

---

## Verdict

**PASS at the 80/100 hard gate.** Round 1 scored 82/100 with M3 (-3) flagged as an air-gap leak. Christina has clarified — and the rule has been tightened — that **derived summaries (coefficient deltas, SE deltas, counts, magnitudes) are paper-class content and exportable**; only raw row-level data, identifiers, and small-cell tabs are air-gapped. The M3 fix has been reverted, restoring `max|db|` / `max|dSE|` magnitudes to both FAIL and PASS `details` strings. Under the corrected interpretation, M3 is no longer a finding — the script's prior behavior was correct, and the round-1 deduction was a misread of the rule's intent.

Net score change: **82 → 85** (M3 -3 removed). No new findings introduced by the revert; the rule update is cleanly written and renders fine.

## Compliance evidence

Round 1's ledger discussion stands (no changes to globals, paths, or sandbox-write discipline). The two new artifacts under review:

- `do/check/m4_golden_master.do` lines 247-260 — `cap_compare_ster` subroutine tail. PASS line 254 + FAIL line 259 both emit `max|db|=...  max|dSE|=...` in details; the prior 5-line "air-gapped convention" comment is replaced by an accurate 4-line note (lines 247-250) on what the comparison reports.
- `.claude/rules/air-gapped-workflow.md` lines 12-34 — two new sections ("What IS OK to Export" + "What IS Air-Gapped") inserted after "Constraints", with a one-line principle close ("When in doubt, ask: is this derived from data (exportable) or the row-level data itself (air-gapped)? Counts, magnitudes, and estimates are derived." — line 34).

Both edits are read-only-verifiable in this review (the critic does not edit source files).

## Step-by-step verification

### Step 1: Round-1 findings — M3 status

| Finding | Round-1 deduction | Round-2 status |
|---|---|---|
| M1 — `.ster` colname-alignment check missing | -5 | Unchanged; deferred per orchestrator scope (post-smoke) |
| M2 — `cf` row-count rc=503 misclassified READ_ERROR | -5 | Unchanged; deferred post-smoke |
| **M3 — `.ster` diff magnitudes leak into air-gapped export** | **-3** | **DE-FLAGGED.** Under the clarified rule, derived diff magnitudes are paper-class content and explicitly safe to export (air-gapped-workflow.md line 19). The script's restoration of `max|db|` / `max|dSE|` to the FAIL details is correct, not a leak. The PASS-details augmentation (line 254) is a small triage-symmetry improvement — same magnitude format on both branches, no information leak. |
| M4 — README tier-count ambiguity | -2 | Unchanged; deferred |
| M5 — pdftotext byte-strict on benign date drift | -2 | Unchanged; deferred |
| Mi1 — smoke missing csv/xlsx coverage | -1 | Unchanged; deferred |
| Mi2 — `MISSING_BOTH` bucketed as `MISSING_PREDECESSOR` | -1 | Unchanged; deferred |
| Mi3 — CSV re-load per row (performance) | 0 advisory | Unchanged; deferred |

### Step 2: Rule-update review

`.claude/rules/air-gapped-workflow.md` updated sections:

| Check | Status | Evidence |
|---|---|---|
| New "What IS OK to Export" section present | PASS | Lines 12-23; positioned correctly after Constraints (line 11) |
| Categories cover the M4-summary contents | PASS | Line 18 explicitly names "counts" (cell counts, merge rates, number-of-differences from `cf`/`cfout`); line 19 explicitly names "Derived diff magnitudes" with `max|db|` and `max|dSE|` examples; line 22 covers `.smcl`/`.log` files. Every export the M4 runner produces is named. |
| New "What IS Air-Gapped" section present | PASS | Lines 25-33; clear bright lines on raw row-level data, identifiers, small-cell tabs, restricted-access metadata |
| One-line principle close | PASS | Line 34: "When in doubt, ask: is this derived from data (exportable) or the row-level data itself (air-gapped)? Counts, magnitudes, and estimates are derived." |
| Markdown rendering — blank lines before lists | PASS | Blank line precedes each `-` list (lines 13, 26); MacDown-compat rule satisfied |
| No broken cross-references | PASS | No `[link]` references to verify; section is self-contained |
| Bullet-point conventions | PASS | All bullets use `-`; bold leading nouns consistent (`**Raw row-level data**`, `**Identifiers...**`, etc.) |
| Tonal consistency with rest of file | PASS | Imperative + declarative mix matches the existing "Constraints" / "Defensive Code Rules" sections; no AI-prose tells |

Minor observation (not a deduction): the principle close on line 34 is excellent — it's the kind of bright-line test that lets a future reader resolve edge cases ("is a coefficient covariance matrix exportable?" — yes, derived) without re-litigating the rule. Recommend leaving as-is.

### Step 3: Script revert inspection — `do/check/m4_golden_master.do` lines 247-260

| Check | Expected | Actual | Status |
|---|---|---|---|
| Lines 247-250 comment block | Brief, accurate, no anti-leak rationale | "Tolerance per replication-protocol.md §3. Diff magnitudes (max\|db\|, max\|dSE\|) are summary-class quantities and are reported in the `details` string so offline triage can compare against the 0.01 / 0.05 tolerances without re-running on Scribe. Also printed to the log for redundancy." | PASS — accurate, cites the rule, justifies the design |
| Line 251 display | `[ster diag] max\|db\|=...  max\|dSE\|=...` log echo | Present, %7.4f format, redundant with details string (defense in depth) | PASS |
| Line 254 PASS-details | Contains `max\|db\|=<val> max\|dSE\|=<val>` | `"coef and SE within tolerance (max\|db\|=\`:di %7.4f \`max_b_diff'' max\|dSE\|=\`:di %7.4f \`max_se_diff'')"` | PASS — magnitude reported; "within tolerance" phrasing keeps the symmetry with the FAIL branch |
| Line 259 FAIL-details | Contains `max\|db\|=<val> max\|dSE\|=<val>` | `"max\|db\|=\`:di %7.4f \`max_b_diff'' max\|dSE\|=\`:di %7.4f \`max_se_diff''"` | PASS — magnitudes reported |
| Line 260 `end` | Correctly closes `cap_compare_ster` | Present | PASS |
| Adjacent subroutine `cap_compare_tex` (lines 263+) | Unchanged | Lines 263-289 inspected; matches round-1 description (cmp -s, awk numeric-strip fallback) | PASS — no collateral damage |
| No "coef exceeds tolerance" status-string substitute remains | Should be gone | No occurrence; details strings carry actual magnitudes | PASS |
| No prior 5-line "air-gapped convention" comment block remains | Should be gone | Replaced with the 4-line comment on lines 247-250 | PASS |

The revert is surgical: 9 lines of comment + return-details edits, no scope creep into adjacent subroutines. The PASS-branch addition of magnitudes (line 254) is a small augmentation flagged in the round-2 dispatch description; it's a triage-symmetry improvement and reads cleanly.

### Step 4: Other findings re-checked

No re-inspection needed for M1, M2, M4, M5, Mi1, Mi2, Mi3 — those were deferred post-smoke per the prior orchestrator scope decision and the revert does not touch any of them. All remain valid items for the post-smoke follow-up pass.

## Per-deliverable summary (round-2 delta)

### `do/check/m4_golden_master.do` lines 247-260

| Check | Round-1 status | Round-2 status |
|---|---|---|
| Air-gapped summary export hygiene | PARTIAL (M3 -3) | PASS (M3 de-flagged under clarified rule) |
| Tolerance check correctness | PASS | PASS |
| `display` log echo of magnitudes | PASS (informational) | PASS |
| FAIL details string content | Withheld magnitude (post-fix); now restored | PASS — magnitudes present |
| PASS details string content | "within tolerance" + magnitudes | PASS — magnitudes present (small augmentation) |
| Comment block accuracy | Prior 5-line air-gap rationale | 4-line accurate note citing replication-protocol §3 |

### `.claude/rules/air-gapped-workflow.md` (rule update)

| Check | Status |
|---|---|
| Two new sections placed correctly | PASS (after Constraints, before "What Claude Does") |
| Categories listed are exhaustive enough for the M4 use case | PASS (counts, diff magnitudes, estimates, table contents, log content all named) |
| Air-gapped categories are clear | PASS (raw row-level, identifiers, small-cell, restricted metadata) |
| One-line principle close | PASS (line 34) |
| Markdown / MacDown compatibility | PASS (blank lines before lists, no math, no escape-hatch issues) |

## Score breakdown

| Item | Round-1 deduction | Round-2 deduction | Note |
|---|---|---|---|
| Starting score | 100 | 100 | |
| M1 — .ster colname not checked | -5 | -5 | Deferred post-smoke |
| M2 — cf row-count mismatch misclassified | -5 | -5 | Deferred post-smoke |
| M3 — diff magnitudes in air-gapped export | **-3** | **0** | **DE-FLAGGED** under clarified rule |
| M4 — README tier-count ambiguity | -2 | -2 | Deferred post-smoke |
| M5 — pdftotext stream byte-strict | -2 | -2 | Deferred post-smoke |
| Mi1 — smoke missing csv/xlsx | -1 | -1 | Deferred post-smoke |
| Mi2 — MISSING_BOTH bucketed as MISSING_PREDECESSOR | -1 | -1 | Deferred post-smoke |
| Mi3 — performance (CSV re-read per row) | 0 (advisory) | 0 (advisory) | Deferred post-smoke |
| **Final** | **82/100** | **85/100** | **+3 net from M3 de-flag** |

## New findings introduced by the revert

**None.** The script change is confined to 9 lines (a comment block and two return-details strings), all within the `cap_compare_ster` subroutine. No adjacent subroutines touched. No new external entities introduced. No new globals or paths.

The PASS-branch magnitude augmentation (line 254) is a small departure from the round-1 state (which presumably had only "coef and SE within tolerance" without numbers in the PASS details), but it's a clean improvement: symmetric formatting between PASS and FAIL branches makes offline triage easier, and exporting bounded ≤0.01 / ≤0.05 magnitudes is squarely within the clarified rule's "OK to Export" zone.

## Verdict and execution recommendation

**PASS — 85/100, clears the 80/100 hard gate.** The corrected interpretation of the air-gapped rule holds; M3 is correctly de-flagged; the rule update is well-written and prevents recurrence of the same misread. Recommend proceeding to the first Scribe smoke run as originally planned, with M1/M2/M4/M5/Mi1/Mi2 addressed after smoke surfaces execution-time issues.

The rule update (lines 12-34 of `.claude/rules/air-gapped-workflow.md`) is itself a load-bearing improvement to the workflow's governance — future agents reviewing M4-style infrastructure will not repeat the round-1 misread.

## Three Strikes status

**Strike 0 / 3.** Round 2 is a clarification-driven re-score, not a converge-or-escalate cycle. The round-1 deduction was a critic-side rule misread (not a code defect); the revert + rule update is the correct fix path.

## Notes for follow-up

- Round-1 notes on the CSV's 12 known limitations, the `.png` byte-compare tradeoff, and derive-don't-guess / primary-source-first clean-bills all carry forward unchanged.
- The five deferred Majors (M1, M2, M4, M5) plus three Minors (Mi1, Mi2, Mi3) remain on the post-smoke fix list; this round-2 review does not re-litigate any of them.
- If the rule update on `air-gapped-workflow.md` is the first edit of that file in this consolidation pass, consider adding a "see also" cross-reference from `.claude/rules/stata-code-conventions.md` § Table Export or § Figures to point users at the export-vs-air-gap bright lines. (Not a deduction; suggestion only.)
