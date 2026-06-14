# Project Handoff — Common Core Value-Added (VA) Pipeline

**For:** Paco (incoming PI)
**From:** Christina Sun (CEL, UC Davis)
**Last updated:** 2026-06-13

This document explains what this repository is, what was done to it, how we made sure it's correct, and how to run it. It assumes you are comfortable with Stata but have not used git or Claude Code before. You do not need either of those to run the analysis. The pipeline is ordinary Stata, and you already have access to the project folder on Scribe where it runs. The git section near the end is optional: it's the workflow I used, but you can keep the code in sync however you prefer.

---

## 1. What this repository is

This is the complete Stata pipeline behind the Common Core value-added paper. It cleans the raw data, builds the estimation samples, runs the value-added (VA) estimation, and produces every table and figure in the paper. The paper itself is finished and being submitted to a new journal as-is; it lives in a separate repository (see §9). You are most likely here to re-run part of the analysis or make a small change, not to rebuild the paper from scratch.

The whole pipeline runs from a single Stata file: `do/main.do`. If you remember nothing else, remember that `do/main.do` is the master script and everything else is called from it.

---

## 2. What was done to it, in plain English

### The mess we started with

Before this repository existed, the analysis was spread across several separate projects on the server, built up over years of active research. I (Christina) wrote most of it during my time as the graduate student researcher on the project: the value-added estimation and the CalSCHLS survey cleaning. The school-to-college distance code is originally yours, Paco. A set of outcome crosswalks, a post-secondary merge helper, and a geocoding script were written by Matt Naven; those are kept exactly as he wrote them (see decision record 0017). The pieces lived in different predecessor folders, and each had grown organically.

To run the full analysis end-to-end, you had to know which scripts to run, inside which project folder, in what order, and how each script's output fed the next. That knowledge lived mostly in my head, supported by a couple of "run everything" master scripts that pointed at absolute paths reaching into all of those scattered locations. It worked while I was here and remembered every step. It would not have survived a handoff, which is exactly why this repository exists.

### The dependency problem

The scripts were chained together through shared files. Script A wrote a dataset that Script B read; Script B's output fed Scripts C and D; and so on, sometimes crossing from one predecessor project into another. The problem was that this chain was **implicit**. Nothing in one place said "run these, in this order." A few specific hazards made that risky:

- **Order-dependence with no guardrail.** Some scripts read a cached file that an earlier step was supposed to have produced. Run them out of order, or against a stale cached file, and you got wrong numbers with no error message.
- **Outputs scattered across projects.** A script in one project might write its results into another, so there was no single place to look for "the outputs," and no clean way to compare a new run against an old one.
- **Inputs that drifted.** At least one step downloaded data live from the internet at run time (the state school directory). Two runs on different days could silently produce different results from identical code.

None of these throw an error. They just quietly give you a different (or wrong) answer. They're exactly the failures that surface only when a new person tries to reproduce the work.

### How we resolved it

- **One pipeline, one command.** Every script was moved into a single folder tree (`do/`) and wired into one master script (`do/main.do`) that runs the seven phases in the correct dependency order automatically. There is now a single answer to "what do I run, and in what order": `stata-mp -b do do/main.do`.
- **A self-contained box.** Scripts still read from the original locations where the raw data lives, but they now **write only inside this repository**. That keeps all outputs in one place and made it possible to compare the new pipeline's results against the old pipeline's results cleanly, file by file (see §3).
- **Pinned the drifting inputs.** The school-directory file that used to be downloaded live is now read from a fixed local copy, so the same code produces the same numbers every time. Why and how is written up in the decision log (see §8).
- **Wrote down what used to be tacit.** The run order, the dependencies between phases, and the reasoning behind the load-bearing choices now live in the structure of the master script and in the decision log, instead of in someone's memory.

So in practice: you can reproduce the analysis with one command, and running it the same way twice gives the same answer.

---

## 3. How we know it's correct

The consolidation wasn't just a file-move-and-hope. Three layers of quality control back it up, and the evidence for each is in the repository.

### Layer 1 — A full reproduction test against the original code

After the consolidated pipeline was built, we ran it end-to-end and compared its output against the original pipeline's output, **file by file, across all 8,324 output files** (we called this the "golden master" comparison). The results:

- **Every paper-facing table and figure came out identical** to the original (byte-for-byte).
- **The main value-added estimates matched exactly:** 3,166 estimate files with zero differences in the numbers that matter — every coefficient and standard error. (We compare the estimates themselves, not the raw bytes of the `.ster` files, which can differ harmlessly in metadata like timestamps.)
- The small number of files that *did* differ were each investigated individually and traced to a **known, documented cause**, not a coding error. The main example: a few estimation samples shifted by a small number of students because the old code downloaded the school directory live while the new code reads a fixed copy. We pinned that input so it can't drift again, and recorded the decision.

No difference was left unexplained. The full triage is written up in `quality_reports/reviews/2026-06-10_m4-full-golden-master_triage.md`, so the reasoning is auditable, not just asserted.

### Layer 2 — An automated check suite that runs every time

The pipeline's final phase (Phase 7) runs six automated checks that assert the results are sane before you trust them:

- sample sizes match expected counts,
- data merges join at expected rates,
- value-added estimates fall in plausible ranges,
- the survey indices stay in their valid bounds,
- the paper's table cells match historical magnitudes,
- and every script actually produced its log (so nothing silently skipped).

These are designed to **fail loudly**. If a future change quietly breaks something upstream, the checks stop the run and tell you what went out of bounds, rather than letting bad numbers reach the paper.

### Layer 3 — Human review of every change

This was not a commit-whatever process, and it was not automated rubber-stamping either. I (Christina) personally reviewed every load-bearing change before it was committed, both the code edit itself and the output it produced, and nothing went in until I was satisfied it was correct. Each change was also put through a structured review step scored against a fixed quality bar, so my review was backed by a consistent checklist rather than a quick glance, and a change that didn't clear the bar didn't go in.

The trail is in the git history and the repository, not anecdotal:

- **135 commits carry a recorded review verdict** in their commit message. You can list them on Scribe or GitHub with `git log --grep="coder-critic"`.
- **Over 50 full review reports** are kept in `quality_reports/reviews/`.
- **30 numbered decision records** in `decisions/` explain the "why" behind every substantive choice.

For any part of this pipeline, then, you can answer "what was changed, why, and who checked it" by reading the record.

---

## 4. The mental model: two places the code lives

It helps to keep two copies straight.

- **GitHub** (`https://github.com/chesun/va_consolidated`) is the master copy of the *code*. It's public and holds the scripts, the documentation, and the full history of changes. It holds no data: the confidential data stays on the server, and I built guardrails into the repository to keep it that way (§7).
- **Scribe** (the lab server) is where the pipeline actually *runs*. It has its own copy of the code plus the real data sitting alongside it. The analysis only runs here, because this is the only machine with the restricted data and the right Stata setup.

Code flows from GitHub down to Scribe; the data stays on Scribe; results are produced on Scribe. How you move code between them is up to you (see §7). One method, git, has a built-in safety benefit worth knowing: it can't accidentally copy restricted data onto a local machine the way manual file transfer can. You already have access to the project folder on Scribe, so the code is there and ready to run right now.

---

## 5. How to run the pipeline

Everything here happens on Scribe, in the project folder:

```
/home/research/ca_ed_lab/projects/common_core_va/consolidated
```

### Run the whole thing

```bash
cd /home/research/ca_ed_lab/projects/common_core_va/consolidated
stata-mp -b do do/main.do
```

`stata-mp` is the correct Stata command on the server, and `-b` runs it in batch mode (no interactive window). A full run takes several hours (the VA estimation in Phase 3 is the slow part), so run it in the background so it survives you logging out:

```bash
nohup stata-mp -b do do/main.do &
```

### Watch it while it runs

The master script writes a timestamped log under `log/`. To follow it live:

```bash
tail -f log/main_$(date +%d-%b-%Y)_*.smcl
```

Each script in the run is bracketed with `[RUN]` and `[OK]` markers in that log, so you can see which file is running and which have finished. If a run stops early, the last `[RUN]` without a matching `[OK]` tells you where it failed.

### What the run does, phase by phase

`do/main.do` runs seven phases in order. You don't call any of them yourself; this list is just so you know what's happening:

1. **Data prep** — cleans the raw inputs (CDE files, ACS, the school directory / distance data, etc.).
2. **Sample construction** — builds the estimation samples.
3. **VA estimation** — the value-added estimates. This is the multi-hour step.
4. **VA tables/figures** — intentionally empty; these are produced in Phase 6. It's kept as a numbered phase only.
5. **Survey VA** — the CalSCHLS survey-index value-added.
6. **Paper outputs** — the tables and figures the paper uses.
7. **Data checks** — the automated sanity checks from §3, Layer 2.

### Where the results land

- `data/cleaned/` — cleaned datasets
- `estimates/` — the VA estimate files
- `output/` — intermediate outputs
- `figures/` and `tables/` — the paper's figures and tables
- `log/` — a log file for every script that ran

---

## 6. Running just part of it (partial re-runs)

You usually won't want to sit through the full multi-hour run to regenerate one piece. Two controls at the top of `do/main.do` let you run a subset. Open `do/main.do` and look near the top (around line 130–190).

### Phase toggles

There's one switch per phase:

```stata
local run_data_prep         1
local run_samples           1
local run_va_estimation     1
local run_va_tables         1
local run_survey_va         1
local run_paper_outputs     1
local run_data_checks       1
```

Set a phase to `0` to skip it, `1` to run it. For example, if the cleaned data and VA estimates from a previous run are still on disk and you only want to rebuild the paper tables, set everything to `0` except `run_paper_outputs` (and `run_data_checks` if you want the checks).

**The catch:** a phase can only be skipped if the outputs it would have produced are already on disk from a previous run, because later phases read them. Skip Phase 1 when the cleaned data isn't there and Phase 2 will fail. When in doubt, run from the earliest phase whose inputs you're unsure about.

### The acceptance-run switch

There's also a master override near line 167 (the `m4_` prefix is just an internal build label; you can ignore what it stands for):

```stata
local m4_acceptance_run  1
```

When this is `1`, it forces a full, from-scratch rebuild of everything (it overrides the phase toggles and a few internal sub-switches so that samples and VA estimates are rebuilt rather than read from old cached copies). This is the setting for a canonical, publishable end-to-end run.

For quicker iteration where you trust the cached intermediate files, set it to `0` and use the phase toggles above.

**Rule of thumb:** for a real, results-producing run, set it to `1`. For tinkering and re-running one piece, set it to `0` and use the phase toggles.

---

## 7. Keeping the code in sync (your choice of method)

You already have access to the project folder on Scribe, so the code is there and runnable as-is. You only need this section when you want to **pull a newer version of the code from GitHub**, or **save a change you made**. There are two ways to do that, and which you use is entirely your call.

One reason I used git rather than drag-and-drop: because the data folders aren't tracked, `git pull` brings down only code, never data. Manual file transfer leaves open a real and common mistake (accidentally copying restricted data from the server onto a local machine) that git simply can't make. The choice is still yours, but that's the safety case for git.

### Option A — FileZilla (or any file transfer), no git required

This is the simplest if you don't want to learn git. Download the updated files from the GitHub web page and drag them into the Scribe project folder with FileZilla (or whatever transfer tool you like). To save a change, edit the file on Scribe and, if you want it preserved on GitHub, send it back the same way. Nothing else to learn.

### Option B — git (the workflow I used)

I kept the Scribe copy synced with git, which gives an automatic record of every change. If you want to keep using it, the day-to-day commands are:

```bash
cd /home/research/ca_ed_lab/projects/common_core_va/consolidated

# get the latest code from GitHub
git pull --rebase origin main

# save a change you made (then send it to GitHub)
git add do/path/to/the_file_you_changed.do
git commit -m "short description of what you changed"
git push origin main
```

This is my personal setup, not a requirement; feel free to drop it and use Option A. If you do keep git, three things to know. First, on data safety: I built guardrails at two levels so confidential data can't reach GitHub, even by accident. The data folders are configured so git never tracks their contents, and on top of that an automatic guard blocks any push that would carry a data file off the server (a message like `refusing to push — restricted data files...` is that guard working as intended). It runs on its own; there's nothing you need to manage. Second, if `git pull` ever reports a conflict or any state you don't recognize, stop and ask rather than improvising, since a wrong move there can be hard to undo. Third, the full git setup-and-troubleshooting guide, including a table of common errors and their fixes, is at `quality_reports/plans/2026-05-25_scribe-setup.md`.

**Either way, the separation is built in:** the code lives on GitHub, and the confidential data stays on the server.

---

## 8. Where everything is

```
consolidated/
├── do/                  ALL the Stata code
│   ├── main.do          the master script — start here
│   ├── settings.do      defines every file path the pipeline uses
│   ├── data_prep/       cleaning scripts
│   ├── samples/         sample construction
│   ├── va/              value-added estimation
│   ├── survey_va/       CalSCHLS survey-index VA
│   ├── share/           shared table/figure helpers
│   └── check/           the automated data checks (Phase 7) + the golden-master comparison
├── data/                confidential data; never leaves the server, never tracked by git
├── estimates/           VA estimate files (Scribe only)
├── output/              intermediate outputs
├── figures/, tables/    the paper's figures and tables
├── log/                 a log per script
├── ado/                 a couple of custom Stata packages the pipeline needs
├── decisions/           short dated notes explaining WHY key choices were made
└── quality_reports/     the review reports and run logs from the build (the §3 evidence)
```

Two folders are worth a sentence each:

- **`do/settings.do`** is where all the file paths are defined. It detects that it's running on Scribe and sets the paths accordingly. If a path ever needs to change, this is the one place to change it; the scripts all read their paths from here.
- **`decisions/`** holds the "why" notes (each a short dated file, numbered `0001`, `0002`, …, with an index in `decisions/README.md`). When you wonder "why does it do *that*?", look here first. For instance, the choice to read a fixed local copy of the school directory instead of downloading a fresh one each run (the reproducibility fix from §2) is written up there.

You'll also see a `.claude/` folder and files like `CLAUDE.md`. These are configuration and notes from the AI-assisted tooling I used while building the repository. **You can ignore them to run the analysis** — they aren't part of the pipeline.

---

## 9. The paper

The paper is a **separate repository**, kept at:

```
~/github_repos/va_paper_clone
```

It's finished and being submitted to a new journal as-is, so you shouldn't need to rebuild it. The figures and tables it uses are the ones this pipeline produces (in `figures/` and `tables/`). If a number in the paper ever needs to change, the change starts here in the analysis and flows out to the paper, never the other way around.

---

## 10. If something breaks, and where to look next

- **Stata command.** On Scribe the pipeline runs under Stata MP, invoked as `stata-mp`. Always use `stata-mp` (not plain `stata`). If `stata-mp` isn't found, ask the lab how Stata is set up on the server.
- **Missing packages.** The pipeline uses a handful of community Stata packages (from SSC). If a run fails saying a command doesn't exist, open `do/main.do` near the top, set `installssc` to `1` for one run to install everything needed, then set it back to `0`.
- **A check failed in Phase 7.** That's the safety net working. The check's log message names what was out of bounds; the `decisions/` notes and `quality_reports/` reviews often already explain expected, accepted differences.
- **A git error** (only if you use Option B). The full setup-and-troubleshooting guide, including a table of common errors and fixes, is at `quality_reports/plans/2026-05-25_scribe-setup.md`.
- **Anything else.** I built this and am the best contact during the transition.

### Want more detail?

- `decisions/README.md` — index of every documented decision, one line each.
- `quality_reports/reviews/` — the review reports and the golden-master triage (the §3 evidence).
- `quality_reports/plans/2026-05-25_scribe-setup.md` — complete git setup, sync rhythm, and error fixes (only relevant if you use git).
- `CLAUDE.md` — the original full project map and conventions; more than you need to run it, but the most complete reference.

---

*This is a living document. If something here is unclear or turns out to be wrong, please correct it — the next person to read it will thank you.*
