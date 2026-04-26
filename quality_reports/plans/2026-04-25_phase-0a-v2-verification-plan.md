# Phase 0a-v2 Execution Plan — Independent Blind Verification

**Status:** DRAFT (awaiting Christina's signoff before execution)
**Author:** Christina Sun (with Claude)
**Date drafted:** 2026-04-25
**Predecessor plan:** `quality_reports/plans/2026-04-25_consolidation-plan-draft.md` (v2)
**Predecessor audit:** `quality_reports/audits/round-1/` (sequestered)

---

## 1. Why this plan exists

**Christina's directive (verbatim, 2026-04-25):**

> "Next I want to launch an independent round of comprehensive review to verify every single finding in the first round of audit. This is because I have previously experienced agents having confirmation bias and forming echo chambers or losing details/inventing details when synthesizing. Since this consolidation is complex and load bearing, it needs to be ABSOLUTELY ROCK SOLID with NO ROOM FOR DOUBT."

**Christina's residual-bias clarification (2026-04-25):**

> "if something is genuinely uninterpretable in both rounds, raise it to me and I will investigate"

The consolidation will reorganize ~150 files across two predecessor repos. If a Phase 0a finding is wrong (e.g., a missed dependency, an over-claimed bug scope, an inverted naming convention), the error propagates into Phase 1 migration and surfaces as broken outputs during verification — costing 1-2 weeks of debugging at minimum. The asymmetric cost favors heavy upfront verification.

**Pre-flight already justified the approach.** Manual T3 verification of Bug 93 (the chunk-10 flagship paper-load-bearing bug) caught a 50% over-claim:

- Round-1 chunk-10 claim: bug at lines 219, 222, 228, 232 of `crosswalk_nsc_outcomes.do`.
- Direct reading: lines 222 and 232 have **protective outer parentheses** (`& (... | ... | ...)`); only lines 218-219 and 226-228 lack the parens. Real scope is 2 paper outcomes (`nsc_enr_uc`, `nsc_enr_ontime_uc`), not 4.
- This level of error in a paper-load-bearing finding would have propagated misinformation about which outcomes are affected. The verification approach worked.

---

## 2. Scope

**Re-verify every Phase 0a finding** across all 10 chunks. Per Christina: "every single finding."

| Chunk | Round-1 high-stakes finding to re-verify | Round-1 doc (sequestered) |
|---|---|---|
| 1 (foundation) | N2 (two-folder server geometry); vam = unmodified Stepner v2.0.1; macros_va.doh `asd_str` and missing-`;` bugs (already fixed) | `round-1/2026-04-25_deep-read-audit.md` §Chunk 1 |
| 2 (helpers) | v1/v2 prior-score table; sample-restriction map; ACS data flow; `_scrhat_` orthogonality; bugs in `vaestmacros.doh` and `merge_k12_postsecondary.doh` | round-1 §Chunk 2 |
| 3 (VA core) | Output-filename grammar; spec-test/FB-test β tracing; drift_limit semantics; vam invocation pattern | round-1 §Chunk 3 |
| 4 (pass-through) | Paper Tables 4/5/7 producers; pass-through ρ canonical spec; SE clustering audit; `_m`/`_wt`/`_nw` resolution; 15 anomalies including `run_prior_score=0` gate | round-1 §Chunk 4 |
| 5 (sibling) | **N1 verdict (SAFE to relocate `siblingoutxwalk.do`)**; sibling-matching specifics; 4-spec convention; positional-arg semantics | `round-1/2026-04-25_chunk5-sibling.md` (1168 lines) |
| 6 (survey VA) | Paper Table 8 producer chain; index construction sum-vs-mean discrepancy; Cronbach α file; `mvpatterns` package | `round-1/2026-04-25_chunk6-survey-va.md` (872 lines) |
| 7 (data prep) | **Distance-FB Row 6 (`d` token wiring)**; ACS years 2010-2013 only; school-char dependency tree; `enrollmentclean.do:21` female-encoding bug | `round-1/2026-04-25_chunk7-data-prep.md` |
| 8 (samples) | **Sample-restriction map finalization** (`<7` vs `<=10`); `gr11enr_mean` weight chain; archive disposition for `sum_stats.do` | `round-1/2026-04-25_chunk8-samples.md` |
| 9 (share) | **All paper-output producer mappings**; scrhat exploratory pipeline; CSV→TeX writers; `va_predicted_score_fb.do:43` bug | `round-1/2026-04-25_chunk9-share-explore.md` (477 lines) |
| 10 (upstream) | **Bug 93 NSC UC inlist precedence** (pre-flight already corrected to 2 outcomes); geocoding pipeline; external-static-inputs list | `round-1/2026-04-25_chunk10-upstream.md` |

---

## 3. Four-tier verification structure

Per the agreed plan after Christina's confirmation-bias question:

| Tier | What's verified | Adjudicator | Bias risk |
|---|---|---|---|
| **T1 — Empirical (gold standard)** | Bug 93 scope; Distance-FB `d` token wiring; v1/v2 prior-score variable construction; vam factor-variable runtime behavior | **Christina, by running ≤15 lines of Stata on Scribe** and sharing output | None — mechanical truth |
| **T2 — Adversarial third agent** | Discrepancies between rounds 1 and 2; high-stakes claims about paper-output mappings, sample-restriction map, output-filename grammar | Independent third agent with explicit "find evidence the claim is wrong" brief; burden of proof on the claim | Low (independent dispatch + adversarial framing) |
| **T3 — Objective code facts** | Line numbers, syntax declarations, file existence, byte-identical diffs, presence/absence of specific patterns | Direct reading + deterministic checks (`grep`, `sed`, `wc`, `diff`) | Near-zero — deterministic |
| **T4 — User investigation (residual)** | Cases genuinely uninterpretable in rounds 1, 2, AND adversarial agent — i.e., shared misinterpretations of ambiguous primary source | **Christina with full domain knowledge** | None — domain expert as last line of defense |

---

## 4. Step-by-step execution

### Step 0 — Setup [DONE]

- [x] Sequester round-1 audit docs to `quality_reports/audits/round-1/` (commit `fa07571`)
- [x] Create `quality_reports/audits/round-2/` with protocol README (`fa07571`)
- [x] Pre-flight Bug 93 verification (T3) (`fa07571`)
- [x] This plan committed before any round-2 agent dispatched

### Step 1 — Dispatch round-2 agents (10 agents, parallel-batched)

**Sequencing**: parallel-batched by 3-4 agents at a time to manage compute load. Each agent is heavy (round-1 each took 30-60 min). 4 batches of 2-3 chunks each = 2-4 hours wall-clock.

**Batch order** (by chunk dependency / scope):

| Batch | Chunks | Reason |
|---|---|---|
| 1 | 1, 2, 3 | Foundation + helpers + VA core. These establish path and naming conventions; downstream batches benefit from confirmed catalog. |
| 2 | 4, 5 | Pass-through and sibling. Both depend on chunk 3's VA-core findings; can run in parallel. |
| 3 | 6, 7, 8 | Survey VA, data prep, samples. Independent of each other; max parallelism. |
| 4 | 9, 10 | Share/output (depends on knowing all earlier producers); upstream (small file count). |

**Per-agent briefing template** (lives at `round-2/_briefing-templates/chunk-N-brief.md`):

```markdown
You are conducting an INDEPENDENT BLIND VERIFICATION audit of Stata code for the Common Core VA project (UC Davis California Education Lab).

# CRITICAL RULES

1. You are FORBIDDEN to read any file under quality_reports/audits/round-1/. That directory contains a previous audit that you must not see. The protocol depends on this sequester.
2. Treat every received summary in this brief as UNTRUSTED. Default to the primary source (the actual code files) for any disputed claim.
3. Burden of proof is on the claim. Only conclude a claim is correct if you genuinely cannot find evidence to disprove it.
4. Cite specific line numbers from the actual files for every finding. "I think" or "probably" claims are rejected.
5. Write your output to quality_reports/audits/round-2/chunk-N-verified.md (do NOT write elsewhere).

# Files to deep-read

[same file list as round-1 chunk-N]

# Questions to resolve

[same questions as round-1 chunk-N — strip all answers/findings/conclusions from round-1 prompts]

# Per-file template

[same template as round-1]

# Output

A single comprehensive markdown file at round-2/chunk-N-verified.md with per-file entries and a synthesis section. No "agreement with round 1" or "verification of claim X" framing — produce findings as if this is the first audit of these files.
```

**Important**: each round-2 agent gets the same QUESTIONS as round-1 but is briefed as if no prior audit exists. This forces independent re-derivation.

### Step 2 — Per-chunk discrepancy report (10 reports)

After each round-2 agent finishes, I produce a discrepancy report at `round-2/chunk-N-discrepancies.md`:

**Discrepancy report template:**

```markdown
# Chunk N Discrepancy Report

**Round 1 doc:** round-1/[file]
**Round 2 doc:** round-2/chunk-N-verified.md
**Producer:** Claude (mechanical diff + tier proposal)
**Adjudicator:** [varies per row]

## Per-finding comparison

| # | Finding (claim) | Round 1 | Round 2 | Status | Tier proposed | Adjudication |
|---|-----------------|---------|---------|--------|---------------|--------------|
| 1 | [finding statement] | line cite + claim | line cite + claim | AGREE / R1-MISSED / R2-MISSED / DISAGREE | T1 / T2 / T3 / T4 | [outcome] |
| ... |

## Discrepancies requiring user action

(T1 items list here — concrete Stata test snippets for Christina to run on Scribe)

## Discrepancies referred to T2 adversarial agent

(list with specific adversarial brief for each)

## Discrepancies referred to T4 (Christina's domain knowledge)

(list with concrete questions and excerpts)
```

### Step 3 — Adjudication

Each discrepancy gets adjudicated per its assigned tier:

- **T1 items**: I draft Stata test scripts (≤15 lines each); Christina runs on Scribe and shares output; I integrate result into the verified-final doc.
- **T2 items**: I dispatch a third independent agent with adversarial brief: "Find evidence that [claim] is wrong. Default to claim being wrong; only conclude correct if you genuinely cannot find counter-evidence." Output goes to `round-2/chunk-N-adversarial.md`.
- **T3 items**: I run deterministic checks (`grep`, `sed`, `wc`, `diff`) and report results. No interpretation needed.
- **T4 items**: I surface to Christina with the round-1 claim, round-2 claim, adversarial-agent finding (if T2 was tried), and the actual primary-source excerpt; Christina decides.

### Step 4 — Verified-final audit doc

After all 10 chunks have completed discrepancy reports + adjudication:

- Produce `quality_reports/audits/2026-04-XX_deep-read-audit-FINAL.md` containing only verified findings.
- All round-1 and round-2 docs preserved in `round-1/` and `round-2/` for archeology.
- Companion docs (`path-references-FINAL.md`, `dependency-graph-FINAL.md`) similarly produced from verified content.

**Christina signs off on the verified-final audit before Phase 0e (design lock) begins.**

### Step 5 — Bug-priority triage

After verification, every confirmed bug gets a priority assignment:

| Priority | Definition | Phase to fix |
|---|---|---|
| **P1** | Paper-load-bearing — affects a number that appears in the paper. Must be fixed before Phase 1 migration completes. | Phase 1 |
| **P2** | Pipeline integrity — affects intermediate dataset semantics, sample sizes, or filenames in ways that could silently corrupt downstream artifacts. | Phase 1 |
| **P3** | Cosmetic / hygiene — typos, dead code, naming inconsistencies, comments-don't-match-code. Document; defer. | Post-consolidation |

Per Christina's prior preference, bugs are fixed in atomic per-bug commits during Phase 1 with line-cited commit messages.

### Step 6 — Q&A consolidation for Phase 0e

The ~30 user-facing questions from round 1 get consolidated, plus any new questions raised by round 2 / adversarial agent / T4 escalations. Output: a single Phase 0e walk-through doc with Christina's answers, used as the basis for ADR-0004 through ADR-0016.

---

## 5. Per-chunk verification matrix

For each chunk, what gets verified and how:

### Chunk 1 (Foundation)

| Finding | Tier | Verification approach |
|---|---|---|
| Both `settings.do` files byte-identical except blank line | T3 | `diff` the two files |
| `$projdir = caschls home`, `$vaprojdir = fork home` | T3 | `grep "global.*projdir"` in both settings.do |
| `vam.ado` byte-identical to server_vam | T3 | `diff` |
| `vam.ado` matches Stepner v2.0.1 | T3 | `head -1 vam.ado` shows version string; `wc -l` should be 760; diff against published Stepner v2.0.1 if locatable |
| `noseed` bug (already fixed) | T3 | `grep` for the fixed `if "\`noseed'"==""` |
| macros_va.doh `asd_str = a_str` (was bug, now fixed) | T3 | `grep` shows fixed |
| 22 ssc/community packages claimed in install block | T3 | `grep "ssc install"` on do_all.do |
| 4 sibling-match calls in master.do (not 5) | T3 | `grep -c "do.*siblingxwalk\|siblingoutxwalk"` |

### Chunk 2 (Helpers)

| Finding | Tier | Verification approach |
|---|---|---|
| v1 prior-score grades+years per cohort | T3+T1 | T3: line citations in `create_prior_scores_v1.doh`. T1: `tab year prior_ela_z_score, miss` on a sample dta to confirm at least one row per cohort×subject. |
| v2 prior-score uses L5 (year-5) | T3+T1 | Same; confirm L5 lookback. |
| `_scrhat_` orthogonal to v1/v2 (computed only in `do_files/explore/`) | T3 | `grep -rn "prior_ela_z_score_hat" do_files/` — only matches in `explore/` |
| Sample restriction sequence | T2 | Adversarial: "Find evidence the sample restriction sequence is different from claimed." |
| `vaestmacros.doh` L27 `.dta.dta` typo | T3 | `sed -n '27p'` |
| `vaestmacros.doh` L45/L118 missing `$` prefix | T3 | `sed -n '45p;118p'` |
| `merge_k12_postsecondary.doh` L7 hardcoded path | T3 | `sed -n '7p'` |

### Chunk 3 (VA core)

| Finding | Tier | Verification approach |
|---|---|---|
| Output-filename grammar `<prefix>{_p}_<outcome>_<sample>_sp_<ctrl>_ct{_<fb_var>_lv}.ster` | T3 | `find estimates/ -name "*.ster" \| head -20` and check pattern |
| `sp/ct/lv` literal separators | T3 | `grep "sp_\|_ct\|_lv" do_files/sbac/va_*.do \| head` shows usage as literal |
| ~30 vam invocations all use rename pattern | T3 | `grep -A 3 "^[[:space:]]*vam " \| grep "rename tv"` count = ~30 |
| `out_drift_limit.doh` is dead code | T3 | `grep -rn "include.*out_drift_limit\|do.*out_drift_limit"` returns 0 |
| `va_out_sib_lag.do` uses `score_drift_limit` (latent bug) | T3 | `grep -n "drift_limit" va_out_sib_lag.do` |
| `va_out_all.do:176` typo `_cts.ster` (extra `s`) | T3 | `sed -n '176p'` |
| Spec-test β at `va_score_all.do:87, va_out_all.do:85` | T3 | `sed -n '85p;87p'` on each file |

### Chunk 4 (Pass-through + heterogeneity)

| Finding | Tier | Verification approach |
|---|---|---|
| `_m` defined at `reg_out_va_all.do:152, 154, 166, 168` | T3 | `sed -n '150,170p' reg_out_va_all.do` |
| `_wt` / `_nw` at `va_het.do:78, 81` | T3 | `sed -n '75,85p' va_het.do` |
| Paper Table 4 producer = `share/reg_out_va_tab.do:219` | T3 | `grep "esttab.*using.*persistence_single_subject\|reg_<outcome>_va.csv" share/reg_out_va_tab.do` |
| Paper Table 5 producer = `va_het.do:219` | T3 | `grep "corr_char_wt" va_het.do` |
| Paper Table 7 producer = `va_het.do:138` | T3 | `grep "var_across_district" va_het.do` |
| `va_het.do:158` uses `cluster(cdscode)` not `cluster(school_id)` | T3 | `sed -n '158p' va_het.do` |
| `run_prior_score = 0` at `reg_out_va_all.do:235` | T3 | `sed -n '235p'` |
| `va_corr_schl_char.do` LHS-peer-suffix bug at L84/94 | T3 | `sed -n '84p;94p'` |
| Pass-through ρ specification clusters at school_id | T2 | Adversarial: "Find evidence pass-through ρ does NOT cluster at school_id" |

### Chunk 5 (Sibling)

| Finding | Tier | Verification approach |
|---|---|---|
| **N1 verdict: SAFE to relocate** | T2 | Adversarial: "Find evidence siblingoutxwalk.do has a `siblingvaregs/` data dependency that would break on relocation." |
| Sibling matching: 5-component address join | T3 | `grep "egen group.*street_address" siblingmatch.do` |
| Transitive closure via `group_twoway` | T3 | `grep "group_twoway" uniquefamily.do` |
| 10-child cap at `uniquefamily.do:53` | T3 | `sed -n '53p'` |
| `group_twoway` is Haghish (not on SSC) | T2 | Adversarial: "Find evidence group_twoway is on SSC." |
| 4-spec convention `og/acs/sib/both` | T3 | `grep -E "og_str\|acs_str\|sib_str\|both_str" macros_va.doh` |
| Positional arg `0` semantics in `va_sibling.do` | T3 | `sed -n '50,65p' va_sibling.do` (look for `args setlimit` and the `if setlimit==0` block) |
| `siblingpairxwalk.do:24` rename-of-dropped-var bug | T3 | `sed -n '24p'` + `grep "middle_intl" uniquefamily.do` |
| `va_sibling_out.do:328-330` collapse missing sibling-sample filter | T3 | `sed -n '328,330p'` and compare to `va_sibling.do:287-291` |

### Chunk 6 (Survey VA)

| Finding | Tier | Verification approach |
|---|---|---|
| Paper Table 8 chain (clean_va → allsvymerge → imputation → indices → withdemo) | T2 | Adversarial: "Find evidence the chain is different or has additional/missing steps." |
| Index construction is SUM, not AVERAGE | T3 | `sed -n '36,50p' imputedcategoryindex.do` |
| Cronbach α in `indexalpha.do` | T3 | `grep "alpha\b" indexalpha.do` |
| Survey-VA merge at cdscode only (no year) | T3 | `grep "merge.*cdscode" allvaregs.do clean_va.do` |
| `allvaregs.do:197` weighted-merge silently saves to `_nw` filename | T3 | `sed -n '195,200p' allvaregs.do` |
| `pcascore.do:36-39` PC2 histogram re-uses pc1 | T3 | `sed -n '36,39p'` |
| `mvpatterns` ssc package new in `allsvymissing.do:38` | T3 | `grep "mvpatterns" allsvymissing.do` |

### Chunk 7 (Data prep)

| Finding | Tier | Verification approach |
|---|---|---|
| **Distance-FB `d` token wiring in `macros_va_all_samples_controls.doh`** | T3+T1 | T3: `grep -n "_ctrl_leave_out_vars" macros_va_all_samples_controls.doh` shows `d` in lists. T1: actually run a fb_var=="d" loop iteration on Scribe to confirm `_ct_d_lv.ster` files get produced. |
| `mindist_*` produced in `k12_postsec_distances.do:121-124` | T3 | `sed -n '121,124p'` |
| ACS only 2010-2013 (not 2014+) | T3 | `grep "year\|forvalues.*year" clean_acs_census_tract.do \| head` |
| `enrollmentclean.do:21` female-encoding bug | T3 | `sed -n '20,30p' enrollmentclean.do` |
| `clean_charter.do:26` Apple Silicon detection broken | T3 | `sed -n '26p'` |
| `reconcile_cdscodes.do:81` in-place save | T3 | `sed -n '78,85p'` |
| QOI year-batching pattern (year-specific quirks) | T2 | Adversarial: "Find evidence the year-batching does NOT correspond to question-numbering compatibility." |

### Chunk 8 (Samples)

| Finding | Tier | Verification approach |
|---|---|---|
| Sample-restriction map (paper Table A.1 ↔ `_archive/matt_original/sum_stats.do`) | T2+T1 | T2: adversarial agent re-maps from `share/sample_counts_tab.do` instead. T1: confirm both files run and produce a Table A.1 — does the new producer's output match what's in the paper? |
| `<7` at `touse_va.do:155, 180` | T3 | `sed -n '155p;180p'` |
| `<=10` cohort cut at `touse_va.do:109` (separate from <7) | T3 | `sed -n '109p'` |
| `gr11enr_mean` weight chain | T3 | `grep "gr11enr_mean\|aweight" relevant files` |
| `pooledrr` two definitions (parentresponserate vs pooledparentdiagnostics) | T3 | Read both files, confirm different formulas |
| `parentdemographics.do:13` 1415 grade-7 silent drop | T3 | Read header comment + check for `keep if grade != -8` (absence confirms silent drop) |
| `pooledsecdemographics.do:23-24` filipinoenr += asianenr | T3 | `sed -n '23,24p'` |
| `secdemographics.do:102` vs `elemdemographics.do:67` sex-coding inversion | T3 | `sed -n '102p' secdemographics.do; sed -n '67p' elemdemographics.do` |

### Chunk 9 (Share/explore)

| Finding | Tier | Verification approach |
|---|---|---|
| `share/sample_counts_tab.do` writes `tables/share/va/pub/counts_k12.tex` | T3 | `grep "esttab.*using.*counts_k12" sample_counts_tab.do` |
| Paper consumes the modern path (`tables/share/va/pub/counts_k12.tex`) | T3 | `grep "counts_k12" va_paper_clone/paper/common_core_va_v2.tex` |
| `share/svyindex_tab.do` writes `imputed_index_combined_wdemo.tex` | T3 | `grep "esttab.*using.*imputed_index_combined" svyindex_tab.do` |
| `share/va_var_explain.do` produces Table 7 input | T3 | `grep "va_var_explain_v1" share/va_var_explain.do share/va_var_explain_tab.do` |
| All paper Tables 1-8 + Figs 1-4 producers IN-SCOPE (closed loop) | T2 | Adversarial: "Find a paper artifact whose producer is OUTSIDE `share/`." |
| `va_predicted_score_fb.do:43` non-scrhat leave-out list bug | T3 | `sed -n '43p'` |
| scrhat outputs go to `tables/explore/` (never paper) | T3 | `grep "tables/" explore/va_predicted_score*.do` |
| `va_scatter.do` `corr_*` vs `b_*` typo in 6 places | T3 | `grep -n "corr_" va_scatter.do` and confirm 6 occurrences |

### Chunk 10 (Upstream)

| Finding | Tier | Verification approach |
|---|---|---|
| **Bug 93: real at L218-219, L226-228; FALSE at L222-223, L230-233** | T3+T1 | T3: pre-flight already done — confirmed by direct reading + Stata operator-precedence rule. T1: Stata test on Scribe — `count if nsc_enr_uc==1 & recordfoundyn != "Y"` should return >0 if bug is real. |
| Geocoding pipeline = `gecode_json.py` only | T3 | `find ~/github_repos/cde_va_project_fork/py_files -name "*.py"` returns one file |
| Census Bureau Geographies API (free, keyless) | T3 | `grep -i "census\|api\|key\|token" gecode_json.py` |
| 5 external static inputs (lag2ela, k12_test_scores_clean, k12_ccc_crosswalk, k12_csu_crosswalk, address_list) | T3 | For each: `grep -rn "save.*<file>" .` returns 0 (i.e., not produced in any in-scope script) |
| 3 in-scope crosswalks vs 2 external | T3 | `grep "save" do_files/upstream/crosswalk_nsc_outcomes.do caschls/do/upstream/crosswalk_*.do` |
| Both Matt crosswalk files have `if c(hostname)=="sapper" exit, STATA clear` auto-shutdown | T3 | `grep "sapper.*exit" caschls/do/upstream/crosswalk_*.do` |
| `gecode_json.py:36-57` broken retry loop | T3 | `sed -n '36,57p' gecode_json.py` |

---

## 6. Cost / time estimate

| Step | Wall-clock | Compute | Christina's time |
|---|---|---|---|
| Step 0: Setup | (done) | (done) | ~0 |
| Step 1: Round-2 agents (4 batches, parallel-batched) | 2-4 hrs | 10-20 hrs | ~0 |
| Step 2: Discrepancy reports (10 chunks, mostly mechanical) | 4-8 hrs | mostly tools (`grep`, `sed`) | ~0 |
| Step 3: Adjudication |  |  |  |
|   T1 — Christina runs Stata tests | depends on her schedule | ~0 | 30-90 min |
|   T2 — adversarial agents (5-10) | 2-4 hrs | 5-10 hrs | ~0 |
|   T3 — deterministic checks | 1-2 hrs | minutes | ~0 |
|   T4 — Christina investigates | depends | ~0 | variable |
| Step 4: Verified-final audit doc | 2-3 hrs | minimal | review only |
| Step 5: Bug-priority triage | 1 hr | minimal | review only |
| Step 6: Q&A consolidation for Phase 0e | 1-2 hrs | minimal | review only |
| **Total** | **12-25 hrs spread across multiple sessions** | **~20-40 hrs compute** | **1-3 hrs of focused time** |

The bulk is agent compute and my synthesis time. Christina's burden is concentrated in T1 Stata tests + adjudicating any T4 escalations.

---

## 7. Commit cadence

Per atomic-commit discipline:

- One commit per round-2 chunk completion (10 commits)
- One commit per discrepancy report completion (10 commits)
- One commit per T1 result integration (variable, ≤10 commits)
- One commit per T2 adversarial-agent output (variable, ≤10 commits)
- Final commits for verified-final audit doc + bug-priority triage + Q&A consolidation

Estimated total: ~40-60 commits across the verification phase.

---

## 8. What gets gated by what

```
Step 0 setup ───→ Step 1 round-2 batches ───┐
                                            ├───→ Step 2 discrepancy reports ───→ Step 3 adjudication
                                            │
                                            └───→ (parallel: T1 tests Christina runs whenever convenient)
                                                                                          │
                                                                                          ▼
                                                              Step 4 verified-final audit doc
                                                                          │
                                                                          ▼
                                                         Step 5 bug-priority triage
                                                                          │
                                                                          ▼
                                                       Step 6 Q&A consolidation for Phase 0e
                                                                          │
                                                                          ▼
                                                         CHRISTINA SIGNOFF GATE
                                                                          │
                                                                          ▼
                                                            Phase 0e (design lock)
                                                                          │
                                                                          ▼
                                                            Phase 1 (migration)
```

---

## 9. Pre-flight result: Bug 93 status (T3 verified, 2026-04-25)

(Documented in `round-2/README.md` and reproduced here for plan completeness.)

Round-1 chunk-10 claim: bug at L219, L222, L228, L232 of `crosswalk_nsc_outcomes.do`. Direct reading via Stata operator precedence (`&` binds tighter than `|`):

| Line | Variable | Has outer parens? | Status |
|---|---|---|---|
| 218-219 | `nsc_enr_uc` | NO | **BUG** — UC Merced bypasses `recordfoundyn=="Y"` |
| 222-223 | `nsc_enr_ucplus` | YES | **CORRECT** — protected |
| 226-228 | `nsc_enr_ontime_uc` | NO | **BUG** — UC Merced bypasses `recordfoundyn` AND `enrollmentbegin` |
| 230-233 | `nsc_enr_ontime_ucplus` | YES | **CORRECT** — protected |

**Verdict**: bug is real but round-1 over-claimed scope by 50%. Real impact: 2 paper outcomes (`nsc_enr_uc`, `nsc_enr_ontime_uc`), not 4. T1 empirical test for full ground-truth confirmation:

```stata
use $vaprojdir/data/sbac/k12_postsecondary_out_merge.dta, clear
count if nsc_enr_uc == 1 & recordfoundyn != "Y"
* >0 confirms bug; UC Merced rows would all qualify
list collegecodebranch recordfoundyn nsc_enr_uc if collegecodebranch == "001319-00" in 1/10
```

Christina runs when convenient. Result feeds into Phase 1 bug-fix priority (P1 if confirmed).

---

## 10. Open questions for Christina before execution

1. **Tier structure acceptable?** (yes already approved 2026-04-25)
2. **Christina's T1 time budget**: 30-90 min OK? Concentrated in one session or spread?
3. **Should adversarial agent (T2) be a different model than round-2 agent**? Recommendation: same model class (general-purpose) is fine for adversarial framing — it's the BRIEFING that creates the difference, not model variance.
4. **Failure mode**: if a chunk has more than 5 discrepancies that can't be auto-adjudicated, escalate to a re-read by me with primary source rather than trying to triage piecemeal?
5. **Hard stop**: any individual finding that round-2 + T2 agents BOTH disagree with round-1 → automatic T4 escalation to Christina (don't let majority of agents overturn a finding without human review)?

---

## 11. After Phase 0a-v2 — what changes

- `quality_reports/audits/2026-04-XX_deep-read-audit-FINAL.md` is the source of truth for Phase 0e.
- All round-1 + round-2 + adversarial docs preserved in subdirs for archeology.
- Bug inventory categorized P1/P2/P3.
- ~30 user-facing questions consolidated into Phase 0e walk-through doc.
- Plan v3 (consolidation plan) gets re-written against verified findings.
- ADRs 0004-0016 written with verified-finding citations.

---

## 12. Awaiting Christina's signoff

Before any round-2 agent dispatches:

1. Christina reviews this plan
2. Answers the 5 questions in §10
3. Approves
4. Then I launch Step 1 batch 1 (chunks 1, 2, 3 in parallel)

If at any point during execution Christina wants to pause, scope down, or course-correct, the atomic-commit cadence makes that easy — discrete state per commit, easy to roll back or branch.
