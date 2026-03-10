class Profile {
  final int? id;
  final String name;
  final String donor;
  final String dob;
  final String bloodtype;
  final String sex;

  Profile({
    this.id,
    required this.name,
    required this.donor,
    required this.dob,
    required this.bloodtype,
    required this.sex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'donor': donor,
      'dob': dob,
      'bloodtype': bloodtype,
      'sex': sex,
    };
  }

  static Profile fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      name: map['name'],
      donor: map['donor'],
      dob: map['dob'],
      bloodtype: map['bloodtype'],
      sex: map['sex'],
    );
  }
}
