from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.models import User, UserRole
from app.schemas import UserResponse, StudentSummary, PaginatedResponse
from app.dependencies import get_current_user, require_roles
from app.services import get_student_balance, get_entry_response

router = APIRouter(prefix="/students", tags=["Users"])


@router.get("", response_model=PaginatedResponse[StudentSummary], summary="List students (manager)")
def list_students(
    search: Optional[str] = None,
    sort: Optional[str] = None,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(require_roles(UserRole.manager)),
    db: Session = Depends(get_db),
):
    query = db.query(User).filter(User.role == UserRole.student)
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            (User.name.ilike(search_term)) |
            (User.username.ilike(search_term)) |
            (User.roll_number.ilike(search_term))
        )
    if sort == "name":
        query = query.order_by(User.name)
    elif sort == "outstanding":
        students = query.all()
        students.sort(key=lambda s: get_student_balance(db, s.id)[0], reverse=True)
        total = len(students)
        paginated = students[offset:offset + limit]
        return PaginatedResponse(
            items=[StudentSummary(
                id=s.id,
                name=s.name,
                username=s.username,
                roll_number=s.roll_number,
                room_number=s.room_number,
                outstanding=get_student_balance(db, s.id)[0],
                overdue_amount=0,
                awaiting_approval=get_student_balance(db, s.id)[1]
            ) for s in paginated],
            total=total,
            limit=limit,
            offset=offset
        )
    else:
        query = query.order_by(User.name)
    
    total = query.count()
    students = query.offset(offset).limit(limit).all()
    return PaginatedResponse(
        items=[StudentSummary(
            id=s.id,
            name=s.name,
            username=s.username,
            roll_number=s.roll_number,
            room_number=s.room_number,
            outstanding=get_student_balance(db, s.id)[0],
            overdue_amount=0,
            awaiting_approval=get_student_balance(db, s.id)[1]
        ) for s in students],
        total=total,
        limit=limit,
        offset=offset
    )


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