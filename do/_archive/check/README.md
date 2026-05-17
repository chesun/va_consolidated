# do/_archive/check/ — Predecessor-layout one-off check diagnostics

**Status:** ARCHIVED. Not invoked from any production pipeline. Preserved for historical reference + archeology.

**Archived:** 2026-05-17 per Phase 1c §5.4 deferred-item resolution (pre-flight Partition B audit finding 4).
**Authority:** ADR-0017 (Matt/predecessor-layout files untouched precedent) + ADR-0021 (description convention; sandbox).

## What this directory contains

One-off Phase 0a-v2 audit diagnostics that ran against the **predecessor** Scribe layout (`do_files/` + `log_files/`) before Phase 1a §3.3 relocation. Bodies preserved verbatim per ADR-0021. Not part of the consolidated sandbox pipeline — would silently break `do/check/check_logs.do`'s invariant (every `do/**/*.do` produces a `$logdir/*.smcl` on a clean main.do run) if kept under `do/check/`.

## Files archived (1)

- `t1_empirical_tests.do` (added 2026-05-17) — Phase 0a-v2 verified-final audit T1 empirical tests (P2-3, P2-6, P2-13). Predecessor-layout script: header documents "Place this file on Scribe at `do_files/check/t1_empirical_tests.do`" and writes log to relative `log_files/check/` (predecessor layout), not `$logdir/`. Not invoked from `do/main.do` (verified by grep). Superseded by the consolidated-sandbox check pipeline at `do/check/check_*.do` per plan v3 §5.3.

## Why archived

Pre-flight Partition B coder-critic review (`quality_reports/reviews/2026-05-16_pre-flight-B_va-samples-xwalk-check_coder_review.md` finding 4): the file's presence in the active `do/` tree breaks `check_logs.do`'s structural invariant on the ADR-0018 acceptance run because no producer wrote `$logdir/t1_empirical_tests.smcl`. Choices were (1) archive, (2) add exclusion regex in `check_logs.do`, (3) tag system. Option (1) is the lowest-friction and consistent with the "predecessor-layout one-off diagnostic" classification.

Side effect: also resolves the orthogonal Minor finding 9 (log target `log_files/check/` not under `$logdir/`) — archiving removes the file from load-bearing scope, so the log-routing concern is moot.

## Cross-references

- **ADR-0017** — Matt-files-untouched precedent (sibling rationale for "predecessor-layout artifact, don't try to repoint into consolidated layout")
- **ADR-0021** — sandbox + body-verbatim archive convention
- **Phase 1c §5.4** — deferred-item resolution
- **Pre-flight Partition B review** — `quality_reports/reviews/2026-05-16_pre-flight-B_va-samples-xwalk-check_coder_review.md` finding 4 + finding 9
- **Audit doc** — `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` §3.1 (T1 tests origin)
- **Consolidated-sandbox successor** — `do/check/check_*.do` (plan v3 §5.3)
