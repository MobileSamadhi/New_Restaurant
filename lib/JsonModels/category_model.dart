class CategoryModel {
  final int? categoryId;
  final String categoryName;
  final bool isActive;

  CategoryModel({
    this.categoryId,
    required this.categoryName,
    this.isActive = true,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> json) => CategoryModel(
    categoryId: json["categoryId"],
    categoryName: json["categoryName"],
    isActive: json["isActive"] == 1,
  );

  Map<String, dynamic> toMap() => {
    "categoryId": categoryId,
    "categoryName": categoryName,
    "isActive": isActive ? 1 : 0,
  };

  CategoryModel copyWith({
    int? categoryId,
    String? categoryName,
    bool? isActive,
  }) {
    return CategoryModel(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isActive: isActive ?? this.isActive,
    );
  }
}