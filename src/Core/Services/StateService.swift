import Foundation
import SwiftUI
import WebKit

/// Centralized browser state management for tabs, history, and cache.
@Observable
class StateService {
    static let shared = StateService()
    
    
    /// All currently open browser tabs in display order
    private(set) var tabs: [Tab] = []
    
    /// Zero-based index of the currently active tab
    private(set) var currentTabIndex: Int = 0
    
    /// The currently active tab, or nil if no tabs are open
    var currentTab: Tab? {
        guard !tabs.isEmpty && currentTabIndex < tabs.count else { return nil }
        return tabs[currentTabIndex]
    }
    
    
    /// Chronologically ordered browsing history (newest first)
    private(set) var historyItems: [HistoryItem] = []
    
    
    /// Cookies organized by domain for efficient access and management
    private(set) var cookiesByDomain: [String: [CookieItem]] = [:]
    
    
    /// Web Storage (localStorage and IndexedDB) organized by domain
    private(set) var webStorageByDomain: [WebStorageItem] = []
    
    
    /// Browser cache information
    private(set) var cacheInfo = CacheInfo()
    
    
    /// Domain-to-base64-image mapping for efficient favicon retrieval
    /// Stored as base64 strings to enable UserDefaults persistence
    private var faviconCacheByDomain: [String: String] = [:]
    
    
    /// Maximum number of history items to keep in memory and persistence
    private let maximumHistoryItems = 500
    
    /// Maximum number of favicon entries to cache
    private let maximumFaviconCacheSize = 200
    
    /// Batch size for history pagination
    private let historyBatchSize = 50
    
    
    private let userDefaults = UserDefaults.standard
    private let browserHistoryPersistenceKey = "browserHistory"
    private let faviconCachePersistenceKey = "faviconCache"
    
    /// Queue for background persistence operations
    private let persistenceQueue = DispatchQueue(label: "xyz.lazysoft.persistence", qos: .utility)
    
    /**
     * Private initializer enforces singleton pattern and clears private data.
     */
    private init() {
        // Clear private data on app startup
        clearPrivateDataOnStartup()
    }
    
    
    @discardableResult
    func createTab(with url: URL? = nil) -> Tab {
        let newTab = Tab(url: url)
        tabs.append(newTab)
        currentTabIndex = tabs.count - 1
        return newTab
    }
    
    @discardableResult
    func createSettingsTab(type: ApplicationSettingsCategory) -> Tab {
        // Only prevent duplicates for browser settings (search engine config)
        // Allow multiple window settings tabs for different configurations
        if type == .browserSettings {
            if let existingIndex = tabs.firstIndex(where: {
                if case .settings(let settingsType) = $0.tabType {
                    return settingsType == type
                }
                return false
            }) {
                // Switch to existing tab instead of creating duplicate
                currentTabIndex = existingIndex
                return tabs[existingIndex]
            }
        }

        let newTab = Tab(settingsType: type)
        tabs.append(newTab)
        currentTabIndex = tabs.count - 1
        return newTab
    }
    
    func selectTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        currentTabIndex = index
    }
    
    func selectTab(withId id: UUID) {
        if let index = tabs.firstIndex(where: { $0.id == id }) {
            selectTab(at: index)
        }
    }
    
    func nextTab() {
        if !tabs.isEmpty {
            currentTabIndex = (currentTabIndex + 1) % tabs.count
        }
    }
    
    func previousTab() {
        if !tabs.isEmpty {
            currentTabIndex = currentTabIndex > 0 ? currentTabIndex - 1 : tabs.count - 1
        }
    }
    
    func closeTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        
        let tabToClose = tabs[index]
        tabToClose.cleanup()
        tabs.remove(at: index)
        
        if !tabs.isEmpty {
            if currentTabIndex >= tabs.count {
                currentTabIndex = tabs.count - 1
            } else if index <= currentTabIndex && currentTabIndex > 0 {
                currentTabIndex -= 1
            }
        } else {
            currentTabIndex = 0
        }
    }
    
    func closeTab(withId id: UUID) {
        if let index = tabs.firstIndex(where: { $0.id == id }) {
            closeTab(at: index)
        }
    }
    
    func closeCurrentTab() {
        closeTab(at: currentTabIndex)
    }
    
    func moveTab(from source: IndexSet, to destination: Int) {
        tabs.move(fromOffsets: source, toOffset: destination)
        if let sourceIndex = source.first {
            if sourceIndex == currentTabIndex {
                if destination > sourceIndex {
                    currentTabIndex = destination - 1
                } else {
                    currentTabIndex = destination
                }
            } else if sourceIndex < currentTabIndex && destination > currentTabIndex {
                currentTabIndex -= 1
            } else if sourceIndex > currentTabIndex && destination <= currentTabIndex {
                currentTabIndex += 1
            }
        }
    }
    
    func updateTab(_ updatedTab: Tab) {
        if let index = tabs.firstIndex(where: { $0.id == updatedTab.id }) {
            tabs[index] = updatedTab
        }
    }
    
    func replaceCurrentTab(with newTab: Tab) {
        guard !tabs.isEmpty && currentTabIndex < tabs.count else { return }
        
        // Clean up the old tab
        tabs[currentTabIndex].cleanup()
        
        // Replace with new tab
        tabs[currentTabIndex] = newTab
    }
    
    func ensureWindowSettingsTab() {
        if tabs.isEmpty {
            let windowSettingsTab = Tab(settingsType: .windowSettings)
            tabs.append(windowSettingsTab)
            currentTabIndex = 0
        }
    }
    
    func isWebContentActive(for tab: Tab?) -> Bool {
        guard let tab = tab else { return false }
        if case .web = tab.tabType {
            return true
        }
        return false
    }
    
    func createURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return nil
        }
        
        // Try parsing as a complete URL first
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        
        // Try parsing as a domain (add https prefix)
        if trimmed.contains(".") && !trimmed.contains(" ") {
            if let url = URL(string: "https://\(trimmed)") {
                return url
            }
        }
        
        // Treat as search query - always use Google search
        let encodedQuery = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        let searchURL = "https://www.google.com/search?q=" + encodedQuery
        return URL(string: searchURL)
    }
    
    
    func addHistoryItem(title: String, url: URL, faviconData: String? = nil) {
        // Skip adding history if collection is disabled
        guard AppSettings.shared.isHistoryCollectionEnabled else { return }
        
        let domain = Self.domain(from: url)
        let favicon = faviconData ?? getFaviconData(for: domain)
        
        // Check if item already exists
        if let existingIndex = historyItems.firstIndex(where: { $0.url == url }) {
            let existingItem = historyItems[existingIndex]
            historyItems.remove(at: existingIndex)
            let updatedItem = HistoryItem(title: title, url: url, visitDate: Date(), visitCount: existingItem.visitCount + 1, faviconData: favicon)
            historyItems.insert(updatedItem, at: 0)
        } else {
            let historyItem = HistoryItem(title: title, url: url, visitDate: Date(), faviconData: favicon)
            historyItems.insert(historyItem, at: 0)
        }
        
        // Limit history to configured maximum
        if historyItems.count > maximumHistoryItems {
            historyItems = Array(historyItems.prefix(maximumHistoryItems))
        }
        
        saveHistoryAsync()
    }
    
    func searchHistory(query: String) -> [HistoryItem] {
        guard !query.isEmpty else { return historyItems }
        
        let lowercaseQuery = query.lowercased()
        return historyItems.filter { item in
            item.title.lowercased().contains(lowercaseQuery) ||
            item.url.absoluteString.lowercased().contains(lowercaseQuery)
        }
    }
    
    func clearHistory() {
        historyItems.removeAll()
        saveHistory()
    }
    
    func removeHistoryItem(withId id: UUID) {
        historyItems.removeAll { $0.id == id }
        saveHistory()
    }
    
    
    @MainActor
    func loadCookies() async {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        
        let cookies = await withCheckedContinuation { continuation in
            cookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
        
        var groupedCookies: [String: [CookieItem]] = [:]
        
        for cookie in cookies {
            let cookieItem = CookieItem(
                name: cookie.name,
                value: cookie.value,
                domain: cookie.domain,
                path: cookie.path,
                expiresDate: cookie.expiresDate
            )
            
            if groupedCookies[cookie.domain] == nil {
                groupedCookies[cookie.domain] = []
            }
            groupedCookies[cookie.domain]?.append(cookieItem)
        }
        
        self.cookiesByDomain = groupedCookies
    }
    
    @MainActor
    func clearAllCookies() async {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        
        let cookies = await withCheckedContinuation { continuation in
            cookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
        
        for cookie in cookies {
            await withCheckedContinuation { continuation in
                cookieStore.delete(cookie) {
                    continuation.resume()
                }
            }
        }
        
        self.cookiesByDomain.removeAll()
    }
    
    @MainActor
    func clearCookiesForDomain(_ domain: String) async {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        
        let cookies = await withCheckedContinuation { continuation in
            cookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
        
        let domainCookies = cookies.filter { $0.domain == domain }
        
        for cookie in domainCookies {
            await withCheckedContinuation { continuation in
                cookieStore.delete(cookie) {
                    continuation.resume()
                }
            }
        }
        
        self.cookiesByDomain.removeValue(forKey: domain)
    }
    
    func getAllDomains() -> [String] {
        return Array(cookiesByDomain.keys).sorted()
    }
    
    func getCookies(for domain: String) -> [CookieItem] {
        return cookiesByDomain[domain] ?? []
    }
    
    func refreshCookies() {
        Task { @MainActor in
            await loadCookies()
        }
    }
    
    func deleteAllCookies() {
        Task { @MainActor in
            await clearAllCookies()
        }
    }
    
    func deleteCookies(for domain: String) {
        Task { @MainActor in
            await clearCookiesForDomain(domain)
        }
    }
    
    
    @MainActor
    func loadWebStorage() async {
        let dataStore = WKWebsiteDataStore.default()
        let webStorageTypes = [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeIndexedDBDatabases]
        
        let records = await dataStore.dataRecords(ofTypes: Set(webStorageTypes))
        
        var storageItems: [WebStorageItem] = []
        
        for record in records {
            let domain = record.displayName
            let hasLocalStorage = record.dataTypes.contains(WKWebsiteDataTypeLocalStorage)
            let hasIndexedDB = record.dataTypes.contains(WKWebsiteDataTypeIndexedDBDatabases)
            
            if hasLocalStorage || hasIndexedDB {
                let item = WebStorageItem(
                    domain: domain,
                    hasLocalStorage: hasLocalStorage,
                    hasIndexedDB: hasIndexedDB,
                    lastModified: Date(),
                    estimatedSize: 0 // Size estimation would require additional processing
                )
                storageItems.append(item)
            }
        }
        
        self.webStorageByDomain = storageItems
    }
    
    @MainActor
    func clearAllWebStorage() async {
        let dataStore = WKWebsiteDataStore.default()
        let webStorageTypes = [WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeIndexedDBDatabases]
        
        await dataStore.removeData(ofTypes: Set(webStorageTypes), modifiedSince: Date(timeIntervalSince1970: 0))
        
        self.webStorageByDomain.removeAll()
    }
    
    @MainActor
    func clearWebStorageForDomain(_ domain: String) async {
        let dataStore = WKWebsiteDataStore.default()
        let webStorageTypes = [WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeIndexedDBDatabases]
        
        let records = await dataStore.dataRecords(ofTypes: Set(webStorageTypes))
        let matchingRecords = records.filter { $0.displayName == domain }
        
        for record in matchingRecords {
            await dataStore.removeData(ofTypes: record.dataTypes, for: [record])
        }
        
        self.webStorageByDomain.removeAll { $0.domain == domain }
    }
    
    func refreshWebStorage() {
        Task { @MainActor in
            await loadWebStorage()
        }
    }
    
    func deleteAllWebStorage() {
        Task { @MainActor in
            await clearAllWebStorage()
        }
    }
    
    func deleteWebStorage(for domain: String) {
        Task { @MainActor in
            await clearWebStorageForDomain(domain)
        }
    }
    
    
    @MainActor
    func loadCacheInfo() async {
        let dataStore = WKWebsiteDataStore.default()
        let cacheTypes = [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]
        
        let records = await dataStore.dataRecords(ofTypes: Set(cacheTypes))
        
        // Calculate total cache size (this is an approximation as WKWebsiteDataRecord doesn't provide size info)
        var diskCacheSize: Int64 = 0
        var memoryCacheSize: Int64 = 0
        
        // In a real implementation, we would need to use additional APIs to get accurate cache size
        // For now, we'll use a placeholder value based on the number of cache records
        diskCacheSize = Int64(records.filter { $0.dataTypes.contains(WKWebsiteDataTypeDiskCache) }.count * 1024 * 1024) // Rough estimate
        memoryCacheSize = Int64(records.filter { $0.dataTypes.contains(WKWebsiteDataTypeMemoryCache) }.count * 512 * 1024) // Rough estimate
        
        self.cacheInfo = CacheInfo(
            diskCacheSize: diskCacheSize,
            memoryCacheSize: memoryCacheSize,
            lastCleared: UserDefaults.standard.object(forKey: "lastCacheClearDate") as? Date
        )
    }
    
    @MainActor
    func clearAllCache() async {
        let dataStore = WKWebsiteDataStore.default()
        let cacheTypes = [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]
        
        await dataStore.removeData(ofTypes: Set(cacheTypes), modifiedSince: Date(timeIntervalSince1970: 0))
        
        // Update cache info
        self.cacheInfo = CacheInfo(
            diskCacheSize: 0,
            memoryCacheSize: 0,
            lastCleared: Date()
        )
        
        // Save last cleared date
        UserDefaults.standard.set(Date(), forKey: "lastCacheClearDate")
    }
    
    func refreshCacheInfo() {
        Task { @MainActor in
            await loadCacheInfo()
        }
    }
    
    func clearCache() {
        Task { @MainActor in
            await clearAllCache()
        }
    }
    
    
    func getFavicon(for domain: String) -> NSImage? {
        guard let base64String = faviconCacheByDomain[domain],
              let data = Data(base64Encoded: base64String) else {
            return nil
        }
        return NSImage(data: data)
    }
    
    func setFavicon(_ image: NSImage, for domain: String) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return
        }
        
        let base64String = pngData.base64EncodedString()
        faviconCacheByDomain[domain] = base64String
        persistFaviconCache()
    }
    
    func setFaviconData(_ data: Data, for domain: String) {
        guard let image = NSImage(data: data) else { return }
        setFavicon(image, for: domain)
    }
    
    func getFaviconData(for domain: String) -> String? {
        return faviconCacheByDomain[domain]
    }
    
    func setFaviconBase64(_ base64String: String, for domain: String) {
        faviconCacheByDomain[domain] = base64String
        
        // Enforce cache size limit using LRU eviction
        if faviconCacheByDomain.count > maximumFaviconCacheSize {
            evictOldestFaviconEntries()
        }
        
        persistFaviconCache()
    }
    
    func clearFaviconCache() {
        faviconCacheByDomain.removeAll()
        persistFaviconCache()
    }
    
    func removeFavicon(for domain: String) {
        faviconCacheByDomain.removeValue(forKey: domain)
        persistFaviconCache()
    }
    
    /**
     * Evict oldest favicon entries when cache exceeds maximum size.
     * 
     * EVICTION STRATEGY: Simple approach removes 25% of entries when limit exceeded.
     * More sophisticated LRU tracking could be added in future for better cache efficiency.
     */
    private func evictOldestFaviconEntries() {
        let targetCount = Int(Double(maximumFaviconCacheSize) * 0.75) // Remove 25% of entries
        let excessCount = faviconCacheByDomain.count - targetCount
        
        if excessCount > 0 {
            // Simple eviction: remove entries until under target count
            let domains = Array(faviconCacheByDomain.keys).prefix(excessCount)
            for domain in domains {
                faviconCacheByDomain.removeValue(forKey: domain)
            }
        }
    }
    
    
    /**
     * Clear private data on app startup and shutdown.
     */
    private func clearPrivateDataOnStartup() {
        Task { @MainActor in
            // Clear cookies
            await clearAllCookies()

            // Clear web storage
            await clearAllWebStorage()

            // Clear cache
            await clearAllCache()

            // Clear favicon cache
            clearFaviconCache()
        }
    }

    /**
     * Clear private data when the app is about to terminate.
     */
    func clearPrivateDataOnShutdown() {
        clearPrivateDataOnStartup()
    }

    static func domain(from url: URL) -> String {
        return url.host ?? url.absoluteString
    }
    
    
    /**
     * Load browsing history from UserDefaults persistence.
     * 
     * FAILURE HANDLING: If deserialization fails (corrupted data, version mismatch),
     * silently start with empty history to prevent app crashes. Users can rebuild
     * history through normal browsing.
     */
    private func loadPersistedBrowsingHistory() {
        guard let data = userDefaults.data(forKey: browserHistoryPersistenceKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let savedItems = try decoder.decode([SavedHistoryItem].self, from: data)
            
            historyItems = savedItems.compactMap { savedItem in
                guard let url = URL(string: savedItem.urlString) else { return nil }
                return HistoryItem(
                    title: savedItem.title,
                    url: url,
                    visitDate: savedItem.visitDate,
                    visitCount: savedItem.visitCount,
                    faviconData: savedItem.faviconData
                )
            }
        } catch {
            // Failed to load history - start with empty array
            // This prevents crashes from corrupted or incompatible data formats
        }
    }
    
    /**
     * Persist current browsing history to UserDefaults.
     * 
     * PERSISTENCE STRATEGY: Uses JSON encoding for human-readable storage
     * and easy debugging. ISO8601 date encoding ensures timezone independence.
     */
    private func saveHistory() {
        let savedItems = historyItems.map { item in
            SavedHistoryItem(
                title: item.title,
                urlString: item.url.absoluteString,
                visitDate: item.visitDate,
                visitCount: item.visitCount,
                faviconData: item.faviconData
            )
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(savedItems)
            userDefaults.set(data, forKey: browserHistoryPersistenceKey)
        } catch {
            // Failed to save history - will retry on next save
            // Encoding failures are rare but can occur with extremely large datasets
        }
    }
    
    /**
     * Asynchronously persist browsing history to avoid blocking main thread during navigation.
     * 
     * PERFORMANCE OPTIMIZATION: Moves encoding and UserDefaults operations to background
     * queue to prevent UI stuttering during rapid navigation or history updates.
     */
    private func saveHistoryAsync() {
        let currentItems = historyItems // Capture current state
        
        persistenceQueue.async { [weak self] in
            guard let self = self else { return }
            
            let savedItems = currentItems.map { item in
                SavedHistoryItem(
                    title: item.title,
                    urlString: item.url.absoluteString,
                    visitDate: item.visitDate,
                    visitCount: item.visitCount,
                    faviconData: item.faviconData
                )
            }
            
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(savedItems)
                self.userDefaults.set(data, forKey: self.browserHistoryPersistenceKey)
            } catch {
                // Failed to save history - will retry on next save
                // Encoding failures are rare but can occur with extremely large datasets
            }
        }
    }
    
    /**
     * Load favicon cache from UserDefaults persistence.
     * 
     * CACHE WARMING: This method populates the in-memory cache with previously
     * stored favicons, providing immediate icon availability on app startup.
     */
    private func loadPersistedFaviconCache() {
        if let data = userDefaults.data(forKey: faviconCachePersistenceKey),
           let savedCache = try? JSONDecoder().decode([String: String].self, from: data) {
            faviconCacheByDomain = savedCache
        }
    }
    
    /**
     * Persist current favicon cache to UserDefaults.
     * 
     * ENCODING RATIONALE: Base64 encoding allows binary image data to be stored
     * as JSON-compatible strings in UserDefaults.
     */
    private func persistFaviconCache() {
        if let data = try? JSONEncoder().encode(faviconCacheByDomain) {
            userDefaults.set(data, forKey: faviconCachePersistenceKey)
        }
    }
}


private struct SavedHistoryItem: Codable {
    let title: String
    let urlString: String
    let visitDate: Date
    let visitCount: Int
    let faviconData: String?
}

// Data models for browser state management

struct HistoryItem: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
    let visitDate: Date
    let visitCount: Int
    let faviconData: String?

    init(title: String, url: URL, visitDate: Date, visitCount: Int = 1, faviconData: String? = nil) {
        self.title = title
        self.url = url
        self.visitDate = visitDate
        self.visitCount = visitCount
        self.faviconData = faviconData
    }
}

struct CookieItem: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let domain: String
    let path: String
    let expiresDate: Date?
}

struct WebStorageItem: Identifiable {
    let id = UUID()
    let domain: String
    let hasLocalStorage: Bool
    let hasIndexedDB: Bool
    let lastModified: Date
    let estimatedSize: Int64 // Size in bytes

    init(domain: String, hasLocalStorage: Bool, hasIndexedDB: Bool, lastModified: Date = Date(), estimatedSize: Int64 = 0) {
        self.domain = domain
        self.hasLocalStorage = hasLocalStorage
        self.hasIndexedDB = hasIndexedDB
        self.lastModified = lastModified
        self.estimatedSize = estimatedSize
    }
}

struct CacheInfo {
    let diskCacheSize: Int64 // Size in bytes
    let memoryCacheSize: Int64 // Size in bytes
    let lastCleared: Date?

    var totalCacheSize: Int64 {
        return diskCacheSize + memoryCacheSize
    }

    init(diskCacheSize: Int64 = 0, memoryCacheSize: Int64 = 0, lastCleared: Date? = nil) {
        self.diskCacheSize = diskCacheSize
        self.memoryCacheSize = memoryCacheSize
        self.lastCleared = lastCleared
    }
}
