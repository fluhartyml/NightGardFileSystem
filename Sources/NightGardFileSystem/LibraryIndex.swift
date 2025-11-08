//
//  LibraryIndex.swift
//  DiamondNotesVault
//
//  Library-level index.json structure
//
//  Terminology:
//  - Library: Parent folder (e.g., OnionBlog) containing all notebooks
//  - Notebook/Binder: Subfolder (e.g., Claude-Sessions) containing pages
//  - Page: Individual markdown file (e.g., 2025-NOV-07-Note.md)
//  - Media: Pocket folder (media/) in each notebook holding images/videos
//

import Foundation

/// Root library index (e.g., OnionBlog/index.json)
/// Tracks all notebooks (binders) within the parent library folder
public struct LibraryIndex: Codable {
    public var libraryName: String
    public var createdDate: Date
    public var lastModified: Date
    public var notebooks: [NotebookMetadata]

    public init(libraryName: String, createdDate: Date, lastModified: Date, notebooks: [NotebookMetadata]) {
        self.libraryName = libraryName
        self.createdDate = createdDate
        self.lastModified = lastModified
        self.notebooks = notebooks
    }

    enum CodingKeys: String, CodingKey {
        case libraryName, createdDate, lastModified, notebooks
    }
}

/// Metadata about a notebook/binder within the library
/// Each notebook is a subfolder containing pages and a media pocket folder
public struct NotebookMetadata: Codable, Identifiable {
    public var id: String  // Folder name
    public var displayName: String  // User-editable display name
    public var description: String  // User-editable description
    public var tags: [String]  // User-editable tags for categorization
    public var icon: String?  // Optional emoji or SF Symbol name
    public var color: String?  // Optional color identifier
    public var noteCount: Int
    public var lastModified: Date
    public var createdDate: Date

    public init(id: String, displayName: String, description: String, tags: [String], icon: String?, color: String?, noteCount: Int, lastModified: Date, createdDate: Date) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.tags = tags
        self.icon = icon
        self.color = color
        self.noteCount = noteCount
        self.lastModified = lastModified
        self.createdDate = createdDate
    }

    enum CodingKeys: String, CodingKey {
        case id, displayName, description, tags, icon, color
        case noteCount, lastModified, createdDate
    }
}

// MARK: - Notebook TOC

/// Individual notebook/binder's table of contents (e.g., Claude-Sessions/toc.json)
/// Tracks all pages (markdown files) within this notebook subfolder
public struct NotebookTOC: Codable {
    public var notebookName: String
    public var displayName: String
    public var description: String
    public var tags: [String]
    public var createdDate: Date
    public var lastModified: Date
    public var pages: [PageMetadata]

    public init(notebookName: String, displayName: String, description: String, tags: [String], createdDate: Date, lastModified: Date, pages: [PageMetadata]) {
        self.notebookName = notebookName
        self.displayName = displayName
        self.description = description
        self.tags = tags
        self.createdDate = createdDate
        self.lastModified = lastModified
        self.pages = pages
    }

    enum CodingKeys: String, CodingKey {
        case notebookName, displayName, description, tags
        case createdDate, lastModified, pages
    }
}

/// Metadata about a page (note) within a notebook/binder
/// Each page is an individual markdown file
public struct PageMetadata: Codable, Identifiable {
    public var id: String  // Filename
    public var title: String  // First line or filename
    public var tags: [String]  // User-editable tags
    public var preview: String  // First few lines of content
    public var wordCount: Int
    public var createdDate: Date
    public var lastModified: Date
    public var hasFrontmatter: Bool

    public init(id: String, title: String, tags: [String], preview: String, wordCount: Int, createdDate: Date, lastModified: Date, hasFrontmatter: Bool) {
        self.id = id
        self.title = title
        self.tags = tags
        self.preview = preview
        self.wordCount = wordCount
        self.createdDate = createdDate
        self.lastModified = lastModified
        self.hasFrontmatter = hasFrontmatter
    }

    enum CodingKeys: String, CodingKey {
        case id, title, tags, preview, wordCount
        case createdDate, lastModified, hasFrontmatter
    }
}

// MARK: - Page Frontmatter

/// YAML-style frontmatter at the top of markdown files
/// Format:
/// ---
/// title: My Note Title
/// tags: [tag1, tag2, tag3]
/// created: 2025-11-07T14:30:00Z
/// modified: 2025-11-07T15:45:00Z
/// ---
public struct PageFrontmatter: Codable {
    public var title: String?
    public var tags: [String]
    public var created: Date?
    public var modified: Date?
    public var customFields: [String: String]  // User-extensible

    enum CodingKeys: String, CodingKey {
        case title, tags, created, modified, customFields
    }

    init(title: String? = nil, tags: [String] = [], created: Date? = nil, modified: Date? = nil, customFields: [String: String] = [:]) {
        self.title = title
        self.tags = tags
        self.created = created
        self.modified = modified
        self.customFields = customFields
    }
}
