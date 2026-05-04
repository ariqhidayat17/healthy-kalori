class WeightEntry {
  final int? id;
  final String date; // Format: dd/MM/yyyy
  final double weight; // in kg
  final String note;

  const WeightEntry({
    this.id,
    required this.date,
    required this.weight,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'weight': weight,
      'note': note,
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      weight: (map['weight'] as num).toDouble(),
      note: (map['note'] as String?) ?? '',
    );
  }

  WeightEntry copyWith({
    int? id,
    String? date,
    double? weight,
    String? note,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      note: note ?? this.note,
    );
  }
}
