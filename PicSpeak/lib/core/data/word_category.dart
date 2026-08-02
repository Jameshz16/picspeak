/// A category of vocabulary words (e.g. "Animals", "Food", "Clothing").
class WordCategory {
  final String id;
  final String nameEs;
  final String nameEn;
  final String icon;

  const WordCategory({
    required this.id,
    required this.nameEs,
    required this.nameEn,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameEs': nameEs,
        'nameEn': nameEn,
        'icon': icon,
      };

  factory WordCategory.fromJson(Map<String, dynamic> json) => WordCategory(
        id: json['id'] as String,
        nameEs: json['nameEs'] as String,
        nameEn: json['nameEn'] as String,
        icon: json['icon'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
