---
name: code-writing-guide
description: >-
  Provides coding guidelines for Unity projects.
  Make sure to use this skill whenever writing, creating, editing, or modifying code files.
  This includes implementing new features, fixing bugs, refactoring, adding tests, or any task that results in code changes.
  Even for small edits or one-line fixes, load this skill to ensure project conventions are followed.
user-invocable: false
license: Unlicense
metadata:
  author: Koji Hasegawa
---

Guide for writing code in Unity projects.

## Rules

- Before modifying any code file, check if the editor is in Play Mode. If it is, stop it using the `unity_play_control` tool first — Play Mode may skip recompilation, leaving stale code active.
- Never create `.meta` files. Unity editor creates them automatically.
- When editing (creating or modifying) scene (`.unity`) or prefab (`.prefab`) files, use the `edit-scene` skill.

## Resources

Read the appropriate resource file based on the situation:

- Before writing or modifying any code file: Read `.claude/skills/code-writing-guide/resources/coding-guideline.md`
- Before writing or modifying any code file: Read `.claude/skills/code-writing-guide/resources/unity-modern-guidelines.md`
- Before writing or modifying MonoBehaviour lifecycle or event-handling methods (Awake, Start, OnEnable, OnDisable, OnDestroy, Update, FixedUpdate, LateUpdate, OnCollision*, OnTrigger*, OnGUI, OnMouse*, OnBecame*, OnPreCull, OnPreRender, OnPostRender, OnRenderImage, OnRenderObject, OnWillRenderObject, OnAnimatorMove, OnAnimatorIK, OnDrawGizmos): Read `.claude/skills/code-writing-guide/resources/unity-event-functions.md`
- Before referencing an API, verifying a package behavior, or looking up documentation: Read `.claude/skills/code-writing-guide/resources/unity-references.md`
- When resolving diagnostics or handling code review feedback: Read `.claude/skills/code-writing-guide/resources/diagnostics-review-feedback.md`
