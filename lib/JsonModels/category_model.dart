class CategoryModel {
  final int? categoryId;
  final String categoryName;

  CategoryModel({
    this.categoryId,
    required this.categoryName,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> json) => CategoryModel(
    categoryId: json["categoryId"],
    categoryName: json["categoryName"],
  );

  Map<String, dynamic> toMap() => {
    "categoryId": categoryId,
    "categoryName": categoryName,
  };
}
