import 'package:connect_kit/src/models/schema/ck_type.dart';

void main() {
  print('=== Testing CKType Hierarchical API ===');

  // Test simple types
  print('Simple types:');
  print('  CKType.height: ${CKType.height}');
  print('  CKType.weight: ${CKType.weight}');
  print('  CKType.steps: ${CKType.steps}');

  // Test composite parent types
  print('\nComposite parent types:');
  print('  CKType.workout: ${CKType.workout}');
  print('  CKType.nutrition: ${CKType.nutrition}');
  print('  CKType.bloodPressure: ${CKType.bloodPressure}');

  // Test component types (this should work!)
  print('\nComponent types:');
  print('  CKType.workout.distance: ${CKType.workout.distance}');
  print('  CKType.nutrition.energy: ${CKType.nutrition.energy}');
  print('  CKType.bloodPressure.systolic: ${CKType.bloodPressure.systolic}');

  // Test string representations
  print('\nString representations:');
  print('  CKType.height.toString(): ${CKType.height.toString()}');
  print(
      '  CKType.workout.distance.toString(): ${CKType.workout.distance.toString()}');

  // Test new fromString methods
  print('\nfromString methods:');
  print('  CKType.fromString("height"): ${CKType.fromString("height")}');
  print('  CKType.fromString("workout"): ${CKType.fromString("workout")}');
  print(
      '  CKType.fromString("workout.distance"): ${CKType.fromString("workout.distance")}');
  print(
      '  CKType.fromString("nutrition.energy"): ${CKType.fromString("nutrition.energy")}');

  // Test safe fromString method
  print('\nSafe fromString methods:');
  print(
      '  CKType.fromStringOrNull("height"): ${CKType.fromStringOrNull("height")}');
  print(
      '  CKType.fromStringOrNull("invalid_type"): ${CKType.fromStringOrNull("invalid_type")}');
  print('  CKType.fromStringOrNull(""): ${CKType.fromStringOrNull("")}');

  // Test validation method
  print('\nValidation method:');
  print('  CKType.isValid("height"): ${CKType.isValid("height")}');
  print('  CKType.isValid("invalid_type"): ${CKType.isValid("invalid_type")}');
  print('  CKType.isValid(""): ${CKType.isValid("")}');

  // Test error cases (should throw)
  print('\nError cases:');
  try {
    CKType.fromString("invalid_type");
  } catch (e) {
    print('  Invalid type error: ${e.toString().substring(0, 80)}...');
  }

  try {
    CKType.fromString("");
  } catch (e) {
    print('  Empty string error: ${e.toString()}');
  }

  // Test if they work the same as the direct accessors
  print('\nComparison with direct access:');
  final directWorkoutDistance = CKType.workout.distance;
  final fromStringWorkoutDistance = CKType.fromString("workout.distance");
  print(
      '  Direct: ${directWorkoutDistance} (${directWorkoutDistance.runtimeType})');
  print(
      '  fromString: ${fromStringWorkoutDistance} (${fromStringWorkoutDistance.runtimeType})');
  print(
      '  Are they equal? ${directWorkoutDistance == fromStringWorkoutDistance}');

  // Test introspection methods
  print('\nIntrospection methods:');
  print('  Total types: ${CKType.allTypes.length}');
  print('  Type names count: ${CKType.allTypeNames.length}');
  print('  First 5 types: ${CKType.allTypeNames.take(5).join(", ")}');
  print(
      '  Contains workout.distance: ${CKType.allTypeNames.contains("workout.distance")}');

  // Test displayName
  print('\nDisplay names:');
  print('  CKType.height.displayName: ${CKType.height.displayName}');
  print(
      '  CKType.workout.distance.displayName: ${CKType.workout.distance.displayName}');

  // Test default components
  print('\nDefault components:');
  print(
      '  CKType.workout.defaultComponents: ${CKType.workout.defaultComponents}');
  print(
      '  CKType.nutrition.defaultComponents: ${CKType.nutrition.defaultComponents}');
  print(
      '  CKType.bloodPressure.defaultComponents: ${CKType.bloodPressure.defaultComponents}');
}
