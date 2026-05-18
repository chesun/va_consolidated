#!/usr/bin/env python3
"""
sweep_comments_and_logdirs.py — bundled sweep across active .do/.doh files.

Implements the comprehensive sweep documented in
quality_reports/plans/2026-05-17_comment-bug-sweep.md (v3).

TWO transforms applied per file:

Transform 1 — `/*` path-glob fix (state-machine, context-aware)
    Stata's parser counts `/*` opens greedily.  A path-glob like `prepare/*`
    sitting inside a `/* ... */` header block produces an unmatched open and
    pushes the rest of the file into a runaway block comment.

    The fix: inside any Stata comment context (block `/* ... */`, line `*`,
    line `//`, but NOT a string literal), rewrite `/*` -> `/<x>`.  Legitimate
    block-comment opens in `code` state are preserved.

Transform 2 — log directory mirror
    Each .do at do/<reldir>/<name>.do should write its log to
    $logdir/<reldir>/<name>.smcl (mirroring do/ structure).  Updates:
      - `log using "$logdir/<name>.smcl"`        -> nested path
      - `translate $logdir/<name>.smcl ...`      -> nested path
      - `cap mkdir "$logdir"` block              -> add intermediate dirs

INVOCATION
    python3 py/sweep_comments_and_logdirs.py
    (run from project root)

OUTPUTS
    Modified files in place.
    One-line summary per transformed file printed to stdout.

EXCLUSIONS
    do/_archive/ — out of scope per plan
    do/main.do, do/settings.do — top-level (reldir empty); Transform 2 skipped
                                  Transform 1 still applies.

ONE-SHOT INTENT, IDEMPOTENT BY CONSTRUCTION
    This is intended as a ONE-SHOT migration helper.  Both transforms are
    nonetheless designed to be idempotent so re-runs on an already-swept
    tree produce 0 changes:
      - T1 (`transform_comment_globs` + `_flatten_lone_block_opens` +
        `strip_orphan_block_closes`): all comment-state `/*` / `*/`
        digraphs are rewritten to `<x>` placeholders on first run; second
        run finds no comment-state digraphs and does nothing.
      - T2 (`transform_log_paths`): path-rewrite regexes use a `/`-free
        char class so already-nested paths don't re-match; the cap-mkdir
        cascade is gated on whether the expected cascade lines already
        follow the `cap mkdir "$logdir"` anchor (idempotence fix added
        post round-2 review per `M-T2`).
    Detection if idempotence ever regresses: a clean `git diff` after a
    second run.  Test:
        python3 py/sweep_comments_and_logdirs.py
        git diff -- do/ | wc -l    # should be 0

REFERENCES
    quality_reports/plans/2026-05-17_comment-bug-sweep.md v3 (+ round-2
        addendum noting the state-machine pre-pass + T2 idempotence fix)
    quality_reports/reviews/2026-05-17_dual-sweep-round2_coder_review.md
        (round-2 finding M-T2: T2 idempotence)
    quality_reports/reviews/2026-05-18_overflatten-fix_coder_review.md
        Round-3 review: closed the over-flatten bug deferred from round 2.
        Confirmed path-glob predicates + context-aware inner rewriter prevent
        legitimate block-marker destruction. PASS 95/100.
    ADR-0021 (sandbox + description convention)
    .claude/rules/stata-code-conventions.md (rule additions in same commit)
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# Transform 1 — state-machine `/*` rewrite
# ---------------------------------------------------------------------------

# Path-continuation chars: chars that precede `/*` or follow `*/` in a
# path-glob context (e.g., `prepare/*`, `$logdir/*`, `do/<x><x>/*.do`).
# Used by `_is_path_glob_open` and `_is_path_glob_close` below.
_PATH_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_<>${}.-"


def _is_path_glob_open(text: str, i: int) -> bool:
    """
    Return True if `text[i:i+2] == '/*'` is a path-glob fragment (e.g., the
    `/*` in `prepare/*` or `$logdir/*`), False if it is a genuine
    block-comment open token.

    Heuristic — `/*` is a path-glob fragment iff the char immediately
    BEFORE the `/` is a path-continuation char.  Otherwise (start-of-text,
    whitespace, newline, punctuation, `*` for `**/`, `"` etc.) it is a
    block-comment open.
    """
    if i == 0:
        return False
    prev = text[i - 1]
    return prev in _PATH_CHARS


def _is_path_glob_close(text: str, i: int) -> bool:
    """
    Return True if `text[i:i+2] == '*/'` is a path-glob fragment (e.g., the
    `*/` in `**/<sub>` or `/foo/*/bar`), False if it is a genuine
    block-comment close token.

    Heuristic — `*/` is a path-glob fragment iff the char immediately
    AFTER the `/` (at position i+2) is a path-continuation char.  Otherwise
    (EOF, whitespace, newline, punctuation) it is a block-comment close.
    """
    n = len(text)
    if i + 2 >= n:
        return False
    after = text[i + 2]
    return after in _PATH_CHARS


def _find_matching_close(text: str, open_end: int) -> int:
    """
    Given a position `open_end` immediately after a `/*` open token, scan
    forward using Stata-parser semantics (depth-counting: every `/*` adds
    depth, every `*/` removes depth) and return the position of the `*/`
    close that brings depth back to 0.

    PATH-GLOB AWARE: path-glob substrings `/*` (e.g., `$logdir/*`) and `*/`
    (e.g., `**/<sub>`) are NOT counted as block-comment opens/closes.  Bug
    fix 2026-05-18: the original implementation counted every `/*` and `*/`
    digraph as a depth-change regardless of context.  In files with
    path-glob substrings INSIDE a multi-line outer block-comment header
    (e.g., `$logdir/*` on line 32 of secqoiclean1415.do, inside a `/* ...
    */` header spanning lines 1-40), the depth count was inflated past 0
    when the real header `*/` close was reached, and `_find_matching_close`
    walked forward looking for a deeper match.  The next legitimate `*/`
    found (line 87's stray `*/` in a `*` line-comment) was then declared
    the "matching close", and `_flatten_lone_block_opens` blanket-rewrote
    every digraph in the over-extended inner span — including the real
    header close and legitimate single-line `/* ... */` body blocks
    (sec1415: lines 40, 44, 73, 74, 80).  Stata's resulting source had no
    header close → runaway block comment swallowing lines 2-87 → M4
    acceptance run errored at `gen totalresp = _N → r(110)`.

    Returns the START position of the matching `*/`, or -1 if no match.
    """
    n = len(text)
    depth = 1
    i = open_end
    while i < n - 1:
        if text[i] == "/" and text[i + 1] == "*":
            # Only count as a real block-open if NOT a path-glob fragment.
            if not _is_path_glob_open(text, i):
                depth += 1
            i += 2
            continue
        if text[i] == "*" and text[i + 1] == "/":
            # Only count as a real block-close if NOT a path-glob fragment.
            if not _is_path_glob_close(text, i):
                depth -= 1
                if depth == 0:
                    return i
            i += 2
            continue
        i += 1
    return -1


def _rewrite_inner_block_markers(inner: str) -> str:
    """
    Rewrite real block-comment `/*` and `*/` digraphs INSIDE an outer
    multi-line block-comment span to `/<x>` and `<x>` respectively, while
    leaving path-glob fragments intact (Transform 1 handles those
    correctly via its state machine downstream).

    Bug fix 2026-05-18 sibling: the original `_flatten_lone_block_opens`
    used `inner.replace("/*", "/<x>").replace("*/", "<x>")`, which
    blanket-rewrote every digraph regardless of context.  Combined with the
    over-greedy depth-counting in `_find_matching_close` (now fixed
    separately), this produced the M4-blocking over-flatten on lines 40
    (header close), 44, 73, 74, 80 of secqoiclean1415.do.

    Now we walk the inner char-by-char and distinguish:
      - REAL block-open `/*` (start-of-text / whitespace-preceded / etc.):
        rewrite to `/<x>` so Transform 1's state machine sees no inner
        block opens and stays in outer-block state until the real outer
        close.
      - REAL block-close `*/` (whitespace/newline/EOF-followed): rewrite
        to `<x>` for the same reason.
      - PATH-GLOB `/*` and `*/`: leave intact.  Transform 1's state machine
        will rewrite them correctly via the path-continuation-char heuristic.

    NOTE: `_is_path_glob_open` and `_is_path_glob_close` operate on the
    INNER span only when called from here, so the prev/next char checks
    use `inner` rather than the full original `text`.  This is correct
    for path-glob detection because path chars are local; an inner `/*`
    preceded by a path char in the inner span IS a path-glob regardless
    of the outer context.

    Returns the rewritten inner string.
    """
    n = len(inner)
    out: list[str] = []
    i = 0
    while i < n:
        if i + 1 < n and inner[i] == "/" and inner[i + 1] == "*":
            if _is_path_glob_open(inner, i):
                out.append("/*")
            else:
                out.append("/<x>")
            i += 2
            continue
        if i + 1 < n and inner[i] == "*" and inner[i + 1] == "/":
            if _is_path_glob_close(inner, i):
                out.append("*/")
            else:
                out.append("<x>")
            i += 2
            continue
        out.append(inner[i])
        i += 1
    return "".join(out)


def _flatten_lone_block_opens(text: str) -> tuple[str, int]:
    """
    Pre-pass: handle the predecessor's "fake nested comment" pattern.

    The predecessor relied on Stata's depth-counting `/*` parser to make
    multi-line block-comment-out regions work even when they contain inner
    `/* ... */` mini-comments:

        /*                       <- `/*` opens "outer" block
          /* mini-comment */     <- inner pair (depth +1/-1)
          ...code...
        */                       <- outer close (depth -1, back to 0)

    Note: the outer open can be either a lone `/*\n` OR an `/* <text>\n`
    form (any content before the newline).  The 2026-05-17 v1 of this
    helper used a narrow regex `r'/\*[ \t]*\n'` that matched only the lone
    form, missing 5 files with `/* Note: ...\n` and `/* This is old code\n`
    outer openers.  Those 5 files had the inner `/* mini */` pair
    half-rewritten by Transform 1 (inner `/*`→`/<x>`, inner `*/` retained),
    and the retained `*/` then prematurely closed the outer block.  Code
    that was dormant in predecessor became ACTIVE in the consolidated tree.

    Fix (round-2): walk forward state-machine-style finding EVERY
    multi-line `/* ... */` block (depth-counted), not just lone `/*\n`
    opens.  For each multi-line block whose inner span contains REAL `/*`
    or `*/` block markers, rewrite every interior `/*` -> `/<x>` and every
    interior `*/` -> `<x>` so the outer block becomes a single flat
    `/*<text>\n ... */` with no inner digraphs that could confuse Stata's
    depth-counting parser after Transform 1.

    Fix (round-3, 2026-05-18): both the depth-counting in
    `_find_matching_close` AND the inner-rewrite are now path-glob aware.

    Bug class addressed:
        Before round-3, `_find_matching_close` counted every `/*` and `*/`
        digraph as a depth change.  In files where a path-glob substring
        (e.g., `$logdir/*` in a header docstring) appeared INSIDE a
        multi-line outer block, depth got inflated past 0 when the real
        header `*/` close was reached.  The function then walked forward
        seeking a "deeper" match, and landed on a stray `*/` token much
        later in the file (e.g., line 87 of secqoiclean1415.do — a `*`
        line-comment with stray `*/` text the predecessor parser-bug
        had been masking).  Subsequently `inner.replace("/*", "/<x>")
        .replace("*/", "<x>")` blanket-rewrote every digraph in the
        over-extended inner span, destroying:
          - the real header `*/` close (turning `------*/` into
            `------<x>`, so the header never closed and Stata treated
            lines 2-87 as one runaway block comment);
          - legitimate single-line `/* ... */` body blocks (turning
            them into `/<x> ... <x>` non-comment syntax).
        Empirical evidence: M4 attempt #3 errored at
        `secqoiclean1415.do:89 (gen totalresp = _N → r(110))` because
        `use sec1415` (line 65) never ran inside the runaway comment.

    Both pieces of the fix:
        1. `_find_matching_close` now uses `_is_path_glob_open` and
           `_is_path_glob_close` to skip path-glob digraphs when
           depth-counting.
        2. `_rewrite_inner_block_markers` replaces the previous blanket
           `.replace()` call.  It walks the inner char-by-char and rewrites
           ONLY genuine block markers; path-glob digraphs are left intact
           and get rewritten downstream by Transform 1's state machine.

    String-literal protection: `/*` inside `"..."` is not treated as a
    block open.  The state machine tracks `code`/`string` and only enters
    block-finding when in `code` state.

    Returns (transformed_text, n_inner_rewrites).
    """
    # Walk forward and find every multi-line `/* ... */` block at depth-0.
    n = len(text)
    spans: list[tuple[int, int]] = []  # (inner_start, inner_end)
    state = "code"  # code | string
    i = 0
    while i < n:
        ch = text[i]
        nxt = text[i + 1] if i + 1 < n else ""

        if state == "code":
            if ch == '"':
                state = "string"
                i += 1
                continue
            if ch == "/" and nxt == "*":
                # Found a `/*` block open at depth 0.  Find its matching close.
                o_end = i + 2
                close_pos = _find_matching_close(text, o_end)
                if close_pos < 0:
                    # Unmatched open — leave it; Transform 1 will handle.
                    i += 2
                    continue
                inner = text[o_end:close_pos]
                # Only flatten multi-line blocks (open and close on
                # different lines).  Single-line `/* foo */` blocks have
                # no nesting risk and Transform 1 handles them correctly.
                # Also only flatten if the inner span actually contains
                # nested digraphs.
                if "\n" in inner and ("/*" in inner or "*/" in inner):
                    spans.append((o_end, close_pos))
                # Advance past the close regardless.
                i = close_pos + 2
                continue
            i += 1
            continue

        if state == "string":
            if ch == '"':
                state = "code"
            i += 1
            continue

    if not spans:
        return text, 0

    # Rewrite interior REAL block markers in reverse order so offsets remain valid.
    # Bug fix 2026-05-18: path-glob `/*` and `*/` are NOT rewritten here — they
    # remain in place and get handled by Transform 1's state machine.  Only
    # genuine block-open `/*` and block-close `*/` (the LEGITIMATE inner
    # fake-nested-comment pair) are rewritten to `/<x>` and `<x>`.
    new_text = text
    rewrites = 0
    for s_start, s_end in reversed(spans):
        inner = new_text[s_start:s_end]
        inner_new = _rewrite_inner_block_markers(inner)
        if inner_new != inner:
            # Count actual rewrites (chars changed) by counting digraph diffs.
            n_open_before = sum(
                1 for i in range(len(inner) - 1)
                if inner[i] == "/" and inner[i + 1] == "*"
                and not _is_path_glob_open(inner, i)
            )
            n_close_before = sum(
                1 for i in range(len(inner) - 1)
                if inner[i] == "*" and inner[i + 1] == "/"
                and not _is_path_glob_close(inner, i)
            )
            rewrites += n_open_before + n_close_before
            new_text = new_text[:s_start] + inner_new + new_text[s_end:]

    return new_text, rewrites


def transform_comment_globs(text: str) -> tuple[str, int]:
    """
    Walk `text` character-by-character.  Inside any comment context (block,
    line-`*`, or line-`//`), rewrite glob-wildcard `*` chars to `<x>` so that
    no `/*` or `*/` digraph survives that could confuse Stata's parser.

    Specifically, inside a comment:
        `/**/`   -> `/<x>/<x>`     (handles `**/` followed by anything via two passes)
        `/*`     -> `/<x>`          (path-glob immediately after a slash)
        `*/`     -> `<x>/`          (path-glob immediately before a slash, e.g. `**/`)

    Outside comments (code state), `/*` legitimately opens a block comment;
    `*/` legitimately closes it; `*` is multiplication or a wildcard in code
    contexts that the parser already handles.  Leave them alone.

    Inside a string literal, leave everything alone.

    The order of checks per character matters.  We resolve the longer pattern
    first (`/**/` → `/<x>/<x>`), then `/*` (when state is comment), then `*/`
    (when state is comment).  Outside comments, `/*` toggles into block state
    and `*/` toggles out.

    Returns (transformed_text, n_replacements).
    """
    out: list[str] = []
    n = len(text)
    i = 0
    state = "code"           # code | block | line_star | line_slash | string
    at_line_start = True     # True until a non-whitespace char is seen on this line
    replacements = 0

    while i < n:
        ch = text[i]
        nxt = text[i + 1] if i + 1 < n else ""

        if ch == "\n":
            if state in ("line_star", "line_slash"):
                state = "code"
            out.append(ch)
            at_line_start = True
            i += 1
            continue

        if state == "code":
            # `*` at start-of-line opens a Stata line comment.
            if ch == "*" and at_line_start:
                state = "line_star"
                out.append(ch)
                at_line_start = False
                i += 1
                continue
            # `//` opens a line comment.  If immediately followed by `*`,
            # insert a space — the visual `//*` creates a grep-overlap
            # `/*` substring that confuses naive `grep -c '/\*'` balance
            # checks without confusing Stata's parser.  Inserting a space
            # is semantically equivalent and avoids the false positive.
            if ch == "/" and nxt == "/":
                state = "line_slash"
                after = text[i + 2] if i + 2 < n else ""
                if after == "*":
                    out.append("// ")
                    replacements += 1
                else:
                    out.append("//")
                at_line_start = False
                i += 2
                continue
            # `/*` opens a legitimate block comment.
            if ch == "/" and nxt == "*":
                state = "block"
                out.append("/*")
                at_line_start = False
                i += 2
                continue
            # String literal.
            if ch == '"':
                state = "string"
                out.append(ch)
                at_line_start = False
                i += 1
                continue
            out.append(ch)
            if not ch.isspace():
                at_line_start = False
            i += 1
            continue

        if state == "block":
            # Distinguish a true block-comment close from a path-glob `*/`.
            # Inside a `/* ... */` block, any `*/` would normally close the
            # block.  But empirically (per plan v3 §3.3 + the M4 failure mode),
            # `*/` digraphs also appear inside path-glob patterns like
            # `<path>/**/<sub>` or `<path>/*`.  The convention says path-glob
            # `*` chars inside comments must become `<x>`, so we must rewrite
            # such `*/` rather than treat them as block closes.
            #
            # Heuristic — the `*/` is a path-glob fragment when followed by
            # any path-continuation char (alphanumeric, `_`, `<`, `$`, `{`,
            # or `*` — the latter for `**/*` patterns).  Otherwise it is a
            # real block close.
            if ch == "*" and nxt == "/":
                after = text[i + 2] if i + 2 < n else ""
                if after and (after.isalnum() or after in ("_", "<", "$", "{", "*")):
                    # Path-glob fragment — rewrite to `<x>/`.
                    out.append("<x>/")
                    replacements += 1
                    i += 2
                    continue
                # Real close (followed by whitespace, newline, EOF, punctuation, etc.).
                out.append("*/")
                state = "code"
                i += 2
                continue
            # `/*` inside an existing block = SPURIOUS path-glob.  Rewrite.
            if ch == "/" and nxt == "*":
                out.append("/<x>")
                replacements += 1
                i += 2
                continue
            # Bare `*` inside block followed by another `*` (e.g., `**` as in
            # `**/<sub>`): collapse `**/` -> `<x>/` or `**` -> `<x>`.
            if ch == "*" and nxt == "*" and out and out[-1].endswith("/"):
                after_pair = text[i + 2] if i + 2 < n else ""
                if after_pair == "/":
                    out.append("<x>/")
                    replacements += 1
                    i += 3
                    continue
                out.append("<x>")
                replacements += 1
                i += 2
                continue
            # Lone `*` preceded by `/` (path-glob trailing wildcard).
            # E.g., `do/<x><x>/*.do` -> `do/<x><x>/<x>.do`.  Only rewrite when
            # NOT followed by `*` or `/` (those cases are handled above).
            if ch == "*" and out and out[-1].endswith("/") and nxt != "*" and nxt != "/":
                out.append("<x>")
                replacements += 1
                i += 1
                continue
            out.append(ch)
            i += 1
            continue

        if state in ("line_star", "line_slash"):
            if ch == "/" and nxt == "*":
                out.append("/<x>")
                replacements += 1
                i += 2
                continue
            # Inside a line comment, `*/` can't close anything (line comment
            # terminates at newline), but the substring triggers naive
            # `grep -c '\*/'` balance checks.  Rewrite path-glob `*/` to
            # `<x>/` when followed by a path-continuation char; rewrite
            # other `*/` (end-of-line, whitespace-followed) to `<x>` for
            # grep-cleanness.
            if ch == "*" and nxt == "/":
                after = text[i + 2] if i + 2 < n else ""
                if after and (after.isalnum() or after in ("_", "<", "$", "{", "*")):
                    out.append("<x>/")
                    replacements += 1
                    i += 2
                    continue
                # Other contexts (end-of-line, whitespace) — rewrite to `<x>`.
                out.append("<x>")
                replacements += 1
                i += 2
                continue
            # `**` inside line comment (e.g., `// do/**/*.do`)
            if ch == "*" and nxt == "*" and out and out[-1].endswith("/"):
                after_pair = text[i + 2] if i + 2 < n else ""
                if after_pair == "/":
                    out.append("<x>/")
                    replacements += 1
                    i += 3
                    continue
                out.append("<x>")
                replacements += 1
                i += 2
                continue
            # Lone `*` preceded by `/` (trailing path-glob) inside a line comment.
            if ch == "*" and out and out[-1].endswith("/") and nxt != "*" and nxt != "/":
                out.append("<x>")
                replacements += 1
                i += 1
                continue
            out.append(ch)
            i += 1
            continue

        if state == "string":
            if ch == '"':
                state = "code"
            out.append(ch)
            i += 1
            continue

        out.append(ch)
        i += 1

    return "".join(out), replacements


_ORPHAN_CLOSE_LINE = re.compile(r'^(\s*)\*/\s*$', re.MULTILINE)


def strip_orphan_block_closes(text: str) -> tuple[str, int]:
    """
    Second pass: remove orphan `*/` tokens that the predecessor parser bug
    had been masking.

    After Transform 1 fixes the spurious `/*` opens, two kinds of orphan
    `*/` survive in the source:

    1. Whole-line orphans — a line containing only whitespace + `*/`.
       These are predecessor latent bugs where the parser bug masked an
       unmatched `*/`.  Strip the entire line (whole line becomes empty).
       With Transform 1 applied, the file's block-comment depth at these
       lines is 0, so Stata would parse them as `*`-prefixed line comments
       harmlessly — but the naive `grep -c '\*/'` balance check would
       still flag them.  Strip for grep-cleanness.

    2. Mid-line orphans — a `*/` token in the middle of code (state=code,
       depth=0).  Same source: predecessor parser-bug masking.  Strip the
       `*/` token (delete those two chars).

    Returns (transformed_text, n_stripped).
    """
    stripped = 0

    # Pass 1: whole-line orphans — strip the entire line (including the
    # newline) so the file stays clean.  Use a state-machine to ensure we
    # only strip when we're in code state at depth 0 on that line.
    # Simpler: identify candidate lines via regex first, then verify each is
    # at code-depth-0 via a depth scan.
    candidate_lines: list[tuple[int, int]] = []  # (start, end) spans
    for m in _ORPHAN_CLOSE_LINE.finditer(text):
        candidate_lines.append((m.start(), m.end()))

    if candidate_lines:
        # Build a depth map: for each byte offset, what is the block-comment
        # depth in code semantics?  We scan once.
        depth_at_offset: list[int] = []
        state = "code"
        depth = 0
        i = 0
        n = len(text)
        while i < n:
            depth_at_offset.append(depth)
            ch = text[i]
            nxt = text[i + 1] if i + 1 < n else ""
            if state == "code":
                if ch == "/" and nxt == "/":
                    state = "line_slash"
                    i += 2
                    depth_at_offset.append(depth)
                    continue
                if ch == "/" and nxt == "*":
                    state = "block"
                    depth = 1
                    i += 2
                    depth_at_offset.append(depth)
                    continue
                if ch == '"':
                    state = "string"
                    i += 1
                    continue
                # `*` at line start: line comment
                # (We don't track at_line_start strictly here — but the
                # candidate lines are whitespace + `*/` patterns; on those
                # lines the `*/` is what we're checking.)
                i += 1
                continue
            if state == "block":
                if ch == "*" and nxt == "/":
                    depth -= 1
                    if depth <= 0:
                        state = "code"
                        depth = 0
                    i += 2
                    depth_at_offset.append(depth)
                    continue
                if ch == "/" and nxt == "*":
                    depth += 1
                    i += 2
                    depth_at_offset.append(depth)
                    continue
                i += 1
                continue
            if state == "line_slash":
                if ch == "\n":
                    state = "code"
                i += 1
                continue
            if state == "string":
                if ch == '"':
                    state = "code"
                i += 1
                continue
            i += 1
        # Pad depth_at_offset to length n.
        while len(depth_at_offset) < n:
            depth_at_offset.append(depth)

        # Now strip candidate lines whose `*/` lies at code-depth 0.
        # Process in reverse so offsets remain valid.
        new_text = text
        for start, end in reversed(candidate_lines):
            # Find the offset of the `*/` within the candidate line.
            # The line goes from `start` (after stripping the trailing `\s*$`,
            # but our regex matches the whole line).  The `*/` is at the
            # position where chars become `*/`.
            line_text = text[start:end]
            star_pos = line_text.find("*/")
            if star_pos < 0:
                continue
            global_star = start + star_pos
            if global_star >= len(depth_at_offset):
                continue
            d = depth_at_offset[global_star]
            if d > 0:
                # This `*/` is a legitimate close.
                continue
            # Orphan — strip the whole line.  Include the trailing newline
            # if present.
            line_end = end
            if line_end < len(new_text) and new_text[line_end] == "\n":
                line_end += 1
            new_text = new_text[:start] + new_text[line_end:]
            stripped += 1
        text = new_text

    return text, stripped


# ---------------------------------------------------------------------------
# Transform 2 — log directory mirror
# ---------------------------------------------------------------------------

# Match `log using "$logdir/<name>.smcl"` — quoted form
_LOG_USING_QUOTED = re.compile(
    r'(log\s+using\s+")\$logdir/([A-Za-z0-9_.-]+)\.smcl(")'
)
# Match `log using $logdir/<name>.smcl` — unquoted form
_LOG_USING_UNQUOTED = re.compile(
    r'(log\s+using\s+)\$logdir/([A-Za-z0-9_.-]+)\.smcl(\b)'
)
# Match `translate "$logdir/<name>.smcl"` or `translate $logdir/<name>.smcl`
_TRANSLATE_SMCL_QUOTED = re.compile(
    r'(translate\s+")\$logdir/([A-Za-z0-9_.-]+)\.smcl(")'
)
_TRANSLATE_SMCL_UNQUOTED = re.compile(
    r'(translate\s+)\$logdir/([A-Za-z0-9_.-]+)\.smcl(\b)'
)
# Match `"$logdir/<name>.log"` or `$logdir/<name>.log` (paired with translate, possibly multi-line)
_LOGPATH_LOG_QUOTED = re.compile(
    r'(")\$logdir/([A-Za-z0-9_.-]+)\.log(")'
)
_LOGPATH_LOG_UNQUOTED = re.compile(
    r'(\s)\$logdir/([A-Za-z0-9_.-]+)\.log(\b)'
)
# Match `$logdir/<name>.smcl` in any context (e.g., header docs)
_LOGPATH_SMCL_ANY = re.compile(
    r'\$logdir/([A-Za-z0-9_.-]+)\.smcl'
)
_LOGPATH_LOG_ANY = re.compile(
    r'\$logdir/([A-Za-z0-9_.-]+)\.log'
)
# Match `cap mkdir "$logdir"` line (we insert sibling lines after it)
_CAP_MKDIR_LOGDIR = re.compile(
    r'^(\s*)cap\s+mkdir\s+"\$logdir"\s*$', re.MULTILINE
)


def transform_log_paths(
    text: str,
    name: str,
    reldir_parts: list[str],
) -> tuple[str, int]:
    """
    Rewrite `$logdir/<name>.{smcl,log}` -> `$logdir/<reldir>/<name>.{smcl,log}`
    and add `cap mkdir "$logdir/<each-intermediate-dir>"` lines after the
    existing `cap mkdir "$logdir"`.

    Only rewrites references where the basename equals `name` (the file's
    stem), to avoid touching unrelated log paths.

    IDEMPOTENCE: the path-rewrite regexes `_LOGPATH_SMCL_ANY` and
    `_LOGPATH_LOG_ANY` use the char class `[A-Za-z0-9_.-]+` which excludes
    `/`, so after the first run `$logdir/<reldir>/<name>.smcl` no longer
    matches (the captured stem `<reldir>` lacks the literal `.smcl`
    extension immediately after).  The cap-mkdir cascade insertion guards
    against the original round-1 non-idempotence (re-matching
    `cap mkdir "$logdir"` and re-appending the cascade) by checking
    whether ALL of the expected per-component `cap mkdir "$logdir/<part>"`
    lines already exist somewhere in the file body.  If so, the insertion
    is skipped — making re-runs no-ops even when the existing cascade is
    separated from the anchor by blank lines or other content (which is
    the case for several files swept in the initial dual sweep).  This is
    conservative: we never double-insert, but on the rare edge case of
    a partial cascade pre-existing the helper will also skip insertion.
    The cost is acceptable; the load-bearing invariant is no duplicates.
    See round-2 review
    `quality_reports/reviews/2026-05-17_dual-sweep-round2_coder_review.md`
    finding M-T2 for the original non-idempotence diagnosis.

    Returns (transformed_text, n_updates).
    """
    if not reldir_parts:
        return text, 0

    nested = "/".join(reldir_parts) + "/" + name
    replacements = 0

    # Path-rewrite for `<name>.smcl` only when the stem matches `name`.
    def _replace_smcl(m: re.Match) -> str:
        nonlocal replacements
        if m.group(1) == name:
            replacements += 1
            return f"$logdir/{nested}.smcl"
        return m.group(0)

    def _replace_log(m: re.Match) -> str:
        nonlocal replacements
        if m.group(1) == name:
            replacements += 1
            return f"$logdir/{nested}.log"
        return m.group(0)

    text = _LOGPATH_SMCL_ANY.sub(_replace_smcl, text)
    text = _LOGPATH_LOG_ANY.sub(_replace_log, text)

    # Compute the expected cumulative cap-mkdir lines for this file's reldir.
    # E.g. for reldir_parts=["data_prep", "prepare"]:
    #   ['cap mkdir "$logdir/data_prep"',
    #    'cap mkdir "$logdir/data_prep/prepare"']
    expected_cumulative: list[str] = []
    cumulative = ""
    for part in reldir_parts:
        cumulative = f"{cumulative}/{part}" if cumulative else f"/{part}"
        expected_cumulative.append(f'cap mkdir "$logdir{cumulative}"')

    # IDEMPOTENCE GUARD — if EVERY expected cap-mkdir cascade line is
    # already present somewhere in the file, the sweep has already been
    # applied (or the lines pre-existed independently) and re-insertion
    # would create duplicates.  Conservative: occasionally skipping a
    # legitimate insertion (if a partial cascade somehow exists) is
    # acceptable; never double-inserting is the load-bearing invariant.
    cascade_already_present = all(line in text for line in expected_cumulative)

    if not cascade_already_present:
        # Insert sibling cap mkdir lines after the `cap mkdir "$logdir"` anchor.
        def _expand_mkdir(m: re.Match) -> str:
            nonlocal replacements
            indent = m.group(1)
            original = m.group(0)
            extra = "\n".join(f"{indent}{line}" for line in expected_cumulative)
            replacements += 1
            return original + "\n" + extra

        text = _CAP_MKDIR_LOGDIR.sub(_expand_mkdir, text, count=1)

    return text, replacements


# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------

# Top-level files that don't get the log-dir mirror treatment.
TOP_LEVEL_SKIP = {"main.do", "settings.do"}


# NOTE: this is a ONE-SHOT migration helper (intent), but BOTH T1 and T2 are
# idempotent by construction (see module docstring "ONE-SHOT INTENT,
# IDEMPOTENT BY CONSTRUCTION").  Re-running across an already-swept tree
# produces 0 changes.  If a future edit ever breaks that invariant, the
# detection is a non-empty `git diff -- do/` after a second run.
def process_file(path: Path, do_root: Path) -> tuple[int, int, int]:
    """
    Read `path`, apply both transforms and the orphan-close strip pass,
    write back if changed.

    Returns (n_t1, n_t2, n_orphans).
    """
    text = path.read_text()
    original = text

    # Transform 0 — pre-pass: handle "fake nested comment" pattern
    # (predecessor's `/*\n ... /* mini */ ... } */` blocks that the parser
    # bug was depth-flattening).  Without this, Transform 1's `/*` rewrite
    # makes inner `*/` close the outer block prematurely.
    text, n_pre = _flatten_lone_block_opens(text)

    # Transform 1 — context-aware path-glob fix
    text, n_t1 = transform_comment_globs(text)
    n_t1 += n_pre

    # Transform 1.5 — strip orphan `*/` that the predecessor parser bug had
    # been masking.  After Transform 1 removes spurious `/*` opens, these
    # orphans become real Stata syntax errors; strip them now.
    text, n_orphans = strip_orphan_block_closes(text)

    # Transform 2 — only for non-top-level .do files
    n_t2 = 0
    rel = path.relative_to(do_root)
    if rel.name not in TOP_LEVEL_SKIP and path.suffix == ".do":
        reldir_parts = list(rel.parent.parts)  # e.g., ['data_prep', 'prepare']
        if reldir_parts:
            name = path.stem
            text, n_t2 = transform_log_paths(text, name, reldir_parts)

    if text != original:
        path.write_text(text)

    return n_t1, n_t2, n_orphans


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

    total_t1 = 0
    total_t2 = 0
    total_orphans = 0
    n_files = 0
    n_changed = 0
    for path in targets:
        before = path.read_text()
        n_t1, n_t2, n_orphans = process_file(path, do_root)
        after = path.read_text()
        n_files += 1
        if before != after:
            n_changed += 1
        total_t1 += n_t1
        total_t2 += n_t2
        total_orphans += n_orphans
        if n_t1 or n_t2 or n_orphans:
            rel = path.relative_to(repo_root)
            print(
                f"{rel}: T1 {n_t1} replacements, T2 {n_t2} log-path updates, "
                f"{n_orphans} orphan */ stripped"
            )

    print()
    print(f"scanned {n_files} files; {n_changed} modified")
    print(f"Transform 1 (/* -> /<x>): {total_t1} total replacements")
    print(f"Transform 2 (log path mirror): {total_t2} total updates")
    print(f"Orphan */ stripped: {total_orphans} total")
    return 0


if __name__ == "__main__":
    sys.exit(main())
