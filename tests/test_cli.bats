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

    # 构建更新工具 Mock
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

    # 创建基础 Mock AppImage
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

# ==================== 帮助命令测试 ====================

@test "帮助命令 (-help) 应显示完整帮助信息" {
    run src/main.sh -help
    [ "$status" -eq 0 ]
    [[ "$output" == *"用法:"* ]]
    [[ "$output" == *"-install"* ]]
    [[ "$output" == *"-uninstall"* ]]
    [[ "$output" == *"-update"* ]]
    [[ "$output" == *"-list"* ]]
    [[ "$output" == *"-clean"* ]]
    [[ "$output" == *"-run"* ]]
    [[ "$output" == *"-help"* ]]
}

@test "帮助命令 (--help) 应显示完整帮助信息" {
    run src/main.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"用法:"* ]]
}

@test "帮助命令 (help) 应显示完整帮助信息" {
    run src/main.sh help
    [ "$status" -eq 0 ]
    [[ "$output" == *"用法:"* ]]
}

# ==================== 错误处理测试 ====================

@test "无参数执行应当返回用法说明及非零状态码" {
    run src/main.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"用法: AppImage"* ]]
}

@test "无效参数执行应当返回用法说明及非零状态码" {
    run src/main.sh -invalid
    [ "$status" -eq 1 ]
    [[ "$output" == *"用法: AppImage"* ]]
}

@test "安装不存在的文件应返回错误" {
    run src/main.sh -install "$TEST_TEMP_DIR/non_existent.AppImage"
    [ "$status" -ne 0 ]
    [[ "$output" == *"文件不存在"* ]]
}

@test "卸载时不指定应用名称应返回错误" {
    run src/main.sh -uninstall
    [ "$status" -ne 0 ]
    [[ "$output" == *"缺少应用名称"* ]]
}

@test "卸载不存在的应用应返回错误" {
    run src/main.sh -uninstall "NonExistentApp"
    [ "$status" -eq 1 ]
    [[ "$output" == *"不存在"* ]]
}

@test "更新时不指定应用名称应返回错误" {
    run src/main.sh -update
    [ "$status" -ne 0 ]
    [[ "$output" == *"缺少应用名称"* ]]
}

@test "更新不存在的应用应返回错误" {
    run src/main.sh -update "NonExistentApp"
    [ "$status" -ne 0 ]
    [[ "$output" == *"未找到应用"* ]]
}

@test "运行时不指定应用名称应返回错误" {
    run src/main.sh -run
    [ "$status" -ne 0 ]
    [[ "$output" == *"未提供需要运行的应用名称"* ]]
}

@test "运行不存在的应用应返回错误" {
    run src/main.sh -run "NonExistentApp"
    [ "$status" -ne 0 ]
    [[ "$output" == *"未在任何作用域内找到"* ]]
}

# ==================== 安装命令测试 ====================

@test "安装命令 (-install) 应正确移动文件并生成桌面快捷方式和图标" {
    run src/main.sh -install "$DUMMY_APPIMAGE"
    [ "$status" -eq 0 ]

    [ ! -f "$DUMMY_APPIMAGE" ]
    [ -f "$LOCAL_TARGET_DIR/DummyApp.AppImage" ]

    [ -f "$LOCAL_DESKTOP_DIR/DummyApp.desktop" ]
    run cat "$LOCAL_DESKTOP_DIR/DummyApp.desktop"
    [[ "$output" == *"Name=DummyApp"* ]]
    [[ "$output" == *"Exec="* ]]

    [ -f "$LOCAL_ICON_DIR/DummyApp.png" ]
}

@test "安装命令应支持自定义名称" {
    run src/main.sh -install "$DUMMY_APPIMAGE" "MyCustomApp"
    [ "$status" -eq 0 ]

    [ -f "$LOCAL_TARGET_DIR/MyCustomApp.AppImage" ]
    [ -f "$LOCAL_DESKTOP_DIR/MyCustomApp.desktop" ]
    [ -f "$LOCAL_ICON_DIR/MyCustomApp.png" ]

    run cat "$LOCAL_DESKTOP_DIR/MyCustomApp.desktop"
    [[ "$output" == *"Name=MyCustomApp"* ]]
}

@test "安装命令应支持 --sandbox 选项" {
    # 创建firejail mock
    echo '#!/bin/bash' > "$TEST_TEMP_DIR/bin/firejail"
    echo 'shift; exec "$@"' >> "$TEST_TEMP_DIR/bin/firejail"
    chmod +x "$TEST_TEMP_DIR/bin/firejail"

    run src/main.sh -install "$DUMMY_APPIMAGE" "SandboxApp" --sandbox
    [ "$status" -eq 0 ]

    [ -f "$LOCAL_TARGET_DIR/SandboxApp.AppImage" ]
    [ -f "$LOCAL_DESKTOP_DIR/SandboxApp.desktop" ]

    run cat "$LOCAL_DESKTOP_DIR/SandboxApp.desktop"
    [[ "$output" == *"Exec=firejail"* ]]
}

# ==================== 卸载命令测试 ====================

@test "卸载命令 (-uninstall) 应清理目标实体、快捷方式和图标" {
    src/main.sh -install "$DUMMY_APPIMAGE"

    run src/main.sh -uninstall "DummyApp"
    [ "$status" -eq 0 ]

    [ ! -f "$LOCAL_TARGET_DIR/DummyApp.AppImage" ]
    [ ! -f "$LOCAL_DESKTOP_DIR/DummyApp.desktop" ]
    [ ! -f "$LOCAL_ICON_DIR/DummyApp.png" ]
}

@test "卸载自定义名称的应用应正确清理" {
    src/main.sh -install "$DUMMY_APPIMAGE" "CustomName"

    run src/main.sh -uninstall "CustomName"
    [ "$status" -eq 0 ]

    [ ! -f "$LOCAL_TARGET_DIR/CustomName.AppImage" ]
    [ ! -f "$LOCAL_DESKTOP_DIR/CustomName.desktop" ]
    [ ! -f "$LOCAL_ICON_DIR/CustomName.png" ]
}

# ==================== 列表命令测试 ====================

@test "列表命令 (-list) 在空系统下应输出 '(空)'" {
    run src/main.sh -list
    [ "$status" -eq 0 ]
    [[ "$output" == *"(空)"* ]]
}

@test "列表命令应在有应用时显示应用列表" {
    src/main.sh -install "$DUMMY_APPIMAGE"

    run src/main.sh -list
    [ "$status" -eq 0 ]
    [[ "$output" == *"DummyApp"* ]]
    [[ "$output" == *"Local"* ]]
}

@test "列表命令应同时显示全局和本地应用" {
    # 创建全局目录的mock环境
    mkdir -p "$GLOBAL_TARGET_DIR"
    touch "$GLOBAL_TARGET_DIR/GlobalApp.AppImage"

    src/main.sh -install "$DUMMY_APPIMAGE"

    run src/main.sh -list
    [ "$status" -eq 0 ]
    [[ "$output" == *"GlobalApp"* ]]
    [[ "$output" == *"DummyApp"* ]]
    [[ "$output" == *"Global"* ]]
    [[ "$output" == *"Local"* ]]
}

# ==================== 清理命令测试 ====================

@test "清理命令 (-clean) 应能识别并删除无效的桌面快捷方式和孤立图标" {
    touch "$LOCAL_DESKTOP_DIR/OrphanedApp.desktop"
    echo "Exec=\"$LOCAL_TARGET_DIR/OrphanedApp.AppImage\"" > "$LOCAL_DESKTOP_DIR/OrphanedApp.desktop"
    touch "$LOCAL_ICON_DIR/OrphanedApp.png"

    run src/main.sh -clean
    [ "$status" -eq 0 ]

    [ ! -f "$LOCAL_DESKTOP_DIR/OrphanedApp.desktop" ]
    [ ! -f "$LOCAL_ICON_DIR/OrphanedApp.png" ]
}

@test "清理命令应在无垃圾时输出干净信息" {
    run src/main.sh -clean
    [ "$status" -eq 0 ]
    [[ "$output" == *"环境干净"* ]] || [[ "$output" == *"无需清理"* ]]
}

@test "清理命令应保留有效的快捷方式和图标" {
    src/main.sh -install "$DUMMY_APPIMAGE"

    # 创建孤立的快捷方式和图标（使用正确的desktop文件格式）
    cat > "$LOCAL_DESKTOP_DIR/OrphanedApp.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=OrphanedApp
Exec=/nonexistent/path/OrphanedApp.AppImage
Icon=OrphanedApp
Terminal=false
EOF
    touch "$LOCAL_ICON_DIR/OrphanedApp.png"

    run src/main.sh -clean
    [ "$status" -eq 0 ]

    # 有效的应该保留
    [ -f "$LOCAL_DESKTOP_DIR/DummyApp.desktop" ]
    [ -f "$LOCAL_ICON_DIR/DummyApp.png" ]
    # 孤立的应该删除
    [ ! -f "$LOCAL_DESKTOP_DIR/OrphanedApp.desktop" ]
    [ ! -f "$LOCAL_ICON_DIR/OrphanedApp.png" ]
}

# ==================== 更新命令测试 ====================

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

@test "更新自定义名称的应用应正常工作" {
    src/main.sh -install "$DUMMY_APPIMAGE" "CustomUpdateApp"

    mkdir -p "$REAL_HOME/.local/bin"
    cp "$TEST_TEMP_DIR/bin/appimageupdatetool" "$REAL_HOME/.local/bin/"

    run src/main.sh -update "CustomUpdateApp"
    [ "$status" -eq 0 ]

    [ -f "$LOCAL_TARGET_DIR/CustomUpdateApp.AppImage" ]
}

# ==================== 运行命令测试 ====================

@test "运行命令 (-run) 应能正确解析路径并在后台触发目标文件" {
    src/main.sh -install "$DUMMY_APPIMAGE"

    run src/main.sh -run "DummyApp"
    [ "$status" -eq 0 ]
    [[ "$output" == *"触发执行管道: DummyApp"* ]]
}

@test "运行自定义名称的应用应正常工作" {
    src/main.sh -install "$DUMMY_APPIMAGE" "CustomRunApp"

    run src/main.sh -run "CustomRunApp"
    [ "$status" -eq 0 ]
    [[ "$output" == *"触发执行管道: CustomRunApp"* ]]
}

# ==================== 边界情况测试 ====================

@test "安装时应保留原始文件扩展名" {
    export DUMMY_APPIMAGE2="$TEST_TEMP_DIR/TestApp2.APPIMAGE"
    cat << 'EOF' > "$DUMMY_APPIMAGE2"
#!/bin/bash
if [ "$1" == "--appimage-extract" ]; then
    mkdir -p squashfs-root
    touch squashfs-root/.DirIcon
    exit 0
fi
EOF
    chmod +x "$DUMMY_APPIMAGE2"

    run src/main.sh -install "$DUMMY_APPIMAGE2"
    [ "$status" -eq 0 ]

    # 应该保留大写扩展名
    [ -f "$LOCAL_TARGET_DIR/TestApp2.APPIMAGE" ]
}

@test "多次安装同一应用应覆盖" {
    src/main.sh -install "$DUMMY_APPIMAGE"

    # 再次安装相同名称
    export DUMMY_APPIMAGE3="$TEST_TEMP_DIR/DummyApp2.AppImage"
    cat << 'EOF' > "$DUMMY_APPIMAGE3"
#!/bin/bash
if [ "$1" == "--appimage-extract" ]; then
    mkdir -p squashfs-root
    touch squashfs-root/.DirIcon
    exit 0
fi
EOF
    chmod +x "$DUMMY_APPIMAGE3"

    run src/main.sh -install "$DUMMY_APPIMAGE3" "DummyApp"
    [ "$status" -eq 0 ]

    # 桌面文件应该更新
    [ -f "$LOCAL_DESKTOP_DIR/DummyApp.desktop" ]
}

@test "卸载后桌面数据库应刷新" {
    src/main.sh -install "$DUMMY_APPIMAGE"

    run src/main.sh -uninstall "DummyApp"
    [ "$status" -eq 0 ]
    # 刷新桌面数据库不会产生特定输出，所以检查命令成功执行即可
}
