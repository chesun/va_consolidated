#!/usr/bin/env python3
"""sweep_mkdir_coverage.py — discovery pass for the "directory not created" bug.

Stata `mkdir` has no `-p`: a write into an un-`cap mkdir`'d directory errors
(r(601)/r(693)). This static pass lists every write whose target DIRECTORY (incl.
loop-variable levels) lacks a covering `cap mkdir` in the same file.

Discovery only — never edits code. Output is a triage list for human fixing.
Final verification is the next Scribe run (static cannot see local-resolved paths).

Usage:
  python3 py/sweep_mkdir_coverage.py            # human-readable report to stdout
  python3 py/sweep_mkdir_coverage.py --check    # exit 1 if any gap (CI/precommit)

Known limits (stated, per adversarial review 2026-05-31):
  - locals that BUILD a dir path (`local s "x"; save $d/`s'/f`) are flagged
    conservatively (can't resolve statically).
  - LEGACY-path writes ($caschls_projdir/$vaprojdir) are flagged with a
    [LEGACY?] marker — fix is a path-repoint per ADR-0021, NOT an mkdir.
  - control-flow gating is not modeled; gated writes are still listed (triage).
"""
import re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
DO = ROOT / "do"

# Write verbs that take a path argument. Longest-first so multi-word verbs win.
VERBS = [
    r"export\s+excel\s+using", r"export\s+delimited\s+using",
    r"estimates\s+save", r"graph\s+export", r"regsave\s+using",
    r"esttab\s+using", r"estout\s+using", r"outsheet\s+using",
    r"outreg2\s+using", r"texsave\s+using", r"log\s+using",
    r"export\s+using", r"translate", r"save", r"saving\s*\(",
]
VERB_RE = re.compile(r"(?:^|\s)(" + "|".join(VERBS) + r")\s+", re.IGNORECASE)
# A path token: starts with $glob or "  then runs until whitespace/comma/quote/paren.
PATH_RE = re.compile(r'["\(]?\s*(\$\{?[A-Za-z_][\w}]*[^\s,"\)]*)')
MKDIR_RE = re.compile(r'mkdir\s+["\(]?\s*(\$\{?[A-Za-z_][\w}]*[^\s,"\)]*)')
LEGACY = ("caschls_projdir", "vaprojdir", "matt_files_dir", "vaprojxwalks")


def norm(p):
    p = p.strip().strip('"').rstrip("/")
    p = p.replace("${", "$").replace("}", "")  # $ {x} -> $x
    return p


def join_continuations(text):
    # Stata `///` line continuation: join so multi-line write paths stay intact.
    return re.sub(r"///[^\n]*\n", " ", text)


def strip_block_comments(text):
    # Remove /* ... */ block comments (header relocation notes mention legacy
    # paths in prose; those are not executable writes). Non-greedy, multi-line.
    return re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)


def dir_of(path):
    # Drop the final component (filename, may carry a `local' prefix — fine).
    return path.rsplit("/", 1)[0] if "/" in path else path


def levels(d):
    # Every cumulative directory level: $a/b/c -> [$a, $a/b, $a/b/c]
    parts = d.split("/")
    return ["/".join(parts[: i + 1]) for i in range(len(parts))]


# `foreach X in a b c {`  → X resolves to literal values a,b,c (only the
# in-literal form is statically resolvable; `of local`/`of varlist` are not).
FOREACH_LIT = re.compile(r"foreach\s+(\w+)\s+in\s+([^\{]+?)\s*\{")


def loop_literals(raw):
    """Map loop-var name -> set of literal values, for `foreach v in v1 v2` forms."""
    m = {}
    for name, vals in FOREACH_LIT.findall(raw):
        toks = [t for t in vals.split() if re.fullmatch(r"[\w.]+", t)]
        if toks:
            m.setdefault(name, set()).update(toks)
    return m


def covered_by_expansion(missing_dir, mkdirs, litmap):
    """True if every loop-var level in missing_dir resolves to literals whose
    fully-expanded paths are ALL in mkdirs. (Handles `foreach version in v1 v2`
    where mkdir creates .../v1/... and .../v2/... explicitly.)"""
    varnames = re.findall(r"`(\w+)'", missing_dir)
    if not varnames or any(v not in litmap for v in varnames):
        return False
    # cartesian product of all resolvable loop vars
    import itertools
    choices = [sorted(litmap[v]) for v in varnames]
    for combo in itertools.product(*choices):
        expanded = missing_dir
        for v, val in zip(varnames, combo):
            expanded = expanded.replace("`%s'" % v, val)
        if expanded not in mkdirs:
            return False
    return True


def scan(f):
    raw = f.read_text(errors="replace")
    # Blank out block-comment spans but keep line numbers aligned (replace
    # non-newline chars with spaces) so file:line in the report stays accurate.
    nocomment = re.sub(r"/\*.*?\*/",
                       lambda m: re.sub(r"[^\n]", " ", m.group(0)),
                       raw, flags=re.DOTALL)
    lines = nocomment.splitlines()
    mkdirs = {norm(m) for m in MKDIR_RE.findall(join_continuations(nocomment))}
    litmap = loop_literals(nocomment)
    gaps = []
    for i, line in enumerate(lines):
        ln = i + 1
        s = line.split("//", 1)[0]
        if s.lstrip().startswith("*") or "mkdir" in s:
            continue
        vm = VERB_RE.search(s)
        if not vm:
            continue
        # build the logical line: this line + any `///`-continued successors
        logical = s
        j = i
        while logical.rstrip().endswith("///"):
            logical = logical.rstrip()[:-3] + " " + lines[j + 1].split("//", 1)[0]
            j += 1
        pm = PATH_RE.search(logical[vm.start():])
        if not pm:
            continue
        tgt = norm(pm.group(1))
        if "/" not in tgt:
            continue
        d = dir_of(tgt)
        missing = [lv for lv in levels(d)
                   if lv not in mkdirs and not covered_by_expansion(lv, mkdirs, litmap)]
        if not missing:
            continue
        legacy = any(g in d for g in LEGACY)
        has_loopvar = "`" in d
        gaps.append((ln, vm.group(1).strip(), d, missing[-1], has_loopvar, legacy))
    return gaps


def main():
    check = "--check" in sys.argv
    files = sorted(p for p in DO.rglob("*.do") if "_archive" not in p.parts)
    files += sorted(p for p in DO.rglob("*.doh") if "_archive" not in p.parts)
    total = 0
    rows = []
    for f in files:
        for ln, verb, d, miss, lv, leg in scan(f):
            total += 1
            rel = f.relative_to(ROOT)
            tag = ("[LOOPVAR]" if lv else "[static]") + (" [LEGACY?]" if leg else "")
            rows.append(f"{rel}:{ln} | {verb} | dir={d} | missing={miss} | {tag}")
    print(f"# mkdir-coverage discovery — {total} candidate gap(s) across {len(files)} files\n")
    for r in rows:
        print(r)
    if check and total:
        sys.exit(1)


if __name__ == "__main__":
    main()
