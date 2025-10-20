import Foundation
import Flutter
import UIKit

/// Implementation of the ConnectKitHostApi for iOS
/// Handles communication between Flutter and native iOS code
class CKHostApi: NSObject, ConnectKitHostApi {
    // MARK: - ConnectKitHostApi Protocol

    /// Retrieves the platform version information from the iOS system
    /// - Parameter completion: The completion handler to return the platform version or error
    func getPlatformVersion(completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let version = "iOS \(UIDevice.current.systemVersion) (\(UIDevice.current.systemName))"
            completion(.success(version))
        } catch {
            completion(.failure(error))
        }
    }
}
