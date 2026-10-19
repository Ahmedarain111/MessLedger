import enum
import uuid
from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy import (
    Column, String, Integer, DateTime, Boolean, ForeignKey, Enum, Text, JSON, UniqueConstraint
)
from sqlalchemy.orm import relationship
from app.database import Base


def gen_uuid() -> str:
    return str(uuid.uuid4())


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class UserRole(str, enum.Enum):
    student = "student"
    manager = "manager"


class Shift(str, enum.Enum):
    breakfast = "breakfast"
    lunch = "lunch"
    dinner = "dinner"


class EntryStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"


class PaymentStatus(str, enum.Enum):
    unpaid = "unpaid"
    partiallyPaid = "partiallyPaid"
    paid = "paid"


class Hostel(Base):
    __tablename__ = "hostels"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    name = Column(String(100), unique=True, nullable=False)
    code = Column(String(20), unique=True, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    users = relationship("User", back_populates="hostel")
    entries = relationship("Entry", back_populates="hostel")


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    name = Column(String(100), nullable=False)
    role = Column(Enum(UserRole), nullable=False)
    username = Column(String(50), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    roll_number = Column(String(50), nullable=True)
    room_number = Column(String(20), nullable=True)
    hostel_id = Column(String(36), ForeignKey("hostels.id"), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    hostel = relationship("Hostel", back_populates="users", foreign_keys=[hostel_id])
    entries = relationship("Entry", back_populates="student", foreign_keys="Entry.student_id")
    created_entries = relationship("Entry", back_populates="creator", foreign_keys="Entry.created_by")
    payments = relationship("Payment", back_populates="student", foreign_keys="Payment.student_id")
    recorded_payments = relationship("Payment", back_populates="recorder", foreign_keys="Payment.recorded_by")

    @property
    def hostel_name(self) -> Optional[str]:
        return self.hostel.name if self.hostel else None


class Dish(Base):
    __tablename__ = "dishes"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    name = Column(String(100), nullable=False)
    price = Column(Integer, nullable=False)
    category = Column(String(50), nullable=False)
    available_in = Column(JSON, nullable=False, default=list)
    is_available = Column(Boolean, default=True, nullable=False)
    image_url = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    entry_items = relationship("EntryItem", back_populates="dish")


class Entry(Base):
    __tablename__ = "entries"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    student_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    hostel_id = Column(String(36), ForeignKey("hostels.id"), nullable=True)
    date_time = Column(DateTime(timezone=True), nullable=False)
    shift = Column(Enum(Shift), nullable=False)
    entry_status = Column(Enum(EntryStatus), default=EntryStatus.pending, nullable=False)
    amount_paid = Column(Integer, default=0, nullable=False)
    paid_at = Column(DateTime(timezone=True), nullable=True)
    marked_paid_by = Column(String(36), ForeignKey("users.id"), nullable=True)
    created_by = Column(String(36), ForeignKey("users.id"), nullable=False)
    note = Column(Text, nullable=True)
    is_disputed = Column(Boolean, default=False, nullable=False)
    dispute_reason = Column(Text, nullable=True)
    rejection_reason = Column(Text, nullable=True)
    last_edited_at = Column(DateTime(timezone=True), nullable=True)
    last_edited_by = Column(String(36), ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    hostel = relationship("Hostel", back_populates="entries", foreign_keys=[hostel_id])
    student = relationship("User", back_populates="entries", foreign_keys=[student_id])
    creator = relationship("User", back_populates="created_entries", foreign_keys=[created_by])
    items = relationship("EntryItem", back_populates="entry", cascade="all, delete-orphan")
    allocations = relationship("PaymentAllocation", back_populates="entry")

    @property
    def hostel_name(self) -> Optional[str]:
        return self.hostel.name if self.hostel else None


class EntryItem(Base):
    __tablename__ = "entry_items"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    entry_id = Column(String(36), ForeignKey("entries.id", ondelete="CASCADE"), nullable=False)
    dish_id = Column(String(36), ForeignKey("dishes.id"), nullable=False)
    dish_name = Column(String(100), nullable=False)
    unit_price = Column(Integer, nullable=False)
    quantity = Column(Integer, nullable=False)

    entry = relationship("Entry", back_populates="items")
    dish = relationship("Dish", back_populates="entry_items")


class Payment(Base):
    __tablename__ = "payments"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    student_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    amount = Column(Integer, nullable=False)
    recorded_by = Column(String(36), ForeignKey("users.id"), nullable=False)
    recorded_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    is_undone = Column(Boolean, default=False, nullable=False)
    undone_at = Column(DateTime(timezone=True), nullable=True)

    student = relationship("User", back_populates="payments", foreign_keys=[student_id])
    recorder = relationship("User", back_populates="recorded_payments", foreign_keys=[recorded_by])
    allocations = relationship("PaymentAllocation", back_populates="payment", cascade="all, delete-orphan")


class PaymentAllocation(Base):
    __tablename__ = "payment_allocations"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    payment_id = Column(String(36), ForeignKey("payments.id", ondelete="CASCADE"), nullable=False)
    entry_id = Column(String(36), ForeignKey("entries.id"), nullable=False)
    amount = Column(Integer, nullable=False)

    payment = relationship("Payment", back_populates="allocations")
    entry = relationship("Entry", back_populates="allocations")