//
//  Created by Jan Gorman on 10/06/15.
//  Copyright (c) 2015 Schnaub. All rights reserved.
//

import UIKit
import SwiftMessageBar

class ViewController: UIViewController {
    
    @IBAction func showSuccess(sender: AnyObject) {
        SwiftMessageBar.SharedMessageBar.showMessageWithTitle(title: "Success", message: "bar", type: .Success, duration: 3) {
            println("oh hai")
        }
    }
    
    @IBAction func showError(sender: AnyObject) {
        SwiftMessageBar.SharedMessageBar.showMessageWithTitle(title: "Error", message: "bar", type: .Error, duration: 3) {
            println("oh hai")
        }
    }
    
    @IBAction func showInfo(sender: AnyObject) {
        SwiftMessageBar.SharedMessageBar.showMessageWithTitle(title: "Info", message: "bar", type: .Info, duration: 3) {
            println("oh hai")
        }
    }
    
}

