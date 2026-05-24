---
name: fix-bug
description: >-
  Diagnoses and fixes bugs using a test-first workflow (reproduce, diagnose, fix).
  Use this skill whenever the user reports a bug, describes unexpected behavior, or asks to
  investigate or fix a defect. Even if the user says "something's broken", "this isn't working",
  "fix this bug", or "why does X happen", load this skill to guide the full
  reproduce → diagnose → fix cycle.
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Guide for diagnosing and fixing bugs. This skill defines a test-first debugging workflow:
reproduce the bug with a failing test, diagnose the root cause, then fix it.

## Mode Check

This skill must be used **outside plan mode**. Before doing anything else, check the current mode:

- `ExitPlanMode` is NOT in the deferred tools list (i.e., directly callable) → **in plan mode** → stop immediately and tell the user:
  > "This skill (`/fix-bug`) must be used outside plan mode. Please exit plan mode first."
- `ExitPlanMode` is in the deferred tools list → not in plan mode → proceed.

## Workflow

### Phase 1: Clarify the Bug Report

Extract the following from the user's prompt:

- **Condition**: the setup or scenario that triggers the bug
- **Expected**: the expected behavior
- **Actual**: the observed behavior

If any of the three cannot be determined from the prompt, use `AskUserQuestion` to ask
the user before proceeding. All three must be known before moving to Phase 2.

Also check the relevant documentation (specs, design docs) for consistency with the
user's bug report. If the documentation and the report conflict, use `AskUserQuestion`
to clarify with the user which is correct. If the docs contain errors or are missing
relevant information, add them to the list of files to be modified in this bug fix.

### Phase 2: Find Similar Tests

Search the project's test code for existing tests closest to the bug scenario. These serve two purposes:
- Placement anchor — add the reproduction test nearby
- Style reference — follow the same test conventions

Use Explore agents to locate relevant test files and test cases.

### Phase 3: Write & Verify the Reproduction Test

Load the `test-designing-guide` skill to design the reproduction test case, then load
`test-writing-guide` to implement it.

Place the reproduction test near the similar tests found in Phase 2.

Run the test using the `/run-tests` skill and verify that it **fails** (the bug is reproduced).

#### If an existing test is incorrect

If Phase 2 reveals an existing test that is testing the wrong behavior (i.e., the test
itself is buggy), rewrite that test to correctly reproduce the bug rather than adding a
new one.

#### If the test does not fail (bug not reproduced)

- Delete the reproduction test
- Return to Phase 2 and search more broadly

If reproduction has been attempted **3 times** without success, return to **Phase 1** and
use `AskUserQuestion` to re-clarify the bug report with the user.

### Phase 4: Diagnose & Propose Fix

With the reproduction test failing, investigate the root cause:

1. Trace through the code path triggered by the reproduction test
2. Identify the specific line(s) or logic responsible for the bug
3. Formulate a fix

**Present the fix proposal to the user** via `AskUserQuestion` before making any changes.
Include:
- Root cause (one or two sentences)
- Reproduction test: file path and method name
- Proposed change: file, location, what changes
- Any trade-offs or risks

Proceed only after the user approves.

### Phase 5: Regression Test Coverage

Before applying the fix, check whether the affected area has adequate coverage for adjacent behavior:

1. Read the test files for the affected production code
2. Identify behaviors that could regress from the change but are not currently tested
3. If gaps exist, add regression tests and run them — they must **pass**
   (they test existing correct behavior, not the bug itself)

### Phase 6: Apply Fix & Verify

1. Apply the approved fix to the production code
2. Run all affected tests using `/run-tests`
3. Confirm:
   - The reproduction test now **passes** (bug is fixed)
   - All regression tests still **pass**
4. Commit to git

### Phase 7: Refactoring

1. Launch a `general-purpose` subagent to check for duplicate test cases in the test files
   added or modified in this iteration (plus any existing files in the same test class).
   Subagent instructions:
   - Read all relevant test files
   - Identify tests with the same condition (setup/input) **and** the same assertion
     (observation/expected value) — these are true duplicates
   - Do **not** flag tests that share only one of the two (different condition → not a
     duplicate; same condition but different assertion → not a duplicate)
   - Do **not** merge same-condition tests into a single multi-assert test
   - Do **not** parameterize expected values
   - If duplicates are found: delete the redundant one (keep the more accurately named
     test), then commit the removal
   - Return a summary: duplicates found and removed, or "no duplicates found"
2. Resolve diagnostics at the `warning` or higher severity level: for each modified file,
   run `open_file_in_editor` → `mcp__ide__getDiagnostics` → fix as a single set, one file
   at a time (opening all files at once exceeds the editor tab limit).
3. Re-run tests using `/run-tests` command to confirm they still pass.
4. Run the `/code-review ${CLAUDE_EFFORT}` skill, then apply the returned findings to fix
   the code. For each finding: read the flagged code, understand the issue, and make the
   correction. If the finding is a **bug**, write a reproduction test first, run it with
   `/run-tests` to confirm it **fails**, then fix the bug.
5. Re-run tests using `/run-tests` command to confirm they still pass.
6. Reformat the modified files, using `reformat_file` tool.
7. Commit to git.
