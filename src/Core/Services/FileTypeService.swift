import Foundation
import UniformTypeIdentifiers

/// File type detection and classification service.

class FileTypeService {
    static let shared = FileTypeService()
    
    private init() {}
    
    
    /**
     * Determine Uniform Type Identifier for a file URL.
     * 
     * DETECTION STRATEGY: Prefers system UTType detection for maximum accuracy,
     * falls back to our comprehensive extension mapping for broader format support.
     */
    func determineUniformTypeIdentifier(for url: URL) -> String {
        let fileExtension = url.pathExtension.lowercased()
        
        // First try system UTType detection for maximum accuracy
        if let systemUTI = UTType(filenameExtension: fileExtension) {
            return systemUTI.identifier
        }
        
        // Fall back to our extension mapping for broader coverage
        return AppConstants.FileTypeIdentification.extensionToUTIMapping[fileExtension] 
            ?? AppConstants.FileTypeIdentification.fallbackUTI
    }
    
    /**
     * Determine MIME type for a file URL.
     * 
     * MIME TYPE ACCURACY: Uses system UTType when available, falls back to 
     * our IANA-compliant mapping for consistent web compatibility.
     */
    func determineMIMEType(for url: URL) -> String {
        let fileExtension = url.pathExtension.lowercased()
        let uti = determineUniformTypeIdentifier(for: url)
        
        // Try system MIME type detection first
        if let systemUTType = UTType(uti),
           let systemMIMEType = systemUTType.preferredMIMEType {
            return systemMIMEType
        }
        
        // Fall back to our extension mapping
        return AppConstants.FileTypeIdentification.extensionToMIMETypeMapping[fileExtension]
            ?? AppConstants.FileTypeIdentification.fallbackMIMEType
    }
    
    /**
     * Determine MIME type from file extension directly.
     * 
     * PERFORMANCE OPTIMIZED: For cases where we only have the extension
     * and don't need to construct a full URL.
     */
    func determineMIMEType(for fileExtension: String) -> String {
        let ext = fileExtension.lowercased()
        
        // Try system detection first
        if let systemUTI = UTType(filenameExtension: ext),
           let systemMIMEType = systemUTI.preferredMIMEType {
            return systemMIMEType
        }
        
        // Fall back to our mapping
        return AppConstants.FileTypeIdentification.extensionToMIMETypeMapping[ext]
            ?? AppConstants.FileTypeIdentification.fallbackMIMEType
    }
    
    
    /**
     * Check if a file is an image that can be displayed inline in the browser.
     * 
     * BROWSER COMPATIBILITY: Uses system UTType conformance for accurate detection
     * of image formats, including modern formats like WebP.
     */
    func isImage(_ url: URL) -> Bool {
        let uti = determineUniformTypeIdentifier(for: url)
        return UTType(uti)?.conforms(to: UTType.image) ?? false
    }
    
    /**
     * Check if a file is a document that should be opened with external applications.
     * 
     * DOCUMENT STRATEGY: Includes office documents, PDFs, and text files that
     * provide better user experience when opened in dedicated applications.
     */
    func isDocument(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        return AppConstants.FileTypeCategories.documentExtensions.contains(fileExtension)
    }
    
    /**
     * Check if a file is an archive that requires extraction software.
     * 
     * ARCHIVE DETECTION: Covers common compression formats that browsers
     * cannot display and should be downloaded for extraction.
     */
    func isArchive(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        return AppConstants.FileTypeCategories.archiveExtensions.contains(fileExtension)
    }
    
    /**
     * Check if a file is media content (audio or video).
     * 
     * MEDIA STRATEGY: Uses both system UTType detection and our category mapping
     * to identify content that requires media player applications.
     */
    func isMedia(_ url: URL) -> Bool {
        let uti = determineUniformTypeIdentifier(for: url)
        guard let utType = UTType(uti) else {
            // Fallback to extension-based detection
            let fileExtension = url.pathExtension.lowercased()
            return AppConstants.FileTypeCategories.mediaExtensions.contains(fileExtension)
        }
        
        return utType.conforms(to: UTType.audiovisualContent) || 
               utType.conforms(to: UTType.audio) || 
               utType.conforms(to: UTType.movie)
    }
    
    /**
     * Check if a file is audio content specifically.
     */
    func isAudio(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        return AppConstants.FileTypeCategories.audioExtensions.contains(fileExtension)
    }
    
    /**
     * Check if a file is video content specifically.
     */
    func isVideo(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        return AppConstants.FileTypeCategories.videoExtensions.contains(fileExtension)
    }
    
    /**
     * Check if a file is web content that should be displayed in the browser.
     */
    func isWebContent(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        return AppConstants.FileTypeCategories.webExtensions.contains(fileExtension)
    }
    
    /**
     * Check if a file is software/executable content.
     */
    func isSoftware(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        return AppConstants.FileTypeCategories.softwareExtensions.contains(fileExtension)
    }
    
    
    /**
     * Get appropriate SF Symbol icon name for a file.
     * 
     * ICON STRATEGY: Provides consistent visual file type identification
     * across the application with appropriate fallback for unknown types.
     */
    func iconForFile(_ filename: String) -> String {
        let fileExtension = (filename as NSString).pathExtension.lowercased()
        return AppConstants.FileTypeIcons.extensionToIconMapping[fileExtension] 
            ?? AppConstants.FileTypeIcons.defaultIcon
    }
    
    /**
     * Get appropriate SF Symbol icon name for a file URL.
     */
    func iconForFile(_ url: URL) -> String {
        return iconForFile(url.lastPathComponent)
    }
    
    
    /**
     * Determine if a file should be downloaded based on its MIME type.
     * 
     * DOWNLOAD STRATEGY: Balances user expectations with security considerations.
     * Generally downloads binary/executable content while allowing browser display
     * of web-native formats.
     */
    func shouldDownloadForMimeType(_ mimeType: String) -> Bool {
        return AppConstants.DownloadBehavior.downloadableMimeTypes.contains(mimeType.lowercased())
    }
    
    /**
     * Determine if a file should be downloaded based on its file extension.
     * 
     * EXTENSION FALLBACK: Used when MIME type is unavailable or unreliable,
     * common with misconfigured servers or local file access.
     */
    func shouldDownloadForFileExtension(_ fileExtension: String) -> Bool {
        return AppConstants.DownloadBehavior.downloadableExtensions.contains(fileExtension.lowercased())
    }
    
    /**
     * Determine if a file should be downloaded based on URL.
     * 
     * COMPREHENSIVE CHECK: Examines file extension to make download decision
     * when MIME type information is not available.
     */
    func shouldDownload(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        return shouldDownloadForFileExtension(fileExtension)
    }
    
    /**
     * Determine if a response should trigger download based on both MIME type and URL.
     * 
     * RESPONSE ANALYSIS: Uses both MIME type and file extension for most accurate
     * download decision, handling cases where server headers may be incorrect.
     */
    func shouldDownload(mimeType: String?, for url: URL) -> Bool {
        // Check MIME type first if available
        if let mimeType = mimeType, shouldDownloadForMimeType(mimeType) {
            return true
        }
        
        // Fall back to file extension
        return shouldDownload(url)
    }
    
    
    /**
     * Get a human-readable description of the file type.
     * 
     * USER COMMUNICATION: Provides friendly descriptions for file types
     * in user-facing contexts like tooltips or error messages.
     */
    func fileTypeDescription(for url: URL) -> String {
        let fileExtension = url.pathExtension.lowercased()
        
        if isImage(url) {
            return "Image"
        } else if isDocument(url) {
            return "Document"
        } else if isArchive(url) {
            return "Archive"
        } else if isAudio(url) {
            return "Audio"
        } else if isVideo(url) {
            return "Video"
        } else if isWebContent(url) {
            return "Web Content"
        } else if isSoftware(url) {
            return "Software"
        } else if !fileExtension.isEmpty {
            return "\(fileExtension.uppercased()) File"
        } else {
            return "File"
        }
    }
    
    /**
     * Get file category as an enumeration for programmatic use.
     */
    func fileCategory(for url: URL) -> FileCategory {
        if isImage(url) {
            return .image
        } else if isDocument(url) {
            return .document
        } else if isArchive(url) {
            return .archive
        } else if isAudio(url) {
            return .audio
        } else if isVideo(url) {
            return .video
        } else if isWebContent(url) {
            return .webContent
        } else if isSoftware(url) {
            return .software
        } else {
            return .other
        }
    }
}


/**
 * Enumeration of file categories for type-safe programmatic use.
 * 
 * CATEGORY DESIGN: Provides structured access to file classifications
 * for features that need to handle different file types differently.
 */
enum FileCategory: CaseIterable {
    case image
    case document
    case archive
    case audio
    case video
    case webContent
    case software
    case other
    
    var displayName: String {
        switch self {
        case .image: return "Image"
        case .document: return "Document"
        case .archive: return "Archive"
        case .audio: return "Audio"
        case .video: return "Video"
        case .webContent: return "Web Content"
        case .software: return "Software"
        case .other: return "Other"
        }
    }
}
