import XCTest

final class ColorFormatsTests: XCTestCase {
    let red = RGB(r: 1, g: 0, b: 0)
    let white = RGB(r: 1, g: 1, b: 1)
    let steel = RGB(r: 0x33 / 255.0, g: 0x66 / 255.0, b: 0x99 / 255.0)

    func testHexAndRGB() {
        XCTAssertEqual(red.hex, "#FF0000")
        XCTAssertEqual(steel.hex, "#336699")
        XCTAssertEqual(steel.rgbString, "rgb(51, 102, 153)")
        XCTAssertEqual(RGB(r: 0, g: 0, b: 0).hex, "#000000")
    }

    func testHSLandHSB() {
        XCTAssertEqual(red.hslString, "hsl(0, 100%, 50%)")
        XCTAssertEqual(red.hsbString, "hsb(0, 100%, 100%)")
        XCTAssertEqual(steel.hslString, "hsl(210, 50%, 40%)")
        XCTAssertEqual(steel.hsbString, "hsb(210, 67%, 60%)")
        XCTAssertEqual(white.hslString, "hsl(0, 0%, 100%)")
        XCTAssertEqual(RGB(r: 1, g: 0, b: 1).hslString, "hsl(300, 100%, 50%)")
    }

    func testOKLCH() {
        let r = red.oklch(in: .sRGB)
        XCTAssertEqual(r.l, 0.628, accuracy: 0.005)
        XCTAssertEqual(r.c, 0.258, accuracy: 0.005)
        XCTAssertEqual(r.h, 29.2, accuracy: 0.5)
        XCTAssertEqual(red.oklchString(in: .sRGB), "oklch(62.8% 0.258 29.2)")

        let w = white.oklch(in: .sRGB)
        XCTAssertEqual(w.l, 1, accuracy: 0.005)
        XCTAssertEqual(w.c, 0, accuracy: 0.005)
        XCTAssertEqual(w.h, 0)

        // Display P3 red is more saturated than sRGB red; P3 white is still white.
        XCTAssertGreaterThan(red.oklch(in: .displayP3).c, r.c + 0.02)
        XCTAssertEqual(white.oklch(in: .displayP3).l, 1, accuracy: 0.005)
    }

    func testFormatsList() {
        XCTAssertEqual(red.formats(in: .sRGB).map(\.label), ["HEX", "RGB", "HSL", "HSB", "OKLCH"])
    }
}
