import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/schema/ck_value.dart';
import 'package:connect_kit/src/models/schema/ck_unit.dart';
import 'package:connect_kit/src/models/ck_categories.dart';

void main() {
  group('CKValue', () {
    late CKUnit metersPerSecond;
    late CKUnit bpm;

    setUp(() {
      metersPerSecond = CKUnit.velocity.metersPerSecond;
      bpm = CKUnit.compound.beatsPerMin;
    });

    group('CKValue sealed class hierarchy', () {
      test('CKValue is sealed and cannot be instantiated directly', () {
        // CKValue is an abstract/sealed class, so we test the concrete implementations
        final labelValue = CKLabelValue('test-label');
        final quantityValue = CKQuantityValue(42, CKUnit.energy.kilocalorie);
        final categoryValue = CKCategoryValue(CKBiologicalSexType.female);

        expect(labelValue, isA<CKValue>());
        expect(quantityValue, isA<CKValue>());
        expect(categoryValue, isA<CKValue>());
      });

      test('concrete types are constructible', () {
        final labelValue = CKLabelValue('test-label');
        final quantityValue = CKQuantityValue(42, CKUnit.energy.kilocalorie);
        final categoryValue = CKCategoryValue(CKBiologicalSexType.female);

        expect(labelValue.value, equals('test-label'));
        expect(quantityValue.value, equals(42.0));
        expect(categoryValue.value, equals(CKBiologicalSexType.female));
      });
    });

    group('unwrap method', () {
      test('performs pattern-matching and unwrapping correctly', () {
        final labelValue = CKLabelValue('test-label');
        final quantityValue =
            CKQuantityValue(150.0, CKUnit.compound.beatsPerMin);
        final categoryValue = CKCategoryValue(CKBiologicalSexType.female);

        // Test unwrapping with matching types
        final result1 = labelValue.unwrap<String?>(
          onLabel: (v) => 'Label: ${v.value}',
          onQuantity: (q) => 'Quantity: ${q.value} ${q.unit}',
          onCategory: (c) => 'Category: ${c.value}',
        );

        expect(result1, equals('Label: test-label'));
        expect(result1, isNotNull);

        // Test unwrapping with quantity only
        final result2 = quantityValue.unwrap<String?>(
          onQuantity: (q) => 'Quantity: ${q.value} ${q.unit}',
        );

        expect(result2, equals('Quantity: 150.0 $bpm'));
        expect(result2, isNotNull);

        // Test unwrapping with category only
        final result3 = quantityValue.unwrap<String?>(
          onCategory: (c) => 'Category: ${c.value}',
        );

        expect(result3,
            isNull); // CKQuantityValue doesn't match CKCategoryValue callback
      });

      test('returns null when no matching callback provided', () {
        final value = CKLabelValue('test-label');

        final result = value.unwrap<String?>(
          onQuantity: (q) => 'Quantity: ${q.value}',
        );

        expect(result, isNull);
      });

      test('unwraps CKMultipleValue and CKSamplesValue correctly', () {
        final multipleValue = CKMultipleValue({
          'systolic': CKQuantityValue(120, CKUnit.pressure.millimetersOfMercury),
          'diastolic': CKQuantityValue(80, CKUnit.pressure.millimetersOfMercury),
        });

        final samplesValue = CKSamplesValue([
          CKSample(72.0, const Duration(seconds: 0)),
          CKSample(75.0, const Duration(seconds: 1)),
        ], CKUnit.compound.beatsPerMin);

        // Test CKMultipleValue unwrapping
        final multipleResult = multipleValue.unwrap<String?>(
          onMultiple: (m) => 'Multiple with ${m.value.length} fields',
        );

        expect(multipleResult, equals('Multiple with 2 fields'));
        expect(multipleResult, isNotNull);

        // Test CKSamplesValue unwrapping
        final samplesResult = samplesValue.unwrap<String?>(
          onSamples: (s) => 'Samples with ${s.value.length} measurements',
        );

        expect(samplesResult, equals('Samples with 2 measurements'));
        expect(samplesResult, isNotNull);
      });

      test('returns null for CKMultipleValue and CKSamplesValue with non-matching callbacks', () {
        final multipleValue = CKMultipleValue({
          'key': CKLabelValue('value'),
        });
        final samplesValue = CKSamplesValue([], CKUnit.scalar.count);

        // Test CKMultipleValue with non-matching callback
        final multipleResult = multipleValue.unwrap<String?>(
          onLabel: (l) => 'Label: ${l.value}',
        );

        expect(multipleResult, isNull);

        // Test CKSamplesValue with non-matching callback
        final samplesResult = samplesValue.unwrap<String?>(
          onQuantity: (q) => 'Quantity: ${q.value}',
        );

        expect(samplesResult, isNull);
      });
    });

    group('unwrapOrElse method', () {
      test('performs pattern-matching with fallback', () {
        final labelValue = CKLabelValue('test-label');
        final quantityValue =
            CKQuantityValue(150.0, CKUnit.compound.beatsPerMin);

        final result1 = labelValue.unwrapOrElse<String>(
          onLabel: (v) => 'Label: ${v.value}',
          orElse: (v) => 'Unknown type: ${v.runtimeType}',
        );

        expect(result1, equals('Label: test-label'));

        final result2 = quantityValue.unwrapOrElse<String>(
          onLabel: (v) => 'Label: ${v.value}',
          orElse: (v) => 'Unknown type: ${v.runtimeType}',
        );

        expect(result2, contains('Unknown type'));
      });

      test('unwraps CKMultipleValue, CKSamplesValue, and CKCategoryValue with fallback correctly', () {
        final multipleValue = CKMultipleValue({
          'systolic': CKQuantityValue(120, CKUnit.pressure.millimetersOfMercury),
          'diastolic': CKQuantityValue(80, CKUnit.pressure.millimetersOfMercury),
        });

        final samplesValue = CKSamplesValue([
          CKSample(72.0, const Duration(seconds: 0)),
          CKSample(75.0, const Duration(seconds: 1)),
        ], CKUnit.compound.beatsPerMin);

        final categoryValue = CKCategoryValue(CKBiologicalSexType.female);

        // Test CKMultipleValue unwrapOrElse with matching callback
        final multipleResult = multipleValue.unwrapOrElse<String>(
          onMultiple: (m) => 'Multiple: ${m.value.length}',
          orElse: (v) => 'Fallback: ${v.runtimeType}',
        );

        expect(multipleResult, equals('Multiple: 2'));

        // Test CKSamplesValue unwrapOrElse with matching callback
        final samplesResult = samplesValue.unwrapOrElse<String>(
          onSamples: (s) => 'Samples: ${s.value.length}',
          orElse: (v) => 'Fallback: ${v.runtimeType}',
        );

        expect(samplesResult, equals('Samples: 2'));

        // Test CKCategoryValue unwrapOrElse with matching callback (covers line 92)
        final categoryResult = categoryValue.unwrapOrElse<String>(
          onCategory: (c) => 'Category: ${c.value}',
          orElse: (v) => 'Fallback: ${v.runtimeType}',
        );

        expect(categoryResult, equals('Category: ${CKBiologicalSexType.female}'));
      });

      test('uses fallback for CKMultipleValue and CKSamplesValue with non-matching callbacks', () {
        final multipleValue = CKMultipleValue({
          'key': CKLabelValue('value'),
        });
        final samplesValue = CKSamplesValue([], CKUnit.scalar.count);

        // Test CKMultipleValue with non-matching callback
        final multipleResult = multipleValue.unwrapOrElse<String>(
          onLabel: (l) => 'Label: ${l.value}',
          orElse: (v) => 'Fallback: ${v.runtimeType}',
        );

        expect(multipleResult, equals('Fallback: CKMultipleValue'));

        // Test CKSamplesValue with non-matching callback
        final samplesResult = samplesValue.unwrapOrElse<String>(
          onQuantity: (q) => 'Quantity: ${q.value}',
          orElse: (v) => 'Fallback: ${v.runtimeType}',
        );

        expect(samplesResult, equals('Fallback: CKSamplesValue'));
      });
    });
  });

  group('CKLabelValue', () {
    test('creates label value with string value', () {
      final value = CKLabelValue('steps_taken');
      expect(value.value, equals('steps_taken'));
      expect(value.unit, isNull);
    });

    test('creates label value', () {
      final value = CKLabelValue('sleep_session_123456');
      expect(value.value, equals('sleep_session_123456'));
      expect(value.unit, isNull);
    });

    test('handles empty string label', () {
      final value = CKLabelValue('');
      expect(value.value, equals(''));
      expect(value.unit, isNull);
    });

    test('handles very long label strings', () {
      final longLabel = 'A' * 1000;
      final value = CKLabelValue(longLabel);
      expect(value.value, equals(longLabel));
    });
  });

  group('CKQuantityValue', () {
    test('creates quantity value with value and unit', () {
      final value = CKQuantityValue(150, CKUnit.compound.beatsPerMin);
      expect(value.value, equals(150.0));
      expect(value.unit, equals(CKUnit.compound.beatsPerMin));
      expect(value.unit?.symbol, equals('bpm'));
    });

    test('creates quantity value with different units', () {
      final steps = CKQuantityValue(5000, CKUnit.scalar.count);
      final distance = CKQuantityValue(1.2, CKUnit.length.kilometer);
      final calories = CKQuantityValue(250, CKUnit.energy.kilocalorie);

      expect(steps.value, equals(5000.0));
      expect(steps.unit, equals(CKUnit.scalar.count));
      expect(distance.value, equals(1.2));
      expect(distance.unit, equals(CKUnit.length.kilometer));
      expect(calories.value, equals(250.0));
      expect(calories.unit, equals(CKUnit.energy.kilocalorie));
    });

    test('handles floating point values', () {
      final value = CKQuantityValue(3.14, CKUnit.length.meter);
      expect(value.value, closeTo(3.14, 0.001));
      expect(value.unit, equals(CKUnit.length.meter));
    });

    test('handles negative values', () {
      final value = CKQuantityValue(-15.2, CKUnit.length.meter);
      expect(value.value, equals(-15.2));
      expect(value.unit, equals(CKUnit.length.meter));
    });

    test('handles zero values', () {
      final value = CKQuantityValue(0, CKUnit.scalar.count);
      expect(value.value, equals(0.0));
      expect(value.unit, equals(CKUnit.scalar.count));
    });

    test('creates quantity value with unit symbol', () {
      final value = CKQuantityValue(42, CKUnit.energy.kilocalorie);
      expect(value.value, equals(42.0));
      expect(value.unit?.symbol, equals('kcal'));
    });
  });

  group('CKCategoryValue', () {
    test('creates category value with enum value', () {
      final workoutType = CKBiologicalSexType.female;
      final value = CKCategoryValue(workoutType);
      expect(value.value, equals(workoutType));
      expect(value.unit, isNull);
    });

    test('creates category value with different enums', () {
      final sexValue = CKCategoryValue(CKBiologicalSexType.male);
      final bloodTypeValue = CKCategoryValue(CKBloodType.aPositive);
      final skinTypeValue = CKCategoryValue(CKFitzpatrickSkinType.ii);

      expect(sexValue.value, equals(CKBiologicalSexType.male));
      expect(bloodTypeValue.value, equals(CKBloodType.aPositive));
      expect(skinTypeValue.value, equals(CKFitzpatrickSkinType.ii));
    });

    test('creates category value', () {
      final value = CKCategoryValue(CKBiologicalSexType.female);
      expect(value.value, equals(CKBiologicalSexType.female));
      expect(value.unit, isNull);
    });
  });

  group('CKMultipleValue', () {
    test('creates multiple value with map', () {
      final heartRateData = <String, CKValue<Object?>>{
        'systolic':
            CKQuantityValue(120.0, CKUnit.pressure.millimetersOfMercury),
        'diastolic':
            CKQuantityValue(80.0, CKUnit.pressure.millimetersOfMercury),
        'status': CKCategoryValue(CKMindfulnessSessionType.meditation),
      };

      final multipleValue = CKMultipleValue(heartRateData);
      expect(multipleValue.value, equals(heartRateData));
      expect(multipleValue.unit, isNull);
    });

    test('quantity method returns correct type', () {
      final data = <String, CKValue<Object?>>{
        'systolic':
            CKQuantityValue(120.0, CKUnit.pressure.millimetersOfMercury),
        'status': CKCategoryValue(CKMindfulnessSessionType.meditation),
      };

      final multipleValue = CKMultipleValue(data);

      expect(multipleValue.quantity('systolic')?.value, equals(120.0));
      expect(multipleValue.quantity('status'), isNull); // Not a quantity
      expect(multipleValue.quantity('nonexistent'), isNull); // Not found
    });

    test('category method returns correct type', () {
      final data = <String, CKValue<Object?>>{
        'systolic':
            CKQuantityValue(120.0, CKUnit.pressure.millimetersOfMercury),
        'status': CKCategoryValue(CKMindfulnessSessionType.meditation),
      };

      final multipleValue = CKMultipleValue(data);

      expect(multipleValue.category('status')?.value,
          equals(CKMindfulnessSessionType.meditation));
      expect(multipleValue.category('systolic'), isNull); // Not a category
      expect(multipleValue.category('nonexistent'), isNull); // Not found
    });

    test('numericValue method returns numeric values', () {
      final data = <String, CKValue<Object?>>{
        'systolic':
            CKQuantityValue(120.0, CKUnit.pressure.millimetersOfMercury),
        'status': CKCategoryValue(CKMindfulnessSessionType.meditation),
      };

      final multipleValue = CKMultipleValue(data);

      expect(multipleValue.numericValue('systolic'), equals(120.0));
      expect(multipleValue.numericValue('status'), isNull); // Not numeric
      expect(multipleValue.numericValue('nonexistent'), isNull); // Not found
    });

    test('stringValue method handles missing keys', () {
      final data = <String, CKValue<Object?>>{
        'systolic':
            CKQuantityValue(120.0, CKUnit.pressure.millimetersOfMercury),
      };

      final multipleValue = CKMultipleValue(data);

      // Test non-existent key
      expect(multipleValue.stringValue('nonexistent'), isNull); // Not found
    });

    test('creates multiple value with category only', () {
      final data = <String, CKValue<Object?>>{
        'status': CKCategoryValue(CKMindfulnessSessionType.meditation),
      };

      final multipleValue = CKMultipleValue(data);
      expect(multipleValue.value, equals(data));
      expect(multipleValue.unit, isNull);
    });
  });

  group('CKSamplesValue', () {
    test('creates samples value with list and unit', () {
      final samples = [
        CKSample(60.0, Duration.zero),
        CKSample(80.0, const Duration(minutes: 1)),
        CKSample(100.0, const Duration(minutes: 2)),
      ];

      final samplesValue = CKSamplesValue(samples, CKUnit.compound.beatsPerMin);
      expect(samplesValue.value, equals(samples));
      expect(samplesValue.unit, equals(CKUnit.compound.beatsPerMin));
    });

    test('numericValues returns all sample numeric values', () {
      final samples = [
        CKSample(60.0, Duration.zero),
        CKSample(80.0, const Duration(minutes: 1)),
        CKSample(100.0, const Duration(minutes: 2)),
      ];

      final samplesValue = CKSamplesValue(samples, CKUnit.compound.beatsPerMin);
      final numericValues = samplesValue.numericValues;

      expect(numericValues, isNotEmpty);
      expect(numericValues.length, equals(3));
      expect(numericValues, containsAll([60.0, 80.0, 100.0]));
      expect(numericValues[0], equals(60.0));
      expect(numericValues[1], equals(80.0));
      expect(numericValues[2], equals(100.0));
    });

    test('numericValueAt handles valid and invalid indices correctly', () {
      final samples = [
        CKSample(60.0, Duration.zero),
        CKSample(80.0, const Duration(minutes: 1)),
      ];

      final samplesValue = CKSamplesValue(samples, CKUnit.compound.beatsPerMin);

      // Test valid indices
      final firstValue = samplesValue.numericValueAt(0);
      final secondValue = samplesValue.numericValueAt(1);

      expect(firstValue, isNotNull);
      expect(firstValue, equals(60.0));

      expect(secondValue, isNotNull);
      expect(secondValue, equals(80.0));

      // Test invalid indices
      expect(samplesValue.numericValueAt(-1), isNull);
      expect(samplesValue.numericValueAt(2), isNull);
      expect(samplesValue.numericValueAt(10), isNull);
    });

    test('creates samples value with single sample', () {
      final samples = [
        CKSample(60.0, Duration.zero),
      ];

      final samplesValue = CKSamplesValue(samples, CKUnit.compound.beatsPerMin);
      expect(samplesValue.value, equals(samples));
      expect(samplesValue.unit, equals(CKUnit.compound.beatsPerMin));
    });
  });

  group('CKSample', () {
    test('creates sample with value and time', () {
      final sample = CKSample(75.5, const Duration(minutes: 5, seconds: 30));
      expect(sample.value, equals(75.5));
      expect(sample.time, equals(const Duration(minutes: 5, seconds: 30)));
    });

    test('creates sample with zero time', () {
      final sample = CKSample(120.0, Duration.zero);
      expect(sample.value, equals(120.0));
      expect(sample.time, equals(Duration.zero));
    });

    test('creates sample', () {
      final sample = CKSample(80.0, Duration.zero);
      expect(sample.value, equals(80.0));
      expect(sample.time, equals(Duration.zero));
    });

    test('handles negative values', () {
      final sample = CKSample(-10.0, const Duration(minutes: 1));
      expect(sample.value, equals(-10.0));
    });

    test('handles very large time values', () {
      final sample = CKSample(100.0, const Duration(days: 1));
      expect(sample.time, equals(const Duration(days: 1)));
    });

    group('Additional coverage tests', () {
      test('CKLabelValue with various string values', () {
        final emptyLabel = CKLabelValue('');
        final longLabel = CKLabelValue('A' * 1000);
        final specialLabel = CKLabelValue('test-label-with_symbols_123');

        expect(emptyLabel.value, equals(''));
        expect(longLabel.value, hasLength(1000));
        expect(specialLabel.value, equals('test-label-with_symbols_123'));
      });

      test('CKQuantityValue with various units', () {
        final steps = CKQuantityValue(5000, CKUnit.scalar.count);
        final meters = CKQuantityValue(1.75, CKUnit.length.meter);
        final bpm = CKQuantityValue(72.0, CKUnit.compound.beatsPerMin);
        final mmHg =
            CKQuantityValue(120.0, CKUnit.pressure.millimetersOfMercury);

        expect(steps.value, equals(5000.0));
        expect(steps.unit?.symbol, equals('count'));
        expect(meters.value, equals(1.75));
        expect(meters.unit?.symbol, equals('m'));
        expect(bpm.value, equals(72.0));
        expect(bpm.unit?.symbol, equals('bpm'));
        expect(mmHg.value, equals(120.0));
        expect(mmHg.unit?.symbol, equals('mmHg'));
      });

      test('CKCategoryValue with different enum types', () {
        final sex = CKCategoryValue(CKBiologicalSexType.male);
        final bloodType = CKCategoryValue(CKBloodType.aPositive);
        final skinType = CKCategoryValue(CKFitzpatrickSkinType.ii);

        expect(sex.value, equals(CKBiologicalSexType.male));
        expect(bloodType.value, equals(CKBloodType.aPositive));
        expect(skinType.value, equals(CKFitzpatrickSkinType.ii));
      });

      test('CKMultipleValue basic functionality', () {
        final data = <String, CKValue<Object?>>{
          'steps': CKQuantityValue(1000, CKUnit.scalar.count),
          'heartRate': CKLabelValue('72_bpm'),
          'status': CKCategoryValue(CKBiologicalSexType.female),
        };

        final multipleValue = CKMultipleValue(data);

        expect(multipleValue.value, equals(data));
        expect(multipleValue.value.keys,
            containsAll(['steps', 'heartRate', 'status']));
        expect(multipleValue.value.length, 3);
        expect(multipleValue.unit, isNull);
      });

      test('CKMultipleValue with empty data', () {
        final Map<String, CKValue<Object>> multipleValueMap = {};
        final multipleValue = CKMultipleValue(multipleValueMap);
        expect(multipleValue.value, isEmpty);
        expect(multipleValue.unit, isNull);
      });

      test('CKSamplesValue with different units', () {
        final samples = [
          CKSample(60.0, Duration.zero),
          CKSample(80.0, const Duration(seconds: 30)),
          CKSample(100.0, const Duration(minutes: 1)),
        ];

        final samplesValueBPM =
            CKSamplesValue(samples, CKUnit.compound.beatsPerMin);
        final samplesValueCount = CKSamplesValue(samples, CKUnit.scalar.count);

        expect(samplesValueBPM.value, hasLength(3));
        expect(samplesValueBPM.unit?.symbol, equals('bpm'));
        expect(samplesValueCount.value, hasLength(3));
        expect(samplesValueCount.unit?.symbol, equals('count'));
      });

      test('CKSamplesValue with single sample', () {
        final singleSample = [
          CKSample(75.5, const Duration(minutes: 5, seconds: 30))
        ];
        final samplesValue = CKSamplesValue(singleSample, CKUnit.length.meter);

        expect(samplesValue.value, hasLength(1));
        expect(samplesValue.value.first.value, equals(75.5));
        expect(samplesValue.value.first.time,
            equals(const Duration(minutes: 5, seconds: 30)));
        expect(samplesValue.unit?.symbol, equals('m'));
      });

      test('CKSample precision and edge cases', () {
        final sample1 = CKSample(0.0, Duration.zero);
        final sample2 = CKSample(-100.0, const Duration(hours: 24));
        final sample3 =
            CKSample(999999999.999, const Duration(milliseconds: 1));

        expect(sample1.value, equals(0.0));
        expect(sample2.value, equals(-100.0));
        expect(sample3.value, closeTo(999999999.999, 0.001));

        expect(sample1.time, equals(Duration.zero));
        expect(sample2.time, equals(const Duration(hours: 24)));
        expect(sample3.time, equals(const Duration(milliseconds: 1)));
      });

      test('CKValue unwrapOrElse with different types', () {
        final labelValue = CKLabelValue('test');
        final quantityValue = CKQuantityValue(42, CKUnit.scalar.count);
        final categoryValue = CKCategoryValue(CKBiologicalSexType.male);

        // Test unwrapOrElse with matching and non-matching types
        final labelResult = labelValue.unwrapOrElse<String>(
          onLabel: (v) => 'Label: ${v.value}',
          orElse: (v) => 'Unknown: ${v.runtimeType}',
        );

        final quantityResult = quantityValue.unwrapOrElse<String>(
          onLabel: (v) => 'Label: ${v.value}',
          orElse: (v) => 'Unknown: ${v.runtimeType}',
        );

        expect(labelResult, equals('Label: test'));
        expect(quantityResult, contains('Unknown'));
        expect(quantityResult, contains('CKQuantityValue'));
      });

      group('CKMultipleValue quantity accessor', () {
        test('should return quantity value for CKQuantityValue', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'quantity': CKQuantityValue(42, CKUnit.scalar.count),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.quantity('quantity');
          expect(result, isNotNull);
          expect(result, isA<CKQuantityValue>());
          expect(result?.value, equals(42));
          expect(result?.unit?.symbol, equals('count'));
        });

        test('should return null for non-quantity types', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'label': CKLabelValue('not_quantity'),
            'category': CKCategoryValue(CKBiologicalSexType.female),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          expect(multipleValue.quantity('label'), isNull);
          expect(multipleValue.quantity('category'), isNull);
        });

        test('should return null for non-existent key', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'existing': CKQuantityValue(100, CKUnit.scalar.count),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.quantity('nonexistent');
          expect(result, isNull);
        });
      });

      group('CKMultipleValue category accessor', () {
        test('should return category value for CKCategoryValue', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'category': CKCategoryValue(CKBiologicalSexType.female),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.category('category');
          expect(result, isNotNull);
          expect(result, isA<CKCategoryValue>());
          expect(result?.value, equals(CKBiologicalSexType.female));
        });

        test('should return null for non-category types', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'label': CKLabelValue('not_category'),
            'quantity': CKQuantityValue(100, CKUnit.scalar.count),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          expect(multipleValue.category('label'), isNull);
          expect(multipleValue.category('quantity'), isNull);
        });

        test('should return null for non-existent key', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'existing': CKCategoryValue(CKBiologicalSexType.female),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.category('nonexistent');
          expect(result, isNull);
        });
      });

      group('CKMultiple label accessor', () {
        test('should return label value for CKLabelValue', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'label': CKLabelValue('test_label'),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.label('label');
          expect(result, isNotNull);
          expect(result, isA<CKLabelValue>());
          expect(result?.value, equals('test_label'));
        });

        test('should return null for non-label types', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'quantity': CKQuantityValue(100, CKUnit.scalar.count),
            'category': CKCategoryValue(CKBiologicalSexType.female),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          expect(multipleValue.label('quantity'), isNull);
          expect(multipleValue.label('category'), isNull);
        });

        test('should return null for non-existent key', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'existing': CKLabelValue('test'),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.label('nonexistent');
          expect(result, isNull);
        });
      });

      group('CKMultipleValue samples accessor', () {
        test('should return samples value for CKSamplesValue', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'samples': CKSamplesValue(
              [
                CKSample(60.0, Duration.zero),
                CKSample(80.0, const Duration(seconds: 30)),
                CKSample(100.0, const Duration(minutes: 1)),
              ],
              CKUnit.compound.beatsPerMin,
            ),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.samples('samples');
          expect(result, isNotNull);
          expect(result, isA<CKSamplesValue>());
          expect(result?.value, isA<List<CKSample>>());
          expect(result?.value, hasLength(3));
          expect(result?.value![0].value, equals(60.0));
          expect(result?.value![1].value, equals(80.0));
          expect(result?.value![2].value, equals(100.0));
          expect(result?.value![0].time, equals(Duration.zero));
          expect(result?.value![1].time, equals(const Duration(seconds: 30)));
          expect(result?.value![2].time, equals(const Duration(minutes: 1)));
          expect(result?.unit, equals(CKUnit.compound.beatsPerMin));
        });

        test('should return null for non-samples types', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'quantity': CKQuantityValue(100, CKUnit.scalar.count),
            'category': CKCategoryValue(CKBiologicalSexType.female),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          expect(multipleValue.samples('quantity'), isNull);
          expect(multipleValue.samples('category'), isNull);
        });

        test('should return null for non-existent key', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'existing': CKSamplesValue(
              [
                CKSample(60.0, Duration.zero),
                CKSample(80.0, const Duration(seconds: 30)),
                CKSample(100.0, const Duration(minutes: 1)),
              ],
              CKUnit.compound.beatsPerMin,
            ),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.samples('nonexistent');
          expect(result, isNull);
        });
      });

      group('CKMultipleValue stringValue accessor', () {
        test('should return string value for CKLabelValue', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'label': CKLabelValue('test_string'),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.stringValue('label');
          expect(result, equals('test_string'));
        });

        test('should return null for non-string types', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'quantity': CKQuantityValue(100, CKUnit.scalar.count),
            'category': CKCategoryValue(CKBiologicalSexType.female),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          expect(multipleValue.stringValue('quantity'), isNull);
          expect(multipleValue.stringValue('category'), isNull);
        });

        test('should return null for non-existent key', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'existing': CKLabelValue('test'),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.stringValue('nonexistent');
          expect(result, isNull);
        });
      });

      group('CKMultipleValue numericValue accessor', () {
        test('should return numeric value for CKQuantityValue', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'quantity': CKQuantityValue(100.5, CKUnit.scalar.count),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.numericValue('quantity');
          expect(result, equals(100.5));
        });

        test('should return null for non-numeric types', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'label': CKLabelValue('not_numeric'),
            'category': CKCategoryValue(CKBiologicalSexType.male),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          expect(multipleValue.numericValue('label'), isNull);
          expect(multipleValue.numericValue('category'), isNull);
        });

        test('should return null for non-existent key', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'existing': CKQuantityValue(100.5, CKUnit.scalar.count),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.numericValue('nonExistingKey');
          expect(result, isNull);
        });
      });

      group('CKMultipleValue enumValue accessor', () {
        test('should return enum value for CKCategoryValue', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'category': CKCategoryValue(CKBiologicalSexType.male),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.enumValue('category');
          expect(result, equals(CKBiologicalSexType.male));
        });

        test('should return null for non-enum types', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'label': CKLabelValue('not_enum'),
            'quantity': CKQuantityValue(100.5, CKUnit.scalar.count),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          expect(multipleValue.enumValue('label'), isNull);
          expect(multipleValue.enumValue('quantity'), isNull);
        });

        test('should return null for non-existent key', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'existing': CKCategoryValue(CKBiologicalSexType.male),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.enumValue('nonExistingKey');
          expect(result, isNull);
        });
      });

      group('CKMultipleValue samplesValue accessor', () {
        test('should return samples value for CKSamplesValue', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'samples': CKSamplesValue(
              [
                CKSample(60.0, Duration.zero),
                CKSample(80.0, const Duration(seconds: 30)),
                CKSample(100.0, const Duration(minutes: 1)),
              ],
              CKUnit.compound.beatsPerMin,
            ),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.samplesValue('samples');
          expect(result, isNotNull);
          expect(result, hasLength(3));
          expect(result?[0].value, equals(60.0));
          expect(result?[1].value, equals(80.0));
          expect(result?[2].value, equals(100.0));
          expect(result?[0].time, equals(Duration.zero));
          expect(result?[1].time, equals(const Duration(seconds: 30)));
          expect(result?[2].time, equals(const Duration(minutes: 1)));
        });

        test('should return null for non-samples types', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'label': CKLabelValue('not_samples'),
            'quantity': CKQuantityValue(100.5, CKUnit.scalar.count),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          expect(multipleValue.samplesValue('label'), isNull);
          expect(multipleValue.samplesValue('quantity'), isNull);
        });

        test('should return null for non-existent key', () {
          final Map<String, CKValue<Object>> multipleValueMap = {
            'existing': CKSamplesValue(
              [
                CKSample(60.0, Duration.zero),
                CKSample(80.0, const Duration(seconds: 30)),
                CKSample(100.0, const Duration(minutes: 1)),
              ],
              CKUnit.compound.beatsPerMin,
            ),
          };
          final multipleValue = CKMultipleValue(multipleValueMap);

          final result = multipleValue.samplesValue('nonExistingKey');
          expect(result, isNull);
        });
      });
    });
  });
}
