import Foundation

class KeychainHelper {
    static let shared = KeychainHelper()
    private let userIdentifierKey = "com.whispertranscription.userIdentifier"

    func saveUserIdentifier(_ identifier: String) {
        let data = Data(identifier.utf8)
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: userIdentifierKey,
            kSecValueData: data
        ] as CFDictionary

        let status = SecItemAdd(query, nil)
        if status != errSecSuccess {
            print("Error saving to Keychain: \(status)")
            // Optionally, handle the error or notify the user
        }
    }

    func getUserIdentifier() -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: userIdentifierKey,
            kSecReturnData: true
        ] as CFDictionary

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query, &dataTypeRef)

        if status == errSecSuccess {
            if let data = dataTypeRef as? Data, let identifier = String(data: data, encoding: .utf8) {
                return identifier
            }
        } else {
            print("Error retrieving from Keychain: \(status)")
            // Optionally, handle the error or notify the user
        }

        return nil
    }

    func deleteUserIdentifier() {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: userIdentifierKey
        ] as CFDictionary

        SecItemDelete(query)
    }
} 