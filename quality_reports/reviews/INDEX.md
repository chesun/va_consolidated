# Active reviews

Index of `Active` review reports. See [`README.md`](README.md) for lifecycle conventions.

When writing a new review, consult this index first. If an `Active` entry exists for the same target, follow the supersession protocol in `README.md`.

---

- [2026-04-24_paper-map.md](2026-04-24_paper-map.md)
- [2026-04-24_primary-source-hook-fix-memo.md](2026-04-24_primary-source-hook-fix-memo.md)
- [2026-04-25_master-file-audit.md](2026-04-25_master-file-audit.md)
- [2026-04-28_data-checks-design.md](2026-04-28_data-checks-design.md)
- [2026-05-07_siblingvaregs-archive_coder_review.md](2026-05-07_siblingvaregs-archive_coder_review.md) — `do/_archive/siblingvaregs/` (Phase 1a §3.3 step 6), score 96, Active
- [2026-05-08_step-7-survey-va_coder_review.md](2026-05-08_step-7-survey-va_coder_review.md) — Phase 1a §3.3 step 7 (9 Survey VA files + main.do Phase 5 wiring), round 1 75/100 BLOCK → round 2 94/100 PASS, Active
- [2026-05-08_step-8-alpha-archive_coder_review.md](2026-05-08_step-8-alpha-archive_coder_review.md) — Phase 1a §3.3 step 8 (`alpha.do` single-file archive + README + main.do flag-comment update; commit `8fe1f28`), score 97, Active
- [2026-05-08_step-9-batch-9a_coder_review.md](2026-05-08_step-9-batch-9a_coder_review.md) — Phase 1a §3.3 step 9 batch 9a (2 ACS census-tract files + main.do Phase 1 wiring; commit `4a88874`), score 95, Active
- [2026-05-08_step-9-batch-9b_coder_review.md](2026-05-08_step-9-batch-9b_coder_review.md) — Phase 1a §3.3 step 9 batch 9b (11 schl_chars files + main.do Phase 1 wiring; commit `40cb161`), score 92, Active
- [2026-05-08_step-9-batch-9c_coder_review.md](2026-05-08_step-9-batch-9c_coder_review.md) — Phase 1a §3.3 step 9 batch 9c (5 k12_postsec_distance files + main.do Phase 1 wiring; commit `4403758`), score 84, Active
- [2026-05-08_step-9-batch-9d_coder_review.md](2026-05-08_step-9-batch-9d_coder_review.md) — Phase 1a §3.3 step 9 batch 9d (4 caschls/prepare files + settings.do LEGACY-globals delta + main.do Phase 1 wiring; round 1 commit `677033f` 67/100 BLOCK → round 2 commit `c35e22a` 87/100 PASS), Active
- [2026-05-08_step-9-batch-9e_coder_review.md](2026-05-08_step-9-batch-9e_coder_review.md) — Phase 1a §3.3 step 9 batch 9e (10 caschls/qoiclean files + main.do Phase 1 wiring; commit `0034ae2`), score 95, Active
- [2026-05-08_step-9-batch-9fg_coder_review.md](2026-05-08_step-9-batch-9fg_coder_review.md) — Phase 1a §3.3 step 9 batches 9f+9g EXTENSION (4 responserate + 5 poolingdata files + main.do Phase 1 wiring; commits `87856ba` 9g + `cf9cb10` 9f; STEP 9 COMPLETE — 41 files total), score 93, Active
- [2026-05-08_step-10-batch-10a_coder_review.md](2026-05-08_step-10-batch-10a_coder_review.md) — Phase 1a §3.3 step 10 batch 10a (10 cde/share/ paper producers + main.do Phase 6 wiring; round 1 commit `4477b6d` 71/100 BLOCK → round 2 commit `ef6006c` 88/100 PASS), Active
- [2026-05-08_step-10-batches-10bc_coder_review.md](2026-05-08_step-10-batches-10bc_coder_review.md) — Phase 1a §3.3 step 10 batches 10b+10c JOINT (4 caschls demographics + 7 caschls misc files + main.do Phase 5+6 wiring + settings.do `$cstdtadir` add; commits `65aae2d` 10b + `bc17fbf` 10c + round-2 fixes `3d8874d`), round 1 78/100 BLOCK → round 2 82/100 PASS (STEP 10 COMPLETE), Active
- [2026-05-08_step-11-deferred-resolved_coder_review.md](2026-05-08_step-11-deferred-resolved_coder_review.md) — Phase 1a §3.3 step 11 deferred-files resolution (commit `6791dec`; 2 active relocations `do/survey_va/{allsvymerge,testscore}.do` + 1 archive `do/_archive/exploratory/allsvyfactor.do` + 4 cross-step Step 7 chain fixes + main.do Phase 5 wiring + COMPLETE marker), score 96, Active. **Phase 1a §3.3 FULLY COMPLETE = 148 files across 11 steps.**
- [2026-05-16_pre-flight-A_main-settings_coder_review.md](2026-05-16_pre-flight-A_main-settings_coder_review.md) — Pre-flight audit Partition A (do/main.do + do/settings.do + cross-tree ADR-0021 sandbox-write discipline across 94 active files; pre-Scribe golden-master), score 92/100 PASS, Active
- [2026-05-16_pre-flight-B-round2_va-samples-xwalk-check_coder_review.md](2026-05-16_pre-flight-B-round2_va-samples-xwalk-check_coder_review.md) — Pre-flight audit Partition B ROUND 2 (Critical fixes verification on do/va/helpers/macros_va.doh + 3 do/check/ files + merge_sib.doh doc header; supersedes round-1 73/100 BLOCK), score 88/100 PASS, Active. Both Critical findings CLOSED (sibling_out_xwalk binding + score_b reader path). 5 Majors+Minors deferred to Phase 1c §5.4 per orchestrator scope.
- [2026-05-16_pre-flight-D-round2_share-surveyva-explore_coder_review.md](2026-05-16_pre-flight-D-round2_share-surveyva-explore_coder_review.md) — Pre-flight audit Partition D ROUND 2 (Critical fix verification on `do/survey_va/factor.do` + `do/survey_va/pcascore.do` + `do/share/svyvaregs/allvaregs.do` — 7 analysisready reads repointed LEGACY→CANONICAL; supersedes round-1 78/100 BLOCK), score 93/100 PASS, Active. Critical C1 CLOSED. 3 Majors+Minors deferred to Phase 1c §5.4 per orchestrator scope.
- [2026-05-16_m4-infrastructure-round2_coder_review.md](2026-05-16_m4-infrastructure-round2_coder_review.md) — M4 golden-master infrastructure ROUND 2 (supersedes round-1 82/100; M3 air-gap leak de-flagged under clarified `.claude/rules/air-gapped-workflow.md` rule update; covers `do/check/m4_golden_master.do` lines 247-260 revert + rule update verification), score 85/100 PASS, Active. 4 Majors + 3 Minors remain deferred post-smoke per prior orchestrator scope.
- [2026-05-17_main-m4-flag_coder_review.md](2026-05-17_main-m4-flag_coder_review.md) — `do/main.do` M4_ACCEPTANCE_RUN master flag addition (per ADR-0018 acceptance-run; one-line operator action overrides three run-once-cached sub-toggles `do_touse_va`/`do_create_samples`/`do_va` from cached-default 0 to 1; CONVENTIONS header + display-line + two override `if`-blocks; phase-1-review.md §3 dispatch), score 94/100 PASS, Active.

---

*Reviews above the 2026-05-07 entry were written before the lifecycle convention; their headers do not yet declare a `Status` field. Treat as `Active` until backfilled or superseded.*
