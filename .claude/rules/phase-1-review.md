# Phase 1 Review Protocol

**Scope:** All commits during Phase 1 consolidation that touch `do/**/*.do`, `do/**/*.doh`, `main.do`, `settings.do`, `ado/`, or `py/upstream/**/*.py`.
**Status:** Active 2026-04-28; sunsets at `v1.0-final` tag (per ADR-0018).

This rule operationalizes `.claude/rules/agents.md` §1 (Adversarial Pairing) for the Claude+Christina pair-flow during Phase 1. The orchestrator pipeline is not running; instead, every load-bearing code change is **manually paired with `coder-critic`** before commit, with a hard 80/100 gate.

The rule exists to guard against three specific failure modes Christina flagged 2026-04-28:

1. **Bias** — Claude defends its own choices when asked to self-review. `coder-critic` runs with fresh context, no prior conversation on why the change was made. Independent evaluation against the rubric, not against Claude's reasoning.
2. **Mistakes** — Path-reference drift, off-by-one errors, missed callers, scope creep. The 12-category rubric (per `agents.md`) catches the common classes.
3. **Fabrication** — Claude confidently writes `assert _N == 1784445` but the design memo says `1784444`; or cites a codebook line that doesn't say what's claimed. `coder-critic` reviews assertions against their cited sources.

---

## 1. Tiered defense — when each layer fires

| Layer | Mechanism | Fires on | Cost | Catches |
|---|---|---|---|---|
| **Tier 1: Self-check** | Pre-commit checklist below | Every in-scope commit | ~30 sec | Path drift, scope creep, missing ADR cite |
| **Tier 2: `coder-critic`** | Agent dispatch via Task tool | Substantive code changes (table below) | ~2-3 min | Strategic misalignment, fabricated assertions, code-quality issues |
| **Tier 3: Data-checks pipeline** | `do/check/check_*.do` (per plan v3 §5.3) | Every `main.do` run on Scribe | Pipeline runtime | Empirical regressions: sample sizes, ranges, merge rates |
| **Tier 4: Golden-master** | One-shot M4 verification | End of Phase 1a | Hours (full pipeline twice) | Behavioral mismatch predecessor vs consolidated |

Tiers 1 + 2 are this rule's contribution. Tiers 3 + 4 already exist in plan v3.

---

## 2. Tier 1 — Pre-commit self-check (every in-scope commit)

Before staging any in-scope change, run through this checklist:

- [ ] **Source identified.** If relocating, the original predecessor-repo path is known and recorded in the commit message.
- [ ] **Destination matches plan.** Per CLAUDE.md folder map + plan v3 §3.3 step ordering. No invented locations.
- [ ] **Path references updated.** `grep -rn` confirms no stale references to the old path remain in tracked files.
- [ ] **Scope minimal.** Diff contains only what the commit message describes. No unrelated cleanup riding along.
- [ ] **ADR cited.** If the change implements an ADR (e.g., ADR-0005 for `siblingoutxwalk.do` relocation, ADR-0011 for sums→means), the ADR number appears in the commit message.
- [ ] **For bug fixes specifically:** the fix matches the ADR's prescribed change. Diff is minimal. Affected upstream/downstream callers identified.
- [ ] **For new `check_*.do` files specifically:** every `assert` cites the design memo line range that justifies its bound, OR carries a `// TBD-codebook` marker.

A commit that fails any item gets fixed, not committed.

---

## 3. Tier 2 — `coder-critic` dispatch matrix

| Change type | Dispatch? | Notes |
|---|---|---|
| Phase 1a §3.3 file relocation | **YES** | Catches dropped reference, wrong destination, scope creep |
| Phase 1b §4.1 paper-text correction | NO (writer-critic instead) | Wrong tool — `writer-critic` for `.tex` |
| Phase 1b §4.2 code correction (paper-affecting) | **YES — REQUIRED** | Paper-affecting; highest-stakes layer |
| Phase 1b §4.3 naming/clarity | YES if multi-file | Single-file rename: self-check is enough |
| Phase 1b §4.4 P3 typos | NO | Self-check is enough; data-checks catch anything load-bearing |
| Phase 1c §5.1 dead-code archival | NO | Self-check is enough |
| Phase 1c §5.2 README rewrite | writer-critic | Wrong tool |
| Phase 1c §5.3 new `check_*.do` file | **YES — REQUIRED** | Asserts must trace to design memo line refs |
| Phase 1c §5.4 acceptance run | verifier (submission mode) | Different agent; pre-`v1.0-final` audit |
| ADR file (`decisions/NNNN_*.md`) | NO | ADR governance + primary-source-first hook handle this |
| Session log / TODO / SESSION_REPORT | NO | Documentation; no coder-critic role |
| Folder stub (`.gitkeep`) | NO | Zero behavior change |
| Plan v3 / quality_reports/* edits | NO | Documentation; out of scope |

When in doubt: dispatch. Cost is low; missing a real bug is high.

---

## 4. Hard gate — score < 80 blocks commit

Per `.claude/rules/quality.md` §1, the project default is hard gate at 80/100. Phase 1 inherits this for code commits.

**Procedure when `coder-critic` returns score < 80:**

1. Read the deduction list. Each item has a severity (Critical / Major / Minor) and a rationale.
2. Address every Critical and every Major. Minor items may be deferred IF deferring them doesn't change the score above 80, AND a TODO entry is added.
3. Re-stage; re-dispatch `coder-critic` on the new diff.
4. Repeat. **Max 3 rounds per commit** (per `agents.md` §3 three-strikes rule). After round 3, if still failing, escalate to Christina with a written summary of what each round changed and why convergence failed.

**Procedure when `coder-critic` returns score ≥ 80:**

1. Note the score in the commit message footer (see §5).
2. Address any Critical findings even if they don't drop the score below 80 — gate is a floor, not a ceiling.
3. Commit + push.

---

## 5. Commit message footer convention

Every in-scope commit carries one of these footers (immediately above the `Co-Authored-By:` line):

```
coder-critic: PASS (89/100)
```

```
coder-critic: PASS (84/100); deferred Minor finding — added to TODO.md backlog.
```

```
coder-critic: skipped (cosmetic typo; rationale: P3-15 single-line fix; data-checks Tier 3 covers regression).
```

```
coder-critic: round 2 — PASS (82/100) after addressing path-update Major finding.
```

The footer is grep-able: `git log --grep='coder-critic'` produces the audit trail of every code change's review status. Successor reading the history sees the gate enforced commit-by-commit.

---

## 6. Dispatch prompt template

When dispatching `coder-critic` via the Task tool, the prompt MUST include:

1. **The change** — paths modified, key diff (or full diff if small).
2. **The strategy/spec the change implements** — which ADR(s), which plan v3 section, which design memo if applicable.
3. **The phase + change type** — so severity calibration matches (Phase 1a relocations = strict; Phase 1b paper-affecting = strictest).
4. **Hard-gate threshold reminder** — `score < 80 blocks commit`.

Template skeleton (paraphrased; agent's own task description always primary):

> Review the following code change for the va_consolidated Phase 1 consolidation. **Phase 1[a/b/c] §[X]; change type: [relocation / bug-fix / new-check-file].** Hard gate at 80/100; flag any Critical or Major issue.
>
> **Implements:** ADR-NNNN ("..."); plan v3 §[X]; design memo `quality_reports/reviews/2026-04-28_data-checks-design.md` §[X] (if applicable).
>
> **Files changed:** [list]
>
> **Diff:** [content or `git diff` reference]
>
> **Specific concerns to verify:**
>   - [path references match plan v3 §3.3 step order]
>   - [assertion bounds trace to design memo line refs]
>   - [no scope creep — diff matches commit-message scope]
>   - [ADR alignment — is the change exactly what the ADR prescribed?]

---

## 7. Exceptions (when this rule does NOT apply)

- **Hot-fix during golden-master verification.** If the M4 golden-master fails and the fix is a one-line correction to a relocated file's path, self-check is enough. Document in session log.
- **Cosmetic-only commits.** Single-line typo, single-file rename with grep confirming no callers, dead-code archival to `do/_archive/dead/`. Self-check is enough; record rationale in commit footer.
- **Files Christina has explicitly carved out** — Matt Naven's files per ADR-0017 are out of scope for Phase 1 edits anyway, so coder-critic dispatch on them is moot.
- **Sunset at `v1.0-final`.** This rule applies to Phase 1 only. Post-tag, the consolidated repo is a frozen archive; no further commits expected per ADR-0018.

---

## 8. Relationship to other governance

- **`.claude/rules/agents.md` §1 Adversarial Pairing** — this rule is the manual-flow translation of that orchestrator-flow requirement.
- **`.claude/rules/quality.md` §1 Scoring + §3 Per-Target Deduction Tables** — `coder-critic` uses these tables; no per-Phase-1 modifications.
- **`.claude/rules/primary-source-first.md`** — orthogonal protection. The hooks fire on file edits + Stop; this rule fires on commits. Both apply to Phase 1 work.
- **`.claude/rules/verification-protocol.md`** — fires on every routine task boundary (compile/run check). Cheaper than `coder-critic`; runs first. If verification fails, fix before dispatching critic.
- **Plan v3 §5.3 data-checks pipeline** — Tier 3 in §1 above. Empirical regression check; complements `coder-critic`'s strategic-alignment check.
- **Plan v3 §3.5 + ADR-0018 acceptance criteria** — Tier 4. Once-per-phase verifications. The verifier agent (submission mode) handles these.

---

## 9. Audit trail

By the end of Phase 1, every code commit carries a `coder-critic:` footer. `git log --grep='coder-critic'` is the index. Any commit without the footer is either (a) out of scope per §1 (docs / ADRs / stubs) or (b) a violation — investigate and document in a session log.

The successor inheriting the repo can `git log --grep='coder-critic'` to see the discipline applied. Combined with the ADR ledger and the design memo, this is the audit trail of how the consolidated repo came to be in the state it is.
