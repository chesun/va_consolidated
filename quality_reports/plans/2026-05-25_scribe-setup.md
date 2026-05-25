# Scribe-side Setup: Sync Hygiene, Sparse Checkout, Pre-push Guard

**Date:** 2026-05-25
**Status:** Active reference (execute on Scribe; update if any step changes)
**Audience:** Christina, working on the Scribe server side of the va_consolidated repo
**Related:** commit `e31fe15` (gitignore + .githooks/pre-push); CLAUDE.md §"Runtime location"; `.claude/rules/air-gapped-workflow.md`

---

## Why this doc exists

Scribe has a checkout of `va_consolidated` that is *operationally* divergent from the GitHub remote:

| Difference | On laptop (origin/main) | On Scribe |
|---|---|---|
| `data/` | `.gitkeep` stubs only | Populated with restricted CalSCHLS / CDE records (PII) |
| `estimates/` | `.gitkeep` stub only (as of `e31fe15`) | Populated with `.ster` + `va_<outcome>_all.dta` |
| `figures/`, `tables/`, `output/` | `.gitkeep` stubs (plus committed paper-class files) | Populated with run-time outputs |
| `log/` | Tracked smcl/log audit trail (committed) | Re-written by each run |
| `.claude/`, `quality_reports/`, etc. | Tracked Claude workflow infra | Should NOT exist (no Claude on Scribe) |

The Scribe checkout was also `git init`'d / set up separately at some point, so its commit history may have local commits that don't exist on origin. Hence: divergent branches.

This doc covers three independent setup tasks:

1. **Resolve the current divergence** so `git pull origin main` works.
2. **Sparse-checkout** so `.claude/` (and optionally other Claude-only dirs) never materialize in the Scribe working tree.
3. **Activate the pre-push hook** so accidental `git add -f data/` cannot escape Scribe.

Tasks are independent — you can do them in any order, but the suggested order is 1 → 2 → 3 because (1) is blocking the next pull.

---

## Pre-flight: diagnose what's actually divergent

Before any reconciliation, run these on Scribe to see the shape of the divergence. Each is read-only; nothing is changed.

```bash
cd /home/research/ca_ed_lab/projects/common_core_va/consolidated

# Make sure origin is set correctly
git remote -v
# Expect: origin  https://github.com/chesun/va_consolidated.git (fetch)
#         origin  https://github.com/chesun/va_consolidated.git (push)

# Fetch the latest remote state (this doesn't modify your working tree)
git fetch origin

# Commits ONLY on Scribe (not on origin/main)
git log --oneline origin/main..HEAD
# This is what Scribe has that GitHub doesn't.  Usually setup commits,
# accidental commits of generated content, or partial work-in-progress.

# Commits ONLY on origin/main (not on Scribe)
git log --oneline HEAD..origin/main
# This is what GitHub has that Scribe doesn't.  Should include
# 184ff0d (clean_va reorder), 932a3fc (M4 logs), e31fe15 (gitignore + hook),
# plus the four workflow-sync commits from 2026-05-24.

# Are there any uncommitted local changes?
git status
```

Now read what you found. The next step depends on what's in `git log --oneline origin/main..HEAD`.

---

## Step 1: Resolve the divergence

Three branches based on the diagnosis above:

### Branch A — Scribe has no commits ahead of origin (the simplest case)

If `git log --oneline origin/main..HEAD` is empty, the only divergence is that `git status` shows local file modifications. Fix:

```bash
# Stash uncommitted changes
git stash push -u -m "scribe-pre-sync $(date +%Y-%m-%d)"

# Fast-forward pull
git pull origin main

# Inspect what was stashed; un-stash if still wanted
git stash list
git stash pop          # restores changes (may conflict if same files were touched on origin)
# OR: git stash drop   # discard
```

### Branch B — Scribe has commits ahead of origin, AND those commits are wanted

The commits should be replayed on top of origin/main. Use rebase. **Read the contents of each Scribe-only commit first** — if any commit added `data/` or `estimates/` files, do NOT push afterward (the new pre-push hook would catch it, but better to fix locally first).

```bash
# Inspect each Scribe-only commit's contents
git log --stat origin/main..HEAD

# If clean (no data/ or estimates/ files added), rebase
git pull --rebase origin main

# Resolve any conflicts iteratively
# git status will show conflicted files
# Edit them, then:
# git add <file>
# git rebase --continue
# (or git rebase --abort to bail out)
```

If during inspection you find a Scribe-only commit that added `data/foo.dta` or similar by mistake, the safest path is **drop those commits** during an interactive rebase:

```bash
# After the pull --rebase fails or before starting:
git rebase -i origin/main
# Editor opens with a list of commits.  Change "pick" to "drop" for any
# commit that added restricted files.  Save and exit.
```

### Branch C — Scribe has commits ahead, but they're throwaway setup commits

If the Scribe-only commits are just `git init` artifacts, accidental `git add .` of generated content, or other things that shouldn't propagate, the cleanest fix is to discard them and adopt origin's state directly.

**WARNING — this is destructive to Scribe's local commit history.** Make sure you understand what you're throwing away before running it.

```bash
# Tag the current state for emergency recovery (5 sec; gives a safety net)
git tag scribe-pre-reset-$(date +%Y%m%d-%H%M%S)

# Hard-reset to origin/main
git fetch origin
git reset --hard origin/main

# Verify
git log --oneline -5     # should show origin's commits only
git status               # working tree should match origin's tracked files
# (untracked files in data/, estimates/, log/, etc. are PRESERVED;
#  git reset --hard only touches tracked files)
```

If you later realize you needed something from the dropped commits:

```bash
git reflog                            # find the pre-reset SHA
git checkout <pre-reset-sha> -- <path>  # rescue a specific file
```

---

## Step 2: Sparse-checkout to exclude `.claude/` (and other Claude-only dirs)

Sparse-checkout is git-native (no extra tools) and lets each machine include only a subset of the tracked files in its working tree. Pulls and pushes still work normally; excluded dirs just don't materialize.

The config is per-machine (lives in `.git/info/sparse-checkout`, not tracked), so doing this on Scribe does not affect the laptop.

### Minimal exclusion (just `.claude/`)

```bash
git sparse-checkout init --no-cone
cat > .git/info/sparse-checkout <<'EOF'
/*
!/.claude/
EOF
git read-tree -m -u HEAD
```

After this, `.claude/` is gone from the Scribe working tree. `git status` won't list it; future pulls won't bring it back.

### Recommended exclusion (Claude-only + LaTeX dirs you don't compile on Scribe)

If you don't render papers, slides, or supplementary docs on Scribe, also exclude those — keeps the Scribe checkout focused on what Stata actually runs.

```bash
git sparse-checkout init --no-cone
cat > .git/info/sparse-checkout <<'EOF'
/*
!/.claude/
!/quality_reports/
!/master_supporting_docs/
!/decisions/
!/paper/
!/talks/
!/slides/
!/supplementary/
!/templates/
!/preambles/
!/replication/
!/explorations/
EOF
git read-tree -m -u HEAD
```

This keeps on Scribe: `do/`, `ado/`, `py/`, `.githooks/`, `data/` (your populated content), `estimates/`, `figures/`, `tables/`, `output/`, `log/`, plus top-level files (`README.md`, `CLAUDE.md`, `LICENSE`, `TODO.md`, `SESSION_REPORT.md`, `MEMORY.md`, `Bibliography_base.bib`, `.gitignore`).

> Note: `CLAUDE.md` stays in the tree even on Scribe. It's a small markdown file; if you want it gone too, add `!/CLAUDE.md` to the list. Same for `MEMORY.md`, `SESSION_REPORT.md`.

### Verifying sparse-checkout

```bash
git sparse-checkout list           # shows the active patterns
ls -la | head -20                  # should NOT show .claude/ (or other excluded dirs)
git status                         # should still be clean
git log --oneline -3 -- .claude/   # history still accessible; just not checked out
```

### Disabling sparse-checkout (if you ever change your mind)

```bash
git sparse-checkout disable        # restores full working tree on next checkout
```

---

## Step 3: Activate the pre-push hook

The hook script ships at `.githooks/pre-push` in the tracked tree. To opt-in on a machine, set the `core.hooksPath` config so git looks in `.githooks/` instead of `.git/hooks/`:

```bash
git config core.hooksPath .githooks
git config --get core.hooksPath          # should print: .githooks

# Smoke test: hook is executable?
ls -la .githooks/pre-push
# Expect: -rwxr-xr-x ... .githooks/pre-push
# If not executable: chmod +x .githooks/pre-push (should already be x from clone,
# but on Scribe filesystems that strip exec bit, you'll need to re-chmod)
```

What the hook does on each `git push`:

- Inspects every commit in the push range
- If any file under `data/` or `estimates/` (other than the four allowlisted `.gitkeep` stubs) appears in the commit, aborts the push with a clear error
- If everything is clean, exits silently and the push proceeds

Emergency override (audited via shell history):

```bash
git push --no-verify
```

---

## Going-forward sync protocol on Scribe

Once Steps 1-3 are complete, the daily/weekly rhythm is:

```bash
# To pull updates from laptop
git fetch origin
git pull --rebase origin main      # rebase keeps history linear; merge also fine if preferred

# To push local Scribe work (e.g., new check_*.do files written on Scribe)
# Pre-push hook will catch any accidental data/ or estimates/ stages
git push origin main

# To set default pull behavior (one-time, recommended)
git config pull.rebase true        # makes plain `git pull` always rebase
```

If you frequently work on both laptop and Scribe, set:

```bash
git config pull.rebase true        # default to rebase, avoids divergence
git config push.default current    # only push the current branch
```

---

## Common errors + fixes

| Error | Likely cause | Fix |
|---|---|---|
| `fatal: Need to specify how to reconcile divergent branches` | Git ≥2.27 default; both branches moved | Step 1 above (run the diagnostics; pick A/B/C) |
| `error: Your local changes to the following files would be overwritten by merge` | Modified tracked files in working tree | `git stash push -u`, pull, `git stash pop` |
| `error: The following untracked working tree files would be overwritten by merge: ...` | Untracked file at a path the pull would create | `mv <file> <file>.scribe-backup`, pull, decide what to do with the backup |
| `fatal: refusing to merge unrelated histories` | Scribe was `git init`'d separately, no common ancestor with origin | Different recovery — re-clone from scratch and move data/estimates contents into the fresh clone (NOT addressed above; ask if this is what you're seeing) |
| `ERROR: refusing to push — restricted data files in the commit range` | Pre-push hook caught a `data/` or `estimates/` file in a commit | Follow the hook's printed remediation (git rm --cached, git commit --amend) |
| `.claude/` keeps reappearing after pull | Sparse-checkout not active | Re-run Step 2; check `git sparse-checkout list` |

---

## Audit checklist (one-time after completing setup)

- [ ] `git remote -v` shows the correct origin URL
- [ ] `git log --oneline HEAD..origin/main` is empty (Scribe is in sync with origin)
- [ ] `git sparse-checkout list` shows the configured exclusions
- [ ] `ls -la` does not show `.claude/` (or any other dir you excluded)
- [ ] `git config --get core.hooksPath` prints `.githooks`
- [ ] `.githooks/pre-push` is executable (`-rwxr-xr-x`)
- [ ] `git status` is clean (no unexpected modifications)
- [ ] `git ls-files data/ estimates/ | grep -v '\.gitkeep$'` is empty (no restricted files tracked)

Once all eight boxes are checked, Scribe is set up safely for the M4 attempt #5 launch.

---

## Reference: what's tracked vs ignored vs sparse-excluded

| Path | Tracked? | Gitignored content? | Sparse-excluded on Scribe? |
|---|---|---|---|
| `do/`, `ado/`, `py/` | Yes (source) | No | No (need at runtime) |
| `data/` | Stub `.gitkeep` only | Yes (populated content) | No (populated on Scribe) |
| `estimates/` | Stub `.gitkeep` only | Yes (populated content) | No (populated on Scribe) |
| `figures/`, `tables/`, `output/` | Stubs + paper-shipping content | No | No (populated on Scribe) |
| `log/` | Yes (audit trail) | No | No (Scribe writes to it) |
| `.githooks/` | Yes (hook script) | No | No (needed for `core.hooksPath`) |
| `.claude/` | Yes (Claude infra) | Settings.local.json + state | **Yes** (Claude doesn't run here) |
| `quality_reports/`, `master_supporting_docs/`, `decisions/` | Yes (docs) | No | Recommended Yes (not used at runtime) |
| `paper/`, `talks/`, `slides/`, `supplementary/`, `templates/`, `preambles/`, `replication/`, `explorations/` | Yes (LaTeX) | LaTeX build artifacts | Recommended Yes (if not compiling on Scribe) |
