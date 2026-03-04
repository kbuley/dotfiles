---
name: Debug
interaction: chat
description: Debug an issue against language-specific standards
opts:
  alias: debug
  is_slash_cmd: true
  auto_submit: true
  modes:
    - n
    - v
  stop_context_insertion: true
---

## user

Help me debug this ${context.filetype} issue against the standards in `AGENTS_${context.filetype}.md`.

#{buffer}

**Problem**: [Describe what is wrong]

**Error or unexpected behavior**: [Paste error message or describe what happens]

**Expected behavior**: [What should happen instead]

Provide:

1. **Root cause** — What is causing this, explained clearly
2. **Fix** — Corrected code following `AGENTS_${context.filetype}.md` patterns
3. **Why it works** — Brief explanation of the fix
4. **Regression test** — A test that would have caught this, following test patterns for ${context.filetype}
5. **Prevention** — How to avoid this class of issue in future

Structure your response as:

### Root Cause

[Explanation]

### Fix

```${context.filetype}
[Fixed code]
```

### Test

```${context.filetype}
[Regression test]
```

### Prevention

- [Actionable advice]
