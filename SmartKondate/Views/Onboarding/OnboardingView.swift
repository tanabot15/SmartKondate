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

    private let pages: [OnboardingPageModel] = [
        OnboardingPageModel(
            title: "Manage Meal Patterns",
            description: "Set up 7-day or custom meal cycles once, and let the app automate your daily menu planning.",
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
            HStack {
                Spacer()
                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundStyle(.secondary)
                    .padding()
                }
            }

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
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Spacer()

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
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

    private func completeOnboarding() {
        PresetDataService.insertPresetDataIfNeeded(context: modelContext)
        hasCompletedOnboarding = true
    }
}

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
