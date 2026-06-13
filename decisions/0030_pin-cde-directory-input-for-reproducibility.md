# 0030: pin the K12 distance input to the cached CDE directory (drop live-URL fetch by default)

- **Date:** 2026-06-12
- **Status:** Decided
- **Scope:** Data
- **Data quality:** Full context

## Context

The full M4 golden-master run (commit `7fe9c1a`) reported value differences on
`data/cleaned/k12_postsec_distance/clean/k12_postsec_{distance,mindistance}.dta`
and, downstream, on exactly the 5 `mindist_*` variables of the analysis samples
(50,766 of 1,784,445 rows in `score_b.dta`; all other 72 variables identical).
Spot-check confirmed identical obs counts + identical variable lists — value
drift only (see `quality_reports/reviews/2026-06-10_m4-full-golden-master_triage.md`
§"Spot-check RESULTS" and §"ROOT CAUSE").

Root cause (code- and log-traced 2026-06-11):
`do/data_prep/k12_postsec_distance/k12_postsec_distances.do` fetched the CDE
school directory from a **live URL** at run time —
`capture import delimited "https://www.cde.ca.gov/schooldirectory/report?rid=dl1&tp=txt"`
— and only fell back to the cached `$distance_dtadir/raw/pubschls.txt`
(downloaded 3/20/23) on HTTP error. The e968d13 run log
(`log/data_prep/k12_postsec_distance/k12_postsec_distances.log:276-282`) shows
the live fetch SUCCEEDED, so the consolidated outputs were built from the
June-2026 directory while the predecessor's reference file reflects an earlier
snapshot. The CDE directory is continuously updated (schools open/close/move,
coordinates get corrected); `geodist` + `collapse (min) … by(cdscode)` are
deterministic, so the entire diff is input-vintage drift, not a code regression.

This logic is predecessor-original (relocated verbatim in Phase-1a batch 9c).
The consequence is that distance-derived outputs — `mindist_*` and every
distance-restricted or distance-controlled VA sample/estimate downstream
(the `d` in sample codes such as `lad`/`lasd`) — were **not reproducible**: two
runs on different dates produce different results from identical code.

## Decision

- **Pin the K12 directory input to the cached file by default.** Introduce a
  config toggle `global refresh_cde_directory 0` in `do/settings.do`
  (BEHAVIOR/CONFIG TOGGLES block, mirroring the `run_prior_score` pattern).
  When `0` (default, unset == pinned) the producer reads
  `$distance_dtadir/raw/pubschls.txt` directly; when `1` it performs the
  original live-URL fetch with disk fallback. Gate condition used verbatim:
  `if "$refresh_cde_directory" == "1"`.
- **Predecessor logic is preserved**, not deleted — it is the `==1` branch, so a
  deliberate refresh (a new-data operation, not a replication run) remains
  available.
- The M4 `mindist_*` / distance-file diffs are classified **intended deviation**
  (input-vintage drift under predecessor-original fetch logic), now eliminated
  going forward by the pin.

Alternatives considered and rejected: (a) accept the drift and only document it
(Option B in the triage) — rejected because the repo is headed for a frozen
`v1.0-final` archive and a replication package whose results depend on the run
date defeats that purpose; (b) vendor the exact June-2026 directory the
consolidated run used — not possible, the live fetch went straight into a
tempfile and was never saved.

## Consequences

**Commits us to:**
- A fresh consolidated run now reproduces the distance outputs from the pinned
  3/20/23 `pubschls.txt`, independent of run date.
- **The committed canonical distance outputs (and all distance-derived
  downstream samples/estimates) must be REGENERATED from the pinned input on the
  next clean re-run.** The currently-committed `data/cleaned/.../k12_postsec_*`
  files were built from the June-2026 live directory; after this pin they no
  longer match what the code produces. This folds into the already-pending clean
  Phase 5–7 re-run. Until that re-run, code and committed outputs are knowingly
  inconsistent for the distance family.
- A subsequent golden master will still NOT byte-match the predecessor on the
  distance family (the predecessor's fetch vintage is unrecoverable); the pin
  fixes forward reproducibility, not backward parity. This ADR is the recorded
  explanation for that residual diff.

**Rules out (for now):** silent live fetches in normal runs.

**Follow-up (not blocking, for the replication deposit):** `pubschls.txt` lives
at a server path under `$distance_dtadir/raw/` outside the repo; for an
AEA-style deposit it should be vendored into the package (cf. ADR-0023 for
`mattschlchar.dta`) with provenance recorded. Tracked, not done here.

## Sources

- Triage + root cause: `quality_reports/reviews/2026-06-10_m4-full-golden-master_triage.md`
  §"Spot-check RESULTS", §"ROOT CAUSE"
- Code: `do/data_prep/k12_postsec_distance/k12_postsec_distances.do` (fetch block,
  now toggle-gated); `do/settings.do` (toggle definition)
- Run log proving live fetch succeeded:
  `log/data_prep/k12_postsec_distance/k12_postsec_distances.log:276-282`
- Spot-check script + log: `do/debug/m4_spotcheck_triage.do`;
  `log/debug/m4_spotcheck_triage.log` (commit `aa43824`)
- Session log: `quality_reports/session_logs/2026-06-09_e968d13-pull-and-phase7-fail-triage.md`
  Addenda 4–5
- Related: ADR-0003 (Python geocoding upstream-only), ADR-0021 (sandbox-write),
  ADR-0023 (vendoring a raw input)
