---
name: plan-feature
description: >-
  Orchestrates the test-first implementation planning workflow for feature
  implementation and spec changes. Use this skill whenever plan mode is active
  and the task involves implementing or adding a new feature, or changing an
  existing specification. Even if the user only says "plan this" or "how should
  we implement this", load this skill to ensure the full test-first planning
  workflow is followed.
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Guide for plan mode. This skill defines the orchestration workflow for test-first implementation planning.

## Mode Check

This skill requires **plan mode**. Before doing anything else, check the current mode:

- `ExitPlanMode` is in the deferred tools list → **not in plan mode** → stop immediately and tell the user:
  > "This skill (`/plan-feature`) requires plan mode. Enter plan mode first: use `/plan` or press Shift+Tab to toggle."
- `ExitPlanMode` is NOT in the deferred tools list (i.e., directly callable) → in plan mode → proceed.

## Task Type Check

If the user's request is to investigate or fix a bug rather than implement a new feature, change a specification, or refactor, use `ExitPlanMode` immediately and guide the user to invoke the `/fix-bug` skill instead. The rest of this skill applies to feature implementation, spec changes, and refactoring only.

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

**Do NOT include** test cases, manual tests, or any test design — those are the sole responsibility of the `test-designer` agent in Phase 3.

### Phase 3: Test Case Design (test-designer Agent)

After Phase 2, launch the `test-designer` agent using the following prompt structure:

```
## Requirements
[feature requirements]

## Implementation Design
[class names, public method signatures, dependency interfaces, and design rationale from the Phase 2 Plan agent]

## Existing Code Context
[relevant existing code structure from Phase 1 Explore]
```

**Rules for assembling the prompt:**
- Under `Implementation Design`, include only the design output — **do NOT include any test cases or manual tests** the Plan agent may have produced. Test design is the `test-designer` agent's sole responsibility.
- **Do NOT add output format specifications.** The `test-designer` agent's output format is self-contained; caller-supplied format overrides produce non-standard output.

The `test-designer` agent returns:
- **Test Cases** across all layers (Editor tests, Unit tests, Integration tests, Visual verification tests, Manual tests) — ready to paste into the plan file as one block
- **Testability Assessment** (`TESTABILITY: PASS`, `WARN`, or `FAIL`)

#### Handling the Testability Assessment

| Result              | Action                                                                                          |
|---------------------|-------------------------------------------------------------------------------------------------|
| `TESTABILITY: PASS` | Proceed to Phase 4 (Review)                                                                     |
| `TESTABILITY: WARN` | Proceed to Phase 4; record the Testability Issues in the plan file's "Known Trade-offs" section |
| `TESTABILITY: FAIL` | Loop back to Phase 2 (see below); maximum **1 retry**                                           |

#### Loopback to Phase 2 (on FAIL)

1. Extract the "Testability Issues" table from the `test-designer` agent output
2. Re-launch the Plan agent with:
   - The previous design output
   - The Testability Issues
   - Instruction: "Revise the design to address the Testability Issues listed below"
3. Re-run Phase 3 with the revised design
4. If still `FAIL` after one retry → **Abort** (see below)

#### Abort (second consecutive FAIL)

Use `AskUserQuestion` to present the user with three options:
- Proceed with the current design despite testability concerns
- Exit plan mode to revise the requirements
- Provide explicit design hints and re-run Phase 2

### Phase 4: Review

Read the critical files identified in the plan. Verify that the Plan agent's design and the `test-designer` agent's test cases are consistent with each other and with the user's intent.

### Phase 5: Write the Plan File

Assemble the plan file with the following sections:

1. **Context** — why this change is needed
2. **Implementation Design** — from Phase 2 Plan agent output
3. **Test Cases** — pasted verbatim as one block from the `test-designer` agent output (all 5 layers: Editor tests, Unit tests, Integration tests, Visual verification tests, Manual tests). Do NOT rewrite, translate, or clean up the output — the `test-designer` agent already enforces the content restrictions defined in `test-designing-guide` (no framework attributes, no async/coroutine patterns, no rationale text, etc.).
4. **Known Trade-offs** — from `TESTABILITY: WARN` issues (if any)
5. **Development Workflow** — paste the **Template** from `## Development Workflow` verbatim as the body of this section in the plan file, then add any project-specific steps per `CLAUDE.md`

### Phase 6: Call ExitPlanMode

---

## Development Workflow

Paste the **Template** below verbatim as the body of the `## Development Workflow` section in the plan file. Then follow the **Agent Execution Notes** when executing each step.

### Template

```markdown
### Step 1: Skeleton (Compilable)

- [ ] Create types and public method signatures only — must compile, need not work yet

### Step 2: Test First

- [ ] Load the `test-writing-guide` skill
- [ ] Implement test code based on the Test Cases in this plan file
- [ ] If spec change: update any existing tests affected by the changed spec
- [ ] Run tests with `/run-tests` and confirm they **fail** (red phase)
- [ ] Commit test changes to git

### Step 3: Implementation

- [ ] Implement product code
- [ ] Run tests with `/run-tests` and confirm **all pass**
- [ ] Commit to git

### Step 4: Refactoring

- [ ] Detect and remove duplicate tests in added/modified test files
- [ ] Resolve diagnostics at warning or higher for each modified file (`open_file_in_editor` → `getDiagnostics` → fix, one file at a time)
- [ ] Run tests with `/run-tests` and confirm **all pass**
- [ ] Run `/code-review ${CLAUDE_EFFORT}` and apply findings (for bug findings: write a reproduction test, confirm it **fails**, then fix)
- [ ] Run tests with `/run-tests` and confirm **all pass**
- [ ] Commit to git
```

### Agent Execution Notes

#### Step 2: Test First

Launch a `general-purpose` subagent. The main agent itself does **NOT** load `test-writing-guide` — the subagent does.

**Subagent prompt must include:**
- Path to the plan file (so it can read the Test Cases table)
- Whether this task is a **spec change** (and if so, the list of existing test files affected by the changed spec)
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
  - For **all other task types**: report to the main agent without committing — main agent decides next action.
- If compilation fails repeatedly, the subagent should report the blocker rather than loop indefinitely

#### Step 4: Refactoring — Duplicate Test Check

Launch a `general-purpose` subagent to check for duplicate test cases in the test files added or modified in this iteration (plus any existing files in the same test class). Subagent instructions:
- Read all relevant test files
- Identify tests with the same condition (setup/input) **and** the same assertion (observation/expected value) — these are true duplicates
- Do **not** flag tests that share only one of the two (different condition → not a duplicate; same condition but different assertion → not a duplicate)
- Do **not** merge same-condition tests into a single multi-assert test
- Do **not** parameterize expected values
- If duplicates are found: delete the redundant one (keep the more accurately named test), then commit the removal
- Return a summary: duplicates found and removed, or "no duplicates found"
