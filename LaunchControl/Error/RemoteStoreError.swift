//
//  RemoteStoreError.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Remote Store Errors used in the ParseServerInterface class
enum RemoteStoreError : Error {
    case InvalidQuery
    case InvalidSortByColumn
}

extension RemoteStoreError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .InvalidQuery:
            return NSLocalizedString("Unable to construct the requested query", comment: "")
        case .InvalidSortByColumn:
            return NSLocalizedString("The sortBy column is not a member of the class", comment: "")
        }
    }
}
