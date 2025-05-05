import Foundation
import Security

class TokenManager {
    static let shared = TokenManager()
    
    private let tokenKey = "auth_token"
    private let service = "com.opca.auth"
    
    private init() {}
    
    func saveToken(_ token: String) {
        let data = Data(token.utf8)
        
        // Define keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data
        ]
        
        // Delete any existing token
        SecItemDelete(query as CFDictionary)
        
        // Add the token to the keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            // If keychain fails, fallback to UserDefaults (less secure)
            UserDefaults.standard.set(token, forKey: tokenKey)
        }
    }
    
    func getToken() -> String? {
        // Define keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data, let token = String(data: data, encoding: .utf8) {
            return token
        } else {
            // If keychain fails, check UserDefaults (fallback)
            return UserDefaults.standard.string(forKey: tokenKey)
        }
    }
    
    func clearToken() {
        // Define keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey
        ]
        
        // Delete the token from the keychain
        SecItemDelete(query as CFDictionary)
        
        // Also clear from UserDefaults if it was stored there
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
    
    func isTokenValid() -> Bool {
        guard let token = getToken() else {
            return false
        }
        
        // Check token expiration
        let components = token.components(separatedBy: ".")
        guard components.count == 3 else {
            // Not a valid JWT format
            return false
        }
        
        // Get payload from JWT token
        guard let payloadData = base64Decode(components[1]) else {
            return false
        }
        
        do {
            if let payload = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any],
               let expirationTimestamp = payload["exp"] as? TimeInterval {
                // Check if token has expired
                let expirationDate = Date(timeIntervalSince1970: expirationTimestamp)
                return expirationDate > Date()
            }
        } catch {
            print("Error decoding JWT: \(error)")
        }
        
        return false
    }
    
    private func base64Decode(_ base64String: String) -> Data? {
        // JWT uses base64url encoding, which has different characters than standard base64
        var base64 = base64String
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        
        return Data(base64Encoded: base64)
    }
} 