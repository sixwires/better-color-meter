import Foundation
import CoreGraphics

enum ColorSpace: String, CaseIterable {
    case sRGB, displayP3

    var label: String { self == .sRGB ? "sRGB" : "Display P3" }
    var cgName: CFString { self == .sRGB ? CGColorSpace.sRGB : CGColorSpace.displayP3 }

    /// Linear RGB → XYZ (D65) rows.
    fileprivate var toXYZ: [[Double]] {
        switch self {
        case .sRGB: return [[0.4124564, 0.3575761, 0.1804375],
                            [0.2126729, 0.7151522, 0.0721750],
                            [0.0193339, 0.1191920, 0.9503041]]
        case .displayP3: return [[0.4865709, 0.2656677, 0.1982173],
                                 [0.2289746, 0.6917385, 0.0792869],
                                 [0.0000000, 0.0451134, 1.0439444]]
        }
    }
}

/// Components 0...1, gamma-encoded, in some display color space.
struct RGB: Equatable {
    var r, g, b: Double

    struct Format: Identifiable { let label, value: String; var id: String { label } }

    func formats(in space: ColorSpace) -> [Format] {
        [.init(label: "HEX", value: hex),
         .init(label: "RGB", value: rgbString),
         .init(label: "HSL", value: hslString),
         .init(label: "HSB", value: hsbString),
         .init(label: "OKLCH", value: oklchString(in: space))]
    }

    var hex: String { String(format: "#%02X%02X%02X", byte(r), byte(g), byte(b)) }
    var rgbString: String { "rgb(\(byte(r)), \(byte(g)), \(byte(b)))" }
    var hslString: String { let c = hsl; return "hsl(\(deg(c.h)), \(pct(c.s))%, \(pct(c.l))%)" }
    var hsbString: String { let c = hsb; return "hsb(\(deg(c.h)), \(pct(c.s))%, \(pct(c.b))%)" }
    func oklchString(in space: ColorSpace) -> String {
        let c = oklch(in: space)
        return String(format: "oklch(%.1f%% %.3f %.1f)", c.l * 100, c.c, c.h)
    }

    var hsb: (h: Double, s: Double, b: Double) {
        let mx = max(r, g, b), d = mx - min(r, g, b)
        return (hue(mx: mx, d: d), mx == 0 ? 0 : d / mx, mx)
    }

    var hsl: (h: Double, s: Double, l: Double) {
        let mx = max(r, g, b), mn = min(r, g, b), d = mx - mn, l = (mx + mn) / 2
        return (hue(mx: mx, d: d), d == 0 ? 0 : d / (1 - abs(2 * l - 1)), l)
    }

    /// Björn Ottosson's OKLab, via XYZ so P3 input is handled correctly.
    func oklch(in space: ColorSpace) -> (l: Double, c: Double, h: Double) {
        let lin = [linear(r), linear(g), linear(b)]
        let xyz = mul(space.toXYZ, lin)
        let lms = mul([[0.8189330101, 0.3618667424, -0.1288597137],
                       [0.0329845436, 0.9293118715, 0.0361456387],
                       [0.0482003018, 0.2643662691, 0.6338517070]], xyz).map { cbrt($0) }
        let lab = mul([[0.2104542553, 0.7936177850, -0.0040720468],
                       [1.9779984951, -2.4285922050, 0.4505937099],
                       [0.0259040371, 0.7827717662, -0.8086757660]], lms)
        let c = hypot(lab[1], lab[2])
        // Below visible chroma hue is noise; report 0 like CSS does for achromatic colors.
        var h = c < 0.0005 ? 0 : atan2(lab[2], lab[1]) * 180 / .pi
        if h < 0 { h += 360 }
        return (lab[0], c, h)
    }

    private func hue(mx: Double, d: Double) -> Double {
        guard d > 0 else { return 0 }
        let h: Double
        if mx == r { h = (g - b) / d } else if mx == g { h = 2 + (b - r) / d } else { h = 4 + (r - g) / d }
        return h < 0 ? h * 60 + 360 : h * 60
    }
}

private func byte(_ v: Double) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
private func pct(_ v: Double) -> Int { Int((v * 100).rounded()) }
private func deg(_ v: Double) -> Int { Int(v.rounded()) % 360 }
private func linear(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
private func mul(_ m: [[Double]], _ v: [Double]) -> [Double] { m.map { zip($0, v).reduce(0) { $0 + $1.0 * $1.1 } } }
