import Foundation
import HealthKit

/// RecordTypeMapper
///
/// Centralizes the mapping between generic string identifiers (from Dart/Pigeon)
/// and the specific iOS HealthKit HKObjectType objects.
/// Simple version-aware mapping - no fallbacks, honest about what's supported.
public enum RecordTypeMapper {

    private static let TAG = CKConstants.TAG_RECORD_TYPE_MAPPER

    /// Defines the type of access requested for a health data type
    public enum AccessType {
        case read
        case write
    }

    // MARK: - Single Source of Truth: The Combined Type Map

    // Tuple Value: (Type Getter, Minimum iOS Version)
    // The getter is a closure () -> HKObjectType? which encapsulates the #available check.
    private static let TYPE_MAP: [String: (getter: () -> HKObjectType?, minVersion: Double)] = [

        // --- Core Types (iOS 8.0+) ---
        "restingEnergy": ({ HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) }, 8.0),
        "activeEnergy": ({ HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) }, 8.0),
        "steps": ({ HKObjectType.quantityType(forIdentifier: .stepCount) }, 8.0),
        "heartRate": ({ HKObjectType.quantityType(forIdentifier: .heartRate) }, 8.0),
        "bloodGlucose": ({ HKObjectType.quantityType(forIdentifier: .bloodGlucose) }, 8.0),
        "bodyTemperature": ({ HKObjectType.quantityType(forIdentifier: .bodyTemperature) }, 8.0),
        "oxygenSaturation": ({ HKObjectType.quantityType(forIdentifier: .oxygenSaturation) }, 8.0),
        "respiratoryRate": ({ HKObjectType.quantityType(forIdentifier: .respiratoryRate) }, 8.0),

        "height": ({ HKObjectType.quantityType(forIdentifier: .height) }, 8.0),
        "weight": ({ HKObjectType.quantityType(forIdentifier: .bodyMass) }, 8.0),
        "bodyFat": ({ HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) }, 8.0),
        "leanBodyMass": ({ HKObjectType.quantityType(forIdentifier: .leanBodyMass) }, 8.0),
        "bodyMassIndex": ({ HKObjectType.quantityType(forIdentifier: .bodyMassIndex) }, 8.0),

        "biologicalSex": ({ HKObjectType.characteristicType(forIdentifier: .biologicalSex) }, 8.0),
        "bloodType": ({ HKObjectType.characteristicType(forIdentifier: .bloodType) }, 8.0),
        "dateOfBirth": ({ HKObjectType.characteristicType(forIdentifier: .dateOfBirth) }, 8.0),

        "floorsClimbed": ({ HKObjectType.quantityType(forIdentifier: .flightsClimbed) }, 8.0),

        "peripheralPerfusionIndex": (
            { HKObjectType.quantityType(forIdentifier: .peripheralPerfusionIndex) }, 8.0
        ),

        "distanceCycling": ({ HKObjectType.quantityType(forIdentifier: .distanceCycling) }, 8.0),

        "fitzpatrickSkinType": (
            {
                if #available(iOS 9.0, *) {
                    return HKObjectType.characteristicType(forIdentifier: .fitzpatrickSkinType)
                }
                return nil
            }, 9.0
        ),
        "menstrualFlow": (
            {
                // NOTE: available in 9.0, but not all enum values are available in 9.0, so normalizing to 18.0
                if #available(iOS 18.0, *) {
                    return HKObjectType.categoryType(forIdentifier: .menstrualFlow)
                }
                return nil
            }, 18.0
        ),
        "basalBodyTemperature": (
            {
                if #available(iOS 9.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .basalBodyTemperature)
                }
                return nil
            }, 9.0
        ),
        "cervicalMucus": (
            {
                if #available(iOS 9.0, *) {
                    return HKObjectType.categoryType(forIdentifier: .cervicalMucusQuality)
                }
                return nil
            }, 9.0
        ),
        "ovulationTest": (
            {
                if #available(iOS 9.0, *) {
                    return HKObjectType.categoryType(forIdentifier: .ovulationTestResult)
                }
                return nil
            }, 9.0
        ),
        "sexualActivity": (
            {
                if #available(iOS 9.0, *) {
                    return HKObjectType.categoryType(forIdentifier: .sexualActivity)
                }
                return nil
            }, 9.0
        ),
        "intermenstrualBleeding": (
            {
                if #available(iOS 9.0, *) {
                    return HKObjectType.categoryType(forIdentifier: .intermenstrualBleeding)
                }
                return nil
            }, 9.0
        ),
        "uvExposure": (
            {
                if #available(iOS 9.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .uvExposure)
                }
                return nil
            }, 9.0
        ),
        "waterIntake": (
            {
                if #available(iOS 9.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .dietaryWater)
                }
                return nil
            }, 9.0
        ),

        "pushCount": (
            {
                if #available(iOS 10.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .pushCount)
                }
                return nil
            }, 10.0
        ),
        "swimmingStrokeCount": (
            {
                if #available(iOS 10.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)
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
        "mindfulSession": (
            {
                if #available(iOS 10.0, *) {
                    return HKObjectType.categoryType(forIdentifier: .mindfulSession)
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

        "restingHeartRate": (
            {
                if #available(iOS 11.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .restingHeartRate)
                }
                return nil
            }, 11.0
        ),
        "heartRateVariability": (
            {
                if #available(iOS 11.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
                }
                return nil
            }, 11.0
        ),
        "vo2Max": (
            {
                if #available(iOS 11.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .vo2Max)
                }
                return nil
            }, 11.0
        ),

        "environmentalAudioExposure": (
            {
                if #available(iOS 13.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .environmentalAudioExposure)
                }
                return nil
            }, 13.0
        ),
        "headphoneAudioExposure": (
            {
                if #available(iOS 13.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .headphoneAudioExposure)
                }
                return nil
            }, 13.0
        ),
        "audiogram": (
            {
                if #available(iOS 13.0, *) {
                    return HKObjectType.audiogramSampleType()
                }
                return nil
            }, 13.0
        ),

        "walkingSpeed": (
            {
                if #available(iOS 14.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .walkingSpeed)
                }
                return nil
            }, 14.0
        ),
        "walkingStepLength": (
            {
                if #available(iOS 14.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .walkingStepLength)
                }
                return nil
            }, 14.0
        ),
        "walkingAsymmetry": (
            {
                if #available(iOS 14.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .walkingAsymmetryPercentage)
                }
                return nil
            }, 14.0
        ),
        "walkingDoubleSupportPercentage": (
            {
                if #available(iOS 14.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .walkingDoubleSupportPercentage)
                }
                return nil
            }, 14.0
        ),
        "electrocardiogram": (
            {
                if #available(iOS 14.0, *) { return HKObjectType.electrocardiogramType() }
                return nil
            }, 14.0
        ),

        "contraceptive": (
            {
                if #available(iOS 14.3, *) {
                    return HKObjectType.categoryType(forIdentifier: .contraceptive)
                }
                return nil
            }, 14.3
        ),

        "progesteroneTest": (
            {
                if #available(iOS 15.0, *) {
                    return HKObjectType.categoryType(forIdentifier: .progesteroneTestResult)
                }
                return nil
            }, 15.0
        ),
        "numberOfAlcoholicBeverages": (
            {
                if #available(iOS 15.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .numberOfAlcoholicBeverages)
                }
                return nil
            }, 15.0
        ),

        "runningPower": (
            {
                if #available(iOS 16.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .runningPower)
                }
                return nil
            }, 16.0
        ),

        "cyclingPower": (
            {
                if #available(iOS 17.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .cyclingPower)
                }
                return nil
            }, 17.0
        ),
        "cyclingPedalingCadence": (
            {
                if #available(iOS 17.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .cyclingCadence)
                }
                return nil
            }, 17.0
        ),
        "timeInDaylight": (
            {
                if #available(iOS 17.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .timeInDaylight)
                }
                return nil
            }, 17.0
        ),

        // === Composite Type: bloodPressure ===
        "bloodPressure.systolic": (
            { HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic) }, 8.0
        ),
        "bloodPressure.diastolic": (
            { HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) }, 8.0
        ),

        // === Composite Type: workout ===

        "workout": ({ HKObjectType.workoutType() }, 8.0),
        "workout.distance": (
            { HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) }, 8.0
        ),
        // TODO: find way of supporting multiple
        // distanceCycling 8.0+
        // distanceWheelchair 10.0+
        // distanceSwimming 10.0+
        // distanceDownhillSnowSports 11.2+
        // distanceCrossCountrySkiing 18.0+
        // distancePaddleSports 18.0+
        // distanceRowing 18.0+
        // distanceSkatingSports 18.0+
        //
        "workout.energy": (
            { HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) }, 8.0
        ),
        "workout.heartRate": ({ HKObjectType.quantityType(forIdentifier: .heartRate) }, 8.0),
        "workout.power": (
            {
                if #available(iOS 16.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .runningPower)
                }
                return nil
            }, 16.0
        ),
        // TODO: find way of supporting multiple
        // cyclingPower  17.0+
        "workout.speed": (
            {
                if #available(iOS 16.0, *) {
                    return HKObjectType.quantityType(forIdentifier: .runningSpeed)
                }
                return nil
            }, 16.0
        ),
        // TODO: find way of supporting multiple
        // walkingSpeed 14.0+
        // crossCountrySkiingSpeed 18.0+
        // cyclingSpeed 17.0+
        // paddleSportsSpeed 18.0+
        // rowingSpeed 18.0+

        // === Composite Type: sleepSession ===

        // NOTE: available in 8.0, but not all stage values are available in 8.0, so normalizing to 16.0
        "sleepSession": ({ HKObjectType.categoryType(forIdentifier: .sleepAnalysis) }, 16.0),
        "sleepSession.inBed": ({ HKObjectType.categoryType(forIdentifier: .sleepAnalysis) }, 16.0),
        "sleepSession.sleeping": (
            { HKObjectType.categoryType(forIdentifier: .sleepAnalysis) }, 16.0
        ),
        "sleepSession.awake": ({ HKObjectType.categoryType(forIdentifier: .sleepAnalysis) }, 16.0),
        "sleepSession.light": ({ HKObjectType.categoryType(forIdentifier: .sleepAnalysis) }, 16.0),
        "sleepSession.deep": ({ HKObjectType.categoryType(forIdentifier: .sleepAnalysis) }, 16.0),
        "sleepSession.rem": ({ HKObjectType.categoryType(forIdentifier: .sleepAnalysis) }, 16.0),
        "sleepSession.unknown": ({ HKObjectType.categoryType(forIdentifier: .sleepAnalysis) }, 16.0),
        "sleepSession.outOfBed": (  // not directly supported but it will be redirected to unkwon
            { HKObjectType.categoryType(forIdentifier: .sleepAnalysis) }, 16.0
        ),

        // === Composite Type: nutrition ===

        "nutrition.biotin": ({ HKObjectType.quantityType(forIdentifier: .dietaryBiotin) }, 8.0),
        "nutrition.caffeine": ({ HKObjectType.quantityType(forIdentifier: .dietaryCaffeine) }, 8.0),
        "nutrition.calcium": ({ HKObjectType.quantityType(forIdentifier: .dietaryCalcium) }, 8.0),
        "nutrition.carbs": (
            { HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates) }, 8.0
        ),
        "nutrition.chloride": ({ HKObjectType.quantityType(forIdentifier: .dietaryChloride) }, 8.0),
        "nutrition.cholesterol": (
            { HKObjectType.quantityType(forIdentifier: .dietaryCholesterol) }, 8.0
        ),
        "nutrition.chromium": ({ HKObjectType.quantityType(forIdentifier: .dietaryChromium) }, 8.0),
        "nutrition.copper": ({ HKObjectType.quantityType(forIdentifier: .dietaryCopper) }, 8.0),
        "nutrition.energy": (
            { HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) }, 8.0
        ),
        "nutrition.fat": ({ HKObjectType.quantityType(forIdentifier: .dietaryFatTotal) }, 8.0),
        "nutrition.fiber": ({ HKObjectType.quantityType(forIdentifier: .dietaryFiber) }, 8.0),
        "nutrition.folate": ({ HKObjectType.quantityType(forIdentifier: .dietaryFolate) }, 8.0),
        "nutrition.iodine": ({ HKObjectType.quantityType(forIdentifier: .dietaryIodine) }, 8.0),
        "nutrition.iron": ({ HKObjectType.quantityType(forIdentifier: .dietaryIron) }, 8.0),
        "nutrition.magnesium": (
            { HKObjectType.quantityType(forIdentifier: .dietaryMagnesium) }, 8.0
        ),
        "nutrition.manganese": (
            { HKObjectType.quantityType(forIdentifier: .dietaryManganese) }, 8.0
        ),
        "nutrition.molybdenum": (
            { HKObjectType.quantityType(forIdentifier: .dietaryMolybdenum) }, 8.0
        ),
        "nutrition.monounsaturatedFat": (
            { HKObjectType.quantityType(forIdentifier: .dietaryFatMonounsaturated) }, 8.0
        ),
        "nutrition.niacin": ({ HKObjectType.quantityType(forIdentifier: .dietaryNiacin) }, 8.0),
        "nutrition.pantothenicAcid": (
            { HKObjectType.quantityType(forIdentifier: .dietaryPantothenicAcid) }, 8.0
        ),
        "nutrition.phosphorus": (
            { HKObjectType.quantityType(forIdentifier: .dietaryPhosphorus) }, 8.0
        ),
        "nutrition.polyunsaturatedFat": (
            { HKObjectType.quantityType(forIdentifier: .dietaryFatPolyunsaturated) }, 8.0
        ),
        "nutrition.potassium": (
            { HKObjectType.quantityType(forIdentifier: .dietaryPotassium) }, 8.0
        ),
        "nutrition.protein": ({ HKObjectType.quantityType(forIdentifier: .dietaryProtein) }, 8.0),
        "nutrition.riboflavin": (
            { HKObjectType.quantityType(forIdentifier: .dietaryRiboflavin) }, 8.0
        ),
        "nutrition.saturatedFat": (
            { HKObjectType.quantityType(forIdentifier: .dietaryFatSaturated) }, 8.0
        ),
        "nutrition.selenium": ({ HKObjectType.quantityType(forIdentifier: .dietarySelenium) }, 8.0),
        "nutrition.sodium": ({ HKObjectType.quantityType(forIdentifier: .dietarySodium) }, 8.0),
        "nutrition.sugar": ({ HKObjectType.quantityType(forIdentifier: .dietarySugar) }, 8.0),
        "nutrition.thiamin": ({ HKObjectType.quantityType(forIdentifier: .dietaryThiamin) }, 8.0),
        // transFat // not supported on iOS
        // unsaturatedFat // not supported on iOS
        "nutrition.vitaminA": ({ HKObjectType.quantityType(forIdentifier: .dietaryVitaminA) }, 8.0),
        "nutrition.vitaminB12": (
            { HKObjectType.quantityType(forIdentifier: .dietaryVitaminB12) }, 8.0
        ),
        "nutrition.vitaminB6": (
            { HKObjectType.quantityType(forIdentifier: .dietaryVitaminB6) }, 8.0
        ),
        "nutrition.vitaminC": ({ HKObjectType.quantityType(forIdentifier: .dietaryVitaminC) }, 8.0),
        "nutrition.vitaminD": ({ HKObjectType.quantityType(forIdentifier: .dietaryVitaminD) }, 8.0),
        "nutrition.vitaminE": ({ HKObjectType.quantityType(forIdentifier: .dietaryVitaminE) }, 8.0),
        "nutrition.vitaminK": ({ HKObjectType.quantityType(forIdentifier: .dietaryVitaminK) }, 8.0),
        "nutrition.zinc": ({ HKObjectType.quantityType(forIdentifier: .dietaryZinc) }, 8.0),
    ]

    // MARK: - Category-Based Read-Only Detection

    /// Device-exclusive and system-generated types that apps cannot write
    /// This is the ONLY list that needs maintenance for new types
    private static let DEVICE_EXCLUSIVE_READ_ONLY: Set<String> = [
        // Apple Watch sensor data
        "appleSleepingWristTemperature",
        "atrialFibrillationBurden",
        "appleWalkingSteadiness",

        // System-generated events (not confirmed, but makes sense)
        "lowHeartRateEvent",
        "highHeartRateEvent",
        "irregularHeartRhythmEvent",
        "headphoneAudioExposureEvent",
        "environmentalAudioExposureEvent",
        "lowCardioFitnessEvent",
        "appleWalkingSteadinessEvent",

        // System-calculated metrics
        "appleStandHour",
        "walkingHeartRateAverage",
        "heartRateRecoveryOneMinute",

        // Menstrual cycle anomalies (iOS 16+)
        "irregularMenstrualCycles",
        "persistentIntermenstrualBleeding",
        "prolongedMenstrualPeriods",
        "infrequentMenstrualCycles",

        // Special cases
        "electrocardiogram",  // Apple Watch ECG app only

        // iOS-specific walking metrics (device-generated, read-only)
        "walkingStepLength",
        "walkingAsymmetry",
        "walkingDoubleSupportPercentage",

        // System-generated composite types
        "timeInDaylight",
        "uvExposure",
    ]

    // MARK: - Public API Method

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

            // Category 2: Characteristic types (entered only through the HealthKit App)
            if objectType is HKCharacteristicType {
                CKLogger.w(
                    tag: TAG,
                    message: "Type '\(recordType)' is a characteristic type. "
                        + "Can only be written using the HealthKit App."
                )
                return nil
            }

            // Category 3: Correlation types (special authorization)
            if objectType is HKCorrelationType {
                CKLogger.w(
                    tag: TAG,
                    message: "Type '\(recordType)' is a correlation type. "
                        + "Request authorization for its component types instead "
                        + "(e.g., for bloodPressure, request systolic and diastolic)."
                )
                return nil
            }

            // Category 4: Clinical types (system-populated)
            if #available(iOS 12.0, *), objectType is HKClinicalType {
                CKLogger.w(
                    tag: TAG,
                    message: "Type '\(recordType)' is a clinical record type. "
                        + "Clinical records are populated by healthcare providers "
                        + "and cannot be written by apps."
                )
                return nil
            }

            // Category 5: Device-exclusive types (maintained list)
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
        if objectType is HKCharacteristicType { return true }
        if objectType is HKCorrelationType { return true }
        if #available(iOS 12.0, *), objectType is HKClinicalType { return true }
        if DEVICE_EXCLUSIVE_READ_ONLY.contains(recordType) { return true }

        return false
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
}
