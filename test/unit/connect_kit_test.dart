import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:connect_kit/src/models/ck_sdk_status.dart';
import 'package:connect_kit/src/models/schema/ck_type.dart';
import 'package:connect_kit/src/models/ck_access_type.dart';
import 'package:connect_kit/src/models/ck_access_status.dart';

// Class under test
import 'package:connect_kit/connect_kit.dart';

// Class to mock
import 'package:connect_kit/src/services/operations_service.dart';
import 'package:connect_kit/src/services/permission_service.dart';

class MockOperationsService extends Mock implements OperationsService {}

class MockPermissionService extends Mock implements PermissionService {}

void main() {
  late ConnectKit testConnectKit;
  late MockOperationsService mockOperationsService;
  late PermissionService mockPermissionService;

  setUp(() {
    mockOperationsService = MockOperationsService();
    mockPermissionService = MockPermissionService();

    // Set up default mock behaviors to return null
    registerFallbackValue(CKSdkStatus.fromString('unknown'));
    registerFallbackValue(CKAccessStatus(dataAccess: {}));

    // We use the forTesting constructor to inject the mock service.
    testConnectKit = ConnectKit.forTesting(
      operationsService: mockOperationsService,
      permissionService: mockPermissionService,
    );
  });

  tearDown(() {
    reset(mockOperationsService);
    reset(mockPermissionService);
  });

  group('ConnectKit Instance', () {
    test('instance returns the same instance (Singleton check)', () {
      final instance1 = ConnectKit.instance;
      final instance2 = ConnectKit.instance;
      expect(instance1, same(instance2));
    });

    test('default instance initializes correctly', () {
      expect(ConnectKit.instance.getPlatformVersion, isNotNull);
    });
  });

  group('ConnectKit Operations Facade', () {
    test(
        'getPlatformVersion delegates call to OperationsService and returns result',
        () async {
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

    test('getPlatformVersion re-throws exceptions from OperationsService',
        () async {
      // Arrange
      final expectedError = Exception('Service layer failure');
      when(() => mockOperationsService.getPlatformVersion())
          .thenThrow(expectedError);

      // Act & Assert
      expect(
        () => testConnectKit.getPlatformVersion(),
        throwsA(isA<Exception>()),
      );
      verify(() => mockOperationsService.getPlatformVersion()).called(1);
    });
  });

  group('ConnectKit Permission Facade', () {
    test(
        'isSdkAvailable delegates call to PermissionService and returns result',
        () async {
      // Arrange
      final statusGranted = CKSdkStatus.fromString('granted');
      when(() => mockPermissionService.isSdkAvailable())
          .thenAnswer((_) async => statusGranted);

      // Act
      final isSdkAvailable = await testConnectKit.isSdkAvailable();

      // Assert
      verify(() => mockPermissionService.isSdkAvailable()).called(1);
      expect(isSdkAvailable, statusGranted);
    });

    test('isSdkAvailable re-throws exceptions from PermissionService',
        () async {
      // Arrange
      final expectedError = Exception('Service layer failure');
      when(() => mockPermissionService.isSdkAvailable())
          .thenThrow(expectedError);

      // Act & Assert
      expect(
        () => testConnectKit.isSdkAvailable(),
        throwsA(isA<Exception>()),
      );
      verify(() => mockPermissionService.isSdkAvailable()).called(1);
    });

    test(
        'requestPermission delegates call to PermissionService and returns result',
        () async {
      // Arrange
      when(() => mockPermissionService.requestPermissions(
            readTypes: any(named: 'readTypes'),
            writeTypes: any(named: 'writeTypes'),
            forHistory: any(named: 'forHistory'),
            forBackground: any(named: 'forBackground'),
          )).thenAnswer((_) async => true);

      // Act
      final requestResult = await testConnectKit.requestPermissions(
        readTypes: {},
        writeTypes: {},
      );

      // Assert
      verify(() => mockPermissionService.requestPermissions(
            readTypes: {},
            writeTypes: {},
            forHistory: false,
            forBackground: false,
          )).called(1);
      expect(requestResult, true);
    });
    test('requestPermission re-throws exceptions from PermissionService',
        () async {
      // Arrange
      final expectedError = Exception('Service layer failure');
      when(() => mockPermissionService.requestPermissions(
            readTypes: any(named: 'readTypes'),
            writeTypes: any(named: 'writeTypes'),
            forHistory: any(named: 'forHistory'),
            forBackground: any(named: 'forBackground'),
          )).thenThrow(expectedError);

      // Act & Assert
      expect(
        () => testConnectKit.requestPermissions(
          readTypes: {},
          writeTypes: {},
        ),
        throwsA(isA<Exception>()),
      );
      verify(() => mockPermissionService.requestPermissions(
            readTypes: {},
            writeTypes: {},
            forHistory: false,
            forBackground: false,
          )).called(1);
    });

    test(
        'checkPermission delegates call to PermissionService and returns result',
        () async {
      // Arrange
      final expectedAccessStatus = CKAccessStatus(
        dataAccess: {
          CKType.steps: {CKAccessType.read: CKPermissionStatus.granted},
        },
      );
      when(() => mockPermissionService.checkPermissions(
            forData: any(named: 'forData'),
            forHistory: any(named: 'forHistory'),
            forBackground: any(named: 'forBackground'),
          )).thenAnswer((_) async => expectedAccessStatus);

      // Act
      final actualAccessStatus = await testConnectKit.checkPermissions(
        forData: {},
      );

      // Assert
      verify(() => mockPermissionService.checkPermissions(
            forData: {},
            forHistory: false,
            forBackground: false,
          )).called(1);
      expect(actualAccessStatus, expectedAccessStatus);
    });

    test('checkPermission re-throws exceptions from PermissionService',
        () async {
      // Arrange
      final expectedError = Exception('Service layer failure');
      when(() => mockPermissionService.checkPermissions(
            forData: any(named: 'forData'),
            forHistory: any(named: 'forHistory'),
            forBackground: any(named: 'forBackground'),
          )).thenThrow(expectedError);

      // Act & Assert
      expect(
        () => testConnectKit.checkPermissions(
          forData: {},
        ),
        throwsA(isA<Exception>()),
      );
      verify(() => mockPermissionService.checkPermissions(
            forData: {},
            forHistory: false,
            forBackground: false,
          )).called(1);
    });

    test(
        'revokePermission delegates call to PermissionService and returns result',
        () async {
      // Arrange
      when(() => mockPermissionService.revokePermissions())
          .thenAnswer((_) async => true);

      // Act
      final revokeResult = await testConnectKit.revokePermissions();

      // Assert
      verify(() => mockPermissionService.revokePermissions()).called(1);
      expect(revokeResult, true);
    });

    test('revokePermission re-throws exceptions from PermissionService',
        () async {
      // Arrange
      final expectedError = Exception('Service layer failure');
      when(() => mockPermissionService.revokePermissions())
          .thenThrow(expectedError);

      // Act & Assert
      expect(
        () => testConnectKit.revokePermissions(),
        throwsA(isA<Exception>()),
      );
      verify(() => mockPermissionService.revokePermissions()).called(1);
    });

    test(
        'openHealthSettings delegates call to PermissionService and returns result',
        () async {
      // Arrange
      when(() => mockPermissionService.openHealthSettings())
          .thenAnswer((_) async => true);

      // Act
      final settingsResult = await testConnectKit.openHealthSettings();

      // Assert
      verify(() => mockPermissionService.openHealthSettings()).called(1);
      expect(settingsResult, true);
    });

    test('openHealthSettings re-throws exceptions from PermissionService',
        () async {
      // Arrange
      final expectedError = Exception('Service layer failure');
      when(() => mockPermissionService.openHealthSettings())
          .thenThrow(expectedError);

      // Act & Assert
      expect(
        () => testConnectKit.openHealthSettings(),
        throwsA(isA<Exception>()),
      );
      verify(() => mockPermissionService.openHealthSettings()).called(1);
    });
  });
}
