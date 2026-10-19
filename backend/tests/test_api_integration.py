import unittest
from datetime import datetime, timezone, timedelta
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.main import app
from app.database import engine, Base, SessionLocal
from app.models import User, Dish, UserRole, Shift, Entry, EntryStatus, Payment
from scripts.seed import seed_db


class TestMessLedgerAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Reset and seed database for a clean test state
        seed_db(reset=True)
        cls.client = TestClient(app)
        cls.db: Session = SessionLocal()

        # Login manager
        res_m = cls.client.post("/api/v1/auth/login", json={"username": "manager", "password": "manager123"})
        assert res_m.status_code == 200, f"Manager login failed: {res_m.text}"
        cls.manager_token = res_m.json()["accessToken"]
        cls.manager_headers = {"Authorization": f"Bearer {cls.manager_token}"}
        cls.manager_id = res_m.json()["user"]["id"]

        # Login student 1 (ahmed)
        res_s1 = cls.client.post("/api/v1/auth/login", json={"username": "ahmed", "password": "student123"})
        assert res_s1.status_code == 200, f"Student 1 login failed: {res_s1.text}"
        cls.student1_token = res_s1.json()["accessToken"]
        cls.student1_headers = {"Authorization": f"Bearer {cls.student1_token}"}
        cls.student1_id = res_s1.json()["user"]["id"]

        # Login student 2 (umer)
        res_s2 = cls.client.post("/api/v1/auth/login", json={"username": "umer", "password": "student123"})
        assert res_s2.status_code == 200, f"Student 2 login failed: {res_s2.text}"
        cls.student2_token = res_s2.json()["accessToken"]
        cls.student2_headers = {"Authorization": f"Bearer {cls.student2_token}"}
        cls.student2_id = res_s2.json()["user"]["id"]

    @classmethod
    def tearDownClass(cls):
        cls.db.close()

    # ==========================================
    # 1. Health Endpoint
    # ==========================================
    def test_01_health_check(self):
        res = self.client.get("/health")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json(), {"status": "ok"})

    # ==========================================
    # 2. Auth Endpoints
    # ==========================================
    def test_02_login_invalid_credentials(self):
        res = self.client.post("/api/v1/auth/login", json={"username": "manager", "password": "wrongpassword"})
        self.assertEqual(res.status_code, 401)
        self.assertEqual(res.json()["error"]["code"], "INVALID_CREDENTIALS")

    def test_03_auth_me_authenticated(self):
        res = self.client.get("/api/v1/auth/me", headers=self.manager_headers)
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["username"], "manager")
        self.assertEqual(res.json()["role"], "manager")

        res_s = self.client.get("/api/v1/auth/me", headers=self.student1_headers)
        self.assertEqual(res_s.status_code, 200)
        self.assertEqual(res_s.json()["username"], "ahmed")
        self.assertEqual(res_s.json()["role"], "student")

    def test_04_auth_me_unauthenticated(self):
        res = self.client.get("/api/v1/auth/me")
        self.assertEqual(res.status_code, 401)

    # ==========================================
    # 3. Users / Students Endpoints
    # ==========================================
    def test_05_list_students_as_manager(self):
        res = self.client.get("/api/v1/students", headers=self.manager_headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("items", data)
        self.assertGreaterEqual(len(data["items"]), 3)

    def test_06_list_students_as_student_forbidden(self):
        res = self.client.get("/api/v1/students", headers=self.student1_headers)
        self.assertEqual(res.status_code, 403)

    def test_07_get_student_by_id(self):
        # Manager can view student 1
        res = self.client.get(f"/api/v1/students/{self.student1_id}", headers=self.manager_headers)
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["username"], "ahmed")

        # Student 1 can view own profile
        res = self.client.get(f"/api/v1/students/{self.student1_id}", headers=self.student1_headers)
        self.assertEqual(res.status_code, 200)

        # Student 1 cannot view student 2's profile
        res = self.client.get(f"/api/v1/students/{self.student2_id}", headers=self.student1_headers)
        self.assertEqual(res.status_code, 403)

    # ==========================================
    # 4. Dishes (Menu) Endpoints
    # ==========================================
    def test_08_list_dishes(self):
        res = self.client.get("/api/v1/dishes", headers=self.student1_headers)
        self.assertEqual(res.status_code, 200)
        dishes = res.json()["items"]
        self.assertGreater(len(dishes), 0)
        for d in dishes:
            self.assertTrue(d["isAvailable"])

    def test_09_list_dishes_by_shift(self):
        res = self.client.get("/api/v1/dishes?shift=breakfast", headers=self.student1_headers)
        self.assertEqual(res.status_code, 200)
        for d in res.json()["items"]:
            self.assertIn("breakfast", d["availableIn"])

    def test_10_create_dish_as_student_forbidden(self):
        res = self.client.post("/api/v1/dishes", headers=self.student1_headers, json={
            "name": "Custom Halwa",
            "price": 80,
            "category": "Dessert",
            "availableIn": ["breakfast"],
            "isAvailable": True
        })
        self.assertEqual(res.status_code, 403)

    def test_11_create_and_update_dish_as_manager(self):
        # Create dish
        res = self.client.post("/api/v1/dishes", headers=self.manager_headers, json={
            "name": "Special Kheer",
            "price": 90,
            "category": "Dessert",
            "availableIn": ["lunch", "dinner"],
            "isAvailable": True,
            "imageUrl": "assets/food/default.png"
        })
        self.assertEqual(res.status_code, 201)
        created_dish = res.json()
        dish_id = created_dish["id"]
        self.assertEqual(created_dish["name"], "Special Kheer")
        self.assertEqual(created_dish["price"], 90)
        self.assertEqual(created_dish["imageUrl"], "assets/food/default.png")

        # Update dish price and availability
        res_patch = self.client.patch(f"/api/v1/dishes/{dish_id}", headers=self.manager_headers, json={
            "price": 100,
            "isAvailable": False
        })
        self.assertEqual(res_patch.status_code, 200)
        self.assertEqual(res_patch.json()["price"], 100)
        self.assertFalse(res_patch.json()["isAvailable"])

    # ==========================================
    # 5. Entries Lifecycle & Business Rules
    # ==========================================
    def test_12_student_creates_entry_starts_pending(self):
        # Get an available dish
        dishes = self.client.get("/api/v1/dishes", headers=self.student1_headers).json()["items"]
        dish = dishes[0]

        entry_data = {
            "shift": "lunch",
            "items": [{"dishId": dish["id"], "quantity": 2}],
            "note": "Student self entry"
        }
        res = self.client.post("/api/v1/entries", headers=self.student1_headers, json=entry_data)
        self.assertEqual(res.status_code, 201)
        entry = res.json()
        self.assertEqual(entry["entryStatus"], "pending")
        self.assertEqual(entry["studentId"], self.student1_id)
        self.assertEqual(entry["totalAmount"], dish["price"] * 2)
        self.assertEqual(entry["amountPaid"], 0)
        self.assertEqual(entry["paymentStatus"], "unpaid")
        self.assertFalse(entry["isDisputed"])

        TestMessLedgerAPI.pending_entry_id = entry["id"]

    def test_13_manager_creates_entry_starts_approved(self):
        dishes = self.client.get("/api/v1/dishes", headers=self.manager_headers).json()["items"]
        dish = dishes[0]

        entry_data = {
            "studentId": self.student1_id,
            "shift": "dinner",
            "items": [{"dishId": dish["id"], "quantity": 1}],
            "note": "Manager created entry"
        }
        res = self.client.post("/api/v1/entries", headers=self.manager_headers, json=entry_data)
        self.assertEqual(res.status_code, 201)
        entry = res.json()
        self.assertEqual(entry["entryStatus"], "approved")
        self.assertEqual(entry["studentId"], self.student1_id)
        self.assertEqual(entry["totalAmount"], dish["price"] * 1)

        TestMessLedgerAPI.approved_entry_id = entry["id"]

    def test_14_entry_creation_validation(self):
        # Quantity out of bounds
        dishes = self.client.get("/api/v1/dishes", headers=self.student1_headers).json()["items"]
        dish_id = dishes[0]["id"]

        res = self.client.post("/api/v1/entries", headers=self.student1_headers, json={
            "shift": "dinner",
            "items": [{"dishId": dish_id, "quantity": 0}]
        })
        self.assertEqual(res.status_code, 422)

        res = self.client.post("/api/v1/entries", headers=self.student1_headers, json={
            "shift": "dinner",
            "items": [{"dishId": dish_id, "quantity": 25}]
        })
        self.assertEqual(res.status_code, 422)

        # Manager missing studentId
        res = self.client.post("/api/v1/entries", headers=self.manager_headers, json={
            "shift": "dinner",
            "items": [{"dishId": dish_id, "quantity": 1}]
        })
        self.assertEqual(res.status_code, 422)

    def test_15_entries_visibility_isolation(self):
        # Student 2 lists entries -> should not see Student 1's entries
        res = self.client.get("/api/v1/entries", headers=self.student2_headers)
        self.assertEqual(res.status_code, 200)
        for item in res.json()["items"]:
            self.assertEqual(item["studentId"], self.student2_id)

        # Student 2 attempts to fetch Student 1's entry by ID -> 404
        res = self.client.get(f"/api/v1/entries/{self.pending_entry_id}", headers=self.student2_headers)
        self.assertEqual(res.status_code, 404)

        # Manager lists entries -> sees both
        res = self.client.get("/api/v1/entries", headers=self.manager_headers)
        self.assertEqual(res.status_code, 200)
        student_ids = {e["studentId"] for e in res.json()["items"]}
        self.assertIn(self.student1_id, student_ids)

    def test_16_manager_approves_entry(self):
        res = self.client.post(
            f"/api/v1/entries/{self.pending_entry_id}/approve",
            headers=self.manager_headers,
            json={}
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["entryStatus"], "approved")

        # Approving again -> 409 Conflict
        res_dup = self.client.post(
            f"/api/v1/entries/{self.pending_entry_id}/approve",
            headers=self.manager_headers,
            json={}
        )
        self.assertEqual(res_dup.status_code, 409)

    def test_17_manager_rejects_entry_workflow(self):
        # Student 1 creates another entry
        dishes = self.client.get("/api/v1/dishes?shift=breakfast", headers=self.student1_headers).json()["items"]
        res = self.client.post("/api/v1/entries", headers=self.student1_headers, json={
            "shift": "breakfast",
            "items": [{"dishId": dishes[0]["id"], "quantity": 1}]
        })
        to_reject_id = res.json()["id"]

        # Reject with valid reason
        res_rej = self.client.post(
            f"/api/v1/entries/{to_reject_id}/reject",
            headers=self.manager_headers,
            json={"reason": "Student was not present in hostel"}
        )
        self.assertEqual(res_rej.status_code, 200)
        self.assertEqual(res_rej.json()["entryStatus"], "rejected")
        self.assertEqual(res_rej.json()["rejectionReason"], "Student was not present in hostel")

        # Attempt to approve rejected entry -> 409 Conflict
        res_app = self.client.post(
            f"/api/v1/entries/{to_reject_id}/approve",
            headers=self.manager_headers,
            json={}
        )
        self.assertEqual(res_app.status_code, 409)

    def test_18_dispute_and_resolve_flow(self):
        # Student disputes own approved entry
        res = self.client.post(
            f"/api/v1/entries/{self.approved_entry_id}/dispute",
            headers=self.student1_headers,
            json={"reason": "I only ordered 1 roti, not 2"}
        )
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.json()["isDisputed"])
        self.assertEqual(res.json()["disputeReason"], "I only ordered 1 roti, not 2")

        # Manager resolves dispute
        res_res = self.client.post(
            f"/api/v1/entries/{self.approved_entry_id}/resolve-dispute",
            headers=self.manager_headers,
            json={}
        )
        self.assertEqual(res_res.status_code, 200)
        self.assertFalse(res_res.json()["isDisputed"])
        self.assertIsNone(res_res.json()["disputeReason"])

    # ==========================================
    # 6. Payments, FIFO Allocation, Reopen, and Undo
    # ==========================================
    def test_19_payment_preview_and_recording(self):
        # Check student 1's balance
        res_me = self.client.get("/api/v1/me/summary", headers=self.student1_headers)
        self.assertEqual(res_me.status_code, 200)
        outstanding = res_me.json()["outstanding"]
        self.assertGreater(outstanding, 0)

        # Payment preview
        res_prev = self.client.get(
            f"/api/v1/students/{self.student1_id}/payment-preview?amount={outstanding}",
            headers=self.manager_headers
        )
        self.assertEqual(res_prev.status_code, 200)
        self.assertIn("fullySettledCount", res_prev.json())

        # Payment exceeding outstanding -> 422
        res_excess = self.client.post(
            f"/api/v1/students/{self.student1_id}/payments",
            headers=self.manager_headers,
            json={"amount": outstanding + 1000}
        )
        self.assertEqual(res_excess.status_code, 422)

        # Record partial payment (e.g. 50 Rs)
        pay_amount = min(50, outstanding)
        res_pay = self.client.post(
            f"/api/v1/students/{self.student1_id}/payments",
            headers=self.manager_headers,
            json={"amount": pay_amount}
        )
        self.assertEqual(res_pay.status_code, 201)
        pay_data = res_pay.json()
        payment_id = pay_data["payment"]["id"]
        self.assertEqual(pay_data["payment"]["amount"], pay_amount)
        self.assertFalse(pay_data["payment"]["isUndone"])
        self.assertEqual(len(pay_data["payment"]["allocations"]), len(pay_data["affectedEntries"]))

        # Undo the payment
        res_undo = self.client.post(f"/api/v1/payments/{payment_id}/undo", headers=self.manager_headers, json={})
        self.assertEqual(res_undo.status_code, 200)
        self.assertTrue(res_undo.json()["isUndone"])

        # Undo again -> 409 Conflict
        res_undo_dup = self.client.post(f"/api/v1/payments/{payment_id}/undo", headers=self.manager_headers, json={})
        self.assertEqual(res_undo_dup.status_code, 409)

    def test_20_mark_paid_and_reopen_flow(self):
        # Manager marks approved entry paid
        res_mp = self.client.post(
            f"/api/v1/entries/{self.approved_entry_id}/mark-paid",
            headers=self.manager_headers,
            json={}
        )
        self.assertEqual(res_mp.status_code, 200)
        self.assertEqual(res_mp.json()["paymentStatus"], "paid")
        self.assertIsNotNone(res_mp.json()["paidAt"])

        # Attempt to edit fully paid entry -> 409 Conflict
        res_edit = self.client.patch(
            f"/api/v1/entries/{self.approved_entry_id}",
            headers=self.manager_headers,
            json={"note": "Editing paid entry"}
        )
        self.assertEqual(res_edit.status_code, 409)

        # Reopen entry
        res_reopen = self.client.post(
            f"/api/v1/entries/{self.approved_entry_id}/reopen",
            headers=self.manager_headers,
            json={}
        )
        self.assertEqual(res_reopen.status_code, 200)
        self.assertEqual(res_reopen.json()["paymentStatus"], "unpaid")
        self.assertEqual(res_reopen.json()["amountPaid"], 0)

        # Now editing is allowed
        res_edit_ok = self.client.patch(
            f"/api/v1/entries/{self.approved_entry_id}",
            headers=self.manager_headers,
            json={"note": "Successfully edited after reopening"}
        )
        self.assertEqual(res_edit_ok.status_code, 200)
        self.assertEqual(res_edit_ok.json()["note"], "Successfully edited after reopening")

    # ==========================================
    # 7. Dashboard Summaries
    # ==========================================
    def test_21_dashboard_summaries(self):
        # Manager dashboard
        res_m = self.client.get("/api/v1/dashboard/summary", headers=self.manager_headers)
        self.assertEqual(res_m.status_code, 200)
        m_data = res_m.json()
        self.assertIn("todaySales", m_data)
        self.assertIn("totalOutstanding", m_data)
        self.assertIn("pendingApprovals", m_data)

        # Student calling manager dashboard -> 403 Forbidden
        res_s_fail = self.client.get("/api/v1/dashboard/summary", headers=self.student1_headers)
        self.assertEqual(res_s_fail.status_code, 403)

        # Student summary via /me/summary
        res_s = self.client.get("/api/v1/me/summary", headers=self.student1_headers)
        self.assertEqual(res_s.status_code, 200)
        s_data = res_s.json()
        self.assertIn("outstanding", s_data)
        self.assertIn("awaitingApproval", s_data)

        # Student summary via /dashboard/me/summary (alias)
        res_s_alias = self.client.get("/api/v1/dashboard/me/summary", headers=self.student1_headers)
        self.assertEqual(res_s_alias.status_code, 200)
        self.assertEqual(res_s_alias.json()["outstanding"], s_data["outstanding"])

    # ==========================================
    # 8. Hostels & Student Account Creation
    # ==========================================
    def test_22_hostels_list(self):
        res = self.client.get("/api/v1/hostels", headers=self.student1_headers)
        self.assertEqual(res.status_code, 200)
        hostels = res.json()
        self.assertGreaterEqual(len(hostels), 4)
        names = [h["name"] for h in hostels]
        self.assertIn("Sheikh Sindhi", names)
        self.assertIn("GM Syed", names)
        self.assertIn("Jatoi", names)
        self.assertIn("Rashidi", names)

    def test_23_create_student_account(self):
        # Manager adds a new student account
        hostels_res = self.client.get("/api/v1/hostels", headers=self.manager_headers)
        ss_hostel_id = [h["id"] for h in hostels_res.json() if h["name"] == "Sheikh Sindhi"][0]

        student_payload = {
            "name": "Bilal Tariq",
            "rollNumber": "21CS099",
            "roomNumber": "C-301",
            "hostelId": ss_hostel_id
        }
        res = self.client.post("/api/v1/students", headers=self.manager_headers, json=student_payload)
        self.assertEqual(res.status_code, 201)
        created = res.json()
        self.assertEqual(created["name"], "Bilal Tariq")
        self.assertEqual(created["rollNumber"], "21CS099")
        self.assertEqual(created["hostelName"], "Sheikh Sindhi")
        self.assertEqual(created["role"], "student")

        # Test duplicate roll number rejection
        res_dup = self.client.post("/api/v1/students", headers=self.manager_headers, json=student_payload)
        self.assertEqual(res_dup.status_code, 409)
        self.assertEqual(res_dup.json()["error"]["code"], "ROLL_NUMBER_EXISTS")

        # Student cannot create student account (403)
        res_fail = self.client.post("/api/v1/students", headers=self.student1_headers, json={"name": "X", "rollNumber": "Y"})
        self.assertEqual(res_fail.status_code, 403)

    def test_24_entry_with_hostel_choice(self):
        hostels_res = self.client.get("/api/v1/hostels", headers=self.student1_headers)
        gms_hostel_id = [h["id"] for h in hostels_res.json() if h["name"] == "GM Syed"][0]

        # Student creates entry choosing GM Syed hostel
        dish = self.client.get("/api/v1/dishes", headers=self.student1_headers).json()["items"][0]
        res = self.client.post(
            "/api/v1/entries",
            headers=self.student1_headers,
            json={
                "hostelId": gms_hostel_id,
                "shift": "lunch",
                "items": [{"dishId": dish["id"], "quantity": 1}],
                "note": "Ate lunch at GM Syed"
            }
        )
        self.assertEqual(res.status_code, 201)
        data = res.json()
        self.assertEqual(data["hostelId"], gms_hostel_id)
        self.assertEqual(data["hostelName"], "GM Syed")


if __name__ == "__main__":
    unittest.main()
