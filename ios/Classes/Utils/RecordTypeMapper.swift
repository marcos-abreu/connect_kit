import Foundation
import HealthKit

/// RecordTypeMapper
///
/// Centralizes the mapping between generic string identifiers (from Dart/Pigeon)
/// and the specific iOS HealthKit HKObjectType objects.
/// Simple version-aware mapping - no fallbacks, honest about what's supported.
public enum RecordTypeMapper {

    private static let TAG = "RecordTypeMapper"

    /// Defines the type of access requested for a health data type
    public enum AccessType {
        case read
        case write
    }

    // MARK: - Category-Based Read-Only Detection

    /// Device-exclusive and system-generated types that apps cannot write
    /// This is the ONLY list that needs maintenance for new types
    private static let DEVICE_EXCLUSIVE_READ_ONLY: Set<String> = [
        // Apple Watch sensor data
        "appleSleepingWristTemperature",
        "atrialFibrillationBurden",
        "appleWalkingSteadiness",
        "runningPower",
        "runningSpeed",
        "runningStrideLength",
        "runningVerticalOscillation",
        "runningGroundContactTime",

        // System-generated events
        "lowHeartRateEvent",
        "highHeartRateEvent",
        "irregularHeartRhythmEvent",
        "audioExposureEvent",
        "headphoneAudioExposureEvent",
        "environmentalAudioExposureEvent",
        "lowCardioFitnessEvent",
        "appleWalkingSteadinessEvent",
        "appleStandHour",

        // System-calculated metrics
        "walkingHeartRateAverage",
        "heartRateRecoveryOneMinute",

        // Menstrual cycle anomalies (iOS 16+)
        "irregularMenstrualCycles",
        "persistentIntermenstrualBleeding",
        "prolongedMenstrualPeriods",
        "infrequentMenstrualCycles",

        // Special cases
        "workoutRoute",  // Can only be written as part of workout
        "electrocardiogram",  // Apple Watch ECG app only
    ]

    // MARK: - Single Source of Truth: The Combined Type Map

    // Tuple Value: (Type Getter, Minimum iOS Version)
    // The getter is a closure () -> HKObjectType? which encapsulates the #available check.
    private static let TYPE_MAP: [String: (getter: () -> HKObjectType?, minVersion: Double)] = [

        // --- Core Types (iOS 8.0+) ---
        // For types available since iOS 8, the closure simply returns the type.
        "biologicalSex": ({ HKObjectType.characteristicType(forIdentifier: .biologicalSex) }, 8.0),
        "bloodType": ({ HKObjectType.characteristicType(forIdentifier: .bloodType) }, 8.0),
        "dateOfBirth": ({ HKObjectType.characteristicType(forIdentifier: .dateOfBirth) }, 8.0),
        "height": ({ HKObjectType.quantityType(forIdentifier: .height) }, 8.0),
        "weight": ({ HKObjectType.quantityType(forIdentifier: .bodyMass) }, 8.0),
        "bodyFat": (
            { HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) }, 8.0
        ),
        "leanBodyMass": ({ HKObjectType.quantityType(forIdentifier: .leanBodyMass) }, 8.0),
        "bodyMassIndex": ({ HKObjectType.quantityType(forIdentifier: .bodyMassIndex) }, 8.0),

        // ... (other iOS 8.0 types simplified here)
        "heartRate": ({ HKObjectType.quantityType(forIdentifier: .heartRate) }, 8.0),
        // "bloodPressure": ({ HKObjectType.correlationType(forIdentifier: .bloodPressure) }, 8.0),
        "bloodPressure.systolic": (
            { HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic) }, 8.0
        ),
        "bloodPressure.diastolic": (
            { HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) }, 8.0
        ),
        "bodyTemperature": ({ HKObjectType.quantityType(forIdentifier: .bodyTemperature) }, 8.0),
        "respiratoryRate": ({ HKObjectType.quantityType(forIdentifier: .respiratoryRate) }, 8.0),
        "oxygenSaturation": ({ HKObjectType.quantityType(forIdentifier: .oxygenSaturation) }, 8.0),

        "steps": ({ HKObjectType.quantityType(forIdentifier: .stepCount) }, 8.0),
        "distance": ({ HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) }, 8.0),
        "floorsClimbed": ({ HKObjectType.quantityType(forIdentifier: .flightsClimbed) }, 8.0),
        "restingCalories": ({ HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) }, 8.0),

        // "nutrition": ({ HKObjectType.correlationType(forIdentifier: .food) }, 8.0),
        "nutrition.calories": (
            { HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) }, 8.0
        ),
        "nutrition.protein": ({ HKObjectType.quantityType(forIdentifier: .dietaryProtein) }, 8.0),
        "nutrition.carbs": (
            { HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates) }, 8.0
        ),
        "nutrition.fat": ({ HKObjectType.quantityType(forIdentifier: .dietaryFatTotal) }, 8.0),
        "bloodGlucose": ({ HKObjectType.quantityType(forIdentifier: .bloodGlucose) }, 8.0),

        "sleepAnalysis": ({ HKObjectType.categoryType(forIdentifier: .sleepAnalysis) }, 8.0),

        "workout": ({ HKObjectType.workoutType() }, 8.0),
        "workout.distance": (
            { HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) }, 8.0
        ),
        "workout.heartRate": ({ HKObjectType.quantityType(forIdentifier: .heartRate) }, 8.0),
        "workout.calories": (
            { HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) }, 8.0
        ),

        // --- Version-Specific Types (Requires #available in the getter) ---
        // Note: For newer APIs, the getter contains the necessary #available check.
        // The minVersion double is now only used for logging/debugging/filtering purposes.
        "waterIntake": (
            {
                if #available(iOS 9.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .dietaryWater)
                }
                return nil
            }, 9.0
        ),

        "menstrualFlow": (
            {
                if #available(iOS 9.0, *) {
                    return HKObjectType.categoryType(forIdentifier: .menstrualFlow)
                }
                return nil
            }, 9.0
        ),

        "mindfulSession": (
            {
                if #available(iOS 10.0, *) {
                    return HKObjectType.categoryType(forIdentifier: .mindfulSession)
                }
                return nil
            }, 10.0
        ),

        "electrocardiogram": (
            {
                if #available(iOS 14.0, *) { return HKObjectType.electrocardiogramType() }
                return nil
            }, 14.0
        ),

        "distanceCycling": (
            {
                if #available(iOS 10.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .distanceCycling)
                }
                return nil
            }, 10.0
        ),

        "distanceWheelchair": (
            {
                if #available(iOS 10.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .distanceWheelchair)
                }
                return nil
            }, 10.0
        ),

        "distanceSwimming": (
            {
                if #available(iOS 10.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .distanceSwimming)
                }
                return nil
            }, 10.0
        ),
    ]

    // MARK: - Public API Method

    // MARK: - The Robust getObjectType Method

    /**
     * Retrieves HealthKit HKObjectType with comprehensive read-only validation.
     *
     * Uses category-based detection for future-proof read-only enforcement:
     * 1. Type system architecture (HKCharacteristicType, HKClinicalType, etc.)
     * 2. Correlation types (special authorization rules)
     * 3. Device-exclusive types (maintained list)
     *
     * @param recordType The string identifier
     * @param accessType The requested access (read or write)
     * @return HKObjectType? The type if valid and allowed, nil otherwise
     */
    public static func getObjectType(
        recordType: String,
        accessType: AccessType = .read
    ) -> HKObjectType? {
        // 1. Check if type exists in mapping
        guard let mapping = TYPE_MAP[recordType] else {
            CKLogger.w(tag: TAG, message: "Unknown record type: '\(recordType)'")
            return nil
        }

        // 2. Execute getter to obtain the HKObjectType
        guard let objectType = mapping.getter() else {
            CKLogger.w(
                tag: TAG,
                message: "Type '\(recordType)' (requires iOS \(mapping.minVersion)) "
                    + "is not available on current OS"
            )
            return nil
        }

        // 3. For write access, perform comprehensive read-only checks
        if accessType == .write {
            // Category 1: Architectural - Not an HKSampleType
            guard objectType is HKSampleType else {
                let typeName = String(describing: type(of: objectType))
                CKLogger.w(
                    tag: TAG,
                    message: "Type '\(recordType)' cannot be written: "
                        + "it's a \(typeName), not an HKSampleType. "
                        + "These types are managed by the user in the Health app."
                )
                return nil
            }

            // Category 2: Correlation types (special authorization)
            if objectType is HKCorrelationType {
                CKLogger.w(
                    tag: TAG,
                    message: "Type '\(recordType)' is a correlation type. "
                        + "Request authorization for its component types instead "
                        + "(e.g., for bloodPressure, request systolic and diastolic)."
                )
                return nil
            }

            // Category 3: Clinical types (system-populated)
            if #available(iOS 12.0, *), objectType is HKClinicalType {
                CKLogger.w(
                    tag: TAG,
                    message: "Type '\(recordType)' is a clinical record type. "
                        + "Clinical records are populated by healthcare providers "
                        + "and cannot be written by apps."
                )
                return nil
            }

            // Category 4: Device-exclusive types (maintained list)
            if DEVICE_EXCLUSIVE_READ_ONLY.contains(recordType) {
                CKLogger.w(
                    tag: TAG,
                    message: "Type '\(recordType)' is device-exclusive or system-generated. "
                        + "This data can only be created by Apple Watch, iPhone sensors, "
                        + "or system calculations."
                )
                return nil
            }

            // If we reach here, it's a writable HKSampleType
        }

        return objectType
    }

    // MARK: - Helper Methods

    /**
     * Checks if a type is read-only based on its category.
     * Useful for pre-validation before making authorization requests.
     */
    public static func isReadOnly(_ recordType: String) -> Bool {
        guard let mapping = TYPE_MAP[recordType],
            let objectType = mapping.getter()
        else {
            return true  // Unknown types are considered read-only
        }

        // Check all read-only categories
        if !(objectType is HKSampleType) { return true }
        if objectType is HKCorrelationType { return true }
        if #available(iOS 12.0, *), objectType is HKClinicalType { return true }
        if DEVICE_EXCLUSIVE_READ_ONLY.contains(recordType) { return true }

        return false
    }

    /**
     * Returns a human-readable explanation for why a type is read-only.
     */
    public static func getReadOnlyReason(_ recordType: String) -> String {
        guard let mapping = TYPE_MAP[recordType],
            let objectType = mapping.getter()
        else {
            return "Type not found or unavailable on this iOS version"
        }

        if !(objectType is HKSampleType) {
            let typeName = String(describing: type(of: objectType))
            return "\(typeName) values are managed by the user in the Health app"
        }

        if objectType is HKCorrelationType {
            return "Correlation types require authorization for component types"
        }

        if #available(iOS 12.0, *), objectType is HKClinicalType {
            return "Clinical records are populated by healthcare providers"
        }

        if DEVICE_EXCLUSIVE_READ_ONLY.contains(recordType) {
            return "This data is generated by Apple hardware or system calculations"
        }

        return "Unknown reason"
    }

    /**
     * Gets all supported record type identifiers based on current iOS version
     * @return Set of all supported record type strings
     */
    public static func getSupportedTypes() -> Set<String> {
        return Set(
            TYPE_MAP.compactMap { (typeName, mapping) -> String? in
                // Only include types that can be successfully resolved on this OS
                if mapping.getter() != nil {
                    return typeName
                }
                return nil
            }
        )
    }

    // TODO: fixe the isSupported method below,
    //       the getObjectType requires recordType and accessType
    /**
     * Checks if a record type is supported on the current iOS version
     * @param recordType The string identifier to check
     * @return Boolean indicating if the type is supported
     */
    // static func isSupported(recordType: String) -> Bool {
    //     return getObjectType(recordType: recordType) != nil
    // }
}
