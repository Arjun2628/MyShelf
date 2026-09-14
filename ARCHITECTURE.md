# EPUB Reader & Audiobook Engine Architecture

A modern, high-performance Flutter application built on Clean Architecture principles, featuring a pure Dart EPUB extraction/parsing pipeline and a synchronized reading + audio engine.

---

## 1. System Overview & Dependency Direction

```
                 PRESENTATION (UI / Screens / Widgets)
                                   │
                                   ▼
                 APPLICATION (Controllers / Session State)
                                   │
                                   ▼
                 DOMAIN (Entities / Use Cases / Contracts)
                                   ▲
                                   │
                 DATA (Parsers / Decoders / Data Sources)
```

**Rule:** The Domain Layer remains 100% pure Dart, decoupled from Flutter UI widgets and framework dependencies.

---

## 2. Complete Project Architecture

```
                              ┌─────────────────────┐
                              │      Flutter App    │
                              └──────────┬──────────┘
                                         │
                ┌────────────────────────┼────────────────────────┐
                │                        │                        │
                ▼                        ▼                        ▼
        ┌──────────────┐        ┌──────────────┐        ┌──────────────┐
        │   Library    │        │    Reader    │        │   Audiobook  │
        │   Feature    │        │   Feature    │        │   Feature    │
        └──────┬───────┘        └──────┬───────┘        └──────┬───────┘
               │                       │                       │
               └───────────────────────┼───────────────────────┘
                                       ▼
                              ┌─────────────────┐
                              │  Unified Book   │
                              │  Session State  │
                              └────────┬────────┘
                                       │
             ┌─────────────────────────┼─────────────────────────┐
             ▼                         ▼                         ▼
      ┌─────────────┐          ┌─────────────┐          ┌─────────────┐
      │ EPUB Engine │          │ Audio Engine│          │ Preferences │
      └──────┬──────┘          └──────┬──────┘          └──────┬──────┘
             │                        │                        │
             ▼                        ▼                        ▼
      ┌────────────────────────────────────────────────────────────┐
      │                       Domain Layer                         │
      │                                                            │
      │ Book │ Chapter │ ContentNode │ BookPosition │ Bookmark     │
      └────────────────────────────┬───────────────────────────────┘
                                   │
                                   ▼
      ┌────────────────────────────────────────────────────────────┐
      │                     Data Layer                             │
      │                                                            │
      │ ArchiveLoader │ OpfParser │ TocParser │ ContentParser      │
      └────────────────────────────┬───────────────────────────────┘
                                   │
                                   ▼
                         ┌──────────────────┐
                         │   File System    │
                         │   / Local DB     │
                         └──────────────────┘
```

---

## 3. EPUB Engine Pipeline

```
                         EPUB FILE (.epub)
                                │
                                ▼
                        ┌────────────────┐
                        │  ArchiveLoader │
                        └───────┬────────┘
                                │
                                ▼
                        ┌────────────────┐
                        │  ZipDecoder    │ (Decompress into memory)
                        └───────┬────────┘
                                │
                 ┌──────────────┴──────────────┐
                 │                             │
                 ▼                             ▼
          META-INF/container.xml          EPUB Folder
                 │                             │
                 ▼                             │
          ┌───────────────┐                    │
          │ Container     │                    │
          │ Parser        │                    │
          └───────┬───────┘                    │
                  │                            │
                  │ OPF path                   │
                  └─────────────┐              │
                                ▼              ▼
                          ┌────────────────────────┐
                          │       OpfParser        │
                          └───────────┬────────────┘
                                      │
              ┌───────────────────────┼───────────────────────┐
              ▼                       ▼                       ▼
         ┌────────┐             ┌────────────┐           ┌──────────┐
         │Metadata│             │  Manifest  │           │  Spine   │
         │ (DC)   │             │ (Resource) │           │ (Order)  │
         └────────┘             └─────┬──────┘           └────┬─────┘
                                      │                       │
                                      ▼                       ▼
                               Resource Catalog         Reading Sequence
                                      │                       │
                                      └───────────┬───────────┘
                                                  ▼
                                      ┌────────────────────────┐
                                      │       TocParser        │ (EPUB 3 Nav & EPUB 2 NCX)
                                      └───────────┬────────────┘
                                                  ▼
                                      ┌────────────────────────┐
                                      │       Book Model       │
                                      └────────────────────────┘
```

---

## 4. XHTML Content Model & Normalization

Rather than piping raw XHTML into the UI, chapters are parsed into a normalized, strongly typed tree of **ContentNodes**:

```
                    XHTML DOCUMENT
                           │
                           ▼
                    ┌─────────────┐
                    │ XHTML Parser│
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  DOM Tree   │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
         Heading       Paragraph      Image
        (h1 - h6)     (InlineSpans) (Standalone)
              │            │            │
              └────────────┼────────────┘
                           ▼
                    ┌──────────────┐
                    │ContentBlock  │
                    └──────┬───────┘
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
      Reader Renderer             Audio System
     (Flutter Widgets)           (TTS Paragraphs)
```

---

## 5. Synchronized Reading & Audio Engine (Shared State)

Reading and listening operate on the **Unified Book Position (`BookPosition`)**:

```
                         BOOK SESSION
                              │
               ┌──────────────┴──────────────┐
               ▼                             ▼
      ┌─────────────────┐           ┌─────────────────┐
      │ READING SYSTEM  │           │  AUDIO SYSTEM   │
      └────────┬────────┘           └────────┬────────┘
               │                             │
               ▼                             ▼
        Reading Position              Audio Position
        (Ch 2, Para 4)                (Ch 2, Para 4)
               │                             │
               └──────────────┬──────────────┘
                              ▼
                      ┌───────────────┐
                      │ BookPosition  │
                      │ • chapterIdx  │
                      │ • paraIdx     │
                      │ • progress%   │
                      └───────────────┘
```

### Bidirectional Flow:
1. **Reading $\rightarrow$ Listening**: Tap the audio button or paragraph $\rightarrow$ Audio resumes from that exact paragraph.
2. **Listening $\rightarrow$ Reading**: Audio plays $\rightarrow$ Active paragraph is highlighted in real-time and smoothly autoscrolls into view.
3. **Pluggable Audio Backend**: `AudioSourceEngine` interface supports:
   - Device TTS (`flutter_tts`)
   - Pre-recorded Audiobooks / EPUB Media Overlays
   - Cloud / Neural AI Narration engines

---

## 6. Project Directory Layout

```
lib/
├── core/
│   ├── errors/
│   │   └── epub_exceptions.dart
│   └── utils/
│       └── path_utils.dart
│
├── features/
│   ├── epub/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── epub_archive.dart
│   │   │   │   └── epub_archive_loader.dart
│   │   │   ├── parsers/
│   │   │   │   ├── container_parser.dart
│   │   │   │   ├── nav_parser.dart
│   │   │   │   ├── ncx_parser.dart
│   │   │   │   ├── opf_parser.dart
│   │   │   │   ├── toc_parser.dart
│   │   │   │   └── xhtml_content_parser.dart
│   │   │   └── repositories/
│   │   │       └── epub_repository_impl.dart
│   │   │
│   │   └── domain/
│   │       ├── entities/
│   │       │   ├── book.dart
│   │       │   ├── chapter_content.dart
│   │       │   ├── content_nodes.dart
│   │       │   ├── epub_chapter.dart
│   │       │   ├── epub_manifest_item.dart
│   │       │   ├── epub_metadata.dart
│   │       │   ├── epub_spine_item.dart
│   │       │   └── toc_entry.dart
│   │       ├── repositories/
│   │       │   └── epub_repository.dart
│   │       └── usecases/
│   │           ├── open_epub_usecase.dart
│   │           └── parse_chapter_content_usecase.dart
│   │
│   ├── reader/
│   │   ├── data/
│   │   │   └── services/
│   │   │       └── translation_service.dart
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       ├── bookmark.dart
│   │   │       ├── reader_preferences.dart
│   │   │       ├── text_highlight.dart
│   │   │       └── translation_result.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── reader_controller.dart
│   │       ├── screens/
│   │       │   └── reader_screen.dart
│   │       └── widgets/
│   │           ├── bookmarks_modal.dart
│   │           ├── highlight_picker_menu.dart
│   │           ├── highlights_modal.dart
│   │           ├── image_block_widget.dart
│   │           ├── reader_content_view.dart
│   │           ├── reader_settings_modal.dart
│   │           ├── toc_drawer.dart
│   │           └── translation_modal.dart
│   │
│   ├── pdf/ (PDF Parsing & Ingestion)
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       └── open_pdf_usecase.dart
│   │   └── data/
│   │       └── parsers/
│   │           └── pdf_document_parser.dart
│   │
│   ├── audio/ (Audio & TTS System)
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── audio_track_state.dart
│   │   ├── data/
│   │   │   └── services/
│   │   │       ├── audio_notification_service.dart
│   │   │       └── tts_audio_service.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── audiobook_player_screen.dart
│   │       └── widgets/
│   │           └── mini_audio_player.dart
│   │
│   ├── voice/ (Multi-Voice Audition & Acoustic Param Casting)
│   │   └── presentation/
│   │       └── widgets/
│   │           └── book_voice_audition_modal.dart
│   │
│   ├── opening_experience/ (Decoupled Book Opening Engine & 3D Atmosphere Stage)
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── book_opening_experience_screen.dart
│   │       └── widgets/
│   │           ├── book_cover_3d_stage.dart
│   │           └── atmospheric_particle_canvas.dart
│   │
│   ├── explore/ (Discovery Hub, Dynamic Category Presets & 7 Shelf Display Styles)
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── category_experience_config.dart
│   │   │   │   ├── book_shelf.dart
│   │   │   │   └── explore_section.dart
│   │   │   └── repositories/
│   │   │       └── explore_repository.dart
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── explore_repository_impl.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── explore_screen.dart
│   │       │   └── category_experience_screen.dart
│   │       └── widgets/
│   │           └── shelves/
│   │               ├── large_featured_shelf_view.dart
│   │               ├── horizontal_carousel_shelf_view.dart
│   │               ├── horizontal_shelf_view.dart
│   │               ├── grid_shelf_view.dart
│   │               ├── vertical_list_shelf_view.dart
│   │               ├── cover_carousel_shelf_view.dart
│   │               └── story_cards_shelf_view.dart
│   │
│   ├── profile/ (Reading Identity, Activity Matrix & Avatar Customizer)
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── user_profile.dart
│   │   │   │   └── reading_stats.dart
│   │   │   └── repositories/
│   │   │       └── profile_repository.dart
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── profile_repository_impl.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── profile_screen.dart
│   │       └── widgets/
│   │           └── avatar_picker_modal.dart
│   │
│   ├── auth/ (Role-Based Authentication: Guest, Member, Admin)
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── auth_user.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── auth_controller.dart
│   │       └── widgets/
│   │           └── auth_modal.dart
│   │
│   ├── catalog/ (Remote Catalog Manifest & Cloud Sync Lifecycle)
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── remote_catalog_manifest.dart
│   │   │   ├── repositories/
│   │   │   │   └── remote_catalog_repository.dart
│   │   │   └── services/
│   │   │       └── catalog_sync_service.dart
│   │   └── data/
│   │       └── repositories/
│   │           └── remote_catalog_repository_impl.dart
│   │
│   ├── admin/ (Curator Console & Live Shelf Management)
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── admin_catalog_screen.dart
│   │       └── widgets/
│   │           └── edit_shelf_modal.dart
│   │
│   ├── session/ (Bidirectional Reader & Audiobook Synchronization)
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       ├── book_progress.dart
│   │   │       └── reading_position.dart
│   │   └── presentation/
│   │       └── controllers/
│   │           └── book_session_controller.dart
│   │
│   ├── navigation/ (Root App Navigation Shell)
│   │   └── presentation/
│   │       └── screens/
│   │           └── main_navigation_screen.dart
│   │
│   └── library/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── hive_storage_service.dart
│       │   └── sample_books_provider.dart
│       └── presentation/
│           └── screens/
│               └── library_screen.dart
│
└── main.dart
```
