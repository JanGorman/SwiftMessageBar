//
//  Created by Jan Gorman on 10/06/15.
//  Copyright (c) 2015 Schnaub. All rights reserved.
//

import UIKit
import SwiftMessageBar

class ViewController: UIViewController {
    
  private var uuid: UUID?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let messageBarConfig = MessageBarConfig(successColor: .orange, isStatusBarHidden: true)
    SwiftMessageBar.setSharedConfig(messageBarConfig)
  }

  @IBAction private func showSuccess(_ sender: AnyObject) {
    let message = "A really long message can go here, to provide a description for the user"
    uuid = SwiftMessageBar.showMessageWithTitle(nil, message: message, type: .success, duration: 3, dismiss: false) {
      print("Dismiss callback")
    }
  }

  @IBAction private func showError(_ sender: AnyObject) {
    let message = "A really long message can go here, to provide a description for the user"
    uuid = SwiftMessageBar.showMessageWithTitle("Error", message: message, type: .error, duration: 3) {
      print("Dismiss callback")
    }
  }
  
  @IBAction private func showInfo(_ sender: AnyObject) {
    let message = "A really long message can go here, to provide a description for the user"
    uuid = SwiftMessageBar.showMessageWithTitle("Info", message: message, type: .info, duration: 3) {
      print("Dismiss callback")
    }
  }

  @IBAction private func clearAll(_ sender: AnyObject) {
    SwiftMessageBar.sharedMessageBar.cancelAll(force: true)
    uuid = nil
  }

  @IBAction private func clearCurrent(_ sender: AnyObject) {
    if let id = uuid {
      SwiftMessageBar.sharedMessageBar.cancelWithId(id)
      uuid = nil
    }
  }

}
