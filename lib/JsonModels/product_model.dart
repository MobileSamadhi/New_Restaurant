// product_model.dart
class NoteModel {
  final int? noteId;
  final String noteTitle;
  final String noteContent;
  final double? notePrice;
  final String noteCategory;
  final String createdAt;
  final String? noteImage; // Add the noteImage field

  NoteModel({
    this.noteId,
    required this.noteTitle,
    required this.noteContent,
    required this.notePrice,
    required this.noteCategory,
    required this.createdAt,
    this.noteImage, // Add the noteImage parameter
  });

  factory NoteModel.fromMap(Map<String, dynamic> json) => NoteModel(
    noteId: json["noteId"],
    noteTitle: json["noteTitle"],
    noteContent: json["noteContent"],
    notePrice: json["notePrice"],
    noteCategory: json["noteCategory"],
    createdAt: json["createdAt"],
    noteImage: json["noteImage"], // Add the noteImage field in the factory
  );

  Map<String, dynamic> toMap() => {
    "noteId": noteId,
    "noteTitle": noteTitle,
    "noteContent": noteContent,
    "notePrice": notePrice,
    "noteCategory": noteCategory,
    "createdAt": createdAt,
    "noteImage": noteImage, // Add the noteImage field to the map
  };
}
