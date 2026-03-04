# Systemd Unit Standards and Best Practices

# APPLIES-TO: systemd

Standards for writing systemd service units, timers, and configuration.

## Table of Contents

- [Core Principles](#core-principles)
- [Service Units](#service-units)
- [Timer Units](#timer-units)
- [Target Units](#target-units)
- [Security and Hardening](#security-and-hardening)
- [Common Patterns](#common-patterns)
- [AI Assistant Guidelines](#ai-assistant-guidelines)

## Core Principles

1. **Security First**: Use sandboxing and isolation features
2. **Explicit Dependencies**: Clear ordering and requirements
3. **Restart Policies**: Handle failures gracefully
4. **Resource Limits**: Prevent resource exhaustion
5. **Logging**: Use systemd journal properly

## Service Units

### Basic Service Template

```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Application Service
Documentation=https://example.com/docs
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=myapp
Group=myapp
WorkingDirectory=/var/lib/myapp
ExecStart=/usr/bin/myapp --config /etc/myapp/myapp.conf
Restart=on-failure
RestartSec=5s

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/myapp

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=myapp

[Install]
WantedBy=multi-user.target
```

### Service Types

```ini
# Simple (default) - process doesn't fork
[Service]
Type=simple
ExecStart=/usr/bin/myapp

# Forking - traditional daemon that forks
[Service]
Type=forking
PIDFile=/run/myapp.pid
ExecStart=/usr/bin/myapp --daemon

# Oneshot - single task, no persistent process
[Service]
Type=oneshot
ExecStart=/usr/bin/setup-script.sh
RemainAfterExit=yes

# Notify - service sends notification when ready
[Service]
Type=notify
ExecStart=/usr/bin/myapp
NotifyAccess=main

# Dbus - service claims D-Bus name
[Service]
Type=dbus
BusName=org.example.MyApp
ExecStart=/usr/bin/myapp
```

### Dependencies and Ordering

```ini
# ✅ Good - explicit dependencies
[Unit]
Description=Web Application
After=network-online.target postgresql.service redis.service
Wants=network-online.target
Requires=postgresql.service

# Wants = optional dependency (doesn't fail if missing)
# Requires = hard dependency (fails if missing)
# After = ordering (start after these)
# Before = ordering (start before these)

# ❌ Bad - unclear dependencies
[Unit]
Description=Web Application
After=network.target

# ❌ Bad - creates circular dependencies
[Unit]
After=other.service
Before=other.service
```

### Restart Policies

```ini
# ✅ Good - restart on failure
[Service]
Restart=on-failure
RestartSec=5s
StartLimitBurst=5
StartLimitIntervalSec=30s

# Options for Restart:
# no          - never restart
# on-success  - restart only on clean exit
# on-failure  - restart on unclean exit (default for most services)
# on-abnormal - restart on unclean signal/timeout
# on-abort    - restart on uncaught signal
# always      - always restart

# ✅ Good - prevent restart loops
[Service]
Restart=on-failure
StartLimitBurst=5           # Max 5 restarts
StartLimitIntervalSec=30s   # Within 30 seconds
```

### Environment Variables

```ini
# ✅ Good - inline environment
[Service]
Environment="LOG_LEVEL=info"
Environment="PORT=8080"

# ✅ Good - from file
[Service]
EnvironmentFile=/etc/myapp/environment
EnvironmentFile=-/etc/myapp/environment.local  # Optional file (-)

# ✅ Good - multiple files
[Service]
EnvironmentFile=/etc/default/myapp
EnvironmentFile=-/etc/sysconfig/myapp

# Format of environment file:
# KEY=value
# ANOTHER_KEY="value with spaces"
# # Comments are allowed
```

## Timer Units

### Basic Timer

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Backup Timer
Requires=backup.service

[Timer]
OnCalendar=daily
Persistent=true
Unit=backup.service

[Install]
WantedBy=timers.target

# /etc/systemd/system/backup.service
[Unit]
Description=Backup Service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
User=backup
```

### Timer Schedules

```ini
# Calendar-based (cron-like)
[Timer]
OnCalendar=daily              # Every day at 00:00
OnCalendar=weekly             # Every Monday at 00:00
OnCalendar=monthly            # First day of month at 00:00
OnCalendar=*-*-* 04:00:00     # Every day at 4 AM
OnCalendar=Mon,Fri 09:00      # Monday and Friday at 9 AM
OnCalendar=*-*-1,15 12:00     # 1st and 15th at noon

# Monotonic (relative to event)
OnBootSec=10min               # 10 minutes after boot
OnStartupSec=5min             # 5 minutes after systemd starts
OnUnitActiveSec=1h            # 1 hour after unit last activated
OnUnitInactiveSec=30min       # 30 minutes after unit last deactivated

# ✅ Good - persistent timer (catches missed runs)
[Timer]
OnCalendar=daily
Persistent=true

# ✅ Good - randomized delay (prevent thundering herd)
[Timer]
OnCalendar=daily
RandomizedDelaySec=1h
```

## Target Units

### Custom Target

```ini
# /etc/systemd/system/myapp.target
[Unit]
Description=My Application Stack
Requires=database.service cache.service
After=database.service cache.service

[Install]
WantedBy=multi-user.target
```

### Service with Custom Target

```ini
# /etc/systemd/system/webapp.service
[Unit]
Description=Web Application
PartOf=myapp.target

[Service]
Type=simple
ExecStart=/usr/bin/webapp

[Install]
WantedBy=myapp.target
```

## Security and Hardening

### Filesystem Protection

```ini
[Service]
# ✅ Strict protection
ProtectSystem=strict        # All of /usr, /boot, /efi read-only
ProtectHome=true            # /home inaccessible
PrivateTmp=true             # Private /tmp and /var/tmp
ReadWritePaths=/var/lib/myapp /var/log/myapp

# Alternatives:
# ProtectSystem=full        # /usr and /boot read-only
# ProtectSystem=true        # /usr read-only
# ReadOnlyPaths=/etc        # Specific paths read-only
# InaccessiblePaths=/proc   # Hide specific paths

# ✅ Dynamic user (automatic user creation)
DynamicUser=true
StateDirectory=myapp        # Creates /var/lib/myapp
LogsDirectory=myapp         # Creates /var/log/myapp
CacheDirectory=myapp        # Creates /var/cache/myapp
ConfigurationDirectory=myapp # Creates /etc/myapp
```

### Process Restrictions

```ini
[Service]
# ✅ Prevent privilege escalation
NoNewPrivileges=true

# ✅ Limit process capabilities
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

# ✅ Private /dev
PrivateDevices=true

# ✅ Kernel restrictions
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true

# ✅ Restrict address families
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6

# ✅ System call filtering
SystemCallFilter=@system-service
SystemCallFilter=~@privileged @resources

# ✅ Restrict namespaces
RestrictNamespaces=true

# ✅ Lock down personality
LockPersonality=true

# ✅ Restrict realtime
RestrictRealtime=true

# ✅ Remove setuid/setgid bits
RemoveIPC=true
```

### Network Restrictions

```ini
[Service]
# ✅ Private network namespace
PrivateNetwork=true

# ✅ Only allow specific IP
IPAddressAllow=192.168.1.0/24
IPAddressDeny=any

# ✅ Restrict address families
RestrictAddressFamilies=AF_INET AF_INET6
```

### Resource Limits

```ini
[Service]
# Memory limits
MemoryMax=512M
MemoryHigh=384M

# CPU limits
CPUQuota=50%
CPUWeight=100

# Task limits
TasksMax=100

# File descriptor limits
LimitNOFILE=1024

# Process limits
LimitNPROC=64

# Core dump size
LimitCORE=0

# Open files
LimitNOFILE=65536
```

## Common Patterns

### Web Application (Go)

```ini
# /etc/systemd/system/webapp.service
[Unit]
Description=Web Application (Go)
Documentation=https://github.com/username/webapp
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
User=webapp
Group=webapp
WorkingDirectory=/var/lib/webapp

# Following AGENTS_GO.md patterns
ExecStart=/usr/bin/webapp \
    --config /etc/webapp/config.yaml \
    --listen :8080

# Health check
ExecStartPost=/usr/bin/curl -f http://localhost:8080/health || exit 1

Restart=on-failure
RestartSec=5s
StartLimitBurst=5
StartLimitIntervalSec=30s

# Security
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectSystem=strict
ProtectHome=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
ReadWritePaths=/var/lib/webapp
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
RestrictNamespaces=true
LockPersonality=true
SystemCallFilter=@system-service
SystemCallFilter=~@privileged @resources

# Resources
MemoryMax=512M
CPUQuota=100%
TasksMax=100

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=webapp

[Install]
WantedBy=multi-user.target
```

### Python Application

```ini
# /etc/systemd/system/pyapp.service
[Unit]
Description=Python Application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=pyapp
Group=pyapp
WorkingDirectory=/opt/pyapp

# Following AGENTS_PYTHON.md patterns
Environment="PYTHONUNBUFFERED=1"
ExecStart=/opt/pyapp/venv/bin/python -m myapp

Restart=on-failure
RestartSec=5s

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/pyapp

# Logging
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### Database Service

```ini
# /etc/systemd/system/database.service
[Unit]
Description=PostgreSQL Database
Documentation=https://www.postgresql.org/docs/
After=network.target

[Service]
Type=notify
User=postgres
Group=postgres

ExecStart=/usr/bin/postgres -D /var/lib/postgresql/data
ExecReload=/bin/kill -HUP $MAINPID

Restart=always
RestartSec=10s

# Resources
MemoryMax=2G
CPUQuota=200%

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/var/lib/postgresql

# Logging
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### Container Service

```ini
# /etc/systemd/system/container.service
[Unit]
Description=Application Container
After=docker.service
Requires=docker.service

[Service]
Type=forking
ExecStartPre=-/usr/bin/docker stop myapp
ExecStartPre=-/usr/bin/docker rm myapp
ExecStart=/usr/bin/docker run \
    --name myapp \
    --detach \
    --restart=unless-stopped \
    -p 8080:8080 \
    myapp:latest

ExecStop=/usr/bin/docker stop myapp
ExecStopPost=/usr/bin/docker rm myapp

Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
```

### Socket-Activated Service

```ini
# /etc/systemd/system/myapp.socket
[Unit]
Description=My Application Socket

[Socket]
ListenStream=8080
Accept=no

[Install]
WantedBy=sockets.target

# /etc/systemd/system/myapp.service
[Unit]
Description=My Application
Requires=myapp.socket

[Service]
Type=simple
ExecStart=/usr/bin/myapp
StandardInput=socket

# No [Install] section - activated by socket
```

## AI Assistant Guidelines

### When Creating Systemd Units

1. **Start with template**: Use appropriate service type
2. **Add dependencies**: Explicit After/Requires
3. **Set user/group**: Don't run as root
4. **Enable security**: Maximum hardening
5. **Configure restart**: Handle failures
6. **Set resource limits**: Prevent exhaustion
7. **Use journal**: StandardOutput=journal

### Example AI Prompt

```
Create a systemd service following .ai/context/AGENTS_SYSTEMD.md:

For: Go web service (from AGENTS_GO.md)
Requirements:
- Runs on port 8080
- Requires PostgreSQL
- Run as dedicated user
- Maximum security hardening
- Restart on failure
- Resource limits (512M RAM, 100% CPU)
- Journal logging
```

### When Reviewing Systemd Units

Check for:

- [ ] Appropriate service type (simple, forking, notify)
- [ ] Clear dependencies (After, Requires)
- [ ] Non-root user/group
- [ ] Security hardening enabled
- [ ] Restart policy configured
- [ ] Resource limits set
- [ ] Logging configured
- [ ] Documentation provided

### Common Commands

```bash
# Enable and start service
sudo systemctl enable myapp.service
sudo systemctl start myapp.service

# Check status
sudo systemctl status myapp.service

# View logs
sudo journalctl -u myapp.service
sudo journalctl -u myapp.service -f  # Follow
sudo journalctl -u myapp.service --since "1 hour ago"

# Reload configuration
sudo systemctl daemon-reload

# Edit service (creates drop-in)
sudo systemctl edit myapp.service

# View effective configuration
systemctl cat myapp.service

# Test security settings
systemd-analyze security myapp.service

# View dependencies
systemctl list-dependencies myapp.service

# Enable timer
sudo systemctl enable --now backup.timer

# List timers
systemctl list-timers
```

### Testing Systemd Units

```bash
# Validate syntax
systemd-analyze verify /etc/systemd/system/myapp.service

# Check security score
systemd-analyze security myapp.service

# See what would be exposed
systemd-run --pty --property=DynamicUser=yes \
    --property=ProtectSystem=strict \
    --property=ProtectHome=yes \
    /bin/bash

# Test resource limits
systemd-run --scope \
    --property=MemoryMax=512M \
    --property=CPUQuota=50% \
    /usr/bin/stress --vm 1 --vm-bytes 1G
```

### LazyVim Integration

```vim
# Keybindings from EDITORS.md
<leader>ff         " Find service file
<leader>sg         " Search in services

# Useful for systemd files
:set ft=systemd    " Set systemd filetype
```

## Best Practices Summary

✅ **Do:**

- Use specific service types (simple, notify, forking)
- Set explicit dependencies with After/Requires
- Run as non-root user
- Enable maximum security hardening
- Configure restart policies
- Set resource limits
- Use systemd journal for logging
- Test with systemd-analyze
- Document with Description and Documentation

❌ **Don't:**

- Run as root unless absolutely necessary
- Skip security hardening
- Allow unlimited resources
- Ignore restart policies
- Use Type=forking for new services
- Skip dependency ordering
- Write logs to files (use journal)
- Forget to enable the service

## Security Checklist

Maximum hardening for most services:

```ini
[Service]
# Process
NoNewPrivileges=true
DynamicUser=true

# Filesystem
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
PrivateDevices=true
ReadWritePaths=/var/lib/myapp

# Kernel
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true

# Network
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6

# Syscalls
SystemCallFilter=@system-service
SystemCallFilter=~@privileged @resources

# Namespaces
RestrictNamespaces=true
LockPersonality=true
RestrictRealtime=true
```

## References

- [systemd.service(5)](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [systemd.unit(5)](https://www.freedesktop.org/software/systemd/man/systemd.unit.html)
- [systemd.exec(5)](https://www.freedesktop.org/software/systemd/man/systemd.exec.html)
- [systemd.resource-control(5)](https://www.freedesktop.org/software/systemd/man/systemd.resource-control.html)

## Version History

- 2024-01-24: Initial version
