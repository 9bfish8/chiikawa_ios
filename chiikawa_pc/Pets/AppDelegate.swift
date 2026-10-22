//
//  AppDelegate.swift
//  chiikawa_pc
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let petManager = PetManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        petManager.setUpMenuBar()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
