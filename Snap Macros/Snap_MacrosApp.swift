//Snap Macros

import SwiftUI
import Combine
import UIKit

@main
struct SnapMacrosApp: App {
    @StateObject private var goalsVM = GoalsViewModel()
    @StateObject private var todayVM = TodayViewModel()
    @StateObject private var historyVM = HistoryViewModel()
    @StateObject private var cameraVM = CameraViewModel()
    @StateObject private var analysisVM = AnalysisViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(goalsVM)
                .environmentObject(todayVM)
                .environmentObject(historyVM)
                .environmentObject(cameraVM)
                .environmentObject(analysisVM)
        }
    }
}
