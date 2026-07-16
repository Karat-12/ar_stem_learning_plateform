# HoloSTEM Explorer — AR STEM Learning Platform

A Flutter UI-first prototype for a **Domain-Independent Adaptive AR-Based Misconception Detection Framework for STEM Education**.

HoloSTEM Explorer is an interactive learning cockpit that lets students build, manipulate, and test concepts across Data Structures, Digital Electronics, and Organic Chemistry through hands-on drag-and-drop labs with real-time adaptive feedback. The visual identity is a dark cyberpunk glassmorphism design system built entirely with Flutter's native rendering pipeline.

---

## Features

### Implemented

| Feature | Status |
|---|---|
| Responsive dashboard with navigation cards and status metrics | Complete |
| Advanced STEM Labs shell with domain and topic navigation | Complete |
| Linked List workspace (dedicated screen) — drag nodes, head pointer, traversal, misconception detection | Complete |
| Linked List workspace (inline in labs) — add/remove head, break links | Complete |
| Stack workspace — PUSH/POP/TOP, overflow/underflow, drag-and-drop values | Complete |
| Binary Tree workspace — node placement, inorder/preorder/postorder traversal simulation | Complete |
| Basic Logic Gates workspace — AND/OR/NOT, gate placement and connections | Complete |
| XOR Gate Builder — build XOR from AND/OR/NOT primitives | Complete |
| Complex Gate Construction — NAND/NOR/XNOR exploration | Complete |
| Truth Table Simulator — gate board, input toggles, truth table display | Complete |
| Hydrocarbon Builder — place C/H atoms, single/double/triple bonds, load Methane/Ethene/Ethyne | Complete |
| Sugar Structure Builder — glucose/sucrose templates, valency validation | Complete |
| Alcohol & Functional Groups — OH/N attachments, ethanol/amine examples | Complete |
| Bond Simulator — interactive bond order exploration with valency checking | Complete |
| Rule-based adaptive misconception feedback in all workspaces | Complete |
| Cyberpunk glassmorphism design system (AppColors, AppTheme, GlassCard) | Complete |
| Responsive layout: NavigationRail (wide) / BottomNavigationBar (narrow) | Complete |
| AR Simulation placeholder screen | Placeholder |
| Progress Tracker placeholder screen | Placeholder |

### Not Yet Implemented

- AR camera integration and 3D scene anchoring
- Persistent learner analytics and progress storage
- Backend API integration
- Authentication and user sessions
- Adaptive curriculum sequencing
- Domain-independent misconception engine
- Concept Board feature

---

## Technology Stack

| Layer | Technology |
|---|---|
| Language | Dart 3 (SDK `^3.11.5`) |
| Framework | Flutter (Material 3, dark theme) |
| State management | Local `StatefulWidget` + `setState` (no external library) |
| Navigation | Index-based shell navigation + `Navigator.push` for standalone screens |
| Animation | Flutter's native `AnimationController`, `TweenAnimationBuilder`, `AnimatedSwitcher`, `CustomPainter` |
| UI style | Cyberpunk glassmorphism — `BackdropFilter`, `BoxShadow`, neon accents |
| Persistence | None (UI prototype only) |
| Backend | None (UI prototype only) |
| Dependencies | `cupertino_icons ^1.0.8` (only external package) |

---

## Current Implementation Status

This is a **UI-first prototype**. The interactive learning mechanics, rule-based feedback panels, and all three STEM domains are fully functional at the UI level. There is no backend, no user accounts, no persistent storage, and no AR camera integration. Every screen renders, every lab is interactive, and the misconception detection system produces contextual feedback — all driven by local widget state.

The codebase is intentionally kept minimal. There is no state management library, no routing library, and no dependency injection framework. This keeps the prototype easy to run, modify, and hand off while the full architecture is designed.

---

## Folder Overview

```
frontend/
├── lib/                        # All Dart source code
│   ├── main.dart               # Application entry point
│   ├── app.dart                # Root MaterialApp widget
│   ├── core/                   # App-wide foundation (theme, constants)
│   │   └── theme/
│   │       ├── app_colors.dart # All color constants
│   │       └── app_theme.dart  # ThemeData configuration
│   ├── navigation/             # Shell and routing structure
│   │   └── app_shell.dart      # Root scaffold with nav rail / bottom nav
│   ├── shared/                 # Reusable cross-feature widgets
│   │   └── widgets/
│   │       ├── cyber_background.dart   # Full-screen gradient + grid + glows
│   │       ├── glass_card.dart         # Frosted glass card container
│   │       ├── neon_action_card.dart   # Hover-animated navigation card
│   │       ├── pulse_orb.dart          # Pulsing animated ring widget
│   │       └── status_chip.dart        # Pill-shaped label with dot indicator
│   └── features/               # Feature-first screen and widget modules
│       ├── dashboard/
│       │   └── dashboard_screen.dart
│       ├── advanced_workspaces/
│       │   └── advanced_stem_workspaces_screen.dart
│       ├── linked_list/
│       │   ├── linked_list_learning_screen.dart
│       │   ├── models/
│       │   │   └── linked_list_node_model.dart
│       │   └── widgets/
│       │       ├── floating_particles.dart
│       │       ├── holographic_explanation_panel.dart
│       │       ├── linked_list_playground.dart
│       │       ├── misconception_feedback_panel.dart
│       │       ├── neon_linked_list_node.dart
│       │       └── operation_control_panel.dart
│       └── placeholder/
│           └── feature_placeholder_screen.dart
├── android/                    # Android platform project
├── windows/                    # Windows platform project
├── pubspec.yaml                # Package manifest
└── analysis_options.yaml       # Dart lint rules
```

---

## How to Run the Project

**Prerequisites:**
- Flutter SDK installed and on your `PATH`
- A connected device, emulator, or desktop target enabled

**Install dependencies:**

```bash
flutter pub get
```

**Run on your default device:**

```bash
flutter run
```

**Run on a specific target:**

```bash
# Windows desktop
flutter run -d windows

# Chrome (web)
flutter run -d chrome

# Android emulator
flutter run -d emulator-5554
```

**Check available devices:**

```bash
flutter devices
```

The app targets Flutter stable. No additional setup, no environment variables, and no backend services are required to run the prototype.

---

## Future Roadmap

The following areas are planned for upcoming development phases:

| Area | Description |
|---|---|
| `lib/features/auth/` | User authentication — login, registration, session handling |
| `lib/features/progress/` | Learner analytics dashboard — misconception history, topic mastery, session summaries |
| `lib/features/analytics/` | Backend-connected data layer for tracking events and learning outcomes |
| `lib/features/ai/` | AI-driven misconception inference engine to replace the current rule-based checks |
| `lib/features/session/` | Session management — track active learning sessions, resume state, sync to backend |
| `lib/features/topic/` | Topic browser — structured curriculum map, prerequisites, difficulty levels |
| AR Integration | Camera access, 3D anchoring, spatial overlays on physical objects |
| State Management | Introduce a state management solution (Provider, Riverpod, or Bloc) as complexity grows |
| Backend API | Connect to a REST or GraphQL backend for persistence and personalization |
| Testing | Unit tests for rule-based feedback logic, widget tests for core UI components |
