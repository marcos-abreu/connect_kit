import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/schema/ck_type.dart';
import 'package:connect_kit/src/models/ck_access_type.dart';
import 'package:connect_kit/src/models/schema/ck_value.dart';
import 'package:connect_kit/src/models/schema/ck_unit.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';
import 'package:connect_kit/src/models/schema/ck_device.dart';
import 'package:connect_kit/src/models/ck_categories.dart';
import 'package:connect_kit/src/models/records/ck_record.dart';
import 'package:connect_kit/src/models/records/ck_audiogram.dart';
import 'package:connect_kit/src/models/records/ck_blood_pressure.dart';
import 'package:connect_kit/src/models/records/ck_ecg.dart';
import 'package:connect_kit/src/models/records/ck_nutrition.dart';
import 'package:connect_kit/src/models/records/ck_data_record.dart';
import 'package:connect_kit/src/models/records/ck_sleep_session.dart';
import 'package:connect_kit/src/models/records/ck_workout.dart';
import 'package:connect_kit/src/mapper/request_mappers.dart';

/// Custom test record class that extends CKRecord but doesn't have specific mapping
class _CustomTestRecord extends CKRecord {
  _CustomTestRecord({
    required super.startTime,
    required super.endTime,
    super.source,
    super.id,
    super.metadata,
  });
}

void main() {
  group('CKTypeMapping extension', () {
    group('expandCompositeTypes', () {
      test('expands composite type to its default components', () {
        final input = {CKType.bloodPressure};
        final result = input.expandCompositeTypes();

        expect(result, contains(CKType.bloodPressure.systolic));
        expect(result, contains(CKType.bloodPressure.diastolic));
        expect(result, isNot(contains(CKType.bloodPressure)));
      });

      test('keeps simple types unchanged', () {
        final input = {CKType.steps, CKType.height};
        final result = input.expandCompositeTypes();

        expect(result, equals(input));
      });

      test('keeps component types unchanged', () {
        final input = {CKType.nutrition.energy, CKType.nutrition.protein};
        final result = input.expandCompositeTypes();

        expect(result, equals(input));
      });

      test('expands nutrition composite type', () {
        final input = {CKType.nutrition};
        final result = input.expandCompositeTypes();

        expect(result, contains(CKType.nutrition.energy));
        expect(result, contains(CKType.nutrition.protein));
        expect(result, contains(CKType.nutrition.carbs));
        expect(result, contains(CKType.nutrition.fat));
        expect(result, isNot(contains(CKType.nutrition)));
      });

      test('expands workout composite type', () {
        final input = {CKType.workout};
        final result = input.expandCompositeTypes();

        // workout's default includes workout itself + distance
        expect(result, contains(CKType.workout));
        expect(result, contains(CKType.workout.distance));
      });

      test('handles mix of composite and simple types', () {
        final input = {
          CKType.steps,
          CKType.bloodPressure,
          CKType.height,
        };
        final result = input.expandCompositeTypes();

        expect(result, contains(CKType.steps));
        expect(result, contains(CKType.height));
        expect(result, contains(CKType.bloodPressure.systolic));
        expect(result, contains(CKType.bloodPressure.diastolic));
        expect(result, isNot(contains(CKType.bloodPressure)));
      });

      test('handles empty set', () {
        final input = <CKType>{};
        final result = input.expandCompositeTypes();

        expect(result, isEmpty);
      });

      test('does not duplicate types', () {
        final input = {
          CKType.bloodPressure,
          CKType.bloodPressure.systolic,
        };
        final result = input.expandCompositeTypes();

        // systolic should appear only once
        expect(
            result.where((t) => t == CKType.bloodPressure.systolic).length, 1);
        expect(result, contains(CKType.bloodPressure.systolic));
        expect(result, contains(CKType.bloodPressure.diastolic));
      });

      test('handles mixed composite and component types correctly', () {
        final input = {
          CKType.nutrition, // composite
          CKType.nutrition.energy, // component - should not duplicate
          CKType.bloodPressure, // composite
          CKType.bloodPressure.systolic, // component - should not duplicate
          CKType.steps, // simple
        };

        final result = input.expandCompositeTypes();

        // Should include expanded components but not duplicates
        expect(result, contains(CKType.nutrition.energy));
        expect(result, contains(CKType.nutrition.protein));
        expect(result, contains(CKType.bloodPressure.systolic));
        expect(result, contains(CKType.bloodPressure.diastolic));
        expect(result, contains(CKType.steps));

        // Should not include parent composite types
        expect(result, isNot(contains(CKType.nutrition)));
        expect(result, isNot(contains(CKType.bloodPressure)));

        // Count should be reasonable (no duplicates)
        expect(result.length, lessThanOrEqualTo(9));
      });
    });

    group('mapToRequest', () {
      test('converts CKType set to string list', () {
        final input = {CKType.steps, CKType.height, CKType.weight};
        final result = input.mapToRequest();

        expect(result, isA<List<String>>());
        expect(result, contains('steps'));
        expect(result, contains('height'));
        expect(result, contains('weight'));
      });

      test('handles composite component types', () {
        final input = {CKType.nutrition.energy, CKType.nutrition.protein};
        final result = input.mapToRequest();

        expect(result, contains('nutrition.energy'));
        expect(result, contains('nutrition.protein'));
      });

      test('handles empty set', () {
        final input = <CKType>{};
        final result = input.mapToRequest();

        expect(result, isEmpty);
      });

      test('preserves all types in conversion', () {
        final input = {
          CKType.steps,
          CKType.bloodPressure.systolic,
          CKType.heartRate,
        };
        final result = input.mapToRequest();

        expect(result.length, 3);
      });
    });

    group('chained operations', () {
      test('expandCompositeTypes then mapToRequest works correctly', () {
        final input = {CKType.bloodPressure, CKType.steps};
        final result = input.expandCompositeTypes().mapToRequest();

        expect(result, contains('bloodPressure.systolic'));
        expect(result, contains('bloodPressure.diastolic'));
        expect(result, contains('steps'));
        expect(result, isNot(contains('bloodPressure')));
      });

      test('preserves type order in predictable way', () {
        final input = {CKType.steps, CKType.height, CKType.weight};
        final result = input.expandCompositeTypes().mapToRequest();

        // Should contain all three types as strings
        expect(result, contains('steps'));
        expect(result, contains('height'));
        expect(result, contains('weight'));
        expect(result.length, 3);
      });
    });
  });

  group('DataAccessStatus extension', () {
    group('mapToRequest', () {
      test('converts simple types with access types', () {
        final input = {
          CKType.steps: {CKAccessType.read, CKAccessType.write},
          CKType.height: {CKAccessType.read},
        };
        final result = input.mapToRequest();

        expect(result['steps'], containsAll(['read', 'write']));
        expect(result['height'], equals(['read']));
      });

      test('expands composite types automatically', () {
        final input = {
          CKType.bloodPressure: {CKAccessType.read, CKAccessType.write},
        };
        final result = input.mapToRequest();

        expect(
            result['bloodPressure.systolic'], containsAll(['read', 'write']));
        expect(
            result['bloodPressure.diastolic'], containsAll(['read', 'write']));
        expect(result, isNot(contains('bloodPressure')));
      });

      test('handles component types correctly', () {
        final input = {
          CKType.nutrition.energy: {CKAccessType.read},
          CKType.nutrition.protein: {CKAccessType.write},
        };
        final result = input.mapToRequest();

        expect(result['nutrition.energy'], equals(['read']));
        expect(result['nutrition.protein'], equals(['write']));
      });

      test('handles empty map', () {
        final input = <CKType, Set<CKAccessType>>{};
        final result = input.mapToRequest();

        expect(result, isEmpty);
      });

      test('handles empty access type set', () {
        final input = {
          CKType.steps: <CKAccessType>{},
        };
        final result = input.mapToRequest();

        expect(result['steps'], isEmpty);
      });

      test('handles mix of composite and simple types', () {
        final input = {
          CKType.steps: {CKAccessType.read},
          CKType.bloodPressure: {CKAccessType.write},
          CKType.height: {CKAccessType.read, CKAccessType.write},
        };
        final result = input.mapToRequest();

        expect(result['steps'], equals(['read']));
        expect(result['bloodPressure.systolic'], equals(['write']));
        expect(result['bloodPressure.diastolic'], equals(['write']));
        expect(result['height'], containsAll(['read', 'write']));
      });

      test('applies same access types to all expanded components', () {
        final input = {
          CKType.nutrition: {CKAccessType.read, CKAccessType.write},
        };
        final result = input.mapToRequest();

        // All nutrition components should have same access types
        expect(result['nutrition.energy'], containsAll(['read', 'write']));
        expect(result['nutrition.protein'], containsAll(['read', 'write']));
        expect(result['nutrition.carbs'], containsAll(['read', 'write']));
        expect(result['nutrition.fat'], containsAll(['read', 'write']));
      });

      test('workout special case includes workout itself', () {
        final input = {
          CKType.workout: {CKAccessType.read},
        };
        final result = input.mapToRequest();

        // workout defaultComponents includes workout + distance
        expect(result['workout'], equals(['read']));
        expect(result['workout.distance'], equals(['read']));
      });

      test('handles complex access patterns', () {
        final input = {
          CKType.steps: {CKAccessType.read, CKAccessType.write},
          CKType.heartRate: {CKAccessType.read},
          CKType.bloodPressure: {CKAccessType.read, CKAccessType.write},
          CKType.sleepSession: {CKAccessType.write},
        };

        final result = input.mapToRequest();

        // Steps should be expanded and have read/write
        expect(result['steps'], containsAll(['read', 'write']));

        // Blood pressure should be expanded to components
        expect(
            result['bloodPressure.systolic'], containsAll(['read', 'write']));
        expect(
            result['bloodPressure.diastolic'], containsAll(['read', 'write']));

        // Sleep session should be expanded to components
        expect(result['sleepSession.inBed'], contains('write'));
        expect(result['sleepSession.asleep'], contains('write'));
        expect(result['sleepSession.awake'], contains('write'));
        expect(result['sleepSession.light'], contains('write'));
        expect(result['sleepSession.deep'], contains('write'));
        expect(result['sleepSession.rem'], contains('write'));
        expect(result['sleepSession.outOfBed'], contains('write'));

        // Simple types should work normally
        expect(result['heartRate'], equals(['read']));
      });
    });
  });

  group('CKDeviceMapping extension', () {
    test('maps device to request format', () {
      final device = CKDevice(
        manufacturer: 'Apple',
        model: 'iPhone 14',
        type: CKDeviceType.phone,
        hardwareVersion: '1.0',
        softwareVersion: '17.0',
      );

      final result = device.mapToRequest();

      expect(result['manufacturer'], equals('Apple'));
      expect(result['model'], equals('iPhone 14'));
      expect(result['type'], equals('phone')); // .name returns 'phone'
      expect(result['hardwareVersion'], equals('1.0'));
      expect(result['softwareVersion'], equals('17.0'));
    });

    test('maps minimal device to request format', () {
      final device = CKDevice(
        manufacturer: null,
        model: null,
        type: CKDeviceType.unknown,
        hardwareVersion: null,
        softwareVersion: null,
      );

      final result = device.mapToRequest();

      expect(result['manufacturer'], isNull);
      expect(result['model'], isNull);
      expect(result['type'], equals('unknown')); // .name returns 'unknown'
      expect(result['hardwareVersion'], isNull);
      expect(result['softwareVersion'], isNull);
    });

    test('handles different device types', () {
      final phone = CKDevice(
        manufacturer: 'Apple',
        model: 'iPhone 14',
        type: CKDeviceType.phone,
      );

      final watch = CKDevice(
        manufacturer: 'Samsung',
        model: 'Galaxy Watch 5',
        type: CKDeviceType.watch,
      );

      final scale = CKDevice(
        manufacturer: 'Withings',
        model: 'Body+',
        type: CKDeviceType.scale,
      );

      final phoneResult = phone.mapToRequest();
      final watchResult = watch.mapToRequest();
      final scaleResult = scale.mapToRequest();

      expect(phoneResult['type'], equals('phone'));
      expect(watchResult['type'], equals('watch'));
      expect(scaleResult['type'], equals('scale'));
    });

    test('handles device with minimal information', () {
      final device = CKDevice(
        manufacturer: null,
        model: null,
        type: CKDeviceType.unknown,
        hardwareVersion: null,
        softwareVersion: null,
      );

      final result = device.mapToRequest();

      expect(result['manufacturer'], isNull);
      expect(result['model'], isNull);
      expect(result['type'], equals('unknown'));
      expect(result['hardwareVersion'], isNull);
      expect(result['softwareVersion'], isNull);
    });

    test('handles device with version information', () {
      final device = CKDevice(
        manufacturer: 'Garmin',
        model: 'Forerunner 955',
        type: CKDeviceType.watch,
        hardwareVersion: '2.0',
        softwareVersion: '15.2.1',
      );

      final result = device.mapToRequest();

      expect(result['hardwareVersion'], equals('2.0'));
      expect(result['softwareVersion'], equals('15.2.1'));
    });

    test('handles device with only software version', () {
      final device = CKDevice(
        manufacturer: 'Fitbit',
        model: 'Versa 4',
        type: CKDeviceType.watch,
        hardwareVersion: null,
        softwareVersion: '1.0.2',
      );

      final result = device.mapToRequest();

      expect(result['hardwareVersion'], isNull);
      expect(result['softwareVersion'], equals('1.0.2'));
    });

    test('handles device with only hardware version', () {
      final device = CKDevice(
        manufacturer: 'Polar',
        model: 'Vantage M',
        type: CKDeviceType.watch,
        hardwareVersion: '3.1',
        softwareVersion: null,
      );

      final result = device.mapToRequest();

      expect(result['hardwareVersion'], equals('3.1'));
      expect(result['softwareVersion'], isNull);
    });

    test('handles device with no version information', () {
      final device = CKDevice(
        manufacturer: 'Unknown',
        model: 'Generic Device',
        type: CKDeviceType.unknown,
        hardwareVersion: null,
        softwareVersion: null,
      );

      final result = device.mapToRequest();

      expect(result['hardwareVersion'], isNull);
      expect(result['softwareVersion'], isNull);
    });
  });

  group('CKSourceMapping extension', () {
    test('maps source to request format', () {
      final source = CKSource(
        recordingMethod: CKRecordingMethod.manualEntry,
      );

      final result = source.mapToRequest();

      expect(result['recordingMethod'], equals('manualEntry'));
    });

    test('maps source with device to request format', () {
      final device = CKDevice(
        manufacturer: 'Apple',
        model: 'iPhone 14',
        type: CKDeviceType.phone,
        hardwareVersion: '1.0',
        softwareVersion: '17.0',
      );

      final source = CKSource(
        recordingMethod: CKRecordingMethod.automaticallyRecorded,
        device: device,
      );

      final result = source.mapToRequest();

      expect(result['recordingMethod'], equals('automaticallyRecorded'));
      expect(result['device'], isNotNull);
    });

    test('handles different recording methods', () {
      final manualSource =
          CKSource(recordingMethod: CKRecordingMethod.manualEntry);
      final automaticSource =
          CKSource(recordingMethod: CKRecordingMethod.automaticallyRecorded);
      final activeSource =
          CKSource(recordingMethod: CKRecordingMethod.automaticallyRecorded);

      final manualResult = manualSource.mapToRequest();
      final automaticResult = automaticSource.mapToRequest();
      final activeResult = activeSource.mapToRequest();

      expect(manualResult['recordingMethod'], equals('manualEntry'));
      expect(
          automaticResult['recordingMethod'], equals('automaticallyRecorded'));
      expect(activeResult['recordingMethod'], equals('automaticallyRecorded'));
    });

    test('handles source with device information', () {
      final device = CKDevice(
        manufacturer: 'Apple',
        model: 'iPhone 14',
        type: CKDeviceType.phone,
        hardwareVersion: '1.0',
        softwareVersion: '17.0',
      );

      final source = CKSource(
        recordingMethod: CKRecordingMethod.automaticallyRecorded,
        device: device,
      );

      final result = source.mapToRequest();

      expect(result['recordingMethod'], equals('automaticallyRecorded'));
      expect(result['device'], isNotNull);

      final deviceMap = result['device'] as Map<String, dynamic>;
      expect(deviceMap['manufacturer'], equals('Apple'));
      expect(deviceMap['model'], equals('iPhone 14'));
      expect(deviceMap['type'], equals('phone'));
      expect(deviceMap['hardwareVersion'], equals('1.0'));
      expect(deviceMap['softwareVersion'], equals('17.0'));
    });

    test('handles source with partial device information', () {
      final device = CKDevice(
        manufacturer: 'Fitbit',
        model: 'Charge 5',
        type: CKDeviceType.watch,
        // hardwareVersion and softwareVersion are null
      );

      final source = CKSource(
        recordingMethod: CKRecordingMethod.automaticallyRecorded,
        device: device,
      );

      final result = source.mapToRequest();

      final deviceMap = result['device'] as Map<String, dynamic>;
      expect(deviceMap['manufacturer'], equals('Fitbit'));
      expect(deviceMap['model'], equals('Charge 5'));
      expect(deviceMap['type'], equals('watch'));
      expect(deviceMap['hardwareVersion'], isNull);
      expect(deviceMap['softwareVersion'], isNull);
    });
  });

  group('CKValueMapping extension', () {
    group('CKQuantityValueMapping', () {
      test('maps quantity value to request format', () {
        final quantityValue = CKQuantityValue(100, CKUnit.scalar.count);
        final result = quantityValue.mapToRequest();

        expect(result['value'], equals(100));
        expect(result['unit'], equals('count'));
        expect(result['valuePattern'], equals('quantity'));
      });

      test('CKQuantityValue with different units', () {
        final steps = CKQuantityValue(1000, CKUnit.scalar.count);
        final meters = CKQuantityValue(1.75, CKUnit.length.meter);
        final bpm = CKQuantityValue(72, CKUnit.compound.beatsPerMin);
        final calories = CKQuantityValue(250, CKUnit.energy.kilocalorie);

        final stepsResult = steps.mapToRequest();
        final metersResult = meters.mapToRequest();
        final bpmResult = bpm.mapToRequest();
        final caloriesResult = calories.mapToRequest();

        expect(stepsResult['value'], equals(1000.0));
        expect(stepsResult['unit'], equals('count'));
        expect(stepsResult['valuePattern'], equals('quantity'));

        expect(metersResult['value'], equals(1.75));
        expect(metersResult['unit'], equals('m'));
        expect(metersResult['valuePattern'], equals('quantity'));

        expect(bpmResult['value'], equals(72.0));
        expect(bpmResult['unit'], equals('bpm'));
        expect(bpmResult['valuePattern'], equals('quantity'));

        expect(caloriesResult['value'], equals(250.0));
        expect(caloriesResult['unit'], equals('kcal'));
        expect(caloriesResult['valuePattern'], equals('quantity'));
      });

      test('CKQuantityValue with different units - edge cases', () {
        final steps = CKQuantityValue(0, CKUnit.scalar.count);
        final negativeValue = CKQuantityValue(-50, CKUnit.length.meter);

        final stepsResult = steps.mapToRequest();
        final negativeResult = negativeValue.mapToRequest();

        expect(stepsResult['value'], equals(0.0));
        expect(stepsResult['unit'], equals('count'));
        expect(stepsResult['valuePattern'], equals('quantity'));

        expect(negativeResult['value'], equals(-50.0));
        expect(negativeResult['unit'], equals('m'));
        expect(negativeResult['valuePattern'], equals('quantity'));
      });
    });

    group('CKCategoryValueMapping', () {
      test('maps category value to request format', () {
        final categoryValue = CKCategoryValue(CKBiologicalSexType.male);
        final result = categoryValue.mapToRequest();

        expect(result['value'], equals('male'));
        expect(result['valuePattern'], equals('category'));
        expect(result['categoryName'], equals('CKBiologicalSexType'));
      });

      test('CKCategoryValue with various enums', () {
        final sex = CKCategoryValue(CKBiologicalSexType.male);
        final bloodType = CKCategoryValue(CKBloodType.aPositive);
        final skinType = CKCategoryValue(CKFitzpatrickSkinType.iv);

        final sexResult = sex.mapToRequest();
        final bloodTypeResult = bloodType.mapToRequest();
        final skinTypeResult = skinType.mapToRequest();

        expect(sexResult['value'], equals('male'));
        expect(sexResult['valuePattern'], equals('category'));

        expect(bloodTypeResult['value'], equals('aPositive'));
        expect(bloodTypeResult['valuePattern'], equals('category'));

        expect(skinTypeResult['value'], equals('iv'));
        expect(skinTypeResult['valuePattern'], equals('category'));
      });
    });

    group('CKLabelValueMapping', () {
      test('maps label value to request format', () {
        final labelValue = CKLabelValue('test-label');
        final result = labelValue.mapToRequest();

        expect(result['value'], equals('test-label'));
        expect(result['valuePattern'], equals('label'));
      });

      test('CKLabelValue with various strings', () {
        final simpleLabel = CKLabelValue('test_label');
        final complexLabel = CKLabelValue('workout_session_12345');
        final numericLabel = CKLabelValue('42');
        final emptyLabel = CKLabelValue('');

        final simpleResult = simpleLabel.mapToRequest();
        final complexResult = complexLabel.mapToRequest();
        final numericResult = numericLabel.mapToRequest();
        final emptyResult = emptyLabel.mapToRequest();

        expect(simpleResult['value'], equals('test_label'));
        expect(simpleResult['valuePattern'], equals('label'));

        expect(complexResult['value'], equals('workout_session_12345'));
        expect(complexResult['valuePattern'], equals('label'));

        expect(numericResult['value'], equals('42'));
        expect(numericResult['valuePattern'], equals('label'));

        expect(emptyResult['value'], equals(''));
        expect(emptyResult['valuePattern'], equals('label'));
      });
    });

    group('CKMultipleValueMapping', () {
      test('maps multiple value to request format', () {
        final Map<String, CKValue<Object>> multipleValueMap = {
          'systolic':
              CKQuantityValue(120.0, CKUnit.pressure.millimetersOfMercury),
          'diastolic':
              CKQuantityValue(80.0, CKUnit.pressure.millimetersOfMercury),
          'status': CKCategoryValue(CKBiologicalSexType.male),
        };
        final multipleValue = CKMultipleValue(multipleValueMap);

        final result = multipleValue.mapToRequest();

        expect(result['valuePattern'], equals('multiple'));
        expect(result['value'], isNotNull);
        expect(result['unit'], isNull);

        final valueMap = result['value'] as Map<String, dynamic>;
        expect(valueMap['systolic'], isNotNull);
        expect(valueMap['diastolic'], isNotNull);
        expect(valueMap['status'], isNotNull);
      });

      test('maps empty multiple value to request format', () {
        final Map<String, CKValue<Object>> multipleValueMap = {};
        final multipleValue = CKMultipleValue(multipleValueMap);

        final result = multipleValue.mapToRequest();

        expect(result['valuePattern'], equals('multiple'));
        expect(result['value'], equals({}));
        expect(result['unit'], isNull);
      });

      test('maps multiple value with nested structures to request format', () {
        final Map<String, CKValue<Object>> subMultipleValueMap = {
          'average': CKQuantityValue(75.0, CKUnit.compound.beatsPerMin),
          'max': CKQuantityValue(120.0, CKUnit.compound.beatsPerMin),
        };
        final Map<String, CKValue<Object>> multipleValueMap = {
          'heartRateData': CKMultipleValue(subMultipleValueMap),
          'status': CKLabelValue('completed'),
        };
        final multipleValue = CKMultipleValue(multipleValueMap);

        final result = multipleValue.mapToRequest();

        final valueMap = result['value'] as Map<String, dynamic>;
        final heartRateData = valueMap['heartRateData'] as Map<String, dynamic>;
        final heartRateValue = heartRateData['value'] as Map<String, dynamic>;
        expect(heartRateValue['average'], isNotNull);
        expect(heartRateValue['max'], isNotNull);
        expect(valueMap['status'], isNotNull);
      });

      test('CKMultipleValue with nested structures', () {
        final Map<String, CKValue<Object>> multipleValueMap = {
          'basicQuantity': CKQuantityValue(100, CKUnit.scalar.count),
          'nestedCategory': CKCategoryValue(CKBiologicalSexType.female),
          'stringLabel': CKLabelValue('test'),
        };
        final multipleValue = CKMultipleValue(multipleValueMap);

        final result = multipleValue.mapToRequest();

        expect(result['valuePattern'], equals('multiple'));
        expect(result['unit'], isNull);

        final valueMap = result['value'] as Map<String, dynamic>;
        expect(valueMap['basicQuantity'], isNotNull);
        expect(valueMap['nestedCategory'], isNotNull);
        expect(valueMap['stringLabel'], isNotNull);
      });
    });

    group('CKSamplesValueMapping', () {
      test('maps samples value to request format', () {
        final samples = [
          CKSample(60.0, Duration.zero),
          CKSample(80.0, const Duration(minutes: 1)),
          CKSample(100.0, const Duration(minutes: 2)),
        ];

        final samplesValue =
            CKSamplesValue(samples, CKUnit.compound.beatsPerMin);

        final result = samplesValue.mapToRequest();

        expect(result['valuePattern'], equals('samples'));
        expect(result['unit'], equals('bpm'));

        final valueList = result['value'] as List<dynamic>;
        expect(valueList, hasLength(3));

        final sample0 = valueList[0] as Map<String, dynamic>;
        expect(sample0['value'], equals(60.0));
        expect(sample0['time'], equals(0));

        final sample1 = valueList[1] as Map<String, dynamic>;
        expect(sample1['value'], equals(80.0));
        expect(sample1['time'], equals(60000)); // 1 minute in milliseconds

        final sample2 = valueList[2] as Map<String, dynamic>;
        expect(sample2['value'], equals(100.0));
        expect(sample2['time'], equals(120000)); // 2 minutes in milliseconds
      });

      test('maps samples value with null unit to request format', () {
        final samples = [CKSample(72.0, Duration.zero)];
        final samplesValue = CKSamplesValue(samples, CKUnit.scalar.count);

        final result = samplesValue.mapToRequest();

        expect(result['valuePattern'], equals('samples'));
        expect(result['unit'], equals('count'));

        final valueList = result['value'] as List<dynamic>;
        expect(valueList, hasLength(1));
      });

      test('maps empty samples value to request format', () {
        final samplesValue = CKSamplesValue([], CKUnit.scalar.count);

        final result = samplesValue.mapToRequest();

        expect(result['valuePattern'], equals('samples'));
        expect(result['unit'], equals('count'));

        final valueList = result['value'] as List<dynamic>;
        expect(valueList, isEmpty);
      });

      test('maps samples value to request format with millisecond precision',
          () {
        final samples = [
          CKSample(72.0, Duration.zero),
          CKSample(80.0, const Duration(minutes: 1)),
          CKSample(100.0, const Duration(minutes: 2)),
          CKSample(120.0, const Duration(minutes: 3)),
        ];

        final samplesValue =
            CKSamplesValue(samples, CKUnit.compound.beatsPerMin);

        final result = samplesValue.mapToRequest();

        expect(result['valuePattern'], equals('samples'));
        expect(result['unit'], equals('bpm'));

        final valueList = result['value'] as List<dynamic>;
        expect(valueList, hasLength(4));

        expect(valueList[0]['time'], equals(0)); // milliseconds
        expect(valueList[1]['time'], equals(60000)); // 1 minute = 60000ms
        expect(valueList[2]['time'], equals(120000)); // 2 minutes = 120000ms
        expect(valueList[3]['time'], equals(180000)); // 3 minutes = 180000ms
      });

      test('handles different units and sample sizes', () {
        final singleSample = [CKSample(72.0, Duration.zero)];
        final fewSamples = [
          CKSample(60.0, Duration.zero),
          CKSample(80.0, const Duration(seconds: 30)),
        ];
        final manySamples = List.generate(
            100,
            (index) => CKSample(
                60.0 + index.toDouble(), Duration(milliseconds: index * 100)));

        final singleResult =
            CKSamplesValue(singleSample, CKUnit.compound.beatsPerMin)
                .mapToRequest();
        final fewResult =
            CKSamplesValue(fewSamples, CKUnit.length.meter).mapToRequest();
        final manyResult =
            CKSamplesValue(manySamples, CKUnit.scalar.count).mapToRequest();

        expect(singleResult['valuePattern'], equals('samples'));
        expect(singleResult['unit'], equals('bpm'));

        final singleValueList = singleResult['value'] as List<dynamic>;
        expect(singleValueList, hasLength(1));

        expect(fewResult['unit'], equals('m'));
        final fewValueList = fewResult['value'] as List<dynamic>;
        expect(fewValueList, hasLength(2));

        expect(manyResult['unit'], equals('count'));
        final manyValueList = manyResult['value'] as List<dynamic>;
        expect(manyValueList, hasLength(100));
      });

      test('handles samples with varying times', () {
        final samples = [
          CKSample(60.0, Duration.zero),
          CKSample(75.0, const Duration(milliseconds: 100)),
          CKSample(90.0, const Duration(seconds: 1)),
          CKSample(105.0, const Duration(minutes: 1)),
        ];

        final result =
            CKSamplesValue(samples, CKUnit.compound.beatsPerMin).mapToRequest();

        final valueList = result['value'] as List<dynamic>;

        expect(valueList[0]['time'], equals(0));
        expect(valueList[1]['time'], equals(100));
        expect(valueList[2]['time'], equals(1000)); // 1 second = 1000ms
        expect(valueList[3]['time'], equals(60000)); // 1 minute = 60000ms
      });

      test('handles samples with different value types', () {
        final samples = [
          CKSample(0.0, Duration.zero),
          CKSample(-50.5, const Duration(seconds: 1)),
          CKSample(999.999, const Duration(minutes: 1)),
        ];

        final result =
            CKSamplesValue(samples, CKUnit.energy.kilocalorie).mapToRequest();

        final valueList = result['value'] as List<dynamic>;

        expect(valueList[0]['value'], equals(0.0));
        expect(valueList[1]['value'], equals(-50.5));
        expect(valueList[2]['value'], closeTo(999.999, 0.001));
        expect(result['unit'], equals('kcal'));
      });
    });
  });

  group('CKSourceMapping extension', () {
    test('maps source with app record UUID to request format', () {
      final source = CKSource(
        recordingMethod: CKRecordingMethod.automaticallyRecorded,
        appRecordUUID: 'app-uuid-12345',
      );

      final result = source.mapToRequest();

      expect(result['recordingMethod'], equals('automaticallyRecorded'));
      expect(result['appRecordUUID'], equals('app-uuid-12345'));
      expect(result['device'], isNull);
      expect(result['sdkRecordId'], isNull);
      expect(result['sdkRecordVersion'], isNull);
    });

    test('maps source with SDK record information to request format', () {
      final source = CKSource(
        recordingMethod: CKRecordingMethod.automaticallyRecorded,
        sdkRecordId: 'sdk-record-67890',
        sdkRecordVersion: 1,
      );

      final result = source.mapToRequest();

      expect(result['recordingMethod'], equals('automaticallyRecorded'));
      expect(result['appRecordUUID'], isNull);
      expect(result['device'], isNull);
      expect(result['sdkRecordId'], equals('sdk-record-67890'));
      expect(result['sdkRecordVersion'], equals(1));
    });

    test('maps source with all optional fields to request format', () {
      final device = CKDevice(
        manufacturer: 'Apple',
        model: 'Watch Series 8',
        type: CKDeviceType.watch,
        hardwareVersion: '2.0',
        softwareVersion: '9.0',
      );

      final source = CKSource(
        recordingMethod: CKRecordingMethod.automaticallyRecorded,
        device: device,
        appRecordUUID: 'app-uuid-12345',
        sdkRecordId: 'sdk-record-67890',
        sdkRecordVersion: 1,
      );

      final result = source.mapToRequest();

      expect(result['recordingMethod'], equals('automaticallyRecorded'));
      expect(result['device'], isNotNull);
      expect(result['appRecordUUID'], equals('app-uuid-12345'));
      expect(result['sdkRecordId'], equals('sdk-record-67890'));
      expect(result['sdkRecordVersion'], equals(1));
    });

    test('maps source with null optional fields to request format', () {
      final source = CKSource(
        recordingMethod: CKRecordingMethod.manualEntry,
        // All optional fields are null by default
      );

      final result = source.mapToRequest();

      expect(result['recordingMethod'], equals('manualEntry'));
      expect(result['device'], isNull);
      expect(result['appRecordUUID'], isNull);
      expect(result['sdkRecordId'], isNull);
      expect(result['sdkRecordVersion'], isNull);
    });
  });

  group('CKValueMapping switch statement', () {
    test('dispatches CKLabelValue to specific mapping', () {
      final labelValue = CKLabelValue('test');
      final result = (labelValue as CKValue).mapToRequest();

      expect(result['valuePattern'], equals('label'));
      expect(result['value'], equals('test'));
    });

    test('dispatches CKQuantityValue to specific mapping', () {
      final quantityValue = CKQuantityValue(100, CKUnit.scalar.count);
      final result = (quantityValue as CKValue).mapToRequest();

      expect(result['valuePattern'], equals('quantity'));
      expect(result['value'], equals(100.0));
      expect(result['unit'], equals('count'));
    });

    test('dispatches CKCategoryValue to specific mapping', () {
      final categoryValue = CKCategoryValue(CKBiologicalSexType.female);
      final result = (categoryValue as CKValue).mapToRequest();

      expect(result['valuePattern'], equals('category'));
      expect(result['value'], equals('female'));
      expect(result['categoryName'], equals('CKBiologicalSexType'));
    });

    test('dispatches CKMultipleValue to specific mapping', () {
      final Map<String, CKValue<Object>> valueMap = {
        'key1': CKLabelValue('value1'),
        'key2': CKQuantityValue(50, CKUnit.scalar.count),
      };
      final multipleValue = CKMultipleValue(valueMap);
      final result = (multipleValue as CKValue).mapToRequest();

      expect(result['valuePattern'], equals('multiple'));
      expect(result['value'], isNotNull);
      expect(result['unit'], isNull);
    });

    test('dispatches CKSamplesValue to specific mapping', () {
      final samples = [CKSample(75.0, Duration.zero)];
      final samplesValue = CKSamplesValue(samples, CKUnit.compound.beatsPerMin);
      final result = (samplesValue as CKValue).mapToRequest();

      expect(result['valuePattern'], equals('samples'));
      expect(result['value'], isA<List>());
      expect(result['unit'], equals('bpm'));
    });
  });

  group('CKDataRecordMapping extension', () {
    test('maps CKDataRecord with all fields to request format', () {
      final dataRecord = CKDataRecord(
        type: CKType.steps,
        data: CKQuantityValue(1000, CKUnit.scalar.count),
        startTime: DateTime(2024, 1, 15, 12, 0),
        endTime: DateTime(2024, 1, 15, 13, 0),
        startZoneOffset: const Duration(hours: -5),
        endZoneOffset: const Duration(hours: -4), // DST change
        source: CKSource.manualEntry(),
        metadata: {'test': 'value'},
        id: 'record-123',
      );

      final result = dataRecord.mapToRequest();

      expect(result['id'], equals('record-123'));
      expect(result['recordKind'], equals('data'));
      expect(result['type'], equals('steps'));
      expect(result['startTime'], equals(1705338000000));
      expect(result['endTime'], equals(1705341600000));
      expect(result['startZoneOffsetSeconds'], equals(-18000)); // -5 hours
      expect(result['endZoneOffsetSeconds'], equals(-14400)); // -4 hours
      expect(result['source'], isNotNull);
      expect(result['metadata'], equals({'test': 'value'}));
    });

    test('maps CKDataRecord with minimal fields to request format', () {
      final dataRecord = CKDataRecord(
        type: CKType.height,
        data: CKQuantityValue(1.75, CKUnit.length.meter),
        startTime: DateTime(2024, 1, 15, 12, 0),
        endTime: DateTime(2024, 1, 15, 12, 0), // instantaneous
      );

      final result = dataRecord.mapToRequest();

      expect(result['id'], isNull);
      expect(result['recordKind'], equals('data'));
      expect(result['type'], equals('height'));
      expect(result['startTime'], isNotNull);
      expect(result['endTime'], isNotNull);
      expect(result['startZoneOffsetSeconds'], isNotNull);
      expect(result['endZoneOffsetSeconds'], isNotNull);
      expect(result['source'], isNull);
      expect(result['metadata'], isNull);
    });
  });

  group('CKRecordMapping default case', () {
    test('handles unknown record type with default mapping', () {
      // Use a simple type that doesn't have specific mapping
      final record = CKDataRecord(
        type: CKType.steps, // This has quantity pattern, not specific mapping
        data: CKQuantityValue(37.0, CKUnit.temperature.celsius),
        startTime: DateTime(2024, 1, 15, 12, 0),
        endTime: DateTime(2024, 1, 15, 12, 30),
        source: CKSource.manualEntry(),
        metadata: {'device': 'thermometer'},
        id: 'unknown-record-456',
      );

      final result = record.mapToRequest();

      // Should use default mapping in CKRecordMapping
      expect(result['id'], equals('unknown-record-456'));
      expect(result['startTime'], isNotNull);
      expect(result['endTime'], isNotNull);
      expect(result['startZoneOffsetSeconds'], isNotNull);
      expect(result['endZoneOffsetSeconds'], isNotNull);
      expect(result['source'], isNotNull);
      expect(result['metadata'], equals({'device': 'thermometer'}));

      // Should have recordKind because CKDataRecord uses CKDataRecordMapping extension
      expect(result['recordKind'], equals('data'));
    });

    test('handles unknown record type without optional fields', () {
      final record = CKDataRecord(
        type: CKType.heartRate,
        data: CKQuantityValue(16, CKUnit.compound.beatsPerMin),
        startTime: DateTime(2024, 1, 15, 12, 0),
        endTime: DateTime(2024, 1, 15, 12, 15),
      );

      final result = record.mapToRequest();

      expect(result['id'], isNull);
      expect(result['startTime'], isNotNull);
      expect(result['endTime'], isNotNull);
      expect(result['startZoneOffsetSeconds'], isNotNull);
      expect(result['endZoneOffsetSeconds'], isNotNull);
      expect(result['source'], isNull);
      expect(result['metadata'], isNull);
    });
  });

  group('CKNutritionMapping complete nutrient coverage', () {
    test('maps nutrition record with all available nutrients', () {
      final nutrition = CKNutrition(
        name: 'Complete Meal',
        mealType: CKMealType.dinner,

        // Basic nutrients
        energy: CKQuantityValue(600, CKUnit.energy.kilocalorie),
        protein: CKQuantityValue(30, CKUnit.scalar.count),
        totalCarbohydrate: CKQuantityValue(80, CKUnit.scalar.count),
        totalFat: CKQuantityValue(25, CKUnit.scalar.count),
        dietaryFiber: CKQuantityValue(10, CKUnit.scalar.count),
        sugar: CKQuantityValue(15, CKUnit.scalar.count),

        // Fat types
        saturatedFat: CKQuantityValue(8, CKUnit.scalar.count),
        unsaturatedFat: CKQuantityValue(12, CKUnit.scalar.count),
        monounsaturatedFat: CKQuantityValue(6, CKUnit.scalar.count),
        polyunsaturatedFat: CKQuantityValue(4, CKUnit.scalar.count),
        transFat: CKQuantityValue(2, CKUnit.scalar.count),

        // Other nutrients
        cholesterol: CKQuantityValue(15, CKUnit.scalar.count),
        calcium: CKQuantityValue(300, CKUnit.scalar.count),
        chloride: CKQuantityValue(100, CKUnit.scalar.count),
        chromium: CKQuantityValue(50, CKUnit.scalar.count),
        copper: CKQuantityValue(1, CKUnit.scalar.count),
        iodine: CKQuantityValue(150, CKUnit.scalar.count),
        iron: CKQuantityValue(8, CKUnit.scalar.count),
        magnesium: CKQuantityValue(100, CKUnit.scalar.count),
        manganese: CKQuantityValue(2, CKUnit.scalar.count),
        molybdenum: CKQuantityValue(0.1, CKUnit.scalar.count),
        phosphorus: CKQuantityValue(500, CKUnit.scalar.count),
        potassium: CKQuantityValue(400, CKUnit.scalar.count),
        selenium: CKQuantityValue(55, CKUnit.scalar.count),
        sodium: CKQuantityValue(700, CKUnit.scalar.count),
        zinc: CKQuantityValue(10, CKUnit.scalar.count),

        // Vitamins
        vitaminA: CKQuantityValue(900, CKUnit.scalar.count),
        vitaminB6: CKQuantityValue(1.5, CKUnit.scalar.count),
        vitaminB12: CKQuantityValue(2.4, CKUnit.scalar.count),
        vitaminC: CKQuantityValue(80, CKUnit.scalar.count),
        vitaminD: CKQuantityValue(20, CKUnit.scalar.count),
        vitaminE: CKQuantityValue(15, CKUnit.scalar.count),
        vitaminK: CKQuantityValue(120, CKUnit.scalar.count),
        thiamin: CKQuantityValue(1.2, CKUnit.scalar.count),
        riboflavin: CKQuantityValue(1.3, CKUnit.scalar.count),
        niacin: CKQuantityValue(16, CKUnit.scalar.count),
        folate: CKQuantityValue(400, CKUnit.scalar.count),
        biotin: CKQuantityValue(30, CKUnit.scalar.count),
        pantothenicAcid: CKQuantityValue(5, CKUnit.scalar.count),

        startTime: DateTime(2024, 1, 15, 19, 0),
        endTime: DateTime(2024, 1, 15, 20, 0),
        startZoneOffset: Duration.zero,
        endZoneOffset: Duration.zero,
        source: CKSource.manualEntry(),
      );

      final result = nutrition.mapToRequest();
      final nutrients = result['nutrients'] as Map<String, dynamic>;

      // Test that all nutrients are included
      expect(nutrients['energy'], isNotNull);
      expect(nutrients['protein'], isNotNull);
      expect(nutrients['totalCarbohydrate'], isNotNull);
      expect(nutrients['totalFat'], isNotNull);
      expect(nutrients['dietaryFiber'], isNotNull);
      expect(nutrients['sugar'], isNotNull);
      expect(nutrients['saturatedFat'], isNotNull);
      expect(nutrients['unsaturatedFat'], isNotNull);
      expect(nutrients['monounsaturatedFat'], isNotNull);
      expect(nutrients['polyunsaturatedFat'], isNotNull);
      expect(nutrients['transFat'], isNotNull);
      expect(nutrients['cholesterol'], isNotNull);
      expect(nutrients['calcium'], isNotNull);
      expect(nutrients['chloride'], isNotNull);
      expect(nutrients['chromium'], isNotNull);
      expect(nutrients['copper'], isNotNull);
      expect(nutrients['iodine'], isNotNull);
      expect(nutrients['iron'], isNotNull);
      expect(nutrients['magnesium'], isNotNull);
      expect(nutrients['manganese'], isNotNull);
      expect(nutrients['molybdenum'], isNotNull);
      expect(nutrients['phosphorus'], isNotNull);
      expect(nutrients['potassium'], isNotNull);
      expect(nutrients['selenium'], isNotNull);
      expect(nutrients['sodium'], isNotNull);
      expect(nutrients['zinc'], isNotNull);
      expect(nutrients['vitaminA'], isNotNull);
      expect(nutrients['vitaminB6'], isNotNull);
      expect(nutrients['vitaminB12'], isNotNull);
      expect(nutrients['vitaminC'], isNotNull);
      expect(nutrients['vitaminD'], isNotNull);
      expect(nutrients['vitaminE'], isNotNull);
      expect(nutrients['vitaminK'], isNotNull);
      expect(nutrients['thiamin'], isNotNull);
      expect(nutrients['riboflavin'], isNotNull);
      expect(nutrients['niacin'], isNotNull);
      expect(nutrients['folate'], isNotNull);
      expect(nutrients['biotin'], isNotNull);
      expect(nutrients['pantothenicAcid'], isNotNull);

      // Verify nutrient values
      expect(nutrients['energy']['value'], equals(600.0));
      expect(nutrients['protein']['value'], equals(30.0));
      expect(nutrients['sodium']['value'], equals(700.0));
      expect(nutrients['vitaminC']['value'], equals(80.0));
    });

    test('maps nutrition record with sparse nutrients to request format', () {
      final nutrition = CKNutrition(
        name: 'Sparse Meal',
        energy: CKQuantityValue(300, CKUnit.energy.kilocalorie),
        vitaminC: CKQuantityValue(100, CKUnit.scalar.count),
        iron: CKQuantityValue(5, CKUnit.scalar.count),

        startTime: DateTime(2024, 1, 15, 12, 30),
        endTime: DateTime(2024, 1, 15, 13, 30),
        startZoneOffset: Duration.zero,
        endZoneOffset: Duration.zero,
        source: CKSource.manualEntry(),
      );

      final result = nutrition.mapToRequest();
      final nutrients = result['nutrients'] as Map<String, dynamic>;

      // Should only include the specified nutrients
      expect(nutrients.length, 3);
      expect(nutrients['energy'], isNotNull);
      expect(nutrients['vitaminC'], isNotNull);
      expect(nutrients['iron'], isNotNull);

      // Should not include unspecified nutrients
      expect(nutrients['protein'], isNull);
      expect(nutrients['sodium'], isNull);
      expect(nutrients['vitaminD'], isNull);
    });
  });

  group('CKSampleMapping extension', () {
    test('maps sample to request format', () {
      final sample = CKSample(75.5, const Duration(minutes: 5, seconds: 30));

      final result = sample.mapToRequest();

      expect(result['value'], equals(75.5));
      expect(result['time'], equals(330000)); // 5:30 in milliseconds
    });

    test('maps zero duration sample to request format', () {
      final sample = CKSample(100.0, Duration.zero);

      final result = sample.mapToRequest();

      expect(result['value'], equals(100.0));
      expect(result['time'], equals(0));
    });

    test('maps negative sample to request format', () {
      final sample = CKSample(-50.0, const Duration(hours: 1));

      final result = sample.mapToRequest();

      expect(result['value'], equals(-50.0));
      expect(result['time'], equals(3600000)); // 1 hour in milliseconds
    });

    test('maps single sample to request format', () {
      final sample = CKSample(75.5, const Duration(minutes: 5, seconds: 30));

      final result = sample.mapToRequest();

      expect(result['value'], equals(75.5));
      expect(result['time'], equals(330000)); // 5:30 in milliseconds
    });

    test('maps negative sample to request format', () {
      final sample = CKSample(-50.0, const Duration(hours: 1));

      final result = sample.mapToRequest();

      expect(result['value'], equals(-50.0));
      expect(result['time'], equals(3600000)); // 1 hour in milliseconds
    });

    test('maps zero duration sample to request format', () {
      final sample = CKSample(100.0, Duration.zero);

      final result = sample.mapToRequest();

      expect(result['value'], equals(100.0));
      expect(result['time'], equals(0)); // 0 milliseconds
    });

    test('maps sample with large time values', () {
      final sample = CKSample(99999999.99, const Duration(days: 30));

      final result = sample.mapToRequest();

      expect(
          result['value'], equals(99999999.99)); // Should be properly truncated
      expect(result['time'], equals(2592000000)); // 30 days in milliseconds
    });

    test('handles various time durations', () {
      final zeroSample = CKSample(100.0, Duration.zero);
      final millisecondSample =
          CKSample(200.0, const Duration(milliseconds: 500));
      final secondSample = CKSample(300.0, const Duration(seconds: 30));
      final minuteSample = CKSample(400.0, const Duration(minutes: 5));
      final hourSample = CKSample(500.0, const Duration(hours: 2));
      final daySample = CKSample(600.0, const Duration(days: 1));

      final zeroResult = zeroSample.mapToRequest();
      final millisecondResult = millisecondSample.mapToRequest();
      final secondResult = secondSample.mapToRequest();
      final minuteResult = minuteSample.mapToRequest();
      final hourResult = hourSample.mapToRequest();
      final dayResult = daySample.mapToRequest();

      expect(zeroResult['time'], equals(0));
      expect(millisecondResult['time'], equals(500));
      expect(secondResult['time'], equals(30000)); // 30 seconds = 30000ms
      expect(minuteResult['time'], equals(300000)); // 5 minutes = 300000ms
      expect(hourResult['time'], equals(7200000)); // 2 hours = 7200000ms
      expect(dayResult['time'], equals(86400000)); // 1 day = 86400000ms
    });

    test('handles extreme values', () {
      final veryLargeSample =
          CKSample(999999999.999, const Duration(days: 365));
      final verySmallSample =
          CKSample(-999999999.999, const Duration(milliseconds: 1));

      final largeResult = veryLargeSample.mapToRequest();
      final smallResult = verySmallSample.mapToRequest();

      expect(largeResult['value'], closeTo(999999999.999, 0.001));
      expect(largeResult['time'], equals(31536000000)); // 365 days in ms

      expect(smallResult['value'], closeTo(-999999999.999, 0.001));
      expect(smallResult['time'], equals(1));
    });

    test('handles zero and integer values', () {
      final zeroSample = CKSample(0.0, Duration.zero);
      final integerSample = CKSample(42, const Duration(seconds: 1));
      final negativeSample = CKSample(-100, const Duration(minutes: 1));

      final zeroResult = zeroSample.mapToRequest();
      final integerResult = integerSample.mapToRequest();
      final negativeResult = negativeSample.mapToRequest();

      expect(zeroResult['value'], equals(0.0));
      expect(integerResult['value'], equals(42.0));
      expect(negativeResult['value'], equals(-100.0));
    });
  });

  group('CKRecordMapping extension', () {
    test('maps CKDataRecord to request format', () {
      final dataRecord = CKDataRecord.instantaneous(
        type: CKType.steps,
        data: CKQuantityValue(1000, CKUnit.scalar.count),
        time: DateTime(2024, 1, 15, 12, 0),
        source: CKSource.manualEntry(),
      );

      final result = dataRecord.mapToRequest();
      final data = result['data'] as Map<String, dynamic>;

      expect(result['type'], equals('steps'));
      expect(data['valuePattern'], equals('quantity'));
      expect(data['value'], equals(1000.0));
      expect(data['unit'], equals('count'));
      expect(result['startTime'], 1705338000000);
      expect(result['endTime'], equals(result['startTime']));
      expect(result['source'], isNotNull);
    });

    test('handles unknown record type', () {
      final record = CKDataRecord.instantaneous(
        type: CKType.height, // Use a simple type
        data: CKQuantityValue(1.75, CKUnit.length.meter),
        time: DateTime.now(), // Use UTC to avoid validation error
        source: CKSource.manualEntry(),
      );

      final result = record.mapToRequest();
      final data = result['data'] as Map<String, dynamic>;

      expect(result['type'], equals('height'));
      expect(data['valuePattern'], equals('quantity'));
      expect(result['startTime'], isNotNull);
      expect(result['endTime'], isNotNull);
      expect(result['startTime'], equals(result['endTime']));
      expect(result['source'], isNotNull);
    });

    test('maps CKDataRecord with complex nested value to request format', () {
      final Map<String, CKValue<Object>> data = {
        'level':
            CKQuantityValue(10000, CKUnit.bloodGlucose.milligramsPerDeciliter),
        'specimenSource': CKCategoryValue(CKSpecimenSource.plasma),
        'mealType': CKCategoryValue(CKMealType.breakfast),
        'relationToMeal': CKCategoryValue(CKRelationToMeal.beforeMeal),
        'mealTime': CKLabelValue(DateTime(2024, 1, 15, 12, 0).toString()),
      };

      final dataRecord = CKDataRecord.interval(
        type: CKType.bloodGlucose,
        startTime: DateTime(2024, 1, 15, 12, 0),
        endTime: DateTime(2024, 1, 15, 13, 0),
        source: CKSource.manualEntry(),
        data: CKMultipleValue(data),
        metadata: {
          'mainProperty': 'level',
        },
      );

      final result = dataRecord.mapToRequest();

      expect(result['type'], equals('bloodGlucose'));
      expect(result['startTime'], isNotNull);
      expect(result['endTime'], isNotNull);
      expect(result['source'], isNotNull);
      expect(result['data'], isNotNull);
    });

    test('switch statement correctly dispatches to specific record types', () {
      final records = [
        CKAudiogram(
          time: DateTime.now(),
          zoneOffset: Duration.zero,
          sensitivityPoints: [],
        ),
        CKBloodPressure(
          systolic: CKQuantityValue(120, CKUnit.pressure.millimetersOfMercury),
          diastolic: CKQuantityValue(80, CKUnit.pressure.millimetersOfMercury),
          time: DateTime.now(),
          zoneOffset: Duration.zero,
        ),
      ];

      for (final record in records) {
        final result = record.mapToRequest();
        expect(result, isA<Map<String, Object?>>());
        expect(result['time'], isNotNull);
        expect(result['zoneOffsetSeconds'], isNotNull);
      }
    });
  });

  group('CKDataRecordMapping extension', () {});

  group('Polymorphic mapToRequest dispatch', () {
    late DateTime testTime;
    late CKSource testSource;

    setUp(() {
      testTime = DateTime.now();
      testSource = CKSource.manualEntry();
    });

    test('dispatches CKEcg.mapToRequest when called via CKRecord interface', () {
      final records = <CKRecord>[];
      final endTime = testTime.add(const Duration(seconds: 10));

      final ecg = CKEcg(
        classification: CKEcgClassification.sinusRhythm,
        averageHeartRate: 72,
        startTime: testTime,
        endTime: endTime,
        startZoneOffset: Duration.zero,
        endZoneOffset: Duration.zero,
        source: testSource,
      );

      records.add(ecg);
      final result = records[0].mapToRequest();

      expect(result['recordKind'], equals('ecg'));
      expect(result['classification'], equals('sinusRhythm'));
      expect(result['averageHeartRate'], equals(72));
    });

    test('dispatches CKDataRecord.mapToRequest when called via CKRecord interface', () {
      final records = <CKRecord>[];

      final dataRecord = CKDataRecord.instantaneous(
        type: CKType.steps,
        data: CKQuantityValue(1000, CKUnit.scalar.count),
        time: testTime,
        source: testSource,
      );

      records.add(dataRecord);
      final result = records[0].mapToRequest();

      expect(result['recordKind'], equals('data'));
      expect(result['type'], equals('steps'));
      expect(result['data'], isNotNull);
    });

    test('dispatches CKWorkout.mapToRequest when called via CKRecord interface', () {
      final records = <CKRecord>[];
      final endTime = testTime.add(const Duration(hours: 1));

      final workout = CKWorkout(
        activityType: CKWorkoutActivityType.running,
        title: 'Morning Run',
        startTime: testTime,
        endTime: endTime,
        startZoneOffset: Duration.zero,
        endZoneOffset: Duration.zero,
        source: testSource,
      );

      records.add(workout);
      final result = records[0].mapToRequest();

      expect(result['recordKind'], equals('workout'));
      expect(result['activityType'], equals('running'));
      expect(result['title'], equals('Morning Run'));
    });

    test('dispatches CKSleepSession.mapToRequest when called via CKRecord interface', () {
      final records = <CKRecord>[];
      final endTime = testTime.add(const Duration(hours: 8));

      final sleepSession = CKSleepSession(
        title: 'Night Sleep',
        stages: [],
        startTime: testTime,
        endTime: endTime,
        startZoneOffset: Duration.zero,
        endZoneOffset: Duration.zero,
        source: testSource,
      );

      records.add(sleepSession);
      final result = records[0].mapToRequest();

      expect(result['recordKind'], equals('sleepSession'));
      expect(result['title'], equals('Night Sleep'));
    });

    test('dispatches CKNutrition.mapToRequest when called via CKRecord interface', () {
      final records = <CKRecord>[];
      final endTime = testTime.add(const Duration(hours: 1));

      final nutrition = CKNutrition(
        name: 'Breakfast',
        mealType: CKMealType.breakfast,
        energy: CKQuantityValue(450, CKUnit.energy.kilocalorie),
        startTime: testTime,
        endTime: endTime,
        startZoneOffset: Duration.zero,
        endZoneOffset: Duration.zero,
        source: testSource,
      );

      records.add(nutrition);
      final result = records[0].mapToRequest();

      expect(result['recordKind'], equals('nutrition'));
      expect(result['name'], equals('Breakfast'));
      expect(result['mealType'], equals('breakfast'));
    });

    test('dispatches CKBloodPressure.mapToRequest when called via CKRecord interface', () {
      final records = <CKRecord>[];

      final bloodPressure = CKBloodPressure(
        systolic: CKQuantityValue(120, CKUnit.pressure.millimetersOfMercury),
        diastolic: CKQuantityValue(80, CKUnit.pressure.millimetersOfMercury),
        time: testTime,
        zoneOffset: Duration.zero,
        source: testSource,
      );

      records.add(bloodPressure);
      final result = records[0].mapToRequest();

      expect(result['recordKind'], equals('bloodPressure'));
      expect(result['systolic'], isNotNull);
      expect(result['diastolic'], isNotNull);
    });

    test('dispatches CKAudiogram.mapToRequest when called via CKRecord interface', () {
      final records = <CKRecord>[];

      final audiogram = CKAudiogram(
        time: testTime,
        zoneOffset: Duration.zero,
        sensitivityPoints: [],
        source: testSource,
      );

      records.add(audiogram);
      final result = records[0].mapToRequest();

      expect(result['recordKind'], equals('audiogram'));
      expect(result['time'], equals(testTime.millisecondsSinceEpoch));
      expect(result['zoneOffsetSeconds'], equals(0));
    });

    test('dispatches base CKRecord.mapToRequest when called via CKRecord interface', () {
      final records = <CKRecord>[];

      // Use CKDataRecord as it extends CKRecord and uses the default mapping
      final baseRecord = CKDataRecord(
        type: CKType.steps,
        data: CKQuantityValue(100, CKUnit.scalar.count),
        startTime: testTime,
        endTime: testTime.add(const Duration(minutes: 30)),
        source: testSource,
      );

      records.add(baseRecord);
      final result = records[0].mapToRequest();

      // Should use default mapping for base CKRecord
      expect(result['startTime'], isNotNull);
      expect(result['endTime'], isNotNull);
      expect(result['source'], isNotNull);
      expect(result['type'], equals('steps'));
    });

    test('dispatches regular CKRecord mapToRequest default case', () {
      final records = <CKRecord>[];

      // Create a custom record class that extends CKRecord but doesn't have specific mapping
      final customRecord = _CustomTestRecord(
        startTime: testTime,
        endTime: testTime.add(const Duration(hours: 1)),
        source: testSource,
        id: 'custom-record-123',
        metadata: {'customField': 'customValue'},
      );

      records.add(customRecord);
      final result = records[0].mapToRequest();

      // Should use default mapping in CKRecordMapping switch statement (lines 198-205)
      expect(result['id'], equals('custom-record-123'));
      expect(result['startTime'], equals(testTime.millisecondsSinceEpoch));
      expect(result['endTime'], equals(testTime.add(const Duration(hours: 1)).millisecondsSinceEpoch));
      expect(result['startZoneOffsetSeconds'], isNotNull);
      expect(result['endZoneOffsetSeconds'], isNotNull);
      expect(result['source'], isNotNull);
      expect(result['metadata'], equals({'customField': 'customValue'}));
    });

    test('regular CKRecord mapToRequest without optional fields', () {
      final records = <CKRecord>[];

      final minimalRecord = _CustomTestRecord(
        startTime: testTime,
        endTime: testTime.add(const Duration(minutes: 15)),
        // No id, source, or metadata
      );

      records.add(minimalRecord);
      final result = records[0].mapToRequest();

      // Should only include required fields
      expect(result['id'], isNull);
      expect(result['startTime'], isNotNull);
      expect(result['endTime'], isNotNull);
      expect(result['startZoneOffsetSeconds'], isNotNull);
      expect(result['endZoneOffsetSeconds'], isNotNull);
      expect(result['source'], isNull);
      expect(result['metadata'], isNull);
    });
  });

  group('Record-specific mapping extension', () {
    late DateTime testTime;
    late CKSource testSource;

    setUp(() {
      testTime = DateTime.now();
      testSource = CKSource.manualEntry();
    });

    group('CKAudiogramMapping', () {
      test('maps audiogram record to request format', () {
        final points = [
          CKAudiogramPoint(
            frequency: 1000,
            leftEarSensitivity: 20.5,
            rightEarSensitivity: 15.5,
          ),
          CKAudiogramPoint(
            frequency: 2000,
            leftEarSensitivity: 25.0,
          ),
        ];

        final audiogram = CKAudiogram(
          time: testTime,
          zoneOffset: Duration.zero,
          sensitivityPoints: points,
          source: testSource,
        );

        final result = audiogram.mapToRequest();

        expect(result['recordKind'], equals('audiogram'));
        expect(result['time'], equals(testTime.millisecondsSinceEpoch));
        expect(result['zoneOffsetSeconds'], equals(0));
        expect(result['sensitivityPoints'], isA<List>());

        final mappedPoints = result['sensitivityPoints'] as List;
        expect(mappedPoints, hasLength(2));

        final firstPoint = mappedPoints[0] as Map<String, dynamic>;
        expect(firstPoint['frequency'], equals(1000));
        expect(firstPoint['leftEarSensitivity'], equals(20.5));
        expect(firstPoint['rightEarSensitivity'], equals(15.5));
      });
    });

    group('CKAudiogramPointMapping', () {
      test('maps audiogram point with both ear sensitivities', () {
        final point = CKAudiogramPoint(
          frequency: 4000,
          leftEarSensitivity: 35.5,
          rightEarSensitivity: 30.0,
        );

        final result = point.mapToRequest();

        expect(result['frequency'], equals(4000));
        expect(result['leftEarSensitivity'], equals(35.5));
        expect(result['rightEarSensitivity'], equals(30.0));
      });

      test('maps audiogram point with only left ear sensitivity', () {
        final point = CKAudiogramPoint(
          frequency: 8000,
          leftEarSensitivity: 45.0,
        );

        final result = point.mapToRequest();

        expect(result['frequency'], equals(8000));
        expect(result['leftEarSensitivity'], equals(45.0));
        expect(result['rightEarSensitivity'], isNull);
      });

      test('maps audiogram point with no sensitivities', () {
        final point = CKAudiogramPoint(frequency: 125);

        final result = point.mapToRequest();

        expect(result['frequency'], equals(125));
        expect(result['leftEarSensitivity'], isNull);
        expect(result['rightEarSensitivity'], isNull);
      });
    });

    group('CKBloodPressureMapping', () {
      test('maps blood pressure record to request format', () {
        final systolic =
            CKQuantityValue(120, CKUnit.pressure.millimetersOfMercury);
        final diastolic =
            CKQuantityValue(80, CKUnit.pressure.millimetersOfMercury);

        final bloodPressure = CKBloodPressure(
          systolic: systolic,
          diastolic: diastolic,
          time: testTime,
          zoneOffset: Duration.zero,
          bodyPosition: CKBodyPosition.sittingDown,
          measurementLocation: CKMeasurementLocation.leftWrist,
          source: testSource,
        );

        final result = bloodPressure.mapToRequest();

        expect(result['recordKind'], equals('bloodPressure'));
        expect(result['time'], equals(testTime.millisecondsSinceEpoch));
        expect(result['zoneOffsetSeconds'], equals(0));
        expect(result['bodyPosition'], equals('sittingDown'));
        expect(result['measurementLocation'], equals('leftWrist'));

        final mappedSystolic = result['systolic'] as Map<String, dynamic>;
        expect(mappedSystolic['value'], equals(120.0));
        expect(mappedSystolic['unit'], equals('mmHg'));

        final mappedDiastolic = result['diastolic'] as Map<String, dynamic>;
        expect(mappedDiastolic['value'], equals(80.0));
        expect(mappedDiastolic['unit'], equals('mmHg'));
      });
    });

    group('CKEcgMapping', () {
      test('maps ECG record to request format', () {
        final endTime = testTime.add(const Duration(seconds: 10));
        final voltageMeasurements = [
          CKEcgVoltageMeasurement(
            timeSinceStart: Duration.zero.inSeconds.toDouble(),
            microvolts: 1000,
          ),
          CKEcgVoltageMeasurement(
            timeSinceStart:
                const Duration(milliseconds: 500).inSeconds.toDouble(),
            microvolts: 1200,
          ),
        ];

        final ecg = CKEcg(
          classification: CKEcgClassification.sinusRhythm,
          averageHeartRate: 72,
          startTime: testTime,
          endTime: endTime,
          startZoneOffset: Duration.zero,
          endZoneOffset: Duration.zero,
          symptoms: [
            CKEcgSymptom.chestPainOrDiscomfort,
            CKEcgSymptom.shortnessOfBreath
          ],
          voltageMeasurements: voltageMeasurements,
          source: testSource,
        );

        final result = ecg.mapToRequest();

        expect(result['recordKind'], equals('ecg'));
        expect(result['classification'], equals('sinusRhythm'));
        expect(result['averageHeartRate'], equals(72));
        expect(result['startTime'], equals(testTime.millisecondsSinceEpoch));
        expect(result['endTime'], equals(endTime.millisecondsSinceEpoch));

        final symptomsList = result['symptoms'] as List;
        expect(symptomsList, contains('chestPainOrDiscomfort'));
        expect(symptomsList, contains('shortnessOfBreath'));

        final voltagesList = result['voltageMeasurements'] as List;
        expect(voltagesList, hasLength(2));

        final firstVoltage = voltagesList[0] as Map<String, dynamic>;
        expect(firstVoltage['timeSinceStart'], equals(0));
        expect(firstVoltage['microvolts'], equals(1000));
      });
    });

    group('CKEcgVoltageMeasurementMapping', () {
      test('maps voltage measurement to request format', () {
        final measurement = CKEcgVoltageMeasurement(
          timeSinceStart: const Duration(seconds: 15).inSeconds.toDouble(),
          microvolts: 850.5,
        );

        final result = measurement.mapToRequest();

        expect(result['timeSinceStart'], equals(15.0));
        expect(result['microvolts'], equals(850.5));
      });

      test('maps voltage measurement with large time', () {
        final measurement = CKEcgVoltageMeasurement(
          timeSinceStart:
              const Duration(minutes: 2, seconds: 30).inSeconds.toDouble(),
          microvolts: 0,
        );

        final result = measurement.mapToRequest();

        expect(result['timeSinceStart'], equals(150.0));
        expect(result['microvolts'], equals(0));
      });
    });

    group('CKNutritionMapping', () {
      test('maps nutrition record with all nutrients', () {
        final nutrition = CKNutrition(
          name: 'Breakfast',
          mealType: CKMealType.breakfast,
          energy: CKQuantityValue(450, CKUnit.energy.kilocalorie),
          protein: CKQuantityValue(25, CKUnit.scalar.count),
          totalCarbohydrate: CKQuantityValue(60, CKUnit.scalar.count),
          totalFat: CKQuantityValue(15, CKUnit.scalar.count),
          cholesterol: CKQuantityValue(10, CKUnit.scalar.count),
          vitaminC: CKQuantityValue(50, CKUnit.scalar.count),
          calcium: CKQuantityValue(200, CKUnit.scalar.count),
          sodium: CKQuantityValue(800, CKUnit.scalar.count),
          startTime: testTime,
          endTime: testTime.add(const Duration(hours: 1)),
          startZoneOffset: Duration.zero,
          endZoneOffset: Duration.zero,
          source: testSource,
        );

        final result = nutrition.mapToRequest();

        expect(result['recordKind'], equals('nutrition'));
        expect(result['name'], equals('Breakfast'));
        expect(result['mealType'], equals('breakfast'));
        expect(result['nutrients'], isNotNull);

        final nutrients = result['nutrients'] as Map<String, dynamic>;
        expect(nutrients['energy']['value'], equals(450.0));
        expect(nutrients['protein']['value'], equals(25.0));
        expect(nutrients['sodium']['value'], equals(800.0));
        expect(nutrients['vitaminC']['value'], equals(50.0));
      });

      test('maps nutrition record with minimal data', () {
        final nutrition = CKNutrition(
          startTime: testTime,
          endTime: testTime.add(const Duration(minutes: 30)),
          startZoneOffset: Duration.zero,
          endZoneOffset: Duration.zero,
        );

        final result = nutrition.mapToRequest();

        expect(result['recordKind'], equals('nutrition'));
        expect(result['name'], isNull);
        expect(result['mealType'], isNull);
        expect(result['nutrients'], isNull);
      });
    });

    group('CKSleepSessionMapping', () {
      test('maps sleep session to request format', () {
        final endTime = testTime.add(const Duration(hours: 8));
        final stages = [
          CKSleepStage(
            stage: CKSleepStageType.awake,
            startTime: testTime,
            endTime: testTime.add(const Duration(minutes: 15)),
          ),
          CKSleepStage(
            stage: CKSleepStageType.light,
            startTime: testTime.add(const Duration(minutes: 15)),
            endTime: testTime.add(const Duration(hours: 2, minutes: 45)),
          ),
        ];

        final sleepSession = CKSleepSession(
          title: 'Night Sleep',
          notes: 'Good quality sleep',
          stages: stages,
          startTime: testTime,
          endTime: endTime,
          startZoneOffset: Duration.zero,
          endZoneOffset: Duration.zero,
          source: testSource,
        );

        final result = sleepSession.mapToRequest();

        expect(result['recordKind'], equals('sleepSession'));
        expect(result['title'], equals('Night Sleep'));
        expect(result['notes'], equals('Good quality sleep'));
        expect(result['startTime'], equals(testTime.millisecondsSinceEpoch));
        expect(result['endTime'], equals(endTime.millisecondsSinceEpoch));

        final stagesList = result['stages'] as List;
        expect(stagesList, hasLength(2));

        final firstStage = stagesList[0] as Map<String, dynamic>;
        expect(firstStage['stage'], equals('awake'));
        expect(
            firstStage['startTime'], equals(testTime.millisecondsSinceEpoch));
      });
    });

    group('CKSleepStageMapping', () {
      test('maps sleep stage to request format', () {
        final stage = CKSleepStage(
          stage: CKSleepStageType.deep,
          startTime: testTime,
          endTime: testTime.add(const Duration(hours: 2)),
        );

        final result = stage.mapToRequest();

        expect(result['stage'], equals('deep'));
        expect(result['startTime'], equals(testTime.millisecondsSinceEpoch));
        expect(
            result['endTime'],
            equals(
                testTime.add(const Duration(hours: 2)).millisecondsSinceEpoch));
      });
    });

    group('CKWorkoutMapping', () {
      test('maps workout record to request format', () {
        final endTime = testTime.add(const Duration(hours: 1));
        final duringSession = [
          CKDataRecord.instantaneous(
            type: CKType.heartRate,
            data: CKQuantityValue(150, CKUnit.compound.beatsPerMin),
            time: testTime.add(const Duration(minutes: 30)),
            source: testSource,
          ),
        ];

        final workout = CKWorkout(
          activityType: CKWorkoutActivityType.running,
          title: 'Morning Run',
          startTime: testTime,
          endTime: endTime,
          startZoneOffset: Duration.zero,
          endZoneOffset: Duration.zero,
          duringSession: duringSession,
          source: testSource,
        );

        final result = workout.mapToRequest();

        expect(result['recordKind'], equals('workout'));
        expect(result['activityType'], equals('running'));
        expect(result['title'], equals('Morning Run'));
        expect(result['startTime'], equals(testTime.millisecondsSinceEpoch));
        expect(result['endTime'], equals(endTime.millisecondsSinceEpoch));

        final duringSessionList = result['duringSession'] as List;
        expect(duringSessionList, hasLength(1));
      });

      test('maps workout with different activity types', () {
        final activities = [
          CKWorkoutActivityType.cycling,
          CKWorkoutActivityType.swimming,
          CKWorkoutActivityType.hiking,
          CKWorkoutActivityType.yoga,
          CKWorkoutActivityType.hiking,
        ];

        for (final activity in activities) {
          final workout = CKWorkout(
            activityType: activity,
            startTime: testTime,
            endTime: testTime.add(const Duration(minutes: 30)),
            startZoneOffset: Duration.zero,
            endZoneOffset: Duration.zero,
          );

          final result = workout.mapToRequest();
          expect(result['activityType'], equals(activity.name));
        }
      });
    });
  });
}
