#!/bin/sh
# Generates all macOS AppIcon sizes from scripts/make-icon.swift. Run once; replace with a real icon later.
set -e
cd "$(dirname "$0")/.."
set_dir=ColorMeter/Assets.xcassets/AppIcon.appiconset
mkdir -p "$set_dir"
swift scripts/make-icon.swift "$set_dir/icon_1024.png"
for s in 16 32 64 128 256 512; do sips -z $s $s "$set_dir/icon_1024.png" --out "$set_dir/icon_$s.png" >/dev/null; done
cat > "$set_dir/Contents.json" <<JSON
{ "images" : [
  { "size" : "16x16",   "idiom" : "mac", "filename" : "icon_16.png",   "scale" : "1x" },
  { "size" : "16x16",   "idiom" : "mac", "filename" : "icon_32.png",   "scale" : "2x" },
  { "size" : "32x32",   "idiom" : "mac", "filename" : "icon_32.png",   "scale" : "1x" },
  { "size" : "32x32",   "idiom" : "mac", "filename" : "icon_64.png",   "scale" : "2x" },
  { "size" : "128x128", "idiom" : "mac", "filename" : "icon_128.png",  "scale" : "1x" },
  { "size" : "128x128", "idiom" : "mac", "filename" : "icon_256.png",  "scale" : "2x" },
  { "size" : "256x256", "idiom" : "mac", "filename" : "icon_256.png",  "scale" : "1x" },
  { "size" : "256x256", "idiom" : "mac", "filename" : "icon_512.png",  "scale" : "2x" },
  { "size" : "512x512", "idiom" : "mac", "filename" : "icon_512.png",  "scale" : "1x" },
  { "size" : "512x512", "idiom" : "mac", "filename" : "icon_1024.png", "scale" : "2x" }
], "info" : { "author" : "xcode", "version" : 1 } }
JSON
echo '{ "info" : { "author" : "xcode", "version" : 1 } }' > ColorMeter/Assets.xcassets/Contents.json
