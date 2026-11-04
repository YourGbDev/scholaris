# Semantic roles and font-reference confirmation

All 15 semantic roles match the approved mapping. Fresh execution of the actual Flutter typography tests passed all five tests; [test output](evidence/semantic-role-tests.log). The [source guard](evidence/source-guard.log) and [three guard/font-asset tests](evidence/source-guard-tests.log) also passed.

| Role | Resolved weight |
|---|---|
| display | 700 |
| screenTitle | 700 |
| sectionTitle | 600 |
| cardTitle | 600 |
| subtitle | 400 |
| body | 400 |
| bodyEmphasis | 500 |
| label | 500 |
| caption | 400 |
| button | 600 |
| navigation | 500 |
| metric | 700 |
| badge | 500 |
| input | 400 |
| placeholder | 400 |

No Geist references were found in any of the 229 app Dart files or pubspec.yaml. The production font manifest registers Inter, MaterialIcons and CupertinoIcons, with no Geist entry. Full [audit evidence](evidence/typography-audit.json) is included.

Retained Geist files on disk, the separate landing website, historical before screenshots/reports, and the guard's deliberate rejected-font test string are intentional. None selects Geist for current app-owned typography. Native SF Pro rendering and physical-device font-weight appearance remain pending; this confirms the configured semantics, not unavailable native captures.
