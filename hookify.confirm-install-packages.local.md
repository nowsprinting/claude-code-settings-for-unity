---
name: confirm-install-packages
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: (Packages/manifest\.json|Assets/packages\.config)$
action: block
---

⚠️ **Change detected in package configuration file**

You are about to modify `Packages/manifest.json` or `Assets/packages.config`.

**You must use the AskUserQuestion tool to confirm with the user:**
- Specify the exact package names and versions being added, changed, or removed
- Explain why the package is needed
- Only proceed if the user explicitly approves

**If the user has already approved in the same conversation:**
This hook is for confirmation purposes. You may proceed if explicit approval was given in the immediately preceding exchange.