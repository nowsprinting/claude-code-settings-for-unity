# Unity Asset YAML Format Reference

## Prerequisite: Force Text serialization

Unity must be set to **Force Text** serialization mode for `.asset` files to be hand-editable.

- Verify: Edit → Project Settings → Editor → Asset Serialization → **Force Text**
- To confirm: open `ProjectSettings/EditorSettings.asset` and check `m_SerializationMode: 2` (Force Text).
- If a file does **not** start with `%YAML 1.1`, the project is in Binary or Mixed mode — stop and ask the user to switch to Force Text before proceeding.

## Allowlist

Only the following asset types are safe to hand-edit. All others carry binary-derived or complex internal structure and must be opened in the Unity Editor.

| Class name | Class ID | File extension | Notes |
|---|---|---|---|
| `MonoBehaviour` / ScriptableObject | 114 | `.asset` | User-defined data assets |
| `Material` | 21 | `.mat` | Shader property overrides |

**Do not hand-edit** (non-exhaustive): `AnimationClip` (74), `AnimatorController` (91), `Texture2D` (28), `Mesh` (43), `AudioClip` (83), `LightingDataAsset` (1120). `PhysicsMaterial` (134) and `PhysicsMaterial2D` (272) are excluded due to Unity version naming discrepancies — request user confirmation before adding them to the allowlist.

## File structure overview

Every Unity text-serialized asset file has this shape:

```
%YAML 1.1
%TAG !u! tag:unity3d.com,2011:
--- !u!<classID> &<fileID>
<ClassName>:
  <field>: <value>
  ...
```

- **Lines 1–2** (`%YAML 1.1` and `%TAG`) are mandatory and must appear exactly as shown — Unity refuses to load the file if they differ.
- **Document marker** `--- !u!<classID> &<fileID>`:
  - `!u!<classID>` — Unity class type tag (see Allowlist table above).
  - `&<fileID>` — local YAML anchor, an integer unique within the file. Internal references use this number.
  - For a single-root ScriptableObject `.asset`: always `--- !u!114 &11400000`.
  - For a single Material `.mat`: always `--- !u!21 &2100000`.
- **Top-level mapping key** matches the class name: `MonoBehaviour:` for ScriptableObject, `Material:` for Material.
- Class ID 114 (`MonoBehaviour`) is shared by both `MonoBehaviour` and user-defined `ScriptableObject` subclasses — there is no separate class ID for ScriptableObject.

## ScriptableObject canonical preamble fields

For `MonoBehaviour:` assets, the first ten fields must appear in this order with these canonical values. User-defined fields come **after** `m_EditorClassIdentifier`.

| Field | Canonical value | Meaning / notes |
|---|---|---|
| `m_ObjectHideFlags` | `0` | Editor hide flags; `0` = visible |
| `m_CorrespondingSourceObject` | `{fileID: 0}` | Prefab source; always null for standalone `.asset` |
| `m_PrefabInstance` | `{fileID: 0}` | Prefab instance; always null for standalone `.asset` |
| `m_PrefabAsset` | `{fileID: 0}` | Prefab asset ref; always null for standalone `.asset` |
| `m_GameObject` | `{fileID: 0}` | Host GameObject; always null — ScriptableObject has no GameObject |
| `m_Enabled` | `1` | Component enabled; keep `1` |
| `m_EditorHideFlags` | `0` | Inspector hide flags; `0` = visible |
| `m_Script` | `{fileID: 11500000, guid: <32-hex>, type: 3}` | Reference to the MonoScript. **Never invent the GUID.** |
| `m_Name` | `<asset filename without extension>` | Must match the `.asset` filename |
| `m_EditorClassIdentifier` | `<Assembly>::<Namespace>.<Type>` | E.g. `MyGame::MyGame.ScriptableObjects.MyData` — do not break this |

### `m_Script` details

- `fileID: 11500000` — the canonical local ID of every MonoScript inside its `.cs.meta` file. This value is always `11500000`.
- `guid` — the GUID from the corresponding `.cs.meta` file. Find it by reading `<ScriptName>.cs.meta` and copying its `guid:` line. **Do not generate or guess.**
- `type: 3` — indicates a script asset.

### `m_EditorClassIdentifier` format

Format: `<AssemblyName>::<Namespace>.<ClassName>`

Example: `MyGame::MyGame.ScriptableObjects.ItemData`

This field is a hint that Unity uses to display the class name in the Inspector. It is normalized by Unity on re-save. However, breaking it (e.g., wrong class name, wrong namespace) causes the asset to display as a "Missing Script" stub until Unity normalizes it on next save.

## Material canonical preamble fields

For `Material:` assets, the key structure is:

```yaml
Material:
  serializedVersion: 8          # migration version; do not change
  m_ObjectHideFlags: 0
  m_CorrespondingSourceObject: {fileID: 0}
  m_PrefabInstance: {fileID: 0}
  m_PrefabAsset: {fileID: 0}
  m_Name: <filename without extension>
  m_Shader: {fileID: <N>, guid: <32-hex>, type: 0}
  m_Parent: {fileID: 0}         # setting to non-zero creates a Material Variant
  m_ModifiedSerializedProperties: 0
  m_ValidKeywords: []
  m_InvalidKeywords: []
  m_LightmapFlags: 4
  m_EnableInstancingVariants: 0
  m_DoubleSidedGI: 0
  m_GIBatchingTracker: 0
  m_PropertyTrampoline: {fileID: 0}
  m_SavedProperties:
    serializedVersion: 3
    m_TexEnvs:
    - <TexturePropertyName>:
        m_Texture: {fileID: 0}
        m_Scale: {x: 1, y: 1}
        m_Offset: {x: 0, y: 0}
    m_Ints: []
    m_Floats:
    - <FloatPropertyName>: 0.5
    m_Colors:
    - <ColorPropertyName>: {r: 1, g: 1, b: 1, a: 1}
```

Key notes:
- `m_Shader` references the shader asset. Built-in shaders use `type: 0` and a fixed GUID of the form `0000000000000000f000000000000000` — copy from an existing `.mat` in the project or package cache rather than guessing.
- `m_Parent: {fileID: 0}` — setting this to a non-zero cross-file reference turns the Material into a **Material Variant**; only do so intentionally.
- Unity re-sorts `m_TexEnvs`, `m_Floats`, `m_Ints`, and `m_Colors` entries **alphabetically by property name** on every save — do not rely on ordering.

## Auto-property backing fields

C# auto-properties annotated with `[field: SerializeField]` are serialized under their compiler-generated backing-field name:

```csharp
[field: SerializeField]
public int Cost { get; private set; }
```

Serializes as:

```yaml
<Cost>k__BackingField: 1
```

**Do not rename** the backing-field key to the property name (`Cost:`) — Unity will not recognize it and the value will be lost on next save. The angle brackets and `k__BackingField` suffix are literal and mandatory.

## Object reference syntax

### Local reference (same file)

```yaml
{fileID: 11400000}
```

`fileID` matches an `&11400000` anchor elsewhere in the same file. `{fileID: 0}` means null.

### Cross-file reference

```yaml
{fileID: N, guid: <32-hex>, type: T}
```

All three keys are required. Omitting any key produces an unresolvable reference.

| `type` value | Meaning |
|---|---|
| `0` | Built-in / internal Unity asset (e.g. built-in shader) |
| `2` | Project asset (most `.asset`, `.mat`, `.prefab`, `.unity` files) |
| `3` | Script asset (MonoScript — target of `m_Script`) |

**To obtain a GUID:** read the target asset's `.meta` file and copy its `guid:` line. Never generate or guess a GUID — a fabricated value produces a broken reference that is invisible until runtime.

## Scalar formatting reference

| Type | Unity form | Why / notes |
|---|---|---|
| bool | `0` / `1` | Unity has historically serialized bools as integers; `true` / `false` are not valid |
| int / enum | bare integer | Enum values serialize as their underlying integer; no string names |
| float | plain decimal (e.g. `0.5`) | IEEE-754 hex form `0x3f000000(0.5)` also parses, but avoid it when authoring by hand |
| ASCII string | unquoted | No quotes needed for plain ASCII (including apostrophes, punctuation) |
| non-ASCII string | double-quoted, `\uXXXX` | Unity's emitter normalizes to ASCII-only; all non-ASCII must be escaped |
| Vector2 | `{x: 0, y: 0}` | Flow mapping, always on one line |
| Vector3 | `{x: 0, y: 0, z: 0}` | Flow mapping |
| Quaternion | `{x: 0, y: 0, z: 0, w: 1}` | Flow mapping |
| Color | `{r: 1, g: 1, b: 1, a: 1}` | Flow mapping |
| empty list | `[]` | Inline on the same line as the key |

### List and nested struct indentation

Block sequences use 2-space indent. For a list of scalars or references:

```yaml
<ItemList>k__BackingField:
- {fileID: 11400000, guid: aaaaaaaa000000000000000000000001, type: 2}
- {fileID: 11400000, guid: aaaaaaaa000000000000000000000002, type: 2}
```

For a list of nested structs, the first field of each struct aligns with the `- ` bullet; subsequent fields indent 2 more spaces under the first:

```yaml
<ActionPatterns>k__BackingField:
- <ActionName>k__BackingField: Attack
  <Damage>k__BackingField: 10
- <ActionName>k__BackingField: DoubleAttack
  <Damage>k__BackingField: 6
```

## Behavior on re-save

Unity does **not** preserve user formatting, key ordering, or comments when it re-saves an asset. Every hand-edit will be normalized:

- All `m_*` preamble fields are reordered to Unity's canonical sequence.
- Non-ASCII strings are re-emitted as `\uXXXX` escapes inside double quotes.
- Float scalars may be reformatted.
- List entries in `m_SavedProperties` are sorted alphabetically.
- Any comments (`#`) are silently dropped.

**Recommended workflow after hand-editing:**

1. Save the file.
2. Focus the Unity Editor (or call `AssetDatabase.Refresh()` via `run_method_in_unity`).
3. Unity re-imports the asset and normalizes the file.
4. Run `git diff` to review what Unity changed — confirm the intent of the edit was preserved and no unintended data was dropped.

Unity is tolerant of **omitted** user fields (it supplies defaults), but dropping `m_Script` or corrupting `m_EditorClassIdentifier` detaches the asset from its script, causing a "Missing Script" display in the Inspector.

## Worked example: Material (synthesized)

> Note: The following is a synthesized minimal example based on Unity 6 Built-in / Unlit Color Material structure. Use it as a format reference when creating or editing `.mat` files.

A minimal `Unlit/Color` Material (`Assets/Materials/ExampleMaterial.mat`):

```yaml
%YAML 1.1
%TAG !u! tag:unity3d.com,2011:
--- !u!21 &2100000
Material:
  serializedVersion: 8
  m_ObjectHideFlags: 0
  m_CorrespondingSourceObject: {fileID: 0}
  m_PrefabInstance: {fileID: 0}
  m_PrefabAsset: {fileID: 0}
  m_Name: ExampleMaterial
  m_Shader: {fileID: 7, guid: 0000000000000000f000000000000000, type: 0}
  m_Parent: {fileID: 0}
  m_ModifiedSerializedProperties: 0
  m_ValidKeywords: []
  m_InvalidKeywords: []
  m_LightmapFlags: 4
  m_EnableInstancingVariants: 0
  m_DoubleSidedGI: 0
  m_GIBatchingTracker: 0
  m_PropertyTrampoline: {fileID: 0}
  m_SavedProperties:
    serializedVersion: 3
    m_TexEnvs: []
    m_Ints: []
    m_Floats: []
    m_Colors:
    - _Color: {r: 1, g: 0, b: 0, a: 1}
```

Annotations:
- `--- !u!21 &2100000` — class ID 21 = Material; `2100000` is the canonical local anchor for a single-root Material.
- `serializedVersion: 8` — Unity's internal migration version; do not change.
- `m_Shader` with `type: 0` and `guid: 0000000000000000f000000000000000` — built-in shader reference format. The exact `fileID` and `guid` for a specific built-in shader must be copied from an existing `.mat` in the project or from a package-cache file; do not guess.
- `m_Parent: {fileID: 0}` — null; setting this to a cross-file reference creates a Material Variant.
- `m_SavedProperties.m_Colors` contains `_Color` — the shader property name. Unity re-sorts all property entries by name on save.
- Empty lists (`m_TexEnvs: []`, `m_Floats: []`, etc.) are written inline — do not expand them to block sequences unless they actually have entries.

## Troubleshooting

**Asset shows as "Missing Script" (broken pink stub) in Inspector**
→ Check `m_Script`: verify `fileID: 11500000`, confirm `guid` matches the target `.cs.meta`, and confirm `type: 3`. Also verify `m_EditorClassIdentifier` has the correct `Assembly::Namespace.Type` format.

**Edit appears accepted but Unity reverts it on next save**
→ A field name typo or wrong scalar type (e.g. `true` instead of `1`) caused Unity to silently drop the value and substitute a default. Run `git diff` after Unity re-saves and trace which field was normalized. Align with Unity's output.

**Non-ASCII characters appear garbled or as escape sequences in Inspector**
→ Ensure the file is UTF-8 without BOM, and that all non-ASCII characters inside string fields are encoded as `\uXXXX` inside double-quoted scalars. An unquoted field containing raw UTF-8 bytes may survive import but will be re-emitted as `\uXXXX` on the next save.

**File does not start with `%YAML 1.1`**
→ The project or this specific asset is in Binary or Mixed serialization mode. Do not hand-edit. Ask the user to switch Asset Serialization to Force Text (Edit → Project Settings → Editor → Asset Serialization → Force Text) and re-save the asset from within Unity before attempting to edit it as text.

## Reference links

- Full class ID table: <https://docs.unity3d.com/Manual/ClassIDReference.html>
- Unity YAML format overview: <https://docs.unity3d.com/Manual/FormatDescription.html>
- Unity YAML parser limitations: <https://docs.unity3d.com/Manual/UnityYAML.html>
