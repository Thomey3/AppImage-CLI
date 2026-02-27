# Makefile
INSTALL_BIN_DIR = /usr/local/bin
LIB_DIR = /usr/local/lib/appimage
BIN_NAME = AppImage

all:
	@echo "执行 'sudo make install' 写入物理介质。"
	@echo "执行 'sudo make uninstall' 摧毁工程映射。"

install:
	mkdir -p $(LIB_DIR)
	cp src/*.sh $(LIB_DIR)/
	cp src/main.sh $(INSTALL_BIN_DIR)/$(BIN_NAME)
	chmod +x $(INSTALL_BIN_DIR)/$(BIN_NAME)
	@echo "部署确认完毕。"

uninstall:
	rm -f $(INSTALL_BIN_DIR)/$(BIN_NAME)
	rm -rf $(LIB_DIR)
	@echo "系统回收完毕。"