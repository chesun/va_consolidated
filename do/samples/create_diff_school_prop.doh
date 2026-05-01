/*------------------------------------------------------------------------------
do/samples/create_diff_school_prop.doh — different-school-proportion var
================================================================================

PURPOSE
    Generate `diff_school_prop' (proportion of g11 students whose lag-N
    prior school differs from current school).  Year-conditional: uses
    L3 (3-year lag) for non-2017 cohorts; L4 (4-year lag) for 2017 cohort.

INCLUDED FROM
    `do/samples/create_va_g11_sample[_v1/_v2].doh' and
    `do/samples/create_va_g11_out_sample[_v1/_v2].doh' (Phase 2 sample
    construction).  Parent-scope dataset must already have
    `gr11_L3_diff_school_prop' and `gr11_L4_diff_school_prop' variables
    (merged in by the parent's grade-spans merge).

ROLE IN ADR-0021 SANDBOX
    Pure `gen'/`replace' on in-memory dataset; no save / export / log.

RELOCATION HISTORY (per ADR-0021, applied 2026-04-30)
    Source:      cde_va_project_fork/do_files/sbac/create_diff_school_prop.doh
    Destination: do/samples/create_diff_school_prop.doh
    Body verbatim from predecessor (no path or global references).
    Predecessor caller-update protocol: predecessor callers untouched per
    plan v3 §3.3 step 5 parenthetical (wholesale §3.5 retirement).

REFERENCES
    Plan v3 §3.3 step 2 (sample construction)
    ADR-0021 (description convention; sandbox role above)
------------------------------------------------------------------------------*/

gen diff_school_prop = gr11_L3_diff_school_prop if year!=2017
replace diff_school_prop = gr11_L4_diff_school_prop if year==2017
