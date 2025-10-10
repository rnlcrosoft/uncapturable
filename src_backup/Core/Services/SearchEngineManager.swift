import Foundation

/**
 * SearchEngineManager - Google-only Search Engine Management
 *
 * Fixed to Google only - no custom search engines or selection.
 * Always returns Google search URLs for privacy and simplicity.
 */
class SearchEngineManager {
    static let shared = SearchEngineManager()

    /**
     * Generates a Google search URL for the given query.
     */
    func searchURL(for query: String) -> String {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return "https://www.google.com/search?q=" + encodedQuery
    }
}
