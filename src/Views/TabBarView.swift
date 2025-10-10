import SwiftUI

/// Browser tab management interface with drag-and-drop reordering.
struct TabBarView: View {
    let tabs: [Tab]
    let selectedTabId: UUID?
    let onTabSelect: (UUID) -> Void
    let onTabClose: (Tab) -> Void
    let onTabMove: (Int, Int) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                TabItemView(
                    tab: tab,
                    isSelected: selectedTabId == tab.id,
                    onSelect: { onTabSelect(tab.id) },
                    onClose: { onTabClose(tab) },
                    onMove: onTabMove,
                    tabIndex: index,
                    totalTabs: tabs.count
                )
                .frame(maxWidth: .infinity)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                    removal: .opacity.combined(with: .scale(scale: 0.9))
                ))
            }
        }
        .frame(height: UIConstants.TabBar.height)
        .clipped()
        .toolbarBackgroundBlur()
        .overlay(
            // Black border above tabs
            Rectangle()
                .fill(Color.black)
                .frame(height: 1),
            alignment: .top
        )
        .overlay(
            // Black border below tabs
            Rectangle()
                .fill(Color.black)
                .frame(height: 1),
            alignment: .bottom
        )
        .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: tabs.count)
        .animation(.easeInOut(duration: 0.25), value: selectedTabId)
    }
}

struct TabDragData: Transferable, Codable {
    let tabId: UUID
    let tabIndex: Int
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

struct TabItemView: View {
    let tab: Tab
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onMove: (Int, Int) -> Void
    let tabIndex: Int
    let totalTabs: Int
    
    @State private var isHovered = false
    @State private var isDragging = false
    @State private var isDropTarget = false
    @State private var closeButtonOffset: CGFloat = 0
    @State private var pulseAnimation = false
    
    private var tabContentView: some View {
        HStack(spacing: 6) {
            // Dynamic favicon with fallback and loading animation
            Group {
                if let favicon = tab.favicon {
                    favicon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(tab.isLoading == true ? 0.6 : 1.0)
                        .scaleEffect(pulseAnimation && tab.isLoading == true ? 1.1 : 1.0)
                } else if tab.isLoading == true {
                    // Loading spinner for active loading tabs
                    Image(systemName: "arrow.2.circlepath")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(pulseAnimation ? 360 : 0))
                } else {
                    // Default document icon
                    Image(systemName: "doc.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 12, height: 12)
            .clipped()
            .onAppear {
                if tab.isLoading == true {
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        pulseAnimation = true
                    }
                }
            }
            .onChange(of: tab.isLoading) { _, isLoading in
                if isLoading == true {
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        pulseAnimation = true
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        pulseAnimation = false
                    }
                }
            }
            
            Text(tab.title.isEmpty ? "New Tab" : tab.title)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .center)
            
            ZStack {
                // Spacer to maintain consistent layout
                Spacer()
                    .frame(width: 18)
                
                // Animated close button
                if isHovered || isSelected {
                    ThemedCloseButton {
                        withAnimation(.easeOut(duration: 0.15)) {
                            onClose()
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity.combined(with: .scale(scale: 0.8))),
                        removal: .move(edge: .trailing).combined(with: .opacity.combined(with: .scale(scale: 0.8)))
                    ))
                    .offset(x: closeButtonOffset)
                    .onAppear {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            closeButtonOffset = 0
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            ZStack {
                if isSelected {
                    // Selected tab with glass morphism effect
                    ZStack {
                        // Glass morphism background
                        VisualEffectView.toolbarBackground
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
                        
                        // Glass overlay for enhanced effect
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(Theme.GlassMorphism.backgroundOverlayOpacity * 0.8),
                                        Color.white.opacity(Theme.GlassMorphism.backgroundOverlayOpacity * 0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(Theme.GlassMorphism.borderOpacity * 1.2),
                                                Color.white.opacity(Theme.GlassMorphism.borderOpacity * 0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: Theme.GlassMorphism.borderWidth
                                    )
                            )
                    }
                } else if isDropTarget {
                    // Drop target with blue glass effect
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.3),
                                    Color.blue.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                        )
                } else if isHovered {
                    // Hover state with subtle glass effect
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                }
            }
        )
        .overlay(
            // Subtle white separator between tabs (only show if not the last tab)
            Group {
                if tabIndex < totalTabs - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1)
                }
            },
            alignment: .trailing
        )
        .overlay(
            // Override top border for selected tab to match toolbar background
            Group {
                if isSelected {
                    Rectangle()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .frame(height: 1)
                }
            },
            alignment: .top
        )
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .opacity(isDragging ? 0.6 : 1.0)
        .contentShape(Rectangle())
        .draggable(TabDragData(tabId: tab.id, tabIndex: tabIndex)) {
            // Drag preview
            HStack(spacing: 6) {
                if let favicon = tab.favicon {
                    favicon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                } else {
                    Image(systemName: "doc.text")
                        .font(.caption)
                        .frame(width: 12, height: 12)
                }
                
                Text(tab.title.isEmpty ? "New Tab" : tab.title)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .shadow(radius: 4)
        }
        .dropDestination(for: TabDragData.self) { items, location in
            if let draggedTab = items.first {
                let sourceIndex = draggedTab.tabIndex
                let targetIndex = tabIndex
                
                let destinationIndex: Int
                if sourceIndex < targetIndex {
                    // Moving forward: insert AFTER target (account for removal shift)
                    destinationIndex = targetIndex + 1
                } else {
                    // Moving backward: insert AT target
                    destinationIndex = targetIndex
                }
                
                onMove(sourceIndex, destinationIndex)
            }
            return true
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                isDropTarget = targeted
            }
        }
        .onLongPressGesture(
            minimumDuration: 0,
            perform: { },
            onPressingChanged: { pressing in
                if pressing {
                    onSelect() // Activate immediately when pressing starts
                }
            }
        )
        .onHover { hovering in
            withAnimation(Theme.Animation.quick) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Close Tab") {
                onClose()
            }
        }
    }
    
    var body: some View {
        tabContentView
    }
}
