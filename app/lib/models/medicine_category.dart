import 'package:flutter/material.dart';

enum MedicineCategory {
  tablet(
    label: 'Tablet',
    icon: Icons.medication,
    units: ['pills', 'mg'],
  ),
  capsule(
    label: 'Capsule',
    icon: Icons.medication_outlined,
    units: ['capsules', 'mg'],
  ),
  liquid(
    label: 'Liquid',
    icon: Icons.water_drop,
    units: ['mL', 'spoons'],
  ),
  injection(
    label: 'Injection',
    icon: Icons.vaccines,
    units: ['mL', 'units'],
  ),
  topical(
    label: 'Topical',
    icon: Icons.back_hand,
    units: ['applications', 'mg'],
  ),
  inhaler(
    label: 'Inhaler',
    icon: Icons.air,
    units: ['puffs', 'mg'],
  );

  final String label;
  final IconData icon;
  final List<String> units;

  const MedicineCategory({
    required this.label,
    required this.icon,
    required this.units,
  });

  String get defaultUnit => units.first;

  /// Look up a category by its stored string name.
  /// Returns [MedicineCategory.tablet] for unknown values.
  static MedicineCategory fromString(String value) {
    for (final cat in MedicineCategory.values) {
      if (cat.name == value) return cat;
    }
    return MedicineCategory.tablet;
  }
}
