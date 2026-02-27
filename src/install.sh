#!/bin/bash

do_install() {
    local appimage_source="$1"
    shift
    local custom_name="" use_sandbox=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --sandbox) use_sandbox=1; shift ;;
            *) [ -z "$custom_name" ] && custom_name="$1"; shift ;;
        esac
    done

    [ ! -f "$appimage_source" ] && { log_error "文件不存在: $appimage_source"; exit 1; }

    local original_filename app_name extension
    original_filename=$(basename "$appimage_source")
    extension="${original_filename##*.}"
    app_name="${custom_name:-${original_filename%.*}}"

    local target_path="$TARGET_DIR/$app_name.$extension"
    local desktop_file="$DESKTOP_DIR/$app_name.desktop"

    log_info "正在配置: $app_name..."
    [ "$appimage_source" != "$target_path" ] && mv "$appimage_source" "$target_path"
    chmod +x "$target_path"

    local final_icon="application-x-executable"
    local temp_dir
    temp_dir=$(mktemp -d)

    (
        cd "$temp_dir" || exit 1
        "$target_path" --appimage-extract > /dev/null 2>&1
        local icon_source
        if [ -e "squashfs-root/.DirIcon" ]; then
            icon_source="squashfs-root/.DirIcon"
        else
            icon_source=$(find squashfs-root -maxdepth 1 -type f \( -name "*.png" -o -name "*.svg" \) | head -n 1)
        fi
        
        if [ -n "$icon_source" ] && [ -e "$icon_source" ]; then
            local ext=".png"
            file -b --mime-type "$icon_source" | grep -qi "svg" && ext=".svg"
            cp -L "$icon_source" "$ICON_DIR/${app_name}${ext}"
            echo "$ICON_DIR/${app_name}${ext}" > "$temp_dir/extracted_icon_path"
        fi
    )

    [ -f "$temp_dir/extracted_icon_path" ] && final_icon=$(cat "$temp_dir/extracted_icon_path")
    rm -rf "$temp_dir"

    local exec_cmd="\"$target_path\""
    if [ "$use_sandbox" -eq 1 ] && command -v firejail >/dev/null 2>&1; then
        exec_cmd="firejail --appimage \"$target_path\""
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
}