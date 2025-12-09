import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';
import 'package:connect_kit/src/models/schema/ck_device.dart';

void main() {
  group('CKSource', () {
    group('Constructor', () {
      test('creates source with minimum required parameters', () {
        final source = CKSource(
          recordingMethod: CKRecordingMethod.manualEntry,
        );

        expect(source.recordingMethod, equals(CKRecordingMethod.manualEntry));
        expect(source.device, isNull);
        expect(source.appRecordUUID, isNull);
        expect(source.sdkRecordId, isNull);
        expect(source.sdkRecordVersion, isNull);
      });

      test('creates source with all parameters', () {
        final device = CKDevice.watch(
          manufacturer: 'Apple',
          model: 'Apple Watch Series 8',
        );

        final source = CKSource(
          recordingMethod: CKRecordingMethod.automaticallyRecorded,
          device: device,
          appRecordUUID: 'app-record-123',
          sdkRecordId: 'sdk-record-456',
          sdkRecordVersion: 1,
        );

        expect(source.recordingMethod, equals(CKRecordingMethod.automaticallyRecorded));
        expect(source.device, equals(device));
        expect(source.appRecordUUID, equals('app-record-123'));
        expect(source.sdkRecordId, equals('sdk-record-456'));
        expect(source.sdkRecordVersion, equals(1));
      });

      test('creates source with partial parameters', () {
        final source = CKSource(
          recordingMethod: CKRecordingMethod.activelyRecorded,
          device: CKDevice.phone(
            manufacturer: 'Google',
            model: 'Pixel 7',
          ),
          sdkRecordId: 'pixel-7-record',
        );

        expect(source.recordingMethod, equals(CKRecordingMethod.activelyRecorded));
        expect(source.device?.manufacturer, equals('Google'));
        expect(source.device?.model, equals('Pixel 7'));
        expect(source.appRecordUUID, isNull);
        expect(source.sdkRecordId, equals('pixel-7-record'));
        expect(source.sdkRecordVersion, isNull);
      });
    });

    group('Factory methods', () {
      test('manualEntry factory creates source with manualEntry recording method', () {
        final device = CKDevice.scale(
          manufacturer: 'Withings',
          model: 'Body+',
        );

        final source = CKSource.manualEntry(
          device: device,
          appRecordUUID: 'manual-uuid-789',
          sdkRecordId: 'manual-sdk-id-101',
          sdkRecordVersion: 2,
        );

        expect(source.recordingMethod, equals(CKRecordingMethod.manualEntry));
        expect(source.device, equals(device));
        expect(source.appRecordUUID, equals('manual-uuid-789'));
        expect(source.sdkRecordId, equals('manual-sdk-id-101'));
        expect(source.sdkRecordVersion, equals(2));
      });

      test('manualEntry factory works with minimal parameters', () {
        final source = CKSource.manualEntry();

        expect(source.recordingMethod, equals(CKRecordingMethod.manualEntry));
        expect(source.device, isNull);
        expect(source.appRecordUUID, isNull);
        expect(source.sdkRecordId, isNull);
        expect(source.sdkRecordVersion, isNull);
      });

      test('manualEntry factory works with only device', () {
        final device = CKDevice(
          manufacturer: 'Oura',
          model: 'Oura Ring 3',
          type: CKDeviceType.ring,
        );

        final source = CKSource.manualEntry(device: device);

        expect(source.recordingMethod, equals(CKRecordingMethod.manualEntry));
        expect(source.device, equals(device));
        expect(source.appRecordUUID, isNull);
        expect(source.sdkRecordId, isNull);
        expect(source.sdkRecordVersion, isNull);
      });

      test('manualEntry factory works with only appRecordUUID', () {
        final source = CKSource.manualEntry(
          appRecordUUID: 'user-uuid-abc',
        );

        expect(source.recordingMethod, equals(CKRecordingMethod.manualEntry));
        expect(source.device, isNull);
        expect(source.appRecordUUID, equals('user-uuid-abc'));
        expect(source.sdkRecordId, isNull);
        expect(source.sdkRecordVersion, isNull);
      });

      test('activelyRecorded factory creates source with activelyRecorded recording method', () {
        final device = CKDevice.watch(
          manufacturer: 'Garmin',
          model: 'Forerunner 955',
        );

        final source = CKSource.activelyRecorded(
          device: device,
          appRecordUUID: 'workout-record-456',
          sdkRecordId: 'workout-sdk-789',
          sdkRecordVersion: 3,
        );

        expect(source.recordingMethod, equals(CKRecordingMethod.activelyRecorded));
        expect(source.device, equals(device));
        expect(source.appRecordUUID, equals('workout-record-456'));
        expect(source.sdkRecordId, equals('workout-sdk-789'));
        expect(source.sdkRecordVersion, equals(3));
      });

      test('activelyRecorded factory requires device parameter', () {
        final device = CKDevice.phone(
          manufacturer: 'Samsung',
          model: 'Galaxy S24',
        );

        final source = CKSource.activelyRecorded(
          device: device,
        );

        expect(source.recordingMethod, equals(CKRecordingMethod.activelyRecorded));
        expect(source.device, equals(device));
        expect(source.appRecordUUID, isNull);
        expect(source.sdkRecordId, isNull);
        expect(source.sdkRecordVersion, isNull);
      });

      test('automaticallyRecorded factory creates source with automaticallyRecorded recording method', () {
        final device = CKDevice(
          manufacturer: 'WHOOP',
          model: 'WHOOP Band',
          type: CKDeviceType.fitnessBand,
        );

        final source = CKSource.automaticallyRecorded(
          device: device,
          appRecordUUID: 'background-steps-123',
          sdkRecordId: 'auto-sdk-id-456',
          sdkRecordVersion: 1,
        );

        expect(source.recordingMethod, equals(CKRecordingMethod.automaticallyRecorded));
        expect(source.device, equals(device));
        expect(source.appRecordUUID, equals('background-steps-123'));
        expect(source.sdkRecordId, equals('auto-sdk-id-456'));
        expect(source.sdkRecordVersion, equals(1));
      });

      test('automaticallyRecorded factory requires device parameter', () {
        final device = CKDevice.scale(
          manufacturer: 'Fitbit',
          model: 'Aria Air',
        );

        final source = CKSource.automaticallyRecorded(
          device: device,
        );

        expect(source.recordingMethod, equals(CKRecordingMethod.automaticallyRecorded));
        expect(source.device, equals(device));
        expect(source.appRecordUUID, isNull);
        expect(source.sdkRecordId, isNull);
        expect(source.sdkRecordVersion, isNull);
      });
    });

    group('CKRecordingMethod enum', () {
      test('contains all expected recording methods', () {
        final methods = CKRecordingMethod.values;
        expect(methods, hasLength(4));
        expect(methods, contains(CKRecordingMethod.manualEntry));
        expect(methods, contains(CKRecordingMethod.activelyRecorded));
        expect(methods, contains(CKRecordingMethod.automaticallyRecorded));
        expect(methods, contains(CKRecordingMethod.unknown));
      });

      test('toString returns enum name', () {
        expect(CKRecordingMethod.manualEntry.toString(), equals('CKRecordingMethod.manualEntry'));
        expect(CKRecordingMethod.activelyRecorded.toString(), equals('CKRecordingMethod.activelyRecorded'));
        expect(CKRecordingMethod.automaticallyRecorded.toString(), equals('CKRecordingMethod.automaticallyRecorded'));
        expect(CKRecordingMethod.unknown.toString(), equals('CKRecordingMethod.unknown'));
      });

      test('can compare recording methods', () {
        expect(CKRecordingMethod.manualEntry, equals(CKRecordingMethod.manualEntry));
        expect(CKRecordingMethod.manualEntry, isNot(equals(CKRecordingMethod.activelyRecorded)));
        expect(CKRecordingMethod.activelyRecorded, isNot(equals(CKRecordingMethod.automaticallyRecorded)));
      });

      test('has same hashCode for equal recording methods', () {
        expect(CKRecordingMethod.manualEntry.hashCode, equals(CKRecordingMethod.manualEntry.hashCode));
        expect(CKRecordingMethod.manualEntry.hashCode, isNot(equals(CKRecordingMethod.activelyRecorded.hashCode)));
      });
    });

    group('Integration tests', () {
      test('creates comprehensive source for different recording scenarios', () {
        final manualDevice = CKDevice.phone(
          manufacturer: 'Apple',
          model: 'iPhone 15 Pro',
        );

        final workoutDevice = CKDevice(
          manufacturer: 'Garmin',
          model: 'Fenix 7X',
          type: CKDeviceType.watch,
        );

        final scaleDevice = CKDevice.scale(
          manufacturer: 'Withings',
          model: 'Body+ Smart Scale',
        );

        final ringDevice = CKDevice(
          manufacturer: 'Oura',
          model: 'Oura Ring 3',
          type: CKDeviceType.ring,
        );

        // Manual entry scenario (e.g., food logging)
        final manualSource = CKSource.manualEntry(
          device: manualDevice,
          appRecordUUID: 'food-log-123',
          sdkRecordId: 'manual-456',
          sdkRecordVersion: 1,
        );

        // Workout recording scenario
        final workoutSource = CKSource.activelyRecorded(
          device: workoutDevice,
          appRecordUUID: 'workout-789',
          sdkRecordId: 'workout-101',
          sdkRecordVersion: 2,
        );

        // Automatic step tracking scenario
        final autoSource = CKSource.automaticallyRecorded(
          device: scaleDevice,
          appRecordUUID: 'steps-123',
          sdkRecordId: 'auto-456',
          sdkRecordVersion: 0,
        );

        // Sleep tracking with ring
        final sleepSource = CKSource.activelyRecorded(
          device: ringDevice,
          appRecordUUID: 'sleep-789',
          sdkRecordId: 'sleep-456',
          sdkRecordVersion: 3,
        );

        // Verify manual source
        expect(manualSource.recordingMethod, equals(CKRecordingMethod.manualEntry));
        expect(manualSource.device?.model, equals('iPhone 15 Pro'));
        expect(manualSource.sdkRecordId, equals('manual-456'));

        // Verify workout source
        expect(workoutSource.recordingMethod, equals(CKRecordingMethod.activelyRecorded));
        expect(workoutSource.device?.hardwareVersion, isNull);
        expect(workoutSource.sdkRecordVersion, equals(2));

        // Verify automatic source
        expect(autoSource.recordingMethod, equals(CKRecordingMethod.automaticallyRecorded));
        expect(autoSource.device?.model, equals('Body+ Smart Scale'));
        expect(autoSource.sdkRecordVersion, equals(0));

        // Verify sleep source
        expect(sleepSource.recordingMethod, equals(CKRecordingMethod.activelyRecorded));
        expect(sleepSource.device?.hardwareVersion, isNull);
        expect(sleepSource.sdkRecordId, equals('sleep-456'));
      });

      test('handles edge cases with null values', () {
        final source1 = CKSource(
          recordingMethod: CKRecordingMethod.manualEntry,
          device: null,
          appRecordUUID: null,
          sdkRecordId: null,
          sdkRecordVersion: null,
        );

        final source2 = CKSource(
          recordingMethod: CKRecordingMethod.activelyRecorded,
          device: null,
          appRecordUUID: 'test-uuid',
        );

        final source3 = CKSource(
          recordingMethod: CKRecordingMethod.automaticallyRecorded,
          device: null,
          sdkRecordId: 'test-sdk-id',
        );

        expect(source1.device, isNull);
        expect(source1.appRecordUUID, isNull);
        expect(source1.sdkRecordId, isNull);
        expect(source1.sdkRecordVersion, isNull);

        expect(source2.device, isNull);
        expect(source2.appRecordUUID, equals('test-uuid'));
        expect(source2.sdkRecordId, isNull);
        expect(source2.sdkRecordVersion, isNull);

        expect(source3.device, isNull);
        expect(source3.sdkRecordId, equals('test-sdk-id'));
        expect(source3.sdkRecordVersion, isNull);
      });

      test('creates source with complex device configurations', () {
        final complexDevice = CKDevice(
          manufacturer: 'Apple',
          model: 'iPhone 15 Pro Max',
          type: CKDeviceType.phone,
          hardwareVersion: null,
          softwareVersion: null,
        );

        final source = CKSource.activelyRecorded(
          device: complexDevice,
          appRecordUUID: 'complex-device-source',
          sdkRecordId: 'complex-id-123',
          sdkRecordVersion: 4,
        );

        expect(source.recordingMethod, equals(CKRecordingMethod.activelyRecorded));
        expect(source.device?.model, equals('iPhone 15 Pro Max'));
        expect(source.device?.type, equals(CKDeviceType.phone));
        expect(source.device?.hardwareVersion, isNull);
        expect(source.device?.softwareVersion, isNull);
      });

      test('handles very long identifiers', () {
        final veryLongAppUUID = 'app-record-uuid-123456789012345678901234567890';
        final veryLongSdkId = 'sdk-record-id-987654321098765432109876543210987654321';
        final veryLongVersion = 999999999;

        final source = CKSource.manualEntry(
          appRecordUUID: veryLongAppUUID,
          sdkRecordId: veryLongSdkId,
          sdkRecordVersion: veryLongVersion,
        );

        expect(source.appRecordUUID, equals(veryLongAppUUID));
        expect(source.sdkRecordId, equals(veryLongSdkId));
        expect(source.sdkRecordVersion, equals(veryLongVersion));
      });

      test('handles zero and negative version numbers', () {
        final source1 = CKSource(
          recordingMethod: CKRecordingMethod.manualEntry,
          sdkRecordVersion: 0,
        );

        final source2 = CKSource(
          recordingMethod: CKRecordingMethod.manualEntry,
          sdkRecordVersion: -1,
        );

        expect(source1.sdkRecordVersion, equals(0));
        expect(source2.sdkRecordVersion, equals(-1));
      });
    });
  });
}