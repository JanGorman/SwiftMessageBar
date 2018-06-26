//
//  Copyright (c) 2015 Schnaub. All rights reserved.
//

import UIKit

protocol Identifiable {

  var id: UUID { get }

}

final class Message: UIView {
  
  private static let padding: CGFloat = 10
  private static let messageOffset: CGFloat = 2
  private static let iconSize: CGFloat = 36

  private(set) var type: MessageType!
  private let uuid = UUID()
  private var title: String?
  private var message: String?
  private var titleFontColor: UIColor!
  private var messageFontColor: UIColor!
  private var icon: UIImage?
  var isHit: Bool = false
  private(set) var callback: Callback?
  private(set) var duration: TimeInterval!
  private(set) var dismiss: Bool = true
  private var languageDirection: NSLocale.LanguageDirection!
  private var titleFont: UIFont!
  private var messageFont: UIFont!
  
  private var paragraphStyle: NSMutableParagraphStyle {
    let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
    paragraphStyle.alignment = .left
    return paragraphStyle
  }
  
  init(type: MessageType, title: String?, message: String?, backgroundColor: UIColor, titleFontColor: UIColor,
       messageFontColor: UIColor, icon: UIImage?, duration: TimeInterval, dismiss: Bool = true, callback: Callback?,
       languageDirection: NSLocale.LanguageDirection, titleFont: UIFont, messageFont: UIFont) {
    self.type = type
    self.title = title
    self.message = message
    self.duration = duration
    self.callback = callback
    self.titleFontColor = titleFontColor
    self.messageFontColor = messageFontColor
    self.icon = icon
    self.dismiss = dismiss
    self.languageDirection = languageDirection
    self.titleFont = titleFont
    self.messageFont = messageFont
    
    super.init(frame: CGRect.zero)
    
    self.backgroundColor = backgroundColor
    usesAutoLayout(true)
  }
  
  func configureSubviews() {
    let iconImageView = initIcon()
    let titleLabel = initTitle()
    let messageLabel = initMessage()
    
    let isTitleEmpty = title?.isEmpty ?? true
    let isMessageEmpty = message?.isEmpty ?? true
    
    if languageDirection == .rightToLeft {
      titleLabel.textAlignment = .right
      messageLabel.textAlignment = .right
      titleLabel.flipHorizontal()
      messageLabel.flipHorizontal()
      iconImageView.flipHorizontal()
    }
    let views = ["icon": iconImageView, "title": titleLabel, "message": messageLabel]
    let metrics = [
      "titleTop": topMargin,
      "right": Message.padding,
      "bottom": bottomMargin,
      "messageLeft": Message.padding + Message.messageOffset,
      "iconLeft": Message.padding,
      
      "messageOffset": !isTitleEmpty && !isMessageEmpty ? Message.messageOffset : 0,
      "width": Message.iconSize,
      "height": Message.iconSize
    ]

    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[icon(==width)]", options: [],
                                                  metrics: metrics, views: views))
    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[icon(==height)]", options: [],
                                                  metrics: metrics, views: views))
    
    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-iconLeft-[icon]-messageLeft-[title]-right-|",
                                                  options: [], metrics: metrics, views: views))
    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-iconLeft-[icon]-messageLeft-[message]-right-|",
                                                  options: [], metrics: metrics, views: views))
    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-titleTop-[title]-messageOffset-[message]-bottom-|",
                                                  options: [], metrics: metrics, views: views))
    
    if isTitleEmpty {
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[title(==0)]", options: [],
                                                      metrics: metrics, views: views))
    } else if isMessageEmpty {
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[message(==0)]", options: [],
                                                      metrics: metrics, views: views))
    }
    
    addConstraint(NSLayoutConstraint(item: iconImageView,
                                     attribute: NSLayoutAttribute.centerY,
                                     relatedBy: NSLayoutRelation.equal,
                                     toItem: iconImageView.superview,
                                     attribute: NSLayoutAttribute.centerY,
                                     multiplier: 1.0,
                                     constant: (topMargin - bottomMargin) / 2.0))
  }
  
  private func initIcon() -> UIImageView {
    let iconImageView = UIImageView()
    iconImageView.image = icon
    iconImageView.usesAutoLayout(true)
    addSubview(iconImageView)
    return iconImageView
  }
  
  private func initTitle() -> UILabel {
    let titleLabel = UILabel()
    titleLabel.numberOfLines = 0
    titleLabel.usesAutoLayout(true)
    addSubview(titleLabel)
    
    if let title = title {
      let attributes: [NSAttributedStringKey: Any] = [
        .font : titleFont,
        .foregroundColor: titleFontColor,
        .paragraphStyle: paragraphStyle
      ]
      titleLabel.attributedText = NSAttributedString(string: title, attributes: attributes)
    }
    return titleLabel
  }
  
  private func initMessage() -> UILabel {
    let messageLabel = UILabel()
    messageLabel.numberOfLines = 0
    messageLabel.usesAutoLayout(true)
    addSubview(messageLabel)
    
    if let message = message {
      let attributes: [NSAttributedStringKey: Any] = [
        .font : messageFont,
        .foregroundColor: messageFontColor,
        .paragraphStyle: paragraphStyle
      ]
      messageLabel.attributedText = NSAttributedString(string: message, attributes: attributes)
    }
    return messageLabel
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func updateConstraints() {
    superview?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: [],
                                                             metrics: nil, views: ["view": self]))
    super.updateConstraints()
  }
  
  override var intrinsicContentSize: CGSize {
    return CGSize(width: statusBarFrame.width, height: estimatedHeight)
  }
  
  var estimatedHeight: CGFloat {
      let iconSize = icon == nil ? 0 : Message.iconSize
      return max(topMargin + titleSize.height + Message.messageOffset + messageSize.height + bottomMargin,
                 topMargin + iconSize + bottomMargin)
  }
  
  var titleSize: CGSize {
    let boundedSize = CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
    let titleFontAttributes: [NSAttributedStringKey: Any] = [.font: titleFont]
    if let size = title?.boundingRect(with: boundedSize,
                                      options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin],
                                      attributes: titleFontAttributes, context: nil).size {
      return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    return .zero
  }
  
  var messageSize: CGSize {
    let boundedSize = CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
    let titleFontAttributes: [NSAttributedStringKey: Any] = [.font: messageFont]
    if let size = message?.boundingRect(with: boundedSize,
                                        options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin],
                                        attributes: titleFontAttributes, context: nil).size {
      return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    return .zero
  }
  
  var statusBarOffset: CGFloat {
    return statusBarFrame.height
  }
  
  var topMargin: CGFloat {
    return max(statusBarOffset, Message.padding)
  }

  var bottomMargin: CGFloat {
    return Message.padding
  }
    
  var width: CGFloat {
    return statusBarFrame.width
  }
  
  var statusBarFrame: CGRect {
    let windowFrame = UIScreen.main.bounds
    let statusFrame = UIApplication.shared.statusBarFrame
    return CGRect(x: windowFrame.minX, y: windowFrame.minY, width: windowFrame.width, height: statusFrame.height)
  }
  
  var availableWidth: CGFloat {
    return width - Message.padding * 2 - Message.iconSize
  }

  static func ==(lhs: Message, rhs: Message) -> Bool {
    return lhs.id == rhs.id
  }

}

extension Message: Identifiable {

  var id: UUID {
    return uuid
  }

}

extension UIView {
  
  func usesAutoLayout(_ usesAutoLayout: Bool) {
    translatesAutoresizingMaskIntoConstraints = !usesAutoLayout
  }
    
  func flipHorizontal() {
    layer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
  }

}
