# `data/raw/upstream/` — vendored upstream `.dta` backups (Scribe-only)

This directory holds **read-only backups of upstream data files** that the
consolidated pipeline depends on but does not build. Per ADR-0007 (code/data
separation), the `.dta` files themselves are **gitignored** — they live only on
Scribe. This README and the `.gitkeep` are the only git-tracked contents; they
are a path-stub documenting what *should* be here.

See ADR-0008 (the original vendoring decision, for the K12↔CCC/CSU crosswalks)
and ADR-0023 (the `mattschlchar.dta` vendoring decision).

## Files that belong here (Scribe-side)

| File | Provenance (source path on Scribe) | Consumed by | ADR |
|------|------------------------------------|-------------|-----|
| `mattschlchar.dta` | `/home/research/ca_ed_lab/users/chesun/gsr/caschls/dta/schoolchar/mattschlchar.dta` (= `$caschls_projdir/dta/schoolchar/mattschlchar.dta`) | `do/survey_va/mattschlchar.do` (`clean==0` block) → `$datadir_clean/schoolchar/mattschlchar` → `schlcharpooledmeans` → Table 8 panels | ADR-0023 |
| `k12_ccc_crosswalk.dta` | Matt Naven user dir (see ADR-0008) | `merge_k12_postsecondary.doh` (runtime still reads Matt's path; this is backup only) | ADR-0008 |
| `k12_csu_crosswalk.dta` | Matt Naven user dir (see ADR-0008) | `merge_k12_postsecondary.doh` (backup only) | ADR-0008 |

> Note: unlike the ADR-0008 crosswalks (vendored as *insurance*, runtime still
> reads Matt's path), `mattschlchar.dta` is vendored as the **active runtime
> source** — the original raw source is no longer accessible, so `mattschlchar.do`
> reads from here directly (`$datadir_raw/upstream/mattschlchar`). See ADR-0023.

## To (re)vendor `mattschlchar.dta` on Scribe (one-time / fresh setup)

```bash
mkdir -p $consolidated_dir/data/raw/upstream
cp /home/research/ca_ed_lab/users/chesun/gsr/caschls/dta/schoolchar/mattschlchar.dta \
   $consolidated_dir/data/raw/upstream/mattschlchar.dta
```

(Equivalently, the source is `$caschls_projdir/dta/schoolchar/mattschlchar.dta`.)

> **Note (2026-06-01):** `do/survey_va/mattschlchar.do`'s `clean==0` block now attempts to
> self-provision this file each run via an in-script copy from `$caschls_projdir`, so the
> manual `cp` above may be unnecessary when caschls is readable from the run host. Caveat:
> the in-script copy must use a command Stata actually recognizes — native `copy "src" "dst"`,
> or `shell cp ...` / `!cp ...` (bare `cp` wrapped in `cap` is not a Stata command and would
> silently no-op, falling back to requiring the file to already be present here). Keep this
> manual recipe as the reliable fallback for fresh setups or if the in-script copy is removed.
