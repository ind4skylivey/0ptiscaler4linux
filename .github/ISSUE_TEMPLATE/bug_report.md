---
name: Bug Report
about: Report a reproducible bug in OptiScaler Universal
title: '[BUG] '
labels: bug, needs-triage
assignees: ''
---

<!--
  ┌─────────────────────────────────────────────────────────────────┐
  │  READ BEFORE SUBMITTING                                         │
  │                                                                 │
  │  Issues missing required information will be CLOSED without     │
  │  response. We are not a help desk — provide diagnostics or      │
  │  your issue will be treated as invalid.                         │
  │                                                                 │
  │  For questions, configuration help, or general discussion,     │
  │  use Discussions:                                               │
  │  https://github.com/ind4skylivey/0ptiscaler4linux/discussions   │
  └─────────────────────────────────────────────────────────────────┘
-->

## Pre-Submission Checklist

**You MUST confirm ALL of the following before submitting. Incomplete issues will be closed.**

- [ ] I have searched [existing issues](https://github.com/ind4skylivey/0ptiscaler4linux/issues?q=is%3Aissue) and confirmed this bug has NOT already been reported
- [ ] I have read the [documentation/wiki](https://github.com/ind4skylivey/0ptiscaler4linux/wiki) and the issue is not addressed there
- [ ] This is a reproducible bug in OptiScaler Universal scripts — NOT a game-specific issue, driver problem, or general Linux gaming question
- [ ] I am reporting a bug in the **latest version** of the project (not an outdated fork or old release)
- [ ] I understand that if I do not provide the required system information and logs below, my issue will be closed without further discussion

## Bug Description

<!-- Clearly describe the bug. One paragraph is usually enough. -->


## System Information

**ALL fields below are REQUIRED. Issues with incomplete system info will be closed.**

| Field | Value |
|-------|-------|
| **GPU** | <!-- e.g., AMD Radeon RX 7900 XTX or NVIDIA RTX 4070 --> |
| **GPU Driver** | <!-- e.g., Mesa 25.2.0 or nvidia 575.57.08 --> |
| **Distribution** | <!-- e.g., Arch Linux, CachyOS, Fedora 41 --> |
| **Kernel** | <!-- paste output of: uname -r --> |
| **Wine/Proton Version** | <!-- e.g., Proton 9.0-4, Wine-GE 8-26 --> |
| **OptiScaler Version** | <!-- version from install.sh output or git commit hash --> |

## Steps to Reproduce

<!-- Numbered steps that reliably trigger the bug. "It doesn't work" is NOT a valid reproduction. -->

1.
2.
3.

## Expected Behavior

<!-- What should happen when following the steps above? -->


## Actual Behavior

<!-- What actually happens? Include exact error messages if any. -->


## Diagnostic Output

**REQUIRED**: Run the following command and paste the FULL output below. Issues without this output will be closed.

```bash
bash scripts/diagnose.sh --verbose
```

<details>
<summary>Click to expand — paste output here</summary>

```
PASTE FULL DIAGNOSE.SH OUTPUT HERE
```

</details>

## Logs

Attach or paste relevant logs. Remove sections that do not apply.

<details>
<summary>OptiScaler.log</summary>

```
PASTE LOG CONTENTS HERE
```

</details>

<details>
<summary>Terminal output from install.sh</summary>

```
PASTE TERMINAL OUTPUT HERE
```

</details>

## Additional Context

<!-- Anything else that might help reproduce or understand the bug. Screenshots, videos, etc. -->
