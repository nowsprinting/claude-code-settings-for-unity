---
name: test-writing-guide
description: >-
  Provides guidelines for writing test code for Unity projects.
  Make sure to use this skill whenever writing, creating, editing, or modifying test code files (files under Tests/).
  This includes implementing new tests, fixing test failures, adding test cases, or any task that results in test code changes.
  Even for small edits or one-line fixes, load this skill to ensure test conventions are followed.
user-invocable: false
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Guide for writing test code for Unity projects.

## Rules

- Before modifying any test file, check if the editor is in Play Mode. If it is, stop it using the `unity_play_control` tool first.
- Never create `.meta` files. Unity editor creates them automatically.

### Integration Tests

When implementing a test classified as an integration test, add `[Category("Integration")]` to the test method.

### UI Tests

#### Use GameObjectFinder instead of GameObject.Find

When finding a GameObject that the user interacts with, always use `GameObjectFinder` instead of `UnityEngine.GameObject.Find` or `Object.FindFirstObjectByType`.
Reasons:

- **Timing safety**: polls until the object appears, so tests pass even when GameObjects are instantiated asynchronously or on the next frame
- **Reachability and interactability**: verifies the object is actually reachable by the user and (optionally) interactable — matching real user experience
- **Blocking check**: `reachable: true` (default) naturally catches elements hidden behind a modal or overlay — which is often the bug being caught
- **Actionable failures**: throws `TimeoutException` with a clear message; `GameObject.Find` silently returns `null` and causes a confusing `NullReferenceException` later

#### Use Operators instead of direct event invocation

When reproducing user actions, always use uGUI operators (e.g., `UguiClickOperator`, `UguiTextInputOperator`) instead of directly calling button events or setting field values.
Reasons:

- **Correct event simulation**: operators go through Unity's `EventSystem` and input pipeline, exercising the same code path as a real user interaction
- **Reachability-gated**: test fails if a UI element is disabled or hidden
- **Simpler test code**: no need to look up components or call internal methods; just find the GameObject and operate it

```csharp
// NG — bypasses Unity's event pipeline
button.onClick.Invoke();
inputField.text = "12345";
scene.OnConfirmClicked();

// OK — goes through the proper UI event path
await new UguiClickOperator().OperateAsync(buttonGo);
await new UguiTextInputOperator().OperateAsync(inputFieldGo, "12345");
```

### Visual verification tests

When implementing a visual verification test (a test designed to verify on-screen rendering via screenshot and image analysis):

1. Take a screenshot using `[TakeScreenshot]` or `ScreenshotHelper.TakeScreenshotAsync()` (see `test-helper.md`).
2. Add `[Description("Verify the screenshots from the following perspectives: <verification aspects>")]` to the test method. The verification aspects are taken directly from the `(saves screenshot for image analysis: ...)` note in the test case design.
3. Add `[Category("VisualVerification")]` to the test method.
4. You can omit writing `Assert` statements.

## Resources

Read the appropriate resource file based on the situation:

- Before writing or modifying any test code file: Read `.claude/skills/test-writing-guide/resources/unity-test-framework.md`
- Before writing or modifying any test code file: Read `.claude/skills/test-writing-guide/resources/test-helper.md`
- Before writing or modifying UI tests (e.g., using `GameObjectFinder`, `Monkey`, or uGUI operators): Read `.claude/skills/test-writing-guide/resources/test-helper-ui.md`
