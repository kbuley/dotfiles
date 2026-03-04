# AGENTS.md - Go (Golang)

# APPLIES-TO: go

This document provides guidance for AI assistants working with Go code in this repository.

## Project Context

This repository contains Go applications and tools for system administration, cloud infrastructure automation, API services, and CLI utilities. Code should follow Go best practices, be idiomatic, maintainable, and production-ready.

## Core Principles

### 1. Idiomatic Go

- Follow the [Effective Go](https://go.dev/doc/effective_go) guidelines
- Use `gofmt` for formatting (enforced via CI/CD)
- Run `go vet` and `golangci-lint` before committing
- Follow standard Go project layout
- Embrace simplicity over cleverness
- **Accept interfaces, return concrete types** - Functions should accept the most flexible type (interface) but return the most specific type (concrete struct)
- **Prefer functional options over builder pattern** - Use functional options for configurable constructors instead of builder pattern or config structs with many fields

### 2. Error Handling

- Always check errors explicitly
- Return errors rather than panicking (except in truly exceptional cases)
- Wrap errors with context using `fmt.Errorf` with `%w` verb
- Use sentinel errors and custom error types when appropriate
- Never ignore errors with `_` unless explicitly justified

### 3. Concurrency

- Use goroutines and channels appropriately
- Avoid goroutine leaks by ensuring proper cleanup
- Use `context.Context` for cancellation and timeouts
- Protect shared state with mutexes or channels
- Prefer channels for communication, mutexes for state

### 4. Testing

- Write table-driven tests
- Aim for >80% code coverage for critical paths
- Use subtests with `t.Run()` for organization
- Mock external dependencies
- Test error cases as thoroughly as success cases

## Project Structure

### Standard Layout

```
.
├── cmd/                    # Main applications
│   ├── app1/
│   │   └── main.go
│   └── app2/
│       └── main.go
├── pkg/                    # Public libraries
│   ├── azure/
│   │   ├── client.go
│   │   ├── client_test.go
│   │   └── doc.go
│   └── config/
│       ├── config.go
│       └── config_test.go
├── internal/               # Private application code
│   ├── server/
│   │   ├── handlers.go
│   │   ├── handlers_test.go
│   │   └── middleware.go
│   └── database/
│       ├── postgres.go
│       └── postgres_test.go
├── api/                    # API definitions (OpenAPI, Protocol Buffers)
│   └── v1/
│       └── api.proto
├── configs/                # Configuration files
│   ├── development.yaml
│   └── production.yaml
├── scripts/                # Build and utility scripts
│   ├── build.sh
│   └── lint.sh
├── test/                   # Integration and e2e tests
│   └── integration/
│       └── api_test.go
├── docs/                   # Documentation
│   └── architecture.md
├── tools.go               # Tool dependencies (optional but recommended)
├── .golangci.yml          # Linter configuration
├── go.mod                 # Go module definition
├── go.sum                 # Dependency checksums
├── Makefile               # Build automation
└── README.md              # Project documentation
```

### Tool Dependency Management

Go 1.16+ supports tracking tool dependencies in `go.mod` using a `tools.go` file. This ensures all team members use the same tool versions.

**Create tools.go:**

```go
//go:build tools
// +build tools

// Package tools tracks tool dependencies.
// Import tools here to track their versions in go.mod.
package tools

import (
	_ "github.com/bufbuild/buf/cmd/buf"
	_ "github.com/golangci/golangci-lint/cmd/golangci-lint"
	_ "golang.org/x/tools/cmd/goimports"
	_ "google.golang.org/grpc/cmd/protoc-gen-go-grpc"
	_ "google.golang.org/protobuf/cmd/protoc-gen-go"
)
```

**Benefits:**

- Tool versions are tracked in `go.mod`
- Consistent versions across team and CI/CD
- No need to install tools globally
- Tools are cached in Go's module cache

**Usage:**

```bash
# Tools are automatically available via 'go run'
go run github.com/bufbuild/buf/cmd/buf generate

# Or use make targets that wrap 'go run'
make proto
make lint
```

## Code Templates

### Main Application

```go
// cmd/myapp/main.go
package main

import (
    "context"
    "errors"
    "flag"
    "fmt"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/yourusername/yourproject/internal/config"
    "github.com/yourusername/yourproject/internal/server"
)

const (
    defaultPort    = 8080
    defaultTimeout = 30 * time.Second
)

func main() {
    if err := run(); err != nil {
        log.Fatalf("application error: %v", err)
    }
}

func run() error {
    // Parse flags
    var (
        configPath = flag.String("config", "configs/config.yaml", "path to config file")
        port       = flag.Int("port", defaultPort, "server port")
        debug      = flag.Bool("debug", false, "enable debug mode")
    )
    flag.Parse()

    // Load configuration
    cfg, err := config.Load(*configPath)
    if err != nil {
        return fmt.Errorf("failed to load config: %w", err)
    }

    if *debug {
        cfg.LogLevel = "debug"
    }

    // Initialize server
    srv, err := server.New(cfg)
    if err != nil {
        return fmt.Errorf("failed to create server: %w", err)
    }

    // Setup HTTP server
    httpServer := &http.Server{
        Addr:         fmt.Sprintf(":%d", *port),
        Handler:      srv.Handler(),
        ReadTimeout:  defaultTimeout,
        WriteTimeout: defaultTimeout,
        IdleTimeout:  defaultTimeout * 2,
    }

    // Start server in goroutine
    serverErrors := make(chan error, 1)
    go func() {
        log.Printf("server listening on %s", httpServer.Addr)
        serverErrors <- httpServer.ListenAndServe()
    }()

    // Setup signal handling for graceful shutdown
    shutdown := make(chan os.Signal, 1)
    signal.Notify(shutdown, os.Interrupt, syscall.SIGTERM)

    // Block until error or shutdown signal
    select {
    case err := <-serverErrors:
        return fmt.Errorf("server error: %w", err)

    case sig := <-shutdown:
        log.Printf("received signal %v, starting shutdown", sig)

        // Give outstanding requests a deadline for completion
        ctx, cancel := context.WithTimeout(context.Background(), defaultTimeout)
        defer cancel()

        if err := httpServer.Shutdown(ctx); err != nil {
            if err := httpServer.Close(); err != nil {
                return fmt.Errorf("could not stop server gracefully: %w", err)
            }
        }
    }

    return nil
}
```

### Package with Error Handling

```go
// pkg/azure/client.go
package azure

import (
    "context"
    "fmt"
    "time"

    "github.com/Azure/azure-sdk-for-go/sdk/azcore"
    "github.com/Azure/azure-sdk-for-go/sdk/azidentity"
)

// Client represents an Azure client (concrete type returned).
type Client struct {
    credential     azcore.TokenCredential
    subscriptionID string
    timeout        time.Duration
}

// Option is a functional option for configuring the client.
type Option func(*Client)

// WithTimeout sets the client timeout.
func WithTimeout(timeout time.Duration) Option {
    return func(c *Client) {
        c.timeout = timeout
    }
}

// WithCredential sets a custom credential.
func WithCredential(cred azcore.TokenCredential) Option {
    return func(c *Client) {
        c.credential = cred
    }
}

// New creates a new Azure client.
// Accept interfaces (none needed here), return concrete type.
func New(subscriptionID string, opts ...Option) (*Client, error) {
    if subscriptionID == "" {
        return nil, fmt.Errorf("subscription ID is required")
    }

    // Default credential
    cred, err := azidentity.NewDefaultAzureCredential(nil)
    if err != nil {
        return nil, fmt.Errorf("failed to create credential: %w", err)
    }

    // Create with defaults
    client := &Client{
        credential:     cred,
        subscriptionID: subscriptionID,
        timeout:        30 * time.Second,
    }

    // Apply functional options
    for _, opt := range opts {
        opt(client)
    }

    return client, nil
}

// ListResourceGroups lists all resource groups in the subscription.
// Returns concrete type ([]string), not interface.
func (c *Client) ListResourceGroups(ctx context.Context) ([]string, error) {
    ctx, cancel := context.WithTimeout(ctx, c.timeout)
    defer cancel()

    // Implementation here
    var groups []string

    return groups, nil
}

// Usage examples:

// Simple usage with defaults
client, err := New("subscription-id")

// With custom timeout
client, err := New("subscription-id",
    WithTimeout(60*time.Second),
)

// With multiple options
client, err := New("subscription-id",
    WithTimeout(60*time.Second),
    WithCredential(customCred),
)
```

### Table-Driven Tests

```go
// pkg/azure/client_test.go
package azure

import (
    "context"
    "errors"
    "testing"
    "time"
)

func TestNew(t *testing.T) {
    tests := []struct {
        name    string
        cfg     Config
        opts    []Option
        wantErr bool
    }{
        {
            name: "valid config",
            cfg: Config{
                SubscriptionID: "test-sub",
                TenantID:       "test-tenant",
            },
            wantErr: false,
        },
        {
            name: "missing subscription ID",
            cfg: Config{
                TenantID: "test-tenant",
            },
            wantErr: true,
        },
        {
            name: "with custom timeout",
            cfg: Config{
                SubscriptionID: "test-sub",
            },
            opts: []Option{
                WithTimeout(60 * time.Second),
            },
            wantErr: false,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := New(tt.cfg, tt.opts...)
            if (err != nil) != tt.wantErr {
                t.Errorf("New() error = %v, wantErr %v", err, tt.wantErr)
                return
            }
            if !tt.wantErr && got == nil {
                t.Error("New() returned nil client")
            }
        })
    }
}

func TestClient_ListResourceGroups(t *testing.T) {
    tests := []struct {
        name    string
        setup   func(*testing.T) *Client
        want    []string
        wantErr bool
    }{
        {
            name: "successful list",
            setup: func(t *testing.T) *Client {
                // Setup mock client
                return &Client{
                    timeout: 30 * time.Second,
                }
            },
            want:    []string{"rg1", "rg2"},
            wantErr: false,
        },
        {
            name: "context timeout",
            setup: func(t *testing.T) *Client {
                return &Client{
                    timeout: 1 * time.Nanosecond,
                }
            },
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            client := tt.setup(t)
            ctx := context.Background()

            got, err := client.ListResourceGroups(ctx)
            if (err != nil) != tt.wantErr {
                t.Errorf("ListResourceGroups() error = %v, wantErr %v", err, tt.wantErr)
                return
            }

            if !tt.wantErr && !stringSliceEqual(got, tt.want) {
                t.Errorf("ListResourceGroups() = %v, want %v", got, tt.want)
            }
        })
    }
}

func stringSliceEqual(a, b []string) bool {
    if len(a) != len(b) {
        return false
    }
    for i := range a {
        if a[i] != b[i] {
            return false
        }
    }
    return true
}
```

## Best Practices

### Accept Interfaces, Return Concrete Types

This is a fundamental Go principle that makes code more flexible and testable.

```go
// GOOD - Accept interface, return concrete type
// Function can work with any implementation
// Callers know exactly what they're getting back
type Storage interface {
    Get(key string) (string, error)
}

type User struct {
    ID   string
    Name string
}

func GetUser(storage Storage, id string) (*User, error) {
    data, err := storage.Get(id)
    if err != nil {
        return nil, err
    }

    var user User
    if err := json.Unmarshal([]byte(data), &user); err != nil {
        return nil, err
    }

    return &user, nil // Concrete type
}

// BAD - Returns interface
// Callers don't know what they're actually getting
// Harder to test, harder to understand
func GetUser(storage Storage, id string) (interface{}, error) {
    // ...
    return &user, nil // What type is this really?
}

// BAD - Accepts concrete type when interface would work
// Inflexible, harder to test
func GetUser(storage *PostgresStorage, id string) (*User, error) {
    // Can only use PostgresStorage, no mocking
}

// GOOD - Dependency injection with interfaces
type UserService struct {
    storage Storage       // Interface
    cache   Cache         // Interface
    logger  Logger        // Interface
}

func NewUserService(storage Storage, cache Cache, logger Logger) *UserService {
    return &UserService{
        storage: storage,
        cache:   cache,
        logger:  logger,
    }
}

// Methods return concrete types
func (s *UserService) GetByID(ctx context.Context, id string) (*User, error) {
    // ...
    return &User{}, nil // Concrete type
}

func (s *UserService) List(ctx context.Context) ([]*User, error) {
    // ...
    return []*User{}, nil // Concrete slice of concrete types
}
```

### Functional Options Pattern

Prefer functional options over config structs with many fields or builder patterns.

```go
// GOOD - Functional options pattern
type Server struct {
    port        int
    timeout     time.Duration
    maxConns    int
    logger      *slog.Logger
    tlsConfig   *tls.Config
}

// Option is a functional option for configuring Server
type Option func(*Server)

func WithPort(port int) Option {
    return func(s *Server) {
        s.port = port
    }
}

func WithTimeout(timeout time.Duration) Option {
    return func(s *Server) {
        s.timeout = timeout
    }
}

func WithMaxConnections(max int) Option {
    return func(s *Server) {
        s.maxConns = max
    }
}

func WithLogger(logger *slog.Logger) Option {
    return func(s *Server) {
        s.logger = logger
    }
}

func WithTLS(config *tls.Config) Option {
    return func(s *Server) {
        s.tlsConfig = config
    }
}

func NewServer(addr string, opts ...Option) *Server {
    // Set defaults
    s := &Server{
        port:     8080,
        timeout:  30 * time.Second,
        maxConns: 100,
        logger:   slog.Default(),
    }

    // Apply options
    for _, opt := range opts {
        opt(s)
    }

    return s
}

// Usage - Clean, readable, flexible
server := NewServer("localhost",
    WithPort(9090),
    WithTimeout(60*time.Second),
    WithLogger(customLogger),
)

// BAD - Config struct approach
type ServerConfig struct {
    Port        int
    Timeout     time.Duration
    MaxConns    int
    Logger      *slog.Logger
    TLSConfig   *tls.Config
    // Many more fields...
}

func NewServer(addr string, config ServerConfig) *Server {
    // Caller must provide entire config, unclear what's required
    // No way to set defaults cleanly
}

// Usage - Verbose, unclear what's required
server := NewServer("localhost", ServerConfig{
    Port:     9090,
    Timeout:  60 * time.Second,
    MaxConns: 100,
    Logger:   customLogger,
    // What about TLSConfig? Is it required?
})

// BAD - Builder pattern (not idiomatic in Go)
type ServerBuilder struct {
    server *Server
}

func NewServerBuilder() *ServerBuilder {
    return &ServerBuilder{
        server: &Server{
            port:    8080,
            timeout: 30 * time.Second,
        },
    }
}

func (b *ServerBuilder) WithPort(port int) *ServerBuilder {
    b.server.port = port
    return b
}

func (b *ServerBuilder) Build() *Server {
    return b.server
}

// Usage - More verbose than functional options
server := NewServerBuilder().
    WithPort(9090).
    WithTimeout(60 * time.Second).
    Build()
```

### When to Use Each Pattern

**Functional Options (Preferred):**

- Multiple optional configuration parameters
- Want clear defaults
- Configuration may grow over time
- Clean, readable API desired

**Simple Constructor:**

- Required parameters only (1-3 parameters)
- No optional configuration needed
- Configuration is static

```go
// Simple constructor - few required parameters
func NewClient(apiKey, endpoint string) *Client {
    return &Client{
        apiKey:   apiKey,
        endpoint: endpoint,
        timeout:  30 * time.Second, // Default
    }
}

// Functional options - many optional parameters
func NewClient(apiKey, endpoint string, opts ...Option) *Client {
    c := &Client{
        apiKey:   apiKey,
        endpoint: endpoint,
        timeout:  30 * time.Second,
    }

    for _, opt := range opts {
        opt(c)
    }

    return c
}
```

### Error Handling Patterns

```go
// Sentinel errors
var (
    ErrNotFound     = errors.New("resource not found")
    ErrUnauthorized = errors.New("unauthorized")
    ErrInvalidInput = errors.New("invalid input")
)

// Custom error types
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error on field %s: %s", e.Field, e.Message)
}

// Error wrapping with context
func ProcessFile(path string) error {
    f, err := os.Open(path)
    if err != nil {
        return fmt.Errorf("failed to open file %s: %w", path, err)
    }
    defer f.Close()

    if err := processContents(f); err != nil {
        return fmt.Errorf("failed to process file contents: %w", err)
    }

    return nil
}

// Error checking with errors.Is and errors.As
func HandleError(err error) {
    if errors.Is(err, ErrNotFound) {
        // Handle not found
        log.Println("resource not found")
        return
    }

    var validationErr *ValidationError
    if errors.As(err, &validationErr) {
        // Handle validation error
        log.Printf("validation failed: %s", validationErr.Field)
        return
    }

    // Handle unknown error
    log.Printf("unexpected error: %v", err)
}
```

### Context Usage

```go
// Pass context as first parameter
func FetchData(ctx context.Context, id string) (*Data, error) {
    // Check context before expensive operations
    if err := ctx.Err(); err != nil {
        return nil, err
    }

    // Use context for cancellation
    req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
    if err != nil {
        return nil, fmt.Errorf("failed to create request: %w", err)
    }

    // Implementation
    return &Data{}, nil
}

// Context with timeout
func DoWork(ctx context.Context) error {
    ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
    defer cancel()

    // Do work with timeout
    return nil
}

// Context with values (use sparingly)
type contextKey string

const userIDKey contextKey = "userID"

func WithUserID(ctx context.Context, userID string) context.Context {
    return context.WithValue(ctx, userIDKey, userID)
}

func UserIDFromContext(ctx context.Context) (string, bool) {
    userID, ok := ctx.Value(userIDKey).(string)
    return userID, ok
}
```

### Concurrency Patterns

```go
// Worker pool pattern
func ProcessItems(ctx context.Context, items []Item) error {
    const numWorkers = 5

    jobs := make(chan Item, len(items))
    results := make(chan error, len(items))

    // Start workers
    for w := 0; w < numWorkers; w++ {
        go worker(ctx, jobs, results)
    }

    // Send jobs
    for _, item := range items {
        jobs <- item
    }
    close(jobs)

    // Collect results
    for i := 0; i < len(items); i++ {
        if err := <-results; err != nil {
            return fmt.Errorf("worker error: %w", err)
        }
    }

    return nil
}

func worker(ctx context.Context, jobs <-chan Item, results chan<- error) {
    for job := range jobs {
        select {
        case <-ctx.Done():
            results <- ctx.Err()
            return
        default:
            results <- processItem(job)
        }
    }
}

// errgroup pattern for concurrent operations
import "golang.org/x/sync/errgroup"

func FetchMultiple(ctx context.Context, ids []string) ([]Data, error) {
    g, ctx := errgroup.WithContext(ctx)
    results := make([]Data, len(ids))

    for i, id := range ids {
        i, id := i, id // Capture loop variables
        g.Go(func() error {
            data, err := FetchData(ctx, id)
            if err != nil {
                return err
            }
            results[i] = *data
            return nil
        })
    }

    if err := g.Wait(); err != nil {
        return nil, err
    }

    return results, nil
}

// Pipeline pattern
func Pipeline(ctx context.Context, input <-chan int) <-chan int {
    output := make(chan int)

    go func() {
        defer close(output)
        for val := range input {
            select {
            case <-ctx.Done():
                return
            case output <- val * 2:
            }
        }
    }()

    return output
}
```

### Resource Management

```go
// Defer for cleanup
func ProcessFile(path string) error {
    f, err := os.Open(path)
    if err != nil {
        return err
    }
    defer f.Close() // Always close

    // Process file
    return nil
}

// Multiple defers execute in LIFO order
func MultipleResources() error {
    f1, err := os.Open("file1.txt")
    if err != nil {
        return err
    }
    defer f1.Close() // Executes third

    f2, err := os.Open("file2.txt")
    if err != nil {
        return err
    }
    defer f2.Close() // Executes second

    db, err := openDatabase()
    if err != nil {
        return err
    }
    defer db.Close() // Executes first

    // Do work
    return nil
}

// Context-based cleanup
type Resource struct {
    conn *Connection
}

func (r *Resource) Close() error {
    return r.conn.Close()
}

func NewResource(ctx context.Context) (*Resource, error) {
    conn, err := connect()
    if err != nil {
        return nil, err
    }

    r := &Resource{conn: conn}

    // Register cleanup on context cancellation
    go func() {
        <-ctx.Done()
        r.Close()
    }()

    return r, nil
}
```

### Configuration Management

```go
// pkg/config/config.go
package config

import (
    "fmt"
    "os"
    "time"

    "github.com/spf13/viper"
)

// Config holds application configuration.
type Config struct {
    Server   ServerConfig
    Database DatabaseConfig
    Azure    AzureConfig
    Logging  LoggingConfig
}

type ServerConfig struct {
    Port         int           `mapstructure:"port"`
    ReadTimeout  time.Duration `mapstructure:"read_timeout"`
    WriteTimeout time.Duration `mapstructure:"write_timeout"`
}

type DatabaseConfig struct {
    Host     string `mapstructure:"host"`
    Port     int    `mapstructure:"port"`
    Name     string `mapstructure:"name"`
    User     string `mapstructure:"user"`
    Password string `mapstructure:"password"`
    SSLMode  string `mapstructure:"ssl_mode"`
}

type AzureConfig struct {
    SubscriptionID string `mapstructure:"subscription_id"`
    TenantID       string `mapstructure:"tenant_id"`
    ClientID       string `mapstructure:"client_id"`
    ClientSecret   string `mapstructure:"client_secret"`
}

type LoggingConfig struct {
    Level  string `mapstructure:"level"`
    Format string `mapstructure:"format"` // json or text
}

// Load reads configuration from file and environment.
func Load(path string) (*Config, error) {
    v := viper.New()

    // Set defaults
    v.SetDefault("server.port", 8080)
    v.SetDefault("server.read_timeout", 30*time.Second)
    v.SetDefault("server.write_timeout", 30*time.Second)
    v.SetDefault("logging.level", "info")
    v.SetDefault("logging.format", "json")

    // Read from config file
    v.SetConfigFile(path)
    if err := v.ReadInConfig(); err != nil {
        if !os.IsNotExist(err) {
            return nil, fmt.Errorf("failed to read config: %w", err)
        }
    }

    // Override with environment variables
    v.SetEnvPrefix("APP")
    v.AutomaticEnv()

    var cfg Config
    if err := v.Unmarshal(&cfg); err != nil {
        return nil, fmt.Errorf("failed to unmarshal config: %w", err)
    }

    // Validate configuration
    if err := cfg.Validate(); err != nil {
        return nil, fmt.Errorf("invalid config: %w", err)
    }

    return &cfg, nil
}

// Validate checks configuration values.
func (c *Config) Validate() error {
    if c.Server.Port < 1 || c.Server.Port > 65535 {
        return fmt.Errorf("invalid server port: %d", c.Server.Port)
    }

    if c.Database.Host == "" {
        return fmt.Errorf("database host is required")
    }

    if c.Azure.SubscriptionID == "" {
        return fmt.Errorf("azure subscription ID is required")
    }

    return nil
}
```

### Logging

```go
// Use structured logging
import (
    "log/slog"
    "os"
)

func SetupLogger(level, format string) *slog.Logger {
    var handler slog.Handler

    opts := &slog.HandlerOptions{
        Level: parseLevel(level),
    }

    switch format {
    case "json":
        handler = slog.NewJSONHandler(os.Stdout, opts)
    default:
        handler = slog.NewTextHandler(os.Stdout, opts)
    }

    return slog.New(handler)
}

func parseLevel(level string) slog.Level {
    switch level {
    case "debug":
        return slog.LevelDebug
    case "info":
        return slog.LevelInfo
    case "warn":
        return slog.LevelWarn
    case "error":
        return slog.LevelError
    default:
        return slog.LevelInfo
    }
}

// Usage
logger := SetupLogger("info", "json")

logger.Info("server starting",
    "port", 8080,
    "version", "1.0.0",
)

logger.Error("failed to connect to database",
    "error", err,
    "host", dbHost,
    "retry_count", retries,
)
```

## HTTP Server Patterns

### RESTful API Handler

```go
// internal/server/handlers.go
package server

import (
    "encoding/json"
    "errors"
    "log/slog"
    "net/http"

    "github.com/gorilla/mux"
)

type Handler struct {
    logger  *slog.Logger
    service Service
}

func NewHandler(logger *slog.Logger, service Service) *Handler {
    return &Handler{
        logger:  logger,
        service: service,
    }
}

// Routes sets up HTTP routes.
func (h *Handler) Routes() http.Handler {
    r := mux.NewRouter()

    // API routes
    api := r.PathPrefix("/api/v1").Subrouter()
    api.Use(h.loggingMiddleware)
    api.Use(h.recoveryMiddleware)

    api.HandleFunc("/resources", h.ListResources).Methods(http.MethodGet)
    api.HandleFunc("/resources/{id}", h.GetResource).Methods(http.MethodGet)
    api.HandleFunc("/resources", h.CreateResource).Methods(http.MethodPost)
    api.HandleFunc("/resources/{id}", h.UpdateResource).Methods(http.MethodPut)
    api.HandleFunc("/resources/{id}", h.DeleteResource).Methods(http.MethodDelete)

    // Health check
    r.HandleFunc("/health", h.Health).Methods(http.MethodGet)

    return r
}

// ListResources handles GET /api/v1/resources
func (h *Handler) ListResources(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    resources, err := h.service.List(ctx)
    if err != nil {
        h.logger.Error("failed to list resources", "error", err)
        h.respondError(w, http.StatusInternalServerError, "internal server error")
        return
    }

    h.respondJSON(w, http.StatusOK, resources)
}

// GetResource handles GET /api/v1/resources/{id}
func (h *Handler) GetResource(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    vars := mux.Vars(r)
    id := vars["id"]

    resource, err := h.service.Get(ctx, id)
    if err != nil {
        if errors.Is(err, ErrNotFound) {
            h.respondError(w, http.StatusNotFound, "resource not found")
            return
        }
        h.logger.Error("failed to get resource", "error", err, "id", id)
        h.respondError(w, http.StatusInternalServerError, "internal server error")
        return
    }

    h.respondJSON(w, http.StatusOK, resource)
}

// CreateResource handles POST /api/v1/resources
func (h *Handler) CreateResource(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    var req CreateResourceRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        h.respondError(w, http.StatusBadRequest, "invalid request body")
        return
    }

    if err := req.Validate(); err != nil {
        h.respondError(w, http.StatusBadRequest, err.Error())
        return
    }

    resource, err := h.service.Create(ctx, req)
    if err != nil {
        h.logger.Error("failed to create resource", "error", err)
        h.respondError(w, http.StatusInternalServerError, "internal server error")
        return
    }

    h.respondJSON(w, http.StatusCreated, resource)
}

// Health handles GET /health
func (h *Handler) Health(w http.ResponseWriter, r *http.Request) {
    h.respondJSON(w, http.StatusOK, map[string]string{
        "status": "healthy",
    })
}

// Helper methods
func (h *Handler) respondJSON(w http.ResponseWriter, status int, data interface{}) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)

    if err := json.NewEncoder(w).Encode(data); err != nil {
        h.logger.Error("failed to encode response", "error", err)
    }
}

func (h *Handler) respondError(w http.ResponseWriter, status int, message string) {
    h.respondJSON(w, status, map[string]string{
        "error": message,
    })
}

// Middleware
func (h *Handler) loggingMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        h.logger.Info("request",
            "method", r.Method,
            "path", r.URL.Path,
            "remote_addr", r.RemoteAddr,
        )
        next.ServeHTTP(w, r)
    })
}

func (h *Handler) recoveryMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        defer func() {
            if err := recover(); err != nil {
                h.logger.Error("panic recovered",
                    "error", err,
                    "path", r.URL.Path,
                )
                h.respondError(w, http.StatusInternalServerError, "internal server error")
            }
        }()
        next.ServeHTTP(w, r)
    })
}

// Request/Response types
type CreateResourceRequest struct {
    Name        string `json:"name"`
    Description string `json:"description"`
}

func (r *CreateResourceRequest) Validate() error {
    if r.Name == "" {
        return errors.New("name is required")
    }
    return nil
}
```

## Protocol Buffers

### Overview

Protocol Buffers (protobuf) are used for:

- API definitions (gRPC services)
- Data serialization for storage
- Inter-service communication
- Configuration files

### Project Structure for Protobuf

```
.
├── api/
│   └── v1/
│       ├── service.proto        # Service definitions
│       ├── models.proto         # Message definitions
│       └── README.md           # API documentation
├── pkg/
│   └── pb/                     # Generated code (committed)
│       └── v1/
│           ├── service.pb.go
│           ├── service_grpc.pb.go
│           └── models.pb.go
├── scripts/
│   └── generate-proto.sh       # Code generation script
└── buf.yaml                    # Buf configuration (recommended)
```

### Installation and Setup

```bash
# Install protoc compiler
# macOS
brew install protobuf

# Ubuntu
apt-get install -y protobuf-compiler

# Install Go plugins
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Optional: Install buf for better protobuf management
go install github.com/bufbuild/buf/cmd/buf@latest
```

### Proto File Structure

```protobuf
// api/v1/service.proto
syntax = "proto3";

package api.v1;

option go_package = "github.com/yourusername/yourproject/pkg/pb/v1;pbv1";

import "google/protobuf/timestamp.proto";
import "google/protobuf/empty.proto";
import "api/v1/models.proto";

// ResourceService manages Azure resources
service ResourceService {
  // ListResources returns all resources in a resource group
  rpc ListResources(ListResourcesRequest) returns (ListResourcesResponse);

  // GetResource returns a specific resource by ID
  rpc GetResource(GetResourceRequest) returns (Resource);

  // CreateResource creates a new resource
  rpc CreateResource(CreateResourceRequest) returns (Resource);

  // UpdateResource updates an existing resource
  rpc UpdateResource(UpdateResourceRequest) returns (Resource);

  // DeleteResource deletes a resource
  rpc DeleteResource(DeleteResourceRequest) returns (google.protobuf.Empty);

  // StreamResourceUpdates streams resource update events
  rpc StreamResourceUpdates(StreamResourceUpdatesRequest) returns (stream ResourceUpdate);
}

message ListResourcesRequest {
  string resource_group = 1;
  string subscription_id = 2;

  // Pagination
  int32 page_size = 3;
  string page_token = 4;

  // Filtering
  map<string, string> tags = 5;
}

message ListResourcesResponse {
  repeated Resource resources = 1;
  string next_page_token = 2;
  int32 total_count = 3;
}

message GetResourceRequest {
  string resource_id = 1;
  string subscription_id = 2;
}

message CreateResourceRequest {
  string name = 1;
  string resource_group = 2;
  string location = 3;
  map<string, string> tags = 4;
  ResourceSpec spec = 5;
}

message UpdateResourceRequest {
  string resource_id = 1;
  map<string, string> tags = 2;
  ResourceSpec spec = 3;
}

message DeleteResourceRequest {
  string resource_id = 1;
  bool force = 2;
}

message StreamResourceUpdatesRequest {
  string resource_group = 1;
  repeated string resource_types = 2;
}

message ResourceUpdate {
  enum UpdateType {
    UNKNOWN = 0;
    CREATED = 1;
    UPDATED = 2;
    DELETED = 3;
  }

  UpdateType type = 1;
  Resource resource = 2;
  google.protobuf.Timestamp timestamp = 3;
}
```

```protobuf
// api/v1/models.proto
syntax = "proto3";

package api.v1;

option go_package = "github.com/yourusername/yourproject/pkg/pb/v1;pbv1";

import "google/protobuf/timestamp.proto";

message Resource {
  string id = 1;
  string name = 2;
  string type = 3;
  string location = 4;
  string resource_group = 5;
  map<string, string> tags = 6;
  ResourceSpec spec = 7;
  ResourceStatus status = 8;
  google.protobuf.Timestamp created_at = 9;
  google.protobuf.Timestamp updated_at = 10;
}

message ResourceSpec {
  string sku = 1;
  int32 capacity = 2;
  map<string, string> properties = 3;
}

message ResourceStatus {
  enum State {
    UNKNOWN = 0;
    CREATING = 1;
    RUNNING = 2;
    UPDATING = 3;
    DELETING = 4;
    FAILED = 5;
  }

  State state = 1;
  string message = 2;
}
```

### Code Generation

#### Using protoc

```bash
#!/bin/bash
# scripts/generate-proto.sh

set -euo pipefail

PROTO_DIR="api"
OUT_DIR="pkg/pb"

# Create output directory
mkdir -p "$OUT_DIR"

# Generate Go code
protoc \
  --proto_path="$PROTO_DIR" \
  --go_out="$OUT_DIR" \
  --go_opt=paths=source_relative \
  --go-grpc_out="$OUT_DIR" \
  --go-grpc_opt=paths=source_relative \
  "$PROTO_DIR/v1"/*.proto

echo "Proto generation complete"
```

#### Using buf (Recommended)

```yaml
# buf.yaml
version: v1
name: buf.build/yourusername/yourproject
breaking:
  use:
    - FILE
lint:
  use:
    - DEFAULT
  except:
    - PACKAGE_VERSION_SUFFIX
```

```yaml
# buf.gen.yaml
version: v1
managed:
  enabled: true
  go_package_prefix:
    default: github.com/yourusername/yourproject/pkg/pb
plugins:
  - plugin: buf.build/protocolbuffers/go
    out: pkg/pb
    opt:
      - paths=source_relative
  - plugin: buf.build/grpc/go
    out: pkg/pb
    opt:
      - paths=source_relative
```

```bash
# Generate with buf
buf generate
```

### gRPC Server Implementation

```go
// internal/grpc/server.go
package grpc

import (
    "context"
    "fmt"
    "log/slog"

    "google.golang.org/grpc"
    "google.golang.org/grpc/codes"
    "google.golang.org/grpc/status"
    "google.golang.org/protobuf/types/known/emptypb"
    "google.golang.org/protobuf/types/known/timestamppb"

    pbv1 "github.com/yourusername/yourproject/pkg/pb/v1"
)

// ResourceService implements the ResourceService gRPC service.
// Accept interfaces, return concrete types.
type ResourceService struct {
    pbv1.UnimplementedResourceServiceServer
    logger  *slog.Logger
    manager ResourceManager // Interface
}

// ResourceManager defines operations for managing resources.
type ResourceManager interface {
    List(ctx context.Context, resourceGroup, subscriptionID string, opts ListOptions) ([]*Resource, error)
    Get(ctx context.Context, resourceID, subscriptionID string) (*Resource, error)
    Create(ctx context.Context, req CreateRequest) (*Resource, error)
    Update(ctx context.Context, resourceID string, req UpdateRequest) (*Resource, error)
    Delete(ctx context.Context, resourceID string, force bool) error
}

// ListOptions contains filtering and pagination options.
type ListOptions struct {
    PageSize  int
    PageToken string
    Tags      map[string]string
}

// Resource represents an Azure resource (domain model).
type Resource struct {
    ID            string
    Name          string
    Type          string
    Location      string
    ResourceGroup string
    Tags          map[string]string
    CreatedAt     time.Time
    UpdatedAt     time.Time
}

// NewResourceService creates a new ResourceService.
// Use functional options for configuration.
func NewResourceService(manager ResourceManager, opts ...ServiceOption) *ResourceService {
    s := &ResourceService{
        manager: manager,
        logger:  slog.Default(),
    }

    for _, opt := range opts {
        opt(s)
    }

    return s
}

// ServiceOption configures the ResourceService.
type ServiceOption func(*ResourceService)

// WithLogger sets a custom logger.
func WithLogger(logger *slog.Logger) ServiceOption {
    return func(s *ResourceService) {
        s.logger = logger
    }
}

// ListResources implements the ListResources RPC.
func (s *ResourceService) ListResources(ctx context.Context, req *pbv1.ListResourcesRequest) (*pbv1.ListResourcesResponse, error) {
    if req.ResourceGroup == "" {
        return nil, status.Error(codes.InvalidArgument, "resource_group is required")
    }

    opts := ListOptions{
        PageSize:  int(req.PageSize),
        PageToken: req.PageToken,
        Tags:      req.Tags,
    }

    resources, err := s.manager.List(ctx, req.ResourceGroup, req.SubscriptionId, opts)
    if err != nil {
        s.logger.Error("failed to list resources",
            "error", err,
            "resource_group", req.ResourceGroup,
        )
        return nil, status.Errorf(codes.Internal, "failed to list resources: %v", err)
    }

    // Convert domain models to protobuf messages
    pbResources := make([]*pbv1.Resource, len(resources))
    for i, r := range resources {
        pbResources[i] = resourceToProto(r)
    }

    return &pbv1.ListResourcesResponse{
        Resources:     pbResources,
        NextPageToken: "", // Implement pagination
        TotalCount:    int32(len(pbResources)),
    }, nil
}

// GetResource implements the GetResource RPC.
func (s *ResourceService) GetResource(ctx context.Context, req *pbv1.GetResourceRequest) (*pbv1.Resource, error) {
    if req.ResourceId == "" {
        return nil, status.Error(codes.InvalidArgument, "resource_id is required")
    }

    resource, err := s.manager.Get(ctx, req.ResourceId, req.SubscriptionId)
    if err != nil {
        if errors.Is(err, ErrNotFound) {
            return nil, status.Error(codes.NotFound, "resource not found")
        }
        s.logger.Error("failed to get resource",
            "error", err,
            "resource_id", req.ResourceId,
        )
        return nil, status.Errorf(codes.Internal, "failed to get resource: %v", err)
    }

    return resourceToProto(resource), nil
}

// CreateResource implements the CreateResource RPC.
func (s *ResourceService) CreateResource(ctx context.Context, req *pbv1.CreateResourceRequest) (*pbv1.Resource, error) {
    if err := validateCreateRequest(req); err != nil {
        return nil, status.Error(codes.InvalidArgument, err.Error())
    }

    createReq := CreateRequest{
        Name:          req.Name,
        ResourceGroup: req.ResourceGroup,
        Location:      req.Location,
        Tags:          req.Tags,
    }

    resource, err := s.manager.Create(ctx, createReq)
    if err != nil {
        s.logger.Error("failed to create resource",
            "error", err,
            "name", req.Name,
        )
        return nil, status.Errorf(codes.Internal, "failed to create resource: %v", err)
    }

    return resourceToProto(resource), nil
}

// DeleteResource implements the DeleteResource RPC.
func (s *ResourceService) DeleteResource(ctx context.Context, req *pbv1.DeleteResourceRequest) (*emptypb.Empty, error) {
    if req.ResourceId == "" {
        return nil, status.Error(codes.InvalidArgument, "resource_id is required")
    }

    if err := s.manager.Delete(ctx, req.ResourceId, req.Force); err != nil {
        if errors.Is(err, ErrNotFound) {
            return nil, status.Error(codes.NotFound, "resource not found")
        }
        s.logger.Error("failed to delete resource",
            "error", err,
            "resource_id", req.ResourceId,
        )
        return nil, status.Errorf(codes.Internal, "failed to delete resource: %v", err)
    }

    return &emptypb.Empty{}, nil
}

// StreamResourceUpdates implements the StreamResourceUpdates RPC.
func (s *ResourceService) StreamResourceUpdates(req *pbv1.StreamResourceUpdatesRequest, stream pbv1.ResourceService_StreamResourceUpdatesServer) error {
    ctx := stream.Context()

    // Implementation would subscribe to resource updates
    // and stream them back to the client
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        default:
            // Get update from subscription
            // Send to stream
            // if err := stream.Send(update); err != nil {
            //     return err
            // }
        }
    }
}

// Helper functions

func resourceToProto(r *Resource) *pbv1.Resource {
    return &pbv1.Resource{
        Id:            r.ID,
        Name:          r.Name,
        Type:          r.Type,
        Location:      r.Location,
        ResourceGroup: r.ResourceGroup,
        Tags:          r.Tags,
        CreatedAt:     timestamppb.New(r.CreatedAt),
        UpdatedAt:     timestamppb.New(r.UpdatedAt),
    }
}

func validateCreateRequest(req *pbv1.CreateResourceRequest) error {
    if req.Name == "" {
        return fmt.Errorf("name is required")
    }
    if req.ResourceGroup == "" {
        return fmt.Errorf("resource_group is required")
    }
    if req.Location == "" {
        return fmt.Errorf("location is required")
    }
    return nil
}
```

### gRPC Client Usage

```go
// pkg/client/client.go
package client

import (
    "context"
    "fmt"
    "time"

    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials/insecure"

    pbv1 "github.com/yourusername/yourproject/pkg/pb/v1"
)

// Client wraps the gRPC client with convenient methods.
type Client struct {
    conn   *grpc.ClientConn
    svc    pbv1.ResourceServiceClient
    config Config
}

// Config holds client configuration.
type Config struct {
    Address string
    Timeout time.Duration
}

// Option configures the client (functional options pattern).
type Option func(*Client)

// WithTimeout sets the default timeout for requests.
func WithTimeout(timeout time.Duration) Option {
    return func(c *Client) {
        c.config.Timeout = timeout
    }
}

// New creates a new gRPC client.
func New(address string, opts ...Option) (*Client, error) {
    client := &Client{
        config: Config{
            Address: address,
            Timeout: 30 * time.Second,
        },
    }

    // Apply options
    for _, opt := range opts {
        opt(client)
    }

    // Create gRPC connection
    conn, err := grpc.NewClient(
        client.config.Address,
        grpc.WithTransportCredentials(insecure.NewCredentials()),
    )
    if err != nil {
        return nil, fmt.Errorf("failed to create connection: %w", err)
    }

    client.conn = conn
    client.svc = pbv1.NewResourceServiceClient(conn)

    return client, nil
}

// Close closes the gRPC connection.
func (c *Client) Close() error {
    return c.conn.Close()
}

// ListResources lists all resources in a resource group.
// Returns concrete type, not interface.
func (c *Client) ListResources(ctx context.Context, resourceGroup, subscriptionID string) ([]*pbv1.Resource, error) {
    ctx, cancel := context.WithTimeout(ctx, c.config.Timeout)
    defer cancel()

    resp, err := c.svc.ListResources(ctx, &pbv1.ListResourcesRequest{
        ResourceGroup:  resourceGroup,
        SubscriptionId: subscriptionID,
    })
    if err != nil {
        return nil, fmt.Errorf("failed to list resources: %w", err)
    }

    return resp.Resources, nil
}

// GetResource retrieves a specific resource.
func (c *Client) GetResource(ctx context.Context, resourceID, subscriptionID string) (*pbv1.Resource, error) {
    ctx, cancel := context.WithTimeout(ctx, c.config.Timeout)
    defer cancel()

    resource, err := c.svc.GetResource(ctx, &pbv1.GetResourceRequest{
        ResourceId:     resourceID,
        SubscriptionId: subscriptionID,
    })
    if err != nil {
        return nil, fmt.Errorf("failed to get resource: %w", err)
    }

    return resource, nil
}

// CreateResource creates a new resource.
func (c *Client) CreateResource(ctx context.Context, req *pbv1.CreateResourceRequest) (*pbv1.Resource, error) {
    ctx, cancel := context.WithTimeout(ctx, c.config.Timeout)
    defer cancel()

    resource, err := c.svc.CreateResource(ctx, req)
    if err != nil {
        return nil, fmt.Errorf("failed to create resource: %w", err)
    }

    return resource, nil
}

// StreamUpdates streams resource updates.
func (c *Client) StreamUpdates(ctx context.Context, resourceGroup string) (<-chan *pbv1.ResourceUpdate, <-chan error) {
    updatesCh := make(chan *pbv1.ResourceUpdate)
    errorsCh := make(chan error, 1)

    go func() {
        defer close(updatesCh)
        defer close(errorsCh)

        stream, err := c.svc.StreamResourceUpdates(ctx, &pbv1.StreamResourceUpdatesRequest{
            ResourceGroup: resourceGroup,
        })
        if err != nil {
            errorsCh <- fmt.Errorf("failed to start stream: %w", err)
            return
        }

        for {
            update, err := stream.Recv()
            if err != nil {
                if err != io.EOF {
                    errorsCh <- fmt.Errorf("stream error: %w", err)
                }
                return
            }

            select {
            case updatesCh <- update:
            case <-ctx.Done():
                return
            }
        }
    }()

    return updatesCh, errorsCh
}
```

### Protobuf Best Practices

#### 1. Message Design

```protobuf
// GOOD - Clear, specific field names
message CreateUserRequest {
  string email = 1;
  string full_name = 2;
  repeated string roles = 3;
}

// BAD - Vague field names
message CreateUserRequest {
  string data = 1;
  string info = 2;
  repeated string items = 3;
}

// GOOD - Use enums for fixed sets of values
message Resource {
  enum State {
    STATE_UNSPECIFIED = 0;  // Always include zero value
    STATE_CREATING = 1;
    STATE_RUNNING = 2;
    STATE_FAILED = 3;
  }
  State state = 1;
}

// GOOD - Use well-known types
import "google/protobuf/timestamp.proto";
import "google/protobuf/duration.proto";

message Task {
  google.protobuf.Timestamp created_at = 1;
  google.protobuf.Duration timeout = 2;
}

// GOOD - Use oneof for mutually exclusive fields
message SearchRequest {
  oneof query {
    string keyword = 1;
    int64 id = 2;
    string email = 3;
  }
}
```

#### 2. Field Numbering

```protobuf
// Reserve field numbers for deleted fields
message User {
  reserved 2, 5 to 10;
  reserved "old_field", "deprecated_field";

  string id = 1;
  // Field 2 was removed - don't reuse
  string email = 3;
  string name = 4;
  // Fields 5-10 reserved for future use
  string role = 11;
}

// Use field numbers strategically
// 1-15: Most frequently used fields (1 byte encoding)
// 16-2047: Less frequent fields (2 byte encoding)
message OptimizedMessage {
  string id = 1;           // Most common
  string name = 2;         // Very common
  string email = 3;        // Common
  string description = 16; // Less common
  map<string, string> metadata = 17; // Rare
}
```

#### 3. Backward Compatibility

```protobuf
// GOOD - Adding new fields is safe
message User {
  string id = 1;
  string name = 2;
  string email = 3;  // New field - old clients ignore it
}

// GOOD - Making fields optional is safe
message User {
  string id = 1;
  optional string name = 2;  // Was required, now optional
}

// BAD - Changing field types breaks compatibility
message User {
  string id = 1;
  int64 created_at = 2;  // Was string, now int64 - BREAKS!
}

// GOOD - Evolving with new messages
message UserV1 {
  string id = 1;
  string name = 2;
}

message UserV2 {
  string id = 1;
  string full_name = 2;
  string email = 3;
}
```

#### 4. Validation

```go
// Implement validation methods on generated types
func (r *CreateResourceRequest) Validate() error {
    if r.Name == "" {
        return fmt.Errorf("name is required")
    }
    if r.ResourceGroup == "" {
        return fmt.Errorf("resource_group is required")
    }
    if r.Location == "" {
        return fmt.Errorf("location is required")
    }

    // Validate nested messages
    if r.Spec != nil {
        if err := r.Spec.Validate(); err != nil {
            return fmt.Errorf("invalid spec: %w", err)
        }
    }

    return nil
}
```

### JSON Mapping

```go
// Protobuf messages can be marshaled to/from JSON
import (
    "google.golang.org/protobuf/encoding/protojson"
)

// Marshal to JSON
func marshalToJSON(resource *pbv1.Resource) ([]byte, error) {
    marshaler := protojson.MarshalOptions{
        UseProtoNames:   true,  // Use proto field names (snake_case)
        EmitUnpopulated: false, // Don't include zero values
        Indent:          "  ",  // Pretty print
    }

    return marshaler.Marshal(resource)
}

// Unmarshal from JSON
func unmarshalFromJSON(data []byte) (*pbv1.Resource, error) {
    unmarshaler := protojson.UnmarshalOptions{
        DiscardUnknown: true, // Ignore unknown fields
    }

    var resource pbv1.Resource
    if err := unmarshaler.Unmarshal(data, &resource); err != nil {
        return nil, err
    }

    return &resource, nil
}

// HTTP handler example
func (h *Handler) CreateResource(w http.ResponseWriter, r *http.Request) {
    var req pbv1.CreateResourceRequest

    // Decode JSON to protobuf
    body, err := io.ReadAll(r.Body)
    if err != nil {
        http.Error(w, "failed to read body", http.StatusBadRequest)
        return
    }

    if err := protojson.Unmarshal(body, &req); err != nil {
        http.Error(w, "invalid JSON", http.StatusBadRequest)
        return
    }

    // Validate
    if err := req.Validate(); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    // Process request
    resource, err := h.service.CreateResource(r.Context(), &req)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    // Encode response
    data, err := protojson.Marshal(resource)
    if err != nil {
        http.Error(w, "failed to encode response", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    w.Write(data)
}
```

### Testing Protobuf Code

```go
// pkg/grpc/server_test.go
package grpc

import (
    "context"
    "errors"
    "testing"

    "google.golang.org/grpc/codes"
    "google.golang.org/grpc/status"

    pbv1 "github.com/yourusername/yourproject/pkg/pb/v1"
)

// Mock implementation
type mockResourceManager struct {
    resources map[string]*Resource
    err       error
}

func (m *mockResourceManager) Get(ctx context.Context, resourceID, subscriptionID string) (*Resource, error) {
    if m.err != nil {
        return nil, m.err
    }
    r, ok := m.resources[resourceID]
    if !ok {
        return nil, ErrNotFound
    }
    return r, nil
}

func TestResourceService_GetResource(t *testing.T) {
    tests := []struct {
        name    string
        req     *pbv1.GetResourceRequest
        setup   func(*mockResourceManager)
        want    *pbv1.Resource
        wantErr codes.Code
    }{
        {
            name: "successful get",
            req: &pbv1.GetResourceRequest{
                ResourceId:     "test-id",
                SubscriptionId: "test-sub",
            },
            setup: func(m *mockResourceManager) {
                m.resources["test-id"] = &Resource{
                    ID:   "test-id",
                    Name: "test-resource",
                }
            },
            want: &pbv1.Resource{
                Id:   "test-id",
                Name: "test-resource",
            },
            wantErr: codes.OK,
        },
        {
            name: "resource not found",
            req: &pbv1.GetResourceRequest{
                ResourceId:     "missing",
                SubscriptionId: "test-sub",
            },
            setup:   func(m *mockResourceManager) {},
            wantErr: codes.NotFound,
        },
        {
            name: "missing resource_id",
            req: &pbv1.GetResourceRequest{
                SubscriptionId: "test-sub",
            },
            setup:   func(m *mockResourceManager) {},
            wantErr: codes.InvalidArgument,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            mock := &mockResourceManager{
                resources: make(map[string]*Resource),
            }
            tt.setup(mock)

            svc := NewResourceService(mock)
            got, err := svc.GetResource(context.Background(), tt.req)

            if tt.wantErr != codes.OK {
                if err == nil {
                    t.Fatal("expected error, got nil")
                }
                st, ok := status.FromError(err)
                if !ok {
                    t.Fatalf("error is not a status error: %v", err)
                }
                if st.Code() != tt.wantErr {
                    t.Errorf("error code = %v, want %v", st.Code(), tt.wantErr)
                }
                return
            }

            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }

            if got.Id != tt.want.Id || got.Name != tt.want.Name {
                t.Errorf("got %v, want %v", got, tt.want)
            }
        })
    }
}
```

## Azure SDK Patterns

### Azure Resource Management

```go
// pkg/azure/resources.go
package azure

import (
    "context"
    "fmt"

    "github.com/Azure/azure-sdk-for-go/sdk/azcore/to"
    "github.com/Azure/azure-sdk-for-go/sdk/azidentity"
    "github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/resources/armresources"
)

type ResourceManager struct {
    client         *armresources.Client
    subscriptionID string
}

func NewResourceManager(subscriptionID string) (*ResourceManager, error) {
    cred, err := azidentity.NewDefaultAzureCredential(nil)
    if err != nil {
        return nil, fmt.Errorf("failed to create credential: %w", err)
    }

    client, err := armresources.NewClient(subscriptionID, cred, nil)
    if err != nil {
        return nil, fmt.Errorf("failed to create client: %w", err)
    }

    return &ResourceManager{
        client:         client,
        subscriptionID: subscriptionID,
    }, nil
}

func (rm *ResourceManager) ListByResourceGroup(ctx context.Context, resourceGroup string) ([]*armresources.GenericResourceExpanded, error) {
    var resources []*armresources.GenericResourceExpanded

    pager := rm.client.NewListByResourceGroupPager(resourceGroup, nil)
    for pager.More() {
        page, err := pager.NextPage(ctx)
        if err != nil {
            return nil, fmt.Errorf("failed to get next page: %w", err)
        }
        resources = append(resources, page.Value...)
    }

    return resources, nil
}

func (rm *ResourceManager) GetByID(ctx context.Context, resourceID string) (*armresources.GenericResource, error) {
    resp, err := rm.client.GetByID(ctx, resourceID, "2021-04-01", nil)
    if err != nil {
        return nil, fmt.Errorf("failed to get resource: %w", err)
    }

    return &resp.GenericResource, nil
}

func (rm *ResourceManager) ListByTag(ctx context.Context, tagName, tagValue string) ([]*armresources.GenericResourceExpanded, error) {
    filter := fmt.Sprintf("tagName eq '%s' and tagValue eq '%s'", tagName, tagValue)

    var resources []*armresources.GenericResourceExpanded
    pager := rm.client.NewListPager(&armresources.ClientListOptions{
        Filter: to.Ptr(filter),
    })

    for pager.More() {
        page, err := pager.NextPage(ctx)
        if err != nil {
            return nil, fmt.Errorf("failed to get next page: %w", err)
        }
        resources = append(resources, page.Value...)
    }

    return resources, nil
}
```

### Azure Storage Operations

```go
// pkg/azure/storage.go
package azure

import (
    "context"
    "fmt"
    "io"

    "github.com/Azure/azure-sdk-for-go/sdk/storage/azblob"
)

type BlobClient struct {
    client *azblob.Client
}

func NewBlobClient(accountURL string) (*BlobClient, error) {
    cred, err := azidentity.NewDefaultAzureCredential(nil)
    if err != nil {
        return nil, fmt.Errorf("failed to create credential: %w", err)
    }

    client, err := azblob.NewClient(accountURL, cred, nil)
    if err != nil {
        return nil, fmt.Errorf("failed to create blob client: %w", err)
    }

    return &BlobClient{client: client}, nil
}

func (bc *BlobClient) UploadBlob(ctx context.Context, containerName, blobName string, data io.Reader) error {
    _, err := bc.client.UploadStream(ctx, containerName, blobName, data, nil)
    if err != nil {
        return fmt.Errorf("failed to upload blob: %w", err)
    }
    return nil
}

func (bc *BlobClient) DownloadBlob(ctx context.Context, containerName, blobName string) ([]byte, error) {
    resp, err := bc.client.DownloadStream(ctx, containerName, blobName, nil)
    if err != nil {
        return nil, fmt.Errorf("failed to download blob: %w", err)
    }
    defer resp.Body.Close()

    data, err := io.ReadAll(resp.Body)
    if err != nil {
        return nil, fmt.Errorf("failed to read blob data: %w", err)
    }

    return data, nil
}

func (bc *BlobClient) ListBlobs(ctx context.Context, containerName string) ([]string, error) {
    var blobNames []string

    pager := bc.client.NewListBlobsFlatPager(containerName, nil)
    for pager.More() {
        page, err := pager.NextPage(ctx)
        if err != nil {
            return nil, fmt.Errorf("failed to get next page: %w", err)
        }

        for _, blob := range page.Segment.BlobItems {
            blobNames = append(blobNames, *blob.Name)
        }
    }

    return blobNames, nil
}
```

## CLI Application Patterns

### Using Cobra for CLI

```go
// cmd/cli/main.go
package main

import (
    "fmt"
    "os"

    "github.com/spf13/cobra"
)

var (
    version = "dev"
    cfgFile string
)

func main() {
    if err := rootCmd.Execute(); err != nil {
        fmt.Fprintf(os.Stderr, "Error: %v\n", err)
        os.Exit(1)
    }
}

var rootCmd = &cobra.Command{
    Use:   "azuretool",
    Short: "Azure resource management tool",
    Long:  `A comprehensive tool for managing Azure resources.`,
}

var versionCmd = &cobra.Command{
    Use:   "version",
    Short: "Print version information",
    Run: func(cmd *cobra.Command, args []string) {
        fmt.Printf("azuretool %s\n", version)
    },
}

var listCmd = &cobra.Command{
    Use:   "list [resource-type]",
    Short: "List Azure resources",
    Args:  cobra.ExactArgs(1),
    RunE: func(cmd *cobra.Command, args []string) error {
        resourceType := args[0]
        return listResources(resourceType)
    },
}

func init() {
    rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.azuretool.yaml)")

    rootCmd.AddCommand(versionCmd)
    rootCmd.AddCommand(listCmd)

    listCmd.Flags().StringP("resource-group", "g", "", "Resource group name")
    listCmd.Flags().StringP("subscription", "s", "", "Subscription ID")
}

func listResources(resourceType string) error {
    // Implementation
    fmt.Printf("Listing %s resources...\n", resourceType)
    return nil
}
```

## Testing Patterns

### Mocking with Interfaces

```go
// internal/service/service.go
package service

import (
    "context"
)

// Storage defines storage operations.
type Storage interface {
    Get(ctx context.Context, key string) (string, error)
    Set(ctx context.Context, key, value string) error
    Delete(ctx context.Context, key string) error
}

// Service handles business logic.
type Service struct {
    storage Storage
}

func New(storage Storage) *Service {
    return &Service{storage: storage}
}

func (s *Service) ProcessData(ctx context.Context, key string) error {
    data, err := s.storage.Get(ctx, key)
    if err != nil {
        return err
    }

    // Process data
    processed := process(data)

    return s.storage.Set(ctx, key, processed)
}

func process(data string) string {
    return data + "_processed"
}
```

```go
// internal/service/service_test.go
package service

import (
    "context"
    "errors"
    "testing"
)

// mockStorage implements Storage interface
type mockStorage struct {
    data map[string]string
    err  error
}

func newMockStorage() *mockStorage {
    return &mockStorage{
        data: make(map[string]string),
    }
}

func (m *mockStorage) Get(ctx context.Context, key string) (string, error) {
    if m.err != nil {
        return "", m.err
    }
    val, ok := m.data[key]
    if !ok {
        return "", errors.New("not found")
    }
    return val, nil
}

func (m *mockStorage) Set(ctx context.Context, key, value string) error {
    if m.err != nil {
        return m.err
    }
    m.data[key] = value
    return nil
}

func (m *mockStorage) Delete(ctx context.Context, key string) error {
    if m.err != nil {
        return m.err
    }
    delete(m.data, key)
    return nil
}

func TestService_ProcessData(t *testing.T) {
    tests := []struct {
        name    string
        key     string
        setup   func(*mockStorage)
        wantErr bool
    }{
        {
            name: "successful processing",
            key:  "test-key",
            setup: func(m *mockStorage) {
                m.data["test-key"] = "test-value"
            },
            wantErr: false,
        },
        {
            name:    "key not found",
            key:     "missing-key",
            setup:   func(m *mockStorage) {},
            wantErr: true,
        },
        {
            name: "storage error",
            key:  "error-key",
            setup: func(m *mockStorage) {
                m.err = errors.New("storage error")
            },
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            storage := newMockStorage()
            tt.setup(storage)

            svc := New(storage)
            err := svc.ProcessData(context.Background(), tt.key)

            if (err != nil) != tt.wantErr {
                t.Errorf("ProcessData() error = %v, wantErr %v", err, tt.wantErr)
            }

            if !tt.wantErr {
                want := "test-value_processed"
                if got := storage.data[tt.key]; got != want {
                    t.Errorf("ProcessData() stored %v, want %v", got, want)
                }
            }
        })
    }
}
```

### Integration Tests

```go
// test/integration/api_test.go
//go:build integration
// +build integration

package integration

import (
    "context"
    "net/http"
    "net/http/httptest"
    "testing"
    "time"

    "github.com/yourusername/yourproject/internal/server"
)

func TestAPIIntegration(t *testing.T) {
    // Setup test server
    srv := setupTestServer(t)
    ts := httptest.NewServer(srv.Handler())
    defer ts.Close()

    tests := []struct {
        name       string
        method     string
        path       string
        wantStatus int
    }{
        {
            name:       "health check",
            method:     http.MethodGet,
            path:       "/health",
            wantStatus: http.StatusOK,
        },
        {
            name:       "list resources",
            method:     http.MethodGet,
            path:       "/api/v1/resources",
            wantStatus: http.StatusOK,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
            defer cancel()

            req, err := http.NewRequestWithContext(ctx, tt.method, ts.URL+tt.path, nil)
            if err != nil {
                t.Fatal(err)
            }

            resp, err := http.DefaultClient.Do(req)
            if err != nil {
                t.Fatal(err)
            }
            defer resp.Body.Close()

            if resp.StatusCode != tt.wantStatus {
                t.Errorf("status = %d, want %d", resp.StatusCode, tt.wantStatus)
            }
        })
    }
}

func setupTestServer(t *testing.T) *server.Server {
    // Setup test dependencies
    // Return configured server
    return nil
}
```

## Build and Deployment

### Makefile

```makefile
.PHONY: build test lint clean docker-build docker-push proto proto-lint proto-breaking

# Variables
APP_NAME := myapp
VERSION := $(shell git describe --tags --always --dirty)
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')
LDFLAGS := -ldflags "-X main.version=$(VERSION) -X main.buildTime=$(BUILD_TIME)"

# Go parameters
GOCMD := go
GOBUILD := $(GOCMD) build
GOTEST := $(GOCMD) test
GOGET := $(GOCMD) get
GOMOD := $(GOCMD) mod
GORUN := $(GOCMD) run
BINARY_NAME := $(APP_NAME)
DOCKER_REGISTRY := your-registry

# Tool versions (managed via tools.go)
GOLANGCI_LINT := $(GORUN) github.com/golangci/golangci-lint/cmd/golangci-lint@latest
GOIMPORTS := $(GORUN) golang.org/x/tools/cmd/goimports@latest
PROTOC_GEN_GO := $(GORUN) google.golang.org/protobuf/cmd/protoc-gen-go@latest
PROTOC_GEN_GO_GRPC := $(GORUN) google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
BUF := $(GORUN) github.com/bufbuild/buf/cmd/buf@latest

# Proto parameters
PROTO_DIR := api
PROTO_OUT := pkg/pb

# Build
build: proto
	$(GOBUILD) $(LDFLAGS) -o bin/$(BINARY_NAME) ./cmd/$(APP_NAME)

build-linux: proto
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o bin/$(BINARY_NAME)-linux ./cmd/$(APP_NAME)

# Test
test:
	$(GOTEST) -v -race -coverprofile=coverage.out ./...

test-integration:
	$(GOTEST) -v -race -tags=integration ./test/integration/...

coverage:
	$(GOTEST) -coverprofile=coverage.out ./...
	$(GOCMD) tool cover -html=coverage.out

# Lint
lint: proto-lint
	$(GOLANGCI_LINT) run ./...

fmt:
	gofmt -s -w .
	$(GOIMPORTS) -w .

# Protobuf
proto:
	@echo "Generating protobuf stubs..."
	$(BUF) generate

proto-lint:
	@echo "Linting proto files..."
	$(BUF) lint

proto-breaking:
	@echo "Checking for breaking changes..."
	$(BUF) breaking --against '.git#branch=main'

proto-format:
	@echo "Formatting proto files..."
	$(BUF) format -w

proto-all: proto-format proto-lint proto

# Dependencies
deps:
	$(GOMOD) download
	$(GOMOD) tidy

# Tool dependencies (alternative: use tools.go)
tools:
	@echo "Tools are managed via 'go run' and don't need separate installation"
	@echo "To use tools.go pattern, create tools.go with blank imports"

# Clean
clean:
	rm -rf bin/
	rm -f coverage.out

# Docker
docker-build: proto
	docker build -t $(DOCKER_REGISTRY)/$(APP_NAME):$(VERSION) .
	docker tag $(DOCKER_REGISTRY)/$(APP_NAME):$(VERSION) $(DOCKER_REGISTRY)/$(APP_NAME):latest

docker-push:
	docker push $(DOCKER_REGISTRY)/$(APP_NAME):$(VERSION)
	docker push $(DOCKER_REGISTRY)/$(APP_NAME):latest

# Run
run: proto
	$(GOBUILD) $(LDFLAGS) -o bin/$(BINARY_NAME) ./cmd/$(APP_NAME)
	./bin/$(BINARY_NAME)

# CI targets
ci: proto-lint lint test

# Full build with all checks
all: proto-all lint test build
```

**Alternative: Using tools.go (recommended for version pinning)**

Create a `tools.go` file in your project root to pin tool versions:

```go
//go:build tools
// +build tools

// Package tools tracks tool dependencies
package tools

import (
	_ "github.com/bufbuild/buf/cmd/buf"
	_ "github.com/golangci/golangci-lint/cmd/golangci-lint"
	_ "golang.org/x/tools/cmd/goimports"
	_ "google.golang.org/grpc/cmd/protoc-gen-go-grpc"
	_ "google.golang.org/protobuf/cmd/protoc-gen-go"
)
```

Then update your Makefile to use versioned tools:

```makefile
# Tool versions from go.mod
GOLANGCI_LINT := $(GORUN) github.com/golangci/golangci-lint/cmd/golangci-lint
GOIMPORTS := $(GORUN) golang.org/x/tools/cmd/goimports
BUF := $(GORUN) github.com/bufbuild/buf/cmd/buf
```

### Dockerfile

```dockerfile
# Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git make

# Copy go mod files first (for better caching)
COPY go.mod go.sum ./
RUN go mod download

# Copy source code (including tools.go if present)
COPY . .

# Generate protobuf stubs
# Tools are run via 'go run' - no separate installation needed
RUN make proto

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-w -s" -o /app/bin/myapp ./cmd/myapp

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/bin/myapp .

# Copy configs
COPY configs/ ./configs/

EXPOSE 8080

CMD ["./myapp"]
```

COPY --from=builder /app/bin/myapp .

# Copy configs

COPY configs/ ./configs/

EXPOSE 8080

CMD ["./myapp"]

````

### .golangci.yml

```yaml
run:
  timeout: 5m
  tests: true
  skip-dirs:
    - vendor

linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - typecheck
    - unused
    - gofmt
    - goimports
    - misspell
    - gocritic
    - revive
    - gosec
    - bodyclose
    - noctx
    - rowserrcheck
    - sqlclosecheck
    - unconvert

linters-settings:
  errcheck:
    check-blank: true
  govet:
    check-shadowing: true
  gofmt:
    simplify: true
  revive:
    rules:
      - name: var-naming
      - name: package-comments
      - name: exported
````

## Performance Optimization

### Benchmarking

```go
// pkg/util/util_test.go
package util

import (
    "testing"
)

func BenchmarkStringConcatenation(b *testing.B) {
    tests := []struct {
        name string
        fn   func([]string) string
    }{
        {
            name: "plus operator",
            fn:   concatenateWithPlus,
        },
        {
            name: "strings.Builder",
            fn:   concatenateWithBuilder,
        },
        {
            name: "strings.Join",
            fn:   concatenateWithJoin,
        },
    }

    input := make([]string, 1000)
    for i := range input {
        input[i] = "test"
    }

    for _, tt := range tests {
        b.Run(tt.name, func(b *testing.B) {
            for i := 0; i < b.N; i++ {
                _ = tt.fn(input)
            }
        })
    }
}

func concatenateWithPlus(strs []string) string {
    result := ""
    for _, s := range strs {
        result += s
    }
    return result
}

func concatenateWithBuilder(strs []string) string {
    var builder strings.Builder
    for _, s := range strs {
        builder.WriteString(s)
    }
    return builder.String()
}

func concatenateWithJoin(strs []string) string {
    return strings.Join(strs, "")
}
```

### Profiling

```go
// Enable pprof in your application
import (
    _ "net/http/pprof"
)

func main() {
    go func() {
        log.Println(http.ListenAndServe("localhost:6060", nil))
    }()

    // Rest of application
}

// Generate CPU profile
// go test -cpuprofile=cpu.prof -bench=.
// go tool pprof cpu.prof

// Generate memory profile
// go test -memprofile=mem.prof -bench=.
// go tool pprof mem.prof
```

## Common Pitfalls

### Goroutine Leaks

```go
// BAD - Goroutine leak
func ProcessData() {
    ch := make(chan int)
    go func() {
        for val := range ch {
            process(val)
        }
    }()
    // ch never closed, goroutine never exits
}

// GOOD - Proper cleanup
func ProcessData(ctx context.Context) {
    ch := make(chan int)
    done := make(chan struct{})

    go func() {
        defer close(done)
        for {
            select {
            case val := <-ch:
                process(val)
            case <-ctx.Done():
                return
            }
        }
    }()

    // Do work
    close(ch)
    <-done // Wait for goroutine to finish
}
```

### Closing Channels

```go
// BAD - Close from receiver
go func() {
    for val := range ch {
        process(val)
    }
    close(ch) // Wrong!
}()

// GOOD - Close from sender
go func() {
    for i := 0; i < 10; i++ {
        ch <- i
    }
    close(ch) // Correct
}()
```

### Pointer to Loop Variable

```go
// BAD - All goroutines reference same variable
for _, item := range items {
    go func() {
        process(item) // Wrong!
    }()
}

// GOOD - Pass as parameter or create new variable
for _, item := range items {
    item := item // Create new variable
    go func() {
        process(item) // Correct
    }()
}

// Or
for _, item := range items {
    go func(i Item) {
        process(i)
    }(item)
}
```

## AI Assistant Guidelines

### When Reviewing Code

1. **Check Idioms**
   - Verify proper error handling (no ignored errors)
   - Check for `gofmt` compliance
   - Look for proper use of defer
   - Verify interface usage is appropriate
   - **Ensure functions accept interfaces and return concrete types**
   - **Check if functional options are used for configurable constructors**

2. **Check Concurrency**
   - Identify potential goroutine leaks
   - Verify proper channel closure
   - Check for race conditions
   - Ensure context is used correctly

3. **Check Performance**
   - Look for unnecessary allocations
   - Identify potential bottlenecks
   - Check for proper resource cleanup
   - Verify efficient data structure usage

4. **Check Testing**
   - Ensure adequate test coverage
   - Verify table-driven tests are used
   - Check for proper mocking
   - Look for integration tests

5. **Check Protobuf Usage**
   - Verify proto files follow naming conventions
   - Check for proper field numbering and reservation
   - Ensure backward compatibility is maintained
   - Verify validation logic is implemented

6. **Check MCP Servers**
   - Verify all tools have proper input schemas
   - Check that tool implementations match schemas
   - Ensure proper error handling and logging
   - Verify resources and prompts are well-documented
   - Check that context cancellation is handled properly

### When Writing Code

1. Start with interfaces for dependencies
2. Use table-driven tests from the beginning
3. Add proper context handling
4. Include comprehensive error handling
5. Document exported functions and types
6. Follow the standard project layout
7. Use structured logging
8. Implement graceful shutdown
9. **Design functions that accept interfaces and return concrete types**
10. **Use functional options for configurable constructors (3+ optional parameters)**
11. **Keep constructors simple with required parameters only when appropriate**

### When Writing Protobuf

1. Start with clear message and service definitions
2. Use semantic field names and proper numbering
3. Reserve deleted field numbers
4. Include validation methods
5. Document breaking changes
6. Use enums for fixed value sets
7. Leverage well-known types (timestamp, duration, etc.)
8. Plan for backward compatibility

### When Writing MCP Servers

1. Use strong typing for all tool arguments (structs with JSON tags)
2. Implement proper error handling in all tool handlers
3. Return structured JSON from tools
4. Use functional options pattern for server configuration
5. Respect context cancellation in long-running operations
6. Write comprehensive tests for all tools and handlers
7. Document tools, resources, and prompts clearly
8. Use structured logging throughout
9. Validate all input arguments
10. Make tools idempotent where possible

### When Debugging

1. Suggest adding debug logging with slog
2. Recommend using pprof for performance issues
3. Propose race detector (`go test -race`)
4. Check for common pitfalls (goroutine leaks, race conditions)
5. Suggest using delve debugger for complex issues
6. For gRPC issues, recommend enabling verbose logging
7. For MCP servers, test with stdio directly

## Resources

- [Effective Go](https://go.dev/doc/effective_go)
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [Standard Go Project Layout](https://github.com/golang-standards/project-layout)
- [Azure SDK for Go](https://github.com/Azure/azure-sdk-for-go)
- [golangci-lint](https://golangci-lint.run/)
- [Go Testing](https://go.dev/doc/tutorial/add-a-test)
- [Protocol Buffers Documentation](https://protobuf.dev/)
- [gRPC Go Documentation](https://grpc.io/docs/languages/go/)
- [Buf Documentation](https://buf.build/docs)
- [Google API Design Guide](https://cloud.google.com/apis/design) - Excellent guide for API design with protobuf
- [Model Context Protocol (MCP) Documentation](https://modelcontextprotocol.io/)
- [MCP Go SDK](https://github.com/mark3labs/mcp-go)

## Model Context Protocol (MCP)

### Overview

MCP (Model Context Protocol) servers provide AI assistants with tools, resources, and prompts. Go is an excellent choice for MCP servers due to its performance, strong typing, and excellent concurrency support.

### Installation

```bash
# Add MCP SDK
go get github.com/mark3labs/mcp-go

# For JSON schema generation
go get github.com/invopop/jsonschema
```

### Project Structure

```
.
├── cmd/
│   └── mcp-server/
│       └── main.go
├── internal/
│   ├── mcp/
│   │   ├── server.go          # MCP server implementation
│   │   ├── tools.go           # Tool definitions and implementations
│   │   ├── resources.go       # Resource definitions
│   │   └── prompts.go         # Prompt templates
│   └── azure/
│       └── client.go          # Azure client
├── pkg/
│   └── types/
│       └── schemas.go         # Shared type definitions
├── configs/
│   └── mcp.json              # MCP server configuration
└── go.mod
```

### MCP Server Implementation

```go
// internal/mcp/server.go
package mcp

import (
	"context"
	"fmt"
	"log/slog"

	"github.com/mark3labs/mcp-go/mcp"
	"github.com/mark3labs/mcp-go/server"

	"github.com/yourusername/yourproject/internal/azure"
)

// Server implements an MCP server for Azure resource management.
type Server struct {
	*server.MCPServer
	logger  *slog.Logger
	manager *azure.ResourceManager
}

// Config holds server configuration.
type Config struct {
	SubscriptionID string
	TenantID       string
	LogLevel       string
}

// Option configures the MCP server (functional options pattern).
type Option func(*Server)

// WithLogger sets a custom logger.
func WithLogger(logger *slog.Logger) Option {
	return func(s *Server) {
		s.logger = logger
	}
}

// WithManager sets a custom Azure resource manager.
func WithManager(manager *azure.ResourceManager) Option {
	return func(s *Server) {
		s.manager = manager
	}
}

// New creates a new MCP server.
// Accept interfaces, return concrete types.
func New(cfg Config, opts ...Option) (*Server, error) {
	if cfg.SubscriptionID == "" {
		return nil, fmt.Errorf("subscription ID is required")
	}

	// Create Azure manager
	manager, err := azure.NewResourceManager(cfg.SubscriptionID)
	if err != nil {
		return nil, fmt.Errorf("failed to create Azure manager: %w", err)
	}

	// Create MCP server
	mcpServer := server.NewMCPServer(
		"azure-mcp-server",
		"1.0.0",
	)

	s := &Server{
		MCPServer: mcpServer,
		logger:    slog.Default(),
		manager:   manager,
	}

	// Apply functional options
	for _, opt := range opts {
		opt(s)
	}

	// Register handlers
	s.registerTools()
	s.registerResources()
	s.registerPrompts()

	return s, nil
}

// Start starts the MCP server on stdio.
func (s *Server) Start(ctx context.Context) error {
	s.logger.Info("Starting MCP server")

	// Serve on stdio (standard for MCP servers)
	if err := s.ServeStdio(ctx); err != nil {
		return fmt.Errorf("server error: %w", err)
	}

	return nil
}

// Close cleans up server resources.
func (s *Server) Close() error {
	s.logger.Info("Closing MCP server")
	// Cleanup Azure manager if needed
	return nil
}
```

### Tool Definitions and Implementations

```go
// internal/mcp/tools.go
package mcp

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/mark3labs/mcp-go/mcp"
)

// Tool argument schemas
type ListResourceGroupsArgs struct {
	SubscriptionID string            `json:"subscription_id" jsonschema:"required,description=Azure subscription ID"`
	TagKey         string            `json:"tag_key,omitempty" jsonschema:"description=Filter by tag key"`
	TagValue       string            `json:"tag_value,omitempty" jsonschema:"description=Filter by tag value"`
	Tags           map[string]string `json:"tags,omitempty" jsonschema:"description=Filter by multiple tags"`
}

type GetResourceGroupArgs struct {
	SubscriptionID string `json:"subscription_id" jsonschema:"required,description=Azure subscription ID"`
	Name           string `json:"name" jsonschema:"required,description=Resource group name"`
}

type CreateResourceGroupArgs struct {
	SubscriptionID string            `json:"subscription_id" jsonschema:"required,description=Azure subscription ID"`
	Name           string            `json:"name" jsonschema:"required,description=Resource group name"`
	Location       string            `json:"location" jsonschema:"required,description=Azure region (e.g., eastus)"`
	Tags           map[string]string `json:"tags,omitempty" jsonschema:"description=Resource tags"`
}

// registerTools registers all available tools with the MCP server.
func (s *Server) registerTools() {
	// List resource groups tool
	s.AddTool(
		mcp.NewTool("list_resource_groups",
			mcp.WithDescription("List all resource groups in an Azure subscription"),
			mcp.WithString("subscription_id",
				mcp.Required(),
				mcp.Description("Azure subscription ID"),
			),
			mcp.WithString("tag_key",
				mcp.Description("Filter by tag key"),
			),
			mcp.WithString("tag_value",
				mcp.Description("Filter by tag value"),
			),
		),
		s.handleListResourceGroups,
	)

	// Get resource group tool
	s.AddTool(
		mcp.NewTool("get_resource_group",
			mcp.WithDescription("Get details of a specific resource group"),
			mcp.WithString("subscription_id",
				mcp.Required(),
				mcp.Description("Azure subscription ID"),
			),
			mcp.WithString("name",
				mcp.Required(),
				mcp.Description("Resource group name"),
			),
		),
		s.handleGetResourceGroup,
	)

	// Create resource group tool
	s.AddTool(
		mcp.NewTool("create_resource_group",
			mcp.WithDescription("Create a new Azure resource group"),
			mcp.WithString("subscription_id",
				mcp.Required(),
				mcp.Description("Azure subscription ID"),
			),
			mcp.WithString("name",
				mcp.Required(),
				mcp.Description("Resource group name"),
			),
			mcp.WithString("location",
				mcp.Required(),
				mcp.Description("Azure region (e.g., eastus)"),
			),
			mcp.WithObject("tags",
				mcp.Description("Resource tags as key-value pairs"),
			),
		),
		s.handleCreateResourceGroup,
	)
}

// handleListResourceGroups implements the list_resource_groups tool.
func (s *Server) handleListResourceGroups(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	var args ListResourceGroupsArgs
	if err := json.Unmarshal(request.Params.Arguments, &args); err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("invalid arguments: %v", err)), nil
	}

	s.logger.Info("Listing resource groups",
		"subscription_id", args.SubscriptionID,
		"tag_key", args.TagKey,
		"tag_value", args.TagValue,
	)

	// Build tag filter
	var tags map[string]string
	if args.TagKey != "" && args.TagValue != "" {
		tags = map[string]string{args.TagKey: args.TagValue}
	} else if len(args.Tags) > 0 {
		tags = args.Tags
	}

	// List resource groups from Azure
	groups, err := s.manager.ListByResourceGroup(ctx, "", tags)
	if err != nil {
		s.logger.Error("Failed to list resource groups", "error", err)
		return mcp.NewToolResultError(fmt.Sprintf("failed to list resource groups: %v", err)), nil
	}

	// Format response
	type ResourceGroup struct {
		Name     string            `json:"name"`
		Location string            `json:"location"`
		Tags     map[string]string `json:"tags"`
		ID       string            `json:"id"`
	}

	result := struct {
		TotalCount     int             `json:"total_count"`
		ResourceGroups []ResourceGroup `json:"resource_groups"`
	}{
		TotalCount: len(groups),
	}

	for _, group := range groups {
		result.ResourceGroups = append(result.ResourceGroups, ResourceGroup{
			Name:     *group.Name,
			Location: *group.Location,
			Tags:     group.Tags,
			ID:       *group.ID,
		})
	}

	resultJSON, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("failed to marshal result: %v", err)), nil
	}

	return mcp.NewToolResultText(string(resultJSON)), nil
}

// handleGetResourceGroup implements the get_resource_group tool.
func (s *Server) handleGetResourceGroup(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	var args GetResourceGroupArgs
	if err := json.Unmarshal(request.Params.Arguments, &args); err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("invalid arguments: %v", err)), nil
	}

	s.logger.Info("Getting resource group",
		"subscription_id", args.SubscriptionID,
		"name", args.Name,
	)

	group, err := s.manager.GetByID(ctx, args.Name)
	if err != nil {
		s.logger.Error("Failed to get resource group", "error", err, "name", args.Name)
		return mcp.NewToolResultError(fmt.Sprintf("failed to get resource group: %v", err)), nil
	}

	type ResourceGroup struct {
		Name     string            `json:"name"`
		Location string            `json:"location"`
		Tags     map[string]string `json:"tags"`
		ID       string            `json:"id"`
		Type     string            `json:"type"`
	}

	result := ResourceGroup{
		Name:     *group.Name,
		Location: *group.Location,
		Tags:     group.Tags,
		ID:       *group.ID,
		Type:     *group.Type,
	}

	resultJSON, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("failed to marshal result: %v", err)), nil
	}

	return mcp.NewToolResultText(string(resultJSON)), nil
}

// handleCreateResourceGroup implements the create_resource_group tool.
func (s *Server) handleCreateResourceGroup(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	var args CreateResourceGroupArgs
	if err := json.Unmarshal(request.Params.Arguments, &args); err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("invalid arguments: %v", err)), nil
	}

	s.logger.Info("Creating resource group",
		"subscription_id", args.SubscriptionID,
		"name", args.Name,
		"location", args.Location,
	)

	// Create resource group
	// Note: This is a simplified example
	// In production, you'd use the Azure SDK's resource groups client
	result := struct {
		Name     string            `json:"name"`
		Location string            `json:"location"`
		Tags     map[string]string `json:"tags"`
		Status   string            `json:"status"`
	}{
		Name:     args.Name,
		Location: args.Location,
		Tags:     args.Tags,
		Status:   "created",
	}

	resultJSON, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		return mcp.NewToolResultError(fmt.Sprintf("failed to marshal result: %v", err)), nil
	}

	return mcp.NewToolResultText(string(resultJSON)), nil
}
```

### Resource Definitions

```go
// internal/mcp/resources.go
package mcp

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/mark3labs/mcp-go/mcp"
)

// registerResources registers all available resources with the MCP server.
func (s *Server) registerResources() {
	// Azure subscriptions resource
	s.AddResource(
		"azure://subscriptions",
		"Azure Subscriptions",
		"List of available Azure subscriptions",
		"application/json",
		s.handleSubscriptionsResource,
	)

	// Azure regions resource
	s.AddResource(
		"azure://regions",
		"Azure Regions",
		"List of available Azure regions",
		"application/json",
		s.handleRegionsResource,
	)

	// Best practices resource
	s.AddResource(
		"azure://docs/best-practices",
		"Azure Best Practices",
		"Best practices for Azure resource management",
		"text/markdown",
		s.handleBestPracticesResource,
	)
}

// handleSubscriptionsResource returns subscription information.
func (s *Server) handleSubscriptionsResource(ctx context.Context, request mcp.ReadResourceRequest) (*mcp.ReadResourceResult, error) {
	s.logger.Info("Reading subscriptions resource")

	subscriptions := []struct {
		ID     string `json:"id"`
		Name   string `json:"name"`
		State  string `json:"state"`
		Tenant string `json:"tenant_id"`
	}{
		{
			ID:     s.manager.SubscriptionID(),
			Name:   "Primary Subscription",
			State:  "Enabled",
			Tenant: "tenant-id",
		},
	}

	data, err := json.MarshalIndent(subscriptions, "", "  ")
	if err != nil {
		return nil, fmt.Errorf("failed to marshal subscriptions: %w", err)
	}

	return &mcp.ReadResourceResult{
		Contents: []mcp.ResourceContents{
			{
				URI:      request.Params.URI,
				MimeType: "application/json",
				Text:     string(data),
			},
		},
	}, nil
}

// handleRegionsResource returns available Azure regions.
func (s *Server) handleRegionsResource(ctx context.Context, request mcp.ReadResourceRequest) (*mcp.ReadResourceResult, error) {
	s.logger.Info("Reading regions resource")

	regions := []struct {
		Name        string `json:"name"`
		DisplayName string `json:"display_name"`
	}{
		{Name: "eastus", DisplayName: "East US"},
		{Name: "westus", DisplayName: "West US"},
		{Name: "centralus", DisplayName: "Central US"},
		{Name: "northeurope", DisplayName: "North Europe"},
		{Name: "westeurope", DisplayName: "West Europe"},
	}

	data, err := json.MarshalIndent(regions, "", "  ")
	if err != nil {
		return nil, fmt.Errorf("failed to marshal regions: %w", err)
	}

	return &mcp.ReadResourceResult{
		Contents: []mcp.ResourceContents{
			{
				URI:      request.Params.URI,
				MimeType: "application/json",
				Text:     string(data),
			},
		},
	}, nil
}

// handleBestPracticesResource returns best practices documentation.
func (s *Server) handleBestPracticesResource(ctx context.Context, request mcp.ReadResourceRequest) (*mcp.ReadResourceResult, error) {
	s.logger.Info("Reading best practices resource")

	content := `# Azure Best Practices

## Resource Groups
- Use consistent naming conventions across all resources
- Tag all resources appropriately for cost tracking and organization
- Group related resources together by lifecycle and ownership
- Use separate resource groups for different environments (dev, staging, prod)

## Security
- Enable Azure AD authentication for all services
- Use managed identities instead of service principals when possible
- Apply least privilege access with Azure RBAC
- Enable Azure Security Center recommendations
- Use Azure Key Vault for secrets management

## Cost Management
- Set up budgets and alerts for cost monitoring
- Use tags for cost allocation and tracking
- Review Azure Advisor cost recommendations regularly
- Implement auto-shutdown for non-production resources
- Use reserved instances for predictable workloads

## Monitoring
- Enable diagnostic settings for all resources
- Send logs to Log Analytics workspace
- Configure alerts for critical metrics
- Use Application Insights for application monitoring
- Implement distributed tracing
`

	return &mcp.ReadResourceResult{
		Contents: []mcp.ResourceContents{
			{
				URI:      request.Params.URI,
				MimeType: "text/markdown",
				Text:     content,
			},
		},
	}, nil
}
```

### Prompt Templates

```go
// internal/mcp/prompts.go
package mcp

import (
	"context"
	"fmt"

	"github.com/mark3labs/mcp-go/mcp"
)

// registerPrompts registers all available prompts with the MCP server.
func (s *Server) registerPrompts() {
	// Troubleshoot resource prompt
	s.AddPrompt(
		"troubleshoot_resource",
		"Troubleshoot Azure resource issues",
		[]mcp.PromptArgument{
			{
				Name:        "resource_type",
				Description: "Type of Azure resource (e.g., VM, Storage Account)",
				Required:    true,
			},
			{
				Name:        "error_message",
				Description: "Error message or symptom",
				Required:    true,
			},
		},
		s.handleTroubleshootPrompt,
	)

	// Optimize costs prompt
	s.AddPrompt(
		"optimize_costs",
		"Get recommendations for optimizing Azure costs",
		[]mcp.PromptArgument{
			{
				Name:        "resource_group",
				Description: "Resource group to analyze",
				Required:    true,
			},
		},
		s.handleOptimizeCostsPrompt,
	)
}

// handleTroubleshootPrompt generates a troubleshooting prompt.
func (s *Server) handleTroubleshootPrompt(ctx context.Context, request mcp.GetPromptRequest) (*mcp.GetPromptResult, error) {
	args := request.Params.Arguments

	resourceType, ok := args["resource_type"].(string)
	if !ok {
		return nil, fmt.Errorf("resource_type argument is required")
	}

	errorMessage, ok := args["error_message"].(string)
	if !ok {
		return nil, fmt.Errorf("error_message argument is required")
	}

	s.logger.Info("Generating troubleshoot prompt",
		"resource_type", resourceType,
		"error", errorMessage,
	)

	prompt := fmt.Sprintf(`You are an Azure cloud infrastructure expert troubleshooting a %s resource.

Error/Symptom: %s

Please provide:
1. **Likely Causes**: List the most probable causes of this issue
2. **Diagnostic Steps**: Provide step-by-step commands or checks to diagnose the problem
3. **Solutions**: Recommend specific solutions, prioritized by likelihood
4. **Prevention**: Suggest how to prevent this issue in the future

Use Azure CLI commands and best practices in your response.`, resourceType, errorMessage)

	return &mcp.GetPromptResult{
		Messages: []mcp.PromptMessage{
			{
				Role: "user",
				Content: mcp.TextContent{
					Type: "text",
					Text: prompt,
				},
			},
		},
	}, nil
}

// handleOptimizeCostsPrompt generates a cost optimization prompt.
func (s *Server) handleOptimizeCostsPrompt(ctx context.Context, request mcp.GetPromptRequest) (*mcp.GetPromptResult, error) {
	args := request.Params.Arguments

	resourceGroup, ok := args["resource_group"].(string)
	if !ok {
		return nil, fmt.Errorf("resource_group argument is required")
	}

	s.logger.Info("Generating cost optimization prompt",
		"resource_group", resourceGroup,
	)

	prompt := fmt.Sprintf(`You are an Azure cost optimization specialist analyzing the resource group: %s

Please analyze the resources and provide:
1. **Cost Analysis**: Identify the top cost drivers
2. **Optimization Opportunities**: List specific ways to reduce costs
3. **Right-sizing Recommendations**: Suggest appropriate VM/resource sizes
4. **Reserved Instances**: Recommend where reserved instances would save money
5. **Cleanup Suggestions**: Identify unused or underutilized resources

Provide specific Azure CLI commands or ARM template changes where applicable.`, resourceGroup)

	return &mcp.GetPromptResult{
		Messages: []mcp.PromptMessage{
			{
				Role: "user",
				Content: mcp.TextContent{
					Type: "text",
					Text: prompt,
				},
			},
		},
	}, nil
}
```

### Main Application

```go
// cmd/mcp-server/main.go
package main

import (
	"context"
	"flag"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"github.com/yourusername/yourproject/internal/mcp"
)

func main() {
	if err := run(); err != nil {
		slog.Error("Application error", "error", err)
		os.Exit(1)
	}
}

func run() error {
	// Parse flags
	var (
		subscriptionID = flag.String("subscription", os.Getenv("AZURE_SUBSCRIPTION_ID"), "Azure subscription ID")
		tenantID       = flag.String("tenant", os.Getenv("AZURE_TENANT_ID"), "Azure tenant ID")
		logLevel       = flag.String("log-level", "info", "Log level (debug, info, warn, error)")
	)
	flag.Parse()

	// Setup logger
	level := parseLogLevel(*logLevel)
	logger := slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{
		Level: level,
	}))
	slog.SetDefault(logger)

	// Create MCP server
	cfg := mcp.Config{
		SubscriptionID: *subscriptionID,
		TenantID:       *tenantID,
		LogLevel:       *logLevel,
	}

	server, err := mcp.New(cfg, mcp.WithLogger(logger))
	if err != nil {
		return fmt.Errorf("failed to create server: %w", err)
	}
	defer server.Close()

	// Setup context with cancellation
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Handle shutdown signals
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-sigChan
		logger.Info("Received shutdown signal")
		cancel()
	}()

	// Start server
	logger.Info("Starting MCP server",
		"subscription_id", *subscriptionID,
		"tenant_id", *tenantID,
	)

	if err := server.Start(ctx); err != nil {
		return fmt.Errorf("server error: %w", err)
	}

	return nil
}

func parseLogLevel(level string) slog.Level {
	switch level {
	case "debug":
		return slog.LevelDebug
	case "info":
		return slog.LevelInfo
	case "warn":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}
```

### MCP Configuration File

```json
{
  "mcpServers": {
    "azure-resources": {
      "command": "/path/to/mcp-server",
      "args": [
        "--subscription",
        "your-subscription-id",
        "--tenant",
        "your-tenant-id",
        "--log-level",
        "info"
      ],
      "env": {
        "AZURE_SUBSCRIPTION_ID": "your-subscription-id",
        "AZURE_TENANT_ID": "your-tenant-id"
      }
    }
  }
}
```

### Testing MCP Server

```go
// internal/mcp/server_test.go
package mcp

import (
	"context"
	"encoding/json"
	"testing"

	"github.com/mark3labs/mcp-go/mcp"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestListResourceGroupsTool(t *testing.T) {
	// Create test server
	cfg := Config{
		SubscriptionID: "test-sub",
		TenantID:       "test-tenant",
	}

	server, err := New(cfg)
	require.NoError(t, err)
	defer server.Close()

	// Create test request
	args := ListResourceGroupsArgs{
		SubscriptionID: "test-sub",
	}
	argsJSON, err := json.Marshal(args)
	require.NoError(t, err)

	request := mcp.CallToolRequest{
		Params: mcp.CallToolParams{
			Name:      "list_resource_groups",
			Arguments: argsJSON,
		},
	}

	// Call tool
	result, err := server.handleListResourceGroups(context.Background(), request)
	require.NoError(t, err)
	assert.NotNil(t, result)
}

func TestGetResourceGroupTool(t *testing.T) {
	cfg := Config{
		SubscriptionID: "test-sub",
		TenantID:       "test-tenant",
	}

	server, err := New(cfg)
	require.NoError(t, err)
	defer server.Close()

	args := GetResourceGroupArgs{
		SubscriptionID: "test-sub",
		Name:           "test-rg",
	}
	argsJSON, err := json.Marshal(args)
	require.NoError(t, err)

	request := mcp.CallToolRequest{
		Params: mcp.CallToolParams{
			Name:      "get_resource_group",
			Arguments: argsJSON,
		},
	}

	result, err := server.handleGetResourceGroup(context.Background(), request)
	require.NoError(t, err)
	assert.NotNil(t, result)
}

func TestTroubleshootPrompt(t *testing.T) {
	cfg := Config{
		SubscriptionID: "test-sub",
		TenantID:       "test-tenant",
	}

	server, err := New(cfg)
	require.NoError(t, err)
	defer server.Close()

	request := mcp.GetPromptRequest{
		Params: mcp.GetPromptParams{
			Name: "troubleshoot_resource",
			Arguments: map[string]interface{}{
				"resource_type":  "Virtual Machine",
				"error_message":  "VM failed to start",
			},
		},
	}

	result, err := server.handleTroubleshootPrompt(context.Background(), request)
	require.NoError(t, err)
	assert.NotNil(t, result)
	assert.Len(t, result.Messages, 1)
	assert.Contains(t, result.Messages[0].Content.Text, "Virtual Machine")
}
```

### Makefile Integration

Add to your existing Makefile:

```makefile
# MCP Server targets
.PHONY: mcp-build mcp-run mcp-test mcp-install

# Build MCP server
mcp-build:
	$(GOBUILD) $(LDFLAGS) -o bin/mcp-server ./cmd/mcp-server

# Run MCP server
mcp-run: mcp-build
	./bin/mcp-server \
		--subscription $(AZURE_SUBSCRIPTION_ID) \
		--tenant $(AZURE_TENANT_ID) \
		--log-level debug

# Test MCP server
mcp-test:
	$(GOTEST) -v ./internal/mcp/...

# Install MCP server to system
mcp-install: mcp-build
	cp bin/mcp-server $(HOME)/.local/bin/
```

### Docker Support for MCP Server

```dockerfile
# Dockerfile for MCP server
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Install dependencies
RUN apk add --no-cache git make

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build MCP server
RUN make mcp-build

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy MCP server binary
COPY --from=builder /app/bin/mcp-server .

# MCP servers typically run on stdio
# So we don't need to expose ports

ENTRYPOINT ["./mcp-server"]
```

### Best Practices for MCP Servers in Go

1. **Strong Typing**: Use structs for all tool arguments and responses
2. **Error Handling**: Return descriptive errors from tool handlers
3. **Logging**: Use structured logging (slog) throughout
4. **Context**: Always respect context cancellation
5. **Testing**: Write unit tests for all tool handlers
6. **Documentation**: Document all tools, resources, and prompts clearly
7. **Validation**: Validate all input arguments
8. **Idempotency**: Make tools idempotent where possible
9. **Performance**: Use goroutines for concurrent operations
10. **Security**: Never expose sensitive credentials in responses

## Editor Setup

For LazyVim (preferred) or VSCode configuration, see [EDITORS.md](./EDITORS.md).

## Version History

- 1.0.0 - Initial version with comprehensive Go development guidelines
