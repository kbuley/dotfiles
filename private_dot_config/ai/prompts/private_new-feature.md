---
name: New Feature
interaction: chat
description: Implement a new feature against language-specific standards
opts:
  alias: feature
  is_slash_cmd: true
  auto_submit: true
  modes:
    - n
    - v
  stop_context_insertion: true
---

## user

Implement a new feature in ${context.filetype} following the standards in `AGENTS_${context.filetype}.md`.

**Feature**: [Name and description]

**Requirements**:

- [Requirement 1]
- [Requirement 2]

**Constraints**:

- [Constraint 1]

Existing code for context:

#{buffer}

Provide:

1. **Implementation** — Complete code following all patterns in `AGENTS_${context.filetype}.md`
2. **Tests** — Following the test patterns for ${context.filetype}
3. **Usage example** — Minimal working example
4. **Documentation** — Inline comments where non-obvious

Structure your response as:

### Implementation

```${context.filetype}
[Feature code]
```

### Tests

```${context.filetype}
[Test code]
```

### Usage

```${context.filetype}
[Example]
```
