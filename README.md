# NightGardFileSystem

File system management module for NightGard apps. Handles library organization, notebook binders, markdown files, media storage, and indexing.

## Features

- **FileSystemManager**: Read/write markdown files with embedded media
- **IndexManager**: Library-wide indexing with JSON-based metadata
- **LibraryIndex**: Hierarchical organization (Library → Sections → Collections → Binders)
- **Security-scoped bookmarks**: Persistent access to user-selected folders
- **Media management**: Automatic media folder creation and asset storage
- **Table of Contents**: Auto-generated TOC for notebooks

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/fluhartyml/NightGardFileSystem", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/fluhartyml/NightGardFileSystem`
3. Select version

## Usage

```swift
import NightGardFileSystem

// File operations
let fsManager = FileSystemManager.shared
try fsManager.saveNote(title: "My Note", attributedContent: content, to: fileURL)

// Library indexing
let indexManager = IndexManager.shared
let index = try indexManager.loadLibraryIndex(libraryURL: parentURL)
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
