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
        duration: NSTimeInterval = 3, dismiss: Bool = true, callback: Callback? = nil) -> NSUUID {
            return SharedMessageBar.showMessageWithTitle(title, message: message, type: type, duration: duration, dismiss: dismiss, callback: callback)
    }

    public func showMessageWithTitle(_ title: String? = nil, message: String? = nil, type: MessageType,
        duration: NSTimeInterval = 3, dismiss: Bool = true, callback: Callback? = nil) -> NSUUID {
            let message = Message(title: title, message: message, backgroundColor: type.backgroundColor(fromConfig: config), titleFontColor: config.titleColor, messageFontColor: config.messageColor, icon: type.image(fromConfig: config), duration: duration, dismiss: dismiss, callback: callback)
            messageQueue.enqueue(message)
            if !isMessageVisible {
                dequeueNextMessage()
        }
        return message.id()
    }
    
    public func cancelAll() {
        if !isMessageVisible && messageQueue.isEmpty() {
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
        if let message = messageQueue.dequeue() {
            messageBarView.addSubview(message)
            messageBarView.bringSubviewToFront(message)
            isMessageVisible = true
            message.frame = CGRect(x: 0, y: -message.height, width: message.width, height: message.height)
            message.hidden = false
            message.setNeedsUpdateConstraints()
            
            let gesture = UITapGestureRecognizer(target: self, action: Selector("didTapMessage:"))
            message.addGestureRecognizer(gesture)
            
            UIView.animateWithDuration(SwiftMessageBar.ShowHideDuration,
                delay: 0,
                options: .CurveEaseInOut,
                animations: {
                    message.frame = CGRect(x: message.frame.minX, y: message.frame.minY + message.height, width: message.width, height: message.height)
                }, completion: nil)
            
            if message.dismiss {
                let time = dispatch_time(DISPATCH_TIME_NOW, (Int64)(message.duration * Double(NSEC_PER_SEC)))
                dispatch_after(time, dispatch_get_main_queue()) {
                    self.dismissMessage(message)
                }
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
            
            UIView.animateWithDuration(SwiftMessageBar.ShowHideDuration,
                delay: 0,
                options: .CurveEaseInOut,
                animations: {
                    message.frame = CGRect(x: message.frame.minX, y: message.frame.minY - message.height, width: message.width, height: message.height)
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

private protocol Identifiable {

    func id() -> NSUUID
    
}

private class Message: UIView, Identifiable {
    
    private static let Padding: CGFloat = 10
    private static let MessageOffset: CGFloat = 2
    private static let IconSize: CGFloat = 36
    
    private let uuid = NSUUID()
    var title: String?
    var message: String?
    var duration: NSTimeInterval!
    var titleFontColor: UIColor!
    var messageFontColor: UIColor!
    var icon: UIImage?
    var callback: Callback?
    var isHit: Bool = false
    var dismiss: Bool = true
    
    var titleFont: UIFont!
    var messageFont: UIFont!
    
    private var iconImageView: UIImageView!
    private var titleLabel: UILabel!
    private var messageLabel: UILabel!

    private var paragraphStyle: NSMutableParagraphStyle {
        let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = .Left
        return paragraphStyle
    }

    init(title: String?, message: String?, backgroundColor: UIColor, titleFontColor: UIColor, messageFontColor: UIColor,
        icon: UIImage?, duration: NSTimeInterval, dismiss: Bool = true, callback: Callback?) {
        self.title = title
        self.message = message
        self.duration = duration
        self.callback = callback
        self.titleFontColor = titleFontColor
        self.messageFontColor = messageFontColor
        self.icon = icon
        self.dismiss = dismiss
        titleFont = UIFont.boldSystemFontOfSize(16)
        messageFont = UIFont.systemFontOfSize(14)
        
        super.init(frame: CGRectZero)
        
        self.backgroundColor = backgroundColor
        usesAutoLayout(true)
        initSubviews()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didChangeOrientation:"), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }

    private func initSubviews() {
        iconImageView = UIImageView()
        iconImageView.image = icon
        iconImageView.usesAutoLayout(true)
        addSubview(iconImageView)
        
        titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.usesAutoLayout(true)
        addSubview(titleLabel)
        
        messageLabel = UILabel()
        messageLabel.numberOfLines = 0
        messageLabel.usesAutoLayout(true)
        addSubview(messageLabel)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    @objc func didChangeOrientation(notification: NSNotification) {
        invalidateIntrinsicContentSize()
        setNeedsUpdateConstraints()
    }

    override func updateConstraints() {
        updateFrameConstraints()
        updateIconConstraints()
        updateTitleConstraints()
        updateMessageConstraints()
        super.updateConstraints()
    }

    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: statusBarFrame.width, height: height)
    }

    private func updateFrameConstraints() {
        superview?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[view]-0-|", options: .allZeros,
            metrics: nil, views: ["view": self]))
    }

    private func updateIconConstraints() {
        let views = ["icon": iconImageView]
        let metrics = [
            "top": Message.Padding + statusBarOffset,
            "left": Message.Padding,
            "width": Message.IconSize,
            "height": Message.IconSize
        ]

        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[icon(==width)]", options: .allZeros,
            metrics: metrics, views: views))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[icon(==height)]", options: .allZeros,
            metrics: metrics, views: views))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-top-[icon]", options: .allZeros,
            metrics: metrics, views:views))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-left-[icon]", options: .allZeros,
            metrics: metrics, views:views))
    }
    
    private func updateTitleConstraints() {
        let views = ["icon": iconImageView, "title": titleLabel]
        let metrics = [
            "top": Message.Padding + statusBarOffset - Message.MessageOffset,
            "left": Message.Padding + Message.MessageOffset,
            "iconLeft": Message.Padding,
            "right": Message.Padding
        ]

        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-iconLeft-[icon]-left-[title]-right-|",
            options: .allZeros, metrics: metrics, views: views))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-top-[title]", options: .allZeros,
            metrics: metrics, views: views))

        if let title = title {
            let attributes = [
                NSFontAttributeName : titleFont,
                NSForegroundColorAttributeName: titleFontColor,
                NSParagraphStyleAttributeName: paragraphStyle
            ]
            let attributedTitle = NSAttributedString(string: title, attributes: attributes)
            titleLabel.attributedText = attributedTitle
        }
    }

    private func updateMessageConstraints() {
        if let message = message {
            let attributes = [
                NSFontAttributeName : messageFont,
                NSForegroundColorAttributeName: messageFontColor,
                NSParagraphStyleAttributeName: paragraphStyle
            ]
            let attributedMessage = NSAttributedString(string: message, attributes: attributes)
            messageLabel.attributedText = attributedMessage

            let views = ["icon": iconImageView, "title": titleLabel, "message": messageLabel]
            let metrics = [
                "top": Message.MessageOffset,
                "titleTop": Message.Padding + statusBarOffset - Message.MessageOffset,
                "left": Message.Padding + Message.MessageOffset,
                "iconLeft": Message.Padding,
                "right": Message.Padding,
                "bottom": Message.Padding
            ]

            addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-iconLeft-[icon]-left-[message]-right-|",
                options: .allZeros, metrics: metrics, views: views))
            addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-titleTop-[title]-top-[message]-bottom-|",
                options: .allZeros, metrics: metrics, views: views))
        }
    }

    var height: CGFloat {
        if icon != nil {
            return max(Message.Padding * 2 + titleSize.height + messageSize.height + statusBarOffset, Message.Padding * 2 + Message.IconSize + statusBarOffset)
            
        } else {
            return Message.Padding * 2 + titleSize.height + messageSize.height + statusBarOffset
        }
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
        if let size = message?.boundingRectWithSize(boundedSize, options: .TruncatesLastVisibleLine | .UsesLineFragmentOrigin, attributes: titleFontAttributes, context: nil).size {
            return CGSize(width: ceil(size.width), height: ceil(size.height))
        }
        return CGSizeZero
    }

    var statusBarOffset: CGFloat {
        return statusBarFrame.height
    }

    var statusBarFrame: CGRect {
        let windowFrame = UIApplication.sharedApplication().keyWindow!.frame
        let statusFrame = UIApplication.sharedApplication().statusBarFrame
        return CGRect(x: windowFrame.minX, y: windowFrame.minY, width: windowFrame.width, height: statusFrame.height)
    }

    var width: CGFloat {
        return statusBarFrame.width
    }

    var availableWidth: CGFloat {
        return width - Message.Padding * 2 - Message.IconSize
    }

    // MARK: Identifiable

    private func id() -> NSUUID {
        return uuid
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
        for (i, element) in enumerate(queue) {
            if element.id() == id {
                return i
            }
        }
        return nil
    }

}

extension UIView {
    
    func usesAutoLayout(usesAutoLayout: Bool) {
        setTranslatesAutoresizingMaskIntoConstraints(!usesAutoLayout)
    }
    
}