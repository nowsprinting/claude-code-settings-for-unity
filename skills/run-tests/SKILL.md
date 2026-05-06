---
name: run-tests
description: >-
  Provides guidelines for running Unity tests using the run_unity_tests tool.
  Make sure to use this skill whenever running, executing, or re-running tests on the Unity editor.
  This includes verifying implementations, debugging test failures, running specific test assemblies, or any task that involves the run_unity_tests tool.
  Even if the user just says "run the tests" or "check if it passes", use this skill.
---

## Run Tests

Before running tests, complete the following steps in order:

1. If the editor is in Play Mode, stop it using the `unity_play_control` tool.
2. If any code was modified, confirm compilation success using the `get_unity_compilation_result` tool before proceeding.

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
