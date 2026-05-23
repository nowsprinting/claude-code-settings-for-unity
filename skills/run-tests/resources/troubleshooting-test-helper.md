# Troubleshooting the TestHelper package

## TakeScreenshot

### Screenshot resolution is too low for image analysis

When the GameView resolution is too low, screenshots produced by `[TakeScreenshot]` may not have enough detail for pixel-level image analysis.

Add `[GameViewResolution(960, 540, "540p")]` to the test method temporarily, re-run the tests, then remove the attribute. Do not commit resolution overrides to visual verification tests (see `test-helper.md` "Image-analysis screenshot tests").

```csharp
[Test]
[CreateScene]
[GameViewResolution(960, 540, "540p")]  // temporary — remove after analysis
[TakeScreenshot(directory: "Logs/Screenshots/MyScene")]
public async Task MyTest_Screenshot() { ... }
```

## FlipTexture2dEqualityComparer

Steps to analyze a failing assertion that uses `FlipTexture2dEqualityComparer`.

### 1. Open the diff image

On failure, a perceptual error map is automatically written to:

- Default: `Application.persistentDataPath/TestHelper/Screenshots/<TestName>.diff.png`
- Configurable via constructor arguments or the `-testHelperScreenshotDirectory` command line argument

In the FLIP error map, **brighter (white/yellow) areas indicate larger perceptual differences**.

### 2. Identify the type of difference

| Diff appearance               | Likely cause                                            |
|-------------------------------|---------------------------------------------------------|
| Broadly bright                | Rendering result differs significantly                  |
| Bright only in specific areas | Positional, color, or texture mismatch in those objects |
| Random noise-like brightness  | Anti-aliasing or floating-point precision errors        |
| Nearly black (no difference)  | `meanErrorTolerance` is set too strictly                |

### 3. Adjust meanErrorTolerance

If the diff shows only minor noise-level differences, loosen the tolerance:

```csharp
// Default is 0 (close to strict equality)
var comparer = new FlipTexture2dEqualityComparer(meanErrorTolerance: 0.01f);
```

If the assertion still fails after raising the tolerance, the rendering result itself has a problem.

### 4. Verify capture timing

Screenshots must be captured at the end of a frame. Capturing before `EndOfFrameAsync` may snapshot a pre-render state:

```csharp
await Awaitable.EndOfFrameAsync(); // Do not capture before this
var actual = ScreenCapture.CaptureScreenshotAsTexture();
```

### 5. Verify setup

If the `FlipBinding.CSharp` NuGet package (v1.0.0 or newer) is not installed, compilation will fail. When not installed via OpenUPM (UnityNuGet), the scripting define symbol `ENABLE_FLIP_BINDING` must also be added.
