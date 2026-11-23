#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "=========================================="
echo "🚀 开始打包 Dave macOS 安装包 (DMG)"
echo "=========================================="

APP_NAME="Dave.app"
BUILD_DIR="$DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME"
DMG_ROOT="$BUILD_DIR/dmg_root"
DMG_NAME="Dave.dmg"
FINAL_DMG="$BUILD_DIR/$DMG_NAME"
ROOT_DMG="$DIR/$DMG_NAME"

# 1. 编译 Universal 通用架构二进制 (arm64 + x86_64)
echo "🔨 1/5: 正在编译 Universal 通用二进制 (Apple Silicon + Intel)..."
swift build -c release --triple arm64-apple-macosx --scratch-path .build/arm64
swift build -c release --triple x86_64-apple-macosx --scratch-path .build/x86_64

ARM_BIN="$DIR/.build/arm64/out/Products/Release/Dave"
X86_BIN="$DIR/.build/x86_64/out/Products/Release/Dave"

# 2. 组装 Dave.app
echo "📦 2/5: 组装 App Bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# 使用 lipo 创建通用二进制
lipo -create "$ARM_BIN" "$X86_BIN" -output "$APP_DIR/Contents/MacOS/Dave"
chmod +x "$APP_DIR/Contents/MacOS/Dave"

# 验证架构
echo "   🔍 二进制架构验证:"
lipo -info "$APP_DIR/Contents/MacOS/Dave"

# 拷贝 Info.plist 和资源
cp "$DIR/scripts/Info.plist" "$APP_DIR/Contents/Info.plist"
cp -R "$DIR/Assets" "$APP_DIR/Contents/Resources/"
if [ -f "$DIR/Assets/AppIcon.icns" ]; then
    cp "$DIR/Assets/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

# 3. 对 App 进行本地自签名 (防止在其他电脑上报文件损坏)
echo "🔏 3/5: 执行本地代码签名..."
codesign --force --deep --sign - "$APP_DIR"

# 4. 准备 DMG 根目录
echo "📂 4/5: 准备 DMG 镜像内容..."
rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT"

# 拷贝 App
cp -R "$APP_DIR" "$DMG_ROOT/"

# 创建 Applications 软链接（实现经典的拖拽安装）
ln -s /Applications "$DMG_ROOT/Applications"

# 添加友好提示文档
cat << 'EOF' > "$DMG_ROOT/安装与使用说明.txt"
===========================================
  💻 Dave - 桌面工程师专属宠物伴侣
===========================================

【一键安装方法】
直接将「Dave」图标拖拽到旁边的「Applications」文件夹即可完成安装！

【打开方式】
1. 安装后在「访达」->「应用程序」或「启动台」中找到 Dave 并打开。
2. 如果 macOS 提示“无法打开，因为无法验证开发者”：
   - 方法一：按住 Control 键点击 Dave，在弹出菜单中点击「打开」，再点击「仍要打开」。
   - 方法二：在「系统设置」->「隐私与安全性」底部，点击「仍要打开」。
   - 方法三（终端极速解除）：在终端执行:
     xattr -cr /Applications/Dave.app

【功能说明】
- 桌面伴侣：右键宠物可以置顶、静音、设置工休喝水提醒或回到底部边缘。
- 顶部状态栏：点击状态栏纯白 Dave 图标可查看详细的 Token 消耗统计卡片及控制项。
===========================================
EOF

# 5. 生成只读压缩 DMG
echo "💿 5/5: 正在生成 DMG 安装文件..."
rm -f "$FINAL_DMG" "$ROOT_DMG"
hdiutil create -volname "Dave" -srcfolder "$DMG_ROOT" -ov -format UDZO "$FINAL_DMG"

# 拷贝一份到项目根目录，方便用户直接获取
cp "$FINAL_DMG" "$ROOT_DMG"

# 清理临时 staging 目录
rm -rf "$DMG_ROOT"

echo "=========================================="
echo "🎉 打包完成！"
echo "📦 DMG 文件生成于:"
echo "   1. $FINAL_DMG"
echo "   2. $ROOT_DMG"
echo "📏 文件大小: $(du -sh "$FINAL_DMG" | cut -f1)"
echo "=========================================="
