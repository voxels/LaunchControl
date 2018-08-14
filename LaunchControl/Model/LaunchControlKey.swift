//
//  LaunchControllerKey.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Enum for handling launch control of services that need obfuscated API Keys
enum LaunchControlKey : String {
    case BugsnagAPIKey
    case ParseApplicationId
    case AWSIdentityPoolId
    case AWSBucketName
    
    /**
     Decodes the encrypted string for a LaunchControlKey
     - parameter obfuscator: an Obfuscator object configured with the same salt array of AnyObject used during the string's encryption
     - Returns: the decrypted API key String
     */
    func decoded(with obfuscator:Obfuscator = Obfuscator.init(withSalt: Obfuscator.saltObjects()))->String {
        return obfuscator.reveal(key())
    }
    
    /**
     Encodes an array of UInt8 that can be used with the Obfuscator class to decrypt an API key
     - Returns: a hard coded array of UInt8 with encrypted bytes
     */
    func key()->[UInt8] {
        switch self {
        default:
            return [UInt8]()
        }
    }

    #if DEBUG
    /**
     Generates the byte array for an API Key.
     - Returns: an array of UInt8 representing the encrypted API Key
     */
    func generate(with salt:[AnyObject])->[UInt8] {
        let obfuscator = Obfuscator(withSalt:salt)
        var hideString = ""
        switch self {
        case .BugsnagAPIKey:
            fallthrough
        case .ParseApplicationId:
            fallthrough
        case .AWSIdentityPoolId:
            fallthrough
        case .AWSBucketName:
            hideString = ""
        }
        
        return obfuscator.bytesByObfuscatingString(hideString)
    }
    #endif
}
