// Helpful class to obfuscate API Keys contributed by
// ltblueberry0 from Gist: https://gist.github.com/ltblueberry0/33fbcd767f9b58faeaaba6e1d1665b62
// via https://medium.com/theappspace/increase-the-security-of-your-ios-app-by-obfuscating-sensitive-strings-swift-c915896711e6

import Foundation

protocol ObfuscatorProtocol {
    #if DEBUG
    func bytesByObfuscatingString(_ string: String) -> [UInt8]
    #endif
    static func saltObjects()->[AnyObject]
    func reveal(_ key: [UInt8]) -> String
}

class Obfuscator: ObfuscatorProtocol {

    // MARK: - Variables

    /// The salt used to obfuscate and reveal the string.
    private var salt: String = ""

    // MARK: - Initialization

    init(withSalt salt: [AnyObject]) {
        self.salt = salt.description
    }

    // MARK: - ObfuscatorProtocol Methods

    #if DEBUG
    /// This method obfuscates the string passed in using the salt
    /// that was used when the Obfuscator was initialized.
    ///
    /// - Parameter string: the string to obfuscate
    /// - Returns: the obfuscated string in a byte array
    func bytesByObfuscatingString(_ string: String) -> [UInt8] {
        let text = [UInt8](string.utf8)
        let cipher = [UInt8](salt.utf8)
        let length = cipher.count

        var encrypted = [UInt8]()

        for t in text.enumerated() {
            encrypted.append(t.element ^ cipher[t.offset % length])
        }

        return encrypted
    }
    #endif

    /// This method reveals the original string from the obfuscated
    /// byte array passed in. The salt must be the same as the one
    /// used to encrypt it in the first place.
    ///
    /// - Parameter key: the byte array to reveal
    /// - Returns: the original string
    func reveal(_ key: [UInt8]) -> String {
        let cipher = [UInt8](salt.utf8)
        let length = cipher.count

        var decrypted = [UInt8]()

        for k in key.enumerated() {
            decrypted.append(k.element ^ cipher[k.offset % length])
        }

        return String(bytes: decrypted, encoding: .utf8)!
    }
}

extension Obfuscator {
    static func saltObjects() -> [AnyObject] {
        return [LaunchController.self, NSString.self, NSSet.self]
    }
}
