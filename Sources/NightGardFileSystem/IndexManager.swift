//
//  IndexManager.swift
//  DiamondNotesVault
//
//  Manages library index.json and notebook toc.json files
//
//  Structure:
//  - Library (parent folder) contains index.json + multiple notebooks
//  - Notebook/Binder (subfolder) contains toc.json + pages + media/ folder
//  - Page (markdown file) is an individual note
//  - Media (media/ folder) is a pocket folder in each notebook for images/videos
//

import Foundation

public class IndexManager {
    public static let shared = IndexManager()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()

    private let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()

    private init() {}

    // MARK: - Library Index Management

    /// Load or create library index.json
    public func loadLibraryIndex(libraryURL: URL) throws -> LibraryIndex {
        let indexURL = libraryURL.appendingPathComponent("index.json")

        if fileManager.fileExists(atPath: indexURL.path) {
            let data = try Data(contentsOf: indexURL)
            return try decoder.decode(LibraryIndex.self, from: data)
        } else {
            // Create new index
            let index = LibraryIndex(
                libraryName: libraryURL.lastPathComponent,
                createdDate: Date(),
                lastModified: Date(),
                notebooks: []
            )
            try saveLibraryIndex(index, to: libraryURL)
            return index
        }
    }

    /// Save library index.json
    func saveLibraryIndex(_ index: LibraryIndex, to libraryURL: URL) throws {
        let indexURL = libraryURL.appendingPathComponent("index.json")
        let data = try encoder.encode(index)
        try data.write(to: indexURL, options: .atomic)
        print("Library index saved to: \(indexURL.path)")
    }

    /// Update library index with current filesystem state
    public func rebuildLibraryIndex(libraryURL: URL) throws {
        var index = try loadLibraryIndex(libraryURL: libraryURL)

        // Scan for notebook directories
        let contents = try fileManager.contentsOfDirectory(
            at: libraryURL,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        )

        var notebookMetadataList: [NotebookMetadata] = []

        for url in contents {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue,
                  url.lastPathComponent != "media" else {
                continue
            }

            // Check if notebook already exists in index
            let notebookID = url.lastPathComponent
            if let existing = index.notebooks.first(where: { $0.id == notebookID }) {
                // Update stats but keep user-editable fields
                var updated = existing
                updated.noteCount = countMarkdownFiles(in: url)
                updated.lastModified = getModificationDate(for: url) ?? Date()
                notebookMetadataList.append(updated)
            } else {
                // Create new notebook metadata
                let metadata = NotebookMetadata(
                    id: notebookID,
                    displayName: notebookID,
                    description: "",
                    tags: [],
                    icon: "📓",
                    color: "blue",
                    noteCount: countMarkdownFiles(in: url),
                    lastModified: getModificationDate(for: url) ?? Date(),
                    createdDate: getCreationDate(for: url) ?? Date()
                )
                notebookMetadataList.append(metadata)
            }
        }

        index.notebooks = notebookMetadataList
        index.lastModified = Date()
        try saveLibraryIndex(index, to: libraryURL)
    }

    // MARK: - Notebook TOC Management

    /// Load or create notebook toc.json
    func loadNotebookTOC(notebookURL: URL) throws -> NotebookTOC {
        let tocURL = notebookURL.appendingPathComponent("toc.json")

        if fileManager.fileExists(atPath: tocURL.path) {
            let data = try Data(contentsOf: tocURL)
            return try decoder.decode(NotebookTOC.self, from: data)
        } else {
            // Create new TOC
            let toc = NotebookTOC(
                notebookName: notebookURL.lastPathComponent,
                displayName: notebookURL.lastPathComponent,
                description: "",
                tags: [],
                createdDate: Date(),
                lastModified: Date(),
                pages: []
            )
            try saveNotebookTOC(toc, to: notebookURL)
            return toc
        }
    }

    /// Save notebook toc.json
    func saveNotebookTOC(_ toc: NotebookTOC, to notebookURL: URL) throws {
        let tocURL = notebookURL.appendingPathComponent("toc.json")
        let data = try encoder.encode(toc)
        try data.write(to: tocURL, options: .atomic)
        print("Notebook TOC saved to: \(tocURL.path)")
    }

    /// Update notebook TOC with current pages
    func rebuildNotebookTOC(notebookURL: URL) throws {
        var toc = try loadNotebookTOC(notebookURL: notebookURL)

        // Scan for markdown files
        let contents = try fileManager.contentsOfDirectory(
            at: notebookURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        )

        var pageMetadataList: [PageMetadata] = []

        for url in contents {
            guard url.pathExtension == "md" else { continue }

            let pageID = url.lastPathComponent

            // Check if page already exists in TOC
            if let existing = toc.pages.first(where: { $0.id == pageID }) {
                // Update stats but keep user-editable tags
                var updated = existing
                updated.lastModified = getModificationDate(for: url) ?? Date()

                // Re-read title and preview in case content changed
                if let content = try? String(contentsOf: url) {
                    let (title, preview, wordCount) = extractPageInfo(from: content, filename: pageID)
                    updated.title = title
                    updated.preview = preview
                    updated.wordCount = wordCount
                }

                pageMetadataList.append(updated)
            } else {
                // Create new page metadata
                let content = (try? String(contentsOf: url)) ?? ""
                let (title, preview, wordCount) = extractPageInfo(from: content, filename: pageID)

                let metadata = PageMetadata(
                    id: pageID,
                    title: title,
                    tags: [],
                    preview: preview,
                    wordCount: wordCount,
                    createdDate: getCreationDate(for: url) ?? Date(),
                    lastModified: getModificationDate(for: url) ?? Date(),
                    hasFrontmatter: content.hasPrefix("---")
                )
                pageMetadataList.append(metadata)
            }
        }

        toc.pages = pageMetadataList.sorted { $0.lastModified > $1.lastModified }
        toc.lastModified = Date()
        try saveNotebookTOC(toc, to: notebookURL)
    }

    // MARK: - User Editable Metadata Updates

    /// Update notebook metadata (display name, description, tags, icon, color)
    public func updateNotebookMetadata(
        libraryURL: URL,
        notebookID: String,
        displayName: String? = nil,
        description: String? = nil,
        tags: [String]? = nil,
        icon: String? = nil,
        color: String? = nil
    ) throws {
        var index = try loadLibraryIndex(libraryURL: libraryURL)

        guard let notebookIndex = index.notebooks.firstIndex(where: { $0.id == notebookID }) else {
            throw NSError(domain: "IndexManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Notebook not found in index"])
        }

        var notebook = index.notebooks[notebookIndex]
        if let displayName = displayName { notebook.displayName = displayName }
        if let description = description { notebook.description = description }
        if let tags = tags { notebook.tags = tags }
        if let icon = icon { notebook.icon = icon }
        if let color = color { notebook.color = color }
        notebook.lastModified = Date()

        index.notebooks[notebookIndex] = notebook
        index.lastModified = Date()
        try saveLibraryIndex(index, to: libraryURL)
    }

    /// Update page metadata (tags)
    func updatePageMetadata(
        notebookURL: URL,
        pageID: String,
        tags: [String]
    ) throws {
        var toc = try loadNotebookTOC(notebookURL: notebookURL)

        guard let pageIndex = toc.pages.firstIndex(where: { $0.id == pageID }) else {
            throw NSError(domain: "IndexManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Page not found in TOC"])
        }

        var page = toc.pages[pageIndex]
        page.tags = tags
        page.lastModified = Date()

        toc.pages[pageIndex] = page
        toc.lastModified = Date()
        try saveNotebookTOC(toc, to: notebookURL)
    }

    // MARK: - Helpers

    private func countMarkdownFiles(in directory: URL) -> Int {
        guard let contents = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return 0
        }
        return contents.filter { $0.pathExtension == "md" }.count
    }

    private func getModificationDate(for url: URL) -> Date? {
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        return attributes?[.modificationDate] as? Date
    }

    private func getCreationDate(for url: URL) -> Date? {
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        return attributes?[.creationDate] as? Date
    }

    private func extractPageInfo(from content: String, filename: String) -> (title: String, preview: String, wordCount: Int) {
        let lines = content.components(separatedBy: .newlines)
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        // Extract title (first non-empty line, or filename without extension)
        let title = nonEmptyLines.first ?? filename.replacingOccurrences(of: ".md", with: "")

        // Extract preview (first 200 characters of actual content)
        let previewText = nonEmptyLines.prefix(3).joined(separator: " ")
        let preview = String(previewText.prefix(200))

        // Word count
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count

        return (title, preview, wordCount)
    }
}
