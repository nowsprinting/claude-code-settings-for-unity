---
name: run-tests
description: Run tests on Unity editor using the run_unity_tests tool.
---

Please run the tests on Unity editor with `run_unity_tests` tool.

## Identify the Assembly

Identify the test assembly name and test mode to run.

1. First, identify the assembly definition file (.asmdef) located in the parent directory hierarchy of the run target file.
2. The assembly name can be obtained from the `name` property in the assembly definition.
3. If the `includePlatforms` in the assembly definition contains `Editor`, it is an Edit Mode test; otherwise, it is a Play Mode test.

## Specify Filters

It is recommended to specify the following filter to minimize the number of tests that are run:

### assemblyNames

The name of test assemblies to run. That is the assembly file name, without `.dll` extension.
e.g., `MyFeature.Tests`

### categoryNames

The names of a category to include in the run. Any test or fixture runs that have a category matching the string.

Specify the category name if the test class/method is decorated with the `Category` attribute.

### groupNames

Same as testNames, except that it allows for Regex. This is useful for running specific fixtures or namespaces.

Generally, specify the test class that corresponds to the modified class. The namespace is the same as the modified class, the class name with `Test` appended.

### testNames

The full name of the tests to match the filter. This is usually in the format `FixtureName.TestName`. If the test has test arguments, include them in parentheses.
e.g., `FixtureName.TestName(1,2)`

Generally, specify when only a specific test is failing, or when only a limited number of tests are affected.

## Run Tests

Use the `run_unity_tests` tool to run the tests.
Specify the test mode, test assembly name, and filters as parameters to the tool.

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
