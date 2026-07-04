import AppKit
import Foundation

struct IconSlot {
    let name: String
    let pixels: Int
}

let iconSlots: [IconSlot] = [
    .init(name: "appicon-16.png", pixels: 16),
    .init(name: "appicon-32.png", pixels: 32),
    .init(name: "appicon-64.png", pixels: 64),
    .init(name: "appicon-128.png", pixels: 128),
    .init(name: "appicon-128@2x.png", pixels: 256),
    .init(name: "appicon-256.png", pixels: 256),
    .init(name: "appicon-256@2x.png", pixels: 512),
    .init(name: "appicon-512.png", pixels: 512),
    .init(name: "appicon-512@2x.png", pixels: 1024),
    .init(name: "appicon-ios-20@2x.png", pixels: 40),
    .init(name: "appicon-ios-20@3x.png", pixels: 60),
    .init(name: "appicon-ios-29@2x.png", pixels: 58),
    .init(name: "appicon-ios-29@3x.png", pixels: 87),
    .init(name: "appicon-ios-40@2x.png", pixels: 80),
    .init(name: "appicon-ios-40@3x.png", pixels: 120),
    .init(name: "appicon-ios-60@2x.png", pixels: 120),
    .init(name: "appicon-ios-60@3x.png", pixels: 180),
    .init(name: "appicon-ios-marketing.png", pixels: 1024),
    .init(name: "appicon-ipad-20.png", pixels: 20),
    .init(name: "appicon-ipad-20@2x.png", pixels: 40),
    .init(name: "appicon-ipad-29.png", pixels: 29),
    .init(name: "appicon-ipad-29@2x.png", pixels: 58),
    .init(name: "appicon-ipad-40.png", pixels: 40),
    .init(name: "appicon-ipad-40@2x.png", pixels: 80),
    .init(name: "appicon-ipad-76.png", pixels: 76),
    .init(name: "appicon-ipad-76@2x.png", pixels: 152),
    .init(name: "appicon-ipad-83.5@2x.png", pixels: 167)
]

let destination = URL(
    fileURLWithPath: FileManager.default.currentDirectoryPath
)
    .appendingPathComponent(
        "Source/PhotoMemo/PhotoMemo/Assets.xcassets/AppIcon.appiconset",
        isDirectory: true
    )

func drawFullMark(
    in rect: CGRect,
    context: CGContext?
) {
    let scale =
        rect.width / 1024.0
    let black =
        NSColor(
            calibratedWhite: 0.08,
            alpha: 1
        )
    let blue =
        NSColor(
            calibratedRed: 0.16,
            green: 0.49,
            blue: 0.96,
            alpha: 1
        )

    let leftFrame =
        NSBezierPath(
            roundedRect: CGRect(
                x: 220 * scale,
                y: 232 * scale,
                width: 344 * scale,
                height: 414 * scale
            ),
            xRadius: 70 * scale,
            yRadius: 70 * scale
        )
    leftFrame.lineWidth =
        max(8 * scale, 3)
    black.setStroke()
    leftFrame.stroke()

    let rightFrame =
        NSBezierPath(
            roundedRect: CGRect(
                x: 468 * scale,
                y: 332 * scale,
                width: 292 * scale,
                height: 352 * scale
            ),
            xRadius: 60 * scale,
            yRadius: 60 * scale
        )
    rightFrame.lineWidth =
        max(6 * scale, 2.5)
    rightFrame.stroke()

    let dotRect = CGRect(
        x: 708 * scale,
        y: 700 * scale,
        width: 104 * scale,
        height: 104 * scale
    )
    blue.setFill()
    NSBezierPath(
        ovalIn: dotRect
    )
    .fill()

    let line =
        NSBezierPath()
    line.move(
        to: CGPoint(
            x: 574 * scale,
            y: 284 * scale
        )
    )
    line.line(
        to: CGPoint(
            x: 740 * scale,
            y: 438 * scale
        )
    )
    line.line(
        to: CGPoint(
            x: 844 * scale,
            y: 342 * scale
        )
    )
    line.lineWidth =
        max(22 * scale, 5)
    line.lineCapStyle = .round
    line.lineJoinStyle = .round
    blue.setStroke()
    line.stroke()

    if let context {
        context.saveGState()
        context.setStrokeColor(
            NSColor(
                calibratedWhite: 0.92,
                alpha: 1
            ).cgColor
        )
        context.setLineWidth(
            max(3 * scale, 1)
        )
        context.stroke(
            CGRect(
                x: 0.5,
                y: 0.5,
                width: rect.width - 1,
                height: rect.height - 1
            )
        )
        context.restoreGState()
    }
}

func drawCompactMark(
    in rect: CGRect,
    context: CGContext?
) {
    let scale =
        rect.width / 1024.0
    let black =
        NSColor(
            calibratedWhite: 0.08,
            alpha: 1
        )
    let blue =
        NSColor(
            calibratedRed: 0.16,
            green: 0.49,
            blue: 0.96,
            alpha: 1
        )

    let mainFrame =
        NSBezierPath(
            roundedRect: CGRect(
                x: 232 * scale,
                y: 222 * scale,
                width: 446 * scale,
                height: 522 * scale
            ),
            xRadius: 84 * scale,
            yRadius: 84 * scale
        )
    mainFrame.lineWidth =
        max(10 * scale, 2)
    black.setStroke()
    mainFrame.stroke()

    let accentRect = CGRect(
        x: 700 * scale,
        y: 696 * scale,
        width: 110 * scale,
        height: 110 * scale
    )
    blue.setFill()
    NSBezierPath(
        ovalIn: accentRect
    )
    .fill()

    let underline =
        NSBezierPath()
    underline.move(
        to: CGPoint(
            x: 360 * scale,
            y: 330 * scale
        )
    )
    underline.line(
        to: CGPoint(
            x: 620 * scale,
            y: 330 * scale
        )
    )
    underline.lineWidth =
        max(30 * scale, 3)
    underline.lineCapStyle = .round
    blue.setStroke()
    underline.stroke()

    context?.saveGState()
    context?.setStrokeColor(
        NSColor(
            calibratedWhite: 0.92,
            alpha: 1
        ).cgColor
    )
    context?.setLineWidth(
        max(2 * scale, 0.8)
    )
    context?.stroke(
        CGRect(
            x: 0.5,
            y: 0.5,
            width: rect.width - 1,
            height: rect.height - 1
        )
    )
    context?.restoreGState()
}

func pngData(
    size: Int
) -> Data? {
    guard let context =
        CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo:
                CGImageAlphaInfo
                .premultipliedLast
                .rawValue
        )
    else {
        return nil
    }

    NSGraphicsContext.saveGraphicsState()
    defer {
        NSGraphicsContext.restoreGraphicsState()
    }

    let graphicsContext =
        NSGraphicsContext(
            cgContext: context,
            flipped: false
        )
    NSGraphicsContext.current =
        graphicsContext

    let rect = CGRect(
        origin: .zero,
        size: CGSize(
            width: size,
            height: size
        )
    )

    NSColor.white.setFill()
    NSBezierPath(
        rect: rect
    )
    .fill()

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    if size <= 40 {
        drawCompactMark(
            in: rect,
            context: context
        )
    } else {
        drawFullMark(
            in: rect,
            context: context
        )
    }

    guard let image =
        context.makeImage() else {
        return nil
    }

    let bitmap =
        NSBitmapImageRep(
            cgImage: image
        )

    return bitmap.representation(
        using: .png,
        properties: [:]
    )
}

try FileManager.default.createDirectory(
    at: destination,
    withIntermediateDirectories: true
)

for slot in iconSlots {
    guard let data = pngData(size: slot.pixels) else {
        throw NSError(
            domain: "PhotoMemoIcon",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "Failed to encode \(slot.name)"
            ]
        )
    }

    try data.write(
        to: destination.appendingPathComponent(
            slot.name
        ),
        options: .atomic
    )
}

print("Generated \(iconSlots.count) icon files at \(destination.path)")
