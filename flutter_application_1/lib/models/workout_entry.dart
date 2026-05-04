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
      'id': id,
      'date': date,
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'weight': weight,
    };
  }

  factory WorkoutEntry.fromMap(Map<String, dynamic> map) {
    return WorkoutEntry(
      id: map['id'],
      date: map['date'],
      exerciseName: map['exerciseName'],
      sets: map['sets'],
      reps: map['reps'],
      weight: map['weight'],
    );
  }
}
