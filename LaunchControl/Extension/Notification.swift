//
//  Notification.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let DidCompleteLaunch = Notification.Name.init("DidCompleteLaunch")
    static let DidLaunchBucketHandler = Notification.Name.init("DidLaunchBucketHandler")
    static let DidLaunchErrorHandler = Notification.Name.init("DidLaunchErrorHandler")
    static let DidLaunchRemoteStore = Notification.Name.init("DidLaunchRemoteStore")
    static let DidLaunchSharedCached = Notification.Name.init("DidLaunchSharedCache")
    static let DidFailLaunch = Notification.Name.init("DidFailLaunch")
}
