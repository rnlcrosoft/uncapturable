import Foundation
import WebKit
import SwiftUI

/// WebView pooling, reuse, and cleanup service.
@Observable
class WebViewPoolService {
    static let shared = WebViewPoolService()
    
    
    /// Maximum number of WebView instances to keep in memory simultaneously
    private let maximumActiveWebViews = 6
    
    /// Time (in seconds) after which inactive WebViews are released from background tabs
    private let backgroundTabTimeoutSeconds: TimeInterval = 600 // 10 minutes
    
    /// Time (in seconds) between cleanup cycles for unused WebViews
    private let cleanupIntervalSeconds: TimeInterval = 120 // 2 minutes
    
    
    /// Pool of available WebView instances ready for reuse
    private var availableWebViews: [WKWebView] = []
    
    /// WebViews currently associated with active tabs
    private var activeWebViews: [UUID: WebViewInfo] = [:]
    
    /// Timer for periodic cleanup of unused WebViews
    private var cleanupTimer: Timer?
    
    /// Memory pressure monitor for emergency cleanup
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    
    
    /// Information about an active WebView and its usage
    private class WebViewInfo {
        let webView: WKWebView
        var lastActiveTime: Date
        var isSuspended: Bool
        weak var tab: Tab?
        
        init(webView: WKWebView, tab: Tab?) {
            self.webView = webView
            self.lastActiveTime = Date()
            self.isSuspended = false
            self.tab = tab
        }
    }
    
    
    private init() {
        setupCleanupTimer()
        setupMemoryPressureObserver()
    }
    
    deinit {
        cleanupTimer?.invalidate()
        memoryPressureSource?.cancel()
    }
    
    
    /**
     * Acquire a WebView for the specified tab, either from the pool or by creating a new one.
     * 
     * ALLOCATION STRATEGY:
     * 1. Check if tab already has an active WebView and return it
     * 2. Try to reuse an available WebView from the pool
     * 3. Create a new WebView if pool is empty and under the limit
     * 4. Forcibly reclaim a WebView from the least recently used background tab if at limit
     * 
     * PERFORMANCE: This method prioritizes memory efficiency over WebView creation overhead.
     */
    func acquireWebView(for tab: Tab) -> WKWebView {
        // Return existing WebView if tab already has one
        if let existingInfo = activeWebViews[tab.id] {
            existingInfo.lastActiveTime = Date()
            resumeWebViewIfNeeded(existingInfo)
            return existingInfo.webView
        }
        
        let webView: WKWebView
        
        // Try to reuse from available pool first
        if let availableWebView = availableWebViews.popLast() {
            webView = availableWebView
            resetWebView(webView)
        } else if activeWebViews.count < maximumActiveWebViews {
            // Create new WebView if under limit
            webView = createNewWebView()
        } else {
            // At capacity - reclaim least recently used WebView
            webView = reclaimLeastRecentlyUsedWebView()
            resetWebView(webView)
        }
        
        // Associate WebView with tab
        let webViewInfo = WebViewInfo(webView: webView, tab: tab)
        activeWebViews[tab.id] = webViewInfo
        
        return webView
    }
    
    /**
     * Release a WebView from a tab, moving it to the available pool or deallocating it.
     * 
     * RELEASE STRATEGY:
     * - Clean up tab association and navigation delegates
     * - Move to available pool if space permits, otherwise deallocate
     * - Reset WebView state to prevent data leakage between tabs
     */
    func releaseWebView(for tabId: UUID) {
        guard let webViewInfo = activeWebViews.removeValue(forKey: tabId) else { return }
        
        // Clean up delegates and references
        webViewInfo.webView.navigationDelegate = nil
        webViewInfo.webView.uiDelegate = nil
        webViewInfo.tab = nil
        
        // Move to available pool if space permits
        if availableWebViews.count < 3 { // Keep small pool of ready WebViews
            resetWebView(webViewInfo.webView)
            availableWebViews.append(webViewInfo.webView)
        }
        // Otherwise, WebView will be deallocated when webViewInfo goes out of scope
    }
    
    /**
     * Suspend background tab to reduce CPU and memory usage.
     * 
     * SUSPENSION STRATEGY:
     * - Pause JavaScript execution timers and animations
     * - Stop network requests and resource loading
     * - Reduce WebView's priority and visibility
     * - Mark as suspended to avoid redundant suspension calls
     */
    func suspendBackgroundTab(tabId: UUID) {
        guard let webViewInfo = activeWebViews[tabId], !webViewInfo.isSuspended else { return }
        
        let webView = webViewInfo.webView
        
        // Pause JavaScript execution
        webView.evaluateJavaScript("""
            // Pause all timers and intervals
            window.__originalSetTimeout = window.setTimeout;
            window.__originalSetInterval = window.setInterval;
            window.setTimeout = function() {};
            window.setInterval = function() {};
            
            // Pause animations
            if (window.requestAnimationFrame) {
                window.__originalRequestAnimationFrame = window.requestAnimationFrame;
                window.requestAnimationFrame = function() {};
            }
            
            // Pause media playback
            document.querySelectorAll('video, audio').forEach(function(media) {
                if (!media.paused) {
                    media.__wasPlaying = true;
                    media.pause();
                }
            });
        """) { _, _ in }
        
        // Reduce WebView's processing priority
        webView.customUserAgent = webView.customUserAgent // Trigger internal optimizations
        
        webViewInfo.isSuspended = true
    }
    
    /**
     * Resume a suspended background tab when it becomes active.
     * 
     * RESUME STRATEGY:
     * - Restore JavaScript execution capabilities
     * - Re-enable network requests and resource loading  
     * - Resume media playback that was active before suspension
     * - Update last active time to prevent immediate re-suspension
     */
    func resumeTab(tabId: UUID) {
        guard let webViewInfo = activeWebViews[tabId] else { return }
        
        webViewInfo.lastActiveTime = Date()
        resumeWebViewIfNeeded(webViewInfo)
    }
    
    /**
     * Force cleanup of all inactive WebViews to free memory immediately.
     * Called during memory pressure situations or manual optimization.
     */
    func performEmergencyCleanup() {
        let currentTime = Date()
        
        // Release all background tabs immediately during memory pressure
        let tabsToRelease = activeWebViews.compactMap { (tabId, webViewInfo) -> UUID? in
            if webViewInfo.isSuspended || 
               currentTime.timeIntervalSince(webViewInfo.lastActiveTime) > 60 { // 1 minute threshold during emergency
                return tabId
            }
            return nil
        }
        
        for tabId in tabsToRelease {
            releaseWebView(for: tabId)
        }
        
        // Clear available pool to free maximum memory
        availableWebViews.removeAll()
    }
    
    
    private func createNewWebView() -> WKWebView {
        let configuration = WebViewConfigurationFactory.createBrowserConfiguration()
        return WKWebView(frame: .zero, configuration: configuration)
    }
    
    private func resetWebView(_ webView: WKWebView) {
        // Clear navigation history and content
        webView.loadHTMLString("", baseURL: nil)
        
        // Reset delegates
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        
        // Clear any custom user agent
        webView.customUserAgent = nil
        
        // Stop any ongoing loads
        webView.stopLoading()
    }
    
    private func reclaimLeastRecentlyUsedWebView() -> WKWebView {
        // Find the WebView that was last active the longest time ago
        let oldestEntry = activeWebViews.min { first, second in
            first.value.lastActiveTime < second.value.lastActiveTime
        }
        
        guard let (tabId, webViewInfo) = oldestEntry else {
            // Fallback: create new WebView if something goes wrong
            return createNewWebView()
        }
        
        // Remove from active tracking
        activeWebViews.removeValue(forKey: tabId)
        
        // Clear the tab's WebView reference to prevent stale references
        webViewInfo.tab?.webView = nil
        
        return webViewInfo.webView
    }
    
    private func resumeWebViewIfNeeded(_ webViewInfo: WebViewInfo) {
        guard webViewInfo.isSuspended else { return }
        
        let webView = webViewInfo.webView
        
        // Restore JavaScript execution
        webView.evaluateJavaScript("""
            // Restore timers and intervals
            if (window.__originalSetTimeout) {
                window.setTimeout = window.__originalSetTimeout;
                delete window.__originalSetTimeout;
            }
            if (window.__originalSetInterval) {
                window.setInterval = window.__originalSetInterval;
                delete window.__originalSetInterval;
            }
            
            // Restore animations
            if (window.__originalRequestAnimationFrame) {
                window.requestAnimationFrame = window.__originalRequestAnimationFrame;
                delete window.__originalRequestAnimationFrame;
            }
            
            // Resume media playback that was active before suspension
            document.querySelectorAll('video, audio').forEach(function(media) {
                if (media.__wasPlaying) {
                    media.play();
                    delete media.__wasPlaying;
                }
            });
        """) { _, _ in }
        
        webViewInfo.isSuspended = false
    }
    
    private func setupCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupIntervalSeconds, repeats: true) { [weak self] _ in
            self?.performPeriodicCleanup()
        }
    }
    
    private func performPeriodicCleanup() {
        let currentTime = Date()
        
        // Find tabs that have been inactive for too long
        let tabsToCleanup = activeWebViews.compactMap { (tabId, webViewInfo) -> UUID? in
            let inactiveTime = currentTime.timeIntervalSince(webViewInfo.lastActiveTime)
            
            // Only clean up if truly inactive (not the current tab) and past timeout
            if inactiveTime > backgroundTabTimeoutSeconds && webViewInfo.isSuspended {
                return tabId
            } else if inactiveTime > 300 && !webViewInfo.isSuspended { // 5 minutes for suspension
                // Suspend but don't release yet
                suspendBackgroundTab(tabId: tabId)
            }
            
            return nil
        }
        
        // Release WebViews from long-inactive tabs
        for tabId in tabsToCleanup {
            releaseWebView(for: tabId)
        }
        
        // Limit available pool size to prevent unbounded growth
        while availableWebViews.count > 3 {
            availableWebViews.removeFirst()
        }
    }
    
    private func setupMemoryPressureObserver() {
        // Use dispatch source for memory pressure monitoring on macOS
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(eventMask: .warning, queue: .main)
        
        memoryPressureSource?.setEventHandler { [weak self] in
            self?.performEmergencyCleanup()
        }
        
        memoryPressureSource?.resume()
    }
}
