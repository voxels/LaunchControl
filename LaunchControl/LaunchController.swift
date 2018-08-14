//
//  LaunchController.swift
//  LaunchControl
//
//  Created by Michael Edgcumbe on 8/14/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

/// Class that launches potentially asynchronous launch services and signals when the expected services
/// have been successfully launched, or sends a failed to launch notification if the time out is reached
class LaunchController {
    /// The resource model we use to create the model
    var resourceModelController:ResourceModelController
    
    /// An array of notifications we need to receive before confirming that launch is complete
    var waitForNotifications = Set<Notification.Name>()
    
    /// An array of notification names for those we have already received
    var receivedNotifications = Set<Notification.Name>()
    
    /// The duration, in seconds, that the launch controller waits before timing out
    var timeoutDuration:TimeInterval = 60
    
    /// A timer used to push launch forward if a service is not reached
    var timeoutTimer:Timer?
    
    /// Flag to indicate of the error reporting service has been launched
    var didLaunchErrorHandler = false
    
    /// We use the debug error handler until we have the Bugsnag service
    var currentErrorHandler:ErrorHandlerDelegate {
        return DebugErrorHandler()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    init(with modelController:ResourceModelController) {
        resourceModelController = modelController
    }
    
    /**
     Calls the launch method for each service, retains any services that need to stay alive,
     and assigns the notification names we need to receive before posting a *DidCompleteLaunch* notification
     - parameter services: An array of *LaunchService* that need to be launched
     - parameter center: the *NotificationCenter* to deregister and post *DidCompleteLaunch* on
     - Returns: void
     */
    func launch(services:[LaunchService], with center:NotificationCenter = NotificationCenter.default) {
        startTimeOutTimer(duration:timeoutDuration, with:center)
        waitForLaunchNotifications(for: services, with:center)
        attempt(services, with:center, errorHandler: currentErrorHandler)
    }
}

// MARK: - Launch Control
extension LaunchController {
    /**
     Registers for *DidCompleteLaunch* notification for each service in the given array
     - parameter services: an array of *LaunchService* that should be checked for waiting to complete the launch
     - parameter center: the *NotificationCenter* to deregister and post *DidCompleteLaunch* on
     - Returns: void
     */
    func waitForLaunchNotifications(for services:[LaunchService], with center:NotificationCenter = NotificationCenter.default) {
        services.forEach { (service) in
            waitIfNecessary(service, awaitedServices:services, with:center)
        }
    }
    
    /**
     Attempts to launch each of the services in the given array and handle the error if the launch fails
     - parameter services: an array of *LaunchService* that need to be launched
     - parameter center: the *NotificationCenter* used to post the *DidLaunch...* notification
     - parameter errorHandler: The *ErrorHandlerDelegate* used to report an error
     - Returns: void
     */
    func attempt(_ services:[LaunchService], with center:NotificationCenter = NotificationCenter.default, errorHandler:ErrorHandlerDelegate) {
        services.forEach { (service) in
            do {
                try service.launch(with:service.launchControlKey?.decoded(), with:center)
            } catch {
                handle(error: error, with:errorHandler)
            }
        }
    }
    
    /**
     Adds a check for services that the controller should wait for before sending a final *DidCompleteLaunch* notification
     - parameter service: A *LaunchService* that needs to be checked for delaying the final *DidCompleteLaunch* notification
     - parameter awaitedServices: An array of *LaunchService* that should be waited for
     - parameter center: the *NotificationCenter* to deregister and post *DidCompleteLaunch* on
     - Returns: void
     */
    func waitIfNecessary(_ service: LaunchService, awaitedServices:[LaunchService], with center:NotificationCenter = NotificationCenter.default) {
        if awaitedServices.contains(where: { (compareService) -> Bool in
            return service.launchControlKey == compareService.launchControlKey
        }), let name = didLaunchNotificationName(for: service) {
            waitForNotifications.insert(name)
            register(for: name, with:center)
        }
    }
    
    /**
     Adds a notification to the set of received notifications and compares the set to the notifications we are waiting for to the notifications we have received.  If the *receivedNotifications* are verified against the *waitForNotifications*, the *galleryModel* is constructed.
     - parameter notification: The notification received
     - parameter center: The notification center to post a *DidFailLaunch* notification to, if necessary
     - Returns: void
     */
    func checkLaunchComplete(with notification:Notification, for center:NotificationCenter = NotificationCenter.default) {
        receivedNotifications.insert(notification.name)
        if verify(received: receivedNotifications, with: waitForNotifications) {
            resourceModelController.delegate = self
            let fetchQueue = DispatchQueue(label: "com.secretatomics.launchcontroller.fetch", qos: .userInteractive, attributes: [.concurrent], autoreleaseFrequency: .inherit, target: nil)
            fetchQueue.async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.resourceModelController.build(using: strongSelf.resourceModelController.remoteStoreController, for: ImageResource.self, on:fetchQueue, with: strongSelf.resourceModelController.errorHandler, timeoutDuration:strongSelf.timeoutDuration)
            }
        }
    }
    
    /**
     Verifies that we have received all of the expected *DidCompleteLaunch* notifications
     - parameter receivedNotifications: a set of the notifications the class has received since launch
     - parameter expectedNotifications: a set of the notifications that we expect to receive before launch is complete
     - Returns: True if all the expected notifications have been received, false if an expected notification hasn't been received
     */
    func verify(received receivedNotifications:Set<Notification.Name>, with expectedNotifications:Set<Notification.Name>)->Bool {
        for expected in expectedNotifications {
            if !receivedNotifications.contains(expected) {
                return false
            }
        }
        
        return true
    }
    
    /**
     Signals that launch is complete with the *DidCompleteLaunch* notification. Resets the notification registration and time out timer for self
     - parameter center: the *NotificationCenter* to deregister and post *DidCompleteLaunch* on
     - Returns: void
     */
    func signalLaunchComplete(with center:NotificationCenter = NotificationCenter.default) {
        reset(with: center)
        center.post(name: Notification.Name.DidCompleteLaunch, object: nil)
    }
    
    /**
     Signals that launch has failed with the *DidFailLaunch* notification. Resets the notification registration and time out timer for self
     - parameter reason: an optional *String* to include as the reason for failure
     - parameter center: the *NotificationCenter* to deregister and post *DidCompleteLaunch* on
     - Returns: void
     */
    func signalLaunchFailed(reason:String?, with center:NotificationCenter = NotificationCenter.default) {
        reset(with: center)
        
        guard let reason = reason else {
            center.post(name: Notification.Name.DidFailLaunch, object: nil)
            return
        }
        
        let notification = Notification(name: Notification.Name.DidFailLaunch, object: nil, userInfo: [NSLocalizedFailureReasonErrorKey:reason])
        center.post(notification)
    }
    
    /**
     Resets the notification sets and *timeOutTimer*, removes self from the notification center
     - parameter center: the center to remove observer status from
     - Returns: void
     */
    func reset(with center:NotificationCenter = NotificationCenter.default) {
        center.removeObserver(self)
        receivedNotifications = Set<Notification.Name>()
        waitForNotifications = Set<Notification.Name>()
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
}

// MARK: - Launch Time Out
extension LaunchController {
    /**
     Starts the time out timer that posts a *DidFailLaunch* notification after the duration has elapsed
     - parameter duration: the TimeInterval that the class should wait for before posting the failure notification
     - parameter center: the *NotificationCenter* to deregister and post *DidCompleteLaunch* on
     - Returns: void
     */
    func startTimeOutTimer(duration:TimeInterval, with center:NotificationCenter = NotificationCenter.default) {
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { [weak self] (timer) in
            let reason = "Launch timed out after \(String(describing:self?.timeoutDuration)) seconds"
            self?.signalLaunchFailed(reason: reason)
        })
    }
}

// MARK: - Error Handling
extension LaunchController {
    /**
     Handles the error with the *errorHandlerDelegate* if one is present or an instance of *DebugErrorHandler* if the error handler hasn't been init
     - parameter error: The error that needs to be handled
     - parameter handler: The error handler reporting the error
     - Returns: void
     */
    func handle(error:Error, with handler:ErrorHandlerDelegate?) {
        guard let handler = handler else {
            let debugHandler = DebugErrorHandler()
            debugHandler.report(error)
            return
        }
        
        handler.report(error)
    }
}

// MARK: - Notifications
extension LaunchController {
    /**
     Removes self from the notification center observers
     - parameter name: The notification name to deregister
     - parameter center: The notification center to deregister from
     - Returns: void
     */
    func deregisterForNotification(_ name:Notification.Name, with center:NotificationCenter = NotificationCenter.default) {
        center.removeObserver(self, name: name, object: nil)
    }
    
    /**
     Registers self for the given notification names and assigns the handle(notification:) selector
     - parameter name: The notification name to register
     - parameter center: The notification center to register with
     - Returns: void
     */
    func register(for name:Notification.Name, with center:NotificationCenter = NotificationCenter.default) {
        deregisterForNotification(name, with:center)
        center.addObserver(self, selector:#selector(handle(notification:)), name: name, object: nil)
    }
    
    /**
     Assigns a *didLaunch...* notification name to a LaunchService
     - parameter service: the *LaunchService* that needs to be checked for completion
     - Returns: a Notification.Name for the *LaunchService* or nil if none is assigned
     */
    func didLaunchNotificationName(for service:LaunchService)->Notification.Name? {
        if service is RemoteStoreController {
            return Notification.Name.DidLaunchRemoteStore
        } else if service is ErrorHandlerDelegate {
            return Notification.Name.DidLaunchErrorHandler
        }
        
        return nil
    }
    
    /**
     Handles incoming notifications
     - parameter notification: the notification received from the default *NotificationCenter*
     - Returns: void
     */
    @objc func handle(notification:Notification) {
        switch notification.name {
        case Notification.Name.DidLaunchErrorHandler:
            didLaunchErrorHandler = true
            fallthrough
        case Notification.Name.DidLaunchRemoteStore:
            fallthrough
        case Notification.Name.DidLaunchBucketHandler:
            fallthrough
        case Notification.Name.DidLaunchSharedCached:
            checkLaunchComplete(with: notification)
        default:
            handle(error: LaunchError.UnexpectedLaunchNotification, with:currentErrorHandler)
        }
    }
}

// MARK: - GalleryViewModelDelegate
extension LaunchController : ResourceModelControllerDelegate {
    /**
     Delegate method called when the *ResourceModelController* successfully updated
     - Returns: void
     */
    func didUpdateModel() {
        resourceModelController.delegate = nil
        signalLaunchComplete()
    }
    
    /**
     Delegate method called when the *ResourceModelController* failed to update
     - parameter reason: an optional *String* to include as the reason why the update failed
     - Returns: void
     */
    func didFailToUpdateModel(with reason:String?) {
        resourceModelController.delegate = nil
        signalLaunchFailed(reason: reason)
    }
}

// MARK: - View
extension LaunchController {
    func showReachabilityView(in rootViewController:UINavigationController) {
        // TODO: show reachability view
        print("show reachability view")
    }
    
    static func showLockoutViewController(_ lockoutViewController:LockoutViewController, with window:UIWindow?, message:String?) {
        lockoutViewController.message = message
        window?.rootViewController = lockoutViewController
        showFatalAlert(with: message ?? "Please contact the developer if you see this message.", in: lockoutViewController)
    }
    
    static func showFatalAlert(with message:String, in viewController:UIViewController?) {
        guard let viewController = viewController else {
            // No further recourse.  The app is dead.
            fatalError("Missing root window view controller")
        }
        
        let alertController = UIAlertController(title: "Fatal Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            fatalError("turtles")
        }
        alertController.addAction(okAction)
        alertController.show(viewController, sender: nil)
    }
}


// MARK: - API Key Security
private extension LaunchController {
    #if DEBUG
    /**
     Debug method used to print the bytes for an array of *LaunchControllerKey* encrypted by the Obfuscator class
     - parameter keys: an array of *LaunchControllerKey* to print to the console
     - parameter handler: The *LogHandlerDelegate* responsible for displaying the string
     */
    func show(hidden keys:[LaunchControlKey], with handler:LogHandlerDelegate = DebugLogHandler()) {
        for key in keys {
            let bytes = key.generate(with:Obfuscator.saltObjects())
            handler.console("Key for \(key):")
            handler.console("\t\(String(describing:bytes))")
            handler.console("Decoded string:")
            handler.console(key.decoded())
            handler.console("\n\n")
        }
    }
    #endif
}
