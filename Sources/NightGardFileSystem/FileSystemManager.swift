//
//  FileSystemManager.swift
//  DiamondNotesVault
//
//  Handles reading/writing markdown files and media to filesystem
//

import Foundation
import UIKit

@Observable
public class FileSystemManager {
    public static let shared = FileSystemManager()

    private init() {}

    // MARK: - File Operations

    /// Save note content to markdown file with media handling
    /// Images are saved to the notebook's media/ pocket folder
    public func saveNote(title: String, attributedContent: NSAttributedString, to fileURL: URL) throws {
        // Get notebook/binder directory (parent of note file)
        let notebookURL = fileURL.deletingLastPathComponent()
        // Each notebook has its own media/ pocket folder for images/videos
        let mediaURL = notebookURL.appendingPathComponent("media")

        // Ensure directories exist
        try FileManager.default.createDirectory(at: notebookURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: mediaURL, withIntermediateDirectories: true)

        // Extract and save images, get markdown with references
        let markdown = try convertToMarkdown(title: title, attributedContent: attributedContent, mediaURL: mediaURL)

        // Write markdown file
        try markdown.write(to: fileURL, atomically: true, encoding: .utf8)

        // Update table of contents
        try updateTableOfContents(notebookURL: notebookURL)
    }

    /// Save image to media folder preserving metadata and return relative path
    public func saveImage(_ image: UIImage, originalFilename: String? = nil, to mediaURL: URL) throws -> String {
        let filename: String
        let destURL: URL

        if let origName = originalFilename, !origName.isEmpty {
            // Use provided original filename
            var finalName = origName
            destURL = mediaURL.appendingPathComponent(finalName)

            // Check for conflicts and append number if needed
            if FileManager.default.fileExists(atPath: destURL.path) {
                let name = (origName as NSString).deletingPathExtension
                let ext = (origName as NSString).pathExtension
                var counter = 2
                var uniqueURL = destURL

                while FileManager.default.fileExists(atPath: uniqueURL.path) {
                    finalName = "\(name)-\(counter).\(ext)"
                    uniqueURL = mediaURL.appendingPathComponent(finalName)
                    counter += 1
                }
            }

            filename = finalName
        } else {
            // No original filename - generate timestamp name
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
            filename = "Photo-\(dateFormatter.string(from: Date())).jpg"
        }

        // Save as JPEG
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "FileSystemManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])
        }

        let finalURL = mediaURL.appendingPathComponent(filename)
        try data.write(to: finalURL)

        // Return relative path for markdown
        return "media/\(filename)"
    }

    /// Load note content from markdown file with image loading
    public func loadNote(from fileURL: URL) throws -> (title: String, attributedContent: NSAttributedString) {
        let markdown = try String(contentsOf: fileURL, encoding: .utf8)
        let notebookURL = fileURL.deletingLastPathComponent()

        // Extract title from first line if it's a heading
        let lines = markdown.components(separatedBy: .newlines)
        var title = ""
        var contentLines = lines

        if let firstLine = lines.first, firstLine.hasPrefix("# ") {
            title = String(firstLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            contentLines = Array(lines.dropFirst())
        } else {
            title = fileURL.deletingPathExtension().lastPathComponent
        }

        // Convert markdown to attributed string with images
        let attributedContent = try convertMarkdownToAttributedString(
            contentLines.joined(separator: "\n"),
            baseURL: notebookURL
        )

        return (title, attributedContent)
    }

    /// Load plain text file (for JSON, etc.)
    func loadPlainText(from fileURL: URL) throws -> String {
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    /// Save plain text file
    func savePlainText(_ text: String, to fileURL: URL) throws {
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Convert markdown text to attributed string, loading images from media folder
    private func convertMarkdownToAttributedString(_ markdown: String, baseURL: URL) throws -> NSAttributedString {
        let result = NSMutableAttributedString()
        let defaultFont = UIFont.preferredFont(forTextStyle: .body)
        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: defaultFont]

        // Split by image markers
        let imagePattern = "!\\[.*?\\]\\((.*?)\\)"
        let regex = try NSRegularExpression(pattern: imagePattern)
        let nsString = markdown as NSString
        let matches = regex.matches(in: markdown, range: NSRange(location: 0, length: nsString.length))

        var lastLocation = 0

        for match in matches {
            // Add text before image
            let textRange = NSRange(location: lastLocation, length: match.range.location - lastLocation)
            let text = nsString.substring(with: textRange)
            result.append(NSAttributedString(string: text, attributes: defaultAttributes))

            // Extract image path
            let pathRange = match.range(at: 1)
            let imagePath = nsString.substring(with: pathRange)
            let imageURL = baseURL.appendingPathComponent(imagePath)

            // Load and insert image
            if let imageData = try? Data(contentsOf: imageURL),
               let image = UIImage(data: imageData) {
                let attachment = NSTextAttachment()
                attachment.image = image

                // Scale to fit
                let maxWidth: CGFloat = 350
                if image.size.width > maxWidth {
                    let scale = maxWidth / image.size.width
                    attachment.bounds = CGRect(x: 0, y: 0, width: maxWidth, height: image.size.height * scale)
                } else {
                    attachment.bounds = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                }

                result.append(NSAttributedString(attachment: attachment))
                result.append(NSAttributedString(string: "\n", attributes: defaultAttributes))
            }

            lastLocation = match.range.location + match.range.length
        }

        // Add remaining text
        let remainingRange = NSRange(location: lastLocation, length: nsString.length - lastLocation)
        let remainingText = nsString.substring(with: remainingRange)
        result.append(NSAttributedString(string: remainingText, attributes: defaultAttributes))

        return result
    }

    /// Delete note file
    public func deleteNote(at fileURL: URL) throws {
        try FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Markdown Conversion

    private func convertToMarkdown(title: String, attributedContent: NSAttributedString, mediaURL: URL) throws -> String {
        var markdown = ""

        // Add title as H1
        if !title.isEmpty {
            markdown += "# \(title)\n\n"
        }

        // Process attributed string and extract images
        attributedContent.enumerateAttributes(in: NSRange(location: 0, length: attributedContent.length)) { attributes, range, _ in
            if let attachment = attributes[.attachment] as? NSTextAttachment,
               let image = attachment.image {
                // Save image to media folder with original filename if stored
                do {
                    let originalFilename = attachment.fileType // Stored from metadata
                    let imagePath = try saveImage(image, originalFilename: originalFilename, to: mediaURL)
                    markdown += "![](\(imagePath))\n\n"
                } catch {
                    print("Failed to save image: \(error)")
                }
            } else {
                // Regular text
                let text = attributedContent.attributedSubstring(from: range).string
                markdown += text
            }
        }

        return markdown
    }

    /// Generate filename from title using YYYY MMM DD [Title] format
    func generateFilename(from title: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy MMM dd"
        let dateString = dateFormatter.string(from: Date())

        let cleanTitle = title.isEmpty ? "Untitled" : title
        return "\(dateString) [\(cleanTitle)].md"
    }
}
