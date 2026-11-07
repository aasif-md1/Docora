<div align="center">

<img src="icon.png" alt="Docora Logo" width="140" />

# Docora

### Every document. Beautifully simple.

A modern, high-performance, completely offline document manager and multi-format reader for Android. Built with a focus on speed, privacy, and desktop-grade document processing on mobile devices.

---

</div>

## Overview

Docora is an all-in-one document suite designed for users who need dependable, offline access to their files without telemetry, third-party cloud dependence, or intrusive analytics. From multi-thousand-page PDFs to complex spreadsheets, formatted Word files, presentations, and encrypted archives, Docora renders every format with fidelity.

Docora pairs high-speed rendering engines with home-screen Android widgets, an encrypted personal vault, document scanning utilities, and an adaptive personalization engine featuring 16 accent colorways.

---

## Key Capabilities

### 1. Unified Multi-Format Document Viewer

- **Portable Document Format (PDF):**
  - Powered by native 60 FPS rendering with hardware acceleration.
  - Freehand drawing, highlighter strokes, text callout notes, and signature annotations.
  - Instant text search with multi-occurrence highlighting.
  - Reading modes: Normal, True Dark (AMOLED friendly), Sepia, and Inverted.
  - Dual layout modes: Continuous vertical scroll and single-page horizontal flip.
  - In-document table of contents and page jump navigation.

- **Microsoft Word (DOCX, DOC, ODT, RTF):**
  - High-fidelity offline document parser with authentic typographic layout.
  - Native table rendering, styled headings, list hierarchies, and embedded images.
  - Night mode color inversion for comfortable night-time reading.
  - In-document full text search and match counter.

- **Microsoft Excel (XLSX, XLS, CSV):**
  - Multi-sheet workbook navigation with sheet tabs.
  - Grid cell calculation, alignment preservation, and freeze header support.

- **Microsoft PowerPoint (PPTX, PPT):**
  - High-resolution slide-by-slide presentation deck viewer.

- **Digital Books & Text (EPUB, TXT, Markdown):**
  - Flowable text formatting, chapter outline navigation, and markdown syntax rendering.

- **Compressed Archives (ZIP, RAR, 7Z, TAR, GZ):**
  - Built-in archive explorer allowing preview and extraction directly within the app.

---

### 2. Document Scanner & Camera OCR

- Built-in document capture with edge correction and perspective enhancement.
- Instant multi-page capture with conversion to compressed PDF files.
- Offline text extraction and metadata indexing.

---

### 3. Encrypted Document Vault

- Secure, sandbox-isolated document storage protected from external file indexing.
- Zero plaintext data exposed to external media scanners.
- Storage monitoring calculating encrypted storage utilization against total filesystem capacity.

---

### 4. PDF Power Tools

- **Image to PDF:** Convert gallery pictures and camera scans into single or multi-page PDF documents.
- **Merge PDF:** Combine multiple PDF files into an organized document.
- **Compress PDF:** Reduce document file sizes while retaining typographic readability.
- **Watermark:** Add text watermarks for document security and identity protection.

---

### 5. Native Android Home-Screen Widgets

Docora includes 4 native RemoteViews home-screen widgets styled with a horizontal linear slate-to-black gradient background (`#2C303A` to `#0E1015`), a fine hairline frosted outline, and real-time state synchronization:

- **Scanner Widget (4x1):** Quick camera capture and document scanning launcher.
- **Quick Open Widget (4x1):** Direct category shortcuts for PDF, Word, Excel, and PowerPoint files.
- **Tools Widget (4x1):** Quick-launch shortcuts for Image to PDF, Merge, Watermark, and Compress.
- **Vault Widget (2x2):** Secure vault storage gauge with live file count and filesystem metrics.

All widgets dynamically adopt the user-selected accent color in real time.

---

### 6. Personalization Engine

Docora features an accent palette with 16 curated colorways designed for optimal contrast across light, dark, and AMOLED black interfaces:

| Name | Hex Code | Tone |
| :--- | :--- | :--- |
| **Indigo Pulse** | `#4F6BED` | Signature electric indigo |
| **Royal Cobalt** | `#2563EB` | Deep vivid royal blue |
| **Skyline Azure** | `#0EA5E9` | Crisp daytime sky blue |
| **Nordic Cyan** | `#06B6D4` | Arctic high-clarity electric cyan |
| **Oceanic Teal** | `#0D9488` | Deep marine teal |
| **Mint Aurora** | `#10B981` | Fresh luminous mint emerald |
| **Emerald Matrix** | `#16A34A` | Botanical forest green |
| **Lime Volt** | `#84CC16` | Cyber high-energy electric lime |
| **Solar Flare** | `#EAB308` | Radiant sunlight gold |
| **Sunset Amber** | `#D97706` | Warm desert amber |
| **Coral Horizon** | `#F97316` | Vibrant tropical orange |
| **Terracotta Rust** | `#C2410C` | Minimalist warm clay |
| **Crimson Blaze** | `#E11D48` | Fiery high-contrast crimson |
| **Sakura Rose** | `#EC4899` | Modern blossom pink |
| **Cyberpunk Violet** | `#7C3AED` | Futuristic neon violet |
| **Neon Amethyst** | `#A855F7` | Luminous radiant purple |

Accent color adjustments update the entire application interface, bottom navigation bar, and active home-screen widgets simultaneously.

---

### 7. Modern Docked Navigation

Docora utilizes a custom bottom navigation interface:
- **Light Theme:** Pitch-black bar (`#101114`) with a thick white ring surrounding the center action button.
- **Dark Theme:** Lifted dark grey bar (`#1A1D23`) with a 1dp top divider (`#2B2F38`) and scaffold-matching ring.
- **Lifted Action Button:** Elevated center action button providing quick access to document creation, scanning, and file imports.

---

## Architecture & Core Tech

- **Framework:** Flutter with Dart
- **State Management:** Riverpod (compile-safe dependency injection and reactive state providers)
- **Local Persistence:** Isar / SharedPreferences with reactive observers
- **PDF Engine:** pdfrx with native Pdfium rendering backend
- **Document Engine:** Custom offline Gander WebView runtime
- **Icons:** Lucide Icons & Material Design Icons
- **Typography:** Inter typography system
- **Widgets:** Android AppWidgetProvider with custom Bitmap Canvas drawing pipelines

---

## Security & Privacy Commitment

Docora operates entirely on-device:
- No internet permissions required for document viewing.
- No remote telemetry, crash trackers, or analytics collectors.
- Documents are never transmitted outside the local device storage.
- Storage permissions are strictly used for local file indexing and vault isolation.

---

## License

This project is licensed under the Apache License 2.0. See the LICENSE file for details.
