---
name: scene-editing-guide
description: >-
  Provides guidelines for creating and modifying Unity scene and prefab files in Unity projects.
  Make sure to use this skill whenever creating, editing, or modifying .unity scene files or .prefab prefab files, or writing editor scripts under Assets/Editor/ that generate or manipulate scenes, prefabs, or scene-bound assets.
  This includes adding GameObjects, building uGUI hierarchies, wiring up components, and any task that results in changes to .unity or .prefab files.
  Even for small edits or one-line scene changes, load this skill to ensure scene-authoring conventions are followed.
---

Guide for creating and editing Unity scene files in Unity projects.

## Rules

- Do not directly Edit or Write `.unity` or `.prefab` files. Instead, write an editor script under `Assets/Editor/` and execute it in Unity to create or update the scene or prefab.
- **Editor scripts must always end with `EditorSceneManager.SaveScene` (or `PrefabUtility.SaveAsPrefabAsset` for prefabs).** Treat "no dirty scenes/assets at script exit" as a hard postcondition.
  - Scene: `EditorSceneManager.SaveScene(scene, path)` (new) or `EditorSceneManager.SaveScene(scene)` (existing). The return value is `true` on success.
  - Prefab: `PrefabUtility.SaveAsPrefabAsset(go, path)`. When editing via `LoadPrefabContents`, always pair with `SaveAsPrefabAsset` → `UnloadPrefabContents`.
  - When the script also creates side-effect assets (Materials, ScriptableObjects, etc.), call `AssetDatabase.SaveAssets()` after the per-object saves to flush pending writes.
- **Never call two Unity Editor tools in parallel.** `unity_play_control`, `get_unity_compilation_result`, `run_method_in_unity`, and `run_unity_tests` must be called strictly one at a time — always wait for each call to return before making the next one. Calling them concurrently causes domain-reload conflicts that result in "canceled" or "did not connect within 30 seconds" errors.
- **When a Unity Editor tool returns `error` or `canceled`, wait 10 seconds before retrying.** Domain reload typically takes several seconds; immediate retry hits the same in-flight reload and fails again. Do not switch tools in the meantime (e.g., calling `unity_play_control` to verify state) — that just compounds the multiplexed calls. If the same tool returns `error` or `canceled` on two consecutive attempts (with the 10-second wait between them), stop and consult the user instead of retrying further.
- Before running an editor script, check if the editor is in Play Mode using the `unity_play_control` tool. If it is, stop it first.
- After modifying code, confirm compilation success using the `get_unity_compilation_result` tool before running.
- **To determine which assembly an editor script belongs to**, run `.claude/skills/scene-editing-guide/scripts/resolve-assembly.sh <cs-file-path>`. It walks up directories to find the nearest `.asmdef`; if none is found, it falls back to `Assembly-CSharp-Editor` (path contains `/Editor/`) or `Assembly-CSharp`.
- **Prefer the `run_method_in_unity` tool (MCP Server Extension for Unity) for execution.** Define a `public static` method in the script (adding `[MenuItem("Tools/...")]` is optional) and invoke it directly via `run_method_in_unity`. Only fall back to `execute_run_configuration` or other alternatives when `run_method_in_unity` is unavailable.
- Never create `.meta` files manually — Unity generates them automatically. Match each `.meta` file's commit fate to its paired asset:
  - Scene/prefab files (`.unity`, `.prefab`) and their referenced assets (materials, SOs, etc.) → **commit** (required for GUID resolution)
  - Editor scripts (`Assets/Editor/*.cs`) and their `.meta` → **do not commit** (orphaned metas break the other checkout if the script is absent)
- Editor scripts (`Assets/Editor/`) and their `.meta` files are **not committed**. Do not delete them — leave them for the user to remove manually. Do not add them to `.gitignore`; the user excludes them at commit time.
- For uGUI buttons and text, use the **legacy variants** (`UnityEngine.UI.Button` / `UnityEngine.UI.Text`). Do not use TextMeshPro unless the user explicitly requests it.
- Apply context-menu-equivalent defaults when creating uGUI components (see Resources below).

## Scene lifecycle

- **New scene**: First determine whether the scene will be loaded additively or as a single scene, then choose the setup accordingly.
  - **Additive** (`LoadSceneMode.Additive`): `EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single)` — no camera or light needed.
  - **Single** (`LoadSceneMode.Single`): `EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single)` — Main Camera and Directional Light are included automatically; do not add a camera manually.
  - In both cases, place additional GameObjects via `ObjectFactory.CreateGameObject` and save with `EditorSceneManager.SaveScene(scene, "Assets/YourFeature/Scenes/XxxScene.unity")`.
- **Edit existing scene**: `EditorSceneManager.OpenScene(path, OpenSceneMode.Single)` → make changes → `EditorSceneManager.SaveScene(scene)`.
- **New prefab**: build the GameObject hierarchy in memory, then save with `PrefabUtility.SaveAsPrefabAsset(go, "Assets/YourFeature/Prefabs/XxxPrefab.prefab")`.
- **Edit existing prefab**: open with `PrefabUtility.LoadPrefabContents(path)` → modify → `PrefabUtility.SaveAsPrefabAsset(root, path)` → `PrefabUtility.UnloadPrefabContents(root)`.
- Use `ObjectFactory.CreateGameObject` / `ObjectFactory.AddComponent` so Undo history and Presets are applied automatically.
- Parent child objects with `transform.SetParent(parent, worldPositionStays: false)`.

## Resources

- Before writing or modifying any editor script that creates or manipulates uGUI components: Read `.claude/skills/scene-editing-guide/resources/ugui.md`

## Troubleshooting

- The `run_method_in_unity` tool is not available or fails with a connection error: Read `.claude/skills/scene-editing-guide/resources/troubleshooting-run-method-in-unity.md`
