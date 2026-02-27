#!/bin/bash

do_list() {
    log_info "系统映射 AppImage 列表:"
    printf "%-30s | %-15s | %-50s\n" "应用名称" "作用域" "物理执行路径"
    echo "--------------------------------------------------------------------------------------------------"
    
    local count=0

    # 扫描全局域
    for file in "$GLOBAL_TARGET_DIR"/*; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            local app_name="${filename%.*}"
            printf "%-30s | %-15s | %-50s\n" "$app_name" "Global (全局)" "$file"
            ((count++))
        fi
    done

    # 扫描个人域
    for file in "$LOCAL_TARGET_DIR"/*; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            local app_name="${filename%.*}"
            printf "%-30s | %-15s | %-50s\n" "$app_name" "Local  (个人)" "$file"
            ((count++))
        fi
    done

    if [ "$count" -eq 0 ]; then
        echo "(空)"
    fi
    echo "--------------------------------------------------------------------------------------------------"
    log_info "系统共计收录 $count 个实例。"
}