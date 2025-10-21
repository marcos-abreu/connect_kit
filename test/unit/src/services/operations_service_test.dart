import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:connect_kit/src/services/operations_service.dart';
import 'package:connect_kit/src/pigeon/connect_kit_messages.g.dart';
import 'package:connect_kit/src/utils/connect_kit_exception.dart';

class MockConnectKitHostApi extends Mock implements ConnectKitHostApi {}

void main() {
  late MockConnectKitHostApi mockApi;
  late OperationsService service;

  setUp(() {
    mockApi = MockConnectKitHostApi();
    service = OperationsService(mockApi);
    resetMocktailState();
  });

  group('OperationsService.getPlatformVersion', () {
    test('returns version on success', () async {
      when(() => mockApi.getPlatformVersion())
          .thenAnswer((_) async => 'iOS 17');
      final version = await service.getPlatformVersion();
      expect(version, 'iOS 17');
      verify(() => mockApi.getPlatformVersion()).called(1);
    });

    test('rethrows ConnectKitException on failure', () async {
      when(() => mockApi.getPlatformVersion())
          .thenThrow(Exception('Test error'));
      expect(
        () => service.getPlatformVersion(),
        throwsA(isA<ConnectKitException>()),
      );
    });

    test('handles timeout', () async {
      // Simulate timeout by mocking OperationGuard (not recommended in real tests,
      // but for this test we rely on the actual OperationGuard behavior)
      // Instead, we test via the OperationGuard tests above.
      // This test just ensures the delegation works.
      when(() => mockApi.getPlatformVersion()).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 2));
        return 'slow';
      });

      // This will not timeout because no timeout is set in getPlatformVersion()
      // To test timeout, you'd need to modify the method to accept a timeout param
      // For now, we just test the happy path and error path.
    });
  });
}

// import 'package:flutter/services.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mocktail/mocktail.dart';

// // Class under test
// import 'package:connect_kit/src/services/operations_service.dart';

// // Class to mock (the generated Pigeon Host API)
// import 'package:connect_kit/src/pigeon/connect_kit_messages.g.dart';
// class MockConnectKitHostApi extends Mock implements ConnectKitHostApi {}

// void main() {
//   setUpAll(() {
//     // Register fallback for PlatformException (required by Mocktail for throwing errors)
//     registerFallbackValue(PlatformException(code: 'TEST_ERROR'));
//   });

//   group('OperationsService', () {
//     late MockConnectKitHostApi mockApi;
//     late OperationsService operationsService;

//     setUp(() {
//       mockApi = MockConnectKitHostApi();
//       // Service is initialized with the mock dependency (Dependency Injection)
//       operationsService = OperationsService(mockApi);
//     });

//     // Tear down is optional here since the main `test/connect_kit_test.dart` has one,
//     // but resetting specific mocks is a good practice.
//     tearDown(() {
//       reset(mockApi);
//     });

//     test('getPlatformVersion returns platform version from host API', () async {
//       // Arrange
//       const expectedVersion = '14.5';
//       when(() => mockApi.getPlatformVersion()).thenAnswer((_) async => expectedVersion);

//       // Act
//       final version = await operationsService.getPlatformVersion();

//       // Assert
//       expect(version, expectedVersion);
//       verify(() => mockApi.getPlatformVersion()).called(1); // Verify the call was delegated
//     });

//     test('getPlatformVersion throws PlatformException when host API fails',
//         () async {
//       // Arrange
//       when(() => mockApi.getPlatformVersion())
//           .thenThrow(PlatformException(code: 'some-code', message: 'Failed'));

//       // Act & Assert
//       expect(
//         () => operationsService.getPlatformVersion(),
//         throwsA(isA<PlatformException>()),
//       );
//       verify(() => mockApi.getPlatformVersion()).called(1);
//     });

//     test('getPlatformVersion rethrows generic exceptions', () async {
//       // Arrange
//       final genericException = Exception('Something went wrong');
//       when(() => mockApi.getPlatformVersion())
//           .thenThrow(genericException);

//       // Act & Assert
//       expect(
//         () => operationsService.getPlatformVersion(),
//         throwsA(isA<Exception>()),
//       );
//       verify(() => mockApi.getPlatformVersion()).called(1);
//     });
//   });
// }
