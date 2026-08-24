# HoloSTEM Explorer — AR STEM Learning Platform

> **Documentation status:** Updated to reflect the actual current implementation.
> Code is the source of truth.

A Flutter application for a **Domain-Independent Adaptive Misconception Detection Framework for STEM Education**.

HoloSTEM Explorer lets students build, manipulate, and test STEM concepts through hands-on drag-and-drop labs with real-time rule-based adaptive feedback. It integrates with a Spring Boot backend for persistent learning analytics, misconception tracking, and an AI Coach that generates personalized study plans and recommendations.

---

## Implementation Status

### Implemented and Working

| Feature | Notes |
|---|---|
| JWT authentication (login + registration) | Full auth flow with secure token storage and session restoration |
| Dark cyberpunk glassmorphism design system | `AppColors`, `AppTheme`, `GlassCard`, `CyberBackground` |
| Responsive navigation shell | `NavigationRail` (≥860px) + `BottomNavigationBar` (narrow) |
| Dashboard with action grid | 5 action cards including direct launch to assessment |
| Advanced STEM Labs shell | Domain → topic → workspace hierarchy with `AnimatedSwitcher` |
| Linked List free-exploration workspace | Drag nodes, head pointer, traversal, toggle broken connection |
| Linked List task-based curriculum | 3 guided construction tasks (`LinkedListConstructionScreen`) |
| Linked List 3-challenge scored assessment | Build/Repair/Traverse challenges, misconception-mapped validation |
| Stack workspace | PUSH/POP/TOP with overflow/underflow detection |
| Binary Tree workspace | Node placement, inorder/preorder/postorder traversal |
| Basic Logic Gates lab | AND/OR/NOT gate placement and connections |
| XOR Gate Builder | Build XOR from primitive gates |
| Complex Gate Construction | NAND/NOR/XNOR exploration |
| Truth Table Simulator | Gate board with input toggles and truth table display |
| Hydrocarbon Builder | C/H/O/N/Cl atoms, bond orders, valency validation |
| Sugar Structure Builder | Glucose/sucrose templates, valency validation |
| Alcohol & Functional Groups lab | Ethanol/amine structures |
| Bond Simulator | Interactive bond order exploration |
| Rule-based misconception detection | All workspaces detect and report misconceptions in real time |
| Session lifecycle tracking | Start/end per workspace, synced to backend |
| Misconception recording | Local detection → `POST /api/v1/misconceptions` |
| Progress screen | Topic mastery, sessions, misconception counts, weak areas |
| AI Coach screen | 5-panel adaptive report (mastery ring, insights, recommendations, revision, study plan) |
| AR screen | Live camera preview + Flutter-canvas linked list scene overlay |
| Assessment → AI Coach feedback loop | Submission triggers AI Coach cache refresh |
| Targeted practice from AI Coach | `LinkedListConstructionScreen(initialTaskId: ...)` |

### Partially Implemented

| Feature | Notes |
|---|---|
| AR spatial interaction | Camera live feed works; scene is Flutter canvas overlay — no ARCore/ARKit spatial anchoring |
| Topic catalog browser | `lib/features/topic/` directory exists with subdirectories, no Dart files |
| Token refresh / automatic re-login | Access token only; no refresh token flow |

### Not Implemented

- ARCore / ARKit spatial anchoring
- True 3D rendering (Unity or native AR SDKs)
- Generative AI / LLM integration (backend AI is fully rule-based)
- User profile editing screen
- Server-side logout / token revocation

---

## Technology Stack

| Layer | Technology | Version |
|---|---|---|
| Language | Dart | SDK `^3.11.5` |
| Framework | Flutter | Stable (Material 3) |
| State management | Provider (`ChangeNotifier`) | `^6.1.0` |
| HTTP client | Dio | `^5.4.0` |
| Secure storage | flutter_secure_storage | `^9.2.0` |
| Local storage | shared_preferences | `^2.2.2` |
| Camera | camera | `^0.12.0+2` |
| Icons | cupertino_icons | `^1.0.8` |
| Animation | Flutter native (`AnimationController`, `TweenAnimationBuilder`, `CustomPainter`) | — |
| UI style | Cyberpunk glassmorphism (`BackdropFilter`, `BoxShadow`, neon accents) | — |

---

## Folder Structure

```
frontend/
├── lib/
│   ├── main.dart                         # Entry point — service wiring, Provider setup, session restore
│   ├── app.dart                          # Root MaterialApp — auth-gate routing
│   │
│   ├── core/                             # App-wide foundation
│   │   ├── config/
│   │   │   └── api_constants.dart        # Base URL, endpoint paths, storage keys, timeouts
│   │   ├── network/
│   │   │   ├── api_client.dart           # Dio wrapper with auth interceptor
│   │   │   └── api_exception.dart        # Typed exception with status codes
│   │   ├── storage/
│   │   │   └── secure_storage_service.dart  # JWT storage (flutter_secure_storage)
│   │   └── theme/
│   │       ├── app_colors.dart           # All color constants (single source of truth)
│   │       └── app_theme.dart            # ThemeData — Material 3 dark cyberpunk
│   │
│   ├── navigation/
│   │   └── app_shell.dart                # Root scaffold, rail/bottom nav, logout, 4 pages
│   │
│   ├── shared/
│   │   └── widgets/
│   │       ├── cyber_background.dart     # Full-screen gradient + grid + ambient glows
│   │       ├── glass_card.dart           # Frosted glass container (BackdropFilter blur 18)
│   │       ├── neon_action_card.dart     # Hover-animated card with icon, title, subtitle
│   │       ├── pulse_orb.dart            # Animated pulsing ring
│   │       └── status_chip.dart          # Pill-shaped label with lime dot indicator
│   │
│   └── features/
│       ├── auth/
│       │   ├── models/                   # LoginRequest, LoginResponse, CurrentUser,
│       │   │                             #   RegisterRequest, index.dart
│       │   ├── services/
│       │   │   └── auth_service.dart     # login, register, getCurrentUser, restoreSession, logout
│       │   ├── providers/
│       │   │   └── auth_provider.dart    # AuthState enum, ChangeNotifier
│       │   └── screens/
│       │       ├── login_screen.dart     # JWT login with cyberpunk UI
│       │       └── register_screen.dart  # Registration with client-side validation
│       │
│       ├── dashboard/
│       │   └── dashboard_screen.dart     # Hero, 5 action cards, insight strip
│       │
│       ├── advanced_workspaces/
│       │   └── advanced_stem_workspaces_screen.dart  # All 11 STEM labs (~4000 lines)
│       │
│       ├── linked_list/
│       │   ├── linked_list_learning_screen.dart      # Free-exploration workspace
│       │   ├── linked_list_construction_screen.dart  # Task-based curriculum (3 tasks)
│       │   ├── models/
│       │   │   ├── linked_list_node_model.dart       # Visual node (id, label, Offset)
│       │   │   ├── linked_list_task.dart             # Task definition + kLinkedListTasks
│       │   │   ├── linked_list_workspace_state.dart  # Immutable workspace state
│       │   │   └── linked_list_misconception_map.dart # Code → task recommendations
│       │   └── widgets/
│       │       ├── linked_list_playground.dart       # Shared canvas (arrows, head pointer)
│       │       ├── floating_particles.dart           # Ambient particle layer
│       │       ├── holographic_explanation_panel.dart # 4 explanation tiles
│       │       ├── misconception_feedback_panel.dart # Animated feedback display
│       │       ├── neon_linked_list_node.dart        # Node chip (data + pointer cells)
│       │       ├── node_palette.dart                 # Draggable node source palette
│       │       └── operation_control_panel.dart      # Buttons + toggles
│       │
│       ├── assessments/
│       │   ├── shared/
│       │   │   ├── assessment_challenge_result.dart  # passed, score, feedback
│       │   │   └── assessment_result_model.dart      # Challenge results + total score
│       │   └── linked_list_assessment/
│       │       ├── models/
│       │       │   ├── linked_list_graph.dart        # Pure Dart logical graph model
│       │       │   ├── validation_result.dart        # isValid, hint, misconceptionCode
│       │       │   ├── challenge_definition.dart     # ChallengeDefinition + interaction modes
│       │       │   ├── linked_list_assessment_challenge.dart  # Metadata DTO
│       │       │   └── linked_list_assessment_state.dart      # Immutable assessment state
│       │       ├── services/
│       │       │   └── linked_list_assessment_service.dart  # Pure validators, 3 challenges
│       │       ├── screens/
│       │       │   ├── linked_list_assessment_screen.dart   # 3-challenge assessment screen
│       │       │   └── linked_list_assessment_result_screen.dart  # Standalone result view
│       │       └── widgets/
│       │           ├── assessment_progress_header.dart      # Progress bar + challenge number
│       │           ├── assessment_result_card.dart          # Pass/fail per challenge
│       │           └── challenge_instruction_card.dart      # Challenge title + description
│       │
│       ├── sessions/
│       │   ├── models/
│       │   │   ├── session_response.dart             # API response model
│       │   │   └── start_session_request.dart        # API request model
│       │   ├── services/
│       │   │   └── session_service.dart              # startSession, endSession
│       │   └── providers/
│       │       └── session_provider.dart             # Active session state
│       │
│       ├── misconceptions/
│       │   ├── models/
│       │   │   └── record_misconception_request.dart # API request model
│       │   └── services/
│       │       └── misconception_service.dart        # recordMisconception (POST)
│       │
│       ├── progress/
│       │   ├── models/
│       │   │   └── progress_response.dart            # API response model
│       │   ├── services/
│       │   │   └── progress_service.dart             # getMyProgress, getTopicProgress
│       │   ├── providers/
│       │   │   └── progress_provider.dart            # Progress list + loading state
│       │   └── screens/
│       │       └── progress_screen.dart              # RefreshIndicator + topic cards
│       │
│       ├── ai_coach/
│       │   ├── models/
│       │   │   ├── ai_coach_report.dart              # Composed 5-source report
│       │   │   ├── ai_insights_response.dart
│       │   │   ├── ai_recommendation_response.dart
│       │   │   ├── ai_revision_response.dart
│       │   │   ├── ai_study_plan_response.dart
│       │   │   └── analytics_topic_response.dart
│       │   ├── services/
│       │   │   └── ai_coach_service.dart             # fetchReport (5 parallel GET calls)
│       │   ├── providers/
│       │   │   └── ai_coach_provider.dart            # Per-topic report cache
│       │   ├── screens/
│       │   │   └── ai_coach_screen.dart              # 8-section adaptive report screen
│       │   ├── widgets/
│       │   │   ├── coach_section_card.dart           # Glass card with accent border
│       │   │   └── mastery_score_ring.dart           # Animated circular progress ring
│       │   └── utils/
│       │       └── topic_labels.dart                 # Code → human-readable label mappings
│       │
│       ├── ar/
│       │   └── screens/
│       │       └── ar_linked_list_screen.dart        # Camera preview + Flutter scene overlay
│       │
│       ├── topic/                        # EMPTY — directory structure created, no files
│       │
│       └── placeholder/
│           └── feature_placeholder_screen.dart       # Generic placeholder (not currently used)
│
├── android/                              # Android platform project
├── windows/                              # Windows platform project
├── ios/                                  # iOS platform project
├── pubspec.yaml                          # Package manifest (version 1.0.0+1)
└── analysis_options.yaml                 # Dart lint rules (flutter_lints ^6.0.0)
```

---

## How to Run

**Prerequisites:**
- Flutter SDK installed and on your `PATH`
- Backend running (see `backend/echo.md` for environment variable setup)

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
flutter run -d windows   # Windows desktop
flutter run -d chrome    # Chrome (web)
flutter run -d emulator-5554  # Android emulator
```

**Check available devices:**
```bash
flutter devices
```

### Backend connection

The base URL is configured in `lib/core/config/api_constants.dart`:

```dart
static const String baseUrl = 'http://192.168.1.5:8080';
```

This is set to a LAN IP for testing on a physical Android device. Change it to:
- `http://localhost:8080` for Windows/macOS desktop
- `http://10.0.2.2:8080` for Android emulator

---

## Key Architecture Decisions

### State Management: Provider

`ChangeNotifier`-based providers with constructor-injected services. No Riverpod, Bloc, or GetX. Services are plain Dart classes. Provider instances are created in `main.dart` and injected via `MultiProvider`.

### Visual / Logical Separation

The Linked List workspace and assessment maintain two separate state layers:
- `List<LinkedListNodeModel>` — screen positions (visual layer)
- `LinkedListGraph` — logical structure with head pointer and next-pointer map

Validators only operate on `LinkedListGraph`. Rendering reads both layers.

### Misconception Pipeline

```
Local rule check in workspace
    ↓
MisconceptionService.recordMisconception() → POST /api/v1/misconceptions
    ↓
ProgressProvider.loadProgress() → GET /api/v1/progress/me
```

Deduplication is performed client-side: once a specific misconception code has been recorded for the current session, it is not sent again.

### Assessment → AI Coach Loop

After submitting the Linked List Assessment:
1. `POST /api/v1/quizzes/submit` stores the score
2. `POST /api/v1/sessions/{id}/end` closes the session
3. `AiCoachProvider.refresh('DSA_LINKED_LIST')` is called fire-and-forget
4. The result screen offers "Open AI Coach" which reads the now-refreshed report

### AR Implementation Note

The AR tab (`ArLinkedListScreen`) uses the Flutter `camera` package to display a live camera preview. A Flutter-canvas linked list scene (perspective-transformed nodes and connectors) is rendered on top. This is **not** ARCore or ARKit — there is no spatial anchoring, depth sensing, or 3D tracking. This is clearly noted in `pubspec.yaml`:

```yaml
camera: ^0.12.0+2
# Official Flutter camera plugin; no ARCore dependency.
```

---

## Future Roadmap

| Area | Description |
|---|---|
| `lib/features/topic/` | Topic catalog browser — currently empty, backend endpoint exists |
| Token refresh | Implement `/auth/refresh` flow using a refresh token |
| ARCore / ARKit | Replace camera overlay with true spatial anchoring |
| `lib/features/ai/` | Integration with a generative AI backend (when implemented) |
| Testing | Unit tests for rule validators; widget tests for core UI |
| Profile screen | `PATCH /api/v1/users/me` when backend implements it |
