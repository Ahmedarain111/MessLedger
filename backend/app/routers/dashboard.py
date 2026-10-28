from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, UserRole
from app.schemas import DashboardSummary, MeSummary
from app.dependencies import get_current_user, require_roles
from app.services import get_dashboard_summary, get_me_summary

from typing import Optional

router = APIRouter(tags=["Dashboard"])


@router.get("/dashboard/summary", response_model=DashboardSummary, summary="Full dashboard summary (manager)")
def dashboard_summary(
    hostel_id: Optional[str] = None,
    current_user: User = Depends(require_roles(UserRole.manager)),
    db: Session = Depends(get_db),
):
    target_hostel_id = hostel_id or current_user.hostel_id
    return get_dashboard_summary(db, target_hostel_id)


@router.get("/dashboard/me/summary", response_model=MeSummary, summary="Own dashboard summary (student)")
@router.get("/me/summary", response_model=MeSummary, summary="Own dashboard summary (student)", include_in_schema=False)
def me_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return get_me_summary(db, current_user.id)