#!/bin/bash

do_update() {
    local search_name="$1"

    if [ -z "$search_name" ]; then
        log_error "缺少应用名称参数。"
        exit 1
    fi

    local target_path=""
    local scope=""
    local current_target_dir=""
    local current_desktop_dir=""

    for file in "$LOCAL_TARGET_DIR"/*; do
        if [[ "$(basename "$file")" == "$search_name".* ]]; then
            target_path="$file"
            scope="local"
            current_target_dir="$LOCAL_TARGET_DIR"
            current_desktop_dir="$LOCAL_DESKTOP_DIR"
            break
        fi
    done

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
        log_error "系统内不存在目标实体: $search_name"
        exit 1
    fi

    if [ "$scope" == "global" ] && [ "$EUID" -ne 0 ]; then
        log_error "目标处于全局域，更新必须提权。请执行 'sudo AppImage -update $search_name'。"
        exit 1
    fi

    local was_sandboxed=0
    local old_desktop_file="$current_desktop_dir/$search_name.desktop"
    if [ -f "$old_desktop_file" ] && grep -q "firejail" "$old_desktop_file"; then
        was_sandboxed=1
    fi

    local updater_tool="/usr/local/bin/appimageupdatetool"
    if [ "$EUID" -ne 0 ]; then
        updater_tool="$REAL_HOME/.local/bin/appimageupdatetool"
    fi

    if [ ! -f "$updater_tool" ]; then
        log_info "构建更新依赖 appimageupdatetool..."
        mkdir -p "$(dirname "$updater_tool")"
        
        local download_url="https://github.com/AppImage/AppImageUpdate/releases/download/continuous/appimageupdatetool-x86_64.AppImage"
        
        if command -v curl >/dev/null 2>&1; then
            curl -L -s -o "$updater_tool" "$download_url"
        elif command -v wget >/dev/null 2>&1; then
            wget -qO "$updater_tool" "$download_url"
        else
            log_error "核心网络组件 wget/curl 缺失，进程阻断。"
            exit 1
        fi

        if [ ! -f "$updater_tool" ] || [ ! -s "$updater_tool" ]; then
            log_error "更新核心获取失败，网络异常。"
            rm -f "$updater_tool"
            exit 1
        fi
        chmod +x "$updater_tool"
    fi

    log_info "请求差异块 (Zsync)..."
    local old_files=$(ls -1 "$current_target_dir")
    
    if ! "$updater_tool" --remove-old "$target_path"; then
        log_error "增量合并失败。源未提供 zsync 或网络阻断。"
        exit 1
    fi

    local new_files=$(ls -1 "$current_target_dir")
    local new_appimage=""
    
    for f in $new_files; do
        if ! echo "$old_files" | grep -q "^$f$"; then
            if [[ "$f" == *.AppImage ]] || [[ "$f" == *.appimage ]]; then
                new_appimage="$current_target_dir/$f"
                break
            fi
        fi
    done

    if [ -n "$new_appimage" ]; then
        log_info "实体写入完成，重建环境锚点..."
        local old_app_name="$(basename "$target_path")"
        old_app_name="${old_app_name%.*}"

        local install_args=("$new_appimage" "$old_app_name")
        if [ "$was_sandboxed" -eq 1 ]; then
            install_args+=("--sandbox")
        fi
        
        do_install "${install_args[@]}"
        log_info "流处理终结。"
    else
        log_info "未检测到远程差分更新。"
    fi
}