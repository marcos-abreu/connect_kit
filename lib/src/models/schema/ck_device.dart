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

  /// Device constructor
  /// parameters:
  /// - manufacturer: Device manufacturer (e.g., "Apple", "Google", "Fitbit")
  /// - model: Device model (e.g., "iPhone 14 Pro", "Pixel Watch")
  /// - type: Device type category (e.g., "phone", "watch", "scale")
  /// - hardwareVersion: Hardware version (iOS only - ignored on Android)
  /// - softwareVersion: Software/firmware version (iOS only - ignored on Android)
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
  /// Unknown or unrecognized device type
  unknown,

  /// Smartphone or tablet device
  phone,

  /// Smartwatch or fitness tracker (but not fitness band)
  watch,

  /// Digital weight scale
  scale,

  /// Smart ring device
  ring,

  /// Heart rate monitoring chest strap
  chestStrap,

  /// Fitness band or activity tracker
  fitnessBand,

  /// Head-mounted display or headphones
  headMounted,
}
