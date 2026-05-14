# Test Helper — Quick Reference

Package: `com.nowsprinting.test-helper`

Add `TestHelper` to Assembly Definition References to use attributes and constraints.  
Add `TestHelper.RuntimeInternals` to also use `SceneManagerHelper`, `ScreenshotHelper`, and `PathHelper`.

---

## Attributes

### Scene setup

| Goal | Solution |
|------|----------|
| Load an existing scene before the test | `[LoadScene("Assets/path/to/Scene.unity")]` on the test method |
| Create a new empty scene before the test | `[CreateScene]` on the test method |
| Include a scene not in Build Settings for player builds | `[BuildScene("Assets/path/to/Scene.unity")]` on the test method |

- Paths can be relative to the test class file: `"../../Scenes/MyScene.unity"`
- `[LoadScene]` and `[CreateScene]` run after `OneTimeSetUp` and before `SetUp`
- If you need to load a scene programmatically during the test, use `SceneManagerHelper.LoadSceneAsync(path)` combined with `[BuildScene]`

### Asset loading

| Goal | Solution |
|------|----------|
| Load an asset into a field before the test | `[LoadAsset("path")]` on a private field |

Must call `LoadAssetAttribute.LoadAssets(this)` from `[OneTimeSetUp]`.

```csharp
[LoadAsset("Assets/Tests/Prefabs/Cube.prefab")]
private GameObject _prefab;

[OneTimeSetUp]
public void OneTimeSetUp() => LoadAssetAttribute.LoadAssets(this);
```

### Game View

| Goal | Solution |
|------|----------|
| Focus the Game View before the test | `[FocusGameView]` |
| Set a custom resolution | `[GameViewResolution(640, 480, "VGA")]` — wait one frame to apply if not using `[CreateScene]`/`[LoadScene]` |
| Show or hide Gizmos | `[GizmosShowOnGameView(true)]` on the test method only |

### Skip conditions

| Goal | Solution |
|------|----------|
| Skip in `-batchmode` | `[IgnoreBatchMode("reason")]` |
| Skip in Editor window mode | `[IgnoreWindowMode("reason")]` |
| Skip for older Unity versions | `[UnityVersion(newerThanOrEqual: "2022")]` |
| Skip for newer Unity versions | `[UnityVersion(olderThan: "2019.4.0f1")]` |

### Timing

| Goal | Solution |
|------|----------|
| Change `Time.timeScale` during the test | `[TimeScale(2.0f)]` on the test method only |

### Screenshots and video (Play Mode only — do NOT use in Edit Mode)

| Goal | Solution |
|------|----------|
| Take a screenshot after the test completes | `[TakeScreenshot]` on the test method |
| Take a screenshot at a specific point in the test | `await ScreenshotHelper.TakeScreenshotAsync()` |
| Record video while the test runs | `[RecordVideo]` (requires Instant Replay package) |

`[FocusGameView]` or `[GameViewResolution]` is required when running in batchmode.

**When to add `[FocusGameView]`**: Add it at class scope on any test class that includes UI-operation tests (using `GameObjectFinder`, click/drag operators, etc.) or screenshot-capture tests. This avoids batchmode edge cases and unintended GameView focus loss. Do not add it assembly-wide or on classes that test pure logic without UI interaction.

```csharp
[TestFixture]
[FocusGameView]
public class MySceneTest { ... }
```

**CI resolution**: To fix the GameView resolution in CI, pass test-helper CLI arguments in Unity's startup parameters rather than hardcoding it in test code:

```
-testHelperGameViewResolution WQVGA              # GameViewResolution enum name
-testHelperGameViewWidth 400 -testHelperGameViewHeight 240  # or explicit pixels
```

**Image-analysis screenshot tests**: Do not override the resolution — let the test run at whatever the environment provides.

```csharp
[Test]
[LoadScene(ScenePath)]
[TakeScreenshot(directory: "Logs/Screenshots/MyScene")]
public async Task MyScene_SomeState_Screenshot() { ... }
```

**Resolution as a test condition**: When the resolution itself is part of the test condition (e.g., verifying element positions at a specific viewport size), apply `[GameViewResolution]` on the test method:

```csharp
[Test]
[LoadScene(ScenePath)]
[GameViewResolution(960, 540, "540p")]
public async Task MyScene_SomeLayout_At960x540_Screenshot() { ... }
```

---

## Constraints

Add `using Is = TestHelper.Constraints.Is;` to use these alongside NUnit's `Is`.

| Goal | Constraint |
|------|------------|
| Assert a `UnityEngine.Object` was destroyed | `Assert.That(actual, Is.Destroyed)` |
| Assert it was NOT destroyed | `Assert.That(actual, Is.Not.Destroyed())` — use method form with operators |

---

## Comparers

| Goal | Comparer |
|------|----------|
| Compare two `Texture2D` perceptually using FLIP | `new FlipTexture2dEqualityComparer(meanErrorTolerance: 0.01f)` |
| Compare two strings as equivalent XML (order-insensitive, ignores comments and whitespace) | `new XmlComparer()` |

```csharp
Assert.That(actual, Is.EqualTo(expected).Using(new XmlComparer()));
```

`FlipTexture2dEqualityComparer` requires the `FlipBinding.CSharp` NuGet package and `ENABLE_FLIP_BINDING` scripting symbol.

---

## Runtime Utilities

### SceneManagerHelper

Load a scene by path (supports relative paths, works in Edit Mode, Play Mode, and on Player):

```csharp
await SceneManagerHelper.LoadSceneAsync("../../Scenes/SampleScene.unity");
```

Use with `[BuildScene]` if the scene is not in Build Settings.

### PathHelper

Create a unique temporary file path named after the running test:

```csharp
var path = PathHelper.CreateTemporaryFilePath(extension: "txt");
// → {Application.temporaryCachePath}/MyTestMethod.txt
```

Pass `namespaceToDirectory: true` to include namespace and class name in the path.
