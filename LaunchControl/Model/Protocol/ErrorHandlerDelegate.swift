//
//  ErrorHandler.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Protocol wrapper for forwarding non-fatal errors to a third-party service such as Bugsnag or Crashlytics
protocol ErrorHandlerDelegate : LaunchService {
    func report(_ error:Error)
}

/// Debug error handling class used to pring error messages to the console
struct DebugErrorHandler : ErrorHandlerDelegate {
    /// The launch control key required by the protocol, nil in this class
    var launchControlKey: LaunchControlKey? = nil
    
    /**
     Posts the did launch error handler notification
     - parameter key: the API Key, nil in this class
     - parameter center: The *NotificationCenter* used to post the *DidLaunchErrorHandler* notification
     - Throws: does not throw in this class
     - Returns: void
     */
    func launch(with key:String? = nil, with center:NotificationCenter = NotificationCenter.default) throws {
        #if DEBUG
        center.post(name: NSNotification.Name.DidLaunchErrorHandler, object: nil)
        #endif
    }
    
    /**
     Reports an error using the DebugLogHandler
     - parameter error: The error to report
     - Returns: void
     */
    func report(_ error: Error) {
        #if DEBUG
        let message = "<<WARNING>>: \(error.localizedDescription)"
        let handler = DebugLogHandler()
        handler.console(message)
        #endif
    }
}
