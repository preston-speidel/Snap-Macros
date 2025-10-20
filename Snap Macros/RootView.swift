//
//  RootView.swift
//  Snap Macros
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            TodayFeedView()
                .tabItem { Label("Today", systemImage: "photo.on.rectangle") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            GoalsView()
                .tabItem { Label("Goals", systemImage: "target") }
        }
    }
}
