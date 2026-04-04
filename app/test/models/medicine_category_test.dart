import 'package:flutter_test/flutter_test.dart';
import 'package:dose/models/medicine_category.dart';

void main() {
  group('MedicineCategory', () {
    test('every category has at least one unit', () {
      for (final cat in MedicineCategory.values) {
        expect(cat.units, isNotEmpty, reason: '${cat.name} has no units');
      }
    });

    test('defaultUnit is the first entry in units', () {
      for (final cat in MedicineCategory.values) {
        expect(
          cat.defaultUnit,
          cat.units.first,
          reason: '${cat.name} defaultUnit mismatch',
        );
      }
    });

    test('fromString round-trips for all values', () {
      for (final cat in MedicineCategory.values) {
        expect(MedicineCategory.fromString(cat.name), cat);
      }
    });

    test('fromString returns tablet for unknown value', () {
      expect(MedicineCategory.fromString('unknown'), MedicineCategory.tablet);
      expect(MedicineCategory.fromString(''), MedicineCategory.tablet);
    });

    test('all categories have distinct labels', () {
      final labels = MedicineCategory.values.map((c) => c.label).toSet();
      expect(labels.length, MedicineCategory.values.length);
    });

    test('expected categories exist', () {
      final names = MedicineCategory.values.map((c) => c.name).toSet();
      expect(
        names,
        containsAll([
          'tablet',
          'capsule',
          'liquid',
          'injection',
          'topical',
          'inhaler',
        ]),
      );
    });
  });
}
