#!/bin/bash

do_uninstall() {
    local search_name="$1"

    if [ -z "$search_name" ]; then
        log_error "缺少应用名称参数。"
        exit 1
    fi

    local found=0

    # 检查全局域
    for file in "$GLOBAL_TARGET_DIR"/*; do
        if [[ "$(basename "$file")" == "$search_name".* ]]; then
            if [ "$EUID" -ne 0 ]; then
                log_error "检测到目标存在于全局域 (/opt)，拒绝操作。请提权执行 'sudo AppImage -uninstall $search_name'。"
                exit 1
            fi
            rm -f "$file"
            rm -f "$GLOBAL_DESKTOP_DIR/$search_name.desktop"
            rm -f "$GLOBAL_ICON_DIR/$search_name".*
            log_info "已执行全局清理。"
            found=1
            break
        fi
    done

    # 检查个人域
    if [ "$found" -eq 0 ]; then
        for file in "$LOCAL_TARGET_DIR"/*; do
            if [[ "$(basename "$file")" == "$search_name".* ]]; then
                rm -f "$file"
                rm -f "$LOCAL_DESKTOP_DIR/$search_name.desktop"
                rm -f "$LOCAL_ICON_DIR/$search_name".*
                log_info "已执行局部清理。"
                found=1
                break
            fi
        done
    fi

    if [ "$found" -eq 1 ]; then
        refresh_desktop_database
        log_info "实例 $search_name 卸载完成。"
    else
        log_error "系统内不存在目标实体: $search_name"
        exit 1
    fi
}