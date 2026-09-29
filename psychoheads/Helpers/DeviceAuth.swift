//
//  DeviceAuth.swift
//  psychoheads
//

import Foundation
import LocalAuthentication

enum DeviceAuth {
    /// Authenticates the device owner via Face ID / Touch ID, falling back to device passcode.
    /// Calls `completion` on the main queue with `true` only on successful authentication.
    static func authenticate(
        reason: String = "Authenticate to delete this item",
        completion: @escaping (Bool) -> Void
    ) {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}
