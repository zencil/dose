class Intake {
  final int? id;
  final String name;
  final String ttime;
  final String time;
  final String date;
  final int currstock;

  Intake({
    this.id,
    required this.name,
    required this.ttime,
    required this.time,
    required this.date,
    required this.currstock,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ttime': ttime,
      'time': time,
      'date': date,
      'currstock': currstock,
    };
  }

  static Intake fromMap(Map<String, dynamic> map) {
    return Intake(
      id: map['id'],
      name: map['name'],
      ttime: map['ttime'],
      time: map['time'],
      date: map['date'],
      currstock: map['currstock'],
    );
  }
}
