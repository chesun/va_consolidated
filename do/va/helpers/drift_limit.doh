/*------------------------------------------------------------------------------
do/va/helpers/drift_limit.doh — drift-limit constants for VA estimation
================================================================================

PURPOSE
    Define `score_drift_limit' and `out_drift_limit' locals consumed by the
    `vam' ado package for the score-VA and outcome-VA estimation loops.

INCLUDED FROM
    Phase 3 VA estimation scripts under `do/va/' (e.g., va_score_all.do,
    va_out_all.do, once relocated per plan v3 §3.3 step 3).  Must follow
    `include do/va/helpers/macros_va.doh' since drift-limit definitions
    depend on `test_score_min_year' / `_max_year' and `outcome_min_year' /
    `_max_year' defined in macros_va.doh L35-65.

ROLE IN ADR-0021 SANDBOX
    Pure local definitions; no reads, no writes; sandbox-trivially clean.
    No `$global' references, so no LEGACY-include macro-trace concerns.

RELOCATION HISTORY (per ADR-0005 + ADR-0021, applied 2026-04-30)
    Source:      cde_va_project_fork/do_files/sbac/drift_limit.doh
    Destination: do/va/helpers/drift_limit.doh
    Path repointing: none (no `$global' references).
    Analysis logic preserved verbatim.
    Predecessor caller-update protocol: predecessor callers untouched in
    this commit per plan v3 §3.3 step 5 parenthetical (wholesale predecessor
    retirement at Phase 1a §3.5 golden-master).

REFERENCES
    Plan v3 §3.3 step 1 (helpers/macros)
    ADR-0021 (description convention; sandbox role above)
------------------------------------------------------------------------------*/

/* set drift limit for test score VA */
local score_drift_limit = max(`test_score_max_year' - `test_score_min_year' - 1, 1)
/* set drift limit outcome VA */
local out_drift_limit = max(`outcome_max_year' - `outcome_min_year' - 1, 1)
