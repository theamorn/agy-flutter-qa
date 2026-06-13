# Antigravity on the Night Shift: Automating Mobile Integration Tests and Auto-Fixing PRs

> How we let an AI coding agent close our test-coverage gap every night —
> writing the unit and widget tests our developers never have time for, keeping
> our tests green, and opening a PR before anyone gets to the office.

## 1. The Problem: Why UI Tests Are Always Skipped

Every Flutter team knows this story. During the day, developers focus on shipping features. They write unit tests for complex business logic and maybe a few widget tests for the core screens they touched. But when the sprint deadline gets tight, one critical task is always skipped: UI and integration test coverage.

It's not laziness. Business moves fast, and maintaining a perfect balance between speed and complete coverage is incredibly difficult in the real world. Writing integration tests is slow, running them is even slower, and they require setting up device simulators or physical hardware. When racing against a release window, "the happy path works on my machine" almost always wins over spending an hour writing UI test drivers.

Consequently, we end up with a lopsided codebase. Take our application, `agy_flutter`. On a typical evening, a coverage check reveals:

```
$ flutter test --coverage
$ lcov --summary coverage/lcov.info

  Lines: 38.6% (114 of 295 lines)
```

The per-file details show the real story:
```
 94.1%  lib/utils/validators.dart          ← devs tested the pure logic
 85.7%  lib/blocs/auth/auth_bloc.dart       ← and the login bloc
 72.9%  lib/screens/login_screen.dart
   ...
  4.2%  lib/screens/forgot_password_screen.dart   ← but ran out of time here
  1.8%  lib/screens/register_screen.dart
  0.0%  lib/blocs/register/register_bloc.dart      ← and never got to these
```
This leaves major user flows like registration and password recovery completely unprotected against future regressions.

---

## 2. The Solution: Enter Google Antigravity

If the code worked at the end of the day, it should still work the next morning. Since nothing changes overnight, this window is the perfect opportunity to run an AI agent to prove everything is intact and write the tests we missed.

### Why an Agent and Not Just a Script?
You might wonder: *Why do we need an autonomous agent for this? Why not just run a shell script and get a report of what is broken?*

A static script can show you a problem, but it cannot fix it. The agent runs the scripts we prepare (which keeps token costs low), but it has the intelligence to decide what action to take next and solve problems by itself. 

To keep token usage and costs fully under control, we divide the responsibilities:
- **Unit and Widget Tests (Autonomous Agent)**: The agent writes these entirely from scratch. Because unit and widget tests only need local context (a single class or file), the agent can generate them using very few tokens.
- **Integration Tests (Developer + Agent Self-Healing)**: Developers write the core integration tests because having an agent read the entire codebase to understand end-to-end user flows would consume too many tokens. However, the agent is responsible for **keeping them green**. If an integration test fails (for example, due to a missing widget key after a UI change), the agent steps in to inspect the widget tree, diagnose the failure, and add the missing keys in the UI code to fix it. This targeted self-healing keeps costs extremely cheap while preserving test reliability.

To orchestrate this, we use the **Antigravity CLI**—a keyboard-driven command-line and Terminal User Interface (TUI) harness. Because the CLI is lightweight, requires no GUI, and integrates perfectly with local shell environments, it is the perfect tool to run as a scheduled local cron job on our development machine. Here is its step-by-step workflow:

### Step 1: Pull and Branch
The agent switches to a dated QA branch so all work happens in isolation:
```bash
git fetch origin develop
git switch develop && git pull --ff-only
git switch -c "qa/auto-$(date +%Y%m%d)"
```

### Step 2: Find Today's Changes
It checks commits since the start of work hours (e.g., 6:00 AM) to target only newly modified files:
```bash
git log --since="06:00" --oneline
```

### Step 3: Measure Coverage
It runs the test suite with coverage enabled and parses the `lcov.info` report to find zero-coverage lines:
```bash
flutter analyze
flutter test --coverage
lcov --summary coverage/lcov.info
```

### Step 4: Write Tests
The agent writes targeted unit and widget tests for the uncovered code paths under two strict constraints: *never alter application source code* (except for adding necessary UI keys), and *every test must assert real behavior*—an output, an error message, or a state change—not merely execute a line to bump the coverage number.

### Step 5: Fix & Verify
To verify everything is correct—including the integration/UI tests that require a device—the agent starts the iOS simulator, runs the tests, and shuts the simulator down once complete to save resources:
```bash
# 1. Boot the iOS simulator daemon (headlessly in the background)
xcrun simctl boot "iPhone 17" || true

# (Optional) Open the simulator GUI window if running locally
open -a Simulator

# 2. Run the integration tests on the booted simulator
flutter test integration_test -d "iPhone 17"

# 3. Shut down the simulator when finished
xcrun simctl shutdown "iPhone 17"
```
If any test fails, it self-heals by analyzing error traces, adjusting the test files, and re-running this verification check until the entire suite is green.

### Step 6: Push the Branch and Open a PR
Because this runs locally on your own machine, the agent simply reuses the git and GitHub credentials you're already logged in with—there's no token juggling and no separate "bot" identity. It pushes the dated `qa/auto-*` branch to `origin` and opens a Pull Request against `develop`, so the work shows up under your name for the team to review in the morning:
```bash
# 1. Push the nightly branch to the team repo (origin)
git push origin HEAD

# 2. Open a pull request against the base develop branch
gh pr create --base develop \
  --title "Nightly QA: add missing tests ($(date +%Y-%m-%d))" \
  --body "Coverage 38.6% → 71.2% (+32.6%). Added: register_bloc, forgot_password_bloc, register_screen. All suites green."
```
> **On credentials:** because the agent runs on your machine, lean on the `gh` login and SSH key you already use day to day—don't hand an autonomous nightly job a long-lived personal access token sitting in an environment variable. If your team *requires* PRs to come from a fork, push to your fork instead (`git push fork HEAD`) and open the PR cross-repo; otherwise pushing straight to `origin` is simpler and keeps everything in one place.

### Coverage Is a Proxy, Not the Goal
A rising coverage number is easy to game. An agent can "cover" a line with a test that asserts nothing, or—worse—write a test that simply locks in whatever the code does *today*, quietly turning an existing bug into the expected behavior. Chasing the percentage alone would make the suite *look* healthier while protecting nothing.

We keep the agent honest with three rules baked into its instructions:
- **Every test must assert behavior, not just execute it.** A test with no meaningful `expect` is rejected. The agent is told to verify outputs, error messages, and state changes—never just that a widget pumps without throwing.
- **Tests describe intended behavior, not observed behavior.** The agent works from a widget's public contract (its API, labels, and validators) rather than reverse-engineering the implementation, so it can't silently bless a bug as "correct."
- **The human reviews assertions, not the percentage.** The morning PR review deliberately focuses on *what the new tests claim*—not the green checkmark. Coverage tells us where we were blind; only a human confirms the new tests point at the right behavior.

In short, coverage tells the agent *where* to look. It never decides whether a test is *good*.

### Dual-Reporting: Daily Delta & Zero-Maintenance Dashboard
To keep the team informed without adding expensive infrastructure or database overhead, we implement a two-tier reporting system:
1. **The Daily Delta (Yesterday vs. Today)**: The nightly script compares the newly generated coverage report against the baseline coverage on the `develop` branch. It formats this direct comparison (e.g., `Coverage: 38.6% → 71.2% (+32.6%)`) and includes it in the PR body and the terminal output.
2. **Zero-Maintenance History Dashboard**: The script appends the nightly results (Date, Coverage %, Tests Added, Run Time) to a lightweight local CSV file: `docs/reports/coverage_history.csv`. It then automatically updates a static markdown dashboard (`docs/reports/coverage_dashboard.md`), which parses the CSV data into a clean, readable table and progress chart. This gives the team a clear view of daily and monthly trends directly inside their repository.

### Self-Documentation: Persistent Agent Memory & Autonomous Learning
A major challenge with scheduled agent runs is statelessness. Because the execution environment resets on every run, the agent starts with no memory of yesterday's run. If it encounters a tricky testing bug or an environment quirk (such as a flaky simulator behavior or complex mock setup), it might waste time and tokens solving the exact same problem night after night.

To prevent this, we introduce **Persistent Agent Memory**:
- **The Memory File (`docs/reports/qa_agent_memory.md`)**: The repository maintains a markdown file containing general testing guidelines, standard mocking structures, and past lessons learned. The agent reads this file at the start of every run to align itself with project quirks.
- **Post-Run Self-Evaluation**: At the end of a run—especially if it had to debug a failed test—the agent writes a brief daily summary of what went wrong and how it solved it. 
- **Autonomous Learning**: The agent evaluates whether its daily summary contains valuable context for future runs. If it identifies a new rule, bug workaround, or reusable testing pattern, it **automatically updates the `qa_agent_memory.md` file**.

By checking in these updates with the pull request, the agent's long-term memory is version-controlled and persists into the next run, making it smarter, faster, and cheaper over time.

---

## 3. A Real Example: From Widget to Test

Let’s look at a real example of the Antigravity agent in action. During the day, a developer created a reusable text field widget, [app_text_field.dart](file:///Users/pikmin/Documents/agy_flutter/lib/widgets/app_text_field.dart), but shipped it without tests:

### The Dart Widget (`lib/widgets/app_text_field.dart`)
```dart
import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
```

### The AI Prompt
When the nightly QA agent runs, it finds that `app_text_field.dart` has 0% coverage. It sends the widget source code with a prompt to the Google Antigravity SDK agent:

```
Write a widget test for the AppTextField widget located in lib/widgets/app_text_field.dart. 
Ensure you cover:
1. That the label is rendered correctly.
2. That text input correctly updates the controller.
3. That the validator function is executed and displays its error message upon form validation.

Strictly write only the test file inside test/widgets/app_text_field_test.dart. 
Do not modify the application code under lib/ or change the widget's public API.
```

### The Generated Test File (`test/widgets/app_text_field_test.dart`)
Using its code writing capabilities, the agent writes this clean test:

```dart
import 'package:agy_flutter/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: Form(
            child: child,
          ),
        ),
      );

  testWidgets('renders label and updates text correctly', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(wrap(AppTextField(
      label: 'Email Address',
      controller: controller,
    )));

    // Verify label is rendered
    expect(find.text('Email Address'), findsOneWidget);

    // Enter text and verify controller is updated
    await tester.enterText(find.byType(TextFormField), 'test@example.com');
    expect(controller.text, 'test@example.com');
  });

  testWidgets('triggers validator when form is validated', (tester) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var validated = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Password',
                controller: controller,
                validator: (value) {
                  validated = true;
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  formKey.currentState?.validate();
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    ));

    // Tap submit when field is empty
    await tester.tap(find.text('Submit'));
    await tester.pump();

    // Verify validator was triggered and error message displays
    expect(validated, true);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
```

The agent runs the tests, checks that they pass, and commits the new test file.

---

## 4. Cost Tips: Keeping Token Usage Cheap

Running AI agents every night can be expensive if not managed carefully. The most effective way to control costs is by running the agent **locally on your own machine** with the Antigravity CLI:
- **Decentralized Billing**: Running locally means each developer uses their own individual API key. This naturally splits the billing across the team and prevents a single, shared organizational account from racking up high fees.
- **Immediate Kill Switch**: Running in your local terminal means you can watch the execution logs and the simulator live. If the agent gets stuck or behaves unexpectedly, you can simply press `Ctrl+C` to stop it instantly—saving thousands of wasted tokens that would otherwise run all the way to a timeout.

Here are the other core methods we use to save tokens with the Google Antigravity SDK:
- **Text-Log and Coverage Parsing**: Instead of asking the agent to look at the whole codebase or screenshots, we read the small `lcov.info` file first. We only give the agent the specific lines and files that have no coverage, making the prompt much smaller.
- **Incremental Diffing**: By running `git log --since="06:00" --oneline`, the agent knows exactly what code was changed during the day. It only writes tests for those changed files, which keeps the context size small.
- **Thinking Token Management**: You can check `thoughts_token_count` in `agent.conversation.total_usage` to see how many tokens the model uses for thinking. If it is too high, you can make the system instructions more direct to avoid spending too much money.
- **CLI Token Auditing**: The Antigravity CLI outputs total token usage metrics (including prompt, candidates, and reasoning/thinking tokens) directly to the console at the end of each session, making it easy to audit and alert on cost regressions in your terminal logs.
- **Caching Schemas and Prompts**: We use context caching for repeated code structures and test patterns. This makes sure prompt tokens are reused, making the cost much cheaper.

### Beyond Simple Scripts: Designing a True Self-Improving Loop
To build a system where the agent gets smarter over time and requires zero developer intervention except for the final merge, three advanced design choices are needed:
- **Negative Feedback Loops (Learning from Rejection)**: Before starting, the agent runs `gh pr view --json comments,reviews` to inspect comments left by humans on the previous night's PR. If developers reject a change or comment on code style, the agent appends this feedback as guidelines to its memory file, preventing it from repeating the same mistake.
- **A Test Quarantine System**: Integration tests on simulators are prone to timing or hardware-based flakiness. If a test fails and the agent cannot resolve it after three self-healing loops, it tags the test with `@Skip('quarantined due to flakiness')`, logs the issue in `qa_agent_memory.md`, and allows the rest of the PR to pass green. This prevents the agent from wasting endless tokens on environmental errors.
- **Automated Lint & Format Gates**: Developers hate sloppy code. Before committing, the agent runs `flutter format` and `flutter analyze`. If lint warnings are found, the agent reads the diagnostics, fixes its own code formatting, and re-verifies. This ensures that every nightly PR matches the team's style guide out of the box.

---

## 5. Conclusion

By offloading the repetitive, time-consuming task of writing tests to a Google Antigravity agent, our developers got their time back. Developers can focus on building features, while the agent works at night, closing coverage gaps and opening PRs that are ready to merge.

The results are clear: our coverage gaps are fixed automatically, our tests stay green, and the team starts every morning knowing that the app is healthy.

The template is ready in the repository. Configure the **Antigravity CLI** to run your local nightly workflows, execute local runs directly in your terminal, and let the agent write tests while you sleep!

---

## Try it yourself (locally)

```bash
# 1. Run unit & widget tests and see the coverage gap on your machine
flutter test --coverage && lcov --summary coverage/lcov.info

# 2. Run the full nightly workflow locally. Without the Antigravity CLI on your
#    PATH it safely dry-runs (printing the exact prompt it would send the agent);
#    with it, the agent writes the tests and the script opens the PR.
./scripts/nightly_qa.sh

# 3. Peek at the generated dashboard and the agent's memory
cat docs/reports/coverage_dashboard.md
cat docs/reports/qa_agent_memory.md

# 4. Set up a local cron job to run the agent automatically every night
crontab -e
# Add the following line to run it every night at 8 PM:
# 0 20 * * * cd /path/to/agy_flutter && ./scripts/nightly_qa.sh
```
