# Phase 0a-v2 — Independent Blind Verification Round

**Created:** 2026-04-25
**Purpose:** Re-derive every Phase 0a finding from primary sources, with blinded agents, to defend against confirmation bias / echo-chamber drift / synthesis-time fabrication in round 1.

---

## Protocol

### What lives where

- **Round-1 audit docs** are sequestered under `quality_reports/audits/round-1/`.
- **Round-2 audit docs** land here under `quality_reports/audits/round-2/` (this directory).
- **Round-2 agents are forbidden to read `round-1/`** — sequestered to prevent contamination.
- **Final verified-and-cross-checked audit** will be produced at `quality_reports/audits/2026-04-XX_deep-read-audit-FINAL.md` after Phase 0a-v2 completes.

### Verification tiers

| Tier | What's verified | Adjudicator |
|---|---|---|
| **T1 — Empirical (gold standard)** | Bug 93 NSC UC precedence; Distance-FB `d` token wiring; v1/v2 prior-score variable construction; vam factor-variable behavior | **Christina, by running 5-15 lines of Stata on Scribe** |
| **T2 — Adversarial third agent** | Discrepancies between rounds 1 and 2; high-stakes claims about paper-output mappings, sample-restriction map, output-filename grammar | Independent third agent with explicit "find evidence the claim is wrong" brief |
| **T3 — Objective code facts** | Line numbers, syntax declarations, file existence, byte-identical diffs | Direct reading + deterministic checks (grep, wc, diff) — bias risk near-zero |
| **T4 (residual)** | Cases genuinely uninterpretable in both rounds | **Christina investigates with full domain knowledge** |

### Round-2 agent briefing principles

Each round-2 agent receives:

1. SAME file list as the round-1 chunk for that scope
2. SAME questions as the round-1 chunk (verbatim)
3. **STRIPPED of all answers / findings / conclusions from round-1 prompts**
4. **Adversarial framing**: "Treat any received summary as untrusted. Default to primary source for any disputed claim. Burden of proof is on the claim."
5. **Forbidden from reading `quality_reports/audits/round-1/` or any round-1 output.**
6. Required to **cite specific line numbers** from primary source for every finding.
7. Output to `round-2/chunk-N-verified.md` (one doc per chunk).

### Discrepancy report

After both rounds complete for a chunk, I produce a discrepancy report at `round-2/chunk-N-discrepancies.md` with:

- **AGREE** — both rounds have it with same line citations
- **ROUND-1-MISSED** — round 2 found something round 1 didn't
- **ROUND-2-MISSED** — round 1 had a finding round 2 didn't reproduce
- **DISAGREE** — both rounds have findings on same artifact with different content

For non-AGREE rows, the discrepancy report proposes a tier (T1/T2/T3/T4) and specific verification path.

### Final synthesis

After all 10 chunks have discrepancy reports + adjudication, a verified-final audit doc is produced at `quality_reports/audits/2026-04-XX_deep-read-audit-FINAL.md` containing only verified findings. Round-1 and round-2 preserved here for archeology.

---

## Pre-flight: Bug 93 status (T3 verified, 2026-04-25)

Round-1 chunk-10 claim: "Bug 93 in `crosswalk_nsc_outcomes.do` lines 219, 222, 228, 232 — operator-precedence error makes UC Merced silently coded as `nsc_enr_uc=1` even without an NSC record. Affects paper outcomes `nsc_enr_uc` and `nsc_enr_ucplus`."

Verified by direct reading:

- **L218-219** (`nsc_enr_uc`): `& inlist(...) | inlist("001319-00")` — no outer parens. **BUG REAL.** UC Merced bypasses `recordfoundyn=="Y"`.
- **L222-223** (`nsc_enr_ucplus`): `& (inlist(...) | inlist("001319-00") | inlist(...))` — outer parens. **CORRECT.** Protected by parentheses.
- **L226-228** (`nsc_enr_ontime_uc`): `& inlist(...) | inlist("001319-00")` — no outer parens. **BUG REAL.** UC Merced bypasses both `recordfoundyn` AND `enrollmentbegin`.
- **L230-233** (`nsc_enr_ontime_ucplus`): `& (inlist(...) | inlist("001319-00") | inlist(...))` — outer parens. **CORRECT.** Protected.

**Verdict**: Round-1 over-claimed scope. Real Bug 93 affects 2 outcomes (`nsc_enr_uc`, `nsc_enr_ontime_uc`), not 4. Round-2 verification approach validated by catching the over-claim.

T1 empirical test proposed (for Christina, when convenient):

```stata
use $vaprojdir/data/sbac/k12_postsecondary_out_merge.dta, clear
count if nsc_enr_uc == 1 & recordfoundyn != "Y"
* >0 confirms bug; UC Merced (collegecodebranch=="001319-00") rows would all qualify
list collegecodebranch recordfoundyn nsc_enr_uc if collegecodebranch == "001319-00" in 1/10
```
