---
name: implementation-planning-guide
description: >-
  Orchestrates the test-first implementation planning workflow. Use this skill
  whenever plan mode is active and the task involves implementing, adding, or
  modifying code. This includes feature implementation, bug fixes, refactoring,
  and any task that will result in code changes. Even if the user only says
  "plan this" or "how should we implement this", load this skill to ensure the
  full test-first planning workflow is followed.
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Guide for plan mode. This skill defines the orchestration workflow for test-first implementation planning.

## Plan Mode Workflow

### Phase 1: Initial Understanding

Launch Explore agents to understand the codebase relevant to the task.

**TBD items:** If the requirements or specifications explicitly contain the text "TBD" for any item, treat that item as non-existent — do not design or implement it. Only ask the user via `AskUserQuestion` if the TBD item is a prerequisite that cannot be deferred without blocking the overall design.

### Phase 2: Implementation Design (Plan Agent)

Launch a Plan agent to design the class/method structure. Include the following instruction in the Plan agent prompt:

> Design the class/method seams with **testability** in mind:
> - Prefer small, focused public interfaces
> - Inject dependencies via interfaces so they can be replaced with test doubles
> - Avoid hidden static/global state and `new` calls inside constructors for external dependencies
>
> **Naming:** If any class or public method name explicitly specified by the user is a poor fit for what the spec describes, propose a more appropriate alternative using `AskUserQuestion` before finalizing the design. Accept the user's final choice without further challenge.
>
> **TBD items:** Any item explicitly marked "TBD" in the requirements or spec must be excluded from the design. Skip it silently unless it is structurally required to complete the design (in which case, ask via `AskUserQuestion`).

The Plan agent output should include **only**:
- Class names and responsibilities
- Public method signatures
- Dependency interfaces (if any)
- Brief rationale for design decisions

**Do NOT include** test cases, manual tests, or any test design — those are the sole responsibility of the `test-designer` agent in Phase 2.5.

### Phase 2.5: Test Case Design (test-designer Agent)

After Phase 2, launch the `test-designer` agent using the following prompt structure:

```
## Requirements
[feature requirements]

## Task Type
[feature | bug-fix]

## Implementation Design
[class names, public method signatures, dependency interfaces, and design rationale from the Phase 2 Plan agent]

## Existing Code Context
[relevant existing code structure from Phase 1 Explore]
```

**Rules for assembling the prompt:**
- Set `Task Type` to `bug-fix` when fixing a bug; omit or set to `feature` otherwise.
- Under `Implementation Design`, include only the design output — **do NOT include any test cases or manual tests** the Plan agent may have produced. Test design is the `test-designer` agent's sole responsibility.
- **Do NOT add output format specifications.** The `test-designer` agent's output format is self-contained; caller-supplied format overrides produce non-standard output.

The `test-designer` agent returns:
- Test cases across all layers (Editor tests, Unit tests, Integration tests, Visual verification tests, Manual tests) — ready to paste into the plan file as one block
- **Testability Assessment** (`TESTABILITY: PASS`, `WARN`, or `FAIL`)

#### Handling the Testability Assessment

| Result              | Action                                                                                          |
|---------------------|-------------------------------------------------------------------------------------------------|
| `TESTABILITY: PASS` | Proceed to Phase 3 (Review)                                                                     |
| `TESTABILITY: WARN` | Proceed to Phase 3; record the Testability Issues in the plan file's "Known Trade-offs" section |
| `TESTABILITY: FAIL` | Loop back to Phase 2 (see below); maximum **1 retry**                                           |

#### Loopback to Phase 2 (on FAIL)

1. Extract the "Testability Issues" table from the `test-designer` agent output
2. Re-launch the Plan agent with:
   - The previous design output
   - The Testability Issues
   - Instruction: "Revise the design to address the Testability Issues listed below"
3. Re-run Phase 2.5 with the revised design
4. If still `FAIL` after one retry → **Abort** (see below)

#### Abort (second consecutive FAIL)

Use `AskUserQuestion` to present the user with three options:
- Proceed with the current design despite testability concerns
- Exit plan mode to revise the requirements
- Provide explicit design hints and re-run Phase 2

### Phase 3: Review

Read the critical files identified in the plan. Verify that the Plan agent's design and the `test-designer` agent's test cases are consistent with each other and with the user's intent.

### Phase 4: Write the Plan File

Assemble the plan file with the following sections:

1. **Context** — why this change is needed
2. **Implementation Design** — from Phase 2 Plan agent output
3. **Test Cases** — pasted as one block from the `test-designer` agent output (all 5 layers: Editor tests, Unit tests, Integration tests, Visual verification tests, Manual tests). **When transcribing, rewrite any mechanism-leaking descriptions to verification content only.** Test framework attributes (`[Test]` / `[UnityTest]` / `[LoadScene]`, etc.) and async/coroutine patterns are decided in the test-writing phase, not in the plan.
4. **Known Trade-offs** — from `TESTABILITY: WARN` issues (if any)
5. **Development Workflow** — the steps below, copied into the plan file

### Phase 5: Call ExitPlanMode

---

## Development Workflow

Include the following implementation steps in the plan file:

### Step 1: Skeleton (Compilable)

Create only the types and public method signatures for the product code that can be compiled. It's okay even if it does not work.

### Step 2: Test First

Launch a `general-purpose` subagent. The main agent itself does **NOT** load `test-writing-guide` — the subagent does.

**Subagent prompt must include:**
- Path to the plan file (so it can read the Test Cases table)
- Whether this task is a **spec change** (and if so, the list of existing test files affected by the changed spec)
- Whether this task is a **bug fix** (so the bug-reproducing test case from Phase 2.5 must be included)
- Explicit instruction to load the `test-writing-guide` skill **before** writing or modifying any test code
- Red-phase expectation: tests must compile and run, but **must fail**

**Subagent responsibilities:**
1. Load the `test-writing-guide` skill
2. Implement test code based on the test cases in the plan file
3. If this task is a spec change, also update any existing tests that are affected by the changed spec
4. Run the added/modified tests using the `/run-tests` skill, and confirm that they **fail**
5. Commit the test changes to git
6. Return a concise summary: which test files were added/modified, and confirmation that they failed as expected

**On subagent failure:**
- If tests unexpectedly pass (no red phase):
  - For a **spec change**: assess whether the reason is legitimate (e.g., the original test code was too loose or not testing the right thing). If the reason is judged valid, proceed with the commit and note the finding in the summary. If the reason is unclear, report to the main agent without committing.
  - For a **bug-fix**: if the reproduction test (marked `(reproduction test)` in the plan) passes unexpectedly, report to the main agent without committing — this has no exception.
  - For **all other task types**: report to the main agent without committing — main agent decides next action.
- If compilation fails repeatedly, the subagent should report the blocker rather than loop indefinitely

### Step 3: Implementation

1. Implement the product code.
2. Run the tests using `/run-tests` command, and confirm that they all **pass**.
3. Commit to git.

### Step 4: Refactoring

1. Resolve diagnostics at the `warning` or higher severity level: for each modified file, run `open_file_in_editor` → `mcp__ide__getDiagnostics` → fix as a single set, one file at a time (opening all files at once exceeds the editor tab limit).
2. Re-run tests using `/run-tests` command to confirm they still pass.
3. Run the `/code-review max` skill, then apply the returned findings to fix the code. For each finding: read the flagged code, understand the issue, and make the correction.
4. Re-run tests using `/run-tests` command to confirm they still pass.
5. Reformat the modified files, using `reformat_file` tool.
6. Commit to git.
