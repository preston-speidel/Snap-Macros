import SwiftUI

struct ConfirmAnalysisSheet: View {
    @EnvironmentObject var analysisVM: AnalysisViewModel

    let estimate: MealEstimate
    let onComplete: (_ didConfirm: Bool,
                     _ calories: Int,
                     _ protein: Int,
                     _ carbs: Int,
                     _ fats: Int) -> Void   //didConfirm = true = add, false = cancel

    @State private var editedCalories: Int
    @State private var editedProtein: Int
    @State private var editedCarbs: Int
    @State private var editedFats: Int

    init(estimate: MealEstimate,
         onComplete: @escaping (_ didConfirm: Bool,
                                _ calories: Int,
                                _ protein: Int,
                                _ carbs: Int,
                                _ fats: Int) -> Void) {
        self.estimate = estimate
        self.onComplete = onComplete
        _editedCalories = State(initialValue: estimate.calories)
        _editedProtein = State(initialValue: estimate.protein)
        _editedCarbs = State(initialValue: estimate.carbs)
        _editedFats = State(initialValue: estimate.fats)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                // Error banner (if any)
                if let err = analysisVM.errorMessage, !err.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(err).font(.subheadline)
                        Spacer()
                        Button("Dismiss") {
                            onComplete(false, editedCalories, editedProtein, editedCarbs, editedFats)
                        }
                    }
                    .padding(10)
                    .background(Color.yellow.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                }

                //title at top
                VStack(spacing: 4) {
                    Text(estimate.title)
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.top, 4)

                //image (if any)
                if let data = estimate.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .padding(.top, 4)
                }

                //editable macro totals below the picture
                VStack(alignment: .leading, spacing: 12) {
                    Text("Totals")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    MacroEditRow(label: "Calories", value: $editedCalories, unit: "kcal", step: 5)
                    MacroEditRow(label: "Protein", value: $editedProtein, unit: "g")
                    MacroEditRow(label: "Carbs", value: $editedCarbs, unit: "g")
                    MacroEditRow(label: "Fats", value: $editedFats, unit: "g")
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal)
                .padding(.top, 6)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(estimate.items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.name)
                                .font(.system(size: 17, weight: .semibold))

                            HStack {
                                Text("\(item.grams) g")
                                Spacer()
                                Text("\(item.calories) kcal")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                }
                .padding(.horizontal)
                }
            }

            HStack {
                Button(role: .cancel) {
                    onComplete(false, editedCalories, editedProtein, editedCarbs, editedFats)
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    onComplete(true, editedCalories, editedProtein, editedCarbs, editedFats)
                } label: {
                    Label("Add Macros", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .padding(.top, 8)
            .background(Color(.systemBackground))
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}

struct MacroEditRow: View {
    let label: String
    @Binding var value: Int
    let unit: String
    let step: Int

    init(label: String, value: Binding<Int>, unit: String, step: Int = 1) {
        self.label = label
        self._value = value
        self.unit = unit
        self.step = step
    }

    var body: some View {
        HStack(spacing: 16) {
            Text(label)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 80, alignment: .leading)

            Spacer()

            HStack(spacing: 10) {
                Button {
                    if value - step >= 0 { value -= step }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                TextField("0", value: $value, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 70, height: 36)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    value += step
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, alignment: .leading)
            }
        }
        .padding(.vertical, 6)
    }
}
