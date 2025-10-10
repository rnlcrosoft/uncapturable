import SwiftUI
import AppKit

/**
 * ActivatingPanel - Custom NSPanel that manually activates on mouse clicks
 * 
 * Fixes focus issues with .nonactivatingPanel while preserving presentation functionality.
 */
class ActivatingPanel: NSPanel {
    
    /**
     * Intercepts left mouse clicks and manually activates the panel.
     * This fixes the focus issue with .nonactivatingPanel where only
     * title bar clicks would activate the window.
     */
    override func mouseDown(with event: NSEvent) {
        activatePanelIfNeeded()
        super.mouseDown(with: event)
    }
    
    /**
     * Intercepts right mouse clicks and manually activates the panel.
     * Ensures context menus and right-click operations also trigger activation.
     */
    override func rightMouseDown(with event: NSEvent) {
        activatePanelIfNeeded()
        super.rightMouseDown(with: event)
    }
    
    /**
     * Intercepts other mouse button clicks (middle button, etc.)
     * for comprehensive activation coverage.
     */
    override func otherMouseDown(with event: NSEvent) {
        activatePanelIfNeeded()
        super.otherMouseDown(with: event)
    }
    
    /**
     * Manually activates the panel with conditional app activation.
     * 
     * BEHAVIOR BASED ON CLEAN INTERFACE MODE SETTING:
     * - When DISABLED: Full activation (normal window behavior)
     * - When ENABLED: Minimal activation (preserves other apps' window controls)
     * 
     * This enables system-wide shortcuts while respecting presentation requirements.
     */
    private func activatePanelIfNeeded() {
        // Always make panel key window for shortcuts to work
        makeKeyAndOrderFront(nil)
        
        // Conditional app activation based on Clean Interface Mode setting
        let windowService = WindowService.shared
        if !windowService.isCleanInterfaceModeEnabled {
            // Normal mode: Full activation (deactivates other apps' window controls)
            NSApp.activate(ignoringOtherApps: true)
        }
        // Clean Interface Mode: Skip app activation to preserve
        // other applications' window control states (presentation behavior)
    }
}

class PanelAppDelegate: NSObject, NSApplicationDelegate, WindowServicePanelDelegate {
    private var mainPanel: NSPanel?
    private var hostingController: NSHostingController<MainView>?
    private var isPanelRecreationInProgress = false
    private var isActivationPolicyChangeInProgress = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up menu bar
        setupMenuBar()
        WindowService.shared.panelDelegate = self
        createMainPanel()
        
        // Observe activation policy changes to handle menu conflicts
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActivationPolicyChange),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Ensure panel is visible after startup
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.Window.panelShowDelay) {
            if let panel = self.mainPanel, !panel.isVisible {
                panel.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    @objc private func handleActivationPolicyChange() {
        DispatchQueue.main.async {
            if NSApp.activationPolicy() == .regular && NSApp.mainMenu == nil {
                self.setupMenuBar()
            }
        }
    }
    
    private func setupMenuBar() {
        let shortcutManager = KeyboardService.shared
        
        // Create main menu
        let mainMenu = NSMenu()
        
        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Quit Swift Browser", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // File menu (Tab Management)
        let fileMenuItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let fileMenu = NSMenu(title: "File")
        
        let tabShortcuts = shortcutManager.shortcuts(for: .tab)
        for shortcut in tabShortcuts {
            if let action = getMenuAction(for: shortcut.id) {
                let menuItem = NSMenuItem(
                    title: shortcut.title,
                    action: action,
                    keyEquivalent: shortcut.keyEquivalent
                )
                menuItem.keyEquivalentModifierMask = shortcut.modifierMask
                fileMenu.addItem(menuItem)
            }
        }
        
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)
        
        // Edit menu (Standard editing commands)
        let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "Edit")
        
        let editShortcuts = shortcutManager.shortcuts(for: .edit)
        for shortcut in editShortcuts {
            // Use standard selectors for system-handled editing commands
            let action = getEditMenuAction(for: shortcut.id)
            let menuItem = NSMenuItem(
                title: shortcut.title,
                action: action,
                keyEquivalent: shortcut.keyEquivalent
            )
            menuItem.keyEquivalentModifierMask = shortcut.modifierMask
            editMenu.addItem(menuItem)
        }
        
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        
        // View menu (Navigation and View shortcuts)
        let viewMenuItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        let viewMenu = NSMenu(title: "View")
        
        let navigationShortcuts = shortcutManager.shortcuts(for: .navigation)
        let viewShortcuts = shortcutManager.shortcuts(for: .view)
        
        for shortcut in navigationShortcuts + viewShortcuts {
            if let action = getMenuAction(for: shortcut.id) {
                let menuItem = NSMenuItem(
                    title: shortcut.title,
                    action: action,
                    keyEquivalent: shortcut.keyEquivalent
                )
                menuItem.keyEquivalentModifierMask = shortcut.modifierMask
                viewMenu.addItem(menuItem)
            }
        }
        
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)
        
        // Window menu
        let windowMenuItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        let windowMenu = NSMenu(title: "Window")
        
        // No window shortcuts currently available
        
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        
        NSApp.mainMenu = mainMenu
    }
    
    private func getMenuAction(for shortcutId: String) -> Selector? {
        let actionMap: [String: Selector] = [
            "newTab": #selector(newTab),
            "closeTab": #selector(closeTab),
            "reopenClosedTab": #selector(reopenClosedTab),
            "nextTab": #selector(nextTab),
            "previousTab": #selector(previousTab),
            "selectTab1": #selector(selectTab1),
            "selectTab2": #selector(selectTab2),
            "selectTab3": #selector(selectTab3),
            "selectTab4": #selector(selectTab4),
            "selectTab5": #selector(selectTab5),
            "selectTab6": #selector(selectTab6),
            "selectTab7": #selector(selectTab7),
            "selectTab8": #selector(selectTab8),
            "selectTab9": #selector(selectTab9),
            "reload": #selector(reload),
            "navigateBack": #selector(navigateBack),
            "navigateForward": #selector(navigateForward),
            "focusAddressBar": #selector(focusAddressBar)
        ]
        return actionMap[shortcutId]
    }
    
    private func getEditMenuAction(for shortcutId: String) -> Selector? {
        let editActionMap: [String: Selector] = [
            "cut": #selector(NSText.cut(_:)),
            "copy": #selector(NSText.copy(_:)),
            "paste": #selector(NSText.paste(_:)),
            "selectAll": #selector(NSText.selectAll(_:)),
            "undo": #selector(UndoManager.undo),
            "redo": #selector(UndoManager.redo)
        ]
        return editActionMap[shortcutId]
    }
    
    @objc private func newTab() {
        NotificationCenter.default.post(name: .createNewTab, object: nil)
    }
    
    @objc private func closeTab() {
        NotificationCenter.default.post(name: .closeCurrentTab, object: nil)
    }
    
    @objc private func reopenClosedTab() {
        NotificationCenter.default.post(name: .reopenMostRecentlyClosedTab, object: nil)
    }
    
    @objc private func nextTab() {
        NotificationCenter.default.post(name: .switchToNextTab, object: nil)
    }
    
    @objc private func previousTab() {
        NotificationCenter.default.post(name: .switchToPreviousTab, object: nil)
    }
    
    @objc private func selectTab1() {
        NotificationCenter.default.post(name: .switchToTabAtIndex1, object: nil)
    }
    
    @objc private func selectTab2() {
        NotificationCenter.default.post(name: .switchToTabAtIndex2, object: nil)
    }
    
    @objc private func selectTab3() {
        NotificationCenter.default.post(name: .switchToTabAtIndex3, object: nil)
    }
    
    @objc private func selectTab4() {
        NotificationCenter.default.post(name: .switchToTabAtIndex4, object: nil)
    }
    
    @objc private func selectTab5() {
        NotificationCenter.default.post(name: .switchToTabAtIndex5, object: nil)
    }
    
    @objc private func selectTab6() {
        NotificationCenter.default.post(name: .switchToTabAtIndex6, object: nil)
    }
    
    @objc private func selectTab7() {
        NotificationCenter.default.post(name: .switchToTabAtIndex7, object: nil)
    }
    
    @objc private func selectTab8() {
        NotificationCenter.default.post(name: .switchToTabAtIndex8, object: nil)
    }
    
    @objc private func selectTab9() {
        NotificationCenter.default.post(name: .switchToTabAtIndex9, object: nil)
    }
    
    @objc private func reload() {
        NotificationCenter.default.post(name: .reloadCurrentTabContent, object: nil)
    }
    
    @objc private func navigateBack() {
        NotificationCenter.default.post(name: .navigateBackInCurrentTab, object: nil)
    }
    
    @objc private func navigateForward() {
        NotificationCenter.default.post(name: .navigateForwardInCurrentTab, object: nil)
    }
    
    @objc private func focusAddressBar() {
        NotificationCenter.default.post(name: .focusAddressBarForInput, object: nil)
    }
    
    private func createMainPanel() {
        // Determine style mask based on WindowService settings
        let windowService = WindowService.shared
        let styleMask: NSPanel.StyleMask = windowService.isCleanInterfaceModeEnabled ?
            [.nonactivatingPanel, .titled, .closable, .resizable, .fullSizeContentView] :
            [.titled, .closable, .resizable, .fullSizeContentView]
        
        // Create the panel with proper dimensions
        let contentRect = NSRect(
            x: UIConstants.Window.defaultX, 
            y: UIConstants.Window.defaultY, 
            width: UIConstants.Window.defaultWidth, 
            height: UIConstants.Window.defaultHeight
        )
        
        mainPanel = ActivatingPanel(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        guard let panel = mainPanel else {
            return
        }
        
        // Register immediately to prevent app termination
        windowService.registerPanel(panel)
        
        // Configure panel properties
        panel.center()
        panel.isMovableByWindowBackground = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.hidesOnDeactivate = false
        panel.canHide = true
        panel.animationBehavior = .documentWindow

        // Enable window translucency for glass morphism effects
        panel.isOpaque = false
        panel.backgroundColor = NSColor.clear
        panel.hasShadow = true

        // Configure unified visual effect background for the window
        if let contentView = panel.contentView {
            let visualEffectView = NSVisualEffectView()
            visualEffectView.material = .underWindowBackground  // Using .underWindowBackground for window-level
            visualEffectView.blendingMode = .behindWindow       // Consistent with our unified system
            visualEffectView.state = .active                    // Always active to maintain blur when window loses focus
            visualEffectView.frame = contentView.bounds
            visualEffectView.autoresizingMask = [.width, .height]

            // Override appearance to maintain blur when window becomes inactive
            visualEffectView.appearance = NSAppearance.currentDrawing()

            contentView.addSubview(visualEffectView, positioned: .below, relativeTo: nil)
        }

        // Configure title bar and toolbar to maintain active appearance
        configureTitleBarAndToolbar(for: panel)

        // Ensure panel doesn't close app when minimized
        panel.hidesOnDeactivate = false
        panel.canHide = false  // Prevent hiding that might trigger termination
        
        // Create hosting controller with the browser view
        let browserView = MainView()
        hostingController = NSHostingController(rootView: browserView)
        
        if let hostingController = hostingController {
            // Directly attach SwiftUI content to panel (preserves toolbar functionality)
            panel.contentView = hostingController.view
            hostingController.view.frame = panel.contentView?.bounds ?? .zero
            hostingController.view.autoresizingMask = [.width, .height]
        }
        
        // Show the panel and ensure it becomes key
        panel.makeKeyAndOrderFront(nil)
        
        // Ensure panel becomes key window to prevent app termination
        DispatchQueue.main.async {
            panel.makeKey()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Never auto-terminate during panel operations
        if isPanelRecreationInProgress || isActivationPolicyChangeInProgress {
            return false
        }
        
        // If main panel still exists and is visible, don't terminate
        if let panel = mainPanel, panel.isVisible {
            return false
        }
        
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up notifications
        NotificationCenter.default.removeObserver(self)
        
        if let panel = mainPanel {
            WindowService.shared.unregisterWindow(panel)
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            mainPanel?.makeKeyAndOrderFront(nil)
        }
        return true
    }
    
    func windowService(_ service: WindowService, didRecreatePanel oldPanel: NSPanel, newPanel: NSPanel) {
        if mainPanel === oldPanel {
            isPanelRecreationInProgress = true
            
            // Preserve existing hosting controller and its state to avoid losing tabs/navigation
            if let existingHostingController = hostingController {
                // Remove from old panel first
                existingHostingController.view.removeFromSuperview()
                
                // Directly attach SwiftUI content to new panel (preserves toolbar functionality)
                newPanel.contentView = existingHostingController.view
                existingHostingController.view.frame = newPanel.contentView?.bounds ?? .zero
                existingHostingController.view.autoresizingMask = [.width, .height]
                
                // Update reference
                mainPanel = newPanel
                
                // Force SwiftUI to reconfigure toolbar on new panel
                existingHostingController.view.needsLayout = true
                existingHostingController.view.layoutSubtreeIfNeeded()
            } else {
                // Fallback: create new hosting controller if none exists
                mainPanel = newPanel
                let browserView = MainView()
                hostingController = NSHostingController(rootView: browserView)
                
                if let hostingController = hostingController {
                    // Directly attach SwiftUI content to fallback panel too
                    newPanel.contentView = hostingController.view
                    hostingController.view.frame = newPanel.contentView?.bounds ?? .zero
                    hostingController.view.autoresizingMask = [.width, .height]
                }
            }
            
            // Presentation-aware configuration to ensure toolbar appearance is properly applied
            // while respecting clean interface mode settings
            
            // Stage 1: Establish window as key with conditional app activation
            DispatchQueue.main.async {
                // Always make panel key window
                newPanel.makeKeyAndOrderFront(nil)
                
                // Respect clean interface mode setting for app activation
                let windowService = WindowService.shared
                if !windowService.isCleanInterfaceModeEnabled {
                    // Normal mode: Full activation (deactivates other apps' window controls)
                    NSApp.activate(ignoringOtherApps: true)
                }
                // Clean Interface Mode: Skip app activation to preserve presentation mode
                
                // Apply basic window appearance
                newPanel.appearance = NSAppearance.currentDrawing()
                newPanel.autorecalculatesKeyViewLoop = false
            }
            
            // Stage 2: Apply window configuration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                newPanel.invalidateRestorableState()
                newPanel.displayIfNeeded()
            }

            // Stage 3: Final validation with forced visual refresh
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Force complete visual refresh to ensure configuration takes effect
                newPanel.invalidateShadow()
                newPanel.display()

                // Ensure the panel maintains key status
                if newPanel.canBecomeKey && !newPanel.isKeyWindow {
                    newPanel.makeKey()
                }
            }
            
            // DON'T close old panel here - WindowService handles cleanup
            // This prevents double cleanup and crashes
            isPanelRecreationInProgress = false
        }
    }
    
    func windowService(_ service: WindowService, willChangeActivationPolicy isAccessory: Bool) {
        isActivationPolicyChangeInProgress = true
    }
    
    func windowService(_ service: WindowService, didChangeActivationPolicy isAccessory: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.Window.activationPolicyChangeDelay) {
            self.isActivationPolicyChangeInProgress = false
        }
    }
    
    
    /**
     * Configures the title bar and toolbar to maintain active appearance even when window loses focus.
     * This prevents the system from applying inactive styling to the title bar and toolbar chrome.
     */
    private func configureTitleBarAndToolbar(for panel: NSPanel) {
        // Set the window to maintain its active appearance even when not key
        panel.autorecalculatesKeyViewLoop = false
        
        // Configure the title bar to use a custom appearance that doesn't change with focus
        let titlebarView = panel.standardWindowButton(.closeButton)?.superview
        if let titlebar = titlebarView {
            let titlebarVisualEffectView = NSVisualEffectView()
            titlebarVisualEffectView.material = .underWindowBackground
            titlebarVisualEffectView.blendingMode = .behindWindow
            titlebarVisualEffectView.state = .active  // Always active to prevent inactive appearance
            titlebarVisualEffectView.appearance = NSAppearance.currentDrawing()
            titlebarVisualEffectView.frame = titlebar.bounds
            titlebarVisualEffectView.autoresizingMask = [.width, .height]
            
            // Insert the visual effect view behind the title bar controls
            titlebar.addSubview(titlebarVisualEffectView, positioned: .below, relativeTo: nil)
        }
        
        // Configure window appearance to prevent automatic inactive styling
        panel.appearance = NSAppearance.currentDrawing()
        
        // Override the window's effective appearance to maintain consistent styling
        DispatchQueue.main.async {
            panel.invalidateShadow()
            panel.display()
        }
    }
    
    /**
     * Enhanced version of title bar and toolbar configuration specifically designed for
     * window recreation scenarios where the window might be inactive during configuration.
     * Uses more aggressive appearance forcing to ensure configuration sticks.
     */
    private func configureTitleBarAndToolbarEnhanced(for panel: NSPanel) {
        // Force window appearance settings regardless of activation state
        panel.autorecalculatesKeyViewLoop = false
        panel.appearance = NSAppearance.currentDrawing()
        
        // Configure the title bar with multiple fallback approaches
        let titlebarView = panel.standardWindowButton(.closeButton)?.superview
        if let titlebar = titlebarView {
            // Remove any existing visual effect views to avoid conflicts
            titlebar.subviews.forEach { view in
                if view is NSVisualEffectView {
                    view.removeFromSuperview()
                }
            }
            
            // Create enhanced visual effect view with forced active state
            let titlebarVisualEffectView = NSVisualEffectView()
            titlebarVisualEffectView.material = .underWindowBackground
            titlebarVisualEffectView.blendingMode = .behindWindow
            titlebarVisualEffectView.state = .active  // Always active to prevent inactive appearance
            titlebarVisualEffectView.appearance = NSAppearance.currentDrawing()
            titlebarVisualEffectView.frame = titlebar.bounds
            titlebarVisualEffectView.autoresizingMask = [.width, .height]
            
            // Force the visual effect view to maintain its state
            titlebarVisualEffectView.wantsLayer = true
            titlebarVisualEffectView.layer?.shouldRasterize = false
            
            // Insert the visual effect view behind the title bar controls
            titlebar.addSubview(titlebarVisualEffectView, positioned: .below, relativeTo: nil)
            
            // Force immediate layout and appearance update
            titlebar.needsLayout = true
            titlebar.layoutSubtreeIfNeeded()
        }
        
        // Apply comprehensive window appearance configuration
        panel.backgroundColor = NSColor.clear
        panel.isOpaque = false
        
        // Force multiple refresh cycles to ensure the configuration takes effect
        panel.invalidateRestorableState()
        panel.invalidateShadow()
        panel.displayIfNeeded()
        
        // Final forced appearance update
        DispatchQueue.main.async {
            panel.display()
            
            // One more validation to ensure toolbar area is properly configured
            if let toolbar = panel.toolbar {
                toolbar.validateVisibleItems()
                // Force toolbar to refresh its display
                for item in toolbar.visibleItems ?? [] {
                    item.validate()
                }
            }
        }
    }
}
