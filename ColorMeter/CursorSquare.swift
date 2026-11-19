import AppKit

/// Click-through outline drawn around the exact area being sampled.
/// The frontmost app owns the system cursor, so a background app can't replace it; an overlay window is the next best thing.
@MainActor
final class CursorSquare {
    /// Width of each ring (white outside, black inside) around the sample.
    private static let ring: CGFloat = 1
    private let window: NSPanel

    init() {
        window = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = SquareView()
    }

    var windowID: CGWindowID { CGWindowID(window.windowNumber) }

    func show() { window.orderFrontRegardless() }
    func hide() { window.orderOut(nil) }

    /// `sample` is the sampled area in global (bottom-left origin) coordinates; the rings sit outside it.
    func move(to sample: CGRect) {
        window.setFrame(sample.insetBy(dx: -2 * Self.ring, dy: -2 * Self.ring), display: true)
    }
}

private final class SquareView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setStroke()
        NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5)).stroke()
        NSColor.black.setStroke()
        NSBezierPath(rect: bounds.insetBy(dx: 1.5, dy: 1.5)).stroke()
    }
}
