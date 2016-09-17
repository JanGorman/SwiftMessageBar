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
    let messageBarConfig = MessageBarConfig(successColor: .orange, statusBarHidden: true)
    SwiftMessageBar.setSharedConfig(messageBarConfig)
  }
  
  @IBAction private func showSuccess(_ sender: AnyObject) {
    let message = "A really long message can go here, to provide a description for the user"
    uuid = SwiftMessageBar.showMessageWithTitle(nil, message: message, type: .success, duration: 3, dismiss: false) {
      print("oh hai")
    }
  }
  
  @IBAction private func showError(_ sender: AnyObject) {
    let message = "A really long message can go here, to provide a description for the user"
    uuid = SwiftMessageBar.showMessageWithTitle("Error", message: message, type: .error, duration: 3) {
      print("oh hai")
    }
  }
  
  @IBAction private func showInfo(_ sender: AnyObject) {
    let message = "A really long message can go here, to provide a description for the user"
    uuid = SwiftMessageBar.showMessageWithTitle("Info", message: message, type: .info, duration: 3) {
      print("oh hai")
    }
  }
  
  @IBAction private func clearAll(_ sender: AnyObject) {
    SwiftMessageBar.SharedMessageBar.cancelAll(force: true)
    uuid = nil
  }
  
  @IBAction private func clearCurrent(_ sender: AnyObject) {
    if let id = uuid {
      SwiftMessageBar.SharedMessageBar.cancelWithId(id)
      uuid = nil
    }
  }

}
