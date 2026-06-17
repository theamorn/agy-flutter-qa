# QA Agent Memory

Persistent, version-controlled memory for the nightly QA agent. The agent reads
this file at the **start** of every run to align with project conventions, and
appends a short run record + any new lesson at the **end** (see
`docs/blog/nightly-qa-agent.md` → "Persistent Agent Memory").

Keep the top sections (conventions/patterns) curated and stable. New per-run
entries are appended under "Run log" automatically.

---

## Project testing conventions

- **Frameworks:** `flutter_test` for unit/widget, `bloc_test` for blocs,
  `mocktail` for mocking, `integration_test` for UI flows.
- **Layout mirrors `lib/`:** a test for `lib/foo/bar.dart` lives at
  `test/foo/bar_test.dart`. Integration tests live in `integration_test/`.
- **Mocks:** declare `class _MockX extends Mock implements X {}` at file top.
  Register fallback values with `registerFallbackValue(...)` in `setUpAll` when
  matching custom types with `any()`.
- **Blocs:** use `blocTest<Bloc, State>(...)` with `build`, `act`, and `expect`.
  Always assert the full emitted state sequence (e.g. `[loading, success]`),
  never just that the bloc didn't throw.
- **Widgets:** wrap in `MaterialApp` + `Scaffold`; for form fields wrap in a
  `Form`. Drive inputs with `tester.enterText`, then `await tester.pump()`
  before asserting.

## Standard mock setup (copy/paste starting point)

```dart
class _MockAuthService extends Mock implements AuthService {}

void main() {
  late AuthService authService;
  setUp(() => authService = _MockAuthService());

  // when(() => authService.login(
  //       email: any(named: 'email'),
  //       password: any(named: 'password'),
  //     )).thenAnswer((_) async => user);
}
```

## Hard rules (do not violate)

1. Never change code under `lib/` except adding a widget `Key` an integration
   test needs. No logic changes to "make a test pass."
2. Every test asserts real behavior (output / error message / state change).
   No assertion-free tests just to raise the coverage number.
3. Test the public contract, not the implementation. If behavior looks wrong,
   flag it in the PR body — do not write a test that locks the bug in.
4. Run `dart format` + `flutter analyze` and fix your own lint before committing.

## Lessons learned

_(Append durable, reusable lessons here — flaky-simulator workarounds, tricky
mock setups, fixtures, timing/`pumpAndSettle` gotchas. Prune anything obsolete.)_

- Example: `forgot_password` integration test needs `pumpAndSettle()` after the
  submit tap — the success SnackBar animates in and isn't found by `pump()`.

---

## Run log

_(Auto-appended by `scripts/nightly_qa.sh` — newest at the bottom.)_

## Run 2026-06-13
- Coverage: 38.6% → 38.6% (+0.0%)
- Tests added: 0 · Run time: 1m23s

## Run 2026-06-14
- Coverage: 41.2% → 85.9% (+44.7%)
- Tests added: 4 · Run time: 2m30s
