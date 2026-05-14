# uGUI Component Defaults

Reference for creating uGUI components that match the Unity editor's **GameObject > UI (Canvas)** context menu behavior.

## Principles

- For **Button** and **Text**: use the legacy variants (`UnityEngine.UI.Button` / `UnityEngine.UI.Text`) by default. Switch to TextMesh Pro (`TMPro.TextMeshProUGUI` etc.) only when the user explicitly requests it.
- Use `ObjectFactory.CreateGameObject` / `ObjectFactory.AddComponent` (editor-only) instead of `new GameObject(...)` / `gameObject.AddComponent<T>()` so that Undo history and user Presets are applied automatically.
- `DefaultControls.Create*` methods are the public API equivalent of the context menu — use them for all standard controls.

## Public API map

| What you need | Use | Notes |
|---|---|---|
| Canvas + CanvasScaler + GraphicRaycaster | `ObjectFactory.CreateGameObject("Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster))` | `MenuOptions.CreateNewUI` is `internal` — replicate manually |
| EventSystem + input module | `ObjectFactory.CreateGameObject("EventSystem", typeof(EventSystem))` then `InputModuleComponentFactory.AddInputModule(go)` | `UnityEditor.EventSystems.InputModuleComponentFactory` is public |
| Button (Legacy) | `DefaultControls.CreateButton(resources)` | `UnityEngine.UI.DefaultControls` — public |
| Text (Legacy) | `DefaultControls.CreateText(resources)` | public |
| Image | `DefaultControls.CreateImage(resources)` | public |
| Panel | `DefaultControls.CreatePanel(resources)` | public |
| Raw Image | `DefaultControls.CreateRawImage(resources)` | public |
| ❌ context menu wrappers | `UnityEditor.UI.MenuOptions.*` | `internal class` — **cannot call directly** |

## Shared constants (from `DefaultControls.cs`)

These private constants drive the defaults for all controls.

### Sizes

| Constant | Value |
|---|---|
| `s_ThickElementSize` | `(160, 30)` |
| `s_ThinElementSize` | `(160, 20)` |
| `s_ImageElementSize` | `(100, 100)` |

### Colors

| Constant | Value |
|---|---|
| `s_DefaultSelectableColor` | `(1, 1, 1, 1)` — white, used for Image on selectable controls |
| `s_PanelColor` | `(1, 1, 1, 0.392)` — translucent white |
| `s_TextColor` | `(50/255, 50/255, 50/255, 1)` ≈ `#323232` dark gray |

### Selectable color block (applied to Button, Toggle, Slider, etc.)

Only the color block values are set; `transition` stays at its component default (`ColorTint`).

| State | Color |
|---|---|
| Normal | White `(1, 1, 1, 1)` — component's own default, not overridden |
| Highlighted | `(0.882, 0.882, 0.882, 1)` |
| Pressed | `(0.698, 0.698, 0.698, 1)` |
| Disabled | `(0.521, 0.521, 0.521, 1)` |
| Color multiplier | `1` |
| Fade duration | `0.1` |

### Sprite paths (editor-only, load with `AssetDatabase.GetBuiltinExtraResource<Sprite>(path)`)

| Key | Path |
|---|---|
| `standard` | `"UI/Skin/UISprite.psd"` |
| `background` | `"UI/Skin/Background.psd"` |
| `inputField` | `"UI/Skin/InputFieldBackground.psd"` |
| `knob` | `"UI/Skin/Knob.psd"` |
| `checkmark` | `"UI/Skin/Checkmark.psd"` |
| `dropdown` | `"UI/Skin/DropdownArrow.psd"` |
| `mask` | `"UI/Skin/UIMask.psd"` |

### Font

If the user has specified a project font (e.g. in CLAUDE.md, a task description, or earlier in the conversation), assign it to every `Text` component you create.
If no font is specified, ask the user with `AskUserQuestion` before proceeding.
Only fall back to the built-in font when the user explicitly says no custom font is needed.

```csharp
// Load in editor scripts:
var font = AssetDatabase.LoadAssetAtPath<Font>("Assets/DtD/Resources/Fonts/NotoSansJP-Regular.otf");
// Load in runtime scripts:
var font = Resources.Load<Font>("Fonts/NotoSansJP-Regular");

// Built-in fallback (Unity 6.x) — only when no project font is specified:
// Font font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
```

### FontData defaults (from `FontData.defaultFontData`)

| Property | Default | Override for Button child |
|---|---|---|
| `fontSize` | `14` | — |
| `fontStyle` | `Normal` | — |
| `lineSpacing` | `1` | — |
| `alignment` | `UpperLeft` | `MiddleCenter` |
| `horizontalOverflow` | `Wrap` | — |
| `verticalOverflow` | `Truncate` | — |
| `richText` | `true` | — |
| `bestFit` | `false` | — |
| `minSize` | `10` | — |
| `maxSize` | `40` | — |
| `alignByGeometry` | `false` | — |
| `color` | `s_TextColor` ≈ `#323232` | — |

## `DefaultControls.Resources` setup

```csharp
using UnityEditor;
using UnityEngine.UI;

var res = new DefaultControls.Resources
{
    standard   = AssetDatabase.GetBuiltinExtraResource<Sprite>("UI/Skin/UISprite.psd"),
    background = AssetDatabase.GetBuiltinExtraResource<Sprite>("UI/Skin/Background.psd"),
    inputField = AssetDatabase.GetBuiltinExtraResource<Sprite>("UI/Skin/InputFieldBackground.psd"),
    knob       = AssetDatabase.GetBuiltinExtraResource<Sprite>("UI/Skin/Knob.psd"),
    checkmark  = AssetDatabase.GetBuiltinExtraResource<Sprite>("UI/Skin/Checkmark.psd"),
    dropdown   = AssetDatabase.GetBuiltinExtraResource<Sprite>("UI/Skin/DropdownArrow.psd"),
    mask       = AssetDatabase.GetBuiltinExtraResource<Sprite>("UI/Skin/UIMask.psd"),
};
```

## Per-component defaults

### Canvas

`MenuOptions.CreateNewUI` is internal. Replicate it manually:

```csharp
var canvasGo = ObjectFactory.CreateGameObject(
    "Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
canvasGo.layer = LayerMask.NameToLayer("UI");  // "UI" layer

var canvas = canvasGo.GetComponent<Canvas>();
canvas.renderMode = RenderMode.ScreenSpaceOverlay;

// CanvasScaler and GraphicRaycaster are added but NOT configured further.
// They keep their component Reset() defaults:
//   CanvasScaler: uiScaleMode = ConstantPixelSize, scaleFactor = 1, referencePixelsPerUnit = 100
//   GraphicRaycaster: all defaults
```

**CanvasScaler: prefer `ScaleWithScreenSize`**: The Reset default (`ConstantPixelSize`) does not resize the UI when the screen resolution changes. Use `ScaleWithScreenSize` for all game scenes — this keeps the UI proportional at any resolution and ensures `EventSystem.RaycastAll` can reach elements regardless of the GameView size (e.g., CI caps the GameView at 640×480):

```csharp
var scaler = canvasGo.GetComponent<CanvasScaler>();
scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
scaler.referenceResolution = new Vector2(800, 600);  // when the game targets a fixed output resolution, use that size here
scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
scaler.matchWidthOrHeight = 0f;  // 0 = match width
```

Also create an EventSystem if none exists in the current stage (see EventSystem section).

When the Canvas is parented under an existing RectTransform, stretch it to fill:
```csharp
var rect = canvasGo.GetComponent<RectTransform>();
rect.anchorMin = Vector2.zero;
rect.anchorMax = Vector2.one;
rect.anchoredPosition = Vector2.zero;
rect.sizeDelta = Vector2.zero;
```

### EventSystem

`MenuOptions.CreateEventSystem` is internal. Replicate it manually, checking for an existing EventSystem first:

```csharp
using UnityEditor.EventSystems;
using UnityEngine.EventSystems;

// Only create if none exists in the current stage
if (Object.FindFirstObjectByType<EventSystem>() == null)
{
    var esGo = ObjectFactory.CreateGameObject("EventSystem", typeof(EventSystem));
    InputModuleComponentFactory.AddInputModule(esGo);
    // Adds StandaloneInputModule by default.
    // If the Input System package is installed and has registered an override,
    // it will add InputSystemUIInputModule instead.
}
```

### Button (Legacy)

```csharp
var buttonGo = DefaultControls.CreateButton(res);
// buttonGo.name == "Button (Legacy)"  ← Unity 6.x naming
```

Result hierarchy and defaults:
```
Button (Legacy)                 RectTransform: size (160, 30)
  Image: sprite=UISprite, type=Sliced, color=white
  Button: transition=ColorTint, colors={highlighted=(0.882,0.882,0.882), pressed=(0.698,0.698,0.698), disabled=(0.521,0.521,0.521)}
  └── Text (Legacy)             RectTransform: anchorMin=(0,0), anchorMax=(1,1), sizeDelta=(0,0)
        Text: text="Button", alignment=MiddleCenter, color=#323232, font=LegacyRuntime.ttf, fontSize=14
```

### Text (Legacy)

```csharp
var textGo = DefaultControls.CreateText(res);
// textGo.name == "Text (Legacy)"
```

Defaults:
```
Text (Legacy)    RectTransform: size (160, 30)
  Text: text="New Text", alignment=UpperLeft, color=#323232, font=LegacyRuntime.ttf, fontSize=14
```

### Image

```csharp
var imageGo = DefaultControls.CreateImage(res);
// imageGo.name == "Image"
```

Defaults:
```
Image    RectTransform: size (100, 100)
  Image: sprite=null, color=white, type=Simple
```

No sprite is assigned by the context menu — `CreateImage` leaves `Image.sprite` null.

### Panel

```csharp
var panelGo = DefaultControls.CreatePanel(res);
// panelGo.name == "Panel"
```

Defaults:
```
Panel    RectTransform: anchorMin=(0,0), anchorMax=(1,1), anchoredPosition=(0,0), sizeDelta=(0,0)
  Image: sprite=Background, type=Sliced, color=(1,1,1,0.392)
```

The Panel always stretches to fill its parent — `MenuOptions.AddPanel` zeros out `anchoredPosition` and `sizeDelta` after placement.

## Canvas / EventSystem notes

- `MenuOptions.CreateNewUI` auto-creates an EventSystem if none exists. Replicate this behavior by calling the EventSystem snippet above after creating the Canvas.
- Set `gameObject.layer = LayerMask.NameToLayer("UI")` on the Canvas. Child GameObjects created via `DefaultControls.Create*` inherit the layer from `PlaceUIElementRoot` in the original source — if you place them manually, set their layer too.
- `DefaultControls.factory` can be swapped to `ObjectFactory`-backed implementation for full Undo/Preset parity. The simplest approach is to set `DefaultControls.factory` before calling `Create*`:

```csharp
// Optional: redirect DefaultControls to use ObjectFactory so Undo/Presets apply to children too
DefaultControls.factory = new DefaultEditorFactory();

// DefaultEditorFactory wraps ObjectFactory:
class DefaultEditorFactory : DefaultControls.IFactoryControls
{
    public GameObject CreateGameObject(string name, params System.Type[] components)
        => ObjectFactory.CreateGameObject(name, components);
}
```

Without this, `DefaultControls.Create*` uses `new GameObject(...)` internally for child objects, which bypasses Undo. If Undo fidelity is not a concern for a one-shot scene-generation script, the factory swap is optional.

## Minimal sample

Editor script that creates a Canvas with a Button under `Assets/Editor/`. Call it via `run_method_in_unity`.

```csharp
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using UnityEditor.EventSystems;

public static class SceneBuilder
{
    // Invoke this method via run_method_in_unity: "SceneBuilder.Build"
    public static void Build()
    {
        // 1. New scene (see SKILL.md ## Scene lifecycle)
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

        // 2. Prepare DefaultControls.Resources
        var res = new DefaultControls.Resources
        {
            standard   = AssetDatabase.GetBuiltinExtraResource<Sprite>("UI/Skin/UISprite.psd"),
            background = AssetDatabase.GetBuiltinExtraResource<Sprite>("UI/Skin/Background.psd"),
        };

        // 3. Canvas
        var canvasGo = ObjectFactory.CreateGameObject(
            "Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
        canvasGo.layer = LayerMask.NameToLayer("UI");
        canvasGo.GetComponent<Canvas>().renderMode = RenderMode.ScreenSpaceOverlay;

        // 4. EventSystem (idempotent)
        if (Object.FindFirstObjectByType<EventSystem>() == null)
        {
            var esGo = ObjectFactory.CreateGameObject("EventSystem", typeof(EventSystem));
            InputModuleComponentFactory.AddInputModule(esGo);
        }

        // 5. Button (Legacy) — parented under Canvas
        var buttonGo = DefaultControls.CreateButton(res);
        buttonGo.transform.SetParent(canvasGo.transform, worldPositionStays: false);
        buttonGo.layer = LayerMask.NameToLayer("UI");

        // 6. Save
        EditorSceneManager.SaveScene(scene, "Assets/YourFeature/Scenes/ExampleScene.unity");
        Debug.Log("Scene saved.");
    }
}
```

## References

Source code (branch `6000.3` of `Unity-Technologies/uGUI`):

- `Editor/UGUI/UI/MenuOptions.cs` — `[MenuItem]` wrappers (internal class)
- `Runtime/UGUI/UI/Core/DefaultControls.cs` — public `Create*` methods and all private constants above
- `Editor/UGUI/EventSystem/InputModuleComponentFactory.cs` — public `AddInputModule`
- `Runtime/UGUI/UI/Core/Text.cs` — `AssignDefaultFont()` (uses `LegacyRuntime.ttf`)
- `Runtime/UGUI/UI/Core/FontData.cs` — `defaultFontData` property
