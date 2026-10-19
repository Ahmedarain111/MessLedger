import argparse
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy.orm import Session
from app.database import engine, Base, SessionLocal
from app.models import User, Dish, UserRole, Shift, Hostel
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
        
        # 1. Seed Hostels
        hostels_data = [
            {"name": "Sheikh Sindhi", "code": "SS"},
            {"name": "GM Syed", "code": "GMS"},
            {"name": "Jatoi", "code": "JAT"},
            {"name": "Rashidi", "code": "RASH"},
        ]
        hostels_map = {}
        for h in hostels_data:
            hostel = Hostel(name=h["name"], code=h["code"], is_active=True)
            db.add(hostel)
            hostels_map[h["name"]] = hostel
        db.flush()

        # 2. Seed Managers (Every hostel has one manager)
        managers = [
            User(
                name="Manager (Sheikh Sindhi)",
                role=UserRole.manager,
                username="manager",
                password_hash=get_password_hash("manager123"),
                hostel_id=hostels_map["Sheikh Sindhi"].id,
                is_active=True
            ),
            User(
                name="Manager (GM Syed)",
                role=UserRole.manager,
                username="manager_gms",
                password_hash=get_password_hash("manager123"),
                hostel_id=hostels_map["GM Syed"].id,
                is_active=True
            ),
            User(
                name="Manager (Jatoi)",
                role=UserRole.manager,
                username="manager_jatoi",
                password_hash=get_password_hash("manager123"),
                hostel_id=hostels_map["Jatoi"].id,
                is_active=True
            ),
            User(
                name="Manager (Rashidi)",
                role=UserRole.manager,
                username="manager_rashidi",
                password_hash=get_password_hash("manager123"),
                hostel_id=hostels_map["Rashidi"].id,
                is_active=True
            ),
        ]
        for m in managers:
            db.add(m)
        
        # 3. Seed Students (Boys only: Ahmed, Umer, Waqar)
        students = [
            User(
                name="Ahmed",
                role=UserRole.student,
                username="ahmed",
                password_hash=get_password_hash("student123"),
                roll_number="23CS032",
                room_number="A-101",
                hostel_id=hostels_map["Sheikh Sindhi"].id,
                is_active=True
            ),
            User(
                name="Umer",
                role=UserRole.student,
                username="umer",
                password_hash=get_password_hash("student123"),
                roll_number="23CS028",
                room_number="B-201",
                hostel_id=hostels_map["GM Syed"].id,
                is_active=True
            ),
            User(
                name="Waqar",
                role=UserRole.student,
                username="waqar",
                password_hash=get_password_hash("student123"),
                roll_number="23CS088",
                room_number="C-301",
                hostel_id=hostels_map["Jatoi"].id,
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
        print("Students: username=ahmed/umer/waqar (Roll: 23CS032/23CS028/23CS088), password=student123")
        
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
