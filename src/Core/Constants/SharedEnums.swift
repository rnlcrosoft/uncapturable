import Foundation
import SwiftUI

/// Browser application domain types and state definitions.


/**
 * Defines the fundamental types of content that can be displayed in browser tabs.
 *
 * ARCHITECTURE RATIONALE: Using an enum with associated values allows type-safe
 * handling of different tab content types while maintaining a unified tab interface.
 * This prevents invalid state combinations (e.g., settings tabs with URLs).
 *
 * TAB CONTENT CATEGORIES:
 * - empty: New tab page or welcome screen for user onboarding
 * - web: Standard web browsing with URL navigation and history
 * - settings: Application configuration and preferences interface
 */
enum TabContentType: Equatable {
    /// Empty tab showing welcome screen or new tab page for user onboarding
    case empty

    /// Web content tab displaying a specific URL (or nil for address bar input)
    case web(URL?)

    /// Application settings interface of specified category
    case settings(ApplicationSettingsCategory)
}

/**
 * Categories of application settings available through the settings interface.
 *
 * SETTINGS ORGANIZATION RATIONALE: Categories are organized by user mental model
 * rather than technical implementation. Users think in terms of "browser features",
 * "window behavior", "privacy", etc. rather than technical component boundaries.
 *
 * ICON SELECTION: System icons chosen to match standard macOS app conventions
 * for maximum user familiarity and accessibility.
 *
 * SETTINGS CATEGORIES:
 * - browserSettings: Core browsing features (search engine, homepage, bookmarks)
 * - windowSettings: Window behavior and layout preferences
 */
enum ApplicationSettingsCategory: CaseIterable {
    /// Core browser functionality settings (search engine, homepage, bookmarks)
    case browserSettings

    /// Window management and display preferences
    case windowSettings

    /**
     * User-facing display names for settings categories.
     * These names appear in the sidebar navigation and page titles.
     *
     * NAMING PRINCIPLE: Use clear, descriptive names that match user expectations
     * and standard macOS application terminology.
     */
    var title: String {
        switch self {
        case .browserSettings:
            return "Browser Settings"
        case .windowSettings:
            return "Window Settings"
        }
    }

    /**
     * System icons representing each settings category.
     *
     * ACCESSIBILITY NOTE: These icons have built-in VoiceOver support
     * and automatically adapt to user's preferred icon style (filled vs outline).
     *
     * ICON DESIGN PRINCIPLES:
     * - Use standard SF Symbols for consistency with macOS
     * - Choose metaphors that are universally understood
     * - Ensure icons remain clear at small sizes (16x16 points)
     */
    var icon: Image {
        switch self {
        case .browserSettings:
            return Image(systemName: "magnifyingglass")  // Search/discovery features
        case .windowSettings:
            return Image(systemName: "macwindow")        // Window behavior controls
        }
    }
}

/**
 * Supported search engines for address bar queries and search functionality.
 *
 * PROVIDER SELECTION RATIONALE: These four engines cover the vast majority
 * of user preferences across different priorities:
 * - Google: Market leader, best general search quality
 * - Bing: Microsoft integration, good for enterprise users
 * - DuckDuckGo: Privacy-focused, no tracking
 * - Yahoo: Legacy compatibility, some regional preferences
 *
 * EXTENSIBILITY: Adding new search engines requires:
 * 1. New case in this enum
 * 2. Display name in `name` computed property
 * 3. Search URL template in AppConstants.SearchEngineSettings.QueryURLTemplates
 *
 * SEARCH ENGINE FEATURES:
 * - google: Comprehensive web search with advanced algorithms
 * - bing: Microsoft's search with good image and video search
 * - duckduckgo: Privacy-focused search without user tracking
 * - yahoo: Traditional search with news and content integration
 */
enum SearchEngineProvider: String, CaseIterable, Identifiable {
    case google = "google"
    case bing = "bing"
    case duckduckgo = "duckduckgo"
    case yahoo = "yahoo"

    /// Unique identifier for SwiftUI list/picker components
    var id: String { rawValue }

    /**
     * User-facing names for search engine selection UI.
     * These appear in settings dropdowns and user preferences.
     *
     * BRANDING NOTE: Use official brand names to maintain user recognition
     * and trust. These names match what users expect to see.
     */
    var name: String {
        switch self {
        case .google:
            return "Google"
        case .bing:
            return "Microsoft Bing"
        case .duckduckgo:
            return "DuckDuckGo"
        case .yahoo:
            return "Yahoo Search"
        }
    }

    /**
     * Base URL for search queries - search terms are appended to these URLs.
     *
     * USAGE PATTERN: Address bar input that doesn't parse as a URL gets
     * URL-encoded and appended to the appropriate searchURL.
     *
     * EXAMPLE: User types "swift programming" →
     * "https://www.google.com/search?q=swift%20programming"
     *
     * URL STRUCTURE: Each provider uses standard query parameter formats
     * that are well-documented and stable over time.
     */
    var searchURL: String {
        switch self {
        case .google:
            return AppConstants.SearchEngineSettings.QueryURLTemplates.googleSearchBase
        case .bing:
            return AppConstants.SearchEngineSettings.QueryURLTemplates.bingSearchBase
        case .duckduckgo:
            return AppConstants.SearchEngineSettings.QueryURLTemplates.duckDuckGoSearchBase
        case .yahoo:
            return AppConstants.SearchEngineSettings.QueryURLTemplates.yahooSearchBase
        }
    }
}

/**
 * Directions for browser navigation operations.
 *
 * These map directly to WebView navigation capabilities and provide
 * type-safe routing for navigation button actions and keyboard shortcuts.
 *
 * NAVIGATION OPERATIONS:
 * - navigateBackward: Move back in tab's browsing history stack
 * - navigateForward: Move forward in tab's history (after going back)
 * - reloadCurrentPage: Refresh current page content from server
 * - stopCurrentPageLoad: Cancel ongoing page load operation
 */
enum BrowserNavigationDirection {
    /// Navigate to previous page in tab's history stack
    case navigateBackward

    /// Navigate to next page in tab's history stack (if available after going back)
    case navigateForward

    /// Reload current page content from server
    case navigateReload

    /// Stop loading current page (if load is in progress)
    case stopCurrentPageLoad
}

/**
 * Possible states for the application window.
 *
 * WINDOW MANAGEMENT RATIONALE: Explicit state tracking allows the app to:
 * - Restore previous window state on app restart
 * - Handle window state transitions properly
 * - Provide appropriate UI feedback for each state
 * - Support keyboard shortcuts for window state changes
 *
 * WINDOW STATES:
 * - normalSized: Standard windowed mode with user-resizable dimensions
 * - minimizedToHidden: Window hidden in dock, not visible on screen
 * - maximizedToFillScreen: Window expanded to fill available screen space
 * - fullScreenMode: Immersive mode hiding menu bar and dock
 */
enum ApplicationWindowState {
    /// Standard windowed mode with user-controlled size and position
    case normalSized

    /// Window minimized to dock, not visible on desktop
    case minimizedToHidden

    /// Window expanded to fill available screen space (not full screen)
    case maximizedToFillScreen

    /// Immersive full screen mode hiding system UI elements
    case fullScreenMode
}

/**
 * Backward compatibility aliases for enum types.
 *
 * MIGRATION STRATEGY: These aliases maintain compatibility with existing code
 * that references the old type names, allowing gradual migration to more
 * descriptive names throughout the codebase.
 *
 * DEPRECATION TIMELINE: These aliases should be removed after all usage
 * sites have been migrated to the new, more descriptive type names.
 */

/// Legacy alias - use TabContentType instead for new code
@available(*, deprecated, message: "Use TabContentType instead")
typealias TabType = TabContentType

/// Legacy alias - use ApplicationSettingsCategory instead for new code
@available(*, deprecated, message: "Use ApplicationSettingsCategory instead")
typealias SettingsType = ApplicationSettingsCategory

/// Legacy alias - use SearchEngineProvider instead for new code
@available(*, deprecated, message: "Use SearchEngineProvider instead")
typealias SearchEngine = SearchEngineProvider

/// Legacy alias - use BrowserNavigationDirection instead for new code
@available(*, deprecated, message: "Use BrowserNavigationDirection instead")
typealias NavigationDirection = BrowserNavigationDirection

/// Legacy alias - use ApplicationWindowState instead for new code
@available(*, deprecated, message: "Use ApplicationWindowState instead")
typealias WindowState = ApplicationWindowState
