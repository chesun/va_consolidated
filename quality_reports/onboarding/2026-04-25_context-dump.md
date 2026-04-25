# Context Dump - Common Core VA Project

<!-- primary-source-ok: chetty_friedman_rockoff_2014, naven_2022 -->

**Purpose:** Capture everything Christina knows about the code, data, and project history that isn't in the paper or the predecessor repos themselves. Fill incrementally; we don't need every section before starting work, but we do need section 2 (current pipeline) and section 4 (code map) before we can audit `do_all.do` / `main.do` and write a consolidation plan.

**How to use this:**

- Fill any section in any order. Skip sections that don't apply.
- Free prose is fine. Bullets, tables, ASCII diagrams - whatever's fastest to write.
- Mark sections `[DONE]`, `[PARTIAL]`, or leave the placeholder text untouched if you haven't gotten to it.
- When you're done, ping Claude and we'll synthesize.

---

## Section 0: What Claude already knows (please correct anything wrong)

These are facts captured during the 2026-04-24 onboarding session. Strike through or rewrite anything inaccurate.

| Fact | Value |
|---|---|
| Project | Common Core VA Project / "Do Schools Matter?" |
| Institution | California Education Lab, UC Davis |
| Deadline | Hard, 3 months from 2026-04-24 |
| Deliverable | Consolidated codebase (paper already drafted) |
| Paper status | Submitted, rejected, in limbo pending coauthor/PI decision |
| Working draft | `~/github_repos/va_paper_clone/paper/common_core_va_v2.tex` |
| Bib | `~/github_repos/va_paper_clone/literature/bibtex/common_core_va.bib` |
| In-scope repos | `~/github_repos/cde_va_project_fork` + `caschls` at Dropbox path |
| Out-of-scope repos | `ca_ed_lab-common_core_va`, `common_core_va_workflow_merge` |
| Server | Scribe (`Scribe@ssds.ucdavis.edu`), `c(hostname) = "scribe"` |
| Server project root | `/home/research/ca_ed_lab/projects/common_core_va` |
| Stata | 17 |
| Languages | Stata only; py_files/ is dead in both predecessors |
| v1 vs v2 | Different prior-score-control variants. v1 is canonical, used in paper. v2 was exploratory, never reported. |
| Solo work | Yes; senior coauthors don't code |

**Corrections / additions:**

> *(write here)*

---

## Section 1: Codebase history

How did we get to the current mess? Pick whatever level of detail is useful.

### Major milestones

> *(rough timeline - "Matt started ~2014; I joined ~2019; I forked when ___; 2022 merge attempt was during ___; v2 prior-score exploration happened ___")*

### What's been rewritten vs. inherited

> *(which parts are still Matt's original code, which parts have you rewritten end-to-end, which parts you've patched but mostly left alone)*

### Dead code / exploratory branches we should ignore

> *(e.g., "v2 prior-score code is still in the fork but I never use it; the kramer_nsc directory is from a side project we abandoned; the va_het folder was an experiment that never made it into the paper")*

### Things that are surprising / counterintuitive

> *(stuff a new collaborator would trip over - "the NSC clean step lives in Matt's data dir, not the code repo" / "the survey scoring is in caschls but reads VA estimates from the fork's output dir" / etc.)*

---

## Section 2: How you currently run the pipeline (without consolidation)

This is the most important section. Even if you skip everything else, please fill this in.

### End-to-end sequence today

What do you actually do, in order, when you need to regenerate the paper from scratch? (Or as close to "from scratch" as you go.)

> *(numbered list. Be brutally specific. Include manual steps - "I open `settings.do` and edit a path", "I copy `sibling_xwalk.dta` from the caschls output dir to the fork's data dir", "I source `do_all.do` then go to lunch then run the post-processing scripts manually". This is the thing I most need to see.)*

### What's the entry point?

> *(do you call `do_all.do` from the fork? `master.do` from caschls? a wrapper script you maintain locally? something else?)*

### What's NOT automated

> *(steps that need human judgment or manual file-shuffling)*

### What's broken / only-works-by-accident

> *(scripts that error if you don't do X first; hardcoded paths that only work on your machine; intermediate files that have to exist before some step but aren't auto-created; date-dependent behavior; etc.)*

### Pipeline diagram (optional)

> *(ASCII boxes-and-arrows, or a verbal walkthrough. Whatever's faster.)*

---

## Section 3: Data sources

### Raw inputs on Scribe

| Path | What | Who creates it | Refresh cadence |
|---|---|---|---|
| `/home/research/ca_ed_lab/data/restricted_access/clean/caaspp/sbac_<year>.dta` | Cleaned CAASPP/SBAC test scores | (per Naven readme: cleaned by `cleancaaspp<year>.do` in same dir) | (one-time? annual?) |
| `/home/research/ca_ed_lab/msnaven/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta` | (combined K-12 test scores?) | (per readme: `clean_k12_test_scores.do`) | |
| | NSC college-enrollment data | | |
| | CalSCHLS surveys 2017-2019 | | |
| | Student addresses (sibling matching, geocoding) | | |
| | ACS Census tract data | | |
| | College location list (for distance computation) | | |
| | Anything else load-bearing | | |

> *(fill paths, ownership, and any quirks - e.g. "this dta has duplicate rows you have to drop", "this got renamed in 2021", "I rebuild this once a year when CDE updates the file")*

### Where outputs land

> *(do figures/tables go to a shared directory? to Overleaf via a sync script? to your laptop and you upload manually?)*

### Restricted-data handling

> *(any data that can't leave the server, can't be in figures, etc. - so we know what's safe to surface in the consolidated repo)*

---

## Section 4: Code map (do-file by do-file)

For each **load-bearing** do-file (i.e., needed to reproduce the paper or to maintain the project), fill in:

```
Path: 
What it does (1 sentence): 
Inputs (datasets read): 
Outputs (datasets/tables/figures written): 
Owner: Matt | Christina | both
Status: in-use | deprecated | exploratory
Notes / gotchas: 
```

You don't have to do every script. Start with the ones that produce paper Tables 1-8 and Figures 1-6. The paper map (`quality_reports/reviews/2026-04-24_paper-map.md`) lists exactly which output files those need.

### From `cde_va_project_fork/do_files/sbac/` (Naven's SBAC pipeline)

> *(fill scripts here. Naven's README lists 20 numbered files starting with `touse_va.do` - that order is a starting point but you may have changed it.)*

### From `caschls/do/`

> *(sibling crosswalk, factor analysis / index construction, survey-VA regressions, etc.)*

### Helper / settings / master files

> *(`settings.do`, `mainscript.do` / `master.do` / `do_all.do`, `.doh` includes - what's the structure, anything weird about how they reference each other)*

### Scripts that ARE NOT load-bearing for the paper

> *(stuff in `_archive/`, `check/`, `explore/`, `share/` that we should leave behind during consolidation. Saves us reading them.)*

---

## Section 5: The sibling-VA circular dependency

You said in onboarding round 3 you couldn't quite remember the precise circle. If you've thought about it since, write it here. Otherwise we'll trace it during the deep-read.

### What scripts produce and consume the sibling crosswalk

> *(which do-file builds it, which do-files consume it, where in the pipeline it sits)*

### What scripts produce and consume "older sibling went to college"

> *(this is what equation 1 needs as a control in the saturated specification)*

### Where the loop closes

> *(if at all - or just describe the order ambiguity)*

---

## Section 6: Naming conventions to verify

The paper-map's filename token glossary is partially inferred. Confirm:

| Token | Inferred meaning | Actual meaning |
|---|---|---|
| `b` | base sample / base controls | |
| `las` | leave-all-sample (restricted)? | |
| `sp` | sample / spec marker? | |
| `ct` | controls? | |
| `_p` | peers | |
| `v1` | prior-score variant 1 | (CONFIRMED) |
| `nw` | non-weighted? | |
| `_m` | math? marginal? | |
| `_wt` | weighted | |
| (others?) | | |

> *(also worth listing variable-naming patterns - e.g., does Matt use camelCase? snake_case? are there standard prefixes for VA-related variables?)*

---

## Section 7: Open questions from the paper read

These came up while reading `common_core_va_v2.tex`. Answer what you can.

| # | Question | Answer |
|---|---|---|
| 1 | Sibling matching specifics: shared address+surname is the rule per paper, but how are family-moves handled? Surname-change (remarriage)? Data-entry typos? Is there a sensitivity-analysis script? | |
| 2 | NSC linkage: by name+DOB+school? Match rate? Who runs it? | |
| 3 | Geocoding: which service / vintage? Match rate? | |
| 4 | Distance to college: Euclidean ("linear" per paper) or driving-time? What's the list of public 2-yr / 4-yr colleges? | |
| 5 | Standard errors: paper consistently says "clustered at school level" - is this implemented as `vce(cluster sch_id)` everywhere, or are some specs different? | |
| 6 | Drift / shrinkage: implemented as Stata's `vam` package (Stepner/Jepsen) or custom code? | |
| 7 | Overleaf-vs-local sync: which `.tex` is canonical now? Are the figures/tables on Overleaf the same files as `~/github_repos/va_paper_clone/...`? | |

---

## Section 8: Free-form context dump

Anything else worth telling me before we audit master files. Institutional history, weird interactions, things you wish someone had told you when you started, "Matt always did X but I disagree with that," what you'd change if you could redo this from scratch, anything.

> *(write here)*

---

## Section 9: After the dump - what we do next

Once you fill enough of the above, the plan is:

1. Claude reads what you wrote and surfaces follow-up questions for anything unclear.
2. We audit `do_all.do` (in `cde_va_project_fork`) and `main.do` (in `caschls`) - see if they capture every load-bearing do-file or whether some are run by hand.
3. Based on that audit, we write a consolidation plan: target folder structure, ordering of pipelines, ADRs for the key decisions (sibling crosswalk location, v1-only policy, settings.do branching, etc.).
4. Then implementation.

You can ping me partway through filling this if you want - I can flag missing context or push back on anything that contradicts what I've already learned.
