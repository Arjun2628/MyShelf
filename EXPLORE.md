# Explore Feature & Curated Catalog Discovery Architecture (`EXPLORE.md`)

The **Explore Feature** (`lib/features/explore/`) powers the rich discovery experience, dual view modes (3D Discovery Stage & Classic Editorial Feed), dynamic curated shelves, category browsing with atmospheric backdrops, 3D interactive book opening stages, and synchronization with the Admin Curator Console & Cloud Catalog.

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
  │  3D Discovery Stage   │       │ Dynamic Classic Feed  │       │ 3D Book Opening Stage │
  │(ExploreDiscoveryStage)│       │   (ShelfRenderer)     │       │ (Perspective & Lights)│
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

## 2. Dual View Modes in `ExploreScreen`

The Explore screen provides seamless toggleable modes with instant animations and user preference persistence via `SharedPreferences`:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                               2 Explore View Modes                                     │
├─────────────────────────┬──────────────────────────────────────────────────────────────┤
│ 1. 3D Discovery Stage   │ • Animated 3D Spotlight Carousel with 5s auto-switch         │
│    (Like Library)       │ • Interactive metadata card (Read, Listen, 3D Inspect)       │
│                         │ • Thematic Category Discovery Portals (with ambient themes)   │
│                         │ • Grand Curator's Bookcase (Spine View & Face View)          │
│                         │ • Tabletop decor (brass compass, magnifying glass, succulent)│
│                         │ • Dynamic Category Filter Chips                              │
├─────────────────────────┼──────────────────────────────────────────────────────────────┤
│ 2. Editorial Feed       │ • Preserved Classic Catalog with 7 dynamic shelf styles      │
│    (Classic Mode)       │ • Mood & Category horizontal sliders                         │
│                         │ • Continue Reading & Continue Listening progress cards       │
│                         │ • Sliver-based smooth fluid scrolling                        │
└─────────────────────────┴──────────────────────────────────────────────────────────────┘
```

---

## 3. Dynamic Curated Shelf System (`ShelfRenderer`)

The Classic Editorial Catalog Feed supports **7 distinct shelf presentation styles** configured dynamically via local presets, the Admin Curator Console, or Cloud Manifests:

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
## 2. Grand Bookshelf Wall Discovery Architecture

The Explore feature delivers an authentic, tactile **Grand Bookshelf Wall** exploration experience designed to feel like browsing through an expansive archival library or antique bookstore, packed with realistic book arrangements directly inspired by rich library bookshelf art.

---

## 🏛️ Key Exploration Components

### 1. **Grand Bookshelf Wall Engine** (`GrandBookshelfWallWidget`)
- **Full-Wall Multi-Tier Shelves**: Continuous vertical-scrolling library wall with rich wooden carpentry (solid wood plank top with light highlight, bevel edge, recessed shelf backing shadow, and brass bracket trim).
- **Natural Book Clusters**:
  - **Vertical Volumes**: Varied heights and widths with distinct vintage & modern foil stamping.
  - **Tilted / Leaning Books**: Realistic angular tilts ($\pm 10^\circ$ to $\pm 18^\circ$) resting against adjacent stacks and shelf ends.
  - **Horizontal Stacks**: Multi-book stacks laid flat with visible gilded page edges and dangling bookmark ribbons.
  - **Multi-Volume Collector Series**: Uniform matching tomes with Roman numeral volume insignias (`I`, `II`, `III`).
- **Tactile Pull-to-Inspect Interaction**: Tapping any book glides it forward with haptic feedback and cast shadows, opening the 3D exploration inspection sheet.
- **Serendipity "Lucky Pick" Tool**: Interactive button that spins and pulls a random book from the shelf with an animated spotlight and quick action snackbar.

### 2. **Realistic Book Spine Engine** (`RealisticBookSpineWidget`)
- Procedural spine styling generator supporting 6 decorative styles (Ornate Vintage, Geometric Bands, Two-Tone Minimal, Multi-Volume Ribbed, Heraldic Cameo, Modern Clean).
- 9 curated authentic palettes (Deep Teal, Coral Rose, Mustard Ochre, Prussian Blue, Forest Sage, Antique Parchment, Deep Mahogany, Dusty Lavender, Olive Moss).

### 3. **Dual Exploration Modes**
- **Grand Bookshelf Wall**: The primary immersive full-wall natural browsing experience.
- **Editorial Feed**: The classic magazine-style feed with categorized horizontal carousels, featured today hero cards, and mood categories. Switchable seamlessly via the top header pill.

---

## 6. Admin Curator Console & Cloud Catalog Sync Integration

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

---

## 7. Testing & Verification Matrix

Automated tests for Explore and Catalog Sync are located in:
- [`test/unit/explore_ui_test.dart`](file:///Users/admin/epub_audio/test/unit/explore_ui_test.dart): Verifies `ExploreScreen` dual-mode rendering (3D Discovery Stage vs Editorial Feed), Spine/Cover switching, `HeroBookCard`, `CategoryCard`, and `ShelfRenderer`.
- [`test/unit/explore_domain_test.dart`](file:///Users/admin/epub_audio/test/unit/explore_domain_test.dart): Verifies `BookShelf`, `Category`, `CategoryExperienceConfig`, and `ExploreSection` domain models.
- [`test/unit/explore_repository_test.dart`](file:///Users/admin/epub_audio/test/unit/explore_repository_test.dart): Tests Explore data source loading, caching, and category filtering.
- [`test/unit/book_opening_experience_test.dart`](file:///Users/admin/epub_audio/test/unit/book_opening_experience_test.dart): Tests `BookCover3DStage` transforms and atmospheric painter.
- [`test/unit/catalog_sync_test.dart`](file:///Users/admin/epub_audio/test/unit/catalog_sync_test.dart): Tests remote catalog manifest serialization, Hive cache fallback, and sync service.
