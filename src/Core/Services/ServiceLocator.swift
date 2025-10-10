import Foundation

/// Centralized service management with singleton access.
final class ServiceLocator {
    
    static let shared = ServiceLocator()
    
    private(set) lazy var appSettings = AppSettings.shared
    private(set) lazy var stateService = StateService.shared
    private(set) lazy var windowService = WindowService.shared
    private(set) lazy var keyboardService = KeyboardService.shared
    
    private init() {}
    
    
    /// Access to application settings
    var settings: AppSettings {
        return appSettings
    }
    
    
    /// Access to application state management
    var state: StateService {
        return stateService
    }
    
    /// Access to window management services
    var window: WindowService {
        return windowService
    }

    /// Access to keyboard shortcut management
    var keyboard: KeyboardService {
        return keyboardService
    }
    
    
    #if DEBUG
    /// Reset all services for testing purposes
    func resetForTesting() {
        // This would be implemented if needed for unit testing
        // to provide fresh instances of services
    }
    #endif
}


extension ServiceLocator {

    /// Quick access to commonly used services
    static var settings: AppSettings {
        return shared.settings
    }

    static var state: StateService {
        return shared.state
    }

    static var window: WindowService {
        return shared.window
    }
}
