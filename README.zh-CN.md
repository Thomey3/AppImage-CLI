# AppImage-CLI

一款纯命令行驱动的 Linux AppImage 包管理器。基于 Bash 构建，严格遵循 KISS（Keep It Simple, Stupid）原则。无后台守护进程，无臃肿的图形界面，所有操作均可通过终端完成。

## 核心特性

- **纯命令行驱动**：100% 终端操作，无需图形界面依赖
- **双域管理**：支持全局安装（`/opt`，需要 `sudo`）和本地安装（`~/Applications`）两种模式
- **零常驻集成**：自动提取 AppImage 内置图标并生成 `.desktop` 文件，无需运行后台监控进程
- **增量更新**：通过 `appimageupdatetool` 集成 zsync 技术，仅下载二进制差异更新
- **沙盒隔离**：支持使用 `firejail` 进行可选的沙盒隔离运行
- **垃圾回收**：双向清理无效的桌面快捷方式和孤立的图标文件

## 依赖项

- `bash`（4.0 及以上版本）
- `curl` 或 `wget`（用于下载更新工具）
- `update-desktop-database`（可选，用于更新桌面数据库）
- `firejail`（可选，用于 `--sandbox` 沙盒隔离功能）

## 安装

```bash
# 克隆仓库
git clone https://github.com/YourUsername/AppImage-CLI.git
cd AppImage-CLI

# 安装（需要 sudo 权限）
sudo make install

# 或本地安装（仅当前用户可用）
make install
```

## 卸载

```bash
sudo make uninstall
```

## 使用说明

### 基本用法

```bash
# 查看帮助信息
AppImage -help

# 安装 AppImage（本地模式，无需 sudo）
AppImage -install /path/to/app.AppImage

# 安装时指定自定义名称
AppImage -install /path/to/app.AppImage MyApp

# 使用沙盒隔离安装（需要 firejail）
AppImage -install /path/to/app.AppImage MyApp --sandbox

# 全局安装（需要 sudo）
sudo AppImage -install /path/to/app.AppImage

# 卸载应用
AppImage -uninstall MyApp

# 更新应用（通过 zsync 增量更新）
AppImage -update MyApp

# 运行已安装的应用
AppImage -run MyApp

# 列出所有已安装的应用
AppImage -list

# 清理无效的快捷方式和孤立图标
AppImage -clean
```

### 命令详解

| 命令 | 说明 | 示例 |
|------|------|------|
| `-install` | 安装 AppImage 包到系统 | `AppImage -install app.AppImage` |
| `-uninstall` | 卸载已安装的应用 | `AppImage -uninstall app` |
| `-update` | 增量更新应用（需要原应用支持 zsync） | `AppImage -update app` |
| `-list` | 列出所有已安装的 AppImage 应用 | `AppImage -list` |
| `-clean` | 清理无效的桌面快捷方式和孤立的图标 | `AppImage -clean` |
| `-run` | 从命令行运行已安装的应用 | `AppImage -run app` |
| `-help` | 显示帮助信息 | `AppImage -help` |

### 安装范围说明

- **本地模式**（无 sudo）：应用安装到 `~/Applications` 目录，桌面快捷方式位于 `~/.local/share/applications`，图标位于 `~/Applications/icons`
- **全局模式**（使用 sudo）：应用安装到 `/opt/AppImages`，桌面快捷方式位于 `/usr/share/applications`，图标位于 `/opt/AppImages/icons`

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `APPIMAGE_LIB_DIR` | 库文件目录 | `/usr/local/lib/appimage` |
| `GLOBAL_TARGET_DIR` | 全局应用安装目录 | `/opt/AppImages` |
| `GLOBAL_DESKTOP_DIR` | 全局桌面快捷方式目录 | `/usr/share/applications` |
| `GLOBAL_ICON_DIR` | 全局图标目录 | `/opt/AppImages/icons` |
| `LOCAL_TARGET_DIR` | 本地应用安装目录 | `~/Applications` |
| `LOCAL_DESKTOP_DIR` | 本地桌面快捷方式目录 | `~/.local/share/applications` |
| `LOCAL_ICON_DIR` | 本地图标目录 | `~/Applications/icons` |

## 测试

本项目使用 BATS（Bash Automated Testing System）进行单元测试。测试覆盖了所有核心功能，包括安装、卸载、更新、列表、清理和运行命令。

```bash
# 安装测试依赖
sudo apt-get install bats shellcheck

# 运行测试
bats tests/

# 运行静态分析
shellcheck src/*.sh
```

## 工作原理

### 安装流程

1. 验证 AppImage 文件存在且可执行
2. 移动 AppImage 文件到目标目录（本地或全局）
3. 提取 AppImage 内置图标（通过 `--appimage-extract`）
4. 生成 `.desktop` 桌面快捷方式文件
5. 更新桌面数据库（如需要）

### 更新流程

1. 查找已安装的应用
2. 检查更新工具是否存在，如不存在则自动下载
3. 使用 `appimageupdatetool` 执行增量更新
4. 重新安装更新后的 AppImage
5. 清理旧版本文件

### 清理流程

1. 扫描桌面快捷方式目录中的所有 `.desktop` 文件
2. 检查每个快捷方式对应的 AppImage 文件是否仍然存在
3. 扫描图标目录中的所有图标文件
4. 检查每个图标是否仍有对应的桌面快捷方式
5. 删除不存在对应应用的快捷方式和孤立图标

## 常见问题

**问：为什么更新失败？**

答：只有支持 zsync 更新的 AppImage 才能使用更新功能。如果应用作者没有集成 zsync，更新将会失败。

**问：如何启用沙盒隔离？**

答：确保已安装 `firejail`，然后在安装时添加 `--sandbox` 参数。

**问：桌面图标不显示怎么办？**

答：运行 `AppImage -clean` 清理无效的快捷方式，或者尝试注销后重新登录以刷新桌面环境。

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
