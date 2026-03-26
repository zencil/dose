class Cabinet {
  final int? id;
  final String name;
  final String dosage;
  final String time;
  final int initstock;
  final int currstock;
  final int priority;
  final String category;
  final String unit;

  Cabinet({
    this.id,
    required this.name,
    required this.dosage,
    required this.time,
    required this.initstock,
    required this.currstock,
    required this.priority,
    this.category = 'tablet',
    this.unit = 'pills',
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
      'category': category,
      'unit': unit,
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
      category: map['category'] ?? 'tablet',
      unit: map['unit'] ?? 'pills',
    );
  }
}
