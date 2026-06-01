# va_score_sib_lag r(111) Debug — coder

**Date:** 2026-05-31
**Reviewer:** claude (debug)
**Target:** `do/va/va_score_sib_lag.do` (+ mirror `do/va/va_out_sib_lag.do`); helpers `do/va/helpers/macros_va.doh`, `do/samples/merge_sib.doh`; log `log/va/va_score_sib_lag.smcl:841-845`
**Status:** Active

## Error

```
VA version: v1
(Test Score VA Sample with Sibling Controls)
variable old1_sib_enr_2year not found
(error in option controls())
r(111);
```

`vam` at `do/va/va_score_sib_lag.do:102` passes `controls(... \`sib_lag1_controls' ...)`. The macro
`sib_lag1_controls` (`do/va/helpers/macros_va.doh:270-273`) expands to `old1_sib_enr_2year old1_sib_enr_4year`.
The loaded sample (`do/va/va_score_sib_lag.do:100`):

```stata
use $datadir_clean/va_samples_v1/score_s if touse_g11_ela==1 & touse_sib_lag==1, clear
```

does **not** contain `old1_sib_enr_2year` → r(111). `sib_lag2_controls` (`old2_sib_enr_2year/_4year`,
macros_va.doh:276-279) would fail identically at the FB-test block (line 164-170).

## Root cause (mechanical, fully traced)

The lag variables are *produced* but *filtered out before the sample is saved*:

1. **Produced:** `do/sibling_xwalk/siblingoutxwalk.do:314-327` builds `old1_sib_enr{,_2year,_4year}` and
   `old2_sib_enr{,_2year,_4year}` (via `rangestat (max) ... interval(birth_order, lag1_bound, lag1_bound)`),
   and saves them in the crosswalk `$datadir_clean/siblingxwalk/sibling_out_xwalk.dta` (line 339).
2. **Filtered out at merge:** when `create_score_samples.do` builds the `_s/_ls/_as/_las` samples it includes
   `do/samples/merge_sib.doh`, whose merge is:

   ```stata
   merge m:1 state_student_id using `sibling_out_xwalk', nogen keep(1 3) keepusing(touse* *sibling*)
   ```

   `keepusing(touse* *sibling*)` keeps only vars matching `touse*` or containing the literal `sibling`.
   `old1_sib_enr_2year` matches **neither** (`sib` ≠ `sibling`). So the lag controls are dropped and never
   land in the saved `score_s.dta`.
3. **Consumed anyway:** the diagnostic `va_score_sib_lag.do` (and `va_out_sib_lag.do`) then ask `vam` to use
   them as controls → r(111). These two diagnostics are the **only** consumers of `sib_lag1_controls`/
   `sib_lag2_controls` in the tree.

## NOT a relocation regression

The consolidated `do/samples/merge_sib.doh:64` keepusing line is **byte-identical** to the predecessor
`cde_va_project_fork/do_files/sbac/merge_sib.doh:5`. The relocation did not introduce this. It is a
pre-existing latent mismatch in the predecessor pipeline.

## Why it only surfaced now

Predecessor production ran sample construction **cached/off** (`do_all.do:148` `do_create_samples = 0`); the
`score_s.dta` on Scribe were built once, long ago, and re-read thereafter. The consolidated M4 acceptance run
sets `m4_acceptance_run = 1` (`do/main.do:128`), which **forces `do_create_samples = 1`** — so `score_s` is
rebuilt fresh through the current `merge_sib.doh`, exposing the mismatch. (Whether the predecessor's *cached*
`score_s` happened to contain `old1_sib_*` from an even older sample build is unknown — that .dta is on Scribe;
no predecessor log for this diagnostic is synced locally.)

The diagnostic is explicitly **not paper-reported** — per `do_all.do`: "kept active for diagnostic; not
reported in the paper but kept available in case coauthors revisit."

## Fix options (genuine decision — see caveats)

### Option A — broaden the merge filter (sample-level fix)

In `do/samples/merge_sib.doh:64`, add the lag vars to `keepusing`:

```stata
merge m:1 state_student_id using `sibling_out_xwalk', nogen keep(1 3) keepusing(touse* *sibling* old1_sib_* old2_sib_*)
```

- Makes `score_s`/`out_s` (and all `_s/_ls/_as/_las` samples) carry the lag controls the diagnostic needs.
- **Caveat:** `merge_sib.doh` feeds the **main paper sibling samples**, not just the diagnostic. Adding columns
  is additive — `vam`/`reg` only use the controls they're named, so main estimates shouldn't change
  numerically — but the saved `.dta` files gain columns, which a strict M4 golden-master var-by-var diff
  against predecessor cached samples could flag.

### Option B — targeted merge inside the two diagnostics (scoped fix)

Leave `merge_sib.doh` untouched; in `va_score_sib_lag.do` and `va_out_sib_lag.do`, after each
`use ... score_s ...`, merge the lag vars from the crosswalk:

```stata
merge m:1 state_student_id using "$datadir_clean/siblingxwalk/sibling_out_xwalk", ///
  nogen keep(1 3) keepusing(old1_sib_enr_2year old1_sib_enr_4year old2_sib_enr_2year old2_sib_enr_4year)
```

- Confines the change to the two diagnostic files; main sample `.dta` files are byte-unchanged → cleanest for
  golden-master parity of the paper samples.
- **Caveat:** `state_student_id` must survive into the saved `score_s` for the merge key to exist (needs a
  quick check on the sample's keys).

### Option C — gate the diagnostic off

If the diagnostic isn't wanted in the M4 run, wrap both `va_score_sib_lag.do`/`va_out_sib_lag.do` invocations
in `do/main.do` behind a toggle (default off), since they're not paper-reported. Avoids the crash without
touching sample logic. Doesn't *fix* the diagnostic — defers it.

## Recommendation

**Option B** if the diagnostic should actually run (scoped, parity-safe). **Option C** if it's genuinely
dormant and we just need M4 to get past it. Option A only if we want the lag controls available in the shared
sibling samples generally. The choice depends on (a) whether this diagnostic is meant to run in M4 and (b)
golden-master parity intent — both user calls.

## Open / unverified

- Cannot run Stata locally (Scribe-only, air-gapped) — no fix applied yet; awaiting fix-location decision.
- Whether predecessor cached `score_s` contained `old1_sib_*` is undetermined (restricted .dta on Scribe).
- For Option B, need to confirm `state_student_id` is retained in saved `score_s`/`out_s`.
