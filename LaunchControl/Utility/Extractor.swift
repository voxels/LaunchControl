//
//  Extractor.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

struct Extractor {
    static func extractValue<T>(named key:String, from dictionary:[String:AnyObject]) throws -> T {
        
        guard var value = dictionary[key] else {
            if key == TableMap.CommonColumn.objectId.rawValue {
                throw ModelError.EmptyObjectId
            } else {
                throw ModelError.MissingValue
            }
        }
        
        // We need to convert the string to an URL type
        if T.self is URL.Type{
            value = try Extractor.constructURL(from: value) as AnyObject
        }
        
        // We need to make sure we have the type of variable we expect to have
        guard let castValue = value as? T else {
            throw ModelError.IncorrectType
        }
        
        return castValue
    }
    
    static func constructURL(from value:AnyObject) throws -> URL {
        if let urlString = value as? String {
            guard let resourceLocator = URL(string: urlString) else {
                throw ModelError.InvalidURL
            }
            return resourceLocator
        } else {
            throw ModelError.IncorrectType
        }
    }
}
