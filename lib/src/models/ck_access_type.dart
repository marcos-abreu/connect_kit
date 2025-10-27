import 'package:connect_kit/src/utils/enum_helper.dart';

/// TODO: Add documentation
enum CKAccessType {
  /// TODO: Add documentation
  read,

  /// TODO: Add documentation
  write;

  /// You can also use a static method.
  static CKAccessType fromString(String accessString) {
    return enumFromStringOrDefault(
      CKAccessType.values,
      accessString,
      CKAccessType.read, // Use a different specific default
    );
  }
}
