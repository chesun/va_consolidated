# 0009: Prior-score variant — v1 is canonical for paper; v2 preserved as exploratory

- **Date:** 2026-04-27
- **Status:** Decided
- **Scope:** Specification
- **Data quality:** Full context

## Context

The VA pipeline supports two prior-score control variants, distinguished by the global `version` macro that runs through `va_score_all.do`, `va_out_all.do`, and the sample-construction code:

- **v1** — original prior-score control. ELA gets one set of prior-score predictors; math gets a different set. Defined in `create_prior_scores_v1.doh`. This is what the working paper `paper/common_core_va_v2.tex` uses end-to-end.
- **v2** — exploratory variant where ELA and math use the **same** prior-score predictors. Originally created to test sensitivity. Phase 0a chunk-2 round-2 verified the v1 prior-score table line-by-line; v2 docstring dates were transcription errors (the code uses L5 = 5-year lag, not the dates the comments suggested).

The audit confirmed all paper-load-bearing tables and figures (chunks 8 and 9) consume v1-pathed estimates: outputs land in `estimates/va_cfr_all_v1/`, tables write to `tables/va_cfr_all_v1/`, figures save to `figures/va_cfr_all_v1/`. The v2 path produces parallel outputs at `*_v2/` paths but those are not referenced anywhere in the paper TeX.

Christina's Phase 0e Q-19 answer ("`base_sum_stats_tab.do` and `sample_counts_tab.do` v1-only intentional, this was written after v1-only decision was reached, saves runtime") confirms that the v1-only direction was decided earlier. Writing this ADR formalizes the decision so the choice is visible to future maintainers and Phase 1 can selectively retire or preserve v2 producers.

This decision settles the original ADR queue's slot 0006 (which had this exact title) and resolves chunk-9 P3-57, P3-58.

## Decision

**v1 is the canonical prior-score variant for paper Tables 1-8 and Figs 1-5.** All paper-output producers in `do/share/` consume `estimates/va_cfr_all_v1/...` paths.

**v2 is preserved as an exploratory variant** but is not paper-load-bearing. The `version` loop in `va_score_all.do` and `va_out_all.do` continues to iterate `foreach version in v1 v2` so estimates regenerate for both, but Phase 1 producers (table/figure scripts in `do/share/`) hardcode the `_v1` path. v2-only outputs remain on disk for future sensitivity analyses but no paper-shipping artifact is built from them.

Specifically allowed Phase 1 simplifications, given v1-only paper status:

- New `share/` table/figure producers may hardcode the v1 path without writing a v2 mirror.
- Existing v2-mirror table/figure producers may be archived if they have no paper consumer (case-by-case, but the v1-only `base_sum_stats_tab.do` and `sample_counts_tab.do` are the precedent — Q-19).
- Documentation may refer to "the prior-score control" without `v1`/`v2` qualification.

Specifically NOT allowed:

- Removing the `foreach version in v1 v2` loop in `va_score_all.do` / `va_out_all.do`. Both variants continue to estimate so v2 is available for future reactivation. Cost is bounded (~2x VA runtime) and the option value is non-zero.
- Deleting `create_prior_scores_v2.doh` or the v2-pathed sample files. They stay on disk on Scribe even if unused.

## Consequences

**Commits us to:**

- Paper compilation, replication, and review activities all reference `estimates/va_cfr_all_v1/`. v2 paths are silent on the paper side.
- Phase 1 producers can simplify to v1-only without violating the contract (precedent set by Q-19).
- Future re-activation of v2 (if a referee asks for it) requires re-pointing producers, not re-running the underlying estimator. The estimator already produces both.

**Rules out:**

- Treating v2 as production. v2 is exploratory, period.
- Removing v2 from the estimator loop in `va_score_all.do` / `va_out_all.do`.
- Mixed-version paper outputs (e.g., a paper that cites a v1 table next to a v2 table without flagging the difference). If a future revision needs v2 results, an ADR superseding this one is required first.

**Open questions:**

- Whether the v2 mirror dirs (`tables/va_cfr_all_v2/`, `figures/va_cfr_all_v2/`, `estimates/va_cfr_all_v2/`) should be Phase-1-archived or kept as live mirrors. Default is "kept" since the estimator still writes to them; if disk pressure ever becomes an issue, revisit.
- Whether `_scrhat_` (the third axis — predicted prior score) interacts with the v1/v2 choice. Per chunk-9 audit `_scrhat_` is exploratory only; it pairs with v1 by default.

## Sources

- `quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md` §1 (v1 prior-score table verified line-by-line; v2 docstring dates transcription errors)
- `quality_reports/audits/round-2/chunk-2-discrepancies.md` (v1 cohort-by-cohort verification)
- `quality_reports/audits/round-2/chunk-9-discrepancies.md` P3-57, P3-58 (v1-only producers)
- `quality_reports/audits/2026-04-27_T4_answers_CS.md` Q-19
- `cde_va_project_fork/do_files/sbac/va_score_all.do:58` (the version loop)
- `cde_va_project_fork/do_files/sbac/create_prior_scores_v1.doh` (canonical prior-score definitions)
- Related: ADR-0004 (canonical pipeline produces v1 + v2 in same loop); ADR-0001 (consolidation scope)
