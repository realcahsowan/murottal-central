#!/usr/bin/env swift

// Membuat ikon aplikasi 1024×1024 (PNG) untuk Murottal Central.
//
// Pemakaian: swift Scripts/GenerateIcon.swift <output.png>

import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    FileHandle.standardError.write(Data("Pemakaian: swift Scripts/GenerateIcon.swift <output.png>\n".utf8))
    exit(1)
}
let outputPath = arguments[1]

let side = 1024
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: side,
    pixelsHigh: side,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    FileHandle.standardError.write(Data("Gagal membuat bitmap.\n".utf8))
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let size = CGFloat(side)
let full = NSRect(x: 0, y: 0, width: size, height: size)

// Latar membulat dengan gradien teal (tema Quran Central #009688).
let inset = size * 0.055
let backgroundRect = full.insetBy(dx: inset, dy: inset)
let background = NSBezierPath(
    roundedRect: backgroundRect,
    xRadius: size * 0.225,
    yRadius: size * 0.225
)
let gradient = NSGradient(colors: [
    NSColor(srgbRed: 0.00, green: 0.76, blue: 0.69, alpha: 1),
    NSColor(srgbRed: 0.00, green: 0.42, blue: 0.45, alpha: 1),
])
gradient?.draw(in: background, angle: -90)

// Batang gelombang suara (5 batang membulat).
let heights: [CGFloat] = [0.22, 0.42, 0.60, 0.40, 0.26]
let barWidth = size * 0.062
let gap = size * 0.052
let totalWidth = CGFloat(heights.count) * barWidth + CGFloat(heights.count - 1) * gap
var x = (size - totalWidth) / 2
let centerY = size / 2

NSColor.white.setFill()
for height in heights {
    let barHeight = size * height
    let barRect = NSRect(
        x: x,
        y: centerY - barHeight / 2,
        width: barWidth,
        height: barHeight
    )
    NSBezierPath(
        roundedRect: barRect,
        xRadius: barWidth / 2,
        yRadius: barWidth / 2
    ).fill()
    x += barWidth + gap
}

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("Gagal meng-encode PNG.\n".utf8))
    exit(1)
}

do {
    try png.write(to: URL(fileURLWithPath: outputPath))
    print("Ikon ditulis: \(outputPath)")
} catch {
    FileHandle.standardError.write(Data("Gagal menulis berkas: \(error)\n".utf8))
    exit(1)
}
