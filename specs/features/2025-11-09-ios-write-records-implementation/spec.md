# **🍎 iOS Write Records Implementation Specification**

## Overview

Complete the native iOS implementation for writing health records through Apple HealthKit, achieving platform parity with the existing Android Health Connect implementation and enabling full cross-platform write functionality in ConnectKit.

## I. Project Goals

1. **Platform Parity**: Match Android write capabilities on iOS with identical API behavior
2. **HealthKit Integration**: Full integration with Apple HealthKit's write operations
3. **Error Handling**: Comprehensive error mapping from HealthKit to ConnectKit error types
4. **Performance**: Efficient batch operations with proper async/await patterns
5. **Maintainability**: Follow established iOS code patterns and Swift conventions

## II. Current State Analysis

### ✅ Completed Infrastructure

**Dart Layer:**
- Cross-platform `writeRecords()` API defined
- `CKWriteResult` and error types implemented
- Pigeon schema supports write operations

**Android Implementation:**
- Complete Health Connect write functionality
- Error handling and validation
- Batch operation support

**iOS Foundation:**
- `CKHostApi.swift` platform channel entry point
- `PermissionService.swift` for HealthKit authorization
- `RecordTypeMapper.swift` for type conversions
- Basic `WriteService.swift` structure exists

### ❌ Missing Implementation

**iOS WriteService.swift:**
- Actual HealthKit write operations
- Error handling and mapping
- Batch write optimization
- Metadata and source handling

## III. Implementation Requirements

### Core Write Operations

```swift
// Primary write method to implement
func writeRecords(_ records: [CKRecordMessage]) -> CKWriteResultMessage
```

**HealthKit Integration Points:**
1. **HKHealthStore** - Primary HealthKit interface
2. **HKObject** - Base class for health objects
3. **HKObjectType** - Type-specific write operations
4. **HKSource** - Data source information
5. **HKMetadata** - Additional record metadata

### Supported Record Types

Based on existing `CKRecord` subclasses:
- **CKActiveEnergyBurned** → `HKQuantitySample` (activeEnergyBurned)
- **CKBasalEnergyBurned** → `HKQuantitySample` (basalEnergyBurned)
- **CKSteps** → `HKQuantitySample` (stepCount)
- **CKHeartRate** → `HKQuantitySample` (heartRate)
- **CKBloodPressure** → `HKCorrelation` (bloodPressure)
- **CKBodyMass** → `HKQuantitySample` (bodyMass)
- **CKHeight** → `HKQuantitySample` (height)
- **CKSleepAnalysis** → `HKCategorySample` (sleepAnalysis)

### Error Handling Requirements

**HealthKit Errors to Map:**
```swift
// HealthKit error domains and codes
HKErrorDomain.errorCodeNoAuthData
HKErrorDomain.errorCodeAuthDenied
HKErrorDomain.errorCodeAuthRestricted
HKErrorDomain.errorCodeDatabaseInaccessible
```

**ConnectKit Error Mapping:**
- Permission denied → `CKPermissionError`
- Invalid data → `CKValidationError`
- HealthKit unavailable → `CKPlatformError`
- Network/store issues → `CKWriteError`

## IV. Technical Implementation Plan

### Phase 1: Basic Write Operations

**Single Record Writing:**
```swift
private func writeSingleRecord(_ record: CKRecordMessage) -> CKWriteResultMessage {
    // 1. Validate permissions for record type
    // 2. Convert CKRecordMessage to HKObject
    // 3. Execute HealthKit save operation
    // 4. Handle errors and map to ConnectKit types
    // 5. Return appropriate result
}
```

**Record Type Mapping:**
```swift
private func mapToHKObject(_ record: CKRecordMessage) -> HKObject? {
    switch record.recordType {
    case .steps:
        return createStepCountSample(from: record)
    case .heartRate:
        return createHeartRateSample(from: record)
    case .bloodPressure:
        return createBloodPressureCorrelation(from: record)
    // ... other types
    }
}
```

### Phase 2: Batch Operations

**Efficient Batch Writing:**
```swift
private func writeBatchRecords(_ records: [CKRecordMessage]) -> CKWriteResultMessage {
    // Group by record type for efficiency
    let groupedRecords = Dictionary(grouping: records) { $0.recordType }

    // Execute batch saves by type
    var successCount = 0
    var failures: [CKRecordFailure] = []

    for (recordType, typeRecords) in groupedRecords {
        let result = writeBatchOfType(recordType, records: typeRecords)
        successCount += result.successCount
        failures.append(contentsOf: result.failures)
    }

    return createWriteResult(
        successCount: successCount,
        totalCount: records.count,
        failures: failures
    )
}
```

### Phase 3: Metadata and Source Handling

**Source Information:**
```swift
private func createHKSource() -> HKSource {
    return HKSource.default()
}

private func createHKMetadata(from record: CKRecordMessage) -> [String: Any] {
    var metadata: [String: Any] = [:]

    // Add ConnectKit-specific metadata
    metadata["ConnectKitVersion"] = getCurrentVersion()

    // Add record-specific metadata
    if let device = record.device {
        metadata["HKDevice"] = createHKDevice(from: device)
    }

    return metadata
}
```

## V. Integration Points

### Platform Channel Integration

**CKHostApi.swift Updates:**
```swift
// Add to existing CKHostApi implementation
func writeRecords(_ records: [CKRecordMessage], completion: @escaping (CKWriteResultMessage) -> Void) {
    Task {
        let result = await writeService.writeRecords(records)
        DispatchQueue.main.async {
            completion(result)
        }
    }
}
```

**Permission Integration:**
```swift
private func ensureWritePermissions(for types: Set<HKObjectType>) async throws {
    let status = await healthStore.authorizationStatus(for: types)

    guard status.contains(.sharingAuthorized) else {
        throw CKError.permissionDenied
    }
}
```

### Mapper Extensions

**RecordTypeMapper.swift Updates:**
```swift
// Add write-specific mappings
extension RecordTypeMapper {

    func mapToHKQuantityType(_ recordType: CKRecordType) -> HKQuantityType? {
        switch recordType {
        case .steps:
            return HKQuantityType.quantityType(forIdentifier: .stepCount)
        case .heartRate:
            return HKQuantityType.quantityType(forIdentifier: .heartRate)
        // ... other quantity types
        }
    }

    func mapToHKCategoryType(_ recordType: CKRecordType) -> HKCategoryType? {
        switch recordType {
        case .sleepAnalysis:
            return HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)
        // ... other category types
        }
    }
}
```

## VI. Error Handling Strategy

### Comprehensive Error Mapping

```swift
private func mapHealthKitError(_ error: Error) -> CKRecordFailure {
    if let hkError = error as? HKError {
        switch hkError.code {
        case .errorAuthorizationDenied:
            return CKRecordFailure(
                recordID: "unknown",
                error: CKPermissionError.denied,
                message: "Health write access denied"
            )
        case .errorAuthorizationStatusRestricted:
            return CKRecordFailure(
                recordID: "unknown",
                error: CKPermissionError.restricted,
                message: "Health write access restricted"
            )
        default:
            return CKRecordFailure(
                recordID: "unknown",
                error: CKWriteError.unknown,
                message: "HealthKit error: \(hkError.localizedDescription)"
            )
        }
    }

    return CKRecordFailure(
        recordID: "unknown",
        error: CKWriteError.unknown,
        message: "Unexpected error: \(error.localizedDescription)"
    )
}
```

## VII. Testing Requirements

### Unit Tests

**Swift Unit Tests:**
- Record type mapping accuracy
- Error handling scenarios
- Permission validation logic
- Metadata creation
- Batch operation logic

### Integration Tests

**HealthKit Integration:**
- Successful write operations
- Permission denial handling
- Invalid data rejection
- Batch write performance
- Cross-platform consistency

### Mock Testing

**MockHealthKitStore:**
```swift
class MockHealthKitStore: HKHealthStoreProtocol {
    var shouldSucceed: Bool = true
    var authStatus: HKAuthorizationStatus = .sharingAuthorized

    func save(_ object: HKObject, withCompletion completion: @escaping (Bool, Error?) -> Void) {
        completion(shouldSucceed, shouldSucceed ? nil : MockError.saveFailed)
    }

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return authStatus
    }
}
```

## VIII. Performance Considerations

### Batch Optimization

**Group By Record Type:**
- Reduce HealthKit call overhead
- Leverage batch save operations
- Minimize permission checks

**Async/Await Patterns:**
- Non-blocking write operations
- Proper memory management
- Background queue usage

### Memory Management

**Record Conversion:**
- Efficient object creation
- Proper cleanup of HKObjects
- Avoid memory leaks in batch operations

## IX. Success Criteria

### Functional Requirements

- [ ] All supported record types can be written successfully
- [ ] Error handling matches Android implementation behavior
- [ ] Permission checking prevents unauthorized writes
- [ ] Batch operations handle partial success scenarios
- [ ] Metadata and source information preserved

### Non-Functional Requirements

- [ ] Performance meets targets (< 100ms per record)
- [ ] Memory usage remains within bounds
- [ ] Code follows established Swift patterns
- [ ] Comprehensive test coverage (> 90%)
- [ ] Documentation updated with implementation details

## X. Deliverables

### Code Deliverables

1. **Complete WriteService.swift** - Full implementation with all record types
2. **Updated CKHostApi.swift** - Integration with platform channels
3. **Extended RecordTypeMapper.swift** - Write-specific type mappings
4. **Swift Unit Tests** - Comprehensive test coverage
5. **Integration Tests** - End-to-end testing

### Documentation Deliverables

1. **Implementation Notes** - Technical decisions and trade-offs
2. **API Documentation** - Updated with iOS-specific behavior
3. **Testing Guide** - Procedures for validating write operations
4. **Troubleshooting Guide** - Common issues and solutions

---

**Implementation Timeline**: 1-2 weeks
**Dependencies**: Existing HealthKit permissions and platform channels
**Blockers**: None identified
**Risks**: HealthKit API complexity, testing on physical devices required