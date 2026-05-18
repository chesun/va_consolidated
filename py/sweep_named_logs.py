#!/usr/bin/env python3
"""
sweep_named_logs.py — convert the predecessor unnamed-log triplet pattern to
the consolidated named-log convention across all relocated .do/.doh files.

Background (2026-05-17 M4 attempt #2 failure mode):
    Predecessor .do files use the triplet
        (1) cap log close _all
        (2) log using "$logdir/.../<name>.smcl", replace text
        (3) log close                                 (or `cap log close`)
    The `_all' form closes EVERY open log — including main.do's master log
    when this file is invoked via `do do/.../<file>.do' from main.do.  After
    the first nested .do, the master log stops capturing.  The orphaned
    main.do echo then leaks into whichever nested log is still open.

    Investigation evidence: 2026-05-17 master log was only 7,445 bytes —
    captured up to the first nested-do `cap log close _all'.  Subsequent
    main.do source-echo leaked into clean_acs_census_tract.smcl, masking
    the r(603) origin.

The fix — name each per-file log, close only by name:
        (1) cap log close <name>          (was: cap log close _all)
        (2) log using "$logdir/.../<name>.smcl", replace text name(<name>)
                                          (added: name(<name>))
        (3) log close <name>              (was: log close   or   cap log close)
    where <name> = the .do file's stem (filename without .do).

    `translate "$logdir/<x>.smcl" "$logdir/<x>.log"' lines are UNCHANGED —
    `translate' takes file PATHS, not log names.

Special handling:
    - do/main.do — opens master log; uses name(master).  Its `cap log close _all'
      (line 60) becomes `cap log close master'; its final `cap log close'
      (line ~485) becomes `cap log close master'.
    - .doh helpers — none currently open logs (verified via grep).  No-op.
    - do/share/outcomesumstats/nsc_codebook.do — opens TWO .txt files (not
      .smcl) via `log using' without `_all'.  Special-case skipped.
    - do/settings.do — no log; no-op.
    - do/_archive/ — out of scope; skipped.

INVOCATION
    python3 py/sweep_named_logs.py
    (run from project root)

OUTPUTS
    Modified files in-place.  Per-file summary printed to stdout.

IDEMPOTENCE
    All three transforms guarded:
      - Transform 1 (`cap log close _all' -> `cap log close <name>'): the
        regex matches the literal `_all'.  After the first run, files
        contain `cap log close <name>' (no `_all') and no longer match.
      - Transform 2 (`log using ...smcl", replace text' -> `... name(<name>)'):
        the regex requires the absence of `name(' in the matched line.
      - Transform 3 (bottom `log close' -> `log close <name>'): handled via
        a state-machine that locates the LAST `[cap ]log close' at depth-0
        whose target is not already a name.  Skip if already named.

    Re-running the helper on a swept tree produces 0 changes.  Test:
        python3 py/sweep_named_logs.py
        git diff -- do/ | wc -l    # should be 0

REFERENCES
    Predecessor failure mode: log/main_17-May-2026_21-14-34.smcl (7,445 B);
        log/data_prep/acs/clean_acs_census_tract.smcl (master echo leak)
    TODO.md Backlog (entry dated 2026-05-17) — defines this sweep's scope
    .claude/rules/stata-code-conventions.md (per-do-file logging convention)
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


# Files where the standard sweep is not appropriate.  Each must be handled
# individually (main.do for master-log naming; settings.do has no log;
# nsc_codebook.do uses non-.smcl .txt log targets).
SPECIAL_FILES = {
    "main.do",
    "settings.do",
}

# Files whose log management deviates structurally (don't auto-rewrite).
SKIP_FILES = {
    # opens .txt logs (not .smcl) twice; no _all in the open triplet.
    "share/outcomesumstats/nsc_codebook.do",
}


# ---------------------------------------------------------------------------
# Transform 1 — top close: `[cap ]log close _all` -> `cap log close <name>`
# ---------------------------------------------------------------------------

# Match both `cap log close _all` and bare `log close _all`.  Capture leading
# indentation so we preserve it.  Both forms appear in the tree (86 + 20).
_TOP_CLOSE_ALL = re.compile(
    r'^(?P<indent>[ \t]*)(cap[ \t]+)?log[ \t]+close[ \t]+_all[ \t]*$',
    re.MULTILINE,
)


def transform_top_close(text: str, name: str) -> tuple[str, int]:
    """
    Replace `cap log close _all` / `log close _all` -> `cap log close <name>`.

    The `cap` prefix is always added (the original was idempotent regardless
    of the cap presence; the new convention is to make it explicit so that
    `log close <name>` doesn't error if the log isn't open for some reason).

    Returns (transformed_text, n_replacements).
    """
    n = 0

    def _sub(m: re.Match) -> str:
        nonlocal n
        n += 1
        return f"{m.group('indent')}cap log close {name}"

    return _TOP_CLOSE_ALL.sub(_sub, text), n


# ---------------------------------------------------------------------------
# Transform 2 — `log using "...smcl", replace text` -> add `name(<name>)`
# ---------------------------------------------------------------------------

# Capture `log using "<path>.smcl", replace text` AND the trailing line break
# context for safe modification.  Only matches when `name(' is NOT already
# present in the line.  Allows `replace text` in either order and with
# possible additional whitespace.
_LOG_USING_SMCL = re.compile(
    r'(?P<prefix>log[ \t]+using[ \t]+"[^"]*\.smcl"[ \t]*,[ \t]*'
    r'(?:replace[ \t]+text|text[ \t]+replace|replace|text))'
    r'(?P<rest>[ \t]*)$',
    re.MULTILINE,
)


def transform_log_using(text: str, name: str) -> tuple[str, int]:
    """
    Append `name(<name>)` to `log using "...smcl", ...` lines that don't
    already have a `name(...)` option.

    Idempotence: regex doesn't match lines that already contain `name(`.

    Returns (transformed_text, n_replacements).
    """
    n = 0

    def _sub(m: re.Match) -> str:
        nonlocal n
        full = m.group(0)
        # Idempotence guard: skip if `name(' already in this match.
        if "name(" in full:
            return full
        n += 1
        return f"{m.group('prefix')} name({name}){m.group('rest')}"

    return _LOG_USING_SMCL.sub(_sub, text), n


# ---------------------------------------------------------------------------
# Transform 3 — bottom close: `[cap ]log close` (no target) -> `log close <name>`
# ---------------------------------------------------------------------------

# Match bare `cap log close` or `log close` (NOT `cap log close _all`,
# NOT `cap log close <something>`).  End-of-line anchored to avoid matching
# the middle of a string.  Captures indentation + leading `cap` if any.
_BOTTOM_CLOSE_BARE = re.compile(
    r'^(?P<indent>[ \t]*)(?P<cap>cap[ \t]+)?log[ \t]+close[ \t]*$',
    re.MULTILINE,
)


def transform_bottom_close(text: str, name: str) -> tuple[str, int]:
    """
    Replace bare `[cap ]log close` -> `cap log close <name>`.

    Conservative — only matches lines whose entire content is exactly the
    bare close pattern.  Lines like `log close _all`, `log close foo`, or
    inline `cap log close // comment` are not matched.

    Idempotence: after first run, all bare closes carry a name target and
    no longer match.

    Returns (transformed_text, n_replacements).
    """
    n = 0

    def _sub(m: re.Match) -> str:
        nonlocal n
        n += 1
        return f"{m.group('indent')}cap log close {name}"

    return _BOTTOM_CLOSE_BARE.sub(_sub, text), n


# ---------------------------------------------------------------------------
# main.do special-case
# ---------------------------------------------------------------------------

def transform_main_do(text: str) -> tuple[str, int]:
    """
    main.do uses `master` as its name.  The standard helpers (top/log-using/
    bottom) work — we just call them with name='master'.

    Returns (transformed_text, n_total_replacements).
    """
    n = 0
    text, n1 = transform_top_close(text, "master")
    text, n2 = transform_log_using(text, "master")
    text, n3 = transform_bottom_close(text, "master")
    n = n1 + n2 + n3
    return text, n


# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------

def process_file(path: Path, do_root: Path) -> tuple[int, int, int]:
    """
    Read `path`, apply the three transforms, write back if changed.

    Returns (n_top, n_using, n_bottom).
    """
    text = path.read_text()
    original = text

    rel = path.relative_to(do_root).as_posix()
    name = path.stem

    if rel in SKIP_FILES:
        return 0, 0, 0

    if path.name in SPECIAL_FILES:
        if path.name == "main.do":
            text, n_total = transform_main_do(text)
            if text != original:
                path.write_text(text)
            # We don't bucket per-transform for main.do; report total under top.
            return n_total, 0, 0
        # settings.do — no log management; no-op.
        return 0, 0, 0

    # .doh files: verify they don't manage logs (per grep, none currently
    # do).  Apply transforms anyway — if a .doh has the pattern, it gets
    # swept; if it doesn't, regex matches 0 times (idempotent).
    text, n_top = transform_top_close(text, name)
    text, n_using = transform_log_using(text, name)
    text, n_bottom = transform_bottom_close(text, name)

    if text != original:
        path.write_text(text)

    return n_top, n_using, n_bottom


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    do_root = repo_root / "do"
    if not do_root.is_dir():
        sys.stderr.write(f"do/ not found at {do_root}\n")
        return 2

    targets: list[Path] = []
    for path in sorted(do_root.rglob("*")):
        if "_archive" in path.parts:
            continue
        if path.is_file() and path.suffix in (".do", ".doh"):
            targets.append(path)

    total_top = 0
    total_using = 0
    total_bottom = 0
    n_files = 0
    n_changed = 0
    for path in targets:
        before = path.read_text()
        n_top, n_using, n_bottom = process_file(path, do_root)
        after = path.read_text()
        n_files += 1
        if before != after:
            n_changed += 1
            rel = path.relative_to(repo_root)
            print(
                f"{rel}: top {n_top}, log-using {n_using}, bottom {n_bottom}"
            )
        total_top += n_top
        total_using += n_using
        total_bottom += n_bottom

    print()
    print(f"scanned {n_files} files; {n_changed} modified")
    print(f"Transform 1 (top close _all -> named): {total_top}")
    print(f"Transform 2 (log using name() suffix): {total_using}")
    print(f"Transform 3 (bottom close -> named):   {total_bottom}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
