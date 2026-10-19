# MessLedger

A digitized university hostel mess credit ledger system.

Students eat first and pay later on credit. MessLedger replaces manual paper ledgers with a modern digital platform comprising a high-performance **FastAPI** backend and an adaptive **Flutter** cross-platform client (Web, Android, Desktop).

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Flutter Client (muet_mess)                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │  Models  │  │Providers │  │ Services │  │   Widgets  │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬──────┘  │
│       │             │             │             │          │
│       ▼             ▼             ▼             ▼          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              ApiClient (Dio + Auth Interceptor)      │  │
│  └────────────────────────────┬─────────────────────────┘  │
└───────────────────────────────│──────────────────────────────┘
                                │ HTTP /api/v1 (REST + Bearer JWT)
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI Backend (backend)                │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌───────┐ │
│  │ Auth    │ │ Dishes  │ │ Entries │ │Payments │ │Summary│ │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └───┬───┘ │
│       │           │           │           │          │       │
│       ▼           ▼           ▼           ▼          ▼       │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              Business Logic Services                    │  │
│  │ (FIFO Allocation, Overdue Checks, Shift Auto-Detection)│  │
│  └────────────────────────────┬───────────────────────────┘  │
│                               ▼                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              SQLAlchemy + SQLite Database               │  │
│  └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Features & Roles

The system operates on a role-based access model with two primary roles: **Student** and **Mess Manager**.

| Feature / Action | Student | Mess Manager |
|------------------|---------|--------------|
| Authentication (JWT) | Yes | Yes |
| View own meal entries and outstanding balance | Yes | — |
| View all students and global records | No | Yes |
| Submit meal entry (self) | Yes (starts `pending`) | — |
| Create meal entry (for any student) | No | Yes (starts `approved`) |
| Edit meal entries | No | Yes |
| Approve / reject pending entries | No | Yes (with mandatory reason) |
| Dispute an entry | Yes (own entry, with reason) | — |
| Resolve disputed entries | No | Yes |
| Record payment | No | Yes |
| Settle single entry as paid | No | Yes |
| Undo recent payment | No | Yes (within 5 minutes) |
| Reopen fully paid entry for modification | No | Yes |
| Manage menu items & pricing | No | Yes |
| View current menu | Yes | Yes |
| Dashboard metrics & summary | Own balance & activity | Mess-wide revenue, overdue counts & totals |

---

## Tech Stack

### Backend (`/backend`)
* **Framework**: FastAPI (Python 3.11+)
* **Server**: Uvicorn
* **Database**: SQLite with SQLAlchemy 2.x ORM
* **Validation**: Pydantic v2 (camelCase JSON aliasing)
* **Authentication**: JWT (JSON Web Tokens) with bcrypt password hashing
* **Timezone**: Evaluated in `Asia/Karachi` timezone

### Frontend (`/muet_mess`)
* **Framework**: Flutter SDK (Material 3)
* **Platforms**: Web, Android, Linux, macOS, Windows
* **State Management**: Provider (`ChangeNotifier`)
* **Routing**: GoRouter (role-based route guards and deep linking)
* **HTTP Client**: Dio with automatic bearer token injection and error handling
* **Design System**: Semantic design tokens, adaptive navigation (bottom bar / nav rail / desktop sidebar), light and dark modes

---

## Repository Structure

```
MessLedger/
├── README.md               # Main project documentation
├── backend/                # FastAPI backend application
│   ├── app/
│   │   ├── main.py         # Application entry point, CORS, routers
│   │   ├── config.py       # Configuration and environment settings
│   │   ├── database.py     # Database engine and session lifecycle
│   │   ├── models.py       # SQLAlchemy ORM models
│   │   ├── schemas.py      # Pydantic request and response schemas
│   │   ├── security.py     # Password hashing and token generation
│   │   ├── dependencies.py # Role authorization guards
│   │   ├── services.py     # Core business logic
│   │   └── routers/        # API endpoints (auth, dishes, entries, payments, dashboard, users)
│   ├── scripts/
│   │   └── seed.py         # Database reset and mock data seeding
│   ├── tests/
│   │   └── test_api_integration.py # Automated integration tests
│   ├── requirements.txt    # Python dependencies
│   ├── .env.example        # Example environment configuration
│   └── API_NOTES.md        # API design and endpoint references
└── muet_mess/              # Flutter client application
    ├── lib/
    │   ├── core/           # Constants, networking, theme, router, utilities
    │   ├── features/       # Screens organized by feature (auth, student, manager, entries, menu, profile)
    │   ├── models/         # Client domain models
    │   ├── providers/      # Application state providers
    │   ├── services/       # API and local service implementations
    │   └── widgets/        # Reusable UI widgets and adaptive shells
    ├── assets/food/        # Food item image assets
    ├── test/               # Unit and widget tests
    └── pubspec.yaml        # Flutter package configuration
```

---

## Core Business Rules

1. **Balance & Ledger Calculation**:
   * Outstanding balance = sum of unpaid expenditure across **approved** entries only.
   * Pending and rejected entries never count toward student balance (pending amounts are displayed separately as "Awaiting Approval").
2. **First-In, First-Out (FIFO) Payment Allocation**:
   * When a manager records a payment, the amount is automatically applied to approved, unpaid entries starting with the oldest.
   * Entries absorb payments up to their remaining balance, setting `paidAt` and `markedPaidBy` when fully settled.
3. **Overdue Meal Entries**:
   * Approved entries unpaid for more than 7 days are automatically marked as overdue.
4. **Shift Detection**:
   * Timestamps are categorized by shift:
     * **Breakfast**: 06:00 – 10:59
     * **Lunch**: 11:00 – 16:59
     * **Dinner**: 17:00 – 23:59 and 00:00 – 05:59
5. **Payment Undo Window**:
   * Managers can reverse an accidental payment within **5 minutes** of recording. Reversing restores the previous entry balances in a single transaction.
6. **Immutable Pricing Snapshots**:
   * Dish prices are captured at the moment a meal entry is created. Subsequent menu price adjustments only apply to future entries.

---

## Getting Started

### 1. Prerequisites
* **Python**: 3.11+
* **Flutter**: 3.5.0+
* **Git**

---

### 2. Backend Setup

```bash
cd backend

# Create and activate a virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env

# Initialize and seed database with demo data
python -m scripts.seed --reset

# Run development server
python -m app.main
```

The API will be available at:
* **Base URL**: `http://localhost:8000/api/v1`
* **Interactive API Docs (Swagger UI)**: `http://localhost:8000/docs`
* **Health Check**: `http://localhost:8000/health`

---

### 3. Frontend Setup

In a new terminal:

```bash
cd muet_mess

# Fetch Flutter dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit tests
flutter test

# Launch the app
flutter run
```

To run on Google Chrome:
```bash
flutter run -d chrome
```

---

## Demo Credentials

After running `python -m scripts.seed --reset`, the database is populated with the following demo accounts:

| Role | Username | Password |
|------|----------|----------|
| **Mess Manager** | `manager` | `manager123` |
| **Student** | `ahmedkhan` | `student123` |
| **Student** | `fatimaali` | `student123` |
| **Student** | `hassanahmed` | `student123` |
| **Student** | `zaramalik` | `student123` |

---

## Network Configuration for Devices

* **Web / Desktop / Localhost**: Connects to `http://localhost:8000/api/v1`
* **Android Emulator**: Uses `http://10.0.2.2:8000/api/v1` (automatically resolved)
* **Physical Device**: Update the host IP in the network configuration to your workstation's local LAN IP (e.g., `http://192.168.1.x:8000/api/v1`).

---

## API Summary

| Category | Endpoint | Method | Role | Description |
|----------|----------|--------|------|-------------|
| **Auth** | `/auth/login` | `POST` | Public | Authenticate with username and password |
| | `/auth/me` | `GET` | Authenticated | Retrieve current user profile |
| **Menu** | `/dishes` | `GET` | Authenticated | List available dishes by shift and category |
| | `/dishes` | `POST` | Manager | Create new menu item |
| | `/dishes/{id}` | `PATCH` | Manager | Update dish pricing, availability, or shifts |
| **Entries** | `/entries` | `GET` | Authenticated | List entries (students view self; managers view all) |
| | `/entries` | `POST` | Authenticated | Submit entry (student: pending, manager: approved) |
| | `/entries/{id}` | `GET` | Authenticated | View entry details and itemized breakdown |
| | `/entries/{id}` | `PATCH` | Manager | Modify dishes/quantities in an entry |
| | `/entries/{id}/approve` | `POST` | Manager | Approve a pending entry |
| | `/entries/{id}/reject` | `POST` | Manager | Reject a pending entry with mandatory reason |
| | `/entries/{id}/dispute` | `POST` | Student | Flag own entry as disputed |
| | `/entries/{id}/resolve-dispute` | `POST` | Manager | Resolve an entry dispute |
| | `/entries/{id}/mark-paid` | `POST` | Manager | Settle a specific entry's outstanding balance |
| | `/entries/{id}/reopen` | `POST` | Manager | Reopen a fully paid entry |
| **Students** | `/students` | `GET` | Manager | List students with outstanding balances |
| | `/students/{id}` | `GET` | Manager / Self | View student account profile |
| **Payments** | `/students/{id}/payments` | `POST` | Manager | Record payment and apply FIFO allocation |
| | `/students/{id}/payment-preview` | `GET` | Manager | Preview entry allocation before committing payment |
| | `/students/{id}/payments` | `GET` | Manager / Self | List payment transaction history |
| | `/payments/{id}/undo` | `POST` | Manager | Reverse payment within 5 minutes |
| **Dashboard** | `/dashboard/summary` | `GET` | Manager | Overview metrics, overdue count, top defaulters |
| | `/me/summary` | `GET` | Student | Personal ledger summary, balances, recent activity |
| **Health** | `/health` | `GET` | Public | System health check (`{"status":"ok"}`) |

---

## License

This project is developed for hostel mess credit and dining ledger management.
