import Foundation
import AppKit

/// System window metadata for screenshot capture and display.

struct WindowInfo: Identifiable, Sendable {
    let id: CGWindowID
    let title: String
    let ownerName: String
    let bounds: CGRect
    let isOnScreen: Bool
    let windowLayer: Int
    nonisolated(unsafe) var thumbnailImage: NSImage?
    
    init?(from windowDict: [String: Any]) {
        guard let windowID = windowDict[kCGWindowNumber as String] as? CGWindowID,
              let ownerName = windowDict[kCGWindowOwnerName as String] as? String,
              let boundsDict = windowDict[kCGWindowBounds as String] as? [String: Any] else {
            return nil
        }
        
        self.id = windowID
        self.ownerName = ownerName
        self.title = (windowDict[kCGWindowName as String] as? String) ?? ownerName
        self.isOnScreen = (windowDict[kCGWindowIsOnscreen as String] as? Bool) ?? false
        self.windowLayer = (windowDict[kCGWindowLayer as String] as? Int) ?? 0
        
        // Parse bounds
        let xPosition = boundsDict["X"] as? CGFloat ?? 0
        let yPosition = boundsDict["Y"] as? CGFloat ?? 0
        let width = boundsDict["Width"] as? CGFloat ?? 0
        let height = boundsDict["Height"] as? CGFloat ?? 0
        self.bounds = CGRect(x: xPosition, y: yPosition, width: width, height: height)
    }
    
    var isValidForScreenshot: Bool {
        return isOnScreen && 
               bounds.width > 50 && 
               bounds.height > 50 && 
               windowLayer == 0 && 
               !title.isEmpty &&
               ownerName != "Window Server"
    }
    
    var displayName: String {
        if title == ownerName || title.isEmpty {
            return ownerName
        }
        return "\(title) - \(ownerName)"
    }
}
