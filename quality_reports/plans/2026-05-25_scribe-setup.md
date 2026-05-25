# Scribe-side Setup: Sync, Sparse-Checkout, Pre-Push Guard

**Date:** 2026-05-25 (rewritten after Christina removed Scribe-side `.git/`)
**Status:** Active reference (execute on Scribe; update if anything changes)
**Audience:** Christina, working on the Scribe server side of `va_consolidated`
**Related:** commits `184ff0d` (main.do clean_va.do hotfix), `e31fe15` (gitignore + .githooks/pre-push); `.claude/rules/air-gapped-workflow.md`

---

## Current Scribe state (2026-05-25)

- `.git/` removed by user
- Working tree intact: `data/`, `estimates/`, `figures/`, `tables/`, `output/`, `log/`, `do/`, `ado/`, `py/`, `paper/`, etc. all still on disk
- No git tracking → no divergent-branch error to resolve, no history to scrub, no data files baked into old commits

This is the cleanest possible starting point. The setup becomes a linear 5-step procedure: clone fresh `.git/`, swap it in, sync tracked files, activate hook, verify.

---

## The setup, in 5 steps

Run on Scribe in this order. Read each block, run it, paste any unexpected output back here before proceeding.

### Step 1: Clone fresh `.git/` with sparse-checkout pre-configured

Clone to a temp location **without** checking out files (`--no-checkout`), so sparse-checkout can be set up before any files materialize. This avoids ever writing `.claude/` (or other excluded dirs) to disk on Scribe.

```bash
cd /tmp
git clone --no-checkout https://github.com/chesun/va_consolidated.git fresh
cd fresh

# Configure sparse-checkout
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
```

> If you'd rather only exclude `.claude/` and keep everything else (e.g., to read the plan doc on Scribe), replace the `cat > ...` block with:
> ```bash
> cat > .git/info/sparse-checkout <<'EOF'
> /*
> !/.claude/
> EOF
> ```

### Step 2: Move `.git/` into Scribe's `consolidated/` dir

```bash
mv .git /home/research/ca_ed_lab/projects/common_core_va/consolidated/.git
cd /home/research/ca_ed_lab/projects/common_core_va/consolidated
rm -rf /tmp/fresh                       # cleanup temp clone
```

### Step 3: Sync tracked files to origin (respects sparse-checkout)

```bash
git reset --hard HEAD
```

This:

- Populates the index from HEAD (necessary because `git clone --no-checkout` leaves it in a state where pathspec-based commands like `git checkout -- .` can fail with `pathspec '.' did not match any file(s) known to git`)
- Writes tracked files to the working tree at HEAD's version (overwrites Scribe's old `do/main.do` with origin's new version)
- Skips paths excluded by sparse-checkout (`.claude/`, etc. never materialize)
- **Leaves untracked + gitignored files alone** — `data/`, `estimates/`, `log/` populated content is preserved on disk

`--hard` is the right tool here because we WANT to overwrite Scribe's old tracked-file content with origin's. Untracked files (your data) are untouched. There's no in-progress work to preserve (any local edits before the `.git/` removal are gone with the old `.git/`).

> If you're more comfortable with a gentler command first, try `git checkout -- .` and only fall back to `git reset --hard HEAD` if you see the "pathspec '.' did not match" error. The reset is the reliable path.

### Step 4: Activate the pre-push hook

```bash
git config core.hooksPath .githooks
git config --get core.hooksPath         # should print: .githooks
ls -la .githooks/pre-push               # confirm executable (rwxr-xr-x)
```

If the hook isn't executable (some shared-storage filesystems strip the exec bit):

```bash
chmod +x .githooks/pre-push
```

### Step 5: Verify

```bash
# === Git state ===
git log --oneline -5
# Expect: c72c08b (or newer) ... 184ff0d (main.do hotfix) ... e31fe15 (gitignore+hook)

git status
# Expect: "nothing to commit, working tree clean"
# (data/, estimates/ contents should NOT appear — covered by .gitignore)

# === Sparse-checkout active ===
git sparse-checkout list
# Expect: shows the patterns you configured in Step 1

ls -la
# Expect: NO .claude/ directory, NO quality_reports/, etc.

# === Data preserved ===
ls -la data/cleaned/acs/ | head -5
# Expect: the restricted .dta files still on disk
du -sh data/ estimates/
# Expect: sizes match what was there before (probably several GB total)

# === Gitignore working: only .gitkeep stubs tracked ===
git ls-files data/ estimates/
# Expect: exactly 4 paths:
#   data/.gitkeep         (will only show if it exists; check)
#   data/cleaned/.gitkeep
#   data/raw/.gitkeep
#   estimates/.gitkeep

# === Pre-push hook armed ===
git config --get core.hooksPath
# Expect: .githooks
```

If all five blocks produce the expected output, Scribe is fully synced and ready for M4 attempt #5.

---

## Re-launching M4 attempt #5

After Steps 1-5 pass:

```bash
cd /home/research/ca_ed_lab/projects/common_core_va/consolidated
nohup stata-mp -b do do/main.do &
```

`do/main.do` now has the clean_va.do Phase 1 → Phase 5 reorder (commit `184ff0d`), so the `r(601)` crash from attempt #4 should not recur. The pipeline should progress through:

- Phase 1 — data prep (re-uses cached intermediates from prior runs)
- Phase 2 — sample construction (`do_touse_va` + `do_create_samples` flip to 1 under `m4_acceptance_run`)
- **Phase 3 — VA estimation (the multi-hour bottleneck)**
- Phase 4 — VA tables/figures (stub)
- Phase 5 — survey VA, now starting with `clean_va.do` (the relocated invocation)
- Phase 6 — paper outputs
- Phase 7 — data checks

Monitor the master log: `tail -f log/main_$(date +%d-%b-%Y)_*.smcl`

When the run completes (or fails), the next M4 step is the smoke-tier golden-master comparison per `quality_reports/plans/2026-05-17_m4-golden-master-protocol.md`.

---

## Going-forward sync protocol

Once setup is complete, the day-to-day rhythm:

```bash
# To pull updates from laptop
git pull --rebase origin main           # rebase keeps history linear

# To push local Scribe work
# (e.g., new check_*.do files written on Scribe; the pre-push hook will
#  catch any accidental data/ or estimates/ stages)
git push origin main
```

One-time config recommendations:

```bash
git config pull.rebase true             # default to rebase on every pull
git config push.default current         # only push the current branch
```

---

## Common errors + fixes

| Error | Cause | Fix |
|---|---|---|
| `fatal: Need to specify how to reconcile divergent branches` | Git ≥2.27 default; happens if you commit on Scribe and laptop also commits before you pull | `git config pull.rebase true` (one-time) then `git pull` |
| `error: Your local changes to the following files would be overwritten by merge` | Modified tracked files in working tree | `git stash push -u`, pull, `git stash pop` |
| `error: The following untracked working tree files would be overwritten by merge: ...` | Untracked file at a path the pull would create | `mv <file> <file>.scribe-backup`, pull, decide what to do with the backup |
| `ERROR: refusing to push — restricted data files in the commit range` | Pre-push hook caught a `data/` or `estimates/` file in a commit | Follow the hook's printed remediation (`git rm --cached`, `git commit --amend`) |
| `.claude/` reappears after pull | Sparse-checkout not active or got disabled | Verify with `git sparse-checkout list`; if empty, re-run Step 1 |
| `.githooks/pre-push: Permission denied` on push | Hook script lost exec bit | `chmod +x .githooks/pre-push` |

---

## Audit checklist (run once after Step 5 passes)

- [ ] `git remote -v` shows correct origin URL
- [ ] `git log --oneline HEAD..origin/main` is empty (Scribe in sync with origin)
- [ ] `git sparse-checkout list` shows the configured exclusions
- [ ] `ls -la` does NOT show `.claude/` (or any other excluded dir)
- [ ] `git config --get core.hooksPath` prints `.githooks`
- [ ] `.githooks/pre-push` is executable (`-rwxr-xr-x`)
- [ ] `git status` is clean (no unexpected modifications)
- [ ] `git ls-files data/ estimates/` shows only `.gitkeep` stubs
- [ ] `ls -la data/cleaned/acs/ | head -5` shows restricted `.dta` files preserved on disk
- [ ] `du -sh data/ estimates/` sizes match pre-setup expectations

Once all ten boxes are checked, Scribe is set up safely for the M4 attempt #5 launch.

---

## Reference: what's tracked vs ignored vs sparse-excluded

| Path | Tracked on origin? | Gitignored content? | Sparse-excluded on Scribe? |
|---|---|---|---|
| `do/`, `ado/`, `py/` | Yes (source) | No | No (need at runtime) |
| `data/` | `.gitkeep` stubs only | Yes (populated content) | No (populated on Scribe) |
| `estimates/` | `.gitkeep` stub only | Yes (populated content) | No (populated on Scribe) |
| `figures/`, `tables/`, `output/` | Stubs + paper-shipping content | No | No (populated on Scribe) |
| `log/` | Yes (audit trail) | No | No (Scribe writes to it) |
| `.githooks/` | Yes (hook script) | No | No (needed for `core.hooksPath`) |
| `.claude/` | Yes (Claude infra) | `settings.local.json` + `state/*` | **Yes** (Claude doesn't run here) |
| `quality_reports/`, `master_supporting_docs/`, `decisions/` | Yes (docs) | No | **Yes** (not used at runtime) |
| `paper/`, `talks/`, `slides/`, `supplementary/`, `templates/`, `preambles/`, `replication/`, `explorations/` | Yes (LaTeX) | LaTeX build artifacts | **Yes** (not compiling on Scribe) |
| Top-level files (`README.md`, `CLAUDE.md`, `LICENSE`, `TODO.md`, `SESSION_REPORT.md`, `MEMORY.md`, `Bibliography_base.bib`, `.gitignore`, `main.do` if at root) | Yes | No | No (sparse-included by default `/*`) |

---

## Recovery: undoing the setup if anything goes wrong

If Steps 1-5 produce an unrecoverable state, the recovery is symmetric to setup — delete `.git/` again and start over:

```bash
cd /home/research/ca_ed_lab/projects/common_core_va/consolidated
rm -rf .git
# Working tree (including data/) preserved.  Restart at Step 1.
```

If you want to permanently abandon sparse-checkout (e.g., to materialize `.claude/` again):

```bash
git sparse-checkout disable             # restores full working tree on next checkout
```

If you want to permanently abandon the pre-push hook:

```bash
git config --unset core.hooksPath       # git uses default .git/hooks/ again
```
