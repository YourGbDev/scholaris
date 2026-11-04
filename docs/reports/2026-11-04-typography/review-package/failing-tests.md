# Seven failing tests — paired original/current evidence

Original source: `1804904c45594803989e5d7ec83e5b3ec09d25dd`. All 230 tracked original app files and relevant test files in the verification copy match the Git blobs after line-ending normalization. See [source proof](evidence/baseline-source-verification.json). The extra new typography file in that copy is not imported by the restored original app.

These are the seven failures from the completed migration suite (1,253 passed, 9 skipped, 7 failed). All seven also failed in the original-source verification copy. This package does not change or reclassify their assertions.

Original-source commands:

```text
flutter test --no-pub test/admin_users_tab_test.dart test/auth_boundary_test.dart test/matches_provider_test.dart test/scholarship_repository_test.dart --reporter expanded
```

## 1. AdminUsersTab creates a new user account with audit event logging

File: `test/admin_users_tab_test.dart`

Exact assertion message, identical on both sources:

```text
Expected: true
  Actual: <false>
```

[Current-source output](evidence/failure-01-current.txt), [original-source output](evidence/failure-01-original.txt).

## 2. AdminUsersTab edits role and status with audit event logging

File: `test/admin_users_tab_test.dart`

Exact assertion message, identical on both sources:

```text
Expected: true
  Actual: <false>
```

[Current-source output](evidence/failure-02-current.txt), [original-source output](evidence/failure-02-original.txt).

## 3. AdminUsersTab deactivates user with audit event logging

File: `test/admin_users_tab_test.dart`

Exact assertion message, identical on both sources:

```text
Expected: true
  Actual: <false>
```

[Current-source output](evidence/failure-03-current.txt), [original-source output](evidence/failure-03-original.txt).

## 4. AdminUsersTab deletes user with audit event logging

File: `test/admin_users_tab_test.dart`

Exact assertion message, identical on both sources:

```text
Expected: true
  Actual: <false>
```

[Current-source output](evidence/failure-04-current.txt), [original-source output](evidence/failure-04-original.txt).

## 5. auth boundary — matches isolation matches recompute for the new user and never reuse prior results

File: `test/auth_boundary_test.dart`

Exact assertion message, identical on both sources:

```text
Expected: ['sch-dost', 'sch-ched']
    Actual: MappedListIterable<Scholarship, String>:['sch-ched', 'sch-dost']
     Which: at location [0] is 'sch-ched' instead of 'sch-dost'
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\auth_boundary_test.dart 292:7                  main.<fn>.<fn>
```

[Current-source output](evidence/failure-05-current.txt), [original-source output](evidence/failure-05-original.txt).

## 6. matchesProvider returns ranked eligible scholarships for the student

File: `test/matches_provider_test.dart`

Exact assertion message, identical on both sources:

```text
Expected: ['sch-dost', 'sch-ched']
    Actual: MappedListIterable<Scholarship, String>:['sch-ched', 'sch-dost']
     Which: at location [0] is 'sch-ched' instead of 'sch-dost'
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\matches_provider_test.dart 63:5                main.<fn>
```

[Current-source output](evidence/failure-06-current.txt), [original-source output](evidence/failure-06-original.txt).

## 7. ScholarshipRepository fetchActive returns scholarships from snake_case rows

File: `test/scholarship_repository_test.dart`

Exact assertion message, identical on both sources:

```text
Expected: 'sch-dost'
    Actual: 'sch-ched'
     Which: is different.
            Expected: sch-dost
              Actual: sch-ched
                          ^
             Differ at offset 4
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\scholarship_repository_test.dart 16:7          main.<fn>.<fn>
```

[Current-source output](evidence/failure-07-current.txt), [original-source output](evidence/failure-07-original.txt).

