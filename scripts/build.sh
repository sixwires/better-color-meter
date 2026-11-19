#!/bin/sh
# Local dev build without xcodebuild: build/ColorMeter.app, sandboxed, ad-hoc signed.
# For App Store archives use the Xcode project (see README).
set -e
cd "$(dirname "$0")/.."
APP=build/ColorMeter.app
rm -rf "$APP" build/icon.iconset
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/icon.iconset

swiftc -O -swift-version 5 -target arm64-apple-macos14.0 \
  -framework ScreenCaptureKit -framework Carbon \
  ColorMeter/*.swift -o "$APP/Contents/MacOS/ColorMeter"

sed -e 's/$(DEVELOPMENT_LANGUAGE)/en/' -e 's/$(EXECUTABLE_NAME)/ColorMeter/' \
    -e 's/$(PRODUCT_NAME)/ColorMeter/' -e 's/$(PRODUCT_BUNDLE_IDENTIFIER)/com.sixwires.ColorMeter/' \
    ColorMeter/Info.plist > "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string AppIcon' "$APP/Contents/Info.plist"

set_dir=ColorMeter/Assets.xcassets/AppIcon.appiconset
for s in 16 32 128 256 512; do
  cp "$set_dir/icon_$s.png" "build/icon.iconset/icon_${s}x${s}.png"
  cp "$set_dir/icon_$((s * 2)).png" "build/icon.iconset/icon_${s}x${s}@2x.png"
done
iconutil -c icns build/icon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

codesign --force --sign - --options runtime \
  --entitlements ColorMeter/ColorMeter.entitlements "$APP"
echo "Built $APP"
