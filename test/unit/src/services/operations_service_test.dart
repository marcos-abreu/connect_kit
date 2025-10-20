
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Class under test
import 'package:connect_kit/src/services/operations_service.dart';

// Class to mock (the generated Pigeon Host API)
import 'package:connect_kit/src/pigeon/connect_kit_messages.g.dart';
class MockConnectKitHostApi extends Mock implements ConnectKitHostApi {}

void main() {
  setUpAll(() {
    // Register fallback for PlatformException (required by Mocktail for throwing errors)
    registerFallbackValue(PlatformException(code: 'TEST_ERROR'));
  });

  group('OperationsService', () {
    late MockConnectKitHostApi mockApi;
    late OperationsService operationsService;

    setUp(() {
      mockApi = MockConnectKitHostApi();
      // Service is initialized with the mock dependency (Dependency Injection)
      operationsService = OperationsService(mockApi);
    });

    // Tear down is optional here since the main `test/connect_kit_test.dart` has one,
    // but resetting specific mocks is a good practice.
    tearDown(() {
      reset(mockApi);
    });

    test('getPlatformVersion returns platform version from host API', () async {
      // Arrange
      const expectedVersion = '14.5';
      when(() => mockApi.getPlatformVersion()).thenAnswer((_) async => expectedVersion);

      // Act
      final version = await operationsService.getPlatformVersion();

      // Assert
      expect(version, expectedVersion);
      verify(() => mockApi.getPlatformVersion()).called(1); // Verify the call was delegated
    });

    test('getPlatformVersion throws PlatformException when host API fails',
        () async {
      // Arrange
      when(() => mockApi.getPlatformVersion())
          .thenThrow(PlatformException(code: 'some-code', message: 'Failed'));

      // Act & Assert
      expect(
        () => operationsService.getPlatformVersion(),
        throwsA(isA<PlatformException>()),
      );
      verify(() => mockApi.getPlatformVersion()).called(1);
    });

    test('getPlatformVersion rethrows generic exceptions', () async {
      // Arrange
      final genericException = Exception('Something went wrong');
      when(() => mockApi.getPlatformVersion())
          .thenThrow(genericException);

      // Act & Assert
      expect(
        () => operationsService.getPlatformVersion(),
        throwsA(isA<Exception>()),
      );
      verify(() => mockApi.getPlatformVersion()).called(1);
    });
  });
}
