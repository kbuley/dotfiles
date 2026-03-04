---
name: Code Review
interaction: chat
description: Review code against language-specific standards
opts:
  alias: review
  is_slash_cmd: true
  auto_submit: true
  modes:
    - n
    - v
  stop_context_insertion: true
---

## user

Please review this ${context.filetype} code against the standards in `AGENTS_${context.filetype}.md`.

#{buffer}

Focus on:

1. **Standards compliance** — Does it follow the patterns in `AGENTS_${context.filetype}.md`?
2. **Type safety** — Are type annotations correct and complete for ${context.filetype}?
3. **Error handling** — Is error handling idiomatic and robust?
4. **Testing** — Are tests needed? Do they follow the patterns for ${context.filetype}?
5. **Documentation** — Is it properly documented?
6. **Performance** — Any obvious inefficiencies?
7. **Security** — Any security concerns?

Structure your feedback as:

### Compliance Issues

- [Issue with line reference]

### Suggestions

- [Improvement with example]

### Approved

- [What's already correct]

### Refactored Code

[Improved version if changes are substantial]
