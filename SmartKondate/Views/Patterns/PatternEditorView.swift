//
//  PatternEditorView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

struct PatternEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var patternToEdit: KondatePattern?

    @State private var name: String = ""
    @State private var durationDays: Int = 7
    @State private var isActive: Bool = false

    let durationOptions = [3, 5, 7, 10, 14, 21, 28]

    init(patternToEdit: KondatePattern? = nil) {
        self.patternToEdit = patternToEdit
        if let pattern = patternToEdit {
            _name = State(initialValue: pattern.name)
            _durationDays = State(initialValue: pattern.durationDays)
            _isActive = State(initialValue: pattern.isActive)
        }
    }

    var body: some View {
        Form {
            Section(header: Text("Pattern Details")) {
                TextField("Pattern Name (e.g. Summer Cycle)", text: $name)
                
                Picker("Cycle Duration", selection: $durationDays) {
                    ForEach(durationOptions, id: \.self) { days in
                        Text("\(days) Days").tag(days)
                    }
                }
            }

            Section {
                Toggle("Set as Active Pattern", isOn: $isActive)
            } footer: {
                Text("Activating this pattern will use it on your Dashboard.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(patternToEdit == nil ? "New Pattern" : "Edit Pattern")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    savePattern()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func savePattern() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if isActive {
            // 他のすべてのパターンのアクティブフラグを落とす
            let fetchDescriptor = FetchDescriptor<KondatePattern>()
            if let allPatterns = try? modelContext.fetch(fetchDescriptor) {
                for p in allPatterns { p.isActive = false }
            }
        }

        if let existing = patternToEdit {
            existing.name = trimmedName
            existing.durationDays = durationDays
            existing.isActive = isActive
            
            // 日数が減った場合、範囲外となった PatternDay を削除
            let daysToRemove = existing.days.filter { $0.dayIndex >= durationDays }
            for day in daysToRemove {
                modelContext.delete(day)
            }
        } else {
            let newPattern = KondatePattern(name: trimmedName, durationDays: durationDays, isActive: isActive)
            modelContext.insert(newPattern)
            
            // 初期 PatternDay 群を生成して紐付け
            for index in 0..<durationDays {
                let day = PatternDay(dayIndex: index)
                day.pattern = newPattern
                modelContext.insert(day)
            }
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        PatternEditorView()
    }
    .modelContainer(for: [KondatePattern.self, PatternDay.self], inMemory: true)
}
