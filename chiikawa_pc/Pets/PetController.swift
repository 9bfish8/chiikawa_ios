//
//  PetController.swift
//  chiikawa_pc
//
//  Owns one desktop pet: its window, its sprite animation, and a small
//  state machine that makes it idle (cycling through idle/waiting/look/
//  review), wander around the screen using the real running-left/
//  running-right art, react to clicks (waving), and follow the mouse
//  while being dragged (jumping).
//

import AppKit

final class PetController {

    let species: PetSpecies

    private let atlas: SpriteAtlas
    private let window: PetWindow
    private let view: PetView
    private let displaySize: CGSize

    private var timer: Timer?
    private let tickInterval: TimeInterval = 1.0 / 30.0

    private var currentMotion: PetMotion = .idle
    private var frameIndex: Int = 0
    private var frameAccumulator: TimeInterval = 0

    private var isDragged = false
    private var walkTarget: CGPoint?
    private var idleTicksRemaining: Int = 0
    private var reactionTicksRemaining: Int = 0
    private let walkSpeed: CGFloat = 90 // points per second

    // Gentle idle "breathing" bounce — the running/waving/jumping art already
    // carries its own motion, so this is only layered on while standing still.
    private var idlePhase: CGFloat = 0
    private let idleBreatheFrequency: CGFloat = 3.2 // radians/sec
    private let idleBreatheBounce: CGFloat = 1.6 // points

    var isVisible: Bool {
        get { window.isVisible }
        set { newValue ? window.orderFront(nil) : window.orderOut(nil) }
    }

    init(species: PetSpecies, atlas: SpriteAtlas, displaySize: CGSize = CGSize(width: 108, height: 117)) {
        self.species = species
        self.atlas = atlas
        self.displaySize = displaySize
        self.window = PetWindow(size: displaySize)
        self.view = PetView(frame: NSRect(origin: .zero, size: displaySize))

        window.contentView = view
        wireViewCallbacks()
        resetIdle(short: true)
        updateFrameImage()
    }

    // MARK: - Lifecycle

    func start(at origin: CGPoint) {
        window.setFrameOrigin(origin)
        window.orderFront(nil)
        timer?.invalidate()
        let t = Timer(timeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        window.orderOut(nil)
    }

    // MARK: - View callbacks

    private func wireViewCallbacks() {
        view.onDragStart = { [weak self] in
            guard let self else { return }
            self.isDragged = true
            self.walkTarget = nil
            self.reactionTicksRemaining = 0
            self.view.bounceOffset = 0
            self.setMotion(.jumping)
        }

        view.onDragMoved = { [weak self] delta in
            guard let self else { return }
            var origin = self.window.frame.origin
            origin.x += delta.x
            origin.y += delta.y
            self.window.setFrameOrigin(self.clamped(origin: origin))
        }

        view.onDragEnd = { [weak self] wasClick in
            guard let self else { return }
            self.isDragged = false
            if wasClick {
                self.triggerReaction(seconds: 1.1)
            } else {
                self.resetIdle(short: true)
            }
        }
    }

    // MARK: - Tick

    private func tick() {
        updateClickThrough()

        if isDragged {
            // Position already driven by drag callbacks; just keep the jumping pose.
        } else if reactionTicksRemaining > 0 {
            reactionTicksRemaining -= 1
            setMotion(.waving)
            if reactionTicksRemaining == 0 {
                resetIdle(short: false)
            }
        } else if let target = walkTarget {
            stepTowards(target)
        } else {
            idlePhase += CGFloat(tickInterval) * idleBreatheFrequency
            view.bounceOffset = (sin(idlePhase) + 1) / 2 * idleBreatheBounce
            idleTicksRemaining -= 1
            if idleTicksRemaining <= 0 {
                decideNextAction()
            }
        }

        advanceAnimationFrame()
    }

    private func decideNextAction() {
        if Double.random(in: 0...1) < 0.72 {
            walkTarget = randomWalkTarget()
        } else {
            resetIdle(short: false)
        }
    }

    private func stepTowards(_ target: CGPoint) {
        let origin = window.frame.origin
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let distance = (dx * dx + dy * dy).squareRoot()
        let step = walkSpeed * CGFloat(tickInterval)

        if distance <= step {
            window.setFrameOrigin(clamped(origin: target))
            walkTarget = nil
            view.bounceOffset = 0
            resetIdle(short: false)
            return
        }

        setMotion(dx < 0 ? .runningLeft : .runningRight)
        let newOrigin = CGPoint(
            x: origin.x + dx / distance * step,
            y: origin.y + dy / distance * step
        )
        window.setFrameOrigin(clamped(origin: newOrigin))
        view.bounceOffset = 0
    }

    private func resetIdle(short: Bool) {
        walkTarget = nil
        idleTicksRemaining = short
            ? Int.random(in: 15...40)
            : Int.random(in: 60...220)
        setMotion(randomIdleMotion())
    }

    private func randomIdleMotion() -> PetMotion {
        switch Double.random(in: 0...1) {
        case ..<0.55: return .idle
        case ..<0.72: return .waiting
        case ..<0.88: return .look
        default: return .review
        }
    }

    private func triggerReaction(seconds: Double) {
        reactionTicksRemaining = Int(seconds / tickInterval)
        frameIndex = 0
        frameAccumulator = 0
    }

    private func randomWalkTarget() -> CGPoint {
        let screen = (window.screen ?? NSScreen.main)?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let minX = screen.minX
        let maxX = screen.maxX - displaySize.width
        let minY = screen.minY
        let maxY = screen.minY + screen.height * 0.65
        guard maxX > minX, maxY > minY else { return window.frame.origin }
        return CGPoint(x: CGFloat.random(in: minX...maxX), y: CGFloat.random(in: minY...maxY))
    }

    private func clamped(origin: CGPoint) -> CGPoint {
        let screen = (window.screen ?? NSScreen.main)?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let x = min(max(origin.x, screen.minX), screen.maxX - displaySize.width)
        let y = min(max(origin.y, screen.minY), screen.maxY - displaySize.height)
        return CGPoint(x: x, y: y)
    }

    // MARK: - Animation

    private func setMotion(_ motion: PetMotion) {
        if currentMotion != motion {
            currentMotion = motion
            frameIndex = 0
            frameAccumulator = 0
            updateFrameImage()
        }
    }

    private func advanceAnimationFrame() {
        frameAccumulator += tickInterval
        let frameDuration = currentMotion.frameDuration
        guard frameAccumulator >= frameDuration else { return }
        frameAccumulator -= frameDuration

        let frames = atlas.frames(for: currentMotion)
        guard !frames.isEmpty else { return }
        frameIndex = (frameIndex + 1) % frames.count
        updateFrameImage()
    }

    private func updateFrameImage() {
        let frames = atlas.frames(for: currentMotion)
        guard !frames.isEmpty else { return }
        let safeIndex = min(frameIndex, frames.count - 1)
        view.currentFrame = frames[safeIndex]
    }

    // MARK: - Click-through

    /// Lets clicks pass through the transparent padding around the character
    /// so the desktop and other apps stay reachable under the pet's window.
    private func updateClickThrough() {
        guard !isDragged else {
            window.ignoresMouseEvents = false
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        let frame = window.frame
        guard frame.contains(mouseLocation) else {
            window.ignoresMouseEvents = true
            return
        }

        let localX = mouseLocation.x - frame.origin.x
        let localY = mouseLocation.y - frame.origin.y

        let framePoint = CGPoint(
            x: localX / displaySize.width * SpriteAtlas.frameSize.width,
            y: localY / displaySize.height * SpriteAtlas.frameSize.height
        )

        let frames = atlas.frames(for: currentMotion)
        let safeIndex = min(frameIndex, max(frames.count - 1, 0))
        let alpha = frames.isEmpty ? 0 : frames[safeIndex].alpha(at: framePoint)
        window.ignoresMouseEvents = alpha < 0.1
    }
}
