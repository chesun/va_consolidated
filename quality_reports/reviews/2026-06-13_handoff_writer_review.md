# HANDOFF.md Review — writer-critic

**Date:** 2026-06-13
**Reviewer:** writer-critic
**Target:** HANDOFF.md
**Score:** 93/100
**Status:** Active

---

## Scope note

Target is a plain-Markdown onboarding/handoff document for an incoming PI (Paco) who knows
Stata but is new to git and Claude Code. LaTeX/compilation/citation/AEA-form rubric rows do
not apply and were skipped. Review focuses on: clarity and correctness for the audience,
claims-evidence alignment in §3, anti-AI-prose (`docs` voice profile), internal consistency
(cross-references, §-numbering, command/path consistency), structure/completeness, and the
MacDown blank-line-before-lists rule.

The §3 numeric claims were NOT independently re-derived (per instruction). They were assessed
for defensibility, internal consistency, and whether the stated audit trail makes them
checkable. Repo-side facts that *were* spot-checked: decision-record count, review-report
count, scribe-setup plan existence, and every `do/main.do` reference (toggle names, line
numbers, `installssc`, `m4_acceptance_run`).

---

## Verification performed (repo cross-checks)

| Claim in HANDOFF | Checked against | Result |
|---|---|---|
| "30 numbered decision records in `decisions/`" | `ls decisions/*.md` | 30 numbered ADRs present (0001–0030, no gaps), plus `README.md`. **Matches.** |
| "Over 50 full review reports in `quality_reports/reviews/`" | glob of `quality_reports/reviews/*.md` | ~65 review/triage `.md` files. **Defensible ("over 50").** |
| scribe-setup guide at `quality_reports/plans/2026-05-25_scribe-setup.md` (§7, §10) | glob | File exists at that exact path. **Matches.** |
| Phase toggle names (§6 code block) | `do/main.do:137-143` | All seven names identical: `run_data_prep`, `run_samples`, `run_va_estimation`, `run_va_tables`, `run_survey_va`, `run_paper_outputs`, `run_data_checks`. **Matches.** |
| "look near the top (around line 130–190)" (§6) | `do/main.do` | Toggles at 137-143; override block 167-190. **Matches.** |
| "master override near line 167: `local m4_acceptance_run 1`" (§6) | `do/main.do:167` | `local m4_acceptance_run  1` at line 167. **Matches.** |
| "set `installssc` to `1` … then set it back to `0`" (§10) | `do/main.do:91-93` | `local installssc = 0`; install block guarded by `if installssc==1`. **Matches.** |
| Phase 4 "intentionally empty … produced in Phase 6 … kept as a numbered phase" (§5) | `do/main.do:140` inline comment | Comment says exactly this. **Matches.** |
| Seven-phase structure (§5) | `do/main.do` phase guards | Seven `run_*` phases in order. **Matches.** |
| `stata-mp` invocation used everywhere (§2, §5, §10) | CLAUDE.md (Scribe uses `stata-mp`; `stata17` alias is local-only) | Consistent; correct command for the server. **Matches.** |

No discrepancies between the doc's instructional claims and the repository. This is the
load-bearing part of a handoff and it holds up.

---

## Findings

### HIGH

None. No factual error, no broken instruction, no cross-reference that resolves wrong.

### MEDIUM

**M1 — §3 numbers are attributed but only partially trail-checkable; one is asymmetric.**
Three of the five §3 numbers point at a verifiable trail: "30 decision records" (`decisions/`),
"over 50 review reports" (`quality_reports/reviews/`), and "135 commits … `git log
--grep="coder-critic"`" (a runnable command). Good — those are stated defensibly. But the two
headline golden-master numbers — **8,324 output files compared** and **3,166 estimate files
with zero differences** — are attributed only to "the golden-master triage report" in
`quality_reports/reviews/` without naming the file. A reader who wants to audit "8,324" has to
guess which report (the relevant one is `2026-06-10_m4-full-golden-master_triage.md`). This is
the one §3 claim where the doc asserts a precise number but does not hand the reader the exact
artifact. Recommend naming the triage file inline at line 60, the same way §7/§10 name
`2026-05-25_scribe-setup.md`. Not an overclaim — the numbers read as defensible and the report
exists — but the citation is looser than the rest of §3. *Severity: Medium. Suggestion, not a
deduction-driver beyond the small consistency ding below.*

**M2 — "byte-for-byte" / "byte-identical" coexists with "matched exactly" for estimates; make
the two claims' strength explicit.** §3 says paper-facing tables/figures are "identical …
(byte-for-byte)" but the 3,166 estimate files "matched exactly: zero differences in
coefficients or standard errors." These are two *different* equality standards (byte-identity
vs. numeric-equality-of-reported-quantities), and an auditor reading carefully will notice the
estimate claim is the weaker of the two. That is almost certainly the honest and correct
distinction (`.ster`/`.dta` files legitimately differ in non-substantive bytes), but a skeptical
reader could read "matched exactly" as overclaiming byte-identity. One clause — e.g., "matched
exactly on every coefficient and standard error (the estimate files themselves can differ in
non-substantive metadata bytes)" — would pre-empt the question. *Severity: Medium.*

### LOW

**L1 — §1 forward-references §9 before the reader knows what §9 is, twice.** §1 (line 13) and
§9 (line 261) both say the paper "is finished and being submitted to a new journal as-is."
The §1 mention forward-points to §9 for the paper's location; fine. Minor redundancy: the
"finished / submitted to a new journal as-is" sentence appears nearly verbatim in both places.
Acceptable in a handoff (repetition aids a skimming reader), flagged only for awareness.
*Severity: Low.*

**L2 — `git pull --rebase` in §7 is the recommended sync but the repo's destructive-actions
guard blocks non-resumption rebases.** §7 Option B line 207 tells Paco `git pull --rebase
origin main`. The project's `destructive-actions.md` guard treats `git rebase` (non-resumption)
as always-blocked — but it explicitly notes `git pull --rebase` is *not* matched (the command
string is `git pull`, not `git rebase`). So the instruction is technically safe under the guard.
However, for a git-novice on a shared server, `--rebase` can produce confusing mid-rebase states
if there are local commits and conflicts. Consider a one-line caveat or a plain `git pull` for
the novice path. *Severity: Low (clarity/safety for the stated audience).*

**L3 — "the data is restricted and never goes to GitHub" mechanism is asserted in §7 but the
guard's exact behavior is paraphrased.** §7 line 215 quotes the guard message `refusing to push
— restricted data files...`. Good that it's quoted so Paco recognizes it. No correction needed;
noting that this is the kind of operational detail that ages — if the guard message string
changes, this line silently goes stale. Consider phrasing as "a message about refusing to push
restricted data" rather than a verbatim quote. *Severity: Low.*

**L4 — `tail -f log/main_$(date +%d-%b-%Y)_*.smcl` assumes the run started *today*.** §5 line
126 gives a live-follow command keyed to the current date. If Paco starts a run before midnight
and checks it after midnight, or checks a run someone else started yesterday, the glob misses.
A date-agnostic `tail -f $(ls -t log/main_*.smcl | head -1)` is more robust. Minor; the current
form works for the common case. *Severity: Low.*

---

## Anti-AI-prose assessment (`docs` voice profile)

The humanizer pass reads clean. Specific checks:

- **Em-dash density (S1, Critical threshold >2/100 words):** Em-dashes are present but sparse and
  used for genuine emphasis/aside ("file by file", "not anecdotal"). Well under threshold. PASS.
- **Tricolon / rule-of-three overuse (S2):** §2 "which scripts to run, inside which project
  folder, in what order, and how each script's output fed the next" is a four-item list, not a
  rote tricolon. §3 "what was changed, why, and who checked it" is a single deliberate tricolon,
  not a default rhythm. No overuse. PASS.
- **Signposting filler / throat-clearing (R1/R2):** None. The doc opens each section with
  substance ("This is the complete Stata pipeline…", "Everything here happens on Scribe…"). No
  "it is worth noting", "of course", "in today's…". PASS.
- **AI vocabulary cluster (L1: delve/navigate/leverage/foster/underscore/landscape):** None
  found. PASS.
- **Significance inflation (C1):** None — claims are concrete and quantified, not "pivotal" /
  "robust" puffery. The QC section earns its confidence with numbers. PASS.
- **Bullet-point thinking / rote connectives (T2):** Transitions are reasoning-driven
  ("So in practice:", "The catch:", "Rule of thumb:"), not "Furthermore/Moreover/Additionally"
  chains. PASS.
- **Uniform sentence rhythm (S4):** Good burstiness — short directive sentences ("That's the
  safety net working.") alternate with longer explanatory ones. PASS.
- **Decorative punctuation / emoji (M3):** None. The tree diagrams use plain ASCII. PASS.
- **Copula avoidance / "serves as" (L4):** None. Plain "is". PASS.

The voice is direct, second-person where appropriate for docs, and reads like a person who
built the thing explaining it to a successor. No residual AI tells. This subsection contributes
zero deduction.

---

## MacDown / Markdown rendering

Spot-checked blank-line-before-list compliance (the project's MacDown-compat rule):

- §2 "How we resolved it" list (line 39) — preceded by blank line after `### How we resolved it`. PASS.
- §3 Layer-2 bullet list (line 65) — blank line before. PASS.
- §3 Layer-3 evidence list (line 80) — blank line before. PASS.
- §5 "What the run does" ordered list (line 134) — blank line before. PASS.
- §8 code-block tree and the two follow-up bullets (line 245) — blank line before. PASS.
- §10 bullets and "Want more detail?" list — blank line before. PASS.

All lists render. Code fences are balanced and language-tagged (`bash`, `stata`). No
Markdown defects.

---

## Structure and completeness

- **Section numbering 1–10 is contiguous and consistent.** Cross-references resolve: §1→§9
  (paper), §3 Layer-2→§5 phase list, §5→§3 Layer-2, §6→§2 (reproducibility fix), §7→§10
  (scribe-setup), §8→§2/§3, §9→pipeline outputs, §10→`decisions/`, `quality_reports/`,
  scribe-setup. Every internal "(see §N)" points to a section that contains the referenced
  material. PASS.
- **Completeness for a handoff:** covers what/why/how-correct/how-to-run/partial-runs/sync/
  layout/paper/troubleshooting. The "two places the code lives" mental model (§4) is exactly the
  conceptual scaffold a git-novice needs before §7. Strong.
- **One small completeness gap (informational, not deducted):** the doc never states the Stata
  *version* on Scribe (CLAUDE.md flags the server "may use Stata 18 with older package
  versions"). §10 says "ask the lab how Stata is set up" as the fallback, which covers it, but a
  one-line "the pipeline was validated under Stata MP 18 on Scribe" (if true) would save Paco a
  question. Optional.
- **Redundancy:** the "paper finished / new journal as-is" sentence and the "you already have
  access to the project folder on Scribe" sentence each appear ~3x. In an onboarding doc this is
  defensible repetition for skimmers; not flagged as a defect.

---

## Compliance evidence

- **Adversarial-default:** This is a Markdown handoff, not the LaTeX manuscript, so the
  `(paper/main.tex, bibliography-resolves)` ledger row does not gate it. The §3 quality-control
  claims are the compliance-adjacent assertions; their backing was checked against the repo
  (decisions count, review-report count, main.do references, scribe-setup plan existence) rather
  than taken on assertion. Where a number could not be re-derived (8,324 / 3,166 / 135 commits),
  the doc attributes it to a named or runnable trail; the only weakness is M1 (triage file not
  named inline).
- **Derive-don't-guess:** Every repo-side fact the doc states (paths, toggle names, line
  numbers, file counts) was looked up, not assumed — see the verification table above. All
  resolved.

---

## Scoring

Markdown-adapted rubric (LaTeX/AEA rows skipped). Starting from 100:

| Issue | Deduction |
|---|---|
| M1 — §3 8,324/3,166 numbers cite an unnamed triage file (looser than rest of §3; recommend inline filename) | -3 |
| M2 — "matched exactly" vs "byte-for-byte" equality strengths not made explicit (skeptical reader could read as overclaim) | -2 |
| L1 — minor §1/§9 redundancy on paper status | -0 (noted, not deducted) |
| L2 — `git pull --rebase` recommended to a git-novice without a conflict caveat | -1 |
| L3 — verbatim guard-message quote can age | -1 |
| L4 — date-keyed `tail -f` glob misses cross-midnight / others' runs | -0 (works for common case; noted) |
| Anti-AI-prose | -0 (clean) |
| MacDown / rendering | -0 |
| Cross-reference / numbering consistency | -0 |

**Total deduction: -7. Score: 93/100.**

This is a strong handoff. Every instruction is correct against the actual `do/main.do`, every
cross-reference resolves, the §3 evidence claims are attributed to a real and auditable trail,
and the prose is clean of AI tells. The deductions are polish-level: name the golden-master
triage file inline (M1), and add one clause distinguishing "byte-identical figures" from
"exact-match estimates" (M2). Neither blocks use of the document.
