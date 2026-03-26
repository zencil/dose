import 'package:flutter_test/flutter_test.dart';
import 'package:dose/models/cabinet_model.dart';

void main() {
  group('Cabinet.toMap', () {
    test('includes category and unit fields', () {
      final cab = Cabinet(
        id: 1,
        name: 'Aspirin',
        dosage: '2',
        time: '08:00',
        initstock: 30,
        currstock: 28,
        priority: 1,
        category: 'tablet',
        unit: 'mg',
      );
      final map = cab.toMap();
      expect(map['category'], 'tablet');
      expect(map['unit'], 'mg');
      expect(map['name'], 'Aspirin');
      expect(map['dosage'], '2');
    });
  });

  group('Cabinet.fromMap', () {
    test('parses all fields including category and unit', () {
      final map = {
        'id': 5,
        'name': 'Ibuprofen',
        'dosage': '200',
        'time': '12:30',
        'initstock': 60,
        'currstock': 55,
        'priority': 2,
        'category': 'capsule',
        'unit': 'mg',
      };
      final cab = Cabinet.fromMap(map);
      expect(cab.id, 5);
      expect(cab.name, 'Ibuprofen');
      expect(cab.dosage, '200');
      expect(cab.category, 'capsule');
      expect(cab.unit, 'mg');
      expect(cab.priority, 2);
    });

    test('defaults category to tablet and unit to pills when missing', () {
      final map = {
        'id': 1,
        'name': 'OldMedicine',
        'dosage': '1',
        'time': '09:00',
        'initstock': 10,
        'currstock': 5,
        'priority': 0,
      };
      final cab = Cabinet.fromMap(map);
      expect(cab.category, 'tablet');
      expect(cab.unit, 'pills');
    });

    test('defaults when category and unit are null', () {
      final map = {
        'id': 2,
        'name': 'NullFields',
        'dosage': '3',
        'time': '14:00',
        'initstock': 20,
        'currstock': 18,
        'priority': 1,
        'category': null,
        'unit': null,
      };
      final cab = Cabinet.fromMap(map);
      expect(cab.category, 'tablet');
      expect(cab.unit, 'pills');
    });
  });

  group('Cabinet round-trip', () {
    test('toMap -> fromMap preserves all fields', () {
      final original = Cabinet(
        id: 10,
        name: 'Cough Syrup',
        dosage: '5',
        time: '20:00',
        initstock: 1,
        currstock: 1,
        priority: 0,
        category: 'liquid',
        unit: 'mL',
      );
      final restored = Cabinet.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.dosage, original.dosage);
      expect(restored.time, original.time);
      expect(restored.initstock, original.initstock);
      expect(restored.currstock, original.currstock);
      expect(restored.priority, original.priority);
      expect(restored.category, original.category);
      expect(restored.unit, original.unit);
    });
  });
}
