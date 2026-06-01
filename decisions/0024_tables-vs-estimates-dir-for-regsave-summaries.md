# 0024: regsave summary `.dta` tables live under `$tables_dir`; raw `.ster` estimates under `$estimates_dir`

- **Date:** 2026-06-01
- **Status:** Decided
- **Scope:** Specification
- **Data quality:** Full context
- **Refines:** #0021 (canonical-path list; this ADR disambiguates which canonical root for an ambiguous output class)

## Context

`do/share/va_spec_fb_tab_all.do` errored `r(601): file .../estimates/va_cfr_all_v1/fb_test/fb_ela_all.dta not found` (Phase 6, 2026-06-01 run, log `log/share/va_spec_fb_tab_all.smcl:992`). Root cause was a **producer/consumer path-root mismatch** for a class of intermediate file the project had never explicitly placed:

- The spec/FB-test **summary tables** `fb_<outcome>_all.dta` and `spec_<outcome>_all.dta` are `regsave`'d by four producers — `va_out_fb_test_tab.do`, `va_score_fb_test_tab.do`, `va_out_spec_test_tab.do`, `va_score_spec_test_tab.do` — all of which write to, and internally read back from, **`$tables_dir/va_cfr_all_<v>/{fb_test,spec_test}/`**.
- The lone downstream **consumer** `va_spec_fb_tab_all.do` read them from **`$estimates_dir/va_cfr_all_<v>/{fb_test,spec_test}/`** (lines 142, 203 pre-fix).

Different roots → file not found. The mismatch traces to a relocation-time note in the consumer's header that asserted *"predecessor stored intermediate regsave dtas under tables/, consolidated relocates under `$estimates_dir/`"*. That relocation was applied to the **consumer's read** but never to the **producers' writes** — and the relocation intent itself was wrong: it conflated two distinct output classes that share the `va_cfr_all_<v>/{fb_test,spec_test}/` subtree.

The predecessor had no ambiguity — both producer and consumer used `$vaprojdir/tables/...`. ADR-0021 lists both `$estimates_dir` and `$consolidated_dir/tables/` as canonical (read/write-allowed) roots but does not say *which* applies to a `regsave` summary `.dta` that happens to sit beside `.ster` estimate files in the `fb_test/`/`spec_test/` subtree. ADR-0012 settled that `_tab.do` CSVs are local-review-only but did not address the `.dta` summary root either. So no prior ADR governed this; the only "decision" was the incorrect header note.

## Decision

Within the `va_cfr_all_<v>/{vam,spec_test,fb_test,va_est_dta,reg_out_va}/` output subtree, the root is determined by **artifact class, not by sibling co-location**:

- **Raw estimation artifacts → `$estimates_dir`.** `.ster` files from `estimates save` / `est save` (and the per-cell `va_est_dta` `.dta`s that are estimation outputs, not summary tables). These are the VA-estimation chain's machine outputs.
- **regsave summary `.dta` tables → `$tables_dir`.** Any `.dta` produced by `regsave using` that accumulates summary rows for a paper/review table (`fb_<outcome>_all.dta`, `spec_<outcome>_all.dta`, and the like). These are table-class artifacts, consistent with `.claude/rules/tables.md` and the paper-shipping `tables/share/.../pub/*.tex` convention.

**Rule of thumb:** if `regsave`/`esttab`/`estout` wrote it as a results-summary `.dta`, it is a TABLE → `$tables_dir`. If `estimates save` wrote it as a fitted-model `.ster`, it is an ESTIMATE → `$estimates_dir`.

### Applied fix

The four producers already write to `$tables_dir` (correct, no change). The consumer `va_spec_fb_tab_all.do` was the outlier: its two reads (L142, L203) were repointed `$estimates_dir` → `$tables_dir`, matching the producers. The consumer's own `cap mkdir` block already prepared only `$tables_dir/...`, confirming `$tables_dir` was the originally-intended root. The misleading header note was corrected to state the rule above.

This **supersedes the file-header relocation note** in `va_spec_fb_tab_all.do` (the "relocates under `$estimates_dir/`" claim), which was the de-facto—but never ADR-ratified—convention that caused the bug. No prior *ADR* is superseded; this ADR fills a gap ADR-0021 left open and is the authoritative tie-breaker going forward.

### Why fix the consumer, not the producers

Four reasons (all verified 2026-06-01): (1) the four producers + their internal read-backs are already consistent on `$tables_dir`; (2) the consumer's own mkdir block only creates `$tables_dir/...`; (3) these are `regsave` summary tables = table-class per `tables.md`; (4) smallest, lowest-risk change (1 file, 2 lines) vs. repointing 16 producer lines. Aligning the majority to the documented-but-wrong header note would have been the larger and semantically-backwards fix.

## Consequences

**Commits us to:**

- A single documented rule for the `$tables_dir`-vs-`$estimates_dir` split (artifact class, not co-location), citable when future relocations touch the `va_cfr_all_<v>/` subtree.
- The summary `.dta` tables (`fb_*_all.dta`, `spec_*_all.dta`) permanently under `$tables_dir`.

**Rules out:**

- Reading these summary `.dta`s from `$estimates_dir` (the bug) without a superseding ADR.
- Future "relocate intermediates under `$estimates_dir`" header notes that don't distinguish `.ster` estimates from `regsave` `.dta` tables.

**Open questions / follow-ups:**

- A grep sweep (run 2026-06-01) found one related case that is **NOT a bug and is left as-is**: `va_var_explain.do` and `va_var_explain_tab.do` read `reg_va_<outcome>_va_both_all.dta` from `$estimates_dir`, but `va_var_explain.do` is **self-contained** — it both `regsave`-writes (L237/249) and reads back (L259) from `$estimates_dir`, consistently. The bug this ADR fixes was a producer/consumer **disagreement**, not the mere fact of a `.dta` under `$estimates_dir`. This ADR's rule is the convention for **new/relocated** code and the tie-breaker when producer and consumer disagree; it does **not** mandate relocating internally-consistent existing cases (doing so would be golden-master churn for no functional gain). If `va_var_explain*` are ever split across files, apply the rule then.
- Golden-master: this fix changes which path is *read*, not the data content (the producers' write path is unchanged), so it is path-correcting, not output-altering — but, like all Scribe-only fixes, confirmed only by the next full M4 run.

## Sources

- `log/share/va_spec_fb_tab_all.smcl:992` (the r(601))
- Consumer reads (pre-fix): `do/share/va_spec_fb_tab_all.do:142,203`; producers: `do/va/va_out_fb_test_tab.do:185,238`, `va_score_fb_test_tab.do:193,243`, `va_out_spec_test_tab.do:224,265`, `va_score_spec_test_tab.do:235,286`
- Predecessor (both roots = `$vaprojdir/tables/`): `cde_va_project_fork/do_files/share/va_spec_fb_tab_all.do:69,130`; `.../sbac/va_out_spec_test_tab.do:127`
- Misleading header note (now corrected): `do/share/va_spec_fb_tab_all.do:44` (pre-fix)
- Related: ADR-0021 (canonical-path list — refined here), ADR-0012 (`_tab.do` CSVs local-review-only — adjacent, not superseded), `.claude/rules/tables.md` (table-class output convention)
