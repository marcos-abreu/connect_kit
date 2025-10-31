# ConnectKit Blood Pressure & Nutrition Records - Cross-Platform Research

## Document Purpose
Comprehensive research on nutrition tracking capabilities across iOS HealthKit and Android Health Connect to design unified `CKNutrition` model.

---

## Executive Summary

**Key Findings:**

| Aspect | iOS HealthKit | Android Health Connect |
|--------|---------------|------------------------|
| **Name** | Dietary (various types) | NutritionRecord |
| **Structure** | Separate samples per nutrient | Single record with all nutrients |
| **Nutrients** | 40+ nutrient types | 30+ nutrient fields |
| **Meal Info** | Via metadata | Built-in `mealType` field |
| **Complexity** | High (many separate samples) | Medium (many optional fields) |

**Recommendation**: Create unified `CKNutrition` model with comprehensive nutrient support.

---

## iOS HealthKit Nutrition

### Structure Overview

iOS uses separate `HKQuantityType` identifiers for each nutrient. Common types include:

**Energy & Macros:**
- `dietaryEnergyConsumed` - Total energy
- `dietaryProtein` - Protein in grams
- `dietaryCarbohydrates` - Carbs in grams
- `dietaryFatTotal` - Total fat in grams
- `dietaryFiber` - Fiber in grams
- `dietarySugar` - Sugar in grams

**Fat Breakdown:**
- `dietaryFatSaturated` - Saturated fat
- `dietaryFatMonounsaturated` - Monounsaturated fat
- `dietaryFatPolyunsaturated` - Polyunsaturated fat
- `dietaryCholesterol` - Cholesterol

**Vitamins & Minerals:**
- `dietaryVitaminA`, `dietaryVitaminC`, `dietaryVitaminD`, etc.
- `dietaryCalcium`, `dietaryIron`, `dietarySodium`, etc.

### Data Structure

**Saving Nutrition Data:**
```swift
func saveNutritionData() {
    let now = Date()
    var samples: [HKQuantitySample] = []

    // Calories
    let energyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
    let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: 450.0)
    let energySample = HKQuantitySample(
        type: energyType,
        quantity: energyQuantity,
        start: now,
        end: now,
        metadata: [
            HKMetadataKeyFoodType: "Chicken Salad",
            "mealType": "lunch"
        ]
    )
    samples.append(energySample)

    // Protein
    let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
    let proteinQuantity = HKQuantity(unit: .gram(), doubleValue: 30.0)
    let proteinSample = HKQuantitySample(
        type: proteinType,
        quantity: proteinQuantity,
        start: now,
        end: now,
        metadata: [HKMetadataKeyFoodType: "Chicken Salad"]
    )
    samples.append(proteinSample)

    // Carbs
    let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!
    let carbsQuantity = HKQuantity(unit: .gram(), doubleValue: 25.0)
    let carbsSample = HKQuantitySample(
        type: carbsType,
        quantity: carbsQuantity,
        start: now,
        end: now,
        metadata: [HKMetadataKeyFoodType: "Chicken Salad"]
    )
    samples.append(carbsSample)

    // Fat
    let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
    let fatQuantity = HKQuantity(unit: .gram(), doubleValue: 15.0)
    let fatSample = HKQuantitySample(
        type: fatType,
        quantity: fatQuantity,
        start: now,
        end: now,
        metadata: [HKMetadataKeyFoodType: "Chicken Salad"]
    )
    samples.append(fatSample)

    // Save all samples
    healthStore.save(samples) { success, error in
        // Handle completion
    }
}
```

### Key Characteristics

1. **Multiple Samples**: Each nutrient is a separate sample
2. **Meal Association**: Use metadata with `HKMetadataKeyFoodType` to group
3. **Same Timestamp**: Use same start/end date for items from same meal
4. **Flexible Units**: Can use various units (g, mg, mcg, IU, etc.)
5. **No Built-in Meal Type**: Must use custom metadata

### Gotchas

⚠️ **Gotcha #1: No Meal Container**
- No correlation or meal object to group nutrients
- Must use matching timestamps + metadata to associate
- Common pattern: Use same `HKMetadataKeyFoodType` value

⚠️ **Gotcha #2: Many Permission Types**
- Need permission for EACH nutrient type separately
- Requesting 10+ permissions can overwhelm users
- Best practice: Request only commonly used nutrients

⚠️ **Gotcha #3: Aggregation Required**
- To get total energy for a day, must query and sum
- No built-in meal-level aggregation

---


## Android Health Connect Nutrition

### Structure Overview

<cite index="23-1">Android uses `NutritionRecord` - a single interval record containing all nutrients as optional fields</cite>. Each record represents a meal or food item consumed over a time period.

### Available Fields

**Basic Info:**
- `name` - Name of food item (optional String)
- `mealType` - Type of meal (breakfast, lunch, dinner, snack, unknown)

**Energy & Macros:**
- `energy` - Total energy in Energy units
- `protein` - Protein in Mass units (grams)
- `totalCarbohydrate` - Total carbs in Mass units
- `totalFat` - Total fat in Mass units
- `dietaryFiber` - Fiber in Mass units
- `sugar` - Sugar in Mass units

**Fat Breakdown:**
- `saturatedFat` - Saturated fat in Mass units
- `unsaturatedFat` - Unsaturated fat in Mass units
- `monounsaturatedFat` - Monounsaturated fat in Mass units
- `polyunsaturatedFat` - Polyunsaturated fat in Mass units
- `transFat` - Trans fat in Mass units
- `cholesterol` - Cholesterol in Mass units

**Minerals:**
- `calcium`, `chloride`, `chromium`, `copper`, `iodine`, `iron`, `magnesium`, `manganese`,`molybdenum`, `phosphorus`, `potassium`, `selenium`, `sodium`, `zinc`

**Vitamins:**
- `vitaminA`, `vitaminB6`, `vitaminB12`, `vitaminC`, `vitaminD`, `vitaminE`, `vitaminK`, `thiamin` (B1), `riboflavin` (B2), `niacin` (B3), `folate`, `biotin`, `pantothenicAcid`

### Data Structure

**Creating Nutrition Record:**
```kotlin
val endTime = Instant.now()
val startTime = endTime.minus(Duration.ofMinutes(15))

val meal = NutritionRecord(
    name = "Grilled Chicken Salad",
    mealType = NutritionRecord.MEAL_TYPE_LUNCH,
    startTime = startTime,
    endTime = endTime,
    startZoneOffset = ZoneOffset.systemDefault(),
    endZoneOffset = ZoneOffset.systemDefault(),

    // Energy & macros
    energy = 450.0.kilocalories,
    protein = 35.0.grams,
    totalCarbohydrate = 25.0.grams,
    totalFat = 20.0.grams,
    dietaryFiber = 5.0.grams,
    sugar = 8.0.grams,

    // Fat breakdown
    saturatedFat = 4.0.grams,
    unsaturatedFat = 12.0.grams,
    cholesterol = 0.085.grams,

    // Minerals
    sodium = 0.8.grams,
    potassium = 0.650.grams,
    calcium = 0.150.grams,
    iron = 0.003.grams,

    // Vitamins
    vitaminA = 0.0005.grams,
    vitaminC = 0.025.grams,
    vitaminD = 0.000005.grams,

    metadata = Metadata.manuallyEntered()
)

healthConnectClient.insertRecords(listOf(meal))
```

### Meal Type Constants

```kotlin
NutritionRecord.MEAL_TYPE_UNKNOWN
NutritionRecord.MEAL_TYPE_BREAKFAST
NutritionRecord.MEAL_TYPE_LUNCH
NutritionRecord.MEAL_TYPE_DINNER
NutritionRecord.MEAL_TYPE_SNACK
```

### Reading Nutrition Data

```kotlin
suspend fun readNutrition(
    healthConnectClient: HealthConnectClient,
    startTime: Instant,
    endTime: Instant
): List<NutritionRecord> {
    val request = ReadRecordsRequest(
        recordType = NutritionRecord::class,
        timeRangeFilter = TimeRangeFilter.between(startTime, endTime)
    )

    val response = healthConnectClient.readRecords(request)

    for (record in response.records) {
        println("${record.name ?: "Unnamed"} - ${record.mealType}")
        record.energy?.let { println("  Energy: ${it.inKilocalories} kcal") }
        record.protein?.let { println("  Protein: ${it.inGrams} g") }
        record.totalCarbohydrate?.let { println("  Carbs: ${it.inGrams} g") }
        record.totalFat?.let { println("  Fat: ${it.inGrams} g") }
    }

    return response.records
}
```

### Key Characteristics

1. **Single Record Per Meal**: All nutrients in one record
2. **All Fields Optional**: Only energy is commonly required by apps
3. **Interval Record**: Has start and end time (eating duration)
4. **Meal Type Built-in**: No need for metadata
5. **Strongly Typed Units**: Mass for nutrients, Energy for calories
6. **Comprehensive**: 30+ nutrient fields supported

### Gotchas

⚠️ **Gotcha #1: All Nutrients Optional**
- No required fields except timestamps
- Apps may provide varying levels of detail
- Must handle null checks for all nutrients

⚠️ **Gotcha #2: Unit Conversions**
- All nutrients use Mass type (grams, milligrams, micrograms)
- Must convert: `15.0.grams`, `0.5.milligrams`, `25.micrograms`
- Energy uses Energy type: `450.kilocalories` or `1880.kilojoules`

⚠️ **Gotcha #3: Interval vs Instantaneous**
- Unlike iOS, nutrition has a duration (start to end)
- Represents time spent eating
- For instantaneous entry, use same start/end time

---

## Platform Comparison - Nutrition

| Aspect | iOS HealthKit | Android Health Connect |
|--------|---------------|------------------------|
| **Structure** | Multiple samples | Single record |
| **Fields** | 40+ separate types | 30+ optional fields |
| **Meal Association** | Via metadata | Built-in `mealType` |
| **Duration** | Instantaneous only | Interval (eating duration) |
| **Permission** | Per-nutrient | Single `NutritionRecord` |
| **Name/Description** | Via metadata | Built-in `name` field |

## Proposed CKNutrition Model

```dart
/// Nutrition/food record with comprehensive nutrient tracking
///
/// **Platform Behavior:**
/// - **Android**: Maps to single `NutritionRecord` with all nutrients
/// - **iOS**: Maps to multiple `HKQuantitySample` objects (one per nutrient)
class CKNutrition extends CKRecord {
  /// Name/description of the food or meal
  final String? name;

  /// Type of meal
  final CKMealType? mealType;

  /// Energy content (calories)
  final CKValue? energy;

  /// Macro nutrients
  final CKValue? protein;
  final CKValue? totalCarbohydrate;
  final CKValue? totalFat;
  final CKValue? dietaryFiber;
  final CKValue? sugar;

  /// Fat breakdown
  final CKValue? saturatedFat;
  final CKValue? unsaturatedFat;
  final CKValue? monounsaturatedFat;
  final CKValue? polyunsaturatedFat;
  final CKValue? transFat;
  final CKValue? cholesterol;

  /// Minerals (all optional)
  final CKValue? calcium;
  final CKValue? chloride;
  final CKValue? chromium;
  final CKValue? copper;
  final CKValue? iodine;
  final CKValue? iron;
  final CKValue? magnesium;
  final CKValue? manganese;
  final CKValue? molybdenum;
  final CKValue? phosphorus;
  final CKValue? potassium;
  final CKValue? selenium;
  final CKValue? sodium;
  final CKValue? zinc;

  /// Vitamins (all optional)
  final CKValue? vitaminA;
  final CKValue? vitaminB6;
  final CKValue? vitaminB12;
  final CKValue? vitaminC;
  final CKValue? vitaminD;
  final CKValue? vitaminE;
  final CKValue? vitaminK;
  final CKValue? thiamin;      // B1
  final CKValue? riboflavin;   // B2
  final CKValue? niacin;       // B3
  final CKValue? folate;       // B9
  final CKValue? biotin;       // B7
  final CKValue? pantothenicAcid; // B5

  const CKNutrition({
    super.id,
    required super.startTime,
    required super.endTime,
    super.startZoneOffset,
    super.endZoneOffset,
    super.source,
    super.metadata,
    this.name,
    this.mealType,
    this.energy,
    this.protein,
    this.totalCarbohydrate,
    this.totalFat,
    this.dietaryFiber,
    this.sugar,
    this.saturatedFat,
    this.unsaturatedFat,
    this.monounsaturatedFat,
    this.polyunsaturatedFat,
    this.transFat,
    this.cholesterol,
    this.calcium,
    this.chloride,
    this.chromium,
    this.copper,
    this.iodine,
    this.iron,
    this.magnesium,
    this.manganese,
    this.molybdenum,
    this.phosphorus,
    this.potassium,
    this.selenium,
    this.sodium,
    this.zinc,
    this.vitaminA,
    this.vitaminB6,
    this.vitaminB12,
    this.vitaminC,
    this.vitaminD,
    this.vitaminE,
    this.vitaminK,
    this.thiamin,
    this.riboflavin,
    this.niacin,
    this.folate,
    this.biotin,
    this.pantothenicAcid,
  });

  /// Create simple nutrition entry with just macros
  factory CKNutrition.macros({
    required DateTime time,
    Duration? zoneOffset,
    required CKSource source,
    String? name,
    CKMealType? mealType,
    CKValue? energy,
    CKValue? protein,
    CKValue? carbs,
    CKValue? fat,
    Map<String, Object>? metadata,
  }) {
    return CKNutrition(
      startTime: time,
      endTime: time,
      startZoneOffset: zoneOffset,
      endZoneOffset: zoneOffset,
      source: source,
      name: name,
      mealType: mealType,
      energy: energy,
      protein: protein,
      totalCarbohydrate: carbs,
      totalFat: fat,
      metadata: metadata,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      if (id != null) 'id': id,
      'recordType': 'nutrition',
      if (name != null) 'name': name,
      if (mealType != null) 'mealType': mealType!.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'startZoneOffsetSeconds': startZoneOffset.inSeconds,
      'endZoneOffsetSeconds': endZoneOffset.inSeconds,
      if (source != null) 'source': source!.toMap(),
      if (metadata != null) 'metadata': metadata,
    };

    // Add all non-null nutrients
    void addNutrient(String key, CKValue? value) {
      if (value != null) map[key] = value.toMap();
    }

    addNutrient('energy', energy);
    addNutrient('protein', protein);
    addNutrient('totalCarbohydrate', totalCarbohydrate);
    addNutrient('totalFat', totalFat);
    addNutrient('dietaryFiber', dietaryFiber);
    addNutrient('sugar', sugar);
    addNutrient('saturatedFat', saturatedFat);
    addNutrient('unsaturatedFat', unsaturatedFat);
    addNutrient('monounsaturatedFat', monounsaturatedFat);
    addNutrient('polyunsaturatedFat', polyunsaturatedFat);
    addNutrient('transFat', transFat);
    addNutrient('cholesterol', cholesterol);
    addNutrient('calcium', calcium);
    addNutrient('chloride', chloride);
    addNutrient('chromium', chromium);
    addNutrient('copper', copper);
    addNutrient('iodine', iodine);
    addNutrient('iron', iron);
    addNutrient('magnesium', magnesium);
    addNutrient('manganese', manganese);
    addNutrient('molybdenum', molybdenum);
    addNutrient('phosphorus', phosphorus);
    addNutrient('potassium', potassium);
    addNutrient('selenium', selenium);
    addNutrient('sodium', sodium);
    addNutrient('zinc', zinc);
    addNutrient('vitaminA', vitaminA);
    addNutrient('vitaminB6', vitaminB6);
    addNutrient('vitaminB12', vitaminB12);
    addNutrient('vitaminC', vitaminC);
    addNutrient('vitaminD', vitaminD);
    addNutrient('vitaminE', vitaminE);
    addNutrient('vitaminK', vitaminK);
    addNutrient('thiamin', thiamin);
    addNutrient('riboflavin', riboflavin);
    addNutrient('niacin', niacin);
    addNutrient('folate', folate);
    addNutrient('biotin', biotin);
    addNutrient('pantothenicAcid', pantothenicAcid);

    return map;
  }
}

/// Meal type classification
enum CKMealType {
  /// Breakfast meal
  breakfast,

  /// Lunch meal
  lunch,

  /// Dinner meal
  dinner,

  /// Snack between meals
  snack,

  /// Unknown or unspecified meal type
  unknown;
}
```

## Native Implementation - Nutrition

**Android Decoder (Simplified):**
```kotlin
fun decodeNutrition(map: Map<String, Any>): NutritionRecord {
    val name = map["name"] as? String
    val mealType = (map["mealType"] as? String)?.let { mapMealType(it) }
        ?: NutritionRecord.MEAL_TYPE_UNKNOWN

    val startTime = Instant.parse(map["startTime"] as String)
    val endTime = Instant.parse(map["endTime"] as String)
    val startOffset = ZoneOffset.ofTotalSeconds(map["startZoneOffsetSeconds"] as Int)
    val endOffset = ZoneOffset.ofTotalSeconds(map["endZoneOffsetSeconds"] as Int)

    // Helper to extract nutrient value
    fun getMass(key: String): Mass? {
        val nutrientMap = map[key] as? Map<String, Any> ?: return null
        val value = (nutrientMap["value"] as Number).toDouble()
        val unit = nutrientMap["unit"] as String
        return when (unit.lowercase()) {
            "g", "gram", "grams" -> value.grams
            "mg", "milligram", "milligrams" -> value.milligrams
            "mcg", "microgram", "micrograms", "μg" -> value.micrograms
            else -> value.grams // default
        }
    }

    fun getEnergy(key: String): Energy? {
        val energyMap = map[key] as? Map<String, Any> ?: return null
        val value = (energyMap["value"] as Number).toDouble()
        val unit = energyMap["unit"] as String
        return when (unit.lowercase()) {
            "kcal", "kilocalorie", "kilocalories" -> value.kilocalories
            "kj", "kilojoule", "kilojoules" -> value.kilojoules
            "cal", "calorie", "calories" -> (value / 1000).kilocalories
            else -> value.kilocalories // default
        }
    }

    val source = map["source"] as? Map<String, Any>
    val metadata = buildMetadata(source)

    return NutritionRecord(
        name = name,
        mealType = mealType,
        startTime = startTime,
        endTime = endTime,
        startZoneOffset = startOffset,
        endZoneOffset = endOffset,
        energy = getEnergy("energy"),
        protein = getMass("protein"),
        totalCarbohydrate = getMass("totalCarbohydrate"),
        totalFat = getMass("totalFat"),
        dietaryFiber = getMass("dietaryFiber"),
        sugar = getMass("sugar"),
        saturatedFat = getMass("saturatedFat"),
        unsaturatedFat = getMass("unsaturatedFat"),
        monounsaturatedFat = getMass("monounsaturatedFat"),
        polyunsaturatedFat = getMass("polyunsaturatedFat"),
        transFat = getMass("transFat"),
        cholesterol = getMass("cholesterol"),
        calcium = getMass("calcium"),
        chloride = getMass("chloride"),
        chromium = getMass("chromium"),
        copper = getMass("copper"),
        iodine = getMass("iodine"),
        iron = getMass("iron"),
        magnesium = getMass("magnesium"),
        manganese = getMass("manganese"),
        molybdenum = getMass("molybdenum"),
        phosphorus = getMass("phosphorus"),
        potassium = getMass("potassium"),
        selenium = getMass("selenium"),
        sodium = getMass("sodium"),
        zinc = getMass("zinc"),
        vitaminA = getMass("vitaminA"),
        vitaminB6 = getMass("vitaminB6"),
        vitaminB12 = getMass("vitaminB12"),
        vitaminC = getMass("vitaminC"),
        vitaminD = getMass("vitaminD"),
        vitaminE = getMass("vitaminE"),
        vitaminK = getMass("vitaminK"),
        thiamin = getMass("thiamin"),
        riboflavin = getMass("riboflavin"),
        niacin = getMass("niacin"),
        folate = getMass("folate"),
        biotin = getMass("biotin"),
        pantothenicAcid = getMass("pantothenicAcid"),
        metadata = metadata
    )
}

private fun mapMealType(type: String): Int {
    return when (type) {
        "breakfast" -> NutritionRecord.MEAL_TYPE_BREAKFAST
        "lunch" -> NutritionRecord.MEAL_TYPE_LUNCH
        "dinner" -> NutritionRecord.MEAL_TYPE_DINNER
        "snack" -> NutritionRecord.MEAL_TYPE_SNACK
        else -> NutritionRecord.MEAL_TYPE_UNKNOWN
    }
}
```

**iOS Decoder (Simplified):**
```swift
func decodeNutrition(map: [String: Any]) throws -> [HKQuantitySample] {
    guard let startTimeString = map["startTime"] as? String,
          let endTimeString = map["endTime"] as? String,
          let startTime = ISO8601DateFormatter().date(from: startTimeString),
          let endTime = ISO8601DateFormatter().date(from: endTimeString) else {
        throw DecoderError.invalidFormat
    }

    let name = map["name"] as? String
    let mealType = map["mealType"] as? String

    // Build base metadata
    var baseMetadata: [String: Any] = [:]
    if let name = name {
        baseMetadata[HKMetadataKeyFoodType] = name
    }
    if let mealType = mealType {
        baseMetadata["mealType"] = mealType
    }
    if let customMetadata = map["metadata"] as? [String: Any] {
        baseMetadata.merge(customMetadata) { (_, new) in new }
    }

    let source = map["source"] as? [String: Any]
    let device = try? buildDevice(from: source)

    var samples: [HKQuantitySample] = []

    // Helper to create sample for a nutrient
    func addNutrientSample(
        key: String,
        identifier: HKQuantityTypeIdentifier,
        defaultUnit: HKUnit
    ) {
        guard let nutrientMap = map[key] as? [String: Any],
              let value = nutrientMap["value"] as? Double,
              let unitString = nutrientMap["unit"] as? String else {
            return
        }

        let quantityType = HKQuantityType.quantityType(forIdentifier: identifier)!
        let unit = HKUnit(from: unitString)
        let quantity = HKQuantity(unit: unit, doubleValue: value)

        let sample = HKQuantitySample(
            type: quantityType,
            quantity: quantity,
            start: startTime,
            end: endTime,
            device: device,
            metadata: baseMetadata
        )

        samples.append(sample)
    }

    // Map all nutrients
    addNutrientSample(key: "energy", identifier: .dietaryEnergyConsumed, defaultUnit: .kilocalorie())
    addNutrientSample(key: "protein", identifier: .dietaryProtein, defaultUnit: .gram())
    addNutrientSample(key: "totalCarbohydrate", identifier: .dietaryCarbohydrates, defaultUnit: .gram())
    addNutrientSample(key: "totalFat", identifier: .dietaryFatTotal, defaultUnit: .gram())
    addNutrientSample(key: "dietaryFiber", identifier: .dietaryFiber, defaultUnit: .gram())
    addNutrientSample(key: "sugar", identifier: .dietarySugar, defaultUnit: .gram())
    addNutrientSample(key: "saturatedFat", identifier: .dietaryFatSaturated, defaultUnit: .gram())
    addNutrientSample(key: "monounsaturatedFat", identifier: .dietaryFatMonounsaturated, defaultUnit: .gram())
    addNutrientSample(key: "polyunsaturatedFat", identifier: .dietaryFatPolyunsaturated, defaultUnit: .gram())
    addNutrientSample(key: "cholesterol", identifier: .dietaryCholesterol, defaultUnit: .gram())

    // Minerals
    addNutrientSample(key: "calcium", identifier: .dietaryCalcium, defaultUnit: .gram())
    addNutrientSample(key: "chloride", identifier: .dietaryChloride, defaultUnit: .gram())
    addNutrientSample(key: "chromium", identifier: .dietaryChromium, defaultUnit: .gram())
    addNutrientSample(key: "copper", identifier: .dietaryCopper, defaultUnit: .gram())
    addNutrientSample(key: "iodine", identifier: .dietaryIodine, defaultUnit: .gram())
    addNutrientSample(key: "iron", identifier: .dietaryIron, defaultUnit: .gram())
    addNutrientSample(key: "magnesium", identifier: .dietaryMagnesium, defaultUnit: .gram())
    addNutrientSample(key: "manganese", identifier: .dietaryManganese, defaultUnit: .gram())
    addNutrientSample(key: "molybdenum", identifier: .dietaryMolybdenum, defaultUnit: .gram())
    addNutrientSample(key: "phosphorus", identifier: .dietaryPhosphorus, defaultUnit: .gram())
    addNutrientSample(key: "potassium", identifier: .dietaryPotassium, defaultUnit: .gram())
    addNutrientSample(key: "selenium", identifier: .dietarySelenium, defaultUnit: .gram())
    addNutrientSample(key: "sodium", identifier: .dietarySodium, defaultUnit: .gram())
    addNutrientSample(key: "zinc", identifier: .dietaryZinc, defaultUnit: .gram())

    // Vitamins
    addNutrientSample(key: "vitaminA", identifier: .dietaryVitaminA, defaultUnit: .gram())
    addNutrientSample(key: "vitaminB6", identifier: .dietaryVitaminB6, defaultUnit: .gram())
    addNutrientSample(key: "vitaminB12", identifier: .dietaryVitaminB12, defaultUnit: .gram())
    addNutrientSample(key: "vitaminC", identifier: .dietaryVitaminC, defaultUnit: .gram())
    addNutrientSample(key: "vitaminD", identifier: .dietaryVitaminD, defaultUnit: .gram())
    addNutrientSample(key: "vitaminE", identifier: .dietaryVitaminE, defaultUnit: .gram())
    addNutrientSample(key: "vitaminK", identifier: .dietaryVitaminK, defaultUnit: .gram())
    addNutrientSample(key: "thiamin", identifier: .dietaryThiamin, defaultUnit: .gram())
    addNutrientSample(key: "riboflavin", identifier: .dietaryRiboflavin, defaultUnit: .gram())
    addNutrientSample(key: "niacin", identifier: .dietaryNiacin, defaultUnit: .gram())
    addNutrientSample(key: "folate", identifier: .dietaryFolate, defaultUnit: .gram())
    addNutrientSample(key: "biotin", identifier: .dietaryBiotin, defaultUnit: .gram())
    addNutrientSample(key: "pantothenicAcid", identifier: .dietaryPantothenicAcid, defaultUnit: .gram())

    return samples
}
```

## Usage Examples

**Example 1: Simple Meal Entry**
```dart
final breakfast = CKNutrition.macros(
  time: DateTime(2024, 10, 27, 8, 0),
  zoneOffset: DateTime.now().timeZoneOffset,
  source: CKSource.manualEntry(),
  name: "Oatmeal with Berries",
  mealType: CKMealType.breakfast,
  calories: CKValue.quantity(350, 'kcal'),
  protein: CKValue.quantity(12, 'g'),
  carbs: CKValue.quantity(58, 'g'),
  fat: CKValue.quantity(8, 'g'),
);

await ConnectKit.instance.writeRecords([breakfast]);
```

**Example 2: Detailed Nutrition Entry**
```dart
final lunch = CKNutrition(
  startTime: DateTime(2024, 10, 27, 12, 30),
  endTime: DateTime(2024, 10, 27, 13, 0), // 30 min eating duration
  startZoneOffset: DateTime.now().timeZoneOffset,
  endZoneOffset: DateTime.now().timeZoneOffset,
  source: CKSource.manualEntry(),
  name: "Grilled Salmon with Vegetables",
  mealType: CKMealType.lunch,

  // Macros
  energy: CKValue.quantity(520, 'kcal'),
  protein: CKValue.quantity(42, 'g'),
  totalCarbohydrate: CKValue.quantity(28, 'g'),
  totalFat: CKValue.quantity(26, 'g'),
  dietaryFiber: CKValue.quantity(7, 'g'),
  sugar: CKValue.quantity(5, 'g'),

  // Fat breakdown
  saturatedFat: CKValue.quantity(5, 'g'),
  monounsaturatedFat: CKValue.quantity(12, 'g'),
  polyunsaturatedFat: CKValue.quantity(8, 'g'),

  // Key minerals
  sodium: CKValue.quantity(450, 'mg'),
  potassium: CKValue.quantity(850, 'mg'),
  calcium: CKValue.quantity(120, 'mg'),
  iron: CKValue.quantity(3, 'mg'),

  // Key vitamins
  vitaminA: CKValue.quantity(850, 'mcg'),
  vitaminC: CKValue.quantity(45, 'mg'),
  vitaminD: CKValue.quantity(15, 'mcg'),
);

await ConnectKit.instance.writeRecords([lunch]);
```

---

## Conclusion

### Nutrition Model: ✅ COMPREHENSIVE

The `CKNutrition` model provides extensive nutrient tracking while maintaining simplicity.

**Key Success Factors:**
- All nutrients optional (flexibility)
- Factory method for common use case (macros only)
- Comprehensive vitamin/mineral support
- Clear meal type classification
- iOS multi-sample approach abstracted away

---

*Research conducted: October 27, 2025*
*Document version: 1.0*
