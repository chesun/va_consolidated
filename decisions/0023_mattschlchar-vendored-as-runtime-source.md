# 0023: `mattschlchar.dta` vendored into the sandbox as the active runtime source

- **Date:** 2026-05-31
- **Status:** Decided
- **Scope:** Data
- **Data quality:** Full context
- **Supersedes:** #0013 (in part — see below)

## Context

`do/survey_va/mattschlchar.do` (Christina-authored wrapper, per ADR-0013) produces
`$datadir_clean/schoolchar/schlcharpooledmeans.dta`, consumed by the paper Table 8
panel producers (`indexregwithdemo.do:96`, `indexhorseracewithdemo.do:92`). It has a
`local clean` toggle:

- **`clean == 1`** — rebuilds the cleaned school-characteristics file from a raw source
  in Matt Naven's user directory (`/home/research/ca_ed_lab/msnaven/.../sch_char`).
- **`clean == 0` (production)** — reads a pre-built cleaned `mattschlchar.dta`, pools it,
  and merges with `elprop` to produce `schlcharpooledmeans.dta`.

ADR-0013 decided to keep `clean = 0` permanently, treat the cleaned file as a
pre-existing input artifact, and leave the `clean = 1` rebuild branch dormant. It left
one open question explicitly: *"Whether `sch_char.dta` should be defensively backed up
to `consolidated/data/raw/upstream/`… defaulting to no. Can revisit if the file is ever
discovered to be at risk."*

**The risk has now materialized.** The M4 acceptance run (`m4_acceptance_run = 1`)
errored in `mattschlchar.do` at the `use $datadir_clean/schoolchar/mattschlchar`
consumption step (line 139): under `clean == 0`, the `if \`clean' == 0 { }` block was
**empty**, so the consolidated sandbox never had a `mattschlchar.dta` to read, and the
`clean == 1` rebuild path is no longer usable because Matt's user directory is no longer
accessible. The original wrapper relied on the cleaned file already sitting on disk at
the predecessor path; the ADR-0021 self-contained sandbox does not inherit that file.

The already-cleaned `mattschlchar.dta` still exists on Scribe at
`$caschls_projdir/dta/schoolchar/mattschlchar.dta`
(`/home/research/ca_ed_lab/users/chesun/gsr/caschls/dta/schoolchar/mattschlchar.dta`).
This is the post-rename, post-clean file (it has `enrtotal`, `fteteach`, etc. that only
exist after the `clean == 1` renames), i.e. exactly what line 139 expects.

## Decision

- **Vendor the cleaned `mattschlchar.dta` into `consolidated/data/raw/upstream/`** on
  Scribe, following the ADR-0008 vendoring posture and directory convention.
  Source: `$caschls_projdir/dta/schoolchar/mattschlchar.dta`. Destination:
  `$datadir_raw/upstream/mattschlchar.dta`. The vendoring copy is performed by Christina
  on Scribe (the only environment with access to both source and destination).
- **Fill the `clean == 0` block** in `mattschlchar.do` to read the vendored copy and
  write the CHAIN file into the sandbox:

  ```stata
  if `clean' == 0 {
    use $datadir_raw/upstream/mattschlchar, clear
    save $datadir_clean/schoolchar/mattschlchar, replace
  }
  ```

- **Difference from ADR-0008:** there, the vendored crosswalks are *insurance* and the
  runtime still reads Matt's path. Here, the original raw source is gone, so the vendored
  copy is the **active runtime source** — `mattschlchar.do` reads from
  `$datadir_raw/upstream/` directly. This keeps the consolidated pipeline self-contained
  per ADR-0021 (no dependency on `$caschls_projdir` at runtime once vendored).
- **The `clean == 1` rebuild branch stays dormant** per ADR-0013, now additionally
  noted as having an inaccessible source.
- **A git-tracked path-stub `README.md`** in `data/raw/upstream/` records provenance; the
  `.dta` itself stays gitignored per ADR-0007 (Scribe-only).

## Relationship to ADR-0013

This **supersedes ADR-0013 in part**: ADR-0013's "`sch_char.dta`/`mattschlchar.dta` is
consumed as-is from its predecessor production path, no vendoring" posture is replaced by
"vendored into the sandbox as the runtime source." The rest of ADR-0013 stands: the
`clean = 0` gate is kept, the `clean = 1` rebuild branch stays dormant, and no rebuild
from Matt's raw sources is attempted. ADR-0013's open question (defensive backup) is
resolved here in the affirmative, triggered by the loss of access it anticipated.

## Consequences

**Commits us to:**

- A one-time (and on-every-fresh-Scribe-setup) `cp` of `mattschlchar.dta` into
  `data/raw/upstream/` on Scribe, documented in `data/raw/upstream/README.md` and the
  `clean == 0` block comment.
- The consolidated pipeline no longer depending on `$caschls_projdir` at runtime for this
  file (it depends on it only at vendoring time).

**Rules out:**

- Reviving the `clean == 1` rebuild branch (source inaccessible; would need a successor ADR).
- Committing the `.dta` to git (stays Scribe-only per ADR-0007).

**Open questions:**

- Provenance of `mattschlchar.dta` itself (which fields, years, original build) remains as
  documented in `mattschlchar.do`'s header and ADR-0013 — not re-derived here.

## Sources

- `do/survey_va/mattschlchar.do` L120-123 (the empty `clean == 0` block, now filled), L139 (the failing `use`)
- `do/settings.do:136` (`$caschls_projdir`), `:103` (`$datadir_raw`), `:102` (`$datadir_clean`)
- M4 acceptance run error in `mattschlchar.do` (reported by Christina 2026-05-31)
- Related: ADR-0013 (clean-gate kept; superseded in part here), ADR-0008 (vendoring posture + `data/raw/upstream/` convention), ADR-0007 (code/data separation — `.dta` gitignored), ADR-0021 (self-contained sandbox)
