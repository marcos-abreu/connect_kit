package dev.luix.connect_kit.logging

import android.util.Log
import dev.luix.connect_kit.BuildConfig

/**
 * A unified, compile-time-safe logging facade for the ConnectKit plugin
 *
 * This logger strictly mirrors the final Dart CKLogger logic to ensure identical behavior regarding
 * standard logging suppression and critical bypass.
 *
 * Kotlin 'object' is the equivalent of a static utility class in Java/Dart.
 */
object CKLogger {

    // --- Log Execution Delegation Property ---
    // NOTE: Unlike the Dart implementation, we DO NOT maintain a private property
    // (e.g., `private var logExecutor: LogExecutor? = null`) or a corresponding setter
    // to swap out the logging mechanism for testing.
    //
    // RATIONALE: Robolectric's `ShadowLog` automatically intercepts all static calls
    // to `android.util.Log`. This provides the verification mechanism we need for unit tests
    // (e.g., asserting the tag, level, and message) without requiring any dependency
    // injection or abstraction in the production code.
    //
    // Log pollution is also mitigated by the use of `ShadowLog` (diverts output to memory)
    // and compiler-level dead code elimination for release builds (`if (BuildConfig.DEBUG)`
    // checks).
    // -----------------------------------------------------------------------------------

    // Static identifier used for structured output
    private const val PLUGIN_TAG = "[ConnectKit]"

    // --- Internal Control Flags (Mirroring Dart logic) ---

    // A nullable boolean used to implement the three-state logic:
    // - null: Defer to BuildConfig.DEBUG (Regular execution)
    // - true/false: Absolute override of BuildConfig.DEBUG (Test control)
    @Volatile // Ensures visibility across threads, especially important for testing
    private var enableLogsForTests: Boolean? = null

    // Controls log output for (Critical Bypass).
    @Volatile private var forceCriticalLog: Boolean = false

    /**
     * Private function to determine if standard logging should occur Logic: Use the override state
     * if set, otherwise use BuildConfig.DEBUG
     */
    private val shouldLog: Boolean
        get() = enableLogsForTests ?: BuildConfig.DEBUG

    // --- Testability Setters (Analogous to Dart's static set properties) ---

    /**
     * [FOR TESTING ONLY] Sets the logging override state Set to `null` to respect
     * BuildConfig.DEBUG. Set to `true` or `false` to override it
     */
    @JvmStatic
    fun setLoggingEnabled(isEnabled: Boolean?) {
        enableLogsForTests = isEnabled
    }

    /**
     * [FOR TESTING ONLY] Sets whether the critical log bypass is active, simulating the runtime
     * configuration override
     */
    @JvmStatic
    fun setCriticalLogBypass(forceBypass: Boolean) {
        forceCriticalLog = forceBypass
    }

    // NOTE: The Dart equivalent 'logExecutor' is omitted, as Kotlin directly uses
    // the non-injectable 'android.util.Log' for native logging

    // --- Public Interface (Mirroring Dart d, i, w, e, f) ---

    /** Logs a [debug] message. Stripped in release builds */
    fun d(tag: String, message: String) {
        if (BuildConfig.DEBUG) {
            if (shouldLog) {
                log(CKLogLevel.DEBUG, tag, message, null)
            }
        }
    }

    /** Logs an [info] message. Stripped in release builds */
    fun i(tag: String, message: String) {
        if (BuildConfig.DEBUG) {
            if (shouldLog) {
                log(CKLogLevel.INFO, tag, message, null)
            }
        }
    }

    /** Logs a [warning] message. Stripped in release builds */
    fun w(tag: String, message: String, error: Throwable? = null) {
        if (BuildConfig.DEBUG) {
            if (shouldLog) {
                log(CKLogLevel.WARN, tag, message, error)
            }
        }
    }

    /** Logs an [error] message. Stripped in release builds */
    fun e(tag: String, message: String, error: Throwable? = null) {
        if (BuildConfig.DEBUG) {
            if (shouldLog) {
                log(CKLogLevel.ERROR, tag, message, error)
            }
        }
    }

    /** Logs a [fatal] error. Stripped in release builds */
    fun f(tag: String, message: String, error: Throwable? = null) {
        if (BuildConfig.DEBUG) {
            if (shouldLog) {
                log(CKLogLevel.FATAL, tag, message, error)
            }
        }
    }

    /**
     * Logs a **critical** message that **bypasses** the standard debug stripping
     *
     * This method respects the Dart logic for critical bypass: it will fire if standard logging is
     * enabled OR if the critical bypass flag is set
     */
    fun critical(tag: String, message: String, error: Throwable? = null) {
        // Logic: (shouldLog) OR if the critical bypass flag is explicitly set (forceCriticalLog)
        if (shouldLog || forceCriticalLog) {
            // Critical logs are treated as FATAL/ERROR severity
            log(CKLogLevel.FATAL, tag, message, error)
        }
    }

    // --- Internal Execution ---

    /** The internal logging execution function that handles formatting and native log calls. */
    private fun log(level: CKLogLevel, tag: String, message: String, error: Throwable?) {
        val levelName = level.name
        val output = "$PLUGIN_TAG[$tag][${levelName}] $message"
        val logTag = "ConnectKit" // Primary tag for logcat filtering

        // Map CKLogLevel to Android Log priority and execute using android.util.Log
        when (level) {
            CKLogLevel.DEBUG -> Log.d(logTag, output, error)
            CKLogLevel.INFO -> Log.i(logTag, output, error)
            CKLogLevel.WARN -> Log.w(logTag, output, error)
            // Map both ERROR and FATAL to Android's highest level Log.e
            CKLogLevel.ERROR,
            CKLogLevel.FATAL -> Log.e(logTag, output, error)
        }
    }
}
