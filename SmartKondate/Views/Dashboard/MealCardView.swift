//
//  MealCardView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

struct MealCardView: View {
    let diffResult: MealDiffResult
    let availableMenus: [Menu]
    let onSelectMenu: (Menu?) -> Void

    @State private var isShowingPickerSheet = false

    private var iconName: String {
        switch diffResult.mealType {
        case .breakfast: return "sun.max.fill"
        case .lunch: return "sun.headline.fill"
        case .dinner: return "moon.stars.fill"
        }
    }

    private var iconColor: Color {
        switch diffResult.mealType {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .indigo
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label {
                    Text(diffResult.mealType.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: iconName)
                        .foregroundStyle(iconColor)
                }

                if diffResult.isModified {
                    Text("Modified")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }

                Spacer()

                Button("Change") {
                    isShowingPickerSheet = true
                }
                .font(.subheadline)
            }

            Divider()

            if let menu = diffResult.effectiveMenu {
                VStack(alignment: .leading, spacing: 6) {
                    Text(menu.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    if !menu.ingredients.isEmpty {
                        Text(menu.ingredients.map { $0.name }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("No ingredients specified")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            } else {
                Text("No menu assigned")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $isShowingPickerSheet) {
            NavigationStack {
                List {
                    Section {
                        Button("None / Clear") {
                            onSelectMenu(nil)
                            isShowingPickerSheet = false
                        }
                        .foregroundStyle(.red)
                    }

                    Section(header: Text("Select Menu")) {
                        ForEach(availableMenus) { menu in
                            Button {
                                onSelectMenu(menu)
                                isShowingPickerSheet = false
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(menu.name)
                                            .foregroundStyle(.primary)
                                        Text(menu.category)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if diffResult.effectiveMenu?.id == menu.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("\(diffResult.mealType.rawValue) Menu")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isShowingPickerSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    let sampleMenu = Menu(name: "Grilled Salmon", category: "Main")
    let result = MealDiffResult(mealType: .dinner, defaultMenu: sampleMenu, customMenu: nil)
    
    return MealCardView(diffResult: result, availableMenus: [sampleMenu], onSelectMenu: { _ in })
        .padding()
        .background(Color(.systemGroupedBackground))
}
