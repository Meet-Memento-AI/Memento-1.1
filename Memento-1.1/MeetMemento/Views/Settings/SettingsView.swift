//
//  SettingsView.swift
//  MeetMemento
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var entryViewModel: EntryViewModel

    @State private var showDataUsageInfo = false

    var body: some View {
        VStack(spacing: 0) {
            // Secondary Header
            Header(
                title: "Settings",
                onBackTapped: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Appearance Section
                    appearanceSection

                    // About Section
                    aboutSection

                    // Data & Privacy Section
                    dataPrivacySection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .background(theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showDataUsageInfo) {
            NavigationStack {
                DataUsageInfoView()
                    .useTheme()
                    .useTypography()
            }
        }
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Appearance")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .padding(.bottom, 4)

            // Section content card
            VStack(spacing: 0) {
                NavigationLink(value: SettingsRoute.appearance) {
                    SettingsRow(
                        icon: "paintbrush.fill",
                        title: "Theme & Display",
                        subtitle: "Customize colors and text size",
                        showChevron: true,
                        action: nil
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(BaseColors.white)
            .cornerRadius(16)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("About")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .padding(.bottom, 4)

            // Section content card
            VStack(spacing: 0) {
                NavigationLink(value: SettingsRoute.about) {
                    SettingsRow(
                        icon: "info.circle.fill",
                        title: "About MeetMemento",
                        subtitle: "Version, legal, and support",
                        showChevron: true,
                        action: nil
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(BaseColors.white)
            .cornerRadius(16)
        }
    }

    private var dataPrivacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Data & Privacy")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .padding(.bottom, 4)

            // Section content card
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "hand.raised",
                    title: "Privacy Policy",
                    subtitle: "How we protect your data",
                    showChevron: true,
                    action: {
                        if let url = URL(string: "https://sebmendo1.github.io/MeetMemento/privacy.html") {
                            UIApplication.shared.open(url)
                        }
                    }
                )

                Divider()
                    .background(theme.border)
                    .padding(.horizontal, 16)

                SettingsRow(
                    icon: "info.circle",
                    title: "What Data We Collect",
                    subtitle: "Learn about data usage",
                    showChevron: true,
                    action: {
                        print("Settings")
                    }
                )
            }
            .background(BaseColors.white)
            .cornerRadius(16)
        }
    }


    // MARK: - Actions
}

// MARK: - ShareSheet Helper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // iPad popover configuration (required to prevent crash on iPad)
        if let popover = controller.popoverPresentationController {
            // Get the window scene to find a source view
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootView = window.rootViewController?.view {
                popover.sourceView = rootView
                popover.sourceRect = CGRect(x: rootView.bounds.midX, y: rootView.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(EntryViewModel())
            .useTheme()
            .useTypography()
    }
}
