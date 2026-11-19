import AppKit
import SwiftUI

@main
struct ColorMeterApp: App {
    @State private var controller = Controller()

    var body: some Scene {
        MenuBarExtra("ColorMeter", systemImage: "eyedropper") {
            @Bindable var sampler = controller.sampler
            Button(controller.mode.actionTitle) { controller.cycle() }
                .keyboardShortcut("c", modifiers: [.control, .option, .command])
            Picker("Color Space", selection: $sampler.colorSpace) {
                ForEach(ColorSpace.allCases, id: \.self) { Text($0.label) }
            }
            Divider()
            Button("Quit ColorMeter") { NSApp.terminate(nil) }.keyboardShortcut("q")
        }
    }
}

/// ⌃⌥⌘C cycles: hidden → live → frozen (hex copied) → hidden. Clicking elsewhere while frozen hides.
@MainActor @Observable
final class Controller {
    enum Mode {
        case idle, live, frozen
        var actionTitle: String {
            switch self {
            case .idle: return "Start Sampling"
            case .live: return "Freeze & Copy HEX"
            case .frozen: return "Hide"
            }
        }
    }

    private(set) var mode: Mode = .idle
    let sampler: Sampler
    @ObservationIgnored private let panel: ReadoutPanel
    @ObservationIgnored private var hotKey: HotKey?
    @ObservationIgnored private var clickMonitor: Any?

    init() {
        let sampler = Sampler()
        self.sampler = sampler
        panel = ReadoutPanel(sampler: sampler)
        sampler.excludedWindowIDs = [panel.windowID]
        sampler.onTick = { [panel] in panel.move(to: $0) }
        hotKey = HotKey { [weak self] in self?.cycle() }
    }

    func cycle() {
        switch mode {
        case .idle: Task { await start() }
        case .live: freeze()
        case .frozen: hide()
        }
    }

    private func start() async {
        guard await sampler.start() else { return }
        mode = .live
        panel.move(to: NSEvent.mouseLocation)
        panel.show()
    }

    private func freeze() {
        sampler.stop()
        mode = .frozen
        if let hex = sampler.color?.hex {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(hex, forType: .string)
        }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            Task { @MainActor in self?.hide() }
        }
    }

    private func hide() {
        if let clickMonitor { NSEvent.removeMonitor(clickMonitor) }
        clickMonitor = nil
        sampler.stop()
        panel.hide()
        mode = .idle
    }
}
