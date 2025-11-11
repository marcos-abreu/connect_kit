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

import dev.luix.connect_kit.utils.RecordMapperUtils.FieldData

/**
 * Maps category names and values between Dart strings and Android Health Connect constants.
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
        "vagina" to BodyTemperatureMeasurementLocation.MEASUREMENT_LOCATION_VAGINA,
        "wrist" to BodyTemperatureMeasurementLocation.MEASUREMENT_LOCATION_WRIST,
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
        "unusual" to CervicalMucusRecord.APPEARANCE_UNUSUAL,
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

    // Add more categories below:
    // private val sleepStageType = mapOf("awake" to SleepStageRecord.STAGE_AWAKE, ...)

    // Registry of all category maps
    private val registry: Map<String, Map<String, Int>> = mapOf(
        "BodyTemperatureMeasurementLocation" to bodyTemperatureMeasurementLocation,
        "SpecimenSource" to specimenSource,
        "MealType" to mealType,
        "RelationToMeal" to relationToMeal,
        "Vo2MaxMeasurementMethod" to vo2MaxMeasurementMethod,
        "SkinTemperatureMeasurementLocation" to skinTemperatureMeasurementLocation,
        "MindfulnessSessionType" to mindfulnessSessionType,
        "MenstruationFlow" to menstruationFlow,
        "CervicalMucusAppearance" to cervicalMucusAppearance,
        "CervicalMucusSensation" to cervicalMucusSensation,
        "OvulationTestResult" to ovulationTestResult,
        "SexualActivityProtection" to sexualActivityProtection,
        "ActivityIntensityType" to activityIntensityType,
        "SleepSession" to sleepSession,
        // "SleepStageType" to sleepStageType,
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
     */
    fun decode(category: String, value: String): Int? {
        val categoryMap = registry[category] ?: return null
        return categoryMap[value]
    }

    /**
     * Encodes an Android Int constant into its corresponding Dart enum string.
     *
     * @param category The category name (e.g. "SkinTemperatureMeasurementLocation").
     * @param constant The Android constant value (e.g. MEASUREMENT_LOCATION_WRIST).
     * @return The Dart enum string, or `null` if unknown.
     */
    fun encode(category: String, constant: Int): String? {
        val categoryMap = registry[category] ?: return null
        // Reverse lookup — find key by value
        return categoryMap.entries.firstOrNull { it.value == constant }?.key
    }


    /**
     * Decodes an optional category field from a map.
     *
     * This method is used to decode fields that are expected to be a category
     * (e.g., "specimenSource" in Blood Glucose records).
     *
     * @param valueMap The map containing the field
     * @param fieldName The name of the field
     * @param categoryMapperKey The key to use in the category mapper
     * @param type Record type, for logging/exception context
     * @return The decoded category value OR null
     * @throws RecordMapperException if the field is missing or invalid
     */
    fun decodeFromField(
        valueMap: Map<String, FieldData>,
        fieldName: String,
        categoryMapperKey: String, // e.g., "BodyTemperatureMeasurementLocation"
        recordKind: String,
        type: String
    ): Int? {
        return valueMap[fieldName]?.let { fieldData ->
            val rawValue = fieldData.value as? String
                ?: throw RecordMapperException(
                    "Expected String for '$fieldName' value, got ${fieldData.value::class.simpleName}",
                    recordKind,
                    type
                )
            decode(categoryMapperKey, rawValue)
                ?: throw RecordMapperException(
                    "Invalid '$fieldName' value: '$rawValue'",
                    recordKind,
                    type
                )
            // Return the successfully decoded Int constant
        }
    }
}
