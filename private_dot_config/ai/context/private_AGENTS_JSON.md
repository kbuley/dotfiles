# JSON Standards and Best Practices

# APPLIES-TO: json, jsonc

Standards for writing JSON configuration and data files.

## Table of Contents

- [Core Principles](#core-principles)
- [Formatting](#formatting)
- [Structure](#structure)
- [Common Patterns](#common-patterns)
- [Security](#security)
- [AI Assistant Guidelines](#ai-assistant-guidelines)

## Core Principles

1. **Valid JSON**: Always produce valid, parseable JSON
2. **Consistent Formatting**: Use consistent indentation and style
3. **Meaningful Keys**: Use clear, descriptive property names
4. **Type Safety**: Be explicit about types
5. **Schema Validation**: Use JSON Schema where appropriate

## Formatting

### Indentation

**Use 2 spaces** (consistent with other formats):

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0",
    "dotenv": "^16.0.0"
  }
}
```

### Key Naming

Use consistent naming conventions:

```json
{
  "camelCase": "for JavaScript/TypeScript",
  "snake_case": "for Python/Ruby",
  "kebab-case": "for URLs/slugs",
  "PascalCase": "for type names"
}
```

**Choose one style and stick with it:**

```json
// ✅ Good - consistent camelCase
{
  "firstName": "John",
  "lastName": "Doe",
  "emailAddress": "john@example.com"
}

// ❌ Bad - mixed styles
{
  "firstName": "John",
  "last_name": "Doe",
  "email-address": "john@example.com"
}
```

### Property Order

Logical ordering improves readability:

```json
{
  "name": "package-name",
  "version": "1.0.0",
  "description": "Package description",
  "main": "index.js",
  "scripts": {
    "test": "jest",
    "build": "tsc"
  },
  "dependencies": {},
  "devDependencies": {}
}
```

### Trailing Commas

**JSON does not allow trailing commas:**

```json
// ❌ Invalid - trailing comma
{
  "name": "example",
  "version": "1.0.0",
}

// ✅ Valid - no trailing comma
{
  "name": "example",
  "version": "1.0.0"
}
```

### String Escaping

Properly escape special characters:

```json
{
  "path": "C:\\Users\\john\\file.txt",
  "message": "He said \"Hello\"",
  "newline": "Line 1\nLine 2",
  "unicode": "Copyright \u00a9 2024"
}
```

## Structure

### Flat vs Nested

Choose based on use case:

```json
// ✅ Good - flat for simple config
{
  "apiKey": "abc123",
  "timeout": 30,
  "retries": 3
}

// ✅ Good - nested for complex config
{
  "api": {
    "key": "abc123",
    "endpoint": "https://api.example.com",
    "timeout": 30
  },
  "retry": {
    "enabled": true,
    "maxAttempts": 3,
    "backoff": "exponential"
  }
}

// ❌ Bad - unnecessary nesting
{
  "config": {
    "settings": {
      "api": {
        "key": "abc123"
      }
    }
  }
}
```

### Arrays

Consistent formatting for readability:

```json
// ✅ Good - inline for simple values
{
  "ports": [80, 443, 8080],
  "tags": ["web", "api", "production"]
}

// ✅ Good - multi-line for objects
{
  "users": [
    {
      "id": 1,
      "name": "Alice"
    },
    {
      "id": 2,
      "name": "Bob"
    }
  ]
}

// ❌ Bad - mixed formatting
{
  "users": [{"id": 1, "name": "Alice"},
    {
      "id": 2,
      "name": "Bob"
    }]
}
```

## Common Patterns

### package.json (Node.js)

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "description": "Project description",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "test": "vitest",
    "lint": "eslint src/**/*.ts",
    "format": "prettier --write src/**/*.ts"
  },
  "keywords": ["typescript", "api"],
  "author": "Your Name <email@example.com>",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.0",
    "dotenv": "^16.0.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.17",
    "tsx": "^4.0.0",
    "typescript": "^5.0.0",
    "vitest": "^1.0.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
```

### tsconfig.json (TypeScript)

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### .eslintrc.json (ESLint)

```json
{
  "env": {
    "node": true,
    "es2022": true
  },
  "extends": ["eslint:recommended", "plugin:@typescript-eslint/recommended"],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "plugins": ["@typescript-eslint"],
  "rules": {
    "no-console": "warn",
    "@typescript-eslint/no-unused-vars": [
      "error",
      {
        "argsIgnorePattern": "^_"
      }
    ]
  }
}
```

### API Response Format

```json
{
  "data": {
    "id": "user-123",
    "type": "user",
    "attributes": {
      "username": "johndoe",
      "email": "john@example.com",
      "createdAt": "2024-01-24T00:00:00Z"
    }
  },
  "meta": {
    "requestId": "req-abc123",
    "timestamp": "2024-01-24T00:00:00Z"
  }
}
```

### Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      },
      {
        "field": "age",
        "message": "Must be greater than 0"
      }
    ]
  },
  "meta": {
    "requestId": "req-abc123",
    "timestamp": "2024-01-24T00:00:00Z"
  }
}
```

## Security

### Sensitive Data

**Never commit secrets in JSON:**

```json
// ❌ Bad - hardcoded secrets
{
  "database": {
    "password": "super-secret-password"
  },
  "apiKey": "sk-1234567890"
}

// ✅ Good - use environment variables or secret management
{
  "database": {
    "passwordEnv": "DB_PASSWORD"
  },
  "apiKeyEnv": "API_KEY"
}
```

### Input Validation

Use JSON Schema for validation:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["name", "email"],
  "properties": {
    "name": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "email": {
      "type": "string",
      "format": "email"
    },
    "age": {
      "type": "integer",
      "minimum": 0,
      "maximum": 150
    }
  },
  "additionalProperties": false
}
```

## AI Assistant Guidelines

### When Generating JSON

1. **Valid JSON**: Always produce parseable JSON
2. **Schema**: Include $schema reference when applicable
3. **Consistent naming**: Pick a convention (camelCase, snake_case)
4. **Logical structure**: Group related properties
5. **Comments**: Use separate documentation (JSON doesn't support comments)
6. **No trailing commas**: JSON is strict about syntax

### Example AI Prompt

```
Create a package.json following .ai/context/AGENTS_JSON.md:

Requirements:
- TypeScript project
- Express.js dependency
- ESM modules
- Testing with Vitest
- Linting with ESLint
- Include all standard fields
```

### When Reviewing JSON

Check for:

- [ ] Valid JSON syntax (no trailing commas)
- [ ] Consistent key naming convention
- [ ] Logical property ordering
- [ ] No hardcoded secrets
- [ ] Schema validation where applicable
- [ ] Proper escaping of special characters

### JSON vs JSON5 vs JSONC

**JSON** (strict):

```json
{
  "name": "example"
}
```

**JSON5** (relaxed, allows comments and trailing commas):

```json5
{
  // This is a comment
  name: "example", // Trailing comma OK
}
```

**JSONC** (JSON with Comments, used by VSCode):

```jsonc
{
  // This is a comment
  "name": "example",
}
```

**Use JSON by default** unless the tool explicitly supports JSON5/JSONC.

### Common Tools

- **jq**: JSON processor

  ```bash
  jq '.name' package.json
  jq '.dependencies | keys' package.json
  ```

- **JSON Schema validators**:

  ```bash
  ajv validate -s schema.json -d data.json
  ```

- **Formatters**:
  ```bash
  jq . unformatted.json > formatted.json
  prettier --write *.json
  ```

## Examples by Use Case

### Configuration File

```json
{
  "app": {
    "name": "my-application",
    "version": "1.0.0",
    "environment": "production"
  },
  "server": {
    "host": "0.0.0.0",
    "port": 8080,
    "timeout": 30000
  },
  "database": {
    "host": "localhost",
    "port": 5432,
    "name": "myapp",
    "poolSize": 10,
    "ssl": true
  },
  "logging": {
    "level": "info",
    "format": "json",
    "outputs": ["stdout", "file"]
  },
  "features": {
    "caching": true,
    "rateLimiting": true,
    "debug": false
  }
}
```

### REST API Payload

```json
{
  "data": {
    "type": "article",
    "attributes": {
      "title": "Understanding JSON",
      "body": "Content here...",
      "published": true,
      "publishedAt": "2024-01-24T12:00:00Z",
      "tags": ["json", "tutorial", "web"]
    },
    "relationships": {
      "author": {
        "data": {
          "type": "user",
          "id": "user-123"
        }
      }
    }
  }
}
```

### Localization File

```json
{
  "en": {
    "common": {
      "save": "Save",
      "cancel": "Cancel",
      "delete": "Delete"
    },
    "errors": {
      "required": "This field is required",
      "invalidEmail": "Please enter a valid email"
    }
  },
  "es": {
    "common": {
      "save": "Guardar",
      "cancel": "Cancelar",
      "delete": "Eliminar"
    },
    "errors": {
      "required": "Este campo es obligatorio",
      "invalidEmail": "Por favor ingrese un correo válido"
    }
  }
}
```

## Best Practices Summary

✅ **Do:**

- Use 2-space indentation
- Validate with JSON Schema
- Keep consistent naming convention
- Order properties logically
- Use meaningful key names
- Properly escape special characters

❌ **Don't:**

- Use trailing commas
- Mix naming conventions
- Hardcode secrets
- Create unnecessarily deep nesting
- Use comments (not valid JSON)

## Version History

- 2024-01-24: Initial version
