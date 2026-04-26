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

> *rough timeline - "Matt started ~2014; I joined ~late 2020*
> I don't remember when I joined Matt's repo or when I forked it. I can see my first commit for changes_by_che branch (branch with my work) was Feb 2022. I think matt accepted a few PRs from me before I forked the repo. There is also a branch called va_v2 which is the v2 exploration, which i think was later merged to changes_by_che branch

### What's been rewritten vs. inherited

> *(which parts are still Matt's original code, which parts have you rewritten end-to-end, which parts you've patched but mostly left alone)*
> The following do files are matt's original code which are no longer used. This is in a commented out block in do_all.do in the cde_va_project_fork repo, changes_by_che branch. The changes_by_che branch is the production branch.
```stata
//----------------------------------------------------------------
/* do do_files/sbac/sum_stats.do
pause
do do_files/sbac/sum_stats_tab.do
pause
do do_files/sbac/va_cfr.do
pause
do do_files/sbac/sum_stats_va_cfr.do
pause
do do_files/sbac/va_cfr_forecast_bias.do
pause
do do_files/sbac/sum_stats_va_cfr_forecast_bias.do
pause
do do_files/sbac/prob_enr.do
pause
do do_files/sbac/reg_out_va_cfr.do
pause
do $vaprojdir/do_files/sbac/reg_out_va_cfr_dk.do
pause
do do_files/sbac/reg_out_va_cfr_tab.do
pause
do do_files/sbac/reg_out_va_cfr_fig.do
pause
do $vaprojdir/do_files/sbac/reg_out_va_cfr_dk_fig.do
pause
do do_files/sbac/va_cfr_out.do
pause
do do_files/sbac/sum_stats_va_cfr_out.do
pause
do do_files/sbac/va_cfr_out_tab.do
pause
do do_files/sbac/va_cfr_out_forecast_bias.do
pause
do do_files/sbac/sum_stats_va_cfr_out_forecast_bias.do
pause
do do_files/sbac/sum_stats_va_res.do
pause
do do_files/sbac/reg_va_cfr_sch_char.do
pause
do do_files/sbac/reg_va_cfr_out_sch_char.do
pause
do do_files/sbac/reg_va_cfr_sch_char_tab.do */
//----------------------------------------------------------------
```

### Dead code / exploratory branches we should ignore

> I moved unused do files to the _archive/ folder, including cde_presentations (presumably early ad hoc code by Matt), kramer_nsc (reference code, not production), and resources (also reference code). I created a folder do_files/_archive/matt_original and these above matt original do files need to be moved to that folder.

### Things that are surprising / counterintuitive

> caschls repo creates sibling linkage in this block in the master.do:
```stata
/* matching siblings using CST data */
////////////////////////////////////////////////////////////////////////////////
local do_match_siblings = 0
if `do_match_siblings' == 1 {

  /* Use CST data to match students with their siblings. Code taken mostly from
  do file by Matt Naven  */
  do $projdir/do/share/siblingxwalk/siblingmatch
  pause

  /* use the sibling crosswalk dataset conditional on same year and create unique family ID
  to link siblings from the same family across years and delete duplicates  */
  do $projdir/do/share/siblingxwalk/uniquefamily
  pause

  /* create a dataset with all pairwise combinations of siblings and their state student IDs.
  Same combination with different orders are different observations. */
  do $projdir/do/share/siblingxwalk/siblingpairxwalk
  pause

  /* create a sibling enrollment outcomes crosswalk dataset by merging k-12 test scores
  to the postsecondary outcomes and then merge to ufamilyxwalk.dta and calculuate
  number of older siblings enrolled and proportion of older siblings enrolled   */
   do $projdir/do/share/siblingvaregs/siblingoutxwalk.do
   pause
}
```
> then master.do says `// THIS IS WHERE TO RUN THE VA ESTIMATES DO FILES` and the fork repo runs va estimatino using the constructed sibling linkage/crosswalks. Then the caschls repo code pulls VA estimate datasets to run regressions by linking it to constructed survey indices.

---

## Section 2: How you currently run the pipeline (without consolidation)

This is the most important section. Even if you skip everything else, please fill this in.

> Thankfully I made a note to myself in the master do files. Currently I think I run the matching sibling block in master.do in caschls repo, then I run the entire do_all.do in forked repo, then I run everything in the master.do in caschls repo after the sibling matching block. You can actually observe this in the value of the code block toggles in master.do.

### End-to-end sequence today

What do you actually do, in order, when you need to regenerate the paper from scratch? (Or as close to "from scratch" as you go.)

> Last time I ran it end to end was probably 2023. I think in the above sequence.

### What's the entry point?

> Again, see above sequence.

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
| `/home/research/ca_ed_lab/data/restricted_access/clean/caaspp/sbac_<year>.dta` | Cleaned CAASPP/SBAC test scores | (per Naven readme: cleaned by `cleancaaspp<year>.do` in same dir) | one-time, i never touched it |
| `/home/research/ca_ed_lab/msnaven/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta` | (combined K-12 test scores?) | (per readme: `clean_k12_test_scores.do`) | |
| | NSC college-enrollment data | | |
| `"/home/research/ca_ed_lab/data/restricted_access/raw/calschls/stata"` and `"/home/research/ca_ed_lab/data/restricted_access/raw/calschls/csv"` for .dta and .csv files| CalSCHLS surveys 2014-15 to 2018-19 | raw data provided by CDE | none |
| `"/home/research/ca_ed_lab/data/restricted_access/clean/cde/cst"`| CST California Standards Test dataset with Student addresses (used in sibling matching) | Raw| None|
| | ACS Census tract data | | |
| | College location list (for distance computation) | | |
| | Anything else load-bearing | | |

> You should be able to infer this from settings do files and dataset inputs.

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
| `b` | base sample / base controls | yes |
| `las` | l stands for leave out score, a stands for acs, and s stands for sibling, d stands for college distance. these are different control combinations in VA estimation | |
| `sp` | sample  | yes|
| `ct` | controls? | yes|
| `_p` | peers | yes|
| `v1` | prior-score variant 1 | (CONFIRMED) |
| `nw` | non-weighted |yes |
| `_m` |matched controls |  |
| `_wt` | weighted | yes |
| (others?) | | |

> use all snake case. See macros_va.dogh for what the abbrevaitions mean

---

## Section 7: Open questions from the paper read

These came up while reading `common_core_va_v2.tex`. Answer what you can.

| # | Question | Answer |
|---|---|---|
| 1 | Sibling matching specifics: shared address+surname is the rule per paper, but how are family-moves handled? Surname-change (remarriage)? Data-entry typos? Is there a sensitivity-analysis script? | See code |
| 2 | NSC linkage: by name+DOB+school? Match rate? Who runs it? | Matt did this. No idea how he did it|
| 3 | Geocoding: which service / vintage? Match rate? | No idea. Think matt did using the python scripts |
| 4 | Distance to college: Euclidean ("linear" per paper) or driving-time? What's the list of public 2-yr / 4-yr colleges? | |
| 5 | Standard errors: paper consistently says "clustered at school level" - is this implemented as `vce(cluster sch_id)` everywhere, or are some specs different? | |
| 6 | Drift / shrinkage: implemented as Stata's `vam` package (Stepner/Jepsen) or custom code? | custom modified version of the vam package in the do/ado/ folder of caschls repo |
| 7 | Overleaf-vs-local sync: which `.tex` is canonical now? Are the figures/tables on Overleaf the same files as `~/github_repos/va_paper_clone/...`? | Both are identical. the paper clone repo is cloned from overleaf, and no one is changing overleaf |

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

---

## Section 10: Claude's follow-up questions (added 2026-04-25 after audit)

These came out of synthesising the context dump answers + the master-file audit (`quality_reports/reviews/2026-04-25_master-file-audit.md`). Answer in any order. Priorities flagged.

### 10A. Master-file audit follow-ups [BLOCKING the consolidation plan]

We can't write a target folder structure / pipeline ordering without knowing whether each unreferenced file is in or out.

**A1. `cde_va_project_fork/do_files/sbac/prior_decile_original_sample.do`**

> Header (your authorship, June 2022): "Creates prior score deciles using the original 11th grade VA sample for merge with sibling census restricted sample." Production-sounding, but not in `do_all.do`. Is this load-bearing? If yes, where in the order? If deprecated, archive?

> I think this is production. There is a change log dated 2024.

**A2. `cde_va_project_fork/do_files/sbac/va_scatter_plot.do`**

> Header (your authorship, Oct 2022): "VA scatter plots for correlations." Paper Figs 3-4 are scatter plots. There's also a `do_files/share/va_scatter.do` (which IS in `do_all.do`). Are these the same purpose, or do they produce different plots? Is `va_scatter_plot.do` load-bearing for the paper figures, or superseded by `va_scatter.do`?

> deprecated, non-production.

**A3. `cde_va_project_fork/do_files/crosswalk_nsc_outcomes.do`**

> NSC linkage step. Not in `do_all.do`. Is the cleaned NSC dataset already on Scribe and treated as a static input to the project (so this script doesn't need to run end-to-end), or does the pipeline depend on it being run manually before `do_all.do`?

> Honestly no idea. Will need to trace output lineage to see if used by any other do files.

**A4. `va_score_sib_lag.do` / `va_out_sib_lag.do` reactivation**

> Your in-flight edit to `do_all.do` (committed as `c7867e4`) uncommented these two lines while adding the comment "forecast bias test with sibling bag is not used in paper." Was the reactivation intentional (running the test for diagnostic) or did you flip the comment by accident? If they should stay commented out, I'll send a quick fix-up commit; if they should be active, the comment should be reworded.

> It was intentional, becuase these are testing code and not in the paper, but we will keep them as production in case we want to use them.

**A5. caschls "possibly production" 10-file checklist**

> These files are in `caschls/do/` but not referenced by `master.do`. For each: KEEP (it IS load-bearing, will add to master.do), ARCHIVE (move to `_archive/`), or LOCAL (move to `do/local/` to mark as ad-hoc-but-keep)? Mark each:

| File | Disposition (KEEP / ARCHIVE / LOCAL) | Notes |
|---|---|---|
| `do/build/buildanalysisdata/poolingdata/clean_va.do` | | |
| `do/build/prepare/poolenrollment.do` | | |
| `do/build/sample/enrollmentconvert.do` | | |
| `do/build/sample/responseyear.do` | | |
| `do/share/outcomesumstats/k12_nsc_match_sumstats.do` | ARCHIVE |  has a comment marking it as deprecated|
| `do/share/outcomesumstats/matchdiscrep.do` | ARCHIVE | also has comment marking as deprecated |
| `do/share/outcomesumstats/nsc2019new/nsc2019sumstats.do` | | No idea honestly. my guess is to archive, but should trace input/output lineage |
| `do/share/outcomesumstats/searchdate_sumstats.do` | | No idea. Looks like ad hoc code, should archive probably |
| `do/share/siblingvaregs/reg_out_va_sib_acs_dk_tab.do` | ARCHIVE | This is an empty do file that never got completed. Only has scaffolding in the code for settings and doh files etc |
| `do/share/siblingvaregs/vamtest.do` | ARCHIVE | ad hoc test code |

**A6. caschls Matt-superseded archival (parallel to fork's `_archive/matt_original/`)**

> These 5 files in caschls are Matt's reference / older code, like the fork's matt_original archive. OK to move them to a new `caschls/do/_archive/matt_original/` for symmetry?

- `do/share/outcomesumstats/matt/crosswalk_ccc_outcomes.do`
- `do/share/outcomesumstats/matt/crosswalk_csu_outcomes.do`
- `do/share/outcomesumstats/matt/crosswalk_nsc_outcomes.do`
- `do/share/siblingxwalk/matt_crosswalk_k12_siblings.do`
- `do/share/siblingxwalk/sibling_example.do`

> Yes, but I think some of these files might be used in producing the original input datasets for the VA. However this project does not depend on them. So archive is fine

### 10B. Reproducibility realism [HELPFUL but not blocking]

**B1. Geocoding scripts status**

> You said py_files/ is dead AND that Matt did geocoding via Python. Two possible interpretations: (a) geocoded outputs are already on Scribe as static inputs, so the Python scripts are dead because we don't ever re-run them — reproducibility scope ends at "use the static geocoded dataset"; or (b) the geocoded outputs were lost/regenerated periodically and we'd need the scripts back to actually reproduce. Which is it?

> It's (a). But I was wrong before, this IS the geocoding file, so we should preserve it for completeness and record keeping.

**B2. Outputs: where do figures/tables actually land at the end of a run?**

> Section 3 of the dump still has placeholders for "Where outputs land." On Scribe? Synced to the Dropbox? Manually copied to Overleaf? Knowing the destination affects how the consolidated repo's output paths should be structured.

> They all get produced in Scribe server. You will see the figure and table directories during the deep read of the code. Then I pull them to local and overleaf

**B3. Bit-rot reality check**

> Last full end-to-end run was 2023. In ~3 years: Stata version may have shifted on the server (you said v17 — was it always v17?), some `ssc install` packages may have updated and broken syntax, server filesystem may have moved data dirs, CDE may have re-released cleaned files. What do you predict will be broken when we first try to re-run? Helps me prioritize what to verify when we start ground-truthing.

> It used to be 16, then got updated to 17 and is now 18 on the server. some do files mark the stata versions at the time. The CDE data is up to date, do not worry about raw data. the ssc packages should be able to be run with the replace option, but build in failsafes. 

**B4. Settings.do project-root convention**

> Both repos have a `settings.do`. Does it use `c(hostname)` branching, or hardcode `/home/research/ca_ed_lab/...` paths? If hardcoded, the consolidation will need to introduce hostname-branching for portability. (I can read this off the file directly during deep-read; only flag if there's a quirk worth knowing.)

> They are currently hard coded. The code is never run locally and always on the server so it is not a problem. If you think branching on hostname is better practice then thats fine.

**B5. va_v2 branch merge residue**

> The `va_v2` branch in the fork was merged into `changes_by_che`. Are there v2-prior-score artifacts still in the active codebase (do-files, intermediate dta files) that we should know about, or did the merge cleanly land and v1 is the only active variant?

> The active codebase in changes_by_che has loops for both v1 and v2 which i think is from the merge. I only pull v1 results actively but kept the v2 just in case, because senior coauthors change their mind all the time and I don't want to redo work.

### 10C. Section 2 placeholders worth a sentence each [LOW PRIORITY]

These are placeholders you skipped in section 2. One sentence each is fine.

**C1. What's NOT automated**

> *(steps that need human judgment or manual file-shuffling - any come to mind?)*

**C2. What's broken / only-works-by-accident**

> *(you mentioned last full run was 2023; even at the time, what was held together by hope?)*

**C3. Pipeline diagram**

> *(optional - skip if not useful)*

### 10D. Things I can answer by deep-reading code [no action needed unless I get stuck]

I'll discover these during the deep-read and flag back only if the code is opaque. Just listing them so you know they're on my list:

- D1. Sibling matching specifics (handling of moves, surname change, typos). The user said "see code" -- will trace.
- D2. NSC linkage method (Matt's territory). Will look for the script in `_archive/matt_original/` or elsewhere.
- D3. Distance computation: Euclidean vs driving-time, source list of CA colleges. Will inspect.
- D4. SE clustering: confirm `vce(cluster <school_id>)` is used everywhere consistently. Will inspect.
- D5. Drift implementation: you said custom-modified `vam` in `caschls/do/ado/`. Will read the .ado to understand the modifications.
