# SmartQueue

<p align="center">
  <strong>Intelligent Campus Queue &amp; Resource Management System</strong><br>
  Bonam Venkata Chalamayya Engineering College (Autonomous), Odalarevu, Andhra Pradesh
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase" alt="Supabase" />
  <img src="https://img.shields.io/badge/State_Management-Riverpod_2.x-00599C" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Android-green" alt="Platforms" />
  <img src="https://img.shields.io/badge/Tests-32%20Passing-brightgreen" alt="Tests" />
</p>

---

## 📌 Overview

**SmartQueue** eliminates physical line waiting at college service counters by providing a real-time digital queue management platform. Students join virtual queues from anywhere on campus and track their position live, while staff manage the counter workflow and administrators monitor throughput with built-in analytics.

---

## 📦 Direct Downloads

Official release binaries are hosted on GitHub Releases and are ready to install with zero prerequisites:

| Platform | Direct Download | Size | Install Instructions |
| :--- | :--- | :--- | :--- |
| 📱 **Android** | [⬇️ Download `app-release.apk`](https://github.com/PrajwalCodes11/BVCEC---Smart-Queue/releases/latest/download/app-release.apk) | ~55 MB | Download on your phone → Tap to install → Allow *"Install unknown apps"* if prompted → Launch |
| 💻 **Windows** | [⬇️ Download `smartqueue-windows-x64.zip`](https://github.com/PrajwalCodes11/BVCEC---Smart-Queue/releases/latest/download/smartqueue-windows-x64.zip) | ~13 MB | Download → Extract ZIP → Double-click `smartqueue.exe` *(No Flutter or Visual Studio required)* |

> [!NOTE]
> All releases and changelogs are on the [**GitHub Releases page**](https://github.com/PrajwalCodes11/BVCEC---Smart-Queue/releases/latest).

---

## 🧪 Testing the App — Default Credentials

Use these seeded accounts to test all roles immediately after installing:

| Role | Login ID | Password | Portal Access |
| :--- | :--- | :--- | :--- |
| **Admin** | `ADMIN001` | `password123` | Full dashboard, analytics, center & counter management |
| **Staff (Exam)** | `STAFF001` | `password123` | Examination Section counter workspace |
| **Staff (Accounts)** | `STAFF002` | `password123` | Accounts Section counter workspace |
| **Student** | `22A61A0501` | `password123` | Student queue portal, live tickets & history |

> [!TIP]
> To test the full workflow: sign in as **Student** to join a queue → switch to **Staff** to call and serve the token → switch to **Admin** to view the analytics update.

---

## ✨ Features by Role

### 🎓 Student Portal

- **Flexible Authentication** — Log in with Registration Number, Roll Number, Staff ID, or Email.
- **Self-Registration** — Students can register new accounts directly from the login screen.
- **Service Center Directory** — Browse all active campus centers (Examination, Accounts, Library, etc.) and their services.
- **Digital Queue Token** — Join any service queue instantly and receive a numbered token.
- **Live Position Tracking** — Real-time queue position updates via Supabase Realtime streaming.
- **Predictive EWT** — Estimated Wait Time shown using exponential smoothing based on live counter throughput.
- **In-App Call Notifications** — Snack bar alert and push notification when your token is called to the counter.
- **Active Tickets Panel** — See all currently active tokens across all services in one screen.
- **Queue History** — Full history of past tokens: Completed, Cancelled, No-Show, and Transferred — filterable by status.
- **Token Cancellation** — Cancel a waiting token at any time before being called.
- **Profile Management** — View and update full name, email, phone, department, and year of study.

### 💼 Staff Console

- **Counter Workspace** — Dedicated full-screen operational desk once a counter is selected.
- **Desk Selection** — Staff choose their active service counter from all available counters in their assigned center.
- **Real-Time Queue Stream** — Live list of waiting, called, and serving students; updates instantly without manual refresh.
- **State Machine Workflow** — Strictly enforced transitions: `Call Next` → `Start Service` → `Complete` / `No-Show` / `Transfer`
- **Counter Status Control** — Toggle counter between `Available`, `Paused`, and `Offline` dynamically.
- **Switch Desk** — Move to a different counter; previous assignment is atomically released in the database.
- **Today's Completed Log** — Scrollable record of all tickets served in the current session.
- **Performance Report** — Per-shift stats: total served, average service duration, and no-show count.
- **Department Queue Monitor** — View queue depth across all services in the assigned center.

### 🛡️ Administrator Suite

- **Live Campus Monitor** — Real-time dashboard: total waiting, being served, counters active, today's completions.
- **Service Centers Management** — Create, edit, toggle active/inactive, and delete campus service centers.
- **Services Management** — Add, edit, configure estimated durations, and toggle services within any center.
- **Counters Management** — Create counters, assign staff, and change counter statuses per center.
- **Staff Desks Roster** — View which staff members are assigned to which counters right now.
- **Live Student Queues** — Campus-wide student token list with status, position, and counter details.
- **Analytics & Reports** (date range: 7 / 30 / 90 days, campus-wide or per-center):
  - Interactive bar chart of daily throughput (total vs. completed)
  - Peak-hour heatmap (24-hour arrival density)
  - Average and maximum wait times and service durations
  - Per-service completion, cancellation, and no-show rates
  - Detailed per-service performance cards with progress indicators

---

## 🏛️ System Architecture

The application uses **Clean Architecture** to separate presentation, domain logic, state management, and data access:

```
lib/
├── core/
│   ├── constants/             # Supabase URL, anon key & table names
│   ├── errors/                # Typed exceptions (AuthException, NetworkException, QueueException)
│   ├── extensions/            # Dart extensions on core types
│   ├── providers/             # Root Riverpod providers & AuthNotifier state machine
│   ├── router/                # GoRouter with role-based auth redirect guards
│   ├── services/              # Local notification dispatcher (token called alerts)
│   ├── theme/                 # Dark theme + Creamy White theme (Inter typography)
│   └── utils/                 # EwtCalculator — isolated exponential smoothing engine
├── data/
│   ├── models/                # Immutable Freezed entities with JSON serialization
│   └── repositories/          # Supabase repositories: Auth, Queue, Service, Counter
├── domain/
│   └── queue_state_machine.dart  # Strict state-transition validator & CounterStatus enum
├── features/
│   ├── admin/presentation/    # Dashboard, CRUD management screens, analytics
│   ├── auth/                  # Login + self-registration (data & presentation layers)
│   ├── profile/presentation/  # Profile view & edit screen
│   ├── staff/presentation/    # Counter dispatch workspace (CounterScreen)
│   └── student/presentation/  # Home, service list, live queue ticket, history
└── shared/widgets/            # AppDrawer, common loading/error/empty widgets
```

### Queue State Machine

All transitions are verified by `QueueStateMachine` before any database write:

```
WAITING ──► CALLED  ──► SERVING ──► COMPLETED
  │             │            │
  └─► CANCELLED  └─► NO_SHOW  └─► TRANSFERRED
```

---

## 🗄️ Database Schema (`supabase/`)

| Script | Purpose |
| :--- | :--- |
| [`01_schema.sql`](./supabase/01_schema.sql) | All tables, RLS policies, Realtime enablement, and performance indexes |
| [`02_register_rpc.sql`](./supabase/02_register_rpc.sql) | PostgreSQL RPC for self-registration without email rate limits |
| [`03_seed_users.sql`](./supabase/03_seed_users.sql) | Seeds service centers, services, counters, and default test accounts |
| [`04_fix_auth_users.sql`](./supabase/04_fix_auth_users.sql) | Maintenance script to reset or clean up auth identity records |

**Tables:** `users`, `service_centers`, `services`, `counters`, `queues`, `queue_entries`, `queue_events`, `service_sessions`, `ewt_stats`

**Realtime enabled on:** `queue_entries`, `counters`, `queues`

---

## 🚀 Developer Setup

### Prerequisites

- Flutter SDK `>= 3.13.0` / Dart SDK `>= 3.1.0`
- A Supabase project ([supabase.com](https://supabase.com))

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/PrajwalCodes11/BVCEC---Smart-Queue.git
cd BVCEC---Smart-Queue

# 2. Install dependencies & generate Freezed code
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 3. Configure Supabase (lib/core/constants/supabase_constants.dart)
#    Replace supabaseUrl and supabaseAnonKey with your project values

# 4. Run the database scripts in Supabase SQL Editor (in order):
#    01_schema.sql → 02_register_rpc.sql → 03_seed_users.sql

# 5. Launch the app
flutter run -d windows   # Windows Desktop
flutter run -d android   # Android device / emulator

# 6. Run the test suite
flutter test             # 32 unit & state machine tests
flutter analyze          # Must show: No issues found
```

> [!TIP]
> For multi-device testing without installing: `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080` then open `http://<PC_IP>:8080` on any device on the same Wi-Fi.

---

## 📊 EWT Formula

The wait-time predictor uses **single exponential smoothing** (α = 0.3):

$$\overline{T}_{k} = 0.3 \times T_{\text{actual}} + 0.7 \times \overline{T}_{k-1}$$

$$\text{EWT} = \left\lceil \frac{\text{Position} - 1}{\text{Active Counters}} \times \overline{T}_{k} \right\rceil$$

Handles multiple concurrent open counters per service. Stored and updated per-service in the `ewt_stats` table.

---

## 🛠️ Tech Stack

| Layer | Technology |
| :--- | :--- |
| Framework | Flutter 3.x |
| Language | Dart 3.x |
| State Management | Riverpod 2.x |
| Navigation | GoRouter |
| Backend & Realtime | Supabase (PostgreSQL + Realtime) |
| Data Models | Freezed + json_serializable |
| Charts | fl_chart |
| Notifications | flutter_local_notifications |
| Typography | Google Fonts — Inter |

---

## 📄 License

Developed for academic evaluation at **Bonam Venkata Chalamayya Engineering College (Autonomous)**. All rights reserved.
