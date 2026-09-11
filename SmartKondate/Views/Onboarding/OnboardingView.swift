//
//  OnboardingView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var currentPage = 0
    @State private var usePresetData: Bool = false
    @State private var selectedPreset: PresetType = .standard

    private let pages: [OnboardingPageModel] = [
        OnboardingPageModel(
            title: "Manage Meal Patterns",
            description: "Set up custom meal cycles once, and let the app automate your daily menu planning.",
            imageName: "calendar.day.timeline.left",
            color: .blue
        ),
        OnboardingPageModel(
            title: "Flexible Replacements",
            description: "Change today's menu on the fly without breaking your base pattern schedule.",
            imageName: "arrow.triangle.2.circlepath",
            color: .orange
        ),
        OnboardingPageModel(
            title: "Smart Shopping List",
            description: "Automatically aggregate required ingredients and highlight customized changes clearly.",
            imageName: "cart.fill",
            color: .green
        )
    ]

    var body: some View {
        VStack {
            // MARK: - Skip Button
            HStack {
                Spacer()
                if currentPage < pages.count {
                    Button("Skip") {
                        completeOnboarding(loadPresets: false)
                    }
                    .foregroundStyle(.secondary)
                    .padding()
                }
            }

            // MARK: - TabView (Pages)
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    let page = pages[index]
                    VStack(spacing: 24) {
                        Image(systemName: page.imageName)
                            .font(.system(size: 80))
                            .foregroundStyle(page.color)
                            .padding()

                        Text(page.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text(page.description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 32)
                    }
                    .tag(index)
                }

                // Page 4: Sample Data Option
                VStack(spacing: 20) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.purple)
                        .padding()

                    Text("Sample Data Options")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text("Would you like to start with pre-filled sample meal patterns, recipes, and stock items?")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)

                    VStack(spacing: 16) {
                        Toggle(isOn: $usePresetData.animation()) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Load Sample Data")
                                    .font(.headline)
                                Text(usePresetData ? "Starts with chosen sample pattern." : "Starts with a clean, empty app.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if usePresetData {
                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Select Preset Type")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)

                                Picker("Preset Type", selection: $selectedPreset) {
                                    ForEach(PresetType.allCases) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 32)
                }
                .tag(pages.count)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Spacer()

            // MARK: - Action Button
            Button {
                if currentPage < pages.count {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    completeOnboarding(loadPresets: usePresetData)
                }
            } label: {
                Text(currentPage == pages.count ? "Get Started" : "Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func completeOnboarding(loadPresets: Bool) {
        if loadPresets {
            PresetDataService.insertPresetDataIfNeeded(context: modelContext, presetType: selectedPreset)
        }
        hasCompletedOnboarding = true
    }
}

// MARK: - Page Model Definition
private struct OnboardingPageModel {
    let title: String
    let description: String
    let imageName: String
    let color: Color
}

#Preview {
    OnboardingView()
        .modelContainer(for: [KondatePattern.self, PatternDay.self, Menu.self, Ingredient.self, StockItem.self], inMemory: true)
}
