<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="tycana-logo-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="tycana-logo-light.svg">
    <img alt="tycana" src="tycana-logo-light.svg" width="200">
  </picture>
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/tycana/releases?style=for-the-badge&label=Latest%20Release" alt="Latest Release">
  <img src="https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-blue?style=for-the-badge" alt="Platforms">
</p>

<p align="center">
  <strong>Add tasks in your terminal. See them in your calendar. Everywhere.</strong>
</p>

---

A CLI task manager with calendar sync for technical professionals who live in their terminal.

- Natural language task capture from the command line
- Calendar subscriptions — tasks appear on your phone, laptop, anywhere
- Cloud sync across devices
- Spaces for organizing and sharing tasks
- MCP server for managing tasks via AI assistants (Claude, ChatGPT)

## Install

### Homebrew (macOS and Linux)

```bash
brew install tycana/tap/tycana
```

### Shell script (macOS and Linux)

```bash
curl -fsSL https://tycana.com/install | bash
```

### Manual download

Download the archive for your platform from the [latest release](https://github.com/tycana/releases/releases/latest), extract it, and add `tycana` to your PATH.

| Platform | File |
|----------|------|
| macOS Apple Silicon | `tycana_VERSION_darwin_arm64.tar.gz` |
| macOS Intel | `tycana_VERSION_darwin_x86_64.tar.gz` |
| Linux x64 | `tycana_VERSION_linux_x86_64.tar.gz` |
| Linux ARM64 | `tycana_VERSION_linux_arm64.tar.gz` |
| Windows x64 | `tycana_VERSION_windows_x86_64.tar.gz` |
| Windows ARM64 | `tycana_VERSION_windows_arm64.tar.gz` |

### Verify downloads

All releases include `checksums.txt`:

```bash
shasum -a 256 -c checksums.txt
```

## Quick start

```bash
# Add tasks with natural language
tycana add "Check staging cert expiry friday 2pm"
tycana add "Capacity review next monday @infra #urgent ~1h"

# See what's on your plate
tycana list

# Complete tasks by title match
tycana done "staging cert"

# Filter and search
tycana list "@infra"
tycana list --due today
tycana list --tags urgent

# Organize with spaces
tycana context work
tycana add "Rotate API keys next monday"
```

## Pricing

**Free** — Full CLI, local storage, one space, manual calendar export.

**Sync ($6/month)** — Cloud sync, unlimited spaces, live calendar subscriptions, MCP access, sharing.

No trials. The free tier is genuinely useful. Pay when you want sync and calendar.

## Documentation

- Website: [tycana.com](https://tycana.com)
- Docs: [tycana.com/docs](https://tycana.com/docs)
- Built-in help: `tycana help`

## System requirements

- macOS 10.15+, Linux (glibc 2.17+), or Windows 10+
- x64 or ARM64

## Security

All binaries are built via GitHub Actions with checksums for verification.
Report security issues to hello@tycana.com.

## License

Proprietary. See the LICENSE file included in the release archive.

---

<p align="center">
  <a href="https://tycana.com">tycana.com</a>
</p>
