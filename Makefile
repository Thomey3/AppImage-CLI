# Makefile for AppImage-CLI
INSTALL_BIN_DIR = /usr/local/bin
LIB_DIR = /usr/local/lib/appimage
BIN_NAME = AppImage

.PHONY: all install uninstall test

all:
	@echo "执行 'sudo make install' 写入物理介质。"
	@echo "执行 'sudo make uninstall' 摧毁工程映射。"
	@echo "执行 'make test' 运行本地单元及静态测试。"

install:
	mkdir -p $(LIB_DIR)
	cp src/*.sh $(LIB_DIR)/
	cp src/main.sh $(INSTALL_BIN_DIR)/$(BIN_NAME)
	chmod +x $(INSTALL_BIN_DIR)/$(BIN_NAME)
	@echo "AppImage-CLI 部署确认完毕。"

uninstall:
	rm -f $(INSTALL_BIN_DIR)/$(BIN_NAME)
	rm -rf $(LIB_DIR)
	@echo "AppImage-CLI 系统回收完毕。"

test:
	@echo "正在赋予源码执行权限..."
	chmod +x src/*.sh
	@echo "正在运行 ShellCheck 静态分析..."
	shellcheck src/*.sh
	@echo "正在运行 BATS 单元测试..."
	bats tests/