# Adversarial Review — check_logs.do rewrite ([RUN]-scoped, reldir-mirrored)

**Date:** 2026-06-01
**Reviewer:** general-purpose agent (adversarial, refute-default) + independent reproduction by Claude
**Target:** `do/check/check_logs.do` (2026-06-01 rewrite)
**Status:** Active
**Verdict:** Rewrite is sound on the hard mechanics; **1 confirmed latent defect (false FAIL) — FIXED**; 1 cosmetic count message — FIXED.

## Method
Reviewer built 13 `stata17 -b` test harnesses, including an end-to-end replay of the 83 real `[RUN]` markers from `log/main_-1-Jun-2026_19-50-47.smcl` against the real 107-file `do/` tree. Claude independently reproduced the one confirmed defect before fixing.

## Confirmed defect (FIXED)
**False FAIL from lines that merely MENTION `[RUN] do/<path>`.** The matcher was
`strpos(line, "[RUN] do/")` + substring cuts. Any non-marker line containing that substring
(a comment, a `di`, leaked sub-do output) was parsed as a genuine marker → flagged that file
as "ran" → if it had no log, `exit 9` halted a clean pipeline.

- **Reproduced** (Claude, independent): master log line `note: will [RUN] do/va/va_corr.do later`,
  `va_corr.do` unlogged → `FAIL: 1 do file(s) RAN ... no matching log` → `r(9)`. False FAIL.
- **Not active in current logs** (reviewer verified: all 81 unique `[RUN] do/` paths in the real
  master log are genuine markers mapping to real files; zero prose `[RUN] do/` lines) — but one
  stray `di`/comment away from halting a clean run.
- **Fix applied:** anchored regex requiring the path to terminate at a closing quote or EOL:
  ```stata
  if regexm(`"`macval(line)'"', `"\[RUN\] (do/[^ "]+\.do)("|$)"') {
      local p = regexs(1)
      quietly replace ran_this_run = 1 if relpath == "`p'"
  }
  ```
  Replaces the strpos + manual quote/space cuts. `macval()` retained for quote-safety.
- **Re-tested (Claude, post-fix), all 3 paths:** (A) prose mention + unlogged file → now PASS
  (rejected, 0 ran); (B) genuine marker + log present → PASS; (C) genuine marker + log missing
  → FAIL exit 9. Correct on all three.

## Cosmetic fix
The first `di` printed `enumerated N` using the pre-drop count (incl. main.do/settings.do),
then `n_dofiles` was reset post-drop → "enumerated 109 … of 107 ran". Renamed the pre-drop
var to `n_enumerated` and clarified the message. No logic impact.

## Attacks the rewrite WITHSTOOD (reviewer proof)
- **`clear all` interaction:** globals + open `master` log handle survive `clear all`; `log query
  master` still returns the filename after check_logs's own `clear all`. Not a no-op false PASS.
- **`log query master` dependency:** returns the path even when log is suspended (`log off master`,
  the Phase-7 state). Standalone (no master) → WARN + skip, no crash. Master open w/ no markers →
  vacuous PASS (correct per design-memo scope).
- **macval / r132 quote safety:** lines with `"`, backticks, `$`-macros, unbalanced quotes — no
  r132. Shielding holds.
- **reldir math:** top-level file → reldir `""` → single-slash `$logdir/<name>.smcl` (matches real
  log); `subinstr` anchored on full `$consolidated_dir/do` prefix — safe even when `$consolidated_dir`
  contains a `do` substring.
- **filelist count consistency:** 109 enumerated → 107 post-drop; `forvalues` bound + `in i` indexing
  stay aligned after `drop` (contiguous renumber). `_archive` regex `/_archive($|/)` rejects
  `_archived`/`my_archive_x`.
- **exit 9 propagation:** `r(9)` from a `do`-called check halts the parent pipeline.

## Open (not a check_logs defect)
- **Vacuous-PASS masking:** if a future main.do edit drops a `[RUN]` marker for a file that does
  run, `n_ran` undercounts → that file isn't asserted. This is a main.do marker-emission concern,
  consistent with the design-memo scope ("files that ran per markers"). Noted, not fixed here.

## Cross-refs
- Target: `do/check/check_logs.do`; markers emitted by `do/main.do` (Phase wrappers)
- Filelist option fix (same file, earlier today): `norecur(0)` → omit (default recursive)
