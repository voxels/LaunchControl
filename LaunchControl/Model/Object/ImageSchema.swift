//
//  ImageSchema.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Protocol used to define a type of *Resource* for images
protocol ImageSchema : Resource {
    var createdAt:Date { get set }
    var updatedAt:Date { get set }
    var filename:String { get set }
    var thumbnailURL:URL { get set }
    var fileURL:URL { get set }
}
