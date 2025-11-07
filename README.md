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

## ⚠️ Important Setup Requirements

### iOS Apps

**1. Add Required Info.plist Keys**

Your app needs permission to access user-selected folders. Add these to `Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to save images in your notes.</string>

<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos for your notes.</string>

<key>UISupportsDocumentBrowser</key>
<true/>
```

**2. Enable File Access Capabilities**

In Xcode:
1. Select your target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add: **File Provider** (if accessing iCloud Drive)

**3. Enable App Sandbox (if distributing via App Store)**

For App Store distribution:
1. **Signing & Capabilities** → Add **App Sandbox**
2. Under **File Access**:
   - ✅ User Selected File: Read/Write
   - ✅ Downloads Folder: Read/Write (optional)

**Important**: Security-scoped bookmarks require proper entitlements!

### macOS Apps

**1. Disable App Sandbox (Recommended for Self-Distribution)**

If self-distributing (not via Mac App Store):
- **Signing & Capabilities** → Remove **App Sandbox**
- This gives full filesystem access without security-scoped resource limitations

**2. OR Configure App Sandbox (Mac App Store)**

If distributing via Mac App Store, keep sandbox enabled:
1. **Signing & Capabilities** → **App Sandbox**
2. Under **File Access**:
   - ✅ User Selected File: Read/Write
   - ✅ Downloads Folder: Read/Write

**3. Add Entitlements**

For sandboxed macOS apps, add to entitlements file:

```xml
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.files.bookmarks.app-scope</key>
<true/>
```

### Universal (iOS + macOS)

**Security-Scoped Bookmarks Best Practices**

```swift
// ALWAYS call startAccessingSecurityScopedResource
let url = // ... user-selected URL
guard url.startAccessingSecurityScopedResource() else {
    print("Failed to access resource!")
    return
}

// Do your work...
try FileSystemManager.shared.saveNote(...)

// ALWAYS balance with stopAccessingSecurityScopedResource
// (Usually when done with the folder or app terminates)
url.stopAccessingSecurityScopedResource()
```

**Create and Store Bookmarks**

```swift
// Save bookmark for persistent access
let bookmarkData = try url.bookmarkData(
    options: .minimalBookmark,
    includingResourceValuesForKeys: nil,
    relativeTo: nil
)
UserDefaults.standard.set(bookmarkData, forKey: "libraryBookmark")

// Restore on next launch
if let data = UserDefaults.standard.data(forKey: "libraryBookmark") {
    var isStale = false
    let url = try URL(
        resolvingBookmarkData: data,
        options: .withoutUI,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
    )

    if url.startAccessingSecurityScopedResource() {
        // Use the URL
    }
}
```

## 🔒 Permissions Checklist

Before using NightGardFileSystem, ensure:

**iOS:**
- [ ] `NSPhotoLibraryUsageDescription` in Info.plist
- [ ] `NSCameraUsageDescription` in Info.plist (if using camera)
- [ ] App Sandbox enabled with User Selected File: Read/Write
- [ ] Security-scoped bookmarks properly saved/restored

**macOS (Self-Distributed):**
- [ ] App Sandbox **disabled** OR
- [ ] App Sandbox enabled with User Selected File: Read/Write
- [ ] Entitlements configured for bookmarks
- [ ] Security-scoped resource access in code

**macOS (Mac App Store):**
- [ ] App Sandbox enabled
- [ ] User Selected File: Read/Write permission
- [ ] Bookmarks entitlement configured
- [ ] Security-scoped resource access implemented

## 🐛 Common Issues

**"Operation not permitted" error**
- Check App Sandbox settings
- Verify you called `startAccessingSecurityScopedResource()`
- Make sure bookmark was created properly

**"No such file or directory" after app restart**
- You need to save and restore security-scoped bookmarks
- See bookmark example above

**Photos not loading**
- Check `NSPhotoLibraryUsageDescription` is in Info.plist
- User may have denied permission - check in Settings

## License

Part of the NightGard system of apps.

## Author

Michael Fluharty
