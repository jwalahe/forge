# FORGE — Workout Progress Tracker

## Product Requirements Document v1.0
**Scope:** MVP + V1 | **Timeline:** 1 Month | **Platform:** iOS + watchOS

---

# Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [App Philosophy](#2-app-philosophy)
3. [Target Users](#3-target-users)
4. [Feature Breakdown](#4-feature-breakdown)
5. [Information Architecture](#5-information-architecture)
6. [Technical Specifications](#6-technical-specifications)
7. [Screen-by-Screen UI Guidance](#7-screen-by-screen-ui-guidance)
8. [Data Models](#8-data-models)
9. [User Stories](#9-user-stories)
10. [Success Metrics](#10-success-metrics)
11. [Timeline](#11-timeline)
12. [Appendix: Default Exercise Library](#appendix-a-default-exercise-library)

---

# 1. Executive Summary

FORGE is a **freeform-first workout tracking app** designed for lifters who want to meticulously log their training progress. Inspired by the disciplined approach of bodybuilders like Mike Mentzer and Dorian Yates who kept detailed training logs, FORGE prioritizes **speed, simplicity, and progressive overload tracking** above all else.

## Problem Statement

Existing workout tracking apps suffer from three core issues:

1. **Too many taps** required to log a single set during active workouts
2. **Previous performance data is buried**, making progressive overload difficult to track
3. **Forced templates and rigid structures** that don't match how people actually train

## Solution

FORGE solves these problems by offering:

- **Freeform-first approach** — users add exercises as they go
- **Previous performance always visible inline** — no digging through menus
- **2-tap set logging** with auto-fill from previous session
- **Templates earned from real workouts**, not created hypothetically

## Key Differentiators

| # | Differentiator |
|---|----------------|
| 1 | 2-tap set logging with auto-fill from previous session |
| 2 | Progress arrows showing immediately if you beat last time |
| 3 | Freeform-first with optional template saving |
| 4 | Offline-first architecture for basement gym reliability |
| 5 | Apple Watch companion for wrist-based logging |

---

# 2. App Philosophy

## Core Design Principles

### Principle 1: Speed Over Features
Every interaction must be optimized for speed. If a feature adds taps without clear value, it is cut. The user should spend more time lifting than logging.

### Principle 2: Previous Performance is Sacred
The single most important piece of information during any set is **what you did last time**. This data must be visible without scrolling, tapping, or navigating.

### Principle 3: Progress is Obvious
When a user beats their previous performance, the UI celebrates it with **green arrows**. When they fall short, **red arrows** appear. No ambiguity.

### Principle 4: Freeform by Default, Templates by Choice
Users should be able to walk into a gym with zero setup and start logging immediately. Templates are a convenience earned from completed workouts, not a prerequisite.

### Principle 5: Offline-First
The app must work perfectly with no internet connection. Sync is a background luxury, not a requirement for functionality.

### Principle 6: Zero Account Friction
Users can start logging workouts within **10 seconds of first launch**. No signup required. iCloud handles sync invisibly.

---

## UX Philosophy: The Slickest Possible Interface

FORGE follows iOS Human Interface Guidelines with a focus on:
- **Clarity** — Content is legible and icons are precise
- **Deference** — UI helps users understand content without competing with it
- **Depth** — Visual layering and realistic motion convey hierarchy

### Visual Design Pillars

| Pillar | Implementation |
|--------|----------------|
| Minimal chrome | Maximum content, minimal UI decoration |
| Large touch targets | Minimum 44pt for gym-friendly interaction |
| High contrast | Visibility in varied lighting conditions |
| Haptic feedback | Confirmations feel tactile |
| Dark mode primary | Optimized for gym lighting |
| SF Pro font | System font throughout |
| SF Symbols | Consistent iconography |

---

# 3. Target Users

## Primary Persona: The Dedicated Lifter

| Attribute | Value |
|-----------|-------|
| Age | 22-40 |
| Training Frequency | 3-6x per week |
| Experience | Intermediate to advanced |
| Goal | Progressive overload and strength gains |
| Pain Point | Current apps are too slow or too complicated |
| Behavior | Follows a general split but adapts based on feel |

## Secondary Persona: The New Lifter

| Attribute | Value |
|-----------|-------|
| Age | 18-30 |
| Training Frequency | 2-4x per week |
| Experience | Beginner to intermediate |
| Goal | Build muscle, track progress |
| Pain Point | Doesn't know what to log or why |
| Behavior | Needs guidance but wants flexibility |

## Anti-Persona: The Cardio Enthusiast

Primary focus is running, cycling, or HIIT. FORGE is **not optimized** for time-based or distance-based activities. These users are better served by Strava or Apple Fitness.

---

# 4. Feature Breakdown

## 4.1 MVP Features (Week 1-2)

**Goal:** Ship to TestFlight. Core logging loop must be flawless.

### Workout Tab (Home)

| Feature | Description | Watch Support |
|---------|-------------|---------------|
| Start Workout | Big prominent button, one tap to begin new session | Complication |
| Quick Resume | If workout in progress, shows "Continue Workout" CTA | ✓ |
| Recent Exercises | Last 10 exercises for fast re-adding | — |
| Saved Templates | Horizontal scroll of saved routines (if any) | List view |

### Active Workout Screen

| Feature | Description | Watch Support |
|---------|-------------|---------------|
| Add Exercise | Search by name or browse by muscle group | Favorites only |
| Exercise Card | Shows name, previous performance, set rows | Compact card |
| Set Row | Input: Weight × Reps, tap checkmark to complete | Digital Crown |
| Auto-fill Previous | Tap to copy last session's weight/reps | ✓ |
| Progress Arrows | Green ↑ if beating previous, red ↓ if lower | Color indicator |
| Rest Timer | Auto-starts on set completion, lock screen visible | Haptic on complete |
| Reorder Exercises | Long-press drag to rearrange | — |
| Delete Set/Exercise | Swipe to delete | ✓ |
| Finish Workout | End session → Summary screen | ✓ |

### Workout Summary (Post-Workout)

| Feature | Description | Watch Support |
|---------|-------------|---------------|
| Duration | Total workout time | ✓ |
| Volume | Total weight lifted (sets × reps × weight) | — |
| PRs Hit | List any new personal records | — |
| Save as Template | "Save this workout for next time?" option | — |
| Add Notes | Optional workout-level notes | Voice input |

### Exercises Tab

| Feature | Description | Watch Support |
|---------|-------------|---------------|
| Exercise Library | 50+ exercises organized by muscle group | — |
| Search | Fuzzy search by name | — |
| Custom Exercise | Create your own (name, muscle group, equipment) | — |
| Exercise Detail | Tap any exercise → see all history for that exercise | — |

### History Tab

| Feature | Description | Watch Support |
|---------|-------------|---------------|
| Workout List | Reverse chronological list of past workouts | — |
| Calendar View | Month view with dots on workout days | — |
| Repeat Workout | Tap any past workout → "Repeat" to start new session | — |

### Profile/Settings

| Feature | Description | Watch Support |
|---------|-------------|---------------|
| Units | kg/lbs toggle | Synced |
| Default Rest Timer | Set default (e.g., 90 seconds) | Synced |
| Offline Mode | Full functionality, syncs via iCloud | ✓ |
| Export CSV | Download all workout data | — |

---

## 4.2 V1 Features (Week 3-4)

**Goal:** App Store submission. Polish and analytics.

| Feature | Description | Watch Support |
|---------|-------------|---------------|
| Exercise History Graph | Weight over time, volume over time per exercise | — |
| PR Detection | Auto-detect when you hit a new 1RM, 5RM, etc. | Haptic |
| PR Celebration | Subtle confetti animation + badge | — |
| Set Types | Mark sets as: Warmup, Working, Drop Set, To Failure | Quick toggle |
| Per-Exercise Notes | "Felt tight on left shoulder" | Voice note |
| Plate Calculator | Enter target weight → shows plate breakdown | — |
| Muscle Heatmap | Body diagram showing volume per muscle this week | — |
| Workout Streak | "5 workouts this week" (non-gamified) | — |
| Template Management | Edit/delete saved templates | — |
| Dark Mode | System default + manual override | Matched |

---

## 4.3 V2 Features (Future)

**Goal:** Post-launch iteration based on user feedback.

| Feature | Description |
|---------|-------------|
| Smart Suggestions | "You've plateaued at 185. Try 190 or add a set?" |
| Weekly Volume Targets | Set goals per muscle group |
| Body Measurements | Weight, arms, chest, waist tracking |
| Progress Photos | Side-by-side comparison |
| Widgets | Today's workout, weekly volume, streak |
| Shortcuts/Siri | "Hey Siri, start my workout" |
| Apple Health Sync | Write workouts to Health app |
| Social Sharing | Export workout as image for IG stories |

---

# 5. Information Architecture

## Tab Bar Structure

```
┌─────────────────────────────────────────────────────┐
│                    TAB BAR                          │
├─────────────┬─────────────┬─────────────┬───────────┤
│   Workout   │   History   │  Exercises  │  Profile  │
│   (Home)    │  Calendar   │   Library   │  Settings │
└─────────────┴─────────────┴─────────────┴───────────┘
```

| Tab | Purpose |
|-----|---------|
| Workout | Home screen. Start new workout, continue in-progress, access templates. |
| History | Calendar view and list of past workouts. Repeat functionality. |
| Exercises | Exercise library. Search, browse by muscle, create custom. |
| Profile | Settings, stats, export, account management. |

## Navigation Hierarchy

### Workout Tab
```
Home
├── Start Workout → Active Workout
│   ├── Add Exercise (Sheet)
│   └── Finish → Summary
└── Template → Start from Template → Active Workout
```

### History Tab
```
History List
├── Workout Detail → Repeat Workout
└── Calendar View → Day Detail → Workout Detail
```

### Exercises Tab
```
Exercise List
├── Exercise Detail → History Graph
└── Create Custom Exercise (Sheet)
```

### Profile Tab
```
Settings List → Individual Setting Screens
Stats Overview → Detailed Stats
```

---

# 6. Technical Specifications

## Platform Requirements

| Spec | Value |
|------|-------|
| iOS Target | iOS 17.0+ |
| watchOS Target | watchOS 10.0+ |
| Framework | SwiftUI (100%) |
| Architecture | MVVM with Repository Pattern |
| Persistence | SwiftData (preferred) or Core Data + CloudKit |
| Sync | iCloud automatic sync via SwiftData/CloudKit |

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                 PRESENTATION LAYER                  │
│         SwiftUI Views (declarative, no logic)       │
│              @StateObject / @ObservedObject         │
└─────────────────────────┬───────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────┐
│                  VIEWMODEL LAYER                    │
│           @Observable classes                       │
│     Presentation logic, formatting, validation      │
└─────────────────────────┬───────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────┐
│                 REPOSITORY LAYER                    │
│         Abstracts data source from ViewModels       │
│           CRUD operations, complex queries          │
└─────────────────────────┬───────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────┐
│                    MODEL LAYER                      │
│         SwiftData @Model classes                    │
│        Pure data structures with relationships      │
└─────────────────────────────────────────────────────┘
```

## Key Technical Decisions

| Decision | Rationale |
|----------|-----------|
| SwiftData over Core Data | Simpler API, native Swift, automatic CloudKit sync |
| @Observable macro | Modern observation without Combine complexity |
| Offline-first | All operations write to local store first, sync is eventual |
| No external dependencies | Pure Apple frameworks for long-term stability |
| Watch independence | watchOS app can function without iPhone nearby |

## File Structure

```
FORGE/
├── App/
│   ├── FORGEApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Workout.swift
│   ├── Exercise.swift
│   ├── ExerciseSet.swift
│   └── Template.swift
├── ViewModels/
│   ├── WorkoutViewModel.swift
│   ├── ActiveWorkoutViewModel.swift
│   ├── ExerciseLibraryViewModel.swift
│   └── HistoryViewModel.swift
├── Views/
│   ├── Workout/
│   │   ├── WorkoutHomeView.swift
│   │   ├── ActiveWorkoutView.swift
│   │   ├── ExerciseCardView.swift
│   │   ├── SetRowView.swift
│   │   └── WorkoutSummaryView.swift
│   ├── History/
│   │   ├── HistoryListView.swift
│   │   └── CalendarView.swift
│   ├── Exercises/
│   │   ├── ExerciseLibraryView.swift
│   │   └── ExerciseDetailView.swift
│   └── Profile/
│       └── ProfileView.swift
├── Repositories/
│   ├── WorkoutRepository.swift
│   └── ExerciseRepository.swift
├── Components/
│   ├── RestTimerView.swift
│   ├── ProgressArrow.swift
│   └── PlateCalculatorView.swift
└── Utilities/
    ├── Extensions.swift
    └── Constants.swift
```

---

# 7. Screen-by-Screen UI Guidance

## 7.1 Workout Tab (Home)

### Layout
```
┌─────────────────────────────────────┐
│ FORGE                    (large)    │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐    │
│  │    ▶  Start Workout         │    │  ← Primary CTA (56pt height)
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ ⏱ Continue Workout (42:30)  │    │  ← Only if workout in progress
│  └─────────────────────────────┘    │
│                                     │
│  Templates                          │
│  ┌──────┐ ┌──────┐ ┌──────┐        │  ← Horizontal scroll
│  │Push A│ │Pull B│ │Legs  │        │
│  └──────┘ └──────┘ └──────┘        │
│                                     │
│  Recent Exercises                   │
│  • Bench Press                      │
│  • Squat                            │
│  • Lat Pulldown                     │
│  • ...                              │
└─────────────────────────────────────┘
```

### Start Workout Button
- **Style:** Filled button with accent color background
- **Text:** "Start Workout" (SF Pro Semibold, 17pt)
- **Icon:** `play.fill` leading
- **Height:** 56pt
- **Corner Radius:** 12pt
- **Interaction:** Tap navigates to Active Workout screen
- **Haptic:** Light impact on tap

### Template Card
- **Size:** 160pt width × 100pt height
- **Content:** Template name (bold), exercise count, last used date
- **Background:** Secondary system background
- **Corner Radius:** 12pt
- **Interaction:** Tap starts workout with template exercises pre-loaded

---

## 7.2 Active Workout Screen

### Layout
```
┌─────────────────────────────────────┐
│ Cancel      ⏱ 00:42:30      Finish  │  ← Navigation bar
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Bench Press            •••  │    │  ← Exercise Card
│  │ Last: 185 lbs × 8           │    │
│  │ ┌───┬────────┬─────┬──┬──┐  │    │
│  │ │ 1 │ 185    │  8  │↑ │✓ │  │    │  ← Set Row
│  │ └───┴────────┴─────┴──┴──┘  │    │
│  │ ┌───┬────────┬─────┬──┬──┐  │    │
│  │ │ 2 │ 185    │  7  │↓ │✓ │  │    │
│  │ └───┴────────┴─────┴──┴──┘  │    │
│  │        + Add Set            │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Incline Dumbbell Press •••  │    │
│  │ Last: 60 lbs × 10           │    │
│  │ ...                         │    │
│  └─────────────────────────────┘    │
│                                     │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │      + Add Exercise         │    │  ← Sticky bottom button
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

### Exercise Card Component

This is the **atomic unit** of the app. Must be optimized for speed.

```
┌─────────────────────────────────────────────────┐
│ Exercise Name                              •••  │  ← Header Row
├─────────────────────────────────────────────────┤
│ Last: 185 lbs × 8 reps                    [tap] │  ← Previous Row (tappable to auto-fill)
├─────────────────────────────────────────────────┤
│  1   [ 185 ]  ×  [ 8 ]   ↑   [✓]               │  ← Set Row
│  2   [ 185 ]  ×  [ 7 ]   ↓   [✓]               │
│  3   [ 190 ]  ×  [ 6 ]   ↑   [ ]               │  ← Incomplete set
├─────────────────────────────────────────────────┤
│              + Add Set                          │
└─────────────────────────────────────────────────┘
```

### Set Row Structure

| Element | Description |
|---------|-------------|
| Set badge | Number (1, 2, 3...) in circle |
| Weight field | Numeric input, shows previous as placeholder |
| × separator | Static text |
| Reps field | Numeric input, shows previous as placeholder |
| Progress arrow | Green ↑ / Red ↓ / Empty |
| Checkmark | Completes set, starts rest timer |

### Input Behavior

| Behavior | Implementation |
|----------|----------------|
| Weight field | Shows previous weight as placeholder. Tap to edit. |
| Reps field | Shows previous reps as placeholder. Tap to edit. |
| Auto-fill | Tapping "Previous Row" copies values to current set inputs |
| Keyboard | Numeric pad with Done button. Auto-advance to reps after weight entry. |
| Completion | Tapping checkmark logs set, triggers haptic, starts rest timer |

### Progress Arrow Logic

Compare current set to **same set number** from previous session:

| Condition | Arrow |
|-----------|-------|
| Weight increased OR reps increased (at same weight) | Green ↑ |
| Weight decreased OR reps decreased | Red ↓ |
| First time doing this exercise OR no comparison | None |

---

## 7.3 Add Exercise Sheet

### Layout
```
┌─────────────────────────────────────┐
│ ─────  (drag indicator)             │
├─────────────────────────────────────┤
│ 🔍 Search exercises...              │
├─────────────────────────────────────┤
│ [Recent] [By Muscle] [All]          │  ← Segmented control
├─────────────────────────────────────┤
│                                     │
│ CHEST                               │
│   Bench Press                       │
│   Incline Bench Press               │
│   Dumbbell Fly                      │
│                                     │
│ BACK                                │
│   Lat Pulldown                      │
│   Barbell Row                       │
│   ...                               │
│                                     │
├─────────────────────────────────────┤
│        + Create Custom Exercise     │
└─────────────────────────────────────┘
```

### Presentation
- **Type:** Sheet with detents (medium, large)
- **Search:** Always visible at top
- **Segments:** Recent | By Muscle | All

### By Muscle Categories
- Chest
- Back
- Shoulders
- Biceps
- Triceps
- Legs (Quads)
- Legs (Hamstrings)
- Legs (Glutes)
- Core
- Full Body

### Interaction
- **Tap exercise:** Adds to current workout, dismisses sheet
- **Search:** Fuzzy matching on exercise name
- **Create Custom:** Button at bottom of All list

---

## 7.4 Rest Timer

### Trigger
Automatically starts when user taps checkmark to complete a set.

### Display Locations

| Location | Behavior |
|----------|----------|
| In-app | Overlay at bottom of Active Workout screen showing countdown |
| Lock screen | Live Activity with countdown and Skip button |
| Apple Watch | Haptic pulse when timer completes |

### Controls
- **Tap timer:** Expand to full view with +30s, -30s, Skip buttons
- **Skip:** Dismisses timer immediately
- **Default duration:** From settings (default 90 seconds)

### Visual Design
```
┌─────────────────────────────────────┐
│                                     │
│            ⏱ 1:23                   │  ← Large countdown
│                                     │
│   [-30s]    [Skip]    [+30s]        │
│                                     │
└─────────────────────────────────────┘
```

---

## 7.5 Workout Summary

### Layout
```
┌─────────────────────────────────────┐
│              ✓                      │  ← Animated checkmark
│       Workout Complete              │
├─────────────────────────────────────┤
│  ┌────────┐  ┌────────┐            │
│  │  42:30 │  │ 12,450 │            │  ← Stats grid
│  │Duration│  │ Volume │            │
│  └────────┘  └────────┘            │
│  ┌────────┐  ┌────────┐            │
│  │   18   │  │   2    │            │
│  │  Sets  │  │  PRs   │            │
│  └────────┘  └────────┘            │
├─────────────────────────────────────┤
│ 🏆 New Personal Records             │
│   • Bench Press: 190 × 6 (1RM: 220)│
│   • Squat: 275 × 5                  │
├─────────────────────────────────────┤
│ Save as Template                    │
│ ┌─────────────────────────────┐     │
│ │ Template name...            │     │
│ └─────────────────────────────┘     │
├─────────────────────────────────────┤
│ Notes                               │
│ ┌─────────────────────────────┐     │
│ │ Add notes...                │     │
│ └─────────────────────────────┘     │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │           Done              │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

---

## 7.6 History Tab

### Layout Options

**List View:**
```
┌─────────────────────────────────────┐
│ History                             │
├─────────────────────────────────────┤
│ [List] [Calendar]                   │
├─────────────────────────────────────┤
│ TODAY                               │
│ ┌─────────────────────────────┐     │
│ │ Push Day A                  │     │
│ │ Today • 45 min • 6 exercises│     │
│ │ Bench, Incline, Fly...      │     │
│ └─────────────────────────────┘     │
│                                     │
│ YESTERDAY                           │
│ ┌─────────────────────────────┐     │
│ │ Pull Day                    │     │
│ │ Jan 12 • 52 min • 7 exercises│    │
│ └─────────────────────────────┘     │
└─────────────────────────────────────┘
```

**Calendar View:**
```
┌─────────────────────────────────────┐
│ History                             │
├─────────────────────────────────────┤
│ [List] [Calendar]                   │
├─────────────────────────────────────┤
│        ◀  January 2026  ▶           │
│ Su Mo Tu We Th Fr Sa                │
│        1  2  3  4  5                │
│  6  7  8  9• 10 11 12•              │  ← Dots indicate workouts
│ 13•14 15 16•17 18 19                │
│ ...                                 │
└─────────────────────────────────────┘
```

### Workout Card (History)
- **Title:** Workout name or auto-generated (e.g., "Chest & Triceps")
- **Subtitle:** Date, duration, exercise count
- **Preview:** First 3 exercises with volume
- **Interaction:** Tap for detail, swipe for delete/repeat

---

## 7.7 Exercise Detail Screen

### Layout
```
┌─────────────────────────────────────┐
│ ← Bench Press                       │
├─────────────────────────────────────┤
│ Chest • Barbell                     │
├─────────────────────────────────────┤
│ ┌─────────────────────────────┐     │
│ │         📈 Graph            │     │  ← Line chart
│ │    Weight over time         │     │
│ └─────────────────────────────┘     │
│ [Weight] [Volume] [Est. 1RM]        │  ← Toggle
├─────────────────────────────────────┤
│ History                             │
│                                     │
│ Jan 13, 2026                        │
│   185 × 8  🏆                       │  ← PR badge
│   185 × 7                           │
│   190 × 6                           │
│                                     │
│ Jan 10, 2026                        │
│   180 × 8                           │
│   180 × 8                           │
│   185 × 6                           │
└─────────────────────────────────────┘
```

---

## 7.8 Profile Tab

### Layout
```
┌─────────────────────────────────────┐
│ Profile                             │
├─────────────────────────────────────┤
│ ┌─────────────────────────────┐     │
│ │ 156 Workouts                │     │
│ │ 1.2M lbs Total Volume       │     │
│ │ 🔥 12 Day Streak            │     │
│ └─────────────────────────────┘     │
├─────────────────────────────────────┤
│ SETTINGS                            │
│   Units                    lbs >    │
│   Rest Timer Default       90s >    │
│   Appearance               Auto >   │
├─────────────────────────────────────┤
│ DATA                                │
│   Export Workouts                 > │
│   iCloud Sync              ✓ On     │
├─────────────────────────────────────┤
│ ABOUT                               │
│   Version                    1.0    │
│   Rate FORGE                      > │
│   Send Feedback                   > │
└─────────────────────────────────────┘
```

---

# 8. Data Models

## SwiftData Schema

### Workout

```swift
@Model
class Workout {
    var id: UUID
    var name: String?
    var startTime: Date
    var endTime: Date?
    var notes: String?
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise]
    
    var templateId: UUID?  // If created from template
    
    // Computed
    var duration: TimeInterval? {
        guard let endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var totalVolume: Double {
        exercises.flatMap { $0.sets }
            .filter { $0.completedAt != nil }
            .reduce(0) { $0 + (($1.weight ?? 0) * Double($1.reps ?? 0)) }
    }
}
```

### WorkoutExercise

```swift
@Model
class WorkoutExercise {
    var id: UUID
    var workout: Workout?
    var exercise: Exercise?
    var order: Int
    var notes: String?
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.workoutExercise)
    var sets: [ExerciseSet]
}
```

### ExerciseSet

```swift
@Model
class ExerciseSet {
    var id: UUID
    var workoutExercise: WorkoutExercise?
    var setNumber: Int
    var weight: Double?
    var reps: Int?
    var setType: SetType
    var completedAt: Date?
    var isPersonalRecord: Bool
    
    enum SetType: String, Codable, CaseIterable {
        case warmup
        case working
        case dropSet
        case toFailure
    }
}
```

### Exercise

```swift
@Model
class Exercise {
    var id: UUID
    var name: String
    var muscleGroup: MuscleGroup
    var equipment: Equipment
    var isCustom: Bool
    var isArchived: Bool
    
    enum MuscleGroup: String, Codable, CaseIterable {
        case chest, back, shoulders, biceps, triceps
        case quads, hamstrings, glutes, calves, core, fullBody
    }
    
    enum Equipment: String, Codable, CaseIterable {
        case barbell, dumbbell, cable, machine, bodyweight, other
    }
}
```

### Template

```swift
@Model
class Template {
    var id: UUID
    var name: String
    var createdAt: Date
    var lastUsedAt: Date?
    
    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise]
}
```

### TemplateExercise

```swift
@Model
class TemplateExercise {
    var id: UUID
    var template: Template?
    var exercise: Exercise?
    var order: Int
    var defaultSets: Int
}
```

---

# 9. User Stories

## MVP Stories

| ID | Story |
|----|-------|
| US-001 | As a user, I can start a new workout with one tap so that I can begin logging immediately. |
| US-002 | As a user, I can add exercises to my workout by searching or browsing so that I can build my session on the fly. |
| US-003 | As a user, I can see my previous performance for each exercise so that I know what to beat. |
| US-004 | As a user, I can log a set with weight and reps in 2 taps so that logging doesn't interrupt my workout. |
| US-005 | As a user, I can see green/red arrows indicating if I improved so that progress is immediately obvious. |
| US-006 | As a user, I have a rest timer that auto-starts after completing a set so that I maintain consistent rest periods. |
| US-007 | As a user, I can finish my workout and see a summary so that I know how the session went. |
| US-008 | As a user, I can save a completed workout as a template so that I can repeat it easily. |
| US-009 | As a user, I can view my workout history so that I can track my consistency. |
| US-010 | As a user, I can use the app offline so that basement gyms with no signal still work. |
| US-011 | As a user, I can log sets from my Apple Watch so that I don't need my phone during workouts. |

## V1 Stories

| ID | Story |
|----|-------|
| US-012 | As a user, I can see graphs of my progress per exercise so that I can visualize improvement over time. |
| US-013 | As a user, I get notified when I hit a new personal record so that achievements are celebrated. |
| US-014 | As a user, I can mark sets as warmup, working, or to-failure so that my log is more detailed. |
| US-015 | As a user, I can add notes to exercises so that I remember form cues or issues. |
| US-016 | As a user, I can see which muscles I trained this week on a heatmap so that I ensure balanced training. |
| US-017 | As a user, I can use a plate calculator so that I know which plates to load. |

---

# 10. Success Metrics

## North Star Metric

**Weekly Active Workouts Logged**
The number of workouts logged per user per week.
**Target:** 3+ workouts/week for retained users.

## Key Performance Indicators

| Metric | Target |
|--------|--------|
| Time to First Workout | < 30 seconds from first launch |
| Sets Logged per Session | 15+ average |
| 7-Day Retention | 40%+ |
| 30-Day Retention | 25%+ |
| Template Creation Rate | 30%+ create at least one |
| Watch Engagement | 20%+ of sets logged via Watch |
| App Store Rating | 4.5+ stars |

## Tracking Implementation

Analytics via TelemetryDeck (privacy-focused) or built-in App Analytics.

**Key Events:**
- `workout_started`
- `set_logged`
- `workout_completed`
- `template_created`
- `exercise_added`
- `pr_achieved`

---

# 11. Timeline

## MVP (Week 1-2)

| Days | Focus |
|------|-------|
| 1-3 | Project setup, data models, core navigation, tab bar |
| 4-7 | Active workout screen, exercise cards, set logging, progress arrows |
| 8-10 | Exercise library, search, add exercise sheet |
| 11-12 | Rest timer (with Live Activity), workout summary, save as template |
| 13-14 | History tab, basic settings, TestFlight submission |

## V1 (Week 3-4)

| Days | Focus |
|------|-------|
| 15-17 | Exercise history graphs (Charts framework), PR detection |
| 18-20 | Set types, per-exercise notes, plate calculator |
| 21-22 | Muscle heatmap, polish and bug fixes |
| 23-25 | Apple Watch app (companion + standalone) |
| 26-28 | App Store assets, screenshots, submission |

## Post-Launch (Week 5+)

- User feedback integration
- V2 feature development
- Performance optimization

---

# Appendix A: Default Exercise Library

The app ships with 50+ exercises covering all major muscle groups.

## Chest
- Bench Press
- Incline Bench Press
- Decline Bench Press
- Dumbbell Press
- Incline Dumbbell Press
- Dumbbell Fly
- Cable Fly
- Push-Up
- Chest Dip

## Back
- Deadlift
- Barbell Row
- Dumbbell Row
- Lat Pulldown
- Pull-Up
- Chin-Up
- Seated Cable Row
- T-Bar Row
- Face Pull

## Shoulders
- Overhead Press
- Dumbbell Shoulder Press
- Lateral Raise
- Front Raise
- Rear Delt Fly
- Upright Row
- Arnold Press
- Shrug

## Biceps
- Barbell Curl
- Dumbbell Curl
- Hammer Curl
- Preacher Curl
- Concentration Curl
- Cable Curl

## Triceps
- Tricep Pushdown
- Skull Crusher
- Overhead Tricep Extension
- Dip
- Close-Grip Bench Press
- Tricep Kickback

## Legs (Quads)
- Squat
- Front Squat
- Leg Press
- Leg Extension
- Hack Squat
- Goblet Squat

## Legs (Hamstrings)
- Romanian Deadlift
- Leg Curl
- Stiff-Leg Deadlift
- Good Morning

## Legs (Glutes)
- Hip Thrust
- Bulgarian Split Squat
- Lunge
- Walking Lunge
- Glute Bridge

## Calves
- Standing Calf Raise
- Seated Calf Raise

## Core
- Plank
- Crunch
- Leg Raise
- Cable Crunch
- Ab Wheel Rollout
- Russian Twist
- Hanging Knee Raise

---

# Appendix B: Color System

```swift
extension Color {
    static let forgeAccent = Color("AccentColor")  // System blue or custom
    static let forgeSuccess = Color.green          // Progress up
    static let forgeWarning = Color.red            // Progress down
    static let forgeMuted = Color.secondary        // Previous values
}
```

---

# Appendix C: Haptic Feedback Map

| Action | Haptic Type |
|--------|-------------|
| Set completed | `.success` |
| PR achieved | `.success` (double) |
| Rest timer complete | `.notification` |
| Workout finished | `.success` |
| Delete action | `.warning` |
| Button tap | `.light` |

---

*End of PRD*