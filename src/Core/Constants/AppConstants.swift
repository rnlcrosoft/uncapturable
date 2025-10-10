import Foundation

/// Application constants and configuration values.
struct AppConstants {
    struct ApplicationIdentity {
        static let name = "uncapturable"
        static let version = "1.0.0"
        static let bundleIdentifier = "xyz.lazysoft.lazyoffice"
        
        // User-Agent string for HTTP requests - identifies our browser to web servers
        // Format follows standard convention: AppName/Version (Platform)
        static let httpUserAgent = "uncapturable/1.0 (macOS)"
    }
    
    
    /**
     * Search engine settings and URL templates for address bar queries.
     * 
     * DEFAULT ENGINE RATIONALE: Google chosen as default due to:
     * - Highest market share and user familiarity
     * - Best search result quality for general queries
     * - Most comprehensive web index coverage
     * 
     * PRIVACY NOTE: Users can change to DuckDuckGo for privacy-focused searching.
     */
    struct SearchEngineSettings {
        static let defaultSearchEngine = SearchEngineProvider.google
        
        /**
         * Search URL templates - append query string after these URLs.
         * These URLs are the base endpoints where search queries are appended.
         */
        struct QueryURLTemplates {
            static let googleSearchBase = "https://www.google.com/search?q="
            static let bingSearchBase = "https://www.bing.com/search?q="
            static let duckDuckGoSearchBase = "https://duckduckgo.com/?q="
            static let yahooSearchBase = "https://search.yahoo.com/search?p="
        }
    }
    
    
    /**
     * File system interaction limits and supported file type definitions.
     * 
     * These limits prevent resource exhaustion and provide clear user expectations
     * about what file types the browser can handle effectively.
     */
    struct FileOperationLimits {
        // File type arrays for quick lookup - organized by functional category
        static let supportedImageFileExtensions = ["png", "jpg", "jpeg", "gif", "webp", "svg"]
        static let supportedDocumentFileExtensions = ["pdf", "txt", "doc", "docx"]
        
        /**
         * Maximum file size for downloads and file operations.
         * 
         * RATIONALE: 100MB limit chosen to balance:
         * - User expectations (can download most common files)
         * - Memory constraints (prevents app from consuming excessive RAM)
         * - Performance (large files can block UI operations)
         * 
         * BEHAVIOR: Files exceeding this limit trigger a warning dialog
         * asking user confirmation before proceeding with download.
         */
        static let maxDownloadSizeBytes: Int64 = 100 * 1024 * 1024  // 100 MB
    }
    
    
    /**
     * Network request behavior and timeout settings.
     * 
     * These values balance responsiveness with reliability for various
     * network conditions users might encounter.
     */
    struct NetworkOperationSettings {
        /**
         * HTTP request timeout for general web requests.
         * 
         * RATIONALE: 30 seconds chosen as compromise between:
         * - User patience (typical user abandons after 10-15 seconds)
         * - Slow connection support (some mobile/satellite connections need time)
         * - Resource cleanup (prevents indefinite connection holding)
         * 
         * BEHAVIOR: After timeout, request fails with user-visible error message.
         */
        static let httpRequestTimeoutSeconds: TimeInterval = 30.0
        
        /**
         * Maximum simultaneous downloads to prevent overwhelming the system.
         * 
         * RATIONALE: 3 concurrent downloads limit chosen because:
         * - Prevents bandwidth starvation of other apps
         * - Maintains responsive UI during downloads
         * - Typical user rarely needs more than 3 simultaneous downloads
         * 
         * BEHAVIOR: Additional downloads queue until slots become available.
         */
        static let maxConcurrentDownloadsCount = 3
    }
    
    
    /**
     * Cache sizes and data retention policies to balance performance with storage usage.
     * 
     * These limits prevent unbounded data growth while maintaining good user experience
     * through effective caching of frequently accessed data.
     */
    struct DataStorageLimits {
        /**
         * Maximum number of history items retained in memory and persistent storage.
         * 
         * RATIONALE: 1000 items chosen because:
         * - Covers approximately 1-2 months of typical browsing for average user
         * - Keeps memory usage reasonable (each item ~200 bytes = ~200KB total)
         * - Provides sufficient history for meaningful search/autocomplete
         * 
         * CLEANUP BEHAVIOR: When limit exceeded, oldest items are removed (FIFO).
         */
        static let maxBrowserHistoryItemsCount = 1000
        
        /**
         * Cookie retention period before automatic cleanup.
         * 
         * RATIONALE: 30 days chosen to match common web session expectations:
         * - Most "remember me" functionality expects ~30 day persistence
         * - Balances user convenience with privacy concerns
         * - Aligns with typical browser cookie retention policies
         * 
         * CLEANUP BEHAVIOR: Cookies older than this are purged during app startup.
         */
        static let maxCookieRetentionSeconds: TimeInterval = 86400 * 30  // 30 days (86400 sec/day)
        
        /**
         * Maximum number of favicon images cached in memory.
         * 
         * RATIONALE: 50 favicons chosen because:
         * - Each favicon ~2-8KB (typical PNG) = ~400KB total maximum
         * - Covers typical user's most frequently visited sites
         * - Provides instant loading for common sites while limiting memory usage
         * 
         * EVICTION POLICY: Least Recently Used (LRU) - oldest accessed favicons removed first.
         */
        static let maxCachedFaviconImagesCount = 50
    }
    
    
    /**
     * File type identification mappings for consistent UTI and MIME type detection.
     * 
     * DESIGN RATIONALE: Centralized lookup tables provide faster, more maintainable
     * file type detection than large switch statements. This approach also enables
     * easy addition of new file types without code complexity growth.
     */
    struct FileTypeIdentification {
        
        /**
         * File extension to UTI identifier mapping.
         * 
         * COVERAGE: Includes common web, document, media, and archive formats
         * that users frequently encounter in browser downloads.
         */
        static let extensionToUTIMapping: [String: String] = [
            // Image formats
            "jpg": "public.jpeg", "jpeg": "public.jpeg", "png": "public.png",
            "gif": "com.compuserve.gif", "webp": "org.webmproject.webp",
            "tiff": "public.tiff", "tif": "public.tiff", "bmp": "com.microsoft.bmp",
            "ico": "com.microsoft.ico", "svg": "public.svg-image",
            
            // Document formats  
            "pdf": "com.adobe.pdf", "doc": "com.microsoft.word.doc",
            "docx": "org.openxmlformats.wordprocessingml.document",
            "xls": "com.microsoft.excel.xls", "xlsx": "org.openxmlformats.spreadsheetml.sheet",
            "ppt": "com.microsoft.powerpoint.ppt", "pptx": "org.openxmlformats.presentationml.presentation",
            "rtf": "public.rtf", "txt": "public.plain-text",
            
            // Archive formats
            "zip": "public.zip-archive", "rar": "com.rarlab.rar-archive",
            "7z": "org.7-zip.7-zip-archive", "tar": "public.tar-archive", "gz": "org.gnu.gnu-zip-archive",
            
            // Audio formats
            "mp3": "public.mp3", "wav": "com.microsoft.waveform-audio", "m4a": "public.mpeg-4-audio",
            "flac": "org.xiph.flac", "aac": "public.aac-audio",
            
            // Video formats
            "mp4": "public.mpeg-4", "mov": "com.apple.quicktime-movie", "avi": "public.avi",
            "mkv": "org.matroska.mkv", "webm": "org.webmproject.webm",
            
            // Web formats
            "html": "public.html", "htm": "public.html", "css": "public.css",
            "js": "com.netscape.javascript-source", "json": "public.json", 
            "xml": "public.xml", "csv": "public.comma-separated-values-text"
        ]
        
        /**
         * File extension to MIME type mapping.
         */
        static let extensionToMIMETypeMapping: [String: String] = [
            // Image formats
            "jpg": "image/jpeg", "jpeg": "image/jpeg", "png": "image/png", "gif": "image/gif",
            "webp": "image/webp", "tiff": "image/tiff", "tif": "image/tiff", "bmp": "image/bmp", "svg": "image/svg+xml",
            
            // Document formats
            "pdf": "application/pdf", "doc": "application/msword", "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "xls": "application/vnd.ms-excel", "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "ppt": "application/vnd.ms-powerpoint", "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "txt": "text/plain", "rtf": "application/rtf",
            
            // Archive formats
            "zip": "application/zip", "rar": "application/vnd.rar", "7z": "application/x-7z-compressed",
            "tar": "application/x-tar", "gz": "application/gzip",
            
            // Audio formats
            "mp3": "audio/mpeg", "wav": "audio/wav", "m4a": "audio/mp4", "flac": "audio/flac", "aac": "audio/aac",
            
            // Video formats
            "mp4": "video/mp4", "mov": "video/quicktime", "avi": "video/x-msvideo", "mkv": "video/x-matroska", "webm": "video/webm",
            
            // Web formats
            "html": "text/html", "htm": "text/html", "css": "text/css", "js": "application/javascript",
            "json": "application/json", "xml": "application/xml", "csv": "text/csv"
        ]
        
        /// Fallback UTI for unknown file types
        static let fallbackUTI = "public.data"
        
        /// Fallback MIME type for unknown file types
        static let fallbackMIMEType = "application/octet-stream"
    }
    
    
    /**
     * Organized file type categories for consistent classification across the application.
     * 
     * DESIGN RATIONALE: Category-based classification enables feature-specific behavior
     * (e.g., auto-download archives, display images in browser) while maintaining
     * a single source of truth for file type relationships.
     */
    struct FileTypeCategories {
        
        /// Document file extensions - files typically opened with productivity applications
        static let documentExtensions: Set<String> = [
            "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "rtf", "txt"
        ]
        
        /// Archive file extensions - compressed/container formats requiring extraction
        static let archiveExtensions: Set<String> = [
            "zip", "rar", "7z", "tar", "gz", "bz2"
        ]
        
        /// Image file extensions - visual content displayable inline in browser
        static let imageExtensions: Set<String> = [
            "jpg", "jpeg", "png", "gif", "webp", "tiff", "tif", "bmp", "ico", "svg"
        ]
        
        /// Audio file extensions - sound content requiring media player
        static let audioExtensions: Set<String> = [
            "mp3", "wav", "m4a", "flac", "aac"
        ]
        
        /// Video file extensions - motion picture content requiring media player
        static let videoExtensions: Set<String> = [
            "mp4", "mov", "avi", "mkv", "webm"
        ]
        
        /// Web file extensions - content typically displayed in browser
        static let webExtensions: Set<String> = [
            "html", "htm", "css", "js", "json", "xml", "csv"
        ]
        
        /// Software file extensions - executable or installer content
        static let softwareExtensions: Set<String> = [
            "dmg", "pkg", "exe", "msi", "deb", "rpm"
        ]
        
        /// All media file extensions (audio + video) for convenience
        static let mediaExtensions: Set<String> = audioExtensions.union(videoExtensions)
    }
    
    
    /**
     * SF Symbol icon mappings for file type visual representation.
     * 
     * ICON STRATEGY: Maps file extensions to appropriate SF Symbols for
     * consistent visual file type identification across the application.
     */
    struct FileTypeIcons {
        
        /// Default icon for unknown file types
        static let defaultIcon = "doc"
        
        /// File extension to SF Symbol name mapping
        static let extensionToIconMapping: [String: String] = [
            // Document formats
            "pdf": "doc.richtext",
            "doc": "doc.text", "docx": "doc.text",
            "xls": "tablecells", "xlsx": "tablecells",
            "ppt": "slider.horizontal.below.rectangle", "pptx": "slider.horizontal.below.rectangle",
            "txt": "doc.plaintext", "rtf": "doc.richtext",
            
            // Archive formats
            "zip": "archivebox", "rar": "archivebox", "7z": "archivebox",
            "tar": "archivebox", "gz": "archivebox", "bz2": "archivebox",
            
            // Image formats
            "jpg": "photo", "jpeg": "photo", "png": "photo", "gif": "photo",
            "webp": "photo", "tiff": "photo", "tif": "photo", "bmp": "photo",
            "ico": "photo", "svg": "photo",
            
            // Audio formats
            "mp3": "music.note", "wav": "music.note", "m4a": "music.note",
            "flac": "music.note", "aac": "music.note",
            
            // Video formats
            "mp4": "play.rectangle", "mov": "play.rectangle", "avi": "play.rectangle",
            "mkv": "play.rectangle", "webm": "play.rectangle",
            
            // Web formats
            "html": "globe", "htm": "globe", "css": "paintbrush", "js": "curlybraces",
            "json": "curlybraces", "xml": "doc.text", "csv": "tablecells",
            
            // Software formats
            "dmg": "shippingbox", "pkg": "shippingbox", "exe": "app", "msi": "app"
        ]
    }
    
    
    /**
     * Configuration for determining when files should be downloaded vs. displayed in browser.
     * 
     * DOWNLOAD STRATEGY: Balances user expectations with security considerations.
     * Generally downloads binary/executable content while displaying web-native formats.
     */
    struct DownloadBehavior {
        
        /// MIME types that should always trigger download instead of browser display
        static let downloadableMimeTypes: Set<String> = [
            // Archives
            "application/zip", "application/x-zip-compressed", "application/x-rar-compressed",
            "application/x-7z-compressed", "application/x-tar", "application/gzip",
            
            // Documents (some browsers can display, but download provides better UX)
            "application/pdf", "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/vnd.ms-excel",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "application/vnd.ms-powerpoint",
            "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            
            // Media (large files better downloaded than streamed)
            "application/octet-stream", "video/mp4", "video/mpeg", "video/quicktime",
            "audio/mpeg", "audio/wav", "audio/mp4",
            
            // Software and executables
            "application/x-apple-diskimage", "application/vnd.apple.installer+xml",
            "application/x-ms-dos-executable", "application/x-msdownload"
        ]
        
        /// File extensions that should always trigger download instead of browser display
        static let downloadableExtensions: Set<String> = [
            // Archives
            "zip", "rar", "7z", "tar", "gz", "bz2",
            
            // Documents
            "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx",
            
            // Media
            "mp4", "avi", "mov", "wmv", "mp3", "wav", "aac",
            
            // Software
            "dmg", "pkg", "exe", "msi", "deb", "rpm"
        ]
    }
}


/**
 * Centralized notification name definitions for type-safe inter-component communication.
 * 
 * ARCHITECTURE RATIONALE: Using typed notification names prevents runtime errors
 * from string typos and provides compile-time verification of notification usage.
 * All notifications follow consistent naming: actionTarget pattern (e.g., "createTab", "navigateBack").
 * 
 * USAGE PATTERN: These notifications decouple UI components from business logic,
 * allowing keyboard shortcuts, menu items, and UI buttons to trigger the same actions
 * without tight coupling between components.
 */
extension Notification.Name {
    
    
    /// Request creation of a new browser tab (typically empty/welcome page)
    static let createNewTab = Notification.Name("createNewTab")
    
    /// Request closure of the currently active tab
    static let closeCurrentTab = Notification.Name("closeCurrentTab")
    
    /// Request reopening of the most recently closed tab (undo close operation)
    static let reopenMostRecentlyClosedTab = Notification.Name("reopenMostRecentlyClosedTab")
    
    /// Request reload of current tab's web content (or stop loading if in progress)
    static let reloadCurrentTabContent = Notification.Name("reloadCurrentTabContent")
    
    
    /// Request backward navigation in current tab's history stack
    static let navigateBackInCurrentTab = Notification.Name("navigateBackInCurrentTab")
    
    /// Request forward navigation in current tab's history stack  
    static let navigateForwardInCurrentTab = Notification.Name("navigateForwardInCurrentTab")
    
    /// Request switching to the next tab in the tab bar (wraps to first if at end)
    static let switchToNextTab = Notification.Name("switchToNextTab")
    
    /// Request switching to the previous tab in the tab bar (wraps to last if at beginning)
    static let switchToPreviousTab = Notification.Name("switchToPreviousTab")
    
    
    /// Request switching to tab at position 1 (first tab)
    static let switchToTabAtIndex1 = Notification.Name("switchToTabAtIndex1")
    static let switchToTabAtIndex2 = Notification.Name("switchToTabAtIndex2")
    static let switchToTabAtIndex3 = Notification.Name("switchToTabAtIndex3")
    static let switchToTabAtIndex4 = Notification.Name("switchToTabAtIndex4")
    static let switchToTabAtIndex5 = Notification.Name("switchToTabAtIndex5")
    static let switchToTabAtIndex6 = Notification.Name("switchToTabAtIndex6")
    static let switchToTabAtIndex7 = Notification.Name("switchToTabAtIndex7")
    static let switchToTabAtIndex8 = Notification.Name("switchToTabAtIndex8")
    static let switchToTabAtIndex9 = Notification.Name("switchToTabAtIndex9")
    
    
    /// Request opening of the application settings/preferences interface
    static let openApplicationSettings = Notification.Name("openApplicationSettings")
    
    /// Request focus on the address bar for URL/search input
    static let focusAddressBarForInput = Notification.Name("focusAddressBarForInput")
}


/**
 * Backward compatibility aliases for notification names.
 * 
 * MIGRATION STRATEGY: These aliases maintain compatibility with existing code
 * while allowing gradual migration to more descriptive names. New code should
 * use the descriptive names above.
 * 
 * TODO: Remove these aliases after migrating all usage sites to new names.
 */
extension Notification.Name {
    // Legacy tab management aliases
    @available(*, deprecated, message: "Use createNewTab instead")
    static let newTab = createNewTab
    
    @available(*, deprecated, message: "Use closeCurrentTab instead") 
    static let closeTab = closeCurrentTab
    
    @available(*, deprecated, message: "Use reloadCurrentTabContent instead")
    static let reload = reloadCurrentTabContent
    
    @available(*, deprecated, message: "Use reopenMostRecentlyClosedTab instead")
    static let reopenClosedTab = reopenMostRecentlyClosedTab
    
    // Legacy navigation aliases
    @available(*, deprecated, message: "Use navigateBackInCurrentTab instead")
    static let navigateBack = navigateBackInCurrentTab
    
    @available(*, deprecated, message: "Use navigateForwardInCurrentTab instead")
    static let navigateForward = navigateForwardInCurrentTab
    
    @available(*, deprecated, message: "Use switchToNextTab instead")
    static let nextTab = switchToNextTab
    
    @available(*, deprecated, message: "Use switchToPreviousTab instead")
    static let previousTab = switchToPreviousTab
    
    // Legacy tab selection aliases
    @available(*, deprecated, message: "Use switchToTabAtIndex1 instead")
    static let selectTab1 = switchToTabAtIndex1
    
    @available(*, deprecated, message: "Use switchToTabAtIndex2 instead")
    static let selectTab2 = switchToTabAtIndex2
    
    @available(*, deprecated, message: "Use switchToTabAtIndex3 instead")
    static let selectTab3 = switchToTabAtIndex3
    
    @available(*, deprecated, message: "Use switchToTabAtIndex4 instead")
    static let selectTab4 = switchToTabAtIndex4
    
    @available(*, deprecated, message: "Use switchToTabAtIndex5 instead")
    static let selectTab5 = switchToTabAtIndex5
    
    @available(*, deprecated, message: "Use switchToTabAtIndex6 instead")
    static let selectTab6 = switchToTabAtIndex6
    
    @available(*, deprecated, message: "Use switchToTabAtIndex7 instead")
    static let selectTab7 = switchToTabAtIndex7
    
    @available(*, deprecated, message: "Use switchToTabAtIndex8 instead")
    static let selectTab8 = switchToTabAtIndex8
    
    @available(*, deprecated, message: "Use switchToTabAtIndex9 instead")
    static let selectTab9 = switchToTabAtIndex9
    
    // Legacy UI aliases
    @available(*, deprecated, message: "Use openApplicationSettings instead")
    static let openSettings = openApplicationSettings
    
    @available(*, deprecated, message: "Use focusAddressBarForInput instead")
    static let focusAddressBar = focusAddressBarForInput
}


/**
 * UserInterfaceText - Centralized Text Content Management
 * 
 * This structure centralizes all user-facing text content to ensure consistency,
 * maintainability, and preparation for future localization efforts.
 * 
 * DESIGN PHILOSOPHY: Text content is organized by functional domain and follows
 * consistent tone and style guidelines throughout the application.
 * 
 * TONE GUIDELINES:
 * - Professional and formal language
 * - Clear, benefit-focused descriptions
 * - Consistent terminology across features
 * - Active voice where appropriate
 * - Complete sentences with proper grammar
 * 
 * ORGANIZATION STRATEGY: Content is grouped by interface section rather than
 * technical implementation, making it easier to maintain related text together
 * and ensure consistency within functional areas.
 */
extension AppConstants {
    
    struct UserInterfaceText {
        
        
        /**
         * Settings page content emphasizing configuration benefits and clear feature explanations.
         * 
         * CONTENT APPROACH: Each settings section provides clear value proposition
         * followed by detailed feature explanations to help users make informed decisions.
         */
        struct Settings {
            
            struct Browser {
                static let pageTitle = "Search"
                static let pageDescription = "Choose your default search engine"
                static let searchEngineLabel = "Default Search Engine"
                static let searchEngineDescription = "Select your preferred search provider for address bar queries and search operations."
            }
            
            struct Window {
                static let pageTitle = "Windows"
                static let pageDescription = "Customize window behavior and appearance"
                
                // Professional Features Section
                static let privacyFeaturesTitle = "Features"
                static let presentationModeLabel = "Screen Recording Protection"
                static let presentationModeDescription = "Prevents window from appearing in recordings"
                static let cleanInterfaceModeLabel = "Preserve Other App Controls"
                static let trafficLightPreventionDescription = "Keeps other apps' buttons active when switching"
                static let desktopPinningLabel = "Pin to Current Desktop"
                static let desktopPinningDescription = "Window stays on current desktop only"
                
                // Window Behavior Section
                static let alwaysOnTopLabel = "Keep Above Other Windows"
                static let alwaysOnTopDescription = "Window floats above all other apps"
                
                // Window Transparency Section
                static let transparencyTitle = "Transparency"
                static let transparencyToggleLabel = "See Through Windows"
                static let transparencyToggleDescription = "Makes window semi-transparent"
                static let transparencyLevelLabel = "Transparency Level"
                
                // Application Behavior Section
                static let applicationBehaviorTitle = "Application Behavior"
                static let accessoryModeLabel = "Hide from Dock"
                static let accessoryModeDescription = "Show only in menu bar"
            }
            
            struct Cookies {
                static let pageTitle = "Privacy"
                static let pageDescription = "Control cookies and website data"
                static let searchPlaceholder = "Search domains..."
                static let refreshAction = "Refresh Cookies"
                static let clearAllAction = "Clear All Cookies"
                static let clearDomainAction = "Clear Domain Cookies"
                static let noCookiesTitle = "No cookies found"
                static let adjustSearchSuggestion = "Try adjusting your search terms"
                static let selectDomainTitle = "Select a domain to view cookies"
                static let selectDomainMessage = "Choose a domain from the sidebar to examine its stored cookies and metadata"
                static let noDomainCookiesTitle = "No cookies for this domain"
                static let copyNameAction = "Copy Name"
                static let copyValueAction = "Copy Value"
                static let clearCookiesAction = "Clear Cookies"
                static let sessionCookieLabel = "Session cookie"
                static let cookieValueLabel = "Value"
                static let cookieDomainLabel = "Domain"
                static let cookiePathLabel = "Path"
                static let cookieExpiresLabel = "Expires"
            }
            
            struct Downloads {
                static let pageTitle = "Downloads"
                static let pageDescription = "View and organize downloaded files"
                static let searchPlaceholder = "Search downloads"
                static let clearAllAction = "Clear All"
                static let noDownloadsTitle = "No Download History"
                static let noDownloadsMessage = "Downloaded files will appear here for convenient access and management."
                static let noMatchingDownloadsTitle = "No Matching Downloads"
                static let adjustSearchMessage = "Try adjusting your search terms."
                static let openFileAction = "Open"
                static let showInFinderAction = "Show in Finder"
                static let removeFromHistoryAction = "Remove from History"
            }
            
            struct History {
                static let pageTitle = "History"
                static let pageDescription = "Manage your browsing history"
                static let historyCollectionLabel = "Collect Browsing History"
                static let historyCollectionDescription = "When disabled, visited pages are not saved to history and existing history is automatically cleared for enhanced privacy."
                static let searchPlaceholder = "Search history..."
                static let deleteSelectedAction = "Delete Selected"
                static let clearSelectionAction = "Clear Selection"
                static let clearAllHistoryAction = "Clear All History"
                static let noHistoryTitle = "No browsing history found"
                static let adjustSearchHistoryMessage = "Try adjusting your search terms or time range"
                static let copyUrlAction = "Copy URL"
                static let deleteItemAction = "Delete"
                static let itemsCountSingular = "item"
                static let itemsCountPlural = "items"
                static let visitsCountSuffix = "visits"
                
                // Time Range Options
                static let timeRangeToday = "Today"
                static let timeRangeYesterday = "Yesterday"
                static let timeRangeThisWeek = "This Week"
                static let timeRangeThisMonth = "This Month"
                static let timeRangeAll = "All Time"
                
                // Sort Options
                static let sortNewest = "Newest First"
                static let sortOldest = "Oldest First"
                static let sortAlphabetical = "A-Z"
                static let sortMostVisited = "Most Visited"
            }
        }
        
        
        /**
         * Dialog content emphasizing clear consequences and providing appropriate warnings.
         * 
         * SAFETY APPROACH: All destructive operations include clear explanations
         * of consequences and permanence to prevent accidental data loss.
         */
        struct Dialogs {
            struct Confirmations {
                // Cookie Management Confirmations
                static let clearAllCookiesTitle = "Clear All Cookies"
                static let clearAllCookiesMessage = "This action will permanently remove all cookies from all domains. This operation cannot be undone."
                static let clearDomainCookiesTitle = "Clear Domain Cookies"
                static func clearDomainCookiesMessage(domain: String) -> String {
                    return "This action will permanently remove all cookies for \(domain). This operation cannot be undone."
                }
                
                // Download History Confirmations
                static let clearDownloadHistoryTitle = "Clear Download History"
                static let clearDownloadHistoryMessage = "This action will permanently remove all download history records. This operation cannot be undone."
                
                // Browsing History Confirmations
                static let clearBrowsingHistoryTitle = "Clear All History"
                static let clearBrowsingHistoryMessage = "This action will permanently delete all browsing history. This operation cannot be undone."
                
                // Common Actions
                static let cancelAction = "Cancel"
                static let clearAllAction = "Clear All"
                static let clearAction = "Clear"
                static let deleteAction = "Delete"
            }
            
            struct StatusMessages {
                static let operationCompleted = "Operation completed successfully"
                static let operationFailed = "Operation failed. Please try again."
            }
        }
        
        
        /**
         * Frequently used UI element labels for consistency across the application.
         * 
         * STANDARDIZATION: Common actions and labels follow consistent patterns
         * to reduce cognitive load and provide predictable user experience.
         */
        struct CommonElements {
            // Action Labels
            static let refresh = "Refresh"
            static let clearAll = "Clear All"
            static let clearSelected = "Clear Selected"
            static let cancel = "Cancel"
            static let delete = "Delete"
            static let open = "Open"
            static let close = "Close"
            static let save = "Save"
            static let copy = "Copy"
            static let paste = "Paste"
            static let search = "Search"
            static let filter = "Filter"
            static let sort = "Sort"
            
            // Sort Options (Generic)
            static let sortAlphabetical = "A-Z"
            static let sortMostRecent = "Most Recent"
            static let sortOldest = "Oldest"
            static let sortMostUsed = "Most Used"
            
            // Common Labels
            static let name = "Name"
            static let size = "Size"
            static let date = "Date"
            static let type = "Type"
            static let status = "Status"
            static let actions = "Actions"
            
            // Count Labels
            static func itemCount(_ count: Int) -> String {
                return "\(count) \(count == 1 ? "item" : "items")"
            }
            
            static func cookieCount(_ count: Int) -> String {
                return "\(count) \(count == 1 ? "cookie" : "cookies")"
            }
        }
        
        

        
        
        /**
         * Download-related status messages and file operation labels.
         * 
         * STATUS CLARITY: Provides clear, immediate understanding of download
         * states and available file operations for user decision-making.
         */
        struct FileOperations {
            // Download States
            static let downloadCompleted = "Completed"
            static let downloadInProgress = "Downloading"
            static let downloadPaused = "Paused" 
            static let downloadFailed = "Failed"
            static let downloadCancelled = "Cancelled"
            
            // File Actions
            static let openFile = "Open"
            static let openInFinder = "Show in Finder"
            static let copyPath = "Copy Path"
            static let deleteFile = "Delete File"
            static let removeFromHistory = "Remove from History"
            
            // File Size Formatting
            static let bytesUnit = "bytes"
            static let kilobytesUnit = "KB"
            static let megabytesUnit = "MB"
            static let gigabytesUnit = "GB"
        }
        
        
        /**
         * Empty state content providing clear guidance and encouraging user action.
         * 
         * GUIDANCE STRATEGY: Empty states explain current state while suggesting
         * productive next steps to help users understand feature capabilities.
         */
        struct EmptyStates {
            struct Downloads {
                static let title = "No Download History"
                static let message = "Downloaded files will appear here for convenient access and management."
                static let searchEmptyTitle = "No Matching Downloads"
                static let searchEmptyMessage = "Try adjusting your search terms."
            }
            
            struct History {
                static let title = "No browsing history found"
                static let message = "Visited pages will appear here when history collection is enabled."
                static let searchEmptyMessage = "Try adjusting your search terms or time range"
            }
            
            struct Cookies {
                static let title = "No cookies found"
                static let message = "Website cookies will appear here as you browse."
                static let searchEmptyMessage = "Try adjusting your search terms"
                static let domainEmptyTitle = "No cookies for this domain"
                static let domainEmptyMessage = "This domain has not stored any cookies."
            }
        }
    }
}
