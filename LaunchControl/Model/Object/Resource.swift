//
//  Resource.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Generic protocol used to allow the *ResourceModelController* to handle different types of internal resources
protocol Resource {
    var updatedAt: Date { get set }
}
