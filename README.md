# NightGardFileSystem

> 📁 File system management module for NightGard apps

A Swift Package that handles library organization, notebook binders, markdown files, media storage, and JSON-based indexing. Perfect for note-taking apps, knowledge bases, or any app that needs hierarchical file organization.

## ✨ Features

- **FileSystemManager**: Read/write markdown files with embedded media
- **IndexManager**: Library-wide indexing with JSON-based metadata
- **LibraryIndex Models**: Hierarchical organization (Library → Sections → Collections → Binders)
- **Security-scoped bookmarks**: Persistent access to user-selected folders (iOS/macOS)
- **Media management**: Automatic media folder creation and asset storage
- **Table of Contents**: Auto-generated TOC for notebooks
- **Metadata support**: Tags, descriptions, icons, colors for organization

## 📦 Installation

### Swift Package Manager

**Option 1: Xcode GUI**
1. In Xcode, go to **File → Add Package Dependencies**
2. Enter: `https://github.com/fluhartyml/NightGardFileSystem`
3. Select version: `1.0.0` or higher
4. Click **Add Package**

**Option 2: Package.swift**
```swift
dependencies: [
    .package(url: "https://github.com/fluhartyml/NightGardFileSystem", from: "1.0.0")
]
```

## 🚀 Quick Start

### 1. Import the module

```swift
import NightGardFileSystem
```

### 2. Save a note with images

```swift
let fsManager = FileSystemManager.shared

// Create attributed content with formatting and images
let attributedContent = NSMutableAttributedString(string: "My note content")

// Save to file
let noteURL = libraryURL.appendingPathComponent("MyBinder/MyNote.md")
try fsManager.saveNote(
    title: "My First Note",
    attributedContent: attributedContent,
    to: noteURL
)
// Images are automatically saved to MyBinder/media/ folder
```

### 3. Load a note

```swift
let (title, attributedContent) = try fsManager.loadNote(from: noteURL)
// Images are automatically loaded from media/ folder
```

### 4. Manage library index

```swift
let indexManager = IndexManager.shared

// Build library index (scans all binders)
try indexManager.rebuildLibraryIndex(libraryURL: parentURL)

// Load library index
let index = try indexManager.loadLibraryIndex(libraryURL: parentURL)

// Browse notebooks
for notebook in index.notebooks {
    print("📓 \(notebook.displayName) - \(notebook.noteCount) notes")
    print("   Section: \(notebook.tags.first ?? "None")")
    print("   Collection: \(notebook.tags.dropFirst().first ?? "None")")
}
```

### 5. Update notebook metadata

```swift
try indexManager.updateNotebookMetadata(
    libraryURL: parentURL,
    notebookID: "MyBinder",
    displayName: "My Work Notes",
    description: "Project notes and ideas",
    tags: ["Work", "Projects", "Swift"],  // Section, Collection, Keywords
    icon: "💼",
    color: "blue"
)
```

## 📚 Complete Implementation Example

```swift
import SwiftUI
import NightGardFileSystem

@main
struct MyApp: App {
    @State private var libraryURL: URL?
    @State private var libraryIndex: LibraryIndex?

    var body: some View {
        NavigationStack {
            if let index = libraryIndex {
                LibraryView(index: index)
            } else {
                Button("Select Library Folder") {
                    selectLibrary()
                }
            }
        }
        .onAppear {
            loadLibrary()
        }
    }

    func selectLibrary() {
        // Use document picker to select folder
        // Then save bookmark and load index
    }

    func loadLibrary() {
        guard let url = libraryURL else { return }
        do {
            libraryIndex = try IndexManager.shared.loadLibraryIndex(libraryURL: url)
        } catch {
            print("Failed to load library: \(error)")
        }
    }
}

struct LibraryView: View {
    let index: LibraryIndex

    var body: some View {
        List(index.notebooks) { notebook in
            VStack(alignment: .leading) {
                Text("\(notebook.icon ?? "📓") \(notebook.displayName)")
                    .font(.headline)
                Text("\(notebook.noteCount) notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(index.libraryName)
    }
}
```

## Structure

```
Library/
├── index.json                    # Library-wide index
├── Section1-Binder1/
│   ├── toc.json                 # Table of contents
│   ├── Note1.md
│   └── media/                   # Media pocket folder
│       ├── image1.jpg
│       └── video1.mp4
└── Section2-Binder2/
    ├── toc.json
    └── media/
```

## Hierarchy

- **Library**: Root folder (e.g., OnionBlog)
- **Section**: First tag (Fiction, Non-Fiction, Work)
- **Collection**: Second tag (Sci-Fi, Technology, Projects)
- **Binder**: Notebook folder containing notes
- **Page**: Individual markdown note
- **Media**: Images/videos in binder's media folder

## License

Part of the NightGard system of apps.

## Author

Michael Fluharty
