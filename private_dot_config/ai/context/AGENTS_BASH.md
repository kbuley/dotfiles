# AGENTS.md - Bash Scripting

# APPLIES-TO: bash, sh

This document provides guidance for AI assistants working with bash scripts in this repository.

## Project Context

This repository contains bash scripts for system administration, automation, and infrastructure management tasks. Scripts should follow best practices for reliability, maintainability, and security.

## Core Principles

### 1. Safety First

- Always use `set -euo pipefail` at the start of scripts
  - `-e`: Exit on error
  - `-u`: Exit on undefined variable
  - `-o pipefail`: Fail on pipe errors
- Validate all inputs and arguments
- Use quotes around variable expansions: `"$var"` not `$var`
- Check for required commands before use: `command -v tool >/dev/null 2>&1`

### 2. Portability

- Target POSIX compliance when possible, or clearly document bash-specific features
- Avoid bashisms in scripts intended for `/bin/sh`
- Test scripts on target platforms (Ubuntu, RHEL, Alpine, etc.)
- Use portable commands (avoid GNU-specific flags without alternatives)

### 3. Maintainability

- Use meaningful variable names (avoid single letters except for loops)
- Add comments for complex logic
- Keep functions focused and single-purpose
- Document function parameters and return values
- Use consistent indentation (2 spaces, never tabs)

## Script Structure

### Standard Template

```bash
#!/usr/bin/env bash
#
# Script Name: script-name.sh
# Description: Brief description of what this script does
# Author: [Author Name]
# Version: 1.0.0
# Usage: script-name.sh [OPTIONS] ARGS
#

set -euo pipefail

# Global variables
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Function: usage
# Description: Display usage information
usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS] ARGS

Description of script purpose

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --debug         Enable debug mode

EXAMPLES:
    $SCRIPT_NAME --verbose input.txt
    $SCRIPT_NAME -d file1 file2

EOF
}

# Function: error
# Description: Print error message and exit
# Arguments:
#   $1 - Error message
error() {
    echo "ERROR: $1" >&2
    exit 1
}

# Function: log
# Description: Print log message if verbose mode enabled
# Arguments:
#   $1 - Log message
log() {
    if [[ "${VERBOSE:-0}" -eq 1 ]]; then
        echo "INFO: $1" >&2
    fi
}

# Main function
main() {
    # Parse arguments
    local verbose=0
    local debug=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                verbose=1
                shift
                ;;
            -d|--debug)
                debug=1
                set -x
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    # Validate required arguments
    if [[ $# -lt 1 ]]; then
        error "Missing required argument. Use --help for usage information."
    fi

    # Script logic here
    log "Starting script execution"

    # ...

    log "Script completed successfully"
}

# Execute main function with all arguments
main "$@"
```

## Best Practices

### Variable Handling

```bash
# Use readonly for constants
readonly API_URL="https://api.example.com"

# Use local in functions
my_function() {
    local temp_var="value"
    # ...
}

# Quote all variable expansions
echo "User: $USER"
cp "$source" "$destination"

# Use parameter expansion for defaults
config_file="${CONFIG_FILE:-/etc/default.conf}"

# Array handling
files=("file1.txt" "file2.txt" "file3.txt")
for file in "${files[@]}"; do
    echo "$file"
done
```

### Error Handling

```bash
# Check command success
if ! command -v jq >/dev/null 2>&1; then
    error "jq is required but not installed"
fi

# Use trap for cleanup
cleanup() {
    rm -f "$temp_file"
}
trap cleanup EXIT

# Validate file operations
if [[ ! -f "$config_file" ]]; then
    error "Config file not found: $config_file"
fi

if [[ ! -r "$input_file" ]]; then
    error "Cannot read input file: $input_file"
fi

# Check return codes explicitly when needed
if ! curl -s "$url" > "$output"; then
    error "Failed to download from $url"
fi
```

### Command Execution

```bash
# Avoid parsing ls output
# BAD
files=$(ls *.txt)

# GOOD
files=(*.txt)

# Use process substitution for complex pipelines
while IFS= read -r line; do
    process "$line"
done < <(command)

# Use command substitution with $() not backticks
result=$(command arg1 arg2)

# Check if command exists before use
if command -v docker >/dev/null 2>&1; then
    docker ps
else
    echo "Docker not available" >&2
fi
```

### File Operations

```bash
# Safe temporary file creation
temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

# Safe directory creation
mkdir -p "$output_dir"

# Read files line by line safely
while IFS= read -r line; do
    echo "Line: $line"
done < "$input_file"

# Write files atomically
{
    echo "Line 1"
    echo "Line 2"
} > "$output_file"

# Or for complex operations
cat > "$config_file" <<EOF
[settings]
option1=value1
option2=value2
EOF
```

### Conditional Logic

```bash
# File tests
[[ -f "$file" ]]      # File exists and is regular file
[[ -d "$dir" ]]       # Directory exists
[[ -r "$file" ]]      # File is readable
[[ -w "$file" ]]      # File is writable
[[ -x "$file" ]]      # File is executable
[[ -s "$file" ]]      # File exists and is not empty

# String tests
[[ -z "$var" ]]       # String is empty
[[ -n "$var" ]]       # String is not empty
[[ "$a" == "$b" ]]    # Strings are equal
[[ "$a" =~ regex ]]   # String matches regex

# Numeric tests
[[ "$a" -eq "$b" ]]   # Equal
[[ "$a" -ne "$b" ]]   # Not equal
[[ "$a" -lt "$b" ]]   # Less than
[[ "$a" -gt "$b" ]]   # Greater than

# Multiple conditions
if [[ -f "$file" && -r "$file" ]]; then
    cat "$file"
fi
```

## Common Patterns

### Argument Parsing (Advanced)

```bash
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--file)
                [[ -n "${2:-}" ]] || error "Missing value for $1"
                input_file="$2"
                shift 2
                ;;
            -o|--output)
                [[ -n "${2:-}" ]] || error "Missing value for $1"
                output_file="$2"
                shift 2
                ;;
            -c|--config)
                [[ -n "${2:-}" ]] || error "Missing value for $1"
                config_file="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=1
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                error "Unknown option: $1"
                ;;
            *)
                break
                ;;
        esac
    done

    # Remaining positional arguments in "$@"
}
```

### Progress Indicators

```bash
# Simple spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p "$pid" > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep "$delay"
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Usage
long_running_command &
spinner $!
```

### Logging

```bash
# Log levels
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

log_debug() { [[ $LOG_LEVEL -le $LOG_LEVEL_DEBUG ]] && echo "[DEBUG] $*" >&2; }
log_info()  { [[ $LOG_LEVEL -le $LOG_LEVEL_INFO ]]  && echo "[INFO]  $*" >&2; }
log_warn()  { [[ $LOG_LEVEL -le $LOG_LEVEL_WARN ]]  && echo "[WARN]  $*" >&2; }
log_error() { [[ $LOG_LEVEL -le $LOG_LEVEL_ERROR ]] && echo "[ERROR] $*" >&2; }
```

### Configuration Files

```bash
# Load configuration from file
load_config() {
    local config_file="$1"

    if [[ -f "$config_file" ]]; then
        # Source config file in a subshell to avoid pollution
        # shellcheck disable=SC1090
        source "$config_file"
    else
        log_warn "Config file not found: $config_file"
    fi
}

# Example config file format (key=value)
# DATABASE_HOST=localhost
# DATABASE_PORT=5432
# API_KEY=secret
```

## Security Considerations

### Input Validation

```bash
# Validate file paths (prevent directory traversal)
validate_path() {
    local path="$1"
    local base_dir="$2"

    # Resolve to absolute path
    local real_path
    real_path=$(realpath -m "$path")
    local real_base
    real_base=$(realpath "$base_dir")

    # Check if path is within base directory
    case "$real_path" in
        "$real_base"*)
            return 0
            ;;
        *)
            error "Path outside allowed directory: $path"
            ;;
    esac
}

# Validate email format
validate_email() {
    local email="$1"
    local regex='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

    if [[ ! "$email" =~ $regex ]]; then
        error "Invalid email format: $email"
    fi
}

# Sanitize user input for SQL (basic)
sanitize_sql() {
    local input="$1"
    # Remove dangerous characters
    echo "$input" | tr -d "';\"\\<>|&\`"
}
```

### Secure Credentials

```bash
# Never hardcode credentials
# BAD
password="secretpass123"

# GOOD - Read from environment
password="${DATABASE_PASSWORD:?DATABASE_PASSWORD not set}"

# GOOD - Read from file with restricted permissions
if [[ -f "$password_file" ]]; then
    password=$(<"$password_file")
fi

# GOOD - Prompt securely
read -rsp "Enter password: " password
echo
```

### File Permissions

```bash
# Set restrictive permissions on sensitive files
create_secure_file() {
    local file="$1"

    # Create with restricted permissions
    (umask 077 && touch "$file")

    # Or set after creation
    chmod 600 "$file"
}

# Check file permissions
check_secure_file() {
    local file="$1"
    local perms
    perms=$(stat -c '%a' "$file" 2>/dev/null || stat -f '%Lp' "$file" 2>/dev/null)

    if [[ "$perms" != "600" && "$perms" != "400" ]]; then
        error "File has insecure permissions: $file ($perms)"
    fi
}
```

## Testing

### Unit Testing with BATS

```bash
#!/usr/bin/env bats

# File: test/script_test.bats

setup() {
    # Run before each test
    export TEST_DIR="$(mktemp -d)"
}

teardown() {
    # Run after each test
    rm -rf "$TEST_DIR"
}

@test "function returns success on valid input" {
    run my_function "valid_input"
    [ "$status" -eq 0 ]
}

@test "function fails on invalid input" {
    run my_function "invalid_input"
    [ "$status" -ne 0 ]
}

@test "output contains expected string" {
    run my_function "input"
    [[ "$output" =~ "expected string" ]]
}
```

### ShellCheck Integration

```bash
# Add ShellCheck directives as needed
# shellcheck disable=SC2034  # Unused variable
unused_var="value"

# shellcheck disable=SC1090  # Can't follow non-constant source
source "$config_file"

# Prefer fixing issues over disabling checks
```

## Performance Optimization

### Avoid Unnecessary Subshells

```bash
# BAD - Creates subshell
var=$(cat file.txt)

# GOOD - Built-in read
var=$(<file.txt)

# BAD - Unnecessary cat
cat file.txt | grep pattern

# GOOD - Direct input
grep pattern file.txt
```

### Efficient String Operations

```bash
# Use parameter expansion instead of external commands
# Remove prefix
filename="${path##*/}"

# Remove suffix
basename="${filename%.*}"

# Replace substring
new_string="${old_string/old/new}"

# Convert to lowercase (bash 4+)
lowercase="${string,,}"

# Convert to uppercase (bash 4+)
uppercase="${string^^}"
```

### Array Operations

```bash
# Build arrays efficiently
# BAD
for file in $(ls *.txt); do
    files+=("$file")
done

# GOOD
files=(*.txt)

# Process arrays efficiently
# BAD
for i in $(seq 0 ${#array[@]}); do
    echo "${array[$i]}"
done

# GOOD
for item in "${array[@]}"; do
    echo "$item"
done
```

## Azure/Cloud Specific Patterns

### Azure CLI Operations

```bash
# Check Azure CLI login status
check_az_login() {
    if ! az account show >/dev/null 2>&1; then
        error "Not logged in to Azure. Run 'az login' first."
    fi
}

# Set subscription context
set_subscription() {
    local subscription="$1"

    if ! az account set --subscription "$subscription" 2>/dev/null; then
        error "Failed to set subscription: $subscription"
    fi

    log_info "Using subscription: $(az account show --query name -o tsv)"
}

# Retry logic for API calls
retry_command() {
    local max_attempts=3
    local delay=5
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        if "$@"; then
            return 0
        fi

        log_warn "Attempt $attempt failed, retrying in ${delay}s..."
        sleep "$delay"
        ((attempt++))
    done

    return 1
}

# Usage
retry_command az vm list --query "[].name" -o tsv
```

### JSON Processing with jq

```bash
# Parse JSON safely
get_json_value() {
    local json="$1"
    local key="$2"

    echo "$json" | jq -r "$key" 2>/dev/null || echo ""
}

# Example: Process Azure resources
resources=$(az resource list --query "[?resourceGroup=='mygroup']" -o json)
while IFS= read -r id; do
    echo "Resource ID: $id"
done < <(echo "$resources" | jq -r '.[].id')
```

## Documentation Requirements

### Function Documentation

```bash
# Function: process_file
# Description: Processes input file and generates output
# Arguments:
#   $1 - Input file path (required)
#   $2 - Output file path (required)
#   $3 - Processing mode: 'full' or 'partial' (optional, default: 'full')
# Returns:
#   0 - Success
#   1 - Input file not found
#   2 - Output file write error
#   3 - Invalid processing mode
# Example:
#   process_file input.txt output.txt full
process_file() {
    local input_file="$1"
    local output_file="$2"
    local mode="${3:-full}"

    # Implementation
}
```

### Script Headers

Every script should include:

- Shebang line (`#!/usr/bin/env bash`)
- Brief description
- Usage information
- Author/version information (if applicable)
- Dependencies and requirements

## AI Assistant Guidelines

### When Reviewing Scripts

1. **Check Safety**
   - Verify `set -euo pipefail` is present
   - Look for unquoted variables
   - Check input validation
   - Review error handling

2. **Check Portability**
   - Identify bashisms if script uses `/bin/sh`
   - Note any GNU-specific commands
   - Verify path handling works across platforms

3. **Check Maintainability**
   - Ensure functions are well-documented
   - Verify consistent style
   - Check for code duplication

4. **Suggest Improvements**
   - Recommend shellcheck integration
   - Suggest better error messages
   - Propose more efficient patterns

### When Writing Scripts

1. Start with the standard template
2. Use meaningful variable names reflecting the domain (Azure, infrastructure, etc.)
3. Add comprehensive error checking
4. Document all functions
5. Include usage examples
6. Consider edge cases
7. Test on target platform

### When Debugging

1. Suggest adding `set -x` for debugging
2. Recommend breaking complex commands into steps
3. Propose adding logging statements
4. Check for common pitfalls (word splitting, globbing, etc.)

## Common Pitfalls to Avoid

### Word Splitting

```bash
# BAD - Word splitting will break spaces in filenames
for file in $(ls *.txt); do
    echo $file
done

# GOOD
for file in *.txt; do
    echo "$file"
done
```

### Pathname Expansion

```bash
# BAD - Glob will expand
file="*.txt"
echo $file  # Prints all .txt files

# GOOD
file="*.txt"
echo "$file"  # Prints literal "*.txt"
```

### Exit Codes

```bash
# BAD - Loses exit code
command
if [[ $? -eq 0 ]]; then
    echo "success"
fi

# GOOD
if command; then
    echo "success"
fi
```

## Resources

- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [ShellCheck](https://www.shellcheck.net/)
- [Bash Hackers Wiki](https://wiki.bash-hackers.org/)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)
- [BATS Testing Framework](https://github.com/bats-core/bats-core)

## Version History

- 1.0.0 - Initial version with comprehensive bash scripting guidelines
