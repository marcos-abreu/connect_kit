// ignore_for_file:  public_member_api_docs

import 'package:connect_kit/src/models/schema/ck_value.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';
import 'package:connect_kit/src/models/records/ck_record.dart';
import 'package:connect_kit/src/models/ck_categories.dart';

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
  final CKQuantityValue? energy;

  /// Macro nutrients
  final CKQuantityValue? protein;
  final CKQuantityValue? totalCarbohydrate;
  final CKQuantityValue? totalFat;
  final CKQuantityValue? dietaryFiber;
  final CKQuantityValue? sugar;

  /// Fat breakdown
  final CKQuantityValue? saturatedFat;
  final CKQuantityValue? unsaturatedFat;
  final CKQuantityValue? monounsaturatedFat;
  final CKQuantityValue? polyunsaturatedFat;
  final CKQuantityValue? transFat;
  final CKQuantityValue? cholesterol;

  /// Minerals (all optional)
  final CKQuantityValue? calcium;
  final CKQuantityValue? chloride;
  final CKQuantityValue? chromium;
  final CKQuantityValue? copper;
  final CKQuantityValue? iodine;
  final CKQuantityValue? iron;
  final CKQuantityValue? magnesium;
  final CKQuantityValue? manganese;
  final CKQuantityValue? molybdenum;
  final CKQuantityValue? phosphorus;
  final CKQuantityValue? potassium;
  final CKQuantityValue? selenium;
  final CKQuantityValue? sodium;
  final CKQuantityValue? zinc;

  /// Vitamins (all optional)
  final CKQuantityValue? vitaminA;
  final CKQuantityValue? vitaminB6;
  final CKQuantityValue? vitaminB12;
  final CKQuantityValue? vitaminC;
  final CKQuantityValue? vitaminD;
  final CKQuantityValue? vitaminE;
  final CKQuantityValue? vitaminK;
  final CKQuantityValue? thiamin; // B1
  final CKQuantityValue? riboflavin; // B2
  final CKQuantityValue? niacin; // B3
  final CKQuantityValue? folate; // B9
  final CKQuantityValue? biotin; // B7
  final CKQuantityValue? pantothenicAcid; // B5

  /// TODO: add documentation
  const CKNutrition({
    super.id,
    required super.startTime,
    required super.endTime,
    super.startZoneOffset,
    super.endZoneOffset,
    super.source,
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
    CKQuantityValue? energy,
    CKQuantityValue? protein,
    CKQuantityValue? carbs,
    CKQuantityValue? fat,
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
    );
  }
}
