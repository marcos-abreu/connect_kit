import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/records/ck_nutrition.dart';
import 'package:connect_kit/src/models/records/ck_record.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';
import 'package:connect_kit/src/models/schema/ck_unit.dart';
import 'package:connect_kit/src/models/schema/ck_value.dart';
import 'package:connect_kit/src/models/ck_categories.dart';

void main() {
  group('CKNutrition', () {
    late CKSource source;
    late DateTime now;

    setUp(() {
      source = CKSource(recordingMethod: CKRecordingMethod.manualEntry);
      now = DateTime.now().toUtc();
    });

    group('Constructor and basic functionality', () {
      test('creates nutrition with minimum required parameters', () {
        final nutrition = CKNutrition(
          startTime: now,
          endTime: now,
          source: source,
        );

        expect(nutrition.startTime, equals(now));
        expect(nutrition.endTime, equals(now));
        expect(nutrition.source, equals(source));
        expect(nutrition.name, isNull);
        expect(nutrition.mealType, isNull);
        expect(nutrition.energy, isNull);
        expect(nutrition.protein, isNull);
      });

      test('creates nutrition with core macro nutrients', () {
        final nutrition = CKNutrition(
          startTime: now,
          endTime: now,
          source: source,
          name: 'Chicken Salad',
          mealType: CKMealType.lunch,
          energy: CKQuantityValue(350.0, CKUnit.energy.kilocalorie),
          protein: CKQuantityValue(25.0, CKUnit.mass.gram),
          totalCarbohydrate: CKQuantityValue(15.0, CKUnit.mass.gram),
          totalFat: CKQuantityValue(20.0, CKUnit.mass.gram),
          dietaryFiber: CKQuantityValue(5.0, CKUnit.mass.gram),
          sugar: CKQuantityValue(10.0, CKUnit.mass.gram),
          saturatedFat: CKQuantityValue(8.0, CKUnit.mass.gram),
          unsaturatedFat: CKQuantityValue(12.0, CKUnit.mass.gram),
          cholesterol: CKQuantityValue(70.0, CKUnit.mass.milligram),
          calcium: CKQuantityValue(200.0, CKUnit.mass.milligram),
          iron: CKQuantityValue(3.0, CKUnit.mass.milligram),
          vitaminC: CKQuantityValue(50.0, CKUnit.mass.milligram),
        );

        expect(nutrition.name, equals('Chicken Salad'));
        expect(nutrition.mealType, equals(CKMealType.lunch));
        expect(nutrition.energy?.value, equals(350.0));
        expect(nutrition.protein?.value, equals(25.0));
        expect(nutrition.totalCarbohydrate?.value, equals(15.0));
        expect(nutrition.totalFat?.value, equals(20.0));
        expect(nutrition.dietaryFiber?.value, equals(5.0));
        expect(nutrition.sugar?.value, equals(10.0));
        expect(nutrition.saturatedFat?.value, equals(8.0));
        expect(nutrition.unsaturatedFat?.value, equals(12.0));
        expect(nutrition.cholesterol?.value, equals(70.0));
        expect(nutrition.calcium?.value, equals(200.0));
        expect(nutrition.iron?.value, equals(3.0));
        expect(nutrition.vitaminC?.value, equals(50.0));
      });

      test('macros factory creates nutrition with macro nutrients', () {
        final nutrition = CKNutrition.macros(
          time: now,
          source: source,
          name: 'Oatmeal',
          mealType: CKMealType.breakfast,
          energy: CKQuantityValue(250.0, CKUnit.energy.kilocalorie),
          protein: CKQuantityValue(8.0, CKUnit.mass.gram),
          carbs: CKQuantityValue(40.0, CKUnit.mass.gram),
          fat: CKQuantityValue(5.0, CKUnit.mass.gram),
        );

        expect(nutrition.name, equals('Oatmeal'));
        expect(nutrition.mealType, equals(CKMealType.breakfast));
        expect(nutrition.energy?.value, equals(250.0));
        expect(nutrition.protein?.value, equals(8.0));
        expect(nutrition.totalCarbohydrate?.value, equals(40.0));
        expect(nutrition.totalFat?.value, equals(5.0));
        expect(nutrition.startTime, equals(now));
        expect(nutrition.endTime, equals(now));
        expect(nutrition.isInstantaneous, isTrue);
      });

      test('macros factory works with minimal parameters', () {
        final nutrition = CKNutrition.macros(
          time: now,
          source: source,
        );

        expect(nutrition.startTime, equals(now));
        expect(nutrition.endTime, equals(now));
        expect(nutrition.source, equals(source));
        expect(nutrition.name, isNull);
        expect(nutrition.mealType, isNull);
      });
    });

    group('CKRecord inheritance', () {
      test('nutrition extends CKRecord correctly', () {
        final nutrition = CKNutrition(
          startTime: now,
          endTime: now,
          source: source,
        );

        expect(nutrition, isA<CKRecord>());
        expect(nutrition.startTime, equals(now));
        expect(nutrition.endTime, equals(now));
        expect(nutrition.source, equals(source));
      });

      test('supports optional CKRecord parameters', () {
        const zoneOffset = Duration(hours: -5);
        final metadata = {'app': 'myfitnesspal'};

        final nutrition = CKNutrition(
          id: 'nutrition-123',
          startTime: now,
          endTime: now.add(const Duration(minutes: 30)),
          startZoneOffset: zoneOffset,
          endZoneOffset: zoneOffset,
          source: source,
          metadata: metadata,
        );

        expect(nutrition.id, equals('nutrition-123'));
        expect(nutrition.startZoneOffset, equals(zoneOffset));
        expect(nutrition.endZoneOffset, equals(zoneOffset));
        expect(nutrition.metadata, equals(metadata));
        expect(nutrition.duration, equals(const Duration(minutes: 30)));
      });
    });

    group('Fat and mineral coverage', () {
      test('supports all fat types', () {
        final nutrition = CKNutrition(
          startTime: now,
          endTime: now,
          source: source,
          saturatedFat: CKQuantityValue(5.0, CKUnit.mass.gram),
          unsaturatedFat: CKQuantityValue(10.0, CKUnit.mass.gram),
          monounsaturatedFat: CKQuantityValue(7.0, CKUnit.mass.gram),
          polyunsaturatedFat: CKQuantityValue(3.0, CKUnit.mass.gram),
          transFat: CKQuantityValue(0.5, CKUnit.mass.gram),
        );

        expect(nutrition.saturatedFat?.value, equals(5.0));
        expect(nutrition.unsaturatedFat?.value, equals(10.0));
        expect(nutrition.monounsaturatedFat?.value, equals(7.0));
        expect(nutrition.polyunsaturatedFat?.value, equals(3.0));
        expect(nutrition.transFat?.value, equals(0.5));
      });

      test('supports key minerals', () {
        final nutrition = CKNutrition(
          startTime: now,
          endTime: now,
          source: source,
          calcium: CKQuantityValue(1000.0, CKUnit.mass.milligram),
          chloride: CKQuantityValue(3400.0, CKUnit.mass.milligram),
          copper: CKQuantityValue(2.0, CKUnit.mass.milligram),
          iron: CKQuantityValue(18.0, CKUnit.mass.milligram),
          magnesium: CKQuantityValue(400.0, CKUnit.mass.milligram),
          phosphorus: CKQuantityValue(1000.0, CKUnit.mass.milligram),
          potassium: CKQuantityValue(4700.0, CKUnit.mass.milligram),
          sodium: CKQuantityValue(2300.0, CKUnit.mass.milligram),
          zinc: CKQuantityValue(11.0, CKUnit.mass.milligram),
        );

        expect(nutrition.calcium?.value, equals(1000.0));
        expect(nutrition.chloride?.value, equals(3400.0));
        expect(nutrition.copper?.value, equals(2.0));
        expect(nutrition.iron?.value, equals(18.0));
        expect(nutrition.magnesium?.value, equals(400.0));
        expect(nutrition.phosphorus?.value, equals(1000.0));
        expect(nutrition.potassium?.value, equals(4700.0));
        expect(nutrition.sodium?.value, equals(2300.0));
        expect(nutrition.zinc?.value, equals(11.0));
      });
    });

    group('Meal types', () {
      test('supports all meal types', () {
        final mealTypes = CKMealType.values;

        for (final mealType in mealTypes) {
          final nutrition = CKNutrition(
            startTime: now,
            endTime: now,
            source: source,
            name: 'Food for ${mealType.toString()}',
            mealType: mealType,
          );

          expect(nutrition.mealType, equals(mealType));
        }
      });
    });

    group('Integration tests', () {
      test('creates comprehensive nutrition record', () {
        final startTime = DateTime(2024, 1, 15, 12, 30).toUtc();
        final endTime = startTime.add(const Duration(minutes: 15));
        const zoneOffset = Duration(hours: -8);

        final nutrition = CKNutrition(
          id: 'full-meal-123',
          startTime: startTime,
          endTime: endTime,
          startZoneOffset: zoneOffset,
          endZoneOffset: zoneOffset,
          source: source,
          metadata: {
            'app': 'myfitnesspal',
            'restaurant': 'Chipotle',
            'meal_complexity': 'full'
          },
          name: 'Chipotle Chicken Bowl',
          mealType: CKMealType.lunch,
          energy: CKQuantityValue(740.0, CKUnit.energy.kilocalorie),
          protein: CKQuantityValue(45.0, CKUnit.mass.gram),
          totalCarbohydrate: CKQuantityValue(65.0, CKUnit.mass.gram),
          totalFat: CKQuantityValue(35.0, CKUnit.mass.gram),
          dietaryFiber: CKQuantityValue(15.0, CKUnit.mass.gram),
          sugar: CKQuantityValue(8.0, CKUnit.mass.gram),
          sodium: CKQuantityValue(2100.0, CKUnit.mass.milligram),
          cholesterol: CKQuantityValue(145.0, CKUnit.mass.milligram),
          calcium: CKQuantityValue(220.0, CKUnit.mass.milligram),
          iron: CKQuantityValue(5.5, CKUnit.mass.milligram),
          vitaminA: CKQuantityValue(1200.0, CKUnit.mass.milligram), // Using mg instead of mcg
          vitaminC: CKQuantityValue(35.0, CKUnit.mass.milligram),
        );

        // Verify all the properties
        expect(nutrition.id, equals('full-meal-123'));
        expect(nutrition.startTime, equals(startTime));
        expect(nutrition.endTime, equals(endTime));
        expect(nutrition.startZoneOffset, equals(zoneOffset));
        expect(nutrition.endZoneOffset, equals(zoneOffset));
        expect(nutrition.source, equals(source));
        expect(nutrition.metadata, equals({
          'app': 'myfitnesspal',
          'restaurant': 'Chipotle',
          'meal_complexity': 'full'
        }));
        expect(nutrition.name, equals('Chipotle Chicken Bowl'));
        expect(nutrition.mealType, equals(CKMealType.lunch));
        expect(nutrition.energy?.value, equals(740.0));
        expect(nutrition.protein?.value, equals(45.0));
        expect(nutrition.totalCarbohydrate?.value, equals(65.0));
        expect(nutrition.totalFat?.value, equals(35.0));
        expect(nutrition.dietaryFiber?.value, equals(15.0));
        expect(nutrition.sugar?.value, equals(8.0));
        expect(nutrition.sodium?.value, equals(2100.0));
        expect(nutrition.cholesterol?.value, equals(145.0));
        expect(nutrition.calcium?.value, equals(220.0));
        expect(nutrition.iron?.value, equals(5.5));
        expect(nutrition.vitaminA?.value, equals(1200.0));
        expect(nutrition.vitaminC?.value, equals(35.0));
        expect(nutrition.duration, equals(const Duration(minutes: 15)));
        expect(nutrition.isInstantaneous, isFalse);
      });

      test('handles empty vs null values correctly', () {
        final nutrition1 = CKNutrition(
          startTime: now,
          endTime: now,
          source: source,
          name: '',
          metadata: {},
        );

        final nutrition2 = CKNutrition(
          startTime: now,
          endTime: now,
          source: source,
        );

        expect(nutrition1.name, equals(''));
        expect(nutrition2.name, isNull);
        expect(nutrition1.metadata, equals({}));
        expect(nutrition2.metadata, isNull);
      });
    });
  });
}