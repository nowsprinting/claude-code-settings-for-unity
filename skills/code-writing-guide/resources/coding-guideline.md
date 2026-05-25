# Coding Guidelines

## Backward Compatibility

Do NOT maintain backward compatibility unless explicitly requested. Break things boldly — backward compatibility layers accumulate over time, increasing maintenance cost and making the codebase harder to evolve.

- Under `Assets/`: delete unused methods outright.
- Under `Packages/`: for `public` members, mark them with `[Obsolete]` first to announce deprecation before removal.

## Structure

- Editor extension code goes under the `Editor/` directory.
- Runtime code goes under the `Runtime/` directory.
- A file contains only one public class or interface.
- Namespaces must align with the directory structure relative to the `Scripts` folder.
  For example, a file at `Assets/MyGame/Scripts/Runtime/Foo/Bar.cs` should use the namespace `MyGame.Foo.Bar`.

## Naming

- Abstract class names have no prefix (e.g., `Abstract`) or suffix (e.g., `Base`); implementation classes use the abstract class name as a suffix.
  For example, when the abstract class is `Card`, implementations are `AttackCard`, `DefenseCard`, etc.
- Enum names use singular nouns in PascalCase. Bitwise enums marked with `[Flags]` use plural nouns instead.

## MonoBehaviour

- The source file name must match the MonoBehaviour class name. Internal helper classes may live in the same file, but only one MonoBehaviour per file.
- For parameters that need to be tuned in the Inspector, expose them as public properties using the `[field: SerializeField]` pattern:
    ```csharp
    [field: SerializeField]
    public int TunableParameter { get; set; } = defaultValue;
    ```
- When making a property a serialization target, apply Unity serialization-related attributes (`SerializeField`, `HideInInspector`, `Range`, `Tooltip`, `Header`, etc.) using the `field:` target so they attach to the backing field:
    ```csharp
    [field: SerializeField]
    [field: Range(0, 100)]
    public int Health { get; set; }
    ```
- Place property XML documentation comments directly above the property, not above the attribute.
- Values that need to be tuned by playing the game (e.g., bullet speed, spawn intervals) must be defined as either a `SerializeField` or a `const`.
    - For `SerializeField`, describe the purpose with `[Tooltip("...")]` so it is readable in the Inspector.
    - For `const`, describe the purpose with a code comment.

## Events

- Prefer `System.Action` / `Action<T>` over `EventHandler` for events.
- Name events with a verb phrase using a present or past participle to indicate state before or after the change (e.g., `OpeningDoor` before, `DoorOpened` after).
- The method that raises an event is prefixed with `On` (e.g., `OnOpeningDoor`, `OnDoorOpened`).
- Observer-side handler methods are named `<Subject>_<EventName>` (e.g., `GameEvents_DoorOpened`).

## Async / Cancellation

- When `await`-ing an async call inside a `try` block using a `CancellationToken` received as a parameter, re-throw `OperationCanceledException` before any general `catch` so that cancellation propagates to the caller.
    ```csharp
    private async Awaitable SomeMethodAsync(CancellationToken ct)
    {
        try
        {
            await SomethingAsync(ct);
        }
        catch (OperationCanceledException)
        {
            throw; // propagate cancellation to the caller; do not swallow
        }
        catch (Exception e)
        {
            // handle real failures
        }
    }
    ```

## IL2CPP and Reflection

- Do NOT use `System.Reflection.Emit`. It is not supported under IL2CPP.
- Methods invoked only via reflection must be annotated with `[UnityEngine.Scripting.Preserve]` so that managed code stripping does not remove them.

## XML documentation

- When implementing an interface or overriding an abstract member, use `/// <inheritdoc/>` instead of duplicating the documentation.

## "Why Not" Comments

Add a comment whenever a non-obvious implementation choice was made — especially when a natural or standard approach was tried and rejected.
The goal is to prevent future readers (human or AI) from rediscovering the same dead end.

**Triggers that require a "why not" comment:**

- A standard API or language feature is avoided because it misbehaves in a specific environment
  (e.g., `withTimeout` deadlocks on the IntelliJ platform test JVM EDT → use `java.util.Timer`)
- A less-efficient or more verbose pattern is chosen over a simpler one for correctness reasons
- A seemingly redundant guard, indirection, or workaround exists due to a framework constraint
