# Tycana CLI Releases

<p align="center">
  <img src="https://img.shields.io/github/v/release/tycana/releases?style=for-the-badge&label=Latest%20Release" alt="Latest Release">
  <img src="https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-blue?style=for-the-badge" alt="Platforms">
  <img src="https://img.shields.io/badge/License-Proprietary-red?style=for-the-badge" alt="License">
</p>

<p align="center">
  <strong>Command your tasks from the terminal.</strong><br>
  The terminal-first task manager that respects your workflow and your data.
</p>

---

## 🚀 Download Tycana

### Latest Release
Download the latest version from the [releases page](https://github.com/tycana/releases/releases/latest).

### Quick Install

#### macOS & Linux
```bash
# Download the latest release (replace VERSION and PLATFORM)
curl -L https://github.com/tycana/releases/releases/download/VERSION/tycana_VERSION_PLATFORM.tar.gz -o tycana.tar.gz

# Extract
tar xzf tycana.tar.gz

# Move to PATH
sudo mv tycana /usr/local/bin/

# Verify installation
tycana version
```

#### Platform Files
- **macOS Intel**: `tycana_VERSION_darwin_x86_64.tar.gz`
- **macOS Apple Silicon**: `tycana_VERSION_darwin_arm64.tar.gz`
- **Linux x64**: `tycana_VERSION_linux_x86_64.tar.gz`
- **Linux ARM**: `tycana_VERSION_linux_arm64.tar.gz`

#### Windows
1. Download the appropriate zip file:
   - **Windows x64**: `tycana_VERSION_windows_x86_64.zip`
   - **Windows ARM**: `tycana_VERSION_windows_arm64.zip`
2. Extract the zip file
3. Add the `tycana.exe` to your PATH
4. Verify with `tycana version`

### Verify Downloads
All releases include a `checksums.txt` file. Verify your download:

```bash
# macOS/Linux
shasum -a 256 -c checksums.txt

# Windows (PowerShell)
Get-FileHash tycana.exe -Algorithm SHA256
```

---

## 📘 What is Tycana?

Tycana is a modern command-line task management system that prioritizes:

- **🔓 Data Ownership**: Your tasks in plain YAML files
- **🛠️ Developer Workflows**: Terminal-native, scriptable, composable
- **🌱 Calm Productivity**: Structure without rigidity
- **⚡ Natural Language**: Quick capture with smart parsing

### Key Features

```bash
# Quick capture with natural language
tycana add "Review PR by 3pm tomorrow @backend #code-review ~45m"

# Smart filtering
tycana today                    # What's on your plate
tycana list --due "this week"   # Week at a glance
tycana list --project work      # Project-focused view

# Git-powered sync
tycana sync --git              # Version control your tasks
```

---

## 🎯 Beta Program

Tycana is currently in beta. We're looking for developers who:
- Live in the terminal
- Value data ownership
- Want to shape the future of task management

### How to Join
1. Install Tycana CLI
2. Use it for a week
3. Share feedback via [hello@tycana.com](mailto:hello@tycana.com)
4. Get lifetime discount when we launch

---

## 📚 Documentation

- **Quick Start**: See [Installation Guide](https://tycana.com/install)
- **User Guide**: Available after installation via `tycana help`
- **Website**: [tycana.com](https://tycana.com)

---

## 🔄 Release Schedule

- **Beta Releases**: Weekly on Fridays
- **Version Format**: `v0.x.x` during beta
- **Stable Release**: Q2 2025 (v1.0.0)

### Release Channels
- **Latest**: Current beta release (recommended)
- **Edge**: Pre-release builds (experimental)

---

## 📋 System Requirements

### Minimum Requirements
- **macOS**: 10.15 or later
- **Linux**: Any modern distribution with glibc 2.17+
- **Windows**: Windows 10 or later
- **Architecture**: x64 or ARM64

### Tested On
- macOS 14 (Sonoma) on Apple Silicon
- Ubuntu 22.04 LTS
- Fedora 39
- Windows 11

---

## ⚖️ License

Tycana CLI is proprietary software. During the beta period:
- Free for evaluation and testing
- Feedback and bug reports appreciated
- No redistribution permitted

See the [LICENSE](https://github.com/tycana/releases/releases/latest/download/LICENSE) file included with each release for full terms.

---

## 🤝 Support

- **Email**: [hello@tycana.com](mailto:hello@tycana.com)
- **Issues**: Contact us directly (issue tracker coming soon)
- **Updates**: Follow development at [tycana.com](https://tycana.com)

---

## 🔐 Security

- All binaries are built via GitHub Actions
- Checksums provided for verification
- Report security issues to: hello@tycana.com

---

<p align="center">
  <i>Command your tasks. Own your data. Stay in flow.</i><br>
  <strong>© 2025 Tycana. All rights reserved.</strong>
</p>
