//
//  Repository.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Generic protocol used to define the map from a hash value string to an associated type
/// Used to create repositories that can be handled by the *ResourceModelController*

protocol Repository {
    associatedtype AssociatedType
    var map:[String:AssociatedType] { get set }
}
