package dev.luix.connect_kit.utils

import android.os.Build
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.HealthConnectFeatures
import androidx.health.connect.client.records.*
import dev.luix.connect_kit.logging.CKLogger
import kotlin.reflect.KClass

/**
 * RecordTypeMapper
 *
 * Maps generic string identifiers to Android Health Connect Record classes.
 * Handles SDK version checking and Health Connect feature availability.
 */
object RecordTypeMapper {
    private const val TAG = "RecordTypeMapper"

    /**
     * Metadata about a Health Connect record type including version and feature requirements
     */
    private data class RecordMapping(
        val recordClass: KClass<out Record>,
        val minSdkVersion: Int = Build.VERSION_CODES.UPSIDE_DOWN_CAKE, // API 34 (Android 14)
        val requiredFeature: Int? = null // Health Connect feature flag if needed
    )

    // Map of Dart identifiers to Health Connect Record classes with metadata
    private val RECORD_TYPE_MAP: Map<String, RecordMapping> = mapOf(
        // --- Activity & Fitness ---
        "steps" to RecordMapping(StepsRecord::class),
        "distance" to RecordMapping(DistanceRecord::class),
        "activeCalories" to RecordMapping(ActiveCaloriesBurnedRecord::class),
        "totalCalories" to RecordMapping(TotalCaloriesBurnedRecord::class),
        "restingCalories" to RecordMapping(BasalMetabolicRateRecord::class),
        "floorsClimbed" to RecordMapping(FloorsClimbedRecord::class),

        // --- Vitals ---
        "heartRate" to RecordMapping(HeartRateRecord::class),
        "restingHeartRate" to RecordMapping(RestingHeartRateRecord::class),
        "bodyTemperature" to RecordMapping(BodyTemperatureRecord::class),
        "skinTemperature" to RecordMapping(
            SkinTemperatureRecord::class,
            requiredFeature = HealthConnectFeatures.FEATURE_SKIN_TEMPERATURE
        ),
        "respiratoryRate" to RecordMapping(RespiratoryRateRecord::class),
        "oxygenSaturation" to RecordMapping(OxygenSaturationRecord::class),
        "bloodGlucose" to RecordMapping(BloodGlucoseRecord::class),

        // --- Body Measurements ---
        "height" to RecordMapping(HeightRecord::class),
        "weight" to RecordMapping(WeightRecord::class),
        "bodyFat" to RecordMapping(BodyFatRecord::class),
        "leanBodyMass" to RecordMapping(LeanBodyMassRecord::class),

        // --- Blood Pressure ---
        "bloodPressure.systolic" to RecordMapping(BloodPressureRecord::class),
        "bloodPressure.diastolic" to RecordMapping(BloodPressureRecord::class),

        // --- Nutrition ---
        "nutrition.calories" to RecordMapping(NutritionRecord::class),
        "nutrition.protein" to RecordMapping(NutritionRecord::class),
        "nutrition.carbs" to RecordMapping(NutritionRecord::class),
        "nutrition.fat" to RecordMapping(NutritionRecord::class),

        // --- Hydration ---
        "waterIntake" to RecordMapping(HydrationRecord::class),

        // --- Sleep & Wellness ---
        "sleepAnalysis" to RecordMapping(SleepSessionRecord::class),
        "mindfulSession" to RecordMapping(
            MindfulnessSessionRecord::class,
            requiredFeature = HealthConnectFeatures.FEATURE_MINDFULNESS_SESSION
        ),

        // --- Reproductive Health ---
        "menstrualFlow" to RecordMapping(MenstruationFlowRecord::class),

        // --- Workouts ---
        "workout" to RecordMapping(ExerciseSessionRecord::class),
        "workout.distance" to RecordMapping(DistanceRecord::class),
        "workout.heartRate" to RecordMapping(HeartRateRecord::class),
        "workout.calories" to RecordMapping(ActiveCaloriesBurnedRecord::class),
    )

    /**
     * Retrieves the Health Connect Record class for a given type identifier.
     *
     * Performs validation:
     * 1. Type exists in mapping
     * 2. SDK version supports the record type
     * 3. Health Connect feature is available (if required)
     *
     * @param recordType The string identifier from Dart/Pigeon
     * @param healthConnectClient Optional client for feature checking (pass null to skip feature check)
     * @return KClass<out Record>? The Record class, or null if unsupported
     */
    fun getRecordClass(
        recordType: String,
        healthConnectClient: HealthConnectClient? = null
    ): KClass<out Record>? {
        // 1. Check if type exists in mapping
        val mapping = RECORD_TYPE_MAP[recordType]

        if (mapping == null) {
            CKLogger.w(
                tag = TAG,
                message = "Unknown record type: '$recordType'"
            )
            return null
        }

        // 2. Check SDK version availability
        if (Build.VERSION.SDK_INT < mapping.minSdkVersion) {
            CKLogger.w(
                tag = TAG,
                message = "Record type '$recordType' requires API ${mapping.minSdkVersion}, " +
                        "but device is running API ${Build.VERSION.SDK_INT}"
            )
            return null
        }

        // 3. Check Health Connect feature availability (if required and client provided)
        if (mapping.requiredFeature != null && healthConnectClient != null) {
            val featureStatus = try {
                healthConnectClient.features.getFeatureStatus(mapping.requiredFeature)
            } catch (e: Exception) {
                CKLogger.w(
                    tag = TAG,
                    message = "Failed to check feature status for '$recordType': ${e.message}"
                )
                HealthConnectFeatures.FEATURE_STATUS_UNAVAILABLE
            }

            if (featureStatus != HealthConnectFeatures.FEATURE_STATUS_AVAILABLE) {
                CKLogger.w(
                    tag = TAG,
                    message = "Record type '$recordType' requires Health Connect feature " +
                            "'${mapping.requiredFeature}' which is not available on this device. " +
                            "User may need to update Health Connect."
                )
                return null
            }
        }

        return mapping.recordClass
    }

    /**
     * Checks if a record type is supported and available on current device.
     * Does NOT check Health Connect features (requires client instance).
     */
    fun isSupported(recordType: String): Boolean {
        val mapping = RECORD_TYPE_MAP[recordType] ?: return false
        return Build.VERSION.SDK_INT >= mapping.minSdkVersion
    }

    /**
     * Gets all record type identifiers that meet basic requirements (SDK version).
     * Does NOT filter by Health Connect feature availability.
     */
    fun getSupportedTypes(): Set<String> {
        return RECORD_TYPE_MAP.filterValues { mapping ->
            Build.VERSION.SDK_INT >= mapping.minSdkVersion
        }.keys
    }

    /**
     * Returns explanation for why a type is unsupported.
     */
    fun getUnsupportedReason(
        recordType: String,
        healthConnectClient: HealthConnectClient? = null
    ): String {
        val mapping = RECORD_TYPE_MAP[recordType]

        return when {
            mapping == null -> "Record type not recognized by Health Connect"
            Build.VERSION.SDK_INT < mapping.minSdkVersion ->
                "Requires Android API ${mapping.minSdkVersion} (device has ${Build.VERSION.SDK_INT})"

            mapping.requiredFeature != null && healthConnectClient != null -> {
                val status = try {
                    healthConnectClient.features.getFeatureStatus(mapping.requiredFeature)
                } catch (e: Exception) {
                    HealthConnectFeatures.FEATURE_STATUS_UNAVAILABLE
                }

                if (status != HealthConnectFeatures.FEATURE_STATUS_AVAILABLE) {
                    "Requires Health Connect feature '${mapping.requiredFeature}' - user needs to update Health Connect"
                } else {
                    "Unknown reason"
                }
            }

            else -> "Unknown reason"
        }
    }

    /**
     * Checks if a type requires a Health Connect feature flag.
     */
    fun requiresFeature(recordType: String): Boolean {
        return RECORD_TYPE_MAP[recordType]?.requiredFeature != null
    }

    /**
     * Gets the required feature flag for a type, if any.
     */
    fun getRequiredFeature(recordType: String): Int? {
        return RECORD_TYPE_MAP[recordType]?.requiredFeature
    }
}
