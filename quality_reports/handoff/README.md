# Offboarding Handoff Memos

This folder holds offboarding-deliverable memos per ADR-0018.

## What lives here

When Phase 1c §5.4 (final verification + freeze) completes, an offboarding memo lands here at:

```
quality_reports/handoff/YYYY-MM-DD_offboarding-memo.md
```

The date is set when the actual offboarding happens (not at any earlier milestone). The audience is **Kramer** (CEL data-management custodian, per ADR-0018) plus the future-unknown successor inheriting the deposit.

## What the memo captures (per ADR-0018 + plan v3 §5.2 step 8)

- **GitHub repo URL** — `<https://github.com/chesun/va_consolidated>` and the `v1.0-final` tag URL.
- **Scribe `consolidated/` folder location** — full path on Scribe.
- **CEL lab IT contact** — for provisioning new Scribe SSH accounts (the successor will need this).
- **Where data lives on Scribe** — paths to `data/raw/`, `estimates/`, etc. (the `.gitignored` data tree that lives only on the server).
- **Where Matt Naven's untouched files are** (per ADR-0017) — paths + rationale.
- **Acceptance-run log path** (per ADR-0018) — the clean-pipeline-run log produced by Phase 1c §5.4 step 13, before `v1.0-final` was tagged.
- **Inventory of Kramer's responsibility** — Kramer is the custodian of the deposit (not the maintainer); this memo records what custody means and what it does not include.
- **Decisions/conversations not in ADRs** — whatever didn't quite warrant an ADR but the successor would benefit from knowing.

## Why this folder exists today (pre-offboarding)

The README at the repo root references this folder in §9 ("When something breaks → if you can't resolve it"). Stub created during Phase 1c §5.2 README pre-draft (2026-04-29) so the path resolves at cold-read time. The actual memo is written at offboarding.

## See also

- ADR-0018 — `decisions/0018_offboarding-model-refinement.md`
- Plan v3 §5.2 step 8 + §5.4 step 17 — `quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md`
