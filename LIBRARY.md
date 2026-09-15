# Library Feature Architecture & Design Specification (`LIBRARY.md`)

The **Library Feature** (`lib/features/library/`) serves as the personal library management hub, document ingestion gateway, reading session coordinator, and highlight/bookmark archive for the application.

---

## 1. Feature Architecture Overview

```
                               ┌─────────────────────────────┐
                               │        LibraryScreen        │
                               │  (lib/features/library/)    │
                               └──────────────┬──────────────┘
                                              │
             ┌────────────────────────────────┼────────────────────────────────┐
             │                                │                                │
             ▼                                ▼                                ▼
  ┌───────────────────────┐       ┌───────────────────────┐       ┌───────────────────────┐
  │   Home Library Tab    │       │ Saved & Bookmarks Tab │       │ Persistent MiniPlayer │
  │   (Shelves & Search)  │       │ (Highlights & Notes)  │       │   (Audio Sync Pill)   │
  └───────────┬───────────┘       └───────────┬───────────┘       └───────────┬───────────┘
              │                               │                               │
              ▼                               ▼                               ▼
  ┌───────────────────────────────────────────────────────────────────────────────────────┐
  │                                   Data & Storage Layer                                │
  │        • HiveStorageService (Progress, Recent Books, Highlights, Bookmarks)           │
  │        • SampleBooksProvider (Bundled Malayalam & World Classic Samples)             │
  │        • OpenEpubUseCase │ OpenPdfUseCase │ ScanBookUseCase │ TextDocumentParser     │
  └───────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Component Hierarchy & Presentation Modules

### 2.1 Top Branding & Search Hub
- **Branding Header**: Emblem badge (`📚`), Serif title `My Library`, and `EPUB & Audiobooks` subtitle.
- **View Toggle**: Micro-action button to switch between dynamic horizontal shelf view and full catalog grid view (`_isGridView`).
- **Theme Picker**: Quick access modal triggering `_showThemeSelectionModal` (`System`, `Light`, `Dark`).
- **Search Capsule (`_buildSearchBar`)**: 16px corner radius text field with live query debouncing and clear button.
- **Import Hub Action (`_buildImportHubButton`)**: Quick bottom sheet trigger for EPUB, PDF, OCR camera scan, and Quick Paste.
- **Category Filter Action (`_buildFilterHubButton`)**: Quick category selector with active dot indicator badge.

### 2.2 Action Trio Bar (`_buildActionTrioBar`)
Provides immediate 1-tap jump actions for the current hero book:
1. **Read**: Opens the reader screen at the user's latest saved paragraph offset.
2. **Listen**: Launches the audiobook narration player with real-time text sync.
3. **Explore**: Toggles between grid browsing and shelf browsing mode.

### 2.3 Shelves & Book Card Presentation
1. **Continue Reading Shelf (`_AnimatedHistoryShelf` / `_buildHistoryCard`)**:
   - Focus scaling (`scale: 1.0` vs `0.93`), 3D spine depth, glowing amber continuous progress indicator, chapter stats, relative read time badge, and dedicated `Read` + `Audio` buttons.
2. **Curated Horizontal Shelves (`_AnimatedHorizontalShelf` / `_buildShelfBookCard`)**:
   - Smooth horizontal scrolling with perspective tilt transforms.
   - 3D physical book cover with left spine crease shadow, diagonal glossy sheen light overlay, format badges (`EPUB`, `PDF`, `SCAN`, `TEXT`), and tactile action capsules.
3. **Catalog Grid & List Slivers (`_buildGridSliver`, `_buildListSliver`, `_buildBookCard`, `_buildBookListTile`)**:
   - Comprehensive browsing modes for large personal libraries with custom book deletion support.

### 2.4 Persistent Active Audio Mini-Player (`_buildActiveAudioPlayerTile`)
- Listens reactively to `BookSessionController.activeSessionNotifier`.
- Renders an ambient glowing floating pill at the bottom whenever background TTS/audio narration is playing.
- Features: Mini cover art, chapter title, live waveform visualizer icon, progress bar, play/pause, next paragraph, and close buttons.

### 2.5 Saved & Bookmarks Hub (`_buildSavedSection`)
- **Segmented Filter Pills**: `All (N)`, `Highlights (N)`, `Bookmarks (N)`, `Notes (N)`.
- **Highlight Cards (`_buildHighlightCard`)**: Color-matched left highlighter stripe, italic serif quote snippet, optional translation/note box, and `Read in Chapter` quick jump.
- **Bookmark Cards (`_buildBookmarkCard`)**: Gold bookmark ribbon indicator, chapter title, passage snippet, creation timestamp, and quick navigation.

---

## 3. Document Ingestion Pipeline

```
  User Selects File / Action
              │
   ┌──────────┼──────────────────────┬──────────────────────┐
   │          │                      │                      │
   ▼          ▼                      ▼                      ▼
  EPUB       PDF                 OCR Camera            Quick Paste
 (.epub)    (.pdf)               Scan (/scan)         (/text_content)
   │          │                      │                      │
   ▼          ▼                      ▼                      ▼
OpenEpub   OpenPdf               ScanBook              TextDocument
 UseCase    UseCase               UseCase                Parser
   │          │                      │                      │
   └──────────┴──────────────────────┴──────────────────────┘
                                 │
                                 ▼
                    Persistent Storage (Hive)
                                 │
                                 ▼
                     Library Screen Auto-Refresh
```

---

## 4. Visual Design Tokens

| Token | Dark Theme (Obsidian) | Light Theme (Warm Parchment) |
| :--- | :--- | :--- |
| **Canvas Background** | `#14100C` | `#FBF7F0` |
| **Card Background** | `#1E1812` | `#FFFDF8` |
| **Card Border** | `#382F24` | `#E2D6C5` |
| **Primary Text** | `#F7F2EB` | `#261D13` |
| **Secondary Text** | `#A89F93` | `#7A6E5F` |
| **Gold Accent** | `#D4A373` | `#D4A373` |
| **Chip Background** | `#2C2218` | `#EADBCE` |

---

## 5. Testing & Verification Matrix

Automated widget tests for the Library feature are defined in [`test/widget_test.dart`](file:///Users/admin/epub_audio/test/widget_test.dart):

- `LibraryScreen loads and renders search bar, row shelves and sample books`: Verifies initial load, search input, shelf headers, and sample books.
- `LibraryScreen search filters books by query`: Tests live search filtering and query reset.
- `LibraryScreen displays Continue Reading shelf when progress exists`: Tests progress map rendering.
- `LibraryScreen switches to Saved & Bookmarks tab and displays saved items`: Tests highlights, bookmarks, and notes.
- `LibraryScreen displays active audio player tile when an audiobook session is active`: Tests reactive mini-player banner.
- `LibraryScreen opens Theme Selection modal and switches theme mode`: Tests theme selection and persistence.
