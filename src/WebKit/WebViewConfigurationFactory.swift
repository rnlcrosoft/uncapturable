import WebKit

/**
 * WebViewConfigurationFactory - Centralized WebKit Configuration Management
 * 
 * Provides a single source of truth for WebView configuration, ensuring consistency
 * across all WebView instances while avoiding redundant default settings.
 * 
 * DESIGN PHILOSOPHY: Only configure non-default settings to minimize overhead
 * and make intentional configuration choices explicit.
 */
struct WebViewConfigurationFactory {
    
    /**
     * Creates a standard WebView configuration for browser tabs.
     * 
     * CONFIGURATION STRATEGY: Only sets non-default values that are required
     * for the browser's functionality. WebKit defaults are sufficient for:
     * - JavaScript execution (enabled by default)
     * - Default website data store
     * - Tab focus behavior
     * - Basic navigation preferences
     */
    static func createBrowserConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        
        // User agent - Required for maximum site compatibility
        configuration.applicationNameForUserAgent = "Version/17.0 Safari/605.1.15"
        
        // Security preferences - Override defaults for browser security
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        // Modern web features - Enable when available
        if #available(macOS 12.0, *) {
            configuration.upgradeKnownHostsToHTTPS = true
        }
        
        return configuration
    }
    
    /**
     * Creates a privacy-focused configuration for non-persistent browsing.
     * Used for screenshot preview and temporary operations.
     */
    static func createNonPersistentConfiguration() -> WKWebViewConfiguration {
        let configuration = createBrowserConfiguration()
        
        // Use non-persistent data store for privacy
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        
        // Additional privacy restrictions
        configuration.preferences.isElementFullscreenEnabled = false
        configuration.mediaTypesRequiringUserActionForPlayback = [.all]
        
        return configuration
    }
}
