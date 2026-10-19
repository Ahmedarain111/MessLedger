import argparse
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy.orm import Session
from app.database import engine, Base, SessionLocal
from app.models import User, Dish, UserRole, Shift
from app.security import get_password_hash


def seed_db(reset: bool = False):
    if reset:
        print("Dropping all tables...")
        Base.metadata.drop_all(bind=engine)
        print("Creating all tables...")
        Base.metadata.create_all(bind=engine)
    else:
        print("Creating tables (if not exist)...")
        Base.metadata.create_all(bind=engine)
    
    db: Session = SessionLocal()
    try:
        if db.query(User).filter(User.username == "manager").first():
            print("Database already seeded. Use --reset to re-seed.")
            return
        
        manager = User(
            name="Mess Manager",
            role=UserRole.manager,
            username="manager",
            password_hash=get_password_hash("manager123"),
            roll_number=None,
            room_number=None,
            is_active=True
        )
        db.add(manager)
        
        students = [
            User(
                name="Ahmed Khan",
                role=UserRole.student,
                username="ahmedkhan",
                password_hash=get_password_hash("student123"),
                roll_number="CS2021001",
                room_number="A-101",
                is_active=True
            ),
            User(
                name="Fatima Ali",
                role=UserRole.student,
                username="fatimaali",
                password_hash=get_password_hash("student123"),
                roll_number="CS2021002",
                room_number="A-102",
                is_active=True
            ),
            User(
                name="Hassan Ahmed",
                role=UserRole.student,
                username="hassanahmed",
                password_hash=get_password_hash("student123"),
                roll_number="EE2021001",
                room_number="B-201",
                is_active=True
            ),
            User(
                name="Zara Malik",
                role=UserRole.student,
                username="zaramalik",
                password_hash=get_password_hash("student123"),
                roll_number="ME2021001",
                room_number="B-202",
                is_active=True
            ),
        ]
        for s in students:
            db.add(s)
        
        dishes = [
            Dish(
                name="Paratha",
                price=30,
                category="Breakfast",
                available_in=[Shift.breakfast.value],
                is_available=True,
                image_url="assets/food/paratha.png"
            ),
            Dish(
                name="Omelette",
                price=40,
                category="Breakfast",
                available_in=[Shift.breakfast.value],
                is_available=True,
                image_url="assets/food/anda_omelette.png"
            ),
            Dish(
                name="Chai",
                price=20,
                category="Beverages",
                available_in=[Shift.breakfast.value, Shift.lunch.value, Shift.dinner.value],
                is_available=True,
                image_url="assets/food/default.png"
            ),
            Dish(
                name="Chicken Biryani",
                price=180,
                category="Lunch",
                available_in=[Shift.lunch.value],
                is_available=True,
                image_url="assets/food/chicken_biryani.png"
            ),
            Dish(
                name="Daal Chawal",
                price=100,
                category="Lunch",
                available_in=[Shift.lunch.value],
                is_available=True,
                image_url="assets/food/daal_rice.png"
            ),
            Dish(
                name="Beef Qorma",
                price=200,
                category="Lunch",
                available_in=[Shift.lunch.value],
                is_available=True,
                image_url="assets/food/beef_qourma_120.png"
            ),
            Dish(
                name="Roti",
                price=15,
                category="Bread",
                available_in=[Shift.lunch.value, Shift.dinner.value],
                is_available=True,
                image_url="assets/food/default.png"
            ),
            Dish(
                name="Chicken Karahi",
                price=250,
                category="Dinner",
                available_in=[Shift.dinner.value],
                is_available=True,
                image_url="assets/food/chicken_karhai.png"
            ),
            Dish(
                name="Fish Fry",
                price=180,
                category="Dinner",
                available_in=[Shift.dinner.value],
                is_available=True,
                image_url="assets/food/fish.png"
            ),
            Dish(
                name="Vegetable Pulao",
                price=120,
                category="Dinner",
                available_in=[Shift.dinner.value],
                is_available=True,
                image_url="assets/food/vegetable_pulao.png"
            ),
            Dish(
                name="Raita",
                price=30,
                category="Sides",
                available_in=[Shift.lunch.value, Shift.dinner.value],
                is_available=True,
                image_url="assets/food/default.png"
            ),
            Dish(
                name="Salad",
                price=25,
                category="Sides",
                available_in=[Shift.lunch.value, Shift.dinner.value],
                is_available=True,
                image_url="assets/food/default.png"
            ),
        ]
        for d in dishes:
            db.add(d)
        
        db.commit()
        print("Database seeded successfully!")
        print("Manager: username=manager, password=manager123")
        print("Students: username=ahmedkhan/fatimaali/hassanahmed/zaramalik, password=student123")
        
    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Seed the MessLedger database")
    parser.add_argument("--reset", action="store_true", help="Drop and recreate all tables before seeding")
    args = parser.parse_args()
    
    seed_db(reset=args.reset)