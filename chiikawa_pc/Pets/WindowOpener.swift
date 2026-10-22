//
//  WindowOpener.swift
//  chiikawa_pc
//
//  Lets AppKit code (the menu bar) reopen the SwiftUI picker window even
//  after the user has closed it, by capturing SwiftUI's `openWindow`
//  action once ContentView appears.
//

import Foundation

enum WindowOpener {
    static var open: (() -> Void)?
}
