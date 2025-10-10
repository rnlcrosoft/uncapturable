import Foundation
import SwiftUI
import WebKit
import Combine

/// Main view model coordinating tabs, navigation, and keyboard shortcuts.

@Observable
class MainViewModel {
    private let stateManager = StateService.shared
    var cancellables = Set<AnyCancellable>()
    
    // UI State
    var addressText: String = ""
    var isAddressBarFocused: Bool = false
    var currentWebView: WKWebView?
    var shouldFocusAddressBar: Bool = false
    
    // Internal State
    private var closedTabs: [Tab] = [] // Track closed tabs for reopening
    
    // Computed Properties
    var currentTab: Tab? {
        stateManager.currentTab
    }
    
    var tabs: [Tab] {
        stateManager.tabs
    }
    
    var isWebContentActive: Bool {
        stateManager.isWebContentActive(for: currentTab)
    }
    
    init() {
        setupNotificationObservers()
        updateUIFromCurrentTab()
    }
    
    /**
     * Configure notification observers for centralized keyboard shortcut handling.
     * 
     * INTEGRATION STRATEGY: Uses AppConstants notification names for consistency
     * and type safety across the application. All observers use weak self references
     * to prevent retain cycles and main queue dispatch for thread-safe UI updates.
     */
    private func setupNotificationObservers() {
        // Tab Management Shortcuts
        NotificationCenter.default.addObserver(
            forName: .createNewTab,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.createNewTab()
        }
        
        NotificationCenter.default.addObserver(
            forName: .closeCurrentTab,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.closeCurrentTab()
        }
        
        NotificationCenter.default.addObserver(
            forName: .reopenMostRecentlyClosedTab,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reopenClosedTab()
        }
        
        NotificationCenter.default.addObserver(
            forName: .switchToNextTab,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.selectNextTab()
        }
        
        NotificationCenter.default.addObserver(
            forName: .switchToPreviousTab,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.selectPreviousTab()
        }
        
        // Navigation Shortcuts
        NotificationCenter.default.addObserver(
            forName: .reloadCurrentTabContent,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadCurrentTab()
        }
        
        NotificationCenter.default.addObserver(
            forName: .navigateBackInCurrentTab,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.navigateBack()
        }
        
        NotificationCenter.default.addObserver(
            forName: .navigateForwardInCurrentTab,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.navigateForward()
        }
        
        // Application Shortcuts  
        NotificationCenter.default.addObserver(
            forName: .openApplicationSettings,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.navigateToSettings(.browserSettings)
        }
        
        NotificationCenter.default.addObserver(
            forName: .focusAddressBarForInput,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.focusAddressBar()
        }
        
        // Direct Tab Selection Shortcuts (Cmd+1-9)
        setupDirectTabSelectionObservers()
    }
    
    /**
     * Configure observers for direct tab selection via keyboard shortcuts.
     * 
     * DESIGN RATIONALE: Separated into dedicated method to improve readability
     * and satisfy SwiftLint variable naming requirements.
     */
    private func setupDirectTabSelectionObservers() {
        let tabIndexNotifications: [Notification.Name] = [
            .switchToTabAtIndex1, .switchToTabAtIndex2, .switchToTabAtIndex3,
            .switchToTabAtIndex4, .switchToTabAtIndex5, .switchToTabAtIndex6,
            .switchToTabAtIndex7, .switchToTabAtIndex8, .switchToTabAtIndex9
        ]
        
        for (tabIndex, notificationName) in tabIndexNotifications.enumerated() {
            NotificationCenter.default.addObserver(
                forName: notificationName,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.selectTab(at: tabIndex)
            }
        }
    }
    
    func navigateToTab(with url: URL?) {
        if let currentTab = stateManager.currentTab {
            if case .empty = currentTab.tabType {
                // Convert empty tab to web tab
                let newWebTab = Tab(url: url)
                stateManager.replaceCurrentTab(with: newWebTab)
                currentWebView = nil
            } else if case .settings = currentTab.tabType {
                // Convert settings tab to web tab
                let newWebTab = Tab(url: url)
                stateManager.replaceCurrentTab(with: newWebTab)
                currentWebView = nil
            } else if let url = url {
                // Navigate current web tab
                currentTab.url = url
                currentWebView?.load(URLRequest(url: url))
            }
        } else if let url = url {
            // Create new tab
            stateManager.createTab(with: url)
            currentWebView = nil
        }
    }
    
    func navigateToSettings(_ settingsType: ApplicationSettingsCategory) {
        stateManager.createSettingsTab(type: settingsType)
        currentWebView = nil
    }
    
    @discardableResult
    func createNewTab() -> UUID {
        let newTab = stateManager.createSettingsTab(type: .windowSettings)
        currentWebView = nil
        addressText = ""
        updateUIFromCurrentTab()
        return newTab.id
    }
    
    func selectTab(withId tabId: UUID) {
        // Suspend current tab before switching
        if let currentTab = stateManager.currentTab {
            WebViewPoolService.shared.suspendBackgroundTab(tabId: currentTab.id)
        }
        
        stateManager.selectTab(withId: tabId)

        // Resume the newly selected tab
        WebViewPoolService.shared.resumeTab(tabId: tabId)

        updateUIFromCurrentTab()
    }
    
    func selectTab(at index: Int) {
        let tabs = stateManager.tabs
        guard index >= 0 && index < tabs.count else { return }
        selectTab(withId: tabs[index].id)
    }
    
    func selectNextTab() {
        let tabs = stateManager.tabs
        guard let currentTab = stateManager.currentTab,
              let currentIndex = tabs.firstIndex(where: { $0.id == currentTab.id }) else { return }
        
        let nextIndex = (currentIndex + 1) % tabs.count
        selectTab(withId: tabs[nextIndex].id)
    }
    
    func selectPreviousTab() {
        let tabs = stateManager.tabs
        guard let currentTab = stateManager.currentTab,
              let currentIndex = tabs.firstIndex(where: { $0.id == currentTab.id }) else { return }
        
        let previousIndex = currentIndex > 0 ? currentIndex - 1 : tabs.count - 1
        selectTab(withId: tabs[previousIndex].id)
    }
    
    func closeTab(withId tabId: UUID) {
        // Find and save the tab before closing it
        if let tabToClose = stateManager.tabs.first(where: { $0.id == tabId }) {
            closedTabs.append(tabToClose)
            // Keep only the last 10 closed tabs
            if closedTabs.count > 10 {
                closedTabs.removeFirst()
            }
        }
        
        let wasCurrentTab = stateManager.currentTab?.id == tabId
        stateManager.closeTab(withId: tabId)
        
        if stateManager.tabs.isEmpty {
            stateManager.ensureWindowSettingsTab()
        }
        
        if wasCurrentTab {
            currentWebView = nil
        }

        updateUIFromCurrentTab()
    }
    
    func closeCurrentTab() {
        // Save current tab before closing
        if let currentTab = stateManager.currentTab {
            closedTabs.append(currentTab)
            // Keep only the last 10 closed tabs
            if closedTabs.count > 10 {
                closedTabs.removeFirst()
            }
        }
        
        stateManager.closeCurrentTab()
        
        if stateManager.tabs.isEmpty {
            stateManager.ensureWindowSettingsTab()
        }
        
        if stateManager.tabs.isEmpty {
            currentWebView = nil
        }
        updateUIFromCurrentTab()
    }
    
    func reopenClosedTab() {
        guard let lastClosedTab = closedTabs.popLast() else { return }
        
        // Create new tab based on the closed tab's type
        let newTab: Tab
        switch lastClosedTab.tabType {
        case .empty:
            newTab = stateManager.createTab()
        case .web:
            newTab = stateManager.createTab(with: lastClosedTab.url)
        case .settings(let settingsType):
            newTab = stateManager.createSettingsTab(type: settingsType)
        }
        
        // Restore the original title
        newTab.title = lastClosedTab.title

        currentWebView = nil
        updateUIFromCurrentTab()
    }
    
    func reloadCurrentTab() {
        if let webView = currentWebView {
            if stateManager.currentTab?.isLoading == true {
                webView.stopLoading()
            } else {
                webView.reload()
            }
        }
    }
    
    func navigateBack() {
        currentWebView?.goBack()
    }
    
    func navigateForward() {
        currentWebView?.goForward()
    }
    
    func focusAddressBar() {
        // Update both focus states for proper coordination
        shouldFocusAddressBar = true
        isAddressBarFocused = true
        
        // Reset the trigger after a brief moment to allow for repeated focus requests
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.shouldFocusAddressBar = false
        }
    }
    
    func createURL(from text: String) -> URL? {
        return stateManager.createURL(from: text)
    }
    
    func handleTabSelection(_ tabId: UUID) {
        selectTab(withId: tabId)
    }
    
    func handleNewTab() {
        createNewTab()
    }
    
    func handleCloseTab(_ tab: Tab) {
        closeTab(withId: tab.id)
    }
    
    func handleCloseCurrentTab() {
        closeCurrentTab()
    }
    
    func handleTabMove(from sourceIndex: Int, to destinationIndex: Int) {
        stateManager.moveTab(from: IndexSet([sourceIndex]), to: destinationIndex)
        updateUIFromCurrentTab()
    }
    
    func handleAddressSubmit() {
        isAddressBarFocused = false
        
        guard let url = createURL(from: addressText) else { return }
        navigateToTab(with: url)
    }
    
    func handleNavigateBack() {
        navigateBack()
    }
    
    func handleNavigateForward() {
        navigateForward()
    }
    
    func handleReloadOrStop() {
        reloadCurrentTab()
    }

    func handleWebViewCreated(_ webView: WKWebView) {
        currentWebView = webView
    }
    
    func handleNavigationChange(_ updatedTab: Tab) {
        stateManager.updateTab(updatedTab)
        updateUIFromCurrentTab()
    }
    
    func updateUIFromCurrentTab() {
        if let tab = currentTab {
            addressText = tab.url?.absoluteString ?? ""
        }
    }
    
    func onAppear() {
        stateManager.ensureWindowSettingsTab()
        updateUIFromCurrentTab()
    }
    
    func onDisappear() {
        NotificationCenter.default.removeObserver(self)
    }
}
