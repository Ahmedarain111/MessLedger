from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timezone
from app.database import get_db
from app.models import User, UserRole, Entry, EntryStatus, Shift
from app.schemas import (
    EntryCreate, EntryUpdate, EntryResponse, PaginatedResponse,
    ApproveRequest, RejectRequest, DisputeRequest, ResolveDisputeRequest,
    MarkPaidRequest, ReopenRequest
)
from app.dependencies import get_current_user, require_roles
from app.services import (
    detect_shift, validate_entry_date, create_entry_items,
    update_entry_items, get_entry_response, get_student_balance,
    calculate_entry_total, is_overdue
)

router = APIRouter(prefix="/entries", tags=["Entries"])


@router.get("", response_model=PaginatedResponse[EntryResponse], summary="List entries")
def list_entries(
    student_id: Optional[str] = None,
    hostel_id: Optional[str] = None,
    status: Optional[EntryStatus] = None,
    shift: Optional[Shift] = None,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = db.query(Entry)
    
    if current_user.role == UserRole.student:
        query = query.filter(Entry.student_id == current_user.id)
    elif student_id:
        query = query.filter(Entry.student_id == student_id)
    
    if hostel_id:
        query = query.filter(Entry.hostel_id == hostel_id)
    if status:
        query = query.filter(Entry.entry_status == status)
    if shift:
        query = query.filter(Entry.shift == shift)
    if from_date:
        query = query.filter(Entry.date_time >= from_date)
    if to_date:
        query = query.filter(Entry.date_time <= to_date)
    
    query = query.order_by(Entry.date_time.desc())
    total = query.count()
    entries = query.offset(offset).limit(limit).all()
    
    return PaginatedResponse(
        items=[get_entry_response(e, db) for e in entries],
        total=total,
        limit=limit,
        offset=offset
    )


@router.get("/{entry_id}", response_model=EntryResponse, summary="Get entry by ID")
def get_entry(
    entry_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    entry = db.query(Entry).filter(Entry.id == entry_id).first()
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Entry not found", "details": None}},
        )
    if current_user.role == UserRole.student and entry.student_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Entry not found", "details": None}},
        )
    return get_entry_response(entry, db)


@router.post("", response_model=EntryResponse, status_code=status.HTTP_201_CREATED, summary="Create entry")
def create_entry(
    entry_in: EntryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role == UserRole.student:
        student_id = current_user.id
        entry_status = EntryStatus.pending
        created_by = current_user.id
        target_student = current_user
    else:
        if not entry_in.student_id:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail={"error": {"code": "VALIDATION_ERROR", "message": "studentId required for manager", "details": None}},
            )
        target_student = db.query(User).filter(
            User.id == entry_in.student_id,
            User.role == UserRole.student,
            User.is_active == True
        ).first()
        if not target_student:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"error": {"code": "NOT_FOUND", "message": "Student not found or inactive", "details": None}},
            )
        student_id = entry_in.student_id
        entry_status = EntryStatus.approved
        created_by = current_user.id
    
    date_time = entry_in.date_time or datetime.now(timezone.utc)
    date_time = validate_entry_date(date_time, current_user.role)
    
    shift = entry_in.shift or detect_shift(date_time)
    
    hostel_id = entry_in.hostel_id or (target_student.hostel_id if target_student else None) or current_user.hostel_id
    
    entry = Entry(
        student_id=student_id,
        hostel_id=hostel_id,
        date_time=date_time,
        shift=shift,
        entry_status=entry_status,
        amount_paid=0,
        created_by=created_by,
        note=entry_in.note
    )
    db.add(entry)
    db.flush()
    
    items_data = [item.model_dump() for item in entry_in.items]
    create_entry_items(db, entry, items_data, current_user)
    
    db.commit()
    db.refresh(entry)
    return get_entry_response(entry, db)


@router.patch("/{entry_id}", response_model=EntryResponse, summary="Update entry (manager)")
def update_entry(
    entry_id: str,
    entry_in: EntryUpdate,
    current_user: User = Depends(require_roles(UserRole.manager)),
    db: Session = Depends(get_db),
):
    entry = db.query(Entry).filter(Entry.id == entry_id).first()
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Entry not found", "details": None}},
        )
    
    total_before = calculate_entry_total(entry.items)
    if entry.amount_paid >= total_before:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error": {"code": "CONFLICT", "message": "Cannot edit fully paid entry. Reopen it first.", "details": None}},
        )
    
    if entry_in.hostel_id is not None:
        entry.hostel_id = entry_in.hostel_id
    if entry_in.date_time is not None:
        entry.date_time = validate_entry_date(entry_in.date_time, current_user.role)
    if entry_in.shift is not None:
        entry.shift = entry_in.shift
    if entry_in.note is not None:
        entry.note = entry_in.note
    
    if entry_in.items is not None:
        items_data = [item.model_dump() for item in entry_in.items]
        update_entry_items(db, entry, items_data, current_user)
    
    entry.last_edited_at = datetime.now(timezone.utc)
    entry.last_edited_by = current_user.id
    
    total_after = calculate_entry_total(entry.items)
    if entry.amount_paid > total_after:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error": {"code": "CONFLICT", "message": "Edit would make total less than amount paid", "details": None}},
        )
    
    db.commit()
    db.refresh(entry)
    return get_entry_response(entry, db)


@router.post("/{entry_id}/approve", response_model=EntryResponse, summary="Approve entry (manager)")
def approve_entry(
    entry_id: str,
    request: ApproveRequest,
    current_user: User = Depends(require_roles(UserRole.manager)),
    db: Session = Depends(get_db),
):
    entry = db.query(Entry).filter(Entry.id == entry_id).first()
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Entry not found", "details": None}},
        )
    if entry.entry_status != EntryStatus.pending:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error": {"code": "CONFLICT", "message": "Only pending entries can be approved", "details": None}},
        )
    entry.entry_status = EntryStatus.approved
    db.commit()
    db.refresh(entry)
    return get_entry_response(entry, db)


@router.post("/{entry_id}/reject", response_model=EntryResponse, summary="Reject entry (manager)")
def reject_entry(
    entry_id: str,
    request: RejectRequest,
    current_user: User = Depends(require_roles(UserRole.manager)),
    db: Session = Depends(get_db),
):
    entry = db.query(Entry).filter(Entry.id == entry_id).first()
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Entry not found", "details": None}},
        )
    if entry.entry_status != EntryStatus.pending:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error": {"code": "CONFLICT", "message": "Only pending entries can be rejected", "details": None}},
        )
    entry.entry_status = EntryStatus.rejected
    entry.rejection_reason = request.reason
    db.commit()
    db.refresh(entry)
    return get_entry_response(entry, db)


@router.post("/{entry_id}/dispute", response_model=EntryResponse, summary="Flag entry as disputed (student)")
def dispute_entry(
    entry_id: str,
    request: DisputeRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    entry = db.query(Entry).filter(Entry.id == entry_id).first()
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Entry not found", "details": None}},
        )
    if entry.student_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Entry not found", "details": None}},
        )
    if entry.entry_status != EntryStatus.approved:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error": {"code": "CONFLICT", "message": "Only approved entries can be disputed", "details": None}},
        )
    entry.is_disputed = True
    entry.dispute_reason = request.reason
    db.commit()
    db.refresh(entry)
    return get_entry_response(entry, db)


@router.post("/{entry_id}/resolve-dispute", response_model=EntryResponse, summary="Resolve dispute (manager)")
def resolve_dispute(
    entry_id: str,
    request: ResolveDisputeRequest,
    current_user: User = Depends(require_roles(UserRole.manager)),
    db: Session = Depends(get_db),
):
    entry = db.query(Entry).filter(Entry.id == entry_id).first()
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Entry not found", "details": None}},
        )
    if not entry.is_disputed:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error": {"code": "CONFLICT", "message": "Entry is not disputed", "details": None}},
        )
    entry.is_disputed = False
    entry.dispute_reason = None
    db.commit()
    db.refresh(entry)
    return get_entry_response(entry, db)


@router.post("/{entry_id}/mark-paid", response_model=EntryResponse, summary="Mark entry as paid (manager)")
def mark_paid(
    entry_id: str,
    request: MarkPaidRequest,
    current_user: User = Depends(require_roles(UserRole.manager)),
    db: Session = Depends(get_db),
):
    entry = db.query(Entry).filter(Entry.id == entry_id).first()
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Entry not found", "details": None}},
        )
    if entry.entry_status != EntryStatus.approved:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error": {"code": "CONFLICT", "message": "Only approved entries can be marked paid", "details": None}},
        )
    
    total = calculate_entry_total(entry.items)
    outstanding = total - entry.amount_paid
    if outstanding <= 0:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error": {"code": "CONFLICT", "message": "Entry already fully paid", "details": None}},
        )
    
    from app.services import mark_entry_as_paid
    payment = mark_entry_as_paid(db, entry, current_user.id)
    
    db.refresh(entry)
    return get_entry_response(entry, db)


@router.post("/{entry_id}/reopen", response_model=EntryResponse, summary="Reopen entry (manager)")
def reopen_entry(
    entry_id: str,
    request: ReopenRequest,
    current_user: User = Depends(require_roles(UserRole.manager)),
    db: Session = Depends(get_db),
):
    entry = db.query(Entry).filter(Entry.id == entry_id).first()
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Entry not found", "details": None}},
        )
    
    total = calculate_entry_total(entry.items)
    if entry.amount_paid < total:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error": {"code": "CONFLICT", "message": "Entry is not fully paid", "details": None}},
        )
    
    from app.services import reopen_entry as reopen_svc
    reopen_svc(db, entry_id, current_user.id)
    
    db.refresh(entry)
    return get_entry_response(entry, db)