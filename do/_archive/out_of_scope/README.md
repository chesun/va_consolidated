# do/_archive/out_of_scope/ — Descoped scripts (input removed / out of project scope)

**Status:** ARCHIVED. Not invoked from `do/main.do`. Preserved for archeology.

**Distinct from `do/_archive/exploratory/`:** those files were *exploratory* (sensitivity
checks never paper-shipping). The files here were *in* the pipeline but became
**non-runnable / out of scope** because a required input was removed or the analysis was
descoped by the PI. Body preserved verbatim per ADR-0021 (plus an ARCHIVED header note).

**Authority:** ADR-0025 (nsc_codebook descope).

## Files archived (1)

- `nsc_codebook.do` (archived 2026-06-01) — produced an NSC-outcomes codebook (txt log) from
  `$nscdtadir/nsc_2010_2017_clean` and `nsc_2010_2018_clean`. The M4 run errored r(601) at
  `use $nscdtadir/nsc_2010_2017_clean` because that dataset **no longer exists on Scribe** —
  per Christina (2026-06-01), the NSC source was removed and re-cleaned into datasets under
  different names, and producing this codebook is now out of project scope. Diagnostic-only
  output (a codebook txt), not paper-shipping; no downstream consumer. Removed from
  `do/main.do` Phase 6. See ADR-0025.

## Why descoped (not just "broken")

The input dataset was intentionally removed/renamed on Scribe; reviving the codebook would
require re-pointing to the new dataset names AND re-confirming the codebook is still wanted —
neither is in scope. Reviving would need a successor ADR.
