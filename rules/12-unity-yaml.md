---
paths:
  - "**/*.{meta,asset,prefab,unity}"
---

# Editing the Unity YAML file

Generally, files with the extensions .meta, .asset, .prefab, and .unity are operated in the Unity Editor via MCP.
If instructed to perform an operation that cannot be performed through MCP, edit the file directly.

Please read the following page before editing a file.

## .meta file

- Do NOT create a .meta file, as it will be created by the Unity editor.
- https://docs.unity3d.com/Manual/AssetMetadata.html

## .asset, .prefab, and .unity file

- Do NOT directly edit the .unity and .prefab files. Instead, create and run an editor script under ./Assets/Editor/.
- https://docs.unity3d.com/Manual/FormatDescription.html
- https://docs.unity3d.com/Manual/UnityYAML.html
- https://docs.unity3d.com/Manual/YAMLFileFormat.html
- https://docs.unity3d.com/Manual/ClassIDReference.html
