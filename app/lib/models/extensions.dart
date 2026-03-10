extension DoseString on String {
  String get formattedDosage {
    return replaceAll('mg', 'pills/spoons');
  }
}
