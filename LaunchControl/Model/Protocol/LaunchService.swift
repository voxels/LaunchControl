//
//  LaunchService.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

// Generic protocol definition for launching services from the LaunchController class
protocol LaunchService {
    var launchControlKey:LaunchControlKey? { get }
    func launch(with key:String?, with center:NotificationCenter) throws
}
