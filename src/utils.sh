#!/bin/bash

log_info() {
    echo -e "\e[32m[INFO]\e[0m $1"
}

log_error() {
    echo -e "\e[31m[ERROR]\e[0m $1" >&2
}

# 提取物理执行用户的真实 HOME 路径，防止 sudo 导致 $HOME 漂移为 /root
REAL_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)

# 定义双域常量
GLOBAL_TARGET_DIR="/opt/AppImages"
GLOBAL_DESKTOP_DIR="/usr/share/applications"
GLOBAL_ICON_DIR="/opt/AppImages/icons"

LOCAL_TARGET_DIR="$REAL_HOME/Applications"
LOCAL_DESKTOP_DIR="$REAL_HOME/.local/share/applications"
LOCAL_ICON_DIR="$REAL_HOME/Applications/icons"

init_env_paths() {
    if [ "$EUID" -eq 0 ]; then
        TARGET_DIR="$GLOBAL_TARGET_DIR"
        DESKTOP_DIR="$GLOBAL_DESKTOP_DIR"
        ICON_DIR="$GLOBAL_ICON_DIR"
    else
        TARGET_DIR="$LOCAL_TARGET_DIR"
        DESKTOP_DIR="$LOCAL_DESKTOP_DIR"
        ICON_DIR="$LOCAL_ICON_DIR"
    fi

    # 预初始化基础挂载点（抑制无权限时的报错输出）
    mkdir -p "$GLOBAL_TARGET_DIR" "$GLOBAL_DESKTOP_DIR" "$GLOBAL_ICON_DIR" 2>/dev/null || true
    mkdir -p "$LOCAL_TARGET_DIR" "$LOCAL_DESKTOP_DIR" "$LOCAL_ICON_DIR" 2>/dev/null || true
}

refresh_desktop_database() {
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$LOCAL_DESKTOP_DIR" 2>/dev/null || true
        if [ "$EUID" -eq 0 ]; then
            update-desktop-database "$GLOBAL_DESKTOP_DIR" 2>/dev/null || true
        fi
    fi
}