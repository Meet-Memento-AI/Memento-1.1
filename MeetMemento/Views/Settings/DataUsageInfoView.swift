//
//  DataUsageInfoView.swift
//  MeetMemento
//
//  Information about what data is collected and how it's used
//  Required for iOS App Store transparency
//

import SwiftUI

public struct DataUsageInfoView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 16)

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Collection")
                        .font(type.h3)
                        .headerGradient()

                    Text("What we collect and why")
                        .font(type.body1)
                        .foregroundStyle(theme.mutedForeground)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                // Data We Collect Section
                dataCollectionSection

                // How We Use Data Section
                dataUsageSection

                // Data Storage Section
                dataStorageSection

                // Your Rights Section
                yourRightsSection

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Data Usage")
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
    }

    // MARK: - Sections

    private var dataCollectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What We Collect")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 16) {
                DataItem(
                    icon: "doc.text.fill",
                    title: "Journal Entries",
                    description: "Your journal entries, including titles, content, and dates. This is the core data you create in MeetMemento."
                )

                Divider()
                    .background(theme.border)
                    .padding(.horizontal, 16)

                DataItem(
                    icon: "sparkles",
                    title: "Insights",
                    description: "AI-generated insights based on your journal entries to help you reflect on patterns and growth."
                )

                Divider()
                    .background(theme.border)
                    .padding(.horizontal, 16)

                DataItem(
                    icon: "person.circle.fill",
                    title: "Account Information",
                    description: "Your email address and authentication tokens to secure your account and data."
                )
            }
            .padding(.vertical, 12)
            .background(BaseColors.white)
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }

    private var dataUsageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How We Use Your Data")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 16) {
                DataItem(
                    icon: "cloud.fill",
                    title: "Sync Across Devices",
                    description: "Your data is stored securely in the cloud so you can access your journal from any device."
                )

                Divider()
                    .background(theme.border)
                    .padding(.horizontal, 16)

                DataItem(
                    icon: "brain.head.profile",
                    title: "Generate Insights",
                    description: "We use AI to analyze your entries and provide personalized insights about your patterns and growth."
                )

                Divider()
                    .background(theme.border)
                    .padding(.horizontal, 16)

                DataItem(
                    icon: "shield.fill",
                    title: "Account Security",
                    description: "Your email and authentication data are used solely to secure your account and prevent unauthorized access."
                )
            }
            .padding(.vertical, 12)
            .background(BaseColors.white)
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }

    private var dataStorageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Storage")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 16) {
                DataItem(
                    icon: "lock.shield.fill",
                    title: "Encrypted & Secure",
                    description: "All data is encrypted in transit and at rest using industry-standard encryption protocols."
                )

                Divider()
                    .background(theme.border)
                    .padding(.horizontal, 16)

                DataItem(
                    icon: "server.rack",
                    title: "Secure Cloud Storage",
                    description: "Your data is stored on secure Supabase servers with robust backup and disaster recovery systems."
                )

                Divider()
                    .background(theme.border)
                    .padding(.horizontal, 16)

                DataItem(
                    icon: "eye.slash.fill",
                    title: "Private by Default",
                    description: "Your journal entries are completely private. We never share, sell, or use your personal data for advertising."
                )
            }
            .padding(.vertical, 12)
            .background(BaseColors.white)
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }

    private var yourRightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Rights")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 16) {
                DataItem(
                    icon: "trash.fill",
                    title: "Delete Your Account",
                    description: "You can permanently delete your account and all associated data at any time from Settings."
                )

                Divider()
                    .background(theme.border)
                    .padding(.horizontal, 16)

                DataItem(
                    icon: "questionmark.circle.fill",
                    title: "Contact Us",
                    description: "For any privacy questions or data requests, contact support@sebastianmendo.com"
                )
            }
            .padding(.vertical, 12)
            .background(BaseColors.white)
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Data Item Component

private struct DataItem: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(theme.primary)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.foreground)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Previews

#Preview("Light") {
    NavigationStack {
        DataUsageInfoView()
            .useTheme()
            .useTypography()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        DataUsageInfoView()
            .useTheme()
            .useTypography()
    }
    .preferredColorScheme(.dark)
}
