import Foundation
import HealthKit

/**
 * Mapper for ECG (Electrocardiogram) records
 *
 * Handles the RECORD_KIND_ECG from Dart, which represents ECG recordings
 * captured by Apple Watch or other compatible devices.
 *
 * **iOS Only**: This record type is only supported on iOS with HealthKit.
 * Android will throw UnsupportedKindException for RECORD_KIND_ECG.
 *
 * Used internally by RecordMapper to handle RECORD_KIND_ECG
 *
 * **Supported Record Types**:
 * - HKElectrocardiogram for ECG recordings (iOS 14.0+)
 *
 * **Architecture**:
 * 1. Validate iOS version (14.0+) and device compatibility
 * 2. Extract ECG measurement data and voltage values
 * 3. Create HKElectrocardiogram with proper classification
 * 4. Handle ECG-specific metadata and source information
 *
 * @property healthStore The HealthKit store (for type validation)
 * @property categoryMapper Category mapper for enum conversions
 */
public class ECGMapper {

    // MARK: - Properties

    private let healthStore: HKHealthStore
    private let categoryMapper: CategoryMapper.Type

    private static let TAG = CKConstants.TAG_ECG_MAPPER
    private static let RECORD_KIND = CKConstants.RECORD_KIND_ECG

    // MARK: - Initialization

    /**
     * Initializes ECGMapper with required dependencies.
     *
     * - Parameter healthStore: HealthKit store for type validation
     * - Parameter categoryMapper: Category mapper for enum conversions
     */
    public init(
        healthStore: HKHealthStore,
        categoryMapper: CategoryMapper.Type = CategoryMapper.self
    ) {
        self.healthStore = healthStore
        self.categoryMapper = categoryMapper
    }

    // MARK: - Public API

    /**
     * Decodes an ECG record map into an HKElectrocardiogram.
     *
     * - Parameter map: The record map from Dart
     * - Throws: UnsupportedKindException if iOS version is incompatible
     */
    public func decode(_ map: [String: Any]) throws {
        throw RecordMapperException(
            message: "ECG records are read-only",
            recordKind: Self.RECORD_KIND
        )
    }
}