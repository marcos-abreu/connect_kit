// test/unit/src/services/permission_service_test.dart
import 'package:connect_kit/src/utils/connect_kit_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/services.dart';

import 'package:connect_kit/src/services/permission_service.dart';
import 'package:connect_kit/src/pigeon/connect_kit_messages.g.dart';
import 'package:connect_kit/src/models/schema/ck_type.dart';
import 'package:connect_kit/src/models/ck_access_type.dart';
import 'package:connect_kit/src/models/ck_sdk_status.dart';
import 'package:connect_kit/src/models/ck_permission_status.dart';

// Mock for ConnectKitHostApi
class MockConnectKitHostApi extends Mock implements ConnectKitHostApi {}

void main() {
  late MockConnectKitHostApi mockHostApi;
  late PermissionService permissionService;

  setUp(() {
    mockHostApi = MockConnectKitHostApi();
    permissionService = PermissionService(mockHostApi);
  });

  group('PermissionService', () {
    group('isSdkAvailable', () {
      test('returns available status when platform returns available',
          () async {
        when(() => mockHostApi.isSdkAvailable())
            .thenAnswer((_) async => 'available');

        final result = await permissionService.isSdkAvailable();

        expect(result, CKSdkStatus.available);
        verify(() => mockHostApi.isSdkAvailable()).called(1);
      });

      test('returns unavailable status when platform returns unavailable',
          () async {
        when(() => mockHostApi.isSdkAvailable())
            .thenAnswer((_) async => 'unavailable');

        final result = await permissionService.isSdkAvailable();

        expect(result, CKSdkStatus.unavailable);
      });

      test('returns updateRequired status when platform returns updateRequired',
          () async {
        when(() => mockHostApi.isSdkAvailable())
            .thenAnswer((_) async => 'updateRequired');

        final result = await permissionService.isSdkAvailable();

        expect(result, CKSdkStatus.updateRequired);
      });

      test('throws exception when platform call fails', () async {
        when(() => mockHostApi.isSdkAvailable())
            .thenThrow(PlatformException(code: 'ERROR'));

        expect(
          () => permissionService.isSdkAvailable(),
          throwsA(isA<ConnectKitException>()),
        );

        // TODO: check the original exception was PlatformException
      });
    });

    group('requestPermissions', () {
      test('requests permissions with simple types', () async {
        when(() => mockHostApi.requestPermissions(any(), any(), any(), any()))
            .thenAnswer((_) async => true);

        final result = await permissionService.requestPermissions(
          readTypes: {CKType.steps, CKType.height},
          writeTypes: {CKType.weight},
        );

        expect(result, isTrue);

        final captured = verify(() => mockHostApi.requestPermissions(
              captureAny(),
              captureAny(),
              captureAny(),
              captureAny(),
            )).captured;

        final readTypes = captured[0] as List<String>?;
        final writeTypes = captured[1] as List<String>?;

        expect(readTypes, contains('steps'));
        expect(readTypes, contains('height'));
        expect(writeTypes, contains('weight'));
      });

      test('expands composite types before requesting', () async {
        when(() => mockHostApi.requestPermissions(any(), any(), any(), any()))
            .thenAnswer((_) async => true);

        await permissionService.requestPermissions(
          readTypes: {CKType.bloodPressure},
          writeTypes: {},
        );

        final captured = verify(() => mockHostApi.requestPermissions(
              captureAny(),
              captureAny(),
              captureAny(),
              captureAny(),
            )).captured;

        final readTypes = captured[0] as List<String>?;

        // bloodPressure should be expanded to components
        expect(readTypes, contains('bloodPressure.systolic'));
        expect(readTypes, contains('bloodPressure.diastolic'));
        expect(readTypes, isNot(contains('bloodPressure')));
      });

      test('passes history and background flags correctly', () async {
        when(() => mockHostApi.requestPermissions(any(), any(), any(), any()))
            .thenAnswer((_) async => true);

        await permissionService.requestPermissions(
          readTypes: {CKType.steps},
          writeTypes: {},
          forHistory: true,
          forBackground: true,
        );

        final captured = verify(() => mockHostApi.requestPermissions(
              captureAny(),
              captureAny(),
              captureAny(),
              captureAny(),
            )).captured;

        expect(captured[2], isTrue); // forHistory
        expect(captured[3], isTrue); // forBackground
      });

      test('handles null read and write types', () async {
        when(() => mockHostApi.requestPermissions(any(), any(), any(), any()))
            .thenAnswer((_) async => true);

        final result = await permissionService.requestPermissions(
          readTypes: null,
          writeTypes: null,
        );

        expect(result, isTrue);
      });

      test('returns false when platform returns false', () async {
        when(() => mockHostApi.requestPermissions(any(), any(), any(), any()))
            .thenAnswer((_) async => false);

        final result = await permissionService.requestPermissions(
          readTypes: {CKType.steps},
          writeTypes: {},
        );

        expect(result, isFalse);
      });

      test('throws exception when platform call fails', () async {
        when(() => mockHostApi.requestPermissions(any(), any(), any(), any()))
            .thenThrow(PlatformException(code: 'ERROR'));

        expect(
          () => permissionService.requestPermissions(
            readTypes: {CKType.steps},
            writeTypes: {},
          ),
          throwsA(isA<ConnectKitException>()),
        );

        // TODO: check the original exception was PlatformException
      });
    });

    group('checkPermissions', () {
      test('returns parsed access status from platform', () async {
        final platformResponse = AccessStatusMessage(
          dataAccess: {
            'steps': {'read': 'granted', 'write': 'denied'},
            'height': {'read': 'notDetermined'},
          },
          historyAccess: 'granted',
          backgroundAccess: 'denied',
        );

        when(() => mockHostApi.checkPermissions(any(), any(), any()))
            .thenAnswer((_) async => platformResponse);

        final result = await permissionService.checkPermissions(
          forData: {
            CKType.steps: {CKAccessType.read, CKAccessType.write},
            CKType.height: {CKAccessType.read},
          },
          forHistory: true,
          forBackground: true,
        );

        expect(result.dataAccess[CKType.steps]?[CKAccessType.read],
            CKPermissionStatus.granted);
        expect(result.dataAccess[CKType.steps]?[CKAccessType.write],
            CKPermissionStatus.denied);
        expect(result.dataAccess[CKType.height]?[CKAccessType.read],
            CKPermissionStatus.notDetermined);
        expect(result.historyAccess, CKPermissionStatus.granted);
        expect(result.backgroundAccess, CKPermissionStatus.denied);
      });

      test('expands composite types before checking', () async {
        final platformResponse = AccessStatusMessage(
          dataAccess: {
            'bloodPressure.systolic': {'read': 'granted'},
            'bloodPressure.diastolic': {'read': 'granted'},
          },
        );

        when(() => mockHostApi.checkPermissions(any(), any(), any()))
            .thenAnswer((_) async => platformResponse);

        await permissionService.checkPermissions(
          forData: {
            CKType.bloodPressure: {CKAccessType.read},
          },
        );

        final captured = verify(() => mockHostApi.checkPermissions(
              captureAny(),
              captureAny(),
              captureAny(),
            )).captured;

        final forDataMap = captured[0] as Map<String, List<String>>?;

        expect(forDataMap?['bloodPressure.systolic'], contains('read'));
        expect(forDataMap?['bloodPressure.diastolic'], contains('read'));
        expect(forDataMap, isNot(contains('bloodPressure')));
      });

      test('handles null forData parameter', () async {
        final platformResponse = AccessStatusMessage(
          dataAccess: {},
          historyAccess: 'granted',
        );

        when(() => mockHostApi.checkPermissions(any(), any(), any()))
            .thenAnswer((_) async => platformResponse);

        final result = await permissionService.checkPermissions(
          forData: null,
          forHistory: true,
        );

        expect(result.dataAccess, isEmpty);
        expect(result.historyAccess, CKPermissionStatus.granted);
      });

      test('handles empty response from platform', () async {
        final platformResponse = AccessStatusMessage(
          dataAccess: {},
        );

        when(() => mockHostApi.checkPermissions(any(), any(), any()))
            .thenAnswer((_) async => platformResponse);

        final result = await permissionService.checkPermissions(
          forData: {
            CKType.steps: {CKAccessType.read}
          },
        );

        expect(result.dataAccess, isEmpty);
        expect(result.historyAccess, CKPermissionStatus.unknown);
        expect(result.backgroundAccess, CKPermissionStatus.unknown);
      });

      test('handles notSupported status correctly', () async {
        final platformResponse = AccessStatusMessage(
          dataAccess: {
            'steps': {'write': 'notSupported'},
          },
        );

        when(() => mockHostApi.checkPermissions(any(), any(), any()))
            .thenAnswer((_) async => platformResponse);

        final result = await permissionService.checkPermissions(
          forData: {
            CKType.steps: {CKAccessType.write}
          },
        );

        expect(result.dataAccess[CKType.steps]?[CKAccessType.write],
            CKPermissionStatus.notSupported);
      });

      test('throws exception when platform call fails', () async {
        when(() => mockHostApi.checkPermissions(any(), any(), any()))
            .thenThrow(PlatformException(code: 'ERROR'));

        expect(
          () => permissionService.checkPermissions(
            forData: {
              CKType.steps: {CKAccessType.read}
            },
          ),
          throwsA(isA<ConnectKitException>()),
        );

        // TODO: check the original exception was PlatformException
      });

      test('passes flags correctly to platform', () async {
        final platformResponse = AccessStatusMessage(dataAccess: {});

        when(() => mockHostApi.checkPermissions(any(), any(), any()))
            .thenAnswer((_) async => platformResponse);

        await permissionService.checkPermissions(
          forData: {},
          forHistory: true,
          forBackground: false,
        );

        final captured = verify(() => mockHostApi.checkPermissions(
              captureAny(),
              captureAny(),
              captureAny(),
            )).captured;

        expect(captured[1], isTrue); // forHistory
        expect(captured[2], isFalse); // forBackground
      });
    });

    group('revokePermissions', () {
      test('returns true when platform succeeds', () async {
        when(() => mockHostApi.revokePermissions())
            .thenAnswer((_) async => true);

        final result = await permissionService.revokePermissions();

        expect(result, isTrue);
        verify(() => mockHostApi.revokePermissions()).called(1);
      });

      test('returns false when platform fails', () async {
        when(() => mockHostApi.revokePermissions())
            .thenAnswer((_) async => false);

        final result = await permissionService.revokePermissions();

        expect(result, isFalse);
      });

      test('throws exception when platform call fails', () async {
        when(() => mockHostApi.revokePermissions())
            .thenThrow(PlatformException(code: 'NOT_SUPPORTED'));

        expect(
          () => permissionService.revokePermissions(),
          throwsA(isA<ConnectKitException>()),
        );

        // TODO: check the original exception was PlatformException
      });
    });

    group('openHealthSettings', () {
      test('returns true when platform succeeds', () async {
        when(() => mockHostApi.openHealthSettings())
            .thenAnswer((_) async => true);

        final result = await permissionService.openHealthSettings();

        expect(result, isTrue);
        verify(() => mockHostApi.openHealthSettings()).called(1);
      });

      test('returns false when platform fails', () async {
        when(() => mockHostApi.openHealthSettings())
            .thenAnswer((_) async => false);

        final result = await permissionService.openHealthSettings();

        expect(result, isFalse);
      });

      test('throws exception when platform call fails', () async {
        when(() => mockHostApi.openHealthSettings())
            .thenThrow(PlatformException(code: 'ERROR'));

        expect(
          () => permissionService.openHealthSettings(),
          throwsA(isA<ConnectKitException>()),
        );

        // TODO: check the original exception was PlatformException
      });
    });

    group('integration scenarios', () {
      test('handles complete permission flow', () async {
        // Check SDK available
        when(() => mockHostApi.isSdkAvailable())
            .thenAnswer((_) async => 'available');

        final sdkStatus = await permissionService.isSdkAvailable();
        expect(sdkStatus, CKSdkStatus.available);

        // Request permissions
        when(() => mockHostApi.requestPermissions(any(), any(), any(), any()))
            .thenAnswer((_) async => true);

        final requested = await permissionService.requestPermissions(
          readTypes: {CKType.steps, CKType.bloodPressure},
          writeTypes: {CKType.weight},
        );
        expect(requested, isTrue);

        // Check permissions
        final platformResponse = AccessStatusMessage(
          dataAccess: {
            'steps': {'read': 'granted'},
            'bloodPressure.systolic': {'read': 'granted'},
            'bloodPressure.diastolic': {'read': 'granted'},
            'weight': {'write': 'granted'},
          },
        );

        when(() => mockHostApi.checkPermissions(any(), any(), any()))
            .thenAnswer((_) async => platformResponse);

        final status = await permissionService.checkPermissions(
          forData: {
            CKType.steps: {CKAccessType.read},
            CKType.bloodPressure: {CKAccessType.read},
            CKType.weight: {CKAccessType.write},
          },
        );

        expect(status.hasReadAccess(CKType.steps), isTrue);
        expect(status.hasReadAccess(CKType.bloodPressure.systolic), isTrue);
        expect(status.hasReadAccess(CKType.bloodPressure.diastolic), isTrue);
        expect(status.hasWriteAccess(CKType.weight), isTrue);
      });

      test('handles permission denial scenario', () async {
        // Request returns true (dialog shown)
        when(() => mockHostApi.requestPermissions(any(), any(), any(), any()))
            .thenAnswer((_) async => true);

        await permissionService.requestPermissions(
          readTypes: {CKType.steps},
          writeTypes: {},
        );

        // But check shows denied
        final platformResponse = AccessStatusMessage(
          dataAccess: {
            'steps': {'read': 'denied'},
          },
        );

        when(() => mockHostApi.checkPermissions(any(), any(), any()))
            .thenAnswer((_) async => platformResponse);

        final status = await permissionService.checkPermissions(
          forData: {
            CKType.steps: {CKAccessType.read}
          },
        );

        expect(status.hasReadAccess(CKType.steps), isFalse);
        expect(status.dataAccess[CKType.steps]?[CKAccessType.read],
            CKPermissionStatus.denied);
      });

      test('handles unsupported type scenario', () async {
        final platformResponse = AccessStatusMessage(
          dataAccess: {
            'steps': {'read': 'granted'},
            'dateOfBirth': {'write': 'notSupported'}, // Read-only type
          },
        );

        when(() => mockHostApi.checkPermissions(any(), any(), any()))
            .thenAnswer((_) async => platformResponse);

        final status = await permissionService.checkPermissions(
          forData: {
            CKType.steps: {CKAccessType.read},
            CKType.dateOfBirth: {CKAccessType.write},
          },
        );

        expect(status.hasReadAccess(CKType.steps), isTrue);
        expect(status.dataAccess[CKType.dateOfBirth]?[CKAccessType.write],
            CKPermissionStatus.notSupported);
      });
    });
  });
}
