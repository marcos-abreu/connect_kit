# Pigeon Nested Map Serialization Issue

## Problem Summary

Pigeon has a fundamental limitation with nested `Map<String, Map<String, String>>` data structures that causes type casting failures during deserialization.

## Root Cause

When defining a Pigeon message class with nested maps:

```dart
class AccessStatusMessage {
  Map<String, Map<String, String>>? dataAccess;  // ❌ This causes issues
  String? historyAccess;
  String? backgroundAccess;
}
```

Pigeon generates a decode method with problematic casting:

```dart
static AccessStatusMessage decode(Object result) {
  result as List<Object?>;
  return AccessStatusMessage(
    dataAccess: (result[0] as Map<Object?, Object?>?)?.cast<String, Map<String, String>>(), // ❌ Fails here
    historyAccess: result[1] as String?,
    backgroundAccess: result[2] as String?,
  );
}
```

**The Issue**: The `.cast<String, Map<String, String>>()` method creates a `CastMap` that fails when accessed because it cannot properly cast the nested `Map<Object?, Object?>` to `Map<String, String>`.

## Error Message

```
type '_Map<Object?, Object?>' is not a subtype of type 'Map<String, String>' in type cast
```

## Solutions Attempted

### ❌ Attempt 1: Nullable Types
Changing to `Map<String?, Map<String?, String?>?>?` did not resolve the core casting issue in the generated decode method.

### ❌ Attempt 2: Custom Decode Method
Pigeon does not allow custom methods in message classes:
```
Error: pigeon/messages.dart:52: Methods aren't supported in Pigeon data classes ("decode").
```

### ❌ Attempt 3: Flattened Map Structure
Using `Map<String, String>` with serialized values like `"height": "read: denied, write: granted"` works but requires complex serialization/deserialization logic.

### ✅ Working Solution: Using `Object` Type

**Pigeon Schema**:
```dart
class AccessStatusMessage {
  Map<String, Object>? dataAccess;  // ✅ Works with Object type
  String? historyAccess;
  String? backgroundAccess;
}
```

**Native Code** (Kotlin):
```kotlin
return AccessStatusMessage(
    historyAccess = historyAccess,
    backgroundAccess = backgroundAccess,
    dataAccess = dataAccess.mapValues { it.value.toMap() } // Returns Map<String, Map<String, String>>
)
```

**Dart Conversion**:
```dart
// Convert from Map<String, Object> to Map<String, Map<String, String>>
final converted = (response.dataAccess as Map?)?.map(
  (key, value) => MapEntry(
    key as String,
    (value as Map?)!.map(
      (k, v) => MapEntry(k as String, v as String),
    ),
  ),
);
```

## Key Learnings

### 1. Pigeon Type System Limitations
- Pigeon cannot properly handle nested `Map<String, Map<String, T>>` structures
- The auto-generated decode method creates problematic `CastMap` instances
- Type casting failures occur when accessing the nested map data

### 2. Object Type as Workaround
- Using `Map<String, Object>?` bypasses Pigeon's type casting limitations
- Native code can still return properly typed nested maps
- Dart side requires manual type casting/conversion

### 3. Debugging Approach
- The error manifests during deserialization, not serialization
- Native code (Android/iOS) works correctly - the issue is in Pigeon's generated code
- Systematic testing of different type structures is essential

## Best Practices for ConnectKit

### 1. Schema Design
```dart
// ✅ Use Object type for complex nested structures
class ComplexMessage {
  Map<String, Object>? complexData;
  // Simple types work fine
  String? simpleField;
  bool? anotherField;
}

// ❌ Avoid nested Maps with specific types
class ProblematicMessage {
  Map<String, Map<String, String>>? nestedMap; // Will cause casting issues
}
```

### 2. Native Implementation
- Native code can return strongly typed nested maps
- No changes needed to Android/iOS implementations
- Pigeon will handle the serialization to Object type

### 3. Dart Usage Pattern
```dart
// Safe conversion pattern for Object-typed maps
T? convertNestedMap<T>(Map<String, Object>? source) {
  if (source == null) return null;

  return source.map((key, value) {
    if (value is Map) {
      // Convert nested Map<Object?, Object?> to Map<String, String>
      final converted = value.map((k, v) => MapEntry(k as String, v as String));
      return MapEntry(key, converted);
    }
    return MapEntry(key, value);
  }) as T;
}
```

### 4. Error Handling
- Always validate and cast Object types safely
- Use try-catch blocks around type conversions
- Provide fallbacks for malformed data

## Impact on ConnectKit

This solution allows:
- ✅ Complex permission status data structures
- ✅ Cross-platform consistency (Android/iOS)
- ✅ Type safety with proper validation
- ✅ Maintainable code without workarounds in native implementations

## Future Considerations

1. **Monitor Pigeon Updates**: Watch for future Pigeon versions that might fix nested Map support
2. **Alternative Serialization**: Consider JSON serialization for very complex nested structures
3. **Custom Codec**: For extreme cases, implement custom platform channel codecs
4. **Schema Evolution**: Design schemas with Object types from the start for complex data

---

**Documented**: 2025-10-24
**Issue Discovered**: Marcos (after 4 hours of systematic debugging)
**Key Insight**: Pigeon's CastMap generation with nested Maps is the root cause