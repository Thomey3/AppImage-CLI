# AppImage-CLI

A pure command-line interface (CLI) package manager for AppImages on Linux. Built strictly on Bash, following the KISS (Keep It Simple, Stupid) principle. No background daemons, no GUI bloat. All operations can be completed through the terminal.

## Features

- **Pure CLI Workflow**: 100% terminal-based operations, no GUI dependencies required
- **Dual-Scope Management**: Supports both global installation (`/opt`, requires `sudo`) and local installation (`~/Applications`) modes
- **Zero-Daemon Integration**: Automatically extracts built-in AppImage icons and generates `.desktop` files without running background monitoring processes
- **Delta Updates**: Integrates zsync technology through `appimageupdatetool` to download only binary diffs
- **Sandbox Security**: Optional sandbox isolation using `firejail`
- **Garbage Collection**: Bidirectional cleanup of invalid desktop entries and orphaned icons

## Prerequisites

- `bash` (version 4.0 or higher)
- `curl` or `wget` (for downloading the update tool)
- `update-desktop-database` (optional, for updating desktop database)
- `firejail` (optional, for `--sandbox` isolation feature)

## Installation

```bash
# Clone the repository
git clone https://github.com/YourUsername/AppImage-CLI.git
cd AppImage-CLI

# Install (requires sudo)
sudo make install

# Or install locally (current user only)
make install
```

## Uninstallation

```bash
sudo make uninstall
```

## Usage

### Basic Usage

```bash
# Display help information
AppImage -help

# Install AppImage (local mode, no sudo required)
AppImage -install /path/to/app.AppImage

# Install with custom name
AppImage -install /path/to/app.AppImage MyApp

# Install with sandbox isolation (requires firejail)
AppImage -install /path/to/app.AppImage MyApp --sandbox

# Install globally (requires sudo)
sudo AppImage -install /path/to/app.AppImage

# Uninstall application
AppImage -uninstall MyApp

# Update application (via zsync delta update)
AppImage -update MyApp

# Run installed application
AppImage -run MyApp

# List all installed applications
AppImage -list

# Clean invalid shortcuts and orphaned icons
AppImage -clean
```

### Command Reference

| Command | Description | Example |
|---------|-------------|---------|
| `-install` | Install AppImage package to system | `AppImage -install app.AppImage` |
| `-uninstall` | Uninstall installed application | `AppImage -uninstall app` |
| `-update` | Delta update application (requires original app to support zsync) | `AppImage -update app` |
| `-list` | List all installed AppImage applications | `AppImage -list` |
| `-clean` | Clean invalid desktop entries and orphaned icons | `AppImage -clean` |
| `-run` | Run installed application from command line | `AppImage -run app` |
| `-help` | Display help information | `AppImage -help` |

### Installation Scope

- **Local Mode** (without sudo): Applications are installed to `~/Applications`, desktop shortcuts to `~/.local/share/applications`, icons to `~/Applications/icons`
- **Global Mode** (with sudo): Applications are installed to `/opt/AppImages`, desktop shortcuts to `/usr/share/applications`, icons to `/opt/AppImages/icons`

## Environment Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `APPIMAGE_LIB_DIR` | Library directory | `/usr/local/lib/appimage` |
| `GLOBAL_TARGET_DIR` | Global application directory | `/opt/AppImages` |
| `GLOBAL_DESKTOP_DIR` | Global desktop shortcut directory | `/usr/share/applications` |
| `GLOBAL_ICON_DIR` | Global icon directory | `/opt/AppImages/icons` |
| `LOCAL_TARGET_DIR` | Local application directory | `~/Applications` |
| `LOCAL_DESKTOP_DIR` | Local desktop shortcut directory | `~/.local/share/applications` |
| `LOCAL_ICON_DIR` | Local icon directory | `~/Applications/icons` |

## Testing

This project uses BATS (Bash Automated Testing System) for unit testing. Tests cover all core functions including install, uninstall, update, list, clean, and run commands.

```bash
# Install test dependencies
sudo apt-get install bats shellcheck

# Run tests
bats tests/

# Run static analysis
shellcheck src/*.sh
```

## How It Works

### Installation Process

1. Verify AppImage file exists and is executable
2. Move AppImage file to target directory (local or global)
3. Extract built-in AppImage icons (via `--appimage-extract`)
4. Generate `.desktop` desktop shortcut file
5. Update desktop database (if needed)

### Update Process

1. Find installed application
2. Check if update tool exists, download if not
3. Execute delta update using `appimageupdatetool`
4. Reinstall updated AppImage
5. Clean up old version files

### Clean Process

1. Scan all `.desktop` files in desktop shortcut directory
2. Check if each shortcut's corresponding AppImage file still exists
3. Scan all icon files in icon directory
4. Check if each icon has a corresponding desktop shortcut
5. Remove shortcuts without corresponding apps and orphaned icons

## FAQ

**Q: Why does update fail?**

A: Only AppImages with zsync update support can use the update feature. If the app author hasn't integrated zsync, the update will fail.

**Q: How to enable sandbox isolation?**

A: Ensure `firejail` is installed, then add the `--sandbox` parameter during installation.

**Q: Desktop icon not showing?**

A: Run `AppImage -clean` to clean up invalid shortcuts, or try logging out and back in to refresh the desktop environment.

## License

MIT License

## Contributing

Issues and Pull Requests are welcome!
