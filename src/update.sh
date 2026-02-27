#!/bin/bash

do_update() {
    local search_name="$1"
    if [ -z "$search_name" ]; then
        log_error "缺少应用名称"
        exit 1
    fi

    local target_path=""
    local scope=""
    local current_target_dir=""
    local current_desktop_dir=""
    local file

    # 优先检索个人域
    for file in "$LOCAL_TARGET_DIR"/*; do
        if [[ "$(basename "$file")" == "$search_name".* ]]; then
            target_path="$file"
            scope="local"
            current_target_dir="$LOCAL_TARGET_DIR"
            current_desktop_dir="$LOCAL_DESKTOP_DIR"
            break
        fi
    done

    # 其次检索全局域
    if [ -z "$target_path" ]; then
        for file in "$GLOBAL_TARGET_DIR"/*; do
            if [[ "$(basename "$file")" == "$search_name".* ]]; then
                target_path="$file"
                scope="global"
                current_target_dir="$GLOBAL_TARGET_DIR"
                current_desktop_dir="$GLOBAL_DESKTOP_DIR"
                break
            fi
        done
    fi

    if [ -z "$target_path" ]; then
        log_error "未找到应用: $search_name"
        exit 1
    fi

    if [ "$scope" == "global" ] && [ "${EUID:-$(id -u)}" -ne 0 ]; then
        log_error "请使用 sudo 更新全局应用"
        exit 1
    fi

    local was_sandboxed=0
    if grep -q "firejail" "$current_desktop_dir/$search_name.desktop" 2>/dev/null; then
        was_sandboxed=1
    fi

    local updater_tool
    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        updater_tool="/usr/local/bin/appimageupdatetool"
    else
        updater_tool="$REAL_HOME/.local/bin/appimageupdatetool"
    fi

    if [ ! -f "$updater_tool" ]; then
        log_info "正在下载更新工具..."
        mkdir -p "$(dirname "$updater_tool")" 2>/dev/null || true
        local url="https://github.com/AppImage/AppImageUpdate/releases/download/continuous/appimageupdatetool-x86_64.AppImage"
        
        if command -v curl >/dev/null 2>&1; then
            curl -L -s -o "$updater_tool" "$url"
        else
            wget -qO "$updater_tool" "$url"
        fi
        chmod +x "$updater_tool"
    fi

    local old_files=()
    for file in "$current_target_dir"/*; do
        old_files+=("$file")
    done
    
    if ! "$updater_tool" --remove-old "$target_path"; then
        log_error "更新失败（可能不支持 zsync）"
        exit 1
    fi

    local new_appimage=""
    local is_old
    for file in "$current_target_dir"/*; do
        is_old=0
        for old_f in "${old_files[@]}"; do
            if [ "$file" == "$old_f" ]; then
                is_old=1
                break
            fi
        done
        
        if [ "$is_old" -eq 0 ]; then
            new_appimage="$file"
            break
        fi
    done

    if [ -n "$new_appimage" ]; then
        local old_app_name
        old_app_name=$(basename "$target_path")
        
        local install_args=("$new_appimage" "${old_app_name%.*}")
        if [ "$was_sandboxed" -eq 1 ]; then
            install_args+=("--sandbox")
        fi
        
        do_install "${install_args[@]}"
    fi

    # 显式阻断 Bash 隐式传递的非零状态码，确保管道干净闭环
    return 0
}