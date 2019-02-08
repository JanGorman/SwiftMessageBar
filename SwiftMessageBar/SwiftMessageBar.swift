//
//  Copyright (c) 2015 Schnaub. All rights reserved.
//

import UIKit

public typealias Callback = () -> Void

public final class SwiftMessageBar {

  public struct Config {

    public struct Defaults {
      public static let errorColor: UIColor = .red
      public static let successColor: UIColor = .green
      public static let infoColor: UIColor = .blue
      public static let titleColor: UIColor = .white
      public static let messageColor: UIColor = .white
      public static let isStatusBarHidden = false
      public static let titleFont: UIFont = .boldSystemFont(ofSize: 16)
      public static let messageFont: UIFont = .systemFont(ofSize: 14)
      public static let isHapticFeedbackEnabled = true
    }

    let errorColor: UIColor
    let successColor: UIColor
    let infoColor: UIColor
    let titleColor: UIColor
    let messageColor: UIColor
    let isStatusBarHidden: Bool
    let successIcon: UIImage?
    let infoIcon: UIImage?
    let errorIcon: UIImage?
    let titleFont: UIFont
    let messageFont: UIFont
    let isHapticFeedbackEnabled: Bool

    public init(errorColor: UIColor = Defaults.errorColor,
                successColor: UIColor = Defaults.successColor,
                infoColor: UIColor = Defaults.infoColor,
                titleColor: UIColor = Defaults.titleColor,
                messageColor: UIColor = Defaults.messageColor,
                isStatusBarHidden: Bool = Defaults.isStatusBarHidden,
                successIcon: UIImage? = nil,
                infoIcon: UIImage? = nil,
                errorIcon: UIImage? = nil,
                titleFont: UIFont = Defaults.titleFont,
                messageFont: UIFont = Defaults.messageFont,
                isHapticFeedbackEnabled: Bool = Defaults.isHapticFeedbackEnabled) {
      self.errorColor = errorColor
      self.successColor = successColor
      self.infoColor = infoColor
      self.titleColor = titleColor
      self.messageColor = messageColor
      self.isStatusBarHidden = isStatusBarHidden
      let bundle = Bundle(for: SwiftMessageBar.self)
      self.successIcon = successIcon ?? UIImage(named: "icon-success", in: bundle, compatibleWith: nil)
      self.infoIcon = infoIcon ?? UIImage(named: "icon-info", in: bundle, compatibleWith: nil)
      self.errorIcon = errorIcon ?? UIImage(named: "icon-error", in: bundle, compatibleWith: nil)
      self.titleFont = titleFont
      self.messageFont = messageFont
      self.isHapticFeedbackEnabled = isHapticFeedbackEnabled
    }

    public class Builder {

      private var errorColor: UIColor?
      private var successColor: UIColor?
      private var infoColor: UIColor?
      private var titleColor: UIColor?
      private var messageColor: UIColor?
      private var isStatusBarHidden: Bool?
      private var successIcon: UIImage?
      private var infoIcon: UIImage?
      private var errorIcon: UIImage?
      private var titleFont: UIFont?
      private var messageFont: UIFont?
      private var isHapticFeedbackEnabled: Bool?

      public init() {
      }

      public func withErrorColor(_ color: UIColor) -> Builder {
        errorColor = color
        return self
      }

      public func withSuccessColor(_ color: UIColor) -> Builder {
        successColor = color
        return self
      }

      public func withInfoColor(_ color: UIColor) -> Builder {
        infoColor = color
        return self
      }

      public func withTitleColor(_ color: UIColor) -> Builder {
        titleColor = color
        return self
      }

      public func withMessageColor(_ color: UIColor) -> Builder {
        messageColor = color
        return self
      }

      public func withStatusBarHidden(_ isHidden: Bool) -> Builder {
        isStatusBarHidden = isHidden
        return self
      }

      public func withSuccessIcon(_ icon: UIImage) -> Builder {
        successIcon = icon
        return self
      }

      public func withInfoIcon(_ icon: UIImage) -> Builder {
        infoIcon = icon
        return self
      }

      public func withErrorIcon(_ icon: UIImage) -> Builder {
        errorIcon = icon
        return self
      }

      public func withTitleFont(_ font: UIFont) -> Builder {
        titleFont = font
        return self
      }

      public func withMessageFont(_ font: UIFont) -> Builder {
        messageFont = font
        return self
      }

      public func withHapticFeedbackEnabled(_ isEnabled: Bool) -> Builder {
        isHapticFeedbackEnabled = isEnabled
        return self
      }

      public func build() -> Config {
        return Config(errorColor: errorColor ?? Defaults.errorColor,
                      successColor: successColor ?? Defaults.successColor,
                      infoColor: infoColor ?? Defaults.infoColor,
                      titleColor: titleColor ?? Defaults.titleColor,
                      messageColor: messageColor ?? Defaults.messageColor,
                      isStatusBarHidden: isStatusBarHidden ?? Defaults.isStatusBarHidden,
                      successIcon: successIcon, infoIcon: infoIcon, errorIcon: errorIcon,
                      titleFont: titleFont ?? Defaults.titleFont,
                      messageFont: messageFont ?? Defaults.messageFont,
                      isHapticFeedbackEnabled: isHapticFeedbackEnabled ?? Defaults.isHapticFeedbackEnabled)
      }

    }

  }

  public static let sharedMessageBar = SwiftMessageBar()
  
  private static let showHideDuration: TimeInterval = 0.25

  private var config: Config
  private var messageWindow: MessageWindow?
  private var timer: Timer?
    
  public var tapHandler : (() -> Void)?
  
  private func newMessageWindow() -> MessageWindow {
    let messageWindow = MessageWindow()
    messageWindow.frame = UIScreen.main.bounds
    messageWindow.isHidden = false
    messageWindow.windowLevel = .normal
    messageWindow.backgroundColor = .clear
    messageWindow.messageBarController.statusBarHidden = config.isStatusBarHidden
    messageWindow.rootViewController = messageWindow.messageBarController
    return messageWindow
  }
  
  private var messageQueue: Queue<Message>
  private var isMessageVisible = false
  
  private init() {
    messageQueue = Queue<Message>()
    config = Config()
  }
  
  /// Set a message bar configuration used by all displayed messages.
  public static func setSharedConfig(_ config: Config) {
    sharedMessageBar.config = config
  }
  
  /// Display a message
  ///
  /// - Parameters:
  ///     - title: An optional title
  ///     - message: An optional message
  ///     - type: The message type
  ///     - duration: The time interval in seconds to show the message for
  ///     - dismiss: Does the message automatically dismiss or not
  ///     - languageDirection: Set an optional language direction if you require RTL support outside of what the system provides
  ///                          i.e. no need to set this parameter when NSLocale already is set to the proper languageDirection
  ///     - accessoryView: An optional view to show in the right of the Message Bar
  ///     - callback: An optional callback to execute when the user taps on a message to dismiss it.
  /// - Returns: A UUID for the message. Can be used to cancel the display of a specific message
  @discardableResult
  public static func showMessage(withTitle title: String? = nil, message: String? = nil, type: MessageType,
                                 duration: TimeInterval = 3, dismiss: Bool = true,
                                 languageDirection: NSLocale.LanguageDirection = .unknown,
                                 accessoryView: UIView? = nil,
                                 callback: Callback? = nil) -> UUID {
    return sharedMessageBar.showMessage(withTitle: title, message: message, type: type, duration: duration,
                                        dismiss: dismiss, languageDirection: languageDirection, accessoryView: accessoryView, callback: callback)
  }
  
  /// Display a message
  ///
  /// - Parameters:
  ///     - title: An optional title
  ///     - message: An optional message
  ///     - type: The message type
  ///     - duration: The time interval in seconds to show the message for
  ///     - dismiss: Does the message automatically dismiss or not
  ///     - languageDirection: Set an optional language direction if you require RTL support outside of what the system provides
  ///                          i.e. no need to set this parameter when NSLocale already is set to the proper languageDirection
  ///     - accessoryView: An optional view to show in the right of the Message Bar
  ///     - callback: An optional callback to execute when the user taps on a message to dismiss it.
  /// - Returns: A UUID for the message. Can be used to cancel the display of a specific message
  @discardableResult
  public func showMessage(withTitle title: String? = nil, message: String? = nil, type: MessageType,
                          duration: TimeInterval = 3, dismiss: Bool = true,
                          languageDirection: NSLocale.LanguageDirection = .unknown,
                          accessoryView: UIView? = nil,
                          callback: Callback? = nil) -> UUID {
    let message = Message(type: type, title: title, message: message,
                          backgroundColor: type.backgroundColor(fromConfig: config), titleFontColor: config.titleColor,
                          messageFontColor: config.messageColor, icon: type.image(fromConfig: config), duration: duration,
                          dismiss: dismiss, callback: callback, languageDirection: languageDirection,
                          titleFont: config.titleFont, messageFont: config.messageFont, accessoryView: accessoryView)
    if languageDirection == .rightToLeft {
      message.flipHorizontal()
    }
    messageQueue.enqueue(message)
    if !isMessageVisible {
      dequeueNextMessage()
    }
    return message.id
  }
  
  /// Cancels the display of all messages.
  ///
  /// - Parameter force: A boolean to force immediate dismissal (without animation). Defaults to `false`
  public func cancelAll(force: Bool = false) {
    guard !isMessageVisible && messageQueue.isEmpty || force else { return }
    
    if let message = visibleMessage {
      if force {
        message.removeFromSuperview()
        messageWindow = nil
      } else {
        dismissMessage(message)
      }
    }
    resetTimer()
    isMessageVisible = false
    messageQueue.removeAll()
  }
  
  /// Cancels the display of a specific message
  ///
  /// - Parameter id: The UUID of the message to cancel.
  public func cancel(withId id: UUID) {
    if let message = visibleMessage, message.id == id {
      dismissMessage(message)
      messageQueue.removeElement(message)
    }
  }
  
  private var visibleMessage: Message? {
    return messageWindow?.messageBarView.subviews.compactMap { $0 as? Message }.first
  }
  
  private func dequeueNextMessage() {
    guard let message = messageQueue.dequeue() else { return }
    
    let messageWindow: MessageWindow
    if let existensWindow = self.messageWindow {
      messageWindow = existensWindow
    } else {
      messageWindow = newMessageWindow()
      self.messageWindow = messageWindow
    }
    
    messageWindow.messageBarView.addSubview(message)
    messageWindow.messageBarView.bringSubviewToFront(message)
    isMessageVisible = true
    message.configureSubviews()
    message.isHidden = false
    message.setNeedsUpdateConstraints()
    
    let gesture = UITapGestureRecognizer(target: self, action: #selector(tap))
    message.addGestureRecognizer(gesture)

    UIView.animate(withDuration: SwiftMessageBar.showHideDuration, animations: {
      let frame = message.frame.offsetBy(dx: 0, dy: message.estimatedHeight)
      message.frame = frame
    }, completion: { _ in
      self.provideHapticFeedback(for: message)
    })

    if message.dismiss {
      resetTimer()
      timer = Timer.scheduledTimer(timeInterval: message.duration, target: self, selector: #selector(dismiss),
                                   userInfo: nil, repeats: false)
    }
  }

  private func provideHapticFeedback(for message: Message) {
    if #available(iOS 10.0, *), config.isHapticFeedbackEnabled && DeviceType.isPhone {
      let generator = UINotificationFeedbackGenerator()
      switch message.type! {
      case .error:
        generator.notificationOccurred(.error)
      case .info:
        generator.notificationOccurred(.warning)
      case .success:
        generator.notificationOccurred(.success)
      }
    }
  }
  
  private func resetTimer() {
    timer?.invalidate()
    timer = nil
  }
    
  @objc
  private func dismiss() {
    resetTimer()
    if let message = visibleMessage {
      dismissMessage(message)
    }
  }
    
  private func dismissMessage(_ message: Message) {
    dismissMessage(message, fromGesture: false)
  }
  
  @objc
  private func tap(_ gesture: UITapGestureRecognizer) {
    let message = gesture.view as! Message
    dismissMessage(message, fromGesture: true)
    tapHandler?()
  }
    
  private func dismissMessage(_ message: Message, fromGesture: Bool) {
    if message.isHit {
      return
    }
    
    message.isHit = true
    
    UIView.animate(withDuration: SwiftMessageBar.showHideDuration, delay: 0, options: [], animations: {
      let frame = message.frame.offsetBy(dx: 0, dy: -message.estimatedHeight)
      message.frame = frame
      }, completion: { [weak self] _ in
        self?.isMessageVisible = false
        message.removeFromSuperview()
        
        if fromGesture {
          message.callback?()
        }
        
        if let messageBar = self , !messageBar.messageQueue.isEmpty {
          messageBar.dequeueNextMessage()
        } else {
          self?.resetTimer()
          self?.messageWindow = nil
        }
      }
    )
  }
  
}

private class MessageWindow: UIWindow {
  
  lazy var messageBarController: MessageBarController = {
    return MessageBarController()
  }()
  
  var messageBarView: UIView {
    return messageBarController.view
  }
  
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    var hitView = super.hitTest(point, with: event)
    if hitView == rootViewController?.view {
      hitView = nil
    }
    return hitView
  }
  
}

private class MessageBarController: UIViewController {
  
  var statusBarStyle: UIStatusBarStyle = .default {
    didSet {
      setNeedsStatusBarAppearanceUpdate()
    }
  }
  
  var statusBarHidden: Bool = false {
    didSet {
      setNeedsStatusBarAppearanceUpdate()
    }
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return statusBarStyle
  }
  
  override var prefersStatusBarHidden: Bool {
    return statusBarHidden
  }
  
}
