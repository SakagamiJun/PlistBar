#!/bin/bash

# 发生错误时立即退出
set -e

# 设置变量
APP_NAME="PlistBar"
APP_BUNDLE="${APP_NAME}.app"
BUILD_DIR="build"
OUTPUT_DIR="${BUILD_DIR}/${APP_BUNDLE}"

# 获取版本号：优先使用环境变量 VERSION，其次从 git tag 获取，最后默认为 1.0.0
RAW_VERSION="${VERSION:-$(git describe --tags --match "v*" --abbrev=0 2>/dev/null || echo "1.0.0")}"
APP_VERSION="${RAW_VERSION#v}"
[ -z "$APP_VERSION" ] && APP_VERSION="1.0.0"

# 获取构建编号：提交次数
BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo "1")

echo "🚀 开始构建 ${APP_NAME} v${APP_VERSION} (Build ${BUILD_NUMBER}) (Release)..."

# 执行 Swift 编译
swift build -c release

# 获取编译输出目录
BIN_PATH=$(swift build -c release --show-bin-path)

echo "📦 正在打包为 macOS App Bundle..."

# 创建 App Bundle 目录结构
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/Contents/MacOS"
mkdir -p "${OUTPUT_DIR}/Contents/Resources"

# 拷贝可执行文件
cp "${BIN_PATH}/${APP_NAME}" "${OUTPUT_DIR}/Contents/MacOS/"

# 写入版本标识文件
echo "${APP_VERSION}" > "${OUTPUT_DIR}/Contents/Resources/version.txt"

# 创建 Info.plist
# 添加 LSUIElement 键以确保应用不会在 Dock 栏出现
cat <<EOF > "${OUTPUT_DIR}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.sakagamijun.${APP_NAME}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>en</string>
        <string>zh-Hans</string>
    </array>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# 拷贝资源文件（包括多语言资源包）
if [ -d "${BIN_PATH}/${APP_NAME}_${APP_NAME}.bundle" ]; then
    cp -r "${BIN_PATH}/${APP_NAME}_${APP_NAME}.bundle" "${OUTPUT_DIR}/Contents/Resources/"
    cp -r "${BIN_PATH}/${APP_NAME}_${APP_NAME}.bundle/"*.lproj "${OUTPUT_DIR}/Contents/Resources/" 2>/dev/null || true
fi

echo "✅ 打包完成！应用程序位于: ${OUTPUT_DIR}"
echo "你可以通过命令打开它: open ${OUTPUT_DIR}"
