# 0006: `vam.ado` pinned at v2.0.1 + noseed customization

<!-- primary-source-ok: sun_2026 -->
(Note: "Sun 2026-04-25" in the version line below refers to Christina Sun, the project author who made the noseed-fix on that date — not an external citation.)

- **Date:** 2026-04-27
- **Status:** Decided
- **Scope:** Methodology
- **Data quality:** Full context

## Context

The CFR-style value-added estimator runs through `vam.ado`, originally distributed by Michael Stepner as a public Stata SSC package (Chetty-Friedman-Rockoff implementation). Phase 0a chunk-1 audit confirmed the file in the predecessor repo is **Stepner v2.0.1** with one local modification:

- `vam.ado:252-255` — a noseed-fix added 2026-04-25 (commit `0202251`) that addresses a reproducibility issue when `vam` is invoked inside a loop without an explicit seed reset. Without the fix, repeated invocations within the same Stata session can produce non-identical estimates because `vam` internally calls `bsample` which advances the seed state.

The fix is small (4 lines) but materially affects reproducibility — running `va_score_all.do` twice in succession would produce slightly different VA estimates without it. The fix is custom and has not been upstreamed to Stepner.

This decision pins the customized `vam.ado` to the consolidated repo's `ado/` directory so the Phase 1 reproducible pipeline does not depend on whatever happens to be in `c(adopath)` on Scribe at runtime.

## Decision

The customized `vam.ado` (Stepner v2.0.1 + noseed-fix at L252-255) is **vendored** to `ado/vam.ado` in the consolidated repo. `main.do` adjusts `adopath` to put `./ado` first, so the project always uses the pinned version regardless of any other `vam.ado` installed on Scribe.

The version line at the top of `vam.ado` is updated:

- **Before:** `*! version 2.0.1`
- **After:** `*! version 2.0.1.1 — C. Sun 2026-04-25 noseed-fix at L252-255 (was originally L252-253 of Stepner v2.0.1)`

This makes the customization visible to anyone reading the file, and to `which vam` calls.

## Consequences

**Commits us to:**

- `ado/vam.ado` is part of the consolidated repo and version-controlled. Future Stepner updates to upstream `vam.ado` are reviewed manually before adoption (no automatic SSC update).
- Replication on or off Scribe uses the same pinned estimator. Resolves chunk-1 disc A11 (vam.ado `*!` line not updated to reflect noseed-fix).
- The noseed-fix becomes a documented, reviewable line of custom code rather than an undocumented patch.

**Rules out:**

- Treating `vam.ado` as a black-box SSC dependency. We own a fork of it.
- Silently updating `vam.ado` to a newer Stepner release without a superseding ADR.

**Open questions:**

- Whether to upstream the noseed-fix to Stepner (separate decision; not blocking Phase 1).
- The 2026-04-25 commit `0202251` was made in a predecessor repo; Phase 1 needs to confirm the customized version (not the unmodified SSC version) is what gets vendored.

## Sources

- `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` §1 (vam.ado is Stepner v2.0.1 with noseed-fix)
- `quality_reports/audits/round-2/chunk-1-discrepancies.md` A11 (`*!` line not updated), TEMPORAL ARTIFACT (round-1 read pre-fix, round-2 read post-fix)
- `quality_reports/audits/round-1/2026-04-25_chunk1-foundation.md` (original v2.0.1 + customization mapping)
- Predecessor repo commit `0202251` (2026-04-25 noseed-fix by C. Sun)
- ADR-0003 (Languages — Stata primary, project owns its `.ado`)
- ADR-0001 (Consolidation scope)
