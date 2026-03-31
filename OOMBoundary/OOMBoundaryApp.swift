//
//  OOMBoundaryApp.swift
//  OOMBoundary
//
//  Created by Katsumasa Kimura on 2026/03/31.
//

import SwiftUI

@main
struct OOMBoundaryApp: App {
    init() {
        // MetricKitレポーターを初期化
        _ = MetricReporter.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
