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
        //load from UserDefaults if present else use the defaults
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
    //running totals for today (updates when user taps "Add Macros")
    @Published var calories = 0
    @Published var protein = 0
    @Published var carbs = 0
    @Published var fats = 0

    //today’s feed of meals with images
    @Published var todayMeals: [MealEstimate] = []

    //fake seed so the UI shows content
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
        //photos are dropped (imageData) by letting todayMeals go empty
        todayMeals = []
        calories = 0; protein = 0; carbs = 0; fats = 0
    }
}

final class HistoryViewModel: ObservableObject {
    //numeric only persistent totals — fake data
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

    //Todo AI API CAll
}
