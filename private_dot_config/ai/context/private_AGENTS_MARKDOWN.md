# Markdown Standards and Best Practices

# APPLIES-TO: markdown

Standards for writing Markdown documentation.

## Table of Contents

- [Core Principles](#core-principles)
- [Formatting](#formatting)
- [Structure](#structure)
- [Common Patterns](#common-patterns)
- [AI Assistant Guidelines](#ai-assistant-guidelines)

## Core Principles

1. **Readability**: Plain text should be readable without rendering
2. **Consistency**: Use consistent formatting throughout
3. **Accessibility**: Write for screen readers and tools
4. **Portability**: Works across different Markdown renderers
5. **Maintainability**: Easy to update and extend

## Formatting

### Headers

Use ATX-style headers (`#`) with a space after:

```markdown
✅ Good

# H1 Header

## H2 Header

### H3 Header

❌ Bad
#H1 Header (no space)
##H2 Header

❌ Bad - Setext style
H1 Header
=========
```

**Header hierarchy**:

- Use only one H1 per document (title)
- Don't skip levels (H1 → H3)
- Keep headers short and descriptive

```markdown
# Document Title (H1)

## Section (H2)

### Subsection (H3)

#### Detail (H4)

Don't go deeper than H4 unless absolutely necessary
```

### Emphasis

```markdown
✅ Good
_italic_ or _italic_
**bold** or **bold**
**_bold italic_**

❌ Bad - inconsistent
_italic_ and _italic_ in same document
**bold** and **bold** in same document
```

**Pick one style and stick with it:**

- Asterisks `*` for italic, `**` for bold (common in Go, Rust docs)
- Underscores `_` for italic, `__` for bold (common in Python docs)

### Lists

**Unordered lists** - use `-` for consistency:

```markdown
✅ Good

- Item 1
- Item 2
  - Nested item
  - Another nested
- Item 3

❌ Bad - mixed markers

- Item 1

* Item 2

- Item 3
```

**Ordered lists** - use `1.` for all items (auto-numbering):

```markdown
✅ Good

1. First item
1. Second item
1. Third item

✅ Also good (explicit)

1. First item
2. Second item
3. Third item

❌ Bad - makes reordering harder

1. First item
2. Second item
3. Third item
```

**List spacing**:

```markdown
✅ Good - compact list

- Item 1
- Item 2
- Item 3

✅ Good - spaced list for longer content

- Item 1 with a longer description
  that spans multiple lines

- Item 2 also has longer content
  that needs space

- Item 3 continues the pattern
```

### Code

**Inline code** - use backticks:

```markdown
Use the `fmt.Println()` function to print output.
Set the `DEBUG` environment variable to `true`.
```

**Code blocks** - use fenced code blocks with language:

````markdown
✅ Good

```go
func main() {
    fmt.Println("Hello, World!")
}
```

```bash
npm install express
```

❌ Bad - no language specified

```
func main() {
    fmt.Println("Hello, World!")
}
```

❌ Bad - indented code blocks (not portable)
func main() {
fmt.Println("Hello, World!")
}
````

### Links

```markdown
✅ Good - inline links
[GitHub](https://github.com)
[Documentation](./docs/README.md)

✅ Good - reference links (for repeated URLs)
See the [documentation][docs] and [API reference][api].

[docs]: https://example.com/docs
[api]: https://example.com/api

❌ Bad - raw URLs (not descriptive)
See https://github.com/user/repo

✅ Good - autolinks for emails
<email@example.com>
```

### Images

```markdown
✅ Good - with alt text
![Project logo](./images/logo.png)
![Architecture diagram showing service connections](./diagrams/arch.png)

❌ Bad - no alt text
![](./images/logo.png)

✅ Good - reference style
![Logo][logo]

[logo]: ./images/logo.png "Company Logo"
```

### Tables

```markdown
✅ Good - aligned for readability
| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1 | Cell 2 | Cell 3 |
| Data | More | Values |

✅ Good - alignment specified
| Left | Center | Right |
|:-----|:------:|------:|
| L1 | C1 | R1 |
| L2 | C2 | R2 |

❌ Bad - not aligned (harder to maintain)
|Header 1|Header 2|Header 3|
|---|---|---|
|Cell 1|Cell 2|Cell 3|
```

### Horizontal Rules

Use three or more dashes, separated from content:

```markdown
✅ Good
Content above

---

Content below

❌ Bad - no spacing
Content above

---

Content below
```

### Blockquotes

```markdown
✅ Good

> This is a quote.
> It can span multiple lines.

✅ Good - nested quotes

> Main quote
>
> > Nested quote

✅ Good - with attribution

> The only way to do great work is to love what you do.
>
> — Steve Jobs
```

## Structure

### README.md Template

````markdown
# Project Name

Brief description of what this project does.

## Features

- Feature 1
- Feature 2
- Feature 3

## Installation

```bash
npm install project-name
```
````

## Usage

```javascript
const project = require("project-name");
project.doSomething();
```

## Documentation

See [full documentation](./docs/README.md).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT License - see [LICENSE](./LICENSE) file.

````

### Documentation Structure

```markdown
# Document Title

## Overview

Brief introduction to the topic.

## Prerequisites

- Requirement 1
- Requirement 2

## Getting Started

### Installation

Step-by-step installation instructions.

### Configuration

How to configure the system.

## Usage

### Basic Usage

Simple examples.

### Advanced Usage

More complex examples.

## API Reference

Detailed API documentation.

## Troubleshooting

Common issues and solutions.

## See Also

- [Related Doc 1](./doc1.md)
- [Related Doc 2](./doc2.md)
````

### ADR (Architecture Decision Record)

```markdown
# ADR-001: Use PostgreSQL for Primary Database

## Status

Accepted

## Context

We need a database for our application that supports:

- ACID transactions
- Complex queries with joins
- JSON data types
- Full-text search

## Decision

We will use PostgreSQL as our primary database.

## Consequences

### Positive

- Mature, battle-tested technology
- Excellent PostgreSQL support in our tech stack
- Strong community and documentation

### Negative

- More complex to scale horizontally than NoSQL
- Requires more operational expertise

## Alternatives Considered

- MySQL: Less feature-rich for our use case
- MongoDB: Doesn't support ACID transactions natively
```

## Common Patterns

### Command Documentation

````markdown
## Command: `deploy`

Deploy the application to production.

### Usage

```bash
cli deploy [options] <environment>
```
````

### Arguments

- `<environment>` - Target environment (staging, production)

### Options

- `-f, --force` - Force deployment without confirmation
- `--dry-run` - Show what would be deployed without deploying
- `-v, --verbose` - Enable verbose output

### Examples

```bash
# Deploy to staging
cli deploy staging

# Deploy to production with confirmation
cli deploy production

# Dry run
cli deploy --dry-run production
```

````

### API Endpoint Documentation

```markdown
## GET /api/users/:id

Get a user by ID.

### Parameters

| Name | Type   | Required | Description |
|------|--------|----------|-------------|
| id   | string | Yes      | User ID     |

### Query Parameters

| Name   | Type   | Required | Description      |
|--------|--------|----------|------------------|
| fields | string | No       | Comma-separated  |

### Response

```json
{
  "id": "user-123",
  "username": "johndoe",
  "email": "john@example.com"
}
````

### Error Responses

| Status | Description           |
| ------ | --------------------- |
| 404    | User not found        |
| 500    | Internal server error |

````

### Code Comment Blocks

```markdown
## Installation

Install dependencies:

```bash
npm install
````

Copy environment file:

```bash
cp .env.example .env
```

Start development server:

```bash
npm run dev
```

```

## AI Assistant Guidelines

### When Writing Documentation

1. **Structure first**: Plan the document outline
2. **Use templates**: Start with common patterns
3. **Be consistent**: Follow style throughout
4. **Add examples**: Show, don't just tell
5. **Link related docs**: Help users navigate
6. **Keep it current**: Date major updates

### Example AI Prompt

```

Create a README.md following .ai/context/AGENTS_MARKDOWN.md:

For: Go web service
Include:

- Installation instructions
- Configuration
- API examples
- Development setup
- Testing commands

````

### When Reviewing Markdown

Check for:
- [ ] One H1 per document
- [ ] Consistent header hierarchy
- [ ] Language specified on code blocks
- [ ] Alt text on images
- [ ] Descriptive link text
- [ ] Tables are aligned
- [ ] Lists use consistent markers
- [ ] Proper spacing around elements

### LazyVim for Markdown

```vim
# Keybindings from EDITORS.md
<leader>mp  " Preview markdown
<leader>mt  " Toggle task list item
<leader>ml  " Insert link
gx          " Open link under cursor

# Plugins
- markdown-preview.nvim
- vim-markdown-toc
````

## Best Practices

### Line Length

Keep lines under 80-100 characters for readability:

```markdown
✅ Good
This is a paragraph that wraps at a reasonable line length,
making it easy to read in any editor without horizontal
scrolling.

❌ Bad
This is a paragraph that goes on and on and on without any line breaks making it very difficult to read in text editors and causing horizontal scrolling which is annoying.
```

### Blank Lines

Use blank lines for readability:

```markdown
✅ Good

## Section

Content for this section.

## Next Section

Content for next section.

❌ Bad

## Section

Content for this section.

## Next Section

Content for next section.
```

### File Naming

```markdown
✅ Good
README.md
CONTRIBUTING.md
docs/installation.md
docs/api-reference.md

❌ Bad
readme.md (inconsistent case)
docs/Installation.md (inconsistent case)
docs/api_reference.md (inconsistent separator)
```

### TODO Comments

```markdown
<!-- TODO: Add performance benchmarks -->
<!-- FIXME: Update deprecated API calls -->
<!-- NOTE: This section needs review -->
```

## Common Tools

- **Linters**:

  ```bash
  markdownlint README.md
  vale docs/
  ```

- **Formatters**:

  ```bash
  prettier --write "**/*.md"
  ```

- **Table of Contents**:
  ```bash
  # Auto-generate TOC
  markdown-toc -i README.md
  ```

## Version History

- 2024-01-24: Initial version
