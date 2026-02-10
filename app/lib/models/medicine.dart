class Medicine {
  final int? id;
  final String name;
  final String dosage;
  final String time;
  final int cycle;
  final String condition;
  final String doctor;
  final int stock;
  final int priority;

  Medicine({
    this.id,
    required this.name,
    required this.dosage,
    required this.time,
    required this.cycle,
    required this.condition,
    required this.doctor,
    required this.stock,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'time': time,
      'cycle': cycle,
      'condition': condition,
      'doctor': doctor,
      'stock': stock,
      'priority': priority,
    };
  }

  static Medicine fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'],
      name: map['name'],
      dosage: map['dosage'],
      time: map['time'],
      cycle: map['cycle'],
      condition: map['condition'],
      doctor: map['doctor'],
      stock: map['stock'],
      priority: map['priority'],
    );
  }
}