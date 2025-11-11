/// Device information for data provenance
class CKDevice {
  /// Device manufacturer (e.g., "Apple", "Google", "Fitbit")
  final String? manufacturer;

  /// Device model (e.g., "iPhone 14 Pro", "Pixel Watch")
  final String? model;

  /// Device type category
  final CKDeviceType type;

  /// Hardware version (iOS only - ignored on Android)
  final String? hardwareVersion;

  /// Software/firmware version (iOS only - ignored on Android)
  final String? softwareVersion;

  /// TODO: add documentation
  const CKDevice({
    this.manufacturer,
    this.model,
    required this.type,
    this.hardwareVersion,
    this.softwareVersion,
  });

  /// Create device representing current phone
  factory CKDevice.phone({
    String? manufacturer,
    String? model,
  }) =>
      CKDevice(
        manufacturer: manufacturer,
        model: model,
        type: CKDeviceType.phone,
      );

  /// Create device representing a wearable
  factory CKDevice.watch({
    String? manufacturer,
    String? model,
  }) =>
      CKDevice(
        manufacturer: manufacturer,
        model: model,
        type: CKDeviceType.watch,
      );

  /// Create device representing a scale
  factory CKDevice.scale({
    String? manufacturer,
    String? model,
  }) =>
      CKDevice(
        manufacturer: manufacturer,
        model: model,
        type: CKDeviceType.scale,
      );
}

/// Device type categories
enum CKDeviceType {
  /// TODO: add documentation
  unknown,

  /// TODO: add documentation
  phone,

  /// TODO: add documentation
  watch,

  /// TODO: add documentation
  scale,

  /// TODO: add documentation
  ring,

  /// TODO: add documentation
  chestStrap,

  /// TODO: add documentation
  fitnessBand,

  /// TODO: add documentation
  headMounted,
}
