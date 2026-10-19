# MessLedger API Notes

## Overview
This document records API design decisions, conventions, and changes for the MessLedger backend.

## Conventions

### Base Path
All endpoints under `/api/v1`

### Authentication
- JWT Bearer token in `Authorization` header
- Token expires in `TOKEN_HOURS` (default 12h)
- Inactive users rejected at auth dependency level

### JSON Format
- **CamelCase** for all keys (Pydantic `alias_generator=to_camel`)
- **ISO 8601 UTC** timestamps with `Z` suffix
- **UUID strings** for all IDs
- **Integer rupees** for money (no decimals)

### Error Response
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable description",
    "details": null
  }
}
```

Error codes:
- `VALIDATION_ERROR` - 422, request validation failed
- `INVALID_CREDENTIALS` - 401, bad username/password
- `INVALID_TOKEN` - 401, JWT invalid/expired
- `INACTIVE_USER` - 401, user account disabled
- `FORBIDDEN` - 403, insufficient role permissions
- `NOT_FOUND` - 404, resource not found
- `CONFLICT` - 409, business rule violation
- `HTTP_ERROR` - Generic HTTP error

### Pagination
Query params: `limit` (1-200, default 50), `offset` (default 0)
Response envelope:
```json
{
  "items": [...],
  "total": 100,
  "limit": 50,
  "offset": 0
}
```
Entries sorted by `date_time` descending (newest first).

### Status Codes
- 200 OK
- 201 Created
- 204 No Content
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- 409 Conflict
- 422 Unprocessable Entity

## Endpoint Details

### Auth
| Method | Path | Auth | Summary |
|--------|------|------|---------|
| POST | /auth/login | No | Login with username/password |
| GET | /auth/me | Yes | Current user profile |

### Users (Manager)
| Method | Path | Auth | Summary |
|--------|------|------|---------|
| GET | /students | Manager | List students with search/sort |
| GET | /students/{id} | Manager/Self | Get student by ID |

### Menu
| Method | Path | Auth | Summary |
|--------|------|------|---------|
| GET | /dishes | Any | List dishes (shift, category filters) |
| POST | /dishes | Manager | Create dish |
| PATCH | /dishes/{id} | Manager | Update dish |

Dish `available_in` is JSON array of shift strings: `["breakfast"]`, `["lunch", "dinner"]`, etc.

### Entries
| Method | Path | Auth | Summary |
|--------|------|------|---------|
| GET | /entries | Any | List entries (filters) |
| GET | /entries/{id} | Any | Get entry detail |
| POST | /entries | Student/Manager | Create entry |
| PATCH | /entries/{id} | Manager | Update entry |
| POST | /entries/{id}/approve | Manager | Approve pending entry |
| POST | /entries/{id}/reject | Manager | Reject pending entry |
| POST | /entries/{id}/dispute | Student (own) | Flag as disputed |
| POST | /entries/{id}/resolve-dispute | Manager | Resolve dispute |
| POST | /entries/{id}/mark-paid | Manager | Mark entry fully paid |
| POST | /entries/{id}/reopen | Manager | Reopen fully paid entry |

#### Entry Filters (GET /entries)
- `student_id` (manager only, auto-limited for students)
- `status` (pending/approved/rejected)
- `shift` (breakfast/lunch/dinner)
- `from_date`, `to_date` (ISO 8601)

#### Create Entry (POST /entries)
Request:
```json
{
  "studentId": "uuid",           // Manager only
  "dateTime": "2026-10-10T12:00:00Z",  // Optional, defaults to now
  "shift": "lunch",              // Optional, auto-detected from dateTime
  "items": [
    {"dishId": "uuid", "quantity": 2}
  ],
  "note": "Optional note"
}
```
Rules:
- Student: `studentId` from token, status=`pending`, max 24h backdate
- Manager: `studentId` required (active student), status=`approved`, any backdate
- At least 1 item, quantity 1-20, no duplicate `dishId`
- Dishes must be available for the shift (students only)
- Server snapshots `dishName` and `unitPrice` at creation

#### Update Entry (PATCH /entries/{id}) - Manager only
- Items replaced wholesale, total recomputed
- Cannot edit fully paid entry (409) until reopened
- New total cannot be < `amount_paid` (409)
- Sets `lastEditedAt`, `lastEditedBy`

#### Approve/Reject (POST /entries/{id}/approve|reject)
- Only `pending` entries (409 otherwise)
- Reject requires `reason` (min 3 chars)
- Rejected entries stay rejected permanently

#### Dispute (POST /entries/{id}/dispute) - Student own
- Only `approved` entries (409 otherwise)
- Reason min 5 chars
- Sets `isDisputed=true`, `disputeReason`

#### Resolve Dispute (POST /entries/{id}/resolve-dispute) - Manager
- Clears `isDisputed` and `disputeReason`

#### Mark Paid (POST /entries/{id}/mark-paid) - Manager
- Implemented as payment for remaining outstanding
- Creates payment + allocation, enables undo

#### Reopen (POST /entries/{id}/reopen) - Manager
- Only fully paid entries
- Reverses all allocations, sets `amountPaid=0`
- Clears `paidAt`, `markedPaidBy`
- Marks related payments as undone
- Sets `lastEditedAt`, `lastEditedBy`

### Payments (Manager)
| Method | Path | Auth | Summary |
|--------|------|------|---------|
| POST | /students/{id}/payments | Manager | Record payment |
| GET | /students/{id}/payment-preview | Manager | Preview allocation |
| GET | /students/{id}/payments | Manager/Self | List payments |
| POST | /payments/{id}/undo | Manager | Undo payment (5 min) |

#### Record Payment (POST /students/{id}/payments)
Request: `{ "amount": 500 }`
- Applies to approved, non-paid entries oldest first
- Each entry absorbs up to its outstanding
- Creates `Payment` + `PaymentAllocation` rows per entry
- Fully paid entries get `paidAt`, `markedPaidBy`
- Single transaction
- Rejects if amount ≤ 0 or > total outstanding (422)

#### Payment Preview (GET /students/{id}/payment-preview?amount=500)
Response:
```json
{
  "fullySettledCount": 2,
  "partiallyPaidEntryId": "uuid",
  "partiallyPaidAmount": 150
}
```

#### Undo Payment (POST /payments/{id}/undo)
- Only within 5 minutes of `recordedAt`
- Reverses each allocation (lowers `amountPaid`)
- Clears `paidAt`/`markedPaidBy` where entry no longer fully paid
- Marks payment `isUndone=true`, sets `undoneAt`
- Single transaction
- Only once per payment (409 if already undone)
- 409 if window expired

### Dashboard
| Method | Path | Auth | Summary |
|--------|------|------|---------|
| GET | /dashboard/summary | Manager | Full dashboard |
| GET | /dashboard/me/summary | Student | Own summary |

#### Manager Dashboard Response
```json
{
  "todaySales": 15000,
  "totalOutstanding": 45000,
  "overdueAmount": 12000,
  "pendingApprovals": 5,
  "disputedEntries": 2,
  "todayByShift": {"breakfast": 3000, "lunch": 7000, "dinner": 5000},
  "topDefaulters": [...]
}
```

#### Student Summary Response
```json
{
  "outstanding": 2500,
  "awaitingApproval": 500,
  "overdueCount": 1,
  "recentEntries": [...]
}
```

## Data Models (Derived Fields)

### Entry
- `totalAmount` = Σ(unitPrice × quantity) from items
- `outstanding` = totalAmount - amountPaid
- `paymentStatus`: unpaid (0), partiallyPaid (0 < paid < total), paid (paid ≥ total)
- `isOverdue`: approved + non-paid + (now - dateTime > 7 days)

### Student Balance
- `outstanding` = Σ outstanding over approved entries
- `awaitingApproval` = Σ totalAmount over pending entries

## Business Rules Reference

1. **Shift Detection** (Asia/Karachi):
   - Breakfast: 06:00-10:59
   - Lunch: 11:00-16:59
   - Dinner: 17:00-23:59 and 00:00-05:59

2. **Overdue Threshold**: 7 days (constant `OVERDUE_DAYS`)

3. **Undo Window**: 5 minutes (constant `UNDO_WINDOW_MINUTES`)

4. **Future Skew Tolerance**: 2 minutes (constant `FUTURE_SKEW_MINUTES`)

5. **Student Backdate Limit**: 24 hours (constant `STUDENT_BACKDATE_HOURS`)

6. **Payment Allocation Order**: Oldest `dateTime` first among approved, non-paid entries

7. **Dish Availability**: Students only see available dishes for the shift; managers see all

8. **Price Snapshots**: Entry items store `dishName` and `unitPrice` at creation time; price changes don't affect existing entries

9. **Soft Delete**: Dishes never hard-deleted; `isAvailable=false` hides from new entries

## API Changes Log

| Date | Change | Reason |
|------|--------|--------|
| 2026-10-10 | Initial API design | Project start |

---

*Update this file when making API contract changes. Record in LOG.md as well.*