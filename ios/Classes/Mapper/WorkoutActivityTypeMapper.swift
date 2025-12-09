import Foundation
import HealthKit

/// Maps Dart activity type strings to iOS HealthKit HKWorkoutActivityType.
///
/// This mapper handles the translation of generic activity strings (e.g., "running")
/// into the specific `HKWorkoutActivityType` enum values used by HealthKit.
/// It supports version-specific activities by checking iOS availability.
public enum WorkoutActivityTypeMapper {

    /// Maps a Dart activity type string to an HKWorkoutActivityType.
    ///
    /// - Parameter activityTypeStr: The activity type string from Dart.
    /// - Returns: The corresponding HKWorkoutActivityType, or nil if unsupported.
    public static func map(_ activityTypeStr: String) -> HKWorkoutActivityType? {
        switch activityTypeStr.lowercased() {
        // Common activities (iOS 8.0+)
        case "running":
            return .running
        case "walking":
            return .walking
        case "cycling":
            return .cycling
        case "swimming":
            return .swimming
        case "yoga":
            return .yoga
        case "hiking":
            return .hiking
        case "basketball":
            return .basketball
        case "soccer":
            return .soccer
        case "baseball":
            return .baseball
        case "football":
            return .americanFootball
        case "tennis":
            return .tennis
        case "golf":
            return .golf
        case "dance":
            return .dance
        case "elliptical":
            return .elliptical
        case "rowing":
            return .rowing
        case "stairs":
            return .stairs
        case "steptraining":
            return .stepTraining
        case "crosstraining":
            return .crossTraining
        case "functionalstrengthtraining":
            return .functionalStrengthTraining
        case "traditionalstrengthtraining":
            return .traditionalStrengthTraining
        case "mixedcardio":
            return .mixedCardio
        case "highintensityintervaltraining":
            return .highIntensityIntervalTraining
        case "kickboxing":
            return .kickboxing
        case "boxing":
            return .boxing
        case "martialarts":
            return .martialArts
        case "pilates":
            return .pilates
        case "barre":
            return .barre
        case "coretraining":
            return .coreTraining
        case "flexibility":
            return .flexibility
        case "mindandbody":
            return .mindAndBody
        case "wheelchair":
            return .wheelchairWalkPace

        // iOS 10.0+
        case "wheelchairrunpace":
            if #available(iOS 10.0, *) {
                return .wheelchairRunPace
            }
            return nil

        // iOS 11.0+
        case "handcycling":
            if #available(iOS 11.0, *) {
                return .handCycling
            }
            return nil
        case "discsports":
            if #available(iOS 11.0, *) {
                return .discSports
            }
            return nil
        case "fitnessgaming":
            if #available(iOS 11.0, *) {
                return .fitnessGaming
            }
            return nil

        // iOS 13.0+

        // iOS 14.0+
        case "cooldown":
            if #available(iOS 14.0, *) {
                return .cooldown
            }
            return nil
        case "pickleball":
            if #available(iOS 14.0, *) {
                return .pickleball
            }
            return nil
        case "cardiodance":
            if #available(iOS 14.0, *) {
                return .cardioDance
            }
            return nil
        case "socialdance":
            if #available(iOS 14.0, *) {
                return .socialDance
            }
            return nil

        // iOS 16.0+
        case "swimbikerun":
            if #available(iOS 16.0, *) {
                return .swimBikeRun
            }
            return nil
        case "transition":
            if #available(iOS 16.0, *) {
                return .transition
            }
            return nil

        // iOS 17.0+
        case "underwaterdiving":
            if #available(iOS 17.0, *) {
                return .underwaterDiving
            }
            return nil

        // Generic fallback
        case "other":
            return .other

        default:
            return nil
        }
    }
}
