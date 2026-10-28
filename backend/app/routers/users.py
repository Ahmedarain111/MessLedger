from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import re
from app.database import get_db
from app.models import User, UserRole
from app.schemas import UserResponse, StudentSummary, PaginatedResponse, StudentCreate
from app.dependencies import get_current_user, require_roles
from app.security import get_password_hash
from app.services import get_student_balance, get_entry_response

router = APIRouter(prefix="/students", tags=["Users"])


@router.get("", response_model=PaginatedResponse[StudentSummary], summary="List students (manager)")
def list_students(
    search: Optional[str] = None,
    sort: Optional[str] = None,
    hostel_id: Optional[str] = None,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(require_roles(UserRole.manager)),
    db: Session = Depends(get_db),
):
    query = db.query(User).filter(User.role == UserRole.student)
    if hostel_id:
        query = query.filter(User.hostel_id == hostel_id)
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            (User.name.ilike(search_term)) |
            (User.username.ilike(search_term)) |
            (User.roll_number.ilike(search_term))
        )
    def to_summary(s: User) -> StudentSummary:
        outstanding, awaiting = get_student_balance(db, s.id)
        return StudentSummary(
            id=s.id,
            name=s.name,
            username=s.username,
            roll_number=s.roll_number,
            room_number=s.room_number,
            hostel_id=s.hostel_id,
            hostel_name=s.hostel_name,
            outstanding=outstanding,
            overdue_amount=0,
            awaiting_approval=awaiting
        )

    if sort == "name":
        query = query.order_by(User.name)
    elif sort == "outstanding":
        students = query.all()
        summaries = [to_summary(s) for s in students]
        summaries.sort(key=lambda s: s.outstanding, reverse=True)
        total = len(summaries)
        paginated = summaries[offset:offset + limit]
        return PaginatedResponse(
            items=paginated,
            total=total,
            limit=limit,
            offset=offset
        )
    else:
        query = query.order_by(User.name)
    
    total = query.count()
    students = query.offset(offset).limit(limit).all()
    return PaginatedResponse(
        items=[to_summary(s) for s in students],
        total=total,
        limit=limit,
        offset=offset
    )


@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED, summary="Create student account (manager)")
def create_student(
    request: StudentCreate,
    current_user: User = Depends(require_roles(UserRole.manager)),
    db: Session = Depends(get_db),
):
    # Username: custom or auto-generated from roll_number
    username = request.username
    if not username:
        username = re.sub(r'[^a-zA-Z0-9]', '', request.roll_number).lower()
        if len(username) < 3:
            username = f"std_{username}"
    else:
        username = username.strip().lower()

    # Check for existing roll number
    existing_roll = db.query(User).filter(User.roll_number == request.roll_number.strip()).first()
    if existing_roll:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error": {"code": "ROLL_NUMBER_EXISTS", "message": f"Roll number '{request.roll_number}' is already registered", "details": None}},
        )

    # Check for existing username
    existing_user = db.query(User).filter(User.username == username).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error": {"code": "USERNAME_TAKEN", "message": f"Username '{username}' already exists", "details": None}},
        )

    raw_password = request.password or "student123"
    hostel_id = request.hostel_id or current_user.hostel_id

    student = User(
        name=request.name.strip(),
        role=UserRole.student,
        username=username,
        password_hash=get_password_hash(raw_password),
        roll_number=request.roll_number.strip(),
        room_number=request.room_number.strip() if request.room_number else None,
        hostel_id=hostel_id,
        is_active=True,
    )
    db.add(student)
    db.commit()
    db.refresh(student)
    return UserResponse.model_validate(student)


@router.get("/{student_id}", response_model=UserResponse, summary="Get student (manager or self)")
def get_student(
    student_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role != UserRole.manager and current_user.id != student_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"error": {"code": "FORBIDDEN", "message": "Insufficient permissions", "details": None}},
        )
    student = db.query(User).filter(User.id == student_id, User.role == UserRole.student).first()
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Student not found", "details": None}},
        )
    return UserResponse.model_validate(student)