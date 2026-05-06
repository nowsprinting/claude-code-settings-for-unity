# Unity Test Framework Guidelines

## Structure

- Tests targeting `Editor/` code → `Tests/Editor/` (Edit Mode tests)
- Tests targeting `Runtime/` code → `Tests/Runtime/` (Play Mode tests)
- Mirror the production code's directory structure within the test directory
- Test doubles (Stub, Spy, Mock, Fake, Dummy) → `Tests/Runtime/TestDoubles/` (even for Edit Mode tests)
- Test scenes → `Tests/Scenes/`

## Naming

| Target | Convention |
|--------|-----------|
| Test assembly | `<ProductionAssembly>.Tests` |
| Test namespace | Same as the production class under test |
| Test class | `<ClassName>Test` — e.g., `CharacterControllerTest` |
| Test method | `<MethodName>_<Condition>_<ExpectedResult>` — e.g., `TakeDamage_WhenHealthIsZero_ReturnsZero` or `TakeDamage_HPが0のとき_ゼロを返す` |
| System under test | `sut` |
| Measured value | `actual` |
| Expected value | `expected` |
| Test double variable | Prefix with role: `stub`, `spy`, `mock`, `fake`, `dummy` |

- `<MethodName>` must always match the production method name exactly — never translate it.
- `<Condition>` and `<ExpectedResult>` follow the project language specified in `CLAUDE.md`. If no language is specified, confirm with the user via `AskUserQuestion` before writing tests.
- Write `<ExpectedResult>` in active voice: `ReturnsTrue`, `ThrowsArgumentException`, `ReducesHpBy3`, etc. For exceptions, include the exception type: `ThrowsArgumentException`, not just `ThrowsException`.

## Writing Tests

- `[TestFixture]` is required on every test class
- Separate Arrange / Act / Assert sections with blank lines; no AAA comments
- One `Assert.That` per test method
- Use the **constraint model only**: `Assert.That(actual, constraint)` — never use the classic model (`Assert.AreEqual`, etc.)
- Do NOT pass the `message` argument to `Assert.That`; the test name and constraint must be self-explanatory

### Constraint Tips

- For predicate assertions over a collection, prefer NUnit's strongly typed predicate constraint over LINQ:
  - Good: `Assert.That(items, Has.Some.Matches<Tool>(t => t.Name == "expected"))`
  - Avoid: `Assert.That(items.Any(t => t.Name == "expected"), Is.True)`
- Negation uses `Has.None.Matches<T>(...)`.

## No Control Flow in Tests

Never use `if`, `switch`, `for`, `foreach`, or the ternary operator in test code. Tests must be straight-line single-pass code.

## Parameterized Tests

Use `[TestCase]`, `[TestCaseSource]`, `[Values]`, `[ValueSource]` when Arrange differs but Act and Assert are the same.  
Use `[ParameterizeIgnore]` to exclude specific combinations.

## Object Creation Pattern

Use a creation method for objects needed in tests:

```csharp
private SomeClass CreateSystemUnderTest() { ... }
```

Even when holding the instance in a private field for `TearDown` cleanup, always use the return value of the creation method inside test methods.

When multiple test methods in a class share the same scene setup, create a test scene file and load it with `[LoadScene]` instead of repeating the setup in each test. Scene files are typically 1:1 with the test class, so name the file after the test class (e.g., `CharacterControllerTest.unity`). Place it under `Tests/Scenes/`.

## Unity-Specific Rules

- When a test creates a `GameObject`, add `[CreateScene]` to the test method (not required if `[LoadScene]` is already present)
- Do NOT use `LogAssert` to verify log output emitted by the production code under test; create a Spy logger that the production code writes through. This keeps tests independent of Unity's global log handler.
- `LogAssert` is acceptable only when a Spy cannot be injected — i.e., the log is emitted by `UnityEngine` itself or a third-party library outside our control. Typical uses: asserting an expected `Debug.LogError` / `LogException` from such a source, or `LogAssert.NoUnexpectedReceived()` to ensure no unexpected engine/library errors during a test.
- For tests that expect a timeout, add `[Timeout(milliseconds)]` so the test fails within a few seconds — this applies even in the RED phase

## Async Tests

- Use `async` method with `[Test]`, NOT `[UnityTest]`
- `[TestCase]` and `[TestCaseSource]` work with async test methods
- Do not use `Task.Delay` or arbitrary wait; use `await Awaitable.NextFrameAsync()` when only one frame is needed
- To assert that an async method throws, use try-catch — NOT the `Throws` constraint (Unity Test Framework limitation):

```csharp
try
{
    await Foo.Bar(-1);
    Assert.Fail("Expected exception was not thrown");
}
catch (ArgumentException expectedException)
{
    Assert.That(expectedException.Message, Is.EqualTo("Expected message"));
}
```

## Spy MonoBehaviour Conventions

When creating a Spy `MonoBehaviour` (placed under `Tests/Runtime/TestDoubles/`) to capture events such as `IPointerClickHandler.OnPointerClick`:

- Add `[AddComponentMenu("/")]` so it does not appear in the editor's Add Component picker.
- Record invocations into public properties (call count, last arguments, etc.) and let the test read them directly. Do NOT log to `Debug.Log` and assert with `LogAssert` — that couples the test to Unity's global log handler and is harder to inspect than typed state.

```csharp
[AddComponentMenu("/")]
public class SpyOnPointerClickHandler : MonoBehaviour, IPointerClickHandler
{
    public int ClickCount { get; private set; }
    public PointerEventData LastEventData { get; private set; }

    public void OnPointerClick(PointerEventData eventData)
    {
        ClickCount++;
        LastEventData = eventData;
    }
}
```

- Assert against the public properties in the test:

```csharp
Assert.That(spy.ClickCount, Is.EqualTo(1));
Assert.That(spy.LastEventData.button, Is.EqualTo(PointerEventData.InputButton.Left));
```

## Comments

Do NOT write XML documentation comments in test code.
