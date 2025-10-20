import SwiftUI

struct ConfirmAnalysisSheet: View {
    let estimate: MealEstimate
    var onClose: (_ confirmed: Bool) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        if let data = estimate.imageData, let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable().scaledToFill()
                                .frame(width: 84, height: 84)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(estimate.title).font(.headline)
                            Text("\(estimate.calories) kcal • P \(estimate.protein)g • C \(estimate.carbs)g • F \(estimate.fats)g")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                Section("Detected items (editable later in Stretch Goals)") {
                    ForEach(estimate.items) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                            Text("\(item.grams) g • \(item.calories) kcal • P \(item.protein)g • C \(item.carbs)g • F \(item.fats)g")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Confirm")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onClose(false) }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Macros") { onClose(true) }.bold()
                }
            }
        }
    }
}
