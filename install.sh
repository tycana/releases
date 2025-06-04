#!/bin/bash
# Tycana CLI Installer
# Usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tycana/tycana-cli/main/install.sh)"

set -u

# Homebrew-inspired installer patterns
abort() {
    printf "%s\n" "$@" >&2
    exit 1
}

# Fail fast with a concise message when not using bash
if [ -z "${BASH_VERSION:-}" ]; then
    abort "Bash is required to interpret this script."
fi

# Configuration
REPO="tycana/releases"
BINARY_NAME="tycana"

# Determine install directory
if [ -n "${TYCANA_INSTALL_DIR:-}" ]; then
    INSTALL_DIR="$TYCANA_INSTALL_DIR"
elif [ -w "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
elif [ -d "$HOME/.local/bin" ]; then
    INSTALL_DIR="$HOME/.local/bin"
elif [ -d "$HOME/bin" ]; then
    INSTALL_DIR="$HOME/bin"
else
    # Default to /usr/local/bin but will need sudo
    INSTALL_DIR="/usr/local/bin"
fi

# string formatters (inspired by Homebrew)
if [[ -t 1 ]]; then
    tty_escape() { printf "\033[%sm" "$1"; }
else
    tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_green="$(tty_mkbold 32)"
tty_yellow="$(tty_mkbold 33)"
tty_purple="$(tty_mkbold 35)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

# Logging functions (Homebrew-style)
ohai() {
    printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$*" >&2
}

warn() {
    printf "${tty_yellow}Warning${tty_reset}: %s\n" "$*" >&2
}

# Keep our accent style
accent() {
    printf "${tty_purple}%s${tty_reset}\n" "$*" >&2
}

# Execute with error handling
execute() {
    if ! "$@"; then
        abort "$(printf "Failed during: %s" "$*")"
    fi
}

# Check for sudo access (Homebrew-inspired)
unset HAVE_SUDO_ACCESS # unset this from the environment

have_sudo_access() {
    if [[ ! -x "/usr/bin/sudo" ]]; then
        return 1
    fi

    local -a SUDO=("/usr/bin/sudo")
    if [[ -n "${SUDO_ASKPASS-}" ]]; then
        SUDO+=("-A")
    elif [[ -n "${NONINTERACTIVE-}" ]]; then
        SUDO+=("-n")
    fi

    if [[ -z "${HAVE_SUDO_ACCESS-}" ]]; then
        if [[ -n "${NONINTERACTIVE-}" ]]; then
            ${SUDO[@]} -l /bin/mkdir &>/dev/null
        else
            ${SUDO[@]} -v && ${SUDO[@]} -l /bin/mkdir &>/dev/null
        fi
        HAVE_SUDO_ACCESS="$?"
    fi

    if [[ -n "${SUDO_ASKPASS-}" ]]; then
        SUDO+=("-A")
    fi

    return "${HAVE_SUDO_ACCESS}"
}

execute_sudo() {
    local -a SUDO=("/usr/bin/sudo")
    if have_sudo_access; then
        execute "${SUDO[@]}" "$@"
    else
        execute "$@"
    fi
}

# Platform detection
detect_platform() {
    case "$(uname -s)" in
        Darwin*) echo "darwin" ;;
        Linux*)  echo "linux" ;;
        *) abort "Unsupported platform: $(uname -s)" ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64) echo "x86_64" ;;
        arm64|aarch64) echo "arm64" ;;
        *) abort "Unsupported architecture: $(uname -m)" ;;
    esac
}

# Get latest release version
get_latest_version() {
    local api_url="https://api.github.com/repos/${REPO}/releases"
    
    # Try to get version from GitHub API
    if command -v curl >/dev/null 2>&1; then
        local version
        version=$(curl -s "$api_url" | grep '"tag_name":' | head -1 | sed -E 's/.*"([^"]+)".*/\1/' 2>/dev/null)
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi
    
    abort "Failed to get latest version from GitHub API"
}

# Download and verify binary
download_binary() {
    local platform="$1"
    local arch="$2"
    local version="$3"
    local temp_dir="$4"
    
    # Construct download URL based on release format
    # Remove 'v' prefix from version for filename
    local version_no_v="${version#v}"
    local base_name="tycana_${version_no_v}_${platform}_${arch}"
    local archive_url="https://github.com/${REPO}/releases/download/${version}/${base_name}.tar.gz"
    local archive_path="$temp_dir/${base_name}.tar.gz"
    
    ohai "Downloading from: $archive_url"
    
    # Download archive with progress and retry logic
    local download_attempts=3
    local attempt=1
    
    while [ $attempt -le $download_attempts ]; do
        if curl -fsSL --connect-timeout 10 --max-time 300 "$archive_url" -o "$archive_path"; then
            break
        else
            if [ $attempt -eq $download_attempts ]; then
                abort "Failed to download after $download_attempts attempts"
            fi
            warn "Download attempt $attempt failed, retrying..."
            attempt=$((attempt + 1))
            sleep 2
        fi
    done
    
    # Verify download size (basic check)
    if [ ! -s "$archive_path" ]; then
        abort "Downloaded file is empty or corrupted"
    fi
    
    local file_size
    file_size=$(stat -c%s "$archive_path" 2>/dev/null || stat -f%z "$archive_path" 2>/dev/null || echo "0")
    if [ "$file_size" -lt 1000000 ]; then  # Less than 1MB seems too small
        warn "Downloaded file seems unusually small ($file_size bytes)"
    fi
    
    ohai "Download complete ($(format_bytes $file_size)), extracting..."
    
    # Extract archive
    if ! tar -xzf "$archive_path" -C "$temp_dir"; then
        abort "Failed to extract archive"
    fi
    
    # Remove archive to save space
    rm -f "$archive_path"
    
    # Find the binary in extracted files
    local binary_path="$temp_dir/$BINARY_NAME"
    
    if [ ! -f "$binary_path" ]; then
        abort "Binary not found in downloaded archive: $binary_path"
    fi
    
    # Verify binary is executable
    if [ ! -x "$binary_path" ]; then
        chmod +x "$binary_path"
    fi
    
    # Basic binary verification (check if it's actually a binary)
    if ! file "$binary_path" | grep -q "executable" 2>/dev/null; then
        warn "Could not verify binary format (file command failed or not available)"
    fi
    
    ohai "Binary extracted and verified: $(basename "$binary_path")"
    echo "$binary_path"
}

# Format bytes for human-readable output
format_bytes() {
    local bytes="$1"
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$((bytes / 1024))KB"
    else
        echo "$((bytes / 1048576))MB"
    fi
}

# Install binary to system
install_binary() {
    local binary_path="$1"
    local install_path="$INSTALL_DIR/$BINARY_NAME"
    
    # Make binary executable
    chmod +x "$binary_path"
    
    # Check if install directory exists and is writable
    if [ ! -d "$INSTALL_DIR" ]; then
        warn "Creating directory: $INSTALL_DIR"
        
        # Try to create without sudo first
        if mkdir -p "$INSTALL_DIR" 2>/dev/null; then
            ohai "Directory created successfully"
        else
            # Only use sudo if we actually need it
            ohai "Elevated permissions required to create $INSTALL_DIR"
            if have_sudo_access; then
                execute_sudo /bin/mkdir -p "$INSTALL_DIR"
            else
                abort "Cannot create $INSTALL_DIR without sudo access. Please create it manually or set TYCANA_INSTALL_DIR to a writable location"
            fi
        fi
    fi
    
    # Install binary
    if [ -w "$INSTALL_DIR" ]; then
        execute /bin/cp "$binary_path" "$install_path"
    else
        ohai "Installing to $INSTALL_DIR (requires sudo)"
        execute_sudo /bin/cp "$binary_path" "$install_path"
    fi
    
    ohai "Binary installed to $install_path"
}

# Verify installation
verify_installation() {
    local install_path="$INSTALL_DIR/$BINARY_NAME"
    
    # Check if binary exists at install location
    if [ ! -f "$install_path" ]; then
        abort "Binary not found at expected location: $install_path"
    fi
    
    # Check if binary is executable
    if [ ! -x "$install_path" ]; then
        abort "Binary is not executable: $install_path"
    fi
    
    # Test if command is available in PATH
    if command -v "$BINARY_NAME" >/dev/null 2>&1; then
        local version
        version=$("$BINARY_NAME" version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
        printf "${tty_green}✓${tty_reset} Tycana CLI %s installed successfully!\n" "$version" >&2
        
        # Verify it's the binary we just installed
        local which_path
        which_path=$(command -v "$BINARY_NAME")
        if [ "$which_path" != "$install_path" ]; then
            warn "Found different tycana binary in PATH: $which_path"
            warn "Just installed: $install_path"
            ohai "You may have multiple installations"
        fi
        
        return 0
    else
        warn "Installation completed, but '$BINARY_NAME' command not found in PATH"
        suggest_path_fix
        return 1
    fi
}

# Suggest PATH fix based on shell and OS
suggest_path_fix() {
    local shell_name
    shell_name=$(basename "${SHELL:-/bin/bash}")
    local profile_file
    
    # Determine the appropriate profile file
    case "$shell_name" in
        bash)
            if [ "$(uname)" = "Darwin" ]; then
                profile_file="~/.bash_profile"
            else
                profile_file="~/.bashrc"
            fi
            ;;
        zsh)
            profile_file="~/.zshrc"
            ;;
        fish)
            profile_file="~/.config/fish/config.fish"
            ;;
        *)
            profile_file="~/.profile"
            ;;
    esac
    
    ohai "To fix this, add $INSTALL_DIR to your PATH:"
    echo >&2
    accent "Manual setup:"
    if [ "$shell_name" = "fish" ]; then
        echo "  echo 'set -gx PATH $INSTALL_DIR \$PATH' >> $profile_file" >&2
    else
        echo "  echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> $profile_file" >&2
    fi
    echo "  source $profile_file" >&2
    echo >&2
    accent "Or reload your shell:"
    echo "  exec \$SHELL" >&2
    echo >&2
}

# Show getting started info
show_getting_started() {
    echo >&2
    accent "🎯 Getting Started:"
    echo "  $BINARY_NAME --help               # Show all commands" >&2
    echo "  $BINARY_NAME add \"Your task\"      # Add your first task" >&2
    echo "  $BINARY_NAME list                 # View your tasks" >&2
    echo >&2
    accent "🚀 For cloud sync and premium features:"
    echo "  $BINARY_NAME login                # Sign up for premium" >&2
    echo >&2
    accent "📚 Documentation:"
    echo "  https://docs.tycana.com" >&2
    echo >&2
}

# Handle macOS-specific setup
setup_macos() {
    local binary_path="$1"
    
    # Remove macOS quarantine attribute if present
    if command -v xattr >/dev/null 2>&1; then
        ohai "Removing macOS quarantine attributes..."
        xattr -dr com.apple.quarantine "$binary_path" 2>/dev/null || true
    fi
}

# Main installation function
install_tycana() {
    local platform
    local arch
    local version
    local temp_dir
    local binary_path
    
    platform=$(detect_platform)
    arch=$(detect_arch)
    version=$(get_latest_version)
    
    if [ -z "$version" ]; then
        abort "Failed to determine latest version"
    fi
    
    ohai "Installing Tycana CLI $version for $platform-$arch"
    ohai "Install directory: $INSTALL_DIR"
    
    if [ "$INSTALL_DIR" = "$HOME/.local/bin" ] || [ "$INSTALL_DIR" = "$HOME/bin" ]; then
        ohai "Using user install directory (no sudo required)"
    elif [ ! -w "$INSTALL_DIR" ]; then
        warn "Will need elevated permissions to install to $INSTALL_DIR"
    fi
    
    # Create temp directory in a location that's likely to allow execution
    # Prefer XDG_RUNTIME_DIR, then HOME, then /tmp as fallback
    local temp_base
    if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -d "${XDG_RUNTIME_DIR:-}" ]; then
        temp_base="${XDG_RUNTIME_DIR:-}"
    elif [ -n "$HOME" ] && [ -d "$HOME" ]; then
        temp_base="$HOME/.cache"
        mkdir -p "$temp_base" 2>/dev/null || temp_base="$HOME"
    else
        temp_base="/tmp"
    fi
    
    temp_dir=$(mktemp -d "$temp_base/tycana-install.XXXXXX")
    trap "rm -rf '$temp_dir'" EXIT
    
    # Verify we can execute in the temp directory
    local test_script="$temp_dir/test.sh"
    echo '#!/bin/sh' > "$test_script"
    echo 'exit 0' >> "$test_script"
    chmod +x "$test_script"
    
    if ! "$test_script" 2>/dev/null; then
        abort "Cannot execute in temporary directory $temp_dir (possibly mounted with noexec). Try setting XDG_RUNTIME_DIR or HOME to a writable location."
    fi
    rm -f "$test_script"
    
    # Download binary
    binary_path=$(download_binary "$platform" "$arch" "$version" "$temp_dir")
    
    # macOS-specific setup
    if [ "$platform" = "darwin" ]; then
        setup_macos "$binary_path"
    fi
    
    # Install binary
    install_binary "$binary_path"
    
    # Verify installation
    if verify_installation; then
        show_getting_started
    fi
}

# Print header
print_header() {
    echo >&2
    accent "╭─────────────────────────────────────────────╮"
    accent "│                                             │"
    accent "│           Tycana CLI Installer              │"
    accent "│          Command Your Tasks                 │"
    accent "│                                             │"
    accent "╰─────────────────────────────────────────────╯"
    echo >&2
}

# Main execution
main() {
    print_header
    
    # Check prerequisites
    if ! command -v curl >/dev/null 2>&1; then
        abort "curl is required but not installed"
    fi
    
    if ! command -v tar >/dev/null 2>&1; then
        abort "tar is required but not installed"
    fi
    
    # Check if already installed
    if command -v "$BINARY_NAME" >/dev/null 2>&1; then
        local current_version
        current_version=$("$BINARY_NAME" version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
        warn "Tycana CLI $current_version is already installed"
        
        # Check for force install flag
        if [ "${TYCANA_FORCE_INSTALL:-}" = "1" ]; then
            ohai "Force install requested, proceeding with reinstallation"
        elif [ -t 0 ]; then
            # Interactive terminal available
            echo -n "Do you want to reinstall? [y/N]: "
            read -r response
            case "$response" in
                [yY][eE][sS]|[yY]) ;;
                *) ohai "Installation cancelled"; exit 0 ;;
            esac
        else
            # No interactive terminal (piped input), default to upgrade
            ohai "Upgrading to latest version..."
        fi
    fi
    
    install_tycana
}

# Run installer
main "$@"