//
//  Created by Jan Gorman on 10/06/15.
//  Copyright (c) 2015 Schnaub. All rights reserved.
//

import UIKit
import SwiftMessageBar

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var messageBarConfig = MessageBarConfig(successColor: UIColor.orangeColor(), statusBarHidden: true)
        SwiftMessageBar.setSharedConfig(messageBarConfig)
    }
    
    @IBAction func showSuccess(sender: AnyObject) {
        SwiftMessageBar.showMessageWithTitle("Success", message: "bar", type: .Success, duration: 3) {
            println("oh hai")
        }
    }
    
    @IBAction func showError(sender: AnyObject) {
        SwiftMessageBar.showMessageWithTitle("Error", message: "bar", type: .Error, duration: 3) {
            println("oh hai")
        }
    }
    
    @IBAction func showInfo(sender: AnyObject) {
        SwiftMessageBar.showMessageWithTitle("Info", message: "bar", type: .Info, duration: 3) {
            println("oh hai")
        }
    }
    
}

