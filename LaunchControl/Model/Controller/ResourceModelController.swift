//
//  ImageResourceModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

typealias ErrorCompletion = ([Error]?)->Void
typealias RawResourceArray = [[String:AnyObject]]

/// The delegate protocol used to notify that the model has updated or failed to update
protocol ResourceModelControllerDelegate : class {
    func didUpdateModel()
    func didFailToUpdateModel(with reason:String?)
}

/// A struct used to handle resources from a *RemoteStoreController* interface
class ResourceModelController {
    /// A controller used to fetch objects from a remote store
    let remoteStoreController:RemoteStoreController
    
    /// An interface uses to make fetches from the network
    let networkSessionInterface:NetworkSessionInterface
    
    /// The error handler used to report non-fatal errors
    let errorHandler:ErrorHandlerDelegate
    
    /// The delegate that gets informed of model updates
    weak var delegate:ResourceModelControllerDelegate?
    
    /// A cache of previously fetched *ImageResource*
    var imageRepository = ImageRepository()
    
    /// The complete number of images
    var totalImageRecords:Int = 0
    
    var writeQueueLabel = "com.secretaomtics.resourcemodelcontroller.write"
    var readQueueLabel = "com.secretaomtics.resourcemodelcontroller.read"
    
    /// The default number of seconds to wait before timing out
    static let defaultTimeout:TimeInterval = 20
    
    init(with storeController:RemoteStoreController, networkSessionInterface:NetworkSessionInterface, errorHandler:ErrorHandlerDelegate) {
        self.remoteStoreController = storeController
        self.networkSessionInterface = networkSessionInterface
        self.errorHandler = errorHandler
    }
    
    /**
     Builds the initial repository asset list
     - parameter storeController: the *RemoteStoreController* used to fetch the resources
     - parameter resourceType: the type of the resource being fetched
     - parameter queue: The *DispatchQueue* we need to call the completion block on
     - parameter errorHandler: the *ErrorHandlerDelegate* used to report non-fatal errors
     - parameter timeoutDuration:  the *TimeInterval* to wait before timing out the request
     - Returns: void
     */
    func build<T>(using storeController:RemoteStoreController, for resourceType:T.Type, on queue:DispatchQueue, with errorHandler:ErrorHandlerDelegate, timeoutDuration:TimeInterval = ResourceModelController.defaultTimeout) where T:Resource {
        switch T.self {
        case is ImageResource.Type:
            guard let table = try? tableMap(with: resourceType) else {
                reportUnsupportedRequest(with:errorHandler)
                return
            }
            
            remoteStoreController.count(table: table, on: queue, errorHandler: errorHandler) { [weak self] (fetchedCount) in
                guard let strongSelf = self else {
                    self?.reportUnsupportedRequest(with:errorHandler)
                    return
                }
                
                strongSelf.totalImageRecords = fetchedCount
                
                do {
                    try strongSelf.fill(repository: strongSelf.imageRepository, skip: 0, limit: strongSelf.remoteStoreController.defaultQuerySize, timeoutDuration:timeoutDuration, on:queue, completion:{ [weak self] (repository) in
                        guard let strongSelf = self else {
                            return
                        }
                        
                        let writeQueue = DispatchQueue(label: "\(strongSelf.writeQueueLabel)")
                        writeQueue.async { [weak self] in
                            self?.imageRepository = repository
                            DispatchQueue.main.async { [weak self] in
                                self?.delegate?.didUpdateModel()
                            }
                        }
                    })
                }
                catch {
                    errorHandler.report(error)
                    DispatchQueue.main.async { [weak self] in
                        self?.delegate?.didFailToUpdateModel(with: error.localizedDescription)
                    }
                }
            }
        default:
            reportUnsupportedRequest(with:errorHandler)
        }
    }
    
    func reportUnsupportedRequest(with errorHandler:ErrorHandlerDelegate) {
        DispatchQueue.main.async { [weak self] in
            let error = ModelError.UnsupportedRequest
            errorHandler.report(error)
            self?.delegate?.didFailToUpdateModel(with: error.localizedDescription)
        }
    }
    
    /**
     Checks the existing number of resources in the repository and fills in entries for indexes between the skip and limit, if necessary
     - parameter repository: the *Repository* that needs to be filled
     - parameter skip: the number of items to skip when finding new resources
     - parameter limit: the number of items we want to fetch
     - parameter timeoutDuration:  the *TimeInterval* to wait before timing out the request
     - parameter queue: The *DispatchQueue* we need to call the completion block on
     - parameter completion: a callback used to pass back the filled repository
     - Throws: Throws any error surfaced from *tableMap*
     - Returns: void
     */
    func fill<T>(repository:T, skip:Int, limit:Int, timeoutDuration:TimeInterval = ResourceModelController.defaultTimeout, on queue:DispatchQueue, completion:((T)->Void)?) throws where T:Repository, T.AssociatedType:Resource {
        let count = repository.map.count
        var fetchedAllRecords = false
        
        if repository is ImageRepository, count == totalImageRecords {
            fetchedAllRecords = true
        }
        
        // We have what we need
        if count >= skip + limit || fetchedAllRecords {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didUpdateModel()
            }
            
            completion?(repository)
            return
        }
        
        let table = try tableMap(for: repository)
        
        find(from: remoteStoreController, in: table, sortBy:TableMap.CommonColumn.createdAt.rawValue, skip: skip, limit: limit, on:queue, errorHandler: errorHandler) {[weak self] (rawResourceArray) in
            if let imageRepository = repository as? ImageRepository {
                self?.append(from: rawResourceArray, into: imageRepository, timeoutDuration:timeoutDuration, completion: { (updatedRepository,accumulatedErrors) in
                    if ResourceModelController.modelUpdateFailed(with: accumulatedErrors) {
                        DispatchQueue.main.async { [weak self] in
                            self?.delegate?.didFailToUpdateModel(with: nil)
                        }
                    } else {
                        completion?(updatedRepository as! T)
                    }
                })
                
            } else {
                self?.errorHandler.report(ModelError.UnsupportedRequest)
                completion?(repository)
            }
        }
    }
}

// MARK: - Utilities

/// NOTE: These methods do not notify the delegate that the model has updated.  These are
/// utility methods for *build*, *fill*, etc.  They are public for unit testing.
extension ResourceModelController {
    /**
     Asks the given *RemoteStoreController* to find the requested records
     - parameter table: the *RemoteStoreTableMap* schema entry to search within
     - parameter sortBy: An optional *String* to sort the query with
     - parameter skip: the number of records we want to skip in the query
     - parameter limit: the number of records we want to fetch
     - parameter queue: The *DispatchQueue* we need to call the completion block on
     - parameter errorHandler: an error handler used to report non-fatal errors
     - parameter completion: a *RawResourceArrayCompletion* that passes through the records fetched from the remote store
     - Returns: void
     */
    func find(from remoteStoreController:RemoteStoreController, in table:ImageTableMap, sortBy:String?, skip:Int, limit:Int, on queue:DispatchQueue, errorHandler:ErrorHandlerDelegate, completion:@escaping RawResourceArrayCompletion) {
        
        remoteStoreController.find(table: table, sortBy: sortBy, skip: skip, limit: limit, on:queue, errorHandler:errorHandler, completion:completion)
    }
    
    /**
     Appends the raw resource array into the model's repository of the given type.  Implemented only for *ImageResource*, for now.
     - parameter rawResourceArray: an array of *[String:AnyObject]* representing the raw model objects fetched from a remote store controller
     - parameter repository: the repository to append valued into
     - parameter timeoutDuration:  the *TimeInterval* to wait before timing out the request
     - parameter completion: a callback used to pass through the repository and errors accumulated during the process
     */
    func append(from rawResourceArray:RawResourceArray, into repository:ImageRepository, timeoutDuration:TimeInterval = ResourceModelController.defaultTimeout, completion:@escaping((ImageRepository,[Error]?)->Void)) {
        
        let mapGroup = DispatchGroup()
        ImageResource.extractImageResources(from: rawResourceArray, completion: {[weak self] (newRepository, accumulatedErrors) in
            let writeQueue = DispatchQueue(label: "\(writeQueueLabel).append")
            var updatedRepository = ImageRepository()
            writeQueue.sync {
                updatedRepository = repository
            }
            
            newRepository.map.forEach({ (object) in
                mapGroup.enter()
                writeQueue.async {
                    guard let strongSelf = self else {
                        mapGroup.leave()
                        return
                    }
                    strongSelf.networkSessionInterface.fetch(url: object.value.thumbnailURL, on: writeQueue, timeout:timeoutDuration, completion: { (data) in
                        if let data = data, let image = UIImage(data:data) {
                            object.value.thumbnailImage = image
                        }
                        
                        writeQueue.async {
                            updatedRepository.map[object.key] = object.value
                            mapGroup.leave()
                        }
                    })
                }
            })
            
            switch mapGroup.wait(timeout:.now() + DispatchTimeInterval.seconds(Int(timeoutDuration))) {
            case .timedOut:
                // this is ok, we have our map
                fallthrough
            case .success:
                completion(updatedRepository,accumulatedErrors)
            }
        })
    }
    
    /**
     Returns the *RemoteStoreTableMap* for a given repository, if possible
     - parameter repository: the repository that needs to be mapped to the table
     - Throws: any error generated by *tableMap(with:)
     - Returns: the located *RemoteStoreTableMap*
     */
    func tableMap<T>(for repository:T) throws -> ImageTableMap where T:Repository, T.AssociatedType:Resource {
        return try tableMap(with: T.AssociatedType.self)
    }
    
    /**
     Returns the *RemoteStoreTableMap* for a given repository, if possible
     - parameter type: the type of repository that needs to be mapped to the table
     - Throws: any error generated by *tableMap(with:)
     - Returns: the located *RemoteStoreTableMap*
     */
    func tableMap<T>(with type:T.Type) throws -> ImageTableMap where T:Resource {
        switch T.self {
        case is ImageResource.Type:
            return ImageTableMap.ImageResource
        default:
            throw ModelError.UnsupportedRequest
        }
    }
}

// MARK: - Sort

extension ResourceModelController {
    
    /**
     Fills the given repository with sorted records between the skip and limit indexes, and calls a callback with the resources that exist between the indexes
     - parameter repository: the *Repository* that needs to be filled
     - parameter skip: the number of items to skip when finding new resources
     - parameter limit: the number of items we want to fetch
     - parameter timeoutDuration:  the *TimeInterval* to wait before timing out the request
     - parameter queue: The *DispatchQueue* we need to call the completion block on
     - parameter completion: a callback used to pass back the filled resources
     - Throws: Throws any error surfaced from *fill*
     - Returns: void
     */
    func fillAndSort<T>(repository:T, skip:Int, limit:Int, timeoutDuration:TimeInterval = ResourceModelController.defaultTimeout, on queue:DispatchQueue, completion:@escaping ([T.AssociatedType])->Void) throws where T:Repository, T.AssociatedType:Resource {
        try fill(repository:repository, skip: skip, limit: limit, timeoutDuration:timeoutDuration, on:queue) { [weak self] (filledRepository) in
            self?.sort(repository: filledRepository, skip:skip, limit:limit, on:queue, completion: completion)
        }
    }
    
    /**
     Sorts the given repository with records between the skip and limit indexes, and calls a callback with the resources that exist between the indexes
     - parameter repository: the *Repository* that needs to be filled
     - parameter skip: the number of items to skip when finding new resources
     - parameter limit: the number of items we want to fetch
     - parameter queue: The *DispatchQueue* we need to call the completion block on
     - parameter completion: a callback used to pass back the filled resources
     - Returns: void
     */
    func sort<T>(repository:T, skip:Int, limit:Int, on queue:DispatchQueue, completion:@escaping ([T.AssociatedType])->Void) where T:Repository, T.AssociatedType:Resource {
        let sortQueue = DispatchQueue(label: "\(readQueueLabel).sort")
        sortQueue.async {
            let values = Array(repository.map.values).sorted { $0.updatedAt > $1.updatedAt }
            let endSlice = skip + limit < values.count ? skip + limit : values.count
            let resources = Array(values[skip..<(endSlice)])
            queue.async {
                completion(resources)
            }
        }
    }
}


// MARK: - Error Checking

extension ResourceModelController {
    /**
     Checks accumulated errors for types that signify that the model failed to update.  For example, if a record in the database fails to parse, then perhaps we should still allow the model update to pass even though the record itself is bad
     - parameter errors: An array of *Error* we need to check for serious errors
     - Returns: *true* if a serious error is found, *false* if *errors* is nil or if no serious errors are found
     */
    static func modelUpdateFailed(with errors:[Error]?) -> Bool {
        guard let errors = errors else {
            return false
        }
        
        var failedLaunch = false
        errors.forEach { (error) in
            switch error {
            case ModelError.InvalidURL:
                fallthrough
            case ModelError.IncorrectType:
                fallthrough
            case ModelError.MissingValue:
                fallthrough
            case ModelError.NoNewValues:
                return
            default:
                failedLaunch = true
            }
        }
        
        return failedLaunch
    }
}
