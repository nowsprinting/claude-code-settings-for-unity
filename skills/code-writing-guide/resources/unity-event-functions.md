# Unity Event Functions

Source: Unity 6.3 LTS (6000.3) local documentation
- `Documentation/en/Manual/event-functions.html`
- `Documentation/en/Manual/execution-order.html`

## What Are Event Functions

Predefined callbacks that all `MonoBehaviour` script components can receive, triggered by Unity Editor and Engine events. Implement the method signature in a `MonoBehaviour`-derived class to use them.

## Initialization Events

| Function | When called |
|----------|-------------|
| `Awake()` | Once when the scene loads, for each object. Called even if the component is disabled. |
| `OnEnable()` | Every time the object/component is enabled. After `SceneManager.sceneLoaded`, before `Start`. |
| `Start()` | Once, before the first frame or physics update, only if the component is enabled. |

**Critical ordering guarantee:** All `Awake` calls across all objects complete before any `Start` is called.  
→ `Start` can safely access state initialized by another object's `Awake`.  
→ `Awake` cannot safely access state initialized by another object's `Awake` (order is arbitrary).

## Regular Update Events

| Function | When called | Use for |
|----------|-------------|---------|
| `Update()` | Once per frame, before rendering and before animations are calculated | General game logic |
| `FixedUpdate()` | Before each physics update, at a fixed discrete interval (not tied to frame rate) | Physics forces, Rigidbody manipulation |
| `LateUpdate()` | After all `Update` and `FixedUpdate` calls and after all animations have been calculated | Camera follow, animation override |

**Physics accuracy:** Use `FixedUpdate` for physics code. `Update` runs at variable frame rate and can cause inconsistent physics results.

**`LateUpdate` use cases:**
- Camera that tracks a moving target (target has already moved by `LateUpdate` time)
- Script that overrides an animation (animation has already calculated by `LateUpdate` time)

## Destruction and Disable Events

| Function | When called |
|----------|-------------|
| `OnDisable()` | Every time the object/component is disabled or destroyed |
| `OnDestroy()` | When the object is destroyed (last frame of its existence) |

## Physics Events

Called when the physics system detects collision or trigger events on the object.

| Function | When called |
|----------|-------------|
| `OnCollisionEnter(Collision)` | First frame of contact between two colliders |
| `OnCollisionStay(Collision)` | Every frame while contact is maintained |
| `OnCollisionExit(Collision)` | First frame after contact breaks |
| `OnTriggerEnter(Collider)` | First frame of overlap with a trigger collider |
| `OnTriggerStay(Collider)` | Every frame while overlapping a trigger collider |
| `OnTriggerExit(Collider)` | First frame after overlap ends |

## Animation Callbacks (MonoBehaviour)

Called during the internal Animation update loop, which runs inside the regular update sequence.

| Function | Use for |
|----------|---------|
| `OnAnimatorMove()` | Apply root motion manually (called after Animator processes movement) |
| `OnAnimatorIK(int layerIndex)` | Adjust IK goals and hints |

## Animation Callbacks (StateMachineBehaviour)

Derive from `StateMachineBehaviour` (not `MonoBehaviour`) to use these:

- `OnStateMachineEnter` / `OnStateMachineExit`
- `OnStateEnter` / `OnStateUpdate` / `OnStateExit`
- `OnStateMove` / `OnStateIK`

## Rendering Callbacks (Built-in Render Pipeline only)

**These do NOT apply to URP or HDRP.** For SRP, use `RenderPipelineManager` events or `Application.onBeforeRender`.

| Function | When called |
|----------|-------------|
| `OnPreCull()` | Before the camera culls the scene |
| `OnBecameVisible()` / `OnBecameInvisible()` | When visibility to any camera changes |
| `OnWillRenderObject()` | Once per camera if the object is visible |
| `OnPreRender()` | Before the camera starts rendering |
| `OnRenderObject()` | After regular scene rendering; use `GL` or `Graphics.DrawMeshNow` here |
| `OnPostRender()` | After the camera finishes rendering |
| `OnRenderImage(RenderTexture, RenderTexture)` | After rendering completes; use for post-processing |
| `OnGUI()` | Multiple times per frame: Layout, Repaint, then once per input event |
| `OnDrawGizmos()` | In Scene view, for visualisation only |

**Camera attachment requirement:** `OnPreCull`, `OnPreRender`, `OnPostRender`, and `OnRenderImage` only fire on a `MonoBehaviour` that is attached to the **same GameObject as a Camera component**. To receive these callbacks on a different object, use the delegate equivalents: `Camera.onPreCull`, `Camera.onPreRender`, `Camera.onPostRender`.

## Input Events (Legacy — do not use in new code)

`OnMouseOver`, `OnMouseDown`, `OnMouseUp`, `OnMouseEnter`, `OnMouseExit`, `OnMouseDrag`, `OnMouseUpAsButton` — only supported with the legacy Input Manager, which is no longer recommended. Use Unity's Input System package instead.

## GUI Events (Legacy — avoid in new code)

`OnGUI()` — only for projects using the legacy IMGUI system.

**Overhead warning:** Adding an `OnGUI` method, **even if the body is empty**, adds IMGUI processing overhead to every frame. Remove empty `OnGUI` stubs completely.

## Coroutine and Async Resumption

| Yield / Await | Resumes at |
|---------------|-----------|
| `yield return null` | Next `Update` phase |
| `yield return new WaitForFixedUpdate()` | End of next `FixedUpdate` step |
| `yield return new WaitForEndOfFrame()` | End of frame (after rendering) |
| `Awaitable.NextFrameAsync()` | `Update` phase of next frame |
| `Awaitable.FixedUpdateAsync()` | Next `FixedUpdate` phase |
| `Awaitable.EndOfFrameAsync()` | End of frame |
| Regular `.NET Task` / `async Task` | `Update` phase |

**Order not guaranteed:** The execution order between a resuming coroutine and a resuming `Awaitable`/`Task` in the same phase is not guaranteed. `Awaitable` instances are grouped and executed in the order they were awaited.

## Non-MonoBehaviour Initialization

| Attribute | When it runs |
|-----------|-------------|
| `[InitializeOnLoad]` on a class with a static constructor | On Unity Editor launch |
| `[InitializeOnLoadMethod]` on a static method | On Unity Editor launch |
| `[RuntimeInitializeOnLoadMethod]` on a static method | At runtime initialization (before scene load by default) |

## Execution Order Limitations

- **Cross-object order is not guaranteed.** You cannot rely on which GameObject's `Update` (or any other event function) runs first unless explicitly documented.
- **Same-script-class order is not guaranteed.** Two instances of the same `MonoBehaviour` on different GameObjects can fire in any order.
- To control order between different `MonoBehaviour` types, use **Edit > Project Settings > Script Execution Order**.

## Scene Load Callbacks

`SceneManager.sceneLoaded` fires after `OnEnable` but before `Start` for all objects in the scene.  
`SceneManager.sceneUnloaded` fires when a scene is fully unloaded.
