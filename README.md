# agy_flutter

A small Flutter demo app that doubles as a case study for **automated overnight
QA with an AI coding agent**.

📖 **Read the story:** [The Night Shift — An AI Agent That Writes Our Missing
Flutter Tests at 8 PM](docs/blog/nightly-qa-agent.md)

## What's in here

A realistic-but-tiny app with a deliberately *lopsided* test-coverage gap, so a
nightly agent has real work to do:

- **Auth flow** — login, register, forgot-password (in-memory `AuthService`,
  no backend, fully deterministic).
- **5-tab home shell** — tab 1 is the real main screen; tabs 2–5 are "in
  progress" placeholders.
- **State management** — `flutter_bloc` (`AuthBloc`, `RegisterBloc`,
  `ForgotPasswordBloc`).

```
lib/
  app.dart                 # root: providers + auth-gated routing
  models/                  # AppUser, AuthFailure
  services/auth_service.dart
  utils/validators.dart    # pure form validators
  blocs/                   # auth / register / forgot_password
  screens/                 # login, register, forgot_password, home + tabs
  widgets/                 # AppTextField, PrimaryButton
```

## The coverage gap (on purpose)

The team wrote ~a third of the tests — validators, the login bloc/screen, core
widgets — and left the rest for the nightly agent:

```bash
flutter test --coverage
lcov --summary coverage/lcov.info     # ~38% lines; register/forgot blocs at 0%
```

Integration tests cover only the two flows worth protecting:

```bash
flutter test integration_test -d <device>   # register + forgot_password
```

## The nightly QA agent

Runs **locally** via the Antigravity CLI, kicked off by a `cron` job at 8 PM:

```bash
0 20 * * * cd /path/to/agy_flutter && ./scripts/nightly_qa.sh
```

| File | Role |
|------|------|
| [`scripts/nightly_qa.sh`](scripts/nightly_qa.sh) | The orchestrator — pull, branch, measure coverage, invoke the agent, verify green, report, push, PR. Degrades to a safe dry-run when the remote / `gh` / Antigravity CLI aren't present. |
| [`scripts/lib/qa_common.sh`](scripts/lib/qa_common.sh) | Shared helpers: lcov coverage parsing + the agent prompt builder. |
| [`scripts/report.py`](scripts/report.py) | Appends the run to the CSV and regenerates the dashboard. |
| [`docs/reports/coverage_history.csv`](docs/reports/coverage_history.csv) | Append-only coverage log. |
| [`docs/reports/coverage_dashboard.md`](docs/reports/coverage_dashboard.md) | Generated trend table + chart. |
| [`docs/reports/qa_agent_memory.md`](docs/reports/qa_agent_memory.md) | The agent's version-controlled long-term memory. |
| [`docs/blog/nightly-qa-agent.md`](docs/blog/nightly-qa-agent.md) | The full narrative. |

Each night the agent pulls `develop`, branches, finds uncovered code, writes the
missing unit & widget tests **without refactoring app code**, keeps the
integration suite green (root-causing any failure), updates the coverage
dashboard + its own memory, and opens a PR for the morning.

## Running the app

```bash
flutter pub get
flutter run
# Demo login →  demo@agy.dev  /  password123
```
