# gRPC and Protobuf Standards and Best Practices

# APPLIES-TO: grpc, proto

Standards for defining Protocol Buffer messages and gRPC services.

## Table of Contents

- [Core Principles](#core-principles)
- [Protobuf Message Design](#protobuf-message-design)
- [Service Definitions](#service-definitions)
- [Naming Conventions](#naming-conventions)
- [Versioning and Compatibility](#versioning-and-compatibility)
- [Common Patterns](#common-patterns)
- [Security](#security)
- [AI Assistant Guidelines](#ai-assistant-guidelines)

## Core Principles

1. **Backward Compatibility**: Never break existing clients
2. **Clear Naming**: Descriptive message and field names
3. **Documentation**: Comprehensive comments
4. **Idempotency**: Safe to retry operations
5. **Error Handling**: Use status codes and details

## Protobuf Message Design

### Basic Message Structure

```protobuf
// user.proto
syntax = "proto3";

package myapp.v1;

option go_package = "github.com/username/myapp/api/v1;apiv1";

import "google/protobuf/timestamp.proto";
import "google/protobuf/empty.proto";

// User represents a user account in the system.
//
// Fields are numbered for backward compatibility.
// Never reuse field numbers.
message User {
  // Unique identifier for the user.
  // Required field.
  string id = 1;

  // User's email address.
  // Must be unique across all users.
  string email = 2;

  // Display name for the user.
  // Optional field.
  string name = 3;

  // Account creation timestamp.
  google.protobuf.Timestamp created_at = 4;

  // Account status.
  UserStatus status = 5;

  // User preferences.
  // Optional nested message.
  UserPreferences preferences = 6;
}

// UserStatus indicates the current state of a user account.
enum UserStatus {
  // Default value must be first.
  USER_STATUS_UNSPECIFIED = 0;
  USER_STATUS_ACTIVE = 1;
  USER_STATUS_SUSPENDED = 2;
  USER_STATUS_DELETED = 3;
}

// UserPreferences stores user-specific settings.
message UserPreferences {
  string language = 1;
  string timezone = 2;
  bool email_notifications = 3;
}
```

### Field Numbering

```protobuf
// ✅ Good - sequential numbering
message Product {
  string id = 1;
  string name = 2;
  int32 price = 3;
  string description = 4;
}

// ❌ Bad - gaps in numbering (wastes space)
message Product {
  string id = 1;
  string name = 10;
  int32 price = 20;
  string description = 30;
}

// ✅ Good - reserve removed fields
message Product {
  reserved 2, 5 to 10;
  reserved "old_field", "deprecated_field";

  string id = 1;
  string name = 3;
  int32 price = 4;
}
```

### Field Types

```protobuf
// Scalar types
message ScalarTypes {
  // Numbers
  int32 age = 1;           // -2^31 to 2^31-1
  int64 large_number = 2;  // -2^63 to 2^63-1
  uint32 count = 3;        // 0 to 2^32-1
  uint64 big_count = 4;    // 0 to 2^64-1
  float price = 5;         // 32-bit float
  double precise = 6;      // 64-bit float

  // Boolean
  bool active = 7;

  // String (UTF-8 or ASCII)
  string name = 8;

  // Bytes (arbitrary data)
  bytes data = 9;
}

// ✅ Good - use appropriate types
message Order {
  string id = 1;                    // UUID or unique string
  int64 user_id = 2;                // Large number IDs
  int32 quantity = 3;               // Small counts
  int64 amount_cents = 4;           // Money in smallest unit
  google.protobuf.Timestamp created_at = 5;
}

// ❌ Bad - inappropriate types
message Order {
  int32 id = 1;                     // IDs should be string or int64
  string quantity = 2;              // Should be int32
  float amount = 3;                 // Never use float for money
  string created_at = 4;            // Should be Timestamp
}
```

### Repeated Fields

```protobuf
// ✅ Good - repeated for lists
message UserList {
  repeated User users = 1;
}

message User {
  string id = 1;
  repeated string tags = 2;
  repeated Address addresses = 3;
}

// ✅ Good - map for key-value pairs
message UserMetadata {
  map<string, string> labels = 1;
  map<string, int32> scores = 2;
}
```

### Nested Messages

```protobuf
// ✅ Good - nested messages for grouping
message Order {
  string id = 1;

  // Shipping information
  message ShippingInfo {
    string address = 1;
    string city = 2;
    string postal_code = 3;
  }

  ShippingInfo shipping = 2;

  // Payment information
  message PaymentInfo {
    string method = 1;
    string last_four = 2;
  }

  PaymentInfo payment = 3;
}

// ✅ Also good - separate messages for reusability
message Address {
  string line1 = 1;
  string line2 = 2;
  string city = 3;
  string state = 4;
  string postal_code = 5;
  string country = 6;
}

message Order {
  string id = 1;
  Address shipping_address = 2;
  Address billing_address = 3;
}
```

## Service Definitions

### Basic Service

```protobuf
// user_service.proto
syntax = "proto3";

package myapp.v1;

option go_package = "github.com/username/myapp/api/v1;apiv1";

import "user.proto";
import "google/protobuf/empty.proto";

// UserService manages user accounts.
service UserService {
  // GetUser retrieves a user by ID.
  rpc GetUser(GetUserRequest) returns (GetUserResponse);

  // ListUsers returns a paginated list of users.
  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);

  // CreateUser creates a new user account.
  rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);

  // UpdateUser modifies an existing user.
  rpc UpdateUser(UpdateUserRequest) returns (UpdateUserResponse);

  // DeleteUser removes a user account.
  rpc DeleteUser(DeleteUserRequest) returns (google.protobuf.Empty);

  // WatchUsers streams user updates.
  rpc WatchUsers(WatchUsersRequest) returns (stream User);
}

// GetUserRequest is the request for GetUser.
message GetUserRequest {
  string id = 1;
}

// GetUserResponse is the response for GetUser.
message GetUserResponse {
  User user = 1;
}

// ListUsersRequest is the request for ListUsers.
message ListUsersRequest {
  // Maximum number of users to return.
  int32 page_size = 1;

  // Token from previous response for pagination.
  string page_token = 2;

  // Filter expression (optional).
  string filter = 3;
}

// ListUsersResponse is the response for ListUsers.
message ListUsersResponse {
  repeated User users = 1;

  // Token for next page, empty if no more pages.
  string next_page_token = 2;

  // Total count of users matching filter.
  int32 total_size = 3;
}
```

### Streaming RPCs

```protobuf
service DataService {
  // Server streaming - multiple responses
  rpc SubscribeToUpdates(SubscribeRequest) returns (stream Update);

  // Client streaming - multiple requests
  rpc UploadData(stream DataChunk) returns (UploadResponse);

  // Bidirectional streaming
  rpc Chat(stream ChatMessage) returns (stream ChatMessage);
}

// ✅ Good - server streaming for real-time updates
message SubscribeRequest {
  string topic = 1;
}

message Update {
  google.protobuf.Timestamp timestamp = 1;
  string event_type = 2;
  bytes payload = 3;
}

// ✅ Good - client streaming for large uploads
message DataChunk {
  bytes data = 1;
  int32 sequence = 2;
}

message UploadResponse {
  string file_id = 1;
  int64 total_bytes = 2;
}
```

## Naming Conventions

### Message Names

```protobuf
// ✅ Good - PascalCase for messages and enums
message UserAccount {}
message OrderItem {}
enum UserStatus {}

// ❌ Bad
message user_account {}
message orderitem {}
```

### Field Names

```protobuf
// ✅ Good - snake_case for fields
message User {
  string user_id = 1;
  string email_address = 2;
  google.protobuf.Timestamp created_at = 3;
}

// ❌ Bad
message User {
  string userId = 1;
  string EmailAddress = 2;
  google.protobuf.Timestamp CreatedAt = 3;
}
```

### Service Names

```protobuf
// ✅ Good - Service suffix, PascalCase
service UserService {}
service OrderService {}
service PaymentService {}

// ❌ Bad
service Users {}
service user_service {}
```

### RPC Names

```protobuf
// ✅ Good - verb-noun pattern
service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
  rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
  rpc UpdateUser(UpdateUserRequest) returns (UpdateUserResponse);
  rpc DeleteUser(DeleteUserRequest) returns (google.protobuf.Empty);
  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);
}

// ✅ Good - standard verbs
rpc Get...()
rpc List...()
rpc Create...()
rpc Update...()
rpc Delete...()
rpc Search...()
rpc Watch...()
```

### Package Names

```protobuf
// ✅ Good - lowercase, versioned
package myapp.users.v1;
package myapp.orders.v2;

// ❌ Bad
package MyApp.Users.V1;
package myapp.users;  // Missing version
```

## Versioning and Compatibility

### API Versioning

```protobuf
// v1/user.proto
syntax = "proto3";
package myapp.v1;
option go_package = "github.com/username/myapp/api/v1;apiv1";

message User {
  string id = 1;
  string email = 2;
}

// v2/user.proto - new version
syntax = "proto3";
package myapp.v2;
option go_package = "github.com/username/myapp/api/v2;apiv2";

message User {
  string id = 1;
  string email = 2;
  string name = 3;        // New field
  UserStatus status = 4;  // New field
}
```

### Adding Fields

```protobuf
// Version 1
message User {
  string id = 1;
  string email = 2;
}

// Version 2 - ✅ Safe: add new fields
message User {
  string id = 1;
  string email = 2;
  string name = 3;        // New optional field
  repeated string tags = 4;  // New repeated field
}
```

### Removing Fields

```protobuf
// Version 1
message User {
  string id = 1;
  string email = 2;
  string deprecated_field = 3;
}

// Version 2 - ✅ Safe: reserve and remove
message User {
  reserved 3;
  reserved "deprecated_field";

  string id = 1;
  string email = 2;
  string name = 4;  // Use new number
}
```

### Renaming Fields

```protobuf
// ❌ Bad - breaking change
message User {
  string id = 1;
  string full_name = 2;  // Was "name"
}

// ✅ Good - add new field, deprecate old
message User {
  string id = 1;
  string name = 2 [deprecated = true];
  string full_name = 3;
}
```

## Common Patterns

### Request/Response Wrappers

```protobuf
// ✅ Good - always use request/response messages
service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
}

message GetUserRequest {
  string id = 1;
}

message GetUserResponse {
  User user = 1;
}

// ❌ Bad - using message directly
service UserService {
  rpc GetUser(User) returns (User);
}
```

### Pagination

```protobuf
// ✅ Good - token-based pagination
message ListUsersRequest {
  int32 page_size = 1;
  string page_token = 2;
}

message ListUsersResponse {
  repeated User users = 1;
  string next_page_token = 2;
  int32 total_size = 3;
}
```

### Filtering and Sorting

```protobuf
message ListUsersRequest {
  int32 page_size = 1;
  string page_token = 2;

  // Filter using CEL or simple expressions
  string filter = 3;  // e.g., "status = 'ACTIVE' AND created_at > '2024-01-01'"

  // Sort order
  string order_by = 4;  // e.g., "created_at desc, name"
}
```

### Long-Running Operations

```protobuf
import "google/longrunning/operations.proto";

service JobService {
  // Returns an Operation that tracks the job.
  rpc StartJob(StartJobRequest) returns (google.longrunning.Operation);
}

message StartJobRequest {
  string job_type = 1;
  map<string, string> parameters = 2;
}

message JobResult {
  string job_id = 1;
  JobStatus status = 2;
  string output_path = 3;
}
```

### Error Details

```protobuf
import "google/rpc/status.proto";
import "google/rpc/error_details.proto";

// Use status codes in responses
message ErrorResponse {
  google.rpc.Status status = 1;
}

// In Go (following AGENTS_GO.md)
// return nil, status.Error(codes.InvalidArgument, "invalid email format")

// With details
// st := status.New(codes.InvalidArgument, "validation failed")
// st, _ = st.WithDetails(&errdetails.BadRequest{
//     FieldViolations: []*errdetails.BadRequest_FieldViolation{
//         {Field: "email", Description: "invalid format"},
//     },
// })
// return nil, st.Err()
```

## Security

### Authentication

```protobuf
// Use gRPC metadata for authentication
service SecureService {
  rpc GetData(GetDataRequest) returns (GetDataResponse);
}

// In Go (following AGENTS_GO.md)
// ctx = metadata.AppendToOutgoingContext(ctx, "authorization", "Bearer "+token)
```

### TLS

```protobuf
// Always use TLS in production
// Go example (following AGENTS_GO.md)
/*
creds, err := credentials.NewClientTLSFromFile("cert.pem", "")
if err != nil {
    return nil, fmt.Errorf("loading TLS credentials: %w", err)
}

conn, err := grpc.Dial("localhost:50051", grpc.WithTransportCredentials(creds))
*/
```

### Field-Level Security

```protobuf
message User {
  string id = 1;
  string email = 2;

  // Sensitive fields should be marked in documentation
  // Hash on server, never store plaintext
  string password_hash = 3;  // SENSITIVE: Server-side only

  // PII should be documented
  string ssn = 4;  // PII: Encrypt at rest
}
```

## AI Assistant Guidelines

### When Designing Protobuf

1. **Start with messages**: Define data structures first
2. **Add services**: Define RPCs after messages are clear
3. **Version early**: Use v1 from the start
4. **Document thoroughly**: Every message and field
5. **Consider compatibility**: Never break existing clients
6. **Use well-known types**: Timestamp, Duration, Empty

### Example AI Prompt

```
Create a gRPC service following .ai/context/AGENTS_GRPC.md:

For: Order management system
Requirements:
- CRUD operations for orders
- List with pagination
- Stream real-time order updates
- Include error handling
- Use buf for code generation (recommended)
- Use Go package option (per AGENTS_GO.md)
- Full documentation
```

### When Reviewing Protobuf

Check for:

- [ ] Syntax version specified (proto3)
- [ ] Package name includes version
- [ ] go_package option set correctly
- [ ] All messages documented
- [ ] Field numbering sequential
- [ ] Removed fields reserved
- [ ] Request/response wrappers used
- [ ] Appropriate field types
- [ ] Pagination implemented for lists
- [ ] Error handling patterns

### Code Generation

**Modern Approach (Recommended): buf**

[buf](https://buf.build) is a modern alternative to `protoc` with built-in linting, breaking change detection, and dependency management.

```bash
# Install buf
brew install bufbuild/buf/buf

# Initialize in your project
buf mod init

# Create buf.yaml
cat > buf.yaml << EOF
version: v1
breaking:
  use:
    - FILE
lint:
  use:
    - DEFAULT
deps:
  - buf.build/googleapis/googleapis
  - buf.build/grpc-ecosystem/grpc-gateway
EOF

# Create buf.gen.yaml
cat > buf.gen.yaml << EOF
version: v1
managed:
  enabled: true
  go_package_prefix:
    default: github.com/username/myapp
plugins:
  - plugin: buf.build/protocolbuffers/go:v1.31.0
    out: gen/go
    opt: paths=source_relative
  - plugin: buf.build/grpc/go:v1.3.0
    out: gen/go
    opt: paths=source_relative
EOF

# Download dependencies
buf mod update

# Generate code
buf generate

# Lint protos
buf lint

# Format protos
buf format -w

# Check for breaking changes
buf breaking --against '.git#branch=main'
```

**Benefits of buf:**

- ✅ Built-in linting with opinionated rules
- ✅ Breaking change detection
- ✅ Dependency management (like go.mod for protobuf)
- ✅ Better error messages
- ✅ Remote plugin execution (no local plugin installation)
- ✅ Package registry at buf.build
- ✅ Simpler configuration

**Traditional Approach: protoc**

For compatibility or legacy projects, you can still use `protoc` directly:

```bash
# Install protoc compiler
# macOS
brew install protobuf

# Linux
sudo apt install protobuf-compiler

# Install Go plugin
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Generate Go code (following AGENTS_GO.md)
protoc \
  --go_out=. \
  --go_opt=paths=source_relative \
  --go-grpc_out=. \
  --go-grpc_opt=paths=source_relative \
  api/v1/*.proto

# Generate Python code (following AGENTS_PYTHON.md)
python -m grpc_tools.protoc \
  -I. \
  --python_out=. \
  --grpc_python_out=. \
  api/v1/*.proto
```

### LazyVim Integration

```vim
# Keybindings from EDITORS.md
<leader>ff         " Find proto files
<leader>sg         " Search in protos

# Useful for proto files
:set ft=proto      " Set proto filetype
```

## Best Practices Summary

✅ **Do:**

- Use proto3 syntax
- Version your packages (v1, v2)
- Document all messages and fields
- Use request/response wrappers
- Reserve removed field numbers
- Use appropriate field types
- Implement pagination for lists
- Use streaming for real-time data
- Use TLS in production
- Follow naming conventions

❌ **Don't:**

- Reuse field numbers
- Use float for money
- Break backward compatibility
- Return messages directly (use wrappers)
- Skip documentation
- Ignore versioning
- Use plain HTTP (use TLS)
- Make non-idempotent operations
- Skip error details

## Tools

- **buf**: Modern protobuf tool (recommended)

  ```bash
  # Install
  brew install bufbuild/buf/buf

  # Lint
  buf lint

  # Format
  buf format -w

  # Breaking change detection
  buf breaking --against '.git#branch=main'

  # Generate code
  buf generate

  # Publish to registry
  buf push
  ```

- **protoc**: Traditional protobuf compiler

  ```bash
  # Install
  brew install protobuf

  # Generate
  protoc --go_out=. --go-grpc_out=. api/v1/*.proto
  ```

- **grpcurl**: curl for gRPC

  ```bash
  # List services
  grpcurl -plaintext localhost:50051 list

  # Call method
  grpcurl -plaintext -d '{"id": "123"}' localhost:50051 myapp.v1.UserService/GetUser

  # With reflection
  grpcurl -plaintext localhost:50051 describe myapp.v1.UserService
  ```

- **grpc-gateway**: Generate REST API from gRPC
  ```bash
  # Add to buf.gen.yaml
  - plugin: buf.build/grpc-ecosystem/gateway:v2.18.0
    out: gen/go
  ```

## References

- [buf Documentation](https://buf.build/docs) - Modern protobuf tooling
- [Protocol Buffers Language Guide](https://protobuf.dev/programming-guides/proto3/)
- [gRPC Core Concepts](https://grpc.io/docs/what-is-grpc/core-concepts/)
- [Google API Design Guide](https://cloud.google.com/apis/design)
- [Buf Style Guide](https://buf.build/docs/best-practices/style-guide)

## Version History

- 2024-01-25: Initial version
