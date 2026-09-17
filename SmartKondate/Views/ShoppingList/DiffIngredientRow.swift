//
//  DiffIngredientRow.swift
//  SmartKondate
//

import SwiftUI

struct DiffIngredientRow: View {
    let ingredientName: String
    let quantity: Double
    let unit: String
    let menuDetails: String
    let isModifiedMeal: Bool
    let isChecked: Bool
    let onToggle: () -> Void
    let onQuantityChange: (Double) -> Void

    @State private var showEditPopover = false
    @State private var editingText = ""

    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Check Status
            Button(action: onToggle) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)

            // MARK: - Ingredient Details
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(ingredientName)
                        .font(.body)
                        .fontWeight(isModifiedMeal ? .bold : .regular)
                        .foregroundStyle(isChecked ? .secondary : .primary)
                        .strikethrough(isChecked)

                    if isModifiedMeal {
                        Text("Changed")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }

                if !menuDetails.isEmpty {
                    Text(menuDetails)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // MARK: - Tap to Edit Quantity (Clean Badge Style)
            Button {
                editingText = formatQuantity(quantity)
                showEditPopover = true
            } label: {
                HStack(spacing: 3) {
                    Text(formatQuantity(quantity))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(isChecked ? .secondary : Color.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showEditPopover) {
                QuantityEditPopover(
                    ingredientName: ingredientName,
                    unit: unit,
                    quantityText: $editingText,
                    onSave: { newQty in
                        onQuantityChange(newQty)
                        showEditPopover = false
                    }
                )
                .presentationCompactAdaptation(.popover)
            }
        }
        .padding(.vertical, 2)
    }

    private func formatQuantity(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", val)
        } else {
            return String(format: "%.1f", val)
        }
    }
}

// MARK: - Quantity Edit Popover Component
private struct QuantityEditPopover: View {
    let ingredientName: String
    let unit: String
    @Binding var quantityText: String
    let onSave: (Double) -> Void

    @FocusState private var isTextFieldFocused: Bool

    // 単位に応じた最適なステップ幅の算出
    private var stepAmount: Double {
        let u = unit.lowercased().trimmingCharacters(in: .whitespaces)
        if u == "g" || u == "ml" {
            return 50.0
        } else if u == "kg" || u == "l" {
            return 0.1
        } else {
            return 1.0
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(ingredientName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            // MARK: - Unified Input ( - [TextField] + )
            HStack(spacing: 12) {
                Button {
                    adjustAmount(by: -stepAmount)
                } label: {
                    Image(systemName: "minus")
                        .font(.body.bold())
                        .frame(width: 36, height: 36)
                        .background(Color(.secondarySystemFill))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                HStack(spacing: 4) {
                    TextField("0", text: $quantityText)
                        .keyboardType(.decimalPad)
                        .focused($isTextFieldFocused)
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(minWidth: 50, maxWidth: 90)

                    if !unit.isEmpty {
                        Text(unit)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    adjustAmount(by: stepAmount)
                } label: {
                    Image(systemName: "plus")
                        .font(.body.bold())
                        .frame(width: 36, height: 36)
                        .background(Color(.secondarySystemFill))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            // MARK: - Save Action
            Button {
                if let val = Double(quantityText) {
                    onSave(max(0, val))
                }
            } label: {
                Text("Done")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .frame(minWidth: 220)
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private func adjustAmount(by delta: Double) {
        let current = Double(quantityText) ?? 0
        let newAmount = max(0, current + delta)
        quantityText = newAmount.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", newAmount)
            : String(format: "%.1f", newAmount)
    }
}

#Preview {
    VStack(spacing: 16) {
        DiffIngredientRow(
            ingredientName: "Pork Slice",
            quantity: 200,
            unit: "g",
            menuDetails: "Pork Ginger (Standard)",
            isModifiedMeal: false,
            isChecked: false,
            onToggle: {},
            onQuantityChange: { _ in }
        )
        
        DiffIngredientRow(
            ingredientName: "Salmon Fillet",
            quantity: 2,
            unit: "pcs",
            menuDetails: "Grilled Salmon (Custom)",
            isModifiedMeal: true,
            isChecked: false,
            onToggle: {},
            onQuantityChange: { _ in }
        )
    }
    .padding()
    .background(Color(.secondarySystemGroupedBackground))
}
