# **📝 Write Records Specification**

## Overview

Enable developers to write health and fitness records to Apple HealthKit and Google Health Connect through a unified, type-safe API with comprehensive error handling and cross-platform consistency.

## I. Project Goals

1. **Unified Write Interface**: Single API for writing health records across iOS and Android platforms
2. **Robust Error Handling**: Clear feedback on validation failures and platform-specific issues
3. **Best-Effort Semantics**: Partial success scenarios where some records succeed and others fail
4. **Performance Optimized**: Batch operations with minimal platform overhead
5. **Type Safety**: Compile-time guarantees for record structure and data types

## II. Core API Methods

### Primary Write Method
```dart
Future<CKWriteResult> writeRecords(List<CKRecord> records)
```

**Purpose**: Write one or more health records to the underlying health data store with best-effort semantics

**Parameters:**
- `records`: List of health records to write (supports mixed record types)

**Returns**: `CKWriteResult` containing:
- Overall operation outcome
- Successfully persisted record IDs (Android only)
- Detailed validation failures for failed records

## III. Data Models

### CKRecord (Base Class)
```dart
abstract class CKRecord {
  final String? id;                    // Platform-assigned ID (null before saving)
  final DateTime startTime;            // Record start time
  final DateTime endTime;              // Record end time (same as startTime for instantaneous)
  final Duration startZoneOffset;      // Timezone offset at start
  final Duration endZoneOffset;        // Timezone offset at end
  final CKSource? source;              // Data source information
}
```

### CKWriteResult
```dart
class CKWriteResult {
  final WriteOutcome outcome;          // Overall operation result
  final List<String>? persistedRecordIds;  // Successfully saved record IDs
  final List<RecordFailure>? validationFailures;  // Failed record details
}
```

### WriteOutcome Enum
```dart
enum WriteOutcome {
  completeSuccess,    // All records succeeded
  partialSuccess,     // Some records succeeded, some failed
  failure,           // No records persisted
}
```

### RecordFailure
```dart
class RecordFailure {
  final List<int> indexPath;   // Path to failed record in input list
  final String message;        // Human-readable error description
  final String? type;          // Machine-readable error category
}
```

## IV. Write Process Flow

### Phase 1: Dart-Side Validation
1. **Structural Validation**: Basic record structure checks
   - `endTime` must be >= `startTime`
   - Required fields present and correctly typed
   - Timezone validation

2. **Record Encoding**: Convert records to platform-agnostic format
   - Serialize data values to primitive types
   - Map CKRecord fields to request format
   - Handle timezone conversions

3. **Error Collection**: Capture validation failures with detailed context
   - Index path for failed record location
   - Descriptive error messages
   - Error categorization for programmatic handling

### Phase 2: Platform Communication
1. **Pigeon Transport**: Type-safe cross-platform data transfer
2. **Batch Optimization**: Send valid records in single platform call
3. **Context Preservation**: Maintain record order and correlation

### Phase 3: Native Processing
1. **Platform-Specific Validation**: Native health platform validation rules
2. **Data Persistence**: Actual insertion into health data store
3. **Result Compilation**: Platform-specific success/failure tracking

### Phase 4: Result Aggregation
1. **Merge Results**: Combine Dart and native validation failures
2. **Determine Outcome**: Calculate overall operation result
3. **Return Detailed Response**: Provide comprehensive result information

## V. Platform-Specific Implementation

### iOS HealthKit Integration

**Key Characteristics:**
- **No Record IDs**: iOS doesn't return record identifiers after successful writes
- **Implicit Timezones**: HealthKit uses device timezone by default
- **Strict Validation**: Apple HealthKit has comprehensive validation rules

**Implementation Details:**
- Use `HKHealthStore.save()` for individual records
- Use `HKHealthStore.saveObjects()` for batch operations
- Map HealthKit errors to unified error format
- Handle iOS-specific data type requirements

**Error Handling:**
- Convert HealthKit error codes to descriptive messages
- Handle authorization failures gracefully
- Manage data type compatibility issues

### Android Health Connect Integration

**Key Characteristics:**
- **Record IDs Available**: Health Connect returns generated record IDs
- **Explicit Timezones**: Required timezone offset specification
- **Source Requirements**: Android requires source information with recording method

**Implementation Details:**
- Use `HealthConnectClient.insertRecords()` for batch operations
- Implement proper timezone handling
- Required source bundle and metadata
- Map Health Connect validation errors

**Error Handling:**
- Handle constraint violation errors
- Manage permission-related failures
- Address data type mapping issues

## VI. Error Handling Strategy

### Error Categories

#### 1. Dart-Side Validation Errors
- **Structural Errors**: Invalid record structure, missing required fields
- **Type Errors**: Incorrect data types for record fields
- **Value Errors**: Invalid values (e.g., negative distances)
- **Temporal Errors**: Invalid time ranges or timezone specifications

#### 2. Platform-Specific Errors
- **Authorization Errors**: Insufficient permissions for data types
- **Constraint Violations**: Platform-specific rule violations
- **Data Format Errors**: Incompatible data formats for target platform
- **System Errors**: Health platform unavailable or corrupted

#### 3. Network/System Errors
- **Service Unavailable**: Health platform not accessible
- **Timeout**: Operations exceeding time limits
- **Resource Constraints**: Insufficient system resources

### Error Response Format

```dart
// Example error response
CKWriteResult(
  outcome: WriteOutcome.partialSuccess,
  persistedRecordIds: ['record-123', 'record-456'],
  validationFailures: [
    RecordFailure(
      indexPath: [2],
      message: 'endTime must be >= startTime',
      type: 'ValidationError'
    ),
    RecordFailure(
      indexPath: [3],
      message: 'Missing required field: value',
      type: 'MissingFieldError'
    )
  ]
)
```

## VII. Supported Record Types

### Currently Implemented
- **Steps**: Step count records
- **Distance**: Distance measurements
- **Active Energy**: Active calories burned
- **Heart Rate**: Heart rate measurements
- **Weight**: Body weight measurements
- **Height**: Body height measurements

### Record Type Structure
Each record type extends `CKRecord` with specific fields:

```dart
class StepsRecord extends CKRecord {
  final int count;                    // Number of steps

  StepsRecord({
    required DateTime startTime,
    required DateTime endTime,
    required this.count,
    // ... inherited CKRecord fields
  });
}
```

## VIII. Testing Strategy

### Unit Tests
- **Record Validation**: Test all validation rules and error conditions
- **Data Mapping**: Verify correct serialization/deserialization
- **Error Aggregation**: Test merging of Dart and native failures
- **Edge Cases**: Boundary conditions and special scenarios

### Integration Tests
- **Platform Channel Communication**: Verify Pigeon message handling
- **Cross-Platform Consistency**: Ensure equivalent behavior
- **Batch Operations**: Test mixed record type batches
- **Error Propagation**: Verify error transmission through layers

### Manual Testing (Physical Devices Required)
- **iOS HealthKit**: Permission scenarios and data validation
- **Android Health Connect**: Source requirements and timezone handling
- **Performance Testing**: Batch operation timing and memory usage
- **Error Scenarios**: Network failures, permission issues, invalid data

### Critical Test Scenarios
- Mixed success/failure batch operations
- Timezone handling across different regions
- Source information requirements (Android)
- Large batch operations (100+ records)
- Concurrent write operations
- Permission revoked during operation

## IX. Implementation Progress

### ✅ Phase 1: Core Framework
- [x] Base `CKRecord` abstract class
- [x] `CKWriteResult` and supporting models
- [x] Write service foundation with `OperationGuard`
- [x] Error handling framework

### ✅ Phase 2: Dart Implementation
- [x] `WriteService` with validation logic
- [x] Record mapping infrastructure
- [x] Public API integration in main `ConnectKit` class
- [x] Comprehensive error handling

### 🔄 Phase 3: Native Platform Implementation
- [x] Android write service implementation (in progress)
- [ ] iOS write service implementation
- [ ] Platform-specific validation rules
- [ ] Error translation and mapping

### 📋 Phase 4: Testing and Validation
- [ ] Unit test suite completion
- [ ] Integration test scenarios
- [ ] Physical device testing
- [ ] Performance optimization
- [ ] Error scenario validation

## X. Usage Examples

### Basic Record Writing
```dart
// Create step record
final stepsRecord = StepsRecord(
  startTime: DateTime.now().subtract(Duration(hours: 1)),
  endTime: DateTime.now(),
  count: 1500,
  source: CKSource(
    name: 'My Fitness App',
    bundleId: 'com.example.fitness',
  ),
);

// Write single record
final result = await connectKit.writeRecords([stepsRecord]);

switch (result.outcome) {
  case WriteOutcome.completeSuccess:
    print('Record saved successfully');
    break;
  case WriteOutcome.partialSuccess:
    print('Some records failed: ${result.validationFailures}');
    break;
  case WriteOutcome.failure:
    print('All records failed: ${result.validationFailures}');
    break;
}
```

### Batch Mixed Record Types
```dart
final records = [
  StepsRecord(
    startTime: DateTime.now().subtract(Duration(hours: 2)),
    endTime: DateTime.now(),
    count: 3500,
  ),
  HeartRateRecord(
    startTime: DateTime.now().subtract(Duration(minutes: 5)),
    value: 72,
    unit: HeartRateUnit.bpm,
  ),
  WeightRecord(
    startTime: DateTime.now(),
    value: 70.5,
    unit: WeightUnit.kilograms,
  ),
];

final result = await connectKit.writeRecords(records);
print('Persisted ${result.persistedRecordIds?.length ?? 0} records');
```

### Error Handling
```dart
final result = await connectKit.writeRecords(records);

if (result.hasValidationFailures) {
  for (final failure in result.validationFailures!) {
    print('Record at ${failure.indexPath} failed: ${failure.message}');
    if (failure.type == 'ValidationError') {
      // Handle validation errors specifically
    }
  }
}

if (result.outcome == WriteOutcome.failure) {
  // All records failed - check for common issues
  final hasPermissionErrors = result.validationFailures
      ?.any((f) => f.message.contains('permission')) ?? false;

  if (hasPermissionErrors) {
    await connectKit.openHealthSettings();
  }
}
```

## XI. Performance Considerations

### Optimization Strategies
1. **Batch Operations**: Group multiple records in single platform calls
2. **Validation Optimization**: Fast-fail validation to minimize platform overhead
3. **Memory Management**: Efficient data structures for large record sets
4. **Parallel Processing**: Concurrent validation where possible

### Performance Targets
- **Single Record**: < 100ms (including validation)
- **Batch Records**: < 50ms per record (amortized)
- **Memory Usage**: < 10MB for 1000 records
- **Validation Time**: < 1ms per record

## XII. Success Criteria

- [ ] Successfully write all supported record types on both platforms
- [ ] Handle mixed success/failure scenarios with detailed feedback
- [ ] Maintain cross-platform API consistency
- [ ] Provide comprehensive error reporting with actionable messages
- [ ] Support efficient batch operations
- [ ] Handle platform-specific requirements (Android sources, iOS timezones)
- [ ] Achieve performance targets for common use cases
- [ ] Pass comprehensive unit and integration test suites
- [ ] Validate on physical devices for both iOS and Android
- [ ] Provide clear documentation and usage examples

---

**Document Status**: 🔄 **IN IMPLEMENTATION**
**Target Release**: v0.4.0
**Dependencies**: Native platform implementation, comprehensive testing, physical device validation
**Last Updated**: 2025-11-09