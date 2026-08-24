# Frontend Architecture — HoloSTEM Explorer

> **Documentation status:** Updated to reflect the actual current implementation.
> Code is the source of truth. Features previously marked as future/planned are updated to reflect their current implementation status.

---

## Table of Contents

1. [Architecture Principles](#1-architecture-principles)
2. [High-Level Structure](#2-high-level-structure)
3. [Application Flow](#3-application-flow)
4. [Dependency Flow](#4-dependency-flow)
5. [Directory Reference](#5-directory-reference)
6. [File Reference — Core and Shared](#6-file-reference--core-and-shared)
7. [File Reference — Implemented Features](#7-file-reference--implemented-features)
8. [State Management](#8-state-management)
9. [Backend Integration Layer](#9-backend-integration-layer)
10. [Misconception Detection System](#10-misconception-detection-system)
11. [Assessment and AI Coach Loop](#11-assessment-and-ai-coach-loop)
12. [Responsive Layout Strategy](#12-responsive-layout-strategy)
13. [Shared vs Feature Widgets](#13-shared-vs-feature-widgets)
14. [Current Implementation Status per Feature Folder](#14-current-implementation-status-per-feature-folder)
15. [Future Folder Expansion](#15-future-folder-expansion)

---

## 1. Architecture Principles

### Separation of Concerns

The codebase is divided into four distinct layers:

- **`core/`** — Network client, secure storage, API constants, and the visual contract (colors + theme). Nothing outside `core/` hardcodes color values or base URLs.
- **`navigation/`** — The root scaffold and routing logic. Screens never navigate themselves through global routing; they receive callbacks from the shell.
- **`shared/`** — Stateless, domain-agnostic UI primitives. A widget in `shared/` must not know anything about STEM content, linked lists, or any specific feature.
- **`features/`** — All domain-specific screens, widgets, models, services, and providers. Each feature is self-contained.

### Feature Isolation

Each folder under `features/` owns its own screens, widgets, models, services, and providers. A feature can use `core/` and `shared/` but must not import from another feature.

### State Management: Provider

State is managed with the `provider` package (`ChangeNotifier`). Services are plain Dart classes injected into providers at construction time. All providers are created in `main.dart` and registered via `MultiProvider`. No GetX, Riverpod, or Bloc.

### Visual / Logical Separation (Linked List features)

The Linked List workspace and assessment maintain two parallel state layers:
- `List<LinkedListNodeModel>` — pixel positions on screen (visual layer, read by rendering code)
- `LinkedListGraph` — logical structure: head ID, `nextPointers` map (logical layer, read by validators)

This separation means validators (`LinkedListAssessmentService`) are pure functions with zero Flutter imports.

### Backend Integration

All API communication goes through `ApiClient` (a Dio wrapper). Services call `ApiClient` methods and return typed models. Providers call services and expose loading/error/data state to widgets.

The `MisconceptionService`, `SessionService`, `ProgressService`, `AiCoachService`, and `AuthService` are all wired up at startup in `main.dart`.

---

## 2. High-Level Structure

```
lib/
├── main.dart                             # Entry point — service wiring, auth restore, runApp
├── app.dart                              # Root MaterialApp — auth-gate routing
│
├── core/                                 # App-wide foundation
│   ├── config/
│   │   └── api_constants.dart            # Base URL, endpoint paths, storage keys
│   ├── network/
│   │   ├── api_client.dart               # Dio wrapper — auth interceptor, error handling
│   │   └── api_exception.dart            # Typed exception
│   ├── storage/
│   │   └── secure_storage_service.dart   # JWT storage (flutter_secure_storage)
│   └── theme/
│       ├── app_colors.dart               # Color palette (const) — single source of truth
│       └── app_theme.dart                # ThemeData — Material 3 dark cyberpunk
│
├── navigation/
│   └── app_shell.dart                    # Root scaffold, rail/bottom nav, logout, 4 pages
│
├── shared/
│   └── widgets/
│       ├── cyber_background.dart
│       ├── glass_card.dart
│       ├── neon_action_card.dart
│       ├── pulse_orb.dart
│       └── status_chip.dart
│
└── features/
    ├── auth/                             # IMPLEMENTED — login, register, JWT, session restore
    ├── dashboard/                        # IMPLEMENTED — home screen, 5 action cards
    ├── advanced_workspaces/              # IMPLEMENTED — 11 STEM labs
    ├── linked_list/                      # IMPLEMENTED — free-explore + task curriculum + assessment
    ├── assessments/                      # IMPLEMENTED — linked list 3-challenge scored assessment
    ├── sessions/                         # IMPLEMENTED — session lifecycle tracking
    ├── misconceptions/                   # IMPLEMENTED — misconception recording service
    ├── progress/                         # IMPLEMENTED — progress screen + service + provider
    ├── ai_coach/                         # IMPLEMENTED — 5-panel adaptive AI report screen
    ├── ar/                               # PARTIALLY IMPLEMENTED — camera + Flutter canvas overlay
    ├── topic/                            # EMPTY — directories created, no Dart files
    └── placeholder/                      # Exists — not currently used in navigation
```

---

## 3. Application Flow

```
main.dart
  ├── Initialize services (SecureStorage, ApiClient, AuthService, SessionService,
  │     ProgressService, AiCoachService)
  ├── Create providers (AuthProvider, SessionProvider, ProgressProvider, AiCoachProvider)
  ├── authProvider.restoreSession() ← async, awaited before runApp
  └── runApp(MultiProvider → StemArApp)

StemArApp (app.dart)
  └── MaterialApp (theme: AppTheme.darkCyberpunk)
        └── Consumer<AuthProvider>
              ├── isRestoring → _LoadingScreen (spinner)
              ├── isAuthenticated → AppShell
              └── else → LoginScreen

AppShell (navigation/app_shell.dart)
  ├── AppBar with user avatar PopupMenuButton (logout)
  ├── CyberBackground (wraps all content)
  ├── _CyberNavigationRail (wide screens ≥ 860px)
  ├── BottomNavigationBar (narrow screens)
  └── AnimatedSwitcher (450ms cubic) → one of four pages:
        ├── [0] DashboardScreen(onOpenSection)
        │       └── 5 action cards → openSection or Navigator.push(LinkedListAssessmentScreen)
        ├── [1] AdvancedStemWorkspacesScreen
        │       └── domain → topic → workspace
        │             └── Linked List → Navigator.push → LinkedListConstructionScreen
        ├── [2] ArLinkedListScreen (live camera + Flutter scene overlay)
        └── [3] ProgressScreen (topic mastery, sessions, misconceptions)
```

### Key Navigation Decisions

**Index-based shell navigation** — the four main destinations (Home, Labs, AR, Progress) are always available and share the scaffold and background.

**`Navigator.push`** — used for `LinkedListConstructionScreen` (from Labs) and `LinkedListAssessmentScreen` (from Dashboard action card and from within Labs). These are full-screen experiences with their own `Scaffold` and back buttons.

**Callback-based cross-screen communication** — `DashboardScreen` receives `onOpenSection` from `AppShell` and calls it when action cards are tapped. This keeps flow explicit and traceable.

---

## 4. Dependency Flow

Dependencies flow strictly downward. No layer imports from a layer above it.

```
main.dart
  ↓
app.dart
  ↓
navigation/app_shell.dart
  ↓ imports
  ├── core/theme/app_colors.dart
  ├── core/network/api_client.dart (via Provider)
  ├── shared/widgets/cyber_background.dart
  ├── features/auth/providers/auth_provider.dart
  ├── features/dashboard/dashboard_screen.dart
  ├── features/advanced_workspaces/advanced_stem_workspaces_screen.dart
  ├── features/ar/screens/ar_linked_list_screen.dart
  └── features/progress/screens/progress_screen.dart

features/*/services/*.dart
  ↓ imports
  └── core/network/api_client.dart

features/*/providers/*.dart
  ↓ imports
  └── features/*/services/*.dart

features/*/screens/*.dart
  ↓ imports
  ├── core/theme/app_colors.dart
  ├── shared/widgets/*.dart
  ├── features/*/models/*.dart
  ├── features/*/widgets/*.dart
  └── features/*/providers/*.dart (via Provider.of / Consumer)
```

**Forbidden imports:**
- `shared/` must not import from `features/`
- `core/` must not import from `features/` or `shared/`
- Feature A must not import from Feature B

---

## 5. Directory Reference

### `lib/core/config/`

Holds `api_constants.dart` — all API endpoint paths, the base URL, HTTP header names, timeout durations, and secure storage keys. This is the single place to change the backend URL when switching environments.

### `lib/core/network/`

`api_client.dart` — Dio wrapper. `api_exception.dart` — typed exception. No feature code should instantiate Dio directly.

### `lib/core/storage/`

`secure_storage_service.dart` — all secure token I/O. No feature code should call `FlutterSecureStorage` directly.

### `lib/core/theme/`

`app_colors.dart` — all color constants. `app_theme.dart` — the one `ThemeData`. No widget should hardcode color values.

### `lib/navigation/`

`app_shell.dart` — the root scaffold. Owns `_selectedIndex` state, the navigation rail/bottom bar, the page list, and the logout button. Does not own any STEM content.

### `lib/shared/widgets/`

Reusable domain-agnostic primitives: `CyberBackground`, `GlassCard`, `NeonActionCard`, `PulseOrb`, `StatusChip`. A widget here must contain zero STEM domain knowledge.

### `lib/features/auth/`

Fully implemented. Login, registration, JWT storage, session restore, `AuthProvider`, `AuthService`. See `AUTH_INTEGRATION.md` for full detail.

### `lib/features/dashboard/`

`DashboardScreen` — the home screen. Hero section, 5 action cards, 3 insight metric tiles. Accepts `onOpenSection` callback.

### `lib/features/advanced_workspaces/`

All 11 interactive STEM labs in one file (`advanced_stem_workspaces_screen.dart`, ~4000 lines). Hierarchical state machine: `_domainIndex` → `_topicIndex` → workspace widget. Integrates with `SessionProvider` (start/end session per topic) and `MisconceptionService` + `ProgressProvider` via `_MisconceptionTracking` mixin.

### `lib/features/linked_list/`

Three screens and a full model/widget set:
- `LinkedListLearningScreen` — original free-exploration workspace
- `LinkedListConstructionScreen` — task-based curriculum (3 guided tasks with progression)
- `LinkedListAssessmentScreen` (in `assessments/`) — 3-challenge scored assessment

### `lib/features/assessments/`

Assessment engine for the Linked List topic:
- Pure Dart `LinkedListGraph` model (no Flutter imports)
- Pure `LinkedListAssessmentService` with 3 `ChallengeDefinition`s and 3 validators
- `LinkedListAssessmentScreen` — the full interactive assessment UI
- Assessment result screen with AI Coach integration and targeted practice recommendations

### `lib/features/sessions/`

`SessionService` (start/end via API), `SessionProvider` (holds active session), models.

### `lib/features/misconceptions/`

`RecordMisconceptionRequest` model and `MisconceptionService` (POST to backend).

### `lib/features/progress/`

`ProgressService` (GET from backend), `ProgressProvider`, `ProgressScreen` (with `RefreshIndicator`).

### `lib/features/ai_coach/`

5-model response set, `AiCoachService` (5 parallel GET calls), `AiCoachProvider` (per-topic cache), `AiCoachScreen` (8-section report). `TopicLabels` utility for code → human-readable name conversion.

### `lib/features/ar/`

`ArLinkedListScreen` — live camera preview via `camera` package + Flutter-canvas 3D-style linked list scene overlay. This is **not** ARCore. Camera lifecycle managed via `WidgetsBindingObserver`.

### `lib/features/topic/`

Directories (`models/`, `providers/`, `services/`) exist but contain no Dart files. The backend `GET /api/v1/topics` endpoint exists and is ready to consume.

### `lib/features/placeholder/`

`FeaturePlaceholderScreen` — generic placeholder widget. Not currently used in `AppShell` navigation (all 4 tabs have real screens).

---

## 6. File Reference — Core and Shared

### `lib/main.dart`

Orchestrates the entire dependency graph. Wires all services and providers. Calls `authProvider.restoreSession()` before `runApp`. No widget or business logic.

### `lib/app.dart` — `StemArApp`

Root `MaterialApp`. Auth-gate routing via `Consumer<AuthProvider>`. Three possible root screens: `_LoadingScreen`, `LoginScreen`, `AppShell`.

### `lib/core/theme/app_colors.dart` — `AppColors`

| Name | Hex | Role |
|---|---|---|
| `backgroundTop` | `#050713` | Gradient start |
| `backgroundBottom` | `#101024` | Gradient end |
| `surface` | `#11142A` | Card/panel background |
| `glass` | `#33FFFFFF` | Frosted glass fill (21% white) |
| `cyan` | `#22F6FF` | Primary accent, interactive elements |
| `pink` | `#FF3DF2` | Error / misconception detected |
| `violet` | `#8A5CFF` | Secondary accent, pointers |
| `lime` | `#B8FF4D` | Success / correct state |
| `orange` | `#FFB547` | Warning / partial error |
| `textPrimary` | `#F5F8FF` | Main text |
| `textSecondary` | `#9DA8C7` | Supporting text |

### `lib/core/theme/app_theme.dart` — `AppTheme.darkCyberpunk`

Material 3, dark brightness, `scaffoldBackgroundColor = backgroundTop`. Full text theme (5 styles). `NavigationRailThemeData` and `BottomNavigationBarThemeData` both use `AppColors`.

### `lib/navigation/app_shell.dart` — `AppShell`

- `_selectedIndex` state (0–3)
- Pages: `[DashboardScreen, AdvancedStemWorkspacesScreen, ArLinkedListScreen, ProgressScreen]`
- AppBar with `Consumer<AuthProvider>` user avatar → `PopupMenuButton` (shows name/email, Logout action)
- Wide ≥860px: `_CyberNavigationRail` (104px pill-shaped glass container)
- Narrow: `BottomNavigationBar` (4 items: Home/Labs/AR/Progress)

### `lib/shared/widgets/cyber_background.dart`

`LinearGradient` (3 stops) + `_GridOverlay` (42px cyan grid, alpha 0.055) + two `_SoftGlow` circles. Wraps `child`.

### `lib/shared/widgets/glass_card.dart`

`BackdropFilter` blur(18,18) + `ClipRRect` radius 24 + glass fill + cyan box shadow. Accepts `child` and `padding`.

### `lib/shared/widgets/neon_action_card.dart`

Hover-animated card via `MouseRegion` + `TweenAnimationBuilder`. Lifts -4px and increases glow on hover. Wraps `GlassCard`.

### `lib/shared/widgets/pulse_orb.dart`

Repeating scale animation (0.90 → 1.08, 2200ms). Fields: `color`, `size`, `delay`.

### `lib/shared/widgets/status_chip.dart`

Lime dot + label text in a cyan-bordered pill.

---

## 7. File Reference — Implemented Features

### `lib/features/auth/screens/login_screen.dart`

`CyberBackground` + `GlassCard` (max 500px). Email + password fields. Calls `AuthProvider.login()`. Error → pink `SnackBar`. "Create an account" → `RegisterScreen`.

### `lib/features/auth/screens/register_screen.dart`

4 fields: display name, email, password, confirm password. Client-side validation. Calls `AuthProvider.register()`. Success → pops to `LoginScreen`.

### `lib/features/dashboard/dashboard_screen.dart`

Three sections:
1. `_DashboardHero` — title, subtitle, `StatusChip`, `PulseOrb` scanner card
2. `_ActionGrid` — 5 `NeonActionCard`s (Start Learning → Labs, Learning Path → Labs, Linked List Assessment → `Navigator.push(LinkedListAssessmentScreen)`, AR Simulation → AR tab, Progress Tracker → Progress tab)
3. `_InsightStrip` — 3 metric tiles (Adaptivity/cyan, Concept Graph/violet, AR Engine/pink)

Responsive: 4-column grid wide (≥900px), 1-column narrow.

### `lib/features/progress/screens/progress_screen.dart`

Calls `ProgressProvider.loadProgress()` in `initState`. `RefreshIndicator` wrapping `ListView.separated`. Each item: `Card` with topic code, session count, misconception count, mastery score, weak area chips, and a circle avatar showing `completionPercent%`. Handles loading, error, and empty states.

### `lib/features/ai_coach/screens/ai_coach_screen.dart`

Accepts `topicCode`, optional `onNavigate`, optional `onRetryAssessment`.

States: loading → error (with retry) → empty → `_CoachBody`.

`_CoachBody` sections (all conditional on data availability):
1. `_CoachHeader` — topic label, refresh button
2. `_MasterySection` — `MasteryScoreRing` + 4 stats (quiz score, sessions, misconceptions, practice badge)
3. `_TutorMessageSection` — tier-based tutor voice message
4. `_InsightsSection` — two-column strengths / needs-work list
5. `_RecommendationSection` — recommendation type badge + reason
6. `_RevisionSection` — revision actions + time estimate
7. `_WeakAreasSection` — misconception code chips + detail explanation cards
8. `_StudyPlanSection` — priority badge + numbered today tasks
9. `_NextActionSection` — action buttons (Continue Learning, Retry Assessment, Open Analytics, AR Practice, targeted practice for DSA_LINKED_LIST)

### `lib/features/ai_coach/widgets/mastery_score_ring.dart` — `MasteryScoreRing`

`StatefulWidget`. 1200ms ease-out-cubic animated arc. Color: lime (≥80), cyan (≥60), orange (≥40), pink (< 40). Center shows numeric score + level label.

### `lib/features/ai_coach/utils/topic_labels.dart` — `TopicLabels`

Static mapping utility. 18 topic codes → display names. 11 misconception codes → full explanation paragraphs + short chip labels. 4 recommendation types → action labels. 6 mastery levels → display strings. `clean(text)` replaces raw backend codes in strings.

### `lib/features/ar/screens/ar_linked_list_screen.dart` — `ArLinkedListScreen`

Uses `camera` package. Finds rear camera, initializes `CameraController` (HIGH resolution, JPEG, no audio).

Modes (`_Mode`): `explore`, `explain`, `practice`.
Challenges: 3 hardcoded challenges.
Nodes: 5 hardcoded nodes (HEAD/violet, 10/cyan, 20/cyan, 30/cyan, 40-tail/lime).

Layers (Stack):
1. `_CameraBackground` — `CameraPreview` widget or loading/error state
2. `_ArSceneOverlay` — perspective-transformed linked list scene (Flutter Canvas)
3. `_ArHeader` — title, LIVE/OFF camera badge
4. Feedback/prompt panels
5. `_BottomControls` — mode buttons

**Important:** This is a Flutter-canvas simulation overlaid on a camera feed. It is **not** ARCore or ARKit. No spatial anchoring is performed.

### `lib/features/linked_list/linked_list_construction_screen.dart` — `LinkedListConstructionScreen`

Task-based curriculum screen. Accepts optional `initialTaskId` for targeted practice mode.

3 tasks defined in `kLinkedListTasks`:
- `task-ll-1`: Build an ascending linked list (10→20→30)
- `task-ll-2`: Understand HEAD and TAIL
- `task-ll-3`: Traverse a linked list

State: `LinkedListWorkspaceState` (immutable, logical) + `List<LinkedListNodeModel>` (visual positions).

Session: `SessionProvider.startSession('DSA', 'DSA_LINKED_LIST', 'workspace')` in `initState`.

Gestures: drag-to-place nodes from `NodePalette`, long-press → "Set as HEAD" bottom sheet, two-tap connect (cycle-guarded via `hasCycle()`).

`_onVerify()`: calls `LinkedListAssessmentService.validateBuild()`, escalates hints, records misconception via `MisconceptionService`, refreshes `ProgressProvider`.

Wide layout (≥900px): palette (180px) + playground (flex) + side panel (280px). Narrow: stacked.

### `lib/features/assessments/linked_list_assessment/screens/linked_list_assessment_screen.dart`

3-challenge interactive assessment. Launched from Dashboard "Linked List Assessment" card and from `DataStructuresWorkspace` "Linked List" topic.

**Challenge types:**
1. `buildFromScratch` — place 4 nodes, set HEAD, connect in order → validates with `validateBuild()`
2. `repairGraph` — restore broken link (node 25 → node 40) → validates with `validateRepair()`
3. `traceTraversal` — tap nodes in traversal order → validates with `validateTraversal()` per tap

Session: `SessionService.startSession('DSA', 'DSA_LINKED_LIST', 'ASSESSMENT_LINKED_LIST')`.

Submission:
1. `POST /api/v1/quizzes/submit` (`totalQuestions=3`, `correctAnswers=passedChallengeCount`)
2. `POST /api/v1/sessions/{id}/end`
3. `AiCoachProvider.refresh('DSA_LINKED_LIST')` (fire-and-forget)
4. Shows `_AssessmentResultScreen`

`_AssessmentResultScreen`: score card, per-challenge results, strengths/improvements, tier-based next step banner, `_RecommendedPracticeSection` (uses `topRecommendations()` on failed codes), "Open AI Coach" button → pushes `AiCoachScreen`.

### `lib/features/assessments/linked_list_assessment/services/linked_list_assessment_service.dart`

Pure Dart service — no state, no API calls, no Flutter imports.

**Validators:**

`validateBuild(current, expected)`:
- No HEAD → `DSA_HEAD_POINTER_MISSING` (HIGH)
- Wrong HEAD → `DSA_HEAD_POINTER_MISSING` (HIGH)
- Isolated nodes → `DSA_BROKEN_LINKED_LIST` (MEDIUM)
- Wrong order → `DSA_INVALID_TRAVERSAL` (MEDIUM)
- All correct → `isValid: true`

`validateRepair(current, expected)`:
- HEAD changed → `DSA_HEAD_POINTER_MISSING` (HIGH)
- Isolated nodes remain → `DSA_BROKEN_LINKED_LIST` (MEDIUM)
- Wrong order → `DSA_INVALID_TRAVERSAL` (MEDIUM)
- All correct → `isValid: true`

`validateTraversal(tappedSequence, expected)`:
- Empty → prompt to tap HEAD
- First tap not HEAD → `DSA_INVALID_TRAVERSAL` (MEDIUM)
- Partial in progress → in-progress message
- Correct → `isValid: true`

### `lib/features/linked_list/models/linked_list_graph.dart` — `LinkedListGraph`

Pure Dart immutable graph. Internal: `_nodes` (Map<int, String>), `_nextPointers` (Map<int, int?>), `_headId`.

Key methods: `traversalOrder()` (cycle-safe), `isolatedNodeIds()`, `hasCycle()`, `isFullyConnected()`, `withHead()`, `withPointer()`.

### `lib/features/linked_list/widgets/linked_list_playground.dart` — `LinkedListPlayground`

Shared playground canvas used by all three linked list screens (free-explore, construction, assessment).

Fields: `nodes`, `headNodeId`, `connectionBroken`, `activeTraversalId`, `onMoveNode`, `onNodeTap?`, `onNodeLongPress?`, `selectedNodeId?`, `nextPointers?` (Map<int, int?>).

Rendering layers: `_PlaygroundGrid` + `AnimatedArrowLayer` + `_HeadPointer` (`AnimatedPositioned`) + nodes as `Positioned` + `GestureDetector`.

`_ArrowPainter`:
- **Pointer-map mode** (when `nextPointers != null`): arrows from logical `nextPointers`; null entry → broken link visual
- **Positional mode** (when `nextPointers == null`): arrows between nodes by X position; second gap broken when `connectionBroken=true`
- Normal arrows: cubic bezier with animated travelling dot
- Broken links: dashed line with X symbol

### `lib/features/linked_list/widgets/node_palette.dart`

`PaletteNodeDragData` (drag transfer type: `nodeId`, `label`). `NodePalette` with `_PaletteDraggableChip` items using `Draggable<PaletteNodeDragData>`. Empty state shows "All nodes placed" chip.

---

## 8. State Management

### Architecture

```
main.dart
  └── MultiProvider
        ├── Provider<SecureStorageService>
        ├── Provider<ApiClient>
        ├── Provider<AuthService>
        ├── Provider<SessionService>
        ├── Provider<ProgressService>
        ├── ChangeNotifierProvider<AuthProvider>
        ├── ChangeNotifierProvider<SessionProvider>
        ├── ChangeNotifierProvider<ProgressProvider>
        └── ChangeNotifierProvider<AiCoachProvider>
```

### Provider inventory

| Provider | Key State | Notifies On |
|---|---|---|
| `AuthProvider` | `AuthState`, `CurrentUser?`, `isRestoring` | Login, logout, error, session restore |
| `SessionProvider` | `SessionResponse? _activeSession` | Session start/end |
| `ProgressProvider` | `List<ProgressResponse>`, loading/error | Progress load |
| `AiCoachProvider` | `Map<String, AiCoachReport> _cache`, current report, loading/error | Report fetch, cache refresh |

### Local state

Complex interactive widgets (`LinkedListConstructionScreen`, `LinkedListAssessmentScreen`, lab workspaces in `AdvancedStemWorkspacesScreen`) use `StatefulWidget` + `setState` internally. They call provider methods for I/O but own their visual state locally.

---

## 9. Backend Integration Layer

### `ApiClient` — Dio wrapper

All HTTP calls go through `ApiClient`. No widget ever calls Dio directly.

The token-getter closure pattern (set up in `main.dart`):
```dart
apiClient = ApiClient(
  getToken: () async => await secureStorageService.getToken(),
);
```

This decouples `ApiClient` from `SecureStorageService` — `ApiClient` does not know how tokens are stored.

### Misconception pipeline (all workspaces)

```
1. Local rule check detects misconception
2. MisconceptionService.recordMisconception(request)
     → POST /api/v1/misconceptions
3. ProgressProvider.loadProgress()
     → GET /api/v1/progress/me
4. Workspace UI updates feedback display
```

Deduplication: each workspace tracks the last recorded misconception code and skips re-posting the same code within the same session.

### Session lifecycle (all workspaces)

```
Topic opened → SessionProvider.startSession(domain, topic, activity)
                 → POST /api/v1/sessions/start
Topic closed / back pressed → SessionProvider.endSession()
                                 → POST /api/v1/sessions/{id}/end
```

`AdvancedStemWorkspacesScreen` calls `_goBack()` which ends the session before returning to the topic list.

### AI Coach data flow

```
AiCoachService.fetchReport(topicCode)
  └── Future.wait([
        GET /api/v1/ai/insights/{topicCode}
        GET /api/v1/ai/recommendations/{topicCode}
        GET /api/v1/ai/revision-suggestions/{topicCode}
        GET /api/v1/ai/study-plan/{topicCode}
        GET /api/v1/analytics/topic/{topicCode}
      ])
  └── Assembles AiCoachReport

AiCoachProvider._cache[topicCode] = report
```

Cache is per-topic, per-session. `refresh(topicCode)` removes the cache entry and re-fetches. `clearAll()` is called on logout.

---

## 10. Misconception Detection System

### Local Rule-Based Detection (in workspaces)

Every workspace has a `_detect*()` method (or uses `LinkedListAssessmentService` validators) that evaluates current state and returns a misconception code + feedback message + accent color.

### Color semantics

| Color | Meaning |
|---|---|
| `AppColors.pink` | Hard error — definitively wrong (missing head, broken link, invalid valency) |
| `AppColors.orange` | Soft warning — possible misunderstanding (reversed traversal, TOP mismatch, hydrogen mismatch) |
| `AppColors.cyan` | Neutral / in progress |
| `AppColors.lime` | Correct — valid configuration |

### Misconception codes

Codes follow a domain-prefix convention: `DSA_*`, `ELECTRONICS_*`, `OC_*` (Organic Chemistry). All codes are defined in `TopicLabels.misconceptionShort()` and `TopicLabels.misconception()` for human-readable display.

### `_MisconceptionTracking` mixin (in `advanced_stem_workspaces_screen.dart`)

Used by `StackLearningLab`, `BinaryTreeLearningLab`, and all 4 chemistry labs. Maintains `_activeMisconceptions: Set<String>`. On first detection of a code, records via `MisconceptionService`, then refreshes `ProgressProvider`.

### Assessment-level detection (`LinkedListAssessmentService`)

Pure validators return `ValidationResult` with a `misconceptionCode`. The screen records the misconception on first occurrence per challenge.

---

## 11. Assessment and AI Coach Loop

This is the primary feedback loop connecting the assessment, backend persistence, and adaptive coaching:

```
Student completes LinkedListAssessmentScreen
    ↓
_submitAssessment():
    POST /api/v1/quizzes/submit {totalQuestions:3, correctAnswers:n}
    → server computes score, updates LearningAnalytics (4-component formula)
    → server resolves misconceptions if score ≥ 60
    ↓
POST /api/v1/sessions/{id}/end
    ↓
AiCoachProvider.refresh('DSA_LINKED_LIST') [fire-and-forget]
    → 5 parallel GET calls to AI endpoints
    → new AiCoachReport cached
    ↓
_AssessmentResultScreen shown:
    - Score / challenges passed
    - Per-challenge pass/fail
    - Strengths / improvements
    - Tier-based next step banner
    - Recommended practice tasks (from LinkedListMisconceptionMap)
    - "Open AI Coach" button → pushes AiCoachScreen with fresh report
```

### Targeted practice from AI Coach

```
AiCoachScreen._NextActionSection
    → "Practice [Concept]" button
    → Navigator.push(LinkedListConstructionScreen(initialTaskId: 'task-ll-2'))
```

`LinkedListConstructionScreen` in targeted mode (`_isTargetedMode = true`) skips the 3-task curriculum and opens only the specified task. On completion it shows `_TargetedPracticeCompletePanel` instead of the full curriculum completion screen.

---

## 12. Responsive Layout Strategy

| Screen / Widget | Breakpoint | Narrow | Wide |
|---|---|---|---|
| `AppShell` | 860px | `BottomNavigationBar` | `_CyberNavigationRail` (104px) |
| `DashboardScreen` hero | 900px | Stacked column | Two-column row |
| `DashboardScreen` action grid | 900px | 1-column | 4-column |
| `LinkedListLearningScreen` | 1040px | Stacked column | Playground + side panel |
| `LinkedListConstructionScreen` | 900px | Stacked | Palette + playground + side panel |
| `LinkedListAssessmentScreen` | 900px | Stacked | Playground + side panel |
| `_ResponsiveLabShell` (all STEM labs) | 980px | Stacked column | Workspace (flex 7) + side panel (flex 4) |
| `AdvancedStemWorkspacesScreen` domain grid | 960px | 1-column | 3-column |

No separate layout files. Each widget uses `LayoutBuilder` with its own appropriate threshold.

---

## 13. Shared vs Feature Widgets

**Put a widget in `shared/widgets/` if:**
1. Zero STEM domain knowledge
2. Used (or will realistically be used) in more than one feature
3. Behavior fully controlled by parameters

**Put a widget in a feature's `widgets/` folder if:**
1. It renders a STEM concept (node with pointer cell, atom bubble, gate chip)
2. Its structure assumes the context of a specific feature
3. It would be meaningless outside that feature

| Widget | Location | Reason |
|---|---|---|
| `GlassCard` | `shared/widgets/` | Generic container; used everywhere |
| `CyberBackground` | `shared/widgets/` | Generic background; used by AppShell and several screens |
| `NeonLinkedListNode` | `linked_list/widgets/` | Has data compartment + pointer compartment — linked list concept |
| `MasteryScoreRing` | `ai_coach/widgets/` | Specifically designed for mastery display; knows about mastery levels |
| `NodePalette` | `linked_list/widgets/` | Draggable linked list nodes — domain-specific |
| `CoachSectionCard` | `ai_coach/widgets/` | Accent-border card used only in AI Coach sections |

---

## 14. Current Implementation Status per Feature Folder

| Feature Folder | Status | Notes |
|---|---|---|
| `auth/` | Implemented | Login, register, JWT, session restore, logout |
| `dashboard/` | Implemented | 5 action cards including assessment launch |
| `advanced_workspaces/` | Implemented | 11 labs with session + misconception tracking |
| `linked_list/` | Implemented | Free-explore + 3-task curriculum + shared playground widget |
| `assessments/` | Implemented | 3-challenge assessment, result screen, AI Coach integration |
| `sessions/` | Implemented | Service + provider + models |
| `misconceptions/` | Implemented | Service + model |
| `progress/` | Implemented | Service + provider + screen |
| `ai_coach/` | Implemented | 5-source report, 8-section screen, cache, targeted practice |
| `ar/` | Partially implemented | Camera preview + Flutter canvas overlay; no spatial AR |
| `topic/` | Empty | Directories created; no Dart files; backend endpoint available |
| `placeholder/` | Exists, unused | Not referenced in AppShell navigation |

---

## 15. Future Folder Expansion

### `lib/features/topic/` — Topic Catalog Browser

The backend `GET /api/v1/topics` endpoint is implemented and returns 18 seeded topics. The frontend folder exists but is empty. Implementing the topic browser requires:
- `topic_model.dart` (map from `TopicResponse`)
- `topic_service.dart` (`getAll()`, `getByCode()`)
- `topic_browser_screen.dart` (domain grid → topic list → launch workspace)

### Token Refresh

When the 24-hour JWT expires, API calls return 401. A Dio interceptor in `ApiClient` should catch 401 responses and trigger `AuthProvider.logout()`. A proper refresh token flow requires backend implementation of `/auth/refresh`.

### True AR Integration

Replace `ArLinkedListScreen`'s camera overlay with ARCore (Android) or ARKit (iOS) integration. This requires platform channel code, a separate AR framework (Unity + AR Foundation, or native), and a decision on which platforms to support.

### Splitting `advanced_stem_workspaces_screen.dart`

The threshold for extraction is when a domain needs a second screen or its widgets need to be shared. Expected structure:

```
lib/features/data_structures/
lib/features/digital_electronics/
lib/features/organic_chemistry/
```

Each with their own `screens/`, `labs/`, `models/`, and `widgets/` subfolders.

### User Profile Screen

`PATCH /api/v1/users/me` will be available once the backend implements it. Frontend would add a `profile_screen.dart` in `auth/` or a new `profile/` feature folder.

---

*End of ARCHITECTURE.md*
