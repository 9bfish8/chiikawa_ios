//
//  SpriteAtlas.swift
//  chiikawa_pc
//
//  Loads a pet's baked motion strips (one horizontal filmstrip per
//  PetMotion, each frame 192x208pt) and slices them into frames.
//  The strips themselves are generated from the real idle/waiting/look/
//  review/running-left/running-right/waving/jumping GIFs the user
//  supplied, with their flat backgrounds keyed out to alpha.
//

import AppKit

enum PetMotion: String, CaseIterable {
    case idle
    case waiting
    case look
    case review
    case runningLeft = "running-left"
    case runningRight = "running-right"
    case waving
    case jumping

    /// Seconds per frame, matched to the source GIF's own timing.
    var frameDuration: TimeInterval {
        switch self {
        case .idle: return 0.28
        case .waiting: return 0.15
        case .look: return 0.35
        case .review: return 0.15
        case .runningLeft, .runningRight: return 0.12
        case .waving: return 0.14
        case .jumping: return 0.14
        }
    }
}

/// One animation frame: its image plus a fast alpha lookup for hit-testing.
struct SpriteFrame {
    let image: NSImage
    private let alphaBitmap: NSBitmapImageRep?

    init(image: NSImage) {
        self.image = image
        if let tiff = image.tiffRepresentation {
            self.alphaBitmap = NSBitmapImageRep(data: tiff)
        } else {
            self.alphaBitmap = nil
        }
    }

    /// Alpha (0...1) at a point in the frame's own coordinate space (origin bottom-left, size = SpriteAtlas.frameSize).
    func alpha(at point: CGPoint) -> CGFloat {
        guard let bitmap = alphaBitmap else { return 1 }
        let x = Int(point.x / SpriteAtlas.frameSize.width * CGFloat(bitmap.pixelsWide))
        let y = Int((1 - point.y / SpriteAtlas.frameSize.height) * CGFloat(bitmap.pixelsHigh))
        guard x >= 0, x < bitmap.pixelsWide, y >= 0, y < bitmap.pixelsHigh else { return 0 }
        guard let color = bitmap.colorAt(x: x, y: y) else { return 0 }
        return color.alphaComponent
    }
}

final class SpriteAtlas {
    static let frameSize = CGSize(width: 192, height: 208)

    let petID: String
    private var framesByMotion: [PetMotion: [SpriteFrame]] = [:]

    init?(petID: String) {
        self.petID = petID
        for motion in PetMotion.allCases {
            guard let sheet = NSImage(named: "\(petID)_\(motion.rawValue)") else { continue }
            framesByMotion[motion] = Self.slice(sheet: sheet)
        }
        guard !framesByMotion.isEmpty else { return nil }
    }

    func frames(for motion: PetMotion) -> [SpriteFrame] {
        framesByMotion[motion] ?? framesByMotion[.idle] ?? []
    }

    private static func slice(sheet: NSImage) -> [SpriteFrame] {
        let frameW = frameSize.width
        let frameH = frameSize.height
        let count = max(1, Int((sheet.size.width / frameW).rounded()))

        var frames: [SpriteFrame] = []
        for i in 0..<count {
            let rect = NSRect(x: CGFloat(i) * frameW, y: 0, width: frameW, height: frameH)

            let cropped = NSImage(size: NSSize(width: frameW, height: frameH))
            cropped.lockFocus()
            sheet.draw(at: .zero, from: rect, operation: .copy, fraction: 1.0)
            cropped.unlockFocus()

            frames.append(SpriteFrame(image: cropped))
        }
        return frames
    }
}
