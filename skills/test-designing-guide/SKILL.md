---
name: test-designing-guide
description: >-
  Provides test design methodology for Unity projects. Use this skill whenever
  designing test cases from requirements or specifications, including selecting
  test techniques, deriving test cases, and formatting them. Even for small
  features, load this skill to ensure test design rigor.
user-invocable: false
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Guide for designing test cases for Unity projects.

## Inputs

This skill requires the following inputs in its prompt:

| Input                     | Required | Description                                                                                          |
|---------------------------|----------|------------------------------------------------------------------------------------------------------|
| **Requirements**          | Required | The feature requirements to test against                                                             |
| **Implementation design** | Required | Class names, public method signatures, dependency interfaces, and design rationale                   |
| **Existing code context** | Optional | File paths and class summaries of relevant existing code                                             |
| **Task type**             | Optional | `bug-fix` to trigger the Reproduction Testing Workflow (Section 3). Defaults to `feature` if omitted |

Silently ignore the following if present in the prompt:
- Test cases or manual test lists from a Plan agent — test design is this skill's sole responsibility
- Output format overrides — the output format (Section 5) is fixed and cannot be overridden by the prompt

## 1. Analyze Specifications

Read the requirements and identify testable specifications.
If the specifications are unclear, use the AskUserQuestion tool to request clarification before proceeding.
If the test target has low testability, flag it in the Testability Assessment (Section 6).

## 2. Assign Test Targets to Layers

For each test target, determine which layer it belongs to based on its nature and integration level:

1. **Editor tests** — for Editor extension code (paths containing `/Editor/`), asset file validation, and cross-asset consistency checks.
2. **Unit tests** — test runtime code whose execution is **initiated by a direct method call**. This includes tests that verify behavior driven by Unity's lifecycle (Awake, Start, Update, etc.) or UI events. Prioritize **least integrated** targets, testing them comprehensively; for highly integrated targets (where the SUT collaborates with dependent objects), keep test density low and focus on interactions between objects.
3. **Integration tests** — test targets that are a **GameObject with multiple components added via `AddComponent<T>()`**, a **prefab**, or a **scene**. Unit tests cover targets whose execution is initiated by a direct method call; integration tests cover behavior that only emerges from Unity's component wiring.
   - Add the integration test method to the test class of the **primary class** involved; OR
   - Create a new dedicated test class if there is no clear primary class (e.g., when the subject is a prefab or scene).
   - Explicitly design integration tests **before** falling back to visual verification tests or manual tests; only drop to those layers when the behavior cannot be expressed as a functional assertion.
4. **Visual verification tests** — verify that actual on-screen rendering is correct. Take screenshots in the test code, and image analysis (see Section 4). Design these **before** falling back to manual tests.
5. **Manual tests** — reserved for items that **neither automated tests nor image analysis can verify** — i.e., items requiring human sensory judgment with no objective pass/fail criterion (e.g., game feel, animation polish, audio balance). Do NOT add manual tests for scenarios already covered by integration tests or visual verification tests, even if they seem "worth confirming by eye."

**Note:** Never use Edit Mode tests for runtime code logic. Edit Mode and Play Mode test runners cannot execute simultaneously — splitting coverage for a single SUT between the two modes prevents running all tests at once. Play Mode tests can run on actual devices (player builds), which Editor tests cannot.

## 3. Select Testing Techniques

**Prefer specification-based tests over structural (implementation-coupled) tests.** Structural tests break under refactoring and lose value fast. It's fine to write a structural test temporarily when you're unsure about an implementation, but plan to delete it once specification tests cover the same behavior.

For each test target, select appropriate techniques:

- **Equivalence partitioning** — group inputs into valid/invalid partitions; one representative per partition. When an **invalid** equivalence partition exists but the spec does not define its behavior (e.g., what happens for negative input, out-of-range values, null), use the `AskUserQuestion` tool to confirm the expected behavior before deriving test cases. Do not guess or invent the behavior.
- **Boundary value analysis** — test at the edges of each equivalence partition. Over-testing boundaries inflates the number of test cases and increases maintenance cost on every spec change. Mitigate this with parameterized tests that consolidate boundary cases into a single test method. When the spec doesn't differentiate behavior near edges (e.g., display color mapping), a representative per equivalence partition is sufficient and boundary testing can be skipped entirely.
- **State transition testing** — if the target has a finite-state-machine (FSM); one test case covers only 0-switch coverage (a direct transition from state A to state B with no intermediate states in between)
- **Decision table testing** — if multiple conditions combine to produce different outcomes
- **Error guessing** — experience-based; derive cases from failure patterns common in game development. Examples to consider: rapid button mashing, simultaneous button press, input during scene transition / loading, collision tunneling, random distribution bias or PRNG sequence looping, numeric overflow, network failure. Use this to surface implementation concerns that spec-based techniques don't reach.

### Invalid partition

- **UI input validation** — test invalid inputs that a user can enter through the UI (e.g., out-of-range values in a numeric text field). These represent real failure paths at the system boundary and must be tested.
- **Dependency error returns** — whether to test error/failure paths from a dependency depends on its origin:
  - **Library or framework** (external, not owned by this project) → test it; use a stub to inject the error condition.
  - **Game's own code** (another component in this project) → skip; trust internal code correctness.
  - **Uncertain** → use `AskUserQuestion` to confirm with the user before designing test cases.

### Testing randomness (PRNG-dependent SUT)

When the SUT consumes a pseudo-random number generator (`UnityEngine.Random`, `System.Random`, etc.), choose one of these strategies based on what the spec actually pins down:

- **Stub the PRNG** — when the spec defines a deterministic mapping from random output to behavior (e.g., "≥0.5 → heads, <0.5 → tails"). Replace the PRNG with a stub that returns canned values; assert exact outcomes.
- **Range / bounds verification** — when only the output range is specified (e.g., random spawn coordinates within a region). Assert with `And`/`Range` constraints, or `Within`/custom comparer for tolerances. Combine with `Repeat` attribute so flakiness isn't masked by a single lucky run.
- **Statistical-property verification** — when the spec is about distribution shape (RPG damage variance, drop rates). Sample the SUT in a loop, compute statistics (mean, variance, histogram bucket counts), and assert on those. The `test-helper` package (`com.nowsprinting.test-helper`) provides lightweight sampling helpers; reach for `MathNet.Numerics` only when you need rigorous statistics.
- **Characteristic verification** — when the SUT generates procedural content (e.g., roguelike maze). Don't assert exact output; assert structural properties the spec requires — e.g., "the exit is reachable from the entrance via path-finding," plus any algorithm-specific invariants.

### Integration test perspectives

When the test target is a prefab, scene, or a GameObject composed of multiple components, consider the following test perspectives:

- **UI operation sequences** — click, drag, and other player operations that advance game mechanics over one or more frames
- **Multi-frame event system interactions** — behaviors triggered by Unity's event system that unfold across multiple frames
- **Scene transitions** — behaviors that span or depend on scene loading and unloading
- **UI blocking** — verify that UI elements behind a modal dialog or overlay are unreachable (blocked from interaction); conversely, verify those elements are reachable when no overlay is present
- **UI layout** — verify element bounds, overlap, and text overflow using rect-comparison assertions. Any layout bug expressible as a geometric predicate (is element within bounds? do two elements overlap? does text overflow its container?) warrants a deterministic integration test assertion. Visual verification tests are still valuable for initial implementation review, but do not rely on them **alone** for regression — image analysis is not run on every CI pass, so regression coverage requires explicit assertions

### Reproduction tests (bug-fix tasks only)

When the task type is `bug-fix`, additionally apply the following during technique selection:

- **Reproduction test** — design one test case that directly triggers the reported bug. Apply error guessing and, if the SUT has state, state transition testing to identify the minimal trigger condition. This test must fail before the fix and pass after.
- **Regression tests** — identify adjacent behavior the fix might disturb, and apply the same techniques (equivalence partitioning, boundary value analysis, etc.) to derive coverage for those areas.

### Cover and modify (refactoring tasks only)

For refactoring work, apply **cover and modify**: design regression coverage before changing the implementation. Treat every bug as an opportunity to grow the regression suite.

## 4. Create Test Cases

For each technique, derive coverage-aware test cases:

- Use the naming convention based on the layer:
  - **Editor tests / Unit tests**: `MethodName_Condition_ExpectedResult` — the test target is a method, so include the method name.
  - **Integration tests / Visual verification tests**: `Condition_ExpectedResult` — the test target is NOT a single method (it is a multi-component interaction or an on-screen rendering), so do NOT include a method name.
- Do NOT create sequential IDs in test case names
- Describe the verification content clearly
  - Verify one condition per test. **Exception**: when multiple properties of the state resulting from a transition must all be correct simultaneously, a single test may assert all of them together. In that case, list each property being verified in the Verification Content column.
  - Test concerns separately
- Describe **verification content only** — what behavior or outcome is verified, not how to write the test. Do NOT include any of the following in Verification Content:
  - Test framework attributes (`[Test]`, `[UnityTest]`, `[LoadScene]`, etc.)
  - Sync vs async / coroutine choice
  - Construction details of test inputs (e.g., how to build `PointerEventData`, how to instantiate fixtures)
  - Any other implementation/mechanism detail — those decisions belong to the test-writing phase
- **Parameterized tests** — when multiple test cases share the same expected outcome but differ only in their input arguments (e.g., boundary values or multiple representatives within the same equivalence partition), consolidate them into a single test case row.
  - Do NOT over-consolidate: keep separate rows for cases that belong to different equivalence partitions or produce different outcomes.
  - In the Verification Content column, indicate that multiple argument patterns are tested. Do NOT specify the framework mechanism (`TestCase`, `Values`, etc.) — that's a test-writing decision.
  - Example: `Add_TwoIntegers_ReturnsSum` | `加算結果が引数の和になる（複数の引数パターンを検証）`
- If a test case requires a test double, state it in the Verification Content column: e.g., `(uses spy: <TargetDependency>)`. Choose the type based on xUnit Test Patterns (xUTP) definitions:
  - **Stub** — returns canned responses to isolate the SUT from a dependency
  - **Spy** — records interactions (calls, arguments) for later verification
  - **Fake** — a simplified but working implementation of a dependency
- **Reproduction test marker** — when a test case is designed to reproduce a reported bug (see Section 3, Reproduction and regression tests), append `(reproduction test)` to the Verification Content column.
- For visual verifications (e.g., on-screen rendering, UI layout), save a screenshot during test execution and verify it via image analysis. Note this in the Verification Content column along with the specific visual aspects to verify — e.g., `(saves screenshot for image analysis: element positions within screen, no overlap between elements, correct visibility state, text/background contrast)`.
  - **NEVER create a dedicated visual verification test class** — add visual verification test methods to the *same test class* as the functional tests.
  - **Screenshot resolution**: By default, do not fix a specific resolution for screenshot tests — let them run at whatever resolution the test environment provides. Only fix a resolution when the test condition explicitly depends on it (e.g., verifying element positions at a stated viewport size).
  - **Resolution as test condition**: When a screenshot test targets a specific resolution as part of its verification (e.g., layout at 960×540), include the resolution in the `<Condition>` segment of the test method name — e.g., `At960x540_RendersVersionLabelAtBottomRight` (visual verification tests use `Condition_ExpectedResult`, with no method name). This makes each resolution a distinct, independently runnable test case.
  - **Visual aspects to verify in screenshots** — always include the following in the `(saves screenshot for image analysis: ...)` list when applicable:
    - Element positions within screen, no overlap between elements, correct visibility state
    - **Text/background contrast** — verify that text color has sufficient contrast against its background so text is clearly legible

### Example: Verification Content — Bad vs. Good

| Style | Verification Content                                                                                 |
|-------|------------------------------------------------------------------------------------------------------|
| Bad   | Call `OnBeginDrag` synchronously with `[Test]` and Assert that `CanvasGroup.blocksRaycasts == false` |
| Good  | `CanvasGroup.blocksRaycasts` is disabled when drag starts                                            |

The Bad row leaks the test-writing mechanism (attribute choice, sync invocation, exact assertion form).
The Good row states the observable behavior; the test-writing phase decides the mechanism.

## 5. Test Case Format

Output must contain the following blocks **in this order**:
1. Test Cases — one block per layer, in this order:
   - `### Editor tests`
   - `### Unit tests`
   - `### Integration tests`
   - `### Visual verification tests`
   - `### Manual tests`
2. Testability Assessment (Section 6)

> **Note:** All layers may contain `(none)` when no test cases apply to that layer.
> Do NOT write "Edit Mode" or "Play Mode" in test case output — that is a test-writing concern, not a design concern.

Structure by layer:
- **Editor tests / Unit tests**: `#### <ClassName>` → `##### <MethodName>` → Test perspectives → table
- **Integration tests / Visual verification tests**: `#### <ClassName>` → Test perspectives → table
- **Manual tests**: no class/method section; uses a table of test cases with "Test perspectives / Verification method" column instead of "Verification Content"

```markdown
### Editor tests

#### <ClassName>

##### <MethodName>

Test perspectives: <techniques selected from Section 3, e.g., equivalence partitioning, boundary value analysis>

| Test Method                 | Verification Content                       |
|-----------------------------|--------------------------------------------|
| `Method_Condition_Expected` | What is verified by this test              |

### Unit tests

#### <ClassName>

##### <MethodName>

Test perspectives: <techniques selected from Section 3>

| Test Method                 | Verification Content                       |
|-----------------------------|--------------------------------------------|
| `Method_Condition_Expected` | What is verified by this test              |
| `Method_Condition_Expected` | What is verified (uses stub: IDependency)  |

### Integration tests

#### <ClassName>

Test perspectives: <class-level testing angles, e.g., multi-frame interaction, scene transition>

| Test Method            | Verification Content                       |
|------------------------|--------------------------------------------|
| `Condition_Expected`   | What is verified by this test              |

### Visual verification tests

#### <ClassName>

Test perspectives: <class-level visual aspects to verify, e.g., layout, contrast>

| Test Method            | Verification Content                       |
|------------------------|--------------------------------------------|
| `Condition_Expected`   | What is verified (saves screenshot for image analysis: element positions, no overlap, text/background contrast) |

### Manual tests

| Test Case                   | Test perspectives / Verification method    |
|-----------------------------|--------------------------------------------|
| Brief description of item   | Testing angle and how to verify            |
```

## 6. Testability Assessment

After designing all test cases, evaluate and output a **Testability Assessment** at the end of your response.

Use one of the following labels:

| Label               | Meaning                                                                                                |
|---------------------|--------------------------------------------------------------------------------------------------------|
| `TESTABILITY: PASS` | All public methods are independently testable; test case count is realistic                            |
| `TESTABILITY: WARN` | Localized concerns (e.g., too many test doubles, large integration tests, high FSM state combinations) |
| `TESTABILITY: FAIL` | Fundamental testability issues that require design revision                                            |

**FAIL criteria** — flag FAIL if any of the following apply:

- Unit test boundaries cannot be drawn (SUT is too large)
- State is hidden and cannot be verified externally
- Combinatorial explosion: test case count grows faster than O(n) relative to the number of conditions
- Dependencies cannot be injected (static/global coupling, `new` inside constructor, etc.)

**Output format** for the assessment section:

```markdown
### Testability Assessment

TESTABILITY: PASS

```

or, for WARN/FAIL, include Testability Issues with specific problem locations and proposed remedies:

```markdown
### Testability Assessment

TESTABILITY: FAIL

#### Testability Issues

| Issue                                                  | Location             | Proposed Remedy                        |
|--------------------------------------------------------|----------------------|----------------------------------------|
| Hidden state: `_score` modified by private method only | `GameManager._score` | Expose via read-only property or event |
| Static coupling: `Random.Range` called directly        | `CardSelector.Pick`  | Inject `IRandomSource` interface       |
```
