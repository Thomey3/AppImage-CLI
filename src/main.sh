#!/bin/bash

# 允许通过环境变量覆盖库目录，以便于自动化测试在源码树内运行
LIB_DIR="${APPIMAGE_LIB_DIR:-/usr/local/lib/appimage}"

# shellcheck source=src/utils.sh
source "$LIB_DIR/utils.sh"
# shellcheck source=src/install.sh
source "$LIB_DIR/install.sh"
# shellcheck source=src/uninstall.sh
source "$LIB_DIR/uninstall.sh"
# shellcheck source=src/update.sh
source "$LIB_DIR/update.sh"
# shellcheck source=src/list.sh
source "$LIB_DIR/list.sh"
# shellcheck source=src/clean.sh
source "$LIB_DIR/clean.sh"
# shellcheck source=src/run.sh
source "$LIB_DIR/run.sh"

show_help() {
    cat << 'HELP_EOF'
AppImage - AppImage 包管理工具

用法:
  AppImage -install <文件> [名称] [--sandbox]    安装 AppImage
  AppImage -uninstall <名称>                     卸载应用
  AppImage -update <名称>                        更新应用
  AppImage -list                                列出已安装应用
  AppImage -clean                               清理无效快捷方式和孤立图标
  AppImage -run <名称>                          运行应用
  AppImage -help                                显示帮助信息

选项:
  -install               安装 AppImage 包
  -uninstall            卸载已安装的应用
  -update               通过 zsync 增量更新应用
  -list                 列出所有已安装的 AppImage 应用
  -clean                清理无效的桌面快捷方式和孤立的图标文件
  -run                  从命令行运行已安装的应用
  -help                 显示此帮助信息

全局选项:
  --sandbox             使用 firejail 沙盒隔离运行（需要安装 firejail）

说明:
  无 sudo 权限时在用户目录 ($HOME/Applications) 安装
  使用 sudo 时在系统目录 (/opt/AppImages) 安装

示例:
  AppImage -install /path/to/AppImage.AppImage
  AppImage -install /path/to/AppImage.AppImage MyApp --sandbox
  AppImage -uninstall MyApp
  AppImage -update MyApp
  AppImage -list
  AppImage -run MyApp
  AppImage -clean
HELP_EOF
}

main() {
    init_env_paths
    local action="$1"
    shift
    case "$action" in
        -install) do_install "$@" ;;
        -uninstall) do_uninstall "$1" ;;
        -update) do_update "$1" ;;
        -list) do_list ;;
        -clean) do_clean ;;
        -run) do_run "$1" ;;
        -help|--help|help) show_help ;;
        *) echo "用法: AppImage -install | -uninstall | -update | -list | -clean | -run | -help"; exit 1 ;;
    esac
}

# 仅在作为主程序调用时执行 main，被测试框架 source 时不主动执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi