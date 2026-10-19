import 'package:flutter/foundation.dart';

import '../models/payment_model.dart';
import '../services/api_payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentProvider({ApiPaymentService? service}) : _service = service ?? ApiPaymentService();

  final ApiPaymentService _service;

  bool loading = false;
  String? error;
  List<Payment> history = [];

  Future<void> load(String studentId) async {
    loading = true;
    notifyListeners();
    try {
      history = await _service.getPayments(studentId: studentId);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<List<Payment>> getPayments({required String studentId}) async {
    return _service.getPayments(studentId: studentId);
  }

  Future<PaymentRecordResult> record({
    required String studentId,
    required int amount,
  }) async {
    loading = true;
    notifyListeners();
    try {
      final result = await _service.recordPayment(studentId: studentId, amount: amount);
      history = [result.payment, ...history];
      return result;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<PaymentPreview> preview({
    required String studentId,
    required int amount,
  }) async {
    return _service.previewPayment(studentId: studentId, amount: amount);
  }

  Future<Payment> undo(String paymentId) async {
    loading = true;
    notifyListeners();
    try {
      final p = await _service.undoPayment(paymentId);
      final i = history.indexWhere((x) => x.id == paymentId);
      if (i >= 0) history[i] = p;
      return p;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
