//
//  ImageRepository.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/4/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

typealias ImageRepositoryCompletion = (ImageRepository,[Error]?)->Void

/// Implementation of the *Repository* protocol for images
class ImageRepository : Repository {
    typealias AssociatedType = ImageResource
    
    /// A map of image resources 
    var map: [String : ImageResource] = [:]
}
