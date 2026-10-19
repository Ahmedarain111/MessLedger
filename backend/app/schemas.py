from datetime import datetime
from typing import List, Optional, Any, Generic, TypeVar
from uuid import UUID
from pydantic import BaseModel, Field, EmailStr, field_validator, model_validator
from pydantic.alias_generators import to_camel
from app.models import UserRole, Shift, EntryStatus, PaymentStatus


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"

    model_config = {"alias_generator": to_camel, "populate_by_name": True}


class UserBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    role: UserRole
    username: str = Field(..., min_length=3, max_length=50)
    roll_number: Optional[str] = Field(None, max_length=50)
    room_number: Optional[str] = Field(None, max_length=20)
    is_active: bool = True

    model_config = {"alias_generator": to_camel, "populate_by_name": True}


class UserCreate(UserBase):
    password: str = Field(..., min_length=6, max_length=100)


class UserUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    role: Optional[UserRole] = None
    roll_number: Optional[str] = Field(None, max_length=50)
    room_number: Optional[str] = Field(None, max_length=20)
    is_active: Optional[bool] = None

    model_config = {"alias_generator": to_camel, "populate_by_name": True}


class UserResponse(UserBase):
    id: str
    created_at: datetime

    model_config = {"alias_generator": to_camel, "populate_by_name": True, "from_attributes": True}


class LoginRequest(BaseModel):
    username: str
    password: str

    model_config = {"alias_generator": to_camel, "populate_by_name": True}


class DishBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    price: int = Field(..., gt=0)
    category: str = Field(..., min_length=1, max_length=50)
    available_in: List[Shift] = Field(..., min_length=1)
    is_available: bool = True
    image_url: Optional[str] = None

    model_config = {"alias_generator": to_camel, "populate_by_name": True}


class DishCreate(DishBase):
    pass


class DishUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    price: Optional[int] = Field(None, gt=0)
    category: Optional[str] = Field(None, min_length=1, max_length=50)
    available_in: Optional[List[Shift]] = None
    is_available: Optional[bool] = None
    image_url: Optional[str] = None

    model_config = {"alias_generator": to_camel, "populate_by_name": True}


class DishResponse(DishBase):
    id: str
    created_at: datetime

    model_config = {"alias_generator": to_camel, "populate_by_name": True, "from_attributes": True}


class EntryItemBase(BaseModel):
    dish_id: str
    quantity: int = Field(..., ge=1, le=20)

    model_config = {"alias_generator": to_camel, "populate_by_name": True}


class EntryItemResponse(BaseModel):
    dish_id: str
    dish_name: str
    unit_price: int
    quantity: int
    line_total: int

    model_config = {"alias_generator": to_camel, "populate_by_name": True, "from_attributes": True}

    @property
    def line_total(self) -> int:
        return self.unit_price * self.quantity


class EntryBase(BaseModel):
    student_id: Optional[str] = None
    date_time: Optional[datetime] = None
    shift: Optional[Shift] = None
    items: List[EntryItemBase] = Field(..., min_length=1)
    note: Optional[str] = None

    model_config = {"alias_generator": to_camel, "populate_by_name": True}

    @model_validator(mode="after")
    def check_duplicate_dishes(self):
        dish_ids = [item.dish_id for item in self.items]
        if len(dish_ids) != len(set(dish_ids)):
            raise ValueError("Duplicate dish IDs not allowed")
        return self


class EntryCreate(EntryBase):
    pass


class EntryUpdate(BaseModel):
    date_time: Optional[datetime] = None
    shift: Optional[Shift] = None
    items: Optional[List[EntryItemBase]] = None
    note: Optional[str] = None

    model_config = {"alias_generator": to_camel, "populate_by_name": True}

    @model_validator(mode="after")
    def check_duplicate_dishes(self):
        if self.items is not None:
            dish_ids = [item.dish_id for item in self.items]
            if len(dish_ids) != len(set(dish_ids)):
                raise ValueError("Duplicate dish IDs not allowed")
        return self


class EntryResponse(BaseModel):
    id: str
    student_id: str
    student_name: str
    student_roll_number: Optional[str] = None
    date_time: datetime
    shift: Shift
    items: List[EntryItemResponse]
    total_amount: int
    amount_paid: int
    outstanding: int
    entry_status: EntryStatus
    payment_status: PaymentStatus
    is_overdue: bool
    paid_at: Optional[datetime] = None
    marked_paid_by: Optional[str] = None
    created_by: str
    note: Optional[str] = None
    is_disputed: bool
    dispute_reason: Optional[str] = None
    rejection_reason: Optional[str] = None
    last_edited_at: Optional[datetime] = None
    last_edited_by: Optional[str] = None
    created_at: datetime

    model_config = {"alias_generator": to_camel, "populate_by_name": True, "from_attributes": True}


class ApproveRequest(BaseModel):
    pass


class RejectRequest(BaseModel):
    reason: str = Field(..., min_length=3)


class DisputeRequest(BaseModel):
    reason: str = Field(..., min_length=5)


class ResolveDisputeRequest(BaseModel):
    pass


class MarkPaidRequest(BaseModel):
    pass


class ReopenRequest(BaseModel):
    pass


T = TypeVar("T")


class PaginatedResponse(BaseModel, Generic[T]):
    items: List[T]
    total: int
    limit: int
    offset: int

    model_config = {"alias_generator": to_camel, "populate_by_name": True}


class StudentSummary(BaseModel):
    id: str
    name: str
    username: Optional[str] = None
    roll_number: Optional[str] = None
    room_number: Optional[str] = None
    outstanding: int
    overdue_amount: int
    awaiting_approval: int

    model_config = {"alias_generator": to_camel, "populate_by_name": True, "from_attributes": True}


class PaymentCreate(BaseModel):
    amount: int = Field(..., gt=0)

    model_config = {"alias_generator": to_camel, "populate_by_name": True}


class PaymentAllocationResponse(BaseModel):
    entry_id: str
    amount: int

    model_config = {"alias_generator": to_camel, "populate_by_name": True, "from_attributes": True}


class PaymentResponse(BaseModel):
    id: str
    student_id: str
    amount: int
    recorded_by: str
    recorded_at: datetime
    is_undone: bool
    undone_at: Optional[datetime] = None
    allocations: List[PaymentAllocationResponse] = []

    model_config = {"alias_generator": to_camel, "populate_by_name": True, "from_attributes": True}


class PaymentPreviewResponse(BaseModel):
    fully_settled_count: int
    partially_paid_entry_id: Optional[str] = None
    partially_paid_amount: int = 0

    model_config = {"alias_generator": to_camel, "populate_by_name": True}


class PaymentRecordResponse(BaseModel):
    payment: PaymentResponse
    affected_entries: List[EntryResponse]
    student_balance: StudentSummary

    model_config = {"alias_generator": to_camel, "populate_by_name": True}


class DashboardSummary(BaseModel):
    today_sales: int
    total_outstanding: int
    overdue_amount: int
    pending_approvals: int
    disputed_entries: int
    today_by_shift: dict
    top_defaulters: List[StudentSummary]

    model_config = {"alias_generator": to_camel, "populate_by_name": True}


class MeSummary(BaseModel):
    outstanding: int
    awaiting_approval: int
    overdue_count: int
    recent_entries: List[EntryResponse]

    model_config = {"alias_generator": to_camel, "populate_by_name": True}


class HealthResponse(BaseModel):
    status: str = "ok"

    model_config = {"alias_generator": to_camel, "populate_by_name": True}


class ErrorDetail(BaseModel):
    code: str
    message: str
    details: Optional[Any] = None


class ErrorResponse(BaseModel):
    error: ErrorDetail

    model_config = {"alias_generator": to_camel, "populate_by_name": True}