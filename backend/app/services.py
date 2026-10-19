from datetime import datetime, timedelta, timezone
from typing import List, Optional, Tuple
from sqlalchemy.orm import Session
import pytz

from app.models import (
    User, Dish, Entry, EntryItem, Payment, PaymentAllocation,
    UserRole, Shift, EntryStatus, PaymentStatus
)

KARACHI_TZ = pytz.timezone("Asia/Karachi")
OVERDUE_DAYS = 7
UNDO_WINDOW_MINUTES = 5
FUTURE_SKEW_MINUTES = 2
STUDENT_BACKDATE_HOURS = 24


def get_karachi_now() -> datetime:
    return datetime.now(KARACHI_TZ)


def detect_shift(dt: datetime) -> Shift:
    karachi_dt = dt.astimezone(KARACHI_TZ) if dt.tzinfo else KARACHI_TZ.localize(dt)
    hour = karachi_dt.hour
    if 6 <= hour <= 10:
        return Shift.breakfast
    elif 11 <= hour <= 16:
        return Shift.lunch
    else:
        return Shift.dinner


def calculate_entry_total(items: List[EntryItem]) -> int:
    return sum(item.unit_price * item.quantity for item in items)


def derive_payment_status(total: int, amount_paid: int) -> PaymentStatus:
    if amount_paid == 0:
        return PaymentStatus.unpaid
    elif amount_paid >= total:
        return PaymentStatus.paid
    else:
        return PaymentStatus.partiallyPaid


def is_overdue(entry: Entry, reference_time: Optional[datetime] = None) -> bool:
    if entry.entry_status != EntryStatus.approved:
        return False
    if entry.amount_paid >= calculate_entry_total(entry.items):
        return False
    ref = reference_time or datetime.now(timezone.utc)
    if entry.date_time.tzinfo is None:
        entry_dt = entry.date_time.replace(tzinfo=timezone.utc)
    else:
        entry_dt = entry.date_time.astimezone(timezone.utc)
    return (ref - entry_dt) > timedelta(days=OVERDUE_DAYS)


def get_student_balance(db: Session, student_id: str) -> Tuple[int, int]:
    entries = db.query(Entry).filter(
        Entry.student_id == student_id,
        Entry.entry_status == EntryStatus.approved
    ).all()
    outstanding = 0
    awaiting_approval = 0
    for entry in entries:
        total = calculate_entry_total(entry.items)
        outstanding += max(0, total - entry.amount_paid)
    pending_entries = db.query(Entry).filter(
        Entry.student_id == student_id,
        Entry.entry_status == EntryStatus.pending
    ).all()
    for entry in pending_entries:
        awaiting_approval += calculate_entry_total(entry.items)
    return outstanding, awaiting_approval


def allocate_payment(
    db: Session,
    student_id: str,
    amount: int,
    recorded_by: str
) -> Tuple[Payment, List[Entry]]:
    if amount <= 0:
        raise ValueError("Payment amount must be positive")
    
    outstanding, _ = get_student_balance(db, student_id)
    if amount > outstanding:
        raise ValueError(f"Payment amount {amount} exceeds outstanding {outstanding}")
    
    entries = db.query(Entry).filter(
        Entry.student_id == student_id,
        Entry.entry_status == EntryStatus.approved
    ).order_by(Entry.date_time.asc()).all()
    
    remaining = amount
    affected_entries = []
    
    payment = Payment(
        student_id=student_id,
        amount=amount,
        recorded_by=recorded_by,
        recorded_at=datetime.now(timezone.utc)
    )
    db.add(payment)
    db.flush()
    
    for entry in entries:
        if remaining <= 0:
            break
        total = calculate_entry_total(entry.items)
        entry_outstanding = max(0, total - entry.amount_paid)
        if entry_outstanding <= 0:
            continue
        alloc_amount = min(entry_outstanding, remaining)
        entry.amount_paid += alloc_amount
        remaining -= alloc_amount
        
        allocation = PaymentAllocation(
            payment_id=payment.id,
            entry_id=entry.id,
            amount=alloc_amount
        )
        db.add(allocation)
        
        if entry.amount_paid >= total:
            entry.paid_at = datetime.now(timezone.utc)
            entry.marked_paid_by = recorded_by
        
        affected_entries.append(entry)
    
    db.commit()
    return payment, affected_entries


def mark_entry_as_paid(db: Session, entry: Entry, recorded_by: str) -> Payment:
    total = calculate_entry_total(entry.items)
    outstanding = max(0, total - entry.amount_paid)
    if outstanding <= 0:
        raise ValueError("Entry already fully paid")
    
    now = datetime.now(timezone.utc)
    payment = Payment(
        student_id=entry.student_id,
        amount=outstanding,
        recorded_by=recorded_by,
        recorded_at=now
    )
    db.add(payment)
    db.flush()
    
    entry.amount_paid += outstanding
    allocation = PaymentAllocation(
        payment_id=payment.id,
        entry_id=entry.id,
        amount=outstanding
    )
    db.add(allocation)
    entry.paid_at = now
    entry.marked_paid_by = recorded_by
    db.commit()
    return payment


def undo_payment(db: Session, payment_id: str, requester_id: str) -> Payment:
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if not payment:
        raise ValueError("Payment not found")
    if payment.is_undone:
        raise ValueError("Payment already undone")
    
    now = datetime.now(timezone.utc)
    if payment.recorded_at.tzinfo is None:
        recorded = payment.recorded_at.replace(tzinfo=timezone.utc)
    else:
        recorded = payment.recorded_at.astimezone(timezone.utc)
    
    if (now - recorded) > timedelta(minutes=UNDO_WINDOW_MINUTES):
        raise ValueError("Undo window expired (5 minutes)")
    
    for allocation in payment.allocations:
        entry = allocation.entry
        entry.amount_paid -= allocation.amount
        if entry.amount_paid < calculate_entry_total(entry.items):
            entry.paid_at = None
            entry.marked_paid_by = None
    
    payment.is_undone = True
    payment.undone_at = now
    db.commit()
    return payment


def reopen_entry(db: Session, entry_id: str, requester_id: str) -> Entry:
    entry = db.query(Entry).filter(Entry.id == entry_id).first()
    if not entry:
        raise ValueError("Entry not found")
    total = calculate_entry_total(entry.items)
    if entry.amount_paid < total:
        raise ValueError("Entry is not fully paid")
    
    for allocation in entry.allocations:
        if not allocation.payment.is_undone:
            allocation.payment.is_undone = True
            allocation.payment.undone_at = datetime.now(timezone.utc)
        entry.amount_paid -= allocation.amount
        db.delete(allocation)
    
    entry.paid_at = None
    entry.marked_paid_by = None
    entry.last_edited_at = datetime.now(timezone.utc)
    entry.last_edited_by = requester_id
    db.commit()
    return entry


def validate_entry_date(
    dt: datetime,
    role: UserRole,
    reference_time: Optional[datetime] = None
) -> datetime:
    ref = reference_time or datetime.now(timezone.utc)
    if dt.tzinfo is None:
        from zoneinfo import ZoneInfo
        karachi_dt = dt.replace(tzinfo=ZoneInfo("Asia/Karachi")).astimezone(timezone.utc)
        if karachi_dt <= ref + timedelta(minutes=FUTURE_SKEW_MINUTES):
            dt = karachi_dt
        else:
            dt = dt.replace(tzinfo=timezone.utc)
    else:
        dt = dt.astimezone(timezone.utc)
    
    if dt > ref + timedelta(minutes=FUTURE_SKEW_MINUTES):
        raise ValueError("Entry date cannot be in the future")
    
    if role == UserRole.student:
        if dt < ref - timedelta(hours=STUDENT_BACKDATE_HOURS):
            raise ValueError("Students can only create entries up to 24 hours in the past")
    
    return dt


def create_entry_items(
    db: Session,
    entry: Entry,
    items_data: List[dict],
    current_user: User
) -> List[EntryItem]:
    dish_ids = [item["dish_id"] for item in items_data]
    if len(dish_ids) != len(set(dish_ids)):
        raise ValueError("Duplicate dish IDs not allowed")
    
    dishes = db.query(Dish).filter(Dish.id.in_(dish_ids)).all()
    dish_map = {d.id: d for d in dishes}
    
    if len(dishes) != len(dish_ids):
        raise ValueError("One or more dishes not found")
    
    entry_items = []
    for item_data in items_data:
        dish = dish_map[item_data["dish_id"]]
        if not dish.is_available:
            raise ValueError(f"Dish '{dish.name}' is not available")
        if current_user.role == UserRole.student:
            shift = entry.shift
            if shift.value not in dish.available_in:
                raise ValueError(f"Dish '{dish.name}' not available for {shift.value}")
        
        entry_item = EntryItem(
            entry_id=entry.id,
            dish_id=dish.id,
            dish_name=dish.name,
            unit_price=dish.price,
            quantity=item_data["quantity"]
        )
        entry_items.append(entry_item)
        db.add(entry_item)
    
    return entry_items


def update_entry_items(
    db: Session,
    entry: Entry,
    items_data: List[dict],
    current_user: User
) -> List[EntryItem]:
    if entry.amount_paid > 0:
        total = calculate_entry_total(entry.items)
        if entry.amount_paid >= total:
            raise ValueError("Cannot edit fully paid entry. Reopen it first.")
    
    for item in entry.items:
        db.delete(item)
    db.flush()
    
    return create_entry_items(db, entry, items_data, current_user)


def get_entry_response(entry: Entry, db: Session) -> dict:
    total = calculate_entry_total(entry.items)
    outstanding = max(0, total - entry.amount_paid)
    payment_status = derive_payment_status(total, entry.amount_paid)
    overdue = is_overdue(entry)
    
    items_response = []
    for item in entry.items:
        items_response.append({
            "dish_id": item.dish_id,
            "dish_name": item.dish_name,
            "unit_price": item.unit_price,
            "quantity": item.quantity,
            "line_total": item.unit_price * item.quantity
        })
    
    student = entry.student
    return {
        "id": entry.id,
        "student_id": entry.student_id,
        "student_name": student.name,
        "student_roll_number": student.roll_number,
        "date_time": entry.date_time,
        "shift": entry.shift,
        "items": items_response,
        "total_amount": total,
        "amount_paid": entry.amount_paid,
        "outstanding": outstanding,
        "entry_status": entry.entry_status,
        "payment_status": payment_status,
        "is_overdue": overdue,
        "paid_at": entry.paid_at,
        "marked_paid_by": entry.marked_paid_by,
        "created_by": entry.created_by,
        "note": entry.note,
        "is_disputed": entry.is_disputed,
        "dispute_reason": entry.dispute_reason,
        "rejection_reason": entry.rejection_reason,
        "last_edited_at": entry.last_edited_at,
        "last_edited_by": entry.last_edited_by,
        "created_at": entry.created_at
    }


def get_payment_preview(db: Session, student_id: str, amount: int) -> dict:
    if amount <= 0:
        raise ValueError("Amount must be positive")
    
    entries = db.query(Entry).filter(
        Entry.student_id == student_id,
        Entry.entry_status == EntryStatus.approved
    ).order_by(Entry.date_time.asc()).all()
    
    remaining = amount
    fully_settled = 0
    partially_paid_entry_id = None
    partially_paid_amount = 0
    
    for entry in entries:
        total = calculate_entry_total(entry.items)
        entry_outstanding = max(0, total - entry.amount_paid)
        if entry_outstanding <= 0:
            continue
        if remaining >= entry_outstanding:
            remaining -= entry_outstanding
            fully_settled += 1
        else:
            partially_paid_entry_id = entry.id
            partially_paid_amount = remaining
            remaining = 0
            break
    
    return {
        "fully_settled_count": fully_settled,
        "partially_paid_entry_id": partially_paid_entry_id,
        "partially_paid_amount": partially_paid_amount
    }


def get_dashboard_summary(db: Session) -> dict:
    today_start = get_karachi_now().replace(hour=0, minute=0, second=0, microsecond=0)
    today_start_utc = today_start.astimezone(timezone.utc)
    today_end_utc = today_start_utc + timedelta(days=1)
    
    today_entries = db.query(Entry).filter(
        Entry.date_time >= today_start_utc,
        Entry.date_time < today_end_utc,
        Entry.entry_status == EntryStatus.approved
    ).all()
    
    today_sales = sum(calculate_entry_total(e.items) for e in today_entries)
    
    all_approved = db.query(Entry).filter(Entry.entry_status == EntryStatus.approved).all()
    total_outstanding = sum(
        max(0, calculate_entry_total(e.items) - e.amount_paid)
        for e in all_approved
    )
    
    overdue_amount = sum(
        max(0, calculate_entry_total(e.items) - e.amount_paid)
        for e in all_approved if is_overdue(e)
    )
    
    pending_count = db.query(Entry).filter(Entry.entry_status == EntryStatus.pending).count()
    disputed_count = db.query(Entry).filter(Entry.is_disputed == True).count()
    
    today_by_shift = {}
    for shift in Shift:
        shift_entries = [e for e in today_entries if e.shift == shift]
        today_by_shift[shift.value] = sum(calculate_entry_total(e.items) for e in shift_entries)
    
    students = db.query(User).filter(User.role == UserRole.student, User.is_active == True).all()
    top_defaulters = []
    for student in students:
        outstanding, _ = get_student_balance(db, student.id)
        if outstanding > 0:
            overdue = sum(
                max(0, calculate_entry_total(e.items) - e.amount_paid)
                for e in db.query(Entry).filter(
                    Entry.student_id == student.id,
                    Entry.entry_status == EntryStatus.approved
                ).all() if is_overdue(e)
            )
            top_defaulters.append({
                "id": student.id,
                "name": student.name,
                "roll_number": student.roll_number,
                "room_number": student.room_number,
                "outstanding": outstanding,
                "overdue_amount": overdue,
                "awaiting_approval": 0
            })
    
    top_defaulters.sort(key=lambda x: x["outstanding"], reverse=True)
    top_defaulters = top_defaulters[:10]
    
    return {
        "today_sales": today_sales,
        "total_outstanding": total_outstanding,
        "overdue_amount": overdue_amount,
        "pending_approvals": pending_count,
        "disputed_entries": disputed_count,
        "today_by_shift": today_by_shift,
        "top_defaulters": top_defaulters
    }


def get_me_summary(db: Session, student_id: str) -> dict:
    outstanding, awaiting_approval = get_student_balance(db, student_id)
    
    approved_entries = db.query(Entry).filter(
        Entry.student_id == student_id,
        Entry.entry_status == EntryStatus.approved
    ).all()
    
    overdue_count = sum(1 for e in approved_entries if is_overdue(e))
    
    recent_entries = db.query(Entry).filter(
        Entry.student_id == student_id
    ).order_by(Entry.date_time.desc()).limit(10).all()
    
    recent_response = [get_entry_response(e, db) for e in recent_entries]
    
    return {
        "outstanding": outstanding,
        "awaiting_approval": awaiting_approval,
        "overdue_count": overdue_count,
        "recent_entries": recent_response
    }