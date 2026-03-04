---
name: Refactor
interaction: chat
description: Refactor code to meet language-specific standards
opts:
  alias: refactor
  is_slash_cmd: true
  auto_submit: true
  modes:
    - n
    - v
  stop_context_insertion: true
---

## user

Refactor this ${context.filetype} code to follow the standards in `AGENTS_${context.filetype}.md`.

#{buffer}

**Goal**: [Describe what needs to change — e.g. "extract interfaces", "add type hints", "replace loops with Graph API"]

Requirements:

1. Follow all patterns in `AGENTS_${context.filetype}.md`
2. Maintain backward compatibility, or explicitly list breaking changes
3. Update or add tests following the test patterns for ${context.filetype}

Structure your response as:

### Refactored Code

```${context.filetype}
[Complete refactored code]
```

### Changes Made

- [What changed and why, referencing the relevant pattern]

### Breaking Changes

- [Any breaking changes and how callers should migrate, or "None"]

### Tests

```${context.filetype}
[Updated or new tests]
```
