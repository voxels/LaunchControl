//
//  LockoutViewController.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/4/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

class LockoutViewController: UIViewController {
    
    var message:String?
    
    var messageLabel:UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .red
    }
    
    func refresh(with text:String) {
        if messageLabel != nil {
            messageLabel?.removeFromSuperview()
            messageLabel = nil
        }
    }
}
