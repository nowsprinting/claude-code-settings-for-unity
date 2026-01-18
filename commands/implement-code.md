Please implement code that satisfies the specifications in the $ARGUMENTS file.

Follow these steps:

1. If the specification does not contain any test cases, abort running this command.
2. Create only the types and public method signatures for the product code that can be compiled. It's okay even if it does not work.
3. Implement test code based on the test cases in the documentation.
4. Run the added tests using `/run-tests` command, and confirm that they fail.
5. Commit to git.
6. Implement the product code.
7. Resolve diagnostics at the `error` severity level, using the `mcp__jetbrains__open_file_in_editor` and `mcp__jetbrains__get_current_file_errors` tools.
8. Run the tests using `/run-tests` command, and they all pass.
9. Commit to git.
10. Refactoring with DRY, KISS, and SOLID principles in mind, re-run tests using `/run-tests` command to pass.
11. Resolve diagnostics at the `suggestion` or higher severity level, re-run tests using `/run-tests` command to pass.
12. Reformat the modified files, using `mcp__jetbrains__reformat_file` tool.
13. Commit to git.
