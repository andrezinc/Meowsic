//
//  MeowdiboxApp.swift
//  Meowdibox
//
//  Created by Andre Castilhano on 16/03/26.
//

import SwiftUI

@main
struct MeowdiboxApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HomeScreen()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            ReviewRequestManager.shared.appDidBecomeActive()
        }
    }
}
