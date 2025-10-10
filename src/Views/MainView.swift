import SwiftUI
import WebKit
import AppKit

struct MainView: View {
    @State private var viewModel: MainViewModel
    @FocusState private var isAddressBarFocused: Bool

    init() {
        _viewModel = State(initialValue: MainViewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom toolbar - above tab bar
            HStack(spacing: 4) {
                // Navigation buttons
                Button(action: { NotificationCenter.default.post(name: .navigateBackInCurrentTab, object: nil) }) {
                    Image(systemName: "chevron.left")
                        .frame(width: 20, height: 20)
                }.buttonStyle(.plain).disabled(!(viewModel.currentTab?.canGoBack ?? false))

                Button(action: { NotificationCenter.default.post(name: .navigateForwardInCurrentTab, object: nil) }) {
                    Image(systemName: "chevron.right")
                        .frame(width: 20, height: 20)
                }.buttonStyle(.plain).disabled(!(viewModel.currentTab?.canGoForward ?? false))

                Button(action: { NotificationCenter.default.post(name: .reloadCurrentTabContent, object: nil) }) {
                    Image(systemName: viewModel.currentTab?.isLoading == true ? "xmark" : "arrow.clockwise")
                        .frame(width: 20, height: 20)
                }.buttonStyle(.plain)
                
                // Search bar
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    HStack(spacing: 0) {
                        if viewModel.addressText.isEmpty && !isAddressBarFocused {
                            Text("Enter URL or search")
                                .foregroundColor(Color.gray.opacity(0.6))
                                .font(.system(size: 13))
                                .lineLimit(1)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 14)
                        }
                        TextField("", text: $viewModel.addressText)
                            .textFieldStyle(.plain)
                            .foregroundColor(.primary)
                            .font(.system(size: 13))
                            .focused($isAddressBarFocused)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 14)
                            .onSubmit(viewModel.handleAddressSubmit)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 24)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    isAddressBarFocused = true
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

                Button(action: { NotificationCenter.default.post(name: .createNewTab, object: nil) }) {
                    Image(systemName: "plus")
                        .frame(width: 20, height: 20)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            
            if !viewModel.tabs.isEmpty {
                TabBarView(
                    tabs: viewModel.tabs,
                    selectedTabId: viewModel.currentTab?.id,
                    onTabSelect: viewModel.handleTabSelection,
                    onTabClose: viewModel.handleCloseTab,
                    onTabMove: viewModel.handleTabMove
                )
            }

            ZStack {
                if let tab = viewModel.currentTab {
                    switch tab.tabType {
                        case .empty: EmptyTabView().id(tab.id)
                        case .web:
                            WebView(tab: .constant(tab),
                                   onNavigationChange: viewModel.handleNavigationChange,
                                   onWebViewCreated: viewModel.handleWebViewCreated).id(tab.id)
                        case .settings(let settingsType):
                            switch settingsType {
                                case .browserSettings: BrowserSettingsView()
                                case .windowSettings: WindowSettingsView()
                            }
                    }
                } else {
                    WindowSettingsView()
                }


            }
            .navigationTitle("")

        }
        .frame(minWidth: Layout.windowMinWidth, minHeight: Layout.windowMinHeight)
        .windowBackgroundBlur()
        .onAppear {
            setupKeyboardShortcuts()
            setupWindowManager()
            viewModel.onAppear()
        }
        .onDisappear {
            removeKeyboardShortcuts()
            viewModel.onDisappear()
        }
    }

    private func setupKeyboardShortcuts() {
        NotificationCenter.default.addObserver(forName: .focusAddressBarForInput, object: nil, queue: .main) { _ in
            DispatchQueue.main.async { [self] in
                self.viewModel.focusAddressBar()
                self.isAddressBarFocused = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let currentTab = self.viewModel.currentTab, let url = currentTab.url {
                        self.viewModel.addressText = url.absoluteString
                    }
                }
            }
        }
    }

    private func removeKeyboardShortcuts() {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupWindowManager() {
        _ = WindowService.shared
    }
}
