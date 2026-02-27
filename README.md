# AppImageManager CLI

A lightweight, purely CLI-based AppImage package manager for Linux systems. Built strictly on Bash, following the KISS principle. No background daemons, no GUI bloat.

一款轻量级、纯命令行的 Linux AppImage 包管理器。基于 Bash 构建，遵循 KISS 原则。无后台守护进程，无臃肿的图形界面。

## Features (核心特性)

* **Dual-Scope Management (双域管理)**: Supports isolated management for Global (`/opt`, requires `sudo`) and Local (`~/Applications`) scopes.
* **Zero-Daemon Integration (零常驻集成)**: Automatically extracts native icons and generates `.desktop` files without running background watchers.
* **Delta Updates (增量更新)**: Integrates `zsync` via `appimageupdatetool` to download only binary diffs.
* **Sandbox Security (沙盒安全)**: Optional isolation via `firejail` during installation.
* **Garbage Collection (垃圾回收)**: Cleans up dead desktop entries and orphaned icons bidirectionally.

## Prerequisites (依赖项)

* `bash`
* `curl` or `wget` (For downloading the update tool)
* `firejail` (Optional, for `--sandbox` isolation)

## Installation (安装)

```bash
git clone [https://github.com/YourUsername/AppImageManager.git](https://github.com/YourUsername/AppImageManager.git)
cd AppImageManager
sudo make install
```

## To uninstall:
```bash
sudo make uninstall
```

## Usage (使用说明)
```Bash
# Install an AppImage (Global scope requires sudo)
[sudo] AppImage -install /path/to/app.AppImage [CustomName] [--sandbox]

# Uninstall
[sudo] AppImage -uninstall <AppName>

# Update via zsync
[sudo] AppImage -update <AppName>

# Run from CLI
AppImage -run <AppName>

# List all tracked applications
[sudo] AppImage -list

# Clean dead links and orphaned icons
[sudo] AppImage -clean
```