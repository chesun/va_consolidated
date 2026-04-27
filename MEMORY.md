# Project Memory

Corrections and learned facts that persist across sessions.
When a mistake is corrected, append a `[LEARN:category]` entry below.

---

<!-- Append new entries below. Most recent at bottom. -->

## Workflow Patterns

[LEARN:workflow] Requirements specification phase catches ambiguity before planning → reduces rework 30-50%. Use spec-then-plan for complex/ambiguous tasks (>1 hour or >3 files).

[LEARN:workflow] Spec-then-plan protocol: AskUserQuestion (3-5 questions) → create `quality_reports/specs/YYYY-MM-DD_description.md` with MUST/SHOULD/MAY requirements → declare clarity status (CLEAR/ASSUMED/BLOCKED) → get approval → then draft plan.

[LEARN:workflow] Context survival before compression: (1) Update MEMORY.md with [LEARN] entries, (2) Ensure session log current (last 10 min), (3) Active plan saved to disk, (4) Open questions documented. The pre-compact hook displays checklist.

[LEARN:workflow] Plans, specs, and session logs must live on disk (not just in conversation) to survive compression and session boundaries. Quality reports only at merge time.

## Documentation Standards

[LEARN:documentation] When adding new features, update BOTH README and guide immediately to prevent documentation drift. Stale docs break user trust.

[LEARN:documentation] Always document new templates in README's "What's Included" section with purpose description. Template inventory must be complete and accurate.

[LEARN:documentation] Guide must be generic (framework-oriented) not prescriptive. Provide templates with examples for multiple workflows (LaTeX, R, Python, Jupyter), let users customize. No "thou shalt" rules.

[LEARN:documentation] Date fields in frontmatter and README must reflect latest significant changes. Users check dates to assess currency.

## Design Philosophy

[LEARN:design] Framework-oriented > Prescriptive rules. Constitutional governance works as a TEMPLATE with examples users customize to their domain. Same for requirements specs.

[LEARN:design] Quality standard for guide additions: useful + pedagogically strong + drives usage + leaves great impression + improves upon starting fresh + no redundancy + not slow. All 7 criteria must hold.

[LEARN:design] Generic means working for any academic workflow: pure LaTeX (no Quarto), pure R (no LaTeX), Python/Jupyter, any domain (not just econometrics). Test recommendations across use cases.

## File Organization

[LEARN:files] Specifications go in `quality_reports/specs/YYYY-MM-DD_description.md`, not scattered in root or other directories. Maintains structure.

[LEARN:files] Templates belong in `templates/` directory with descriptive names. Currently have: session-log.md, quality-report.md, exploration-readme.md, archive-readme.md, requirements-spec.md, constitutional-governance.md.

## Constitutional Governance

[LEARN:governance] Constitutional articles distinguish immutable principles (non-negotiable for quality/reproducibility) from flexible user preferences. Keep to 3-7 articles max.

[LEARN:governance] Example articles: Primary Artifact (which file is authoritative), Plan-First Threshold (when to plan), Quality Gate (minimum score), Verification Standard (what must pass), File Organization (where files live).

[LEARN:governance] Amendment process: Ask user if deviating from article is "amending Article X (permanent)" or "overriding for this task (one-time exception)". Preserves institutional memory.

## Skill Creation

[LEARN:skills] Effective skill descriptions use trigger phrases users actually say: "check citations", "format results", "validate protocol" → Claude knows when to load skill.

[LEARN:skills] Skills need 3 sections minimum: Instructions (step-by-step), Examples (concrete scenarios), Troubleshooting (common errors) → users can debug independently.

[LEARN:skills] Domain-specific examples beat generic ones: citation checker (psychology), protocol validator (biology), regression formatter (economics) → shows adaptability.

## Memory System

[LEARN:memory] Two-tier memory solves template vs working project tension: MEMORY.md (generic patterns, committed), personal-memory.md (machine-specific, gitignored) → cross-machine sync + local privacy.

[LEARN:memory] Post-merge hooks prompt reflection, don't auto-append → user maintains control while building habit.

## Meta-Governance

[LEARN:meta] Repository dual nature requires explicit governance: what's generic (commit) vs specific (gitignore) → prevents template pollution.

[LEARN:meta] Dogfooding principles must be enforced: plan-first, spec-then-plan, quality gates, session logs → we follow our own guide.

[LEARN:meta] Template development work (building infrastructure, docs) doesn't create session logs in quality_reports/ → those are for user work (slides, analysis), not meta-work. Keeps template clean for users who fork.

## VA Project Domain Facts

[LEARN:domain] **v1 and v2 in this project refer to different prior test score controls for ELA and Math VA estimates — NOT to sibling vs. CFR or any other methodological distinction.** The exact grade/year choice of prior scores is in `create_prior_scores_v1.doh` and `create_prior_scores_v2.doh`. See `quality_reports/session_logs/2026-04-24_project-onboarding.md` for the explicit grade/year tables across spring-2015–spring-2018 cohorts. Wrong → right: v1/v2 ≠ CFR/sibling; v1/v2 = different prior-control grade/year combinations.

[LEARN:domain] **Repo scope for `va_consolidated` consolidation is exactly TWO predecessor repos:** (1) `~/github_repos/cde_va_project_fork` — Christina's fork of Matt Naven's `ca_ed_lab-common_core_va` (Matt no longer active; fork supersedes the original); (2) `caschls` at `/Users/christinasun/Library/CloudStorage/Dropbox/Davis/Research_Projects/Ed Lab GSR/caschls` — Christina's own VA + CALSCHLS survey work. The 2022 `common_core_va_workflow_merge` repo is OUT of scope (abandoned, did not produce anything useful). Also out of scope: `ca_ed_lab-common_core_va` itself (superseded by the fork). va_consolidated/README.md needs correction on this.

[LEARN:domain] **Paper status:** submitted to journal, rejected, currently in limbo pending coauthor/PI decision on next venue. Working draft is `commoncore_va_v2.tex` in `paper/`. A snapshot of the submitted version is in `va_paper_clone` (Overleaf clone). Christina is the sole person responsible for data and code; coauthors are senior faculty who are not involved with coding.

[LEARN:domain] **Last full-pipeline run was probably mid-2024**, NOT 2023 as initially stated in context dump §2. Evidence: `cde_va_project_fork/tables/share/va/pub/counts_k12.tex` is dated 2024-07-04; that summer's submission cycle aligns with a full run. Christina doesn't remember exactly. Consolidation bit-rot risk window: ~21 months (mid-2024 → 2026-04), not ~3 years. Stata version drift, ssc package updates, and CDE data refresh windows are all narrower than initially feared.

[LEARN:domain] **Bug 93 family is 4 instances, not 2** (initially scoped at chunk 10 NSC UC only, then expanded by Phase 0a-v2 round-2). Active locations of the operator-precedence pattern `gen X = 1 if A & B | C` (Stata: `&` binds tighter than `|`, so `C` fires regardless of `A`):
1. `cde_va_project_fork/do_files/upstream/crosswalk_nsc_outcomes.do:218-219` — `nsc_enr_uc` (UC Merced bypasses `recordfoundyn`)
2. `cde_va_project_fork/do_files/upstream/crosswalk_nsc_outcomes.do:227-228` — `nsc_enr_ontime_uc` (UC Merced bypasses `recordfoundyn` AND `enrollmentbegin`)
3. `cde_va_project_fork/do_files/merge_k12_postsecondary.doh:168-170` — `ccc_enr_ontime` (CCC ontime fires without `ccc_enr==1`)
4. `cde_va_project_fork/do_files/merge_k12_postsecondary.doh:232-234` — `csu_enr_ontime` (CSU ontime fires without `csu_enr==1`)
Phase 1 fix: wrap OR clauses in outer parens (`& ((...) | (...))`). Bundle as single patch.

[LEARN:domain] **`_scrhat_` is exploratory, not v2.** It's the third axis (predicted prior-score, `prior_ela_z_score_hat`), orthogonal to v1/v2. Generated only in `do_files/explore/va_predicted_score.do` and `va_predicted_score_fb.do`. Canonical paper uses v1, not `_scrhat_`. So `_scrhat_*` macro bugs (e.g., L342-345 `l_scrhat_spec_controls` pattern break) affect exploratory outputs only.

[LEARN:domain] **FB (forecast-bias) test structure** (per Christina 2026-04-26): (1) estimate VA without certain controls, (2) estimate VA with those controls, (3) regress (residual_no_ctrl − residual_with_ctrl) on the round-1 VA estimates. **Critical structural property**: when VA spec already includes everything (`lasd` = loscore + ACS + sibling + distance kitchen sink), there are NO leave-out variables left → no FB test possible → blank FB cells by design. `macros_va_all_samples_controls.doh:66` confirms: `va_controls_for_fb` lists 8 specs (`b l a s la ls as las`) and EXCLUDES `lasd`. There is NO `lasd_ctrl_leave_out_vars` macro. Wrong → right: column 6 (lasd) blank FB cells in paper Tables 2/3 is correct, NOT a producer bug.

[LEARN:domain] **Paper Table 2/3 row 6 attribution**: column 6 is the `lasd` (kitchen-sink + distance) VA spec column — Distance is INCLUDED IN THE VA SPECIFICATION, not used AS A LEAVE-OUT. The paper's "Distance" row shows the spec-test result for the most-saturated VA spec. Resolves the chunk-3 distance-FB-row-6 mystery: correctly NO FB rows, correctly populated spec-test row.

[LEARN:domain] **File ownership constraint for Phase 1** (Christina 2026-04-26): "leave Matt Naven's files as-is; only fix code Christina owns." Specifically OUT-OF-SCOPE for Phase 1 modification: NSC/CCC/CSU crosswalks (`crosswalk_{nsc,ccc,csu}_outcomes.do`), `merge_k12_postsecondary.doh`, `gecode_json.py` (Christina confirmed Matt-authored), other Matt-originated files. **Implication**: Bug 93 family stays UNFIXED; CCC ontime / CSU ontime operator-precedence bugs stay UNFIXED; Naven hardcoded user-machine paths in CCC/CSU stay UNTOUCHED. Path resolution still works on Scribe (paths are literally Scribe paths). Christina's wrappers that consume Matt's data (e.g., `mattschlchar.do`) ARE editable.

[LEARN:domain] **`mattschlchar.do` I/O lineage**: Christina-authored wrapper (header L4-5: "written by Che Sun"). IS production code — wired into `master.do:412`; produces `$projdir/dta/schoolchar/schlcharpooledmeans.dta` consumed by `indexregwithdemo.do:37` (paper Table 8 Panel A) and `indexhorseracewithdemo.do:41` (paper Table 8 Panel B). Reads `$projdir/dta/schoolchar/mattschlchar.dta` which originates from Matt's user dir `/home/research/ca_ed_lab/msnaven/common_core_va/data/sch_char` (gated by `local clean = 0` toggle; current production runs use a pre-built copy).

[LEARN:workflow] **Consolidate-first-fix-bugs-later** is the cleaner Phase 1 approach. Three sub-phases: (1a) consolidate, behavior-preserving, byte-equivalent output target; (1b) fix bugs, paper-affecting first then code-quality; (1c) cosmetic cleanup. Replication target = predecessor outputs (with all bugs intact) so consolidation can be verified by output diff. Constraint: Phase 0e Q&A walkthrough must complete before Phase 1 plan can be locked.

## Discipline

[LEARN:discipline] **No assumptions.** Global rule (~/github_repos/claude-config/rules/no-assumptions.md) prohibits guessing about workflow, infrastructure, tools, role boundaries, or preferences. Only state what was explicitly provided. If a detail is missing and relevant, ask or omit — never fill blanks with plausible-sounding inference. Wrong → right: never reframe ambiguous user terminology (e.g., v1/v2) by analogy to other projects; ask what it means.

[LEARN:discipline] **Verification protocol catches confirmation-bias errors in BOTH directions.** Phase 0a-v2 surfaced two false positives within the first 3 chunks: round-2 chunk-2 mis-claimed `asd_str` typo still active (was fixed in `e8dd083`); round-1 chunk-2 mis-claimed `peer_L3_cst_ela_z_score` missing from `create_va_sample.doh` keepusing list (it IS at L29). Both caught by T3 deterministic file-read. Lesson: independent re-derivation works because the bias mode (anchor on prior framing) is asymmetric across rounds; either round can err. Don't assume either is the "trusted source."

[LEARN:discipline] **Temporal artifacts vs. true contradictions.** When two audits disagree, first check whether intervening fixes occurred between the audits (git log on the artifact). Phase 0a-v2 chunk 1 had two such cases: vam.ado customization status (round-1 wrote pre-noseed-fix; round-2 wrote post-fix) and macros_va.doh missing-`;` location (round-1 found L558 fixed in `e8dd083`; round-2 found still-open L23). Both resolved cleanly to "both rounds correct in their respective time slices."
