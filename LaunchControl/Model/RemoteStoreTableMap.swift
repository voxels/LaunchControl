//
//  RemoteStoreTable.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Enum representing the table and column names for the schema
enum RemoteStoreTableMap : String {
    enum CommonColumn : String {
        case objectId
        case updatedAt
        case createdAt
    }
    
    case ImageResource = "Resource"
    enum ImageResourceColumn : String {
        case filename
        case thumbnailURLString
        case fileURLString
        case width
        case height
    }
}
