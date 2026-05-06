# Unity Modern Guidelines

## How to Use This Guidelines

Based on the detected Unity version, apply all features up to that version when writing Unity C# code.

**When writing Unity code**, use ALL features from this document up to the target version:
- Prefer modern Unity APIs over deprecated or legacy alternatives
- Never use features from newer Unity versions than the target
- Never use outdated patterns when a modern alternative is available

## Detected Unity Version

!grep "m_EditorVersion:" ProjectSettings/ProjectVersion.txt 2>/dev/null | sed 's/m_EditorVersion: //' | grep . || echo unknown

**If version detected (not "unknown"):**
- Say: "This project is using Unity X.Y, so I'll use modern Unity APIs and C# features up to this version."
- Do NOT list features, do NOT ask for confirmation

**If version is "unknown":**
- Say: "Could not detect Unity version in this repository"
- Use AskUserQuestion: "Which Unity version should I target?" with common version options

## Features by Unity Version

### Unity 2020.2+

**C# 8.0:**
- Switch expressions: `state switch { State.Active => true, _ => false }` instead of switch statements
- Property patterns: `obj is Enemy { IsDead: true }` instead of casting and field checks
- Tuple patterns: `(a, b) switch { (0, 0) => "origin", _ => "other" }`
- Nullable reference types: Add `#nullable enable` (or enable in project settings) to catch null dereferences at compile time

```csharp
// Instead of:
string Describe(State state)
{
    switch (state)
    {
        case State.Active: return "Active";
        case State.Dead:   return "Dead";
        default:           return "Unknown";
    }
}

// Use:
string Describe(State state) => state switch
{
    State.Active => "Active",
    State.Dead   => "Dead",
    _            => "Unknown",
};
```

**Unity APIs:**
- Add `[NonReorderable]` to serialized `List<T>` or array fields when Inspector reordering should be disabled
- Use `ProfilerRecorder` to sample performance counters (draw calls, SetPass) from runtime code

### Unity 2021.1+

**Object Pooling:**
- Use `ObjectPool<T>`, `ListPool<T>`, `HashSetPool<T>`, `DictionaryPool<TKey, TValue>` from `UnityEngine.Pool` instead of custom pool implementations

```csharp
// Instead of:
private readonly Queue<Bullet> _pool = new();
private Bullet Get()            => _pool.Count > 0 ? _pool.Dequeue() : Instantiate(_prefab);
private void   Return(Bullet b) => _pool.Enqueue(b);

// Use:
private readonly ObjectPool<Bullet> _pool = new(
    createFunc:      () => Instantiate(_prefab),
    actionOnGet:     b  => b.gameObject.SetActive(true),
    actionOnRelease: b  => b.gameObject.SetActive(false)
);
```

### Unity 2021.2+

**.NET Standard 2.1:**
- Use `Span<T>` for zero-allocation temporary buffers instead of `new T[]`
- Use index-from-end `array[^1]` instead of `array[array.Length - 1]`
- Use range slices `array[1..4]` instead of `Array.Copy` or LINQ `Skip`/`Take`

```csharp
// Instead of:
var last  = items[items.Length - 1];
var slice = items.Skip(1).Take(3).ToArray();
// Use:
var last  = items[^1];
var slice = items[1..4];
```

**C# 9.0:**
- Target-typed `new()`: `List<Enemy> enemies = new();` instead of `new List<Enemy>()`
- `init`-only setters for read-only-after-construction properties
- Record types for immutable value objects

**Unity APIs:**
- Use UI Toolkit (`UnityEngine.UIElements`) for runtime UI — runtime support is now available

### Unity 2023.1+

**Awaitable — ALWAYS prefer over coroutines:**
- Use `async Awaitable` methods instead of `IEnumerator` coroutines
- `Awaitable.NextFrameAsync(ct)` instead of `yield return null`
- `Awaitable.EndOfFrameAsync(ct)` instead of `yield return new WaitForEndOfFrame()`
- `Awaitable.FixedUpdateAsync(ct)` instead of `yield return new WaitForFixedUpdate()`
- `Awaitable.WaitForSecondsAsync(t, ct)` instead of `yield return new WaitForSeconds(t)`
- Pass `destroyCancellationToken` (on `MonoBehaviour`) to tie async lifetime to object destruction

```csharp
// Instead of:
private IEnumerator SpawnRoutine()
{
    yield return new WaitForSeconds(2f);
    SpawnEnemy();
    yield return null;
    ShowEffect();
}
StartCoroutine(SpawnRoutine());

// Use:
private async Awaitable SpawnAsync(CancellationToken ct = default)
{
    await Awaitable.WaitForSecondsAsync(2f, ct);
    SpawnEnemy();
    await Awaitable.NextFrameAsync(ct);
    ShowEffect();
}
_ = SpawnAsync(destroyCancellationToken);
```

### Unity 2023.2+

**TextMesh Pro:**
- TMP is merged into uGUI (`com.unity.ugui`); do NOT add the separate `com.unity.textmeshpro` package
- Import and usage are unchanged: use `TMPro.TextMeshProUGUI`, `TMPro.TMP_Text`, etc.

### Unity 6.3+

**Testing:**
- Use UI Test Framework (`com.unity.test-framework.ui`) v1.0 for runtime UI interaction tests
