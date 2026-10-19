from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.models import User, UserRole, Dish, Shift
from app.schemas import (
    DishCreate, DishUpdate, DishResponse, UserResponse,
    StudentSummary, PaginatedResponse
)
from app.dependencies import get_current_user, require_roles

router = APIRouter(prefix="/dishes", tags=["Menu"])


@router.get("", response_model=PaginatedResponse[DishResponse], summary="List dishes")
def list_dishes(
    shift: Optional[Shift] = None,
    category: Optional[str] = None,
    include_unavailable: bool = False,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if include_unavailable and current_user.role != UserRole.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"error": {"code": "FORBIDDEN", "message": "Only managers can view unavailable dishes", "details": None}},
        )
    query = db.query(Dish)
    if not include_unavailable:
        query = query.filter(Dish.is_available == True)
    if shift:
        query = query.filter(Dish.available_in.contains([shift.value]))
    if category:
        query = query.filter(Dish.category == category)
    total = query.count()
    dishes = query.order_by(Dish.name).offset(offset).limit(limit).all()
    return PaginatedResponse(
        items=[DishResponse.model_validate(d) for d in dishes],
        total=total,
        limit=limit,
        offset=offset,
    )


@router.post("", response_model=DishResponse, status_code=status.HTTP_201_CREATED, summary="Create dish (manager)")
def create_dish(
    dish_in: DishCreate,
    current_user: User = Depends(require_roles(UserRole.manager)),
    db: Session = Depends(get_db),
):
    dish = Dish(**dish_in.model_dump())
    db.add(dish)
    db.commit()
    db.refresh(dish)
    return DishResponse.model_validate(dish)


@router.patch("/{dish_id}", response_model=DishResponse, summary="Update dish (manager)")
def update_dish(
    dish_id: str,
    dish_in: DishUpdate,
    current_user: User = Depends(require_roles(UserRole.manager)),
    db: Session = Depends(get_db),
):
    dish = db.query(Dish).filter(Dish.id == dish_id).first()
    if not dish:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": {"code": "NOT_FOUND", "message": "Dish not found", "details": None}},
        )
    update_data = dish_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(dish, field, value)
    db.commit()
    db.refresh(dish)
    return DishResponse.model_validate(dish)