# Explore Feature & Curated Catalog Discovery Architecture (`EXPLORE.md`)

The **Explore Feature** (`lib/features/explore/`) powers the rich discovery experience, dynamic curated shelves, category browsing with atmospheric backdrops, 3D interactive book opening stages, and synchronization with the Admin Curator Console & Cloud Catalog.

---

## 1. Feature Architecture Overview

```
                               ┌─────────────────────────────┐
                               │        ExploreScreen        │
                               │  (lib/features/explore/)    │
                               └──────────────┬──────────────┘
                                              │
             ┌────────────────────────────────┼────────────────────────────────┐
             │                                │                                │
             ▼                                ▼                                ▼
  ┌───────────────────────┐       ┌───────────────────────┐       ┌───────────────────────┐
  │   Dynamic Shelves     │       │  Category Experience  │       │ 3D Book Opening Stage │
  │   (ShelfRenderer)     │       │ (Thematic Atmosphere) │       │ (Perspective & Lights)│
  └───────────┬───────────┘       └───────────┬───────────┘       └───────────┬───────────┘
              │                               │                               │
              ▼                               ▼                               ▼
  ┌───────────────────────────────────────────────────────────────────────────────────────┐
  │                                Domain & Repository Layer                              │
  │        • ExploreRepository / ExploreRepositoryImpl                                    │
  │        • BookShelf │ Category │ CategoryExperienceConfig │ ExploreSection             │
  │        • RemoteCatalogRepository │ CatalogSyncService │ AdminCatalogScreen            │
  └───────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Dynamic Curated Shelf System (`ShelfRenderer`)

The Explore discovery engine supports **7 distinct shelf presentation styles** configured dynamically via local presets, the Admin Curator Console, or Cloud Manifests:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                               7 Dynamic Shelf Display Styles                           │
├─────────────────────────┬──────────────────────────────────────────────────────────────┤
│ 1. Large Featured       │ Hero spotlight banner with rich backdrop & glowing metadata  │
│ 2. Story Cards          │ Vertical cards with full-bleed imagery and storyline quotes  │
│ 3. Horizontal Carousel  │ Smooth side-scrolling cards with focal zoom & tilt effects   │
│ 4. Cover Carousel       │ Minimalist cover-first carousel with reflection sheen        │
│ 5. Horizontal Shelf     │ Classic bookstore row with title, author, and audio badges   │
│ 6. Vertical List        │ Dense, scannable editorial list with chapter & duration data │
│ 7. Grid Matrix          │ 2-column or 3-column responsive catalog grid                 │
└─────────────────────────┴──────────────────────────────────────────────────────────────┘
```

---

## 3. Immersive Category Experience (`CategoryExperienceScreen`)

When a user taps any category (e.g. *Malayalam Classics*, *Science Fiction*, *Ancient Philosophy*):
- **Atmospheric Palette**: Injects a custom theme palette with gradient backdrops (`ambientColor`, `particleColor`).
- **Dynamic Shelf Loading**: Fetches category-specific books via `GetCategoryBooksUseCase`.
- **Editorial Subtitle & Header**: Displays localized descriptions and total volume counts.
- **Direct Reader & Audio Entrypoints**: Allows 1-tap launching into either the EPUB/PDF reading view or audiobook session.

---

## 4. 3D Book Opening Experience (`BookCover3DStage`)

When previewing or opening a book from the Explore Hub:
1. **Interactive 3D Perspective**: Utilizes `Matrix4` transformations (`setEntry(3, 2, 0.001)`, `rotateY`, `rotateX`) driven by user gesture dragging.
2. **Spine & Page Thickness**: Simulates realistic physical hardcover depth with stacked layers and spine crease shadows.
3. **Ambient Particle System (`AtmosphereParticlesPainter`)**: Renders floating illuminated dust motes/light particles matching the book's atmospheric mood.
4. **Lighting & Specular Reflection**: Dynamic sheen layers that react to tilt angle.

---

## 5. Admin Curator Console & Cloud Catalog Sync Integration

```
  Curator Configures Shelf / Manifest
                  │
                  ▼
         AdminCatalogScreen
  (lib/features/admin/presentation/)
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
   Save to Hive        Publish Cloud Snapshot
  (Local Cache)       (Encrypted Remote Sync)
        │                   │
        └─────────┬─────────┘
                  │
                  ▼
         CatalogSyncService
                  │
                  ▼
         ExploreRepositoryImpl
  (lib/features/explore/data/)
                  │
                  ▼
       Live Explore UI Updates
```

- **Curated Shelves Tab**: Live reordering, display style switching, and book selection.
- **Catalog Books Tab**: Complete overview of all books in the master catalog.
- **Cloud Sync Tab**: Real-time cloud sync status, pull updates, and encrypted snapshot creation.

---

## 6. Testing & Verification Matrix

Automated tests for Explore and Catalog Sync are located in:
- [`test/unit/explore_domain_test.dart`](file:///Users/admin/epub_audio/test/unit/explore_domain_test.dart): Verifies `BookShelf`, `Category`, `CategoryExperienceConfig`, and `ExploreSection` domain models.
- [`test/unit/explore_repository_test.dart`](file:///Users/admin/epub_audio/test/unit/explore_repository_test.dart): Tests Explore data source loading, caching, and category filtering.
- [`test/unit/explore_ui_test.dart`](file:///Users/admin/epub_audio/test/unit/explore_ui_test.dart): Tests `ExploreScreen` rendering, `HeroBookCard`, `CategoryCard`, and `ShelfRenderer`.
- [`test/unit/book_opening_experience_test.dart`](file:///Users/admin/epub_audio/test/unit/book_opening_experience_test.dart): Tests `BookCover3DStage` transforms and atmospheric painter.
- [`test/unit/catalog_sync_test.dart`](file:///Users/admin/epub_audio/test/unit/catalog_sync_test.dart): Tests remote catalog manifest serialization, Hive cache fallback, and sync service.
