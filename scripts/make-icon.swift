// Placeholder app icon: gradient rounded square with a white "sample" dot.
// Usage: swift scripts/make-icon.swift out.png
import AppKit

let out = CommandLine.arguments[1]
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let square = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 190, yRadius: 190)
NSGradient(colors: [NSColor(calibratedRed: 1.0, green: 0.35, blue: 0.45, alpha: 1),
                    NSColor(calibratedRed: 0.3, green: 0.5, blue: 1.0, alpha: 1)])!.draw(in: square, angle: -60)
NSColor.white.setFill()
NSBezierPath(ovalIn: NSRect(x: 402, y: 402, width: 220, height: 220)).fill()
NSColor.black.withAlphaComponent(0.25).setStroke()
let ring = NSBezierPath(ovalIn: NSRect(x: 362, y: 362, width: 300, height: 300))
ring.lineWidth = 28
ring.stroke()
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
