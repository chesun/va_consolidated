# va_spec_fb_tab_all.do r(9) reshape — missing predicted_score filter

**Date:** 2026-06-01
**Target:** `do/share/va_spec_fb_tab_all.do` (FB reshape L189-area; spec reshape L253-area)
**Status:** Active
**Verdict:** Real CODE bug in the consumer — it never filters the exploratory `predicted_score==1` rows the producer started writing 14 months after the consumer was last touched, so `(column, fb_var)` is non-unique → `reshape long` r(9). Fixed by `keep if predicted_score==0` in both consumer blocks.

> CORRECTION: an earlier draft of this doc hypothesized a stale-cache / cross-run append. **That was wrong** — Christina noted the whole producer do-file reruns each pass, so `regsave ... replace` fires on the first write and the file cannot accumulate across runs. The real cause is within a single clean run, below.

## Error
```
log/share/va_spec_fb_tab_all.smcl:1038
reshape long entry, i(column fb_var) j(row) string
variable id does not uniquely identify the observations   r(9)
```
`tab column` in the log (post-keeper): col1=2, col2=16, col3=16, col4=8, col5=2 (Total 44) — heavy, uneven duplication.

## Root cause (evidenced)
The producer `va_{out,score}_fb_test_tab.do` writes **4 rows** per `(va_control, fb_var, sample)` tuple: `peer_controls{0,1}` × `predicted_score{0,1}` (lines 193/202/225/232). The consumer's `column` definition keys on `va_sample`, `va_control`, `peer_controls` — but **NOT `predicted_score`**. So within one column (peer fixed), each `(column, fb_var)` cell carries 2 rows — `predicted_score=0` (canonical FB test) and `predicted_score=1` (exploratory "using predicted ELA score as controls"). `reshape long entry, i(column fb_var)` then fails because `i()` is not unique.

Count check (closes exactly): col2 = sample=las, control=b, peer=0. fb_vars whose `_fb_b_samples` list includes `las` = {l,a,s,la,ls,as,las,d} = 8; × predicted_score{2} = **16** ✓ (matches the log). The `keeper` filter later trims fb_var to {l,a,s,d}, but the predicted_score×2 survives → 2 rows per (column, fb_var) → r(9).

## Why it's a real bug, not a regression or cache artifact
Git timeline (predecessor repo):
- Consumer `va_spec_fb_tab_all.do` last touched **2023-06-20** (`0f84d78`).
- predicted_score block ADDED to producer **2024-08-16 / 2024-09-03** (`114e3cb` "add VA using predicted score", `89e2e94` "code to use predicted ELA scores as controls`) — ~14 months later.

When the consumer was written, the producer emitted only `predicted_score=0` rows, so `(column, fb_var)` was unique and the reshape worked. The exploratory `predicted_score=1` variant was bolted onto the producer later, but the consumer was never updated to exclude it. The predecessor masked this (its `fb_*_all.dta` on disk predated the producer change / wasn't re-run against fresh data); the consolidated M4 rebuild ran the *current* producer → both predicted_score values present → r(9). Predecessor consumer also lacks the filter (same latent bug, never triggered there).

## Fix applied
`keep if predicted_score==0` immediately after the `use` in BOTH consumer blocks:
- FB-test block (after `use ...fb_test/fb_<outcome>_all.dta`) — fixes the L189 reshape.
- spec-test block (after `use ...spec_test/spec_<outcome>_all.dta`) — pre-empts the identical r(9) at the L253 reshape (the spec producers write predicted_score 0/1 too).

`predicted_score==0` is the canonical/paper-shipping FB & spec test (the real leave-out-variable test). `predicted_score==1` is the exploratory predicted-ELA-score-as-controls variant (producer label: "Using predicted ELA score as controls"), not paper-shipping. Balances: `/* */` 5=5, braces 17=17. mkdir detector still 0 gaps.

## Verification caveat
Scribe-only, air-gapped — cannot run locally. Reasoned from the log's `tab column` + producer/consumer/git evidence. Next Phase-6 Scribe run is the test. (This stacks on the same file's prior r(601) $tables_dir fix, ADR-0024.)
