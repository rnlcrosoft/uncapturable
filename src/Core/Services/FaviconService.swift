import Foundation
import WebKit
import SwiftUI

/// Centralized favicon discovery and caching service.
class FaviconService {
    static let shared = FaviconService()
    
    
    /// JavaScript for favicon URL discovery with multi-stage fallback
    private let faviconDiscoveryScript = """
    (function() {
        // Try multiple favicon selectors in order of preference
        var favicon = document.querySelector('link[rel*="icon"]') ||
                      document.querySelector('link[rel="shortcut icon"]') ||
                      document.querySelector('link[rel="apple-touch-icon"]');
        
        if (favicon && favicon.href) {
            return favicon.href;
        }
        
        // Fallback to standard favicon location
        return window.location.origin + '/favicon.ico';
    })();
    """
    
    private init() {}
    
    
    /**
     * Extract favicon from WebView and provide base64 data for persistence.
     * 
     * EXTRACTION STRATEGY:
     * 1. Check domain cache for existing favicon
     * 2. Execute JavaScript to discover favicon URL
     * 3. Download favicon and cache by domain
     * 4. Return base64 data for StateService storage
     */
    func extractFaviconData(from webView: WKWebView, completion: @escaping (String?) -> Void) {
        guard let url = webView.url else {
            completion(nil)
            return
        }
        
        let domain = StateService.domain(from: url)
        
        // Check cache first
        if let cachedFavicon = StateService.shared.getFaviconData(for: domain) {
            completion(cachedFavicon)
            return
        }
        
        // Discover and download favicon
        discoverFaviconURL(from: webView) { [weak self] faviconURL in
            guard let self = self, let faviconURL = faviconURL else {
                completion(nil)
                return
            }
            
            self.downloadAndCacheFavicon(from: faviconURL, domain: domain, completion: completion)
        }
    }
    
    /**
     * Extract favicon from WebView and provide SwiftUI Image for immediate UI use.
     * 
     * UI INTEGRATION: Optimized for SwiftUI Image usage with NSImage conversion
     * and main-thread updates for smooth UI performance.
     */
    func extractFaviconImage(from webView: WKWebView, completion: @escaping (Image?) -> Void) {
        discoverFaviconURL(from: webView) { [weak self] faviconURL in
            guard let self = self, let faviconURL = faviconURL else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            self.downloadFaviconAsImage(from: faviconURL, completion: completion)
        }
    }
    
    
    /**
     * Discover favicon URL using JavaScript evaluation.
     */
    private func discoverFaviconURL(from webView: WKWebView, completion: @escaping (URL?) -> Void) {
        webView.evaluateJavaScript(faviconDiscoveryScript) { result, error in
            guard let urlString = result as? String,
                  let url = URL(string: urlString) else {
                completion(nil)
                return
            }
            
            completion(url)
        }
    }
    
    /**
     * Download favicon and cache by domain, returning base64 data.
     */
    private func downloadAndCacheFavicon(from url: URL, domain: String, completion: @escaping (String?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  data.count > 0 else {
                completion(nil)
                return
            }
            
            // Store in domain cache
            StateService.shared.setFaviconData(data, for: domain)
            
            // Return base64 string for persistence
            let base64String = data.base64EncodedString()
            completion(base64String)
        }.resume()
    }
    
    /**
     * Download favicon and convert to SwiftUI Image for UI use.
     */
    private func downloadFaviconAsImage(from url: URL, completion: @escaping (Image?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let nsImage = NSImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // Convert to SwiftUI Image on main thread
            DispatchQueue.main.async {
                completion(Image(nsImage: nsImage))
            }
        }.resume()
    }
}
