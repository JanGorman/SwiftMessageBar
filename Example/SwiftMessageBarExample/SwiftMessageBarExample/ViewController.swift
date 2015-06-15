//
//  Created by Jan Gorman on 10/06/15.
//  Copyright (c) 2015 Schnaub. All rights reserved.
//

import UIKit
import SwiftMessageBar

class ViewController: UIViewController {
    
    private var uuid: NSUUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let messageBarConfig = MessageBarConfig(successColor: UIColor.orangeColor(), statusBarHidden: true)
        SwiftMessageBar.setSharedConfig(messageBarConfig)
    }
    
    @IBAction func showSuccess(sender: AnyObject) {
        uuid = SwiftMessageBar.showMessageWithTitle(nil, message: "A really long message can go here, to provide a description for the user", type: .Success, duration: 3) {
            println("oh hai")
        }
    }

    @IBAction func showError(sender: AnyObject) {
        uuid = SwiftMessageBar.showMessageWithTitle("Error", message: "A really long message can go here, to provide a description for the user", type: .Error, duration: 3) {
            println("oh hai")
        }
    }

    @IBAction func showInfo(sender: AnyObject) {
        uuid = SwiftMessageBar.showMessageWithTitle("Info", message: "A really long message can go here, to provide a description for the user", type: .Info, duration: 3) {
            println("oh hai")
        }
    }

    @IBAction func clearAll(sender: AnyObject) {
        SwiftMessageBar.SharedMessageBar.cancelAll()
        uuid = nil
    }

    @IBAction func clearCurrent(sender: AnyObject) {
        if let id = uuid {
            SwiftMessageBar.SharedMessageBar.cancelWithId(id)
            uuid = nil
        }
    }

}

