---
name: run-tests
description: >-
  Provides guidelines for running Unity tests using the run_unity_tests tool.
  Make sure to use this skill whenever running, executing, or re-running tests
  on Unity Editor. This includes verifying implementations, debugging test
  failures, running specific test assemblies, or any task that involves the
  run_unity_tests tool. Even if the user just says "run the tests" or "check
  if it passes", use this skill.
---

## Run Tests

Use the `run_unity_tests` tool to run the tests on the Unity editor.

## Rules for Test Failures

If the same test(s) fail on two or more consecutive runs, stop and consult the user rather than continuing to fix.

When consulting, clarify:

- Current failure status: what is failing and the likely cause
- Fix history: what was changed, how many times, and the scope of impact
- Planned approach: what options are being considered next

## Troubleshooting

When a tool fails with a connection error, it may be due to the following reasons:

- The connection may have been disconnected due to domain reloading caused by compilation, etc. Wait a moment and try again.
- Play Mode tests cannot be run if there are any compilation errors. Check for any compilation errors using the `get_unity_compilation_result` and `get_file_problems` tool.
- The test may be timing out due to a long execution time. Review the filter settings to narrow down the tests to be executed, or ask the user to extend the timeout setting.
