//
//  PetView.swift
//  chiikawa_pc
//
//  Draws the pet's current animation frame and reports click/drag
//  gestures to its controller. Pixel-perfect click-through for the
//  transparent padding around the character is handled by toggling
//  the owning window's `ignoresMouseEvents`, driven from
//  PetController's tick (see SpriteFrame.alpha).
//

import AppKit

final class PetView: NSView {

    var currentFrame: SpriteFrame? {
        didSet { needsDisplay = true }
    }

    /// Gentle idle "breathing" bounce, in points, lifting the character straight up.
    /// Running/waving/jumping already carry their own motion from the real frames.
    var bounceOffset: CGFloat = 0 {
        didSet { if oldValue != bounceOffset { needsDisplay = true } }
    }

    /// Fired on mouse down, before any drag delta has been reported.
    var onDragStart: (() -> Void)?
    /// Fired on every mouse-dragged event with the screen-space delta since the last callback.
    var onDragMoved: ((_ screenDelta: CGPoint) -> Void)?
    /// Fired on mouse up. `wasClick` is true when the total drag distance stayed below the click threshold.
    var onDragEnd: ((_ wasClick: Bool) -> Void)?

    private var lastScreenLocation: NSPoint = .zero
    private var totalDragDistance: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    override var isFlipped: Bool { false }
    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let frame = currentFrame, let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        ctx.translateBy(x: 0, y: bounceOffset)
        frame.image.draw(in: bounds)
        ctx.restoreGState()
    }

    override func mouseDown(with event: NSEvent) {
        lastScreenLocation = NSEvent.mouseLocation
        totalDragDistance = 0
        onDragStart?()
    }

    override func mouseDragged(with event: NSEvent) {
        let current = NSEvent.mouseLocation
        let delta = CGPoint(x: current.x - lastScreenLocation.x, y: current.y - lastScreenLocation.y)
        totalDragDistance += abs(delta.x) + abs(delta.y)
        lastScreenLocation = current
        onDragMoved?(delta)
    }

    override func mouseUp(with event: NSEvent) {
        onDragEnd?(totalDragDistance < 4)
    }
}
