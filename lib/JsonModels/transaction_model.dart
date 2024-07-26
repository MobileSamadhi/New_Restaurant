class TransactionModel {
  final int id;
  final String productName;
  final int totalQuantity;
  final double totalPrice;
  final String date;

  TransactionModel({
    required this.id,
    required this.productName,
    required this.totalQuantity,
    required this.totalPrice,
    required this.date,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      productName: map['product_name'],
      totalQuantity: map['total_quantity'],
      totalPrice: map['total_sales'],
      date: map['date'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_name': productName,
      'total_quantity': totalQuantity,
      'total_sales': totalPrice,
      'date': date,
    };
  }
}
