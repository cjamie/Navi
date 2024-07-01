//
//  NaviApp.swift
//  Navi
//
//  Created by Jamie Chu on 6/28/24.
//

import SwiftUI

@main
struct NaviApp: App {
    var body: some Scene {
        WindowGroup {
//            ContentView()
            ScenarioOne(viewModel: .init(state: .mock))
//            ScenarioTwo.init(viewModel: .init())
        }
    }
}
