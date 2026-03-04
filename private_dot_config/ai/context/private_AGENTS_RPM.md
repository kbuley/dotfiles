# RPM Package Standards and Best Practices

# APPLIES-TO: spec

Standards for creating and managing RPM packages for Red Hat-based Linux distributions.

## Table of Contents

- [Core Principles](#core-principles)
- [Spec File Structure](#spec-file-structure)
- [Naming Conventions](#naming-conventions)
- [Dependencies](#dependencies)
- [Build Process](#build-process)
- [Common Patterns](#common-patterns)
- [Security](#security)
- [AI Assistant Guidelines](#ai-assistant-guidelines)

## Core Principles

1. **Follow FHS**: Filesystem Hierarchy Standard compliance
2. **Clean Builds**: Reproducible from source
3. **Proper Dependencies**: Explicit requirements and provides
4. **Scriptlets**: Minimal and idempotent
5. **Documentation**: Complete changelog and descriptions

## Spec File Structure

### Basic Template

```spec
# myapp.spec
Name:           myapp
Version:        1.0.0
Release:        1%{?dist}
Summary:        Brief description of the application

License:        MIT
URL:            https://github.com/username/myapp
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  golang >= 1.21

Requires:       systemd

%description
Longer description of the application.
Multiple lines are fine here.

%prep
%setup -q

%build
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
%make_install

%files
%license LICENSE
%doc README.md
%{_bindir}/%{name}
%{_unitdir}/%{name}.service
%config(noreplace) %{_sysconfdir}/%{name}/%{name}.conf

%post
%systemd_post %{name}.service

%preun
%systemd_preun %{name}.service

%postun
%systemd_postun_with_restart %{name}.service

%changelog
* Fri Jan 24 2024 Your Name <email@example.com> - 1.0.0-1
- Initial package
```

### Required Sections

```spec
# Always required
Name:           package-name
Version:        1.0.0
Release:        1%{?dist}
Summary:        Short description
License:        MIT
URL:            https://project.url

%description
Detailed description

%files
/path/to/files

%changelog
* Date Author <email> - version-release
- Changes
```

## Naming Conventions

### Package Names

```spec
# ✅ Good - lowercase, descriptive
Name: httpd
Name: python3-requests
Name: nodejs-express

# ❌ Bad - inconsistent case or unclear
Name: MyApp
Name: app
Name: tool
```

### Version-Release Format

```spec
# ✅ Good
Version: 1.2.3
Release: 1%{?dist}
# Results in: myapp-1.2.3-1.el9

# ✅ Good - snapshot builds
Version: 1.2.3
Release: 0.1.20240124git%{shortcommit}%{?dist}

# ✅ Good - prereleases
Version: 1.2.3
Release: 0.1.rc1%{?dist}

# ❌ Bad - version in release
Version: 1.2.3
Release: v1.2.3
```

### File Naming

```spec
# ✅ Good - follows convention
Source0: %{name}-%{version}.tar.gz
Source1: %{name}.service

# ❌ Bad - doesn't follow convention
Source0: myapp.tar.gz
```

## Dependencies

### BuildRequires vs Requires

```spec
# Build-time dependencies
BuildRequires: gcc
BuildRequires: make
BuildRequires: golang >= 1.21
BuildRequires: systemd-rpm-macros

# Runtime dependencies
Requires: systemd
Requires: shadow-utils
Requires(pre): shadow-utils
Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd

# Conflicts
Conflicts: old-package-name

# Obsoletes (for package renames)
Obsoletes: old-package-name < 2.0.0
```

### Automatic Dependencies

```spec
# Let RPM auto-detect shared library dependencies
# ✅ Good - let autodeps work
%files
%{_libdir}/libmyapp.so.1
%{_libdir}/libmyapp.so.1.0.0

# ❌ Bad - manual library deps (usually unnecessary)
Requires: libssl.so.1.1
Requires: libcrypto.so.1.1
```

### Version Pinning

```spec
# ✅ Good - version ranges
Requires: python3 >= 3.9
BuildRequires: golang >= 1.21, golang < 2.0

# ✅ Good - exact version when needed
Requires: mylib = %{version}-%{release}

# ❌ Bad - overly restrictive
Requires: python3 = 3.9.16-1.el9
```

## Build Process

### %prep Section

```spec
# ✅ Good - standard source extraction
%prep
%setup -q

# ✅ Good - with patches
%prep
%setup -q
%patch0 -p1
%patch1 -p1

# ✅ Good - multiple sources
%prep
%setup -q -n %{name}-%{version}
tar xzf %{SOURCE1}
```

### %build Section

```spec
# ✅ Good - Make-based
%build
%configure
make %{?_smp_mflags}

# ✅ Good - Go application
%build
export GOPATH=$(pwd)/_build
export GO111MODULE=on
go build -o %{name} \
    -ldflags "-X main.Version=%{version}" \
    cmd/%{name}/main.go

# ✅ Good - CMake
%build
%cmake .
%cmake_build

# ✅ Good - Python
%build
%py3_build

# ❌ Bad - hardcoded paths
%build
make DESTDIR=/usr/local
```

### %install Section

```spec
# ✅ Good - clean buildroot first
%install
rm -rf %{buildroot}
%make_install

# ✅ Good - manual installation
%install
rm -rf %{buildroot}
install -Dpm 0755 %{name} %{buildroot}%{_bindir}/%{name}
install -Dpm 0644 %{name}.service %{buildroot}%{_unitdir}/%{name}.service
install -Dpm 0644 %{name}.conf %{buildroot}%{_sysconfdir}/%{name}/%{name}.conf

# ✅ Good - Python
%install
%py3_install

# ❌ Bad - absolute paths
%install
install -m 755 %{name} /usr/bin/%{name}
```

### %check Section (Optional but Recommended)

```spec
# ✅ Good - run tests
%check
make test

# ✅ Good - Go tests
%check
go test -v ./...

# ✅ Good - Python tests
%check
%pytest
```

## Common Patterns

### Systemd Service

```spec
# myapp.spec
BuildRequires: systemd-rpm-macros
Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd

%files
%{_bindir}/%{name}
%{_unitdir}/%{name}.service

%post
%systemd_post %{name}.service

%preun
%systemd_preun %{name}.service

%postun
%systemd_postun_with_restart %{name}.service
```

### Configuration Files

```spec
# ✅ Good - preserve user changes
%files
%config(noreplace) %{_sysconfdir}/%{name}/%{name}.conf

# ✅ Good - default config (can be replaced)
%files
%config %{_sysconfdir}/%{name}/defaults.conf

# ✅ Good - config directory
%files
%dir %{_sysconfdir}/%{name}
%config(noreplace) %{_sysconfdir}/%{name}/*.conf
```

### User Creation

```spec
Requires(pre): shadow-utils

%pre
getent group %{name} >/dev/null || groupadd -r %{name}
getent passwd %{name} >/dev/null || \
    useradd -r -g %{name} -d %{_sharedstatedir}/%{name} \
    -s /sbin/nologin -c "%{name} user" %{name}
exit 0

%files
%attr(0755,%{name},%{name}) %dir %{_sharedstatedir}/%{name}
```

### Subpackages

```spec
# Main package
Name: myapp
Version: 1.0.0

%description
Main application

# Development subpackage
%package devel
Summary: Development files for %{name}
Requires: %{name}%{?_isa} = %{version}-%{release}

%description devel
Development files and headers for %{name}

%files devel
%{_includedir}/%{name}/
%{_libdir}/lib%{name}.so
%{_libdir}/pkgconfig/%{name}.pc

# Documentation subpackage
%package doc
Summary: Documentation for %{name}
BuildArch: noarch

%description doc
Documentation and examples for %{name}

%files doc
%doc docs/*
%{_docdir}/%{name}/
```

### Go Application

```spec
Name:           mygoapp
Version:        1.0.0
Release:        1%{?dist}
Summary:        Go application

License:        MIT
URL:            https://github.com/username/mygoapp
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  golang >= 1.21
BuildRequires:  systemd-rpm-macros

%description
A Go application following AGENTS_GO.md patterns.

%prep
%setup -q

%build
export GO111MODULE=on
export GOFLAGS="-mod=vendor"
go build -o %{name} \
    -ldflags "-X main.Version=%{version} -X main.BuildDate=$(date -u +%%Y-%%m-%%d)" \
    ./cmd/%{name}

%install
install -Dpm 0755 %{name} %{buildroot}%{_bindir}/%{name}
install -Dpm 0644 %{name}.service %{buildroot}%{_unitdir}/%{name}.service

%check
go test -v ./...

%files
%license LICENSE
%doc README.md
%{_bindir}/%{name}
%{_unitdir}/%{name}.service

%changelog
* Fri Jan 24 2024 Your Name <email@example.com> - 1.0.0-1
- Initial package
```

### Python Application

```spec
Name:           python3-myapp
Version:        1.0.0
Release:        1%{?dist}
Summary:        Python application

License:        MIT
URL:            https://github.com/username/myapp
Source0:        myapp-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  python3-devel
BuildRequires:  python3-setuptools
BuildRequires:  python3-pytest

Requires:       python3-requests
Requires:       python3-pydantic

%description
A Python application following AGENTS_PYTHON.md patterns.

%prep
%setup -q -n myapp-%{version}

%build
%py3_build

%install
%py3_install

%check
%pytest

%files
%license LICENSE
%doc README.md
%{python3_sitelib}/myapp/
%{python3_sitelib}/myapp-%{version}-py%{python3_version}.egg-info/
%{_bindir}/myapp

%changelog
* Fri Jan 24 2024 Your Name <email@example.com> - 1.0.0-1
- Initial package
```

## Security

### File Permissions

```spec
# ✅ Good - explicit permissions
%files
%attr(0755,root,root) %{_bindir}/%{name}
%attr(0644,root,root) %config(noreplace) %{_sysconfdir}/%{name}/%{name}.conf
%attr(0750,%{name},%{name}) %dir %{_sharedstatedir}/%{name}
%attr(0640,%{name},%{name}) %{_sharedstatedir}/%{name}/*.db

# ❌ Bad - world-writable
%attr(0777,root,root) %{_bindir}/%{name}
```

### Hardening

```spec
# ✅ Good - compiler flags
%build
export CFLAGS="%{optflags} -fPIC -pie"
export LDFLAGS="-Wl,-z,relro,-z,now"
%configure
make %{?_smp_mflags}

# ✅ Good - Go with PIE
%build
go build -buildmode=pie -o %{name}
```

### SELinux

```spec
# If your app needs SELinux policy
BuildRequires: selinux-policy-devel
Requires(post): policycoreutils
Requires(postun): policycoreutils

%files
%{_datadir}/selinux/packages/%{name}.pp

%post
semodule -i %{_datadir}/selinux/packages/%{name}.pp || :

%postun
if [ $1 -eq 0 ]; then
    semodule -r %{name} || :
fi
```

## AI Assistant Guidelines

### When Creating RPM Specs

1. **Start with template**: Use basic template structure
2. **Follow naming**: Package and file naming conventions
3. **Explicit dependencies**: BuildRequires and Requires
4. **Test in mock**: Build in clean environment
5. **Minimal scriptlets**: Keep %post/%pre simple
6. **Complete changelog**: Document all changes

### Example AI Prompt

```
Create an RPM spec following .ai/context/AGENTS_RPM.md:

For: Go web service (from AGENTS_GO.md)
Requirements:
- Version 1.0.0
- Systemd service
- Configuration in /etc
- Run as dedicated user
- Build with Go 1.21+
- Include tests
```

### When Reviewing RPM Specs

Check for:

- [ ] Follows naming conventions
- [ ] Version-Release format correct
- [ ] All dependencies listed
- [ ] FHS-compliant paths
- [ ] Proper file permissions
- [ ] Config files marked with %config(noreplace)
- [ ] Systemd scriptlets if applicable
- [ ] Complete changelog entry
- [ ] License file included
- [ ] Documentation included

### Building and Testing

```bash
# Install build tools
sudo dnf install rpm-build rpmdevtools

# Setup build tree
rpmdev-setuptree

# Check spec syntax
rpmlint myapp.spec

# Build in mock (clean environment)
mock -r fedora-39-x86_64 --rebuild myapp-1.0.0-1.src.rpm

# Build locally
rpmbuild -ba myapp.spec

# Install and test
sudo dnf install ~/rpmbuild/RPMS/x86_64/myapp-1.0.0-1.fc39.x86_64.rpm

# Check installed files
rpm -ql myapp

# Verify dependencies
rpm -qpR myapp-1.0.0-1.fc39.x86_64.rpm
```

### Common Macros

```spec
# Directories
%{_bindir}           # /usr/bin
%{_sbindir}          # /usr/sbin
%{_libdir}           # /usr/lib64 or /usr/lib
%{_includedir}       # /usr/include
%{_datadir}          # /usr/share
%{_sysconfdir}       # /etc
%{_localstatedir}    # /var
%{_sharedstatedir}   # /var/lib
%{_unitdir}          # /usr/lib/systemd/system

# Python
%{python3_sitelib}   # Python library path
%{python3_version}   # Python version

# Build info
%{name}              # Package name
%{version}           # Version
%{release}           # Release
%{_arch}             # Architecture
%{?dist}             # Distribution tag (.el9, .fc39)
```

### LazyVim Integration

```vim
# Keybindings from EDITORS.md
<leader>ff         " Find spec file
<leader>sg         " Search in spec

# Useful for spec files
:set ft=spec       " Set spec filetype
```

## Best Practices Summary

✅ **Do:**

- Follow FHS for file locations
- Use RPM macros instead of hardcoded paths
- Mark config files with %config(noreplace)
- Include license and documentation
- Use systemd macros for services
- Test builds in mock
- Keep scriptlets minimal and idempotent
- Document all changes in %changelog

❌ **Don't:**

- Hardcode paths like /usr/bin
- Install files directly in scriptlets
- Skip BuildRequires
- Make scriptlets fail the transaction
- Use absolute paths in %files
- Forget to clean %buildroot
- Mix BuildRequires and Requires

## Tools

- **rpmbuild**: Build RPM packages

  ```bash
  rpmbuild -ba myapp.spec
  ```

- **mock**: Build in clean environment

  ```bash
  mock -r fedora-39-x86_64 --rebuild myapp.src.rpm
  ```

- **rpmlint**: Check spec and RPM quality

  ```bash
  rpmlint myapp.spec
  rpmlint myapp.rpm
  ```

- **rpmdev-setuptree**: Setup build directories

  ```bash
  rpmdev-setuptree
  ```

- **spectool**: Download sources
  ```bash
  spectool -g -R myapp.spec
  ```

## References

- [Fedora Packaging Guidelines](https://docs.fedoraproject.org/en-US/packaging-guidelines/)
- [RPM Packaging Guide](https://rpm-packaging-guide.github.io/)
- [Maximum RPM](http://ftp.rpm.org/max-rpm/)

## Version History

- 2024-01-24: Initial version
