#!/bin/bash

# ============================================
# Universal macOS App Builder for Person Game
# ============================================

# ===== CONFIGURATION =====
# These can be overridden by setting environment variables
APP_NAME="${APP_NAME:-Person}"
BUNDLE_ID="${BUNDLE_ID:-com.iy-home.person}"
COPYRIGHT_HOLDER="${COPYRIGHT_HOLDER:-IY-Home}"
COPYRIGHT_YEAR="${COPYRIGHT_YEAR:-2026}"
VERSION="${VERSION:-4.1}"

# Icon settings
ICON_PNG="${ICON_PNG:-icon.png}"  # Name of the PNG file in data/app/
ICON_SIZE=512  # Size to resize PNG to before conversion
# ===== END CONFIGURATION =====

# Determine base directory from script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "📁 Script directory: $SCRIPT_DIR"

# Navigate up to find base directory (should be 2 levels up from macOS_app_builder)
# Current: [base_dir]/Application/macOS_app_builder
BASE_DIR="$( cd "$SCRIPT_DIR/../.." && pwd )"
echo "📁 Base directory: $BASE_DIR"

# Set source directory
SOURCE_DIR="$BASE_DIR/Source"
echo "📁 Source directory: $SOURCE_DIR"

# Verify source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Source directory not found at: $SOURCE_DIR"
    echo "   Please ensure your folder structure is:"
    echo "   [base_dir]/"
    echo "   ├── Application/"
    echo "   │   └── macOS_app_builder/"
    echo "   │       └── $(basename "$0")"
    echo "   │   └── icons/"
    echo "   └── Source/"
    exit 1
fi

# Set paths relative to source directory
ICON_PNG_PATH="$BASE_DIR/Application/icons/$ICON_PNG"
INTEL_APP="$SOURCE_DIR/macos-x86_64/Source.app"
ARM_APP="$SOURCE_DIR/macos-aarch64/Source.app"
OUTPUT_APP="$BASE_DIR/Application/macOS_app_builder/$APP_NAME.app"
ICON_OUTPUT_DIR="$BASE_DIR/Application/icons/generated"

echo ""
echo "🔨 Building Universal $APP_NAME.app..."
echo "📋 Configuration:"
echo "   - App Name: $APP_NAME"
echo "   - Bundle ID: $BUNDLE_ID"
echo "   - Version: $VERSION"
echo "   - Icon PNG: $ICON_PNG_PATH"
echo ""

# Step 1: Clean up any previous build
echo "🧹 Cleaning previous build..."
rm -rf "$OUTPUT_APP"
rm -rf "$ICON_OUTPUT_DIR"

# Step 2: Create icon if PNG exists
echo "🎨 Processing application icon..."
mkdir -p "$ICON_OUTPUT_DIR"

if [ -f "$ICON_PNG_PATH" ]; then
    echo "   Found PNG icon at: $ICON_PNG_PATH"
    
    # Create iconset directory
    ICONSET_DIR="$ICON_OUTPUT_DIR/$APP_NAME.iconset"
    mkdir -p "$ICONSET_DIR"
    
    # Generate all required icon sizes
    echo "   Generating icon sizes..."
    
    # Regular icons
    sips -z 16 16     "$ICON_PNG_PATH" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null 2>&1
    sips -z 32 32     "$ICON_PNG_PATH" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null 2>&1
    sips -z 32 32     "$ICON_PNG_PATH" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null 2>&1
    sips -z 64 64     "$ICON_PNG_PATH" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null 2>&1
    sips -z 128 128   "$ICON_PNG_PATH" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null 2>&1
    sips -z 256 256   "$ICON_PNG_PATH" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null 2>&1
    sips -z 256 256   "$ICON_PNG_PATH" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null 2>&1
    sips -z 512 512   "$ICON_PNG_PATH" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null 2>&1
    sips -z 512 512   "$ICON_PNG_PATH" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null 2>&1
    sips -z 1024 1024 "$ICON_PNG_PATH" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null 2>&1
    
    # Convert iconset to icns
    echo "   Converting to ICNS format..."
    iconutil -c icns "$ICONSET_DIR" -o "$ICON_OUTPUT_DIR/$APP_NAME.icns"
    
    if [ $? -eq 0 ] && [ -f "$ICON_OUTPUT_DIR/$APP_NAME.icns" ]; then
        ICON_SOURCE="$ICON_OUTPUT_DIR/$APP_NAME.icns"
        echo "   ✅ ICNS created at: $ICON_SOURCE"
    else
        echo "   ⚠️  ICNS creation failed, will skip icon"
        ICON_SOURCE=""
    fi
else
    echo "   ⚠️  PNG icon not found at: $ICON_PNG_PATH"
    echo "   Will proceed without custom icon"
    ICON_SOURCE=""
fi

# Step 3: Verify the app bundles exist
echo ""
echo "🔍 Verifying source app bundles..."

if [ ! -d "$INTEL_APP" ]; then
    echo "❌ Intel app not found at: $INTEL_APP"
    exit 1
fi
echo "   ✅ Intel app: $INTEL_APP"

if [ ! -d "$ARM_APP" ]; then
    echo "❌ ARM app not found at: $ARM_APP"
    exit 1
fi
echo "   ✅ ARM app: $ARM_APP"

# Step 4: Create new app bundle structure
echo ""
echo "📁 Creating $APP_NAME.app bundle..."
mkdir -p "$OUTPUT_APP/Contents/MacOS"
mkdir -p "$OUTPUT_APP/Contents/Resources"
mkdir -p "$OUTPUT_APP/Contents/Java"

# Step 5: Copy Java resources from Intel version (they're identical)
echo "📚 Copying Java resources..."
cp -R "$INTEL_APP/Contents/Java/"* "$OUTPUT_APP/Contents/Java/" 2>/dev/null

# Step 6: Copy data and saves from source directory
if [ -d "$SOURCE_DIR/data" ]; then
    echo "📁 Copying game data from source..."
    cp -R "$SOURCE_DIR/data" "$OUTPUT_APP/Contents/Resources/"
fi

if [ -d "$SOURCE_DIR/saves" ]; then
    echo "💾 Copying saves folder..."
    cp -R "$SOURCE_DIR/saves" "$OUTPUT_APP/Contents/Resources/"
fi

# Step 7: Copy icon if we have one
if [ -n "$ICON_SOURCE" ] && [ -f "$ICON_SOURCE" ]; then
    echo "🎨 Copying application icon..."
    cp "$ICON_SOURCE" "$OUTPUT_APP/Contents/Resources/application.icns"
fi

# Step 8: Create universal Java launcher
echo "📝 Creating universal Java launcher..."

cat > "$OUTPUT_APP/Contents/MacOS/$APP_NAME" << 'EOF'
#!/bin/bash

# Get the app bundle path
cd "$(dirname "$0")/../.."
APP_PATH="$PWD"

# Build classpath from all JARs in Contents/Java
CLASSPATH=""
for jar in "$APP_PATH/Contents/Java"/*.jar; do
    if [ -f "$jar" ]; then
        if [ -z "$CLASSPATH" ]; then
            CLASSPATH="$jar"
        else
            CLASSPATH="$CLASSPATH:$jar"
        fi
    fi
done

# Add resources directory to classpath
CLASSPATH="$CLASSPATH:$APP_PATH/Contents/Resources"

# Find Java
if [ -f "/usr/bin/java" ]; then
    JAVA="/usr/bin/java"
elif [ -f "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/bin/java" ]; then
    JAVA="/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/bin/java"
else
    JAVA=$(which java 2>/dev/null)
fi

if [ -z "$JAVA" ]; then
    osascript -e 'display dialog "Java not found! Please install Java to run this application." buttons {"OK"} default button 1'
    exit 1
fi

# Change to Resources directory (so relative paths work)
cd "$APP_PATH/Contents/Resources"

# Launch Java with Main class
exec "$JAVA" \
    -Djava.awt.headless=false \
    -Dapple.awt.graphics.UseQuartz=true \
    -Dapple.laf.useScreenMenuBar=true \
    -Xdock:name="Person" \
    -Xdock:icon="$APP_PATH/Contents/Resources/application.icns" \
    -cp "$CLASSPATH" \
    Main
EOF

chmod 755 "$OUTPUT_APP/Contents/MacOS/$APP_NAME"

# Step 9: Create Info.plist
echo "📝 Creating Info.plist..."

cat > "$OUTPUT_APP/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>application</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.games</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © $COPYRIGHT_YEAR $COPYRIGHT_HOLDER. All rights reserved.</string>
</dict>
</plist>
EOF

# Step 10: Create PkgInfo
echo "APPL????" > "$OUTPUT_APP/Contents/PkgInfo"

# Step 11: Set permissions
chmod -R 755 "$OUTPUT_APP"

# Step 12: Clean up icon generation files (optional - comment out if you want to keep them)
echo "🧹 Cleaning up temporary icon files..."
rm -rf "$ICON_OUTPUT_DIR"

# Step 13: Create DMG if create-dmg is available
if command -v create-dmg &> /dev/null; then
    echo "💿 Creating DMG for distribution..."
    DMG_NAME="${APP_NAME}-${VERSION}.dmg"
    create-dmg \
        --volname "$APP_NAME" \
        --window-pos 200 120 \
        --window-size 800 400 \
        --icon-size 100 \
        --app-drop-link 600 185 \
        --icon "$APP_NAME.app" 200 185 \
        "$BASE_DIR/Application/macOS_app_builder/$DMG_NAME" \
        "$OUTPUT_APP" > /dev/null 2>&1
    
    if [ -f "$SOURCE_DIR/$DMG_NAME" ]; then
        echo "   ✅ DMG created: $BASE_DIR/Application/macOS_app_builder/$DMG_NAME"
    else
        echo "   ⚠️  DMG creation failed"
    fi
else
    echo "📦 create-dmg not installed. To enable DMG creation: brew install create-dmg"
    # Create zip as fallback
    echo "📦 Creating zip archive instead..."
    ditto -c -k --sequesterRsrc --keepParent "$OUTPUT_APP" "$BASE_DIR/Application/macOS_app_builder/${APP_NAME}-${VERSION}.zip"
fi

# Step 14: Final verification
echo ""
echo "========================================="
echo "✅ Universal $APP_NAME.app built successfully!"
echo "========================================="
echo "Location: $OUTPUT_APP"
echo ""

# Launch the app
read -p "🚀 Launch the app for testing? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Launching $APP_NAME.app..."
    open "$OUTPUT_APP"
fi