import AppKit
import Foundation

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = CGSize(width: 1024, height: 1024)

let image = NSImage(size: size)
image.lockFocus()

let rect = CGRect(origin: .zero, size: size)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.18, green: 0.48, blue: 0.96, alpha: 1.0),
    NSColor(calibratedRed: 0.21, green: 0.76, blue: 0.83, alpha: 1.0)
])!

let background = NSBezierPath(roundedRect: rect.insetBy(dx: 80, dy: 80), xRadius: 240, yRadius: 240)
gradient.draw(in: background, angle: -45)

let phoneRect = CGRect(x: 310, y: 250, width: 404, height: 560)
let phonePath = NSBezierPath(roundedRect: phoneRect, xRadius: 88, yRadius: 88)
NSColor.white.withAlphaComponent(0.97).setFill()
phonePath.fill()

let screenRect = phoneRect.insetBy(dx: 42, dy: 54)
let screenPath = NSBezierPath(roundedRect: screenRect, xRadius: 48, yRadius: 48)
NSColor(calibratedRed: 0.18, green: 0.48, blue: 0.96, alpha: 0.18).setFill()
screenPath.fill()

let notchRect = CGRect(x: 420, y: 725, width: 184, height: 34)
let notchPath = NSBezierPath(roundedRect: notchRect, xRadius: 17, yRadius: 17)
NSColor.white.withAlphaComponent(0.97).setFill()
notchPath.fill()

let arrowCircleRect = CGRect(x: 610, y: 170, width: 190, height: 190)
let arrowCirclePath = NSBezierPath(ovalIn: arrowCircleRect)
NSColor.white.withAlphaComponent(0.95).setFill()
arrowCirclePath.fill()

let arrowColor = NSColor(calibratedRed: 0.18, green: 0.48, blue: 0.96, alpha: 1.0)
arrowColor.setFill()

let shaft = NSBezierPath(roundedRect: CGRect(x: 691, y: 225, width: 28, height: 74), xRadius: 14, yRadius: 14)
shaft.fill()

let arrowHead = NSBezierPath()
arrowHead.move(to: CGPoint(x: 650, y: 250))
arrowHead.line(to: CGPoint(x: 705, y: 190))
arrowHead.line(to: CGPoint(x: 760, y: 250))
arrowHead.close()
arrowHead.fill()

let base = NSBezierPath(roundedRect: CGRect(x: 648, y: 309, width: 114, height: 22), xRadius: 11, yRadius: 11)
base.fill()

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiff),
    let pngData = rep.representation(using: .png, properties: [:])
else {
    fatalError("Icon PNG olusturulamadi.")
}

try pngData.write(to: outputURL)
