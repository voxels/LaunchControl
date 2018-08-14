//
//  LogHandler.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Protocol wrapper for logging messages and breadcrumbs to the console or to a third party service
protocol LogHandlerDelegate {
    func console(_ message:String)
}

/// Debug Log Handler used to print log messages to the console
struct DebugLogHandler : LogHandlerDelegate {
    func console(_ message:String) {
        print(message)
    }
}
