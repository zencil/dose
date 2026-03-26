extension DoseString on String {
  /// Formats a raw dosage value with its unit for display.
  /// Example: "2" with unit "pills" → displayed via "$dosage $unit" at call site.
  /// This getter strips any legacy 'pills/spoons' suffix left from old data.
  String get formattedDosage {
    return replaceAll(' pills/spoons', '').trim();
  }
}
