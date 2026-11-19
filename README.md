# ColorMeter

A simpler Digital Color Meter for macOS. Menu bar app. Press **⌃⌥⌘C**, hover anything, read the color as
HEX, RGB, HSL, HSB and OKLCH at once. Click a row to copy it.

- **⌃⌥⌘C** cycles: hidden → **live** (panel follows cursor, a small square outlines the sampled pixel) → **frozen** (HEX copied) → hidden.
  Clicking anywhere else while frozen also hides it.
- Menu bar icon: same action, plus **Color Space** (sRGB default, or Display P3) and Quit.
- Sandboxed, no network, no data collected. Needs **Screen Recording** permission (that is how macOS lets
  an app read pixels; macOS re-asks roughly monthly).

## Build locally (no Apple Developer account needed)

Xcode 16.2's `xcodebuild` is currently broken on macOS 26 (`Symbol not found: _XPCTypeBool`), so local
builds use `swiftc` from the Command Line Tools:

```sh
./scripts/build.sh          # → build/ColorMeter.app, ad-hoc signed, sandboxed
open build/ColorMeter.app
```

First ⌃⌥⌘C shows the Screen Recording prompt. Grant it, quit and relaunch the app.
Ad-hoc signatures change on every rebuild, so macOS may ask again after each build; a real
Apple Development certificate (after enrollment) makes the grant stick.

Color math checks (the XCTest target in `ColorMeter.xcodeproj` runs the same cases once Xcode 26 works):

```sh
swiftc ColorMeter/ColorFormats.swift scripts/check/main.swift -o build/check && build/check
```

Regenerate the placeholder icon: `./scripts/make-icon.sh`. Replace the PNGs in
`ColorMeter/Assets.xcassets/AppIcon.appiconset` with a real icon before shipping.

## Ship to the Mac App Store

1. **Update Xcode** to 26.x from the App Store (required for App Store submissions, and fixes `xcodebuild`).
   Then `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.
2. **Enroll** in the Apple Developer Program (developer.apple.com, $99/yr). Sign in to Xcode → Settings → Accounts.
3. Put your Team ID in `project.yml` (`DEVELOPMENT_TEAM`) and run `xcodegen generate`.
   Open `ColorMeter.xcodeproj`; Signing & Capabilities should show App Sandbox + Hardened Runtime with
   automatic signing.
4. **App Store Connect** → Apps → New App: macOS, name "ColorMeter", bundle ID `com.sixwires.ColorMeter`
   (register the bundle ID at developer.apple.com → Identifiers first), SKU anything.
   Fill in: category Developer Tools, price, privacy "Data Not Collected", screenshots (1280×800 or larger),
   description, support URL. In **App Review Information → Notes** explain: *"The app reads the color of the
   pixel under the cursor using ScreenCaptureKit, which requires Screen Recording permission. No screen
   content is stored or transmitted."*
5. **Archive and upload**: Xcode → Product → Archive → Distribute App → App Store Connect → Upload.
   Or from the shell:
   ```sh
   xcodebuild -scheme ColorMeter -configuration Release archive -archivePath build/ColorMeter.xcarchive
   xcodebuild -exportArchive -archivePath build/ColorMeter.xcarchive -exportPath build/export \
     -exportOptionsPlist scripts/ExportOptions.plist
   ```
6. In App Store Connect select the build, then **Submit for Review**.

## Layout

```
project.yml                 XcodeGen spec (app + test targets, sandbox, LSUIElement)
ColorMeter/
  ColorMeterApp.swift       @main, MenuBarExtra, Controller state machine
  Sampler.swift             ScreenCaptureKit pixel polling + permission flow
  ReadoutPanel.swift        Floating NSPanel + SwiftUI readout rows
  CursorSquare.swift        Click-through overlay outlining the sampled pixel
  HotKey.swift              Carbon global hotkey ⌃⌥⌘C
  ColorFormats.swift        RGB → HEX / RGB / HSL / HSB / OKLCH (sRGB and Display P3)
ColorMeterTests/            Color math tests (Swift Testing)
scripts/                    build.sh, check/main.swift (color self-check), make-icon.sh, ExportOptions.plist
```
