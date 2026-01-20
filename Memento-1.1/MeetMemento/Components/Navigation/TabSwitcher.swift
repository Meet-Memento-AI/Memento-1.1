//
//  TabSwitcher.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 10/1/25.
//

import SwiftUI

// MARK: - Tabs must provide a label + icon for TabPill.
public protocol LabeledTab {
    var title: String { get }
    var systemImage: String { get }
}

/// Segmented “switch” that composes TabPill(s).
/// - Selection background is a fully round Capsule with theme.accent @ 8%
/// - Smooth, attractive motion with matchedGeometry + spring
/// - Inner height fits TabPill padding so visuals align perfectly
public struct TabSwitcher<Tab: LabeledTab & CaseIterable & Hashable & Identifiable>: View
where Tab.AllCases: RandomAccessCollection {

    public let tabs: [Tab]
    @Binding public var selection: Tab

    @Environment(\.theme) private var theme
    @Namespace private var thumbNS

    // Layout + animation constants
    private let containerHeight: CGFloat = 72   // total control height
    private let trackPadding: CGFloat = 6       // inset for pills & thumb
    private let itemSpacing: CGFloat = 6        // spacing between tabs
    private let thumbSpring = Animation.spring(response: 0.30,
                                               dampingFraction: 0.86,
                                               blendDuration: 0.08)

    public init(
        tabs: [Tab] = Array(Tab.allCases),
        selection: Binding<Tab>
    ) {
        self.tabs = tabs
        self._selection = selection
    }

    public var body: some View {
        ZStack {
            // Outer capsule container
            RoundedRectangle(cornerRadius: containerHeight / 2, style: .continuous)
                .fill(theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: containerHeight / 2, style: .continuous)
                        .stroke(theme.border, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 8)

            GeometryReader { geo in
                let totalWidth = geo.size.width
                let count = max(1, tabs.count)
                let itemWidth = (totalWidth - (trackPadding * 2) - (itemSpacing * CGFloat(count - 1))) / CGFloat(count)
                let itemHeight = geo.size.height - (trackPadding * 2) // ~44 when containerHeight is 56

                // === Round moving selection background ===
                Capsule(style: .continuous)
                    .fill(theme.accent.opacity(0.08))
                    .frame(width: itemWidth, height: itemHeight)
                    .matchedGeometryEffect(id: "accent-thumb", in: thumbNS)
                    .offset(x: xOffset(for: selection, itemWidth: itemWidth,
                                       spacing: itemSpacing, pad: trackPadding),
                            y: trackPadding)
                    .animation(thumbSpring, value: selection)

                // Pills
                HStack(spacing: itemSpacing) {
                    ForEach(tabs.indices, id: \.self) { idx in
                        let tab = tabs[idx]
                        let selected = (tab == selection)

                        TabPill(
                            title: tab.title,
                            systemImage: tab.systemImage,
                            isSelected: selected,
                            onTap: {
                                withAnimation(thumbSpring) {
                                    selection = tab
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.horizontal, trackPadding)
                .padding(.vertical, trackPadding)
            }
        }
        .frame(height: containerHeight)
    }

    // MARK: - Helpers
    private func xOffset(for selected: Tab,
                         itemWidth: CGFloat,
                         spacing: CGFloat,
                         pad: CGFloat) -> CGFloat {
        guard let idx = tabs.firstIndex(of: selected) else { return pad }
        return pad + CGFloat(idx) * (itemWidth + spacing)
    }
}

// MARK: - Preview Support

fileprivate enum DemoTab: String, CaseIterable, Identifiable, Hashable, LabeledTab {
    case journal, insights
    var id: String { rawValue }
    var title: String { self == .journal ? "Journal" : "Insights" }
    var systemImage: String { self == .journal ? "book.closed.fill" : "sparkles" }
}

// MARK: - Preview Wrapper

private struct TabSwitcherPreviewWrapper: View {
    @Environment(\.typography) private var type
    @State private var selection: DemoTab = .journal

    var body: some View {
        VStack(spacing: 24) {
            TabSwitcher<DemoTab>(selection: $selection)
                .useTheme()
                .useTypography()
                .frame(width: 180)
                .frame(height:64)

            Text("Selected: \(selection.title)")
                .font(type.h4)
        }
        .padding()
    }
}

#Preview("Light") {
    TabSwitcherPreviewWrapper()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TabSwitcherPreviewWrapper()
        .preferredColorScheme(.dark)
}
