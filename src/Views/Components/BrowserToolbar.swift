import SwiftUI
import WebKit

/**
 * CustomToolbarView - Custom Toolbar Implementation
 *
 * Fully programmatic toolbar that avoids macOS native toolbar overflow issues
 * while maintaining identical visual appearance.
 */

struct CustomToolbarView: View {
    @Binding var addressText: String
    @FocusState.Binding var isAddressBarFocused: Bool

    let currentTab: Tab?
    let onSubmit: () -> Void

    @State private var toolbarHeight: CGFloat = 48

    private func isWebContentActiveForTab(_ tab: Tab?) -> Bool {
        guard let tab = tab else { return false }
        if case .web = tab.tabType {
            return true
        }
        return false
    }

    var body: some View {
        // Main toolbar container with native macOS toolbar appearance
        HStack(spacing: 0) {
            // Left section - Navigation buttons
            HStack(spacing: 8) {
                ThemedToolbarButton(
                    icon: "chevron.left",
                    isDisabled: !(currentTab?.canGoBack ?? false)
                ) {
                    // Navigate back interaction will be handled by parent
                    NotificationCenter.default.post(name: .navigateBackInCurrentTab, object: nil)
                }

                ThemedToolbarButton(
                    icon: "chevron.right",
                    isDisabled: !(currentTab?.canGoForward ?? false)
                ) {
                    // Navigate forward interaction will be handled by parent
                    NotificationCenter.default.post(name: .navigateForwardInCurrentTab, object: nil)
                }

                ThemedToolbarButton(
                    icon: currentTab?.isLoading == true ? "xmark" : "arrow.clockwise"
                ) {
                    NotificationCenter.default.post(name: .reloadCurrentTabContent, object: nil)
                }
            }
            .padding(.leading, 16)

            // Central section - Address bar (flexible width)
            CustomAddressField(
                addressText: $addressText,
                isAddressBarFocused: $isAddressBarFocused,
                currentTab: currentTab,
                onSubmit: onSubmit,
                isWebContentActive: isWebContentActiveForTab(currentTab),
                toolbarHeight: toolbarHeight
            )
            .frame(maxWidth: .infinity)

            // Right section - Utility buttons
            HStack(spacing: 8) {
                ThemedToolbarButton(
                    icon: "plus"
                ) {
                    NotificationCenter.default.post(name: .createNewTab, object: nil)
                }
            }
            .padding(.trailing, 16)
        }
        .frame(height: toolbarHeight)
        .background(
            VisualEffectView.toolbarBackground
                .overlay(
                    // Bottom border for native toolbar appearance
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.black.opacity(0.1)),
                    alignment: .bottom
                )
        )
        .overlay(
            // Top border for depth effect
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.3)),
            alignment: .top
        )
        .padding(.vertical, 1) // Subtle padding to match native appearance
    }
}

struct CustomAddressField: View {
    @Binding var addressText: String
    @FocusState.Binding var isAddressBarFocused: Bool

    let currentTab: Tab?
    let onSubmit: () -> Void
    let isWebContentActive: Bool
    let toolbarHeight: CGFloat

    var body: some View {
        ZStack {
            // Base rounded rectangle background
            RoundedRectangle(cornerRadius: 6)
                .fill(isWebContentActive ?
                      Color(NSColor.controlBackgroundColor) :
                      Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)

            // Content
            HStack(spacing: 0) {
                if addressText.isEmpty && !isAddressBarFocused {
                    Text("Enter URL or search")
                        .foregroundColor(Color.gray.opacity(0.6))
                        .font(.system(size: 13))
                        .padding(.horizontal, 8)
                } else {
                    // Text field for input
                    TextField("", text: $addressText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.black)
                        .font(.system(size: 13))
                        .focused($isAddressBarFocused)
                        .padding(.horizontal, 8)
                        .onSubmit(onSubmit)
                }
            }
        }
        .frame(height: toolbarHeight)
        .frame(minWidth: 200, maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            isAddressBarFocused = true
        }
        .padding(.horizontal, 4)
    }
}

struct NSTextFieldRepresentable: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let onSubmit: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.placeholderString = ""
        textField.isBordered = false
        textField.isBezeled = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.cell?.isScrollable = true
        textField.cell?.wraps = false
        textField.cell?.usesSingleLineMode = true
        textField.lineBreakMode = .byClipping

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NSTextFieldRepresentable

        init(_ parent: NSTextFieldRepresentable) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            if let event = NSApp.currentEvent,
               event.type == .keyDown && event.keyCode == 36 { // Enter key
                parent.onSubmit()
            }
        }
    }
}
