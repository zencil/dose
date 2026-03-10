class Cabinet {
  final int? id;
  final String name;
  final String dosage;
  final String time;
  final int initstock;
  final int currstock;
  final int priority;

  Cabinet({
    this.id,
    required this.name,
    required this.dosage,
    required this.time,
    required this.initstock,
    required this.currstock,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'time': time,
      'initstock': initstock,
      'currstock': currstock,
      'priority': priority,
    };
  }

  static Cabinet fromMap(Map<String, dynamic> map) {
    return Cabinet(
      id: map['id'],
      name: map['name'],
      dosage: map['dosage'],
      time: map['time'],
      initstock: map['initstock'],
      currstock: map['currstock'],
      priority: map['priority'],
    );
  }
}
