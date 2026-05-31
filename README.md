<!-- primary-source-ok: sun_2026 -->

# Common Core Value-Added (CEL UC Davis) — Consolidated Pipeline

> **Status note (2026-04-29):** This README is a Phase 1c §5.2 PRE-DRAFT — a runnable skeleton for the offboarding-era operator. The final polish pass and cold-read test happen as part of Phase 1c §5.4 (per ADR-0018). Sections marked *[VERIFY at offboarding]* depend on Phase 1a §3.3 relocation outputs that aren't yet on Scribe.

---

## 1. Quick overview

This repo holds the **consolidated Stata pipeline** for the *Common Core Value-Added* project at the California Education Lab, UC Davis (Carrell, Kurlaender, Martorell, Naven, Sun — "Do Schools Matter?"). The pipeline produces:

- **School-level value-added estimates** for ~1,400 California high schools across 4 cohorts of 11th-graders (2014-15 through 2017-18, ~2M student-years), using a CFR-style "value-added with drift" estimator.
- **Survey-VA mechanism analysis** linking VA estimates to CalSCHLS school-climate, school-quality, and student-support indices (~5,600 schools).
- **Paper-shipping tables and figures** consumed by the working draft (paper LaTeX is canonical at a separate repo — see §10).

The repo is the consolidated successor to **two predecessor codebases**:

- `cde_va_project_fork` — VA estimation (originally Matt Naven's; subsequently extended and refactored by Christina Sun).
- `caschls` — CalSCHLS survey processing + sibling-link construction.

End-state: this repo is the offboarding deliverable to **Kramer** (CEL data-management custodian). A future successor inheriting this codebase clones the GitHub `v1.0-final` tag and runs the pipeline on Scribe. See §10 for the project history and §9 if something breaks.

**Constraints to know before starting:**

- This is a **Stata pipeline**. The single entry point is `do/main.do`. Stata 17 is the supported version; Stata 18 may work but is unverified.
- The pipeline runs **only on the lab's Scribe server**. It will not run on your local machine — paths and restricted-access data live on Scribe.
- **You need SSH access to Scribe.** Lab IT (see §9) provisions accounts. No `~/.ssh/config` aliases or key-authentication setup is required (per ADR-0020); password-prompt SSH is fine.

---

## 2. How to run the pipeline

This is the most important section. If you only read one section, read this one.

### One-time setup

1. **Get SSH access to Scribe** from CEL lab IT (see §9). They issue you a username (e.g., `<your_username>`); the host is `Scribe.ssds.ucdavis.edu` (the canonical lab-IT-issued form uses capital `S`; in practice DNS resolution is case-insensitive).

2. **Clone this repo** to your local machine:

    ```
    git clone https://github.com/chesun/va_consolidated.git
    ```

   If you don't use git: download the ZIP from the GitHub repo's "Code → Download ZIP" button.

3. **Push the working tree to Scribe** at the consolidated folder. Operator-choice file-transfer per ADR-0020 — Christina used FileZilla. Common alternatives: `scp -r`, `rsync`, drag-and-drop in Cyberduck. Destination on Scribe:

    ```
    /home/research/ca_ed_lab/projects/common_core_va/consolidated/
    ```

   *Do NOT push the `.git/` folder to Scribe.* Per ADR-0007, no GitHub credentials live on the restricted server.

4. **Install required Stata packages** on Scribe (one-time per Scribe account):

    ```
    ssh <your_username>@Scribe.ssds.ucdavis.edu
    cd /home/research/ca_ed_lab/projects/common_core_va/consolidated
    stata -b
    ```

   In Stata: `ssc install <package>` for each entry in `.claude/rules/stata-code-conventions.md` Required Packages. As of `v1.0-final` the list is: `reghdfe, estout, coefplot, ivreghdfe, palettes, cleanplots, egenmore, regsave, cdfplot, binscatter, binscatter2, filelist`. Plus the vendored `vam.ado` under `ado/` (per ADR-0006; do NOT replace with the upstream version — see §7).

### Running the pipeline

From a Scribe SSH session:

```
cd /home/research/ca_ed_lab/projects/common_core_va/consolidated
stata -b do do/main.do
```

That's it. `main.do` orchestrates the whole pipeline through 7 phases (data prep → samples → VA estimation → VA tables → survey-VA → paper outputs → automated data checks). Each phase has a toggle near the top of `do/main.do`; defaults are all ON. A successful run produces:

- Logs under `log/` (one `.smcl` + `.log` per do file).
- Cleaned data under `data/cleaned/`.
- VA estimates under `estimates/`.
- Paper-shipping tables under `tables/` and figures under `figures/`.
- A clean `data-checks` block at the end (Phase 7) with all assertions PASSING.

### Running only one phase

Edit the toggles near line 75 of `do/main.do`. Set the phases you don't want to 0:

```stata
local run_data_prep         0    /* skip: data already cleaned */
local run_samples           0    /* skip: samples already built */
local run_va_estimation     1    /* run only this */
local run_va_tables         0
local run_survey_va         0
local run_paper_outputs     0
local run_data_checks       0
```

Production / acceptance runs (per ADR-0018) require **all toggles ON**, including `run_data_checks`.

### Expected runtime

*[VERIFY at offboarding]* — full-pipeline runtime documented after the §5.4 acceptance run. Predecessor pipeline ran in several hours end-to-end on Scribe.

---

## 3. What to know — folder map

Top-level structure of the repo (what you'll see on Scribe under `consolidated/`):

```
consolidated/
├── README.md            # this file — your starting point
├── CLAUDE.md            # detailed project instructions; mirrors this file with more depth
├── MEMORY.md            # accumulated learnings + conventions discovered during consolidation
├── TODO.md              # what's open / done / pending
├── SESSION_REPORT.md    # consolidated operations log across all working sessions
│
├── do/                  # ALL Stata code lives here. Run `stata -b do do/main.do` from `consolidated/`.
│   ├── main.do          # the single entry point — phase toggles + orchestration
│   ├── settings.do      # path globals (Scribe-branched); included by main.do
│   ├── data_prep/       # raw → cleaned data transformations
│   ├── samples/         # analytic-sample construction
│   ├── sibling_xwalk/   # sibling crosswalk (per ADR-0005)
│   ├── va/              # value-added estimation (helpers, score, outcome, heterogeneity, pass_through)
│   ├── survey_va/       # CalSCHLS index construction + survey-VA regressions
│   ├── share/           # paper-shipping tables + figures (per ADR-0012)
│   ├── check/           # automated data-quality assertions (Phase 7)
│   ├── upstream/        # one-off prep that produces static project inputs
│   ├── debug/, explore/ # ad-hoc / exploratory; not invoked from main.do
│   ├── local/           # operator-machine ad-hoc scripts; not invoked from main.do
│   └── _archive/        # historical / superseded code; never invoked
│
├── ado/                 # vendored .ado files (vam.ado pinned at v2.0.1 — DO NOT MODIFY per §7)
│
├── decisions/           # ADRs (architecture decision records) — append-only; numbered
├── master_supporting_docs/  # cited primary sources + reading notes; data documentation
├── quality_reports/     # plans, reviews, audits, session logs (consolidation history)
│
├── data/                # input + cleaned data (gitignored on GitHub; lives only on Scribe)
│   ├── raw/             # untouched source data; DO NOT MODIFY (§7)
│   └── cleaned/         # cleaned datasets produced by Phase 1 (data_prep)
├── estimates/           # VA estimates produced by Phase 3 (gitignored)
├── output/              # intermediate non-paper outputs (gitignored)
├── log/                 # Stata logs from main.do runs (gitignored)
├── tables/              # paper-shipping tables (tracked in git)
├── figures/             # paper-shipping figures (tracked in git)
└── py/                  # one Python script (geocoding) — see §7
```

*Anything under `data/`, `estimates/`, `output/`, `log/` is gitignored — those folders only exist on Scribe at runtime, not in the GitHub repo. The folder structure on Scribe matches the layout above.*

---

## 4. Data flow

The pipeline is 7 phases. Each phase reads from the previous phase's outputs (or from raw/static inputs).

| Phase | What it does | Reads | Writes |
|------:|---|---|---|
| 1. data_prep | Cleans raw K12 enrollment, ACS school-neighborhood, school characteristics, K12-postsec distance, CalSCHLS QOI items | `data/raw/`, predecessor static inputs | `data/cleaned/` |
| 2. samples | Builds analytic samples (VA-eligible students, sibling crosswalk, sibling × ACS restrictions) | `data/cleaned/` | `estimates/<sample-name>/` |
| 3. va_estimation | Estimates score-VA + outcome-VA (CFR drift) per ADR-0004; runs heterogeneity + pass-through regressions | sample dta files | `estimates/va_cfr_all_v1/` |
| 4. va_tables | Produces VA tables + figures (paper Tables 2-3 spec/FB tests, etc.) per ADR-0012 | `estimates/va_cfr_all_v1/` | `tables/share/va/`, `figures/share/va/` |
| 5. survey_va | Builds CalSCHLS climate/quality/support indices (per ADR-0010 + ADR-0011); runs survey-VA regressions (paper Table 8) | CalSCHLS source data | `estimates/calschls/` |
| 6. paper_outputs | Produces non-VA paper tables (Table 1, A.1 sample restrictions, descriptive stats) | sample dta files | `tables/share/`, `figures/share/` |
| 7. data_checks | Runs assertion-based sanity checks (sample sizes, merge rates, VA centeredness, CalSCHLS Likert ranges, paper-cell magnitudes); halts on regression | analytic-pipeline outputs | `log/check_*.log` |

For more depth on what each script does, see the one-liner descriptions in `do/main.do` (each `do do/<path>/<file>.do` line carries a comment summarizing the called script's role per ADR-0021).

---

## 5. Where outputs go (the "sandbox principle")

This repo follows a **self-contained sandbox** convention (per ADR-0021). Two classes of paths:

- **CANONICAL paths** — under `\$consolidated_dir` (the `consolidated/` folder on Scribe). Pipeline scripts may read AND write these freely. These are: `\$datadir`, `\$datadir_clean`, `\$datadir_raw`, `\$logdir`, `\$estimates_dir`, `\$output_dir`, plus the tracked `tables/` and `figures/`.
- **LEGACY paths** — predecessor repos and restricted-access raw data. Pipeline scripts may **read** these (for static inputs like CalSCHLS surveys, NSC crosswalks, Matt's files) but **must not write** to them. These are: `\$matt_files_dir`, `\$vaprojdir`, `\$vaprojxwalks`, `\$caschls_projdir`, `\$nscdtadir`, `\$mattxwalks`.

Globals are defined in `do/settings.do` and labeled there. The payoff: a future operator can run `diff -r consolidated/output predecessor/output` to compare the two pipelines without polluting either tree.

**If you write a new script that produces a new output:** save it to a CANONICAL path. The per-commit checklist (`.claude/rules/phase-1-review.md` §2) and `do/check/check_*.do` data-checks pipeline both enforce this.

---

## 6. How to make changes — 3 common cases

### 6.1 Re-running after a data refresh (e.g., a new cohort year)

1. Update `data/raw/` on Scribe with the new raw files (paths follow predecessor conventions; see `do/data_prep/` headers for which file each script reads).
2. Re-run the full pipeline: `stata -b do do/main.do` from `consolidated/` with all toggles ON.
3. Verify Phase 7 (`run_data_checks`) passes. Per-cohort N counts in `do/check/check_samples.do` will need updating to reflect the new cohort (the assertions are hardcoded against the 2015-2018 cohorts; see the design memo `quality_reports/reviews/2026-04-28_data-checks-design.md` §2 for the bound rationale).
4. Compare new outputs against the prior run's outputs.

### 6.2 Tweaking a specification (e.g., adding a control, changing SE clustering)

1. Find the relevant script under `do/va/` (estimation), `do/samples/` (sample construction), or `do/share/` (output formatting). Each script has a header block explaining its purpose, inputs, outputs, and references (per ADR-0021).
2. Make the edit. Save outputs to a CANONICAL path (not a LEGACY path — see §5).
3. Re-run the affected phase only by toggling the others off in `do/main.do`.
4. Re-run Phase 7 (`run_data_checks`) — some assertions may need updating if the spec change is load-bearing.
5. Compare new outputs against the prior run's outputs.

### 6.3 Adding a new analysis (new outcome, new heterogeneity cut, etc.)

1. Write the new script under the appropriate `do/` subfolder (most likely `do/va/heterogeneity/`, `do/share/`, or `do/survey_va/`). Mirror the header style of existing scripts (header block + per-do-file logging).
2. Add a `do do/<path>/<new-script>.do` invocation in the relevant Phase block of `do/main.do`, with a `// <one-liner>` description per the ADR-0021 description convention.
3. If the script produces a new dataset that other scripts will read, add a corresponding assertion to the most relevant `do/check/check_*.do` file (header citation: design memo + the ADR-0021 sandbox-write principle).
4. Run the full pipeline + verify Phase 7 passes.

For all three cases: **check `MEMORY.md` first** — it has accumulated learnings about gotchas (e.g., `codebook` leaking PII; `filelist` package usage; CalSCHLS Likert ranges; etc.) that may save you debugging time.

---

## 7. What NOT to touch

A short list of files and conventions you should leave alone unless you have a specific reason and have read the relevant ADR.

| Don't touch | Why | Reference |
|---|---|---|
| `ado/vam.ado` | Pinned at v2.0.1 with the `noseed` fix vendored. Newer upstream `vam.ado` versions have changed the random-seed handling and will produce different VA estimates. | ADR-0006 |
| Matt Naven's files at `/home/research/ca_ed_lab/projects/common_core_va/do_files/` (on Scribe — NOT in this repo) | Static, run-once-cached crosswalks (NSC, CCC, CSU outcomes; `merge_k12_postsecondary.doh`; `gecode_json.py`). Their `.dta` outputs are inputs to this pipeline. Per ADR-0017 they stay in their predecessor location. | ADR-0017 |
| `data/raw/` | Raw source data; never overwrite or modify. The pipeline only writes to `data/cleaned/` and below. | ADR-0007 |
| `decisions/<NNNN>_*.md` after they're marked Decided | ADRs are append-only. Don't edit a Decided ADR's body. If a decision changes, write a new ADR with `Supersedes: #NNNN` in its header. | `.claude/rules/decision-log.md` |
| LEGACY-path globals as write targets in any new code | Breaks the sandbox principle (§5). Reads from LEGACY paths are fine; writes are not. | ADR-0021 |
| Your SSH password / Scribe credentials in any tracked file | This repo is on public GitHub. Credentials never go in code, comments, or commit messages. | ADR-0007 |
| `py/upstream/gecode_json.py` (Python geocoding) | Matt-authored; produces static crosswalks; runs once and caches. Per ADR-0017 untouched in Phase 1. | ADR-0003, ADR-0017 |

---

## 8. Where things are documented

| You want to know | Look here |
|---|---|
| Why a particular design decision was made | `decisions/` — ADRs numbered 0001-0021 (as of `v1.0-final`). Index at `decisions/README.md`. |
| The full project history (operations log) | `SESSION_REPORT.md` — append-only consolidated log across all working sessions. |
| The audit trail of what was reviewed and how | `quality_reports/reviews/` — code reviews, paper maps, audit memos. |
| The plans + protocols followed | `quality_reports/plans/` — most recent is `2026-04-27_phase-1-consolidation-plan-v3.md` (status APPROVED). |
| The audits and discrepancy reports from Phase 0 | `quality_reports/audits/` — Phase 0a deep-read audit + T1 empirical-test results + T4 Q&A walkthrough. |
| Per-session detailed work logs | `quality_reports/session_logs/` — one file per session. |
| Cited papers + reading notes | `master_supporting_docs/literature/` — papers under `papers/`, notes under `reading_notes/`. |
| Codebooks for source datasets | `master_supporting_docs/codebooks/` (gitignored on GitHub for PII reasons; on Scribe under the same folder). |
| Stata code-style conventions | `.claude/rules/stata-code-conventions.md` |
| Required Stata packages | Same file, "Required Packages" section. |
| The ADR-0021 sandbox principle | `decisions/0021_main-settings-relocation-and-self-contained-sandbox.md` + this README §5. |
| Accumulated gotchas + learnings | `MEMORY.md` — `[LEARN:category]` entries. |

---

## 9. When something breaks

### First steps

1. **Check the most recent log under `log/`** — Stata writes a `.smcl` per do file. Look for `r(<error-code>)` in the orchestration log `log/main_<timestamp>.smcl`. The offending do file's own log will have the failure context.
2. **Check Phase 7 data-check output** — if `run_data_checks` triggered the failure, the assertion message tells you which invariant failed and points to the relevant codebook line.
3. **Check `MEMORY.md`** — the `[LEARN:category]` entries cover gotchas Christina ran into during consolidation.
4. **Check the relevant ADR** — `decisions/README.md` has a one-line summary per ADR; the ADR body has rationale + cross-references.

### If you can't resolve it

- **Christina Sun** — project author. Email: `christinasun101@gmail.com` (offboarding-era contact). She wrote the consolidation pipeline 2026-04-24 through `v1.0-final`.
- **Kramer (CEL data-management custodian)** — owns the offboarding deposit per ADR-0018. Best contact for: access to Scribe, location of restricted-access data, lab IT escalation.
- **CEL lab IT** — provisions Scribe SSH accounts; handles server-side issues. *[VERIFY at offboarding]* — at offboarding, the lab IT contact + escalation path is recorded in the offboarding memo under `quality_reports/handoff/` (folder exists; the dated memo lands there at the offboarding event per ADR-0018).

### Codebook ambiguities — there is no provider PDF

There are no provider PDF codebooks for this project. The Stata-generated codebook log under `master_supporting_docs/codebooks/` captures empirical metadata (ranges, label-to-numeric maps) — useful for the data-checks pipeline (Phase 7), not for resolving semantic questions about what a code means. If you hit an ambiguous code (e.g., "what does NSC sector code 5 mean?", "what's the CalSCHLS convention for skipped vs. truly-missing items?"):

- **During the project (pre-`v1.0-final`):** route to Christina. She is the codebook authority.
- **Post-`v1.0-final`:** check `quality_reports/handoff/` for the offboarding memo, which surfaces residual semantic ambiguities Christina identified but didn't resolve before deposit. If your question isn't in the memo, it's a true open unknown — document it in your own working notes; there is no further authority to consult.

### Specific failure modes documented during consolidation

- `filelist` ssc not installed → `do/check/check_logs.do` fails immediately with `r(199)`. Fix: `ssc install filelist` from inside Stata on Scribe. (Per `MEMORY.md` 2026-04-29.)
- `\$consolidated_dir` not found at the expected Scribe path → `do/settings.do` fails with `r(601)`. Means you're running Stata from the wrong CWD (must be `/home/research/.../consolidated/`) or the folder hasn't been transferred to Scribe yet.
- `codebook` command leaks PII when run on bridge crosswalks → known pattern from 2026-04-28; the `do/explore/codebook_export.do` script has a `cap drop` PII block at the top of each `use`. Don't remove the scrub.

---

## 10. Project history

### Predecessor codebases

This repo merges two previously-separate codebases (both on `~/github_repos/` on Christina's local machine; archived at `v1.0-archive` tag of each):

- `~/github_repos/cde_va_project_fork` — VA estimation. Originally Matt Naven's; subsequently extended and refactored by Christina Sun (2022 onward). Master file was `do_files/do_all.do`; replaced by `do/main.do` here.
- `<Christina's Dropbox>/Davis/Research_Projects/Ed Lab GSR/caschls` — CalSCHLS survey processing + sibling-link construction. Master file was `do/master.do`; integrated into Phase 5 (survey_va) + Phase 2 (sibling_xwalk) here. *(Lives outside `~/github_repos/` — Christina's local working copy is on Dropbox; on Scribe the predecessor is at `/home/research/ca_ed_lab/users/chesun/gsr/caschls` per `do/settings.do` `$caschls_projdir`.)*

A third historical predecessor — `ca_ed_lab-common_core_va` (workflow merge attempt 2022) — is **out of scope** per ADR-0001; it was abandoned before completion.

### Key architectural decisions

The consolidation philosophy (in 7 ADRs you'd want to read first):

- **ADR-0001** — In-scope: cde_va_project_fork + caschls. Out-of-scope: superseded merges.
- **ADR-0002** — Runtime: Scribe-only via SSH.
- **ADR-0007** — Code/data separation; GitHub holds code+docs+tables+figures only; data lives on Scribe.
- **ADR-0017** — Matt Naven's files stay untouched in their predecessor location.
- **ADR-0018** — Offboarding model: Kramer is custodian; successor is unknown at offboarding time; `v1.0-final` tag freezes the deliverable.
- **ADR-0020** — File transfer Scribe ↔ local is operator-choice (FileZilla today).
- **ADR-0021** — main.do/settings.do under do/; consolidated/ is a self-contained output sandbox; every do file has a header description + a one-liner in main.do.

The full ledger of 21 ADRs is at `decisions/README.md`.

### Repo provenance + GitHub

This repo is at **<https://github.com/chesun/va_consolidated>**. The `v1.0-final` tag (when reached) is the offboarding-canonical version. Subsequent edits (if any) are post-deposit and not part of the deposit.

The infrastructure (rules, agent definitions, hooks under `.claude/`) is based on `claude-code-my-workflow` (applied-micro overlay), forked 2026-04-24 and customized for this project.

### Paper

The paper LaTeX is at a separate repository: `~/github_repos/va_paper_clone/paper/common_core_va_v2.tex` (Carrell, Kurlaender, Martorell, Naven, Sun — "Do Schools Matter?"). This pipeline produces the tables and figures that the paper LaTeX `\input{}`'s. Paper status: submitted, rejected, in limbo as of `v1.0-final`. See `quality_reports/reviews/2026-04-24_paper-map.md` for the table-by-table mapping from paper to producing scripts.

