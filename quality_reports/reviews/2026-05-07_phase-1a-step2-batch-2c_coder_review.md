# Phase 1a §3.3 Step 2 Batch 2c Review — coder-critic
**Date:** 2026-05-07
**Reviewer:** coder-critic
**Target:** Phase 1a §3.3 step 2 batch 2c (4 merge helpers relocated + 3 batch 2b files: bugfix broken relative-path includes + LEGACY repointing)
**Score:** 95/100
**Status:** Active
**Mode:** Full (Phase 1 commit gate per `.claude/rules/phase-1-review.md`)

---

## Verdict

**PASS — clears 80/100 hard gate.** All 5 specific concerns verified clean. Bugfix is complete; relocations are sandbox-clean; pure-fragment vs do-script header distinction is correctly made; macro-trace on `merge_va_smp_acs.doh` confirmed against in-repo `do/va/helpers/macros_va.doh`. One Minor finding (-3) on a stylistic oversight; one Minor finding (-2) on header-attribution edge case.

---

## Concern-by-concern verification

### Concern 1 — Bugfix completeness for batch 2b's broken relative includes

**PASS.** `grep -nE '^[ \t]*(include|do)[ \t]+do/' do/samples/{touse_va,create_score_samples,create_out_samples}.do` returned ZERO matches. All include sites in the three batch 2b files now use absolute paths:

- `touse_va.do` L173 `include $consolidated_dir/do/va/helpers/macros_va.doh`; L256 `include $consolidated_dir/do/samples/create_diff_school_prop.doh`; L261 `include $consolidated_dir/do/samples/create_prior_scores.doh` (DEAD INCLUDE flagged in header L82, L89-101).
- `create_score_samples.do` L188 macros_va; L199 create_va_sample.doh; L206 create_va_g11_sample_`version'.doh; L212 merge_lag2_ela.doh; L243 merge_loscore.doh; L260, L302 `do merge_va_smp_acs.doh`; L285, L326, L345, L366 merge_sib.doh — all `$consolidated_dir/do/...`.
- `create_out_samples.do` L172 macros_va; L184 create_va_sample.doh; L198 create_va_g11_out_sample_`version'.doh; L204 merge_lag2_ela.doh; L223 merge_loscore.doh; L238, L273 `do merge_va_smp_acs.doh`; L259, L295, L313, L333 merge_sib.doh — all `$consolidated_dir/do/...`.

Critical hazard correctly mitigated: the `cd $vaprojdir` at L152/L169/L153 of the three files no longer breaks any consolidated includes because they all use absolute `$consolidated_dir`-prefixed paths. The cd-restore at L334/L396/L365 (`cd "$consolidated_dir"`) confirmed.

### Concern 2 — LEGACY-include macro-trace on `merge_va_smp_acs.doh`

**PASS.** Read the consolidated `do/va/helpers/macros_va.doh` and confirmed the four locals merge_va_smp_acs.doh consumes are all defined:

- `census_grade` — defined L239-241 (= 6).
- `census_controls` — defined L243-248 (eth_*, educ_*, pov_fam_child_lt18_pct, inc_median_hh).
- `` `va_type'_min_year `` and `` `va_type'_max_year `` — `test_score_min_year`/`max_year` (L114-119), `outcome_min_year`/`max_year` (L138-143).

The L141 include line in the relocated file (`include $consolidated_dir/do/va/helpers/macros_va.doh`) is sound; its L77-79 RELOCATION HISTORY entry correctly records the repointing from predecessor `$vaprojdir/do_files/sbac/macros_va.doh`.

### Concern 3 — Sandbox-write check on 4 new helpers

**PASS.** `grep -nE 'save|export|outsheet|esttab using|graph export|outreg2 using|texsave' do/samples/merge_*.doh` returned only:

- Header-text mentions (merge_loscore L34; merge_sib L37; merge_lag2_ela L31; merge_va_smp_acs L22, L56) — not actual code.
- Tempfile saves in merge_va_smp_acs.doh (L150 `save \`census_geocode'`, L166 `save \`lagged_address'`, L173 `save \`address_id'`, L179 `save \`lagged_acs'`) — exempt per established convention (each preceded by `tempfile <name>` declaration).

Zero persistent-disk LEGACY writes; zero CANONICAL writes from the helpers themselves (parent files do the persistent saving). Sandbox-trivially clean.

### Concern 4 — Pure-fragment vs do-script distinction in headers

**PASS.** All four headers correctly disambiguate invocation form:

- `merge_loscore.doh` L19: "Pure fragment — runs only inside parent's log scope; no own log." L33-35 ROLE: "Pure fragment; no save / export / log."
- `merge_sib.doh` L17: "Pure fragment — runs only inside parent's log scope; no own log." L36-37 ROLE: same.
- `merge_lag2_ela.doh` L16: same; L31 ROLE: same.
- `merge_va_smp_acs.doh` L7-9: "called via `do' (not `include') with 5 positional arguments — it runs in its OWN scope and re-includes macros_va.doh to set up the locals it needs." L24-29 ARGUMENTS section enumerates the 5 positional args. L66-69 ROLE: "writes ONLY to Stata tempfiles (session-scoped, auto-cleaned, exempt per established convention). No persistent on-disk writes."

The do-script vs pure-fragment distinction is structurally clean and well-documented. The pure fragments correctly do NOT appear in `do/main.do` (they're transitively invoked from create_*.do); the do-script `merge_va_smp_acs.doh` likewise correctly does NOT appear in main.do because it's invoked from create_*.do as a callable, not from the master pipeline directly.

### Concern 5 — Repointing completeness in create_*_samples.do

**PASS.** `grep -nE '\$vaprojdir/do_files/sbac/(merge_|create_va|macros)' do/samples/create_*.do` returned ZERO body matches. All matches confined to header doc-comments (L41/L43/L45/L47, L80, L86, L88, L95, L97 of create_score_samples.do; L32-35, L64, L78-80 of create_out_samples.do — these are RELOCATION HISTORY records preserving the original predecessor paths for traceability, expected and correct per the established `5de34a7` precedent).

The single intentional KEPT-LEGACY include (`$vaprojdir/do_files/k12_postsec_distance/merge_k12_postsec_dist.doh` at create_score_samples.do:209 and create_out_samples.do:201) is correctly preserved per Step 9 deferral. Both flagged in header (create_score_samples.do L92, create_out_samples.do — header records the reference).

---

## Cross-cutting verification

### No hardcoded absolute paths (Stata convention)

`grep -nE '"/Users|"/home|"C:\\\\' do/samples/{merge_*.doh,touse_va.do,create_score_samples.do,create_out_samples.do}` → 0 matches. PASS.

### Macros bound in `do/settings.do` (derive-don't-guess)

All globals referenced in body code resolve to `do/settings.do`:

- `$consolidated_dir` (L92), `$logdir` (L99), `$datadir_clean` (L102), `$matt_files_dir` (L116), `$vaprojdir` (L120), `$caschls_projdir` (L128), `$distance_dtadir` (L145).

### CWD-restore + log-handling hygiene

All three modified files correctly:

- `cap log close _all` at top (touse_va.do L122; create_score_samples.do/create_out_samples.do reopen `log using` at the top of their gated block).
- `log using "$logdir/<name>.smcl", replace text` (touse_va L154; score L174; out L158).
- `cap log close` + `cap translate "$logdir/<name>.smcl" "$logdir/<name>.log"` at end (touse_va L330-331; score L390-392; out L360-361).
- `cd "$consolidated_dir"` at end (touse_va L334; score L396; out L365) — restores CWD for downstream main.do invocations.

### main.do wiring (per ADR-0021 description convention checklist item b)

`grep` of main.do confirms all 3 do-script callers are wired with one-liner descriptions:

- L155 `do do/samples/touse_va.do` // tag the VA-eligible analysis sample (touse_g11_<subject>/<outcome> markers; writes `$datadir_clean/sbac/va_samples.dta`)
- L158 `do do/samples/create_score_samples.do` // build 7 test-score VA samples × 2 prior-score versions (v1/v2 per ADR-0009); writes `$datadir_clean/va_samples_v[12]/score_*.dta`
- L159 `do do/samples/create_out_samples.do` // build 7 outcome VA samples × 2 prior-score versions; writes `$datadir_clean/va_samples_v[12]/out_*.dta`

Pure fragments (merge_loscore/sib/lag2_ela) and do-script merge_va_smp_acs.doh correctly omitted from main.do (transitively included from create_*.do).

---

## Deductions

| Severity | Issue | Deduction |
|---|---|---|
| Minor | Header attribution edge case in `merge_loscore.doh` L46-47: "Predecessor file lacked an authorship header. Per file role and adjacent create_score_samples.do (Christina-authored, 2022-08-15), attributed to Christina (Che) Sun." This is a reasonable inference given file-role context, but the attribution is *derived* not *recorded*. Future readers should be able to distinguish "preserved from predecessor" vs "derived attribution". The note in the file makes this clear, so the issue is minor — but the same pattern in `merge_sib.doh` L52-53 says "Authorship attributed to Christina via adjacent file conventions" without explicitly flagging the inference is derived. Recommend (non-blocking) tightening to a uniform convention: e.g., "Authorship: derived from adjacent file conventions (Christina (Che) Sun); no explicit attribution in predecessor source." | -3 |
| Minor | `merge_sib.doh` L36-42 ROLE describes `sibling_out_xwalk` resolution: "this LEGACY-classed read is on a CANONICAL output of the relocated siblingoutxwalk.do — the local in macros_va.doh still resolves to the caschls predecessor location until a future relocation routes it to `$datadir_clean`." This is accurate but introduces a subtle inconsistency: macros_va.doh L110 binds `local sibling_out_xwalk "$caschls_projdir/dta/siblingxwalk/sibling_out_xwalk"`. The crosswalk *is* CANONICAL (built by the relocated `do/sibling_xwalk/siblingoutxwalk.do` per ADR-0005), but its destination is `$caschls_projdir/...` (LEGACY prefix). This labeling tension is not new in this batch — it's inherited from the macros_va relocation 2026-04-30 — but flagging it here so it is on record. No action required for batch 2c; consider opening a TODO to revisit when sibling_out_xwalk's write-target is repointed to `$datadir_clean`. | -2 |

**Total deductions:** -5

---

## Score Breakdown

- Starting: 100
- Minor findings (header-attribution edge, sibling_out_xwalk LEGACY/CANONICAL labeling): -5
- **Final: 95/100**

---

## Compliance Evidence (from `.claude/state/verification-ledger.md`)

The 3 modified batch 2b files have ledger rows from 2026-05-07T20:30Z covering `no-hardcoded-paths`, `adr-0021-sandbox-write`, and `legacy-include-macro-trace`. The macro-trace rows for `create_score_samples.do` and `create_out_samples.do` are marked `ASSUMED` (out-of-repo merge helpers). **This batch 2c relocates those helpers in-repo, which means those `ASSUMED` rows are now updateable to `PASS`.** Recommend (post-merge) updating the ledger:

```
| do/samples/create_score_samples.do | legacy-include-macro-trace | <new-timestamp> | <new-hash> | PASS | merge_loscore/sib/lag2_ela/va_smp_acs now in-repo at do/samples/; macros_va.doh trace verified against do/va/helpers/macros_va.doh L114-119, L138-143, L239, L243 |
```

Same for `create_out_samples.do`. The 4 new merge helpers also need fresh ledger rows: recommend `no-hardcoded-paths` (PASS, 0 matches), `adr-0021-sandbox-write` (PASS, only tempfile saves in merge_va_smp_acs.doh; 3 pure fragments have zero saves).

(This is an audit-trail recommendation; not blocking.)

---

## Escalation Status

**None — Round 1 PASS.** No blocking findings. No escalation triggered.

---

## Phase 1 Commit Footer Recommendation

```
coder-critic: round 1 — PASS (95/100); 2 Minor findings noted in
quality_reports/reviews/2026-05-07_phase-1a-step2-batch-2c_coder_review.md
(header attribution convention, sibling_out_xwalk LEGACY/CANONICAL labeling tension);
neither blocks; no fixes required for this batch.
```

---

## Summary

Batch 2c cleanly closes Step 2 of Phase 1a §3.3:

- **Bugfix:** post-`cd $vaprojdir` consolidated includes (3 files × 3 sites = 9 sites) all converted to `$consolidated_dir/do/...` absolute paths. Zero remaining broken-relative-include hazards.
- **Relocations:** 4 merge helpers (3 pure fragments + 1 do-script) successfully relocated with full ADR-0021 description-convention compliance. Sandbox-clean: zero persistent-disk LEGACY writes; only tempfile saves in the do-script (exempt).
- **Repointing:** 16 LEGACY refs in batch 2b create_*.do (8 each in create_score_samples.do and create_out_samples.do) successfully converted to `$consolidated_dir/do/(samples|va/helpers)/...`. Single intentional KEPT-LEGACY (k12_postsec_distance) preserved per Step 9 deferral and flagged in headers.
- **Header quality:** pure-fragment vs do-script distinction structurally clear in all 4 new helpers. Macro-trace on `merge_va_smp_acs.doh`'s `macros_va.doh` include verified against in-repo `do/va/helpers/macros_va.doh` (L114-119 year-range; L239 census_grade; L243 census_controls).

After this batch, Phase 1a §3.3 progress is 21 of ~150 files relocated; Phase 2 wiring in main.do is complete except for the deferred `merge_k12_postsec_dist.doh` (Step 9). Cleared for commit.
