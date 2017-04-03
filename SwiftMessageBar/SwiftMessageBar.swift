//
//  Created by Jan Gorman on 10/06/15.
//  Copyright (c) 2015 Schnaub. All rights reserved.
//

import UIKit

public struct MessageBarConfig {
  
  let errorColor: UIColor
  let successColor: UIColor
  let infoColor: UIColor
  let titleColor: UIColor
  let messageColor: UIColor
  let statusBarHidden: Bool
  let successIcon: UIImage?
  let infoIcon: UIImage?
  let errorIcon: UIImage?
  
  public init(errorColor: UIColor = UIColor.red, successColor: UIColor = .green, infoColor: UIColor = .blue,
              titleColor: UIColor = .white, messageColor: UIColor = .white, statusBarHidden: Bool = false,
              successIcon: UIImage? = nil, infoIcon: UIImage? = nil, errorIcon: UIImage? = nil,
              languageDirection: NSLocale.LanguageDirection = .leftToRight) {
    self.errorColor = errorColor
    self.successColor = successColor
    self.infoColor = infoColor
    self.titleColor = titleColor
    self.messageColor = messageColor
    self.statusBarHidden = statusBarHidden
    let bundle = Bundle(for: SwiftMessageBar.self)
    self.successIcon = successIcon ?? UIImage(named: "icon-success", in: bundle, compatibleWith: nil)
    self.infoIcon = infoIcon ?? UIImage(named: "icon-info", in: bundle, compatibleWith: nil)
    self.errorIcon = errorIcon ?? UIImage(named: "icon-error", in: bundle, compatibleWith: nil)
  }
  
}

public typealias Callback = () -> Void

public final class SwiftMessageBar {
  
  private var config: MessageBarConfig
  public enum MessageType {
    case error, success, info
    
    func backgroundColor(fromConfig config: MessageBarConfig) -> UIColor {
      switch self {
      case .error:
        return config.errorColor
      case .info:
        return config.infoColor
      case .success:
        return config.successColor
      }
    }
    
    func image(fromConfig config: MessageBarConfig) -> UIImage? {
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
  
  public static let SharedMessageBar = SwiftMessageBar()
  
  private static let ShowHideDuration: TimeInterval = 0.25
  
  private var messageWindow: MessageWindow?
  
  private var timer: Timer?
    
  public var tapHandler : (() -> Void)?
  
  private func newMessageWindow() -> MessageWindow {
    let messageWindow = MessageWindow()
    messageWindow.frame = UIApplication.shared.keyWindow!.frame
    messageWindow.isHidden = false
    messageWindow.windowLevel = UIWindowLevelNormal
    messageWindow.backgroundColor = UIColor.clear
    let controller = MessageBarController()
    controller.statusBarHidden = config.statusBarHidden
    messageWindow.rootViewController = controller
    return messageWindow
  }
  
  private var messageBarView: UIView {
    if messageWindow == nil {
      messageWindow = newMessageWindow()
    }
    return (messageWindow?.rootViewController as! MessageBarController).view
  }
  
  private var messageQueue: Queue<Message>
  private var isMessageVisible = false
  
  private init() {
    messageQueue = Queue<Message>()
    config = MessageBarConfig()
  }
  
  /// Set a message bar configuration used by all displayed messages.
  public static func setSharedConfig(_ config: MessageBarConfig) {
    SharedMessageBar.config = config
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
  ///     - callback: An optional callback to execute when the user taps on a message to dismiss it.
  /// - Returns: A UUID for the message. Can be used to cancel the display of a specific message
  @discardableResult
  public static func showMessageWithTitle(_ title: String? = nil, message: String? = nil, type: MessageType,
                                          duration: TimeInterval = 3, dismiss: Bool = true,
                                          languageDirection: NSLocale.LanguageDirection = .unknown,
                                          callback: Callback? = nil ) -> UUID {
    return SharedMessageBar.showMessageWithTitle(title, message: message, type: type, duration: duration,
                                                 dismiss: dismiss, languageDirection: languageDirection,
                                                 callback: callback)
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
  ///     - callback: An optional callback to execute when the user taps on a message to dismiss it.
  /// - Returns: A UUID for the message. Can be used to cancel the display of a specific message
  @discardableResult
  public func showMessageWithTitle(_ title: String? = nil, message: String? = nil, type: MessageType,
                                   duration: TimeInterval = 3, dismiss: Bool = true,
                                   languageDirection: NSLocale.LanguageDirection = .unknown,
                                   callback: Callback? = nil) -> UUID {
    let message = Message(title: title, message: message, backgroundColor: type.backgroundColor(fromConfig: config),
                          titleFontColor: config.titleColor, messageFontColor: config.messageColor,
                          icon: type.image(fromConfig: config), duration: duration, dismiss: dismiss,
                          callback: callback, languageDirection: languageDirection)
    if languageDirection == .rightToLeft {
      message.flipHorizontal()
    }
    messageQueue.enqueue(message)
    if !isMessageVisible {
      dequeueNextMessage()
    }
    return message.id()
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
  public func cancelWithId(_ id: UUID) {
    if let message = visibleMessage , message.id() == id {
      dismissMessage(message)
    }
    messageQueue.removeWithId(id)
  }
  
  private var visibleMessage: Message? {
    return messageBarView.subviews.filter({ $0 is Message }).first as? Message
  }
  
  private func dequeueNextMessage() {
    guard let message = messageQueue.dequeue() else {
      return
    }
    messageBarView.addSubview(message)
    messageBarView.bringSubview(toFront: message)
    isMessageVisible = true
    message.frame = CGRect(x: 0, y: -message.estimatedHeight, width: message.width, height: message.estimatedHeight)
    message.isHidden = false
    message.setNeedsUpdateConstraints()
    
    let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMessage))
    message.addGestureRecognizer(gesture)
    
    UIView.animate(withDuration: SwiftMessageBar.ShowHideDuration, delay: 0, options: [], animations: {
      message.frame = CGRect(x: message.frame.minX, y: message.frame.minY + message.estimatedHeight,
                             width: message.width, height: message.estimatedHeight)
      }, completion: nil)
    
    if message.dismiss {
      resetTimer()
      timer = Timer.scheduledTimer(timeInterval: message.duration, target: self, selector: #selector(dismiss),
                                     userInfo: nil, repeats: false)
    }
  }
  
  private func resetTimer() {
    timer?.invalidate()
    timer = nil
  }
    
  @objc private func dismiss() {
    resetTimer()
    if let message = visibleMessage {
      dismissMessage(message)
    }
  }
    
  private func dismissMessage(_ message: Message) {
    dismissMessage(message, fromGesture: false)
  }
  
  @objc func didTapMessage(_ gesture: UITapGestureRecognizer) {
    let message = gesture.view as! Message
    dismissMessage(message, fromGesture: true)
    tapHandler?()
  }
    
  private func dismissMessage(_ message: Message, fromGesture: Bool) {
    if message.isHit {
      return
    }
    
    message.isHit = true
    
    UIView.animate(withDuration: SwiftMessageBar.ShowHideDuration, delay: 0, options: [], animations: {
      message.frame = CGRect(x: message.frame.minX, y: -message.estimatedHeight,
                             width: message.width, height: message.estimatedHeight)
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

private struct Queue<T: Identifiable> {
  
  private var left: [T]
  private var right: [T]
  
  var isEmpty: Bool {
    return left.isEmpty && right.isEmpty
  }
  
  init() {
    left = []
    right = []
  }
  
  mutating func dequeue() -> T? {
    guard !(left.isEmpty && right.isEmpty) else { return nil }
    
    if left.isEmpty {
      left = right.reversed()
      right.removeAll(keepingCapacity: true)
    }
    return left.removeLast()
  }
  
  mutating func enqueue(_ newElement: T) {
    right.append(newElement)
  }
  
  mutating func removeAll() {
    left.removeAll()
    right.removeAll()
  }
  
  mutating func removeWithId(_ id: UUID) {
    if let idx = left.findWithId(id) {
      left.remove(at: idx)
    }
    if let idx = right.findWithId(id) {
      right.remove(at: idx)
    }
  }
  
}

private extension Array where Element: Identifiable {
  
  func findWithId(_ id: UUID) -> Int? {
    return enumerated().lazy.filter({ $1.id() == id }).first?.0
  }
  
}
