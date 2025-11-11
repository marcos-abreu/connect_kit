package dev.luix.connect_kit.mapper.records

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.NutritionRecord
import androidx.health.connect.client.records.MealType
import androidx.health.connect.client.units.*
import dev.luix.connect_kit.logging.CKLogger
import dev.luix.connect_kit.mapper.RecordMapperException
import dev.luix.connect_kit.utils.RecordMapperUtils
import dev.luix.connect_kit.utils.CKConstants
import dev.luix.connect_kit.mapper.CategoryMapper
import java.time.Instant
import java.time.ZoneOffset

/**
 * Responsible for translating between Pigeon message maps and [NutritionRecord] objects.
 *
 * This mapper handles both directions of data flow:
 * - **decode()**: Converts a Map<String, Any> received from Dart into a [NutritionRecord].
 * - **encode()** (future): Converts a [NutritionRecord] into a Map<String, Any> to send back to Dart.
 *
 * The decoding process validates required fields (e.g. `startTime`, `endTime`, `mealType`)
 * and parses optional data such as zone offsets and nutrient values.
 *
 * This class is intended to be used by the [RecordMapper], which delegates decoding
 * to this class when handling RECORD_KIND_NUTRITION
 *
 * **Example (decode flow):**
 * ```
 * RecordMapper
 *   └─> NutritionMapper.decode(map)
 * ```
 *
 * **Note:** The Health Connect client is injected for potential future use (e.g., checking feature availability),
 * even though it’s not required during decoding.
 *
 * @property healthConnectClient The Health Connect client instance.
 */
class NutritionMapper(
    private val healthConnectClient: HealthConnectClient,
    private val categoryMapper: CategoryMapper,
) {
    companion object {
        private const val TAG = CKConstants.TAG_NUTRITION_MAPPER
        private const val RECORD_KIND = CKConstants.RECORD_KIND_NUTRITION
        private const val TYPE = "Nutrition"
    }

    /**
     * Decodes a Pigeon message map into a [NutritionRecord].
     *
     * This function:
     * 1. Parses required timestamps (`startTime`, `endTime`) and validates their order.
     * 2. Parses optional zone offsets (`startZoneOffsetSeconds`, `endZoneOffsetSeconds`).
     * 3. Extracts basic attributes (`name`, `mealType`) and maps meal type strings to Health Connect constants.
     * 4. Parses optional nutrient fields (mass and energy units) using [RecordMapperUtils] helpers.
     * 5. Builds Health Connect [Metadata] including optional source information
     *
     * @param map The map received from the Dart layer representing a nutrition record.
     * @return A [NutritionRecord] instance ready for insertion into Health Connect.
     *
     * @throws RecordMapperException if required fields are missing or have invalid formats.
     */
    fun decode(map: Map<String, Any?>): NutritionRecord {
        // === Core times ===
        val startTimeStr = RecordMapperUtils.getRequiredString(map, "startTime", RECORD_KIND)
        val endTimeStr = RecordMapperUtils.getRequiredString(map, "endTime", RECORD_KIND)
        val startTime = RecordMapperUtils.parseInstant(startTimeStr, "startTime", RECORD_KIND)
        val endTime = RecordMapperUtils.parseInstant(endTimeStr, "endTime", RECORD_KIND)
        RecordMapperUtils.validateTimeOrder(startTime, endTime, RECORD_KIND)

        // === Zone offsets ===
        val startOffsetSeconds = RecordMapperUtils.getOptionalInt(map, "startZoneOffsetSeconds")
        val endOffsetSeconds = RecordMapperUtils.getOptionalInt(map, "endZoneOffsetSeconds")
        val startZoneOffset = startOffsetSeconds?.let(RecordMapperUtils::parseZoneOffset)
        val endZoneOffset = endOffsetSeconds?.let(RecordMapperUtils::parseZoneOffset)

        // === Basic attributes ===
        val name = RecordMapperUtils.getOptionalString(map, "name")

        val mealType = RecordMapperUtils.getOptionalString(map, "mealType")?.let { typeStr ->
            categoryMapper.decode("MealType", typeStr)
        } ?: MealType.MEAL_TYPE_UNKNOWN

        // === Nutrients ===
        fun massField(key: String): Mass? {
            val nutrientMap = RecordMapperUtils.getOptionalMap(map, key) ?: return null
            val value = RecordMapperUtils.getOptionalDouble(nutrientMap, "value")
                ?: return null
            val unit = nutrientMap["unit"] as? String
            return RecordMapperUtils.convertToMass(value, unit, RECORD_KIND)
        }

        fun energyField(key: String): Energy? {
            val energyMap = RecordMapperUtils.getOptionalMap(map, key) ?: return null
            val value = RecordMapperUtils.getOptionalDouble(energyMap, "value")
                ?: return null
            val unit = energyMap["unit"] as? String
            return RecordMapperUtils.convertToEnergy(value, unit, RECORD_KIND)
        }

        // Extract source and build metadata
        val sourceMap = RecordMapperUtils.getOptionalMap(map, "source")
        val metadata = RecordMapperUtils.buildMetadata(sourceMap)

        // === Build record ===
        return NutritionRecord(
            name = name,
            mealType = mealType,
            startTime = startTime,
            endTime = endTime,
            startZoneOffset = startZoneOffset,
            endZoneOffset = endZoneOffset,
            energy = energyField("energy"),
            protein = massField("protein"),
            totalCarbohydrate = massField("totalCarbohydrate"),
            totalFat = massField("totalFat"),
            dietaryFiber = massField("dietaryFiber"),
            sugar = massField("sugar"),
            saturatedFat = massField("saturatedFat"),
            unsaturatedFat = massField("unsaturatedFat"),
            monounsaturatedFat = massField("monounsaturatedFat"),
            polyunsaturatedFat = massField("polyunsaturatedFat"),
            transFat = massField("transFat"),
            cholesterol = massField("cholesterol"),
            calcium = massField("calcium"),
            chloride = massField("chloride"),
            chromium = massField("chromium"),
            copper = massField("copper"),
            iodine = massField("iodine"),
            iron = massField("iron"),
            magnesium = massField("magnesium"),
            manganese = massField("manganese"),
            molybdenum = massField("molybdenum"),
            phosphorus = massField("phosphorus"),
            potassium = massField("potassium"),
            selenium = massField("selenium"),
            sodium = massField("sodium"),
            zinc = massField("zinc"),
            vitaminA = massField("vitaminA"),
            vitaminB6 = massField("vitaminB6"),
            vitaminB12 = massField("vitaminB12"),
            vitaminC = massField("vitaminC"),
            vitaminD = massField("vitaminD"),
            vitaminE = massField("vitaminE"),
            vitaminK = massField("vitaminK"),
            thiamin = massField("thiamin"),
            riboflavin = massField("riboflavin"),
            niacin = massField("niacin"),
            folate = massField("folate"),
            biotin = massField("biotin"),
            pantothenicAcid = massField("pantothenicAcid"),
            metadata = metadata
        )
    }
}
