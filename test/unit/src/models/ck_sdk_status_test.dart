// test/unit/src/models/ck_sdk_status_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/ck_sdk_status.dart';

void main() {
  group('CKSdkStatus', () {
    test('has correct enum values', () {
      expect(CKSdkStatus.values, hasLength(3));
      expect(CKSdkStatus.values, contains(CKSdkStatus.available));
      expect(CKSdkStatus.values, contains(CKSdkStatus.unavailable));
      expect(CKSdkStatus.values, contains(CKSdkStatus.updateRequired));
    });

    group('fromString', () {
      test('returns correct enum for valid strings', () {
        expect(CKSdkStatus.fromString('available'), CKSdkStatus.available);
        expect(CKSdkStatus.fromString('unavailable'), CKSdkStatus.unavailable);
        expect(CKSdkStatus.fromString('updateRequired'),
            CKSdkStatus.updateRequired);
      });

      test('returns unavailable for invalid strings', () {
        expect(CKSdkStatus.fromString('invalid'), CKSdkStatus.unavailable);
        expect(CKSdkStatus.fromString(''), CKSdkStatus.unavailable);
      });
    });

    group('extension properties', () {
      test('displayName returns correct values', () {
        expect(CKSdkStatus.available.displayName, 'Available');
        expect(CKSdkStatus.unavailable.displayName, 'Unavailable');
        expect(CKSdkStatus.updateRequired.displayName, 'Update Required');
      });
    });
  });
}
