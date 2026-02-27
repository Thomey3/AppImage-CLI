#!/bin/bash

do_install() {
    local appimage_source="$1"
    shift

    local custom_name=""
    local use_sandbox=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --sandbox)
                use_sandbox=1
                shift
                ;;
            *)
                if [ -z "$custom_name" ]; then
                    custom_name="$1"
                fi
                shift
                ;;
        esac
    done

    if [ -z "$appimage_source" ]; then
        log_error "未提供 AppImage 文件路径。"
        exit 1
    fi

    if [ ! -f "$appimage_source" ]; then
        log_error "文件不存在: $appimage_source"
        exit 1
    fi

    local original_filename=$(basename "$appimage_source")
    local extension="${original_filename##*.}"
    local app_name

    if [ -n "$custom_name" ]; then
        app_name="$custom_name"
    else
        app_name="${original_filename%.*}"
    fi

    local target_path="$TARGET_DIR/$app_name.$extension"
    local desktop_file="$DESKTOP_DIR/$app_name.desktop"

    log_info "正在配置: $app_name..."

    if [ "$appimage_source" != "$target_path" ]; then
        mv "$appimage_source" "$target_path"
    fi
    chmod +x "$target_path"

    local final_icon="application-x-executable"
    local temp_dir=$(mktemp -d)

    log_info "正在提取应用原生图标..."
    (
        cd "$temp_dir" || exit 1
        "$target_path" --appimage-extract > /dev/null 2>&1
        
        local icon_source=""
        if [ -e "squashfs-root/.DirIcon" ]; then
            icon_source="squashfs-root/.DirIcon"
        else
            icon_source=$(find squashfs-root -maxdepth 1 -type f \( -name "*.png" -o -name "*.svg" \) | head -n 1)
        fi
        
        if [ -n "$icon_source" ] && [ -e "$icon_source" ]; then
            local ext=".png"
            if file -b --mime-type "$icon_source" | grep -qi "svg"; then
                ext=".svg"
            fi
            
            local icon_target="$ICON_DIR/${app_name}${ext}"
            cp -L "$icon_source" "$icon_target"
            echo "$icon_target" > "$temp_dir/extracted_icon_path"
        fi
    )

    if [ -f "$temp_dir/extracted_icon_path" ]; then
        final_icon=$(cat "$temp_dir/extracted_icon_path")
    fi
    rm -rf "$temp_dir"

    local exec_cmd="\"$target_path\""
    if [ "$use_sandbox" -eq 1 ]; then
        if command -v firejail >/dev/null 2>&1; then
            exec_cmd="firejail --appimage \"$target_path\""
            log_info "已启用 firejail 沙盒隔离机制。"
        else
            log_error "未检测到 firejail，降级为标准执行模式。"
        fi
    fi

    cat <<EOF > "$desktop_file"
[Desktop Entry]
Type=Application
Name=$app_name
Exec=$exec_cmd
Icon=$final_icon
Terminal=false
Categories=Utility;
EOF

    refresh_desktop_database
    log_info "配置成功: $target_path"
}