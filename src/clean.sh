#!/bin/bash

# 定义原子化清扫逻辑
do_clean_dir() {
    local t_dir="$1"
    local d_dir="$2"
    local i_dir="$3"
    
    [ -d "$d_dir" ] || return
    [ -d "$i_dir" ] || return

    for desktop in "$d_dir"/*.desktop; do
        [ -f "$desktop" ] || continue
        
        local exec_path=$(grep "^Exec=" "$desktop" | cut -d'=' -f2- | tr -d '"' | sed 's/firejail --appimage //g' | xargs)
        
        if [ -n "$exec_path" ] && [ ! -f "$exec_path" ]; then
            rm -f "$desktop"
            log_info "移除死链项: $(basename "$desktop")"
            ((cleaned_count++))
        fi
    done

    for icon in "$i_dir"/*; do
        [ -f "$icon" ] || continue
        
        local icon_name=$(basename "$icon")
        local app_name="${icon_name%.*}"
        
        local has_target=0
        for target in "$t_dir"/*; do
            if [[ "$(basename "$target")" == "$app_name".* ]]; then
                has_target=1
                break
            fi
        done

        if [ "$has_target" -eq 0 ]; then
            rm -f "$icon"
            log_info "回收孤立资源: $icon_name"
            ((cleaned_count++))
        fi
    done
}

do_clean() {
    log_info "执行系统拓扑完整性扫描..."
    cleaned_count=0

    # 清理个人域
    do_clean_dir "$LOCAL_TARGET_DIR" "$LOCAL_DESKTOP_DIR" "$LOCAL_ICON_DIR"

    # 有提权时连带清理全局域
    if [ "$EUID" -eq 0 ]; then
        do_clean_dir "$GLOBAL_TARGET_DIR" "$GLOBAL_DESKTOP_DIR" "$GLOBAL_ICON_DIR"
    fi

    if [ "$cleaned_count" -gt 0 ]; then
        refresh_desktop_database
        log_info "GC 回收结束，清理 $cleaned_count 个非法映射。"
    else
        log_info "环境拓扑验证通过，无异常映射。"
    fi
}