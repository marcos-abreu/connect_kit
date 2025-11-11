package dev.luix.connect_kit.mapper

/**
 * Base exception for all record mapper errors.
 *
 * Thrown when a record map cannot be decoded into a Health Connect Record.
 * Common causes:
 * - Missing required fields
 * - Invalid field values (wrong type, out of range)
 * - Invalid record structure
 * - Unsupported field combinations
 *
 * @property message Human-readable error description
 * @property recordKind The record kind that failed to decode (if known)
 * @property fieldName The specific field that caused the error (if applicable)
 * @property cause The underlying exception (if any)
 */
class RecordMapperException(
    message: String,
    val recordKind: String? = null,
    val fieldName: String? = null,
    cause: Throwable? = null
) : Exception(buildMessage(message, recordKind, fieldName), cause) {

    companion object {
        private fun buildMessage(
            message: String,
            recordKind: String?,
            fieldName: String?
        ): String {
            val parts = mutableListOf<String>()

            if (recordKind != null) {
                parts.add("Record kind: $recordKind")
            }

            if (fieldName != null) {
                parts.add("Field: $fieldName")
            }

            parts.add(message)

            return parts.joinToString(" | ")
        }

        /**
         * Creates a MapperException for a missing required field.
         */
        fun missingField(fieldName: String, recordKind: String): RecordMapperException {
            return RecordMapperException(
                message = "Missing required field",
                recordKind = recordKind,
                fieldName = fieldName
            )
        }

        fun invalidFieldType(
            fieldName: String,
            expectedType: String,
            actualValue: Any?,
            recordKind: String
        ): RecordMapperException {
            return RecordMapperException(
                message = "Expected $expectedType but got ${actualValue?.javaClass?.simpleName ?: "null"}",
                recordKind = recordKind,
                fieldName = fieldName
            )
        }

        fun invalidFieldValue(
            fieldName: String,
            reason: String,
            recordKind: String
        ): RecordMapperException {
            return RecordMapperException(
                message = reason,
                recordKind = recordKind,
                fieldName = fieldName
            )
        }
    }
}

/**
 * Exception thrown when a record kind is not supported on the current platform.
 *
 * Used for iOS-only record kinds like Audiogram and ECG that have no
 * Android Health Connect equivalent.
 *
 * @property recordKind The unsupported record kind identifier
 * @property platform The platform where this record kind is not supported
 * @property message Human-readable explanation
 */
class UnsupportedKindException(
    val recordKind: String,
    val platform: String,
    message: String
) : Exception("[$platform] Unsupported record kind '$recordKind': $message")


/**
 * Represents a record that failed during decode/validation.
 * Used internally before conversion to WriteResultMessage.
 *
 * IMPORTANT: This should be in sync with the dart <RecordFailure>
 *
 * @property recordIndex Index in the record in the original records array (0-based)
 * @property error Human-readable error message
 * @property type Optional category (e.g., "ValidationError", "MapperError")
 */
data class RecordMapperFailure(
    val indexPath: List<Int>,
    val message: String,
    val type: String,
)

// At the top level of your file (not inside any class)
fun RecordMapperFailure.toMap(): Map<String, Any> {
    return mapOf(
        "indexPath" to indexPath,
        "message" to message,
        "type" to type
    )
}
