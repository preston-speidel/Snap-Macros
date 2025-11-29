//
//  HomeView.swift
//  Snap Macros
//

import SwiftUI

private enum ActiveSheet: Identifiable { case camera, confirm; var id: Int { hashValue } }

struct HomeView: View {
    @EnvironmentObject var goalsVM: GoalsViewModel
    @EnvironmentObject var todayVM: TodayViewModel
    @EnvironmentObject var cameraVM: CameraViewModel
    @EnvironmentObject var analysisVM: AnalysisViewModel

    @State private var activeSheet: ActiveSheet?
    @State private var showErrorAlert = false
    @State private var showManualEntry = false
    
    @State private var showUsageAlert = false
    private let dailyLimit = 10

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    RingGrid(goals: MacroGoals(calories: goalsVM.goals.calories,
                                               protein: goalsVM.goals.protein,
                                               carbs: goalsVM.goals.carbs,
                                               fats: goalsVM.goals.fats),
                             totals: (todayVM.calories, todayVM.protein, todayVM.carbs, todayVM.fats))
                        .padding(.top, 8)

                    Button {
                        if !todayVM.canSnapAI(limit: dailyLimit) {
                            showUsageAlert = true
                            return
                        }
                        activeSheet = .camera
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                            Text("Snap Meal").font(.title2).bold()
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)

                    Button {
                        showManualEntry = true
                    } label: {
                        Text("Manual Entry")
                            .font(.subheadline).bold()
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered) // smaller, secondary style
                    .padding(.horizontal)

                    TodayPreview()
                        .padding(.horizontal)
                }
                .onAppear {
                    todayVM.rolloverIfNeeded()
                }            }
            .navigationTitle("AIMacros")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showUsageAlert = true
                    } label: {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                    }
                    .accessibilityLabel("Usage Information")
                }
            }

            // Full-screen analyzing overlay
            .overlay {
                if analysisVM.isAnalyzing {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()
                        VStack(spacing: 10) {
                            ProgressView()
                            Text("Analyzing…").font(.headline)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .transition(.opacity)
                }
            }

            // One unified sheet
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .camera:
                    CameraCaptureView(image: $cameraVM.capturedImage)
                        .ignoresSafeArea()
                        .onDisappear {
                            guard let img = cameraVM.capturedImage else { return }
                            Task { @MainActor in
                                await analysisVM.analyze(image: img)

                                if analysisVM.lastEstimate != nil {
                                    todayVM.recordAIUsage()
                                    // success → show confirm after picker fully dismisses
                                    try? await Task.sleep(nanoseconds: 150_000_000)
                                    activeSheet = .confirm
                                } else if analysisVM.errorMessage != nil {
                                    // failure → show alert; keep captured image so user can retry
                                    showErrorAlert = true
                                    activeSheet = nil
                                }
                            }
                        }

                case .confirm:
                    if let est = analysisVM.lastEstimate {
                        ConfirmAnalysisSheet(estimate: est) { didConfirm, calories, protein, carbs, fats in
                            if didConfirm {
                                let adjusted = MealEstimate(
                                    title: est.title,
                                    calories: calories,
                                    protein: protein,
                                    carbs: carbs,
                                    fats: fats,
                                    items: est.items,
                                    imageData: est.imageData,
                                    timestamp: est.timestamp
                                )
                                todayVM.add(estimate: adjusted)
                            }
                            analysisVM.clear()
                            cameraVM.capturedImage = nil
                            activeSheet = nil
                        }
                        //.presentationDetents([.large, .medium])
                        .presentationDetents([.large])
                        .interactiveDismissDisabled(true)
                    } else {
                        Color.clear.onAppear { activeSheet = nil }
                    }
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualEntrySheet { name, cals, prot, carbs, fats in
                    // Build a MealEstimate from manual values (defaults handled in sheet)
                    let estimate = MealEstimate(
                        title: name.isEmpty ? "Meal" : name,
                        calories: cals,
                        protein: prot,
                        carbs: carbs,
                        fats: fats,
                        items: [],
                        imageData: nil,
                        timestamp: Date()
                    )
                    todayVM.add(estimate: estimate)
                    showManualEntry = false
                } onCancel: {
                    showManualEntry = false
                }
                .presentationDetents([.large])
            }

            // Error alert on failures (no key / no network / server)
            .alert("Unable to analyze", isPresented: $showErrorAlert, actions: {
                Button("Retry") {
                    guard let img = cameraVM.capturedImage else { return }
                    Task { @MainActor in
                        await analysisVM.analyze(image: img)

                        if analysisVM.lastEstimate != nil {
                            todayVM.recordAIUsage()
                            // on success, show the confirm sheet
                            try? await Task.sleep(nanoseconds: 150_000_000)
                            activeSheet = .confirm
                        } else if analysisVM.errorMessage != nil {
                            // still failing → show alert again
                            showErrorAlert = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    analysisVM.clear()
                    cameraVM.capturedImage = nil
                }
            }, message: {
                Text(analysisVM.errorMessage ?? "Please try again later.")
            })
            
            .alert(todayVM.aiPhotosUsed >= dailyLimit ? "Daily limit reached" : "AI Photos",
                   isPresented: $showUsageAlert,
                   actions: {
                       Button("OK", role: .cancel) { }
                   },
                   message: {
                       Text("\(todayVM.aiPhotosUsed)/\(dailyLimit) AI photos used today. The limit resets at midnight.")
                   })
        }
    }
}

// MARK: - Today preview & list

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
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.15))
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
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Manual Entry Sheet

struct ManualEntrySheet: View {
    var onSave: (_ name: String, _ calories: Int, _ protein: Int, _ carbs: Int, _ fats: Int) -> Void
    var onCancel: () -> Void

    @State private var name: String = ""
    @State private var caloriesText: String = ""
    @State private var proteinText: String = ""
    @State private var carbsText: String = ""
    @State private var fatsText: String = ""

    @FocusState private var focusedField: Field?

    private enum Field {
        case name, calories, protein, carbs, fats
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Name (optional)", text: $name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.done)
                }
                Section(header: Text("Macros")) {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("", text: $caloriesText, prompt: Text("0"))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                            .focused($focusedField, equals: .calories)
                    }
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("", text: $proteinText, prompt: Text("0"))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                            .focused($focusedField, equals: .protein)
                    }
                    HStack {
                        Text("Carbs (g)")
                        Spacer()
                        TextField("", text: $carbsText, prompt: Text("0"))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                            .focused($focusedField, equals: .carbs)
                    }
                    HStack {
                        Text("Fats (g)")
                        Spacer()
                        TextField("", text: $fatsText, prompt: Text("0"))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                            .focused($focusedField, equals: .fats)
                    }
                    Text("Leave any field blank to use 0.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Manual Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        focusedField = nil
                        let c = Int(caloriesText.trimmingCharacters(in: .whitespaces)) ?? 0
                        let p = Int(proteinText.trimmingCharacters(in: .whitespaces)) ?? 0
                        let cb = Int(carbsText.trimmingCharacters(in: .whitespaces)) ?? 0
                        let f = Int(fatsText.trimmingCharacters(in: .whitespaces)) ?? 0
                        let nm = name.trimmingCharacters(in: .whitespaces)
                        onSave(nm, c, p, cb, f)
                    }
                    .bold()
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .bold()
                }
            }
        }
    }
}
