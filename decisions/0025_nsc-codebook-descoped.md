# 0025: `nsc_codebook.do` descoped and archived — input dataset removed from Scribe

- **Date:** 2026-06-01
- **Status:** Decided
- **Scope:** Data
- **Data quality:** Full context

## Context

`do/share/outcomesumstats/nsc_codebook.do` produced an NSC-outcomes codebook (a `.txt`
log of variable definitions/ranges) by reading `$nscdtadir/nsc_2010_2017_clean` and
`nsc_2010_2018_clean`. The 2026-06-01 M4 run errored `r(601)` at
`use $nscdtadir/nsc_2010_2017_clean, clear` — the dataset is no longer present on Scribe.

Per Christina (2026-06-01): the NSC source data was **removed and re-cleaned into datasets
under different names**, and producing this codebook is **out of project scope**. The
output is a diagnostic codebook txt, not paper-shipping, with no downstream consumer in
the pipeline (the chain producers read NSC outcomes via the separate `k12_nsc2019_merge.doh`
helper, not via this codebook).

This is distinct from the exploratory-archive class (ADR-0010, `alpha.do`): that was a
sensitivity check never meant for the paper. `nsc_codebook.do` *was* wired into the
pipeline (Phase 6) but is now **non-runnable** because its input was intentionally removed,
and reviving it is out of scope.

## Decision

- **Remove `do do/share/outcomesumstats/nsc_codebook.do` from `do/main.do` Phase 6.**
- **Archive the file to `do/_archive/out_of_scope/nsc_codebook.do`** (a new archive subdir
  for descoped-not-exploratory scripts), with an ARCHIVED header note and a directory
  README. Body preserved verbatim per ADR-0021.
- **Do not** repoint it to the renamed NSC datasets or otherwise revive it — out of scope.
- The `nsc2019new/k12_nsc2019_merge.doh` helper (different file, still consumed by chain
  producers) is **unaffected** and stays under `do/share/outcomesumstats/`.

## Consequences

**Commits us to:**
- A new archive bucket `do/_archive/out_of_scope/` for descoped scripts (reason: input
  removed / PI-descoped), separate from `do/_archive/exploratory/`.
- Phase 6 no longer attempts the NSC codebook; the M4 run proceeds past this point.

**Rules out:**
- Reviving the codebook without a successor ADR + re-pointing to the new NSC dataset names.

**Open questions:**
- The renamed/re-cleaned NSC datasets' names are not recorded here (out of scope); if a
  codebook is ever wanted again, that's net-new work.

## Sources

- M4 run error: `log/share/...` r(601) at `use $nscdtadir/nsc_2010_2017_clean`
- `do/_archive/out_of_scope/nsc_codebook.do` (archived file + header note), `do/_archive/out_of_scope/README.md`
- `do/main.do` Phase 6 (invocation removed 2026-06-01)
- Christina 2026-06-01 (NSC source removed/re-cleaned; out of scope)
- Related: ADR-0010 (exploratory-archive convention — this is the *descoped* sibling bucket), ADR-0021 (verbatim-body archive convention)
