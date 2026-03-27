import AppKit
import Foundation

struct IconSpec {
    let filename: String
    let size: Int
}

let specs: [IconSpec] = [
    .init(filename: "icon_16x16.png", size: 16),
    .init(filename: "icon_16x16@2x.png", size: 32),
    .init(filename: "icon_32x32.png", size: 32),
    .init(filename: "icon_32x32@2x.png", size: 64),
    .init(filename: "icon_128x128.png", size: 128),
    .init(filename: "icon_128x128@2x.png", size: 256),
    .init(filename: "icon_256x256.png", size: 256),
    .init(filename: "icon_256x256@2x.png", size: 512),
    .init(filename: "icon_512x512.png", size: 512),
    .init(filename: "icon_512x512@2x.png", size: 1024),
]

guard CommandLine.arguments.count > 1 else {
    fputs("Usage: generate_app_icon.swift <output-directory>\n", stderr)
    exit(1)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    guard let context = NSGraphicsContext.current?.cgContext else {
        return image
    }

    let canvas = CGRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.23
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.03)
    shadow.shadowBlurRadius = size * 0.06
    shadow.set()

    let bodyRect = canvas.insetBy(dx: size * 0.06, dy: size * 0.06)
    let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: radius, yRadius: radius)

    context.saveGState()
    bodyPath.addClip()
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.06, green: 0.45, blue: 0.98, alpha: 1.0),
        NSColor(calibratedRed: 0.18, green: 0.78, blue: 0.93, alpha: 1.0),
    ])!
    gradient.draw(in: bodyPath, angle: -45)
    context.restoreGState()

    let glowRect = CGRect(x: bodyRect.minX,
                          y: bodyRect.midY,
                          width: bodyRect.width,
                          height: bodyRect.height * 0.7)
    let glowPath = NSBezierPath(roundedRect: glowRect, xRadius: radius, yRadius: radius)
    context.saveGState()
    glowPath.addClip()
    let glowGradient = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.30),
        NSColor.white.withAlphaComponent(0.02),
    ])!
    glowGradient.draw(in: glowPath, angle: 90)
    context.restoreGState()

    let innerStroke = NSBezierPath(roundedRect: bodyRect.insetBy(dx: size * 0.01, dy: size * 0.01),
                                   xRadius: radius * 0.9,
                                   yRadius: radius * 0.9)
    NSColor.white.withAlphaComponent(0.16).setStroke()
    innerStroke.lineWidth = size * 0.012
    innerStroke.stroke()

    shadow.set()
    let photoRect = CGRect(x: size * 0.19, y: size * 0.28, width: size * 0.40, height: size * 0.34)
    let photoPath = NSBezierPath(roundedRect: photoRect, xRadius: size * 0.06, yRadius: size * 0.06)
    NSColor.white.withAlphaComponent(0.96).setFill()
    photoPath.fill()

    let sunRect = CGRect(x: photoRect.minX + size * 0.055, y: photoRect.maxY - size * 0.12, width: size * 0.065, height: size * 0.065)
    let sunPath = NSBezierPath(ovalIn: sunRect)
    NSColor(calibratedRed: 0.06, green: 0.45, blue: 0.98, alpha: 0.85).setFill()
    sunPath.fill()

    let mountain = NSBezierPath()
    mountain.move(to: CGPoint(x: photoRect.minX + size * 0.04, y: photoRect.minY + size * 0.06))
    mountain.line(to: CGPoint(x: photoRect.minX + size * 0.16, y: photoRect.minY + size * 0.17))
    mountain.line(to: CGPoint(x: photoRect.minX + size * 0.25, y: photoRect.minY + size * 0.11))
    mountain.line(to: CGPoint(x: photoRect.minX + size * 0.36, y: photoRect.minY + size * 0.22))
    mountain.line(to: CGPoint(x: photoRect.maxX - size * 0.04, y: photoRect.minY + size * 0.06))
    mountain.close()
    NSColor(calibratedRed: 0.06, green: 0.45, blue: 0.98, alpha: 0.82).setFill()
    mountain.fill()

    let videoRect = CGRect(x: size * 0.48, y: size * 0.43, width: size * 0.27, height: size * 0.22)
    let videoPath = NSBezierPath(roundedRect: videoRect, xRadius: size * 0.05, yRadius: size * 0.05)
    NSColor.white.withAlphaComponent(0.92).setFill()
    videoPath.fill()

    let play = NSBezierPath()
    play.move(to: CGPoint(x: videoRect.minX + size * 0.085, y: videoRect.minY + size * 0.055))
    play.line(to: CGPoint(x: videoRect.minX + size * 0.085, y: videoRect.maxY - size * 0.055))
    play.line(to: CGPoint(x: videoRect.maxX - size * 0.07, y: videoRect.midY))
    play.close()
    NSColor(calibratedRed: 0.04, green: 0.60, blue: 0.86, alpha: 0.95).setFill()
    play.fill()

    let arrowShaft = NSBezierPath(roundedRect: CGRect(x: size * 0.73, y: size * 0.24, width: size * 0.06, height: size * 0.26),
                                  xRadius: size * 0.03,
                                  yRadius: size * 0.03)
    NSColor.white.withAlphaComponent(0.97).setFill()
    arrowShaft.fill()

    let arrowHead = NSBezierPath()
    arrowHead.move(to: CGPoint(x: size * 0.69, y: size * 0.31))
    arrowHead.line(to: CGPoint(x: size * 0.82, y: size * 0.31))
    arrowHead.line(to: CGPoint(x: size * 0.755, y: size * 0.20))
    arrowHead.close()
    NSColor.white.withAlphaComponent(0.97).setFill()
    arrowHead.fill()

    return image
}

for spec in specs {
    let image = drawIcon(size: CGFloat(spec.size))
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        fputs("Failed to render \(spec.filename)\n", stderr)
        exit(2)
    }

    try png.write(to: outputDirectory.appendingPathComponent(spec.filename))
}

