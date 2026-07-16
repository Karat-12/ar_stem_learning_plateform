# Frontend Architecture — HoloSTEM Explorer

> This document is the authoritative technical reference for the Flutter frontend of the AR STEM Learning Platform. It explains every directory, every file, every design decision, and every boundary between layers. A new developer should be able to understand the codebase completely without asking questions.

---

## Table of Contents

1. [Architecture Principles](#1-architecture-principles)
2. [High-Level Structure](#2-high-level-structure)
3. [Application Flow](#3-application-flow)
4. [Dependency Flow](#4-dependency-flow)
5. [Directory Reference](#5-directory-reference)
   - [lib/](#lib)
   - [lib/core/theme/](#libcoretheme)
   - [lib/navigation/](#libnavigation)
   - [lib/shared/widgets/](#libsharedwidgets)
   - [lib/features/](#libfeatures)
   - [lib/features/dashboard/](#libfeaturesdashboard)
   - [lib/features/placeholder/](#libfeaturesplaceholder)
   - [lib/features/linked_list/](#libfeatureslinked_list)
   - [lib/features/advanced_workspaces/](#libfeaturesadvanced_workspaces)
6. [File Reference](#6-file-reference)
7. [Shared vs Feature Widgets](#7-shared-vs-feature-widgets)
8. [Misconception Detection System](#8-misconception-detection-system)
9. [Responsive Layout Strategy](#9-responsive-layout-strategy)
10. [Future Folder Expansion](#10-future-folder-expansion)

---

## 1. Architecture Principles

### Separation of Concerns

The codebase is divided into four distinct layers, each with a clear responsibility:

- **`core/`** — Defines the visual contract of the application. It owns colors and theme. Nothing outside `core/` is allowed to hardcode color values; they always come from `AppColors`.
- **`navigation/`** — Owns the root scaffold and routing logic. Screens never navigate themselves through global routing; they receive callbacks from the shell.
- **`shared/`** — Provides stateless, domain-agnostic UI primitives that any feature can use. A widget in `shared/` must not know anything about STEM content, linked lists, or any specific feature.
- **`features/`** — Contains all domain-specific screens, widgets, and models. Each feature is self-contained. A feature can use `core/` and `shared/` but must not import from another feature.

### Feature Isolation

Each folder under `features/` owns its own screens, widgets, and models. This boundary prevents cross-feature coupling and makes it safe to add, replace, or remove an entire feature without breaking other parts of the app. The linked list feature, for example, has its own model class (`LinkedListNodeModel`) and its own set of widgets because no other feature needs to render linked list nodes. Putting those in `shared/` would contaminate the shared layer with domain-specific knowledge.

### Reusable Widgets

A widget is placed in `shared/widgets/` only when it is genuinely domain-agnostic and can be used in any context without modification. `GlassCard`, `StatusChip`, and `PulseOrb` are examples — they accept styling parameters but have zero knowledge of STEM content. A widget that renders linked list arrows, atom bubbles, or logic gate chips belongs inside its specific feature folder.

### No Global State

The prototype deliberately avoids state management libraries. All state lives in `StatefulWidget` using `setState`. This keeps the codebase readable and runnable without configuration, which is appropriate for a UI prototype. When the application grows to include backend integration, persistent state, or cross-screen shared data, a state management solution should be introduced at that point.

### No Global Router

Navigation is index-based inside `AppShell`. Screens do not push routes by name. The dashboard communicates a destination by calling an `onOpenSection(int)` callback passed in by the shell. The only exception is `LinkedListLearningScreen`, which is pushed onto the navigator stack with `Navigator.push` because it is a full-screen standalone experience launched from inside the labs. This pattern should be the model for any future deep-link screens.

### Future Backend Integration

The current architecture is intentionally shaped to make backend integration non-disruptive. The rule-based `_detect*` methods in each lab are isolated functions that transform local state into feedback strings. Replacing them with API calls or an AI inference engine requires changing only those methods — not the widget structure or the UI components.


---

## 2. High-Level Structure

```
lib/
├── main.dart                         # Entry point — calls runApp
├── app.dart                          # Root MaterialApp widget
│
├── core/                             # App-wide foundation
│   └── theme/
│       ├── app_colors.dart           # Global color palette (const)
│       └── app_theme.dart            # ThemeData — Material 3 dark cyberpunk
│
├── navigation/                       # Shell and nav logic
│   └── app_shell.dart                # Root scaffold, rail/bottom nav, page switching
│
├── shared/                           # Domain-agnostic UI primitives
│   └── widgets/
│       ├── cyber_background.dart     # Full-screen gradient + grid background
│       ├── glass_card.dart           # Frosted glass container
│       ├── neon_action_card.dart     # Hover-animated card with icon, title, subtitle
│       ├── pulse_orb.dart            # Animated pulsing ring
│       └── status_chip.dart          # Pill-shaped status label with dot
│
└── features/                         # Feature-first modules (one folder per feature)
    ├── dashboard/
    │   └── dashboard_screen.dart     # Home screen with hero, action grid, metrics
    │
    ├── advanced_workspaces/
    │   └── advanced_stem_workspaces_screen.dart   # All 11 interactive STEM labs
    │
    ├── linked_list/                  # Dedicated linked list learning screen
    │   ├── linked_list_learning_screen.dart
    │   ├── models/
    │   │   └── linked_list_node_model.dart
    │   └── widgets/
    │       ├── floating_particles.dart
    │       ├── holographic_explanation_panel.dart
    │       ├── linked_list_playground.dart
    │       ├── misconception_feedback_panel.dart
    │       ├── neon_linked_list_node.dart
    │       └── operation_control_panel.dart
    │
    └── placeholder/
        └── feature_placeholder_screen.dart       # Reusable "coming soon" screen
```


---

## 3. Application Flow

When the app starts, execution flows through these layers:

```
main.dart
  └── runApp(StemArApp())
        └── app.dart → StemArApp (MaterialApp)
              ├── theme: AppTheme.darkCyberpunk
              └── home: AppShell
                    └── navigation/app_shell.dart
                          ├── CyberBackground (wraps everything)
                          ├── _CyberNavigationRail (wide screens ≥ 860px)
                          ├── BottomNavigationBar (narrow screens)
                          └── AnimatedSwitcher → one of four pages:
                                ├── [0] DashboardScreen
                                │       └── onOpenSection(int) → switches AppShell index
                                ├── [1] AdvancedStemWorkspacesScreen
                                │       └── domain selection → topic selection → lab workspace
                                │             └── Data Structures / Linked List
                                │                   └── Navigator.push → LinkedListLearningScreen
                                ├── [2] FeaturePlaceholderScreen (AR Simulation)
                                └── [3] FeaturePlaceholderScreen (Progress Tracker)
```

### Navigation Decisions

**Index-based shell navigation** is used for top-level page switching because the four main destinations (Home, Labs, AR, Progress) are always available and share the same scaffold and background. This is simpler and more performant than named routes for a fixed tab structure.

**`Navigator.push`** is used for `LinkedListLearningScreen` because it is a full-screen immersive experience with its own `Scaffold`, header, and back button. It is launched from inside the Advanced Workspaces screen when the user selects "Linked List" under Data Structures, making it a deeper screen rather than a peer tab.

**Callback-based cross-screen communication** is used instead of a global event bus. `DashboardScreen` receives `onOpenSection` from `AppShell` and calls it when the user taps a card. This keeps the flow explicit and traceable.


---

## 4. Dependency Flow

Dependencies flow strictly downward. No layer imports from a layer above it.

```
main.dart
  ↓ imports
app.dart
  ↓ imports
navigation/app_shell.dart
  ↓ imports
  ├── core/theme/app_colors.dart
  ├── shared/widgets/cyber_background.dart
  ├── features/dashboard/dashboard_screen.dart
  ├── features/advanced_workspaces/advanced_stem_workspaces_screen.dart
  └── features/placeholder/feature_placeholder_screen.dart

features/dashboard/dashboard_screen.dart
  ↓ imports
  ├── core/theme/app_colors.dart
  └── shared/widgets/  (glass_card, neon_action_card, pulse_orb, status_chip)

features/advanced_workspaces/advanced_stem_workspaces_screen.dart
  ↓ imports
  ├── core/theme/app_colors.dart
  ├── shared/widgets/glass_card.dart
  └── shared/widgets/status_chip.dart

features/linked_list/linked_list_learning_screen.dart
  ↓ imports
  ├── core/theme/app_colors.dart
  ├── shared/widgets/  (cyber_background, glass_card, status_chip)
  ├── features/linked_list/models/linked_list_node_model.dart
  └── features/linked_list/widgets/  (all six widgets)

features/linked_list/widgets/*.dart
  ↓ imports
  ├── core/theme/app_colors.dart
  ├── shared/widgets/glass_card.dart
  └── features/linked_list/models/linked_list_node_model.dart (where needed)

shared/widgets/*.dart
  ↓ imports
  └── core/theme/app_colors.dart (only)

core/theme/app_theme.dart
  ↓ imports
  └── core/theme/app_colors.dart (only)
```

**Allowed imports:**
- Any layer may import from `core/`
- Any layer may import from `shared/`
- Features may import their own `models/` and `widgets/`
- Features must NOT import from other features

**Forbidden imports:**
- `shared/` must not import from `features/`
- `core/` must not import from anywhere else in the project
- Feature A must not import from Feature B


---

## 5. Directory Reference

### `lib/`

**Purpose:** Root of all Dart source code. Contains the two entry files and the four architectural layers.

**What belongs here:** Only `main.dart` and `app.dart`. No other files should ever be placed directly in `lib/`.

**What does NOT belong here:** Screens, widgets, models, utilities, constants. All of these belong inside `core/`, `navigation/`, `shared/`, or `features/`.

---

### `lib/core/theme/`

**Purpose:** Defines the visual contract for the entire application. Any value that affects how the app looks — colors, font sizes, border radii in the theme, spacing constants — lives here.

**Why it exists:** Without a single source of truth for colors, individual screens would hardcode hex values. A design change would then require hunting across dozens of files. `AppColors` ensures that changing one value propagates everywhere automatically.

**What belongs here:**
- Color palette constants (`app_colors.dart`)
- `ThemeData` configuration (`app_theme.dart`)
- Typography constants (if added in future)
- Spacing/sizing constants (if added in future)

**What does NOT belong here:**
- Widgets — even small ones
- Business logic or feature-specific values
- Icons (Material Icons are used directly throughout the app)
- Any import from `features/` or `shared/`

---

### `lib/navigation/`

**Purpose:** Owns the root application scaffold and the logic for switching between top-level destinations.

**Why it is separated from screens:** If navigation logic lived inside a screen, that screen would be responsible for rendering both its own content and deciding what the rest of the app shows. Separating `AppShell` into `navigation/` makes it clear that this file owns the chrome (rail, bottom nav, background) and delegates content to feature screens. Feature screens become pure content — they do not know where they are in the navigation hierarchy.

**What belongs here:**
- The root `AppShell` widget
- Navigation rail and bottom nav bar configuration
- Page index state and switching logic
- Future: route configuration if a router library is adopted

**What does NOT belong here:**
- Screen content (that belongs in `features/`)
- Business logic
- Any stateful logic unrelated to which page is shown

---

### `lib/shared/widgets/`

**Purpose:** A library of reusable UI primitives that are not tied to any specific STEM domain or feature.

**Why it exists:** Multiple features need glass-card containers, status chips, and background styling. Duplicating these would cause drift — the dashboard glass card might look slightly different from the linked list glass card for no architectural reason. `shared/` prevents this by providing one authoritative implementation that all features use.

**When to add a file here:** A widget belongs in `shared/widgets/` when:
- It contains no domain knowledge (no mention of linked lists, atoms, gates, etc.)
- It would be useful in at least two different feature contexts
- It is configurable through parameters rather than hardcoded content

**When NOT to add a file here:** Do not add a widget to `shared/` if:
- It renders a concept specific to one STEM domain
- It holds state that only one screen needs
- It imports from any `features/` folder
- It is only used in one place

---

### `lib/features/`

**Purpose:** Contains all feature modules. Each subfolder is a self-contained feature with its own screens, widgets, and models.

**Why feature-first architecture:** Feature-first organization groups code by business purpose rather than by technical type. Instead of having a flat `widgets/` folder with hundreds of unrelated widgets, each feature's widgets live next to the screen that uses them. This makes it easy to locate all code related to a feature, and it makes deletion or replacement of a feature safe.

**Rules for feature folders:**
- A feature folder may contain: a screen file at the top level, a `widgets/` subfolder for widgets specific to that feature, and a `models/` subfolder for data classes specific to that feature.
- Feature A's screen must not import Feature B's widgets or models.
- Features that need to share data structures should do so through `shared/` or through the shell callback pattern, not through direct imports.

---

### `lib/features/dashboard/`

**Purpose:** The home screen of the application — the first thing a user sees after launch.

**Responsibilities:**
- Display the app's identity (HoloSTEM Explorer title, hero scanner widget)
- Provide the four main entry points (Start Learning, Learning Path, AR Simulation, Progress Tracker) as `NeonActionCard` widgets
- Show current system status metrics (Adaptivity, Concept Graph, AR Engine)
- Communicate navigation intent upward via the `onOpenSection` callback

**When to add files here:** Add to this folder only when building new dashboard-level content — for example, a featured topic carousel, a recent sessions strip, or a learner greeting widget.

**When NOT to add files here:** Do not put lab workspaces, feature-specific models, or shared UI primitives here.

---

### `lib/features/placeholder/`

**Purpose:** Provides a reusable, configurable placeholder screen for features that are not yet implemented.

**Why it exists:** The AR Simulation and Progress Tracker destinations need to be navigable (the nav rail shows them) but have no implementation yet. Rather than leaving empty screens or crashing, `FeaturePlaceholderScreen` provides a honest, styled holding screen. Using one parameterized widget for all placeholders ensures consistency and eliminates duplication.

**When to add files here:** This folder should remain minimal. A second file would only be warranted if placeholder behavior becomes significantly more complex (for example, a placeholder that shows a waitlist sign-up form).

**When NOT to add files here:** Do not put real feature screens here. Once a feature is implemented, its screen moves to its own feature folder and the placeholder is removed from `AppShell`.

---

### `lib/features/linked_list/`

**Purpose:** The dedicated, full-screen linked list learning experience — a standalone deep-dive workspace separate from the advanced labs shell.

**Why it has its own feature folder (and not just a widget inside `advanced_workspaces/`):** The linked list workspace is significant enough to warrant a dedicated screen with its own `Scaffold`, `CyberBackground`, floating particles layer, back button header, and responsive layout. It is a complete learning experience, not a panel inside a larger screen. Giving it its own feature folder keeps `advanced_stem_workspaces_screen.dart` from becoming even larger, and makes it independently navigable via `Navigator.push`.

**Why it has its own `models/` subfolder:** `LinkedListNodeModel` is an immutable data class with an `id`, `label`, and `position`. It is the data type that `LinkedListLearningScreen` creates, modifies, and passes to its child widgets. Placing the model inside the feature folder rather than in a global `models/` directory keeps it co-located with the code that uses it. No other feature needs this model — it is specific to the linked list concept.

**Why it has its own `widgets/` subfolder:** The linked list playground requires purpose-built widgets: a node that visually represents a data field and a pointer field side by side, an animated arrow layer drawn with `CustomPainter`, a floating particle system, a holographic explanation panel, a misconception panel, and an operation control panel. These widgets are semantically linked list widgets — they understand concepts like "head", "active traversal", and "broken connection". They do not belong in `shared/` because they are domain-specific. They are extracted into separate files (rather than kept as private classes in the screen file) because each is complex enough to deserve its own file for readability and future modification.

**When to add files here:**
- New widgets that render linked list concepts (for example, a doubly-linked list node widget, a null terminator widget)
- New models for extended linked list data (for example, a `DoublyLinkedListNodeModel`)
- A new screen for a linked list quiz or challenge mode

**When NOT to add files here:**
- Stack, binary tree, or other data structure widgets — those belong in their own feature folders
- Generic lab widgets that multiple features share — those belong in `shared/`


---

### `lib/features/advanced_workspaces/`

**Purpose:** The multi-domain interactive STEM labs shell. Contains all 11 interactive learning workspaces across Data Structures, Digital Electronics, and Organic Chemistry.

**Why everything is in one file:** At the current prototype stage, the entire labs experience — domain navigation state machine, topic grids, all lab widgets, all internal data models, all `CustomPainter` implementations — lives in `advanced_stem_workspaces_screen.dart`. This was a deliberate prototype decision: it keeps the code portable, runnable without configuration, and easy to review as a whole.

This file is acknowledged to be large (~4,000 lines). It is organized internally by domain and lab section. New developers should treat it as a monolith that is ready to be broken up into per-domain feature folders as development matures.

**How internal organization works inside the file:**

```
AdvancedStemWorkspacesScreen (StatefulWidget)
  State machine: _domainIndex → _topicIndex
  _buildCurrentStep() dispatches to:
    ├── _DomainSelectionGrid
    ├── _TopicSelectionGrid
    ├── DataStructuresWorkspace
    │     ├── _LinkedListLearningLab
    │     ├── StackLearningLab
    │     └── BinaryTreeLearningLab
    ├── DigitalElectronicsWorkspace
    │     ├── BasicLogicGatesLab
    │     ├── XorGateBuilderLab
    │     ├── ComplexGateConstructionLab
    │     └── TruthTableSimulatorLab
    └── OrganicChemistryWorkspace
          ├── HydrocarbonBuilderLab
          ├── SugarStructureBuilderLab
          ├── AlcoholFunctionalGroupsLab
          └── BondSimulatorLab
```

**When to add files here:** Currently all new lab content should be added inside `advanced_stem_workspaces_screen.dart` to maintain the existing structure. When a domain grows complex enough to warrant its own folder (typically when a domain has more than one screen or needs shared models), extract it into a new feature folder such as `lib/features/data_structures/`.

**When NOT to add files here:** Do not add shared UI primitives, theme values, or navigation logic to this folder.

---

## 6. File Reference

### `lib/main.dart`

**Purpose:** Dart application entry point.

**Responsibility:** Calls `runApp(const StemArApp())` and nothing else.

**Dependencies:** `package:flutter/material.dart`, `app.dart`

**Who uses it:** Dart VM / Flutter engine at startup. No other file imports `main.dart`.

**Rule:** Keep this file to its minimum. Any setup that is needed before `runApp` (for example, `WidgetsFlutterBinding.ensureInitialized()` for future plugin initialization) goes here, but no widget or business logic ever belongs here.

---

### `lib/app.dart`

**Purpose:** Defines the root `MaterialApp` and applies the global theme and entry screen.

**Responsibility:**
- Creates the `MaterialApp` with `title`, `theme`, and `home`
- Disables the debug banner
- Delegates the home screen to `AppShell`

**Dependencies:** `core/theme/app_theme.dart`, `navigation/app_shell.dart`

**Who uses it:** `main.dart` only.

**Rule:** This file should never contain widget layout code, feature logic, or navigation decisions. It is a configuration file for the `MaterialApp`. Route configuration (when a router is added) would go here.

---

### `lib/core/theme/app_colors.dart`

**Purpose:** The single source of truth for all colors used in the application.

**Responsibility:** Declares a set of `static const Color` values organized as a utility class (`AppColors._()` private constructor prevents instantiation).

**Color palette:**
| Name | Hex | Role |
|---|---|---|
| `backgroundTop` | `#050713` | Gradient start (near black, deep navy) |
| `backgroundBottom` | `#101024` | Gradient end |
| `surface` | `#11142A` | Card and panel backgrounds |
| `glass` | `#33FFFFFF` | Frosted glass fill (21% white alpha) |
| `cyan` | `#22F6FF` | Primary accent — interactive elements, borders |
| `pink` | `#FF3DF2` | Error / misconception detected |
| `violet` | `#8A5CFF` | Secondary accent — pointers, connections |
| `lime` | `#B8FF4D` | Success / correct state |
| `orange` | `#FFB547` | Warning / partial error |
| `textPrimary` | `#F5F8FF` | Main readable text |
| `textSecondary` | `#9DA8C7` | Supporting text, labels |

**Dependencies:** None.

**Who uses it:** Every file that renders color — `app_theme.dart`, all shared widgets, all feature screens and widgets.

---

### `lib/core/theme/app_theme.dart`

**Purpose:** Configures the Material 3 dark theme used by `MaterialApp`.

**Responsibility:**
- Returns a `ThemeData` via the `AppTheme.darkCyberpunk` static getter
- Sets `useMaterial3: true`, `brightness: Brightness.dark`
- Configures `TextTheme` (5 text styles: headlineLarge 38px/800w, headlineSmall 22px/700w, titleMedium 16px/700w, bodyLarge 16px, bodyMedium 14px)
- Configures `NavigationRailThemeData` (transparent background, cyan selected, secondary unselected)
- Configures `BottomNavigationBarThemeData` (surface background, cyan selected)

**Dependencies:** `app_colors.dart`

**Who uses it:** `app.dart` (assigns it to `MaterialApp.theme`). No widget should build its own `ThemeData` or override theme properties inline.

---

### `lib/navigation/app_shell.dart`

**Purpose:** The root application scaffold. Manages top-level navigation between the four main destinations.

**Responsibility:**
- Maintains `_selectedIndex` state (0 = Dashboard, 1 = Labs, 2 = AR, 3 = Progress)
- Renders `CyberBackground` as the full-screen backdrop
- Shows `_CyberNavigationRail` on screens ≥ 860px wide; shows `BottomNavigationBar` on narrower screens
- Uses `AnimatedSwitcher` + `KeyedSubtree` to animate between pages
- Passes `_openSection` as a callback to `DashboardScreen` so the dashboard can request navigation

**Key classes:**
- `AppShell` — root `StatefulWidget`
- `_AppShellState` — holds `_selectedIndex`, builds pages list, dispatches `_openSection`
- `_CyberNavigationRail` — glassmorphism pill-shaped `NavigationRail` (104px wide, 28px corner radius, cyan glow border)

**Dependencies:** `app_colors.dart`, `cyber_background.dart`, `dashboard_screen.dart`, `advanced_stem_workspaces_screen.dart`, `feature_placeholder_screen.dart`

**Who uses it:** `app.dart`

---

### `lib/shared/widgets/cyber_background.dart`

**Purpose:** Provides the full-screen cyberpunk atmospheric background for any screen that needs it.

**Responsibility:**
- Renders a `LinearGradient` from `backgroundTop` (top-left) through `backgroundBottom` to a deep purple (`#180D2B`) at bottom-right
- Paints a `_GridOverlay` — a `CustomPainter` that draws a 42px-spaced cyan grid (alpha 0.055)
- Places two `_SoftGlow` circles (cyan top-right, pink bottom-left) as ambient light sources — each is a 280×280px `Container` with a `BoxShadow` of `blurRadius: 160`
- Wraps the `child` widget on top of all layers

**Dependencies:** `app_colors.dart`

**Who uses it:** `app_shell.dart` (wraps the entire app body), `linked_list_learning_screen.dart` (wraps the linked list screen body)

---

### `lib/shared/widgets/glass_card.dart`

**Purpose:** A frosted glass container used as the standard panel component throughout the app.

**Responsibility:**
- Clips content to 24px border radius
- Applies `BackdropFilter` with `ImageFilter.blur(sigmaX: 18, sigmaY: 18)` for the glass effect
- Fills with `AppColors.glass` (21% white), white border (12% alpha), cyan drop shadow
- Accepts a `child` and a configurable `padding` (default 22px all sides)

**Dependencies:** `app_colors.dart`

**Who uses it:** Nearly every screen and widget — dashboard panels, linked list panels, operation controls, explanation panels, placeholder screen, lab workspaces.

**Rule:** When a panel needs a custom dark background inside a lab workspace, the `_CyberPanel` private widget in `advanced_stem_workspaces_screen.dart` wraps `GlassCard` with an additional dark `ClipRRect` child. Do not change `GlassCard` itself to support dark-interior variations — add a wrapper instead.


---

### `lib/shared/widgets/neon_action_card.dart`

**Purpose:** A hover-responsive navigation card used in the dashboard action grid.

**Responsibility:**
- Accepts `title`, `subtitle`, `icon`, `accent` (color), and `onTap`
- Uses `MouseRegion` to detect hover on desktop/web
- Uses `TweenAnimationBuilder<double>` to smoothly animate a vertical lift (`-4px`) and glow increase on hover
- Wraps a `GlassCard` with an accent-colored icon box (54×54px), title text, and subtitle text (max 2 lines)

**Dependencies:** `app_colors.dart`, `glass_card.dart`

**Who uses it:** `dashboard_screen.dart` (4 action cards in the grid)

---

### `lib/shared/widgets/pulse_orb.dart`

**Purpose:** An animated pulsing ring used as a decorative scanning visualization on the dashboard.

**Responsibility:**
- Animates a `Transform.scale` from 0.90 to 1.08 over 2200ms (reversing), creating a heartbeat-like pulse
- Accepts `color`, `size`, and `delay` (integer milliseconds to offset the phase, creating layered pulses)
- Renders a circle with a colored border and a soft glow `BoxShadow`

**Dependencies:** None (uses Flutter only — no `AppColors` dependency, color is passed as a parameter)

**Who uses it:** `dashboard_screen.dart` `_DashboardHero` scanner widget (two orbs: cyan 190px, pink 116px with 300ms delay)

---

### `lib/shared/widgets/status_chip.dart`

**Purpose:** A pill-shaped label with a lime dot indicator used as a section identifier at the top of screens.

**Responsibility:**
- Renders a horizontal `Row` with a lime `BoxDecoration` circle (8×8px) + text label
- Styled with a cyan-bordered, cyan-tinted pill background

**Dependencies:** `app_colors.dart`

**Who uses it:** `dashboard_screen.dart`, `linked_list_learning_screen.dart`, `advanced_stem_workspaces_screen.dart`

---

### `lib/features/dashboard/dashboard_screen.dart`

**Purpose:** The application home screen. Entry point for learners.

**Responsibility:**
- Receives `onOpenSection(int index)` callback from `AppShell`
- Renders a responsive layout (breakpoint at 900px width):
  - Wide: two-column hero (text left, scanner right)
  - Narrow: stacked hero
- Contains three private layout widgets: `_DashboardHero`, `_ActionGrid`, `_InsightStrip`

**Key internal widgets:**
- `_DashboardHero` — app title, subtitle, `StatusChip`, and the `PulseOrb` scanner `GlassCard`
- `_ActionGrid` — 4 `NeonActionCard` items in a `GridView` (4 columns wide, 1 column narrow); tapping "Start Learning" or "Learning Path" calls `onOpenSection(1)`; "AR Simulation" → `onOpenSection(2)`; "Progress Tracker" → `onOpenSection(3)`
- `_InsightStrip` — `GlassCard` with three `_MetricTile` items (Adaptivity/Ready, Concept Graph/UI only, AR Engine/Pending), each with a colored vertical bar

**Dependencies:** `app_colors.dart`, `glass_card.dart`, `neon_action_card.dart`, `pulse_orb.dart`, `status_chip.dart`

**Who uses it:** `app_shell.dart` (page index 0)

---

### `lib/features/placeholder/feature_placeholder_screen.dart`

**Purpose:** A configurable placeholder screen for destinations that are not yet implemented.

**Responsibility:**
- Accepts `title`, `message`, `icon`, and `accent` color
- Renders a centered `GlassCard` with a circular icon container, a title, a descriptive message, and a static disclaimer note
- Constrains width to 680px maximum

**Dependencies:** `app_colors.dart`, `glass_card.dart`

**Who uses it:** `app_shell.dart` (page index 2 for AR, page index 3 for Progress)

---

### `lib/features/linked_list/linked_list_learning_screen.dart`

**Purpose:** A dedicated full-screen immersive learning experience for the linked list data structure concept.

**Responsibility:**
- Owns the state for the entire linked list workspace: node positions, head node identity, connection state, traversal state, and feedback
- Manages a list of `LinkedListNodeModel` instances
- Implements six operations: move node (drag), insert node, delete tail node, toggle broken connection, toggle head pointer, toggle traversal order
- Runs an async traversal animation that highlights each node in sequence with a 560ms delay
- Calls `_detectMisconceptions()` after every state change to evaluate the current configuration and produce color-coded feedback

**Key internal private widgets:**
- `_LinkedListHeader` — back button, `StatusChip`, screen title, description
- `_WorkspaceColumn` — wraps `LinkedListPlayground` in a `GlassCard` with instructions
- `_LearningSidePanel` — stacks `OperationControlPanel`, `MisconceptionFeedbackPanel`, `HolographicExplanationPanel`

**Misconception rules (evaluated in `_detectMisconceptions`):**
1. Head node is `null` → pink error: "Head node missing"
2. Connection is broken → pink error: "Node linkage mismatch detected"
3. Reverse traversal is on → orange warning: "Traversal path incorrect"
4. All valid → lime success: "Great! Head and node links form a valid left-to-right path."

**Dependencies:** `app_colors.dart`, `cyber_background.dart`, `glass_card.dart`, `status_chip.dart`, `linked_list_node_model.dart`, all six widgets in `linked_list/widgets/`

**Who uses it:** Launched via `Navigator.push` from `_LinkedListLearningLab` inside `advanced_stem_workspaces_screen.dart`

---

### `lib/features/linked_list/models/linked_list_node_model.dart`

**Purpose:** Immutable data class representing a single node in the linked list playground.

**Responsibility:**
- Holds `id` (int, unique identifier), `label` (String, display character e.g. "A"), `position` (Offset, pixel coordinates in the playground)
- Provides a `copyWith` method for updating `label` or `position` while preserving immutability

**Dependencies:** `package:flutter/material.dart` (for `Offset`)

**Who uses it:** `linked_list_learning_screen.dart`, `linked_list_playground.dart`, `neon_linked_list_node.dart`

**Why it is here and not in `shared/`:** `LinkedListNodeModel` encodes a linked list concept (a node with a label and a visual position). It is not a generic data class. It belongs in the linked list feature folder because it is meaningless outside of that context.

---

### `lib/features/linked_list/widgets/floating_particles.dart`

**Purpose:** An animated ambient particle layer that adds visual depth to the linked list learning screen.

**Responsibility:**
- Renders 28 particles using `CustomPainter` (`_ParticlePainter`)
- Each particle is positioned using a sine function for x-offset and animates vertically upward over 9 seconds in a repeating loop
- Particles cycle through cyan, pink, and lime colors with opacity that increases as they rise

**Dependencies:** `dart:math`, `app_colors.dart`

**Who uses it:** `linked_list_learning_screen.dart` (placed as `Positioned.fill` behind all content)

---

### `lib/features/linked_list/widgets/holographic_explanation_panel.dart`

**Purpose:** An educational panel that explains linked list concepts in the side panel of the learning screen.

**Responsibility:**
- Renders four `_ExplanationItem` tiles (What is a linked list, How nodes connect, Head pointer concept, Traversal concept)
- Each tile animates in with a fade + right-to-left slide via `TweenAnimationBuilder` (520ms, `easeOutCubic`)
- Tiles have a cyan-bordered, glass-tinted background

**Dependencies:** `app_colors.dart`, `glass_card.dart`

**Who uses it:** `linked_list_learning_screen.dart` `_LearningSidePanel`

---

### `lib/features/linked_list/widgets/linked_list_playground.dart`

**Purpose:** The interactive canvas where the user drags and rearranges linked list nodes.

**Responsibility:**
- Renders a dark-background canvas (520px tall narrow / 470px wide) with a subtle grid
- Displays `NeonLinkedListNode` widgets at their positions, wrapped in `GestureDetector` for pan drag
- Renders the HEAD pointer label via `_HeadPointer` (an `AnimatedPositioned` label + downward arrow)
- Renders connection arrows between nodes via `AnimatedArrowLayer` (a `StatefulWidget` with a 1300ms looping `AnimationController`)
- `_ArrowPainter` draws cubic bezier curves between nodes with an animated dot traveling along them; broken connections are drawn as a disconnected line with an X cross

**Key internal classes:**
- `LinkedListPlayground` — stateless container widget
- `AnimatedArrowLayer` / `_AnimatedArrowLayerState` — owns the animation controller
- `_ArrowPainter` — `CustomPainter` for arrows, dot, and broken link X
- `_HeadPointer` — `AnimatedPositioned` HEAD label
- `_PlaygroundGrid` / `_PlaygroundGridPainter` — background grid lines

**Dependencies:** `dart:math`, `app_colors.dart`, `linked_list_node_model.dart`, `neon_linked_list_node.dart`

**Who uses it:** `linked_list_learning_screen.dart` `_WorkspaceColumn`

---

### `lib/features/linked_list/widgets/misconception_feedback_panel.dart`

**Purpose:** Displays the current misconception detection result with animated color and text transitions.

**Responsibility:**
- Accepts `message` (String) and `accent` (Color)
- Wraps an `AnimatedContainer` (border + fill color transitions on accent change) inside a `GlassCard`
- Uses `AnimatedSwitcher` to cross-fade between message strings when they change
- Always shows a `Icons.radar_rounded` icon (tinted with the accent color) and an "Adaptive Feedback" label

**Dependencies:** `app_colors.dart`, `glass_card.dart`

**Who uses it:** `linked_list_learning_screen.dart` `_LearningSidePanel`

---

### `lib/features/linked_list/widgets/neon_linked_list_node.dart`

**Purpose:** Visual representation of a single linked list node, styled as a neon holographic chip.

**Responsibility:**
- Renders a 106×76px `AnimatedContainer` with neon border glow
- Left cell: colored tinted box with the node label (font size 24, weight 900)
- Right cell: violet arrow-forward icon in a small rounded box — visually represents the "next pointer" field of the node
- Active nodes scale to 1.1× via `AnimatedScale` and get a larger glow
- Head nodes get a lime border instead of the standard accent color

**Dependencies:** `app_colors.dart`, `linked_list_node_model.dart`

**Who uses it:** `linked_list_playground.dart`

---

### `lib/features/linked_list/widgets/operation_control_panel.dart`

**Purpose:** The user control panel for executing linked list operations and toggling misconception scenarios.

**Responsibility:**
- Three `FilledButton.icon` action buttons: Insert Node (lime), Delete Tail (orange), Traverse (cyan)
- Three `SwitchListTile` toggles: Break one connection (pink), Hide head pointer (orange), Reverse traversal order (violet)
- All interaction logic is externalized — this widget is entirely stateless and accepts only `VoidCallback` parameters

**Key internal classes:**
- `OperationControlPanel` — stateless outer widget
- `_NeonOperationButton` — styled `FilledButton.icon`
- `_ToggleRow` — styled `SwitchListTile`

**Dependencies:** `app_colors.dart`, `glass_card.dart`

**Who uses it:** `linked_list_learning_screen.dart` `_LearningSidePanel`


---

### `lib/features/advanced_workspaces/advanced_stem_workspaces_screen.dart`

**Purpose:** The main interactive STEM labs screen. A two-level navigation state machine (domain → topic) that renders one of eleven interactive lab workspaces.

**Responsibility:**
- Maintains `_domainIndex` and `_topicIndex` state to track the user's position in the domain → topic hierarchy
- Renders a domain selection grid, then a topic selection grid, then the appropriate lab workspace using `AnimatedSwitcher` for smooth transitions
- Owns all three domain workspace dispatcher widgets: `DataStructuresWorkspace`, `DigitalElectronicsWorkspace`, `OrganicChemistryWorkspace`
- Contains all 11 interactive lab widgets, all their private state classes, all their `CustomPainter` implementations, all their drag-and-drop logic, and all their rule-based misconception feedback methods

**Three Domains and Their Labs:**

| Domain | Accent | Topics |
|---|---|---|
| Data Structures | cyan | Linked List, Stack, Binary Tree |
| Digital Electronics | violet | Basic Logic Gates, XOR Gate Builder, Complex Gate Construction, Truth Table Simulator |
| Organic Chemistry | lime | Hydrocarbon Builder, Sugar Structure Builder, Alcohol & Functional Groups, Bond Simulator |

**Data Structures Labs:**

`_LinkedListLearningLab` — add/remove head nodes, drag nodes, toggle broken links, HEAD pointer label. Uses `_LinkedListBoard` (DragTarget + `_LinkedListPainter` CustomPainter).

`StackLearningLab` — PUSH/POP/TOP simulation with capacity 5. Drag-and-drop values from palette. Detects overflow (push beyond capacity), underflow (pop empty stack), and TOP mismatch. Uses `_StackBoard` (DragTarget with animated slot cells and `_PointerLabel`).

`BinaryTreeLearningLab` — drag-position nodes, animate inorder/preorder/postorder traversal sequences, toggle bad hierarchy, toggle wrong traversal order. Uses `_TreeBoard` (DragTarget + `_TreePainter`).

**Digital Electronics Labs:**

`BasicLogicGatesLab` — drag AND/OR/NOT gates, tap-to-connect them, toggle A/B inputs. Feedback checks for empty board, disconnected gates, and valid network.

`XorGateBuilderLab` — same board mechanics as basic gates, but evaluates whether the user has used AND + OR + NOT together (the primitive gate decomposition of XOR).

`ComplexGateConstructionLab` — drag NAND/NOR/XNOR gates, same board mechanics.

`TruthTableSimulatorLab` — full gate board with all 7 gate types (AND, OR, NOT, NAND, NOR, XOR, XNOR), `_BinaryToggle` inputs A and B, computed output, and a `_TruthTable` widget showing the complete truth table for the last placed gate.

All four labs share `_LogicCircuitBoard` (DragTarget + `_CircuitPainter` which draws animated signal lines from inputs through gates to output) and `_GateNodeWidget`.

**Organic Chemistry Labs:**

All four labs (`HydrocarbonBuilderLab`, `SugarStructureBuilderLab`, `AlcoholFunctionalGroupsLab`, `BondSimulatorLab`) share the same architecture:
- `_MoleculeBoard` (DragTarget + `_MoleculePainter` which draws bond lines with an animated dot)
- `_AtomBubble` for draggable/selectable atom rendering
- Tap-first-then-tap-second selection model for creating bonds
- `_detectValency()` rule: checks each atom's bond count against its maximum valency (C=4, H=1, O=2, N=3, Cl=1) and produces pink (invalid), orange (hydrogen mismatch), or lime (valid) feedback
- Bond order control (single/double/triple) via `_MiniTab` chips
- Example structure loaders (Methane, Ethene, Ethyne, Alcohol for hydrocarbons; Glucose, Sucrose for sugars; Ethanol, Amine for functional groups)

**Shared private infrastructure inside this file:**

| Class | Role |
|---|---|
| `_ResponsiveLabShell` | Splits workspace (flex 7) and side panel (flex 4) at ≥980px; stacks vertically on narrow |
| `_CyberPanel` | `GlassCard` with title, subtitle, and a dark inner `ClipRRect` child container |
| `_FeedbackPanel` | Icon + colored bold text feedback row inside a `GlassCard` |
| `_ExplanationPanel` | Bullet-point concept list with cyan "01" prefixes |
| `_GlowButton` | `FilledButton.icon` with accent tint and border |
| `_DragChip` | Draggable value chip for Stack lab |
| `_GateChip` | Draggable gate label chip for electronics labs |
| `_AtomChip` | Circular draggable atom chip for chemistry labs |
| `_BinaryToggle` | 1/0 tap toggle for circuit inputs |
| `_MiniTab` | `ActionChip` for bond order or mode selection |
| `_TruthRow` | Single row in a truth table |
| `_SignalPad` | Circular signal indicator (A, B, OUT) on the circuit board |
| `_PointerLabel` | Arrow + label badge (HEAD, TOP pointers) |
| `_NeonGrid` | `CustomPainter` background grid for all lab boards |
| `_TreeNodeBubble`, `_GateNodeWidget`, `_AtomBubble`, `_LinkedListNodeBubble` | Domain-specific node renderers |
| `_atomColor(String)` | Maps atom symbol to accent color |

**Data model classes private to this file:**

| Class | Fields |
|---|---|
| `_LearningDomain` | `title`, `subtitle`, `icon`, `accent`, `topics` |
| `_LearningTopic` | `title`, `subtitle`, `icon` |
| `_TreeNode` | `label`, `position` |
| `_GateNode` | `type`, `position` |
| `_GateConnection` | `from` (index), `to` (index) |
| `_Bond` | `a` (atom index), `b` (atom index), `order` (1/2/3) |
| `_AtomNode` | `symbol`, `position` |
| `_LinkedListNode` | `label`, `position` |

**Dependencies:** `dart:math`, `app_colors.dart`, `glass_card.dart`, `status_chip.dart`

**Who uses it:** `app_shell.dart` (page index 1)


---

## 7. Shared vs Feature Widgets

Understanding when a widget belongs in `shared/widgets/` vs inside a feature folder is one of the most important architectural decisions in this codebase. The rule is:

**Put a widget in `shared/widgets/` if and only if:**
1. It contains zero domain knowledge (no understanding of linked lists, atoms, logic gates, or any STEM concept)
2. It is — or will realistically be — used in more than one feature
3. Its behavior is fully controlled by parameters

**Put a widget in a feature's `widgets/` folder if:**
1. It renders a domain concept (a node with a pointer field, an atom bubble, a gate chip)
2. Its structure assumes the context of a specific feature
3. It would be confusing or misleading outside that feature

**Examples:**

| Widget | Location | Reason |
|---|---|---|
| `GlassCard` | `shared/widgets/` | Generic frosted container; used in dashboard, linked list, labs, placeholder |
| `StatusChip` | `shared/widgets/` | Generic label; used in dashboard, linked list, and labs headers |
| `NeonActionCard` | `shared/widgets/` | Generic hover card; configurable by any feature |
| `PulseOrb` | `shared/widgets/` | Generic animated ring; used in dashboard, could be used in future AR screen |
| `CyberBackground` | `shared/widgets/` | Generic background; used by app shell and linked list screen |
| `NeonLinkedListNode` | `linked_list/widgets/` | Renders a node with a "data" cell and a "next pointer" cell — specific to linked list concept |
| `OperationControlPanel` | `linked_list/widgets/` | Has toggles for "Hide head pointer" and "Break connection" — linked list concepts |
| `HolographicExplanationPanel` | `linked_list/widgets/` | Content is hardcoded linked list explanations |
| `FloatingParticles` | `linked_list/widgets/` | Decorative — but placed here because it was built for and is only used in the linked list screen |
| `LinkedListPlayground` | `linked_list/widgets/` | Renders arrows, HEAD pointer, and draggable nodes — entirely linked list specific |

**The `_CyberPanel`, `_FeedbackPanel`, and `_ExplanationPanel` question:**

These three private classes inside `advanced_stem_workspaces_screen.dart` are general-purpose layout widgets — they do not contain domain knowledge. They are currently private to that file because they were built alongside the labs. As the codebase grows, they are candidates for promotion to `shared/widgets/`. When a second screen outside `advanced_workspaces/` needs them, move them to `shared/` at that point.

---

## 8. Misconception Detection System

The prototype implements a rule-based misconception detection system. Each lab has its own `_detect*()` method that evaluates the current widget state and produces a feedback string and accent color. This is the precursor to the planned AI-driven misconception engine.

### How it works

Every interactive state change in a lab ends with a call to the lab's detection method. That method reads the current state variables, applies a ranked set of conditional rules, and calls `setState` to update the feedback message and color.

### Color semantics

| Color | Meaning |
|---|---|
| Pink (`AppColors.pink`) | Hard error — the configuration is definitively wrong (missing head, broken link, invalid valency) |
| Orange (`AppColors.orange`) | Soft warning — the configuration may indicate a misunderstanding (reversed traversal, TOP mismatch, hydrogen mismatch) |
| Cyan (`AppColors.cyan`) | Neutral / in-progress — traversal is running, waiting for input |
| Lime (`AppColors.lime`) | Correct — the configuration is valid |

### Rule examples by lab

**Linked List (dedicated screen):**
```
if (headNodeId == null)          → pink:  "Head node missing"
if (connectionBroken)            → pink:  "Node linkage mismatch detected"
if (reverseTraversal)            → orange: "Traversal path incorrect"
else                             → lime:  "Valid left-to-right path"
```

**Stack:**
```
if (items.length >= capacity on push) → pink:   "Stack overflow condition detected"
if (items.isEmpty on pop)             → pink:   "Invalid POP operation"
if (topMismatch toggled)              → orange: "TOP pointer mismatch"
else                                  → lime:   "PUSH/POP complete"
```

**Organic Chemistry (valency check):**
```
if any atom's bond count > its maximum valency  → pink:   "Invalid valency detected"
if any H atom's bond count ≠ 1                  → orange: "Hydrogen count mismatch"
else                                            → lime:   "Structure consistency looks stable"
```

### Future replacement path

When the AI misconception engine is ready, replace the body of each `_detect*()` method with an API call or a local model inference call. The surrounding widget structure, feedback display, and color semantics do not need to change.

---

## 9. Responsive Layout Strategy

The app uses `LayoutBuilder` throughout to respond to available width. There is no fixed global breakpoint constant — each layer defines its own threshold appropriate to its content.

| Screen / Widget | Breakpoint | Narrow behavior | Wide behavior |
|---|---|---|---|
| `AppShell` | 860px | `BottomNavigationBar` | `_CyberNavigationRail` (left side, 104px) |
| `DashboardScreen` hero | 900px | Stacked column | Side-by-side row (hero text 60%, scanner 40%) |
| `DashboardScreen` grid | 900px | 1-column `GridView` | 4-column `GridView` |
| `LinkedListLearningScreen` | 1040px | Stacked column | Side-by-side row (workspace 70%, panel 30%) |
| `_ResponsiveLabShell` (all labs) | 980px | Stacked column | Side-by-side row (workspace flex 7, side flex 4) |
| `AdvancedStemWorkspacesScreen` | 960px | 1-column grid | 3-column domain grid |

The app renders correctly on narrow mobile screens, tablet widths, and wide desktop windows without any separate layout files.


---

## 10. Future Folder Expansion

As the platform grows beyond a UI prototype, new feature folders will be introduced. Each one is described below with its purpose, its location rationale, and what it should contain.

---

### `lib/features/auth/`

**What it is:** User authentication — login, registration, password reset, session tokens.

**Why it belongs here:** Authentication is a standalone feature domain. It has its own screens (login screen, register screen), its own models (user credentials, auth tokens), and its own service layer (API calls to an auth endpoint). It does not belong in `navigation/` because navigation concerns routing, not identity.

**Expected contents:**
```
lib/features/auth/
  ├── login_screen.dart
  ├── register_screen.dart
  ├── models/
  │   └── auth_user_model.dart
  └── services/
      └── auth_service.dart
```

**Integration point:** `AppShell` would check auth state before rendering the main navigation. Unauthenticated users would be redirected to `LoginScreen`.

---

### `lib/features/progress/`

**What it is:** The learner progress tracker — topic mastery, session history, misconception frequency visualization.

**Why it belongs here:** Progress is a feature that aggregates data from multiple sessions and domains. It is not a lab workspace and not a navigation concern. It replaces the current `FeaturePlaceholderScreen` at index 3 in `AppShell`.

**Expected contents:**
```
lib/features/progress/
  ├── progress_screen.dart
  ├── widgets/
  │   ├── mastery_chart.dart
  │   └── session_history_list.dart
  └── models/
      └── learner_progress_model.dart
```

**Integration point:** `AppShell` replaces `FeaturePlaceholderScreen` (index 3) with `ProgressScreen`.

---

### `lib/features/analytics/`

**What it is:** The data collection and event logging layer — tracking which operations a learner performs, which misconceptions are detected, how long they spend in each workspace.

**Why it belongs here:** Analytics is a cross-cutting feature but should be isolated in its own folder rather than scattered throughout the codebase. It should expose a simple API (e.g., `AnalyticsService.logEvent(event)`) that other features call.

**Expected contents:**
```
lib/features/analytics/
  ├── analytics_service.dart
  └── models/
      └── learning_event_model.dart
```

**Integration point:** Lab detection methods (`_detectMisconceptions`, `_detectValency`, etc.) would call `AnalyticsService.logEvent` after producing feedback. No widget structure changes are needed.

---

### `lib/features/ai/`

**What it is:** The AI-driven misconception inference engine that replaces the current rule-based detection logic.

**Why it belongs here:** The AI engine is a domain feature — it consumes learner state and produces diagnostic output. Keeping it in its own folder isolates the ML/AI integration from the UI widgets. Lab widgets would depend on an `AiMisconceptionService` interface, not on the concrete implementation.

**Expected contents:**
```
lib/features/ai/
  ├── misconception_service.dart    (interface / abstract class)
  ├── rule_based_service.dart       (current logic extracted here)
  └── api_inference_service.dart    (future: calls AI backend endpoint)
```

**Integration point:** Each lab's `_detect*()` method becomes a call to `MisconceptionService.evaluate(labState)`. Swapping `RuleBasedService` for `ApiInferenceService` requires no changes in the lab widgets.

---

### `lib/features/session/`

**What it is:** Session management — starting a learning session, tracking active time, pausing and resuming, syncing state to a backend when connectivity is available.

**Why it belongs here:** A session is a concept that spans multiple labs and needs its own lifecycle management. It is not the same as navigation state (which page is shown) and not the same as progress data (aggregated history). It is the active working context of a learner right now.

**Expected contents:**
```
lib/features/session/
  ├── session_manager.dart
  └── models/
      └── session_model.dart
```

**Integration point:** `AppShell` or individual lab screens call `SessionManager.start()` / `SessionManager.pause()`. Session events feed into `analytics/`.

---

### `lib/features/topic/`

**What it is:** A structured curriculum browser — topics organized by domain, with prerequisite relationships, difficulty levels, and completion status.

**Why it belongs here:** The current `AdvancedStemWorkspacesScreen` hardcodes domain and topic lists as `_LearningDomain` and `_LearningTopic` private constants. As the curriculum grows, this data should live in a proper model layer, potentially fetched from a backend. The `topic/` feature folder would own this model and the screens to navigate it.

**Expected contents:**
```
lib/features/topic/
  ├── topic_browser_screen.dart
  ├── models/
  │   ├── topic_model.dart
  │   └── domain_model.dart
  └── services/
      └── curriculum_service.dart
```

**Integration point:** `AdvancedStemWorkspacesScreen` would source its domain/topic data from `CurriculumService` instead of hardcoded constants.

---

### When to split `advanced_stem_workspaces_screen.dart`

The current monolith is a pragmatic prototype decision. The threshold for splitting it is when either:
1. A domain needs a second screen (e.g., a lab quiz screen or a lab settings screen), or
2. A domain's widgets need to be shared with another feature

When that happens, extract each domain into its own feature folder:

```
lib/features/data_structures/
  ├── data_structures_screen.dart
  └── labs/
      ├── linked_list_lab.dart
      ├── stack_lab.dart
      └── binary_tree_lab.dart

lib/features/digital_electronics/
  ├── digital_electronics_screen.dart
  └── labs/
      ├── basic_gates_lab.dart
      ├── xor_gate_lab.dart
      ├── complex_gates_lab.dart
      └── truth_table_lab.dart

lib/features/organic_chemistry/
  ├── organic_chemistry_screen.dart
  └── labs/
      ├── hydrocarbon_lab.dart
      ├── sugar_structure_lab.dart
      ├── alcohol_groups_lab.dart
      └── bond_simulator_lab.dart
```

Private model classes (`_GateNode`, `_Bond`, `_AtomNode`, etc.) would move to `models/` subfolders within each feature.

---

*End of ARCHITECTURE.md*
