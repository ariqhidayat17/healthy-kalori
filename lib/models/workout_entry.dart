class WorkoutEntry {
  final int? id;
  final String date;
  final String exerciseName;
  final int sets;
  final int reps;
  final double weight;

  WorkoutEntry({
    this.id,
    required this.date,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'weight': weight,
    };
  }

  factory WorkoutEntry.fromMap(Map<String, dynamic> map) {
    return WorkoutEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      exerciseName: map['exerciseName'] as String,
      sets: map['sets'] as int,
      reps: map['reps'] as int,
      weight: (map['weight'] as num).toDouble(),
    );
  }
}
