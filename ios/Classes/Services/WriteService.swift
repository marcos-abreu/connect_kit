import Foundation
import HealthKit

/// Service for writing health records to HealthKit.
///
/// This service handles:
/// - Decoding Dart maps to HealthKit HKObject records
/// - Filtering out records that are already saved (e.g. Workouts from HKWorkoutBuilder)
/// - Saving new records to the HealthKit store
/// - Error handling and validation failure collection
///
/// **Architecture**:
/// ```
/// Dart Maps → RecordMapper → HKObjects
///    ├─> Workouts (already saved) → Collect IDs
///    └─> Others (not saved) → HealthStore.save() → Collect IDs
/// ```
class WriteService {

    // MARK: - Properties

    private let healthStore: HKHealthStore
    private let recordMapper: RecordMapper

    private static let TAG = CKConstants.TAG_WRITE_SERVICE

    // MARK: - Initialization

    public init(
        healthStore: HKHealthStore,
        recordMapper: RecordMapper
    ) {
        self.healthStore = healthStore
        self.recordMapper = recordMapper
    }

    // MARK: - Public API

    /**
     Writes health records to HealthKit with best-effort semantics.

     **Process:**
     1. Decode each record individually (catch failures per record)
     2. Track duringSession record failures separately (non-critical)
     3. Identify records that need saving vs. those already saved (Workouts)
     4. Batch save new records to HealthKit
     5. Build WriteResultMessage with outcome, IDs, and all failures

     - Parameter records: List of record maps from Dart
     - Returns: WriteResultMessage with outcome, persisted IDs, and failures
     */
    public func writeRecords(_ records: [[String: Any]]) async -> WriteResultMessage {
        // Early return for empty input
        if records.isEmpty {
            return WriteResultMessage(
                outcome: CKConstants.WRITE_OUTCOME_FAILURE,
                persistedRecordIds: [],
                validationFailures: [
                    RecordMapperFailure(
                        indexPath: [CKConstants.ERROR_NO_INDEX_PATH],
                        message: "No records to write - empty input",
                        type: CKConstants.MAPPER_ERROR_NO_RECORD
                    ).toMap()
                ]
            )
        }

        // Use a dictionary to track successful UUIDs by their original index
        // This ensures we can return them in the correct order even with mixed processing
        var successfulUUIDsByIndex: [Int: String] = [:]
        
        // Track objects that need to be batch saved, along with their original index
        // index is -1 for secondary objects (e.g. sleep stages) that shouldn't map to a return ID
        var objectsToSave: [(index: Int, object: HKObject)] = []
        
        var allFailures: [RecordMapperFailure] = []

        // Decode records individually isolating failures
        for (index, recordMap) in records.enumerated() {
            do {
                // Check record kind to determine saving strategy
                let recordKind = recordMap["recordKind"] as? String

                let (decodedObjects, duringSessionFailures) = try recordMapper.decode(recordMap)

                // Track duringSession record failures with decimal indices
                if let failures = duringSessionFailures {
                    for failure in failures {
                        let updatedFailure = failure.copy(
                            indexPath: [index] + failure.indexPath
                        )
                        allFailures.append(updatedFailure)
                    }
                }

                // Handle decoded objects
                if recordKind == CKConstants.RECORD_KIND_WORKOUT {
                    // Workouts are already saved by HKWorkoutBuilder in WorkoutMapper
                    // Since decode didn't throw, the save was successful.
                    // Collect the main workout UUID immediately at the correct index.
                    if let workout = decodedObjects.first {
                        successfulUUIDsByIndex[index] = workout.uuid.uuidString
                    }
                } else {
                    // Other records need to be saved later
                    // Store them with their index so we can map the UUID back after saving
                    // Only track index for the first object (main record) to ensure 1-to-1 mapping
                    for (objIndex, object) in decodedObjects.enumerated() {
                        let trackingIndex = (objIndex == 0) ? index : -1
                        objectsToSave.append((index: trackingIndex, object: object))
                    }
                }

            } catch let error as RecordMapperException {
                allFailures.append(
                    RecordMapperFailure(
                        indexPath: [index],
                        message: "\(error.recordKind ?? "Unknown RecordKind") | \(error.fieldName ?? "") | \(error.message)",
                        type: CKConstants.MAPPER_ERROR_DECODE
                    )
                )
                CKLogger.e(
                    tag: Self.TAG,
                    message: "Failed to decode record at index \(index): \(error.message)",
                    error: error
                )
            } catch {
                allFailures.append(
                    RecordMapperFailure(
                        indexPath: [index],
                        message: "Unexpected error: \(error.localizedDescription)",
                        type: CKConstants.MAPPER_ERROR_UNEXPECTED
                    )
                )
                CKLogger.e(
                    tag: Self.TAG,
                    message: "Unexpected error decoding record at index \(index)",
                    error: error
                )
            }
        }

        // Attempt to save records that need saving
        if !objectsToSave.isEmpty {
            let hkObjects = objectsToSave.map { $0.object }
            
            do {
                try await healthStore.save(hkObjects)
                
                // If successful, map the UUIDs back to their original indices
                for item in objectsToSave {
                    // Only map back if it's a main record (index != -1)
                    if item.index != -1 {
                        successfulUUIDsByIndex[item.index] = item.object.uuid.uuidString
                    }
                }
            } catch {
                allFailures.append(
                    RecordMapperFailure(
                        indexPath: [CKConstants.ERROR_NO_INDEX_PATH],
                        message: "HealthKit failed to save records: \(error.localizedDescription)",
                        type: CKConstants.MAPPER_ERROR_HEALTH_CONNECT_INSERT
                    )
                )
                CKLogger.e(
                    tag: Self.TAG,
                    message: "HealthKit failed to save records: \(error.localizedDescription)",
                    error: error
                )
                // Note: If batch save fails, we assume none were persisted from this batch
                // so we don't add anything to successfulUUIDsByIndex for these items
            }
        }

        // Construct the final ordered list of persisted IDs
        // Sort keys to ensure order matches input records
        let sortedKeys = successfulUUIDsByIndex.keys.sorted()
        let persistedIds = sortedKeys.map { successfulUUIDsByIndex[$0]! }

        // Determine outcome
        let outcome: String
        if !persistedIds.isEmpty && allFailures.isEmpty {
            outcome = "completeSuccess"
        } else if !persistedIds.isEmpty {
            outcome = "partialSuccess"
        } else {
            outcome = "failure"
        }

        let validationFailuresMap = allFailures.map { $0.toMap() }
        
        return WriteResultMessage(
            outcome: outcome,
            persistedRecordIds: persistedIds.isEmpty ? nil : persistedIds,
            validationFailures: validationFailuresMap.isEmpty ? nil : validationFailuresMap
        )
    }
}
