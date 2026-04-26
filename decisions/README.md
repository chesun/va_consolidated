# Design Decisions Log

An append-only record of substantive research, design, and methodology decisions for this project. Each entry is an **ADR** (Architecture Decision Record, borrowed from software engineering): short, dated, immutable.

This log is the *record*. Analysis docs in `quality_reports/` are the *reasoning*. When we need to know **what** was decided, read here. When we need to know **why** in depth, follow the Sources link.

**Rule:** `.claude/rules/decision-log.md`.

---

## Rules

1. **One decision per file.** Numbered `NNNN_short-slug.md`, zero-padded to four digits.
2. **Never edit a Decided entry.** If the decision changes, write a new ADR whose Status is `Decided` and whose header links the prior entry: `Supersedes: #0008`. Then edit the old entry's Status to `Superseded by #NNNN`. The body of the old entry stays.
3. **Proposed entries may be edited** until they become Decided. Once Decided, rule 2 applies.
4. **Reference by number.** In session logs, analysis docs, and commit messages, cite decisions as `ADR-0008`. This is durable across file renames.
5. **Data quality flag is required.** "Full context" = source docs contain explicit reasoning. "Reconstructed — partial context" = date and decision are clear, but reasoning was retrofitted. Future-you needs to know which.
6. **Scope is a recommended field.** Each decision serves a specific component of the research — tagging the scope helps prevent conflating unrelated decisions and makes the log navigable by theme.

## Decision components

Tag each ADR with a single scope. Suggested categories depend on the research paradigm:

**Behavioral / experimental projects:**

- **Research framing** — what the paper is about; hypothesis choices.
- **IC foundation** — theoretical assumptions that make the mechanism incentive-compatible.
- **Behavioral theory** — frameworks explaining *why* subjects fail or succeed.
- **Experimental design** — arm structure, treatments, controls, instruments.
- **Methodology** — analysis metrics, ε tolerances, format choices, instructions.

**Applied micro / reduced-form projects:**

- **Research framing** — question, outcome, population.
- **Identification** — source of exogenous variation, exclusion restriction, parallel trends.
- **Data** — sample construction, restrictions, merges, cleaning rules.
- **Specification** — functional form, controls, fixed effects, interactions.
- **Inference** — clustering, weights, multiple-testing correction, confidence-interval method.

Not every ADR needs to be perfectly tagged — some decisions cut across components — but tag it when the scope is unambiguous.

---

## When to write a new ADR

Write one when any of the following becomes true:

- A research framing or hypothesis choice is locked.
- A design parameter is committed (sample size, arm structure, instrument format, specification).
- A methodological choice is made (estimator, metric, clustering, tolerance).
- A scope decision excludes a candidate.

Do **not** write an ADR for:

- Literature reading progress or individual paper summaries.
- Code, repo setup, or file-path logistics.
- Tentative thoughts that haven't been committed to. Draft those in a session log or analysis doc first; promote to an ADR once settled.

---

## Entry template

```markdown
# NNNN: [Decision title, <= 80 chars]

- **Date:** YYYY-MM-DD
- **Status:** Decided | Proposed | Superseded by #NNNN
- **Scope:** [one category]
- **Data quality:** Full context | Reconstructed — partial context
- **Supersedes:** #NNNN (optional)

## Context
1-3 paragraphs. What problem? What constraints? What prompted this now?

## Decision
The decision, stated crisply. Bullet points OK.

## Consequences
What this commits us to. What it rules out. Open questions it creates.

## Sources
- path/to/file.md :: section or line range
- Git commit hash if relevant
```

---

## Index

| ID | Title | Date | Status | Scope |
|----|-------|------|--------|-------|
| [0001](0001_consolidation-scope.md) | Consolidation scope — two predecessor repos in scope | 2026-04-25 | Decided | Infrastructure |
| [0002](0002_runtime-server-only.md) | Runtime — Scribe server only, hostname-branched settings | 2026-04-25 | Decided | Infrastructure |
| [0003](0003_languages-stata-primary-python-upstream.md) | Languages — Stata primary; Python preserved for upstream geocoding | 2026-04-25 | Decided | Methodology |

---

## Pending decisions (tracked, not yet committed)

Decisions that need to happen but aren't resolved. They get an ADR when resolved, not before.

The full list of expected ADRs (with proposed slugs) lives in
`quality_reports/plans/2026-04-25_consolidation-plan-draft.md` §5. Items deferred until Phase 0 deep-read completes:

- **0004** sibling-xwalk canonical location (siblingoutxwalk relocation depends on dependency trace)
- **0005** pipeline order (locks after Phase 0b dependency graph)
- **0006** prior-score policy v1-canonical / v2-preserved (locks after VA core deep-read)
- **0007** upstream-data-prep convention
- **0008** local-script convention
- **0009** custom vam ado handling (after .ado deep-read in Phase 0a)
- **0010** paper source-of-truth
- **0011** output paths mirror paper expectations
- **0012** settings.do hostname branching pattern
- **0013** cohort coverage 2014-15 to 2017-18
- **0014** entry-point naming (main.do vs do_all.do — locked direction is main.do)
- **0015** Stata version pin
- **0016** server canonical folder (resolved via Phase 0d server reconciliation)
