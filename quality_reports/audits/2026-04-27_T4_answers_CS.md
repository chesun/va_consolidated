# Phase 0e Q&A Items (T4 escalations) Christina Answers

Christina answers in "CS Answers" column.

| # | Question | Source | CS Answers |
|---|---|---|---|
| ~~**Q-1**~~ | ~~Paper Table 2/3 row 6 attribution~~ — **RESOLVED** (Christina 2026-04-26): Column 6 is the `lasd` column (kitchen-sink + distance INCLUDED IN VA SPEC). Spec-test row populated; FB rows correctly blank by FB-test structural property. | RESOLVED | |
| **Q-2** | Is the `run_prior_score = 0` gate intentional? Single-subject prior-decile heterogeneity figures need it ON to regenerate cleanly. | P2-4 | yes, intentional to save run time |
| **Q-3** | Where does the paper-reported α come from — `alpha.do` (wider 20/17/4/4-item lists) or `indexalpha.do` (narrower 9/15/4-item lists matching the regression indices)? | P1-5 | indexalpha.do produces paper results. alpha.do is exploratory |
| **Q-4** | Is the `enr=.` for NSC-non-matched-but-CCC-or-CSU-positive intentional NSC-anchoring or a bug? | P2-10 | Out of scope, Matt file |
| **Q-5** | Is `mattschlchar.do`'s msnaven cross-user dependency planned for Phase 1 vendoring or symlink? | P2-15 | keep the gate. will not need to reproduce original file, avoid cross user dependency | 
| **Q-6** | Does `reg_out_va_sib_acs_tab.do` actually feed paper Table 7? If yes, the mtitles labeling bug needs fixing. | P2-5 | it does not feed paper tables, the csv outputs are for local review only. All paper tables are produced by code in share/ folder |
| **Q-7** | `peer_<X>d_controls` peer-distance asymmetry — intentional (peer-distance not meaningful at school level) or bug? | P3-6 | intentional |
| **Q-8** | `Xd_str` display-string aliases (all collapse to `X_str`) — intentional or labeling bug? | P3-3 | intentional |
| **Q-9** | Naming standardization for sibling-VA — adopt `og/acs/sib/both` as canonical, deprecate `_sibling/_nosibctrl/_nocontrol`? | chunk 5 disc N2 | sibling VA estimation files in /siblingvaregs are deprecated. production code for sibling VA estimation is in the cde_va_project_fork/do_files/sbac/va_{score|out}_all.do do files. please verify |
| **Q-10** | DK controls in `va_sib_acs_out_dk.do` — hard-coded `va_ela_og va_math_og` across all 4 specs — intentional design choice (single OG baseline) or bug (should be spec-matched)? | chunk 5 disc A8 | intentional, but deprecated per Q9|
| **Q-11** | "Averages" (paper text) vs "Sums" (code) for survey indices — fix paper or fix code? | P3 (chunk 6 A3) | fix code |
| **Q-12** | NSC `keep(1 3 4 5)` + `update` vs CCC/CSU `keep(1 3)` — intentional NSC multi-vintage update or undocumented? | chunk 2 disc M3 | I think this is intentional, but it's Matt's code. Out of scope |
| **Q-13** | `paper/common_core_va.tex` (OLD paper version) — abandoned? Phase 1 cleanup deletes it + stale `tables/sbac/counts_k12.tex`? | T3.6 / P3-56 | old paper draft, do not touch, keep for record keeping |
| **Q-14** | Paper-mentioned but NOT-implemented restrictions in `touse_va.do:104-106` (>25% special ed, home/hospital) — were they implemented upstream in `va_samples.dta`, or never applied? | P3-48 | honestly no idea, I took this code from Matt. Might need to check upstream code |
| **Q-15** | Filipino-into-Asian silent recoding — needs ADR if survives consolidation. | P3-53 | Yes intentional |
| **Q-16** | 4 `pooledrr` definitions — Phase 1 rename to indicate scope? | P3-55 | Yes. This is exploratory code so does not impact production code, but good practice nonetheless |
| **Q-17** | Naming convention standardization for column-mapping consistency — Phase 1 sweep all `_tab.do` `mtitles` declarations vs eststo accumulation. | P2-5, P2-6, P3-62, P3-63 | Treat all irregularities in table production as intentional - the code usually includes the full range of results for completeness but end product depends on what senior coauthors want to show in the paper |
| **Q-18** | `lasd_ct_p` (5th combo in Table 6) silently dropped — intentional 4-column Table 6 layout, or oversight? | P3-62 | same as above |
| **Q-19** | `base_sum_stats_tab.do` and `sample_counts_tab.do` v1-only — intentional? | P3-57, P3-58 | Yes, this was written after v1 only decision was reached, saves runtime |
| **Q-20** | Geocoding pipeline documentation — Python `_geocoded2.csv` → Stata `_batch_geocoded.csv` rename: was production using the Python script + manual rename, or the Census Bureau's bulk batch tool? | P3-69 | No idea, Matt's code, out of scope |