class AddProductModel {
  final int? noteId;
  final String noteTitle;
  final double notePrice;
  final String noteContent;
  final String noteCategory;
  final String date;
  final String time;
  final int noteStock;
  late  int saleStock;
  late  int availableStock;
  final String? noteImage;

  AddProductModel({
    this.noteId,
    required this.noteTitle,
    required this.notePrice,
    required this.noteContent,
    required this.noteCategory,
    required this.date,
    required this.time,
    required this.noteStock,
    required this.saleStock,
    required this.availableStock,
    required this.noteImage,
  });

  // Convert a ProductModel into a Map
  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'noteTitle': noteTitle,
      'notePrice': notePrice,
      'noteContent': noteContent,
      'noteCategory': noteCategory,
      'date': date,
      'time': time,
      'noteStock': noteStock,
      'saleStock': saleStock,
      'availableStock': availableStock,
      'noteImage': noteImage,
    };
  }

  // Convert a Map into a ProductModel
  factory AddProductModel.fromMap(Map<String, dynamic> map) {
    return AddProductModel(
      noteId: map['noteId'],
      noteTitle: map['noteTitle'],
      notePrice: map['notePrice'],
      noteContent: map['noteContent'],
      noteCategory: map['noteCategory'],
      date: map['date'],
      time: map['time'],
      noteStock: map['noteStock'],
      saleStock: map['saleStock'],
      availableStock: map['availableStock'],
      noteImage: map['noteImage'],
    );
  }

  @override
  String toString() {
    return 'AddProductModel(noteId: $noteId, noteTitle: $noteTitle, notePrice: $notePrice, noteContent: $noteContent, noteCategory: $noteCategory, date: $date, time: $time, noteStock: $noteStock, saleStock: $saleStock, availableStock: $availableStock, noteImage: $noteImage)';
  }
}
