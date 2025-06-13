#!/bin/bash
# Tycana CLI Upgrader
# Usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tycana/tycana-cli/main/upgrade.sh)"

set -u

# Homebrew-inspired patterns for consistency with install.sh
abort() {
    printf "%s\n" "$@" >&2
    exit 1
}

# Fail fast with a concise message when not using bash
if [ -z "${BASH_VERSION:-}" ]; then
    abort "Bash is required to interpret this script."
fi

# Configuration (matching install.sh)
REPO="tycana/releases"
BINARY_NAME="tycana"

# string formatters (matching install.sh)
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

# Logging functions (matching install.sh style)
ohai() {
    printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$*" >&2
}

warn() {
    printf "${tty_yellow}Warning${tty_reset}: %s\n" "$*" >&2
}

accent() {
    printf "${tty_purple}%s${tty_reset}\n" "$*" >&2
}

# Execute with error handling
execute() {
    if ! "$@"; then
        abort "$(printf "Failed during: %s" "$*")"
    fi
}

# Platform detection (matching install.sh)
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

# Get latest release version (matching install.sh)
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

# Find current Tycana installation
find_current_installation() {
    local current_binary
    current_binary=$(command -v "$BINARY_NAME" 2>/dev/null)
    
    if [ -z "$current_binary" ]; then
        abort "Tycana CLI not found. Please install it first using: curl -fsSL https://raw.githubusercontent.com/tycana/tycana-cli/main/install.sh | bash"
    fi
    
    # Resolve symlinks to get the actual binary location
    if command -v readlink >/dev/null 2>&1; then
        current_binary=$(readlink -f "$current_binary")
    fi
    
    echo "$current_binary"
}

# Get current version
get_current_version() {
    local current_binary="$1"
    local current_version
    
    # Extract version from the binary (matching install.sh format)
    current_version=$("$current_binary" version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
    
    if [ -z "$current_version" ]; then
        warn "Could not determine current version"
        echo "unknown"
    else
        echo "$current_version"
    fi
}

# Format bytes for human-readable output (from install.sh)
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

# Download and verify binary (adapted from install.sh)
download_binary() {
    local platform="$1"
    local arch="$2"
    local version="$3"
    local temp_dir="$4"
    
    # Construct download URL (matching install.sh format)
    local version_no_v="${version#v}"
    local base_name="tycana_${version_no_v}_${platform}_${arch}"
    local archive_url="https://github.com/${REPO}/releases/download/${version}/${base_name}.tar.gz"
    local archive_path="$temp_dir/${base_name}.tar.gz"
    
    ohai "Downloading from: $archive_url"
    
    # Download archive with retry logic (from install.sh)
    local download_attempts=3
    local attempt=1
    
    while [ $attempt -le $download_attempts ]; do
        if curl -fsSL --connect-timeout 10 --max-time 300 "$archive_url" -o "$archive_path"; then
            break
        else
            local curl_exit_code=$?
            if [ $attempt -eq $download_attempts ]; then
                if [ $curl_exit_code -eq 22 ]; then
                    abort "Download failed: Release $version not found (HTTP 404). Please check if the version exists at: https://github.com/$REPO/releases"
                else
                    abort "Failed to download after $download_attempts attempts (curl exit code: $curl_exit_code)"
                fi
            fi
            warn "Download attempt $attempt failed (curl exit code: $curl_exit_code), retrying..."
            attempt=$((attempt + 1))
            sleep 2
        fi
    done
    
    # Verify download (from install.sh)
    if [ ! -s "$archive_path" ]; then
        abort "Downloaded file is empty or corrupted"
    fi
    
    local file_size
    file_size=$(stat -c%s "$archive_path" 2>/dev/null || stat -f%z "$archive_path" 2>/dev/null || echo "0")
    if [ "$file_size" -lt 1000000 ]; then
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
    
    # Make it executable
    chmod +x "$binary_path"
    
    # Basic binary verification
    if ! file "$binary_path" | grep -q "executable" 2>/dev/null; then
        warn "Could not verify binary format (file command failed or not available)"
    fi
    
    ohai "Binary extracted and verified: $(basename "$binary_path")"
    echo "$binary_path"
}

# Check for sudo access (from install.sh)
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

# Safely replace binary (THE KEY DIFFERENCE from install.sh)
safe_replace_binary() {
    local current_binary="$1"
    local new_binary="$2"
    
    ohai "Replacing binary at: $current_binary"
    
    # Check if we need sudo for this operation
    local binary_dir
    binary_dir=$(dirname "$current_binary")
    local needs_sudo=false
    
    if [ ! -w "$binary_dir" ]; then
        needs_sudo=true
        ohai "Elevated permissions required for $binary_dir"
    fi
    
    # Create backup filename with timestamp
    local backup_binary="${current_binary}.backup-$(date +%s)"
    
    # Step 1: Move current binary to backup (this releases the file handle!)
    # This is the key to solving "text file busy"
    if [ "$needs_sudo" = true ]; then
        if ! execute_sudo mv "$current_binary" "$backup_binary"; then
            abort "Failed to backup current binary to $backup_binary"
        fi
    else
        if ! mv "$current_binary" "$backup_binary"; then
            abort "Failed to backup current binary to $backup_binary"
        fi
    fi
    
    # Step 2: Move new binary into place atomically
    if [ "$needs_sudo" = true ]; then
        if ! execute_sudo mv "$new_binary" "$current_binary"; then
            # Rollback on failure
            warn "Failed to install new binary, rolling back..."
            if ! execute_sudo mv "$backup_binary" "$current_binary"; then
                abort "CRITICAL: Failed to restore backup! Original binary at: $backup_binary"
            fi
            abort "Upgrade failed - original binary restored"
        fi
    else
        if ! mv "$new_binary" "$current_binary"; then
            # Rollback on failure
            warn "Failed to install new binary, rolling back..."
            if ! mv "$backup_binary" "$current_binary"; then
                abort "CRITICAL: Failed to restore backup! Original binary at: $backup_binary"
            fi
            abort "Upgrade failed - original binary restored"
        fi
    fi
    
    # Step 3: Verify new binary works
    if ! "$current_binary" version >/dev/null 2>&1; then
        # Rollback on failure
        warn "New binary failed verification, rolling back..."
        if [ "$needs_sudo" = true ]; then
            if ! execute_sudo mv "$backup_binary" "$current_binary"; then
                abort "CRITICAL: Failed to restore backup! Original binary at: $backup_binary"
            fi
        else
            if ! mv "$backup_binary" "$current_binary"; then
                abort "CRITICAL: Failed to restore backup! Original binary at: $backup_binary"
            fi
        fi
        abort "New binary verification failed - original binary restored"
    fi
    
    # Step 4: Clean up backup on success
    if [ "$needs_sudo" = true ]; then
        execute_sudo rm -f "$backup_binary"
    else
        rm -f "$backup_binary"
    fi
    
    ohai "Binary successfully replaced"
}

# Handle macOS-specific setup (from install.sh)
setup_macos() {
    local binary_path="$1"
    
    # Remove macOS quarantine attribute if present
    if command -v xattr >/dev/null 2>&1; then
        ohai "Removing macOS quarantine attributes..."
        xattr -dr com.apple.quarantine "$binary_path" 2>/dev/null || true
    fi
}

# Main upgrade function
upgrade_tycana() {
    local platform
    local arch
    local latest_version
    local current_binary
    local current_version
    local temp_dir
    local new_binary_path
    
    # Detect system
    platform=$(detect_platform)
    arch=$(detect_arch)
    
    ohai "Detected platform: ${platform}-${arch}"
    
    # Find current installation
    current_binary=$(find_current_installation)
    ohai "Found current installation: $current_binary"
    
    # Get current version
    current_version=$(get_current_version "$current_binary")
    ohai "Current version: $current_version"
    
    # Get latest version
    latest_version=$(get_latest_version)
    ohai "Latest version: $latest_version"
    
    # Check if upgrade is needed
    local latest_version_clean="${latest_version#v}"
    if [ "$current_version" = "$latest_version_clean" ]; then
        printf "${tty_green}✓${tty_reset} Already running the latest version (%s)\n" "$current_version" >&2
        echo >&2
        accent "No upgrade needed!"
        exit 0
    fi
    
    ohai "Upgrading from $current_version to $latest_version_clean"
    
    # Create temp directory (matching install.sh logic)
    local temp_base
    if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -d "${XDG_RUNTIME_DIR:-}" ]; then
        temp_base="${XDG_RUNTIME_DIR:-}"
    elif [ -n "$HOME" ] && [ -d "$HOME" ]; then
        temp_base="$HOME/.cache"
        mkdir -p "$temp_base" 2>/dev/null || temp_base="$HOME"
    else
        temp_base="/tmp"
    fi
    
    temp_dir=$(mktemp -d "$temp_base/tycana-upgrade.XXXXXX")
    trap "rm -rf '$temp_dir'" EXIT
    
    # Download new version
    new_binary_path=$(download_binary "$platform" "$arch" "$latest_version" "$temp_dir")
    
    # macOS-specific setup
    if [ "$platform" = "darwin" ]; then
        setup_macos "$new_binary_path"
    fi
    
    # Perform safe replacement (the key difference from install.sh)
    safe_replace_binary "$current_binary" "$new_binary_path"
    
    # Final verification
    local final_version
    final_version=$(get_current_version "$current_binary")
    
    echo >&2
    printf "${tty_green}✓${tty_reset} Successfully upgraded from %s to %s!\n" "$current_version" "$final_version" >&2
    echo >&2
    accent "🎉 Upgrade complete!"
    
    # Show what's new
    echo >&2
    accent "📋 What's new:"
    echo "  View release notes: https://github.com/$REPO/releases/tag/$latest_version" >&2
    echo >&2
}

# Print header (matching install.sh style)
print_header() {
    echo >&2
    accent "╭─────────────────────────────────────────────╮"
    accent "│                                             │"
    accent "│           Tycana CLI Upgrader               │"
    accent "│          Command Your Tasks                 │"
    accent "│                                             │"
    accent "╰─────────────────────────────────────────────╯"
    echo >&2
}

# Main execution
main() {
    print_header
    
    # Check prerequisites (matching install.sh)
    if ! command -v curl >/dev/null 2>&1; then
        abort "curl is required but not installed"
    fi
    
    if ! command -v tar >/dev/null 2>&1; then
        abort "tar is required but not installed"
    fi
    
    # Verify Tycana is installed
    if ! command -v "$BINARY_NAME" >/dev/null 2>&1; then
        abort "Tycana CLI is not installed. Please install it first using: curl -fsSL https://raw.githubusercontent.com/tycana/tycana-cli/main/install.sh | bash"
    fi
    
    upgrade_tycana
}

# Run upgrader
main "$@"