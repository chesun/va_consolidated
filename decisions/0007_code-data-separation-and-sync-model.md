# 0007: Code-data separation; Scribe consolidated/ as non-git working copy; GitHub as frozen archive at handoff

- **Date:** 2026-04-27
- **Status:** Decided
- **Scope:** Infrastructure
- **Data quality:** Full context

## Context

Three constraints converged on 2026-04-27 to require an explicit architecture decision:

1. **Restricted data.** Common Core VA data are CDE-restricted and live only on Scribe. They cannot be checked into a public GitHub repo (and even a private GitHub repo introduces accidental-exposure risk). The project's air-gapped-workflow rule already treats Scribe as restricted.
2. **Network exposure concern.** Cloning the GitHub remote on Scribe creates a credential-bearing channel between the restricted server and the public internet. Even with strict `.gitignore`, an accidental `git push` of staged data files, a compromised SSH key, or a malicious upstream commit could exfiltrate or corrupt restricted data. Christina (2026-04-27) flagged this risk explicitly.
3. **Handoff endpoint.** After Phase 1, Christina hands the project to a senior coauthor with Stata skill but no git or data-management experience. Any architecture that requires the successor to use git, sync code between two locations, or maintain `.gitignore` discipline will not survive the handoff.

The audit trail / traceback motivation is also explicit: the 3-month consolidation produces decisions (ADRs), session logs, and code edits that future-Christina or the senior coauthor must be able to reconstruct without insider context. The architecture below makes the GitHub repo the durable record of that audit trail.

## Decision

**Code-data separation:**

- The GitHub repo `va_consolidated` (origin: `github.com/chesun/va_consolidated`) holds **code, documentation, ADRs, reading notes, paper LaTeX, table fragments, and figures**. It does NOT hold raw data, intermediate `.dta` files, estimation `.ster` files, runtime logs, or any output that depends on restricted CDE data.
- Scribe holds **everything**: a working copy of the GitHub repo's contents PLUS the restricted data, intermediate files, and logs. Location: `/home/research/ca_ed_lab/projects/common_core_va/consolidated/`.
- Scribe's `consolidated/` folder is a **non-git working copy** — no `.git/` directory exists on Scribe at any point.

**Sync model (Christina's tenure):**

- Christina maintains the canonical git clone on her local Mac at `~/github_repos/va_consolidated/`.
- `git push` / `git pull` flows between local Mac and GitHub origin.
- Code, docs, tables, and figures sync from local Mac to Scribe via one-way `rsync` over SSH:

  ```bash
  rsync -avz --delete \
    --exclude='.git/' \
    --exclude='data/' --exclude='estimates/' \
    --exclude='log/' --exclude='output/' \
    --exclude='*.dta' --exclude='*.smcl' --exclude='*.log' \
    ~/github_repos/va_consolidated/ \
    scribe:/home/research/ca_ed_lab/projects/common_core_va/consolidated/
  ```

- Tables and figures produced on Scribe rsync back to local for git commit:

  ```bash
  rsync -avz scribe:.../consolidated/tables/ ~/github_repos/va_consolidated/tables/
  rsync -avz scribe:.../consolidated/figures/ ~/github_repos/va_consolidated/figures/
  ```

- A `VERSION` marker file on Scribe records the git SHA of the synced state, so when something breaks Christina can identify which commit Scribe is running:

  ```bash
  git -C ~/github_repos/va_consolidated rev-parse HEAD > /tmp/v
  scp /tmp/v scribe:.../consolidated/VERSION
  ```

- SSH `ControlMaster` keeps the authenticated session warm so multiple rsync calls within a session don't re-prompt. (Scribe does not require 2FA, so single-prompt SSH suffices.)

**`.gitignore` policy:**

The repo's `.gitignore` excludes the directories that only exist on Scribe and the file types that are runtime-only. Tables and figures (per Christina 2026-04-27) are TRACKED — including exploratory and intermediate ones — to provide a historical archive for senior-coauthor revisions.

```
data/
estimates/
log/
output/
*.dta
*.smcl
*.log
*.ster
.DS_Store
```

`tables/` and `figures/` are NOT in `.gitignore`.

**Handoff endpoint:**

When Phase 1 completes and Christina hands off:

- Final commit pushed to GitHub. The GitHub repo becomes a **frozen, read-only archive** of the project's decision history (ADRs, session logs, audit trail, code state at handoff).
- Scribe `consolidated/` becomes the **canonical** version going forward. The senior coauthor edits Scribe directly. They do not need git, do not need GitHub, and do not need to know about either.
- Christina hands over: SSH credentials (or onboarding to the lab's Scribe access), and the `consolidated/README.md` (see below).

**Single README for both audiences:**

`README.md` at the repo root serves both the GitHub-archive viewer and the post-handoff Scribe maintainer. Phase 1 deliverable: rewrite the current placeholder README for a Stata-skilled, non-git successor. Operational sections (how to run, folder map, data flow, what not to touch) at the top; archive sections (project history, GitHub link, decision pointers) at the bottom.

**Documentation discipline during consolidation:**

Every ADR, session log, audit doc, and commit message produced during these 3 months is written with the eventual successor in mind. Cross-reference paths over inline reproduction; cite ADR numbers; explain WHY decisions were made (not just WHAT). The `decisions/` directory + `quality_reports/` together form the auditable trail of how the consolidated repo came to exist. The README links to both.

## Consequences

**Commits us to:**

- A two-step "edit on local, test on Scribe" loop during consolidation. Wrapper script `sync_to_scribe.sh` (Phase 1 deliverable) does commit-rsync-version-tag in one command.
- README rewrite as a Phase 1 deliverable, structured for the actual successor.
- A single discipline going forward: every change documented in a way that survives handoff. ADRs cite sources; session logs date-stamp progress; commit messages explain WHY.
- `.git/` never touches Scribe. Net consequence: no GitHub credentials on the restricted server, no risk of accidental data push, no software-supply-chain attack surface from a malicious upstream commit landing on Scribe.
- Tables and figures balloon the repo modestly over 3 months (small `.tex` fragments + small `.pdf` files). Acceptable cost for the historical-archive value.

**Rules out:**

- Cloning the GitHub remote onto Scribe.
- A workflow that requires the successor to use git or maintain `.gitignore` discipline.
- Splitting documentation across `README.md` and a separate `HANDOFF.md` (single doc, single source of truth).
- Treating the GitHub repo as a permanent collaboration platform — it's a frozen archive at handoff, not a living maintained codebase past Phase 1.

**Open questions:**

- Whether a wrapper script (`sync_to_scribe.sh`) is committed to the repo or kept as a local-only tool. Likely committed for reproducibility, but it bakes in Christina's local path — needs to be parameterizable. Defer to Phase 1.
- Whether file size of tracked tables/figures becomes an issue over 3 months. Monitor; if any single artifact > 50MB, revisit (likely move to Git LFS or gitignore that one path).
- Post-handoff: who has SSH access to Scribe besides Christina and the senior coauthor? Lab onboarding question, not architecture.

## Sources

- 2026-04-27 conversation: code-data separation + SSH-login-no-2FA + handoff to non-git successor
- `.claude/rules/air-gapped-workflow.md` (existing project rule treating Scribe as restricted)
- `CLAUDE.md` (folder layout reserves `data/`, `tables/`, `figures/`, etc. — confirmed not all in git)
- Related: ADR-0001 (consolidation scope), ADR-0002 (runtime — Scribe only), ADR-0003 (languages)
- Related: ADR-0008 (external crosswalks vendoring — uses the architecture pinned here)
- Related: ADR-0017 (Matt's files untouched — the no-touch rule applies per file ownership; this ADR is about repo-vs-server placement, distinct concern)
