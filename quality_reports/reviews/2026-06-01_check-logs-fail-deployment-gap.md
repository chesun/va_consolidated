# check_logs FAIL (4 files) — true-positive deployment-sync gap, not a code bug

**Date:** 2026-06-01
**Target:** Phase-7 `check_logs.do` FAIL: 4 files "ran but no log"
**Status:** Active
**Verdict:** The check is working CORRECTLY. It detected that 4 files ran but their logs aren't where the *current committed code* says they should be — because Scribe ran an **older checkout** of those 4 files (pre-commit `6043336`). Fix = deploy current code to Scribe + re-run; no code change needed.

## The 4 flagged files
```
do/sibling_xwalk/siblingmatch.do
do/sibling_xwalk/siblingpairxwalk.do
do/sibling_xwalk/uniquefamily.do
do/survey_va/indexhorseracewithdemo.do
```

## Evidence chain (each claim verified)

1. **The check correctly scoped this time:** "of 110 do files, 98 ran this run" → it no longer
   false-fails on skipped phases (the earlier 111/112 bug is gone). It flagged exactly 4.

2. **The 3 sibling files:** committed (HEAD, pushed to origin) versions log to
   `$logdir/sibling_xwalk/<name>.smcl` (verified `git show HEAD:do/sibling_xwalk/siblingmatch.do`
   → `log using "$logdir/sibling_xwalk/siblingmatch.smcl"`). But the run produced
   `log/share/siblingxwalk/<name>.smcl` (the OLD path) and **never wrote** `log/sibling_xwalk/<name>.smcl`.
   The only code that writes the old path is the **pre-ADR-0026** version of these files. So Scribe
   executed an older `siblingmatch.do` body than what's committed.

3. **indexhorseracewithdemo.do:** committed version logs to
   `$logdir/survey_va/indexhorseracewithdemo.smcl` (line 72). The master log shows it got both
   `[RUN]` and `[OK]` (line 950/955) → it *completed*. Yet that log doesn't exist; only the
   sibling file `indexhorserace.smcl` (a different, "no-withdemo" script) does. So the
   `indexhorseracewithdemo.do` that ran on Scribe had a different/older `log using` than committed.

4. **Not a marker/path bug in check_logs:** the master log's `[RUN]` markers use the NEW
   `do/sibling_xwalk/...` invocation paths (main.do is current), and the check's reldir-mirror +
   regex parse are correct (last commit `84fa249`, adversarially reviewed). The expected path
   `$logdir/sibling_xwalk/siblingmatch.smcl` is exactly right; the log is simply absent because the
   deployed file-body wrote elsewhere.

## Root cause
**Deployment lag.** main.do (uncommitted, user-deployed-live) is current on Scribe — it invokes the
files from `do/sibling_xwalk/` and writes `[RUN]` markers. But the committed `6043336` changes to the
**sibling file bodies** (the `log using` repoint to `$logdir/sibling_xwalk/`) and the
`indexhorseracewithdemo.do` log fix were not pulled to Scribe before this run. So Scribe ran:
new main.do (new invocation paths + markers) + OLD file bodies (old log paths) → logs land at the
old location → check_logs (correctly) reports them missing at the new expected location.

## Fix (no code change)
1. On Scribe: `git pull` (or sync) to bring the sibling files + indexhorseracewithdemo.do to
   `6043336`/`68d4512` (both pushed to origin/main).
2. Delete the stale `log/share/siblingxwalk/*.smcl` (old-path artifacts) to avoid confusion.
3. Re-run. The 4 files will then log to `$logdir/sibling_xwalk/` and `$logdir/survey_va/
   indexhorseracewithdemo.smcl`, and check_logs will PASS.

## Note
This is exactly the failure check_logs was designed to catch — a file that ran without producing its
expected log. Here the cause is a sync gap rather than a missing `log using`, but the check firing is
correct behavior, not a false positive.
