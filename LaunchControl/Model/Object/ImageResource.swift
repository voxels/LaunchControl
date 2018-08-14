//
//  ImageResource.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

typealias ImageResourceCompletion = ([ImageResource])->Void
typealias ImageCompletion = (UIImage?)->Void

protocol ImageResourceDelegate : class {
    func didUpdateThumbnailImage()
    func didUpdateFileImage()
}

/// Implementation of the *ImageSchema* protocol used as model objects that hold data
/// fetched from the *RemoteStoreController*
class ImageResource : ImageSchema  {
    var createdAt: Date
    var updatedAt: Date
    var filename: String
    var thumbnailURL: URL
    var fileURL: URL
    var thumbnailImage:UIImage?
    var thumbnailWidth:CGFloat = 0
    var thumbnailHeight:CGFloat = 0
    var fileImage:UIImage?
    
    init(createdAt:Date, updatedAt:Date, filename:String, thumbnailURL:URL, fileURL:URL, width:Int, height:Int) {
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.filename = filename
        self.thumbnailURL = thumbnailURL
        self.fileURL = fileURL
        self.thumbnailImage = nil
        self.fileImage = nil
        self.thumbnailWidth = CGFloat(width)
        self.thumbnailHeight = CGFloat(height)
    }
    
    /**
     Creates an array of *ImageResource* with the given *RawResourceArray*
     - parameter rawResourceArray: an array of *[String:AnyObject]* containing the records fetched from a *RemoteStoreController*
     - parameter completion: a callback used to pass through the constructed array of *ImageResource*
     - Returns: void
     */
    static func extractImageResources(from rawResourceArray:RawResourceArray, completion:ImageRepositoryCompletion) -> Void {
        
        var accumulatedErrors = [Error]()
        let newEntries = ImageRepository()
        
        var foundImageResource = false
        
        rawResourceArray.forEach { (dictionary) in
            do {
                let objectId:String = try Extractor.extractValue(named: TableMap.CommonColumn.objectId.rawValue, from: dictionary)
                
                foundImageResource = true
                let imageResource = try ImageResource.imageResource(from: dictionary)
                newEntries.map[objectId] = imageResource
                
            } catch {
                accumulatedErrors.append(error)
            }
        }
        
        if !foundImageResource {
            accumulatedErrors.append(ModelError.NoNewValues)
        }
        
        completion(newEntries, accumulatedErrors)
    }
    
    /**
     Creates an *ImageResource* from the given *[String:AnyObject]*
     - parameter dictionary: the raw model object fetched from the *RemoteStoreController*
     - Throws: any error generated by the *Extractor*
     - Returns: an *ImageResource* for the given raw model object
     */
    static func imageResource(from dictionary:[String:AnyObject]) throws -> ImageResource {
        let createdAt:Date = try Extractor.extractValue(named: TableMap.CommonColumn.createdAt.rawValue, from: dictionary)
        let updatedAt:Date = try Extractor.extractValue(named: TableMap.CommonColumn.updatedAt.rawValue, from: dictionary)
        let filename:String = try Extractor.extractValue(named: ImageTableMap.ImageResourceColumn.filename.rawValue, from: dictionary)
        let thumbnailURL:URL = try Extractor.extractValue(named: ImageTableMap.ImageResourceColumn.thumbnailURLString.rawValue, from: dictionary)
        let fileURL:URL = try Extractor.extractValue(named: ImageTableMap.ImageResourceColumn.fileURLString.rawValue, from: dictionary)
        let width:Int = try Extractor.extractValue(named: ImageTableMap.ImageResourceColumn.width.rawValue, from: dictionary)
        let height:Int = try Extractor.extractValue(named: ImageTableMap.ImageResourceColumn.height.rawValue, from: dictionary)
        
        return ImageResource(createdAt: createdAt, updatedAt: updatedAt, filename: filename, thumbnailURL: thumbnailURL, fileURL: fileURL, width:width, height:height)
    }
}

extension ImageResource : Hashable {
    var hashValue: Int {
        return filename.hashValue ^ createdAt.hashValue ^ updatedAt.hashValue &* 16777619
    }
    
    static func == (lhs: ImageResource, rhs: ImageResource) -> Bool {
        
        return lhs.createdAt == rhs.createdAt && lhs.updatedAt == rhs.updatedAt && lhs.filename == rhs.filename && lhs.thumbnailURL == rhs.thumbnailURL && lhs.fileURL == rhs.fileURL
    }
}
