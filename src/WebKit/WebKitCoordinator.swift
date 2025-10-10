import SwiftUI
import WebKit
import UniformTypeIdentifiers

/// SwiftUI-WebKit bridge with WebView lifecycle management.
struct WebView: NSViewRepresentable {
    @Binding var tab: Tab
    let onNavigationChange: (Tab) -> Void
    let onWebViewCreated: ((WKWebView) -> Void)?
    
    func makeNSView(context: Context) -> WKWebView {
        // Reuse existing WebView if available, otherwise create new one
        if let existingWebView = tab.webView {
            existingWebView.navigationDelegate = context.coordinator
            existingWebView.uiDelegate = context.coordinator
            context.coordinator.updateWebViewConfiguration(existingWebView)
            onWebViewCreated?(existingWebView)
            return existingWebView
        }
        
        // Create new WebView with optimized configuration
        let configuration = WebViewConfigurationFactory.createBrowserConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Configure WebView for proper keyboard shortcut handling
        context.coordinator.configureWebViewForKeyboardShortcuts(webView)
        
        // Store WebView in tab for reuse
        tab.webView = webView
        
        // Notify parent about WebView creation
        onWebViewCreated?(webView)
        
        // Load initial content only for new WebViews
        if let url = tab.url {
            webView.load(URLRequest(url: url))
        }
        // For new empty tabs, leave WebView empty (no content loading)
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.tab = tab
        
        // Only load URL if it's a programmatic navigation request
        // and different from current URL (avoid reloads on tab switches)
        if let url = tab.url, 
           nsView.url != url,
           !context.coordinator.isTabSwitch,
           context.coordinator.shouldLoadURL(url, in: nsView) {
            let request = URLRequest(url: url)
            nsView.load(request)
        }
        
        // Reset tab switch flag
        context.coordinator.isTabSwitch = false
    }
    
    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(tab: tab, onNavigationChange: onNavigationChange)
    }
}

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var tab: Tab
    let onNavigationChange: (Tab) -> Void
    private var lastLoadedURL: URL?
    var isTabSwitch: Bool = false
    
    init(tab: Tab, onNavigationChange: @escaping (Tab) -> Void) {
        self.tab = tab
        self.onNavigationChange = onNavigationChange
    }
    
    func shouldLoadURL(_ url: URL, in webView: WKWebView) -> Bool {
        // Don't reload if this URL was just loaded
        if lastLoadedURL == url {
            return false
        }
        
        // Allow loading if it's a genuine new navigation
        lastLoadedURL = url
        return true
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        tab.isLoading = true
        tab.updateFromWebView(webView)
        onNavigationChange(tab)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        tab.isLoading = false
        tab.updateFromWebView(webView)
        
        // Add to history when navigation completes
        if let url = webView.url,
           !url.absoluteString.hasPrefix("about:") &&
           !url.absoluteString.hasPrefix("data:") {
            let title = webView.title ?? url.host ?? "Untitled"
            
            // Extract and cache favicon using centralized service
            FaviconService.shared.extractFaviconData(from: webView) { faviconData in
                StateService.shared.addHistoryItem(title: title, url: url, faviconData: faviconData)
            }
        }
        
        onNavigationChange(tab)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        tab.isLoading = false
        tab.updateFromWebView(webView)
        onNavigationChange(tab)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, 
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        decisionHandler(.allow)
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, 
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Prevent new windows/popups - handle navigation in the current tab instead
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        // Handle webview close events - prevent unwanted UI changes
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, 
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        // Handle JavaScript alerts properly
        let alert = NSAlert()
        alert.messageText = "Alert"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
        completionHandler()
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, 
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        // Handle JavaScript confirms properly
        let alert = NSAlert()
        alert.messageText = "Confirm"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        completionHandler(response == .alertFirstButtonReturn)
    }
    
    
    func updateWebViewConfiguration(_ webView: WKWebView) {
        // Configure WebView for proper keyboard shortcut handling
        configureWebViewForKeyboardShortcuts(webView)
    }
    
    func configureWebViewForKeyboardShortcuts(_ webView: WKWebView) {
        // Configure accessibility to improve keyboard navigation
        webView.setAccessibilityRole(.group)
        webView.setAccessibilityLabel("Web content")
        
        // Allow the WebView to handle standard editing commands
        // This ensures Copy, Paste, Select All work properly in web content
        DispatchQueue.main.async {
            // Make WebView the first responder when it's ready to accept keyboard input
            if webView.canBecomeKeyView {
                webView.window?.makeFirstResponder(webView)
            }
        }
    }
    

}
