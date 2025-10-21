import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/utils/connect_kit_exception.dart';

void main() {
  group('ConnectKitException', () {
    test('toString includes message, code, and cause', () {
      final original = Exception('Original');
      final ex = ConnectKitException(
        'Test message',
        code: 'TEST_CODE',
        originalError: original,
      );

      expect(
        ex.toString(),
        'ConnectKitException: Test message [code: TEST_CODE] (caused by: $original)',
      );
    });

    test('toString handles null code and cause', () {
      final ex = ConnectKitException('Test message');
      expect(ex.toString(), 'ConnectKitException: Test message');
    });
  });

  group('PlatformUnavailableException', () {
    test('uses default message when null', () {
      final ex = PlatformUnavailableException(null);
      expect(ex.message, 'Native platform implementation is unavailable');
      expect(ex.code, 'PLATFORM_UNAVAILABLE');
    });

    test('uses provided message', () {
      final ex = PlatformUnavailableException('Custom message');
      expect(ex.message, 'Custom message');
    });
  });

  group('OperationTimeoutException', () {
    test('uses default message when null', () {
      final ex = OperationTimeoutException(null);
      expect(ex.message, 'Operation timed out');
      expect(ex.code, 'OPERATION_TIMEOUT');
    });

    test('stores timeout duration', () {
      final timeout = Duration(seconds: 5);
      final ex = OperationTimeoutException('Timed out', timeout: timeout);
      expect(ex.timeout, timeout);
    });
  });

  group('PlatformCommunicationException', () {
    test('uses default message when null', () {
      final ex = PlatformCommunicationException(null);
      expect(ex.message, 'Fluter <-> Platform communication failed');
      expect(ex.code, 'COMMUNICATION_FAILED');
    });
  });

  group('NotImplementedException', () {
    test('uses default message when null', () {
      final ex = NotImplementedException(null);
      expect(ex.message, 'Feature not implemented');
      expect(ex.code, 'NOT_IMPLEMENTED');
    });
  });

  group('DataConversionException', () {
    test('stores source and target types', () {
      final ex = DataConversionException(
        'Conversion failed',
        sourceType: int,
        targetType: String,
      );
      expect(ex.sourceType, int);
      expect(ex.targetType, String);
    });
  });
}
