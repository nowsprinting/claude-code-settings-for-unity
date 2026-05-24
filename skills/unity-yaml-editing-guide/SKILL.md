---
name: unity-yaml-editing-guide
description: >-
  Provides guidelines for directly editing Unity YAML-serialized asset files for Unity projects.
  Make sure to use this skill whenever creating, editing, or modifying simple YAML asset files (ScriptableObjects, Materials, etc.) via Edit/Write tools without going through the Unity Editor.
  This includes adjusting ScriptableObject field values, modifying material shader properties, or any task that results in direct changes to allowlisted Unity YAML asset files.
  Even for small edits or one-line value changes, load this skill to ensure Unity asset-YAML conventions are followed.
user-invocable: false
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Guide for directly editing Unity YAML-serialized asset files for Unity projects.

## Rules

- **Edit only the following allowlist of simple YAML asset types.** Other YAML assets (`AnimationClip`, `AnimatorController`, `Texture2D`, `Mesh`, `AudioClip`, `LightingDataAsset`, etc.) carry binary-derived data or complex internal structure — open them in Unity Editor instead.
  - ScriptableObject (`MonoBehaviour`, class ID 114) — files `*.asset`
  - Material (`Material`, class ID 21) — files `*.mat`
- **Never directly edit `.unity` or `.prefab` files.** Use `edit-scene` skill — those carry GameObject/Prefab-instance structure that is unsafe to author by hand.
- **Never touch `.meta` files.** Unity owns `.meta` content (GUIDs, importer settings); hand-edits corrupt asset references project-wide.
- **Preserve the mandatory two-line header exactly.** Lines 1–2 must be `%YAML 1.1` and `%TAG !u! tag:unity3d.com,2011:` — these are not stylistic, and Unity will fail to load the asset if they drift.
- **Preserve the document marker.** `--- !u!<classID> &<fileID>` — for ScriptableObject use `--- !u!114 &11400000`, for Material use `--- !u!21 &2100000` (canonical local anchors).
- **Keep the canonical preamble field order at the top of the mapping.** For ScriptableObject (`MonoBehaviour:`), the order is `m_ObjectHideFlags` → `m_CorrespondingSourceObject` → `m_PrefabInstance` → `m_PrefabAsset` → `m_GameObject` → `m_Enabled` → `m_EditorHideFlags` → `m_Script` → `m_Name` → `m_EditorClassIdentifier`. User fields come after.
- **Keep `m_Name` in sync with the filename** (without the `.asset` / `.mat` extension) — a mismatch confuses Unity's importer and `Resources.Load`-style lookups.
- **Cross-file object references need all three keys** — `{fileID: N, guid: <32-hex>, type: T}` where `type: 2` is a project asset and `type: 3` is a script. Local references use `{fileID: N}` matching an `&N` anchor in the same file; `{fileID: 0}` means null.
- **Quote strings only when they contain non-ASCII characters,** and escape every non-ASCII code point as `\uXXXX` inside double quotes — plain ASCII stays unquoted. Match how Unity itself emits the file.
- **Use 2-space indent, LF line endings, UTF-8 without BOM, and a trailing newline at EOF.** Tabs, CRLF, or a BOM round-trip badly when Unity re-saves the file.
- **Do not add comments, YAML aliases (`*name`), extra tags, or chomping indicators (`|`, `>`).** Unity's YAML parser drops or rejects them, and re-save would strip cosmetic formatting anyway — don't bother polishing what Unity will normalize.
- **After editing, let Unity re-import the asset** (focus the Editor) and confirm successful import using `get_unity_compilation_result`. Review the diff Unity produces on next save to confirm the edit was accepted as intended.

## Gotchas

- **Verify the file starts with `%YAML 1.1` before editing.** If it does not, the project is in Binary or Mixed serialization mode and the asset must not be hand-edited — open it in the Unity Editor instead.
- **Never invent an `m_Script` GUID.** Copy from an existing asset of the same ScriptableObject type, or look up the script's `.cs.meta` file — fabricated GUIDs detach the asset from its script.
- **Auto-property backing fields appear literally as `<PropertyName>k__BackingField`.** Do not rename them to the property name — the serialized name is the C# compiler's backing-field symbol.
- **Use Unity's scalar forms, not generic YAML forms** — bools as `0` / `1` (never `true` / `false`), enums and ints bare, floats as plain decimals, `Vector3` as `{x: 0, y: 0, z: 0}` flow style, `Quaternion` as `{x: 0, y: 0, z: 0, w: 1}`, `Color` as `{r: 1, g: 1, b: 1, a: 1}`.

## Scalar quick-reference

| Type | Form | Example |
|---|---|---|
| bool | `0` / `1` | `m_Enabled: 1` |
| int / enum | bare integer | `<Cost>k__BackingField: 1` |
| float | plain decimal | `m_Glossiness: 0.5` |
| ASCII string | unquoted | `m_Name: DryPrinciple` |
| non-ASCII string | double-quoted, `\uXXXX` escapes | `"DRY原則"` |
| Vector3 | flow mapping | `{x: 0, y: 0, z: 0}` |
| Quaternion | flow mapping | `{x: 0, y: 0, z: 0, w: 1}` |
| Color | flow mapping | `{r: 1, g: 1, b: 1, a: 1}` |
| local ref | flow mapping | `{fileID: 11400000}` |
| cross-file ref | flow mapping | `{fileID: 11400000, guid: <32-hex>, type: 2}` |
| null ref | flow mapping | `{fileID: 0}` |
| list of refs | block sequence with `- ` bullets | one `- {fileID: ...}` per line |

## Resources

- Before editing any `.asset` or `.mat` file (header, `m_Script`, class-typed contents, or unfamiliar field): Read `.claude/skills/unity-yaml-editing-guide/resources/asset-yaml-format.md`
