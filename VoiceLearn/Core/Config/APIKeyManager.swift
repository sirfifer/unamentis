// VoiceLearn - API Key Manager
// Secure management of API keys for external services
//
// Part of Configuration (TDD Section 7)

import Foundation
import Security
import Logging

/// Manages API keys securely using Keychain and environment variables
///
/// Priority order:
/// 1. Keychain (most secure, persistent)
/// 2. Environment variables (development)
/// 3. UserDefaults (fallback, least secure)
public actor APIKeyManager {
    
    // MARK: - Singleton
    
    public static let shared = APIKeyManager()
    
    // MARK: - Properties
    
    private let logger = Logger(label: "com.voicelearn.apikeys")
    private let serviceName = "com.voicelearn.apikeys"
    
    /// API key identifiers
    public enum KeyType: String, CaseIterable, Sendable {
        case assemblyAI = "ASSEMBLYAI_API_KEY"
        case deepgram = "DEEPGRAM_API_KEY"
        case openAI = "OPENAI_API_KEY"
        case anthropic = "ANTHROPIC_API_KEY"
        case elevenLabs = "ELEVENLABS_API_KEY"
        case liveKit = "LIVEKIT_API_KEY"
        case liveKitSecret = "LIVEKIT_API_SECRET"
        
        public var displayName: String {
            switch self {
            case .assemblyAI: return "AssemblyAI"
            case .deepgram: return "Deepgram"
            case .openAI: return "OpenAI"
            case .anthropic: return "Anthropic"
            case .elevenLabs: return "ElevenLabs"
            case .liveKit: return "LiveKit API Key"
            case .liveKitSecret: return "LiveKit Secret"
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        logger.info("APIKeyManager initialized")
    }
    
    // MARK: - Public API
    
    /// Get an API key, checking sources in priority order
    public func getKey(_ keyType: KeyType) -> String? {
        // 1. Try Keychain first
        if let key = getFromKeychain(keyType) {
            return key
        }
        
        // 2. Try environment variable
        if let key = ProcessInfo.processInfo.environment[keyType.rawValue], !key.isEmpty {
            return key
        }
        
        // 3. Try UserDefaults (for development only)
        if let key = UserDefaults.standard.string(forKey: keyType.rawValue), !key.isEmpty {
            return key
        }
        
        logger.warning("No API key found for: \(keyType.displayName)")
        return nil
    }
    
    /// Store an API key in Keychain
    public func setKey(_ keyType: KeyType, value: String) throws {
        try saveToKeychain(keyType: keyType, value: value)
        logger.info("Saved API key for: \(keyType.displayName)")
    }
    
    /// Remove an API key from Keychain
    public func removeKey(_ keyType: KeyType) throws {
        try deleteFromKeychain(keyType)
        logger.info("Removed API key for: \(keyType.displayName)")
    }
    
    /// Check if a key is configured
    public func hasKey(_ keyType: KeyType) -> Bool {
        getKey(keyType) != nil
    }
    
    /// Get status of all keys
    public func getKeyStatus() -> [KeyType: Bool] {
        var status: [KeyType: Bool] = [:]
        for keyType in KeyType.allCases {
            status[keyType] = hasKey(keyType)
        }
        return status
    }
    
    /// Validate all required keys for a session
    public func validateRequiredKeys() -> [KeyType] {
        let required: [KeyType] = [.assemblyAI, .deepgram, .openAI]
        return required.filter { !hasKey($0) }
    }
    
    // MARK: - Keychain Operations
    
    private func getFromKeychain(_ keyType: KeyType) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: keyType.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    private func saveToKeychain(keyType: KeyType, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw APIKeyError.invalidValue
        }
        
        // Delete any existing key first
        try? deleteFromKeychain(keyType)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: keyType.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw APIKeyError.keychainError(status)
        }
    }
    
    private func deleteFromKeychain(_ keyType: KeyType) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: keyType.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw APIKeyError.keychainError(status)
        }
    }
}

// MARK: - Errors

public enum APIKeyError: Error, LocalizedError {
    case invalidValue
    case keychainError(OSStatus)
    case keyNotFound(APIKeyManager.KeyType)
    
    public var errorDescription: String? {
        switch self {
        case .invalidValue:
            return "Invalid API key value"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .keyNotFound(let keyType):
            return "API key not found: \(keyType.displayName)"
        }
    }
}
