//
//  LaunchError.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Launch errors used in the LaunchController class
enum LaunchError : Error {
    case MissingRequiredKey
    case UnexpectedLaunchNotification
    case DuplicateLaunch
    case MissingRemoteStoreController
    case MissingLaunchController
}

extension LaunchError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .MissingRequiredKey:
            return NSLocalizedString("The required API key is missing", comment: "")
        case .UnexpectedLaunchNotification:
            return NSLocalizedString("An unexpected launch notification was received", comment: "")
        case .DuplicateLaunch:
            return NSLocalizedString("The remote store has already been launched", comment: "")
        case .MissingRemoteStoreController:
            return NSLocalizedString("The required remote store controller is missing", comment: "")
        case .MissingLaunchController:
            return NSLocalizedString("The expected launch controller is missing", comment: "")
        }
    }
}
