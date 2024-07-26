// sales_model.dart
/*class SalesModel {
  final int id;
  final String productName;
  final int totalQuantity;
  final double totalSales;
  final String date;  // Assuming you want to display the date as well

  SalesModel({
    required this.id,
    required this.productName,
    required this.totalQuantity,
    required this.totalSales,
    required this.date,
  });

  factory SalesModel.fromMap(Map<String, dynamic> json) => SalesModel(
    id: json["id"],
    productName: json["product_name"],
    totalQuantity: json["total_quantity"],
    totalSales: json["total_sales"],
    date: json["date"],  // Assuming the date field exists in the sales table
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "product_name": productName,
    "total_quantity": totalQuantity,
    "total_sales": totalSales,
    "date": date,  // Assuming you want to store the date as well
  };
}
*/

class SalesModel {
  final int? id;
  final String productName;
  final int totalQuantity;
  final double totalSales;
  final String date;

  SalesModel({
    required this.id,
    required this.productName,
    required this.totalQuantity,
    required this.totalSales,
    required this.date,
  });


  factory SalesModel.fromMap(Map<String, dynamic> map) {
    return SalesModel(
      id: map['id'] as int?,
      productName: map['product_name'] as String? ?? '',
      totalQuantity: map['total_quantity'] as int? ?? 0,
      totalSales: (map['total_sales'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] as String? ?? '',
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_name': productName,
      'total_quantity': totalQuantity,
      'total_sales': totalSales,
      'date': date,
    };
  }
}

