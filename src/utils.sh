#!/bin/bash

log_info() { echo -e "\e[32m[INFO]\e[0m $1"; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $1" >&2; }

# 允许测试环境通过环境变量覆写路径，实现沙箱隔离
# 优先使用环境变量中已设置的 REAL_HOME，避免测试环境变量被覆盖
REAL_HOME="${REAL_HOME:-$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)}"


# 允许测试环境通过环境变量覆写路径，实现沙箱隔离
# shellcheck disable=SC2034
GLOBAL_TARGET_DIR="${GLOBAL_TARGET_DIR:-/opt/AppImages}"
# shellcheck disable=SC2034
GLOBAL_DESKTOP_DIR="${GLOBAL_DESKTOP_DIR:-/usr/share/applications}"
# shellcheck disable=SC2034
GLOBAL_ICON_DIR="${GLOBAL_ICON_DIR:-/opt/AppImages/icons}"

# shellcheck disable=SC2034
LOCAL_TARGET_DIR="${LOCAL_TARGET_DIR:-$REAL_HOME/Applications}"
# shellcheck disable=SC2034
LOCAL_DESKTOP_DIR="${LOCAL_DESKTOP_DIR:-$REAL_HOME/.local/share/applications}"
# shellcheck disable=SC2034
LOCAL_ICON_DIR="${LOCAL_ICON_DIR:-$REAL_HOME/Applications/icons}"

init_env_paths() {
    # 忽略由其他脚本引用的共享环境变量的未使用警告
    # shellcheck disable=SC2034
    if [ "${EUID:-0}" -eq 0 ]; then
        TARGET_DIR="$GLOBAL_TARGET_DIR"
        DESKTOP_DIR="$GLOBAL_DESKTOP_DIR"
        ICON_DIR="$GLOBAL_ICON_DIR"
    else
        TARGET_DIR="$LOCAL_TARGET_DIR"
        DESKTOP_DIR="$LOCAL_DESKTOP_DIR"
        ICON_DIR="$LOCAL_ICON_DIR"
    fi

    mkdir -p "$GLOBAL_TARGET_DIR" "$GLOBAL_DESKTOP_DIR" "$GLOBAL_ICON_DIR" 2>/dev/null || true
    mkdir -p "$LOCAL_TARGET_DIR" "$LOCAL_DESKTOP_DIR" "$LOCAL_ICON_DIR" 2>/dev/null || true
}

refresh_desktop_database() {
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$LOCAL_DESKTOP_DIR" 2>/dev/null || true
        if [ "${EUID:-0}" -eq 0 ]; then
            update-desktop-database "$GLOBAL_DESKTOP_DIR" 2>/dev/null || true
        fi
    fi
}