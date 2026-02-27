#!/bin/bash

LIB_DIR="/usr/local/lib/appimage"

source "$LIB_DIR/utils.sh"
source "$LIB_DIR/install.sh"
source "$LIB_DIR/uninstall.sh"
source "$LIB_DIR/update.sh"
source "$LIB_DIR/list.sh"
source "$LIB_DIR/clean.sh"
source "$LIB_DIR/run.sh"

show_help() {
    echo "AppImageManager CLI"
    echo "======================================================"
    echo "用法:"
    echo "  AppImage -install <AppImage路径> [自定义名称] [--sandbox]"
    echo "  AppImage -uninstall <应用名称>"
    echo "  AppImage -update <应用名称>"
    echo "  AppImage -run <应用名称>"
    echo "  AppImage -list"
    echo "  AppImage -clean"
    echo ""
    echo "行为准则:"
    echo "  包含 sudo : 操作穿透全局作用域 (/opt)。"
    echo "  无 sudo   : 操作约束在本地用户作用域 (~/Applications)。"
}

main() {
    init_env_paths

    local action="$1"
    shift

    case "$action" in
        -install)
            do_install "$@"
            ;;
        -uninstall)
            do_uninstall "$1"
            ;;
        -update)
            do_update "$1"
            ;;
        -list)
            do_list
            ;;
        -clean)
            do_clean
            ;;
        -run)
            do_run "$1"
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

main "$@"