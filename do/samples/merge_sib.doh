/*------------------------------------------------------------------------------
do/samples/merge_sib.doh — sibling-controls merger (in-memory fragment)
================================================================================

PURPOSE
    Pure parent-context fragment.  Merges the sibling outcomes crosswalk
    (built by `do/sibling_xwalk/siblingoutxwalk.do' per ADR-0005) onto the
    in-memory VA dataset, restricts to observations with at least one older
    sibling matched to postsecondary outcomes (`sibling_out_sample == 1'),
    and computes peer sibling-college-going controls (school-year mean
    excluding self).

INCLUDED FROM
    `do/samples/create_score_samples.do' and `do/samples/create_out_samples.do'
    (the `_s', `_ls', `_as', `_las' control combination blocks in each — 4 sites
    per parent, 8 total).
    Pure fragment — runs only inside parent's log scope; no own log.

INPUTS
    Parent-scope locals (from macros_va.doh):
      `sibling_out_xwalk' -> $datadir_clean/siblingxwalk/sibling_out_xwalk

    CANONICAL (read-only):
      `sibling_out_xwalk'.dta — sibling enrollment-outcomes crosswalk built by
                                do/sibling_xwalk/siblingoutxwalk.do (relocated
                                2026-04-30 per ADR-0005)

OUTPUTS
    None on disk.  Modifies in-memory dataset:
      - keeps obs with sibling_out_sample == 1
      - drops obs with missing has_older_sibling_enr_2year / _4year
      + has_older_sibling_enr_2year, _4year (from crosswalk)
      + peer_has_older_sibling_enr_2year, _4year (school-year peer mean)
      + touse_* updates from crosswalk

ROLE IN ADR-0021 SANDBOX
    Pure fragment; no save / export / log.  Reads `sibling_out_xwalk'
    (resolves to CANONICAL $datadir_clean/siblingxwalk/sibling_out_xwalk) via
    parent-scope local in macros_va.doh.  Sandbox-trivially clean; reader-path
    matches producer-path (do/sibling_xwalk/siblingoutxwalk.do:338).

RELOCATION HISTORY (per plan v3 §3.3 step 2 batch 2c, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/merge_sib.doh (predecessor)
    Destination: do/samples/merge_sib.doh (this file)
    Path repointing under ADR-0021 (analysis logic preserved verbatim):
      - No internal path globals or top-level $<global> references.
      - Body verbatim from predecessor.

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina (Che) Sun)
    Original predecessor file had no dated CHANGE LOG.  Authorship attributed
    to Christina via adjacent file conventions.
    2026-05-07: Relocated to consolidated repo per plan v3 §3.3 step 2 batch 2c.

REFERENCES
    Plan: quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §3.3 step 2
    ADRs: 0005 (siblingoutxwalk.do relocation — produces the crosswalk this consumes),
          0021 (sandbox; description convention)
------------------------------------------------------------------------------*/

/* do helper file to for the subroutine that merges sibling
college going conrols to existing va dataset */

//merge on to sibling outcomes crosswalk to get sibling enrollment controls
merge m:1 state_student_id using `sibling_out_xwalk', nogen keep(1 3) keepusing(touse* *sibling*)

drop if mi(has_older_sibling_enr_2year)
drop if mi(has_older_sibling_enr_4year)

//keep obs with at least one older sibling matched to postsec outcomes
keep if sibling_out_sample == 1

// create peer sibling college going controls
foreach var in has_older_sibling_enr_2year has_older_sibling_enr_4year {
  rangestat (mean) `var', interval(year, 0, 0) by(cdscode) excludeself
  rename `var'_mean peer_`var'
  label var peer_`var' "percentage of peers in same school and year with `var' equals 1"
}
