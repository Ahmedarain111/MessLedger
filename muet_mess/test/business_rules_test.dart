import 'package:flutter_test/flutter_test.dart';
import 'package:mess_ledger/models/enums.dart';
import 'package:mess_ledger/models/meal_item_model.dart';
import 'package:mess_ledger/models/meal_model.dart';
import 'package:mess_ledger/core/utils/ledger_rules.dart';

void main() {
  test('Meal total = sum of item line totals (multiple items)', () {
    const items = [
      MealItem(dishId: 'a', dishName: 'Chicken Qourma', unitPrice: 120, quantity: 1),
      MealItem(dishId: 'b', dishName: 'Daal Rice', unitPrice: 100, quantity: 2),
    ];
    final total = items.fold(0, (s, i) => s + i.lineTotal);
    expect(total, 320);
  });

  test('PaymentStatus derives correctly from totalAmount and amountPaid', () {
    expect(paymentStatusFor(200, 0), PaymentStatus.unpaid);
    expect(paymentStatusFor(200, 100), PaymentStatus.partiallyPaid);
    expect(paymentStatusFor(200, 200), PaymentStatus.paid);
  });

  test('Outstanding balance sums only approved entries', () {
    final now = DateTime.now();
    final entries = [
      Meal(
        id: '1',
        studentId: 's1',
        dateTime: now,
        shift: Shift.lunch,
        items: const [MealItem(dishId: 'd1', dishName: 'Biryani', unitPrice: 180, quantity: 1)],
        createdBy: 's1',
        entryStatus: EntryStatus.approved,
        amountPaid: 0,
        createdAt: now,
      ),
      Meal(
        id: '2',
        studentId: 's1',
        dateTime: now,
        shift: Shift.dinner,
        items: const [MealItem(dishId: 'd2', dishName: 'Roti', unitPrice: 15, quantity: 2)],
        createdBy: 's1',
        entryStatus: EntryStatus.pending,
        amountPaid: 0,
        createdAt: now,
      ),
      Meal(
        id: '3',
        studentId: 's1',
        dateTime: now,
        shift: Shift.dinner,
        items: const [MealItem(dishId: 'd3', dishName: 'Qorma', unitPrice: 200, quantity: 1)],
        createdBy: 's1',
        entryStatus: EntryStatus.rejected,
        amountPaid: 0,
        createdAt: now,
      ),
    ];

    expect(outstandingBalance(entries, studentId: 's1'), 180);
  });

  test('FIFO payment allocation settles oldest approved entry first', () {
    final t1 = DateTime(2026, 10, 1, 12);
    final t2 = DateTime(2026, 10, 2, 12);
    final entries = [
      Meal(
        id: '1',
        studentId: 's1',
        dateTime: t1,
        shift: Shift.lunch,
        items: const [MealItem(dishId: 'd1', dishName: 'Dish 1', unitPrice: 100, quantity: 1)],
        createdBy: 'm1',
        entryStatus: EntryStatus.approved,
        amountPaid: 0,
        createdAt: t1,
      ),
      Meal(
        id: '2',
        studentId: 's1',
        dateTime: t2,
        shift: Shift.dinner,
        items: const [MealItem(dishId: 'd2', dishName: 'Dish 2', unitPrice: 150, quantity: 1)],
        createdBy: 'm1',
        entryStatus: EntryStatus.approved,
        amountPaid: 0,
        createdAt: t2,
      ),
    ];

    final result = allocatePayment(
      entries: entries,
      amount: 150,
      managerId: 'm1',
      now: DateTime(2026, 10, 3),
    );

    expect(result.settlements.length, 2);
    expect(result.settlements[0].applied, 100);
    expect(result.settlements[0].settled, true);
    expect(result.settlements[1].applied, 50);
    expect(result.settlements[1].settled, false);
  });
}
