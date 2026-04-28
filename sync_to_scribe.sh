#!/usr/bin/env bash
#
# sync_to_scribe.sh — push consolidated repo from local Mac to Scribe
# =============================================================================
#
# PURPOSE
#     One-command sync of the local consolidated repo to Scribe's non-git
#     working copy at $REMOTE_DIR.  Idempotent.  Per ADR-0007:
#       - GitHub holds code/docs/tables/figures only (no .dta / data)
#       - Scribe `consolidated/` is non-git working copy
#       - rsync is the only sync direction local → Scribe
#       - .git/ is NEVER copied to Scribe (no GitHub credentials on the
#         restricted server, no risk of accidental `git push` of staged data)
#
# USAGE
#     bash sync_to_scribe.sh                    # standard run
#     bash sync_to_scribe.sh --dry-run          # show what would change
#     bash sync_to_scribe.sh --allow-dirty      # skip clean-tree check
#                                                 (use sparingly; emergency
#                                                 work-in-progress sync)
#
# PRE-REQS
#     1. SSH to Scribe via the alias `Scribe`, with key-based auth + a
#        running ControlMaster (single auth per session).  See SSH SETUP
#        section below for the one-time ~/.ssh/config snippet.
#     2. Remote dir $REMOTE_DIR exists (Phase 1a §3.1 step 1).
#     3. The local repo is at $LOCAL_DIR (this script lives at $LOCAL_DIR).
#
# WHAT GETS SYNCED
#     Everything under $LOCAL_DIR except:
#       - .git/                            never on Scribe per ADR-0007
#       - .claude/                         not needed on Scribe (no Claude Code)
#       - data/ estimates/ log/ output/    Scribe-side only (data lives there)
#       - master_supporting_docs/codebooks/ may contain restricted-access metadata
#       - *.dta *.smcl *.log *.ster .DS_Store
#
#     rsync uses --delete: files removed locally are removed on Scribe too.
#     This is safe because the excluded paths above are never touched.
#
# WHAT GETS WRITTEN ON SCRIBE
#     $REMOTE_DIR/                       full code mirror (post-sync)
#     $REMOTE_DIR/VERSION                the synced commit SHA + timestamp
#
#
# SSH SETUP (one-time, on Christina's local Mac)
# -----------------------------------------------------------------------------
# This script invokes `ssh Scribe` as a shorthand for the actual server
# `chesun1@Scribe.ssds.ucdavis.edu`.  The shorthand is provided by an
# `~/.ssh/config` Host alias.  Add the following block to ~/.ssh/config
# (creating the file if absent — `mkdir -p ~/.ssh && chmod 700 ~/.ssh`).
# The ControlMaster lines are the ergonomic win — single auth per shell
# session.
#
#     Host Scribe
#         HostName Scribe.ssds.ucdavis.edu
#         User chesun1
#         IdentityFile ~/.ssh/id_ed25519       # adjust to your key file
#         ControlMaster auto
#         ControlPath ~/.ssh/cm-%r@%h:%p
#         ControlPersist 4h
#         ServerAliveInterval 60
#         ServerAliveCountMax 3
#
# Ensure the IdentityFile is `chmod 600`.  First `ssh Scribe` prompts for
# the key passphrase + 2FA; subsequent commands within ControlPersist's
# window reuse the connection without re-prompting.  Verify the
# multiplexer is live with `ssh -O check Scribe`.
#
# OFFBOARDING NOTE (per ADR-0018): a successor with different credentials
# updates this single Host block — the User / IdentityFile lines — and
# every script in this repo continues to work.  No script-level edits.
# -----------------------------------------------------------------------------
#
# REFERENCES
#     ADR-0002 (runtime: Scribe only)
#     ADR-0007 (code-data separation; non-git working copy on Scribe)
#     ADR-0018 (offboarding: $REMOTE_DIR is the canonical post-handoff)
#     Plan v3 §3.1 (Scribe folder + sync setup)

set -euo pipefail

# -----------------------------------------------------------------------------
# CONFIG
# -----------------------------------------------------------------------------
readonly LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REMOTE_HOST="Scribe"
readonly REMOTE_DIR="/home/research/ca_ed_lab/projects/common_core_va/consolidated"

# -----------------------------------------------------------------------------
# ARG PARSING
# -----------------------------------------------------------------------------
DRY_RUN=0
ALLOW_DIRTY=0
for arg in "$@"; do
    case "$arg" in
        --dry-run)     DRY_RUN=1 ;;
        --allow-dirty) ALLOW_DIRTY=1 ;;
        -h|--help)
            sed -n '/^# USAGE/,/^# PRE-REQS/p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "unknown arg: $arg" >&2 ; exit 2 ;;
    esac
done

# -----------------------------------------------------------------------------
# PRE-FLIGHT CHECKS
# -----------------------------------------------------------------------------
cd "$LOCAL_DIR"

# 1. We're in a git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "ERROR: $LOCAL_DIR is not a git repo" >&2
    exit 1
fi

# 2. Working tree is clean (unless --allow-dirty)
if [[ "$ALLOW_DIRTY" -eq 0 ]]; then
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "ERROR: working tree has unstaged or staged changes." >&2
        echo "       commit / stash first, or pass --allow-dirty (use sparingly)." >&2
        git status --short >&2
        exit 1
    fi
    if [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
        echo "ERROR: working tree has untracked files." >&2
        echo "       commit / stash first, or pass --allow-dirty." >&2
        git status --short >&2
        exit 1
    fi
fi

# 3. SSH ControlMaster reachable (or fall through to a fresh auth)
if ! ssh -O check "$REMOTE_HOST" >/dev/null 2>&1; then
    echo "note: no live SSH ControlMaster — first connection may prompt for auth."
fi

# 4. Remote dir exists
if ! ssh "$REMOTE_HOST" "test -d '$REMOTE_DIR'" 2>/dev/null; then
    echo "ERROR: remote dir not found: $REMOTE_HOST:$REMOTE_DIR" >&2
    echo "       create it on Scribe before first sync (Phase 1a §3.1 step 1):" >&2
    echo "       ssh $REMOTE_HOST 'mkdir -p $REMOTE_DIR'" >&2
    exit 1
fi

# -----------------------------------------------------------------------------
# CAPTURE SHA + STAMP
# -----------------------------------------------------------------------------
readonly HEAD_SHA="$(git rev-parse HEAD)"
readonly HEAD_SHA_SHORT="$(git rev-parse --short HEAD)"
readonly STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
readonly DIRTY_TAG="$([[ "$ALLOW_DIRTY" -eq 1 ]] && echo "+dirty" || echo "")"

echo "------------------------------------------------------------"
echo "sync_to_scribe.sh"
echo "  local:        $LOCAL_DIR"
echo "  remote:       $REMOTE_HOST:$REMOTE_DIR"
echo "  HEAD:         $HEAD_SHA_SHORT$DIRTY_TAG ($HEAD_SHA)"
echo "  timestamp:    $STAMP"
[[ "$DRY_RUN" -eq 1 ]] && echo "  MODE:         DRY-RUN (no changes will be made)"
echo "------------------------------------------------------------"

# -----------------------------------------------------------------------------
# RSYNC
# -----------------------------------------------------------------------------
RSYNC_FLAGS=(
    -a            # archive (perms, times, symlinks, recursion)
    -v            # verbose
    --human-readable
    --delete      # remove on remote anything we no longer have locally
                  # (safe: the excludes below cover everything Scribe-side-only)
)
[[ "$DRY_RUN" -eq 1 ]] && RSYNC_FLAGS+=(--dry-run)

# Exclusion list — must mirror .gitignore + ADR-0007
EXCLUDES=(
    --exclude='.git/'
    --exclude='.claude/'
    --exclude='data/'
    --exclude='estimates/'
    --exclude='log/'
    --exclude='output/'
    --exclude='master_supporting_docs/codebooks/'
    --exclude='*.dta'
    --exclude='*.smcl'
    --exclude='*.log'
    --exclude='*.ster'
    --exclude='.DS_Store'
    --exclude='.venv/'
    --exclude='__pycache__/'
)

rsync "${RSYNC_FLAGS[@]}" "${EXCLUDES[@]}" \
    "$LOCAL_DIR/" "$REMOTE_HOST:$REMOTE_DIR/"

# -----------------------------------------------------------------------------
# WRITE VERSION MARKER
# -----------------------------------------------------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
    ssh "$REMOTE_HOST" "cat > '$REMOTE_DIR/VERSION'" <<EOF
# Synced from local on $STAMP
commit:    $HEAD_SHA
short:     $HEAD_SHA_SHORT$DIRTY_TAG
synced_at: $STAMP
synced_by: $USER@$(hostname)
EOF
    echo "wrote VERSION marker on Scribe ($HEAD_SHA_SHORT$DIRTY_TAG)"
fi

echo "------------------------------------------------------------"
echo "DONE.  $REMOTE_HOST:$REMOTE_DIR is now at commit $HEAD_SHA_SHORT$DIRTY_TAG"
echo "------------------------------------------------------------"
