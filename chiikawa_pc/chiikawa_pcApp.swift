//
//  chiikawa_pcApp.swift
//  chiikawa_pc
//
//  Created by 정가연 on 10/22/26.
//

import SwiftUI

@main
struct chiikawa_pcApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup(id: "picker") {
            ContentView()
                .environmentObject(appDelegate.petManager)
        }
        .windowResizability(.contentSize)
    }
}
