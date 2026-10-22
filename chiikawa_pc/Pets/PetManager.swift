//
//  PetManager.swift
//  chiikawa_pc
//
//  Owns every pet's sprite atlas (loaded once, reused for thumbnails and
//  for live controllers) and the set of currently-active characters.
//  Nothing spawns on its own — the picker UI or the menu bar decides
//  what shows up on the desktop.
//

import AppKit
import Combine

final class PetManager: ObservableObject {

    @Published private(set) var activeSpeciesIDs: Set<String> = []

    private(set) var atlases: [String: SpriteAtlas] = [:]
    private var controllers: [String: PetController] = [:]
    private var statusItem: NSStatusItem?

    init() {
        for species in PetCatalog.all {
            atlases[species.id] = SpriteAtlas(petID: species.id)
        }
    }

    func previewImage(for id: String) -> NSImage? {
        atlases[id]?.frames(for: .idle).first?.image
    }

    func isActive(_ id: String) -> Bool {
        activeSpeciesIDs.contains(id)
    }

    // MARK: - Spawning

    func toggle(_ species: PetSpecies) {
        if activeSpeciesIDs.contains(species.id) {
            remove(species.id)
        } else {
            spawn(species)
        }
    }

    func spawn(_ species: PetSpecies) {
        guard controllers[species.id] == nil, let atlas = atlases[species.id] else { return }
        let controller = PetController(species: species, atlas: atlas)
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        controller.start(at: randomPosition(in: screen))
        controllers[species.id] = controller
        activeSpeciesIDs.insert(species.id)
        refreshMenu()
    }

    func remove(_ id: String) {
        guard let controller = controllers[id] else { return }
        controller.stop()
        controllers[id] = nil
        activeSpeciesIDs.remove(id)
        refreshMenu()
    }

    func removeAll() {
        for id in Array(controllers.keys) { remove(id) }
    }

    func scatterActive() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        for controller in controllers.values {
            controller.start(at: randomPosition(in: screen))
        }
    }

    private func randomPosition(in screen: NSRect) -> CGPoint {
        let margin: CGFloat = 120
        let x = CGFloat.random(in: screen.minX...(max(screen.maxX - margin, screen.minX)))
        let y = CGFloat.random(in: screen.minY...(screen.minY + screen.height * 0.5))
        return CGPoint(x: x, y: y)
    }

    // MARK: - Menu bar

    func setUpMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "pawprint.fill",
            accessibilityDescription: "Chiikawa Pets"
        )
        statusItem = item
        refreshMenu()
    }

    private func refreshMenu() {
        guard let item = statusItem else { return }

        let menu = NSMenu()
        menu.addItem(withTitle: "Chiikawa Desktop Pets", action: nil, keyEquivalent: "")
        menu.addItem(.separator())

        let openPicker = NSMenuItem(title: "캐릭터 선택 열기", action: #selector(openPicker), keyEquivalent: "")
        openPicker.target = self
        menu.addItem(openPicker)
        menu.addItem(.separator())

        for species in PetCatalog.all {
            let menuItem = NSMenuItem(
                title: species.displayName,
                action: #selector(toggleFromMenu(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.state = activeSpeciesIDs.contains(species.id) ? .on : .off
            menuItem.representedObject = species
            menu.addItem(menuItem)
        }

        menu.addItem(.separator())
        let scatterItem = NSMenuItem(title: "다시 흩뿌리기", action: #selector(scatter), keyEquivalent: "r")
        scatterItem.target = self
        menu.addItem(scatterItem)

        let clearItem = NSMenuItem(title: "모두 치우기", action: #selector(clearAll), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        item.menu = menu
    }

    @objc private func openPicker() {
        WindowOpener.open?()
    }

    @objc private func toggleFromMenu(_ sender: NSMenuItem) {
        guard let species = sender.representedObject as? PetSpecies else { return }
        toggle(species)
    }

    @objc private func scatter() {
        scatterActive()
    }

    @objc private func clearAll() {
        removeAll()
    }
}
