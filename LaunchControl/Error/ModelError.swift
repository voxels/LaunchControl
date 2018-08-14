//
//  ModelError.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Remote Store Errors used in the ParseServerInterface class
enum ModelError : Error {
    case IncorrectType
    case InvalidURL
    case Deallocated
    case EmptyObjectId
    case MissingValue
    case NoNewValues
    case MissingDataSourceItem
    case UnsupportedRequest
    case MissingResourceModelController
}

extension ModelError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .IncorrectType:
            return NSLocalizedString("The object was not the expected type", comment: "")
        case .InvalidURL:
            return NSLocalizedString("The expected URL could not be constructed", comment: "")
        case .Deallocated:
            return NSLocalizedString("The model has been deallocated", comment: "")
        case .EmptyObjectId:
            return NSLocalizedString("No object id was found", comment: "")
        case .MissingValue:
            return NSLocalizedString("The raw dictionary does not contain the desired value", comment: "")
        case .NoNewValues:
            return NSLocalizedString("No new values were created", comment: "")
        case .MissingDataSourceItem:
            return NSLocalizedString("The data source does not contain the expected item", comment: "")
        case .UnsupportedRequest:
            return NSLocalizedString("The request has not been implemented", comment: "")
        case .MissingResourceModelController:
            return NSLocalizedString("The expected resource model controller is missing", comment: "")
        }
    }
}
