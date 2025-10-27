// test/unit/src/models/ck_access_type_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/ck_access_type.dart';

void main() {
  group('CKAccessType', () {
    test('has correct enum values', () {
      expect(CKAccessType.values, hasLength(2));
      expect(CKAccessType.values, contains(CKAccessType.read));
      expect(CKAccessType.values, contains(CKAccessType.write));
    });

    test('enum names are correct', () {
      expect(CKAccessType.read.name, 'read');
      expect(CKAccessType.write.name, 'write');
    });

    group('fromString', () {
      test('returns correct enum for valid strings', () {
        expect(CKAccessType.fromString('read'), CKAccessType.read);
        expect(CKAccessType.fromString('write'), CKAccessType.write);
      });

      test('returns default (read) for invalid strings', () {
        expect(CKAccessType.fromString('invalid'), CKAccessType.read);
        expect(CKAccessType.fromString(''), CKAccessType.read);
        expect(CKAccessType.fromString('READ'), CKAccessType.read);
      });
    });
  });
}
