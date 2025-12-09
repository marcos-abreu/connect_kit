import Foundation
import HealthKit

/// Maps audiogram records between Dart representation and iOS HealthKit HKAudiogramSample objects.
///
/// **Architecture:**
/// Audiogram in HealthKit is represented as a single HKAudiogramSample containing multiple
/// HKAudiogramSensitivityPoint objects (one per frequency tested).
///
/// **Key Responsibilities:**
/// - Extract audiogram timestamp and sensitivity points
/// - Map each sensitivity point to HKAudiogramSensitivityPoint
/// - Create HKAudiogramSample with all points
/// - Validate frequency ranges (125-16000 Hz)
/// - Handle separate left/right ear measurements
///
/// **iOS HealthKit Specifics:**
/// - HKAudiogramSample introduced in iOS 13.0
/// - Represents hearing test results (pure-tone audiometry)
/// - Each point has frequency (Hz) and optional left/right ear sensitivity (dBHL)
/// - Frequencies typically range from 125 Hz to 16000 Hz
/// - Sensitivity measured in decibels Hearing Level (dBHL)
///
/// **Platform Support:**
/// - **iOS**: ✅ Supported (HKAudiogramSample, iOS 13.0+)
/// - **Android**: ❌ NOT SUPPORTED (Health Connect has no audiogram type)
///
/// **Important Notes:**
/// - Audiogram is instantaneous (single timestamp, no duration)
/// - At least one sensitivity point required
/// - Each point must have frequency and at least one ear measurement
/// - iOS-only feature: apps cannot write audiograms on Android
@available(iOS 13.0, *)
public class AudiogramMapper {

    // MARK: - Properties

    private let healthStore: HKHealthStore
    private let categoryMapper: CategoryMapper.Type

    private static let TAG = CKConstants.TAG_AUDIOGRAM_MAPPER
    private static let RECORD_KIND = CKConstants.RECORD_KIND_AUDIOGRAM

    // MARK: - Initialization

    /**
     * Initializes AudiogramMapper with required dependencies.
     *
     * - Parameter healthStore: HealthKit store for type validation
     * - Parameter categoryMapper: Category mapper for enum conversions
     */
    public init(
        healthStore: HKHealthStore,
        categoryMapper: CategoryMapper.Type = CategoryMapper.self
    ) {
        self.healthStore = healthStore
        self.categoryMapper = categoryMapper
    }

    // MARK: - Public API

    /**
     Decodes a CK audiogram record map into HealthKit HKAudiogramSample object.
    
     **Workflow:**
     1. Extract timestamp (audiogram is instantaneous)
     2. Extract sensitivity points array
     3. Map each point to HKAudiogramSensitivityPoint
     4. Validate frequency ranges and ear measurements
     5. Create HKAudiogramSample with all points
    
     - Parameter map: The audiogram record map from Dart (via Pigeon)
     - Returns: HKAudiogramSample object with all sensitivity points
     - Throws: RecordMapperException if decoding fails
     */
    public func decode(_ map: [String: Any]) throws -> HKAudiogramSample {
        CKLogger.d(tag: Self.TAG, message: "Decoding audiogram record")

        // Extract timestamp (audiogram is instantaneous, so start == end)
        let timeRange = try RecordMapperUtils.extractTimeRange(
            from: map,
            recordKind: Self.RECORD_KIND
        )

        // Validate it's instantaneous
        if timeRange.start != timeRange.end {
            CKLogger.w(
                tag: Self.TAG,
                message:
                    "Audiogram has different start/end times. Using start time for both."
            )
        }

        let time = timeRange.start

        // Extract sensitivity points array
        guard let pointsArray = map["sensitivityPoints"] as? [[String: Any]], !pointsArray.isEmpty
        else {
            throw RecordMapperException(
                message: "Audiogram must have at least one sensitivity point",
                recordKind: Self.RECORD_KIND,
                fieldName: "sensitivityPoints"
            )
        }

        // Extract device
        let hkDevice = RecordMapperUtils.createHKDevice(from: map)

        // Create metadata
        let metadata = createAudiogramMetadata(from: map)

        // Decode each sensitivity point
        var sensitivityPoints: [HKAudiogramSensitivityPoint] = []

        for (index, pointMap) in pointsArray.enumerated() {
            do {
                let point = try decodeSensitivityPoint(pointMap: pointMap, pointIndex: index)
                sensitivityPoints.append(point)
            } catch let error as RecordMapperException {
                // Re-throw with point index context
                throw RecordMapperException(
                    message: "Point \(index): \(error.message)",
                    recordKind: Self.RECORD_KIND,
                    fieldName: "sensitivityPoints[\(index)]",
                    cause: error
                )
            }
        }

        // Create HKAudiogramSample
        let audiogramSample: HKAudiogramSample
        if let device = hkDevice, #available(iOS 18.1, *) {
            audiogramSample = HKAudiogramSample(
                sensitivityPoints: sensitivityPoints,
                start: time,
                end: time,
                device: device,
                metadata: metadata
            )
        } else {
            audiogramSample = HKAudiogramSample(
                sensitivityPoints: sensitivityPoints,
                start: time,
                end: time,
                metadata: metadata
            )
        }

        CKLogger.d(
            tag: Self.TAG,
            message: "Successfully created audiogram sample with \(sensitivityPoints.count) points"
        )

        return audiogramSample
    }

    // MARK: - Private Helpers

    /**
     Decodes a single sensitivity point into HKAudiogramSensitivityPoint.
     */
    private func decodeSensitivityPoint(
        pointMap: [String: Any],
        pointIndex: Int
    ) throws -> HKAudiogramSensitivityPoint {

        // Extract frequency
        guard let frequency = pointMap["frequency"] as? Double else {
            throw RecordMapperException(
                message: "Missing or invalid 'frequency' field",
                recordKind: Self.RECORD_KIND,
                fieldName: "sensitivityPoints[\(pointIndex)].frequency"
            )
        }

        // Validate frequency range (typical audiogram range)
        if frequency < 125.0 || frequency > 16000.0 {
            CKLogger.w(
                tag: Self.TAG,
                message:
                    "Frequency \(frequency) Hz is outside typical range (125-16000 Hz)"
            )
        }

        // Extract optional left ear sensitivity
        let leftEarSensitivity = pointMap["leftEarSensitivity"] as? Double

        // Extract optional right ear sensitivity
        let rightEarSensitivity = pointMap["rightEarSensitivity"] as? Double

        // Validate at least one ear measurement exists
        if leftEarSensitivity == nil && rightEarSensitivity == nil {
            throw RecordMapperException(
                message: "Sensitivity point must have at least one ear measurement",
                recordKind: Self.RECORD_KIND,
                fieldName: "sensitivityPoints[\(pointIndex)]"
            )
        }

        // Create HKQuantity objects for frequencies (in Hz)
        let frequencyQuantity = HKQuantity(unit: HKUnit.hertz(), doubleValue: frequency)

        // Create HKQuantity objects for sensitivities (in dBHL)
        let dBHLUnit = HKUnit.decibelHearingLevel()

        let leftEarQuantity: HKQuantity?
        if let leftValue = leftEarSensitivity {
            leftEarQuantity = HKQuantity(unit: dBHLUnit, doubleValue: leftValue)
        } else {
            leftEarQuantity = nil
        }

        let rightEarQuantity: HKQuantity?
        if let rightValue = rightEarSensitivity {
            rightEarQuantity = HKQuantity(unit: dBHLUnit, doubleValue: rightValue)
        } else {
            rightEarQuantity = nil
        }

        // Create HKAudiogramSensitivityPoint
        do {
            let sensitivityPoint = try HKAudiogramSensitivityPoint(
                frequency: frequencyQuantity,
                leftEarSensitivity: leftEarQuantity,
                rightEarSensitivity: rightEarQuantity
            )
            return sensitivityPoint
        } catch {
            throw RecordMapperException(
                message: "Failed to create sensitivity point: \(error.localizedDescription)",
                recordKind: Self.RECORD_KIND,
                fieldName: "sensitivityPoints[\(pointIndex)]",
                cause: error
            )
        }
    }

    /**
     Creates audiogram metadata dictionary.
    
     Includes:
     1. Source metadata (recording method, device, sync IDs)
     2. Timezone metadata
     3. Custom Dart metadata (with ck_ prefix)
     */
    private func createAudiogramMetadata(from map: [String: Any]) -> [String: Any] {
        return RecordMapperUtils.createMetadata(from: map)
    }
}