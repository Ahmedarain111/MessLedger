from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models import User, UserRole, Payment, Entry
from app.schemas import (
    PaymentCreate, PaymentResponse, PaymentPreviewResponse,
    PaymentRecordResponse, StudentSummary, PaginatedResponse,
    PaymentAllocationResponse
)
from app.dependencies import get_current_user, require_roles
from app.services import (
    allocate_payment, undo_payment, get_payment_preview,
    get_student_balance, get_entry_response, calculate_entry_total
)

router = APIRouter(tags=["Payments"])


@router.post("/students/{student_id}/payments", response_model=PaymentRecordResponse, status_code=status.HTTP_201_CREATED, summary="Record payment for student (manager)")
def record_payment(
    student_id: str,
    payment_in: PaymentCreate,
    current_user: User = Depends(require_roles(UserRole.manager)),
    db: Session = Depends(get_db),
):
    student = db.query(User).filter(User.id == student_id, User.role == UserRole.student, User.is_active == True).first()
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Student not found or inactive", "details": None}},
        )
    
    outstanding, _ = get_student_balance(db, student_id)
    if payment_in.amount > outstanding:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"error": {"code": "VALIDATION_ERROR", "message": f"Amount exceeds outstanding ({outstanding})", "details": None}},
        )
    
    payment, affected_entries = allocate_payment(db, student_id, payment_in.amount, current_user.id)
    
    db.refresh(payment)
    for entry in affected_entries:
        db.refresh(entry)
    
    outstanding_after, awaiting = get_student_balance(db, student_id)
    
    payment_response = PaymentResponse.model_validate(payment)
    payment_response.allocations = [
        PaymentAllocationResponse(entry_id=a.entry_id, amount=a.amount) for a in payment.allocations
    ]
    
    return PaymentRecordResponse(
        payment=payment_response,
        affected_entries=[get_entry_response(e, db) for e in affected_entries],
        student_balance=StudentSummary(
            id=student.id,
            name=student.name,
            roll_number=student.roll_number,
            room_number=student.room_number,
            outstanding=outstanding_after,
            overdue_amount=0,
            awaiting_approval=awaiting
        )
    )


@router.get("/students/{student_id}/payment-preview", response_model=PaymentPreviewResponse, summary="Preview payment allocation (manager)")
def preview_payment(
    student_id: str,
    amount: int = Query(..., gt=0),
    current_user: User = Depends(require_roles(UserRole.manager)),
    db: Session = Depends(get_db),
):
    student = db.query(User).filter(User.id == student_id, User.role == UserRole.student, User.is_active == True).first()
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Student not found or inactive", "details": None}},
        )
    
    return get_payment_preview(db, student_id, amount)


@router.get("/students/{student_id}/payments", response_model=PaginatedResponse[PaymentResponse], summary="List payments for student (manager or self)")
def list_payments(
    student_id: str,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role != UserRole.manager and current_user.id != student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"error": {"code": "FORBIDDEN", "message": "Insufficient permissions", "details": None}},
        )
    
    query = db.query(Payment).filter(Payment.student_id == student_id).order_by(Payment.recorded_at.desc())
    total = query.count()
    payments = query.offset(offset).limit(limit).all()
    
    return PaginatedResponse(
        items=[PaymentResponse.model_validate(p) for p in payments],
        total=total,
        limit=limit,
        offset=offset
    )


@router.post("/payments/{payment_id}/undo", response_model=PaymentResponse, summary="Undo payment (manager)")
@router.post("/students/payments/{payment_id}/undo", response_model=PaymentResponse, include_in_schema=False)
def undo_payment_endpoint(
    payment_id: str,
    current_user: User = Depends(require_roles(UserRole.manager)),
    db: Session = Depends(get_db),
):
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Payment not found", "details": None}},
        )
    
    try:
        undo_payment(db, payment_id, current_user.id)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT if "expired" in str(e) or "already" in str(e) else status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"error": {"code": "CONFLICT" if "expired" in str(e) or "already" in str(e) else "VALIDATION_ERROR", "message": str(e), "details": None}},
        )
    
    db.refresh(payment)
    return PaymentResponse.model_validate(payment)