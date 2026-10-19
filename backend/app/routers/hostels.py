from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models import Hostel, User, UserRole
from app.schemas import HostelResponse, HostelCreate
from app.dependencies import get_current_user, require_roles

router = APIRouter(prefix="/hostels", tags=["Hostels"])


@router.get("", response_model=List[HostelResponse], summary="List all active hostels")
def list_hostels(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return db.query(Hostel).filter(Hostel.is_active == True).order_by(Hostel.name).all()


@router.post("", response_model=HostelResponse, status_code=status.HTTP_201_CREATED, summary="Create a new hostel (manager)")
def create_hostel(
    request: HostelCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.manager)),
):
    existing = db.query(Hostel).filter(Hostel.name.ilike(request.name.strip())).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error": {"code": "HOSTEL_EXISTS", "message": f"Hostel '{request.name}' already exists", "details": None}},
        )
    hostel = Hostel(
        name=request.name.strip(),
        code=request.code.strip() if request.code else None,
        is_active=request.is_active,
    )
    db.add(hostel)
    db.commit()
    db.refresh(hostel)
    return hostel
