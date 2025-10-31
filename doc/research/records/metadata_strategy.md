## Cross-Platform Metadata Strategy

### Problem:
Platform-specific fields (e.g., Android's `bodyPosition` for blood pressure) have no equivalent on iOS.

### Solution:
Store platform-specific data in metadata with `ck_` prefix when writing to platforms that don't natively support it.

### Benefits:
- **Round-trip consistency**: Data preserved across write/read cycles
- **Cross-platform sync**: Apps syncing between iOS/Android maintain full data
- **No data loss**: Platform-specific enrichment retained
- **Namespace safety**: `ck_` prefix prevents collisions

### Implementation:
```dart
// Writing blood pressure on iOS
// Android-specific fields stored in metadata
final bp = CKBloodPressure.mmHg(
  systolic: 120,
  diastolic: 80,
  bodyPosition: CKBodyPosition.sitting,  // → ck_bp_bodyPosition in iOS metadata
  measurementLocation: CKMeasurementLocation.leftUpperArm,  // → ck_bp_measurementLocation
);
```

### Supported Metadata Keys:
See `CKMetadataKeys` class for complete list of reserved keys.

### Important Notes:
- Apps NOT using ConnectKit for reading won't see this data
- Native platform apps see metadata but won't interpret it
- This is an optimization for ConnectKit-to-ConnectKit workflows
