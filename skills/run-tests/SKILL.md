---
name: run-tests
description: >-
  Provides guidelines for running Unity tests using the run_unity_tests tool.
  Make sure to use this skill whenever running, executing, or re-running tests on the Unity editor.
  This includes verifying implementations, debugging test failures, running specific test assemblies, or any task that involves the run_unity_tests tool.
  Even if the user just says "run the tests" or "check if it passes", use this skill.
license: Unlicense
metadata:
  author: Koji Hasegawa
---

## Run Tests

**IMPORTANT: Never call two Unity Editor tools in parallel.** `unity_play_control`, `get_unity_compilation_result`, `run_unity_tests`, and `run_method_in_unity` must be called strictly one at a time — always wait for each call to return before making the next one. Calling them concurrently causes domain-reload conflicts that result in "canceled" or "did not connect within 30 seconds" errors.

**When a Unity Editor tool returns `error` or `canceled`, wait 10 seconds before retrying.** Domain reload typically takes several seconds; immediate retry hits the same in-flight reload and fails again. Do not switch tools in the meantime (e.g., calling `unity_play_control` to verify state) — that just compounds the multiplexed calls. If the same tool returns `error` or `canceled` on two consecutive attempts (with the 10-second wait between them), stop and consult the user instead of retrying further.

Before running tests, complete the following steps in order:

1. If the editor is in Play Mode, stop it using the `unity_play_control` tool.
2. If any code was modified, confirm compilation success using the `get_unity_compilation_result` tool before proceeding.
3. To determine `assemblyNames` and `testMode` for a specific test class, run `.claude/skills/run-tests/scripts/resolve-test-target.sh <test-class-cs-path>`. The script prints `<assemblyName>\t<testMode>` (e.g. `MyGame.Tests\tPlayMode`). Skip this step when running an already-known assembly.

Then use the `run_unity_tests` tool to run the tests on the Unity editor.

Test execution can take several minutes. Do not re-run while a test is in progress — always wait for it to complete or time out. If a timeout occurs, narrow down the tests using filter settings and re-run.

## Rules for Test Failures

If the same test(s) fail on two or more consecutive runs, stop and consult the user rather than continuing to fix.

When consulting, clarify:

- Current failure status: what is failing and the likely cause
- Fix history: what was changed, how many times, and the scope of impact
- Planned approach: what options are being considered next

## Troubleshooting

Read the appropriate resource file based on the situation:

- Any Unity MCP tool (`run_unity_tests`, `unity_play_control`, `get_unity_compilation_result`) is not available or fails with a connection error: Read `.claude/skills/run-tests/resources/troubleshooting-run-unity-tests.md`
- A test fails due to an assertion, constraint, or comparer in the `TestHelper` namespace (excluding `TestHelper.UI`): Read `.claude/skills/run-tests/resources/troubleshooting-test-helper.md`
- A test fails due to an exception thrown from the `TestHelper.UI` namespace: Read `.claude/skills/run-tests/resources/troubleshooting-test-helper-ui.md`
