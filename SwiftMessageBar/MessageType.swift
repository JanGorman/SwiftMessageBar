//
//  Copyright © 2018 Schnaub. All rights reserved.
//

import UIKit

public enum MessageType {
  case error, success, info

  func backgroundColor(fromConfig config: SwiftMessageBar.Config) -> UIColor {
    switch self {
    case .error:
      return config.errorColor
    case .info:
      return config.infoColor
    case .success:
      return config.successColor
    }
  }

  func image(fromConfig config: SwiftMessageBar.Config) -> UIImage? {
    switch self {
    case .error:
      return config.errorIcon
    case .info:
      return config.infoIcon
    case .success:
      return config.successIcon
    }
  }

}
