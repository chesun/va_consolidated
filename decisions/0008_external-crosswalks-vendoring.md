# 0008: External crosswalks vendored as defensive backup on Scribe; runtime unchanged

- **Date:** 2026-04-27
- **Status:** Decided
- **Scope:** Infrastructure
- **Data quality:** Full context

## Context

Two `.dta` crosswalk files are read by `merge_k12_postsecondary.doh` (Matt's file, untouched per ADR-0017):

- `k12_ccc_crosswalk.dta` — at `merge_k12_postsecondary.doh:142`
- `k12_csu_crosswalk.dta` — at `merge_k12_postsecondary.doh:207`

Both files live in Matt's user directory on Scribe (referenced by hardcoded path in the merge file's preamble). They are **data**, not code — administrative crosswalks linking K-12 student IDs to community-college and CSU outcome IDs. The files are static (single-vintage). Phase 0a chunk-2 audit flagged this as ADR-0017's open question on Matt's data files: does the "untouched" rule extend to his data, or only to his code?

The realistic failure mode: Matt's user directory or account permissions change, and the pipeline silently breaks at the merge step. The mitigation is cheap — copy the two files into the consolidated folder on Scribe as defensive backup. Christina's preference (2026-04-27): vendor as backup only; do not modify Matt's code to read from the new location, since that would violate ADR-0017.

Per ADR-0007 (code-data separation), all data lives on Scribe and is gitignored. So the vendored copies are NOT in the GitHub repo — they are Scribe-only artifacts.

## Decision

The two external crosswalks are **vendored to `consolidated/data/raw/upstream/` on Scribe** as defensive backups:

- `consolidated/data/raw/upstream/k12_ccc_crosswalk.dta`
- `consolidated/data/raw/upstream/k12_csu_crosswalk.dta`

`merge_k12_postsecondary.doh` is **NOT modified.** Runtime continues to read from Matt's user directory paths as before. The vendored copies are insurance against Matt's directory becoming unavailable.

A `consolidated/data/raw/upstream/README.md` note (also gitignored on Scribe-side, but present in the GitHub repo as a path-stub README documenting what should be there) records:

- Provenance of each file (Matt's user directory path, date copied, file size, optional checksum)
- That these are read-only backups, NOT the runtime path
- That if Matt's directory becomes unavailable, the path resolution in `merge_k12_postsecondary.doh` would need to be updated, which would be a Phase 2+ activity (or trigger a successor ADR if needed sooner)

The vendoring action is performed by **Christina on Scribe** (the only environment with access to both source and destination). The GitHub repo will contain the empty `data/raw/upstream/` directory with a placeholder `README.md` per ADR-0007, but never the `.dta` files themselves.

## Consequences

**Commits us to:**

- ~50-100MB of `.dta` data committed to Scribe-side `consolidated/`. Not in the git repo (per ADR-0007).
- An asymmetry: file copies exist in the consolidated folder but production reads from Matt's user directory. Documented in the path-stub README.
- Resolves ADR-0017's open question on Matt's data files: scope rule applies to **code only**; data files MAY be vendored to Scribe consolidated/ if cheap and cleanly read-only.

**Rules out:**

- Path A (no vendoring) — accepted the runtime risk previously, now mitigated.
- Path C (vendor + code change) — explicitly violates ADR-0017.
- Vendoring to the GitHub repo — explicitly violates ADR-0007.

**Open questions:**

- The CCC and CSU outcomes crosswalks proper (`crosswalk_ccc_outcomes.do` / `crosswalk_csu_outcomes.do` — Matt's `.do` files) produce upstream `.dta` outputs that are also consumed by `merge_k12_postsecondary.doh`. Those are NOT covered by this ADR — they remain in scope of ADR-0017 (code) and would require their own decision if defensive backup of those `.dta` outputs is ever wanted.
- Whether to include a checksum in the README provenance note. Useful for detecting silent corruption but not required.

## Sources

- `quality_reports/audits/2026-04-27_T4_answers_CS.md` (Q-12 context — Matt's merge code intentional but out of scope)
- `quality_reports/audits/round-2/chunk-2-discrepancies.md` (external crosswalk dependencies)
- `quality_reports/audits/round-2/chunk-10-discrepancies.md` A11 (external crosswalk vendoring open question)
- `cde_va_project_fork/do_files/merge_k12_postsecondary.doh:142, 207` (consumer points)
- 2026-04-27 conversation: Christina prefers Path B (vendor as defensive backup; runtime unchanged); vendoring action performed by Christina on Scribe
- Related: ADR-0007 (code-data separation — data lives on Scribe only), ADR-0017 (Matt's files untouched — open question on data files resolved here)
