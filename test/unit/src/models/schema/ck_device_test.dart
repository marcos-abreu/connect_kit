import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/schema/ck_device.dart';

void main() {
  group('CKDevice', () {
    group('Constructor', () {
      test('creates device with minimum required parameters', () {
        final device = CKDevice(
          type: CKDeviceType.phone,
        );

        expect(device.type, equals(CKDeviceType.phone));
        expect(device.manufacturer, isNull);
        expect(device.model, isNull);
        expect(device.hardwareVersion, isNull);
        expect(device.softwareVersion, isNull);
      });

      test('creates device with all parameters', () {
        final device = CKDevice(
          manufacturer: 'Apple',
          model: 'iPhone 14 Pro',
          type: CKDeviceType.watch,
          hardwareVersion: '9.0',
          softwareVersion: '17.1',
        );

        expect(device.manufacturer, equals('Apple'));
        expect(device.model, equals('iPhone 14 Pro'));
        expect(device.type, equals(CKDeviceType.watch));
        expect(device.hardwareVersion, equals('9.0'));
        expect(device.softwareVersion, equals('17.1'));
      });

      test('creates device with partial parameters', () {
        final device = CKDevice(
          manufacturer: 'Samsung',
          type: CKDeviceType.phone,
          softwareVersion: '14.0',
        );

        expect(device.manufacturer, equals('Samsung'));
        expect(device.model, isNull);
        expect(device.type, equals(CKDeviceType.phone));
        expect(device.hardwareVersion, isNull);
        expect(device.softwareVersion, equals('14.0'));
      });
    });

    group('Factory methods', () {
      test('phone factory creates device with phone type', () {
        final device = CKDevice.phone(
          manufacturer: 'Google',
          model: 'Pixel 7',
        );

        expect(device.type, equals(CKDeviceType.phone));
        expect(device.manufacturer, equals('Google'));
        expect(device.model, equals('Pixel 7'));
        expect(device.hardwareVersion, isNull);
        expect(device.softwareVersion, isNull);
      });

      test('phone factory works with minimal parameters', () {
        final device = CKDevice.phone();

        expect(device.type, equals(CKDeviceType.phone));
        expect(device.manufacturer, isNull);
        expect(device.model, isNull);
        expect(device.hardwareVersion, isNull);
        expect(device.softwareVersion, isNull);
      });

      test('phone factory works with only manufacturer', () {
        final device = CKDevice.phone(
          manufacturer: 'OnePlus',
        );

        expect(device.type, equals(CKDeviceType.phone));
        expect(device.manufacturer, equals('OnePlus'));
        expect(device.model, isNull);
      });

      test('phone factory works with only model', () {
        final device = CKDevice.phone(
          model: 'Galaxy S23',
        );

        expect(device.type, equals(CKDeviceType.phone));
        expect(device.manufacturer, isNull);
        expect(device.model, equals('Galaxy S23'));
      });

      test('watch factory creates device with watch type', () {
        final device = CKDevice.watch(
          manufacturer: 'Apple',
          model: 'Apple Watch Series 8',
        );

        expect(device.type, equals(CKDeviceType.watch));
        expect(device.manufacturer, equals('Apple'));
        expect(device.model, equals('Apple Watch Series 8'));
        expect(device.hardwareVersion, isNull);
        expect(device.softwareVersion, isNull);
      });

      test('watch factory works with minimal parameters', () {
        final device = CKDevice.watch();

        expect(device.type, equals(CKDeviceType.watch));
        expect(device.manufacturer, isNull);
        expect(device.model, isNull);
        expect(device.hardwareVersion, isNull);
        expect(device.softwareVersion, isNull);
      });

      test('watch factory works with only manufacturer', () {
        final device = CKDevice.watch(
          manufacturer: 'Fitbit',
        );

        expect(device.type, equals(CKDeviceType.watch));
        expect(device.manufacturer, equals('Fitbit'));
        expect(device.model, isNull);
      });

      test('watch factory works with only model', () {
        final device = CKDevice.watch(
          model: 'Versa 3',
        );

        expect(device.type, equals(CKDeviceType.watch));
        expect(device.manufacturer, isNull);
        expect(device.model, equals('Versa 3'));
      });

      test('scale factory creates device with scale type', () {
        final device = CKDevice.scale(
          manufacturer: 'Withings',
          model: 'Body+',
        );

        expect(device.type, equals(CKDeviceType.scale));
        expect(device.manufacturer, equals('Withings'));
        expect(device.model, equals('Body+'));
        expect(device.hardwareVersion, isNull);
        expect(device.softwareVersion, isNull);
      });

      test('scale factory works with minimal parameters', () {
        final device = CKDevice.scale();

        expect(device.type, equals(CKDeviceType.scale));
        expect(device.manufacturer, isNull);
        expect(device.model, isNull);
        expect(device.hardwareVersion, isNull);
        expect(device.softwareVersion, isNull);
      });

      test('scale factory works with only manufacturer', () {
        final device = CKDevice.scale(
          manufacturer: 'Tanita',
        );

        expect(device.type, equals(CKDeviceType.scale));
        expect(device.manufacturer, equals('Tanita'));
        expect(device.model, isNull);
      });

      test('scale factory works with only model', () {
        final device = CKDevice.scale(
          model: 'Smart Scale P2',
        );

        expect(device.type, equals(CKDeviceType.scale));
        expect(device.manufacturer, isNull);
        expect(device.model, equals('Smart Scale P2'));
      });
    });

    group('Integration tests', () {
      test('creates comprehensive devices for different platforms', () {
        final phoneDevice = CKDevice(
          manufacturer: 'Apple',
          model: 'iPhone 15 Pro Max',
          type: CKDeviceType.phone,
          hardwareVersion: '8.1',
          softwareVersion: '17.2',
        );

        final watchDevice = CKDevice.watch(
          manufacturer: 'Garmin',
          model: 'Forerunner 965',
        );

        final scaleDevice = CKDevice.scale(
          manufacturer: 'Fitbit',
          model: 'Aria Air',
        );

        // Verify phone device
        expect(phoneDevice.type, equals(CKDeviceType.phone));
        expect(phoneDevice.manufacturer, equals('Apple'));
        expect(phoneDevice.model, equals('iPhone 15 Pro Max'));

        // Verify watch device
        expect(watchDevice.type, equals(CKDeviceType.watch));
        expect(watchDevice.manufacturer, equals('Garmin'));
        expect(watchDevice.model, equals('Forerunner 965'));

        // Verify scale device
        expect(scaleDevice.type, equals(CKDeviceType.scale));
        expect(scaleDevice.manufacturer, equals('Fitbit'));
        expect(scaleDevice.model, equals('Aria Air'));
      });

      test('handles edge cases with empty strings', () {
        final device1 = CKDevice(
          manufacturer: '',
          model: '',
          type: CKDeviceType.phone,
        );

        final device2 = CKDevice.phone(
          manufacturer: '',
          model: '',
        );

        expect(device1.manufacturer, equals(''));
        expect(device1.model, equals(''));
        expect(device2.manufacturer, equals(''));
        expect(device2.model, equals(''));
      });

      test('handles devices with very long names', () {
        final veryLongManufacturer = 'A Very Long Manufacturer Name That Exceeds Normal Limits And Contains Many Characters To Test String Handling Capabilities';
        final veryLongModel = 'A Very Long Model Name That Exceeds Normal Limits And Contains Many Characters To Test String Handling Capabilities In The System';

        final device = CKDevice(
          manufacturer: veryLongManufacturer,
          model: veryLongModel,
          type: CKDeviceType.phone,
        );

        expect(device.manufacturer, equals(veryLongManufacturer));
        expect(device.model, equals(veryLongModel));
        expect(device.type, equals(CKDeviceType.phone));
      });

      test('creates devices for Android ecosystem', () {
        final samsungPhone = CKDevice.phone(
          manufacturer: 'Samsung',
          model: 'Galaxy S24 Ultra',
        );

        final pixelWatch = CKDevice.watch(
          manufacturer: 'Google',
          model: 'Pixel Watch 2',
        );

        expect(samsungPhone.manufacturer, equals('Samsung'));
        expect(samsungPhone.model, equals('Galaxy S24 Ultra'));
        expect(samsungPhone.type, equals(CKDeviceType.phone));

        expect(pixelWatch.manufacturer, equals('Google'));
        expect(pixelWatch.model, equals('Pixel Watch 2'));
        expect(pixelWatch.type, equals(CKDeviceType.watch));
      });

      test('creates devices for fitness wearables', () {
        final fitbitWatch = CKDevice.watch(
          manufacturer: 'Fitbit',
          model: 'Charge 6',
        );

        final garminWatch = CKDevice.watch(
          manufacturer: 'Garmin',
          model: 'Fenix 7X Solar',
        );

        final whoopBand = CKDevice(
          manufacturer: 'WHOOP',
          model: 'WHOOP Band',
          type: CKDeviceType.fitnessBand,
        );

        final ouraRing = CKDevice(
          manufacturer: 'Oura',
          model: 'Oura Ring 3',
          type: CKDeviceType.ring,
        );

        expect(fitbitWatch.type, equals(CKDeviceType.watch));
        expect(garminWatch.type, equals(CKDeviceType.watch));
        expect(whoopBand.type, equals(CKDeviceType.fitnessBand));
        expect(ouraRing.type, equals(CKDeviceType.ring));
      });

      test('creates devices with complex version information', () {
        final device = CKDevice(
          manufacturer: 'Apple',
          model: 'iPhone 15 Pro',
          type: CKDeviceType.phone,
          hardwareVersion: 'A2847',
          softwareVersion: '17.1.1',
        );

        expect(device.hardwareVersion, equals('A2847'));
        expect(device.softwareVersion, equals('17.1.1'));
      });
    });
  });

  group('CKDeviceType enum', () {
    test('contains all expected device types', () {
      final deviceTypes = CKDeviceType.values;
      expect(deviceTypes, hasLength(8));
      expect(deviceTypes, contains(CKDeviceType.unknown));
      expect(deviceTypes, contains(CKDeviceType.phone));
      expect(deviceTypes, contains(CKDeviceType.watch));
      expect(deviceTypes, contains(CKDeviceType.scale));
      expect(deviceTypes, contains(CKDeviceType.ring));
      expect(deviceTypes, contains(CKDeviceType.chestStrap));
      expect(deviceTypes, contains(CKDeviceType.fitnessBand));
      expect(deviceTypes, contains(CKDeviceType.headMounted));
    });

    test('toString returns enum name', () {
      expect(CKDeviceType.phone.toString(), equals('CKDeviceType.phone'));
      expect(CKDeviceType.watch.toString(), equals('CKDeviceType.watch'));
      expect(CKDeviceType.scale.toString(), equals('CKDeviceType.scale'));
      expect(CKDeviceType.unknown.toString(), equals('CKDeviceType.unknown'));
    });

    test('can compare device types', () {
      expect(CKDeviceType.phone, equals(CKDeviceType.phone));
      expect(CKDeviceType.phone, isNot(equals(CKDeviceType.watch)));
      expect(CKDeviceType.watch, isNot(equals(CKDeviceType.scale)));
    });

    test('has same hashCode for equal device types', () {
      expect(CKDeviceType.phone.hashCode, equals(CKDeviceType.phone.hashCode));
      expect(CKDeviceType.phone.hashCode, isNot(equals(CKDeviceType.watch.hashCode)));
    });
  });
}