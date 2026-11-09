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
    var isUnbuyableMode: Bool = false
    let onToggle: () -> Void
    let onQuantityChange: (Double) -> Void

    @State private var showEditSheet = false // .popover から .sheet へ変更
    @State private var editingText = ""

    var body: some View {
        HStack(spacing: 12) {
            checkButton
            detailsView
            Spacer()
            quantityBadgeButton
        }
        .padding(.vertical, 2)
    }

    // MARK: - Subviews
    private var checkButton: some View {
        Button(action: onToggle) {
            if isUnbuyableMode {
                Image(systemName: isChecked ? "xmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? Color.red : Color.secondary)
            } else {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? Color.accentColor : Color.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(ingredientName)
                    .font(.body)
                    .fontWeight(isModifiedMeal ? .bold : .regular)
                    .foregroundStyle(isChecked ? (isUnbuyableMode ? .red : .secondary) : .primary)
                    .strikethrough(isChecked && !isUnbuyableMode)

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
    }

    private var quantityBadgeButton: some View {
        Button {
            editingText = formatQuantity(quantity)
            showEditSheet = true
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
        .sheet(isPresented: $showEditSheet) { // .popover から .sheet に変更し位置を完全に固定
            QuantityEditSheet(
                ingredientName: ingredientName,
                unit: unit,
                quantityText: $editingText,
                onSave: { newQty in
                    onQuantityChange(newQty)
                    showEditSheet = false
                }
            )
            .presentationDetents([.height(240)]) // 高さを固定してすっきりと表示
            .presentationDragIndicator(.visible)
        }
    }

    private func formatQuantity(_ val: Double) -> String {
        val.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", val) : String(format: "%.1f", val)
    }
}

// MARK: - Quantity Edit Sheet (PopoverからSheetへ移行)
private struct QuantityEditSheet: View {
    let ingredientName: String
    let unit: String
    @Binding var quantityText: String
    let onSave: (Double) -> Void

    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private var stepAmount: Double {
        switch unit.lowercased().trimmingCharacters(in: .whitespaces) {
        case "g", "ml": return 50.0
        case "kg", "l": return 0.1
        default: return 1.0
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                inputStepperRow

                Button {
                    if let val = Double(quantityText) {
                        onSave(max(0, val))
                    }
                } label: {
                    Text("Done")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding(20)
            .navigationTitle(ingredientName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }

    private var inputStepperRow: some View {
        HStack(spacing: 16) {
            Button {
                adjustAmount(by: -stepAmount)
            } label: {
                Image(systemName: "minus")
                    .font(.title3.bold())
                    .frame(width: 44, height: 44)
                    .background(Color(.secondarySystemFill))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                TextField("0", text: $quantityText)
                    .keyboardType(.decimalPad)
                    .focused($isTextFieldFocused)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(minWidth: 60, maxWidth: 100)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button {
                adjustAmount(by: stepAmount)
            } label: {
                Image(systemName: "plus")
                    .font(.title3.bold())
                    .frame(width: 44, height: 44)
                    .background(Color(.secondarySystemFill))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
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
    }
    .padding()
    .background(Color(.secondarySystemGroupedBackground))
}
