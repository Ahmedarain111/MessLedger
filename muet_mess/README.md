# University Hostel Mess Khata Management System

A Flutter (Dart) frontend for managing student mess credit accounts ("Khatas") across the
university's hostels. Students log meals, managers approve them and record payments, and
the warden-facing read restrictions are replaced by a strict two-role model (Student /
Mess Manager) with hostel isolation.

The backend will be built separately with Django REST Framework. All UI code goes through
services (`lib/services/`) which currently read/write an in-memory mock repository
(`lib/services/mock/`). Swapping in the Django API means replacing those services —
no widget changes required.

## Features

- Email/password login, student & manager registration, logout, session restore
- Role-based route guards (students cannot reach manager screens and vice versa)
- Exactly two roles: Student, Mess Manager. Manager belongs to exactly one hostel.
- Student can hold Khatas at multiple hostels (one Khata per student+hostel)
- Khata ledger table: Date | Breakfast | Lunch | Dinner | Daily Total, cells clickable
- Reusable month filter (Student & Manager)
- Today's menu only for students; menu editor for managers (hostel-specific)
- Official university food list with distinct items/prices (incl. both "Beef Qourma" entries)
- Meal entry with checkboxes and live total; pending/approved/rejected statuses
- Manager approval, rejection (with reason), and editing of approved meals (mandatory reason)
- Immutable per-meal update history (who, when, reason, old/new items & amounts)
- Payments separate from meals; Total Paid only changes via payments
- Balance = Total Paid − Approved Expenditure (pending/rejected never count)
- Soft-close of Khatas with reason; history preserved
- Notifications model/provider/screen for submission/approval/updates
- Compact, responsive dashboards (mobile bottom nav, tablet rail, desktop side nav)
- Light & dark themes, centralized design tokens
- Demo data covering pending/approved/rejected meals, updated meals, positive/zero/negative balances

## Architecture

```
Screen → Provider → Service → (MockRepository | ApiClient → Django REST API)
```

- `lib/core/` — constants, theme, routes (go_router), network (dio ApiClient), storage, utils
- `lib/models/` — plain data classes
- `lib/services/` — auth/student/manager/hostel/khata/menu/meal/payment/notification/dashboard services + `mock/` seed data
- `lib/providers/` — ChangeNotifier-based state (Provider package)
- `lib/widgets/` — shared widgets & adaptive navigation shell
- `lib/features/` — feature screens per role

## Packages

`provider`, `go_router`, `dio`, `intl`, `uuid`, `cached_network_image` (+ `flutter_lints`, `flutter_test`).

> Note: `shared_preferences` was replaced by a local JSON-file store
> (`lib/core/storage/`) because plugin symlinks require Developer Mode on this
> Windows machine. The storage interface mirrors SharedPreferences.

## Demo accounts

| Role    | Email               | Password     |
|---------|---------------------|--------------|
| Student | student@test.com    | password123  |
| Manager | manager@test.com    | password123  |

More seeded accounts exist in `lib/services/mock/mock_database.dart` (e.g.
`manager2@test.com` … `manager5@test.com`, `ayesha@test.com`, `bilal@test.com`).

## Run

```bash
flutter pub get
flutter run            # pick a device (web, windows, android, ios)
flutter test           # business-rule unit tests
flutter analyze        # static analysis (clean)
flutter build web      # production web build into build/web
```

Food images in `assets/food/` are distinct generated placeholders (`tools/gen_assets.dart`
to regenerate). Replace with real photos keeping the same filenames.

## Connecting the Django backend later

1. Implement each service in `lib/services/` against `ApiClient` (base URL in
   `lib/core/constants/app_constants.dart`, endpoints in `api_endpoints.dart`).
2. Expected endpoints: `/auth/login/`, `/auth/register/`, `/hostels/`, `/students/`,
   `/managers/`, `/khatas/`, `/menus/`, `/meals/`, `/payments/`, `/notifications/`,
   `/reports/`.
3. The backend must enforce hostel isolation server-side (Flutter restrictions are not security).

## Testing

`test/business_rules_test.dart` covers: meal total calculation, multiple selection,
payments separate from meals, pending meals not affecting expenditure, rejected meals not
affecting expenditure, approved updates changing expenditure with preserved history,
mandatory update/close reasons, and duplicate student+hostel Khata prevention.
