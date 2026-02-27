#!/bin/bash

do_clean_dir() {
    local t_dir="$1" d_dir="$2" i_dir="$3"
    [ -d "$d_dir" ] || return

    for desktop in "$d_dir"/*.desktop; do
        [ -f "$desktop" ] || continue
        local exec_path
        exec_path=$(grep "^Exec=" "$desktop" | cut -d'=' -f2- | tr -d '"' | sed 's/firejail --appimage //g' | xargs)
        if [ -n "$exec_path" ] && [ ! -f "$exec_path" ]; then
            rm -f "$desktop"
            ((cleaned_count++))
        fi
    done

    for icon in "$i_dir"/*; do
        [ -f "$icon" ] || continue
        local icon_name app_name has_target=0
        icon_name=$(basename "$icon")
        app_name="${icon_name%.*}"
        for target in "$t_dir"/*; do
            [[ "$(basename "$target")" == "$app_name".* ]] && { has_target=1; break; }
        done
        [ "$has_target" -eq 0 ] && { rm -f "$icon"; ((cleaned_count++)); }
    done
}

do_clean() {
    local cleaned_count=0
    log_info "正在清理无效的快捷方式和图标..."
    
    # 动态探测权限以执行全局清理
    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        do_clean_dir "$GLOBAL_TARGET_DIR" "$GLOBAL_DESKTOP_DIR" "$GLOBAL_ICON_DIR"
    fi
    
    do_clean_dir "$LOCAL_TARGET_DIR" "$LOCAL_DESKTOP_DIR" "$LOCAL_ICON_DIR"
    
    if [ "$cleaned_count" -gt 0 ]; then
        refresh_desktop_database
        log_info "清理完成，共移除 $cleaned_count 个无用映射。"
    else
        log_info "环境干净，无需清理。"
    fi
}