# UI Test Helper — Quick Reference

Package: `com.nowsprinting.test-helper.ui`  
Add `TestHelper.UI` to Assembly Definition References.

---

## Find a GameObject

Use `GameObjectFinder` instead of `UnityEngine.GameObject.Find`. `GameObjectFinder` polls until the object appears (no timing issues), verifies user reachability and interactability, and fails with `TimeoutException` when the object is not found — making test failures actionable. `GameObject.Find` returns `null` silently and cannot check reachability.

```csharp
var finder = new GameObjectFinder();                    // 1 second timeout (default)
var finder = new GameObjectFinder(timeoutSeconds: 5d);  // custom timeout
```

| Goal | Method |
|------|--------|
| Find by name | `await finder.FindByNameAsync("ButtonName")` |
| Find by hierarchy path | `await finder.FindByPathAsync("/**/Dialog/**/OK")` — supports `*`, `**`, `?` glob |
| Find by component type, text, or texture | `await finder.FindByMatcherAsync(matcher)` |
| Find inside a scrollable or pageable component | `await finder.FindByMatcherAsync(matcher, paginator: paginator)` |

Common options: `reachable: true` (default), `interactable: false` (default).  
Result: use `.GameObject` on the returned value.

**UI blocking**: `reachable: true` is also useful for verifying that elements behind a modal dialog or overlay are blocked from interaction — or conversely, that they become reachable once the overlay is dismissed.

**Built-in matchers**: `ComponentMatcher`, `ButtonMatcher` (by name/path/text/texture), `ToggleMatcher` (by name/path/text)

**Built-in paginators**: `UguiScrollbarPaginator(scrollbar)`, `UguiScrollRectPaginator(scrollRect)`

**ScrollRect navigation**: pass a paginator when the target is inside a `ScrollRect`; the finder scrolls to reveal the target before the reachability check.

```csharp
var scrollViewGo = await finder.FindByNameAsync("ScrollView");
var paginator = new UguiScrollRectPaginator(scrollViewGo.GameObject.GetComponent<ScrollRect>());
var item = await finder.FindByNameAsync("ItemName", interactable: true, paginator: paginator);
```

`UguiScrollRectPaginator.ResetAsync` resets the scroll position to the top-left before searching so the scan always starts from the beginning.

---

## Operate a GameObject

```csharp
var result = await finder.FindByNameAsync("SubmitButton", interactable: true);
var op = new UguiClickOperator();
await op.OperateAsync(result.GameObject);
```

| Goal | Operator |
|------|----------|
| Click | `UguiClickOperator` |
| Click and hold | `UguiClickAndHoldOperator` |
| Double click | `UguiDoubleClickOperator` |
| Drag and drop | `UguiDragAndDropOperator` |
| Scroll wheel | `UguiScrollWheelOperator` |
| Swipe or flick | `UguiSwipeOperator` — for flick: `new UguiSwipeOperator(swipeSpeed: 2000, swipeDistance: 80f)` |
| Type text into InputField | `UguiTextInputOperator` |
| Toggle a Toggle component | `UguiToggleOperator` |

---

## Monkey Testing

Randomly operates all interactable GameObjects for a duration. Throws `TimeoutException` if no interactable objects appear, or `InfiniteLoopException` if a repeating operation pattern is detected.

```csharp
var config = new MonkeyConfig
{
    Lifetime = TimeSpan.FromMinutes(2),
    DelayMillis = 200,
    SecondsToErrorForNoInteractiveComponent = 5,
};
await Monkey.Run(config);
```

Register additional operators via `config.OperatorPool.Register<T>()`.  
Enable verbose logging with `config.Verbose = true`.

---

## Annotation Components

Attach to GameObjects in scenes to control test behavior without code changes.  
Assembly reference: `TestHelper.UI.Annotations`

| Goal | Component |
|------|-----------|
| Exclude from monkey testing | `IgnoreAnnotation` — children are also excluded |
| Mark as preferred drag-drop target | `DropAnnotation` |
| Configure character kind/length for text input | `InputFieldAnnotation` |
| Exclude from blocking reachability raycasts | `NonBlockingAnnotation` |
| Offset the raycast point from pivot (screen space) | `ScreenOffsetAnnotation` |
| Offset the raycast point from pivot (world space) | `WorldOffsetAnnotation` |
| Override the raycast point (screen space) | `ScreenPositionAnnotation` |
| Override the raycast point (world space) | `WorldPositionAnnotation` |

---

## Customization

Use these extension points when the game uses a custom UI framework or requires special behavior.

### Strategy functions / interfaces

| Extension point | Purpose | When to replace |
|-----------------|---------|-----------------|
| `IsInteractable` function | Returns whether a `Component` is interactable. Default: true for uGUI components whose `interactable` property is true. | When you have non-uGUI components that need interactability checks |
| `IIgnoreStrategy` | `IsIgnored` returns whether a `GameObject` should be skipped by Monkey. Default: true if `IgnoreAnnotation` is attached. | When you need name/path-based exclusion rules |
| `IReachableStrategy` | `IsReachable` returns whether a `GameObject` is reachable from the user. Default: raycast from `Camera.main` to pivot. | When you need a different camera or randomized raycast point |

Pass custom strategies to the `GameObjectFinder` or `MonkeyConfig` constructors:

```csharp
var reachableStrategy = new DefaultReachableStrategy(verboseLogger: Debug.unityLogger);
var finder = new GameObjectFinder(reachableStrategy: reachableStrategy);
```

### IGameObjectMatcher interface

Implement `IGameObjectMatcher` to match GameObjects by custom conditions. Pass the instance to `FindByMatcherAsync`.

### IPaginator interface

Implement `IPaginator` to support custom scrollable or pageable components. Required methods:
- `ResetAsync` — navigate to the first page
- `NextPageAsync` — navigate to the next page
- `HasNextPage` — returns whether a next page exists

Constructor requirements: first parameter must be a `MonoBehaviour` subclass (the pageable component to control).

### IOperator interface

Implement `IOperator` (or a sub-interface like `IClickOperator`) to support non-uGUI interactions. Implement:
- `CanOperate(GameObject)` — whether the operation applies to this object
- `OperateAsync(GameObject, RaycastResult, CancellationToken)` — execute the operation

Register custom operators via `MonkeyConfig.Operators` or `OperatorPool.Register<T>()`.

---

## Debugging

| Goal | Solution |
|------|----------|
| Visualize "not reachable" / "not interactable" on screen | Pass `new DefaultDebugVisualizer()` to `GameObjectFinder` constructor |
| Visualize operator tap/swipe points | Pass `new DefaultDebugVisualizer()` to operator constructor or `OperatorPool` constructor |
| Visualize during monkey testing | Set both `MonkeyConfig.Visualizer` and `MonkeyConfig.OperatorPool` with the same `DefaultDebugVisualizer` instance |
