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
    
    public init(errorColor: UIColor = UIColor.redColor(), successColor: UIColor = UIColor.greenColor(), infoColor: UIColor = UIColor.blueColor(), titleColor: UIColor = UIColor.whiteColor(), messageColor: UIColor = UIColor.whiteColor(), statusBarHidden: Bool = false, successIcon: UIImage? = nil, infoIcon: UIImage? = nil, errorIcon: UIImage? = nil) {
        self.errorColor = errorColor
        self.successColor = successColor
        self.infoColor = infoColor
        self.titleColor = titleColor
        self.messageColor = messageColor
        self.statusBarHidden = statusBarHidden
        let bundle = NSBundle(forClass: SwiftMessageBar.self)
        self.successIcon = successIcon ?? UIImage(named: "icon-success", inBundle: bundle, compatibleWithTraitCollection: nil)
        self.infoIcon = infoIcon ?? UIImage(named: "icon-info", inBundle: bundle, compatibleWithTraitCollection: nil)
        self.errorIcon = errorIcon ?? UIImage(named: "icon-error", inBundle: bundle, compatibleWithTraitCollection: nil)
    }

}

public typealias Callback = () -> Void

public final class SwiftMessageBar {
    
    private var config: MessageBarConfig

    public enum MessageType {
        case Error, Success, Info
        
        func backgroundColor(fromConfig config: MessageBarConfig) -> UIColor {
            switch self {
            case Error:
                return config.errorColor
            case Info:
                return config.infoColor
            case Success:
                return config.successColor
            }
        }
        
        func image(fromConfig config: MessageBarConfig) -> UIImage? {
            switch self {
            case Error:
                return config.errorIcon
            case Info:
                return config.infoIcon
            case Success:
                return config.successIcon
            }
        }

    }

    public static let SharedMessageBar = SwiftMessageBar()
    
    private static let ShowHideDuration: NSTimeInterval = 0.25
    
    private var messageWindow: MessageWindow?
    
    public var tapHandler : (() -> Void)?
    
    private func newMessageWindow() -> MessageWindow {
        let messageWindow = MessageWindow()
        messageWindow.frame = UIApplication.sharedApplication().keyWindow!.frame
        messageWindow.hidden = false
        messageWindow.windowLevel = UIWindowLevelNormal
        messageWindow.backgroundColor = UIColor.clearColor()
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
    
    public static func setSharedConfig(config: MessageBarConfig) {
        SharedMessageBar.config = config
    }
    
    public static func showMessageWithTitle(title: String? = nil, message: String? = nil, type: MessageType,
            duration: NSTimeInterval = 3, dismiss: Bool = true, callback: Callback? = nil) -> NSUUID {
        return SharedMessageBar.showMessageWithTitle(title, message: message, type: type, duration: duration, dismiss: dismiss, callback: callback)
    }

    public func showMessageWithTitle(title: String? = nil, message: String? = nil, type: MessageType,
            duration: NSTimeInterval = 3, dismiss: Bool = true, callback: Callback? = nil) -> NSUUID {
        let message = Message(title: title, message: message, backgroundColor: type.backgroundColor(fromConfig: config), titleFontColor: config.titleColor, messageFontColor: config.messageColor, icon: type.image(fromConfig: config), duration: duration, dismiss: dismiss, callback: callback)
        messageQueue.enqueue(message)
        if !isMessageVisible {
            dequeueNextMessage()
        }
        return message.id()
    }
    
    public func cancelAll() {
        guard !isMessageVisible && messageQueue.isEmpty() else {
            return
        }
        if let message = messageBarView.subviews.filter({ $0 is Message }).first as? Message {
            dismissMessage(message)
        }
        isMessageVisible = false
        messageQueue.removeAll()
    }

    public func cancelWithId(id: NSUUID) {
        if let message = messageBarView.subviews.filter({ $0 is Message }).first as? Message where message.id() == id {
            dismissMessage(message)
        }
        messageQueue.removeWithId(id)
    }

    private func dequeueNextMessage() {
        guard let message = messageQueue.dequeue() else {
            return
        }
        messageBarView.addSubview(message)
        messageBarView.bringSubviewToFront(message)
        isMessageVisible = true
        message.frame = CGRect(x: 0, y: -message.estimatedHeight, width: message.width, height: message.estimatedHeight)
        message.hidden = false
        message.setNeedsUpdateConstraints()
        
        let gesture = UITapGestureRecognizer(target: self, action: Selector("didTapMessage:"))
        message.addGestureRecognizer(gesture)
        
        UIView.animateWithDuration(SwiftMessageBar.ShowHideDuration,
            delay: 0,
            options: .CurveEaseInOut,
            animations: {
                message.frame = CGRect(x: message.frame.minX, y: message.frame.minY + message.estimatedHeight,
                    width: message.width, height: message.estimatedHeight)
            }, completion: nil)
        
        if message.dismiss {
            let time = dispatch_time(DISPATCH_TIME_NOW, (Int64)(message.duration * Double(NSEC_PER_SEC)))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.dismissMessage(message)
            }
        }
    }
    
    private func dismissMessage(message: Message) {
        dismissMessage(message, fromGesture: false)
    }
    
    @objc func didTapMessage(gesture: UITapGestureRecognizer) {
        let message = gesture.view as! Message
        dismissMessage(message, fromGesture: true)
        tapHandler?()
    }
    
    private func dismissMessage(message: Message, fromGesture: Bool) {
        if !message.isHit {
            message.isHit = true
            
            UIView.animateWithDuration(SwiftMessageBar.ShowHideDuration,
                delay: 0,
                options: .CurveEaseInOut,
                animations: {
                    message.frame = CGRect(x: message.frame.minX, y: message.frame.minY - message.estimatedHeight,
                        width: message.width, height: message.estimatedHeight)
                },
                completion: {
                    [weak self] _ in
                    self?.isMessageVisible = false
                    message.removeFromSuperview()
                    
                    if fromGesture {
                        message.callback?()
                    }
                    
                    if let messageBar = self where !messageBar.messageQueue.isEmpty() {
                        messageBar.dequeueNextMessage()
                    } else {
                        self?.messageWindow = nil
                    }
                })
        }
    }

}

private class MessageWindow: UIWindow {
    
    private override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        var hitView = super.hitTest(point, withEvent: event)
        if hitView == rootViewController?.view {
            hitView = nil
        }
        return hitView
    }
    
}

private class MessageBarController: UIViewController {

    var statusBarStyle: UIStatusBarStyle = .Default {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    var statusBarHidden: Bool = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    private override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return statusBarStyle
    }
    
    private override func prefersStatusBarHidden() -> Bool {
        return statusBarHidden
    }
    
}

private struct Queue<T: Identifiable> {
    
    private var queue = [T]()
    
    mutating func dequeue() -> T? {
        return !queue.isEmpty ? queue.removeAtIndex(0) : nil
    }
    
    mutating func enqueue(newElement: T) {
        queue.append(newElement)
    }
    
    func isEmpty() -> Bool {
        return queue.isEmpty
    }
    
    mutating func removeAll() {
        queue.removeAll(keepCapacity: false)
    }
    
    mutating func removeWithId(id: NSUUID) {
        if let idx = findElementIndexWithId(id) {
            queue.removeAtIndex(idx)
        }
    }
    
    private func findElementIndexWithId(id: NSUUID) -> Int? {
        for (i, element) in queue.enumerate() {
            if element.id() == id {
                return i
            }
        }
        return nil
    }
    
}
