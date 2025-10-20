//
//  HomeView.swift
//  Snap Macros
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var goalsVM: GoalsViewModel
    @EnvironmentObject var todayVM: TodayViewModel
    @EnvironmentObject var cameraVM: CameraViewModel
    @EnvironmentObject var analysisVM: AnalysisViewModel

    @State private var showConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    RingGrid(goals: goalsVM.goals,
                             totals: (todayVM.calories, todayVM.protein, todayVM.carbs, todayVM.fats))
                        .padding(.top, 8)

                    Button(action: { cameraVM.showCamera = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                            Text("Snap Meal")
                                .font(.title2).bold()
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)

                    if analysisVM.isAnalyzing {
                        ProgressView("Analyzing…")
                            .padding(.top, 8)
                    }

                    // Short Today preview
                    TodayPreview()
                        .padding(.horizontal)
                }
                .onAppear { todayVM.seedFake() }
            }
            .navigationTitle("SnapMacros")
            .sheet(isPresented: $cameraVM.showCamera) {
                CameraCaptureView(image: $cameraVM.capturedImage)
                    .ignoresSafeArea()
            }
            .onChange(of: cameraVM.capturedImage) { _, newImage in
                guard let img = newImage else { return }
                analysisVM.analyze(image: img) // fake now, real later
                showConfirm = true
            }
            .sheet(isPresented: $showConfirm) {
                if let est = analysisVM.lastEstimate {
                    ConfirmAnalysisSheet(estimate: est) { confirmed in
                        if confirmed {
                            todayVM.todayMeals.insert(est, at: 0)
                            todayVM.addToTotals(est)
                        }
                        showConfirm = false
                    }
                    .presentationDetents([.medium, .large])
                }
            }
        }
    }
}

struct TodayPreview: View {
    @EnvironmentObject var todayVM: TodayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today’s Meals")
                    .font(.headline)
                Spacer()
                NavigationLink("View All") { TodayFeedView() }
            }
            .padding(.horizontal, 4)

            ForEach(todayVM.todayMeals.prefix(3)) { meal in
                MealRow(meal: meal)
            }
        }
    }
}

struct TodayFeedView: View {
    @EnvironmentObject var todayVM: TodayViewModel

    var body: some View {
        List {
            Section("Today") {
                ForEach(todayVM.todayMeals) { meal in
                    MealRow(meal: meal)
                }
            }
        }
        .navigationTitle("Today")
        .onAppear { todayVM.seedFake() }
    }
}

struct MealRow: View {
    let meal: MealEstimate

    var body: some View {
        HStack(spacing: 12) {
            if let data = meal.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.15))
                    Image(systemName: "photo")
                }
                .frame(width: 64, height: 64)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.title).font(.headline)
                Text("\(meal.calories) kcal • P \(meal.protein)g • C \(meal.carbs)g • F \(meal.fats)g")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(meal.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
