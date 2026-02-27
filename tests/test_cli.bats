#!/usr/bin/env bats

setup() {
    export TEST_TEMP_DIR="$(mktemp -d)"
    export APPIMAGE_LIB_DIR="$PWD/src"
    export REAL_HOME="$TEST_TEMP_DIR/home"
    
    export GLOBAL_TARGET_DIR="$TEST_TEMP_DIR/opt/AppImages"
    export GLOBAL_DESKTOP_DIR="$TEST_TEMP_DIR/usr/share/applications"
    export GLOBAL_ICON_DIR="$TEST_TEMP_DIR/opt/AppImages/icons"
    export LOCAL_TARGET_DIR="$REAL_HOME/Applications"
    export LOCAL_DESKTOP_DIR="$REAL_HOME/.local/share/applications"
    export LOCAL_ICON_DIR="$REAL_HOME/Applications/icons"

    mkdir -p "$GLOBAL_TARGET_DIR" "$GLOBAL_DESKTOP_DIR" "$GLOBAL_ICON_DIR"
    mkdir -p "$LOCAL_TARGET_DIR" "$LOCAL_DESKTOP_DIR" "$LOCAL_ICON_DIR"

    export PATH="$TEST_TEMP_DIR/bin:$PATH"
    mkdir -p "$TEST_TEMP_DIR/bin"
    
    echo '#!/bin/bash' > "$TEST_TEMP_DIR/bin/update-desktop-database"
    chmod +x "$TEST_TEMP_DIR/bin/update-desktop-database"

    # 使用显式逐行追加构建更新工具 Mock，彻底切断变量转义风险
    echo '#!/bin/bash' > "$TEST_TEMP_DIR/bin/appimageupdatetool"
    echo 'if [ "$1" == "--remove-old" ]; then' >> "$TEST_TEMP_DIR/bin/appimageupdatetool"
    echo '    rm -f "$2"' >> "$TEST_TEMP_DIR/bin/appimageupdatetool"
    echo '    NEW_FILE="${2%.AppImage}-v2.AppImage"' >> "$TEST_TEMP_DIR/bin/appimageupdatetool"
    echo '    echo "#!/bin/bash" > "$NEW_FILE"' >> "$TEST_TEMP_DIR/bin/appimageupdatetool"
    echo '    echo "if [ \"\$1\" == \"--appimage-extract\" ]; then" >> "$NEW_FILE"' >> "$TEST_TEMP_DIR/bin/appimageupdatetool"
    echo '    echo "    mkdir -p squashfs-root; touch squashfs-root/.DirIcon; exit 0" >> "$NEW_FILE"' >> "$TEST_TEMP_DIR/bin/appimageupdatetool"
    echo '    echo "fi" >> "$NEW_FILE"' >> "$TEST_TEMP_DIR/bin/appimageupdatetool"
    echo '    echo "echo UPDATED_SUCCESSFULLY" >> "$NEW_FILE"' >> "$TEST_TEMP_DIR/bin/appimageupdatetool"
    echo '    chmod +x "$NEW_FILE"' >> "$TEST_TEMP_DIR/bin/appimageupdatetool"
    echo '    exit 0' >> "$TEST_TEMP_DIR/bin/appimageupdatetool"
    echo 'fi' >> "$TEST_TEMP_DIR/bin/appimageupdatetool"
    chmod +x "$TEST_TEMP_DIR/bin/appimageupdatetool"

    export DUMMY_APPIMAGE="$TEST_TEMP_DIR/DummyApp.AppImage"
    cat << 'EOF' > "$DUMMY_APPIMAGE"
#!/bin/bash
if [ "$1" == "--appimage-extract" ]; then
    mkdir -p squashfs-root
    touch squashfs-root/.DirIcon
    exit 0
fi
EOF
    chmod +x "$DUMMY_APPIMAGE"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

@test "无参数执行应当返回用法说明及非零状态码" {
    run src/main.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"用法: AppImage -install"* ]]
}

@test "无效参数执行应当返回用法说明及非零状态码" {
    run src/main.sh -invalid
    [ "$status" -eq 1 ]
    [[ "$output" == *"用法: AppImage -install"* ]]
}

@test "列表命令 (-list) 在空系统下应输出 '(空)'" {
    run src/main.sh -list
    [ "$status" -eq 0 ]
    [[ "$output" == *"(空)"* ]]
}

@test "安装命令 (-install) 应正确移动文件并生成桌面快捷方式和图标" {
    run src/main.sh -install "$DUMMY_APPIMAGE"
    [ "$status" -eq 0 ]
    
    [ ! -f "$DUMMY_APPIMAGE" ]
    [ -f "$LOCAL_TARGET_DIR/DummyApp.AppImage" ]
    
    [ -f "$LOCAL_DESKTOP_DIR/DummyApp.desktop" ]
    run cat "$LOCAL_DESKTOP_DIR/DummyApp.desktop"
    [[ "$output" == *"Name=DummyApp"* ]]
    [[ "$output" == *"Exec=\"$LOCAL_TARGET_DIR/DummyApp.AppImage\""* ]]
    
    [ -f "$LOCAL_ICON_DIR/DummyApp.png" ]
}

@test "卸载命令 (-uninstall) 应清理目标实体、快捷方式和图标" {
    src/main.sh -install "$DUMMY_APPIMAGE"
    
    run src/main.sh -uninstall "DummyApp"
    [ "$status" -eq 0 ]
    
    [ ! -f "$LOCAL_TARGET_DIR/DummyApp.AppImage" ]
    [ ! -f "$LOCAL_DESKTOP_DIR/DummyApp.desktop" ]
    [ ! -f "$LOCAL_ICON_DIR/DummyApp.png" ]
}

@test "清理命令 (-clean) 应能识别并删除无效的桌面快捷方式和孤立图标" {
    touch "$LOCAL_DESKTOP_DIR/OrphanedApp.desktop"
    echo "Exec=\"$LOCAL_TARGET_DIR/OrphanedApp.AppImage\"" > "$LOCAL_DESKTOP_DIR/OrphanedApp.desktop"
    touch "$LOCAL_ICON_DIR/OrphanedApp.png"
    
    run src/main.sh -clean
    [ "$status" -eq 0 ]
    
    [ ! -f "$LOCAL_DESKTOP_DIR/OrphanedApp.desktop" ]
    [ ! -f "$LOCAL_ICON_DIR/OrphanedApp.png" ]
}

@test "更新命令 (-update) 应调用更新工具并完成增量接管" {
    src/main.sh -install "$DUMMY_APPIMAGE"
    
    mkdir -p "$REAL_HOME/.local/bin"
    cp "$TEST_TEMP_DIR/bin/appimageupdatetool" "$REAL_HOME/.local/bin/"
    
    run src/main.sh -update "DummyApp"
    [ "$status" -eq 0 ]
    
    [ -f "$LOCAL_TARGET_DIR/DummyApp.AppImage" ]
    run cat "$LOCAL_TARGET_DIR/DummyApp.AppImage"
    [[ "$output" == *"UPDATED_SUCCESSFULLY"* ]]
}

@test "运行命令 (-run) 应能正确解析路径并在后台触发目标文件" {
    src/main.sh -install "$DUMMY_APPIMAGE"
    
    run src/main.sh -run "DummyApp"
    [ "$status" -eq 0 ]
    [[ "$output" == *"触发执行管道: DummyApp"* ]]
}