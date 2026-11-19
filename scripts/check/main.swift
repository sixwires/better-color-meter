// Assert-based self-check for ColorFormats, runnable without Xcode:
//   swiftc ColorMeter/ColorFormats.swift scripts/check/main.swift -o build/check && build/check
// Mirrors ColorMeterTests/ColorFormatsTests.swift, which Xcode runs once Xcode 26 is installed.
import Foundation

func check(_ ok: Bool, _ what: String, line: Int = #line) {
    if !ok { print("FAIL line \(line): \(what)"); exit(1) }
}
func near(_ a: Double, _ b: Double, _ tol: Double) -> Bool { abs(a - b) <= tol }

let red = RGB(r: 1, g: 0, b: 0), white = RGB(r: 1, g: 1, b: 1)
let steel = RGB(r: 0x33 / 255.0, g: 0x66 / 255.0, b: 0x99 / 255.0)

check(red.hex == "#FF0000", red.hex)
check(steel.hex == "#336699", steel.hex)
check(steel.rgbString == "rgb(51, 102, 153)", steel.rgbString)
check(red.hslString == "hsl(0, 100%, 50%)", red.hslString)
check(red.hsbString == "hsb(0, 100%, 100%)", red.hsbString)
check(steel.hslString == "hsl(210, 50%, 40%)", steel.hslString)
check(steel.hsbString == "hsb(210, 67%, 60%)", steel.hsbString)
check(white.hslString == "hsl(0, 0%, 100%)", white.hslString)
check(RGB(r: 1, g: 0, b: 1).hslString == "hsl(300, 100%, 50%)", "magenta hsl")

let r = red.oklch(in: .sRGB)
check(near(r.l, 0.628, 0.005) && near(r.c, 0.258, 0.005) && near(r.h, 29.2, 0.5), "oklch red \(r)")
check(red.oklchString(in: .sRGB) == "oklch(62.8% 0.258 29.2)", red.oklchString(in: .sRGB))
let w = white.oklch(in: .sRGB)
check(near(w.l, 1, 0.005) && near(w.c, 0, 0.005) && w.h == 0, "oklch white \(w)")
check(red.oklch(in: .displayP3).c > r.c + 0.02, "P3 red more chromatic")
check(near(white.oklch(in: .displayP3).l, 1, 0.005), "P3 white")
check(red.formats(in: .sRGB).map(\.label) == ["HEX", "RGB", "HSL", "HSB", "OKLCH"], "format labels")
print("All color checks passed")
