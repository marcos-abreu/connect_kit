package dev.luix.connect_kit.mapper

import androidx.health.connect.client.records.BodyTemperatureMeasurementLocation
import androidx.health.connect.client.records.BloodGlucoseRecord
import androidx.health.connect.client.records.MealType
import androidx.health.connect.client.records.Vo2MaxRecord
import androidx.health.connect.client.records.SkinTemperatureRecord
import androidx.health.connect.client.records.CervicalMucusRecord
import androidx.health.connect.client.records.MindfulnessSessionRecord
import androidx.health.connect.client.records.MenstruationFlowRecord
import androidx.health.connect.client.records.OvulationTestRecord
import androidx.health.connect.client.records.SexualActivityRecord
import androidx.health.connect.client.records.ActivityIntensityRecord
import androidx.health.connect.client.records.SleepSessionRecord

/**
 * Maps category values between Dart enum strings and Android Health Connect constants.
 *
 * This mapper provides bidirectional conversions:
 *  - [decode] converts a Dart enum string (e.g. "wrist") into the Android Int constant.
 *  - [encode] converts an Android Int constant back into a Dart enum string.
 *
 * Internally, each category defines its own map of `String` ↔ `Int`.
 */
object CategoryMapper {

    // ------------------------------------------------------------------------
    // Category mappings
    // ------------------------------------------------------------------------

    private val bodyTemperatureMeasurementLocation: Map<String, Int> = mapOf(
        "armpit" to BodyTemperatureMeasurementLocation.MEASUREMENT_LOCATION_ARMPIT,
        "ear" to BodyTemperatureMeasurementLocation.MEASUREMENT_LOCATION_EAR,
        "finger" to BodyTemperatureMeasurementLocation.MEASUREMENT_LOCATION_FINGER,
        "forehead" to BodyTemperatureMeasurementLocation.MEASUREMENT_LOCATION_FOREHEAD,
        "mouth" to BodyTemperatureMeasurementLocation.MEASUREMENT_LOCATION_MOUTH,
        "rectum" to BodyTemperatureMeasurementLocation.MEASUREMENT_LOCATION_RECTUM,
        "artery" to BodyTemperatureMeasurementLocation.MEASUREMENT_LOCATION_TEMPORAL_ARTERY,
        "toe" to BodyTemperatureMeasurementLocation.MEASUREMENT_LOCATION_TOE,
        "unknown" to BodyTemperatureMeasurementLocation.MEASUREMENT_LOCATION_UNKNOWN,
    )

    private val specimenSource: Map<String, Int> = mapOf(
        "capillaryBlood" to BloodGlucoseRecord.SPECIMEN_SOURCE_CAPILLARY_BLOOD,
        "interstitialFluid" to BloodGlucoseRecord.SPECIMEN_SOURCE_INTERSTITIAL_FLUID,
        "plasma" to BloodGlucoseRecord.SPECIMEN_SOURCE_PLASMA,
        "serum" to BloodGlucoseRecord.SPECIMEN_SOURCE_SERUM,
        "tears" to BloodGlucoseRecord.SPECIMEN_SOURCE_TEARS,
        "blood" to BloodGlucoseRecord.SPECIMEN_SOURCE_WHOLE_BLOOD,
        "unknown" to BloodGlucoseRecord.SPECIMEN_SOURCE_UNKNOWN,
    )

    private val mealType: Map<String, Int> = mapOf(
        "breakfast" to MealType.MEAL_TYPE_BREAKFAST,
        "dinner" to MealType.MEAL_TYPE_DINNER,
        "lunch" to MealType.MEAL_TYPE_LUNCH,
        "snack" to MealType.MEAL_TYPE_SNACK,
        "unknown" to MealType.MEAL_TYPE_UNKNOWN,
    )

    private val relationToMeal: Map<String, Int> = mapOf(
        "afterMeal" to BloodGlucoseRecord.RELATION_TO_MEAL_AFTER_MEAL,
        "beforeMeal" to BloodGlucoseRecord.RELATION_TO_MEAL_BEFORE_MEAL,
        "fasting" to BloodGlucoseRecord.RELATION_TO_MEAL_FASTING,
        "general" to BloodGlucoseRecord.RELATION_TO_MEAL_GENERAL,
        "unknown" to BloodGlucoseRecord.RELATION_TO_MEAL_UNKNOWN,
    )

    private val vo2MaxMeasurementMethod: Map<String, Int> = mapOf(
        "cooperTest" to Vo2MaxRecord.MEASUREMENT_METHOD_COOPER_TEST,
        "rateRatio" to Vo2MaxRecord.MEASUREMENT_METHOD_HEART_RATE_RATIO,
        "metabolicCart" to Vo2MaxRecord.MEASUREMENT_METHOD_METABOLIC_CART,
        "multistageFitnessTest" to Vo2MaxRecord.MEASUREMENT_METHOD_MULTISTAGE_FITNESS_TEST,
        "fitnessTest" to Vo2MaxRecord.MEASUREMENT_METHOD_ROCKPORT_FITNESS_TEST,
        "other" to Vo2MaxRecord.MEASUREMENT_METHOD_OTHER,
    )

    private val skinTemperatureMeasurementLocation: Map<String, Int> = mapOf(
        "finger" to SkinTemperatureRecord.MEASUREMENT_LOCATION_FINGER,
        "toe" to SkinTemperatureRecord.MEASUREMENT_LOCATION_TOE,
        "wrist" to SkinTemperatureRecord.MEASUREMENT_LOCATION_WRIST,
        "unknown" to SkinTemperatureRecord.MEASUREMENT_LOCATION_UNKNOWN,
    )

    private val mindfulnessSessionType: Map<String, Int> = mapOf(
        "breathing" to MindfulnessSessionRecord.MINDFULNESS_SESSION_TYPE_BREATHING,
        "meditation" to MindfulnessSessionRecord.MINDFULNESS_SESSION_TYPE_MEDITATION,
        "movement" to MindfulnessSessionRecord.MINDFULNESS_SESSION_TYPE_MOVEMENT,
        "music" to MindfulnessSessionRecord.MINDFULNESS_SESSION_TYPE_MUSIC,
        "unguided" to MindfulnessSessionRecord.MINDFULNESS_SESSION_TYPE_UNGUIDED,
        "unknown" to MindfulnessSessionRecord.MINDFULNESS_SESSION_TYPE_UNKNOWN,
    )

    private val menstruationFlow: Map<String, Int> = mapOf(
        "heavy" to MenstruationFlowRecord.FLOW_HEAVY,
        "light" to MenstruationFlowRecord.FLOW_LIGHT,
        "medium" to MenstruationFlowRecord.FLOW_MEDIUM,
        "unknown" to MenstruationFlowRecord.FLOW_UNKNOWN,
    )

    private val cervicalMucusAppearance: Map<String, Int> = mapOf(
        "dry" to CervicalMucusRecord.APPEARANCE_DRY,
        "sticky" to CervicalMucusRecord.APPEARANCE_STICKY,
        "creamy" to CervicalMucusRecord.APPEARANCE_CREAMY,
        "watery" to CervicalMucusRecord.APPEARANCE_WATERY,
        "eggWhite" to CervicalMucusRecord.APPEARANCE_EGG_WHITE,
        "unknown" to CervicalMucusRecord.APPEARANCE_UNKNOWN,
    )

    private val cervicalMucusSensation: Map<String, Int> = mapOf(
        "light" to CervicalMucusRecord.SENSATION_LIGHT,
        "medium" to CervicalMucusRecord.SENSATION_MEDIUM,
        "heavy" to CervicalMucusRecord.SENSATION_HEAVY,
        "unknown" to CervicalMucusRecord.SENSATION_UNKNOWN,
    )

    private val ovulationTestResult: Map<String, Int> = mapOf(
        "high" to OvulationTestRecord.RESULT_HIGH,
        "negative" to OvulationTestRecord.RESULT_NEGATIVE,
        "positive" to OvulationTestRecord.RESULT_POSITIVE,
        "inconclusive" to OvulationTestRecord.RESULT_INCONCLUSIVE,
    )

    private val sexualActivityProtection: Map<String, Int> = mapOf(
        "protected" to SexualActivityRecord.PROTECTION_USED_PROTECTED,
        "unprotected" to SexualActivityRecord.PROTECTION_USED_UNPROTECTED,
        "unknown" to SexualActivityRecord.PROTECTION_USED_UNKNOWN,
    )

    private val activityIntensityType: Map<String, Int> = mapOf(
        "moderate" to ActivityIntensityRecord.ACTIVITY_INTENSITY_TYPE_MODERATE,
        "vigorous" to ActivityIntensityRecord.ACTIVITY_INTENSITY_TYPE_VIGOROUS,
    )

    private val sleepSession: Map<String, Int> = mapOf(
        "inBed" to SleepSessionRecord.STAGE_TYPE_AWAKE_IN_BED,
        "outOfBed" to SleepSessionRecord.STAGE_TYPE_OUT_OF_BED,
        "sleeping" to SleepSessionRecord.STAGE_TYPE_SLEEPING,
        "awake" to SleepSessionRecord.STAGE_TYPE_AWAKE,
        "light" to SleepSessionRecord.STAGE_TYPE_LIGHT,
        "deep" to SleepSessionRecord.STAGE_TYPE_DEEP,
        "rem" to SleepSessionRecord.STAGE_TYPE_REM,
        "unknown" to SleepSessionRecord.STAGE_TYPE_UNKNOWN,
    )

    /**
     * Registry using Dart enum class names as keys (from runtimeType.toString()).
     *
     * Keys must match the Dart enum class names exactly (e.g., "CKMealType", "CKSpecimenSource").
     */
    private val registry: Map<String, Map<String, Int>> = mapOf(
        "CKBodyTemperatureMeasurementLocation" to bodyTemperatureMeasurementLocation,
        "CKSpecimenSource" to specimenSource,
        "CKMealType" to mealType,
        "CKRelationToMeal" to relationToMeal,
        "CKVo2MaxMeasurementMethod" to vo2MaxMeasurementMethod,
        "CKSkinTemperatureMeasurementLocation" to skinTemperatureMeasurementLocation,
        "CKMindfulnessSessionType" to mindfulnessSessionType,
        "CKMenstruationFlow" to menstruationFlow,
        "CKCervicalMucusAppearance" to cervicalMucusAppearance,
        "CKCervicalMucusSensation" to cervicalMucusSensation,
        "CKOvulationTestResult" to ovulationTestResult,
        "CKSexualActivityProtection" to sexualActivityProtection,
        "CKActivityIntensityType" to activityIntensityType,
        // NOTE: SleepSession is not a category enum in dart (no `CK` prefix)
        "SleepSession" to sleepSession, // Note: This might need to be CKSleepStage depending on Dart implementation
    )

    // ------------------------------------------------------------------------
    // Public API
    // ------------------------------------------------------------------------

    /**
     * Decodes a Dart enum string into its corresponding Android Int constant.
     *
     * @param category The category name (e.g. "SkinTemperatureMeasurementLocation").
     * @param value The Dart enum value string (e.g. "wrist").
     * @return The matching Android Int constant, or `null` if unknown.
     * @param categoryName The Dart enum class name (e.g. "CKMealType") - injected from Dart via runtimeType.toString()
     * @param value The Dart enum value string (e.g. "breakfast")
     * @return The matching Android Int constant, or `null` if unknown
     */
    fun decode(categoryName: String?, value: String?): Int? {
        if (categoryName == null || value == null) return null
        val categoryMap = registry[categoryName] ?: return null
        return categoryMap[value]
    }

    /**
     * Encodes an Android Int constant into its corresponding Dart enum string.
     *
     * @param categoryName The Dart enum class name (e.g. "CKMealType")
     * @param constant The Android constant value (e.g. MEAL_TYPE_BREAKFAST)
     * @return The Dart enum value string (e.g. "breakfast"), or `null` if unknown
     */
    fun encode(categoryName: String, constant: Int): String? {
        val categoryMap = registry[categoryName] ?: return null
        return categoryMap.entries.firstOrNull { it.value == constant }?.key
    }
}
