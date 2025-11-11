import 'package:connect_kit/src/models/schema/ck_type.dart';
import 'package:connect_kit/src/models/schema/ck_device.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';
import 'package:connect_kit/src/models/schema/ck_value.dart';
import 'package:connect_kit/src/models/ck_access_type.dart';
import 'package:connect_kit/src/models/records/ck_record.dart';
import 'package:connect_kit/src/models/records/ck_audiogram.dart';
import 'package:connect_kit/src/models/records/ck_blood_pressure.dart';
import 'package:connect_kit/src/models/records/ck_ecg.dart';
import 'package:connect_kit/src/models/records/ck_nutrition.dart';
import 'package:connect_kit/src/models/records/ck_data_record.dart';
import 'package:connect_kit/src/models/records/ck_sleep_session.dart';
import 'package:connect_kit/src/models/records/ck_workout.dart';
import 'package:connect_kit/src/utils/ck_constants.dart';

/// Utility extensions for converting ConnectKit types to platform channel representations.
///
/// These extensions handle the conversion from Dart types to their string representations
/// that can be sent across the platform channel boundary to native iOS and Android code.
extension CKTypeMapping on Set<CKType> {
  /// Expands composite types to their default component types.
  ///
  /// This method handles the hierarchical CKType system by converting parent composite types
  /// (like `CKType.nutrition`, `CKType.bloodPressure`) into their constituent component types.
  ///
  /// **Use case**: This should be called before `mapToRequest()` when preparing types for
  /// permission requests to native platforms.
  Set<CKType> expandCompositeTypes() {
    final expanded = <CKType>{};

    for (final type in this) {
      // Try to get default components - this works for both composite and simple types
      final defaultComponents = type.defaultComponents;

      if (defaultComponents.isNotEmpty) {
        // This is a composite parent type (e.g., CKType.nutrition) - expand it
        expanded.addAll(defaultComponents);
      } else {
        // Simple type (CKType.height) or component type (CKType.nutrition.energy) - Keep as-is
        expanded.add(type);
      }
    }

    return expanded;
  }

  // TODO: use .name instead of .toString (for consistency)
  /// Maps Record to platform channel request format
  List<String> mapToRequest() {
    return map((type) => type.toString()).toList();
  }
}

/// Utility extensions for converting ConnectKit AccessStatus to platform channel representations.
///
/// These extensions handle the conversion from Dart types to their string representations
/// that can be sent across the platform channel boundary to native iOS and Android code.
extension DataAccessStatus on Map<CKType, Set<CKAccessType>> {
  /// Maps Record to platform channel request format
  ///
  /// Returns a Map where:
  /// - Keys: String representations of CKType objects (e.g., 'nutrition.energy')
  /// - Values: Lists of access type names (e.g., ['read', 'write'])
  Map<String, List<String>> mapToRequest() {
    final result = <String, List<String>>{};

    for (final entry in entries) {
      final typeSet = {entry.key};
      final expandedTypes = typeSet.expandCompositeTypes();
      final accessTypeStrings = entry.value.map((t) => t.name).toList();

      for (final expandedType in expandedTypes) {
        result[expandedType.toString()] = accessTypeStrings;
      }
    }

    return result;
  }
}

/// === Schema: Mapping ===

/// Extension for enhancing CKDevice to handle requests to native platforms
extension CKDeviceMapping on CKDevice {
  /// Maps Record to platform channel request format
  Map<String, Object?> mapToRequest() => {
        if (manufacturer != null) 'manufacturer': manufacturer as Object,
        if (model != null) 'model': model,
        'type': type.name,
        if (hardwareVersion != null) 'hardwareVersion': hardwareVersion,
        if (softwareVersion != null) 'softwareVersion': softwareVersion,
      };
}

/// Extension for enhancing CKSource to handle requests to native platforms
extension CKSourceMapping on CKSource {
  /// Maps Record to platform channel request format
  Map<String, Object?> mapToRequest() => {
        'recordingMethod': recordingMethod.name,
        if (device != null) 'device': device!.mapToRequest(),
        if (clientRecordId != null) 'clientRecordId': clientRecordId,
        if (clientRecordVersion != null)
          'clientRecordVersion': clientRecordVersion,
      };
}

/// === Schema: Value Mapping ===
/// Extension CKValue native serialization
extension CKValueMapping on CKValue {
  /// Maps CKValue to platform channel request format
  Map<String, Object?> mapToRequest() {
    return switch (this) {
      CKLabelValue() => (this as CKLabelValue).mapToRequest(),
      CKQuantityValue() => (this as CKQuantityValue).mapToRequest(),
      CKCategoryValue() => (this as CKCategoryValue).mapToRequest(),
      CKMultipleValue() => (this as CKMultipleValue).mapToRequest(),
      CKSamplesValue() => (this as CKSamplesValue).mapToRequest(),
    };
  }
}

/// Extension CKLabelValue native serialization
extension CKLabelValueMapping on CKLabelValue {
  /// Maps CKLabelValue to platform channel format
  Map<String, Object?> mapToRequest() => {
        'valuePattern': 'label',
        'value': value,
        // no unit for label values
      };
}

/// Extension CKQuantityValue native serialization
extension CKQuantityValueMapping on CKQuantityValue {
  /// Maps CKQuantityValue to platform channel format
  Map<String, Object?> mapToRequest() => {
        'valuePattern': 'quantity',
        'value': value,
        if (unit != null) 'unit': unit?.symbol,
      };
}

/// Extension CKCategoryValue native serialization
extension CKCategoryValueMapping on CKCategoryValue {
  /// Maps CKCategoryValue to platform channel format
  Map<String, Object?> mapToRequest() => {
        'valuePattern': 'category',
        'value': value.name, // enum name
        // no unit for category values
      };
}

/// Extension CKMultipleValue native serialization
extension CKMultipleValueMapping on CKMultipleValue {
  /// Maps CKMultipleValue to platform channel format
  Map<String, Object?> mapToRequest() => {
        'valuePattern': 'multiple',
        'value': {
          for (final entry in value.entries)
            entry.key: entry.value.mapToRequest(),
        },
        // no unit for parent multiple values
      };
}

/// Extension for CKSamplesValue native serialization
extension CKSamplesValueMapping on CKSamplesValue {
  /// Maps CKSamplesValue to platform channel format
  Map<String, Object?> mapToRequest() => {
        'valuePattern': 'samples',
        'value': value.map((sample) => sample.mapToRequest()).toList(),
        if (unit != null) 'unit': unit!.symbol, // outer unit for all samples
      };
}

/// Extension for CKSample serialization
extension CKSampleMapping on CKSample {
  /// Maps CKSample to platform channel format
  Map<String, Object?> mapToRequest() => {
        'value': value, // simple num
        'time': time.inMilliseconds,
      };
}

/// === Base Record Mapping ===
/// NOTE: Keep it in sync with record model
extension CKRecordMapping on CKRecord {
  /// Maps Record to platform channel request format
  Map<String, Object?> mapToRequest() {
    return {
      if (id != null) 'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'startZoneOffsetSeconds': startZoneOffset.inSeconds,
      'endZoneOffsetSeconds': endZoneOffset.inSeconds,
      if (source != null) 'source': source!.mapToRequest(),
    };
  }
}

/// === CKDataRecord Record Mapping ===
/// NOTE: Keep it in sync with record model
extension CKDataRecordMapping on CKDataRecord {
  /// Maps Record to platform channel request format
  Map<String, Object?> mapToRequest() => {
        if (id != null) 'id': id!,
        'recordKind':
            CKConstants.recordKindDataRecord, // Injected Differentiator
        'type': type.name,
        'data': data.mapToRequest(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'startZoneOffsetSeconds': startZoneOffset.inSeconds,
        'endZoneOffsetSeconds': endZoneOffset.inSeconds,
        if (source != null) 'source': source!.mapToRequest(),
      };
}

/// === CKAudiogram Record Mapping ===
/// NOTE: Keep it in sync with record model
extension CKAudiogramMapping on CKAudiogram {
  /// Maps Audiogram Record to platform channel request format
  Map<String, Object?> mapToRequest() => {
        if (id != null) 'id': id,
        'recordKind':
            CKConstants.recordKindAudiogram, // Injected Differentiator
        'time': startTime.toIso8601String(),
        'zoneOffsetSeconds': startZoneOffset.inSeconds,
        'sensitivityPoints':
            sensitivityPoints.map((p) => p.mapToRequest()).toList(),
        if (source != null) 'source': source!.mapToRequest(),
      };
}

/// === CKAudiogramPoint Mapping ===
/// NOTE: Keep it in sync with record model
extension CKAudiogramPointMapping on CKAudiogramPoint {
  /// Maps Audiogram Point to platform channel request format
  Map<String, Object?> mapToRequest() => {
        'frequency': frequency,
        if (leftEarSensitivity != null)
          'leftEarSensitivity': leftEarSensitivity,
        if (rightEarSensitivity != null)
          'rightEarSensitivity': rightEarSensitivity,
      };
}

/// === CKBloodPressure Record Mapping ===
/// NOTE: Keep it in sync with record model
extension CKBloodPressureMapping on CKBloodPressure {
  /// Maps Blood Pressure Record to platform channel request format
  Map<String, Object?> mapToRequest() => {
        if (id != null) 'id': id,
        'recordKind':
            CKConstants.recordKindBloodPressure, // Injected Differentiator
        'systolic': systolic.mapToRequest(),
        'diastolic': diastolic.mapToRequest(),
        'time': startTime.toIso8601String(),
        'zoneOffsetSeconds': startZoneOffset.inSeconds,
        if (bodyPosition != null) 'bodyPosition': bodyPosition!.name,
        if (measurementLocation != null)
          'measurementLocation': measurementLocation!.name,
        if (source != null) 'source': source!.mapToRequest(),
      };
}

/// === CKECG Record Mapping ===
/// NOTE: Keep it in sync with record model
extension CKEcgMapping on CKEcg {
  /// Maps ECG Record to platform channel request format
  Map<String, Object?> mapToRequest() => {
        if (id != null) 'id': id,
        'recordKind': CKConstants.recordKindEcg, // Injected Differentiator
        'classification': classification.name,
        if (averageHeartRate != null) 'averageHeartRate': averageHeartRate,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'startZoneOffsetSeconds': startZoneOffset.inSeconds,
        'endZoneOffsetSeconds': endZoneOffset.inSeconds,
        'symptoms': symptoms.map((s) => s.name).toList(),
        if (voltageMeasurements != null)
          'voltageMeasurements':
              voltageMeasurements!.map((v) => v.mapToRequest()).toList(),
        if (source != null) 'source': source!.mapToRequest(),
      };
}

/// === CKECGVoltageMeasurement Mapping ===
/// NOTE: Keep it in sync with record model/// NOTE: Keep it in sync with record model
extension CKEcgVoltageMeasurementMapping on CKEcgVoltageMeasurement {
  /// Maps ECG Voltage Measurement to platform channel request format
  Map<String, Object?> mapToRequest() => {
        'timeSinceStart': timeSinceStart,
        'microvolts': microvolts,
      };
}

/// === CKNutrition Record Mapping ===
/// NOTE: Keep it in sync with record model
extension CKNutritionMapping on CKNutrition {
  /// Maps Nutrition Record to platform channel request format
  Map<String, Object?> mapToRequest() {
    final map = <String, Object?>{
      if (id != null) 'id': id,
      'recordKind': CKConstants.recordKindNutrition, // Injected Differentiator
      if (name != null) 'name': name,
      if (mealType != null) 'mealType': mealType!.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'startZoneOffsetSeconds': startZoneOffset.inSeconds,
      'endZoneOffsetSeconds': endZoneOffset.inSeconds,
      if (source != null) 'source': source!.mapToRequest(),
    };

    // Add all non-null nutrients
    void addNutrient(String key, CKQuantityValue? value) {
      if (value != null) map[key] = value.mapToRequest();
    }

    // === NOTE: Keep it in sync with the nutrition values in ck_type.dart Schema ===
    addNutrient('energy', energy);
    addNutrient('protein', protein);
    addNutrient('totalCarbohydrate', totalCarbohydrate);
    addNutrient('totalFat', totalFat);
    addNutrient('dietaryFiber', dietaryFiber);
    addNutrient('sugar', sugar);
    addNutrient('saturatedFat', saturatedFat);
    addNutrient('unsaturatedFat', unsaturatedFat);
    addNutrient('monounsaturatedFat', monounsaturatedFat);
    addNutrient('polyunsaturatedFat', polyunsaturatedFat);
    addNutrient('transFat', transFat);
    addNutrient('cholesterol', cholesterol);
    addNutrient('calcium', calcium);
    addNutrient('chloride', chloride);
    addNutrient('chromium', chromium);
    addNutrient('copper', copper);
    addNutrient('iodine', iodine);
    addNutrient('iron', iron);
    addNutrient('magnesium', magnesium);
    addNutrient('manganese', manganese);
    addNutrient('molybdenum', molybdenum);
    addNutrient('phosphorus', phosphorus);
    addNutrient('potassium', potassium);
    addNutrient('selenium', selenium);
    addNutrient('sodium', sodium);
    addNutrient('zinc', zinc);
    addNutrient('vitaminA', vitaminA);
    addNutrient('vitaminB6', vitaminB6);
    addNutrient('vitaminB12', vitaminB12);
    addNutrient('vitaminC', vitaminC);
    addNutrient('vitaminD', vitaminD);
    addNutrient('vitaminE', vitaminE);
    addNutrient('vitaminK', vitaminK);
    addNutrient('thiamin', thiamin);
    addNutrient('riboflavin', riboflavin);
    addNutrient('niacin', niacin);
    addNutrient('folate', folate);
    addNutrient('biotin', biotin);
    addNutrient('pantothenicAcid', pantothenicAcid);

    return map;
  }
}

/// === CKSleepSession Record Mapping ===
/// NOTE: Keep it in sync with record model
extension CKSleepSessionMapping on CKSleepSession {
  /// Maps Sleep Session Record to platform channel request format
  Map<String, Object?> mapToRequest() => {
        if (id != null) 'id': id,
        'recordKind':
            CKConstants.recordKindSleepSession, // Injected Differentiator
        if (title != null) 'title': title,
        if (notes != null) 'notes': notes,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'startZoneOffsetSeconds': startZoneOffset.inSeconds,
        'endZoneOffsetSeconds': endZoneOffset.inSeconds,
        'stages': stages.map((s) => s.mapToRequest()).toList(),
        if (source != null) 'source': source!.mapToRequest(),
      };
}

/// === CKSleepStage Mapping ===
/// NOTE: Keep it in sync with record model
extension CKSleepStageMapping on CKSleepStage {
  /// Maps Sleep tage to platform channel request format
  Map<String, Object?> mapToRequest() => {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'stage': stage.name,
      };
}

/// === CKWorkout Record Mapping ===
/// NOTE: Keep it in sync with record model
extension CKWorkoutMapping on CKWorkout {
  /// Maps Workout Record to platform channel request format
  Map<String, Object?> mapToRequest() => {
        if (id != null) 'id': id,
        'recordKind': CKConstants.recordKindWorkout, // Injected Differentiator
        'activityType': activityType.name,
        if (title != null) 'title': title,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'startZoneOffsetSeconds': startZoneOffset.inSeconds,
        'endZoneOffsetSeconds': endZoneOffset.inSeconds,
        if (source != null) 'source': source!.mapToRequest(),
        if (duringSession != null)
          'duringSession': duringSession!.map((r) => r.mapToRequest()).toList(),
      };
}
