# va_spec_fb_tab_all.do path-root fix Review — coder-critic

**Date:** 2026-06-01
**Reviewer:** coder-critic
**Target:** do/share/va_spec_fb_tab_all.do (+ decisions/0024_tables-vs-estimates-dir-for-regsave-summaries.md)
**Score:** 88/100
**Status:** Active
**Mode:** Full (Phase 1b bug-fix; Execution severity)

---

## Verdict: PASS (88/100) — gate 80; clears.

Air-gapped caveat: Scribe-only, the consolidated tree cannot be run here. All findings are
static (diff inspection, grep across producers/consumers, ADR cross-read). The r(601) repro and
the post-fix success are NOT verified by execution — only by path-consistency reasoning. Final
pass/fail is the next M4 run.

## Code-Strategy Alignment: MATCH
The fix implements exactly what ADR-0024 prescribes: repoint the two consumer reads
`$estimates_dir -> $tables_dir`, correct the header note, leave the 4 producers and va_var_explain*
untouched. No deviation.

## Sanity Checks: PASS
Direction is correct and the fix is the minimal one (1 file, 2 executable lines). Evidence below.

## Robustness: Complete (for a path-root bug fix — N/A to econometric robustness)

---

## Evidence by requested check

### (1) Direction correctness — CONFIRMED, fix-the-consumer is the correct minimal direction
All four producers write AND read-back from `$tables_dir`:
- `do/va/va_out_fb_test_tab.do`: regsave L185/194/218/225 → `$tables_dir/.../fb_test/`; read-back `use` L238 → `$tables_dir`.
- `do/va/va_score_fb_test_tab.do`: regsave L193/202/225/232 → `$tables_dir/.../fb_test/`; read-back `use` L243 → `$tables_dir`.
- `do/va/va_out_spec_test_tab.do`: regsave L224/233/250/259 → `$tables_dir/.../spec_test/`; read-back `use` L265 → `$tables_dir`.
- `do/va/va_score_spec_test_tab.do`: regsave L235/243/268/277 → `$tables_dir/.../spec_test/`; read-back `use` L286 → `$tables_dir`.

The consumer's own `cap mkdir` block (L100–114) creates only `$tables_dir/...` paths — it never
creates the `$estimates_dir/.../fb_test` or `/spec_test` dirs it was reading from, which is direct
internal evidence `$tables_dir` was the intended root all along (a read from a never-created dir is
exactly the r(601)). Aligning the 4 producers to the wrong header note would be the larger,
semantically-backwards fix. Direction is right.

### (2) Both reads repointed — CONFIRMED
- fb_test read now at L154: `use $tables_dir/va_cfr_all_`version'/fb_test/fb_`va_outcome'_all.dta, clear` ✓
- spec_test read now at L217: `use $tables_dir/va_cfr_all_`version'/spec_test/spec_`va_outcome'_all.dta, clear` ✓
- Zero remaining *executable* `$estimates_dir/...{fb_test,spec_test}.../*_all.dta` reads. The only
  surviving `$estimates_dir` + `fb_test`/`spec_test` + `_all.dta` tokens (L24, L25, L48, L51) are all
  inside the `/* ... */` header block — non-executable. See Finding A (Minor) for the L24–25 residue.

(Note: the task brief said reads "now ~L147/210"; in the committed file the actual `use` statements
land at L154 and L217. The L147/210 figures are the comment-block lead-ins, not the `use` lines.
Cosmetic discrepancy in the brief, not in the code.)

### (3) No logic change beyond the 2 paths + comments — CONFIRMED, with one doc residue
The functional delta is exactly: two `use` paths flipped `$estimates_dir -> $tables_dir`, plus
explanatory `//` comments at L149–153 and L215–216, plus the corrected RELOCATION note (L44–51).
No reshape/keep/gen/regsave/texsave logic altered. Ledger row
`do/share/va_spec_fb_tab_all.do | no-logic-change` = **UNVERIFIED** (residue = the 2 path repoints +
comments) — this is the *intended* change, not unintended logic drift, so I adjudicate it as
UNVERIFIED-but-correct rather than FAIL (see Compliance Evidence). One residue worth flagging:
**the INPUTS header block (L24–25) still lists the `_all.dta` files as `$estimates_dir/... (LEGACY)`**,
now contradicting both the corrected RELOCATION note (L44–51) and the executable reads. Minor doc
inconsistency (Finding A).

### (4) The va_var_explain exception — AGREE, do NOT change
`va_var_explain.do` is self-contained on `$estimates_dir`: it `regsave`-writes `reg_va_<outcome>_va_both_all.dta`
at L237/249 to `$estimates_dir/.../reg_out_va/` and reads it back at L259 from the same root —
producer == consumer, internally consistent, no r(601) risk. `va_var_explain_tab.do` reads the same
file at L104 from `$estimates_dir`, matching `va_var_explain.do`'s write root. So the producer/consumer
pair agrees; there is no mismatch bug. ADR-0024's open-question framing is accurate: relocating these
would be golden-master churn for zero functional gain. **Agree it should not be changed.** (Strictly,
`reg_va_*_all.dta` is also a `regsave` summary `.dta`, so by ADR-0024's artifact-class rule-of-thumb it
*would* belong under `$tables_dir`; the ADR correctly scopes its rule to new/relocated code and
producer/consumer *disagreements*, explicitly not mandating relocation of internally-consistent cases.
That carve-out is reasonable and stated.)

### (5) ADR supersession framing — HONEST, confirmed
No prior ADR decided `$estimates_dir` for these files:
- ADR-0021 (`0021_main-settings-relocation-and-self-contained-sandbox.md`) lists `$estimates_dir` AND
  `$consolidated_dir/tables/` both as CANONICAL read/write roots (L37) but does not adjudicate *which*
  applies to a `regsave` summary `.dta` in the `fb_test/`/`spec_test/` subtree. Gap, as ADR-0024 claims.
- ADR-0012 (`0012_tab-csvs-local-review-only.md`) — zero mention of these files, the `_all.dta` class,
  or the `$estimates_dir`-vs-`$tables_dir` split. Adjacent, not superseding.
The only "decision" that placed these under `$estimates_dir` was the file-header relocation note —
never ADR-ratified. ADR-0024's "Refines #0021, supersedes the file-header note, no prior ADR superseded"
framing is therefore accurate and honest. (ADR filenames differ slightly from the brief's titles:
0012 = `tab-csvs-local-review-only`, 0021 = `main-settings-relocation-and-self-contained-sandbox`;
content matches.)

### (6) Hazards
- `/* */` balance: `grep -c '/\*'` = 5, `grep -c '\*/'` = 5 — **balanced**. (The corrected note at
  L44–51 ends with a literal `$estimates_dir.)` followed by the original block close; no stray glob.)
- No `*/`-glob in the added comments: the new `//` lines (L149–153, L215–216) and the rewritten block
  note use `<x>`/literal paths; no `*` path-glob introduced. ✓
- Brace balance: the `foreach version` / `foreach va_outcome` / `foreach var of varlist` / `program define`
  blocks all close (L139→L339, L144→L291, program L127→L129). Unchanged by this diff. ✓

---

## Score Breakdown
- Starting: 100
- Finding A (Minor) — stale INPUTS header (L24–25 still says `$estimates_dir ... (LEGACY)` for the
  `_all.dta` files, contradicting the fix and the corrected RELOCATION note): poor comment quality /
  internal doc inconsistency: **−5**
- Finding B (Minor) — `no-logic-change` ledger row is `UNVERIFIED` (correctly, since residue is the
  intended path change); end-to-end unrun is honestly disclosed as ASSUMED-by-air-gap, but the fix's
  correctness rests on static reasoning only. Per evidence-gating, an UNVERIFIED no-logic-change row
  bars a clean-refactor PASS *verdict*; here the change is an ADR-backed bug fix whose residue IS the
  intent, so I do not apply the −25 clean-refactor deduction. Small deduction for the residual
  not-executed risk: **−5**
- Pre-existing (not introduced here, NOT deducted): producers use a literal `$vaprojdir/estimates/...`
  predecessor path in the predicted_prior_score branches (e.g. va_out_fb_test_tab.do L216/223) — a
  separate latent inconsistency, out of scope for this diff; flagged for awareness only.
- **Final: 88/100**

## Compliance Evidence (from .claude/state/verification-ledger.md)
- do/share/va_spec_fb_tab_all.do | diagnosis:fb-spec-all-dta-root-mismatch-r601 | 2026-06-01T14:30Z | cb11ad61ec0a | DIAGNOSED | r601 root-mismatch; producers→$tables_dir, consumer read $estimates_dir
- do/share/va_spec_fb_tab_all.do | no-logic-change | 2026-06-01T14:30Z | cb11ad61ec0a | UNVERIFIED | residue = 2 path repoints + comments (the intended change); /* */ 5=5; Scribe-only unrun
- File hash cb11ad61ec0a is current (rows written same session as the edit; no further edit since). Both rows fresh.

## Recommendations (not implemented — critic does not edit source)
1. Update the INPUTS header block L24–25: change `$estimates_dir/.../fb_test/fb_<outcome>_all.dta (LEGACY)`
   and the spec_test line to `$tables_dir/...` so the header matches the executable reads (Finding A).
2. On the next Scribe M4 run, confirm Phase 6 `va_spec_fb_tab_all.do` completes past former L142/203
   without r(601), and that the `texsave` outputs land (the only verification air-gap closes there).

## Escalation Status: None (PASS round 1)
