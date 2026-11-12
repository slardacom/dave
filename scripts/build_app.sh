#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "🔨 Building Dave (Release)..."
swift build -c release

APP_NAME="Dave.app"
APP_DIR="$DIR/build/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Creating app bundle: $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
BIN_PATH="$(swift build -c release --show-bin-path)/Dave"
cp "$BIN_PATH" "$MACOS_DIR/Dave"
chmod +x "$MACOS_DIR/Dave"

# Copy Info.plist
cp scripts/Info.plist "$CONTENTS_DIR/Info.plist"

# Copy Assets
cp -R Assets "$RESOURCES_DIR/"
if [ -f Assets/AppIcon.icns ]; then
    cp Assets/AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
fi

echo "✅ Successfully built $APP_DIR"
echo "🚀 You can launch Dave with: open '$APP_DIR'"
