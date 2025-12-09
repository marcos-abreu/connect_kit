import Foundation
import HealthKit

/// Maps category names and values between Dart strings and iOS HealthKit constants.
///
/// This mapper provides bidirectional conversions:
///  - `decode` converts a Dart enum string (e.g. "wrist") into the iOS Int constant.
///  - `encode` converts an iOS Int constant back into a Dart enum string.
///
/// Internally, each category defines its own map of `String` ↔ `Int`.
/// Mirrors Android CategoryMapper.kt exactly for cross-platform consistency.
public enum CategoryMapper {

    // ------------------------------------------------------------------------
    // Category mappings
    // ------------------------------------------------------------------------

    private static let biologicalSex: [String: Int] = [
        "female": HKBiologicalSex.female.rawValue,
        "male": HKBiologicalSex.male.rawValue,
        "other": HKBiologicalSex.other.rawValue,  // @available(macOS 13.0, *)
        "unknown": HKBiologicalSex.notSet.rawValue,
    ]

    private static let bloodType: [String: Int] = [
        "aPositive": HKBloodType.aPositive.rawValue,
        "aNegative": HKBloodType.aNegative.rawValue,
        "bPositive": HKBloodType.bPositive.rawValue,
        "bNegative": HKBloodType.bNegative.rawValue,
        "abPositive": HKBloodType.abPositive.rawValue,
        "abNegative": HKBloodType.abNegative.rawValue,
        "oPositive": HKBloodType.oPositive.rawValue,
        "oNegative": HKBloodType.oNegative.rawValue,
        "unknown": HKBloodType.notSet.rawValue,
    ]

    private static let fitzpatrickSkinType: [String: Int] = [
        "I": HKFitzpatrickSkinType.I.rawValue,
        "II": HKFitzpatrickSkinType.II.rawValue,
        "III": HKFitzpatrickSkinType.III.rawValue,
        "IV": HKFitzpatrickSkinType.IV.rawValue,
        "V": HKFitzpatrickSkinType.V.rawValue,
        "VI": HKFitzpatrickSkinType.VI.rawValue,
        "unknown": HKFitzpatrickSkinType.notSet.rawValue,
    ]

    private static let intermenstrualBleedingType: [String: Int] = [
        "notApplicable": HKCategoryValue.notApplicable.rawValue,
        "unknown": HKCategoryValue.notApplicable.rawValue,
    ]

    private static let contraceptiveValue: [String: Int] = {
        // iOS 14.3+ — full map available
        if #available(iOS 14.3, *) {
            return [
                "unspecified": HKCategoryValueContraceptive.unspecified.rawValue,
                "implant": HKCategoryValueContraceptive.implant.rawValue,
                "injection": HKCategoryValueContraceptive.injection.rawValue,
                "intrauterineDevice": HKCategoryValueContraceptive.intrauterineDevice.rawValue,
                "intravaginalRing": HKCategoryValueContraceptive.intravaginalRing.rawValue,
                "oral": HKCategoryValueContraceptive.oral.rawValue,
                "patch": HKCategoryValueContraceptive.patch.rawValue,
                "unknown": HKCategoryValueContraceptive.unspecified.rawValue,
            ]
        }

        // Pre–iOS 14.3 — None of these symbols exist (it is guaranteed by the RecordTypeMapper)
        return [:]
    }()

    private static let progesteroneTestResult: [String: Int] = {
        // iOS 15.0+ — full map available
        if #available(iOS 15.0, *) {
            return [
                "negative": HKCategoryValueProgesteroneTestResult.negative.rawValue,
                "positive": HKCategoryValueProgesteroneTestResult.positive.rawValue,
                "indeterminate": HKCategoryValueProgesteroneTestResult.indeterminate.rawValue,
                "unknown": HKCategoryValueProgesteroneTestResult.indeterminate.rawValue,
            ]
        }

        // Pre–iOS 15.0 — None of these symbols exist (it is guaranteed by the RecordTypeMapper)
        return [:]
    }()

    /// Body temperature measurement location mappings
    private static let bodyTemperatureMeasurementLocation: [String: Int] = [
        "armpit": HKBodyTemperatureSensorLocation.armpit.rawValue,
        "body": HKBodyTemperatureSensorLocation.body.rawValue,
        "ear": HKBodyTemperatureSensorLocation.ear.rawValue,
        "finger": HKBodyTemperatureSensorLocation.finger.rawValue,
        "gastroIntestinal": HKBodyTemperatureSensorLocation.gastroIntestinal.rawValue,
        "mouth": HKBodyTemperatureSensorLocation.mouth.rawValue,
        "rectum": HKBodyTemperatureSensorLocation.rectum.rawValue,
        "toe": HKBodyTemperatureSensorLocation.toe.rawValue,
        "earDrum": HKBodyTemperatureSensorLocation.earDrum.rawValue,
        "artery": HKBodyTemperatureSensorLocation.temporalArtery.rawValue,
        "forehead": HKBodyTemperatureSensorLocation.forehead.rawValue,
        "unknown": HKBodyTemperatureSensorLocation.other.rawValue,
    ]

    private static let mindfulnessSessionType: [String: Int] = [
        "unknown": HKCategoryValue.notApplicable.rawValue
    ]

    /// Menstruation flow mappings
    private static let menstruationFlow: [String: Int] = {
        // iOS 18.0+ — full map available
        if #available(iOS 18.0, *) {
            return [
                "light": HKCategoryValueVaginalBleeding.light.rawValue,
                "medium": HKCategoryValueVaginalBleeding.medium.rawValue,
                "heavy": HKCategoryValueVaginalBleeding.heavy.rawValue,
                "none": HKCategoryValueVaginalBleeding.none.rawValue,
                "unknown": HKCategoryValueVaginalBleeding.unspecified.rawValue,
            ]
        }

        // Pre–iOS 18.0 — None of these symbols exist (it is guaranteed by the RecordTypeMapper)
        return [:]
    }()

    /// Cervical mucus appearance mappings
    private static let cervicalMucusAppearance: [String: Int] = [
        "dry": HKCategoryValueCervicalMucusQuality.dry.rawValue,
        "sticky": HKCategoryValueCervicalMucusQuality.sticky.rawValue,
        "creamy": HKCategoryValueCervicalMucusQuality.creamy.rawValue,
        "watery": HKCategoryValueCervicalMucusQuality.watery.rawValue,
        "eggWhite": HKCategoryValueCervicalMucusQuality.eggWhite.rawValue,
        "unknown": HKCategoryValueCervicalMucusQuality.dry.rawValue,  // no unspecified in iOS
    ]

    /// Ovulation test result mappings
    private static let ovulationTestResult: [String: Int] = [
        "high": HKCategoryValueOvulationTestResult.estrogenSurge.rawValue,
        "negative": HKCategoryValueOvulationTestResult.negative.rawValue,
        "positive": HKCategoryValueOvulationTestResult.luteinizingHormoneSurge.rawValue,
        "inconclusive": HKCategoryValueOvulationTestResult.indeterminate.rawValue,
    ]

    /// Sexual activity protection mappings
    /// Documentation says to store HKCategoryValue.notApplicable, and use metadata for real value
    private static let sexualActivityProtection: [String: Int] = [
        "protected": HKCategoryValue.notApplicable.rawValue,
        "unprotected": HKCategoryValue.notApplicable.rawValue,
        "unknown": HKCategoryValue.notApplicable.rawValue,
    ]

    /// Sleep session stage mappings
    /// Maps to HKCategoryValueIdentifier.sleepAnalysis values
    private static let sleepSession: [String: Int] = {
        // iOS 16.0+ — full map available
        if #available(iOS 16.0, *) {
            return [
                "inBed": HKCategoryValueSleepAnalysis.inBed.rawValue,
                "outOfBed": HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,  // Not directly mapped in iOS
                "sleeping": HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,  // Generic sleep state
                "awake": HKCategoryValueSleepAnalysis.awake.rawValue,
                "light": HKCategoryValueSleepAnalysis.asleepCore.rawValue,  // iOS uses asleep, we map light to asleep
                "deep": HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                "rem": HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                "unknown": HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            ]
        }

        // Pre–iOS 16.0 — None of these symbols exist (it is guaranteed by the RecordTypeMapper)
        return [:]
    }()

    private static let vo2MaxMeasurementMethod: [String: Int] = [
        "cooperTest": HKVO2MaxTestType.maxExercise.rawValue,
        "rateRatio": HKVO2MaxTestType.predictionNonExercise.rawValue,
        "metabolicCart": HKVO2MaxTestType.maxExercise.rawValue,
        "multistageFitnessTest": HKVO2MaxTestType.maxExercise.rawValue,
        "fitnessTest": HKVO2MaxTestType.predictionSubMaxExercise.rawValue,
        "other": HKVO2MaxTestType.maxExercise.rawValue,
    ]

    // ------------------------------------------------------------------------
    // Registry of all category maps
    // ------------------------------------------------------------------------

    private static let registry: [String: [String: Int]] = [
        "CKBiologicalSex": biologicalSex,
        "CKBloodType": bloodType,
        "CKFitzpatrickSkinType": fitzpatrickSkinType,
        "CKIntermenstrualBleedingType": intermenstrualBleedingType,
        "CKContraceptiveValue": contraceptiveValue,
        "CKProgesteroneTestResult": progesteroneTestResult,
        "CKBodyTemperatureMeasurementLocation": bodyTemperatureMeasurementLocation,
        "CKMindfulnessSessionType": mindfulnessSessionType,
        "CKMenstruationFlow": menstruationFlow,
        "CKCervicalMucusAppearance": cervicalMucusAppearance,
        "CKOvulationTestResult": ovulationTestResult,
        "CKSexualActivityProtection": sexualActivityProtection,
        "CKVo2MaxMeasurementMethod": vo2MaxMeasurementMethod,
        // NOTE: SleepSession is not a category enum in dart (no `CK` prefix)
        "SleepSession": sleepSession,
    ]

    // ------------------------------------------------------------------------
    // Public API
    // ------------------------------------------------------------------------

    /// Decodes a Dart enum string into its corresponding iOS Int constant.
    ///
    /// - Parameters:
    ///   - category: The category name (e.g. "SkinTemperatureMeasurementLocation").
    ///   - value: The Dart enum value string (e.g. "wrist").
    /// - Returns: The matching iOS Int constant, or `nil` if unknown.
    public static func decode(categoryName: String, value: String) -> Int? {
        guard let categoryMap = registry[categoryName] else {
            return nil
        }
        return categoryMap[value]
    }

    /// Encodes an iOS Int constant into its corresponding Dart enum string.
    ///
    /// - Parameters:
    ///   - category: The category name (e.g. "SkinTemperatureMeasurementLocation").
    ///   - constant: The iOS constant value (e.g. 10 for wrist).
    /// - Returns: The Dart enum string, or `nil` if unknown.
    public static func encode(categoryName: String, constant: Int) -> String? {
        guard let categoryMap = registry[categoryName] else {
            return nil
        }
        // Reverse lookup — find key by value
        return categoryMap.first(where: { $0.value == constant })?.key
    }
}
