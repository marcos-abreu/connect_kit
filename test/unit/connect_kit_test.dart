import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Class under test
import 'package:connect_kit/connect_kit.dart';

// Class to mock
import 'package:connect_kit/src/services/operations_service.dart';
class MockOperationsService extends Mock implements OperationsService {}

void main() {
  late ConnectKit testConnectKit;
  late MockOperationsService mockOperationsService;

  setUp(() {
    mockOperationsService = MockOperationsService();

    // We use the forTesting constructor to inject the mock service.
    testConnectKit = ConnectKit.forTesting(
      operationsService: mockOperationsService,
    );
  });

  tearDown(() {
    reset(mockOperationsService);
  });

  group('ConnectKit Facade', () {
    test('instance returns the same instance (Singleton check)', () {
      final instance1 = ConnectKit.instance;
      final instance2 = ConnectKit.instance;
      expect(instance1, same(instance2));
    });

    test('getPlatformVersion delegates call to OperationsService and returns result', () async {
      // Arrange
      const expectedVersion = 'Test-OS 1.0';
      when(() => mockOperationsService.getPlatformVersion())
          .thenAnswer((_) async => expectedVersion);

      // Act
      final actualVersion = await testConnectKit.getPlatformVersion();

      // Assert
      verify(() => mockOperationsService.getPlatformVersion()).called(1);
      expect(actualVersion, expectedVersion);
    });

    test('getPlatformVersion re-throws exceptions from OperationsService', () async {
      // Arrange
      final expectedError = Exception('Service layer failure');
      when(() => mockOperationsService.getPlatformVersion()).thenThrow(expectedError);

      // Act & Assert
      expect(
        () => testConnectKit.getPlatformVersion(),
        throwsA(isA<Exception>()),
      );
      verify(() => mockOperationsService.getPlatformVersion()).called(1);
    });
  });
}
