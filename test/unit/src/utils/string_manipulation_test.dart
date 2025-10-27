// test/unit/src/utils/string_manipulation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/utils/string_manipulation.dart';

void main() {
  group('camelCaseToTitleCase', () {
    test('converts simple camelCase to Title Case', () {
      expect(
          camelCaseToTitleCase('basalMetabolicRate'), 'Basal Metabolic Rate');
    });

    test('handles single word', () {
      expect(camelCaseToTitleCase('height'), 'Height');
    });

    test('handles already lowercase single word', () {
      expect(camelCaseToTitleCase('steps'), 'Steps');
    });

    test('handles string starting with capital', () {
      expect(camelCaseToTitleCase('BloodPressure'), 'Blood Pressure');
    });

    test('handles empty string', () {
      expect(camelCaseToTitleCase(''), '');
    });

    test('preserves spacing for real-world health types', () {
      expect(camelCaseToTitleCase('bodyMassIndex'), 'Body Mass Index');
      expect(camelCaseToTitleCase('heartRate'), 'Heart Rate');
      expect(camelCaseToTitleCase('bloodGlucose'), 'Blood Glucose');
    });
  });

  group('capitalizeWord', () {
    test('capitalizes first letter of lowercase word', () {
      expect(capitalizeWord('hello'), 'Hello');
    });

    test('converts rest of word to lowercase', () {
      expect(capitalizeWord('HELLO'), 'Hello');
      expect(capitalizeWord('HeLLo'), 'Hello');
    });

    test('handles single character', () {
      expect(capitalizeWord('a'), 'A');
    });

    test('handles empty string', () {
      expect(capitalizeWord(''), '');
    });

    test('handles already capitalized word', () {
      expect(capitalizeWord('World'), 'World');
    });

    test('handles word with numbers', () {
      expect(capitalizeWord('test123'), 'Test123');
    });
  });
}
