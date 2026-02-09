import 'dart:convert';

class BookmarkModel {
  final String name;
  final int suraNumber;
  final int verseNumber;
  final String color;

  BookmarkModel({
    required this.name,
    required this.suraNumber,
    required this.verseNumber,
    required this.color,
  });

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      name: map['name'] as String,
      suraNumber: map['suraNumber'] as int,
      verseNumber: map['verseNumber'] as int,
      color: map['color'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'suraNumber': suraNumber,
      'verseNumber': verseNumber,
      'color': color,
    };
  }

  factory BookmarkModel.fromJson(String source) =>
      BookmarkModel.fromMap(json.decode(source) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BookmarkModel &&
        other.suraNumber == suraNumber &&
        other.verseNumber == verseNumber;
  }

  @override
  int get hashCode => suraNumber.hashCode ^ verseNumber.hashCode;
}
