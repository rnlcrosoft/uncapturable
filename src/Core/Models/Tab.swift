import Foundation
import WebKit
import SwiftUI

/// Browser tab data model with WebView integration.

@Observable
class Tab: Identifiable, Equatable {
    static func == (lhs: Tab, rhs: Tab) -> Bool {
        return lhs.id == rhs.id
    }
    let id = UUID()
    var title: String = "New Tab"
    var url: URL?
    var isLoading: Bool = false
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var estimatedProgress: Double = 0.0
    private var _webView: WKWebView?
    
    /// Lazily acquire WebView from pool when needed
    var webView: WKWebView? {
        get {
            if _webView == nil, case .web = tabType {
                _webView = WebViewPoolService.shared.acquireWebView(for: self)
            }
            return _webView
        }
        set {
            _webView = newValue
        }
    }
    var favicon: Image?
    let tabType: TabContentType
    
    init(url: URL? = nil) {
        if url == nil {
            self.tabType = .empty
        } else {
            self.tabType = .web(url)
        }
        self.url = url
        if let url = url {
            self.title = url.host ?? url.absoluteString
        }
    }
    
    init(settingsType: ApplicationSettingsCategory) {
        self.tabType = .settings(settingsType)
        self.title = settingsType.title
        self.favicon = settingsType.icon
    }
    
    func updateFromWebView(_ webView: WKWebView) {
        self.title = webView.title ?? "New Tab"
        
        if let webViewURL = webView.url,
           !webViewURL.absoluteString.hasPrefix("about:") &&
           !webViewURL.absoluteString.hasPrefix("data:") {
            self.url = webViewURL
        }
        
        self.isLoading = webView.isLoading
        self.canGoBack = webView.canGoBack
        self.canGoForward = webView.canGoForward
        self.estimatedProgress = webView.estimatedProgress
        
        // Load favicon when page finishes loading using centralized service
        if !webView.isLoading {
            FaviconService.shared.extractFaviconImage(from: webView) { [weak self] faviconImage in
                self?.favicon = faviconImage
            }
        }
    }
    
    
    func cleanup() {
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        
        // Release WebView back to pool for reuse
        WebViewPoolService.shared.releaseWebView(for: id)
        _webView = nil
    }
}
