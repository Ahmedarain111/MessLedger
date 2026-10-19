from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta
from app.database import get_db
from app.models import User, UserRole
from app.schemas import LoginRequest, Token, UserResponse
from app.security import verify_password, create_access_token, get_password_hash
from app.dependencies import get_current_user, require_roles

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/login", response_model=Token, summary="User login")
def login(request: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(
        (User.username == request.username) | (User.roll_number.ilike(request.username))
    ).first()
    if not user or not verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "INVALID_CREDENTIALS", "message": "Invalid username or password", "details": None}},
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error": {"code": "INACTIVE_USER", "message": "User account is inactive", "details": None}},
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(data={"sub": user.id}, expires_delta=timedelta(hours=12))
    return Token(access_token=access_token, user=UserResponse.model_validate(user))


@router.get("/me", response_model=UserResponse, summary="Get current user profile")
def get_me(current_user: User = Depends(get_current_user)):
    return UserResponse.model_validate(current_user)