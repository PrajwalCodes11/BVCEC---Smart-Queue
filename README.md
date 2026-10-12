# BVCEC SmartQueue

<p align="center">
  <strong>Intelligent Campus Queue & Resource Management System</strong><br>
  Bonam Venkata Chalamayya Engineering College (Autonomous), Odalarevu, Andhra Pradesh
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase" alt="Supabase" />
  <img src="https://img.shields.io/badge/State_Management-Riverpod_2.x-00599C" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Platform-Windows%20|%20Android-green" alt="Platforms" />
</p>

---

## 📌 Overview

**BVCEC SmartQueue** transforms traditional physical line waiting at college service counters into a streamlined, real-time digital experience. Students can join virtual queues from anywhere on campus, track their position and estimated wait times in real time, while staff and administrators manage queue flow and monitor throughput with comprehensive operational analytics.

---

## 📦 Direct Downloads & Testing (Android & Windows)

Official standalone release binaries are hosted on GitHub Releases for one-click downloading and testing across different mobile phones and PCs:

| Platform | Direct Download Link | Size | Instructions |
|:---|:---|:---|:---|
| 📱 **Android (Mobile Phones)** | [**⬇️ Download `app-release.apk` (Latest)**](https://github.com/PrajwalCodes11/BVCEC---Smart-Queue/releases/latest/download/app-release.apk) | 55.3 MB | 1. Click to download on your phone.<br>2. Tap to install (allow *"Install unknown apps"* if prompted).<br>3. Launch and test the native Android app! |
| 💻 **Windows (Other PCs)** | [**⬇️ Download `smartqueue-windows-x64.zip` (Latest)**](https://github.com/PrajwalCodes11/BVCEC---Smart-Queue/releases/latest/download/smartqueue-windows-x64.zip) | 12.8 MB | 1. Download and extract the ZIP folder on any Windows PC.<br>2. Double-click `smartqueue.exe` to run immediately.<br>*(Zero prerequisites — no Flutter or Visual Studio needed!)* |
| 🌐 **Local Wi-Fi Browser Testing** | Local Web Server | — | 1. Run `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080`<br>2. On any phone or laptop on the same Wi-Fi, open `http://<YOUR_PC_IP>:8080`<br>*(Zero install, instant multi-device testing)* |

> [!NOTE]
> View all release notes and assets directly on the [**GitHub Releases Page (Latest)**](https://github.com/PrajwalCodes11/BVCEC---Smart-Queue/releases/latest).

---

## ✨ Features by Role

### 🎓 Student Portal
- **Zero-Friction Authentication**: Login using Registration / Roll Number and password.
- **Service Center Directory**: Browse campus centers (Examination Section, Accounts, Library, etc.) and active services.
- **Digital Token & Live Tracking**: Real-time position updates, ticket receipt, and status tracking powered by Supabase Realtime.
- **Predictive EWT**: Dynamic Estimated Waiting Time calculated using exponential smoothing based on historical service duration and active counter throughput.
- **Queue Controls & History**: Cancel active tokens and review previous service records with full session timestamps.
- **Profile Management**: View and update academic profile details.

### 💼 Staff Console
- **Dedicated Counter Workspace**: Staff log in and connect to their assigned service counter.
- **Real-Time Stream**: Live student list updating instantly upon queue arrivals and cancellations.
- **State Machine Workflow**: Controlled transitions (`Call Next` ➔ `Start Service` ➔ `Complete` / `No-Show` / `Transfer`).
- **Counter Status Toggle**: Pause or open counters dynamically.

### 🛡️ Administrator Suite
- **Live Campus Queue Monitor**: Real-time overview of active waiting and serving students across all centers.
- **Center, Service & Counter Management**: Create, toggle active states, configure estimated durations, and assign staff to counters.
- **Advanced Operations Analytics**:
  - **Date Range Filters**: Inspect 7-day, 30-day, or 90-day periods.
  - **Campus-Wide or Per-Center**: Toggle between overall campus metrics and specific center performance.
  - **Interactive Bar Chart (`fl_chart`)**: Daily throughput comparing total tickets vs completed sessions with touch tooltips.
  - **Peak Hours Heatmap**: 24-hour arrival density histogram pinpointing rush periods.
  - **Wait & Service Time Metrics**: Average and maximum student wait times and service durations.
  - **Per-Service Performance**: Granular cards showing total volume, completion progress bars, cancellations, and no-shows.
  - **Operational Rates**: Completion rate, cancellation rate, and no-show rate indicators.

---

## 🏛️ System Architecture

The application is built using **Clean Architecture** patterns separating UI presentation, domain logic, state management, and data sources:

```
lib/
├── core/
│   ├── constants/             # Supabase credentials & table definitions
│   ├── errors/                # Strongly-typed application exceptions
│   ├── extensions/            # Helper extensions on core types
│   ├── providers/             # Root Riverpod providers
│   ├── router/                # GoRouter with role-based auth guards
│   ├── services/              # Local notification dispatcher
│   ├── theme/                 # Dark aesthetic theme (Inter typography & teal accents)
│   └── utils/                 # EwtCalculator (isolated exponential smoothing engine)
├── data/
│   ├── models/                # Immutable Freezed domain entities & JSON serialization
│   └── repositories/          # Supabase data repositories (Auth, Queue, Service, Counter)
├── domain/
│   └── queue_state_machine.dart  # Strict state transition validator
├── features/
│   ├── admin/presentation/    # Admin dashboard, management CRUD, and analytics
│   ├── auth/presentation/     # Multi-tab unified authentication & registration
│   ├── profile/presentation/  # User profile & credentials management
│   ├── staff/presentation/    # Counter dispatch console
│   └── student/presentation/  # Virtual queuing, status screens, and history
└── shared/widgets/            # Reusable UI cards, inputs, and indicators
```

### Queue State Machine
All queue state transitions are verified through `QueueStateMachine` to ensure business integrity:
```
WAITING    ──►  CALLED    ──►  SERVING    ──►  COMPLETED
   │                │                │
   └──► CANCELLED   └──► NO_SHOW     └──► TRANSFERRED
```

---

## 🗄️ Database & Backend (`supabase/`)

Database scripts are structured sequentially inside the [`supabase/`](./supabase/) directory:

| Script | Purpose |
|---|---|
| [`01_schema.sql`](./supabase/01_schema.sql) | Tables, views, triggers, and Row Level Security (RLS) policies. |
| [`02_register_rpc.sql`](./supabase/02_register_rpc.sql) | Hardened PostgreSQL RPC function enabling direct student & staff signups without email rate limits. |
| [`03_seed_users.sql`](./supabase/03_seed_users.sql) | Seeds campus service centers, services, counters, and default testing accounts. |
| [`04_fix_auth_users.sql`](./supabase/04_fix_auth_users.sql) | Maintenance script to clean up or reset authentication records cleanly. |

### Default Credentials (from Seed)
| Role | Identifier | Password | Access |
|---|---|---|---|
| **Admin** | `admin@bvcec.edu.in` | `Admin@123` | Full admin dashboard, analytics, and management |
| **Staff (Exam)** | `STF001` | `Staff@123` | Examination Section counter |
| **Staff (Accounts)** | `STF002` | `Staff@123` | Accounts Section counter |
| **Student** | `21BV1A0501` | `Student@123` | Student queue portal |

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK** (`>= 3.13.0`)
- **Dart SDK** (`>= 3.1.0`)
- A **Supabase** project account ([supabase.com](https://supabase.com))

### 1. Database Setup
1. In your Supabase Project dashboard, open the **SQL Editor**.
2. Run [`supabase/01_schema.sql`](./supabase/01_schema.sql).
3. Run [`supabase/02_register_rpc.sql`](./supabase/02_register_rpc.sql).
4. Run [`supabase/03_seed_users.sql`](./supabase/03_seed_users.sql).

### 2. Configure Credentials
Update `lib/core/constants/supabase_constants.dart` with your Supabase URL and anon public key:

```dart
class SupabaseConstants {
  static const String supabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_PUBLIC_KEY';
}
```

### 3. Generate Freezed Code
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run the Application
```bash
# Windows Desktop
flutter run -d windows

# Android Device / Emulator
flutter run -d android
```

### 5. Running Tests
```bash
flutter test
```

---

## 📊 Estimated Waiting Time (EWT) Formula

The waiting time predictor utilizes **single exponential smoothing** to adapt to counter speed dynamically without extreme volatility:

$$\overline{T}_{k} = \alpha \cdot T_{\text{actual}} + (1 - \alpha) \cdot \overline{T}_{k-1}$$

$$\text{EWT} = \frac{\text{Ahead in Queue}}{\text{Active Counters}} \times \overline{T}_{k}$$

- $\alpha = 0.3$: Balanced smoothing factor between recent transactions and historical averages.
- Handles multiple concurrent open counters per service.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **Language**: [Dart](https://dart.dev)
- **State Management**: [Riverpod 2.x](https://riverpod.dev)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **Data Serialization**: [Freezed](https://pub.dev/packages/freezed) & [json_serializable](https://pub.dev/packages/json_serializable)
- **Database & Realtime**: [Supabase](https://supabase.com)
- **Charts & Data Viz**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Design System**: Custom Dark Theme, Inter typography, responsive layouts

---

## 📄 License
Developed for academic evaluation at **Bonam Venkata Chalamayya Engineering College (Autonomous)**. All rights reserved.
