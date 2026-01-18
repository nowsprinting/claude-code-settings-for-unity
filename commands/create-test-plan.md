Add test cases to the current plan file.

## Process

1. **Analyze specifications**: Read the current plan file and identify testable specifications. If specifications are unclear, use the AskUserQuestionTool to ask for clarification before proceeding.

2. **Identify test targets**: Choose public classes and methods under test in order of the least integrated level (unit tests first).

3. **Select testing techniques**: For each test target, select appropriate techniques:
   - Equivalence partitioning
   - Boundary value analysis
   - State transition testing (if the test target has a finite-state-machine (FMS). One test case should cover only 0 switch coverage.)
   - Decision table testing (if applicable)

4. **Create test cases**: For each technique, derive coverage-aware test cases:
   - Use the naming convention: `MethodName_Condition_ExpectedResult`
   - Do NOT create sequential IDs in test case names
   - Describe the verification content clearly
   - Drop test cases that cannot be verified bu test code

5. **Add to plan file**: Append test cases to the "Test Cases" section of the plan file using the Edit tool.

## Test Case Format

### Test Cases

#### <ClassName>

| Test Method | Description |
|------------|-------------|
| `Method_Condition_Expected` | Brief description of what is verified |

## Notes

- Refer to `.claude/rules/02-testing.md` for project-specific testing guidelines
- Test cases should align with Unity Test Framework conventions
- Each test should verify a single behavior
- Do NOT commit to git (plan mode restriction)
