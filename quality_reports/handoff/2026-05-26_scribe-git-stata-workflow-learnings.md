# Scribe + Stata + Git Workflow: Lab Guide Source Material

**Date:** 2026-05-26
**Status:** Raw learnings document — source material for a future lab-internal guide
**Audience:** Christina (author of the future guide); incidentally also any successor reading this archive
**Scope:** Lessons from setting up a fresh git workflow on Scribe for the `va_consolidated` project, written so the gotchas don't have to be rediscovered

This document is **not** the lab guide itself. It's a collection of concrete learnings — each rooted in a specific failure or near-miss from the 2026-05-25 to 2026-05-26 work block — that should be reorganized into prescriptive guidance when the guide gets written. Each section names the trap, explains the underlying mechanism, and gives the recovery pattern.

The intended pattern for the future guide: take these themes, distill them into "always do X / never do Y / watch out for Z" rules with one-paragraph rationales, and ship as a single ~5-page Markdown for the lab wiki or onboarding packet.

---

## 1. Architecture: when is git-on-Scribe worth it?

### The decision

The lab default (per ADR-0007, 2026-04-25) was: **never put `.git/` on Scribe**. Code moves between laptop and Scribe via FileZilla drag-and-drop. The rationale was security (no GitHub credentials on a restricted server) + simplicity (no learning new tools for a 3-month project).

We reversed this 2026-05-26 (ADR-0022) for the active-development phase. The reasons:

| Friction without git on Scribe | Why it matters during active development |
|---|---|
| No audit trail of which file moved when | Can't reproduce what was on Scribe at any past point |
| GUI-only sync, no scriptable rhythm | Every M4 attempt = manual drag-drop of changed files, then manual drag-back of logs |
| Code-vs-log divergence drifts silently | Hard to confirm Scribe is running the exact code the laptop committed |
| Logs as audit trail require separate transfer | Each attempt's output documentation is operator-dependent |

What changed the security calculus: a **multi-layer data-isolation discipline** (Section 2 below) brought the residual leak risk low enough that the convenience win became worth it.

### When to use which

**FileZilla-only (no git on Scribe) — best for:**

- Stable, low-velocity projects where the laptop pushes to Scribe rarely (e.g., monthly data refresh).
- Successor-inheritance scenarios where the new operator may not know git.
- The frozen-archive phase post-publication (deliverable lives at GitHub tag; Scribe is read-only).

**Git on Scribe — best for:**

- Active development with frequent code/test cycles.
- Multi-attempt debugging (acceptance runs, golden-master verification, large refactors).
- Audit trail matters (logs committed as evidence of what ran when).
- Operator is comfortable with git CLI and credential management.

### Generalizable pattern: provisional-with-revisit

ADR-0022 explicitly framed the decision as **provisional, with revisit criteria documented**. This pattern is reusable for any architectural change that crosses a security or workflow line:

1. State the decision + the explicit reversal criteria upfront ("revisit if X, Y, or Z happens")
2. Tag the revisit moment in advance (e.g., "before the next freeze tag")
3. Capture data during the experimental period so the revisit has evidence
4. When revisiting, write a new ADR — either confirming or reverting — citing the captured evidence

This is **better than committing permanently** to a risky change AND **better than refusing to try** the change. The provisional decision creates an experiment with a defined end.

---

## 2. The three-layer data-isolation pattern

Restricted-data projects need **multiple independent layers** that each have to fail before data can leak. For this project:

### Layer 1 — `.gitignore`

Path-anchored patterns prevent `git add` from staging anything under `data/` or `estimates/` (except `.gitkeep` stubs).

```
/data/*
!/data/.gitkeep
!/data/raw/
!/data/cleaned/
/data/raw/*
!/data/raw/.gitkeep
/data/cleaned/*
!/data/cleaned/.gitkeep
/estimates/*
!/estimates/.gitkeep
```

Why anchored (`/data/*`, not `data/*`): so nested `data/` directories elsewhere in the tree don't accidentally trigger the pattern. The leading `/` anchors to repo root.

Why `.gitkeep` allowlist: preserves directory structure on clone so scripts don't have to `mkdir -p` everywhere.

### Layer 2 — Pre-push hook (`.githooks/pre-push`)

A git-native Bash script that runs at every `git push`, scans the commit range for any non-`.gitkeep` file under `data/` or `estimates/`, and aborts with a clear error if found.

```bash
forbidden_pattern='^(data|estimates)/'
allowed_pattern='^(data|data/raw|data/cleaned|estimates)/\.gitkeep$'

# For each ref being pushed:
files=$(git diff --name-only "${remote_sha}..${local_sha}")
bad_files=$(printf '%s\n' "$files" | grep -E "$forbidden_pattern" | grep -vE "$allowed_pattern")
[ -n "$bad_files" ] && exit 1
```

This catches the `git add -f data/...` bypass — the user explicitly overrode `.gitignore`, but the hook still blocks the push.

### Layer 3 — Sparse-checkout (Scribe-only)

The Scribe `consolidated/` working tree never even includes laptop-only directories (`.claude/`, `quality_reports/`, etc.). So even an attacker with shell on Scribe can't trivially `git add` Claude infrastructure files because they aren't there.

Sparse-checkout is more of a **discipline layer** than a security layer — it prevents accidental commits of files that don't belong on Scribe, which preserves the audit trail's cleanliness.

### Why three layers?

| If only `.gitignore` | `git add -f` bypasses it; secrets leak |
| If only pre-push hook | A `git add` of `data/foo.dta` makes the file tracked; a future operator might not know about the hook and accept the file as legitimate; subtle leak in working-tree state |
| If only sparse-checkout | Doesn't apply to `data/` (we want data on Scribe disk); doesn't help laptop-side |

Three layers means **two independent intentional overrides** would be required to leak data: `git add -f` (override gitignore) AND `git push --no-verify` (override hook). That's the threshold for accidental leakage to be vanishingly rare.

The principle generalizes: **for any constraint that matters, design two independent guards.** Either guard alone catches most accidents; both bypasses are auditable in shell history.

---

## 3. Setup procedure pitfalls discovered

### Pitfall 3.1 — `git clone --no-checkout` + sparse-checkout interaction

**What we tried:**

```bash
git clone --no-checkout https://github.com/chesun/va_consolidated.git fresh
cd fresh
git sparse-checkout init --no-cone
cat > .git/info/sparse-checkout <<'EOF'
/*
!/.claude/
EOF
mv .git /scribe/path/.git
cd /scribe/path
git checkout -- .                       # FAILED here
```

**Error:** `pathspec '.' did not match any file(s) known to git`

**Root cause:** `git clone --no-checkout` leaves the index in a state where pathspec-based commands can't resolve `.` against any tracked path. The exact behavior depends on git version + whether sparse-checkout was activated before/after the clone. We didn't fully diagnose the internals, but the fix is reliable.

**Fix:** Use `git reset --hard HEAD` instead. It populates the index from HEAD AND writes the working tree atomically, regardless of the initial index state.

**Generalizable rule:** For setup recipes that combine `--no-checkout` + sparse-checkout, **don't use pathspec-based commands for the post-swap sync**. Use `git reset --hard HEAD` (or `git checkout HEAD --` with no pathspec) instead.

### Pitfall 3.2 — Sparse-checkout pattern semantics in non-cone mode

**The trap:** sparse-checkout patterns in `--no-cone` mode use `.gitignore`-style syntax, which has subtle differences from intuition:

- `/foo` matches `foo` at root only — does NOT recurse to contents (in gitignore, ignoring a directory recursively ignores its contents, but sparse-checkout doesn't automatically extend that)
- `/foo/` (trailing slash) means "directory only"
- `!/foo/` excludes that path from the sparse set
- `/*` at top of file is the "include everything" base; subsequent `!`s subtract

**Working pattern we settled on:**

```
/*
!/.claude/
!/quality_reports/
!/CLAUDE.md
!/MEMORY.md
!/README.md
```

This says: include everything at root (`/*`), then subtract specific dirs and files.

**Verify with:** `git sparse-checkout list` shows the current pattern. After changes, `git sparse-checkout reapply` re-walks the index and updates the working tree.

**Generalizable rule:** Configure sparse-checkout patterns BEFORE the first checkout if possible. Use `--no-cone` for fine-grained exclusion (cone mode requires whole-directory thinking). Test the pattern by listing `ls -la` after `reapply` — what shouldn't be there shouldn't appear.

### Pitfall 3.3 — IDE buffer staleness during external file edits

**The trap:** when an external process (a script, an AI assistant, another machine) modifies a file that's currently open in VS Code, VS Code doesn't always refresh the visible buffer. The user sees stale content until they explicitly close + reopen.

**How we got tripped up:** Christina had `2026-05-25_scribe-setup.md` open while I rewrote it. VS Code didn't refresh. She kept seeing the old "Option A/B/C" content that had been deleted on disk + on origin.

**Diagnostic:** `git diff origin/main -- <path>` from the terminal. If it shows differences, the IDE buffer differs from origin (or you have unsaved edits). If it's empty, the IDE is the problem — close + reopen.

**Generalizable rule:** When an instruction says "the file says X" but you see Y in the IDE, **don't trust the IDE buffer.** Trust the terminal `cat <file>` or `git diff`. This applies any time external automation touches your tree.

---

## 4. Credential management on shared servers

### Pitfall 4.1 — The PAT username/password trap

**The trap:** When you `git push` and HTTPS auth prompts appear:

```
Username for 'https://github.com':
Password for 'https://chesun@github.com':
```

Both prompts look like text input fields. After freshly copying a PAT from GitHub's "Generate token" page, muscle memory says "paste the long thing", and the PAT lands in the **username** field. Result:

- Git transports the PAT as the username over HTTPS
- GitHub returns "Invalid username or token. Password authentication is not supported" — the PAT was sent in the wrong header
- The PAT is now logged in git's transport logs + shell history + potentially the conversation if pasted there too

**Recovery (mandatory):** revoke the PAT on GitHub immediately. The string is compromised even if the only "exposure" was to the local machine — assume it leaked.

**Prevention:**

- **Username:** your GitHub login (e.g., `chesun`). Short, no `github_pat_` prefix.
- **Password:** the PAT (the long `github_pat_...` string).
- Read the prompt carefully before pasting. The prompt literally says "Username" or "Password" — match the field.

### Pitfall 4.2 — `~/.git-credentials` is plaintext

`git config --global credential.helper store` caches credentials at `~/.git-credentials` in plaintext. On a shared lab server like Scribe, this means:

- Anyone with your account-level access can read the file
- Anyone with `sudo` or root can read it (shouldn't be a concern in well-managed lab IT)
- If the home directory is backed up off-server, the PAT goes with the backup

**Mitigations:**

- Use a **fine-grained PAT scoped to a single repository** (not classic PATs that grant access to all your repos)
- Set a **short expiration** aligned to project timeline (90 days is fine; 1 year is sloppy)
- Use **minimum permissions** (e.g., `Contents: Read and write` only — not full repo admin)
- Rotate the PAT if you suspect compromise (cheap; revoke + generate + push once)

### Pitfall 4.3 — Auto-configured git identity on shared servers

When git is fresh on a server and you commit, git auto-derives `user.name` and `user.email` from the system account (e.g., `user.name = chesun1`, `user.email = chesun1@scribe.local`). Commits authored with the server identity break the audit trail because:

- GitHub doesn't recognize `chesun1@scribe.local` and won't link commits to your profile
- The same person ends up with multiple author identities across machines
- The frozen-archive at offboarding has muddied authorship

**Fix:** set `user.name` and `user.email` globally to match your canonical GitHub identity:

```bash
git config --global user.name "Christina Che Sun"
git config --global user.email "che.sun.1996@gmail.com"
```

If you committed with the wrong identity already:

```bash
git commit --amend --reset-author --no-edit
```

Verify:

```bash
git log -1 --format='%an <%ae>'
```

**Generalizable rule:** On every new machine where you commit, set git identity globally BEFORE the first commit. Confirm with `git config --get user.email`.

---

## 5. Pre-push hook architecture: file vs config separation

### The mechanism

Git looks for hooks at `$GIT_DIR/hooks/` by default (i.e., `.git/hooks/`). That directory is **not tracked by git** — it's part of the local `.git/` metadata. So a hook script placed there doesn't get committed and won't ship to a fresh clone.

**To track hooks in the repo:**

1. Place the hook script anywhere in the working tree (convention: `.githooks/`)
2. Each machine that wants the hook active sets `git config core.hooksPath .githooks`
3. Git then looks for hooks in `.githooks/` instead of `.git/hooks/`
4. The hook script itself ships via normal git operations; the config is per-machine opt-in

### Why opt-in per machine?

Setting `core.hooksPath` is a security-relevant action — running unknown shell scripts on every push. Forcing it on every clone would surprise users and could be a vector for malicious upstreams (push something with a malicious `.githooks/pre-push` and trip the hook on every contributor's first push).

Opt-in via explicit config means: "I've read this hook, I trust it, run it on my pushes."

### Hook activation checklist

```bash
git config core.hooksPath .githooks         # opt-in
git config --get core.hooksPath             # verify "  .githooks"
ls -la .githooks/pre-push                   # verify exists + executable
chmod +x .githooks/pre-push                 # if exec bit was stripped
```

### Hook firing order in `git push`

Important for designing tests:

1. Git resolves what refs to push (local commits not on remote)
2. Git **contacts the remote and authenticates** (this is where bad PAT or network errors fail)
3. Git runs the `pre-push` hook (gets remote name + URL as argv, refs as stdin)
4. If hook exits 0, git uploads objects + updates refs
5. If hook exits nonzero, push aborts

**Implication:** if you're testing the hook but get a credential prompt instead, the test isn't measuring the hook — it's measuring auth. Fix auth first, retry.

### The deliberate-trip test

You cannot trust a safety system you haven't tested. The trip test:

```bash
echo "fake data" > data/test_leak.dta
git add -f data/test_leak.dta
git commit -m "test: should be blocked"
git push origin main      # expect ERROR: refusing to push
git reset --hard HEAD~1   # cleanup
rm -f data/test_leak.dta
```

If the hook doesn't fire on this, **something is broken** — re-check `core.hooksPath`, exec bit, script syntax.

**Generalizable rule:** Every safety hook needs a deliberate-trip test run at setup time. Document the expected output so the next operator can confirm it. Untested safety = no safety.

---

## 6. Pull/push divergence handling

### The "rejected (fetch first)" error

```
! [rejected]        main -> main (fetch first)
error: failed to push some refs to '...'
hint: Updates were rejected because the remote contains work that you do
hint: not have locally.
```

**Cause:** the other machine pushed commits to origin while you were working locally. Your local HEAD is behind origin's HEAD, AND your local has commits origin doesn't have (otherwise you'd just fast-forward push).

**Fix:**

```bash
git pull --rebase origin main      # fetch origin, rebase your local commits on top
git push origin main               # retry
```

`--rebase` is preferable to default `--merge` for individual workflows: keeps history linear, no merge commits cluttering the log.

### The "Need to specify how to reconcile divergent branches" error (git ≥2.27)

```
fatal: Need to specify how to reconcile divergent branches.
```

**Cause:** Recent git versions refuse to auto-decide between merge / rebase / fast-forward. You have to set a default once.

**Fix:**

```bash
git config --global pull.rebase true       # default to rebase
git config --global push.default current   # only push current branch
```

These two configs make routine pull/push behavior predictable.

### Asymmetry: pulls vs pushes

| Operation | Auth needed? | Hook involved? | Comment |
|---|---|---|---|
| `git pull` from public repo | No | No | Anonymous access is fine |
| `git pull` from private repo | Yes | No | PAT or SSH key needed |
| `git push` (any repo) | Yes | Yes (pre-push) | Auth + hook gate |

So you can **pull** on Scribe even before setting up the PAT — useful for the initial setup when you haven't done auth yet. Only the **first push** triggers the auth setup flow.

---

## 7. File preservation across git operations

The operative question for any git command: **does this touch untracked files?**

| Command | Tracked files | Untracked files |
|---|---|---|
| `git checkout <commit>` | Replaced with that commit's version | Preserved |
| `git checkout -- <pathspec>` | Pathspec files replaced from index | Preserved |
| `git reset --hard <commit>` | Replaced with that commit's version | Preserved |
| `git clean -fd` | (no effect) | **DELETED** |
| `git stash push -u` | Stashed | Stashed (with `-u`) |
| `git rm <path>` | Removed from index + working tree | (n/a) |
| `git rm --cached <path>` | Removed from index only | (now untracked, on disk) |

**The rule that saved us multiple times:** `git reset --hard HEAD` overwrites tracked files but leaves untracked files alone. So Scribe's populated `data/`, `estimates/`, `log/` (all untracked + gitignored) survive a hard reset that's pulling the laptop's pristine HEAD onto Scribe. No backup-restore dance needed.

**The trap:** `git clean -fd` deletes untracked files. Never run this without `--dry-run` first.

### Stata vs git: file-handle semantics

If Stata is **actively writing** to `log/main.smcl` and you run `git checkout HEAD -- log/main.smcl`:

- Git writes a new file at that path via `tmpfile + rename` (atomic at the filesystem layer)
- Stata's open file handle still points to the OLD inode (now orphaned — no directory entry)
- Stata keeps writing to the orphaned inode
- The new file (origin's version) sits at the path; Stata's writes go to a file no one can find
- When Stata closes, its writes are silently lost (orphaned inode reclaimed by the filesystem)

**Generalizable rule:** **never run git operations that touch the file tree while a Stata batch run is in progress.** Wait for the run to complete OR kill it (`kill <pid>`) before any `checkout`, `reset --hard`, `clean`, or branch switch.

---

## 8. Workflow-sync regression: template-overwrites-project

The `claude-code-my-workflow` template syncs updates to consumer repos via a propagate script. The script ships every changed file from the template — including `README.md`.

On 2026-05-?? (commit `287b8df`), a workflow-sync silently overwrote the project's README.md (~311 lines, written for offboarding-era operator per ADR-0018) with the generic 220-line "Pedro Sant'Anna template" README. **Three months of project-specific documentation evolution reverted in one chore commit.**

### Why this is a regression class, not a one-off

Any time a template-style tool propagates changes downstream, there's a tension:

- **Template wants to update** files it shipped initially (CLAUDE.md template, README.md template, etc.)
- **Consumer customizes** those same files post-fork

Without an explicit "consumer-customized files" allowlist, the template's "always sync this" wins by default. Silent regression.

### Generalizable mitigations

1. **Consumer-side gitignore-like list:** `.workflow-sync-exclude` listing paths the local sync mechanism should never touch.
2. **Template-side discipline:** template ships an "INITIAL" version of customizable files (e.g., `README.template.md`); consumer copies + edits + the template never touches the consumer's copy.
3. **Diff-review before propagation:** every workflow-sync commit reviewed by a human before merge, with a diff that flags changes to customized files. Manual process; doesn't scale.

We've punted this to a Backlog TODO entry for upstream-side fix coordination. Until fixed, the workaround on consumer side is **manual inspection of every workflow-sync commit's file list** for README.md / CLAUDE.md / project-specific files.

### How we discovered it

The current README on Scribe (after the v5 setup procedure) was visibly the workflow-template README, not the project README. Christina noticed. `git log -- README.md` showed the regression commit.

**Generalizable rule:** After any "chore: workflow-sync" or similar automated-propagation commit, **verify nothing project-specific got reverted**. `git diff <commit>~1..<commit> -- <important-files>` is a 30-second sanity check.

---

## 9. Documentation patterns that paid off

### 9.1 ADR supersession with explicit revisit criteria

ADR-0022 (the git-on-Scribe decision) is provisional. It explicitly lists:

- The criteria for revisiting (Phase 1c §5.4 acceptance run timing)
- The evidence to capture during the experimental period (audit-trail usefulness, hook firing record, friction)
- The two possible outcomes (kept = supersede ADR-0007 permanently; reverted = new ADR returns to FileZilla model)

This means **the decision has a defined end**. Without that, "provisional" decisions calcify into permanent ones because no one schedules the revisit.

### 9.2 Plan docs as living runbooks

`quality_reports/plans/2026-05-25_scribe-setup.md` was rewritten **five times** in 36 hours as the situation clarified. The pattern:

- v1: initial best-effort plan based on stated facts
- v2-v4: iterate as user feedback revealed misunderstandings
- v5: **comprehensive rewrite** dropping obsolete content once the situation stabilized

The lesson: **don't be precious about plan docs.** Rewrite them in place when the situation changes substantially. Git history preserves the prior versions if anyone wants to look back.

### 9.3 Memory notes for cross-conversation persistence

The PAT username/password trap incident generated a memory note (`feedback_credentials_pat_username_trap.md`). This is auto-loaded in future conversations so the warning gets surfaced proactively next time credentials come up — not just remediated reactively after another mistake.

**Generalizable pattern:** when a near-miss happens, write a one-paragraph note that's terse, named, and findable. Future-you (or future operators) get the benefit without re-discovering.

---

## 10. The setup procedure that finally worked (canonical)

For reference, here's the procedure that worked end-to-end (after the iterations). Adapt for any restricted-server git workflow.

```bash
# === PRECONDITIONS ===
# - User has GitHub account + ability to generate PAT
# - User has SSH access to Scribe + an existing working-tree directory there
# - Repo is public (or PAT can pull) on GitHub

# === STAGE 1: clean slate ===
cd /home/research/ca_ed_lab/projects/common_core_va/consolidated
rm -rf .git    # if any existing git state needs to go

# === STAGE 2: clone fresh .git/ with sparse-checkout preconfigured ===
cd /tmp
git clone --no-checkout https://github.com/chesun/va_consolidated.git fresh
cd fresh
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
!/CLAUDE.md
!/MEMORY.md
!/SESSION_REPORT.md
!/README.md
!/TODO.md
EOF

# === STAGE 3: swap .git/ ===
mv .git /home/research/ca_ed_lab/projects/common_core_va/consolidated/.git
cd /home/research/ca_ed_lab/projects/common_core_va/consolidated
rm -rf /tmp/fresh

# === STAGE 4: sync working tree ===
git reset --hard HEAD

# === STAGE 5: arm pre-push hook ===
git config core.hooksPath .githooks
chmod +x .githooks/pre-push   # in case exec bit stripped

# === STAGE 6: set canonical git identity ===
git config --global user.name "Christina Che Sun"
git config --global user.email "che.sun.1996@gmail.com"

# === STAGE 7: configure pull/push defaults ===
git config --global pull.rebase true
git config --global push.default current

# === STAGE 8: first-push auth + hook smoke test ===
# (Generate PAT on GitHub first — fine-grained, single repo, Contents R/W,
#  90-day expiration. Username for prompt = your GitHub login. Password
#  for prompt = the PAT.  NOT the other way around.)
git config --global credential.helper store
echo "fake data" > data/test_leak.dta
git add -f data/test_leak.dta
git commit -m "test: should be blocked by pre-push hook"
git push origin main
# Expect: ERROR: refusing to push — restricted data files in the commit range

# === STAGE 9: cleanup ===
git reset --hard HEAD~1
rm -f data/test_leak.dta
git log --oneline -3   # confirm HEAD matches origin
```

That's the end-to-end recipe. Every command above is one that was sanity-checked and worked. Commands that **didn't** work (omitted): `git checkout -- .` after the `.git` swap (use `reset --hard HEAD` instead).

---

## Appendix: complete error-message → fix lookup

| Error | Cause | Fix |
|---|---|---|
| `pathspec '.' did not match any file(s) known to git` | Index half-populated after `--no-checkout` + sparse-checkout setup | `git reset --hard HEAD` |
| `fatal: Need to specify how to reconcile divergent branches` | Git ≥2.27 default; both branches moved | `git config --global pull.rebase true` then `git pull` |
| `! [rejected] main -> main (fetch first)` | Local is behind origin AND has local commits | `git pull --rebase origin main` then `git push` |
| `Invalid username or token. Password authentication is not supported` | Typed actual GitHub password (or PAT into wrong field) | Revoke PAT (if leaked); regenerate; paste into password prompt only |
| `Permission denied (publickey)` on SSH | SSH key not added to GitHub | Add public key to GitHub Settings → SSH and GPG keys |
| `error: Your local changes to the following files would be overwritten by merge` | Working-tree modifications to tracked files | `git stash push -u`, pull, `git stash pop` |
| `.githooks/pre-push: Permission denied` on push | Hook exec bit stripped by filesystem | `chmod +x .githooks/pre-push` |
| Hook didn't fire despite bad data in commit | `core.hooksPath` not set, OR auth failed first | Check `git config --get core.hooksPath`; complete auth setup first |
| `ERROR: refusing to push — restricted data files...` | Hook caught data file in commit range — working as designed | Cleanup: `git reset --hard HEAD~1 && rm <file>` |
| IDE shows different content than `cat <file>` | IDE buffer stale after external edit | Close + reopen file in IDE |

---

## Closing thought for the future guide

The biggest meta-lesson from this 36-hour iteration: **set up the safety net BEFORE you need it**. The pre-push hook, gitignore patterns, and sparse-checkout config all existed before the deliberate-trip test confirmed them. Without those, the natural muscle memory of `git add . && git commit -m '...'` would have leaked restricted data into a public repo on the first careless push.

The corollary: **test the safety net deliberately.** A guard you haven't tripped is a guard you don't actually have.
