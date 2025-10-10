import Foundation

/// Browser data models for history, cookies, and cache storage.

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

/**
 * Web Storage data model representing localStorage and IndexedDB entries.
 * 
 * STORAGE TYPES:
 * - localStorage: Simple key-value storage with string values
 * - indexedDB: Structured database storage for complex data
 * 
 * USAGE PATTERN:
 * - Grouped by domain for user-friendly organization
 * - Type information helps users understand data persistence
 */
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

/**
 * Cache data model representing browser cache information.
 * 
 * CACHE TYPES:
 * - Memory cache: Temporary storage in RAM
 * - Disk cache: Persistent storage on disk
 * 
 * USAGE PATTERN:
 * - Aggregated size information for user display
 * - Last cleared date for context
 */
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
