# BVCEC SmartQueue

A campus queue-management system for Bonam Venkata Chalamayya Engineering College (Autonomous), Odalarevu, Andhra Pradesh.

**B.Tech Laboratory Project** — Flutter / Dart

---

## Overview

BVCEC SmartQueue allows students to join virtual queues for campus services instead of waiting physically at counters. Staff manage queue flow from a dedicated counter screen, and administrators configure service centers, services, and counters.

---

## Features

### Student
- Login with registration number + password
- Browse all service centers (Examination, Library, Accounts, etc.)
- Select a service and join the queue
- Get a digital token with real-time position tracking
- See estimated waiting time (adaptive EWT algorithm)
- Cancel queue entry
- View queue history

### Staff
- Login and select assigned counter
- Real-time queue view (auto-updates via Supabase Realtime)
- Call Next → Start Service → Complete
- Mark No-Show for absent students

### Administrator
- Manage service centers (add, activate/deactivate)
- Manage services per center (add, configure duration, toggle)
- Manage counters (add, assign staff, update status)
- Analytics dashboard (last 30 days: throughput, avg service time, rates)

---

## Setup

### 1. Supabase Project

1. Go to [supabase.com](https://supabase.com) → New Project
2. Open **SQL Editor** and run `supabase_schema.sql` (in project root)
3. Copy your **Project URL** and **anon key** from Settings → API

### 2. Configure Credentials

Open `lib/core/constants/supabase_constants.dart`:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';     // ← paste here
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY'; // ← paste here
```

> ⚠️ Never commit real credentials to a public repository.

### 3. Generate Freezed Models

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Run the App

```bash
# Android
flutter run

# Windows
flutter run -d windows
```

---

## Architecture

```
lib/
├── core/                  # Constants, theme, router, extensions, utils
│   ├── constants/         # Supabase table names & credentials
│   ├── providers/         # Root Riverpod providers
│   ├── router/            # GoRouter with role-based guards
│   ├── theme/             # Dark theme (Inter font, teal/navy palette)
│   ├── utils/             # EwtCalculator (business logic, no Flutter deps)
│   └── errors/            # Typed exception hierarchy
├── data/
│   ├── models/            # Freezed immutable models (all domain entities)
│   └── repositories/      # Supabase-backed data access
├── domain/
│   └── queue_state_machine.dart  # All valid state transitions enforced
└── features/
    ├── auth/              # Login + registration
    ├── student/           # Home, service list, queue screen, history
    ├── staff/             # Counter screen (live queue management)
    └── admin/             # Dashboard, service centers, services, counters, analytics
```

Pattern: **View → Riverpod Provider → Repository → Supabase**

---

## Queue State Machine

```
WAITING ──► CANCELLED
WAITING ──► CALLED
CALLED  ──► NO_SHOW
CALLED  ──► SERVING
SERVING ──► COMPLETED
SERVING ──► TRANSFERRED
```

Invalid transitions throw `InvalidStateTransitionException`.

---

## EWT Algorithm

**Exponential Smoothing** (adaptive prediction):

```
newAvg = α × actualDuration + (1 - α) × previousAverage
```

- α = 0.3 *(PROTOTYPE ASSUMPTION — tune after collecting real data)*
- EWT per student = `(customersAhead / activeCounters) × avgDuration`
- MAE should be measured to evaluate prediction accuracy

---

## Technology Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter / Dart |
| State Management | Riverpod 2.x |
| Navigation | GoRouter |
| Models | Freezed + json_serializable |
| Backend | Supabase (PostgreSQL + Realtime + Auth) |
| Notifications | flutter_local_notifications (in-app) |
| Charts | fl_chart |
| Fonts | Google Fonts (Inter) |

---

## Running Tests

```bash
flutter test
```

Tests cover:
- Queue state machine (all valid and invalid transitions)
- EWT calculator (estimates, exponential smoothing convergence)
- QueueEntryStatus parsing

---

## Known Prototype Assumptions

| Assumption | Location | Action Needed |
|---|---|---|
| α = 0.3 for EWT smoothing | `ewt_calculator.dart` | Tune from real data |
| Estimated service durations | DB seed / admin UI | Update from actual measurements |
| Auth uses `@bvcec.internal` domain | `auth_repository.dart` | Keep for prototype |
| Staff account creation requires Supabase dashboard | `counter_repository.dart` | Implement admin-side user creation |
| Synthetic/seeded data for testing | `supabase_schema.sql` | Label clearly in report |

---

## Academic Notes

- **No blockchain, cryptocurrency, face recognition, AR, IoT, or generic chatbots** — excluded per project requirements
- Waiting-time prediction uses a documented algorithm with measurable error (MAE)
- All state transitions are enforced server-side via RLS policies
- Architecture supports explanation at viva: View → Provider → Repository → Backend
