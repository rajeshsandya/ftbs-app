import Foundation
import AppKit

struct IconStyle {
    let background: NSColor
    let sealFill: NSColor
    let sealStroke: NSColor
    let topText: NSColor
    let innerText: NSColor
    let accentBlue: NSColor
    let accentRed: NSColor
    let accentGreen: NSColor
    let ribbonGradientStart: NSColor
    let ribbonGradientEnd: NSColor
    let ribbonText: NSColor
    let mottoText: NSColor
    let flameOrange: NSColor
    let flameRed: NSColor
    let bookRed: NSColor
    let bookGray: NSColor
    let trunk: NSColor
}

struct AppIconEntry {
    let filename: String
    let idiom: String
    let platform: String?
    let size: String
    let scale: String?
    let appearances: [[String: String]]?
}

let fileManager = FileManager.default
let repoRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let assetsRoot = repoRoot.appendingPathComponent("ftbs/Assets.xcassets")
let appIconDir = assetsRoot.appendingPathComponent("AppIcon.appiconset")
let logoDir = assetsRoot.appendingPathComponent("ftbs-logo.imageset")

try fileManager.createDirectory(at: appIconDir, withIntermediateDirectories: true)
try fileManager.createDirectory(at: logoDir, withIntermediateDirectories: true)

let defaultStyle = IconStyle(
    background: .black,
    sealFill: .white,
    sealStroke: NSColor(calibratedRed: 0.16, green: 0.17, blue: 0.72, alpha: 1),
    topText: NSColor(calibratedRed: 0.16, green: 0.17, blue: 0.72, alpha: 1),
    innerText: NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.18, alpha: 1),
    accentBlue: NSColor(calibratedRed: 0.08, green: 0.08, blue: 0.55, alpha: 1),
    accentRed: NSColor(calibratedRed: 0.70, green: 0.05, blue: 0.07, alpha: 1),
    accentGreen: NSColor(calibratedRed: 0.12, green: 0.62, blue: 0.17, alpha: 1),
    ribbonGradientStart: NSColor(calibratedRed: 0.48, green: 0.00, blue: 0.03, alpha: 1),
    ribbonGradientEnd: NSColor(calibratedRed: 0.74, green: 0.00, blue: 0.08, alpha: 1),
    ribbonText: .white,
    mottoText: NSColor(calibratedRed: 0.98, green: 0.82, blue: 0.36, alpha: 1),
    flameOrange: NSColor(calibratedRed: 1.0, green: 0.55, blue: 0.10, alpha: 1),
    flameRed: NSColor(calibratedRed: 0.98, green: 0.16, blue: 0.10, alpha: 1),
    bookRed: NSColor(calibratedRed: 0.92, green: 0.15, blue: 0.12, alpha: 1),
    bookGray: NSColor(calibratedWhite: 0.92, alpha: 1),
    trunk: NSColor(calibratedRed: 0.48, green: 0.28, blue: 0.12, alpha: 1)
)

let darkStyle = IconStyle(
    background: NSColor(calibratedRed: 0.02, green: 0.02, blue: 0.05, alpha: 1),
    sealFill: NSColor(calibratedRed: 0.98, green: 0.99, blue: 1.0, alpha: 1),
    sealStroke: NSColor(calibratedRed: 0.10, green: 0.16, blue: 0.62, alpha: 1),
    topText: NSColor(calibratedRed: 0.12, green: 0.16, blue: 0.65, alpha: 1),
    innerText: .black,
    accentBlue: NSColor(calibratedRed: 0.10, green: 0.10, blue: 0.60, alpha: 1),
    accentRed: NSColor(calibratedRed: 0.72, green: 0.08, blue: 0.10, alpha: 1),
    accentGreen: NSColor(calibratedRed: 0.18, green: 0.64, blue: 0.20, alpha: 1),
    ribbonGradientStart: NSColor(calibratedRed: 0.36, green: 0.00, blue: 0.03, alpha: 1),
    ribbonGradientEnd: NSColor(calibratedRed: 0.70, green: 0.00, blue: 0.08, alpha: 1),
    ribbonText: .white,
    mottoText: NSColor(calibratedRed: 0.98, green: 0.82, blue: 0.36, alpha: 1),
    flameOrange: NSColor(calibratedRed: 1.0, green: 0.50, blue: 0.08, alpha: 1),
    flameRed: NSColor(calibratedRed: 0.95, green: 0.12, blue: 0.08, alpha: 1),
    bookRed: NSColor(calibratedRed: 0.88, green: 0.12, blue: 0.10, alpha: 1),
    bookGray: NSColor(calibratedWhite: 0.85, alpha: 1),
    trunk: NSColor(calibratedRed: 0.42, green: 0.25, blue: 0.10, alpha: 1)
)

let tintedStyle = IconStyle(
    background: NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.99, alpha: 1),
    sealFill: .white,
    sealStroke: NSColor(calibratedRed: 0.16, green: 0.17, blue: 0.72, alpha: 1),
    topText: NSColor(calibratedRed: 0.16, green: 0.17, blue: 0.72, alpha: 1),
    innerText: NSColor(calibratedRed: 0.14, green: 0.14, blue: 0.18, alpha: 1),
    accentBlue: NSColor(calibratedRed: 0.10, green: 0.18, blue: 0.72, alpha: 1),
    accentRed: NSColor(calibratedRed: 0.74, green: 0.12, blue: 0.14, alpha: 1),
    accentGreen: NSColor(calibratedRed: 0.12, green: 0.58, blue: 0.18, alpha: 1),
    ribbonGradientStart: NSColor(calibratedRed: 0.46, green: 0.03, blue: 0.04, alpha: 1),
    ribbonGradientEnd: NSColor(calibratedRed: 0.70, green: 0.03, blue: 0.10, alpha: 1),
    ribbonText: .white,
    mottoText: NSColor(calibratedRed: 0.90, green: 0.72, blue: 0.26, alpha: 1),
    flameOrange: NSColor(calibratedRed: 1.0, green: 0.60, blue: 0.16, alpha: 1),
    flameRed: NSColor(calibratedRed: 0.96, green: 0.20, blue: 0.12, alpha: 1),
    bookRed: NSColor(calibratedRed: 0.92, green: 0.18, blue: 0.14, alpha: 1),
    bookGray: NSColor(calibratedWhite: 0.92, alpha: 1),
    trunk: NSColor(calibratedRed: 0.50, green: 0.30, blue: 0.14, alpha: 1)
)

func makeImage(size: Int, style: IconStyle) -> NSImage {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Unable to create bitmap image representation")
    }

    let graphicsContext = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    defer { NSGraphicsContext.restoreGraphicsState() }

    drawIcon(in: CGRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size)), style: style, context: graphicsContext.cgContext)

    let image = NSImage(size: NSSize(width: size, height: size))
    image.addRepresentation(rep)
    return image
}

func drawIcon(in rect: CGRect, style: IconStyle, context ctx: CGContext) {
    let size = rect.width
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let s = size / 1024.0

    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    ctx.setFillColor(style.background.cgColor)
    ctx.fill(rect)

    // outer emblem
    let outerRadius = size * 0.40
    let ringRadius = size * 0.365
    let innerRadius = size * 0.345

    ctx.setFillColor(style.sealFill.cgColor)
    ctx.fillEllipse(in: CGRect(x: c.x - outerRadius, y: c.y - outerRadius, width: outerRadius * 2, height: outerRadius * 2))

    ctx.setStrokeColor(style.sealStroke.cgColor)
    ctx.setLineWidth(18 * s)
    ctx.strokeEllipse(in: CGRect(x: c.x - outerRadius + 8 * s, y: c.y - outerRadius + 8 * s, width: (outerRadius - 8 * s) * 2, height: (outerRadius - 8 * s) * 2))

    ctx.setStrokeColor(style.accentRed.cgColor)
    ctx.setLineWidth(4.5 * s)
    ctx.strokeEllipse(in: CGRect(x: c.x - ringRadius, y: c.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2))

    ctx.setStrokeColor(style.accentBlue.cgColor)
    ctx.setLineWidth(8 * s)
    ctx.strokeEllipse(in: CGRect(x: c.x - innerRadius, y: c.y - innerRadius, width: innerRadius * 2, height: innerRadius * 2))

    // stars
    drawStar(in: CGPoint(x: c.x - size * 0.305, y: c.y + size * 0.12), radius: 17 * s, color: style.accentRed, ctx: ctx)
    drawStar(in: CGPoint(x: c.x + size * 0.305, y: c.y + size * 0.12), radius: 17 * s, color: style.accentRed, ctx: ctx)

    // arc text
    let topText = "FULL TRUTH BIBLE SOCIETY"
    drawArcText(topText, center: c, radius: size * 0.30, startAngle: .pi * 0.93, endAngle: .pi * 0.07, font: NSFont.boldSystemFont(ofSize: 34 * s), color: style.topText, context: ctx)

    // FTBS label
    drawCenteredText("FTBS", in: CGRect(x: c.x - size * 0.08, y: c.y + size * 0.17, width: size * 0.16, height: size * 0.04), font: NSFont.boldSystemFont(ofSize: 20 * s), color: style.accentBlue, context: ctx)

    // tree trunk/branches
    ctx.saveGState()
    ctx.setStrokeColor(style.trunk.cgColor)
    ctx.setLineWidth(10 * s)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.move(to: CGPoint(x: c.x, y: c.y + size * 0.02))
    ctx.addLine(to: CGPoint(x: c.x, y: c.y + size * 0.14))
    ctx.addLine(to: CGPoint(x: c.x - size * 0.03, y: c.y + size * 0.21))
    ctx.move(to: CGPoint(x: c.x - size * 0.01, y: c.y + size * 0.10))
    ctx.addLine(to: CGPoint(x: c.x - size * 0.10, y: c.y + size * 0.18))
    ctx.move(to: CGPoint(x: c.x + size * 0.01, y: c.y + size * 0.10))
    ctx.addLine(to: CGPoint(x: c.x + size * 0.09, y: c.y + size * 0.18))
    ctx.strokePath()
    ctx.restoreGState()

    // leaves and apples
    let leafPoints: [CGPoint] = [
        CGPoint(x: c.x - size * 0.12, y: c.y + size * 0.26),
        CGPoint(x: c.x - size * 0.08, y: c.y + size * 0.18),
        CGPoint(x: c.x - size * 0.03, y: c.y + size * 0.26),
        CGPoint(x: c.x + size * 0.02, y: c.y + size * 0.22),
        CGPoint(x: c.x + size * 0.07, y: c.y + size * 0.29),
        CGPoint(x: c.x + size * 0.13, y: c.y + size * 0.20),
        CGPoint(x: c.x - size * 0.16, y: c.y + size * 0.24),
        CGPoint(x: c.x + size * 0.16, y: c.y + size * 0.25)
    ]
    for (index, p) in leafPoints.enumerated() {
        let color = (index % 3 == 0) ? style.accentRed : style.accentGreen
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: CGRect(x: p.x - 11 * s, y: p.y - 11 * s, width: 22 * s, height: 22 * s))
    }

    // book / open pages
    let bookY = c.y - size * 0.09
    let bookWidth = size * 0.30
    let bookHeight = size * 0.06
    ctx.setFillColor(style.bookGray.cgColor)
    let leftPage = CGRect(x: c.x - bookWidth - 10 * s, y: bookY, width: bookWidth, height: bookHeight)
    let rightPage = CGRect(x: c.x + 10 * s, y: bookY, width: bookWidth, height: bookHeight)
    ctx.fill(leftPage)
    ctx.fill(rightPage)
    ctx.setStrokeColor(style.bookRed.cgColor)
    ctx.setLineWidth(5 * s)
    ctx.stroke(leftPage)
    ctx.stroke(rightPage)

    ctx.setStrokeColor(style.bookRed.cgColor)
    ctx.setLineWidth(8 * s)
    ctx.move(to: CGPoint(x: c.x - bookWidth - 8 * s, y: bookY + bookHeight + 6 * s))
    ctx.addCurve(to: CGPoint(x: c.x + bookWidth + 8 * s, y: bookY + bookHeight + 6 * s), control1: CGPoint(x: c.x - bookWidth * 0.35, y: bookY + bookHeight + 18 * s), control2: CGPoint(x: c.x + bookWidth * 0.35, y: bookY + bookHeight + 18 * s))
    ctx.strokePath()

    drawCenteredText("Regd.1174 of 2024", in: CGRect(x: c.x - size * 0.18, y: c.y - size * 0.13, width: size * 0.36, height: size * 0.03), font: NSFont.boldSystemFont(ofSize: 15 * s), color: style.innerText, context: ctx)

    // ribbon banner
    let ribbonY = c.y - size * 0.28
    let ribbonWidth = size * 0.72
    let ribbonHeight = size * 0.12
    let ribbonRect = CGRect(x: c.x - ribbonWidth / 2, y: ribbonY, width: ribbonWidth, height: ribbonHeight)
    drawRibbon(in: ribbonRect, start: style.ribbonGradientStart, end: style.ribbonGradientEnd, context: ctx)

    drawCenteredText("FULL TRUTH SPREADERS", in: CGRect(x: ribbonRect.minX + size * 0.06, y: ribbonRect.minY + ribbonHeight * 0.43, width: ribbonWidth - size * 0.12, height: ribbonHeight * 0.28), font: NSFont.boldSystemFont(ofSize: 27 * s), color: style.ribbonText, context: ctx)
    drawCenteredText("Jude 3;1 Cor 1:23", in: CGRect(x: ribbonRect.minX + size * 0.12, y: ribbonRect.minY + ribbonHeight * 0.14, width: ribbonWidth - size * 0.24, height: ribbonHeight * 0.18), font: NSFont.systemFont(ofSize: 15 * s, weight: .medium), color: style.mottoText, context: ctx)

    // bottom GLOBAL
    drawCenteredText("GLOBAL", in: CGRect(x: c.x - size * 0.10, y: c.y - size * 0.35, width: size * 0.20, height: size * 0.03), font: NSFont.boldSystemFont(ofSize: 16 * s), color: style.accentBlue, context: ctx)

    // side flames
    drawFlame(in: CGPoint(x: c.x - size * 0.37, y: c.y - size * 0.22), scale: s, context: ctx, style: style)
    drawFlame(in: CGPoint(x: c.x + size * 0.37, y: c.y - size * 0.22), scale: s, context: ctx, style: style)
}

func drawRibbon(in rect: CGRect, start: NSColor, end: NSColor, context ctx: CGContext) {
    let path = CGMutablePath()
    let tail = rect.height * 0.55
    path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.20))
    path.addLine(to: CGPoint(x: rect.minX - tail, y: rect.midY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.20))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.20))
    path.addLine(to: CGPoint(x: rect.maxX + tail, y: rect.midY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.20))
    path.closeSubpath()

    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()

    let colors = [start.cgColor, end.cgColor] as CFArray
    let space = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) {
        ctx.drawLinearGradient(gradient, start: CGPoint(x: rect.minX, y: rect.midY), end: CGPoint(x: rect.maxX, y: rect.midY), options: [])
    }
    ctx.restoreGState()

    ctx.setStrokeColor(NSColor(calibratedRed: 0.35, green: 0.0, blue: 0.03, alpha: 1).cgColor)
    ctx.setLineWidth(1.5)
    ctx.addPath(path)
    ctx.strokePath()
}

func drawFlame(in center: CGPoint, scale s: CGFloat, context ctx: CGContext, style: IconStyle) {
    let w = 36 * s
    let h = 64 * s
    let path = CGMutablePath()
    path.move(to: CGPoint(x: center.x, y: center.y - h * 0.45))
    path.addCurve(to: CGPoint(x: center.x - w * 0.20, y: center.y + h * 0.10), control1: CGPoint(x: center.x - w * 0.55, y: center.y - h * 0.10), control2: CGPoint(x: center.x - w * 0.45, y: center.y + h * 0.32))
    path.addCurve(to: CGPoint(x: center.x, y: center.y + h * 0.48), control1: CGPoint(x: center.x - w * 0.05, y: center.y + h * 0.30), control2: CGPoint(x: center.x - w * 0.10, y: center.y + h * 0.42))
    path.addCurve(to: CGPoint(x: center.x + w * 0.20, y: center.y + h * 0.10), control1: CGPoint(x: center.x + w * 0.10, y: center.y + h * 0.42), control2: CGPoint(x: center.x + w * 0.55, y: center.y + h * 0.32))
    path.addCurve(to: CGPoint(x: center.x, y: center.y - h * 0.45), control1: CGPoint(x: center.x + w * 0.45, y: center.y - h * 0.10), control2: CGPoint(x: center.x + w * 0.55, y: center.y - h * 0.36))
    path.closeSubpath()

    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [style.flameOrange.cgColor, style.flameRed.cgColor] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: center.x, y: center.y - h * 0.5), end: CGPoint(x: center.x, y: center.y + h * 0.5), options: [])
    ctx.restoreGState()
}

func drawStar(in center: CGPoint, radius: CGFloat, color: NSColor, ctx: CGContext) {
    let path = CGMutablePath()
    let inner = radius * 0.45
    for i in 0..<10 {
        let angle = CGFloat(i) * (.pi / 5.0) - .pi / 2
        let r = i % 2 == 0 ? radius : inner
        let p = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
        if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
    }
    path.closeSubpath()
    ctx.setFillColor(color.cgColor)
    ctx.addPath(path)
    ctx.fillPath()
}

func drawCenteredText(_ string: String, in rect: CGRect, font: NSFont, color: NSColor, context ctx: CGContext) {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let size = (string as NSString).size(withAttributes: attrs)
    let point = CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2)
    (string as NSString).draw(at: point, withAttributes: attrs)
}

func drawArcText(_ string: String, center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, font: NSFont, color: NSColor, context ctx: CGContext) {
    let chars = Array(string)
    guard !chars.isEmpty else { return }
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let widths = chars.map { (String($0) as NSString).size(withAttributes: attrs).width }
    let totalWidth = widths.reduce(0, +)
    let angleSpan = startAngle - endAngle
    guard angleSpan != 0, totalWidth > 0 else { return }
    let totalArcLength = radius * abs(angleSpan)
    let scale = totalArcLength / totalWidth
    let angles = widths.map { $0 * scale / radius }
    var angle = startAngle

    for (idx, ch) in chars.enumerated() {
        let half = angles[idx] / 2
        angle -= half
        let x = center.x + cos(angle) * radius
        let y = center.y + sin(angle) * radius

        ctx.saveGState()
        ctx.translateBy(x: x, y: y)
        ctx.rotate(by: angle - .pi / 2)
        let s = String(ch) as NSString
        let charSize = s.size(withAttributes: attrs)
        s.draw(at: CGPoint(x: -charSize.width / 2, y: -charSize.height / 2), withAttributes: attrs)
        ctx.restoreGState()

        angle -= half
    }
}

func pngData(for image: NSImage) -> Data {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to encode PNG")
    }
    return data
}

func writePNG(_ image: NSImage, to url: URL) throws {
    try pngData(for: image).write(to: url, options: .atomic)
}

func assetJSON(for entries: [AppIconEntry], author: String = "xcode") throws -> Data {
    var images: [[String: Any]] = []
    for entry in entries {
        var dict: [String: Any] = [
            "idiom": entry.idiom,
            "size": entry.size
        ]
        if let platform = entry.platform { dict["platform"] = platform }
        if let scale = entry.scale { dict["scale"] = scale }
        if let appearances = entry.appearances { dict["appearances"] = appearances }
        dict["filename"] = entry.filename
        images.append(dict)
    }

    let root: [String: Any] = [
        "images": images,
        "info": ["author": author, "version": 1]
    ]

    return try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
}

let default1024 = makeImage(size: 1024, style: defaultStyle)
let dark1024 = makeImage(size: 1024, style: darkStyle)
let tinted1024 = makeImage(size: 1024, style: tintedStyle)

let defaultFilename = "AppIcon-ios-1024.png"
let darkFilename = "AppIcon-ios-1024-dark.png"
let tintedFilename = "AppIcon-ios-1024-tinted.png"
let logoFilename = "ftbs-logo.png"

try writePNG(default1024, to: appIconDir.appendingPathComponent(defaultFilename))
try writePNG(dark1024, to: appIconDir.appendingPathComponent(darkFilename))
try writePNG(tinted1024, to: appIconDir.appendingPathComponent(tintedFilename))
try writePNG(default1024, to: logoDir.appendingPathComponent(logoFilename))

let macSizes: [(Int, String)] = [
    (16, "AppIcon-mac-16.png"),
    (32, "AppIcon-mac-16@2x.png"),
    (32, "AppIcon-mac-32.png"),
    (64, "AppIcon-mac-32@2x.png"),
    (128, "AppIcon-mac-128.png"),
    (256, "AppIcon-mac-128@2x.png"),
    (256, "AppIcon-mac-256.png"),
    (512, "AppIcon-mac-256@2x.png"),
    (512, "AppIcon-mac-512.png"),
    (1024, "AppIcon-mac-512@2x.png")
]

for (size, filename) in macSizes {
    let image = makeImage(size: size, style: defaultStyle)
    try writePNG(image, to: appIconDir.appendingPathComponent(filename))
}

let appIconEntries: [AppIconEntry] = [
    AppIconEntry(filename: defaultFilename, idiom: "universal", platform: "ios", size: "1024x1024", scale: nil, appearances: nil),
    AppIconEntry(filename: darkFilename, idiom: "universal", platform: "ios", size: "1024x1024", scale: nil, appearances: [["appearance": "luminosity", "value": "dark"]]),
    AppIconEntry(filename: tintedFilename, idiom: "universal", platform: "ios", size: "1024x1024", scale: nil, appearances: [["appearance": "luminosity", "value": "tinted"]]),
    AppIconEntry(filename: "AppIcon-mac-16.png", idiom: "mac", platform: nil, size: "16x16", scale: "1x", appearances: nil),
    AppIconEntry(filename: "AppIcon-mac-16@2x.png", idiom: "mac", platform: nil, size: "16x16", scale: "2x", appearances: nil),
    AppIconEntry(filename: "AppIcon-mac-32.png", idiom: "mac", platform: nil, size: "32x32", scale: "1x", appearances: nil),
    AppIconEntry(filename: "AppIcon-mac-32@2x.png", idiom: "mac", platform: nil, size: "32x32", scale: "2x", appearances: nil),
    AppIconEntry(filename: "AppIcon-mac-128.png", idiom: "mac", platform: nil, size: "128x128", scale: "1x", appearances: nil),
    AppIconEntry(filename: "AppIcon-mac-128@2x.png", idiom: "mac", platform: nil, size: "128x128", scale: "2x", appearances: nil),
    AppIconEntry(filename: "AppIcon-mac-256.png", idiom: "mac", platform: nil, size: "256x256", scale: "1x", appearances: nil),
    AppIconEntry(filename: "AppIcon-mac-256@2x.png", idiom: "mac", platform: nil, size: "256x256", scale: "2x", appearances: nil),
    AppIconEntry(filename: "AppIcon-mac-512.png", idiom: "mac", platform: nil, size: "512x512", scale: "1x", appearances: nil),
    AppIconEntry(filename: "AppIcon-mac-512@2x.png", idiom: "mac", platform: nil, size: "512x512", scale: "2x", appearances: nil)
]

let appIconJSON = try assetJSON(for: appIconEntries)
try appIconJSON.write(to: appIconDir.appendingPathComponent("Contents.json"), options: .atomic)

let logoJSON: [String: Any] = [
    "images": [["idiom": "universal", "filename": logoFilename]],
    "info": ["author": "xcode", "version": 1]
]
let logoData = try JSONSerialization.data(withJSONObject: logoJSON, options: [.prettyPrinted, .sortedKeys])
try logoData.write(to: logoDir.appendingPathComponent("Contents.json"), options: .atomic)

print("Generated FTBS icons at:\n- \(appIconDir.path)\n- \(logoDir.path)")
