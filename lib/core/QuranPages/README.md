# QuranPages Module

> **مكتبة شاملة لعرض وتفاعل مع صفحات القرآن الكريم**

## Overview

This module provides comprehensive functionality for displaying and interacting with Quran pages in multiple view modes with full support for bookmarks, starred verses, audio playback, sharing, and translations.

## Features

✨ **Multiple View Modes**

- 📖 Page View - Traditional Mushaf page layout
- 📜 Vertical Scroll - Continuous scrolling view
- 📝 Verse by Verse - Individual verses with translations

🎨 **Customization**

- Multiple theme colors
- Adjustable font sizes
- Multiple Arabic fonts
- Dark/Light mode support

🔖 **Bookmarks & Favorites**

- Create named bookmarks with colors
- Star favorite verses
- Quick navigation

🎧 **Audio Playback**

- Multiple reciters
- Play individual verses or full surahs
- Reciter selection

📤 **Sharing**

- Share as text or image
- Include/exclude diacritics
- Optional tafseer and translations

📱 **Translation Support**

- Multiple translation languages
- Download and manage translations
- Display alongside Arabic text

---

## Folder Structure

```
QuranPages/
├── models/                      # Data models
│   ├── bookmark_model.dart
│   ├── quran_page_config.dart
│   ├── reciter_model.dart
│   └── verse_data.dart
├── services/                    # Business logic services
│   ├── bookmark_service.dart
│   ├── reciter_service.dart
│   └── starred_verses_service.dart
├── utils/                       # Utility functions
│   ├── audio_url_fixer.dart
│   ├── html_utils.dart
│   ├── number_converter.dart
│   └── quran_page_calculator.dart
├── views/                       # Main pages
│   ├── quran_details_page.dart
│   ├── quran_sura_list.dart
│   └── screenshot_preview.dart
├── widgets/                     # Reusable widgets
│   ├── common/
│   │   ├── bismallah.dart
│   │   ├── header_widget.dart
│   │   └── mushaf_page_shell.dart
│   ├── builders/
│   │   └── mushaf_divider.dart
│   ├── bottom_sheets/
│   │   └── tafseer_and_translation_sheet.dart
│   └── dialogs/
│       └── bookmark_dialog.dart
└── helpers/                     # Legacy helpers
    └── translation/
        ├── get_translation_data.dart
        ├── translation_info.dart
        ├── translationdata.dart
        └── translations/
```

---

## Key Components

### Models

- **`QuranPageConfig`**: Configuration for page display settings (theme, font, size, alignment)
- **`VerseData`**: Verse information (surah, verse, page numbers and text)
- **`BookmarkModel`**: Bookmark data with color and name
- **`ReciterModel`**: Quran reciter information

### Services

- **`BookmarkService`**: Manage bookmarks (add, remove, check existence)
- **`StarredVersesService`**: Manage starred/favorite verses
- **`ReciterService`**: Load and manage available reciters

### Utils

- **`quran_page_calculator.dart`**: Calculate quarters (hizb) and juz positions
- **`audio_url_fixer.dart`**: Fix audio URLs for compatibility
- **`number_converter.dart`**: Convert numbers to Arabic numerals
- **`html_utils.dart`**: Remove HTML tags from text

### Widgets

- **`MushafPageShell`**: Decorative frame around Quran pages
- **`MushafDivider`**: Traditional Mushaf-style dividers
- **`Basmallah`**: Bismillah header widget
- **`HeaderWidget`**: Surah header display
- **`BookmarksDialog`**: Dialog for creating bookmarks
- **`TafseerAndTranslateSheet`**: Bottom sheet for tafseer and translation

---

## Usage Example

```dart
import 'package:ghaith/core/QuranPages/views/quran_details_page.dart';

// Navigate to Quran page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => QuranDetailsPage(
      pageNumber: 1,
      jsonData: jsonData,
      quarterJsonData: quarterJsonData,
      shouldHighlightSura: true,
      shouldHighlightText: false,
      highlightVerse: "",
    ),
  ),
);
```

---

## Dependencies

```yaml
dependencies:
  quran: ^latest # Quran data and utilities
  flutter_bloc: ^latest # State management
  shared_preferences: ^latest
  flutter_html: ^latest
  just_audio: ^latest
  screenshot: ^latest
  share_plus: ^latest
```

---

## Architecture

This module follows a **clean, modular architecture**:

1. **Models**: Pure data classes
2. **Services**: Business logic and state management
3. **Utils**: Stateless helper functions
4. **View**: UI pages that compose widgets
5. **Widgets**: Reusable UI components

---

## Recent Refactoring (February 2026)

The module was refactored from a monolithic 3274-line file into modular components:

- ✅ Extracted 4 models
- ✅ Created 3 service classes
- ✅ Organized 4 utility functions
- ✅ Separated widgets into categories
- ✅ Improved maintainability and testability

---

## Contributing

When adding new features:

1. Place models in `models/`
2. Place business logic in `services/`
3. Place utilities in `utils/`
4. Keep widgets small and focused
5. Update this README accordingly
