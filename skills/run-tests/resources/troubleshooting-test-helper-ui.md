# Troubleshooting the UI TestHelper package

## GameObjectFinder

### Thrown TimeoutException

#### Not found

If no `GameObject` is found that matches the specified name, path, or matcher, throws a `TimeoutException` with the following message:

By name:

```
GameObject (name=Button) is not found.
```

By path:

```
GameObject (path=Path/To/Button) is not found.
```

By matcher:

```
GameObject (type=UnityEngine.UI.Button, text=START) is not found.
```

#### Not reachable

"Not reachable" means the `GameObject` is judged to be unreachable from the user's mouse or touch input. For example, `DefaultReachableStrategy` checks whether a raycast from `Camera.main` to the pivot position of the `GameObject` hits it.

If `GameObject` is found that matches the specified name, path, or matcher but not reachable, throws a `TimeoutException` with the following message:

```
GameObject (name=CloseButton) is found, but not reachable.
```

If you need more details, pass an `ILogger` instance to the constructor of `DefaultReachableStrategy`, like this:

```
var reachableStrategy = new DefaultReachableStrategy(verboseLogger: Debug.unityLogger);
var finder = new GameObjectFinder(reachableStrategy: reachableStrategy);
var result = await finder.FindByNameAsync("StartButton", reachable: true);
```

If the following message is printed, the specified object is off-screen:

```
Not reachable to CloseButton(-2278), position=(515,-32). Raycast is not hit.
```

If the following message is printed, other object is hiding the pivot position of the specified object:

```
Not reachable to BehindButton(-2324), position=(320,240). Raycast hit other objects: [BlockScreen, FrontButton]
```

Solutions will be considered in the following order of priority:

1. Adjust the pivot position of the target GameObject to be in-screen and not hidden by other objects.
2. Adjust the location where the raycast is sent using annotation components such as `ScreenOffsetAnnotation`.
3. Customize `IReachableStrategy` to make special decisions for specific GameObjects

If the cause is hidden by other objects, you can choose the following solutions:

1. If the raycast hit object is not the interactable, turn off the `raycastTarget` property.
2. Makes the raycast hit object a child of the target object, so bubbles up.

#### Not interactable

If `GameObject` is found that matches the specified name, path, or matcher but not interactable, throws a `TimeoutException` with the following message:

```
GameObject (name=Button) is found, but not interactable.
```

### Thrown MultipleGameObjectsMatchingException

If multiple `GameObjects` matching the condition are found, throw `MultipleGameObjectsMatchingException` with the following message:

```
Multiple GameObjects matching the condition (name=Button) were found.
```

### Visualizer

Using the `IVisualizer` can help you investigate why a `GameObject` cannot be found.

`DefaultDebugVisualizer` shows visual indicators when "not reachable" or "not interactable" occurs.
"not reachable" is indicated by a red eye icon with a slash, and "not interactable" is indicated by a red hand icon with a slash.

To use it, simply pass an instance to the `GameObjectFinder` constructor, like this:

```csharp
using var visualizer = new DefaultDebugVisualizer();
var finder = new GameObjectFinder(visualizer: visualizer);
```



## Operators

### Log messages

Built-in operators output log messages such as the following immediately before an operation:

```
UguiClickOperator operates to StartButton(-12345), screenshot=UguiMonkeyAgent01_0001.png
```

This log message is output just before the operator `UguiClickOperator` operates on the `GameObject` named `StartButton`.
"UguiMonkeyAgent01_0001.png" is the screenshot file name taken just before the operation.

### Visualizer

Using the `IVisualizer` can help visualize the operator's operation.

`DefaultDebugVisualizer` shows a ripple effect on the screen position of the operation.

To use it, simply pass an instance to the operator's constructor, like this:

```csharp
using var visualizer = new DefaultDebugVisualizer();
var clickOperator = new UguiClickOperator(visualizer: visualizer);
```

If you use operators with `OperatorPool`, you can inject the visualizer into the operator instance via the constructor arguments or properties when registering the operator type in the pool, like this:

```csharp
using var visualizer = new DefaultDebugVisualizer();
var operatorPool = new OperatorPool(visualizer: visualizer);
```



## Monkey

### Thrown TimeoutException

If thrown `TimeoutException` with the following message:

```
Interactive component not found in 5 seconds
```

This indicates that no `GameObject` with an interactable component appeared in the scene within specified seconds.
`GameObject` determined to be Ignored will be excluded, even if they are interactable.
`GameObject` that are not reachable by the user are excluded, even if they are interactable.

More details can be output using the verbose option (`MonkeyConfig.Verbose`).

The waiting seconds can be specified in the `MonkeyConfig.SecondsToErrorForNoInteractiveComponent`.
If you want to disable this feature, specify `0`.


### Thrown InfiniteLoopException

If thrown `InfiniteLoopException` with the following message:

```
Found loop in the operation sequence: [44030, 43938, 44010, 44030, 43938, 44010, 44030, 43938, 44010, 44030]
```

This indicates that a repeating operation is detected within the specified buffer length.
The pattern `[44030, 43938, 44010]` is looped in the above message.
Numbers are the instance ID of the operated `GameObject`.

The detectable repeating pattern max length is half the buffer length.
The buffer length can be specified in the `MonkeyConfig.BufferLengthForDetectLooping`.
If you want to disable this feature, specify `0`.


### Verbose log messages

You can output details logs when the `MonkeyConfig.Verbose` is true.

#### Lottery entries

```
Lottery entries: [
  StartButton(30502):Button:UguiClickOperator,
  StartButton(30502):Button:UguiClickAndHoldOperator,
  MenuButton(30668):Button:UguiClickOperator,
  MenuButton(30668):Button:UguiClickAndHoldOperator
]
```

Each entry format is `GameObject` name (instance ID) : `Component` type : `Operator` type.

This log message shows the lottery entries that the monkey can operate.
Entries are made by the `IsInteractable` and `Operator.CanOperate` method.
`IsIgnore` and `IsReachable` are not used at this time.

If there are zero entries, the following message is output:

```
No lottery entries.
```

#### Ignored GameObject

If the lotteries `GameObject` is ignored, the following message will be output and lottery again.

```
Ignored QuitButton(30388).
```

#### Not reachable GameObject

If the lotteries `GameObject` is not reachable by the user, the following messages will be output and lottery again.

```
Not reachable to CloseButton(-2278), position=(515,-32). Raycast is not hit.
```

Or

```
Not reachable to BehindButton(-2324), position=(320,240). Raycast hit other objects: [BlockScreen, FrontButton]
```

The former output is when the object is off-screen, and the latter is when other objects hide the pivot position.
The position to send the raycast can be arranged using annotation components such as `ScreenOffsetAnnotation`.

#### No GameObjects that are operable

If all lotteries `GameObject` are not operable, the following message is displayed.
If this condition persists, a `TimeoutException` will be thrown.

```
Lottery entries are empty or all of not reachable.
```

### Visualizer

Using the `IVisualizer` can help you investigate why a `GameObject` cannot be operated on.

`DefaultDebugVisualizer` shows visual indicators when "not reachable" or "ignored" occurs.
"not reachable" is indicated by a red eye icon with a slash, and "ignored" is indicated by a yellow lock icon.

To use it, simply set an instance to the `MonkeyConfig`, like this:

```csharp
using var visualizer = new DefaultDebugVisualizer();
var config = new MonkeyConfig()
{
    Visualizer = visualizer,                                // for use by GameObjectFinder and Monkey
    OperatorPool = new OperatorPool(visualizer: visualizer) // for use by operators
        .Register<UguiClickOperator>()
};
await Monkey.Run(config);
```