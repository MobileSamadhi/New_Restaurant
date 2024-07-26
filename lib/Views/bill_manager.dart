// bill_manager.dart
class BillManager {
  static final BillManager _instance = BillManager._internal();

  factory BillManager() {
    return _instance;
  }

  BillManager._internal();

  int _billCounter = 1;

  String getCurrentBillNumber() {
    return _billCounter.toString().padLeft(10, '0');
  }

  void incrementBillCounter() {
    _billCounter++;
  }
}
