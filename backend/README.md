# MessLedger Backend

FastAPI backend for the MessLedger hostel mess credit ledger system.

## Quick Start

### Prerequisites
- Python 3.11+
- pip

### Setup

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env

# Seed database (creates manager + 4 students + menu)
python -m scripts.seed --reset

# Run server
python -m app.main
```

Server runs at `http://0.0.0.0:8000`. API docs at `http://0.0.0.0:8000/docs`.

### Default Credentials

| Role | Username | Password |
|------|----------|----------|
| Manager | `manager` | `manager123` |
| Students | `ahmedkhan`, `fatimaali`, `hassanahmed`, `zaramalik` | `student123` |

### Android Emulator Access
Use `http://10.0.2.2:8000` instead of `localhost`.

### Physical Device Access
Use your laptop's LAN IP (e.g., `http://192.168.1.x:8000`).

## Project Structure

```
backend/
├── app/
│   ├── main.py           # FastAPI app, CORS, routers, error handlers
│   ├── config.py         # Settings via pydantic-settings
│   ├── database.py       # SQLAlchemy engine, session, init_db
│   ├── security.py       # JWT, bcrypt password hashing
│   ├── dependencies.py   # get_current_user, require_roles
│   ├── models.py         # SQLAlchemy models
│   ├── schemas.py        # Pydantic request/response schemas
│   ├── services.py       # Business logic (totals, allocation, undo, shift, overdue)
│   └── routers/          # API endpoints
│       ├── auth.py       # Login, /me
│       ├── dishes.py     # Menu CRUD
│       ├── users.py      # Student listing
│       ├── entries.py    # Meal entries CRUD + actions
│       ├── payments.py   # Payment recording, preview, undo
│       └── dashboard.py  # Summary endpoints
├── scripts/
│   └── seed.py           # Database seeding
├── requirements.txt
├── .env.example
├── AGENTS.md
├── LOG.md
└── API_NOTES.md
```

## API Endpoints

Base path: `/api/v1`

### Auth
- `POST /auth/login` - Login, returns JWT
- `GET /auth/me` - Current user profile

### Users (Manager)
- `GET /students` - List students (search, sort, pagination)
- `GET /students/{id}` - Get student (manager or self)

### Menu
- `GET /dishes` - List dishes (filter by shift, category)
- `POST /dishes` - Create dish (manager)
- `PATCH /dishes/{id}` - Update dish (manager)

### Entries
- `GET /entries` - List entries (filters, pagination)
- `GET /entries/{id}` - Get entry
- `POST /entries` - Create entry (student=pending, manager=approved)
- `PATCH /entries/{id}` - Update entry (manager)
- `POST /entries/{id}/approve` - Approve pending entry (manager)
- `POST /entries/{id}/reject` - Reject pending entry (manager)
- `POST /entries/{id}/dispute` - Flag as disputed (student, own)
- `POST /entries/{id}/resolve-dispute` - Resolve dispute (manager)
- `POST /entries/{id}/mark-paid` - Mark entry paid (manager)
- `POST /entries/{id}/reopen` - Reopen fully paid entry (manager)

### Payments (Manager)
- `POST /students/{id}/payments` - Record payment
- `GET /students/{id}/payment-preview?amount=` - Preview allocation
- `GET /students/{id}/payments` - List payments (manager or self)
- `POST /payments/{id}/undo` - Undo payment (within 5 min)

### Dashboard
- `GET /dashboard/summary` - Full dashboard (manager)
- `GET /dashboard/me/summary` - Own summary (student)

### Health
- `GET /health` - Health check (no auth)

## Business Rules Summary

- **Money**: Integer rupees (no decimals)
- **Timestamps**: UTC, ISO 8601 with Z
- **IDs**: UUID strings
- **Shift detection**: Asia/Karachi timezone (breakfast 6-10, lunch 11-16, dinner 17-23 + 0-5)
- **Payment allocation**: Oldest approved entries first
- **Overdue**: Approved, non-paid entry > 7 days old
- **Undo window**: 5 minutes for payments
- **Student backdate limit**: 24 hours
- **Entry statuses**: pending → approved/rejected (no reverse)
- **Dishes**: Soft delete only (is_available flag)

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SECRET_KEY` | change-me... | JWT signing key |
| `DATABASE_URL` | sqlite:///./mess_ledger.db | SQLite path |
| `TOKEN_HOURS` | 12 | JWT expiry |

## Development

```bash
# Reset and re-seed database
python -m scripts.seed --reset

# Run with auto-reload
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Error Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR|INVALID_CREDENTIALS|FORBIDDEN|NOT_FOUND|CONFLICT|HTTP_ERROR",
    "message": "Human readable message",
    "details": null
  }
}
```

## Pagination

List endpoints accept `limit` (default 50, max 200) and `offset`. Response:
```json
{
  "items": [...],
  "total": 100,
  "limit": 50,
  "offset": 0
}
```

Entries sorted newest first.