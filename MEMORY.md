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

## Discipline

[LEARN:discipline] **No assumptions.** Global rule (~/github_repos/claude-config/rules/no-assumptions.md) prohibits guessing about workflow, infrastructure, tools, role boundaries, or preferences. Only state what was explicitly provided. If a detail is missing and relevant, ask or omit — never fill blanks with plausible-sounding inference. Wrong → right: never reframe ambiguous user terminology (e.g., v1/v2) by analogy to other projects; ask what it means.
