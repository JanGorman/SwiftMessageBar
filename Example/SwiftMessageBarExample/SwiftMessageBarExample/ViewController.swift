//
//  Copyright (c) 2015 Schnaub. All rights reserved.
//

import UIKit
import SwiftMessageBar

final class ViewController: UIViewController {
    
  private var uuid: UUID?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let messageBarConfig = SwiftMessageBar.Config(successColor: .orange, isStatusBarHidden: true)
    SwiftMessageBar.setSharedConfig(messageBarConfig)
  }

  @IBAction private func showSuccess() {
    let message = "A really long message can go here, to provide a description for the user"
    uuid = SwiftMessageBar.showMessage(withTitle: nil, message: message, type: .success, duration: 3, dismiss: false) {
      print("Dismiss callback")
    }
  }

  @IBAction private func showError() {
    let message = "A really long message can go here, to provide a description for the user"
    uuid = SwiftMessageBar.showMessage(withTitle: "Error", message: message, type: .error, duration: 3) {
      print("Dismiss callback")
    }
  }
  
  @IBAction private func showInfo() {
    let message = "A really long message can go here, to provide a description for the user"
    uuid = SwiftMessageBar.showMessage(withTitle: "Info", message: message, type: .info, duration: 3) {
      print("Dismiss callback")
    }
  }

  @IBAction private func clearAll() {
    SwiftMessageBar.sharedMessageBar.cancelAll(force: true)
    uuid = nil
  }

  @IBAction private func clearCurrent() {
    if let id = uuid {
      SwiftMessageBar.sharedMessageBar.cancel(withId: id)
      uuid = nil
    }
  }

  @IBAction private func showSuccessWithAccesoryView() {
    let message = "A really long message can go here, to provide a description for the user"
    let button = UIButton(type: .roundedRect, primaryAction: UIAction { _ in
      print("Button tapped")
    })
    button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    button.setContentHuggingPriority(.required, for: .horizontal)
    button.setTitle("Open", for: .normal)
    button.tintColor = .orange
    button.backgroundColor = .white
    button.layer.cornerRadius = 6

    uuid = SwiftMessageBar.showMessage(withTitle: nil, message: message, type: .success, duration: 3, dismiss: false, accessoryView: button ) {
      print("Dismiss callback")
    }
  }

}
