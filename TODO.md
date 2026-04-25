# TODO — VA Consolidated (CEL Value-Added Project)

Last updated: 2026-04-24

## Active (doing now)

- [ ] Onboarding context-gathering with Claude (session log: `quality_reports/session_logs/2026-04-24_project-onboarding.md`)

## Up Next

- [ ] Universal hook fix in the workflow repo (handed off to user; memo at `quality_reports/reviews/2026-04-24_primary-source-hook-fix-memo.md`)
- [ ] Get user to confirm sibling-crosswalk specific do-file path inside caschls, then deep-read it as the entry point to the sibling pipeline
- [ ] Deep-read `~/github_repos/cde_va_project_fork`: starting at `do_all.do` and `settings.do`, then SBAC subdirectory (the SBAC pipeline is the entry point per Naven's readme.txt, which lists 20 numbered do-files starting with `touse_va.do`). Map every script's inputs/outputs to the paper-map's six pipelines.
- [ ] Deep-read `caschls` at the Dropbox path: `master.do`, `settings.do`, `file_dict.md`, sibling-crosswalk + factor-analysis subdirs.
- [ ] Characterize the sibling-construction vs VA-estimation circular dependency in concrete script/output terms (deferred from round 3 -- user did not remember precisely; will surface during deep-read)
- [ ] Verify filename-token glossary in `quality_reports/reviews/2026-04-24_paper-map.md` against the actual generating do-files. Tokens `las`, `sp`, `ct`, `nw`, `_m` are inferred only.
- [ ] Confirm `literature/bibtex/common_core_va.bib` location (caschls vs fork vs va_paper_clone) -- needed for paper compilation in consolidated repo.
- [ ] Draft consolidation ADRs in `decisions/`: (1) canonical sibling construction location, (2) pipeline ordering (sibling crosswalk -> VA estimation), (3) source-of-truth for student-year roster, (4) v1 vs v2 prior-score policy in the consolidated repo, (5) whether upstream CAASPP cleaning (`cleancaaspp*.do`) is in scope or treated as input.
- [ ] Fix `README.md` factual errors: repo list (two not three), caschls path (Dropbox not `~/github_repos/`), paper status (rejected/in-limbo).
- [ ] Fix `CLAUDE.md` placeholders: project name "Common Core VA", institution "California Education Lab, UC Davis", Stata 17, server-only runtime, paper file at `~/github_repos/va_paper_clone/paper/common_core_va_v2.tex`.

## Waiting On

- [ ] User confirmation of sibling-crosswalk specific path inside caschls (server hostname / project-root captured -- saved to `.claude/state/server.md` since machine-specific)

## Waiting On

- [ ] *(add blocked items here)*

## Backlog

- [ ] *(add future tasks here)*

## Done (recent)

- [x] Initialize repo from `claude-code-my-workflow` applied-micro template — 2026-04-24
- [x] Personalize template: project name, institution in CLAUDE.md; copyright in LICENSE; repo list in README.md — 2026-04-24
- [x] 5-round Q&A onboarding context-gathering with Claude (session log + paper map + MEMORY updates) — 2026-04-24
- [x] Read `paper/common_core_va_v2.tex` end-to-end; produce paper map indexing every table/figure to its expected input file — 2026-04-24
- [x] Diagnose primary-source-check hook false-positive bugs and write fix memo for workflow repo — 2026-04-24
- [x] Populate `.claude/state/primary_source_surnames.txt` with 210 surnames auto-extracted from the paper bibliography — 2026-04-24
- [x] Capture server info (Scribe SSH, project root, Stata 17) to gitignored `.claude/state/server.md` — 2026-04-24
