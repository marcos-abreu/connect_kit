library;

// The auto-generated Pigeon code lives here.
import 'package:connect_kit/src/pigeon/connect_kit_messages.g.dart';
import 'package:connect_kit/src/services/operations_service.dart';

// Future exports for models/enums will go here, keeping the public interface clean
// export 'src/models/model_name.dart';

/// Primary interface for the ConnectKit plugin
///
/// This class is implemented as a **singleton** using a lazy getter
/// to ensure internal services are initialized automatically upon first access
class ConnectKit {
  // --- Singleton Implementation ---

  /// Private constructor to enforce the singleton pattern
  ConnectKit._internal() {
    _initialize(); // Initialize immediately on construction
  }

  // A static final variable is initialized the first time it is accessed.
  // Initialization is atomic and happens at most once
  static final ConnectKit _instance = ConnectKit._internal(); // ← final, non-nullable

  late final ConnectKitHostApi _hostApi;
  late final OperationsService _operationsService;

  /// The getter returns as single instance of the [ConnectKit] plugin
  static ConnectKit get instance => _instance;

  /// Initialization (idempotent)
  bool _initialized = false;
  void _initialize() {
    if (_initialized) return;
    _initialized = true;

    _hostApi = ConnectKitHostApi();
    _operationsService = OperationsService(_hostApi);
  }

  // --- Public API ---

  /// Retrieves the operating system version from the native platform
  ///
  /// Delegates the call to the internal Pigeon communication client
  Future<String> getPlatformVersion() {
    return _operationsService.getPlatformVersion();
  }

  // Future public methods will be added here, delegating to other services or clients
}
