import Foundation

/// Application settings management with persistence.

@Observable
class AppSettings {
    static let shared = AppSettings()
    
    /**
     * Default search engine provider (legacy compatibility).
     * 
     * MIGRATION NOTE: This property provides backward compatibility for existing code
     * that directly accesses the built-in search engine. New code should use
     * SearchEngineManager for unified built-in + custom engine handling.
     */
    var defaultSearchEngine: SearchEngineProvider {
        get {
            // Always return Google as the only search engine
            return .google
        }
        set {
            // Always Google - no setting changes
            saveSettings()
        }
    }
    
    var isHistoryCollectionEnabled: Bool = false {
        didSet { 
            saveSettings()
            if !isHistoryCollectionEnabled {
                // Clear existing history when collection is disabled
                StateService.shared.clearHistory()
            }
        }
    }
    
    private init() {
        loadSettings()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        isHistoryCollectionEnabled = defaults.object(forKey: "isHistoryCollectionEnabled") as? Bool ?? false
        
        // Migration: Remove old defaultSearchEngine setting (Google only now)
        defaults.removeObject(forKey: "defaultSearchEngine")
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isHistoryCollectionEnabled, forKey: "isHistoryCollectionEnabled")
        // Note: Search engine settings are now managed by SearchEngineManager
    }
}
