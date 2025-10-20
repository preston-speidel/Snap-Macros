//
//  ViewModels.swift
//  Snap Macros
//

import SwiftUI
import Combine
import UIKit
import Foundation

final class GoalsViewModel: ObservableObject {
    @Published var goals: MacroGoals = {
        // Load from UserDefaults if present; else defaults
        if let data = UserDefaults.standard.data(forKey: "goals"),
           let g = try? JSONDecoder().decode(MacroGoals.self, from: data) {
            return g
        }
        return MockData.sampleGoals
    }() {
        didSet { save() }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.setValue(data, forKey: "goals")
        }
    }
}

final class TodayViewModel: ObservableObject {
    // Running totals for today (updates when user taps "Add Macros")
    @Published var calories = 0
    @Published var protein = 0
    @Published var carbs = 0
    @Published var fats = 0

    // Today’s feed of meals with images
    @Published var todayMeals: [MealEstimate] = []

    // Fake seed so the UI shows content at milestone time
    func seedFake() {
        if todayMeals.isEmpty {
            todayMeals = [MockData.sampleEstimate]
            addToTotals(MockData.sampleEstimate)
        }
    }

    func addToTotals(_ est: MealEstimate) {
        calories += est.calories
        protein += est.protein
        carbs += est.carbs
        fats += est.fats
    }

    func resetForNewDay() {
        // Photos are dropped (imageData) by letting todayMeals go empty
        todayMeals = []
        calories = 0; protein = 0; carbs = 0; fats = 0
    }
}

final class HistoryViewModel: ObservableObject {
    // Numeric-only persistent totals — fake data for milestone
    @Published var pastDays: [DayTotals] = MockData.sampleHistory

    func appendYesterdayFrom(today: TodayViewModel) {
        let yesterday = DayTotals(date: Date(), calories: today.calories, protein: today.protein, carbs: today.carbs, fats: today.fats)
        pastDays.insert(yesterday, at: 0)
    }
}

final class CameraViewModel: ObservableObject {
    @Published var capturedImage: UIImage? = nil
    @Published var showCamera = false
}

final class AnalysisViewModel: ObservableObject {
    @Published var lastEstimate: MealEstimate? = nil
    @Published var isAnalyzing = false
    @Published var errorMessage: String? = nil

    // MARK: Placeholder that fakes a result now
    func analyze(image: UIImage) {
        isAnalyzing = true
        errorMessage = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            var est = MockData.sampleEstimate
            est.imageData = image.jpegData(compressionQuality: 0.6)
            est.timestamp = Date()
            self.lastEstimate = est
            self.isAnalyzing = false
        }
    }

    // MARK: REAL API CALL goes here
    // TODO: Replace `analyze(image:)` body with network call to your chosen vision API
    // 1) JPEG compress -> Data
    // 2) Build multipart/form-data or base64 JSON as required by the API
    // 3) Send with URLSession, handle errors/timeouts
    // 4) Parse (title, calories, protein, carbs, fats, breakdown) into `MealEstimate`
}
