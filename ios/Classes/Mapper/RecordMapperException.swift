import Foundation

/// Base exception for all record mapper errors.
///
/// Thrown when a record map cannot be decoded into a HealthKit Record.
/// Common causes:
/// - Missing required fields
/// - Invalid field values (wrong type, out of range)
/// - Invalid record structure
/// - Unsupported field combinations
public class RecordMapperException: Error, CustomStringConvertible {

    /// Human-readable error description
    public let message: String

    /// The record kind that failed to decode (if known)
    public let recordKind: String?

    /// The specific field that caused the error (if applicable)
    public let fieldName: String?

    /// The underlying exception (if any)
    public let cause: Error?

    /// Formatted error description
    public var description: String {
        return RecordMapperException.buildMessage(
            message: message,
            recordKind: recordKind,
            fieldName: fieldName
        )
    }

    public init(
        message: String,
        recordKind: String? = nil,
        fieldName: String? = nil,
        cause: Error? = nil
    ) {
        self.message = message
        self.recordKind = recordKind
        self.fieldName = fieldName
        self.cause = cause
    }

    /**
     * Builds a formatted error message with optional context.
     */
    private static func buildMessage(
        message: String,
        recordKind: String?,
        fieldName: String?
    ) -> String {
        var parts: [String] = []

        if let recordKind = recordKind {
            parts.append("Record kind: \(recordKind)")
        }

        if let fieldName = fieldName {
            parts.append("Field: \(fieldName)")
        }

        parts.append(message)

        return parts.joined(separator: " | ")
    }

    // MARK: - Factory Methods

    /**
     * Creates a MapperException for a missing required field.
     */
    public static func missingField(
        fieldName: String,
        recordKind: String
    ) -> RecordMapperException {
        return RecordMapperException(
            message: "Missing required field",
            recordKind: recordKind,
            fieldName: fieldName
        )
    }

    /**
     * Creates a MapperException for an invalid field type.
     */
    public static func invalidFieldType(
        fieldName: String,
        expectedType: String,
        actualValue: Any?,
        recordKind: String
    ) -> RecordMapperException {
        let actualTypeName = type(of: actualValue as Any)
        let actualTypeNameString = String(describing: actualTypeName)

        return RecordMapperException(
            message:
                "Expected \(expectedType) but got \(actualValue == nil ? "null" : actualTypeNameString)",
            recordKind: recordKind,
            fieldName: fieldName
        )
    }

    /**
     * Creates a MapperException for an invalid field value.
     */
    public static func invalidFieldValue(
        fieldName: String,
        reason: String,
        recordKind: String
    ) -> RecordMapperException {
        return RecordMapperException(
            message: reason,
            recordKind: recordKind,
            fieldName: fieldName
        )
    }
}

/// Exception thrown when a record kind is not supported on the current platform.
///
/// Used for iOS-only record kinds like Audiogram and ECG that have no
/// Android Health Connect equivalent.
public class UnsupportedKindException: Error, CustomStringConvertible {

    /// The unsupported record kind identifier
    public let recordKind: String

    /// The platform where this record kind is not supported
    public let platform: String

    /// Human-readable explanation
    public let message: String

    public var description: String {
        return "[\(platform)] Unsupported record kind '\(recordKind)': \(message)"
    }

    public init(
        recordKind: String,
        platform: String = "iOS",
        message: String
    ) {
        self.recordKind = recordKind
        self.platform = platform
        self.message = message
    }
}

/// Represents a record that failed during decode/validation.
/// Used internally before conversion to WriteResultMessage.
///
/// IMPORTANT: This should be in sync with the dart RecordFailure
public struct RecordMapperFailure {

    /// Index path to the record in the original records array (supports nested structures)
    public let indexPath: [Int]

    /// Human-readable error message
    public let message: String

    /// Optional category (e.g., "ValidationError", "MapperError")
    public let type: String

    public init(indexPath: [Int], message: String, type: String) {
        self.indexPath = indexPath
        self.message = message
        self.type = type
    }

    public func copy(
        indexPath: [Int]? = nil,
        message: String? = nil,
        type: String? = nil
    ) -> RecordMapperFailure {
        return RecordMapperFailure(
            indexPath: indexPath ?? self.indexPath,
            message: message ?? self.message,
            type: type ?? self.type
        )
    }
}

// MARK: - RecordMapperFailure Extensions

extension RecordMapperFailure {

    /**
     * Converts the RecordMapperFailure to a dictionary representation.
     * Used for serialization across platform channels.
     */
    public func toMap() -> [String: Any] {
        return [
            "indexPath": indexPath,
            "message": message,
            "type": type,
        ]
    }

    /**
     * Creates a RecordMapperFailure for a single record at a specific index.
     */
    public static func single(
        index: Int,
        message: String,
        type: String = "ValidationError"
    ) -> RecordMapperFailure {
        return RecordMapperFailure(
            indexPath: [index],
            message: message,
            type: type
        )
    }

    /**
     * Creates a RecordMapperFailure for a nested record using an index path.
     */
    public static func nested(
        indexPath: [Int],
        message: String,
        type: String = "ValidationError"
    ) -> RecordMapperFailure {
        return RecordMapperFailure(
            indexPath: indexPath,
            message: message,
            type: type
        )
    }
}
