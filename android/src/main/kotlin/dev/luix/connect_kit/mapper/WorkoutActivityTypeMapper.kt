package dev.luix.connect_kit.mapper

import androidx.health.connect.client.records.ExerciseSessionRecord
import dev.luix.connect_kit.logging.CKLogger
import dev.luix.connect_kit.utils.CKConstants

/**
 * Maps Dart workout activity type strings to Android Health Connect constants.
 */
object WorkoutActivityTypeMapper {
    private const val TAG = "WorkoutActivityTypeMapper"

    /**
     * Maps a string representation of a workout activity to Health Connect constants.
     *
     * @param typeName The activity type name from Dart.
     * @return The integer constant corresponding to [ExerciseSessionRecord] activity type.
     */
    fun map(typeName: String): Int {
        return when (typeName.lowercase()) {
            "badminton" -> ExerciseSessionRecord.EXERCISE_TYPE_BADMINTON
            "baseball" -> ExerciseSessionRecord.EXERCISE_TYPE_BASEBALL
            "basketball" -> ExerciseSessionRecord.EXERCISE_TYPE_BASKETBALL
            "biking" -> ExerciseSessionRecord.EXERCISE_TYPE_BIKING
            "biking_stationary" -> ExerciseSessionRecord.EXERCISE_TYPE_BIKING_STATIONARY
            "boot_camp" -> ExerciseSessionRecord.EXERCISE_TYPE_BOOT_CAMP
            "boxing" -> ExerciseSessionRecord.EXERCISE_TYPE_BOXING
            "calisthenics" -> ExerciseSessionRecord.EXERCISE_TYPE_CALISTHENICS
            "cricket" -> ExerciseSessionRecord.EXERCISE_TYPE_CRICKET
            "dancing" -> ExerciseSessionRecord.EXERCISE_TYPE_DANCING
            "elliptical" -> ExerciseSessionRecord.EXERCISE_TYPE_ELLIPTICAL
            "exercise_class" -> ExerciseSessionRecord.EXERCISE_TYPE_EXERCISE_CLASS
            "fencing" -> ExerciseSessionRecord.EXERCISE_TYPE_FENCING
            "football_american" -> ExerciseSessionRecord.EXERCISE_TYPE_FOOTBALL_AMERICAN
            "football_australian" -> ExerciseSessionRecord.EXERCISE_TYPE_FOOTBALL_AUSTRALIAN
            "frisbee_disc" -> ExerciseSessionRecord.EXERCISE_TYPE_FRISBEE_DISC
            "golf" -> ExerciseSessionRecord.EXERCISE_TYPE_GOLF
            "guided_breathing" -> ExerciseSessionRecord.EXERCISE_TYPE_GUIDED_BREATHING
            "gymnastics" -> ExerciseSessionRecord.EXERCISE_TYPE_GYMNASTICS
            "handball" -> ExerciseSessionRecord.EXERCISE_TYPE_HANDBALL
            "high_intensity_interval_training" -> ExerciseSessionRecord.EXERCISE_TYPE_HIGH_INTENSITY_INTERVAL_TRAINING
            "hiking" -> ExerciseSessionRecord.EXERCISE_TYPE_HIKING
            "ice_hockey" -> ExerciseSessionRecord.EXERCISE_TYPE_ICE_HOCKEY
            "ice_skating" -> ExerciseSessionRecord.EXERCISE_TYPE_ICE_SKATING
            "martial_arts" -> ExerciseSessionRecord.EXERCISE_TYPE_MARTIAL_ARTS
            "paddling" -> ExerciseSessionRecord.EXERCISE_TYPE_PADDLING
            "paragliding" -> ExerciseSessionRecord.EXERCISE_TYPE_PARAGLIDING
            "pilates" -> ExerciseSessionRecord.EXERCISE_TYPE_PILATES
            "racquetball" -> ExerciseSessionRecord.EXERCISE_TYPE_RACQUETBALL
            "rock_climbing" -> ExerciseSessionRecord.EXERCISE_TYPE_ROCK_CLIMBING
            "roller_hockey" -> ExerciseSessionRecord.EXERCISE_TYPE_ROLLER_HOCKEY
            "rowing" -> ExerciseSessionRecord.EXERCISE_TYPE_ROWING
            "rowing_machine" -> ExerciseSessionRecord.EXERCISE_TYPE_ROWING_MACHINE
            "rugby" -> ExerciseSessionRecord.EXERCISE_TYPE_RUGBY
            "running" -> ExerciseSessionRecord.EXERCISE_TYPE_RUNNING
            "running_treadmill" -> ExerciseSessionRecord.EXERCISE_TYPE_RUNNING_TREADMILL
            "sailing" -> ExerciseSessionRecord.EXERCISE_TYPE_SAILING
            "scuba_diving" -> ExerciseSessionRecord.EXERCISE_TYPE_SCUBA_DIVING
            "skating" -> ExerciseSessionRecord.EXERCISE_TYPE_SKATING
            "skiing" -> ExerciseSessionRecord.EXERCISE_TYPE_SKIING
            "snowboarding" -> ExerciseSessionRecord.EXERCISE_TYPE_SNOWBOARDING
            "snowshoeing" -> ExerciseSessionRecord.EXERCISE_TYPE_SNOWSHOEING
            "soccer" -> ExerciseSessionRecord.EXERCISE_TYPE_SOCCER
            "softball" -> ExerciseSessionRecord.EXERCISE_TYPE_SOFTBALL
            "squash" -> ExerciseSessionRecord.EXERCISE_TYPE_SQUASH
            "stair_climbing" -> ExerciseSessionRecord.EXERCISE_TYPE_STAIR_CLIMBING
            "stair_climbing_machine" -> ExerciseSessionRecord.EXERCISE_TYPE_STAIR_CLIMBING_MACHINE
            "strength_training" -> ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING
            "stretching" -> ExerciseSessionRecord.EXERCISE_TYPE_STRETCHING
            "surfing" -> ExerciseSessionRecord.EXERCISE_TYPE_SURFING
            "swimming_open_water" -> ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_OPEN_WATER
            "swimming_pool" -> ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL
            "table_tennis" -> ExerciseSessionRecord.EXERCISE_TYPE_TABLE_TENNIS
            "tennis" -> ExerciseSessionRecord.EXERCISE_TYPE_TENNIS
            "volleyball" -> ExerciseSessionRecord.EXERCISE_TYPE_VOLLEYBALL
            "walking" -> ExerciseSessionRecord.EXERCISE_TYPE_WALKING
            "water_polo" -> ExerciseSessionRecord.EXERCISE_TYPE_WATER_POLO
            "weightlifting" -> ExerciseSessionRecord.EXERCISE_TYPE_WEIGHTLIFTING
            "wheelchair" -> ExerciseSessionRecord.EXERCISE_TYPE_WHEELCHAIR
            "yoga" -> ExerciseSessionRecord.EXERCISE_TYPE_YOGA
            "other_workout" -> ExerciseSessionRecord.EXERCISE_TYPE_OTHER_WORKOUT
            else -> {
                CKLogger.d(TAG, "Unknown workout activity type '$typeName', defaulting to OTHER")
                ExerciseSessionRecord.EXERCISE_TYPE_OTHER_WORKOUT
            }
        }
    }
}
