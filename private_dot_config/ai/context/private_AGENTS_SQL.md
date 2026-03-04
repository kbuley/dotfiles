# SQL Standards and Best Practices

# APPLIES-TO: sql

Standards for writing SQL queries, schema definitions, and database operations.

## Table of Contents

- [Core Principles](#core-principles)
- [Naming Conventions](#naming-conventions)
- [Schema Design](#schema-design)
- [Query Patterns](#query-patterns)
- [Indexes and Performance](#indexes-and-performance)
- [Migrations](#migrations)
- [Security](#security)
- [AI Assistant Guidelines](#ai-assistant-guidelines)

## Core Principles

1. **Consistency**: Use consistent naming and formatting
2. **Readability**: SQL should be self-documenting
3. **Performance**: Consider query plans and indexes
4. **Safety**: Use transactions and constraints
5. **Portability**: Avoid vendor-specific features when possible

## Naming Conventions

### Tables

```sql
-- ✅ Good - plural, snake_case
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY
);

CREATE TABLE order_items (
    id BIGSERIAL PRIMARY KEY
);

-- ❌ Bad - singular or mixed case
CREATE TABLE user (
    id BIGSERIAL PRIMARY KEY
);

CREATE TABLE OrderItems (
    id BIGSERIAL PRIMARY KEY
);
```

### Columns

```sql
-- ✅ Good - descriptive, snake_case
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email_address VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- ❌ Bad - abbreviations or unclear names
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    eml VARCHAR(255),
    dt TIMESTAMP,
    active BOOLEAN
);
```

### Indexes

```sql
-- ✅ Good - descriptive with table name
CREATE INDEX idx_users_email ON users(email_address);
CREATE INDEX idx_orders_user_id_created_at ON orders(user_id, created_at);
CREATE UNIQUE INDEX idx_users_email_unique ON users(email_address);

-- ❌ Bad - generic names
CREATE INDEX idx1 ON users(email_address);
CREATE INDEX email_index ON users(email_address);
```

### Foreign Keys

```sql
-- ✅ Good - table_name_singular_id pattern
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id),
    product_id BIGINT NOT NULL REFERENCES products(id)
);

-- ❌ Bad - inconsistent naming
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    userId BIGINT NOT NULL REFERENCES users(id),
    created TIMESTAMP
);
```

## Schema Design

### Primary Keys

```sql
-- ✅ Good - BIGSERIAL for auto-increment
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL
);

-- ✅ Good - UUID for distributed systems
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(50) NOT NULL,
    occurred_at TIMESTAMP NOT NULL
);

-- ✅ Good - composite primary key when appropriate
CREATE TABLE user_roles (
    user_id BIGINT NOT NULL REFERENCES users(id),
    role_id BIGINT NOT NULL REFERENCES roles(id),
    PRIMARY KEY (user_id, role_id)
);

-- ❌ Bad - no primary key
CREATE TABLE logs (
    message TEXT,
    created_at TIMESTAMP
);
```

### Timestamps

```sql
-- ✅ Good - always include created_at and updated_at
CREATE TABLE posts (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ✅ Good - add trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_posts_updated_at
    BEFORE UPDATE ON posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### Constraints

```sql
-- ✅ Good - comprehensive constraints
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    username VARCHAR(50) NOT NULL,
    age INTEGER,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    -- Unique constraints
    CONSTRAINT users_email_unique UNIQUE (email),
    CONSTRAINT users_username_unique UNIQUE (username),

    -- Check constraints
    CONSTRAINT users_age_check CHECK (age >= 0 AND age <= 150),
    CONSTRAINT users_status_check CHECK (status IN ('active', 'inactive', 'suspended')),
    CONSTRAINT users_email_format_check CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- ✅ Good - foreign key with ON DELETE
CREATE TABLE posts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,

    CONSTRAINT posts_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);
```

### Soft Deletes

```sql
-- ✅ Good - soft delete pattern
CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Index for active records
CREATE INDEX idx_products_active ON products(id) WHERE deleted_at IS NULL;

-- Soft delete function
CREATE OR REPLACE FUNCTION soft_delete_product(product_id BIGINT)
RETURNS VOID AS $$
BEGIN
    UPDATE products
    SET deleted_at = NOW()
    WHERE id = product_id AND deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql;
```

## Query Patterns

### SELECT Queries

```sql
-- ✅ Good - explicit columns, proper formatting
SELECT
    u.id,
    u.email,
    u.username,
    p.title AS post_title,
    p.created_at AS post_created_at
FROM users u
INNER JOIN posts p ON p.user_id = u.id
WHERE u.is_active = TRUE
    AND p.published_at IS NOT NULL
ORDER BY p.created_at DESC
LIMIT 10;

-- ❌ Bad - SELECT *, unclear joins
SELECT * FROM users, posts WHERE users.id = posts.user_id;

-- ✅ Good - use CTEs for complex queries
WITH active_users AS (
    SELECT id, email, username
    FROM users
    WHERE is_active = TRUE
        AND created_at > NOW() - INTERVAL '1 year'
),
user_post_counts AS (
    SELECT
        user_id,
        COUNT(*) AS post_count
    FROM posts
    WHERE published_at IS NOT NULL
    GROUP BY user_id
)
SELECT
    au.email,
    au.username,
    COALESCE(upc.post_count, 0) AS post_count
FROM active_users au
LEFT JOIN user_post_counts upc ON upc.user_id = au.id
ORDER BY post_count DESC;
```

### INSERT Queries

```sql
-- ✅ Good - explicit columns
INSERT INTO users (email, username, created_at, updated_at)
VALUES
    ('user1@example.com', 'user1', NOW(), NOW()),
    ('user2@example.com', 'user2', NOW(), NOW());

-- ✅ Good - INSERT with RETURNING
INSERT INTO users (email, username, created_at, updated_at)
VALUES ('user@example.com', 'username', NOW(), NOW())
RETURNING id, created_at;

-- ✅ Good - INSERT ON CONFLICT (upsert)
INSERT INTO user_preferences (user_id, preference_key, preference_value)
VALUES (1, 'theme', 'dark')
ON CONFLICT (user_id, preference_key)
DO UPDATE SET
    preference_value = EXCLUDED.preference_value,
    updated_at = NOW();

-- ❌ Bad - no column list
INSERT INTO users VALUES (1, 'email@example.com', 'username');
```

### UPDATE Queries

```sql
-- ✅ Good - explicit WHERE clause
UPDATE users
SET
    email = 'newemail@example.com',
    updated_at = NOW()
WHERE id = 123;

-- ✅ Good - UPDATE with FROM
UPDATE posts
SET view_count = view_count + daily_views.views
FROM (
    SELECT post_id, COUNT(*) AS views
    FROM post_views
    WHERE viewed_at > NOW() - INTERVAL '1 day'
    GROUP BY post_id
) AS daily_views
WHERE posts.id = daily_views.post_id;

-- ✅ Good - UPDATE with RETURNING
UPDATE users
SET is_active = FALSE, updated_at = NOW()
WHERE last_login < NOW() - INTERVAL '1 year'
RETURNING id, email;

-- ❌ Bad - UPDATE without WHERE (updates all rows!)
UPDATE users SET is_active = FALSE;
```

### DELETE Queries

```sql
-- ✅ Good - explicit WHERE clause
DELETE FROM sessions
WHERE expires_at < NOW();

-- ✅ Good - DELETE with RETURNING
DELETE FROM old_logs
WHERE created_at < NOW() - INTERVAL '90 days'
RETURNING id, created_at;

-- ✅ Good - prefer soft delete
UPDATE products
SET deleted_at = NOW()
WHERE id = 123;

-- ❌ Bad - DELETE without WHERE
DELETE FROM sessions;
```

### Joins

```sql
-- ✅ Good - explicit join types, table aliases
SELECT
    u.id,
    u.username,
    o.order_number,
    o.total_amount
FROM users u
INNER JOIN orders o ON o.user_id = u.id
WHERE o.created_at > NOW() - INTERVAL '30 days'
ORDER BY o.created_at DESC;

-- ✅ Good - LEFT JOIN with NULL check
SELECT
    u.id,
    u.username,
    COUNT(o.id) AS order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.username
ORDER BY order_count DESC;

-- ❌ Bad - implicit join (old style)
SELECT users.id, orders.order_number
FROM users, orders
WHERE users.id = orders.user_id;
```

## Indexes and Performance

### Index Types

```sql
-- ✅ Good - B-tree index (default, most common)
CREATE INDEX idx_users_email ON users(email);

-- ✅ Good - Composite index (order matters!)
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);

-- ✅ Good - Partial index
CREATE INDEX idx_users_active_email ON users(email) WHERE is_active = TRUE;

-- ✅ Good - GIN index for JSONB
CREATE INDEX idx_products_metadata ON products USING GIN(metadata);

-- ✅ Good - GiST index for full-text search
CREATE INDEX idx_posts_content_search ON posts USING GiST(to_tsvector('english', content));

-- ✅ Good - Unique index
CREATE UNIQUE INDEX idx_users_email_unique ON users(email) WHERE deleted_at IS NULL;
```

### Query Optimization

```sql
-- ✅ Good - use EXPLAIN ANALYZE
EXPLAIN ANALYZE
SELECT u.username, COUNT(p.id) AS post_count
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
GROUP BY u.id, u.username;

-- ✅ Good - avoid SELECT COUNT(*) on large tables
SELECT reltuples::BIGINT AS approximate_count
FROM pg_class
WHERE relname = 'users';

-- ✅ Good - use EXISTS instead of COUNT
SELECT EXISTS (
    SELECT 1
    FROM users
    WHERE email = 'test@example.com'
) AS email_exists;

-- ❌ Bad - SELECT COUNT(*) just to check existence
SELECT COUNT(*) FROM users WHERE email = 'test@example.com';

-- ✅ Good - pagination with OFFSET/LIMIT
SELECT id, username, created_at
FROM users
ORDER BY created_at DESC
LIMIT 20 OFFSET 40;

-- ✅ Better - keyset pagination (more efficient)
SELECT id, username, created_at
FROM users
WHERE created_at < '2024-01-20 10:00:00'
ORDER BY created_at DESC
LIMIT 20;
```

## Migrations

### Migration Files

```sql
-- migrations/001_create_users_table.up.sql
-- ✅ Good - idempotent migration
BEGIN;

CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT users_email_unique UNIQUE (email),
    CONSTRAINT users_username_unique UNIQUE (username)
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

COMMIT;

-- migrations/001_create_users_table.down.sql
BEGIN;

DROP TABLE IF EXISTS users CASCADE;

COMMIT;
```

### Adding Columns

```sql
-- migrations/002_add_users_last_login.up.sql
BEGIN;

-- ✅ Good - add nullable column first
ALTER TABLE users
ADD COLUMN last_login TIMESTAMP NULL;

-- Create index
CREATE INDEX idx_users_last_login ON users(last_login);

COMMIT;

-- migrations/002_add_users_last_login.down.sql
BEGIN;

ALTER TABLE users
DROP COLUMN IF EXISTS last_login;

COMMIT;
```

### Data Migrations

```sql
-- migrations/003_migrate_user_status.up.sql
-- ✅ Good - separate data migration
BEGIN;

-- Add new column
ALTER TABLE users
ADD COLUMN status VARCHAR(20) NULL;

-- Migrate data in batches
UPDATE users
SET status = CASE
    WHEN is_active = TRUE THEN 'active'
    WHEN is_active = FALSE THEN 'inactive'
END
WHERE status IS NULL;

-- Make NOT NULL after data migration
ALTER TABLE users
ALTER COLUMN status SET NOT NULL;

-- Add constraint
ALTER TABLE users
ADD CONSTRAINT users_status_check
CHECK (status IN ('active', 'inactive', 'suspended'));

-- Drop old column
ALTER TABLE users
DROP COLUMN is_active;

COMMIT;
```

## Security

### SQL Injection Prevention

```sql
-- ✅ Good - use parameterized queries (application code)
-- Go example following AGENTS_GO.md
db.Query("SELECT * FROM users WHERE email = $1", email)

-- Python example following AGENTS_PYTHON.md
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))

-- ❌ Bad - string concatenation
db.Query("SELECT * FROM users WHERE email = '" + email + "'")
```

### Row-Level Security (RLS)

```sql
-- ✅ Good - enable RLS for multi-tenant
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY posts_isolation_policy ON posts
    USING (user_id = current_setting('app.current_user_id')::BIGINT);

-- Grant access
GRANT SELECT, INSERT, UPDATE, DELETE ON posts TO app_user;
```

### Permissions

```sql
-- ✅ Good - least privilege
CREATE ROLE app_reader;
GRANT CONNECT ON DATABASE myapp TO app_reader;
GRANT USAGE ON SCHEMA public TO app_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_reader;

CREATE ROLE app_writer;
GRANT app_reader TO app_writer;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_writer;

-- ❌ Bad - overly permissive
GRANT ALL PRIVILEGES ON DATABASE myapp TO app_user;
```

## AI Assistant Guidelines

### When Writing SQL

1. **Use explicit formatting**: Uppercase keywords, lowercase identifiers
2. **Name clearly**: Tables plural, columns descriptive
3. **Add constraints**: Primary keys, foreign keys, check constraints
4. **Include indexes**: Performance-critical queries
5. **Use transactions**: Wrap DDL in BEGIN/COMMIT
6. **Document**: Comments for complex logic

### Example AI Prompt

```
Create SQL schema following .ai/context/AGENTS_SQL.md:

For: E-commerce system
Tables needed:
- users (authentication)
- products (catalog)
- orders (purchases)
- order_items (line items)

Requirements:
- Proper constraints and indexes
- Soft deletes for products
- Timestamps on all tables
- Foreign keys with cascades
```

### When Reviewing SQL

Check for:

- [ ] Consistent naming (snake_case, plural tables)
- [ ] Primary keys on all tables
- [ ] created_at/updated_at timestamps
- [ ] Proper indexes for foreign keys
- [ ] Check constraints for enums
- [ ] NOT NULL where appropriate
- [ ] Explicit column lists in INSERT
- [ ] WHERE clauses in UPDATE/DELETE
- [ ] Use of CTEs for complex queries
- [ ] Parameterized queries (no string concat)

### PostgreSQL-Specific Features

```sql
-- ✅ JSONB for flexible data
CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB
);

CREATE INDEX idx_products_metadata ON products USING GIN(metadata);

-- Query JSONB
SELECT * FROM products WHERE metadata->>'color' = 'red';

-- ✅ Arrays
CREATE TABLE posts (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    tags TEXT[] NOT NULL DEFAULT '{}'
);

-- Query arrays
SELECT * FROM posts WHERE 'postgres' = ANY(tags);

-- ✅ Full-text search
ALTER TABLE posts ADD COLUMN search_vector tsvector;

CREATE INDEX idx_posts_search ON posts USING GIN(search_vector);

UPDATE posts
SET search_vector = to_tsvector('english', title || ' ' || content);

-- Query full-text
SELECT * FROM posts WHERE search_vector @@ to_tsquery('postgres & database');
```

### LazyVim Integration

```vim
# Keybindings from EDITORS.md
<leader>db    " Database UI
<leader>ff    " Find SQL files

# SQL formatting
:!pg_format % " Format SQL file
```

## Best Practices Summary

✅ **Do:**

- Use snake_case for tables and columns
- Always have primary keys
- Include created_at/updated_at timestamps
- Use explicit column lists in SELECT and INSERT
- Add WHERE clauses to UPDATE/DELETE
- Use transactions for DDL
- Create indexes for foreign keys
- Use parameterized queries
- Prefer soft deletes for user data
- Use CTEs for complex queries

❌ **Don't:**

- Use SELECT \* in production code
- Skip indexes on foreign keys
- Update without WHERE clause
- Concatenate strings in SQL queries
- Use reserved words as identifiers
- Skip constraints
- Forget to handle NULL values
- Use cursors when set operations work
- Mix camelCase and snake_case

## Tools

- **psql**: PostgreSQL command-line client

  ```bash
  psql -U postgres -d mydb
  ```

- **pg_dump**: Backup database

  ```bash
  pg_dump -U postgres mydb > backup.sql
  ```

- **EXPLAIN ANALYZE**: Query performance

  ```sql
  EXPLAIN ANALYZE SELECT ...
  ```

- **pgcli**: Enhanced PostgreSQL CLI with autocomplete
  ```bash
  pgcli postgresql://localhost/mydb
  ```

## References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Use The Index, Luke](https://use-the-index-luke.com/)
- [SQL Style Guide](https://www.sqlstyle.guide/)

## Version History

- 2024-01-24: Initial version
