import AppKit
import ScreenCaptureKit
import Observation

/// Polls the pixel under the cursor via ScreenCaptureKit while running.
@MainActor @Observable
final class Sampler {
    private(set) var color: RGB?
    private(set) var isRunning = false
    var colorSpace = ColorSpace(rawValue: UserDefaults.standard.string(forKey: "colorSpace") ?? "") ?? .sRGB {
        didSet { UserDefaults.standard.set(colorSpace.rawValue, forKey: "colorSpace") }
    }
    /// Our own windows, so hovering the readout panel doesn't sample itself.
    @ObservationIgnored var excludedWindowIDs: [CGWindowID] = []
    /// Called each tick with the sampled area in global (bottom-left origin) coordinates.
    @ObservationIgnored var onTick: ((CGRect) -> Void)?

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var content: SCShareableContent?
    @ObservationIgnored private var inFlight = false

    /// Returns false when Screen Recording permission is missing (user was prompted).
    func start() async -> Bool {
        guard CGPreflightScreenCaptureAccess() else { requestPermission(); return false }
        do {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        } catch {
            NSLog("ColorMeter: shareable content failed: \(error)")
            requestPermission()
            return false
        }
        isRunning = true
        // ponytail: 30 Hz one-shot screenshots; switch to SCStream if CPU use exceeds ~5%.
        timer = Timer.scheduledTimer(withTimeInterval: 1 / 30, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.tick() }
        }
        return true
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func tick() async {
        guard !inFlight, let content else { return }
        inFlight = true
        defer { inFlight = false }

        let point = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }),
              let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
              let display = content.displays.first(where: { $0.displayID == displayID }) else { return }

        // Global coords are bottom-left origin; SCK sourceRect is display-local, top-left origin.
        let rect = CGRect(x: floor(point.x - screen.frame.minX), y: floor(screen.frame.maxY - point.y), width: 1, height: 1)
        onTick?(CGRect(x: rect.minX + screen.frame.minX, y: screen.frame.maxY - rect.maxY, width: rect.width, height: rect.height))
        let scale = Int(screen.backingScaleFactor)
        let config = SCStreamConfiguration()
        config.sourceRect = rect
        config.width = scale
        config.height = scale
        config.showsCursor = false
        config.colorSpaceName = colorSpace.cgName
        config.pixelFormat = kCVPixelFormatType_32BGRA
        let excluded = content.windows.filter { excludedWindowIDs.contains($0.windowID) }
        let filter = SCContentFilter(display: display, excludingWindows: excluded)
        do {
            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            if let rgb = Self.centerPixel(of: image, in: colorSpace) { color = rgb }
        } catch {
            NSLog("ColorMeter: capture failed: \(error)")
        }
    }

    nonisolated static func centerPixel(of image: CGImage, in space: ColorSpace) -> RGB? {
        var px = [UInt8](repeating: 0, count: 4)
        guard let cs = CGColorSpace(name: space.cgName),
              let ctx = CGContext(data: &px, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: cs,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
        else { return nil }
        ctx.interpolationQuality = .none
        let w = CGFloat(image.width), h = CGFloat(image.height)
        // Shift so the image's center device pixel lands on our single output pixel.
        ctx.draw(image, in: CGRect(x: -floor(w / 2), y: -floor(h / 2), width: w, height: h))
        return RGB(r: Double(px[0]) / 255, g: Double(px[1]) / 255, b: Double(px[2]) / 255)
    }

    private func requestPermission() {
        // First call shows the system prompt and adds us to the Screen Recording list.
        let askedBefore = UserDefaults.standard.bool(forKey: "askedScreenCapture")
        UserDefaults.standard.set(true, forKey: "askedScreenCapture")
        if CGRequestScreenCaptureAccess() || !askedBefore { return }

        let alert = NSAlert()
        alert.messageText = "Screen Recording permission needed"
        alert.informativeText = "ColorMeter reads the pixel under your cursor using macOS screen capture. Enable ColorMeter under System Settings → Privacy & Security → Screen & System Audio Recording, then relaunch the app."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
