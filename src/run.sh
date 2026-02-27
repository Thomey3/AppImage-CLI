#!/bin/bash

do_run() {
    local search_name="$1"

    if [ -z "$search_name" ]; then
        log_error "未提供需要运行的应用名称。"
        exit 1
    fi

    local target_path=""
    local desktop_file=""

    # 优先检索个人域
    for file in "$LOCAL_TARGET_DIR"/*; do
        if [[ "$(basename "$file")" == "$search_name".* ]]; then
            target_path="$file"
            desktop_file="$LOCAL_DESKTOP_DIR/$search_name.desktop"
            break
        fi
    done

    # 其次检索全局域
    if [ -z "$target_path" ]; then
        for file in "$GLOBAL_TARGET_DIR"/*; do
            if [[ "$(basename "$file")" == "$search_name".* ]]; then
                target_path="$file"
                desktop_file="$GLOBAL_DESKTOP_DIR/$search_name.desktop"
                break
            fi
        done
    fi

    if [ -z "$target_path" ]; then
        log_error "未在任何作用域内找到应用: $search_name"
        exit 1
    fi

    local exec_cmd="\"$target_path\""
    if [ -f "$desktop_file" ] && grep -q "firejail" "$desktop_file"; then
        exec_cmd="firejail --appimage \"$target_path\""
    fi

    log_info "触发执行管道: $search_name"
    eval "nohup $exec_cmd >/dev/null 2>&1 &"
}