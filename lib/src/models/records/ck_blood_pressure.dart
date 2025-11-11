import 'package:connect_kit/src/models/records/ck_record.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';
import 'package:connect_kit/src/models/schema/ck_unit.dart';
import 'package:connect_kit/src/models/schema/ck_value.dart';

/// Blood pressure reading (systolic/diastolic)
///
/// **Platform Behavior:**
/// - **Android**: Maps to `BloodPressureRecord`
/// - **iOS**: Maps to `HKCorrelation` containing systolic + diastolic samples
class CKBloodPressure extends CKRecord {
  /// Systolic pressure value (upper number)
  final CKQuantityValue systolic;

  /// Diastolic pressure value (lower number)
  final CKQuantityValue diastolic;

  /// Body position during measurement (optional)
  /// Android-specific
  final CKBodyPosition? bodyPosition;

  /// Measurement location (optional)
  /// Android-specific
  final CKMeasurementLocation? measurementLocation;

  /// TODO: add documentation
  const CKBloodPressure({
    super.id,
    required DateTime time,
    Duration? zoneOffset,
    super.source,
    required this.systolic,
    required this.diastolic,
    this.bodyPosition,
    this.measurementLocation,
  }) : super(
          startTime: time,
          endTime: time,
          startZoneOffset: zoneOffset,
          endZoneOffset: zoneOffset,
        );

  /// Create blood pressure with values in mmHg
  factory CKBloodPressure.mmHg({
    required double systolic,
    required double diastolic,
    required DateTime time,
    Duration? zoneOffset,
    required CKSource source,
    CKBodyPosition? bodyPosition,
    CKMeasurementLocation? measurementLocation,
  }) {
    return CKBloodPressure(
      time: time,
      zoneOffset: zoneOffset,
      source: source,
      systolic: CKQuantityValue(systolic, CKUnit.pressure.millimetersOfMercury),
      diastolic:
          CKQuantityValue(diastolic, CKUnit.pressure.millimetersOfMercury),
      bodyPosition: bodyPosition,
      measurementLocation: measurementLocation,
    );
  }

  @override
  void validate() {
    super.validate();

    // Validate both values are present and use same unit
    if (systolic.unit != diastolic.unit) {
      throw ArgumentError('Systolic and diastolic must use same unit: '
          'systolic=${systolic.unit}, diastolic=${diastolic.unit}');
    }

    // Validate reasonable ranges (optional warning)
    final sysValue = systolic.value as double;
    final diaValue = diastolic.value as double;

    if (sysValue < diaValue) {
      throw ArgumentError(
        'Systolic ($sysValue) cannot be less than diastolic ($diaValue)',
      );
    }
  }
}

/// Body position during blood pressure measurement
enum CKBodyPosition {
  /// Standing upright
  standingUp,

  /// Sitting down
  sittingDown,

  /// Lying down flat
  lyingDown,

  /// Reclining (partially reclined)
  reclining,

  /// Body position unknown / not identified
  unknown;
}

/// Measurement location for blood pressure
enum CKMeasurementLocation {
  /// Left wrist
  leftWrist,

  /// Right wrist
  rightWrist,

  /// Left upper arm
  leftUpperArm,

  /// Right upper arm
  rightUpperArm,

  /// Measurement location unknown / not identified
  unknown;
}
