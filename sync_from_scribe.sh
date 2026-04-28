#!/usr/bin/env bash
#
# sync_from_scribe.sh — pull tables/figures (and other producer outputs)
#                       from Scribe back to local for git commit
# =============================================================================
#
# PURPOSE
#     Per ADR-0007: code/docs/tables/figures are tracked in git; data/logs/
#     estimates are NOT.  When `main.do` runs on Scribe and produces new
#     paper-shipping artifacts (`tables/`, `figures/`), those need to come
#     back to the local Mac so they can be `git add`-ed and pushed.
#
#     This script is the asymmetric counterpart to sync_to_scribe.sh:
#       - sync_to_scribe.sh:  local → Scribe (entire code mirror)
#       - sync_from_scribe.sh: Scribe → local (just tables/figures)
#
#     We deliberately do NOT pull all of Scribe back: the Scribe working
#     copy may have intermediate artifacts (estimates/, log/, etc.) that
#     belong on Scribe and not in git.
#
# USAGE
#     bash sync_from_scribe.sh                  # standard run (tables + figures)
#     bash sync_from_scribe.sh --dry-run        # show what would change
#     bash sync_from_scribe.sh --include-supplementary
#                                                # also pull supplementary/
#
# WHAT GETS PULLED
#     tables/                                    # paper tables (.tex)
#     figures/                                   # paper figures (.pdf)
#   and (with --include-supplementary):
#     supplementary/                             # online appendix sources
#
# PRE-REQS
#     Same as sync_to_scribe.sh:
#       1. SSH ControlMaster set up (see sync_to_scribe.sh SSH SETUP section)
#       2. Remote dir $REMOTE_DIR populated (sync_to_scribe.sh + main.do run)
#       3. Local repo at $LOCAL_DIR
#
# WORKFLOW
#     1. sync_to_scribe.sh                              # push code
#     2. ssh $REMOTE_HOST 'cd $REMOTE_DIR && stata -b do main.do'
#                                                        # run pipeline on Scribe
#     3. sync_from_scribe.sh                            # pull tables/figures
#     4. git add tables/ figures/ && git commit         # commit outputs
#     5. sync_to_scribe.sh                              # push the commit ref back
#                                                        # (so VERSION matches)
#
# REFERENCES
#     ADR-0007 (code-data separation; tracked vs. ignored asset classes)
#     Plan v3 §3.1 step 4 (sync_from_scribe.sh)

set -euo pipefail

# -----------------------------------------------------------------------------
# CONFIG  (must match sync_to_scribe.sh)
# -----------------------------------------------------------------------------
readonly LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REMOTE_HOST="Scribe"
readonly REMOTE_DIR="/home/research/ca_ed_lab/projects/common_core_va/consolidated"

# -----------------------------------------------------------------------------
# ARG PARSING
# -----------------------------------------------------------------------------
DRY_RUN=0
INCLUDE_SUPP=0
for arg in "$@"; do
    case "$arg" in
        --dry-run)                  DRY_RUN=1 ;;
        --include-supplementary)    INCLUDE_SUPP=1 ;;
        -h|--help)
            sed -n '/^# USAGE/,/^# PRE-REQS/p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "unknown arg: $arg" >&2 ; exit 2 ;;
    esac
done

# -----------------------------------------------------------------------------
# SUBDIRS TO PULL
# -----------------------------------------------------------------------------
SUBDIRS=(tables figures)
[[ "$INCLUDE_SUPP" -eq 1 ]] && SUBDIRS+=(supplementary)

# -----------------------------------------------------------------------------
# RSYNC EACH SUBDIR
# -----------------------------------------------------------------------------
RSYNC_FLAGS=(
    -a
    -v
    --human-readable
    --delete                # if a table was removed on Scribe, remove locally
)
[[ "$DRY_RUN" -eq 1 ]] && RSYNC_FLAGS+=(--dry-run)

EXCLUDES=(
    --exclude='.DS_Store'
    --exclude='*.aux'
    --exclude='*.log'        # LaTeX build artifacts (defensive — should not be present)
    --exclude='*.synctex.gz'
)

echo "------------------------------------------------------------"
echo "sync_from_scribe.sh"
echo "  remote:       $REMOTE_HOST:$REMOTE_DIR"
echo "  local:        $LOCAL_DIR"
echo "  pulling:      ${SUBDIRS[*]}"
[[ "$DRY_RUN" -eq 1 ]] && echo "  MODE:         DRY-RUN"
echo "------------------------------------------------------------"

cd "$LOCAL_DIR"

for sub in "${SUBDIRS[@]}"; do
    echo ""
    echo "--- pulling $sub/ ---"

    # Verify remote subdir exists (otherwise rsync would create an empty local dir)
    if ! ssh "$REMOTE_HOST" "test -d '$REMOTE_DIR/$sub'" 2>/dev/null; then
        echo "  [SKIP] $REMOTE_DIR/$sub does not exist on Scribe."
        continue
    fi

    mkdir -p "$LOCAL_DIR/$sub"
    rsync "${RSYNC_FLAGS[@]}" "${EXCLUDES[@]}" \
        "$REMOTE_HOST:$REMOTE_DIR/$sub/" "$LOCAL_DIR/$sub/"
done

echo "------------------------------------------------------------"
echo "DONE.  next: review changes, git add, commit, sync_to_scribe.sh."
echo "------------------------------------------------------------"
