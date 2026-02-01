//
//  AppearanceSettingsView.swift
//  MeetMemento
//
//  Customize app theme and display settings
//

import SwiftUI

public struct AppearanceSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    @State private var selectedTheme: AppThemePreference = .system

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 16)

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appearance")
                        .font(type.h3)
                        .headerGradient()

                    Text("Customize how MeetMemento looks")
                        .font(type.body1)
                        .foregroundStyle(theme.mutedForeground)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                // Theme selector section
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theme")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(theme.foreground)

                        Text("Choose your preferred color scheme")
                            .font(type.body2)
                            .foregroundStyle(theme.mutedForeground)
                    }
                    .padding(.horizontal, 16)

                    // Theme options card
                    VStack(spacing: 0) {
                        ForEach(AppThemePreference.allCases, id: \.self) { themeOption in
                            Button {
                                selectTheme(themeOption)
                            } label: {
                                HStack(spacing: 16) {
                                    // Icon
                                    Image(systemName: iconForTheme(themeOption))
                                        .font(.system(size: 20))
                                        .foregroundStyle(theme.primary)
                                        .frame(width: 28, height: 28)

                                    // Title and description
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(themeOption.displayName)
                                            .font(type.body1)
                                            .foregroundStyle(theme.foreground)

                                        Text(descriptionForTheme(themeOption))
                                            .font(.system(size: 14))
                                            .foregroundStyle(theme.mutedForeground)
                                    }

                                    Spacer()

                                    // Checkmark for selected
                                    if selectedTheme == themeOption {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(theme.primary)
                                    } else {
                                        Image(systemName: "circle")
                                            .font(.system(size: 20))
                                            .foregroundStyle(theme.mutedForeground.opacity(0.3))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Divider between options (not after last one)
                            if themeOption != AppThemePreference.allCases.last {
                                Divider()
                                    .background(theme.border)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(BaseColors.white)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                IconButtonNav(
                    icon: "chevron.left",
                    iconSize: 18,
                    buttonSize: 40,
                    enableHaptic: true,
                    onTap: { dismiss() }
                )
            }
        }
        .onAppear {
            loadCurrentTheme()
        }
    }

    // MARK: - Actions

    private func loadCurrentTheme() {
        selectedTheme = PreferencesService.shared.themePreference
    }

    private func selectTheme(_ themeOption: AppThemePreference) {
        selectedTheme = themeOption
        PreferencesService.shared.themePreference = themeOption

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Helper Methods

    private func iconForTheme(_ themeOption: AppThemePreference) -> String {
        switch themeOption {
        case .system:
            return "gear"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }

    private func descriptionForTheme(_ themeOption: AppThemePreference) -> String {
        switch themeOption {
        case .system:
            return "Match your device settings"
        case .light:
            return "Always use light mode"
        case .dark:
            return "Always use dark mode"
        }
    }
}

#Preview("Light") {
    NavigationStack {
        AppearanceSettingsView()
            .useTheme()
            .useTypography()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        AppearanceSettingsView()
            .useTheme()
            .useTypography()
    }
    .preferredColorScheme(.dark)
}
