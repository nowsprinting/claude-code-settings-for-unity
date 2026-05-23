# Troubleshooting the `run_method_in_unity` Tool

## Tool Not Found

If the `run_method_in_unity` tool is not available, consider the following causes:

1. [MCP Server Extension for Unity](https://plugins.jetbrains.com/plugin/30357-mcp-server-extension-for-unity) plugin is not installed: Install it from **Settings > Plugins**.
2. Built-in [MCP Server](https://www.jetbrains.com/help/rider/mcp-server.html) is not enabled: Open **Settings > Tools > MCP Server** and turn on **Enable MCP Server**.
3. The tool is disabled: Open **Settings > Tools > MCP Server > Exposed Tools** and turn on **UnityEditorToolset** and **run_method_in_unity**.

## When Tool Response Does Not Return

`run_method_in_unity` blocks until the method returns. Unlike `run_unity_tests`, it is **not** governed by `MCP_TOOL_TIMEOUT` — there is no configurable timeout, no domain-reload reconnection, and no re-launch logic. The only Kotlin-side wait is the initial 30-second Unity Editor connection check.

**Do not call the tool again while waiting — concurrent calls are unsupported and may interleave console-log collection.**

If the response takes longer than expected, check:

1. Unity Editor is still running and connected to Rider.
2. The method is not stuck in a long-running operation or infinite loop.
3. If the Editor appears hung, force-quit and restart it; then retry once.

## Triage by Tool Response

Check the tool response before investigating log files. Most failure modes can be identified and resolved from `errorMessage` alone.

### `success: false` — Validation errors

Fix the tool call and retry immediately. No log investigation needed.

| `errorMessage`                                          | Problem                       | Fix                                                                                    |
|---------------------------------------------------------|-------------------------------|----------------------------------------------------------------------------------------|
| `"assemblyName is required and must be non-blank."`     | Missing or blank `assemblyName` | Find the `.asmdef` file in the target file's directory hierarchy and use its `name` property. If no `.asmdef` exists, use `Assembly-CSharp-Editor` (Editor code) or `Assembly-CSharp` (runtime code). |
| `"typeName is required and must be non-blank."`         | Missing or blank `typeName`   | Provide the fully qualified type name including namespace (e.g., `"MyNamespace.MyEditorTool"`). |
| `"methodName is required and must be non-blank."`       | Missing or blank `methodName` | Provide the method name. The method must be static and parameterless.                  |

### `success: false` — Unity Editor not connected

`errorMessage`: `"Unity Editor did not connect within 30 seconds."`

Rider cannot see the Unity Editor. Possible causes:

- **Compilation errors**: The Editor may have disconnected due to compile errors. Check with `get_unity_compilation_result` and fix errors before retrying.
- **Editor not running**: Use the `execute_run_configuration` tool to launch the `Start Unity` configuration, then retry.
- **Wrong project open**: Verify the Editor has the correct project loaded.

### `success: false` — Protocol not available

`errorMessage`: `"No protocol available. The solution may not be fully loaded."`

Rider is still loading the solution. Wait for indexing to complete, then retry.

### `success: false` — Method, type, or assembly not found

The Rd RPC returns `success: false` with an `errorMessage` (and optionally a `Stack trace:` block) describing why Unity could not resolve the reflection target. These messages come from resharper-unity's reflection layer and may vary between Rider versions — read `errorMessage` verbatim rather than pattern-matching against fixed strings.

Common categories:

- **Assembly not found** — the assembly name does not match any loaded assembly. Verify it matches the `.asmdef` `name` property exactly (case-sensitive). Confirm the assembly compiles without errors.
- **Type not found** — the fully qualified type name is wrong or the type is in a different assembly. Include the full namespace.
- **Method not found** — the method name is misspelled or the method does not exist on the type.
- **Signature mismatch** — the method is not static or has parameters; the reflection constraint requires a static parameterless method.

Before retrying: call `get_unity_compilation_result` to confirm the assembly is compiled and loaded, then double-check the spelling and access modifiers in the source file.

### `success: false` — Unexpected exception

`errorMessage`: `"<ExceptionClassName>: <message>"`

A Kotlin-side exception was caught unexpectedly. Capture the message verbatim and check `idea.log` (grep `RunMethodInUnityTool`) for the full stack trace to diagnose the cause.

### `success: true` — What this means (and does not mean)

`success: true` indicates only that the RPC reached Unity and the method was found and invoked. It does **not** mean:

- The method completed without throwing internally.
- The return value is available — this tool does not return method return values.
- An `async` method finished — async methods are not awaited; the tool returns as soon as invocation starts.

**Always read `logs` for entries with `"type": "Error"` before reporting success to the user.** An internal exception lands in the console (and is captured in `logs`) but does not flip `success` to `false`.

## Common Pitfalls

1. **`success: true` with an Error log** — the method threw internally. Inspect `logs` entries with `"type": "Error"` for the exception class and stack trace. The tool intentionally surfaces this through console logs rather than the `success` flag.

2. **Return value not available** — the tool returns `{"success": true, "logs": [...]}` only. If the agent needs the return value, the user must add `Debug.Log(...)` inside the method to emit it as a console log.

3. **Async methods are fire-and-forget** — `async Task` and `async void` methods are not awaited. The tool returns when invocation completes, not when the asynchronous task finishes. Side effects after the first `await` may not yet have occurred. If completion is required, add a synchronous wrapper that blocks on the task (e.g., `.GetAwaiter().GetResult()`).

4. **Concurrent calls are unsupported** — there is no backend serialization. Calling the tool a second time while the first is still in progress may interleave console-log collection or cause unexpected behavior in resharper-unity's Rd RPC layer.

5. **Domain reload during the call is undefined** — unlike `run_unity_tests`, there is no reconnection or re-launch logic for domain reloads triggered mid-call. If the method causes script recompilation, the call will fail in an undefined way. Run `get_unity_compilation_result` separately to trigger a refresh and confirm compilation succeeds before calling this tool.

6. **Console logs after method return may be missed** — `UnityConsoleLogCollector` waits 500 ms after the RPC returns for trailing logs to arrive (`LOG_FLUSH_DELAY_MS`). Logs that flush after a frame boundary or arrive more than 500 ms later will not appear in the response.

7. **`logs` is absent on `success: false`** — the error response shape is `{"success": false, "errorMessage": "..."}` with no `logs` field. Do not assume `logs` is always present.

8. **C# source changes require a compilation refresh first** — the tool description explicitly states: if you have modified any C# source files, call `get_unity_compilation_result` first to trigger a refresh and verify compilation succeeds before invoking this tool.

## Log Files to Investigate

Paths are from Unity's [Log Files](https://docs.unity3d.com/Manual/log-files.html) and JetBrains' [Directories used by the IDE](https://www.jetbrains.com/help/rider/Directories_Used_by_the_IDE_to_Store_Settings_Caches_Plugins_and_Logs.html) documentation. Replace `<version>` with the Rider build directory name (e.g. `Rider2024.3`).

### JetBrains Rider log (primary)

`run_method_in_unity` only writes to this log when a Kotlin-side exception is caught — i.e., when the tool returns `success: false` with `errorMessage: "<ExceptionClassName>: <message>"`. For that scenario, grep for `RunMethodInUnityTool`. Successful calls, validation errors, the 30-second connection timeout, "No protocol available", and resharper-unity reflection failures are **not** written to `idea.log` from this plugin's code path.

> There is no custom C# handler for this tool — it calls resharper-unity's `frontendBackendModel.runMethodInUnity` Rd RPC directly. No C# handler keyword exists to grep for.

| OS      | Path                                              |
|---------|---------------------------------------------------|
| macOS   | `~/Library/Logs/JetBrains/<version>/idea.log`     |
| Windows | `%LOCALAPPDATA%\JetBrains\<version>\log\idea.log` |
| Linux   | `~/.cache/JetBrains/<version>/log/idea.log`       |

In the IDE: **Help → Show Log in Finder / Explorer / Files**.

### Unity Editor log

Editor-side crashes, compilation errors, and `Debug.Log` output from the invoked method (if not captured by the console log collector).

| OS      | Path                                     |
|---------|------------------------------------------|
| macOS   | `~/Library/Logs/Unity/Editor.log`        |
| Windows | `%LOCALAPPDATA%\Unity\Editor\Editor.log` |
| Linux   | `~/.config/unity3d/Editor.log`           |

## Diagnostic Workflow

1. Check `errorMessage` first — validation and connection failures need no log investigation.
2. For `success: true`, always inspect `logs` for `"type": "Error"` entries before concluding the method succeeded.
3. If the response is delayed and the Editor is running and connected, the Unity-side method is most likely stuck in a long-running operation, infinite loop, or waiting on something that never completes — no log line is written on dispatch. Force-quit and restart the Editor, then retry once.
4. For `"did not connect within 30 seconds"`, the recovery procedure is the same as `run_unity_tests` — see [Unity Editor not connected](torubleshooting.md#success-false--unity-editor-not-connected) in `torubleshooting.md`. Note: `BackendUnityModel=null` is a `run_unity_tests` C# handler log and will not appear for this tool.
5. For method resolution failures, verify the assembly compiles via `get_unity_compilation_result`, then re-check the fully qualified type name and method signature in the source.
