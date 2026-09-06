SHELL := /bin/bash

.PHONY: all build dist test run clean help

all: build

help:
	@echo "PlistBar Makefile"
	@echo "  make build   - 构建 macOS App Bundle (build/PlistBar.app)"
	@echo "  make dist    - 构建 App Bundle 并打包为 ZIP 发布文件 (build/PlistBar.zip)"
	@echo "  make test    - 运行测试套件"
	@echo "  make run     - 构建并启动 PlistBar.app"
	@echo "  make clean   - 清理构建产物"

build:
	@chmod +x ./build.sh
	@./build.sh

dist: build
	@echo "📦 打包 PlistBar.zip..."
	@ditto -c -k --sequesterRsrc --keepParent build/PlistBar.app build/PlistBar.zip
	@shasum -a 256 build/PlistBar.zip
	@echo "✅ 发布包已生成: build/PlistBar.zip"

test:
	@swift test

run: build
	@echo "🚀 启动 PlistBar.app..."
	@open build/PlistBar.app

clean:
	@echo "🧹 清理构建产物..."
	@rm -rf build .build
	@echo "✅ 清理完成"
