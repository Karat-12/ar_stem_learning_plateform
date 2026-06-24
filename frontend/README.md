# AR STEM Learning Prototype

A Flutter UI-first prototype for a **Domain-Independent Adaptive AR-Based Misconception Detection Framework for STEM Education**.

This repository currently contains an interactive learning prototype focused on dashboard navigation, advanced STEM lab workspaces, rule-based learner feedback, and a cyberpunk glassmorphism UI. The main target is a prototype learning cockpit rather than a finished AR engine.

## What Changed

- Updated README to reflect the actual implemented workspace state in the current codebase.
- Replaced earlier roadmap text with a detailed summary of completed work, current lab flow, and placeholders.
- Documented the current structure of dashboard, linked-list workspace, advanced STEM labs, and placeholder screens.
- Highlighted where the prototype is working today and what remains planned.

## Current Prototype Scope

### Implemented

- Responsive dashboard entry surface with navigation cards and status metrics.
- Advanced STEM labs shell with domain and topic selection.
- Data Structures workspaces:
  - Linked List: draggable node placement, head pointer controls, insert/delete, traversal simulation, and rule-based feedback.
  - Stack: PUSH / POP simulation, TOP pointer behavior, overflow/underflow feedback, and drag/drop value controls.
  - Binary Tree: node placement, traversal options, hierarchy checks, and sequence validation.
- Digital Electronics workspaces:
  - Basic Logic Gates: AND, OR, NOT placement with gate selection and connection semantics.
  - XOR Gate Builder: assemble XOR logic from primitive gates.
  - Complex Gate Construction: NAND / NOR / XNOR exploration.
  - Truth Table Simulator: gate board, input toggles, output evaluation, and feedback.
- Organic Chemistry workspaces:
  - Hydrocarbon Builder: place C/H atoms and build simple hydrocarbons.
  - Sugar Structure Builder: simplified glucose/sucrose templates and bond validation.
  - Alcohol & Functional Groups: OH / N attachments, bond order control, and valency feedback.
  - Bond Simulator: interactive single/double/triple bond exploration.
- Dedicated linked-list learning screen with explanation panels, interactive controls, and misconception detection.
- Shared UI foundation in `lib/core`, `lib/navigation`, and `lib/shared/widgets` for consistent theme and visuals.

### Partially Implemented

- Rule-based misconception feedback in selected UI states and learning workspaces.
- Prototype validation logic for selected data structure, circuit, and molecule interactions.
- Responsive layout adaptation for wide and narrow screens.
- Guided topic flow inside the advanced STEM labs shell.

### Placeholder / Planned

- AR Simulation mode is a placeholder screen without camera integration.
- Progress Tracker is a placeholder without learner analytics or persistence.
- Dedicated Concept Board feature is not currently present in `lib/features`.
- Persistent learner analytics, progress storage, and adaptive curriculum sequencing are not built yet.
- Full domain-independent misconception engine and real 3D AR anchoring remain future work.

## Project Structure

```text
lib/
  main.dart
  app.dart
  core/
    theme/
      app_colors.dart
      app_theme.dart
  navigation/
    app_shell.dart
  shared/
    widgets/
      cyber_background.dart
      glass_card.dart
      neon_action_card.dart
      pulse_orb.dart
      status_chip.dart
  features/
    dashboard/
      dashboard_screen.dart
    linked_list/
      linked_list_learning_screen.dart
      models/
        linked_list_node_model.dart
      widgets/
        floating_particles.dart
        holographic_explanation_panel.dart
        linked_list_playground.dart
        misconception_feedback_panel.dart
        neon_linked_list_node.dart
        operation_control_panel.dart
    advanced_workspaces/
      advanced_stem_workspaces_screen.dart
    placeholder/
      feature_placeholder_screen.dart
```

## Core Features

### Dashboard

Located at `lib/features/dashboard/dashboard_screen.dart`.

- Entry point for the prototype.
- Action cards for launching advanced labs, AR placeholder, and progress placeholder.
- Status metrics strip showing prototype readiness.
- Responsive layout with adaptive grid behavior.

### Advanced STEM Labs

Located at `lib/features/advanced_workspaces/advanced_stem_workspaces_screen.dart`.

- Domain selection for Data Structures, Digital Electronics, and Organic Chemistry.
- Topic selection and workspace navigation inside a single screen.
- Interactive labs using drag/drop, animated boards, and feedback panels.
- Working lab areas for linked lists, stacks, binary trees, logic circuits, and molecule building.

### Linked List Workspace

Located at `lib/features/linked_list/linked_list_learning_screen.dart`.

- Dedicated learning workspace for linked list concepts.
- Draggable nodes, head pointer state, and link visualization.
- Operations for inserting nodes, deleting tail nodes, toggling broken links, and traversal order.
- Feedback panel with misconception warnings for missing head, broken connections, and reversed traversal.

### Placeholder Screens

Located at `lib/features/placeholder/feature_placeholder_screen.dart`.

- AR Simulation placeholder screen.
- Progress Tracker placeholder screen.
- Designed as future targets for AR mode and analytics integration.

## Running the App

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```
