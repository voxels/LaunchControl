//
//  RemoteStoreController.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

typealias RawResourceArrayCompletion = (RawResourceArray) -> Void

/// Protocol wrapper for handling a remote store service such as Parse
protocol RemoteStoreController : LaunchService {
    var serverURLString:String { get }
    var defaultQuerySize:Int { get }
    
    func find(table: RemoteStoreTableMap, sortBy: String?, skip: Int, limit: Int, on queue:DispatchQueue, errorHandler:ErrorHandlerDelegate, completion: @escaping RawResourceArrayCompletion) -> Void
    func count(table:RemoteStoreTableMap, on queue:DispatchQueue, errorHandler:ErrorHandlerDelegate, completion:@escaping((Int)->Void))
    func validate(sortBy:String, in schemaClass:RemoteStoreTableMap) throws -> Void
}

extension RemoteStoreController {
    /**
     Validates that the sortBy column name exists in the *RemoteStoreTable* type
     - parameter sortBy: the *String* of the column name to validate
     - parameter table: the *RemoteStoreTable* containing the desired column
     - Throws: a *RemoteStoreError.InvalidSortByColumn* error if the column does not exist in the table schema
     */
    func validate(sortBy:String, in table:RemoteStoreTableMap) throws -> Void {
        if RemoteStoreTableMap.CommonColumn.init(rawValue: sortBy) != nil{
            return
        }
        
        switch table {
        case .ImageResource:
            if RemoteStoreTableMap.ImageResourceColumn.init(rawValue: sortBy) != nil {
                return
            }
        }
        
        throw RemoteStoreError.InvalidSortByColumn
    }
}
