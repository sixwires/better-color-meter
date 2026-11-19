import AppKit
import SwiftUI

/// Floating, non-activating panel that trails the cursor and shows the sampled color.
@MainActor
final class ReadoutPanel {
    let window: NSPanel

    init(sampler: Sampler) {
        window = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 230, height: 180),
                         styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
                         backing: .buffered, defer: false)
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let host = NSHostingView(rootView: ReadoutView(sampler: sampler))
        host.sizingOptions = .preferredContentSize
        window.contentView = host
    }

    var windowID: CGWindowID { CGWindowID(window.windowNumber) }

    func show() { window.orderFrontRegardless() }
    func hide() { window.orderOut(nil) }

    /// Place the panel below-right of the cursor, flipped to stay on screen.
    func move(to cursor: CGPoint) {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(cursor) }) else { return }
        let size = window.frame.size, gap: CGFloat = 18, bounds = screen.visibleFrame
        var x = cursor.x + gap, y = cursor.y - gap - size.height
        if x + size.width > bounds.maxX { x = cursor.x - gap - size.width }
        if y < bounds.minY { y = cursor.y + gap }
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

struct ReadoutView: View {
    var sampler: Sampler
    @State private var copied: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let c = sampler.color {
                RoundedRectangle(cornerRadius: 6)
                    .fill(swatch(c))
                    .frame(height: 34)
                    .padding(.bottom, 4)
                ForEach(c.formats(in: sampler.colorSpace)) { f in
                    Button { copy(f.value) } label: {
                        HStack(spacing: 8) {
                            Text(f.label).foregroundStyle(.secondary).frame(width: 48, alignment: .leading)
                            Text(copied == f.value ? "Copied" : f.value).monospaced()
                            Spacer(minLength: 0)
                        }
                        .font(.system(size: 12))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Text(sampler.colorSpace.label)
                    .font(.system(size: 10)).foregroundStyle(.tertiary).padding(.top, 2)
            } else {
                Text("Move the cursor…").foregroundStyle(.secondary).font(.system(size: 12))
            }
        }
        .padding(10)
        .frame(width: 230, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private func swatch(_ c: RGB) -> Color {
        sampler.colorSpace == .sRGB
            ? Color(.sRGB, red: c.r, green: c.g, blue: c.b)
            : Color(.displayP3, red: c.r, green: c.g, blue: c.b)
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        copied = value
        Task { try? await Task.sleep(for: .seconds(0.8)); if copied == value { copied = nil } }
    }
}
