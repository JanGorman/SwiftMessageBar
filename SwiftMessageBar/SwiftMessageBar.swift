//
//  Created by Jan Gorman on 10/06/15.
//  Copyright (c) 2015 Schnaub. All rights reserved.
//

import UIKit

public struct MessageBarConfig {
    
    public var errorColor: UIColor
    public var successColor: UIColor
    public var infoColor: UIColor
    public var titleColor: UIColor
    public var messageColor: UIColor
    public var statusBarHidden: Bool
    
    public init(errorColor: UIColor = UIColor.redColor(), successColor: UIColor = UIColor.greenColor(), infoColor: UIColor = UIColor.yellowColor(), titleColor: UIColor = UIColor.blackColor(), messageColor: UIColor = UIColor.blackColor(), statusBarHidden: Bool = false) {
        self.errorColor = errorColor
        self.successColor = successColor
        self.infoColor = infoColor
        self.titleColor = titleColor
        self.messageColor = messageColor
        self.statusBarHidden = statusBarHidden
    }
}

public typealias Callback = () -> Void

public class SwiftMessageBar {
    
    var config: MessageBarConfig

    public enum MessageType {
        case Error
        case Success
        case Info
        
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
    }

    public static let SharedMessageBar = SwiftMessageBar()
    
    private static let ShowHideDuration: NSTimeInterval = 0.25
    
    private var messageWindow: MessageWindow?
    
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
    
    public static func showMessageWithTitle(_ title: String? = nil, message: String? = nil, type: MessageType,
        duration: NSTimeInterval = 3, callback: Callback? = nil) {
        SharedMessageBar.showMessageWithTitle(title, message: message, type: type, duration: duration, callback: callback)
    }

    public func showMessageWithTitle(_ title: String? = nil, message: String? = nil, type: MessageType,
        duration: NSTimeInterval = 3, callback: Callback? = nil) {
            let message = Message(title: title, message: message, backgroundColor: type.backgroundColor(fromConfig: config), duration: duration, callback: callback)
            messageQueue.enqueue(message)
            messageBarView.addSubview(message)
            messageBarView.bringSubviewToFront(message)
            if !isMessageVisible {
                dequeueNextMessage()
        }
    }
    
    private func dequeueNextMessage() {
        if let message = messageQueue.dequeue() {
            isMessageVisible = true
            // TODO ask if message wants to hide status bar
            message.frame = CGRect(x: 0, y: -message.height, width: message.width, height: message.height)
            message.hidden = false
            message.setNeedsDisplay()
            
            let gesture = UITapGestureRecognizer(target: self, action: Selector("didTapMessage:"))
            message.addGestureRecognizer(gesture)

            UIView.animateWithDuration(SwiftMessageBar.ShowHideDuration) {
                message.frame = CGRect(x: CGRectGetMinX(message.frame), y: CGRectGetMinY(message.frame) + message.height, width: message.width, height: message.height)
            }
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
    }
    
    private func dismissMessage(message: Message, fromGesture: Bool) {
        if !message.isHit {
            message.isHit = true
            
            UIView.animateWithDuration(SwiftMessageBar.ShowHideDuration, animations: {
                message.frame = CGRect(x: CGRectGetMinX(message.frame), y: CGRectGetMinY(message.frame) - message.height, width: message.width, height: message.height)
            }) {
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
            }
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

private class Message: UIView {
    
    private static let Padding: CGFloat = 10
    private static let MessageOffset: CGFloat = 2
    
    var title: String?
    var message: String?
    var duration: NSTimeInterval!
    var color: UIColor!
    var callback: Callback?
    var isHit: Bool = false
    
    var titleFont: UIFont!
    var messageFont: UIFont!
    
    init(title: String?, message: String?, backgroundColor: UIColor, duration: NSTimeInterval, callback: Callback?) {
        self.title = title
        self.message = message
        self.duration = duration
        self.callback = callback
        self.color = backgroundColor
        titleFont = UIFont.boldSystemFontOfSize(16)
        messageFont = UIFont.systemFontOfSize(14)
        super.init(frame: CGRectZero)
        // TODO register for rotation
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        // TODO check appearance proxy
        CGContextSaveGState(context)
        color!.set()
        CGContextFillRect(context, rect)
        CGContextRestoreGState(context)
        
        var xOffset = Message.Padding
        var yOffset = Message.Padding + statusBarOffset
        
        // TODO draw icon
        
        yOffset -= Message.MessageOffset
        xOffset += Message.Padding
        
        if let _ = title where message == nil {
            yOffset = ceil(CGRectGetHeight(rect) * 0.5) - ceil(titleSize.height * 0.5) - Message.MessageOffset
        }
        
        let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = .Left
        if let title = title {
            let attributes = [
                NSFontAttributeName : titleFont,
                NSForegroundColorAttributeName: UIColor.blackColor(),
                NSParagraphStyleAttributeName: paragraphStyle
            ]
            let rect = CGRect(x: xOffset, y: yOffset, width: titleSize.width, height: titleSize.height)
            title.drawWithRect(rect, options: .UsesLineFragmentOrigin | .TruncatesLastVisibleLine, attributes: attributes, context: nil)
            
            yOffset += titleSize.height
        }
        if let message = message {
            let attributes = [
                NSFontAttributeName : messageFont,
                NSForegroundColorAttributeName: UIColor.blackColor(),
                NSParagraphStyleAttributeName: paragraphStyle
            ]
            let rect = CGRect(x: xOffset, y: yOffset, width: messageSize.width, height: messageSize.height)
            message.drawWithRect(rect, options: .UsesLineFragmentOrigin | .TruncatesLastVisibleLine, attributes: attributes, context: nil)
            
            yOffset += titleSize.height
        }
    }
    
    var height: CGFloat {
//        return max(Message.Padding * 2 + titleSize.height + descriptionSize.height + statusBarOffset, Message.Padding * 2 + Message.IconSize + statusBarOffset)
        return Message.Padding * 2 + titleSize.height + messageSize.height + statusBarOffset
    }
    
    var titleSize: CGSize {
        let boundedSize = CGSize(width: availableWidth, height: CGFloat.max)
        let titleFontAttributes = [NSFontAttributeName: titleFont]
        if let size = title?.boundingRectWithSize(boundedSize, options: .TruncatesLastVisibleLine | .UsesLineFragmentOrigin, attributes: titleFontAttributes, context: nil).size {
            return CGSize(width: ceil(size.width), height: ceil(size.height))
        }
        return CGSizeZero
    }
    
    var messageSize: CGSize {
        let boundedSize = CGSize(width: availableWidth, height: CGFloat.max)
        let titleFontAttributes = [NSFontAttributeName: messageFont]
        if let size = title?.boundingRectWithSize(boundedSize, options: .TruncatesLastVisibleLine | .UsesLineFragmentOrigin, attributes: titleFontAttributes, context: nil).size {
            return CGSize(width: ceil(size.width), height: ceil(size.height))
        }
        return CGSizeZero
    }
    
    var statusBarOffset: CGFloat {
        return CGRectGetHeight(statusBarFrame)
    }
    
    var statusBarFrame: CGRect {
        let windowFrame = UIApplication.sharedApplication().keyWindow!.frame
        let statusFrame = UIApplication.sharedApplication().statusBarFrame
        return CGRect(x: CGRectGetMinX(windowFrame), y: CGRectGetMinY(windowFrame), width: CGRectGetWidth(windowFrame), height: CGRectGetHeight(statusFrame))
    }
    
    var width: CGFloat {
        return CGRectGetWidth(statusBarFrame)
    }
    
    var availableWidth: CGFloat {
        return width - Message.Padding * 3 // - size for icon
    }
    
}

private struct Queue<T> {

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

}